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
  extractStringIntegerPairs,
  extractStringIntegerTriples,
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
const AUDIT_PATH = "docs/upstream-audit/parser-expressions.tsv";
const TEST_PATH = "parser_expressions_wbtest.mbt";

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
    "parser-expressions audit headers",
  );
  assertDeepEqual(
    audit.rows.map((row) => row.contract),
    [
      "expression_assignment_conditional",
      "binary_and_type_operators",
      "unary_update_await_yield",
      "arrow_speculation",
      "member_and_optional_chain",
      "calls_generics_and_templates",
      "primary_and_array_literals",
      "object_literals",
      "function_class_new_and_meta",
    ],
    "parser-expressions contract order",
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
  assertEqual(symbols.size, 63, "upstream helper count");
}

function expressionParse(source) {
  const file = ts.createSourceFile(
    "expression.ts",
    `const value=(${source});`,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS,
  );
  const statement = file.statements[0];
  assert(ts.isVariableStatement(statement), `expression fixture did not parse: ${source}`);
  const initializer = statement.declarationList.declarations[0].initializer;
  assert(ts.isParenthesizedExpression(initializer), `missing wrapper for ${source}`);
  return { file, root: initializer.expression };
}

function standaloneExpressionParse(source) {
  const file = ts.createSourceFile(
    "expression.ts",
    source,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS,
  );
  const statement = file.statements[0];
  assert(ts.isExpressionStatement(statement), `standalone fixture did not parse: ${source}`);
  return { file, root: statement.expression };
}

function kindRangeShape(root) {
  const base = root.pos;
  const result = [];
  function visit(node) {
    result.push(`${node.kind}@${node.pos - base}:${node.end - base}`);
    ts.forEachChild(node, visit);
  }
  visit(root);
  return result.join(",");
}

function arrayShape(root) {
  const base = root.pos;
  const result = [];
  function visit(node) {
    result.push(`N${node.kind}@${node.pos - base}:${node.end - base}`);
    ts.forEachChild(node, visit, (array) => {
      result.push(
        `A@${array.pos - base}:${array.end - base}:` +
          (array.hasTrailingComma ? "1" : "0"),
      );
      for (const child of array) visit(child);
    });
  }
  visit(root);
  return result.join(",");
}

function verifyDifferentialFixtures(testSource) {
  const rangeFixtures = extractStringPairs(
    testBlock(
      testSource,
      "expression preorder kinds and UTF-16 ranges match TypeScript",
    ),
  );
  assertEqual(rangeFixtures.length, 40, "exact expression fixture count");
  const coveredKinds = new Set();
  for (const [source, expected] of rangeFixtures) {
    const { file, root } = expressionParse(source);
    assertEqual(kindRangeShape(root), expected, `kind/range reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
    (function collect(node) {
      if (node.kind >= 210 && node.kind <= 240) coveredKinds.add(node.kind);
      ts.forEachChild(node, collect);
    })(root);
  }
  const awaitResult = standaloneExpressionParse("await x");
  assertEqual(awaitResult.file.parseDiagnostics.length, 0, "unexpected TS await diagnostic");
  assertEqual(kindRangeShape(awaitResult.root), "224@0:7,80@5:7", "await expression reference");
  coveredKinds.add(awaitResult.root.kind);
  const yieldFile = ts.createSourceFile(
    "expression.ts",
    "function* f(){yield* x}",
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS,
  );
  const yieldFunction = yieldFile.statements[0];
  assert(ts.isFunctionDeclaration(yieldFunction), "yield wrapper did not parse");
  const yieldStatement = yieldFunction.body.statements[0];
  assert(ts.isExpressionStatement(yieldStatement), "yield statement did not parse");
  assertEqual(yieldFile.parseDiagnostics.length, 0, "unexpected TS yield diagnostic");
  assertEqual(
    kindRangeShape(yieldStatement.expression),
    "230@0:8,42@5:6,80@6:8",
    "yield expression reference",
  );
  coveredKinds.add(yieldStatement.expression.kind);
  const expectedKinds = Array.from({ length: 31 }, (_, index) => 210 + index)
    .filter((kind) => kind !== 238);
  assertDeepEqual(
    [...coveredKinds].sort((left, right) => left - right),
    expectedKinds,
    "all parser-created non-synthetic expression SyntaxKinds",
  );

  const arrayFixtures = extractStringPairs(
    testBlock(
      testSource,
      "expression NodeArray ranges order and trailing commas match TypeScript",
    ),
  );
  assertEqual(arrayFixtures.length, 10, "NodeArray fixture count");
  for (const [source, expected] of arrayFixtures) {
    const { file, root } = expressionParse(source);
    assertEqual(arrayShape(root), expected, `NodeArray reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
  }
}

function verifyOperatorReferences(testSource) {
  const block = testBlock(
    testSource,
    "binary and assignment operator matrix matches scanner kinds",
  );
  const fixtures = extractStringIntegerPairs(block);
  assertEqual(fixtures.length, 41, "binary/assignment operator count");
  for (const [spelling, expected] of fixtures) {
    const { file, root } = expressionParse(`a ${spelling} b`);
    assert(ts.isBinaryExpression(root), `${spelling} did not create BinaryExpression`);
    assertEqual(root.operatorToken.kind, expected, `operator kind for ${spelling}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${spelling}`);
  }

  const unaryBlock = testBlock(
    testSource,
    "unary operators and disallow-in context preserve parser state",
  );
  const unaryFixtures = extractStringIntegerTriples(unaryBlock);
  assertEqual(unaryFixtures.length, 8, "unary operator count");
  for (const [source, expectedOperator, expectedKind] of unaryFixtures) {
    const { file, root } = expressionParse(source);
    assertEqual(root.kind, expectedKind, `unary node kind for ${source}`);
    assertEqual(root.operator, expectedOperator, `unary operator for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
  }
}

function verifyRecoveryReferences() {
  const fixtures = [
    ["-a ** b", [{ code: 17006, start: 0, length: 2 }]],
    ["<T>a ** b", [{ code: 17007, start: 0, length: 4 }]],
    ["obj?.#field", [{ code: 18030, start: 5, length: 6 }]],
    ["new Foo?.()", [{ code: 1209, start: 7, length: 2 }]],
    ["a[]", [{ code: 1011, start: 2, length: 0 }]],
    ["super", [{ code: 1034, start: 5, length: 0 }]],
    ["f<T>.x", [{ code: 1477, start: 1, length: 3 }]],
  ];
  for (const [source, expected] of fixtures) {
    const { file, root } = standaloneExpressionParse(source);
    assertDeepEqual(
      relativeDiagnostics(file, root.pos),
      expected,
      `diagnostic reference for ${source}`,
    );
  }
}

function verifyFlagsAndAmbiguities() {
  for (const [source, flag] of [
    ["import(\"x\")", ts.NodeFlags.PossiblyContainsDynamicImport],
    ["import.defer(\"x\")", ts.NodeFlags.PossiblyContainsDynamicImport],
    ["import.meta", ts.NodeFlags.PossiblyContainsImportMeta],
  ]) {
    const file = ts.createSourceFile(
      "expression.ts",
      source,
      ts.ScriptTarget.Latest,
      true,
      ts.ScriptKind.TS,
    );
    assert((file.flags & flag) !== 0, `source flag missing for ${source}`);
  }
  for (const source of [
    "obj?.foo.bar",
    "obj?.foo?.[i]?.(x)!.bar",
    "tag?.`x`",
  ]) {
    const { root } = standaloneExpressionParse(source);
    assert(
      (root.flags & ts.NodeFlags.OptionalChain) !== 0,
      `OptionalChain flag missing for ${source}`,
    );
  }
  const relational = expressionParse("f < T > x").root;
  assert(ts.isBinaryExpression(relational), "spaced type arguments became instantiation");
  const instantiation = expressionParse("f<T>").root;
  assertEqual(
    instantiation.kind,
    ts.SyntaxKind.ExpressionWithTypeArguments,
    "instantiation-expression ambiguity",
  );
  const genericArrow = expressionParse("<T>(x:T)=>x").root;
  assertEqual(genericArrow.kind, ts.SyntaxKind.ArrowFunction, "generic-arrow ambiguity");
}

function verifyFactoryFieldReferences() {
  const source = [
    "node_factory_expressions_contract_wbtest.mbt",
    "node_factory_types_wbtest.mbt",
  ].map((name) => fs.readFileSync(name, "utf8")).join("\n");
  const factories = [
    [210, "NodeFactory.createArrayLiteralExpression"],
    [211, "NodeFactory.createObjectLiteralExpression"],
    [212, "NodeFactory.createPropertyAccessExpression"],
    [213, "NodeFactory.createElementAccessExpression"],
    [214, "NodeFactory.createCallExpression"],
    [215, "NodeFactory.createNewExpression"],
    [216, "NodeFactory.createTaggedTemplateExpression"],
    [217, "NodeFactory.createTypeAssertion"],
    [218, "NodeFactory.createParenthesizedExpression"],
    [219, "NodeFactory.createFunctionExpression"],
    [220, "NodeFactory.createArrowFunction"],
    [221, "NodeFactory.createDeleteExpression"],
    [222, "NodeFactory.createTypeOfExpression"],
    [223, "NodeFactory.createVoidExpression"],
    [224, "NodeFactory.createAwaitExpression"],
    [225, "NodeFactory.createPrefixUnaryExpression"],
    [226, "NodeFactory.createPostfixUnaryExpression"],
    [227, "NodeFactory.createBinaryExpression"],
    [228, "NodeFactory.createConditionalExpression"],
    [229, "NodeFactory.createTemplateExpression"],
    [230, "NodeFactory.createYieldExpression"],
    [231, "NodeFactory.createSpreadElement"],
    [232, "NodeFactory.createClassExpression"],
    [233, "NodeFactory.createOmittedExpression"],
    [234, "NodeFactory.createExpressionWithTypeArguments"],
    [235, "NodeFactory.createAsExpression"],
    [236, "NodeFactory.createNonNullExpression"],
    [237, "NodeFactory.createMetaProperty"],
    [239, "NodeFactory.createSatisfiesExpression"],
    [240, "NodeFactory.createTemplateSpan"],
  ];
  for (const [kind, name] of factories) {
    const start = source.indexOf(JSON.stringify(name));
    assert(start >= 0, `missing factory field reference ${name}`);
    const snippet = source.slice(start, start + 1000);
    assert(new RegExp(`\\b${kind},`).test(snippet), `${name} kind reference changed`);
    assert(snippet.includes("["), `${name} field list reference missing`);
  }
}

function verifyImplementationShape(testSource) {
  const core = fs.readFileSync("parser_expression_core.mbt", "utf8");
  const functions = fs.readFileSync("parser_expression_functions.mbt", "utf8");
  const member = fs.readFileSync("parser_expression_member.mbt", "utf8");
  const literals = fs.readFileSync("parser_expression_literals.mbt", "utf8");
  const unary = fs.readFileSync("parser_expression_unary.mbt", "utf8");
  for (const fragment of [
    "61 | 57 => 5",
    "56 => 6",
    "kind.to_int() >= 64 && kind.to_int() <= 79",
    "_re_scan_greater_token",
    "_in_disallow_in_context",
  ]) {
    assert(core.includes(fragment), `expression core missing ${fragment}`);
  }
  for (const fragment of [
    "_record_not_parenthesized_arrow",
    "_parse_parenthesized_arrow_function_expression",
    "_parse_arrow_function_expression_body",
  ]) {
    assert(functions.includes(fragment), `arrow implementation missing ${fragment}`);
  }
  for (const fragment of [
    "_parser_try_reparse_optional_chain",
    "possibly_contains_dynamic_import",
    "possibly_contains_import_meta",
    "_re_scan_slash_token",
    "_re_scan_template_token",
  ]) {
    assert(member.includes(fragment), `member implementation missing ${fragment}`);
  }
  for (const fragment of [
    "_parse_object_literal_element",
    "_parse_object_method_declaration",
    "_parse_object_accessor_declaration",
  ]) {
    assert(literals.includes(fragment), `literal implementation missing ${fragment}`);
  }
  assert(unary.includes("_diagnostic_message(17006)"), "unary exponentiation diagnostic missing");
  assert(unary.includes("_diagnostic_message(17007)"), "assertion exponentiation diagnostic missing");
  for (const fragment of [
    "failed parenthesized-arrow speculation is cached",
    "source and optional-chain flags propagate",
    "binary and assignment operator matrix",
    "f<T>?.(x)",
    "tag?.`x`",
  ]) {
    assert(testSource.includes(fragment), `white-box reference missing ${fragment}`);
  }
  const publicInterface = fs.readFileSync("pkg.generated.mbti", "utf8");
  for (const privateName of ["ParserState", "_parse_expression_for_test"] ) {
    assert(!publicInterface.includes(privateName), `${privateName} leaked publicly`);
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-parser-expressions.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  const parserSource = fs.readFileSync(PARSER_SOURCE_PATH, "utf8");
  const testSource = fs.readFileSync(TEST_PATH, "utf8");
  verifyTraceability(parserSource);
  verifyDifferentialFixtures(testSource);
  verifyOperatorReferences(testSource);
  verifyRecoveryReferences();
  verifyFlagsAndAmbiguities();
  verifyFactoryFieldReferences();
  verifyImplementationShape(testSource);
  console.log(
    "verified 63 parser helpers, all 30 non-synthetic expression " +
      "SyntaxKinds, 41 operators, exact ranges, NodeArray metadata, flags, " +
      "ambiguities, field contracts, and recovery diagnostics",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
