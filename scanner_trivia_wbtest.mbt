///|
fn _assert_comment_range(
  actual : CommentRange,
  kind : Int,
  pos : Int,
  end : Int,
  trailing : Bool,
) -> Unit raise {
  assert_eq(actual.kind().to_int(), kind)
  assert_eq(actual.pos(), pos)
  assert_eq(actual.end(), end)
  assert_eq(actual.has_trailing_new_line(), trailing)
}

///|
test "skip_trivia matches whitespace comments shebang JSDoc and conflicts" {
  assert_eq(skip_trivia(SourceText::new(" \t/*a*/ //b\r\n\u{2028}x"), 0), 14)
  assert_eq(
    skip_trivia(SourceText::new(" \r\nx"), 0, stop_after_line_break=true),
    3,
  )
  assert_eq(
    skip_trivia(SourceText::new(" \t/*a*/x"), 0, stop_at_comments=true),
    2,
  )
  assert_eq(skip_trivia(SourceText::new("#!/usr/bin/env node\n x"), 0), 21)
  assert_eq(skip_trivia(SourceText::new("\n * value"), 0, in_jsdoc=true), 4)
  assert_eq(skip_trivia(SourceText::new("x"), -1), -1)
  assert_eq(
    skip_trivia(
      SourceText::new("<<<<<<< HEAD\na\n=======\nb\n>>>>>>> branch\nx"),
      0,
    ),
    13,
  )
  let starts = compute_token_start(SourceText::new(" /*a*/x"), 0)
  assert_eq(starts.full_start(), 0)
  assert_eq(starts.token_start(), 6)
}

///|
test "trivia start and shebang helpers match scanner rules" {
  let shebang_source = SourceText::new("#!/usr/bin/env node\nvalue")
  assert_eq(get_shebang(shebang_source), Some("#!/usr/bin/env node"))
  assert_true(could_start_trivia(shebang_source, 0))
  assert_false(could_start_trivia(SourceText::new("x"), 0))
  assert_true(could_start_trivia(SourceText::new("\u{feff}x"), 0))
  assert_true(could_start_trivia(SourceText::new("/x"), 0))
  assert_false(could_start_trivia(SourceText::new("x#"), 1))
  assert_true(get_shebang(SourceText::new(" #!x")) is None)
}

///|
test "leading comment ranges skip shebang and preserve newline metadata" {
  let source = SourceText::new("#!/usr/bin/env node\n// a\n/* b */  x")
  guard get_leading_comment_ranges(source, 0) is Some(comments) else {
    fail("expected leading comments")
  }
  assert_eq(comments.length(), 2)
  _assert_comment_range(comments[0], 2, 20, 24, true)
  _assert_comment_range(comments[1], 3, 25, 32, false)
  assert_true(get_trailing_comment_ranges(source, 0) is None)
}

///|
test "leading and trailing comment collection boundaries match TypeScript" {
  let source = SourceText::new("a; /*old*/\n // one\n /* two */ x")
  guard get_leading_comment_ranges(source, 2) is Some(leading) else {
    fail("expected leading comments")
  }
  assert_eq(leading.length(), 2)
  _assert_comment_range(leading[0], 2, 12, 18, true)
  _assert_comment_range(leading[1], 3, 20, 29, false)
  guard get_trailing_comment_ranges(source, 2) is Some(trailing) else {
    fail("expected trailing comment")
  }
  assert_eq(trailing.length(), 1)
  _assert_comment_range(trailing[0], 3, 3, 10, false)

  let second = SourceText::new("a; /*one*/ //two\n /*not*/ x")
  guard get_trailing_comment_ranges(second, 2) is Some(second_trailing) else {
    fail("expected trailing comments")
  }
  assert_eq(second_trailing.length(), 2)
  _assert_comment_range(second_trailing[0], 3, 3, 10, false)
  _assert_comment_range(second_trailing[1], 2, 11, 16, true)
  guard get_leading_comment_ranges(second, 2) is Some(second_leading) else {
    fail("expected next-line leading comment")
  }
  assert_eq(second_leading.length(), 1)
  _assert_comment_range(second_leading[0], 3, 18, 25, false)
}

///|
test "Unicode line separators retain upstream trailing-comment behavior" {
  let source = SourceText::new("a; /*one*/\u{2028}/*two*/x")
  guard get_trailing_comment_ranges(source, 2) is Some(comments) else {
    fail("expected Unicode-separated comments")
  }
  assert_eq(comments.length(), 2)
  _assert_comment_range(comments[0], 3, 3, 10, true)
  _assert_comment_range(comments[1], 3, 11, 18, false)
  assert_true(get_leading_comment_ranges(SourceText::new("a;  x"), 2) is None)
  assert_true(get_trailing_comment_ranges(SourceText::new("a;  x"), 2) is None)
}
