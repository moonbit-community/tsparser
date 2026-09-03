#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import {
  DEFAULT_TYPESCRIPT_SOURCE_DIR,
  TYPESCRIPT_GIT_HEAD,
  TYPESCRIPT_REPOSITORY,
  TYPESCRIPT_TAG,
  TYPESCRIPT_VERSION,
  UPSTREAM_SOURCE_MANIFEST,
  compilerSourcePaths,
  manifestEntry,
  readJson,
} from "./upstream-config.mjs";

function parseArguments(argv) {
  let verify = false;
  let sourceDirectory = DEFAULT_TYPESCRIPT_SOURCE_DIR;
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    if (argument === "--verify") {
      verify = true;
    } else if (argument === "--source-dir") {
      sourceDirectory = argv[++index];
      if (!sourceDirectory) {
        throw new Error("--source-dir requires a path");
      }
    } else {
      throw new Error(`unknown argument: ${argument}`);
    }
  }
  if (!verify) {
    throw new Error("only the read-only audit mode --verify is supported");
  }
  return { sourceDirectory: path.resolve(sourceDirectory) };
}

function runGit(arguments_, options = {}) {
  const result = spawnSync("git", arguments_, {
    cwd: options.cwd,
    encoding: "utf8",
    stdio: options.capture ? "pipe" : "inherit",
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    const detail = options.capture ? (result.stderr || result.stdout).trim() : "";
    throw new Error(`git ${arguments_.join(" ")} failed${detail ? `: ${detail}` : ""}`);
  }
  return options.capture ? result.stdout.trim() : "";
}

function removeFailedCheckout(directory) {
  try {
    fs.rmSync(directory, { recursive: true, force: true });
  } catch {
    // Keep the original bootstrap failure.
  }
}

function ensureExactCheckout(sourceDirectory) {
  const gitDirectory = path.join(sourceDirectory, ".git");
  if (fs.existsSync(gitDirectory)) {
    return;
  }
  if (fs.existsSync(sourceDirectory) && fs.readdirSync(sourceDirectory).length > 0) {
    throw new Error(
      `${sourceDirectory} exists but is not a git checkout; choose another --source-dir`,
    );
  }

  fs.mkdirSync(path.dirname(sourceDirectory), { recursive: true });
  const temporaryDirectory = `${sourceDirectory}.tmp-${process.pid}`;
  removeFailedCheckout(temporaryDirectory);
  try {
    runGit(["init", "--quiet", temporaryDirectory]);
    runGit(["-C", temporaryDirectory, "remote", "add", "origin", TYPESCRIPT_REPOSITORY]);
    runGit(["-C", temporaryDirectory, "fetch", "--depth", "1", "origin", `refs/tags/${TYPESCRIPT_TAG}`]);
    runGit(["-C", temporaryDirectory, "checkout", "--quiet", "--detach", "FETCH_HEAD"]);
    fs.renameSync(temporaryDirectory, sourceDirectory);
  } catch (error) {
    removeFailedCheckout(temporaryDirectory);
    throw error;
  }
}

function verifyNpmPackage() {
  const packagePath = path.resolve("node_modules", "typescript", "package.json");
  if (!fs.existsSync(packagePath)) {
    throw new Error("node_modules/typescript is missing; run npm ci first");
  }
  const packageJson = readJson(packagePath);
  if (packageJson.version !== TYPESCRIPT_VERSION) {
    throw new Error(
      `npm TypeScript version mismatch: expected ${TYPESCRIPT_VERSION}, found ${packageJson.version ?? "unknown"}`,
    );
  }
  if (packageJson.gitHead !== TYPESCRIPT_GIT_HEAD) {
    throw new Error(
      `npm TypeScript gitHead mismatch: expected ${TYPESCRIPT_GIT_HEAD}, found ${packageJson.gitHead ?? "missing"}`,
    );
  }
}

function verifyManifest(sourceDirectory) {
  const manifest = readJson(path.resolve(UPSTREAM_SOURCE_MANIFEST));
  if (
    manifest.schema_version !== 1 ||
    manifest.typescript?.version !== TYPESCRIPT_VERSION ||
    manifest.typescript?.git_head !== TYPESCRIPT_GIT_HEAD
  ) {
    throw new Error(`${UPSTREAM_SOURCE_MANIFEST} has unexpected metadata`);
  }

  const actualCompilerPaths = compilerSourcePaths(sourceDirectory);
  const expectedCompilerPaths = manifest.files
    .map((entry) => entry.path)
    .filter((entryPath) => entryPath.startsWith("src/compiler/"));
  if (JSON.stringify(actualCompilerPaths) !== JSON.stringify(expectedCompilerPaths)) {
    throw new Error("compiler source file list differs from the committed manifest");
  }

  let compilerLineCount = 0;
  for (const expected of manifest.files) {
    const actual = manifestEntry(sourceDirectory, expected.path);
    if (actual.lines !== expected.lines || actual.sha256 !== expected.sha256) {
      throw new Error(
        `${expected.path} differs: expected ${expected.lines} lines/${expected.sha256}, ` +
          `found ${actual.lines} lines/${actual.sha256}`,
      );
    }
    if (expected.path.startsWith("src/compiler/")) {
      compilerLineCount += actual.lines;
    }
  }

  if (
    actualCompilerPaths.length !== manifest.compiler_tree?.file_count ||
    compilerLineCount !== manifest.compiler_tree?.line_count
  ) {
    throw new Error("compiler tree totals differ from the committed manifest");
  }
  return manifest;
}

export function verifyCheckout(sourceDirectory) {
  const head = runGit(["-C", sourceDirectory, "rev-parse", "HEAD"], { capture: true });
  if (head !== TYPESCRIPT_GIT_HEAD) {
    throw new Error(`checkout HEAD mismatch: expected ${TYPESCRIPT_GIT_HEAD}, found ${head}`);
  }
  const status = runGit(["-C", sourceDirectory, "status", "--porcelain"], { capture: true });
  if (status) {
    throw new Error(`TypeScript source checkout is dirty:\n${status}`);
  }
  return verifyManifest(sourceDirectory);
}

function main(argv) {
  const { sourceDirectory } = parseArguments(argv);
  verifyNpmPackage();
  ensureExactCheckout(sourceDirectory);
  const manifest = verifyCheckout(sourceDirectory);
  console.log(
    `verified TypeScript ${TYPESCRIPT_VERSION} (${TYPESCRIPT_GIT_HEAD}) at ` +
      `${path.relative(process.cwd(), sourceDirectory) || "."}: ` +
      `${manifest.compiler_tree.file_count} compiler files, ` +
      `${manifest.compiler_tree.line_count} lines`,
  );
}

const currentFile = fileURLToPath(import.meta.url);
if (process.argv[1] && path.resolve(process.argv[1]) === currentFile) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  }
}
