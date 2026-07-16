// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
pub fn is_line_break(code_unit : Int) -> Bool {
  code_unit == CharacterCodes::line_feed() ||
  code_unit == CharacterCodes::carriage_return() ||
  code_unit == CharacterCodes::line_separator() ||
  code_unit == CharacterCodes::paragraph_separator()
}

///|
pub fn is_white_space_single_line(code_unit : Int) -> Bool {
  code_unit == CharacterCodes::space() ||
  code_unit == CharacterCodes::tab() ||
  code_unit == CharacterCodes::vertical_tab() ||
  code_unit == CharacterCodes::form_feed() ||
  code_unit == CharacterCodes::non_breaking_space() ||
  code_unit == CharacterCodes::next_line() ||
  code_unit == CharacterCodes::ogham() ||
  (
    code_unit >= CharacterCodes::en_quad() &&
    code_unit <= CharacterCodes::zero_width_space()
  ) ||
  code_unit == CharacterCodes::narrow_no_break_space() ||
  code_unit == CharacterCodes::mathematical_space() ||
  code_unit == CharacterCodes::ideographic_space() ||
  code_unit == CharacterCodes::byte_order_mark()
}

///|
pub fn is_white_space_like(code_unit : Int) -> Bool {
  is_white_space_single_line(code_unit) || is_line_break(code_unit)
}

///|
/// Immutable UTF-16 line-start table. It always contains at least the first
/// line start `0`, including for an empty source.
pub struct LineMap {
  text_length : Int
  starts : ReadOnlyArray[Int]
} derive(Eq, Debug)

///|
pub fn LineMap::new(source : SourceText) -> LineMap {
  let starts = []
  let mut position = 0
  let mut line_start = 0
  while position < source.length() {
    let code_unit = source.code_unit_at(position)
    position += 1
    if code_unit == CharacterCodes::carriage_return() {
      if source.code_unit_at(position) == CharacterCodes::line_feed() {
        position += 1
      }
      starts.push(line_start)
      line_start = position
    } else if code_unit == CharacterCodes::line_feed() ||
      (
        code_unit > CharacterCodes::max_ascii_character() &&
        is_line_break(code_unit)
      ) {
      starts.push(line_start)
      line_start = position
    }
  }
  starts.push(line_start)
  { text_length: source.length(), starts: ReadOnlyArray::from_array(starts) }
}

///|
pub fn LineMap::starts(self : LineMap) -> ReadOnlyArray[Int] {
  self.starts
}

///|
pub fn LineMap::line_count(self : LineMap) -> Int {
  self.starts.length()
}

///|
pub fn LineMap::text_length(self : LineMap) -> Int {
  self.text_length
}

///|
pub fn LineMap::line_of_position(
  self : LineMap,
  position : Int,
  lower_bound? : Int = 0,
) -> Int {
  guard position >= 0 else { abort("position precedes source") }
  let result = _binary_search_int(self.starts, position, offset=lower_bound)
  if result >= 0 {
    result
  } else {
    let line = -result - 2
    guard line >= 0 else { abort("position precedes first line") }
    line
  }
}

///|
pub fn LineMap::line_and_character_of_position(
  self : LineMap,
  position : Int,
) -> LineAndCharacter {
  let line = self.line_of_position(position)
  LineAndCharacter::new(line, position - self.starts[line])
}

///|
/// Converts a line/character pair using TypeScript's strict or edit-tolerant
/// behavior. Strict mode rejects positions at or beyond the next line start.
pub fn LineMap::position_of_line_and_character(
  self : LineMap,
  line : Int,
  character : Int,
  allow_edits? : Bool = false,
) -> Int {
  let mut actual_line = line
  if actual_line < 0 || actual_line >= self.starts.length() {
    if allow_edits {
      actual_line = if actual_line < 0 { 0 } else { self.starts.length() - 1 }
    } else {
      abort("line outside line map")
    }
  }
  let result = self.starts[actual_line] + character
  if allow_edits {
    if actual_line + 1 < self.starts.length() &&
      result > self.starts[actual_line + 1] {
      self.starts[actual_line + 1]
    } else if result > self.text_length {
      self.text_length
    } else {
      result
    }
  } else {
    if actual_line + 1 < self.starts.length() {
      guard result < self.starts[actual_line + 1] else {
        abort("character crosses next line")
      }
    } else {
      guard result <= self.text_length else { abort("character crosses EOF") }
    }
    result
  }
}

///|
pub fn LineMap::lines_between_positions(
  self : LineMap,
  first : Int,
  second : Int,
) -> Int {
  if first == second {
    return 0
  }
  let lower = if first <= second { first } else { second }
  let upper = if first <= second { second } else { first }
  let lower_line = self.line_of_position(lower)
  let upper_line = self.line_of_position(upper, lower_bound=lower_line)
  if first <= second {
    upper_line - lower_line
  } else {
    lower_line - upper_line
  }
}
