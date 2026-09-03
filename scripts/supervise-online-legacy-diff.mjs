#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import ts from "typescript";

import { parseMode } from "./audit-support.mjs";
import { superviseProcess } from "./process-supervisor.mjs";
import {
  TYPESCRIPT_VERSION,
  verifyInstalledTypeScript,
} from "./upstream-config.mjs";

const BUDGET_PATH = "docs/stress-budgets.json";
const MANIFEST_PATH = "docs/corpus-manifest.jsonl";
const RESULT_PATH = "docs/online-legacy-diff-results.json";
const CAPTURE_LIMIT = 128 * 1024;

async function runSupervised(command, args, options) {
  return superviseProcess({
    command,
    args,
    timeoutMs: options.timeoutMs,
    captureLimit: CAPTURE_LIMIT,
    sampleIntervalMs: 10,
    env: options.env ?? process.env,
  });
}

function assertSuccessful(label, result, fixture) {
  if (result.timedOut) {
    throw new Error(`${label}: timed out after ${fixture.timeout_ms}ms`);
  }
  if (result.code !== 0) {
    throw new Error(
      `${label}: exited ${result.code ?? result.signal}\n${result.stdout}\n${result.stderr}`,
    );
  }
  if (result.peakRssKib > fixture.max_peak_rss_kib) {
    throw new Error(
      `${label}: ${result.peakRssKib} KiB exceeds ${fixture.max_peak_rss_kib} KiB`,
    );
  }
}

function readOnlineInputs() {
  const records = fs
    .readFileSync(MANIFEST_PATH, "utf8")
    .trimEnd()
    .split("\n")
    .map((line) => JSON.parse(line));
  const seen = new Set();
  for (const record of records) {
    if (seen.has(record.input)) throw new Error(`duplicate manifest input: ${record.input}`);
    seen.add(record.input);
  }
  return records
    .filter((record) => record.legacy_ast === null)
    .map((record) => {
      if (record.legacy_ast_mode !== "online_stream") {
        throw new Error(`${record.input}: null legacy AST is not online_stream`);
      }
      if (record.stress_budget !== record.input) {
        throw new Error(`${record.input}: missing matching stress_budget`);
      }
      return record.input;
    });
}

function verifyStoredResults(expectedInputs) {
  if (!fs.existsSync(RESULT_PATH)) throw new Error(`missing ${RESULT_PATH}`);
  const stored = JSON.parse(fs.readFileSync(RESULT_PATH, "utf8"));
  if (stored.typescript_version !== TYPESCRIPT_VERSION) {
    throw new Error(`${RESULT_PATH}: TypeScript version changed`);
  }
  const actualInputs = stored.fixtures.map((fixture) => fixture.input);
  if (JSON.stringify(actualInputs) !== JSON.stringify(expectedInputs)) {
    throw new Error(`${RESULT_PATH}: fixture list differs from the corpus manifest`);
  }
  if (!stored.fixtures.every((fixture) => fixture.within_budget === true)) {
    throw new Error(`${RESULT_PATH}: a recorded fixture did not pass`);
  }
}

function buildDiffTool() {
  const result = spawnSync(
    "moon",
    ["build", "tools/diff", "--target", "native", "--release"],
    { cwd: process.cwd(), encoding: "utf8" },
  );
  if (result.status !== 0) {
    throw new Error(`could not build tools/diff\n${result.stdout}\n${result.stderr}`);
  }
}

async function compareFixture(fixture) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "tsparser-online-legacy-"));
  const expectedAst = path.join(directory, "expected.ast.json");
  const expectedErrors = path.join(directory, "expected.errors.txt");
  try {
    const reference = await runSupervised(
      process.execPath,
      ["scripts/ts-parse-baseline.mjs", fixture.input, expectedAst, expectedErrors],
      {
        timeoutMs: fixture.timeout_ms,
        env: { ...process.env, TS_PARSE_BASELINE_MAX_AST_BYTES: "0" },
      },
    );
    assertSuccessful(`${fixture.input}: streaming reference`, reference, fixture);
    if (!fs.existsSync(expectedAst)) {
      throw new Error(`${fixture.input}: streaming reference did not produce an AST`);
    }

    const diff = await runSupervised(
      "moon",
      [
        "run",
        "tools/diff",
        "--target",
        "native",
        "--release",
        "--",
        "--manifest",
        MANIFEST_PATH,
        "--one-file",
        fixture.input,
        "--expected-legacy-ast",
        expectedAst,
        "--max-failures",
        "1",
      ],
      { timeoutMs: fixture.timeout_ms },
    );
    assertSuccessful(`${fixture.input}: tools/diff`, diff, fixture);
    if (!/SUMMARY selected=1 compared=1 failures=0 truncated=false/.test(diff.stdout)) {
      throw new Error(`${fixture.input}: missing successful diff summary\n${diff.stdout}`);
    }
    return {
      input: fixture.input,
      timeout_ms: fixture.timeout_ms,
      max_peak_rss_kib: fixture.max_peak_rss_kib,
      expected_ast_bytes: fs.statSync(expectedAst).size,
      reference_wall_ms: reference.wallMs,
      reference_peak_rss_kib: reference.peakRssKib,
      diff_wall_ms: diff.wallMs,
      diff_peak_rss_kib: diff.peakRssKib,
      within_budget: true,
    };
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

async function main(argv) {
  const mode = parseMode(
    argv,
    ["write", "verify"],
    "usage: node scripts/supervise-online-legacy-diff.mjs <--write|--verify>",
  );
  if (process.platform !== "linux" || !fs.existsSync("/proc")) {
    throw new Error("online legacy supervision requires Linux /proc process-group metrics");
  }
  verifyInstalledTypeScript(ts.version);
  const onlineInputs = readOnlineInputs();
  const budgets = JSON.parse(fs.readFileSync(BUDGET_PATH, "utf8"));
  const byInput = new Map(budgets.fixtures.map((fixture) => [fixture.input, fixture]));
  if (JSON.stringify([...byInput.keys()]) !== JSON.stringify(onlineInputs)) {
    throw new Error(`${BUDGET_PATH}: pressure fixtures do not exactly match online inputs`);
  }
  if (mode === "verify") verifyStoredResults(onlineInputs);
  buildDiffTool();
  const fixtures = [];
  for (const input of onlineInputs) {
    const result = await compareFixture(byInput.get(input));
    fixtures.push(result);
    console.error(
      `online-legacy input=${input} ast_bytes=${result.expected_ast_bytes} ` +
        `diff_wall_ms=${result.diff_wall_ms} diff_peak_rss_kib=${result.diff_peak_rss_kib}`,
    );
  }
  const document = {
    schema_version: 1,
    typescript_version: TYPESCRIPT_VERSION,
    measured_on: new Date().toISOString().slice(0, 10),
    runner_class: budgets.runner_class,
    scope: "one streaming TypeScript legacy projection followed by one independently supervised tools/diff process group per input",
    fixtures,
  };
  if (mode === "write") {
    fs.writeFileSync(RESULT_PATH, `${JSON.stringify(document, null, 2)}\n`);
    console.log(`wrote ${RESULT_PATH}`);
  } else {
    console.log(`verified ${fixtures.length} online legacy AST projections`);
  }
}

main(process.argv.slice(2)).catch((error) => {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
});
