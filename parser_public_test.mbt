///|
fn public_integer_field(node : Node, name : String) -> Int? {
  match node.field(name) {
    Some(Integer(value)) => value
    _ => abort("missing integer field: " + name)
  }
}

///|
fn public_text_field(node : Node, name : String) -> String? {
  match node.field(name) {
    Some(Text(value)) => value
    _ => abort("missing text field: " + name)
  }
}

///|
fn public_statements(node : Node) -> NodeArray {
  match node.field("statements") {
    Some(NodeList(Some(statements))) => statements
    _ => abort("missing statements")
  }
}

///|
fn public_diagnostics(node : Node) -> ReadOnlyArray[Diagnostic] {
  match node.field("parseDiagnostics") {
    Some(DiagnosticList(Some(diagnostics))) => diagnostics
    _ => abort("missing parse diagnostics")
  }
}

///|
test "public create_source_file optional targets and script kinds" {
  let implicit = create_source_file("default.ts", "const value = 1;")
  let explicit = create_source_file(
    "default.ts",
    "const value = 1;",
    language_version=ScriptTarget::latest(),
    script_kind=ScriptKind::unknown(),
  )
  assert_eq(public_integer_field(implicit, "languageVersion"), Some(99))
  assert_eq(
    public_integer_field(implicit, "languageVersion"),
    public_integer_field(explicit, "languageVersion"),
  )
  assert_eq(
    public_integer_field(implicit, "scriptKind"),
    public_integer_field(explicit, "scriptKind"),
  )

  let cases = [
    ("a.js", ScriptKind::unknown(), 1),
    ("a.jsx", ScriptKind::unknown(), 2),
    ("a.ts", ScriptKind::unknown(), 3),
    ("a.tsx", ScriptKind::unknown(), 4),
    ("a.ext", ScriptKind::external_file(), 5),
    ("a.json", ScriptKind::unknown(), 6),
    ("a.ext", ScriptKind::deferred(), 7),
    ("a.ext", ScriptKind::unknown(), 3),
  ]
  for item in cases {
    let (file_name, script_kind, expected) = item
    let file = create_source_file(file_name, "{}", script_kind~)
    assert_eq(
      public_integer_field(file, "scriptKind"),
      Some(expected),
      msg=file_name,
    )
  }
  let json_override = create_source_file(
    "override.ts",
    "{}",
    language_version=ScriptTarget::json(),
    script_kind=ScriptKind::js(),
  )
  assert_eq(public_integer_field(json_override, "scriptKind"), Some(6))
  assert_eq(public_integer_field(json_override, "languageVersion"), Some(2))
  let normalized = create_source_file("a\\x\\..\\b.ts", "")
  assert_eq(public_text_field(normalized, "fileName"), Some("a/b.ts"))
}

///|
test "public parent JSDoc implied-format and module-policy options" {
  let without_parents = create_source_file("parents.ts", "const x = 1;")
  assert_true(
    public_statements(without_parents).get(0).unwrap().parent() is None,
  )
  let with_parents = create_source_file(
    "parents.ts",
    "const x = 1;",
    set_parent_nodes=true,
  )
  assert_true(
    public_statements(with_parents)
    .get(0)
    .unwrap()
    .parent()
    .unwrap()
    .same_identity(with_parents),
  )

  let modes = [
    JSDocParsingMode::parse_all(),
    JSDocParsingMode::parse_none(),
    JSDocParsingMode::parse_for_type_errors(),
    JSDocParsingMode::parse_for_type_info(),
  ]
  for mode in modes {
    let file = create_source_file(
      "doc.js",
      "/** @param {number} x */\nfunction f(x) {}",
      jsdoc_parsing_mode=mode,
    )
    assert_eq(
      public_integer_field(file, "jsDocParsingMode"),
      Some(mode.to_int()),
    )
  }

  for format in [ResolutionMode::common_js(), ResolutionMode::es_next()] {
    let file = create_source_file(
      "format.ts",
      "export {};",
      implied_node_format=format,
    )
    assert_eq(
      public_integer_field(file, "impliedNodeFormat"),
      Some(format.to_int()),
    )
    assert_true(is_external_module(file))
  }
  let forced = create_source_file("script.ts", "const x = 1;", external_module_indicator_policy=fn(
    _,
  ) {
    Some(ExternalModuleIndicator::forced())
  })
  match forced.field("externalModuleIndicator") {
    Some(ExternalModuleIndicatorValue(Some(IndicatorTrue))) => ()
    _ => fail("forced module sentinel is not observable")
  }
  let cleared = create_source_file("module.ts", "export {};", external_module_indicator_policy=fn(
    _,
  ) {
    None
  })
  assert_false(is_external_module(cleared))
}

///|
test "all five public parsing entries are usable from blackbox tests" {
  let source = create_source_file(
    "entry.ts", "namespace A { export class B {} }",
  )
  assert_eq(source.kind().to_int(), 308)
  let json = parse_json_text("entry.json", "{\"ok\": true}")
  assert_eq(public_integer_field(json, "scriptKind"), Some(6))
  assert_true(parse_isolated_entity_name("A.B") is Some(_))
  assert_true(parse_isolated_entity_name("A B") is None)
  let doc = parse_isolated_jsdoc_comment("/** @type {number} */").unwrap()
  assert_eq(doc.jsdoc().kind().to_int(), 321)
  assert_eq(doc.diagnostics().length(), 0)
  assert_false(is_external_module(source))
}

///|
test "nested public parses keep invocation state isolated" {
  let mut nested : Node? = None
  let outer = create_source_file(
    "outer.ts",
    "// @ts-ignore\nexport const outerName = ;",
    external_module_indicator_policy=fn(file) {
      nested = Some(
        create_source_file(
          "inner.js", "// @ts-expect-error\nconst innerName = 1;",
        ),
      )
      match public_statements(file).get(0) {
        Some(statement) => Some(ExternalModuleIndicator::from_node(statement))
        None => None
      }
    },
  )
  let inner = nested.unwrap()
  assert_eq(public_text_field(outer, "fileName"), Some("outer.ts"))
  assert_eq(public_text_field(inner, "fileName"), Some("inner.js"))
  assert_eq(public_diagnostics(outer).length(), 1)
  assert_eq(public_diagnostics(inner).length(), 0)
  match outer.field("identifiers") {
    Some(TextList(Some(identifiers))) => {
      assert_true(identifiers.contains("outerName"))
      assert_false(identifiers.contains("innerName"))
    }
    _ => fail("outer identifier table is missing")
  }
  match inner.field("identifiers") {
    Some(TextList(Some(identifiers))) => {
      assert_true(identifiers.contains("innerName"))
      assert_false(identifiers.contains("outerName"))
    }
    _ => fail("inner identifier table is missing")
  }
  match outer.field("commentDirectives") {
    Some(CommentDirectiveList(Some(directives))) =>
      assert_eq(directives[0].directive_type().to_int(), 1)
    _ => fail("outer comment directive is missing")
  }
  match inner.field("commentDirectives") {
    Some(CommentDirectiveList(Some(directives))) =>
      assert_eq(directives[0].directive_type().to_int(), 0)
    _ => fail("inner comment directive is missing")
  }
}
