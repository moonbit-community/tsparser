///|
fn _module_parse_shape(source : String) -> (String, String, SyntaxKind) {
  let (statements, diagnostics, token, _) = _parse_statements_for_test(source)
  (_statement_array_shape(statements), _diagnostic_shape(diagnostics), token)
}

///|
test "import and export preorder ranges and lists match TypeScript" {
  let fixtures = [
    ("import \"m\";", "A@0:11:0,N273@0:11,N11@6:10"),
    (
      "import d, * as ns from \"m\";", "A@0:27:0,N273@0:27,N274@6:17,N80@6:8,N275@9:17,N80@14:17,N11@22:26",
    ),
    (
      "import type d, {A, type B as C} from \"m\";", "A@0:41:0,N273@0:41,N274@6:31,N80@11:13,N276@14:31,A@16:30:0,N277@16:17,N80@16:17,N277@18:30,N80@23:25,N80@28:30,N11@36:40",
    ),
    (
      "import defer * as ns from \"m\";", "A@0:30:0,N273@0:30,N274@6:20,N275@12:20,N80@17:20,N11@25:29",
    ),
    (
      "import q = require(\"m\");", "A@0:24:0,N272@0:24,N80@6:8,N284@10:23,N11@19:22",
    ),
    (
      "import type q = R.S;", "A@0:20:0,N272@0:20,N80@11:13,N167@15:19,N80@15:17,N80@18:19",
    ),
    (
      "import { type, type as, type as as, type as as as, \"x\" as y } from \"m\";",
      "A@0:71:0,N273@0:71,N274@6:61,N276@6:61,A@8:59:0,N277@8:13,N80@8:13,N277@14:22,N80@19:22,N277@23:34,N80@23:28,N80@31:34,N277@35:49,N80@40:43,N80@46:49,N277@50:59,N11@50:54,N80@57:59,N11@66:70",
    ),
    (
      "import x from \"m\" with { type: \"json\", \"k\": v, };", "A@0:49:0,N273@0:49,N274@6:8,N80@6:8,N11@13:17,N301@17:48,A@24:46:1,N302@24:37,N80@24:29,N11@30:37,N302@38:45,N11@38:42,N80@43:45",
    ),
    ("export default x;", "A@0:17:0,N278@0:17,N80@14:16"),
    ("export = x;", "A@0:11:0,N278@0:11,N80@8:10"),
    (
      "export {a, b as c, type d, \"x\" as \"y\"};", "A@0:39:0,N279@0:39,N280@6:38,A@8:37:0,N282@8:9,N80@8:9,N282@10:17,N80@10:12,N80@15:17,N282@18:25,N80@23:25,N282@26:37,N11@26:30,N11@33:37",
    ),
    ("export * from \"m\";", "A@0:18:0,N279@0:18,N11@13:17"),
    (
      "export * as ns from \"m\" assert {type: \"json\"};", "A@0:46:0,N279@0:46,N281@6:14,N80@11:14,N11@19:23,N301@23:45,A@32:44:0,N302@32:44,N80@32:36,N11@37:44",
    ),
    (
      "export type {A} from \"m\" with {type: \"json\"};", "A@0:45:0,N279@0:45,N280@11:15,A@13:14:0,N282@13:14,N80@13:14,N11@20:24,N301@24:44,A@31:43:0,N302@31:43,N80@31:35,N11@36:43",
    ),
    ("export as namespace UMD;", "A@0:24:0,N271@0:24,N80@19:23"),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (actual, diagnostics, token) = _module_parse_shape(source)
    assert_eq(actual, expected, msg=source)
    assert_eq(diagnostics, "", msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
fn _parsed_source_statements(result : SourceFileParseResult) -> NodeArray {
  _source_file_statements(result.source_file)
}

///|
fn _collect_module_flag_shape(node : Node, output : Array[String]) -> Unit {
  output.push(
    node.kind().to_int().to_string() +
    "@" +
    node.pos().to_string() +
    ":" +
    node.end().to_string() +
    ":" +
    node.flags().bits().to_string() +
    ":" +
    node.transform_flags().bits().to_string(),
  )
  ignore(
    for_each_child(node, fn(child) -> Unit? {
      _collect_module_flag_shape(child, output)
      None
    }),
  )
}

///|
fn _module_flag_shape(result : SourceFileParseResult) -> String {
  let output : Array[String] = []
  for statement in _parsed_source_statements(result).elements() {
    _collect_module_flag_shape(statement, output)
  }
  output.join(",")
}

///|
fn _external_module_indicator_for_test(
  source_file : Node,
) -> ExternalModuleIndicator? {
  match source_file.field("externalModuleIndicator") {
    Some(ExternalModuleIndicatorValue(value)) => value
    _ => abort("SourceFile externalModuleIndicator field is missing")
  }
}

///|
test "top-level await reparses only marked intervals" {
  let result = _parse_source_file_for_test(
    "export {}; const before=0; await + 1; const after=2;",
  )
  assert_eq(
    _module_flag_shape(result),
    "279@0:10:0:0,280@6:9:65536:0,244@10:26:0:4457472,262@10:25:2:4457472,261@16:25:0:0,80@16:23:0:0,9@24:25:0:0,245@26:37:65536:2097536,224@26:36:65536:2097536,225@32:36:65536:0,9@34:36:65536:0,244@37:52:0:4457472,262@37:51:2:4457472,261@43:51:0:0,80@43:49:0:0,9@50:51:0:0",
  )
  assert_eq(result.first_node_count, 19)
  assert_eq(result.final_node_count, 24)
  assert_eq(result.first_identifier_count, 3)
  assert_eq(result.final_identifier_count, 3)
  assert_eq(result.first_interned_identifier_count, 3)
  assert_eq(result.final_interned_identifier_count, 3)
  assert_eq(result.reparse_intervals.length(), 1)
  let interval = result.reparse_intervals[0]
  assert_eq(interval.start, 26)
  assert_eq(interval.initial_stop, 37)
  assert_eq(interval.final_stop, 37)
  let final_statements = _parsed_source_statements(result)
  assert_true(
    final_statements
    .get(0)
    .unwrap()
    .same_identity(result.first_pass_statements.get(0).unwrap()),
  )
  assert_true(
    final_statements
    .get(1)
    .unwrap()
    .same_identity(result.first_pass_statements.get(1).unwrap()),
  )
  assert_false(
    final_statements
    .get(2)
    .unwrap()
    .same_identity(result.first_pass_statements.get(2).unwrap()),
  )
  assert_true(
    final_statements
    .get(3)
    .unwrap()
    .same_identity(result.first_pass_statements.get(3).unwrap()),
  )
}

///|
test "top-level await expands a reparse interval after swallowing its boundary" {
  let result = _parse_source_file_for_test(
    "export {}; const before=0; await\nfunction f(){}\nconst after=1;",
  )
  assert_eq(
    _module_flag_shape(result),
    "279@0:10:0:0,280@6:9:65536:0,244@10:26:0:4457472,262@10:25:2:4457472,261@16:25:0:0,80@16:23:0:0,9@24:25:0:0,245@26:47:65536:2097536,224@26:47:65536:2097536,219@32:47:65536:4194304,80@41:43:65536:0,242@45:47:0:0,244@47:62:65536:4457472,262@47:61:65538:4457472,261@53:61:65536:0,80@53:59:65536:0,9@60:61:65536:0",
  )
  assert_eq(result.first_node_count, 19)
  assert_eq(result.final_node_count, 30)
  assert_eq(result.first_identifier_count, 4)
  assert_eq(result.final_identifier_count, 6)
  assert_eq(result.first_interned_identifier_count, 4)
  assert_eq(result.final_interned_identifier_count, 4)
  assert_eq(result.reparse_intervals.length(), 1)
  let interval = result.reparse_intervals[0]
  assert_eq(interval.start, 26)
  assert_eq(interval.initial_stop, 32)
  assert_eq(interval.final_stop, 62)
  let final_statements = _parsed_source_statements(result)
  assert_eq(final_statements.length(), 4)
  assert_true(
    final_statements
    .get(0)
    .unwrap()
    .same_identity(result.first_pass_statements.get(0).unwrap()),
  )
  assert_true(
    final_statements
    .get(1)
    .unwrap()
    .same_identity(result.first_pass_statements.get(1).unwrap()),
  )
  assert_false(
    final_statements
    .get(3)
    .unwrap()
    .same_identity(result.first_pass_statements.get(4).unwrap()),
  )
}

///|
test "top-level await preserves statements and diagnostics between intervals" {
  let result = _parse_source_file_for_test(
    "export {}; await [x]; y; await <T>(z); q;",
  )
  assert_eq(result.first_node_count, 19)
  assert_eq(result.final_node_count, 31)
  assert_eq(result.first_identifier_count, 7)
  assert_eq(result.final_identifier_count, 10)
  assert_eq(result.reparse_intervals.length(), 2)
  let final_statements = _parsed_source_statements(result)
  assert_true(
    final_statements
    .get(2)
    .unwrap()
    .same_identity(result.first_pass_statements.get(2).unwrap()),
  )
  assert_true(
    final_statements
    .get(4)
    .unwrap()
    .same_identity(result.first_pass_statements.get(4).unwrap()),
  )
  assert_eq(_diagnostic_shape(result.diagnostics), "")

  let diagnostics = _parse_source_file_for_test(
    "export {}; let a = ; await + ; let b = ;",
  )
  assert_eq(
    _diagnostic_shape(diagnostics.diagnostics),
    "1109@19:1,1109@29:1,1109@39:1",
  )
  let replacement = _parse_source_file_for_test("export {}; await (1,); x;")
  assert_eq(_diagnostic_shape(replacement.diagnostics), "1109@20:1")
}

///|
test "external module indicator policy and implied format match SourceFile contract" {
  let default_module = _parse_source_file_for_test(
    "const x=0; import \"m\"; export {};",
  )
  assert_true(is_external_module(default_module.source_file))
  match _external_module_indicator_for_test(default_module.source_file) {
    Some(IndicatorNode(node)) =>
      assert_true(
        node.same_identity(
          _parsed_source_statements(default_module).get(1).unwrap(),
        ),
      )
    _ => fail("default module indicator must be the first import")
  }

  let import_meta = _parse_source_file_for_test(
    "function f(){ return import.meta; } await + 1;",
  )
  assert_true(is_external_module(import_meta.source_file))
  match _external_module_indicator_for_test(import_meta.source_file) {
    Some(IndicatorNode(node)) => assert_eq(node.kind().to_int(), 237)
    _ => fail("import.meta must be the fallback indicator node")
  }

  let forced = _parse_source_file_for_test(
    "await + 1; const x=2;",
    implied_node_format=ResolutionMode::common_js(),
    external_module_indicator_policy=fn(_) {
      Some(ExternalModuleIndicator::forced())
    },
  )
  assert_true(is_external_module(forced.source_file))
  assert_eq(forced.reparse_intervals.length(), 1)
  assert_true(
    _external_module_indicator_for_test(forced.source_file)
    is Some(IndicatorTrue),
  )
  assert_true(
    forced.source_file.field("impliedNodeFormat") is Some(Integer(Some(1))),
  )

  let cleared = _parse_source_file_for_test(
    "export {}; await + 1;",
    implied_node_format=ResolutionMode::es_next(),
    external_module_indicator_policy=fn(_) { None },
  )
  assert_false(is_external_module(cleared.source_file))
  assert_eq(cleared.reparse_intervals.length(), 0)
  assert_true(_external_module_indicator_for_test(cleared.source_file) is None)
  assert_true(
    cleared.source_file.field("impliedNodeFormat") is Some(Integer(Some(99))),
  )

  let ordinary = _parse_source_file_for_test("const x=1;")
  assert_false(is_external_module(ordinary.source_file))
  assert_true(_external_module_indicator_for_test(ordinary.source_file) is None)
  assert_true(
    ordinary.source_file.field("impliedNodeFormat") is Some(Undefined),
  )

  let concrete = _parse_source_file_for_test("const x=1;", external_module_indicator_policy=fn(
    file,
  ) {
    Some(
      ExternalModuleIndicator::from_node(
        _source_file_statements(file).get(0).unwrap(),
      ),
    )
  })
  match _external_module_indicator_for_test(concrete.source_file) {
    Some(IndicatorNode(node)) =>
      assert_true(
        node.same_identity(_parsed_source_statements(concrete).get(0).unwrap()),
      )
    _ => fail("policy must retain its concrete indicator node")
  }
}

///|
test "final parent links cover reused and reparsed statements" {
  let result = _parse_source_file_for_test(
    "export {}; const before=0; await + 1; const after=2;",
  )
  for statement in _parsed_source_statements(result).elements() {
    match statement.parent() {
      Some(parent) => assert_true(parent.same_identity(result.source_file))
      None => fail("final statement has no SourceFile parent")
    }
  }
  assert_true(result.first_pass_statements.get(2).unwrap().parent() is None)

  let detached = _parse_source_file_for_test(
    "export {}; await + 1;",
    set_parent_nodes=false,
  )
  for statement in _parsed_source_statements(detached).elements() {
    assert_true(statement.parent() is None)
  }
}

///|
fn _first_module_statement(source : String) -> (Node, Array[Diagnostic]) {
  let (statements, diagnostics, _, _) = _parse_statements_for_test(source)
  (statements.get(0).unwrap(), diagnostics)
}

///|
fn _required_node_field(node : Node, name : String) -> Node {
  match node.field(name) {
    Some(NodeRef(Some(value))) => value
    _ => abort("required node field is absent: " + name)
  }
}

///|
fn _optional_identifier_text(node : Node, name : String) -> String {
  match node.field(name) {
    Some(NodeRef(Some(value))) =>
      match _parser_identifier_text(value) {
        Some(text) => text
        None => "<non-identifier>"
      }
    Some(NodeRef(None)) => "<none>"
    _ => "<absent>"
  }
}

///|
fn _import_modifier_shape(source : String) -> String {
  let (statement, diagnostics) = _first_module_statement(source)
  guard diagnostics.is_empty() else {
    abort("unexpected import modifier diagnostics: " + source)
  }
  if statement.kind().to_int() == 272 {
    let type_only = match statement.field("isTypeOnly") {
      Some(Boolean(Some(value))) => value
      _ => abort("import-equals isTypeOnly is absent")
    }
    return "272:" +
      (if type_only { "type" } else { "value" }) +
      ":" +
      _optional_identifier_text(statement, "name")
  }
  let clause = _required_node_field(statement, "importClause")
  let type_only = match clause.field("isTypeOnly") {
    Some(Boolean(Some(value))) => value
    _ => abort("import clause isTypeOnly is absent")
  }
  let modifier = match clause.field("phaseModifier") {
    Some(Kind(Some(kind))) => kind.to_int().to_string()
    Some(Kind(None)) => "none"
    _ => "absent"
  }
  "273:" +
  (if type_only { "type" } else { "value" }) +
  ":" +
  modifier +
  ":" +
  _optional_identifier_text(clause, "name")
}

///|
test "type and defer import modifier ambiguity matches TypeScript 6.0.3" {
  let fixtures = [
    ("import type d from \"m\";", "273:type:156:d"),
    ("import defer * as ns from \"m\";", "273:value:166:<none>"),
    ("import type from \"m\";", "273:value:none:type"),
    ("import type from = require(\"m\");", "272:type:from"),
    ("import defer from \"m\";", "273:value:none:defer"),
    ("import defer from from \"m\";", "273:value:166:from"),
    ("import defer, {x} from \"m\";", "273:value:none:defer"),
    ("import type {x} from \"m\";", "273:type:156:<none>"),
    ("import type = require(\"m\");", "272:value:type"),
    ("import defer = require(\"m\");", "272:value:defer"),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    assert_eq(_import_modifier_shape(source), expected, msg=source)
  }
}

///|
fn _module_name_shape(node : Node?) -> String {
  match node {
    None => "none"
    Some(node) => {
      let text = match node.kind().to_int() {
        80 =>
          match _parser_identifier_text(node) {
            Some(text) => text
            None => ""
          }
        11 =>
          match node.field("text") {
            Some(Text(Some(text))) => text
            _ => ""
          }
        _ => ""
      }
      node.kind().to_int().to_string() + ":" + text
    }
  }
}

///|
fn _module_specifier_shape(specifier : Node) -> String {
  let type_only = match specifier.field("isTypeOnly") {
    Some(Boolean(Some(value))) => value
    _ => abort("specifier isTypeOnly is absent")
  }
  let property = match specifier.field("propertyName") {
    Some(NodeRef(value)) => value
    _ => abort("specifier propertyName is absent")
  }
  let name = match specifier.field("name") {
    Some(NodeRef(value)) => value
    _ => abort("specifier name is absent")
  }
  (if type_only { "type" } else { "value" }) +
  ":" +
  _module_name_shape(property) +
  ":" +
  _module_name_shape(name)
}

///|
test "import and export specifier names preserve type/as/string ambiguity" {
  let (statement, diagnostics) = _first_module_statement(
    "import { type, type as, type as as, type as as as, type x, a as b, \"x\" as y, default as d, await as a } from \"m\";",
  )
  assert_eq(_diagnostic_shape(diagnostics), "")
  let clause = _required_node_field(statement, "importClause")
  let bindings = _required_node_field(clause, "namedBindings")
  let elements = match bindings.field("elements") {
    Some(NodeList(Some(elements))) => elements
    _ => abort("named imports elements are absent")
  }
  let expected = [
    "value:none:80:type", "type:none:80:as", "value:80:type:80:as", "type:80:as:80:as",
    "type:none:80:x", "value:80:a:80:b", "value:11:x:80:y", "value:80:default:80:d",
    "value:80:await:80:a",
  ]
  assert_eq(elements.length(), expected.length())
  for index = 0; index < expected.length(); index = index + 1 {
    assert_eq(
      _module_specifier_shape(elements.get(index).unwrap()),
      expected[index],
    )
  }

  let (exports, export_diagnostics) = _first_module_statement(
    "export { default, class as c, \"x\" as \"y\" };",
  )
  assert_eq(_diagnostic_shape(export_diagnostics), "")
  let named = _required_node_field(exports, "exportClause")
  let export_elements = match named.field("elements") {
    Some(NodeList(Some(elements))) => elements
    _ => abort("named exports elements are absent")
  }
  assert_eq(
    export_elements.elements().map(_module_specifier_shape).join(","),
    "value:none:80:default,value:80:class:80:c,value:11:x:11:y",
  )
}

///|
test "import attributes preserve token multiline trailing and duplicate shape" {
  let (assert_import, diagnostics) = _first_module_statement(
    "import x from \"m\" assert {type: \"json\"};",
  )
  assert_eq(_diagnostic_shape(diagnostics), "")
  let attributes = _required_node_field(assert_import, "attributes")
  assert_true(
    assert_import.field("assertClause") is Some(NodeRef(Some(attribute_alias))) &&
    attribute_alias.same_identity(attributes),
  )
  assert_true(
    attributes.field("token") is Some(Kind(Some(kind))) && kind.to_int() == 132,
  )
  assert_true(attributes.field("multiLine") is Some(Boolean(Some(false))))

  let (multi, multi_diagnostics) = _first_module_statement(
    "import x from \"m\" with {\n type: \"json\", type: \"css\",\n};",
  )
  assert_eq(_diagnostic_shape(multi_diagnostics), "")
  let multi_attributes = _required_node_field(multi, "attributes")
  assert_true(
    multi_attributes.field("token") is Some(Kind(Some(kind))) &&
    kind.to_int() == 118,
  )
  assert_true(multi_attributes.field("multiLine") is Some(Boolean(Some(true))))
  let attribute_elements = match multi_attributes.field("elements") {
    Some(NodeList(Some(elements))) => elements
    _ => abort("import attributes elements are absent")
  }
  assert_eq(attribute_elements.length(), 2)
  assert_true(attribute_elements.has_trailing_comma())
  assert_eq(
    _optional_identifier_text(attribute_elements.get(0).unwrap(), "name"),
    "type",
  )
  assert_eq(
    _optional_identifier_text(attribute_elements.get(1).unwrap(), "name"),
    "type",
  )

  let with_newline = _first_module_statement(
      "import x from \"m\"\nwith {type: \"json\"};",
    ).0
  assert_eq(
    _required_node_field(with_newline, "attributes").kind().to_int(),
    301,
  )
  let (_, assert_newline_diagnostics, _, _) = _parse_statements_for_test(
    "import x from \"m\"\nassert {type: \"json\"};",
  )
  assert_eq(_diagnostic_shape(assert_newline_diagnostics), "1435@18:6")
}

///|
test "module recovery diagnostics and Unicode names match TypeScript" {
  let fixtures = [
    ("import { \"x\" } from \"m\";", "1003@9:3"),
    ("import { default } from \"m\";", "1003@9:7"),
    ("import { a as \\u0064efault } from \"m\";", "1003@14:12"),
    ("import { a b } from \"m\";", "1005@11:1"),
    ("export { from \"m\";", "1005@9:4"),
    ("export * \"m\";", "1005@9:3"),
    ("import x from \"m\" with { type \"json\" };", "1005@30:6"),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (_, diagnostics, _, _) = _parse_statements_for_test(source)
    assert_eq(_diagnostic_shape(diagnostics), expected, msg=source)
  }
  for
    source in [
      "import { \\u0061 as b } from \"m\";", "import { \\u0064efault as d } from \"m\";",
      "export { \\u0064efault as d };", "export { default, class as c, \"x\" as \"y\" };",
      "import q = require(1 + x);", "import q = require;",
    ] {
    let (_, diagnostics, token, _) = _parse_statements_for_test(source)
    assert_eq(_diagnostic_shape(diagnostics), "", msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
  let (_, missing_close, _, _) = _parse_statements_for_test(
    "import x from \"m\" with { type: \"json\"",
  )
  assert_eq(_diagnostic_shape(missing_close), "1005@37:0")
  let related = missing_close[0].related_information()
  assert_true(related is Some(items) && items.length() == 1)
  match related {
    Some(items) => {
      assert_eq(items[0].code(), 1007)
      assert_eq(items[0].start(), Some(23))
      assert_eq(items[0].length(), Some(1))
    }
    None => fail("missing close-brace diagnostic has no related information")
  }
}

///|
test "external indicators distinguish import-equals exports and declaration files" {
  for
    source in [
      "import q = require(\"m\");", "export const x=1;", "import \"m\";", "export default 1;",
      "export {};",
    ] {
    let result = _parse_source_file_for_test(source)
    assert_true(is_external_module(result.source_file), msg=source)
  }
  for
    source in [
      "import q = R.S;", "import q = require;", "export as namespace UMD;", "const x=1;",
    ] {
    let result = _parse_source_file_for_test(source)
    assert_false(is_external_module(result.source_file), msg=source)
  }
  let declaration = _parse_source_file_for_test(
    "export {}; await + 1;",
    file_name="ambient.d.mts",
  )
  assert_true(is_external_module(declaration.source_file))
  assert_eq(declaration.reparse_intervals.length(), 0)
  assert_true(declaration.source_file.flags().contains(NodeFlags::ambient()))
  assert_true(
    declaration.source_file.field("nodeCount") is Some(Integer(Some(count))) &&
    count == declaration.final_node_count,
  )
  assert_true(
    declaration.source_file.field("identifierCount")
    is Some(Integer(Some(count))) &&
    count == declaration.final_identifier_count,
  )
}

///|
test "possible await inside functions does not trigger a source interval" {
  let result = _parse_source_file_for_test(
    "export {}; function f(){ await + 1; } const x=2;",
  )
  assert_eq(result.reparse_intervals.length(), 0)
  assert_eq(result.first_node_count, result.final_node_count)
  assert_eq(result.first_identifier_count, result.final_identifier_count)
}
