///|
test "signature and type factory field contracts" {
  let id = _contract_identifier()
  let type_node = _factory_create_this_type_node()
  let empty = _contract_empty_list()
  let block = _contract_block()
  let tail = _factory_create_template_literal_like_node(_syntax_kind(18), "")
  let type_span = _factory_create_template_literal_type_span(type_node, tail)

  _assert_factory_contract(
    "NodeFactory.createArrayTypeNode",
    _factory_create_array_type_node(type_node),
    189,
    ["elementType"],
  )
  _assert_factory_contract(
    "NodeFactory.createCallSignature",
    _factory_create_call_signature(None, empty, None),
    180,
    ["typeParameters", "parameters", "type", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createComputedPropertyName",
    _factory_create_computed_property_name(id),
    168,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createClassStaticBlockDeclaration",
    _factory_create_class_static_block_declaration(block),
    176,
    ["body", "modifiers"],
  )
  _assert_factory_contract(
    "NodeFactory.createConditionalTypeNode",
    _factory_create_conditional_type_node(
      type_node, type_node, type_node, type_node,
    ),
    195,
    ["checkType", "extendsType", "trueType", "falseType"],
  )
  _assert_factory_contract(
    "NodeFactory.createConstructorDeclaration",
    _factory_create_constructor_declaration(None, empty, Some(block)),
    177,
    [
      "modifiers", "parameters", "body", "typeParameters", "type", "typeArguments",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createConstructorTypeNode",
    _factory_create_constructor_type_node(None, None, empty, type_node),
    186,
    ["modifiers", "typeParameters", "parameters", "type", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createConstructSignature",
    _factory_create_construct_signature(None, empty, None),
    181,
    ["typeParameters", "parameters", "type", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createDecorator",
    _factory_create_decorator(id),
    171,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createFunctionTypeNode",
    _factory_create_function_type_node(None, empty, type_node),
    185,
    ["typeParameters", "parameters", "type", "modifiers", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createGetAccessorDeclaration",
    _factory_create_get_accessor_declaration(None, id, empty, None, Some(block)),
    178,
    [
      "modifiers", "name", "parameters", "type", "body", "typeArguments", "typeParameters",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createImportTypeNode",
    _factory_create_import_type_node(type_node, None, None, None),
    206,
    ["argument", "attributes", "qualifier", "typeArguments", "isTypeOf"],
  )
  _assert_factory_contract(
    "NodeFactory.createIndexedAccessTypeNode",
    _factory_create_indexed_access_type_node(type_node, type_node),
    200,
    ["objectType", "indexType"],
  )
  _assert_factory_contract(
    "NodeFactory.createIndexSignature",
    _factory_create_index_signature(None, empty, None),
    182,
    ["modifiers", "parameters", "type", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createInferTypeNode",
    _factory_create_infer_type_node(
      _factory_create_type_parameter_declaration(None, id, None, None),
    ),
    196,
    ["typeParameter"],
  )
  _assert_factory_contract(
    "NodeFactory.createIntersectionTypeNode",
    _factory_create_intersection_type_node(empty),
    194,
    ["types"],
  )
  _assert_factory_contract(
    "NodeFactory.createLiteralTypeNode",
    _factory_create_literal_type_node(_factory_create_string_literal("x")),
    202,
    ["literal"],
  )
  _assert_factory_contract(
    "NodeFactory.createMappedTypeNode",
    _factory_create_mapped_type_node(
      None,
      _factory_create_type_parameter_declaration(None, id, None, None),
      None,
      None,
      None,
      None,
    ),
    201,
    [
      "readonlyToken", "typeParameter", "nameType", "questionToken", "type", "members",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createMethodDeclaration",
    _factory_create_method_declaration(
      None,
      None,
      id,
      None,
      None,
      empty,
      None,
      Some(block),
    ),
    175,
    [
      "modifiers", "asteriskToken", "name", "questionToken", "exclamationToken",
      "typeParameters", "parameters", "type", "body", "typeArguments",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createMethodSignature",
    _factory_create_method_signature(None, id, None, None, empty, None),
    174,
    [
      "modifiers", "name", "questionToken", "typeParameters", "parameters", "type",
      "typeArguments",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createNamedTupleMember",
    _factory_create_named_tuple_member(None, id, None, type_node),
    203,
    ["dotDotDotToken", "name", "questionToken", "type"],
  )
  _assert_factory_contract(
    "NodeFactory.createOptionalTypeNode",
    _factory_create_optional_type_node(type_node),
    191,
    ["type"],
  )
  _assert_factory_contract(
    "NodeFactory.createParameterDeclaration",
    _factory_create_parameter_declaration(None, None, id, None, None, None),
    170,
    [
      "modifiers", "dotDotDotToken", "name", "questionToken", "type", "initializer",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createParenthesizedType",
    _factory_create_parenthesized_type(type_node),
    197,
    ["type"],
  )
  _assert_factory_contract(
    "NodeFactory.createPropertyDeclaration",
    _factory_create_property_declaration(None, id, None, None, None),
    173,
    [
      "modifiers", "name", "questionToken", "exclamationToken", "type", "initializer",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createPropertySignature",
    _factory_create_property_signature(None, id, None, None),
    172,
    ["modifiers", "name", "type", "questionToken", "initializer"],
  )
  _assert_factory_contract(
    "NodeFactory.createQualifiedName",
    _factory_create_qualified_name(id, id),
    167,
    ["left", "right"],
  )
  _assert_factory_contract(
    "NodeFactory.createRestTypeNode",
    _factory_create_rest_type_node(type_node),
    192,
    ["type"],
  )
  _assert_factory_contract(
    "NodeFactory.createSetAccessorDeclaration",
    _factory_create_set_accessor_declaration(None, id, empty, Some(block)),
    179,
    [
      "modifiers", "name", "parameters", "body", "typeArguments", "typeParameters",
      "type",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createTemplateLiteralType",
    _factory_create_template_literal_type(
      _factory_create_template_literal_like_node(_syntax_kind(16), ""),
      _create_node_array([type_span]),
    ),
    204,
    ["head", "templateSpans"],
  )
  _assert_factory_contract(
    "NodeFactory.createTemplateLiteralTypeSpan",
    type_span,
    205,
    ["type", "literal"],
  )
  _assert_factory_contract("NodeFactory.createThisTypeNode", type_node, 198, [])
  _assert_factory_contract(
    "NodeFactory.createTupleTypeNode",
    _factory_create_tuple_type_node(empty),
    190,
    ["elements"],
  )
  _assert_factory_contract(
    "NodeFactory.createTypeAssertion",
    _factory_create_type_assertion(type_node, id),
    217,
    ["expression", "type"],
  )
  _assert_factory_contract(
    "NodeFactory.createTypeLiteralNode",
    _factory_create_type_literal_node(None),
    188,
    ["members"],
  )
  _assert_factory_contract(
    "NodeFactory.createTypeOperatorNode",
    _factory_create_type_operator_node(_syntax_kind(143), type_node),
    199,
    ["operator", "type"],
  )
  _assert_factory_contract(
    "NodeFactory.createTypeParameterDeclaration",
    _factory_create_type_parameter_declaration(None, id, None, None),
    169,
    ["modifiers", "name", "constraint", "default", "expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createTypePredicateNode",
    _factory_create_type_predicate_node(None, id, None),
    183,
    ["assertsModifier", "parameterName", "type"],
  )
  _assert_factory_contract(
    "NodeFactory.createTypeQueryNode",
    _factory_create_type_query_node(id, None),
    187,
    ["exprName", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createTypeReferenceNode",
    _factory_create_type_reference_node(id, None),
    184,
    ["typeName", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createUnionTypeNode",
    _factory_create_union_type_node(empty),
    193,
    ["types"],
  )
}
