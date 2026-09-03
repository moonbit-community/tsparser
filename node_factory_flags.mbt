// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _is_identifier(node : Node) -> Bool {
  node.kind().to_int() == 80
}

///|
fn _is_property_name(node : Node) -> Bool {
  match node.kind().to_int() {
    9 | 11 | 80 | 81 | 168 => true
    _ => false
  }
}

///|
fn _get_transform_flags_subtree_exclusions(kind : SyntaxKind) -> TransformFlags {
  let value = kind.to_int()
  if value >= 183 && value <= 206 {
    return TransformFlags::type_excludes()
  }
  match value {
    210 | 214 | 215 => TransformFlags::array_literal_or_call_or_new_excludes()
    268 => TransformFlags::module_excludes()
    170 => TransformFlags::parameter_excludes()
    220 => TransformFlags::arrow_function_excludes()
    219 | 263 => TransformFlags::function_excludes()
    262 => TransformFlags::variable_declaration_list_excludes()
    232 | 264 => TransformFlags::class_excludes()
    177 => TransformFlags::constructor_excludes()
    173 => TransformFlags::property_excludes()
    175 | 178 | 179 => TransformFlags::method_or_accessor_excludes()
    116
    | 133
    | 136
    | 146
    | 150
    | 151
    | 154
    | 155
    | 163
    | 169
    | 172
    | 174
    | 180
    | 181
    | 182
    | 265
    | 266 => TransformFlags::type_excludes()
    211 => TransformFlags::object_literal_excludes()
    300 => TransformFlags::catch_clause_excludes()
    207 | 208 => TransformFlags::binding_pattern_excludes()
    108 | 217 | 218 | 235 | 239 | 356 =>
      TransformFlags::outer_expression_excludes()
    212 | 213 => TransformFlags::property_access_excludes()
    _ => TransformFlags::node_excludes()
  }
}

///|
fn _property_name_of_named_child(child : Node) -> Node? {
  match child.field("name") {
    Some(NodeRef(Some(name))) if _is_property_name(name) => Some(name)
    _ => None
  }
}

///|
fn _propagate_property_name_flags_of_child(
  name : Node,
  transform_flags : TransformFlags,
) -> TransformFlags {
  transform_flags.union(
    name
    .transform_flags()
    .intersect(TransformFlags::property_name_propagating_flags()),
  )
}

///|
fn _propagate_child_flags(child : Node?) -> TransformFlags {
  match child {
    None => TransformFlags::none()
    Some(child) => {
      let child_flags = child
        .transform_flags()
        .without(_get_transform_flags_subtree_exclusions(child.kind()))
      match _property_name_of_named_child(child) {
        Some(name) => _propagate_property_name_flags_of_child(name, child_flags)
        None => child_flags
      }
    }
  }
}

///|
fn _propagate_children_flags(children : NodeArray?) -> TransformFlags {
  match children {
    Some(children) => children.transform_flags()
    None => TransformFlags::none()
  }
}

///|
fn _propagate_identifier_name_flags(node : Node) -> TransformFlags {
  _propagate_child_flags(Some(node)).without(
    TransformFlags::contains_possible_top_level_await(),
  )
}

///|
fn _propagate_name_flags(node : Node?) -> TransformFlags {
  match node {
    Some(node) if _is_identifier(node) => _propagate_identifier_name_flags(node)
    _ => _propagate_child_flags(node)
  }
}

///|
fn _aggregate_children_flags(elements : ReadOnlyArray[Node]) -> TransformFlags {
  let mut flags = TransformFlags::none()
  for child in elements {
    flags = flags.union(_propagate_child_flags(Some(child)))
  }
  flags
}

///|
fn _modifier_to_flag(kind : SyntaxKind) -> ModifierFlags {
  match kind.to_int() {
    126 => ModifierFlags::static_flag()
    125 => ModifierFlags::public_flag()
    124 => ModifierFlags::protected_flag()
    123 => ModifierFlags::private_flag()
    128 => ModifierFlags::abstract_flag()
    129 => ModifierFlags::accessor()
    95 => ModifierFlags::export_flag()
    138 => ModifierFlags::ambient()
    87 => ModifierFlags::const_flag()
    90 => ModifierFlags::default_flag()
    134 => ModifierFlags::async_flag()
    148 => ModifierFlags::readonly_flag()
    164 => ModifierFlags::override_flag()
    103 => ModifierFlags::in_flag()
    147 => ModifierFlags::out_flag()
    171 => ModifierFlags::decorator()
    _ => ModifierFlags::none()
  }
}

///|
fn _modifiers_to_flags(modifiers : NodeArray?) -> ModifierFlags {
  let mut flags = ModifierFlags::none()
  match modifiers {
    Some(modifiers) =>
      for modifier in modifiers.elements() {
        flags = flags.union(_modifier_to_flag(modifier.kind()))
      }
    None => ()
  }
  flags
}

///|
fn _has_modifier(modifiers : NodeArray?, flag : ModifierFlags) -> Bool {
  _modifiers_to_flags(modifiers).intersect(flag).bits() != 0U
}

///|
fn _node_array_or_empty(elements : NodeArray?) -> NodeArray {
  match elements {
    Some(elements) => elements
    None => _create_node_array([])
  }
}

///|
/// Parser-facing equivalent of `NodeFactory.createNodeArray` for a mutable
/// builder list. The input array is copied and cannot be mutated through the
/// returned value.
fn _create_node_array(
  elements : Array[Node],
  has_trailing_comma? : Bool = false,
) -> NodeArray {
  let frozen = ReadOnlyArray::from_array(elements)
  {
    elements: frozen,
    pos: -1,
    end: -1,
    has_trailing_comma,
    transform_flags: _aggregate_children_flags(frozen),
  }
}

///|
/// Reuses an existing NodeArray when its trailing-comma metadata already
/// matches, exactly as the upstream factory does.
fn _create_node_array_from_node_array(
  elements : NodeArray,
  has_trailing_comma? : Bool = false,
) -> NodeArray {
  if elements.has_trailing_comma() == has_trailing_comma {
    return elements
  }
  let copied : Array[Node] = []
  for element in elements.elements() {
    copied.push(element)
  }
  _make_node_array(
    copied,
    elements.pos(),
    elements.end(),
    has_trailing_comma,
    elements.transform_flags(),
  )
}
