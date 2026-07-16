// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_next_token_is_from_or_equals(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 161 || self.current_token.to_int() == 64 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_open_paren_for_module(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 21 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_is_external_module_reference(self : ParserState) -> Bool {
  self.current_token.to_int() == 149 &&
  self._look_ahead(fn() { self._next_token_is_open_paren_for_module() })
  is Some(_)
}

///|
fn ParserState::_parse_module_specifier(self : ParserState) -> Node {
  if self.current_token.to_int() == 11 {
    let literal = self._parse_literal_node()
    match literal.field("text") {
      Some(Text(Some(text))) =>
        _parser_set_node_field(
          literal,
          "text",
          Text(Some(self._intern_identifier(text))),
        )
      _ => ()
    }
    literal
  } else {
    self._parse_expression()
  }
}

///|
fn ParserState::_parse_external_module_reference(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(149)))
  ignore(self._parse_expected(_syntax_kind(21)))
  let expression = self._parse_module_specifier()
  ignore(self._parse_expected(_syntax_kind(22)))
  self._finish_parser_node(
    _factory_create_external_module_reference(expression),
    pos,
  )
}

///|
fn ParserState::_parse_module_reference(self : ParserState) -> Node {
  if self._is_external_module_reference() {
    self._parse_external_module_reference()
  } else {
    self._parse_entity_name(false)
  }
}

///|
fn ParserState::_parse_namespace_import(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(42)))
  ignore(self._parse_expected(_syntax_kind(130)))
  self._finish_parser_node(
    _factory_create_namespace_import(self._parse_identifier()),
    pos,
  )
}

///|
fn ParserState::_can_parse_module_export_name(self : ParserState) -> Bool {
  _parser_token_is_identifier_or_keyword(self.current_token) ||
  self.current_token.to_int() == 11
}

///|
fn ParserState::_parse_module_export_name(self : ParserState) -> Node {
  if self.current_token.to_int() == 11 {
    self._parse_literal_node()
  } else {
    self._parse_identifier_name()
  }
}

///|
fn ParserState::_parse_checked_module_export_name(
  self : ParserState,
) -> (Node, Bool, Int, Int) {
  let is_keyword = _parser_token_is_keyword(self.current_token) &&
    !self._is_identifier()
  let start = self.scanner._token_start()
  let end = self.scanner._token_end()
  (self._parse_module_export_name(), is_keyword, start, end)
}

///|
fn ParserState::_parse_import_or_export_specifier(
  self : ParserState,
  kind : Int,
) -> Node {
  let pos = self._get_node_pos()
  let mut check_identifier_is_keyword = _parser_token_is_keyword(
      self.current_token,
    ) &&
    !self._is_identifier()
  let mut check_identifier_start = self.scanner._token_start()
  let mut check_identifier_end = self.scanner._token_end()
  let mut is_type_only = false
  let mut property_name : Node? = None
  let mut can_parse_as_keyword = true
  let mut name = self._parse_module_export_name()
  if _parser_identifier_text(name) is Some("type") {
    if self.current_token.to_int() == 130 {
      let first_as = self._parse_identifier_name()
      if self.current_token.to_int() == 130 {
        let second_as = self._parse_identifier_name()
        if self._can_parse_module_export_name() {
          is_type_only = true
          property_name = Some(first_as)
          let (parsed, keyword, start, end) = self._parse_checked_module_export_name()
          name = parsed
          check_identifier_is_keyword = keyword
          check_identifier_start = start
          check_identifier_end = end
          can_parse_as_keyword = false
        } else {
          property_name = Some(name)
          name = second_as
          can_parse_as_keyword = false
        }
      } else if self._can_parse_module_export_name() {
        property_name = Some(name)
        let (parsed, keyword, start, end) = self._parse_checked_module_export_name()
        name = parsed
        check_identifier_is_keyword = keyword
        check_identifier_start = start
        check_identifier_end = end
        can_parse_as_keyword = false
      } else {
        is_type_only = true
        name = first_as
      }
    } else if self._can_parse_module_export_name() {
      is_type_only = true
      let (parsed, keyword, start, end) = self._parse_checked_module_export_name()
      name = parsed
      check_identifier_is_keyword = keyword
      check_identifier_start = start
      check_identifier_end = end
    }
  }
  if can_parse_as_keyword && self.current_token.to_int() == 130 {
    property_name = Some(name)
    ignore(self._parse_expected(_syntax_kind(130)))
    let (parsed, keyword, start, end) = self._parse_checked_module_export_name()
    name = parsed
    check_identifier_is_keyword = keyword
    check_identifier_start = start
    check_identifier_end = end
  }
  if kind == 277 {
    if name.kind().to_int() != 80 {
      ignore(
        self._parse_error_at(
          skip_trivia(SourceText::new(self.source_text), name.pos()),
          name.end(),
          _diagnostic_message(1003),
        ),
      )
      let missing = self._create_missing_parser_node(_syntax_kind(80), false)
      missing._set_text_range(name.pos(), name.pos())
      name = missing
    } else if check_identifier_is_keyword {
      ignore(
        self._parse_error_at(
          check_identifier_start,
          check_identifier_end,
          _diagnostic_message(1003),
        ),
      )
    }
  }
  self._finish_parser_node(
    if kind == 277 {
      _factory_create_import_specifier(is_type_only, property_name, name)
    } else {
      _factory_create_export_specifier(is_type_only, property_name, name)
    },
    pos,
  )
}

///|
fn ParserState::_parse_import_specifier(self : ParserState) -> Node {
  self._parse_import_or_export_specifier(277)
}

///|
fn ParserState::_parse_export_specifier(self : ParserState) -> Node {
  self._parse_import_or_export_specifier(282)
}

///|
fn ParserState::_parse_named_imports_or_exports(
  self : ParserState,
  kind : Int,
) -> Node {
  let pos = self._get_node_pos()
  let elements = _parser_required_node_array(
    self._parse_bracketed_list(
      ParsingContext::import_or_export_specifiers(),
      fn() {
        Some(
          if kind == 276 {
            self._parse_import_specifier()
          } else {
            self._parse_export_specifier()
          },
        )
      },
      _syntax_kind(19),
      _syntax_kind(20),
    ),
  )
  self._finish_parser_node(
    if kind == 276 {
      _factory_create_named_imports(elements)
    } else {
      _factory_create_named_exports(elements)
    },
    pos,
  )
}

///|
fn ParserState::_parse_import_clause(
  self : ParserState,
  identifier : Node?,
  pos : Int,
  import_modifier : SyntaxKind?,
  skip_jsdoc_leading_asterisks? : Bool = false,
) -> Node {
  let mut named_bindings : Node? = None
  if identifier is None || self._parse_optional(_syntax_kind(28)) {
    if skip_jsdoc_leading_asterisks {
      self.scanner._set_skip_jsdoc_leading_asterisks(true)
    }
    named_bindings = Some(
      if self.current_token.to_int() == 42 {
        self._parse_namespace_import()
      } else {
        self._parse_named_imports_or_exports(276)
      },
    )
    if skip_jsdoc_leading_asterisks {
      self.scanner._set_skip_jsdoc_leading_asterisks(false)
    }
  }
  self._finish_parser_node(
    _factory_create_import_clause(import_modifier, identifier, named_bindings),
    pos,
  )
}

///|
fn ParserState::_try_parse_import_clause(
  self : ParserState,
  identifier : Node?,
  pos : Int,
  import_modifier : SyntaxKind?,
  skip_jsdoc_leading_asterisks? : Bool = false,
) -> Node? {
  if identifier is Some(_) ||
    self.current_token.to_int() == 42 ||
    self.current_token.to_int() == 19 {
    let clause = self._parse_import_clause(
      identifier,
      pos,
      import_modifier,
      skip_jsdoc_leading_asterisks~,
    )
    ignore(self._parse_expected(_syntax_kind(161)))
    Some(clause)
  } else {
    None
  }
}

///|
fn ParserState::_parse_module_import_attribute(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let name = if _parser_token_is_identifier_or_keyword(self.current_token) {
    self._parse_identifier_name()
  } else {
    self._parse_literal_like_node(_syntax_kind(11))
  }
  ignore(self._parse_expected(_syntax_kind(59)))
  let value = self._parse_assignment_expression_or_higher(true)
  self._finish_parser_node(_factory_create_import_attribute(name, value), pos)
}

///|
fn ParserState::_parse_module_import_attributes(
  self : ParserState,
  token : SyntaxKind,
) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(token))
  let open_position = self.scanner._token_start()
  let open_parsed = self._parse_expected(_syntax_kind(19))
  let (elements, multi_line) = if open_parsed {
    let multi_line = self.scanner._has_flag(TokenFlags::preceding_line_break())
    let elements = _parser_required_node_array(
      self._parse_delimited_list(
        ParsingContext::import_attributes(),
        fn() { Some(self._parse_module_import_attribute()) },
        consider_semicolon_as_delimiter=true,
      ),
    )
    self._parse_expected_matching_brackets(
      _syntax_kind(19),
      _syntax_kind(20),
      true,
      open_position,
    )
    (elements, multi_line)
  } else {
    (
      self._create_parser_node_array(
        [],
        self._get_node_pos(),
        end=self._get_node_pos(),
      ),
      false,
    )
  }
  self._finish_parser_node(
    _factory_create_import_attributes(elements, multi_line~, token~),
    pos,
  )
}

///|
fn ParserState::_try_parse_module_import_attributes(
  self : ParserState,
) -> Node? {
  if self.current_token.to_int() == 118 ||
    (
      self.current_token.to_int() == 132 &&
      !self.scanner._has_flag(TokenFlags::preceding_line_break())
    ) {
    Some(self._parse_module_import_attributes(self.current_token))
  } else {
    None
  }
}

///|
fn ParserState::_parse_import_equals_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
  identifier : Node,
  is_type_only : Bool,
) -> Node {
  ignore(self._parse_expected(_syntax_kind(64)))
  let module_reference = self._parse_module_reference()
  ignore(self._parse_semicolon())
  self._finish_parser_node(
    _factory_create_import_equals_declaration(
      modifiers, is_type_only, identifier, module_reference,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_import_declaration_or_import_equals(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  ignore(self._parse_expected(_syntax_kind(102)))
  let after_import_pos = self.scanner._token_full_start()
  let mut identifier = if self._is_identifier() {
    Some(self._parse_identifier())
  } else {
    None
  }
  let mut import_modifier : SyntaxKind? = None
  match identifier {
    Some(candidate) if _parser_identifier_text(candidate) is Some("type") => {
      let from_or_equals_after_identifier = self.current_token.to_int() == 161 &&
        self._is_identifier() &&
        self._look_ahead(fn() { self._next_token_is_from_or_equals() })
        is Some(_)
      if (self.current_token.to_int() != 161 || from_or_equals_after_identifier) &&
        (
          self._is_identifier() ||
          self.current_token.to_int() == 42 ||
          self.current_token.to_int() == 19
        ) {
        import_modifier = Some(_syntax_kind(156))
        identifier = if self._is_identifier() {
          Some(self._parse_identifier())
        } else {
          None
        }
      }
    }
    Some(candidate) if _parser_identifier_text(candidate) is Some("defer") => {
      let is_import_modifier = if self.current_token.to_int() == 161 {
        self._look_ahead(fn() { self._next_token_is_string_literal() }) is None
      } else {
        self.current_token.to_int() != 28 && self.current_token.to_int() != 64
      }
      if is_import_modifier {
        import_modifier = Some(_syntax_kind(166))
        identifier = if self._is_identifier() {
          Some(self._parse_identifier())
        } else {
          None
        }
      }
    }
    _ => ()
  }
  let is_defer_import = match import_modifier {
    Some(kind) => kind.to_int() == 166
    None => false
  }
  let is_type_only = match import_modifier {
    Some(kind) => kind.to_int() == 156
    None => false
  }
  match identifier {
    Some(identifier) if self.current_token.to_int() != 28 &&
      self.current_token.to_int() != 161 &&
      !is_defer_import =>
      return self._parse_import_equals_declaration(
        pos, modifiers, identifier, is_type_only,
      )
    _ => ()
  }
  let import_clause = self._try_parse_import_clause(
    identifier, after_import_pos, import_modifier,
  )
  let module_specifier = self._parse_module_specifier()
  let attributes = self._try_parse_module_import_attributes()
  ignore(self._parse_semicolon())
  self._finish_parser_node(
    _factory_create_import_declaration(
      modifiers, import_clause, module_specifier, attributes,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_namespace_export(self : ParserState, pos : Int) -> Node {
  self._finish_parser_node(
    _factory_create_namespace_export(self._parse_module_export_name()),
    pos,
  )
}

///|
fn ParserState::_parse_export_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  let saved_await = self._in_await_context()
  self._set_await_context(true)
  let mut export_clause : Node? = None
  let mut module_specifier : Node? = None
  let mut attributes : Node? = None
  let is_type_only = self._parse_optional(_syntax_kind(156))
  let namespace_export_pos = self._get_node_pos()
  if self._parse_optional(_syntax_kind(42)) {
    if self._parse_optional(_syntax_kind(130)) {
      export_clause = Some(self._parse_namespace_export(namespace_export_pos))
    }
    ignore(self._parse_expected(_syntax_kind(161)))
    module_specifier = Some(self._parse_module_specifier())
  } else {
    export_clause = Some(self._parse_named_imports_or_exports(280))
    if self.current_token.to_int() == 161 ||
      (
        self.current_token.to_int() == 11 &&
        !self.scanner._has_flag(TokenFlags::preceding_line_break())
      ) {
      ignore(self._parse_expected(_syntax_kind(161)))
      module_specifier = Some(self._parse_module_specifier())
    }
  }
  if module_specifier is Some(_) &&
    (self.current_token.to_int() == 118 || self.current_token.to_int() == 132) &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    attributes = Some(self._parse_module_import_attributes(self.current_token))
  }
  ignore(self._parse_semicolon())
  self._set_await_context(saved_await)
  self._finish_parser_node(
    _factory_create_export_declaration(
      modifiers, is_type_only, export_clause, module_specifier, attributes,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_export_assignment(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  let saved_await = self._in_await_context()
  self._set_await_context(true)
  let is_export_equals = if self._parse_optional(_syntax_kind(64)) {
    Some(true)
  } else {
    ignore(self._parse_expected(_syntax_kind(90)))
    None
  }
  let expression = self._parse_assignment_expression_or_higher(true)
  ignore(self._parse_semicolon())
  self._set_await_context(saved_await)
  self._finish_parser_node(
    _factory_create_export_assignment(modifiers, is_export_equals, expression),
    pos,
  )
}

///|
fn ParserState::_parse_namespace_export_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  ignore(self._parse_expected(_syntax_kind(130)))
  ignore(self._parse_expected(_syntax_kind(145)))
  let name = self._parse_identifier()
  ignore(self._parse_semicolon())
  let node = _factory_create_namespace_export_declaration(name)
  _parser_set_node_field(node, "modifiers", NodeList(modifiers))
  self._finish_parser_node(node, pos)
}
