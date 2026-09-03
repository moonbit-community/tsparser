///|
test "every SyntaxKind token has an audited scanner path" {
  let seen = Array::make(167, false)
  let mark = fn(kind : SyntaxKind) {
    let value = kind.to_int()
    if value >= 0 && value < seen.length() {
      seen[value] = true
    }
  }
  let scan_one = fn(
    text : String,
    skip_trivia : Bool,
    variant : LanguageVariant,
  ) -> Scanner {
    let scanner = _create_scanner(
      ScriptTarget::latest(),
      skip_trivia,
      language_variant=variant,
      text~,
    )
    mark(scanner._scan())
    scanner
  }

  ignore(scan_one("\u0000", true, LanguageVariant::standard()))
  ignore(scan_one("", true, LanguageVariant::standard()))
  ignore(scan_one("//x", false, LanguageVariant::standard()))
  ignore(scan_one("/*x*/", false, LanguageVariant::standard()))
  ignore(scan_one("\r\n", false, LanguageVariant::standard()))
  ignore(scan_one(" \t", false, LanguageVariant::standard()))
  ignore(scan_one("#!/usr/bin/env node", false, LanguageVariant::standard()))
  ignore(scan_one("<<<<<<< HEAD\n", false, LanguageVariant::standard()))
  ignore(scan_one("�", true, LanguageVariant::standard()))
  ignore(scan_one("1", true, LanguageVariant::standard()))
  ignore(scan_one("1n", true, LanguageVariant::standard()))
  ignore(scan_one("'x'", true, LanguageVariant::standard()))

  let jsx_text = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text="text<",
  )
  mark(jsx_text._scan_jsx_token())
  let jsx_whitespace = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text=" \n <",
  )
  mark(jsx_whitespace._scan_jsx_token())

  let regexp = scan_one("/x/u", true, LanguageVariant::standard())
  mark(regexp._re_scan_slash_token())
  ignore(scan_one("`x`", true, LanguageVariant::standard()))
  ignore(scan_one("`x${", true, LanguageVariant::standard()))
  let template_middle = scan_one("}x${", true, LanguageVariant::standard())
  mark(template_middle._re_scan_template_token(false))
  let template_tail = scan_one("}x`", true, LanguageVariant::standard())
  mark(template_tail._re_scan_template_token(false))

  for value = 19; value <= 79; value = value + 1 {
    if value == 31 ||
      value == 34 ||
      value == 49 ||
      value == 50 ||
      value == 62 ||
      value == 63 ||
      value == 72 ||
      value == 73 {
      continue
    }
    guard _token_to_string(SyntaxKind(value)) is Some(spelling) else {
      fail("missing punctuation spelling")
    }
    let scanner = scan_one(spelling, true, LanguageVariant::standard())
    assert_eq(scanner._token().to_int(), value)
  }
  let less_than_slash = scan_one("</", true, LanguageVariant::jsx())
  assert_eq(less_than_slash._token().to_int(), 31)
  for item in [(">=", 34), (">>", 49), (">>>", 50), (">>=", 72), (">>>=", 73)] {
    let (text, expected) = item
    let scanner = scan_one(text, true, LanguageVariant::standard())
    mark(scanner._re_scan_greater_token())
    assert_eq(scanner._token().to_int(), expected)
  }
  let hash = scan_one("#x", true, LanguageVariant::standard())
  mark(hash._re_scan_hash_token())

  ignore(scan_one("identifier", true, LanguageVariant::standard()))
  ignore(scan_one("#private", true, LanguageVariant::standard()))
  let jsdoc_text = _create_scanner(ScriptTarget::latest(), true, text="words")
  mark(jsdoc_text._scan_jsdoc_comment_text_token(false))
  let jsdoc_punctuation = _create_scanner(
    ScriptTarget::latest(),
    true,
    text="`#",
  )
  mark(jsdoc_punctuation._scan_jsdoc_token())
  mark(jsdoc_punctuation._scan_jsdoc_token())

  for value = 83; value <= 166; value = value + 1 {
    guard _token_to_string(SyntaxKind(value)) is Some(spelling) else {
      fail("missing keyword spelling")
    }
    let scanner = scan_one(spelling, true, LanguageVariant::standard())
    assert_eq(scanner._token().to_int(), value)
  }

  let missing : Array[Int] = []
  for value = 0; value < seen.length(); value = value + 1 {
    if !seen[value] {
      missing.push(value)
    }
  }
  debug_inspect(
    missing,
    content=(
      #|[]
    ),
  )
}
