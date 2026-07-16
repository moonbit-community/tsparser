#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";

import { parseMode } from "./audit-support.mjs";

const DIRECTORY = "docs/coverage";
const CARET_PATH = `${DIRECTORY}/caret.txt`;
const SUMMARY_PATH = `${DIRECTORY}/summary.txt`;
const MAPPING_PATH = `${DIRECTORY}/uncovered.tsv`;

function runMoon(args) {
  const result = spawnSync("moon", args, {
    cwd: process.cwd(),
    encoding: "utf8",
    maxBuffer: 16 * 1024 * 1024,
  });
  if (result.status !== 0) {
    throw new Error(`moon ${args.join(" ")} failed\n${result.stdout}\n${result.stderr}`);
  }
  return result.stdout;
}

function contractFor(file) {
  if (/^scanner(?:_|\.)/.test(file)) return "scanner";
  if (/^parser_(?:state|lists|tokens|names_literals)/.test(file)) return "parser_core";
  if (/^parser_(?:types|parameters_signatures)/.test(file)) return "parser_types_signatures";
  if (/^parser_expression/.test(file)) return "parser_expressions";
  if (/^parser_(?:bindings_variables|declarations|statements)/.test(file)) return "parser_statements_declarations";
  if (/^parser_(?:modules|source_file)/.test(file)) return "parser_modules_source";
  if (file === "parser_jsx.mbt") return "parser_jsx_tsx";
  if (/^parser_jsdoc/.test(file)) return "parser_jsdoc";
  if (/^parser_(?:pragmas|public)/.test(file)) return "parser_source_public";
  if (file === "for_each_child.mbt") return "child_traversal";
  if (/^ast_|^node_|^parent_links/.test(file)) return "ast_factory";
  if (/^diagnostic/.test(file)) return "diagnostics";
  if (/^flags|^options|^syntax_kind|^line_map|^source_text|^text_range/.test(file)) {
    return "representation_constants";
  }
  return "root_support_contract";
}

function mappingFromReports(caret, summary) {
  const linesByFile = new Map();
  for (const match of caret.matchAll(/^ --> ([^:\n]+):(\d+)$/gm)) {
    const lines = linesByFile.get(match[1]) ?? new Set();
    lines.add(Number(match[2]));
    linesByFile.set(match[1], lines);
  }
  const lines = [
    "file\tuncovered_points\tuncovered_lines\taudit_contract\tdisposition\treason",
  ];
  let pointCount = 0;
  for (const match of summary.matchAll(/^([^:\n]+): (\d+)\/(\d+)$/gm)) {
    const file = match[1];
    if (file === "Total") continue;
    const uncovered = Number(match[3]) - Number(match[2]);
    if (uncovered === 0) continue;
    const uncoveredLines = [...(linesByFile.get(file) ?? [])].sort((left, right) => left - right);
    if (uncoveredLines.length === 0) throw new Error(`${file}: no caret locations for ${uncovered} points`);
    const contract = contractFor(file);
    pointCount += uncovered;
    lines.push(
      [
        file,
        uncovered,
        uncoveredLines.join(","),
        contract,
        "mapped_to_audited_contract",
        "retained as an explicit uncovered point; no unreachable or platform exemption claimed",
      ].join("\t"),
    );
  }
  if (pointCount === 0) throw new Error("coverage reports did not contain uncovered points");
  return `${lines.join("\n")}\n`;
}

function compare(path, actual) {
  if (!fs.existsSync(path)) throw new Error(`missing generated coverage artifact: ${path}`);
  const expected = fs.readFileSync(path, "utf8");
  if (expected !== actual) throw new Error(`${path} is stale; run npm run generate:coverage`);
}

function main(argv) {
  const mode = parseMode(
    argv,
    ["write", "verify"],
    "usage: node scripts/generate-coverage.mjs <--write|--verify>",
  );
  runMoon(["coverage", "clean"]);
  const caret = runMoon([
    "coverage",
    "analyze",
    "-p",
    "moonbit-community/tsparser",
    "--",
    "-f",
    "caret",
  ]);
  const summary = runMoon([
    "coverage",
    "analyze",
    "-p",
    "moonbit-community/tsparser",
    "--",
    "-f",
    "summary",
  ]);
  const mapping = mappingFromReports(caret, summary);
  if (mode === "write") {
    fs.mkdirSync(DIRECTORY, { recursive: true });
    fs.writeFileSync(CARET_PATH, caret);
    fs.writeFileSync(SUMMARY_PATH, summary);
    fs.writeFileSync(MAPPING_PATH, mapping);
    console.log(`wrote ${CARET_PATH}, ${SUMMARY_PATH}, and ${MAPPING_PATH}`);
  } else {
    compare(CARET_PATH, caret);
    compare(SUMMARY_PATH, summary);
    compare(MAPPING_PATH, mapping);
    console.log(`verified current coverage reports and ${mapping.split("\n").length - 2} mapped files`);
  }
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
