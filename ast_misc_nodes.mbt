// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _factory_create_case_clause(
  expression : Node,
  statements : NodeArray,
) -> Node {
  _make_fields_node(
    _syntax_kind(297),
    [
      _node_ref_field("expression", Some(expression)),
      _node_list_field("statements", Some(statements)),
    ],
    transform_flags=_propagate_child_flags(Some(expression)).union(
      _propagate_children_flags(Some(statements)),
    ),
  )
}

///|
fn _factory_create_default_clause(statements : NodeArray) -> Node {
  _make_fields_node(
    _syntax_kind(298),
    [_node_list_field("statements", Some(statements))],
    transform_flags=_propagate_children_flags(Some(statements)),
  )
}

///|
fn _factory_create_heritage_clause(
  token : SyntaxKind,
  types : NodeArray,
) -> Node {
  let own_flags = match token.to_int() {
    96 => TransformFlags::contains_es2015()
    119 => TransformFlags::contains_typescript()
    _ => abort("invalid heritage-clause token")
  }
  _make_fields_node(
    _syntax_kind(299),
    [_kind_field("token", Some(token)), _node_list_field("types", Some(types))],
    transform_flags=_propagate_children_flags(Some(types)).union(own_flags),
  )
}

///|
fn _factory_create_catch_clause(
  variable_declaration : Node?,
  block : Node,
) -> Node {
  let mut flags = _propagate_child_flags(variable_declaration).union(
    _propagate_child_flags(Some(block)),
  )
  if variable_declaration is None {
    flags = flags.union(TransformFlags::contains_es2019())
  }
  _make_fields_node(
    _syntax_kind(300),
    [
      _node_ref_field("variableDeclaration", variable_declaration),
      _node_ref_field("block", Some(block)),
    ],
    transform_flags=flags,
  )
}

///|
fn _factory_create_property_assignment(name : Node, initializer : Node) -> Node {
  _make_fields_node(
    _syntax_kind(304),
    [
      _node_ref_field("name", Some(name)),
      _node_ref_field("initializer", Some(initializer)),
      _node_list_field("modifiers", None),
      _node_ref_field("questionToken", None),
      _node_ref_field("exclamationToken", None),
    ],
    transform_flags=_propagate_name_flags(Some(name)).union(
      _propagate_child_flags(Some(initializer)),
    ),
  )
}

///|
fn _factory_create_shorthand_property_assignment(
  name : Node,
  object_assignment_initializer : Node?,
) -> Node {
  _make_fields_node(
    _syntax_kind(305),
    [
      _node_ref_field("name", Some(name)),
      _node_ref_field(
        "objectAssignmentInitializer", object_assignment_initializer,
      ),
      _node_ref_field("equalsToken", None),
      _node_list_field("modifiers", None),
      _node_ref_field("questionToken", None),
      _node_ref_field("exclamationToken", None),
    ],
    transform_flags=_propagate_identifier_name_flags(name)
      .union(_propagate_child_flags(object_assignment_initializer))
      .union(TransformFlags::contains_es2015()),
  )
}

///|
fn _factory_create_spread_assignment(expression : Node) -> Node {
  _make_fields_node(
    _syntax_kind(306),
    [_node_ref_field("expression", Some(expression))],
    transform_flags=_propagate_child_flags(Some(expression))
      .union(TransformFlags::contains_es2018())
      .union(TransformFlags::contains_object_rest_or_spread()),
  )
}

///|
fn _factory_create_enum_member(name : Node, initializer : Node?) -> Node {
  _make_fields_node(
    _syntax_kind(307),
    [
      _node_ref_field("name", Some(name)),
      _node_ref_field("initializer", initializer),
    ],
    transform_flags=_propagate_child_flags(Some(name))
      .union(_propagate_child_flags(initializer))
      .union(TransformFlags::contains_typescript()),
  )
}

///|
fn _factory_create_source_file(
  statements : NodeArray,
  end_of_file_token : Node,
  flags : NodeFlags,
) -> Node {
  let node = _make_fields_node(
    _syntax_kind(308),
    [
      _node_list_field("statements", Some(statements)),
      _node_ref_field("endOfFileToken", Some(end_of_file_token)),
      _text_field("text", Some("")),
      _text_field("fileName", Some("")),
      _text_field("path", Some("")),
      _text_field("resolvedPath", Some("")),
      _text_field("originalFileName", Some("")),
      _integer_field("languageVersion", Some(12)),
      _integer_field("languageVariant", Some(0)),
      _integer_field("scriptKind", Some(0)),
      _boolean_field("isDeclarationFile", Some(false)),
      _boolean_field("hasNoDefaultLib", Some(false)),
      _integer_field("nodeCount", Some(0)),
      _integer_field("identifierCount", Some(0)),
      _integer_field("symbolCount", Some(0)),
      _node_field("parseDiagnostics", DiagnosticList(None)),
      _undefined_field("bindDiagnostics"),
      _undefined_field("bindSuggestionDiagnostics"),
      _undefined_field("lineMap"),
      _external_module_indicator_field("externalModuleIndicator", None),
      _undefined_field("setExternalModuleIndicator"),
      _node_field("pragmas", PragmaMapValue(None)),
      _node_field("checkJsDirective", CheckJsDirectiveValue(None)),
      _node_field("referencedFiles", FileReferenceList(None)),
      _node_field("typeReferenceDirectives", FileReferenceList(None)),
      _node_field("libReferenceDirectives", FileReferenceList(None)),
      _node_field("amdDependencies", AmdDependencyList(None)),
      _node_field("commentDirectives", CommentDirectiveList(None)),
      _node_field("identifiers", TextList(None)),
      _undefined_field("packageJsonLocations"),
      _undefined_field("packageJsonScope"),
      _undefined_field("imports"),
      _undefined_field("moduleAugmentations"),
      _undefined_field("ambientModuleNames"),
      _undefined_field("classifiableNames"),
      _undefined_field("impliedNodeFormat"),
    ],
    transform_flags=_propagate_children_flags(Some(statements)).union(
      _propagate_child_flags(Some(end_of_file_token)),
    ),
  )
  node._set_flags(flags)
  node
}

///|
/// The two non-empty states accepted by `SourceFile.externalModuleIndicator`.
pub enum ExternalModuleIndicator {
  IndicatorNode(Node)
  IndicatorTrue
}

///|
pub fn ExternalModuleIndicator::from_node(
  node : Node,
) -> ExternalModuleIndicator {
  IndicatorNode(node)
}

///|
pub fn ExternalModuleIndicator::forced() -> ExternalModuleIndicator {
  IndicatorTrue
}
