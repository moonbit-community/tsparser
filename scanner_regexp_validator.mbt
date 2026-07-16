// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
priv struct RegexpNamedRange {
  pos : Int
  end : Int
  name : String
}

///|
priv struct RegexpDecimalEscape {
  pos : Int
  end : Int
  value : Double
}

///|
priv struct RegexpValidator {
  scanner : Scanner
  unicode_sets_mode : Bool
  any_unicode_mode : Bool
  strict_mode : Bool
  annex_b : Bool
  named_capture_groups : Bool
  mut may_contain_strings : Bool
  mut number_of_capturing_groups : Int
  group_specifiers : Array[String]
  group_name_references : Array[RegexpNamedRange]
  decimal_escapes : Array[RegexpDecimalEscape]
  scope_stack : Array[Array[String]?]
  mut top_scope : Array[String]?
}

///|
fn _regexp_array_contains(values : Array[String], value : String) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

///|
fn _regexp_readonly_array_contains(
  values : ReadOnlyArray[String],
  value : String,
) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

///|
fn _regexp_option_array_contains(
  values : Array[String]?,
  value : String,
) -> Bool {
  match values {
    Some(values) => _regexp_array_contains(values, value)
    None => false
  }
}

///|
fn _regexp_first_code_point(text : String) -> Int {
  if text == "" {
    CharacterCodes::eof()
  } else {
    SourceText::new(text).code_point_at(0)
  }
}

///|
fn _is_ascii_letter(code_unit : Int) -> Bool {
  (
    code_unit >= CharacterCodes::upper_a() &&
    code_unit <= CharacterCodes::upper_z()
  ) ||
  (
    code_unit >= CharacterCodes::lower_a() &&
    code_unit <= CharacterCodes::lower_z()
  )
}

///|
fn _is_word_character(code_unit : Int) -> Bool {
  _is_ascii_letter(code_unit) ||
  _is_digit(code_unit) ||
  code_unit == CharacterCodes::underscore()
}

///|
fn RegexpValidator::_error(
  self : RegexpValidator,
  code : Int,
  pos : Int,
  length : Int,
) -> Unit {
  self.scanner._error_at(_diagnostic_message(code), pos, length)
}

///|
fn RegexpValidator::_error_text(
  self : RegexpValidator,
  code : Int,
  pos : Int,
  length : Int,
  value : String,
) -> Unit {
  self.scanner._error_at(
    _diagnostic_message(code),
    pos,
    length,
    argument=DiagnosticArgument::text(value),
  )
}

///|
fn RegexpValidator::_error_number(
  self : RegexpValidator,
  code : Int,
  pos : Int,
  length : Int,
  value : Int,
) -> Unit {
  self.scanner._error_at(
    _diagnostic_message(code),
    pos,
    length,
    argument=DiagnosticArgument::number(value),
  )
}

///|
fn RegexpValidator::_scan_expected_char(
  self : RegexpValidator,
  expected : Int,
) -> Unit {
  if self.scanner._code_unit(self.scanner.pos) == expected {
    self.scanner.pos += 1
  } else {
    self._error_text(
      1005,
      self.scanner.pos,
      0,
      utf16_encode_as_string(expected),
    )
  }
}

///|
fn RegexpValidator::_scan_source_character(self : RegexpValidator) -> String {
  let size = if self.any_unicode_mode {
    utf16_char_size(self.scanner._code_point(self.scanner.pos))
  } else {
    1
  }
  self.scanner.pos += size
  if size > 0 {
    self.scanner.source.substring(self.scanner.pos - size, end=self.scanner.pos)
  } else {
    ""
  }
}

///|
fn RegexpValidator::_scan_word_characters(self : RegexpValidator) -> String {
  let output = StringBuilder::new()
  while true {
    let code_unit = self.scanner._code_unit(self.scanner.pos)
    if code_unit == CharacterCodes::eof() || !_is_word_character(code_unit) {
      break
    }
    output.write_char(code_unit.unsafe_to_char())
    self.scanner.pos += 1
  }
  output.to_string()
}

///|
fn RegexpValidator::_scan_pattern_modifiers(
  self : RegexpValidator,
  initial : RegularExpressionFlags,
) -> RegularExpressionFlags {
  let mut flags = initial
  while true {
    let code_point = self.scanner._code_point(self.scanner.pos)
    if code_point == CharacterCodes::eof() ||
      !_is_identifier_part(code_point, self.scanner.language_version) {
      break
    }
    let size = utf16_char_size(code_point)
    match _character_code_to_regular_expression_flag(code_point) {
      None => self._error(1499, self.scanner.pos, size)
      Some(flag) if flags.contains(flag) =>
        self._error(1500, self.scanner.pos, size)
      Some(flag) if !RegularExpressionFlags::modifiers().contains(flag) =>
        self._error(1509, self.scanner.pos, size)
      Some(flag) => {
        flags = flags.union(flag)
        self.scanner._check_regexp_flag_target(flag, size)
      }
    }
    self.scanner.pos += size
  }
  flags
}

///|
fn RegexpValidator::_scan_regexp_escape_sequence(
  self : RegexpValidator,
  atom_escape : Bool,
) -> String {
  let scanner = self.scanner
  let start = scanner.pos
  scanner.pos += 1
  if scanner.pos >= scanner.end {
    scanner._error(_diagnostic_message(1126))
    return ""
  }
  let code_unit = scanner._code_unit(scanner.pos)
  scanner.pos += 1
  match code_unit {
    0x30 | 0x31 | 0x32 | 0x33 | 0x34 | 0x35 | 0x36 | 0x37 => {
      if code_unit == CharacterCodes::digit_0() &&
        !_is_digit(scanner._code_unit(scanner.pos)) {
        return utf16_encode_as_string(0)
      }
      if code_unit <= CharacterCodes::digit_3() &&
        _is_octal_digit(scanner._code_unit(scanner.pos)) {
        scanner.pos += 1
      }
      if _is_octal_digit(scanner._code_unit(scanner.pos)) {
        scanner.pos += 1
      }
      scanner.token_flags = scanner.token_flags.union(
        TokenFlags::contains_invalid_escape(),
      )
      let octal_text = scanner.source.substring(start + 1, end=scanner.pos)
      let value = _scanner_parse_radix_double(octal_text, 8).to_int()
      let hex = value.to_string(radix=16)
      let replacement = "\\x" + (if hex.length() == 1 { "0" } else { "" }) + hex
      if !atom_escape && code_unit != CharacterCodes::digit_0() {
        self._error_text(1536, start, scanner.pos - start, replacement)
      } else {
        self._error_text(1487, start, scanner.pos - start, replacement)
      }
      utf16_encode_as_string(value)
    }
    0x38 | 0x39 => {
      scanner.token_flags = scanner.token_flags.union(
        TokenFlags::contains_invalid_escape(),
      )
      if !atom_escape {
        self._error(1537, start, scanner.pos - start)
      } else {
        self._error_text(
          1488,
          start,
          scanner.pos - start,
          scanner.source.substring(start, end=scanner.pos),
        )
      }
      utf16_encode_as_string(code_unit)
    }
    0x62 => "\b"
    0x74 => "\t"
    0x6e => "\n"
    0x76 => "\u000b"
    0x66 => "\u000c"
    0x72 => "\r"
    0x27 => "'"
    0x22 => "\""
    0x75 => {
      if scanner._code_unit(scanner.pos) == CharacterCodes::open_brace() {
        scanner.pos = start
        let result = scanner._scan_extended_unicode_escape(true)
        if !self.any_unicode_mode {
          scanner.token_flags = scanner.token_flags.union(
            TokenFlags::contains_invalid_escape(),
          )
          self._error(1538, start, scanner.pos - start)
        }
        return result
      }
      let mut value = 0
      let required_end = start + 6
      while scanner.pos < required_end {
        let digit = _hex_value(scanner._code_unit(scanner.pos))
        if digit < 0 {
          scanner.token_flags = scanner.token_flags.union(
            TokenFlags::contains_invalid_escape(),
          )
          scanner._error(_diagnostic_message(1125))
          return scanner.source.substring(start, end=scanner.pos)
        }
        value = value * 16 + digit
        scanner.pos += 1
      }
      scanner.token_flags = scanner.token_flags.union(
        TokenFlags::unicode_escape(),
      )
      let first = utf16_encode_as_string(value)
      if self.any_unicode_mode &&
        _is_high_surrogate(value) &&
        scanner.pos + 6 < scanner.end &&
        scanner._code_unit(scanner.pos) == CharacterCodes::backslash() &&
        scanner._code_unit(scanner.pos + 1) == CharacterCodes::lower_u() &&
        scanner._code_unit(scanner.pos + 2) != CharacterCodes::open_brace() {
        let next_start = scanner.pos
        let mut next_pos = scanner.pos + 2
        let mut next_value = 0
        let mut valid = true
        while next_pos < next_start + 6 {
          let digit = _hex_value(scanner._code_unit(next_pos))
          if digit < 0 {
            valid = false
            break
          }
          next_value = next_value * 16 + digit
          next_pos += 1
        }
        if valid && _is_low_surrogate(next_value) {
          scanner.pos = next_pos
          return first + utf16_encode_as_string(next_value)
        }
      }
      first
    }
    0x78 => {
      let mut value = 0
      let required_end = start + 4
      while scanner.pos < required_end {
        let digit = _hex_value(scanner._code_unit(scanner.pos))
        if digit < 0 {
          scanner.token_flags = scanner.token_flags.union(
            TokenFlags::contains_invalid_escape(),
          )
          scanner._error(_diagnostic_message(1125))
          return scanner.source.substring(start, end=scanner.pos)
        }
        value = value * 16 + digit
        scanner.pos += 1
      }
      scanner.token_flags = scanner.token_flags.union(TokenFlags::hex_escape())
      utf16_encode_as_string(value)
    }
    0x0d => {
      if scanner._code_unit(scanner.pos) == CharacterCodes::line_feed() {
        scanner.pos += 1
      }
      ""
    }
    0x0a | 0x2028 | 0x2029 => ""
    _ => {
      if self.any_unicode_mode ||
        (
          !self.annex_b &&
          _is_identifier_part(code_unit, scanner.language_version)
        ) {
        self._error(1535, scanner.pos - 2, 2)
      }
      utf16_encode_as_string(code_unit)
    }
  }
}

///|
fn RegexpValidator::_scan_character_escape(
  self : RegexpValidator,
  atom_escape : Bool,
) -> String {
  let scanner = self.scanner
  let mut code_unit = scanner._code_unit(scanner.pos)
  match code_unit {
    -1 => {
      self._error(1513, scanner.pos - 1, 1)
      "\\"
    }
    0x63 => {
      scanner.pos += 1
      code_unit = scanner._code_unit(scanner.pos)
      if _is_ascii_letter(code_unit) {
        scanner.pos += 1
        utf16_encode_as_string(code_unit & 0x1f)
      } else if self.strict_mode {
        self._error(1512, scanner.pos - 2, 2)
        utf16_encode_as_string(code_unit)
      } else if atom_escape {
        scanner.pos -= 1
        "\\"
      } else {
        utf16_encode_as_string(code_unit)
      }
    }
    0x5e
    | 0x24
    | 0x2f
    | 0x5c
    | 0x2e
    | 0x2a
    | 0x2b
    | 0x3f
    | 0x28
    | 0x29
    | 0x5b
    | 0x5d
    | 0x7b
    | 0x7d
    | 0x7c => {
      scanner.pos += 1
      utf16_encode_as_string(code_unit)
    }
    _ => {
      scanner.pos -= 1
      self._scan_regexp_escape_sequence(atom_escape)
    }
  }
}

///|
fn RegexpValidator::_scan_decimal_escape(self : RegexpValidator) -> Bool {
  let scanner = self.scanner
  let code_unit = scanner._code_unit(scanner.pos)
  if code_unit < CharacterCodes::digit_1() ||
    code_unit > CharacterCodes::digit_9() {
    return false
  }
  let start = scanner.pos
  ignore(scanner._scan_decimal_digits())
  let value = _scanner_parse_double(scanner._required_token_value())
  self.decimal_escapes.push({ pos: start, end: scanner.pos, value })
  true
}

///|
fn RegexpValidator::_scan_group_name(
  self : RegexpValidator,
  is_reference : Bool,
) -> Unit {
  let scanner = self.scanner
  scanner.token_start = scanner.pos
  ignore(
    scanner._scan_identifier(
      scanner._code_point(scanner.pos),
      scanner.language_version,
    ),
  )
  if scanner.pos == scanner.token_start {
    self._error(1514, scanner.pos, 0)
    return
  }
  let name = scanner._required_token_value()
  if is_reference {
    self.group_name_references.push({
      pos: scanner.token_start,
      end: scanner.pos,
      name,
    })
    return
  }
  let mut duplicate = _regexp_option_array_contains(self.top_scope, name)
  if !duplicate {
    for scope in self.scope_stack {
      if _regexp_option_array_contains(scope, name) {
        duplicate = true
        break
      }
    }
  }
  if duplicate {
    self._error(1515, scanner.token_start, scanner.pos - scanner.token_start)
    return
  }
  match self.top_scope {
    Some(scope) => scope.push(name)
    None => self.top_scope = Some([name])
  }
  if !_regexp_array_contains(self.group_specifiers, name) {
    self.group_specifiers.push(name)
  }
}

///|
fn RegexpValidator::_scan_atom_escape(self : RegexpValidator) -> Unit {
  let scanner = self.scanner
  match scanner._code_unit(scanner.pos) {
    0x6b => {
      scanner.pos += 1
      if scanner._code_unit(scanner.pos) == CharacterCodes::less_than() {
        scanner.pos += 1
        self._scan_group_name(true)
        self._scan_expected_char(CharacterCodes::greater_than())
      } else if self.strict_mode || self.named_capture_groups {
        self._error(1510, scanner.pos - 2, 2)
      }
    }
    0x71 if self.unicode_sets_mode => {
      scanner.pos += 1
      self._error(1511, scanner.pos - 2, 2)
    }
    _ =>
      if !self._scan_character_class_escape() && !self._scan_decimal_escape() {
        ignore(self._scan_character_escape(true))
      }
  }
}

///|
fn RegexpValidator::_class_content_exit(
  self : RegexpValidator,
  ch : Int,
) -> Bool {
  ch == CharacterCodes::close_bracket() ||
  ch == CharacterCodes::eof() ||
  self.scanner.pos >= self.scanner.end
}

///|
fn RegexpValidator::_scan_class_atom(self : RegexpValidator) -> String {
  let scanner = self.scanner
  if scanner._code_unit(scanner.pos) == CharacterCodes::backslash() {
    scanner.pos += 1
    let code_unit = scanner._code_unit(scanner.pos)
    match code_unit {
      0x62 => {
        scanner.pos += 1
        "\b"
      }
      0x2d => {
        scanner.pos += 1
        "-"
      }
      _ =>
        if self._scan_character_class_escape() {
          ""
        } else {
          self._scan_character_escape(false)
        }
    }
  } else {
    self._scan_source_character()
  }
}

///|
fn RegexpValidator::_scan_class_ranges(self : RegexpValidator) -> Unit {
  let scanner = self.scanner
  if scanner._code_unit(scanner.pos) == CharacterCodes::caret() {
    scanner.pos += 1
  }
  while true {
    let code_unit = scanner._code_unit(scanner.pos)
    if self._class_content_exit(code_unit) {
      return
    }
    let minimum_start = scanner.pos
    let minimum = self._scan_class_atom()
    if scanner._code_unit(scanner.pos) == CharacterCodes::minus() {
      scanner.pos += 1
      if self._class_content_exit(scanner._code_unit(scanner.pos)) {
        return
      }
      if minimum == "" && self.strict_mode {
        self._error(1516, minimum_start, scanner.pos - 1 - minimum_start)
      }
      let maximum_start = scanner.pos
      let maximum = self._scan_class_atom()
      if maximum == "" && self.strict_mode {
        self._error(1516, maximum_start, scanner.pos - maximum_start)
        continue
      }
      if minimum == "" {
        continue
      }
      let minimum_value = _regexp_first_code_point(minimum)
      let maximum_value = _regexp_first_code_point(maximum)
      if maximum != "" &&
        minimum.length() == utf16_char_size(minimum_value) &&
        maximum.length() == utf16_char_size(maximum_value) &&
        minimum_value > maximum_value {
        self._error(1517, minimum_start, scanner.pos - minimum_start)
      }
    }
  }
  abort("unreachable character class scanner")
}

///|
fn RegexpValidator::_scan_class_set_expression(self : RegexpValidator) -> Unit {
  let scanner = self.scanner
  let mut is_character_complement = false
  if scanner._code_unit(scanner.pos) == CharacterCodes::caret() {
    scanner.pos += 1
    is_character_complement = true
  }
  let mut expression_may_contain_strings = false
  let mut ch = scanner._code_unit(scanner.pos)
  let initial_ch = ch
  if self._class_content_exit(ch) {
    return
  }
  let mut start = scanner.pos
  let mut operand = ""
  let first_pair = scanner.source.substring(
    scanner.pos,
    end=(scanner.pos + 2).min(scanner.end),
  )
  if first_pair == "--" || first_pair == "&&" {
    self._error(1520, scanner.pos, 0)
    self.may_contain_strings = false
  } else {
    operand = self._scan_class_set_operand()
  }
  ch = scanner._code_unit(scanner.pos)
  if ch == CharacterCodes::minus() &&
    scanner._code_unit(scanner.pos + 1) == CharacterCodes::minus() {
    if is_character_complement && self.may_contain_strings {
      self._error(1518, start, scanner.pos - start)
    }
    expression_may_contain_strings = self.may_contain_strings
    self._scan_class_set_sub_expression(true)
    self.may_contain_strings = !is_character_complement &&
      expression_may_contain_strings
    return
  }
  if ch == CharacterCodes::ampersand() {
    if scanner._code_unit(scanner.pos + 1) == CharacterCodes::ampersand() {
      self._scan_class_set_sub_expression(false)
      if is_character_complement && self.may_contain_strings {
        self._error(1518, start, scanner.pos - start)
      }
      expression_may_contain_strings = self.may_contain_strings
      self.may_contain_strings = !is_character_complement &&
        expression_may_contain_strings
      return
    }
    self._error_text(1508, scanner.pos, 1, utf16_encode_as_string(initial_ch))
  } else {
    if is_character_complement && self.may_contain_strings {
      self._error(1518, start, scanner.pos - start)
    }
    expression_may_contain_strings = self.may_contain_strings
  }
  while true {
    ch = scanner._code_unit(scanner.pos)
    if ch == CharacterCodes::eof() {
      break
    }
    if ch == CharacterCodes::minus() {
      scanner.pos += 1
      ch = scanner._code_unit(scanner.pos)
      if self._class_content_exit(ch) {
        self.may_contain_strings = !is_character_complement &&
          expression_may_contain_strings
        return
      }
      if ch == CharacterCodes::minus() {
        scanner.pos += 1
        self._error(1519, scanner.pos - 2, 2)
        start = scanner.pos - 2
        operand = scanner.source.substring(start, end=scanner.pos)
        continue
      }
      if operand == "" {
        self._error(1516, start, scanner.pos - 1 - start)
      }
      let second_start = scanner.pos
      let second_operand = self._scan_class_set_operand()
      if is_character_complement && self.may_contain_strings {
        self._error(1518, second_start, scanner.pos - second_start)
      }
      expression_may_contain_strings = expression_may_contain_strings ||
        self.may_contain_strings
      if second_operand == "" {
        self._error(1516, second_start, scanner.pos - second_start)
      } else if operand != "" {
        let minimum = _regexp_first_code_point(operand)
        let maximum = _regexp_first_code_point(second_operand)
        if operand.length() == utf16_char_size(minimum) &&
          second_operand.length() == utf16_char_size(maximum) &&
          minimum > maximum {
          self._error(1517, start, scanner.pos - start)
        }
      }
    } else if ch == CharacterCodes::ampersand() {
      start = scanner.pos
      scanner.pos += 1
      if scanner._code_unit(scanner.pos) == CharacterCodes::ampersand() {
        scanner.pos += 1
        self._error(1519, scanner.pos - 2, 2)
        if scanner._code_unit(scanner.pos) == CharacterCodes::ampersand() {
          self._error_text(1508, scanner.pos, 1, "&")
          scanner.pos += 1
        }
      } else {
        self._error_text(1508, scanner.pos - 1, 1, "&")
      }
      operand = scanner.source.substring(start, end=scanner.pos)
      continue
    }
    if self._class_content_exit(scanner._code_unit(scanner.pos)) {
      break
    }
    start = scanner.pos
    let pair = scanner.source.substring(
      scanner.pos,
      end=(scanner.pos + 2).min(scanner.end),
    )
    if pair == "--" || pair == "&&" {
      self._error(1519, scanner.pos, 2)
      scanner.pos += 2
      operand = scanner.source.substring(start, end=scanner.pos)
    } else {
      operand = self._scan_class_set_operand()
    }
  }
  self.may_contain_strings = !is_character_complement &&
    expression_may_contain_strings
}

///|
fn RegexpValidator::_scan_class_set_sub_expression(
  self : RegexpValidator,
  is_subtraction : Bool,
) -> Unit {
  let scanner = self.scanner
  let mut expression_may_contain_strings = self.may_contain_strings
  while true {
    let mut ch = scanner._code_unit(scanner.pos)
    if self._class_content_exit(ch) {
      break
    }
    if ch == CharacterCodes::minus() {
      scanner.pos += 1
      if scanner._code_unit(scanner.pos) == CharacterCodes::minus() {
        scanner.pos += 1
        if !is_subtraction {
          self._error(1519, scanner.pos - 2, 2)
        }
      } else {
        self._error(1519, scanner.pos - 1, 1)
      }
    } else if ch == CharacterCodes::ampersand() {
      scanner.pos += 1
      if scanner._code_unit(scanner.pos) == CharacterCodes::ampersand() {
        scanner.pos += 1
        if is_subtraction {
          self._error(1519, scanner.pos - 2, 2)
        }
        if scanner._code_unit(scanner.pos) == CharacterCodes::ampersand() {
          self._error_text(1508, scanner.pos, 1, "&")
          scanner.pos += 1
        }
      } else {
        self._error_text(1508, scanner.pos - 1, 1, "&")
      }
    } else {
      self._error_text(
        1005,
        scanner.pos,
        0,
        if is_subtraction {
          "--"
        } else {
          "&&"
        },
      )
    }
    ch = scanner._code_unit(scanner.pos)
    if self._class_content_exit(ch) {
      self._error(1520, scanner.pos, 0)
      break
    }
    ignore(self._scan_class_set_operand())
    expression_may_contain_strings = expression_may_contain_strings &&
      self.may_contain_strings
  }
  self.may_contain_strings = expression_may_contain_strings
}

///|
fn RegexpValidator::_scan_class_set_operand(self : RegexpValidator) -> String {
  let scanner = self.scanner
  self.may_contain_strings = false
  match scanner._code_unit(scanner.pos) {
    -1 => ""
    0x5b => {
      scanner.pos += 1
      self._scan_class_set_expression()
      self._scan_expected_char(CharacterCodes::close_bracket())
      ""
    }
    0x5c => {
      scanner.pos += 1
      if self._scan_character_class_escape() {
        ""
      } else if scanner._code_unit(scanner.pos) == 0x71 {
        scanner.pos += 1
        if scanner._code_unit(scanner.pos) == CharacterCodes::open_brace() {
          scanner.pos += 1
          self._scan_class_string_disjunction_contents()
          self._scan_expected_char(CharacterCodes::close_brace())
          ""
        } else {
          self._error(1521, scanner.pos - 2, 2)
          "q"
        }
      } else {
        scanner.pos -= 1
        self._scan_class_set_character()
      }
    }
    _ => self._scan_class_set_character()
  }
}

///|
fn RegexpValidator::_scan_class_string_disjunction_contents(
  self : RegexpValidator,
) -> Unit {
  let scanner = self.scanner
  let mut character_count = 0
  while true {
    match scanner._code_unit(scanner.pos) {
      -1 => return
      0x7d => {
        if character_count != 1 {
          self.may_contain_strings = true
        }
        return
      }
      0x7c => {
        if character_count != 1 {
          self.may_contain_strings = true
        }
        scanner.pos += 1
        character_count = 0
      }
      _ => {
        ignore(self._scan_class_set_character())
        character_count += 1
      }
    }
  }
}

///|
fn RegexpValidator::_scan_class_set_character(self : RegexpValidator) -> String {
  let scanner = self.scanner
  let ch = scanner._code_unit(scanner.pos)
  if ch == CharacterCodes::eof() {
    return ""
  }
  if ch == CharacterCodes::backslash() {
    scanner.pos += 1
    let escaped = scanner._code_unit(scanner.pos)
    if escaped == 0x62 {
      scanner.pos += 1
      return "\b"
    }
    if escaped == 0x26 ||
      escaped == 0x2d ||
      escaped == 0x21 ||
      escaped == 0x23 ||
      escaped == 0x25 ||
      escaped == 0x2c ||
      escaped == 0x3a ||
      escaped == 0x3b ||
      escaped == 0x3c ||
      escaped == 0x3d ||
      escaped == 0x3e ||
      escaped == 0x40 ||
      escaped == 0x60 ||
      escaped == 0x7e {
      scanner.pos += 1
      return utf16_encode_as_string(escaped)
    }
    return self._scan_character_escape(false)
  }
  if ch == scanner._code_unit(scanner.pos + 1) &&
    (
      ch == 0x26 ||
      ch == 0x21 ||
      ch == 0x23 ||
      ch == 0x25 ||
      ch == 0x2a ||
      ch == 0x2b ||
      ch == 0x2c ||
      ch == 0x2e ||
      ch == 0x3a ||
      ch == 0x3b ||
      ch == 0x3c ||
      ch == 0x3d ||
      ch == 0x3e ||
      ch == 0x3f ||
      ch == 0x40 ||
      ch == 0x60 ||
      ch == 0x7e
    ) {
    self._error(1522, scanner.pos, 2)
    scanner.pos += 2
    return scanner.source.substring(scanner.pos - 2, end=scanner.pos)
  }
  if ch == CharacterCodes::slash() ||
    ch == CharacterCodes::open_paren() ||
    ch == CharacterCodes::close_paren() ||
    ch == CharacterCodes::open_bracket() ||
    ch == CharacterCodes::close_bracket() ||
    ch == CharacterCodes::open_brace() ||
    ch == CharacterCodes::close_brace() ||
    ch == CharacterCodes::minus() ||
    ch == CharacterCodes::bar() {
    self._error_text(1508, scanner.pos, 1, utf16_encode_as_string(ch))
    scanner.pos += 1
    return utf16_encode_as_string(ch)
  }
  self._scan_source_character()
}

///|
fn RegexpValidator::_report_spelling_suggestion(
  self : RegexpValidator,
  value : String,
  candidates : ReadOnlyArray[String],
  pos : Int,
  length : Int,
) -> Unit {
  match _regexp_spelling_suggestion(value, candidates) {
    Some(suggestion) => self._error_text(1369, pos, length, suggestion)
    None => ()
  }
}

///|
fn RegexpValidator::_scan_character_class_escape(
  self : RegexpValidator,
) -> Bool {
  let scanner = self.scanner
  let start = scanner.pos - 1
  let ch = scanner._code_unit(scanner.pos)
  if ch == 0x64 ||
    ch == 0x44 ||
    ch == 0x73 ||
    ch == 0x53 ||
    ch == 0x77 ||
    ch == 0x57 {
    scanner.pos += 1
    return true
  }
  if ch != 0x70 && ch != 0x50 {
    return false
  }
  let is_character_complement = ch == 0x50
  scanner.pos += 1
  if scanner._code_unit(scanner.pos) == CharacterCodes::open_brace() {
    scanner.pos += 1
    let name_or_value_start = scanner.pos
    let name_or_value = self._scan_word_characters()
    if scanner._code_unit(scanner.pos) == CharacterCodes::equals() {
      let property_kind = _regexp_non_binary_property_kind(name_or_value)
      if scanner.pos == name_or_value_start {
        self._error(1523, scanner.pos, 0)
      } else if property_kind is None {
        self._error(
          1524,
          name_or_value_start,
          scanner.pos - name_or_value_start,
        )
        self._report_spelling_suggestion(
          name_or_value,
          _regexp_non_binary_property_names,
          name_or_value_start,
          scanner.pos - name_or_value_start,
        )
      }
      scanner.pos += 1
      let property_value_start = scanner.pos
      let property_value = self._scan_word_characters()
      if scanner.pos == property_value_start {
        self._error(1525, scanner.pos, 0)
      } else {
        match property_kind {
          Some(kind) => {
            let values = _regexp_non_binary_property_values(kind)
            if !_regexp_readonly_array_contains(values, property_value) {
              self._error(
                1526,
                property_value_start,
                scanner.pos - property_value_start,
              )
              self._report_spelling_suggestion(
                property_value,
                values,
                property_value_start,
                scanner.pos - property_value_start,
              )
            }
          }
          None => ()
        }
      }
    } else if scanner.pos == name_or_value_start {
      self._error(1527, scanner.pos, 0)
    } else if _regexp_readonly_array_contains(
        _regexp_binary_string_properties, name_or_value,
      ) {
      if !self.unicode_sets_mode {
        self._error(
          1528,
          name_or_value_start,
          scanner.pos - name_or_value_start,
        )
      } else if is_character_complement {
        self._error(
          1518,
          name_or_value_start,
          scanner.pos - name_or_value_start,
        )
      } else {
        self.may_contain_strings = true
      }
    } else if !_regexp_readonly_array_contains(
        _regexp_general_category_values, name_or_value,
      ) &&
      !_regexp_readonly_array_contains(_regexp_binary_properties, name_or_value) {
      self._error(1529, name_or_value_start, scanner.pos - name_or_value_start)
      self._report_spelling_suggestion(
        name_or_value,
        _regexp_lone_property_candidates(),
        name_or_value_start,
        scanner.pos - name_or_value_start,
      )
    }
    self._scan_expected_char(CharacterCodes::close_brace())
    if !self.any_unicode_mode {
      self._error(1530, start, scanner.pos - start)
    }
  } else if self.strict_mode {
    self._error_text(1531, scanner.pos - 2, 2, utf16_encode_as_string(ch))
  } else {
    scanner.pos -= 1
    return false
  }
  true
}

///|
fn RegexpValidator::_scan_disjunction(
  self : RegexpValidator,
  is_in_group : Bool,
) -> Unit {
  while true {
    self.scope_stack.push(self.top_scope)
    self.top_scope = None
    self._scan_alternative(is_in_group)
    match self.scope_stack.pop() {
      Some(scope) => self.top_scope = scope
      None => abort("unbalanced regexp named-capture scope")
    }
    if self.scanner._code_unit(self.scanner.pos) != CharacterCodes::bar() {
      return
    }
    self.scanner.pos += 1
  }
}

///|
fn RegexpValidator::_scan_alternative(
  self : RegexpValidator,
  is_in_group : Bool,
) -> Unit {
  let scanner = self.scanner
  let mut previous_quantifiable = false
  while true {
    let start = scanner.pos
    let ch = scanner._code_unit(scanner.pos)
    match ch {
      -1 => return
      0x5e | 0x24 => {
        scanner.pos += 1
        previous_quantifiable = false
      }
      0x5c => {
        scanner.pos += 1
        let escaped = scanner._code_unit(scanner.pos)
        if escaped == 0x62 || escaped == 0x42 {
          scanner.pos += 1
          previous_quantifiable = false
        } else {
          self._scan_atom_escape()
          previous_quantifiable = true
        }
      }
      0x28 => {
        scanner.pos += 1
        if scanner._code_unit(scanner.pos) == CharacterCodes::question() {
          scanner.pos += 1
          let group_kind = scanner._code_unit(scanner.pos)
          if group_kind == CharacterCodes::equals() || group_kind == 0x21 {
            scanner.pos += 1
            previous_quantifiable = !self.strict_mode
          } else if group_kind == CharacterCodes::less_than() {
            let group_name_start = scanner.pos
            scanner.pos += 1
            let lookaround = scanner._code_unit(scanner.pos)
            if lookaround == CharacterCodes::equals() || lookaround == 0x21 {
              scanner.pos += 1
              previous_quantifiable = false
            } else {
              self._scan_group_name(false)
              self._scan_expected_char(CharacterCodes::greater_than())
              if scanner.language_version.to_int() <
                ScriptTarget::es2018().to_int() {
                self._error(
                  1503,
                  group_name_start,
                  scanner.pos - group_name_start,
                )
              }
              self.number_of_capturing_groups += 1
              previous_quantifiable = true
            }
          } else {
            let modifiers_start = scanner.pos
            let set_flags = self._scan_pattern_modifiers(
              RegularExpressionFlags::none(),
            )
            if scanner._code_unit(scanner.pos) == CharacterCodes::minus() {
              scanner.pos += 1
              ignore(self._scan_pattern_modifiers(set_flags))
              if scanner.pos == modifiers_start + 1 {
                self._error(
                  1504,
                  modifiers_start,
                  scanner.pos - modifiers_start,
                )
              }
            }
            self._scan_expected_char(CharacterCodes::colon())
            previous_quantifiable = true
          }
        } else {
          self.number_of_capturing_groups += 1
          previous_quantifiable = true
        }
        self._scan_disjunction(true)
        self._scan_expected_char(CharacterCodes::close_paren())
      }
      0x7b => {
        scanner.pos += 1
        let digits_start = scanner.pos
        ignore(scanner._scan_decimal_digits())
        let minimum = scanner._required_token_value()
        if !self.strict_mode && minimum == "" {
          previous_quantifiable = true
          continue
        }
        if scanner._code_unit(scanner.pos) == CharacterCodes::comma() {
          scanner.pos += 1
          ignore(scanner._scan_decimal_digits())
          let maximum = scanner._required_token_value()
          if minimum == "" {
            if maximum != "" ||
              scanner._code_unit(scanner.pos) == CharacterCodes::close_brace() {
              self._error(1505, digits_start, 0)
            } else {
              self._error_text(1508, start, 1, "{")
              previous_quantifiable = true
              continue
            }
          } else if maximum != "" &&
            _scanner_parse_double(minimum) > _scanner_parse_double(maximum) &&
            (
              self.strict_mode ||
              scanner._code_unit(scanner.pos) == CharacterCodes::close_brace()
            ) {
            self._error(1506, digits_start, scanner.pos - digits_start)
          }
        } else if minimum == "" {
          if self.strict_mode {
            self._error_text(1508, start, 1, "{")
          }
          previous_quantifiable = true
          continue
        }
        if scanner._code_unit(scanner.pos) != CharacterCodes::close_brace() {
          if self.strict_mode {
            self._error_text(1005, scanner.pos, 0, "}")
            scanner.pos -= 1
          } else {
            previous_quantifiable = true
            continue
          }
        }
        scanner.pos += 1
        if scanner._code_unit(scanner.pos) == CharacterCodes::question() {
          scanner.pos += 1
        }
        if !previous_quantifiable {
          self._error(1507, start, scanner.pos - start)
        }
        previous_quantifiable = false
      }
      0x2a | 0x2b | 0x3f => {
        scanner.pos += 1
        if scanner._code_unit(scanner.pos) == CharacterCodes::question() {
          scanner.pos += 1
        }
        if !previous_quantifiable {
          self._error(1507, start, scanner.pos - start)
        }
        previous_quantifiable = false
      }
      0x2e => {
        scanner.pos += 1
        previous_quantifiable = true
      }
      0x5b => {
        scanner.pos += 1
        if self.unicode_sets_mode {
          self._scan_class_set_expression()
        } else {
          self._scan_class_ranges()
        }
        self._scan_expected_char(CharacterCodes::close_bracket())
        previous_quantifiable = true
      }
      0x29 => {
        if is_in_group {
          return
        }
        self._error_text(1508, scanner.pos, 1, ")")
        scanner.pos += 1
        previous_quantifiable = true
      }
      0x5d | 0x7d => {
        if self.strict_mode {
          self._error_text(1508, scanner.pos, 1, utf16_encode_as_string(ch))
        }
        scanner.pos += 1
        previous_quantifiable = true
      }
      0x2f | 0x7c => return
      _ => {
        ignore(self._scan_source_character())
        previous_quantifiable = true
      }
    }
  }
}

///|
fn _validate_regular_expression(
  scanner : Scanner,
  flags : RegularExpressionFlags,
  annex_b : Bool,
  named_capture_groups : Bool,
) -> Unit {
  let any_unicode_mode = flags
    .bits()
    .land(RegularExpressionFlags::any_unicode_mode().bits()) !=
    0U
  let validator : RegexpValidator = {
    scanner,
    unicode_sets_mode: flags.contains(RegularExpressionFlags::unicode_sets()),
    any_unicode_mode,
    strict_mode: any_unicode_mode || !annex_b,
    annex_b,
    named_capture_groups,
    may_contain_strings: false,
    number_of_capturing_groups: 0,
    group_specifiers: [],
    group_name_references: [],
    decimal_escapes: [],
    scope_stack: [],
    top_scope: None,
  }
  validator._scan_disjunction(false)
  for reference in validator.group_name_references {
    if !_regexp_array_contains(validator.group_specifiers, reference.name) {
      validator._error_text(
        1532,
        reference.pos,
        reference.end - reference.pos,
        reference.name,
      )
      validator._report_spelling_suggestion(
        reference.name,
        ReadOnlyArray::from_array(validator.group_specifiers),
        reference.pos,
        reference.end - reference.pos,
      )
    }
  }
  for escape in validator.decimal_escapes {
    if escape.value > Double::from_int(validator.number_of_capturing_groups) {
      if validator.number_of_capturing_groups > 0 {
        validator._error_number(
          1533,
          escape.pos,
          escape.end - escape.pos,
          validator.number_of_capturing_groups,
        )
      } else {
        validator._error(1534, escape.pos, escape.end - escape.pos)
      }
    }
  }
}
