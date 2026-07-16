// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts, src/compiler/core.ts, src/compiler/utilities.ts, and
// src/compiler/utilitiesPublic.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// A half-open UTF-16 source range. TypeScript also uses `(-1, -1)` for
/// synthesized ranges.
pub struct TextRange {
  pos : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn TextRange::new(pos : Int, end? : Int = pos) -> TextRange {
  guard end >= pos || end == -1 else { abort("invalid TextRange") }
  { pos, end }
}

///|
pub fn TextRange::synthesized() -> TextRange {
  { pos: -1, end: -1 }
}

///|
pub fn TextRange::pos(self : TextRange) -> Int {
  self.pos
}

///|
pub fn TextRange::end(self : TextRange) -> Int {
  self.end
}

///|
pub fn TextRange::width(self : TextRange) -> Int {
  self.end - self.pos
}

///|
pub fn TextRange::is_empty(self : TextRange) -> Bool {
  self.pos == self.end
}

///|
pub fn TextRange::is_synthesized(self : TextRange) -> Bool {
  self.pos < 0 || self.end < 0
}

///|
/// TypeScript's inclusive position predicate, used where EOF belongs to the
/// enclosing range.
pub fn TextRange::contains_position(self : TextRange, position : Int) -> Bool {
  position >= self.pos && position <= self.end
}

///|
pub fn TextRange::contains_range(self : TextRange, other : TextRange) -> Bool {
  self.pos <= other.pos && self.end >= other.end
}

///|
/// Closed intersection, matching TypeScript text-span intersection semantics:
/// touching ranges intersect in an empty range.
pub fn TextRange::intersection(
  self : TextRange,
  other : TextRange,
) -> TextRange? {
  let start = if self.pos >= other.pos { self.pos } else { other.pos }
  let end = if self.end <= other.end { self.end } else { other.end }
  if start <= end {
    Some(TextRange::new(start, end~))
  } else {
    None
  }
}

///|
/// Strict overlap excludes ranges which only touch at an endpoint.
pub fn TextRange::overlaps(self : TextRange, other : TextRange) -> Bool {
  let start = if self.pos >= other.pos { self.pos } else { other.pos }
  let end = if self.end <= other.end { self.end } else { other.end }
  start < end
}

///|
pub fn TextRange::move_pos(self : TextRange, pos : Int) -> TextRange {
  TextRange::new(pos, end=self.end)
}

///|
pub fn TextRange::move_end(self : TextRange, end : Int) -> TextRange {
  TextRange::new(self.pos, end~)
}

///|
fn _clamp_position(position : Int, text_length : Int) -> Int {
  if position < 0 {
    0
  } else if position > text_length {
    text_length
  } else {
    position
  }
}

///|
/// Clips both offsets exactly as the legacy reference does before deriving line
/// and character positions.
pub fn TextRange::clipped(self : TextRange, text_length : Int) -> TextRange {
  guard text_length >= 0 else { abort("negative text length") }
  let pos = _clamp_position(self.pos, text_length)
  let end = _clamp_position(self.end, text_length)
  if end >= pos {
    TextRange::new(pos, end~)
  } else {
    TextRange::new(end, end=pos)
  }
}

///|
pub struct LineAndCharacter {
  line : Int
  character : Int
} derive(Eq, Debug)

///|
pub fn LineAndCharacter::new(line : Int, character : Int) -> LineAndCharacter {
  { line, character }
}

///|
pub fn LineAndCharacter::line(self : LineAndCharacter) -> Int {
  self.line
}

///|
pub fn LineAndCharacter::character(self : LineAndCharacter) -> Int {
  self.character
}

///|
/// TypeScript binary-search result convention: exact index, otherwise the
/// two's-complement (`-insertion_index - 1`) of the first greater element.
fn _binary_search_int(
  values : ReadOnlyArray[Int],
  key : Int,
  offset? : Int = 0,
) -> Int {
  if values.is_empty() {
    return -1
  }
  let mut low = offset
  let mut high = values.length() - 1
  while low <= high {
    let middle = low + ((high - low) >> 1)
    let value = values[middle]
    if value < key {
      low = middle + 1
    } else if value > key {
      high = middle - 1
    } else {
      return middle
    }
  }
  -low - 1
}
