#!/usr/bin/env node

import fs from "node:fs";
import ts from "typescript";

import {
  assertEqual,
  parseMode,
  parseTsvText as parseTsv,
} from "./audit-support.mjs";
import { verifyInstalledTypeScript } from "./upstream-config.mjs";

const AUDIT_PATH = "docs/upstream-audit/diagnostics.tsv";
const IMPLEMENTATION_PATH = "diagnostic_catalog.mbt";
const TEST_PATH = "diagnostic_wbtest.mbt";
const COMPLETE_STATUS = "complete";

function parseArguments(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-diagnostics.mjs --verify",
  );
}

function verifyRuntimeBehavior() {
  assertEqual(
    ts.formatStringFromArgs("a{10}b{0}c{x}", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
    "a10b0c{x}",
    "diagnostic placeholder formatting",
  );
  const leaf = ts.chainDiagnosticMessages(
    undefined,
    ts.Diagnostics.Identifier_expected,
  );
  const middle = ts.chainDiagnosticMessages(
    leaf,
    ts.Diagnostics.Unexpected_token,
  );
  const sibling = ts.chainDiagnosticMessages(
    undefined,
    ts.Diagnostics.Expression_expected,
  );
  const head = ts.chainDiagnosticMessages(
    [middle, sibling],
    ts.Diagnostics._0_expected,
    ";",
  );
  assertEqual(
    ts.flattenDiagnosticMessageText(head, "\n"),
    "';' expected.\n  Unexpected token.\n    Identifier expected.\n  Expression expected.",
    "diagnostic message-chain flattening",
  );

  const sourceText = "A😀B";
  const detached = ts.createDetachedDiagnostic(
    "unicode.ts",
    sourceText,
    1,
    99,
    ts.Diagnostics.Unterminated_string_literal,
  );
  assertEqual(detached.length, 3, "detached diagnostic UTF-16 clipping");
  const sameFile = ts.createDetachedDiagnostic(
    "unicode.ts",
    sourceText,
    0,
    1,
    ts.Diagnostics.Identifier_expected,
  );
  const otherFile = ts.createDetachedDiagnostic(
    "other.ts",
    "Z",
    0,
    1,
    ts.Diagnostics.Unexpected_token,
  );
  ts.addRelatedInfo(detached, sameFile, otherFile);
  const sourceFile = ts.createSourceFile(
    "unicode.ts",
    sourceText,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS,
  );
  const attached = ts.attachFileToDiagnostics([detached], sourceFile)[0];
  assertEqual(attached.file, sourceFile, "attached diagnostic SourceFile");
  assertEqual(
    attached.relatedInformation[0].file,
    sourceFile,
    "same-file related diagnostic attachment",
  );
  assertEqual(
    attached.relatedInformation[1].file,
    undefined,
    "other-file related diagnostic preservation",
  );
  assertEqual(
    attached.relatedInformation[1].fileName,
    "other.ts",
    "other-file detached filename preservation",
  );
}

function placeholderCount(message) {
  const indexes = [...message.matchAll(/\{(\d+)\}/g)].map((match) =>
    Number.parseInt(match[1], 10),
  );
  return indexes.length === 0 ? 0 : Math.max(...indexes) + 1;
}

function runtimeEntry(row) {
  const name = row.upstream_symbol.slice("Diagnostics.".length);
  const entry = ts.Diagnostics[name];
  if (!entry) throw new Error(`missing runtime diagnostic ${row.upstream_symbol}`);
  const category = ts.DiagnosticCategory[entry.category];
  const expected = {
    symbol: row.upstream_symbol,
    key: entry.key,
    category,
    code: entry.code,
    message: entry.message,
    placeholderCount: placeholderCount(entry.message),
  };
  if (
    String(expected.code) !== row.code ||
    expected.category !== row.category ||
    expected.message !== row.message ||
    String(expected.placeholderCount) !== row.placeholder_count
  ) {
    throw new Error(`${row.upstream_symbol} audit row differs from ts.Diagnostics`);
  }
  return expected;
}

function parseMoonBitCatalog(source) {
  const string = `("(?:\\\\.|[^"\\\\])*")`;
  const pattern = new RegExp(
    String.raw`(\d+)\s*=>\s*_make_diagnostic_message\(\s*${string}\s*,\s*${string}\s*,\s*DiagnosticCategory::(warning|error|suggestion|message)\(\)\s*,\s*(\d+)\s*,\s*${string}\s*,\s*(\d+)\s*,?\s*\)`,
    "g",
  );
  const entries = new Map();
  for (const match of source.matchAll(pattern)) {
    const armCode = Number.parseInt(match[1], 10);
    const entry = {
      symbol: JSON.parse(match[2]),
      key: JSON.parse(match[3]),
      category: match[4][0].toUpperCase() + match[4].slice(1),
      code: Number.parseInt(match[5], 10),
      message: JSON.parse(match[6]),
      placeholderCount: Number.parseInt(match[7], 10),
    };
    if (entries.has(armCode)) throw new Error(`duplicate MoonBit diagnostic ${armCode}`);
    if (armCode !== entry.code) throw new Error(`catalog arm/code mismatch for ${armCode}`);
    entries.set(armCode, entry);
  }
  return entries;
}

function assertEntry(expected, actual) {
  if (!actual) throw new Error(`${expected.symbol} has no MoonBit catalog entry`);
  for (const field of ["symbol", "key", "category", "code", "message", "placeholderCount"]) {
    if (actual[field] !== expected[field]) {
      throw new Error(
        `${expected.symbol} ${field} expected ${JSON.stringify(expected[field])}, ` +
          `got ${JSON.stringify(actual[field])}`,
      );
    }
  }
}

function main(argv) {
  parseArguments(argv);
  verifyInstalledTypeScript(ts.version);
  verifyRuntimeBehavior();
  const audit = parseTsv(fs.readFileSync(AUDIT_PATH, "utf8"));
  if (audit.rows.length !== 148) {
    throw new Error(`expected 148 diagnostic rows, found ${audit.rows.length}`);
  }
  const symbols = new Set(audit.rows.map((row) => row.upstream_symbol));
  const codes = new Set(audit.rows.map((row) => row.code));
  if (symbols.size !== 148 || codes.size !== 148) {
    throw new Error("diagnostic audit contains duplicate symbols or codes");
  }
  const entries = audit.rows.map(runtimeEntry);
  const reachabilityKinds = new Set([
    "scanner_public_parser",
    "public_parser",
    "scanner_report_errors_only",
    "json_wrapper",
  ]);
  for (const row of audit.rows) {
    for (const reachability of row.reachability.split(", ")) {
      if (!reachabilityKinds.has(reachability)) {
        throw new Error(`${row.upstream_symbol} has unknown reachability ${reachability}`);
      }
    }
    if (!row.source_locations) {
      throw new Error(`${row.upstream_symbol} has no call-site classification`);
    }
  }

  const actual = parseMoonBitCatalog(
    fs.readFileSync(IMPLEMENTATION_PATH, "utf8"),
  );
  if (actual.size !== 148) {
    throw new Error(`expected 148 MoonBit catalog entries, found ${actual.size}`);
  }
  for (const entry of entries) assertEntry(entry, actual.get(entry.code));
  for (const row of audit.rows) {
    if (
      row.moonbit_implementation !== IMPLEMENTATION_PATH ||
      row.test_location !== TEST_PATH ||
      row.status !== COMPLETE_STATUS
    ) {
      throw new Error(`${row.upstream_symbol} has stale progress columns`);
    }
  }
  const tests = fs.readFileSync(TEST_PATH, "utf8");
  for (const contract of [
    "148-entry diagnostic catalog",
    "diagnostic formatting and message chains",
    "detached attached and related diagnostics",
    "parse error suppression is adjacent only",
  ]) {
    if (!tests.includes(`test ${JSON.stringify(contract)}`)) {
      throw new Error(`missing MoonBit diagnostic contract test: ${contract}`);
    }
  }
  console.log(
    "verified 148/148 diagnostics, English templates, placeholders, reachability, and tests",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
