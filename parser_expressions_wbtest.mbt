///|
fn _collect_node_kind_ranges(
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
      _collect_node_kind_ranges(child, base, result)
      None
    }),
  )
}

///|
fn _node_kind_range_shape(node : Node) -> String {
  let result : Array[String] = []
  _collect_node_kind_ranges(node, node.pos(), result)
  result.join(",")
}

///|
fn _collect_node_array_shape(
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
        _collect_node_array_shape(child, base, result)
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
          _collect_node_array_shape(child, base, result)
        }
        None
      },
    ),
  )
}

///|
fn _node_array_shape(node : Node) -> String {
  let result : Array[String] = []
  _collect_node_array_shape(node, node.pos(), result)
  result.join(",")
}

///|
test "expression grammar smoke matrix terminates and consumes input" {
  let fixtures = [
    ("a + b * c ** d - e", 227),
    ("a = b = c", 227),
    ("a ? b : c ? d : e", 228),
    ("a as T satisfies U", 239),
    ("<T>x!", 217),
    ("++a + b--", 227),
    ("delete x, typeof y, void z", 227),
    ("x => x + 1", 220),
    ("(x: T, y = 1): U => x", 220),
    ("async x => await x", 220),
    ("<T>(x:T)=>x", 220),
    ("() => ({x:1})", 220),
    ("() => { return 1; }", 220),
    ("[1,,...xs]", 210),
    ("{a, b:1, ...rest}", 211),
    ("function* f<T>(x:T):T { return x; }", 219),
    ("class C {}", 232),
    ("new Foo<T>(1).bar", 212),
    ("import.meta.url", 212),
    ("new.target", 237),
    ("/a+/gu.test(s)", 214),
    ("`a${x}b`", 229),
    ("obj?.foo?.[i]?.(x)!.bar", 212),
    ("f<T>(x)", 214),
  ]
  for fixture in fixtures {
    let (source, expected_kind) = fixture
    let (node, diagnostics, token, _) = _parse_expression_for_test(source)
    assert_eq(node.kind().to_int(), expected_kind, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
  }
}

///|
test "expression preorder kinds and UTF-16 ranges match TypeScript" {
  let fixtures = [
    (
      "a + b * c ** d - e", "227@0:18,227@0:14,80@0:1,40@1:3,227@3:14,80@3:5,42@5:7,227@7:14,80@7:9,43@9:12,80@12:14,41@14:16,80@16:18",
    ),
    ("a = b = c", "227@0:9,80@0:1,64@1:3,227@3:9,80@3:5,64@5:7,80@7:9"),
    (
      "a || b && c ?? d", "227@0:16,227@0:11,80@0:1,57@1:4,227@4:11,80@4:6,56@6:9,80@9:11,61@11:14,80@14:16",
    ),
    ("f < T > x", "227@0:9,227@0:5,80@0:1,30@1:3,80@3:5,32@5:7,80@7:9"),
    ("f<T> + x", "227@0:8,227@0:3,80@0:1,30@1:2,80@2:3,32@3:4,225@4:8,80@6:8"),
    (
      "a ? b : c ? d : e", "228@0:17,80@0:1,58@1:3,80@3:5,59@5:7,228@7:17,80@7:9,58@9:11,80@11:13,59@13:15,80@15:17",
    ),
    (
      "a as T satisfies U", "239@0:18,235@0:6,80@0:1,184@4:6,80@4:6,184@16:18,80@16:18",
    ),
    ("<T>x!", "217@0:5,184@1:2,80@1:2,236@3:5,80@3:4"),
    ("++a + b--", "227@0:9,225@0:3,80@2:3,40@3:5,226@5:9,80@5:7"),
    (
      "delete x, typeof y, void z", "227@0:26,227@0:18,221@0:8,80@6:8,28@8:9,222@9:18,80@16:18,28@18:19,223@19:26,80@24:26",
    ),
    (
      "x => x + 1", "220@0:10,170@0:1,80@0:1,39@1:4,227@4:10,80@4:6,40@6:8,9@8:10",
    ),
    (
      "(x: T, y = 1): U => x", "220@0:21,170@1:5,80@1:2,184@3:5,80@3:5,170@6:12,80@6:8,9@10:12,184@14:16,80@14:16,39@16:19,80@19:21",
    ),
    (
      "async x => await x", "220@0:18,134@0:5,170@5:7,80@5:7,39@7:10,224@10:18,80@16:18",
    ),
    (
      "<T>(x:T)=>x", "220@0:11,169@1:2,80@1:2,170@4:7,80@4:5,184@6:7,80@6:7,39@8:10,80@10:11",
    ),
    (
      "async<T>(x:T)=>x", "220@0:16,134@0:5,169@6:7,80@6:7,170@9:12,80@9:10,184@11:12,80@11:12,39@13:15,80@15:16",
    ),
    (
      "() => ({x:1})", "220@0:13,39@2:5,218@5:13,211@7:12,304@8:11,80@8:9,9@10:11",
    ),
    ("() => { return 1; }", "220@0:19,39@2:5,242@5:19,254@7:17,9@14:16"),
    ("[1,,...xs]", "210@0:10,9@1:2,233@3:3,231@4:9,80@7:9"),
    (
      "{a, b:1, ...rest}", "211@0:17,305@1:2,80@1:2,304@3:7,80@3:5,9@6:7,306@8:16,80@12:16",
    ),
    (
      "function* f<T>(x:T):T { return x; }", "219@0:35,42@8:9,80@9:11,169@12:13,80@12:13,170@15:18,80@15:16,184@17:18,80@17:18,184@20:21,80@20:21,242@21:35,254@23:33,80@30:32",
    ),
    ("class C {}", "232@0:10,80@5:7"),
    (
      "new Foo<T>(1).bar", "212@0:17,215@0:13,80@3:7,184@8:9,80@8:9,9@11:12,80@14:17",
    ),
    ("import.meta.url", "212@0:15,237@0:11,80@7:11,80@12:15"),
    ("new.target", "237@0:10,80@4:10"),
    ("/a+/gu.test(s)", "214@0:14,212@0:11,14@0:6,80@7:11,80@12:13"),
    (
      "/a/.test(x) / 2", "227@0:15,214@0:11,212@0:8,14@0:3,80@4:8,80@9:10,44@11:13,9@13:15",
    ),
    (
      "a / /b/.test(x)", "227@0:15,80@0:1,44@1:3,214@3:15,212@3:12,14@3:7,80@8:12,80@13:14",
    ),
    ("`a${x}b`", "229@0:8,16@0:4,240@4:8,80@4:5,18@5:8"),
    (
      "obj?.foo?.[i]?.(x)!.bar", "212@0:23,236@0:19,214@0:18,213@0:13,212@0:8,80@0:3,29@3:5,80@5:8,29@8:10,80@11:12,29@13:15,80@16:17,80@20:23",
    ),
    ("f<T>(x)", "214@0:7,80@0:1,184@2:3,80@2:3,80@5:6"),
    (
      "tag<T>`a${x}b`", "216@0:14,80@0:3,184@4:5,80@4:5,229@6:14,16@6:10,240@10:14,80@10:11,18@11:14",
    ),
    ("tag?.`x`", "216@0:8,80@0:3,29@3:5,15@5:8"),
    ("f<T>", "234@0:4,80@0:1,184@2:3,80@2:3"),
    ("f<T>?.(x)", "214@0:9,234@0:4,80@0:1,184@2:3,80@2:3,29@4:6,80@7:8"),
    ("f<T>`x`", "216@0:7,80@0:1,184@2:3,80@2:3,15@4:7"),
    (
      "a?.b.c?.[d]?.(e)", "214@0:16,213@0:11,212@0:6,212@0:4,80@0:1,29@1:3,80@3:4,80@5:6,29@6:8,80@9:10,29@11:13,80@14:15",
    ),
    (
      "a ? `x${b}` : tag`y`", "228@0:20,80@0:1,58@1:3,229@3:11,16@3:8,240@8:11,80@8:9,18@9:11,59@11:13,216@13:20,80@13:17,15@17:20",
    ),
    ("obj.#field", "212@0:10,80@0:3,81@4:10"),
    (
      "{ async *[key]<T>(x:T):T { return x; }, get value(): T { return x; }, set value(v:T) {}, shorthand = 1, [\"p\"]: 2 }",
      "211@0:114,175@1:38,134@1:7,42@7:9,168@9:14,80@10:13,169@15:16,80@15:16,170@18:21,80@18:19,184@20:21,80@20:21,184@23:24,80@23:24,242@24:38,254@26:36,80@33:35,178@39:68,80@43:49,184@52:54,80@52:54,242@54:68,254@56:66,80@63:65,179@69:87,80@73:79,170@80:83,80@80:81,184@82:83,80@82:83,242@84:87,305@88:102,80@88:98,64@98:100,9@100:102,304@103:112,168@103:109,11@105:108,9@110:112",
    ),
    (
      "class C<T> extends B<T> { x:T=1; m<U>(u:U):U{return u;} }", "232@0:57,80@5:7,169@8:9,80@8:9,299@10:23,234@18:23,80@18:20,184@21:22,80@21:22,173@25:32,80@25:27,184@28:29,80@28:29,9@30:31,175@32:55,80@32:34,169@35:36,80@35:36,170@38:41,80@38:39,184@40:41,80@40:41,184@43:44,80@43:44,242@44:55,254@45:54,80@51:53",
    ),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (node, diagnostics, token, _) = _parse_expression_for_test(source)
    assert_eq(_node_kind_range_shape(node), expected, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "expression NodeArray ranges order and trailing commas match TypeScript" {
  let fixtures = [
    (
      "(x: T, y = 1): U => x", "N220@0:21,A@1:12:0,N170@1:5,N80@1:2,N184@3:5,N80@3:5,N170@6:12,N80@6:8,N9@10:12,N184@14:16,N80@14:16,N39@16:19,N80@19:21",
    ),
    (
      "<T>(x:T)=>x", "N220@0:11,A@1:2:0,N169@1:2,N80@1:2,A@4:7:0,N170@4:7,N80@4:5,N184@6:7,N80@6:7,N39@8:10,N80@10:11",
    ),
    (
      "() => { return 1; }", "N220@0:19,A@1:1:0,N39@2:5,N242@5:19,A@7:17:0,N254@7:17,N9@14:16",
    ),
    ("[1,,...xs]", "N210@0:10,A@1:9:0,N9@1:2,N233@3:3,N231@4:9,N80@7:9"),
    (
      "{a, b:1, ...rest}", "N211@0:17,A@1:16:0,N305@1:2,N80@1:2,N304@3:7,N80@3:5,N9@6:7,N306@8:16,N80@12:16",
    ),
    (
      "function* f<T>(x:T):T { return x; }", "N219@0:35,N42@8:9,N80@9:11,A@12:13:0,N169@12:13,N80@12:13,A@15:18:0,N170@15:18,N80@15:16,N184@17:18,N80@17:18,N184@20:21,N80@20:21,N242@21:35,A@23:33:0,N254@23:33,N80@30:32",
    ),
    ("class C {}", "N232@0:10,N80@5:7,A@9:9:0"),
    (
      "new Foo<T>(1).bar", "N212@0:17,N215@0:13,N80@3:7,A@8:9:0,N184@8:9,N80@8:9,A@11:12:0,N9@11:12,N80@14:17",
    ),
    (
      "obj?.foo?.[i]?.(x)!.bar", "N212@0:23,N236@0:19,N214@0:18,N213@0:13,N212@0:8,N80@0:3,N29@3:5,N80@5:8,N29@8:10,N80@11:12,N29@13:15,A@16:17:0,N80@16:17,N80@20:23",
    ),
    ("f<T>(x)", "N214@0:7,N80@0:1,A@2:3:0,N184@2:3,N80@2:3,A@5:6:0,N80@5:6"),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (node, diagnostics, token, _) = _parse_expression_for_test(source)
    assert_eq(_node_array_shape(node), expected, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "await yield and parser-only expression diagnostics" {
  let (await_node, await_errors, await_token, _) = _parse_expression_for_test(
    "await x",
    context_flags=NodeFlags::await_context(),
  )
  assert_eq(await_node.kind().to_int(), 224)
  assert_eq(_node_kind_range_shape(await_node), "224@0:7,80@5:7")
  assert_eq(await_errors.length(), 0)
  assert_eq(await_token.to_int(), 1)

  let (yield_node, yield_errors, yield_token, _) = _parse_expression_for_test(
    "yield* x",
    context_flags=NodeFlags::yield_context(),
  )
  assert_eq(yield_node.kind().to_int(), 230)
  assert_eq(_node_kind_range_shape(yield_node), "230@0:8,42@5:6,80@6:8")
  assert_eq(yield_errors.length(), 0)
  assert_eq(yield_token.to_int(), 1)

  let (_, unary_errors, unary_token, _) = _parse_expression_for_test("-a ** b")
  assert_eq(unary_errors.length(), 1)
  assert_eq(unary_errors[0].code(), 17006)
  assert_eq(unary_errors[0].start(), Some(0))
  assert_eq(unary_errors[0].length(), Some(2))
  assert_eq(unary_token.to_int(), 1)

  let (_, assertion_errors, assertion_token, _) = _parse_expression_for_test(
    "<T>a ** b",
  )
  assert_eq(assertion_errors.length(), 1)
  assert_eq(assertion_errors[0].code(), 17007)
  assert_eq(assertion_errors[0].start(), Some(0))
  assert_eq(assertion_errors[0].length(), Some(4))
  assert_eq(assertion_token.to_int(), 1)

  let (_, private_errors, private_token, _) = _parse_expression_for_test(
    "obj?.#field",
  )
  assert_eq(private_errors.length(), 1)
  assert_eq(private_errors[0].code(), 18030)
  assert_eq(private_errors[0].start(), Some(5))
  assert_eq(private_errors[0].length(), Some(6))
  assert_eq(private_token.to_int(), 1)
}

///|
fn _assert_binary_operator(source : String, expected : Int) -> Unit raise {
  let (node, diagnostics, token, _) = _parse_expression_for_test(source)
  assert_eq(node.kind().to_int(), 227, msg=source)
  match _parser_node_field_node(node, "operatorToken") {
    Some(operator) => assert_eq(operator.kind().to_int(), expected, msg=source)
    None => abort("missing operatorToken for " + source)
  }
  assert_eq(diagnostics.length(), 0, msg=source)
  assert_eq(token.to_int(), 1, msg=source)
}

///|
test "binary and assignment operator matrix matches scanner kinds" {
  let binary_operators = [
    ("??", 61),
    ("||", 57),
    ("&&", 56),
    ("|", 52),
    ("^", 53),
    ("&", 51),
    ("==", 35),
    ("!=", 36),
    ("===", 37),
    ("!==", 38),
    ("<", 30),
    (">", 32),
    ("<=", 33),
    (">=", 34),
    ("instanceof", 104),
    ("in", 103),
    ("<<", 48),
    (">>", 49),
    (">>>", 50),
    ("+", 40),
    ("-", 41),
    ("*", 42),
    ("/", 44),
    ("%", 45),
    ("**", 43),
  ]
  for fixture in binary_operators {
    let (spelling, expected) = fixture
    _assert_binary_operator("a " + spelling + " b", expected)
  }
  let assignment_operators = [
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
  for fixture in assignment_operators {
    let (spelling, expected) = fixture
    _assert_binary_operator("a " + spelling + " b", expected)
  }
  let (as_node, as_errors, as_token, _) = _parse_expression_for_test("a as T")
  assert_eq(as_node.kind().to_int(), 235)
  assert_eq(as_errors.length(), 0)
  assert_eq(as_token.to_int(), 1)
  let (satisfies_node, satisfies_errors, satisfies_token, _) = _parse_expression_for_test(
    "a satisfies T",
  )
  assert_eq(satisfies_node.kind().to_int(), 239)
  assert_eq(satisfies_errors.length(), 0)
  assert_eq(satisfies_token.to_int(), 1)
}

///|
test "unary operators and disallow-in context preserve parser state" {
  let unary_operators = [
    ("+x", 40, 225),
    ("-x", 41, 225),
    ("!x", 54, 225),
    ("~x", 55, 225),
    ("++x", 46, 225),
    ("--x", 47, 225),
    ("x++", 46, 226),
    ("x--", 47, 226),
  ]
  for fixture in unary_operators {
    let (source, expected_operator, expected_kind) = fixture
    let (node, diagnostics, token, _) = _parse_expression_for_test(source)
    assert_eq(node.kind().to_int(), expected_kind, msg=source)
    match node.field("operator") {
      Some(Kind(Some(operator))) =>
        assert_eq(operator.to_int(), expected_operator, msg=source)
      _ => abort("missing unary operator for " + source)
    }
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
  let (node, diagnostics, token, _) = _parse_expression_for_test(
    "a in b",
    context_flags=NodeFlags::disallow_in_context(),
  )
  assert_eq(node.kind().to_int(), 80)
  assert_eq(node.pos(), 0)
  assert_eq(node.end(), 1)
  assert_eq(diagnostics.length(), 0)
  assert_eq(token.to_int(), 103)
}

///|
test "source and optional-chain flags propagate through expressions" {
  let (dynamic, dynamic_errors, dynamic_token, dynamic_flags) = _parse_expression_for_test(
    "import(\"x\")",
  )
  assert_eq(dynamic.kind().to_int(), 214)
  assert_eq(dynamic_errors.length(), 0)
  assert_eq(dynamic_token.to_int(), 1)
  assert_true(
    dynamic_flags.contains(NodeFlags::possibly_contains_dynamic_import()),
  )
  let (defer_node, defer_errors, defer_token, defer_flags) = _parse_expression_for_test(
    "import.defer(\"x\")",
  )
  assert_eq(defer_node.kind().to_int(), 214)
  assert_eq(defer_errors.length(), 0)
  assert_eq(defer_token.to_int(), 1)
  assert_true(
    defer_flags.contains(NodeFlags::possibly_contains_dynamic_import()),
  )
  let (meta, meta_errors, meta_token, meta_flags) = _parse_expression_for_test(
    "import.meta",
  )
  assert_eq(meta.kind().to_int(), 237)
  assert_eq(meta_errors.length(), 0)
  assert_eq(meta_token.to_int(), 1)
  assert_true(meta_flags.contains(NodeFlags::possibly_contains_import_meta()))
  for source in ["obj?.foo.bar", "obj?.foo?.[i]?.(x)!.bar", "tag?.`x`"] {
    let (node, diagnostics, token, _) = _parse_expression_for_test(source)
    assert_true(node.flags().contains(NodeFlags::optional_chain()), msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "failed parenthesized-arrow speculation is cached" {
  for source in ["(x)", "(x, y)"] {
    let state = _new_parser_state("expression.ts", source)
    ignore(state._prime())
    let node = state._parse_expression()
    assert_eq(node.kind().to_int(), 218, msg=source)
    assert_eq(state.current_token.to_int(), 1, msg=source)
    assert_eq(state.diagnostics.length(), 0, msg=source)
    assert_true(state._is_not_parenthesized_arrow(0), msg=source)
    state._dispose()
  }
}

///|
test "malformed member and new expressions recover with exact diagnostics" {
  let fixtures = [
    ("new Foo?.()", 1209, 7, 2),
    ("a[]", 1011, 2, 0),
    ("super", 1034, 5, 0),
    ("f<T>.x", 1477, 1, 3),
  ]
  for fixture in fixtures {
    let (source, code, start, length) = fixture
    let (_, diagnostics, token, _) = _parse_expression_for_test(source)
    assert_eq(diagnostics.length(), 1, msg=source)
    assert_eq(diagnostics[0].code(), code, msg=source)
    assert_eq(diagnostics[0].start(), Some(start), msg=source)
    assert_eq(diagnostics[0].length(), Some(length), msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "object recovery does not consume const as a modifier" {
  let (parenthesized, diagnostics, token, _) = _parse_expression_for_test(
    "({ const t2 = value })",
  )
  let object = _parser_node_field_node(parenthesized, "expression").unwrap()
  let properties = _parser_node_field_list(object, "properties").unwrap()
  let property = properties.get(0).unwrap()
  assert_eq(property.kind().to_int(), 304)
  assert_true(property.field("modifiers") is Some(NodeList(None)))
  assert_eq(_diagnostic_shape(diagnostics), "1005@9:2")
  assert_eq(token.to_int(), 1)
}

///|
test "arrow recovery treats a following statement as a missing block" {
  let (arrow, diagnostics, token, _) = _parse_expression_for_test(
    "() => var k = 10;}",
  )
  assert_eq(arrow.kind().to_int(), 220)
  assert_eq(
    _parser_node_field_node(arrow, "body").unwrap().kind().to_int(),
    242,
  )
  assert_eq(_diagnostic_shape(diagnostics), "1005@6:3")
  assert_eq(token.to_int(), 1)
}

///|
test "object method recovery expects a block before an arrow" {
  let (_, diagnostics, token, _) = _parse_statements_for_test(
    "let o = { m(n: number) => string { return n; } };",
  )
  assert_eq(_diagnostic_shape(diagnostics), "1005@23:2,1434@26:6,1128@47:1")
  assert_eq(token.to_int(), 1)
}
