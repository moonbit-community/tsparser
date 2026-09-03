///|
fn _assert_factory_contract(
  symbol : String,
  node : Node,
  expected_kind : Int,
  expected_fields : Array[String],
) -> Unit raise {
  assert_eq(node.kind().to_int(), expected_kind, msg=symbol + " kind")
  let fields = node.fields()
  assert_eq(
    fields.length(),
    expected_fields.length(),
    msg=symbol + " field count",
  )
  for index in 0..<expected_fields.length() {
    assert_eq(
      fields[index].name(),
      expected_fields[index],
      msg=symbol + " field " + index.to_string(),
    )
  }
  assert_true(
    node.kind().is_parser_constructable(),
    msg=symbol + " constructable",
  )
}

///|
fn _contract_identifier(text? : String = "x") -> Node {
  _factory_create_identifier(text)
}

///|
fn _contract_empty_list() -> NodeArray {
  _create_node_array([])
}

///|
fn _contract_block() -> Node {
  _factory_create_block(_contract_empty_list())
}

///|
test "emit-only SyntaxKind values have no parser payload strategy" {
  assert_false(_syntax_kind(309).is_parser_constructable())
  for kind in 353..<359 {
    assert_false(_syntax_kind(kind).is_parser_constructable())
  }
  assert_false(_syntax_kind(303).is_parser_constructable())
  assert_true(_syntax_kind(308).is_parser_constructable())
  assert_true(_syntax_kind(310).is_parser_constructable())
  assert_true(_syntax_kind(352).is_parser_constructable())
}

///|
test "finish_node applies range and context and consumes one parse error" {
  let state = _new_node_finish_state()
  state._set_context_flags(
    NodeFlags::await_context().union(NodeFlags::yield_context()),
  )
  state._mark_parse_error()
  let first = _finish_node(state, _contract_identifier(), 4, 9)
  assert_eq(first.pos(), 4)
  assert_eq(first.end(), 9)
  assert_true(first.flags().contains(NodeFlags::await_context()))
  assert_true(first.flags().contains(NodeFlags::yield_context()))
  assert_true(first.flags().contains(NodeFlags::this_node_has_error()))
  assert_false(state._has_pending_parse_error())
  let second = _finish_node(state, _contract_identifier(), 9, 9)
  assert_false(second.flags().contains(NodeFlags::this_node_has_error()))
}

///|
test "missing nodes are zero-width and preserve empty payloads" {
  let state = _new_node_finish_state()
  let identifier = _create_missing_node(state, _syntax_kind(80), 7)
  assert_eq(identifier.pos(), 7)
  assert_eq(identifier.end(), 7)
  assert_text_field(identifier, "escapedText", Some(""))
  let numeric = _create_missing_node(state, _syntax_kind(9), 8)
  assert_text_field(numeric, "text", Some(""))
  let template = _create_missing_node(state, _syntax_kind(16), 9)
  assert_text_field(template, "text", Some(""))
  assert_text_field(template, "rawText", Some(""))
  let declaration = _create_missing_node(state, _syntax_kind(283), 10)
  assert_eq(declaration.kind().to_int(), 283)
  let token = _create_missing_node(state, _syntax_kind(58), 11)
  assert_eq(token.kind().to_int(), 58)
  assert_eq(token.pos(), token.end())
}
