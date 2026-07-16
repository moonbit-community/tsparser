#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { performance } from "node:perf_hooks";

import ts from "typescript";

function scriptKindForPath(filePath) {
  return path.extname(filePath).toLowerCase() === ".tsx"
    ? ts.ScriptKind.TSX
    : ts.ScriptKind.TS;
}

const [inputPath] = process.argv.slice(2);
if (!inputPath) {
  console.error("usage: node scripts/measure-pressure-fixture.mjs <input.ts|tsx>");
  process.exitCode = 1;
} else {
  const sourceText = fs.readFileSync(inputPath, "utf8");
  const parseStart = performance.now();
  const sourceFile = ts.createSourceFile(
    path.resolve(inputPath),
    sourceText,
    ts.ScriptTarget.Latest,
    false,
    scriptKindForPath(inputPath),
  );
  const parseEnd = performance.now();
  const stack = [sourceFile];
  let nodeCount = 0;
  while (stack.length > 0) {
    const node = stack.pop();
    nodeCount++;
    ts.forEachChild(node, (child) => {
      stack.push(child);
    });
  }
  const traversalEnd = performance.now();
  console.log(JSON.stringify({
    input: path.basename(inputPath),
    bytes: Buffer.byteLength(sourceText, "utf8"),
    nodes: nodeCount,
    diagnostics: sourceFile.parseDiagnostics.length,
    parse_ms: Math.round((parseEnd - parseStart) * 100) / 100,
    traversal_ms: Math.round((traversalEnd - parseEnd) * 100) / 100,
    rss_kib: Math.ceil(process.memoryUsage.rss() / 1024),
  }));
}
