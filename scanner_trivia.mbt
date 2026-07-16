// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
pub struct CommentRange {
  kind : SyntaxKind
  pos : Int
  end : Int
  has_trailing_new_line : Bool
} derive(Eq, Debug)

///|
fn _comment_range(
  kind : SyntaxKind,
  pos : Int,
  end : Int,
  has_trailing_new_line : Bool,
) -> CommentRange {
  { kind, pos, end, has_trailing_new_line }
}

///|
pub fn CommentRange::kind(self : CommentRange) -> SyntaxKind {
  self.kind
}

///|
pub fn CommentRange::pos(self : CommentRange) -> Int {
  self.pos
}

///|
pub fn CommentRange::end(self : CommentRange) -> Int {
  self.end
}

///|
pub fn CommentRange::has_trailing_new_line(self : CommentRange) -> Bool {
  self.has_trailing_new_line
}

///|
fn _is_shebang_trivia(source : SourceText, position : Int) -> Bool {
  position == 0 &&
  source.code_unit_at(0) == CharacterCodes::hash() &&
  source.code_unit_at(1) == CharacterCodes::exclamation()
}

///|
fn _scan_shebang_trivia(source : SourceText, position : Int) -> Int {
  let mut current = position
  while current < source.length() &&
        !is_line_break(source.code_unit_at(current)) {
    current += 1
  }
  current
}

///|
pub fn get_shebang(source : SourceText) -> String? {
  if _is_shebang_trivia(source, 0) {
    Some(source.substring(0, end=_scan_shebang_trivia(source, 0)))
  } else {
    None
  }
}

///|
fn _is_conflict_marker_trivia(source : SourceText, position : Int) -> Bool {
  if position < 0 ||
    !(position == 0 || is_line_break(source.code_unit_at(position - 1))) {
    return false
  }
  let marker_length = 7
  if position + marker_length >= source.length() {
    return false
  }
  let code_unit = source.code_unit_at(position)
  for offset in 0..<marker_length {
    if source.code_unit_at(position + offset) != code_unit {
      return false
    }
  }
  code_unit == CharacterCodes::equals() ||
  source.code_unit_at(position + marker_length) == CharacterCodes::space()
}

///|
fn _scan_conflict_marker_trivia(source : SourceText, position : Int) -> Int {
  let code_unit = source.code_unit_at(position)
  let mut current = position
  if code_unit == CharacterCodes::less_than() ||
    code_unit == CharacterCodes::greater_than() {
    while current < source.length() &&
          !is_line_break(source.code_unit_at(current)) {
      current += 1
    }
  } else {
    guard code_unit == CharacterCodes::bar() ||
      code_unit == CharacterCodes::equals() else {
      abort("invalid conflict marker")
    }
    while current < source.length() {
      let current_code_unit = source.code_unit_at(current)
      if (
          current_code_unit == CharacterCodes::equals() ||
          current_code_unit == CharacterCodes::greater_than()
        ) &&
        current_code_unit != code_unit &&
        _is_conflict_marker_trivia(source, current) {
        break
      }
      current += 1
    }
  }
  current
}

///|
pub fn could_start_trivia(source : SourceText, position : Int) -> Bool {
  let code_unit = source.code_unit_at(position)
  match code_unit {
    0x0d
    | 0x0a
    | 0x09
    | 0x0b
    | 0x0c
    | 0x20
    | 0x2f
    | 0x3c
    | 0x7c
    | 0x3d
    | 0x3e => true
    0x23 => position == 0
    _ => code_unit > CharacterCodes::max_ascii_character()
  }
}

///|
/// Skips exactly the trivia consumed by TypeScript's standalone helper.
/// Synthesized (negative) positions pass through unchanged.
pub fn skip_trivia(
  source : SourceText,
  position : Int,
  stop_after_line_break? : Bool = false,
  stop_at_comments? : Bool = false,
  in_jsdoc? : Bool = false,
) -> Int {
  if position < 0 {
    return position
  }
  let mut current = position
  let mut can_consume_star = false
  while true {
    let code_unit = source.code_unit_at(current)
    match code_unit {
      0x0d => {
        if source.code_unit_at(current + 1) == CharacterCodes::line_feed() {
          current += 1
        }
        current += 1
        if stop_after_line_break {
          return current
        }
        can_consume_star = in_jsdoc
        continue
      }
      0x0a => {
        current += 1
        if stop_after_line_break {
          return current
        }
        can_consume_star = in_jsdoc
        continue
      }
      0x09 | 0x0b | 0x0c | 0x20 => {
        current += 1
        continue
      }
      0x2f => {
        if stop_at_comments {
          return current
        }
        let next = source.code_unit_at(current + 1)
        if next == CharacterCodes::slash() {
          current += 2
          while current < source.length() &&
                !is_line_break(source.code_unit_at(current)) {
            current += 1
          }
          can_consume_star = false
          continue
        }
        if next == CharacterCodes::asterisk() {
          current += 2
          while current < source.length() {
            if source.code_unit_at(current) == CharacterCodes::asterisk() &&
              source.code_unit_at(current + 1) == CharacterCodes::slash() {
              current += 2
              break
            }
            current += 1
          }
          can_consume_star = false
          continue
        }
        return current
      }
      0x3c | 0x7c | 0x3d | 0x3e => {
        if _is_conflict_marker_trivia(source, current) {
          current = _scan_conflict_marker_trivia(source, current)
          can_consume_star = false
          continue
        }
        return current
      }
      0x23 => {
        if current == 0 && _is_shebang_trivia(source, current) {
          current = _scan_shebang_trivia(source, current)
          can_consume_star = false
          continue
        }
        return current
      }
      0x2a => {
        if can_consume_star {
          current += 1
          can_consume_star = false
          continue
        }
        return current
      }
      _ => {
        if code_unit > CharacterCodes::max_ascii_character() &&
          is_white_space_like(code_unit) {
          current += 1
          continue
        }
        return current
      }
    }
  }
  abort("unreachable trivia loop")
}

///|
fn _with_trailing_new_line(comment : CommentRange) -> CommentRange {
  _comment_range(comment.kind, comment.pos, comment.end, true)
}

///|
fn _comment_ranges(
  source : SourceText,
  position : Int,
  trailing : Bool,
) -> ReadOnlyArray[CommentRange]? {
  let comments = []
  let mut current = position
  let mut collecting = trailing
  let mut pending : CommentRange? = None
  if current == 0 {
    collecting = true
    match get_shebang(source) {
      Some(shebang) => current = shebang.length()
      None => ()
    }
  }
  let mut scanning = true
  while scanning && current >= 0 && current < source.length() {
    let code_unit = source.code_unit_at(current)
    match code_unit {
      0x0d => {
        if source.code_unit_at(current + 1) == CharacterCodes::line_feed() {
          current += 1
        }
        current += 1
        if trailing {
          scanning = false
        } else {
          collecting = true
          pending = pending.map(_with_trailing_new_line)
        }
      }
      0x0a => {
        current += 1
        if trailing {
          scanning = false
        } else {
          collecting = true
          pending = pending.map(_with_trailing_new_line)
        }
      }
      0x09 | 0x0b | 0x0c | 0x20 => current += 1
      0x2f => {
        let next = source.code_unit_at(current + 1)
        if next != CharacterCodes::slash() && next != CharacterCodes::asterisk() {
          scanning = false
          continue
        }
        let kind = if next == CharacterCodes::slash() {
          SyntaxKind(2)
        } else {
          SyntaxKind(3)
        }
        let start = current
        let mut has_trailing_new_line = false
        current += 2
        if next == CharacterCodes::slash() {
          while current < source.length() {
            if is_line_break(source.code_unit_at(current)) {
              has_trailing_new_line = true
              break
            }
            current += 1
          }
        } else {
          while current < source.length() {
            if source.code_unit_at(current) == CharacterCodes::asterisk() &&
              source.code_unit_at(current + 1) == CharacterCodes::slash() {
              current += 2
              break
            }
            current += 1
          }
        }
        if collecting {
          match pending {
            Some(comment) => comments.push(comment)
            None => ()
          }
          pending = Some(
            _comment_range(kind, start, current, has_trailing_new_line),
          )
        }
      }
      _ =>
        if code_unit > CharacterCodes::max_ascii_character() &&
          is_white_space_like(code_unit) {
          if is_line_break(code_unit) {
            pending = pending.map(_with_trailing_new_line)
          }
          current += 1
        } else {
          scanning = false
        }
    }
  }
  match pending {
    Some(comment) => comments.push(comment)
    None => ()
  }
  if comments.is_empty() {
    None
  } else {
    Some(ReadOnlyArray::from_array(comments))
  }
}

///|
pub fn get_leading_comment_ranges(
  source : SourceText,
  position : Int,
) -> ReadOnlyArray[CommentRange]? {
  _comment_ranges(source, position, false)
}

///|
pub fn get_trailing_comment_ranges(
  source : SourceText,
  position : Int,
) -> ReadOnlyArray[CommentRange]? {
  _comment_ranges(source, position, true)
}

///|
pub struct FullStartAndTokenStart {
  full_start : Int
  token_start : Int
} derive(Eq, Debug)

///|
pub fn FullStartAndTokenStart::full_start(self : FullStartAndTokenStart) -> Int {
  self.full_start
}

///|
pub fn FullStartAndTokenStart::token_start(
  self : FullStartAndTokenStart,
) -> Int {
  self.token_start
}

///|
pub fn compute_token_start(
  source : SourceText,
  full_start : Int,
  stop_after_line_break? : Bool = false,
  stop_at_comments? : Bool = false,
  in_jsdoc? : Bool = false,
) -> FullStartAndTokenStart {
  {
    full_start,
    token_start: skip_trivia(
      source,
      full_start,
      stop_after_line_break~,
      stop_at_comments~,
      in_jsdoc~,
    ),
  }
}
