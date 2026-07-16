// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts and src/compiler/commandLineParser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _normalize_parser_file_name(file_name : String) -> String {
  let normalized = file_name.replace_all(old="\\", new="/")
  let rooted = normalized.has_prefix("/")
  let drive_rooted = normalized.length() >= 3 &&
    normalized[1].to_int() == CharacterCodes::colon() &&
    normalized[2].to_int() == CharacterCodes::slash()
  let protected_segments = if drive_rooted { 1 } else { 0 }
  let segments : Array[String] = []
  for segment in normalized.split("/") {
    match segment {
      "" | "." => ()
      ".." =>
        if segments.length() > protected_segments &&
          segments[segments.length() - 1] != ".." {
          ignore(segments.pop())
        } else if !rooted && !drive_rooted {
          segments.push("..")
        }
      value => segments.push(value.to_owned())
    }
  }
  let body = segments.join("/")
  if rooted {
    "/" + body
  } else {
    body
  }
}

///|
fn _source_file_attached_diagnostics(
  source_file : Node,
  diagnostics : Array[Diagnostic],
) -> ReadOnlyArray[Diagnostic] {
  let attached : Array[Diagnostic] = []
  for diagnostic in diagnostics {
    attached.push(_attach_file_to_diagnostic(diagnostic, source_file))
  }
  ReadOnlyArray::from_array(attached)
}

///|
fn ParserState::_finish_source_file_metadata(
  self : ParserState,
  source_file : Node,
  include_parser_collections : Bool,
) -> Unit {
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
  _parser_set_node_field(
    source_file,
    "identifiers",
    TextList(Some(ReadOnlyArray::from_array(self.identifier_order.copy()))),
  )
  if include_parser_collections {
    let pragmas = _process_comment_pragmas(self.source_text)
    self._process_pragmas_into_fields(source_file, pragmas)
    _parser_set_node_field(
      source_file,
      "commentDirectives",
      CommentDirectiveList(self.scanner._comment_directives()),
    )
  }
  _parser_add_node_field(
    source_file,
    "jsDocParsingMode",
    Integer(
      if include_parser_collections {
        Some(self.jsdoc_parsing_mode.to_int())
      } else {
        None
      },
    ),
  )
  _parser_set_node_field(
    source_file,
    "parseDiagnostics",
    DiagnosticList(
      Some(self._source_file_diagnostics_after_pragmas(source_file)),
    ),
  )
  match self.jsdoc_diagnostics {
    Some(diagnostics) =>
      _parser_add_node_field(
        source_file,
        "jsDocDiagnostics",
        DiagnosticList(
          Some(_source_file_attached_diagnostics(source_file, diagnostics)),
        ),
      )
    None => ()
  }
}

///|
fn ParserState::_source_file_diagnostics_after_pragmas(
  self : ParserState,
  source_file : Node,
) -> ReadOnlyArray[Diagnostic] {
  _source_file_attached_diagnostics(source_file, self.diagnostics)
}

///|
fn ParserState::_parse_json_root_expression(self : ParserState) -> Node {
  match self.current_token.to_int() {
    23 => self._parse_array_literal_expression()
    97 | 106 | 112 => self._parse_token_node()
    41 => {
      let negative_number = self._look_ahead(fn() -> Bool? {
          ignore(self._next_token())
          guard self.current_token.to_int() == 9 else { return None }
          ignore(self._next_token())
          if self.current_token.to_int() != 59 {
            Some(true)
          } else {
            None
          }
        })
        is Some(_)
      if negative_number {
        self._parse_prefix_unary_expression()
      } else {
        self._parse_object_literal_expression()
      }
    }
    9 | 11 => {
      let literal_value = self._look_ahead(fn() -> Bool? {
          ignore(self._next_token())
          if self.current_token.to_int() != 59 {
            Some(true)
          } else {
            None
          }
        })
        is Some(_)
      if literal_value {
        self._parse_literal_node()
      } else {
        self._parse_object_literal_expression()
      }
    }
    _ => self._parse_object_literal_expression()
  }
}

///|
fn _parse_json_text_worker(
  file_name : String,
  source_text : String,
  set_parent_nodes : Bool,
  scanner_language_version? : ScriptTarget = ScriptTarget::es2015(),
) -> Node {
  let state = _new_parser_state(
    file_name,
    source_text,
    language_version=scanner_language_version,
    script_kind=ScriptKind::json(),
    jsdoc_parsing_mode=JSDocParsingMode::parse_all(),
  )
  state.source_flags = state.context_flags
  ignore(state._prime())
  let pos = state._get_node_pos()
  let (statements, end_of_file_token) = if state.current_token.to_int() == 1 {
    let statements = state._create_parser_node_array([], pos, end=pos)
    let end_of_file_token = state._parse_token_node()
    (statements, end_of_file_token)
  } else {
    let expressions : Array[Node] = []
    while state.current_token.to_int() != 1 {
      let expression = state._parse_json_root_expression()
      expressions.push(expression)
      if expressions.length() == 1 && state.current_token.to_int() != 1 {
        ignore(state._parse_error_at_current_token(_diagnostic_message(1012)))
      }
    }
    let expression = if expressions.length() == 1 {
      expressions[0]
    } else {
      state._finish_parser_node(
        _factory_create_array_literal_expression(
          Some(_create_node_array(expressions)),
        ),
        pos,
      )
    }
    let statement = state._finish_parser_node(
      _factory_create_expression_statement(expression),
      pos,
    )
    let statements = state._create_parser_node_array([statement], pos)
    let end_of_file_token = state._parse_expected_token(
      _syntax_kind(1),
      message=_diagnostic_message(1012),
    )
    (statements, end_of_file_token)
  }
  let source_file = state._create_source_file(
    statements,
    end_of_file_token,
    false,
    None,
    Some(fn(_) { None }),
  )
  _parser_set_node_field(
    source_file,
    "languageVersion",
    Integer(Some(ScriptTarget::es2015().to_int())),
  )
  state._finish_source_file_metadata(source_file, false)
  if set_parent_nodes {
    ignore(_set_parent_recursive(source_file, incremental=true))
  }
  state._dispose()
  source_file
}

///|
fn _source_file_diagnostic_array(source_file : Node) -> Array[Diagnostic] {
  match source_file.field("parseDiagnostics") {
    Some(DiagnosticList(Some(diagnostics))) => {
      let result : Array[Diagnostic] = []
      for diagnostic in diagnostics {
        result.push(diagnostic)
      }
      result
    }
    _ => []
  }
}

///|
fn _json_error_span(source_file : Node, node : Node) -> TextRange {
  let error_node = match node.kind().to_int() {
    172
    | 173
    | 175
    | 178
    | 179
    | 209
    | 219
    | 232
    | 261
    | 263
    | 264
    | 265
    | 266
    | 267
    | 268
    | 275
    | 307 =>
      match _json_node_ref(node, "name") {
        Some(name) => name
        None => node
      }
    _ => node
  }
  if _node_is_missing(error_node) {
    return TextRange::new(error_node.pos(), end=error_node.end())
  }
  let start = skip_trivia(_source_file_text(source_file), error_node.pos())
  TextRange::new(start, end=error_node.end())
}

///|
fn _append_json_conversion_diagnostic(
  source_file : Node,
  diagnostics : Array[Diagnostic],
  node : Node,
  message : DiagnosticMessage,
  arguments? : ReadOnlyArray[DiagnosticArgument] = _no_diagnostic_arguments(),
) -> Unit {
  let range = _json_error_span(source_file, node)
  diagnostics.push(
    _create_file_diagnostic(
      source_file,
      range.pos(),
      range.width(),
      message,
      arguments,
    ),
  )
}

///|
fn _json_node_ref(node : Node, field_name : String) -> Node? {
  match node.field(field_name) {
    Some(NodeRef(value)) => value
    _ => None
  }
}

///|
fn _json_node_list(node : Node, field_name : String) -> NodeArray? {
  match node.field(field_name) {
    Some(NodeList(value)) => value
    _ => None
  }
}

///|
fn _json_is_double_quoted(source_file : Node, node : Node) -> Bool {
  guard node.kind().to_int() == 11 else { return false }
  let start = skip_trivia(_source_file_text(source_file), node.pos())
  _source_file_text(source_file).code_unit_at(start) ==
  CharacterCodes::double_quote()
}

///|
fn _convert_json_value(
  source_file : Node,
  node : Node,
  diagnostics : Array[Diagnostic],
) -> Unit {
  match node.kind().to_int() {
    97 | 106 | 112 | 9 => ()
    11 =>
      if !_json_is_double_quoted(source_file, node) {
        _append_json_conversion_diagnostic(
          source_file,
          diagnostics,
          node,
          _diagnostic_message(1327),
        )
      }
    225 => {
      let operator_is_minus = match node.field("operator") {
        Some(Kind(Some(operator))) => operator.to_int() == 41
        _ => false
      }
      let operand = _json_node_ref(node, "operand")
      let operand_is_numeric = match operand {
        Some(value) => value.kind().to_int() == 9
        None => false
      }
      if !operator_is_minus || !operand_is_numeric {
        _append_json_conversion_diagnostic(
          source_file,
          diagnostics,
          node,
          _diagnostic_message(1328),
        )
      }
    }
    210 =>
      match _json_node_list(node, "elements") {
        Some(elements) =>
          for element in elements.elements() {
            _convert_json_value(source_file, element, diagnostics)
          }
        None => ()
      }
    211 =>
      match _json_node_list(node, "properties") {
        Some(properties) =>
          for property in properties.elements() {
            if property.kind().to_int() != 304 {
              _append_json_conversion_diagnostic(
                source_file,
                diagnostics,
                property,
                _diagnostic_message(1136),
              )
              continue
            }
            match _json_node_ref(property, "questionToken") {
              Some(question) =>
                _append_json_conversion_diagnostic(
                  source_file,
                  diagnostics,
                  question,
                  _diagnostic_message(8009),
                  arguments=_parser_text_arguments("?"),
                )
              None => ()
            }
            match _json_node_ref(property, "name") {
              Some(name) =>
                if !_json_is_double_quoted(source_file, name) {
                  _append_json_conversion_diagnostic(
                    source_file,
                    diagnostics,
                    name,
                    _diagnostic_message(1327),
                  )
                }
              None => ()
            }
            match _json_node_ref(property, "initializer") {
              Some(initializer) =>
                _convert_json_value(source_file, initializer, diagnostics)
              None => ()
            }
          }
        None => ()
      }
    _ =>
      _append_json_conversion_diagnostic(
        source_file,
        diagnostics,
        node,
        _diagnostic_message(1328),
      )
  }
}

///|
fn _convert_source_file_to_json(source_file : Node) -> Unit {
  let diagnostics = _source_file_diagnostic_array(source_file)
  let root = match source_file.field("statements") {
    Some(NodeList(Some(statements))) =>
      match statements.get(0) {
        Some(statement) => _json_node_ref(statement, "expression")
        None => None
      }
    _ => None
  }
  match root {
    Some(expression) =>
      _convert_json_value(source_file, expression, diagnostics)
    None => ()
  }
  _parser_set_node_field(
    source_file,
    "parseDiagnostics",
    DiagnosticList(Some(ReadOnlyArray::from_array(diagnostics))),
  )
}

///|
fn _initialize_json_wrapper_collections(source_file : Node) -> Unit {
  _parser_set_node_field(
    source_file,
    "referencedFiles",
    FileReferenceList(Some(ReadOnlyArray::from_array([]))),
  )
  _parser_set_node_field(
    source_file,
    "typeReferenceDirectives",
    FileReferenceList(Some(ReadOnlyArray::from_array([]))),
  )
  _parser_set_node_field(
    source_file,
    "libReferenceDirectives",
    FileReferenceList(Some(ReadOnlyArray::from_array([]))),
  )
  _parser_set_node_field(
    source_file,
    "amdDependencies",
    AmdDependencyList(Some(ReadOnlyArray::from_array([]))),
  )
  _parser_set_node_field(
    source_file,
    "pragmas",
    PragmaMapValue(Some(ReadOnlyArray::from_array([]))),
  )
}

///|
fn _parse_source_file_worker(
  file_name : String,
  source_text : String,
  language_version : ScriptTarget,
  script_kind : ScriptKind,
  set_parent_nodes : Bool,
  jsdoc_parsing_mode : JSDocParsingMode,
  implied_node_format : ResolutionMode?,
  external_module_indicator_policy : ((Node) -> ExternalModuleIndicator?)?,
) -> Node {
  let state = _new_parser_state(
    file_name,
    source_text,
    language_version~,
    script_kind~,
    jsdoc_parsing_mode~,
  )
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
  if !is_declaration_file &&
    is_external_module(source_file) &&
    source_file
    .transform_flags()
    .contains(TransformFlags::contains_possible_top_level_await()) {
    let (statements, _) = state._reparse_top_level_await_intervals(
      first_pass_statements,
    )
    source_file = state._create_source_file(
      statements, end_of_file_token, is_declaration_file, implied_node_format, external_module_indicator_policy,
    )
  }
  state._finish_source_file_metadata(source_file, true)
  if set_parent_nodes {
    ignore(_set_parent_recursive(source_file, incremental=true))
  }
  state._dispose()
  source_file
}

///|
/// Parses a TypeScript, JavaScript, JSX, TSX, external, deferred, or JSON
/// source file. Unknown script kinds are inferred from the file name and then
/// fall back to TypeScript.
pub fn create_source_file(
  file_name : String,
  source_text : String,
  language_version? : ScriptTarget = ScriptTarget::latest(),
  script_kind? : ScriptKind = ScriptKind::unknown(),
  set_parent_nodes? : Bool = false,
  jsdoc_parsing_mode? : JSDocParsingMode = JSDocParsingMode::parse_all(),
  implied_node_format? : ResolutionMode,
  external_module_indicator_policy? : (Node) -> ExternalModuleIndicator?,
) -> Node {
  let file_name = _normalize_parser_file_name(file_name)
  let actual_script_kind = if language_version == ScriptTarget::json() {
    ScriptKind::json()
  } else if script_kind == ScriptKind::unknown() {
    ScriptKind::infer_or_ts(file_name)
  } else {
    script_kind
  }
  if actual_script_kind == ScriptKind::json() {
    let source_file = _parse_json_text_worker(
      file_name,
      source_text,
      set_parent_nodes,
      scanner_language_version=language_version,
    )
    _convert_source_file_to_json(source_file)
    _initialize_json_wrapper_collections(source_file)
    source_file
  } else {
    _parse_source_file_worker(
      file_name, source_text, language_version, actual_script_kind, set_parent_nodes,
      jsdoc_parsing_mode, implied_node_format, external_module_indicator_policy,
    )
  }
}

///|
/// Parses JSON/JSONC directly as a JSON/ES2015 SourceFile without running the
/// public wrapper's `convertToJson` validation pass.
pub fn parse_json_text(file_name : String, source_text : String) -> Node {
  _parse_json_text_worker(
    _normalize_parser_file_name(file_name),
    source_text,
    false,
  )
}

///|
/// Parses an entity name only when the complete input is consumed without a
/// parser diagnostic.
pub fn parse_isolated_entity_name(
  text : String,
  language_version? : ScriptTarget = ScriptTarget::latest(),
) -> Node? {
  let state = _new_parser_state(
    "",
    text,
    language_version~,
    script_kind=ScriptKind::js(),
    jsdoc_parsing_mode=JSDocParsingMode::parse_all(),
  )
  ignore(state._prime())
  let entity_name = state._parse_entity_name(true)
  let valid = state.current_token.to_int() == 1 && state.diagnostics.is_empty()
  state._dispose()
  if valid {
    Some(entity_name)
  } else {
    None
  }
}
