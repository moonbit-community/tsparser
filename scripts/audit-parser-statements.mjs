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
  extractStringPairs,
  relativeDiagnostics,
  testBlock,
} from "./parser-audit-support.mjs";
import {
  DEFAULT_TYPESCRIPT_SOURCE_DIR,
  verifyInstalledTypeScript,
} from "./upstream-config.mjs";

const PARSER_SOURCE_PATH =
  `${DEFAULT_TYPESCRIPT_SOURCE_DIR}/src/compiler/parser.ts`;
const AUDIT_PATH = "docs/upstream-audit/parser-statements-declarations.tsv";
const TEST_PATH = "parser_statements_wbtest.mbt";

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
    "parser-statements audit headers",
  );
  assertDeepEqual(
    audit.rows.map((row) => row.contract),
    [
      "blocks_and_control_flow",
      "switch_try_and_labels",
      "statement_dispatch_and_detection",
      "bindings_and_variables",
      "decorators_and_modifiers",
      "function_declarations",
      "class_members",
      "classes_and_heritage",
      "typescript_declarations",
    ],
    "parser-statements contract order",
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
      assert(!symbols.has(symbol), `duplicate symbol ${symbol}`);
      assert(upstreamFunctions.has(symbol), `stale symbol ${symbol}`);
      symbols.add(symbol);
    }
  }
  assertEqual(symbols.size, 95, "upstream helper count");
}

function parseStatements(source, fileName = "statements.ts") {
  return ts.createSourceFile(
    fileName,
    source,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS,
  );
}

function statementShape(file) {
  const result = [
    `A@${file.statements.pos}:${file.statements.end}:` +
      (file.statements.hasTrailingComma ? "1" : "0"),
  ];
  function visit(node) {
    result.push(`${node.kind}@${node.pos}:${node.end}`);
    ts.forEachChild(node, visit);
  }
  for (const statement of file.statements) visit(statement);
  return result.join(",");
}

function statementArrayShape(file) {
  const result = [];
  function visitArray(array) {
    result.push(
      `A@${array.pos}:${array.end}:` +
        (array.hasTrailingComma ? "1" : "0"),
    );
    for (const child of array) visit(child);
  }
  function visit(node) {
    result.push(`N${node.kind}@${node.pos}:${node.end}`);
    ts.forEachChild(node, visit, visitArray);
  }
  visitArray(file.statements);
  return result.join(",");
}

function verifyDifferentialFixtures(testSource) {
  const rangeFixtures = extractStringPairs(
    testBlock(
      testSource,
      "statement declaration preorder kinds and UTF-16 ranges match TypeScript",
    ),
  );
  assertEqual(rangeFixtures.length, 32, "exact statement fixture count");
  const coveredKinds = new Set();
  for (const [source, expected] of rangeFixtures) {
    const file = parseStatements(source);
    assertEqual(statementShape(file), expected, `statement reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
    function collect(node) {
      coveredKinds.add(node.kind);
      ts.forEachChild(node, collect);
    }
    for (const statement of file.statements) collect(statement);
  }
  const requiredKinds = [
    171, 172, 173, 174, 175, 176, 177, 178, 179, 182,
    207, 208, 209,
    241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252,
    253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264,
    265, 266, 267, 268, 269, 270,
    297, 298, 299, 300, 307,
  ];
  assertDeepEqual(
    requiredKinds.filter((kind) => coveredKinds.has(kind)),
    requiredKinds,
    "all statement/declaration SyntaxKinds",
  );

  const arrayFixtures = extractStringPairs(
    testBlock(
      testSource,
      "statement declaration NodeArray metadata matches TypeScript",
    ),
  );
  assertEqual(arrayFixtures.length, 8, "NodeArray fixture count");
  for (const [source, expected] of arrayFixtures) {
    const file = parseStatements(source);
    assertEqual(statementArrayShape(file), expected, `NodeArray reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
  }
}

function verifyAsiAndRecoveryReferences() {
  const asiFixtures = [
    ["throw\nx;", "A@0:8:0,258@0:5,80@5:5,245@5:8,80@5:7"],
    ["return\nx;", "A@0:9:0,254@0:6,245@6:9,80@6:8"],
    ["break\nlabel;", "A@0:12:0,253@0:5,245@5:12,80@5:11"],
    ["for(let of xs){}", "A@0:16:0,251@0:16,262@4:7,80@10:13,242@14:16"],
    ["do{}while(false)foo()", "A@0:21:0,247@0:16,242@2:4,97@10:15,245@16:21,214@16:21,80@16:19"],
  ];
  for (const [source, expected] of asiFixtures) {
    const file = parseStatements(source);
    assertEqual(statementShape(file), expected, `ASI reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected ASI diagnostic for ${source}`);
  }
  const recoveryFixtures = [
    ["var #x=1;", [{ code: 18029, start: 4, length: 2 }]],
    ["const #x=1;", [{ code: 18029, start: 6, length: 2 }]],
    ["function f(#x){}", [{ code: 18009, start: 11, length: 2 }]],
    ["try{}", [{ code: 1472, start: 5, length: 0 }]],
    ["let {a b}=x;", [{ code: 1005, start: 7, length: 1 }]],
    ["function f(", [{ code: 1005, start: 11, length: 0 }]],
    ["class C { x: ; }", [{ code: 1110, start: 13, length: 1 }]],
  ];
  for (const [source, expected] of recoveryFixtures) {
    const file = parseStatements(source);
    assertDeepEqual(relativeDiagnostics(file), expected, `recovery reference for ${source}`);
  }
}

function verifyFlagsAndInternalFields(testSource) {
  const declarations = parseStatements(
    "var a;let b;const c=1;using d=f();await using e=g();",
  ).statements;
  assertDeepEqual(
    declarations.map((statement) => statement.declarationList.flags),
    [0, 1, 2, 4, 6],
    "variable declaration-list flags",
  );
  for (const fileName of ["x.d.ts", "x.d.cts", "x.d.mts", "x.d.generated.ts"]) {
    const file = parseStatements("interface I{}", fileName);
    assert((file.flags & ts.NodeFlags.Ambient) !== 0, `ambient file flag missing for ${fileName}`);
    assert((file.statements[0].flags & ts.NodeFlags.Ambient) !== 0, `ambient node flag missing for ${fileName}`);
    assert((file.statements[0].flags & ts.NodeFlags.ExportContext) === 0, `unexpected export context for ${fileName}`);
  }
  const moduleFile = parseStatements("namespace N.Inner{} declare global{}");
  const namespaceNode = moduleFile.statements[0];
  assert((namespaceNode.flags & ts.NodeFlags.Namespace) !== 0, "namespace flag missing");
  assert((namespaceNode.body.flags & ts.NodeFlags.NestedNamespace) !== 0, "nested namespace flag missing");
  assert((namespaceNode.body.flags & ts.NodeFlags.Namespace) !== 0, "nested namespace propagation missing");
  const globalNode = moduleFile.statements[1];
  assert((globalNode.flags & ts.NodeFlags.Ambient) !== 0, "declare global ambient flag missing");
  assert((globalNode.flags & ts.NodeFlags.GlobalAugmentation) !== 0, "global augmentation flag missing");
  for (const fragment of [
    "typeParameters",
    "constructor_node",
    "setter",
    "static_block",
    "modifiers are absent",
  ]) {
    assert(testSource.includes(fragment), `internal-field reference missing ${fragment}`);
  }
}

function verifyImplementationShape(testSource) {
  const statements = fs.readFileSync("parser_statements.mbt", "utf8");
  const bindings = fs.readFileSync("parser_bindings_variables.mbt", "utf8");
  const declarations = fs.readFileSync("parser_declarations.mbt", "utf8");
  const lists = fs.readFileSync("parser_lists.mbt", "utf8");
  const doStart = statements.indexOf("fn ParserState::_parse_do_statement");
  const doEnd = statements.indexOf("\n///|", doStart + 10);
  const doBody = statements.slice(doStart, doEnd);
  assert(doBody.includes("_parse_optional(_syntax_kind(27))"), "do-while explicit semicolon rule missing");
  assert(!doBody.includes("_parse_semicolon()"), "do-while incorrectly uses ordinary ASI semicolon parsing");
  for (const fragment of [
    "_parse_for_statement",
    "_parse_switch_statement",
    "_parse_try_statement",
    "_parse_expression_or_labeled_statement",
  ]) {
    assert(statements.includes(fragment), `statement implementation missing ${fragment}`);
  }
  for (const fragment of [
    "_parse_object_binding_pattern",
    "_parse_array_binding_pattern",
    "NodeFlags::await_using()",
    "_diagnostic_message(18029)",
  ]) {
    assert(bindings.includes(fragment), `binding implementation missing ${fragment}`);
  }
  for (const fragment of [
    "_parse_class_static_block",
    "_parse_class_declaration_or_expression",
    "_parse_interface_declaration",
    "_parse_type_alias_declaration",
    "_parse_enum_declaration",
    "_parse_module_declaration",
  ]) {
    assert(declarations.includes(fragment), `declaration implementation missing ${fragment}`);
  }
  assert(
    lists.includes("let candidate = if self.current_token.to_int() == 156"),
    "export-type declaration lookahead rollback is missing",
  );
  for (const fragment of [
    "declaration filename variants set ambient context only",
    "parser-only fields preserve invalid syntax",
    "do-while consumes only an explicit trailing semicolon",
  ]) {
    assert(testSource.includes(fragment), `white-box reference missing ${fragment}`);
  }
  const publicInterface = fs.readFileSync("pkg.generated.mbti", "utf8");
  for (const privateName of ["ParserState", "_parse_statements_for_test"]) {
    assert(!publicInterface.includes(privateName), `${privateName} leaked publicly`);
  }
}

function verifyFactoryReferences() {
  const source = [
    "node_factory_declarations_contract_wbtest.mbt",
    "node_factory_expressions_contract_wbtest.mbt",
  ].map((name) => fs.readFileSync(name, "utf8")).join("\n");
  for (const name of [
    "NodeFactory.createBlock",
    "NodeFactory.createForOfStatement",
    "NodeFactory.createTryStatement",
    "NodeFactory.createVariableDeclaration",
    "NodeFactory.createFunctionDeclaration",
    "NodeFactory.createClassDeclaration",
    "NodeFactory.createInterfaceDeclaration",
    "NodeFactory.createTypeAliasDeclaration",
    "NodeFactory.createEnumDeclaration",
    "NodeFactory.createModuleDeclaration",
    "NodeFactory.createCatchClause",
    "NodeFactory.createHeritageClause",
  ]) {
    assert(source.includes(JSON.stringify(name)), `missing factory field reference ${name}`);
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-parser-statements.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  const parserSource = fs.readFileSync(PARSER_SOURCE_PATH, "utf8");
  const testSource = fs.readFileSync(TEST_PATH, "utf8");
  verifyTraceability(parserSource);
  verifyDifferentialFixtures(testSource);
  verifyAsiAndRecoveryReferences();
  verifyFlagsAndInternalFields(testSource);
  verifyImplementationShape(testSource);
  verifyFactoryReferences();
  console.log(
    "verified 95 parser helpers, 48 statement/declaration kinds, " +
      "exact ranges, NodeArray metadata, ASI, flags, parser-only fields, and recovery diagnostics",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
