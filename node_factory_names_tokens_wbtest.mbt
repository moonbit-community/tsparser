///|
fn assert_text_field(
  node : Node,
  name : String,
  expected : String?,
) -> Unit raise {
  match node.field(name) {
    Some(Text(actual)) => assert_eq(actual, expected)
    _ => fail("expected text field " + name)
  }
}

///|
fn assert_bool_field(
  node : Node,
  name : String,
  expected : Bool?,
) -> Unit raise {
  match node.field(name) {
    Some(Boolean(actual)) => assert_eq(actual, expected)
    _ => fail("expected boolean field " + name)
  }
}

///|
test "literal factories preserve exact fields and transform flags" {
  let binary = _factory_create_numeric_literal(
    "0b1",
    numeric_literal_flags=TokenFlags::binary_specifier(),
  )
  assert_eq(binary.kind().to_int(), 9)
  assert_text_field(binary, "text", Some("0b1"))
  match binary.field("numericLiteralFlags") {
    Some(TokenFlagSet(flags)) => assert_eq(flags.bits(), 128U)
    _ => fail("missing numericLiteralFlags")
  }
  assert_true(
    binary.transform_flags().contains(TransformFlags::contains_es2015()),
  )

  let string = _factory_create_string_literal(
    "x",
    is_single_quote=true,
    has_extended_unicode_escape=true,
  )
  assert_text_field(string, "text", Some("x"))
  assert_bool_field(string, "singleQuote", Some(true))
  assert_bool_field(string, "hasExtendedUnicodeEscape", Some(true))
  assert_true(
    string.transform_flags().contains(TransformFlags::contains_es2015()),
  )

  let plain = _factory_create_string_literal("x")
  assert_bool_field(plain, "singleQuote", None)
  assert_bool_field(plain, "hasExtendedUnicodeEscape", None)

  let bigint = _factory_create_literal_like_node(_syntax_kind(10), "1n")
  assert_eq(bigint.kind().to_int(), 10)
  assert_true(
    bigint.transform_flags().contains(TransformFlags::contains_es2020()),
  )

  let white = _factory_create_literal_like_node(_syntax_kind(13), "  ")
  assert_eq(white.kind().to_int(), 12)
  assert_bool_field(white, "containsOnlyTriviaWhiteSpaces", Some(true))
  assert_true(white.transform_flags().contains(TransformFlags::contains_jsx()))
}

///|
test "template literal flags are masked and preserve undefined raw text" {
  let flags = TokenFlags::contains_invalid_escape().union(
    TokenFlags::preceding_line_break(),
  )
  let template = _factory_create_template_literal_like_node(
    _syntax_kind(16),
    "value",
    template_flags=flags,
  )
  assert_text_field(template, "text", Some("value"))
  assert_text_field(template, "rawText", None)
  match template.field("templateFlags") {
    Some(TokenFlagSet(actual)) => assert_eq(actual.bits(), 2048U)
    _ => fail("missing templateFlags")
  }
  assert_true(
    template.transform_flags().contains(TransformFlags::contains_es2015()),
  )
  assert_true(
    template.transform_flags().contains(TransformFlags::contains_es2018()),
  )
}

///|
test "identifier factories preserve escaped text, flags, and stable identity" {
  let identifier = _factory_create_identifier(
    "__proto__",
    has_extended_unicode_escape=true,
  )
  assert_text_field(identifier, "escapedText", Some("___proto__"))
  assert_true(
    identifier
    .flags()
    .contains(NodeFlags::identifier_has_extended_unicode_escape()),
  )
  assert_true(
    identifier.transform_flags().contains(TransformFlags::contains_es2015()),
  )

  let await_name = _factory_create_identifier("await")
  assert_true(
    await_name
    .transform_flags()
    .contains(TransformFlags::contains_possible_top_level_await()),
  )
  let qualified = _factory_create_qualified_name(identifier, await_name)
  match qualified.field("left") {
    Some(NodeRef(Some(actual))) => assert_true(actual.same_identity(identifier))
    _ => fail("missing qualified-name left")
  }
  assert_false(
    qualified
    .transform_flags()
    .contains(TransformFlags::contains_possible_top_level_await()),
  )

  let private_name = _factory_create_private_identifier("#x")
  assert_text_field(private_name, "escapedText", Some("#x"))
  assert_true(
    private_name
    .transform_flags()
    .contains(TransformFlags::contains_class_fields()),
  )
}

///|
test "token factory applies the exact syntax-family transform flags" {
  let cases : Array[(Int, UInt)] = [
    (134, 384U),
    (160, 4U),
    (125, 1U),
    (108, 134218752U),
    (126, 1024U),
    (129, 16777216U),
    (110, 16384U),
    (19, 0U),
  ]
  for pair in cases {
    let (kind, expected) = pair
    let token = _factory_create_token(_syntax_kind(kind))
    assert_eq(token.kind().to_int(), kind)
    assert_eq(token.transform_flags().bits(), expected)
    assert_eq(token.fields().length(), 0)
  }
}

///|
test "computed names and NodeArray aggregation match subtree exclusions" {
  let this_token = _factory_create_token(_syntax_kind(110))
  let computed = _factory_create_computed_property_name(this_token)
  assert_true(
    computed
    .transform_flags()
    .contains(TransformFlags::contains_computed_property_name()),
  )
  assert_true(
    computed.transform_flags().contains(TransformFlags::contains_lexical_this()),
  )

  let mutable_elements = [computed]
  let list = _create_node_array(mutable_elements, has_trailing_comma=true)
  mutable_elements.push(this_token)
  assert_eq(list.length(), 1)
  assert_true(list.get(0).unwrap().same_identity(computed))
  assert_eq(list.pos(), -1)
  assert_eq(list.end(), -1)
  assert_true(list.has_trailing_comma())
  assert_true(
    list
    .transform_flags()
    .contains(TransformFlags::contains_computed_property_name()),
  )

  list._set_text_range(4, 9)
  let same = _create_node_array_from_node_array(list, has_trailing_comma=true)
  assert_true(same.same_identity(list))
  let changed = _create_node_array_from_node_array(list)
  assert_false(changed.same_identity(list))
  assert_eq(changed.pos(), 4)
  assert_eq(changed.end(), 9)
  assert_true(changed.get(0).unwrap().same_identity(computed))
}

///|
test "property-name lexical flags re-enter excluded declarations" {
  let name = _factory_create_computed_property_name(
    _factory_create_token(_syntax_kind(110)),
  )
  let declaration = _make_fields_node(
    _syntax_kind(173),
    [_node_ref_field("name", Some(name))],
    transform_flags=TransformFlags::contains_lexical_this(),
  )
  let propagated = _propagate_child_flags(Some(declaration))
  assert_true(propagated.contains(TransformFlags::contains_lexical_this()))
}
