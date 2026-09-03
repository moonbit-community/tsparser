// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
#warnings("-unused_field")
priv struct TopLevelAwaitReparseInterval {
  start : Int
  initial_stop : Int
  final_stop : Int
}

///|
#warnings("-unused_field")
priv struct SourceFileParseResult {
  source_file : Node
  first_pass_statements : NodeArray
  diagnostics : Array[Diagnostic]
  first_node_count : Int
  first_identifier_count : Int
  first_interned_identifier_count : Int
  final_node_count : Int
  final_identifier_count : Int
  final_interned_identifier_count : Int
  reparse_intervals : Array[TopLevelAwaitReparseInterval]
}

///|
fn _source_file_statements(source_file : Node) -> NodeArray {
  match source_file.field("statements") {
    Some(NodeList(Some(statements))) => statements
    _ => abort("SourceFile statements are missing")
  }
}

///|
fn _node_has_modifier(node : Node, kind : Int) -> Bool {
  match node.field("modifiers") {
    Some(NodeList(Some(modifiers))) => {
      for modifier in modifiers.elements() {
        if modifier.kind().to_int() == kind {
          return true
        }
      }
      false
    }
    _ => false
  }
}

///|
fn _is_external_import_equals(node : Node) -> Bool {
  guard node.kind().to_int() == 272 else { return false }
  match node.field("moduleReference") {
    Some(NodeRef(Some(reference))) => reference.kind().to_int() == 284
    _ => false
  }
}

///|
fn _is_external_module_indicator_node(node : Node) -> Bool {
  _node_has_modifier(node, 95) ||
  _is_external_import_equals(node) ||
  node.kind().to_int() == 273 ||
  node.kind().to_int() == 278 ||
  node.kind().to_int() == 279
}

///|
fn _is_import_meta(node : Node) -> Bool {
  guard node.kind().to_int() == 237 else { return false }
  let is_import = match node.field("keywordToken") {
    Some(Kind(Some(kind))) => kind.to_int() == 102
    _ => false
  }
  let is_meta = match node.field("name") {
    Some(NodeRef(Some(name))) => _parser_identifier_text(name) is Some("meta")
    _ => false
  }
  is_import && is_meta
}

///|
fn _find_import_meta(source_file : Node) -> Node? {
  guard source_file.flags().contains(NodeFlags::possibly_contains_import_meta()) else {
    return None
  }
  for_each_child_recursively(source_file, fn(child, _) {
    if _is_import_meta(child) {
      TraversalControl::stop(child)
    } else {
      TraversalControl::proceed()
    }
  })
}

///|
fn _default_external_module_indicator(
  source_file : Node,
) -> ExternalModuleIndicator? {
  for statement in _source_file_statements(source_file).elements() {
    if _is_external_module_indicator_node(statement) {
      return Some(ExternalModuleIndicator::from_node(statement))
    }
  }
  match _find_import_meta(source_file) {
    Some(node) => Some(ExternalModuleIndicator::from_node(node))
    None => None
  }
}

///|
fn _set_external_module_indicator(
  source_file : Node,
  policy : ((Node) -> ExternalModuleIndicator?)?,
) -> Unit {
  let indicator = match policy {
    Some(policy) => policy(source_file)
    None => _default_external_module_indicator(source_file)
  }
  _parser_set_node_field(
    source_file,
    "externalModuleIndicator",
    ExternalModuleIndicatorValue(indicator),
  )
}

///|
pub fn is_external_module(source_file : Node) -> Bool {
  guard source_file.kind().to_int() == 308 else { return false }
  match source_file.field("externalModuleIndicator") {
    Some(ExternalModuleIndicatorValue(Some(_))) => true
    _ => false
  }
}

///|
fn ParserState::_set_source_file_fields(
  self : ParserState,
  source_file : Node,
  is_declaration_file : Bool,
  implied_node_format : ResolutionMode?,
  external_module_indicator_policy : ((Node) -> ExternalModuleIndicator?)?,
) -> Unit {
  _parser_set_node_field(source_file, "text", Text(Some(self.source_text)))
  _parser_set_node_field(source_file, "fileName", Text(Some(self.file_name)))
  _parser_set_node_field(
    source_file,
    "languageVersion",
    Integer(Some(self.language_version.to_int())),
  )
  _parser_set_node_field(
    source_file,
    "languageVariant",
    Integer(Some(self.language_variant.to_int())),
  )
  _parser_set_node_field(
    source_file,
    "scriptKind",
    Integer(Some(self.script_kind.to_int())),
  )
  _parser_set_node_field(
    source_file,
    "isDeclarationFile",
    Boolean(Some(is_declaration_file)),
  )
  _parser_set_node_field(
    source_file,
    "nodeCount",
    Integer(Some(self.node_count)),
  )
  _parser_set_node_field(
    source_file,
    "identifierCount",
    Integer(Some(self.identifier_count)),
  )
  match implied_node_format {
    Some(format) =>
      _parser_set_node_field(
        source_file,
        "impliedNodeFormat",
        Integer(Some(format.to_int())),
      )
    None => _parser_set_node_field(source_file, "impliedNodeFormat", Undefined)
  }
  _set_external_module_indicator(source_file, external_module_indicator_policy)
}

///|
fn ParserState::_create_source_file(
  self : ParserState,
  statements : NodeArray,
  end_of_file_token : Node,
  is_declaration_file : Bool,
  implied_node_format : ResolutionMode?,
  external_module_indicator_policy : ((Node) -> ExternalModuleIndicator?)?,
) -> Node {
  self.node_count += 1
  let source_file = _factory_create_source_file(
    statements,
    end_of_file_token,
    self.source_flags,
  )
  source_file._set_text_range(0, SourceText::new(self.source_text).length())
  self._set_source_file_fields(
    source_file, is_declaration_file, implied_node_format, external_module_indicator_policy,
  )
  source_file
}

///|
fn _contains_possible_top_level_await(node : Node) -> Bool {
  !node.flags().contains(NodeFlags::await_context()) &&
  node
  .transform_flags()
  .contains(TransformFlags::contains_possible_top_level_await())
}

///|
fn _find_next_statement_with_await(statements : NodeArray, start : Int) -> Int {
  for index = start; index < statements.length(); index = index + 1 {
    if _contains_possible_top_level_await(statements.get(index).unwrap()) {
      return index
    }
  }
  -1
}

///|
fn _find_next_statement_without_await(
  statements : NodeArray,
  start : Int,
) -> Int {
  for index = start; index < statements.length(); index = index + 1 {
    if !_contains_possible_top_level_await(statements.get(index).unwrap()) {
      return index
    }
  }
  -1
}

///|
fn _diagnostic_at_or_after(
  diagnostics : Array[Diagnostic],
  position : Int,
  start : Int,
) -> Int {
  for index = start; index < diagnostics.length(); index = index + 1 {
    match diagnostics[index].start() {
      Some(diagnostic_start) if diagnostic_start >= position => return index
      _ => ()
    }
  }
  -1
}

///|
fn _append_diagnostics(
  output : Array[Diagnostic],
  input : Array[Diagnostic],
  start : Int,
  end : Int,
) -> Unit {
  guard start >= 0 else { return }
  let limit = if end >= 0 { end } else { input.length() }
  for index = start; index < limit; index = index + 1 {
    output.push(input[index])
  }
}

///|
fn ParserState::_reparse_top_level_await_intervals(
  self : ParserState,
  statements : NodeArray,
) -> (NodeArray, Array[TopLevelAwaitReparseInterval]) {
  let reparsed : Array[Node] = []
  let intervals : Array[TopLevelAwaitReparseInterval] = []
  let saved_diagnostics = self.diagnostics.copy()
  self.diagnostics.clear()
  let mut pos = 0
  let mut start = _find_next_statement_with_await(statements, 0)
  while start != -1 {
    let previous_statement = statements.get(pos).unwrap()
    let next_statement = statements.get(start).unwrap()
    for index = pos; index < start; index = index + 1 {
      reparsed.push(statements.get(index).unwrap())
    }
    pos = _find_next_statement_without_await(statements, start)
    let diagnostic_start = _diagnostic_at_or_after(
      saved_diagnostics,
      previous_statement.pos(),
      0,
    )
    let diagnostic_end = if diagnostic_start >= 0 {
      _diagnostic_at_or_after(
        saved_diagnostics,
        next_statement.pos(),
        diagnostic_start,
      )
    } else {
      -1
    }
    _append_diagnostics(
      self.diagnostics,
      saved_diagnostics,
      diagnostic_start,
      diagnostic_end,
    )
    let initial_stop = if pos >= 0 {
      statements.get(pos).unwrap().pos()
    } else {
      SourceText::new(self.source_text).length()
    }
    let mut final_stop = next_statement.pos()
    ignore(
      self._reparse(fn() -> Unit? {
        let saved_context_flags = self.context_flags
        self._set_await_context(true)
        self.scanner._reset_token_state(next_statement.pos())
        ignore(self._next_token())
        while self.current_token.to_int() != 1 {
          let start_position = self.scanner._token_full_start()
          let statement = self._parse_statement()
          reparsed.push(statement)
          final_stop = statement.end()
          if start_position == self.scanner._token_full_start() {
            ignore(self._next_token())
          }
          if pos >= 0 {
            let non_await_statement = statements.get(pos).unwrap()
            if statement.end() == non_await_statement.pos() {
              break
            }
            if statement.end() > non_await_statement.pos() {
              pos = _find_next_statement_without_await(statements, pos + 1)
            }
          }
        }
        self.context_flags = saved_context_flags
        self.finish_state._set_context_flags(saved_context_flags)
        Some(())
      }),
    )
    intervals.push({ start: next_statement.pos(), initial_stop, final_stop })
    start = if pos >= 0 {
      _find_next_statement_with_await(statements, pos)
    } else {
      -1
    }
  }
  if pos >= 0 {
    let previous_statement = statements.get(pos).unwrap()
    for index = pos; index < statements.length(); index = index + 1 {
      reparsed.push(statements.get(index).unwrap())
    }
    let diagnostic_start = _diagnostic_at_or_after(
      saved_diagnostics,
      previous_statement.pos(),
      0,
    )
    _append_diagnostics(
      self.diagnostics,
      saved_diagnostics,
      diagnostic_start,
      -1,
    )
  }
  let result = _create_node_array(
    reparsed,
    has_trailing_comma=statements.has_trailing_comma(),
  )
  result._set_text_range(statements.pos(), statements.end())
  (result, intervals)
}

///|
fn _parse_source_file_for_test(
  text : String,
  file_name? : String = "module.ts",
  script_kind? : ScriptKind = ScriptKind::ts(),
  implied_node_format? : ResolutionMode,
  external_module_indicator_policy? : (Node) -> ExternalModuleIndicator?,
  set_parent_nodes? : Bool = true,
) -> SourceFileParseResult {
  let state = _new_parser_state(file_name, text, script_kind~)
  let is_declaration_file = _parser_is_declaration_file_name(file_name)
  if is_declaration_file {
    state._set_context_flag(true, NodeFlags::ambient())
  }
  state.source_flags = state.context_flags
  ignore(state._prime())
  let first_pass_statements = state._parse_list(
    ParsingContext::source_elements(),
    fn() { state._parse_statement() },
  )
  let end_of_file_token = state._parse_token_node()
  let mut source_file = state._create_source_file(
    first_pass_statements, end_of_file_token, is_declaration_file, implied_node_format,
    external_module_indicator_policy,
  )
  let first_node_count = state.node_count
  let first_identifier_count = state.identifier_count
  let first_interned_identifier_count = state.identifiers.length()
  let mut reparse_intervals : Array[TopLevelAwaitReparseInterval] = []
  if !is_declaration_file &&
    is_external_module(source_file) &&
    source_file
    .transform_flags()
    .contains(TransformFlags::contains_possible_top_level_await()) {
    let (statements, intervals) = state._reparse_top_level_await_intervals(
      first_pass_statements,
    )
    reparse_intervals = intervals
    source_file = state._create_source_file(
      statements, end_of_file_token, is_declaration_file, implied_node_format, external_module_indicator_policy,
    )
  }
  if set_parent_nodes {
    ignore(_set_parent_recursive(source_file, incremental=true))
  }
  let result : SourceFileParseResult = {
    source_file,
    first_pass_statements,
    diagnostics: state.diagnostics.copy(),
    first_node_count,
    first_identifier_count,
    first_interned_identifier_count,
    final_node_count: state.node_count,
    final_identifier_count: state.identifier_count,
    final_interned_identifier_count: state.identifiers.length(),
    reparse_intervals,
  }
  state._dispose()
  result
}
