import assert from "node:assert/strict";
import test from "node:test";

import {
  CHECKS,
  GROUPS,
  parseArguments,
  resolveSelectors,
  runChecks,
} from "./run-audits.mjs";

test("audit defaults to the baseline group", () => {
  assert.deepEqual(parseArguments([]), {
    list: false,
    selectors: ["baseline"],
  });
  assert.deepEqual(
    resolveSelectors(["baseline"]).map((check) => check.id),
    GROUPS.baseline,
  );
});

test("audit expands groups in registry order and removes duplicates", () => {
  const ids = resolveSelectors(["repo", "parser", "repository-policy"])
    .map((check) => check.id);
  assert.deepEqual(ids, [...GROUPS.parser, ...GROUPS.repo]);
});

test("audit rejects unknown selectors and command options before running", () => {
  assert.throws(() => resolveSelectors(["missing"]), /unknown audit selector/);
  assert.throws(() => parseArguments(["--write"]), /audit is read-only/);
  assert.throws(() => parseArguments(["parser", "--verify"]), /audit is read-only/);
});

test("audit registry contains no interface or formatter commands", () => {
  const serialized = JSON.stringify(CHECKS);
  assert.doesNotMatch(serialized, /\bmoon (?:info|fmt)\b/);
  assert.equal(CHECKS.some((check) => check.id === "moon-info"), false);
});

test("audit registry contains no license check", () => {
  assert.equal(CHECKS.some((check) => check.id === "licenses"), false);
});

test("memory-sensitive corpus checks enable exposed garbage collection", () => {
  for (const id of ["legacy-corpus", "reference-corpus", "reference-corpus-smoke"]) {
    const check = CHECKS.find((candidate) => candidate.id === id);
    assert.deepEqual(check.nodeArgs, ["--expose-gc"]);
  }
});

test("audit stops after the first failed check", async () => {
  const visited = [];
  const checks = resolveSelectors(["syntax-kind", "tables", "factories"]);
  await assert.rejects(
    runChecks(checks, async (check) => {
      visited.push(check.id);
      if (check.id === "tables") throw new Error("expected failure");
    }),
    /expected failure/,
  );
  assert.deepEqual(visited, ["syntax-kind", "tables"]);
});
