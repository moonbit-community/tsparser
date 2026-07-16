///|
fn _collect_type_kinds(node : Node, kinds : Array[Int]) -> Unit {
  kinds.push(node.kind().to_int())
  ignore(
    for_each_child(node, fn(child) -> Unit? {
      _collect_type_kinds(child, kinds)
      None
    }),
  )
}

///|
fn _collect_type_kind_ranges(
  node : Node,
  base : Int,
  result : Array[String],
) -> Unit {
  result.push(
    node.kind().to_int().to_string() +
    "@" +
    (node.pos() - base).to_string() +
    ":" +
    (node.end() - base).to_string(),
  )
  ignore(
    for_each_child(node, fn(child) -> Unit? {
      _collect_type_kind_ranges(child, base, result)
      None
    }),
  )
}

///|
fn _type_kind_range_shape(node : Node) -> String {
  let result : Array[String] = []
  _collect_type_kind_ranges(node, node.pos(), result)
  result.join(",")
}

///|
fn _collect_type_array_shape(
  node : Node,
  base : Int,
  result : Array[String],
) -> Unit {
  result.push(
    "N" +
    node.kind().to_int().to_string() +
    "@" +
    (node.pos() - base).to_string() +
    ":" +
    (node.end() - base).to_string(),
  )
  ignore(
    for_each_child(
      node,
      fn(child) -> Unit? {
        _collect_type_array_shape(child, base, result)
        None
      },
      list_callback=fn(array) -> Unit? {
        result.push(
          "A@" +
          (array.pos() - base).to_string() +
          ":" +
          (array.end() - base).to_string() +
          ":" +
          (if array.has_trailing_comma() { "1" } else { "0" }),
        )
        for child in array.elements() {
          _collect_type_array_shape(child, base, result)
        }
        None
      },
    ),
  )
}

///|
fn _type_array_shape(node : Node) -> String {
  let result : Array[String] = []
  _collect_type_array_shape(node, node.pos(), result)
  result.join(",")
}

///|
fn _assert_type_node(
  source : String,
  root_kind : Int,
  required_kinds : Array[Int],
) -> Unit raise {
  let (node, diagnostics, token) = _parse_type_for_test(source)
  assert_eq(node.kind().to_int(), root_kind, msg=source)
  assert_eq(token.to_int(), 1, msg="type did not consume input: " + source)
  assert_eq(diagnostics.length(), 0, msg="unexpected diagnostic: " + source)
  let kinds : Array[Int] = []
  _collect_type_kinds(node, kinds)
  for required in required_kinds {
    let mut found = false
    for actual in kinds {
      if actual == required {
        found = true
        break
      }
    }
    assert_true(
      found,
      msg="missing kind " + required.to_string() + " in " + source,
    )
  }
}

///|
test "creates every TypeScript type-node family" {
  let fixtures = [
    ("T", 184, [80]),
    ("A.B<C>", 184, [167, 184]),
    ("this", 198, []),
    ("this is T", 183, [198, 184]),
    ("typeof A<B>", 187, [80, 184]),
    ("string", 154, []),
    ("\"x\"", 202, [11]),
    ("-1", 202, [225, 9]),
    ("(T)", 197, [184]),
    ("T[]", 189, [184]),
    ("T[K]", 200, [184]),
    ("keyof T", 199, [184]),
    ("infer T extends U", 196, [169, 184]),
    ("T & U | V", 193, [194, 184]),
    ("T extends U ? X : Y", 195, [184]),
    ("(x: T) => U", 185, [170, 184]),
    ("abstract new <T>(x: T) => U", 186, [128, 169, 170, 184]),
    ("[name?: T, ...rest: U[]]", 190, [203, 189]),
    ("[T?]", 190, [191, 184]),
    ("[...T]", 190, [192, 184]),
    ("{ readonly [K in keyof T as K]?: T[K] }", 201, [169, 199, 200]),
    ("{ p?: T; m<U>(x: U): U; [k: string]: number }", 188, [172, 174, 182]),
    ("import(\"pkg\").Type<T>", 206, [202, 80]),
    ("typeof import(\"pkg\")", 206, [202]),
    ("`head${T}tail`", 204, [205, 184]),
  ]
  let covered : Array[Int] = []
  for fixture in fixtures {
    let (source, root_kind, required_kinds) = fixture
    _assert_type_node(source, root_kind, required_kinds)
    let (node, _, _) = _parse_type_for_test(source)
    _collect_type_kinds(node, covered)
  }
  for kind = 183; kind <= 206; kind = kind + 1 {
    let mut found = false
    for actual in covered {
      if actual == kind {
        found = true
        break
      }
    }
    assert_true(found, msg="uncovered type SyntaxKind " + kind.to_string())
  }
}

///|
test "type preorder kinds and UTF-16 ranges match TypeScript" {
  let fixtures = [
    ("T", "184@0:1,80@0:1"),
    ("A.B<C>", "184@0:6,167@0:3,80@0:1,80@2:3,184@4:5,80@4:5"),
    ("this", "198@0:4"),
    ("this is T", "183@0:9,198@0:4,184@7:9,80@7:9"),
    ("typeof A<B>", "187@0:11,80@6:8,184@9:10,80@9:10"),
    ("string", "154@0:6"),
    ("\"x\"", "202@0:3,11@0:3"),
    ("-1", "202@0:2,225@0:2,9@1:2"),
    ("(T)", "197@0:3,184@1:2,80@1:2"),
    ("T[]", "189@0:3,184@0:1,80@0:1"),
    ("T[K]", "200@0:4,184@0:1,80@0:1,184@2:3,80@2:3"),
    ("keyof T", "199@0:7,184@5:7,80@5:7"),
    ("infer T extends U", "196@0:17,169@5:17,80@5:7,184@15:17,80@15:17"),
    (
      "T & U | V", "193@0:9,194@0:5,184@0:1,80@0:1,184@3:5,80@3:5,184@7:9,80@7:9",
    ),
    (
      "T extends U ? X : Y", "195@0:19,184@0:1,80@0:1,184@9:11,80@9:11,184@13:15,80@13:15,184@17:19,80@17:19",
    ),
    ("(x: T) => U", "185@0:11,170@1:5,80@1:2,184@3:5,80@3:5,184@9:11,80@9:11"),
    (
      "abstract new <T>(x: T) => U", "186@0:27,128@0:8,169@14:15,80@14:15,170@17:21,80@17:18,184@19:21,80@19:21,184@25:27,80@25:27",
    ),
    (
      "[name?: T, ...rest: U[]]", "190@0:24,203@1:9,80@1:5,58@5:6,184@7:9,80@7:9,203@10:23,26@10:14,80@14:18,189@19:23,184@19:21,80@19:21",
    ),
    ("[T?]", "190@0:4,191@1:3,184@1:2,80@1:2"),
    ("[...T]", "190@0:6,192@1:5,184@4:5,80@4:5"),
    (
      "{ readonly [K in keyof T as K]?: T[K] }", "201@0:39,148@1:10,169@12:24,80@12:13,199@16:24,184@22:24,80@22:24,184@27:29,80@27:29,58@30:31,200@32:37,184@32:34,80@32:34,184@35:36,80@35:36",
    ),
    (
      "{ p?: T; m<U>(x: U): U; [k: string]: number }", "188@0:45,172@1:8,80@1:3,58@3:4,184@5:7,80@5:7,174@8:23,80@8:10,169@11:12,80@11:12,170@14:18,80@14:15,184@16:18,80@16:18,184@20:22,80@20:22,182@23:43,170@25:34,80@25:26,154@27:34,150@36:43",
    ),
    (
      "import(\"pkg\").Type<T>", "206@0:21,202@7:12,11@7:12,80@14:18,184@19:20,80@19:20",
    ),
    ("typeof import(\"pkg\")", "206@0:20,202@14:19,11@14:19"),
    ("`head${T}tail`", "204@0:14,16@0:7,205@7:14,184@7:8,80@7:8,18@8:14"),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (node, diagnostics, token) = _parse_type_for_test(source)
    assert_eq(_type_kind_range_shape(node), expected, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "NodeArray ranges order and trailing commas match TypeScript" {
  let fixtures = [
    ("A.B<C>", "N184@0:6,N167@0:3,N80@0:1,N80@2:3,A@4:5:0,N184@4:5,N80@4:5"),
    (
      "(x: T) => U", "N185@0:11,A@1:5:0,N170@1:5,N80@1:2,N184@3:5,N80@3:5,N184@9:11,N80@9:11",
    ),
    (
      "abstract new <T>(x: T) => U", "N186@0:27,A@0:8:0,N128@0:8,A@14:15:0,N169@14:15,N80@14:15,A@17:21:0,N170@17:21,N80@17:18,N184@19:21,N80@19:21,N184@25:27,N80@25:27",
    ),
    (
      "[name?: T, ...rest: U[]]", "N190@0:24,A@1:23:0,N203@1:9,N80@1:5,N58@5:6,N184@7:9,N80@7:9,N203@10:23,N26@10:14,N80@14:18,N189@19:23,N184@19:21,N80@19:21",
    ),
    ("typeof A<B>", "N187@0:11,N80@6:8,A@9:10:0,N184@9:10,N80@9:10"),
    ("[T?]", "N190@0:4,A@1:3:0,N191@1:3,N184@1:2,N80@1:2"),
    ("[...T]", "N190@0:6,A@1:5:0,N192@1:5,N184@4:5,N80@4:5"),
    (
      "{ readonly [K in keyof T as K]?: T[K] }", "N201@0:39,N148@1:10,N169@12:24,N80@12:13,N199@16:24,N184@22:24,N80@22:24,N184@27:29,N80@27:29,N58@30:31,N200@32:37,N184@32:34,N80@32:34,N184@35:36,N80@35:36,A@37:37:0",
    ),
    (
      "{ p?: T; m<U>(x: U): U; [k: string]: number }", "N188@0:45,A@1:43:0,N172@1:8,N80@1:3,N58@3:4,N184@5:7,N80@5:7,N174@8:23,N80@8:10,A@11:12:0,N169@11:12,N80@11:12,A@14:18:0,N170@14:18,N80@14:15,N184@16:18,N80@16:18,N184@20:22,N80@20:22,N182@23:43,A@25:34:0,N170@25:34,N80@25:26,N154@27:34,N150@36:43",
    ),
    (
      "import(\"pkg\").Type<T>", "N206@0:21,N202@7:12,N11@7:12,N80@14:18,A@19:20:0,N184@19:20,N80@19:20",
    ),
    (
      "`head${T}tail`", "N204@0:14,N16@0:7,A@7:14:0,N205@7:14,N184@7:8,N80@7:8,N18@8:14",
    ),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (node, diagnostics, token) = _parse_type_for_test(source)
    assert_eq(_type_array_shape(node), expected, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "import type attributes preserve token shape and trailing comma" {
  let fixtures = [
    (
      "import(\"pkg\", { with: { type: \"json\", mode: \"strict\", }, }).Type", "N206@0:64,N202@7:12,N11@7:12,N301@21:55,A@23:53:1,N302@23:36,N80@23:28,N11@29:36,N302@37:52,N80@37:42,N11@43:52,N80@60:64",
    ),
    (
      "import(\"pkg\", { assert: { type: \"json\" } })", "N206@0:43,N202@7:12,N11@7:12,N301@23:40,A@25:38:0,N302@25:38,N80@25:30,N11@31:38",
    ),
    (
      "import(\"pkg\", { with: { \"resolution-mode\": \"import\" } })", "N206@0:56,N202@7:12,N11@7:12,N301@21:53,A@23:51:0,N302@23:51,N11@23:41,N11@42:51",
    ),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (node, diagnostics, token) = _parse_type_for_test(source)
    assert_eq(_type_array_shape(node), expected, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
    match node.field("attributes") {
      Some(NodeRef(Some(attributes))) =>
        assert_eq(attributes.kind().to_int(), 301)
      _ => fail("import type attributes missing")
    }
  }
}

///|
test "template expression raw cooked spans match TypeScript" {
  let state = _new_parser_state("template.ts", "`a${x}b${1}c`")
  ignore(state._prime())
  let expression = state._parse_template_expression_with(false, fn() {
    state._parse_expression()
  })
  assert_eq(expression.kind().to_int(), 229)
  assert_eq(
    _type_array_shape(expression),
    "N229@0:13,N16@0:4,A@4:13:0,N240@4:9,N80@4:5,N17@5:9,N240@9:13,N9@9:10,N18@10:13",
  )
  assert_eq(state.current_token.to_int(), 1)
  assert_eq(state.diagnostics.length(), 0)
  match expression.field("head") {
    Some(NodeRef(Some(head))) => {
      assert_true(head.field("text") is Some(Text(Some("a"))))
      assert_true(head.field("rawText") is Some(Text(Some("a"))))
    }
    _ => fail("template head missing")
  }
  state._dispose()

  let (type_node, type_errors, type_token) = _parse_type_for_test(
    "`\\x61${T}\\u0062`",
  )
  assert_eq(type_errors.length(), 0)
  assert_eq(type_token.to_int(), 1)
  match type_node.field("head") {
    Some(NodeRef(Some(head))) => {
      assert_true(head.field("text") is Some(Text(Some("a"))))
      assert_true(head.field("rawText") is Some(Text(Some("\\x61"))))
    }
    _ => fail("template type head missing")
  }
  match type_node.field("templateSpans") {
    Some(NodeList(Some(spans))) =>
      match spans.get(0) {
        Some(span) =>
          match span.field("literal") {
            Some(NodeRef(Some(literal))) => {
              assert_true(literal.field("text") is Some(Text(Some("b"))))
              assert_true(
                literal.field("rawText") is Some(Text(Some("\\u0062"))),
              )
            }
            _ => fail("template type tail missing")
          }
        None => fail("template type span missing")
      }
    _ => fail("template type spans missing")
  }
}

///|
test "parses predicates parameters and type-member signatures" {
  let predicate_state = _new_parser_state("predicate.ts", "asserts value is T")
  ignore(predicate_state._prime())
  let predicate = predicate_state._parse_type_or_type_predicate()
  assert_eq(predicate.kind().to_int(), 183)
  assert_eq(predicate_state.current_token.to_int(), 1)
  assert_eq(predicate_state.diagnostics.length(), 0)
  predicate_state._dispose()

  let state = _new_parser_state(
    "signature.ts", "<in T extends U = V>(this: C, value?: T, ...rest: U[]) => T",
  )
  ignore(state._prime())
  let type_node = state._parse_type()
  assert_eq(type_node.kind().to_int(), 185)
  assert_eq(state.current_token.to_int(), 1)
  assert_eq(state.diagnostics.length(), 0)
  match type_node.field("typeParameters") {
    Some(NodeList(Some(parameters))) => {
      assert_eq(parameters.length(), 1)
      match parameters.get(0) {
        Some(parameter) =>
          match parameter.field("modifiers") {
            Some(NodeList(Some(modifiers))) => assert_eq(modifiers.length(), 1)
            _ => fail("variance modifier list missing")
          }
        None => fail("type parameter missing")
      }
    }
    _ => fail("type parameter list missing")
  }
  match type_node.field("parameters") {
    Some(NodeList(Some(parameters))) => assert_eq(parameters.length(), 3)
    _ => fail("parameter list missing")
  }
  state._dispose()

  let (members, member_errors, member_token) = _parse_type_for_test(
    "{ <in out const T extends U = V>(this: C, x?: T, ...r: U[]): V; new <T>(x:T): U }",
  )
  assert_eq(
    _type_kind_range_shape(members),
    "188@0:81,180@1:63,169@3:31,103@3:5,147@5:9,87@9:15,80@15:17,184@25:27,80@25:27,184@29:31,80@29:31,170@33:40,80@33:37,184@38:40,80@38:40,170@41:47,80@41:43,58@43:44,184@45:47,80@45:47,170@48:58,26@48:52,80@52:53,189@54:58,184@54:56,80@54:56,184@60:62,80@60:62,181@63:79,169@69:70,80@69:70,170@72:75,80@72:73,184@74:75,80@74:75,184@77:79,80@77:79",
  )
  assert_eq(member_errors.length(), 0)
  assert_eq(member_token.to_int(), 1)
}

///|
test "ordinary literal parsing preserves scanner values and ranges" {
  let fixtures = [
    ("123", 9, "123"),
    ("12n", 10, "12n"),
    ("\"value\"", 11, "value"),
  ]
  for fixture in fixtures {
    let (source, kind, value) = fixture
    let state = _new_parser_state("literal.ts", source)
    ignore(state._prime())
    let literal = state._parse_literal_node()
    assert_eq(literal.kind().to_int(), kind, msg=source)
    assert_eq(literal.pos(), 0, msg=source)
    assert_eq(literal.end(), source.length(), msg=source)
    assert_true(
      literal.field("text") is Some(Text(Some(actual))) && actual == value,
    )
    assert_eq(state.current_token.to_int(), 1, msg=source)
    assert_eq(state.diagnostics.length(), 0, msg=source)
    state._dispose()
  }

  let regexp = _new_parser_state("literal.ts", "/a+/gu")
  ignore(regexp._prime())
  ignore(regexp._re_scan_slash_token())
  let literal = regexp._parse_literal_node()
  assert_eq(literal.kind().to_int(), 14)
  assert_eq(literal.pos(), 0)
  assert_eq(literal.end(), 6)
  assert_true(literal.field("text") is Some(Text(Some("/a+/gu"))))
  assert_eq(regexp.current_token.to_int(), 1)
  assert_eq(regexp.diagnostics.length(), 0)
  regexp._dispose()
}

///|
test "type recovery preserves parentheses comma and conditional diagnostics" {
  let (union_function, union_errors, _) = _parse_type_for_test(
    "T | (x: U) => V",
  )
  assert_eq(union_function.kind().to_int(), 193)
  assert_eq(union_errors[0].code(), 1385)
  assert_eq(union_errors[0].start(), Some(3))
  assert_eq(union_errors[0].length(), Some(12))

  let (intersection_constructor, intersection_errors, _) = _parse_type_for_test(
    "T & new () => U",
  )
  assert_eq(intersection_constructor.kind().to_int(), 194)
  assert_eq(intersection_errors[0].code(), 1388)
  assert_eq(intersection_errors[0].start(), Some(3))
  assert_eq(intersection_errors[0].length(), Some(12))

  let (missing, missing_errors, token) = _parse_type_for_test("T extends U X Y")
  assert_eq(missing.kind().to_int(), 195)
  assert_eq(token.to_int(), 1)
  assert_true(missing_errors.length() >= 2)
  assert_eq(missing_errors[0].code(), 1005)
  assert_eq(missing_errors[0].start(), Some(12))
  assert_eq(missing_errors[0].length(), Some(1))
  assert_eq(missing_errors[1].code(), 1005)
  assert_eq(missing_errors[1].start(), Some(14))
  assert_eq(missing_errors[1].length(), Some(1))
}

///|
test "type parameter expression and missing bracket recovery match TypeScript" {
  let (expression_constraint, expression_errors, expression_token) = _parse_type_for_test(
    "<T extends -x>(a:T)=>T",
  )
  assert_eq(
    _type_kind_range_shape(expression_constraint),
    "185@0:22,169@1:13,80@1:2,225@10:13,80@12:13,170@15:18,80@15:16,184@17:18,80@17:18,184@21:22,80@21:22",
  )
  assert_eq(expression_errors.length(), 0)
  assert_eq(expression_token.to_int(), 1)
  match expression_constraint.field("typeParameters") {
    Some(NodeList(Some(parameters))) =>
      match parameters.get(0) {
        Some(parameter) => {
          assert_true(parameter.field("constraint") is Some(NodeRef(None)))
          assert_true(parameter.field("expression") is Some(NodeRef(Some(_))))
        }
        None => fail("recovered type parameter missing")
      }
    _ => fail("recovered type parameter list missing")
  }

  let (missing_bracket, missing_errors, missing_token) = _parse_type_for_test(
    "<T(a:T)=>T",
  )
  assert_eq(
    _type_kind_range_shape(missing_bracket),
    "185@0:10,169@1:2,80@1:2,170@3:6,80@3:4,184@5:6,80@5:6,184@9:10,80@9:10",
  )
  assert_eq(missing_errors.length(), 1)
  assert_eq(missing_errors[0].code(), 1005)
  assert_eq(missing_errors[0].start(), Some(2))
  assert_eq(missing_errors[0].length(), Some(1))
  assert_eq(missing_token.to_int(), 1)
}

///|
test "names mapped modifiers tuple ambiguity and precedence match TypeScript" {
  let fixtures = [
    ("A.\\u0062", "184@0:8,167@0:8,80@0:1,80@2:8", 0),
    (
      "{ #p: T; [key]: U; \"s\": V; 1: W; 2n: X }", "188@0:40,172@1:8,81@1:4,184@5:7,80@5:7,172@8:18,168@8:14,80@10:13,184@15:17,80@15:17,172@18:26,11@18:22,184@23:25,80@23:25,172@26:32,9@26:28,184@29:31,80@29:31,172@32:38,10@32:35,184@36:38,80@36:38",
      0,
    ),
    (
      "{ +readonly [K in keyof T as K]-?: T[K]; extra: U }", "201@0:51,40@1:3,169@13:25,80@13:14,199@17:25,184@23:25,80@23:25,184@28:30,80@28:30,41@31:32,200@34:39,184@34:36,80@34:36,184@37:38,80@37:38,172@40:49,80@40:46,184@47:49,80@47:49",
      0,
    ),
    (
      "[T?, ...U, V]", "190@0:13,191@1:3,184@1:2,80@1:2,192@4:9,184@8:9,80@8:9,184@10:12,80@10:12",
      0,
    ),
    (
      "A | B & C", "193@0:9,184@0:1,80@0:1,194@3:9,184@3:5,80@3:5,184@7:9,80@7:9",
      0,
    ),
    (
      "A extends B ? C : D extends E ? F : G", "195@0:37,184@0:1,80@0:1,184@9:11,80@9:11,184@13:15,80@13:15,195@17:37,184@17:19,80@17:19,184@27:29,80@27:29,184@31:33,80@31:33,184@35:37,80@35:37",
      0,
    ),
    (
      "infer T extends U ? X : Y", "195@0:25,196@0:7,169@5:7,80@5:7,184@15:17,80@15:17,184@19:21,80@19:21,184@23:25,80@23:25",
      0,
    ),
    (
      "T | new () => U", "193@0:15,184@0:1,80@0:1,186@3:15,184@13:15,80@13:15", 1386,
    ),
    (
      "T & (x: U) => V", "194@0:15,184@0:1,80@0:1,185@3:15,170@5:9,80@5:6,184@7:9,80@7:9,184@13:15,80@13:15",
      1387,
    ),
    (
      "T | (() => U)", "193@0:13,184@0:1,80@0:1,197@3:13,185@5:12,184@10:12,80@10:12",
      0,
    ),
  ]
  for fixture in fixtures {
    let (source, expected, diagnostic_code) = fixture
    let (node, diagnostics, token) = _parse_type_for_test(source)
    assert_eq(_type_kind_range_shape(node), expected, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
    if diagnostic_code == 0 {
      assert_eq(diagnostics.length(), 0, msg=source)
    } else {
      assert_eq(diagnostics.length(), 1, msg=source)
      assert_eq(diagnostics[0].code(), diagnostic_code, msg=source)
      assert_eq(diagnostics[0].start(), Some(3), msg=source)
      assert_eq(diagnostics[0].length(), Some(12), msg=source)
    }
  }
}

///|
test "function type lookahead accepts binding-pattern parameters" {
  for
    source in [
      "({ key }: { key: string }) => void", "([first]: [string]) => void",
    ] {
    let (node, diagnostics, token) = _parse_type_for_test(source)
    assert_eq(node.kind().to_int(), 185, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
    match node.field("parameters") {
      Some(NodeList(Some(parameters))) => assert_eq(parameters.length(), 1)
      _ => fail("function type parameter list is missing")
    }
  }
}
