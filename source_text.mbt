// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/core.ts and src/compiler/scanner.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// Materializes an arbitrary validated UTF-16 code-unit range, including a
/// range that splits a surrogate pair.
fn _materialize_text_range(source : String, start : Int, end : Int) -> String {
  guard start >= 0 && start <= end && end <= source.length() else {
    abort("invalid UTF-16 source range")
  }
  source.unsafe_substring(start~, end~)
}

///|
/// Immutable owner for the original MoonBit string. Its offsets are always
/// UTF-16 code-unit offsets, matching TypeScript and JavaScript strings.
pub struct SourceText {
  text : String
} derive(Eq, Debug)

///|
pub fn SourceText::new(text : String) -> SourceText {
  { text, }
}

///|
pub fn SourceText::original(self : SourceText) -> String {
  self.text
}

///|
pub fn SourceText::length(self : SourceText) -> Int {
  self.text.length()
}

///|
/// Returns EOF outside the source, matching scanner checked reads.
pub fn SourceText::code_unit_at(self : SourceText, position : Int) -> Int {
  if position < 0 || position >= self.text.length() {
    CharacterCodes::eof()
  } else {
    self.text[position].to_int()
  }
}

///|
pub fn SourceText::substring(
  self : SourceText,
  start : Int,
  end? : Int = self.text.length(),
) -> String {
  _materialize_text_range(self.text, start, end)
}

///|
pub fn SourceText::range(
  self : SourceText,
  start : Int,
  end? : Int = self.text.length(),
) -> SourceTextRange {
  SourceTextRange::new(self, start, end)
}

///|
/// An O(1) view represented only by its immutable owner and two code-unit
/// offsets. Materialization is explicit and may split a surrogate pair.
pub struct SourceTextRange {
  source : SourceText
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn SourceTextRange::new(
  source : SourceText,
  start : Int,
  end : Int,
) -> SourceTextRange {
  guard start >= 0 && start <= end && end <= source.length() else {
    abort("invalid UTF-16 source range")
  }
  { source, start, end }
}

///|
pub fn SourceTextRange::source(self : SourceTextRange) -> SourceText {
  self.source
}

///|
pub fn SourceTextRange::start(self : SourceTextRange) -> Int {
  self.start
}

///|
pub fn SourceTextRange::end(self : SourceTextRange) -> Int {
  self.end
}

///|
pub fn SourceTextRange::length(self : SourceTextRange) -> Int {
  self.end - self.start
}

///|
pub fn SourceTextRange::materialize(self : SourceTextRange) -> String {
  self.source.substring(self.start, end=self.end)
}

///|
fn _is_high_surrogate(code_unit : Int) -> Bool {
  code_unit >= 0xd800 && code_unit <= 0xdbff
}

///|
fn _is_low_surrogate(code_unit : Int) -> Bool {
  code_unit >= 0xdc00 && code_unit <= 0xdfff
}

///|
/// Decodes a valid pair but deliberately returns an unpaired surrogate as its
/// original code-unit value instead of replacing or rejecting it.
pub fn SourceText::code_point_at(self : SourceText, position : Int) -> Int {
  let first = self.code_unit_at(position)
  if _is_high_surrogate(first) {
    let second = self.code_unit_at(position + 1)
    if _is_low_surrogate(second) {
      return ((first - 0xd800) << 10) + (second - 0xdc00) + 0x10000
    }
  }
  first
}

///|
/// Number of UTF-16 code units occupied by a scanner code point. EOF occupies
/// zero units; an unpaired surrogate occupies one.
pub fn utf16_char_size(code_point : Int) -> Int {
  if code_point >= 0x10000 {
    2
  } else if code_point == CharacterCodes::eof() {
    0
  } else {
    1
  }
}

///|
/// ES UTF16Encoding for any code point in 0..0x10ffff. Surrogate values are
/// preserved as a single code unit, as with JavaScript `String.fromCodePoint`.
pub fn utf16_encode_as_string(code_point : Int) -> String {
  guard code_point >= 0 && code_point <= 0x10ffff else {
    abort("invalid Unicode code point")
  }
  if code_point <= 0xffff {
    String::from_array([code_point.unsafe_to_char()])
  } else {
    let high = ((code_point - 0x10000) >> 10) + 0xd800
    let low = ((code_point - 0x10000) & 0x3ff) + 0xdc00
    String::from_array([high.unsafe_to_char(), low.unsafe_to_char()])
  }
}
