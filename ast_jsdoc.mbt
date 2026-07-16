// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts, src/compiler/factory/utilities.ts, and
// src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
priv enum JSDocCommentInput {
  CommentText(String)
  CommentNodes(NodeArray)
}

///|
fn _jsdoc_comment_text(text : String) -> JSDocCommentInput {
  CommentText(text)
}

///|
fn _jsdoc_comment_nodes(nodes : NodeArray) -> JSDocCommentInput {
  CommentNodes(nodes)
}

///|
fn _jsdoc_comment_field(comment : JSDocCommentInput?) -> NodeField {
  match comment {
    None => _text_field("comment", None)
    Some(CommentText(text)) => _text_field("comment", Some(text))
    Some(CommentNodes(nodes)) => _node_list_field("comment", Some(nodes))
  }
}

///|
fn _jsdoc_default_tag_name(kind : Int) -> String {
  match kind {
    329 => "augments"
    330 => "implements"
    331 => "author"
    332 => "deprecated"
    333 => "class"
    334 => "public"
    335 => "private"
    336 => "protected"
    337 => "readonly"
    338 => "override"
    339 => "callback"
    340 => "overload"
    341 => "enum"
    342 => "param"
    343 => "returns"
    344 => "this"
    345 => "type"
    346 => "template"
    347 => "typedef"
    348 => "see"
    349 => "prop"
    350 => "throws"
    351 => "satisfies"
    352 => "import"
    _ => abort("unsupported JSDoc tag kind")
  }
}

///|
fn _jsdoc_tag_name(kind : Int, tag_name : Node?) -> Node {
  match tag_name {
    Some(tag_name) => tag_name
    None => _factory_create_identifier(_jsdoc_default_tag_name(kind))
  }
}

///|
fn _factory_create_jsdoc_all_type() -> Node {
  _make_fields_node(_syntax_kind(313), [])
}

///|
fn _factory_create_jsdoc_unknown_type() -> Node {
  _make_fields_node(_syntax_kind(314), [])
}

///|
fn _factory_create_jsdoc_nullable_type(
  type_node : Node?,
  postfix? : Bool = false,
) -> Node {
  _make_fields_node(_syntax_kind(315), [
    _node_ref_field("type", type_node),
    _boolean_field("postfix", Some(postfix)),
  ])
}

///|
fn _factory_create_jsdoc_non_nullable_type(
  type_node : Node?,
  postfix? : Bool = false,
) -> Node {
  _make_fields_node(_syntax_kind(316), [
    _node_ref_field("type", type_node),
    _boolean_field("postfix", Some(postfix)),
  ])
}

///|
fn _factory_create_jsdoc_optional_type(type_node : Node?) -> Node {
  _make_fields_node(_syntax_kind(317), [_node_ref_field("type", type_node)])
}

///|
fn _factory_create_jsdoc_function_type(
  parameters : NodeArray,
  type_node : Node?,
) -> Node {
  let mut flags = _propagate_children_flags(Some(parameters))
  if type_node is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  _make_fields_node(
    _syntax_kind(318),
    [
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_jsdoc_variadic_type(type_node : Node?) -> Node {
  _make_fields_node(_syntax_kind(319), [_node_ref_field("type", type_node)])
}

///|
fn _factory_create_jsdoc_namepath_type(type_node : Node?) -> Node {
  _make_fields_node(_syntax_kind(320), [_node_ref_field("type", type_node)])
}

///|
fn _factory_create_jsdoc_type_expression(type_node : Node) -> Node {
  _make_fields_node(_syntax_kind(310), [
    _node_ref_field("type", Some(type_node)),
  ])
}

///|
fn _factory_create_jsdoc_type_literal(
  property_tags : NodeArray?,
  is_array_type? : Bool = false,
) -> Node {
  _make_fields_node(_syntax_kind(323), [
    _node_list_field("jsDocPropertyTags", property_tags),
    _boolean_field("isArrayType", Some(is_array_type)),
  ])
}

///|
fn _factory_create_jsdoc_signature(
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node?,
) -> Node {
  _make_fields_node(_syntax_kind(324), [
    _node_list_field("typeParameters", type_parameters),
    _node_list_field("parameters", Some(parameters)),
    _node_ref_field("type", type_node),
  ])
}

///|
fn _factory_create_jsdoc_name_reference(name : Node) -> Node {
  _make_fields_node(_syntax_kind(311), [_node_ref_field("name", Some(name))])
}

///|
fn _factory_create_jsdoc_member_name(left : Node, right : Node) -> Node {
  _make_fields_node(
    _syntax_kind(312),
    [_node_ref_field("left", Some(left)), _node_ref_field("right", Some(right))],
    transform_flags=_propagate_child_flags(Some(left)).union(
      _propagate_child_flags(Some(right)),
    ),
  )
}

///|
fn _factory_create_jsdoc_link_node(
  kind : Int,
  name : Node?,
  text : String,
) -> Node {
  _make_fields_node(_syntax_kind(kind), [
    _node_ref_field("name", name),
    _text_field("text", Some(text)),
  ])
}

///|
fn _factory_create_jsdoc_link(name : Node?, text : String) -> Node {
  _factory_create_jsdoc_link_node(325, name, text)
}

///|
fn _factory_create_jsdoc_link_code(name : Node?, text : String) -> Node {
  _factory_create_jsdoc_link_node(326, name, text)
}

///|
fn _factory_create_jsdoc_link_plain(name : Node?, text : String) -> Node {
  _factory_create_jsdoc_link_node(327, name, text)
}

///|
fn _jsdoc_base_tag_fields(
  kind : Int,
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Array[NodeField] {
  [
    _node_ref_field("tagName", Some(_jsdoc_tag_name(kind, tag_name))),
    _jsdoc_comment_field(comment),
  ]
}

///|
fn _factory_create_jsdoc_simple_tag(
  kind : Int,
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _make_fields_node(
    _syntax_kind(kind),
    _jsdoc_base_tag_fields(kind, tag_name, comment),
  )
}

///|
fn _factory_create_jsdoc_author_tag(
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_simple_tag(331, tag_name, comment)
}

///|
fn _factory_create_jsdoc_class_tag(
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_simple_tag(333, tag_name, comment)
}

///|
fn _factory_create_jsdoc_public_tag(
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_simple_tag(334, tag_name, comment)
}

///|
fn _factory_create_jsdoc_private_tag(
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_simple_tag(335, tag_name, comment)
}

///|
fn _factory_create_jsdoc_protected_tag(
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_simple_tag(336, tag_name, comment)
}

///|
fn _factory_create_jsdoc_readonly_tag(
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_simple_tag(337, tag_name, comment)
}

///|
fn _factory_create_jsdoc_override_tag(
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_simple_tag(338, tag_name, comment)
}

///|
fn _factory_create_jsdoc_deprecated_tag(
  tag_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_simple_tag(332, tag_name, comment)
}

///|
fn _factory_create_jsdoc_type_like_tag(
  kind : Int,
  tag_name : Node?,
  type_expression : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(kind, tag_name, comment)
  fields.push(_node_ref_field("typeExpression", type_expression))
  _make_fields_node(_syntax_kind(kind), fields)
}

///|
fn _factory_create_jsdoc_type_tag(
  tag_name : Node?,
  type_expression : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_type_like_tag(345, tag_name, type_expression, comment)
}

///|
fn _factory_create_jsdoc_return_tag(
  tag_name : Node?,
  type_expression : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_type_like_tag(343, tag_name, type_expression, comment)
}

///|
fn _factory_create_jsdoc_this_tag(
  tag_name : Node?,
  type_expression : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_type_like_tag(344, tag_name, type_expression, comment)
}

///|
fn _factory_create_jsdoc_throws_tag(
  tag_name : Node?,
  type_expression : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_type_like_tag(350, tag_name, type_expression, comment)
}

///|
fn _factory_create_jsdoc_satisfies_tag(
  tag_name : Node?,
  type_expression : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_type_like_tag(351, tag_name, type_expression, comment)
}

///|
fn _factory_create_jsdoc_template_tag(
  tag_name : Node?,
  constraint : Node?,
  type_parameters : NodeArray,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(346, tag_name, comment)
  fields.push(_node_ref_field("constraint", constraint))
  fields.push(_node_list_field("typeParameters", Some(type_parameters)))
  _make_fields_node(_syntax_kind(346), fields)
}

///|
fn _jsdoc_type_alias_name(full_name : Node?) -> Node? {
  let mut current = full_name
  while current is Some(_) {
    guard current is Some(node) else { abort("unreachable JSDoc alias") }
    if node.kind().to_int() == 80 {
      return Some(node)
    }
    match node.field("body") {
      Some(NodeRef(Some(body))) => current = Some(body)
      _ =>
        return match node.field("name") {
          Some(NodeRef(name)) => name
          _ => None
        }
    }
  }
  None
}

///|
fn _factory_create_jsdoc_typedef_tag(
  tag_name : Node?,
  type_expression : Node?,
  full_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(347, tag_name, comment)
  fields.push(_node_ref_field("typeExpression", type_expression))
  fields.push(_node_ref_field("fullName", full_name))
  fields.push(_node_ref_field("name", _jsdoc_type_alias_name(full_name)))
  _make_fields_node(_syntax_kind(347), fields)
}

///|
fn _factory_create_jsdoc_property_like_tag(
  kind : Int,
  tag_name : Node?,
  name : Node,
  is_bracketed : Bool,
  type_expression : Node?,
  is_name_first? : Bool = false,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(kind, tag_name, comment)
  fields.push(_node_ref_field("typeExpression", type_expression))
  fields.push(_node_ref_field("name", Some(name)))
  fields.push(_boolean_field("isNameFirst", Some(is_name_first)))
  fields.push(_boolean_field("isBracketed", Some(is_bracketed)))
  _make_fields_node(_syntax_kind(kind), fields)
}

///|
fn _factory_create_jsdoc_parameter_tag(
  tag_name : Node?,
  name : Node,
  is_bracketed : Bool,
  type_expression : Node?,
  is_name_first? : Bool = false,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_property_like_tag(
    342,
    tag_name,
    name,
    is_bracketed,
    type_expression,
    is_name_first~,
    comment,
  )
}

///|
fn _factory_create_jsdoc_property_tag(
  tag_name : Node?,
  name : Node,
  is_bracketed : Bool,
  type_expression : Node?,
  is_name_first? : Bool = false,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_property_like_tag(
    349,
    tag_name,
    name,
    is_bracketed,
    type_expression,
    is_name_first~,
    comment,
  )
}

///|
fn _factory_create_jsdoc_callback_tag(
  tag_name : Node?,
  type_expression : Node,
  full_name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(339, tag_name, comment)
  fields.push(_node_ref_field("typeExpression", Some(type_expression)))
  fields.push(_node_ref_field("fullName", full_name))
  fields.push(_node_ref_field("name", _jsdoc_type_alias_name(full_name)))
  _make_fields_node(_syntax_kind(339), fields)
}

///|
fn _factory_create_jsdoc_overload_tag(
  tag_name : Node?,
  type_expression : Node,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(340, tag_name, comment)
  fields.push(_node_ref_field("typeExpression", Some(type_expression)))
  _make_fields_node(_syntax_kind(340), fields)
}

///|
fn _factory_create_jsdoc_class_reference_tag(
  kind : Int,
  tag_name : Node?,
  class_name : Node,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(kind, tag_name, comment)
  fields.push(_node_ref_field("class", Some(class_name)))
  _make_fields_node(_syntax_kind(kind), fields)
}

///|
fn _factory_create_jsdoc_augments_tag(
  tag_name : Node?,
  class_name : Node,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_class_reference_tag(329, tag_name, class_name, comment)
}

///|
fn _factory_create_jsdoc_implements_tag(
  tag_name : Node?,
  class_name : Node,
  comment : JSDocCommentInput?,
) -> Node {
  _factory_create_jsdoc_class_reference_tag(330, tag_name, class_name, comment)
}

///|
fn _factory_create_jsdoc_see_tag(
  tag_name : Node?,
  name : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(348, tag_name, comment)
  fields.push(_node_ref_field("name", name))
  _make_fields_node(_syntax_kind(348), fields)
}

///|
fn _factory_create_jsdoc_unknown_tag(
  tag_name : Node,
  comment : JSDocCommentInput?,
) -> Node {
  _make_fields_node(_syntax_kind(328), [
    _node_ref_field("tagName", Some(tag_name)),
    _jsdoc_comment_field(comment),
  ])
}

///|
fn _factory_create_jsdoc_enum_tag(
  tag_name : Node?,
  type_expression : Node,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(341, tag_name, comment)
  fields.push(_node_ref_field("typeExpression", Some(type_expression)))
  _make_fields_node(_syntax_kind(341), fields)
}

///|
fn _factory_create_jsdoc_import_tag(
  tag_name : Node?,
  import_clause : Node?,
  module_specifier : Node,
  attributes : Node?,
  comment : JSDocCommentInput?,
) -> Node {
  let fields = _jsdoc_base_tag_fields(352, tag_name, comment)
  fields.push(_node_ref_field("importClause", import_clause))
  fields.push(_node_ref_field("moduleSpecifier", Some(module_specifier)))
  fields.push(_node_ref_field("attributes", attributes))
  _make_fields_node(_syntax_kind(352), fields)
}

///|
fn _factory_create_jsdoc_text(text : String) -> Node {
  _make_fields_node(_syntax_kind(322), [_text_field("text", Some(text))])
}

///|
fn _factory_create_jsdoc_comment(
  comment : JSDocCommentInput?,
  tags : NodeArray?,
) -> Node {
  _make_fields_node(_syntax_kind(321), [
    _jsdoc_comment_field(comment),
    _node_list_field("tags", tags),
  ])
}
