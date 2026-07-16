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
  testBlock,
} from "./parser-audit-support.mjs";
import {
  DEFAULT_TYPESCRIPT_SOURCE_DIR,
  verifyInstalledTypeScript,
} from "./upstream-config.mjs";

const PARSER_SOURCE_PATH =
  `${DEFAULT_TYPESCRIPT_SOURCE_DIR}/src/compiler/parser.ts`;
const AUDIT_PATH =
  "docs/upstream-audit/parser-modules-top-level-await.tsv";
const TEST_PATH = "parser_modules_wbtest.mbt";
const MODULE_IMPLEMENTATION_PATH = "parser_modules.mbt";
const SOURCE_IMPLEMENTATION_PATH = "parser_source_file.mbt";

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
      "import_modifier_and_dispatch",
      "import_clauses_and_references",
      "specifier_names_and_ambiguity",
      "module_import_attributes",
      "export_forms",
      "external_module_indicator",
      "source_file_policy_and_format",
      "top_level_await_intervals",
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
  assertEqual(symbols.size, 45, "upstream helper count");
}

function parseSource(source, options = {}) {
  const createOptions = { languageVersion: ts.ScriptTarget.Latest };
  if (options.impliedNodeFormat !== undefined) {
    createOptions.impliedNodeFormat = options.impliedNodeFormat;
  }
  if (options.indicator === "clear") {
    createOptions.setExternalModuleIndicator = (file) => {
      file.externalModuleIndicator = undefined;
    };
  } else if (options.indicator === "force") {
    createOptions.setExternalModuleIndicator = (file) => {
      file.externalModuleIndicator = true;
    };
  }
  return ts.createSourceFile(
    options.fileName ?? "module.ts",
    source,
    createOptions,
    options.parents ?? true,
    ts.ScriptKind.TS,
  );
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

function flagShape(file) {
  const result = [];
  function visit(node) {
    result.push(
      `${node.kind}@${node.pos}:${node.end}:${node.flags}:${node.transformFlags}`,
    );
    ts.forEachChild(node, visit);
  }
  for (const statement of file.statements) visit(statement);
  return result.join(",");
}

function diagnosticShape(file) {
  return file.parseDiagnostics
    .map((diagnostic) =>
      `${diagnostic.code}@${diagnostic.start}:${diagnostic.length}`)
    .join(",");
}

function verifyModuleFixtures(testSource) {
  const fixtures = extractStringPairs(
    testBlock(
      testSource,
      "import and export preorder ranges and lists match TypeScript",
    ),
  );
  assertEqual(fixtures.length, 15, "exact module fixture count");
  const coveredKinds = new Set();
  for (const [source, expected] of fixtures) {
    const file = parseSource(source);
    assertEqual(statementArrayShape(file), expected, `module reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected TS diagnostic for ${source}`);
    function collect(node) {
      coveredKinds.add(node.kind);
      ts.forEachChild(node, collect);
    }
    for (const statement of file.statements) collect(statement);
  }
  const requiredKinds = [
    271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282,
    284, 301, 302,
  ];
  assertDeepEqual(
    requiredKinds.filter((kind) => coveredKinds.has(kind)),
    requiredKinds,
    "all module SyntaxKinds",
  );
}

function importModifierShape(file) {
  const statement = file.statements[0];
  if (statement.kind === ts.SyntaxKind.ImportEqualsDeclaration) {
    return `272:${statement.isTypeOnly ? "type" : "value"}:${statement.name.text}`;
  }
  const clause = statement.importClause;
  const modifier = clause.phaseModifier === undefined ? "none" : clause.phaseModifier;
  return `273:${clause.isTypeOnly ? "type" : "value"}:${modifier}:` +
    (clause.name?.text ?? "<none>");
}

function verifyImportModifierAmbiguity(testSource) {
  const fixtures = extractStringPairs(
    testBlock(
      testSource,
      "type and defer import modifier ambiguity matches TypeScript 6.0.3",
    ),
  );
  assertEqual(fixtures.length, 10, "import modifier fixture count");
  for (const [source, expected] of fixtures) {
    const file = parseSource(source);
    assertEqual(importModifierShape(file), expected, `import modifier reference for ${source}`);
    assertEqual(file.parseDiagnostics.length, 0, `unexpected modifier diagnostic for ${source}`);
  }
}

function nameShape(node) {
  if (!node) return "none";
  return `${node.kind}:${node.text ?? node.escapedText ?? ""}`;
}

function specifierShape(specifier) {
  return `${specifier.isTypeOnly ? "type" : "value"}:` +
    `${nameShape(specifier.propertyName)}:${nameShape(specifier.name)}`;
}

function verifySpecifiersAndAttributes() {
  const imports = parseSource(
    "import { type, type as, type as as, type as as as, type x, a as b, \"x\" as y, default as d, await as a } from \"m\";",
  );
  assertDeepEqual(
    imports.statements[0].importClause.namedBindings.elements.map(specifierShape),
    [
      "value:none:80:type",
      "type:none:80:as",
      "value:80:type:80:as",
      "type:80:as:80:as",
      "type:none:80:x",
      "value:80:a:80:b",
      "value:11:x:80:y",
      "value:80:default:80:d",
      "value:80:await:80:a",
    ],
    "import specifier ambiguity",
  );
  const exports = parseSource(
    "export { default, class as c, \"x\" as \"y\" };",
  );
  assertDeepEqual(
    exports.statements[0].exportClause.elements.map(specifierShape),
    [
      "value:none:80:default",
      "value:80:class:80:c",
      "value:11:x:11:y",
    ],
    "export module names",
  );

  const asserted = parseSource(
    "import x from \"m\" assert {type: \"json\"};",
  ).statements[0];
  assertEqual(asserted.attributes.token, ts.SyntaxKind.AssertKeyword, "assert token");
  assertEqual(asserted.attributes.multiLine, false, "single-line attributes");
  assert(asserted.attributes === asserted.assertClause, "attribute alias identity");

  const multiline = parseSource(
    "import x from \"m\" with {\n type: \"json\", type: \"css\",\n};",
  ).statements[0].attributes;
  assertEqual(multiline.token, ts.SyntaxKind.WithKeyword, "with token");
  assertEqual(multiline.multiLine, true, "multiline attributes");
  assertEqual(multiline.elements.length, 2, "duplicate attribute count");
  assertEqual(multiline.elements.hasTrailingComma, true, "attribute trailing comma");
  assertDeepEqual(multiline.elements.map((entry) => entry.name.text), ["type", "type"], "duplicate attribute names");

  assertEqual(
    diagnosticShape(parseSource("import x from \"m\"\nassert {type: \"json\"};")),
    "1435@18:6",
    "assert line-break boundary",
  );
  const withNewline = parseSource(
    "import x from \"m\"\nwith {type: \"json\"};",
  );
  assert(withNewline.statements[0].attributes, "with after a line break must parse");
}

function verifyRecovery() {
  const fixtures = [
    ["import { \"x\" } from \"m\";", "1003@9:3"],
    ["import { default } from \"m\";", "1003@9:7"],
    ["import { a as \\u0064efault } from \"m\";", "1003@14:12"],
    ["import { a b } from \"m\";", "1005@11:1"],
    ["export { from \"m\";", "1005@9:4"],
    ["export * \"m\";", "1005@9:3"],
    ["import x from \"m\" with { type \"json\" };", "1005@30:6"],
  ];
  for (const [source, expected] of fixtures) {
    assertEqual(diagnosticShape(parseSource(source)), expected, `recovery for ${source}`);
  }
  for (const source of [
    "import { \\u0061 as b } from \"m\";",
    "import { \\u0064efault as d } from \"m\";",
    "export { \\u0064efault as d };",
    "import q = require(1 + x);",
    "import q = require;",
  ]) {
    assertEqual(parseSource(source).parseDiagnostics.length, 0, `valid module name ${source}`);
  }
  const missingClose = parseSource(
    "import x from \"m\" with { type: \"json\"",
  ).parseDiagnostics;
  assertEqual(
    `${missingClose[0].code}@${missingClose[0].start}:${missingClose[0].length}`,
    "1005@37:0",
    "missing attribute close",
  );
  assertDeepEqual(
    missingClose[0].relatedInformation.map((diagnostic) => [
      diagnostic.code,
      diagnostic.start,
      diagnostic.length,
    ]),
    [[1007, 23, 1]],
    "missing attribute close related information",
  );
}

function verifyExternalModulePolicy() {
  const defaultModule = parseSource("const x=0; import \"m\"; export {};");
  assert(
    defaultModule.externalModuleIndicator === defaultModule.statements[1],
    "first top-level import must be the indicator",
  );
  const importMeta = parseSource(
    "function f(){ return import.meta; } await + 1;",
  );
  assertEqual(importMeta.externalModuleIndicator.kind, 237, "import.meta fallback indicator");
  for (const source of [
    "import q = require(\"m\");",
    "export const x=1;",
    "import \"m\";",
    "export default 1;",
    "export {};",
  ]) {
    assert(parseSource(source).externalModuleIndicator !== undefined, `module indicator for ${source}`);
  }
  for (const source of [
    "import q = R.S;",
    "import q = require;",
    "export as namespace UMD;",
    "const x=1;",
  ]) {
    assertEqual(parseSource(source).externalModuleIndicator, undefined, `no module indicator for ${source}`);
  }
  const forced = parseSource("await + 1; const x=2;", {
    indicator: "force",
    impliedNodeFormat: ts.ModuleKind.CommonJS,
  });
  assertEqual(forced.externalModuleIndicator, true, "forced true indicator");
  assertEqual(forced.impliedNodeFormat, ts.ModuleKind.CommonJS, "CommonJS implied format");
  assertEqual(forced.nodeCount, 17, "forced-module reparse node count");
  const cleared = parseSource("export {}; await + 1;", {
    indicator: "clear",
    impliedNodeFormat: ts.ModuleKind.ESNext,
  });
  assertEqual(cleared.externalModuleIndicator, undefined, "cleared module indicator");
  assertEqual(cleared.impliedNodeFormat, ts.ModuleKind.ESNext, "ESNext implied format");
  assert(
    cleared.statements[1].transformFlags & ts.TransformFlags.ContainsPossibleTopLevelAwait,
    "cleared module must retain first-pass possible-await shape",
  );
}

function verifyTopLevelAwait() {
  const simpleSource =
    "export {}; const before=0; await + 1; const after=2;";
  const simple = parseSource(simpleSource);
  assertEqual(simple.nodeCount, 24, "simple reparse node count");
  assertEqual(simple.identifierCount, 3, "simple reparse identifier count");
  assertEqual(
    flagShape(simple),
    "279@0:10:0:0,280@6:9:65536:0,244@10:26:0:4457472,262@10:25:2:4457472,261@16:25:0:0,80@16:23:0:0,9@24:25:0:0,245@26:37:65536:2097536,224@26:36:65536:2097536,225@32:36:65536:0,9@34:36:65536:0,244@37:52:0:4457472,262@37:51:2:4457472,261@43:51:0:0,80@43:49:0:0,9@50:51:0:0",
    "simple top-level-await flag shape",
  );
  const simpleFirstPass = parseSource(simpleSource, { indicator: "clear" });
  assertEqual(simpleFirstPass.nodeCount, 19, "simple first-pass node count");
  assertEqual(simpleFirstPass.identifierCount, 3, "simple first-pass identifier count");

  const expansionSource =
    "export {}; const before=0; await\nfunction f(){}\nconst after=1;";
  const expansion = parseSource(expansionSource);
  assertEqual(expansion.nodeCount, 30, "expanded reparse node count");
  assertEqual(expansion.identifierCount, 6, "expanded reparse identifier count");
  assertDeepEqual(
    expansion.statements.map((statement) => [
      statement.kind,
      statement.pos,
      statement.end,
      statement.flags,
    ]),
    [
      [279, 0, 10, 0],
      [244, 10, 26, 0],
      [245, 26, 47, 65536],
      [244, 47, 62, 65536],
    ],
    "expanded interval statements",
  );
  const expansionFirstPass = parseSource(expansionSource, { indicator: "clear" });
  assertEqual(expansionFirstPass.nodeCount, 19, "expanded first-pass node count");
  assertEqual(expansionFirstPass.identifierCount, 4, "expanded first-pass identifier count");

  const multiple = parseSource(
    "export {}; await [x]; y; await <T>(z); q;",
  );
  assertEqual(multiple.nodeCount, 31, "multiple-interval node count");
  assertEqual(multiple.identifierCount, 10, "multiple-interval identifier count");
  assert(multiple.statements.every((statement) => statement.parent === multiple), "final statement parents");

  assertEqual(
    diagnosticShape(parseSource("export {}; await (1,); x;")),
    "1109@20:1",
    "reparsed diagnostic replacement",
  );
  assertEqual(
    diagnosticShape(parseSource("export {}; let a = ; await + ; let b = ;")),
    "1109@19:1,1109@29:1,1109@39:1",
    "diagnostic ordering around a reparse interval",
  );
  const declaration = parseSource("export {}; await + 1;", {
    fileName: "ambient.d.mts",
  });
  assert(
    declaration.statements[1].transformFlags & ts.TransformFlags.ContainsPossibleTopLevelAwait,
    "declaration files must not reparse top-level await",
  );
}

function moonFunctionBody(source, marker) {
  const start = source.indexOf(marker);
  assert(start >= 0, `missing MoonBit function ${marker}`);
  const open = source.indexOf("{", start + marker.length);
  assert(open >= 0, `missing body for ${marker}`);
  let depth = 0;
  for (let index = open; index < source.length; index++) {
    if (source[index] === "{") depth++;
    if (source[index] === "}") {
      depth--;
      if (depth === 0) return source.slice(open + 1, index);
    }
  }
  throw new Error(`unterminated MoonBit function ${marker}`);
}

function verifyImplementationShape(moduleSource, sourceImplementation, testSource) {
  for (const fragment of [
    "_parse_import_declaration_or_import_equals",
    "_parse_import_or_export_specifier",
    "_parse_module_import_attributes",
    "_parse_export_declaration",
    "_parse_export_assignment",
  ]) {
    assert(moduleSource.includes(fragment), `missing module implementation ${fragment}`);
  }
  assert(
    !/^pub fn ParserState::_parse_/m.test(moduleSource),
    "module parser methods must remain package-private",
  );
  const reparseBody = moonFunctionBody(
    sourceImplementation,
    "fn ParserState::_reparse_top_level_await_intervals(",
  );
  for (const fragment of [
    "saved_diagnostics = self.diagnostics.copy()",
    "self.diagnostics.clear()",
    "self._reparse(fn()",
    "self._set_await_context(true)",
    "self.scanner._reset_token_state(next_statement.pos())",
    "reparsed.push(statements.get(index).unwrap())",
    "pos = _find_next_statement_without_await",
  ]) {
    assert(reparseBody.includes(fragment), `top-level-await reparse missing ${fragment}`);
  }
  assert(!reparseBody.includes("_new_parser_state"), "interval reparse reinitializes parser state");
  assert(!reparseBody.includes("identifiers.clear"), "interval reparse clears identifier interner");
  assert(!reparseBody.includes("node_count = 0"), "interval reparse resets node count");
  assert(!reparseBody.includes("identifier_count = 0"), "interval reparse resets identifier count");

  const isExternalBody = moonFunctionBody(
    sourceImplementation,
    "pub fn is_external_module(",
  );
  assert(isExternalBody.includes("externalModuleIndicator"), "is_external_module does not read the indicator field");
  assert(!isExternalBody.includes("for_each"), "is_external_module traverses the tree");
  assert(!isExternalBody.includes("import_meta"), "is_external_module searches for import.meta");
  assert(sourceImplementation.includes("impliedNodeFormat"), "implied node format field is not set");
  assert(sourceImplementation.includes("external_module_indicator_policy"), "indicator policy is absent");

  for (const fragment of [
    "same_identity",
    "first_node_count",
    "final_node_count",
    "first_interned_identifier_count",
    "final_interned_identifier_count",
    "initial_stop",
    "final_stop",
    "set_parent_nodes=false",
  ]) {
    assert(testSource.includes(fragment), `invariant test missing ${fragment}`);
  }
}

function verifyFactoryReferences() {
  const factorySource = fs.readFileSync("ast_declarations.mbt", "utf8");
  for (const name of [
    "namespace_export_declaration",
    "import_equals_declaration",
    "import_declaration",
    "import_clause",
    "namespace_import",
    "named_imports",
    "import_specifier",
    "export_assignment",
    "export_declaration",
    "named_exports",
    "namespace_export",
    "export_specifier",
    "external_module_reference",
    "import_attributes",
    "import_attribute",
  ]) {
    assert(
      factorySource.includes(`fn _factory_create_${name}(`),
      `missing module factory ${name}`,
    );
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-parser-modules.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  const parserSource = fs.readFileSync(PARSER_SOURCE_PATH, "utf8");
  const testSource = fs.readFileSync(TEST_PATH, "utf8");
  const moduleSource = fs.readFileSync(MODULE_IMPLEMENTATION_PATH, "utf8");
  const sourceImplementation = fs.readFileSync(SOURCE_IMPLEMENTATION_PATH, "utf8");
  verifyTraceability(parserSource);
  verifyModuleFixtures(testSource);
  verifyImportModifierAmbiguity(testSource);
  verifySpecifiersAndAttributes();
  verifyRecovery();
  verifyExternalModulePolicy();
  verifyTopLevelAwait();
  verifyImplementationShape(moduleSource, sourceImplementation, testSource);
  verifyFactoryReferences();
  console.log(
    "verified 45 parser helpers, 15 module kinds, import modifiers, " +
      "attributes, external-module policy, and identity-preserving top-level-await intervals",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
