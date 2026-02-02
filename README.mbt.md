# moonbit-community/tsparser

A small TypeScript parser written in MoonBit. It currently supports a focused
subset of the language: imports/exports (including export default), classes
(extends/implements, modifiers, fields, methods, getters/setters), enums,
variable declarations, function declarations, type aliases, interfaces,
block/return/if/while/for/do-while/switch/try/throw/break/continue statements,
expressions (calls/members with optional chaining, nullish coalescing, arrow
functions, object/array literals with spread, template literals, new, type
assertions, unary/binary/conditional, update and compound assignment), binding
patterns (object/array destructuring with rest), type-only imports/exports, and
type annotations (union/intersection/tuple/object/literal/array/generic/function
types) with type parameters on declarations.

## Example

```mbt check
///|
test "parse simple program" {
  let source = "let x: number = 1 + 2 * 3;"
  let program = parse_program(source)
  inspect(program.stmts.length(), content="1")
}
```
