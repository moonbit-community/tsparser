// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_parse_block(
  self : ParserState,
  ignore_missing_open_brace : Bool,
  message? : DiagnosticMessage,
) -> Node {
  let pos = self._get_node_pos()
  let open_position = self.scanner._token_start()
  let open_parsed = match message {
    Some(message) => self._parse_expected(_syntax_kind(19), message~)
    None => self._parse_expected(_syntax_kind(19))
  }
  if open_parsed || ignore_missing_open_brace {
    let multi_line = self.scanner._has_flag(TokenFlags::preceding_line_break())
    let statements = self._parse_list(ParsingContext::block_statements(), fn() {
      self._parse_statement()
    })
    self._parse_expected_matching_brackets(
      _syntax_kind(19),
      _syntax_kind(20),
      open_parsed,
      open_position,
    )
    let result = self._finish_parser_node(
      _factory_create_block(statements, multi_line~),
      pos,
    )
    if self.current_token.to_int() == 64 {
      ignore(self._parse_error_at_current_token(_diagnostic_message(2809)))
      ignore(self._next_token())
    }
    result
  } else {
    self._finish_parser_node(
      _factory_create_block(self._create_missing_list()),
      pos,
    )
  }
}

///|
fn ParserState::_parse_function_block(
  self : ParserState,
  flags : ParserSignatureFlags,
  message? : DiagnosticMessage,
) -> Node {
  let saved_yield = self._in_yield_context()
  let saved_await = self._in_await_context()
  let saved_top_level = self.top_level
  let saved_decorator = self._in_decorator_context()
  self._set_yield_context(
    (flags.bits() & ParserSignatureFlags::yield_flag().bits()) != 0U,
  )
  self._set_await_context(
    (flags.bits() & ParserSignatureFlags::await_flag().bits()) != 0U,
  )
  self.top_level = false
  if saved_decorator {
    self._set_decorator_context(false)
  }
  let ignore_missing = (
      flags.bits() & ParserSignatureFlags::ignore_missing_open_brace().bits()
    ) !=
    0U
  let block = match message {
    Some(message) => self._parse_block(ignore_missing, message~)
    None => self._parse_block(ignore_missing)
  }
  if saved_decorator {
    self._set_decorator_context(true)
  }
  self.top_level = saved_top_level
  self._set_yield_context(saved_yield)
  self._set_await_context(saved_await)
  block
}

///|
fn ParserState::_parse_empty_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(27)))
  self._finish_parser_node(_factory_create_empty_statement(), pos)
}

///|
fn ParserState::_parse_if_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(101)))
  let open_position = self.scanner._token_start()
  let open_parsed = self._parse_expected(_syntax_kind(21))
  let expression = self._allow_in_and(fn() { self._parse_expression() })
  self._parse_expected_matching_brackets(
    _syntax_kind(21),
    _syntax_kind(22),
    open_parsed,
    open_position,
  )
  let then_statement = self._parse_statement()
  let else_statement = if self._parse_optional(_syntax_kind(93)) {
    Some(self._parse_statement())
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_if_statement(expression, then_statement, else_statement),
    pos,
  )
}

///|
fn ParserState::_parse_do_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(92)))
  let statement = self._parse_statement()
  ignore(self._parse_expected(_syntax_kind(117)))
  let open_position = self.scanner._token_start()
  let open_parsed = self._parse_expected(_syntax_kind(21))
  let expression = self._allow_in_and(fn() { self._parse_expression() })
  self._parse_expected_matching_brackets(
    _syntax_kind(21),
    _syntax_kind(22),
    open_parsed,
    open_position,
  )
  ignore(self._parse_optional(_syntax_kind(27)))
  self._finish_parser_node(
    _factory_create_do_statement(statement, expression),
    pos,
  )
}

///|
fn ParserState::_parse_while_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(117)))
  let open_position = self.scanner._token_start()
  let open_parsed = self._parse_expected(_syntax_kind(21))
  let expression = self._allow_in_and(fn() { self._parse_expression() })
  self._parse_expected_matching_brackets(
    _syntax_kind(21),
    _syntax_kind(22),
    open_parsed,
    open_position,
  )
  self._finish_parser_node(
    _factory_create_while_statement(expression, self._parse_statement()),
    pos,
  )
}

///|
fn ParserState::_for_initializer_or_missing(
  self : ParserState,
  initializer : Node?,
) -> Node {
  match initializer {
    Some(initializer) => initializer
    None => self._create_missing_parser_node(_syntax_kind(80), true)
  }
}

///|
fn ParserState::_parse_for_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(99)))
  let await_token = self._parse_optional_token(_syntax_kind(135))
  ignore(self._parse_expected(_syntax_kind(21)))
  let mut initializer : Node? = None
  if self.current_token.to_int() != 27 {
    let variable_start = match self.current_token.to_int() {
      115 | 121 | 87 => true
      160 => self._is_using_declaration()
      135 => self._is_await_using_declaration()
      _ => false
    }
    initializer = Some(
      if variable_start {
        self._parse_variable_declaration_list(true)
      } else {
        self._disallow_in_and(fn() { self._parse_expression() })
      },
    )
  }
  let is_for_of = match await_token {
    Some(_) => self._parse_expected(_syntax_kind(165))
    None => self._parse_optional(_syntax_kind(165))
  }
  if is_for_of {
    let expression = self._allow_in_and(fn() {
      self._parse_assignment_expression_or_higher(true)
    })
    ignore(self._parse_expected(_syntax_kind(22)))
    return self._finish_parser_node(
      _factory_create_for_of_statement(
        await_token,
        self._for_initializer_or_missing(initializer),
        expression,
        self._parse_statement(),
      ),
      pos,
    )
  }
  if self._parse_optional(_syntax_kind(103)) {
    let expression = self._allow_in_and(fn() { self._parse_expression() })
    ignore(self._parse_expected(_syntax_kind(22)))
    return self._finish_parser_node(
      _factory_create_for_in_statement(
        self._for_initializer_or_missing(initializer),
        expression,
        self._parse_statement(),
      ),
      pos,
    )
  }
  ignore(self._parse_expected(_syntax_kind(27)))
  let condition = if self.current_token.to_int() != 27 &&
    self.current_token.to_int() != 22 {
    Some(self._allow_in_and(fn() { self._parse_expression() }))
  } else {
    None
  }
  ignore(self._parse_expected(_syntax_kind(27)))
  let incrementor = if self.current_token.to_int() != 22 {
    Some(self._allow_in_and(fn() { self._parse_expression() }))
  } else {
    None
  }
  ignore(self._parse_expected(_syntax_kind(22)))
  self._finish_parser_node(
    _factory_create_for_statement(
      initializer,
      condition,
      incrementor,
      self._parse_statement(),
    ),
    pos,
  )
}

///|
fn ParserState::_parse_break_or_continue_statement(
  self : ParserState,
  kind : Int,
) -> Node {
  let pos = self._get_node_pos()
  ignore(
    self._parse_expected(
      if kind == 253 {
        _syntax_kind(83)
      } else {
        _syntax_kind(88)
      },
    ),
  )
  let label = if self._can_parse_semicolon() {
    None
  } else {
    Some(self._parse_identifier())
  }
  ignore(self._parse_semicolon())
  self._finish_parser_node(
    if kind == 253 {
      _factory_create_break_statement(label)
    } else {
      _factory_create_continue_statement(label)
    },
    pos,
  )
}

///|
fn ParserState::_parse_return_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(107)))
  let expression = if self._can_parse_semicolon() {
    None
  } else {
    Some(self._allow_in_and(fn() { self._parse_expression() }))
  }
  ignore(self._parse_semicolon())
  self._finish_parser_node(_factory_create_return_statement(expression), pos)
}

///|
fn ParserState::_parse_with_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(118)))
  let open_position = self.scanner._token_start()
  let open_parsed = self._parse_expected(_syntax_kind(21))
  let expression = self._allow_in_and(fn() { self._parse_expression() })
  self._parse_expected_matching_brackets(
    _syntax_kind(21),
    _syntax_kind(22),
    open_parsed,
    open_position,
  )
  let statement = self._do_inside_of_context(NodeFlags::in_with_statement(), fn() {
    self._parse_statement()
  })
  self._finish_parser_node(
    _factory_create_with_statement(expression, statement),
    pos,
  )
}

///|
fn ParserState::_parse_case_clause(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(84)))
  let expression = self._allow_in_and(fn() { self._parse_expression() })
  ignore(self._parse_expected(_syntax_kind(59)))
  let statements = self._parse_list(
    ParsingContext::switch_clause_statements(),
    fn() { self._parse_statement() },
  )
  self._finish_parser_node(
    _factory_create_case_clause(expression, statements),
    pos,
  )
}

///|
fn ParserState::_parse_default_clause(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(90)))
  ignore(self._parse_expected(_syntax_kind(59)))
  let statements = self._parse_list(
    ParsingContext::switch_clause_statements(),
    fn() { self._parse_statement() },
  )
  self._finish_parser_node(_factory_create_default_clause(statements), pos)
}

///|
fn ParserState::_parse_case_block(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(19)))
  let clauses = self._parse_list(ParsingContext::switch_clauses(), fn() {
    if self.current_token.to_int() == 84 {
      self._parse_case_clause()
    } else {
      self._parse_default_clause()
    }
  })
  ignore(self._parse_expected(_syntax_kind(20)))
  self._finish_parser_node(_factory_create_case_block(clauses), pos)
}

///|
fn ParserState::_parse_switch_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(109)))
  ignore(self._parse_expected(_syntax_kind(21)))
  let expression = self._allow_in_and(fn() { self._parse_expression() })
  ignore(self._parse_expected(_syntax_kind(22)))
  self._finish_parser_node(
    _factory_create_switch_statement(expression, self._parse_case_block()),
    pos,
  )
}

///|
fn ParserState::_parse_throw_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(111)))
  let expression = if self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    self.identifier_count += 1
    self._create_missing_parser_node(_syntax_kind(80), false)
  } else {
    self._allow_in_and(fn() { self._parse_expression() })
  }
  if !self._try_parse_semicolon() {
    self._parse_error_for_missing_semicolon_after(expression)
  }
  self._finish_parser_node(_factory_create_throw_statement(expression), pos)
}

///|
fn ParserState::_parse_catch_clause(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(85)))
  let variable = if self._parse_optional(_syntax_kind(21)) {
    let declaration = self._parse_variable_declaration(false)
    ignore(self._parse_expected(_syntax_kind(22)))
    Some(declaration)
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_catch_clause(variable, self._parse_block(false)),
    pos,
  )
}

///|
fn ParserState::_parse_try_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(113)))
  let try_block = self._parse_block(false)
  let catch_clause = if self.current_token.to_int() == 85 {
    Some(self._parse_catch_clause())
  } else {
    None
  }
  let finally_block = if catch_clause is None ||
    self.current_token.to_int() == 98 {
    ignore(
      self._parse_expected(_syntax_kind(98), message=_diagnostic_message(1472)),
    )
    Some(self._parse_block(false))
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_try_statement(try_block, catch_clause, finally_block),
    pos,
  )
}

///|
fn ParserState::_parse_debugger_statement(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(89)))
  ignore(self._parse_semicolon())
  self._finish_parser_node(_factory_create_debugger_statement(), pos)
}

///|
fn ParserState::_parse_expression_or_labeled_statement(
  self : ParserState,
) -> Node {
  let pos = self._get_node_pos()
  let expression = self._allow_in_and(fn() { self._parse_expression() })
  let node = if expression.kind().to_int() == 80 &&
    self._parse_optional(_syntax_kind(59)) {
    _factory_create_labeled_statement(expression, self._parse_statement())
  } else {
    if !self._try_parse_semicolon() {
      self._parse_error_for_missing_semicolon_after(expression)
    }
    _factory_create_expression_statement(expression)
  }
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_statement(self : ParserState) -> Node {
  match self.current_token.to_int() {
    27 => self._parse_empty_statement()
    19 => self._parse_block(false)
    115 => self._parse_variable_statement(self._get_node_pos(), None)
    121 if self._is_let_declaration() =>
      self._parse_variable_statement(self._get_node_pos(), None)
    135 if self._is_await_using_declaration() =>
      self._parse_variable_statement(self._get_node_pos(), None)
    160 if self._is_using_declaration() =>
      self._parse_variable_statement(self._get_node_pos(), None)
    100 => self._parse_function_declaration(self._get_node_pos(), None)
    86 => self._parse_class_declaration(self._get_node_pos(), None)
    101 => self._parse_if_statement()
    92 => self._parse_do_statement()
    117 => self._parse_while_statement()
    99 => self._parse_for_statement()
    88 => self._parse_break_or_continue_statement(252)
    83 => self._parse_break_or_continue_statement(253)
    107 => self._parse_return_statement()
    118 => self._parse_with_statement()
    109 => self._parse_switch_statement()
    111 => self._parse_throw_statement()
    113 | 85 | 98 => self._parse_try_statement()
    89 => self._parse_debugger_statement()
    60 => self._parse_declaration()
    87
    | 94
    | 95
    | 102
    | 120
    | 123
    | 124
    | 125
    | 126
    | 128
    | 129
    | 134
    | 138
    | 144
    | 145
    | 148
    | 156
    | 162 =>
      if self._is_start_of_declaration() {
        self._parse_declaration()
      } else {
        self._parse_expression_or_labeled_statement()
      }
    _ => self._parse_expression_or_labeled_statement()
  }
}

///|
fn _parser_is_declaration_file_name(file_name : String) -> Bool {
  is_declaration_file_name(file_name)
}

///|
fn _parse_statements_for_test(
  text : String,
  file_name? : String = "statements.ts",
  script_kind? : ScriptKind = ScriptKind::ts(),
) -> (NodeArray, Array[Diagnostic], SyntaxKind, NodeFlags) {
  let state = _new_parser_state(file_name, text, script_kind~)
  if _parser_is_declaration_file_name(file_name) {
    state._set_context_flag(true, NodeFlags::ambient())
  }
  ignore(state._prime())
  let statements = state._parse_list(ParsingContext::source_elements(), fn() {
    state._parse_statement()
  })
  let diagnostics = state.diagnostics.copy()
  let token = state.current_token
  let flags = state.context_flags
  state._dispose()
  (statements, diagnostics, token, flags)
}
