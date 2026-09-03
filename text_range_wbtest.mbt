///|
test "TextRange operations use TypeScript boundary semantics" {
  let range = TextRange::new(3, end=8)
  assert_eq(range.pos(), 3)
  assert_eq(range.end(), 8)
  assert_eq(range.width(), 5)
  assert_false(range.is_empty())
  assert_true(range.contains_position(3))
  assert_true(range.contains_position(8))
  assert_false(range.contains_position(9))
  assert_true(range.contains_range(TextRange::new(4, end=8)))
  assert_false(range.contains_range(TextRange::new(2, end=4)))
  assert_eq(
    range.intersection(TextRange::new(8, end=12)),
    Some(TextRange::new(8)),
  )
  assert_false(range.overlaps(TextRange::new(8, end=12)))
  assert_true(range.overlaps(TextRange::new(7, end=12)))
  assert_eq(range.move_pos(4), TextRange::new(4, end=8))
  assert_eq(range.move_end(9), TextRange::new(3, end=9))
  assert_eq(TextRange::new(-4, end=20).clipped(10), TextRange::new(0, end=10))
  assert_eq(TextRange::synthesized().clipped(10), TextRange::new(0))
  assert_true(TextRange::synthesized().is_synthesized())
}

///|
test "binary search returns TypeScript two's-complement insertion points" {
  let values = ReadOnlyArray::from_array([5, 10, 23, 80])
  assert_eq(_binary_search_int(values, 5), 0)
  assert_eq(_binary_search_int(values, 23), 2)
  assert_eq(_binary_search_int(values, 20), -3)
  assert_eq(_binary_search_int(values, 0), -1)
  assert_eq(_binary_search_int(values, 100), -5)
  assert_eq(_binary_search_int(values, 20, offset=1), -3)
  assert_eq(_binary_search_int(ReadOnlyArray::from_array([]), 1), -1)
}
