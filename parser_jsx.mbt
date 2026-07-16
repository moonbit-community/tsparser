// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _parser_jsx_identifier_text(node : Node) -> String? {
  match node.field("escapedText") {
    Some(Text(value)) => value
    _ => None
  }
}

///|
fn _parser_jsx_tag_names_are_equivalent(left : Node, right : Node) -> Bool {
  guard left.kind() == right.kind() else { return false }
  match left.kind().to_int() {
    80 =>
      _parser_jsx_identifier_text(left) == _parser_jsx_identifier_text(right)
    110 => true
    296 => {
      let left_namespace = _parser_node_field_node(left, "namespace")
      let right_namespace = _parser_node_field_node(right, "namespace")
      let left_name = _parser_node_field_node(left, "name")
      let right_name = _parser_node_field_node(right, "name")
      match (left_namespace, right_namespace, left_name, right_name) {
        (Some(lns), Some(rns), Some(ln), Some(rn)) =>
          _parser_jsx_identifier_text(lns) == _parser_jsx_identifier_text(rns) &&
          _parser_jsx_identifier_text(ln) == _parser_jsx_identifier_text(rn)
        _ => false
      }
    }
    212 => {
      let left_expression = _parser_node_field_node(left, "expression")
      let right_expression = _parser_node_field_node(right, "expression")
      let left_name = _parser_node_field_node(left, "name")
      let right_name = _parser_node_field_node(right, "name")
      match (left_expression, right_expression, left_name, right_name) {
        (Some(le), Some(re), Some(ln), Some(rn)) =>
          _parser_jsx_identifier_text(ln) == _parser_jsx_identifier_text(rn) &&
          _parser_jsx_tag_names_are_equivalent(le, re)
        _ => false
      }
    }
    _ => false
  }
}

///|
fn ParserState::_parse_jsx_text(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let node = _factory_create_jsx_text(
    self.scanner._required_token_value(),
    contains_only_trivia_white_spaces=self.current_token.to_int() == 13,
  )
  ignore(self._scan_jsx_text())
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_jsx_tag_name(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._scan_jsx_identifier())
  let is_this = self.current_token.to_int() == 110
  let tag_name = self._parse_identifier_name_no_unicode_escape()
  if self._parse_optional(_syntax_kind(59)) {
    ignore(self._scan_jsx_identifier())
    return self._finish_parser_node(
      _factory_create_jsx_namespaced_name(
        tag_name,
        self._parse_identifier_name_no_unicode_escape(),
      ),
      pos,
    )
  }
  if is_this {
    self._finish_parser_node(_factory_create_token(_syntax_kind(110)), pos)
  } else {
    tag_name
  }
}

///|
fn ParserState::_parse_jsx_element_name(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let mut expression = self._parse_jsx_tag_name()
  if expression.kind().to_int() == 296 {
    return expression
  }
  while self._parse_optional(_syntax_kind(25)) {
    expression = self._finish_parser_node(
      _factory_create_property_access_expression(
        expression,
        self._parse_right_side_of_dot(true, false, false),
      ),
      pos,
    )
  }
  expression
}

///|
fn ParserState::_parse_jsx_expression(
  self : ParserState,
  in_expression_context : Bool,
) -> Node? {
  let pos = self._get_node_pos()
  guard self._parse_expected(_syntax_kind(19)) else { return None }
  let mut dot_dot_dot_token : Node? = None
  let mut expression : Node? = None
  if self.current_token.to_int() != 20 {
    if !in_expression_context {
      dot_dot_dot_token = self._parse_optional_token(_syntax_kind(26))
    }
    expression = Some(self._parse_expression())
  }
  if in_expression_context {
    ignore(self._parse_expected(_syntax_kind(20)))
  } else if self._parse_expected(_syntax_kind(20), should_advance=false) {
    ignore(self._scan_jsx_text())
  }
  Some(
    self._finish_parser_node(
      _factory_create_jsx_expression(dot_dot_dot_token, expression),
      pos,
    ),
  )
}

///|
fn ParserState::_parse_jsx_attribute_name(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._scan_jsx_identifier())
  let name = self._parse_identifier_name_no_unicode_escape()
  if self._parse_optional(_syntax_kind(59)) {
    ignore(self._scan_jsx_identifier())
    self._finish_parser_node(
      _factory_create_jsx_namespaced_name(
        name,
        self._parse_identifier_name_no_unicode_escape(),
      ),
      pos,
    )
  } else {
    name
  }
}

///|
fn ParserState::_parse_jsx_attribute_value(self : ParserState) -> Node? {
  guard self.current_token.to_int() == 64 else { return None }
  ignore(self._scan_jsx_attribute_value())
  match self.current_token.to_int() {
    11 => Some(self._parse_literal_node())
    19 => self._parse_jsx_expression(true)
    30 =>
      Some(self._parse_jsx_element_or_self_closing_element_or_fragment(true))
    _ => {
      ignore(self._parse_error_at_current_token(_diagnostic_message(1145)))
      None
    }
  }
}

///|
fn ParserState::_parse_jsx_spread_attribute(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(19)))
  ignore(self._parse_expected(_syntax_kind(26)))
  let expression = self._parse_expression()
  ignore(self._parse_expected(_syntax_kind(20)))
  self._finish_parser_node(
    _factory_create_jsx_spread_attribute(expression),
    pos,
  )
}

///|
fn ParserState::_parse_jsx_attribute(self : ParserState) -> Node {
  if self.current_token.to_int() == 19 {
    return self._parse_jsx_spread_attribute()
  }
  let pos = self._get_node_pos()
  self._finish_parser_node(
    _factory_create_jsx_attribute(
      self._parse_jsx_attribute_name(),
      self._parse_jsx_attribute_value(),
    ),
    pos,
  )
}

///|
fn ParserState::_parse_jsx_attributes(self : ParserState) -> Node {
  let pos = self._get_node_pos()
  let properties = self._parse_list(ParsingContext::jsx_attributes(), fn() {
    self._parse_jsx_attribute()
  })
  self._finish_parser_node(_factory_create_jsx_attributes(properties), pos)
}

///|
fn ParserState::_parse_jsx_type_arguments(self : ParserState) -> NodeArray? {
  if self.context_flags.contains(NodeFlags::javascript_file()) ||
    self.current_token.to_int() != 30 {
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
fn ParserState::_parse_jsx_opening_or_self_closing_element_or_fragment(
  self : ParserState,
  in_expression_context : Bool,
) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(30)))
  if self.current_token.to_int() == 32 {
    ignore(self._scan_jsx_text())
    return self._finish_parser_node(_factory_create_jsx_opening_fragment(), pos)
  }
  let tag_name = self._parse_jsx_element_name()
  let type_arguments = self._parse_jsx_type_arguments()
  let attributes = self._parse_jsx_attributes()
  let node = if self.current_token.to_int() == 32 {
    ignore(self._scan_jsx_text())
    _factory_create_jsx_opening_element(tag_name, type_arguments, attributes)
  } else {
    ignore(self._parse_expected(_syntax_kind(44)))
    if self._parse_expected(_syntax_kind(32), should_advance=false) {
      if in_expression_context {
        ignore(self._next_token())
      } else {
        ignore(self._scan_jsx_text())
      }
    }
    _factory_create_jsx_self_closing_element(
      tag_name, type_arguments, attributes,
    )
  }
  self._finish_parser_node(node, pos)
}

///|
fn ParserState::_parse_jsx_closing_element(
  self : ParserState,
  opening : Node,
  in_expression_context : Bool,
) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(31)))
  let tag_name = self._parse_jsx_element_name()
  if self._parse_expected(_syntax_kind(32), should_advance=false) {
    let opening_name = _parser_node_field_node(opening, "tagName")
    let names_match = match opening_name {
      Some(name) => _parser_jsx_tag_names_are_equivalent(name, tag_name)
      None => false
    }
    if in_expression_context || !names_match {
      ignore(self._next_token())
    } else {
      ignore(self._scan_jsx_text())
    }
  }
  self._finish_parser_node(_factory_create_jsx_closing_element(tag_name), pos)
}

///|
fn ParserState::_parse_jsx_closing_fragment(
  self : ParserState,
  in_expression_context : Bool,
) -> Node {
  let pos = self._get_node_pos()
  ignore(self._parse_expected(_syntax_kind(31)))
  if self._parse_expected(
      _syntax_kind(32),
      message=_diagnostic_message(17015),
      should_advance=false,
    ) {
    if in_expression_context {
      ignore(self._next_token())
    } else {
      ignore(self._scan_jsx_text())
    }
  }
  self._finish_parser_node(_factory_create_jsx_jsx_closing_fragment(), pos)
}

///|
fn ParserState::_parse_jsx_child(
  self : ParserState,
  opening_tag : Node,
) -> Node? {
  match self.current_token.to_int() {
    1 => {
      if opening_tag.kind().to_int() == 290 {
        ignore(
          self._parse_error_at_range(
            TextRange::new(opening_tag.pos(), end=opening_tag.end()),
            _diagnostic_message(17014),
          ),
        )
      } else {
        match _parser_node_field_node(opening_tag, "tagName") {
          Some(tag) => {
            let source = SourceText::new(self.source_text)
            let skipped = skip_trivia(source, tag.pos())
            let start = if skipped < tag.end() { skipped } else { tag.end() }
            ignore(
              self._parse_error_at(
                start,
                tag.end(),
                _diagnostic_message(17008),
                arguments=_parser_text_arguments(self._source_text_of_node(tag)),
              ),
            )
          }
          None => ()
        }
      }
      None
    }
    31 | 7 => None
    12 | 13 => Some(self._parse_jsx_text())
    19 => self._parse_jsx_expression(false)
    30 =>
      Some(
        self._parse_jsx_element_or_self_closing_element_or_fragment(
          false,
          opening_tag~,
        ),
      )
    _ => abort("invalid JSX child token")
  }
}

///|
fn _parser_jsx_child_steals_parent_closing(
  opening_tag : Node,
  child : Node,
) -> Bool {
  guard opening_tag.kind().to_int() == 287 && child.kind().to_int() == 285 else {
    return false
  }
  let child_opening = _parser_node_field_node(child, "openingElement")
  let child_closing = _parser_node_field_node(child, "closingElement")
  let parent_name = _parser_node_field_node(opening_tag, "tagName")
  match (child_opening, child_closing, parent_name) {
    (Some(co), Some(cc), Some(pn)) => {
      let child_open_name = _parser_node_field_node(co, "tagName")
      let child_close_name = _parser_node_field_node(cc, "tagName")
      match (child_open_name, child_close_name) {
        (Some(con), Some(ccn)) =>
          !_parser_jsx_tag_names_are_equivalent(con, ccn) &&
          _parser_jsx_tag_names_are_equivalent(pn, ccn)
        _ => false
      }
    }
    _ => false
  }
}

///|
fn ParserState::_parse_jsx_children(
  self : ParserState,
  opening_tag : Node,
) -> NodeArray {
  let children : Array[Node] = []
  let list_pos = self._get_node_pos()
  let saved_context = self.parsing_context
  self.parsing_context = self.parsing_context |
    ParsingContext::jsx_children().bit()
  while true {
    ignore(self._re_scan_jsx_text())
    match self._parse_jsx_child(opening_tag) {
      Some(child) => {
        children.push(child)
        if _parser_jsx_child_steals_parent_closing(opening_tag, child) {
          break
        }
      }
      None => break
    }
  }
  self.parsing_context = saved_context
  self._create_parser_node_array(children, list_pos)
}

///|
fn ParserState::_restructure_jsx_children(
  self : ParserState,
  parent_opening : Node,
  children : NodeArray,
) -> (NodeArray, Node)? {
  guard children.length() > 0 else { return None }
  let last = children.get(children.length() - 1).unwrap()
  guard last.kind().to_int() == 285 else { return None }
  let last_opening = _parser_node_field_node(last, "openingElement")
  let last_children = _parser_node_field_list(last, "children")
  let last_closing = _parser_node_field_node(last, "closingElement")
  match (last_opening, last_children, last_closing) {
    (Some(child_opening), Some(inner_children), Some(closing)) => {
      let child_open_name = _parser_node_field_node(child_opening, "tagName")
      let child_close_name = _parser_node_field_node(closing, "tagName")
      let parent_name = _parser_node_field_node(parent_opening, "tagName")
      guard (match (child_open_name, child_close_name, parent_name) {
        (Some(child_open_name), Some(child_close_name), Some(parent_name)) =>
          !_parser_jsx_tag_names_are_equivalent(
            child_open_name, child_close_name,
          ) &&
          _parser_jsx_tag_names_are_equivalent(parent_name, child_close_name)
        _ => false
      }) else {
        return None
      }
      let end = inner_children.end()
      let missing_name = self._finish_parser_node(
        _factory_create_identifier(""),
        end,
        end~,
      )
      let missing_closing = self._finish_parser_node(
        _factory_create_jsx_closing_element(missing_name),
        end,
        end~,
      )
      let new_last = self._finish_parser_node(
        _factory_create_jsx_element(
          child_opening, inner_children, missing_closing,
        ),
        child_opening.pos(),
        end~,
      )
      let elements : Array[Node] = []
      for index = 0; index < children.length() - 1; index = index + 1 {
        elements.push(children.get(index).unwrap())
      }
      elements.push(new_last)
      let replacement = self._create_parser_node_array(
        elements,
        children.pos(),
        end~,
      )
      Some((replacement, closing))
    }
    _ => None
  }
}

///|
fn ParserState::_parse_jsx_element_or_self_closing_element_or_fragment(
  self : ParserState,
  in_expression_context : Bool,
  top_invalid_node_position? : Int,
  opening_tag? : Node,
  must_be_unary? : Bool = false,
) -> Node {
  let pos = self._get_node_pos()
  let opening = self._parse_jsx_opening_or_self_closing_element_or_fragment(
    in_expression_context,
  )
  let mut result = match opening.kind().to_int() {
    287 => {
      let mut children = self._parse_jsx_children(opening)
      let closing = match self._restructure_jsx_children(opening, children) {
        Some((replacement, closing)) => {
          children = replacement
          closing
        }
        None => {
          let closing = self._parse_jsx_closing_element(
            opening, in_expression_context,
          )
          let opening_name = _parser_node_field_node(opening, "tagName")
          let closing_name = _parser_node_field_node(closing, "tagName")
          match (opening_name, closing_name) {
            (Some(on), Some(cn)) if !_parser_jsx_tag_names_are_equivalent(
                on, cn,
              ) => {
              let matches_parent = match opening_tag {
                Some(parent) if parent.kind().to_int() == 287 =>
                  match _parser_node_field_node(parent, "tagName") {
                    Some(parent_name) =>
                      _parser_jsx_tag_names_are_equivalent(cn, parent_name)
                    None => false
                  }
                _ => false
              }
              if matches_parent {
                ignore(
                  self._parse_error_at_range(
                    TextRange::new(on.pos(), end=on.end()),
                    _diagnostic_message(17008),
                    arguments=_parser_text_arguments(
                      self._source_text_of_node(on),
                    ),
                  ),
                )
              } else {
                ignore(
                  self._parse_error_at_range(
                    TextRange::new(cn.pos(), end=cn.end()),
                    _diagnostic_message(17002),
                    arguments=_parser_text_arguments(
                      self._source_text_of_node(on),
                    ),
                  ),
                )
              }
            }
            _ => ()
          }
          closing
        }
      }
      self._finish_parser_node(
        _factory_create_jsx_element(opening, children, closing),
        pos,
      )
    }
    290 =>
      self._finish_parser_node(
        _factory_create_jsx_fragment(
          opening,
          self._parse_jsx_children(opening),
          self._parse_jsx_closing_fragment(in_expression_context),
        ),
        pos,
      )
    286 => opening
    _ => abort("invalid JSX opening node")
  }
  if !must_be_unary &&
    in_expression_context &&
    self.current_token.to_int() == 30 {
    let top_bad_pos = match top_invalid_node_position {
      Some(position) => position
      None => result.pos()
    }
    match
      self._try_parse(fn() {
        Some(
          self._parse_jsx_element_or_self_closing_element_or_fragment(
            true,
            top_invalid_node_position=top_bad_pos,
          ),
        )
      }) {
      Some(invalid_element) => {
        let operator = self._create_missing_parser_node(_syntax_kind(28), false)
        operator._set_text_range(invalid_element.pos(), invalid_element.pos())
        let source = SourceText::new(self.source_text)
        ignore(
          self._parse_error_at(
            skip_trivia(source, top_bad_pos),
            invalid_element.end(),
            _diagnostic_message(2657),
          ),
        )
        result = self._finish_parser_node(
          _factory_create_binary_expression(result, operator, invalid_element),
          pos,
        )
      }
      None => ()
    }
  }
  result
}
