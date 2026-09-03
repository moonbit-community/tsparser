///|
fn _parse_isolated_jsdoc(
  source : String,
  start? : Int = 0,
  length? : Int,
) -> (Node, Array[Diagnostic]) {
  let state = _new_parser_state(
    "fixture.js",
    source,
    script_kind=ScriptKind::js(),
  )
  let node = state
    ._do_inside_of_context(NodeFlags::jsdoc(), fn() {
      state._parse_jsdoc_comment_worker(start~, length?)
    })
    .unwrap()
  let diagnostics = state.diagnostics.copy()
  state._dispose()
  (node, diagnostics)
}

///|
fn _parse_first_attached_jsdoc(
  source : String,
  script_kind : ScriptKind,
  mode : JSDocParsingMode,
) -> (Node, Array[Diagnostic], Array[Diagnostic]?) {
  let state = _new_parser_state(
    "fixture.ts",
    source,
    script_kind~,
    jsdoc_parsing_mode=mode,
  )
  ignore(state._prime())
  let statements = state._parse_list(ParsingContext::source_elements(), fn() {
    state._parse_statement()
  })
  let node = statements.get(0).unwrap()
  let diagnostics = state.diagnostics.copy()
  let jsdoc_diagnostics = state.jsdoc_diagnostics.map(fn(items) { items.copy() })
  state._dispose()
  (node, diagnostics, jsdoc_diagnostics)
}

///|
fn _collect_attached_jsdoc_hosts(node : Node, output : Array[String]) -> Unit {
  match node.jsdoc() {
    Some(documents) => {
      let ranges : Array[String] = []
      for document in documents.elements() {
        ranges.push(
          document.pos().to_string() + ":" + document.end().to_string(),
        )
      }
      output.push(
        node.kind().to_int().to_string() +
        "@" +
        node.pos().to_string() +
        ":" +
        node.end().to_string() +
        "=" +
        ranges.join("+"),
      )
    }
    None => ()
  }
  ignore(
    for_each_child(node, fn(child) -> Unit? {
      _collect_attached_jsdoc_hosts(child, output)
      None
    }),
  )
}

///|
fn _collect_jsdoc_kinds(node : Node, seen : Array[Bool]) -> Unit {
  let kind = node.kind().to_int()
  if kind >= 310 && kind <= 352 {
    seen[kind - 310] = true
  }
  ignore(
    for_each_child(node, fn(child) -> Unit? {
      _collect_jsdoc_kinds(child, seen)
      None
    }),
  )
}

///|
fn _first_jsdoc_tag(document : Node) -> Node {
  match document.field("tags") {
    Some(NodeList(Some(tags))) => tags.get(0).unwrap()
    _ => abort("JSDoc fixture has no tag")
  }
}

///|
fn _jsdoc_tag_text(tag : Node) -> String {
  match _jsdoc_node_ref(tag, "tagName") {
    Some(name) => _parser_identifier_text(name).unwrap()
    None => abort("JSDoc tag has no tagName")
  }
}

///|
fn _find_jsdoc_kind(node : Node, kind : Int) -> Node? {
  if node.kind().to_int() == kind {
    return Some(node)
  }
  for_each_child(node, fn(child) -> Node? { _find_jsdoc_kind(child, kind) })
}

///|
fn _jsdoc_text_field(node : Node, field : String) -> String? {
  match node.field(field) {
    Some(Text(value)) => value
    _ => None
  }
}

///|
fn _jsdoc_boolean_field(node : Node, field : String) -> Bool? {
  match node.field(field) {
    Some(Boolean(value)) => value
    _ => None
  }
}

///|
fn _isolated_jsdoc_diagnostic_shape(
  diagnostics : ReadOnlyArray[Diagnostic],
) -> String {
  diagnostics
  .map(fn(diagnostic) {
    let related = match diagnostic.related_information() {
      Some(items) =>
        "[" +
        items
        .map(fn(item) {
          item.code().to_string() +
          "@" +
          item.start().unwrap().to_string() +
          ":" +
          item.length().unwrap().to_string()
        })
        .join(",") +
        "]"
      None => ""
    }
    diagnostic.code().to_string() +
    "@" +
    diagnostic.start().unwrap().to_string() +
    ":" +
    diagnostic.length().unwrap().to_string() +
    related
  })
  .join(",")
}

///|
fn _collect_jsdoc_parent_validity(node : Node, valid : Array[Bool]) -> Unit {
  ignore(
    for_each_child(node, fn(child) -> Unit? {
      match child.parent() {
        Some(parent) if parent.same_identity(node) => ()
        _ => valid[0] = false
      }
      _collect_jsdoc_parent_validity(child, valid)
      None
    }),
  )
}

///|
test "isolated JSDoc smoke" {
  let sources = [
    "/** hello {@link Foo#bar label} */", "/** @author Alice <a@b.com> */", "/** @param {Object} options text\n * @param {string} options.name child */",
    "/** @template {Foo} T,U text */", "/** @typedef {Object} NS.Foo desc\n * @property {string} value */",
    "/** @callback NS.Handler desc\n * @param {string} value\n * @returns {number} result */",
    "/** @overload\n * @param {string} value\n * @returns {number} */", "/** @import { Foo } from \"pkg\" with { type: \"json\" } text */",
  ]
  let shapes : Array[String] = []
  for source in sources {
    let (node, diagnostics) = _parse_isolated_jsdoc(source)
    shapes.push(_node_array_shape(node) + "|" + _diagnostic_shape(diagnostics))
  }
  let expected = [
    "N321@0:34,A@0:32:0,N322@0:10,N325@10:31,N312@17:24,N80@17:20,N80@21:24|", "N321@0:30,A@4:28:0,N331@4:28,N80@5:11,A@12:28:0,N322@12:28|",
    "N321@0:73,A@4:71:0,N342@4:71,N80@5:10,N80@20:27,N310@36:71,N323@36:71,N342@36:71,N80@37:42,N310@43:51,N154@44:50,N167@52:64,N80@52:59,N80@60:64|",
    "N321@0:31,A@4:29:0,N346@4:29,N80@5:13,N310@14:19,N184@15:18,N80@15:18,A@19:24:0,N169@20:21,N80@20:21,N169@22:23,N80@22:23|",
    "N321@0:64,A@4:62:0,N347@4:62,N80@5:12,N268@22:28,N80@22:24,N80@25:28,N323@4:62,N349@37:62,N80@38:46,N310@47:55,N154@48:54,N80@56:61|",
    "N321@0:85,A@4:83:0,N339@4:83,N80@5:13,N268@14:24,N80@14:16,N80@17:24,N324@4:83,N342@33:58,N80@34:39,N310@40:48,N154@41:47,N80@49:54,N343@58:83,N80@59:66,N310@67:75,N150@68:74|",
    "N321@0:62,A@4:60:0,N340@4:60,N80@5:13,N324@4:60,N342@17:42,N80@18:23,N310@24:32,N154@25:31,N80@33:38,N343@42:60,N80@43:50,N310@51:59,N150@52:58|",
    "N321@0:60,A@4:58:0,N352@4:58,N80@5:11,N274@12:19,N276@12:19,A@13:17:0,N277@13:17,N80@13:17,N11@24:30,N301@30:52,A@37:50:0,N302@37:50,N80@37:42,N11@43:50|",
  ]
  for index = 0; index < sources.length(); index = index + 1 {
    assert_eq(shapes[index], expected[index], msg=sources[index])
  }
}

///|
test "attached JSDoc smoke" {
  let source = "/** @deprecated old */\n/** @type { */\nconst value = 1;"
  let state = _new_parser_state(
    "fixture.js",
    source,
    script_kind=ScriptKind::js(),
  )
  ignore(state._prime())
  let statements = state._parse_list(ParsingContext::source_elements(), fn() {
    state._parse_statement()
  })
  let statement = statements.get(0).unwrap()
  let documents = statement.jsdoc().unwrap()
  let document_shapes : Array[String] = []
  for document in documents.elements() {
    document_shapes.push(_node_array_shape(document))
  }
  assert_eq(documents.length(), 2)
  assert_eq(document_shapes, [
    "N321@0:22,A@4:20:0,N332@4:20,N80@5:15", "N321@0:14,A@4:11:0,N345@4:11,N80@5:9,N310@10:11,N184@11:11,N80@11:11",
  ])
  assert_true(statement.flags().contains(NodeFlags::deprecated()))
  assert_eq(_diagnostic_shape(state.diagnostics), "")
  assert_eq(
    match state.jsdoc_diagnostics {
      Some(diagnostics) => _diagnostic_shape(diagnostics)
      None => "none"
    },
    "1110@34:0,1005@35:0",
  )
  for document in documents.elements() {
    assert_true(document.parent().unwrap().same_identity(statement))
  }
  state._dispose()
}

///|
test "all JSDoc kinds smoke" {
  let sources = [
    "/** @type {*} */", "/** @type {?} */", "/** @type {?Foo} */", "/** @type {!Foo} */",
    "/** @type {Foo?} */", "/** @type {Foo!} */", "/** @type {...string=} */", "/** @type {function(string, this:Foo): number} */",
    "/** @type {module:foo/bar} */", "/** @type {Array.<string>} */", "/** text {@link Foo label} {@linkcode Foo#bar code} {@linkplain Foo plain} */",
    "/** @see Foo#bar desc */", "/**\n * @wat unknown\n * @augments {Base<T>} aug\n * @extends Other ext\n * @implements IFace impl\n * @author Alice <a@b.com>\n * @deprecated old\n * @class cls\n * @constructor ctor\n * @public pub\n * @private priv\n * @protected prot\n * @readonly ro\n * @override ov\n */",
    "/**\n * @enum {number} en\n * @this {Foo} th\n * @return {string} ret\n * @returns {number} ret2\n * @throws {Error} err\n * @exception {RangeError} range\n * @satisfies {Foo} sat\n * @type {boolean} typ\n * @see {Foo#bar} see\n */",
    "/**\n * @arg {string} a\n * @argument [b=1] {number}\n * @param c {boolean}\n */",
    "/** @template [T=string], const U comment */", "/** @typedef {Object} Foo\n * @prop {string} Foo.a\n * @property {number} Foo.b */",
    "/** @callback NS.Handler desc\n * @param {string} value\n * @returns {number} result */",
    "/** @overload\n * @param {string} value\n * @returns {number} */", "/** @import { Foo } from \"pkg\" with { type: \"json\" } text */",
  ]
  let shapes : Array[String] = []
  let seen = Array::make(43, false)
  for source in sources {
    let (node, diagnostics) = _parse_isolated_jsdoc(source)
    _collect_jsdoc_kinds(node, seen)
    shapes.push(_node_array_shape(node) + "|" + _diagnostic_shape(diagnostics))
  }
  let expected = [
    "N321@0:16,A@4:14:0,N345@4:14,N80@5:9,N310@10:13,N313@11:12|", "N321@0:16,A@4:14:0,N345@4:14,N80@5:9,N310@10:13,N314@11:12|",
    "N321@0:19,A@4:17:0,N345@4:17,N80@5:9,N310@10:16,N315@11:15,N184@12:15,N80@12:15|",
    "N321@0:19,A@4:17:0,N345@4:17,N80@5:9,N310@10:16,N316@11:15,N184@12:15,N80@12:15|",
    "N321@0:19,A@4:17:0,N345@4:17,N80@5:9,N310@10:16,N315@11:15,N184@11:14,N80@11:14|",
    "N321@0:19,A@4:17:0,N345@4:17,N80@5:9,N310@10:16,N316@11:15,N184@11:14,N80@11:14|",
    "N321@0:25,A@4:23:0,N345@4:23,N80@5:9,N310@10:22,N317@11:21,N319@11:20,N154@14:20|",
    "N321@0:49,A@4:47:0,N345@4:47,N80@5:9,N310@10:46,N318@11:45,A@20:36:0,N170@20:26,N154@20:26,N170@27:36,N80@27:32,N184@33:36,N80@33:36,N150@38:45|",
    "N321@0:29,A@4:27:0,N345@4:27,N80@5:9,N310@10:26,N320@11:25|", "N321@0:29,A@4:27:0,N345@4:27,N80@5:9,N310@10:26,N184@11:25,N80@11:16,A@18:24:0,N154@18:24|",
    "N321@0:77,A@0:75:0,N322@0:9,N325@9:26,N80@16:19,N322@26:27,N326@27:51,N312@38:45,N80@38:41,N80@42:45,N322@51:52,N327@52:74,N80@64:67|",
    "N321@0:24,A@4:22:0,N348@4:22,N80@5:8,N311@9:16,N312@9:16,N80@9:12,N80@13:16|",
    "N321@0:262,A@7:260:0,N328@7:23,N80@8:11,N329@23:50,N80@24:32,N234@34:41,N80@34:38,A@39:40:0,N184@39:40,N80@39:40,N329@50:72,N80@51:58,N234@59:64,N80@59:64,N330@72:98,N80@73:83,N234@84:89,N80@84:89,N331@98:125,N80@99:105,A@106:125:0,N322@106:125,N332@125:144,N80@126:136,N333@144:158,N80@145:150,N333@158:179,N80@159:170,N334@179:194,N80@180:186,N335@194:211,N80@195:202,N336@211:230,N80@212:221,N337@230:246,N80@231:239,N338@246:260,N80@247:255|",
    "N321@0:221,A@7:219:0,N341@7:28,N80@8:12,N310@13:21,N150@14:20,N344@28:46,N80@29:33,N310@34:39,N184@35:38,N80@35:38,N343@46:70,N80@47:53,N310@54:62,N154@55:61,N343@70:96,N80@71:78,N310@79:87,N150@80:86,N350@96:119,N80@97:103,N310@104:111,N184@105:110,N80@105:110,N350@119:152,N80@120:129,N310@130:142,N184@131:141,N80@131:141,N351@152:176,N80@153:162,N310@163:168,N184@164:167,N80@164:167,N345@176:199,N80@177:181,N310@182:191,N136@183:190,N348@199:219,N80@200:203,N311@204:213,N312@205:212,N80@205:208,N80@209:212|1223@71:8",
    "N321@0:76,A@7:74:0,N342@7:26,N80@8:11,N310@12:20,N154@13:19,N80@21:22,N342@26:54,N80@27:35,N80@37:38,N310@41:50,N150@43:49,N342@54:74,N80@55:60,N80@61:62,N310@63:72,N136@64:71|",
    "N321@0:44,A@4:42:0,N346@4:42,N80@5:13,A@14:34:0,N169@14:24,N80@15:16,N154@17:23,N169@26:33,A@26:31:0,N87@26:31,N80@32:33|",
    "N321@0:80,A@4:78:0,N347@4:78,N80@5:12,N80@22:25,N323@4:78,N349@29:53,N80@30:34,N310@35:43,N154@36:42,N167@44:49,N80@44:47,N80@48:49,N349@53:78,N80@54:62,N310@63:71,N150@64:70,N167@72:77,N80@72:75,N80@76:77|",
    "N321@0:85,A@4:83:0,N339@4:83,N80@5:13,N268@14:24,N80@14:16,N80@17:24,N324@4:83,N342@33:58,N80@34:39,N310@40:48,N154@41:47,N80@49:54,N343@58:83,N80@59:66,N310@67:75,N150@68:74|",
    "N321@0:62,A@4:60:0,N340@4:60,N80@5:13,N324@4:60,N342@17:42,N80@18:23,N310@24:32,N154@25:31,N80@33:38,N343@42:60,N80@43:50,N310@51:59,N150@52:58|",
    "N321@0:60,A@4:58:0,N352@4:58,N80@5:11,N274@12:19,N276@12:19,A@13:17:0,N277@13:17,N80@13:17,N11@24:30,N301@30:52,A@37:50:0,N302@37:50,N80@37:42,N11@43:50|",
  ]
  for index = 0; index < sources.length(); index = index + 1 {
    assert_eq(shapes[index], expected[index], msg=sources[index])
  }
  for kind = 310; kind <= 352; kind = kind + 1 {
    assert_true(seen[kind - 310], msg="missing JSDoc kind " + kind.to_string())
  }
}

///|
test "tag aliases preserve spelling and select exact kinds" {
  let fixtures = [
    ("author", 331, " Alice"),
    ("implements", 330, " Foo"),
    ("augments", 329, " Foo"),
    ("extends", 329, " Foo"),
    ("class", 333, ""),
    ("constructor", 333, ""),
    ("public", 334, ""),
    ("private", 335, ""),
    ("protected", 336, ""),
    ("readonly", 337, ""),
    ("override", 338, ""),
    ("deprecated", 332, ""),
    ("this", 344, " {Foo}"),
    ("enum", 341, " {number}"),
    ("arg", 342, " value"),
    ("argument", 342, " value"),
    ("param", 342, " value"),
    ("return", 343, " {string}"),
    ("returns", 343, " {string}"),
    ("template", 346, " T"),
    ("type", 345, " {string}"),
    ("typedef", 347, " Value"),
    ("callback", 339, " Callback"),
    ("overload", 340, ""),
    ("satisfies", 351, " {Value}"),
    ("see", 348, " Value"),
    ("exception", 350, " {Error}"),
    ("throws", 350, " {Error}"),
    ("import", 352, " \"pkg\""),
    ("custom", 328, " text"),
  ]
  for fixture in fixtures {
    let (spelling, expected_kind, suffix) = fixture
    let source = "/** @" + spelling + suffix + " */"
    let (document, diagnostics) = _parse_isolated_jsdoc(source)
    let tag = _first_jsdoc_tag(document)
    assert_eq(tag.kind().to_int(), expected_kind, msg=source)
    assert_eq(_jsdoc_tag_text(tag), spelling, msg=source)
    assert_eq(
      _diagnostic_shape(diagnostics),
      if spelling == "import" {
        "1109@12:1"
      } else {
        ""
      },
      msg=source,
    )
  }
  for spelling in ["prop", "property"] {
    let source = "/** @typedef {Object} Value\n * @" +
      spelling +
      " {string} field */"
    let (document, diagnostics) = _parse_isolated_jsdoc(source)
    let property = _find_jsdoc_kind(document, 349).unwrap()
    assert_eq(_jsdoc_tag_text(property), spelling, msg=source)
    assert_eq(_diagnostic_shape(diagnostics), "", msg=source)
  }
}

///|
test "comment text backticks links and tag fields are exact" {
  let structured = parse_isolated_jsdoc_comment(
    "/**\r\n * First  \r\n *   second `@notTag` {@link Foo label}\r\n */",
  ).unwrap()
  let document = structured.jsdoc()
  assert_true(document.field("tags") is Some(NodeList(None)))
  match document.field("comment") {
    Some(NodeList(Some(parts))) => {
      assert_eq(parts.pos(), 0)
      assert_eq(parts.end(), 59)
      assert_eq(parts.length(), 2)
      let text = parts.get(0).unwrap()
      let link = parts.get(1).unwrap()
      assert_eq(text.kind().to_int(), 322)
      assert_eq(text.pos(), 0)
      assert_eq(text.end(), 39)
      assert_eq(
        _jsdoc_text_field(text, "text"),
        Some("First  \r\n  second `@notTag` "),
      )
      assert_eq(link.kind().to_int(), 325)
      assert_eq(link.pos(), 39)
      assert_eq(link.end(), 56)
      assert_eq(_jsdoc_text_field(link, "text"), Some("label"))
      assert_eq(
        _parser_identifier_text(_jsdoc_node_ref(link, "name").unwrap()),
        Some("Foo"),
      )
    }
    _ => fail("structured comment must retain its NodeArray")
  }
  let parameter = parse_isolated_jsdoc_comment(
      "/** leading\n * text\n * @param [value=42] {string} description\n */",
    )
    .unwrap()
    .jsdoc()
  assert_eq(_jsdoc_text_field(parameter, "comment"), Some("leading\ntext"))
  let tag = _first_jsdoc_tag(parameter)
  assert_eq(tag.kind().to_int(), 342)
  assert_eq(_jsdoc_boolean_field(tag, "isBracketed"), Some(true))
  assert_eq(_jsdoc_boolean_field(tag, "isNameFirst"), Some(true))
  assert_eq(
    _parser_identifier_text(_jsdoc_node_ref(tag, "name").unwrap()),
    Some("value"),
  )
  assert_eq(_jsdoc_text_field(tag, "comment"), Some("description"))
  let type_expression = _jsdoc_node_ref(tag, "typeExpression").unwrap()
  assert_eq(type_expression.pos(), 40)
  assert_eq(type_expression.end(), 49)
}

///|
test "isolated subranges flags and parent completion are exact" {
  let source = "xx/** @see Foo */yy"
  let result = parse_isolated_jsdoc_comment(
    source,
    start=2,
    length=source.length() - 4,
  ).unwrap()
  let document = result.jsdoc()
  assert_eq(document.pos(), 2)
  assert_eq(document.end(), 17)
  assert_true(document.parent() is None)
  assert_true(document.flags().contains(NodeFlags::jsdoc()))
  assert_eq(result.diagnostics().length(), 0)
  match document.field("tags") {
    Some(NodeList(Some(tags))) => {
      assert_eq(tags.pos(), 6)
      assert_eq(tags.end(), 14)
    }
    _ => fail("subrange JSDoc must retain tag range")
  }
  let parents_valid = [true]
  _collect_jsdoc_parent_validity(document, parents_valid)
  assert_true(parents_valid[0])
  assert_true(parse_isolated_jsdoc_comment(source) is None)
  assert_true(parse_isolated_jsdoc_comment("/**/") is None)
}

///|
test "duplicate and child-tag diagnostics retain related information" {
  let fixtures = [
    (
      "/**\n * @typedef Foo\n * @type {string}\n * @type {number}\n */", "8033@55:1[8034@0:0]",
    ),
    ("/**\n * @callback Foo\n * @template T\n */", "8039@25:8"),
    ("/**\n * @overload\n * @template T\n */", "8039@21:8"),
    ("/**\n * @param {Object} value\n * @template T\n */", "8039@33:8"),
    ("/** @type {string}\n * @type {number} */", "1223@23:5"),
    ("/** @template {Foo} */", "1069@19:1"),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let result = parse_isolated_jsdoc_comment(source).unwrap()
    assert_eq(
      _isolated_jsdoc_diagnostic_shape(result.diagnostics()),
      expected,
      msg=source,
    )
    for diagnostic in result.diagnostics() {
      let file = diagnostic.file().unwrap()
      assert_eq(file.full_text(), source)
      match diagnostic.related_information() {
        Some(items) =>
          for item in items {
            assert_true(item.file().unwrap().same_identity(file))
          }
        None => ()
      }
    }
  }
}

///|
test "attached host selection matches trailing and leading ranges" {
  let source = "/** root */ function f(/** param */ x) {}\nconst /** decl */ x = 1;\nconst f = /** arrow */ () => 1;\nexport { /** spec */ f };"
  let state = _new_parser_state(
    "fixture.js",
    source,
    script_kind=ScriptKind::js(),
  )
  ignore(state._prime())
  let statements = state._parse_list(ParsingContext::source_elements(), fn() {
    state._parse_statement()
  })
  let hosts : Array[String] = []
  for statement in statements.elements() {
    _collect_attached_jsdoc_hosts(statement, hosts)
  }
  assert_eq(
    hosts.join(","),
    "263@0:41=0:11,170@23:37=23:35,261@47:65=48:59,220@76:97=77:89,282@107:121=108:119",
  )
  assert_eq(_diagnostic_shape(state.diagnostics), "")
  state._dispose()
}

///|
test "JSDoc parsing modes match JS and TS behavior" {
  let typed = "/** @type {string} */\nconst value = 1;"
  let modes = [
    JSDocParsingMode::parse_all(),
    JSDocParsingMode::parse_none(),
    JSDocParsingMode::parse_for_type_errors(),
    JSDocParsingMode::parse_for_type_info(),
  ]
  let expected_ts = [1, 0, 0, 0]
  let expected_js = [1, 0, 1, 1]
  let expected_js_diagnostic_channel = [true, false, true, true]
  for index = 0; index < modes.length(); index = index + 1 {
    let (ts_node, ts_diagnostics, ts_jsdoc_diagnostics) = _parse_first_attached_jsdoc(
      typed,
      ScriptKind::ts(),
      modes[index],
    )
    let (js_node, js_diagnostics, js_jsdoc_diagnostics) = _parse_first_attached_jsdoc(
      typed,
      ScriptKind::js(),
      modes[index],
    )
    assert_eq(
      match ts_node.jsdoc() {
        Some(documents) => documents.length()
        None => 0
      },
      expected_ts[index],
    )
    assert_eq(
      match js_node.jsdoc() {
        Some(documents) => documents.length()
        None => 0
      },
      expected_js[index],
    )
    assert_eq(_diagnostic_shape(ts_diagnostics), "")
    assert_eq(_diagnostic_shape(js_diagnostics), "")
    assert_true(ts_jsdoc_diagnostics is None)
    assert_eq(
      js_jsdoc_diagnostics is Some(_),
      expected_js_diagnostic_channel[index],
    )
  }
  let linked = "/** @see Foo and {@link Bar} */\nconst value = 1;"
  let (errors_node, _, _) = _parse_first_attached_jsdoc(
    linked,
    ScriptKind::ts(),
    JSDocParsingMode::parse_for_type_errors(),
  )
  let (info_node, _, _) = _parse_first_attached_jsdoc(
    linked,
    ScriptKind::ts(),
    JSDocParsingMode::parse_for_type_info(),
  )
  assert_true(errors_node.jsdoc() is Some(_))
  assert_true(info_node.jsdoc() is None)
  let (tsx_errors, _, _) = _parse_first_attached_jsdoc(
    linked,
    ScriptKind::tsx(),
    JSDocParsingMode::parse_for_type_errors(),
  )
  let (tsx_info, _, _) = _parse_first_attached_jsdoc(
    linked,
    ScriptKind::tsx(),
    JSDocParsingMode::parse_for_type_info(),
  )
  let (jsx_errors, _, _) = _parse_first_attached_jsdoc(
    typed,
    ScriptKind::jsx(),
    JSDocParsingMode::parse_for_type_errors(),
  )
  let (jsx_info, _, _) = _parse_first_attached_jsdoc(
    typed,
    ScriptKind::jsx(),
    JSDocParsingMode::parse_for_type_info(),
  )
  assert_true(tsx_errors.jsdoc() is Some(_))
  assert_true(tsx_info.jsdoc() is None)
  assert_true(jsx_errors.jsdoc() is Some(_))
  assert_true(jsx_info.jsdoc() is Some(_))
}

///|
test "attached and isolated diagnostics stay in separate channels" {
  let source = "/** @type { */\nconst value = 1;"
  let (js_node, js_main, js_jsdoc) = _parse_first_attached_jsdoc(
    source,
    ScriptKind::js(),
    JSDocParsingMode::parse_all(),
  )
  assert_true(js_node.jsdoc() is Some(_))
  assert_false(js_node.flags().contains(NodeFlags::this_node_has_error()))
  assert_eq(_diagnostic_shape(js_main), "")
  assert_eq(
    match js_jsdoc {
      Some(diagnostics) => _diagnostic_shape(diagnostics)
      None => "none"
    },
    "1110@11:0,1005@12:0",
  )
  let (_, ts_main, ts_jsdoc) = _parse_first_attached_jsdoc(
    source,
    ScriptKind::ts(),
    JSDocParsingMode::parse_all(),
  )
  assert_eq(_diagnostic_shape(ts_main), "")
  assert_true(ts_jsdoc is None)
  let isolated = parse_isolated_jsdoc_comment("/** @type { */").unwrap()
  assert_eq(
    isolated
    .diagnostics()
    .map(fn(diagnostic) {
      diagnostic.code().to_string() +
      "@" +
      diagnostic.start().unwrap().to_string() +
      ":" +
      diagnostic.length().unwrap().to_string()
    })
    .join(","),
    "1110@11:0,1005@12:0",
  )
}

///|
test "EOF ranges empty comments and multiline JSDoc imports are exact" {
  let source_result = _parse_source_file_for_test(
    "/** eof */",
    file_name="fixture.js",
    script_kind=ScriptKind::js(),
    set_parent_nodes=false,
  )
  let eof = _jsdoc_node_ref(source_result.source_file, "endOfFileToken").unwrap()
  let eof_documents = eof.jsdoc().unwrap()
  assert_eq(eof_documents.length(), 1)
  assert_eq(eof_documents.get(0).unwrap().pos(), 0)
  assert_eq(eof_documents.get(0).unwrap().end(), 10)
  assert_true(
    eof_documents.get(0).unwrap().parent().unwrap().same_identity(eof),
  )
  let (empty_comment_host, _, _) = _parse_first_attached_jsdoc(
    "/**/ const value = 1;",
    ScriptKind::js(),
    JSDocParsingMode::parse_all(),
  )
  assert_true(empty_comment_host.jsdoc() is None)
  let multiline_import = "/**\n * @import {\n *   Foo,\n *   Bar\n * } from \"pkg\"\n */"
  let result = parse_isolated_jsdoc_comment(multiline_import).unwrap()
  assert_eq(
    _node_array_shape(result.jsdoc()),
    "N321@0:55,A@7:51:0,N352@7:51,N80@8:14,N274@15:40,N276@15:40,A@16:35:0,N277@16:25,N80@22:25,N277@26:35,N80@32:35,N11@45:51",
  )
  assert_eq(result.diagnostics().length(), 0)
}
