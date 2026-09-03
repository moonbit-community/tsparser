# Legacy baseline coverage

This is a generated, read-only inventory of the committed legacy projection. It does not claim full AST coverage. Run `node scripts/generate-corpus-audit.mjs --verify` to reproduce it.

## Corpus

- Inputs: 6541 (6423 TS, 118 TSX).
- Stored legacy AST: 6530; online-stream-only AST: 11.
- Input-paired legacy errors: 6541; excluded historical errors: 1120.
- Covered runtime reverse kind names: 234; missing: 125.
- Covered parser diagnostic codes: 67; missing required catalog entries: 81.
- Legacy AST files containing any JSDoc node: 3; this is explicitly insufficient for JSDoc completion.

## Kind feature families

| Family | Runtime names | Node occurrences |
|---|---:|---:|
| declarations-and-modules | 40 | 111105 |
| expressions-and-names | 27 | 214017 |
| jsdoc | 3 | 46 |
| jsx | 13 | 1724 |
| lexical-and-literals | 83 | 94876 |
| source-and-other | 10 | 17291 |
| statements-and-control | 24 | 57994 |
| types | 34 | 69844 |

## Historical legacy-projection gaps

All 219 concrete legacy gaps are tracked in [`fixture-tasks.tsv`](fixture-tasks.tsv). It includes every uncovered runtime kind name, required diagnostic, missing JS/JSX/JSON ScriptKind, and every dimension omitted by the legacy projection. Its completed locations point to the later scanner/factory, fixed-fixture, full-structure, and diagnostic suites; completion does not rewrite the historical legacy corpus.
