// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts, src/compiler/utilities.ts, and
// src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _factory_create_object_binding_pattern(elements : NodeArray) -> Node {
  let mut flags = _propagate_children_flags(Some(elements))
    .union(TransformFlags::contains_es2015())
    .union(TransformFlags::contains_binding_pattern())
  if flags.intersect(TransformFlags::contains_rest_or_spread()).bits() != 0U {
    flags = flags
      .union(TransformFlags::contains_es2018())
      .union(TransformFlags::contains_object_rest_or_spread())
  }
  _make_fields_node(
    _syntax_kind(207),
    [_node_list_field("elements", Some(elements))],
    transform_flags=flags,
  )
}

///|
fn _factory_create_array_binding_pattern(elements : NodeArray) -> Node {
  _make_fields_node(
    _syntax_kind(208),
    [_node_list_field("elements", Some(elements))],
    transform_flags=_propagate_children_flags(Some(elements))
      .union(TransformFlags::contains_es2015())
      .union(TransformFlags::contains_binding_pattern()),
  )
}

///|
fn _factory_create_binding_element(
  dot_dot_dot_token : Node?,
  property_name : Node?,
  name : Node,
  initializer : Node?,
) -> Node {
  let mut flags = _propagate_child_flags(dot_dot_dot_token)
    .union(_propagate_name_flags(property_name))
    .union(_propagate_name_flags(Some(name)))
    .union(_propagate_child_flags(initializer))
    .union(TransformFlags::contains_es2015())
  if dot_dot_dot_token is Some(_) {
    flags = flags.union(TransformFlags::contains_rest_or_spread())
  }
  _make_fields_node(
    _syntax_kind(209),
    [
      _node_ref_field("dotDotDotToken", dot_dot_dot_token),
      _node_ref_field("propertyName", property_name),
      _node_ref_field("name", Some(name)),
      _node_ref_field("initializer", initializer),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_array_literal_expression(
  elements : NodeArray?,
  multi_line? : Bool,
) -> Node {
  let elements = match elements {
    None => _create_node_array([])
    Some(elements) => {
      let last_is_omitted = match elements.get(elements.length() - 1) {
        Some(last) => last.kind().to_int() == 233
        None => false
      }
      if last_is_omitted {
        _create_node_array_from_node_array(elements, has_trailing_comma=true)
      } else {
        elements
      }
    }
  }
  _make_fields_node(
    _syntax_kind(210),
    [
      _node_list_field("elements", Some(elements)),
      _boolean_field("multiLine", multi_line),
    ],
    transform_flags=_propagate_children_flags(Some(elements)),
  )
}

///|
fn _factory_create_object_literal_expression(
  properties : NodeArray?,
  multi_line? : Bool,
) -> Node {
  let properties = _node_array_or_empty(properties)
  _make_fields_node(
    _syntax_kind(211),
    [
      _node_list_field("properties", Some(properties)),
      _boolean_field("multiLine", multi_line),
    ],
    transform_flags=_propagate_children_flags(Some(properties)),
  )
}

///|
fn _factory_create_base_property_access_expression(
  expression : Node,
  question_dot_token : Node?,
  name : Node,
) -> Node {
  let name_flags = if _is_identifier(name) {
    _propagate_identifier_name_flags(name)
  } else {
    _propagate_child_flags(Some(name)).union(
      TransformFlags::contains_private_identifier_in_expression(),
    )
  }
  _make_fields_node(
    _syntax_kind(212),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("questionDotToken", question_dot_token),
      _node_ref_field("name", Some(name)),
    ],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(_propagate_child_flags(question_dot_token))
      .union(name_flags),
  )
}

///|
fn _factory_create_property_access_expression(
  expression : Node,
  name : Node,
) -> Node {
  let node = _factory_create_base_property_access_expression(
    expression,
    None,
    name,
  )
  if expression.kind().to_int() == 108 {
    node._add_transform_flags(
      TransformFlags::contains_es2017().union(TransformFlags::contains_es2018()),
    )
  }
  node
}

///|
fn _factory_create_property_access_chain(
  expression : Node,
  question_dot_token : Node?,
  name : Node,
) -> Node {
  let node = _factory_create_base_property_access_expression(
    expression, question_dot_token, name,
  )
  node._add_flags(NodeFlags::optional_chain())
  node._add_transform_flags(TransformFlags::contains_es2020())
  node
}

///|
fn _factory_create_base_element_access_expression(
  expression : Node,
  question_dot_token : Node?,
  argument_expression : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(213),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("questionDotToken", question_dot_token),
      _node_ref_field("argumentExpression", Some(argument_expression)),
    ],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(_propagate_child_flags(question_dot_token))
      .union(_propagate_child_flags(Some(argument_expression))),
  )
}

///|
fn _factory_create_element_access_expression(
  expression : Node,
  argument_expression : Node,
) -> Node {
  let node = _factory_create_base_element_access_expression(
    expression,
    None,
    argument_expression,
  )
  if expression.kind().to_int() == 108 {
    node._add_transform_flags(
      TransformFlags::contains_es2017().union(TransformFlags::contains_es2018()),
    )
  }
  node
}

///|
fn _factory_create_element_access_chain(
  expression : Node,
  question_dot_token : Node?,
  argument_expression : Node,
) -> Node {
  let node = _factory_create_base_element_access_expression(
    expression, question_dot_token, argument_expression,
  )
  node._add_flags(NodeFlags::optional_chain())
  node._add_transform_flags(TransformFlags::contains_es2020())
  node
}

///|
fn _is_super_property(node : Node) -> Bool {
  if node.kind().to_int() != 212 && node.kind().to_int() != 213 {
    return false
  }
  match node.field("expression") {
    Some(NodeRef(Some(expression))) => expression.kind().to_int() == 108
    _ => false
  }
}

///|
fn _factory_create_base_call_expression(
  expression : Node,
  question_dot_token : Node?,
  type_arguments : NodeArray?,
  arguments : NodeArray,
) -> Node {
  let mut flags = _propagate_child_flags(Some(expression))
    .union(_propagate_child_flags(question_dot_token))
    .union(_propagate_children_flags(type_arguments))
    .union(_propagate_children_flags(Some(arguments)))
  if type_arguments is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  if _is_super_property(expression) {
    flags = flags.union(TransformFlags::contains_lexical_this())
  }
  _make_fields_node(
    _syntax_kind(214),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("questionDotToken", question_dot_token),
      _node_list_field("typeArguments", type_arguments),
      _node_list_field("arguments", Some(arguments)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_call_expression(
  expression : Node,
  type_arguments : NodeArray?,
  arguments : NodeArray?,
) -> Node {
  let node = _factory_create_base_call_expression(
    expression,
    None,
    type_arguments,
    _node_array_or_empty(arguments),
  )
  if expression.kind().to_int() == 102 {
    node._add_transform_flags(TransformFlags::contains_dynamic_import())
  }
  node
}

///|
fn _factory_create_call_chain(
  expression : Node,
  question_dot_token : Node?,
  type_arguments : NodeArray?,
  arguments : NodeArray?,
) -> Node {
  let node = _factory_create_base_call_expression(
    expression,
    question_dot_token,
    type_arguments,
    _node_array_or_empty(arguments),
  )
  node._add_flags(NodeFlags::optional_chain())
  node._add_transform_flags(TransformFlags::contains_es2020())
  node
}

///|
fn _factory_create_new_expression(
  expression : Node,
  type_arguments : NodeArray?,
  arguments : NodeArray?,
) -> Node {
  let mut flags = _propagate_child_flags(Some(expression))
    .union(_propagate_children_flags(type_arguments))
    .union(_propagate_children_flags(arguments))
    .union(TransformFlags::contains_es2020())
  if type_arguments is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  _make_fields_node(
    _syntax_kind(215),
    [
      _node_ref_field("expression", Some(expression)),
      _node_list_field("typeArguments", type_arguments),
      _node_list_field("arguments", arguments),
    ],
    transform_flags=flags,
  )
}

///|
fn _template_token_has_invalid_escape(node : Node) -> Bool {
  match node.field("templateFlags") {
    Some(TokenFlagSet(flags)) =>
      flags.intersect(TokenFlags::contains_invalid_escape()).bits() != 0U
    _ => false
  }
}

///|
fn _template_has_invalid_escape(template : Node) -> Bool {
  if template.kind().to_int() == 15 {
    return _template_token_has_invalid_escape(template)
  }
  match template.field("head") {
    Some(NodeRef(Some(head))) if _template_token_has_invalid_escape(head) =>
      return true
    _ => ()
  }
  match template.field("templateSpans") {
    Some(NodeList(Some(spans))) =>
      for span in spans.elements() {
        match span.field("literal") {
          Some(NodeRef(Some(literal))) if _template_token_has_invalid_escape(
              literal,
            ) => return true
          _ => ()
        }
      }
    _ => ()
  }
  false
}

///|
fn _factory_create_tagged_template_expression(
  tag : Node,
  type_arguments : NodeArray?,
  template : Node,
) -> Node {
  let mut flags = _propagate_child_flags(Some(tag))
    .union(_propagate_children_flags(type_arguments))
    .union(_propagate_child_flags(Some(template)))
    .union(TransformFlags::contains_es2015())
  if type_arguments is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  if _template_has_invalid_escape(template) {
    flags = flags.union(TransformFlags::contains_es2018())
  }
  _make_fields_node(
    _syntax_kind(216),
    [
      _node_ref_field("tag", Some(tag)),
      _node_list_field("typeArguments", type_arguments),
      _node_ref_field("template", Some(template)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_type_assertion(type_node : Node, expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(217),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("type", Some(type_node)),
    ],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(_propagate_child_flags(Some(type_node)))
      .union(TransformFlags::contains_typescript()),
  )
}

///|
fn _factory_create_parenthesized_expression(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(218),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression)),
  )
}

///|
fn _factory_create_function_expression(
  modifiers : NodeArray?,
  asterisk_token : Node?,
  name : Node?,
  type_parameters : NodeArray?,
  parameters : NodeArray?,
  type_node : Node?,
  body : Node,
) -> Node {
  let parameters = _node_array_or_empty(parameters)
  let is_async = _has_modifier(modifiers, ModifierFlags::async_flag())
  let is_generator = asterisk_token is Some(_)
  let mut flags = _propagate_children_flags(modifiers)
    .union(_propagate_child_flags(asterisk_token))
    .union(_propagate_name_flags(name))
    .union(_propagate_children_flags(type_parameters))
    .union(_propagate_children_flags(Some(parameters)))
    .union(_propagate_child_flags(type_node))
    .union(
      _propagate_child_flags(Some(body)).without(
        TransformFlags::contains_possible_top_level_await(),
      ),
    )
  if is_async && is_generator {
    flags = flags.union(TransformFlags::contains_es2018())
  } else if is_async {
    flags = flags.union(TransformFlags::contains_es2017())
  } else if is_generator {
    flags = flags.union(TransformFlags::contains_generator())
  }
  if type_parameters is Some(_) || type_node is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  flags = flags.union(
    TransformFlags::contains_hoisted_declaration_or_completion(),
  )
  _make_fields_node(
    _syntax_kind(219),
    [
      _node_list_field("modifiers", modifiers),
      _node_ref_field("asteriskToken", asterisk_token),
      _node_ref_field("name", name),
      _node_list_field("typeParameters", type_parameters),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_ref_field("body", Some(body)),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_arrow_function(
  modifiers : NodeArray?,
  type_parameters : NodeArray?,
  parameters : NodeArray,
  type_node : Node?,
  equals_greater_than_token : Node?,
  body : Node,
) -> Node {
  let equals_greater_than_token = match equals_greater_than_token {
    Some(token) => token
    None => _factory_create_token(_syntax_kind(39))
  }
  let mut flags = _propagate_children_flags(modifiers)
    .union(_propagate_children_flags(type_parameters))
    .union(_propagate_children_flags(Some(parameters)))
    .union(_propagate_child_flags(type_node))
    .union(_propagate_child_flags(Some(equals_greater_than_token)))
    .union(
      _propagate_child_flags(Some(body)).without(
        TransformFlags::contains_possible_top_level_await(),
      ),
    )
  if type_parameters is Some(_) || type_node is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  if _has_modifier(modifiers, ModifierFlags::async_flag()) {
    flags = flags
      .union(TransformFlags::contains_es2017())
      .union(TransformFlags::contains_lexical_this())
  }
  flags = flags.union(TransformFlags::contains_es2015())
  _make_fields_node(
    _syntax_kind(220),
    [
      _node_list_field("modifiers", modifiers),
      _node_list_field("typeParameters", type_parameters),
      _node_list_field("parameters", Some(parameters)),
      _node_ref_field("type", type_node),
      _node_ref_field("equalsGreaterThanToken", Some(equals_greater_than_token)),
      _node_ref_field("body", Some(body)),
      _node_list_field("typeArguments", None),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_unary_expression(kind : Int, expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(kind),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression)),
  )
}

///|
fn _factory_create_delete_expression(expression : Node) -> Node {
  _factory_create_unary_expression(221, expression)
}

///|
fn _factory_create_type_of_expression(expression : Node) -> Node {
  _factory_create_unary_expression(222, expression)
}

///|
fn _factory_create_void_expression(expression : Node) -> Node {
  _factory_create_unary_expression(223, expression)
}

///|
fn _factory_create_await_expression(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(224),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(TransformFlags::contains_es2017())
      .union(TransformFlags::contains_es2018())
      .union(TransformFlags::contains_await()),
  )
}

///|
fn _factory_create_prefix_unary_expression(
  operator : SyntaxKind,
  operand : Node,
) -> Node {
  let mut flags = _propagate_child_flags(Some(operand))
  if (operator.to_int() == 46 || operator.to_int() == 47) &&
    operand.kind().to_int() == 80 {
    flags = flags.union(
      TransformFlags::contains_update_expression_for_identifier(),
    )
  }
  _make_fields_node(
    _syntax_kind(225),
    [
      _kind_field("operator", Some(operator)),
      _node_ref_field("operand", Some(operand)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_postfix_unary_expression(
  operand : Node,
  operator : SyntaxKind,
) -> Node {
  let mut flags = _propagate_child_flags(Some(operand))
  if operand.kind().to_int() == 80 {
    flags = flags.union(
      TransformFlags::contains_update_expression_for_identifier(),
    )
  }
  _make_fields_node(
    _syntax_kind(226),
    [
      _kind_field("operator", Some(operator)),
      _node_ref_field("operand", Some(operand)),
    ],
    transform_flags=flags,
  )
}

///|
fn _contains_object_rest_or_spread(root : Node) -> Bool {
  let stack = [root]
  while stack.length() > 0 {
    match stack.pop() {
      Some(node) => {
        if node
          .transform_flags()
          .intersect(TransformFlags::contains_object_rest_or_spread())
          .bits() !=
          0U {
          return true
        }
        match node.children() {
          Some(children) =>
            for child in children.elements() {
              stack.push(child)
            }
          None => ()
        }
      }
      None => ()
    }
  }
  false
}

///|
fn _factory_create_binary_expression(
  left : Node,
  operator_token : Node,
  right : Node,
) -> Node {
  let operator = operator_token.kind().to_int()
  let mut flags = _propagate_child_flags(Some(left))
    .union(_propagate_child_flags(Some(operator_token)))
    .union(_propagate_child_flags(Some(right)))
  if operator == 61 {
    flags = flags.union(TransformFlags::contains_es2020())
  } else if operator == 64 {
    if left.kind().to_int() == 211 {
      flags = flags
        .union(TransformFlags::contains_es2015())
        .union(TransformFlags::contains_es2018())
        .union(TransformFlags::contains_destructuring_assignment())
      if _contains_object_rest_or_spread(left) {
        flags = flags.union(TransformFlags::contains_object_rest_or_spread())
      }
    } else if left.kind().to_int() == 210 {
      flags = flags
        .union(TransformFlags::contains_es2015())
        .union(TransformFlags::contains_destructuring_assignment())
      if _contains_object_rest_or_spread(left) {
        flags = flags.union(TransformFlags::contains_object_rest_or_spread())
      }
    }
  } else if operator == 43 || operator == 68 {
    flags = flags.union(TransformFlags::contains_es2016())
  } else if operator == 76 || operator == 77 || operator == 78 {
    flags = flags.union(TransformFlags::contains_es2021())
  }
  if operator == 103 && left.kind().to_int() == 81 {
    flags = flags.union(
      TransformFlags::contains_private_identifier_in_expression(),
    )
  }
  _make_fields_node(
    _syntax_kind(227),
    [
      _node_ref_field("left", Some(left)),
      _node_ref_field("operatorToken", Some(operator_token)),
      _node_ref_field("right", Some(right)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_conditional_expression(
  condition : Node,
  question_token : Node?,
  when_true : Node,
  colon_token : Node?,
  when_false : Node,
) -> Node {
  let question_token = match question_token {
    Some(token) => token
    None => _factory_create_token(_syntax_kind(58))
  }
  let colon_token = match colon_token {
    Some(token) => token
    None => _factory_create_token(_syntax_kind(59))
  }
  _make_fields_node(
    _syntax_kind(228),
    [
      _node_ref_field("condition", Some(condition)),
      _node_ref_field("questionToken", Some(question_token)),
      _node_ref_field("whenTrue", Some(when_true)),
      _node_ref_field("colonToken", Some(colon_token)),
      _node_ref_field("whenFalse", Some(when_false)),
    ],
    transform_flags=_propagate_child_flags(Some(condition))
      .union(_propagate_child_flags(Some(question_token)))
      .union(_propagate_child_flags(Some(when_true)))
      .union(_propagate_child_flags(Some(colon_token)))
      .union(_propagate_child_flags(Some(when_false))),
  )
}

///|
fn _factory_create_template_expression(
  head : Node,
  template_spans : NodeArray,
) -> Node {
  _make_fields_node(
    _syntax_kind(229),
    [
      _node_ref_field("head", Some(head)),
      _node_list_field("templateSpans", Some(template_spans)),
    ],
    transform_flags=_propagate_child_flags(Some(head))
      .union(_propagate_children_flags(Some(template_spans)))
      .union(TransformFlags::contains_es2015()),
  )
}

///|
fn _factory_create_yield_expression(
  asterisk_token : Node?,
  expression : Node?,
) -> Node {
  guard asterisk_token is None || expression is Some(_) else {
    abort("yield* requires an expression")
  }
  _make_fields_node(
    _syntax_kind(230),
    [
      _node_ref_field("expression", expression),
      _node_ref_field("asteriskToken", asterisk_token),
    ],
    transform_flags=_propagate_child_flags(expression)
      .union(_propagate_child_flags(asterisk_token))
      .union(TransformFlags::contains_es2015())
      .union(TransformFlags::contains_es2018())
      .union(TransformFlags::contains_yield()),
  )
}

///|
fn _factory_create_spread_element(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(231),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(TransformFlags::contains_es2015())
      .union(TransformFlags::contains_rest_or_spread()),
  )
}

///|
fn _factory_create_class_expression(
  modifiers : NodeArray?,
  name : Node?,
  type_parameters : NodeArray?,
  heritage_clauses : NodeArray?,
  members : NodeArray,
) -> Node {
  let mut flags = _propagate_children_flags(modifiers)
    .union(_propagate_name_flags(name))
    .union(_propagate_children_flags(type_parameters))
    .union(_propagate_children_flags(heritage_clauses))
    .union(_propagate_children_flags(Some(members)))
    .union(TransformFlags::contains_es2015())
  if type_parameters is Some(_) {
    flags = flags.union(TransformFlags::contains_typescript())
  }
  _make_fields_node(
    _syntax_kind(232),
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
fn _factory_create_omitted_expression() -> Node {
  _make_fields_node(_syntax_kind(233), [])
}

///|
fn _factory_create_expression_with_type_arguments(
  expression : Node,
  type_arguments : NodeArray?,
) -> Node {
  _make_fields_node(
    _syntax_kind(234),
    [
      _node_ref_field("expression", Some(expression)),
      _node_list_field("typeArguments", type_arguments),
    ],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(_propagate_children_flags(type_arguments))
      .union(TransformFlags::contains_es2015()),
  )
}

///|
fn _factory_create_as_expression(expression : Node, type_node : Node) -> Node {
  _make_fields_node(
    _syntax_kind(235),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("type", Some(type_node)),
    ],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(_propagate_child_flags(Some(type_node)))
      .union(TransformFlags::contains_typescript()),
  )
}

///|
fn _factory_create_non_null_expression(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(236),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression)).union(
      TransformFlags::contains_typescript(),
    ),
  )
}

///|
fn _factory_create_satisfies_expression(
  expression : Node,
  type_node : Node,
) -> Node {
  _make_fields_node(
    _syntax_kind(239),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("type", Some(type_node)),
    ],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(_propagate_child_flags(Some(type_node)))
      .union(TransformFlags::contains_typescript()),
  )
}

///|
fn _factory_create_meta_property(
  keyword_token : SyntaxKind,
  name : Node,
) -> Node {
  let own_flags = match keyword_token.to_int() {
    105 => TransformFlags::contains_es2015()
    102 => TransformFlags::contains_es2020()
    _ => abort("invalid meta-property keyword")
  }
  _make_fields_node(
    _syntax_kind(237),
    [
      _kind_field("keywordToken", Some(keyword_token)),
      _node_ref_field("name", Some(name)),
    ],
    transform_flags=_propagate_child_flags(Some(name)).union(own_flags),
  )
}

///|
fn _factory_create_template_span(expression : Node, literal : Node) -> Node {
  _make_fields_node(
    _syntax_kind(240),
    [
      _node_ref_field("expression", Some(expression)),
      _node_ref_field("literal", Some(literal)),
    ],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(_propagate_child_flags(Some(literal)))
      .union(TransformFlags::contains_es2015()),
  )
}

///|
fn _factory_create_semicolon_class_element() -> Node {
  _make_fields_node(
    _syntax_kind(241),
    [],
    transform_flags=TransformFlags::contains_es2015(),
  )
}
