///|
fn _parser_test_contexts() -> Array[ParsingContext] {
  [
    ParsingContext::source_elements(),
    ParsingContext::block_statements(),
    ParsingContext::switch_clauses(),
    ParsingContext::switch_clause_statements(),
    ParsingContext::type_members(),
    ParsingContext::class_members(),
    ParsingContext::enum_members(),
    ParsingContext::heritage_clause_element(),
    ParsingContext::variable_declarations(),
    ParsingContext::object_binding_elements(),
    ParsingContext::array_binding_elements(),
    ParsingContext::argument_expressions(),
    ParsingContext::object_literal_members(),
    ParsingContext::jsx_attributes(),
    ParsingContext::jsx_children(),
    ParsingContext::array_literal_members(),
    ParsingContext::parameters(),
    ParsingContext::jsdoc_parameters(),
    ParsingContext::rest_properties(),
    ParsingContext::type_parameters(),
    ParsingContext::type_arguments(),
    ParsingContext::tuple_element_types(),
    ParsingContext::heritage_clauses(),
    ParsingContext::import_or_export_specifiers(),
    ParsingContext::import_attributes(),
    ParsingContext::jsdoc_comment(),
  ]
}

///|
fn _parser_test_consume_any(state : ParserState) -> Node {
  if _parser_token_is_identifier_or_keyword(state.current_token) {
    return state._parse_identifier_name()
  }
  if state.current_token.to_int() == 9 ||
    state.current_token.to_int() == 10 ||
    state.current_token.to_int() == 11 {
    return state._parse_literal_property_name()
  }
  let pos = state._get_node_pos()
  ignore(state._next_token())
  state._finish_parser_node(_factory_create_missing_declaration(), pos)
}

///|
test "all 26 list contexts recognize representative elements and terminators" {
  let contexts = _parser_test_contexts()
  let element_texts = [
    "x", "x", "case", "x", "x", "x", "x", "x", "x", "x", "x", "x", "x", "x", "child",
    "x", "x", "x", "x", "x", "x", "x", "extends", "x", "x", "doc",
  ]
  let terminator_texts = [
    "", "}", "}", "case", "}", "}", "}", "extends", ";", "}", "]", ")", "}", ">",
    "</", "]", ")", ")", ")", ">", ">", "]", "{", "}", "}", "",
  ]
  assert_eq(contexts.length(), ParsingContext::count())
  for index in 0..<contexts.length() {
    let element = _parser_test_state(element_texts[index])
    assert_true(
      element._is_list_element(contexts[index], false),
      msg="missing representative element for context " + index.to_string(),
    )
    element._dispose()
    let terminator = _parser_test_state(terminator_texts[index])
    assert_true(
      terminator._is_list_terminator(contexts[index]),
      msg="missing representative terminator for context " + index.to_string(),
    )
    terminator._dispose()
  }
}

///|
test "list start lookahead matches declaration type and member recovery edges" {
  let cases = [
    (ParsingContext::source_elements(), "export value", false),
    (ParsingContext::source_elements(), "import(value)", true),
    (ParsingContext::source_elements(), "static value", false),
    (ParsingContext::source_elements(), "static + value", true),
    (ParsingContext::type_members(), "name + value", false),
    (ParsingContext::type_members(), "name\n+ value", true),
    (ParsingContext::class_members(), "async + value", false),
    (ParsingContext::class_members(), "readonly value", true),
    (ParsingContext::heritage_clause_element(), "implements", true),
    (ParsingContext::heritage_clause_element(), "implements Base", false),
  ]
  for item in cases {
    let (context, source, expected) = item
    let state = _parser_test_state(source)
    assert_eq(
      state._is_list_element(context, false),
      expected,
      msg="lookahead mismatch for " + source,
    )
    state._dispose()
  }
  let negative_number = _parser_test_state("-1")
  assert_true(negative_number._is_start_of_type(false))
  negative_number._dispose()
  let negative_name = _parser_test_state("-name")
  assert_false(negative_name._is_start_of_type(false))
  negative_name._dispose()
  let parenthesized = _parser_test_state("() => value")
  assert_true(parenthesized._is_start_of_type(false))
  parenthesized._dispose()
  let bad_parenthesized = _parser_test_state("(:")
  assert_false(bad_parenthesized._is_start_of_type(false))
  bad_parenthesized._dispose()
}

///|
test "all 26 parsing context diagnostics use the upstream code" {
  let expected = [
    1128, 1128, 1130, 1129, 1131, 1068, 1132, 1109, 1134, 1180, 1181, 1135, 1136,
    1003, 1003, 1137, 1138, 1138, 1131, 1139, 1140, 1110, 1179, 1003, 1478, 1003,
  ]
  for index in 0..<ParsingContext::count() {
    let state = _parser_test_state(":")
    state._report_parsing_context_error(ParsingContext(index))
    assert_eq(
      state.diagnostics[0].code(),
      expected[index],
      msg="wrong diagnostic for context " + index.to_string(),
    )
    state._dispose()
  }

  let special_cases = [
    (ParsingContext::source_elements(), "default", 1005),
    (ParsingContext::variable_declarations(), "class", 1389),
    (ParsingContext::parameters(), "class", 1390),
    (ParsingContext::import_or_export_specifiers(), "from", 1005),
  ]
  for item in special_cases {
    let (context, text, code) = item
    let state = _parser_test_state(text)
    state._report_parsing_context_error(context)
    assert_eq(state.diagnostics[0].code(), code)
    state._dispose()
  }
}

///|
test "all 26 contexts terminate at EOF and survive stalled and nested recovery" {
  let element_texts = [
    "x", "x", "case", "x", "x", "x", "x", "x", "x", "x", "x", "x", "x", "x", "child",
    "x", "x", "x", "x", "x", "x", "x", "extends", "x", "x", "doc",
  ]
  for index in 0..<ParsingContext::count() {
    let context = ParsingContext(index)
    let eof = _parser_test_state("")
    assert_true(eof._is_list_terminator(context))
    eof._dispose()

    let stalled = _parser_test_state(element_texts[index])
    let result = stalled._parse_delimited_list(context, fn() {
      Some(stalled._create_missing_parser_node(_syntax_kind(80), true))
    })
    assert_true(result is Some(_))
    assert_true(
      stalled.scanner._token_full_start() <= stalled.source_text.length(),
    )
    stalled._dispose()

    let nested = _parser_test_state("}")
    nested.parsing_context = ParsingContext::block_statements().bit() |
      context.bit()
    assert_true(nested._abort_parsing_list_or_move_to_next_token(context))
    assert_eq(nested.current_token.to_int(), 20)
    assert_eq(nested.diagnostics.length(), 1)
    nested._dispose()
  }
}

///|
test "every comma-delimited context recovers a missing separator" {
  let contexts = [
    ParsingContext::enum_members(),
    ParsingContext::heritage_clause_element(),
    ParsingContext::variable_declarations(),
    ParsingContext::object_binding_elements(),
    ParsingContext::array_binding_elements(),
    ParsingContext::argument_expressions(),
    ParsingContext::object_literal_members(),
    ParsingContext::array_literal_members(),
    ParsingContext::parameters(),
    ParsingContext::jsdoc_parameters(),
    ParsingContext::rest_properties(),
    ParsingContext::type_parameters(),
    ParsingContext::tuple_element_types(),
    ParsingContext::import_or_export_specifiers(),
    ParsingContext::import_attributes(),
  ]
  let closes = [
    "}", "{", ";", "}", "]", ")", "}", "]", ")", ")", ")", ">", "]", "}", "}",
  ]
  for index in 0..<contexts.length() {
    let state = _parser_test_state("a b" + closes[index])
    let result = state._parse_delimited_list(contexts[index], fn() {
      Some(state._parse_identifier_name())
    })
    match result {
      Some(items) => assert_eq(items.length(), 2)
      None => fail("missing separator recovery unexpectedly failed")
    }
    let expected_code = if contexts[index].to_int() == 6 { 1357 } else { 1005 }
    assert_eq(_parser_test_diagnostic_codes(state), [expected_code])
    state._dispose()
  }

  let type_arguments = _parser_test_state("a b>")
  let result = type_arguments._parse_delimited_list(
    ParsingContext::type_arguments(),
    fn() { Some(type_arguments._parse_identifier_name()) },
  )
  match result {
    Some(items) => assert_eq(items.length(), 1)
    None => fail("type argument recovery unexpectedly failed")
  }
  assert_eq(type_arguments.current_token.to_int(), 80)
  assert_eq(type_arguments.diagnostics.length(), 0)
  type_arguments._dispose()
}

///|
test "delimited lists preserve commas missing commas semicolons and enum errors" {
  let trailing = _parser_test_state("a,b,")
  let trailing_result = trailing._parse_delimited_list(
    ParsingContext::argument_expressions(),
    fn() { Some(trailing._parse_identifier()) },
  )
  match trailing_result {
    Some(items) => {
      assert_eq(items.length(), 2)
      assert_true(items.has_trailing_comma())
      assert_eq(items.pos(), 0)
      assert_eq(items.end(), 4)
    }
    None => fail("ordinary argument list unexpectedly failed")
  }
  assert_eq(trailing.current_token.to_int(), 1)
  trailing._dispose()

  let missing = _parser_test_state("a b)")
  let missing_result = missing._parse_delimited_list(
    ParsingContext::argument_expressions(),
    fn() { Some(missing._parse_identifier()) },
  )
  match missing_result {
    Some(items) => assert_eq(items.length(), 2)
    None => fail("missing-comma recovery unexpectedly failed")
  }
  assert_eq(_parser_test_diagnostic_codes(missing), [1005])
  assert_eq(missing.current_token.to_int(), 22)
  missing._dispose()

  let semicolon = _parser_test_state("a;b}")
  let semicolon_result = semicolon._parse_delimited_list(
    ParsingContext::object_literal_members(),
    fn() { Some(semicolon._parse_identifier()) },
    consider_semicolon_as_delimiter=true,
  )
  match semicolon_result {
    Some(items) => assert_eq(items.length(), 2)
    None => fail("semicolon delimiter recovery unexpectedly failed")
  }
  assert_eq(_parser_test_diagnostic_codes(semicolon), [1005])
  assert_eq(semicolon.current_token.to_int(), 20)
  semicolon._dispose()

  let enum_members = _parser_test_state("a b}")
  let enum_result = enum_members._parse_delimited_list(
    ParsingContext::enum_members(),
    fn() { Some(enum_members._parse_identifier_name()) },
  )
  match enum_result {
    Some(items) => assert_eq(items.length(), 2)
    None => fail("enum recovery unexpectedly failed")
  }
  assert_eq(_parser_test_diagnostic_codes(enum_members), [1357])
  enum_members._dispose()
}

///|
test "bracketed and missing lists retain side-table identity" {
  let bracketed = _parser_test_state("[a,b]")
  let result = bracketed._parse_bracketed_list(
    ParsingContext::tuple_element_types(),
    fn() { Some(bracketed._parse_identifier()) },
    _syntax_kind(23),
    _syntax_kind(24),
  )
  match result {
    Some(items) => {
      assert_eq(items.length(), 2)
      assert_false(bracketed._is_missing_list(items))
    }
    None => fail("bracketed list unexpectedly failed")
  }
  assert_eq(bracketed.current_token.to_int(), 1)
  bracketed._dispose()

  let absent = _parser_test_state("value")
  let missing = absent._parse_bracketed_list(
    ParsingContext::tuple_element_types(),
    fn() { Some(absent._parse_identifier()) },
    _syntax_kind(23),
    _syntax_kind(24),
  )
  match missing {
    Some(items) => {
      assert_eq(items.length(), 0)
      assert_true(absent._is_missing_list(items))
    }
    None => fail("missing bracket must produce a missing list")
  }
  assert_eq(_parser_test_diagnostic_codes(absent), [1005])
  assert_eq(absent.current_token.to_int(), 80)
  absent._dispose()
}

///|
test "list recovery detects no progress and respects nested contexts" {
  let stalled = _parser_test_state("a b")
  let items = stalled._parse_list(ParsingContext::source_elements(), fn() {
    stalled._create_missing_parser_node(_syntax_kind(80), true)
  })
  assert_eq(items.length(), 2)
  assert_eq(stalled.current_token.to_int(), 1)
  stalled._dispose()

  let nested = _parser_test_state("}")
  nested.parsing_context = ParsingContext::block_statements().bit() |
    ParsingContext::argument_expressions().bit()
  assert_true(
    nested._abort_parsing_list_or_move_to_next_token(
      ParsingContext::argument_expressions(),
    ),
  )
  assert_eq(nested.current_token.to_int(), 20)
  assert_eq(_parser_test_diagnostic_codes(nested), [1135])
  nested._dispose()
}

///|
test "arbitrary error-token streams terminate in every parsing context" {
  for context in _parser_test_contexts() {
    let state = _parser_test_state(": : : :")
    let result = state._parse_list(context, fn() {
      _parser_test_consume_any(state)
    })
    assert_true(result.length() <= 4)
    assert_true(state.scanner._token_full_start() <= state.source_text.length())
    state._dispose()
  }
}

///|
test "delimited element failure rolls back parsing-context bits" {
  let state = _parser_test_state("a")
  state.parsing_context = ParsingContext::block_statements().bit()
  let result = state._parse_delimited_list(
    ParsingContext::argument_expressions(),
    fn() -> Node? { None },
  )
  assert_true(result is None)
  assert_eq(state.parsing_context, ParsingContext::block_statements().bit())
  assert_eq(state.current_token.to_int(), 80)
  state._dispose()
}
