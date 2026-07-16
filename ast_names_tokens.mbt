// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts, src/compiler/utilitiesPublic.ts, and
// src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _syntax_kind(value : Int) -> SyntaxKind {
  guard SyntaxKind::from_int(value) is Some(kind) else {
    abort("invalid parser SyntaxKind")
  }
  kind
}

///|
fn _escape_leading_underscores(identifier : String) -> String {
  if identifier.length() >= 2 && identifier[0] == 95 && identifier[1] == 95 {
    "_" + identifier
  } else {
    identifier
  }
}

///|
fn _factory_create_numeric_literal(
  text : String,
  numeric_literal_flags? : TokenFlags = TokenFlags::none(),
) -> Node {
  guard text.length() == 0 || text[0] != 45 else {
    abort("negative numeric literal must use a prefix unary expression")
  }
  let mut flags = TransformFlags::none()
  if numeric_literal_flags
    .intersect(TokenFlags::binary_or_octal_specifier())
    .bits() !=
    0U {
    flags = flags.union(TransformFlags::contains_es2015())
  }
  _make_fields_node(
    _syntax_kind(9),
    [
      _text_field("text", Some(text)),
      _token_flags_field("numericLiteralFlags", numeric_literal_flags),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_big_int_literal(text : String) -> Node {
  _make_fields_node(
    _syntax_kind(10),
    [_text_field("text", Some(text))],
    transform_flags=TransformFlags::contains_es2020(),
  )
}

///|
fn _factory_create_string_literal(
  text : String,
  is_single_quote? : Bool,
  has_extended_unicode_escape? : Bool,
) -> Node {
  let mut flags = TransformFlags::none()
  match has_extended_unicode_escape {
    Some(true) => flags = flags.union(TransformFlags::contains_es2015())
    _ => ()
  }
  _make_fields_node(
    _syntax_kind(11),
    [
      _text_field("text", Some(text)),
      _boolean_field("singleQuote", is_single_quote),
      _boolean_field("hasExtendedUnicodeEscape", has_extended_unicode_escape),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_regular_expression_literal(text : String) -> Node {
  _make_fields_node(_syntax_kind(14), [_text_field("text", Some(text))])
}

///|
fn _factory_create_jsx_text(
  text : String,
  contains_only_trivia_white_spaces? : Bool = false,
) -> Node {
  _make_fields_node(
    _syntax_kind(12),
    [
      _text_field("text", Some(text)),
      _boolean_field(
        "containsOnlyTriviaWhiteSpaces",
        Some(contains_only_trivia_white_spaces),
      ),
    ],
    transform_flags=TransformFlags::contains_jsx(),
  )
}

///|
fn _factory_create_template_literal_like_node(
  kind : SyntaxKind,
  text : String,
  raw_text? : String,
  template_flags? : TokenFlags,
) -> Node {
  guard kind.to_int() >= 15 && kind.to_int() <= 18 else {
    abort("invalid template literal kind")
  }
  let masked_flags = match template_flags {
    Some(flags) => flags.intersect(TokenFlags::template_literal_like_flags())
    None => TokenFlags::none()
  }
  let mut transform_flags = TransformFlags::contains_es2015()
  if masked_flags.bits() != 0U {
    transform_flags = transform_flags.union(TransformFlags::contains_es2018())
  }
  _make_fields_node(
    kind,
    [
      _text_field("text", Some(text)),
      _text_field("rawText", raw_text),
      _token_flags_field("templateFlags", masked_flags),
    ],
    transform_flags~,
  )
}

///|
fn _factory_create_literal_like_node(kind : SyntaxKind, text : String) -> Node {
  match kind.to_int() {
    9 => _factory_create_numeric_literal(text)
    10 => _factory_create_big_int_literal(text)
    11 => _factory_create_string_literal(text)
    12 => _factory_create_jsx_text(text)
    13 => _factory_create_jsx_text(text, contains_only_trivia_white_spaces=true)
    14 => _factory_create_regular_expression_literal(text)
    15 => _factory_create_template_literal_like_node(kind, text)
    _ => abort("invalid literal-like kind")
  }
}

///|
fn _factory_create_identifier(
  text : String,
  original_keyword_kind? : SyntaxKind,
  has_extended_unicode_escape? : Bool = false,
) -> Node {
  ignore(original_keyword_kind)
  let escaped_text = _escape_leading_underscores(text)
  let node = _make_fields_node(_syntax_kind(80), [
    _text_field("escapedText", Some(escaped_text)),
  ])
  if has_extended_unicode_escape {
    node._add_flags(NodeFlags::identifier_has_extended_unicode_escape())
  }
  if escaped_text == "await" {
    node._add_transform_flags(
      TransformFlags::contains_possible_top_level_await(),
    )
  }
  if has_extended_unicode_escape {
    node._add_transform_flags(TransformFlags::contains_es2015())
  }
  node
}

///|
fn _factory_create_private_identifier(text : String) -> Node {
  guard text.length() > 0 && text[0] == 35 else {
    abort("private identifier must start with #")
  }
  _make_fields_node(
    _syntax_kind(81),
    [_text_field("escapedText", Some(_escape_leading_underscores(text)))],
    transform_flags=TransformFlags::contains_class_fields(),
  )
}

///|
fn _factory_create_token(kind : SyntaxKind) -> Node {
  let value = kind.to_int()
  guard value >= 0 && value <= 166 else { abort("invalid token kind") }
  guard value <= 15 || value >= 18 else {
    abort("template literal requires create_template_literal_like_node")
  }
  guard value <= 9 || value >= 15 else {
    abort("literal requires create_literal_like_node")
  }
  guard value != 80 else { abort("identifier requires create_identifier") }
  let mut flags = TransformFlags::none()
  match value {
    134 =>
      flags = TransformFlags::contains_es2017().union(
        TransformFlags::contains_es2018(),
      )
    160 => flags = TransformFlags::contains_es_next()
    87
    | 103
    | 116
    | 123
    | 124
    | 125
    | 128
    | 133
    | 136
    | 138
    | 146
    | 147
    | 148
    | 150
    | 151
    | 154
    | 155
    | 157
    | 159
    | 163
    | 164 => flags = TransformFlags::contains_typescript()
    108 =>
      flags = TransformFlags::contains_es2015().union(
        TransformFlags::contains_lexical_super(),
      )
    126 => flags = TransformFlags::contains_es2015()
    129 => flags = TransformFlags::contains_class_fields()
    110 => flags = TransformFlags::contains_lexical_this()
    _ => ()
  }
  _make_fields_node(kind, [], transform_flags=flags)
}

///|
fn _factory_create_qualified_name(left : Node, right : Node) -> Node {
  _make_fields_node(
    _syntax_kind(167),
    [_node_ref_field("left", Some(left)), _node_ref_field("right", Some(right))],
    transform_flags=_propagate_child_flags(Some(left)).union(
      _propagate_identifier_name_flags(right),
    ),
  )
}

///|
fn _factory_create_computed_property_name(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(168),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(TransformFlags::contains_es2015())
      .union(TransformFlags::contains_computed_property_name()),
  )
}
