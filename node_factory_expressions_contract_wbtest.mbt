///|
test "binding and expression factory field contracts" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let block = _contract_block()
  let question_dot = _factory_create_token(_syntax_kind(29))
  let operator = _factory_create_token(_syntax_kind(64))
  let head = _factory_create_template_literal_like_node(_syntax_kind(16), "")
  let tail = _factory_create_template_literal_like_node(_syntax_kind(18), "")
  let span = _factory_create_template_span(id, tail)
  let template = _factory_create_template_expression(
    head,
    _create_node_array([span]),
  )

  _assert_factory_contract(
    "NodeFactory.createArrayBindingPattern",
    _factory_create_array_binding_pattern(empty),
    208,
    ["elements"],
  )
  _assert_factory_contract(
    "NodeFactory.createArrayLiteralExpression",
    _factory_create_array_literal_expression(Some(empty)),
    210,
    ["elements", "multiLine"],
  )
  _assert_factory_contract(
    "NodeFactory.createArrowFunction",
    _factory_create_arrow_function(None, None, empty, None, None, block),
    220,
    [
      "modifiers", "typeParameters", "parameters", "type", "equalsGreaterThanToken",
      "body", "typeArguments",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createAsExpression",
    _factory_create_as_expression(id, id),
    235,
    ["expression", "type"],
  )
  _assert_factory_contract(
    "NodeFactory.createAwaitExpression",
    _factory_create_await_expression(id),
    224,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createBinaryExpression",
    _factory_create_binary_expression(id, operator, id),
    227,
    ["left", "operatorToken", "right"],
  )
  _assert_factory_contract(
    "NodeFactory.createBindingElement",
    _factory_create_binding_element(None, None, id, None),
    209,
    ["dotDotDotToken", "propertyName", "name", "initializer"],
  )
  _assert_factory_contract(
    "NodeFactory.createCallChain",
    _factory_create_call_chain(id, Some(question_dot), None, None),
    214,
    ["expression", "questionDotToken", "typeArguments", "arguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createCallExpression",
    _factory_create_call_expression(id, None, None),
    214,
    ["expression", "questionDotToken", "typeArguments", "arguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createClassExpression",
    _factory_create_class_expression(None, None, None, None, empty),
    232,
    ["modifiers", "name", "typeParameters", "heritageClauses", "members"],
  )
  _assert_factory_contract(
    "NodeFactory.createConditionalExpression",
    _factory_create_conditional_expression(id, None, id, None, id),
    228,
    ["condition", "questionToken", "whenTrue", "colonToken", "whenFalse"],
  )
  _assert_factory_contract(
    "NodeFactory.createDeleteExpression",
    _factory_create_delete_expression(id),
    221,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createElementAccessChain",
    _factory_create_element_access_chain(id, Some(question_dot), id),
    213,
    ["expression", "questionDotToken", "argumentExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createElementAccessExpression",
    _factory_create_element_access_expression(id, id),
    213,
    ["expression", "questionDotToken", "argumentExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createExpressionWithTypeArguments",
    _factory_create_expression_with_type_arguments(id, None),
    234,
    ["expression", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createFunctionExpression",
    _factory_create_function_expression(
      None,
      None,
      None,
      None,
      None,
      None,
      block,
    ),
    219,
    [
      "modifiers", "asteriskToken", "name", "typeParameters", "parameters", "type",
      "body", "typeArguments",
    ],
  )
  _assert_factory_contract("NodeFactory.createIdentifier", id, 80, [
    "escapedText",
  ])
  _assert_factory_contract(
    "NodeFactory.createLiteralLikeNode",
    _factory_create_literal_like_node(_syntax_kind(14), "/x/"),
    14,
    ["text"],
  )
  _assert_factory_contract(
    "NodeFactory.createMetaProperty",
    _factory_create_meta_property(_syntax_kind(105), id),
    237,
    ["keywordToken", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createNewExpression",
    _factory_create_new_expression(id, None, None),
    215,
    ["expression", "typeArguments", "arguments"],
  )
  let node_array_symbol = "NodeFactory.createNodeArray"
  let node_array = _create_node_array([id], has_trailing_comma=true)
  assert_eq(node_array.length(), 1, msg=node_array_symbol)
  assert_true(node_array.has_trailing_comma(), msg=node_array_symbol)
  assert_true(
    node_array.get(0).unwrap().same_identity(id),
    msg=node_array_symbol,
  )
  _assert_factory_contract(
    "NodeFactory.createNonNullExpression",
    _factory_create_non_null_expression(id),
    236,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createNumericLiteral",
    _factory_create_numeric_literal("1"),
    9,
    ["text", "numericLiteralFlags"],
  )
  _assert_factory_contract(
    "NodeFactory.createObjectBindingPattern",
    _factory_create_object_binding_pattern(empty),
    207,
    ["elements"],
  )
  _assert_factory_contract(
    "NodeFactory.createObjectLiteralExpression",
    _factory_create_object_literal_expression(Some(empty)),
    211,
    ["properties", "multiLine"],
  )
  _assert_factory_contract(
    "NodeFactory.createOmittedExpression",
    _factory_create_omitted_expression(),
    233,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createParenthesizedExpression",
    _factory_create_parenthesized_expression(id),
    218,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createPostfixUnaryExpression",
    _factory_create_postfix_unary_expression(id, _syntax_kind(46)),
    226,
    ["operator", "operand"],
  )
  _assert_factory_contract(
    "NodeFactory.createPrefixUnaryExpression",
    _factory_create_prefix_unary_expression(_syntax_kind(46), id),
    225,
    ["operator", "operand"],
  )
  _assert_factory_contract(
    "NodeFactory.createPrivateIdentifier",
    _factory_create_private_identifier("#x"),
    81,
    ["escapedText"],
  )
  _assert_factory_contract(
    "NodeFactory.createPropertyAccessChain",
    _factory_create_property_access_chain(id, Some(question_dot), id),
    212,
    ["expression", "questionDotToken", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createPropertyAccessExpression",
    _factory_create_property_access_expression(id, id),
    212,
    ["expression", "questionDotToken", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createSatisfiesExpression",
    _factory_create_satisfies_expression(id, id),
    239,
    ["expression", "type"],
  )
  _assert_factory_contract(
    "NodeFactory.createSemicolonClassElement",
    _factory_create_semicolon_class_element(),
    241,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createSpreadElement",
    _factory_create_spread_element(id),
    231,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createStringLiteral",
    _factory_create_string_literal("x"),
    11,
    ["text", "singleQuote", "hasExtendedUnicodeEscape"],
  )
  _assert_factory_contract(
    "NodeFactory.createTaggedTemplateExpression",
    _factory_create_tagged_template_expression(id, None, template),
    216,
    ["tag", "typeArguments", "template"],
  )
  _assert_factory_contract(
    "NodeFactory.createTemplateExpression",
    template,
    229,
    ["head", "templateSpans"],
  )
  _assert_factory_contract(
    "NodeFactory.createTemplateLiteralLikeNode",
    head,
    16,
    ["text", "rawText", "templateFlags"],
  )
  _assert_factory_contract("NodeFactory.createTemplateSpan", span, 240, [
    "expression", "literal",
  ])
  _assert_factory_contract(
    "NodeFactory.createToken",
    _factory_create_token(_syntax_kind(58)),
    58,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createTypeOfExpression",
    _factory_create_type_of_expression(id),
    222,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createVoidExpression",
    _factory_create_void_expression(id),
    223,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createYieldExpression",
    _factory_create_yield_expression(None, Some(id)),
    230,
    ["expression", "asteriskToken"],
  )
}

///|
test "expression family transform-flag branches" {
  let id = _contract_identifier()
  let optional = _factory_create_property_access_chain(
    id,
    Some(_factory_create_token(_syntax_kind(29))),
    id,
  )
  assert_true(optional.flags().contains(NodeFlags::optional_chain()))
  assert_true(
    optional.transform_flags().contains(TransformFlags::contains_es2020()),
  )

  let dynamic_import = _factory_create_call_expression(
    _factory_create_token(_syntax_kind(102)),
    None,
    None,
  )
  assert_true(
    dynamic_import
    .transform_flags()
    .contains(TransformFlags::contains_dynamic_import()),
  )

  let exponentiation = _factory_create_binary_expression(
    id,
    _factory_create_token(_syntax_kind(43)),
    id,
  )
  assert_true(
    exponentiation.transform_flags().contains(TransformFlags::contains_es2016()),
  )
  let logical_assignment = _factory_create_binary_expression(
    id,
    _factory_create_token(_syntax_kind(76)),
    id,
  )
  assert_true(
    logical_assignment
    .transform_flags()
    .contains(TransformFlags::contains_es2021()),
  )
}
