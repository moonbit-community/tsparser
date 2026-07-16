# Validation

`npm run audit` executes the read-only baseline audit group. Pass one or more
stable selectors to run a focused subset, for example
`npm run audit -- parser repo`; use `npm run audit -- --list` to list all
groups and checks. Artifact updates remain separate `generate:*` or
`measure:*` commands.

## Tests and coverage

The exhaustive audit tables cover syntax kinds, diagnostics, parser-used
factory entries, `forEachChild` branches, and real parsing contexts.
`npm run audit -- test-coverage` verifies that every current row names an
executable test or audit location. The same gate checks the UTF-16,
token/rescan, rollback, ASI, operator, JSX ambiguity, decorator,
module/top-level-await, JSDoc, JSON, parent, malformed-corpus, mutation, range,
child-containment, and `NodeArray` suites.

Run `npm run generate:coverage` only when intentionally refreshing
coverage. It executes the required clean/caret/summary protocol and writes:

- `coverage/caret.txt`;
- `coverage/summary.txt`;
- `coverage/uncovered.tsv`.

The mapping assigns every uncovered root-package point to its scanner, parser,
representation, factory, traversal, diagnostics, or SourceFile audit contract.
It claims no unreachable/platform exemption. Native-only diff tools are outside
the root-package coverage acceptance.

## Full differential matrix

`npm run diff:full` compares all 6,541 inputs. It uses byte-streamed legacy AST
comparison, so the two 2.31 GB deeply indented binary-expression projections do
not need to be held in memory. `npm run audit -- online-legacy` generates and
compares the 11 non-committed projections independently, with per-process-group
TERM/KILL timeout handling and Linux `/proc` peak-RSS sampling.

`npm run audit -- structured` creates pinned TypeScript and MoonBit streams
for fixed `.js`, `.jsx`, `.json`, and `.tsx` inputs. It compares every parser
node's numeric kind, raw range, flags, transform flags, scalar fields, named
child edges, token text/flags, plus collection range/order/trailing-comma/
transform metadata. The JS fixture includes attached JSDoc.

## Robustness, complexity, and memory

[`stress-budgets.json`](stress-budgets.json) is the executable manifest.
`npm run audit -- stress` builds the native release runner, performs two warm-up
runs and five measured repeats, and uses the median wall time. It covers
small/medium/large inputs, deep parentheses/types/JSX, long binary and list
forms, regexp-v, JSX, and JSDoc.

Scanner, list parsing, and child traversal use fixed N/2N/4N generators and
numeric ratio limits. Full-corpus memory runs separately with parents off and
on; progress is written through asynchronous standard output so the supervisor
can sample real post-warm-up RSS, growth, and fitted KiB-per-1,000-files slope.
Recorded results are in [`stress-results.json`](stress-results.json).
Unterminated literals and comments, no-progress closing tokens, and
2,000-diagnostic inputs also have root-package regression tests.
