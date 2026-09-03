///|
fn _assert_parent_identity(child : Node, expected : Node) -> Unit raise {
  match child.parent() {
    Some(parent) => assert_true(parent.same_identity(expected))
    None => fail("expected parent link")
  }
}

///|
fn _assert_no_parent(node : Node) -> Unit raise {
  match node.parent() {
    None => ()
    Some(_) => fail("expected no parent link")
  }
}

///|
test "parent filling follows ordinary children and the independent JSDoc path" {
  let expression = _contract_identifier(text="value")
  let statement = _factory_create_expression_statement(expression)
  let comment_text = _factory_create_jsdoc_text("details")
  let type_node = _factory_create_this_type_node()
  let type_expression = _factory_create_jsdoc_type_expression(type_node)
  let tag = _factory_create_jsdoc_type_tag(None, Some(type_expression), None)
  let comment = _factory_create_jsdoc_comment(
    Some(_jsdoc_comment_nodes(_create_node_array([comment_text]))),
    Some(_create_node_array([tag])),
  )
  let documents = _create_node_array([comment])
  statement._set_jsdoc(Some(documents))
  let eof = _factory_create_token(_syntax_kind(1))
  let source = _factory_create_source_file(
    _create_node_array([statement]),
    eof,
    NodeFlags::none(),
  )

  _assert_no_parent(source)
  _assert_no_parent(statement)
  _assert_no_parent(expression)
  _assert_no_parent(comment)
  _assert_no_parent(comment_text)
  _assert_no_parent(tag)

  let ordinary_children : Array[Node] = []
  let ordinary_result : Unit? = for_each_child(statement, fn(child) {
    ordinary_children.push(child)
    None
  })
  assert_eq(ordinary_result, None)
  assert_eq(ordinary_children.length(), 1)
  assert_true(ordinary_children[0].same_identity(expression))

  ignore(_set_parent_recursive(source))
  _assert_no_parent(source)
  _assert_parent_identity(statement, source)
  _assert_parent_identity(eof, source)
  _assert_parent_identity(expression, statement)
  _assert_parent_identity(comment, statement)
  _assert_parent_identity(comment_text, comment)
  _assert_parent_identity(tag, comment)
  _assert_parent_identity(type_expression, tag)
  _assert_parent_identity(type_node, type_expression)
  match tag.field("tagName") {
    Some(NodeRef(Some(tag_name))) => _assert_parent_identity(tag_name, tag)
    _ => fail("JSDoc type tag must have a name")
  }
}

///|
test "incremental parent filling skips already-correct ordinary subtrees" {
  let leaf = _contract_identifier(text="leaf")
  let inner = _factory_create_parenthesized_expression(leaf)
  let outer = _factory_create_parenthesized_expression(inner)
  let statement = _factory_create_expression_statement(outer)
  let root = _factory_create_block(_create_node_array([statement]))
  statement._set_parent(Some(root))

  ignore(_set_parent_recursive(root, incremental=true))
  _assert_no_parent(outer)
  _assert_no_parent(inner)
  _assert_no_parent(leaf)

  ignore(_set_parent_recursive(root))
  _assert_parent_identity(outer, statement)
  _assert_parent_identity(inner, outer)
  _assert_parent_identity(leaf, inner)
}

///|
test "isolated JSDoc roots receive complete ordinary parent links" {
  let text = _factory_create_jsdoc_text("text")
  let link_name = _contract_identifier(text="target")
  let link = _factory_create_jsdoc_link(Some(link_name), "label")
  let comment = _factory_create_jsdoc_comment(
    Some(_jsdoc_comment_nodes(_create_node_array([text, link]))),
    None,
  )
  ignore(_set_parent_recursive(comment))
  _assert_no_parent(comment)
  _assert_parent_identity(text, comment)
  _assert_parent_identity(link, comment)
  _assert_parent_identity(link_name, link)
}
