// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _parser_text_arguments(value : String) -> ReadOnlyArray[DiagnosticArgument] {
  ReadOnlyArray::from_array([DiagnosticArgument::text(value)])
}

///|
fn _parser_two_text_arguments(
  first : String,
  second : String,
) -> ReadOnlyArray[DiagnosticArgument] {
  ReadOnlyArray::from_array([
    DiagnosticArgument::text(first),
    DiagnosticArgument::text(second),
  ])
}

///|
fn _parser_token_spelling(kind : SyntaxKind) -> String {
  match _token_to_string(kind) {
    Some(spelling) => spelling
    None => kind.runtime_name()
  }
}

///|
fn _parser_token_is_keyword(kind : SyntaxKind) -> Bool {
  kind.to_int() >= 83 && kind.to_int() <= 166
}

///|
fn _parser_token_is_identifier_or_keyword(kind : SyntaxKind) -> Bool {
  kind.to_int() >= 80
}

///|
fn ParserState::_prime(self : ParserState) -> SyntaxKind {
  self._assert_active()
  self._next_token()
}

///|
fn ParserState::_next_token_without_check(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._scan()
  self.current_token
}

///|
fn ParserState::_next_token(self : ParserState) -> SyntaxKind {
  if _parser_token_is_keyword(self.current_token) &&
    (
      self.scanner._has_flag(TokenFlags::unicode_escape()) ||
      self.scanner._has_flag(TokenFlags::extended_unicode_escape())
    ) {
    ignore(
      self._parse_error_at(
        self.scanner._token_start(),
        self.scanner._token_end(),
        _diagnostic_message(1260),
      ),
    )
  }
  self._next_token_without_check()
}

///|
fn[T] ParserState::_next_token_and(self : ParserState, callback : () -> T) -> T {
  ignore(self._next_token())
  callback()
}

///|
fn ParserState::_next_token_jsdoc(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._scan_jsdoc_token()
  self.current_token
}

///|
fn ParserState::_next_jsdoc_comment_text_token(
  self : ParserState,
  in_backticks : Bool,
) -> SyntaxKind {
  self.current_token = self.scanner._scan_jsdoc_comment_text_token(in_backticks)
  self.current_token
}

///|
fn ParserState::_re_scan_greater_token(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_greater_token()
  self.current_token
}

///|
fn ParserState::_re_scan_slash_token(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_slash_token()
  self.current_token
}

///|
fn ParserState::_re_scan_template_token(
  self : ParserState,
  tagged_template : Bool,
) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_template_token(tagged_template)
  self.current_token
}

///|
fn ParserState::_re_scan_less_than_token(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_less_than_token()
  self.current_token
}

///|
fn ParserState::_re_scan_hash_token(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_hash_token()
  self.current_token
}

///|
fn ParserState::_re_scan_question_token(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_question_token()
  self.current_token
}

///|
fn ParserState::_re_scan_asterisk_equals_token(
  self : ParserState,
) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_asterisk_equals_token()
  self.current_token
}

///|
fn ParserState::_scan_jsx_identifier(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._scan_jsx_identifier()
  self.current_token
}

///|
fn ParserState::_scan_jsx_text(
  self : ParserState,
  allow_multiline_text? : Bool = true,
) -> SyntaxKind {
  self.current_token = self.scanner._scan_jsx_token(allow_multiline_text~)
  self.current_token
}

///|
fn ParserState::_re_scan_jsx_text(
  self : ParserState,
  allow_multiline_text? : Bool = true,
) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_jsx_token(allow_multiline_text~)
  self.current_token
}

///|
fn ParserState::_scan_jsx_attribute_value(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._scan_jsx_attribute_value()
  self.current_token
}

///|
fn ParserState::_re_scan_jsx_attribute_value(self : ParserState) -> SyntaxKind {
  self.current_token = self.scanner._re_scan_jsx_attribute_value()
  self.current_token
}

///|
fn ParserState::_is_binding_identifier(self : ParserState) -> Bool {
  self.current_token.to_int() == 80 || self.current_token.to_int() > 118
}

///|
fn ParserState::_is_identifier(self : ParserState) -> Bool {
  if self.current_token.to_int() == 80 {
    return true
  }
  if self.current_token.to_int() == 127 &&
    self._in_context(NodeFlags::yield_context()) {
    return false
  }
  if self.current_token.to_int() == 135 &&
    self._in_context(NodeFlags::await_context()) {
    return false
  }
  self.current_token.to_int() > 118
}

///|
fn ParserState::_parse_expected(
  self : ParserState,
  kind : SyntaxKind,
  message? : DiagnosticMessage,
  should_advance? : Bool = true,
) -> Bool {
  if self.current_token == kind {
    if should_advance {
      ignore(self._next_token())
    }
    return true
  }
  match message {
    Some(message) => ignore(self._parse_error_at_current_token(message))
    None =>
      ignore(
        self._parse_error_at_current_token(
          _diagnostic_message(1005),
          arguments=_parser_text_arguments(_parser_token_spelling(kind)),
        ),
      )
  }
  false
}

///|
fn ParserState::_parse_optional(self : ParserState, kind : SyntaxKind) -> Bool {
  if self.current_token == kind {
    ignore(self._next_token())
    true
  } else {
    false
  }
}

///|
fn ParserState::_parse_token_node(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let kind = self.current_token
  ignore(self._next_token())
  self._finish_parser_node(_factory_create_token(kind), pos)
}

///|
fn ParserState::_parse_token_node_jsdoc(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let kind = self.current_token
  ignore(self._next_token_jsdoc())
  self._finish_parser_node(_factory_create_token(kind), pos)
}

///|
fn ParserState::_parse_optional_token(
  self : ParserState,
  kind : SyntaxKind,
) -> Node? {
  if self.current_token == kind {
    Some(self._parse_token_node())
  } else {
    None
  }
}

///|
fn ParserState::_parse_expected_jsdoc(
  self : ParserState,
  kind : SyntaxKind,
) -> Bool {
  if self.current_token == kind {
    ignore(self._next_token_jsdoc())
    true
  } else {
    ignore(
      self._parse_error_at_current_token(
        _diagnostic_message(1005),
        arguments=_parser_text_arguments(_parser_token_spelling(kind)),
      ),
    )
    false
  }
}

///|
fn ParserState::_parse_optional_token_jsdoc(
  self : ParserState,
  kind : SyntaxKind,
) -> Node? {
  if self.current_token == kind {
    Some(self._parse_token_node_jsdoc())
  } else {
    None
  }
}

///|
fn ParserState::_parse_expected_token_jsdoc(
  self : ParserState,
  kind : SyntaxKind,
) -> Node {
  match self._parse_optional_token_jsdoc(kind) {
    Some(token) => token
    None =>
      self._create_missing_parser_node(
        kind,
        false,
        message=_diagnostic_message(1005),
        arguments=_parser_text_arguments(_parser_token_spelling(kind)),
      )
  }
}

///|
fn ParserState::_parse_expected_token(
  self : ParserState,
  kind : SyntaxKind,
  message? : DiagnosticMessage,
  argument? : String,
) -> Node {
  match self._parse_optional_token(kind) {
    Some(token) => token
    None => {
      let actual_message = match message {
        Some(message) => message
        None => _diagnostic_message(1005)
      }
      let actual_argument = match argument {
        Some(argument) => argument
        None => _parser_token_spelling(kind)
      }
      self._create_missing_parser_node(
        kind,
        false,
        message=actual_message,
        arguments=_parser_text_arguments(actual_argument),
      )
    }
  }
}

///|
fn ParserState::_parse_expected_matching_brackets(
  self : ParserState,
  open_kind : SyntaxKind,
  close_kind : SyntaxKind,
  open_parsed : Bool,
  open_position : Int,
) -> Unit {
  if self.current_token == close_kind {
    ignore(self._next_token())
    return
  }
  let diagnostic = self._parse_error_at_current_token(
    _diagnostic_message(1005),
    arguments=_parser_text_arguments(_parser_token_spelling(close_kind)),
  )
  guard open_parsed && diagnostic is Some(diagnostic) else { return }
  let related = _create_detached_diagnostic(
    self.file_name,
    self.source_text,
    open_position,
    1,
    _diagnostic_message(1007),
    _parser_two_text_arguments(
      _parser_token_spelling(open_kind),
      _parser_token_spelling(close_kind),
    ),
  )
  let updated = _add_related_information(
    diagnostic,
    ReadOnlyArray::from_array([related]),
  )
  self.diagnostics[self.diagnostics.length() - 1] = updated
}

///|
fn ParserState::_can_parse_semicolon(self : ParserState) -> Bool {
  self.current_token.to_int() == 27 ||
  self.current_token.to_int() == 20 ||
  self.current_token.to_int() == 1 ||
  self.scanner._has_flag(TokenFlags::preceding_line_break())
}

///|
fn ParserState::_try_parse_semicolon(self : ParserState) -> Bool {
  if !self._can_parse_semicolon() {
    return false
  }
  if self.current_token.to_int() == 27 {
    ignore(self._next_token())
  }
  true
}

///|
fn ParserState::_parse_semicolon(self : ParserState) -> Bool {
  self._try_parse_semicolon() || self._parse_expected(_syntax_kind(27))
}

///|
fn ParserState::_create_identifier(
  self : ParserState,
  is_identifier : Bool,
  message? : DiagnosticMessage,
  private_identifier_message? : DiagnosticMessage,
) -> Node {
  if is_identifier {
    self.identifier_count += 1
    let pos = if self.scanner._has_flag(
        TokenFlags::preceding_jsdoc_leading_asterisks(),
      ) {
      self.scanner._token_start()
    } else {
      self._get_node_pos()
    }
    let original_kind = self.current_token
    let text = self._intern_identifier(self.scanner._required_token_value())
    let extended = self.scanner._has_flag(TokenFlags::extended_unicode_escape())
    ignore(self._next_token_without_check())
    return self._finish_parser_node(
      _factory_create_identifier(
        text,
        original_keyword_kind=original_kind,
        has_extended_unicode_escape=extended,
      ),
      pos,
    )
  }
  if self.current_token.to_int() == 81 {
    ignore(
      self._parse_error_at_current_token(
        match private_identifier_message {
          Some(message) => message
          None => _diagnostic_message(18016)
        },
      ),
    )
    return self._create_identifier(true)
  }
  if self.current_token.to_int() == 0 {
    let rescanned = self.scanner._try_scan(fn() {
      let kind = self.scanner._re_scan_invalid_identifier()
      if kind.to_int() == 80 {
        Some(kind)
      } else {
        None
      }
    })
    match rescanned {
      Some(kind) => {
        self.current_token = kind
        return self._create_identifier(true)
      }
      None => ()
    }
  }
  self.identifier_count += 1
  let default_message = if self.scanner._is_reserved_word() {
    _diagnostic_message(1359)
  } else {
    _diagnostic_message(1003)
  }
  let actual_message = match message {
    Some(message) => message
    None => default_message
  }
  let arguments = if actual_message.code() == 1359 {
    _parser_text_arguments(self.scanner._token_text())
  } else {
    _no_diagnostic_arguments()
  }
  self._create_missing_parser_node(
    _syntax_kind(80),
    self.current_token.to_int() == 1,
    message=actual_message,
    arguments~,
  )
}

///|
fn ParserState::_parse_binding_identifier(self : ParserState) -> Node {
  self._create_identifier(self._is_binding_identifier())
}

///|
fn ParserState::_parse_identifier(
  self : ParserState,
  message? : DiagnosticMessage,
) -> Node {
  match message {
    Some(message) => self._create_identifier(self._is_identifier(), message~)
    None => self._create_identifier(self._is_identifier())
  }
}

///|
fn ParserState::_parse_identifier_name(
  self : ParserState,
  message? : DiagnosticMessage,
) -> Node {
  match message {
    Some(message) =>
      self._create_identifier(
        _parser_token_is_identifier_or_keyword(self.current_token),
        message~,
      )
    None =>
      self._create_identifier(
        _parser_token_is_identifier_or_keyword(self.current_token),
      )
  }
}

///|
fn ParserState::_parse_identifier_name_no_unicode_escape(
  self : ParserState,
) -> Node {
  if self.scanner._has_flag(TokenFlags::unicode_escape()) ||
    self.scanner._has_flag(TokenFlags::extended_unicode_escape()) {
    ignore(self._parse_error_at_current_token(_diagnostic_message(17021)))
  }
  self._create_identifier(
    _parser_token_is_identifier_or_keyword(self.current_token),
  )
}

///|
fn ParserState::_parse_private_identifier(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let text = self._intern_identifier(self.scanner._required_token_value())
  let node = _factory_create_private_identifier(text)
  ignore(self._next_token())
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_is_literal_property_name(self : ParserState) -> Bool {
  _parser_token_is_identifier_or_keyword(self.current_token) ||
  self.current_token.to_int() == 9 ||
  self.current_token.to_int() == 10 ||
  self.current_token.to_int() == 11
}

///|
fn ParserState::_is_import_attribute_name(self : ParserState) -> Bool {
  _parser_token_is_identifier_or_keyword(self.current_token) ||
  self.current_token.to_int() == 11
}

///|
fn ParserState::_parse_literal_property_name(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let value = self._intern_identifier(self.scanner._required_token_value())
  let kind = self.current_token.to_int()
  let node = match kind {
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
    _ => abort("literal property name expected")
  }
  ignore(self._next_token())
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_property_name_without_computed(
  self : ParserState,
) -> Node {
  match self.current_token.to_int() {
    9 | 10 | 11 => self._parse_literal_property_name()
    81 => self._parse_private_identifier()
    _ => self._parse_identifier_name()
  }
}

///|
fn ParserState::_parse_property_name(
  self : ParserState,
  parse_expression : () -> Node,
) -> Node {
  if self.current_token.to_int() != 23 {
    return self._parse_property_name_without_computed()
  }
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(23)))
  let expression = self._do_outside_of_context(
    NodeFlags::disallow_in_context(),
    parse_expression,
  )
  ignore(self._parse_expected(_syntax_kind(24)))
  self._finish_parser_node(
    _factory_create_computed_property_name(expression),
    pos,
  )
}

///|
fn _parser_identifier_text(node : Node) -> String? {
  guard node.kind().to_int() == 80 else { return None }
  match node.field("escapedText") {
    Some(Text(Some(text))) =>
      if text.length() >= 3 && text[0] == 95 && text[1] == 95 && text[2] == 95 {
        Some(text.unsafe_substring(start=1, end=text.length()))
      } else {
        Some(text)
      }
    _ => None
  }
}

///|
fn _parser_is_identifier_text(text : String, target : ScriptTarget) -> Bool {
  let source = SourceText::new(text)
  if source.length() == 0 {
    return false
  }
  let first = source.code_point_at(0)
  if !_is_identifier_start(first, target) {
    return false
  }
  let mut position = utf16_char_size(first)
  while position < source.length() {
    let code_point = source.code_point_at(position)
    if !_is_identifier_part(code_point, target) {
      return false
    }
    position += utf16_char_size(code_point)
  }
  true
}

///|
fn _parser_keyword_suggestions() -> ReadOnlyArray[String] {
  let result : Array[String] = []
  for value = 83; value <= 166; value = value + 1 {
    match _token_to_string(_syntax_kind(value)) {
      Some(keyword) if keyword.length() > 2 => result.push(keyword)
      _ => ()
    }
  }
  ReadOnlyArray::from_array(result)
}

///|
fn _parser_space_suggestion(text : String) -> String? {
  for keyword in _parser_keyword_suggestions() {
    if text.length() > keyword.length() + 2 &&
      text.unsafe_substring(start=0, end=keyword.length()) == keyword {
      return Some(
        keyword +
        " " +
        text.unsafe_substring(start=keyword.length(), end=text.length()),
      )
    }
  }
  None
}

///|
fn ParserState::_parse_error_for_invalid_name(
  self : ParserState,
  name_diagnostic : DiagnosticMessage,
  blank_diagnostic : DiagnosticMessage,
  token_if_blank_name : SyntaxKind,
) -> Unit {
  if self.current_token == token_if_blank_name {
    ignore(self._parse_error_at_current_token(blank_diagnostic))
    return
  }
  let value = match self.scanner._token_value() {
    Some(value) => value
    None => self.scanner._token_text()
  }
  ignore(
    self._parse_error_at_current_token(
      name_diagnostic,
      arguments=_parser_text_arguments(value),
    ),
  )
}

///|
fn ParserState::_parse_error_for_missing_semicolon_after(
  self : ParserState,
  node : Node,
) -> Unit {
  if node.kind().to_int() == 216 {
    match node.field("template") {
      Some(NodeRef(Some(template))) => {
        ignore(
          self._parse_error_at(
            skip_trivia(SourceText::new(self.source_text), template.pos()),
            template.end(),
            _diagnostic_message(1443),
          ),
        )
        return
      }
      _ => ()
    }
  }
  guard _parser_identifier_text(node) is Some(text) &&
    _parser_is_identifier_text(text, self.language_version) else {
    ignore(
      self._parse_error_at_current_token(
        _diagnostic_message(1005),
        arguments=_parser_text_arguments(";"),
      ),
    )
    return
  }
  let pos = skip_trivia(SourceText::new(self.source_text), node.pos())
  match text {
    "const" | "let" | "var" => {
      ignore(self._parse_error_at(pos, node.end(), _diagnostic_message(1440)))
      return
    }
    "declare" => return
    "interface" => {
      self._parse_error_for_invalid_name(
        _diagnostic_message(2427),
        _diagnostic_message(1438),
        _syntax_kind(19),
      )
      return
    }
    "is" => {
      ignore(
        self._parse_error_at(
          pos,
          self.scanner._token_start(),
          _diagnostic_message(1228),
        ),
      )
      return
    }
    "module" | "namespace" => {
      self._parse_error_for_invalid_name(
        _diagnostic_message(2819),
        _diagnostic_message(1437),
        _syntax_kind(19),
      )
      return
    }
    "type" => {
      self._parse_error_for_invalid_name(
        _diagnostic_message(2457),
        _diagnostic_message(1439),
        _syntax_kind(64),
      )
      return
    }
    _ => ()
  }
  let suggestion = match
    _regexp_spelling_suggestion(text, _parser_keyword_suggestions()) {
    Some(suggestion) => Some(suggestion)
    None => _parser_space_suggestion(text)
  }
  match suggestion {
    Some(suggestion) => {
      ignore(
        self._parse_error_at(
          pos,
          node.end(),
          _diagnostic_message(1435),
          arguments=_parser_text_arguments(suggestion),
        ),
      )
      return
    }
    None => ()
  }
  if self.current_token.to_int() != 0 {
    ignore(self._parse_error_at(pos, node.end(), _diagnostic_message(1434)))
  }
}
