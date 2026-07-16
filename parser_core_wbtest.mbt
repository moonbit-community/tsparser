///|
fn _parser_test_state(
  text : String,
  script_kind? : ScriptKind = ScriptKind::ts(),
) -> ParserState {
  let state = _new_parser_state("test.ts", text, script_kind~)
  ignore(state._prime())
  state
}

///|
fn _parser_test_diagnostic_codes(state : ParserState) -> Array[Int] {
  let result : Array[Int] = []
  for diagnostic in state.diagnostics {
    result.push(diagnostic.code())
  }
  result
}

///|
test "ParserState is invocation local and dispose releases mutable input state" {
  let first = _parser_test_state("alpha")
  let second = _parser_test_state("beta", script_kind=ScriptKind::js())
  assert_eq(first.scanner._required_token_value(), "alpha")
  assert_eq(second.scanner._required_token_value(), "beta")
  assert_eq(first.context_flags.bits(), 0U)
  assert_true(second.context_flags.contains(NodeFlags::javascript_file()))
  first._intern_identifier("alpha") |> ignore
  first._record_not_parenthesized_arrow(7)
  first.node_count = 3
  first.identifier_count = 2
  ignore(first._parse_error_at_current_token(_diagnostic_message(1003)))
  assert_eq(second.diagnostics.length(), 0)
  assert_true(second.identifiers.get("alpha") is None)
  first._dispose()
  assert_false(first.active)
  assert_eq(first.file_name, "")
  assert_eq(first.source_text, "")
  assert_eq(first.current_token.to_int(), 0)
  assert_eq(first.node_count, 0)
  assert_eq(first.identifier_count, 0)
  assert_eq(first.parsing_context, 0U)
  assert_eq(first.diagnostics.length(), 0)
  assert_true(first.identifiers.get("alpha") is None)
  assert_true(first.not_parenthesized_arrow.get(7) is None)
  assert_eq(first.scanner.source.length(), 0)
  assert_true(second.active)
  second._dispose()
}

///|
test "parser token advance validates escaped keywords and JSDoc scans" {
  let escaped = _parser_test_state("\\u0069f x")
  assert_eq(escaped.current_token.to_int(), 101)
  ignore(escaped._next_token())
  assert_eq(_parser_test_diagnostic_codes(escaped), [1260])
  assert_eq(escaped.current_token.to_int(), 80)
  escaped._dispose()

  let jsdoc = _new_parser_state("doc.js", "@param x")
  assert_eq(jsdoc._next_token_jsdoc().to_int(), 60)
  assert_eq(jsdoc._next_token_jsdoc().to_int(), 80)
  assert_eq(jsdoc.scanner._required_token_value(), "param")
  jsdoc._dispose()

  let jsdoc_expected = _new_parser_state("doc.js", "@param")
  ignore(jsdoc_expected._next_token_jsdoc())
  assert_true(jsdoc_expected._parse_expected_jsdoc(_syntax_kind(60)))
  assert_eq(jsdoc_expected.current_token.to_int(), 80)
  let missing_at = jsdoc_expected._parse_expected_token_jsdoc(_syntax_kind(60))
  assert_eq(missing_at.kind().to_int(), 60)
  assert_eq(missing_at.pos(), missing_at.end())
  assert_eq(_parser_test_diagnostic_codes(jsdoc_expected), [1005])
  jsdoc_expected._dispose()
}

///|
test "parser owns every scanner rescan path" {
  let greater = _parser_test_state(">>>=")
  assert_eq(greater._re_scan_greater_token().to_int(), 73)
  assert_eq(greater.current_token.to_int(), 73)
  greater._dispose()

  let regexp = _parser_test_state("/a[\\/]b/gu")
  assert_eq(regexp._re_scan_slash_token().to_int(), 14)
  regexp._dispose()

  let less = _parser_test_state("<<")
  assert_eq(less._re_scan_less_than_token().to_int(), 30)
  less._dispose()

  let question = _parser_test_state("??")
  assert_eq(question._re_scan_question_token().to_int(), 58)
  question._dispose()

  let asterisk = _parser_test_state("*=")
  assert_eq(asterisk._re_scan_asterisk_equals_token().to_int(), 64)
  asterisk._dispose()

  let hash = _parser_test_state("#x")
  assert_eq(hash._re_scan_hash_token().to_int(), 63)
  hash._dispose()

  let template = _parser_test_state("}tail`")
  assert_eq(template._re_scan_template_token(false).to_int(), 18)
  template._dispose()

  let jsx = _new_parser_state(
    "test.tsx",
    "text<",
    script_kind=ScriptKind::tsx(),
  )
  assert_eq(jsx._scan_jsx_text().to_int(), 12)
  jsx._dispose()

  let jsx_rescan = _parser_test_state("text<", script_kind=ScriptKind::tsx())
  assert_eq(jsx_rescan._re_scan_jsx_text().to_int(), 12)
  jsx_rescan._dispose()

  let jsx_name = _parser_test_state("data-id", script_kind=ScriptKind::tsx())
  assert_eq(jsx_name._scan_jsx_identifier().to_int(), 80)
  assert_eq(jsx_name.scanner._required_token_value(), "data-id")
  jsx_name._dispose()

  let jsx_attribute = _parser_test_state(
    "\"a\\n\"",
    script_kind=ScriptKind::tsx(),
  )
  assert_eq(jsx_attribute._re_scan_jsx_attribute_value().to_int(), 11)
  assert_eq(jsx_attribute.scanner._required_token_value(), "a\\n")
  jsx_attribute._dispose()
}

///|
test "lookahead tryParse and reparse have exact rollback boundaries" {
  let lookahead = _parser_test_state("a b")
  let looked : Int? = lookahead._look_ahead(fn() -> Int? {
    ignore(lookahead._next_token())
    lookahead.node_count += 1
    lookahead.identifier_count += 1
    ignore(lookahead._intern_identifier("speculative"))
    lookahead._record_not_parenthesized_arrow(11)
    ignore(lookahead._parse_error_at_current_token(_diagnostic_message(1003)))
    Some(lookahead.current_token.to_int())
  })
  assert_eq(looked, Some(80))
  assert_eq(lookahead.current_token.to_int(), 80)
  assert_eq(lookahead.scanner._token_start(), 0)
  assert_eq(lookahead.diagnostics.length(), 0)
  assert_false(lookahead.finish_state._has_pending_parse_error())
  assert_eq(lookahead.node_count, 1)
  assert_eq(lookahead.identifier_count, 1)
  assert_eq(lookahead.identifiers.get("speculative"), Some("speculative"))
  assert_eq(lookahead.not_parenthesized_arrow.get(11), Some(true))

  let failed : Int? = lookahead._try_parse(fn() -> Int? {
    ignore(lookahead._next_token())
    ignore(lookahead._parse_error_at_current_token(_diagnostic_message(1003)))
    None
  })
  assert_true(failed is None)
  assert_eq(lookahead.scanner._token_start(), 0)
  assert_eq(lookahead.diagnostics.length(), 0)

  let committed : Int? = lookahead._try_parse(fn() -> Int? {
    ignore(lookahead._next_token())
    ignore(lookahead._parse_error_at_current_token(_diagnostic_message(1003)))
    Some(7)
  })
  assert_eq(committed, Some(7))
  assert_eq(lookahead.scanner._token_start(), 2)
  assert_eq(lookahead.diagnostics.length(), 1)
  lookahead._dispose()

  let reparse = _parser_test_state("a b")
  let reparsed : Int? = reparse._reparse(fn() -> Int? {
    ignore(reparse._next_token())
    ignore(reparse._parse_error_at_current_token(_diagnostic_message(1003)))
    Some(9)
  })
  assert_eq(reparsed, Some(9))
  assert_eq(reparse.current_token.to_int(), 80)
  assert_eq(reparse.scanner._token_start(), 0)
  assert_eq(reparse.diagnostics.length(), 1)
  assert_false(reparse.finish_state._has_pending_parse_error())
  reparse._dispose()
}

///|
test "parser context helpers inherit and restore all five context flags" {
  let state = _parser_test_state("x")
  assert_false(state._in_disallow_in_context())
  let observed = state._disallow_in_and(() => {
    let outside_value = state._allow_in_and(() => {
      state._in_disallow_in_context()
    })
    (state._in_disallow_in_context(), outside_value)
  })
  assert_eq(observed, (true, false))
  assert_false(state._in_disallow_in_context())
  let yield_await = state._do_in_yield_and_await_context(() => {
    let outside = state._do_outside_of_yield_and_await_context(() => {
      (state._in_yield_context(), state._in_await_context())
    })
    (state._in_yield_context(), state._in_await_context(), outside)
  })
  assert_eq(yield_await, (true, true, (false, false)))
  assert_false(state._in_yield_context())
  assert_false(state._in_await_context())
  let decorator = state._do_in_decorator_context(() => {
    state._in_decorator_context()
  })
  assert_true(decorator)
  let conditional = state._disallow_conditional_types_and(() => {
    let outside = state._allow_conditional_types_and(() => {
      state._in_disallow_conditional_types_context()
    })
    (state._in_disallow_conditional_types_context(), outside)
  })
  assert_eq(conditional, (true, false))
  assert_eq(state.context_flags.bits(), 0U)
  state._dispose()
}

///|
test "expected tokens matching brackets and identifier forms preserve ranges" {
  let brackets = _parser_test_state("(name")
  let open_position = brackets.scanner._token_start()
  assert_true(brackets._parse_expected(_syntax_kind(21)))
  let name = brackets._parse_identifier()
  assert_eq(name.kind().to_int(), 80)
  assert_eq(name.pos(), 1)
  assert_eq(name.end(), 5)
  brackets._parse_expected_matching_brackets(
    _syntax_kind(21),
    _syntax_kind(22),
    true,
    open_position,
  )
  assert_eq(_parser_test_diagnostic_codes(brackets), [1005])
  match brackets.diagnostics[0].related_information() {
    Some(related) => assert_eq(related[0].code(), 1007)
    None => fail("matching bracket diagnostic needs related information")
  }
  brackets._dispose()

  let names = _parser_test_state("#field 1 \"key\" word")
  let private_name = names._parse_private_identifier()
  assert_eq(private_name.kind().to_int(), 81)
  let numeric = names._parse_property_name_without_computed()
  assert_eq(numeric.kind().to_int(), 9)
  let string = names._parse_property_name_without_computed()
  assert_eq(string.kind().to_int(), 11)
  let identifier = names._parse_property_name_without_computed()
  assert_eq(identifier.kind().to_int(), 80)
  assert_eq(names.identifier_count, 1)
  names._dispose()

  let computed = _parser_test_state("[value]")
  let property = computed._parse_property_name(fn() {
    computed._parse_identifier()
  })
  assert_eq(property.kind().to_int(), 168)
  assert_eq(computed.current_token.to_int(), 1)
  computed._dispose()
}

///|
test "ASI suggestions error flags EOF and adjacent diagnostic suppression" {
  let asi = _parser_test_state("x\ny")
  ignore(asi._parse_identifier())
  assert_true(asi._try_parse_semicolon())
  assert_eq(asi.diagnostics.length(), 0)
  asi._dispose()

  let same_line = _parser_test_state("x y")
  let first = same_line._parse_identifier()
  assert_false(same_line._try_parse_semicolon())
  same_line._parse_error_for_missing_semicolon_after(first)
  assert_eq(_parser_test_diagnostic_codes(same_line), [1434])
  same_line._dispose()

  let keyword = _parser_test_state("const value")
  let keyword_name = keyword._parse_identifier_name()
  keyword._parse_error_for_missing_semicolon_after(keyword_name)
  assert_eq(_parser_test_diagnostic_codes(keyword), [1440])
  keyword._dispose()

  let invalid_name_cases = [
    ("interface {", 1438),
    ("interface bad", 2427),
    ("is value", 1228),
    ("namespace {", 1437),
    ("namespace bad", 2819),
    ("type =", 1439),
    ("type bad", 2457),
  ]
  for item in invalid_name_cases {
    let (source, code) = item
    let state = _parser_test_state(source)
    let name = state._parse_identifier_name()
    state._parse_error_for_missing_semicolon_after(name)
    assert_eq(_parser_test_diagnostic_codes(state), [code])
    state._dispose()
  }
  let declared_state = _parser_test_state("declare value")
  let declare_name = declared_state._parse_identifier_name()
  declared_state._parse_error_for_missing_semicolon_after(declare_name)
  assert_eq(declared_state.diagnostics.length(), 0)
  declared_state._dispose()

  let tagged_state = _parser_test_state("tag`x` next")
  let tag = _factory_create_identifier("tag")
  tag._set_text_range(0, 3)
  let template = _factory_create_template_literal_like_node(
    _syntax_kind(15),
    "x",
    raw_text="x",
  )
  template._set_text_range(3, 6)
  let tagged = _factory_create_tagged_template_expression(tag, None, template)
  tagged._set_text_range(0, 6)
  tagged_state._parse_error_for_missing_semicolon_after(tagged)
  assert_eq(_parser_test_diagnostic_codes(tagged_state), [1443])
  tagged_state._dispose()

  let errors = _parser_test_state("a b")
  ignore(errors._parse_error_at_current_token(_diagnostic_message(1003)))
  ignore(errors._parse_error_at_current_token(_diagnostic_message(1109)))
  assert_eq(errors.diagnostics.length(), 1)
  let error_node = errors._parse_identifier()
  assert_true(error_node.flags().contains(NodeFlags::this_node_has_error()))
  let clean_node = errors._parse_identifier()
  assert_false(clean_node.flags().contains(NodeFlags::this_node_has_error()))
  assert_eq(errors.current_token.to_int(), 1)
  errors._dispose()

  let eof_error = _parser_test_state("")
  let missing_identifier = eof_error._parse_identifier()
  assert_eq(_parser_test_diagnostic_codes(eof_error), [1003])
  assert_true(
    missing_identifier.flags().contains(NodeFlags::this_node_has_error()),
  )
  assert_eq(missing_identifier.pos(), 0)
  assert_eq(missing_identifier.end(), 0)
  eof_error._dispose()
}
