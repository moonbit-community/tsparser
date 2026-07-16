// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_can_follow_modifier(self : ParserState) -> Bool {
  self.current_token.to_int() == 23 ||
  self.current_token.to_int() == 19 ||
  self.current_token.to_int() == 42 ||
  self.current_token.to_int() == 26 ||
  self._is_literal_property_name()
}

///|
fn ParserState::_next_token_is_same_line_and_can_follow_modifier(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    self._can_follow_modifier() {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_can_follow_default_modifier(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 86 ||
    self.current_token.to_int() == 100 ||
    self.current_token.to_int() == 120 ||
    self.current_token.to_int() == 60 {
    return Some(true)
  }
  if self.current_token.to_int() == 128 {
    return self._look_ahead(fn() {
      ignore(self._next_token())
      if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
        self.current_token.to_int() == 86 {
        Some(true)
      } else {
        None
      }
    })
  } else if self.current_token.to_int() == 134 {
    return self._look_ahead(fn() {
      ignore(self._next_token())
      if !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
        self.current_token.to_int() == 100 {
        Some(true)
      } else {
        None
      }
    })
  }
  None
}

///|
fn ParserState::_can_follow_export_modifier(self : ParserState) -> Bool {
  self.current_token.to_int() == 60 ||
  (
    self.current_token.to_int() != 42 &&
    self.current_token.to_int() != 130 &&
    self.current_token.to_int() != 19 &&
    self._can_follow_modifier()
  )
}

///|
fn ParserState::_next_token_can_follow_modifier(self : ParserState) -> Bool? {
  match self.current_token.to_int() {
    87 => {
      ignore(self._next_token())
      if self.current_token.to_int() == 94 {
        Some(true)
      } else {
        None
      }
    }
    95 => {
      ignore(self._next_token())
      if self.current_token.to_int() == 90 {
        return self._look_ahead(fn() {
          self._next_token_can_follow_default_modifier()
        })
      }
      if self.current_token.to_int() == 156 {
        return self._look_ahead(fn() {
          ignore(self._next_token())
          if self._can_follow_export_modifier() {
            Some(true)
          } else {
            None
          }
        })
      }
      if self._can_follow_export_modifier() {
        Some(true)
      } else {
        None
      }
    }
    90 => self._next_token_can_follow_default_modifier()
    126 => {
      ignore(self._next_token())
      if self._can_follow_modifier() {
        Some(true)
      } else {
        None
      }
    }
    139 | 153 => {
      ignore(self._next_token())
      if self.current_token.to_int() == 23 || self._is_literal_property_name() {
        Some(true)
      } else {
        None
      }
    }
    _ => self._next_token_is_same_line_and_can_follow_modifier()
  }
}

///|
fn ParserState::_try_parse_decorator(self : ParserState) -> Node? {
  let pos = self._get_node_pos()
  guard self._parse_optional(_syntax_kind(60)) else { return None }
  let expression = self._do_in_decorator_context(fn() {
    self._parse_left_hand_side_expression_or_higher()
  })
  Some(self._finish_parser_node(_factory_create_decorator(expression), pos))
}

///|
fn ParserState::_try_parse_modifier(
  self : ParserState,
  has_seen_static : Bool,
  permit_const : Bool,
  stop_on_static_block : Bool,
) -> Node? {
  let kind = self.current_token
  let pos = self._get_node_pos()
  if kind.to_int() == 87 && permit_const {
    guard self._try_parse(fn() {
        self._next_token_is_same_line_and_can_follow_modifier()
      })
      is Some(_) else {
      return None
    }
  } else if stop_on_static_block &&
    kind.to_int() == 126 &&
    self._look_ahead(fn() {
      ignore(self._next_token())
      if self.current_token.to_int() == 19 {
        Some(true)
      } else {
        None
      }
    })
    is Some(_) {
    return None
  } else if has_seen_static && kind.to_int() == 126 {
    return None
  } else {
    guard _parser_is_modifier_kind(kind) &&
      self._try_parse(fn() { self._next_token_can_follow_modifier() })
      is Some(_) else {
      return None
    }
  }
  Some(self._finish_parser_node(_factory_create_token(kind), pos))
}

///|
fn ParserState::_parse_modifiers(
  self : ParserState,
  allow_decorators : Bool,
  permit_const : Bool,
  stop_on_static_block : Bool,
) -> NodeArray? {
  let pos = self._get_node_pos()
  let values : Array[Node] = []
  if allow_decorators {
    while self.current_token.to_int() == 60 {
      match self._try_parse_decorator() {
        Some(decorator) => values.push(decorator)
        None => break
      }
    }
  }
  let mut seen_static = false
  let mut leading_modifier = false
  while true {
    match
      self._try_parse_modifier(seen_static, permit_const, stop_on_static_block) {
      Some(modifier) => {
        if modifier.kind().to_int() == 126 {
          seen_static = true
        }
        values.push(modifier)
        leading_modifier = true
      }
      None => break
    }
  }
  let mut trailing_decorator = false
  if leading_modifier && allow_decorators {
    while self.current_token.to_int() == 60 {
      match self._try_parse_decorator() {
        Some(decorator) => {
          values.push(decorator)
          trailing_decorator = true
        }
        None => break
      }
    }
  }
  if trailing_decorator {
    while true {
      match
        self._try_parse_modifier(
          seen_static, permit_const, stop_on_static_block,
        ) {
        Some(modifier) => {
          if modifier.kind().to_int() == 126 {
            seen_static = true
          }
          values.push(modifier)
        }
        None => break
      }
    }
  }
  if values.is_empty() {
    None
  } else {
    Some(self._create_parser_node_array(values, pos))
  }
}

///|
fn _parser_modifiers_contain_kind(modifiers : NodeArray?, kind : Int) -> Bool {
  match modifiers {
    Some(modifiers) => {
      for modifier in modifiers.elements() {
        if modifier.kind().to_int() == kind {
          return true
        }
      }
      false
    }
    None => false
  }
}

///|
fn _parser_mark_modifiers_ambient(modifiers : NodeArray?) -> Unit {
  match modifiers {
    Some(modifiers) =>
      for modifier in modifiers.elements() {
        modifier._add_flags(NodeFlags::ambient())
      }
    None => ()
  }
}

///|
fn _parser_append_node_field(
  node : Node,
  name : String,
  value : NodeFieldValue,
) -> Unit {
  let fields : Array[NodeField] = []
  for field in node.fields() {
    if field.name() == name {
      abort("parser attempted to append an existing node field")
    }
    fields.push(field)
  }
  fields.push(_node_field(name, value))
  node._set_fields(fields)
}

///|
fn ParserState::_parse_declaration(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let modifiers = self._parse_modifiers(true, false, false)
  if _parser_modifiers_contain_kind(modifiers, 138) {
    _parser_mark_modifiers_ambient(modifiers)
    self._do_inside_of_context(NodeFlags::ambient(), fn() {
      self._parse_declaration_worker(pos, modifiers)
    })
  } else {
    self._parse_declaration_worker(pos, modifiers)
  }
}

///|
fn ParserState::_parse_declaration_worker(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  match self.current_token.to_int() {
    115 | 121 | 87 | 160 => self._parse_variable_statement(pos, modifiers)
    135 if self._is_await_using_declaration() =>
      self._parse_variable_statement(pos, modifiers)
    100 => self._parse_function_declaration(pos, modifiers)
    86 => self._parse_class_declaration(pos, modifiers)
    120 => self._parse_interface_declaration(pos, modifiers)
    156 => self._parse_type_alias_declaration(pos, modifiers)
    94 => self._parse_enum_declaration(pos, modifiers)
    162 | 144 | 145 => self._parse_module_declaration(pos, modifiers)
    102 => self._parse_import_declaration_or_import_equals(pos, modifiers)
    95 => {
      ignore(self._next_token())
      match self.current_token.to_int() {
        90 | 64 => self._parse_export_assignment(pos, modifiers)
        130 => self._parse_namespace_export_declaration(pos, modifiers)
        _ => self._parse_export_declaration(pos, modifiers)
      }
    }
    _ => {
      let missing = self._create_missing_parser_node(
        _syntax_kind(283),
        true,
        message=_diagnostic_message(1146),
      )
      match modifiers {
        Some(_) =>
          _parser_append_node_field(missing, "modifiers", NodeList(modifiers))
        None => ()
      }
      missing._set_text_range(pos, missing.end())
      missing
    }
  }
}

///|
fn ParserState::_parse_function_block_or_semicolon(
  self : ParserState,
  flags : ParserSignatureFlags,
) -> Node? {
  if self.current_token.to_int() != 19 {
    if (flags.bits() & ParserSignatureFlags::type_flag().bits()) != 0U {
      self._parse_type_member_semicolon()
      return None
    }
    if self._can_parse_semicolon() {
      ignore(self._parse_semicolon())
      return None
    }
  }
  Some(self._parse_function_block(flags, message=_diagnostic_message(1144)))
}

///|
fn ParserState::_parse_function_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  let saved_await = self._in_await_context()
  ignore(self._parse_expected(_syntax_kind(100)))
  let asterisk = self._parse_optional_token(_syntax_kind(42))
  let name = if _parser_modifiers_contain_kind(modifiers, 90) {
    self._parse_optional_binding_identifier()
  } else {
    Some(self._parse_binding_identifier())
  }
  let mut flags = ParserSignatureFlags::none()
  if asterisk is Some(_) {
    flags = flags.union(ParserSignatureFlags::yield_flag())
  }
  if _parser_modifiers_contain_kind(modifiers, 134) {
    flags = flags.union(ParserSignatureFlags::await_flag())
  }
  let type_parameters = self._parse_type_parameters()
  if _parser_modifiers_contain_kind(modifiers, 95) {
    self._set_await_context(true)
  }
  let parameters = self._parse_parameters(flags)
  let type_node = self._parse_return_type(_syntax_kind(59), false)
  let body = self._parse_function_block_or_semicolon(flags)
  self._set_await_context(saved_await)
  self._finish_parser_node(
    _factory_create_function_declaration(
      modifiers, asterisk, name, type_parameters, parameters, type_node, body,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_constructor_name(self : ParserState) -> Bool {
  if self.current_token.to_int() == 137 {
    ignore(self._next_token())
    return true
  }
  if self.current_token.to_int() == 11 &&
    self._look_ahead(fn() {
      ignore(self._next_token())
      if self.current_token.to_int() == 21 {
        Some(true)
      } else {
        None
      }
    })
    is Some(_) {
    let saved = self._parse_literal_node()
    return match saved.field("text") {
      Some(Text(Some("constructor"))) => true
      _ => false
    }
  }
  false
}

///|
fn ParserState::_try_parse_constructor_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node? {
  self._try_parse(fn() {
    guard self._parse_constructor_name() else { return None }
    let type_parameters = self._parse_type_parameters()
    let parameters = self._parse_parameters(ParserSignatureFlags::none())
    let type_node = self._parse_return_type(_syntax_kind(59), false)
    let body = self._parse_function_block_or_semicolon(
      ParserSignatureFlags::none(),
    )
    let node = _factory_create_constructor_declaration(
      modifiers, parameters, body,
    )
    _parser_set_node_field(node, "typeParameters", NodeList(type_parameters))
    _parser_set_node_field(node, "type", NodeRef(type_node))
    Some(self._finish_parser_node(node, pos))
  })
}

///|
fn ParserState::_parse_method_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
  asterisk : Node?,
  name : Node,
  question : Node?,
  exclamation : Node?,
) -> Node {
  let mut flags = ParserSignatureFlags::none()
  if asterisk is Some(_) {
    flags = flags.union(ParserSignatureFlags::yield_flag())
  }
  if _parser_modifiers_contain_kind(modifiers, 134) {
    flags = flags.union(ParserSignatureFlags::await_flag())
  }
  let type_parameters = self._parse_type_parameters()
  let parameters = self._parse_parameters(flags)
  let type_node = self._parse_return_type(_syntax_kind(59), false)
  let body = self._parse_function_block_or_semicolon(flags)
  let node = _factory_create_method_declaration(
    modifiers, asterisk, name, question, type_parameters, parameters, type_node,
    body,
  )
  _parser_set_node_field(node, "exclamationToken", NodeRef(exclamation))
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_property_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
  name : Node,
  question : Node?,
) -> Node {
  let exclamation = if question is None &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    self._parse_optional_token(_syntax_kind(54))
  } else {
    None
  }
  let type_node = self._parse_type_annotation()
  let initializer = self._do_outside_of_context(
    NodeFlags::yield_context()
    .union(NodeFlags::await_context())
    .union(NodeFlags::disallow_in_context()),
    fn() { self._parse_initializer() },
  )
  self._parse_semicolon_after_property_name(name, type_node, initializer)
  self._finish_parser_node(
    _factory_create_property_declaration(
      modifiers,
      name,
      match question {
        Some(question) => Some(question)
        None => exclamation
      },
      type_node,
      initializer,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_semicolon_after_property_name(
  self : ParserState,
  name : Node,
  type_node : Node?,
  initializer : Node?,
) -> Unit {
  if self.current_token.to_int() == 60 &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    ignore(self._parse_error_at_current_token(_diagnostic_message(1436)))
    return
  }
  if self.current_token.to_int() == 21 {
    ignore(self._parse_error_at_current_token(_diagnostic_message(1441)))
    ignore(self._next_token())
    return
  }
  if type_node is Some(_) && !self._can_parse_semicolon() {
    let diagnostic = if initializer is Some(_) {
      _diagnostic_message(1005)
    } else {
      _diagnostic_message(1442)
    }
    let arguments = if initializer is Some(_) {
      _parser_text_arguments(";")
    } else {
      []
    }
    ignore(self._parse_error_at_current_token(diagnostic, arguments~))
    return
  }
  if self._try_parse_semicolon() {
    return
  }
  match initializer {
    Some(_) =>
      ignore(
        self._parse_error_at_current_token(
          _diagnostic_message(1005),
          arguments=_parser_text_arguments(";"),
        ),
      )
    None => self._parse_error_for_missing_semicolon_after(name)
  }
}

///|
fn ParserState::_parse_property_or_method_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  let asterisk = self._parse_optional_token(_syntax_kind(42))
  let name = self._parse_property_name(fn() { self._parse_expression() })
  let question = self._parse_optional_token(_syntax_kind(58))
  if asterisk is Some(_) ||
    self.current_token.to_int() == 21 ||
    self.current_token.to_int() == 30 {
    self._parse_method_declaration(
      pos,
      modifiers,
      asterisk,
      name,
      question,
      None,
    )
  } else {
    self._parse_property_declaration(pos, modifiers, name, question)
  }
}

///|
fn ParserState::_parse_accessor_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
  is_get : Bool,
  flags : ParserSignatureFlags,
) -> Node {
  let name = self._parse_property_name(fn() { self._parse_expression() })
  let type_parameters = self._parse_type_parameters()
  let parameters = self._parse_parameters(ParserSignatureFlags::none())
  let type_node = self._parse_return_type(_syntax_kind(59), false)
  let body = self._parse_function_block_or_semicolon(flags)
  let node = if is_get {
    _factory_create_get_accessor_declaration(
      modifiers, name, parameters, type_node, body,
    )
  } else {
    _factory_create_set_accessor_declaration(modifiers, name, parameters, body)
  }
  _parser_set_node_field(node, "typeParameters", NodeList(type_parameters))
  if !is_get {
    _parser_set_node_field(node, "type", NodeRef(type_node))
  }
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_class_static_block(self : ParserState) -> Node {
  let saved_yield = self._in_yield_context()
  let saved_await = self._in_await_context()
  self._set_yield_context(false)
  self._set_await_context(true)
  let block = self._parse_block(false)
  self._set_yield_context(saved_yield)
  self._set_await_context(saved_await)
  block
}

///|
fn ParserState::_parse_class_element(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  if self.current_token.to_int() == 27 {
    ignore(self._next_token())
    return self._finish_parser_node(
      _factory_create_semicolon_class_element(),
      pos,
    )
  }
  let modifiers = self._parse_modifiers(true, true, true)
  if self.current_token.to_int() == 126 &&
    self._look_ahead(fn() {
      ignore(self._next_token())
      if self.current_token.to_int() == 19 {
        Some(true)
      } else {
        None
      }
    })
    is Some(_) {
    ignore(self._parse_expected_token(_syntax_kind(126)))
    let node = self._finish_parser_node(
      _factory_create_class_static_block_declaration(
        self._parse_class_static_block(),
      ),
      pos,
    )
    _parser_set_node_field(node, "modifiers", NodeList(modifiers))
    return node
  }
  if self._parse_contextual_accessor_modifier(_syntax_kind(139)) {
    return self._parse_accessor_declaration(
      pos,
      modifiers,
      true,
      ParserSignatureFlags::none(),
    )
  }
  if self._parse_contextual_accessor_modifier(_syntax_kind(153)) {
    return self._parse_accessor_declaration(
      pos,
      modifiers,
      false,
      ParserSignatureFlags::none(),
    )
  }
  if self.current_token.to_int() == 137 || self.current_token.to_int() == 11 {
    match self._try_parse_constructor_declaration(pos, modifiers) {
      Some(constructor_node) => return constructor_node
      None => ()
    }
  }
  if self._is_index_signature() {
    return self._parse_index_signature_declaration(pos, modifiers)
  }
  let parse_member = fn() {
    self._parse_property_or_method_declaration(pos, modifiers)
  }
  if _parser_modifiers_contain_kind(modifiers, 138) {
    _parser_mark_modifiers_ambient(modifiers)
    self._do_inside_of_context(NodeFlags::ambient(), parse_member)
  } else if self._is_literal_property_name() ||
    self.current_token.to_int() == 42 ||
    self.current_token.to_int() == 23 ||
    self.current_token.to_int() == 81 {
    parse_member()
  } else {
    let missing = self._create_missing_parser_node(
      _syntax_kind(80),
      true,
      message=_diagnostic_message(1146),
    )
    self._parse_property_declaration(pos, modifiers, missing, None)
  }
}

///|
fn ParserState::_is_implements_clause(self : ParserState) -> Bool {
  self.current_token.to_int() == 119 &&
  self._look_ahead(fn() { self._next_token_is_identifier_or_keyword() })
  is Some(_)
}

///|
fn ParserState::_parse_expression_with_type_arguments(
  self : ParserState,
) -> Node {
  let pos = self._get_node_pos()
  let expression = self._parse_left_hand_side_expression_or_higher()
  if expression.kind().to_int() == 234 {
    return expression
  }
  let type_arguments = if self.current_token.to_int() == 30 {
    self._parse_bracketed_list(
      ParsingContext::type_arguments(),
      fn() { Some(self._parse_type()) },
      _syntax_kind(30),
      _syntax_kind(32),
    )
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_expression_with_type_arguments(expression, type_arguments),
    pos,
  )
}

///|
fn ParserState::_parse_heritage_clause(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let token = self.current_token
  ignore(self._next_token())
  let types = _parser_required_node_array(
    self._parse_delimited_list(ParsingContext::heritage_clause_element(), fn() {
      Some(self._parse_expression_with_type_arguments())
    }),
  )
  self._finish_parser_node(_factory_create_heritage_clause(token, types), pos)
}

///|
fn ParserState::_parse_heritage_clauses(self : ParserState) -> NodeArray? {
  if self.current_token.to_int() != 96 && self.current_token.to_int() != 119 {
    return None
  }
  Some(
    self._parse_list(ParsingContext::heritage_clauses(), fn() {
      self._parse_heritage_clause()
    }),
  )
}

///|
fn ParserState::_parse_class_members(self : ParserState) -> NodeArray {
  self._parse_list(ParsingContext::class_members(), fn() {
    self._parse_class_element()
  })
}

///|
fn ParserState::_parse_class_declaration_or_expression(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
  kind : Int,
) -> Node {
  let saved_await = self._in_await_context()
  ignore(self._parse_expected(_syntax_kind(86)))
  let name = if self._is_binding_identifier() && !self._is_implements_clause() {
    Some(self._parse_binding_identifier())
  } else {
    None
  }
  let type_parameters = self._parse_type_parameters()
  if _parser_modifiers_contain_kind(modifiers, 95) {
    self._set_await_context(true)
  }
  let heritage = self._parse_heritage_clauses()
  let members = if self._parse_expected(_syntax_kind(19)) {
    let members = self._parse_class_members()
    ignore(self._parse_expected(_syntax_kind(20)))
    members
  } else {
    self._create_missing_list()
  }
  self._set_await_context(saved_await)
  self._finish_parser_node(
    if kind == 264 {
      _factory_create_class_declaration(
        modifiers, name, type_parameters, heritage, members,
      )
    } else {
      _factory_create_class_expression(
        modifiers, name, type_parameters, heritage, members,
      )
    },
    pos,
  )
}

///|
fn ParserState::_parse_class_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  self._parse_class_declaration_or_expression(pos, modifiers, 264)
}

///|
fn ParserState::_parse_interface_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  ignore(self._parse_expected(_syntax_kind(120)))
  let name = self._parse_identifier()
  let type_parameters = self._parse_type_parameters()
  let heritage = self._parse_heritage_clauses()
  let members = self._parse_object_type_members()
  self._finish_parser_node(
    _factory_create_interface_declaration(
      modifiers, name, type_parameters, heritage, members,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_type_alias_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  ignore(self._parse_expected(_syntax_kind(156)))
  if self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    ignore(self._parse_error_at_current_token(_diagnostic_message(1142)))
  }
  let name = self._parse_identifier()
  let type_parameters = self._parse_type_parameters()
  ignore(self._parse_expected(_syntax_kind(64)))
  let type_node = self._parse_type()
  ignore(self._parse_semicolon())
  self._finish_parser_node(
    _factory_create_type_alias_declaration(
      modifiers, name, type_parameters, type_node,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_enum_member(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let name = self._parse_property_name(fn() { self._parse_expression() })
  let initializer = self._allow_in_and(fn() { self._parse_initializer() })
  self._finish_parser_node(_factory_create_enum_member(name, initializer), pos)
}

///|
fn ParserState::_parse_enum_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  ignore(self._parse_expected(_syntax_kind(94)))
  let name = self._parse_identifier()
  let members = if self._parse_expected(_syntax_kind(19)) {
    let members = self._do_outside_of_yield_and_await_context(fn() {
      _parser_required_node_array(
        self._parse_delimited_list(ParsingContext::enum_members(), fn() {
          Some(self._parse_enum_member())
        }),
      )
    })
    ignore(self._parse_expected(_syntax_kind(20)))
    members
  } else {
    self._create_missing_list()
  }
  self._finish_parser_node(
    _factory_create_enum_declaration(modifiers, name, members),
    pos,
  )
}

///|
fn ParserState::_parse_module_block(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let statements = if self._parse_expected(_syntax_kind(19)) {
    let statements = self._parse_list(ParsingContext::block_statements(), fn() {
      self._parse_statement()
    })
    ignore(self._parse_expected(_syntax_kind(20)))
    statements
  } else {
    self._create_missing_list()
  }
  self._finish_parser_node(_factory_create_module_block(statements), pos)
}

///|
fn ParserState::_parse_module_or_namespace_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
  flags : NodeFlags,
) -> Node {
  let nested = flags.contains(NodeFlags::nested_namespace())
  let name = if nested {
    self._parse_identifier_name()
  } else {
    self._parse_identifier()
  }
  let body = if self._parse_optional(_syntax_kind(25)) {
    Some(
      self._parse_module_or_namespace_declaration(
        self._get_node_pos(),
        None,
        NodeFlags::nested_namespace().union(
          flags.intersect(NodeFlags::namespace_flag()),
        ),
      ),
    )
  } else {
    Some(self._parse_module_block())
  }
  self._finish_parser_node(
    _factory_create_module_declaration(modifiers, name, body, flags~),
    pos,
  )
}

///|
fn ParserState::_parse_ambient_external_module(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  let mut flags = NodeFlags::none()
  let name = if self.current_token.to_int() == 162 {
    flags = flags.union(NodeFlags::global_augmentation())
    self._parse_identifier()
  } else {
    let literal = self._parse_literal_node()
    match literal.field("text") {
      Some(Text(Some(text))) =>
        _parser_set_node_field(
          literal,
          "text",
          Text(Some(self._intern_identifier(text))),
        )
      _ => ()
    }
    literal
  }
  let body = if self.current_token.to_int() == 19 {
    Some(self._parse_module_block())
  } else {
    ignore(self._parse_semicolon())
    None
  }
  self._finish_parser_node(
    _factory_create_module_declaration(modifiers, name, body, flags~),
    pos,
  )
}

///|
fn ParserState::_parse_module_declaration(
  self : ParserState,
  pos : Int,
  modifiers : NodeArray?,
) -> Node {
  if self.current_token.to_int() == 162 {
    return self._parse_ambient_external_module(pos, modifiers)
  }
  let mut flags = NodeFlags::none()
  if self._parse_optional(_syntax_kind(145)) {
    flags = flags.union(NodeFlags::namespace_flag())
  } else {
    ignore(self._parse_expected(_syntax_kind(144)))
    if self.current_token.to_int() == 11 {
      return self._parse_ambient_external_module(pos, modifiers)
    }
  }
  self._parse_module_or_namespace_declaration(pos, modifiers, flags)
}
