///|
fn _parse_first_jsx_expression(
  source : String,
  script_kind : ScriptKind,
) -> (Node, Array[Diagnostic], SyntaxKind) {
  let (statements, diagnostics, token, _) = _parse_statements_for_test(
    source,
    script_kind~,
  )
  let statement = statements.get(0).unwrap()
  (
    _parser_node_field_node(statement, "expression").unwrap(),
    diagnostics,
    token,
  )
}

///|
test "JSX elements fragments attributes children and ranges match TypeScript" {
  let fixtures = [
    ("<div />", "N286@0:7,N80@1:4,N293@4:4,A@4:4:0"),
    (
      "<div a b=\"x&amp;y\" c={v} ns:x={}>text{x}<span/> </div>", "N285@0:54,N287@0:33,N80@1:4,N293@4:32,A@4:32:0,N292@4:6,N80@4:6,N292@6:18,N80@6:8,N11@9:18,N292@18:24,N80@18:20,N295@21:24,N80@22:23,N292@24:32,N296@24:29,N80@24:27,N80@28:29,N295@30:32,A@33:48:0,N12@33:37,N295@37:40,N80@38:39,N286@40:47,N80@41:45,N293@45:45,A@45:45:0,N12@47:48,N288@48:54,N80@50:53",
    ),
    (
      "<>a\n  <A.B<T> {...p} />&amp;</>", "N289@0:31,N290@0:2,A@2:28:0,N12@2:6,N286@6:23,N212@7:10,N80@7:8,N80@9:10,A@11:12:0,N184@11:12,N80@11:12,N293@13:20,A@13:20:0,N294@13:20,N80@18:19,N12@23:28,N291@28:31",
    ),
    (
      "<this.foo></this.foo>", "N285@0:21,N287@0:10,N212@1:9,N110@1:5,N80@6:9,N293@9:9,A@9:9:0,A@10:10:0,N288@10:21,N212@12:20,N110@12:16,N80@17:20",
    ),
    (
      "<ns:tag></ns:tag>", "N285@0:17,N287@0:8,N296@1:7,N80@1:3,N80@4:7,N293@7:7,A@7:7:0,A@8:8:0,N288@8:17,N296@10:16,N80@10:12,N80@13:16",
    ),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (node, diagnostics, token, _) = _parse_expression_for_test(
      source,
      script_kind=ScriptKind::tsx(),
    )
    assert_eq(_node_array_shape(node), expected)
    assert_eq(_diagnostic_shape(diagnostics), "", msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "JSX recovery and TSX ambiguity match TypeScript" {
  let fixtures = [
    (
      "<div><span></div>", "N285@0:17,N287@0:5,N80@1:4,N293@4:4,A@4:4:0,A@5:11:0,N285@5:11,N287@5:11,N80@6:10,N293@10:10,A@10:10:0,A@11:11:0,N288@11:11,N80@11:11,N288@11:17,N80@13:16",
      "17008@6:4",
    ),
    (
      "<div></span>", "N285@0:12,N287@0:5,N80@1:4,N293@4:4,A@4:4:0,A@5:5:0,N288@5:12,N80@7:11",
      "17002@7:4",
    ),
    (
      "<div></div><span></span>", "N227@0:24,N285@0:11,N287@0:5,N80@1:4,N293@4:4,A@4:4:0,A@5:5:0,N288@5:11,N80@7:10,N28@11:11,N285@11:24,N287@11:17,N80@12:16,N293@16:16,A@16:16:0,A@17:17:0,N288@17:24,N80@19:23",
      "2657@0:24",
    ),
    (
      "<T>(x)", "N285@0:6,N287@0:3,N80@1:2,N293@2:2,A@2:2:0,A@3:6:0,N12@3:6,N288@6:6,N80@6:6",
      "17008@1:1,1005@6:0",
    ),
    ("+ <A/>", "N225@0:6,N286@1:6,N80@3:4,N293@4:4,A@4:4:0", ""),
    (
      "<Comp<T> p />", "N286@0:13,N80@1:5,A@6:7:0,N184@6:7,N80@6:7,N293@8:10,A@8:10:0,N292@8:10,N80@8:10",
      "",
    ),
  ]
  for fixture in fixtures {
    let (source, expected, expected_diagnostics) = fixture
    let (node, diagnostics, token, _) = _parse_expression_for_test(
      source,
      script_kind=ScriptKind::tsx(),
    )
    assert_eq(_node_array_shape(node), expected)
    assert_eq(_diagnostic_shape(diagnostics), expected_diagnostics, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }

  let arrow_fixtures = [("<T,>(x:T)=>x", 220), ("<T extends U>(x:T)=>x", 220)]
  for fixture in arrow_fixtures {
    let (source, expected_kind) = fixture
    let (node, diagnostics, token, _) = _parse_expression_for_test(
      source,
      script_kind=ScriptKind::tsx(),
    )
    assert_eq(node.kind().to_int(), expected_kind, msg=source)
    assert_eq(_diagnostic_shape(diagnostics), "", msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "JSX text fields and scanner diagnostics match TypeScript" {
  let (fragment, fragment_diagnostics, fragment_token, _) = _parse_expression_for_test(
    "<>\n   \n</>",
    script_kind=ScriptKind::tsx(),
  )
  let fragment_children = _parser_node_field_list(fragment, "children").unwrap()
  let whitespace = fragment_children.get(0).unwrap()
  assert_true(whitespace.field("text") is Some(Text(Some("\n   \n"))))
  assert_true(
    whitespace.field("containsOnlyTriviaWhiteSpaces")
    is Some(Boolean(Some(true))),
  )
  assert_eq(_diagnostic_shape(fragment_diagnostics), "")
  assert_eq(fragment_token.to_int(), 1)

  let (raw, raw_diagnostics, raw_token, _) = _parse_expression_for_test(
    "<a s=\"&amp;\">&amp; &bogus;</a>",
    script_kind=ScriptKind::tsx(),
  )
  let opening = _parser_node_field_node(raw, "openingElement").unwrap()
  let attributes = _parser_node_field_node(opening, "attributes").unwrap()
  let properties = _parser_node_field_list(attributes, "properties").unwrap()
  let initializer = _parser_node_field_node(
    properties.get(0).unwrap(),
    "initializer",
  ).unwrap()
  assert_true(initializer.field("text") is Some(Text(Some("&amp;"))))
  let raw_children = _parser_node_field_list(raw, "children").unwrap()
  assert_true(
    raw_children.get(0).unwrap().field("text")
    is Some(Text(Some("&amp; &bogus;"))),
  )
  assert_eq(_diagnostic_shape(raw_diagnostics), "")
  assert_eq(raw_token.to_int(), 1)

  let (_, scanner_diagnostics, scanner_token, _) = _parse_expression_for_test(
    "<div>&amp; &bogus; # } ></div>",
    script_kind=ScriptKind::tsx(),
  )
  assert_eq(
    _diagnostic_shape(scanner_diagnostics),
    "1381@21:1,1382@23:1,1381@21:1,1382@23:1",
  )
  assert_eq(scanner_token.to_int(), 1)
}

///|
test "TSX generic arrow JSX and type argument ambiguity match TypeScript" {
  let fixtures = [
    (
      "<T,>(x:T)=>x", "N220@0:12,A@1:3:1,N169@1:2,N80@1:2,A@5:8:0,N170@5:8,N80@5:6,N184@7:8,N80@7:8,N39@9:11,N80@11:12",
    ),
    (
      "<T extends U>(x:T)=>x", "N220@0:21,A@1:12:0,N169@1:12,N80@1:2,N184@10:12,N80@10:12,A@14:17:0,N170@14:17,N80@14:15,N184@16:17,N80@16:17,N39@18:20,N80@20:21",
    ),
    (
      "<const T,>(x:T)=>x", "N220@0:18,A@1:9:1,N169@1:8,A@1:6:0,N87@1:6,N80@6:8,A@11:14:0,N170@11:14,N80@11:12,N184@13:14,N80@13:14,N39@15:17,N80@17:18",
    ),
    (
      "<T = U>(x:T)=>x", "N220@0:15,A@1:6:0,N169@1:6,N80@1:2,N184@4:6,N80@4:6,A@8:11:0,N170@8:11,N80@8:9,N184@10:11,N80@10:11,N39@12:14,N80@14:15",
    ),
    ("f<T>(x)", "N214@0:7,N80@0:1,A@2:3:0,N184@2:3,N80@2:3,A@5:6:0,N80@5:6"),
    (
      "<T extends={x}></T>", "N285@0:19,N287@0:15,N80@1:2,N293@2:14,A@2:14:0,N292@2:14,N80@2:10,N295@11:14,N80@12:13,A@15:15:0,N288@15:19,N80@17:18",
    ),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (node, diagnostics, token, _) = _parse_expression_for_test(
      source,
      script_kind=ScriptKind::tsx(),
    )
    assert_eq(_node_array_shape(node), expected)
    assert_eq(_diagnostic_shape(diagnostics), "", msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "JSX ScriptKind disables opening-element type arguments" {
  let (node, diagnostics, token) = _parse_first_jsx_expression(
    "<Comp<T> p />",
    ScriptKind::jsx(),
  )
  assert_eq(
    _node_array_shape(node),
    "N227@0:13,N286@0:5,N80@1:5,N293@5:5,A@5:5:0,N28@5:5,N285@5:13,N287@5:8,N80@6:7,N293@7:7,A@7:7:0,A@8:13:0,N12@8:13,N288@13:13,N80@13:13",
  )
  assert_eq(
    _diagnostic_shape(diagnostics),
    "1003@5:1,1382@12:1,17008@6:1,1005@13:0,2657@0:13",
  )
  assert_eq(token.to_int(), 1)

  let (arrow, arrow_diagnostics, arrow_token, _) = _parse_expression_for_test(
    "<T,>(x)=>x",
    script_kind=ScriptKind::jsx(),
  )
  assert_eq(arrow.kind().to_int(), 220)
  assert_eq(_diagnostic_shape(arrow_diagnostics), "")
  assert_eq(arrow_token.to_int(), 1)
}

///|
test "JSX malformed closing fragments unicode and attributes recover exactly" {
  let fixtures = [
    ("<></x>", "17015@4:1,1109@6:0"),
    ("<><x></>", "1003@7:1,17014@0:2,1005@8:0"),
    ("<div>", "17008@1:3,1005@5:0"),
    ("<>", "17014@0:2,1005@2:0"),
    ("<a\\u0062></ab>", "17021@1:7"),
    ("<ab></a\\u0062>", "17021@6:7"),
    ("<a x= y />", "1145@6:1"),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (_, diagnostics, token) = _parse_first_jsx_expression(
      source,
      ScriptKind::tsx(),
    )
    assert_eq(_diagnostic_shape(diagnostics), expected)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "JSX hash text remains text around nested elements" {
  for
    source in [
      "<a>#<i></i></a>", "<a>#<i>#</i></a>", "<a><i></i>#</a>", "<a>#<i></i>#</a>",
    ] {
    let (_, diagnostics, token, _) = _parse_expression_for_test(
      source,
      script_kind=ScriptKind::tsx(),
    )
    assert_eq(_diagnostic_shape(diagnostics), "", msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}
