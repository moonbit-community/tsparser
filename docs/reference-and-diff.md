# Reference streams and differential testing

This document defines the differential verification contract. The normative
runtime is the exact TypeScript package and source commit selected by
[`scripts/upstream-config.mjs`](../scripts/upstream-config.mjs) and recorded in
[`upstream-source-manifest.json`](upstream-source-manifest.json).

## Reference streams

`scripts/ts-reference.mjs` exposes four deterministic modes:

| Mode | Schema | Content |
|---|---|---|
| `full-ast` | `typescript-6.0.3-full-ast-v1` | One header followed by iterative node, NodeArray, and parser-only node-list records. |
| `diagnostics` | record stream | `parseDiagnostics` followed by `jsDocDiagnostics`, preserving each array's original order, message chains, and related information. |
| `source-file` | `typescript-6.0.3-source-file-v1` | Script/target/variant, declaration mode, identifiers, pragmas, references, directives, module indicator, JSDoc mode, and parser counts. |
| `scanner` | record stream | Token kind/ranges/raw text/value/flags, preceding trivia state, token diagnostics, directives, and summary. |

The full AST stream records both numeric `SyntaxKind` and the runtime reverse
name. Declaration names and classification aliases remain separate. It keeps
raw and clipped UTF-16 locations, parser scalar fields (including explicit
`undefined`), token flags, `NodeFlags`, `TransformFlags`, named child edges,
and NodeArray boundaries and metadata. Attached JSDoc is an explicit
`parser_extra` edge because the ordinary host `forEachChild` traversal omits it.
When upstream `forEachChild` calls back once per element of a child array, the
reference maps those calls back to the owning field and verifies element order.

The projection excludes parent cycles and compiler-owned state: symbols,
locals, flow nodes, emit/original links, checker links/caches, and internal IDs.
The exclusions are explicit in `scripts/ts-reference.mjs` rather than inferred
from JSON serialization failures.

## Committed and online baselines

- All 6,530 stored legacy AST files are regenerated in memory and compared
  byte-for-byte by `scripts/verify-legacy-corpus.mjs`.
- All 6,541 paired legacy `.errors.txt` projections are compared byte-for-byte.
- There are 6,541 committed structured-diagnostic reference paths. Of these, 447
  are non-empty and 6,094 deliberately represent an empty diagnostic stream;
  together they contain 2,425 records and 785,586 bytes. The corpus manifest
  records the byte length and SHA-256 of every file.
- Full-node projections stay online and stream one record at a time. This
  applies equally to the 6,530 files with a legacy AST and the 11 storage
  exceptions; the 4 MiB legacy storage policy is not a semantic skip.

`scripts/validate-reference-corpus.mjs` streams every input without retaining a
whole-corpus AST. It validates node, NodeArray, parser-only list, diagnostic,
and SourceFile records and rechecks each input byte length and SHA-256 against
the manifest. Its final machine-readable summary is the current source of truth
for record and byte totals.

The 11 pressure fixtures are additionally run in isolated processes with
stdout consumed by the operating system. `docs/reference-pressure-results.json`
records the executable budgets and reference measurements.
`npm run audit -- reference-pressure` requires every process to exit successfully
within its timeout and peak-RSS limits.

## Native differential program

`tools/diff` is a native-only executable. The public parser package does not
import native I/O. Its arguments are:

```text
--manifest PATH
--shard-index N
--shard-count N
--filter TEXT
--max-failures N
--one-file PATH
```

`--verify-shards`, `--synthetic-regression`, and the paired
`--expected-stream`/`--actual-stream` flags are harness diagnostics. Manifest
paths are normalized, duplicate or escaping paths are rejected, and inputs are
sorted before assigning sorted index `i` to shard `i % shard_count`.

The program uses `moonbitlang/async` filesystem and reader APIs to read one line
at a time. It keeps only the current expected and actual NDJSON records, closes
both streams explicitly, and reports file, node/diagnostic path, field,
expected value, and actual value. Legacy AST comparison likewise stays
streaming through a bounded 64 KiB expected-byte buffer; the project does not
carry a custom native I/O stub.

The synthetic regression has four fixed mismatches and reports all four
independently: numeric kind, raw position, child order, and diagnostic code.
Ordinary corpus invocations now parse and compare the complete matrix; this
synthetic mode remains only as a regression test for failure reporting.

`--verify-shards` proves that every sorted manifest entry is assigned exactly
once for the requested shard count and that the shard sizes differ by at most
one.

## Reproduction

```sh
npm run test:baseline
npm run audit -- reference-corpus reference-pressure
moon test tools/diff --target native --deny-warn
moon run tools/diff --target native -- \
  --manifest docs/corpus-manifest.jsonl --verify-shards --shard-count 17
```
