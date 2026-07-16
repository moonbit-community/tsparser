// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_parse_prefix_unary_expression(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let operator = self.current_token
  ignore(self._next_token())
  self._finish_parser_node(
    _factory_create_prefix_unary_expression(
      operator,
      self._parse_simple_unary_expression(),
    ),
    pos,
  )
}

///|
fn ParserState::_parse_keyword_unary_expression(
  self : ParserState,
  kind : Int,
) -> Node {
  let pos = self._get_node_pos()
  ignore(self._next_token())
  let expression = self._parse_simple_unary_expression()
  let node = match kind {
    221 => _factory_create_delete_expression(expression)
    222 => _factory_create_type_of_expression(expression)
    223 => _factory_create_void_expression(expression)
    224 => _factory_create_await_expression(expression)
    _ => abort("invalid keyword unary expression")
  }
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_is_await_expression(self : ParserState) -> Bool {
  self.current_token.to_int() == 135 &&
  (
    self._in_await_context() ||
    self._look_ahead(fn() {
      self._next_token_is_identifier_or_keyword_or_literal_on_same_line()
    })
    is Some(_)
  )
}

///|
fn ParserState::_parse_type_assertion(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(30)))
  let type_node = self._parse_type()
  ignore(self._parse_expected(_syntax_kind(32)))
  self._finish_parser_node(
    _factory_create_type_assertion(
      type_node,
      self._parse_simple_unary_expression(),
    ),
    pos,
  )
}

///|
fn ParserState::_parse_simple_unary_expression(self : ParserState) -> Node {
  match self.current_token.to_int() {
    40 | 41 | 54 | 55 => self._parse_prefix_unary_expression()
    91 => self._parse_keyword_unary_expression(221)
    114 => self._parse_keyword_unary_expression(222)
    116 => self._parse_keyword_unary_expression(223)
    30 =>
      if self.language_variant == LanguageVariant::jsx() {
        self._parse_jsx_element_or_self_closing_element_or_fragment(
          true,
          must_be_unary=true,
        )
      } else {
        self._parse_type_assertion()
      }
    135 if self._is_await_expression() =>
      self._parse_keyword_unary_expression(224)
    _ => self._parse_update_expression()
  }
}

///|
fn ParserState::_is_update_expression(self : ParserState) -> Bool {
  match self.current_token.to_int() {
    40 | 41 | 54 | 55 | 91 | 114 | 116 | 135 => false
    30 => self.language_variant == LanguageVariant::jsx()
    _ => true
  }
}

///|
fn ParserState::_parse_update_expression(self : ParserState) -> Node {
  if self.current_token.to_int() == 46 || self.current_token.to_int() == 47 {
    let pos = self._get_node_pos()
    let operator = self.current_token
    ignore(self._next_token())
    return self._finish_parser_node(
      _factory_create_prefix_unary_expression(
        operator,
        self._parse_left_hand_side_expression_or_higher(),
      ),
      pos,
    )
  }
  if self.language_variant == LanguageVariant::jsx() &&
    self.current_token.to_int() == 30 &&
    self._look_ahead(fn() {
      self._next_token_is_identifier_or_keyword_or_greater_than()
    })
    is Some(_) {
    return self._parse_jsx_element_or_self_closing_element_or_fragment(true)
  }
  let expression = self._parse_left_hand_side_expression_or_higher()
  if (self.current_token.to_int() == 46 || self.current_token.to_int() == 47) &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    let operator = self.current_token
    ignore(self._next_token())
    return self._finish_parser_node(
      _factory_create_postfix_unary_expression(expression, operator),
      expression.pos(),
    )
  }
  expression
}

///|
fn ParserState::_parse_unary_expression_or_higher(self : ParserState) -> Node {
  if self._is_update_expression() {
    let pos = self._get_node_pos()
    let expression = self._parse_update_expression()
    if self.current_token.to_int() == 43 {
      return self._parse_binary_expression_rest(
        _parser_binary_operator_precedence(self.current_token),
        expression,
        pos,
      )
    }
    return expression
  }
  let unary_operator = self.current_token
  let expression = self._parse_simple_unary_expression()
  if self.current_token.to_int() == 43 {
    let source = SourceText::new(self.source_text)
    let start = skip_trivia(source, expression.pos())
    if expression.kind().to_int() == 217 {
      ignore(
        self._parse_error_at(
          start,
          expression.end(),
          _diagnostic_message(17007),
        ),
      )
    } else {
      ignore(
        self._parse_error_at(
          start,
          expression.end(),
          _diagnostic_message(17006),
          arguments=_parser_text_arguments(
            _parser_token_spelling(unary_operator),
          ),
        ),
      )
    }
  }
  expression
}
