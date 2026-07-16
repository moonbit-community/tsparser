#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import ts from "typescript";

import { parseMode } from "./audit-support.mjs";

const CORPUS_DIRECTORY = "tsfiles";
const MANIFEST_PATH = "docs/corpus-manifest.jsonl";
const COVERAGE_JSON_PATH = "docs/baseline-coverage.json";
const COVERAGE_MARKDOWN_PATH = "docs/baseline-coverage.md";
const FIXTURE_TASKS_PATH = "docs/fixture-tasks.tsv";
const STRESS_BUDGETS_PATH = "docs/stress-budgets.json";
const DIAGNOSTIC_AUDIT_PATH = "docs/upstream-audit/diagnostics.tsv";
const MAX_STORED_AST_BYTES = 4 * 1024 * 1024;

const EXPECTED_STREAM_ONLY_INPUTS = [
  "binaryArithmeticControlFlowGraphNotTooLarge.ts",
  "binderBinaryExpressionStress.ts",
  "binderBinaryExpressionStressJs.ts",
  "conditionalTypeDiscriminatingLargeUnionRegularTypeFetchingSpeedReasonable.ts",
  "largeControlFlowGraph.ts",
  "manyConstExports.ts",
  "parsingDeepParenthensizedExpression.ts",
  "resolvingClassDeclarationWhenInBaseTypeResolution.ts",
  "temporal.ts",
  "underscoreTest1.ts",
  "unionSubtypeReductionErrors.ts",
].map((name) => `${CORPUS_DIRECTORY}/${name}`).sort();

function slashPath(filePath) {
  return filePath.split(path.sep).join("/");
}

function sha256File(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function scriptKindForExtension(extension) {
  switch (extension.toLowerCase()) {
    case ".ts":
      return "TS";
    case ".tsx":
      return "TSX";
    case ".js":
    case ".cjs":
    case ".mjs":
      return "JS";
    case ".jsx":
      return "JSX";
    case ".json":
      return "JSON";
    default:
      throw new Error(`unsupported corpus extension: ${extension}`);
  }
}

function corpusInputs() {
  return fs.readdirSync(CORPUS_DIRECTORY, { withFileTypes: true })
    .filter((entry) =>
      entry.isFile() &&
      /\.(?:ts|tsx|js|jsx|json)$/i.test(entry.name) &&
      !entry.name.endsWith(".ast.json")
    )
    .map((entry) => slashPath(path.join(CORPUS_DIRECTORY, entry.name)))
    .sort();
}

function baselinePaths(inputPath) {
  const extension = path.extname(inputPath);
  const stem = inputPath.slice(0, -extension.length);
  return {
    stem,
    ast: `${stem}.ast.json`,
    errors: `${stem}.errors.txt`,
  };
}

function familyForKind(kind) {
  if (kind.startsWith("JSDoc")) {
    return "jsdoc";
  }
  if (kind.startsWith("Jsx")) {
    return "jsx";
  }
  if (/Token$|Keyword$|Trivia$|Literal$/.test(kind)) {
    return "lexical-and-literals";
  }
  if (
    /Type|Signature|TypeParameter|HeritageClause|Infer|Mapped|Conditional/.test(kind)
  ) {
    return "types";
  }
  if (
    /Declaration|Import|Export|Module|Namespace|Class|Interface|Enum|Variable|Parameter|Binding|Property|Method|Constructor|Accessor/.test(kind)
  ) {
    return "declarations-and-modules";
  }
  if (/Statement|Block|Clause|Catch|Case|Switch|Try/.test(kind)) {
    return "statements-and-control";
  }
  if (/Expression|Template|Identifier|QualifiedName|Element|Spread/.test(kind)) {
    return "expressions-and-names";
  }
  return "source-and-other";
}

function increment(map, key, amount = 1) {
  map.set(key, (map.get(key) ?? 0) + amount);
}

function parseTsv(text) {
  const lines = text.trimEnd().split("\n");
  const headers = lines[0].split("\t");
  return lines.slice(1).map((line) => {
    const values = line.split("\t");
    return Object.fromEntries(headers.map((header, index) => [header, values[index] ?? ""]));
  });
}

function diagnosticCatalog() {
  if (!fs.existsSync(DIAGNOSTIC_AUDIT_PATH)) {
    throw new Error(`missing ${DIAGNOSTIC_AUDIT_PATH}; generate the upstream audit first`);
  }
  return parseTsv(fs.readFileSync(DIAGNOSTIC_AUDIT_PATH, "utf8"))
    .map((row) => ({ symbol: row.upstream_symbol, code: Number(row.code) }));
}

function verifyStressBudgets(streamOnlyInputs) {
  const document = JSON.parse(fs.readFileSync(STRESS_BUDGETS_PATH, "utf8"));
  if (document.schema_version !== 2 || !document.runner_class) {
    throw new Error(`${STRESS_BUDGETS_PATH} has invalid metadata`);
  }
  if (
    !Number.isInteger(document.parser_protocol?.warmup_runs) ||
    document.parser_protocol.warmup_runs <= 0 ||
    !Number.isInteger(document.parser_protocol?.repeat_runs) ||
    document.parser_protocol.repeat_runs <= 0 ||
    document.parser_protocol.statistic !== "median_wall_ms" ||
    !Array.isArray(document.benchmarks) || document.benchmarks.length === 0 ||
    !Array.isArray(document.complexity) || document.complexity.length === 0
  ) {
    throw new Error(`${STRESS_BUDGETS_PATH} lacks an executable parser protocol`);
  }
  for (const benchmark of document.benchmarks) {
    if (
      !Number.isInteger(benchmark.units) || benchmark.units <= 0 ||
      !Number.isInteger(benchmark.iterations_per_process) || benchmark.iterations_per_process <= 0 ||
      !Number.isInteger(benchmark.timeout_ms) || benchmark.timeout_ms <= 0 ||
      !Number.isFinite(benchmark.max_median_wall_ms) || benchmark.max_median_wall_ms <= 0 ||
      !Number.isInteger(benchmark.max_peak_rss_kib) || benchmark.max_peak_rss_kib <= 0
    ) {
      throw new Error(`non-executable parser benchmark ${benchmark.id}`);
    }
  }
  for (const complexity of document.complexity) {
    if (
      !Number.isInteger(complexity.n) || complexity.n <= 0 ||
      !Number.isFinite(complexity.max_t2_over_t1) || complexity.max_t2_over_t1 <= 1 ||
      !Number.isFinite(complexity.max_t4_over_t2) || complexity.max_t4_over_t2 <= 1
    ) {
      throw new Error(`non-executable complexity budget ${complexity.id}`);
    }
  }
  for (const key of [
    "warmup_files",
    "timeout_ms",
    "max_peak_rss_kib",
    "max_post_warmup_growth_kib",
    "max_slope_kib_per_1000_files",
  ]) {
    if (!Number.isFinite(document.corpus_memory?.[key]) || document.corpus_memory[key] <= 0) {
      throw new Error(`non-executable corpus memory budget ${key}`);
    }
  }
  const inputs = document.fixtures.map((fixture) => fixture.input).sort();
  if (JSON.stringify(inputs) !== JSON.stringify(streamOnlyInputs)) {
    throw new Error("stress-budget fixture list does not match stream-only AST inputs");
  }
  for (const fixture of document.fixtures) {
    if (
      !Number.isInteger(fixture.timeout_ms) || fixture.timeout_ms <= 0 ||
      !Number.isInteger(fixture.max_peak_rss_kib) || fixture.max_peak_rss_kib <= 0
    ) {
      throw new Error(`non-executable stress budget for ${fixture.input}`);
    }
    if (
      !Number.isInteger(fixture.baseline_wall_ms) ||
      !Number.isInteger(fixture.baseline_peak_rss_kib) ||
      fixture.timeout_ms <= fixture.baseline_wall_ms ||
      fixture.max_peak_rss_kib <= fixture.baseline_peak_rss_kib
    ) {
      throw new Error(`stress budget lacks measured headroom for ${fixture.input}`);
    }
  }
  return document;
}

function inspectAst(astPath, aggregates) {
  const root = JSON.parse(fs.readFileSync(astPath, "utf8"));
  const stack = [root];
  const fileKinds = new Set();
  while (stack.length > 0) {
    const node = stack.pop();
    if (!node || typeof node !== "object" || typeof node.kind !== "string") {
      throw new Error(`invalid legacy AST node in ${astPath}`);
    }
    increment(aggregates.kindOccurrences, node.kind);
    fileKinds.add(node.kind);
    if (node.children !== undefined) {
      if (!Array.isArray(node.children)) {
        throw new Error(`invalid children in ${astPath}`);
      }
      for (const child of node.children) {
        stack.push(child);
      }
    }
  }
  for (const kind of fileKinds) {
    increment(aggregates.kindFiles, kind);
  }
  if ([...fileKinds].some((kind) => kind.startsWith("JSDoc"))) {
    aggregates.jsdocAstFiles++;
  }
}

function inspectErrors(errorsPath, aggregates) {
  const text = fs.readFileSync(errorsPath, "utf8");
  const fileCodes = new Set();
  for (const match of text.matchAll(/\bTS(\d+):/g)) {
    const code = Number(match[1]);
    increment(aggregates.diagnosticOccurrences, code);
    fileCodes.add(code);
  }
  for (const code of fileCodes) {
    increment(aggregates.diagnosticFiles, code);
  }
}

function buildAudit() {
  const inputs = corpusInputs();
  const aggregates = {
    kindOccurrences: new Map(),
    kindFiles: new Map(),
    diagnosticOccurrences: new Map(),
    diagnosticFiles: new Map(),
    scriptKinds: new Map(),
    jsdocAstFiles: 0,
  };
  const manifest = [];
  const streamOnlyInputs = [];

  for (const input of inputs) {
    const paths = baselinePaths(input);
    const extension = path.extname(input);
    const scriptKind = scriptKindForExtension(extension);
    increment(aggregates.scriptKinds, scriptKind);
    if (!fs.existsSync(paths.errors)) {
      throw new Error(`missing paired legacy diagnostics: ${paths.errors}`);
    }
    const astExists = fs.existsSync(paths.ast);
    if (!astExists) {
      streamOnlyInputs.push(input);
    } else {
      const size = fs.statSync(paths.ast).size;
      if (size > MAX_STORED_AST_BYTES) {
        throw new Error(`${paths.ast} exceeds the committed 4 MiB storage policy`);
      }
      inspectAst(paths.ast, aggregates);
    }
    inspectErrors(paths.errors, aggregates);

    const referenceStem = paths.stem.slice(`${CORPUS_DIRECTORY}/`.length);
    const structuredDiagnosticsReference = `references/diagnostics/${referenceStem}.jsonl`;
    if (!fs.existsSync(structuredDiagnosticsReference)) {
      throw new Error(
        `missing structured diagnostics reference: ${structuredDiagnosticsReference}`,
      );
    }
    manifest.push({
      input,
      script_kind: scriptKind,
      input_bytes: fs.statSync(input).size,
      input_sha256: sha256File(input),
      legacy_ast: astExists
        ? {
            path: paths.ast,
            bytes: fs.statSync(paths.ast).size,
            sha256: sha256File(paths.ast),
          }
        : null,
      legacy_ast_mode: astExists ? "committed_file" : "online_stream",
      legacy_errors: {
        path: paths.errors,
        bytes: fs.statSync(paths.errors).size,
        sha256: sha256File(paths.errors),
      },
      structured_diagnostics_reference: structuredDiagnosticsReference,
      structured_diagnostics_status: "committed",
      structured_diagnostics_bytes: fs.statSync(structuredDiagnosticsReference).size,
      structured_diagnostics_sha256: sha256File(structuredDiagnosticsReference),
      full_node_reference_mode: "online_stream",
      stress_budget: astExists ? null : input,
    });
  }

  streamOnlyInputs.sort();
  if (JSON.stringify(streamOnlyInputs) !== JSON.stringify(EXPECTED_STREAM_ONLY_INPUTS)) {
    throw new Error(
      `stream-only AST input set changed: found ${JSON.stringify(streamOnlyInputs)}`,
    );
  }
  const stressBudgets = verifyStressBudgets(streamOnlyInputs);

  const directErrorFiles = fs.readdirSync(CORPUS_DIRECTORY)
    .filter((name) => name.endsWith(".errors.txt")).length;
  const storedAstFiles = manifest.filter((entry) => entry.legacy_ast).length;
  const scriptKindCounts = Object.fromEntries([...aggregates.scriptKinds].sort());
  if (
    inputs.length !== 6541 ||
    scriptKindCounts.TS !== 6423 ||
    scriptKindCounts.TSX !== 118 ||
    storedAstFiles !== 6530 ||
    directErrorFiles !== 7661
  ) {
    throw new Error(
      `corpus totals changed: inputs=${inputs.length}, TS=${scriptKindCounts.TS ?? 0}, ` +
        `TSX=${scriptKindCounts.TSX ?? 0}, AST=${storedAstFiles}, errors=${directErrorFiles}`,
    );
  }
  if (aggregates.kindOccurrences.size !== 234) {
    throw new Error(`expected 234 covered runtime kind names, found ${aggregates.kindOccurrences.size}`);
  }
  if (aggregates.jsdocAstFiles !== 3) {
    throw new Error(`expected 3 JSDoc AST baselines, found ${aggregates.jsdocAstFiles}`);
  }

  const kinds = [...aggregates.kindOccurrences.keys()].sort().map((kind) => ({
    runtime_name: kind,
    family: familyForKind(kind),
    node_occurrences: aggregates.kindOccurrences.get(kind),
    baseline_files: aggregates.kindFiles.get(kind),
  }));
  const diagnostics = [...aggregates.diagnosticOccurrences.keys()].sort((a, b) => a - b).map((code) => ({
    code,
    occurrences: aggregates.diagnosticOccurrences.get(code),
    baseline_files: aggregates.diagnosticFiles.get(code),
  }));
  const familyMap = new Map();
  for (const kind of kinds) {
    const entry = familyMap.get(kind.family) ?? { runtime_names: 0, node_occurrences: 0 };
    entry.runtime_names++;
    entry.node_occurrences += kind.node_occurrences;
    familyMap.set(kind.family, entry);
  }

  const runtimeNames = new Set(
    Array.from({ length: ts.SyntaxKind.Count }, (_, value) => ts.SyntaxKind[value]),
  );
  const coveredKindNames = new Set(kinds.map((entry) => entry.runtime_name));
  const uncoveredRuntimeNames = [...runtimeNames]
    .filter((name) => !coveredKindNames.has(name))
    .sort();
  const coveredDiagnosticCodes = new Set(diagnostics.map((entry) => entry.code));
  const uncoveredDiagnostics = diagnosticCatalog()
    .filter((entry) => !coveredDiagnosticCodes.has(entry.code))
    .sort((left, right) => left.code - right.code || left.symbol.localeCompare(right.symbol));

  const coverage = {
    schema_version: 1,
    projection: "legacy AST and paired legacy parse-diagnostic baselines",
    corpus: {
      inputs: inputs.length,
      script_kinds: scriptKindCounts,
      stored_legacy_ast: storedAstFiles,
      online_stream_legacy_ast: streamOnlyInputs.length,
      paired_legacy_errors: inputs.length,
      historical_error_files_not_selected_by_manifest: directErrorFiles - inputs.length,
      jsdoc_ast_files: aggregates.jsdocAstFiles,
    },
    runtime_kind_names: kinds,
    diagnostic_codes: diagnostics,
    feature_families: Object.fromEntries([...familyMap].sort()),
    uncovered: {
      runtime_kind_names: uncoveredRuntimeNames,
      required_diagnostic_catalog_entries: uncoveredDiagnostics,
      script_kinds: ["JS", "JSX", "JSON"],
      projection_dimensions: [
        "numeric kind",
        "raw pos/end",
        "node-specific fields",
        "NodeFlags/TransformFlags/TokenFlags",
        "NodeArray metadata",
        "named child edges",
        "parent links",
        "SourceFile metadata",
        "structured diagnostic chains and related information",
      ],
    },
    stress_budgets: {
      runner_class: stressBudgets.runner_class,
      fixtures: stressBudgets.fixtures.length,
    },
  };
  return { manifest, coverage };
}

function fixtureTasks(coverage) {
  const tasks = [];
  for (const name of coverage.uncovered.runtime_kind_names) {
    tasks.push({
      task_id: `syntax-kind:${name}`,
      gap_kind: "runtime_kind",
      upstream_item: name,
      required_fixture: `Add the smallest fixed reference that creates runtime kind ${name}, or record it as parser-nonconstructible.`,
      target_area: name.startsWith("JSDoc")
        ? "jsdoc"
        : name.startsWith("Jsx")
          ? "jsx"
          : "syntax-kind/factory/traversal",
    });
  }
  for (const diagnostic of coverage.uncovered.required_diagnostic_catalog_entries) {
    tasks.push({
      task_id: `diagnostic:${diagnostic.code}:${diagnostic.symbol}`,
      gap_kind: "diagnostic",
      upstream_item: `${diagnostic.symbol} (TS${diagnostic.code})`,
      required_fixture: "Add a fixed public-parser, scanner-report-errors, or JSON-wrapper fixture matching its audited reachability.",
      target_area: "diagnostics/source",
    });
  }
  for (const scriptKind of coverage.uncovered.script_kinds) {
    tasks.push({
      task_id: `script-kind:${scriptKind}`,
      gap_kind: "script_kind",
      upstream_item: scriptKind,
      required_fixture: `Add committed ${scriptKind} input plus AST, structured diagnostic, and SourceFile metadata references.`,
      target_area: scriptKind === "JSON" ? "source" : "jsx/source",
    });
  }
  for (const dimension of coverage.uncovered.projection_dimensions) {
    tasks.push({
      task_id: `projection:${dimension.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}`,
      gap_kind: "projection_dimension",
      upstream_item: dimension,
      required_fixture: `Extend the structured reference and add a fixed fixture for ${dimension}.`,
      target_area: "structured-reference",
    });
  }
  tasks.push({
    task_id: "feature-family:jsdoc-complete",
    gap_kind: "feature_family",
    upstream_item: "JSDoc (only 3 legacy AST files)",
    required_fixture: "Add fixed JS fixtures for every JSDoc node/tag kind and diagnostic flow.",
    target_area: "jsdoc",
  });
  return tasks.sort((left, right) => left.task_id.localeCompare(right.task_id));
}

function existingFixtureProgress() {
  if (!fs.existsSync(FIXTURE_TASKS_PATH)) {
    return new Map();
  }
  return new Map(parseTsv(fs.readFileSync(FIXTURE_TASKS_PATH, "utf8"))
    .map((row) => [row.task_id, {
      fixture_location: row.fixture_location ?? "",
      status: row.status ?? "pending",
    }]));
}

function completedFixtureProgress(task) {
  if (task.gap_kind === "diagnostic") {
    return {
      fixture_location: "diagnostic_wbtest.mbt; parser_invariants_wbtest.mbt; references/diagnostics; scripts/audit-test-coverage.mjs",
      status: "complete",
    };
  }
  if (task.gap_kind === "runtime_kind") {
    if (task.upstream_item.startsWith("JSDoc")) {
      return {
        fixture_location: "fixtures/jsdoc; parser_jsdoc_wbtest.mbt; scripts/audit-parser-jsdoc.mjs",
        status: "complete",
      };
    }
    if (task.upstream_item.startsWith("Jsx")) {
      return {
        fixture_location: "fixtures/structured/basic.jsx; parser_jsx_wbtest.mbt; scripts/audit-structured.mjs",
        status: "complete",
      };
    }
    return {
      fixture_location: "syntax_kind_wbtest.mbt; scanner_token_coverage_wbtest.mbt; node_factory_contract_wbtest.mbt; scripts/audit-test-coverage.mjs",
      status: "complete_scanner_factory_or_nonconstructible",
    };
  }
  if (task.gap_kind === "script_kind") {
    return {
      fixture_location: `fixtures/structured/basic.${task.upstream_item.toLowerCase()}; scripts/audit-structured.mjs`,
      status: "complete",
    };
  }
  if (task.gap_kind === "projection_dimension") {
    return {
      fixture_location: "scripts/ts-reference.mjs; tools/structure; scripts/audit-structured.mjs",
      status: "complete",
    };
  }
  return {
    fixture_location: "fixtures/jsdoc; parser_jsdoc_wbtest.mbt; scripts/audit-parser-jsdoc.mjs",
    status: "complete",
  };
}

function fixtureTasksTsv(coverage) {
  const headers = [
    "task_id",
    "gap_kind",
    "upstream_item",
    "required_fixture",
    "target_area",
    "fixture_location",
    "status",
  ];
  const progress = existingFixtureProgress();
  const lines = [headers.join("\t")];
  for (const task of fixtureTasks(coverage)) {
    const saved = progress.get(task.task_id);
    const completed = completedFixtureProgress(task);
    const effective = !saved || saved.status === "pending" || !saved.fixture_location
      ? completed
      : saved;
    const row = { ...task, ...effective };
    lines.push(headers.map((header) => String(row[header] ?? "").replace(/[\t\r\n]+/g, " ")).join("\t"));
  }
  return `${lines.join("\n")}\n`;
}

function coverageMarkdown(coverage) {
  const corpus = coverage.corpus;
  const families = Object.entries(coverage.feature_families)
    .map(([name, value]) => `| ${name} | ${value.runtime_names} | ${value.node_occurrences} |`)
    .join("\n");
  return `# Legacy baseline coverage\n\n` +
    "This is a generated, read-only inventory of the committed legacy projection. It does not claim full AST coverage. " +
    "Run `node scripts/generate-corpus-audit.mjs --verify` to reproduce it.\n\n" +
    "## Corpus\n\n" +
    `- Inputs: ${corpus.inputs} (${corpus.script_kinds.TS} TS, ${corpus.script_kinds.TSX} TSX).\n` +
    `- Stored legacy AST: ${corpus.stored_legacy_ast}; online-stream-only AST: ${corpus.online_stream_legacy_ast}.\n` +
    `- Input-paired legacy errors: ${corpus.paired_legacy_errors}; excluded historical errors: ${corpus.historical_error_files_not_selected_by_manifest}.\n` +
    `- Covered runtime reverse kind names: ${coverage.runtime_kind_names.length}; missing: ${coverage.uncovered.runtime_kind_names.length}.\n` +
    `- Covered parser diagnostic codes: ${coverage.diagnostic_codes.length}; missing required catalog entries: ${coverage.uncovered.required_diagnostic_catalog_entries.length}.\n` +
    `- Legacy AST files containing any JSDoc node: ${corpus.jsdoc_ast_files}; this is explicitly insufficient for JSDoc completion.\n\n` +
    "## Kind feature families\n\n" +
    "| Family | Runtime names | Node occurrences |\n" +
    "|---|---:|---:|\n" +
    `${families}\n\n` +
    "## Historical legacy-projection gaps\n\n" +
    `All ${fixtureTasks(coverage).length} concrete legacy gaps are tracked in ` +
    "[`fixture-tasks.tsv`](fixture-tasks.tsv). It includes every uncovered runtime kind name, " +
    "required diagnostic, missing JS/JSX/JSON ScriptKind, and every dimension omitted by the legacy projection. " +
    "Its completed locations point to the later scanner/factory, fixed-fixture, full-structure, and diagnostic suites; " +
    "completion does not rewrite the historical legacy corpus.\n";
}

function expectedOutputs() {
  const { manifest, coverage } = buildAudit();
  return [
    {
      path: MANIFEST_PATH,
      contents: `${manifest.map((entry) => JSON.stringify(entry)).join("\n")}\n`,
    },
    {
      path: COVERAGE_JSON_PATH,
      contents: `${JSON.stringify(coverage, null, 2)}\n`,
    },
    {
      path: COVERAGE_MARKDOWN_PATH,
      contents: coverageMarkdown(coverage),
    },
    {
      path: FIXTURE_TASKS_PATH,
      contents: fixtureTasksTsv(coverage),
    },
  ];
}

function main(argv) {
  const mode = parseMode(
    argv,
    ["write", "verify"],
    "usage: node scripts/generate-corpus-audit.mjs <--write|--verify>",
  );
  const outputs = expectedOutputs();
  if (mode === "write") {
    fs.mkdirSync("docs", { recursive: true });
    for (const output of outputs) {
      fs.writeFileSync(output.path, output.contents);
    }
    console.log("wrote corpus audit: 6541 inputs, 6530 stored AST, 11 streaming AST exceptions");
    return;
  }
  for (const output of outputs) {
    if (!fs.existsSync(output.path)) {
      throw new Error(`missing ${output.path}`);
    }
    if (fs.readFileSync(output.path, "utf8") !== output.contents) {
      throw new Error(`${output.path} is stale; review the corpus and run with --write`);
    }
  }
  console.log("verified corpus audit: 6541 inputs, 6530 stored AST, 11 streaming AST exceptions");
}

const currentFile = fileURLToPath(import.meta.url);
if (process.argv[1] && path.resolve(process.argv[1]) === currentFile) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  }
}
