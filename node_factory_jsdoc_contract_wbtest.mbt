///|
test "JSDoc type and link factory field contracts" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let type_node = _factory_create_this_type_node()
  let type_expression = _factory_create_jsdoc_type_expression(type_node)

  _assert_factory_contract(
    "NodeFactory.createJSDocAllType",
    _factory_create_jsdoc_all_type(),
    313,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocUnknownType",
    _factory_create_jsdoc_unknown_type(),
    314,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocNullableType",
    _factory_create_jsdoc_nullable_type(Some(type_node)),
    315,
    ["type", "postfix"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocNonNullableType",
    _factory_create_jsdoc_non_nullable_type(Some(type_node)),
    316,
    ["type", "postfix"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocOptionalType",
    _factory_create_jsdoc_optional_type(Some(type_node)),
    317,
    ["type"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocFunctionType",
    _factory_create_jsdoc_function_type(empty, Some(type_node)),
    318,
    ["parameters", "type", "typeArguments"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocVariadicType",
    _factory_create_jsdoc_variadic_type(Some(type_node)),
    319,
    ["type"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocNamepathType",
    _factory_create_jsdoc_namepath_type(Some(type_node)),
    320,
    ["type"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocTypeExpression",
    type_expression,
    310,
    ["type"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocTypeLiteral",
    _factory_create_jsdoc_type_literal(None),
    323,
    ["jsDocPropertyTags", "isArrayType"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocSignature",
    _factory_create_jsdoc_signature(None, empty, Some(type_node)),
    324,
    ["typeParameters", "parameters", "type"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocNameReference",
    _factory_create_jsdoc_name_reference(id),
    311,
    ["name"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocMemberName",
    _factory_create_jsdoc_member_name(id, id),
    312,
    ["left", "right"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocLink",
    _factory_create_jsdoc_link(Some(id), "label"),
    325,
    ["name", "text"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocLinkCode",
    _factory_create_jsdoc_link_code(Some(id), "label"),
    326,
    ["name", "text"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocLinkPlain",
    _factory_create_jsdoc_link_plain(Some(id), "label"),
    327,
    ["name", "text"],
  )
}

///|
test "JSDoc tag factory field contracts" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let type_node = _factory_create_this_type_node()
  let type_expression = _factory_create_jsdoc_type_expression(type_node)
  let signature = _factory_create_jsdoc_signature(None, empty, Some(type_node))
  let comment = Some(_jsdoc_comment_text("comment"))

  _assert_factory_contract(
    "NodeFactory.createJSDocAuthorTag",
    _factory_create_jsdoc_author_tag(None, comment),
    331,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocClassTag",
    _factory_create_jsdoc_class_tag(None, comment),
    333,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocPublicTag",
    _factory_create_jsdoc_public_tag(None, comment),
    334,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocPrivateTag",
    _factory_create_jsdoc_private_tag(None, comment),
    335,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocProtectedTag",
    _factory_create_jsdoc_protected_tag(None, comment),
    336,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocReadonlyTag",
    _factory_create_jsdoc_readonly_tag(None, comment),
    337,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocOverrideTag",
    _factory_create_jsdoc_override_tag(None, comment),
    338,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocDeprecatedTag",
    _factory_create_jsdoc_deprecated_tag(None, comment),
    332,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocTypeTag",
    _factory_create_jsdoc_type_tag(None, Some(type_expression), comment),
    345,
    ["tagName", "comment", "typeExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocReturnTag",
    _factory_create_jsdoc_return_tag(None, Some(type_expression), comment),
    343,
    ["tagName", "comment", "typeExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocThisTag",
    _factory_create_jsdoc_this_tag(None, Some(type_expression), comment),
    344,
    ["tagName", "comment", "typeExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocThrowsTag",
    _factory_create_jsdoc_throws_tag(None, Some(type_expression), comment),
    350,
    ["tagName", "comment", "typeExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocSatisfiesTag",
    _factory_create_jsdoc_satisfies_tag(None, Some(type_expression), comment),
    351,
    ["tagName", "comment", "typeExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocTemplateTag",
    _factory_create_jsdoc_template_tag(None, None, empty, comment),
    346,
    ["tagName", "comment", "constraint", "typeParameters"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocTypedefTag",
    _factory_create_jsdoc_typedef_tag(
      None,
      Some(type_expression),
      Some(id),
      comment,
    ),
    347,
    ["tagName", "comment", "typeExpression", "fullName", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocParameterTag",
    _factory_create_jsdoc_parameter_tag(
      None,
      id,
      false,
      Some(type_expression),
      is_name_first=false,
      comment,
    ),
    342,
    [
      "tagName", "comment", "typeExpression", "name", "isNameFirst", "isBracketed",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocPropertyTag",
    _factory_create_jsdoc_property_tag(
      None,
      id,
      false,
      Some(type_expression),
      is_name_first=false,
      comment,
    ),
    349,
    [
      "tagName", "comment", "typeExpression", "name", "isNameFirst", "isBracketed",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocCallbackTag",
    _factory_create_jsdoc_callback_tag(None, signature, Some(id), comment),
    339,
    ["tagName", "comment", "typeExpression", "fullName", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocOverloadTag",
    _factory_create_jsdoc_overload_tag(None, signature, comment),
    340,
    ["tagName", "comment", "typeExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocAugmentsTag",
    _factory_create_jsdoc_augments_tag(None, id, comment),
    329,
    ["tagName", "comment", "class"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocImplementsTag",
    _factory_create_jsdoc_implements_tag(None, id, comment),
    330,
    ["tagName", "comment", "class"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocSeeTag",
    _factory_create_jsdoc_see_tag(None, Some(id), comment),
    348,
    ["tagName", "comment", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocUnknownTag",
    _factory_create_jsdoc_unknown_tag(id, comment),
    328,
    ["tagName", "comment"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocEnumTag",
    _factory_create_jsdoc_enum_tag(None, type_expression, comment),
    341,
    ["tagName", "comment", "typeExpression"],
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocImportTag",
    _factory_create_jsdoc_import_tag(
      None,
      None,
      _factory_create_string_literal("m"),
      None,
      comment,
    ),
    352,
    ["tagName", "comment", "importClause", "moduleSpecifier", "attributes"],
  )
}

///|
test "JSDoc text and structured-comment payload contracts" {
  let text = _factory_create_jsdoc_text("text")
  _assert_factory_contract("NodeFactory.createJSDocText", text, 322, ["text"])
  assert_text_field(text, "text", Some("text"))

  let text_comment = _factory_create_jsdoc_comment(
    Some(_jsdoc_comment_text("comment")),
    None,
  )
  _assert_factory_contract(
    "NodeFactory.createJSDocComment",
    text_comment,
    321,
    ["comment", "tags"],
  )
  assert_text_field(text_comment, "comment", Some("comment"))

  let nodes = _create_node_array([text])
  let node_comment = _factory_create_jsdoc_comment(
    Some(_jsdoc_comment_nodes(nodes)),
    None,
  )
  match node_comment.field("comment") {
    Some(NodeList(Some(actual))) => assert_true(actual.same_identity(nodes))
    _ => fail("structured JSDoc comment must preserve its NodeArray")
  }
}
