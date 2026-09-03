// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _parser_is_modifier_kind(kind : SyntaxKind) -> Bool {
  match kind.to_int() {
    87
    | 90
    | 95
    | 103
    | 123
    | 124
    | 125
    | 126
    | 128
    | 129
    | 134
    | 138
    | 147
    | 148
    | 164 => true
    _ => false
  }
}

///|
fn _parser_is_class_member_modifier(kind : SyntaxKind) -> Bool {
  match kind.to_int() {
    123 | 124 | 125 | 126 | 129 | 148 | 164 => true
    _ => false
  }
}

///|
fn _parser_is_binary_operator(kind : SyntaxKind) -> Bool {
  _parser_binary_operator_precedence(kind) > 0
}

///|
fn ParserState::_is_binding_identifier_or_private_identifier_or_pattern(
  self : ParserState,
) -> Bool {
  self.current_token.to_int() == 19 ||
  self.current_token.to_int() == 23 ||
  self.current_token.to_int() == 81 ||
  self._is_binding_identifier()
}

///|
fn ParserState::_next_token_is_open_paren_or_less_than_or_dot(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  match self.current_token.to_int() {
    21 | 25 | 30 => Some(true)
    _ => None
  }
}

///|
fn ParserState::_next_token_is_identifier_on_same_line(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    self._is_identifier() {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_identifier(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self._is_identifier() {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_identifier_or_keyword(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if _parser_token_is_identifier_or_keyword(self.current_token) {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_identifier_or_keyword_or_greater_than(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if _parser_token_is_identifier_or_keyword(self.current_token) ||
    self.current_token.to_int() == 32 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_start_of_expression(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self._is_start_of_expression() {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_start_of_type(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self._is_start_of_type(false) {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_identifier_or_string_on_same_line(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    (self._is_identifier() || self.current_token.to_int() == 11) {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_identifier_or_keyword_on_same_line(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    _parser_token_is_identifier_or_keyword(self.current_token) {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_binding_or_object_pattern_on_same_line(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    (self._is_binding_identifier() || self.current_token.to_int() == 19) {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_using_declaration(self : ParserState) -> Bool? {
  ignore(self._next_token())
  guard self.current_token.to_int() == 160 else { return None }
  self._next_token_is_binding_or_object_pattern_on_same_line()
}

///|
fn ParserState::_is_declaration_worker(self : ParserState) -> Bool {
  while true {
    match self.current_token.to_int() {
      86 | 87 | 94 | 100 | 115 | 121 => return true
      160 =>
        return self._look_ahead(fn() {
            self._next_token_is_binding_or_object_pattern_on_same_line()
          })
          is Some(_)
      135 =>
        return self._look_ahead(fn() { self._next_token_is_using_declaration() })
          is Some(_)
      120 | 156 | 166 =>
        return self._next_token_is_identifier_on_same_line() is Some(_)
      144 | 145 =>
        return self._next_token_is_identifier_or_string_on_same_line()
          is Some(_)
      123 | 124 | 125 | 128 | 129 | 134 | 138 | 148 => {
        let previous = self.current_token.to_int()
        ignore(self._next_token())
        if self.scanner._has_flag(TokenFlags::preceding_line_break()) {
          return false
        }
        if previous == 138 && self.current_token.to_int() == 156 {
          return true
        }
      }
      162 => {
        ignore(self._next_token())
        return self.current_token.to_int() == 19 ||
          self.current_token.to_int() == 80 ||
          self.current_token.to_int() == 95
      }
      102 => {
        ignore(self._next_token())
        return self.current_token.to_int() == 166 ||
          self.current_token.to_int() == 11 ||
          self.current_token.to_int() == 42 ||
          self.current_token.to_int() == 19 ||
          _parser_token_is_identifier_or_keyword(self.current_token)
      }
      95 => {
        ignore(self._next_token())
        let candidate = if self.current_token.to_int() == 156 {
          match self._look_ahead(fn() { Some(self._next_token()) }) {
            Some(token) => token.to_int()
            None => self.current_token.to_int()
          }
        } else {
          self.current_token.to_int()
        }
        match candidate {
          19 | 42 | 60 | 64 | 90 | 130 => return true
          _ => ()
        }
      }
      126 => ignore(self._next_token())
      _ => return false
    }
  }
  false
}

///|
fn ParserState::_is_start_of_declaration(self : ParserState) -> Bool {
  self._look_ahead(fn() {
    if self._is_declaration_worker() {
      Some(true)
    } else {
      None
    }
  })
  is Some(_)
}

///|
fn ParserState::_is_start_of_left_hand_side_expression(
  self : ParserState,
) -> Bool {
  match self.current_token.to_int() {
    9
    | 10
    | 11
    | 15
    | 16
    | 19
    | 21
    | 23
    | 44
    | 69
    | 80
    | 86
    | 97
    | 100
    | 105
    | 106
    | 108
    | 110
    | 112 => true
    102 =>
      self._look_ahead(fn() {
        self._next_token_is_open_paren_or_less_than_or_dot()
      })
      is Some(_)
    _ => self._is_identifier()
  }
}

///|
fn ParserState::_is_start_of_expression(self : ParserState) -> Bool {
  if self._is_start_of_left_hand_side_expression() {
    return true
  }
  match self.current_token.to_int() {
    30 | 40 | 41 | 46 | 47 | 54 | 55 | 60 | 81 | 91 | 114 | 116 | 127 | 135 =>
      true
    103 if self._in_context(NodeFlags::disallow_in_context()) => false
    _ => _parser_is_binary_operator(self.current_token) || self._is_identifier()
  }
}

///|
fn ParserState::_is_start_of_expression_statement(self : ParserState) -> Bool {
  self.current_token.to_int() != 19 &&
  self.current_token.to_int() != 100 &&
  self.current_token.to_int() != 86 &&
  self.current_token.to_int() != 60 &&
  self._is_start_of_expression()
}

///|
fn ParserState::_is_start_of_statement(self : ParserState) -> Bool {
  match self.current_token.to_int() {
    19
    | 27
    | 60
    | 83
    | 85
    | 86
    | 88
    | 89
    | 92
    | 94
    | 98
    | 99
    | 100
    | 101
    | 107
    | 109
    | 111
    | 113
    | 115
    | 117
    | 118
    | 120
    | 121
    | 134
    | 138
    | 144
    | 145
    | 156
    | 160
    | 162
    | 166 => true
    102 =>
      self._is_start_of_declaration() ||
      self._look_ahead(fn() {
        self._next_token_is_open_paren_or_less_than_or_dot()
      })
      is Some(_)
    87 | 95 => self._is_start_of_declaration()
    123 | 124 | 125 | 126 | 129 | 148 =>
      self._is_start_of_declaration() ||
      self._look_ahead(fn() {
        self._next_token_is_identifier_or_keyword_on_same_line()
      })
      is None
    _ => self._is_start_of_expression()
  }
}

///|
fn ParserState::_is_start_of_type(
  self : ParserState,
  in_start_of_parameter : Bool,
) -> Bool {
  match self.current_token.to_int() {
    9
    | 10
    | 11
    | 15
    | 16
    | 19
    | 23
    | 26
    | 30
    | 42
    | 51
    | 52
    | 54
    | 58
    | 97
    | 102
    | 105
    | 106
    | 110
    | 112
    | 114
    | 116
    | 131
    | 133
    | 136
    | 140
    | 146
    | 148
    | 150
    | 151
    | 154
    | 155
    | 157
    | 158
    | 159
    | 163 => true
    100 => !in_start_of_parameter
    41 =>
      !in_start_of_parameter &&
      self._look_ahead(fn() {
        ignore(self._next_token())
        if self.current_token.to_int() == 9 || self.current_token.to_int() == 10 {
          Some(true)
        } else {
          None
        }
      })
      is Some(_)
    21 =>
      !in_start_of_parameter &&
      self._look_ahead(fn() {
        ignore(self._next_token())
        if self.current_token.to_int() == 22 ||
          self._is_start_of_parameter(false) ||
          self._is_start_of_type(false) {
          Some(true)
        } else {
          None
        }
      })
      is Some(_)
    _ => self._is_identifier()
  }
}

///|
fn ParserState::_is_start_of_parameter(
  self : ParserState,
  is_jsdoc_parameter : Bool,
) -> Bool {
  self.current_token.to_int() == 26 ||
  self._is_binding_identifier_or_private_identifier_or_pattern() ||
  _parser_is_modifier_kind(self.current_token) ||
  self.current_token.to_int() == 60 ||
  self._is_start_of_type(!is_jsdoc_parameter)
}

///|
fn ParserState::_is_type_member_start_worker(self : ParserState) -> Bool {
  match self.current_token.to_int() {
    21 | 30 | 139 | 153 => return true
    _ => ()
  }
  let mut has_id_token = false
  while _parser_is_modifier_kind(self.current_token) {
    has_id_token = true
    ignore(self._next_token())
  }
  if self.current_token.to_int() == 23 {
    return true
  }
  if self._is_literal_property_name() {
    has_id_token = true
    ignore(self._next_token())
  }
  if has_id_token {
    match self.current_token.to_int() {
      21 | 30 | 58 | 59 | 28 => return true
      _ => return self._can_parse_semicolon()
    }
  }
  false
}

///|
fn ParserState::_is_type_member_start(self : ParserState) -> Bool {
  self._look_ahead(fn() {
    if self._is_type_member_start_worker() {
      Some(true)
    } else {
      None
    }
  })
  is Some(_)
}

///|
fn ParserState::_is_class_member_start_worker(self : ParserState) -> Bool {
  if self.current_token.to_int() == 60 {
    return true
  }
  let mut id_token : SyntaxKind? = None
  while _parser_is_modifier_kind(self.current_token) {
    id_token = Some(self.current_token)
    if _parser_is_class_member_modifier(self.current_token) {
      return true
    }
    ignore(self._next_token())
  }
  if self.current_token.to_int() == 42 {
    return true
  }
  if self._is_literal_property_name() {
    id_token = Some(self.current_token)
    ignore(self._next_token())
  }
  if self.current_token.to_int() == 23 {
    return true
  }
  match id_token {
    Some(id_token) => {
      if !_parser_token_is_keyword(id_token) ||
        id_token.to_int() == 153 ||
        id_token.to_int() == 139 {
        return true
      }
      match self.current_token.to_int() {
        21 | 30 | 54 | 58 | 59 | 64 => true
        _ => self._can_parse_semicolon()
      }
    }
    None => false
  }
}

///|
fn ParserState::_is_class_member_start(self : ParserState) -> Bool {
  self._look_ahead(fn() {
    if self._is_class_member_start_worker() {
      Some(true)
    } else {
      None
    }
  })
  is Some(_)
}

///|
fn ParserState::_is_valid_heritage_clause_object_literal(
  self : ParserState,
) -> Bool? {
  guard self.current_token.to_int() == 19 else { return None }
  ignore(self._next_token())
  if self.current_token.to_int() != 20 {
    return Some(true)
  }
  ignore(self._next_token())
  match self.current_token.to_int() {
    19 | 28 | 96 | 119 => Some(true)
    _ => None
  }
}

///|
fn ParserState::_is_heritage_clause_element(
  self : ParserState,
  in_error_recovery : Bool,
) -> Bool {
  if self.current_token.to_int() == 19 {
    return self._look_ahead(fn() {
        self._is_valid_heritage_clause_object_literal()
      })
      is Some(_)
  }
  if self._is_heritage_clause_extends_or_implements_keyword() {
    return false
  }
  if in_error_recovery {
    self._is_identifier()
  } else {
    self._is_start_of_left_hand_side_expression()
  }
}

///|
fn ParserState::_is_heritage_clause_extends_or_implements_keyword(
  self : ParserState,
) -> Bool {
  guard self.current_token.to_int() == 96 || self.current_token.to_int() == 119 else {
    return false
  }
  self._look_ahead(fn() { self._next_token_is_start_of_expression() })
  is Some(_)
}

///|
fn ParserState::_next_token_is_string_literal(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 11 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_is_list_element(
  self : ParserState,
  context : ParsingContext,
  in_error_recovery : Bool,
) -> Bool {
  match context.to_int() {
    0 | 1 | 3 =>
      !(self.current_token.to_int() == 27 && in_error_recovery) &&
      self._is_start_of_statement()
    2 => self.current_token.to_int() == 84 || self.current_token.to_int() == 90
    4 => self._is_type_member_start()
    5 =>
      self._is_class_member_start() ||
      (self.current_token.to_int() == 27 && !in_error_recovery)
    6 => self.current_token.to_int() == 23 || self._is_literal_property_name()
    7 => self._is_heritage_clause_element(in_error_recovery)
    8 => self._is_binding_identifier_or_private_identifier_or_pattern()
    9 =>
      self.current_token.to_int() == 23 ||
      self.current_token.to_int() == 26 ||
      self._is_literal_property_name()
    10 =>
      self.current_token.to_int() == 28 ||
      self.current_token.to_int() == 26 ||
      self._is_binding_identifier_or_private_identifier_or_pattern()
    11 => self.current_token.to_int() == 26 || self._is_start_of_expression()
    12 =>
      match self.current_token.to_int() {
        23 | 25 | 26 | 42 => true
        _ => self._is_literal_property_name()
      }
    13 =>
      _parser_token_is_identifier_or_keyword(self.current_token) ||
      self.current_token.to_int() == 19
    14 | 25 => true
    15 =>
      self.current_token.to_int() == 28 ||
      self.current_token.to_int() == 25 ||
      self.current_token.to_int() == 26 ||
      self._is_start_of_expression()
    16 => self._is_start_of_parameter(false)
    17 => self._is_start_of_parameter(true)
    18 => self._is_literal_property_name()
    19 =>
      self.current_token.to_int() == 103 ||
      self.current_token.to_int() == 87 ||
      self._is_identifier()
    20 | 21 =>
      self.current_token.to_int() == 28 || self._is_start_of_type(false)
    22 =>
      self.current_token.to_int() == 96 || self.current_token.to_int() == 119
    23 => {
      if self.current_token.to_int() == 161 &&
        self._look_ahead(fn() { self._next_token_is_string_literal() })
        is Some(_) {
        return false
      }
      self.current_token.to_int() == 11 ||
      _parser_token_is_identifier_or_keyword(self.current_token)
    }
    24 => self._is_import_attribute_name()
    _ => abort("ParsingContext.Count used as a context")
  }
}

///|
fn ParserState::_next_token_is_slash(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 44 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_is_variable_declarator_list_terminator(
  self : ParserState,
) -> Bool {
  self._can_parse_semicolon() ||
  self.current_token.to_int() == 103 ||
  self.current_token.to_int() == 165 ||
  self.current_token.to_int() == 39
}

///|
fn ParserState::_is_list_terminator(
  self : ParserState,
  context : ParsingContext,
) -> Bool {
  if self.current_token.to_int() == 1 {
    return true
  }
  match context.to_int() {
    1 | 2 | 4 | 5 | 6 | 9 | 12 | 23 | 24 => self.current_token.to_int() == 20
    3 =>
      self.current_token.to_int() == 20 ||
      self.current_token.to_int() == 84 ||
      self.current_token.to_int() == 90
    7 =>
      self.current_token.to_int() == 19 ||
      self.current_token.to_int() == 96 ||
      self.current_token.to_int() == 119
    8 => self._is_variable_declarator_list_terminator()
    10 | 15 | 21 => self.current_token.to_int() == 24
    11 => self.current_token.to_int() == 22 || self.current_token.to_int() == 27
    13 => self.current_token.to_int() == 32 || self.current_token.to_int() == 44
    14 =>
      self.current_token.to_int() == 30 &&
      self._look_ahead(fn() { self._next_token_is_slash() }) is Some(_)
    16 | 17 | 18 =>
      self.current_token.to_int() == 22 || self.current_token.to_int() == 24
    19 =>
      self.current_token.to_int() == 32 ||
      self.current_token.to_int() == 21 ||
      self.current_token.to_int() == 19 ||
      self.current_token.to_int() == 96 ||
      self.current_token.to_int() == 119
    20 => self.current_token.to_int() != 28
    22 => self.current_token.to_int() == 19 || self.current_token.to_int() == 20
    _ => false
  }
}

///|
fn ParserState::_is_in_some_parsing_context(self : ParserState) -> Bool {
  guard self.parsing_context != 0U else { return false }
  for value = 0; value < ParsingContext::count(); value = value + 1 {
    let context = ParsingContext(value)
    if (self.parsing_context & context.bit()) != 0U &&
      (
        self._is_list_element(context, true) ||
        self._is_list_terminator(context)
      ) {
      return true
    }
  }
  false
}

///|
fn ParserState::_report_parsing_context_error(
  self : ParserState,
  context : ParsingContext,
) -> Unit {
  let token = self.current_token
  let code = match context.to_int() {
    0 if token.to_int() == 90 => 1005
    0 | 1 => 1128
    2 => 1130
    3 => 1129
    4 | 18 => 1131
    5 => 1068
    6 => 1132
    7 => 1109
    8 if _parser_token_is_keyword(token) => 1389
    8 => 1134
    9 => 1180
    10 => 1181
    11 => 1135
    12 => 1136
    15 => 1137
    16 if _parser_token_is_keyword(token) => 1390
    16 | 17 => 1138
    19 => 1139
    20 => 1140
    21 => 1110
    22 => 1179
    23 if token.to_int() == 161 => 1005
    13 | 14 | 23 | 25 => 1003
    24 => 1478
    _ => abort("ParsingContext.Count used as a context")
  }
  let arguments = match code {
    1005 if context.to_int() == 0 => _parser_text_arguments("export")
    1005 => _parser_text_arguments("}")
    1389 | 1390 => _parser_text_arguments(_parser_token_spelling(token))
    _ => _no_diagnostic_arguments()
  }
  ignore(
    self._parse_error_at_current_token(_diagnostic_message(code), arguments~),
  )
}

///|
fn ParserState::_abort_parsing_list_or_move_to_next_token(
  self : ParserState,
  context : ParsingContext,
) -> Bool {
  self._report_parsing_context_error(context)
  if self._is_in_some_parsing_context() {
    true
  } else {
    ignore(self._next_token())
    false
  }
}

///|
fn ParserState::_parse_list(
  self : ParserState,
  context : ParsingContext,
  parse_element : () -> Node,
) -> NodeArray {
  let saved_context = self.parsing_context
  self.parsing_context = self.parsing_context | context.bit()
  let elements : Array[Node] = []
  let list_pos = self._get_node_pos()
  while !self._is_list_terminator(context) {
    if self._is_list_element(context, false) {
      let start = self.scanner._token_full_start()
      elements.push(parse_element())
      if start == self.scanner._token_full_start() {
        ignore(self._next_token())
      }
      continue
    }
    if self._abort_parsing_list_or_move_to_next_token(context) {
      break
    }
  }
  self.parsing_context = saved_context
  self._create_parser_node_array(elements, list_pos)
}

///|
fn ParserState::_expected_comma_diagnostic(
  context : ParsingContext,
) -> DiagnosticMessage? {
  if context.to_int() == 6 {
    Some(_diagnostic_message(1357))
  } else {
    None
  }
}

///|
fn ParserState::_parse_delimited_list(
  self : ParserState,
  context : ParsingContext,
  parse_element : () -> Node?,
  consider_semicolon_as_delimiter? : Bool = false,
) -> NodeArray? {
  let saved_context = self.parsing_context
  self.parsing_context = self.parsing_context | context.bit()
  let elements : Array[Node] = []
  let list_pos = self._get_node_pos()
  let mut comma_start = _invalid_position()
  while true {
    if self._is_list_element(context, false) {
      let start = self.scanner._token_full_start()
      match parse_element() {
        Some(element) => elements.push(element)
        None => {
          self.parsing_context = saved_context
          return None
        }
      }
      comma_start = self.scanner._token_start()
      if self._parse_optional(_syntax_kind(28)) {
        continue
      }
      comma_start = _invalid_position()
      if self._is_list_terminator(context) {
        break
      }
      match ParserState::_expected_comma_diagnostic(context) {
        Some(message) =>
          ignore(self._parse_expected(_syntax_kind(28), message~))
        None => ignore(self._parse_expected(_syntax_kind(28)))
      }
      if consider_semicolon_as_delimiter &&
        self.current_token.to_int() == 27 &&
        !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
        ignore(self._next_token())
      }
      if start == self.scanner._token_full_start() {
        ignore(self._next_token())
      }
      continue
    }
    if self._is_list_terminator(context) {
      break
    }
    if self._abort_parsing_list_or_move_to_next_token(context) {
      break
    }
  }
  self.parsing_context = saved_context
  Some(
    self._create_parser_node_array(
      elements,
      list_pos,
      has_trailing_comma=comma_start >= 0,
    ),
  )
}

///|
fn ParserState::_parse_bracketed_list(
  self : ParserState,
  context : ParsingContext,
  parse_element : () -> Node?,
  open : SyntaxKind,
  close : SyntaxKind,
) -> NodeArray? {
  if self._parse_expected(open) {
    let result = self._parse_delimited_list(context, parse_element)
    ignore(self._parse_expected(close))
    result
  } else {
    Some(self._create_missing_list())
  }
}
