#!/usr/bin/env node

import fs from "node:fs";

import ts from "typescript";

import {
  assert,
  assertDeepEqual,
  assertEqual,
  parseMode,
  parseTsvText as parseTsv,
  splitList,
} from "./audit-support.mjs";
import {
  DEFAULT_TYPESCRIPT_SOURCE_DIR,
  verifyInstalledTypeScript,
} from "./upstream-config.mjs";
import { scannerRecords } from "./ts-reference.mjs";

const SCANNER_SOURCE_PATH =
  `${DEFAULT_TYPESCRIPT_SOURCE_DIR}/src/compiler/scanner.ts`;
const SCANNER_AUDIT_PATH = "docs/upstream-audit/scanner.tsv";
const REGEXP_TABLE_PATH = "scanner_regexp_tables.mbt";
const UNICODE_TABLE_PATH = "scanner_unicode_tables.mbt";

function verifyScannerTraceability(scannerSource) {
  const audit = parseTsv(fs.readFileSync(SCANNER_AUDIT_PATH, "utf8"));
  assertDeepEqual(
    audit.headers,
    [
      "contract",
      "upstream_symbols",
      "upstream_location",
      "moonbit_implementation",
      "test_location",
      "status",
      "notes",
    ],
    "scanner audit headers",
  );
  assertEqual(audit.rows.length, 19, "scanner audit contract count");
  const contracts = new Set();
  const auditedSymbols = new Set();
  for (const row of audit.rows) {
    assert(!contracts.has(row.contract), `duplicate scanner contract ${row.contract}`);
    contracts.add(row.contract);
    assertEqual(row.status, "complete", `${row.contract} status`);
    assert(row.upstream_location, `${row.contract} has no upstream location`);
    assert(row.notes, `${row.contract} has no design note`);
    for (const implementation of splitList(row.moonbit_implementation)) {
      assert(fs.existsSync(implementation), `${row.contract} missing ${implementation}`);
    }
    for (const test of splitList(row.test_location)) {
      assert(fs.existsSync(test), `${row.contract} missing ${test}`);
    }
    for (const symbol of splitList(row.upstream_symbols)) {
      assert(!auditedSymbols.has(symbol), `duplicate scanner symbol ${symbol}`);
      auditedSymbols.add(symbol);
    }
  }

  const upstreamSymbols = new Set(
    [...scannerSource.matchAll(/^\s+function ([A-Za-z_][A-Za-z0-9_]*)/gm)]
      .map((match) => match[1]),
  );
  assertEqual(upstreamSymbols.size, 95, "pinned scanner helper count");
  const missing = [...upstreamSymbols].filter((name) => !auditedSymbols.has(name));
  const extra = [...auditedSymbols].filter((name) => !upstreamSymbols.has(name));
  assertDeepEqual(missing, [], "unaudited upstream scanner helpers");
  assertDeepEqual(extra, [], "stale scanner helper audit rows");
}

function quotedStrings(text) {
  return [...text.matchAll(/"(?:\\.|[^"\\])*"/g)].map((match) =>
    JSON.parse(match[0]),
  );
}

function extractMoonBitStringTable(source, name) {
  const match = source.match(
    new RegExp(
      String.raw`let ${name}\s*:\s*ReadOnlyArray\[String\]\s*=\s*\[([\s\S]*?)\n\]`,
    ),
  );
  if (!match) throw new Error(`missing MoonBit regexp table ${name}`);
  return quotedStrings(match[1]);
}

function extractUpstreamSet(source, pattern, name) {
  const match = source.match(pattern);
  if (!match) throw new Error(`missing upstream regexp table ${name}`);
  return quotedStrings(match[1]);
}

function verifyRegexpPropertyTables(scannerSource) {
  const moonbit = fs.readFileSync(REGEXP_TABLE_PATH, "utf8");
  const propertyBlock = scannerSource.match(
    /const nonBinaryUnicodeProperties = new Map\(Object\.entries\(\{([\s\S]*?)\} as const\)\);/,
  );
  assert(propertyBlock, "missing nonBinaryUnicodeProperties");
  const nonBinary = [...propertyBlock[1].matchAll(/^\s*([A-Za-z_]+):/gm)]
    .map((match) => match[1]);
  const binary = extractUpstreamSet(
    scannerSource,
    /const binaryUnicodeProperties = new Set\(\[([\s\S]*?)\]\);/,
    "binaryUnicodeProperties",
  );
  const binaryStrings = extractUpstreamSet(
    scannerSource,
    /const binaryUnicodePropertiesOfStrings = new Set\(\[([\s\S]*?)\]\);/,
    "binaryUnicodePropertiesOfStrings",
  );
  const generalCategory = extractUpstreamSet(
    scannerSource,
    /General_Category: new Set\(\[([\s\S]*?)\]\),/,
    "General_Category",
  );
  const script = extractUpstreamSet(
    scannerSource,
    /Script: new Set\(\[([\s\S]*?)\]\),/,
    "Script",
  );
  const pairs = [
    ["_regexp_non_binary_property_names", nonBinary, 6],
    ["_regexp_binary_properties", binary, 98],
    ["_regexp_binary_string_properties", binaryStrings, 7],
    ["_regexp_general_category_values", generalCategory, 80],
    ["_regexp_script_values", script, 324],
  ];
  for (const [name, expected, count] of pairs) {
    assertEqual(expected.length, count, `${name} upstream count`);
    assertDeepEqual(
      extractMoonBitStringTable(moonbit, name),
      expected,
      `${name} exact insertion order`,
    );
  }
  assert(
    scannerSource.includes(
      "valuesOfNonBinaryUnicodeProperties.Script_Extensions = valuesOfNonBinaryUnicodeProperties.Script",
    ),
    "Script_Extensions no longer aliases Script upstream",
  );
}

function extractUpstreamIntegerTable(source, name) {
  const match = source.match(new RegExp(String.raw`const ${name} = \[([\s\S]*?)\];`));
  if (!match) throw new Error(`missing upstream Unicode table ${name}`);
  return [...match[1].matchAll(/\d+/g)].map((item) => Number(item[0]));
}

function extractMoonBitIntegerTable(source, name) {
  const match = source.match(
    new RegExp(String.raw`let ${name}\s*:\s*ReadOnlyArray\[Int\]\s*=\s*\[([\s\S]*?)\n\]`),
  );
  if (!match) throw new Error(`missing MoonBit Unicode table ${name}`);
  return [...match[1].matchAll(/\d+/g)].map((item) => Number(item[0]));
}

function verifyUnicodeIdentifierTables(scannerSource) {
  const moonbit = fs.readFileSync(UNICODE_TABLE_PATH, "utf8");
  const tables = [
    ["unicodeES5IdentifierStart", "_unicode_es5_identifier_start"],
    ["unicodeES5IdentifierPart", "_unicode_es5_identifier_part"],
    ["unicodeESNextIdentifierStart", "_unicode_es_next_identifier_start"],
    ["unicodeESNextIdentifierPart", "_unicode_es_next_identifier_part"],
  ];
  let endpoints = 0;
  for (const [upstreamName, moonbitName] of tables) {
    const expected = extractUpstreamIntegerTable(scannerSource, upstreamName);
    const actual = extractMoonBitIntegerTable(moonbit, moonbitName);
    assert(expected.length > 0 && expected.length % 2 === 0, `${upstreamName} ranges`);
    assertDeepEqual(actual, expected, `${moonbitName} exact endpoints`);
    for (let index = 0; index < actual.length; index += 2) {
      assert(actual[index] <= actual[index + 1], `${moonbitName} inverted range`);
      if (index > 0) {
        assert(actual[index] > actual[index - 1], `${moonbitName} unordered ranges`);
      }
    }
    endpoints += actual.length;
  }
  assertEqual(endpoints, 4454, "Unicode identifier endpoint count");
}

function diagnosticText(diagnostic) {
  const argument = diagnostic.arguments.length === 0
    ? "-"
    : String(diagnostic.arguments[0]);
  return `${diagnostic.code}@${diagnostic.start}:${diagnostic.length ?? 0}:${argument}`;
}

function ordinaryDiagnosticSnapshot(text) {
  return [...scannerRecords(text)].at(-1).diagnostics.map(diagnosticText).join(",");
}

function regexpDiagnosticSnapshot(text, target = ts.ScriptTarget.Latest) {
  const diagnostics = [];
  let scanner;
  scanner = ts.createScanner(
    target,
    true,
    ts.LanguageVariant.Standard,
    text,
    (message, length, argument) => {
      diagnostics.push({
        code: message.code,
        start: scanner.getTextPos(),
        length: length ?? 0,
        arguments: argument === undefined ? [] : [argument],
      });
    },
  );
  assertEqual(scanner.scan(), ts.SyntaxKind.SlashToken, `${text} initial slash`);
  assertEqual(
    scanner.reScanSlashToken(true),
    ts.SyntaxKind.RegularExpressionLiteral,
    `${text} regexp rescan`,
  );
  return diagnostics.map(diagnosticText).join(",");
}

function extractRegexpSnapshotCases(testSource) {
  const start = testSource.indexOf('test "scanner full regexp grammar diagnostics"');
  const end = testSource.indexOf("\n///|\ntest ", start + 1);
  assert(start >= 0 && end > start, "missing full regexp grammar test block");
  const block = testSource.slice(start, end);
  const fixturesBlock = block.match(
    /let fixtures\s*:\s*Array\[String\]\s*=\s*\[([\s\S]*?)\n\s*\]/,
  );
  assert(fixturesBlock, "missing regexp fixture array");
  const fixtures = quotedStrings(fixturesBlock[1]);
  const expected = [...block.matchAll(/#\|\s+("(?:\\.|[^"\\])*")\s*,/g)]
    .map((match) => JSON.parse(match[1]))
    .filter((value) => value.includes(" => "));
  assertEqual(expected.length, fixtures.length + 2, "regexp snapshot row count");
  return { fixtures, expected };
}

function verifyRegexpReference() {
  const source = fs.readFileSync("scanner_regexp_wbtest.mbt", "utf8");
  const { fixtures, expected } = extractRegexpSnapshotCases(source);
  const actual = fixtures.map((fixture) =>
    `${fixture} => ${regexpDiagnosticSnapshot(fixture)}`
  );
  actual.push(
    `/a/d@ES5 => ${regexpDiagnosticSnapshot("/a/d", ts.ScriptTarget.ES5)}`,
  );
  actual.push(
    `/(?<x>a)/u@ES2017 => ${regexpDiagnosticSnapshot(
      "/(?<x>a)/u",
      ts.ScriptTarget.ES2017,
    )}`,
  );
  assertDeepEqual(actual, expected, "full regexp diagnostic snapshots");
  assert(
    source.includes('["1513@0:1"]'),
    "validator-only undetermined escape diagnostic is not pinned",
  );
}

function verifyPublicErrorReference() {
  const cases = [
    ['"unterminated', "1002@13:0:-"],
    ["/*", "1010@2:0:-"],
    ["077", "1121@0:3:0o77"],
    ["1e", "1124@2:0:-"],
    ["0xg", "1125@2:0:-"],
    ['"a\\', "1126@3:0:-,1002@3:0:-"],
    ["\u0000", "1127@0:1:-"],
    ["`x", "1160@2:0:-"],
    ["0b2", "1177@2:0:-"],
    ["0o8", "1178@2:0:-"],
    ["<<<<<<< HEAD\n", "1185@0:7:-"],
    ['"\\u{110000}"', "1198@4:6:-"],
    ['"\\u{1x"', "1199@5:0:-"],
    ["1abc", "1351@1:3:-"],
    ["1e2n", "1352@0:4:-"],
    ["1.0n", "1353@0:4:-"],
    ['"\\1"', "1487@1:2:\\x01"],
    ['"\\8"', "1488@1:2:\\8"],
    ["08", "1489@0:2:-"],
    ["�", "1490@0:0:-"],
    ["1__2 1_", "6189@2:1:-,6188@6:1:-"],
    ["x\n#!y", "18026@2:2:-"],
  ];
  for (const [fixture, expected] of cases) {
    assertEqual(
      ordinaryDiagnosticSnapshot(fixture),
      expected,
      `public scanner errors for ${JSON.stringify(fixture)}`,
    );
  }
}

function createContextScanner(text, variant = ts.LanguageVariant.Standard) {
  const diagnostics = [];
  let scanner;
  scanner = ts.createScanner(
    ts.ScriptTarget.Latest,
    true,
    variant,
    text,
    (message, length, argument) => {
      diagnostics.push({
        code: message.code,
        start: scanner.getTextPos(),
        length: length ?? 0,
        arguments: argument === undefined ? [] : [argument],
      });
    },
  );
  return { scanner, diagnostics };
}

function verifyContextualReference() {
  for (const [tagged, expectedValue, expectedErrors] of [
    [true, "\\8", ""],
    [false, "8", "1488@1:2:\\8"],
  ]) {
    const { scanner, diagnostics } = createContextScanner("`\\8`");
    assertEqual(scanner.scan(), ts.SyntaxKind.NoSubstitutionTemplateLiteral, "template scan");
    assertEqual(scanner.getTokenValue(), "\\8", "template initial raw value");
    assertEqual(scanner.getTokenFlags(), 2048, "template invalid escape flag");
    assertEqual(
      scanner.reScanTemplateToken(tagged),
      ts.SyntaxKind.NoSubstitutionTemplateLiteral,
      "template contextual rescan",
    );
    assertEqual(scanner.getTokenValue(), expectedValue, "template contextual value");
    assertEqual(
      diagnostics.map(diagnosticText).join(","),
      expectedErrors,
      "template contextual diagnostics",
    );
  }

  const jsx = createContextScanner("x}y>z", ts.LanguageVariant.JSX);
  assertEqual(jsx.scanner.scanJsxToken(), ts.SyntaxKind.JsxText, "JSX text token");
  assertEqual(jsx.scanner.getTokenValue(), "x}y>z", "JSX text value");
  assertEqual(
    jsx.diagnostics.map(diagnosticText).join(","),
    "1381@1:1:-,1382@3:1:-",
    "JSX text diagnostics",
  );

  const recoveryCases = [
    ["/abc\nrest", 4],
    ["/[abc\nrest", 5],
    ["/abc) tail", 4],
    ["/abc] tail", 4],
    ["/abc} tail", 4],
    ["/abc;   ", 4],
    ["/(abc\nrest", 5],
    ["/{1,2\nrest", 5],
    ["/abc\\\nrest", 5],
  ];
  for (const [fixture, end] of recoveryCases) {
    const context = createContextScanner(fixture);
    context.scanner.scan();
    assertEqual(
      context.scanner.reScanSlashToken(),
      ts.SyntaxKind.RegularExpressionLiteral,
      `${fixture} recovery kind`,
    );
    assertEqual(context.scanner.getTextPos(), end, `${fixture} recovery end`);
    assertEqual(context.scanner.getTokenFlags(), 4, `${fixture} unterminated flag`);
    assertEqual(
      context.diagnostics.map(diagnosticText).join(","),
      `1161@0:${end}:-`,
      `${fixture} recovery diagnostic`,
    );
  }

  const html = ts.createScanner(
    ts.ScriptTarget.Latest,
    false,
    ts.LanguageVariant.Standard,
    "<!--x\n-->y",
  );
  const htmlKinds = [];
  while (true) {
    const kind = html.scan();
    htmlKinds.push(kind);
    if (kind === ts.SyntaxKind.EndOfFileToken) break;
  }
  assertDeepEqual(
    htmlKinds,
    [30, 54, 47, 80, 4, 47, 32, 80, 1],
    "TypeScript 6.0.3 HTML-like comment tokenization",
  );
}

function verifyDirectiveReference() {
  const cases = [
    ["/* @ts-ignore */x", [[0, 16, 1]]],
    ["/* first\n * @ts-expect-error */x", [[9, 31, 0]]],
    ["// @ts-check\n// @ts-nocheck\n// @ts-ignore x\ny", [[28, 43, 1]]],
    ["/* @ts-ignore\n * tail */x", []],
    ["/// @ts-expect-error x\ny", [[0, 22, 0]]],
  ];
  for (const [fixture, expected] of cases) {
    const summary = [...scannerRecords(fixture)].at(-1);
    const actual = summary.comment_directives.map((directive) => [
      directive.range.pos,
      directive.range.end,
      directive.type,
    ]);
    assertDeepEqual(actual, expected, `comment directives for ${JSON.stringify(fixture)}`);
  }
}

function verifySnapshotReference() {
  const scanner = ts.createScanner(
    ts.ScriptTarget.Latest,
    true,
    ts.LanguageVariant.Standard,
    "let alpha = 1",
  );
  assertEqual(scanner.scan(), ts.SyntaxKind.LetKeyword, "snapshot initial token");
  const looked = scanner.lookAhead(() => [scanner.scan(), scanner.getTokenText()]);
  assertDeepEqual(looked, [ts.SyntaxKind.Identifier, "alpha"], "lookahead result");
  assertEqual(scanner.getToken(), ts.SyntaxKind.LetKeyword, "lookahead token restore");
  assertEqual(scanner.getTokenText(), "let", "lookahead text restore");
  const failed = scanner.tryScan(() => {
    scanner.scan();
    return undefined;
  });
  assertEqual(failed, undefined, "failed tryScan result");
  assertEqual(scanner.getToken(), ts.SyntaxKind.LetKeyword, "failed tryScan restore");
  const accepted = scanner.tryScan(() => scanner.scan());
  assertEqual(accepted, ts.SyntaxKind.Identifier, "accepted tryScan result");
  assertEqual(scanner.getToken(), ts.SyntaxKind.Identifier, "accepted tryScan commit");
}

function verifyDiagnosticReachability() {
  const audit = parseTsv(
    fs.readFileSync("docs/upstream-audit/diagnostics.tsv", "utf8"),
  );
  const byCode = new Map(audit.rows.map((row) => [Number(row.code), row]));
  for (const code of [1535, 1536, 1537, 1538]) {
    assertEqual(
      byCode.get(code)?.reachability,
      "scanner_report_errors_only",
      `regexp-only diagnostic ${code} reachability`,
    );
  }
  for (const code of [1125, 1126, 1198, 1487, 1488]) {
    const paths = new Set(byCode.get(code)?.reachability.split(", "));
    assert(paths.has("scanner_public_parser"), `${code} missing public scanner path`);
    assert(paths.has("scanner_report_errors_only"), `${code} missing regexp worker path`);
  }
  for (let code = 1499; code <= 1534; code += 1) {
    const row = byCode.get(code);
    if (row) {
      assert(
        row.reachability.split(", ").includes("scanner_report_errors_only"),
        `${code} is not classified as checker-triggered`,
      );
    }
  }
}

function verifyTestsAndTokenCoverage() {
  const scannerTests = fs.readFileSync("scanner_wbtest.mbt", "utf8");
  const regexpTests = fs.readFileSync("scanner_regexp_wbtest.mbt", "utf8");
  const tokenTests = fs.readFileSync("scanner_token_coverage_wbtest.mbt", "utf8");
  for (const name of [
    "scanner public error families",
    "scanner regexp and contextual rescans",
    "scanner six-field speculation and range restoration",
    "scanner successful try-scan setters ranges and JSDoc asterisks",
    "scanner directive and HTML-like comment reference boundaries",
    "scanner unicode identifiers and ESNext invalid rescan",
    "scanner template tagged escape and JSX text diagnostics",
    "scanner JSDoc token and comment-text modes",
    "scanner ScriptKind and JSDoc parsing-mode gating",
  ]) {
    assert(
      scannerTests.includes(`test ${JSON.stringify(name)}`),
      `missing scanner contract test ${name}`,
    );
  }
  for (const name of [
    "scanner full regexp grammar diagnostics",
    "scanner regexp unterminated recovery and validator-only trailing escape",
  ]) {
    assert(
      regexpTests.includes(`test ${JSON.stringify(name)}`),
      `missing regexp contract test ${name}`,
    );
  }
  assert(
    tokenTests.includes('test "every SyntaxKind token has an audited scanner path"'),
    "missing every-token scanner audit",
  );
  assert(tokenTests.includes("Array::make(167, false)"), "token audit width is not 167");
  assertEqual(ts.SyntaxKind.LastToken, 166, "TypeScript LastToken");
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-scanner.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  const scannerSource = fs.readFileSync(SCANNER_SOURCE_PATH, "utf8");
  verifyScannerTraceability(scannerSource);
  verifyUnicodeIdentifierTables(scannerSource);
  verifyRegexpPropertyTables(scannerSource);
  verifyPublicErrorReference();
  verifyRegexpReference();
  verifyContextualReference();
  verifyDirectiveReference();
  verifySnapshotReference();
  verifyDiagnosticReachability();
  verifyTestsAndTokenCoverage();
  console.log(
    "verified 95 scanner helpers, 4 Unicode tables, 5 regexp property tables, " +
      "167 token paths, contextual rescans, diagnostics, and read-only audits",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
