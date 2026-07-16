#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import { parseMode } from "./audit-support.mjs";
import { superviseProcess } from "./process-supervisor.mjs";

const BUDGET_PATH = "docs/stress-budgets.json";
const MANIFEST_PATH = "docs/corpus-manifest.jsonl";
const RESULT_PATH = "docs/stress-results.json";
const EXECUTABLE = "_build/native/release/build/tools/stress/stress.exe";
const CAPTURE_LIMIT = 256 * 1024;

function median(values) {
  const sorted = [...values].sort((left, right) => left - right);
  return sorted[Math.floor(sorted.length / 2)];
}

async function runSupervised(args, budget, options = {}) {
  const result = await superviseProcess({
    command: EXECUTABLE,
    args,
    timeoutMs: budget.timeout_ms,
    captureLimit: CAPTURE_LIMIT,
    sampleIntervalMs: options.sampleIntervalMs ?? 5,
    onStdoutLine(line, sample) {
      const match = line.match(/^PROGRESS iteration=\d+ completed=(\d+) /);
      if (match) sample(Number(match[1]));
    },
  });
  if (result.timedOut) {
    throw new Error(`${args.join(" ")}: exceeded ${budget.timeout_ms}ms`);
  }
  if (result.code !== 0) {
    throw new Error(
      `${args.join(" ")}: exited ${result.code ?? result.signal}\n` +
        `${result.stdout}\n${result.stderr}`,
    );
  }
  if (!result.stdout.includes("STRESS_OK")) {
    throw new Error(`${args.join(" ")}: missing STRESS_OK\n${result.stdout}`);
  }
  if (result.peakRssKib > budget.max_peak_rss_kib) {
    throw new Error(
      `${args.join(" ")}: ${result.peakRssKib} KiB exceeds ${budget.max_peak_rss_kib} KiB`,
    );
  }
  return result;
}

function generatedSource(kind, units) {
  switch (kind) {
    case "statements": {
      let result = "";
      for (let index = 0; index < units; index++) {
        result += `const value${index} = ${index};\n`;
      }
      return result;
    }
    case "deep_parentheses":
      return `const value = ${"(".repeat(units)}0${")".repeat(units)};\n`;
    case "deep_type":
      return `type Value = ${"(".repeat(units)}string${")".repeat(units)};\n`;
    case "deep_jsx":
      return `const view = ${"<x>".repeat(units)}text${"</x>".repeat(units)};\n`;
    case "long_binary":
      return `const value = ${Array(units).fill("item").join(" + ")};\n`;
    case "long_list":
      return `const values = [${Array.from({ length: units }, (_, index) => index).join(",")}];\n`;
    case "regexp_v": {
      let result = "";
      for (let index = 0; index < units; index++) {
        result += `const regexp${index} = /[\\q{ab}&&[^c]]/v;\n`;
      }
      return result;
    }
    case "jsx_siblings":
      return `const view = <>${Array.from({ length: units }, (_, index) => `<x key={${index}} />`).join("")}</>;\n`;
    case "jsdoc": {
      let result = "";
      for (let index = 0; index < units; index++) {
        result += `/** @param {number} value${index} item */\nfunction f${index}(value${index}) {}\n`;
      }
      return result;
    }
    default:
      throw new Error(`unknown stress generator: ${kind}`);
  }
}

function buildStressTool() {
  const result = spawnSync(
    "moon",
    ["build", "tools/stress", "--target", "native", "--release"],
    { cwd: process.cwd(), encoding: "utf8" },
  );
  if (result.status !== 0) {
    throw new Error(`could not build tools/stress\n${result.stdout}\n${result.stderr}`);
  }
  if (!fs.existsSync(EXECUTABLE)) throw new Error(`missing built executable: ${EXECUTABLE}`);
}

function fixturePath(directory, id, extension, generator, units) {
  const filePath = path.join(directory, `${id}${extension}`);
  fs.writeFileSync(filePath, generatedSource(generator, units));
  return filePath;
}

async function repeatedMeasurements(filePath, definition, protocol) {
  const args = [
    "--input",
    filePath,
    "--parents",
    "false",
    "--iterations",
    String(definition.iterations_per_process),
  ];
  if (definition.traverse) args.push("--traverse");
  for (let index = 0; index < protocol.warmup_runs; index++) {
    await runSupervised(args, definition, { sampleIntervalMs: protocol.sample_interval_ms });
  }
  const runs = [];
  for (let index = 0; index < protocol.repeat_runs; index++) {
    runs.push(
      await runSupervised(args, definition, {
        sampleIntervalMs: protocol.sample_interval_ms,
      }),
    );
  }
  return {
    wall_ms: runs.map((run) => Number(run.wallMs.toFixed(3))),
    peak_rss_kib: runs.map((run) => run.peakRssKib),
    median_wall_ms: Number(median(runs.map((run) => run.wallMs)).toFixed(3)),
    max_peak_rss_kib: Math.max(...runs.map((run) => run.peakRssKib)),
  };
}

async function runBenchmarks(directory, budgets, smoke) {
  const definitions = smoke
    ? budgets.benchmarks.filter((item) => ["small", "deep_parentheses", "regexp_v"].includes(item.id))
    : budgets.benchmarks;
  const results = [];
  for (const definition of definitions) {
    const filePath = fixturePath(
      directory,
      definition.id,
      definition.extension,
      definition.generator,
      definition.units,
    );
    const measurement = await repeatedMeasurements(
      filePath,
      definition,
      budgets.parser_protocol,
    );
    if (measurement.median_wall_ms > definition.max_median_wall_ms) {
      throw new Error(
        `${definition.id}: median ${measurement.median_wall_ms}ms exceeds ${definition.max_median_wall_ms}ms`,
      );
    }
    results.push({
      id: definition.id,
      units: definition.units,
      ...measurement,
      within_budget: true,
    });
    console.error(
      `stress-benchmark id=${definition.id} median_wall_ms=${measurement.median_wall_ms} ` +
        `peak_rss_kib=${measurement.max_peak_rss_kib}`,
    );
  }
  return results;
}

async function runComplexity(directory, budgets, smoke) {
  const definitions = smoke ? budgets.complexity.slice(0, 1) : budgets.complexity;
  const results = [];
  for (const definition of definitions) {
    const medians = [];
    const peaks = [];
    for (const multiplier of [1, 2, 4]) {
      const units = definition.n * multiplier;
      const filePath = fixturePath(
        directory,
        `${definition.id}-${multiplier}n`,
        definition.extension,
        definition.generator,
        units,
      );
      const measurement = await repeatedMeasurements(
        filePath,
        definition,
        budgets.parser_protocol,
      );
      medians.push(measurement.median_wall_ms);
      peaks.push(measurement.max_peak_rss_kib);
    }
    const t2OverT1 = medians[1] / medians[0];
    const t4OverT2 = medians[2] / medians[1];
    if (t2OverT1 > definition.max_t2_over_t1) {
      throw new Error(`${definition.id}: 2N/N ratio ${t2OverT1} exceeds ${definition.max_t2_over_t1}`);
    }
    if (t4OverT2 > definition.max_t4_over_t2) {
      throw new Error(`${definition.id}: 4N/2N ratio ${t4OverT2} exceeds ${definition.max_t4_over_t2}`);
    }
    const result = {
      id: definition.id,
      n: definition.n,
      median_wall_ms: medians,
      max_peak_rss_kib: peaks,
      t2_over_t1: Number(t2OverT1.toFixed(3)),
      t4_over_t2: Number(t4OverT2.toFixed(3)),
      within_budget: true,
    };
    results.push(result);
    console.error(
      `stress-complexity id=${definition.id} medians=${medians.join(",")} ` +
        `ratios=${result.t2_over_t1},${result.t4_over_t2}`,
    );
  }
  return results;
}

function positiveSlopeKibPer1000(samples) {
  if (samples.length < 2) return 0;
  const meanX = samples.reduce((sum, sample) => sum + sample.completed, 0) / samples.length;
  const meanY = samples.reduce((sum, sample) => sum + sample.rss_kib, 0) / samples.length;
  let numerator = 0;
  let denominator = 0;
  for (const sample of samples) {
    numerator += (sample.completed - meanX) * (sample.rss_kib - meanY);
    denominator += (sample.completed - meanX) ** 2;
  }
  return denominator === 0 ? 0 : Math.max(0, (numerator / denominator) * 1000);
}

async function runCorpusMemory(budgets, smoke) {
  if (smoke) return [];
  const definition = budgets.corpus_memory;
  const results = [];
  for (const parents of [false, true]) {
    const run = await runSupervised(
      [
        "--manifest",
        MANIFEST_PATH,
        "--parents",
        String(parents),
        "--iterations",
        "1",
        "--progress-every",
        String(definition.progress_every),
      ],
      definition,
      { sampleIntervalMs: budgets.parser_protocol.sample_interval_ms },
    );
    const postWarmup = run.progressSamples.filter(
      (sample) => sample.completed >= definition.warmup_files,
    );
    if (postWarmup.length < 2) throw new Error(`parent=${parents}: insufficient RSS milestones`);
    const warmupRssKib = postWarmup[0].rss_kib;
    const maxPostWarmupRssKib = Math.max(...postWarmup.map((sample) => sample.rss_kib));
    const growthKib = Math.max(0, maxPostWarmupRssKib - warmupRssKib);
    const slopeKibPer1000Files = positiveSlopeKibPer1000(postWarmup);
    if (growthKib > definition.max_post_warmup_growth_kib) {
      throw new Error(
        `parent=${parents}: growth ${growthKib} KiB exceeds ${definition.max_post_warmup_growth_kib} KiB`,
      );
    }
    if (slopeKibPer1000Files > definition.max_slope_kib_per_1000_files) {
      throw new Error(
        `parent=${parents}: slope ${slopeKibPer1000Files} exceeds ${definition.max_slope_kib_per_1000_files}`,
      );
    }
    const result = {
      parents,
      wall_ms: Number(run.wallMs.toFixed(3)),
      peak_rss_kib: run.peakRssKib,
      warmup_rss_kib: warmupRssKib,
      post_warmup_growth_kib: growthKib,
      slope_kib_per_1000_files: Number(slopeKibPer1000Files.toFixed(3)),
      progress_samples: postWarmup.length,
      within_budget: true,
    };
    results.push(result);
    console.error(
      `stress-corpus parents=${parents} wall_ms=${result.wall_ms} peak_rss_kib=${run.peakRssKib} ` +
        `growth_kib=${growthKib} slope=${result.slope_kib_per_1000_files}`,
    );
  }
  return results;
}

function verifyStoredResults(budgets) {
  if (!fs.existsSync(RESULT_PATH)) throw new Error(`missing ${RESULT_PATH}`);
  const stored = JSON.parse(fs.readFileSync(RESULT_PATH, "utf8"));
  const benchmarkIds = stored.benchmarks.map((item) => item.id);
  const complexityIds = stored.complexity.map((item) => item.id);
  if (JSON.stringify(benchmarkIds) !== JSON.stringify(budgets.benchmarks.map((item) => item.id))) {
    throw new Error(`${RESULT_PATH}: benchmark inventory changed`);
  }
  if (JSON.stringify(complexityIds) !== JSON.stringify(budgets.complexity.map((item) => item.id))) {
    throw new Error(`${RESULT_PATH}: complexity inventory changed`);
  }
  const all = [...stored.benchmarks, ...stored.complexity, ...stored.corpus_memory];
  if (!all.every((item) => item.within_budget === true)) {
    throw new Error(`${RESULT_PATH}: a recorded stress result failed`);
  }
}

async function main(argv) {
  const mode = parseMode(
    argv,
    ["write", "verify", "smoke"],
    "usage: node scripts/run-parser-stress.mjs <--write|--verify|--smoke>",
  );
  if (process.platform !== "linux" || !fs.existsSync("/proc")) {
    throw new Error("parser stress supervision requires Linux /proc");
  }
  const budgets = JSON.parse(fs.readFileSync(BUDGET_PATH, "utf8"));
  if (mode === "verify") verifyStoredResults(budgets);
  buildStressTool();
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "tsparser-stress-"));
  try {
    const smoke = mode === "smoke";
    const benchmarks = await runBenchmarks(directory, budgets, smoke);
    const complexity = await runComplexity(directory, budgets, smoke);
    const corpusMemory = await runCorpusMemory(budgets, smoke);
    const result = {
      schema_version: 1,
      measured_on: new Date().toISOString().slice(0, 10),
      runner_class: budgets.runner_class,
      protocol: budgets.parser_protocol,
      benchmarks,
      complexity,
      corpus_memory: corpusMemory,
    };
    if (mode === "write") {
      fs.writeFileSync(RESULT_PATH, `${JSON.stringify(result, null, 2)}\n`);
      console.log(`wrote ${RESULT_PATH}`);
    } else {
      console.log(
        `verified parser stress benchmarks=${benchmarks.length} complexity=${complexity.length} corpus_modes=${corpusMemory.length}`,
      );
    }
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

main(process.argv.slice(2)).catch((error) => {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
});
