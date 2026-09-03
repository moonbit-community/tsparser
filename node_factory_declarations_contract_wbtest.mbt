///|
test "statement factory field contracts" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let block = _contract_block()

  _assert_factory_contract("NodeFactory.createBlock", block, 242, [
    "statements", "multiLine",
  ])
  _assert_factory_contract(
    "NodeFactory.createBreakStatement",
    _factory_create_break_statement(None),
    253,
    ["label"],
  )
  _assert_factory_contract(
    "NodeFactory.createContinueStatement",
    _factory_create_continue_statement(None),
    252,
    ["label"],
  )
  _assert_factory_contract(
    "NodeFactory.createDebuggerStatement",
    _factory_create_debugger_statement(),
    260,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createDoStatement",
    _factory_create_do_statement(block, id),
    247,
    ["statement", "expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createEmptyStatement",
    _factory_create_empty_statement(),
    243,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createExpressionStatement",
    _factory_create_expression_statement(id),
    245,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createForInStatement",
    _factory_create_for_in_statement(id, id, block),
    250,
    ["initializer", "expression", "statement"],
  )
  _assert_factory_contract(
    "NodeFactory.createForOfStatement",
    _factory_create_for_of_statement(None, id, id, block),
    251,
    ["awaitModifier", "initializer", "expression", "statement"],
  )
  _assert_factory_contract(
    "NodeFactory.createForStatement",
    _factory_create_for_statement(None, None, None, block),
    249,
    ["initializer", "condition", "incrementor", "statement"],
  )
  _assert_factory_contract(
    "NodeFactory.createIfStatement",
    _factory_create_if_statement(id, block, None),
    246,
    ["expression", "thenStatement", "elseStatement"],
  )
  _assert_factory_contract(
    "NodeFactory.createLabeledStatement",
    _factory_create_labeled_statement(id, block),
    257,
    ["label", "statement"],
  )
  _assert_factory_contract(
    "NodeFactory.createReturnStatement",
    _factory_create_return_statement(None),
    254,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createSwitchStatement",
    _factory_create_switch_statement(id, _factory_create_case_block(empty)),
    256,
    ["expression", "caseBlock", "possiblyExhaustive"],
  )
  _assert_factory_contract(
    "NodeFactory.createThrowStatement",
    _factory_create_throw_statement(id),
    258,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createTryStatement",
    _factory_create_try_statement(block, None, None),
    259,
    ["tryBlock", "catchClause", "finallyBlock"],
  )
  _assert_factory_contract(
    "NodeFactory.createWhileStatement",
    _factory_create_while_statement(id, block),
    248,
    ["expression", "statement"],
  )
  _assert_factory_contract(
    "NodeFactory.createWithStatement",
    _factory_create_with_statement(id, block),
    255,
    ["expression", "statement"],
  )
}

///|
test "declaration and module factory field contracts" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let block = _contract_block()
  let type_node = _factory_create_this_type_node()
  let string_literal = _factory_create_string_literal("m")
  let external = _factory_create_external_module_reference(string_literal)

  _assert_factory_contract(
    "NodeFactory.createVariableDeclaration",
    _factory_create_variable_declaration(id, None, None, None),
    261,
    ["name", "exclamationToken", "type", "initializer"],
  )
  _assert_factory_contract(
    "NodeFactory.createVariableDeclarationList",
    _factory_create_variable_declaration_list(empty),
    262,
    ["declarations"],
  )
  _assert_factory_contract(
    "NodeFactory.createVariableStatement",
    _factory_create_variable_statement(
      None,
      _factory_create_variable_declaration_list(empty),
    ),
    244,
    ["modifiers", "declarationList"],
  )
  _assert_factory_contract(
    "NodeFactory.createFunctionDeclaration",
    _factory_create_function_declaration(
      None,
      None,
      Some(id),
      None,
      empty,
      None,
      Some(block),
    ),
    263,
    [
      "modifiers", "asteriskToken", "name", "typeParameters", "parameters", "type",
      "body", "typeArguments",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createClassDeclaration",
    _factory_create_class_declaration(None, Some(id), None, None, empty),
    264,
    ["modifiers", "name", "typeParameters", "heritageClauses", "members"],
  )
  _assert_factory_contract(
    "NodeFactory.createInterfaceDeclaration",
    _factory_create_interface_declaration(None, id, None, None, empty),
    265,
    ["modifiers", "name", "typeParameters", "heritageClauses", "members"],
  )
  _assert_factory_contract(
    "NodeFactory.createTypeAliasDeclaration",
    _factory_create_type_alias_declaration(None, id, None, type_node),
    266,
    ["modifiers", "name", "typeParameters", "type"],
  )
  _assert_factory_contract(
    "NodeFactory.createEnumDeclaration",
    _factory_create_enum_declaration(None, id, empty),
    267,
    ["modifiers", "name", "members"],
  )
  _assert_factory_contract(
    "NodeFactory.createModuleDeclaration",
    _factory_create_module_declaration(None, id, None),
    268,
    ["modifiers", "name", "body"],
  )
  _assert_factory_contract(
    "NodeFactory.createModuleBlock",
    _factory_create_module_block(empty),
    269,
    ["statements"],
  )
  _assert_factory_contract(
    "NodeFactory.createCaseBlock",
    _factory_create_case_block(empty),
    270,
    ["clauses"],
  )
  _assert_factory_contract(
    "NodeFactory.createNamespaceExportDeclaration",
    _factory_create_namespace_export_declaration(id),
    271,
    ["name", "modifiers"],
  )
  _assert_factory_contract(
    "NodeFactory.createImportEqualsDeclaration",
    _factory_create_import_equals_declaration(None, false, id, external),
    272,
    ["modifiers", "name", "isTypeOnly", "moduleReference"],
  )
  _assert_factory_contract(
    "NodeFactory.createImportDeclaration",
    _factory_create_import_declaration(None, None, string_literal, None),
    273,
    [
      "modifiers", "importClause", "moduleSpecifier", "assertClause", "attributes",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createImportClause",
    _factory_create_import_clause(None, Some(id), None),
    274,
    ["isTypeOnly", "phaseModifier", "name", "namedBindings"],
  )
  _assert_factory_contract(
    "NodeFactory.createImportAttributes",
    _factory_create_import_attributes(empty),
    301,
    ["token", "elements", "multiLine"],
  )
  _assert_factory_contract(
    "NodeFactory.createImportAttribute",
    _factory_create_import_attribute(id, string_literal),
    302,
    ["name", "value"],
  )
  _assert_factory_contract(
    "NodeFactory.createNamespaceImport",
    _factory_create_namespace_import(id),
    275,
    ["name"],
  )
  _assert_factory_contract(
    "NodeFactory.createNamespaceExport",
    _factory_create_namespace_export(id),
    281,
    ["name"],
  )
  _assert_factory_contract(
    "NodeFactory.createNamedImports",
    _factory_create_named_imports(empty),
    276,
    ["elements"],
  )
  _assert_factory_contract(
    "NodeFactory.createImportSpecifier",
    _factory_create_import_specifier(false, None, id),
    277,
    ["isTypeOnly", "propertyName", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createExportAssignment",
    _factory_create_export_assignment(None, None, id),
    278,
    ["modifiers", "isExportEquals", "expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createExportDeclaration",
    _factory_create_export_declaration(None, false, None, None, None),
    279,
    [
      "modifiers", "isTypeOnly", "exportClause", "moduleSpecifier", "assertClause",
      "attributes",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createNamedExports",
    _factory_create_named_exports(empty),
    280,
    ["elements"],
  )
  _assert_factory_contract(
    "NodeFactory.createExportSpecifier",
    _factory_create_export_specifier(false, None, id),
    282,
    ["isTypeOnly", "propertyName", "name"],
  )
  _assert_factory_contract(
    "NodeFactory.createMissingDeclaration",
    _factory_create_missing_declaration(),
    283,
    [],
  )
  _assert_factory_contract(
    "NodeFactory.createExternalModuleReference",
    external,
    284,
    ["expression"],
  )
}

///|
test "miscellaneous declaration factory field contracts" {
  let id = _contract_identifier()
  let empty = _contract_empty_list()
  let block = _contract_block()

  _assert_factory_contract(
    "NodeFactory.createCaseClause",
    _factory_create_case_clause(id, empty),
    297,
    ["expression", "statements"],
  )
  _assert_factory_contract(
    "NodeFactory.createDefaultClause",
    _factory_create_default_clause(empty),
    298,
    ["statements"],
  )
  _assert_factory_contract(
    "NodeFactory.createHeritageClause",
    _factory_create_heritage_clause(_syntax_kind(96), empty),
    299,
    ["token", "types"],
  )
  _assert_factory_contract(
    "NodeFactory.createCatchClause",
    _factory_create_catch_clause(None, block),
    300,
    ["variableDeclaration", "block"],
  )
  _assert_factory_contract(
    "NodeFactory.createPropertyAssignment",
    _factory_create_property_assignment(id, id),
    304,
    ["name", "initializer", "modifiers", "questionToken", "exclamationToken"],
  )
  _assert_factory_contract(
    "NodeFactory.createShorthandPropertyAssignment",
    _factory_create_shorthand_property_assignment(id, None),
    305,
    [
      "name", "objectAssignmentInitializer", "equalsToken", "modifiers", "questionToken",
      "exclamationToken",
    ],
  )
  _assert_factory_contract(
    "NodeFactory.createSpreadAssignment",
    _factory_create_spread_assignment(id),
    306,
    ["expression"],
  )
  _assert_factory_contract(
    "NodeFactory.createEnumMember",
    _factory_create_enum_member(id, None),
    307,
    ["name", "initializer"],
  )
  let source_file = _factory_create_source_file(
    empty,
    _factory_create_token(_syntax_kind(1)),
    NodeFlags::none(),
  )
  _assert_factory_contract("NodeFactory.createSourceFile", source_file, 308, [
    "statements", "endOfFileToken", "text", "fileName", "path", "resolvedPath", "originalFileName",
    "languageVersion", "languageVariant", "scriptKind", "isDeclarationFile", "hasNoDefaultLib",
    "nodeCount", "identifierCount", "symbolCount", "parseDiagnostics", "bindDiagnostics",
    "bindSuggestionDiagnostics", "lineMap", "externalModuleIndicator", "setExternalModuleIndicator",
    "pragmas", "checkJsDirective", "referencedFiles", "typeReferenceDirectives",
    "libReferenceDirectives", "amdDependencies", "commentDirectives", "identifiers",
    "packageJsonLocations", "packageJsonScope", "imports", "moduleAugmentations",
    "ambientModuleNames", "classifiableNames", "impliedNodeFormat",
  ])
  match source_file.field("externalModuleIndicator") {
    Some(ExternalModuleIndicatorValue(None)) => ()
    _ => fail("SourceFile must initialize a typed empty module indicator")
  }

  let by_node = ExternalModuleIndicator::from_node(id)
  match by_node {
    IndicatorNode(actual) => assert_true(actual.same_identity(id))
    IndicatorTrue => fail("node module indicator lost its node identity")
  }
  match ExternalModuleIndicator::forced() {
    IndicatorTrue => ()
    IndicatorNode(_) =>
      fail("forced module indicator must be the true sentinel")
  }
}
