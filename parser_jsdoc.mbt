// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts and src/compiler/utilities.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// Result of parsing one isolated `/** ... */` comment.
pub struct JsDocParseResult {
  jsdoc : Node
  diagnostics : ReadOnlyArray[Diagnostic]
}

///|
pub fn JsDocParseResult::jsdoc(self : JsDocParseResult) -> Node {
  self.jsdoc
}

///|
pub fn JsDocParseResult::diagnostics(
  self : JsDocParseResult,
) -> ReadOnlyArray[Diagnostic] {
  self.diagnostics
}

///|
priv struct JSDocParseContext {
  comment_start : Int
  tags : Array[Node]
  mut tags_pos : Int
  mut tags_end : Int
}

///|
fn _new_jsdoc_parse_context(start : Int) -> JSDocParseContext {
  {
    comment_start: start,
    tags: [],
    tags_pos: _invalid_position(),
    tags_end: _invalid_position(),
  }
}

///|
fn _jsdoc_is_comment(source : SourceText, start : Int) -> Bool {
  start >= 0 &&
  start + 3 < source.length() &&
  source.code_unit_at(start) == CharacterCodes::slash() &&
  source.code_unit_at(start + 1) == CharacterCodes::asterisk() &&
  source.code_unit_at(start + 2) == CharacterCodes::asterisk() &&
  source.code_unit_at(start + 3) != CharacterCodes::slash()
}

///|
fn _jsdoc_trim_end(text : String) -> String {
  let source = SourceText::new(text)
  let mut end = source.length()
  while end > 0 && is_white_space_like(source.code_unit_at(end - 1)) {
    end -= 1
  }
  source.substring(0, end~)
}

///|
fn _jsdoc_join_trimmed(parts : Array[String]) -> String {
  _jsdoc_trim_end(parts.join(""))
}

///|
fn _jsdoc_remove_trailing_whitespace(parts : Array[String]) -> Unit {
  while !parts.is_empty() {
    let index = parts.length() - 1
    let value = parts[index]
    let trimmed = _jsdoc_trim_end(value)
    if trimmed == "" {
      ignore(parts.pop())
    } else {
      if trimmed.length() < value.length() {
        parts[index] = trimmed
      }
      break
    }
  }
}

///|
fn _jsdoc_remove_leading_newlines(parts : Array[String]) -> Array[String] {
  let mut first = 0
  while first < parts.length() && (parts[first] == "\n" || parts[first] == "\r") {
    first += 1
  }
  if first == 0 {
    return parts
  }
  let result : Array[String] = []
  for index = first; index < parts.length(); index = index + 1 {
    result.push(parts[index])
  }
  result
}

///|
fn _jsdoc_string_from(text : String, start : Int) -> String {
  let source = SourceText::new(text)
  let actual = if start < 0 {
    0
  } else if start > source.length() {
    source.length()
  } else {
    start
  }
  source.substring(actual, end=source.length())
}

///|
fn _jsdoc_initial_indent(source : SourceText, start : Int) -> Int {
  let mut line_start = 0
  for position = 0; position < start; position = position + 1 {
    if source.code_unit_at(position) == CharacterCodes::line_feed() {
      line_start = position + 1
    }
  }
  start - line_start + 4
}

///|
fn _jsdoc_push_comment(
  comments : Array[String],
  text : String,
  margin : Int?,
  indent : Int,
) -> (Int?, Int) {
  let next_margin = match margin {
    Some(value) if value != 0 => margin
    _ => Some(indent)
  }
  comments.push(text)
  (next_margin, indent + text.length())
}

///|
fn ParserState::_jsdoc_add_tag(
  self : ParserState,
  context : JSDocParseContext,
  tag : Node?,
) -> Unit {
  ignore(self)
  match tag {
    Some(tag) => {
      if context.tags.is_empty() {
        context.tags_pos = tag.pos()
      }
      context.tags.push(tag)
      context.tags_end = tag.end()
    }
    None => ()
  }
}

///|
fn ParserState::_jsdoc_next_nonwhitespace_is_eof(self : ParserState) -> Bool? {
  while true {
    ignore(self._next_token_jsdoc())
    if self.current_token.to_int() == 1 {
      return Some(true)
    }
    if self.current_token.to_int() != 5 && self.current_token.to_int() != 4 {
      return None
    }
  }
  None
}

///|
fn ParserState::_jsdoc_skip_whitespace(self : ParserState) -> Unit {
  if (self.current_token.to_int() == 5 || self.current_token.to_int() == 4) &&
    self._look_ahead(fn() { self._jsdoc_next_nonwhitespace_is_eof() })
    is Some(_) {
    return
  }
  while self.current_token.to_int() == 5 || self.current_token.to_int() == 4 {
    ignore(self._next_token_jsdoc())
  }
}

///|
fn ParserState::_jsdoc_skip_whitespace_or_asterisk(
  self : ParserState,
) -> String {
  if (self.current_token.to_int() == 5 || self.current_token.to_int() == 4) &&
    self._look_ahead(fn() { self._jsdoc_next_nonwhitespace_is_eof() })
    is Some(_) {
    return ""
  }
  let mut preceding_line_break = self.scanner._has_flag(
    TokenFlags::preceding_line_break(),
  )
  let mut seen_line_break = false
  let mut indent_text = ""
  while (preceding_line_break && self.current_token.to_int() == 42) ||
        self.current_token.to_int() == 5 ||
        self.current_token.to_int() == 4 {
    indent_text = indent_text + self.scanner._token_text()
    if self.current_token.to_int() == 4 {
      preceding_line_break = true
      seen_line_break = true
      indent_text = ""
    } else if self.current_token.to_int() == 42 {
      preceding_line_break = false
    }
    ignore(self._next_token_jsdoc())
  }
  if seen_line_break {
    indent_text
  } else {
    ""
  }
}

///|
fn ParserState::_parse_optional_jsdoc(
  self : ParserState,
  kind : SyntaxKind,
) -> Bool {
  if self.current_token == kind {
    ignore(self._next_token_jsdoc())
    true
  } else {
    false
  }
}

///|
fn ParserState::_parse_jsdoc_comment_worker(
  self : ParserState,
  start? : Int = 0,
  length? : Int,
) -> Node? {
  let source = SourceText::new(self.source_text)
  let end = match length {
    Some(length) => start + length
    None => source.length()
  }
  guard start >= 0 && start <= end && end <= source.length() else {
    abort("invalid isolated JSDoc range")
  }
  guard _jsdoc_is_comment(source, start) else { return None }
  let context = _new_jsdoc_parse_context(start)
  let saved_context = self.parsing_context
  self.parsing_context = self.parsing_context |
    ParsingContext::jsdoc_comment().bit()
  let result = self.scanner._scan_range(start + 3, end - start - 5, fn() {
    self._parse_jsdoc_comment_contents(context, end)
  })
  self.parsing_context = saved_context
  Some(result)
}

///|
fn ParserState::_parse_jsdoc_comment_contents(
  self : ParserState,
  context : JSDocParseContext,
  end : Int,
) -> Node {
  let source = SourceText::new(self.source_text)
  let mut state = JSDocState::SawAsterisk.to_int()
  let mut margin : Int? = None
  let mut indent = _jsdoc_initial_indent(source, context.comment_start)
  let mut comments : Array[String] = []
  let parts : Array[Node] = []
  let mut link_end : Int? = None
  let mut comments_pos : Int? = None
  ignore(self._next_token_jsdoc())
  while self._parse_optional_jsdoc(_syntax_kind(5)) {

  }
  if self._parse_optional_jsdoc(_syntax_kind(4)) {
    state = JSDocState::BeginningOfLine.to_int()
    indent = 0
  }
  let mut scanning = true
  while scanning {
    match self.current_token.to_int() {
      60 => {
        _jsdoc_remove_trailing_whitespace(comments)
        if comments_pos is None {
          comments_pos = Some(self._get_node_pos())
        }
        self._jsdoc_add_tag(context, self._parse_jsdoc_tag(context, indent))
        state = JSDocState::BeginningOfLine.to_int()
        margin = None
      }
      4 => {
        comments.push(self.scanner._token_text())
        state = JSDocState::BeginningOfLine.to_int()
        indent = 0
      }
      42 => {
        let asterisk = self.scanner._token_text()
        if state == JSDocState::SawAsterisk.to_int() {
          state = JSDocState::SavingComments.to_int()
          let pushed = _jsdoc_push_comment(comments, asterisk, margin, indent)
          margin = pushed.0
          indent = pushed.1
        } else {
          state = JSDocState::SawAsterisk.to_int()
          indent += asterisk.length()
        }
      }
      5 => {
        let whitespace = self.scanner._token_text()
        match margin {
          Some(margin_value) if indent + whitespace.length() > margin_value =>
            comments.push(_jsdoc_string_from(whitespace, margin_value - indent))
          _ => ()
        }
        indent += whitespace.length()
      }
      1 => scanning = false
      82 => {
        state = JSDocState::SavingComments.to_int()
        let pushed = _jsdoc_push_comment(
          comments,
          self.scanner._required_token_value(),
          margin,
          indent,
        )
        margin = pushed.0
        indent = pushed.1
      }
      19 => {
        state = JSDocState::SavingComments.to_int()
        let comment_end = self.scanner._token_full_start()
        let link_start = self.scanner._token_end() - 1
        match self._parse_jsdoc_link(link_start) {
          Some(link) => {
            if link_end is None {
              comments = _jsdoc_remove_leading_newlines(comments)
            }
            let text_start = match link_end {
              Some(value) => value
              None => context.comment_start
            }
            parts.push(
              self._finish_parser_node(
                _factory_create_jsdoc_text(comments.join("")),
                text_start,
                end=comment_end,
              ),
            )
            parts.push(link)
            comments = []
            link_end = Some(self.scanner._token_end())
          }
          None => {
            let pushed = _jsdoc_push_comment(
              comments,
              self.scanner._token_text(),
              margin,
              indent,
            )
            margin = pushed.0
            indent = pushed.1
          }
        }
      }
      _ => {
        state = JSDocState::SavingComments.to_int()
        let pushed = _jsdoc_push_comment(
          comments,
          self.scanner._token_text(),
          margin,
          indent,
        )
        margin = pushed.0
        indent = pushed.1
      }
    }
    if scanning {
      if state == JSDocState::SavingComments.to_int() {
        ignore(self._next_jsdoc_comment_text_token(false))
      } else {
        ignore(self._next_token_jsdoc())
      }
    }
  }
  let trimmed = _jsdoc_join_trimmed(comments)
  if !parts.is_empty() && trimmed != "" {
    parts.push(
      self._finish_parser_node(
        _factory_create_jsdoc_text(trimmed),
        match link_end {
          Some(value) => value
          None => context.comment_start
        },
        end=match comments_pos {
          Some(value) => value
          None => self.scanner._token_full_start()
        },
      ),
    )
  }
  let tags = if context.tags.is_empty() {
    None
  } else {
    Some(
      self._create_parser_node_array(
        context.tags,
        context.tags_pos,
        end=context.tags_end,
      ),
    )
  }
  let comment = if !parts.is_empty() {
    Some(
      _jsdoc_comment_nodes(
        self._create_parser_node_array(
          parts,
          context.comment_start,
          end=match comments_pos {
            Some(value) => value
            None => self.scanner._token_full_start()
          },
        ),
      ),
    )
  } else if trimmed != "" {
    Some(_jsdoc_comment_text(trimmed))
  } else {
    None
  }
  self._finish_parser_node(
    _factory_create_jsdoc_comment(comment, tags),
    context.comment_start,
    end~,
  )
}

///|
fn ParserState::_parse_jsdoc_link_prefix(self : ParserState) -> String? {
  ignore(self._jsdoc_skip_whitespace_or_asterisk())
  guard self.current_token.to_int() == 19 else { return None }
  ignore(self._next_token_jsdoc())
  guard self.current_token.to_int() == 60 else { return None }
  ignore(self._next_token_jsdoc())
  guard _parser_token_is_identifier_or_keyword(self.current_token) else {
    return None
  }
  let kind = self.scanner._required_token_value()
  if kind == "link" || kind == "linkcode" || kind == "linkplain" {
    Some(kind)
  } else {
    None
  }
}

///|
fn ParserState::_parse_jsdoc_link_name(self : ParserState) -> Node? {
  guard _parser_token_is_identifier_or_keyword(self.current_token) else {
    return None
  }
  let pos = self._get_node_pos()
  let mut name = self._parse_identifier_name()
  while self._parse_optional(_syntax_kind(25)) {
    let right = if self.current_token.to_int() == 81 {
      self._create_missing_parser_node(_syntax_kind(80), false)
    } else {
      self._parse_identifier_name()
    }
    name = self._finish_parser_node(
      _factory_create_qualified_name(name, right),
      pos,
    )
  }
  while self.current_token.to_int() == 81 {
    ignore(self._re_scan_hash_token())
    ignore(self._next_token_jsdoc())
    name = self._finish_parser_node(
      _factory_create_jsdoc_member_name(name, self._parse_identifier()),
      pos,
    )
  }
  Some(name)
}

///|
fn ParserState::_parse_jsdoc_link(self : ParserState, start : Int) -> Node? {
  let link_type = self._try_parse(fn() { self._parse_jsdoc_link_prefix() })
  guard link_type is Some(kind) else { return None }
  ignore(self._next_token_jsdoc())
  self._jsdoc_skip_whitespace()
  let name = self._parse_jsdoc_link_name()
  let text : Array[String] = []
  while self.current_token.to_int() != 20 &&
        self.current_token.to_int() != 4 &&
        self.current_token.to_int() != 1 {
    text.push(self.scanner._token_text())
    ignore(self._next_token_jsdoc())
  }
  let node = if kind == "link" {
    _factory_create_jsdoc_link(name, text.join(""))
  } else if kind == "linkcode" {
    _factory_create_jsdoc_link_code(name, text.join(""))
  } else {
    _factory_create_jsdoc_link_plain(name, text.join(""))
  }
  Some(self._finish_parser_node(node, start, end=self.scanner._token_end()))
}

///|
fn ParserState::_parse_jsdoc_tag_comments(
  self : ParserState,
  context : JSDocParseContext,
  indent_start : Int,
  initial_margin? : String,
) -> JSDocCommentInput? {
  ignore(context)
  let comments_pos = self._get_node_pos()
  let mut comments : Array[String] = []
  let parts : Array[Node] = []
  let mut link_end : Int? = None
  let mut state = JSDocState::BeginningOfLine.to_int()
  let mut margin : Int? = None
  let mut indent = indent_start
  match initial_margin {
    Some(value) => {
      if value != "" {
        let pushed = _jsdoc_push_comment(comments, value, margin, indent)
        margin = pushed.0
        indent = pushed.1
      }
      state = JSDocState::SawAsterisk.to_int()
    }
    None => ()
  }
  let mut scanning = true
  while scanning {
    match self.current_token.to_int() {
      4 => {
        state = JSDocState::BeginningOfLine.to_int()
        comments.push(self.scanner._token_text())
        indent = 0
      }
      60 => {
        self.scanner._reset_token_state(self.scanner._token_end() - 1)
        scanning = false
      }
      1 => scanning = false
      5 => {
        let whitespace = self.scanner._token_text()
        match margin {
          Some(value) if indent + whitespace.length() > value => {
            comments.push(_jsdoc_string_from(whitespace, value - indent))
            state = JSDocState::SavingComments.to_int()
          }
          _ => ()
        }
        indent += whitespace.length()
      }
      19 => {
        state = JSDocState::SavingComments.to_int()
        let comment_end = self.scanner._token_full_start()
        let link_start = self.scanner._token_end() - 1
        match self._parse_jsdoc_link(link_start) {
          Some(link) => {
            parts.push(
              self._finish_parser_node(
                _factory_create_jsdoc_text(comments.join("")),
                match link_end {
                  Some(value) => value
                  None => comments_pos
                },
                end=comment_end,
              ),
            )
            parts.push(link)
            comments = []
            link_end = Some(self.scanner._token_end())
          }
          None => {
            let pushed = _jsdoc_push_comment(
              comments,
              self.scanner._token_text(),
              margin,
              indent,
            )
            margin = pushed.0
            indent = pushed.1
          }
        }
      }
      62 => {
        state = if state == JSDocState::SavingBackticks.to_int() {
          JSDocState::SavingComments.to_int()
        } else {
          JSDocState::SavingBackticks.to_int()
        }
        let pushed = _jsdoc_push_comment(
          comments,
          self.scanner._token_text(),
          margin,
          indent,
        )
        margin = pushed.0
        indent = pushed.1
      }
      82 => {
        if state != JSDocState::SavingBackticks.to_int() {
          state = JSDocState::SavingComments.to_int()
        }
        let pushed = _jsdoc_push_comment(
          comments,
          self.scanner._required_token_value(),
          margin,
          indent,
        )
        margin = pushed.0
        indent = pushed.1
      }
      42 if state == JSDocState::BeginningOfLine.to_int() => {
        state = JSDocState::SawAsterisk.to_int()
        indent += 1
      }
      _ => {
        if state != JSDocState::SavingBackticks.to_int() {
          state = JSDocState::SavingComments.to_int()
        }
        let pushed = _jsdoc_push_comment(
          comments,
          self.scanner._token_text(),
          margin,
          indent,
        )
        margin = pushed.0
        indent = pushed.1
      }
    }
    if scanning {
      if state == JSDocState::SavingComments.to_int() ||
        state == JSDocState::SavingBackticks.to_int() {
        ignore(
          self._next_jsdoc_comment_text_token(
            state == JSDocState::SavingBackticks.to_int(),
          ),
        )
      } else {
        ignore(self._next_token_jsdoc())
      }
    }
  }
  comments = _jsdoc_remove_leading_newlines(comments)
  let trimmed = _jsdoc_join_trimmed(comments)
  if !parts.is_empty() {
    if trimmed != "" {
      parts.push(
        self._finish_parser_node(
          _factory_create_jsdoc_text(trimmed),
          match link_end {
            Some(value) => value
            None => comments_pos
          },
        ),
      )
    }
    Some(
      _jsdoc_comment_nodes(
        self._create_parser_node_array(
          parts,
          comments_pos,
          end=self.scanner._token_end(),
        ),
      ),
    )
  } else if trimmed != "" {
    Some(_jsdoc_comment_text(trimmed))
  } else {
    None
  }
}

///|
fn ParserState::_parse_jsdoc_trailing_comments(
  self : ParserState,
  context : JSDocParseContext,
  pos : Int,
  end : Int,
  margin : Int,
  indent_text : String,
) -> JSDocCommentInput? {
  let actual_margin = if indent_text == "" {
    margin + end - pos
  } else {
    margin
  }
  self._parse_jsdoc_tag_comments(
    context,
    actual_margin,
    initial_margin=_jsdoc_string_from(indent_text, actual_margin),
  )
}

///|
fn _jsdoc_kind_can_have_comment(kind : Int) -> Bool {
  match kind {
    1
    | 80
    | 169
    | 170
    | 172
    | 173
    | 174
    | 175
    | 176
    | 177
    | 178
    | 179
    | 180
    | 181
    | 182
    | 185
    | 186
    | 203
    | 211
    | 212
    | 213
    | 218
    | 219
    | 220
    | 227
    | 232
    | 241
    | 242
    | 243
    | 244
    | 245
    | 246
    | 247
    | 248
    | 249
    | 250
    | 251
    | 252
    | 253
    | 254
    | 255
    | 256
    | 257
    | 258
    | 259
    | 260
    | 261
    | 263
    | 264
    | 265
    | 266
    | 267
    | 268
    | 271
    | 272
    | 273
    | 278
    | 279
    | 282
    | 297
    | 304
    | 305
    | 306
    | 307
    | 318
    | 324 => true
    _ => false
  }
}

///|
fn _jsdoc_kind_uses_trailing_ranges(kind : Int) -> Bool {
  kind == 169 ||
  kind == 170 ||
  kind == 218 ||
  kind == 219 ||
  kind == 220 ||
  kind == 261 ||
  kind == 282
}

///|
fn _jsdoc_append_comment_ranges(
  target : Array[CommentRange],
  source : ReadOnlyArray[CommentRange]?,
) -> Unit {
  match source {
    Some(ranges) =>
      for range in ranges {
        target.push(range)
      }
    None => ()
  }
}

///|
fn ParserState::_jsdoc_comment_allowed_by_mode(
  self : ParserState,
  source : SourceText,
  range : CommentRange,
) -> Bool {
  match self.jsdoc_parsing_mode.to_int() {
    0 => true
    1 => false
    _ => {
      if self.script_kind != ScriptKind::ts() &&
        self.script_kind != ScriptKind::tsx() {
        return true
      }
      if self.jsdoc_parsing_mode == JSDocParsingMode::parse_for_type_info() {
        return false
      }
      let comment = source.substring(range.pos(), end=range.end()).to_lower()
      comment.contains("@see") || comment.contains("@link")
    }
  }
}

///|
fn ParserState::_get_jsdoc_comment_ranges(
  self : ParserState,
  node : Node,
) -> Array[CommentRange] {
  let source = SourceText::new(self.source_text)
  let candidates : Array[CommentRange] = []
  if _jsdoc_kind_uses_trailing_ranges(node.kind().to_int()) {
    _jsdoc_append_comment_ranges(
      candidates,
      get_trailing_comment_ranges(source, node.pos()),
    )
  }
  _jsdoc_append_comment_ranges(
    candidates,
    get_leading_comment_ranges(source, node.pos()),
  )
  let result : Array[CommentRange] = []
  for range in candidates {
    if range.end() <= node.end() &&
      _jsdoc_is_comment(source, range.pos()) &&
      self._jsdoc_comment_allowed_by_mode(source, range) {
      result.push(range)
    }
  }
  result
}

///|
fn ParserState::_parse_attached_jsdoc_comment(
  self : ParserState,
  parent : Node,
  start : Int,
  length : Int,
) -> Node? {
  let saved_token = self.current_token
  let saved_diagnostics_length = self.diagnostics.length()
  let saved_error_before_node = self.finish_state.parse_error_before_next_finished_node
  let comment = self._do_inside_of_context(NodeFlags::jsdoc(), fn() {
    self._parse_jsdoc_comment_worker(start~, length~)
  })
  match comment {
    Some(comment) => comment._set_parent(Some(parent))
    None => ()
  }
  if self.context_flags.contains(NodeFlags::javascript_file()) {
    let collected = match self.jsdoc_diagnostics {
      Some(diagnostics) => diagnostics
      None => {
        let diagnostics : Array[Diagnostic] = []
        self.jsdoc_diagnostics = Some(diagnostics)
        diagnostics
      }
    }
    for index = saved_diagnostics_length
        index < self.diagnostics.length()
        index = index + 1 {
      collected.push(self.diagnostics[index])
    }
  }
  self.current_token = saved_token
  self.diagnostics.truncate(saved_diagnostics_length)
  self.finish_state.parse_error_before_next_finished_node = saved_error_before_node
  comment
}

///|
fn ParserState::_with_jsdoc_if_needed(self : ParserState, node : Node) -> Node {
  if !_jsdoc_kind_can_have_comment(node.kind().to_int()) ||
    node.jsdoc() is Some(_) {
    return node
  }
  let ranges = self._get_jsdoc_comment_ranges(node)
  if ranges.is_empty() {
    return node
  }
  let documents : Array[Node] = []
  for range in ranges {
    match
      self._parse_attached_jsdoc_comment(
        node,
        range.pos(),
        range.end() - range.pos(),
      ) {
      Some(document) => documents.push(document)
      None => ()
    }
  }
  if !documents.is_empty() {
    node._set_jsdoc(Some(_create_node_array(documents)))
  }
  if self.has_deprecated_tag {
    self.has_deprecated_tag = false
    node._add_flags(NodeFlags::deprecated())
  }
  node
}

///|
fn _isolated_jsdoc_diagnostic_file(content : String) -> Node {
  let statements = _create_node_array([])
  statements._set_text_range(0, 0)
  let eof = _factory_create_token(_syntax_kind(1))
  eof._set_text_range(content.length(), content.length())
  let source_file = _factory_create_source_file(
    statements,
    eof,
    NodeFlags::javascript_file(),
  )
  source_file._set_text_range(0, content.length())
  _parser_set_node_field(source_file, "text", Text(Some(content)))
  _parser_set_node_field(source_file, "fileName", Text(Some("")))
  _parser_set_node_field(
    source_file,
    "languageVersion",
    Integer(Some(ScriptTarget::latest().to_int())),
  )
  _parser_set_node_field(
    source_file,
    "languageVariant",
    Integer(Some(LanguageVariant::standard().to_int())),
  )
  _parser_set_node_field(
    source_file,
    "scriptKind",
    Integer(Some(ScriptKind::js().to_int())),
  )
  source_file
}

///|
fn _isolated_jsdoc_diagnostics(
  content : String,
  diagnostics : Array[Diagnostic],
) -> ReadOnlyArray[Diagnostic] {
  if diagnostics.is_empty() {
    return ReadOnlyArray::from_array([])
  }
  let source_file = _isolated_jsdoc_diagnostic_file(content)
  let attached : Array[Diagnostic] = []
  for diagnostic in diagnostics {
    attached.push(_attach_file_to_diagnostic(diagnostic, source_file))
  }
  ReadOnlyArray::from_array(attached)
}

///|
/// Parses a standalone JSDoc comment or a UTF-16 subrange containing one.
pub fn parse_isolated_jsdoc_comment(
  content : String,
  start? : Int = 0,
  length? : Int,
) -> JsDocParseResult? {
  let state = _new_parser_state(
    "",
    content,
    script_kind=ScriptKind::js(),
    jsdoc_parsing_mode=JSDocParsingMode::parse_all(),
  )
  let jsdoc = state._do_inside_of_context(NodeFlags::jsdoc(), fn() {
    state._parse_jsdoc_comment_worker(start~, length?)
  })
  let result = match jsdoc {
    Some(jsdoc) => {
      ignore(_set_parent_recursive(jsdoc))
      Some({
        jsdoc,
        diagnostics: _isolated_jsdoc_diagnostics(
          content,
          state.diagnostics.copy(),
        ),
      })
    }
    None => None
  }
  state._dispose()
  result
}
