// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _scanner_number_to_string(value : Double) -> String {
  value.to_string()
}

///|
fn _scanner_parse_double(text : String) -> Double {
  try @string.parse_double(text) catch {
    _ => 0x7ff0000000000000UL.reinterpret_as_double()
  } noraise {
    value => value
  }
}

///|
fn _scanner_parse_radix_double(text : String, radix : Int) -> Double {
  let mut value = 0.0
  for code_unit in text {
    let digit = _hex_value(code_unit.to_int())
    if digit >= 0 && digit < radix {
      value = value * Double::from_int(radix) + Double::from_int(digit)
    }
  }
  value
}

///|
fn _scanner_double_integer_to_octal(value : Double) -> String {
  if value == 0.0 {
    return "0"
  }
  let bits = value.reinterpret_as_uint64()
  let exponent_bits = (bits >> 52).land(0x7ffUL).to_int()
  if exponent_bits == 0x7ff {
    return value.to_string()
  }
  if exponent_bits == 0 {
    return "0"
  }
  let significand = bits.land(0x000fffffffffffffUL).lor(0x0010000000000000UL)
  let binary = StringBuilder::new()
  for bit = 52; bit >= 0; bit = bit - 1 {
    binary.write_char(
      (if (significand >> bit).land(1UL) == 0UL { 0x30 } else { 0x31 }).unsafe_to_char(),
    )
  }
  let shift = exponent_bits - 1023 - 52
  if shift >= 0 {
    for _ in 0..<shift {
      binary.write_string("0")
    }
  }
  let full_binary = binary.to_string()
  let integer_binary = if shift < 0 {
    let end = full_binary.length() + shift
    if end <= 0 {
      return "0"
    }
    full_binary.unsafe_substring(start=0, end~)
  } else {
    full_binary
  }
  let output = StringBuilder::new()
  let padding = (3 - integer_binary.length() % 3) % 3
  let mut group_value = 0
  let mut group_size = 0
  for _ in 0..<padding {
    group_value *= 2
    group_size += 1
  }
  for code_unit in integer_binary {
    group_value = group_value * 2 +
      code_unit.to_int() -
      CharacterCodes::digit_0()
    group_size += 1
    if group_size == 3 {
      output.write_char(
        (CharacterCodes::digit_0() + group_value).unsafe_to_char(),
      )
      group_value = 0
      group_size = 0
    }
  }
  output.to_string()
}

///|
fn _scanner_radix_integer_to_decimal(text : String, radix : Int) -> String {
  // Little-endian base-10^8 limbs avoid front insertion and stay within a
  // signed 32-bit Int even when multiplying a limb by hexadecimal radix 16.
  let limbs : Array[Int] = [0]
  let limb_base = 100000000
  for character in text {
    let digit = _hex_value(character.to_int())
    if digit < 0 || digit >= radix {
      continue
    }
    let mut carry = digit
    for index = 0; index < limbs.length(); index = index + 1 {
      let next = limbs[index] * radix + carry
      limbs[index] = next % limb_base
      carry = next / limb_base
    }
    while carry > 0 {
      limbs.push(carry % limb_base)
      carry /= limb_base
    }
  }
  let output = StringBuilder::new()
  let mut index = limbs.length() - 1
  output.write_string(limbs[index].to_string())
  index -= 1
  while index >= 0 {
    let limb = limbs[index].to_string()
    for _ in 0..<(8 - limb.length()) {
      output.write_string("0")
    }
    output.write_string(limb)
    index -= 1
  }
  output.to_string()
}

///|
fn Scanner::_scan_number_fragment(self : Scanner) -> String {
  let output = StringBuilder::new()
  let mut start = self.pos
  let mut allow_separator = false
  let mut previous_was_separator = false
  while true {
    let code_unit = self._code_unit(self.pos)
    if code_unit == CharacterCodes::underscore() {
      self.token_flags = self.token_flags.union(
        TokenFlags::contains_separator(),
      )
      if allow_separator {
        allow_separator = false
        previous_was_separator = true
        output.write_string(self.source.substring(start, end=self.pos))
      } else {
        self.token_flags = self.token_flags.union(
          TokenFlags::contains_invalid_separator(),
        )
        let code = if previous_was_separator { 6189 } else { 6188 }
        self._error_at(_diagnostic_message(code), self.pos, 1)
      }
      self.pos += 1
      start = self.pos
      continue
    }
    if _is_digit(code_unit) {
      allow_separator = true
      previous_was_separator = false
      self.pos += 1
      continue
    }
    break
  }
  if self._code_unit(self.pos - 1) == CharacterCodes::underscore() {
    self.token_flags = self.token_flags.union(
      TokenFlags::contains_invalid_separator(),
    )
    self._error_at(_diagnostic_message(6188), self.pos - 1, 1)
  }
  output.write_string(self.source.substring(start, end=self.pos))
  output.to_string()
}

///|
fn Scanner::_scan_decimal_digits(self : Scanner) -> Bool {
  let start = self.pos
  let mut is_octal = true
  while _is_digit(self._code_unit(self.pos)) {
    if !_is_octal_digit(self._code_unit(self.pos)) {
      is_octal = false
    }
    self.pos += 1
  }
  self._set_token_value(self.source.substring(start, end=self.pos))
  is_octal
}

///|
fn Scanner::_scan_hex_digits(
  self : Scanner,
  minimum_count : Int,
  scan_as_many_as_possible : Bool,
  can_have_separators : Bool,
) -> String {
  let values : Array[Int] = []
  let mut allow_separator = false
  let mut previous_was_separator = false
  while values.length() < minimum_count || scan_as_many_as_possible {
    let code_unit = self._code_unit(self.pos)
    if can_have_separators && code_unit == CharacterCodes::underscore() {
      self.token_flags = self.token_flags.union(
        TokenFlags::contains_separator(),
      )
      if allow_separator {
        allow_separator = false
        previous_was_separator = true
      } else {
        let code = if previous_was_separator { 6189 } else { 6188 }
        self._error_at(_diagnostic_message(code), self.pos, 1)
      }
      self.pos += 1
      continue
    }
    allow_separator = can_have_separators
    if !_is_hex_digit(code_unit) {
      break
    }
    let normalized = if code_unit >= CharacterCodes::upper_a() &&
      code_unit <= CharacterCodes::upper_f() {
      code_unit + CharacterCodes::lower_a() - CharacterCodes::upper_a()
    } else {
      code_unit
    }
    values.push(normalized)
    self.pos += 1
    previous_was_separator = false
  }
  if self._code_unit(self.pos - 1) == CharacterCodes::underscore() {
    self._error_at(_diagnostic_message(6188), self.pos - 1, 1)
  }
  if values.length() < minimum_count {
    return ""
  }
  String::from_array(values.map(fn(value) { value.unsafe_to_char() }))
}

///|
fn Scanner::_scan_exact_hex_digits(
  self : Scanner,
  count : Int,
  can_have_separators : Bool,
) -> Int {
  let text = self._scan_hex_digits(count, false, can_have_separators)
  if text == "" {
    -1
  } else {
    _scanner_parse_radix_double(text, 16).to_int()
  }
}

///|
fn Scanner::_scan_minimum_hex_digits(
  self : Scanner,
  count : Int,
  can_have_separators : Bool,
) -> String {
  self._scan_hex_digits(count, true, can_have_separators)
}

///|
fn Scanner::_scan_binary_or_octal_digits(self : Scanner, radix : Int) -> String {
  let output = StringBuilder::new()
  let mut separator_allowed = false
  let mut previous_was_separator = false
  while true {
    let code_unit = self._code_unit(self.pos)
    if code_unit == CharacterCodes::underscore() {
      self.token_flags = self.token_flags.union(
        TokenFlags::contains_separator(),
      )
      if separator_allowed {
        separator_allowed = false
        previous_was_separator = true
      } else {
        let code = if previous_was_separator { 6189 } else { 6188 }
        self._error_at(_diagnostic_message(code), self.pos, 1)
      }
      self.pos += 1
      continue
    }
    separator_allowed = true
    if !_is_digit(code_unit) || code_unit - CharacterCodes::digit_0() >= radix {
      break
    }
    output.write_char(code_unit.unsafe_to_char())
    self.pos += 1
    previous_was_separator = false
  }
  if self._code_unit(self.pos - 1) == CharacterCodes::underscore() {
    self._error_at(_diagnostic_message(6188), self.pos - 1, 1)
  }
  output.to_string()
}

///|
fn Scanner::_check_big_int_suffix(self : Scanner) -> SyntaxKind {
  let token_value = self._required_token_value()
  if self._code_unit(self.pos) == CharacterCodes::lower_n() {
    let radix_and_digits = if self.token_flags.contains(
        TokenFlags::binary_specifier(),
      ) {
      Some((2, token_value.unsafe_substring(start=2, end=token_value.length())))
    } else if self.token_flags.contains(TokenFlags::octal_specifier()) {
      Some((8, token_value.unsafe_substring(start=2, end=token_value.length())))
    } else {
      None
    }
    self._set_token_value(
      match radix_and_digits {
        Some((radix, digits)) =>
          _scanner_radix_integer_to_decimal(digits, radix) + "n"
        None => token_value + "n"
      },
    )
    self.pos += 1
    SyntaxKind(10)
  } else {
    let numeric_value = if self.token_flags.contains(
        TokenFlags::binary_specifier(),
      ) {
      _scanner_parse_radix_double(
        token_value.unsafe_substring(start=2, end=token_value.length()),
        2,
      )
    } else if self.token_flags.contains(TokenFlags::octal_specifier()) {
      _scanner_parse_radix_double(
        token_value.unsafe_substring(start=2, end=token_value.length()),
        8,
      )
    } else if self.token_flags.contains(TokenFlags::hex_specifier()) {
      _scanner_parse_radix_double(
        token_value.unsafe_substring(start=2, end=token_value.length()),
        16,
      )
    } else {
      _scanner_parse_double(token_value)
    }
    self._set_token_value(_scanner_number_to_string(numeric_value))
    SyntaxKind(9)
  }
}

///|
fn Scanner::_check_identifier_after_number(
  self : Scanner,
  numeric_start : Int,
  scientific? : Bool = false,
) -> Unit {
  if !_is_identifier_start(self._code_point(self.pos), self.language_version) {
    return
  }
  let identifier_start = self.pos
  let identifier = self._scan_identifier_parts()
  if identifier.length() == 1 &&
    self.source.code_unit_at(identifier_start) == CharacterCodes::lower_n() {
    let code = if scientific { 1352 } else { 1353 }
    self._error_at(
      _diagnostic_message(code),
      numeric_start,
      identifier_start - numeric_start + 1,
    )
  } else {
    self._error_at(
      _diagnostic_message(1351),
      identifier_start,
      identifier.length(),
    )
    self.pos = identifier_start
  }
}

///|
fn Scanner::_scan_number(self : Scanner) -> SyntaxKind {
  let mut start = self.pos
  let main_fragment = if self._code_unit(self.pos) == CharacterCodes::digit_0() {
    self.pos += 1
    if self._code_unit(self.pos) == CharacterCodes::underscore() {
      self.token_flags = self.token_flags
        .union(TokenFlags::contains_separator())
        .union(TokenFlags::contains_invalid_separator())
      self._error_at(_diagnostic_message(6188), self.pos, 1)
      self.pos -= 1
      self._scan_number_fragment()
    } else if !self._scan_decimal_digits() {
      self.token_flags = self.token_flags.union(
        TokenFlags::contains_leading_zero(),
      )
      _scanner_number_to_string(
        _scanner_parse_double(self._required_token_value()),
      )
    } else if self._required_token_value() == "" {
      "0"
    } else {
      let value = _scanner_parse_radix_double(self._required_token_value(), 8)
      self._set_token_value(_scanner_number_to_string(value))
      self.token_flags = self.token_flags.union(TokenFlags::octal())
      let with_minus = self.token.to_int() == 41
      let replacement = (if with_minus { "-" } else { "" }) +
        "0o" +
        _scanner_double_integer_to_octal(value)
      if with_minus {
        start -= 1
      }
      self._error_at(
        _diagnostic_message(1121),
        start,
        self.pos - start,
        argument=DiagnosticArgument::text(replacement),
      )
      return SyntaxKind(9)
    }
  } else {
    self._scan_number_fragment()
  }
  let mut decimal_fragment : String? = None
  let mut scientific_fragment : String? = None
  if self._code_unit(self.pos) == CharacterCodes::dot() {
    self.pos += 1
    decimal_fragment = Some(self._scan_number_fragment())
  }
  let mut numeric_end = self.pos
  if self._code_unit(self.pos) == CharacterCodes::upper_e() ||
    self._code_unit(self.pos) == CharacterCodes::lower_e() {
    self.pos += 1
    self.token_flags = self.token_flags.union(TokenFlags::scientific())
    if self._code_unit(self.pos) == CharacterCodes::plus() ||
      self._code_unit(self.pos) == CharacterCodes::minus() {
      self.pos += 1
    }
    let pre_numeric_part = self.pos
    let final_fragment = self._scan_number_fragment()
    if final_fragment == "" {
      self._error(_diagnostic_message(1124))
    } else {
      scientific_fragment = Some(
        self.source.substring(numeric_end, end=pre_numeric_part) +
        final_fragment,
      )
      numeric_end = self.pos
    }
  }
  let result = if self.token_flags.contains(TokenFlags::contains_separator()) {
    let output = StringBuilder::new()
    output.write_string(main_fragment)
    match decimal_fragment {
      Some(fragment) => {
        output.write_string(".")
        output.write_string(fragment)
      }
      None => ()
    }
    match scientific_fragment {
      Some(fragment) => output.write_string(fragment)
      None => ()
    }
    output.to_string()
  } else {
    self.source.substring(start, end=numeric_end)
  }
  if self.token_flags.contains(TokenFlags::contains_leading_zero()) {
    self._error_at(_diagnostic_message(1489), start, numeric_end - start)
    self._set_token_value(
      _scanner_number_to_string(_scanner_parse_double(result)),
    )
    return SyntaxKind(9)
  }
  if decimal_fragment is Some(_) ||
    self.token_flags.contains(TokenFlags::scientific()) {
    self._check_identifier_after_number(
      start,
      scientific=decimal_fragment is None &&
        self.token_flags.contains(TokenFlags::scientific()),
    )
    self._set_token_value(
      _scanner_number_to_string(_scanner_parse_double(result)),
    )
    SyntaxKind(9)
  } else {
    self._set_token_value(result)
    let kind = self._check_big_int_suffix()
    self._check_identifier_after_number(start)
    kind
  }
}

///|
fn Scanner::_scan_extended_unicode_escape(
  self : Scanner,
  report_errors : Bool,
) -> String {
  let start = self.pos
  self.pos += 3
  let escaped_start = self.pos
  let digits = self._scan_minimum_hex_digits(1, false)
  let escaped_value = if digits == "" {
    -1
  } else {
    _scanner_parse_radix_double(digits, 16).to_int()
  }
  let mut invalid = false
  if escaped_value < 0 {
    if report_errors {
      self._error(_diagnostic_message(1125))
    }
    invalid = true
  } else if escaped_value > 0x10ffff {
    if report_errors {
      self._error_at(
        _diagnostic_message(1198),
        escaped_start,
        self.pos - escaped_start,
      )
    }
    invalid = true
  }
  if self.pos >= self.end {
    if report_errors {
      self._error(_diagnostic_message(1126))
    }
    invalid = true
  } else if self._code_unit(self.pos) == CharacterCodes::close_brace() {
    self.pos += 1
  } else {
    if report_errors {
      self._error(_diagnostic_message(1199))
    }
    invalid = true
  }
  if invalid {
    self.token_flags = self.token_flags.union(
      TokenFlags::contains_invalid_escape(),
    )
    self.source.substring(start, end=self.pos)
  } else {
    self.token_flags = self.token_flags.union(
      TokenFlags::extended_unicode_escape(),
    )
    utf16_encode_as_string(escaped_value)
  }
}

///|
fn Scanner::_peek_unicode_escape(self : Scanner) -> Int {
  if self.pos + 5 < self.end &&
    self._code_unit(self.pos + 1) == CharacterCodes::lower_u() {
    let mut value = 0
    for offset in 2..<6 {
      let digit = _hex_value(self._code_unit(self.pos + offset))
      if digit < 0 {
        return -1
      }
      value = value * 16 + digit
    }
    value
  } else {
    -1
  }
}

///|
fn Scanner::_peek_extended_unicode_escape(self : Scanner) -> Int {
  if self._code_unit(self.pos + 1) != CharacterCodes::lower_u() ||
    self._code_unit(self.pos + 2) != CharacterCodes::open_brace() {
    return -1
  }
  let mut cursor = self.pos + 3
  let mut value = 0
  let mut count = 0
  while _is_hex_digit(self._code_unit(cursor)) {
    let digit = _hex_value(self._code_unit(cursor))
    if value > (0x10ffff - digit) / 16 {
      return 0x110000
    }
    value = value * 16 + digit
    count += 1
    cursor += 1
  }
  if count > 0 {
    value
  } else {
    -1
  }
}

///|
fn Scanner::_scan_identifier_parts(self : Scanner) -> String {
  let output = StringBuilder::new()
  let mut start = self.pos
  while self.pos < self.end {
    let mut code_point = self._code_point(self.pos)
    if _is_identifier_part(code_point, self.language_version) {
      self.pos += utf16_char_size(code_point)
    } else if code_point == CharacterCodes::backslash() {
      code_point = self._peek_extended_unicode_escape()
      if code_point >= 0 &&
        _is_identifier_part(code_point, self.language_version) {
        output.write_string(self.source.substring(start, end=self.pos))
        output.write_string(self._scan_extended_unicode_escape(true))
        start = self.pos
        continue
      }
      code_point = self._peek_unicode_escape()
      if code_point < 0 ||
        !_is_identifier_part(code_point, self.language_version) {
        break
      }
      self.token_flags = self.token_flags.union(TokenFlags::unicode_escape())
      output.write_string(self.source.substring(start, end=self.pos))
      output.write_string(utf16_encode_as_string(code_point))
      self.pos += 6
      start = self.pos
    } else {
      break
    }
  }
  output.write_string(self.source.substring(start, end=self.pos))
  output.to_string()
}

///|
fn Scanner::_identifier_token(self : Scanner) -> SyntaxKind {
  let token_value = self._required_token_value()
  if token_value.length() >= 2 && token_value.length() <= 12 {
    match _string_to_keyword(token_value) {
      Some(keyword) => return keyword
      None => ()
    }
  }
  SyntaxKind(80)
}

///|
fn Scanner::_scan_identifier(
  self : Scanner,
  start_character : Int,
  target : ScriptTarget,
) -> SyntaxKind? {
  let mut code_point = start_character
  if !_is_identifier_start(code_point, target) {
    return None
  }
  self.pos += utf16_char_size(code_point)
  while self.pos < self.end {
    code_point = self._code_point(self.pos)
    if !_is_identifier_part(code_point, target) {
      break
    }
    self.pos += utf16_char_size(code_point)
  }
  self._set_token_value(self.source.substring(self.token_start, end=self.pos))
  if code_point == CharacterCodes::backslash() {
    self._set_token_value(
      self._required_token_value() + self._scan_identifier_parts(),
    )
  }
  Some(self._identifier_token())
}

///|
fn Scanner::_scan_escape_sequence(
  self : Scanner,
  report_invalid_escape? : Bool = true,
) -> String {
  let start = self.pos
  self.pos += 1
  if self.pos >= self.end {
    self._error(_diagnostic_message(1126))
    return ""
  }
  let code_unit = self._code_unit(self.pos)
  self.pos += 1
  match code_unit {
    0x30 | 0x31 | 0x32 | 0x33 | 0x34 | 0x35 | 0x36 | 0x37 => {
      if code_unit == CharacterCodes::digit_0() &&
        !_is_digit(self._code_unit(self.pos)) {
        return utf16_encode_as_string(0)
      }
      if code_unit <= CharacterCodes::digit_3() &&
        _is_octal_digit(self._code_unit(self.pos)) {
        self.pos += 1
      }
      if _is_octal_digit(self._code_unit(self.pos)) {
        self.pos += 1
      }
      let octal_text = self.source.substring(start + 1, end=self.pos)
      let value = _scanner_parse_radix_double(octal_text, 8).to_int()
      self.token_flags = self.token_flags.union(
        TokenFlags::contains_invalid_escape(),
      )
      if !report_invalid_escape {
        return self.source.substring(start, end=self.pos)
      }
      let hex = value.to_string(radix=16)
      let replacement = "\\x" + (if hex.length() == 1 { "0" } else { "" }) + hex
      self._error_at(
        _diagnostic_message(1487),
        start,
        self.pos - start,
        argument=DiagnosticArgument::text(replacement),
      )
      utf16_encode_as_string(value)
    }
    0x38 | 0x39 => {
      self.token_flags = self.token_flags.union(
        TokenFlags::contains_invalid_escape(),
      )
      if !report_invalid_escape {
        return self.source.substring(start, end=self.pos)
      }
      self._error_at(
        _diagnostic_message(1488),
        start,
        self.pos - start,
        argument=DiagnosticArgument::text(
          self.source.substring(start, end=self.pos),
        ),
      )
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
      if self._code_unit(self.pos) == CharacterCodes::open_brace() {
        self.pos = start
        return self._scan_extended_unicode_escape(report_invalid_escape)
      }
      let mut value = 0
      let required_end = start + 6
      while self.pos < required_end {
        let digit = _hex_value(self._code_unit(self.pos))
        if digit < 0 {
          self.token_flags = self.token_flags.union(
            TokenFlags::contains_invalid_escape(),
          )
          if report_invalid_escape {
            self._error(_diagnostic_message(1125))
          }
          return self.source.substring(start, end=self.pos)
        }
        value = value * 16 + digit
        self.pos += 1
      }
      self.token_flags = self.token_flags.union(TokenFlags::unicode_escape())
      utf16_encode_as_string(value)
    }
    0x78 => {
      let mut value = 0
      let required_end = start + 4
      while self.pos < required_end {
        let digit = _hex_value(self._code_unit(self.pos))
        if digit < 0 {
          self.token_flags = self.token_flags.union(
            TokenFlags::contains_invalid_escape(),
          )
          if report_invalid_escape {
            self._error(_diagnostic_message(1125))
          }
          return self.source.substring(start, end=self.pos)
        }
        value = value * 16 + digit
        self.pos += 1
      }
      self.token_flags = self.token_flags.union(TokenFlags::hex_escape())
      utf16_encode_as_string(value)
    }
    0x0d => {
      if self._code_unit(self.pos) == CharacterCodes::line_feed() {
        self.pos += 1
      }
      ""
    }
    0x0a | 0x2028 | 0x2029 => ""
    _ => utf16_encode_as_string(code_unit)
  }
}

///|
fn Scanner::_scan_string(
  self : Scanner,
  jsx_attribute_string? : Bool = false,
) -> String {
  let quote = self._code_unit(self.pos)
  self.pos += 1
  let output = StringBuilder::new()
  let mut start = self.pos
  while true {
    if self.pos >= self.end {
      output.write_string(self.source.substring(start, end=self.pos))
      self.token_flags = self.token_flags.union(TokenFlags::unterminated())
      self._error(_diagnostic_message(1002))
      break
    }
    let code_unit = self._code_unit(self.pos)
    if code_unit == quote {
      output.write_string(self.source.substring(start, end=self.pos))
      self.pos += 1
      break
    }
    if code_unit == CharacterCodes::backslash() && !jsx_attribute_string {
      output.write_string(self.source.substring(start, end=self.pos))
      output.write_string(self._scan_escape_sequence())
      start = self.pos
      continue
    }
    if (
        code_unit == CharacterCodes::line_feed() ||
        code_unit == CharacterCodes::carriage_return()
      ) &&
      !jsx_attribute_string {
      output.write_string(self.source.substring(start, end=self.pos))
      self.token_flags = self.token_flags.union(TokenFlags::unterminated())
      self._error(_diagnostic_message(1002))
      break
    }
    self.pos += 1
  }
  output.to_string()
}

///|
fn Scanner::_scan_template(
  self : Scanner,
  report_invalid_escape : Bool,
) -> SyntaxKind {
  let started_with_backtick = self._code_unit(self.pos) ==
    CharacterCodes::backtick()
  self.pos += 1
  let output = StringBuilder::new()
  let mut start = self.pos
  while true {
    if self.pos >= self.end {
      output.write_string(self.source.substring(start, end=self.pos))
      self.token_flags = self.token_flags.union(TokenFlags::unterminated())
      self._error(_diagnostic_message(1160))
      self._set_token_value(output.to_string())
      return if started_with_backtick { SyntaxKind(15) } else { SyntaxKind(18) }
    }
    let code_unit = self._code_unit(self.pos)
    if code_unit == CharacterCodes::backtick() {
      output.write_string(self.source.substring(start, end=self.pos))
      self.pos += 1
      self._set_token_value(output.to_string())
      return if started_with_backtick { SyntaxKind(15) } else { SyntaxKind(18) }
    }
    if code_unit == CharacterCodes::dollar() &&
      self._code_unit(self.pos + 1) == CharacterCodes::open_brace() {
      output.write_string(self.source.substring(start, end=self.pos))
      self.pos += 2
      self._set_token_value(output.to_string())
      return if started_with_backtick { SyntaxKind(16) } else { SyntaxKind(17) }
    }
    if code_unit == CharacterCodes::backslash() {
      output.write_string(self.source.substring(start, end=self.pos))
      output.write_string(self._scan_escape_sequence(report_invalid_escape~))
      start = self.pos
      continue
    }
    if code_unit == CharacterCodes::carriage_return() {
      output.write_string(self.source.substring(start, end=self.pos))
      self.pos += 1
      if self._code_unit(self.pos) == CharacterCodes::line_feed() {
        self.pos += 1
      }
      output.write_string("\n")
      start = self.pos
      continue
    }
    self.pos += 1
  } nobreak {
    abort("unreachable template scanner state")
  }
}
