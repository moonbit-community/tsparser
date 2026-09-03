///|
fn _assert_transform_bits(
  label : String,
  node : Node,
  expected : UInt,
) -> Unit raise {
  let actual = node.transform_flags().bits()
  assert_eq(
    actual,
    expected,
    msg=label +
      " expected " +
      expected.to_string() +
      ", got " +
      actual.to_string(),
  )
}

///|
test "factory transform flags match pinned TypeScript reference fixtures" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let block = _contract_block()
  let type_node = _factory_create_this_type_node()
  let async_modifier = _factory_create_token(_syntax_kind(134))

  _assert_transform_bits("type-this", type_node, 1U)
  _assert_transform_bits(
    "parameter-typed",
    _factory_create_parameter_declaration(
      None,
      None,
      id,
      None,
      Some(type_node),
      None,
    ),
    1U,
  )
  _assert_transform_bits(
    "property-declaration",
    _factory_create_property_declaration(None, id, None, None, Some(id)),
    16777216U,
  )
  _assert_transform_bits(
    "class-static-block",
    _factory_create_class_static_block_declaration(block),
    16777216U,
  )
  _assert_transform_bits(
    "function-async-generator",
    _factory_create_function_declaration(
      Some(_create_node_array([async_modifier])),
      Some(_factory_create_token(_syntax_kind(42))),
      Some(id),
      None,
      empty,
      None,
      Some(block),
    ),
    4194688U,
  )

  let let_list = _factory_create_variable_declaration_list(
    empty,
    flags=NodeFlags::let_flag(),
  )
  _assert_transform_bits("variable-list-let", let_list, 4457472U)
  assert_eq(let_list.flags().bits(), 1U)
  let using_list = _factory_create_variable_declaration_list(
    empty,
    flags=NodeFlags::using_flag(),
  )
  _assert_transform_bits("variable-list-using", using_list, 4457476U)
  assert_eq(using_list.flags().bits(), 4U)

  _assert_transform_bits(
    "for-of-await",
    _factory_create_for_of_statement(
      Some(_factory_create_token(_syntax_kind(135))),
      id,
      id,
      block,
    ),
    1152U,
  )
  _assert_transform_bits(
    "catch-no-binding",
    _factory_create_catch_clause(None, block),
    64U,
  )
  _assert_transform_bits(
    "import-attributes",
    _factory_create_import_attributes(empty),
    4U,
  )
  _assert_transform_bits(
    "namespace-export",
    _factory_create_namespace_export(id),
    32U,
  )
}

///|
test "expression and JSX transform flags match pinned TypeScript reference fixtures" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let type_node = _factory_create_this_type_node()

  _assert_transform_bits(
    "array-binding",
    _factory_create_array_binding_pattern(empty),
    525312U,
  )
  _assert_transform_bits(
    "object-binding",
    _factory_create_object_binding_pattern(empty),
    525312U,
  )
  _assert_transform_bits(
    "spread-element",
    _factory_create_spread_element(id),
    33792U,
  )
  _assert_transform_bits(
    "await-expression",
    _factory_create_await_expression(id),
    2097536U,
  )
  _assert_transform_bits(
    "yield-expression",
    _factory_create_yield_expression(None, Some(id)),
    1049728U,
  )
  _assert_transform_bits(
    "arrow-async",
    _factory_create_arrow_function(
      Some(_create_node_array([_factory_create_token(_syntax_kind(134))])),
      None,
      empty,
      None,
      None,
      id,
    ),
    17792U,
  )
  _assert_transform_bits(
    "dynamic-import",
    _factory_create_call_expression(
      _factory_create_token(_syntax_kind(102)),
      None,
      None,
    ),
    8388608U,
  )
  _assert_transform_bits(
    "private-access",
    _factory_create_property_access_expression(
      id,
      _factory_create_private_identifier("#x"),
    ),
    553648128U,
  )
  let optional_access = _factory_create_property_access_chain(
    id,
    Some(_factory_create_token(_syntax_kind(29))),
    id,
  )
  _assert_transform_bits("optional-access", optional_access, 32U)
  assert_eq(optional_access.flags().bits(), 64U)
  _assert_transform_bits(
    "exponentiation",
    _factory_create_binary_expression(
      id,
      _factory_create_token(_syntax_kind(43)),
      id,
    ),
    512U,
  )
  _assert_transform_bits(
    "logical-assignment",
    _factory_create_binary_expression(
      id,
      _factory_create_token(_syntax_kind(76)),
      id,
    ),
    16U,
  )
  _assert_transform_bits(
    "nullish",
    _factory_create_binary_expression(
      id,
      _factory_create_token(_syntax_kind(61)),
      id,
    ),
    32U,
  )
  _assert_transform_bits(
    "destructuring-array-assignment",
    _factory_create_binary_expression(
      _factory_create_array_literal_expression(Some(empty)),
      _factory_create_token(_syntax_kind(64)),
      id,
    ),
    5120U,
  )

  let attributes = _factory_create_jsx_attributes(empty)
  _assert_transform_bits(
    "jsx-opening-type-args",
    _factory_create_jsx_opening_element(
      id,
      Some(_create_node_array([type_node])),
      attributes,
    ),
    3U,
  )
  _assert_transform_bits(
    "jsdoc-function-typed",
    _factory_create_jsdoc_function_type(empty, Some(type_node)),
    1U,
  )
}
