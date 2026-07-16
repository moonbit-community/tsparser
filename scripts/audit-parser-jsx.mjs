#!/usr/bin/env node

import fs from "node:fs";

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

const PARSER_SOURCE_PATH =
  `${DEFAULT_TYPESCRIPT_SOURCE_DIR}/src/compiler/parser.ts`;
const AUDIT_PATH = "docs/upstream-audit/parser-jsx-tsx.tsv";
const TEST_PATH = "parser_jsx_wbtest.mbt";

function verifyTraceability(parserSource) {
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
      "scanner_mode_switches",
      "element_tree_and_recovery",
      "tag_names",
      "attributes_and_expressions",
      "text_nodes",
      "tsx_less_than_ambiguity",
    ],
    "contract order",
  );
  const upstreamFunctions = new Set(
    [...parserSource.matchAll(/^\s*(?:export )?function ([A-Za-z_][A-Za-z0-9_]*)/gm)]
      .map((match) => match[1]),
  );
  const symbols = new Set();
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
      assert(!symbols.has(symbol), `duplicate symbol ${symbol}`);
      assert(upstreamFunctions.has(symbol), `stale symbol ${symbol}`);
      symbols.add(symbol);
    }
  }
  assertEqual(symbols.size, 28, "upstream helper count");
}

function parse(source, scriptKind = ts.ScriptKind.TSX, fileName = "fixture.tsx") {
  return ts.createSourceFile(
    fileName,
    source,
    ts.ScriptTarget.Latest,
    true,
    scriptKind,
  );
}

function expression(file) {
  return file.statements[0]?.expression;
}

function diagnosticShape(file) {
  return file.parseDiagnostics
    .map((diagnostic) =>
      `${diagnostic.code}@${diagnostic.start}:${diagnostic.length}`)
    .join(",");
}

function arrayShape(root) {
  const result = [];
  function visitArray(array) {
    result.push(
      `A@${array.pos - root.pos}:${array.end - root.pos}:` +
        (array.hasTrailingComma ? "1" : "0"),
    );
    for (const node of array) visit(node);
  }
  function visit(node) {
    result.push(`N${node.kind}@${node.pos - root.pos}:${node.end - root.pos}`);
    ts.forEachChild(node, visit, visitArray);
  }
  visit(root);
  return result.join(",");
}

function collectKinds(node, kinds) {
  kinds.add(node.kind);
  ts.forEachChild(node, (child) => collectKinds(child, kinds));
}

function verifyExactTreesAndKinds() {
  const fixtures = [
    ["<div />", "N286@0:7,N80@1:4,N293@4:4,A@4:4:0"],
    [
      "<this.foo></this.foo>",
      "N285@0:21,N287@0:10,N212@1:9,N110@1:5,N80@6:9,N293@9:9,A@9:9:0,A@10:10:0,N288@10:21,N212@12:20,N110@12:16,N80@17:20",
    ],
    [
      "<ns:tag></ns:tag>",
      "N285@0:17,N287@0:8,N296@1:7,N80@1:3,N80@4:7,N293@7:7,A@7:7:0,A@8:8:0,N288@8:17,N296@10:16,N80@10:12,N80@13:16",
    ],
    [
      "<div></div><span></span>",
      "N227@0:24,N285@0:11,N287@0:5,N80@1:4,N293@4:4,A@4:4:0,A@5:5:0,N288@5:11,N80@7:10,N28@11:11,N285@11:24,N287@11:17,N80@12:16,N293@16:16,A@16:16:0,A@17:17:0,N288@17:24,N80@19:23",
    ],
    [
      "<>a\n  <A.B<T> {...p} />&amp;</>",
      "N289@0:31,N290@0:2,A@2:28:0,N12@2:6,N286@6:23,N212@7:10,N80@7:8,N80@9:10,A@11:12:0,N184@11:12,N80@11:12,N293@13:20,A@13:20:0,N294@13:20,N80@18:19,N12@23:28,N291@28:31",
    ],
    [
      "<a b=\"x\" c={v} d={}>text{x}</a>",
      "N285@0:31,N287@0:20,N80@1:2,N293@2:19,A@2:19:0,N292@2:8,N80@2:4,N11@5:8,N292@8:14,N80@8:10,N295@11:14,N80@12:13,N292@14:19,N80@14:16,N295@17:19,A@20:27:0,N12@20:24,N295@24:27,N80@25:26,N288@27:31,N80@29:30",
    ],
  ];
  const kinds = new Set();
  for (const [source, expected] of fixtures) {
    const file = parse(source);
    const root = expression(file);
    assert(root, `missing expression for ${source}`);
    assertEqual(arrayShape(root), expected, `JSX tree for ${source}`);
    if (source.includes("</div><span")) {
      assertEqual(diagnosticShape(file), "2657@0:24", "adjacent roots diagnostic");
    } else {
      assertEqual(file.parseDiagnostics.length, 0, `unexpected diagnostic for ${source}`);
    }
    collectKinds(root, kinds);
  }
  assertDeepEqual(
    [...Array(12)].map((_, index) => 285 + index)
      .filter((kind) => kinds.has(kind)),
    [...Array(12)].map((_, index) => 285 + index),
    "all JSX SyntaxKinds",
  );
}

function verifyRecoveryAndText() {
  const diagnostics = [
    ["<div><span></div>", "17008@6:4"],
    ["<div></span>", "17002@7:4"],
    ["<></x>", "17015@4:1,1109@6:0"],
    ["<><x></>", "1003@7:1,17014@0:2,1005@8:0"],
    ["<a\\u0062></ab>", "17021@1:7"],
    ["<a x= y />", "1145@6:1"],
    [
      "<div>&amp; &bogus; # } ></div>",
      "1381@21:1,1382@23:1,1381@21:1,1382@23:1",
    ],
  ];
  for (const [source, expected] of diagnostics) {
    assertEqual(diagnosticShape(parse(source)), expected, `JSX recovery for ${source}`);
  }
  const whitespace = expression(parse("<>\n   \n</>")).children[0];
  assertEqual(whitespace.text, "\n   \n", "all-whitespace text value");
  assertEqual(
    whitespace.containsOnlyTriviaWhiteSpaces,
    true,
    "all-whitespace text marker",
  );
  const raw = expression(parse("<a s=\"&amp;\">&amp; &bogus;</a>"));
  assertEqual(raw.openingElement.attributes.properties[0].initializer.text, "&amp;", "raw attribute entity");
  assertEqual(raw.children[0].text, "&amp; &bogus;", "raw child entities");
}

function verifyLessThanAmbiguity() {
  const kinds = [
    ["<T,>(x:T)=>x", 220],
    ["<T extends U>(x:T)=>x", 220],
    ["<const T,>(x:T)=>x", 220],
    ["<T = U>(x:T)=>x", 220],
    ["f<T>(x)", 214],
    ["<T extends={x}></T>", 285],
    ["<T>(x)", 285],
    ["+ <A/>", 225],
  ];
  for (const [source, expectedKind] of kinds) {
    const file = parse(source);
    assertEqual(expression(file).kind, expectedKind, `TSX ambiguity for ${source}`);
  }
  assertEqual(
    expression(parse("<Comp<T> p />", ts.ScriptKind.JSX, "fixture.jsx")).kind,
    227,
    "JSX must not accept opening-element type arguments",
  );
  assertEqual(
    expression(parse("<Comp<T> p />")).kind,
    286,
    "TSX accepts opening-element type arguments",
  );
  assertEqual(
    expression(parse("<T,>(x)=>x", ts.ScriptKind.JSX, "fixture.jsx")).kind,
    220,
    "generic arrow lookahead wins in JSX ScriptKind",
  );
}

function verifyMoonBitImplementation(testSource) {
  const implementation = fs.readFileSync("parser_jsx.mbt", "utf8");
  const unary = fs.readFileSync("parser_expression_unary.mbt", "utf8");
  const arrow = fs.readFileSync("parser_expression_functions.mbt", "utf8");
  for (const marker of [
    "_parse_jsx_element_or_self_closing_element_or_fragment",
    "_parse_jsx_children",
    "_re_scan_jsx_text",
    "_parse_jsx_attribute_value",
    "_restructure_jsx_children",
    "_parser_jsx_tag_names_are_equivalent",
  ]) {
    assert(implementation.includes(marker), `missing JSX implementation marker ${marker}`);
  }
  assert(unary.includes("must_be_unary=true"), "unary JSX recovery guard is absent");
  assert(
    arrow.includes("self.language_variant == LanguageVariant::jsx()"),
    "TSX generic-arrow override is absent",
  );
  for (const name of [
    "JSX elements fragments attributes children and ranges match TypeScript",
    "JSX recovery and TSX ambiguity match TypeScript",
    "JSX text fields and scanner diagnostics match TypeScript",
    "TSX generic arrow JSX and type argument ambiguity match TypeScript",
    "JSX ScriptKind disables opening-element type arguments",
    "JSX malformed closing fragments unicode and attributes recover exactly",
  ]) {
    assert(testSource.includes(`test ${JSON.stringify(name)} {`), `missing white-box test ${name}`);
  }
  const manifest = fs.readFileSync("docs/corpus-manifest.jsonl", "utf8")
    .trimEnd().split("\n").map((line) => JSON.parse(line));
  assertEqual(
    manifest.filter((entry) => entry.input.endsWith(".tsx")).length,
    118,
    "TSX corpus inventory",
  );
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-parser-jsx.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  const parserSource = fs.readFileSync(PARSER_SOURCE_PATH, "utf8");
  const testSource = fs.readFileSync(TEST_PATH, "utf8");
  verifyTraceability(parserSource);
  verifyExactTreesAndKinds();
  verifyRecoveryAndText();
  verifyLessThanAmbiguity();
  verifyMoonBitImplementation(testSource);
  console.log(
    "verified 28 parser helpers, 12 JSX kinds, scanner-mode transitions, recovery, and TSX less-than ambiguity",
  );
}

main(process.argv.slice(2));
