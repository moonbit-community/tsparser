import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

export const TYPESCRIPT_VERSION = "6.0.3";
export const TYPESCRIPT_GIT_HEAD = "050880ce59e30b356b686bd3144efe24f875ebc8";
export const TYPESCRIPT_TAG = `v${TYPESCRIPT_VERSION}`;
export const TYPESCRIPT_REPOSITORY = "https://github.com/microsoft/TypeScript.git";
export const DEFAULT_TYPESCRIPT_SOURCE_DIR = `target/typescript-source-${TYPESCRIPT_VERSION}`;
export const UPSTREAM_SOURCE_MANIFEST = "docs/upstream-source-manifest.json";

export function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

export function verifyInstalledTypeScript(runtimeVersion) {
  const packageJson = readJson("node_modules/typescript/package.json");
  if (
    packageJson.version !== TYPESCRIPT_VERSION ||
    packageJson.gitHead !== TYPESCRIPT_GIT_HEAD
  ) {
    throw new Error(
      `installed TypeScript does not match ${TYPESCRIPT_VERSION} (${TYPESCRIPT_GIT_HEAD})`,
    );
  }
  if (runtimeVersion !== undefined && runtimeVersion !== TYPESCRIPT_VERSION) {
    throw new Error(
      `expected TypeScript runtime ${TYPESCRIPT_VERSION}, found ${runtimeVersion}`,
    );
  }
}

export function sha256(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

export function countLines(buffer) {
  let count = 0;
  for (const byte of buffer) {
    if (byte === 0x0a) {
      count++;
    }
  }
  return count;
}

export function listFilesRecursively(directory) {
  const files = [];
  const stack = [directory];
  while (stack.length > 0) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true })
      .sort((left, right) => left.name.localeCompare(right.name));
    for (let index = entries.length - 1; index >= 0; index--) {
      const entry = entries[index];
      const entryPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(entryPath);
      } else if (entry.isFile()) {
        files.push(entryPath);
      }
    }
  }
  return files.sort();
}

export function compilerSourcePaths(sourceDirectory) {
  return listFilesRecursively(path.join(sourceDirectory, "src", "compiler"))
    .map((filePath) => path.relative(sourceDirectory, filePath).split(path.sep).join("/"));
}

export function manifestEntry(sourceDirectory, relativePath) {
  const contents = fs.readFileSync(path.join(sourceDirectory, relativePath));
  return {
    path: relativePath,
    lines: countLines(contents),
    sha256: sha256(contents),
  };
}
