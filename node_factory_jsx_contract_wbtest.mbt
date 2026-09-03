///|
test "JSX factory field contracts" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let attributes = _factory_create_jsx_attributes(empty)
  let opening = _factory_create_jsx_opening_element(id, None, attributes)
  let closing = _factory_create_jsx_closing_element(id)
  let opening_fragment = _factory_create_jsx_opening_fragment()
  let closing_fragment = _factory_create_jsx_jsx_closing_fragment()

  _assert_factory_contract(
    "NodeFactory.createJsxElement",
    _factory_create_jsx_element(opening, empty, closing),
    285,
    ["openingElement", "children", "closingElement"],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxSelfClosingElement",
    _factory_create_jsx_self_closing_element(id, None, attributes),
    286,
    ["tagName", "typeArguments", "attributes"],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxOpeningElement",
    opening,
    287,
    ["tagName", "typeArguments", "attributes"],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxClosingElement",
    closing,
    288,
    ["tagName"],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxFragment",
    _factory_create_jsx_fragment(opening_fragment, empty, closing_fragment),
    289,
    ["openingFragment", "children", "closingFragment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxOpeningFragment",
    opening_fragment,
    290,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxJsxClosingFragment",
    closing_fragment,
    291,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxAttribute",
    _factory_create_jsx_attribute(id, None),
    292,
    ["name", "initializer"],
  )
  _assert_factory_contract("NodeFactory.createJsxAttributes", attributes, 293, [
    "properties",
  ])
  _assert_factory_contract(
    "NodeFactory.createJsxSpreadAttribute",
    _factory_create_jsx_spread_attribute(id),
    294,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxExpression",
    _factory_create_jsx_expression(None, Some(id)),
    295,
    ["dotDotDotToken", "expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxNamespacedName",
    _factory_create_jsx_namespaced_name(id, id),
    296,
    ["namespace", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createJsxText",
    _factory_create_jsx_text("text"),
    12,
    ["text", "containsOnlyTriviaWhiteSpaces"],
  )
}
