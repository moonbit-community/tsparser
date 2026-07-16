///|
fn _validate_node_array(
  array : NodeArray,
  parent : Node,
  source_length : Int,
) -> Unit raise {
  assert_true(array.pos() >= 0)
  assert_true(array.pos() <= array.end())
  assert_true(array.end() <= source_length)
  assert_true(array.pos() >= parent.pos())
  assert_true(array.end() <= parent.end())
  assert_eq(
    array.transform_flags(),
    _aggregate_children_flags(array.elements()),
  )
  let mut previous_pos = array.pos()
  for element in array.elements() {
    assert_true(element.pos() >= array.pos())
    assert_true(element.end() <= array.end())
    assert_true(element.pos() >= previous_pos)
    previous_pos = element.pos()
  }
}

///|
fn _tree_invariant_projection(
  root : Node,
  source_length : Int,
) -> (Array[String], Int) raise {
  let projection : Array[String] = []
  let stack : Array[Node] = [root]
  let mut trailing_comma_lists = 0
  while !stack.is_empty() {
    let node = stack.pop().unwrap()
    assert_true(node.pos() >= 0)
    assert_true(node.pos() <= node.end())
    assert_true(node.end() <= source_length)
    projection.push(
      node.kind().to_int().to_string() +
      "@" +
      node.pos().to_string() +
      ":" +
      node.end().to_string(),
    )
    for field in node.fields() {
      match field.value() {
        NodeList(Some(array)) => {
          _validate_node_array(array, node, source_length)
          if array.has_trailing_comma() {
            trailing_comma_lists += 1
          }
        }
        _ => ()
      }
    }
    let children : Array[Node] = []
    ignore(
      for_each_child(
        node,
        fn(child) -> Unit? {
          children.push(child)
          None
        },
        list_callback=fn(array) -> Unit? {
          for child in array.elements() {
            children.push(child)
          }
          None
        },
      ),
    )
    match node.jsdoc() {
      Some(array) => {
        _validate_node_array(array, node, source_length)
        for child in array.elements() {
          children.push(child)
        }
      }
      None => ()
    }
    for child in children {
      assert_true(child.pos() >= node.pos())
      assert_true(child.end() <= node.end())
    }
    for index = children.length() - 1; index >= 0; index = index - 1 {
      stack.push(children[index])
    }
  }
  (projection, trailing_comma_lists)
}

///|
fn _apply_source_mutation(
  source : String,
  position : Int,
  width : Int,
  replacement : String,
) -> String raise {
  assert_true(position >= 0)
  assert_true(width >= 0)
  assert_true(position + width <= source.length())
  source.unsafe_substring(start=0, end=position) +
  replacement +
  source.unsafe_substring(start=position + width, end=source.length())
}

///|
test "fixed malformed corpus preserves reference diagnostic order and ranges" {
  let fixtures = [
    ("function f( {", ScriptKind::ts(), "1005@13:0"),
    ("const x = \"unterminated", ScriptKind::ts(), "1002@23:0"),
    ("const x = `a${b", ScriptKind::ts(), "1005@15:0"),
    ("/* unterminated", ScriptKind::ts(), "1010@15:0"),
    ("<div>{x</span>", ScriptKind::tsx(), "1005@7:2,17002@9:4"),
    ("type T = { [K in keyof U: U[K]", ScriptKind::ts(), "1005@24:1,1005@30:0"),
    ("const r = /[a-/v;", ScriptKind::ts(), "1161@10:6"),
    ("class C { @dec public }", ScriptKind::ts(), ""),
    ("export default @dec class {", ScriptKind::ts(), "1005@27:0"),
    ("async function f(){ await using x = ; }", ScriptKind::ts(), "1109@36:1"),
  ]
  for fixture in fixtures {
    let (source, script_kind, expected_diagnostics) = fixture
    let suffix = if script_kind == ScriptKind::tsx() { ".tsx" } else { ".ts" }
    let first = create_source_file("malformed" + suffix, source, script_kind~)
    let second = create_source_file("malformed" + suffix, source, script_kind~)
    assert_eq(
      _source_file_diagnostic_projection(first).join(","),
      expected_diagnostics,
      msg=source,
    )
    assert_eq(
      _source_file_diagnostic_projection(second),
      _source_file_diagnostic_projection(first),
      msg=source,
    )
    let (first_projection, _) = _tree_invariant_projection(
      first,
      source.length(),
    )
    let (second_projection, _) = _tree_invariant_projection(
      second,
      source.length(),
    )
    assert_eq(second_projection, first_projection, msg=source)
  }
}

///|
test "deterministic mutations match TypeScript diagnostics and invariants" {
  let source = "class C<T> { method(x: T) { return <T>x; } }\nconst value = new C<number>().method(1);"
  let mutations = [
    (7, 1, "", "1005@8:1"),
    (9, 1, "]", "1005@9:1,1005@11:1"),
    (11, 1, "", "1005@12:6,1005@20:1,1005@25:1,1128@42:1"),
    (19, 1, "", "1442@23:1,1068@25:1,1128@42:1"),
    (21, 1, "", "1005@22:1"),
    (24, 1, "{", "1005@24:1,1180@26:1,1005@35:1,1005@37:1,1128@41:1,1128@43:1"),
    (26, 1, "", "1144@27:6,1005@37:1,1128@42:1"),
    (35, 1, "", ""),
    (37, 1, "", "1005@38:1"),
    (39, 1, "", ""),
    (41, 1, "", "1005@84:0"),
    (43, 1, "", "1005@84:0"),
    (64, 1, "", "1109@72:1"),
    (71, 1, "", ""),
    (74, 1, "?", "1005@84:1"),
    (84, 1, "`", "1160@85:0"),
    (0, 0, "@", ""),
    (44, 0, "\u{2028}", ""),
  ]
  for mutation in mutations {
    let (position, width, replacement, expected_diagnostics) = mutation
    let mutated = _apply_source_mutation(source, position, width, replacement)
    let first = create_source_file("mutation.ts", mutated)
    let second = create_source_file("mutation.ts", mutated)
    let actual_diagnostics = _source_file_diagnostic_projection(first).join(",")
    assert_eq(
      actual_diagnostics,
      expected_diagnostics,
      msg=mutated + "\nactual=" + actual_diagnostics,
    )
    let (first_projection, _) = _tree_invariant_projection(
      first,
      mutated.length(),
    )
    let (second_projection, _) = _tree_invariant_projection(
      second,
      mutated.length(),
    )
    assert_eq(
      _source_file_diagnostic_projection(second),
      _source_file_diagnostic_projection(first),
      msg=mutated,
    )
    assert_eq(second_projection, first_projection, msg=mutated)
  }
}

///|
test "NodeArray trailing commas and transform aggregation are observable" {
  let source = "const a = [1, 2,]; function f(x: number, y?: string,) {} type T = [a: string, b?: number,];"
  let file = create_source_file("arrays.ts", source)
  assert_eq(_source_file_diagnostics(file).length(), 0)
  let (_, trailing_comma_lists) = _tree_invariant_projection(
    file,
    source.length(),
  )
  assert_true(trailing_comma_lists >= 3)
}

///|
test "malformed input terminates with exact literal and high-volume diagnostics" {
  let unterminated = [
    ("const x = \"unterminated", "1002@23:0"),
    ("/* unterminated", "1010@15:0"),
    ("const x = `unterminated", "1160@23:0"),
    ("const r = /unterminated", "1161@10:13"),
  ]
  for fixture in unterminated {
    let (source, expected) = fixture
    let file = create_source_file("unterminated.ts", source)
    assert_eq(_source_file_diagnostic_projection(file).join(","), expected)
    ignore(_tree_invariant_projection(file, source.length()))
  }

  let closing_braces = "}".repeat(2000)
  let brace_file = create_source_file("braces.ts", closing_braces)
  let brace_diagnostics = _source_file_diagnostic_projection(brace_file)
  assert_eq(brace_diagnostics.length(), 2000)
  assert_eq(brace_diagnostics[0], "1128@0:1")
  assert_eq(brace_diagnostics[1999], "1128@1999:1")

  let broken_declarations = "const = ;\n".repeat(2000)
  let declaration_file = create_source_file(
    "declarations.ts", broken_declarations,
  )
  let declaration_diagnostics = _source_file_diagnostic_projection(
    declaration_file,
  )
  assert_eq(declaration_diagnostics.length(), 2000)
  assert_eq(declaration_diagnostics[0], "1134@6:1")
  assert_eq(declaration_diagnostics[1999], "1134@19996:1")
}
