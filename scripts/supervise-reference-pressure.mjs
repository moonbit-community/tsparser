#!/usr/bin/env node

import childProcess from "node:child_process";
import fs from "node:fs";

import ts from "typescript";

import { parseMode } from "./audit-support.mjs";
import {
  TYPESCRIPT_VERSION,
  verifyInstalledTypeScript,
} from "./upstream-config.mjs";

const BUDGET_PATH = "docs/stress-budgets.json";
const RESULT_PATH = "docs/reference-pressure-results.json";
const METRIC_PREFIX = "__TSPARSER_REFERENCE_METRIC__";

function measure(fixture) {
  const format = `${METRIC_PREFIX} wall_s=%e peak_rss_kib=%M exit=%x`;
  const result = childProcess.spawnSync(
    "/usr/bin/time",
    [
      "-f",
      format,
      "timeout",
      `${(fixture.timeout_ms / 1000).toFixed(3)}s`,
      process.execPath,
      "scripts/ts-reference.mjs",
      "full-ast",
      fixture.input,
    ],
    {
      cwd: process.cwd(),
      encoding: "utf8",
      maxBuffer: 4 * 1024 * 1024,
      stdio: ["ignore", "ignore", "pipe"],
      timeout: fixture.timeout_ms + 5_000,
    },
  );
  if (result.error) {
    throw new Error(`${fixture.input}: supervisor failed`, { cause: result.error });
  }
  const metricLine = result.stderr
    .split("\n")
    .find((line) => line.startsWith(METRIC_PREFIX));
  if (!metricLine) {
    throw new Error(`${fixture.input}: missing /usr/bin/time metrics\n${result.stderr}`);
  }
  const match = metricLine.match(
    /wall_s=([0-9.]+) peak_rss_kib=(\d+) exit=(\d+)/,
  );
  if (!match) {
    throw new Error(`${fixture.input}: malformed metrics: ${metricLine}`);
  }
  const wallMs = Math.round(Number(match[1]) * 1000);
  const peakRssKib = Number(match[2]);
  const exitCode = Number(match[3]);
  if (result.status !== 0 || exitCode !== 0) {
    throw new Error(
      `${fixture.input}: reference exited ${result.status}/${exitCode}\n${result.stderr}`,
    );
  }
  if (wallMs > fixture.timeout_ms) {
    throw new Error(
      `${fixture.input}: ${wallMs}ms exceeds ${fixture.timeout_ms}ms budget`,
    );
  }
  if (peakRssKib > fixture.max_peak_rss_kib) {
    throw new Error(
      `${fixture.input}: ${peakRssKib} KiB exceeds ${fixture.max_peak_rss_kib} KiB budget`,
    );
  }
  return {
    input: fixture.input,
    timeout_ms: fixture.timeout_ms,
    max_peak_rss_kib: fixture.max_peak_rss_kib,
    measured_wall_ms: wallMs,
    measured_peak_rss_kib: peakRssKib,
    exit_code: exitCode,
    within_budget: true,
  };
}

function verifyStoredResults(budgets) {
  if (!fs.existsSync(RESULT_PATH)) {
    throw new Error(`missing pressure result record: ${RESULT_PATH}`);
  }
  const stored = JSON.parse(fs.readFileSync(RESULT_PATH, "utf8"));
  if (stored.typescript_version !== TYPESCRIPT_VERSION) {
    throw new Error(`${RESULT_PATH}: TypeScript version changed`);
  }
  const expectedInputs = budgets.fixtures.map((fixture) => fixture.input);
  const actualInputs = stored.fixtures.map((fixture) => fixture.input);
  if (JSON.stringify(actualInputs) !== JSON.stringify(expectedInputs)) {
    throw new Error(`${RESULT_PATH}: fixture list differs from ${BUDGET_PATH}`);
  }
  if (!stored.fixtures.every((fixture) => fixture.within_budget === true)) {
    throw new Error(`${RESULT_PATH}: a recorded fixture exceeded its budget`);
  }
}

function main(argv) {
  const mode = parseMode(
    argv,
    ["write", "verify"],
    "usage: node scripts/supervise-reference-pressure.mjs <--write|--verify>",
  );
  verifyInstalledTypeScript(ts.version);
  const budgets = JSON.parse(fs.readFileSync(BUDGET_PATH, "utf8"));
  if (mode === "verify") {
    verifyStoredResults(budgets);
  }
  const fixtures = [];
  for (const fixture of budgets.fixtures) {
    const result = measure(fixture);
    fixtures.push(result);
    console.error(
      `reference-pressure input=${fixture.input} wall_ms=${result.measured_wall_ms} peak_rss_kib=${result.measured_peak_rss_kib}`,
    );
  }
  const document = {
    schema_version: 1,
    typescript_version: TYPESCRIPT_VERSION,
    measured_on: new Date().toISOString().slice(0, 10),
    runner_class: budgets.runner_class,
    scope: "one TypeScript full-AST NDJSON reference process with stdout consumed by the operating system",
    command: "/usr/bin/time -f ... timeout <budget> node scripts/ts-reference.mjs full-ast <input>",
    fixtures,
  };
  if (mode === "write") {
    fs.writeFileSync(RESULT_PATH, `${JSON.stringify(document, null, 2)}\n`);
    console.log(`wrote ${RESULT_PATH}`);
  } else {
    console.log(
      `verified ${fixtures.length} full-AST reference pressure fixtures within executable budgets`,
    );
  }
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  if (error instanceof Error && error.cause) {
    console.error(error.cause);
  }
  process.exitCode = 1;
}
