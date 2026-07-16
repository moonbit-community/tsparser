// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _factory_create_jsx_element(
  opening_element : Node,
  children : NodeArray,
  closing_element : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(285),
    [
      _node_ref_field("openingElement", Some(opening_element)),
      _node_list_field("children", Some(children)),
      _node_ref_field("closingElement", Some(closing_element)),
    ],
    transform_flags=_propagate_child_flags(Some(opening_element))
      .union(_propagate_children_flags(Some(children)))
      .union(_propagate_child_flags(Some(closing_element)))
      .union(TransformFlags::contains_jsx()),
  )
}

///|
fn _factory_create_jsx_self_closing_element(
  tag_name : Node,
  type_arguments : NodeArray?,
  attributes : Node,
) -> Node {
  let mut flags = _propagate_child_flags(Some(tag_name))
    .union(_propagate_children_flags(type_arguments))
    .union(_propagate_child_flags(Some(attributes)))
    .union(TransformFlags::contains_jsx())
  if type_arguments is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  _make_fields_node(
    _syntax_kind(286),
    [
      _node_ref_field("tagName", Some(tag_name)),
      _node_list_field("typeArguments", type_arguments),
      _node_ref_field("attributes", Some(attributes)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_jsx_opening_element(
  tag_name : Node,
  type_arguments : NodeArray?,
  attributes : Node,
) -> Node {
  let mut flags = _propagate_child_flags(Some(tag_name))
    .union(_propagate_children_flags(type_arguments))
    .union(_propagate_child_flags(Some(attributes)))
    .union(TransformFlags::contains_jsx())
  if type_arguments is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  _make_fields_node(
    _syntax_kind(287),
    [
      _node_ref_field("tagName", Some(tag_name)),
      _node_list_field("typeArguments", type_arguments),
      _node_ref_field("attributes", Some(attributes)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_jsx_closing_element(tag_name : Node) -> Node {
  _make_fields_node(
    _syntax_kind(288),
    [_node_ref_field("tagName", Some(tag_name))],
    transform_flags=_propagate_child_flags(Some(tag_name)).union(
      TransformFlags::contains_jsx(),
    ),
  )
}

///|
fn _factory_create_jsx_fragment(
  opening_fragment : Node,
  children : NodeArray,
  closing_fragment : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(289),
    [
      _node_ref_field("openingFragment", Some(opening_fragment)),
      _node_list_field("children", Some(children)),
      _node_ref_field("closingFragment", Some(closing_fragment)),
    ],
    transform_flags=_propagate_child_flags(Some(opening_fragment))
      .union(_propagate_children_flags(Some(children)))
      .union(_propagate_child_flags(Some(closing_fragment)))
      .union(TransformFlags::contains_jsx()),
  )
}

///|
fn _factory_create_jsx_opening_fragment() -> Node {
  _make_fields_node(
    _syntax_kind(290),
    [],
    transform_flags=TransformFlags::contains_jsx(),
  )
}

///|
fn _factory_create_jsx_jsx_closing_fragment() -> Node {
  _make_fields_node(
    _syntax_kind(291),
    [],
    transform_flags=TransformFlags::contains_jsx(),
  )
}

///|
fn _factory_create_jsx_attribute(name : Node, initializer : Node?) -> Node {
  _make_fields_node(
    _syntax_kind(292),
    [
      _node_ref_field("name", Some(name)),
      _node_ref_field("initializer", initializer),
    ],
    transform_flags=_propagate_child_flags(Some(name))
      .union(_propagate_child_flags(initializer))
      .union(TransformFlags::contains_jsx()),
  )
}

///|
fn _factory_create_jsx_attributes(properties : NodeArray) -> Node {
  _make_fields_node(
    _syntax_kind(293),
    [_node_list_field("properties", Some(properties))],
    transform_flags=_propagate_children_flags(Some(properties)).union(
      TransformFlags::contains_jsx(),
    ),
  )
}

///|
fn _factory_create_jsx_spread_attribute(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(294),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression)).union(
      TransformFlags::contains_jsx(),
    ),
  )
}

///|
fn _factory_create_jsx_expression(
  dot_dot_dot_token : Node?,
  expression : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(295),
    [
      _node_ref_field("dotDotDotToken", dot_dot_dot_token),
      _node_ref_field("expression", expression),
    ],
    transform_flags=_propagate_child_flags(dot_dot_dot_token)
      .union(_propagate_child_flags(expression))
      .union(TransformFlags::contains_jsx()),
  )
}

///|
fn _factory_create_jsx_namespaced_name(
  namespace_node : Node,
  name : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(296),
    [
      _node_ref_field("namespace", Some(namespace_node)),
      _node_ref_field("name", Some(name)),
    ],
    transform_flags=_propagate_child_flags(Some(namespace_node))
      .union(_propagate_child_flags(Some(name)))
      .union(TransformFlags::contains_jsx()),
  )
}
