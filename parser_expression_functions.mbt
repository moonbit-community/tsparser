// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_parse_optional_binding_identifier(self : ParserState) -> Node? {
  if self._is_binding_identifier() {
    Some(self._parse_binding_identifier())
  } else {
    None
  }
}

///|
fn ParserState::_parse_function_expression(self : ParserState) -> Node {
  let saved_decorator = self._in_decorator_context()
  if saved_decorator {
    self._set_decorator_context(false)
  }
  let pos = self._get_node_pos()
  let modifiers = self._parse_modifier_list(false, false)
  ignore(self._parse_expected(_syntax_kind(100)))
  let asterisk = self._parse_optional_token(_syntax_kind(42))
  let mut flags = ParserSignatureFlags::none()
  if asterisk is Some(_) {
    flags = flags.union(ParserSignatureFlags::yield_flag())
  }
  if _parser_modifiers_have_async(modifiers) {
    flags = flags.union(ParserSignatureFlags::await_flag())
  }
  let name = if asterisk is Some(_) && _parser_modifiers_have_async(modifiers) {
    self._do_in_yield_and_await_context(fn() {
      self._parse_optional_binding_identifier()
    })
  } else if asterisk is Some(_) {
    self._do_in_yield_context(fn() { self._parse_optional_binding_identifier() })
  } else if _parser_modifiers_have_async(modifiers) {
    self._do_in_await_context(fn() { self._parse_optional_binding_identifier() })
  } else {
    self._parse_optional_binding_identifier()
  }
  let type_parameters = self._parse_type_parameters()
  let parameters = self._parse_parameters(flags)
  let type_node = self._parse_return_type(_syntax_kind(59), false)
  let body = self._parse_function_block(flags)
  if saved_decorator {
    self._set_decorator_context(true)
  }
  self._finish_parser_node(
    _factory_create_function_expression(
      modifiers,
      asterisk,
      name,
      type_parameters,
      Some(parameters),
      type_node,
      body,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_modifiers_for_arrow_function(
  self : ParserState,
) -> NodeArray? {
  if self.current_token.to_int() != 134 {
    return None
  }
  let pos = self._get_node_pos()
  let modifier = self._parse_token_node()
  Some(self._create_parser_node_array([modifier], pos, end=modifier.end()))
}

///|
fn ParserState::_type_has_arrow_function_blocking_parse_error(
  self : ParserState,
  node : Node,
) -> Bool {
  match node.kind().to_int() {
    184 =>
      match _parser_node_field_node(node, "typeName") {
        Some(name) => name.pos() == name.end()
        None => true
      }
    185 | 186 => {
      match _parser_node_field_list(node, "parameters") {
        Some(parameters) if self._is_missing_list(parameters) => return true
        _ => ()
      }
      match _parser_node_field_node(node, "type") {
        Some(type_node) =>
          self._type_has_arrow_function_blocking_parse_error(type_node)
        None => true
      }
    }
    197 =>
      match _parser_node_field_node(node, "type") {
        Some(type_node) =>
          self._type_has_arrow_function_blocking_parse_error(type_node)
        None => true
      }
    _ => false
  }
}

///|
fn ParserState::_parse_simple_arrow_function_expression(
  self : ParserState,
  pos : Int,
  identifier : Node,
  allow_return_type_in_arrow_function : Bool,
  async_modifiers : NodeArray?,
) -> Node {
  let parameter = self._finish_parser_node(
    _factory_create_parameter_declaration(
      None,
      None,
      identifier,
      None,
      None,
      None,
    ),
    identifier.pos(),
    end=identifier.end(),
  )
  let parameters = self._create_parser_node_array(
    [parameter],
    parameter.pos(),
    end=parameter.end(),
  )
  let arrow = self._parse_expected_token(_syntax_kind(39))
  let body = self._parse_arrow_function_expression_body(
    async_modifiers is Some(_),
    allow_return_type_in_arrow_function,
  )
  self._finish_parser_node(
    _factory_create_arrow_function(
      async_modifiers,
      None,
      parameters,
      None,
      Some(arrow),
      body,
    ),
    pos,
  )
}

///|
fn ParserState::_is_parenthesized_arrow_function_expression_worker(
  self : ParserState,
) -> Tristate {
  if self.current_token.to_int() == 134 {
    ignore(self._next_token())
    if self.scanner._has_flag(TokenFlags::preceding_line_break()) ||
      (self.current_token.to_int() != 21 && self.current_token.to_int() != 30) {
      return Tristate::False
    }
  }
  let first = self.current_token
  let second = self._next_token()
  if first.to_int() == 21 {
    if second.to_int() == 22 {
      match self._next_token().to_int() {
        39 | 59 | 19 => return Tristate::True
        _ => return Tristate::False
      }
    }
    if second.to_int() == 23 || second.to_int() == 19 {
      return Tristate::Unknown
    }
    if second.to_int() == 26 {
      return Tristate::True
    }
    if _parser_is_modifier_kind(second) &&
      second.to_int() != 134 &&
      self._look_ahead(fn() { self._next_token_is_identifier() }) is Some(_) {
      if self._next_token().to_int() == 130 {
        return Tristate::False
      }
      return Tristate::True
    }
    if !self._is_identifier() && second.to_int() != 110 {
      return Tristate::False
    }
    match self._next_token().to_int() {
      59 => return Tristate::True
      58 => {
        ignore(self._next_token())
        match self.current_token.to_int() {
          59 | 28 | 64 | 22 => return Tristate::True
          _ => return Tristate::False
        }
      }
      28 | 64 | 22 => return Tristate::Unknown
      _ => return Tristate::False
    }
  }
  if first.to_int() != 30 {
    return Tristate::False
  }
  if !self._is_identifier() && self.current_token.to_int() != 87 {
    return Tristate::False
  }
  if self.language_variant == LanguageVariant::jsx() {
    let is_arrow = self._look_ahead(fn() -> Bool? {
      ignore(self._parse_optional(_syntax_kind(87)))
      let third = self._next_token()
      if third.to_int() == 96 {
        let fourth = self._next_token()
        return match fourth.to_int() {
          64 | 32 | 44 => None
          _ => Some(true)
        }
      }
      match third.to_int() {
        28 | 64 => Some(true)
        _ => None
      }
    })
    if is_arrow is Some(_) {
      return Tristate::True
    }
    return Tristate::False
  }
  Tristate::Unknown
}

///|
fn ParserState::_is_parenthesized_arrow_function_expression(
  self : ParserState,
) -> Tristate {
  if self.current_token.to_int() == 21 ||
    self.current_token.to_int() == 30 ||
    self.current_token.to_int() == 134 {
    return match
      self._look_ahead(fn() {
        Some(self._is_parenthesized_arrow_function_expression_worker())
      }) {
      Some(value) => value
      None => Tristate::False
    }
  }
  if self.current_token.to_int() == 39 {
    Tristate::True
  } else {
    Tristate::False
  }
}

///|
fn ParserState::_parse_possible_parenthesized_arrow_function_expression(
  self : ParserState,
  allow_return_type_in_arrow_function : Bool,
) -> Node? {
  let position = self.scanner._token_start()
  if self._is_not_parenthesized_arrow(position) {
    return None
  }
  let result = self._parse_parenthesized_arrow_function_expression(
    false, allow_return_type_in_arrow_function,
  )
  if result is None {
    self._record_not_parenthesized_arrow(position)
  }
  result
}

///|
fn ParserState::_try_parse_parenthesized_arrow_function_expression(
  self : ParserState,
  allow_return_type_in_arrow_function : Bool,
) -> Node? {
  match self._is_parenthesized_arrow_function_expression() {
    Tristate::False => None
    Tristate::True =>
      self._parse_parenthesized_arrow_function_expression(true, true)
    Tristate::Unknown =>
      self._try_parse(fn() {
        self._parse_possible_parenthesized_arrow_function_expression(
          allow_return_type_in_arrow_function,
        )
      })
  }
}

///|
fn ParserState::_is_unparenthesized_async_arrow_function_worker(
  self : ParserState,
) -> Tristate {
  guard self.current_token.to_int() == 134 else { return Tristate::False }
  ignore(self._next_token())
  if self.scanner._has_flag(TokenFlags::preceding_line_break()) ||
    self.current_token.to_int() == 39 {
    return Tristate::False
  }
  let expression = self._parse_binary_expression_or_higher(0)
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    expression.kind().to_int() == 80 &&
    self.current_token.to_int() == 39 {
    Tristate::True
  } else {
    Tristate::False
  }
}

///|
fn ParserState::_try_parse_async_simple_arrow_function_expression(
  self : ParserState,
  allow_return_type_in_arrow_function : Bool,
) -> Node? {
  guard self.current_token.to_int() == 134 else { return None }
  let state = match
    self._look_ahead(fn() {
      Some(self._is_unparenthesized_async_arrow_function_worker())
    }) {
    Some(state) => state
    None => Tristate::False
  }
  guard state.to_int() == Tristate::True.to_int() else { return None }
  let pos = self._get_node_pos()
  let modifiers = self._parse_modifiers_for_arrow_function()
  let expression = self._parse_binary_expression_or_higher(0)
  Some(
    self._parse_simple_arrow_function_expression(
      pos, expression, allow_return_type_in_arrow_function, modifiers,
    ),
  )
}

///|
fn ParserState::_parse_parenthesized_arrow_function_expression(
  self : ParserState,
  allow_ambiguity : Bool,
  allow_return_type_in_arrow_function : Bool,
) -> Node? {
  let pos = self._get_node_pos()
  let modifiers = self._parse_modifiers_for_arrow_function()
  let flags = if _parser_modifiers_have_async(modifiers) {
    ParserSignatureFlags::await_flag()
  } else {
    ParserSignatureFlags::none()
  }
  let type_parameters = self._parse_type_parameters()
  let parameters = if !self._parse_expected(_syntax_kind(21)) {
    if !allow_ambiguity {
      return None
    }
    self._create_missing_list()
  } else {
    let parameters = match
      self._parse_parameters_worker_with_ambiguity(flags, allow_ambiguity) {
      Some(parameters) => parameters
      None => return None
    }
    if !self._parse_expected(_syntax_kind(22)) && !allow_ambiguity {
      return None
    }
    parameters
  }
  let has_return_colon = self.current_token.to_int() == 59
  let type_node = self._parse_return_type(_syntax_kind(59), false)
  match type_node {
    Some(type_node) if !allow_ambiguity &&
      self._type_has_arrow_function_blocking_parse_error(type_node) =>
      return None
    _ => ()
  }
  if !allow_ambiguity &&
    self.current_token.to_int() != 39 &&
    self.current_token.to_int() != 19 {
    return None
  }
  let last_token = self.current_token
  let arrow = self._parse_expected_token(_syntax_kind(39))
  let body = if last_token.to_int() == 39 || last_token.to_int() == 19 {
    self._parse_arrow_function_expression_body(
      _parser_modifiers_have_async(modifiers),
      allow_return_type_in_arrow_function,
    )
  } else {
    self._parse_identifier()
  }
  if !allow_return_type_in_arrow_function &&
    has_return_colon &&
    self.current_token.to_int() != 59 {
    return None
  }
  Some(
    self._finish_parser_node(
      _factory_create_arrow_function(
        modifiers,
        type_parameters,
        parameters,
        type_node,
        Some(arrow),
        body,
      ),
      pos,
    ),
  )
}

///|
fn ParserState::_parse_arrow_function_expression_body(
  self : ParserState,
  is_async : Bool,
  allow_return_type_in_arrow_function : Bool,
) -> Node {
  if self.current_token.to_int() == 19 {
    return self._parse_function_block(
      if is_async {
        ParserSignatureFlags::await_flag()
      } else {
        ParserSignatureFlags::none()
      },
    )
  }
  if self.current_token.to_int() != 27 &&
    self.current_token.to_int() != 100 &&
    self.current_token.to_int() != 86 &&
    self._is_start_of_statement() &&
    !self._is_start_of_expression_statement() {
    let flags = ParserSignatureFlags::ignore_missing_open_brace().union(
      if is_async {
        ParserSignatureFlags::await_flag()
      } else {
        ParserSignatureFlags::none()
      },
    )
    return self._parse_function_block(flags)
  }
  let saved_yield = self._in_yield_context()
  let saved_top_level = self.top_level
  self._set_yield_context(false)
  self.top_level = false
  let node = if is_async {
    self._do_in_await_context(fn() {
      self._parse_assignment_expression_or_higher(
        allow_return_type_in_arrow_function,
      )
    })
  } else {
    self._do_outside_of_await_context(fn() {
      self._parse_assignment_expression_or_higher(
        allow_return_type_in_arrow_function,
      )
    })
  }
  self.top_level = saved_top_level
  self._set_yield_context(saved_yield)
  node
}

///|
fn _parse_expression_for_test(
  text : String,
  script_kind? : ScriptKind = ScriptKind::ts(),
  context_flags? : NodeFlags = NodeFlags::none(),
) -> (Node, Array[Diagnostic], SyntaxKind, NodeFlags) {
  let state = _new_parser_state("expression.ts", text, script_kind~)
  if context_flags.bits() != 0U {
    state._set_context_flag(true, context_flags)
  }
  ignore(state._prime())
  let node = state._parse_expression()
  let diagnostics = state.diagnostics.copy()
  let token = state.current_token
  let source_flags = state.source_flags
  state._dispose()
  (node, diagnostics, token, source_flags)
}
