///|
test "parser option enums preserve TypeScript numeric values and aliases" {
  inspect(ScriptTarget::es3().to_int(), content="0")
  inspect(ScriptTarget::es2025().to_int(), content="12")
  inspect(ScriptTarget::latest().to_int(), content="99")
  inspect(ScriptTarget::json().to_int(), content="100")
  inspect(ScriptTarget::es2025().runtime_name(), content="LatestStandard")
  inspect(ScriptTarget::latest().runtime_name(), content="Latest")
  assert_true(ScriptTarget::from_int(13) is None)
  assert_true(ScriptTarget::from_int(98) is None)
  inspect(ScriptKind::external_file().to_int(), content="5")
  inspect(ScriptKind::deferred().to_int(), content="7")
  inspect(LanguageVariant::jsx().to_int(), content="1")
  inspect(JSDocParsingMode::parse_for_type_info().to_int(), content="3")
  inspect(ResolutionMode::common_js().to_int(), content="1")
  inspect(ResolutionMode::es_next().to_int(), content="99")
  inspect(DiagnosticCategory::message().to_int(), content="3")
  inspect(CommentDirectiveType::ExpectError.to_int(), content="0")
  inspect(CommentDirectiveType::Ignore.to_int(), content="1")
}

///|
test "ScriptKind inference covers every supported extension" {
  let fixtures = [
    ("a.js", ScriptKind::js()),
    ("a.CJS", ScriptKind::js()),
    ("a.mjs", ScriptKind::js()),
    ("a.jsx", ScriptKind::jsx()),
    ("a.ts", ScriptKind::ts()),
    ("a.cts", ScriptKind::ts()),
    ("a.mts", ScriptKind::ts()),
    ("a.d.ts", ScriptKind::ts()),
    ("a.tsx", ScriptKind::tsx()),
    ("a.JSON", ScriptKind::json()),
    ("a.unknown", ScriptKind::unknown()),
  ]
  for fixture in fixtures {
    let (file_name, expected) = fixture
    assert_eq(ScriptKind::from_file_name(file_name), expected)
  }
  assert_eq(ScriptKind::infer_or_ts("a.unknown"), ScriptKind::ts())
  assert_eq(
    LanguageVariant::from_script_kind(ScriptKind::tsx()),
    LanguageVariant::jsx(),
  )
  assert_eq(
    LanguageVariant::from_script_kind(ScriptKind::ts()),
    LanguageVariant::standard(),
  )
}

///|
test "declaration file recognition is case-sensitive and includes fallback" {
  let accepted = [
    "a.d.ts", "a.d.cts", "a.d.mts", "path/to/a.d.generated.ts", "path\\to\\a.d.anything.ts",
  ]
  for file_name in accepted {
    assert_true(is_declaration_file_name(file_name))
  }
  let rejected = ["a.ts", "a.D.ts", "a.d.tsx", "a.d.generated.js"]
  for file_name in rejected {
    assert_false(is_declaration_file_name(file_name))
  }
  debug_inspect(
    Extension::all().map(fn(extension) { extension.text() }),
    content=(
      #|<ReadOnlyArray:
      #|  [
      #|    ".ts",
      #|    ".tsx",
      #|    ".d.ts",
      #|    ".js",
      #|    ".jsx",
      #|    ".json",
      #|    ".tsbuildinfo",
      #|    ".mjs",
      #|    ".mts",
      #|    ".d.mts",
      #|    ".cjs",
      #|    ".cts",
      #|    ".d.cts",
      #|  ]>
    ),
  )
}
