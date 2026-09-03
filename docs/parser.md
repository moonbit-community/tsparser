# Parser design

`tsparser` implements the TypeScript 6.0.3 parser contract pinned by
[`scripts/upstream-config.mjs`](../scripts/upstream-config.mjs). This document
describes current control flow, recovery, and grammar boundaries. Executable
audits under `scripts/` and source-derived tables under `upstream-audit/`
remain authoritative for inventories and counts.

## Implementation map

| Area | Main implementation | Verification |
|---|---|---|
| parser state, tokens, lists, recovery | `parser_state*.mbt`, `parser_tokens.mbt`, `parser_lists.mbt` | `audit -- parser-core` |
| names, signatures, and types | `parser_names_literals.mbt`, `parser_parameters_signatures.mbt`, `parser_types.mbt` | `audit -- types` |
| expressions | `parser_expression_*.mbt` | `audit -- expressions` |
| statements and declarations | `parser_statements.mbt`, `parser_bindings_variables.mbt`, `parser_declarations.mbt` | `audit -- statements` |
| imports, exports, top-level await | `parser_modules.mbt`, `parser_source_file.mbt` | `audit -- modules` |
| JSX and TSX | `parser_jsx.mbt` | `audit -- jsx` |
| JSDoc | `parser_jsdoc*.mbt` | `audit -- jsdoc` |
| SourceFile, JSON, public entries | `parser_public.mbt`, `parser_pragmas.mbt`, `source_metadata.mbt` | `audit -- source public-api` |

The audit selectors and implementation files use stable domain names.

## Invocation state and speculation

Every parser call owns a private `ParserState` and `Scanner`. State includes
source and mode data, ordinary and JSDoc diagnostics, the current token,
node/identifier counts, identifier interning, active parsing contexts, context
flags, top-level state, failed-arrow caching, missing-list identity, and the
pending node-error marker.

The speculative modes have different commit rules:

- lookahead always restores scanner state, current token, diagnostic length,
  and the pending node-error marker;
- TryParse commits only a non-`None` result and otherwise restores the same
  fields;
- Reparse restores scanner state, current token, and the pending marker while
  retaining diagnostics emitted by its callback.

Callbacks must restore parser context flags themselves. Node and identifier
counts, interned strings, and failed-arrow cache entries are intentionally not
rolled back, matching TypeScript.

The general incremental-parser `currentNode`, `consumeNode`, and
`isReusable*` syntax-cursor paths are deliberately absent. The only reuse path
is the dedicated top-level-await interval reparse described below.

## Tokens, ASI, lists, and recovery

ParserState owns ordinary and JSDoc token advancement plus every
parser-context rescan. Expected/optional tokens, bracket-related information,
missing nodes, names, literals, and identifier interning preserve UTF-16
ranges and original keyword kinds. Escaped keywords are diagnosed when the
parser leaves the token.

ASI accepts an explicit semicolon, `}`, EOF, or a preceding line break. Return,
throw, break, and continue keep their line-break-sensitive operand boundaries.
The `do...while` terminator is an intentional exception: it consumes only an
explicit semicolon and does not invoke ordinary ASI.

Ordinary, delimited, and bracketed lists share TypeScript's start, terminator,
diagnostic, and delimiter rules for every parsing context. They preserve
ranges, trailing commas, enum-specific comma diagnostics, semicolon recovery,
and invocation-local missing-list identity.

Every list loop records scanner `fullStart`. If its callback makes no progress,
the loop consumes one token unless a context terminator ends the list. Nested
recovery checks all active contexts and returns without consuming a token that
belongs to an enclosing list; EOF terminates every context. After a parsed type
argument, any non-comma token retains TypeScript's ambiguity rule and
terminates the `TypeArguments` list.

Parser diagnostics preserve production order and recovery shape. Binder and
checker diagnostics are outside this package unless TypeScript itself emits
them during parsing.

## Names, signatures, and types

Entity and qualified names preserve keywords, escapes, ranges, and
right-of-dot recovery. Property names support computed, private, identifier,
keyword, string, numeric, and bigint forms. Literal and template nodes retain
scanner values, raw/cooked text, token flags, and `NodeArray` ranges.

Type parameters preserve variance/const modifiers, constraints, defaults, and
malformed expression-shaped constraints. Parameters and signatures cover
`this`, rest, optional, typed, initialized, call, construct, index, method,
property, and accessor forms with their exact list metadata.

The type grammar includes references, predicates, queries, type literals,
mapped and tuple types, function/constructor forms, literal and keyword types,
postfix arrays/indexed access, operators, `infer`, unions, intersections, and
right-associative conditionals. `DisallowConditionalTypes` is scoped at the
same infer/conditional boundaries as TypeScript.

Import types support `typeof import(...)`, qualifiers, type arguments,
`with`/compatible `assert` attributes, trailing commas, and
`"resolution-mode"`. Tuple grammar retains ambiguities that the TypeScript
checker diagnoses later; this parser does not manufacture checker-only errors.

## Expressions

Expression parsing is split by precedence and responsibility. It preserves all
binary and assignment operators, right-associative exponentiation,
`DisallowIn`, conditional-expression context changes, `as`, `satisfies`,
assertions, non-null expressions, and instantiation expressions.

Slash tokens become regexp literals only at primary-expression boundaries.
Greater tokens are rescanned for relation, shift, assignment, and type
arguments. Tagged templates rescan in tagged mode and retain raw/cooked text.

Simple, parenthesized, async, generic, and typed arrows use TypeScript's
tri-state lookahead and rollback rules. Failed non-JSX parenthesized-arrow
candidates are cached by source position. Await/yield context is scoped to the
appropriate body and restored afterward.

Primary and continuation parsing covers literals, arrays, objects, functions,
classes, calls, members, generics, templates, optional chains, dynamic import,
`import.meta`, and `new.target`. Optional-chain flags propagate through later
continuations and nested non-null expressions. Source flags for dynamic import
and import-meta are set during parsing.

## Statements and declarations

Statements include directives, blocks, conditionals, loops, jumps, labels,
`with`, switch, exception handling, debugger statements, and function bodies.
For-loop initializers share TypeScript's `DisallowIn`, await, and declaration
contexts.

Binding patterns cover object/array properties, rest, initializers, omitted
elements, computed names, and private-name rejection. Variable lists preserve
the exact `None`, `Let`, `Const`, `Using`, and `AwaitUsing` flags.

Declaration parsing covers functions, classes and class elements, interfaces,
type aliases, enums, namespaces/modules, ambient declarations, decorators,
modifiers, heritage, overloads, and parser-only fields. Declaration filenames
such as `.d.ts`, `.d.cts`, `.d.mts`, and `.d.*.ts` establish ambient context.
`ExportContext` is not synthesized where TypeScript 6.0.3 leaves it unset.

## Imports, exports, and top-level await

Imports support side effects, default/namespace/named clauses, internal and
external import-equals forms, type-only clauses, and TypeScript's `type` and
`defer` lookahead ambiguities. Named specifiers retain the full `type`/`as`
ambiguity table. Exports cover equals/default, named/star/namespace, type-only,
attributes, and `export as namespace`.

Import attributes accept `with` and compatible `assert`, preserving element
order, arbitrary assignment-expression values, multiline state, recovery,
trailing commas, and the `assertClause`/`attributes` identity alias.

The default external-module indicator is the first qualifying top-level
import/export, or the first concrete `import.meta` when the source flag permits
it. A caller policy may replace it with a node, the forced `true` sentinel, or
`None`. `impliedNodeFormat` stores only the caller-provided CommonJS or ESNext
mode and performs no package or module resolution.

For a non-declaration external module containing possible top-level await, only
marked statement intervals are reparsed under `AwaitContext`:

- statements outside those intervals retain identity;
- diagnostics outside the intervals retain order, while diagnostics inside
  are replaced;
- the existing parser state, scanner, identifier interner, and cumulative
  counts are retained;
- a reparsed statement may expand the interval if it consumes the next old
  statement;
- final parent completion covers reused and new nodes.

A fresh full second parse would violate these identity and accounting
contracts and is intentionally not used.

## JSX and TSX

JSX parsing switches the existing scanner between ordinary, JSX identifier,
attribute-value, and child-text modes. It does not create a second scanner or
normalize entity spellings. Attributes, expressions, spreads, fragments,
namespaced/property-access tag names, and whitespace-only multiline text keep
their TypeScript fields and raw values.

Recovery reattaches a closing element consumed by a mismatched child to the
parent and gives the child a zero-width closing identifier. Other mismatches
report on the closing name; EOF reports on the opening tag or fragment.
Adjacent roots use TypeScript's synthetic zero-width comma recovery.

In TSX, generic-arrow lookahead runs before JSX parsing. Arrow-specific
constraints, `const` parameters, and defaults select an arrow; tag-shaped
input selects JSX. JSX/TSX never parses angle-bracket type assertions, while
calls, tagged/member expressions, and TSX opening-element type arguments retain
their type-argument paths.

## JSDoc

Attached and isolated JSDoc parsing reuse the existing scanner. Text preserves
line asterisks, indentation, CRLF spelling, backticks, and structured inline
links. Type forms reuse the TypeScript type parser under `NodeFlags.JSDoc` and
add JSDoc-specific wrappers and Closure-style syntax.

Tag dispatch accepts upstream aliases without normalizing the stored tag name.
Nested parameter/property structures, typedefs, callbacks, overloads,
templates, imports, related information, and rollback behavior retain their
upstream shapes.

Range discovery follows TypeScript's leading-comment rule plus its trailing
exceptions. It excludes `/**/`, attaches EOF comments, and keeps the local
JSDoc-root-to-host parent even when whole-tree parent completion is disabled.

The four `JSDocParsingMode` values distinguish TS/TSX from JS/JSX. Attached
parsing saves and restores the main token and pending-error state, moves only
the appropriate diagnostics into the JSDoc channel, and truncates the main
buffer. Isolated parsing returns its diagnostics in `JsDocParseResult`; a
parsed `@deprecated` marks only its host.

## SourceFile and JSON entry behavior

`create_source_file` accepts TS, TSX, JS, JSX, and JSON plus target, parent,
JSDoc, implied-format, and module-indicator options. `parse_json_text` uses the
direct JSON entry contract; JSON passed through `create_source_file` also runs
the conversion validation and metadata initialization described in
[`architecture.md`](architecture.md).

SourceFile construction preserves identifiers, pragmas, references, comment
directives, ordinary and JSDoc diagnostics, parser counts, external-module
state, line maps, and immutable source ownership.

## Verification

Run the focused parser audits:

```sh
npm run audit -- parser
moon check --target all --deny-warn
moon test --target all
moon info
```

Full structural and corpus comparison is documented in
[`reference-and-diff.md`](reference-and-diff.md), with acceptance and stress
gates in [`validation.md`](validation.md).
