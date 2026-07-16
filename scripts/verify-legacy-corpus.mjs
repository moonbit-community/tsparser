#!/usr/bin/env node

import fs from "node:fs";

import {
  formatDiagnostic,
  parseSourceFile,
  serializeNode,
} from "./ts-parse-baseline.mjs";

const MANIFEST_PATH = "docs/corpus-manifest.jsonl";

function main() {
  const entries = fs.readFileSync(MANIFEST_PATH, "utf8")
    .split("\n")
    .filter((line) => line !== "")
    .map(JSON.parse);
  let astFiles = 0;
  let streamingAstFiles = 0;
  let diagnosticFiles = 0;
  for (const entry of entries) {
    const sourceFile = parseSourceFile(entry.input);
    const errors = sourceFile.parseDiagnostics
      .map((diagnostic) => formatDiagnostic(sourceFile, diagnostic))
      .join("\n");
    const expectedErrors = errors === "" ? "" : `${errors}\n`;
    const actualErrors = fs.readFileSync(entry.legacy_errors.path, "utf8");
    if (actualErrors !== expectedErrors) {
      throw new Error(`legacy diagnostics projection changed: ${entry.input}`);
    }
    diagnosticFiles++;

    if (entry.legacy_ast === null) {
      streamingAstFiles++;
      continue;
    }
    const expectedAst = `${JSON.stringify(serializeNode(sourceFile, sourceFile), null, 2)}\n`;
    const actualAst = fs.readFileSync(entry.legacy_ast.path, "utf8");
    if (actualAst !== expectedAst) {
      throw new Error(`legacy AST projection changed: ${entry.input}`);
    }
    astFiles++;
  }
  if (entries.length !== 6541 || astFiles !== 6530 || streamingAstFiles !== 11) {
    throw new Error(
      `legacy corpus totals changed: inputs=${entries.length} AST=${astFiles} streaming=${streamingAstFiles}`,
    );
  }
  console.log(
    `verified ${astFiles} committed legacy AST projections, ${streamingAstFiles} streaming AST entries, and ${diagnosticFiles} legacy diagnostics projections`,
  );
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
