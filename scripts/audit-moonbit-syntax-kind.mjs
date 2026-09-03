#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";

import { parseMode } from "./audit-support.mjs";

const AUDIT_PATH = "docs/upstream-audit/syntax-kind.tsv";
const NAMES_PATH = "syntax_kind_names.mbt";
const MARKERS_PATH = "syntax_kind_markers.mbt";

function parseTsv() {
  const lines = fs.readFileSync(AUDIT_PATH, "utf8").trimEnd().split("\n");
  const headers = lines[0].split("\t");
  return lines.slice(1).map((line) => {
    const values = line.split("\t");
    return Object.fromEntries(headers.map((header, index) => [header, values[index] ?? ""]));
  });
}

function functionBlock(source, name) {
  const start = source.indexOf(`pub fn SyntaxKind::${name}`);
  if (start < 0) {
    throw new Error(`missing SyntaxKind::${name}`);
  }
  const end = source.indexOf("\n///|", start + 1);
  return source.slice(start, end < 0 ? source.length : end);
}

function stringArms(block) {
  const result = new Map();
  for (const match of block.matchAll(/^\s*(\d+)\s*=>\s*"([^"]+)"\s*$/gm)) {
    const value = Number(match[1]);
    if (result.has(value)) {
      throw new Error(`duplicate string arm for SyntaxKind ${value}`);
    }
    result.set(value, match[2]);
  }
  return result;
}

function arrayArms(block) {
  const result = new Map();
  for (const match of block.matchAll(/^\s*(\d+)\s*=>\s*\[([\s\S]*?)\]\s*$/gm)) {
    const value = Number(match[1]);
    if (result.has(value)) {
      throw new Error(`duplicate array arm for SyntaxKind ${value}`);
    }
    result.set(value, [...match[2].matchAll(/"([^"]+)"/g)].map((item) => item[1]));
  }
  return result;
}

function splitNames(value) {
  return value === "" ? [] : value.split(", ");
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-moonbit-syntax-kind.mjs --verify",
  );
  const rows = parseTsv();
  assert.equal(rows.length, 359);
  const namesSource = fs.readFileSync(NAMES_PATH, "utf8");
  const markersSource = fs.readFileSync(MARKERS_PATH, "utf8");
  const runtime = stringArms(functionBlock(namesSource, "runtime_name"));
  const declarationExceptions = arrayArms(
    functionBlock(namesSource, "declaration_names"),
  );
  const markers = arrayArms(
    functionBlock(markersSource, "classification_markers"),
  );
  assert.equal(runtime.size, 359, "runtime_name must contain exactly 359 explicit arms");

  for (const row of rows) {
    const value = Number(row.value);
    assert.equal(runtime.get(value), row.runtime_reverse_name, `runtime name ${value}`);
    const actualDeclarations = declarationExceptions.get(value) ?? [runtime.get(value)];
    assert.deepEqual(
      actualDeclarations,
      splitNames(row.declaration_names),
      `declaration names ${value}`,
    );
    assert.deepEqual(
      markers.get(value) ?? [],
      splitNames(row.classification_markers),
      `classification markers ${value}`,
    );
  }
  console.log(
    "verified all 359 hand-written MoonBit SyntaxKind runtime names, declaration aliases, and classification markers",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
