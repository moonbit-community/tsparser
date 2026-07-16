///|
fn _source_file_integer_field(node : Node, name : String) -> Int? {
  match node.field(name) {
    Some(Integer(value)) => value
    _ => abort("expected integer SourceFile field: " + name)
  }
}

///|
fn _source_file_boolean_field(node : Node, name : String) -> Bool? {
  match node.field(name) {
    Some(Boolean(value)) => value
    _ => abort("expected boolean SourceFile field: " + name)
  }
}

///|
fn _source_file_text_field(node : Node, name : String) -> String? {
  match node.field(name) {
    Some(Text(value)) => value
    _ => abort("expected text SourceFile field: " + name)
  }
}

///|
fn _source_file_statement_list(node : Node) -> NodeArray {
  match node.field("statements") {
    Some(NodeList(Some(statements))) => statements
    _ => abort("expected SourceFile statements")
  }
}

///|
fn _source_file_diagnostics(node : Node) -> ReadOnlyArray[Diagnostic] {
  match node.field("parseDiagnostics") {
    Some(DiagnosticList(Some(diagnostics))) => diagnostics
    _ => abort("expected initialized parse diagnostics")
  }
}

///|
fn _source_file_expression(node : Node) -> Node {
  let statement = _source_file_statement_list(node).get(0).unwrap()
  match statement.field("expression") {
    Some(NodeRef(Some(expression))) => expression
    _ => abort("expected expression statement")
  }
}

///|
fn _source_file_diagnostic_projection(node : Node) -> Array[String] {
  let output : Array[String] = []
  for diagnostic in _source_file_diagnostics(node) {
    output.push(
      diagnostic.code().to_string() +
      "@" +
      diagnostic.start().unwrap().to_string() +
      ":" +
      diagnostic.length().unwrap().to_string(),
    )
  }
  output
}

///|
test "direct and wrapped JSON preserve their distinct contracts" {
  let source = "// leading\n{\n  \"name\": \"tsparser\",\n  \"values\": [1, -2, true, false, null,],\n}\n"
  let direct = parse_json_text("valid.json", source)
  let wrapped = create_source_file("valid.json", source)
  for file in [direct, wrapped] {
    assert_eq(file.kind().to_int(), 308)
    assert_eq(_source_file_integer_field(file, "languageVersion"), Some(2))
    assert_eq(_source_file_integer_field(file, "languageVariant"), Some(1))
    assert_eq(_source_file_integer_field(file, "scriptKind"), Some(6))
    assert_eq(
      _source_file_boolean_field(file, "isDeclarationFile"),
      Some(false),
    )
    assert_eq(_source_file_boolean_field(file, "hasNoDefaultLib"), Some(false))
    assert_eq(_source_file_statement_list(file).length(), 1)
    assert_eq(_source_file_expression(file).kind().to_int(), 211)
    assert_true(file.flags().contains(NodeFlags::javascript_file()))
    assert_true(file.flags().contains(NodeFlags::json_file()))
    assert_eq(
      _source_file_diagnostics(file).length(),
      0,
      msg=_source_file_diagnostic_projection(file).join(","),
    )
  }
  assert_eq(_source_file_integer_field(direct, "nodeCount"), Some(16))
  assert_eq(_source_file_integer_field(direct, "identifierCount"), Some(0))
  match direct.field("identifiers") {
    Some(TextList(Some(identifiers))) =>
      assert_eq(identifiers, ReadOnlyArray::from_array(["name", "values"]))
    _ => fail("JSON identifier table is not initialized")
  }
  match direct.field("referencedFiles") {
    Some(FileReferenceList(None)) => ()
    _ => fail("direct JSON must preserve an uninitialized reference list")
  }
  match direct.field("pragmas") {
    Some(PragmaMapValue(None)) => ()
    _ => fail("direct JSON must preserve an uninitialized pragma map")
  }
  match wrapped.field("referencedFiles") {
    Some(FileReferenceList(Some(references))) =>
      assert_eq(references.length(), 0)
    _ => fail("wrapped JSON must initialize an empty reference list")
  }
  match wrapped.field("pragmas") {
    Some(PragmaMapValue(Some(pragmas))) => assert_eq(pragmas.length(), 0)
    _ => fail("wrapped JSON must initialize an empty pragma map")
  }
  match direct.field("jsDocParsingMode") {
    Some(Integer(None)) => ()
    _ => fail("JSON does not publish a JSDoc parsing mode")
  }
}

///|
test "JSON recovery and convertToJson diagnostics match reference order" {
  let multiple = create_source_file("multiple.json", "{\"a\": 1}\n[2]\ntrue\n")
  assert_eq(_source_file_diagnostic_projection(multiple), ["1012@9:1"])
  let root = _source_file_expression(multiple)
  assert_eq(root.kind().to_int(), 210)
  match root.field("elements") {
    Some(NodeList(Some(elements))) => {
      assert_eq(elements.length(), 3)
      assert_eq(elements.pos(), -1)
      assert_eq(elements.end(), -1)
    }
    _ => fail("multiple JSON roots must synthesize one array")
  }

  let invalid = "{\n  single: 'text',\n  shorthand,\n  method() {},\n  nested: [undefined, +1],\n  optional?: 1\n}\n"
  let direct = parse_json_text("conversion.json", invalid)
  let wrapped = create_source_file("conversion.json", invalid)
  assert_eq(_source_file_diagnostics(direct).length(), 0)
  assert_eq(_source_file_diagnostic_projection(wrapped), [
    "1327@4:6", "1327@12:6", "1136@22:9", "1136@35:6", "1327@50:6", "1328@59:9",
    "1328@70:2", "8009@85:1", "1327@77:8",
  ])

  let empty = parse_json_text("empty.json", "")
  assert_eq(_source_file_statement_list(empty).length(), 0)
  assert_eq(_source_file_statement_list(empty).pos(), 0)
  assert_eq(_source_file_statement_list(empty).end(), 0)
  match empty.field("endOfFileToken") {
    Some(NodeRef(Some(eof))) => {
      assert_eq(eof.pos(), 0)
      assert_eq(eof.end(), 0)
    }
    _ => fail("empty JSON must retain EOF")
  }
}

///|
fn _source_file_pragmas(node : Node) -> ReadOnlyArray[PragmaEntry] {
  match node.field("pragmas") {
    Some(PragmaMapValue(Some(pragmas))) => pragmas
    _ => abort("expected initialized pragma map")
  }
}

///|
fn _source_file_references(
  node : Node,
  field_name : String,
) -> ReadOnlyArray[FileReference] {
  match node.field(field_name) {
    Some(FileReferenceList(Some(references))) => references
    _ => abort("expected initialized reference list: " + field_name)
  }
}

///|
test "leading pragmas populate exact SourceFile metadata" {
  let source =
    #|/// <reference path="a.ts" preserve="true" />
    #|/// <reference types="node" resolution-mode="import" />
    #|/// <reference types="bad" resolution-mode="invalid" />
    #|/// <reference lib="es2025" />
    #|/// <reference no-default-lib="true" />
    #|/// <reference />
    #|/// <amd-dependency path="dep-a" name="named" />
    #|/// <amd-dependency path="dep-b" />
    #|/// <amd-module name="first" />
    #|/// <amd-module name="second" />
    #|// @ts-check
    #|// @ts-nocheck
    #|/* @jsx h
    #| * @jsxfrag Fragment
    #| * @jsximportsource pkg
    #| * @jsxruntime automatic
    #| */
    #|export const value = 1;
  let file = create_source_file("pragmas.ts", source)
  let pragmas = _source_file_pragmas(file)
  assert_eq(
    pragmas.map(fn(entry) { entry.name() }),
    ReadOnlyArray::from_array([
      "reference", "amd-dependency", "amd-module", "ts-check", "ts-nocheck", "jsx",
      "jsxfrag", "jsximportsource", "jsxruntime",
    ]),
  )
  assert_eq(pragmas[0].occurrences().length(), 6)
  assert_eq(pragmas[1].occurrences().length(), 2)
  assert_eq(pragmas[2].occurrences().length(), 2)

  let paths = _source_file_references(file, "referencedFiles")
  assert_eq(paths.length(), 1)
  assert_eq(paths[0].file_name(), "a.ts")
  assert_eq(paths[0].pos(), 21)
  assert_eq(paths[0].end(), 25)
  assert_eq(paths[0].preserve(), Some(true))
  let types = _source_file_references(file, "typeReferenceDirectives")
  assert_eq(types.length(), 2)
  assert_eq(types[0].resolution_mode(), Some(ResolutionMode::es_next()))
  assert_true(types[1].resolution_mode() is None)
  let libraries = _source_file_references(file, "libReferenceDirectives")
  assert_eq(libraries.length(), 1)
  assert_eq(libraries[0].file_name(), "es2025")
  match file.field("amdDependencies") {
    Some(AmdDependencyList(Some(dependencies))) => {
      assert_eq(dependencies.length(), 2)
      assert_eq(dependencies[0].name(), Some("named"))
      assert_eq(dependencies[1].name(), None)
      assert_eq(dependencies[1].path(), "dep-b")
    }
    _ => fail("AMD dependency metadata is missing")
  }
  assert_eq(_source_file_text_field(file, "moduleName"), Some("second"))
  match file.field("checkJsDirective") {
    Some(CheckJsDirectiveValue(Some(directive))) => {
      assert_false(directive.enabled())
      assert_eq(directive.pos(), 410)
      assert_eq(directive.end(), 424)
    }
    _ => fail("latest check directive is missing")
  }
  assert_eq(_source_file_diagnostic_projection(file), [
    "1453@124:3", "1084@229:17", "2458@364:32",
  ])
  assert_eq(_source_file_boolean_field(file, "hasNoDefaultLib"), Some(false))
}

///|
test "SourceFile modes directives policies and parents are finalized" {
  let js = create_source_file(
    "mode.js",
    "// @ts-check\n// @ts-ignore\nexport const x = 1;\n",
    set_parent_nodes=true,
    jsdoc_parsing_mode=JSDocParsingMode::parse_for_type_info(),
    implied_node_format=ResolutionMode::common_js(),
  )
  assert_eq(_source_file_integer_field(js, "scriptKind"), Some(1))
  assert_eq(_source_file_integer_field(js, "languageVariant"), Some(1))
  assert_true(js.flags().contains(NodeFlags::javascript_file()))
  assert_eq(_source_file_integer_field(js, "jsDocParsingMode"), Some(3))
  assert_eq(_source_file_integer_field(js, "impliedNodeFormat"), Some(1))
  match js.field("commentDirectives") {
    Some(CommentDirectiveList(Some(directives))) => {
      assert_eq(directives.length(), 1)
      assert_eq(directives[0].directive_type(), CommentDirectiveType::Ignore)
    }
    _ => fail("scanner comment directives are missing")
  }
  match js.field("checkJsDirective") {
    Some(CheckJsDirectiveValue(Some(directive))) =>
      assert_true(directive.enabled())
    _ => fail("ts-check is missing")
  }
  let statement = _source_file_statement_list(js).get(0).unwrap()
  assert_true(statement.parent().unwrap().same_identity(js))
  assert_true(is_external_module(js))

  let cleared = create_source_file("module.ts", "export {};", external_module_indicator_policy=fn(
    _,
  ) {
    None
  })
  assert_false(is_external_module(cleared))
  let forced = create_source_file("script.ts", "const x = 1;", external_module_indicator_policy=fn(
    _,
  ) {
    Some(ExternalModuleIndicator::forced())
  })
  assert_true(is_external_module(forced))

  let declaration = create_source_file("types.d.ts", "declare const x: number;")
  assert_true(declaration.flags().contains(NodeFlags::ambient()))
  assert_eq(
    _source_file_boolean_field(declaration, "isDeclarationFile"),
    Some(true),
  )
  let external = create_source_file(
    "unknown.ext",
    "x;",
    script_kind=ScriptKind::external_file(),
  )
  assert_eq(_source_file_integer_field(external, "scriptKind"), Some(5))
  let deferred = create_source_file(
    "unknown.ext",
    "x;",
    script_kind=ScriptKind::deferred(),
  )
  assert_eq(_source_file_integer_field(deferred, "scriptKind"), Some(7))
  let fallback = create_source_file("unknown.ext", "x;")
  assert_eq(_source_file_integer_field(fallback, "scriptKind"), Some(3))
  let forced_json = create_source_file(
    "file.ts",
    "{}",
    language_version=ScriptTarget::json(),
    script_kind=ScriptKind::ts(),
  )
  assert_eq(_source_file_integer_field(forced_json, "languageVersion"), Some(2))
  assert_eq(_source_file_integer_field(forced_json, "scriptKind"), Some(6))
}

///|
test "isolated entity parsing consumes the complete input" {
  assert_eq(parse_isolated_entity_name("A.B.C").unwrap().kind().to_int(), 167)
  assert_true(parse_isolated_entity_name("await.default") is Some(_))
  assert_true(parse_isolated_entity_name("A + B") is None)
  assert_true(parse_isolated_entity_name("") is None)
}

///|
test "corpus regressions preserve modifiers accessors and template escapes" {
  let repeated = create_source_file(
    "repeated.ts", "class A { protected protected: any; }",
  )
  assert_eq(_source_file_diagnostics(repeated).length(), 0)
  let class_members = _parser_node_field_list(
    _source_file_statement_list(repeated).get(0).unwrap(),
    "members",
  ).unwrap()
  let property = class_members.get(0).unwrap()
  assert_eq(property.kind().to_int(), 173)
  assert_eq(_parser_node_field_list(property, "modifiers").unwrap().length(), 1)
  assert_eq(
    _parser_node_field_node(property, "name").unwrap().kind().to_int(),
    80,
  )
  match
    _parser_node_field_node(property, "name").unwrap().field("escapedText") {
    Some(Text(Some(value))) => assert_eq(value, "protected")
    _ => fail("contextual property name text is missing")
  }

  let accessors = create_source_file(
    "accessors.ts", "interface I { get foo(): string; set foo(value: string); }",
  )
  assert_eq(_source_file_diagnostics(accessors).length(), 0)
  let interface_members = _parser_node_field_list(
    _source_file_statement_list(accessors).get(0).unwrap(),
    "members",
  ).unwrap()
  assert_eq(interface_members.length(), 2)
  assert_eq(interface_members.get(0).unwrap().kind().to_int(), 178)
  assert_eq(interface_members.get(1).unwrap().kind().to_int(), 179)

  let template = create_source_file("template.ts", "`\\5`;")
  assert_eq(_source_file_diagnostic_projection(template), ["1487@1:2"])
  match _source_file_expression(template).field("text") {
    Some(Text(Some(value))) => assert_eq(value, "\u0005")
    _ => fail("template literal cooked text is missing")
  }
}

///|
test "import-type recovery retains matching-brace related information" {
  let file = create_source_file(
    "unmatched.ts", "// @target: es2015\r\n@<[[import(obju2c77,\r\n",
  )
  let diagnostics = _source_file_diagnostics(file)
  assert_eq(_source_file_diagnostic_projection(file), [
    "1109@21:1", "1005@42:0", "1109@40:0",
  ])
  match diagnostics[1].related_information() {
    Some(related) => {
      assert_eq(related.length(), 1)
      assert_eq(related[0].code(), 1007)
      assert_eq(related[0].start(), Some(42))
      assert_eq(related[0].length(), Some(0))
    }
    None => fail("missing import-type matching-brace related information")
  }
}
