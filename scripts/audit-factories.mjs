#!/usr/bin/env node

import fs from "node:fs";
import ts from "typescript";

import {
  parseMode,
  parseTsvText as parseTsv,
  renderTsv,
} from "./audit-support.mjs";
import { verifyInstalledTypeScript } from "./upstream-config.mjs";

const AUDIT_PATH = "docs/upstream-audit/node-factory.tsv";
const PROGRESS_COLUMNS = [
  "moonbit_implementation",
  "test_location",
  "status",
];
const COMPLETE_STATUS = "complete";

function parseArguments(argv) {
  return parseMode(
    argv,
    ["verify", "write"],
    "usage: node scripts/audit-factories.mjs (--verify|--write)",
  );
}

function camelToSnake(name) {
  return name
    .replaceAll("JSDoc", "Jsdoc")
    .replaceAll("JSX", "Jsx")
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1_$2")
    .toLowerCase();
}

function implementationFunction(symbol) {
  const prefix = "NodeFactory.create";
  if (!symbol.startsWith(prefix)) {
    throw new Error(`unexpected factory symbol: ${symbol}`);
  }
  const suffix = symbol.slice(prefix.length);
  if (suffix === "NodeArray") return "_create_node_array";
  return `_factory_create_${camelToSnake(suffix)}`;
}

function escapeRegularExpression(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function rootMoonBitFiles() {
  return fs
    .readdirSync(".", { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith(".mbt"))
    .map((entry) => entry.name)
    .sort();
}

function exactImplementation(symbol, sourceFiles) {
  const functionName = implementationFunction(symbol);
  const declaration = new RegExp(
    `(?:^|\\n)(?:pub )?fn ${escapeRegularExpression(functionName)}\\(`,
  );
  const matches = sourceFiles.filter(({ text }) => declaration.test(text));
  if (matches.length !== 1) {
    throw new Error(
      `${symbol} expected one ${functionName} implementation, found ` +
        `${matches.length}: ${matches.map(({ name }) => name).join(", ")}`,
    );
  }
  return matches[0].name;
}

function exactTest(symbol, testFiles) {
  const literal = JSON.stringify(symbol);
  const matches = testFiles.filter(({ text }) => text.includes(literal));
  if (matches.length !== 1) {
    throw new Error(
      `${symbol} expected one field-contract fixture, found ${matches.length}: ` +
        matches.map(({ name }) => name).join(", "),
    );
  }
  if (symbol !== "NodeFactory.createNodeArray") {
    const contract = new RegExp(
      `_assert_factory_contract\\(\\s*${escapeRegularExpression(literal)}`,
    );
    if (!contract.test(matches[0].text)) {
      throw new Error(`${symbol} is named in a test but has no field contract`);
    }
  }
  return matches[0].name;
}

function splitCallArguments(source, openingParenthesis) {
  const arguments_ = [];
  let argumentStart = openingParenthesis + 1;
  let parenthesisDepth = 1;
  let bracketDepth = 0;
  let braceDepth = 0;
  let quote;
  let escaped = false;
  for (let index = openingParenthesis + 1; index < source.length; index++) {
    const character = source[index];
    if (quote) {
      if (escaped) {
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === quote) {
        quote = undefined;
      }
      continue;
    }
    if (character === '"' || character === "'") {
      quote = character;
    } else if (character === "(") {
      parenthesisDepth++;
    } else if (character === ")") {
      parenthesisDepth--;
      if (parenthesisDepth === 0) {
        const finalArgument = source.slice(argumentStart, index).trim();
        if (finalArgument !== "") arguments_.push(finalArgument);
        return arguments_;
      }
    } else if (character === "[") {
      bracketDepth++;
    } else if (character === "]") {
      bracketDepth--;
    } else if (character === "{") {
      braceDepth++;
    } else if (character === "}") {
      braceDepth--;
    } else if (
      character === "," &&
      parenthesisDepth === 1 &&
      bracketDepth === 0 &&
      braceDepth === 0
    ) {
      arguments_.push(source.slice(argumentStart, index).trim());
      argumentStart = index + 1;
    }
  }
  throw new Error("unterminated _assert_factory_contract call");
}

function fieldContracts(testFiles) {
  const result = new Map();
  const marker = "_assert_factory_contract(";
  for (const file of testFiles) {
    let offset = 0;
    while (true) {
      const call = file.text.indexOf(marker, offset);
      if (call < 0) break;
      offset = call + marker.length;
      const arguments_ = splitCallArguments(
        file.text,
        call + marker.length - 1,
      );
      if (!arguments_[0]?.startsWith('"')) continue;
      const symbol = JSON.parse(arguments_[0]);
      if (!symbol.startsWith("NodeFactory.create")) continue;
      if (arguments_.length !== 4 || !/^\d+$/.test(arguments_[2])) {
        throw new Error(`${symbol} has a malformed field contract in ${file.name}`);
      }
      const fields = [...arguments_[3].matchAll(/"([^"\\]+)"/g)].map(
        (match) => match[1],
      );
      if (result.has(symbol)) {
        throw new Error(`${symbol} has more than one field contract`);
      }
      result.set(symbol, {
        kind: Number.parseInt(arguments_[2], 10),
        fields,
        file: file.name,
      });
    }
  }
  return result;
}

const ARRAY_PARAMETERS = new Set([
  "arguments",
  "children",
  "clauses",
  "declarations",
  "elements",
  "heritageClauses",
  "jsDocPropertyTags",
  "members",
  "modifiers",
  "parameters",
  "properties",
  "propertyTags",
  "statements",
  "tags",
  "templateSpans",
  "typeArguments",
  "typeParameters",
  "types",
]);

function factoryParameters(factory, name) {
  const source = Function.prototype.toString.call(factory);
  const match = /^function\s+[^\s(]*\(([^)]*)\)/.exec(source) ??
    /^(?:\(([^)]*)\)|([A-Za-z_$][\w$]*))\s*=>/.exec(source);
  if (!match) {
    throw new Error(`could not read TypeScript factory parameters for ${name}`);
  }
  const parameters = match[1] ?? match[2] ?? "";
  if (parameters.trim() === "") return [];
  return parameters.split(",").map((parameter) => parameter.trim());
}

function specialFactoryArguments(name, expectedKind) {
  const factory = ts.factory;
  const id = () => factory.createIdentifier("x");
  switch (name) {
    case "createNodeArray":
      return [[], false];
    case "createNumericLiteral":
      return ["0", ts.TokenFlags.None];
    case "createStringLiteral":
      return ["x", false, false];
    case "createLiteralLikeNode":
      return [expectedKind, "x"];
    case "createTemplateLiteralLikeNode":
      return [expectedKind, "x", undefined, 0];
    case "createJsxText":
      return ["x", false];
    case "createIdentifier":
      return ["x", undefined, 0];
    case "createPrivateIdentifier":
      return ["#x"];
    case "createToken":
      return [expectedKind];
    case "createHeritageClause":
      return [ts.SyntaxKind.ExtendsKeyword, []];
    case "createConstructorTypeNode":
      return [undefined, undefined, [], factory.createThisTypeNode()];
    case "createPrefixUnaryExpression":
      return [ts.SyntaxKind.PlusToken, id()];
    case "createPostfixUnaryExpression":
      return [id(), ts.SyntaxKind.PlusPlusToken];
    case "createBinaryExpression":
      return [id(), ts.SyntaxKind.EqualsToken, id()];
    case "createMetaProperty":
      return [ts.SyntaxKind.NewKeyword, id()];
    case "createImportAttributes":
      return [[], false, undefined];
    case "createImportClause":
      return [undefined, id(), undefined];
    case "createSourceFile":
      return [
        [],
        factory.createToken(ts.SyntaxKind.EndOfFileToken),
        ts.NodeFlags.None,
      ];
    default:
      return undefined;
  }
}

function genericFactoryArgument(name, parameter) {
  const factory = ts.factory;
  if (ARRAY_PARAMETERS.has(parameter)) return [];
  if (parameter === "endOfFileToken") {
    return factory.createToken(ts.SyntaxKind.EndOfFileToken);
  }
  if (parameter === "moduleSpecifier") return factory.createStringLiteral("m");
  if (parameter === "head") {
    return factory.createTemplateHead("");
  }
  if (parameter === "template") {
    return factory.createNoSubstitutionTemplateLiteral("");
  }
  if (parameter === "literal" && name.includes("Template")) {
    return factory.createTemplateTail("");
  }
  if (parameter === "flags" || parameter.endsWith("Flags")) return 0;
  if (parameter === "phaseModifier") return undefined;
  if (
    parameter.startsWith("is") ||
    parameter.startsWith("has") ||
    parameter === "multiLine" ||
    parameter === "postfix" ||
    parameter.startsWith("containsOnly")
  ) {
    return false;
  }
  if (parameter === "text" || parameter === "rawText") return "x";
  if (parameter === "comment") return "comment";
  return factory.createIdentifier("x");
}

const NON_PAYLOAD_FIELDS = new Set([
  "pos",
  "end",
  "kind",
  "id",
  "flags",
  "modifierFlagsCache",
  "transformFlags",
  "parent",
  "original",
  "emitNode",
  "symbol",
  "localSymbol",
  "jsDoc",
  "locals",
  "nextContainer",
  "flowNode",
  "flowNodeWhenFalse",
  "flowNodeWhenTrue",
  "endFlowNode",
  "returnFlowNode",
]);

function upstreamFactoryContract(symbol, expectedKind) {
  const name = symbol.slice("NodeFactory.".length);
  const factory = ts.factory[name];
  if (typeof factory !== "function") {
    throw new Error(`installed TypeScript has no factory.${name}`);
  }
  const special = specialFactoryArguments(name, expectedKind);
  const arguments_ = special ??
    factoryParameters(factory, name).map((parameter) =>
      genericFactoryArgument(name, parameter)
    );
  let node;
  try {
    node = factory(...arguments_);
  } catch (error) {
    throw new Error(
      `${symbol} reference invocation failed: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
  return {
    kind: node.kind,
    fields: Object.keys(node).filter((field) => !NON_PAYLOAD_FIELDS.has(field)),
  };
}

function verifyFieldContracts(rows, testFiles) {
  const contracts = fieldContracts(testFiles);
  const mismatches = [];
  for (const row of rows) {
    if (row.upstream_symbol === "NodeFactory.createNodeArray") continue;
    const actual = contracts.get(row.upstream_symbol);
    if (!actual) {
      mismatches.push(`${row.upstream_symbol} has no parsed field contract`);
      continue;
    }
    const expected = upstreamFactoryContract(row.upstream_symbol, actual.kind);
    if (actual.kind !== expected.kind) {
      mismatches.push(
        `${row.upstream_symbol} kind expected ${expected.kind}, got ${actual.kind}`,
      );
    }
    if (JSON.stringify(actual.fields) !== JSON.stringify(expected.fields)) {
      mismatches.push(
        `${row.upstream_symbol} fields expected [${expected.fields.join(", ")}], ` +
          `got [${actual.fields.join(", ")}]`,
      );
    }
  }
  if (mismatches.length > 0) {
    throw new Error(
      `TypeScript factory field-reference mismatch:\n${mismatches.slice(0, 20).join("\n")}`,
    );
  }
  if (contracts.size !== rows.length - 1) {
    throw new Error(
      `expected ${rows.length - 1} node field contracts, found ${contracts.size}`,
    );
  }
}

function upstreamTransformFlagFixtures() {
  const factory = ts.factory;
  const id = () => factory.createIdentifier("x");
  const block = () => factory.createBlock([]);
  const typeNode = () => factory.createThisTypeNode();
  const token = (kind) => factory.createToken(kind);
  const fixtures = new Map();
  const add = (name, node) => fixtures.set(name, node.transformFlags >>> 0);

  add("type-this", typeNode());
  add(
    "parameter-typed",
    factory.createParameterDeclaration(
      undefined,
      undefined,
      id(),
      undefined,
      typeNode(),
      undefined,
    ),
  );
  add(
    "property-declaration",
    factory.createPropertyDeclaration(undefined, id(), undefined, undefined, id()),
  );
  add("class-static-block", factory.createClassStaticBlockDeclaration(block()));
  add(
    "function-async-generator",
    factory.createFunctionDeclaration(
      [factory.createModifier(ts.SyntaxKind.AsyncKeyword)],
      token(ts.SyntaxKind.AsteriskToken),
      id(),
      undefined,
      [],
      undefined,
      block(),
    ),
  );
  add(
    "variable-list-let",
    factory.createVariableDeclarationList([], ts.NodeFlags.Let),
  );
  add(
    "variable-list-using",
    factory.createVariableDeclarationList([], ts.NodeFlags.Using),
  );
  add(
    "for-of-await",
    factory.createForOfStatement(
      token(ts.SyntaxKind.AwaitKeyword),
      id(),
      id(),
      block(),
    ),
  );
  add("catch-no-binding", factory.createCatchClause(undefined, block()));
  add("import-attributes", factory.createImportAttributes([]));
  add("namespace-export", factory.createNamespaceExport(id()));
  add("array-binding", factory.createArrayBindingPattern([]));
  add("object-binding", factory.createObjectBindingPattern([]));
  add("spread-element", factory.createSpreadElement(id()));
  add("await-expression", factory.createAwaitExpression(id()));
  add("yield-expression", factory.createYieldExpression(undefined, id()));
  add(
    "arrow-async",
    factory.createArrowFunction(
      [factory.createModifier(ts.SyntaxKind.AsyncKeyword)],
      undefined,
      [],
      undefined,
      undefined,
      id(),
    ),
  );
  add(
    "dynamic-import",
    factory.createCallExpression(token(ts.SyntaxKind.ImportKeyword), undefined, []),
  );
  add(
    "private-access",
    factory.createPropertyAccessExpression(
      id(),
      factory.createPrivateIdentifier("#x"),
    ),
  );
  add(
    "optional-access",
    factory.createPropertyAccessChain(
      id(),
      token(ts.SyntaxKind.QuestionDotToken),
      id(),
    ),
  );
  add(
    "exponentiation",
    factory.createBinaryExpression(
      id(),
      token(ts.SyntaxKind.AsteriskAsteriskToken),
      id(),
    ),
  );
  add(
    "logical-assignment",
    factory.createBinaryExpression(
      id(),
      token(ts.SyntaxKind.BarBarEqualsToken),
      id(),
    ),
  );
  add(
    "nullish",
    factory.createBinaryExpression(
      id(),
      token(ts.SyntaxKind.QuestionQuestionToken),
      id(),
    ),
  );
  add(
    "destructuring-array-assignment",
    factory.createBinaryExpression(
      factory.createArrayLiteralExpression([]),
      token(ts.SyntaxKind.EqualsToken),
      id(),
    ),
  );
  add(
    "jsx-opening-type-args",
    factory.createJsxOpeningElement(
      id(),
      [typeNode()],
      factory.createJsxAttributes([]),
    ),
  );
  add("jsdoc-function-typed", factory.createJSDocFunctionType([], typeNode()));
  return fixtures;
}

function verifyTransformFlagFixtures(testFiles) {
  const file = testFiles.find(
    ({ name }) => name === "node_factory_transform_flags_wbtest.mbt",
  );
  if (!file) throw new Error("missing transform-flag reference fixture test");
  const actual = new Map();
  const marker = "_assert_transform_bits(";
  let offset = 0;
  while (true) {
    const call = file.text.indexOf(marker, offset);
    if (call < 0) break;
    offset = call + marker.length;
    const arguments_ = splitCallArguments(
      file.text,
      call + marker.length - 1,
    );
    if (!arguments_[0]?.startsWith('"')) continue;
    const name = JSON.parse(arguments_[0]);
    const valueMatch = /^(\d+)U$/.exec(arguments_[2] ?? "");
    if (!valueMatch) {
      throw new Error(`${name} has a malformed transform-flag expectation`);
    }
    if (actual.has(name)) {
      throw new Error(`duplicate transform-flag fixture: ${name}`);
    }
    actual.set(name, Number.parseInt(valueMatch[1], 10));
  }

  const expected = upstreamTransformFlagFixtures();
  const mismatches = [];
  for (const [name, expectedValue] of expected) {
    if (!actual.has(name)) {
      mismatches.push(`missing ${name}`);
    } else if (actual.get(name) !== expectedValue) {
      mismatches.push(
        `${name} expected ${expectedValue}, got ${actual.get(name)}`,
      );
    }
  }
  for (const name of actual.keys()) {
    if (!expected.has(name)) mismatches.push(`unexpected ${name}`);
  }
  if (mismatches.length > 0) {
    throw new Error(
      `TypeScript transform-flag reference mismatch:\n${mismatches.join("\n")}`,
    );
  }
}

function expectedProgress(rows) {
  const moonBitFiles = rootMoonBitFiles();
  const sourceFiles = moonBitFiles
    .filter(
      (name) => !name.endsWith("_test.mbt") && !name.endsWith("_wbtest.mbt"),
    )
    .map((name) => ({ name, text: fs.readFileSync(name, "utf8") }));
  const testFiles = moonBitFiles
    .filter((name) => name.endsWith("_wbtest.mbt"))
    .map((name) => ({ name, text: fs.readFileSync(name, "utf8") }));

  verifyFieldContracts(rows, testFiles);
  verifyTransformFlagFixtures(testFiles);

  return new Map(
    rows.map((row) => [
      row.upstream_symbol,
      {
        moonbit_implementation: exactImplementation(
          row.upstream_symbol,
          sourceFiles,
        ),
        test_location: exactTest(row.upstream_symbol, testFiles),
        status: COMPLETE_STATUS,
      },
    ]),
  );
}

function main(argv) {
  const mode = parseArguments(argv);
  verifyInstalledTypeScript(ts.version);
  const audit = parseTsv(fs.readFileSync(AUDIT_PATH, "utf8"));
  const expectedHeaders = [
    "upstream_symbol",
    "parser_access",
    "source_locations",
    ...PROGRESS_COLUMNS,
  ];
  if (JSON.stringify(audit.headers) !== JSON.stringify(expectedHeaders)) {
    throw new Error(`${AUDIT_PATH} has unexpected columns`);
  }
  if (audit.rows.length !== 195) {
    throw new Error(`expected 195 factory rows, found ${audit.rows.length}`);
  }
  const symbols = new Set(audit.rows.map((row) => row.upstream_symbol));
  if (symbols.size !== audit.rows.length) {
    throw new Error(`${AUDIT_PATH} contains duplicate factory symbols`);
  }

  const progress = expectedProgress(audit.rows);
  if (mode === "write") {
    for (const row of audit.rows) {
      Object.assign(row, progress.get(row.upstream_symbol));
    }
    fs.writeFileSync(AUDIT_PATH, renderTsv(audit.headers, audit.rows));
    console.log(`closed ${audit.rows.length}/195 NodeFactory audit rows`);
    return;
  }

  const mismatches = [];
  for (const row of audit.rows) {
    const expected = progress.get(row.upstream_symbol);
    for (const column of PROGRESS_COLUMNS) {
      if (row[column] !== expected[column]) {
        mismatches.push(
          `${row.upstream_symbol} ${column}: expected ${expected[column]}, got ${row[column] || "<empty>"}`,
        );
      }
    }
  }
  if (mismatches.length > 0) {
    throw new Error(
      `factory audit progress is stale:\n${mismatches.slice(0, 20).join("\n")}`,
    );
  }
  console.log(
    `verified ${audit.rows.length}/195 NodeFactory implementations, ` +
      `${audit.rows.length - 1} node field/kind references, and 26 transform-flag fixtures`,
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
