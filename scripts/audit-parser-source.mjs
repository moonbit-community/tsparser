#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

import ts from "typescript";

import {
  assert,
  assertDeepEqual,
  assertEqual,
  parseMode,
} from "./audit-support.mjs";
import { verifyInstalledTypeScript } from "./upstream-config.mjs";

const FIXTURE_DIRECTORY = "fixtures/source";
const AUDIT_PATH = "docs/upstream-audit/parser-source-json-pragmas.tsv";

function diagnostics(file) {
  return file.parseDiagnostics.map((diagnostic) =>
    `${diagnostic.code}@${diagnostic.start}:${diagnostic.length}`);
}

function wrapper(fileName, text, options = {}) {
  return ts.createSourceFile(
    fileName,
    text,
    {
      languageVersion: options.languageVersion ?? ts.ScriptTarget.Latest,
      jsDocParsingMode: options.jsDocParsingMode ?? ts.JSDocParsingMode.ParseAll,
    },
    options.parents ?? false,
    options.scriptKind,
  );
}

function readFixture(name) {
  return fs.readFileSync(path.join(FIXTURE_DIRECTORY, name), "utf8");
}

function verifyJsonContracts() {
  const validText = readFixture("valid.json");
  const direct = ts.parseJsonText("valid.json", validText);
  const wrapped = wrapper("valid.json", validText, { scriptKind: ts.ScriptKind.JSON });
  for (const [label, file] of [["direct", direct], ["wrapped", wrapped]]) {
    assertEqual(file.languageVersion, ts.ScriptTarget.ES2015, `${label} JSON target`);
    assertEqual(file.languageVariant, ts.LanguageVariant.JSX, `${label} JSON variant`);
    assertEqual(file.scriptKind, ts.ScriptKind.JSON, `${label} JSON script kind`);
    assertEqual(file.statements.length, 1, `${label} JSON statement count`);
    assertEqual(file.statements[0].expression.kind, ts.SyntaxKind.ObjectLiteralExpression, `${label} JSON root`);
    assertDeepEqual(diagnostics(file), [], `${label} JSON diagnostics`);
    assertEqual(file.hasNoDefaultLib, false, `${label} hasNoDefaultLib`);
  }
  assertEqual(direct.nodeCount, 16, "direct JSON node count");
  assertDeepEqual([...direct.identifiers.keys()], ["name", "values"], "direct JSON identifiers");
  assertEqual(direct.referencedFiles, undefined, "direct JSON references");
  assertEqual(direct.pragmas, undefined, "direct JSON pragmas");
  assertDeepEqual(wrapped.referencedFiles, [], "wrapped JSON references");
  assertEqual(wrapped.pragmas.size, 0, "wrapped JSON pragmas");

  const multiple = wrapper("multiple.json", readFixture("multiple.json"), {
    scriptKind: ts.ScriptKind.JSON,
  });
  assertDeepEqual(diagnostics(multiple), ["1012@9:1"], "multiple-root JSON diagnostics");
  assertEqual(multiple.statements[0].expression.kind, ts.SyntaxKind.ArrayLiteralExpression, "multiple-root synthetic array");
  assertEqual(multiple.statements[0].expression.elements.length, 3, "multiple-root element count");
  assertEqual(multiple.statements[0].expression.elements.pos, -1, "synthetic array list pos");

  const conversionText = readFixture("conversion.json");
  const directConversion = ts.parseJsonText("conversion.json", conversionText);
  const wrappedConversion = wrapper("conversion.json", conversionText, {
    scriptKind: ts.ScriptKind.JSON,
  });
  assertDeepEqual(diagnostics(directConversion), [], "direct JSON skips conversion");
  assertDeepEqual(diagnostics(wrappedConversion), [
    "1327@4:6",
    "1327@12:6",
    "1136@22:9",
    "1136@35:6",
    "1327@50:6",
    "1328@59:9",
    "1328@70:2",
    "8009@85:1",
    "1327@77:8",
  ], "wrapped convertToJson diagnostics");

  const targetOverride = wrapper("forced.ts", "{}", {
    languageVersion: ts.ScriptTarget.JSON,
    scriptKind: ts.ScriptKind.TS,
  });
  assertEqual(targetOverride.scriptKind, ts.ScriptKind.JSON, "JSON target route priority");
  assertEqual(targetOverride.languageVersion, ts.ScriptTarget.ES2015, "JSON target normalized result");
}

function verifyPragmasAndMetadata() {
  const file = wrapper("pragmas.ts", readFixture("pragmas.ts"), {
    scriptKind: ts.ScriptKind.TS,
  });
  assertDeepEqual([...file.pragmas.keys()], [
    "reference",
    "amd-dependency",
    "amd-module",
    "ts-check",
    "ts-nocheck",
    "jsx",
    "jsxfrag",
    "jsximportsource",
    "jsxruntime",
  ], "pragma key order");
  assertDeepEqual(file.referencedFiles, [
    { pos: 21, end: 25, fileName: "a.ts", preserve: true },
  ], "path references");
  assertDeepEqual(file.typeReferenceDirectives, [
    { pos: 68, end: 72, fileName: "node", resolutionMode: ts.ModuleKind.ESNext },
    { pos: 124, end: 127, fileName: "bad" },
  ], "type references");
  assertDeepEqual(file.libReferenceDirectives, [
    { pos: 178, end: 184, fileName: "es2025" },
  ], "lib references");
  assertDeepEqual(file.amdDependencies, [
    { name: "named", path: "dep-a" },
    { name: undefined, path: "dep-b" },
  ], "AMD dependencies");
  assertEqual(file.moduleName, "second", "AMD module name");
  assertDeepEqual(file.checkJsDirective, { enabled: false, end: 424, pos: 410 }, "latest check directive");
  assertEqual(file.hasNoDefaultLib, false, "6.0.3 ignored no-default-lib");
  assertDeepEqual(diagnostics(file), [
    "1453@124:3",
    "1084@229:17",
    "2458@364:32",
  ], "pragma diagnostics");
  assert(file.externalModuleIndicator === file.statements[0], "external indicator node identity");
  assertEqual(file.jsDocParsingMode, ts.JSDocParsingMode.ParseAll, "SourceFile JSDoc mode");
}

function verifyMoonBitCoverageMarkers() {
  const sourceTest = fs.readFileSync("parser_source_wbtest.mbt", "utf8");
  const publicTest = fs.readFileSync("parser_public_test.mbt", "utf8");
  for (const marker of [
    "direct and wrapped JSON preserve their distinct contracts",
    "JSON recovery and convertToJson diagnostics match reference order",
    "leading pragmas populate exact SourceFile metadata",
    "SourceFile modes directives policies and parents are finalized",
  ]) {
    assert(sourceTest.includes(marker), `missing SourceFile test marker: ${marker}`);
  }
  for (const marker of [
    "optional targets and script kinds",
    "parent JSDoc implied-format and module-policy options",
    "all five public parsing entries",
    "nested public parses keep invocation state isolated",
  ]) {
    assert(publicTest.includes(marker), `missing public API test marker: ${marker}`);
  }
  const tsv = fs.readFileSync(AUDIT_PATH, "utf8").trimEnd().split("\n");
  assertEqual(tsv.length, 9, "audit row count");
  for (const row of tsv.slice(1)) {
    assert(row.includes("complete"), `incomplete audit row: ${row}`);
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-parser-source.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  verifyJsonContracts();
  verifyPragmasAndMetadata();
  verifyMoonBitCoverageMarkers();
  console.log("verified JSON entry split, nine pragmas, SourceFile metadata, and ordered diagnostics");
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
