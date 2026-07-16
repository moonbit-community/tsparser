// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _parser_node_field_node(node : Node, name : String) -> Node? {
  match node.field(name) {
    Some(NodeRef(value)) => value
    _ => None
  }
}

///|
fn _parser_node_field_list(node : Node, name : String) -> NodeArray? {
  match node.field(name) {
    Some(NodeList(value)) => value
    _ => None
  }
}

///|
fn _parser_insert_node_field_after(
  node : Node,
  after : String,
  name : String,
  value : NodeFieldValue,
) -> Unit {
  let fields : Array[NodeField] = []
  let mut inserted = false
  for field in node.fields() {
    if field.name() == name {
      abort("parser attempted to add an existing node field")
    }
    fields.push(field)
    if field.name() == after {
      fields.push(_node_field(name, value))
      inserted = true
    }
  }
  guard inserted else { abort("parser field insertion anchor is absent") }
  node._set_fields(fields)
}

///|
fn ParserState::_next_token_is_open_paren_or_less_than(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 21 || self.current_token.to_int() == 30 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_dot(self : ParserState) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 25 {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_function_keyword_on_same_line(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if self.current_token.to_int() == 100 &&
    !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_next_token_is_identifier_or_keyword_or_open_bracket_or_template(
  self : ParserState,
) -> Bool? {
  ignore(self._next_token())
  if _parser_token_is_identifier_or_keyword(self.current_token) ||
    self.current_token.to_int() == 23 ||
    self._is_template_start_of_tagged_template() {
    Some(true)
  } else {
    None
  }
}

///|
fn ParserState::_is_start_of_optional_property_or_element_access_chain(
  self : ParserState,
) -> Bool {
  self.current_token.to_int() == 29 &&
  self._look_ahead(fn() {
    self._next_token_is_identifier_or_keyword_or_open_bracket_or_template()
  })
  is Some(_)
}

///|
fn _parser_node_is_optional_chain(node : Node) -> Bool {
  node.flags().contains(NodeFlags::optional_chain())
}

///|
fn _parser_try_reparse_optional_chain(node : Node) -> Bool {
  if _parser_node_is_optional_chain(node) {
    return true
  }
  guard node.kind().to_int() == 236 else { return false }
  let mut inner = match _parser_node_field_node(node, "expression") {
    Some(inner) => inner
    None => return false
  }
  while inner.kind().to_int() == 236 && !_parser_node_is_optional_chain(inner) {
    match _parser_node_field_node(inner, "expression") {
      Some(next) => inner = next
      None => return false
    }
  }
  guard _parser_node_is_optional_chain(inner) else { return false }
  let mut current = node
  while current.kind().to_int() == 236 {
    current._add_flags(NodeFlags::optional_chain())
    match _parser_node_field_node(current, "expression") {
      Some(next) => current = next
      None => break
    }
  }
  true
}

///|
fn ParserState::_parse_property_access_expression_rest(
  self : ParserState,
  pos : Int,
  expression : Node,
  question_dot : Node?,
) -> Node {
  let name = self._parse_right_side_of_dot(true, true, true)
  let optional_chain = question_dot is Some(_) ||
    _parser_try_reparse_optional_chain(expression)
  let property = if optional_chain {
    _factory_create_property_access_chain(expression, question_dot, name)
  } else {
    _factory_create_property_access_expression(expression, name)
  }
  if optional_chain && name.kind().to_int() == 81 {
    ignore(
      self._parse_error_at_range(
        TextRange::new(name.pos(), end=name.end()),
        _diagnostic_message(18030),
      ),
    )
  }
  if expression.kind().to_int() == 234 {
    match _parser_node_field_list(expression, "typeArguments") {
      Some(arguments) => {
        let source = SourceText::new(self.source_text)
        let start = arguments.pos() - 1
        let after = skip_trivia(source, arguments.end()) + 1
        let end = if after > source.length() { source.length() } else { after }
        ignore(self._parse_error_at(start, end, _diagnostic_message(1477)))
      }
      None => ()
    }
  }
  self._finish_parser_node(property, pos)
}

///|
fn ParserState::_parse_element_access_expression_rest(
  self : ParserState,
  pos : Int,
  expression : Node,
  question_dot : Node?,
) -> Node {
  let argument = if self.current_token.to_int() == 24 {
    self._create_missing_parser_node(
      _syntax_kind(80),
      true,
      message=_diagnostic_message(1011),
    )
  } else {
    self._allow_in_and(fn() { self._parse_expression() })
  }
  if argument.kind().to_int() == 9 ||
    argument.kind().to_int() == 10 ||
    argument.kind().to_int() == 11 {
    match argument.field("text") {
      Some(Text(Some(text))) =>
        _parser_set_node_field(
          argument,
          "text",
          Text(Some(self._intern_identifier(text))),
        )
      _ => ()
    }
  }
  ignore(self._parse_expected(_syntax_kind(24)))
  let optional_chain = question_dot is Some(_) ||
    _parser_try_reparse_optional_chain(expression)
  self._finish_parser_node(
    if optional_chain {
      _factory_create_element_access_chain(expression, question_dot, argument)
    } else {
      _factory_create_element_access_expression(expression, argument)
    },
    pos,
  )
}

///|
fn ParserState::_is_template_start_of_tagged_template(
  self : ParserState,
) -> Bool {
  self.current_token.to_int() == 15 || self.current_token.to_int() == 16
}

///|
fn ParserState::_parse_tagged_template_rest(
  self : ParserState,
  pos : Int,
  tag : Node,
  question_dot : Node?,
  type_arguments : NodeArray?,
) -> Node {
  let template = if self.current_token.to_int() == 15 {
    ignore(self._re_scan_template_token(true))
    self._parse_literal_node()
  } else {
    self._parse_template_expression_with(true, fn() { self._parse_expression() })
  }
  let node = _factory_create_tagged_template_expression(
    tag, type_arguments, template,
  )
  if question_dot is Some(_) || _parser_node_is_optional_chain(tag) {
    node._add_flags(NodeFlags::optional_chain())
  }
  _parser_insert_node_field_after(
    node,
    "tag",
    "questionDotToken",
    NodeRef(question_dot),
  )
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_member_expression_rest(
  self : ParserState,
  pos : Int,
  initial_expression : Node,
  allow_optional_chain : Bool,
) -> Node {
  let mut expression = initial_expression
  while true {
    let mut question_dot : Node? = None
    let mut property_access = false
    if allow_optional_chain &&
      self._is_start_of_optional_property_or_element_access_chain() {
      question_dot = Some(self._parse_expected_token(_syntax_kind(29)))
      property_access = _parser_token_is_identifier_or_keyword(
        self.current_token,
      )
    } else {
      property_access = self._parse_optional(_syntax_kind(25))
    }
    if property_access {
      expression = self._parse_property_access_expression_rest(
        pos, expression, question_dot,
      )
      continue
    }
    if (question_dot is Some(_) || !self._in_decorator_context()) &&
      self._parse_optional(_syntax_kind(23)) {
      expression = self._parse_element_access_expression_rest(
        pos, expression, question_dot,
      )
      continue
    }
    if self._is_template_start_of_tagged_template() {
      if question_dot is None && expression.kind().to_int() == 234 {
        let tag = match _parser_node_field_node(expression, "expression") {
          Some(tag) => tag
          None => expression
        }
        expression = self._parse_tagged_template_rest(
          pos,
          tag,
          None,
          _parser_node_field_list(expression, "typeArguments"),
        )
      } else {
        expression = self._parse_tagged_template_rest(
          pos,
          expression,
          question_dot,
          None,
        )
      }
      continue
    }
    if question_dot is None {
      if self.current_token.to_int() == 54 &&
        !self.scanner._has_flag(TokenFlags::preceding_line_break()) {
        ignore(self._next_token())
        expression = self._finish_parser_node(
          _factory_create_non_null_expression(expression),
          pos,
        )
        continue
      }
      match
        self._try_parse(fn() { self._parse_type_arguments_in_expression() }) {
        Some(type_arguments) => {
          expression = self._finish_parser_node(
            _factory_create_expression_with_type_arguments(
              expression,
              Some(type_arguments),
            ),
            pos,
          )
          continue
        }
        None => ()
      }
    }
    return expression
  }
  expression
}

///|
fn ParserState::_parse_argument_or_array_literal_element(
  self : ParserState,
) -> Node {
  if self.current_token.to_int() == 26 {
    return self._parse_spread_element()
  }
  if self.current_token.to_int() == 28 {
    return self._finish_parser_node(
      _factory_create_omitted_expression(),
      self._get_node_pos(),
    )
  }
  self._parse_assignment_expression_or_higher(true)
}

///|
fn ParserState::_parse_argument_expression(self : ParserState) -> Node {
  self._do_outside_of_context(
    NodeFlags::disallow_in_context().union(NodeFlags::decorator_context()),
    fn() { self._parse_argument_or_array_literal_element() },
  )
}

///|
fn ParserState::_parse_argument_list(self : ParserState) -> NodeArray {
  ignore(self._parse_expected(_syntax_kind(21)))
  let arguments = _parser_required_node_array(
    self._parse_delimited_list(ParsingContext::argument_expressions(), fn() {
      Some(self._parse_argument_expression())
    }),
  )
  ignore(self._parse_expected(_syntax_kind(22)))
  arguments
}

///|
fn ParserState::_can_follow_type_arguments_in_expression(
  self : ParserState,
) -> Bool {
  match self.current_token.to_int() {
    21 | 15 | 16 => true
    30 | 32 | 40 | 41 => false
    _ =>
      self.scanner._has_flag(TokenFlags::preceding_line_break()) ||
      _parser_is_binary_operator(self.current_token) ||
      !self._is_start_of_expression()
  }
}

///|
fn ParserState::_parse_type_arguments_in_expression(
  self : ParserState,
) -> NodeArray? {
  if self.context_flags.contains(NodeFlags::javascript_file()) {
    return None
  }
  guard self._re_scan_less_than_token().to_int() == 30 else { return None }
  ignore(self._next_token())
  let arguments = self._parse_delimited_list(ParsingContext::type_arguments(), fn() {
    Some(self._parse_type())
  })
  guard self._re_scan_greater_token().to_int() == 32 else { return None }
  ignore(self._next_token())
  match arguments {
    Some(arguments) if self._can_follow_type_arguments_in_expression() =>
      Some(arguments)
    _ => None
  }
}

///|
fn ParserState::_parse_call_expression_rest(
  self : ParserState,
  pos : Int,
  initial_expression : Node,
) -> Node {
  let mut expression = initial_expression
  while true {
    expression = self._parse_member_expression_rest(pos, expression, true)
    let mut type_arguments : NodeArray? = None
    let question_dot = self._parse_optional_token(_syntax_kind(29))
    if question_dot is Some(_) {
      type_arguments = self._try_parse(fn() {
        self._parse_type_arguments_in_expression()
      })
      if self._is_template_start_of_tagged_template() {
        expression = self._parse_tagged_template_rest(
          pos, expression, question_dot, type_arguments,
        )
        continue
      }
    }
    if type_arguments is Some(_) || self.current_token.to_int() == 21 {
      if question_dot is None && expression.kind().to_int() == 234 {
        type_arguments = _parser_node_field_list(expression, "typeArguments")
        match _parser_node_field_node(expression, "expression") {
          Some(inner) => expression = inner
          None => ()
        }
      }
      let arguments = self._parse_argument_list()
      let optional_chain = question_dot is Some(_) ||
        _parser_try_reparse_optional_chain(expression)
      expression = self._finish_parser_node(
        if optional_chain {
          _factory_create_call_chain(
            expression,
            question_dot,
            type_arguments,
            Some(arguments),
          )
        } else {
          _factory_create_call_expression(
            expression,
            type_arguments,
            Some(arguments),
          )
        },
        pos,
      )
      continue
    }
    match question_dot {
      Some(question_dot) => {
        let name = self._create_missing_parser_node(
          _syntax_kind(80),
          false,
          message=_diagnostic_message(1003),
        )
        expression = self._finish_parser_node(
          _factory_create_property_access_chain(
            expression,
            Some(question_dot),
            name,
          ),
          pos,
        )
      }
      None => ()
    }
    break
  }
  expression
}

///|
fn ParserState::_parse_super_expression(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let mut expression = self._parse_token_node()
  if self.current_token.to_int() == 30 {
    let start = self._get_node_pos()
    match self._try_parse(fn() { self._parse_type_arguments_in_expression() }) {
      Some(type_arguments) => {
        ignore(
          self._parse_error_at(
            start,
            self._get_node_pos(),
            _diagnostic_message(2754),
          ),
        )
        if !self._is_template_start_of_tagged_template() {
          expression = _factory_create_expression_with_type_arguments(
            expression,
            Some(type_arguments),
          )
        }
      }
      None => ()
    }
  }
  if self.current_token.to_int() == 21 ||
    self.current_token.to_int() == 25 ||
    self.current_token.to_int() == 23 {
    return expression
  }
  ignore(
    self._parse_expected_token(
      _syntax_kind(25),
      message=_diagnostic_message(1034),
    ),
  )
  self._finish_parser_node(
    _factory_create_property_access_expression(
      expression,
      self._parse_right_side_of_dot(true, true, true),
    ),
    pos,
  )
}

///|
fn ParserState::_parse_left_hand_side_expression_or_higher(
  self : ParserState,
) -> Node {
  let pos = self._get_node_pos()
  let expression = if self.current_token.to_int() == 102 {
    if self._look_ahead(fn() { self._next_token_is_open_paren_or_less_than() })
      is Some(_) {
      self.source_flags = self.source_flags.union(
        NodeFlags::possibly_contains_dynamic_import(),
      )
      self._parse_token_node()
    } else if self._look_ahead(fn() { self._next_token_is_dot() }) is Some(_) {
      ignore(self._next_token())
      ignore(self._next_token())
      let name = self._parse_identifier_name()
      let meta = self._finish_parser_node(
        _factory_create_meta_property(_syntax_kind(102), name),
        pos,
      )
      match _parser_identifier_text(name) {
        Some("defer") =>
          if self.current_token.to_int() == 21 ||
            self.current_token.to_int() == 30 {
            self.source_flags = self.source_flags.union(
              NodeFlags::possibly_contains_dynamic_import(),
            )
          }
        _ =>
          self.source_flags = self.source_flags.union(
            NodeFlags::possibly_contains_import_meta(),
          )
      }
      meta
    } else {
      self._parse_member_expression_or_higher()
    }
  } else if self.current_token.to_int() == 108 {
    self._parse_super_expression()
  } else {
    self._parse_member_expression_or_higher()
  }
  self._parse_call_expression_rest(pos, expression)
}

///|
fn ParserState::_parse_member_expression_or_higher(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  self._parse_member_expression_rest(
    pos,
    self._parse_primary_expression(),
    true,
  )
}

///|
fn ParserState::_source_text_of_node(self : ParserState, node : Node) -> String {
  let source = SourceText::new(self.source_text)
  let start = skip_trivia(source, node.pos())
  source.substring(start, end=node.end())
}

///|
fn ParserState::_parse_new_expression_or_new_dot_target(
  self : ParserState,
) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(105)))
  if self._parse_optional(_syntax_kind(25)) {
    return self._finish_parser_node(
      _factory_create_meta_property(
        _syntax_kind(105),
        self._parse_identifier_name(),
      ),
      pos,
    )
  }
  let expression_pos = self._get_node_pos()
  let mut expression = self._parse_member_expression_rest(
    expression_pos,
    self._parse_primary_expression(),
    false,
  )
  let mut type_arguments : NodeArray? = None
  if expression.kind().to_int() == 234 {
    type_arguments = _parser_node_field_list(expression, "typeArguments")
    match _parser_node_field_node(expression, "expression") {
      Some(inner) => expression = inner
      None => ()
    }
  }
  if self.current_token.to_int() == 29 {
    ignore(
      self._parse_error_at_current_token(
        _diagnostic_message(1209),
        arguments=_parser_text_arguments(self._source_text_of_node(expression)),
      ),
    )
  }
  let arguments = if self.current_token.to_int() == 21 {
    Some(self._parse_argument_list())
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_new_expression(expression, type_arguments, arguments),
    pos,
  )
}

///|
fn ParserState::_parse_primary_expression(self : ParserState) -> Node {
  match self.current_token.to_int() {
    15 => {
      if self.scanner._token_flags().intersect(TokenFlags::is_invalid()).bits() !=
        0U {
        ignore(self._re_scan_template_token(false))
      }
      self._parse_literal_node()
    }
    9 | 10 | 11 => self._parse_literal_node()
    97 | 106 | 108 | 110 | 112 => self._parse_token_node()
    21 => self._parse_parenthesized_expression()
    23 => self._parse_array_literal_expression()
    19 => self._parse_object_literal_expression()
    134 =>
      if self._look_ahead(fn() {
          self._next_token_is_function_keyword_on_same_line()
        })
        is Some(_) {
        self._parse_function_expression()
      } else {
        self._parse_identifier(message=_diagnostic_message(1109))
      }
    60 => self._parse_decorated_expression()
    86 => self._parse_class_expression()
    100 => self._parse_function_expression()
    105 => self._parse_new_expression_or_new_dot_target()
    44 | 69 =>
      if self._re_scan_slash_token().to_int() == 14 {
        self._parse_literal_node()
      } else {
        self._parse_identifier(message=_diagnostic_message(1109))
      }
    16 =>
      self._parse_template_expression_with(false, fn() {
        self._parse_expression()
      })
    81 => self._parse_private_identifier()
    _ => self._parse_identifier(message=_diagnostic_message(1109))
  }
}
