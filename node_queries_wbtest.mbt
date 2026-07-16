///|
fn _query_set_source_text(source_file : Node, text : String) -> Unit {
  let fields : Array[NodeField] = []
  let mut replaced = false
  for field in source_file.fields() {
    if field.name() == "text" {
      fields.push(_text_field("text", Some(text)))
      replaced = true
    } else {
      fields.push(field)
    }
  }
  guard replaced else { abort("SourceFile text field is missing") }
  source_file._set_fields(fields)
}

///|
fn _query_source(text : String) -> Node {
  let eof = _factory_create_token(_syntax_kind(1))
  eof._set_text_range(text.length(), text.length())
  let source = _factory_create_source_file(
    _create_node_array([]),
    eof,
    NodeFlags::none(),
  )
  source._set_text_range(0, text.length())
  _query_set_source_text(source, text)
  source
}

///|
fn _assert_query_identity(actual : Node?, expected : Node) -> Unit raise {
  match actual {
    Some(actual) => assert_true(actual.same_identity(expected))
    None => fail("expected a node")
  }
}

///|
test "node range and text queries preserve UTF-16 and JSDoc starts" {
  let text = " \t/*lead*/foo😀;\r\nbar"
  assert_eq(text.length(), 21)
  let identifier = _contract_identifier(text="foo😀")
  identifier._set_text_range(0, 15)
  let statement = _factory_create_expression_statement(identifier)
  statement._set_text_range(0, 16)
  let document = _factory_create_jsdoc_comment(None, None)
  document._set_text_range(2, 10)
  statement._set_jsdoc(Some(_create_node_array([document])))
  let eof = _factory_create_token(_syntax_kind(1))
  eof._set_text_range(21, 21)
  let statements = _create_node_array([statement])
  statements._set_text_range(0, 16)
  let source = _factory_create_source_file(statements, eof, NodeFlags::none())
  source._set_text_range(0, 21)
  _query_set_source_text(source, text)

  assert_true(identifier.source_file() is None)
  assert_eq(identifier.full_start(), 0)
  assert_eq(identifier.full_width(), 15)
  assert_eq(identifier.start(source_file=source), 10)
  assert_eq(identifier.leading_trivia_width(source_file=source), 10)
  assert_eq(identifier.width(source_file=source), 5)
  inspect(
    identifier.full_text(source_file=source),
    content=" \t/*lead*/foo😀",
  )
  inspect(identifier.text(source_file=source), content="foo😀")
  assert_eq(statement.start(source_file=source), 10)
  assert_eq(statement.start(source_file=source, include_jsdoc_comment=true), 2)
  inspect(document.text(source_file=source), content="/*lead*/")

  ignore(_set_parent_recursive(source))
  _assert_query_identity(identifier.source_file(), source)
  _assert_query_identity(document.source_file(), source)
  inspect(identifier.text(), content="foo😀")
  inspect(source.full_text(), content=" \t/*lead*/foo😀;\r\nbar")

  let starts = source.line_starts()
  assert_eq(starts.length(), 2)
  assert_eq(starts[0], 0)
  assert_eq(starts[1], 18)
  assert_eq(
    source.line_and_character_of_position(15),
    LineAndCharacter::new(0, 15),
  )
  assert_eq(
    source.line_and_character_of_position(20),
    LineAndCharacter::new(1, 2),
  )
  assert_eq(source.position_of_line_and_character(1, 2), 20)
  assert_eq(source.position_of_line_and_character(0, 99, allow_edits=true), 18)
}

///|
test "token starts retain missing JSDoc-context and JSX special cases" {
  let missing_source = _query_source("     x")
  let missing = _contract_identifier(text="")
  missing._set_text_range(5, 5)
  assert_eq(missing.start(source_file=missing_source), 5)
  assert_eq(missing.width(source_file=missing_source), 0)
  inspect(missing.text(source_file=missing_source), content="")

  let jsdoc_source = _query_source("\n * value")
  let jsdoc_identifier = _contract_identifier(text="value")
  jsdoc_identifier._set_text_range(0, 9)
  jsdoc_identifier._set_flags(NodeFlags::jsdoc())
  assert_eq(jsdoc_identifier.start(source_file=jsdoc_source), 4)
  inspect(jsdoc_identifier.text(source_file=jsdoc_source), content="value")

  let jsx_source = _query_source("//not-comment")
  let jsx_text = _factory_create_jsx_text("//not-comment")
  jsx_text._set_text_range(0, 13)
  assert_eq(jsx_text.start(source_file=jsx_source), 0)
  inspect(jsx_text.text(source_file=jsx_source), content="//not-comment")
}

///|
test "direct child and token queries use normative semantic order" {
  let left = _contract_identifier(text="left")
  left._set_text_range(0, 1)
  let operator = _factory_create_token(_syntax_kind(40))
  operator._set_text_range(1, 2)
  let right = _contract_identifier(text="right")
  right._set_text_range(2, 3)
  let binary = _factory_create_binary_expression(left, operator, right)
  binary._set_text_range(0, 3)

  assert_eq(binary.child_count(), 3)
  _assert_query_identity(binary.first_child(), left)
  _assert_query_identity(binary.last_child(), right)
  _assert_query_identity(binary.first_token(), left)
  _assert_query_identity(binary.last_token(), right)
  assert_true(left.first_token() is None)
  assert_true(right.last_token() is None)
  match binary.children() {
    Some(children) => {
      assert_eq(children.length(), 3)
      _assert_query_identity(children.get(0), left)
      _assert_query_identity(children.get(1), operator)
      _assert_query_identity(children.get(2), right)
    }
    None => fail("expected binary children")
  }

  right._set_text_range(3, 3)
  _assert_query_identity(binary.last_child(), operator)
  assert_eq(binary.child_count(), 3)
}
