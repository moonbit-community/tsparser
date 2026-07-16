///|
test "line starts cover CR LF CRLF LS and PS exactly" {
  let source = SourceText::new("a\r\nb\rc\nd\u{2028}e\u{2029}")
  let line_map = LineMap::new(source)
  let expected_starts = [0, 3, 5, 7, 9, 11]
  assert_eq(line_map.line_count(), expected_starts.length())
  assert_eq(line_map.text_length(), 11)
  for index in 0..<expected_starts.length() {
    assert_eq(line_map.starts()[index], expected_starts[index])
  }
  let expected_lines = [0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5]
  let expected_characters = [0, 1, 2, 0, 1, 0, 1, 0, 1, 0, 1, 0]
  for position in 0..<=source.length() {
    let location = line_map.line_and_character_of_position(position)
    assert_eq(location.line(), expected_lines[position])
    assert_eq(location.character(), expected_characters[position])
    assert_eq(
      line_map.position_of_line_and_character(
        location.line(),
        location.character(),
      ),
      position,
    )
  }
  assert_eq(line_map.lines_between_positions(1, 9), 4)
  assert_eq(line_map.lines_between_positions(9, 1), -4)
  assert_eq(line_map.lines_between_positions(3, 3), 0)
}

///|
test "empty and trailing-newline line maps match TypeScript" {
  let empty = LineMap::new(SourceText::new(""))
  assert_eq(empty.starts().length(), 1)
  assert_eq(empty.starts()[0], 0)
  assert_eq(
    empty.line_and_character_of_position(0),
    LineAndCharacter::new(0, 0),
  )
  let trailing = LineMap::new(SourceText::new("a\n"))
  assert_eq(trailing.starts().length(), 2)
  assert_eq(trailing.starts()[0], 0)
  assert_eq(trailing.starts()[1], 2)
  assert_eq(
    trailing.line_and_character_of_position(2),
    LineAndCharacter::new(1, 0),
  )
  assert_eq(trailing.position_of_line_and_character(0, 99, allow_edits=true), 2)
  assert_eq(
    trailing.position_of_line_and_character(99, 99, allow_edits=true),
    2,
  )
  assert_eq(trailing.position_of_line_and_character(-1, 1, allow_edits=true), 1)
}

///|
test "whitespace classes distinguish NEL from ECMAScript line breaks" {
  for code in [0x0a, 0x0d, 0x2028, 0x2029] {
    assert_true(is_line_break(code))
    assert_true(is_white_space_like(code))
  }
  assert_false(is_line_break(0x85))
  assert_true(is_white_space_single_line(0x85))
  for
    code in [
      0x20, 0x09, 0x0b, 0x0c, 0xa0, 0x1680, 0x2000, 0x200b, 0x202f, 0x205f, 0x3000,
      0xfeff,
    ] {
    assert_true(is_white_space_single_line(code))
  }
  assert_false(is_white_space_like(0x61))
}
