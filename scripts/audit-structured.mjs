#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import ts from "typescript";

import { assert, parseMode } from "./audit-support.mjs";
import { verifyInstalledTypeScript } from "./upstream-config.mjs";

const DIRECTORY = "fixtures/structured";
const MANIFEST = "docs/corpus-manifest.jsonl";
const FILES = ["basic.js", "basic.jsx", "basic.json", "basic.tsx"];

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: process.cwd(),
    encoding: "utf8",
    maxBuffer: 4 * 1024 * 1024,
  });
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed\n${result.stdout}\n${result.stderr}`);
  }
  return result.stdout;
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-structured.mjs --verify",
  );
  verifyInstalledTypeScript(ts.version);
  assert(
    JSON.stringify(fs.readdirSync(DIRECTORY).sort()) === JSON.stringify([...FILES].sort()),
    "structured fixture inventory changed",
  );
  run("moon", ["build", "tools/structure", "--target", "native", "--release"]);
  run("moon", ["build", "tools/diff", "--target", "native", "--release"]);
  const structure = "_build/native/release/build/tools/structure/structure.exe";
  const diff = "_build/native/release/build/tools/diff/diff.exe";
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "tsparser-structured-"));
  try {
    for (const file of FILES) {
      const input = `${DIRECTORY}/${file}`;
      const expected = path.join(temporary, `${file}.expected.ndjson`);
      const actual = path.join(temporary, `${file}.actual.ndjson`);
      run(process.execPath, ["scripts/structured-fixture-reference.mjs", input, expected]);
      run(structure, [input, actual]);
      const output = run(diff, [
        "--manifest",
        MANIFEST,
        "--expected-stream",
        expected,
        "--actual-stream",
        actual,
        "--one-file",
        input,
        "--max-failures",
        "20",
      ]);
      assert(
        output.includes("SUMMARY compared_streams=true failures=0"),
        `${file}: missing zero-difference summary`,
      );
    }
  } finally {
    fs.rmSync(temporary, { recursive: true, force: true });
  }
  console.log("verified complete parser structure for fixed JS, JSX, JSON, and TSX/JSDoc fixtures");
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
