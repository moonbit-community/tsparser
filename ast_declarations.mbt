// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _without_possible_top_level_await(flags : TransformFlags) -> TransformFlags {
  flags.without(TransformFlags::contains_possible_top_level_await())
}

///|
fn _factory_create_variable_declaration(
  name : Node,
  exclamation_token : Node?,
  type_node : Node?,
  initializer : Node?,
) -> Node {
  let mut flags = _propagate_name_flags(Some(name)).union(
    _propagate_child_flags(initializer),
  )
  if exclamation_token is Some(_) || type_node is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  _make_fields_node(
    _syntax_kind(261),
    [
      _node_ref_field("name", Some(name)),
      _node_ref_field("exclamationToken", exclamation_token),
      _node_ref_field("type", type_node),
      _node_ref_field("initializer", initializer),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_variable_declaration_list(
  declarations : NodeArray,
  flags? : NodeFlags = NodeFlags::none(),
) -> Node {
  let block_scoped = flags.intersect(NodeFlags::block_scoped())
  let node = _make_fields_node(
    _syntax_kind(262),
    [_node_list_field("declarations", Some(declarations))],
    transform_flags=_propagate_children_flags(Some(declarations)).union(
      TransformFlags::contains_hoisted_declaration_or_completion(),
    ),
  )
  node._set_flags(block_scoped)
  if block_scoped.bits() != 0U {
    node._add_transform_flags(
      TransformFlags::contains_es2015().union(
        TransformFlags::contains_block_scoped_binding(),
      ),
    )
  }
  if flags.intersect(NodeFlags::using_flag()).bits() != 0U {
    node._add_transform_flags(TransformFlags::contains_es_next())
  }
  node
}

///|
fn _factory_create_function_declaration(
  modifiers : NodeArray?,
  asterisk_token : Node?,
  name : Node?,
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node?,
  body : Node?,
) -> Node {
  let flags = if body is None ||
    _has_modifier(modifiers, ModifierFlags::ambient()) {
    TransformFlags::contains_typescript()
  } else {
    guard body is Some(body) else { abort("unreachable function body") }
    let is_async = _has_modifier(modifiers, ModifierFlags::async_flag())
    let is_generator = asterisk_token is Some(_)
    let mut result = _propagate_children_flags(modifiers)
      .union(_propagate_child_flags(asterisk_token))
      .union(_propagate_name_flags(name))
      .union(_propagate_children_flags(type_parameters))
      .union(_propagate_children_flags(Some(parameters)))
      .union(_propagate_child_flags(type_node))
      .union(
        _without_possible_top_level_await(_propagate_child_flags(Some(body))),
      )
    if is_async && is_generator {
      result = result.union(TransformFlags::contains_es2018())
    } else if is_async {
      result = result.union(TransformFlags::contains_es2017())
    } else if is_generator {
      result = result.union(TransformFlags::contains_generator())
    }
    if type_parameters is Some(_) || type_node is Some(_) {
      result = result.union(TransformFlags::contains_typescript())
    }
    result.union(TransformFlags::contains_hoisted_declaration_or_completion())
  }
  _make_fields_node(
    _syntax_kind(263),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("asteriskToken", asterisk_token),
      _node_ref_field("name", name),
      _node_list_field("typeParameters", type_parameters),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_ref_field("body", body),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_class_declaration(
  modifiers : NodeArray?,
  name : Node?,
  type_parameters : NodeArray?,
  heritage_clauses : NodeArray?,
  members : NodeArray,
) -> Node {
  let flags = if _has_modifier(modifiers, ModifierFlags::ambient()) {
    TransformFlags::contains_typescript()
  } else {
    let mut result = _propagate_children_flags(modifiers)
      .union(_propagate_name_flags(name))
      .union(_propagate_children_flags(type_parameters))
      .union(_propagate_children_flags(heritage_clauses))
      .union(_propagate_children_flags(Some(members)))
      .union(TransformFlags::contains_es2015())
    if type_parameters is Some(_) {
      result = result.union(TransformFlags::contains_typescript())
    }
    if result
      .intersect(TransformFlags::contains_typescript_class_syntax())
      .bits() !=
      0U {
      result = result.union(TransformFlags::contains_typescript())
    }
    result
  }
  _make_fields_node(
    _syntax_kind(264),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", name),
      _node_list_field("typeParameters", type_parameters),
      _node_list_field("heritageClauses", heritage_clauses),
      _node_list_field("members", Some(members)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_interface_declaration(
  modifiers : NodeArray?,
  name : Node,
  type_parameters : NodeArray?,
  heritage_clauses : NodeArray?,
  members : NodeArray,
) -> Node {
  _make_fields_node(
    _syntax_kind(265),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_list_field("typeParameters", type_parameters),
      _node_list_field("heritageClauses", heritage_clauses),
      _node_list_field("members", Some(members)),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_type_alias_declaration(
  modifiers : NodeArray?,
  name : Node,
  type_parameters : NodeArray?,
  type_node : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(266),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_list_field("typeParameters", type_parameters),
      _node_ref_field("type", Some(type_node)),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_enum_declaration(
  modifiers : NodeArray?,
  name : Node,
  members : NodeArray,
) -> Node {
  _make_fields_node(
    _syntax_kind(267),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_list_field("members", Some(members)),
    ],
    transform_flags=_without_possible_top_level_await(
      _propagate_children_flags(modifiers)
      .union(_propagate_child_flags(Some(name)))
      .union(_propagate_children_flags(Some(members)))
      .union(TransformFlags::contains_typescript()),
    ),
  )
}

///|
fn _factory_create_module_declaration(
  modifiers : NodeArray?,
  name : Node,
  body : Node?,
  flags? : NodeFlags = NodeFlags::none(),
) -> Node {
  let node_flags = flags.intersect(NodeFlags::from_bits(2088U))
  let transform_flags = if _has_modifier(modifiers, ModifierFlags::ambient()) {
    TransformFlags::contains_typescript()
  } else {
    _propagate_children_flags(modifiers)
    .union(_propagate_child_flags(Some(name)))
    .union(_propagate_child_flags(body))
    .union(TransformFlags::contains_typescript())
  }
  let node = _make_fields_node(
    _syntax_kind(268),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_ref_field("body", body),
    ],
    transform_flags=_without_possible_top_level_await(transform_flags),
  )
  node._set_flags(node_flags)
  node
}

///|
fn _factory_create_module_block(statements : NodeArray) -> Node {
  _make_fields_node(
    _syntax_kind(269),
    [_node_list_field("statements", Some(statements))],
    transform_flags=_propagate_children_flags(Some(statements)),
  )
}

///|
fn _factory_create_case_block(clauses : NodeArray) -> Node {
  _make_fields_node(
    _syntax_kind(270),
    [_node_list_field("clauses", Some(clauses))],
    transform_flags=_propagate_children_flags(Some(clauses)),
  )
}

///|
fn _factory_create_namespace_export_declaration(name : Node) -> Node {
  _make_fields_node(
    _syntax_kind(271),
    [_node_ref_field("name", Some(name)), _node_list_field("modifiers", None)],
    transform_flags=_propagate_identifier_name_flags(name).union(
      TransformFlags::contains_typescript(),
    ),
  )
}

///|
fn _factory_create_import_equals_declaration(
  modifiers : NodeArray?,
  is_type_only : Bool,
  name : Node,
  module_reference : Node,
) -> Node {
  let mut flags = _propagate_children_flags(modifiers)
    .union(_propagate_identifier_name_flags(name))
    .union(_propagate_child_flags(Some(module_reference)))
  if module_reference.kind().to_int() != 284 {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  _make_fields_node(
    _syntax_kind(272),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _boolean_field("isTypeOnly", Some(is_type_only)),
      _node_ref_field("moduleReference", Some(module_reference)),
    ],
    transform_flags=_without_possible_top_level_await(flags),
  )
}

///|
fn _factory_create_import_declaration(
  modifiers : NodeArray?,
  import_clause : Node?,
  module_specifier : Node,
  attributes : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(273),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("importClause", import_clause),
      _node_ref_field("moduleSpecifier", Some(module_specifier)),
      _node_ref_field("assertClause", attributes),
      _node_ref_field("attributes", attributes),
    ],
    transform_flags=_without_possible_top_level_await(
      _propagate_child_flags(import_clause).union(
        _propagate_child_flags(Some(module_specifier)),
      ),
    ),
  )
}

///|
fn _factory_create_import_clause(
  import_modifier : SyntaxKind?,
  name : Node?,
  named_bindings : Node?,
) -> Node {
  let is_type_only = match import_modifier {
    Some(kind) => kind.to_int() == 156
    None => false
  }
  let mut flags = _propagate_child_flags(name).union(
    _propagate_child_flags(named_bindings),
  )
  if is_type_only {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  _make_fields_node(
    _syntax_kind(274),
    [
      _boolean_field("isTypeOnly", Some(is_type_only)),
      _kind_field("phaseModifier", import_modifier),
      _node_ref_field("name", name),
      _node_ref_field("namedBindings", named_bindings),
    ],
    transform_flags=_without_possible_top_level_await(flags),
  )
}

///|
fn _factory_create_import_attributes(
  elements : NodeArray,
  multi_line? : Bool,
  token? : SyntaxKind = _syntax_kind(118),
) -> Node {
  _make_fields_node(
    _syntax_kind(301),
    [
      _kind_field("token", Some(token)),
      _node_list_field("elements", Some(elements)),
      _boolean_field("multiLine", multi_line),
    ],
    transform_flags=TransformFlags::contains_es_next(),
  )
}

///|
fn _factory_create_import_attribute(name : Node, value : Node) -> Node {
  _make_fields_node(
    _syntax_kind(302),
    [_node_ref_field("name", Some(name)), _node_ref_field("value", Some(value))],
    transform_flags=TransformFlags::contains_es_next(),
  )
}

///|
fn _factory_create_namespace_import(name : Node) -> Node {
  _make_fields_node(
    _syntax_kind(275),
    [_node_ref_field("name", Some(name))],
    transform_flags=_without_possible_top_level_await(
      _propagate_child_flags(Some(name)),
    ),
  )
}

///|
fn _factory_create_namespace_export(name : Node) -> Node {
  _make_fields_node(
    _syntax_kind(281),
    [_node_ref_field("name", Some(name))],
    transform_flags=_without_possible_top_level_await(
      _propagate_child_flags(Some(name)).union(
        TransformFlags::contains_es2020(),
      ),
    ),
  )
}

///|
fn _factory_create_named_imports(elements : NodeArray) -> Node {
  _make_fields_node(
    _syntax_kind(276),
    [_node_list_field("elements", Some(elements))],
    transform_flags=_without_possible_top_level_await(
      _propagate_children_flags(Some(elements)),
    ),
  )
}

///|
fn _factory_create_import_specifier(
  is_type_only : Bool,
  property_name : Node?,
  name : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(277),
    [
      _boolean_field("isTypeOnly", Some(is_type_only)),
      _node_ref_field("propertyName", property_name),
      _node_ref_field("name", Some(name)),
    ],
    transform_flags=_without_possible_top_level_await(
      _propagate_child_flags(property_name).union(
        _propagate_child_flags(Some(name)),
      ),
    ),
  )
}

///|
fn _factory_create_export_assignment(
  modifiers : NodeArray?,
  is_export_equals : Bool?,
  expression : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(278),
    [
      _node_list_field("modifiers", modifiers),
      _boolean_field("isExportEquals", is_export_equals),
      _node_ref_field("expression", Some(expression)),
    ],
    transform_flags=_without_possible_top_level_await(
      _propagate_children_flags(modifiers).union(
        _propagate_child_flags(Some(expression)),
      ),
    ),
  )
}

///|
fn _factory_create_export_declaration(
  modifiers : NodeArray?,
  is_type_only : Bool,
  export_clause : Node?,
  module_specifier : Node?,
  attributes : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(279),
    [
      _node_list_field("modifiers", modifiers),
      _boolean_field("isTypeOnly", Some(is_type_only)),
      _node_ref_field("exportClause", export_clause),
      _node_ref_field("moduleSpecifier", module_specifier),
      _node_ref_field("assertClause", attributes),
      _node_ref_field("attributes", attributes),
    ],
    transform_flags=_without_possible_top_level_await(
      _propagate_children_flags(modifiers)
      .union(_propagate_child_flags(export_clause))
      .union(_propagate_child_flags(module_specifier)),
    ),
  )
}

///|
fn _factory_create_named_exports(elements : NodeArray) -> Node {
  _make_fields_node(
    _syntax_kind(280),
    [_node_list_field("elements", Some(elements))],
    transform_flags=_without_possible_top_level_await(
      _propagate_children_flags(Some(elements)),
    ),
  )
}

///|
fn _factory_create_export_specifier(
  is_type_only : Bool,
  property_name : Node?,
  name : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(282),
    [
      _boolean_field("isTypeOnly", Some(is_type_only)),
      _node_ref_field("propertyName", property_name),
      _node_ref_field("name", Some(name)),
    ],
    transform_flags=_without_possible_top_level_await(
      _propagate_child_flags(property_name).union(
        _propagate_child_flags(Some(name)),
      ),
    ),
  )
}

///|
fn _factory_create_missing_declaration() -> Node {
  _make_fields_node(_syntax_kind(283), [])
}

///|
fn _factory_create_external_module_reference(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(284),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_without_possible_top_level_await(
      _propagate_child_flags(Some(expression)),
    ),
  )
}
