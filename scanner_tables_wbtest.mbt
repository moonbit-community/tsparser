///|
test "all 84 keyword spellings and values match TypeScript" {
  let keywords = [
    ("break", 83),
    ("case", 84),
    ("catch", 85),
    ("class", 86),
    ("const", 87),
    ("continue", 88),
    ("debugger", 89),
    ("default", 90),
    ("delete", 91),
    ("do", 92),
    ("else", 93),
    ("enum", 94),
    ("export", 95),
    ("extends", 96),
    ("false", 97),
    ("finally", 98),
    ("for", 99),
    ("function", 100),
    ("if", 101),
    ("import", 102),
    ("in", 103),
    ("instanceof", 104),
    ("new", 105),
    ("null", 106),
    ("return", 107),
    ("super", 108),
    ("switch", 109),
    ("this", 110),
    ("throw", 111),
    ("true", 112),
    ("try", 113),
    ("typeof", 114),
    ("var", 115),
    ("void", 116),
    ("while", 117),
    ("with", 118),
    ("implements", 119),
    ("interface", 120),
    ("let", 121),
    ("package", 122),
    ("private", 123),
    ("protected", 124),
    ("public", 125),
    ("static", 126),
    ("yield", 127),
    ("abstract", 128),
    ("accessor", 129),
    ("as", 130),
    ("asserts", 131),
    ("assert", 132),
    ("any", 133),
    ("async", 134),
    ("await", 135),
    ("boolean", 136),
    ("constructor", 137),
    ("declare", 138),
    ("get", 139),
    ("infer", 140),
    ("intrinsic", 141),
    ("is", 142),
    ("keyof", 143),
    ("module", 144),
    ("namespace", 145),
    ("never", 146),
    ("out", 147),
    ("readonly", 148),
    ("require", 149),
    ("number", 150),
    ("object", 151),
    ("satisfies", 152),
    ("set", 153),
    ("string", 154),
    ("symbol", 155),
    ("type", 156),
    ("undefined", 157),
    ("unique", 158),
    ("unknown", 159),
    ("using", 160),
    ("from", 161),
    ("global", 162),
    ("bigint", 163),
    ("override", 164),
    ("of", 165),
    ("defer", 166),
  ]
  assert_eq(keywords.length(), 84)
  for item in keywords {
    let (text, value) = item
    guard _string_to_keyword(text) is Some(keyword) else {
      fail("missing keyword")
    }
    assert_eq(keyword.to_int(), value)
    guard _string_to_token(text) is Some(token) else { fail("missing token") }
    assert_eq(token.to_int(), value)
    guard _token_to_string(SyntaxKind(value)) is Some(reverse) else {
      fail("missing reverse keyword")
    }
    assert_eq(reverse, text)
  }
  assert_true(_string_to_keyword("identifier") is None)
  assert_true(_string_to_keyword("Break") is None)
}

///|
test "all punctuation spellings and values match TypeScript" {
  let punctuation = [
    ("{", 19),
    ("}", 20),
    ("(", 21),
    (")", 22),
    ("[", 23),
    ("]", 24),
    (".", 25),
    ("...", 26),
    (";", 27),
    (",", 28),
    ("?.", 29),
    ("<", 30),
    ("</", 31),
    (">", 32),
    ("<=", 33),
    (">=", 34),
    ("==", 35),
    ("!=", 36),
    ("===", 37),
    ("!==", 38),
    ("=>", 39),
    ("+", 40),
    ("-", 41),
    ("*", 42),
    ("**", 43),
    ("/", 44),
    ("%", 45),
    ("++", 46),
    ("--", 47),
    ("<<", 48),
    (">>", 49),
    (">>>", 50),
    ("&", 51),
    ("|", 52),
    ("^", 53),
    ("!", 54),
    ("~", 55),
    ("&&", 56),
    ("||", 57),
    ("?", 58),
    (":", 59),
    ("@", 60),
    ("??", 61),
    ("`", 62),
    ("#", 63),
    ("=", 64),
    ("+=", 65),
    ("-=", 66),
    ("*=", 67),
    ("**=", 68),
    ("/=", 69),
    ("%=", 70),
    ("<<=", 71),
    (">>=", 72),
    (">>>=", 73),
    ("&=", 74),
    ("|=", 75),
    ("||=", 76),
    ("&&=", 77),
    ("??=", 78),
    ("^=", 79),
  ]
  assert_eq(punctuation.length(), 61)
  for item in punctuation {
    let (text, value) = item
    guard _string_to_token(text) is Some(token) else {
      fail("missing punctuation")
    }
    assert_eq(token.to_int(), value)
    guard _token_to_string(SyntaxKind(value)) is Some(reverse) else {
      fail("missing reverse punctuation")
    }
    assert_eq(reverse, text)
  }
  assert_true(_string_to_token("=>=") is None)
  assert_true(_token_to_string(SyntaxKind(80)) is None)
}

///|
test "regexp flag character and target tables match TypeScript" {
  let flags = [
    (0x64, RegularExpressionFlags::has_indices(), 9),
    (0x67, RegularExpressionFlags::global(), -1),
    (0x69, RegularExpressionFlags::ignore_case(), -1),
    (0x6d, RegularExpressionFlags::multiline(), -1),
    (0x73, RegularExpressionFlags::dot_all(), 5),
    (0x75, RegularExpressionFlags::unicode(), 2),
    (0x76, RegularExpressionFlags::unicode_sets(), 11),
    (0x79, RegularExpressionFlags::sticky(), 2),
  ]
  for item in flags {
    let (code, flag, target) = item
    guard _character_code_to_regular_expression_flag(code) is Some(actual) else {
      fail("missing regexp flag")
    }
    assert_eq(actual.bits(), flag.bits())
    assert_eq(_regular_expression_flag_to_character_code(flag), Some(code))
    let actual_target = _regular_expression_flag_minimum_target(flag)
    if target < 0 {
      assert_true(actual_target is None)
    } else {
      guard actual_target is Some(actual_target) else {
        fail("missing regexp target")
      }
      assert_eq(actual_target.to_int(), target)
    }
  }
  assert_true(_character_code_to_regular_expression_flag(0x78) is None)
  assert_true(
    _regular_expression_flag_to_character_code(
      RegularExpressionFlags::any_unicode_mode(),
    )
    is None,
  )
}

///|
test "all language feature minimum targets match TypeScript" {
  let values = [
    (LanguageFeature::Classes, 2),
    (LanguageFeature::ForOf, 2),
    (LanguageFeature::Generators, 2),
    (LanguageFeature::Iteration, 2),
    (LanguageFeature::SpreadElements, 2),
    (LanguageFeature::RestElements, 2),
    (LanguageFeature::TaggedTemplates, 2),
    (LanguageFeature::DestructuringAssignment, 2),
    (LanguageFeature::BindingPatterns, 2),
    (LanguageFeature::ArrowFunctions, 2),
    (LanguageFeature::BlockScopedVariables, 2),
    (LanguageFeature::ObjectAssign, 2),
    (LanguageFeature::RegularExpressionFlagsUnicode, 2),
    (LanguageFeature::RegularExpressionFlagsSticky, 2),
    (LanguageFeature::Exponentiation, 3),
    (LanguageFeature::AsyncFunctions, 4),
    (LanguageFeature::ForAwaitOf, 5),
    (LanguageFeature::AsyncGenerators, 5),
    (LanguageFeature::AsyncIteration, 5),
    (LanguageFeature::ObjectSpreadRest, 5),
    (LanguageFeature::RegularExpressionFlagsDotAll, 5),
    (LanguageFeature::BindinglessCatch, 6),
    (LanguageFeature::BigInt, 7),
    (LanguageFeature::NullishCoalesce, 7),
    (LanguageFeature::OptionalChaining, 7),
    (LanguageFeature::LogicalAssignment, 8),
    (LanguageFeature::TopLevelAwait, 9),
    (LanguageFeature::ClassFields, 9),
    (LanguageFeature::PrivateNamesAndClassStaticBlocks, 9),
    (LanguageFeature::RegularExpressionFlagsHasIndices, 9),
    (LanguageFeature::ShebangComments, 10),
    (LanguageFeature::RegularExpressionFlagsUnicodeSets, 11),
    (LanguageFeature::UsingAndAwaitUsing, 99),
    (LanguageFeature::ClassAndClassElementDecorators, 99),
  ]
  assert_eq(values.length(), 34)
  for value in values {
    let (feature, target) = value
    assert_eq(feature.minimum_target().to_int(), target)
  }
}
