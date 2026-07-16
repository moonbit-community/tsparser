#!/usr/bin/env node

import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIRECTORY = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(SCRIPT_DIRECTORY, "..");

export const CHECKS = [
  { id: "upstream", script: "generate-upstream-audit.mjs", args: ["--verify"] },
  {
    id: "syntax-kind",
    script: "audit-moonbit-syntax-kind.mjs",
    args: ["--verify"],
  },
  { id: "tables", script: "audit-tables.mjs", args: ["--verify"] },
  { id: "factories", script: "audit-factories.mjs", args: ["--verify"] },
  { id: "children", script: "audit-children.mjs", args: ["--verify"] },
  { id: "diagnostics", script: "audit-diagnostics.mjs", args: ["--verify"] },
  { id: "scanner", script: "audit-scanner.mjs", args: ["--verify"] },
  { id: "parser-core", script: "audit-parser-core.mjs", args: ["--verify"] },
  { id: "types", script: "audit-parser-types.mjs", args: ["--verify"] },
  { id: "expressions", script: "audit-parser-expressions.mjs", args: ["--verify"] },
  { id: "statements", script: "audit-parser-statements.mjs", args: ["--verify"] },
  { id: "modules", script: "audit-parser-modules.mjs", args: ["--verify"] },
  { id: "jsx", script: "audit-parser-jsx.mjs", args: ["--verify"] },
  { id: "jsdoc", script: "audit-parser-jsdoc.mjs", args: ["--verify"] },
  { id: "source", script: "audit-parser-source.mjs", args: ["--verify"] },
  { id: "public-api", script: "audit-public-api.mjs", args: ["--verify"] },
  { id: "test-coverage", script: "audit-test-coverage.mjs", args: ["--verify"] },
  { id: "structured", script: "audit-structured.mjs", args: ["--verify"] },
  { id: "corpus-manifest", script: "generate-corpus-audit.mjs", args: ["--verify"] },
  {
    id: "legacy-corpus",
    script: "verify-legacy-corpus.mjs",
    nodeArgs: ["--expose-gc"],
    args: [],
  },
  {
    id: "structured-diagnostics",
    script: "generate-structured-diagnostics.mjs",
    args: ["--verify"],
  },
  {
    id: "reference-corpus",
    script: "validate-reference-corpus.mjs",
    nodeArgs: ["--expose-gc"],
    args: [],
  },
  {
    id: "reference-corpus-smoke",
    script: "validate-reference-corpus.mjs",
    nodeArgs: ["--expose-gc"],
    args: ["--max-files", "10", "--progress-every", "0"],
  },
  {
    id: "reference-pressure",
    script: "supervise-reference-pressure.mjs",
    args: ["--verify"],
  },
  {
    id: "repository-policy",
    script: "audit-repository-policy.mjs",
    args: ["--verify"],
  },
  {
    id: "online-legacy",
    script: "supervise-online-legacy-diff.mjs",
    args: ["--verify"],
  },
  { id: "stress", script: "run-parser-stress.mjs", args: ["--verify"] },
  { id: "stress-smoke", script: "run-parser-stress.mjs", args: ["--smoke"] },
  { id: "coverage", script: "generate-coverage.mjs", args: ["--verify"] },
];

const BASELINE = [
  "upstream",
  "syntax-kind",
  "tables",
  "factories",
  "children",
  "diagnostics",
  "scanner",
  "parser-core",
  "types",
  "expressions",
  "statements",
  "modules",
  "jsx",
  "jsdoc",
  "source",
  "public-api",
  "test-coverage",
  "structured",
  "corpus-manifest",
  "legacy-corpus",
  "structured-diagnostics",
  "reference-corpus",
  "reference-pressure",
  "repository-policy",
];

export const GROUPS = {
  baseline: BASELINE,
  foundations: [
    "upstream",
    "syntax-kind",
    "tables",
    "factories",
    "children",
    "diagnostics",
  ],
  parser: [
    "parser-core",
    "types",
    "expressions",
    "statements",
    "modules",
    "jsx",
    "jsdoc",
    "source",
    "public-api",
  ],
  validation: [
    "test-coverage",
    "structured",
    "corpus-manifest",
    "legacy-corpus",
    "structured-diagnostics",
    "reference-corpus",
    "reference-pressure",
  ],
  repo: ["repository-policy"],
};

const CHECK_BY_ID = new Map(CHECKS.map((check) => [check.id, check]));

export function parseArguments(argv) {
  if (argv.length === 0) return { list: false, selectors: ["baseline"] };
  if (argv.length === 1 && argv[0] === "--list") {
    return { list: true, selectors: [] };
  }
  const option = argv.find((argument) => argument.startsWith("-"));
  if (option) {
    throw new Error(
      `${option} is not supported; audit is read-only and accepts only selectors or --list`,
    );
  }
  return { list: false, selectors: argv };
}

export function resolveSelectors(selectors) {
  const selected = new Set();
  for (const selector of selectors) {
    if (Object.hasOwn(GROUPS, selector)) {
      for (const id of GROUPS[selector]) selected.add(id);
    } else if (CHECK_BY_ID.has(selector)) {
      selected.add(selector);
    } else {
      throw new Error(`unknown audit selector: ${selector}`);
    }
  }
  return CHECKS.filter((check) => selected.has(check.id));
}

export function formatList() {
  const groups = Object.entries(GROUPS)
    .map(([name, ids]) => `  ${name}: ${ids.join(", ")}`)
    .join("\n");
  const checks = CHECKS.map((check) => `  ${check.id}`).join("\n");
  return `Groups:\n${groups}\n\nChecks:\n${checks}`;
}

export async function runCheck(check) {
  const args = [
    ...(check.nodeArgs ?? []),
    path.join(SCRIPT_DIRECTORY, check.script),
    ...check.args,
  ];
  await new Promise((resolve, reject) => {
    const child = spawn(process.execPath, args, {
      cwd: ROOT,
      stdio: "inherit",
    });
    child.once("error", reject);
    child.once("close", (code, signal) => {
      if (code === 0) {
        resolve();
      } else {
        reject(
          new Error(
            `${check.id} failed with ${code === null ? `signal ${signal}` : `exit code ${code}`}`,
          ),
        );
      }
    });
  });
}

export async function runChecks(checks, execute = runCheck) {
  for (const check of checks) {
    console.log(`\n[audit] ${check.id}`);
    await execute(check);
  }
}

async function main(argv) {
  const options = parseArguments(argv);
  if (options.list) {
    console.log(formatList());
    return;
  }
  const checks = resolveSelectors(options.selectors);
  await runChecks(checks);
}

const currentFile = fileURLToPath(import.meta.url);
if (process.argv[1] && path.resolve(process.argv[1]) === currentFile) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
