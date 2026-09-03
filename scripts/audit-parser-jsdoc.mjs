#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

import ts from "typescript";

import {
  assert,
  assertDeepEqual,
  assertEqual,
  parseMode,
  readTsv as parseTsv,
  splitList,
} from "./audit-support.mjs";
import {
  DEFAULT_TYPESCRIPT_SOURCE_DIR,
  verifyInstalledTypeScript,
} from "./upstream-config.mjs";

const AUDIT_PATH = "docs/upstream-audit/parser-jsdoc.tsv";
const FIXTURE_DIRECTORY = "fixtures/jsdoc";
const TEST_PATH = "parser_jsdoc_wbtest.mbt";

function functionNames(source) {
  return new Set(
    [...source.matchAll(/^\s*(?:export )?function ([A-Za-z_][A-Za-z0-9_]*)/gm)]
      .map((match) => match[1]),
  );
}

function verifyTraceability() {
  const audit = parseTsv(AUDIT_PATH);
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
    "audit headers",
  );
  assertDeepEqual(
    audit.rows.map((row) => row.contract),
    [
      "isolated_and_comment_lifecycle",
      "comment_text_and_indentation",
      "links_and_name_references",
      "jsdoc_type_syntax",
      "tag_dispatch_and_simple_tags",
      "type_like_class_and_import_tags",
      "parameter_property_and_nested_literals",
      "typedef_callback_overload_template",
      "attachment_modes_and_diagnostic_channels",
    ],
    "contract order",
  );
  const sourceFiles = [
    `${DEFAULT_TYPESCRIPT_SOURCE_DIR}/src/compiler/parser.ts`,
    `${DEFAULT_TYPESCRIPT_SOURCE_DIR}/src/compiler/scanner.ts`,
    `${DEFAULT_TYPESCRIPT_SOURCE_DIR}/src/compiler/utilities.ts`,
  ];
  const upstreamFunctions = new Set();
  for (const sourceFile of sourceFiles) {
    for (const name of functionNames(fs.readFileSync(sourceFile, "utf8"))) {
      upstreamFunctions.add(name);
    }
  }
  const auditedSymbols = new Set();
  for (const row of audit.rows) {
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
      assert(!auditedSymbols.has(symbol), `duplicate symbol ${symbol}`);
      assert(upstreamFunctions.has(symbol), `stale symbol ${symbol}`);
      auditedSymbols.add(symbol);
    }
  }
  assertEqual(auditedSymbols.size, 64, "upstream helper count");
}

function diagnosticShape(diagnostics) {
  return (diagnostics ?? [])
    .map((diagnostic) =>
      `${diagnostic.code}@${diagnostic.start}:${diagnostic.length}`)
    .join(",");
}

function collectJSDocKinds(node, kinds) {
  if (node.kind >= 310 && node.kind <= 352) kinds.add(node.kind);
  ts.forEachChild(node, (child) => collectJSDocKinds(child, kinds));
}

function visitAttachedJSDoc(node, kinds) {
  for (const document of node.jsDoc ?? []) collectJSDocKinds(document, kinds);
  ts.forEachChild(node, (child) => visitAttachedJSDoc(child, kinds));
}

function verifyFixedFixtures() {
  const expectedFiles = [
    "callback.js",
    "import.js",
    "links.js",
    "overload.js",
    "parameters.js",
    "simple-tags.js",
    "type-tags.js",
    "typedef.js",
    "types.js",
  ];
  const actualFiles = fs.readdirSync(FIXTURE_DIRECTORY)
    .filter((file) => file.endsWith(".js"))
    .sort();
  assertDeepEqual(actualFiles, expectedFiles, "fixed fixture inventory");
  const kinds = new Set();
  for (const file of actualFiles) {
    const source = fs.readFileSync(path.join(FIXTURE_DIRECTORY, file), "utf8");
    const sourceFile = ts.createSourceFile(
      file,
      source,
      ts.ScriptTarget.Latest,
      true,
      ts.ScriptKind.JS,
      ts.JSDocParsingMode.ParseAll,
    );
    assertEqual(sourceFile.parseDiagnostics.length, 0, `${file} parse diagnostics`);
    assertEqual(sourceFile.jsDocDiagnostics?.length ?? 0, 0, `${file} JSDoc diagnostics`);
    visitAttachedJSDoc(sourceFile, kinds);
  }
  assertDeepEqual(
    [...kinds].sort((left, right) => left - right),
    [...Array(43)].map((_, index) => 310 + index),
    "all JSDoc SyntaxKinds",
  );
}

function firstTag(source) {
  const result = ts.parseIsolatedJSDocComment(source);
  assert(result, `missing isolated JSDoc for ${source}`);
  return { result, tag: result.jsDoc.tags[0] };
}

function verifyAliasesAndFields() {
  const fixtures = [
    ["author", 331, " Alice"],
    ["implements", 330, " Foo"],
    ["augments", 329, " Foo"],
    ["extends", 329, " Foo"],
    ["class", 333, ""],
    ["constructor", 333, ""],
    ["public", 334, ""],
    ["private", 335, ""],
    ["protected", 336, ""],
    ["readonly", 337, ""],
    ["override", 338, ""],
    ["deprecated", 332, ""],
    ["this", 344, " {Foo}"],
    ["enum", 341, " {number}"],
    ["arg", 342, " value"],
    ["argument", 342, " value"],
    ["param", 342, " value"],
    ["return", 343, " {string}"],
    ["returns", 343, " {string}"],
    ["template", 346, " T"],
    ["type", 345, " {string}"],
    ["typedef", 347, " Value"],
    ["callback", 339, " Callback"],
    ["overload", 340, ""],
    ["satisfies", 351, " {Value}"],
    ["see", 348, " Value"],
    ["exception", 350, " {Error}"],
    ["throws", 350, " {Error}"],
    ["import", 352, " { Foo } from \"pkg\""],
    ["custom", 328, " text"],
  ];
  for (const [spelling, expectedKind, suffix] of fixtures) {
    const source = `/** @${spelling}${suffix} */`;
    const { result, tag } = firstTag(source);
    assertEqual(tag.kind, expectedKind, `${spelling} kind`);
    assertEqual(tag.tagName.text, spelling, `${spelling} spelling`);
    assertEqual(result.diagnostics.length, 0, `${spelling} diagnostics`);
  }
  const structured = ts.parseIsolatedJSDocComment(
    "/**\r\n * First  \r\n *   second `@notTag` {@link Foo label}\r\n */",
  ).jsDoc;
  assertEqual(structured.comment.pos, 0, "structured comment pos");
  assertEqual(structured.comment.end, 59, "structured comment end");
  assertEqual(structured.comment[0].text, "First  \r\n  second `@notTag` ", "structured text");
  assertEqual(structured.comment[1].kind, 325, "structured link kind");
  assertEqual(structured.comment[1].text, "label", "structured link label");
}

function parseAttached(source, scriptKind, mode) {
  return ts.createSourceFile(
    "fixture.ts",
    source,
    {
      languageVersion: ts.ScriptTarget.Latest,
      jsDocParsingMode: mode,
    },
    true,
    scriptKind,
  );
}

function attachedDocumentCount(sourceFile) {
  let count = 0;
  function visit(node) {
    count += node.jsDoc?.length ?? 0;
    ts.forEachChild(node, visit);
  }
  visit(sourceFile);
  return count;
}

function verifyModesAndDiagnostics() {
  const typed = "/** @type {string} */\nconst value = 1;";
  const modes = [
    ts.JSDocParsingMode.ParseAll,
    ts.JSDocParsingMode.ParseNone,
    ts.JSDocParsingMode.ParseForTypeErrors,
    ts.JSDocParsingMode.ParseForTypeInfo,
  ];
  const expectedTs = [1, 0, 0, 0];
  const expectedJs = [1, 0, 1, 1];
  for (let index = 0; index < modes.length; index++) {
    assertEqual(
      attachedDocumentCount(parseAttached(typed, ts.ScriptKind.TS, modes[index])),
      expectedTs[index],
      `TS JSDoc mode ${index}`,
    );
    assertEqual(
      attachedDocumentCount(parseAttached(typed, ts.ScriptKind.JS, modes[index])),
      expectedJs[index],
      `JS JSDoc mode ${index}`,
    );
  }
  const linked = "/** @see Foo and {@link Bar} */\nconst value = 1;";
  assertEqual(
    attachedDocumentCount(parseAttached(
      linked,
      ts.ScriptKind.TSX,
      ts.JSDocParsingMode.ParseForTypeErrors,
    )),
    1,
    "TSX ParseForTypeErrors @link exception",
  );
  const malformed = "/** @type { */\nconst value = 1;";
  const jsFile = parseAttached(
    malformed,
    ts.ScriptKind.JS,
    ts.JSDocParsingMode.ParseAll,
  );
  assertEqual(diagnosticShape(jsFile.parseDiagnostics), "", "JS main diagnostics");
  assertEqual(
    diagnosticShape(jsFile.jsDocDiagnostics),
    "1110@11:0,1005@12:0",
    "JS JSDoc diagnostics",
  );
  const tsFile = parseAttached(
    malformed,
    ts.ScriptKind.TS,
    ts.JSDocParsingMode.ParseAll,
  );
  assertEqual(diagnosticShape(tsFile.parseDiagnostics), "", "TS main diagnostics");
  assertEqual(tsFile.jsDocDiagnostics, undefined, "TS JSDoc diagnostics presence");
  const isolated = ts.parseIsolatedJSDocComment("/** @type { */");
  assertEqual(
    diagnosticShape(isolated.diagnostics),
    "1110@11:0,1005@12:0",
    "isolated diagnostics",
  );
  assert(isolated.diagnostics.every((diagnostic) => diagnostic.file), "isolated diagnostics lack file");
  const subrangeSource = "xx/** @see Foo */yy";
  const subrange = ts.parseIsolatedJSDocComment(subrangeSource, 2, 15);
  assertEqual(subrange.jsDoc.pos, 2, "isolated subrange pos");
  assertEqual(subrange.jsDoc.end, 17, "isolated subrange end");
}

function verifyMoonBitImplementation() {
  const core = fs.readFileSync("parser_jsdoc.mbt", "utf8");
  const tags = fs.readFileSync("parser_jsdoc_tags.mbt", "utf8");
  const types = fs.readFileSync("parser_jsdoc_types.mbt", "utf8");
  const finish = fs.readFileSync("node_finish.mbt", "utf8");
  const tests = fs.readFileSync(TEST_PATH, "utf8");
  for (const marker of [
    "parse_isolated_jsdoc_comment",
    "_parse_attached_jsdoc_comment",
    "_get_jsdoc_comment_ranges",
    "_parse_jsdoc_comment_worker",
    "_parse_jsdoc_tag_comments",
  ]) {
    assert(core.includes(marker), `missing JSDoc core marker ${marker}`);
  }
  for (const marker of [
    "_parse_jsdoc_parameter_or_property_tag",
    "_parse_jsdoc_typedef_tag",
    "_parse_jsdoc_callback_tag",
    "_parse_jsdoc_overload_tag",
    "_parse_jsdoc_import_tag",
  ]) {
    assert(tags.includes(marker), `missing JSDoc tag marker ${marker}`);
  }
  for (const marker of [
    "_parse_jsdoc_type_expression",
    "_parse_jsdoc_function_type",
    "_parse_jsdoc_name_reference",
  ]) {
    assert(types.includes(marker), `missing JSDoc type marker ${marker}`);
  }
  assert(
    finish.includes("self.context_flags = flags"),
    "finish state does not preserve NodeFlags.JSDoc",
  );
  for (const name of [
    "all JSDoc kinds smoke",
    "tag aliases preserve spelling and select exact kinds",
    "comment text backticks links and tag fields are exact",
    "isolated subranges flags and parent completion are exact",
    "JSDoc parsing modes match JS and TS behavior",
    "attached and isolated diagnostics stay in separate channels",
    "duplicate and child-tag diagnostics retain related information",
  ]) {
    assert(tests.includes(`test ${JSON.stringify(name)} {`), `missing white-box test ${name}`);
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-parser-jsdoc.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  verifyTraceability();
  verifyFixedFixtures();
  verifyAliasesAndFields();
  verifyModesAndDiagnostics();
  verifyMoonBitImplementation();
  console.log(
    "verified 64 helpers, all 43 JSDoc kinds, aliases, modes, attachment, and diagnostic channels",
  );
}

main(process.argv.slice(2));
