// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _factory_create_block(statements : NodeArray, multi_line? : Bool) -> Node {
  _make_fields_node(
    _syntax_kind(242),
    [
      _node_list_field("statements", Some(statements)),
      _boolean_field("multiLine", multi_line),
    ],
    transform_flags=_propagate_children_flags(Some(statements)),
  )
}

///|
fn _factory_create_variable_statement(
  modifiers : NodeArray?,
  declaration_list : Node,
) -> Node {
  let flags = if _has_modifier(modifiers, ModifierFlags::ambient()) {
    TransformFlags::contains_typescript()
  } else {
    _propagate_children_flags(modifiers).union(
      _propagate_child_flags(Some(declaration_list)),
    )
  }
  _make_fields_node(
    _syntax_kind(244),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("declarationList", Some(declaration_list)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_empty_statement() -> Node {
  _make_fields_node(_syntax_kind(243), [])
}

///|
fn _factory_create_expression_statement(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(245),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression)),
  )
}

///|
fn _factory_create_if_statement(
  expression : Node,
  then_statement : Node,
  else_statement : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(246),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("thenStatement", Some(then_statement)),
      _node_ref_field("elseStatement", else_statement),
    ],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(_propagate_child_flags(Some(then_statement)))
      .union(_propagate_child_flags(else_statement)),
  )
}

///|
fn _factory_create_do_statement(statement : Node, expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(247),
    [
      _node_ref_field("statement", Some(statement)),
      _node_ref_field("expression", Some(expression)),
    ],
    transform_flags=_propagate_child_flags(Some(statement)).union(
      _propagate_child_flags(Some(expression)),
    ),
  )
}

///|
fn _factory_create_while_statement(expression : Node, statement : Node) -> Node {
  _make_fields_node(
    _syntax_kind(248),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("statement", Some(statement)),
    ],
    transform_flags=_propagate_child_flags(Some(expression)).union(
      _propagate_child_flags(Some(statement)),
    ),
  )
}

///|
fn _factory_create_for_statement(
  initializer : Node?,
  condition : Node?,
  incrementor : Node?,
  statement : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(249),
    [
      _node_ref_field("initializer", initializer),
      _node_ref_field("condition", condition),
      _node_ref_field("incrementor", incrementor),
      _node_ref_field("statement", Some(statement)),
    ],
    transform_flags=_propagate_child_flags(initializer)
      .union(_propagate_child_flags(condition))
      .union(_propagate_child_flags(incrementor))
      .union(_propagate_child_flags(Some(statement))),
  )
}

///|
fn _factory_create_for_in_statement(
  initializer : Node,
  expression : Node,
  statement : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(250),
    [
      _node_ref_field("initializer", Some(initializer)),
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("statement", Some(statement)),
    ],
    transform_flags=_propagate_child_flags(Some(initializer))
      .union(_propagate_child_flags(Some(expression)))
      .union(_propagate_child_flags(Some(statement))),
  )
}

///|
fn _factory_create_for_of_statement(
  await_modifier : Node?,
  initializer : Node,
  expression : Node,
  statement : Node,
) -> Node {
  let mut flags = _propagate_child_flags(await_modifier)
    .union(_propagate_child_flags(Some(initializer)))
    .union(_propagate_child_flags(Some(expression)))
    .union(_propagate_child_flags(Some(statement)))
    .union(TransformFlags::contains_es2015())
  if await_modifier is Some(_) {
    flags = flags.union(TransformFlags::contains_es2018())
  }
  _make_fields_node(
    _syntax_kind(251),
    [
      _node_ref_field("awaitModifier", await_modifier),
      _node_ref_field("initializer", Some(initializer)),
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("statement", Some(statement)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_jump_statement(kind : Int, label : Node?) -> Node {
  _make_fields_node(
    _syntax_kind(kind),
    [_node_ref_field("label", label)],
    transform_flags=_propagate_child_flags(label).union(
      TransformFlags::contains_hoisted_declaration_or_completion(),
    ),
  )
}

///|
fn _factory_create_continue_statement(label : Node?) -> Node {
  _factory_create_jump_statement(252, label)
}

///|
fn _factory_create_break_statement(label : Node?) -> Node {
  _factory_create_jump_statement(253, label)
}

///|
fn _factory_create_return_statement(expression : Node?) -> Node {
  _make_fields_node(
    _syntax_kind(254),
    [_node_ref_field("expression", expression)],
    transform_flags=_propagate_child_flags(expression)
      .union(TransformFlags::contains_es2018())
      .union(TransformFlags::contains_hoisted_declaration_or_completion()),
  )
}

///|
fn _factory_create_with_statement(expression : Node, statement : Node) -> Node {
  _make_fields_node(
    _syntax_kind(255),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("statement", Some(statement)),
    ],
    transform_flags=_propagate_child_flags(Some(expression)).union(
      _propagate_child_flags(Some(statement)),
    ),
  )
}

///|
fn _factory_create_switch_statement(
  expression : Node,
  case_block : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(256),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("caseBlock", Some(case_block)),
      _boolean_field("possiblyExhaustive", Some(false)),
    ],
    transform_flags=_propagate_child_flags(Some(expression)).union(
      _propagate_child_flags(Some(case_block)),
    ),
  )
}

///|
fn _factory_create_labeled_statement(label : Node, statement : Node) -> Node {
  _make_fields_node(
    _syntax_kind(257),
    [
      _node_ref_field("label", Some(label)),
      _node_ref_field("statement", Some(statement)),
    ],
    transform_flags=_propagate_child_flags(Some(label)).union(
      _propagate_child_flags(Some(statement)),
    ),
  )
}

///|
fn _factory_create_throw_statement(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(258),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression)),
  )
}

///|
fn _factory_create_try_statement(
  try_block : Node,
  catch_clause : Node?,
  finally_block : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(259),
    [
      _node_ref_field("tryBlock", Some(try_block)),
      _node_ref_field("catchClause", catch_clause),
      _node_ref_field("finallyBlock", finally_block),
    ],
    transform_flags=_propagate_child_flags(Some(try_block))
      .union(_propagate_child_flags(catch_clause))
      .union(_propagate_child_flags(finally_block)),
  )
}

///|
fn _factory_create_debugger_statement() -> Node {
  _make_fields_node(_syntax_kind(260), [])
}
