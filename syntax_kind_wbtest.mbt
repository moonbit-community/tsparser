///|
test "all 359 SyntaxKind values have complete names and aliases" {
  let runtime_names : Map[String, Int] = Map([])
  let mut declaration_count = 0
  let mut marker_count = 0
  for value = 0; value < SyntaxKind::count(); value = value + 1 {
    guard SyntaxKind::from_int(value) is Some(kind) else {
      fail("valid SyntaxKind was rejected")
    }
    let runtime_name = kind.runtime_name()
    guard !runtime_name.is_empty() else { fail("empty runtime name") }
    guard !runtime_names.contains(runtime_name) else {
      fail("duplicate runtime reverse name")
    }
    runtime_names[runtime_name] = value
    let declarations = kind.declaration_names()
    guard declarations.length() > 0 else { fail("missing declaration name") }
    declaration_count += declarations.length()
    marker_count += kind.classification_markers().length()
    inspect(kind.to_int(), content="\{value}")
  }
  inspect(runtime_names.length(), content="359")
  inspect(declaration_count, content="362")
  inspect(marker_count, content="33")
  assert_true(SyntaxKind::from_int(-1) is None)
  assert_true(SyntaxKind::from_int(SyntaxKind::count()) is None)
}

///|
test "SyntaxKind compatibility aliases remain distinct projections" {
  guard SyntaxKind::from_int(301) is Some(import_attributes) else {
    fail("missing ImportAttributes")
  }
  guard SyntaxKind::from_int(321) is Some(jsdoc) else { fail("missing JSDoc") }
  guard SyntaxKind::from_int(79) is Some(last_binary) else {
    fail("missing CaretEqualsToken")
  }
  inspect(import_attributes.runtime_name(), content="AssertClause")
  debug_inspect(
    import_attributes.declaration_names(),
    content=(
      #|<ReadOnlyArray: ["ImportAttributes", "AssertClause"]>
    ),
  )
  inspect(jsdoc.runtime_name(), content="JSDocComment")
  debug_inspect(
    jsdoc.declaration_names(),
    content=(
      #|<ReadOnlyArray: ["JSDoc", "JSDocComment"]>
    ),
  )
  inspect(last_binary.runtime_name(), content="LastBinaryOperator")
  debug_inspect(
    last_binary.classification_markers(),
    content=(
      #|<ReadOnlyArray:
      #|  [
      #|    "LastAssignment",
      #|    "LastCompoundAssignment",
      #|    "LastPunctuation",
      #|    "LastBinaryOperator",
      #|  ]>
    ),
  )
}
