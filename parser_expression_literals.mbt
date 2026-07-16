// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_parse_parenthesized_expression(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(21)))
  let expression = self._allow_in_and(fn() { self._parse_expression() })
  ignore(self._parse_expected(_syntax_kind(22)))
  self._finish_parser_node(
    _factory_create_parenthesized_expression(expression),
    pos,
  )
}

///|
fn ParserState::_parse_spread_element(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(26)))
  self._finish_parser_node(
    _factory_create_spread_element(
      self._parse_assignment_expression_or_higher(true),
    ),
    pos,
  )
}

///|
fn ParserState::_parse_array_literal_expression(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let open_position = self.scanner._token_start()
  let open_parsed = self._parse_expected(_syntax_kind(23))
  let multi_line = self.scanner._has_flag(TokenFlags::preceding_line_break())
  let elements = _parser_required_node_array(
    self._parse_delimited_list(ParsingContext::array_literal_members(), fn() {
      Some(self._parse_argument_or_array_literal_element())
    }),
  )
  self._parse_expected_matching_brackets(
    _syntax_kind(23),
    _syntax_kind(24),
    open_parsed,
    open_position,
  )
  self._finish_parser_node(
    _factory_create_array_literal_expression(Some(elements), multi_line~),
    pos,
  )
}

///|
fn ParserState::_parse_object_literal_modifiers(
  self : ParserState,
) -> NodeArray? {
  self._parse_modifiers(true, false, false)
}

///|
fn ParserState::_next_token_can_follow_get_or_set(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 23 || self._is_literal_property_name() {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_parse_contextual_accessor_modifier(
  self : ParserState,
  kind : SyntaxKind,
) -> Bool {
  if self.current_token != kind ||
    self._look_ahead(fn() { self._next_token_can_follow_get_or_set() }) is None {
    return false
  }
  ignore(self._next_token())
  true
}

///|
fn _parser_modifiers_have_async(modifiers : NodeArray?) -> Bool {
  match modifiers {
    Some(modifiers) => {
      for modifier in modifiers.elements() {
        if modifier.kind().to_int() == 134 {
          return true
        }
      }
      false
    }
    None => false
  }
}

///|
fn ParserState::_parse_object_function_block_or_semicolon(
  self : ParserState,
  flags : ParserSignatureFlags,
) -> Node? {
  if self.current_token.to_int() != 19 && self._can_parse_semicolon() {
    ignore(self._parse_semicolon())
    None
  } else {
    Some(self._parse_function_block(flags))
  }
}

///|
fn ParserState::_parse_object_method_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
  asterisk : Node?,
  name : Node,
  question : Node?,
  exclamation : Node?,
) -> Node {
  let mut flags = ParserSignatureFlags::none()
  if asterisk is Some(_) {
    flags = flags.union(ParserSignatureFlags::yield_flag())
  }
  if _parser_modifiers_have_async(modifiers) {
    flags = flags.union(ParserSignatureFlags::await_flag())
  }
  let type_parameters = self._parse_type_parameters()
  let parameters = self._parse_parameters(flags)
  let type_node = self._parse_return_type(_syntax_kind(59), false)
  let body = self._parse_object_function_block_or_semicolon(flags)
  let node = _factory_create_method_declaration(
    modifiers, asterisk, name, question, type_parameters, parameters, type_node,
    body,
  )
  _parser_set_node_field(node, "exclamationToken", NodeRef(exclamation))
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_object_accessor_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
  is_get : Bool,
) -> Node {
  let name = self._parse_property_name(fn() { self._parse_expression() })
  let type_parameters = self._parse_type_parameters()
  let parameters = self._parse_parameters(ParserSignatureFlags::none())
  let type_node = self._parse_return_type(_syntax_kind(59), false)
  let body = self._parse_object_function_block_or_semicolon(
    ParserSignatureFlags::none(),
  )
  let node = if is_get {
    _factory_create_get_accessor_declaration(
      modifiers, name, parameters, type_node, body,
    )
  } else {
    _factory_create_set_accessor_declaration(modifiers, name, parameters, body)
  }
  _parser_set_node_field(node, "typeParameters", NodeList(type_parameters))
  if !is_get {
    _parser_set_node_field(node, "type", NodeRef(type_node))
  }
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_object_literal_element(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  match self._parse_optional_token(_syntax_kind(26)) {
    Some(_) =>
      return self._finish_parser_node(
        _factory_create_spread_assignment(
          self._parse_assignment_expression_or_higher(true),
        ),
        pos,
      )
    None => ()
  }
  let modifiers = self._parse_object_literal_modifiers()
  if self._parse_contextual_accessor_modifier(_syntax_kind(139)) {
    return self._parse_object_accessor_declaration(pos, modifiers, true)
  }
  if self._parse_contextual_accessor_modifier(_syntax_kind(153)) {
    return self._parse_object_accessor_declaration(pos, modifiers, false)
  }
  let asterisk = self._parse_optional_token(_syntax_kind(42))
  let token_is_identifier = self._is_identifier()
  let name = self._parse_property_name(fn() { self._parse_expression() })
  let question = self._parse_optional_token(_syntax_kind(58))
  let exclamation = self._parse_optional_token(_syntax_kind(54))
  if asterisk is Some(_) ||
    self.current_token.to_int() == 21 ||
    self.current_token.to_int() == 30 {
    return self._parse_object_method_declaration(
      pos, modifiers, asterisk, name, question, exclamation,
    )
  }
  if token_is_identifier && self.current_token.to_int() != 59 {
    let equals = self._parse_optional_token(_syntax_kind(64))
    let initializer = match equals {
      Some(_) =>
        Some(
          self._allow_in_and(fn() {
            self._parse_assignment_expression_or_higher(true)
          }),
        )
      None => None
    }
    let node = _factory_create_shorthand_property_assignment(name, initializer)
    _parser_set_node_field(node, "equalsToken", NodeRef(equals))
    _parser_set_node_field(node, "modifiers", NodeList(modifiers))
    _parser_set_node_field(node, "questionToken", NodeRef(question))
    _parser_set_node_field(node, "exclamationToken", NodeRef(exclamation))
    return self._finish_parser_node(node, pos)
  }
  ignore(self._parse_expected(_syntax_kind(59)))
  let initializer = self._allow_in_and(fn() {
    self._parse_assignment_expression_or_higher(true)
  })
  let node = _factory_create_property_assignment(name, initializer)
  _parser_set_node_field(node, "modifiers", NodeList(modifiers))
  _parser_set_node_field(node, "questionToken", NodeRef(question))
  _parser_set_node_field(node, "exclamationToken", NodeRef(exclamation))
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_object_literal_expression(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let open_position = self.scanner._token_start()
  let open_parsed = self._parse_expected(_syntax_kind(19))
  let multi_line = self.scanner._has_flag(TokenFlags::preceding_line_break())
  let properties = _parser_required_node_array(
    self._parse_delimited_list(
      ParsingContext::object_literal_members(),
      fn() { Some(self._parse_object_literal_element()) },
      consider_semicolon_as_delimiter=true,
    ),
  )
  self._parse_expected_matching_brackets(
    _syntax_kind(19),
    _syntax_kind(20),
    open_parsed,
    open_position,
  )
  self._finish_parser_node(
    _factory_create_object_literal_expression(Some(properties), multi_line~),
    pos,
  )
}

///|
fn ParserState::_parse_class_expression_with_modifiers(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  self._parse_class_declaration_or_expression(pos, modifiers, 232)
}

///|
fn ParserState::_parse_class_expression(self : ParserState) -> Node {
  self._parse_class_expression_with_modifiers(self._get_node_pos(), None)
}

///|
fn ParserState::_parse_decorated_expression(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let modifiers = self._parse_modifiers(true, false, false)
  if self.current_token.to_int() == 86 {
    self._parse_class_expression_with_modifiers(pos, modifiers)
  } else {
    let missing = self._create_missing_parser_node(
      _syntax_kind(283),
      true,
      message=_diagnostic_message(1109),
    )
    _parser_append_node_field(missing, "modifiers", NodeList(modifiers))
    missing._set_text_range(pos, missing.end())
    missing
  }
}
