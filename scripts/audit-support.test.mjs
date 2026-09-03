import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import test from "node:test";

import {
  parseMode,
  parseTsvText,
  renderTsv,
  splitList,
} from "./audit-support.mjs";
import {
  extractStringIntegerPairs,
  extractStringPairs,
  relativeDiagnostics,
  testBlock,
} from "./parser-audit-support.mjs";
import { superviseProcess } from "./process-supervisor.mjs";
import { verifyInstalledTypeScript } from "./upstream-config.mjs";

const spawnProbe = spawnSync(process.execPath, ["-e", ""], {
  encoding: "utf8",
});
const canSpawnChildProcesses = spawnProbe.error === undefined;

test("TSV helpers enforce row widths and round-trip rows", () => {
  const parsed = parseTsvText("name\tvalue\nfirst\t1\nsecond\t2\n", "fixture.tsv");
  assert.deepEqual(parsed, {
    headers: ["name", "value"],
    rows: [
      { name: "first", value: "1" },
      { name: "second", value: "2" },
    ],
  });
  assert.equal(renderTsv(parsed.headers, parsed.rows), "name\tvalue\nfirst\t1\nsecond\t2\n");
  assert.throws(
    () => parseTsvText("name\tvalue\nbroken\n", "fixture.tsv"),
    /fixture\.tsv:2 row width/,
  );
});

test("audit argument and list helpers normalize common inputs", () => {
  assert.equal(
    parseMode(["--verify"], ["verify"], "usage"),
    "verify",
  );
  assert.throws(() => parseMode(["--write"], ["verify"], "usage"), /usage/);
  assert.deepEqual(splitList("one; two ; ;three"), ["one", "two", "three"]);
});

test("parser audit helpers extract MoonBit fixtures and relative diagnostics", () => {
  const source = [
    "///|",
    'test "fixture" {',
    '  let pairs = [("a", "b"), ("c", "d")]',
    '  let integers = [("x", 1), ("y", 2)]',
    "}",
    "///|",
    'test "next" {}',
  ].join("\n");
  const block = testBlock(source, "fixture");
  assert.deepEqual(extractStringPairs(block), [["a", "b"], ["c", "d"]]);
  assert.deepEqual(extractStringIntegerPairs(block), [["x", 1], ["y", 2]]);
  assert.deepEqual(
    relativeDiagnostics(
      {
        parseDiagnostics: [
          { code: 100, start: 12, length: 3 },
          { code: 200, start: 18, length: 1 },
        ],
      },
      10,
    ),
    [
      { code: 100, start: 2, length: 3 },
      { code: 200, start: 8, length: 1 },
    ],
  );
});

test("pinned TypeScript validation accepts the installed runtime", () => {
  const packageJson = JSON.parse(
    fs.readFileSync("node_modules/typescript/package.json", "utf8"),
  );
  verifyInstalledTypeScript(packageJson.version);
  assert.throws(
    () => verifyInstalledTypeScript("0.0.0"),
    /expected TypeScript runtime/,
  );
});

test(
  "process supervisor captures output and progress samples",
  {
    skip:
      process.platform !== "linux" ||
      !fs.existsSync("/proc") ||
      !canSpawnChildProcesses,
  },
  async () => {
    const result = await superviseProcess({
      command: process.execPath,
      args: [
        "-e",
        'console.log("PROGRESS iteration=1 completed=7 ok"); setTimeout(() => console.log("done"), 80)',
      ],
      timeoutMs: 2_000,
      captureLimit: 4_096,
      sampleIntervalMs: 5,
      onStdoutLine(line, sample) {
        const match = line.match(/completed=(\d+)/);
        if (match) sample(Number(match[1]));
      },
    });
    assert.equal(result.code, 0);
    assert.match(result.stdout, /done/);
    assert.equal(result.timedOut, false);
    assert(result.peakRssKib > 0);
    assert.deepEqual(
      result.progressSamples.map((sample) => sample.completed),
      [7],
    );
  },
);
