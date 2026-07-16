// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// One `@ts-expect-error` or `@ts-ignore` directive found in comment trivia.
pub struct CommentDirective {
  range : TextRange
  directive_type : CommentDirectiveType
} derive(Eq, Debug)

///|
pub fn CommentDirective::range(self : CommentDirective) -> TextRange {
  self.range
}

///|
pub fn CommentDirective::directive_type(
  self : CommentDirective,
) -> CommentDirectiveType {
  self.directive_type
}

///|
/// The six fields TypeScript saves for scanner lookahead and try-scan.
priv struct ScannerSnapshot {
  pos : Int
  full_start_pos : Int
  token_start : Int
  token : SyntaxKind
  token_value : String?
  token_flags : TokenFlags
}

///|
/// Mutable, invocation-local lexical state. The scanner stays package-private;
/// parser results never retain it or expose a mutable source handle.
priv struct Scanner {
  mut language_version : ScriptTarget
  skip_trivia : Bool
  mut language_variant : LanguageVariant
  mut source : SourceText
  mut pos : Int
  mut end : Int
  mut full_start_pos : Int
  mut token_start : Int
  mut token : SyntaxKind
  mut token_value : String?
  mut token_flags : TokenFlags
  mut comment_directives : Array[CommentDirective]?
  mut skip_jsdoc_leading_asterisks : Int
  mut script_kind : ScriptKind
  mut jsdoc_parsing_mode : JSDocParsingMode
  mut on_error : ((DiagnosticMessage, Int, Int, DiagnosticArgument?) -> Unit)?
}

///|
fn _create_scanner(
  language_version : ScriptTarget,
  skip_trivia : Bool,
  language_variant? : LanguageVariant = LanguageVariant::standard(),
  text? : String = "",
  on_error? : (DiagnosticMessage, Int, Int, DiagnosticArgument?) -> Unit,
  start? : Int = 0,
  length? : Int,
) -> Scanner {
  let source = SourceText::new(text)
  let range_end = match length {
    Some(length) => start + length
    None => source.length()
  }
  guard start >= 0 && range_end >= start && range_end <= source.length() else {
    abort("invalid scanner range")
  }
  {
    language_version,
    skip_trivia,
    language_variant,
    source,
    pos: start,
    end: range_end,
    full_start_pos: start,
    token_start: start,
    token: SyntaxKind(0),
    token_value: None,
    token_flags: TokenFlags::none(),
    comment_directives: None,
    skip_jsdoc_leading_asterisks: 0,
    script_kind: ScriptKind::unknown(),
    jsdoc_parsing_mode: JSDocParsingMode::parse_all(),
    on_error,
  }
}

///|
fn Scanner::_code_unit(self : Scanner, position : Int) -> Int {
  if position < 0 || position >= self.end {
    CharacterCodes::eof()
  } else {
    self.source.code_unit_at(position)
  }
}

///|
fn Scanner::_code_point(self : Scanner, position : Int) -> Int {
  if position < 0 || position >= self.end {
    CharacterCodes::eof()
  } else {
    let first = self.source.code_unit_at(position)
    if _is_high_surrogate(first) && position + 1 >= self.end {
      first
    } else {
      self.source.code_point_at(position)
    }
  }
}

///|
fn Scanner::_error_at(
  self : Scanner,
  message : DiagnosticMessage,
  position : Int,
  length : Int,
  argument? : DiagnosticArgument,
) -> Unit {
  match self.on_error {
    Some(callback) => callback(message, position, length, argument)
    None => ()
  }
}

///|
fn Scanner::_error(self : Scanner, message : DiagnosticMessage) -> Unit {
  self._error_at(message, self.pos, 0)
}

///|
fn Scanner::_snapshot(self : Scanner) -> ScannerSnapshot {
  {
    pos: self.pos,
    full_start_pos: self.full_start_pos,
    token_start: self.token_start,
    token: self.token,
    token_value: self.token_value,
    token_flags: self.token_flags,
  }
}

///|
fn Scanner::_restore(self : Scanner, snapshot : ScannerSnapshot) -> Unit {
  self.pos = snapshot.pos
  self.full_start_pos = snapshot.full_start_pos
  self.token_start = snapshot.token_start
  self.token = snapshot.token
  self.token_value = snapshot.token_value
  self.token_flags = snapshot.token_flags
}

///|
fn[T] Scanner::_look_ahead(self : Scanner, callback : () -> T) -> T {
  let snapshot = self._snapshot()
  let result = callback()
  self._restore(snapshot)
  result
}

///|
fn[T] Scanner::_try_scan(self : Scanner, callback : () -> T?) -> T? {
  let snapshot = self._snapshot()
  let result = callback()
  match result {
    Some(_) => ()
    None => self._restore(snapshot)
  }
  result
}

///|
fn[T] Scanner::_scan_range(
  self : Scanner,
  start : Int,
  length : Int,
  callback : () -> T,
) -> T {
  guard start >= 0 && length >= 0 && start + length <= self.source.length() else {
    abort("invalid scanner range")
  }
  let saved_end = self.end
  let snapshot = self._snapshot()
  let saved_directives = self.comment_directives
  self.end = start + length
  self._reset_token_state(start)
  let result = callback()
  self.end = saved_end
  self._restore(snapshot)
  self.comment_directives = saved_directives
  result
}

///|
fn Scanner::_reset_token_state(self : Scanner, position : Int) -> Unit {
  guard position >= 0 && position <= self.end else {
    abort("invalid scanner position")
  }
  self.pos = position
  self.full_start_pos = position
  self.token_start = position
  self.token = SyntaxKind(0)
  self.token_value = None
  self.token_flags = TokenFlags::none()
}

///|
fn Scanner::_set_text(
  self : Scanner,
  text : String,
  start? : Int = 0,
  length? : Int,
) -> Unit {
  let source = SourceText::new(text)
  let range_end = match length {
    Some(length) => start + length
    None => source.length()
  }
  guard start >= 0 && range_end >= start && range_end <= source.length() else {
    abort("invalid scanner range")
  }
  self.source = source
  self.end = range_end
  self._reset_token_state(start)
}

///|
fn Scanner::_set_on_error(
  self : Scanner,
  callback : ((DiagnosticMessage, Int, Int, DiagnosticArgument?) -> Unit)?,
) -> Unit {
  self.on_error = callback
}

///|
fn Scanner::_set_script_target(self : Scanner, target : ScriptTarget) -> Unit {
  self.language_version = target
}

///|
fn Scanner::_set_language_variant(
  self : Scanner,
  variant : LanguageVariant,
) -> Unit {
  self.language_variant = variant
}

///|
fn Scanner::_set_script_kind(self : Scanner, kind : ScriptKind) -> Unit {
  self.script_kind = kind
}

///|
fn Scanner::_set_jsdoc_parsing_mode(
  self : Scanner,
  mode : JSDocParsingMode,
) -> Unit {
  self.jsdoc_parsing_mode = mode
}

///|
fn Scanner::_set_skip_jsdoc_leading_asterisks(
  self : Scanner,
  skip : Bool,
) -> Unit {
  self.skip_jsdoc_leading_asterisks += if skip { 1 } else { -1 }
  guard self.skip_jsdoc_leading_asterisks >= 0 else {
    abort("unbalanced JSDoc leading-asterisk scanner mode")
  }
}

///|
fn Scanner::_token_full_start(self : Scanner) -> Int {
  self.full_start_pos
}

///|
fn Scanner::_token_start(self : Scanner) -> Int {
  self.token_start
}

///|
fn Scanner::_token_end(self : Scanner) -> Int {
  self.pos
}

///|
fn Scanner::_token(self : Scanner) -> SyntaxKind {
  self.token
}

///|
fn Scanner::_token_text(self : Scanner) -> String {
  self.source.substring(self.token_start, end=self.pos)
}

///|
fn Scanner::_token_value(self : Scanner) -> String? {
  self.token_value
}

///|
fn Scanner::_required_token_value(self : Scanner) -> String {
  match self.token_value {
    Some(value) => value
    None => abort("current scanner token has no value")
  }
}

///|
fn Scanner::_set_token_value(self : Scanner, value : String) -> Unit {
  self.token_value = Some(value)
}

///|
fn Scanner::_token_flags(self : Scanner) -> TokenFlags {
  self.token_flags
}

///|
fn Scanner::_numeric_literal_flags(self : Scanner) -> TokenFlags {
  self.token_flags.intersect(TokenFlags::numeric_literal_flags())
}

///|
fn Scanner::_comment_directives(
  self : Scanner,
) -> ReadOnlyArray[CommentDirective]? {
  match self.comment_directives {
    Some(directives) => Some(ReadOnlyArray::from_array(directives.copy()))
    None => None
  }
}

///|
fn Scanner::_clear_comment_directives(self : Scanner) -> Unit {
  self.comment_directives = None
}

///|
fn Scanner::_text(self : Scanner) -> String {
  self.source.original()
}

///|
fn Scanner::_has_flag(self : Scanner, flag : TokenFlags) -> Bool {
  self.token_flags.contains(flag)
}

///|
fn Scanner::_is_identifier(self : Scanner) -> Bool {
  self.token.to_int() == 80 || self.token.to_int() > 118
}

///|
fn Scanner::_is_reserved_word(self : Scanner) -> Bool {
  self.token.to_int() >= 83 && self.token.to_int() <= 118
}

///|
fn _is_digit(code_unit : Int) -> Bool {
  code_unit >= CharacterCodes::digit_0() &&
  code_unit <= CharacterCodes::digit_9()
}

///|
fn _is_octal_digit(code_unit : Int) -> Bool {
  code_unit >= CharacterCodes::digit_0() &&
  code_unit <= CharacterCodes::digit_7()
}

///|
fn _is_hex_digit(code_unit : Int) -> Bool {
  _is_digit(code_unit) ||
  (
    code_unit >= CharacterCodes::upper_a() &&
    code_unit <= CharacterCodes::upper_f()
  ) ||
  (
    code_unit >= CharacterCodes::lower_a() &&
    code_unit <= CharacterCodes::lower_f()
  )
}

///|
fn _hex_value(code_unit : Int) -> Int {
  if _is_digit(code_unit) {
    code_unit - CharacterCodes::digit_0()
  } else if code_unit >= CharacterCodes::lower_a() &&
    code_unit <= CharacterCodes::lower_f() {
    code_unit - CharacterCodes::lower_a() + 10
  } else if code_unit >= CharacterCodes::upper_a() &&
    code_unit <= CharacterCodes::upper_f() {
    code_unit - CharacterCodes::upper_a() + 10
  } else {
    -1
  }
}

///|
fn Scanner::_finish_token(self : Scanner, kind : SyntaxKind) -> SyntaxKind {
  self.token = kind
  kind
}

///|
fn Scanner::_should_parse_jsdoc(self : Scanner) -> Bool {
  match self.jsdoc_parsing_mode.to_int() {
    0 => return true
    1 => return false
    _ => ()
  }
  if self.script_kind != ScriptKind::ts() &&
    self.script_kind != ScriptKind::tsx() {
    return true
  }
  if self.jsdoc_parsing_mode == JSDocParsingMode::parse_for_type_info() {
    return false
  }
  let comment = self.source
    .substring(self.full_start_pos, end=self.pos)
    .to_lower()
  comment.contains("@see") || comment.contains("@link")
}

///|
fn Scanner::_append_comment_directive(
  self : Scanner,
  line_start : Int,
  single_line : Bool,
) -> Unit {
  let mut cursor = line_start
  while cursor < self.pos && is_white_space_like(self._code_unit(cursor)) {
    cursor += 1
  }
  if single_line {
    if self._code_unit(cursor) != CharacterCodes::slash() ||
      self._code_unit(cursor + 1) != CharacterCodes::slash() {
      return
    }
    cursor += 2
    if self._code_unit(cursor) == CharacterCodes::slash() {
      cursor += 1
    }
  } else {
    while self._code_unit(cursor) == CharacterCodes::slash() ||
          self._code_unit(cursor) == CharacterCodes::asterisk() {
      cursor += 1
    }
  }
  while cursor < self.pos && is_white_space_like(self._code_unit(cursor)) {
    cursor += 1
  }
  if self._code_unit(cursor) != CharacterCodes::at() {
    return
  }
  cursor += 1
  let expect_error = "ts-expect-error"
  let ignore_directive = "ts-ignore"
  let directive_type = if cursor + expect_error.length() <= self.pos &&
    self.source.substring(cursor, end=cursor + expect_error.length()) ==
    expect_error {
    Some(CommentDirectiveType::ExpectError)
  } else if cursor + ignore_directive.length() <= self.pos &&
    self.source.substring(cursor, end=cursor + ignore_directive.length()) ==
    ignore_directive {
    Some(CommentDirectiveType::Ignore)
  } else {
    None
  }
  match directive_type {
    Some(directive_type) => {
      let directive = CommentDirective::{
        range: TextRange::new(line_start, end=self.pos),
        directive_type,
      }
      match self.comment_directives {
        Some(directives) => directives.push(directive)
        None => self.comment_directives = Some([directive])
      }
    }
    None => ()
  }
}

///|
fn Scanner::_scan_conflict_marker(self : Scanner) -> Unit {
  self._error_at(_diagnostic_message(1185), self.pos, 7)
  self.pos = _scan_conflict_marker_trivia(self.source, self.pos)
}

///|
fn Scanner::_scan(self : Scanner) -> SyntaxKind {
  self.full_start_pos = self.pos
  self.token_flags = TokenFlags::none()
  while true {
    self.token_start = self.pos
    if self.pos >= self.end {
      return self._finish_token(SyntaxKind(1))
    }
    let code_point = self._code_point(self.pos)
    if self.pos == 0 &&
      code_point == CharacterCodes::hash() &&
      _is_shebang_trivia(self.source, self.pos) {
      self.pos = _scan_shebang_trivia(self.source, self.pos)
      if self.skip_trivia {
        continue
      }
      return self._finish_token(SyntaxKind(6))
    }
    match code_point {
      0x0a | 0x0d => {
        self.token_flags = self.token_flags.union(
          TokenFlags::preceding_line_break(),
        )
        if self.skip_trivia {
          self.pos += 1
          continue
        }
        if code_point == CharacterCodes::carriage_return() &&
          self._code_unit(self.pos + 1) == CharacterCodes::line_feed() {
          self.pos += 2
        } else {
          self.pos += 1
        }
        return self._finish_token(SyntaxKind(4))
      }
      0x09
      | 0x0b
      | 0x0c
      | 0x20
      | 0x00a0
      | 0x1680
      | 0x2000
      | 0x2001
      | 0x2002
      | 0x2003
      | 0x2004
      | 0x2005
      | 0x2006
      | 0x2007
      | 0x2008
      | 0x2009
      | 0x200a
      | 0x200b
      | 0x202f
      | 0x205f
      | 0x3000
      | 0xfeff => {
        if self.skip_trivia {
          self.pos += 1
          continue
        }
        while self.pos < self.end &&
              is_white_space_single_line(self._code_unit(self.pos)) {
          self.pos += 1
        }
        return self._finish_token(SyntaxKind(5))
      }
      0x21 => {
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          if self._code_unit(self.pos + 2) == CharacterCodes::equals() {
            self.pos += 3
            return self._finish_token(SyntaxKind(38))
          }
          self.pos += 2
          return self._finish_token(SyntaxKind(36))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(54))
      }
      0x22 | 0x27 => {
        self._set_token_value(self._scan_string())
        return self._finish_token(SyntaxKind(11))
      }
      0x60 => return self._finish_token(self._scan_template(false))
      0x25 => {
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(70))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(45))
      }
      0x26 => {
        if self._code_unit(self.pos + 1) == CharacterCodes::ampersand() {
          if self._code_unit(self.pos + 2) == CharacterCodes::equals() {
            self.pos += 3
            return self._finish_token(SyntaxKind(77))
          }
          self.pos += 2
          return self._finish_token(SyntaxKind(56))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(74))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(51))
      }
      0x28 => {
        self.pos += 1
        return self._finish_token(SyntaxKind(21))
      }
      0x29 => {
        self.pos += 1
        return self._finish_token(SyntaxKind(22))
      }
      0x2a => {
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(67))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::asterisk() {
          if self._code_unit(self.pos + 2) == CharacterCodes::equals() {
            self.pos += 3
            return self._finish_token(SyntaxKind(68))
          }
          self.pos += 2
          return self._finish_token(SyntaxKind(43))
        }
        self.pos += 1
        if self.skip_jsdoc_leading_asterisks > 0 &&
          !self.token_flags.contains(
            TokenFlags::preceding_jsdoc_leading_asterisks(),
          ) &&
          self.token_flags.contains(TokenFlags::preceding_line_break()) {
          self.token_flags = self.token_flags.union(
            TokenFlags::preceding_jsdoc_leading_asterisks(),
          )
          continue
        }
        return self._finish_token(SyntaxKind(42))
      }
      0x2b => {
        if self._code_unit(self.pos + 1) == CharacterCodes::plus() {
          self.pos += 2
          return self._finish_token(SyntaxKind(46))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(65))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(40))
      }
      0x2c => {
        self.pos += 1
        return self._finish_token(SyntaxKind(28))
      }
      0x2d => {
        if self._code_unit(self.pos + 1) == CharacterCodes::minus() {
          self.pos += 2
          return self._finish_token(SyntaxKind(47))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(66))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(41))
      }
      0x2e => {
        if _is_digit(self._code_unit(self.pos + 1)) {
          ignore(self._scan_number())
          return self._finish_token(SyntaxKind(9))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::dot() &&
          self._code_unit(self.pos + 2) == CharacterCodes::dot() {
          self.pos += 3
          return self._finish_token(SyntaxKind(26))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(25))
      }
      0x2f => {
        if self._code_unit(self.pos + 1) == CharacterCodes::slash() {
          self.pos += 2
          while self.pos < self.end && !is_line_break(self._code_unit(self.pos)) {
            self.pos += 1
          }
          self._append_comment_directive(self.token_start, true)
          if self.skip_trivia {
            continue
          }
          return self._finish_token(SyntaxKind(2))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::asterisk() {
          self.pos += 2
          let is_jsdoc = self._code_unit(self.pos) == CharacterCodes::asterisk() &&
            self._code_unit(self.pos + 1) != CharacterCodes::slash()
          let mut closed = false
          let mut last_line_start = self.token_start
          while self.pos < self.end {
            let current = self._code_unit(self.pos)
            if current == CharacterCodes::asterisk() &&
              self._code_unit(self.pos + 1) == CharacterCodes::slash() {
              self.pos += 2
              closed = true
              break
            }
            self.pos += 1
            if is_line_break(current) {
              last_line_start = self.pos
              self.token_flags = self.token_flags.union(
                TokenFlags::preceding_line_break(),
              )
            }
          }
          if is_jsdoc && self._should_parse_jsdoc() {
            self.token_flags = self.token_flags.union(
              TokenFlags::preceding_jsdoc_comment(),
            )
          }
          self._append_comment_directive(last_line_start, false)
          if !closed {
            self._error(_diagnostic_message(1010))
          }
          if self.skip_trivia {
            continue
          }
          if !closed {
            self.token_flags = self.token_flags.union(
              TokenFlags::unterminated(),
            )
          }
          return self._finish_token(SyntaxKind(3))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(69))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(44))
      }
      0x30 => {
        if self.pos + 2 < self.end &&
          (
            self._code_unit(self.pos + 1) == CharacterCodes::upper_x() ||
            self._code_unit(self.pos + 1) == CharacterCodes::lower_x()
          ) {
          self.pos += 2
          let digits = self._scan_minimum_hex_digits(1, true)
          self._set_token_value(if digits == "" { "0" } else { digits })
          if digits == "" {
            self._error(_diagnostic_message(1125))
          }
          self._set_token_value("0x" + self._required_token_value())
          self.token_flags = self.token_flags.union(TokenFlags::hex_specifier())
          return self._finish_token(self._check_big_int_suffix())
        }
        if self.pos + 2 < self.end &&
          (
            self._code_unit(self.pos + 1) == CharacterCodes::upper_b() ||
            self._code_unit(self.pos + 1) == CharacterCodes::lower_b()
          ) {
          self.pos += 2
          let digits = self._scan_binary_or_octal_digits(2)
          self._set_token_value(if digits == "" { "0" } else { digits })
          if digits == "" {
            self._error(_diagnostic_message(1177))
          }
          self._set_token_value("0b" + self._required_token_value())
          self.token_flags = self.token_flags.union(
            TokenFlags::binary_specifier(),
          )
          return self._finish_token(self._check_big_int_suffix())
        }
        if self.pos + 2 < self.end &&
          (
            self._code_unit(self.pos + 1) == CharacterCodes::upper_o() ||
            self._code_unit(self.pos + 1) == CharacterCodes::lower_o()
          ) {
          self.pos += 2
          let digits = self._scan_binary_or_octal_digits(8)
          self._set_token_value(if digits == "" { "0" } else { digits })
          if digits == "" {
            self._error(_diagnostic_message(1178))
          }
          self._set_token_value("0o" + self._required_token_value())
          self.token_flags = self.token_flags.union(
            TokenFlags::octal_specifier(),
          )
          return self._finish_token(self._check_big_int_suffix())
        }
        return self._finish_token(self._scan_number())
      }
      0x31 | 0x32 | 0x33 | 0x34 | 0x35 | 0x36 | 0x37 | 0x38 | 0x39 =>
        return self._finish_token(self._scan_number())
      0x3a => {
        self.pos += 1
        return self._finish_token(SyntaxKind(59))
      }
      0x3b => {
        self.pos += 1
        return self._finish_token(SyntaxKind(27))
      }
      0x3c => {
        if _is_conflict_marker_trivia(self.source, self.pos) {
          self._scan_conflict_marker()
          if self.skip_trivia {
            continue
          }
          return self._finish_token(SyntaxKind(7))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::less_than() {
          if self._code_unit(self.pos + 2) == CharacterCodes::equals() {
            self.pos += 3
            return self._finish_token(SyntaxKind(71))
          }
          self.pos += 2
          return self._finish_token(SyntaxKind(48))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(33))
        }
        if self.language_variant == LanguageVariant::jsx() &&
          self._code_unit(self.pos + 1) == CharacterCodes::slash() &&
          self._code_unit(self.pos + 2) != CharacterCodes::asterisk() {
          self.pos += 2
          return self._finish_token(SyntaxKind(31))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(30))
      }
      0x3d => {
        if _is_conflict_marker_trivia(self.source, self.pos) {
          self._scan_conflict_marker()
          if self.skip_trivia {
            continue
          }
          return self._finish_token(SyntaxKind(7))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          if self._code_unit(self.pos + 2) == CharacterCodes::equals() {
            self.pos += 3
            return self._finish_token(SyntaxKind(37))
          }
          self.pos += 2
          return self._finish_token(SyntaxKind(35))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::greater_than() {
          self.pos += 2
          return self._finish_token(SyntaxKind(39))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(64))
      }
      0x3e => {
        if _is_conflict_marker_trivia(self.source, self.pos) {
          self._scan_conflict_marker()
          if self.skip_trivia {
            continue
          }
          return self._finish_token(SyntaxKind(7))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(32))
      }
      0x3f => {
        if self._code_unit(self.pos + 1) == CharacterCodes::dot() &&
          !_is_digit(self._code_unit(self.pos + 2)) {
          self.pos += 2
          return self._finish_token(SyntaxKind(29))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::question() {
          if self._code_unit(self.pos + 2) == CharacterCodes::equals() {
            self.pos += 3
            return self._finish_token(SyntaxKind(78))
          }
          self.pos += 2
          return self._finish_token(SyntaxKind(61))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(58))
      }
      0x5b => {
        self.pos += 1
        return self._finish_token(SyntaxKind(23))
      }
      0x5d => {
        self.pos += 1
        return self._finish_token(SyntaxKind(24))
      }
      0x5e => {
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(79))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(53))
      }
      0x7b => {
        self.pos += 1
        return self._finish_token(SyntaxKind(19))
      }
      0x7c => {
        if _is_conflict_marker_trivia(self.source, self.pos) {
          self._scan_conflict_marker()
          if self.skip_trivia {
            continue
          }
          return self._finish_token(SyntaxKind(7))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::bar() {
          if self._code_unit(self.pos + 2) == CharacterCodes::equals() {
            self.pos += 3
            return self._finish_token(SyntaxKind(76))
          }
          self.pos += 2
          return self._finish_token(SyntaxKind(57))
        }
        if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
          self.pos += 2
          return self._finish_token(SyntaxKind(75))
        }
        self.pos += 1
        return self._finish_token(SyntaxKind(52))
      }
      0x7d => {
        self.pos += 1
        return self._finish_token(SyntaxKind(20))
      }
      0x7e => {
        self.pos += 1
        return self._finish_token(SyntaxKind(55))
      }
      0x40 => {
        self.pos += 1
        return self._finish_token(SyntaxKind(60))
      }
      0x5c => {
        let extended = self._peek_extended_unicode_escape()
        if extended >= 0 &&
          _is_identifier_start(extended, self.language_version) {
          self._set_token_value(
            self._scan_extended_unicode_escape(true) +
            self._scan_identifier_parts(),
          )
          return self._finish_token(self._identifier_token())
        }
        let cooked = self._peek_unicode_escape()
        if cooked >= 0 && _is_identifier_start(cooked, self.language_version) {
          self.pos += 6
          self.token_flags = self.token_flags.union(
            TokenFlags::unicode_escape(),
          )
          self._set_token_value(
            utf16_encode_as_string(cooked) + self._scan_identifier_parts(),
          )
          return self._finish_token(self._identifier_token())
        }
        self._error(_diagnostic_message(1127))
        self.pos += 1
        return self._finish_token(SyntaxKind(0))
      }
      0x23 => {
        if self.pos != 0 &&
          self._code_unit(self.pos + 1) == CharacterCodes::exclamation() {
          self._error_at(_diagnostic_message(18026), self.pos, 2)
          self.pos += 1
          return self._finish_token(SyntaxKind(0))
        }
        let after_hash = self._code_point(self.pos + 1)
        if after_hash == CharacterCodes::backslash() {
          self.pos += 1
          let extended = self._peek_extended_unicode_escape()
          if extended >= 0 &&
            _is_identifier_start(extended, self.language_version) {
            self._set_token_value(
              "#" +
              self._scan_extended_unicode_escape(true) +
              self._scan_identifier_parts(),
            )
            return self._finish_token(SyntaxKind(81))
          }
          let cooked = self._peek_unicode_escape()
          if cooked >= 0 && _is_identifier_start(cooked, self.language_version) {
            self.pos += 6
            self.token_flags = self.token_flags.union(
              TokenFlags::unicode_escape(),
            )
            self._set_token_value(
              "#" +
              utf16_encode_as_string(cooked) +
              self._scan_identifier_parts(),
            )
            return self._finish_token(SyntaxKind(81))
          }
          self.pos -= 1
        }
        if _is_identifier_start(after_hash, self.language_version) {
          self.pos += 1
          ignore(self._scan_identifier(after_hash, self.language_version))
        } else {
          self._set_token_value("#")
          self._error_at(
            _diagnostic_message(1127),
            self.pos,
            utf16_char_size(code_point),
          )
          self.pos += utf16_char_size(code_point)
        }
        return self._finish_token(SyntaxKind(81))
      }
      0xfffd => {
        self._error_at(_diagnostic_message(1490), 0, 0)
        self.pos = self.end
        return self._finish_token(SyntaxKind(8))
      }
      _ =>
        match self._scan_identifier(code_point, self.language_version) {
          Some(kind) => return self._finish_token(kind)
          None => {
            if is_white_space_single_line(code_point) {
              self.pos += utf16_char_size(code_point)
              continue
            }
            if is_line_break(code_point) {
              self.token_flags = self.token_flags.union(
                TokenFlags::preceding_line_break(),
              )
              self.pos += utf16_char_size(code_point)
              continue
            }
            let size = utf16_char_size(code_point)
            self._error_at(_diagnostic_message(1127), self.pos, size)
            self.pos += size
            return self._finish_token(SyntaxKind(0))
          }
        }
    }
  }
  abort("unreachable scanner loop")
}
