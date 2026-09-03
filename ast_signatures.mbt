// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _is_this_identifier(node : Node) -> Bool {
  if node.kind().to_int() != 80 {
    return false
  }
  match node.field("escapedText") {
    Some(Text(Some("this"))) => true
    _ => false
  }
}

///|
fn _factory_create_type_parameter_declaration(
  modifiers : NodeArray?,
  name : Node,
  constraint : Node?,
  default_type : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(169),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_ref_field("constraint", constraint),
      _node_ref_field("default", default_type),
      _node_ref_field("expression", None),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_parameter_declaration(
  modifiers : NodeArray?,
  dot_dot_dot_token : Node?,
  name : Node,
  question_token : Node?,
  type_node : Node?,
  initializer : Node?,
) -> Node {
  let mut flags = TransformFlags::contains_typescript()
  if !_is_this_identifier(name) {
    flags = _propagate_children_flags(modifiers)
      .union(_propagate_child_flags(dot_dot_dot_token))
      .union(_propagate_name_flags(Some(name)))
      .union(_propagate_child_flags(question_token))
      .union(_propagate_child_flags(initializer))
    if question_token is Some(_) || type_node is Some(_) {
      flags = flags.union(TransformFlags::contains_typescript())
    }
    if dot_dot_dot_token is Some(_) || initializer is Some(_) {
      flags = flags.union(TransformFlags::contains_es2015())
    }
    if _has_modifier(modifiers, ModifierFlags::parameter_property_modifier()) {
      flags = flags.union(TransformFlags::contains_typescript_class_syntax())
    }
  }
  _make_fields_node(
    _syntax_kind(170),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("dotDotDotToken", dot_dot_dot_token),
      _node_ref_field("name", Some(name)),
      _node_ref_field("questionToken", question_token),
      _node_ref_field("type", type_node),
      _node_ref_field("initializer", initializer),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_jsdoc_parameter_declaration(
  name : Node?,
  type_node : Node,
) -> Node {
  let flags = _propagate_name_flags(name).union(
    TransformFlags::contains_typescript(),
  )
  _make_fields_node(
    _syntax_kind(170),
    [
      _node_list_field("modifiers", None),
      _node_ref_field("dotDotDotToken", None),
      _node_ref_field("name", name),
      _node_ref_field("questionToken", None),
      _node_ref_field("type", Some(type_node)),
      _node_ref_field("initializer", None),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_decorator(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(171),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(TransformFlags::contains_typescript())
      .union(TransformFlags::contains_typescript_class_syntax())
      .union(TransformFlags::contains_decorators()),
  )
}

///|
fn _factory_create_property_signature(
  modifiers : NodeArray?,
  name : Node,
  question_token : Node?,
  type_node : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(172),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_ref_field("type", type_node),
      _node_ref_field("questionToken", question_token),
      _node_ref_field("initializer", None),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_property_declaration(
  modifiers : NodeArray?,
  name : Node,
  question_or_exclamation_token : Node?,
  type_node : Node?,
  initializer : Node?,
) -> Node {
  let question_token = match question_or_exclamation_token {
    Some(token) if token.kind().to_int() == 58 => Some(token)
    _ => None
  }
  let exclamation_token = match question_or_exclamation_token {
    Some(token) if token.kind().to_int() == 54 => Some(token)
    _ => None
  }
  let mut flags = _propagate_children_flags(modifiers)
    .union(_propagate_name_flags(Some(name)))
    .union(_propagate_child_flags(initializer))
  if _has_modifier(modifiers, ModifierFlags::ambient()) ||
    question_token is Some(_) ||
    exclamation_token is Some(_) ||
    type_node is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  if name.kind().to_int() == 168 ||
    (
      _has_modifier(modifiers, ModifierFlags::static_flag()) &&
      initializer is Some(_)
    ) {
    flags = flags.union(TransformFlags::contains_typescript_class_syntax())
  }
  flags = flags.union(TransformFlags::contains_class_fields())
  _make_fields_node(
    _syntax_kind(173),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_ref_field("questionToken", question_token),
      _node_ref_field("exclamationToken", exclamation_token),
      _node_ref_field("type", type_node),
      _node_ref_field("initializer", initializer),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_method_signature(
  modifiers : NodeArray?,
  name : Node,
  question_token : Node?,
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(174),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_ref_field("questionToken", question_token),
      _node_list_field("typeParameters", type_parameters),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_method_declaration(
  modifiers : NodeArray?,
  asterisk_token : Node?,
  name : Node,
  question_token : Node?,
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node?,
  body : Node?,
) -> Node {
  let flags = match body {
    None => TransformFlags::contains_typescript()
    Some(body) => {
      let is_async = _has_modifier(modifiers, ModifierFlags::async_flag())
      let is_generator = asterisk_token is Some(_)
      let mut result = _propagate_children_flags(modifiers)
        .union(_propagate_child_flags(asterisk_token))
        .union(_propagate_name_flags(Some(name)))
        .union(_propagate_child_flags(question_token))
        .union(_propagate_children_flags(type_parameters))
        .union(_propagate_children_flags(Some(parameters)))
        .union(_propagate_child_flags(type_node))
        .union(
          _propagate_child_flags(Some(body)).without(
            TransformFlags::contains_possible_top_level_await(),
          ),
        )
      if is_async && is_generator {
        result = result.union(TransformFlags::contains_es2018())
      } else if is_async {
        result = result.union(TransformFlags::contains_es2017())
      } else if is_generator {
        result = result.union(TransformFlags::contains_generator())
      }
      if question_token is Some(_) ||
        type_parameters is Some(_) ||
        type_node is Some(_) {
        result = result.union(TransformFlags::contains_typescript())
      }
      result.union(TransformFlags::contains_es2015())
    }
  }
  _make_fields_node(
    _syntax_kind(175),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("asteriskToken", asterisk_token),
      _node_ref_field("name", Some(name)),
      _node_ref_field("questionToken", question_token),
      _node_ref_field("exclamationToken", None),
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
fn _factory_create_class_static_block_declaration(body : Node) -> Node {
  _make_fields_node(
    _syntax_kind(176),
    [_node_ref_field("body", Some(body)), _node_list_field("modifiers", None)],
    transform_flags=_propagate_child_flags(Some(body)).union(
      TransformFlags::contains_class_fields(),
    ),
  )
}

///|
fn _factory_create_constructor_declaration(
  modifiers : NodeArray?,
  parameters : NodeArray,
  body : Node?,
) -> Node {
  let flags = match body {
    None => TransformFlags::contains_typescript()
    Some(body) =>
      _propagate_children_flags(modifiers)
      .union(_propagate_children_flags(Some(parameters)))
      .union(
        _propagate_child_flags(Some(body)).without(
          TransformFlags::contains_possible_top_level_await(),
        ),
      )
      .union(TransformFlags::contains_es2015())
  }
  _make_fields_node(
    _syntax_kind(177),
    [
      _node_list_field("modifiers", modifiers),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("body", body),
      _node_list_field("typeParameters", None),
      _node_ref_field("type", None),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_get_accessor_declaration(
  modifiers : NodeArray?,
  name : Node,
  parameters : NodeArray,
  type_node : Node?,
  body : Node?,
) -> Node {
  let flags = match body {
    None => TransformFlags::contains_typescript()
    Some(body) => {
      let mut result = _propagate_children_flags(modifiers)
        .union(_propagate_name_flags(Some(name)))
        .union(_propagate_children_flags(Some(parameters)))
        .union(_propagate_child_flags(type_node))
        .union(
          _propagate_child_flags(Some(body)).without(
            TransformFlags::contains_possible_top_level_await(),
          ),
        )
      if type_node is Some(_) {
        result = result.union(TransformFlags::contains_typescript())
      }
      result
    }
  }
  _make_fields_node(
    _syntax_kind(178),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_ref_field("body", body),
      _node_list_field("typeArguments", None),
      _node_list_field("typeParameters", None),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_set_accessor_declaration(
  modifiers : NodeArray?,
  name : Node,
  parameters : NodeArray,
  body : Node?,
) -> Node {
  let flags = match body {
    None => TransformFlags::contains_typescript()
    Some(body) =>
      _propagate_children_flags(modifiers)
      .union(_propagate_name_flags(Some(name)))
      .union(_propagate_children_flags(Some(parameters)))
      .union(
        _propagate_child_flags(Some(body)).without(
          TransformFlags::contains_possible_top_level_await(),
        ),
      )
  }
  _make_fields_node(
    _syntax_kind(179),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("name", Some(name)),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("body", body),
      _node_list_field("typeArguments", None),
      _node_list_field("typeParameters", None),
      _node_ref_field("type", None),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_call_signature(
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(180),
    [
      _node_list_field("typeParameters", type_parameters),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_construct_signature(
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(181),
    [
      _node_list_field("typeParameters", type_parameters),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_index_signature(
  modifiers : NodeArray?,
  parameters : NodeArray,
  type_node : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(182),
    [
      _node_list_field("modifiers", modifiers),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_template_literal_type_span(
  type_node : Node,
  literal : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(205),
    [
      _node_ref_field("type", Some(type_node)),
      _node_ref_field("literal", Some(literal)),
    ],
    transform_flags=TransformFlags::contains_typescript(),
  )
}
