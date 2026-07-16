// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// Invocation-local mutable parser state. No value of this type is retained by
/// a completed SourceFile or exposed through the public package interface.
#warnings("-unused_field")
priv struct ParserState {
  scanner : Scanner
  mut file_name : String
  mut source_text : String
  mut language_version : ScriptTarget
  mut script_kind : ScriptKind
  mut language_variant : LanguageVariant
  mut jsdoc_parsing_mode : JSDocParsingMode
  diagnostics : Array[Diagnostic]
  mut jsdoc_diagnostics : Array[Diagnostic]?
  mut current_token : SyntaxKind
  mut node_count : Int
  identifiers : Map[String, String]
  identifier_order : Array[String]
  mut identifier_count : Int
  mut parsing_context : UInt
  not_parenthesized_arrow : Map[Int, Bool]
  missing_lists : Array[NodeArray]
  mut context_flags : NodeFlags
  mut source_flags : NodeFlags
  mut top_level : Bool
  mut has_deprecated_tag : Bool
  finish_state : NodeFinishState
  mut active : Bool
}

///|
fn _new_parser_state(
  file_name : String,
  source_text : String,
  language_version? : ScriptTarget = ScriptTarget::latest(),
  script_kind? : ScriptKind = ScriptKind::ts(),
  jsdoc_parsing_mode? : JSDocParsingMode = JSDocParsingMode::parse_all(),
) -> ParserState {
  let language_variant = LanguageVariant::from_script_kind(script_kind)
  let context_flags = if script_kind == ScriptKind::js() ||
    script_kind == ScriptKind::jsx() {
    NodeFlags::javascript_file()
  } else if script_kind == ScriptKind::json() {
    NodeFlags::javascript_file().union(NodeFlags::json_file())
  } else {
    NodeFlags::none()
  }
  let scanner = _create_scanner(
    language_version,
    true,
    language_variant~,
    text=source_text,
  )
  scanner._set_script_kind(script_kind)
  scanner._set_jsdoc_parsing_mode(jsdoc_parsing_mode)
  let finish_state = _new_node_finish_state()
  finish_state._set_context_flags(context_flags)
  let state : ParserState = {
    scanner,
    file_name,
    source_text,
    language_version,
    script_kind,
    language_variant,
    jsdoc_parsing_mode,
    diagnostics: [],
    jsdoc_diagnostics: None,
    current_token: _syntax_kind(0),
    node_count: 0,
    identifiers: Map([]),
    identifier_order: [],
    identifier_count: 0,
    parsing_context: 0U,
    not_parenthesized_arrow: Map([]),
    missing_lists: [],
    context_flags,
    source_flags: context_flags,
    top_level: true,
    has_deprecated_tag: false,
    finish_state,
    active: true,
  }
  scanner._set_on_error(
    Some(fn(message, position, length, argument) {
      state._scan_error(message, position, length, argument)
    }),
  )
  state
}

///|
fn ParserState::_dispose(self : ParserState) -> Unit {
  self.scanner._clear_comment_directives()
  self.scanner._set_text("")
  self.scanner._set_on_error(None)
  self.scanner._set_script_kind(ScriptKind::unknown())
  self.scanner._set_jsdoc_parsing_mode(JSDocParsingMode::parse_all())
  self.file_name = ""
  self.source_text = ""
  self.language_version = ScriptTarget::latest()
  self.script_kind = ScriptKind::unknown()
  self.language_variant = LanguageVariant::standard()
  self.jsdoc_parsing_mode = JSDocParsingMode::parse_all()
  self.diagnostics.clear()
  self.jsdoc_diagnostics = None
  self.current_token = _syntax_kind(0)
  self.node_count = 0
  self.identifier_count = 0
  self.parsing_context = 0U
  self.identifiers.clear()
  self.identifier_order.clear()
  self.not_parenthesized_arrow.clear()
  self.missing_lists.clear()
  self.context_flags = NodeFlags::none()
  self.source_flags = NodeFlags::none()
  self.top_level = true
  self.has_deprecated_tag = false
  self.finish_state._set_context_flags(NodeFlags::none())
  self.finish_state.parse_error_before_next_finished_node = false
  self.active = false
}

///|
fn ParserState::_assert_active(self : ParserState) -> Unit {
  guard self.active else { abort("parser state has been disposed") }
}

///|
fn ParserState::_token(self : ParserState) -> SyntaxKind {
  self.current_token
}

///|
fn ParserState::_get_node_pos(self : ParserState) -> Int {
  self.scanner._token_full_start()
}

///|
fn ParserState::_diagnostic_arguments(
  argument : DiagnosticArgument?,
) -> ReadOnlyArray[DiagnosticArgument] {
  match argument {
    Some(argument) => ReadOnlyArray::from_array([argument])
    None => _no_diagnostic_arguments()
  }
}

///|
fn ParserState::_parse_error_at_position(
  self : ParserState,
  start : Int,
  length : Int,
  message : DiagnosticMessage,
  arguments? : ReadOnlyArray[DiagnosticArgument] = _no_diagnostic_arguments(),
) -> Diagnostic? {
  _parse_error_at_position(
    self.finish_state,
    self.diagnostics,
    self.file_name,
    self.source_text,
    start,
    length,
    message,
    arguments,
  )
}

///|
fn ParserState::_parse_error_at(
  self : ParserState,
  start : Int,
  end : Int,
  message : DiagnosticMessage,
  arguments? : ReadOnlyArray[DiagnosticArgument] = _no_diagnostic_arguments(),
) -> Diagnostic? {
  self._parse_error_at_position(start, end - start, message, arguments~)
}

///|
fn ParserState::_parse_error_at_range(
  self : ParserState,
  range : TextRange,
  message : DiagnosticMessage,
  arguments? : ReadOnlyArray[DiagnosticArgument] = _no_diagnostic_arguments(),
) -> Diagnostic? {
  self._parse_error_at(range.pos(), range.end(), message, arguments~)
}

///|
fn ParserState::_parse_error_at_current_token(
  self : ParserState,
  message : DiagnosticMessage,
  arguments? : ReadOnlyArray[DiagnosticArgument] = _no_diagnostic_arguments(),
) -> Diagnostic? {
  self._parse_error_at(
    self.scanner._token_start(),
    self.scanner._token_end(),
    message,
    arguments~,
  )
}

///|
fn ParserState::_scan_error(
  self : ParserState,
  message : DiagnosticMessage,
  position : Int,
  length : Int,
  argument : DiagnosticArgument?,
) -> Unit {
  ignore(
    self._parse_error_at_position(
      position,
      length,
      message,
      arguments=ParserState::_diagnostic_arguments(argument),
    ),
  )
}

///|
fn ParserState::_finish_parser_node(
  self : ParserState,
  node : Node,
  pos : Int,
  end? : Int,
) -> Node {
  self.finish_state._set_context_flags(self.context_flags)
  self.node_count += 1
  let result = _finish_node(
    self.finish_state,
    node,
    pos,
    match end {
      Some(end) => end
      None => self.scanner._token_full_start()
    },
  )
  self._with_jsdoc_if_needed(result)
}

///|
fn ParserState::_create_missing_parser_node(
  self : ParserState,
  kind : SyntaxKind,
  report_at_current_position : Bool,
  message? : DiagnosticMessage,
  arguments? : ReadOnlyArray[DiagnosticArgument] = _no_diagnostic_arguments(),
) -> Node {
  match message {
    Some(message) =>
      if report_at_current_position {
        ignore(
          self._parse_error_at_position(
            self.scanner._token_full_start(),
            0,
            message,
            arguments~,
          ),
        )
      } else {
        ignore(self._parse_error_at_current_token(message, arguments~))
      }
    None => ()
  }
  self.finish_state._set_context_flags(self.context_flags)
  self.node_count += 1
  _create_missing_node(
    self.finish_state,
    kind,
    self.scanner._token_full_start(),
  )
}

///|
fn ParserState::_create_parser_node_array(
  self : ParserState,
  elements : Array[Node],
  pos : Int,
  end? : Int,
  has_trailing_comma? : Bool = false,
) -> NodeArray {
  let result = _create_node_array(elements, has_trailing_comma~)
  result._set_text_range(
    pos,
    match end {
      Some(end) => end
      None => self.scanner._token_full_start()
    },
  )
  result
}

///|
fn ParserState::_create_missing_list(self : ParserState) -> NodeArray {
  let list = self._create_parser_node_array([], self._get_node_pos())
  self.missing_lists.push(list)
  list
}

///|
fn ParserState::_is_missing_list(
  self : ParserState,
  candidate : NodeArray,
) -> Bool {
  for list in self.missing_lists {
    if list.same_identity(candidate) {
      return true
    }
  }
  false
}

///|
fn ParserState::_intern_identifier(self : ParserState, text : String) -> String {
  match self.identifiers.get(text) {
    Some(identifier) => identifier
    None => {
      self.identifiers[text] = text
      self.identifier_order.push(text)
      text
    }
  }
}

///|
fn ParserState::_set_context_flag(
  self : ParserState,
  value : Bool,
  flag : NodeFlags,
) -> Unit {
  self.context_flags = if value {
    self.context_flags.union(flag)
  } else {
    self.context_flags.without(flag)
  }
  self.finish_state._set_context_flags(self.context_flags)
}

///|
fn[T] ParserState::_do_inside_of_context(
  self : ParserState,
  context : NodeFlags,
  callback : () -> T,
) -> T {
  let flags_to_set = context.without(self.context_flags)
  if flags_to_set.bits() == 0U {
    return callback()
  }
  self._set_context_flag(true, flags_to_set)
  let result = callback()
  self._set_context_flag(false, flags_to_set)
  result
}

///|
fn[T] ParserState::_do_outside_of_context(
  self : ParserState,
  context : NodeFlags,
  callback : () -> T,
) -> T {
  let flags_to_clear = context.intersect(self.context_flags)
  if flags_to_clear.bits() == 0U {
    return callback()
  }
  self._set_context_flag(false, flags_to_clear)
  let result = callback()
  self._set_context_flag(true, flags_to_clear)
  result
}

///|
fn ParserState::_in_context(self : ParserState, flags : NodeFlags) -> Bool {
  self.context_flags.intersect(flags).bits() != 0U
}

///|
fn ParserState::_set_disallow_in_context(
  self : ParserState,
  value : Bool,
) -> Unit {
  self._set_context_flag(value, NodeFlags::disallow_in_context())
}

///|
fn ParserState::_set_yield_context(self : ParserState, value : Bool) -> Unit {
  self._set_context_flag(value, NodeFlags::yield_context())
}

///|
fn ParserState::_set_decorator_context(
  self : ParserState,
  value : Bool,
) -> Unit {
  self._set_context_flag(value, NodeFlags::decorator_context())
}

///|
fn ParserState::_set_await_context(self : ParserState, value : Bool) -> Unit {
  self._set_context_flag(value, NodeFlags::await_context())
}

///|
fn[T] ParserState::_allow_in_and(self : ParserState, callback : () -> T) -> T {
  self._do_outside_of_context(NodeFlags::disallow_in_context(), callback)
}

///|
fn[T] ParserState::_disallow_in_and(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_inside_of_context(NodeFlags::disallow_in_context(), callback)
}

///|
fn[T] ParserState::_allow_conditional_types_and(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_outside_of_context(
    NodeFlags::disallow_conditional_types_context(),
    callback,
  )
}

///|
fn[T] ParserState::_disallow_conditional_types_and(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_inside_of_context(
    NodeFlags::disallow_conditional_types_context(),
    callback,
  )
}

///|
fn[T] ParserState::_do_in_yield_context(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_inside_of_context(NodeFlags::yield_context(), callback)
}

///|
fn[T] ParserState::_do_in_decorator_context(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_inside_of_context(NodeFlags::decorator_context(), callback)
}

///|
fn[T] ParserState::_do_in_await_context(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_inside_of_context(NodeFlags::await_context(), callback)
}

///|
fn[T] ParserState::_do_outside_of_await_context(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_outside_of_context(NodeFlags::await_context(), callback)
}

///|
fn[T] ParserState::_do_in_yield_and_await_context(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_inside_of_context(
    NodeFlags::yield_context().union(NodeFlags::await_context()),
    callback,
  )
}

///|
fn[T] ParserState::_do_outside_of_yield_and_await_context(
  self : ParserState,
  callback : () -> T,
) -> T {
  self._do_outside_of_context(
    NodeFlags::yield_context().union(NodeFlags::await_context()),
    callback,
  )
}

///|
fn ParserState::_in_yield_context(self : ParserState) -> Bool {
  self._in_context(NodeFlags::yield_context())
}

///|
fn ParserState::_in_disallow_in_context(self : ParserState) -> Bool {
  self._in_context(NodeFlags::disallow_in_context())
}

///|
fn ParserState::_in_disallow_conditional_types_context(
  self : ParserState,
) -> Bool {
  self._in_context(NodeFlags::disallow_conditional_types_context())
}

///|
fn ParserState::_in_decorator_context(self : ParserState) -> Bool {
  self._in_context(NodeFlags::decorator_context())
}

///|
fn ParserState::_in_await_context(self : ParserState) -> Bool {
  self._in_context(NodeFlags::await_context())
}

///|
fn[T] ParserState::_speculation_helper(
  self : ParserState,
  callback : () -> T?,
  kind : SpeculationKind,
) -> T? {
  let saved_token = self.current_token
  let saved_diagnostics_length = self.diagnostics.length()
  let saved_error_before_node = self.finish_state.parse_error_before_next_finished_node
  let saved_context_flags = self.context_flags
  let result = match kind {
    TryParse => self.scanner._try_scan(callback)
    Lookahead | Reparse => self.scanner._look_ahead(callback)
  }
  guard saved_context_flags == self.context_flags else {
    abort("parser speculation callback did not restore context flags")
  }
  if result is None || kind.to_int() != SpeculationKind::TryParse.to_int() {
    self.current_token = saved_token
    if kind.to_int() != SpeculationKind::Reparse.to_int() {
      self.diagnostics.truncate(saved_diagnostics_length)
    }
    self.finish_state.parse_error_before_next_finished_node = saved_error_before_node
  }
  result
}

///|
fn[T] ParserState::_look_ahead(self : ParserState, callback : () -> T?) -> T? {
  self._speculation_helper(callback, SpeculationKind::Lookahead)
}

///|
fn[T] ParserState::_try_parse(self : ParserState, callback : () -> T?) -> T? {
  self._speculation_helper(callback, SpeculationKind::TryParse)
}

///|
fn[T] ParserState::_reparse(self : ParserState, callback : () -> T?) -> T? {
  self._speculation_helper(callback, SpeculationKind::Reparse)
}

///|
fn ParserState::_record_not_parenthesized_arrow(
  self : ParserState,
  position : Int,
) -> Unit {
  self.not_parenthesized_arrow[position] = true
}

///|
fn ParserState::_is_not_parenthesized_arrow(
  self : ParserState,
  position : Int,
) -> Bool {
  self.not_parenthesized_arrow.contains(position)
}
