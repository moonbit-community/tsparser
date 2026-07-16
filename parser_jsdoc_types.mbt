// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_parse_jsdoc_identifier_name(
  self : ParserState,
  message? : DiagnosticMessage,
) -> Node {
  if !_parser_token_is_identifier_or_keyword(self.current_token) {
    return match message {
      Some(message) =>
        self._create_missing_parser_node(_syntax_kind(80), false, message~)
      None =>
        self._create_missing_parser_node(
          _syntax_kind(80),
          true,
          message=_diagnostic_message(1003),
        )
    }
  }
  self.identifier_count += 1
  let start = self.scanner._token_start()
  let end = self.scanner._token_end()
  let original_keyword_kind = self.current_token
  let text = self._intern_identifier(self.scanner._required_token_value())
  let result = self._finish_parser_node(
    _factory_create_identifier(text, original_keyword_kind~),
    start,
    end~,
  )
  ignore(self._next_token_jsdoc())
  result
}

///|
fn ParserState::_parse_jsdoc_type(self : ParserState) -> Node {
  self.scanner._set_skip_jsdoc_leading_asterisks(true)
  let pos = self._get_node_pos()
  if self._parse_optional(_syntax_kind(144)) {
    let node = _factory_create_jsdoc_namepath_type(None)
    while self.current_token.to_int() != 20 &&
          self.current_token.to_int() != 1 &&
          self.current_token.to_int() != 28 &&
          self.current_token.to_int() != 5 {
      ignore(self._next_token_jsdoc())
    }
    self.scanner._set_skip_jsdoc_leading_asterisks(false)
    return self._finish_parser_node(node, pos)
  }
  let has_dot_dot_dot = self._parse_optional(_syntax_kind(26))
  let mut type_node = self._parse_type_or_type_predicate()
  self.scanner._set_skip_jsdoc_leading_asterisks(false)
  if has_dot_dot_dot {
    type_node = self._finish_parser_node(
      _factory_create_jsdoc_variadic_type(Some(type_node)),
      pos,
    )
  }
  if self.current_token.to_int() == 64 {
    ignore(self._next_token())
    return self._finish_parser_node(
      _factory_create_jsdoc_optional_type(Some(type_node)),
      pos,
    )
  }
  type_node
}

///|
fn ParserState::_parse_jsdoc_parameter(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let name = if self.current_token.to_int() == 110 ||
    self.current_token.to_int() == 105 {
    let value = self._parse_identifier_name()
    ignore(self._parse_expected(_syntax_kind(59)))
    Some(value)
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_jsdoc_parameter_declaration(name, self._parse_jsdoc_type()),
    pos,
  )
}

///|
fn ParserState::_parse_jsdoc_function_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let has_open_paren = self._try_parse(fn() {
    ignore(self._next_token())
    if self.current_token.to_int() == 21 {
      Some(true)
    } else {
      None
    }
  })
  if has_open_paren is Some(_) {
    let flags = ParserSignatureFlags::type_flag().union(
      ParserSignatureFlags::jsdoc(),
    )
    let parameters = self._parse_parameters(flags)
    let type_node = self._parse_return_type(_syntax_kind(59), false)
    return self._finish_parser_node(
      _factory_create_jsdoc_function_type(parameters, type_node),
      pos,
    )
  }
  self._finish_parser_node(
    _factory_create_type_reference_node(self._parse_identifier_name(), None),
    pos,
  )
}

///|
fn ParserState::_parse_jsdoc_type_expression(
  self : ParserState,
  may_omit_braces? : Bool = false,
) -> Node {
  let pos = self._get_node_pos()
  let has_brace = if may_omit_braces {
    self._parse_optional(_syntax_kind(19))
  } else {
    self._parse_expected(_syntax_kind(19))
  }
  let type_node = self._do_inside_of_context(NodeFlags::jsdoc(), fn() {
    self._parse_jsdoc_type()
  })
  if !may_omit_braces || has_brace {
    ignore(self._parse_expected_jsdoc(_syntax_kind(20)))
  }
  let result = self._finish_parser_node(
    _factory_create_jsdoc_type_expression(type_node),
    pos,
  )
  ignore(_set_parent_recursive(result))
  result
}

///|
fn ParserState::_parse_jsdoc_name_reference(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let has_brace = self._parse_optional(_syntax_kind(19))
  let name_pos = self._get_node_pos()
  let mut entity_name = self._parse_entity_name(false)
  while self.current_token.to_int() == 81 {
    ignore(self._re_scan_hash_token())
    ignore(self._next_token_jsdoc())
    entity_name = self._finish_parser_node(
      _factory_create_jsdoc_member_name(entity_name, self._parse_identifier()),
      name_pos,
    )
  }
  if has_brace {
    ignore(self._parse_expected_jsdoc(_syntax_kind(20)))
  }
  let result = self._finish_parser_node(
    _factory_create_jsdoc_name_reference(entity_name),
    pos,
  )
  ignore(_set_parent_recursive(result))
  result
}

///|
fn ParserState::_parse_jsdoc_entity_name(self : ParserState) -> Node {
  let mut entity = self._parse_jsdoc_identifier_name()
  if self._parse_optional(_syntax_kind(23)) {
    ignore(self._parse_expected(_syntax_kind(24)))
  }
  while self._parse_optional(_syntax_kind(25)) {
    let name = self._parse_jsdoc_identifier_name()
    if self._parse_optional(_syntax_kind(23)) {
      ignore(self._parse_expected(_syntax_kind(24)))
    }
    entity = self._create_qualified_name(entity, name)
  }
  entity
}
