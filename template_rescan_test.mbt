///|
test "unterminated no-substitution template keeps template AST" {
  let source_file = create_source_file(
    "const value = `hello",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors
    is [
      Diagnostic(
        error_code=1160,
        error_msg="Unterminated template literal.",
        ..
      ),
    ] else {
    fail("unterminated template should report TS1160")
  }
  guard source_file.stmts
    is [
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  { kind: Template({ quasis: ["hello"], exprs: [] }), .. }
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
      "unterminated no-substitution template should still build template AST",
    )
  }
}

///|
test "unterminated template continuation keeps trailing quasi" {
  let source_file = create_source_file(
    "const value = `a${b}c",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors
    is [
      Diagnostic(
        error_code=1160,
        error_msg="Unterminated template literal.",
        ..
      ),
    ] else {
    fail("unterminated template continuation should report TS1160")
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
                    kind: Template(
                      { quasis: ["a", "c"], exprs: [{ kind: Ident("b"), .. }] }
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
    fail("template continuation should keep both quasis around the placeholder")
  }
}

///|
test "missing template placeholder expression keeps empty tail without TS1160" {
  let source_file = create_source_file(
    "const value = `a${",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors
    is [Diagnostic(error_code=1109, error_msg="Expression expected.", ..)] else {
    fail("missing template expression should only report TS1109")
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
                    kind: Template(
                      { quasis: ["a", ""], exprs: [{ kind: Ident(""), .. }] }
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
    fail("missing template expression should keep an empty trailing quasi")
  }
}

///|
test "missing template placeholder closing brace keeps empty tail" {
  let source_file = create_source_file(
    "const value = `a${b",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors
    is [Diagnostic(error_code=1005, error_msg="'}' expected.", ..)] else {
    fail("missing template closing brace should only report TS1005")
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
                    kind: Template(
                      { quasis: ["a", ""], exprs: [{ kind: Ident("b"), .. }] }
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
    fail("missing template closing brace should keep an empty trailing quasi")
  }
}

///|
test "unterminated template literal type keeps trailing quasi" {
  let source_file = create_source_file(
    "type Greeting<T> = `a${T}c",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors
    is [
      Diagnostic(
        error_code=1160,
        error_msg="Unterminated template literal.",
        ..
      ),
    ] else {
    fail("unterminated template literal type should report TS1160")
  }
  guard source_file.stmts
    is [
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: TemplateLiteral(
                { quasis: ["a", "c"], types: [{ kind: Ident("T"), .. }] }
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail("template literal type should preserve its trailing quasi at EOF")
  }
}

///|
test "missing template literal type closing brace keeps empty tail" {
  let source_file = create_source_file(
    "type Greeting<T> = `a${T",
    default_parse_options("x.ts"),
  )
  guard source_file.parse_errors
    is [Diagnostic(error_code=1005, error_msg="'}' expected.", ..)] else {
    fail(
      "missing template literal type closing brace should only report TS1005",
    )
  }
  guard source_file.stmts
    is [
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: TemplateLiteral(
                { quasis: ["a", ""], types: [{ kind: Ident("T"), .. }] }
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
    ] else {
    fail(
      "missing template literal type closing brace should keep an empty tail",
    )
  }
}
