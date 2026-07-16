# TypeScript 6.0.3 upstream parser audit

Normative upstream commit: `050880ce59e30b356b686bd3144efe24f875ebc8`. Refresh only after an explicit upstream-version decision:

```sh
node scripts/bootstrap-typescript-source.mjs --verify
node scripts/generate-upstream-audit.mjs --write
```

Every TSV carries the required progress columns `moonbit_implementation`, `test_location`, and `status`. The generator preserves those three columns by `upstream_symbol`; all other columns are derived from the exact upstream checkout.

- SyntaxKind numeric values: 359; `SyntaxKind.Count == 359`.
- Parser-used NodeFactory entries: 195.
- `forEachChild` branches: 175.
- Real ParsingContext values: 26; `Count` is excluded.
- Scanner/parser/JSON-wrapper diagnostics: 148.
- Scanner helper functions: 95, grouped into 19 exact behavioral contracts.
- Scanner token kinds: 167 (`SyntaxKind` values 0 through 166), all with an
  ordinary or contextual scanner path.
- parser core helpers: 111, grouped into 12 exact behavioral contracts;
  all 26 real ParsingContext rows are complete.
- type parser helpers: 92, grouped into 10 exact behavioral contracts;
  all 24 parser-created TypeScript type SyntaxKinds are covered.
- expression parser helpers: 63, grouped into 9 exact behavioral contracts;
  all 30 non-synthetic expression SyntaxKinds and 41 operators are covered.
- statement/declaration parser helpers: 95, grouped into 9 exact behavioral contracts;
  all 48 parser-created statement/declaration SyntaxKinds are covered.
- module/top-level-await parser helpers: 45, grouped into 8 exact behavioral contracts;
  all 15 module SyntaxKinds and identity-preserving await intervals are covered.
- JSX/TSX parser helpers: 28, grouped into 6 exact behavioral contracts;
  all 12 JSX SyntaxKinds and the three-way less-than ambiguity are covered.
- JSDoc helpers: 64, grouped into 9 exact behavioral contracts; all
  43 JSDoc SyntaxKinds, aliases, parsing modes, attachment paths, and
  diagnostic channels are covered.
- JSON, pragma, SourceFile, and public API behavior is grouped
  into 8 exact contracts; both JSON entry paths, nine pragma keys, five
  public entries, invocation isolation, and immutable result collections
  are covered.

Diagnostic reachability is additive: `scanner_public_parser` and `public_parser` feed public parse diagnostics, `scanner_report_errors_only` is the full regexp validation path not requested by the public parser, and `json_wrapper` is the `create_source_file(..., ScriptKind.JSON)` conversion path.
