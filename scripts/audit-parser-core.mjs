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
const CORE_AUDIT_PATH = "docs/upstream-audit/parser-core.tsv";
const CONTEXT_AUDIT_PATH = "docs/upstream-audit/parsing-context.tsv";

function verifyCoreTraceability(parserSource) {
  const audit = parseTsv(CORE_AUDIT_PATH);
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
    "parser-core audit headers",
  );
  assertEqual(audit.rows.length, 12, "parser-core contract count");
  const expectedContracts = [
    "invocation_state",
    "context_flags",
    "diagnostic_and_token_bridge",
    "speculation",
    "expected_tokens_and_asi",
    "missing_semicolon_diagnostics",
    "node_finishing",
    "identifiers",
    "property_names",
    "list_predicates",
    "list_parsing",
    "incremental_reuse_exclusion",
  ];
  assertDeepEqual(
    audit.rows.map((row) => row.contract),
    expectedContracts,
    "parser-core contract order",
  );
  const upstreamFunctions = new Set(
    [...parserSource.matchAll(/^    function ([A-Za-z_][A-Za-z0-9_]*)/gm)]
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
      assert(!symbols.has(symbol), `duplicate parser-core symbol ${symbol}`);
      assert(upstreamFunctions.has(symbol), `stale parser-core symbol ${symbol}`);
      symbols.add(symbol);
    }
  }
  assertEqual(symbols.size, 111, "upstream helper count");
}

function verifyParsingContexts() {
  const audit = parseTsv(CONTEXT_AUDIT_PATH);
  assertEqual(audit.rows.length, 26, "real ParsingContext count");
  const expectedNames = [
    "SourceElements",
    "BlockStatements",
    "SwitchClauses",
    "SwitchClauseStatements",
    "TypeMembers",
    "ClassMembers",
    "EnumMembers",
    "HeritageClauseElement",
    "VariableDeclarations",
    "ObjectBindingElements",
    "ArrayBindingElements",
    "ArgumentExpressions",
    "ObjectLiteralMembers",
    "JsxAttributes",
    "JsxChildren",
    "ArrayLiteralMembers",
    "Parameters",
    "JSDocParameters",
    "RestProperties",
    "TypeParameters",
    "TypeArguments",
    "TupleElementTypes",
    "HeritageClauses",
    "ImportOrExportSpecifiers",
    "ImportAttributes",
    "JSDocComment",
  ].map((name) => `ParsingContext.${name}`);
  assertDeepEqual(
    audit.rows.map((row) => row.upstream_symbol),
    expectedNames,
    "ParsingContext order",
  );
  for (const row of audit.rows) {
    assert(row.start_rule, `${row.upstream_symbol} start rule is empty`);
    assert(row.terminator_rule, `${row.upstream_symbol} terminator rule is empty`);
    assert(row.recovery_diagnostics, `${row.upstream_symbol} diagnostics are empty`);
    assert(row.delimiter_rule, `${row.upstream_symbol} delimiter rule is empty`);
    assertEqual(row.status, "complete", `${row.upstream_symbol} status`);
    assert(
      row.moonbit_implementation.includes("parser_lists.mbt"),
      `${row.upstream_symbol} is not mapped to parser_lists.mbt`,
    );
    assert(
      row.test_location.includes("parser_lists_wbtest.mbt"),
      `${row.upstream_symbol} has no white-box recovery test`,
    );
  }
}

function verifyImplementationShape() {
  const state = fs.readFileSync("parser_state.mbt", "utf8");
  const tokens = fs.readFileSync("parser_tokens.mbt", "utf8");
  const lists = fs.readFileSync("parser_lists.mbt", "utf8");
  const combined = `${state}\n${tokens}\n${lists}`;
  assert(state.includes("priv struct ParserState"), "ParserState is not private");
  for (const field of [
    "scanner",
    "diagnostics",
    "jsdoc_diagnostics",
    "current_token",
    "node_count",
    "identifier_count",
    "identifiers",
    "parsing_context",
    "not_parenthesized_arrow",
    "context_flags",
    "top_level",
  ]) {
    assert(new RegExp(`\\b${field}\\b`).test(state), `ParserState missing ${field}`);
  }
  for (const saved of [
    "saved_token",
    "saved_diagnostics_length",
    "saved_error_before_node",
    "saved_context_flags",
  ]) {
    assert(state.includes(saved), `speculation does not save ${saved}`);
  }
  assert(
    state.includes("kind.to_int() != SpeculationKind::Reparse.to_int()"),
    "Reparse diagnostic retention branch is missing",
  );
  assert(
    lists.includes("start == self.scanner._token_full_start()"),
    "list no-progress guard is missing",
  );
  for (const forbidden of [
    "syntax_cursor",
    "_current_node",
    "_consume_node",
    "_is_reusable_parsing_context",
    "_can_reuse_node",
  ]) {
    assert(!combined.includes(forbidden), `general incremental path leaked: ${forbidden}`);
  }
  const publicInterface = fs.readFileSync("pkg.generated.mbti", "utf8");
  for (const privateName of ["ParserState", "Scanner", "SpeculationKind", "ParsingContext"]) {
    assert(!publicInterface.includes(privateName), `${privateName} leaked publicly`);
  }
}

function verifyTests() {
  const core = fs.readFileSync("parser_core_wbtest.mbt", "utf8");
  const lists = fs.readFileSync("parser_lists_wbtest.mbt", "utf8");
  for (const name of [
    "ParserState is invocation local and dispose releases mutable input state",
    "parser owns every scanner rescan path",
    "lookahead tryParse and reparse have exact rollback boundaries",
    "parser context helpers inherit and restore all five context flags",
    "expected tokens matching brackets and identifier forms preserve ranges",
    "ASI suggestions error flags EOF and adjacent diagnostic suppression",
  ]) {
    assert(core.includes(`test ${JSON.stringify(name)}`), `missing core test ${name}`);
  }
  for (const name of [
    "all 26 list contexts recognize representative elements and terminators",
    "all 26 parsing context diagnostics use the upstream code",
    "all 26 contexts terminate at EOF and survive stalled and nested recovery",
    "every comma-delimited context recovers a missing separator",
    "list recovery detects no progress and respects nested contexts",
    "arbitrary error-token streams terminate in every parsing context",
  ]) {
    assert(lists.includes(`test ${JSON.stringify(name)}`), `missing list test ${name}`);
  }
  assert(
    lists.match(/ParsingContext::count\(\)/g)?.length >= 3,
    "26-context matrix coverage was reduced",
  );
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-parser-core.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  const parserSource = fs.readFileSync(PARSER_SOURCE_PATH, "utf8");
  verifyCoreTraceability(parserSource);
  verifyParsingContexts();
  verifyImplementationShape();
  verifyTests();
  console.log(
    "verified 111 parser helpers, 12 contracts, 26 parsing contexts, " +
      "rollback boundaries, termination guards, and private surface",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
