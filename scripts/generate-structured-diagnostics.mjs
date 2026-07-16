#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

import ts from "typescript";

import { parseMode } from "./audit-support.mjs";
import {
  createReferenceSourceFile,
  diagnosticRecords,
} from "./ts-reference.mjs";
import { verifyInstalledTypeScript } from "./upstream-config.mjs";

const MANIFEST_PATH = "docs/corpus-manifest.jsonl";
const REFERENCE_ROOT = "references/diagnostics";

function readManifest() {
  return fs.readFileSync(MANIFEST_PATH, "utf8")
    .split("\n")
    .filter((line) => line !== "")
    .map((line, index) => {
      const entry = JSON.parse(line);
      if (
        typeof entry.input !== "string" ||
        typeof entry.structured_diagnostics_reference !== "string"
      ) {
        throw new Error(`${MANIFEST_PATH}:${index + 1}: invalid reference entry`);
      }
      if (!entry.structured_diagnostics_reference.startsWith(`${REFERENCE_ROOT}/`)) {
        throw new Error(
          `${MANIFEST_PATH}:${index + 1}: diagnostics reference escapes ${REFERENCE_ROOT}`,
        );
      }
      return entry;
    });
}

function expectedContents(entry) {
  const sourceText = fs.readFileSync(entry.input, "utf8");
  const sourceFile = createReferenceSourceFile(entry.input, sourceText);
  let output = "";
  for (const record of diagnosticRecords(sourceFile)) {
    output += `${JSON.stringify(record)}\n`;
  }
  return output;
}

function listFiles(directory) {
  if (!fs.existsSync(directory)) {
    return [];
  }
  const files = [];
  const stack = [directory];
  while (stack.length > 0) {
    const current = stack.pop();
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const entryPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(entryPath);
      } else if (entry.isFile()) {
        files.push(entryPath.split(path.sep).join("/"));
      }
    }
  }
  return files.sort();
}

function main(argv) {
  const mode = parseMode(
    argv,
    ["write", "verify"],
    "usage: node scripts/generate-structured-diagnostics.mjs <--write|--verify>",
  );
  verifyInstalledTypeScript(ts.version);
  const entries = readManifest();
  const expectedPaths = entries
    .map((entry) => entry.structured_diagnostics_reference)
    .sort();
  if (new Set(expectedPaths).size !== expectedPaths.length) {
    throw new Error("structured diagnostics reference paths are not unique");
  }

  let recordCount = 0;
  let byteCount = 0;
  for (const entry of entries) {
    const output = expectedContents(entry);
    recordCount += output === "" ? 0 : output.split("\n").length - 1;
    byteCount += Buffer.byteLength(output);
    const referencePath = entry.structured_diagnostics_reference;
    if (mode === "write") {
      fs.mkdirSync(path.dirname(referencePath), { recursive: true });
      fs.writeFileSync(referencePath, output);
    } else if (!fs.existsSync(referencePath)) {
      throw new Error(`missing structured diagnostics reference: ${referencePath}`);
    } else {
      const actual = fs.readFileSync(referencePath, "utf8");
      if (actual !== output) {
        throw new Error(`stale structured diagnostics reference: ${referencePath}`);
      }
    }
  }

  const actualPaths = listFiles(REFERENCE_ROOT);
  if (JSON.stringify(actualPaths) !== JSON.stringify(expectedPaths)) {
    const expectedSet = new Set(expectedPaths);
    const actualSet = new Set(actualPaths);
    const missing = expectedPaths.filter((file) => !actualSet.has(file));
    const extra = actualPaths.filter((file) => !expectedSet.has(file));
    throw new Error(
      `diagnostics reference file set mismatch: missing=${JSON.stringify(missing)} extra=${JSON.stringify(extra)}`,
    );
  }
  console.log(
    `${mode === "write" ? "wrote" : "verified"} ${entries.length} diagnostics references ` +
      `(${recordCount} records, ${byteCount} bytes) with TypeScript ${ts.version}`,
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
