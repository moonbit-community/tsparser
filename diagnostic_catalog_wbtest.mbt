///|
test "diagnostic catalog formats standard ts templates" {
  assert_eq(format_diagnostic_message(1003, []), "Identifier expected.")
  assert_eq(format_diagnostic_message(1005, [";"]), "';' expected.")
  assert_eq(
    format_diagnostic_message(1212, ["implements"]),
    "Identifier expected. 'implements' is a reserved word in strict mode.",
  )
  assert_eq(
    format_diagnostic_message(1213, ["implements"]),
    "Identifier expected. 'implements' is a reserved word in strict mode. Class definitions are automatically in strict mode.",
  )
  assert_eq(
    format_diagnostic_message(1214, ["await"]),
    "Identifier expected. 'await' is a reserved word in strict mode. Modules are automatically in strict mode.",
  )
  assert_eq(
    format_diagnostic_message(1327, []),
    "String literal with double quotes expected.",
  )
  assert_eq(
    format_diagnostic_message(1328, []),
    "Property value can only be string literal, numeric literal, 'true', 'false', 'null', object literal or array literal.",
  )
  assert_eq(
    format_diagnostic_message(999999, []),
    "Diagnostic message missing for TS999999.",
  )
}

///|
test "expected syntax mapping stays typed" {
  let (identifier_code, identifier_args) = expected_syntax_code_and_args(
    ExpectedSyntax::Identifier,
  )
  assert_eq(identifier_code, 1003)
  assert_eq(identifier_args, [])

  let (token_code, token_args) = expected_syntax_code_and_args(
    ExpectedSyntax::Token("}"),
  )
  assert_eq(token_code, 1005)
  assert_eq(token_args, ["}"])

  let (binding_code, binding_args) = expected_syntax_code_and_args(
    ExpectedSyntax::BindingPattern,
  )
  assert_eq(binding_code, 1180)
  assert_eq(binding_args, [])
}

///|
test "json diagnostics use standard ts codes" {
  let invalid_value = parse_json_text("oops")
  guard invalid_value.parse_errors
    is [
      Diagnostic(error_code=1005, ..),
      Diagnostic(error_code=1136, ..),
      Diagnostic(error_code=1005, ..),
    ] else {
    fail("invalid json root should use standard object-literal diagnostics")
  }

  let invalid_string = parse_json_text("'answer'")
  guard invalid_string.parse_errors
    is [
      Diagnostic(
        error_code=1327,
        error_msg="String literal with double quotes expected.",
        ..
      ),
    ] else {
    fail("single-quoted json string should use TS1327")
  }

  let commented_source =
    #|{
    #|  // nope
    #|  'answer': 42
    #|}
  let commented = parse_json_text(commented_source)
  guard commented.parse_errors is [Diagnostic(error_code=1327, ..)] else {
    fail(
      "json comments should be accepted while single-quoted keys still use TS1327",
    )
  }
}

///|
test "parenthesized expression fallback hides speculative binding diagnostics" {
  let source = "(1) => 2"
  let (errors, program) = parse_program(source)
  guard errors.length() > 0 else {
    fail("invalid arrow-like input should still report parse errors")
  }
  for err in errors {
    match err {
      Diagnostic(error_code=1180, ..) | Diagnostic(error_code=1181, ..) =>
        fail("speculative binding-pattern diagnostics should stay internal")
      _ => ()
    }
  }
  guard program.stmts is [{ kind: ExprStmt({ kind: Number("1"), .. }), .. }, ..] else {
    fail(
      "binding-pattern fallback should preserve the parenthesized expression parse path",
    )
  }
}
