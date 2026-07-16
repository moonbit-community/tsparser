///|
fn optional_parameter_probe(value? : Int = 7, policy? : (Int) -> Int?) -> Int {
  match policy {
    None => value
    Some(policy) =>
      match policy(value) {
        Some(result) => result
        None => value
      }
  }
}

///|
fn recursive_callback_probe(node : Node, policy? : (Node) -> Node?) -> Node? {
  match policy {
    Some(policy) => policy(node)
    None => Some(node)
  }
}

///|
test "SyntaxKind uses explicit numeric aliases" {
  guard SyntaxKind::from_int(0) is Some(unknown) else {
    fail("0 must be a SyntaxKind")
  }
  guard SyntaxKind::from_int(9) is Some(numeric) else {
    fail("9 must be a SyntaxKind")
  }
  guard SyntaxKind::from_int(167) is Some(qualified) else {
    fail("167 must be a SyntaxKind")
  }
  inspect(unknown.runtime_name(), content="FirstToken")
  inspect(numeric.runtime_name(), content="FirstLiteralToken")
  inspect(qualified.runtime_name(), content="FirstNode")
  debug_inspect(
    numeric.declaration_names(),
    content=(
      #|<ReadOnlyArray: ["NumericLiteral"]>
    ),
  )
  debug_inspect(
    numeric.classification_markers(),
    content=(
      #|<ReadOnlyArray: ["FirstLiteralToken"]>
    ),
  )
  assert_true(SyntaxKind::from_int(-1) is None)
  assert_true(SyntaxKind::from_int(359) is None)
  match numeric.to_int() {
    9 => ()
    _ => fail("numeric pattern scheme must preserve the explicit value")
  }
}

///|
test "unsigned flags preserve the high bit" {
  let high = TransformFlags::has_computed_flags()
  inspect(high.bits(), content="2147483648")
  inspect(high.bits().reinterpret_as_int(), content="-2147483648")
  let low = TransformFlags::from_bits(5U)
  let combined = high.union(low)
  inspect(combined.bits(), content="2147483653")
  assert_true(combined.contains(high))
  assert_true(combined.contains(low))
}

///|
test "node identity, parent cycles, and readonly arrays are stable" {
  guard SyntaxKind::from_int(80) is Some(identifier_kind) else {
    fail("identifier kind must be valid")
  }
  let leaf = _make_node(
    identifier_kind,
    0,
    1,
    NodeFlags::none(),
    TransformFlags::none(),
    None,
  )
  let mutable_elements = [leaf]
  let children = _make_node_array(
    mutable_elements,
    0,
    1,
    false,
    TransformFlags::none(),
  )
  guard SyntaxKind::from_int(244) is Some(block_kind) else {
    fail("block kind must be valid")
  }
  let parent = _make_node(
    block_kind,
    0,
    1,
    NodeFlags::none(),
    TransformFlags::none(),
    Some(children),
  )
  leaf._set_parent(Some(parent))
  mutable_elements.push(parent)
  inspect(children.length(), content="1")
  guard children.get(0) is Some(same_leaf) else { fail("missing child") }
  assert_true(same_leaf.same_identity(leaf))
  assert_false(same_leaf.same_identity(parent))
  guard leaf.parent() is Some(actual_parent) else { fail("missing parent") }
  assert_true(actual_parent.same_identity(parent))
  guard recursive_callback_probe(leaf) is Some(default_node) else {
    fail("default recursive callback result missing")
  }
  assert_true(default_node.same_identity(leaf))
  assert_true(recursive_callback_probe(leaf, policy=_ => None) is None)
}

///|
test "UTF-16 ranges may split surrogate pairs" {
  let source = "A😀B"
  inspect(source.length(), content="4")
  let high = _materialize_text_range(source, 1, 2)
  let low = _materialize_text_range(source, 2, 3)
  inspect(high.length(), content="1")
  inspect(low.length(), content="1")
  inspect(high.code_units()[0], content="55357")
  inspect(low.code_units()[0], content="56832")
  let pair = _materialize_text_range(source, 1, 3)
  inspect(pair.length(), content="2")
  inspect(pair, content="😀")
}

///|
test "deep node traversal uses an explicit stack" {
  guard SyntaxKind::from_int(217) is Some(parenthesized_kind) else {
    fail("parenthesized expression kind must be valid")
  }
  let mut current = _make_node(
    parenthesized_kind,
    0,
    0,
    NodeFlags::none(),
    TransformFlags::none(),
    None,
  )
  let depth = 50000
  for _ in 0..<depth {
    let child = current
    let children = _make_node_array(
      [child],
      0,
      0,
      false,
      TransformFlags::none(),
    )
    current = _make_node(
      parenthesized_kind,
      0,
      0,
      NodeFlags::none(),
      TransformFlags::none(),
      Some(children),
    )
    child._set_parent(Some(current))
  }
  inspect(_count_nodes_iterative(current), content="50001")
}

///|
test "optional arguments and callbacks keep distinct defaults" {
  inspect(optional_parameter_probe(), content="7")
  inspect(optional_parameter_probe(value=4), content="4")
  inspect(
    optional_parameter_probe(value=4, policy=x => Some(x + 1)),
    content="5",
  )
  inspect(optional_parameter_probe(value=4, policy=_ => None), content="4")
}
