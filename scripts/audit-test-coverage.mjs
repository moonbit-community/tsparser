#!/usr/bin/env node

import fs from "node:fs";

import { assert, parseMode, readTsv } from "./audit-support.mjs";

const TABLES = [
  ["docs/upstream-audit/syntax-kind.tsv", 359],
  ["docs/upstream-audit/diagnostics.tsv", 148],
  ["docs/upstream-audit/node-factory.tsv", 195],
  ["docs/upstream-audit/for-each-child.tsv", 175],
  ["docs/upstream-audit/parsing-context.tsv", 26],
];

function verifyAuditTables() {
  for (const [filePath, expectedRows] of TABLES) {
    const rows = readTsv(filePath).rows;
    assert(rows.length === expectedRows, `${filePath}: expected ${expectedRows} rows`);
    for (const row of rows) {
      assert(row.status === "complete", `${filePath}: incomplete ${row.upstream_symbol}`);
      assert(row.test_location, `${filePath}: untested ${row.upstream_symbol}`);
      for (const location of row.test_location.split(";").map((item) => item.trim())) {
        assert(fs.existsSync(location), `${filePath}: missing test location ${location}`);
        const source = fs.readFileSync(location, "utf8");
        assert(/\btest\b|--verify|assert/.test(source), `${location}: no executable test/audit marker`);
      }
    }
  }
  const flags = fs.readFileSync("flags_values_wbtest.mbt", "utf8");
  for (const marker of ["NodeFlags", "TransformFlags", "TokenFlags", "ModifierFlags"]) {
    assert(flags.includes(marker), `flags_values_wbtest.mbt: missing ${marker}`);
  }
}

function verifyFeatureSuites() {
  const required = new Map([
    ["source_text_wbtest.mbt", ["UTF-16", "surrogate"]],
    ["scanner_token_coverage_wbtest.mbt", ["token"]],
    ["scanner_wbtest.mbt", ["rescan", "numeric overflow"]],
    ["parser_core_wbtest.mbt", ["rollback", "semicolon"]],
    ["parser_expressions_wbtest.mbt", ["operator matrix", "missing block"]],
    ["parser_jsx_wbtest.mbt", ["generic", "nested"]],
    ["parser_statements_wbtest.mbt", ["@dec", "ASI"]],
    ["parser_modules_wbtest.mbt", ["module", "await"]],
    ["parser_jsdoc_wbtest.mbt", ["JSDoc", "diagnostic"]],
    ["parser_source_wbtest.mbt", ["JSON", "parent"]],
    ["parser_invariants_wbtest.mbt", ["deterministic mutations", "high-volume diagnostics"]],
  ]);
  for (const [filePath, markers] of required) {
    const source = fs.readFileSync(filePath, "utf8");
    assert((source.match(/^test /gm) ?? []).length > 0, `${filePath}: no tests`);
    for (const marker of markers) {
      assert(source.toLowerCase().includes(marker.toLowerCase()), `${filePath}: missing ${marker}`);
    }
  }
  const allTests = fs.readdirSync(".").filter((name) => /_(?:wb)?test\.mbt$/.test(name));
  const inspectCount = allTests.reduce((count, name) => {
    const source = fs.readFileSync(name, "utf8");
    return count + (source.match(/\b(?:debug_)?inspect\s*\(/g) ?? []).length;
  }, 0);
  assert(inspectCount >= 100, `expected stable inspect snapshots, found ${inspectCount}`);
}

function verifyCoverageMapping() {
  const summary = fs.readFileSync("docs/coverage/summary.txt", "utf8");
  const total = summary.match(/^Total: (\d+)\/(\d+)$/m);
  assert(total, "coverage summary has no total");
  assert(Number(total[1]) > 0 && Number(total[2]) >= Number(total[1]), "invalid coverage total");
  assert(!summary.includes("tools/diff"), "native-only diff tool leaked into root coverage acceptance");
  const mapping = readTsv("docs/coverage/uncovered.tsv").rows;
  const mappedPoints = mapping.reduce((sum, row) => sum + Number(row.uncovered_points), 0);
  assert(mappedPoints === Number(total[2]) - Number(total[1]), "coverage mapping count mismatch");
  for (const row of mapping) {
    assert(row.audit_contract, `${row.file}: missing coverage contract`);
    assert(row.disposition === "mapped_to_audited_contract", `${row.file}: unexplained`);
    assert(!/exempt/i.test(row.disposition), `${row.file}: unreviewed exemption`);
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-test-coverage.mjs --verify",
  );
  verifyAuditTables();
  verifyFeatureSuites();
  verifyCoverageMapping();
  console.log("verified five exhaustive audit tables, feature suites, and mapped root coverage points");
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
