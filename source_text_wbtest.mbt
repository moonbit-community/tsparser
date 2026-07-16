///|
test "SourceText retains exact UTF-16 code units and O(1) ranges" {
  let source = SourceText::new("A😀B")
  assert_eq(source.original(), "A😀B")
  assert_eq(source.length(), 4)
  let expected = [0x41, 0xd83d, 0xde00, 0x42]
  for index in 0..<expected.length() {
    assert_eq(source.code_unit_at(index), expected[index])
  }
  assert_eq(source.code_unit_at(-1), CharacterCodes::eof())
  assert_eq(source.code_unit_at(4), CharacterCodes::eof())
  assert_eq(source.code_point_at(1), 0x1f600)
  assert_eq(source.code_point_at(2), 0xde00)
  assert_eq(source.code_point_at(4), CharacterCodes::eof())
  let high = source.range(1, end=2)
  let low = source.range(2, end=3)
  assert_eq(high.start(), 1)
  assert_eq(high.end(), 2)
  assert_eq(high.length(), 1)
  assert_eq(high.source().original(), source.original())
  assert_eq(high.materialize().code_units()[0].to_int(), 0xd83d)
  assert_eq(low.materialize().code_units()[0].to_int(), 0xde00)
  assert_eq(source.substring(1, end=3), "😀")
}

///|
test "UTF-16 code point size and encoding preserve lone surrogates" {
  assert_eq(utf16_char_size(CharacterCodes::eof()), 0)
  assert_eq(utf16_char_size(0x61), 1)
  assert_eq(utf16_char_size(0xd800), 1)
  assert_eq(utf16_char_size(0x10000), 2)
  let ascii = utf16_encode_as_string(0x61)
  assert_eq(ascii, "a")
  let face = utf16_encode_as_string(0x1f600)
  assert_eq(face, "😀")
  assert_eq(face.length(), 2)
  assert_eq(face.code_units()[0].to_int(), 0xd83d)
  assert_eq(face.code_units()[1].to_int(), 0xde00)
  let lone_high = utf16_encode_as_string(0xd800)
  assert_eq(lone_high.length(), 1)
  assert_eq(lone_high.code_units()[0].to_int(), 0xd800)
  let lone_low = utf16_encode_as_string(0xdfff)
  assert_eq(lone_low.length(), 1)
  assert_eq(lone_low.code_units()[0].to_int(), 0xdfff)
  let maximum = utf16_encode_as_string(0x10ffff)
  assert_eq(maximum.length(), 2)
  assert_eq(SourceText::new(maximum).code_point_at(0), 0x10ffff)
}
