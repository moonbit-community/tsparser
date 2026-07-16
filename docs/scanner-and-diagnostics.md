# Scanner and diagnostics

The scanner and diagnostic layer follows the TypeScript 6.0.3 source pinned by
[`scripts/upstream-config.mjs`](../scripts/upstream-config.mjs). This document
records behavior that callers and parser maintenance rely on; current
inventories and counts come from the executable audits.

## Scanner ownership and rollback

Each parse owns a private `Scanner`. It keeps the source range, target,
language variant, `ScriptKind`, JSDoc mode, error callback, comment directives,
JSDoc leading-asterisk depth, and mutable token state.

Lookahead and failed try-scan restore the same six fields as TypeScript:
position, full start, token start, kind, value, and flags. A successful
try-scan commits. Scan-range also restores its temporary end and
comment-directive collection.

Ordinary punctuation uses maximal matching. Ambiguous parser contexts are
handled by explicit rescans for greater-than tokens, slash/regexp, `*=`,
template tokens, JSX tokens and attributes, `<`, `#`, `?`, and invalid
identifiers. Scanner snapshots never include parser context or global mutable
state.

## Tokens and text

- Keyword, punctuation, character-code, identifier, and regexp-property tables
  are checked in and compared semantically with the pinned TypeScript source.
- Identifier scanning uses the ES5 and ESNext range tables with UTF-16-aware
  surrogate handling. It covers escaped and astral identifiers, ZWNJ/ZWJ,
  private identifiers, escaped keywords, JSX hyphens, and invalid-identifier
  rescanning.
- Numeric scanning covers decimal, binary, octal, hexadecimal, legacy octal,
  fractions, exponents, separators, leading zeroes, and BigInt. Radix BigInts
  retain upstream spelling without depending on host integer width.
- String and template tokens preserve raw versus cooked text, line-ending
  normalization, escape families, invalid/unterminated flags, and the
  tagged-template rule that suppresses an invalid-escape diagnostic while
  preserving raw text.

Whitespace, ECMAScript line breaks, BOM, shebang, comments, merge markers, the
non-text marker, invalid characters, and comment ranges follow the pinned
scanner. In TypeScript 6.0.3, `<!--` and `-->` have no special scanner meaning;
they tokenize as punctuation and identifiers around the line break.

Comment directives recognize only `ts-expect-error` and `ts-ignore`, including
the final line of a multiline comment. `ts-check` and `ts-nocheck` are parsed
later as SourceFile pragmas.

JSX scanning has distinct identifier, attribute-value, and child-text modes.
JSDoc scanning has ordinary-token, comment-text/backtick, and
leading-asterisk-skipping modes, gated by `ScriptKind` and
`JSDocParsingMode`.

## Regular expressions

The parser-visible `reScanSlashToken()` finds the literal boundary, records an
unterminated token when necessary, and applies delimiter-aware recovery. It
does not request grammar or flag diagnostics.

The white-box `report_errors=true` path additionally validates duplicate and
target-dependent flags, named captures, backreferences, quantifiers,
subpattern modifiers, `u`/`v` escapes, ordinary and set-operation character
classes, string disjunction, and Unicode properties. Diagnostics retain the
upstream code, UTF-16 position, length, argument, and production order.

Keeping those paths separate is intentional: full regexp grammar diagnostics
are scanner-worker results and are not inserted into
`SourceFile.parse_diagnostics` by the public parser.

## Diagnostic representation

`DiagnosticMessage` retains its upstream symbol, key, numeric code, category,
English template, placeholder arity, and report markers. Localized catalog
loading is intentionally absent; checked-in English TypeScript 6.0.3 strings
are the runtime catalog.

Formatting preserves string versus integer arguments. Placeholder replacement
supports decimal indexes, including multiple digits. With no arguments, the
template remains unchanged.

`DiagnosticMessageText` distinguishes a plain string from a preformatted
message chain. Chains preserve `next=None` versus a present empty list and keep
sibling order; flattening adds a newline and two spaces per nesting level.

`Diagnostic` is immutable to callers and distinguishes:

- no location;
- a detached filename and optional UTF-16 range;
- an attached `SourceFile` and range.

Detached construction clips only a span that extends past source end before
validating it. Attaching verifies the filename and range, recursively attaches
same-file detached related information, and leaves other-file or no-location
entries unchanged. Adding related information returns a new diagnostic and
preserves order; diagnostics are never globally sorted or deduplicated.

Parser insertion compares only the last diagnostic's `start`. A same-start
adjacent error is suppressed, but that start is accepted again after an
intervening diagnostic. Scanner span lengths and production order are
preserved. Even a suppressed error marks the next finished syntax node.

## Reachability

[`upstream-audit/diagnostics.tsv`](upstream-audit/diagnostics.tsv) records
additive reachability through the public parser, public scanner integration,
scanner `report_errors=true`, and JSON wrapper. Catalogued checker-only or
scanner-worker diagnostics are not manufactured by the public parser.

The maintained source and audit map is:

| Area | Main implementation | Verification |
|---|---|---|
| diagnostic values and attachment | `diagnostic.mbt`, `diagnostic_catalog.mbt` | `audit -- diagnostics` |
| scanner state and tokenization | `scanner*.mbt`, `scanner_tables.mbt` | `audit -- scanner` |
| Unicode identifier tables | `scanner_unicode_tables.mbt` | `audit -- scanner` |
| regexp validation | `scanner_regexp*.mbt` | `audit -- scanner` |

Run:

```sh
npm run audit -- diagnostics scanner
moon check --target all --deny-warn
moon test --target all
moon info
```
