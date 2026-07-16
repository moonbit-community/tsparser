#!/usr/bin/env node

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

import {
  createReferenceSourceFile,
  diagnosticRecords,
  fullAstRecords,
  sourceFileProjection,
} from "./ts-reference.mjs";

const DEFAULT_MANIFEST = "docs/corpus-manifest.jsonl";

function parseNonNegativeInteger(name, value) {
  if (!/^\d+$/.test(value)) {
    throw new Error(`${name} requires a non-negative decimal integer`);
  }
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed)) {
    throw new Error(`${name} exceeds the safe integer range`);
  }
  return parsed;
}

function parseArguments(argv) {
  const options = {
    manifest: DEFAULT_MANIFEST,
    shardIndex: 0,
    shardCount: 1,
    filter: undefined,
    maxFiles: undefined,
    progressEvery: 100,
  };
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    const value = () => {
      if (index + 1 >= argv.length) {
        throw new Error(`missing value for ${argument}`);
      }
      return argv[++index];
    };
    if (argument === "--manifest") {
      options.manifest = value();
    } else if (argument === "--shard-index") {
      options.shardIndex = parseNonNegativeInteger(argument, value());
    } else if (argument === "--shard-count") {
      options.shardCount = parseNonNegativeInteger(argument, value());
    } else if (argument === "--filter") {
      options.filter = value();
    } else if (argument === "--max-files") {
      options.maxFiles = parseNonNegativeInteger(argument, value());
    } else if (argument === "--progress-every") {
      options.progressEvery = parseNonNegativeInteger(argument, value());
    } else {
      throw new Error(`unknown argument: ${argument}`);
    }
  }
  if (options.shardCount <= 0) {
    throw new Error("--shard-count must be positive");
  }
  if (options.shardIndex >= options.shardCount) {
    throw new Error("--shard-index must be smaller than --shard-count");
  }
  if (options.maxFiles !== undefined && options.maxFiles <= 0) {
    throw new Error("--max-files must be positive");
  }
  return options;
}

function readManifest(manifestPath) {
  const lines = fs.readFileSync(manifestPath, "utf8").split("\n");
  const entries = [];
  const seen = new Map();
  for (let index = 0; index < lines.length; index++) {
    if (lines[index].trim() === "") {
      continue;
    }
    const entry = JSON.parse(lines[index]);
    if (typeof entry.input !== "string" || entry.input === "") {
      throw new Error(`${manifestPath}:${index + 1}: invalid input`);
    }
    const normalized = entry.input.split(path.sep).join("/");
    if (normalized !== entry.input || path.isAbsolute(normalized) || normalized.includes("../")) {
      throw new Error(`${manifestPath}:${index + 1}: non-normalized input ${entry.input}`);
    }
    if (seen.has(normalized)) {
      throw new Error(
        `${manifestPath}:${index + 1}: duplicate input also present at line ${seen.get(normalized)}`,
      );
    }
    seen.set(normalized, index + 1);
    entries.push(entry);
  }
  const sorted = entries.map((entry) => entry.input).toSorted();
  assert.deepEqual(
    entries.map((entry) => entry.input),
    sorted,
    "corpus manifest must be sorted by normalized input path",
  );
  return entries;
}

function hashBuffer(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

function hashRecord(hash, record) {
  const line = JSON.stringify(record);
  if (line === undefined) {
    throw new Error("reference record is not JSON serializable");
  }
  hash.update(line);
  hash.update("\n");
  return Buffer.byteLength(line) + 1;
}

function validateEntry(entry) {
  const bytes = fs.readFileSync(entry.input);
  assert.equal(bytes.length, entry.input_bytes, `${entry.input}: byte length`);
  assert.equal(hashBuffer(bytes), entry.input_sha256, `${entry.input}: sha256`);
  const sourceText = bytes.toString("utf8");
  const sourceFile = createReferenceSourceFile(entry.input, sourceText);

  const astHash = crypto.createHash("sha256");
  let astBytes = 0;
  let astRecords = 0;
  let nodes = 0;
  let nodeArrays = 0;
  let nodeLists = 0;
  for (const record of fullAstRecords(sourceFile)) {
    if (astRecords === 0) {
      assert.equal(record.record, "header", `${entry.input}: first AST record`);
      assert.equal(record.file_name, entry.input, `${entry.input}: reference file name`);
      assert.equal(record.text_utf16_length, sourceText.length, `${entry.input}: UTF-16 length`);
    }
    if (record.record === "node") {
      nodes++;
    } else if (record.record === "node_array") {
      nodeArrays++;
    } else if (record.record === "node_list") {
      nodeLists++;
    }
    astBytes += hashRecord(astHash, record);
    astRecords++;
  }
  assert.ok(astRecords >= 2, `${entry.input}: AST stream must contain header and SourceFile`);
  assert.ok(nodes >= 2, `${entry.input}: AST stream must contain SourceFile and EOF`);

  const diagnosticHash = crypto.createHash("sha256");
  let diagnosticBytes = 0;
  let diagnosticCount = 0;
  let parseDiagnosticCount = 0;
  let jsdocDiagnosticCount = 0;
  for (const record of diagnosticRecords(sourceFile)) {
    if (record.record === "parse_diagnostic") {
      assert.equal(record.index, parseDiagnosticCount, `${entry.input}: parse diagnostic order`);
      parseDiagnosticCount++;
    } else if (record.record === "jsdoc_diagnostic") {
      assert.equal(record.index, jsdocDiagnosticCount, `${entry.input}: JSDoc diagnostic order`);
      jsdocDiagnosticCount++;
    } else {
      throw new Error(`${entry.input}: unexpected diagnostic record ${record.record}`);
    }
    diagnosticBytes += hashRecord(diagnosticHash, record);
    diagnosticCount++;
  }
  assert.equal(parseDiagnosticCount, sourceFile.parseDiagnostics.length);
  assert.equal(jsdocDiagnosticCount, (sourceFile.jsDocDiagnostics ?? []).length);

  const sourceFileRecord = sourceFileProjection(sourceFile);
  assert.equal(sourceFileRecord.file_name, entry.input);
  assert.equal(sourceFileRecord.text_utf16_length, sourceText.length);
  assert.equal(sourceFileRecord.parse_diagnostic_count, parseDiagnosticCount);
  assert.equal(sourceFileRecord.jsdoc_diagnostic_count, jsdocDiagnosticCount);
  const sourceFileBytes = Buffer.byteLength(JSON.stringify(sourceFileRecord)) + 1;

  return {
    astRecords,
    astBytes,
    astSha256: astHash.digest("hex"),
    nodes,
    nodeArrays,
    nodeLists,
    diagnosticCount,
    diagnosticBytes,
    diagnosticSha256: diagnosticHash.digest("hex"),
    sourceFileBytes,
  };
}

function main(argv) {
  const options = parseArguments(argv);
  const entries = readManifest(options.manifest);
  let selected = entries.filter((entry) =>
    options.filter === undefined || entry.input.includes(options.filter)
  );
  selected = selected.filter((_entry, index) => index % options.shardCount === options.shardIndex);
  if (options.maxFiles !== undefined) {
    selected = selected.slice(0, options.maxFiles);
  }
  if (selected.length === 0) {
    throw new Error("reference corpus selection is empty");
  }

  const totals = {
    files: 0,
    ast_records: 0,
    ast_bytes: 0,
    nodes: 0,
    node_arrays: 0,
    node_lists: 0,
    diagnostics: 0,
    diagnostic_bytes: 0,
    source_file_bytes: 0,
    peak_rss_kib: 0,
  };
  const started = process.hrtime.bigint();
  for (const entry of selected) {
    let result;
    try {
      result = validateEntry(entry);
    } catch (error) {
      throw new Error(`${entry.input}: reference validation failed`, { cause: error });
    }
    totals.files++;
    totals.ast_records += result.astRecords;
    totals.ast_bytes += result.astBytes;
    totals.nodes += result.nodes;
    totals.node_arrays += result.nodeArrays;
    totals.node_lists += result.nodeLists;
    totals.diagnostics += result.diagnosticCount;
    totals.diagnostic_bytes += result.diagnosticBytes;
    totals.source_file_bytes += result.sourceFileBytes;
    totals.peak_rss_kib = Math.max(
      totals.peak_rss_kib,
      Math.ceil(process.memoryUsage().rss / 1024),
    );
    if (global.gc && totals.files % 25 === 0) {
      global.gc();
    }
    if (options.progressEvery > 0 && totals.files % options.progressEvery === 0) {
      const elapsedMs = Number(process.hrtime.bigint() - started) / 1e6;
      console.error(
        `reference-progress files=${totals.files}/${selected.length} elapsed_ms=${elapsedMs.toFixed(0)} rss_kib=${Math.ceil(process.memoryUsage().rss / 1024)} input=${entry.input}`,
      );
    }
  }
  totals.elapsed_ms = Math.round(Number(process.hrtime.bigint() - started) / 1e6);
  totals.manifest_files = entries.length;
  totals.shard_index = options.shardIndex;
  totals.shard_count = options.shardCount;
  console.log(JSON.stringify(totals));
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
