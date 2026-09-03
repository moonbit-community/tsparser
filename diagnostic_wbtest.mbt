///|
fn _diagnostic_arguments(
  arguments : Array[DiagnosticArgument],
) -> ReadOnlyArray[DiagnosticArgument] {
  ReadOnlyArray::from_array(arguments)
}

///|
fn _set_diagnostic_source_file_fields(
  source_file : Node,
  file_name : String,
  text : String,
) -> Unit {
  let fields : Array[NodeField] = []
  let mut found_file_name = false
  let mut found_text = false
  for field in source_file.fields() {
    if field.name() == "fileName" {
      fields.push(_text_field("fileName", Some(file_name)))
      found_file_name = true
    } else if field.name() == "text" {
      fields.push(_text_field("text", Some(text)))
      found_text = true
    } else {
      fields.push(field)
    }
  }
  guard found_file_name && found_text else {
    abort("SourceFile diagnostic fields are missing")
  }
  source_file._set_fields(fields)
}

///|
fn _diagnostic_source(file_name : String, text : String) -> Node {
  let eof = _factory_create_token(_syntax_kind(1))
  eof._set_text_range(text.length(), text.length())
  let source = _factory_create_source_file(
    _create_node_array([]),
    eof,
    NodeFlags::none(),
  )
  source._set_text_range(0, text.length())
  _set_diagnostic_source_file_fields(source, file_name, text)
  source
}

///|
test "148-entry diagnostic catalog" {
  let codes = _diagnostic_catalog_codes()
  assert_eq(codes.length(), 148)
  let mut errors = 0
  let mut messages = 0
  let mut zero_placeholders = 0
  let mut one_placeholder = 0
  let mut two_placeholders = 0
  for index in 0..<codes.length() {
    let code = codes[index]
    for earlier in 0..<index {
      assert_false(codes[earlier] == code, msg="duplicate diagnostic code")
    }
    let message = _diagnostic_message(code)
    assert_eq(message.code(), code)
    assert_true(message.upstream_symbol().has_prefix("Diagnostics."))
    assert_true(message.key().has_suffix("_" + code.to_string()))
    assert_false(message.message().is_empty())
    assert_true(message.reports_unnecessary() is None)
    assert_true(message.reports_deprecated() is None)
    if message.category() == DiagnosticCategory::error() {
      errors += 1
    } else if message.category() == DiagnosticCategory::message() {
      messages += 1
    } else {
      fail("parser catalog contains an unexpected category")
    }
    match message.placeholder_count() {
      0 => zero_placeholders += 1
      1 => one_placeholder += 1
      2 => two_placeholders += 1
      _ => fail("unexpected diagnostic placeholder count")
    }
  }
  assert_eq(errors, 147)
  assert_eq(messages, 1)
  assert_eq(zero_placeholders, 123)
  assert_eq(one_placeholder, 24)
  assert_eq(two_placeholders, 1)
  assert_eq(_diagnostic_message(1369).category(), DiagnosticCategory::message())
  inspect(
    _diagnostic_message(1510).message(),
    content="'\\k' must be followed by a capturing group name enclosed in angle brackets.",
  )
}

///|
test "diagnostic formatting and message chains" {
  let matching = _diagnostic_message(1007)
  let formatted = _format_diagnostic_message(
    matching,
    _diagnostic_arguments([
      DiagnosticArgument::text("{"),
      DiagnosticArgument::text("}"),
    ]),
  )
  inspect(
    formatted,
    content="The parser expected to find a '}' to match the '{' token here.",
  )
  inspect(
    _format_diagnostic_message(
      _diagnostic_message(1005),
      _no_diagnostic_arguments(),
    ),
    content="'{0}' expected.",
  )
  let indexed = _diagnostic_arguments([
    DiagnosticArgument::number(0),
    DiagnosticArgument::number(1),
    DiagnosticArgument::number(2),
    DiagnosticArgument::number(3),
    DiagnosticArgument::number(4),
    DiagnosticArgument::number(5),
    DiagnosticArgument::number(6),
    DiagnosticArgument::number(7),
    DiagnosticArgument::number(8),
    DiagnosticArgument::number(9),
    DiagnosticArgument::number(10),
  ])
  inspect(
    format_string_from_diagnostic_arguments("a{10}b{0}c{x}", indexed),
    content="a10b0c{x}",
  )

  let leaf = _chain_diagnostic_messages(
    None,
    _diagnostic_message(1003),
    _no_diagnostic_arguments(),
  )
  let middle = _chain_diagnostic_messages(
    Some(ReadOnlyArray::from_array([leaf])),
    _diagnostic_message(1012),
    _no_diagnostic_arguments(),
  )
  let sibling = _chain_diagnostic_messages(
    None,
    _diagnostic_message(1109),
    _no_diagnostic_arguments(),
  )
  let head = _chain_diagnostic_messages(
    Some(ReadOnlyArray::from_array([middle, sibling])),
    _diagnostic_message(1005),
    _diagnostic_arguments([DiagnosticArgument::text(";")]),
  )
  inspect(
    DiagnosticChainValue(head).flatten("\n"),
    content="';' expected.\n  Unexpected token.\n    Identifier expected.\n  Expression expected.",
  )
  match head.next() {
    Some(children) => {
      assert_eq(children.length(), 2)
      assert_eq(children[0].code(), 1012)
      match children[0].next() {
        Some(grandchildren) => assert_eq(grandchildren[0].code(), 1003)
        None => fail("expected nested message chain")
      }
    }
    None => fail("expected message-chain children")
  }
  let empty_next = _chain_diagnostic_messages(
    Some(ReadOnlyArray::from_array([])),
    _diagnostic_message(1002),
    _no_diagnostic_arguments(),
  )
  assert_true(
    _create_compiler_diagnostic_from_chain(empty_next).message_text()
    is DiagnosticChainValue(_),
  )
  assert_true(
    _create_compiler_diagnostic_from_chain(leaf).message_text()
    is DiagnosticTextValue(_),
  )
}

///|
test "detached attached and related diagnostics" {
  let source = _diagnostic_source("unicode.ts", "A😀B")
  let main = _create_detached_diagnostic(
    "unicode.ts",
    "A😀B",
    1,
    99,
    _diagnostic_message(1002),
    _no_diagnostic_arguments(),
  )
  assert_true(main.is_detached())
  assert_false(main.is_attached())
  assert_eq(main.file_name(), Some("unicode.ts"))
  assert_eq(main.start(), Some(1))
  assert_eq(main.length(), Some(3))
  assert_true(main.file() is None)

  let same_file = _create_detached_diagnostic(
    "unicode.ts",
    "A😀B",
    0,
    1,
    _diagnostic_message(1003),
    _no_diagnostic_arguments(),
  )
  let other_file = _create_detached_diagnostic(
    "other.ts",
    "Z",
    0,
    1,
    _diagnostic_message(1012),
    _no_diagnostic_arguments(),
  )
  let no_location = _create_compiler_diagnostic(
    _diagnostic_message(1109),
    _no_diagnostic_arguments(),
  )
  let with_related = _add_related_information(
    main,
    ReadOnlyArray::from_array([same_file, other_file, no_location]),
  )
  let attached = _attach_file_to_diagnostic(with_related, source)
  assert_true(attached.is_attached())
  assert_false(attached.is_detached())
  match attached.file() {
    Some(file) => assert_true(file.same_identity(source))
    None => fail("expected attached SourceFile")
  }
  match attached.related_information() {
    Some(related) => {
      assert_eq(related.length(), 3)
      assert_true(related[0].is_attached())
      match related[0].file() {
        Some(file) => assert_true(file.same_identity(source))
        None => fail("same-file related diagnostic was not attached")
      }
      assert_true(related[1].is_detached())
      assert_eq(related[1].file_name(), Some("other.ts"))
      assert_false(related[2].is_attached())
      assert_false(related[2].is_detached())
      assert_true(related[2].file_name() is None)
    }
    None => fail("expected related information")
  }

  let direct = _create_file_diagnostic(
    source,
    1,
    2,
    _diagnostic_message(1127),
    _no_diagnostic_arguments(),
  )
  assert_true(direct.is_attached())
  assert_eq(direct.start(), Some(1))
  assert_eq(direct.length(), Some(2))
}

///|
test "parse error suppression is adjacent only" {
  let finish_state = _new_node_finish_state()
  let diagnostics : Array[Diagnostic] = []
  let first = _parse_error_at_position(
    finish_state,
    diagnostics,
    "broken.ts",
    "abcdef",
    0,
    1,
    _diagnostic_message(1002),
    _no_diagnostic_arguments(),
  )
  assert_true(first is Some(_))
  let adjacent_duplicate = _parse_error_at_position(
    finish_state,
    diagnostics,
    "broken.ts",
    "abcdef",
    0,
    2,
    _diagnostic_message(1003),
    _no_diagnostic_arguments(),
  )
  assert_true(adjacent_duplicate is None)
  assert_eq(diagnostics.length(), 1)
  assert_true(finish_state._has_pending_parse_error())

  let scanned_span = _parse_error_at_position(
    finish_state,
    diagnostics,
    "broken.ts",
    "abcdef",
    2,
    2,
    _diagnostic_message(1127),
    _no_diagnostic_arguments(),
  )
  assert_true(scanned_span is Some(_))
  assert_eq(diagnostics[1].start(), Some(2))
  assert_eq(diagnostics[1].length(), Some(2))

  let non_adjacent_same_start = _parse_error_at_position(
    finish_state,
    diagnostics,
    "broken.ts",
    "abcdef",
    0,
    6,
    _diagnostic_message(1005),
    _diagnostic_arguments([DiagnosticArgument::text(";")]),
  )
  assert_true(non_adjacent_same_start is Some(_))
  assert_eq(diagnostics.length(), 3)
  assert_eq(diagnostics[0].code(), 1002)
  assert_eq(diagnostics[1].code(), 1127)
  assert_eq(diagnostics[2].code(), 1005)
  assert_eq(diagnostics[2].start(), Some(0))

  let final_duplicate = _parse_error_at_position(
    finish_state,
    diagnostics,
    "broken.ts",
    "abcdef",
    0,
    0,
    _diagnostic_message(1012),
    _no_diagnostic_arguments(),
  )
  assert_true(final_duplicate is None)
  assert_eq(diagnostics.length(), 3)
  let error_node = _finish_node(finish_state, _contract_identifier(), 0, 0)
  assert_true(error_node.flags().contains(NodeFlags::this_node_has_error()))
  assert_false(finish_state._has_pending_parse_error())
}
