#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import { assert, parseMode } from "./audit-support.mjs";

function verifyInterface() {
  const interfaceText = fs.readFileSync("pkg.generated.mbti", "utf8");
  const required = [
    "pub fn create_source_file(String, String, language_version? : ScriptTarget, script_kind? : ScriptKind, set_parent_nodes? : Bool, jsdoc_parsing_mode? : JSDocParsingMode, implied_node_format? : ResolutionMode, external_module_indicator_policy? : (Node) -> ExternalModuleIndicator?) -> Node",
    "pub fn parse_json_text(String, String) -> Node",
    "pub fn parse_isolated_entity_name(String, language_version? : ScriptTarget) -> Node?",
    "pub fn parse_isolated_jsdoc_comment(String, start? : Int, length? : Int) -> JsDocParseResult?",
    "pub fn is_external_module(Node) -> Bool",
  ];
  for (const signature of required) {
    assert(interfaceText.includes(signature), `missing public signature: ${signature}`);
  }
  const forbidden = [
    "pub struct ParserState",
    "pub struct Scanner",
    "pub struct NodeFactory",
    "parse_jsdoc_type_expression_for_tests",
    "parse_program",
    "parse_source",
    "ParseOptions",
    "Program",
    "ParseError",
  ];
  for (const spelling of forbidden) {
    assert(!interfaceText.includes(spelling), `internal API leaked: ${spelling}`);
  }
  for (const spelling of [
    "TextList(ReadOnlyArray[String]?)",
    "DiagnosticList(ReadOnlyArray[Diagnostic]?)",
    "PragmaMapValue(ReadOnlyArray[PragmaEntry]?)",
    "FileReferenceList(ReadOnlyArray[FileReference]?)",
    "CommentDirectiveList(ReadOnlyArray[CommentDirective]?)",
  ]) {
    assert(interfaceText.includes(spelling), `mutable SourceFile collection: ${spelling}`);
  }
}

const header = `fn source_identifiers() -> ReadOnlyArray[String] {
  let file = @tsparser.create_source_file("probe.ts", "const value = 1;")
  match file.field("identifiers") {
    Some(@tsparser.TextList(Some(values))) => values
    _ => abort("missing identifiers")
  }
}

`;

function runProbe(root, parent, name, body, shouldCompile) {
  const probeDirectory = path.join(parent, name);
  fs.mkdirSync(probeDirectory, { recursive: true });
  fs.writeFileSync(
    path.join(probeDirectory, "moon.pkg"),
    'import { "moonbit-community/tsparser" }\n',
  );
  fs.writeFileSync(path.join(probeDirectory, "probe.mbt"), `${header}${body}\n`);
  const targetDirectory = path.join(os.tmpdir(), `tsparser-public-api-build-${process.pid}-${name}`);
  const result = spawnSync(
    "moon",
    ["check", probeDirectory, "--target", "js", "--target-dir", targetDirectory],
    { cwd: root, encoding: "utf8" },
  );
  const output = `${result.stdout ?? ""}\n${result.stderr ?? ""}`;
  if (shouldCompile) {
    assert(result.status === 0, `${name} control probe failed:\n${output}`);
  } else {
    assert(result.status !== 0, `${name} unexpectedly compiled`);
    assert(
      /read-only|has no method|not mutable|Cannot mutate|cannot assign/i.test(output),
      `${name} failed for an unrelated reason:\n${output}`,
    );
  }
  fs.rmSync(targetDirectory, { recursive: true, force: true });
}

function verifyCompileFailProbes() {
  const root = process.cwd();
  const parent = path.join(root, `.public-api-probes-${process.pid}`);
  fs.mkdirSync(parent, { recursive: true });
  try {
    runProbe(
      root,
      parent,
      "readonly_control",
      "pub fn probe() -> String { source_identifiers()[0] }",
      true,
    );
    runProbe(
      root,
      parent,
      "element_assignment",
      'pub fn probe() -> Unit { source_identifiers()[0] = "changed" }',
      false,
    );
    runProbe(
      root,
      parent,
      "push",
      'pub fn probe() -> Unit { source_identifiers().push("changed") }',
      false,
    );
    runProbe(
      root,
      parent,
      "remove",
      "pub fn probe() -> Unit { source_identifiers().remove(0) }",
      false,
    );
    runProbe(
      root,
      parent,
      "clear",
      "pub fn probe() -> Unit { source_identifiers().clear() }",
      false,
    );
  } finally {
    fs.rmSync(parent, { recursive: true, force: true });
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-public-api.mjs --verify",
  );
  verifyInterface();
  verifyCompileFailProbes();
  console.log("verified five public parser entries and four immutable-collection compile-fail probes");
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
