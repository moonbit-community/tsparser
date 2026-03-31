# moonbit-community/tsparser

A small TypeScript parser written in MoonBit. 

## Example

```mbt check
///|
test "parse simple program" {
  let source = "let x: number = 1 + 2 * 3;"
  let (_, program) = parse_program(source)
  debug_inspect(
    program,
    content=(
      #|{
      #|  stmts: [
      #|    {
      #|      kind: VarDecl(
      #|        {
      #|          kind: Let,
      #|          decls: [
      #|            {
      #|              pattern: {
      #|                kind: Ident("x"),
      #|                span: {
      #|                  start: { offset: 4, line: 1, column: 5 },
      #|                  end: { offset: 5, line: 1, column: 6 },
      #|                },
      #|              },
      #|              type_ann: Some(
      #|                {
      #|                  kind: Ident("number"),
      #|                  span: {
      #|                    start: { offset: 7, line: 1, column: 8 },
      #|                    end: { offset: 13, line: 1, column: 14 },
      #|                  },
      #|                },
      #|              ),
      #|              init: Some(
      #|                {
      #|                  kind: Binary(
      #|                    {
      #|                      op: Add,
      #|                      left: {
      #|                        kind: Number("1"),
      #|                        span: {
      #|                          start: { offset: 16, line: 1, column: 17 },
      #|                          end: { offset: 17, line: 1, column: 18 },
      #|                        },
      #|                      },
      #|                      right: {
      #|                        kind: Binary(
      #|                          {
      #|                            op: Mul,
      #|                            left: { kind: Number("2"), span: { start: ..., end: ... } },
      #|                            right: { kind: Number("3"), span: { start: ..., end: ... } },
      #|                          },
      #|                        ),
      #|                        span: {
      #|                          start: { offset: 20, line: 1, column: 21 },
      #|                          end: { offset: 25, line: 1, column: 26 },
      #|                        },
      #|                      },
      #|                    },
      #|                  ),
      #|                  span: {
      #|                    start: { offset: 16, line: 1, column: 17 },
      #|                    end: { offset: 25, line: 1, column: 26 },
      #|                  },
      #|                },
      #|              ),
      #|              span: {
      #|                start: { offset: 4, line: 1, column: 5 },
      #|                end: { offset: 25, line: 1, column: 26 },
      #|              },
      #|            },
      #|          ],
      #|        },
      #|      ),
      #|      span: {
      #|        start: { offset: 0, line: 1, column: 1 },
      #|        end: { offset: 26, line: 1, column: 27 },
      #|      },
      #|    },
      #|  ],
      #|}
    ),
  )
}
```
