import assert from "node:assert/strict";
import test from "node:test";

import ts from "typescript";

import {
  createReferenceSourceFile,
  diagnosticRecords,
  fullAstRecords,
  scannerRecords,
  serializeDiagnostic,
  sourceFileProjection,
} from "./ts-reference.mjs";

function recordsFor(text, fileName = "fixture.ts", options = {}) {
  const sourceFile = createReferenceSourceFile(fileName, text, options);
  return { sourceFile, records: [...fullAstRecords(sourceFile)] };
}

test("full AST keeps numeric kind, runtime alias, declarations, and markers distinct", () => {
  const { records } = recordsFor("const value = 1;\n");
  const numeric = records.find(
    (record) => record.record === "node" && record.kind.value === ts.SyntaxKind.NumericLiteral,
  );
  assert.ok(numeric);
  assert.equal(numeric.kind.value, 9);
  assert.equal(numeric.kind.runtime_reverse_name, "FirstLiteralToken");
  assert.deepEqual(numeric.kind.declaration_names, ["NumericLiteral"]);
  assert.deepEqual(numeric.kind.classification_markers, ["FirstLiteralToken"]);
  assert.equal(numeric.fields.text, "1");
  assert.equal(numeric.fields.numericLiteralFlags, 0);

  const statement = records.find(
    (record) => record.record === "node" && record.path === "/statements/0",
  );
  assert.equal(statement.kind.runtime_reverse_name, "FirstStatement");
  assert.deepEqual(statement.kind.declaration_names, ["VariableStatement"]);
  assert.deepEqual(statement.kind.classification_markers, ["FirstStatement"]);
});

test("full AST emits named children and NodeArray metadata in source child order", () => {
  const { records } = recordsFor("function f(a: number, b = 1) { return a + b; }\n");
  const declaration = records.find(
    (record) => record.record === "node" && record.kind.value === ts.SyntaxKind.FunctionDeclaration,
  );
  assert.deepEqual(
    declaration.child_edges.map((edge) => edge.field),
    ["name", "parameters", "body"],
  );
  assert.equal(declaration.fields.asteriskToken.state, "undefined");
  assert.equal(declaration.fields.type.state, "undefined");

  const parameters = records.find(
    (record) => record.record === "node_array" && record.path.endsWith("/parameters"),
  );
  assert.equal(parameters.length, 2);
  assert.equal(parameters.has_trailing_comma, false);
  assert.equal(typeof parameters.pos.raw_offset, "number");
  assert.equal(typeof parameters.end.raw_offset, "number");

  const parameterPaths = records
    .filter((record) => record.record === "node" && record.field === "parameters")
    .map((record) => record.path);
  assert.deepEqual(parameterPaths, ["/statements/0/parameters/0", "/statements/0/parameters/1"]);
});

test("full AST preserves raw missing-node ranges and parser diagnostics", () => {
  const { sourceFile, records } = recordsFor("let = ;\n");
  assert.ok(sourceFile.parseDiagnostics.length > 0);
  const zeroWidth = records.find(
    (record) =>
      record.record === "node" &&
      record.pos.raw_offset === record.end.raw_offset &&
      record.kind.value === ts.SyntaxKind.Identifier,
  );
  assert.ok(zeroWidth, "expected a zero-width missing identifier");
  assert.equal(zeroWidth.pos.raw_offset, zeroWidth.pos.clipped_offset);
  assert.ok(zeroWidth.flags !== 0);
});

test("structured diagnostics preserve array order, message chains, and related information", () => {
  const sourceFile = createReferenceSourceFile("broken.ts", "let = ;\n");
  const records = [...diagnosticRecords(sourceFile)];
  assert.deepEqual(records.map((record) => record.index),
    Array.from({ length: records.length }, (_, index) => index));
  assert.ok(records.every((record) => record.record === "parse_diagnostic"));

  const synthetic = serializeDiagnostic({
    file: sourceFile,
    start: -2,
    length: 3,
    category: ts.DiagnosticCategory.Error,
    code: 9000,
    messageText: {
      messageText: "outer",
      category: ts.DiagnosticCategory.Error,
      code: 9000,
      next: [
        {
          messageText: "inner",
          category: ts.DiagnosticCategory.Message,
          code: 9001,
        },
      ],
    },
    relatedInformation: [
      {
        file: sourceFile,
        start: 0,
        length: 1,
        category: ts.DiagnosticCategory.Message,
        code: 9002,
        messageText: "related",
      },
    ],
  });
  assert.equal(synthetic.start, -2);
  assert.equal(synthetic.location.raw_offset, -2);
  assert.equal(synthetic.location.clipped_offset, 0);
  assert.equal(synthetic.message_text.kind, "chain");
  assert.equal(synthetic.message_text.next[0].message_text, "inner");
  assert.equal(synthetic.related_information[0].message_text.text, "related");
});

test("SourceFile reference records module indicator, identifiers, modes, and counts", () => {
  const sourceFile = createReferenceSourceFile(
    "module.ts",
    "/// <reference path=\"a.ts\" />\nimport { x } from 'm';\n// @ts-ignore\nx;\n",
  );
  const projection = sourceFileProjection(sourceFile);
  assert.equal(projection.script_kind_name, "TS");
  assert.equal(projection.language_version_name, "Latest");
  assert.equal(projection.is_declaration_file, false);
  assert.equal(projection.jsdoc_parsing_mode, ts.JSDocParsingMode.ParseAll);
  assert.equal(projection.referenced_files[0].fileName, "a.ts");
  assert.ok(projection.identifiers.some(([name]) => name === "x"));
  assert.equal(projection.external_module_indicator.node_path, "/statements/0");
  assert.equal(projection.comment_directives.length, 1);
  assert.equal(projection.parse_diagnostic_count, sourceFile.parseDiagnostics.length);
});

test("scanner reference records token state, flags, directives, and diagnostics deterministically", () => {
  const text = "// @ts-ignore\nlet \\u0061 = 0b1__0;\n";
  const first = [...scannerRecords(text, { skipTrivia: false })];
  const second = [...scannerRecords(text, { skipTrivia: false })];
  assert.deepEqual(first, second);
  const identifier = first.find(
    (record) => record.record === "scanner_token" && record.value === "a",
  );
  assert.ok(identifier.has_unicode_escape);
  assert.ok(identifier.flags !== 0);
  const numeric = first.find(
    (record) => record.record === "scanner_token" &&
      record.kind.value === ts.SyntaxKind.NumericLiteral,
  );
  assert.ok(numeric.diagnostics.length > 0);
  const summary = first.at(-1);
  assert.equal(summary.record, "scanner_summary");
  assert.equal(summary.comment_directives.length, 1);
  assert.ok(summary.diagnostics.length > 0);
});

test("full AST projection is deterministic and includes attached JSDoc as an explicit edge", () => {
  const options = { scriptKind: ts.ScriptKind.JS };
  const first = recordsFor("/** @param {number} x */\nfunction f(x) {}\n", "fixture.js", options).records;
  const second = recordsFor("/** @param {number} x */\nfunction f(x) {}\n", "fixture.js", options).records;
  assert.deepEqual(first, second);
  const host = first.find(
    (record) => record.record === "node" && record.kind.value === ts.SyntaxKind.FunctionDeclaration,
  );
  assert.ok(host.child_edges.some((edge) => edge.field === "jsDoc" && edge.traversal === "parser_extra"));
  assert.ok(first.some(
    (record) => record.record === "node" && record.kind.runtime_reverse_name.startsWith("JSDoc"),
  ));
});

test("full AST maps element-wise JSDoc child callbacks back to their list field", () => {
  const source = [
    "/**",
    " * @typedef {Object} Foo",
    " * @property {boolean} a",
    " * @property {boolean} b",
    " */",
    "const value = {};",
    "",
  ].join("\n");
  const { records } = recordsFor(source);
  const properties = records.find(
    (record) => record.record === "node_array" && record.field === "jsDocPropertyTags",
  );
  assert.ok(properties);
  assert.equal(properties.length, 2);
  assert.deepEqual(
    records
      .filter((record) => record.record === "node" && record.field === "jsDocPropertyTags")
      .map((record) => record.path),
    [
      `${properties.parent_path}/jsDocPropertyTags/0`,
      `${properties.parent_path}/jsDocPropertyTags/1`,
    ],
  );
});
