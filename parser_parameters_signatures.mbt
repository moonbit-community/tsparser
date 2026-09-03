// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _parser_required_node_array(array : NodeArray?) -> NodeArray {
  match array {
    Some(array) => array
    None => abort("required parser list callback failed")
  }
}

///|
fn _parser_set_node_field(
  node : Node,
  name : String,
  value : NodeFieldValue,
) -> Unit {
  let fields : Array[NodeField] = []
  let mut replaced = false
  for field in node.fields() {
    if field.name() == name {
      fields.push(_node_field(name, value))
      replaced = true
    } else {
      fields.push(field)
    }
  }
  guard replaced else {
    abort("parser attempted to replace an absent node field")
  }
  node._set_fields(fields)
}

///|
fn _parser_add_node_field(
  node : Node,
  name : String,
  value : NodeFieldValue,
) -> Unit {
  let fields : Array[NodeField] = []
  for field in node.fields() {
    guard field.name() != name else {
      abort("parser attempted to add an existing node field")
    }
    fields.push(field)
  }
  fields.push(_node_field(name, value))
  node._set_fields(fields)
}

///|
fn ParserState::_parse_modifier_list(
  self : ParserState,
  allow_decorators : Bool,
  permit_const : Bool,
) -> NodeArray? {
  self._parse_modifiers(allow_decorators, permit_const, false)
}

///|
fn ParserState::_parse_type_parameter_modifiers(
  self : ParserState,
) -> NodeArray? {
  let pos = self._get_node_pos()
  let modifiers : Array[Node] = []
  while self.current_token.to_int() == 103 ||
        self.current_token.to_int() == 147 ||
        self.current_token.to_int() == 87 {
    modifiers.push(self._parse_token_node())
  }
  if modifiers.is_empty() {
    None
  } else {
    Some(self._create_parser_node_array(modifiers, pos))
  }
}

///|
fn ParserState::_parse_type_parameter(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let modifiers = self._parse_type_parameter_modifiers()
  let name = self._parse_identifier()
  let mut expression : Node? = None
  let constraint = if self._parse_optional(_syntax_kind(96)) {
    if self._is_start_of_type(false) || !self._is_start_of_expression() {
      Some(self._parse_type())
    } else {
      expression = Some(self._parse_simple_unary_expression())
      None
    }
  } else {
    None
  }
  let default_type = if self._parse_optional(_syntax_kind(64)) {
    Some(self._parse_type())
  } else {
    None
  }
  let node = _factory_create_type_parameter_declaration(
    modifiers, name, constraint, default_type,
  )
  _parser_set_node_field(node, "expression", NodeRef(expression))
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_type_parameters(self : ParserState) -> NodeArray? {
  if self.current_token.to_int() != 30 {
    return None
  }
  self._parse_bracketed_list(
    ParsingContext::type_parameters(),
    fn() { Some(self._parse_type_parameter()) },
    _syntax_kind(30),
    _syntax_kind(32),
  )
}

///|
fn ParserState::_is_parameter_name_start(self : ParserState) -> Bool {
  self._is_binding_identifier() ||
  self.current_token.to_int() == 23 ||
  self.current_token.to_int() == 19
}

///|
fn ParserState::_parse_parameter_worker(
  self : ParserState,
  in_outer_await_context : Bool,
  allow_ambiguity : Bool,
) -> Node? {
  let pos = self._get_node_pos()
  let modifiers = if in_outer_await_context {
    self._do_in_await_context(fn() { self._parse_modifier_list(true, false) })
  } else {
    self._do_outside_of_await_context(fn() {
      self._parse_modifier_list(true, false)
    })
  }
  if self.current_token.to_int() == 110 {
    let name = self._create_identifier(true)
    let type_node = self._parse_type_annotation()
    let node = self._finish_parser_node(
      _factory_create_parameter_declaration(
        modifiers,
        None,
        name,
        None,
        type_node,
        None,
      ),
      pos,
    )
    match modifiers {
      Some(modifiers) if modifiers.length() > 0 =>
        match modifiers.get(0) {
          Some(modifier) =>
            ignore(
              self._parse_error_at_range(
                TextRange::new(modifier.pos(), end=modifier.end()),
                _diagnostic_message(1433),
              ),
            )
          None => ()
        }
      _ => ()
    }
    return Some(node)
  }
  let saved_top_level = self.top_level
  self.top_level = false
  let dot_dot_dot = self._parse_optional_token(_syntax_kind(26))
  if !allow_ambiguity && !self._is_parameter_name_start() {
    self.top_level = saved_top_level
    return None
  }
  let name = self._parse_identifier_or_pattern(
    private_message=_diagnostic_message(18009),
  )
  if name.pos() == name.end() &&
    modifiers is None &&
    _parser_is_modifier_kind(self.current_token) {
    ignore(self._next_token())
  }
  let question = self._parse_optional_token(_syntax_kind(58))
  let type_node = self._parse_type_annotation()
  let initializer = self._parse_initializer()
  let node = self._finish_parser_node(
    _factory_create_parameter_declaration(
      modifiers, dot_dot_dot, name, question, type_node, initializer,
    ),
    pos,
  )
  self.top_level = saved_top_level
  Some(node)
}

///|
fn ParserState::_parse_parameter(
  self : ParserState,
  in_outer_await_context : Bool,
) -> Node {
  match self._parse_parameter_worker(in_outer_await_context, true) {
    Some(parameter) => parameter
    None => abort("non-speculative parameter parse failed")
  }
}

///|
fn ParserState::_parse_parameters_worker_with_ambiguity(
  self : ParserState,
  flags : ParserSignatureFlags,
  allow_ambiguity : Bool,
) -> NodeArray? {
  let saved_yield = self._in_yield_context()
  let saved_await = self._in_await_context()
  self._set_yield_context(
    (flags.bits() & ParserSignatureFlags::yield_flag().bits()) != 0U,
  )
  self._set_await_context(
    (flags.bits() & ParserSignatureFlags::await_flag().bits()) != 0U,
  )
  let parameters = if (flags.bits() & ParserSignatureFlags::jsdoc().bits()) !=
    0U {
    self._parse_delimited_list(ParsingContext::jsdoc_parameters(), fn() {
      Some(self._parse_jsdoc_parameter())
    })
  } else {
    self._parse_delimited_list(ParsingContext::parameters(), fn() {
      self._parse_parameter_worker(saved_await, allow_ambiguity)
    })
  }
  self._set_yield_context(saved_yield)
  self._set_await_context(saved_await)
  parameters
}

///|
fn ParserState::_parse_parameters_worker(
  self : ParserState,
  flags : ParserSignatureFlags,
) -> NodeArray {
  _parser_required_node_array(
    self._parse_parameters_worker_with_ambiguity(flags, true),
  )
}

///|
fn ParserState::_parse_parameters(
  self : ParserState,
  flags : ParserSignatureFlags,
) -> NodeArray {
  if !self._parse_expected(_syntax_kind(21)) {
    return self._create_missing_list()
  }
  let parameters = self._parse_parameters_worker(flags)
  ignore(self._parse_expected(_syntax_kind(22)))
  parameters
}

///|
fn ParserState::_parse_type_annotation(self : ParserState) -> Node? {
  if self._parse_optional(_syntax_kind(59)) {
    Some(self._parse_type())
  } else {
    None
  }
}

///|
fn ParserState::_parse_type_predicate_prefix(self : ParserState) -> Node? {
  let identifier = self._parse_identifier()
  if self.current_token.to_int() == 142 &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    ignore(self._next_token())
    Some(identifier)
  } else {
    None
  }
}

///|
fn ParserState::_parse_asserts_type_predicate(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let asserts_modifier = self._parse_expected_token(_syntax_kind(131))
  let parameter_name = if self.current_token.to_int() == 110 {
    self._parse_this_type_node()
  } else {
    self._parse_identifier()
  }
  let type_node = if self.current_token.to_int() == 142 &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    ignore(self._next_token())
    Some(self._parse_type())
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_type_predicate_node(
      Some(asserts_modifier),
      parameter_name,
      type_node,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_type_or_type_predicate(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  if self.current_token.to_int() == 131 {
    return self._parse_asserts_type_predicate()
  }
  let predicate = if self._is_identifier() {
    self._try_parse(fn() { self._parse_type_predicate_prefix() })
  } else {
    None
  }
  let type_node = self._parse_type()
  match predicate {
    Some(parameter_name) =>
      self._finish_parser_node(
        _factory_create_type_predicate_node(
          None,
          parameter_name,
          Some(type_node),
        ),
        pos,
      )
    None => type_node
  }
}

///|
fn ParserState::_parse_return_type(
  self : ParserState,
  return_token : SyntaxKind,
  is_type : Bool,
) -> Node? {
  let should_parse = if return_token.to_int() == 39 {
    ignore(self._parse_expected(return_token))
    true
  } else if self._parse_optional(_syntax_kind(59)) {
    true
  } else if is_type && self.current_token.to_int() == 39 {
    ignore(
      self._parse_error_at_current_token(
        _diagnostic_message(1005),
        arguments=_parser_text_arguments(":"),
      ),
    )
    ignore(self._next_token())
    true
  } else {
    false
  }
  if should_parse {
    Some(
      self._allow_conditional_types_and(fn() {
        self._parse_type_or_type_predicate()
      }),
    )
  } else {
    None
  }
}

///|
fn ParserState::_parse_type_member_semicolon(self : ParserState) -> Unit {
  if !self._parse_optional(_syntax_kind(28)) {
    ignore(self._parse_semicolon())
  }
}

///|
fn ParserState::_parse_signature_member(
  self : ParserState,
  kind : SyntaxKind,
) -> Node {
  let pos = self._get_node_pos()
  if kind.to_int() == 181 {
    ignore(self._parse_expected(_syntax_kind(105)))
  }
  let type_parameters = self._parse_type_parameters()
  let parameters = self._parse_parameters(ParserSignatureFlags::type_flag())
  let type_node = self._parse_return_type(_syntax_kind(59), true)
  self._parse_type_member_semicolon()
  let node = if kind.to_int() == 180 {
    _factory_create_call_signature(type_parameters, parameters, type_node)
  } else {
    _factory_create_construct_signature(type_parameters, parameters, type_node)
  }
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_is_unambiguously_index_signature(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 26 || self.current_token.to_int() == 24 {
    return Some(true)
  }
  if _parser_is_modifier_kind(self.current_token) {
    ignore(self._next_token())
    return if self._is_identifier() { Some(true) } else { None }
  }
  guard self._is_identifier() else { return None }
  ignore(self._next_token())
  if self.current_token.to_int() == 59 || self.current_token.to_int() == 28 {
    return Some(true)
  }
  guard self.current_token.to_int() == 58 else { return None }
  ignore(self._next_token())
  match self.current_token.to_int() {
    24 | 28 | 59 => Some(true)
    _ => None
  }
}

///|
fn ParserState::_is_index_signature(self : ParserState) -> Bool {
  self.current_token.to_int() == 23 &&
  self._look_ahead(fn() { self._is_unambiguously_index_signature() }) is Some(_)
}

///|
fn ParserState::_parse_index_signature_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  let parameters = _parser_required_node_array(
    self._parse_bracketed_list(
      ParsingContext::parameters(),
      fn() { Some(self._parse_parameter(false)) },
      _syntax_kind(23),
      _syntax_kind(24),
    ),
  )
  let type_node = self._parse_type_annotation()
  self._parse_type_member_semicolon()
  self._finish_parser_node(
    _factory_create_index_signature(modifiers, parameters, type_node),
    pos,
  )
}

///|
fn ParserState::_parse_property_or_method_signature(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  let name = self._parse_property_name(fn() { self._parse_expression() })
  let question = self._parse_optional_token(_syntax_kind(58))
  let node = if self.current_token.to_int() == 21 ||
    self.current_token.to_int() == 30 {
    let type_parameters = self._parse_type_parameters()
    let parameters = self._parse_parameters(ParserSignatureFlags::type_flag())
    let type_node = self._parse_return_type(_syntax_kind(59), true)
    _factory_create_method_signature(
      modifiers, name, question, type_parameters, parameters, type_node,
    )
  } else {
    let type_node = self._parse_type_annotation()
    let property = _factory_create_property_signature(
      modifiers, name, question, type_node,
    )
    match self._parse_initializer() {
      Some(initializer) =>
        _parser_set_node_field(
          property,
          "initializer",
          NodeRef(Some(initializer)),
        )
      None => ()
    }
    property
  }
  self._parse_type_member_semicolon()
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_type_member(self : ParserState) -> Node {
  if self.current_token.to_int() == 21 || self.current_token.to_int() == 30 {
    return self._parse_signature_member(_syntax_kind(180))
  }
  if self.current_token.to_int() == 105 &&
    self._look_ahead(fn() {
      ignore(self._next_token())
      if self.current_token.to_int() == 21 || self.current_token.to_int() == 30 {
        Some(true)
      } else {
        None
      }
    })
    is Some(_) {
    return self._parse_signature_member(_syntax_kind(181))
  }
  let pos = self._get_node_pos()
  let modifiers = self._parse_modifiers(false, false, false)
  if self._parse_contextual_accessor_modifier(_syntax_kind(139)) {
    return self._parse_accessor_declaration(
      pos,
      modifiers,
      true,
      ParserSignatureFlags::type_flag(),
    )
  }
  if self._parse_contextual_accessor_modifier(_syntax_kind(153)) {
    return self._parse_accessor_declaration(
      pos,
      modifiers,
      false,
      ParserSignatureFlags::type_flag(),
    )
  }
  if self._is_index_signature() {
    self._parse_index_signature_declaration(pos, modifiers)
  } else {
    self._parse_property_or_method_signature(pos, modifiers)
  }
}

///|
fn ParserState::_parse_object_type_members(self : ParserState) -> NodeArray {
  if !self._parse_expected(_syntax_kind(19)) {
    return self._create_missing_list()
  }
  let members = self._parse_list(ParsingContext::type_members(), fn() {
    self._parse_type_member()
  })
  ignore(self._parse_expected(_syntax_kind(20)))
  members
}
