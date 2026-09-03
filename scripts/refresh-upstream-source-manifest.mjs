#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
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
  let sourceDirectory;
  let write = false;
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    if (argument === "--source-dir") {
      sourceDirectory = argv[++index];
      if (!sourceDirectory) {
        throw new Error("--source-dir requires a path");
      }
    } else if (argument === "--write") {
      write = true;
    } else {
      throw new Error(`unknown argument: ${argument}`);
    }
  }
  if (!sourceDirectory) {
    throw new Error("--source-dir is required");
  }
  if (!write) {
    throw new Error("refusing to refresh without explicit --write");
  }
  return { sourceDirectory: path.resolve(sourceDirectory) };
}

export function buildManifest(sourceDirectory) {
  const packageJson = readJson(path.join(sourceDirectory, "package.json"));
  if (packageJson.version !== TYPESCRIPT_VERSION) {
    throw new Error(
      `expected TypeScript ${TYPESCRIPT_VERSION}, found ${packageJson.version ?? "unknown"}`,
    );
  }

  const compilerPaths = compilerSourcePaths(sourceDirectory);
  const auditedPaths = [
    "package.json",
    "LICENSE.txt",
    "ThirdPartyNoticeText.txt",
    ...compilerPaths,
  ];
  const files = auditedPaths.map((relativePath) => manifestEntry(sourceDirectory, relativePath));
  const compilerEntries = files.filter((entry) => entry.path.startsWith("src/compiler/"));

  return {
    schema_version: 1,
    typescript: {
      version: TYPESCRIPT_VERSION,
      git_head: TYPESCRIPT_GIT_HEAD,
      tag: TYPESCRIPT_TAG,
      repository: TYPESCRIPT_REPOSITORY,
    },
    compiler_tree: {
      file_count: compilerEntries.length,
      line_count: compilerEntries.reduce((sum, entry) => sum + entry.lines, 0),
    },
    files,
  };
}

function main(argv) {
  const { sourceDirectory } = parseArguments(argv);
  const manifest = buildManifest(sourceDirectory);
  const outputPath = path.resolve(UPSTREAM_SOURCE_MANIFEST);
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(manifest, null, 2)}\n`);
  console.log(
    `wrote ${path.relative(process.cwd(), outputPath)}: ` +
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
