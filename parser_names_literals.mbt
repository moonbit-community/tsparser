// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_create_qualified_name(
  self : ParserState,
  entity : Node,
  name : Node,
) -> Node {
  self._finish_parser_node(
    _factory_create_qualified_name(entity, name),
    entity.pos(),
  )
}

///|
fn ParserState::_parse_right_side_of_dot(
  self : ParserState,
  allow_identifier_names : Bool,
  allow_private_identifiers : Bool,
  allow_unicode_escape_sequence : Bool,
) -> Node {
  if self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    _parser_token_is_identifier_or_keyword(self.current_token) {
    let matches_pattern = self._look_ahead(fn() {
        self._next_token_is_identifier_or_keyword_on_same_line()
      })
      is Some(_)
    if matches_pattern {
      return self._create_missing_parser_node(
        _syntax_kind(80),
        true,
        message=_diagnostic_message(1003),
      )
    }
  }
  if self.current_token.to_int() == 81 {
    let node = self._parse_private_identifier()
    if allow_private_identifiers {
      return node
    }
    return self._create_missing_parser_node(
      _syntax_kind(80),
      true,
      message=_diagnostic_message(1003),
    )
  }
  if allow_identifier_names {
    if allow_unicode_escape_sequence {
      self._parse_identifier_name()
    } else {
      self._parse_identifier_name_no_unicode_escape()
    }
  } else {
    self._parse_identifier()
  }
}

///|
fn ParserState::_parse_entity_name(
  self : ParserState,
  allow_reserved_words : Bool,
  message? : DiagnosticMessage,
) -> Node {
  let pos = self._get_node_pos()
  let mut entity = match message {
    Some(message) =>
      if allow_reserved_words {
        self._parse_identifier_name(message~)
      } else {
        self._parse_identifier(message~)
      }
    None =>
      if allow_reserved_words {
        self._parse_identifier_name()
      } else {
        self._parse_identifier()
      }
  }
  while self._parse_optional(_syntax_kind(25)) {
    if self.current_token.to_int() == 30 {
      break
    }
    entity = self._finish_parser_node(
      _factory_create_qualified_name(
        entity,
        self._parse_right_side_of_dot(allow_reserved_words, false, true),
      ),
      pos,
    )
  }
  entity
}

///|
fn ParserState::_parse_entity_name_of_type_reference(
  self : ParserState,
) -> Node {
  self._parse_entity_name(true, message=_diagnostic_message(1110))
}

///|
fn ParserState::_template_literal_raw_text(
  self : ParserState,
  kind : SyntaxKind,
) -> String {
  let is_last = kind.to_int() == 15 || kind.to_int() == 18
  let token_text = self.scanner._token_text()
  let trim_end = if self.scanner._has_flag(TokenFlags::unterminated()) {
    0
  } else if is_last {
    1
  } else {
    2
  }
  let end = token_text.length() - trim_end
  if end <= 1 {
    ""
  } else {
    token_text.unsafe_substring(start=1, end~)
  }
}

///|
fn ParserState::_parse_literal_like_node(
  self : ParserState,
  kind : SyntaxKind,
) -> Node {
  let pos = self._get_node_pos()
  let value = self.scanner._required_token_value()
  let node = match kind.to_int() {
    9 =>
      _factory_create_numeric_literal(
        value,
        numeric_literal_flags=self.scanner._numeric_literal_flags(),
      )
    10 => _factory_create_big_int_literal(value)
    11 =>
      _factory_create_string_literal(
        value,
        has_extended_unicode_escape=self.scanner._has_flag(
          TokenFlags::extended_unicode_escape(),
        ),
      )
    14 => _factory_create_regular_expression_literal(value)
    15 | 16 | 17 | 18 =>
      _factory_create_template_literal_like_node(
        kind,
        value,
        raw_text=self._template_literal_raw_text(kind),
        template_flags=self.scanner._token_flags(),
      )
    _ => abort("literal-like parser received a non-literal token")
  }
  ignore(self._next_token())
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_literal_node(self : ParserState) -> Node {
  self._parse_literal_like_node(self.current_token)
}

///|
fn ParserState::_parse_template_head(
  self : ParserState,
  is_tagged_template : Bool,
) -> Node {
  if !is_tagged_template &&
    self.scanner._token_flags().intersect(TokenFlags::is_invalid()).bits() != 0U {
    ignore(self._re_scan_template_token(false))
  }
  self._parse_literal_like_node(self.current_token)
}

///|
fn ParserState::_parse_template_middle_or_tail(self : ParserState) -> Node {
  self._parse_literal_like_node(self.current_token)
}

///|
fn ParserState::_parse_literal_of_template_span(
  self : ParserState,
  is_tagged_template : Bool,
) -> Node {
  if self.current_token.to_int() == 20 {
    ignore(self._re_scan_template_token(is_tagged_template))
    return self._parse_template_middle_or_tail()
  }
  self._create_missing_parser_node(
    _syntax_kind(18),
    false,
    message=_diagnostic_message(1005),
    arguments=_parser_text_arguments("}"),
  )
}

///|
fn _parser_template_span_has_middle(span : Node) -> Bool {
  match span.field("literal") {
    Some(NodeRef(Some(literal))) => literal.kind().to_int() == 17
    _ => false
  }
}

///|
fn ParserState::_parse_template_spans(
  self : ParserState,
  is_tagged_template : Bool,
  parse_expression : () -> Node,
) -> NodeArray {
  let pos = self._get_node_pos()
  let spans : Array[Node] = []
  while true {
    let span_pos = self._get_node_pos()
    let span = self._finish_parser_node(
      _factory_create_template_span(
        self._allow_in_and(parse_expression),
        self._parse_literal_of_template_span(is_tagged_template),
      ),
      span_pos,
    )
    spans.push(span)
    if !_parser_template_span_has_middle(span) {
      break
    }
  }
  self._create_parser_node_array(spans, pos)
}

///|
fn ParserState::_parse_template_expression_with(
  self : ParserState,
  is_tagged_template : Bool,
  parse_expression : () -> Node,
) -> Node {
  let pos = self._get_node_pos()
  let head = self._parse_template_head(is_tagged_template)
  let spans = self._parse_template_spans(is_tagged_template, parse_expression)
  self._finish_parser_node(
    _factory_create_template_expression(head, spans),
    pos,
  )
}

///|
fn ParserState::_parse_template_type_span(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let type_node = self._parse_type()
  let literal = self._parse_literal_of_template_span(false)
  self._finish_parser_node(
    _factory_create_template_literal_type_span(type_node, literal),
    pos,
  )
}

///|
fn ParserState::_parse_template_type_spans(self : ParserState) -> NodeArray {
  let pos = self._get_node_pos()
  let spans : Array[Node] = []
  while true {
    let span = self._parse_template_type_span()
    spans.push(span)
    if !_parser_template_span_has_middle(span) {
      break
    }
  }
  self._create_parser_node_array(spans, pos)
}

///|
fn ParserState::_parse_template_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let head = self._parse_template_head(false)
  let spans = self._parse_template_type_spans()
  self._finish_parser_node(
    _factory_create_template_literal_type(head, spans),
    pos,
  )
}
