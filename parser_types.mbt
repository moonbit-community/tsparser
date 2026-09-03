// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn ParserState::_parse_type_arguments_of_type_reference(
  self : ParserState,
) -> NodeArray? {
  if self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    return None
  }
  if self._re_scan_less_than_token().to_int() != 30 {
    return None
  }
  self._parse_bracketed_list(
    ParsingContext::type_arguments(),
    fn() { Some(self._parse_type()) },
    _syntax_kind(30),
    _syntax_kind(32),
  )
}

///|
fn ParserState::_parse_type_reference(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let type_name = self._parse_entity_name_of_type_reference()
  let type_arguments = self._parse_type_arguments_of_type_reference()
  self._finish_parser_node(
    _factory_create_type_reference_node(type_name, type_arguments),
    pos,
  )
}

///|
fn ParserState::_parse_this_type_node(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._next_token())
  self._finish_parser_node(_factory_create_this_type_node(), pos)
}

///|
fn ParserState::_parse_this_type_predicate(
  self : ParserState,
  this_type : Node,
) -> Node {
  ignore(self._next_token())
  self._finish_parser_node(
    _factory_create_type_predicate_node(
      None,
      this_type,
      Some(self._parse_type()),
    ),
    this_type.pos(),
  )
}

///|
fn ParserState::_parse_type_query(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(114)))
  let expression_name = self._parse_entity_name(true)
  let type_arguments = if !self.scanner._has_flag(
      TokenFlags::preceding_line_break(),
    ) {
    self._parse_type_arguments_of_type_reference()
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_type_query_node(expression_name, type_arguments),
    pos,
  )
}

///|
fn ParserState::_parse_type_literal(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  self._finish_parser_node(
    _factory_create_type_literal_node(Some(self._parse_object_type_members())),
    pos,
  )
}

///|
fn ParserState::_is_start_of_mapped_type_worker(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 40 || self.current_token.to_int() == 41 {
    ignore(self._next_token())
    guard self.current_token.to_int() == 148 else { return None }
  }
  if self.current_token.to_int() == 148 {
    ignore(self._next_token())
  }
  guard self.current_token.to_int() == 23 else { return None }
  ignore(self._next_token())
  guard self._is_identifier() else { return None }
  ignore(self._next_token())
  if self.current_token.to_int() == 103 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_is_start_of_mapped_type(self : ParserState) -> Bool {
  self._look_ahead(fn() { self._is_start_of_mapped_type_worker() }) is Some(_)
}

///|
fn ParserState::_parse_mapped_type_parameter(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let name = self._parse_identifier_name()
  ignore(self._parse_expected(_syntax_kind(103)))
  let constraint = self._parse_type()
  self._finish_parser_node(
    _factory_create_type_parameter_declaration(
      None,
      name,
      Some(constraint),
      None,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_mapped_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(19)))
  let readonly_token = if self.current_token.to_int() == 148 ||
    self.current_token.to_int() == 40 ||
    self.current_token.to_int() == 41 {
    let token = self._parse_token_node()
    if token.kind().to_int() != 148 {
      ignore(self._parse_expected(_syntax_kind(148)))
    }
    Some(token)
  } else {
    None
  }
  ignore(self._parse_expected(_syntax_kind(23)))
  let type_parameter = self._parse_mapped_type_parameter()
  let name_type = if self._parse_optional(_syntax_kind(130)) {
    Some(self._parse_type())
  } else {
    None
  }
  ignore(self._parse_expected(_syntax_kind(24)))
  let question_token = if self.current_token.to_int() == 58 ||
    self.current_token.to_int() == 40 ||
    self.current_token.to_int() == 41 {
    let token = self._parse_token_node()
    if token.kind().to_int() != 58 {
      ignore(self._parse_expected(_syntax_kind(58)))
    }
    Some(token)
  } else {
    None
  }
  let type_node = self._parse_type_annotation()
  ignore(self._parse_semicolon())
  let members = self._parse_list(ParsingContext::type_members(), fn() {
    self._parse_type_member()
  })
  ignore(self._parse_expected(_syntax_kind(20)))
  self._finish_parser_node(
    _factory_create_mapped_type_node(
      readonly_token,
      type_parameter,
      name_type,
      question_token,
      type_node,
      Some(members),
    ),
    pos,
  )
}

///|
fn ParserState::_parse_tuple_element_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  if self._parse_optional(_syntax_kind(26)) {
    return self._finish_parser_node(
      _factory_create_rest_type_node(self._parse_type()),
      pos,
    )
  }
  let type_node = self._parse_type()
  if type_node.kind().to_int() == 315 && type_node.pos() == pos {
    match type_node.field("type") {
      Some(NodeRef(Some(inner))) if inner.pos() == type_node.pos() => {
        let optional = _factory_create_optional_type_node(inner)
        optional._set_text_range(type_node.pos(), type_node.end())
        optional._set_flags(type_node.flags())
        return optional
      }
      _ => ()
    }
  }
  type_node
}

///|
fn ParserState::_is_next_token_colon_or_question_colon(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 59 {
    return Some(true)
  }
  guard self.current_token.to_int() == 58 else { return None }
  ignore(self._next_token())
  if self.current_token.to_int() == 59 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_is_tuple_element_name_worker(self : ParserState) -> Bool? {
  if self.current_token.to_int() == 26 {
    ignore(self._next_token())
    guard _parser_token_is_identifier_or_keyword(self.current_token) else {
      return None
    }
    return self._is_next_token_colon_or_question_colon()
  }
  guard _parser_token_is_identifier_or_keyword(self.current_token) else {
    return None
  }
  self._is_next_token_colon_or_question_colon()
}

///|
fn ParserState::_parse_tuple_element_name_or_type(self : ParserState) -> Node {
  if self._look_ahead(fn() { self._is_tuple_element_name_worker() }) is Some(_) {
    let pos = self._get_node_pos()
    let dot_dot_dot = self._parse_optional_token(_syntax_kind(26))
    let name = self._parse_identifier_name()
    let question = self._parse_optional_token(_syntax_kind(58))
    ignore(self._parse_expected(_syntax_kind(59)))
    let type_node = self._parse_tuple_element_type()
    return self._finish_parser_node(
      _factory_create_named_tuple_member(dot_dot_dot, name, question, type_node),
      pos,
    )
  }
  self._parse_tuple_element_type()
}

///|
fn ParserState::_parse_tuple_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let elements = _parser_required_node_array(
    self._parse_bracketed_list(
      ParsingContext::tuple_element_types(),
      fn() { Some(self._parse_tuple_element_name_or_type()) },
      _syntax_kind(23),
      _syntax_kind(24),
    ),
  )
  self._finish_parser_node(_factory_create_tuple_type_node(elements), pos)
}

///|
fn ParserState::_parse_parenthesized_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(21)))
  let type_node = self._parse_type()
  ignore(self._parse_expected(_syntax_kind(22)))
  self._finish_parser_node(_factory_create_parenthesized_type(type_node), pos)
}

///|
fn ParserState::_parse_modifiers_for_constructor_type(
  self : ParserState,
) -> NodeArray? {
  if self.current_token.to_int() != 128 {
    return None
  }
  let pos = self._get_node_pos()
  let modifier = self._parse_token_node()
  Some(self._create_parser_node_array([modifier], pos))
}

///|
fn ParserState::_skip_parameter_start(self : ParserState) -> Bool {
  if _parser_is_modifier_kind(self.current_token) {
    ignore(self._parse_modifiers(false, false, false))
  }
  if self._is_identifier() || self.current_token.to_int() == 110 {
    ignore(self._next_token())
    return true
  }
  if self.current_token.to_int() == 23 || self.current_token.to_int() == 19 {
    let previous_error_count = self.diagnostics.length()
    ignore(self._parse_identifier_or_pattern())
    return previous_error_count == self.diagnostics.length()
  }
  false
}

///|
fn ParserState::_is_unambiguously_start_of_function_type(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 22 || self.current_token.to_int() == 26 {
    return Some(true)
  }
  guard self._skip_parameter_start() else { return None }
  match self.current_token.to_int() {
    28 | 58 | 59 | 64 => Some(true)
    22 => {
      ignore(self._next_token())
      if self.current_token.to_int() == 39 {
        Some(true)
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn ParserState::_is_start_of_function_or_constructor_type(
  self : ParserState,
) -> Bool {
  if self.current_token.to_int() == 30 {
    return true
  }
  if self.current_token.to_int() == 21 {
    return self._look_ahead(fn() {
        self._is_unambiguously_start_of_function_type()
      })
      is Some(_)
  }
  if self.current_token.to_int() == 105 {
    return true
  }
  self.current_token.to_int() == 128 &&
  self._look_ahead(fn() {
    ignore(self._next_token())
    if self.current_token.to_int() == 105 {
      Some(true)
    } else {
      None
    }
  })
  is Some(_)
}

///|
fn ParserState::_parse_function_or_constructor_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let modifiers = self._parse_modifiers_for_constructor_type()
  let is_constructor = self._parse_optional(_syntax_kind(105))
  let type_parameters = self._parse_type_parameters()
  let parameters = self._parse_parameters(ParserSignatureFlags::type_flag())
  let type_node = match self._parse_return_type(_syntax_kind(39), false) {
    Some(type_node) => type_node
    None =>
      self._create_missing_parser_node(
        _syntax_kind(184),
        false,
        message=_diagnostic_message(1110),
      )
  }
  let node = if is_constructor {
    _factory_create_constructor_type_node(
      modifiers, type_parameters, parameters, type_node,
    )
  } else {
    _factory_create_function_type_node(type_parameters, parameters, type_node)
  }
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_literal_type_node(
  self : ParserState,
  negative : Bool,
) -> Node {
  let pos = self._get_node_pos()
  let operator = self.current_token
  if negative {
    ignore(self._next_token())
  }
  let mut expression = if self.current_token.to_int() == 97 ||
    self.current_token.to_int() == 106 ||
    self.current_token.to_int() == 112 {
    self._parse_token_node()
  } else {
    self._parse_literal_like_node(self.current_token)
  }
  if negative {
    expression = self._finish_parser_node(
      _factory_create_prefix_unary_expression(operator, expression),
      pos,
    )
  }
  self._finish_parser_node(_factory_create_literal_type_node(expression), pos)
}

///|
fn ParserState::_parse_import_attribute(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let name = if _parser_token_is_identifier_or_keyword(self.current_token) {
    self._parse_identifier_name()
  } else {
    self._parse_literal_like_node(_syntax_kind(11))
  }
  ignore(self._parse_expected(_syntax_kind(59)))
  let value = self._parse_assignment_expression_or_higher(true)
  self._finish_parser_node(_factory_create_import_attribute(name, value), pos)
}

///|
fn ParserState::_parse_import_attributes(
  self : ParserState,
  token : SyntaxKind,
  skip_keyword : Bool,
) -> Node {
  let pos = self._get_node_pos()
  if !skip_keyword {
    ignore(self._parse_expected(token))
  }
  let open_pos = self.scanner._token_start()
  if !self._parse_expected(_syntax_kind(19)) {
    return self._finish_parser_node(
      _factory_create_import_attributes(
        self._create_parser_node_array([], self._get_node_pos()),
        multi_line=false,
        token~,
      ),
      pos,
    )
  }
  let multi_line = self.scanner._has_flag(TokenFlags::preceding_line_break())
  let elements = _parser_required_node_array(
    self._parse_delimited_list(
      ParsingContext::import_attributes(),
      fn() { Some(self._parse_import_attribute()) },
      consider_semicolon_as_delimiter=true,
    ),
  )
  self._parse_expected_matching_brackets(
    _syntax_kind(19),
    _syntax_kind(20),
    true,
    open_pos,
  )
  self._finish_parser_node(
    _factory_create_import_attributes(elements, multi_line~, token~),
    pos,
  )
}

///|
fn ParserState::_parse_import_type(self : ParserState) -> Node {
  self.source_flags = self.source_flags.union(
    NodeFlags::possibly_contains_dynamic_import(),
  )
  let pos = self._get_node_pos()
  let is_type_of = self._parse_optional(_syntax_kind(114))
  ignore(self._parse_expected(_syntax_kind(102)))
  ignore(self._parse_expected(_syntax_kind(21)))
  let argument = self._parse_type()
  let attributes = if self._parse_optional(_syntax_kind(28)) {
    let open_pos = self.scanner._token_start()
    ignore(self._parse_expected(_syntax_kind(19)))
    let attribute_token = if self.current_token.to_int() == 118 ||
      self.current_token.to_int() == 132 {
      let token = self.current_token
      ignore(self._next_token())
      token
    } else {
      ignore(
        self._parse_error_at_current_token(
          _diagnostic_message(1005),
          arguments=_parser_text_arguments("with"),
        ),
      )
      _syntax_kind(118)
    }
    ignore(self._parse_expected(_syntax_kind(59)))
    let result = self._parse_import_attributes(attribute_token, true)
    ignore(self._parse_optional(_syntax_kind(28)))
    if !self._parse_expected(_syntax_kind(20)) && !self.diagnostics.is_empty() {
      let diagnostic_index = self.diagnostics.length() - 1
      let diagnostic = self.diagnostics[diagnostic_index]
      if diagnostic.code() == 1005 {
        let related = _create_detached_diagnostic(
          self.file_name,
          self.source_text,
          open_pos,
          1,
          _diagnostic_message(1007),
          _parser_two_text_arguments("{", "}"),
        )
        self.diagnostics[diagnostic_index] = _add_related_information(
          diagnostic,
          ReadOnlyArray::from_array([related]),
        )
      }
    }
    Some(result)
  } else {
    None
  }
  ignore(self._parse_expected(_syntax_kind(22)))
  let qualifier = if self._parse_optional(_syntax_kind(25)) {
    Some(self._parse_entity_name_of_type_reference())
  } else {
    None
  }
  let type_arguments = self._parse_type_arguments_of_type_reference()
  self._finish_parser_node(
    _factory_create_import_type_node(
      argument,
      attributes,
      qualifier,
      type_arguments,
      is_type_of~,
    ),
    pos,
  )
}

///|
fn ParserState::_parse_non_array_type(self : ParserState) -> Node {
  match self.current_token.to_int() {
    133 | 136 | 146 | 150 | 151 | 154 | 155 | 157 | 159 | 163 => {
      let keyword = self._try_parse(fn() -> Node? {
        let token = self._parse_token_node()
        if self.current_token.to_int() == 25 {
          None
        } else {
          Some(token)
        }
      })
      match keyword {
        Some(keyword) => keyword
        None => self._parse_type_reference()
      }
    }
    67 => {
      ignore(self._re_scan_asterisk_equals_token())
      self._parse_non_array_type()
    }
    42 => {
      let pos = self._get_node_pos()
      ignore(self._next_token())
      self._finish_parser_node(_factory_create_jsdoc_all_type(), pos)
    }
    61 => {
      ignore(self._re_scan_question_token())
      self._parse_non_array_type()
    }
    58 => {
      let pos = self._get_node_pos()
      ignore(self._next_token())
      match self.current_token.to_int() {
        20 | 22 | 28 | 32 | 52 | 64 =>
          self._finish_parser_node(_factory_create_jsdoc_unknown_type(), pos)
        _ =>
          self._finish_parser_node(
            _factory_create_jsdoc_nullable_type(Some(self._parse_type())),
            pos,
          )
      }
    }
    54 => {
      let pos = self._get_node_pos()
      ignore(self._next_token())
      self._finish_parser_node(
        _factory_create_jsdoc_non_nullable_type(
          Some(self._parse_non_array_type()),
        ),
        pos,
      )
    }
    9 | 10 | 11 | 15 | 97 | 106 | 112 => self._parse_literal_type_node(false)
    41 => {
      let negative = self._look_ahead(fn() {
          ignore(self._next_token())
          if self.current_token.to_int() == 9 ||
            self.current_token.to_int() == 10 {
            Some(true)
          } else {
            None
          }
        })
        is Some(_)
      if negative {
        self._parse_literal_type_node(true)
      } else {
        self._parse_type_reference()
      }
    }
    116 => self._parse_token_node()
    110 => {
      let this_type = self._parse_this_type_node()
      if self.current_token.to_int() == 142 &&
        !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
        self._parse_this_type_predicate(this_type)
      } else {
        this_type
      }
    }
    100 => self._parse_jsdoc_function_type()
    114 => {
      let is_import = self._look_ahead(fn() {
          ignore(self._next_token())
          if self.current_token.to_int() == 102 {
            Some(true)
          } else {
            None
          }
        })
        is Some(_)
      if is_import {
        self._parse_import_type()
      } else {
        self._parse_type_query()
      }
    }
    19 =>
      if self._is_start_of_mapped_type() {
        self._parse_mapped_type()
      } else {
        self._parse_type_literal()
      }
    23 => self._parse_tuple_type()
    21 => self._parse_parenthesized_type()
    102 => self._parse_import_type()
    131 => {
      let predicate = self._look_ahead(fn() {
          self._next_token_is_identifier_or_keyword_on_same_line()
        })
        is Some(_)
      if predicate {
        self._parse_asserts_type_predicate()
      } else {
        self._parse_type_reference()
      }
    }
    16 => self._parse_template_type()
    _ => self._parse_type_reference()
  }
}

///|
fn ParserState::_parse_postfix_type_or_higher(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let mut type_node = self._parse_non_array_type()
  while !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    match self.current_token.to_int() {
      54 => {
        ignore(self._next_token())
        type_node = self._finish_parser_node(
          _factory_create_jsdoc_non_nullable_type(Some(type_node), postfix=true),
          pos,
        )
      }
      58 => {
        let starts_type = self._look_ahead(fn() {
            self._next_token_is_start_of_type()
          })
          is Some(_)
        if starts_type {
          return type_node
        }
        ignore(self._next_token())
        type_node = self._finish_parser_node(
          _factory_create_jsdoc_nullable_type(Some(type_node), postfix=true),
          pos,
        )
      }
      23 => {
        ignore(self._parse_expected(_syntax_kind(23)))
        if self._is_start_of_type(false) {
          let index_type = self._parse_type()
          ignore(self._parse_expected(_syntax_kind(24)))
          type_node = self._finish_parser_node(
            _factory_create_indexed_access_type_node(type_node, index_type),
            pos,
          )
        } else {
          ignore(self._parse_expected(_syntax_kind(24)))
          type_node = self._finish_parser_node(
            _factory_create_array_type_node(type_node),
            pos,
          )
        }
      }
      _ => return type_node
    }
  }
  type_node
}

///|
fn ParserState::_parse_type_operator(
  self : ParserState,
  operator : SyntaxKind,
) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(operator))
  self._finish_parser_node(
    _factory_create_type_operator_node(
      operator,
      self._parse_type_operator_or_higher(),
    ),
    pos,
  )
}

///|
fn ParserState::_try_parse_constraint_of_infer_type(
  self : ParserState,
) -> Node? {
  guard self._parse_optional(_syntax_kind(96)) else { return None }
  let constraint = self._disallow_conditional_types_and(fn() {
    self._parse_type()
  })
  if self._in_disallow_conditional_types_context() ||
    self.current_token.to_int() != 58 {
    Some(constraint)
  } else {
    None
  }
}

///|
fn ParserState::_parse_type_parameter_of_infer_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let name = self._parse_identifier()
  let constraint = self._try_parse(fn() {
    self._try_parse_constraint_of_infer_type()
  })
  self._finish_parser_node(
    _factory_create_type_parameter_declaration(None, name, constraint, None),
    pos,
  )
}

///|
fn ParserState::_parse_infer_type(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(140)))
  self._finish_parser_node(
    _factory_create_infer_type_node(self._parse_type_parameter_of_infer_type()),
    pos,
  )
}

///|
fn ParserState::_parse_type_operator_or_higher(self : ParserState) -> Node {
  match self.current_token.to_int() {
    143 | 148 | 158 => self._parse_type_operator(self.current_token)
    140 => self._parse_infer_type()
    _ =>
      self._allow_conditional_types_and(fn() {
        self._parse_postfix_type_or_higher()
      })
  }
}

///|
fn ParserState::_parse_function_or_constructor_type_to_error(
  self : ParserState,
  is_union : Bool,
) -> Node? {
  guard self._is_start_of_function_or_constructor_type() else { return None }
  let type_node = self._parse_function_or_constructor_type()
  let code = if type_node.kind().to_int() == 185 {
    if is_union {
      1385
    } else {
      1387
    }
  } else if is_union {
    1386
  } else {
    1388
  }
  ignore(
    self._parse_error_at_range(
      TextRange::new(type_node.pos(), end=type_node.end()),
      _diagnostic_message(code),
    ),
  )
  Some(type_node)
}

///|
fn ParserState::_parse_union_or_intersection_type(
  self : ParserState,
  operator : SyntaxKind,
  parse_constituent : () -> Node,
) -> Node {
  let pos = self._get_node_pos()
  let is_union = operator.to_int() == 52
  let has_leading = self._parse_optional(operator)
  let mut type_node = if has_leading {
    match self._parse_function_or_constructor_type_to_error(is_union) {
      Some(type_node) => type_node
      None => parse_constituent()
    }
  } else {
    parse_constituent()
  }
  if self.current_token == operator || has_leading {
    let types : Array[Node] = [type_node]
    while self._parse_optional(operator) {
      match self._parse_function_or_constructor_type_to_error(is_union) {
        Some(type_node) => types.push(type_node)
        None => types.push(parse_constituent())
      }
    }
    let list = self._create_parser_node_array(types, pos)
    type_node = self._finish_parser_node(
      if is_union {
        _factory_create_union_type_node(list)
      } else {
        _factory_create_intersection_type_node(list)
      },
      pos,
    )
  }
  type_node
}

///|
fn ParserState::_parse_intersection_type_or_higher(self : ParserState) -> Node {
  self._parse_union_or_intersection_type(_syntax_kind(51), fn() {
    self._parse_type_operator_or_higher()
  })
}

///|
fn ParserState::_parse_union_type_or_higher(self : ParserState) -> Node {
  self._parse_union_or_intersection_type(_syntax_kind(52), fn() {
    self._parse_intersection_type_or_higher()
  })
}

///|
fn ParserState::_parse_type(self : ParserState) -> Node {
  if self._in_context(NodeFlags::type_excludes_flags()) {
    return self._do_outside_of_context(NodeFlags::type_excludes_flags(), fn() {
      self._parse_type()
    })
  }
  if self._is_start_of_function_or_constructor_type() {
    return self._parse_function_or_constructor_type()
  }
  let pos = self._get_node_pos()
  let check_type = self._parse_union_type_or_higher()
  if !self._in_disallow_conditional_types_context() &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) &&
    self._parse_optional(_syntax_kind(96)) {
    let extends_type = self._disallow_conditional_types_and(fn() {
      self._parse_type()
    })
    ignore(self._parse_expected(_syntax_kind(58)))
    let true_type = self._allow_conditional_types_and(fn() {
      self._parse_type()
    })
    ignore(self._parse_expected(_syntax_kind(59)))
    let false_type = self._allow_conditional_types_and(fn() {
      self._parse_type()
    })
    return self._finish_parser_node(
      _factory_create_conditional_type_node(
        check_type, extends_type, true_type, false_type,
      ),
      pos,
    )
  }
  check_type
}

///|
fn _parse_type_for_test(text : String) -> (Node, Array[Diagnostic], SyntaxKind) {
  let state = _new_parser_state("type.ts", text)
  ignore(state._prime())
  let node = state._parse_type()
  let diagnostics = state.diagnostics.copy()
  let token = state.current_token
  state._dispose()
  (node, diagnostics, token)
}
