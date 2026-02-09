# moonbit-community/tsparser

A small TypeScript parser written in MoonBit. 

## Example

```mbt check
///|
test "parse simple program" {
  let source = "let x: number = 1 + 2 * 3;"
  let (_, program) = parse_program(source)
  inspect(program.stmts.length(), content="1")
}
```
