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
  extractStringStringIntegerTriples as extractStringTriples,
  relativeDiagnostics,
  testBlock,
} from "./parser-audit-support.mjs";
import {
  DEFAULT_TYPESCRIPT_SOURCE_DIR,
  verifyInstalledTypeScript,
} from "./upstream-config.mjs";

const PARSER_SOURCE_PATH =
  `${DEFAULT_TYPESCRIPT_SOURCE_DIR}/src/compiler/parser.ts`;
const AUDIT_PATH = "docs/upstream-audit/parser-types.tsv";
const TEST_PATH = "parser_types_wbtest.mbt";

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
    "parser-types audit headers",
  );
  const expectedContracts = [
    "names_and_property_names",
    "literals_and_templates",
    "references_predicates_and_queries",
    "type_parameters",
    "parameters_returns_and_predicates",
    "type_members_and_signatures",
    "mapped_tuple_and_parenthesized_types",
    "function_literal_and_import_types",
    "postfix_operators_and_infer",
    "unions_intersections_conditionals",
  ];
  assertDeepEqual(
    audit.rows.map((row) => row.contract),
    expectedContracts,
    "parser-types contract order",
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
  assertEqual(symbols.size, 92, "upstream helper count");
}

function typeParse(source) {
  const file = ts.createSourceFile(
    "type.ts",
    `type X=${source};`,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS,
  );
  const statement = file.statements[0];
  assert(ts.isTypeAliasDeclaration(statement), `type fixture did not parse: ${source}`);
  return { file, root: statement.type };
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
    testBlock(testSource, "type preorder kinds and UTF-16 ranges match TypeScript"),
  );
  assertEqual(rangeFixtures.length, 25, "exact type range fixture count");
  const coveredKinds = new Set();
  for (const [source, expected] of rangeFixtures) {
    const { file, root } = typeParse(source);
    assertEqual(kindRangeShape(root), expected, `kind/range reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
    (function collect(node) {
      if (node.kind >= 183 && node.kind <= 206) coveredKinds.add(node.kind);
      ts.forEachChild(node, collect);
    })(root);
  }
  assertDeepEqual(
    [...coveredKinds].sort((left, right) => left - right),
    Array.from({ length: 24 }, (_, index) => 183 + index),
    "all parser-created TypeScript type SyntaxKinds",
  );

  const arrayFixtures = extractStringPairs(
    testBlock(testSource, "NodeArray ranges order and trailing commas match TypeScript"),
  );
  assertEqual(arrayFixtures.length, 11, "NodeArray fixture count");
  for (const [source, expected] of arrayFixtures) {
    const { file, root } = typeParse(source);
    assertEqual(arrayShape(root), expected, `NodeArray reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
  }

  const attributeFixtures = extractStringPairs(
    testBlock(testSource, "import type attributes preserve token shape and trailing comma"),
  );
  assertEqual(attributeFixtures.length, 3, "import-attribute fixture count");
  for (const [source, expected] of attributeFixtures) {
    const { file, root } = typeParse(source);
    assertEqual(arrayShape(root), expected, `import-attribute reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
  }

  const ambiguityFixtures = extractStringTriples(
    testBlock(
      testSource,
      "names mapped modifiers tuple ambiguity and precedence match TypeScript",
    ),
  );
  assertEqual(ambiguityFixtures.length, 10, "precedence fixture count");
  for (const [source, expected, diagnosticCode] of ambiguityFixtures) {
    const { file, root } = typeParse(source);
    assertEqual(kindRangeShape(root), expected, `precedence reference for ${source}`);
    const actual = relativeDiagnostics(file, root.pos);
    const wanted = diagnosticCode === 0
      ? []
      : [{ code: diagnosticCode, start: 3, length: 12 }];
    assertDeepEqual(actual, wanted, `diagnostic reference for ${source}`);
  }
}

function verifyRecoveryAndTemplateReferences() {
  const recovery = [
    ["T | (x: U) => V", [{ code: 1385, start: 3, length: 12 }]],
    ["T | new () => U", [{ code: 1386, start: 3, length: 12 }]],
    ["T & (x: U) => V", [{ code: 1387, start: 3, length: 12 }]],
    ["T & new () => U", [{ code: 1388, start: 3, length: 12 }]],
    ["<T(a:T)=>T", [{ code: 1005, start: 2, length: 1 }]],
    [
      "T extends U X Y",
      [
        { code: 1005, start: 12, length: 1 },
        { code: 1005, start: 14, length: 1 },
      ],
    ],
  ];
  for (const [source, expected] of recovery) {
    const { file, root } = typeParse(source);
    assertDeepEqual(
      relativeDiagnostics(file, root.pos),
      expected,
      `recovery reference for ${source}`,
    );
  }

  const expressionConstraint = typeParse("<T extends -x>(a:T)=>T");
  assertEqual(
    expressionConstraint.root.typeParameters[0].expression.kind,
    ts.SyntaxKind.PrefixUnaryExpression,
    "invalid constraint expression recovery",
  );

  const template = typeParse("`\\x61${T}\\u0062`").root;
  assertEqual(template.head.text, "a", "template cooked head");
  assertEqual(template.head.rawText, "\\x61", "template raw head");
  assertEqual(template.templateSpans[0].literal.text, "b", "template cooked tail");
  assertEqual(
    template.templateSpans[0].literal.rawText,
    "\\u0062",
    "template raw tail",
  );
}

function verifyFactoryFieldReferences() {
  const source = fs.readFileSync("node_factory_types_wbtest.mbt", "utf8");
  const factories = [
    [167, "NodeFactory.createQualifiedName"],
    [168, "NodeFactory.createComputedPropertyName"],
    [169, "NodeFactory.createTypeParameterDeclaration"],
    [170, "NodeFactory.createParameterDeclaration"],
    [172, "NodeFactory.createPropertySignature"],
    [174, "NodeFactory.createMethodSignature"],
    [180, "NodeFactory.createCallSignature"],
    [181, "NodeFactory.createConstructSignature"],
    [182, "NodeFactory.createIndexSignature"],
    [183, "NodeFactory.createTypePredicateNode"],
    [184, "NodeFactory.createTypeReferenceNode"],
    [185, "NodeFactory.createFunctionTypeNode"],
    [186, "NodeFactory.createConstructorTypeNode"],
    [187, "NodeFactory.createTypeQueryNode"],
    [188, "NodeFactory.createTypeLiteralNode"],
    [189, "NodeFactory.createArrayTypeNode"],
    [190, "NodeFactory.createTupleTypeNode"],
    [191, "NodeFactory.createOptionalTypeNode"],
    [192, "NodeFactory.createRestTypeNode"],
    [193, "NodeFactory.createUnionTypeNode"],
    [194, "NodeFactory.createIntersectionTypeNode"],
    [195, "NodeFactory.createConditionalTypeNode"],
    [196, "NodeFactory.createInferTypeNode"],
    [197, "NodeFactory.createParenthesizedType"],
    [198, "NodeFactory.createThisTypeNode"],
    [199, "NodeFactory.createTypeOperatorNode"],
    [200, "NodeFactory.createIndexedAccessTypeNode"],
    [201, "NodeFactory.createMappedTypeNode"],
    [202, "NodeFactory.createLiteralTypeNode"],
    [203, "NodeFactory.createNamedTupleMember"],
    [204, "NodeFactory.createTemplateLiteralType"],
    [205, "NodeFactory.createTemplateLiteralTypeSpan"],
    [206, "NodeFactory.createImportTypeNode"],
  ];
  for (const [kind, name] of factories) {
    const start = source.indexOf(JSON.stringify(name));
    assert(start >= 0, `missing factory field reference ${name}`);
    const snippet = source.slice(start, start + 900);
    assert(new RegExp(`\\b${kind},`).test(snippet), `${name} kind reference changed`);
    assert(snippet.includes("["), `${name} field list reference missing`);
  }
}

function verifyImplementationShape(testSource) {
  const names = fs.readFileSync("parser_names_literals.mbt", "utf8");
  const parameters = fs.readFileSync("parser_parameters_signatures.mbt", "utf8");
  const types = fs.readFileSync("parser_types.mbt", "utf8");
  const tokens = fs.readFileSync("parser_tokens.mbt", "utf8");
  const state = fs.readFileSync("parser_state.mbt", "utf8");
  assert(
    tokens.includes("kind.to_int() >= 80"),
    "identifier-or-keyword no longer includes PrivateIdentifier",
  );
  assert(
    parameters.includes("_parser_set_node_field(node, \"expression\", NodeRef(expression))"),
    "type-parameter invalid-expression recovery is missing",
  );
  assert(
    types.includes("_disallow_conditional_types_and") &&
      types.includes("_allow_conditional_types_and"),
    "conditional-type context boundary is missing",
  );
  for (const fragment of [
    "_parse_template_spans",
    "_parse_template_type_spans",
    "_template_literal_raw_text",
  ]) {
    assert(names.includes(fragment), `template implementation missing ${fragment}`);
  }
  for (const fragment of [
    "has_trailing_comma()",
    "uncovered type SyntaxKind",
    "resolution-mode",
    "Some(12)",
  ]) {
    assert(testSource.includes(fragment), `white-box reference missing ${fragment}`);
  }
  assert(state.includes("disallow_conditional_types_context"), "state flag missing");
  const publicInterface = fs.readFileSync("pkg.generated.mbti", "utf8");
  for (const privateName of ["ParserState", "_parse_type_for_test", "ParsingContext"]) {
    assert(!publicInterface.includes(privateName), `${privateName} leaked publicly`);
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-parser-types.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  const parserSource = fs.readFileSync(PARSER_SOURCE_PATH, "utf8");
  const testSource = fs.readFileSync(TEST_PATH, "utf8");
  verifyTraceability(parserSource);
  verifyDifferentialFixtures(testSource);
  verifyRecoveryAndTemplateReferences();
  verifyFactoryFieldReferences();
  verifyImplementationShape(testSource);
  console.log(
    "verified 92 parser helpers, all 24 type SyntaxKinds, exact ranges, " +
      "NodeArray metadata, field contracts, recovery diagnostics, and raw/cooked templates",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
