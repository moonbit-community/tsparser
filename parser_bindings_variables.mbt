// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_parse_array_binding_element(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  if self.current_token.to_int() == 28 {
    return self._finish_parser_node(_factory_create_omitted_expression(), pos)
  }
  let spread = self._parse_optional_token(_syntax_kind(26))
  let name = self._parse_identifier_or_pattern()
  let initializer = self._parse_initializer()
  self._finish_parser_node(
    _factory_create_binding_element(spread, None, name, initializer),
    pos,
  )
}

///|
fn ParserState::_parse_object_binding_element(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let spread = self._parse_optional_token(_syntax_kind(26))
  let token_is_identifier = self._is_binding_identifier()
  let mut property_name : Node? = Some(
    self._parse_property_name(fn() { self._parse_expression() }),
  )
  let name = if token_is_identifier && self.current_token.to_int() != 59 {
    match property_name {
      Some(name) => {
        property_name = None
        name
      }
      None => abort("object binding property name is absent")
    }
  } else {
    ignore(self._parse_expected(_syntax_kind(59)))
    self._parse_identifier_or_pattern()
  }
  let initializer = self._parse_initializer()
  self._finish_parser_node(
    _factory_create_binding_element(spread, property_name, name, initializer),
    pos,
  )
}

///|
fn ParserState::_parse_object_binding_pattern(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(19)))
  let elements = self._allow_in_and(fn() {
    _parser_required_node_array(
      self._parse_delimited_list(ParsingContext::object_binding_elements(), fn() {
        Some(self._parse_object_binding_element())
      }),
    )
  })
  ignore(self._parse_expected(_syntax_kind(20)))
  self._finish_parser_node(
    _factory_create_object_binding_pattern(elements),
    pos,
  )
}

///|
fn ParserState::_parse_array_binding_pattern(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(23)))
  let elements = self._allow_in_and(fn() {
    _parser_required_node_array(
      self._parse_delimited_list(ParsingContext::array_binding_elements(), fn() {
        Some(self._parse_array_binding_element())
      }),
    )
  })
  ignore(self._parse_expected(_syntax_kind(24)))
  self._finish_parser_node(_factory_create_array_binding_pattern(elements), pos)
}

///|
fn ParserState::_parse_identifier_or_pattern(
  self : ParserState,
  private_message? : DiagnosticMessage = _diagnostic_message(18029),
) -> Node {
  match self.current_token.to_int() {
    23 => self._parse_array_binding_pattern()
    19 => self._parse_object_binding_pattern()
    _ =>
      self._create_identifier(
        self._is_binding_identifier(),
        private_identifier_message=private_message,
      )
  }
}

///|
fn ParserState::_parse_variable_declaration(
  self : ParserState,
  allow_exclamation : Bool,
) -> Node {
  let pos = self._get_node_pos()
  let name = self._parse_identifier_or_pattern()
  let exclamation = if allow_exclamation &&
    name.kind().to_int() == 80 &&
    self.current_token.to_int() == 54 &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    Some(self._parse_token_node())
  } else {
    None
  }
  let type_node = self._parse_type_annotation()
  let initializer = if self.current_token.to_int() == 103 ||
    self.current_token.to_int() == 165 {
    None
  } else {
    self._parse_initializer()
  }
  self._finish_parser_node(
    _factory_create_variable_declaration(
      name, exclamation, type_node, initializer,
    ),
    pos,
  )
}

///|
fn ParserState::_can_follow_contextual_of_keyword(self : ParserState) -> Bool? {
  guard self._next_token_is_identifier() is Some(_) else { return None }
  if self._next_token().to_int() == 22 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_parse_variable_declaration_list(
  self : ParserState,
  in_for_statement_initializer : Bool,
) -> Node {
  let pos = self._get_node_pos()
  let mut flags = NodeFlags::none()
  match self.current_token.to_int() {
    115 => ()
    121 => flags = flags.union(NodeFlags::let_flag())
    87 => flags = flags.union(NodeFlags::const_flag())
    160 => flags = flags.union(NodeFlags::using_flag())
    135 => {
      flags = flags.union(NodeFlags::await_using())
      ignore(self._next_token())
    }
    _ => abort("variable declaration list started at an invalid token")
  }
  ignore(self._next_token())
  let declarations = if self.current_token.to_int() == 165 &&
    self._look_ahead(fn() { self._can_follow_contextual_of_keyword() })
    is Some(_) {
    self._create_missing_list()
  } else {
    let saved_disallow_in = self._in_disallow_in_context()
    self._set_disallow_in_context(in_for_statement_initializer)
    let result = _parser_required_node_array(
      self._parse_delimited_list(ParsingContext::variable_declarations(), fn() {
        Some(self._parse_variable_declaration(!in_for_statement_initializer))
      }),
    )
    self._set_disallow_in_context(saved_disallow_in)
    result
  }
  self._finish_parser_node(
    _factory_create_variable_declaration_list(declarations, flags~),
    pos,
  )
}

///|
fn ParserState::_next_token_is_binding_identifier_or_pattern(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if self._is_binding_identifier() ||
    self.current_token.to_int() == 19 ||
    self.current_token.to_int() == 23 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_is_let_declaration(self : ParserState) -> Bool {
  self._look_ahead(fn() { self._next_token_is_binding_identifier_or_pattern() })
  is Some(_)
}

///|
fn ParserState::_next_token_is_binding_or_object_pattern_for_variable(
  self : ParserState,
  disallow_of : Bool,
) -> Bool? {
  ignore(self._next_token())
  if disallow_of && self.current_token.to_int() == 165 {
    ignore(self._next_token())
    if self.current_token.to_int() == 64 ||
      self.current_token.to_int() == 27 ||
      self.current_token.to_int() == 59 {
      return Some(true)
    }
    return None
  }
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    (self._is_binding_identifier() || self.current_token.to_int() == 19) {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_is_using_declaration(self : ParserState) -> Bool {
  self._look_ahead(fn() {
    self._next_token_is_binding_or_object_pattern_for_variable(false)
  })
  is Some(_)
}

///|
fn ParserState::_next_token_is_using_then_binding(
  self : ParserState,
  disallow_of : Bool,
) -> Bool? {
  ignore(self._next_token())
  guard self.current_token.to_int() == 160 else { return None }
  self._next_token_is_binding_or_object_pattern_for_variable(disallow_of)
}

///|
fn ParserState::_is_await_using_declaration(self : ParserState) -> Bool {
  self._look_ahead(fn() { self._next_token_is_using_then_binding(false) })
  is Some(_)
}

///|
fn ParserState::_parse_variable_statement(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  let declaration_list = self._parse_variable_declaration_list(false)
  ignore(self._parse_semicolon())
  self._finish_parser_node(
    _factory_create_variable_statement(modifiers, declaration_list),
    pos,
  )
}
