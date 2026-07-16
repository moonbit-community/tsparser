# Architecture

This document describes the current representation and package boundaries of
`tsparser`. Historical implementation order is intentionally omitted. The
normative behavior is TypeScript 6.0.3; its exact npm version and source commit
are defined by [`scripts/upstream-config.mjs`](../scripts/upstream-config.mjs)
and [`upstream-source-manifest.json`](upstream-source-manifest.json).

## Package boundary

The root MoonBit package owns the public syntax representation:
`SyntaxKind`, flags, `Node`, `NodeArray`, diagnostics, source metadata, and the
five parser/query entry points. Scanner, parser, factory, and construction
state remain private implementation details in the same package. MoonBit file
names organize that package but do not create namespaces or runtime module
boundaries.

`tools/diff` imports the public package and is explicitly native-only because
it performs filesystem and streaming I/O. The public parser has no native-only
dependency. Ordinary MoonBit builds and tests consume only checked-in sources;
the ignored `target/` TypeScript checkout is used by explicit upstream audits.

No package-level mutable parser singleton exists. Each parse owns its scanner,
parser state, diagnostic buffers, identifier interner, and caches. Temporary
state is cleared after the completed `SourceFile` has retained the immutable
source and metadata it needs.

## Numeric and source-text representation

- `SyntaxKind` is an opaque numeric wrapper with checked conversion. Runtime
  reverse names, declaration names, and classification aliases remain separate
  tables so aliases never change the numeric identity.
- Parser and transform flags wrap MoonBit `UInt`, including the unsigned
  `0x80000000U` bit. Audits normalize JavaScript signed bitwise results before
  comparison.
- `SourceText` retains the original MoonBit `String`. Every parser position,
  diagnostic span, node range, and line/character conversion is measured in
  UTF-16 code units.
- `SourceTextRange` stores an immutable source owner and validated start/end
  offsets. Materialization is explicit and uses `unsafe_substring`, which also
  preserves lone surrogate code units.
- Valid surrogate pairs decode as one code point; lone surrogates retain their
  original code-unit values. Line maps distinguish CR, LF, CRLF, U+2028, and
  U+2029. U+0085 remains same-line whitespace.
- Comment ranges preserve source order and TypeScript's trailing-newline
  metadata.

## AST and immutable collections

`Node` is a stable reference. It deliberately has no structural `Eq`, `Show`,
or recursive `Debug` implementation because parent links form cycles.
`physical_equal` is used only when syntax-node identity is part of the
contract.

Parser-created nodes store ordered `NodeField` values with exact TypeScript
field names. `NodeFieldValue` distinguishes nodes, lists, strings, booleans,
kinds, flags, diagnostics, metadata collections, and explicit `undefined`.
Optional properties therefore keep their absent/present distinction without
lowering the AST to JSON. The older `NodePayload::Children` case is retained
only for the representation probe; parser nodes use typed fields.

Public node fields and collection elements are read-only. Private construction
code may finish ranges, flags, JSDoc, and parent links:

- unfinished parser nodes start at `0..0`; `finish_node` assigns the source
  range, inherits context flags, and consumes the pending parse-error marker;
- missing identifiers, literals, declarations, and tokens retain their real
  kind and remain zero-width at the diagnostic position;
- `NodeArray` copies mutable input storage into `ReadOnlyArray[Node]`, preserves
  element identity, and owns its range, trailing-comma bit, and aggregate
  transform flags;
- `ExternalModuleIndicator` distinguishes a concrete syntax node from the
  forced `true` sentinel, while `None` represents a non-external file;
- JSDoc content preserves the upstream `string | NodeArray | undefined` shape,
  including structured inline links.

Emit-only and transform-only synthetic kinds do not receive invented parser
payloads.

## Traversal, parent links, and queries

`for_each_child` preserves TypeScript source order and early termination. With
no list callback, ordinary `NodeArray` children are flattened through the node
callback; supplying a list callback preserves list boundaries. The two
upstream JSDoc cases that always flatten retain that exception.

Recursive traversal is iterative depth-first preorder, so deeply nested syntax
does not consume the native call stack. Node and list callbacks can continue,
skip a subtree, or stop with a value; the root itself is not reported.

Parent completion follows TypeScript's `setParentRecursive` behavior:

- ordinary children are reached through `for_each_child`;
- attached host JSDoc roots use their separate edge;
- incremental mode may skip an ordinary subtree whose parent is already
  correct, but still traverses an attached JSDoc root;
- the supplied root retains its existing parent, while statements, list
  elements, EOF, attached JSDoc, and descendants receive identity-preserving
  links.

Node queries use real UTF-16 offsets. Callers may provide a `SourceFile`
explicitly when parent completion is disabled. `first_child`, `last_child`, and
`child_count` use flattened traversal semantics; `last_child` ignores missing
nodes. `first_token` and `last_token` search parser-owned semantic descendants
and do not fabricate scanner punctuation or a service-layer `SyntaxList`.

## Public parser surface and SourceFile metadata

The public entries are:

- `create_source_file`;
- `parse_json_text`;
- `parse_isolated_entity_name`;
- `parse_isolated_jsdoc_comment`;
- `is_external_module`.

`parse_json_text` follows the direct TypeScript JSON contract and leaves
pragma/reference collections uninitialized. JSON routed through
`create_source_file` additionally runs `convertToJson` validation and
initializes those collections to empty. Both paths retain comments and trailing
commas and recover multiple top-level values through a synthetic array
expression.

Leading-comment processing recognizes triple-slash references, AMD pragmas,
line `ts-check`/`ts-nocheck` directives, and multiline JSX pragmas. Metadata
keeps source order and UTF-16 capture spans. TypeScript 6.0.3 recognizes
`no-default-lib` but does not set `hasNoDefaultLib`; this package preserves that
behavior.

All public collections are `ReadOnlyArray` values or immutable wrappers.
Compile-fail probes enforce that callers cannot assign elements or call
mutating collection operations.

## Source map and verification

The executable audits, rather than duplicated completion tables in Markdown,
are the source of truth:

| Area | Main implementation | Verification |
|---|---|---|
| kinds, flags, UTF-16, line maps | `syntax_kind*.mbt`, `flags*.mbt`, `source_text.mbt`, `text_range.mbt`, `line_map.mbt` | `audit -- syntax-kind tables` |
| AST and factory contracts | `ast_*.mbt`, `node_array.mbt`, `node_factory_*.mbt` | `audit -- factories` |
| traversal, parents, queries | `for_each_child.mbt`, `parent_links.mbt`, `node_queries.mbt` | `audit -- children` |
| SourceFile and public surface | `parser_public.mbt`, `source_metadata.mbt` | `audit -- source public-api` |

Audit selectors and implementation files use stable domain names:

```sh
npm run audit -- syntax-kind tables factories children source public-api
moon check --target all --deny-warn
moon test --target all --deny-warn
moon info --target all
```

Scanner and diagnostic behavior is documented in
[`scanner-and-diagnostics.md`](scanner-and-diagnostics.md); parser control flow
and grammar are documented in [`parser.md`](parser.md).
