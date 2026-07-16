// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _typescript_type_node(kind : Int, fields : Array[NodeField]) -> Node {
  _make_fields_node(
    _syntax_kind(kind),
    fields,
    transform_flags=TransformFlags::contains_typescript(),
  )
}

///|
fn _factory_create_type_predicate_node(
  asserts_modifier : Node?,
  parameter_name : Node,
  type_node : Node?,
) -> Node {
  _typescript_type_node(183, [
    _node_ref_field("assertsModifier", asserts_modifier),
    _node_ref_field("parameterName", Some(parameter_name)),
    _node_ref_field("type", type_node),
  ])
}

///|
fn _factory_create_type_reference_node(
  type_name : Node,
  type_arguments : NodeArray?,
) -> Node {
  _typescript_type_node(184, [
    _node_ref_field("typeName", Some(type_name)),
    _node_list_field("typeArguments", type_arguments),
  ])
}

///|
fn _factory_create_function_type_node(
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node,
) -> Node {
  _typescript_type_node(185, [
    _node_list_field("typeParameters", type_parameters),
    _node_list_field("parameters", Some(parameters)),
    _node_ref_field("type", Some(type_node)),
    _node_list_field("modifiers", None),
    _node_list_field("typeArguments", None),
  ])
}

///|
fn _factory_create_constructor_type_node(
  modifiers : NodeArray?,
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node,
) -> Node {
  _typescript_type_node(186, [
    _node_list_field("modifiers", modifiers),
    _node_list_field("typeParameters", type_parameters),
    _node_list_field("parameters", Some(parameters)),
    _node_ref_field("type", Some(type_node)),
    _node_list_field("typeArguments", None),
  ])
}

///|
fn _factory_create_type_query_node(
  expression_name : Node,
  type_arguments : NodeArray?,
) -> Node {
  _typescript_type_node(187, [
    _node_ref_field("exprName", Some(expression_name)),
    _node_list_field("typeArguments", type_arguments),
  ])
}

///|
fn _factory_create_type_literal_node(members : NodeArray?) -> Node {
  _typescript_type_node(188, [
    _node_list_field("members", Some(_node_array_or_empty(members))),
  ])
}

///|
fn _factory_create_array_type_node(element_type : Node) -> Node {
  _typescript_type_node(189, [
    _node_ref_field("elementType", Some(element_type)),
  ])
}

///|
fn _factory_create_tuple_type_node(elements : NodeArray) -> Node {
  _typescript_type_node(190, [_node_list_field("elements", Some(elements))])
}

///|
fn _factory_create_optional_type_node(type_node : Node) -> Node {
  _typescript_type_node(191, [_node_ref_field("type", Some(type_node))])
}

///|
fn _factory_create_rest_type_node(type_node : Node) -> Node {
  _typescript_type_node(192, [_node_ref_field("type", Some(type_node))])
}

///|
fn _factory_create_union_type_node(types : NodeArray) -> Node {
  _typescript_type_node(193, [_node_list_field("types", Some(types))])
}

///|
fn _factory_create_intersection_type_node(types : NodeArray) -> Node {
  _typescript_type_node(194, [_node_list_field("types", Some(types))])
}

///|
fn _factory_create_conditional_type_node(
  check_type : Node,
  extends_type : Node,
  true_type : Node,
  false_type : Node,
) -> Node {
  _typescript_type_node(195, [
    _node_ref_field("checkType", Some(check_type)),
    _node_ref_field("extendsType", Some(extends_type)),
    _node_ref_field("trueType", Some(true_type)),
    _node_ref_field("falseType", Some(false_type)),
  ])
}

///|
fn _factory_create_infer_type_node(type_parameter : Node) -> Node {
  _typescript_type_node(196, [
    _node_ref_field("typeParameter", Some(type_parameter)),
  ])
}

///|
fn _factory_create_parenthesized_type(type_node : Node) -> Node {
  _typescript_type_node(197, [_node_ref_field("type", Some(type_node))])
}

///|
fn _factory_create_this_type_node() -> Node {
  _typescript_type_node(198, [])
}

///|
fn _factory_create_type_operator_node(
  operator : SyntaxKind,
  type_node : Node,
) -> Node {
  _typescript_type_node(199, [
    _kind_field("operator", Some(operator)),
    _node_ref_field("type", Some(type_node)),
  ])
}

///|
fn _factory_create_indexed_access_type_node(
  object_type : Node,
  index_type : Node,
) -> Node {
  _typescript_type_node(200, [
    _node_ref_field("objectType", Some(object_type)),
    _node_ref_field("indexType", Some(index_type)),
  ])
}

///|
fn _factory_create_mapped_type_node(
  readonly_token : Node?,
  type_parameter : Node,
  name_type : Node?,
  question_token : Node?,
  type_node : Node?,
  members : NodeArray?,
) -> Node {
  _typescript_type_node(201, [
    _node_ref_field("readonlyToken", readonly_token),
    _node_ref_field("typeParameter", Some(type_parameter)),
    _node_ref_field("nameType", name_type),
    _node_ref_field("questionToken", question_token),
    _node_ref_field("type", type_node),
    _node_list_field("members", members),
  ])
}

///|
fn _factory_create_literal_type_node(literal : Node) -> Node {
  _typescript_type_node(202, [_node_ref_field("literal", Some(literal))])
}

///|
fn _factory_create_named_tuple_member(
  dot_dot_dot_token : Node?,
  name : Node,
  question_token : Node?,
  type_node : Node,
) -> Node {
  _typescript_type_node(203, [
    _node_ref_field("dotDotDotToken", dot_dot_dot_token),
    _node_ref_field("name", Some(name)),
    _node_ref_field("questionToken", question_token),
    _node_ref_field("type", Some(type_node)),
  ])
}

///|
fn _factory_create_template_literal_type(
  head : Node,
  template_spans : NodeArray,
) -> Node {
  _typescript_type_node(204, [
    _node_ref_field("head", Some(head)),
    _node_list_field("templateSpans", Some(template_spans)),
  ])
}

///|
fn _factory_create_import_type_node(
  argument : Node,
  attributes : Node?,
  qualifier : Node?,
  type_arguments : NodeArray?,
  is_type_of? : Bool = false,
) -> Node {
  _typescript_type_node(206, [
    _node_ref_field("argument", Some(argument)),
    _node_ref_field("attributes", attributes),
    _node_ref_field("qualifier", qualifier),
    _node_list_field("typeArguments", type_arguments),
    _boolean_field("isTypeOf", Some(is_type_of)),
  ])
}
