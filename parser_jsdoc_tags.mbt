// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _jsdoc_property_target_parameter() -> Int {
  1
}

///|
fn _jsdoc_property_target_property() -> Int {
  2
}

///|
fn _jsdoc_property_target_callback_parameter() -> Int {
  4
}

///|
fn _jsdoc_node_ref(node : Node, field : String) -> Node? {
  match node.field(field) {
    Some(NodeRef(value)) => value
    _ => None
  }
}

///|
fn _jsdoc_has_node_list(node : Node, field : String) -> Bool {
  match node.field(field) {
    Some(NodeList(Some(_))) => true
    _ => false
  }
}

///|
fn _jsdoc_type_expression_type(type_expression : Node?) -> Node? {
  match type_expression {
    Some(node) if node.kind().to_int() == 310 => _jsdoc_node_ref(node, "type")
    _ => None
  }
}

///|
fn _jsdoc_is_object_or_object_array_type_reference(node : Node) -> Bool {
  match node.kind().to_int() {
    151 => true
    189 =>
      match _jsdoc_node_ref(node, "elementType") {
        Some(element) =>
          _jsdoc_is_object_or_object_array_type_reference(element)
        None => false
      }
    184 =>
      match _jsdoc_node_ref(node, "typeName") {
        Some(name) =>
          _parser_identifier_text(name) is Some("Object") &&
          !_jsdoc_has_node_list(node, "typeArguments")
        None => false
      }
    _ => false
  }
}

///|
fn _jsdoc_context_has_tag_kind(context : JSDocParseContext, kind : Int) -> Bool {
  for tag in context.tags {
    if tag.kind().to_int() == kind {
      return true
    }
  }
  false
}

///|
fn ParserState::_jsdoc_report_duplicate_tag(
  self : ParserState,
  context : JSDocParseContext,
  tag_name : Node,
  kind : Int,
) -> Unit {
  if _jsdoc_context_has_tag_kind(context, kind) {
    let text = match _parser_identifier_text(tag_name) {
      Some(value) => value
      None => ""
    }
    ignore(
      self._parse_error_at(
        tag_name.pos(),
        self.scanner._token_start(),
        _diagnostic_message(1223),
        arguments=_parser_text_arguments(text),
      ),
    )
  }
}

///|
fn ParserState::_try_parse_jsdoc_type_expression(self : ParserState) -> Node? {
  self._jsdoc_skip_whitespace_or_asterisk() |> ignore
  if self.current_token.to_int() == 19 {
    Some(self._parse_jsdoc_type_expression())
  } else {
    None
  }
}

///|
fn ParserState::_parse_jsdoc_bracket_name(self : ParserState) -> (Node, Bool) {
  let bracketed = self._parse_optional_jsdoc(_syntax_kind(23))
  if bracketed {
    self._jsdoc_skip_whitespace()
  }
  let backquoted = self._parse_optional_jsdoc(_syntax_kind(62))
  let name = self._parse_jsdoc_entity_name()
  if backquoted {
    ignore(self._parse_expected_jsdoc(_syntax_kind(62)))
  }
  if bracketed {
    self._jsdoc_skip_whitespace()
    if self._parse_optional_token(_syntax_kind(64)) is Some(_) {
      ignore(self._parse_expression())
    }
    ignore(self._parse_expected(_syntax_kind(24)))
  }
  (name, bracketed)
}

///|
fn ParserState::_parse_jsdoc_simple_tag(
  self : ParserState,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
  kind : Int,
) -> Node {
  let comment = self._parse_jsdoc_trailing_comments(
    _new_jsdoc_parse_context(start),
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  let node = match kind {
    331 => _factory_create_jsdoc_author_tag(Some(tag_name), comment)
    333 => _factory_create_jsdoc_class_tag(Some(tag_name), comment)
    334 => _factory_create_jsdoc_public_tag(Some(tag_name), comment)
    335 => _factory_create_jsdoc_private_tag(Some(tag_name), comment)
    336 => _factory_create_jsdoc_protected_tag(Some(tag_name), comment)
    337 => _factory_create_jsdoc_readonly_tag(Some(tag_name), comment)
    338 => _factory_create_jsdoc_override_tag(Some(tag_name), comment)
    332 => _factory_create_jsdoc_deprecated_tag(Some(tag_name), comment)
    _ => abort("unsupported simple JSDoc tag")
  }
  self._finish_parser_node(node, start)
}

///|
fn ParserState::_parse_jsdoc_tag(
  self : ParserState,
  context : JSDocParseContext,
  margin : Int,
) -> Node? {
  guard self.current_token.to_int() == 60 else { return None }
  let start = self.scanner._token_start()
  ignore(self._next_token_jsdoc())
  let tag_name = self._parse_jsdoc_identifier_name()
  let indent_text = self._jsdoc_skip_whitespace_or_asterisk()
  let name = match _parser_identifier_text(tag_name) {
    Some(value) => value
    None => ""
  }
  Some(
    match name {
      "author" =>
        self._parse_jsdoc_author_tag(
          context, start, tag_name, margin, indent_text,
        )
      "implements" =>
        self._parse_jsdoc_implements_tag(
          context, start, tag_name, margin, indent_text,
        )
      "augments" | "extends" =>
        self._parse_jsdoc_augments_tag(
          context, start, tag_name, margin, indent_text,
        )
      "class" | "constructor" =>
        self._parse_jsdoc_simple_tag(start, tag_name, margin, indent_text, 333)
      "public" =>
        self._parse_jsdoc_simple_tag(start, tag_name, margin, indent_text, 334)
      "private" =>
        self._parse_jsdoc_simple_tag(start, tag_name, margin, indent_text, 335)
      "protected" =>
        self._parse_jsdoc_simple_tag(start, tag_name, margin, indent_text, 336)
      "readonly" =>
        self._parse_jsdoc_simple_tag(start, tag_name, margin, indent_text, 337)
      "override" =>
        self._parse_jsdoc_simple_tag(start, tag_name, margin, indent_text, 338)
      "deprecated" => {
        self.has_deprecated_tag = true
        self._parse_jsdoc_simple_tag(start, tag_name, margin, indent_text, 332)
      }
      "this" =>
        self._parse_jsdoc_this_tag(
          context, start, tag_name, margin, indent_text,
        )
      "enum" =>
        self._parse_jsdoc_enum_tag(
          context, start, tag_name, margin, indent_text,
        )
      "arg" | "argument" | "param" =>
        self._parse_jsdoc_parameter_or_property_tag(
          context,
          start,
          tag_name,
          _jsdoc_property_target_parameter(),
          margin,
        )
      "return" | "returns" =>
        self._parse_jsdoc_return_tag(
          context, start, tag_name, margin, indent_text,
        )
      "template" =>
        self._parse_jsdoc_template_tag(
          context, start, tag_name, margin, indent_text,
        )
      "type" =>
        self._parse_jsdoc_type_tag(
          context,
          start,
          tag_name,
          Some(margin),
          Some(indent_text),
        )
      "typedef" =>
        self._parse_jsdoc_typedef_tag(
          context, start, tag_name, margin, indent_text,
        )
      "callback" =>
        self._parse_jsdoc_callback_tag(
          context, start, tag_name, margin, indent_text,
        )
      "overload" =>
        self._parse_jsdoc_overload_tag(
          context, start, tag_name, margin, indent_text,
        )
      "satisfies" =>
        self._parse_jsdoc_satisfies_tag(
          context, start, tag_name, margin, indent_text,
        )
      "see" =>
        self._parse_jsdoc_see_tag(
          context,
          start,
          tag_name,
          Some(margin),
          Some(indent_text),
        )
      "exception" | "throws" =>
        self._parse_jsdoc_throws_tag(
          context, start, tag_name, margin, indent_text,
        )
      "import" =>
        self._parse_jsdoc_import_tag(
          context, start, tag_name, margin, indent_text,
        )
      _ =>
        self._parse_jsdoc_unknown_tag(
          context, start, tag_name, margin, indent_text,
        )
    },
  )
}

///|
fn ParserState::_parse_jsdoc_unknown_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_unknown_tag(tag_name, comment),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_return_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  self._jsdoc_report_duplicate_tag(context, tag_name, 343)
  let type_expression = self._try_parse_jsdoc_type_expression()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_return_tag(Some(tag_name), type_expression, comment),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_type_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int?,
  indent_text : String?,
) -> Node {
  self._jsdoc_report_duplicate_tag(context, tag_name, 345)
  let type_expression = self._parse_jsdoc_type_expression(may_omit_braces=true)
  let comments = match (margin, indent_text) {
    (Some(margin), Some(indent_text)) =>
      self._parse_jsdoc_trailing_comments(
        context,
        start,
        self._get_node_pos(),
        margin,
        indent_text,
      )
    _ => None
  }
  self._finish_parser_node(
    _factory_create_jsdoc_type_tag(
      Some(tag_name),
      Some(type_expression),
      comments,
    ),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_this_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let type_expression = self._parse_jsdoc_type_expression(may_omit_braces=true)
  self._jsdoc_skip_whitespace()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_this_tag(
      Some(tag_name),
      Some(type_expression),
      comment,
    ),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_enum_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let type_expression = self._parse_jsdoc_type_expression(may_omit_braces=true)
  self._jsdoc_skip_whitespace()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_enum_tag(Some(tag_name), type_expression, comment),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_throws_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let type_expression = self._try_parse_jsdoc_type_expression()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_throws_tag(Some(tag_name), type_expression, comment),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_satisfies_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let type_expression = self._parse_jsdoc_type_expression()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_satisfies_tag(
      Some(tag_name),
      Some(type_expression),
      comment,
    ),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_see_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int?,
  indent_text : String?,
) -> Node {
  let markdown_or_link = self.current_token.to_int() == 23 ||
    self._look_ahead(fn() { self._parse_jsdoc_link_prefix() }) is Some(_)
  let name = if markdown_or_link {
    None
  } else {
    Some(self._parse_jsdoc_name_reference())
  }
  let comment = match (margin, indent_text) {
    (Some(margin), Some(indent_text)) =>
      self._parse_jsdoc_trailing_comments(
        context,
        start,
        self._get_node_pos(),
        margin,
        indent_text,
      )
    _ => None
  }
  self._finish_parser_node(
    _factory_create_jsdoc_see_tag(Some(tag_name), name, comment),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_author_name_and_email(self : ParserState) -> Node {
  let comments : Array[String] = []
  let mut in_email = false
  let mut scanning = true
  while scanning &&
        self.current_token.to_int() != 1 &&
        self.current_token.to_int() != 4 {
    match self.current_token.to_int() {
      30 => in_email = true
      60 if !in_email => scanning = false
      32 if in_email => {
        comments.push(self.scanner._token_text())
        self.scanner._reset_token_state(self.scanner._token_end())
        scanning = false
      }
      _ => ()
    }
    if scanning {
      comments.push(self.scanner._token_text())
      ignore(self._next_token_jsdoc())
    }
  }
  _factory_create_jsdoc_text(comments.join(""))
}

///|
fn ParserState::_parse_jsdoc_author_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let comment_start = self._get_node_pos()
  let text_only = self._parse_jsdoc_author_name_and_email()
  let mut comment_end = self.scanner._token_full_start()
  let comments = self._parse_jsdoc_trailing_comments(
    context, start, comment_end, margin, indent_text,
  )
  if comments is None {
    comment_end = self.scanner._token_full_start()
  }
  let text_node = self._finish_parser_node(
    text_only,
    comment_start,
    end=comment_end,
  )
  let all_parts = match comments {
    Some(CommentText(text)) =>
      _jsdoc_comment_text(
        match text_node.field("text") {
          Some(Text(Some(prefix))) => prefix + text
          _ => text
        },
      )
    Some(CommentNodes(nodes)) => {
      let values = [text_node]
      for index = 0; index < nodes.length(); index = index + 1 {
        match nodes.get(index) {
          Some(node) => values.push(node)
          None => ()
        }
      }
      _jsdoc_comment_nodes(
        self._create_parser_node_array(values, comment_start),
      )
    }
    None =>
      _jsdoc_comment_nodes(
        self._create_parser_node_array([text_node], comment_start),
      )
  }
  self._finish_parser_node(
    _factory_create_jsdoc_author_tag(Some(tag_name), Some(all_parts)),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_property_access_entity_name(
  self : ParserState,
) -> Node {
  let pos = self._get_node_pos()
  let mut node = self._parse_jsdoc_identifier_name()
  while self._parse_optional(_syntax_kind(25)) {
    node = self._finish_parser_node(
      _factory_create_property_access_expression(
        node,
        self._parse_jsdoc_identifier_name(),
      ),
      pos,
    )
  }
  node
}

///|
fn ParserState::_parse_jsdoc_expression_with_type_arguments(
  self : ParserState,
) -> Node {
  let used_brace = self._parse_optional(_syntax_kind(19))
  let pos = self._get_node_pos()
  let expression = self._parse_jsdoc_property_access_entity_name()
  self.scanner._set_skip_jsdoc_leading_asterisks(true)
  let type_arguments = if self.current_token.to_int() == 30 {
    self._parse_type_arguments_of_type_reference()
  } else {
    None
  }
  self.scanner._set_skip_jsdoc_leading_asterisks(false)
  let result = self._finish_parser_node(
    _factory_create_expression_with_type_arguments(expression, type_arguments),
    pos,
  )
  if used_brace {
    self._jsdoc_skip_whitespace()
    ignore(self._parse_expected(_syntax_kind(20)))
  }
  result
}

///|
fn ParserState::_parse_jsdoc_implements_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let class_name = self._parse_jsdoc_expression_with_type_arguments()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_implements_tag(Some(tag_name), class_name, comment),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_augments_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let class_name = self._parse_jsdoc_expression_with_type_arguments()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_augments_tag(Some(tag_name), class_name, comment),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_import_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  margin : Int,
  indent_text : String,
) -> Node {
  let clause_pos = self.scanner._token_full_start()
  let identifier = if self._is_identifier() {
    Some(self._parse_identifier())
  } else {
    None
  }
  let import_clause = self._try_parse_import_clause(
    identifier,
    clause_pos,
    Some(_syntax_kind(159)),
    skip_jsdoc_leading_asterisks=true,
  )
  let module_specifier = self._parse_module_specifier()
  let attributes = self._try_parse_module_import_attributes()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    margin,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_import_tag(
      Some(tag_name),
      import_clause,
      module_specifier,
      attributes,
      comment,
    ),
    start,
  )
}

///|
fn _jsdoc_entity_names_equal(left : Node, right : Node) -> Bool {
  if left.kind().to_int() == 80 && right.kind().to_int() == 80 {
    return _parser_identifier_text(left) == _parser_identifier_text(right)
  }
  guard left.kind().to_int() == 167 && right.kind().to_int() == 167 else {
    return false
  }
  match
    (
      _jsdoc_node_ref(left, "left"),
      _jsdoc_node_ref(left, "right"),
      _jsdoc_node_ref(right, "left"),
      _jsdoc_node_ref(right, "right"),
    ) {
    (Some(ll), Some(lr), Some(rl), Some(rr)) =>
      _jsdoc_entity_names_equal(ll, rl) &&
      _parser_identifier_text(lr) == _parser_identifier_text(rr)
    _ => false
  }
}

///|
fn _jsdoc_child_name_matches(parent_name : Node, child : Node) -> Bool {
  guard child.kind().to_int() == 342 || child.kind().to_int() == 349 else {
    return true
  }
  guard _jsdoc_node_ref(child, "name") is Some(child_name) else { return false }
  guard child_name.kind().to_int() == 167 else { return false }
  match _jsdoc_node_ref(child_name, "left") {
    Some(left) => _jsdoc_entity_names_equal(parent_name, left)
    None => false
  }
}

///|
fn ParserState::_try_parse_jsdoc_child_tag(
  self : ParserState,
  context : JSDocParseContext,
  target : Int,
  indent : Int,
) -> Node? {
  guard self.current_token.to_int() == 60 else { return None }
  let start = self.scanner._token_full_start()
  ignore(self._next_token_jsdoc())
  let tag_name = self._parse_jsdoc_identifier_name()
  let indent_text = self._jsdoc_skip_whitespace_or_asterisk()
  let name = match _parser_identifier_text(tag_name) {
    Some(value) => value
    None => ""
  }
  match name {
    "type" =>
      if target == _jsdoc_property_target_property() {
        Some(self._parse_jsdoc_type_tag(context, start, tag_name, None, None))
      } else {
        None
      }
    "prop" | "property" =>
      if (target & _jsdoc_property_target_property()) != 0 {
        Some(
          self._parse_jsdoc_parameter_or_property_tag(
            context, start, tag_name, target, indent,
          ),
        )
      } else {
        None
      }
    "arg" | "argument" | "param" =>
      if (
          target &
          (
            _jsdoc_property_target_parameter() |
            _jsdoc_property_target_callback_parameter()
          )
        ) !=
        0 {
        Some(
          self._parse_jsdoc_parameter_or_property_tag(
            context, start, tag_name, target, indent,
          ),
        )
      } else {
        None
      }
    "template" =>
      Some(
        self._parse_jsdoc_template_tag(
          context, start, tag_name, indent, indent_text,
        ),
      )
    "this" =>
      Some(
        self._parse_jsdoc_this_tag(
          context, start, tag_name, indent, indent_text,
        ),
      )
    _ => None
  }
}

///|
fn ParserState::_parse_jsdoc_child_parameter_or_property_tag(
  self : ParserState,
  context : JSDocParseContext,
  target : Int,
  indent : Int,
  parent_name? : Node,
) -> Node? {
  let mut can_parse_tag = true
  let mut seen_asterisk = false
  while true {
    ignore(self._next_token_jsdoc())
    match self.current_token.to_int() {
      60 => {
        if can_parse_tag {
          let child = self._try_parse(fn() {
            self._try_parse_jsdoc_child_tag(context, target, indent)
          })
          match child {
            Some(child) =>
              match parent_name {
                Some(name) if !_jsdoc_child_name_matches(name, child) =>
                  return None
                _ => return Some(child)
              }
            None => return None
          }
        }
        seen_asterisk = false
      }
      4 => {
        can_parse_tag = true
        seen_asterisk = false
      }
      42 => {
        if seen_asterisk {
          can_parse_tag = false
        }
        seen_asterisk = true
      }
      80 => can_parse_tag = false
      1 => return None
      _ => ()
    }
  }
  None
}

///|
fn ParserState::_parse_jsdoc_nested_type_literal(
  self : ParserState,
  context : JSDocParseContext,
  type_expression : Node?,
  name : Node,
  target : Int,
  indent : Int,
) -> Node? {
  guard _jsdoc_type_expression_type(type_expression) is Some(type_node) &&
    _jsdoc_is_object_or_object_array_type_reference(type_node) else {
    return None
  }
  let pos = self._get_node_pos()
  let children : Array[Node] = []
  while true {
    let child = self._try_parse(fn() {
      self._parse_jsdoc_child_parameter_or_property_tag(
        context,
        target,
        indent,
        parent_name=name,
      )
    })
    match child {
      Some(child) if child.kind().to_int() == 342 ||
        child.kind().to_int() == 349 => children.push(child)
      Some(child) if child.kind().to_int() == 346 =>
        match _jsdoc_node_ref(child, "tagName") {
          Some(child_name) =>
            ignore(
              self._parse_error_at(
                child_name.pos(),
                child_name.end(),
                _diagnostic_message(8039),
              ),
            )
          None => ()
        }
      Some(_) => ()
      None => break
    }
  }
  guard !children.is_empty() else { return None }
  let literal = self._finish_parser_node(
    _factory_create_jsdoc_type_literal(
      Some(_create_node_array(children)),
      is_array_type=type_node.kind().to_int() == 189,
    ),
    pos,
  )
  Some(
    self._finish_parser_node(
      _factory_create_jsdoc_type_expression(literal),
      pos,
    ),
  )
}

///|
fn ParserState::_parse_jsdoc_parameter_or_property_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  target : Int,
  indent : Int,
) -> Node {
  let mut type_expression = self._try_parse_jsdoc_type_expression()
  let mut name_first = type_expression is None
  self._jsdoc_skip_whitespace_or_asterisk() |> ignore
  let (name, bracketed) = self._parse_jsdoc_bracket_name()
  let indent_text = self._jsdoc_skip_whitespace_or_asterisk()
  if name_first &&
    self._look_ahead(fn() { self._parse_jsdoc_link_prefix() }) is None {
    type_expression = self._try_parse_jsdoc_type_expression()
  }
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    indent,
    indent_text,
  )
  match
    self._parse_jsdoc_nested_type_literal(
      context, type_expression, name, target, indent,
    ) {
    Some(nested) => {
      type_expression = Some(nested)
      name_first = true
    }
    None => ()
  }
  let result = if target == _jsdoc_property_target_property() {
    _factory_create_jsdoc_property_tag(
      Some(tag_name),
      name,
      bracketed,
      type_expression,
      is_name_first=name_first,
      comment,
    )
  } else {
    _factory_create_jsdoc_parameter_tag(
      Some(tag_name),
      name,
      bracketed,
      type_expression,
      is_name_first=name_first,
      comment,
    )
  }
  self._finish_parser_node(result, start)
}

///|
fn ParserState::_parse_jsdoc_template_type_parameter(
  self : ParserState,
) -> Node? {
  let pos = self._get_node_pos()
  let bracketed = self._parse_optional_jsdoc(_syntax_kind(23))
  if bracketed {
    self._jsdoc_skip_whitespace()
  }
  let modifiers = self._parse_modifiers(false, true, false)
  let name = self._parse_jsdoc_identifier_name(
    message=_diagnostic_message(1069),
  )
  let mut default_type : Node? = None
  if bracketed {
    self._jsdoc_skip_whitespace()
    ignore(self._parse_expected(_syntax_kind(64)))
    default_type = Some(
      self._do_inside_of_context(NodeFlags::jsdoc(), fn() {
        self._parse_jsdoc_type()
      }),
    )
    ignore(self._parse_expected(_syntax_kind(24)))
  }
  guard !_node_is_missing(name) else { return None }
  Some(
    self._finish_parser_node(
      _factory_create_type_parameter_declaration(
        modifiers,
        name,
        None,
        default_type,
      ),
      pos,
    ),
  )
}

///|
fn ParserState::_parse_jsdoc_template_type_parameters(
  self : ParserState,
) -> NodeArray {
  let pos = self._get_node_pos()
  let parameters : Array[Node] = []
  let mut more = true
  while more {
    self._jsdoc_skip_whitespace()
    match self._parse_jsdoc_template_type_parameter() {
      Some(parameter) => parameters.push(parameter)
      None => ()
    }
    self._jsdoc_skip_whitespace_or_asterisk() |> ignore
    more = self._parse_optional_jsdoc(_syntax_kind(28))
  }
  self._create_parser_node_array(parameters, pos)
}

///|
fn ParserState::_parse_jsdoc_template_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  indent : Int,
  indent_text : String,
) -> Node {
  let constraint = if self.current_token.to_int() == 19 {
    Some(self._parse_jsdoc_type_expression())
  } else {
    None
  }
  let type_parameters = self._parse_jsdoc_template_type_parameters()
  let comment = self._parse_jsdoc_trailing_comments(
    context,
    start,
    self._get_node_pos(),
    indent,
    indent_text,
  )
  self._finish_parser_node(
    _factory_create_jsdoc_template_tag(
      Some(tag_name),
      constraint,
      type_parameters,
      comment,
    ),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_type_name_with_namespace(
  self : ParserState,
  nested? : Bool = false,
) -> Node? {
  let start = self.scanner._token_start()
  guard _parser_token_is_identifier_or_keyword(self.current_token) else {
    return None
  }
  let name = self._parse_jsdoc_identifier_name()
  if self._parse_optional(_syntax_kind(25)) {
    let body = self._parse_jsdoc_type_name_with_namespace(nested=true)
    let flags = if nested {
      NodeFlags::nested_namespace()
    } else {
      NodeFlags::none()
    }
    return Some(
      self._finish_parser_node(
        _factory_create_module_declaration(None, name, body, flags~),
        start,
      ),
    )
  }
  if nested {
    name._add_flags(NodeFlags::identifier_is_in_jsdoc_namespace())
  }
  Some(name)
}

///|
fn ParserState::_jsdoc_report_typedef_duplicate_type(
  self : ParserState,
) -> Unit {
  let diagnostic = self._parse_error_at_current_token(_diagnostic_message(8033))
  guard diagnostic is Some(diagnostic) else { return }
  let related = _create_detached_diagnostic(
    self.file_name,
    self.source_text,
    0,
    0,
    _diagnostic_message(8034),
    _no_diagnostic_arguments(),
  )
  let updated = _add_related_information(
    diagnostic,
    ReadOnlyArray::from_array([related]),
  )
  self.diagnostics[self.diagnostics.length() - 1] = updated
}

///|
fn ParserState::_parse_jsdoc_typedef_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  indent : Int,
  indent_text : String,
) -> Node {
  let mut type_expression = self._try_parse_jsdoc_type_expression()
  self._jsdoc_skip_whitespace_or_asterisk() |> ignore
  let full_name = self._parse_jsdoc_type_name_with_namespace()
  self._jsdoc_skip_whitespace()
  let mut comment = self._parse_jsdoc_tag_comments(context, indent)
  let mut explicit_end : Int? = None
  let can_have_children = match _jsdoc_type_expression_type(type_expression) {
    Some(type_node) =>
      _jsdoc_is_object_or_object_array_type_reference(type_node)
    None => true
  }
  if can_have_children {
    let properties : Array[Node] = []
    let mut child_type_tag : Node? = None
    let mut has_children = false
    let mut parsing_children = true
    while parsing_children {
      let child = self._try_parse(fn() {
        self._parse_jsdoc_child_parameter_or_property_tag(
          context,
          _jsdoc_property_target_property(),
          indent,
        )
      })
      match child {
        Some(child) if child.kind().to_int() == 346 => parsing_children = false
        Some(child) if child.kind().to_int() == 345 => {
          has_children = true
          match child_type_tag {
            Some(_) => {
              self._jsdoc_report_typedef_duplicate_type()
              parsing_children = false
            }
            None => child_type_tag = Some(child)
          }
        }
        Some(child) => {
          has_children = true
          properties.push(child)
        }
        None => parsing_children = false
      }
    }
    if has_children {
      let is_array_type = match _jsdoc_type_expression_type(type_expression) {
        Some(type_node) => type_node.kind().to_int() == 189
        None => false
      }
      let literal = _factory_create_jsdoc_type_literal(
        if properties.is_empty() {
          None
        } else {
          Some(_create_node_array(properties))
        },
        is_array_type~,
      )
      type_expression = match child_type_tag {
        Some(child) =>
          match _jsdoc_node_ref(child, "typeExpression") {
            Some(child_expression) =>
              match _jsdoc_type_expression_type(Some(child_expression)) {
                Some(child_type) if !_jsdoc_is_object_or_object_array_type_reference(
                    child_type,
                  ) => Some(child_expression)
                _ => Some(self._finish_parser_node(literal, start))
              }
            None => Some(self._finish_parser_node(literal, start))
          }
        None => Some(self._finish_parser_node(literal, start))
      }
      match type_expression {
        Some(node) => explicit_end = Some(node.end())
        None => ()
      }
    }
  }
  let end = match explicit_end {
    Some(value) => value
    None if comment is Some(_) => self._get_node_pos()
    None =>
      match full_name {
        Some(node) => node.end()
        None =>
          match type_expression {
            Some(node) => node.end()
            None => tag_name.end()
          }
      }
  }
  if comment is None {
    comment = self._parse_jsdoc_trailing_comments(
      context, start, end, indent, indent_text,
    )
  }
  self._finish_parser_node(
    _factory_create_jsdoc_typedef_tag(
      Some(tag_name),
      type_expression,
      full_name,
      comment,
    ),
    start,
    end~,
  )
}

///|
fn ParserState::_parse_jsdoc_callback_parameters(
  self : ParserState,
  context : JSDocParseContext,
  indent : Int,
) -> NodeArray {
  let pos = self._get_node_pos()
  let parameters : Array[Node] = []
  let mut parsing = true
  while parsing {
    let child = self._try_parse(fn() {
      self._parse_jsdoc_child_parameter_or_property_tag(
        context,
        _jsdoc_property_target_callback_parameter(),
        indent,
      )
    })
    match child {
      Some(child) if child.kind().to_int() == 346 => {
        match _jsdoc_node_ref(child, "tagName") {
          Some(name) =>
            ignore(
              self._parse_error_at(
                name.pos(),
                name.end(),
                _diagnostic_message(8039),
              ),
            )
          None => ()
        }
        parsing = false
      }
      Some(child) => parameters.push(child)
      None => parsing = false
    }
  }
  self._create_parser_node_array(parameters, pos)
}

///|
fn ParserState::_parse_jsdoc_signature(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  indent : Int,
) -> Node {
  let parameters = self._parse_jsdoc_callback_parameters(context, indent)
  let return_tag = self._try_parse(fn() {
    guard self._parse_optional_jsdoc(_syntax_kind(60)) else { return None }
    match self._parse_jsdoc_tag(context, indent) {
      Some(tag) if tag.kind().to_int() == 343 => Some(tag)
      _ => None
    }
  })
  self._finish_parser_node(
    _factory_create_jsdoc_signature(None, parameters, return_tag),
    start,
  )
}

///|
fn ParserState::_parse_jsdoc_callback_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  indent : Int,
  indent_text : String,
) -> Node {
  let full_name = self._parse_jsdoc_type_name_with_namespace()
  self._jsdoc_skip_whitespace()
  let mut comment = self._parse_jsdoc_tag_comments(context, indent)
  let signature = self._parse_jsdoc_signature(context, start, indent)
  if comment is None {
    comment = self._parse_jsdoc_trailing_comments(
      context,
      start,
      self._get_node_pos(),
      indent,
      indent_text,
    )
  }
  let end = if comment is Some(_) {
    self._get_node_pos()
  } else {
    signature.end()
  }
  self._finish_parser_node(
    _factory_create_jsdoc_callback_tag(
      Some(tag_name),
      signature,
      full_name,
      comment,
    ),
    start,
    end~,
  )
}

///|
fn ParserState::_parse_jsdoc_overload_tag(
  self : ParserState,
  context : JSDocParseContext,
  start : Int,
  tag_name : Node,
  indent : Int,
  indent_text : String,
) -> Node {
  self._jsdoc_skip_whitespace()
  let mut comment = self._parse_jsdoc_tag_comments(context, indent)
  let signature = self._parse_jsdoc_signature(context, start, indent)
  if comment is None {
    comment = self._parse_jsdoc_trailing_comments(
      context,
      start,
      self._get_node_pos(),
      indent,
      indent_text,
    )
  }
  let end = if comment is Some(_) {
    self._get_node_pos()
  } else {
    signature.end()
  }
  self._finish_parser_node(
    _factory_create_jsdoc_overload_tag(Some(tag_name), signature, comment),
    start,
    end~,
  )
}
