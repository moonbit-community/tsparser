// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts and src/compiler/utilities.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _parser_binary_operator_precedence(kind : SyntaxKind) -> Int {
  match kind.to_int() {
    61 | 57 => 5
    56 => 6
    52 => 7
    53 => 8
    51 => 9
    35 | 36 | 37 | 38 => 10
    30 | 32 | 33 | 34 | 103 | 104 | 130 | 152 => 11
    48 | 49 | 50 => 12
    40 | 41 => 13
    42 | 44 | 45 => 14
    43 => 15
    _ => -1
  }
}

///|
fn _parser_is_assignment_operator(kind : SyntaxKind) -> Bool {
  kind.to_int() >= 64 && kind.to_int() <= 79
}

///|
fn _parser_is_left_hand_side_expression(node : Node) -> Bool {
  match node.kind().to_int() {
    9
    | 10
    | 11
    | 14
    | 15
    | 80
    | 81
    | 97
    | 106
    | 108
    | 110
    | 112
    | 210
    | 211
    | 212
    | 213
    | 214
    | 215
    | 216
    | 218
    | 219
    | 229
    | 232
    | 234
    | 236
    | 237
    | 282
    | 283
    | 288 => true
    _ => false
  }
}

///|
fn ParserState::_next_token_is_identifier_or_keyword_or_literal_on_same_line(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    (
      _parser_token_is_identifier_or_keyword(self.current_token) ||
      self.current_token.to_int() == 9 ||
      self.current_token.to_int() == 10 ||
      self.current_token.to_int() == 11
    ) {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_parse_expression(self : ParserState) -> Node {
  let saved_decorator = self._in_decorator_context()
  if saved_decorator {
    self._set_decorator_context(false)
  }
  let pos = self._get_node_pos()
  let mut expression = self._parse_assignment_expression_or_higher(true)
  while self.current_token.to_int() == 28 {
    let operator = self._parse_token_node()
    expression = self._finish_parser_node(
      _factory_create_binary_expression(
        expression,
        operator,
        self._parse_assignment_expression_or_higher(true),
      ),
      pos,
    )
  }
  if saved_decorator {
    self._set_decorator_context(true)
  }
  expression
}

///|
fn ParserState::_parse_initializer(self : ParserState) -> Node? {
  if self._parse_optional(_syntax_kind(64)) {
    Some(self._parse_assignment_expression_or_higher(true))
  } else {
    None
  }
}

///|
fn ParserState::_is_yield_expression(self : ParserState) -> Bool {
  self.current_token.to_int() == 127 &&
  (
    self._in_yield_context() ||
    self._look_ahead(fn() {
      self._next_token_is_identifier_or_keyword_or_literal_on_same_line()
    })
    is Some(_)
  )
}

///|
fn ParserState::_parse_yield_expression(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._next_token())
  let mut asterisk : Node? = None
  let mut expression : Node? = None
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    (self.current_token.to_int() == 42 || self._is_start_of_expression()) {
    asterisk = self._parse_optional_token(_syntax_kind(42))
    expression = Some(self._parse_assignment_expression_or_higher(true))
  }
  self._finish_parser_node(
    _factory_create_yield_expression(asterisk, expression),
    pos,
  )
}

///|
fn ParserState::_parse_assignment_expression_or_higher(
  self : ParserState,
  allow_return_type_in_arrow_function : Bool,
) -> Node {
  if self._is_yield_expression() {
    return self._parse_yield_expression()
  }
  match
    self._try_parse_parenthesized_arrow_function_expression(
      allow_return_type_in_arrow_function,
    ) {
    Some(arrow) => return arrow
    None => ()
  }
  match
    self._try_parse_async_simple_arrow_function_expression(
      allow_return_type_in_arrow_function,
    ) {
    Some(arrow) => return arrow
    None => ()
  }
  let pos = self._get_node_pos()
  let expression = self._parse_binary_expression_or_higher(0)
  if expression.kind().to_int() == 80 && self.current_token.to_int() == 39 {
    return self._parse_simple_arrow_function_expression(
      pos,
      expression,
      allow_return_type_in_arrow_function,
      None,
    )
  }
  ignore(self._re_scan_greater_token())
  if _parser_is_left_hand_side_expression(expression) &&
    _parser_is_assignment_operator(self.current_token) {
    let operator = self._parse_token_node()
    return self._finish_parser_node(
      _factory_create_binary_expression(
        expression,
        operator,
        self._parse_assignment_expression_or_higher(
          allow_return_type_in_arrow_function,
        ),
      ),
      pos,
    )
  }
  self._parse_conditional_expression_rest(
    expression, pos, allow_return_type_in_arrow_function,
  )
}

///|
fn ParserState::_parse_conditional_expression_rest(
  self : ParserState,
  left : Node,
  pos : Int,
  allow_return_type_in_arrow_function : Bool,
) -> Node {
  let question = self._parse_optional_token(_syntax_kind(58))
  guard question is Some(_) else { return left }
  let when_true = self._do_outside_of_context(
    NodeFlags::disallow_in_context().union(NodeFlags::decorator_context()),
    fn() { self._parse_assignment_expression_or_higher(false) },
  )
  let has_colon = self.current_token.to_int() == 59
  let colon = self._parse_expected_token(_syntax_kind(59))
  let when_false = if has_colon {
    self._parse_assignment_expression_or_higher(
      allow_return_type_in_arrow_function,
    )
  } else {
    self._create_missing_parser_node(
      _syntax_kind(80),
      false,
      message=_diagnostic_message(1005),
      arguments=_parser_text_arguments(":"),
    )
  }
  self._finish_parser_node(
    _factory_create_conditional_expression(
      left,
      question,
      when_true,
      Some(colon),
      when_false,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_binary_expression_or_higher(
  self : ParserState,
  precedence : Int,
) -> Node {
  let pos = self._get_node_pos()
  let left = self._parse_unary_expression_or_higher()
  self._parse_binary_expression_rest(precedence, left, pos)
}

///|
fn ParserState::_parse_binary_expression_rest(
  self : ParserState,
  precedence : Int,
  initial_left : Node,
  pos : Int,
) -> Node {
  let mut left = initial_left
  while true {
    ignore(self._re_scan_greater_token())
    let new_precedence = _parser_binary_operator_precedence(self.current_token)
    let consume = if self.current_token.to_int() == 43 {
      new_precedence >= precedence
    } else {
      new_precedence > precedence
    }
    if !consume ||
      (self.current_token.to_int() == 103 && self._in_disallow_in_context()) {
      break
    }
    if self.current_token.to_int() == 130 || self.current_token.to_int() == 152 {
      if self.scanner._has_flag(TokenFlags::preceding_line_break()) {
        break
      }
      let keyword = self.current_token
      ignore(self._next_token())
      let type_node = self._parse_type()
      left = self._finish_parser_node(
        if keyword.to_int() == 152 {
          _factory_create_satisfies_expression(left, type_node)
        } else {
          _factory_create_as_expression(left, type_node)
        },
        left.pos(),
      )
    } else {
      let operator = self._parse_token_node()
      left = self._finish_parser_node(
        _factory_create_binary_expression(
          left,
          operator,
          self._parse_binary_expression_or_higher(new_precedence),
        ),
        pos,
      )
    }
  }
  left
}
