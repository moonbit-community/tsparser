// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn Scanner::_re_scan_greater_token(self : Scanner) -> SyntaxKind {
  if self.token.to_int() == 32 {
    if self._code_unit(self.pos) == CharacterCodes::greater_than() {
      if self._code_unit(self.pos + 1) == CharacterCodes::greater_than() {
        if self._code_unit(self.pos + 2) == CharacterCodes::equals() {
          self.pos += 3
          return self._finish_token(SyntaxKind(73))
        }
        self.pos += 2
        return self._finish_token(SyntaxKind(50))
      }
      if self._code_unit(self.pos + 1) == CharacterCodes::equals() {
        self.pos += 2
        return self._finish_token(SyntaxKind(72))
      }
      self.pos += 1
      return self._finish_token(SyntaxKind(49))
    }
    if self._code_unit(self.pos) == CharacterCodes::equals() {
      self.pos += 1
      return self._finish_token(SyntaxKind(34))
    }
  }
  self.token
}

///|
fn Scanner::_re_scan_asterisk_equals_token(self : Scanner) -> SyntaxKind {
  guard self.token.to_int() == 67 else {
    abort("asterisk-equals rescan requires '*='")
  }
  self.pos = self.token_start + 1
  self._finish_token(SyntaxKind(64))
}

///|
fn Scanner::_re_scan_less_than_token(self : Scanner) -> SyntaxKind {
  if self.token.to_int() == 48 {
    self.pos = self.token_start + 1
    self._finish_token(SyntaxKind(30))
  } else {
    self.token
  }
}

///|
fn Scanner::_re_scan_hash_token(self : Scanner) -> SyntaxKind {
  if self.token.to_int() == 81 {
    self.pos = self.token_start + 1
    self._finish_token(SyntaxKind(63))
  } else {
    self.token
  }
}

///|
fn Scanner::_re_scan_question_token(self : Scanner) -> SyntaxKind {
  guard self.token.to_int() == 61 else {
    abort("question rescan requires '??'")
  }
  self.pos = self.token_start + 1
  self._finish_token(SyntaxKind(58))
}

///|
fn Scanner::_re_scan_template_token(
  self : Scanner,
  tagged_template : Bool,
) -> SyntaxKind {
  self.pos = self.token_start
  self._finish_token(self._scan_template(!tagged_template))
}

///|
fn Scanner::_re_scan_template_head_or_no_substitution(
  self : Scanner,
) -> SyntaxKind {
  self.pos = self.token_start
  self._finish_token(self._scan_template(true))
}

///|
fn Scanner::_re_scan_invalid_identifier(self : Scanner) -> SyntaxKind {
  guard self.token.to_int() == 0 else {
    abort("invalid-identifier rescan requires an Unknown token")
  }
  self.pos = self.full_start_pos
  self.token_start = self.full_start_pos
  self.token_flags = TokenFlags::none()
  let code_point = self._code_point(self.pos)
  match self._scan_identifier(code_point, ScriptTarget::es_next()) {
    Some(kind) => self._finish_token(kind)
    None => {
      self.pos += utf16_char_size(code_point)
      self.token
    }
  }
}

///|
fn Scanner::_check_regexp_flag_target(
  self : Scanner,
  flag : RegularExpressionFlags,
  size : Int,
) -> Unit {
  match _regular_expression_flag_minimum_target(flag) {
    Some(minimum) if self.language_version.to_int() < minimum.to_int() =>
      self._error_at(
        _diagnostic_message(1501),
        self.pos,
        size,
        argument=DiagnosticArgument::text(minimum.runtime_name().to_lower()),
      )
    _ => ()
  }
}

///|
fn Scanner::_recover_unterminated_regexp(
  self : Scanner,
  body_start : Int,
  body_end : Int,
) -> Unit {
  self.pos = body_start
  let mut escaped = false
  let mut class_depth = 0
  let mut in_decimal_quantifier = false
  let mut group_depth = 0
  while self.pos < body_end {
    let code_unit = self._code_unit(self.pos)
    if escaped {
      escaped = false
    } else if code_unit == CharacterCodes::backslash() {
      escaped = true
    } else if code_unit == CharacterCodes::open_bracket() {
      class_depth += 1
    } else if code_unit == CharacterCodes::close_bracket() && class_depth > 0 {
      class_depth -= 1
    } else if class_depth == 0 {
      if code_unit == CharacterCodes::open_brace() {
        in_decimal_quantifier = true
      } else if code_unit == CharacterCodes::close_brace() &&
        in_decimal_quantifier {
        in_decimal_quantifier = false
      } else if !in_decimal_quantifier {
        if code_unit == CharacterCodes::open_paren() {
          group_depth += 1
        } else if code_unit == CharacterCodes::close_paren() && group_depth > 0 {
          group_depth -= 1
        } else if code_unit == CharacterCodes::close_paren() ||
          code_unit == CharacterCodes::close_bracket() ||
          code_unit == CharacterCodes::close_brace() {
          break
        }
      }
    }
    self.pos += 1
  }
  while self.pos > self.token_start &&
        (
          is_white_space_like(self._code_unit(self.pos - 1)) ||
          self._code_unit(self.pos - 1) == CharacterCodes::semicolon()
        ) {
    self.pos -= 1
  }
  self._error_at(
    _diagnostic_message(1161),
    self.token_start,
    self.pos - self.token_start,
  )
}

///|
fn Scanner::_re_scan_slash_token(
  self : Scanner,
  report_errors? : Bool = false,
) -> SyntaxKind {
  if self.token.to_int() != 44 && self.token.to_int() != 69 {
    return self.token
  }
  let body_start = self.token_start + 1
  self.pos = body_start
  let mut escaped = false
  let mut in_class = false
  let mut named_capture_groups = false
  while true {
    let code_unit = self._code_unit(self.pos)
    if code_unit == CharacterCodes::eof() || is_line_break(code_unit) {
      self.token_flags = self.token_flags.union(TokenFlags::unterminated())
      break
    }
    if escaped {
      escaped = false
    } else if code_unit == CharacterCodes::slash() && !in_class {
      break
    } else if code_unit == CharacterCodes::open_bracket() {
      in_class = true
    } else if code_unit == CharacterCodes::backslash() {
      escaped = true
    } else if code_unit == CharacterCodes::close_bracket() {
      in_class = false
    } else if !in_class &&
      code_unit == CharacterCodes::open_paren() &&
      self._code_unit(self.pos + 1) == CharacterCodes::question() &&
      self._code_unit(self.pos + 2) == CharacterCodes::less_than() &&
      self._code_unit(self.pos + 3) != CharacterCodes::equals() &&
      self._code_unit(self.pos + 3) != CharacterCodes::exclamation() {
      named_capture_groups = true
    }
    self.pos += 1
  }
  let body_end = self.pos
  if self.token_flags.contains(TokenFlags::unterminated()) {
    self._recover_unterminated_regexp(body_start, body_end)
  } else {
    self.pos += 1
    let mut flags = RegularExpressionFlags::none()
    while true {
      let code_point = self._code_point(self.pos)
      if code_point == CharacterCodes::eof() ||
        !_is_identifier_part(code_point, self.language_version) {
        break
      }
      let size = utf16_char_size(code_point)
      if report_errors {
        match _character_code_to_regular_expression_flag(code_point) {
          None => self._error_at(_diagnostic_message(1499), self.pos, size)
          Some(flag) if flags.contains(flag) =>
            self._error_at(_diagnostic_message(1500), self.pos, size)
          Some(flag) if flags
            .union(flag)
            .contains(RegularExpressionFlags::any_unicode_mode()) =>
            self._error_at(_diagnostic_message(1502), self.pos, size)
          Some(flag) => {
            flags = flags.union(flag)
            self._check_regexp_flag_target(flag, size)
          }
        }
      }
      self.pos += size
    }
    if report_errors {
      self._scan_range(body_start, body_end - body_start, fn() {
        _validate_regular_expression(self, flags, true, named_capture_groups)
      })
    }
  }
  self._set_token_value(self.source.substring(self.token_start, end=self.pos))
  self._finish_token(SyntaxKind(14))
}
