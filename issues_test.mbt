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
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
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
