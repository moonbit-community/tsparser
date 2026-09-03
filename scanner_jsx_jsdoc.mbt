// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn Scanner::_scan_jsx_token(
  self : Scanner,
  allow_multiline_text? : Bool = true,
) -> SyntaxKind {
  self.full_start_pos = self.pos
  self.token_start = self.pos
  if self.pos >= self.end {
    return self._finish_token(SyntaxKind(1))
  }
  let first = self._code_unit(self.pos)
  if first == CharacterCodes::less_than() {
    if self._code_unit(self.pos + 1) == CharacterCodes::slash() {
      self.pos += 2
      return self._finish_token(SyntaxKind(31))
    }
    self.pos += 1
    return self._finish_token(SyntaxKind(30))
  }
  if first == CharacterCodes::open_brace() {
    self.pos += 1
    return self._finish_token(SyntaxKind(19))
  }
  let mut first_non_whitespace = 0
  while self.pos < self.end {
    let code_unit = self._code_unit(self.pos)
    if code_unit == CharacterCodes::open_brace() {
      break
    }
    if code_unit == CharacterCodes::less_than() {
      if _is_conflict_marker_trivia(self.source, self.pos) {
        self._scan_conflict_marker()
        return self._finish_token(SyntaxKind(7))
      }
      break
    }
    if code_unit == CharacterCodes::greater_than() {
      self._error_at(_diagnostic_message(1382), self.pos, 1)
    }
    if code_unit == CharacterCodes::close_brace() {
      self._error_at(_diagnostic_message(1381), self.pos, 1)
    }
    if is_line_break(code_unit) && first_non_whitespace == 0 {
      first_non_whitespace = -1
    } else if !allow_multiline_text &&
      is_line_break(code_unit) &&
      first_non_whitespace > 0 {
      break
    } else if !is_white_space_like(code_unit) {
      first_non_whitespace = self.pos
    }
    self.pos += 1
  }
  self._set_token_value(
    self.source.substring(self.full_start_pos, end=self.pos),
  )
  self._finish_token(
    if first_non_whitespace == -1 {
      SyntaxKind(13)
    } else {
      SyntaxKind(12)
    },
  )
}

///|
fn Scanner::_re_scan_jsx_token(
  self : Scanner,
  allow_multiline_text? : Bool = true,
) -> SyntaxKind {
  self.pos = self.full_start_pos
  self.token_start = self.full_start_pos
  self._scan_jsx_token(allow_multiline_text~)
}

///|
fn Scanner::_scan_jsx_identifier(self : Scanner) -> SyntaxKind {
  if self.token.to_int() >= 80 {
    while self.pos < self.end {
      if self._code_unit(self.pos) == CharacterCodes::minus() {
        self._set_token_value(self._required_token_value() + "-")
        self.pos += 1
        continue
      }
      let old_pos = self.pos
      let suffix = self._scan_identifier_parts()
      self._set_token_value(self._required_token_value() + suffix)
      if self.pos == old_pos {
        break
      }
    }
    self._finish_token(self._identifier_token())
  } else {
    self.token
  }
}

///|
fn Scanner::_scan_jsx_attribute_value(self : Scanner) -> SyntaxKind {
  self.full_start_pos = self.pos
  if self._code_unit(self.pos) == CharacterCodes::double_quote() ||
    self._code_unit(self.pos) == CharacterCodes::single_quote() {
    self._set_token_value(self._scan_string(jsx_attribute_string=true))
    self._finish_token(SyntaxKind(11))
  } else {
    self._scan()
  }
}

///|
fn Scanner::_re_scan_jsx_attribute_value(self : Scanner) -> SyntaxKind {
  self.pos = self.full_start_pos
  self.token_start = self.full_start_pos
  self._scan_jsx_attribute_value()
}

///|
fn Scanner::_scan_jsdoc_comment_text_token(
  self : Scanner,
  in_backticks : Bool,
) -> SyntaxKind {
  self.full_start_pos = self.pos
  self.token_start = self.pos
  self.token_flags = TokenFlags::none()
  if self.pos >= self.end {
    return self._finish_token(SyntaxKind(1))
  }
  while self.pos < self.end {
    let code_point = self._code_point(self.pos)
    if is_line_break(code_point) || code_point == CharacterCodes::backtick() {
      break
    }
    if !in_backticks {
      if code_point == CharacterCodes::open_brace() {
        break
      }
      if code_point == CharacterCodes::at() &&
        self.pos > 0 &&
        is_white_space_single_line(self._code_unit(self.pos - 1)) &&
        !(self.pos + 1 < self.end &&
        is_white_space_like(self._code_unit(self.pos + 1))) {
        break
      }
    }
    self.pos += utf16_char_size(code_point)
  }
  if self.pos == self.token_start {
    return self._scan_jsdoc_token()
  }
  self._set_token_value(self.source.substring(self.token_start, end=self.pos))
  self._finish_token(SyntaxKind(82))
}

///|
fn Scanner::_scan_jsdoc_token(self : Scanner) -> SyntaxKind {
  self.full_start_pos = self.pos
  self.token_start = self.pos
  self.token_flags = TokenFlags::none()
  if self.pos >= self.end {
    return self._finish_token(SyntaxKind(1))
  }
  let code_point = self._code_point(self.pos)
  self.pos += utf16_char_size(code_point)
  match code_point {
    0x09 | 0x0b | 0x0c | 0x20 => {
      while self.pos < self.end &&
            is_white_space_single_line(self._code_unit(self.pos)) {
        self.pos += 1
      }
      self._finish_token(SyntaxKind(5))
    }
    0x40 => self._finish_token(SyntaxKind(60))
    0x0d => {
      if self._code_unit(self.pos) == CharacterCodes::line_feed() {
        self.pos += 1
      }
      self.token_flags = self.token_flags.union(
        TokenFlags::preceding_line_break(),
      )
      self._finish_token(SyntaxKind(4))
    }
    0x0a => {
      self.token_flags = self.token_flags.union(
        TokenFlags::preceding_line_break(),
      )
      self._finish_token(SyntaxKind(4))
    }
    0x2a => self._finish_token(SyntaxKind(42))
    0x7b => self._finish_token(SyntaxKind(19))
    0x7d => self._finish_token(SyntaxKind(20))
    0x5b => self._finish_token(SyntaxKind(23))
    0x5d => self._finish_token(SyntaxKind(24))
    0x28 => self._finish_token(SyntaxKind(21))
    0x29 => self._finish_token(SyntaxKind(22))
    0x3c => self._finish_token(SyntaxKind(30))
    0x3e => self._finish_token(SyntaxKind(32))
    0x3d => self._finish_token(SyntaxKind(64))
    0x2c => self._finish_token(SyntaxKind(28))
    0x2e => self._finish_token(SyntaxKind(25))
    0x60 => self._finish_token(SyntaxKind(62))
    0x23 => self._finish_token(SyntaxKind(63))
    0x5c => {
      self.pos -= 1
      let extended = self._peek_extended_unicode_escape()
      if extended >= 0 && _is_identifier_start(extended, self.language_version) {
        self._set_token_value(
          self._scan_extended_unicode_escape(true) +
          self._scan_identifier_parts(),
        )
        return self._finish_token(self._identifier_token())
      }
      let cooked = self._peek_unicode_escape()
      if cooked >= 0 && _is_identifier_start(cooked, self.language_version) {
        self.pos += 6
        self.token_flags = self.token_flags.union(TokenFlags::unicode_escape())
        self._set_token_value(
          utf16_encode_as_string(cooked) + self._scan_identifier_parts(),
        )
        return self._finish_token(self._identifier_token())
      }
      self.pos += 1
      self._finish_token(SyntaxKind(0))
    }
    _ => {
      if !_is_identifier_start(code_point, self.language_version) {
        return self._finish_token(SyntaxKind(0))
      }
      let mut next = self._code_point(self.pos)
      while self.pos < self.end &&
            (
              _is_identifier_part(next, self.language_version) ||
              next == CharacterCodes::minus()
            ) {
        self.pos += utf16_char_size(next)
        next = self._code_point(self.pos)
      }
      self._set_token_value(
        self.source.substring(self.token_start, end=self.pos),
      )
      if next == CharacterCodes::backslash() {
        self._set_token_value(
          self._required_token_value() + self._scan_identifier_parts(),
        )
      }
      self._finish_token(self._identifier_token())
    }
  }
}
