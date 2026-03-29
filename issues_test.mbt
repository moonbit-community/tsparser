///|
test "`...` in arrow parameter should emit TS1003" {
  let source =
    #|(...) => {} 
  guard parse_program(source).0[0]
    is Diagnostic(error_code=1003, error_msg="Identifier expected.", ..) else {
    fail("parse '\{source}' should emit TS1003")
  }
}

///|
test "ambient implementations are deferred beyond parser" {
  let cases = [
    "declare function f() {}", "declare class C { constructor() {} }", "declare class C { m() {} }",
    "declare class C { get x() { return 1 } }", "declare namespace N { function f() {} }",
    "declare class C { static {} }",
  ]
  for source in cases {
    let (errors, _) = parse_program(source, name="x.ts")
    guard errors is [] else {
      fail("parse '\{source}' should not emit parser diagnostics")
    }
  }
}

///|
test "nested declare modifiers are deferred beyond parser" {
  let cases = [
    "declare namespace N { declare const x: number; }", "declare namespace N { declare class C {} }",
    "declare namespace N { declare function f(); }",
  ]
  for source in cases {
    let (errors, _) = parse_program(source, name="x.ts")
    guard errors is [] else {
      fail("parse '\{source}' should not emit parser diagnostics")
    }
  }
}

///|
test "interface method bodies still use ordinary parse errors" {
  let source =
    #|interface I { m(): void {} }
  let (errors, _) = parse_program(source, name="x.ts")
  guard errors
    is [
      Diagnostic(error_code=1005, error_msg="';' expected.", ..),
      Diagnostic(
        error_code=1128,
        error_msg="Declaration or statement expected.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should keep the standard parse-error recovery path")
  }
}

///|
test "type literal method bodies still use ordinary parse errors" {
  let source =
    #|type T = { m(): void {} }
  let (errors, _) = parse_program(source, name="x.ts")
  guard errors
    is [
      Diagnostic(error_code=1005, error_msg="';' expected.", ..),
      Diagnostic(
        error_code=1128,
        error_msg="Declaration or statement expected.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should keep the standard parse-error recovery path")
  }
}

///|
test "untyped interface property initializers still use ordinary parse errors" {
  let source =
    #|interface I { x = 1 }
  let (errors, _) = parse_program(source, name="x.ts")
  guard errors
    is [
      Diagnostic(
        error_code=1131,
        error_msg="Property or signature expected.",
        ..
      ),
      Diagnostic(
        error_code=1128,
        error_msg="Declaration or statement expected.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should recover like the official parser")
  }
}

///|
test "untyped type literal property initializers still use ordinary parse errors" {
  let source =
    #|type T = { x = 1 }
  let (errors, _) = parse_program(source, name="x.ts")
  guard errors
    is [
      Diagnostic(
        error_code=1131,
        error_msg="Property or signature expected.",
        ..
      ),
      Diagnostic(
        error_code=1128,
        error_msg="Declaration or statement expected.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should recover like the official parser")
  }
}

///|
test "typed interface property initializers are deferred beyond parser" {
  let source =
    #|interface I { x: number = 1 }
  let (errors, _) = parse_program(source, name="x.ts")
  guard errors is [] else {
    fail("parse '\{source}' should not emit parser diagnostics")
  }
}

///|
test "typed type literal property initializers are deferred beyond parser" {
  let source =
    #|type T = { x: number = 1 }
  let (errors, _) = parse_program(source, name="x.ts")
  guard errors is [] else {
    fail("parse '\{source}' should not emit parser diagnostics")
  }
}

///|
test "class member implementation checks are deferred beyond parser" {
  let cases = [
    "class C { constructor() }", "class C { constructor(); }", "class C { m(): void }",
    "class C { m(): void; }", "class C { get x(): number }", "class C { get x(): number; }",
    "class C { set x(v: number) }", "class C { set x(v: number); }",
  ]
  for source in cases {
    let (errors, _) = parse_program(source, name="x.ts")
    guard errors is [] else {
      fail("parse '\{source}' should not emit parser diagnostics")
    }
  }
}

///|
test "abstract class-member placement checks are deferred beyond parser" {
  let cases = [
    "class C { abstract m(): void }", "class C { abstract get x(): number }", "class C { abstract set x(v: number) }",
    "class C { abstract x: number }",
  ]
  for source in cases {
    let (errors, _) = parse_program(source, name="x.ts")
    guard errors is [] else {
      fail("parse '\{source}' should not emit parser diagnostics")
    }
  }
}

///|
test "index signature grammar checks are deferred beyond parser" {
  let cases = [
    "interface I { [x?: string]: number }", "type T = { [public x: string]: number }",
    "class C { [...x: string]: number }", "interface I { [x, y: string]: number }",
    "class C { [x: string,]: number }", "type T = { [x: string] }", "interface I { public [x: string]: number }",
    "class C { [x: \"foo\"]: number }",
  ]
  for source in cases {
    let (errors, _) = parse_program(source, name="x.ts")
    guard errors is [] else {
      fail("parse '\{source}' should not emit parser diagnostics")
    }
  }
}

///|
test "statement context grammar errors are deferred beyond parser" {
  let cases = [
    "return;", "break;", "continue;", "label: { break label; }", "label: { continue label; }",
    "declare namespace N { while (0) {} }",
  ]
  for source in cases {
    let (errors, _) = parse_program(source, name="x.ts")
    guard errors is [] else {
      fail("parse '\{source}' should not emit parser diagnostics")
    }
  }
}

///|
test "invalid arrow parameter modifier should emit TS2369" {
  let source =
    #|(public foo) => {}
  guard parse_program(source).0
    is [
      Diagnostic(
        error_code=2369,
        error_msg="A parameter property is only allowed in a constructor implementation.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS2369")
  }
}

///|
test "function type parameter modifier should emit TS2369" {
  let source =
    #|declare const foo: (public bar) => baz
  guard parse_program(source).0
    is [
      Diagnostic(
        error_code=2369,
        error_msg="A parameter property is only allowed in a constructor implementation.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS2369")
  }
}

///|
test "parse_expression recovery should still collect errors" {
  let source =
    #|foo(,)
  guard parse_program(source).0[0]
    is Diagnostic(
      error_code=1135,
      error_msg="Argument expression expected.",
      ..
    ) else {
    fail("parse '\{source}' should emit TS1135")
  }
}

///|
test "undefined should be parsed as undefined type literal" {
  let source =
    #|declare const foo: undefined
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: VarDecl(
          {
            kind: Const,
            decls: [{ type_ann: Some({ kind: type_annotation_kind, .. }), .. }],
          }
        ),
        ..,
      },
    ]
  assert_true(type_annotation_kind is Literal(Undefined))
}

///|
test "yield* should not be parsed as yield" {
  let source =
    #|function* foo() { yield* bar }
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: FunctionDecl(
          {
            body: {
              stmts: [
                {
                  kind: ExprStmt({ kind: Unary({ op: operation, .. }), .. }),
                  ..,
                },
              ],
              ..,
            },
            ..,
          }
        ),
        ..,
      },
    ]
  assert_true(operation is YieldStar)
}

///|
test "empty element access should emit TS1011" {
  let source =
    #|foo[]
  guard parse_program(source).0
    is [
      Diagnostic(
        error_code=1011,
        error_msg="An element access expression should take an argument.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS1011")
  }
}

///|
test "empty template interpolation should emit TS1109" {
  let source =
    #|`${}`
  guard parse_program(source).0
    is [Diagnostic(error_code=1109, error_msg="Expression expected.", ..)] else {
    fail("parse '\{source}' should emit TS1109")
  }
}

///|
test "misplaced rest parameter should emit TS1014" {
  let source =
    #|function foo(...bar, baz) {}
  guard parse_program(source).0
    is [
      Diagnostic(
        error_code=1014,
        error_msg="A rest parameter must be last in a parameter list.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS1014")
  }
}

///|
test "abstract new type should require parenthesized parameters" {
  let source =
    #|type foo = abstract new bar
  guard parse_program(source).0
    is [Diagnostic(error_code=1005, error_msg="'(' expected.", ..)] else {
    fail("parse '\{source}' should emit TS1005")
  }
}

///|
test "function type generic parameters should be preserved" {
  let source =
    #|type foo = <T>(_: T) => T
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: GenericFunction([{ name: type_parameter_name, .. }], _, _),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
    ]
  assert_eq(type_parameter_name, "T")
}

///|
test "function type parameters should preserve pattern optional and rest info" {
  let source =
    #|type foo = (bar?: baz, ...daz: fred[]) => quux
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  assert_true(
    program.stmts
    is [
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: Function(
                [
                  {
                    pattern: { kind: Ident("bar"), .. },
                    optional: true,
                    is_rest: false,
                    ..,
                  },
                  {
                    pattern: { kind: Ident("daz"), .. },
                    optional: false,
                    is_rest: true,
                    ..,
                  },
                ],
                _
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
    ],
  )
}

///|
test "untyped rest parameter in function type should infer any[]" {
  let source =
    #|type foo = (...baz) => daz
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  assert_true(
    program.stmts
    is [
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: Function(
                [
                  {
                    pattern: { kind: Ident("baz"), .. },
                    optional: false,
                    is_rest: true,
                    type_ann: Some(
                      { kind: Array({ kind: Ident("any"), .. }), .. }
                    ),
                    ..,
                  },
                ],
                _
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
    ],
  )
}

///|
test "adjacent expression statements without semicolon separate should emit TS1005" {
  let source =
    #|1 1 4 5 1 4
  guard parse_program(source).0[0]
    is Diagnostic(error_code=1005, error_msg="';' expected.", ..) else {
    fail("parse '\{source}' should emit TS1005")
  }
}

///|
test "numeric literal member access should emit TS1351" {
  let source =
    #|0.foo
  guard parse_program(source).0
    is [
      Diagnostic(
        line=1,
        column=3,
        error_code=1351,
        error_msg="An identifier or keyword cannot immediately follow a numeric literal.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS1351")
  }
}

///|
test "escaped keywords still tokenize as keywords and emit TS1260" {
  let source =
    #|cl\u0061ss C {}
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors
    is [
      Diagnostic(
        error_code=1260,
        error_msg="Keywords cannot contain escape characters.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS1260")
  }
  guard program.stmts is [{ kind: ClassDecl({ name: Some("C"), .. }), .. }] else {
    fail("escaped class keyword should still parse as a class declaration")
  }
}

///|
test "consecutive numeric separators should emit TS6189" {
  let source =
    #|const value = 1__0
  guard parse_program(source, name="x.ts").0
    is [
      Diagnostic(
        error_code=6189,
        error_msg="Multiple consecutive numeric separators are not permitted.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS6189")
  }
}

///|
test "trailing numeric separators should emit TS6188" {
  let source =
    #|const value = 1_
  guard parse_program(source, name="x.ts").0
    is [
      Diagnostic(
        error_code=6188,
        error_msg="Numeric separators are not allowed here.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS6188")
  }
}

///|
test "prefix numeric separators should emit TS6188" {
  let source =
    #|const value = 0x_FF
  guard parse_program(source, name="x.ts").0
    is [
      Diagnostic(
        error_code=6188,
        error_msg="Numeric separators are not allowed here.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS6188")
  }
}

///|
test "exponent numeric separators should emit TS6188" {
  let source =
    #|const value = 1e_1
  guard parse_program(source, name="x.ts").0
    is [
      Diagnostic(
        error_code=6188,
        error_msg="Numeric separators are not allowed here.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS6188")
  }
}

///|
test "typeof import with extra token should emit TS1005" {
  let source =
    #|type foo = typeof import("bar" baz)
  guard parse_program(source).0
    is [
      Diagnostic(
        line=1,
        column=32,
        error_code=1005,
        error_msg="')' expected.",
        ..
      ),
    ] else {
    fail("parse '\\{source}' should emit TS1005 at ')' location")
  }
}

///|
test "typeof foo[] should be parsed as array of (typeof foo)" {
  let source =
    #|const foo: number = 42
    #|type bar = typeof foo[]
  let (errors, program) = parse_program(source)
  guard errors is [] else {
    fail("parse '\{source}' should not emit diagnostics")
  }
  guard program.stmts
    is [
      {
        kind: VarDecl(
          {
            kind: Const,
            decls: [
              {
                pattern: { kind: Ident("foo"), .. },
                type_ann: Some({ kind: Ident("number"), .. }),
                init: Some({ kind: Number("42"), .. }),
                ..,
              },
            ],
          }
        ),
        ..,
      },
      {
        kind: TypeAliasDecl(
          {
            name: "bar",
            type_params: [],
            value: { kind: Array({ kind: TypeQuery("foo"), .. }), .. },
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail(
      "parse '\{source}' should treat `typeof foo[]` as `Array(TypeQuery(\"foo\"))`",
    )
  }
}

///|
test "typeof foo[baz] should not become TypeQuery(\"foo[baz]\")" {
  let source =
    #|const foo: number = 42
    #|type bar = typeof foo[baz]
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [_, { kind: TypeAliasDecl({ value: type_value, .. }), .. }] else {
    fail("parse '\\{source}' should produce a type alias declaration")
  }
  assert_true(
    type_value.kind
    is IndexAccess({ kind: TypeQuery("foo"), .. }, { kind: Ident("baz"), .. }),
  )
}

///|
test "in modifier on function type parameter list should emit TS1274" {
  let source =
    #|declare function foo<in T>(): T;
  guard parse_program(source).0
    is [
      Diagnostic(
        line=1,
        column=22,
        error_code=1274,
        error_msg="'in' modifier can only appear on a type parameter of a class, interface or type alias",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS1274")
  }
}

///|
test "in modifier on class type parameter should be represented" {
  let with_modifier_source =
    #|class Bar<in T> {}
  let without_modifier_source =
    #|class Bar<T> {}
  let (with_modifier_errors, with_modifier_program) = parse_program(
    with_modifier_source,
  )
  assert_true(with_modifier_errors is [])
  guard with_modifier_program.stmts
    is [
      {
        kind: ClassDecl(
          {
            name: Some("Bar"),
            type_params: [
              {
                name: "T",
                variance: Some(In),
                constraint: None,
                default_type: None,
                ..,
              },
            ],
            extends: None,
            implements: [],
            members: [],
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail(
      "parse '\{with_modifier_source}' should preserve 'in' variance on class type parameter",
    )
  }
  let (without_modifier_errors, without_modifier_program) = parse_program(
    without_modifier_source,
  )
  assert_true(without_modifier_errors is [])
  guard without_modifier_program.stmts
    is [
      {
        kind: ClassDecl(
          {
            name: Some("Bar"),
            type_params: [
              {
                name: "T",
                variance: None,
                constraint: None,
                default_type: None,
                ..,
              },
            ],
            extends: None,
            implements: [],
            members: [],
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail(
      "parse '\{without_modifier_source}' should keep class type parameter variance empty",
    )
  }
}

///|
test "invalid type parameter should emit TS1139 (and empty parameter list should emit TS1109)" {
  let source =
    #|declare function foo<function>();
    #|declare function foo<"bar">();
    #|declare function foo<42>(); 
  guard parse_program(source).0
    is [
      Diagnostic(
        line=1,
        column=22,
        error_code=1139,
        error_msg="Type parameter declaration expected.",
        ..
      ),
      Diagnostic(
        line=1,
        column=30,
        error_code=1003,
        error_msg="Identifier expected.",
        ..
      ),
      Diagnostic(
        line=1,
        column=32,
        error_code=1109,
        error_msg="Expression expected.",
        ..
      ),
      Diagnostic(
        line=2,
        column=22,
        error_code=1139,
        error_msg="Type parameter declaration expected.",
        ..
      ),
      Diagnostic(
        line=2,
        column=29,
        error_code=1109,
        error_msg="Expression expected.",
        ..
      ),
      Diagnostic(
        line=3,
        column=22,
        error_code=1139,
        error_msg="Type parameter declaration expected.",
        ..
      ),
      Diagnostic(
        line=3,
        column=26,
        error_code=1109,
        error_msg="Expression expected.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS1139/TS1109")
  }
}

///|
test "hard keyword should not be parsed as identifier (emit TS1212)" {
  let source =
    #|"use strict";
    #|let implements = implements;
    #|let interface = interface;
    #|let let = let;
    #|let package = package;
    #|let private = private;
    #|let protected = protected;
    #|let public = public;
    #|let static = static;
    #|let yield = yield;
  guard parse_program(source).0
    is [
      Diagnostic(
        line=2,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'implements' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=2,
        column=18,
        error_code=1212,
        error_msg="Identifier expected. 'implements' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=3,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'interface' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=3,
        column=17,
        error_code=1212,
        error_msg="Identifier expected. 'interface' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=4,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'let' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=4,
        column=11,
        error_code=1212,
        error_msg="Identifier expected. 'let' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=5,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'package' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=5,
        column=15,
        error_code=1212,
        error_msg="Identifier expected. 'package' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=6,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'private' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=6,
        column=15,
        error_code=1212,
        error_msg="Identifier expected. 'private' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=7,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'protected' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=7,
        column=17,
        error_code=1212,
        error_msg="Identifier expected. 'protected' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=8,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'public' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=8,
        column=14,
        error_code=1212,
        error_msg="Identifier expected. 'public' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=9,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'static' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=9,
        column=14,
        error_code=1212,
        error_msg="Identifier expected. 'static' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=10,
        column=5,
        error_code=1212,
        error_msg="Identifier expected. 'yield' is a reserved word in strict mode.",
        ..
      ),
      Diagnostic(
        line=10,
        column=13,
        error_code=1212,
        error_msg="Identifier expected. 'yield' is a reserved word in strict mode.",
        ..
      ),
    ] else {
    fail(
      "parse '\{source}' should emit TS1212 for all hard keywords in identifier positions",
    )
  }
}

///|
test "@pretty should not drop diagnostics" {
  let source =
    #|// @pretty: true
    #|foo(,)
  guard parse_program(source).0 is [Diagnostic(error_code=1135, ..), ..] else {
    fail("parse '\{source}' should still emit diagnostics in pretty mode")
  }
}

///|
test "async newline before bare arrow is not parsed as async arrow" {
  let source =
    #|const f = async
    #|x => x
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors is [] else {
    fail("parse '\{source}' should not emit diagnostics")
  }
  guard program.stmts
    is [
      {
        kind: VarDecl(
          { decls: [{ init: Some({ kind: Ident("async"), .. }), .. }], .. }
        ),
        ..,
      },
      { kind: ExprStmt({ kind: Arrow(_), .. }), .. },
    ] else {
    fail("newline after async should split the arrow head")
  }
}

///|
test "async newline before parenthesized arrow is not parsed as async arrow" {
  let source =
    #|const f = async
    #|(x) => x
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors is [Diagnostic(error_code=1005, error_msg="';' expected.", ..)] else {
    fail("parse '\{source}' should emit TS1005 for the missing semicolon")
  }
  guard program.stmts
    is [{ kind: VarDecl({ decls: [{ init: Some(init), .. }], .. }), .. }, ..] else {
    fail(
      "newline after async should keep the parenthesized form out of async-arrow parsing",
    )
  }
  match init.kind {
    Arrow(_) =>
      fail(
        "parenthesized arrow after a newline should not be attached to async",
      )
    _ => ()
  }
}

///|
test "async newline before generic arrow is not parsed as async arrow" {
  let source =
    #|const f = async
    #|<T>(x: T) => x
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors is [Diagnostic(error_code=1005, ..), ..] else {
    fail(
      "parse '\{source}' should report parse errors instead of building an async arrow",
    )
  }
  guard program.stmts
    is [{ kind: VarDecl({ decls: [{ init: Some(init), .. }], .. }), .. }, ..] else {
    fail("newline after async should still produce a split statement sequence")
  }
  match init.kind {
    Arrow(_) =>
      fail("generic arrow after a newline should not be attached to async")
    _ => ()
  }
}

///|
test "export type star reexport parses as type-only export" {
  let source =
    #|export type * from "m"
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors is [] else {
    fail("parse '\{source}' should not emit diagnostics")
  }
  guard program.stmts
    is [
      {
        kind: ExportDecl(
          Named(
            {
              is_type_only: true,
              specs: [{ name: "*", as_name: None, .. }],
              from: Some("m"),
            }
          )
        ),
        ..,
      },
    ] else {
    fail("export type * should stay as a type-only export declaration")
  }
}

///|
test "export type namespace reexport parses as type-only export" {
  let source =
    #|export type * as ns from "m"
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors is [] else {
    fail("parse '\{source}' should not emit diagnostics")
  }
  guard program.stmts
    is [
      {
        kind: ExportDecl(
          Named(
            {
              is_type_only: true,
              specs: [{ name: "*", as_name: Some("ns"), .. }],
              from: Some("m"),
            }
          )
        ),
        ..,
      },
    ] else {
    fail("export type * as ns should stay as a type-only export declaration")
  }
}

///|
test "decorators are preserved on exported classes" {
  let source =
    #|@dec export class C {}
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors is [] else {
    fail("parse '\{source}' should not emit diagnostics")
  }
  guard program.stmts
    is [
      {
        kind: ExportDecl(
          Declaration(
            {
              kind: ClassDecl(
                {
                  name: Some("C"),
                  decorators: [{ kind: Ident("dec"), .. }],
                  ..,
                }
              ),
              ..,
            }
          )
        ),
        ..,
      },
    ] else {
    fail("exported class declarations should retain leading decorators")
  }
}

///|
test "for-of right side still reports empty element access after using" {
  let source =
    #|for (using of of []) {}
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors
    is [
      Diagnostic(
        error_code=1011,
        error_msg="An element access expression should take an argument.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS1011")
  }
  guard program.stmts is [{ kind: ForOf(_), .. }] else {
    fail("the for-of statement should still be preserved")
  }
}

///|
test "optional chains with private identifiers should emit TS18030" {
  let source =
    #|obj?.#value
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors
    is [
      Diagnostic(
        error_code=18030,
        error_msg="An optional chain cannot contain private identifiers.",
        ..
      ),
    ] else {
    fail("parse '\{source}' should emit TS18030")
  }
  guard program.stmts
    is [
      {
        kind: ExprStmt(
          {
            kind: Member({ property: Private("value"), optional: true, .. }),
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail("optional-chain private identifier should still preserve member AST")
  }
}

///|
test "logical and exponent assignment operators keep dedicated AST ops" {
  let source =
    #|a ||= b;
    #|c &&= d;
    #|e ??= f;
    #|g **= h;
  let (errors, program) = parse_program(source, name="x.ts")
  guard errors is [] else {
    fail("parse '\{source}' should not emit diagnostics")
  }
  guard program.stmts
    is [
      { kind: ExprStmt({ kind: Assign({ op: LogicalOrAssign, .. }), .. }), .. },
      { kind: ExprStmt({ kind: Assign({ op: LogicalAndAssign, .. }), .. }), .. },
      { kind: ExprStmt({ kind: Assign({ op: NullishAssign, .. }), .. }), .. },
      { kind: ExprStmt({ kind: Assign({ op: PowAssign, .. }), .. }), .. },
    ] else {
    fail("assignment operators should not be collapsed to plain '=' or '*='")
  }
}
