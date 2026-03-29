///|
test "parse_program uses file extension to enable tsx" {
  let source =
    #|const view = <div />
  let (errors, program) = parse_program(source, name="x.tsx")
  guard errors is [] else {
    fail("tsx source should parse without diagnostics")
  }
  guard program.stmts
    is [
      {
        kind: VarDecl(
          {
            kind: Const,
            decls: [{ init: Some({ kind: JSXElement(_), .. }), .. }],
          }
        ),
        ..,
      },
    ] else {
    fail("tsx source should produce a JSX element initializer")
  }
}

///|
test "create_source_file keeps ts type assertions even with jsx pragma" {
  let source =
    #|// @jsx: preserve
    #|const value = <T>y
  let source_file = create_source_file(source, default_parse_options("x.ts"))
  guard source_file.parse_errors is [] else {
    fail("ts source with jsx pragma should still parse as type assertion")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          { decls: [{ init: Some({ kind: TypeAssert(_), .. }), .. }], .. }
        ),
        ..,
      },
    ] else {
    fail("ts source should keep '<T>y' as a type assertion")
  }
}

///|
test "parse_program keeps ts type assertions even with jsx pragma" {
  let source =
    #|// @jsx: preserve
    #|const value = <T>y
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors is [] else {
    fail("ts source should not switch to tsx parsing because of jsx pragma")
  }
  guard program.stmts
    is [
      {
        kind: VarDecl(
          { decls: [{ init: Some({ kind: TypeAssert(_), .. }), .. }], .. }
        ),
        ..,
      },
    ] else {
    fail("parse_program should keep '<T>y' as a type assertion for .ts input")
  }
}

///|
test "parse_program honors virtual tsx filename markers" {
  let source =
    #|// @filename: virtual.tsx
    #|const view = <div />
  let (errors, program) = parse_program(source)
  guard errors is [] else {
    fail("virtual tsx filename marker should enable jsx parsing")
  }
  guard program.stmts
    is [
      {
        kind: VarDecl(
          {
            kind: Const,
            decls: [{ init: Some({ kind: JSXElement(_), .. }), .. }],
          }
        ),
        ..,
      },
    ] else {
    fail("virtual tsx filename marker should preserve JSX parsing")
  }
}

///|
test "parse_program treats jsx syntax as jsx in js files" {
  let source =
    #|const view = <div />
  let (errors, program) = parse_program(source, name="x.js")
  guard errors is [] else {
    fail("js input with jsx syntax should parse without diagnostics")
  }
  guard program.stmts
    is [
      {
        kind: VarDecl(
          {
            kind: Const,
            decls: [{ init: Some({ kind: JSXElement(_), .. }), .. }],
          }
        ),
        ..,
      },
    ] else {
    fail("js input should build a JSX element instead of a type assertion")
  }
}

///|
test "create_source_file ignores alwaysStrict pragma for parser strict mode" {
  let source =
    #|// @alwaysStrict: true
    #|with (x) {}
  let source_file = create_source_file(source, default_parse_options("x.ts"))
  guard source_file.parse_errors is [] else {
    fail("alwaysStrict pragma should not force strict parse mode")
  }
  guard source_file.stmts
    is [
      {
        kind: With(
          { object: { kind: Ident("x"), .. }, body: { kind: Block(_), .. } }
        ),
        ..,
      },
    ] else {
    fail("with statement should be preserved as With AST")
  }
}

///|
test "debugger parses as debugger statement" {
  let source_file = create_source_file(
    "debugger;",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors is [] else {
    fail("debugger statement should parse without diagnostics")
  }
  guard source_file.stmts is [{ kind: Debugger, .. }] else {
    fail("debugger statement should not fall back to an expression statement")
  }
}

///|
test "using declarations become variable statements" {
  let source =
    #|using x = foo();
  let source_file = create_source_file(source, default_parse_options("x.ts"))
  guard source_file.parse_errors is [] else {
    fail("using declaration should parse without diagnostics")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          {
            kind: Using,
            decls: [
              {
                pattern: { kind: Ident("x"), .. },
                init: Some({ kind: Call(_), .. }),
                ..,
              },
            ],
          }
        ),
        ..,
      },
    ] else {
    fail("using declaration should be modeled as a variable statement")
  }
}

///|
test "await using declarations become variable statements" {
  let source =
    #|await using resource = foo();
  let source_file = create_source_file(source, default_parse_options("x.ts"))
  guard source_file.parse_errors is [] else {
    fail("await using declaration should parse without diagnostics")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          {
            kind: AwaitUsing,
            decls: [
              {
                pattern: { kind: Ident("resource"), .. },
                init: Some({ kind: Call(_), .. }),
                ..,
              },
            ],
          }
        ),
        ..,
      },
    ] else {
    fail("await using declaration should be modeled as a variable statement")
  }
}

///|
test "source file preserves comments and directives" {
  let source =
    #|/** doc */
    #|// @ts-ignore
    #|const x = 1
  let source_file = create_source_file(source, default_parse_options("x.ts"))
  guard source_file.comments is [{ kind: JsDoc, .. }, { kind: Line, .. }] else {
    fail("source file should retain raw comment ranges")
  }
  guard source_file.comment_directives is [{ kind: TsIgnore, .. }] else {
    fail("source file should retain ts-ignore directives")
  }
}

///|
test "source file can disable jsdoc collection" {
  let source =
    #|/** doc */
    #|const x = 1
  let source_file = create_source_file(
    source,
    default_parse_options_without_jsdoc("x.ts"),
  )
  guard source_file.comments is [{ kind: Block, .. }] else {
    fail("ParseNone should keep jsdoc comments as plain block comments")
  }
}

///|
test "block comments do not mark files as external modules" {
  let source =
    #|/*
    #|export {}
    #|*/
    #|let x = 1
  let source_file = create_source_file(source, default_parse_options("x.ts"))
  guard source_file.parse_errors is [] else {
    fail("commented export should not introduce diagnostics")
  }
  guard !source_file.external_module_indicator else {
    fail("commented export should not mark the file as an external module")
  }
  guard !source_file.strict_mode else {
    fail(
      "non-module file should not become strict because of a commented export",
    )
  }
}

///|
test "source file preserves comments inside template substitutions" {
  let source =
    #|const value = `a${/* @ts-ignore */ foo}`
  let source_file = create_source_file(source, default_parse_options("x.ts"))
  guard source_file.comments is [{ kind: Block, text, .. }] else {
    fail("template substitutions should retain block comments")
  }
  guard text.contains("@ts-ignore") else {
    fail("template substitution comment text should be preserved")
  }
  guard source_file.comment_directives is [{ kind: TsIgnore, .. }] else {
    fail(
      "template substitution comments should still produce ts-ignore directives",
    )
  }
}

///|
test "regex literals do not synthesize block comments" {
  let source =
    #|const value = /a\/*keep*/;
  let source_file = create_source_file(source, default_parse_options("x.ts"))
  guard source_file.parse_errors is [] else {
    fail("regex literal should parse without diagnostics")
  }
  guard source_file.comments is [] else {
    fail("regex literal contents should not be collected as comments")
  }
}

///|
test "parse_isolated_entity_name parses qualified names" {
  let (errors, entity_name) = parse_isolated_entity_name(
    "Foo.Bar.Baz",
    default_parse_options("x.ts"),
  )
  guard errors is [] else {
    fail("isolated entity name parsing should not produce diagnostics")
  }
  guard entity_name is Some("Foo.Bar.Baz") else {
    fail("isolated entity name helper should keep the full qualified name")
  }
}

///|
test "parse_isolated_type_expression parses standalone type nodes" {
  let (errors, type_expr) = parse_isolated_type_expression(
    "Array<Foo | Bar>",
    default_parse_options("x.ts"),
  )
  guard errors is [] else {
    fail("isolated type parsing should not produce diagnostics")
  }
  guard type_expr
    is Some(
      {
        kind: Generic(
          { kind: Ident("Array"), .. },
          [
            {
              kind: Union(
                [{ kind: Ident("Foo"), .. }, { kind: Ident("Bar"), .. }]
              ),
              ..,
            },
          ]
        ),
        ..,
      }
    ) else {
    fail("isolated type helper should preserve the standalone type AST")
  }
}

///|
test "parse_isolated_type_expression reports trailing tokens" {
  let (errors, type_expr) = parse_isolated_type_expression(
    "Foo; Bar",
    default_parse_options("x.ts"),
  )
  guard type_expr is Some({ kind: Ident("Foo"), .. }) else {
    fail(
      "isolated type helper should still return the parsed leading type node",
    )
  }
  guard errors.length() > 0 else {
    fail("isolated type helper should reject trailing tokens")
  }
}

///|
test "parse_isolated_jsdoc_comment parses standalone jsdoc" {
  let (errors, jsdoc_comment) = parse_isolated_jsdoc_comment(
    "/** @type {Foo} */",
    default_parse_options("x.ts"),
  )
  guard errors is [] else {
    fail("isolated jsdoc parsing should not produce diagnostics")
  }
  guard jsdoc_comment is Some({ kind: JsDoc, text, .. }) else {
    fail("isolated jsdoc helper should return the jsdoc comment range")
  }
  guard text.contains("@type {Foo}") else {
    fail("isolated jsdoc helper should preserve the raw comment text")
  }
}

///|
test "parse_isolated_jsdoc_comment reports trailing tokens" {
  let (errors, jsdoc_comment) = parse_isolated_jsdoc_comment(
    "/** @type {Foo} */ const value = 1",
    default_parse_options("x.ts"),
  )
  guard jsdoc_comment is Some({ kind: JsDoc, .. }) else {
    fail("isolated jsdoc helper should still return the parsed leading comment")
  }
  guard errors.length() > 0 else {
    fail("isolated jsdoc helper should reject trailing tokens")
  }
}

///|
test "parse_isolated_jsdoc_comment respects ParseNone" {
  let (errors, jsdoc_comment) = parse_isolated_jsdoc_comment(
    "/** @type {Foo} */",
    default_parse_options_without_jsdoc("x.ts"),
  )
  guard errors is [] else {
    fail("disabled jsdoc parsing should not introduce diagnostics")
  }
  guard jsdoc_comment is None else {
    fail("disabled jsdoc parsing should not surface jsdoc comment ranges")
  }
}

///|
test "parse_json_text parses structured root values" {
  let source =
    #|{
    #|  "answer": 42,
    #|  "items": [true, null, -3]
    #|}
  let source_file = parse_json_text(source)
  guard source_file.parse_errors is [] else {
    fail("json root value should parse without diagnostics")
  }
  guard source_file.stmts
    is [
      {
        kind: ExprStmt(
          {
            kind: Object(
              {
                props: [
                  Property(
                    { name: "answer", value: { kind: Number("42"), .. }, .. }
                  ),
                  Property(
                    {
                      name: "items",
                      value: {
                        kind: Array(
                          [
                            Expr({ kind: Bool(true), .. }),
                            Expr({ kind: Null, .. }),
                            Expr(
                              {
                                kind: Unary(
                                  { op: Minus, expr: { kind: Number("3"), .. } }
                                ),
                                ..,
                              }
                            ),
                          ]
                        ),
                        ..,
                      },
                      ..,
                    }
                  ),
                ],
              }
            ),
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail("json root should stay as a structured object expression")
  }
}

///|
test "parse_json_text preserves leading root before trailing tokens" {
  let source =
    #|{"answer": 42} true
  let source_file = parse_json_text(source)
  guard source_file.stmts
    is [
      {
        kind: ExprStmt(
          { kind: Object({ props: [Property({ name: "answer", .. })] }), .. }
        ),
        ..,
      },
    ] else {
    fail("json parser should keep the leading root value AST")
  }
  guard source_file.parse_errors.length() > 0 else {
    fail("trailing json tokens should still report diagnostics")
  }
}

///|
test "parse_json_text rejects comments and single-quoted strings" {
  let source =
    #|{
    #|  // nope
    #|  'answer': 42
    #|}
  let source_file = parse_json_text(source)
  guard source_file.stmts is [{ kind: ExprStmt({ kind: Object(_), .. }), .. }] else {
    fail(
      "json parser should still build the root object for recoverable errors",
    )
  }
  guard source_file.comments is [{ kind: Line, .. }] else {
    fail("json source file should still retain raw comment ranges")
  }
  guard source_file.parse_errors.length() >= 2 else {
    fail("json parser should reject both comments and single-quoted strings")
  }
}

///|
test "adjacent right shift tokens still parse as a shift operator" {
  let source_file = create_source_file(
    "const value = a >> b",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors is [] else {
    fail("adjacent >> should parse without diagnostics")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          {
            decls: [{ init: Some({ kind: Binary({ op: Shr, .. }), .. }), .. }],
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail("adjacent >> should produce a Shr binary expression")
  }
}

///|
test "spaced greater-than tokens are not rescanned as a shift operator" {
  let source_file = create_source_file(
    "const value = a > > b",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors.length() > 0 else {
    fail("spaced > > should not parse as a valid shift expression")
  }
  guard source_file.stmts
    is [{ kind: VarDecl({ decls: [{ init: Some(init), .. }], .. }), .. }] else {
    fail("parser should still recover a variable initializer")
  }
  if init.kind is Binary({ op: Shr, .. }) {
    fail("spaced > > should not be merged into >>")
  }
  if init.kind is Binary({ op: UShr, .. }) {
    fail("spaced > > should not be merged into >>>")
  }
}

///|
test "spaced less-than tokens are not rescanned as a left shift operator" {
  let source_file = create_source_file(
    "const value = a < < b",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors.length() > 0 else {
    fail("spaced < < should not parse as a valid shift expression")
  }
  guard source_file.stmts
    is [{ kind: VarDecl({ decls: [{ init: Some(init), .. }], .. }), .. }] else {
    fail("parser should still recover a variable initializer")
  }
  if init.kind is Binary({ op: Shl, .. }) {
    fail("spaced < < should not be merged into <<")
  }
}

///|
test "adjacent bitwise-or assignment tokens still parse as assignment" {
  let source_file = create_source_file(
    "value |= next",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors is [] else {
    fail("adjacent |= should parse without diagnostics")
  }
  guard source_file.stmts
    is [{ kind: ExprStmt({ kind: Assign({ op: BitOrAssign, .. }), .. }), .. }] else {
    fail("adjacent |= should produce a BitOrAssign assignment")
  }
}

///|
test "spaced bitwise-or assignment tokens are not rescanned as assignment" {
  let source_file = create_source_file(
    "value | = next",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors.length() > 0 else {
    fail("spaced | = should not parse as a valid |= assignment")
  }
  guard source_file.stmts is [{ kind: ExprStmt(expr), .. }] else {
    fail("parser should still recover an expression statement")
  }
  if expr.kind is Assign({ op: BitOrAssign, .. }) {
    fail("spaced | = should not be merged into |=")
  }
}

///|
test "slash-equals token can be rescanned as a regex literal" {
  let source_file = create_source_file(
    "const matcher = /=foo/g",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors is [] else {
    fail("/=foo/g should parse as a regex literal in expression position")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          { decls: [{ init: Some({ kind: String("/regex/"), .. }), .. }], .. }
        ),
        ..,
      },
    ] else {
    fail("regex literal starting with '=' should stay in the initializer")
  }
}

///|
test "slash-equals still parses as division assignment outside regex context" {
  let source_file = create_source_file(
    "value /= next",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors is [] else {
    fail("division assignment should parse without diagnostics")
  }
  guard source_file.stmts
    is [{ kind: ExprStmt({ kind: Assign({ op: DivAssign, .. }), .. }), .. }] else {
    fail(
      "/= should still parse as a division assignment when a lhs already exists",
    )
  }
}

///|
test "nullish assignment still depends on adjacency" {
  let merged = create_source_file(
    "value ??= next",
    default_parse_options("x.ts"),
  )
  guard merged.parse_errors is [] else {
    fail("adjacent ??= should parse without diagnostics")
  }
  guard merged.stmts
    is [{ kind: ExprStmt({ kind: Assign({ op: NullishAssign, .. }), .. }), .. }] else {
    fail("adjacent ??= should still parse as an assignment expression")
  }

  let spaced = create_source_file(
    "value ?? = next",
    default_parse_options("x.ts"),
  )
  guard spaced.parse_errors.length() > 0 else {
    fail("spaced ?? = should not be rescanned as ??=")
  }
  guard spaced.stmts is [{ kind: ExprStmt(expr), .. }] else {
    fail("parser should still recover an expression statement for spaced ?? =")
  }
  if expr.kind is Assign({ op: Assign, .. }) {
    fail("spaced ?? = should not be merged into an assignment operator")
  }
}

///|
test "optional chaining still depends on adjacency" {
  let merged = create_source_file(
    "const value = obj?.prop",
    default_parse_options("x.ts"),
  )
  guard merged.parse_errors is [] else {
    fail("adjacent ?. should parse without diagnostics")
  }
  guard merged.stmts
    is [
      {
        kind: VarDecl(
          {
            decls: [
              { init: Some({ kind: Member({ optional: true, .. }), .. }), .. },
            ],
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail("adjacent ?. should produce an optional member access")
  }

  let spaced = create_source_file(
    "const value = obj ? .prop : fallback",
    default_parse_options("x.ts"),
  )
  guard spaced.parse_errors.length() > 0 else {
    fail("spaced ? . should not be rescanned as optional chaining")
  }
  guard spaced.stmts
    is [{ kind: VarDecl({ decls: [{ init: Some(init), .. }], .. }), .. }] else {
    fail("parser should still recover a variable initializer for spaced ? .")
  }
  if init.kind is Member({ optional: true, .. }) {
    fail("spaced ? . should not become an optional member access")
  }
}

///|
test "conditional types can use mapped types with readonly removal" {
  let (errors, type_expr) = parse_isolated_type_expression(
    "T extends Function ? T : { -readonly [K in keyof T]: T[K] }",
    default_parse_options("x.ts"),
  )
  guard errors is [] else {
    fail("mapped type readonly removal should parse without diagnostics")
  }
  guard type_expr
    is Some(
      {
        kind: Conditional(
          _,
          _,
          _,
          { kind: MappedType({ readonly_modifier: Some(Remove), .. }), .. }
        ),
        ..,
      }
    ) else {
    fail("conditional false branch should preserve the mapped type modifier")
  }
}

///|
test "invalid import attribute entry reports ts1478" {
  let source =
    #|import("pkg", { assert: {1234, "resolution-mode": "require"} }).RequireInterface
  let (errors, _) = parse_isolated_type_expression(
    source,
    default_parse_options("x.ts"),
  )
  let mut saw_invalid_attr_entry = false
  for err in errors {
    if err is Diagnostic(error_code=1478, ..) {
      saw_invalid_attr_entry = true
    }
  }
  guard saw_invalid_attr_entry else {
    fail("numeric import attribute entries should report TS1478")
  }
}

///|
test "jsx text reports bare greater-than tokens" {
  let source_file = create_source_file(
    "const view = <div>></div>",
    default_parse_options("x.tsx"),
  )
  let mut saw_unescaped_gt = false
  for err in source_file.parse_errors {
    if err is Diagnostic(error_code=1382, ..) {
      saw_unescaped_gt = true
    }
  }
  guard saw_unescaped_gt else {
    fail("bare '>' in JSX text should report TS1382")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  {
                    kind: JSXElement(
                      {
                        name: "div",
                        children: [Text(">")],
                        closing_name: Some("div"),
                        ..,
                      }
                    ),
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail("jsx text with bare '>' should still build a structured JSX element")
  }
}

///|
test "jsx text reports bare closing-brace tokens" {
  let source_file = create_source_file(
    "const view = <div>}</div>",
    default_parse_options("x.tsx"),
  )
  let mut saw_unescaped_rbrace = false
  for err in source_file.parse_errors {
    if err is Diagnostic(error_code=1381, ..) {
      saw_unescaped_rbrace = true
    }
  }
  guard saw_unescaped_rbrace else {
    fail("bare '}' in JSX text should report TS1381")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  {
                    kind: JSXElement(
                      {
                        name: "div",
                        children: [Text("}")],
                        closing_name: Some("div"),
                        ..,
                      }
                    ),
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail("jsx text with bare '}' should still build a structured JSX element")
  }
}

///|
test "mismatched nested jsx closing tags stay structured" {
  let source_file = create_source_file(
    "const view = <div><span></div>",
    default_parse_options("x.tsx"),
  )
  let mut saw_missing_span_close = false
  for err in source_file.parse_errors {
    if err is Diagnostic(error_code=17008, ..) {
      saw_missing_span_close = true
    }
  }
  guard saw_missing_span_close else {
    fail("mismatched nested JSX closing tags should report TS17008")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  {
                    kind: JSXElement(
                      {
                        name: "div",
                        children: [
                          Element(
                            {
                              kind: JSXElement(
                                { name: "span", self_closing: false, .. }
                              ),
                              ..,
                            }
                          ),
                        ],
                        closing_name: Some("div"),
                        ..,
                      }
                    ),
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail(
      "mismatched nested JSX closing tags should keep a structured outer/inner JSX tree",
    )
  }
}
