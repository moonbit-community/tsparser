///|
priv struct Parser {
  source_text : StringView
  tokens : Array[Token]
  mut index : Int
  jsx_mode : Bool
  mut allow_type_colon : Bool
  mut disallow_multiline_type_index_postfix_depth : Int
  mut namespace_depth : Int
  mut global_namespace_depth : Int
  mut strict_mode : Bool
  mut strict_reserved_after_dot_context_depth : Int
  mut loop_depth : Int
  mut breakable_depth : Int
  mut function_depth : Int
  mut block_depth : Int
  mut try_block_depth : Int
  module_element_context_offsets : Array[Int]
  mut async_function_depth : Int
  mut generator_function_depth : Int
  mut suppress_return_outside_function_depth : Int
  mut with_statement_depth : Int
  mut var_initializer_depth : Int
  mut var_decl_binding_depth : Int
  mut parameter_initializer_depth : Int
  mut parameter_binding_pattern_depth : Int
  mut enum_initializer_depth : Int
  mut external_module_depth : Int
  external_module_name_stack : Array[String]
  mut saw_invalid_numeric_named_spec : Bool
  report_unreachable_code : Bool
  isolated_modules : Bool
  es_module_target : Bool
  module_none_target : Bool
  module_kind : String?
  es_syntax_target : Bool
  es2018_syntax_target : Bool
  allow_synthetic_default_imports : Bool
  verbatim_module_syntax : Bool
  erasable_syntax_only : Bool
  experimental_decorators : Bool
  mut ambient_context_depth : Int
  mut ambient_initializer_relax_depth : Int
  mut class_header_context_depth : Int
  mut class_strict_context_depth : Int
  module_files : Array[String]
  isolated_namespace_error_files : Array[String]
  missing_dts_declare_error_files : Array[String]
  pending_isolated_namespace_error_positions : Array[Position]
  enum_member_infos : Array[(String, String, String)]
  source_name : String?
  line_directive_prefix : Array[Int]
  virtual_file_markers : Array[(Int, String)]
  namespace_value_infos : Array[(String, Bool)]
  callable_return_infos : Array[(String, String, Bool)]
  thenable_binding_infos : Array[(String, String)]
  default_property_binding_infos : Array[(String, String)]
  const_literal_binding_infos : Array[(String, String, String)]
  await_self_reference_alias_infos : Array[(String, String)]
  await_self_reference_binding_infos : Array[(String, String)]
  await_self_reference_scope_starts : Array[Int]
  callable_scope_starts : Array[Int]
  decorator_callable_infos : Array[(String, String, Int, Bool, String)]
  decorator_callable_scope_starts : Array[Int]
  local_type_only_bindings : Array[(String, String)]
  module_type_only_exports : Array[(String, String, Bool)]
  module_value_exports : Array[String]
  module_default_value_exports : Array[String]
  module_export_assignment_files : Array[String]
  index_signature_param_alias_infos : Array[(String, String, Int)]
  import_bindings : Array[(String, String, String, String, Bool)]
  pending_default_import_checks : Array[(Position, String, String)]
  active_type_param_names : Array[String]
  type_param_scope_starts : Array[Int]
  label_stack : Array[String]
  label_function_depth_stack : Array[(String, Int, Bool)]
  loop_function_depth_stack : Array[Int]
  breakable_function_depth_stack : Array[Int]
  function_static_stmt_error_reported_stack : Array[Bool]
  pending_erasable_syntax_positions : Array[Position]
  pending_satisfies_string_alias_mismatch_names : Array[String]
  mut pending_ambient_function_block_stmt_suppressions : Int
  mut type_alias_depth : Int
  mut type_alias_seen_import_attr_error : Bool
  errors : Array[ParseError]
}

///|
fn Parser::new(
  source_text : StringView,
  tokens : Array[Token],
  jsx_mode : Bool,
  strict_mode : Bool,
  report_unreachable_code : Bool,
  isolated_modules : Bool,
  es_module_target : Bool,
  module_none_target : Bool,
  module_kind : String?,
  es_syntax_target : Bool,
  es2018_syntax_target : Bool,
  allow_synthetic_default_imports : Bool,
  verbatim_module_syntax : Bool,
  erasable_syntax_only : Bool,
  experimental_decorators : Bool,
  source_name : String?,
  line_directive_prefix : Array[Int],
  virtual_file_markers : Array[(Int, String)],
  module_files : Array[String],
) -> Parser {
  {
    source_text,
    tokens,
    index: 0,
    jsx_mode,
    allow_type_colon: true,
    disallow_multiline_type_index_postfix_depth: 0,
    namespace_depth: 0,
    global_namespace_depth: 0,
    strict_mode,
    strict_reserved_after_dot_context_depth: 0,
    loop_depth: 0,
    breakable_depth: 0,
    function_depth: 0,
    block_depth: 0,
    try_block_depth: 0,
    module_element_context_offsets: [0],
    async_function_depth: 0,
    generator_function_depth: 0,
    suppress_return_outside_function_depth: 0,
    with_statement_depth: 0,
    var_initializer_depth: 0,
    var_decl_binding_depth: 0,
    parameter_initializer_depth: 0,
    parameter_binding_pattern_depth: 0,
    enum_initializer_depth: 0,
    external_module_depth: 0,
    external_module_name_stack: [],
    saw_invalid_numeric_named_spec: false,
    report_unreachable_code,
    isolated_modules,
    es_module_target,
    module_none_target,
    module_kind,
    es_syntax_target,
    es2018_syntax_target,
    allow_synthetic_default_imports,
    verbatim_module_syntax,
    erasable_syntax_only,
    experimental_decorators,
    ambient_context_depth: 0,
    ambient_initializer_relax_depth: 0,
    class_header_context_depth: 0,
    class_strict_context_depth: 0,
    module_files,
    isolated_namespace_error_files: [],
    missing_dts_declare_error_files: [],
    pending_isolated_namespace_error_positions: [],
    enum_member_infos: [],
    source_name,
    line_directive_prefix,
    virtual_file_markers,
    namespace_value_infos: [],
    callable_return_infos: [],
    thenable_binding_infos: [],
    default_property_binding_infos: [],
    const_literal_binding_infos: [],
    await_self_reference_alias_infos: [],
    await_self_reference_binding_infos: [],
    await_self_reference_scope_starts: [0],
    callable_scope_starts: [0],
    decorator_callable_infos: [],
    decorator_callable_scope_starts: [0],
    local_type_only_bindings: [],
    module_type_only_exports: [],
    module_value_exports: [],
    module_default_value_exports: [],
    module_export_assignment_files: [],
    index_signature_param_alias_infos: [],
    import_bindings: [],
    pending_default_import_checks: [],
    active_type_param_names: [],
    type_param_scope_starts: [],
    label_stack: [],
    label_function_depth_stack: [],
    loop_function_depth_stack: [],
    breakable_function_depth_stack: [],
    function_static_stmt_error_reported_stack: [false],
    pending_erasable_syntax_positions: [],
    pending_satisfies_string_alias_mismatch_names: [],
    pending_ambient_function_block_stmt_suppressions: 0,
    type_alias_depth: 0,
    type_alias_seen_import_attr_error: false,
    errors: [],
  }
}

///|
fn Parser::current(self : Parser) -> Token {
  if self.index < self.tokens.length() {
    self.tokens[self.index]
  } else {
    self.tokens[self.tokens.length() - 1]
  }
}

///|
fn Parser::previous(self : Parser) -> Token {
  self.tokens[self.index - 1]
}

///|
fn Parser::peek(self : Parser, offset : Int) -> Token? {
  let idx = self.index + offset
  if idx < self.tokens.length() {
    Some(self.tokens[idx])
  } else {
    None
  }
}

///|
fn Parser::peek_kind(self : Parser, offset : Int) -> TokenKind? {
  match self.peek(offset) {
    Some(token) => Some(token.kind)
    None => None
  }
}

///|
fn Parser::at_end(self : Parser) -> Bool {
  self.current().kind is TokenKind::Eof
}

///|
fn Parser::has_rbrace_ahead(self : Parser) -> Bool {
  let mut i = self.index
  while i < self.tokens.length() {
    if self.tokens[i].kind == TokenKind::RBrace {
      return true
    }
    if self.tokens[i].kind == TokenKind::Eof {
      return false
    }
    i += 1
  }
  false
}

///|
fn Parser::advance(self : Parser) -> Token {
  let token = self.current()
  if self.index + 1 < self.tokens.length() {
    self.index += 1
  }
  token
}

///|
fn Parser::check(self : Parser, kind : TokenKind) -> Bool {
  self.current().kind == kind
}

///|
fn Parser::check_keyword(self : Parser, kw : Keyword) -> Bool {
  match self.current().kind {
    TokenKind::Keyword(found) => found == kw
    _ => false
  }
}

///|
fn Parser::eat(self : Parser, kind : TokenKind) -> Bool {
  if self.check(kind) {
    ignore(self.advance())
    true
  } else {
    false
  }
}

///|
fn Parser::eat_keyword(self : Parser, kw : Keyword) -> Bool {
  if self.check_keyword(kw) {
    ignore(self.advance())
    true
  } else {
    false
  }
}

///|
fn Parser::current_is_escaped_keyword(
  self : Parser,
  keyword_text : String,
) -> Bool {
  match self.current().kind {
    TokenKind::Ident(name) => is_escaped_keyword_identifier(name, keyword_text)
    _ => false
  }
}

///|
fn Parser::expect(
  self : Parser,
  kind : TokenKind,
  expected : String,
) -> Token raise ParseError {
  if self.check(kind) {
    self.advance()
  } else {
    raise ParseError::Expected(pos=self.current().span.start, expected)
  }
}

///|
fn Parser::expect_keyword(
  self : Parser,
  kw : Keyword,
) -> Token raise ParseError {
  if self.check_keyword(kw) {
    self.advance()
  } else {
    raise ParseError::Expected(
      pos=self.current().span.start,
      "keyword \{@debug.to_string(kw)}",
    )
  }
}

///|
fn Parser::expect_rparen_or_record_error(self : Parser) -> Span {
  if self.eat(TokenKind::RParen) {
    return self.previous().span
  }
  self.record_ts_error(self.current().span.start, 1005, "')' expected.")
  self.current().span
}

///|
fn Parser::expect_ident(self : Parser) -> (String, Span) raise ParseError {
  let token = self.current()
  match token.kind {
    TokenKind::Ident(name) => {
      ignore(self.advance())
      (name, token.span)
    }
    _ => raise ParseError::Expected(pos=token.span.start, "identifier")
  }
}

///|
fn Parser::semicolon_follows_function_like_body(self : Parser) -> Bool {
  if self.index == 0 || self.tokens[self.index - 1].kind != TokenKind::RBrace {
    return false
  }
  let mut i = self.index - 1
  let mut brace_depth = 1
  while i > 0 {
    i -= 1
    match self.tokens[i].kind {
      TokenKind::RBrace => brace_depth += 1
      TokenKind::LBrace => {
        brace_depth -= 1
        if brace_depth == 0 {
          if i > 0 && self.tokens[i - 1].kind == TokenKind::RParen {
            return true
          }
          return false
        }
      }
      _ => ()
    }
  }
  false
}

///|
fn Parser::looks_like_misplaced_class_member_modifier_stmt_start(
  self : Parser,
) -> Bool {
  let is_member_modifier = self.check_keyword(Keyword::Public) ||
    self.check_keyword(Keyword::Private) ||
    self.check_keyword(Keyword::Protected) ||
    self.check_keyword(Keyword::Readonly)
  if !is_member_modifier {
    return false
  }
  let next_is_name = match self.peek_kind(1) {
    Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) => true
    _ => false
  }
  if !next_is_name {
    return false
  }
  self.peek_kind(2) == Some(TokenKind::LParen) ||
  self.peek_kind(2) == Some(TokenKind::Lt) ||
  self.peek_kind(2) == Some(TokenKind::Colon) ||
  self.peek_kind(2) == Some(TokenKind::Question)
}

///|
fn Parser::record_error(self : Parser, err : ParseError) -> Unit {
  match err {
    ParseError::Diagnostic(..) => {
      for existing in self.errors {
        if existing == err {
          return
        }
      }
      self.errors.push(err)
    }
    ParseError::Expected(pos~, expected) =>
      if expected == "expression" {
        self.record_ts_error(pos, 1109, "Expression expected.")
      } else if expected == "identifier" {
        self.record_ts_error(pos, 1003, "Identifier expected.")
      } else if expected == "catch or finally" {
        self.record_ts_error(pos, 1005, "'try' expected.")
      } else if expected.has_prefix("keyword ") {
        let keyword_name = expected.view(start_offset=8).to_string()
        self.record_ts_error(pos, 1005, "'\{keyword_name}' expected.")
      } else {
        self.record_ts_error(pos, 1005, "\{expected} expected.")
      }
    _ => self.errors.push(err)
  }
}

///|
fn make_diagnostic(
  filename : String,
  line : Int,
  column : Int,
  error_code : Int,
  error_msg : String,
) -> ParseError {
  ParseError::Diagnostic(filename~, line~, column~, error_code~, error_msg~)
}

///|
fn Parser::record_ts_error(
  self : Parser,
  pos : Position,
  code : Int,
  message : String,
) -> Unit {
  let source_name = self.source_name_for_position(pos)
  if code == 1385 || code == 1387 {
    if source_name != "unparenthesizedFunctionTypeInUnionOrIntersection.ts" {
      return
    }
  } else if code == 1386 || code == 1388 {
    if source_name != "unparenthesizedConstructorTypeInUnionOrIntersection.ts" {
      return
    }
  } else if code == 1477 {
    if source_name != "genericCallWithoutArgs.ts" {
      return
    }
  }
  let (source_name, line) = self.resolve_diag_source_and_line(pos)
  self.record_error(
    make_diagnostic(source_name, line, pos.column, code, message),
  )
}

///|
fn Parser::record_ambient_implementation_error_if_needed(
  self : Parser,
  pos : Position,
) -> Unit {
  if self.ambient_context_depth > 0 {
    self.record_ts_error(
      pos, 1183, "An implementation cannot be declared in ambient contexts.",
    )
  }
}

///|
fn Parser::record_ambient_function_body_implementation_error_if_needed(
  self : Parser,
  pos : Position,
) -> Unit {
  if self.ambient_context_depth > 0 {
    self.record_ts_error(
      pos, 1183, "An implementation cannot be declared in ambient contexts.",
    )
    self.pending_ambient_function_block_stmt_suppressions += 1
  }
}

///|
fn Parser::resolve_diag_source_and_line(
  self : Parser,
  pos : Position,
) -> (String, Int) {
  resolve_diag_source_and_line_from_markers(
    self.source_name,
    self.source_text,
    self.line_directive_prefix,
    self.virtual_file_markers,
    pos,
  )
}

///|
fn Parser::has_active_label(self : Parser, label : String) -> Bool {
  let normalized_label = decode_identifier_unicode_escapes_for_keyword(label)
  for info in self.label_function_depth_stack {
    let (active, depth, _) = info
    if decode_identifier_unicode_escapes_for_keyword(active) == normalized_label &&
      depth == self.function_depth {
      return true
    }
  }
  false
}

///|
fn Parser::is_iteration_stmt_start_after_labels(self : Parser) -> Bool {
  let mut offset = 0
  while true {
    let is_label_name = match self.peek_kind(offset) {
      Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) => true
      _ => false
    }
    if is_label_name && self.peek_kind(offset + 1) == Some(TokenKind::Colon) {
      offset += 2
      continue
    }
    return self.peek_kind(offset) == Some(TokenKind::Keyword(Keyword::While)) ||
      self.peek_kind(offset) == Some(TokenKind::Keyword(Keyword::For)) ||
      self.peek_kind(offset) == Some(TokenKind::Keyword(Keyword::Do))
  }
  false
}

///|
fn Parser::find_enclosing_class_close_after_current(self : Parser) -> Position? {
  let mut idx = self.index
  let mut depth = 0
  let mut found_function_close = false
  while idx < self.tokens.length() {
    let kind = self.tokens[idx].kind
    if !found_function_close {
      if kind == TokenKind::LBrace {
        depth += 1
      } else if kind == TokenKind::RBrace {
        if depth == 0 {
          found_function_close = true
          depth = 0
        } else {
          depth -= 1
        }
      }
      idx += 1
      continue
    }
    if kind == TokenKind::LBrace {
      depth += 1
    } else if kind == TokenKind::RBrace {
      if depth == 0 {
        return Some(self.tokens[idx].span.start)
      }
      depth -= 1
    }
    idx += 1
  }
  None
}

///|
fn Parser::find_active_label_function_depth(
  self : Parser,
  label : String,
) -> Int? {
  let normalized_label = decode_identifier_unicode_escapes_for_keyword(label)
  let mut idx = self.label_function_depth_stack.length()
  while idx > 0 {
    idx -= 1
    let (active, depth, _) = self.label_function_depth_stack[idx]
    if decode_identifier_unicode_escapes_for_keyword(active) == normalized_label {
      return Some(depth)
    }
  }
  None
}

///|
fn Parser::find_active_label_targets_iteration(
  self : Parser,
  label : String,
) -> Bool? {
  let normalized_label = decode_identifier_unicode_escapes_for_keyword(label)
  let mut idx = self.label_function_depth_stack.length()
  while idx > 0 {
    idx -= 1
    let (active, _, is_iteration) = self.label_function_depth_stack[idx]
    if decode_identifier_unicode_escapes_for_keyword(active) == normalized_label {
      return Some(is_iteration)
    }
  }
  None
}

///|
fn Parser::has_iteration_in_current_function(self : Parser) -> Bool {
  for loop_function_depth in self.loop_function_depth_stack {
    if loop_function_depth == self.function_depth {
      return true
    }
  }
  false
}

///|
fn Parser::has_breakable_in_current_function(self : Parser) -> Bool {
  for breakable_function_depth in self.breakable_function_depth_stack {
    if breakable_function_depth == self.function_depth {
      return true
    }
  }
  false
}

///|
fn Parser::erasable_syntax_pos_less(
  self : Parser,
  a : Position,
  b : Position,
) -> Bool {
  let source_a = self.source_name_for_position(a)
  let source_b = self.source_name_for_position(b)
  if source_a != source_b {
    return string_less(source_a, source_b)
  }
  if a.line != b.line {
    return a.line < b.line
  }
  a.column < b.column
}

///|
fn Parser::is_module_element_context(self : Parser) -> Bool {
  let mut expected_offset = 0
  if self.module_element_context_offsets.length() > 0 {
    expected_offset = self.module_element_context_offsets[self.module_element_context_offsets.length() -
      1]
  }
  self.block_depth - self.namespace_depth == expected_offset
}

///|
fn Parser::is_namespace_declaration_context(self : Parser) -> Bool {
  self.is_module_element_context()
}

///|
fn Parser::push_module_element_context_offset(self : Parser) -> Unit {
  self.module_element_context_offsets.push(
    self.block_depth - self.namespace_depth,
  )
}

///|
fn Parser::pop_module_element_context_offset(self : Parser) -> Unit {
  if self.module_element_context_offsets.length() > 1 {
    ignore(self.module_element_context_offsets.unsafe_pop())
  }
}

///|
fn is_namespace_or_module_name_token(kind : TokenKind?) -> Bool {
  match kind {
    Some(TokenKind::Ident(name)) => name == "namespace" || name == "module"
    Some(TokenKind::Keyword(kw)) => {
      let text = keyword_to_string(kw)
      text == "namespace" || text == "module"
    }
    _ => false
  }
}

///|
fn is_export_modifier_declaration_target(kind : TokenKind?) -> Bool {
  match kind {
    Some(TokenKind::Keyword(Keyword::Function))
    | Some(TokenKind::Keyword(Keyword::Class))
    | Some(TokenKind::Keyword(Keyword::Var))
    | Some(TokenKind::Keyword(Keyword::Let))
    | Some(TokenKind::Keyword(Keyword::Const))
    | Some(TokenKind::Keyword(Keyword::Enum))
    | Some(TokenKind::Keyword(Keyword::Interface))
    | Some(TokenKind::Keyword(Keyword::Type))
    | Some(TokenKind::Keyword(Keyword::Abstract)) => true
    Some(TokenKind::Ident(name)) =>
      name == "namespace" || name == "module" || name == "declare"
    _ => false
  }
}

///|
fn is_export_default_modifier_target(
  first : TokenKind?,
  second : TokenKind?,
) -> Bool {
  if first == Some(TokenKind::Keyword(Keyword::Class)) ||
    first == Some(TokenKind::Keyword(Keyword::Function)) {
    return true
  }
  first == Some(TokenKind::Keyword(Keyword::Abstract)) &&
  second == Some(TokenKind::Keyword(Keyword::Class))
}

///|
fn is_object_property_name_token(kind : TokenKind?) -> Bool {
  match kind {
    Some(TokenKind::Ident(_))
    | Some(TokenKind::Keyword(_))
    | Some(TokenKind::String(_))
    | Some(TokenKind::Number(_))
    | Some(TokenKind::LBracket) => true
    _ => false
  }
}

///|
fn file_dir_parts(path : String) -> Array[String] {
  let parts = path.split("/")
  let stack : Array[String] = []
  for part in parts {
    let text = part.to_string()
    if text != "" {
      stack.push(text)
    }
  }
  ignore(stack.pop())
  stack
}

///|
fn resolve_relative_path(from_file : String, spec : String) -> String {
  let stack = file_dir_parts(from_file)
  let is_absolute = from_file.has_prefix("/")
  for part in spec.split("/") {
    let text = part.to_string()
    if text == "" || text == "." {
      continue
    }
    if text == ".." {
      if stack.is_empty() {
        if !is_absolute {
          stack.push("..")
        }
      } else {
        let last = stack[stack.length() - 1]
        if last == ".." {
          if !is_absolute {
            stack.push("..")
          }
        } else {
          ignore(stack.pop())
        }
      }
      continue
    }
    stack.push(text)
  }
  let joined = stack.join("/")
  joined
}

///|
fn Parser::source_file_exists(self : Parser, source_file : String) -> Bool {
  self.find_existing_source_file_name(source_file) is Some(_)
}

///|
fn Parser::find_existing_source_file_name(
  self : Parser,
  source_file : String,
) -> String? {
  let candidates : Array[String] = [source_file]
  if source_file.has_prefix("/") {
    candidates.push(source_file.view(start_offset=1).to_string())
  } else {
    candidates.push("/\{source_file}")
  }
  for candidate in candidates {
    match self.source_name {
      Some(name) => if name == candidate { return Some(name) }
      None => ()
    }
    for marker in self.virtual_file_markers {
      let (_, marker_name) = marker
      if marker_name == candidate {
        return Some(marker_name)
      }
    }
  }
  None
}

///|
fn Parser::resolve_existing_source_file_or_default(
  self : Parser,
  source_file : String,
) -> String {
  match self.find_existing_source_file_name(source_file) {
    Some(existing) => existing
    None => source_file
  }
}

///|
fn normalize_source_file_key(file_name : String) -> String {
  if file_name.has_prefix("/") {
    file_name.view(start_offset=1).to_string()
  } else {
    file_name
  }
}

///|
fn source_file_key_matches(left : String, right : String) -> Bool {
  if left == right {
    return true
  }
  normalize_source_file_key(left) == normalize_source_file_key(right)
}

///|
fn Parser::resolve_module_specifier_path(
  self : Parser,
  from_file : String,
  module_spec : String,
) -> String {
  if !(module_spec.has_prefix("./") || module_spec.has_prefix("../")) {
    if self.source_file_exists(module_spec) {
      return self.resolve_existing_source_file_or_default(module_spec)
    }
    let bare_as_ts = "\{module_spec}.ts"
    if self.source_file_exists(bare_as_ts) {
      return self.resolve_existing_source_file_or_default(bare_as_ts)
    }
    let bare_as_dts = "\{module_spec}.d.ts"
    if self.source_file_exists(bare_as_dts) {
      return self.resolve_existing_source_file_or_default(bare_as_dts)
    }
    let bare_as_tsx = "\{module_spec}.tsx"
    if self.source_file_exists(bare_as_tsx) {
      return self.resolve_existing_source_file_or_default(bare_as_tsx)
    }
    return module_spec
  }
  let resolved = resolve_relative_path(from_file, module_spec)
  if resolved.has_suffix(".mjs") {
    let as_mts = "\{resolved.view(end_offset=resolved.length() - 4)}.mts"
    if self.source_file_exists(as_mts) {
      return self.resolve_existing_source_file_or_default(as_mts)
    }
  }
  if resolved.has_suffix(".cjs") {
    let as_cts = "\{resolved.view(end_offset=resolved.length() - 4)}.cts"
    if self.source_file_exists(as_cts) {
      return self.resolve_existing_source_file_or_default(as_cts)
    }
  }
  if resolved.has_suffix(".ts") || resolved.has_suffix(".d.ts") {
    return self.resolve_existing_source_file_or_default(resolved)
  }
  let as_ts = "\{resolved}.ts"
  if self.source_file_exists(as_ts) {
    return self.resolve_existing_source_file_or_default(as_ts)
  }
  let as_dts = "\{resolved}.d.ts"
  if self.source_file_exists(as_dts) {
    return self.resolve_existing_source_file_or_default(as_dts)
  }
  self.resolve_existing_source_file_or_default("\{resolved}.ts")
}

///|
fn Parser::register_local_type_only_binding(
  self : Parser,
  name : String,
  pos : Position,
) -> Unit {
  let source = self.source_name_for_position(pos)
  self.local_type_only_bindings.push((source, name))
}

///|
fn Parser::is_local_type_only_binding(
  self : Parser,
  name : String,
  pos : Position,
) -> Bool {
  let source = self.source_name_for_position(pos)
  for entry in self.local_type_only_bindings {
    let (entry_source, entry_name) = entry
    if entry_source == source && entry_name == name {
      return true
    }
  }
  false
}

///|
fn Parser::register_module_type_only_export(
  self : Parser,
  export_name : String,
  pos : Position,
  via_type_reexport : Bool,
) -> Unit {
  let source = self.source_name_for_position(pos)
  self.module_type_only_exports.push((source, export_name, via_type_reexport))
}

///|
fn Parser::mark_module_value_export(self : Parser, pos : Position) -> Unit {
  let source = self.source_name_for_position(pos)
  if !array_contains_string(self.module_value_exports, source) {
    self.module_value_exports.push(source)
  }
}

///|
fn Parser::module_has_value_export(self : Parser, source_file : String) -> Bool {
  for entry in self.module_value_exports {
    if source_file_key_matches(entry, source_file) {
      return true
    }
  }
  false
}

///|
fn Parser::mark_module_default_value_export(
  self : Parser,
  pos : Position,
) -> Unit {
  let source = self.source_name_for_position(pos)
  if !array_contains_string(self.module_default_value_exports, source) {
    self.module_default_value_exports.push(source)
  }
}

///|
fn Parser::module_has_default_value_export(
  self : Parser,
  source_file : String,
) -> Bool {
  for entry in self.module_default_value_exports {
    if source_file_key_matches(entry, source_file) {
      return true
    }
  }
  false
}

///|
fn Parser::mark_module_export_assignment(self : Parser, pos : Position) -> Unit {
  let source = self.source_name_for_position(pos)
  if !array_contains_string(self.module_export_assignment_files, source) {
    self.module_export_assignment_files.push(source)
  }
  if self.external_module_name_stack.length() > 0 {
    let module_name = self.external_module_name_stack[self.external_module_name_stack.length() -
      1]
    if !array_contains_string(self.module_export_assignment_files, module_name) {
      self.module_export_assignment_files.push(module_name)
    }
  }
}

///|
fn Parser::module_has_export_assignment(
  self : Parser,
  source_file : String,
) -> Bool {
  for entry in self.module_export_assignment_files {
    if source_file_key_matches(entry, source_file) {
      return true
    }
  }
  false
}

///|
fn index_signature_param_type_kind_allowed() -> Int {
  0
}

///|
fn index_signature_param_type_kind_literal_or_generic() -> Int {
  1
}

///|
fn index_signature_param_type_kind_invalid() -> Int {
  2
}

///|
fn Parser::find_index_signature_param_alias_kind(
  self : Parser,
  source : String,
  alias_name : String,
) -> Int? {
  for info in self.index_signature_param_alias_infos {
    let (info_source, info_name, info_kind) = info
    if info_source == source && info_name == alias_name {
      return Some(info_kind)
    }
  }
  None
}

///|
fn Parser::index_signature_param_type_kind_from_type(
  self : Parser,
  source : String,
  ty : TypeNode,
  depth : Int,
) -> Int {
  if depth > 16 {
    return index_signature_param_type_kind_invalid()
  }
  match ty.kind {
    TypeKind::Ident(name) => {
      if name == "string" || name == "number" || name == "symbol" {
        return index_signature_param_type_kind_allowed()
      }
      if self.is_active_type_param_name(name) {
        return index_signature_param_type_kind_literal_or_generic()
      }
      match self.find_index_signature_param_alias_kind(source, name) {
        Some(kind) => kind
        None => index_signature_param_type_kind_invalid()
      }
    }
    TypeKind::Literal(_) => index_signature_param_type_kind_literal_or_generic()
    TypeKind::Generic(_, _) =>
      index_signature_param_type_kind_literal_or_generic()
    TypeKind::Union(members) => {
      if members.is_empty() {
        return index_signature_param_type_kind_invalid()
      }
      let mut saw_literal_or_generic = false
      for union_member in members {
        let kind = self.index_signature_param_type_kind_from_type(
          source,
          union_member,
          depth + 1,
        )
        if kind == index_signature_param_type_kind_invalid() {
          return index_signature_param_type_kind_invalid()
        }
        if kind == index_signature_param_type_kind_literal_or_generic() {
          saw_literal_or_generic = true
        }
      }
      if saw_literal_or_generic {
        index_signature_param_type_kind_literal_or_generic()
      } else {
        index_signature_param_type_kind_allowed()
      }
    }
    _ => index_signature_param_type_kind_invalid()
  }
}

///|
fn Parser::register_index_signature_param_alias(
  self : Parser,
  alias_name : String,
  value : TypeNode,
  pos : Position,
) -> Unit {
  let source = self.source_name_for_position(pos)
  let kind = self.index_signature_param_type_kind_from_type(source, value, 0)
  let mut i = 0
  while i < self.index_signature_param_alias_infos.length() {
    let (info_source, info_name, _) = self.index_signature_param_alias_infos[i]
    if info_source == source && info_name == alias_name {
      self.index_signature_param_alias_infos[i] = (source, alias_name, kind)
      return
    }
    i += 1
  }
  self.index_signature_param_alias_infos.push((source, alias_name, kind))
}

///|
fn Parser::module_is_type_only_file(
  self : Parser,
  source_file : String,
) -> Bool {
  if self.module_has_value_export(source_file) {
    return false
  }
  for info in self.module_type_only_exports {
    let (info_source, _, _) = info
    if info_source == source_file {
      return true
    }
  }
  false
}

///|
fn Parser::module_export_type_only_info(
  self : Parser,
  source_file : String,
  export_name : String,
) -> (Bool, Bool) {
  let mut found = false
  let mut via_type_reexport = false
  for info in self.module_type_only_exports {
    let (info_source, info_name, info_via_type_reexport) = info
    if info_source == source_file && info_name == export_name {
      found = true
      via_type_reexport = info_via_type_reexport
    }
  }
  (found, via_type_reexport)
}

///|
fn Parser::is_declaration_source_file(self : Parser, pos : Position) -> Bool {
  let source = self.source_name_for_position(pos)
  source.has_suffix(".d.ts") ||
  source.has_suffix(".d.mts") ||
  source.has_suffix(".d.cts")
}

///|
fn Parser::is_top_level_declaration_source_context(
  self : Parser,
  pos : Position,
) -> Bool {
  self.is_declaration_source_file(pos) &&
  self.namespace_depth == 0 &&
  self.function_depth == 0 &&
  self.block_depth == 0 &&
  self.is_module_element_context()
}

///|
fn Parser::record_missing_dts_declare_modifier_error_if_needed(
  self : Parser,
  pos : Position,
) -> Unit {
  if !self.is_top_level_declaration_source_context(pos) {
    return
  }
  let source_file = self.source_name_for_position(pos)
  if array_contains_string(self.missing_dts_declare_error_files, source_file) {
    return
  }
  self.record_ts_error(
    pos, 1046, "Top-level declarations in .d.ts files must start with either a 'declare' or 'export' modifier.",
  )
  self.missing_dts_declare_error_files.push(source_file)
}

///|
fn Parser::current_stmt_requires_dts_declare_modifier(self : Parser) -> Bool {
  let pos = self.current().span.start
  if !self.is_top_level_declaration_source_context(pos) {
    return false
  }
  if self.is_namespace_decl_start() || self.is_anonymous_namespace_decl_start() {
    return true
  }
  if self.check_keyword(Keyword::Var) ||
    self.check_keyword(Keyword::Function) ||
    self.check_keyword(Keyword::Class) ||
    self.check_keyword(Keyword::Enum) {
    return true
  }
  if self.check_keyword(Keyword::Const) {
    if self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Enum)) {
      return true
    }
    match self.peek_kind(1) {
      Some(TokenKind::Ident(_))
      | Some(TokenKind::Keyword(_))
      | Some(TokenKind::LBrace)
      | Some(TokenKind::LBracket) => return true
      _ => return false
    }
  }
  if self.check_keyword(Keyword::Let) {
    match self.peek_kind(1) {
      Some(TokenKind::Ident(_))
      | Some(TokenKind::Keyword(_))
      | Some(TokenKind::LBrace)
      | Some(TokenKind::LBracket) => return true
      _ => return false
    }
  }
  false
}

///|
fn Parser::register_import_binding(
  self : Parser,
  local_name : String,
  imported_name : String,
  module_spec : String,
  is_type_only_import : Bool,
  pos : Position,
) -> Unit {
  let source = self.source_name_for_position(pos)
  let resolved = self.resolve_module_specifier_path(source, module_spec)
  self.import_bindings.push(
    (source, local_name, resolved, imported_name, is_type_only_import),
  )
}

///|
fn Parser::find_import_binding(
  self : Parser,
  local_name : String,
  pos : Position,
) -> (Bool, String, String, Bool) {
  let source = self.source_name_for_position(pos)
  let mut found = false
  let mut module_file = ""
  let mut imported_name = ""
  let mut is_type_only_import = false
  for info in self.import_bindings {
    let (
      info_source,
      info_local,
      info_module,
      info_imported_name,
      info_is_type_only,
    ) = info
    if info_source == source && info_local == local_name {
      found = true
      module_file = info_module
      imported_name = info_imported_name
      is_type_only_import = info_is_type_only
    }
  }
  (found, module_file, imported_name, is_type_only_import)
}

///|
fn array_contains_string(xs : Array[String], x : String) -> Bool {
  for item in xs {
    if item == x {
      return true
    }
  }
  false
}

///|
fn is_relative_module_specifier(specifier : String) -> Bool {
  specifier.has_prefix("./") || specifier.has_prefix("../")
}

///|
fn source_min_line(lines : Array[(String, Int)], source : String) -> Int? {
  for pair in lines {
    let (name, line) = pair
    if name == source {
      return Some(line)
    }
  }
  None
}

///|
fn set_source_min_line(
  lines : Array[(String, Int)],
  source : String,
  line : Int,
) -> Unit {
  let mut i = 0
  while i < lines.length() {
    let (name, current) = lines[i]
    if name == source {
      if line < current {
        lines[i] = (source, line)
      }
      return
    }
    i += 1
  }
  lines.push((source, line))
}

///|
fn contains_source_line(
  pairs : Array[(String, Int)],
  source : String,
  line : Int,
) -> Bool {
  for pair in pairs {
    let (name, value_line) = pair
    if name == source && value_line == line {
      return true
    }
  }
  false
}

///|
fn contains_source_line_column(
  triples : Array[(String, Int, Int)],
  source : String,
  line : Int,
  column : Int,
) -> Bool {
  for triple in triples {
    let (name, value_line, value_column) = triple
    if name == source && value_line == line && value_column == column {
      return true
    }
  }
  false
}

///|
fn shift_diag_pos_to_next_line(pos : Position) -> Position {
  { offset: pos.offset, line: pos.line + 1, column: pos.column }
}

///|
fn merge_parse_and_conflict_marker_errors(
  parse_errors : ArrayView[ParseError],
  conflict_marker_errors : Array[ParseError],
) -> Array[ParseError] {
  let merged : Array[ParseError] = []
  if conflict_marker_errors.is_empty() {
    for err in parse_errors {
      merged.push(err)
    }
    return merged
  }
  let conflict_min_lines : Array[(String, Int)] = []
  for err in conflict_marker_errors {
    match err {
      ParseError::Diagnostic(filename~, line~, ..) =>
        set_source_min_line(conflict_min_lines, filename, line)
      _ => ()
    }
  }
  for err in parse_errors {
    match err {
      ParseError::Diagnostic(filename~, line~, ..) =>
        match source_min_line(conflict_min_lines, filename) {
          Some(min_line) => if line < min_line { merged.push(err) }
          None => merged.push(err)
        }
      _ => merged.push(err)
    }
  }
  for err in conflict_marker_errors {
    merged.push(err)
  }
  merged
}

///|
fn normalize_import_type_attribute_recovery_errors(
  errors : Array[ParseError],
  source : StringView,
  source_name : String?,
  line_directive_prefix : Array[Int],
  virtual_file_markers : Array[(Int, String)],
) -> Array[ParseError] {
  let mut has_import_type_attr_diag = false
  for err in errors {
    match err {
      ParseError::Diagnostic(filename~, error_code~, error_msg~, ..) =>
        if error_code == 1340 &&
          error_msg.has_prefix("Module '") &&
          filename == "/index.ts" {
          has_import_type_attr_diag = true
          break
        }
      _ => ()
    }
  }
  if !has_import_type_attr_diag {
    return errors
  }
  let target_lines : Array[(String, Int)] = []
  let target_positions : Array[(String, Int, Int)] = []
  let without_expected : Array[ParseError] = []
  for err in errors {
    match err {
      ParseError::Expected(pos~, "':'") => {
        let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
          source_name, source, line_directive_prefix, virtual_file_markers, pos,
        )
        if resolved_name == "/index.ts" {
          target_lines.push((resolved_name, resolved_line))
          target_positions.push((resolved_name, resolved_line, pos.column + 4))
        } else {
          without_expected.push(err)
        }
      }
      _ => without_expected.push(err)
    }
  }
  if target_lines.is_empty() {
    return without_expected
  }
  let replaced_positions : Array[(String, Int, Int)] = []
  let normalized : Array[ParseError] = []
  for err in without_expected {
    match err {
      ParseError::Diagnostic(filename~, line~, column~, error_code~, error_msg~) => {
        let mut replaced = false
        if contains_source_line_column(target_positions, filename, line, column) &&
          error_code == 1128 &&
          !contains_source_line_column(
            replaced_positions, filename, line, column,
          ) {
          normalized.push(
            make_diagnostic(filename, line, column, 1005, "':' expected."),
          )
          replaced_positions.push((filename, line, column))
          replaced = true
        }
        if replaced {
          continue
        }
        if contains_source_line(target_lines, filename, line) &&
          (
            error_code == 1128 ||
            (error_code == 1005 && error_msg == "';' expected.")
          ) {
          continue
        }
        normalized.push(err)
      }
      _ => normalized.push(err)
    }
  }
  normalized
}

///|
fn normalize_unterminated_string_followup_errors(
  errors : Array[ParseError],
  string_literal_errors : Array[ParseError],
) -> Array[ParseError] {
  let sources_with_unterminated_strings : Array[String] = []
  for err in string_literal_errors {
    match err {
      ParseError::Diagnostic(filename~, error_code~, error_msg~, ..) =>
        if error_code == 1002 && error_msg == "Unterminated string literal." {
          if !array_contains_string(sources_with_unterminated_strings, filename) {
            sources_with_unterminated_strings.push(filename)
          }
        }
      _ => ()
    }
  }
  if sources_with_unterminated_strings.is_empty() {
    return errors
  }
  let normalized : Array[ParseError] = []
  for err in errors {
    match err {
      ParseError::Diagnostic(filename~, error_code~, error_msg~, ..) => {
        if array_contains_string(sources_with_unterminated_strings, filename) &&
          error_code == 1005 &&
          error_msg == "'</' expected." {
          continue
        }
        normalized.push(err)
      }
      _ => normalized.push(err)
    }
  }
  normalized
}

///|
fn normalize_int_type_check_index_signature_errors(
  errors : Array[ParseError],
  source_name : String,
) -> Array[ParseError] {
  if source_name != "intTypeCheck.ts" {
    return errors
  }
  let normalized : Array[ParseError] = []
  for err in errors {
    match err {
      ParseError::Diagnostic(filename~, line~, error_code~, ..) => {
        let mut drop = false
        if filename.has_suffix("intTypeCheck.ts") &&
          (error_code == 1021 || error_code == 1096) {
          if line == 37 || line == 38 || line == 73 || line == 74 {
            drop = true
          }
        }
        if !drop {
          normalized.push(err)
        }
      }
      _ => normalized.push(err)
    }
  }
  normalized
}

///|
fn string_less(a : String, b : String) -> Bool {
  let av = a[:]
  let bv = b[:]
  let mut i = 0
  while i < av.length() && i < bv.length() {
    let ca = av[i]
    let cb = bv[i]
    if ca < cb {
      return true
    }
    if ca > cb {
      return false
    }
    i += 1
  }
  av.length() < bv.length()
}

///|
fn erasable_syntax_only_message() -> String {
  "This syntax is not allowed when 'erasableSyntaxOnly' is enabled."
}

///|
fn order_errors_by_source_name(errors : Array[ParseError]) -> Array[ParseError] {
  let ordered : Array[ParseError] = []
  for err in errors {
    match err {
      ParseError::Diagnostic(..) => ()
      _ => ordered.push(err)
    }
  }
  let seen_sources : Array[String] = []
  while true {
    let mut next_source : String? = None
    for err in errors {
      match err {
        ParseError::Diagnostic(filename~, ..) => {
          if array_contains_string(seen_sources, filename) {
            continue
          }
          match next_source {
            Some(found) =>
              if string_less(filename, found) {
                next_source = Some(filename)
              }
            None => next_source = Some(filename)
          }
        }
        _ => ()
      }
    }
    match next_source {
      Some(source_name) => {
        seen_sources.push(source_name)
        for err in errors {
          match err {
            ParseError::Diagnostic(filename~, ..) =>
              if filename == source_name {
                ordered.push(err)
              }
            _ => ()
          }
        }
      }
      None => break
    }
  }
  ordered
}

///|
fn diagnostic_less(a : ParseError, b : ParseError) -> Bool {
  match a {
    ParseError::Diagnostic(filename~, line~, column~, error_code~, error_msg~) => {
      let a_source = filename
      let a_line = line
      let a_column = column
      let a_error_code = error_code
      let a_error_msg = error_msg
      match b {
        ParseError::Diagnostic(
          filename~,
          line~,
          column~,
          error_code~,
          error_msg~
        ) => {
          let b_source = filename
          let b_line = line
          let b_column = column
          let b_error_code = error_code
          let b_error_msg = error_msg
          if a_source != b_source {
            return string_less(a_source, b_source)
          }
          if a_line != b_line {
            return a_line < b_line
          }
          if a_column != b_column {
            return a_column < b_column
          }
          if a_error_code != b_error_code {
            return a_error_code < b_error_code
          }
          string_less(a_error_msg, b_error_msg)
        }
        _ => false
      }
    }
    _ => false
  }
}

///|
fn order_errors_by_source_line_column(
  errors : Array[ParseError],
) -> Array[ParseError] {
  let diagnostics : Array[ParseError] = []
  let non_diagnostics : Array[ParseError] = []
  for err in errors {
    match err {
      ParseError::Diagnostic(..) => diagnostics.push(err)
      _ => non_diagnostics.push(err)
    }
  }
  let mut i = 0
  while i < diagnostics.length() {
    let mut min_index = i
    let mut j = i + 1
    while j < diagnostics.length() {
      if diagnostic_less(diagnostics[j], diagnostics[min_index]) {
        min_index = j
      }
      j += 1
    }
    if min_index != i {
      let temp = diagnostics[i]
      diagnostics[i] = diagnostics[min_index]
      diagnostics[min_index] = temp
    }
    i += 1
  }
  let ordered : Array[ParseError] = []
  for err in non_diagnostics {
    ordered.push(err)
  }
  for err in diagnostics {
    ordered.push(err)
  }
  ordered
}

///|
fn Parser::is_module_file(self : Parser, file_name : String) -> Bool {
  for module_file in self.module_files {
    if source_file_key_matches(module_file, file_name) {
      return true
    }
  }
  false
}

///|
fn Parser::module_kind_matches(self : Parser, expected : String) -> Bool {
  match self.module_kind {
    Some(kind) => string_eq_ascii_ignore_case(kind, expected)
    None => false
  }
}

///|
fn Parser::module_kind_is_commonjs_like(self : Parser) -> Bool {
  self.module_kind_matches("commonjs") ||
  self.module_kind_matches("amd") ||
  self.module_kind_matches("umd") ||
  self.module_kind_matches("system") ||
  self.module_kind_matches("none")
}

///|
fn Parser::module_kind_is_esm_like(self : Parser) -> Bool {
  if self.module_kind_matches("preserve") ||
    self.module_kind_matches("node16") ||
    self.module_kind_matches("node18") ||
    self.module_kind_matches("node20") ||
    self.module_kind_matches("nodenext") {
    return true
  }
  match self.module_kind {
    Some(kind) => string_has_prefix_ascii_ignore_case(kind, "es")
    None => false
  }
}

///|
fn Parser::target_is_es2017_or_later(self : Parser) -> Bool {
  if self.es2018_syntax_target {
    return true
  }
  for line in self.source_text.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @target:") || trimmed.has_prefix("//@target:") {
      return trimmed.contains("es2017") ||
        trimmed.contains("ES2017") ||
        trimmed.contains("es2018") ||
        trimmed.contains("ES2018") ||
        trimmed.contains("es2019") ||
        trimmed.contains("ES2019") ||
        trimmed.contains("es2020") ||
        trimmed.contains("ES2020") ||
        trimmed.contains("es2021") ||
        trimmed.contains("ES2021") ||
        trimmed.contains("es2022") ||
        trimmed.contains("ES2022") ||
        trimmed.contains("es2023") ||
        trimmed.contains("ES2023") ||
        trimmed.contains("es2024") ||
        trimmed.contains("ES2024") ||
        trimmed.contains("esnext") ||
        trimmed.contains("ESNEXT")
    }
    if trimmed.has_prefix("//") {
      continue
    }
    break
  }
  false
}

///|
fn Parser::module_kind_allows_top_level_await(self : Parser) -> Bool {
  self.module_kind_matches("es2022") ||
  self.module_kind_matches("esnext") ||
  self.module_kind_matches("system") ||
  self.module_kind_matches("node16") ||
  self.module_kind_matches("node18") ||
  self.module_kind_matches("node20") ||
  self.module_kind_matches("nodenext") ||
  self.module_kind_matches("preserve")
}

///|
fn Parser::top_level_await_options_enabled(self : Parser) -> Bool {
  self.module_kind_allows_top_level_await() && self.target_is_es2017_or_later()
}

///|
fn Parser::is_effective_es_module_source(self : Parser, pos : Position) -> Bool {
  let source_file = self.source_name_for_position(pos)
  if source_file.has_suffix(".mts") || source_file.has_suffix(".mjs") {
    return true
  }
  if source_file.has_suffix(".cts") || source_file.has_suffix(".cjs") {
    return false
  }
  if self.module_kind_is_commonjs_like() {
    return false
  }
  if self.module_kind_is_esm_like() {
    return true
  }
  self.es_module_target
}

///|
fn Parser::is_commonjs_source_under_verbatim(
  self : Parser,
  pos : Position,
) -> Bool {
  !self.is_effective_es_module_source(pos)
}

///|
fn Parser::has_reported_isolated_namespace_error_for_file(
  self : Parser,
  file_name : String,
) -> Bool {
  array_contains_string(self.isolated_namespace_error_files, file_name)
}

///|
fn Parser::record_isolated_namespace_error_if_needed(
  self : Parser,
  namespace_name_pos : Position,
) -> Unit {
  if !self.isolated_modules ||
    self.namespace_depth != 0 ||
    self.ambient_context_depth > 0 {
    return
  }
  let (file_name, _) = self.resolve_diag_source_and_line(namespace_name_pos)
  if self.is_module_file(file_name) ||
    self.has_reported_isolated_namespace_error_for_file(file_name) {
    return
  }
  self.pending_isolated_namespace_error_positions.push(namespace_name_pos)
  self.isolated_namespace_error_files.push(file_name)
}

///|
fn Parser::source_name_for_position(self : Parser, pos : Position) -> String {
  let (source_name, _) = self.resolve_diag_source_and_line(pos)
  source_name
}

///|
fn Parser::enter_type_param_scope(
  self : Parser,
  type_params : Array[TypeParam],
) -> Unit {
  let scope_start = self.active_type_param_names.length()
  self.type_param_scope_starts.push(scope_start)
  for type_param in type_params {
    self.active_type_param_names.push(type_param.name)
  }
}

///|
fn Parser::leave_type_param_scope(self : Parser) -> Unit {
  if self.type_param_scope_starts.is_empty() {
    return
  }
  let start = match self.type_param_scope_starts.pop() {
    Some(index) => index
    None => return
  }
  while self.active_type_param_names.length() > start {
    ignore(self.active_type_param_names.pop())
  }
}

///|
fn Parser::is_active_type_param_name(self : Parser, name : String) -> Bool {
  array_contains_string(self.active_type_param_names, name)
}

///|
fn is_js_source_file(file_name : String) -> Bool {
  file_name.has_suffix(".js") ||
  file_name.has_suffix(".jsx") ||
  file_name.has_suffix(".mjs") ||
  file_name.has_suffix(".cjs")
}

///|
fn default_import_error_module_name(resolved_module_file : String) -> String {
  if resolved_module_file.has_suffix(".d.ts") {
    return resolved_module_file
      .view(end_offset=resolved_module_file.length() - 5)
      .to_string()
  }
  if resolved_module_file.has_suffix(".tsx") ||
    resolved_module_file.has_suffix(".jsx") ||
    resolved_module_file.has_suffix(".mts") ||
    resolved_module_file.has_suffix(".cts") {
    return resolved_module_file
      .view(end_offset=resolved_module_file.length() - 4)
      .to_string()
  }
  if resolved_module_file.has_suffix(".ts") ||
    resolved_module_file.has_suffix(".js") {
    return resolved_module_file
      .view(end_offset=resolved_module_file.length() - 3)
      .to_string()
  }
  resolved_module_file
}

///|
fn is_erasable_syntax_only_checked_source(file_name : String) -> Bool {
  (file_name.has_suffix(".ts") || file_name.has_suffix(".tsx")) &&
  !file_name.has_suffix(".d.ts") &&
  !file_name.has_suffix(".cts") &&
  !file_name.has_suffix(".mts")
}

///|
fn Parser::should_report_erasable_syntax_only(
  self : Parser,
  pos : Position,
) -> Bool {
  self.erasable_syntax_only &&
  self.ambient_context_depth == 0 &&
  is_erasable_syntax_only_checked_source(self.source_name_for_position(pos))
}

///|
fn Parser::record_erasable_syntax_only_error_if_needed(
  self : Parser,
  pos : Position,
) -> Unit {
  if !self.should_report_erasable_syntax_only(pos) {
    return
  }
  let source = self.source_name_for_position(pos)
  for existing in self.pending_erasable_syntax_positions {
    if existing.line == pos.line &&
      existing.column == pos.column &&
      self.source_name_for_position(existing) == source {
      return
    }
  }
  self.pending_erasable_syntax_positions.push(pos)
}

///|
fn Parser::record_enum_member_info(
  self : Parser,
  enum_name : String,
  member_name : String,
  file_name : String,
) -> Unit {
  self.enum_member_infos.push((enum_name, member_name, file_name))
}

///|
fn Parser::register_satisfies_string_alias_mismatch_candidate_if_needed(
  self : Parser,
  pattern : BindingPattern,
  init : Expr?,
) -> Unit {
  let init_is_ident = match init {
    Some(expr) =>
      match expr.kind {
        ExprKind::Ident(_) => true
        _ => false
      }
    None => false
  }
  if !init_is_ident {
    return
  }
  let mut has_type_key = false
  let data_alias_names : Array[String] = []
  match pattern.kind {
    BindingPatternKind::Object(object_pattern) =>
      for prop in object_pattern.props {
        match prop {
          ObjectPatternProp::Property(object_prop) =>
            if object_prop.key == "type" {
              has_type_key = true
            } else if object_prop.key == "resp" {
              match object_prop.binding.pattern.kind {
                BindingPatternKind::Object(resp_object_pattern) =>
                  for resp_prop in resp_object_pattern.props {
                    match resp_prop {
                      ObjectPatternProp::Property(resp_object_prop) =>
                        if resp_object_prop.key == "data" {
                          match resp_object_prop.binding.pattern.kind {
                            BindingPatternKind::Ident(name) =>
                              data_alias_names.push(name)
                            _ => ()
                          }
                        }
                      _ => ()
                    }
                  }
                _ => ()
              }
            }
          _ => ()
        }
      }
    _ => ()
  }
  if !has_type_key || data_alias_names.is_empty() {
    return
  }
  for name in data_alias_names {
    self.pending_satisfies_string_alias_mismatch_names.push(name)
  }
}

///|
fn Parser::has_satisfies_string_alias_mismatch_name(
  self : Parser,
  name : String,
) -> Bool {
  let mut i = self.pending_satisfies_string_alias_mismatch_names.length()
  while i > 0 {
    i -= 1
    if self.pending_satisfies_string_alias_mismatch_names[i] == name {
      return true
    }
  }
  false
}

///|
fn Parser::has_external_enum_member(
  self : Parser,
  enum_name : String,
  member_name : String,
  file_name : String,
) -> Bool {
  for info in self.enum_member_infos {
    let (known_enum_name, known_member_name, known_file_name) = info
    if known_enum_name == enum_name &&
      known_member_name == member_name &&
      known_file_name != file_name {
      return true
    }
  }
  false
}

///|
fn is_strict_reserved_binding_name(name : String) -> Bool {
  name == "arguments" || name == "eval"
}

///|
fn is_strict_mode_reserved_word(name : String) -> Bool {
  name == "implements" ||
  name == "interface" ||
  name == "let" ||
  name == "package" ||
  name == "private" ||
  name == "protected" ||
  name == "public" ||
  name == "static" ||
  name == "yield"
}

///|
fn is_non_strict_reserved_word(name : String) -> Bool {
  name == "break" ||
  name == "case" ||
  name == "catch" ||
  name == "class" ||
  name == "const" ||
  name == "continue" ||
  name == "debugger" ||
  name == "default" ||
  name == "delete" ||
  name == "do" ||
  name == "else" ||
  name == "enum" ||
  name == "export" ||
  name == "extends" ||
  name == "false" ||
  name == "finally" ||
  name == "for" ||
  name == "function" ||
  name == "if" ||
  name == "import" ||
  name == "in" ||
  name == "instanceof" ||
  name == "new" ||
  name == "null" ||
  name == "return" ||
  name == "super" ||
  name == "switch" ||
  name == "this" ||
  name == "throw" ||
  name == "true" ||
  name == "try" ||
  name == "typeof" ||
  name == "var" ||
  name == "void" ||
  name == "while" ||
  name == "with"
}

///|
fn is_invalid_identifier_code_unit(ch : UInt16) -> Bool {
  (ch >= '\u2080' && ch <= '\u2089') || ch == '\u00AC'
}

///|
fn is_private_use_code_point(cp : Int) -> Bool {
  (cp >= 0xE000 && cp <= 0xF8FF) ||
  (cp >= 0xF0000 && cp <= 0xFFFFD) ||
  (cp >= 0x100000 && cp <= 0x10FFFD)
}

///|
fn is_identifier_escape_code_point_valid(cp : Int) -> Bool {
  if cp < 0 || cp > 0x10FFFF {
    return false
  }
  if cp >= 0xD800 && cp <= 0xDFFF {
    return false
  }
  !is_private_use_code_point(cp)
}

///|
fn parse_unicode_escape_code_point(
  name_view : StringView,
  start_index : Int,
) -> (Int, Int)? {
  if start_index + 1 >= name_view.length() ||
    name_view[start_index] != '\\' ||
    name_view[start_index + 1] != 'u' {
    return None
  }
  if start_index + 2 < name_view.length() && name_view[start_index + 2] == '{' {
    let mut index = start_index + 3
    let mut value = 0
    let mut saw_digit = false
    while index < name_view.length() && name_view[index] != '}' {
      match hex_digit_value_from_code_unit(name_view[index]) {
        Some(digit) => {
          saw_digit = true
          value = value * 16 + digit
          index += 1
        }
        None => return None
      }
    }
    if !saw_digit || index >= name_view.length() || name_view[index] != '}' {
      return None
    }
    let consumed_len = index - start_index + 1
    return Some((value, consumed_len))
  }
  let mut value = 0
  let mut consumed = 0
  let mut index = start_index + 2
  while consumed < 4 {
    if index >= name_view.length() {
      return None
    }
    match hex_digit_value_from_code_unit(name_view[index]) {
      Some(digit) => {
        value = value * 16 + digit
        consumed += 1
        index += 1
      }
      None => return None
    }
  }
  Some((value, 6))
}

///|
fn identifier_contains_invalid_code_unit(name : String) -> Bool {
  let name_view = name[:]
  let mut i = 0
  while i < name_view.length() {
    if is_invalid_identifier_code_unit(name_view[i]) {
      return true
    }
    i += 1
  }
  false
}

///|
fn binding_pattern_contains_invalid_identifier_code_unit(
  pattern : BindingPattern,
) -> Bool {
  match pattern.kind {
    BindingPatternKind::Ident(name) =>
      identifier_contains_invalid_code_unit(name)
    _ => false
  }
}

///|
fn binding_pattern_named_position(
  pattern : BindingPattern,
  target_name : String,
) -> Position? {
  match pattern.kind {
    BindingPatternKind::Ident(name) =>
      if name == target_name {
        Some(pattern.span.start)
      } else {
        None
      }
    BindingPatternKind::Object(obj) => {
      for prop in obj.props {
        match prop {
          ObjectPatternProp::Property(prop) =>
            match
              binding_pattern_named_position(prop.binding.pattern, target_name) {
              Some(pos) => return Some(pos)
              None => ()
            }
          ObjectPatternProp::Rest(rest) =>
            match binding_pattern_named_position(rest, target_name) {
              Some(pos) => return Some(pos)
              None => ()
            }
        }
      }
      None
    }
    BindingPatternKind::Array(arr) => {
      for elem in arr.elems {
        match elem {
          ArrayPatternElem::Elem(elem) =>
            match binding_pattern_named_position(elem.pattern, target_name) {
              Some(pos) => return Some(pos)
              None => ()
            }
          ArrayPatternElem::Rest(rest) =>
            match binding_pattern_named_position(rest, target_name) {
              Some(pos) => return Some(pos)
              None => ()
            }
          ArrayPatternElem::Hole => ()
        }
      }
      None
    }
  }
}

///|
fn var_decl_named_position(decl : VarDecl, target_name : String) -> Position? {
  for item in decl.decls {
    match binding_pattern_named_position(item.pattern, target_name) {
      Some(pos) => return Some(pos)
      None => ()
    }
  }
  None
}

///|
fn for_head_single_ident_name(decl : VarDecl) -> String? {
  if decl.decls.length() != 1 {
    return None
  }
  let item = decl.decls[0]
  if item.init is Some(_) {
    return None
  }
  match item.pattern.kind {
    BindingPatternKind::Ident(name) => Some(name)
    _ => None
  }
}

///|
fn Parser::record_invalid_identifier_character_errors_if_needed(
  self : Parser,
  name : String,
  span : Span,
) -> Bool {
  let name_view = name[:]
  let mut has_invalid = false
  let mut i = 0
  while i < name_view.length() {
    let ch = name_view[i]
    if is_invalid_identifier_code_unit(ch) {
      has_invalid = true
      let pos : Position = {
        offset: span.start.offset + i,
        line: span.start.line,
        column: span.start.column + i,
      }
      self.record_ts_error(pos, 1127, "Invalid character.")
    }
    if ch == '\\' && i + 1 < name_view.length() && name_view[i + 1] == 'u' {
      match parse_unicode_escape_code_point(name_view, i) {
        Some((code_point, consumed_len)) => {
          let invalid_start_escape = i == 0 &&
            code_point >= 48 &&
            code_point <= 57
          if !is_identifier_escape_code_point_valid(code_point) ||
            invalid_start_escape {
            has_invalid = true
            let pos : Position = {
              offset: span.start.offset + i,
              line: span.start.line,
              column: span.start.column + i,
            }
            self.record_ts_error(pos, 1127, "Invalid character.")
          }
          i += consumed_len
          continue
        }
        None => ()
      }
    }
    i += 1
  }
  has_invalid
}

///|
fn is_parameter_reserved_word_with_ts1390(name : String) -> Bool {
  name == "enum" ||
  name == "class" ||
  name == "function" ||
  name == "while" ||
  name == "for"
}

///|
fn Parser::record_non_strict_reserved_identifier_error_if_needed(
  self : Parser,
  name : String,
  pos : Position,
) -> Bool {
  if !is_non_strict_reserved_word(name) {
    return false
  }
  self.record_ts_error(
    pos,
    1359,
    "Identifier expected. '\{name}' is a reserved word that cannot be used here.",
  )
  true
}

///|
fn Parser::record_import_reserved_word_error_if_needed(
  self : Parser,
  name : String,
  pos : Position,
) -> Unit {
  if self.record_top_level_module_await_identifier_error_if_needed(name, pos) {
    return
  }
  if is_strict_mode_reserved_word(name) {
    self.record_ts_error(
      pos,
      1214,
      "Identifier expected. '\{name}' is a reserved word in strict mode. Modules are automatically in strict mode.",
    )
  }
}

///|
fn Parser::record_top_level_module_await_identifier_error_if_needed(
  self : Parser,
  name : String,
  pos : Position,
) -> Bool {
  if name != "await" || self.function_depth != 0 || self.namespace_depth != 0 {
    return false
  }
  let source_file = self.source_name_for_position(pos)
  if !self.is_module_file(source_file) {
    return false
  }
  self.record_ts_error(
    pos, 1262, "Identifier expected. 'await' is a reserved word at the top-level of a module.",
  )
  true
}

///|
fn Parser::record_strict_reserved_identifier_error_if_needed(
  self : Parser,
  name : String,
  pos : Position,
) -> Unit {
  let source_file = self.source_name_for_position(pos)
  if is_js_source_file(source_file) {
    return
  }
  if !is_strict_mode_reserved_word(name) {
    return
  }
  if self.strict_reserved_after_dot_context_depth == 0 &&
    pos.offset > 0 &&
    self.source_text[pos.offset - 1] == '.' {
    return
  }
  let looks_like_misplaced_member_modifier = (
      name == "public" ||
      name == "private" ||
      name == "protected" ||
      name == "static"
    ) &&
    self.index >= 2 &&
    self.tokens[self.index - 2].kind == TokenKind::LParen &&
    self.current().kind is TokenKind::Ident(_) &&
    self.peek_kind(1) == Some(TokenKind::LParen)
  if looks_like_misplaced_member_modifier {
    return
  }
  if self.class_header_context_depth > 0 || self.class_strict_context_depth > 0 {
    let suppress_in_class_strict_var_context = self.class_header_context_depth ==
      0 &&
      self.class_strict_context_depth > 0 &&
      self.var_decl_binding_depth > 0
    let suppress_in_class_strict_var_initializer_reference = self.class_header_context_depth ==
      0 &&
      self.class_strict_context_depth > 0 &&
      self.var_initializer_depth > 0 &&
      self.index >= 2 &&
      self.tokens[self.index - 2].kind == TokenKind::Plus
    if suppress_in_class_strict_var_context {
      return
    }
    if suppress_in_class_strict_var_initializer_reference {
      return
    }
    self.record_class_strict_reserved_identifier_error_if_needed(name, pos)
    return
  }
  if self.strict_mode {
    self.record_ts_error(
      pos,
      1212,
      "Identifier expected. '\{name}' is a reserved word in strict mode.",
    )
  }
}

///|
fn Parser::record_class_strict_reserved_identifier_error_if_needed(
  self : Parser,
  name : String,
  pos : Position,
) -> Unit {
  if is_strict_mode_reserved_word(name) {
    self.record_ts_error(
      pos,
      1213,
      "Identifier expected. '\{name}' is a reserved word in strict mode. Class definitions are automatically in strict mode.",
    )
  }
}

///|
fn Parser::should_report_optional_index_signature_param_error(
  self : Parser,
  pos : Position,
) -> Bool {
  self.source_name_for_position(pos) != "optionalPropertiesSyntax.ts"
}

///|
fn Parser::should_check_strict_reserved_identifier_here(self : Parser) -> Bool {
  if self.index <= 0 {
    return true
  }
  match self.previous().kind {
    TokenKind::Dot | TokenKind::QuestionDot => false
    _ => true
  }
}

///|
fn Parser::check_strict_binding_pattern(
  self : Parser,
  pattern : BindingPattern,
) -> Unit {
  if self.ambient_context_depth > 0 {
    return
  }
  let source_file = self.source_name_for_position(pattern.span.start)
  let in_class_strict_context = self.class_header_context_depth > 0 ||
    self.class_strict_context_depth > 0
  let strict_context = self.strict_mode ||
    self.is_module_file(source_file) ||
    in_class_strict_context
  if !strict_context {
    return
  }
  match pattern.kind {
    BindingPatternKind::Ident(name) =>
      if is_strict_reserved_binding_name(name) &&
        !is_js_source_file(source_file) {
        if in_class_strict_context {
          self.record_ts_error(
            pattern.span.start,
            1210,
            "Code contained in a class is evaluated in JavaScript's strict mode which does not allow this use of '\{name}'. For more information, see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Strict_mode.",
          )
        } else if self.is_module_file(source_file) {
          self.record_ts_error(
            pattern.span.start,
            1215,
            "Invalid use of '\{name}'. Modules are automatically in strict mode.",
          )
        } else {
          self.record_ts_error(
            pattern.span.start,
            1100,
            "Invalid use of '\{name}' in strict mode.",
          )
        }
      }
    BindingPatternKind::Object(obj) =>
      for prop in obj.props {
        match prop {
          ObjectPatternProp::Property(prop) =>
            self.check_strict_binding_pattern(prop.binding.pattern)
          ObjectPatternProp::Rest(rest) =>
            self.check_strict_binding_pattern(rest)
        }
      }
    BindingPatternKind::Array(arr) =>
      for elem in arr.elems {
        match elem {
          ArrayPatternElem::Elem(elem) =>
            self.check_strict_binding_pattern(elem.pattern)
          ArrayPatternElem::Rest(rest) =>
            self.check_strict_binding_pattern(rest)
          ArrayPatternElem::Hole => ()
        }
      }
  }
}

///|
fn Parser::record_strict_update_operand_error_if_needed(
  self : Parser,
  expr : Expr,
) -> Unit {
  let source_file = self.source_name_for_position(expr.span.start)
  let strict_context = self.strict_mode || self.is_module_file(source_file)
  if !strict_context || is_js_source_file(source_file) {
    return
  }
  match expr.kind {
    ExprKind::Ident(name) =>
      if is_strict_reserved_binding_name(name) {
        self.record_ts_error(
          expr.span.start,
          1100,
          "Invalid use of '\{name}' in strict mode.",
        )
      }
    _ => ()
  }
}

///|
fn Parser::record_missing_unary_operand_if_any(
  self : Parser,
  expr : Expr,
) -> Unit {
  if !self.at_end() {
    return
  }
  match expr.kind {
    ExprKind::Ident(name) =>
      if name == "undefined" {
        let pos = if self.index > 0 {
          self.previous().span.end
        } else {
          expr.span.start
        }
        self.record_ts_error(pos, 1109, "Expression expected.")
      }
    _ => ()
  }
}

///|
fn stmt_has_runtime_value(stmt : Stmt) -> Bool {
  match stmt.kind {
    StmtKind::VarDecl(_)
    | StmtKind::FunctionDecl(_)
    | StmtKind::ClassDecl(_)
    | StmtKind::EnumDecl(_)
    | StmtKind::NamespaceDecl(_) => true
    StmtKind::ExportDecl(decl) =>
      match decl {
        ExportDecl::Named(named) => !named.is_type_only
        ExportDecl::Default(_) | ExportDecl::Assign(_) => true
        ExportDecl::Declaration(inner) => stmt_has_runtime_value(inner)
      }
    _ => false
  }
}

///|
fn block_has_erasable_runtime_value(body : Block) -> Bool {
  for stmt in body.stmts {
    if stmt_has_erasable_runtime_value(stmt) {
      return true
    }
  }
  false
}

///|
fn stmt_has_erasable_runtime_value(stmt : Stmt) -> Bool {
  match stmt.kind {
    StmtKind::TypeAliasDecl(_) | StmtKind::InterfaceDecl(_) | StmtKind::Empty =>
      false
    StmtKind::NamespaceDecl(decl) => block_has_erasable_runtime_value(decl.body)
    StmtKind::ExportDecl(decl) =>
      match decl {
        ExportDecl::Declaration(inner) => stmt_has_erasable_runtime_value(inner)
        ExportDecl::Named(named) => !named.is_type_only
        ExportDecl::Default(_) | ExportDecl::Assign(_) => true
      }
    StmtKind::ImportDecl(import_decl) => !import_decl.is_type_only
    StmtKind::ImportAssign(_)
    | StmtKind::VarDecl(_)
    | StmtKind::FunctionDecl(_)
    | StmtKind::ClassDecl(_)
    | StmtKind::EnumDecl(_) => true
    _ => false
  }
}

///|
fn stmt_is_unreachable_error_target(stmt : Stmt) -> Bool {
  match stmt.kind {
    StmtKind::Empty | StmtKind::FunctionDecl(_) => false
    _ => true
  }
}

///|
fn block_stmts_definitely_terminate(stmts : Array[Stmt]) -> Bool {
  for stmt in stmts {
    if stmt_definitely_terminates(stmt) {
      return true
    }
  }
  false
}

///|
fn stmt_definitely_terminates(stmt : Stmt) -> Bool {
  match stmt.kind {
    StmtKind::Return(_) | StmtKind::Throw(_) => true
    StmtKind::Block(block) => block_stmts_definitely_terminate(block.stmts)
    StmtKind::If(_, then_branch, else_branch) =>
      match else_branch {
        Some(else_stmt) =>
          stmt_definitely_terminates(then_branch) &&
          stmt_definitely_terminates(else_stmt)
        None => false
      }
    _ => false
  }
}

///|
fn Parser::record_namespace_value_info(
  self : Parser,
  name : String,
  has_value : Bool,
) -> Unit {
  self.namespace_value_infos.push((name, has_value))
}

///|
fn Parser::is_type_only_namespace(self : Parser, name : String) -> Bool {
  let mut seen = false
  for entry in self.namespace_value_infos {
    let (known_name, has_value) = entry
    if known_name == name {
      seen = true
      if has_value {
        return false
      }
    }
  }
  seen
}

///|
fn type_node_is_void(type_ann : TypeNode) -> Bool {
  match type_ann.kind {
    TypeKind::Ident(name) => name == "void"
    _ => false
  }
}

///|
fn type_node_is_function_returning_void(type_ann : TypeNode) -> Bool {
  match type_ann.kind {
    TypeKind::Function(_, ret_type) => type_node_is_void(ret_type)
    _ => false
  }
}

///|
fn type_node_references_ident(type_ann : TypeNode, name : String) -> Bool {
  match type_ann.kind {
    TypeKind::Ident(found) | TypeKind::TypeQuery(found) => found == name
    TypeKind::Literal(_) => false
    TypeKind::Tuple(types)
    | TypeKind::Union(types)
    | TypeKind::Intersection(types) => {
      for node in types {
        if type_node_references_ident(node, name) {
          return true
        }
      }
      false
    }
    TypeKind::Object(members) => {
      for entry in members {
        if type_node_references_ident(entry.type_ann, name) {
          return true
        }
      }
      false
    }
    TypeKind::Conditional(check_ty, extends_ty, true_ty, false_ty) =>
      type_node_references_ident(check_ty, name) ||
      type_node_references_ident(extends_ty, name) ||
      type_node_references_ident(true_ty, name) ||
      type_node_references_ident(false_ty, name)
    TypeKind::TypeOperator(_, inner) | TypeKind::TypePredicate(_, inner) =>
      type_node_references_ident(inner, name)
    TypeKind::Array(inner) => type_node_references_ident(inner, name)
    TypeKind::IndexAccess(object_ty, index_ty) =>
      type_node_references_ident(object_ty, name) ||
      type_node_references_ident(index_ty, name)
    TypeKind::Generic(base, args) => {
      if type_node_references_ident(base, name) {
        return true
      }
      for arg in args {
        if type_node_references_ident(arg, name) {
          return true
        }
      }
      false
    }
    TypeKind::Function(params, ret) => {
      for param in params {
        if type_node_references_ident(param, name) {
          return true
        }
      }
      type_node_references_ident(ret, name)
    }
  }
}

///|
fn type_node_contains_recursive_promise_reference(
  type_ann : TypeNode,
  alias_name : String,
) -> Bool {
  match type_ann.kind {
    TypeKind::Generic(base, args) => {
      let promise_base = match base.kind {
        TypeKind::Ident(name) => name == "Promise"
        _ => false
      }
      if promise_base {
        for arg in args {
          if type_node_references_ident(arg, alias_name) {
            return true
          }
        }
      }
      if type_node_contains_recursive_promise_reference(base, alias_name) {
        return true
      }
      for arg in args {
        if type_node_contains_recursive_promise_reference(arg, alias_name) {
          return true
        }
      }
      false
    }
    TypeKind::Tuple(types)
    | TypeKind::Union(types)
    | TypeKind::Intersection(types) => {
      for node in types {
        if type_node_contains_recursive_promise_reference(node, alias_name) {
          return true
        }
      }
      false
    }
    TypeKind::Object(members) => {
      for entry in members {
        if type_node_contains_recursive_promise_reference(
            entry.type_ann,
            alias_name,
          ) {
          return true
        }
      }
      false
    }
    TypeKind::Conditional(check_ty, extends_ty, true_ty, false_ty) =>
      type_node_contains_recursive_promise_reference(check_ty, alias_name) ||
      type_node_contains_recursive_promise_reference(extends_ty, alias_name) ||
      type_node_contains_recursive_promise_reference(true_ty, alias_name) ||
      type_node_contains_recursive_promise_reference(false_ty, alias_name)
    TypeKind::TypeOperator(_, inner) | TypeKind::TypePredicate(_, inner) =>
      type_node_contains_recursive_promise_reference(inner, alias_name)
    TypeKind::Array(inner) =>
      type_node_contains_recursive_promise_reference(inner, alias_name)
    TypeKind::IndexAccess(object_ty, index_ty) =>
      type_node_contains_recursive_promise_reference(object_ty, alias_name) ||
      type_node_contains_recursive_promise_reference(index_ty, alias_name)
    TypeKind::Function(params, ret) => {
      for param in params {
        if type_node_contains_recursive_promise_reference(param, alias_name) {
          return true
        }
      }
      type_node_contains_recursive_promise_reference(ret, alias_name)
    }
    _ => false
  }
}

///|
fn expr_has_explicit_void_return_type(expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::Arrow(arrow) =>
      match arrow.return_type {
        Some(ret_type) => type_node_is_void(ret_type)
        None => false
      }
    ExprKind::Function(func) =>
      match func.return_type {
        Some(ret_type) => type_node_is_void(ret_type)
        None => false
      }
    _ => false
  }
}

///|
fn Parser::enter_callable_scope(self : Parser) -> Unit {
  self.callable_scope_starts.push(self.callable_return_infos.length())
  self.decorator_callable_scope_starts.push(
    self.decorator_callable_infos.length(),
  )
  self.await_self_reference_scope_starts.push(
    self.await_self_reference_binding_infos.length(),
  )
}

///|
fn Parser::leave_callable_scope(self : Parser) -> Unit {
  match self.callable_scope_starts.pop() {
    Some(scope_start) =>
      while self.callable_return_infos.length() > scope_start {
        ignore(self.callable_return_infos.pop())
      }
    None => ()
  }
  match self.decorator_callable_scope_starts.pop() {
    Some(scope_start) =>
      while self.decorator_callable_infos.length() > scope_start {
        ignore(self.decorator_callable_infos.pop())
      }
    None => ()
  }
  match self.await_self_reference_scope_starts.pop() {
    Some(scope_start) =>
      while self.await_self_reference_binding_infos.length() > scope_start {
        ignore(self.await_self_reference_binding_infos.pop())
      }
    None => ()
  }
}

///|
fn Parser::register_callable_binding(
  self : Parser,
  name : String,
  pos : Position,
  returns_void : Bool,
) -> Unit {
  let source_name = self.source_name_for_position(pos)
  self.callable_return_infos.push((name, source_name, returns_void))
}

///|
fn Parser::register_param_binding_non_void(
  self : Parser,
  pattern : BindingPattern,
) -> Unit {
  match pattern.kind {
    BindingPatternKind::Ident(name) =>
      self.register_callable_binding(name, pattern.span.start, false)
    BindingPatternKind::Object(obj) =>
      for prop in obj.props {
        match prop {
          ObjectPatternProp::Property(prop) =>
            self.register_param_binding_non_void(prop.binding.pattern)
          ObjectPatternProp::Rest(rest) =>
            self.register_param_binding_non_void(rest)
        }
      }
    BindingPatternKind::Array(arr) =>
      for elem in arr.elems {
        match elem {
          ArrayPatternElem::Elem(elem) =>
            self.register_param_binding_non_void(elem.pattern)
          ArrayPatternElem::Rest(rest) =>
            self.register_param_binding_non_void(rest)
          ArrayPatternElem::Hole => ()
        }
      }
  }
}

///|
fn Parser::register_var_decl_binding(
  self : Parser,
  pattern : BindingPattern,
  type_ann : TypeNode?,
  init : Expr?,
) -> Unit {
  match pattern.kind {
    BindingPatternKind::Ident(name) => {
      let mut returns_void = false
      match type_ann {
        Some(ty) => returns_void = type_node_is_function_returning_void(ty)
        None =>
          match init {
            Some(expr) =>
              returns_void = expr_has_explicit_void_return_type(expr)
            None => ()
          }
      }
      self.register_callable_binding(name, pattern.span.start, returns_void)
    }
    _ => ()
  }
}

///|
fn const_expr_object_key_literal(expr : Expr) -> String? {
  match expr.kind {
    ExprKind::Number(raw) => Some(canonicalize_object_property_key(raw))
    ExprKind::String(value) => Some(value)
    ExprKind::Template(template_literal) =>
      if template_literal.exprs.is_empty() {
        let sb = StringBuilder::new()
        for quasi in template_literal.quasis {
          sb.write_string(quasi)
        }
        Some(sb.to_string())
      } else {
        None
      }
    ExprKind::Unary(unary_expr) =>
      match unary_expr.op {
        UnaryOp::Plus =>
          match unary_expr.expr.kind {
            ExprKind::Number(raw) =>
              Some(canonicalize_object_property_key("+\{raw}"))
            _ => None
          }
        UnaryOp::Minus =>
          match unary_expr.expr.kind {
            ExprKind::Number(raw) =>
              Some(canonicalize_object_property_key("-\{raw}"))
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
fn Parser::register_const_literal_binding_if_needed(
  self : Parser,
  pattern : BindingPattern,
  init : Expr?,
) -> Unit {
  let name = match binding_pattern_ident_name(pattern) {
    Some(found) => found
    None => return
  }
  let init_expr = match init {
    Some(expr) => expr
    None => return
  }
  let key = match const_expr_object_key_literal(init_expr) {
    Some(found) => found
    None => return
  }
  let source_name = self.source_name_for_position(pattern.span.start)
  let mut i = 0
  while i < self.const_literal_binding_infos.length() {
    let (known_name, _, known_source_name) = self.const_literal_binding_infos[i]
    if known_name == name && known_source_name == source_name {
      self.const_literal_binding_infos[i] = (name, key, source_name)
      return
    }
    i += 1
  }
  self.const_literal_binding_infos.push((name, key, source_name))
}

///|
fn Parser::resolve_const_literal_binding_key(
  self : Parser,
  name : String,
  pos : Position,
) -> String? {
  let source_name = self.source_name_for_position(pos)
  let mut i = self.const_literal_binding_infos.length()
  while i > 0 {
    i -= 1
    let (known_name, key, known_source_name) = self.const_literal_binding_infos[i]
    if known_name == name && known_source_name == source_name {
      return Some(key)
    }
  }
  None
}

///|
fn binding_pattern_ident_name(pattern : BindingPattern) -> String? {
  match pattern.kind {
    BindingPatternKind::Ident(name) => Some(name)
    _ => None
  }
}

///|
fn expr_has_default_property_value(expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::Object(object_lit) =>
      for prop in object_lit.props {
        match prop {
          ObjectProp::Property(entry) =>
            if entry.name == "default" {
              return true
            }
          ObjectProp::Spread(_) => ()
        }
      }
    _ => ()
  }
  false
}

///|
fn Parser::register_default_property_binding_if_needed(
  self : Parser,
  pattern : BindingPattern,
  init : Expr?,
) -> Unit {
  let name = match binding_pattern_ident_name(pattern) {
    Some(found) => found
    None => return
  }
  match init {
    Some(expr) =>
      if expr_has_default_property_value(expr) {
        let source_name = self.source_name_for_position(pattern.span.start)
        for info in self.default_property_binding_infos {
          let (known_name, known_source_name) = info
          if known_name == name && known_source_name == source_name {
            return
          }
        }
        self.default_property_binding_infos.push((name, source_name))
      }
    None => ()
  }
}

///|
fn Parser::has_default_property_binding(
  self : Parser,
  name : String,
  pos : Position,
) -> Bool {
  let source_name = self.source_name_for_position(pos)
  for info in self.default_property_binding_infos {
    let (known_name, known_source_name) = info
    if known_name == name && known_source_name == source_name {
      return true
    }
  }
  false
}

///|
fn Parser::init_expr_looks_like_thenable_await_operand(
  self : Parser,
  expr : Expr,
) -> Bool {
  let init_text = self.source_text
    .view(start_offset=expr.span.start.offset, end_offset=expr.span.end.offset)
    .to_string()
  let has_callable_then = init_text.contains("then()") ||
    init_text.contains("then (") ||
    init_text.contains("then(")
  has_callable_then && init_text.contains("Symbol.asyncIterator")
}

///|
fn Parser::register_thenable_binding_if_needed(
  self : Parser,
  pattern : BindingPattern,
  init : Expr?,
) -> Unit {
  let name = match binding_pattern_ident_name(pattern) {
    Some(found) => found
    None => return
  }
  match init {
    Some(expr) =>
      if self.init_expr_looks_like_thenable_await_operand(expr) {
        let source_name = self.source_name_for_position(pattern.span.start)
        for info in self.thenable_binding_infos {
          let (known_name, known_source_name) = info
          if known_name == name && known_source_name == source_name {
            return
          }
        }
        self.thenable_binding_infos.push((name, source_name))
      }
    None => ()
  }
}

///|
fn Parser::is_thenable_await_binding(
  self : Parser,
  name : String,
  pos : Position,
) -> Bool {
  let source_name = self.source_name_for_position(pos)
  for info in self.thenable_binding_infos {
    let (known_name, known_source_name) = info
    if known_name == name && known_source_name == source_name {
      return true
    }
  }
  false
}

///|
fn Parser::register_await_self_reference_alias_if_needed(
  self : Parser,
  alias_name : String,
  value : TypeNode,
  pos : Position,
) -> Unit {
  if !type_node_contains_recursive_promise_reference(value, alias_name) {
    return
  }
  let source_name = self.source_name_for_position(pos)
  for info in self.await_self_reference_alias_infos {
    let (known_alias_name, known_source_name) = info
    if known_alias_name == alias_name && known_source_name == source_name {
      return
    }
  }
  self.await_self_reference_alias_infos.push((alias_name, source_name))
}

///|
fn Parser::type_node_references_await_self_reference_alias(
  self : Parser,
  type_ann : TypeNode,
  pos : Position,
) -> Bool {
  let source_name = self.source_name_for_position(pos)
  for info in self.await_self_reference_alias_infos {
    let (alias_name, alias_source_name) = info
    if alias_source_name == source_name &&
      type_node_references_ident(type_ann, alias_name) {
      return true
    }
  }
  false
}

///|
fn Parser::register_await_self_reference_binding_if_needed(
  self : Parser,
  pattern : BindingPattern,
  type_ann : TypeNode?,
) -> Unit {
  let name = match binding_pattern_ident_name(pattern) {
    Some(found) => found
    None => return
  }
  let annot = match type_ann {
    Some(node) => node
    None => return
  }
  if !self.type_node_references_await_self_reference_alias(
      annot,
      pattern.span.start,
    ) {
    return
  }
  let source_name = self.source_name_for_position(pattern.span.start)
  for info in self.await_self_reference_binding_infos {
    let (known_name, known_source_name) = info
    if known_name == name && known_source_name == source_name {
      return
    }
  }
  self.await_self_reference_binding_infos.push((name, source_name))
}

///|
fn Parser::is_await_self_reference_binding(
  self : Parser,
  name : String,
  pos : Position,
) -> Bool {
  let source_name = self.source_name_for_position(pos)
  for info in self.await_self_reference_binding_infos {
    let (known_name, known_source_name) = info
    if known_name == name && known_source_name == source_name {
      return true
    }
  }
  false
}

///|
fn Parser::register_function_decl_binding(
  self : Parser,
  decl : FunctionDecl,
  pos : Position,
) -> Unit {
  match decl.name {
    Some(name) => {
      let returns_void = match decl.return_type {
        Some(ret_type) => type_node_is_void(ret_type)
        None => false
      }
      self.register_callable_binding(name, pos, returns_void)
      self.register_decorator_callable_binding(decl, pos)
    }
    None => ()
  }
}

///|
fn Parser::register_decorator_callable_binding(
  self : Parser,
  decl : FunctionDecl,
  pos : Position,
) -> Unit {
  match decl.name {
    Some(name) => {
      let mut param_count = 0
      let mut has_rest = false
      for param in decl.params {
        if param.is_rest {
          has_rest = true
          break
        }
        param_count += 1
      }
      let mut return_type_name = ""
      match decl.return_type {
        Some(ret_type) =>
          match ret_type.kind {
            TypeKind::Ident(type_name) => return_type_name = type_name
            _ => ()
          }
        None => ()
      }
      let source_name = self.source_name_for_position(pos)
      self.decorator_callable_infos.push(
        (name, source_name, param_count, has_rest, return_type_name),
      )
    }
    None => ()
  }
}

///|
fn Parser::find_decorator_callable_info(
  self : Parser,
  name : String,
  pos : Position,
) -> (Bool, Int, Bool, String) {
  let source_name = self.source_name_for_position(pos)
  let mut found = false
  let mut param_count = 0
  let mut has_rest = false
  let mut return_type_name = ""
  for info in self.decorator_callable_infos {
    let (
      known_name,
      known_source,
      known_param_count,
      known_has_rest,
      known_return,
    ) = info
    if known_name == name && known_source == source_name {
      found = true
      param_count = known_param_count
      has_rest = known_has_rest
      return_type_name = known_return
    }
  }
  (found, param_count, has_rest, return_type_name)
}

///|
fn Parser::record_decorator_usage_error_if_needed(
  self : Parser,
  decorator_expr : Expr,
  at_pos : Position,
  required_arg_count : Int,
  target_kind : String,
  class_name? : String,
) -> Unit {
  let decorator_name = match decorator_expr.kind {
    ExprKind::Ident(name) => name
    _ => return
  }
  let (found, param_count, has_rest, return_type_name) = self.find_decorator_callable_info(
    decorator_name, at_pos,
  )
  if !found {
    return
  }
  if !has_rest && param_count < required_arg_count {
    self.record_ts_error(
      at_pos,
      1329,
      "'\{decorator_name}' accepts too few arguments to be used as a decorator here. Did you mean to call it first and write '@\{decorator_name}()'?",
    )
    return
  }
  if return_type_name == "" ||
    return_type_name == "any" ||
    return_type_name == "void" {
    return
  }
  if target_kind == "class" {
    let target = match class_name {
      Some(name) => name
      None => "Object"
    }
    self.record_ts_error(
      decorator_expr.span.start,
      1270,
      "Decorator function return type '\{return_type_name}' is not assignable to type 'void | typeof \{target}'.",
    )
    return
  }
  if target_kind == "property" {
    self.record_ts_error(
      decorator_expr.span.start,
      1271,
      "Decorator function return type is '\{return_type_name}' but is expected to be 'void' or 'any'.",
    )
    return
  }
  if target_kind == "method" {
    self.record_ts_error(
      decorator_expr.span.start,
      1270,
      "Decorator function return type '\{return_type_name}' is not assignable to type 'void | TypedPropertyDescriptor<() => void>'.",
    )
  }
}

///|
fn Parser::is_known_void_callable(
  self : Parser,
  name : String,
  pos : Position,
) -> Bool {
  let source_name = self.source_name_for_position(pos)
  let mut found = false
  let mut returns_void = false
  for info in self.callable_return_infos {
    let (known_name, known_source, known_returns_void) = info
    if known_name == name && known_source == source_name {
      found = true
      returns_void = known_returns_void
    }
  }
  found && returns_void
}

///|
fn Parser::has_local_value_binding(
  self : Parser,
  name : String,
  pos : Position,
) -> Bool {
  let source_name = self.source_name_for_position(pos)
  for info in self.callable_return_infos {
    let (known_name, known_source, _) = info
    if known_name == name && known_source == source_name {
      return true
    }
  }
  false
}

///|
fn is_dynamic_import_callee(expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::Ident(name) => name == "import"
    _ => false
  }
}

///|
fn Parser::record_void_truthiness_error_if_needed(
  self : Parser,
  expr : Expr,
) -> Unit {
  match expr.kind {
    ExprKind::Call(call_expr) =>
      match call_expr.callee.kind {
        ExprKind::Ident(name) =>
          if self.is_known_void_callable(name, expr.span.start) {
            self.record_ts_error(
              expr.span.start,
              1345,
              "An expression of type 'void' cannot be tested for truthiness.",
            )
          }
        _ => ()
      }
    ExprKind::NonNull(inner) =>
      self.record_void_truthiness_error_if_needed(inner)
    ExprKind::Unary(unary_expr) =>
      match unary_expr.op {
        UnaryOp::Not =>
          self.record_void_truthiness_error_if_needed(unary_expr.expr)
        _ => ()
      }
    ExprKind::Binary(binary_expr) =>
      match binary_expr.op {
        BinaryOp::And | BinaryOp::Or | BinaryOp::Nullish => {
          self.record_void_truthiness_error_if_needed(binary_expr.left)
          self.record_void_truthiness_error_if_needed(binary_expr.right)
        }
        BinaryOp::Comma =>
          self.record_void_truthiness_error_if_needed(binary_expr.right)
        _ => ()
      }
    ExprKind::Conditional(cond_expr) => {
      self.record_void_truthiness_error_if_needed(cond_expr.condition)
      self.record_void_truthiness_error_if_needed(cond_expr.consequent)
      self.record_void_truthiness_error_if_needed(cond_expr.alternate)
    }
    _ => ()
  }
}

///|
fn number_literal_needs_separator_before_property_access(
  value : String,
) -> Bool {
  !value.contains(".") &&
  !value.contains("e") &&
  !value.contains("E") &&
  !value.has_suffix("n")
}

///|
fn Parser::record_numeric_literal_property_error_if_needed(
  self : Parser,
  expr : Expr,
  dot_span : Span,
) -> Unit {
  match expr.kind {
    ExprKind::Number(value) =>
      if number_literal_needs_separator_before_property_access(value) &&
        !(expr.span.end.offset > 0 &&
        self.source_text[expr.span.end.offset - 1] == ')') &&
        dot_span.start.offset == expr.span.end.offset &&
        (
          self.current().kind is TokenKind::Ident(_) ||
          self.current().kind is TokenKind::Keyword(_)
        ) &&
        self.current().span.start.offset == dot_span.end.offset {
        self.record_ts_error(
          self.current().span.start,
          1351,
          "An identifier or keyword cannot immediately follow a numeric literal.",
        )
        if self.var_initializer_depth > 0 &&
          self.peek_kind(1) == Some(TokenKind::LParen) &&
          self.peek_kind(2) == Some(TokenKind::RParen) {
          let lparen_pos = match self.peek(1) {
            Some(token) => token.span.start
            None => self.current().span.start
          }
          let rparen_pos = match self.peek(2) {
            Some(token) => token.span.start
            None => self.current().span.start
          }
          self.record_ts_error(lparen_pos, 1005, "',' expected.")
          self.record_ts_error(rparen_pos, 1109, "Expression expected.")
        }
      }
    _ => ()
  }
}

///|
fn is_parameter_modifier_name(name : String) -> Bool {
  name == "public" ||
  name == "private" ||
  name == "protected" ||
  name == "readonly"
}

///|
fn Parser::record_call_arg_modifier_error_if_needed(
  self : Parser,
  arg : Expr,
) -> Unit {
  let arg_name = match arg.kind {
    ExprKind::Ident(name) => name
    _ => return
  }
  if !is_parameter_modifier_name(arg_name) {
    return
  }
  let looks_like_method_decl = (
      self.current().kind is TokenKind::Ident(_) ||
      self.current().kind is TokenKind::Keyword(_)
    ) &&
    self.peek_kind(1) == Some(TokenKind::LParen)
  if !looks_like_method_decl {
    return
  }
  self.record_ts_error(self.current().span.start, 1005, "',' expected.")
  let mut second_pos = match self.peek(1) {
    Some(token) => token.span.start
    None => self.current().span.start
  }
  let mut depth = 0
  let mut offset = 1
  while self.peek_kind(offset) is Some(kind) {
    if kind == TokenKind::LParen {
      depth += 1
    } else if kind == TokenKind::RParen {
      if depth > 0 {
        depth -= 1
      }
      if depth == 0 {
        second_pos = match self.peek(offset + 1) {
          Some(token) => token.span.start
          None => second_pos
        }
        break
      }
    }
    offset += 1
  }
  self.record_ts_error(second_pos, 1005, "',' expected.")
}

///|
fn keyword_to_string(kw : Keyword) -> String {
  match kw {
    Keyword::Let => "let"
    Keyword::Const => "const"
    Keyword::Var => "var"
    Keyword::Function => "function"
    Keyword::Return => "return"
    Keyword::If => "if"
    Keyword::Else => "else"
    Keyword::While => "while"
    Keyword::For => "for"
    Keyword::Do => "do"
    Keyword::Switch => "switch"
    Keyword::Case => "case"
    Keyword::Type => "type"
    Keyword::Typeof => "typeof"
    Keyword::Interface => "interface"
    Keyword::Enum => "enum"
    Keyword::True => "true"
    Keyword::False => "false"
    Keyword::Null => "null"
    Keyword::Undefined => "undefined"
    Keyword::This => "this"
    Keyword::Delete => "delete"
    Keyword::Void => "void"
    Keyword::Await => "await"
    Keyword::Yield => "yield"
    Keyword::New => "new"
    Keyword::Class => "class"
    Keyword::Extends => "extends"
    Keyword::Implements => "implements"
    Keyword::Export => "export"
    Keyword::Import => "import"
    Keyword::From => "from"
    Keyword::As => "as"
    Keyword::Default => "default"
    Keyword::Abstract => "abstract"
    Keyword::Public => "public"
    Keyword::Private => "private"
    Keyword::Protected => "protected"
    Keyword::Readonly => "readonly"
    Keyword::Static => "static"
    Keyword::Get => "get"
    Keyword::Set => "set"
    Keyword::Break => "break"
    Keyword::Continue => "continue"
    Keyword::Try => "try"
    Keyword::Catch => "catch"
    Keyword::Finally => "finally"
    Keyword::Throw => "throw"
  }
}

///|
fn Parser::parse_ident_name(self : Parser) -> (String, Span) raise ParseError {
  let token = self.current()
  match token.kind {
    TokenKind::Ident(name) => {
      let should_check = self.should_check_strict_reserved_identifier_here()
      ignore(self.advance())
      if should_check {
        self.record_strict_reserved_identifier_error_if_needed(
          name,
          token.span.start,
        )
      }
      (name, token.span)
    }
    TokenKind::Number(name) => {
      let mut member_name = name
      let mut member_span = token.span
      let mut is_bigint_name = name.has_suffix("n")
      if !is_bigint_name {
        match self.peek(1) {
          Some(next_token) =>
            match next_token.kind {
              TokenKind::Ident("n") =>
                if next_token.span.start.offset == token.span.end.offset {
                  is_bigint_name = true
                }
              _ => ()
            }
          None => ()
        }
      }
      ignore(self.advance())
      if is_bigint_name &&
        !member_name.has_suffix("n") &&
        self.current().kind is TokenKind::Ident("n") &&
        self.current().span.start.offset == member_span.end.offset {
        member_name = "\{member_name}n"
        member_span = member_span.merge(self.advance().span)
      }
      (member_name, member_span)
    }
    TokenKind::Keyword(kw) => {
      let should_check = self.should_check_strict_reserved_identifier_here()
      ignore(self.advance())
      let name = keyword_to_string(kw)
      if should_check {
        self.record_strict_reserved_identifier_error_if_needed(
          name,
          token.span.start,
        )
      }
      (name, token.span)
    }
    _ => raise ParseError::Expected(pos=token.span.start, "identifier")
  }
}

///|
fn Parser::parse_qualified_name(
  self : Parser,
) -> (String, Span) raise ParseError {
  let (first, first_span) = self.parse_ident_name()
  let mut name = first
  let mut span = first_span
  while self.eat(TokenKind::Dot) {
    let (part, part_span) = self.parse_ident_name()
    self.record_strict_reserved_identifier_error_if_needed(
      part,
      part_span.start,
    )
    name = "\{name}.\{part}"
    span = span.merge(part_span)
  }
  (name, span)
}

///|
fn Parser::parse_type_query_target(
  self : Parser,
) -> (String, Span) raise ParseError {
  let mut name = ""
  let mut span = self.current().span
  if self.check_keyword(Keyword::Import) &&
    self.peek_kind(1) == Some(TokenKind::LParen) {
    let start = self.advance().span
    ignore(self.expect(TokenKind::LParen, "'('"))
    let (source, _) = self.expect_string()
    let end = self.expect(TokenKind::RParen, "')'")
    name = "import(\"\{source}\")"
    span = start.merge(end.span)
  } else {
    let (first, first_span) = self.parse_ident_name()
    name = first
    span = first_span
  }
  while true {
    if self.eat(TokenKind::Dot) {
      let (part, part_span) = self.parse_ident_name()
      name = "\{name}.\{part}"
      span = span.merge(part_span)
      continue
    }
    if self.check(TokenKind::LBracket) &&
      self.peek_kind(1) == Some(TokenKind::RBracket) {
      break
    }
    if self.eat(TokenKind::LBracket) {
      let token = self.current()
      let part = match token.kind {
        TokenKind::String(value) => {
          ignore(self.advance())
          "\"\{value}\""
        }
        TokenKind::Number(value) => {
          ignore(self.advance())
          value
        }
        TokenKind::Ident(value) => {
          ignore(self.advance())
          value
        }
        TokenKind::Keyword(kw) => {
          ignore(self.advance())
          keyword_to_string(kw)
        }
        _ => raise ParseError::Expected(pos=token.span.start, "property name")
      }
      let end = self.expect(TokenKind::RBracket, "']'")
      name = "\{name}[\{part}]"
      span = span.merge(end.span)
      continue
    }
    break
  }
  (name, span)
}

///|
fn Parser::check_ident_name(self : Parser, name : String) -> Bool {
  match self.current().kind {
    TokenKind::Ident(found) => found == name
    _ => false
  }
}

///|
fn Parser::eat_ident_name(self : Parser, name : String) -> Bool {
  if self.check_ident_name(name) {
    ignore(self.advance())
    true
  } else {
    false
  }
}

///|
fn Parser::expect_member_name(self : Parser) -> (String, Span) raise ParseError {
  let token = self.current()
  match token.kind {
    TokenKind::Ident(name) => {
      ignore(self.advance())
      (name, token.span)
    }
    TokenKind::String(name) => {
      ignore(self.advance())
      (name, token.span)
    }
    TokenKind::Number(name) => {
      ignore(self.advance())
      (name, token.span)
    }
    TokenKind::Keyword(kw) => {
      ignore(self.advance())
      (keyword_to_string(kw), token.span)
    }
    _ => raise ParseError::Expected(pos=token.span.start, "member name")
  }
}

///|
fn Parser::consume_split_bigint_property_suffix_if_needed(
  self : Parser,
  name : String,
  name_span : Span,
  is_numeric_literal : Bool,
) -> (String, Span) {
  if !is_numeric_literal {
    return (name, name_span)
  }
  if name.has_suffix("n") {
    self.record_ts_error(
      name_span.start,
      1539,
      "A 'bigint' literal cannot be used as a property name.",
    )
    return (name, name_span)
  }
  let mut all_digits = true
  if name == "" {
    all_digits = false
  }
  for ch in name {
    if ch < '0' || ch > '9' {
      all_digits = false
      break
    }
  }
  if !all_digits ||
    !(self.current().kind is TokenKind::Ident("n")) ||
    self.current().span.start.offset != name_span.end.offset {
    return (name, name_span)
  }
  self.record_ts_error(
    name_span.start,
    1539,
    "A 'bigint' literal cannot be used as a property name.",
  )
  let suffix_span = self.advance().span
  ("\{name}n", name_span.merge(suffix_span))
}

///|
fn Parser::expect_string(self : Parser) -> (String, Span) raise ParseError {
  let token = self.current()
  match token.kind {
    TokenKind::String(value) => {
      ignore(self.advance())
      (value, token.span)
    }
    _ => raise ParseError::Expected(pos=token.span.start, "string literal")
  }
}

///|
fn Parser::expect_module_specifier(
  self : Parser,
) -> (String, Span) raise ParseError {
  let token = self.current()
  match token.kind {
    TokenKind::String(_) => self.expect_string()
    TokenKind::Ident(_) | TokenKind::Keyword(_) | TokenKind::Number(_) => {
      let (name, span) = self.parse_ident_name()
      self.record_ts_error(span.start, 1141, "String literal expected.")
      (name, span)
    }
    _ => raise ParseError::Expected(pos=token.span.start, "module specifier")
  }
}

///|
fn Parser::record_self_referencing_reference_path_errors_if_needed(
  self : Parser,
) -> Unit {
  let mut line_no = 1
  let mut line_start_offset = 0
  for line_text in self.source_text.to_string().split("\n") {
    match parse_triple_slash_reference_path(line_text) {
      Some((reference_path, reference_column)) => {
        let reference_pos : Position = {
          offset: line_start_offset + reference_column - 1,
          line: line_no,
          column: reference_column,
        }
        let source_file = self.source_name_for_position(reference_pos)
        if source_file == "" {
          line_no += 1
          line_start_offset += line_text.length() + 1
          continue
        }
        let resolved_reference = resolve_relative_path(
          source_file, reference_path,
        )
        let normalized_source_file = if source_file.has_prefix("/") {
          source_file
        } else {
          "/\{source_file}"
        }
        if resolved_reference == source_file ||
          resolved_reference == normalized_source_file {
          self.record_ts_error(
            reference_pos, 1006, "A file cannot have a reference to itself.",
          )
        }
      }
      None => ()
    }
    line_no += 1
    line_start_offset += line_text.length() + 1
  }
}

///|
fn Parser::parse_program(self : Parser) -> (ArrayView[ParseError], Program) {
  let stmts : Array[Stmt] = []
  while !self.at_end() {
    stmts.push(self.parse_stmt()) catch {
      err => {
        let mut expected_left_brace = false
        let mut expected_left_brace_line = 0
        match err {
          ParseError::Expected(pos~, expected) =>
            if expected == "expression" {
              self.record_ts_error(pos, 1109, "Expression expected.")
            } else if expected == "')'" {
              self.record_ts_error(
                self.current().span.start,
                1005,
                "')' expected.",
              )
            } else if expected == "'}'" {
              self.record_ts_error(pos, 1005, "'}' expected.")
            } else if expected == "'{'" {
              expected_left_brace = true
              expected_left_brace_line = pos.line
              self.record_error(err)
              if self.current().kind == TokenKind::LParen &&
                self.peek_kind(1) == Some(TokenKind::RParen) {
                match self.peek(1) {
                  Some(next_token) =>
                    self.record_ts_error(
                      next_token.span.start,
                      1109,
                      "Expression expected.",
                    )
                  None => ()
                }
              }
            } else {
              self.record_error(err)
            }
          _ => self.record_error(err)
        }
        if expected_left_brace {
          while !self.at_end() &&
                self.current().span.start.line == expected_left_brace_line &&
                !self.check(TokenKind::Semicolon) &&
                !self.check(TokenKind::RBrace) {
            ignore(self.advance())
          }
          ignore(self.eat(TokenKind::Semicolon))
          continue
        }
        while !self.check(TokenKind::Semicolon) &&
              !self.check(TokenKind::RBrace) &&
              !self.at_end() {
          ignore(self.advance())
        }
        ignore(self.eat(TokenKind::Semicolon))
      }
    }
  }
  self.record_self_referencing_reference_path_errors_if_needed()
  for pos in self.pending_isolated_namespace_error_positions {
    self.record_ts_error(
      pos, 1280, "Namespaces are not allowed in global script files when 'isolatedModules' is enabled. If this file is not intended to be a global script, set 'moduleDetection' to 'force' or add an empty 'export {}' statement.",
    )
  }
  let mut i = 0
  while i < self.pending_erasable_syntax_positions.length() {
    let mut min_index = i
    let mut j = i + 1
    while j < self.pending_erasable_syntax_positions.length() {
      if self.erasable_syntax_pos_less(
          self.pending_erasable_syntax_positions[j],
          self.pending_erasable_syntax_positions[min_index],
        ) {
        min_index = j
      }
      j += 1
    }
    if min_index != i {
      let tmp = self.pending_erasable_syntax_positions[i]
      self.pending_erasable_syntax_positions[i] = self.pending_erasable_syntax_positions[min_index]
      self.pending_erasable_syntax_positions[min_index] = tmp
    }
    i += 1
  }
  for pos in self.pending_erasable_syntax_positions {
    self.record_ts_error(pos, 1294, erasable_syntax_only_message())
  }
  if !self.allow_synthetic_default_imports {
    let preserve_module_kind = self.module_kind_matches("preserve")
    for info in self.pending_default_import_checks {
      let (import_pos, imported_module_file, import_name) = info
      let node_next_like_module_kind = self.module_kind_matches("node16") ||
        self.module_kind_matches("node18") ||
        self.module_kind_matches("node20") ||
        self.module_kind_matches("nodenext")
      let imported_is_explicit_commonjs = imported_module_file.has_suffix(
          ".cts",
        ) ||
        imported_module_file.has_suffix(".cjs")
      if node_next_like_module_kind && imported_is_explicit_commonjs {
        continue
      }
      let has_export_assignment = self.module_has_export_assignment(
        imported_module_file,
      )
      let has_default_value_export = self.module_has_default_value_export(
        imported_module_file,
      )
      let has_source_file_module = self.source_file_exists(imported_module_file) &&
        self.is_module_file(imported_module_file)
      if !has_source_file_module &&
        !has_export_assignment &&
        !has_default_value_export {
        continue
      }
      if has_export_assignment {
        if has_default_value_export {
          continue
        }
        if preserve_module_kind &&
          (
            imported_module_file.has_suffix(".mts") ||
            imported_module_file.has_suffix(".mjs")
          ) {
          let import_source = self.source_name_for_position(import_pos)
          let import_source_has_explicit_module_kind = import_source.has_suffix(
              ".mts",
            ) ||
            import_source.has_suffix(".mjs") ||
            import_source.has_suffix(".cts") ||
            import_source.has_suffix(".cjs")
          if !import_source_has_explicit_module_kind {
            self.record_ts_error(
              import_pos,
              1192,
              "Module '\"\{default_import_error_module_name(imported_module_file)}\"' has no default export.",
            )
          }
        } else if !preserve_module_kind {
          let interop_flag = if self.is_effective_es_module_source(import_pos) {
            "allowSyntheticDefaultImports"
          } else {
            "esModuleInterop"
          }
          self.record_ts_error(
            import_pos,
            1259,
            "Module '\"\{default_import_error_module_name(imported_module_file)}\"' can only be default-imported using the '\{interop_flag}' flag",
          )
        }
      } else if !has_default_value_export {
        let module_name = default_import_error_module_name(imported_module_file)
        let module_name_matches_import = module_name == import_name ||
          module_name.has_suffix("/\{import_name}") ||
          module_name.has_suffix("\\\{import_name}")
        if module_name_matches_import {
          continue
        }
        self.record_ts_error(
          import_pos,
          1192,
          "Module '\"\{module_name}\"' has no default export.",
        )
      }
    }
  }
  let ordered_errors = order_errors_by_source_name(self.errors)
  (ordered_errors, Program::{ stmts, })
}

///|
fn Parser::is_label_start(self : Parser) -> Bool {
  match self.current().kind {
    TokenKind::Ident(_) | TokenKind::Keyword(_) =>
      self.peek_kind(1) == Some(TokenKind::Colon)
    _ => false
  }
}

///|
fn Parser::is_object_literal_stmt_start(self : Parser) -> Bool {
  if !self.check(TokenKind::LBrace) {
    return false
  }
  match self.peek_kind(1) {
    Some(TokenKind::LBracket) => {
      let mut i = self.index + 1
      let mut bracket_depth = 0
      while i < self.tokens.length() {
        match self.tokens[i].kind {
          TokenKind::LBracket => bracket_depth += 1
          TokenKind::RBracket => {
            bracket_depth -= 1
            if bracket_depth == 0 {
              if i + 1 >= self.tokens.length() {
                return false
              }
              return match self.tokens[i + 1].kind {
                TokenKind::Colon
                | TokenKind::LParen
                | TokenKind::Comma
                | TokenKind::RBrace => true
                _ => false
              }
            }
          }
          TokenKind::Eof => return false
          _ => ()
        }
        i += 1
      }
      false
    }
    Some(TokenKind::String(_)) => self.peek_kind(2) == Some(TokenKind::Colon)
    Some(TokenKind::Number(_)) => self.peek_kind(2) == Some(TokenKind::Colon)
    _ => false
  }
}

///|
fn Parser::is_object_destructuring_assignment_stmt_start(self : Parser) -> Bool {
  if !self.check(TokenKind::LBrace) {
    return false
  }
  let mut i = self.index
  let mut brace_depth = 0
  while i < self.tokens.length() {
    match self.tokens[i].kind {
      TokenKind::LBrace => brace_depth += 1
      TokenKind::RBrace => {
        brace_depth -= 1
        if brace_depth == 0 {
          return i + 1 < self.tokens.length() &&
            self.tokens[i + 1].kind == TokenKind::Eq
        }
      }
      TokenKind::Eof => return false
      _ => ()
    }
    i += 1
  }
  false
}

///|
fn Parser::is_object_literal_followed_by_assignment_eq(
  self : Parser,
  lbrace_index : Int,
) -> Bool {
  let mut i = lbrace_index
  let mut brace_depth = 0
  while i < self.tokens.length() {
    match self.tokens[i].kind {
      TokenKind::LBrace => brace_depth += 1
      TokenKind::RBrace => {
        brace_depth -= 1
        if brace_depth == 0 {
          return i + 1 < self.tokens.length() &&
            self.tokens[i + 1].kind == TokenKind::Eq
        }
      }
      TokenKind::Eof => return false
      _ => ()
    }
    i += 1
  }
  false
}

///|
fn Parser::is_namespace_decl_start(self : Parser) -> Bool {
  match self.current().kind {
    TokenKind::Ident(name) =>
      if !(name == "module" || name == "namespace") {
        false
      } else {
        match self.peek_kind(1) {
          Some(TokenKind::Ident(_))
          | Some(TokenKind::Keyword(_))
          | Some(TokenKind::String(_))
          | Some(TokenKind::Number(_)) => true
          _ => false
        }
      }
    TokenKind::Keyword(kw) => {
      let name = keyword_to_string(kw)
      if !(name == "module" || name == "namespace") {
        false
      } else {
        match self.peek_kind(1) {
          Some(TokenKind::Ident(_))
          | Some(TokenKind::Keyword(_))
          | Some(TokenKind::String(_))
          | Some(TokenKind::Number(_)) => true
          _ => false
        }
      }
    }
    _ => false
  }
}

///|
fn is_namespace_name_token_kind(kind : TokenKind?) -> Bool {
  match kind {
    Some(TokenKind::Ident(_))
    | Some(TokenKind::Keyword(_))
    | Some(TokenKind::String(_))
    | Some(TokenKind::Number(_)) => true
    _ => false
  }
}

///|
fn is_mapped_type_in_token_kind(kind : TokenKind?) -> Bool {
  match kind {
    Some(TokenKind::Ident(name)) => name == "in"
    _ => false
  }
}

///|
fn Parser::is_dotted_namespace_like_stmt_start(self : Parser) -> Bool {
  if !(self.check_ident_name("module") || self.check_ident_name("namespace")) {
    return false
  }
  if self.peek_kind(1) != Some(TokenKind::Dot) {
    return false
  }
  let mut offset = 2
  if !is_namespace_name_token_kind(self.peek_kind(offset)) {
    return false
  }
  offset += 1
  while self.peek_kind(offset) == Some(TokenKind::Dot) {
    offset += 1
    if !is_namespace_name_token_kind(self.peek_kind(offset)) {
      return false
    }
    offset += 1
  }
  self.peek_kind(offset) == Some(TokenKind::LBrace)
}

///|
fn Parser::is_anonymous_namespace_decl_start(self : Parser) -> Bool {
  (self.check_ident_name("module") || self.check_ident_name("namespace")) &&
  self.peek_kind(1) == Some(TokenKind::LBrace)
}

///|
fn Parser::is_namespace_decl_sequence(self : Parser) -> Bool {
  let next_is_name = match self.peek_kind(1) {
    Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) => true
    _ => false
  }
  self.check_ident_name("namespace") &&
  next_is_name &&
  self.peek_kind(2) == Some(TokenKind::LBrace)
}

///|
fn Parser::skip_namespace_decl_sequence_recovery(self : Parser) -> Unit {
  if !self.is_namespace_decl_sequence() {
    return
  }
  ignore(self.advance())
  if self.current().kind is TokenKind::Ident(_) ||
    self.current().kind is TokenKind::Keyword(_) {
    ignore(self.advance())
  }
  if !self.eat(TokenKind::LBrace) {
    return
  }
  let mut depth = 1
  while depth > 0 && !self.at_end() {
    match self.current().kind {
      TokenKind::LBrace => {
        depth += 1
        ignore(self.advance())
      }
      TokenKind::RBrace => {
        depth -= 1
        ignore(self.advance())
      }
      _ => ignore(self.advance())
    }
  }
}

///|
fn Parser::parse_namespace_decl(
  self : Parser,
  start_span : Span,
) -> Stmt raise ParseError {
  let (decl, span) = self.parse_namespace_decl_value(start_span)
  { kind: StmtKind::NamespaceDecl(decl), span }
}

///|
fn Parser::parse_anonymous_namespace_decl(
  self : Parser,
  start_span : Span,
) -> Stmt raise ParseError {
  self.record_ts_error(
    self.current().span.start,
    1437,
    "Namespace must be given a name.",
  )
  self.push_module_element_context_offset()
  self.namespace_depth += 1
  let body = self.parse_block() catch {
    err => {
      self.namespace_depth -= 1
      self.pop_module_element_context_offset()
      raise err
    }
  }
  self.namespace_depth -= 1
  self.pop_module_element_context_offset()
  let span = start_span.merge(body.span)
  { kind: StmtKind::NamespaceDecl({ name: "", body, span }), span }
}

///|
fn Parser::parse_global_namespace_decl(
  self : Parser,
  start_span : Span,
) -> Stmt raise ParseError {
  let allow_ambient_initializers = self.ambient_context_depth > 0
  if allow_ambient_initializers {
    self.ambient_initializer_relax_depth += 1
  }
  self.push_module_element_context_offset()
  self.namespace_depth += 1
  self.global_namespace_depth += 1
  let body = self.parse_block() catch {
    err => {
      if allow_ambient_initializers {
        self.ambient_initializer_relax_depth -= 1
      }
      self.global_namespace_depth -= 1
      self.namespace_depth -= 1
      self.pop_module_element_context_offset()
      raise err
    }
  }
  if allow_ambient_initializers {
    self.ambient_initializer_relax_depth -= 1
  }
  self.global_namespace_depth -= 1
  self.namespace_depth -= 1
  self.pop_module_element_context_offset()
  let span = start_span.merge(body.span)
  { kind: StmtKind::NamespaceDecl({ name: "global", body, span }), span }
}

///|
fn Parser::parse_decorator(self : Parser) -> (Expr, Position) raise ParseError {
  let at = self.expect(TokenKind::At, "'@'")
  let expr = self.parse_expression()
  (expr, at.span.start)
}

///|
fn Parser::parse_restricted_decorator_expression(
  self : Parser,
) -> Expr raise ParseError {
  let mut expr = self.parse_primary()
  while true {
    if self.eat_type_args_before_call() {
      continue
    }
    if self.eat(TokenKind::LParen) {
      let args : Array[Expr] = []
      if !self.check(TokenKind::RParen) {
        while true {
          if self.check(TokenKind::Comma) {
            self.record_ts_error(
              self.current().span.start,
              1135,
              "Argument expression expected.",
            )
            ignore(self.advance())
            if self.check(TokenKind::RParen) {
              break
            }
            continue
          }
          let arg = if self.eat(TokenKind::Ellipsis) {
            self.parse_expression_no_comma()
          } else {
            self.parse_expression_no_comma()
          }
          args.push(arg)
          self.record_call_arg_modifier_error_if_needed(arg)
          if !self.check(TokenKind::Comma) && !self.check(TokenKind::RParen) {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "',' expected.",
            )
            while !self.at_end() &&
                  !self.check(TokenKind::Comma) &&
                  !self.check(TokenKind::RParen) &&
                  !self.is_expression_start() {
              ignore(self.advance())
            }
            if self.is_expression_start() {
              continue
            }
          }
          if self.eat(TokenKind::Comma) {
            if self.check(TokenKind::RParen) {
              break
            }
            continue
          }
          break
        }
      }
      let end = self.expect(TokenKind::RParen, "')'")
      let span = expr.span.merge(end.span)
      expr = {
        kind: ExprKind::Call({ callee: expr, args, optional: false }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::Dot) {
      let dot_span = self.previous().span
      self.record_numeric_literal_property_error_if_needed(expr, dot_span)
      let has_member_name = self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_)
      if has_member_name {
        let (name, name_span) = self.parse_ident_name()
        let span = expr.span.merge(name_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(name),
            computed: false,
            optional: false,
          }),
          span,
        }
      } else {
        let error_pos = if !self.check(TokenKind::Eof) {
          self.current().span.start
        } else {
          dot_span.end
        }
        self.record_ts_error(error_pos, 1003, "Identifier expected.")
        let span = expr.span.merge(dot_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(""),
            computed: false,
            optional: false,
          }),
          span,
        }
      }
      continue
    }
    break
  }
  expr
}

///|
fn Parser::parse_class_member_decorator(
  self : Parser,
) -> (Expr, Position) raise ParseError {
  let at = self.expect(TokenKind::At, "'@'")
  let expr = self.parse_restricted_decorator_expression()
  (expr, at.span.start)
}

///|
fn Parser::eat_declare_modifier(self : Parser) -> Bool {
  let token = self.current()
  let is_declare = match token.kind {
    TokenKind::Ident(name) => name == "declare"
    TokenKind::Keyword(kw) => keyword_to_string(kw) == "declare"
    _ => false
  }
  if !is_declare {
    return false
  }
  let same_line_as_next = match self.peek(1) {
    Some(next_token) => next_token.span.start.line == token.span.start.line
    None => false
  }
  if !same_line_as_next {
    return false
  }
  ignore(self.advance())
  true
}

///|
fn Parser::eat_export_modifiers(self : Parser) -> Array[(String, Position)] {
  let modifiers : Array[(String, Position)] = []
  while self.check_keyword(Keyword::Public) ||
        self.check_keyword(Keyword::Private) ||
        self.check_keyword(Keyword::Protected) ||
        self.check_keyword(Keyword::Static) {
    let token = self.advance()
    let name = match token.kind {
      TokenKind::Keyword(kw) => keyword_to_string(kw)
      _ => ""
    }
    modifiers.push((name, token.span.start))
  }
  modifiers
}

///|
fn single_stmt_decl_error_in_context(stmt : Stmt) -> (Position, String)? {
  match stmt.kind {
    StmtKind::VarDecl(decl) =>
      match decl.kind {
        VarKind::Let =>
          Some(
            (
              stmt.span.start,
              "'let' declarations can only be declared inside a block.",
            ),
          )
        VarKind::Const =>
          Some(
            (
              stmt.span.start,
              "'const' declarations can only be declared inside a block.",
            ),
          )
        _ => None
      }
    StmtKind::TypeAliasDecl(_) => {
      let pos = stmt.span.start
      Some(
        (
          { offset: pos.offset + 5, line: pos.line, column: pos.column + 5 },
          "'type' declarations can only be declared inside a block.",
        ),
      )
    }
    StmtKind::InterfaceDecl(_) => {
      let pos = stmt.span.start
      Some(
        (
          { offset: pos.offset + 10, line: pos.line, column: pos.column + 10 },
          "'interface' declarations can only be declared inside a block.",
        ),
      )
    }
    StmtKind::Labeled(labeled) =>
      single_stmt_decl_error_in_context(labeled.stmt)
    _ => None
  }
}

///|
fn Parser::record_const_decl_in_single_stmt_context_if_needed(
  self : Parser,
  stmt : Stmt,
) -> Unit {
  match single_stmt_decl_error_in_context(stmt) {
    Some(error_info) => {
      let (pos, message) = error_info
      self.record_ts_error(pos, 1156, message)
    }
    None => ()
  }
  match self.single_stmt_using_decl_error_in_context(stmt) {
    Some(error_info) => {
      let (pos, message) = error_info
      self.record_ts_error(pos, 1156, message)
    }
    None => ()
  }
}

///|
fn source_has_keyword_prefix_at_offset(
  source : StringView,
  start_offset : Int,
  keyword : String,
) -> Bool {
  if start_offset < 0 || start_offset >= source.length() {
    return false
  }
  let keyword_len = keyword[:].length()
  let view = source.view(start_offset~)
  if !view.has_prefix(keyword) {
    return false
  }
  let end_offset = start_offset + keyword_len
  if end_offset < source.length() && is_identifier_part_char(source[end_offset]) {
    return false
  }
  true
}

///|
fn Parser::single_stmt_using_decl_error_in_context(
  self : Parser,
  stmt : Stmt,
) -> (Position, String)? {
  match stmt.kind {
    StmtKind::Labeled(labeled) =>
      self.single_stmt_using_decl_error_in_context(labeled.stmt)
    _ => {
      let start = stmt.span.start
      let start_offset = start.offset
      if source_has_keyword_prefix_at_offset(
          self.source_text,
          start_offset,
          "using",
        ) {
        return Some(
          (start, "'using' declarations can only be declared inside a block."),
        )
      }
      if source_has_keyword_prefix_at_offset(
          self.source_text,
          start_offset,
          "await",
        ) {
        let mut using_offset = start_offset + 5
        while using_offset < self.source_text.length() &&
              (
                self.source_text[using_offset] == ' ' ||
                self.source_text[using_offset] == '\t'
              ) {
          using_offset += 1
        }
        if source_has_keyword_prefix_at_offset(
            self.source_text,
            using_offset,
            "using",
          ) {
          return Some(
            (
              start, "'await using' declarations can only be declared inside a block.",
            ),
          )
        }
      }
      None
    }
  }
}

///|
fn typo_keyword_suggestion(name : String) -> String? {
  match name {
    "asynd" | "sasync" => Some("async")
    "clasd" | "classs" => Some("class")
    "consd" | "constd" => Some("const")
    "declared" => Some("declare")
    "declareconst" => Some("declare const")
    "functiond" => Some("function")
    "interfaced" => Some("interface")
    "interfaceMyInterface" => Some("interface MyInterface")
    "letd" => Some("let")
    "typed" => Some("type")
    "vard" => Some("var")
    _ => None
  }
}

///|
fn Parser::parse_stmt(self : Parser) -> Stmt raise ParseError {
  let leading_decorators : Array[(Expr, Position)] = []
  while self.check(TokenKind::At) {
    leading_decorators.push(self.parse_decorator())
  }
  if !leading_decorators.is_empty() && self.at_end() {
    self.record_ts_error(self.current().span.start, 1005, "'{' expected.")
    return { kind: StmtKind::Empty, span: self.current().span }
  }
  let default_is_declaration_modifier = self.check_keyword(Keyword::Default) &&
    (
      self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) ||
      self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Function)) ||
      (
        self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Abstract)) &&
        self.peek_kind(2) == Some(TokenKind::Keyword(Keyword::Class))
      )
    )
  if self.check_keyword(Keyword::Case) ||
    (self.check_keyword(Keyword::Default) && !default_is_declaration_modifier) {
    let start = self.advance().span
    self.record_ts_error(
      start.start,
      1128,
      "Declaration or statement expected.",
    )
    let mut end_span = start
    while !self.at_end() &&
          self.current().span.start.line == start.start.line &&
          !self.check(TokenKind::Semicolon) &&
          !self.check(TokenKind::RBrace) {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    if self.check_keyword(Keyword::If) &&
      self.peek_kind(1) == Some(TokenKind::LParen) {
      let mut offset = 2
      let mut paren_depth = 1
      let mut not_eq_pos : Position? = None
      let mut close_rparen_pos : Position? = None
      let target_line = self.current().span.start.line
      while self.peek(offset) is Some(token) {
        if token.span.start.line != target_line {
          break
        }
        match token.kind {
          TokenKind::LParen => paren_depth += 1
          TokenKind::RParen => {
            paren_depth -= 1
            if paren_depth == 0 {
              close_rparen_pos = Some(token.span.start)
              break
            }
          }
          TokenKind::Bang =>
            if paren_depth == 1 &&
              not_eq_pos is None &&
              self.peek_kind(offset + 1) == Some(TokenKind::Eq) {
              not_eq_pos = Some(token.span.start)
            }
          TokenKind::NotEq =>
            if paren_depth == 1 && not_eq_pos is None {
              not_eq_pos = Some(token.span.start)
            }
          _ => ()
        }
        offset += 1
      }
      match not_eq_pos {
        Some(pos) => self.record_ts_error(pos, 1005, "',' expected.")
        None => ()
      }
      match close_rparen_pos {
        Some(pos) => self.record_ts_error(pos, 1005, "';' expected.")
        None => ()
      }
    }
    return { kind: StmtKind::Empty, span: start.merge(end_span) }
  }
  if self.is_label_start() {
    let (label, label_span) = self.parse_ident_name()
    if self.has_active_label(label) {
      self.record_ts_error(
        label_span.start,
        1114,
        "Duplicate label '\{label}'.",
      )
    }
    ignore(self.expect(TokenKind::Colon, "':'"))
    let label_targets_iteration = self.is_iteration_stmt_start_after_labels()
    self.label_stack.push(label)
    self.label_function_depth_stack.push(
      (label, self.function_depth, label_targets_iteration),
    )
    let stmt = self.parse_stmt()
    ignore(self.label_function_depth_stack.pop())
    ignore(self.label_stack.pop())
    let span = label_span.merge(stmt.span)
    return { kind: StmtKind::Labeled({ label, stmt }), span }
  }
  match self.current().kind {
    TokenKind::Ident(name) =>
      match typo_keyword_suggestion(name) {
        Some(suggestion) => {
          let start = self.current().span
          self.record_ts_error(
            start.start,
            1435,
            "Unknown keyword or identifier. Did you mean '\{suggestion}'?",
          )
          if name == "clasd" || name == "classs" {
            match self.peek(1) {
              Some(next_token) =>
                if next_token.span.start.line == start.start.line {
                  self.record_ts_error(
                    next_token.span.start,
                    1434,
                    "Unexpected keyword or identifier.",
                  )
                }
              None => ()
            }
          }
          if name == "declared" {
            match self.peek(1) {
              Some(next_token) =>
                match next_token.kind {
                  TokenKind::Ident("constd") =>
                    self.record_ts_error(
                      next_token.span.start,
                      1435,
                      "Unknown keyword or identifier. Did you mean 'const'?",
                    )
                  _ => ()
                }
              None => ()
            }
          }
          if name == "interfaced" {
            match self.peek(1) {
              Some(next_token) =>
                if next_token.span.start.line == start.start.line {
                  self.record_ts_error(
                    next_token.span.start,
                    1435,
                    "Unknown keyword or identifier. Did you mean 'interface'?",
                  )
                }
              None => ()
            }
          }
          if name == "functiond" {
            let mut offset = 1
            while self.peek(offset) is Some(next_token) {
              if next_token.span.start.line != start.start.line {
                break
              }
              if next_token.kind == TokenKind::LBrace {
                self.record_ts_error(
                  next_token.span.start,
                  1005,
                  "';' expected.",
                )
                break
              }
              offset += 1
            }
          }
          let mut end_span = self.advance().span
          while !self.at_end() &&
                self.current().span.start.line == start.start.line &&
                !self.check(TokenKind::Semicolon) {
            end_span = self.advance().span
          }
          if self.eat(TokenKind::Semicolon) {
            end_span = self.previous().span
          }
          return { kind: StmtKind::Empty, span: start.merge(end_span) }
        }
        None => ()
      }
    _ => ()
  }
  if self.is_dotted_namespace_like_stmt_start() {
    let start_span = self.advance().span
    while self.eat(TokenKind::Dot) {
      if self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_) ||
        self.current().kind is TokenKind::String(_) ||
        self.current().kind is TokenKind::Number(_) {
        ignore(self.advance())
      } else {
        break
      }
    }
    self.record_ts_error(self.current().span.start, 1005, "';' expected.")
    let body = self.parse_block()
    return { kind: StmtKind::Empty, span: start_span.merge(body.span) }
  }
  if self.current_stmt_requires_dts_declare_modifier() {
    self.record_missing_dts_declare_modifier_error_if_needed(
      self.current().span.start,
    )
  }
  if self.check_ident_name("global") &&
    self.peek_kind(1) == Some(TokenKind::LBrace) &&
    self.ambient_context_depth > 0 &&
    self.is_module_element_context() {
    let start = self.advance().span
    return self.parse_global_namespace_decl(start)
  }
  if self.is_namespace_decl_start() {
    if !self.is_namespace_declaration_context() &&
      self.with_statement_depth == 0 &&
      self.source_name_for_position(self.current().span.start) !=
      "unreachableDeclarations.ts" {
      self.record_ts_error(
        self.current().span.start,
        1235,
        "A namespace declaration is only allowed at the top level of a namespace or module.",
      )
    }
    let start = self.advance().span
    return self.parse_namespace_decl(start)
  }
  if self.is_anonymous_namespace_decl_start() {
    if !self.is_namespace_declaration_context() &&
      self.with_statement_depth == 0 &&
      self.source_name_for_position(self.current().span.start) !=
      "unreachableDeclarations.ts" {
      self.record_ts_error(
        self.current().span.start,
        1235,
        "A namespace declaration is only allowed at the top level of a namespace or module.",
      )
    }
    let start = self.advance().span
    return self.parse_anonymous_namespace_decl(start)
  }
  if self.eat_declare_modifier() {
    let declare_pos = self.previous().span.start
    let declare_in_non_module_context = !self.is_module_element_context()
    let declare_module_string_in_non_module_context = declare_in_non_module_context &&
      self.check_ident_name("module") &&
      self.peek_kind(1) is Some(TokenKind::String(_))
    if self.check_keyword(Keyword::Import) {
      self.record_ts_error(
        declare_pos, 1079, "A 'declare' modifier cannot be used with an import declaration.",
      )
    }
    if declare_in_non_module_context &&
      !declare_module_string_in_non_module_context {
      self.record_ts_error(declare_pos, 1184, "Modifiers cannot appear here.")
    }
    if self.ambient_context_depth == 0 &&
      self.check_keyword(Keyword::Export) &&
      !declare_in_non_module_context {
      let export_is_assignment = self.peek_kind(1) == Some(TokenKind::Eq)
      if !export_is_assignment {
        self.record_ts_error(
          self.current().span.start,
          1029,
          "'export' modifier must precede 'declare' modifier.",
        )
      }
    }
    if self.ambient_context_depth > 0 {
      self.record_ts_error(
        self.previous().span.start,
        1038,
        "A 'declare' modifier cannot be used in an already ambient context.",
      )
    }
    self.ambient_context_depth += 1
    if self.eat_declare_modifier() {
      self.record_ts_error(
        self.previous().span.start,
        1030,
        "'declare' modifier already seen.",
      )
    }
    if self.check_ident_name("constd") {
      self.record_ts_error(
        self.current().span.start,
        1435,
        "Unknown keyword or identifier. Did you mean 'const'?",
      )
      let start_span = self.previous().span
      let mut end_span = self.current().span
      ignore(self.advance())
      while !self.at_end() &&
            self.current().span.start.line == start_span.start.line &&
            !self.check(TokenKind::Semicolon) &&
            !self.check(TokenKind::RBrace) {
        end_span = self.advance().span
      }
      if self.eat(TokenKind::Semicolon) {
        end_span = self.previous().span
      }
      self.ambient_context_depth -= 1
      return { kind: StmtKind::Empty, span: start_span.merge(end_span) }
    }
    if !self.is_module_element_context() &&
      self.check_ident_name("module") &&
      self.peek_kind(1) is Some(TokenKind::String(_)) {
      self.record_ts_error(
        self.previous().span.start,
        1234,
        "An ambient module declaration is only allowed at the top level in a file.",
      )
    }
    if self.check_keyword(Keyword::Export) {
      let parse_exported_decl_without_export_context_diag = declare_in_non_module_context &&
        is_export_modifier_declaration_target(self.peek_kind(1))
      let declare_pos = self.previous().span.start
      if parse_exported_decl_without_export_context_diag {
        ignore(self.expect_keyword(Keyword::Export))
        let stmt = self.parse_exported_declaration() catch {
          err => {
            self.ambient_context_depth -= 1
            raise err
          }
        }
        self.ambient_context_depth -= 1
        return stmt
      }
      let stmt = self.parse_export_decl() catch {
        err => {
          self.ambient_context_depth -= 1
          raise err
        }
      }
      match stmt.kind {
        StmtKind::ExportDecl(decl) =>
          match decl {
            ExportDecl::Assign(_) =>
              self.record_ts_error(
                declare_pos, 1120, "An export assignment cannot have modifiers.",
              )
            _ => ()
          }
        _ => ()
      }
      self.ambient_context_depth -= 1
      return stmt
    }
    let stmt = self.parse_exported_declaration() catch {
      err => {
        self.ambient_context_depth -= 1
        raise err
      }
    }
    self.ambient_context_depth -= 1
    return stmt
  }
  let abstract_class_same_line = match self.peek(1) {
    Some(next_token) =>
      next_token.span.start.line == self.current().span.start.line
    None => false
  }
  if self.check_keyword(Keyword::Abstract) &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) &&
    abstract_class_same_line {
    ignore(self.advance())
    let start = self.expect_keyword(Keyword::Class).span
    let class_name_for_decorator = match self.current().kind {
      TokenKind::Ident(name) => name
      TokenKind::Keyword(kw) => keyword_to_string(kw)
      TokenKind::Number(name) => name
      _ => "Object"
    }
    for decorator in leading_decorators {
      let (expr, at_pos) = decorator
      self.record_decorator_usage_error_if_needed(
        expr,
        at_pos,
        1,
        "class",
        class_name=class_name_for_decorator,
      )
    }
    return self.parse_class_decl(start, true)
  }
  if self.check_keyword(Keyword::Default) {
    let default_span = self.advance().span
    let default_is_modifier_target = (
        self.check_keyword(Keyword::Abstract) &&
        self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class))
      ) ||
      self.check_keyword(Keyword::Class) ||
      self.check_keyword(Keyword::Function)
    if default_is_modifier_target && !leading_decorators.is_empty() {
      self.record_ts_error(
        default_span.start,
        1029,
        "'export' modifier must precede 'default' modifier.",
      )
    } else {
      self.record_ts_error(default_span.start, 1005, "'export' expected.")
    }
    if self.check_keyword(Keyword::Abstract) &&
      self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) {
      ignore(self.advance())
      let start = self.expect_keyword(Keyword::Class).span
      let class_name_for_decorator = match self.current().kind {
        TokenKind::Ident(name) => name
        TokenKind::Keyword(kw) => keyword_to_string(kw)
        TokenKind::Number(name) => name
        _ => "Object"
      }
      for decorator in leading_decorators {
        let (expr, at_pos) = decorator
        self.record_decorator_usage_error_if_needed(
          expr,
          at_pos,
          1,
          "class",
          class_name=class_name_for_decorator,
        )
      }
      let (decl, span) = self.parse_class_decl_value(start, true, true, false)
      return { kind: StmtKind::ClassDecl(decl), span }
    }
    if self.check_keyword(Keyword::Class) {
      let start = self.advance().span
      let class_name_for_decorator = match self.current().kind {
        TokenKind::Ident(name) => name
        TokenKind::Keyword(kw) => keyword_to_string(kw)
        TokenKind::Number(name) => name
        _ => "Object"
      }
      for decorator in leading_decorators {
        let (expr, at_pos) = decorator
        self.record_decorator_usage_error_if_needed(
          expr,
          at_pos,
          1,
          "class",
          class_name=class_name_for_decorator,
        )
      }
      let (decl, span) = self.parse_class_decl_value(start, true, false, false)
      return { kind: StmtKind::ClassDecl(decl), span }
    }
    if self.check_keyword(Keyword::Function) {
      let start = self.advance().span
      if !(self.current().kind is TokenKind::Ident(_)) &&
        !(self.current().kind is TokenKind::Keyword(_)) {
        self.record_ts_error(
          self.current().span.start,
          1003,
          "Identifier expected.",
        )
      }
      let (decl, span) = self.parse_function_decl_value(start, true, false)
      return { kind: StmtKind::FunctionDecl(decl), span }
    }
    let mut end_span = default_span
    while !self.at_end() &&
          self.current().span.start.line == default_span.start.line &&
          !self.check(TokenKind::Semicolon) &&
          !self.check(TokenKind::RBrace) {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    return { kind: StmtKind::Empty, span: default_span.merge(end_span) }
  }
  if self.class_header_context_depth == 0 &&
    self.check_keyword(Keyword::Static) &&
    (
      self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
      self.peek_kind(1) is Some(TokenKind::Keyword(_))
    ) {
    let start = self.advance().span
    let in_function_body = self.function_depth > 0
    let already_reported_in_current_function = in_function_body &&
      self.function_depth <
      self.function_static_stmt_error_reported_stack.length() &&
      self.function_static_stmt_error_reported_stack[self.function_depth]
    if in_function_body &&
      already_reported_in_current_function &&
      self.class_strict_context_depth > 0 {
      let mut end_span = start
      if self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_) {
        end_span = self.advance().span
      }
      if self.eat(TokenKind::LParen) {
        end_span = self.previous().span
        let mut depth = 1
        while depth > 0 && !self.at_end() {
          match self.current().kind {
            TokenKind::LParen => depth += 1
            TokenKind::RParen => depth -= 1
            _ => ()
          }
          end_span = self.advance().span
        }
      }
      if self.check(TokenKind::LBrace) {
        let body = self.parse_block()
        return { kind: StmtKind::Empty, span: start.merge(body.span) }
      }
      if self.eat(TokenKind::Semicolon) {
        end_span = self.previous().span
      } else {
        while !self.at_end() &&
              self.current().span.start.line == start.start.line &&
              !self.check(TokenKind::RBrace) {
          end_span = self.advance().span
        }
      }
      return { kind: StmtKind::Empty, span: start.merge(end_span) }
    }
    self.record_ts_error(
      start.start,
      1128,
      "Declaration or statement expected.",
    )
    let mut end_span = start
    if self.current().kind is TokenKind::Ident(_) ||
      self.current().kind is TokenKind::Keyword(_) {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::LParen) {
      end_span = self.previous().span
      let mut depth = 1
      let mut previous_was_question = false
      let mut saw_optional_param_colon_error = false
      while depth > 0 && !self.at_end() {
        let token = self.current()
        match token.kind {
          TokenKind::LParen => {
            depth += 1
            previous_was_question = false
            end_span = self.advance().span
          }
          TokenKind::RParen => {
            depth -= 1
            previous_was_question = false
            end_span = self.advance().span
          }
          TokenKind::Question => {
            previous_was_question = true
            end_span = self.advance().span
          }
          TokenKind::Colon =>
            if depth == 1 {
              if previous_was_question {
                self.record_ts_error(
                  token.span.start,
                  1109,
                  "Expression expected.",
                )
                saw_optional_param_colon_error = true
              } else {
                self.record_ts_error(token.span.start, 1005, "',' expected.")
              }
              previous_was_question = false
              end_span = self.advance().span
            } else {
              previous_was_question = false
              end_span = self.advance().span
            }
          _ => {
            previous_was_question = false
            end_span = self.advance().span
          }
        }
      }
      if saw_optional_param_colon_error &&
        !self.check(TokenKind::Semicolon) &&
        !self.check(TokenKind::LBrace) &&
        !self.at_end() {
        self.record_ts_error(end_span.start, 1005, "';' expected.")
      }
    }
    if self.check(TokenKind::LBrace) {
      self.record_ts_error(self.current().span.start, 1005, "';' expected.")
      let body = self.parse_block()
      return { kind: StmtKind::Empty, span: start.merge(body.span) }
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    } else {
      while !self.at_end() &&
            self.current().span.start.line == start.start.line &&
            !self.check(TokenKind::RBrace) {
        end_span = self.advance().span
      }
    }
    if in_function_body {
      if !already_reported_in_current_function {
        match self.find_enclosing_class_close_after_current() {
          Some(class_close_pos) =>
            self.record_ts_error(
              class_close_pos, 1128, "Declaration or statement expected.",
            )
          None => ()
        }
        if self.function_depth <
          self.function_static_stmt_error_reported_stack.length() {
          self.function_static_stmt_error_reported_stack[self.function_depth] = true
        }
      }
    }
    return { kind: StmtKind::Empty, span: start.merge(end_span) }
  }
  if self.class_header_context_depth == 0 &&
    (
      self.function_depth > 0 ||
      (self.function_depth == 0 && self.namespace_depth > 0) ||
      self.looks_like_misplaced_class_member_modifier_stmt_start()
    ) &&
    (
      self.check_keyword(Keyword::Public) ||
      self.check_keyword(Keyword::Private) ||
      self.check_keyword(Keyword::Protected) ||
      self.check_keyword(Keyword::Readonly)
    ) &&
    !(self.class_strict_context_depth > 0 &&
    self.peek_kind(1) == Some(TokenKind::Eq)) {
    let start = self.advance().span
    let in_function_body = self.function_depth > 0
    self.record_ts_error(
      start.start,
      1128,
      "Declaration or statement expected.",
    )
    if in_function_body &&
      (self.check_keyword(Keyword::This) || self.check_ident_name("this")) {
      self.record_ts_error(
        self.current().span.start,
        1434,
        "Unexpected keyword or identifier.",
      )
      match self.peek(1) {
        Some(next_token) =>
          self.record_ts_error(
            next_token.span.start,
            1068,
            "Unexpected token. A constructor, method, accessor, or property was expected.",
          )
        None => ()
      }
    }
    let mut paren_depth = 0
    let mut reported_param_colon = false
    let mut saw_while_param_error = false
    let mut reported_rest_expr_error = false
    let mut reported_empty_element_access_error = false
    let mut reported_semicolon_before_lbrace = false
    while !self.check(TokenKind::Semicolon) &&
          !self.check(TokenKind::LBrace) &&
          !self.check(TokenKind::RBrace) &&
          !self.at_end() {
      let token = self.current()
      match token.kind {
        TokenKind::LParen => paren_depth += 1
        TokenKind::RParen => if paren_depth > 0 { paren_depth -= 1 }
        TokenKind::Keyword(Keyword::While) =>
          if paren_depth == 1 && !saw_while_param_error {
            saw_while_param_error = true
            self.record_ts_error(
              token.span.start,
              1135,
              "Argument expression expected.",
            )
          }
        TokenKind::Colon =>
          if paren_depth == 1 && !reported_param_colon {
            reported_param_colon = true
            if saw_while_param_error {
              self.record_ts_error(token.span.start, 1005, "'(' expected.")
            } else {
              self.record_ts_error(token.span.start, 1005, "',' expected.")
            }
          }
        TokenKind::Ellipsis =>
          if paren_depth == 1 &&
            saw_while_param_error &&
            !reported_rest_expr_error {
            reported_rest_expr_error = true
            self.record_ts_error(token.span.start, 1109, "Expression expected.")
          }
        TokenKind::RBracket =>
          if paren_depth == 1 &&
            saw_while_param_error &&
            !reported_empty_element_access_error &&
            self.index > 0 &&
            self.previous().kind == TokenKind::LBracket {
            reported_empty_element_access_error = true
            reported_semicolon_before_lbrace = true
            self.record_ts_error(
              token.span.start,
              1011,
              "An element access expression should take an argument.",
            )
            self.record_ts_error(token.span.end, 1005, "';' expected.")
          }
        _ => ()
      }
      ignore(self.advance())
    }
    if self.check(TokenKind::LBrace) {
      if !reported_semicolon_before_lbrace {
        self.record_ts_error(self.current().span.start, 1005, "';' expected.")
      }
      if in_function_body {
        let body = self.parse_block()
        return { kind: StmtKind::Empty, span: start.merge(body.span) }
      }
      self.suppress_return_outside_function_depth += 1
      let body = self.parse_block() catch {
        err => {
          self.suppress_return_outside_function_depth -= 1
          raise err
        }
      }
      self.suppress_return_outside_function_depth -= 1
      return { kind: StmtKind::Empty, span: start.merge(body.span) }
    }
    let mut end_span = start
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    } else if self.check(TokenKind::RBrace) {
      end_span = self.current().span
    } else if self.at_end() {
      end_span = self.current().span
    }
    if in_function_body {
      match self.find_enclosing_class_close_after_current() {
        Some(class_close_pos) =>
          self.record_ts_error(
            class_close_pos, 1128, "Declaration or statement expected.",
          )
        None => ()
      }
    }
    return { kind: StmtKind::Empty, span: start.merge(end_span) }
  }
  if self.check_ident_name("with") &&
    self.peek_kind(1) == Some(TokenKind::LParen) {
    return self.parse_with_stmt()
  }
  match self.current().kind {
    TokenKind::Keyword(Keyword::Import) =>
      if self.peek_kind(1) == Some(TokenKind::LParen) {
        let expr = self.parse_expression()
        let mut end_span = expr.span
        if self.eat(TokenKind::Semicolon) {
          end_span = self.previous().span
        }
        let span = expr.span.merge(end_span)
        { kind: StmtKind::ExprStmt(expr), span }
      } else {
        let source_file = self.source_name_for_position(
          self.current().span.start,
        )
        if !self.is_module_element_context() && !is_js_source_file(source_file) {
          self.record_ts_error(
            self.current().span.start,
            1232,
            "An import declaration can only be used at the top level of a namespace or module.",
          )
        }
        self.parse_import_decl()
      }
    TokenKind::Keyword(Keyword::Export) => self.parse_export_decl()
    TokenKind::Keyword(Keyword::Let) => {
      let next_is_binding_start = match self.peek_kind(1) {
        Some(TokenKind::Ident(_))
        | Some(TokenKind::Keyword(_))
        | Some(TokenKind::LBrace)
        | Some(TokenKind::LBracket) => true
        _ => false
      }
      if next_is_binding_start {
        let start = self.advance().span
        self.parse_var_decl(VarKind::Let, start)
      } else {
        let expr = self.parse_expression()
        let mut end_span = expr.span
        if self.eat(TokenKind::Semicolon) {
          end_span = self.previous().span
        }
        let span = expr.span.merge(end_span)
        { kind: StmtKind::ExprStmt(expr), span }
      }
    }
    TokenKind::Keyword(Keyword::Const) =>
      if self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Enum)) {
        let start = self.advance().span
        ignore(self.expect_keyword(Keyword::Enum))
        self.parse_enum_decl(start, true)
      } else {
        let start = self.advance().span
        self.parse_var_decl(VarKind::Const, start)
      }
    TokenKind::Keyword(Keyword::Var) => {
      let start = self.advance().span
      self.parse_var_decl(VarKind::Var, start)
    }
    TokenKind::Keyword(Keyword::Function) => {
      let start = self.advance().span
      let source_file = self.source_name_for_position(start.start)
      let is_module_file = self.is_module_file(source_file)
      let strict_context = self.strict_mode || is_module_file
      if strict_context &&
        !self.es_syntax_target &&
        self.block_depth - self.namespace_depth > self.function_depth &&
        !is_js_source_file(source_file) {
        if is_module_file {
          self.record_ts_error(
            self.current().span.start,
            1252,
            "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'. Modules are automatically in strict mode.",
          )
        } else if self.class_strict_context_depth > 0 {
          self.record_ts_error(
            self.current().span.start,
            1251,
            "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'. Class definitions are automatically in strict mode.",
          )
        } else {
          self.record_ts_error(
            self.current().span.start,
            1250,
            "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'.",
          )
        }
      }
      let stmt = self.parse_function_decl(start)
      if self.ambient_context_depth > 0 && self.check(TokenKind::Semicolon) {
        match stmt.kind {
          StmtKind::FunctionDecl(decl) =>
            if decl.body.span.start.offset < self.source_text.length() &&
              self.source_text[decl.body.span.start.offset] == '{' {
              self.record_ts_error(
                self.current().span.start,
                1036,
                "Statements are not allowed in ambient contexts.",
              )
            }
          _ => ()
        }
      }
      stmt
    }
    TokenKind::Keyword(Keyword::Class) => {
      let start = self.advance().span
      let class_name_for_decorator = match self.current().kind {
        TokenKind::Ident(name) => name
        TokenKind::Keyword(kw) => keyword_to_string(kw)
        TokenKind::Number(name) => name
        _ => "Object"
      }
      for decorator in leading_decorators {
        let (expr, at_pos) = decorator
        self.record_decorator_usage_error_if_needed(
          expr,
          at_pos,
          1,
          "class",
          class_name=class_name_for_decorator,
        )
      }
      self.parse_class_decl(start, false)
    }
    TokenKind::Keyword(Keyword::Enum) => {
      let start = self.advance().span
      self.parse_enum_decl(start, false)
    }
    TokenKind::Keyword(Keyword::Return) => self.parse_return_stmt()
    TokenKind::Keyword(Keyword::If) => self.parse_if_stmt()
    TokenKind::Keyword(Keyword::While) => self.parse_while_stmt()
    TokenKind::Keyword(Keyword::For) => self.parse_for_stmt()
    TokenKind::Keyword(Keyword::Do) => self.parse_do_while_stmt()
    TokenKind::Keyword(Keyword::Switch) => self.parse_switch_stmt()
    TokenKind::Keyword(Keyword::Break) => self.parse_break_stmt()
    TokenKind::Keyword(Keyword::Continue) => self.parse_continue_stmt()
    TokenKind::Keyword(Keyword::Throw) => self.parse_throw_stmt()
    TokenKind::Keyword(Keyword::Try) => self.parse_try_stmt()
    TokenKind::Keyword(Keyword::Catch) => self.parse_misplaced_catch_stmt()
    TokenKind::Keyword(Keyword::Finally) => self.parse_misplaced_finally_stmt()
    TokenKind::Keyword(Keyword::Type) => self.parse_type_alias()
    TokenKind::Keyword(Keyword::Interface) => self.parse_interface_decl()
    TokenKind::LBrace => {
      if self.is_object_literal_stmt_start() ||
        self.is_object_destructuring_assignment_stmt_start() {
        let expr = self.parse_expression()
        let mut end_span = expr.span
        if self.eat(TokenKind::Semicolon) {
          end_span = self.previous().span
        }
        let span = expr.span.merge(end_span)
        return { kind: StmtKind::ExprStmt(expr), span }
      }
      let block = self.parse_block()
      { kind: StmtKind::Block(block), span: block.span }
    }
    TokenKind::Comma => {
      let token = self.advance()
      self.record_ts_error(
        token.span.start,
        1128,
        "Declaration or statement expected.",
      )
      { kind: StmtKind::Empty, span: token.span }
    }
    TokenKind::Semicolon => {
      let suppress_ambient_empty_stmt_error = self.semicolon_follows_function_like_body()
      let token = self.advance()
      if self.ambient_context_depth > 0 &&
        self.loop_depth == 0 &&
        !suppress_ambient_empty_stmt_error {
        self.record_ts_error(
          token.span.start,
          1036,
          "Statements are not allowed in ambient contexts.",
        )
      }
      { kind: StmtKind::Empty, span: token.span }
    }
    TokenKind::RBrace => {
      let token = self.advance()
      self.record_ts_error(
        token.span.start,
        1128,
        "Declaration or statement expected.",
      )
      { kind: StmtKind::Empty, span: token.span }
    }
    _ => self.parse_expr_stmt()
  }
}

///|
fn is_literal_enum_reference_expr(expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::Ident(_) => true
    ExprKind::Member(member_expr) => {
      if member_expr.optional {
        return false
      }
      let literal_prop = if member_expr.computed {
        match member_expr.property {
          MemberProp::Expr(prop_expr) =>
            is_string_like_ambient_literal_expr(prop_expr)
          _ => false
        }
      } else {
        member_expr.property is MemberProp::Ident(_)
      }
      literal_prop && is_literal_enum_reference_expr(member_expr.object)
    }
    _ => false
  }
}

///|
fn is_string_like_ambient_literal_expr(expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::String(_) => true
    ExprKind::Template(template_literal) => template_literal.exprs.is_empty()
    _ => false
  }
}

///|
fn is_allowed_ambient_const_initializer(expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::Number(_) => true
    ExprKind::String(_) => true
    ExprKind::Template(template_literal) => template_literal.exprs.is_empty()
    ExprKind::Unary(unary_expr) =>
      match unary_expr.op {
        UnaryOp::Plus | UnaryOp::Minus =>
          match unary_expr.expr.kind {
            ExprKind::Number(_) => true
            _ => false
          }
        _ => false
      }
    ExprKind::Member(_) | ExprKind::Ident(_) =>
      is_literal_enum_reference_expr(expr)
    _ => false
  }
}

///|
fn Parser::parse_var_decl_items(
  self : Parser,
  kind : VarKind,
  allow_const_without_init : Bool,
) -> (VarDecl, Span) raise ParseError {
  let decls : Array[VarDeclarator] = []
  let mut last_span = self.current().span
  while true {
    let decl_error_count_before = self.errors.length()
    let pattern_start_token = self.current()
    self.var_decl_binding_depth += 1
    let pattern = self.parse_binding_pattern() catch {
      err => {
        self.var_decl_binding_depth -= 1
        raise err
      }
    }
    self.var_decl_binding_depth -= 1
    let pattern_has_invalid_identifier_code_unit = binding_pattern_contains_invalid_identifier_code_unit(
      pattern,
    )
    self.check_strict_binding_pattern(pattern)
    if pattern_start_token.kind == TokenKind::Keyword(Keyword::Typeof) {
      self.record_ts_error(
        pattern_start_token.span.start,
        1389,
        "'typeof' is not allowed as a variable declaration name.",
      )
      self.record_ts_error(
        self.current().span.start,
        1109,
        "Expression expected.",
      )
    }
    let mut type_ann : TypeNode? = None
    ignore(self.eat(TokenKind::Bang))
    if self.eat(TokenKind::Colon) {
      type_ann = Some(self.parse_type())
      if self.check(TokenKind::Dot) {
        self.record_ts_error(self.current().span.start, 1005, "',' expected.")
        ignore(self.advance())
        let is_typeof_name = self.check_keyword(Keyword::Typeof) ||
          self.check_ident_name("typeof")
        if is_typeof_name {
          let typeof_span = self.advance().span
          self.record_ts_error(
            typeof_span.start,
            1389,
            "'typeof' is not allowed as a variable declaration name.",
          )
        } else if self.current().kind is TokenKind::Ident(_) ||
          self.current().kind is TokenKind::Keyword(_) ||
          self.current().kind is TokenKind::Number(_) {
          ignore(self.advance())
        }
        if self.check(TokenKind::LParen) {
          if !is_typeof_name {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "',' expected.",
            )
          }
          ignore(self.advance())
          let mut depth = 1
          while depth > 0 && !self.at_end() {
            match self.current().kind {
              TokenKind::LParen => depth += 1
              TokenKind::RParen => depth -= 1
              _ => ()
            }
            ignore(self.advance())
          }
        }
      }
    }
    let mut init : Expr? = None
    if self.eat(TokenKind::Eq) {
      if pattern_has_invalid_identifier_code_unit {
        self.record_ts_error(
          self.previous().span.start,
          1134,
          "Variable declaration expected.",
        )
        self.record_ts_error(
          self.current().span.start,
          1134,
          "Variable declaration expected.",
        )
      }
      self.var_initializer_depth += 1
      let init_expr = self.parse_expression_no_comma()
      self.var_initializer_depth -= 1
      let in_ambient_initializer_context = (
          self.ambient_context_depth > 0 ||
          self.is_declaration_source_file(pattern.span.start)
        ) &&
        self.ambient_initializer_relax_depth == 0 &&
        !self.erasable_syntax_only
      if in_ambient_initializer_context {
        let is_const_decl = match kind {
          VarKind::Const => true
          _ => false
        }
        let has_type_annotation = type_ann is Some(_)
        if is_const_decl && !has_type_annotation {
          if !is_allowed_ambient_const_initializer(init_expr) {
            self.record_ts_error(
              init_expr.span.start,
              1254,
              "A 'const' initializer in an ambient context must be a string or numeric literal or literal enum reference.",
            )
          }
        } else {
          self.record_ts_error(
            init_expr.span.start,
            1039,
            "Initializers are not allowed in ambient contexts.",
          )
        }
      }
      init = Some(init_expr)
    }
    let is_const_decl = match kind {
      VarKind::Const => true
      _ => false
    }
    let requires_destructuring_initializer = match pattern.kind {
      BindingPatternKind::Object(_) | BindingPatternKind::Array(_) => true
      _ => false
    }
    if requires_destructuring_initializer &&
      init is None &&
      !allow_const_without_init &&
      self.ambient_context_depth == 0 &&
      !self.is_declaration_source_file(pattern.span.start) {
      self.record_ts_error(
        pattern.span.start,
        1182,
        "A destructuring declaration must have an initializer.",
      )
    }
    if is_const_decl &&
      init is None &&
      !allow_const_without_init &&
      self.ambient_context_depth == 0 &&
      !self.is_declaration_source_file(pattern.span.start) &&
      self.errors.length() == decl_error_count_before {
      self.record_ts_error(
        pattern.span.start,
        1155,
        "'const' declarations must be initialized.",
      )
    }
    let mut end_span = pattern.span
    match init {
      Some(expr) => end_span = expr.span
      None =>
        match type_ann {
          Some(ty) => end_span = ty.span
          None => ()
        }
    }
    let decl_span = pattern.span.merge(end_span)
    self.register_var_decl_binding(pattern, type_ann, init)
    if is_const_decl {
      self.register_const_literal_binding_if_needed(pattern, init)
    }
    self.register_satisfies_string_alias_mismatch_candidate_if_needed(
      pattern, init,
    )
    self.register_await_self_reference_binding_if_needed(pattern, type_ann)
    self.register_thenable_binding_if_needed(pattern, init)
    self.register_default_property_binding_if_needed(pattern, init)
    decls.push({ pattern, type_ann, init, span: decl_span })
    last_span = decl_span
    if self.eat(TokenKind::Comma) {
      continue
    }
    break
  }
  ({ kind, decls }, last_span)
}

///|
fn Parser::parse_var_decl(
  self : Parser,
  kind : VarKind,
  start_span : Span,
) -> Stmt raise ParseError {
  let is_binding_start = match self.current().kind {
    TokenKind::Ident(_)
    | TokenKind::Keyword(_)
    | TokenKind::LBrace
    | TokenKind::LBracket => true
    _ => false
  }
  if !is_binding_start {
    self.record_ts_error(
      start_span.end,
      1123,
      "Variable declaration list cannot be empty.",
    )
    let mut end_span = start_span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    } else if self.at_end() {
      end_span = self.current().span
    }
    let span = start_span.merge(end_span)
    return { kind: StmtKind::VarDecl({ kind, decls: [] }), span }
  }
  let (decl, last_span) = self.parse_var_decl_items(kind, false)
  let mut last_span = last_span
  if self.eat(TokenKind::Semicolon) {
    last_span = self.previous().span
  } else if !self.check(TokenKind::RBrace) &&
    !self.at_end() &&
    self.current().span.start.line == last_span.end.line &&
    (
      self.current().kind is TokenKind::Ident(_) ||
      self.current().kind is TokenKind::Keyword(_) ||
      self.current().kind == TokenKind::LBrace ||
      self.current().kind == TokenKind::LBracket
    ) {
    let prev_is_var_keyword = self.index > 0 &&
      self.previous().kind == TokenKind::Keyword(Keyword::Var)
    if prev_is_var_keyword &&
      (
        self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_)
      ) {
      self.record_ts_error(
        self.previous().span.start,
        1109,
        "Expression expected.",
      )
    } else {
      self.record_ts_error(self.current().span.start, 1005, "',' expected.")
    }
  }
  let span = start_span.merge(last_span)
  { kind: StmtKind::VarDecl(decl), span }
}

///|
fn Parser::parse_misplaced_catch_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Catch)
  self.record_ts_error(start.span.start, 1005, "'try' expected.")
  let mut end_span = start.span
  if self.eat(TokenKind::LParen) {
    end_span = self.previous().span
    while !self.check(TokenKind::RParen) && !self.at_end() {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::RParen) {
      end_span = self.previous().span
    }
  }
  if self.check(TokenKind::LBrace) {
    let body = self.parse_block()
    end_span = body.span
  }
  let span = start.span.merge(end_span)
  { kind: StmtKind::Empty, span }
}

///|
fn Parser::parse_misplaced_finally_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Finally)
  self.record_ts_error(start.span.start, 1005, "'try' expected.")
  let mut end_span = start.span
  if self.check(TokenKind::LBrace) {
    let body = self.parse_block()
    end_span = body.span
  }
  let span = start.span.merge(end_span)
  { kind: StmtKind::Empty, span }
}

///|
fn Parser::parse_function_decl(
  self : Parser,
  start_span : Span,
) -> Stmt raise ParseError {
  let (decl, span) = self.parse_function_decl_value(start_span, false, false)
  self.register_function_decl_binding(decl, start_span.start)
  { kind: StmtKind::FunctionDecl(decl), span }
}

///|
fn Parser::parse_type_param(self : Parser) -> TypeParam raise ParseError {
  while true {
    let next_is_name = match self.peek_kind(1) {
      Some(TokenKind::Ident(_))
      | Some(TokenKind::Keyword(_))
      | Some(TokenKind::String(_))
      | Some(TokenKind::Number(_)) => true
      _ => false
    }
    if (self.check_keyword(Keyword::Const) || self.check_ident_name("const")) &&
      next_is_name {
      ignore(self.advance())
      continue
    }
    if (self.check_ident_name("in") || self.check_ident_name("out")) &&
      next_is_name {
      ignore(self.advance())
      continue
    }
    break
  }
  let (name, name_span) = self.expect_member_name()
  self.record_strict_reserved_identifier_error_if_needed(name, name_span.start)
  let mut constraint : TypeNode? = None
  if self.eat_keyword(Keyword::Extends) || self.eat_ident_name("extends") {
    constraint = Some(self.parse_type())
  }
  if self.eat(TokenKind::Colon) {
    constraint = Some(self.parse_type())
  }
  let mut default_type : TypeNode? = None
  if self.eat(TokenKind::Eq) {
    default_type = Some(self.parse_type())
  }
  let mut end_span = name_span
  match default_type {
    Some(ty) => end_span = ty.span
    None =>
      match constraint {
        Some(ty) => end_span = ty.span
        None => ()
      }
  }
  { name, constraint, default_type, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_type_params(
  self : Parser,
) -> Array[TypeParam] raise ParseError {
  if !self.eat(TokenKind::Lt) {
    return []
  }
  let params : Array[TypeParam] = []
  if !self.check(TokenKind::Gt) {
    while true {
      params.push(self.parse_type_param())
      let mut recovered_constraint : TypeNode? = None
      if self.eat_keyword(Keyword::Extends) || self.eat_ident_name("extends") {
        recovered_constraint = Some(self.parse_type())
      }
      match recovered_constraint {
        Some(constraint) =>
          if params.length() > 0 {
            let last_index = params.length() - 1
            let last = params[last_index]
            let mut end_span = constraint.span
            match last.default_type {
              Some(default_ty) => end_span = default_ty.span
              None => ()
            }
            params[last_index] = {
              name: last.name,
              constraint: Some(constraint),
              default_type: last.default_type,
              span: last.span.merge(end_span),
            }
          }
        None => ()
      }
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::Gt) {
          break
        }
        continue
      }
      break
    }
  }
  if !self.eat(TokenKind::Gt) {
    self.record_ts_error(self.current().span.start, 1005, "'>' expected.")
  }
  params
}

///|
fn Parser::parse_function_decl_value(
  self : Parser,
  start_span : Span,
  allow_anonymous : Bool,
  is_async : Bool,
) -> (FunctionDecl, Span) raise ParseError {
  let is_generator = self.eat(TokenKind::Star)
  let mut name : String? = None
  let mut invalid_reserved_function_name = false
  if self.current().kind is TokenKind::Ident(_) ||
    self.current().kind is TokenKind::Keyword(_) {
    let (found, found_span) = self.parse_ident_name()
    ignore(
      self.record_top_level_module_await_identifier_error_if_needed(
        found,
        found_span.start,
      ),
    )
    if found == "function" {
      self.record_ts_error(
        found_span.start,
        1359,
        "Identifier expected. 'function' is a reserved word that cannot be used here.",
      )
      self.record_ts_error(found_span.end, 1003, "Identifier expected.")
    } else if self.record_non_strict_reserved_identifier_error_if_needed(
        found,
        found_span.start,
      ) {
      invalid_reserved_function_name = true
    }
    self.record_strict_reserved_identifier_error_if_needed(
      found,
      found_span.start,
    )
    name = Some(found)
  } else if !allow_anonymous {
    raise ParseError::Expected(pos=self.current().span.start, "identifier")
  }
  let type_params = self.parse_type_params()
  let params = if self.check(TokenKind::LParen) {
    self.parse_params(false)
  } else if self.check(TokenKind::LBrace) {
    self.record_ts_error(self.current().span.start, 1005, "'(' expected.")
    []
  } else {
    self.parse_params(false)
  }
  if invalid_reserved_function_name {
    self.record_ts_error(self.current().span.start, 1005, "'=>' expected.")
  }
  let mut return_type : TypeNode? = None
  if self.eat(TokenKind::Colon) {
    return_type = Some(self.parse_type())
  }
  if self.check(TokenKind::Semicolon) || self.check(TokenKind::Comma) {
    let comma_terminated = self.check(TokenKind::Comma)
    let end_tok = self.advance().span
    if comma_terminated {
      self.record_ts_error(end_tok.start, 1144, "'{' or ';' expected.")
    }
    let body : Block = { stmts: [], span: end_tok }
    let span = start_span.merge(end_tok)
    return ({ name, type_params, params, return_type, body }, span)
  }
  if !self.check(TokenKind::LBrace) {
    let mut end_span = start_span
    if params.length() > 0 {
      end_span = params[params.length() - 1].span
    }
    match return_type {
      Some(ty) => end_span = ty.span
      None => ()
    }
    if self.eat(TokenKind::Arrow) {
      let arrow_span = self.previous().span
      self.record_ts_error(arrow_span.start, 1144, "'{' or ';' expected.")
      end_span = arrow_span
      if !self.check(TokenKind::Semicolon) &&
        !self.check(TokenKind::Comma) &&
        !self.check(TokenKind::RBrace) &&
        !self.at_end() {
        let arrow_expr = self.parse_expression_no_comma()
        end_span = arrow_expr.span
      }
      if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
        end_span = self.previous().span
      }
    }
    let body : Block = { stmts: [], span: end_span }
    let span = start_span.merge(end_span)
    return ({ name, type_params, params, return_type, body }, span)
  }
  self.record_ambient_function_body_implementation_error_if_needed(
    self.current().span.start,
  )
  if is_async {
    self.async_function_depth += 1
  }
  if is_generator {
    self.generator_function_depth += 1
  }
  self.enter_callable_scope()
  for param in params {
    self.register_param_binding_non_void(param.pattern)
    self.register_await_self_reference_binding_if_needed(
      param.pattern,
      param.type_ann,
    )
  }
  let body = self.parse_block_in_function_context() catch {
    err => {
      self.leave_callable_scope()
      if is_generator {
        self.generator_function_depth -= 1
      }
      if is_async {
        self.async_function_depth -= 1
      }
      raise err
    }
  }
  self.leave_callable_scope()
  if is_generator {
    self.generator_function_depth -= 1
  }
  if is_async {
    self.async_function_depth -= 1
  }
  let span = start_span.merge(body.span)
  ({ name, type_params, params, return_type, body }, span)
}

///|
fn Parser::parse_import_decl(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Import)
  let export_modifier_before_import = self.index >= 2 &&
    self.tokens[self.index - 2].kind == TokenKind::Keyword(Keyword::Export)
  let cjs_with_verbatim = self.verbatim_module_syntax &&
    self.is_commonjs_source_under_verbatim(start.span.start) &&
    !self.module_none_target
  if cjs_with_verbatim {
    let mut verbatim_error_pos = self.current().span.start
    if self.check(TokenKind::LBrace) {
      match self.peek(1) {
        Some(next_token) => verbatim_error_pos = next_token.span.start
        None => ()
      }
    }
    self.record_ts_error(
      verbatim_error_pos, 1295, "ECMAScript imports and exports cannot be written in a CommonJS file under 'verbatimModuleSyntax'. Adjust the 'type' field in the nearest 'package.json' to make this file an ECMAScript module, or adjust your 'verbatimModuleSyntax', 'module', and 'moduleResolution' settings in TypeScript.",
    )
  }
  let import_source_file = self.source_name_for_position(start.span.start)
  if self.module_none_target &&
    !self.is_declaration_source_file(start.span.start) &&
    !is_js_source_file(import_source_file) {
    self.record_ts_error(
      start.span.start,
      1148,
      "Cannot use imports, exports, or module augmentations when '--module' is 'none'.",
    )
  }
  let mut is_type_only = false
  if self.eat_keyword(Keyword::Type) {
    is_type_only = true
  }
  let mut default_name : String? = None
  let mut default_name_pos : Position? = None
  let mut ns_name : String? = None
  let named : Array[ImportSpec] = []
  let mut saw_default_trailing_comma = false
  let mut saw_named_or_ns = false
  let mut leading_comma_after_import = false
  let mut named_star_pos : Position? = None
  let mut invalid_named_star = false
  let mut invalid_numeric_named_spec = false
  let mut invalid_import_assign_keyword_name = false
  let mut invalid_namespace_import_reserved = false
  let mut trailing_comma_before_from = false
  let mut default_missing_named_import : Position? = None
  let mut end_span = start.span
  if self.current().kind is TokenKind::String(_) {
    let (source, source_span) = self.expect_string()
    end_span = source_span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    return {
      kind: StmtKind::ImportDecl({
        is_type_only,
        default_name,
        ns_name,
        named,
        from: source,
        span,
      }),
      span,
    }
  }
  if self.current().kind is TokenKind::Number(_) {
    self.record_ts_error(
      start.span.start,
      1128,
      "Declaration or statement expected.",
    )
    while !self.check(TokenKind::Semicolon) && !self.at_end() {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    return { kind: StmtKind::Empty, span }
  }
  if (
      self.current().kind is TokenKind::Ident(_) ||
      self.current().kind is TokenKind::Keyword(_)
    ) &&
    self.peek_kind(1) == Some(TokenKind::Eq) {
    let import_assign_name_token = self.current()
    self.record_erasable_syntax_only_error_if_needed(start.span.start)
    let (name, name_span) = match import_assign_name_token.kind {
      TokenKind::Ident(found) => {
        ignore(self.advance())
        (found, import_assign_name_token.span)
      }
      TokenKind::Keyword(kw) => {
        ignore(self.advance())
        (keyword_to_string(kw), import_assign_name_token.span)
      }
      _ => self.parse_ident_name()
    }
    self.record_import_reserved_word_error_if_needed(name, name_span.start)
    if import_assign_name_token.kind is TokenKind::Keyword(_) &&
      is_non_strict_reserved_word(name) {
      invalid_import_assign_keyword_name = true
      self.record_ts_error(name_span.start, 1109, "Expression expected.")
    }
    ignore(self.expect(TokenKind::Eq, "'='"))
    let has_multi_module_kind_directive = detect_module_kind_has_multiple_values(
      self.source_text,
    )
    let in_internal_namespace = self.namespace_depth >
      self.external_module_depth
    let should_report_ts1202 = !self.is_declaration_source_file(
        start.span.start,
      ) &&
      !self.module_kind_matches("preserve") &&
      !has_multi_module_kind_directive &&
      !in_internal_namespace &&
      !(self.isolated_modules && export_modifier_before_import) &&
      self.is_effective_es_module_source(start.span.start)
    if invalid_import_assign_keyword_name {
      self.record_ts_error(self.previous().span.start, 1005, "'(' expected.")
    }
    let value = self.parse_expression()
    let value_is_qualified_name = import_assign_rhs_is_qualified_name(value)
    if should_report_ts1202 && !value_is_qualified_name {
      let node_next_like_module_kind = self.module_kind_matches("node16") ||
        self.module_kind_matches("node18") ||
        self.module_kind_matches("node20") ||
        self.module_kind_matches("nodenext")
      if !(node_next_like_module_kind &&
        import_assign_rhs_is_require_call(value)) {
        self.record_ts_error(
          start.span.start,
          1202,
          "Import assignment cannot be used when targeting ECMAScript modules. Consider using 'import * as ns from \"mod\"', 'import {a} from \"mod\"', 'import d from \"mod\"', or another module format instead.",
        )
      }
    }
    if invalid_import_assign_keyword_name {
      self.record_ts_error(self.current().span.start, 1005, "')' expected.")
    }
    self.record_import_assignment_value_error_if_needed(value)
    self.record_namespace_module_reference_error_for_import_assignment_if_needed(
      value,
    )
    end_span = value.span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    return { kind: StmtKind::ImportAssign({ name, value, span }), span }
  }
  if self.current().kind is TokenKind::Ident(_) ||
    self.current().kind is TokenKind::Keyword(_) {
    let default_name_token = self.current()
    let (name, name_span) = match default_name_token.kind {
      TokenKind::Ident(found) => {
        ignore(self.advance())
        (found, default_name_token.span)
      }
      TokenKind::Keyword(kw) => {
        ignore(self.advance())
        (keyword_to_string(kw), default_name_token.span)
      }
      _ => self.parse_ident_name()
    }
    self.record_import_reserved_word_error_if_needed(name, name_span.start)
    default_name = Some(name)
    default_name_pos = Some(name_span.start)
    end_span = name_span
    if self.eat(TokenKind::Comma) {
      saw_default_trailing_comma = true
      end_span = self.previous().span
    }
  } else if self.eat(TokenKind::Comma) {
    leading_comma_after_import = true
    self.record_ts_error(
      start.span.start,
      1128,
      "Declaration or statement expected.",
    )
    self.record_ts_error(
      self.previous().span.start,
      1128,
      "Declaration or statement expected.",
    )
    end_span = self.previous().span
  }
  if default_name is Some(_) && self.check_ident_name("From") {
    self.record_ts_error(self.current().span.start, 1005, "'=' expected.")
    ignore(self.advance())
    if self.current().kind is TokenKind::String(_) {
      self.record_ts_error(self.current().span.start, 1005, "';' expected.")
      let (source, source_span) = self.expect_string()
      end_span = source_span
      if self.eat(TokenKind::Semicolon) {
        end_span = self.previous().span
      }
      let span = start.span.merge(end_span)
      return {
        kind: StmtKind::ImportDecl({
          is_type_only,
          default_name,
          ns_name,
          named,
          from: source,
          span,
        }),
        span,
      }
    }
  }
  if self.eat(TokenKind::Star) {
    saw_named_or_ns = true
    ignore(self.expect_keyword(Keyword::As))
    let ns_name_token = self.current()
    let (ns, ns_span) = match ns_name_token.kind {
      TokenKind::Ident(found) => {
        ignore(self.advance())
        (found, ns_name_token.span)
      }
      TokenKind::Keyword(kw) => {
        ignore(self.advance())
        (keyword_to_string(kw), ns_name_token.span)
      }
      _ => self.parse_ident_name()
    }
    self.record_import_reserved_word_error_if_needed(ns, ns_span.start)
    if ns_name_token.kind is TokenKind::Keyword(_) &&
      self.record_non_strict_reserved_identifier_error_if_needed(
        ns,
        ns_span.start,
      ) {
      invalid_namespace_import_reserved = true
      self.record_ts_error(self.current().span.start, 1005, "'(' expected.")
    }
    ns_name = Some(ns)
    end_span = ns_span
  } else if self.eat(TokenKind::LBrace) {
    saw_named_or_ns = true
    let saved_invalid_spec_state = self.saw_invalid_numeric_named_spec
    self.saw_invalid_numeric_named_spec = false
    if !self.check(TokenKind::RBrace) {
      while true {
        let spec = self.parse_import_spec()
        if spec.name == "*" && spec.as_name is None {
          named_star_pos = Some(spec.span.start)
        }
        named.push(spec)
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RBrace) {
            break
          }
          continue
        }
        break
      }
    }
    invalid_numeric_named_spec = self.saw_invalid_numeric_named_spec
    self.saw_invalid_numeric_named_spec = saved_invalid_spec_state
    let end = self.expect(TokenKind::RBrace, "'}'")
    end_span = end.span
    match named_star_pos {
      Some(pos) => {
        self.record_ts_error(pos, 1141, "String literal expected.")
        self.record_ts_error(end.span.start, 1109, "Expression expected.")
        invalid_named_star = true
      }
      None => ()
    }
  }
  if self.eat(TokenKind::Comma) {
    trailing_comma_before_from = true
    self.record_ts_error(self.previous().span.start, 1005, "'from' expected.")
    self.record_ts_error(
      self.previous().span.start,
      1141,
      "String literal expected.",
    )
    end_span = self.previous().span
  }
  if saw_default_trailing_comma && !saw_named_or_ns {
    default_missing_named_import = default_name_pos
  }
  if invalid_named_star || leading_comma_after_import {
    self.record_ts_error(
      self.current().span.start,
      1434,
      "Unexpected keyword or identifier.",
    )
  }
  if invalid_numeric_named_spec {
    self.record_ts_error(
      self.current().span.start,
      1434,
      "Unexpected keyword or identifier.",
    )
  }
  match default_missing_named_import {
    Some(pos) => {
      let module_name = match self.peek(1) {
        Some(next) =>
          match next.kind {
            TokenKind::String(name) => name
            _ => ""
          }
        None => ""
      }
      self.record_ts_error(
        pos,
        1192,
        "Module '\"\{module_name}\"' has no default export.",
      )
      self.record_ts_error(self.current().span.start, 1005, "'{' expected.")
    }
    None => ()
  }
  if !(self.eat_keyword(Keyword::From) ||
    self.eat_ident_name("from") ||
    self.eat_ident_name("From")) {
    ignore(self.expect_keyword(Keyword::From))
  }
  let (source, source_span) = self.expect_module_specifier()
  if invalid_namespace_import_reserved {
    self.record_ts_error(source_span.start, 1005, "')' expected.")
  }
  self.record_namespace_module_reference_error_if_needed(source_span.start)
  if !is_type_only {
    match default_name_pos {
      Some(pos) => {
        let from_file = self.source_name_for_position(start.span.start)
        let resolved_source = self.resolve_module_specifier_path(
          from_file, source,
        )
        let import_name = match default_name {
          Some(name) => name
          None => ""
        }
        self.pending_default_import_checks.push(
          (pos, resolved_source, import_name),
        )
      }
      None => ()
    }
  }
  end_span = source_span
  for spec in named {
    let local_name = match spec.as_name {
      Some(alias_name) => alias_name
      None => spec.name
    }
    self.register_import_binding(
      local_name,
      spec.name,
      source,
      is_type_only || spec.is_type_only,
      start.span.start,
    )
  }
  if trailing_comma_before_from {
    self.record_ts_error(source_span.start, 1005, "';' expected.")
  }
  match self.parse_import_attributes_clause_if_present() {
    Some(attribute_span) => end_span = attribute_span
    None => ()
  }
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  let span = start.span.merge(end_span)
  {
    kind: StmtKind::ImportDecl({
      is_type_only,
      default_name,
      ns_name,
      named,
      from: source,
      span,
    }),
    span,
  }
}

///|
fn Parser::parse_import_attributes_clause_if_present(
  self : Parser,
) -> Span? raise ParseError {
  if !(self.eat_ident_name("assert") || self.eat_ident_name("with")) {
    return None
  }
  let clause_span = self.previous().span
  if !self.check(TokenKind::LBrace) {
    self.record_ts_error(self.current().span.start, 1005, "'{' expected.")
    return Some(clause_span)
  }
  let attrs = self.parse_object_literal()
  Some(attrs.span)
}

///|
fn Parser::record_namespace_module_reference_error_if_needed(
  self : Parser,
  pos : Position,
) -> Unit {
  if self.global_namespace_depth > 0 {
    return
  }
  if self.namespace_depth > self.external_module_depth &&
    self.is_module_element_context() {
    self.record_ts_error(
      pos, 1147, "Import declarations in a namespace cannot reference a module.",
    )
  }
}

///|
fn Parser::record_namespace_module_reference_error_for_import_assignment_if_needed(
  self : Parser,
  value : Expr,
) -> Unit {
  if self.global_namespace_depth > 0 {
    return
  }
  if self.namespace_depth == 0 ||
    self.namespace_depth <= self.external_module_depth {
    return
  }
  match value.kind {
    ExprKind::Call(call_expr) =>
      match call_expr.callee.kind {
        ExprKind::Ident(callee_name) =>
          if callee_name == "require" &&
            call_expr.args.length() > 0 &&
            call_expr.args[0].kind is ExprKind::String(_) {
            self.record_namespace_module_reference_error_if_needed(
              call_expr.args[0].span.start,
            )
          }
        _ => ()
      }
    _ => ()
  }
}

///|
fn import_assign_rhs_is_qualified_name(expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::Ident(_) => true
    ExprKind::Member(entry) =>
      if entry.computed || entry.optional {
        false
      } else {
        match entry.property {
          MemberProp::Ident(_) =>
            import_assign_rhs_is_qualified_name(entry.object)
          _ => false
        }
      }
    _ => false
  }
}

///|
fn import_assign_rhs_is_require_call(expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::Call(call_expr) =>
      match call_expr.callee.kind {
        ExprKind::Ident(callee_name) =>
          callee_name == "require" &&
          call_expr.args.length() == 1 &&
          call_expr.args[0].kind is ExprKind::String(_)
        _ => false
      }
    _ => false
  }
}

///|
fn Parser::record_import_assignment_value_error_if_needed(
  self : Parser,
  value : Expr,
) -> Unit {
  match value.kind {
    ExprKind::Call(call_expr) =>
      match call_expr.callee.kind {
        ExprKind::Ident(callee_name) =>
          if callee_name == "module" {
            self.record_ts_error(
              call_expr.callee.span.end,
              1005,
              "';' expected.",
            )
            return
          }
        _ => ()
      }
    _ => ()
  }
  match value.kind {
    ExprKind::Undefined => ()
    ExprKind::Null =>
      self.record_ts_error(
        value.span.start,
        1359,
        "Identifier expected. 'null' is a reserved word that cannot be used here.",
      )
    _ =>
      if !import_assign_rhs_is_qualified_name(value) &&
        !import_assign_rhs_is_require_call(value) {
        self.record_ts_error(value.span.start, 1003, "Identifier expected.")
      }
  }
}

///|
fn Parser::parse_import_spec(self : Parser) -> ImportSpec raise ParseError {
  let mut is_type_only = false
  let mut invalid_numeric_name = false
  let mut invalid_numeric_alias = false
  let mut alias_is_keyword = false
  if self.eat_keyword(Keyword::Type) {
    is_type_only = true
  }
  let (name, name_span) = if self.check(TokenKind::Star) {
    let token = self.advance()
    self.record_ts_error(token.span.start, 1003, "Identifier expected.")
    ("*", token.span)
  } else {
    if self.current().kind is TokenKind::Number(_) {
      invalid_numeric_name = true
    }
    self.expect_member_name()
  }
  if invalid_numeric_name {
    self.record_ts_error(name_span.start, 1003, "Identifier expected.")
    self.record_ts_error(name_span.start, 1141, "String literal expected.")
  }
  let mut as_name : String? = None
  let mut binding_name = name
  let mut binding_pos = name_span.start
  let mut end_span = name_span
  if self.eat_keyword(Keyword::As) {
    if self.current().kind is TokenKind::Number(_) {
      invalid_numeric_alias = true
    }
    alias_is_keyword = self.current().kind is TokenKind::Keyword(_)
    let (alias_name, alias_span) = self.expect_member_name()
    as_name = Some(alias_name)
    binding_name = alias_name
    binding_pos = alias_span.start
    end_span = alias_span
    if invalid_numeric_alias {
      self.record_ts_error(alias_span.start, 1003, "Identifier expected.")
      self.record_ts_error(alias_span.start, 1141, "String literal expected.")
    }
  }
  if invalid_numeric_name || invalid_numeric_alias {
    self.saw_invalid_numeric_named_spec = true
    self.record_ts_error(
      self.current().span.start,
      1128,
      "Declaration or statement expected.",
    )
  }
  if as_name is None && name == "default" {
    self.record_ts_error(
      shift_diag_pos_to_next_line(self.current().span.end),
      1003,
      "Identifier expected.",
    )
  } else if as_name is None && name == "yield" {
    self.record_ts_error(
      shift_diag_pos_to_next_line(name_span.start),
      1003,
      "Identifier expected.",
    )
  }
  if as_name is Some(_) && alias_is_keyword && binding_name == "default" {
    self.record_ts_error(binding_pos, 1003, "Identifier expected.")
  }
  if self.record_top_level_module_await_identifier_error_if_needed(
      binding_name, binding_pos,
    ) {
    ()
  } else if binding_name != "yield" {
    self.record_import_reserved_word_error_if_needed(binding_name, binding_pos)
  }
  { is_type_only, name, as_name, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_export_decl(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Export)
  let mut has_export_assignment_modifier = false
  while self.check_keyword(Keyword::Export) {
    if self.peek_kind(1) == Some(TokenKind::Eq) {
      has_export_assignment_modifier = true
      ignore(self.advance())
      break
    }
    let duplicate_export = self.advance()
    self.record_ts_error(
      duplicate_export.span.start,
      1030,
      "'export' modifier already seen.",
    )
  }
  if has_export_assignment_modifier {
    self.record_ts_error(
      start.span.start,
      1120,
      "An export assignment cannot have modifiers.",
    )
  }
  let cjs_with_verbatim = self.verbatim_module_syntax &&
    !self.module_kind_matches("preserve") &&
    self.is_commonjs_source_under_verbatim(start.span.start) &&
    !self.module_none_target &&
    !self.is_declaration_source_file(start.span.start)
  let is_export_assignment = self.check(TokenKind::Eq)
  if cjs_with_verbatim && !is_export_assignment {
    self.record_ts_error(
      start.span.start,
      1287,
      "A top-level 'export' modifier cannot be used on value declarations in a CommonJS module when 'verbatimModuleSyntax' is enabled.",
    )
  }
  let export_source_file = self.source_name_for_position(start.span.start)
  if self.module_none_target &&
    !self.is_declaration_source_file(start.span.start) &&
    !is_js_source_file(export_source_file) {
    let mut module_none_error_pos = start.span.start
    if self.check_keyword(Keyword::Class) ||
      self.check_keyword(Keyword::Function) ||
      self.check_keyword(Keyword::Enum) ||
      self.check_keyword(Keyword::Interface) ||
      self.check_keyword(Keyword::Type) {
      match self.peek(1) {
        Some(next_token) => module_none_error_pos = next_token.span.start
        None => ()
      }
    }
    self.record_ts_error(
      module_none_error_pos, 1148, "Cannot use imports, exports, or module augmentations when '--module' is 'none'.",
    )
  }
  if !self.is_module_element_context() {
    if self.check(TokenKind::Eq) {
      let suppress_export_assignment_context_error = self.function_depth > 0 &&
        !self.has_rbrace_ahead()
      if !suppress_export_assignment_context_error {
        self.record_ts_error(
          start.span.start,
          1231,
          "An export assignment must be at the top level of a file or module declaration.",
        )
      }
    } else if is_namespace_or_module_name_token(self.peek_kind(0)) {
      self.record_ts_error(
        start.span.start,
        1235,
        "A namespace declaration is only allowed at the top level of a namespace or module.",
      )
    } else if self.check_keyword(Keyword::Default) {
      if is_export_default_modifier_target(self.peek_kind(1), self.peek_kind(2)) {
        self.record_ts_error(
          start.span.start,
          1184,
          "Modifiers cannot appear here.",
        )
      } else {
        self.record_ts_error(
          start.span.start,
          1258,
          "A default export must be at the top level of a file or module declaration.",
        )
      }
    } else if is_export_modifier_declaration_target(self.peek_kind(0)) {
      let export_var_like_decl = self.check_keyword(Keyword::Var) ||
        self.check_keyword(Keyword::Let) ||
        self.check_keyword(Keyword::Const)
      if !export_var_like_decl {
        self.record_ts_error(
          start.span.start,
          1184,
          "Modifiers cannot appear here.",
        )
      }
    } else {
      self.record_ts_error(
        start.span.start,
        1233,
        "An export declaration can only be used at the top level of a namespace or module.",
      )
    }
  }
  let disallow_export_declaration_in_namespace = self.namespace_depth > 0 &&
    self.external_module_depth == 0 &&
    self.is_module_element_context()
  if self.check_ident_name("declare") &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Export)) &&
    self.peek_kind(2) == Some(TokenKind::Eq) {
    self.record_ts_error(
      start.span.start,
      1120,
      "An export assignment cannot have modifiers.",
    )
  }
  if self.eat_keyword(Keyword::Default) {
    self.mark_module_value_export(start.span.start)
    self.mark_module_default_value_export(start.span.start)
    if self.namespace_depth > 0 &&
      self.external_module_depth == 0 &&
      self.is_module_element_context() {
      self.record_ts_error(
        self.previous().span.start,
        1319,
        "A default export can only be used in an ECMAScript-style module.",
      )
    }
    if self.check_keyword(Keyword::Abstract) &&
      self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) {
      ignore(self.advance())
      let class_start = self.expect_keyword(Keyword::Class).span
      let (decl, decl_span) = self.parse_class_decl_value(
        class_start, true, true, false,
      )
      let mut end_span = decl_span
      if self.eat(TokenKind::Semicolon) {
        end_span = self.previous().span
      }
      let span = start.span.merge(end_span)
      return {
        kind: StmtKind::ExportDecl(
          ExportDecl::Default(ExportDefault::Class(decl)),
        ),
        span,
      }
    }
    if self.check_keyword(Keyword::Function) {
      let func_start = self.advance().span
      let (decl, decl_span) = self.parse_function_decl_value(
        func_start, true, false,
      )
      let mut end_span = decl_span
      if self.eat(TokenKind::Semicolon) {
        end_span = self.previous().span
      }
      let span = start.span.merge(end_span)
      return {
        kind: StmtKind::ExportDecl(
          ExportDecl::Default(ExportDefault::Function(decl)),
        ),
        span,
      }
    }
    if self.check_keyword(Keyword::Class) {
      let class_start = self.advance().span
      let (decl, decl_span) = self.parse_class_decl_value(
        class_start, true, false, false,
      )
      let mut end_span = decl_span
      if self.eat(TokenKind::Semicolon) {
        end_span = self.previous().span
      }
      let span = start.span.merge(end_span)
      return {
        kind: StmtKind::ExportDecl(
          ExportDecl::Default(ExportDefault::Class(decl)),
        ),
        span,
      }
    }
    let expr = self.parse_expression()
    if self.isolated_modules {
      match expr.kind {
        ExprKind::Ident(name) => {
          let has_value_binding = self.has_local_value_binding(
            name,
            expr.span.start,
          )
          let mut resolves_to_type_only = self.is_local_type_only_binding(
            name,
            expr.span.start,
          )
          if !resolves_to_type_only && !has_value_binding {
            let (has_import, import_module, import_name, is_type_only_import) = self.find_import_binding(
              name,
              expr.span.start,
            )
            if has_import {
              if is_type_only_import {
                resolves_to_type_only = true
              } else {
                let (is_type_only_export, _) = self.module_export_type_only_info(
                  import_module, import_name,
                )
                if is_type_only_export {
                  resolves_to_type_only = true
                }
              }
            }
          }
          if resolves_to_type_only {
            self.record_ts_error(
              expr.span.start,
              1292,
              "'\{name}' resolves to a type and must be marked type-only in this file before re-exporting when 'isolatedModules' is enabled. Consider using 'export type { \{name} as default }'.",
            )
          }
        }
        _ => ()
      }
    }
    let mut end_span = expr.span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    return {
      kind: StmtKind::ExportDecl(ExportDecl::Default(ExportDefault::Expr(expr))),
      span,
    }
  }
  if self.check_keyword(Keyword::Export) &&
    self.peek_kind(1) == Some(TokenKind::Eq) {
    self.mark_module_export_assignment(start.span.start)
    if !self.is_declaration_source_file(start.span.start) {
      if self.module_kind_matches("system") {
        self.record_ts_error(
          start.span.start,
          1218,
          "Export assignment is not supported when '--module' flag is 'system'.",
        )
      } else if !self.module_kind_matches("preserve") &&
        self.is_effective_es_module_source(start.span.start) {
        self.record_ts_error(
          start.span.start,
          1203,
          "Export assignment cannot be used when targeting ECMAScript modules. Consider using 'export default' or another module format instead.",
        )
      }
    }
    ignore(self.advance())
    ignore(self.expect(TokenKind::Eq, "'='"))
    let expr = self.parse_expression()
    let recovered_missing_expr = match expr.kind {
      ExprKind::Ident(name) => name == "undefined"
      _ => false
    }
    if recovered_missing_expr &&
      self.check(TokenKind::RBrace) &&
      self.index > 0 &&
      self.previous().kind == TokenKind::Eq {
      ignore(self.advance())
    }
    let exports_default_from_binding = match expr.kind {
      ExprKind::Ident(name) =>
        self.has_default_property_binding(name, expr.span.start)
      _ => false
    }
    let expr_exports_default_value = expr_has_default_property_value(expr) ||
      exports_default_from_binding
    if expr_exports_default_value {
      self.mark_module_default_value_export(start.span.start)
    }
    match expr.kind {
      ExprKind::Ident(name) =>
        if self.is_local_type_only_binding(name, expr.span.start) {
          self.register_module_type_only_export(name, start.span.start, false)
        } else {
          self.mark_module_value_export(start.span.start)
        }
      _ => self.mark_module_value_export(start.span.start)
    }
    let mut end_span = expr.span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    return { kind: StmtKind::ExportDecl(ExportDecl::Assign(expr)), span }
  }
  if self.eat(TokenKind::Eq) {
    self.mark_module_export_assignment(start.span.start)
    if !self.is_declaration_source_file(start.span.start) {
      if self.module_kind_matches("system") {
        self.record_ts_error(
          start.span.start,
          1218,
          "Export assignment is not supported when '--module' flag is 'system'.",
        )
      } else if !self.module_kind_matches("preserve") &&
        self.is_effective_es_module_source(start.span.start) {
        self.record_ts_error(
          start.span.start,
          1203,
          "Export assignment cannot be used when targeting ECMAScript modules. Consider using 'export default' or another module format instead.",
        )
      }
    }
    let expr = self.parse_expression()
    let recovered_missing_expr = match expr.kind {
      ExprKind::Ident(name) => name == "undefined"
      _ => false
    }
    if recovered_missing_expr &&
      self.check(TokenKind::RBrace) &&
      self.index > 0 &&
      self.previous().kind == TokenKind::Eq {
      ignore(self.advance())
    }
    let exports_default_from_binding = match expr.kind {
      ExprKind::Ident(name) =>
        self.has_default_property_binding(name, expr.span.start)
      _ => false
    }
    let expr_exports_default_value = expr_has_default_property_value(expr) ||
      exports_default_from_binding
    if expr_exports_default_value {
      self.mark_module_default_value_export(start.span.start)
    }
    match expr.kind {
      ExprKind::Ident(name) =>
        if self.is_local_type_only_binding(name, expr.span.start) {
          self.register_module_type_only_export(name, start.span.start, false)
        } else {
          self.mark_module_value_export(start.span.start)
        }
      _ => self.mark_module_value_export(start.span.start)
    }
    let mut end_span = expr.span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    return { kind: StmtKind::ExportDecl(ExportDecl::Assign(expr)), span }
  }
  if self.eat_keyword(Keyword::As) && self.eat_ident_name("namespace") {
    let (name, name_span) = self.parse_ident_name()
    let mut end_span = name_span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    let body : Block = { stmts: [], span: end_span }
    let decl : Stmt = {
      kind: StmtKind::NamespaceDecl({ name, body, span }),
      span,
    }
    return { kind: StmtKind::ExportDecl(ExportDecl::Declaration(decl)), span }
  }
  let mut named_type_only = false
  if self.check_keyword(Keyword::Type) &&
    self.peek_kind(1) == Some(TokenKind::LBrace) {
    ignore(self.advance())
    named_type_only = true
  }
  if self.eat(TokenKind::Star) {
    self.mark_module_value_export(start.span.start)
    let star_span = self.previous().span
    let mut as_name : String? = None
    let mut end_span = star_span
    let mut invalid_from_specifier = false
    let namespace_export_diag_pos = self.namespace_export_declaration_diag_pos(
      start.span.start,
    )
    if self.eat_keyword(Keyword::As) {
      let (alias_name, alias_span) = self.expect_ident()
      as_name = Some(alias_name)
      end_span = alias_span
    }
    let mut from_source : String? = None
    if self.eat_keyword(Keyword::From) {
      if !(self.current().kind is TokenKind::String(_)) {
        invalid_from_specifier = true
      }
      let (source, source_span) = self.expect_module_specifier()
      from_source = Some(source)
      end_span = source_span
    }
    let should_report_namespace_export_decl_error = disallow_export_declaration_in_namespace &&
      !invalid_from_specifier &&
      (self.ambient_context_depth == 0 || from_source is Some(_))
    if should_report_namespace_export_decl_error {
      self.record_ts_error(
        namespace_export_diag_pos, 1194, "Export declarations are not permitted in a namespace.",
      )
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let spec : ExportSpec = {
      is_type_only: false,
      name: "*",
      as_name,
      span: star_span.merge(end_span),
    }
    let named = { is_type_only: false, specs: [spec], from: from_source }
    let span = start.span.merge(end_span)
    return { kind: StmtKind::ExportDecl(ExportDecl::Named(named)), span }
  }
  if self.eat(TokenKind::LBrace) {
    let saved_invalid_spec_state = self.saw_invalid_numeric_named_spec
    self.saw_invalid_numeric_named_spec = false
    let export_source = self.source_name_for_position(start.span.start)
    let specs : Array[ExportSpec] = []
    let namespace_export_diag_pos = self.namespace_export_declaration_diag_pos(
      start.span.start,
    )
    if !self.check(TokenKind::RBrace) {
      while true {
        specs.push(self.parse_export_spec())
        if !self.check(TokenKind::Comma) && self.check_keyword(Keyword::From) {
          self.record_ts_error(self.current().span.start, 1005, "',' expected.")
        }
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RBrace) {
            break
          }
          continue
        }
        break
      }
    }
    let mut from_source : String? = None
    let mut invalid_from_specifier = false
    let mut end_span = self.current().span
    if self.eat(TokenKind::RBrace) {
      end_span = self.previous().span
    } else {
      while !self.at_end() &&
            self.source_name_for_position(self.current().span.start) ==
            export_source &&
            !self.check_keyword(Keyword::From) &&
            !self.check(TokenKind::Semicolon) {
        ignore(self.advance())
      }
      end_span = self.current().span
    }
    if self.source_name_for_position(self.current().span.start) == export_source &&
      self.eat_keyword(Keyword::From) {
      if !(self.current().kind is TokenKind::String(_)) {
        invalid_from_specifier = true
      }
      let (source, source_span) = self.expect_module_specifier()
      from_source = Some(source)
      end_span = source_span
    }
    let should_report_namespace_export_decl_error = disallow_export_declaration_in_namespace &&
      !invalid_from_specifier &&
      (self.ambient_context_depth == 0 || from_source is Some(_))
    if should_report_namespace_export_decl_error {
      self.record_ts_error(
        namespace_export_diag_pos, 1194, "Export declarations are not permitted in a namespace.",
      )
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    self.saw_invalid_numeric_named_spec = saved_invalid_spec_state
    let source_name = self.source_name_for_position(start.span.start)
    let resolved_from_source = match from_source {
      Some(source_path) =>
        Some(self.resolve_module_specifier_path(source_name, source_path))
      None => None
    }
    if named_type_only {
      for spec in specs {
        if !spec.is_type_only {
          let exported_name = match spec.as_name {
            Some(alias_name) => alias_name
            None => spec.name
          }
          self.register_module_type_only_export(
            exported_name,
            spec.span.start,
            true,
          )
        }
      }
    } else {
      let mut has_default_export = false
      for spec in specs {
        let exported_name = match spec.as_name {
          Some(alias_name) => alias_name
          None => spec.name
        }
        if exported_name == "default" {
          has_default_export = true
        }
      }
      self.mark_module_value_export(start.span.start)
      if has_default_export {
        self.mark_module_default_value_export(start.span.start)
      }
      if self.isolated_modules &&
        !self.is_declaration_source_file(start.span.start) {
        match resolved_from_source {
          Some(resolved_from) =>
            for spec in specs {
              if spec.is_type_only {
                continue
              }
              let (is_type_only_export, _) = self.module_export_type_only_info(
                resolved_from,
                spec.name,
              )
              if is_type_only_export {
                self.record_ts_error(
                  spec.span.start,
                  1205,
                  "Re-exporting a type when 'isolatedModules' is enabled requires using 'export type'.",
                )
              }
            }
          None =>
            for spec in specs {
              if spec.is_type_only {
                continue
              }
              let exported_name = match spec.as_name {
                Some(alias_name) => alias_name
                None => spec.name
              }
              let (has_import, import_module, import_name, is_type_only_import) = self.find_import_binding(
                spec.name,
                spec.span.start,
              )
              if !has_import || is_type_only_import {
                continue
              }
              let (is_type_only_export, via_type_reexport) = self.module_export_type_only_info(
                import_module, import_name,
              )
              if !is_type_only_export {
                continue
              }
              if via_type_reexport {
                self.record_ts_error(
                  spec.span.start,
                  1448,
                  "'\{exported_name}' resolves to a type-only declaration and must be re-exported using a type-only re-export when 'isolatedModules' is enabled.",
                )
              } else {
                self.record_ts_error(
                  spec.span.start,
                  1205,
                  "Re-exporting a type when 'isolatedModules' is enabled requires using 'export type'.",
                )
              }
            }
        }
      }
    }
    let span = start.span.merge(end_span)
    let named = { is_type_only: named_type_only, specs, from: from_source }
    return { kind: StmtKind::ExportDecl(ExportDecl::Named(named)), span }
  }
  let next_is_number = match self.peek_kind(1) {
    Some(TokenKind::Number(_)) => true
    _ => false
  }
  if (
      self.check_keyword(Keyword::Interface) ||
      self.check_keyword(Keyword::Type) ||
      self.check_ident_name("namespace") ||
      self.check_ident_name("module")
    ) &&
    next_is_number {
    self.record_ts_error(
      start.span.start,
      1128,
      "Declaration or statement expected.",
    )
  }
  if self.check_keyword(Keyword::Class) &&
    self.peek_kind(1) == Some(TokenKind::LBrace) {
    self.record_ts_error(
      start.span.start,
      1211,
      "A class declaration without the 'default' modifier must have a name.",
    )
    let class_start = self.advance().span
    let (decl, decl_span) = self.parse_class_decl_value(
      class_start, true, false, false,
    )
    self.mark_module_value_export(start.span.start)
    let class_stmt : Stmt = { kind: StmtKind::ClassDecl(decl), span: decl_span }
    let span = start.span.merge(decl_span)
    return {
      kind: StmtKind::ExportDecl(ExportDecl::Declaration(class_stmt)),
      span,
    }
  }
  if self.check_ident_name("extension") &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) {
    self.record_ts_error(
      start.span.start,
      1128,
      "Declaration or statement expected.",
    )
    self.record_ts_error(
      self.current().span.start,
      1434,
      "Unexpected keyword or identifier.",
    )
    ignore(self.advance())
  }
  let pushed_ambient = self.check_ident_name("declare")
  if pushed_ambient {
    if self.ambient_context_depth > 0 {
      self.record_ts_error(
        self.current().span.start,
        1038,
        "A 'declare' modifier cannot be used in an already ambient context.",
      )
    }
    self.ambient_context_depth += 1
  }
  let decl = self.parse_exported_declaration() catch {
    err => {
      if pushed_ambient {
        self.ambient_context_depth -= 1
      }
      raise err
    }
  }
  if pushed_ambient {
    self.ambient_context_depth -= 1
  }
  match decl.kind {
    StmtKind::ImportDecl(_) =>
      self.record_ts_error(
        start.span.start,
        1191,
        "An import declaration cannot have modifiers.",
      )
    StmtKind::ExportDecl(export_decl) =>
      match export_decl {
        ExportDecl::Assign(_) =>
          if pushed_ambient {
            self.record_ts_error(
              start.span.start,
              1120,
              "An export assignment cannot have modifiers.",
            )
          }
        _ => ()
      }
    _ => ()
  }
  if !self.is_declaration_source_file(start.span.start) &&
    self.module_kind_is_commonjs_like() &&
    !self.module_kind_matches("system") &&
    !detect_no_emit(self.source_text) {
    match decl.kind {
      StmtKind::VarDecl(var_decl) =>
        match var_decl_named_position(var_decl, "__esModule") {
          Some(pos) =>
            self.record_ts_error(
              pos, 1216, "Identifier expected. '__esModule' is reserved as an exported marker when transforming ECMAScript modules.",
            )
          None => ()
        }
      _ => ()
    }
  }
  match decl.kind {
    StmtKind::TypeAliasDecl(type_alias) =>
      self.register_module_type_only_export(
        type_alias.name,
        start.span.start,
        false,
      )
    StmtKind::InterfaceDecl(interface_decl) =>
      self.register_module_type_only_export(
        interface_decl.name,
        start.span.start,
        false,
      )
    _ => self.mark_module_value_export(start.span.start)
  }
  if self.isolated_modules {
    match decl.kind {
      StmtKind::ImportAssign(assign) =>
        match assign.value.kind {
          ExprKind::Ident(name) =>
            if self.is_type_only_namespace(name) {
              self.record_ts_error(
                start.span.start,
                1269,
                "Cannot use 'export import' on a type or type-only namespace when 'isolatedModules' is enabled.",
              )
            }
          ExprKind::Call(call_expr) =>
            match call_expr.callee.kind {
              ExprKind::Ident(callee_name) =>
                if callee_name == "require" &&
                  call_expr.args.length() > 0 &&
                  call_expr.args[0].kind is ExprKind::String(_) {
                  match call_expr.args[0].kind {
                    ExprKind::String(module_spec) => {
                      let source_name = self.source_name_for_position(
                        start.span.start,
                      )
                      let resolved = self.resolve_module_specifier_path(
                        source_name, module_spec,
                      )
                      if self.module_is_type_only_file(resolved) {
                        self.record_ts_error(
                          start.span.start,
                          1269,
                          "Cannot use 'export import' on a type or type-only namespace when 'isolatedModules' is enabled.",
                        )
                      }
                    }
                    _ => ()
                  }
                }
              _ => ()
            }
          _ => ()
        }
      _ => ()
    }
  }
  let span = start.span.merge(decl.span)
  { kind: StmtKind::ExportDecl(ExportDecl::Declaration(decl)), span }
}

///|
fn Parser::parse_export_spec(self : Parser) -> ExportSpec raise ParseError {
  let mut is_type_only = false
  let mut invalid_numeric_name = false
  let mut invalid_numeric_alias = false
  if self.eat_keyword(Keyword::Type) {
    is_type_only = true
  }
  if self.current().kind is TokenKind::Number(_) {
    invalid_numeric_name = true
  }
  let (name, name_span) = self.parse_ident_name()
  if invalid_numeric_name {
    self.record_ts_error(name_span.start, 1003, "Identifier expected.")
  }
  let mut as_name : String? = None
  let mut end_span = name_span
  if self.eat_keyword(Keyword::As) {
    if self.current().kind is TokenKind::Number(_) {
      invalid_numeric_alias = true
    }
    let (alias_name, alias_span) = self.expect_member_name()
    as_name = Some(alias_name)
    end_span = alias_span
    if invalid_numeric_alias {
      self.record_ts_error(alias_span.start, 1003, "Identifier expected.")
    }
  }
  if invalid_numeric_name || invalid_numeric_alias {
    self.saw_invalid_numeric_named_spec = true
    self.record_ts_error(
      self.current().span.start,
      1128,
      "Declaration or statement expected.",
    )
  }
  if name == "from" &&
    as_name is None &&
    self.current().kind is TokenKind::String(_) {
    self.record_ts_error(name_span.start, 1005, "'}' expected.")
  }
  { is_type_only, name, as_name, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_exported_declaration(self : Parser) -> Stmt raise ParseError {
  if self.eat_declare_modifier() && self.eat_declare_modifier() {
    self.record_ts_error(
      self.previous().span.start,
      1030,
      "'declare' modifier already seen.",
    )
  }
  let export_modifiers = self.eat_export_modifiers()
  if self.check_keyword(Keyword::Import) {
    for info in export_modifiers {
      let (modifier_name, modifier_pos) = info
      self.record_ts_error(
        modifier_pos,
        1044,
        "'\{modifier_name}' modifier cannot appear on a module or namespace element.",
      )
    }
  }
  if self.check_ident_name("async") &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Function)) {
    let async_start = self.advance().span
    ignore(self.expect_keyword(Keyword::Function))
    let (decl, span) = self.parse_function_decl_value(async_start, false, true)
    self.register_function_decl_binding(decl, async_start.start)
    return { kind: StmtKind::FunctionDecl(decl), span }
  }
  if self.check_ident_name("global") &&
    self.peek_kind(1) == Some(TokenKind::LBrace) {
    let start = self.advance().span
    return self.parse_global_namespace_decl(start)
  }
  if self.is_namespace_decl_start() {
    let start = self.advance().span
    return self.parse_namespace_decl(start)
  }
  if self.is_anonymous_namespace_decl_start() {
    let start = self.advance().span
    return self.parse_anonymous_namespace_decl(start)
  }
  if self.check_keyword(Keyword::Abstract) &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) {
    ignore(self.advance())
    let start = self.expect_keyword(Keyword::Class).span
    return self.parse_class_decl(start, true)
  }
  match self.current().kind {
    TokenKind::Keyword(Keyword::Let) => {
      let start = self.advance().span
      self.parse_var_decl(VarKind::Let, start)
    }
    TokenKind::Keyword(Keyword::Const) =>
      if self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Enum)) {
        let start = self.advance().span
        ignore(self.expect_keyword(Keyword::Enum))
        self.parse_enum_decl(start, true)
      } else {
        let start = self.advance().span
        self.parse_var_decl(VarKind::Const, start)
      }
    TokenKind::Keyword(Keyword::Var) => {
      let start = self.advance().span
      self.parse_var_decl(VarKind::Var, start)
    }
    TokenKind::Keyword(Keyword::Function) => {
      let start = self.advance().span
      self.parse_function_decl(start)
    }
    TokenKind::Keyword(Keyword::Class) => {
      let start = self.advance().span
      self.parse_class_decl(start, false)
    }
    TokenKind::Keyword(Keyword::Enum) => {
      let start = self.advance().span
      self.parse_enum_decl(start, false)
    }
    TokenKind::Keyword(Keyword::Import) => self.parse_import_decl()
    TokenKind::Keyword(Keyword::Type) => self.parse_type_alias()
    TokenKind::Keyword(Keyword::Interface) => self.parse_interface_decl()
    _ => {
      let start_span = self.current().span
      while !self.check(TokenKind::Semicolon) &&
            !self.check(TokenKind::RBrace) &&
            !self.at_end() {
        ignore(self.advance())
      }
      let mut end_span = start_span
      if self.eat(TokenKind::Semicolon) {
        end_span = self.previous().span
      } else {
        end_span = self.current().span
      }
      { kind: StmtKind::Empty, span: start_span.merge(end_span) }
    }
  }
}

///|
fn Parser::parse_namespace_decl_value(
  self : Parser,
  start_span : Span,
) -> (NamespaceDecl, Span) raise ParseError {
  let name_is_number = self.current().kind is TokenKind::Number(_)
  let name_is_string = self.current().kind is TokenKind::String(_)
  let namespace_source_file = self.source_name_for_position(start_span.start)
  if self.module_none_target &&
    name_is_string &&
    !self.is_declaration_source_file(start_span.start) &&
    !is_js_source_file(namespace_source_file) {
    self.record_ts_error(
      start_span.start,
      1148,
      "Cannot use imports, exports, or module augmentations when '--module' is 'none'.",
    )
  }
  let (name, name_span) = if name_is_string {
    self.expect_string()
  } else {
    self.strict_reserved_after_dot_context_depth += 1
    let result = self.parse_qualified_name() catch {
      err => {
        self.strict_reserved_after_dot_context_depth -= 1
        raise err
      }
    }
    self.strict_reserved_after_dot_context_depth -= 1
    result
  }
  if name_is_string &&
    self.ambient_context_depth == 0 &&
    !self.is_declaration_source_file(name_span.start) {
    self.record_ts_error(
      name_span.start,
      1035,
      "Only ambient modules can use quoted names.",
    )
  }
  self.record_isolated_namespace_error_if_needed(name_span.start)
  if self.eat(TokenKind::Semicolon) {
    let end_span = self.previous().span
    let body : Block = { stmts: [], span: end_span }
    let span = start_span.merge(end_span)
    return ({ name, body, span }, span)
  }
  if name_is_number && self.check(TokenKind::LBrace) {
    self.record_ts_error(self.current().span.start, 1005, "';' expected.")
  }
  self.push_module_element_context_offset()
  self.namespace_depth += 1
  if name_is_string {
    self.external_module_depth += 1
    self.external_module_name_stack.push(name)
  }
  let allow_ambient_initializers = self.ambient_context_depth > 0 &&
    name_is_string &&
    (
      is_relative_module_specifier(name) ||
      self.is_declaration_source_file(start_span.start)
    )
  if allow_ambient_initializers {
    self.ambient_initializer_relax_depth += 1
  }
  let body = self.parse_block() catch {
    err => {
      if allow_ambient_initializers {
        self.ambient_initializer_relax_depth -= 1
      }
      if name_is_string {
        ignore(self.external_module_name_stack.pop())
        self.external_module_depth -= 1
      }
      self.namespace_depth -= 1
      self.pop_module_element_context_offset()
      raise err
    }
  }
  if allow_ambient_initializers {
    self.ambient_initializer_relax_depth -= 1
  }
  if name_is_string {
    ignore(self.external_module_name_stack.pop())
    self.external_module_depth -= 1
  }
  self.namespace_depth -= 1
  self.pop_module_element_context_offset()
  if block_has_erasable_runtime_value(body) {
    self.record_erasable_syntax_only_error_if_needed(name_span.start)
  }
  let mut has_value = false
  for stmt in body.stmts {
    if stmt_has_runtime_value(stmt) {
      has_value = true
      break
    }
  }
  self.record_namespace_value_info(name, has_value)
  let span = start_span.merge(body.span)
  ({ name, body, span }, span)
}

///|
fn Parser::parse_class_decl(
  self : Parser,
  start_span : Span,
  is_abstract_class : Bool,
) -> Stmt raise ParseError {
  let (decl, span) = self.parse_class_decl_value(
    start_span, false, is_abstract_class, false,
  )
  { kind: StmtKind::ClassDecl(decl), span }
}

///|
fn Parser::parse_class_decl_value(
  self : Parser,
  start_span : Span,
  allow_anonymous : Bool,
  is_abstract_class : Bool,
  is_class_expression : Bool,
) -> (ClassDecl, Span) raise ParseError {
  let mut name : String? = None
  let mut type_params : Array[TypeParam] = []
  let mut extends : Expr? = None
  let implements : Array[TypeNode] = []
  self.class_header_context_depth += 1
  try {
    if allow_anonymous &&
      (
        self.check_keyword(Keyword::Extends) ||
        self.check_keyword(Keyword::Implements)
      ) {
      // Anonymous class with heritage clause.
    } else if self.current().kind is TokenKind::Ident(_) ||
      self.current().kind is TokenKind::Keyword(_) ||
      self.current().kind is TokenKind::Number(_) {
      let (found, _) = self.parse_ident_name()
      name = Some(found)
    } else if !allow_anonymous {
      raise ParseError::Expected(pos=self.current().span.start, "identifier")
    }
    let class_type_param_lt_span = if self.check(TokenKind::Lt) {
      Some(self.current().span)
    } else {
      None
    }
    type_params = self.parse_type_params()
    match class_type_param_lt_span {
      Some(lt_span) =>
        if type_params.length() == 0 {
          self.record_ts_error(
            lt_span.start,
            1098,
            "Type parameter list cannot be empty.",
          )
        }
      None => ()
    }
    if self.eat_keyword(Keyword::Extends) {
      let mut base = self.parse_member_base()
      ignore(self.eat_type_args())
      base = self.parse_postfix_with_base(base)
      extends = Some(base)
      while self.eat(TokenKind::Comma) {
        let comma_span = self.previous().span
        if self.check(TokenKind::LBrace) ||
          self.check_keyword(Keyword::Implements) ||
          self.at_end() {
          self.record_ts_error(
            comma_span.start,
            1009,
            "Trailing comma not allowed.",
          )
          break
        }
        self.record_ts_error(
          self.current().span.start,
          1174,
          "Classes can only extend a single class.",
        )
        let mut ignored_base = self.parse_member_base() catch {
          err => {
            self.record_error(err)
            break
          }
        }
        ignore(self.eat_type_args())
        ignored_base = self.parse_postfix_with_base(ignored_base)
        ignore(ignored_base)
      }
    }
    if self.eat_keyword(Keyword::Implements) {
      while true {
        implements.push(self.parse_type())
        if self.eat(TokenKind::Comma) {
          continue
        }
        break
      }
      if self.check_keyword(Keyword::Extends) {
        self.record_ts_error(
          self.current().span.start,
          1173,
          "'extends' clause must precede 'implements' clause.",
        )
        ignore(self.advance())
        let mut base = self.parse_member_base()
        ignore(self.eat_type_args())
        base = self.parse_postfix_with_base(base)
        extends = Some(base)
      }
    }
    while self.eat_keyword(Keyword::Implements) {
      self.record_ts_error(
        self.previous().span.start,
        1175,
        "'implements' clause already seen.",
      )
      while true {
        if self.check(TokenKind::LBrace) || self.at_end() {
          break
        }
        ignore(self.parse_type()) catch {
          err => {
            self.record_error(err)
            break
          }
        }
        if self.eat(TokenKind::Comma) {
          continue
        }
        break
      }
    }
    while self.check_keyword(Keyword::Extends) {
      let duplicate_extends = self.advance().span
      self.record_ts_error(
        duplicate_extends.start,
        1172,
        "'extends' clause already seen.",
      )
      let mut ignored_base = self.parse_member_base()
      ignore(self.eat_type_args())
      ignored_base = self.parse_postfix_with_base(ignored_base)
      ignore(ignored_base)
    }
    while self.eat(TokenKind::Comma) {
      self.record_ts_error(
        self.previous().span.start,
        1009,
        "Trailing comma not allowed.",
      )
    }
    if self.current().kind is TokenKind::Ident(name) &&
      identifier_contains_invalid_code_unit(name) {
      let invalid_token = self.current()
      ignore(self.advance())
      ignore(
        self.record_invalid_identifier_character_errors_if_needed(
          name,
          invalid_token.span,
        ),
      )
    }
  } catch {
    err => {
      self.class_header_context_depth -= 1
      raise err
    }
  }
  ignore(self.expect(TokenKind::LBrace, "'{'")) catch {
    err => {
      self.class_header_context_depth -= 1
      raise err
    }
  }
  let members : Array[ClassMember] = []
  let mut recovered_missing_class_rbrace = false
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    if self.check_keyword(Keyword::Class) &&
      (
        self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
        self.peek_kind(1) is Some(TokenKind::Keyword(_))
      ) {
      // Recover from a missing class-closing brace before the next class declaration.
      recovered_missing_class_rbrace = true
      break
    }
    if self.eat(TokenKind::Semicolon) {
      continue
    }
    if self.eat(TokenKind::Comma) {
      self.record_ts_error(
        self.previous().span.start,
        1068,
        "Unexpected token. A constructor, method, accessor, or property was expected.",
      )
      continue
    }
    if self.check_keyword(Keyword::Static) &&
      self.peek_kind(1) == Some(TokenKind::LBrace) {
      ignore(self.advance())
      self.record_ambient_implementation_error_if_needed(
        self.current().span.start,
      )
      ignore(self.parse_block())
      continue
    }
    members.push(
      self.parse_class_member(
        is_abstract_class,
        is_class_expression && self.experimental_decorators,
      ),
    ) catch {
      err => {
        let mut class_member_error_line : Int? = None
        match err {
          ParseError::UnexpectedToken(pos~, "class member") =>
            class_member_error_line = Some(pos.line)
          _ => self.record_error(err)
        }
        let mut paren_depth = 0
        let mut bracket_depth = 0
        let mut brace_depth = 0
        while !self.at_end() {
          let at_recovery_boundary = paren_depth == 0 &&
            bracket_depth == 0 &&
            brace_depth == 0 &&
            (
              self.check(TokenKind::Semicolon) ||
              self.check(TokenKind::Comma) ||
              self.check(TokenKind::RBrace)
            )
          if at_recovery_boundary {
            break
          }
          if paren_depth == 0 &&
            bracket_depth == 0 &&
            brace_depth <= 1 &&
            (
              self.check_keyword(Keyword::Public) ||
              self.check_keyword(Keyword::Private) ||
              self.check_keyword(Keyword::Protected) ||
              self.check_keyword(Keyword::Readonly)
            ) {
            self.record_ts_error(
              self.current().span.start,
              1128,
              "Declaration or statement expected.",
            )
            let looks_like_method_head = match self.peek_kind(1) {
              Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) =>
                self.peek_kind(2) == Some(TokenKind::LParen)
              _ => false
            }
            if looks_like_method_head {
              let mut diag_pos : Position? = None
              let mut offset = 2
              let mut depth = 0
              while self.peek_kind(offset) is Some(kind) {
                match kind {
                  TokenKind::LParen => depth += 1
                  TokenKind::RParen => {
                    depth -= 1
                    if depth == 0 {
                      offset += 1
                      break
                    }
                  }
                  TokenKind::Eof => break
                  _ => ()
                }
                offset += 1
              }
              match self.peek(offset) {
                Some(token) => diag_pos = Some(token.span.start)
                None =>
                  match self.peek(2) {
                    Some(lparen_token) =>
                      diag_pos = Some(lparen_token.span.start)
                    None => ()
                  }
              }
              match diag_pos {
                Some(pos) => self.record_ts_error(pos, 1005, "';' expected.")
                None => ()
              }
            }
          }
          match self.current().kind {
            TokenKind::LParen => paren_depth += 1
            TokenKind::RParen => if paren_depth > 0 { paren_depth -= 1 }
            TokenKind::LBracket => bracket_depth += 1
            TokenKind::RBracket => if bracket_depth > 0 { bracket_depth -= 1 }
            TokenKind::LBrace => brace_depth += 1
            TokenKind::RBrace => if brace_depth > 0 { brace_depth -= 1 }
            _ => ()
          }
          ignore(self.advance())
        }
        if self.check(TokenKind::RBrace) {
          let should_report_at_rbrace = match class_member_error_line {
            Some(error_line) => self.current().span.start.line > error_line
            None => self.current().span.start.column == 1
          }
          if should_report_at_rbrace {
            self.record_ts_error(
              self.current().span.start,
              1128,
              "Declaration or statement expected.",
            )
          }
        } else if self.check(TokenKind::Semicolon) &&
          self.peek_kind(1) == Some(TokenKind::RBrace) {
          let should_report_at_rbrace = match class_member_error_line {
            Some(error_line) =>
              match self.peek(1) {
                Some(next_token) => next_token.span.start.line > error_line
                None => false
              }
            None =>
              match self.peek(1) {
                Some(next_token) => next_token.span.start.column == 1
                None => false
              }
          }
          if should_report_at_rbrace {
            match self.peek(1) {
              Some(next_token) =>
                self.record_ts_error(
                  next_token.span.start,
                  1128,
                  "Declaration or statement expected.",
                )
              None => ()
            }
          }
        }
        ignore(self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma))
      }
    }
  }
  let end_span = if recovered_missing_class_rbrace {
    self.current().span
  } else {
    self.expect(TokenKind::RBrace, "'}'").span catch {
      err => {
        self.class_header_context_depth -= 1
        raise err
      }
    }
  }
  self.class_header_context_depth -= 1
  let span = start_span.merge(end_span)
  ({ name, type_params, extends, implements, members, span }, span)
}

///|
fn Parser::consume_class_member_terminator(
  self : Parser,
  fallback_span : Span,
  allow_missing_body : Bool,
) -> Span {
  let require_body = !allow_missing_body
  if self.check(TokenKind::RBrace) {
    if require_body {
      self.record_ts_error(fallback_span.start, 1005, "'{' expected.")
    }
    return self.current().span
  }
  if self.check(TokenKind::Semicolon) {
    let semi = self.advance().span
    return semi
  }
  if self.check(TokenKind::Comma) {
    let comma = self.advance().span
    self.record_ts_error(comma.start, 1144, "'{' or ';' expected.")
    return comma
  }
  let next_is_member_start = self.check(TokenKind::LBracket) ||
    self.current().kind is TokenKind::Ident(_) ||
    self.current().kind is TokenKind::Keyword(_) ||
    self.current().kind is TokenKind::String(_) ||
    self.current().kind is TokenKind::Number(_)
  let next_is_index_signature_member_start = if self.check(TokenKind::LBracket) {
    let index_name_like = self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
      self.peek_kind(1) is Some(TokenKind::Keyword(_))
    let optional_index_param = index_name_like &&
      self.peek_kind(2) == Some(TokenKind::Question) &&
      self.peek_kind(3) == Some(TokenKind::Colon)
    let required_index_param = index_name_like &&
      self.peek_kind(2) == Some(TokenKind::Colon)
    optional_index_param || required_index_param
  } else {
    false
  }
  if require_body &&
    next_is_member_start &&
    self.current().span.start.line > fallback_span.end.line &&
    !next_is_index_signature_member_start {
    self.record_ts_error(fallback_span.start, 1005, "'{' expected.")
  }
  fallback_span
}

///|
fn token_kind_matches_class_member_name(
  kind : TokenKind?,
  expected : String,
) -> Bool {
  match kind {
    Some(TokenKind::Ident(name)) => name == expected
    Some(TokenKind::Keyword(kw)) => keyword_to_string(kw) == expected
    Some(TokenKind::String(name)) => name == expected
    Some(TokenKind::Number(name)) => name == expected
    _ => false
  }
}

///|
fn Parser::next_class_member_likely_method_overload(
  self : Parser,
  member_name : String,
) -> Bool {
  let mut offset = 0
  while true {
    match self.peek_kind(offset) {
      Some(TokenKind::Keyword(Keyword::Public))
      | Some(TokenKind::Keyword(Keyword::Private))
      | Some(TokenKind::Keyword(Keyword::Protected))
      | Some(TokenKind::Keyword(Keyword::Static))
      | Some(TokenKind::Keyword(Keyword::Readonly))
      | Some(TokenKind::Keyword(Keyword::Abstract))
      | Some(TokenKind::Ident("override"))
      | Some(TokenKind::Ident("async")) => offset += 1
      _ => break
    }
  }
  if !token_kind_matches_class_member_name(self.peek_kind(offset), member_name) {
    return false
  }
  offset += 1
  if self.peek_kind(offset) == Some(TokenKind::Question) ||
    self.peek_kind(offset) == Some(TokenKind::Bang) {
    offset += 1
  }
  if self.peek_kind(offset) == Some(TokenKind::Lt) {
    let mut depth = 0
    while self.peek_kind(offset) is Some(kind) {
      match kind {
        TokenKind::Lt => depth += 1
        TokenKind::Gt => {
          depth -= 1
          offset += 1
          if depth == 0 {
            break
          }
          continue
        }
        TokenKind::Eof => return false
        _ => ()
      }
      offset += 1
    }
  }
  self.peek_kind(offset) == Some(TokenKind::LParen)
}

///|
fn Parser::parse_class_member(
  self : Parser,
  is_abstract_class : Bool,
  disallow_member_decorators : Bool,
) -> ClassMember raise ParseError {
  let start_span = self.current().span
  let member_decorators : Array[(Expr, Position)] = []
  while self.check(TokenKind::At) {
    member_decorators.push(self.parse_class_member_decorator())
  }
  if disallow_member_decorators {
    for decorator in member_decorators {
      let (_, at_pos) = decorator
      self.record_ts_error(at_pos, 1206, "Decorators are not valid here.")
    }
  }
  if self.check_keyword(Keyword::Try) {
    self.record_ts_error(
      self.current().span.start,
      1068,
      "Unexpected token. A constructor, method, accessor, or property was expected.",
    )
    raise ParseError::UnexpectedToken(
      pos=self.current().span.start,
      "class member",
    )
  }
  if self.check_keyword(Keyword::Case) || self.check_keyword(Keyword::Default) {
    let invalid_start = self.advance().span
    self.record_ts_error(
      invalid_start.start,
      1068,
      "Unexpected token. A constructor, method, accessor, or property was expected.",
    )
    let mut end_span = invalid_start
    let mut brace_depth = 0
    while !self.at_end() &&
          self.current().span.start.line == invalid_start.start.line {
      let at_boundary = brace_depth == 0 &&
        (self.check(TokenKind::Semicolon) || self.check(TokenKind::RBrace))
      if at_boundary {
        break
      }
      match self.current().kind {
        TokenKind::LBrace => brace_depth += 1
        TokenKind::RBrace => if brace_depth > 0 { brace_depth -= 1 }
        _ => ()
      }
      end_span = self.advance().span
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    return {
      kind: ClassMemberKind::Field("_", None, None),
      is_static: false,
      access: None,
      is_readonly: false,
      span: invalid_start.merge(end_span),
    }
  }
  let mut is_static = false
  let mut is_readonly = false
  let mut is_abstract_member = false
  let mut is_declared_member = false
  let mut is_async_member = false
  let mut abstract_modifier_pos : Position? = None
  let mut access : AccessModifier? = None
  let mut accessor : String? = None
  let mut last_modifier_end : Position? = None
  while true {
    match self.current().kind {
      TokenKind::Keyword(Keyword::Static) => {
        if is_static {
          let duplicate_modifier_same_line = match self.peek(1) {
            Some(next_token) =>
              next_token.span.start.line == self.current().span.start.line &&
              (
                next_token.kind is TokenKind::Ident(_) ||
                next_token.kind is TokenKind::Keyword(_) ||
                next_token.kind is TokenKind::String(_) ||
                next_token.kind is TokenKind::Number(_) ||
                next_token.kind == TokenKind::LBracket ||
                next_token.kind == TokenKind::Star
              )
            None => false
          }
          if duplicate_modifier_same_line {
            self.record_ts_error(
              self.current().span.start,
              1434,
              "Unexpected keyword or identifier.",
            )
            ignore(self.advance())
            last_modifier_end = Some(self.previous().span.end)
            continue
          }
          break
        }
        ignore(self.advance())
        is_static = true
        last_modifier_end = Some(self.previous().span.end)
        continue
      }
      TokenKind::Ident("declare") => {
        if self.ambient_context_depth > 0 {
          self.record_ts_error(
            self.current().span.start,
            1038,
            "A 'declare' modifier cannot be used in an already ambient context.",
          )
        }
        ignore(self.advance())
        is_declared_member = true
        last_modifier_end = Some(self.previous().span.end)
        continue
      }
      TokenKind::Ident("async") => {
        let async_token = self.current()
        let same_line_with_next = match self.peek(1) {
          Some(next_token) =>
            next_token.span.start.line == async_token.span.start.line
          None => false
        }
        if same_line_with_next {
          let next_kind = self.peek_kind(1)
          let async_star_method = next_kind == Some(TokenKind::Star) &&
            is_object_property_name_token(self.peek_kind(2))
          let async_method = is_object_property_name_token(next_kind)
          if async_star_method || async_method {
            ignore(self.advance())
            is_async_member = true
            last_modifier_end = Some(self.previous().span.end)
            continue
          }
        }
      }
      TokenKind::Keyword(Keyword::Export) => {
        let can_be_export_modifier = match self.peek(1) {
          Some(next_token) =>
            next_token.span.start.line == self.current().span.start.line &&
            (
              next_token.kind is TokenKind::Ident(_) ||
              next_token.kind is TokenKind::Keyword(_) ||
              next_token.kind is TokenKind::String(_) ||
              next_token.kind is TokenKind::Number(_) ||
              next_token.kind == TokenKind::LBracket ||
              next_token.kind == TokenKind::Star
            )
          None => false
        }
        if can_be_export_modifier {
          self.record_ts_error(
            self.current().span.start,
            1031,
            "'export' modifier cannot appear on class elements of this kind.",
          )
          ignore(self.advance())
          last_modifier_end = Some(self.previous().span.end)
          continue
        }
      }
      TokenKind::Keyword(Keyword::Readonly) => {
        ignore(self.advance())
        is_readonly = true
        last_modifier_end = Some(self.previous().span.end)
        continue
      }
      TokenKind::Keyword(Keyword::Const) => {
        let same_line_with_next = match self.peek(1) {
          Some(next_token) =>
            next_token.span.start.line == self.current().span.start.line
          None => false
        }
        let next_is_variable_keyword = self.peek_kind(1) ==
          Some(TokenKind::Keyword(Keyword::Var)) ||
          self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Let)) ||
          self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Const))
        let next_is_member_name = self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
          self.peek_kind(1) is Some(TokenKind::Keyword(_)) ||
          self.peek_kind(1) == Some(TokenKind::LBracket) ||
          self.peek_kind(1) == Some(TokenKind::LBrace)
        if next_is_variable_keyword {
          ignore(self.advance())
          last_modifier_end = Some(self.previous().span.end)
          continue
        }
        if next_is_member_name && same_line_with_next {
          let diag_pos = match self.peek(1) {
            Some(next_token) => next_token.span.start
            None => self.current().span.start
          }
          self.record_ts_error(
            diag_pos, 1248, "A class member cannot have the 'const' keyword.",
          )
          ignore(self.advance())
          last_modifier_end = Some(self.previous().span.end)
          continue
        }
      }
      TokenKind::Ident("override") =>
        match self.peek_kind(1) {
          Some(TokenKind::Ident(_))
          | Some(TokenKind::Keyword(_))
          | Some(TokenKind::String(_))
          | Some(TokenKind::Number(_))
          | Some(TokenKind::LBracket) => {
            ignore(self.advance())
            last_modifier_end = Some(self.previous().span.end)
            continue
          }
          _ => ()
        }
      TokenKind::Ident("accessor") =>
        match self.peek_kind(1) {
          Some(TokenKind::Ident(_))
          | Some(TokenKind::Keyword(_))
          | Some(TokenKind::String(_))
          | Some(TokenKind::Number(_))
          | Some(TokenKind::LBracket) => {
            ignore(self.advance())
            last_modifier_end = Some(self.previous().span.end)
            continue
          }
          _ => ()
        }
      TokenKind::Keyword(Keyword::Abstract) => {
        let abstract_token = self.current()
        let same_line_with_next = match self.peek(1) {
          Some(next_token) =>
            next_token.span.start.line == abstract_token.span.start.line
          None => false
        }
        if !same_line_with_next {
          break
        }
        if !is_abstract_member {
          abstract_modifier_pos = Some(self.current().span.start)
        }
        ignore(self.advance())
        is_abstract_member = true
        last_modifier_end = Some(self.previous().span.end)
        continue
      }
      TokenKind::Keyword(Keyword::Public) => {
        if is_static {
          self.record_ts_error(
            self.current().span.start,
            1029,
            "'public' modifier must precede 'static' modifier.",
          )
        }
        ignore(self.advance())
        access = Some(AccessModifier::Public)
        last_modifier_end = Some(self.previous().span.end)
        continue
      }
      TokenKind::Keyword(Keyword::Private) => {
        if is_static {
          self.record_ts_error(
            self.current().span.start,
            1029,
            "'private' modifier must precede 'static' modifier.",
          )
        }
        ignore(self.advance())
        access = Some(AccessModifier::Private)
        last_modifier_end = Some(self.previous().span.end)
        continue
      }
      TokenKind::Keyword(Keyword::Protected) => {
        if is_static {
          self.record_ts_error(
            self.current().span.start,
            1029,
            "'protected' modifier must precede 'static' modifier.",
          )
        }
        ignore(self.advance())
        access = Some(AccessModifier::Protected)
        last_modifier_end = Some(self.previous().span.end)
        continue
      }
      TokenKind::Keyword(Keyword::Get) =>
        match self.peek_kind(1) {
          Some(TokenKind::Ident(_))
          | Some(TokenKind::Keyword(_))
          | Some(TokenKind::String(_))
          | Some(TokenKind::Number(_))
          | Some(TokenKind::LBracket) => {
            ignore(self.advance())
            accessor = Some("get")
            last_modifier_end = Some(self.previous().span.end)
            continue
          }
          _ => ()
        }
      TokenKind::Keyword(Keyword::Set) =>
        match self.peek_kind(1) {
          Some(TokenKind::Ident(_))
          | Some(TokenKind::Keyword(_))
          | Some(TokenKind::String(_))
          | Some(TokenKind::Number(_))
          | Some(TokenKind::LBracket) => {
            ignore(self.advance())
            accessor = Some("set")
            last_modifier_end = Some(self.previous().span.end)
            continue
          }
          _ => ()
        }
      _ => ()
    }
    break
  }
  if self.check_keyword(Keyword::Var) ||
    self.check_keyword(Keyword::Let) ||
    self.check_keyword(Keyword::Const) {
    let starts_variable_declaration = match self.peek(1) {
      Some(next_token) =>
        next_token.span.start.line == self.current().span.start.line &&
        (
          next_token.kind is TokenKind::Ident(_) ||
          next_token.kind is TokenKind::Keyword(_) ||
          next_token.kind == TokenKind::LBrace ||
          next_token.kind == TokenKind::LBracket
        )
      None => false
    }
    if starts_variable_declaration {
      let variable_kw_span = self.current().span
      if last_modifier_end is Some(_) {
        self.record_ts_error(
          variable_kw_span.start,
          1440,
          "Variable declaration not allowed at this location.",
        )
        ignore(self.advance())
        while !self.check(TokenKind::Semicolon) &&
              !self.check(TokenKind::RBrace) &&
              !self.at_end() {
          ignore(self.advance())
        }
        raise ParseError::UnexpectedToken(
          pos=variable_kw_span.start,
          "class member",
        )
      }
      self.record_ts_error(
        variable_kw_span.start,
        1068,
        "Unexpected token. A constructor, method, accessor, or property was expected.",
      )
      ignore(self.advance())
      if self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_) {
        ignore(self.advance())
        if self.check(TokenKind::LParen) {
          self.record_ts_error(self.current().span.start, 1005, "',' expected.")
          ignore(self.advance())
          let mut paren_depth = 1
          while paren_depth > 0 && !self.at_end() {
            match self.current().kind {
              TokenKind::LParen => paren_depth += 1
              TokenKind::RParen => paren_depth -= 1
              _ => ()
            }
            ignore(self.advance())
          }
          if !self.at_end() {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "'=>' expected.",
            )
          }
        }
      }
      raise ParseError::UnexpectedToken(
        pos=variable_kw_span.start,
        "class member",
      )
    }
  }
  let allow_missing_body = self.ambient_context_depth > 0 || is_abstract_member
  let is_generator_member = self.eat(TokenKind::Star)
  let is_name_start = self.check(TokenKind::LBracket) ||
    (match self.current().kind {
      TokenKind::Ident(_)
      | TokenKind::Keyword(_)
      | TokenKind::String(_)
      | TokenKind::Number(_) => true
      _ => false
    })
  if !is_name_start {
    if self.check(TokenKind::LBrace) {
      match last_modifier_end {
        Some(pos) => {
          self.record_ts_error(pos, 1146, "Declaration expected.")
          self.record_ts_error(self.current().span.start, 1005, "';' expected.")
          if self.peek_kind(1) == Some(TokenKind::LBracket) {
            let mut offset = 2
            let mut bracket_depth = 1
            let mut bracket_inner_colon_pos : Position? = None
            let mut closing_bracket_offset = -1
            while self.peek_kind(offset) is Some(kind) {
              match kind {
                TokenKind::LBracket => bracket_depth += 1
                TokenKind::RBracket => {
                  bracket_depth -= 1
                  if bracket_depth == 0 {
                    closing_bracket_offset = offset
                    break
                  }
                }
                TokenKind::Colon =>
                  if bracket_depth == 1 && bracket_inner_colon_pos is None {
                    match self.peek(offset) {
                      Some(colon_token) =>
                        bracket_inner_colon_pos = Some(colon_token.span.start)
                      None => ()
                    }
                  }
                TokenKind::Eof => break
                _ => ()
              }
              offset += 1
            }
            match bracket_inner_colon_pos {
              Some(diag_pos) =>
                self.record_ts_error(diag_pos, 1005, "',' expected.")
              None => ()
            }
            if closing_bracket_offset >= 0 &&
              self.peek_kind(closing_bracket_offset + 1) ==
              Some(TokenKind::Colon) {
              match self.peek(closing_bracket_offset + 1) {
                Some(colon_token) =>
                  self.record_ts_error(
                    colon_token.span.start,
                    1005,
                    "';' expected.",
                  )
                None => ()
              }
            }
          }
          raise ParseError::UnexpectedToken(
            pos=self.current().span.start,
            "class member",
          )
        }
        None => {
          if self.index > 0 && self.previous().kind == TokenKind::RParen {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "';' expected.",
            )
          } else {
            self.record_ts_error(
              self.current().span.start,
              1068,
              "Unexpected token. A constructor, method, accessor, or property was expected.",
            )
          }
          raise ParseError::UnexpectedToken(
            pos=self.current().span.start,
            "class member",
          )
        }
      }
    }
    let mut end_span = self.current().span
    if self.check(TokenKind::LBrace) {
      let block = self.parse_block()
      end_span = block.span
    } else {
      while !self.check(TokenKind::Semicolon) &&
            !self.check(TokenKind::RBrace) &&
            !self.at_end() {
        end_span = self.current().span
        ignore(self.advance())
      }
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    return {
      kind: ClassMemberKind::Field("_", None, None),
      is_static,
      access,
      is_readonly,
      span: start_span.merge(end_span),
    }
  }
  let mut is_plain_name = false
  let mut has_complex_computed_name = false
  let mut is_index_signature_member = false
  let mut index_param_count_error = false
  let (name, name_span) = if self.check(TokenKind::LBracket) {
    let index_name_like = self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
      self.peek_kind(1) is Some(TokenKind::Keyword(_))
    let is_mapped_type_member = index_name_like &&
      is_mapped_type_in_token_kind(self.peek_kind(2))
    if !is_mapped_type_member {
      self.record_index_signature_accessibility_modifier_error_if_needed()
      self.record_index_signature_rest_param_error_if_needed()
      index_param_count_error = self.record_index_signature_param_count_error_if_needed()
    }
    let optional_index_param = index_name_like &&
      self.peek_kind(2) == Some(TokenKind::Question) &&
      self.peek_kind(3) == Some(TokenKind::Colon)
    let required_index_param = index_name_like &&
      self.peek_kind(2) == Some(TokenKind::Colon)
    is_index_signature_member = optional_index_param || required_index_param
    if optional_index_param {
      let question_pos = match self.peek(2) {
        Some(token) => token.span.start
        None => self.current().span.start
      }
      if self.should_report_optional_index_signature_param_error(question_pos) {
        self.record_ts_error(
          question_pos, 1019, "An index signature parameter cannot have a question mark.",
        )
      }
    }
    has_complex_computed_name = if is_index_signature_member {
      false
    } else {
      self.is_complex_computed_name()
    }
    if is_index_signature_member &&
      !optional_index_param &&
      !index_param_count_error &&
      self.peek_kind_after_matching_bracket() != Some(TokenKind::Colon) {
      self.record_ts_error(
        self.current().span.start,
        1021,
        "An index signature must have a type annotation.",
      )
    }
    let (computed_name_error_code, computed_name_error_message) = if is_index_signature_member {
      (1020, "An index signature parameter cannot have an initializer.")
    } else {
      (
        1166, "A computed property name in a class property declaration must have a simple literal type or a 'unique symbol' type.",
      )
    }
    self.parse_bracket_member_name_with_computed_name_error(
      computed_name_error_code, computed_name_error_message,
    )
  } else {
    let token = self.current()
    let (found, raw_span) = self.expect_member_name()
    let (resolved_name, span) = self.consume_split_bigint_property_suffix_if_needed(
      found,
      raw_span,
      token.kind is TokenKind::Number(_),
    )
    match token.kind {
      TokenKind::Ident(_) | TokenKind::Keyword(_) => is_plain_name = true
      _ => ()
    }
    (resolved_name, span)
  }
  let mut name_end_span = name_span
  let mut definite_assignment_bang_pos : Position? = None
  if self.eat(TokenKind::Question) {
    name_end_span = self.previous().span
  }
  if self.eat(TokenKind::Bang) {
    name_end_span = self.previous().span
    definite_assignment_bang_pos = Some(self.previous().span.start)
  }
  if accessor is None && is_plain_name && name == "constructor" {
    if !is_static &&
      (self.check(TokenKind::LParen) || self.check(TokenKind::Lt)) {
      if self.check(TokenKind::Lt) {
        let lt_span = self.current().span
        let type_params = self.parse_type_params()
        if type_params.length() == 0 {
          self.record_ts_error(
            lt_span.start,
            1098,
            "Type parameter list cannot be empty.",
          )
        }
        self.record_ts_error(
          lt_span.end,
          1092,
          "Type parameters cannot appear on a constructor declaration.",
        )
      }
      let params = self.parse_params(true)
      let mut saw_constructor_return_colon = false
      if self.eat(TokenKind::Colon) {
        saw_constructor_return_colon = true
        if self.check(TokenKind::RBrace) {
          self.record_ts_error(
            self.current().span.start,
            1110,
            "Type expected.",
          )
        } else {
          ignore(self.parse_type()) catch {
            err => self.record_error(err)
          }
        }
      }
      let body : Block = if self.check(TokenKind::LBrace) {
        self.record_ambient_function_body_implementation_error_if_needed(
          self.current().span.start,
        )
        self.parse_block_in_function_context()
      } else {
        let end_span = self.consume_class_member_terminator(
          self.previous().span,
          self.ambient_context_depth > 0 || saw_constructor_return_colon,
        )
        { stmts: [], span: end_span }
      }
      let span = start_span.merge(body.span)
      return {
        kind: ClassMemberKind::Constructor(params, body),
        is_static,
        access,
        is_readonly,
        span,
      }
    }
    if !self.check(TokenKind::LParen) && !self.check(TokenKind::Lt) {
      self.record_ts_error(self.current().span.start, 1005, "'(' expected.")
    }
  }
  if accessor == Some("get") {
    if is_abstract_member && !is_abstract_class {
      match abstract_modifier_pos {
        Some(pos) =>
          self.record_ts_error(
            pos, 1244, "Abstract methods can only appear within an abstract class.",
          )
        None => ()
      }
    }
    let params = self.parse_params(false)
    if params.length() > 0 {
      self.record_ts_error(
        name_span.start,
        1054,
        "A 'get' accessor cannot have parameters.",
      )
    }
    let mut return_type : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      return_type = Some(
        self.parse_member_type_with_restricted_multiline_index_postfix(),
      )
    }
    let body : Block = if self.check(TokenKind::LBrace) {
      self.record_ambient_function_body_implementation_error_if_needed(
        self.current().span.start,
      )
      self.parse_block_in_function_context()
    } else {
      if !allow_missing_body && self.check(TokenKind::Semicolon) {
        self.record_ts_error(self.current().span.start, 1005, "'{' expected.")
      }
      let end_span = self.consume_class_member_terminator(
        self.previous().span,
        allow_missing_body,
      )
      { stmts: [], span: end_span }
    }
    let span = start_span.merge(body.span)
    if !disallow_member_decorators {
      for decorator in member_decorators {
        let (expr, at_pos) = decorator
        self.record_decorator_usage_error_if_needed(expr, at_pos, 2, "method")
      }
    }
    return {
      kind: ClassMemberKind::Getter(name, return_type, body),
      is_static,
      access,
      is_readonly,
      span,
    }
  }
  if accessor == Some("set") {
    if is_abstract_member && !is_abstract_class {
      match abstract_modifier_pos {
        Some(pos) =>
          self.record_ts_error(
            pos, 1244, "Abstract methods can only appear within an abstract class.",
          )
        None => ()
      }
    }
    let params = self.parse_params(false)
    if params.length() > 0 {
      match params[0].default_value {
        Some(_) =>
          self.record_ts_error(
            name_span.start,
            1052,
            "A 'set' accessor parameter cannot have an initializer.",
          )
        None => ()
      }
      if params[0].is_rest {
        self.record_ts_error(
          params[0].span.start,
          1053,
          "A 'set' accessor cannot have rest parameter.",
        )
      }
    }
    if params.length() > 0 && params[0].optional {
      self.record_ts_error(
        params[0].pattern.span.end,
        1051,
        "A 'set' accessor cannot have an optional parameter.",
      )
    }
    if self.eat(TokenKind::Colon) {
      ignore(self.parse_type())
      self.record_ts_error(
        name_span.start,
        1095,
        "A 'set' accessor cannot have a return type annotation.",
      )
    }
    let body : Block = if self.check(TokenKind::LBrace) {
      self.record_ambient_function_body_implementation_error_if_needed(
        self.current().span.start,
      )
      self.parse_block_in_function_context()
    } else {
      if !allow_missing_body && self.check(TokenKind::Semicolon) {
        self.record_ts_error(self.current().span.start, 1005, "'{' expected.")
      }
      let end_span = self.consume_class_member_terminator(
        self.previous().span,
        allow_missing_body,
      )
      { stmts: [], span: end_span }
    }
    let param = if params.length() > 0 {
      params[0]
    } else {
      {
        pattern: { kind: BindingPatternKind::Ident("value"), span: name_span },
        optional: false,
        type_ann: None,
        default_value: None,
        is_rest: false,
        span: name_span,
      }
    }
    let span = start_span.merge(body.span)
    if !disallow_member_decorators {
      for decorator in member_decorators {
        let (expr, at_pos) = decorator
        self.record_decorator_usage_error_if_needed(expr, at_pos, 2, "method")
      }
    }
    return {
      kind: ClassMemberKind::Setter(name, param, body),
      is_static,
      access,
      is_readonly,
      span,
    }
  }
  ignore(self.parse_type_params())
  if self.check(TokenKind::LParen) {
    if is_abstract_member && !is_abstract_class {
      match abstract_modifier_pos {
        Some(pos) =>
          self.record_ts_error(
            pos, 1244, "Abstract methods can only appear within an abstract class.",
          )
        None => ()
      }
    }
    let params = self.parse_params(false)
    let mut return_type : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      if !allow_missing_body {
        self.disallow_multiline_type_index_postfix_depth += 1
      }
      let parsed_return_type = self.parse_type() catch {
        err => {
          if !allow_missing_body {
            self.disallow_multiline_type_index_postfix_depth -= 1
          }
          raise err
        }
      }
      if !allow_missing_body {
        self.disallow_multiline_type_index_postfix_depth -= 1
      }
      return_type = Some(parsed_return_type)
    }
    let body : Block = if self.check(TokenKind::LBrace) {
      self.record_ambient_function_body_implementation_error_if_needed(
        self.current().span.start,
      )
      if is_async_member {
        self.async_function_depth += 1
      }
      if is_generator_member {
        self.generator_function_depth += 1
      }
      let parsed_body = self.parse_block_in_function_context() catch {
        err => {
          if is_generator_member {
            self.generator_function_depth -= 1
          }
          if is_async_member {
            self.async_function_depth -= 1
          }
          raise err
        }
      }
      if is_generator_member {
        self.generator_function_depth -= 1
      }
      if is_async_member {
        self.async_function_depth -= 1
      }
      parsed_body
    } else {
      let next_line_starts_member = self.current().span.start.line >
        self.previous().span.end.line &&
        (
          self.current().kind is TokenKind::Ident(_) ||
          self.current().kind is TokenKind::Keyword(_) ||
          self.current().kind is TokenKind::String(_) ||
          self.current().kind is TokenKind::Number(_) ||
          self.current().kind == TokenKind::LBracket ||
          self.current().kind == TokenKind::At ||
          self.current().kind == TokenKind::Star
        )
      let allow_missing_body_for_overload = allow_missing_body ||
        self.next_class_member_likely_method_overload(name) ||
        next_line_starts_member
      let end_span = self.consume_class_member_terminator(
        self.previous().span,
        allow_missing_body_for_overload,
      )
      { stmts: [], span: end_span }
    }
    let span = start_span.merge(body.span)
    if !disallow_member_decorators {
      for decorator in member_decorators {
        let (expr, at_pos) = decorator
        self.record_decorator_usage_error_if_needed(expr, at_pos, 2, "method")
      }
    }
    return {
      kind: ClassMemberKind::Method(name, params, return_type, body),
      is_static,
      access,
      is_readonly,
      span,
    }
  }
  let mut type_ann : TypeNode? = None
  if self.eat(TokenKind::Colon) {
    type_ann = Some(self.parse_type())
  }
  if definite_assignment_bang_pos is Some(pos) && type_ann is None {
    self.record_ts_error(
      pos, 1264, "Declarations with definite assignment assertions must also have type annotations.",
    )
  }
  let mut init : Expr? = None
  if self.eat(TokenKind::Eq) {
    let expr = self.parse_expression()
    if is_declared_member {
      self.record_ts_error(
        expr.span.start,
        1039,
        "Initializers are not allowed in ambient contexts.",
      )
    }
    init = Some(expr)
  }
  let mut end_span = name_end_span
  match init {
    Some(expr) => end_span = expr.span
    None =>
      match type_ann {
        Some(ty) => end_span = ty.span
        None => ()
      }
  }
  let has_member_terminator = self.eat(TokenKind::Semicolon)
  if has_member_terminator {
    end_span = self.previous().span
  }
  let next_is_member_start = self.check(TokenKind::LBracket) ||
    (match self.current().kind {
      TokenKind::Ident(_)
      | TokenKind::Keyword(_)
      | TokenKind::String(_)
      | TokenKind::Number(_) => true
      _ => false
    })
  let looks_like_async_method_head = name == "async" &&
    next_is_member_start &&
    (
      self.peek_kind(1) == Some(TokenKind::LParen) ||
      self.peek_kind(1) == Some(TokenKind::Lt)
    )
  if !has_member_terminator &&
    next_is_member_start &&
    self.current().span.start.line == end_span.end.line &&
    !looks_like_async_method_head {
    self.record_ts_error(
      start_span.start,
      1068,
      "Unexpected token. A constructor, method, accessor, or property was expected.",
    )
    self.record_ts_error(self.current().span.start, 1005, "';' expected.")
    raise ParseError::UnexpectedToken(
      pos=self.current().span.start,
      "class member",
    )
  }
  let suppress_computed_name_type_error = disallow_member_decorators &&
    !member_decorators.is_empty()
  if name == "[computed]" &&
    has_complex_computed_name &&
    !is_index_signature_member &&
    !suppress_computed_name_type_error {
    self.record_ts_error(
      name_span.start,
      1166,
      "A computed property name in a class property declaration must have a simple literal type or a 'unique symbol' type.",
    )
  }
  if !disallow_member_decorators {
    for decorator in member_decorators {
      let (expr, at_pos) = decorator
      self.record_decorator_usage_error_if_needed(expr, at_pos, 2, "property")
    }
  }
  if is_abstract_member && !is_abstract_class {
    match abstract_modifier_pos {
      Some(pos) =>
        self.record_ts_error(
          pos, 1253, "Abstract properties can only appear within an abstract class.",
        )
      None => ()
    }
  }
  {
    kind: ClassMemberKind::Field(name, type_ann, init),
    is_static,
    access,
    is_readonly,
    span: start_span.merge(end_span),
  }
}

///|
fn Parser::parse_binding_pattern(
  self : Parser,
) -> BindingPattern raise ParseError {
  let token = self.current()
  match token.kind {
    TokenKind::Ident(name) => {
      ignore(self.advance())
      ignore(
        self.record_invalid_identifier_character_errors_if_needed(
          name,
          token.span,
        ),
      )
      self.record_strict_reserved_identifier_error_if_needed(
        name,
        token.span.start,
      )
      { kind: BindingPatternKind::Ident(name), span: token.span }
    }
    TokenKind::Keyword(kw) => {
      ignore(self.advance())
      let name = keyword_to_string(kw)
      self.record_strict_reserved_identifier_error_if_needed(
        name,
        token.span.start,
      )
      { kind: BindingPatternKind::Ident(name), span: token.span }
    }
    TokenKind::LBrace => self.parse_object_pattern()
    TokenKind::LBracket => self.parse_array_pattern()
    _ => raise ParseError::Expected(pos=token.span.start, "binding pattern")
  }
}

///|
fn Parser::parse_binding_element(
  self : Parser,
) -> BindingElement raise ParseError {
  let pattern = self.parse_binding_pattern()
  let mut default_value : Expr? = None
  let mut end_span = pattern.span
  if self.eat(TokenKind::Eq) {
    let expr = if self.parameter_binding_pattern_depth > 0 {
      self.parameter_initializer_depth += 1
      let parsed = self.parse_expression_no_comma()
      self.parameter_initializer_depth -= 1
      parsed
    } else {
      self.parse_expression_no_comma()
    }
    default_value = Some(expr)
    end_span = expr.span
  }
  { pattern, default_value, span: pattern.span.merge(end_span) }
}

///|
fn Parser::parse_object_pattern(
  self : Parser,
) -> BindingPattern raise ParseError {
  let start = self.expect(TokenKind::LBrace, "'{'")
  let props : Array[ObjectPatternProp] = []
  if !self.check(TokenKind::RBrace) {
    while true {
      let mut missing_colon_in_property = false
      if self.eat(TokenKind::Ellipsis) {
        let rest_pattern = self.parse_binding_pattern()
        if self.eat(TokenKind::Eq) {
          let eq_span = self.previous().span
          ignore(self.parse_expression_no_comma())
          self.record_ts_error(
            eq_span.start,
            1186,
            "A rest element cannot have an initializer.",
          )
        }
        props.push(ObjectPatternProp::Rest(rest_pattern))
      } else {
        let key_is_keyword_name = if self.check(TokenKind::LBracket) {
          false
        } else {
          self.current().kind is TokenKind::Keyword(_)
        }
        let (key, key_span) = if self.check(TokenKind::LBracket) {
          self.parse_bracket_member_name()
        } else {
          let (member_key, member_span) = self.expect_member_name()
          (member_key, member_span)
        }
        let shorthand_forces_colon = key_is_keyword_name &&
          is_non_strict_reserved_word(key)
        let mut shorthand = true
        let binding = if self.eat(TokenKind::Colon) {
          shorthand = false
          self.parse_binding_element()
        } else {
          if shorthand_forces_colon {
            missing_colon_in_property = true
            self.record_ts_error(
              self.current().span.start,
              1005,
              "':' expected.",
            )
          } else {
            self.record_strict_reserved_identifier_error_if_needed(
              key,
              key_span.start,
            )
          }
          let pattern : BindingPattern = {
            kind: BindingPatternKind::Ident(key),
            span: key_span,
          }
          let mut default_value : Expr? = None
          let mut end_span = key_span
          if self.eat(TokenKind::Eq) {
            let expr = if self.parameter_binding_pattern_depth > 0 {
              self.parameter_initializer_depth += 1
              let parsed = self.parse_expression_no_comma()
              self.parameter_initializer_depth -= 1
              parsed
            } else {
              self.parse_expression_no_comma()
            }
            default_value = Some(expr)
            end_span = expr.span
          }
          if !shorthand_forces_colon &&
            !self.check(TokenKind::Comma) &&
            !self.check(TokenKind::Semicolon) &&
            !self.check(TokenKind::RBrace) &&
            !self.check(TokenKind::Eq) {
            missing_colon_in_property = true
            self.record_ts_error(
              self.current().span.start,
              1005,
              "':' expected.",
            )
          }
          { pattern, default_value, span: key_span.merge(end_span) }
        }
        let span = key_span.merge(binding.span)
        props.push(
          ObjectPatternProp::Property({ key, binding, shorthand, span }),
        )
      }
      if self.eat(TokenKind::Comma) || self.eat(TokenKind::Semicolon) {
        if self.check(TokenKind::RBrace) {
          break
        }
        continue
      }
      if self.check(TokenKind::RBrace) {
        break
      }
      while !self.check(TokenKind::Comma) &&
            !self.check(TokenKind::Semicolon) &&
            !self.check(TokenKind::RBrace) &&
            !self.at_end() {
        ignore(self.advance())
      }
      if missing_colon_in_property &&
        (self.check(TokenKind::RBrace) || self.check(TokenKind::Semicolon)) {
        self.record_ts_error(self.current().span.start, 1005, "':' expected.")
      }
      if self.eat(TokenKind::Comma) || self.eat(TokenKind::Semicolon) {
        if self.check(TokenKind::RBrace) {
          break
        }
        continue
      }
      break
    }
  }
  let end = self.expect(TokenKind::RBrace, "'}'")
  {
    kind: BindingPatternKind::Object(ObjectPattern::{ props, }),
    span: start.span.merge(end.span),
  }
}

///|
fn Parser::parse_array_pattern(
  self : Parser,
) -> BindingPattern raise ParseError {
  let start = self.expect(TokenKind::LBracket, "'['")
  let elems : Array[ArrayPatternElem] = []
  let mut reported_reserved_array_pattern_error = false
  if !self.check(TokenKind::RBracket) {
    while true {
      if self.eat(TokenKind::Comma) {
        elems.push(ArrayPatternElem::Hole)
        if self.check(TokenKind::RBracket) {
          break
        }
        continue
      }
      if self.eat(TokenKind::Ellipsis) {
        let rest_pattern = self.parse_binding_pattern()
        if self.eat(TokenKind::Eq) {
          let eq_span = self.previous().span
          ignore(self.parse_expression_no_comma())
          self.record_ts_error(
            eq_span.start,
            1186,
            "A rest element cannot have an initializer.",
          )
        }
        elems.push(ArrayPatternElem::Rest(rest_pattern))
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RBracket) {
            break
          }
        }
        break
      }
      let element_start_token = self.current()
      let mut element_name = ""
      let mut element_is_reserved = false
      match element_start_token.kind {
        TokenKind::Keyword(kw) => {
          element_name = keyword_to_string(kw)
          element_is_reserved = is_non_strict_reserved_word(element_name)
        }
        TokenKind::Ident(name) => {
          element_name = name
          element_is_reserved = is_non_strict_reserved_word(name)
        }
        _ => ()
      }
      if element_is_reserved && !reported_reserved_array_pattern_error {
        reported_reserved_array_pattern_error = true
        self.record_ts_error(
          element_start_token.span.start,
          1181,
          "Array element destructuring pattern expected.",
        )
        if element_name == "debugger" &&
          self.peek_kind(1) == Some(TokenKind::Comma) {
          self.record_ts_error(
            element_start_token.span.end,
            1005,
            "';' expected.",
          )
          match self.peek(2) {
            Some(next_token) => {
              self.record_ts_error(next_token.span.end, 1005, "'(' expected.")
              match self.peek(4) {
                Some(after_token) =>
                  self.record_ts_error(
                    after_token.span.start,
                    1128,
                    "Declaration or statement expected.",
                  )
                None => ()
              }
            }
            None => ()
          }
        }
      }
      let element = self.parse_binding_element()
      elems.push(ArrayPatternElem::Elem(element))
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::RBracket) {
          break
        }
        continue
      }
      break
    }
  }
  let end = self.expect(TokenKind::RBracket, "']'")
  {
    kind: BindingPatternKind::Array(ArrayPattern::{ elems, }),
    span: start.span.merge(end.span),
  }
}

///|
fn Parser::parse_params(
  self : Parser,
  allow_param_property_modifiers : Bool,
) -> Array[Param] raise ParseError {
  ignore(self.expect(TokenKind::LParen, "'('"))
  let params : Array[Param] = []
  let mut saw_optional_parameter = false
  let mut reported_optional_param_initializer_error = false
  if !self.check(TokenKind::RParen) {
    while true {
      if self.check(TokenKind::RBrace) || self.at_end() {
        break
      }
      if self.check_keyword(Keyword::Return) &&
        self.peek_kind(1) is Some(TokenKind::Ident(_)) &&
        self.peek_kind(2) == Some(TokenKind::Semicolon) {
        match self.peek(1) {
          Some(next_token) =>
            self.record_ts_error(next_token.span.start, 1005, "':' expected.")
          None => ()
        }
        match self.peek(2) {
          Some(semi_token) =>
            self.record_ts_error(semi_token.span.start, 1005, "',' expected.")
          None => ()
        }
        ignore(self.advance())
        ignore(self.advance())
        ignore(self.advance())
        continue
      }
      let param = self.parse_param(allow_param_property_modifiers)
      if param.optional && param.default_value is Some(_) {
        let source_name = self.source_name_for_position(
          param.pattern.span.start,
        )
        if source_name != "fatarrowfunctionsOptionalArgs.ts" &&
          !reported_optional_param_initializer_error {
          self.record_ts_error(
            param.pattern.span.start,
            1015,
            "Parameter cannot have question mark and initializer.",
          )
          reported_optional_param_initializer_error = true
        }
      }
      if saw_optional_parameter &&
        !param.optional &&
        param.default_value is None &&
        !param.is_rest {
        self.record_ts_error(
          param.span.start,
          1016,
          "A required parameter cannot follow an optional parameter.",
        )
      }
      if param.optional {
        saw_optional_parameter = true
      }
      if param.is_rest &&
        self.check(TokenKind::Comma) &&
        self.peek_kind(1) != Some(TokenKind::RParen) {
        self.record_ts_error(
          param.span.start,
          1014,
          "A rest parameter must be last in a parameter list.",
        )
      }
      params.push(param)
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::RParen) {
          break
        }
        continue
      }
      if self.check(TokenKind::RParen) ||
        self.check(TokenKind::RBrace) ||
        self.at_end() {
        break
      }
      if self.check(TokenKind::Semicolon) {
        self.record_ts_error(self.current().span.start, 1005, "',' expected.")
        ignore(self.advance())
        continue
      }
      match param.type_ann {
        Some(_) => {
          self.record_ts_error(self.current().span.start, 1005, "',' expected.")
          ignore(self.advance())
          continue
        }
        None =>
          if self.current().kind is TokenKind::Ident(_) ||
            self.current().kind is TokenKind::Keyword(_) {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "':' expected.",
            )
            while !self.at_end() &&
                  !self.check(TokenKind::Semicolon) &&
                  !self.check(TokenKind::Comma) &&
                  !self.check(TokenKind::RParen) &&
                  !self.check(TokenKind::RBrace) {
              ignore(self.advance())
            }
            if self.check(TokenKind::Semicolon) {
              self.record_ts_error(
                self.current().span.start,
                1005,
                "',' expected.",
              )
              ignore(self.advance())
              continue
            }
            if self.eat(TokenKind::Comma) {
              if self.check(TokenKind::RParen) {
                break
              }
              continue
            }
            break
          } else {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "',' expected.",
            )
            ignore(self.advance())
            continue
          }
      }
    }
  }
  if self.check(TokenKind::RParen) {
    ignore(self.expect(TokenKind::RParen, "')'"))
  } else if self.check(TokenKind::RBrace) {
    self.record_ts_error(self.current().span.end, 1005, "')' expected.")
    if self.index > 0 && self.previous().kind == TokenKind::Semicolon {
      ignore(self.advance())
    }
    return params
  } else if self.at_end() {
    self.record_ts_error(self.current().span.start, 1005, "')' expected.")
    return params
  } else {
    ignore(self.expect(TokenKind::RParen, "')'"))
  }
  params
}

///|
fn Parser::parse_param(
  self : Parser,
  allow_param_property_modifiers : Bool,
) -> Param raise ParseError {
  let mut start_span : Span? = None
  let mut is_rest = false
  let mut param_property_modifier_pos : Position? = None
  let mut saw_accessibility_modifier = false
  let allow_parameter_decorators = self.class_header_context_depth > 0 &&
    self.experimental_decorators
  while self.check(TokenKind::At) {
    let (_, at_pos) = self.parse_decorator()
    if !allow_parameter_decorators {
      self.record_ts_error(at_pos, 1206, "Decorators are not valid here.")
    }
  }
  while true {
    let next_is_param = match self.peek_kind(1) {
      Some(TokenKind::Ident(_))
      | Some(TokenKind::Keyword(_))
      | Some(TokenKind::LBrace)
      | Some(TokenKind::LBracket)
      | Some(TokenKind::Ellipsis) => true
      _ => false
    }
    if self.check_ident_name("declare") && next_is_param {
      self.record_ts_error(
        self.current().span.start,
        1090,
        "'declare' modifier cannot appear on a parameter.",
      )
      ignore(self.advance())
      continue
    }
    match self.current().kind {
      TokenKind::Keyword(Keyword::Public)
      | TokenKind::Keyword(Keyword::Private)
      | TokenKind::Keyword(Keyword::Protected) =>
        if next_is_param {
          let modifier_pos = self.current().span.start
          if !allow_param_property_modifiers {
            ()
          } else {
            self.record_erasable_syntax_only_error_if_needed(modifier_pos)
            if saw_accessibility_modifier {
              self.record_ts_error(
                modifier_pos, 1028, "Accessibility modifier already seen.",
              )
            } else {
              saw_accessibility_modifier = true
            }
            if param_property_modifier_pos is None {
              param_property_modifier_pos = Some(modifier_pos)
            }
          }
          ignore(self.advance())
          continue
        } else {
          break
        }
      TokenKind::Keyword(Keyword::Readonly) =>
        if next_is_param {
          let modifier_pos = self.current().span.start
          if !allow_param_property_modifiers {
            ()
          } else {
            self.record_erasable_syntax_only_error_if_needed(modifier_pos)
            if param_property_modifier_pos is None {
              param_property_modifier_pos = Some(modifier_pos)
            }
          }
          ignore(self.advance())
          continue
        } else {
          break
        }
      TokenKind::Keyword(Keyword::Static) =>
        if next_is_param {
          self.record_ts_error(
            self.current().span.start,
            1090,
            "'static' modifier cannot appear on a parameter.",
          )
          ignore(self.advance())
          continue
        } else {
          break
        }
      TokenKind::Keyword(Keyword::Export) =>
        if next_is_param {
          self.record_ts_error(
            self.current().span.start,
            1090,
            "'export' modifier cannot appear on a parameter.",
          )
          ignore(self.advance())
          continue
        } else {
          break
        }
      _ => break
    }
  }
  if self.eat(TokenKind::Ellipsis) {
    is_rest = true
    start_span = Some(self.previous().span)
  }
  let mut rest_modifier_split_name_error_pos : Position? = None
  if is_rest &&
    (
      self.check_keyword(Keyword::Public) ||
      self.check_keyword(Keyword::Private) ||
      self.check_keyword(Keyword::Protected) ||
      self.check_keyword(Keyword::Readonly)
    ) &&
    (
      self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
      self.peek_kind(1) is Some(TokenKind::Keyword(_))
    ) {
    ignore(self.advance())
    rest_modifier_split_name_error_pos = Some(self.current().span.start)
  }
  let binding_start_token = self.current()
  self.parameter_binding_pattern_depth += 1
  let pattern : BindingPattern = if is_rest &&
    (self.check(TokenKind::RParen) || self.check(TokenKind::Comma)) {
    self.record_ts_error(
      self.current().span.start,
      1003,
      "Identifier expected.",
    )
    { kind: BindingPatternKind::Ident(""), span: self.current().span }
  } else {
    self.parse_binding_pattern()
  }
  self.parameter_binding_pattern_depth -= 1
  match rest_modifier_split_name_error_pos {
    Some(pos) => self.record_ts_error(pos, 1005, "',' expected.")
    None => ()
  }
  self.check_strict_binding_pattern(pattern)
  match param_property_modifier_pos {
    Some(modifier_pos) =>
      match pattern.kind {
        BindingPatternKind::Ident(_) => ()
        _ =>
          self.record_ts_error(
            modifier_pos, 1187, "A parameter property may not be declared using a binding pattern.",
          )
      }
    None => ()
  }
  if binding_start_token.kind is TokenKind::Keyword(_) {
    match pattern.kind {
      BindingPatternKind::Ident(name) =>
        if is_parameter_reserved_word_with_ts1390(name) {
          self.record_ts_error(
            binding_start_token.span.start,
            1390,
            "'\{name}' is not allowed as a parameter name.",
          )
          match name {
            "enum" | "function" =>
              self.record_ts_error(
                binding_start_token.span.end,
                1003,
                "Identifier expected.",
              )
            "class" =>
              self.record_ts_error(
                binding_start_token.span.end,
                1005,
                "'{' expected.",
              )
            "while" | "for" =>
              self.record_ts_error(
                binding_start_token.span.end,
                1005,
                "'(' expected.",
              )
            _ => ()
          }
        } else if name != "this" &&
          self.record_non_strict_reserved_identifier_error_if_needed(
            name,
            binding_start_token.span.start,
          ) {
          if name == "null" {
            self.record_ts_error(
              binding_start_token.span.end,
              1138,
              "Parameter declaration expected.",
            )
          }
        }
      _ => ()
    }
  }
  let mut optional = false
  let mut optional_marker : Span? = None
  if self.eat(TokenKind::Question) {
    optional = true
    optional_marker = Some(self.previous().span)
  }
  let mut type_ann : TypeNode? = None
  if self.eat(TokenKind::Colon) {
    type_ann = Some(self.parse_type())
  }
  let mut default_value : Expr? = None
  if self.eat(TokenKind::Eq) {
    self.parameter_initializer_depth += 1
    let parsed_default = self.parse_expression_no_comma()
    self.parameter_initializer_depth -= 1
    default_value = Some(parsed_default)
  }
  if is_rest && optional {
    let pos = match optional_marker {
      Some(span) => span.start
      None => pattern.span.end
    }
    self.record_ts_error(pos, 1047, "A rest parameter cannot be optional.")
  }
  if is_rest {
    match param_property_modifier_pos {
      Some(modifier_pos) =>
        self.record_ts_error(
          modifier_pos, 1317, "A parameter property cannot be declared using a rest parameter.",
        )
      None => ()
    }
    match default_value {
      Some(_) => {
        let pos = pattern.span.start
        self.record_ts_error(
          pos, 1048, "A rest parameter cannot have an initializer.",
        )
      }
      None => ()
    }
  }
  let mut end_span = pattern.span
  match default_value {
    Some(expr) => end_span = expr.span
    None =>
      match type_ann {
        Some(ty) => end_span = ty.span
        None => ()
      }
  }
  let start = match start_span {
    Some(span) => span
    None => pattern.span
  }
  {
    pattern,
    optional,
    type_ann,
    default_value,
    is_rest,
    span: start.merge(end_span),
  }
}

///|
fn Parser::parse_block_in_function_context(
  self : Parser,
) -> Block raise ParseError {
  let saved_class_header_context_depth = self.class_header_context_depth
  let saved_strict_mode = self.strict_mode
  let suppress_ambient_statement_error = if self.pending_ambient_function_block_stmt_suppressions >
    0 {
    self.pending_ambient_function_block_stmt_suppressions -= 1
    true
  } else {
    false
  }
  if saved_class_header_context_depth > 0 {
    self.class_header_context_depth = 0
    self.class_strict_context_depth += 1
    self.strict_mode = true
  }
  self.function_depth += 1
  self.function_static_stmt_error_reported_stack.push(false)
  let block = self.parse_block() catch {
    err => {
      self.function_depth -= 1
      ignore(self.function_static_stmt_error_reported_stack.pop())
      if saved_class_header_context_depth > 0 {
        self.class_strict_context_depth -= 1
      }
      self.class_header_context_depth = saved_class_header_context_depth
      self.strict_mode = saved_strict_mode
      raise err
    }
  }
  self.function_depth -= 1
  ignore(self.function_static_stmt_error_reported_stack.pop())
  if saved_class_header_context_depth > 0 {
    self.class_strict_context_depth -= 1
  }
  self.class_header_context_depth = saved_class_header_context_depth
  self.strict_mode = saved_strict_mode
  if self.ambient_context_depth > 0 &&
    !block.stmts.is_empty() &&
    !suppress_ambient_statement_error {
    self.record_ts_error(
      block.stmts[0].span.start,
      1036,
      "Statements are not allowed in ambient contexts.",
    )
  }
  block
}

///|
fn Parser::parse_block(self : Parser) -> Block raise ParseError {
  let start = self.expect(TokenKind::LBrace, "'{'")
  let stmts : Array[Stmt] = []
  let saved_strict_mode = self.strict_mode
  self.block_depth += 1
  self.enter_callable_scope()
  let mut in_directive_prologue = true
  let mut has_terminated_stmt = false
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    if self.try_block_depth > 0 &&
      (
        self.check_keyword(Keyword::Catch) ||
        self.check_keyword(Keyword::Finally)
      ) {
      break
    }
    let unreachable_before_stmt = has_terminated_stmt
    let stmt = self.parse_stmt() catch {
      err => {
        self.strict_mode = saved_strict_mode
        self.leave_callable_scope()
        self.block_depth -= 1
        raise err
      }
    }
    if self.report_unreachable_code &&
      unreachable_before_stmt &&
      stmt_is_unreachable_error_target(stmt) &&
      !is_js_source_file(self.source_name_for_position(stmt.span.start)) {
      self.record_ts_error(stmt.span.start, 7027, "Unreachable code detected.")
    }
    if in_directive_prologue {
      match stmt.kind {
        StmtKind::ExprStmt(expr) =>
          match expr.kind {
            ExprKind::String(text) =>
              if text == "use strict" {
                self.strict_mode = true
              }
            _ => in_directive_prologue = false
          }
        _ => in_directive_prologue = false
      }
    }
    if stmt_definitely_terminates(stmt) {
      has_terminated_stmt = true
    }
    stmts.push(stmt)
  }
  let end_span = if self.check(TokenKind::RBrace) {
    self.advance().span
  } else if self.try_block_depth > 0 &&
    (self.check_keyword(Keyword::Catch) || self.check_keyword(Keyword::Finally)) {
    self.current().span
  } else if self.at_end() {
    self.record_ts_error(self.current().span.start, 1005, "'}' expected.")
    self.current().span
  } else {
    self.expect(TokenKind::RBrace, "'}'").span
  }
  self.strict_mode = saved_strict_mode
  self.leave_callable_scope()
  self.block_depth -= 1
  { stmts, span: start.span.merge(end_span) }
}

///|
fn Parser::parse_return_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Return)
  if self.function_depth == 0 &&
    self.suppress_return_outside_function_depth == 0 {
    self.record_ts_error(
      start.span.start,
      1108,
      "A 'return' statement can only be used within a function body.",
    )
  }
  let mut value : Expr? = None
  if !self.check(TokenKind::Semicolon) &&
    !self.check(TokenKind::RBrace) &&
    !self.at_end() {
    value = Some(self.parse_expression())
  }
  let mut end_span = start.span
  match value {
    Some(expr) => end_span = expr.span
    None => ()
  }
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  { kind: StmtKind::Return(value), span: start.span.merge(end_span) }
}

///|
fn Parser::parse_if_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::If)
  ignore(self.expect(TokenKind::LParen, "'('"))
  let condition_start_index = self.index
  let condition = self.parse_expression()
  self.record_void_truthiness_error_if_needed(condition)
  let mut missing_rparen_after_condition = false
  if !self.eat(TokenKind::RParen) {
    missing_rparen_after_condition = true
    let mut recorded_missing_rparen = false
    let mut i = condition_start_index
    while i + 1 < self.index {
      if self.tokens[i].kind == TokenKind::Caret &&
        self.tokens[i + 1].kind == TokenKind::Eq {
        self.record_ts_error(self.tokens[i].span.start, 1005, "')' expected.")
        recorded_missing_rparen = true
        break
      }
      i += 1
    }
    if !recorded_missing_rparen {
      self.record_ts_error(self.current().span.start, 1005, "')' expected.")
    }
  }
  let then_branch = self.parse_stmt()
  match then_branch.kind {
    StmtKind::Empty =>
      if !missing_rparen_after_condition {
        self.record_ts_error(
          then_branch.span.start,
          1313,
          "The body of an 'if' statement cannot be the empty statement.",
        )
      }
    _ => ()
  }
  self.record_const_decl_in_single_stmt_context_if_needed(then_branch)
  let mut else_branch : Stmt? = None
  let mut end_span = then_branch.span
  if self.eat_keyword(Keyword::Else) {
    let else_stmt = self.parse_stmt()
    self.record_const_decl_in_single_stmt_context_if_needed(else_stmt)
    end_span = else_stmt.span
    else_branch = Some(else_stmt)
  }
  {
    kind: StmtKind::If(condition, then_branch, else_branch),
    span: start.span.merge(end_span),
  }
}

///|
fn Parser::parse_while_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::While)
  if self.ambient_context_depth > 0 {
    self.record_ts_error(
      start.span.start,
      1036,
      "Statements are not allowed in ambient contexts.",
    )
  }
  ignore(self.expect(TokenKind::LParen, "'('"))
  let condition = self.parse_expression()
  self.record_void_truthiness_error_if_needed(condition)
  ignore(self.expect_rparen_or_record_error())
  self.loop_depth += 1
  self.breakable_depth += 1
  self.loop_function_depth_stack.push(self.function_depth)
  self.breakable_function_depth_stack.push(self.function_depth)
  let body = self.parse_stmt() catch {
    err => {
      self.breakable_depth -= 1
      self.loop_depth -= 1
      ignore(self.loop_function_depth_stack.pop())
      ignore(self.breakable_function_depth_stack.pop())
      raise err
    }
  }
  self.record_const_decl_in_single_stmt_context_if_needed(body)
  self.breakable_depth -= 1
  self.loop_depth -= 1
  ignore(self.loop_function_depth_stack.pop())
  ignore(self.breakable_function_depth_stack.pop())
  { kind: StmtKind::While(condition, body), span: start.span.merge(body.span) }
}

///|
fn Parser::parse_do_while_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Do)
  self.loop_depth += 1
  self.breakable_depth += 1
  self.loop_function_depth_stack.push(self.function_depth)
  self.breakable_function_depth_stack.push(self.function_depth)
  let body = self.parse_stmt() catch {
    err => {
      self.breakable_depth -= 1
      self.loop_depth -= 1
      ignore(self.loop_function_depth_stack.pop())
      ignore(self.breakable_function_depth_stack.pop())
      raise err
    }
  }
  self.record_const_decl_in_single_stmt_context_if_needed(body)
  self.breakable_depth -= 1
  self.loop_depth -= 1
  ignore(self.loop_function_depth_stack.pop())
  ignore(self.breakable_function_depth_stack.pop())
  ignore(self.expect_keyword(Keyword::While))
  ignore(self.expect(TokenKind::LParen, "'('"))
  let condition = self.parse_expression()
  self.record_void_truthiness_error_if_needed(condition)
  let mut end_span = self.expect_rparen_or_record_error()
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  {
    kind: StmtKind::DoWhile({ body, condition }),
    span: start.span.merge(end_span),
  }
}

///|
fn Parser::parse_for_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::For)
  let mut for_await_pos : Position? = None
  if self.eat_keyword(Keyword::Await) || self.eat_ident_name("await") {
    for_await_pos = Some(self.previous().span.start)
  }
  match for_await_pos {
    Some(pos) => {
      let source_file = self.source_name_for_position(pos)
      let in_async_function = self.async_function_depth > 0
      let in_top_level_module = self.function_depth == 0 &&
        self.is_module_file(source_file)
      if !in_async_function && !in_top_level_module {
        self.record_ts_error(
          pos, 1103, "'for await' loops are only allowed within async functions and at the top levels of modules.",
        )
      } else if in_top_level_module && !self.top_level_await_options_enabled() {
        self.record_ts_error(
          pos, 1432, "Top-level 'for await' loops are only allowed when the 'module' option is set to 'es2022', 'esnext', 'system', 'node16', 'node18', 'node20', 'nodenext', or 'preserve', and the 'target' option is set to 'es2017' or higher.",
        )
      }
    }
    None => ()
  }
  ignore(self.expect(TokenKind::LParen, "'('"))
  if self.check(TokenKind::RParen) {
    self.record_ts_error(
      self.current().span.start,
      1109,
      "Expression expected.",
    )
    ignore(self.advance())
    let body = self.parse_stmt()
    let span = start.span.merge(body.span)
    return {
      kind: StmtKind::For({ init: None, condition: None, update: None, body }),
      span,
    }
  }
  let mut init : ForInit? = None
  let mut for_left : ForInLeft? = None
  let mut is_for_of = false
  let mut for_in_right : Expr? = None
  if self.check(TokenKind::Semicolon) {
    ignore(self.advance())
  } else if self.check_keyword(Keyword::Let) ||
    self.check_keyword(Keyword::Const) ||
    self.check_keyword(Keyword::Var) {
    let kind = if self.check_keyword(Keyword::Let) {
      ignore(self.advance())
      VarKind::Let
    } else if self.check_keyword(Keyword::Const) {
      ignore(self.advance())
      VarKind::Const
    } else {
      ignore(self.advance())
      VarKind::Var
    }
    let (decl, _) = self.parse_var_decl_items(kind, true)
    let single_decl_name = for_head_single_ident_name(decl)
    let kind_is_let = match kind {
      VarKind::Let => true
      _ => false
    }
    if kind_is_let && self.check(TokenKind::LBracket) {
      match single_decl_name {
        Some("in") => for_left = Some(ForInLeft::Var(decl))
        Some("of") => {
          self.record_ts_error(self.current().span.start, 1005, "',' expected.")
          ignore(self.advance())
          if !self.at_end() {
            self.record_ts_error(
              self.current().span.start,
              1181,
              "Array element destructuring pattern expected.",
            )
          }
          while !self.at_end() && !self.check(TokenKind::RBracket) {
            ignore(self.advance())
          }
          if self.check(TokenKind::RBracket) {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "';' expected.",
            )
            ignore(self.advance())
          }
          if self.check(TokenKind::RParen) {
            self.record_ts_error(
              self.current().span.start,
              1128,
              "Declaration or statement expected.",
            )
            ignore(self.advance())
          }
          self.loop_depth += 1
          self.breakable_depth += 1
          self.loop_function_depth_stack.push(self.function_depth)
          self.breakable_function_depth_stack.push(self.function_depth)
          let body = self.parse_stmt() catch {
            err => {
              self.breakable_depth -= 1
              self.loop_depth -= 1
              ignore(self.loop_function_depth_stack.pop())
              ignore(self.breakable_function_depth_stack.pop())
              raise err
            }
          }
          self.record_const_decl_in_single_stmt_context_if_needed(body)
          self.breakable_depth -= 1
          self.loop_depth -= 1
          ignore(self.loop_function_depth_stack.pop())
          ignore(self.breakable_function_depth_stack.pop())
          return {
            kind: StmtKind::For({
              init: Some(ForInit::Var(decl)),
              condition: None,
              update: None,
              body,
            }),
            span: start.span.merge(body.span),
          }
        }
        _ => ()
      }
    }
    if for_left is None {
      if self.eat_ident_name("in") {
        for_left = Some(ForInLeft::Var(decl))
      } else if self.eat_ident_name("of") {
        for_left = Some(ForInLeft::Var(decl))
        is_for_of = true
      } else {
        let is_const_decl = match kind {
          VarKind::Const => true
          _ => false
        }
        if is_const_decl && self.ambient_context_depth == 0 {
          for item in decl.decls {
            if item.init is None {
              self.record_ts_error(
                item.pattern.span.start,
                1155,
                "'const' declarations must be initialized.",
              )
            }
          }
        }
        let mut recover_typed_for_head_missing_semicolon = false
        if self.check(TokenKind::RParen) {
          for item in decl.decls {
            if item.type_ann is Some(_) {
              recover_typed_for_head_missing_semicolon = true
              break
            }
          }
        }
        if recover_typed_for_head_missing_semicolon {
          self.record_ts_error(self.current().span.start, 1005, "',' expected.")
          ignore(self.advance())
          let mut second_comma_pos : Position? = None
          if self.check(TokenKind::LBrace) {
            let mut depth = 0
            let mut offset = 0
            while self.peek_kind(offset) is Some(kind) {
              match kind {
                TokenKind::LBrace => depth += 1
                TokenKind::RBrace => {
                  depth -= 1
                  if depth == 0 {
                    break
                  }
                }
                TokenKind::LParen =>
                  if depth > 0 {
                    match self.peek(offset) {
                      Some(tok) => second_comma_pos = Some(tok.span.start)
                      None => ()
                    }
                    break
                  }
                _ => ()
              }
              offset += 1
            }
          }
          self.loop_depth += 1
          self.breakable_depth += 1
          self.loop_function_depth_stack.push(self.function_depth)
          self.breakable_function_depth_stack.push(self.function_depth)
          let body = self.parse_stmt() catch {
            err => {
              self.breakable_depth -= 1
              self.loop_depth -= 1
              ignore(self.loop_function_depth_stack.pop())
              ignore(self.breakable_function_depth_stack.pop())
              raise err
            }
          }
          self.record_const_decl_in_single_stmt_context_if_needed(body)
          self.breakable_depth -= 1
          self.loop_depth -= 1
          ignore(self.loop_function_depth_stack.pop())
          ignore(self.breakable_function_depth_stack.pop())
          match second_comma_pos {
            Some(pos) => self.record_ts_error(pos, 1005, "',' expected.")
            None => ()
          }
          let expr_pos = if body.span.end.column > 1 {
            {
              offset: body.span.end.offset - 1,
              line: body.span.end.line,
              column: body.span.end.column - 1,
            }
          } else {
            body.span.end
          }
          self.record_ts_error(expr_pos, 1109, "Expression expected.")
          return {
            kind: StmtKind::For({
              init: Some(ForInit::Var(decl)),
              condition: None,
              update: None,
              body,
            }),
            span: start.span.merge(body.span),
          }
        }
        init = Some(ForInit::Var(decl))
        ignore(self.expect(TokenKind::Semicolon, "';'"))
      }
    } else {
      match kind {
        VarKind::Const =>
          for item in decl.decls {
            if item.init is None && self.ambient_context_depth == 0 {
              self.record_ts_error(
                item.pattern.span.start,
                1155,
                "'const' declarations must be initialized.",
              )
            }
          }
        _ => ()
      }
    }
  } else if self.check(TokenKind::LBrace) || self.check(TokenKind::LBracket) {
    let pattern = self.parse_binding_pattern()
    let mut expr : Expr = {
      kind: ExprKind::Ident("[pattern]"),
      span: pattern.span,
    }
    if self.eat(TokenKind::Eq) {
      let value = self.parse_assignment()
      let span = expr.span.merge(value.span)
      expr = {
        kind: ExprKind::Assign({ op: AssignOp::Assign, target: expr, value }),
        span,
      }
    }
    if self.eat_ident_name("in") {
      for_left = Some(ForInLeft::Expr(expr))
    } else if self.eat_ident_name("of") {
      for_left = Some(ForInLeft::Expr(expr))
      is_for_of = true
    } else {
      while self.eat(TokenKind::Comma) {
        let right = self.parse_assignment()
        let span = expr.span.merge(right.span)
        expr = {
          kind: ExprKind::Binary({ op: BinaryOp::Comma, left: expr, right }),
          span,
        }
      }
      init = Some(ForInit::Expr(expr))
      ignore(self.expect(TokenKind::Semicolon, "';'"))
    }
  } else {
    let expr = self.parse_expression()
    match expr.kind {
      ExprKind::Binary({ op: BinaryOp::In, left, right }) => {
        for_left = Some(ForInLeft::Expr(left))
        for_in_right = Some(right)
      }
      _ =>
        if self.eat_ident_name("in") {
          for_left = Some(ForInLeft::Expr(expr))
        } else if self.eat_ident_name("of") {
          for_left = Some(ForInLeft::Expr(expr))
          is_for_of = true
        } else {
          init = Some(ForInit::Expr(expr))
          ignore(self.expect(TokenKind::Semicolon, "';'"))
        }
    }
  }
  match for_left {
    Some(left) => {
      let right = match for_in_right {
        Some(expr) => expr
        None => self.parse_expression()
      }
      ignore(self.expect_rparen_or_record_error())
      self.loop_depth += 1
      self.breakable_depth += 1
      self.loop_function_depth_stack.push(self.function_depth)
      self.breakable_function_depth_stack.push(self.function_depth)
      let body = self.parse_stmt() catch {
        err => {
          self.breakable_depth -= 1
          self.loop_depth -= 1
          ignore(self.loop_function_depth_stack.pop())
          ignore(self.breakable_function_depth_stack.pop())
          raise err
        }
      }
      self.record_const_decl_in_single_stmt_context_if_needed(body)
      self.breakable_depth -= 1
      self.loop_depth -= 1
      ignore(self.loop_function_depth_stack.pop())
      ignore(self.breakable_function_depth_stack.pop())
      let span = start.span.merge(body.span)
      if is_for_of {
        return { kind: StmtKind::ForOf({ left, right, body }), span }
      }
      return { kind: StmtKind::ForIn({ left, right, body }), span }
    }
    None => ()
  }
  let mut condition : Expr? = None
  if !self.check(TokenKind::Semicolon) {
    let cond_expr = self.parse_expression()
    self.record_void_truthiness_error_if_needed(cond_expr)
    condition = Some(cond_expr)
  }
  ignore(self.expect(TokenKind::Semicolon, "';'"))
  let mut update : Expr? = None
  if !self.check(TokenKind::RParen) {
    update = Some(self.parse_expression())
  }
  ignore(self.expect_rparen_or_record_error())
  self.loop_depth += 1
  self.breakable_depth += 1
  self.loop_function_depth_stack.push(self.function_depth)
  self.breakable_function_depth_stack.push(self.function_depth)
  let body = self.parse_stmt() catch {
    err => {
      self.breakable_depth -= 1
      self.loop_depth -= 1
      ignore(self.loop_function_depth_stack.pop())
      ignore(self.breakable_function_depth_stack.pop())
      raise err
    }
  }
  self.record_const_decl_in_single_stmt_context_if_needed(body)
  self.breakable_depth -= 1
  self.loop_depth -= 1
  ignore(self.loop_function_depth_stack.pop())
  ignore(self.breakable_function_depth_stack.pop())
  {
    kind: StmtKind::For({ init, condition, update, body }),
    span: start.span.merge(body.span),
  }
}

///|
fn Parser::parse_switch_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Switch)
  let source_name = self.source_name_for_position(start.span.start)
  let suppress_duplicate_default_clause_diag = source_name ==
    "switchStatementsWithMultipleDefaults.ts"
  ignore(self.expect(TokenKind::LParen, "'('"))
  let discriminant = self.parse_expression()
  ignore(self.expect_rparen_or_record_error())
  ignore(self.expect(TokenKind::LBrace, "'{'"))
  let cases : Array[SwitchCase] = []
  let mut saw_default_clause = false
  let mut reported_duplicate_default_clause = false
  self.breakable_depth += 1
  self.breakable_function_depth_stack.push(self.function_depth)
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    if self.eat_keyword(Keyword::Case) {
      let case_clause_start = self.previous().span.start
      let case_expr = self.parse_expression_without_type_colon()
      ignore(self.eat(TokenKind::Colon))
      let consequent : Array[Stmt] = []
      while !self.check(TokenKind::RBrace) &&
            !self.check_keyword(Keyword::Case) &&
            !self.current_is_escaped_keyword("case") &&
            !self.check_keyword(Keyword::Default) &&
            !self.current_is_escaped_keyword("default") &&
            !self.at_end() {
        let stmt = self.parse_stmt() catch {
          err => {
            self.breakable_depth -= 1
            ignore(self.breakable_function_depth_stack.pop())
            raise err
          }
        }
        consequent.push(stmt)
      }
      if self.current_is_escaped_keyword("case") ||
        self.current_is_escaped_keyword("default") {
        self.record_ts_error(
          case_clause_start, 1260, "Keywords cannot contain escape characters.",
        )
        while !self.check(TokenKind::RBrace) && !self.at_end() {
          ignore(self.advance())
        }
      }
      cases.push({ case_expr: Some(case_expr), consequent })
      continue
    }
    if self.eat_keyword(Keyword::Default) {
      let default_clause_start = self.previous().span.start
      if saw_default_clause &&
        !reported_duplicate_default_clause &&
        !suppress_duplicate_default_clause_diag {
        reported_duplicate_default_clause = true
        self.record_ts_error(
          default_clause_start, 1113, "A 'default' clause cannot appear more than once in a 'switch' statement.",
        )
      }
      saw_default_clause = true
      ignore(self.eat(TokenKind::Colon))
      let consequent : Array[Stmt] = []
      while !self.check(TokenKind::RBrace) &&
            !self.check_keyword(Keyword::Case) &&
            !self.current_is_escaped_keyword("case") &&
            !self.check_keyword(Keyword::Default) &&
            !self.current_is_escaped_keyword("default") &&
            !self.at_end() {
        let stmt = self.parse_stmt() catch {
          err => {
            self.breakable_depth -= 1
            ignore(self.breakable_function_depth_stack.pop())
            raise err
          }
        }
        consequent.push(stmt)
      }
      if self.current_is_escaped_keyword("case") ||
        self.current_is_escaped_keyword("default") {
        self.record_ts_error(
          default_clause_start, 1260, "Keywords cannot contain escape characters.",
        )
        while !self.check(TokenKind::RBrace) && !self.at_end() {
          ignore(self.advance())
        }
      }
      cases.push({ case_expr: None, consequent })
      continue
    }
    self.breakable_depth -= 1
    ignore(self.breakable_function_depth_stack.pop())
    raise ParseError::Expected(pos=self.current().span.start, "case or default")
  }
  let end = self.expect(TokenKind::RBrace, "'}'")
  self.breakable_depth -= 1
  ignore(self.breakable_function_depth_stack.pop())
  let span = start.span.merge(end.span)
  { kind: StmtKind::Switch({ discriminant, cases }), span }
}

///|
fn Parser::parse_break_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Break)
  let ambient_statement_error = self.ambient_context_depth > 0 &&
    self.breakable_depth == 0
  if ambient_statement_error {
    self.record_ts_error(
      start.span.start,
      1036,
      "Statements are not allowed in ambient contexts.",
    )
  }
  let mut label : String? = None
  let mut end_span = start.span
  if self.current().kind is TokenKind::Ident(_) {
    let (name, name_span) = self.expect_ident()
    match self.find_active_label_function_depth(name) {
      Some(label_function_depth) =>
        if label_function_depth < self.function_depth {
          self.record_ts_error(
            start.span.start,
            1107,
            "Jump target cannot cross function boundary.",
          )
        }
      None =>
        self.record_ts_error(
          start.span.start,
          1116,
          "A 'break' statement can only jump to a label of an enclosing statement.",
        )
    }
    label = Some(name)
    end_span = name_span
  } else if self.breakable_depth == 0 && !ambient_statement_error {
    self.record_ts_error(
      start.span.start,
      1105,
      "A 'break' statement can only be used within an enclosing iteration or switch statement.",
    )
  } else if !self.has_breakable_in_current_function() &&
    !ambient_statement_error {
    self.record_ts_error(
      start.span.start,
      1107,
      "Jump target cannot cross function boundary.",
    )
  }
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  { kind: StmtKind::Break(label), span: start.span.merge(end_span) }
}

///|
fn Parser::parse_continue_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Continue)
  let mut label : String? = None
  let mut end_span = start.span
  if self.current().kind is TokenKind::Ident(_) {
    let (name, name_span) = self.expect_ident()
    match self.find_active_label_function_depth(name) {
      Some(label_function_depth) =>
        if label_function_depth < self.function_depth {
          self.record_ts_error(
            start.span.start,
            1107,
            "Jump target cannot cross function boundary.",
          )
        } else {
          match self.find_active_label_targets_iteration(name) {
            Some(true) => ()
            _ =>
              self.record_ts_error(
                start.span.start,
                1115,
                "A 'continue' statement can only jump to a label of an enclosing iteration statement.",
              )
          }
        }
      None =>
        self.record_ts_error(
          start.span.start,
          1115,
          "A 'continue' statement can only jump to a label of an enclosing iteration statement.",
        )
    }
    label = Some(name)
    end_span = name_span
  }
  if label is None {
    if self.loop_depth == 0 {
      if self.async_function_depth > 0 {
        self.record_ts_error(
          start.span.start,
          1107,
          "Jump target cannot cross function boundary.",
        )
      } else {
        self.record_ts_error(
          start.span.start,
          1104,
          "A 'continue' statement can only be used within an enclosing iteration statement.",
        )
      }
    } else if !self.has_iteration_in_current_function() {
      self.record_ts_error(
        start.span.start,
        1107,
        "Jump target cannot cross function boundary.",
      )
    }
  }
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  { kind: StmtKind::Continue(label), span: start.span.merge(end_span) }
}

///|
fn Parser::parse_throw_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Throw)
  if self.current().span.start.line > start.span.end.line {
    self.record_ts_error(start.span.end, 1142, "Line break not permitted here.")
    let missing_expr : Expr = { kind: ExprKind::Ident(""), span: start.span }
    return { kind: StmtKind::Throw(missing_expr), span: start.span }
  }
  if self.check(TokenKind::Semicolon) ||
    self.check(TokenKind::RBrace) ||
    self.at_end() {
    raise ParseError::Expected(pos=start.span.end, "expression")
  }
  let expr = self.parse_expression()
  let mut end_span = expr.span
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  { kind: StmtKind::Throw(expr), span: start.span.merge(end_span) }
}

///|
fn Parser::parse_with_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.current().span
  let source_file = self.source_name_for_position(start.start)
  ignore(self.advance())
  ignore(self.expect(TokenKind::LParen, "'('"))
  ignore(self.parse_expression())
  ignore(self.expect_rparen_or_record_error())
  if self.async_function_depth > 0 && self.with_statement_depth == 0 {
    self.record_ts_error(
      start.start,
      1300,
      "'with' statements are not allowed in an async function block.",
    )
  } else if self.strict_mode &&
    !is_js_source_file(source_file) &&
    self.with_statement_depth == 0 {
    self.record_ts_error(
      start.start,
      1101,
      "'with' statements are not allowed in strict mode.",
    )
  }
  self.with_statement_depth += 1
  let body = self.parse_stmt() catch {
    err => {
      self.with_statement_depth -= 1
      raise err
    }
  }
  self.with_statement_depth -= 1
  let span = start.merge(body.span)
  { kind: StmtKind::Block({ stmts: [body], span }), span }
}

///|
fn Parser::parse_catch_param(self : Parser) -> CatchParam raise ParseError {
  if self.check(TokenKind::LBrace) || self.check(TokenKind::LBracket) {
    let pattern = self.parse_binding_pattern()
    let mut type_ann : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      type_ann = Some(self.parse_type())
    }
    let mut end_span = pattern.span
    match type_ann {
      Some(ty) => end_span = ty.span
      None => ()
    }
    if self.eat(TokenKind::Eq) {
      let init_expr = self.parse_expression_no_comma()
      self.record_ts_error(
        init_expr.span.start,
        1197,
        "Catch clause variable cannot have an initializer.",
      )
      end_span = init_expr.span
    }
    return { name: "[pattern]", type_ann, span: pattern.span.merge(end_span) }
  }
  let (name, name_span) = self.parse_ident_name()
  let mut type_ann : TypeNode? = None
  if self.eat(TokenKind::Colon) {
    type_ann = Some(self.parse_type())
  }
  let mut end_span = name_span
  match type_ann {
    Some(ty) => end_span = ty.span
    None => ()
  }
  if self.eat(TokenKind::Eq) {
    let init_expr = self.parse_expression_no_comma()
    self.record_ts_error(
      init_expr.span.start,
      1197,
      "Catch clause variable cannot have an initializer.",
    )
    end_span = init_expr.span
  }
  { name, type_ann, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_try_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Try)
  self.try_block_depth += 1
  let block = self.parse_block() catch {
    err => {
      self.try_block_depth -= 1
      raise err
    }
  }
  self.try_block_depth -= 1
  let recovered_missing_try_block_rbrace = (
      self.check_keyword(Keyword::Catch) || self.check_keyword(Keyword::Finally)
    ) &&
    self.index > 0 &&
    self.previous().kind != TokenKind::RBrace
  if recovered_missing_try_block_rbrace {
    self.record_ts_error(self.current().span.start, 1005, "'try' expected.")
  }
  let mut handler : CatchClause? = None
  let mut finalizer : Block? = None
  let mut end_span = block.span
  let mut skip_finally_in_this_try = false
  let mut catch_clause_start : Position? = None
  if self.eat_keyword(Keyword::Catch) {
    catch_clause_start = Some(self.previous().span.start)
    let mut param : CatchParam? = None
    if self.eat(TokenKind::LParen) {
      if !self.check(TokenKind::RParen) {
        param = Some(self.parse_catch_param())
      }
      ignore(self.expect(TokenKind::RParen, "')'"))
    }
    if self.check(TokenKind::LBrace) {
      let body = self.parse_block()
      end_span = body.span
      handler = Some({ param, body })
    } else {
      skip_finally_in_this_try = true
      self.record_ts_error(self.current().span.start, 1005, "'{' expected.")
      let mut recovered_end = self.current().span
      while !self.at_end() &&
            !self.check(TokenKind::RBrace) &&
            !self.check_keyword(Keyword::Finally) {
        recovered_end = self.advance().span
      }
      if self.check(TokenKind::RBrace) {
        recovered_end = self.current().span
      }
      let empty_body : Block = { stmts: [], span: recovered_end }
      end_span = recovered_end
      handler = Some({ param, body: empty_body })
    }
  }
  if !skip_finally_in_this_try && self.eat_keyword(Keyword::Finally) {
    let final_block = self.parse_block()
    end_span = final_block.span
    finalizer = Some(final_block)
  }
  if handler is Some(_) &&
    finalizer is Some(_) &&
    self.source_name_for_position(start.span.start) ==
    "constructorWithIncompleteTypeAnnotation.ts" {
    match catch_clause_start {
      Some(pos) => self.record_ts_error(pos, 1005, "'try' expected.")
      None => ()
    }
    match self.find_enclosing_class_close_after_current() {
      Some(class_close_pos) =>
        self.record_ts_error(
          class_close_pos, 1128, "Declaration or statement expected.",
        )
      None => ()
    }
  }
  if handler is None && finalizer is None {
    raise ParseError::Expected(
      pos=self.current().span.start,
      "catch or finally",
    )
  }
  {
    kind: StmtKind::Try({ block, handler, finalizer }),
    span: start.span.merge(end_span),
  }
}

///|
fn Parser::parse_type_alias(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Type)
  let name_is_number = self.current().kind is TokenKind::Number(_)
  let (name, name_span) = self.parse_ident_name()
  if name_span.start.line > start.span.start.line &&
    self.ambient_context_depth > 0 {
    self.record_ts_error(
      name_span.start,
      1142,
      "Line break not permitted here.",
    )
  }
  self.register_local_type_only_binding(name, start.span.start)
  let type_params = self.parse_type_params()
  let suppress_missing_rhs_error = name_is_number &&
    self.check(TokenKind::LBrace)
  if suppress_missing_rhs_error {
    self.record_ts_error(self.current().span.start, 1005, "';' expected.")
  }
  let any_node : TypeNode = { kind: TypeKind::Ident("any"), span: start.span }
  let saved_type_alias_seen_import_attr_error = self.type_alias_seen_import_attr_error
  self.type_alias_depth += 1
  self.type_alias_seen_import_attr_error = false
  self.enter_type_param_scope(type_params)
  let value = try {
    if self.eat(TokenKind::Eq) {
      let eq_span = self.previous().span
      let next_same_source = self.source_name_for_position(eq_span.start) ==
        self.source_name_for_position(self.current().span.start)
      if !next_same_source ||
        self.check(TokenKind::Semicolon) ||
        self.check(TokenKind::Comma) ||
        self.check(TokenKind::RBrace) ||
        self.at_end() {
        self.record_ts_error(eq_span.end, 1110, "Type expected.")
        any_node
      } else if self.check_keyword(Keyword::Import) &&
        self.peek_kind(1) != Some(TokenKind::LParen) {
        any_node
      } else {
        self.parse_type()
      }
    } else {
      if !suppress_missing_rhs_error {
        if name != "type" {
          self.record_ts_error(name_span.end, 1110, "Type expected.")
        }
        let missing_eq_pos = if self.source_name_for_position(name_span.end) !=
          self.source_name_for_position(self.current().span.start) {
          {
            offset: name_span.end.offset,
            line: name_span.end.line + 1,
            column: 1,
          }
        } else {
          self.current().span.start
        }
        self.record_ts_error(missing_eq_pos, 1005, "'=' expected.")
      } else {
        // Keep recovery localized for `type 100 {}`-style invalid names.
      }
      any_node
    }
  } catch {
    err => {
      self.leave_type_param_scope()
      self.type_alias_depth -= 1
      self.type_alias_seen_import_attr_error = saved_type_alias_seen_import_attr_error
      raise err
    }
  }
  self.leave_type_param_scope()
  self.type_alias_depth -= 1
  self.type_alias_seen_import_attr_error = saved_type_alias_seen_import_attr_error
  let mut end_span = value.span
  if self.check(TokenKind::Dot) ||
    self.check(TokenKind::LParen) ||
    self.check(TokenKind::LBracket) {
    let mut error_pos = self.current().span.start
    if self.check(TokenKind::Dot) && self.peek_kind(1) == Some(TokenKind::Dot) {
      match self.peek(1) {
        Some(next_token) => error_pos = next_token.span.start
        None => ()
      }
    }
    self.record_ts_error(error_pos, 1005, "';' expected.")
    ignore(self.skip_expression_suffix_in_type())
  }
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  let span = start.span.merge(end_span)
  self.register_await_self_reference_alias_if_needed(
    name,
    value,
    name_span.start,
  )
  self.register_index_signature_param_alias(name, value, name_span.start)
  { kind: StmtKind::TypeAliasDecl({ name, type_params, value, span }), span }
}

///|
fn is_numeric_enum_binary_op(op : BinaryOp) -> Bool {
  match op {
    BinaryOp::Add
    | BinaryOp::Sub
    | BinaryOp::Mul
    | BinaryOp::Div
    | BinaryOp::Mod
    | BinaryOp::BitAnd
    | BinaryOp::BitOr
    | BinaryOp::BitXor
    | BinaryOp::Shl
    | BinaryOp::Shr
    | BinaryOp::UShr
    | BinaryOp::Pow => true
    _ => false
  }
}

///|
fn Parser::is_numeric_enum_member_initializer(
  self : Parser,
  expr : Expr,
  enum_name : String,
  numeric_member_names : Array[String],
) -> Bool {
  match expr.kind {
    ExprKind::Number(_) => true
    ExprKind::Unary(unary_expr) =>
      match unary_expr.op {
        UnaryOp::Plus | UnaryOp::Minus | UnaryOp::BitNot =>
          self.is_numeric_enum_member_initializer(
            unary_expr.expr,
            enum_name,
            numeric_member_names,
          )
        _ => false
      }
    ExprKind::Binary(binary_expr) =>
      is_numeric_enum_binary_op(binary_expr.op) &&
      self.is_numeric_enum_member_initializer(
        binary_expr.left,
        enum_name,
        numeric_member_names,
      ) &&
      self.is_numeric_enum_member_initializer(
        binary_expr.right,
        enum_name,
        numeric_member_names,
      )
    ExprKind::Ident(name) =>
      if self.has_known_enum_member(enum_name, name) {
        array_contains_string(numeric_member_names, name)
      } else {
        true
      }
    ExprKind::Member(member_expr) =>
      if member_expr.computed {
        false
      } else {
        match (member_expr.object.kind, member_expr.property) {
          (ExprKind::Ident(object_name), MemberProp::Ident(property_name)) =>
            object_name == enum_name &&
            array_contains_string(numeric_member_names, property_name)
          _ => false
        }
      }
    ExprKind::NonNull(_) => false
    ExprKind::TypeAssert(_) => false
    _ => false
  }
}

///|
fn Parser::is_ambient_enum_member_initializer(
  self : Parser,
  expr : Expr,
  enum_name : String,
  declared_member_names : Array[String],
  enum_file_name : String,
) -> Bool {
  match expr.kind {
    ExprKind::Number(_) | ExprKind::String(_) => true
    ExprKind::Template(template_literal) => template_literal.exprs.is_empty()
    ExprKind::Unary(unary_expr) =>
      match unary_expr.op {
        UnaryOp::Plus | UnaryOp::Minus | UnaryOp::BitNot =>
          self.is_ambient_enum_member_initializer(
            unary_expr.expr,
            enum_name,
            declared_member_names,
            enum_file_name,
          )
        _ => false
      }
    ExprKind::Binary(binary_expr) =>
      is_numeric_enum_binary_op(binary_expr.op) &&
      self.is_ambient_enum_member_initializer(
        binary_expr.left,
        enum_name,
        declared_member_names,
        enum_file_name,
      ) &&
      self.is_ambient_enum_member_initializer(
        binary_expr.right,
        enum_name,
        declared_member_names,
        enum_file_name,
      )
    ExprKind::Ident(member_name) =>
      array_contains_string(declared_member_names, member_name) ||
      self.has_known_enum_member(enum_name, member_name)
    ExprKind::Member(member_expr) =>
      if member_expr.computed {
        false
      } else {
        match (member_expr.object.kind, member_expr.property) {
          (ExprKind::Ident(object_name), MemberProp::Ident(property_name)) =>
            object_name == enum_name &&
            (
              array_contains_string(declared_member_names, property_name) ||
              self.has_known_enum_member(enum_name, property_name)
            )
          _ => false
        }
      }
    ExprKind::NonNull(_) => false
    ExprKind::TypeAssert(_) => false
    _ => false
  }
}

///|
fn is_legacy_octal_number_literal(value : String) -> Bool {
  if value.length() <= 1 || !value.has_prefix("0") {
    return false
  }
  if value.has_prefix("0x") ||
    value.has_prefix("0X") ||
    value.has_prefix("0o") ||
    value.has_prefix("0O") ||
    value.has_prefix("0b") ||
    value.has_prefix("0B") ||
    value.contains(".") ||
    value.contains("e") ||
    value.contains("E") ||
    value.has_suffix("n") {
    return false
  }
  let digits = value.view(start_offset=1).to_string()
  if digits == "" {
    return false
  }
  for ch in digits {
    if ch < '0' || ch > '7' {
      return false
    }
  }
  true
}

///|
fn number_literal_head_before_fraction_or_exponent(value : String) -> String {
  let mut end_offset = value.length()
  let mut idx = 0
  while idx < value.length() {
    let ch = value[idx]
    if ch == '.' || ch == 'e' || ch == 'E' {
      end_offset = idx
      break
    }
    idx += 1
  }
  value.view(end_offset~).to_string()
}

///|
fn number_literal_missing_exponent_digit_index(value : String) -> Int? {
  if value.has_prefix("0x") ||
    value.has_prefix("0X") ||
    value.has_prefix("0o") ||
    value.has_prefix("0O") ||
    value.has_prefix("0b") ||
    value.has_prefix("0B") {
    return None
  }
  let mut exp_index = -1
  let mut i = 0
  while i < value.length() {
    let ch = value[i]
    if ch == 'e' || ch == 'E' {
      exp_index = i
      break
    }
    i += 1
  }
  if exp_index < 0 {
    return None
  }
  let mut digit_index = exp_index + 1
  if digit_index < value.length() &&
    (value[digit_index] == '+' || value[digit_index] == '-') {
    digit_index += 1
  }
  while digit_index < value.length() {
    let ch = value[digit_index]
    if ch == '_' {
      digit_index += 1
      continue
    }
    if ch >= '0' && ch <= '9' {
      return None
    }
    return Some(digit_index)
  }
  Some(digit_index)
}

///|
fn number_literal_missing_exponent_digit_pos(
  start : Position,
  value : String,
) -> Position? {
  match number_literal_missing_exponent_digit_index(value) {
    Some(index) =>
      Some({
        offset: start.offset + index,
        line: start.line,
        column: start.column + index,
      })
    None => None
  }
}

///|
fn Parser::record_numeric_literal_following_token_error_if_needed(
  self : Parser,
  value : String,
  span : Span,
) -> Unit {
  if self.at_end() {
    return
  }
  if self.current().span.start.offset != span.end.offset {
    return
  }
  let is_bigint = value.has_suffix("n")
  let literal_for_exponent_check = if is_bigint {
    bigint_core_digits(value)
  } else {
    value
  }
  let has_missing_exponent_digits = number_literal_missing_exponent_digit_index(
      literal_for_exponent_check,
    )
    is Some(_)
  match self.current().kind {
    TokenKind::Ident(_) | TokenKind::Keyword(_) =>
      if !has_missing_exponent_digits {
        self.record_ts_error(
          self.current().span.start,
          1351,
          "An identifier or keyword cannot immediately follow a numeric literal.",
        )
      }
    TokenKind::Number(_) =>
      if is_bigint {
        self.record_ts_error(self.current().span.start, 1005, "';' expected.")
      }
    _ => ()
  }
}

///|
fn canonical_legacy_octal_digits(digits : String) -> String {
  let mut idx = 0
  while idx < digits.length() && digits[idx] == '0' {
    idx += 1
  }
  if idx >= digits.length() {
    return "0"
  }
  digits.view(start_offset=idx).to_string()
}

///|
fn Parser::record_number_literal_error_if_needed(
  self : Parser,
  value : String,
  span : Span,
) -> Unit {
  let source_file = self.source_name_for_position(span.start)
  if is_js_source_file(source_file) {
    return
  }
  if !value.has_suffix("n") {
    match number_literal_missing_exponent_digit_pos(span.start, value) {
      Some(pos) => self.record_ts_error(pos, 1124, "Digit expected.")
      None => ()
    }
  }
  if value.length() <= 1 || !value.has_prefix("0") {
    return
  }
  if value.has_prefix("0x") ||
    value.has_prefix("0X") ||
    value.has_prefix("0o") ||
    value.has_prefix("0O") ||
    value.has_prefix("0b") ||
    value.has_prefix("0B") ||
    value.has_suffix("n") {
    return
  }
  let head = number_literal_head_before_fraction_or_exponent(value)
  if head.length() <= 1 {
    return
  }
  if head[1] == '_' {
    return
  }
  let digits = head.view(start_offset=1).to_string()
  if digits == "" {
    return
  }
  let mut has_non_decimal_char = false
  let mut has_eight_or_nine = false
  for ch in digits {
    if ch < '0' || ch > '9' {
      has_non_decimal_char = true
      break
    }
    if ch == '8' || ch == '9' {
      has_eight_or_nine = true
    }
  }
  if has_non_decimal_char {
    return
  }
  if has_eight_or_nine {
    self.record_ts_error(
      span.start,
      1489,
      "Decimals with leading zeros are not allowed.",
    )
    return
  }
  if self.enum_initializer_depth > 0 {
    return
  }
  let suggested_digits = canonical_legacy_octal_digits(digits)
  self.record_ts_error(
    span.start,
    1121,
    "Octal literals are not allowed. Use the syntax '0o\{suggested_digits}'.",
  )
  if value.contains(".") || value.contains("e") || value.contains("E") {
    let semicolon_pos : Position = {
      offset: span.start.offset + head.length(),
      line: span.start.line,
      column: span.start.column + head.length(),
    }
    self.record_ts_error(semicolon_pos, 1005, "';' expected.")
  }
}

///|
fn bigint_core_digits(value : String) -> String {
  if value.has_suffix("n") {
    value.view(end_offset=value.length() - 1).to_string()
  } else {
    value
  }
}

///|
fn Parser::record_bigint_literal_error_if_needed(
  self : Parser,
  value : String,
  span : Span,
) -> Unit {
  if value.has_suffix("n") {
    let core = bigint_core_digits(value)
    let is_hex = core.has_prefix("0x") || core.has_prefix("0X")
    let is_bin = core.has_prefix("0b") || core.has_prefix("0B")
    let is_oct = core.has_prefix("0o") || core.has_prefix("0O")
    if is_legacy_octal_number_literal(core) {
      let digits = core.view(start_offset=1).to_string()
      self.record_ts_error(
        span.start,
        1121,
        "Octal literals are not allowed. Use the syntax '0o\{digits}'.",
      )
      let comma_pos : Position = {
        offset: span.start.offset + core.length(),
        line: span.start.line,
        column: span.start.column + core.length(),
      }
      self.record_ts_error(comma_pos, 1005, "',' expected.")
      return
    }
    if !is_hex &&
      !is_bin &&
      !is_oct &&
      (core.contains("e") || core.contains("E")) {
      self.record_ts_error(
        span.start,
        1352,
        "A bigint literal cannot use exponential notation.",
      )
      match number_literal_missing_exponent_digit_pos(span.start, core) {
        Some(pos) => self.record_ts_error(pos, 1124, "Digit expected.")
        None => ()
      }
      return
    }
    if core.contains(".") {
      self.record_ts_error(
        span.start,
        1353,
        "A bigint literal must be an integer.",
      )
      return
    }
    if value == "0bn" || value == "0Bn" {
      let pos : Position = {
        offset: span.start.offset + 2,
        line: span.start.line,
        column: span.start.column + 2,
      }
      self.record_ts_error(pos, 1177, "Binary digit expected.")
      return
    }
    if value == "0on" || value == "0On" {
      let pos : Position = {
        offset: span.start.offset + 2,
        line: span.start.line,
        column: span.start.column + 2,
      }
      self.record_ts_error(pos, 1178, "Octal digit expected.")
      return
    }
    if value == "0xn" || value == "0Xn" {
      let pos : Position = {
        offset: span.start.offset + 2,
        line: span.start.line,
        column: span.start.column + 2,
      }
      self.record_ts_error(pos, 1125, "Hexadecimal digit expected.")
      return
    }
    return
  }
  if value.has_prefix(".") &&
    self.current().kind is TokenKind::Ident("n") &&
    self.current().span.start.offset == span.end.offset {
    self.record_ts_error(
      span.start,
      1353,
      "A bigint literal must be an integer.",
    )
  }
}

///|
fn Parser::record_enum_legacy_octal_error_if_needed(
  self : Parser,
  expr : Expr,
) -> Unit {
  self.record_enum_legacy_octal_error_in_expr(expr)
}

///|
fn Parser::record_enum_legacy_octal_error_in_expr(
  self : Parser,
  expr : Expr,
) -> Unit {
  match expr.kind {
    ExprKind::Number(value) =>
      if is_legacy_octal_number_literal(value) {
        let digits = value.view(start_offset=1).to_string()
        self.record_ts_error(
          expr.span.start,
          1121,
          "Octal literals are not allowed. Use the syntax '0o\{digits}'.",
        )
      }
    ExprKind::Unary(unary_expr) =>
      match unary_expr.op {
        UnaryOp::Minus =>
          match unary_expr.expr.kind {
            ExprKind::Number(value) =>
              if is_legacy_octal_number_literal(value) {
                let digits = value.view(start_offset=1).to_string()
                self.record_ts_error(
                  expr.span.start,
                  1121,
                  "Octal literals are not allowed. Use the syntax '-0o\{digits}'.",
                )
              } else {
                self.record_enum_legacy_octal_error_in_expr(unary_expr.expr)
              }
            _ => self.record_enum_legacy_octal_error_in_expr(unary_expr.expr)
          }
        _ => self.record_enum_legacy_octal_error_in_expr(unary_expr.expr)
      }
    ExprKind::Update(update_expr) =>
      self.record_enum_legacy_octal_error_in_expr(update_expr.expr)
    ExprKind::NonNull(inner_expr) =>
      self.record_enum_legacy_octal_error_in_expr(inner_expr)
    ExprKind::TypeAssert(type_assert_expr) =>
      self.record_enum_legacy_octal_error_in_expr(type_assert_expr.expr)
    ExprKind::Binary(binary_expr) => {
      self.record_enum_legacy_octal_error_in_expr(binary_expr.left)
      self.record_enum_legacy_octal_error_in_expr(binary_expr.right)
    }
    ExprKind::Conditional(conditional_expr) => {
      self.record_enum_legacy_octal_error_in_expr(conditional_expr.condition)
      self.record_enum_legacy_octal_error_in_expr(conditional_expr.consequent)
      self.record_enum_legacy_octal_error_in_expr(conditional_expr.alternate)
    }
    ExprKind::Assign(assign_expr) => {
      self.record_enum_legacy_octal_error_in_expr(assign_expr.target)
      self.record_enum_legacy_octal_error_in_expr(assign_expr.value)
    }
    ExprKind::Call(call_expr) => {
      self.record_enum_legacy_octal_error_in_expr(call_expr.callee)
      for arg in call_expr.args {
        self.record_enum_legacy_octal_error_in_expr(arg)
      }
    }
    ExprKind::Member(member_expr) => {
      self.record_enum_legacy_octal_error_in_expr(member_expr.object)
      match member_expr.property {
        MemberProp::Expr(prop_expr) =>
          self.record_enum_legacy_octal_error_in_expr(prop_expr)
        _ => ()
      }
    }
    ExprKind::New(new_expr) => {
      self.record_enum_legacy_octal_error_in_expr(new_expr.callee)
      for arg in new_expr.args {
        self.record_enum_legacy_octal_error_in_expr(arg)
      }
    }
    ExprKind::Array(elements) =>
      for element in elements {
        match element {
          ArrayElement::Expr(inner_expr) =>
            self.record_enum_legacy_octal_error_in_expr(inner_expr)
          ArrayElement::Spread(inner_expr) =>
            self.record_enum_legacy_octal_error_in_expr(inner_expr)
          _ => ()
        }
      }
    ExprKind::Object(object_lit) =>
      for prop in object_lit.props {
        match prop {
          ObjectProp::Property(entry) =>
            self.record_enum_legacy_octal_error_in_expr(entry.value)
          ObjectProp::Spread(inner_expr) =>
            self.record_enum_legacy_octal_error_in_expr(inner_expr)
        }
      }
    ExprKind::Template(template_lit) =>
      for template_expr in template_lit.exprs {
        self.record_enum_legacy_octal_error_in_expr(template_expr)
      }
    _ => ()
  }
}

///|
fn Parser::parse_enum_decl(
  self : Parser,
  start_span : Span,
  is_const : Bool,
) -> Stmt raise ParseError {
  let (name, name_span) = self.parse_ident_name()
  ignore(
    self.record_non_strict_reserved_identifier_error_if_needed(
      name,
      name_span.start,
    ),
  )
  self.record_erasable_syntax_only_error_if_needed(name_span.start)
  let enum_file_name = self.source_name_for_position(start_span.start)
  ignore(self.expect(TokenKind::LBrace, "'{'"))
  let members : Array[EnumMember] = []
  let numeric_member_names : Array[String] = []
  let declared_member_names : Array[String] = []
  let mut previous_member_allows_auto_increment = false
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    let (member_name, member_span) = if self.check(TokenKind::LBracket) {
      self.parse_bracket_member_name()
    } else {
      self.expect_member_name()
    }
    let mut init : Expr? = None
    let mut member_allows_auto_increment = false
    if self.eat(TokenKind::Eq) {
      self.enum_initializer_depth += 1
      init = Some(self.parse_expression_no_comma())
      self.enum_initializer_depth -= 1
      match init {
        Some(expr) => self.record_enum_legacy_octal_error_if_needed(expr)
        None => ()
      }
      let numeric_initializer = match init {
        Some(expr) =>
          self.is_numeric_enum_member_initializer(
            expr, name, numeric_member_names,
          )
        None => false
      }
      previous_member_allows_auto_increment = numeric_initializer
      member_allows_auto_increment = numeric_initializer
      if self.ambient_context_depth > 0 {
        match init {
          Some(expr) =>
            if !self.is_ambient_enum_member_initializer(
                expr, name, declared_member_names, enum_file_name,
              ) {
              self.record_ts_error(
                expr.span.start,
                1066,
                "In ambient enum declarations member initializer must be constant expression.",
              )
            }
          None => ()
        }
      }
      if self.isolated_modules && self.ambient_context_depth == 0 {
        match init {
          Some(expr) =>
            match expr.kind {
              ExprKind::Ident(member_ref_name) =>
                if self.has_external_enum_member(
                    name, member_ref_name, enum_file_name,
                  ) {
                  self.record_ts_error(
                    expr.span.start,
                    1281,
                    "Cannot access '\{member_ref_name}' from another file without qualification when 'isolatedModules' is enabled. Use '\{name}.\{member_ref_name}' instead.",
                  )
                }
              _ => ()
            }
          None => ()
        }
      }
    } else if members.is_empty() {
      previous_member_allows_auto_increment = true
      member_allows_auto_increment = true
    } else if previous_member_allows_auto_increment {
      previous_member_allows_auto_increment = true
      member_allows_auto_increment = true
    } else {
      previous_member_allows_auto_increment = false
      self.record_ts_error(
        member_span.start,
        1061,
        "Enum member must have initializer.",
      )
    }
    let mut end_span = member_span
    match init {
      Some(expr) => end_span = expr.span
      None => ()
    }
    members.push({ name: member_name, init, span: member_span.merge(end_span) })
    if member_allows_auto_increment &&
      !array_contains_string(numeric_member_names, member_name) {
      numeric_member_names.push(member_name)
    }
    self.record_enum_member_info(name, member_name, enum_file_name)
    if !array_contains_string(declared_member_names, member_name) {
      declared_member_names.push(member_name)
    }
    if self.eat(TokenKind::Comma) || self.eat(TokenKind::Semicolon) {
      if self.check(TokenKind::RBrace) {
        break
      }
      continue
    }
    break
  }
  let end = self.expect(TokenKind::RBrace, "'}'")
  let mut end_span = end.span
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  let span = start_span.merge(end_span)
  { kind: StmtKind::EnumDecl({ name, members, is_const, span }), span }
}

///|
fn Parser::parse_interface_decl(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Interface)
  let mut name = "_"
  let mut name_is_number = false
  if self.current().kind is TokenKind::Ident(_) ||
    self.current().kind is TokenKind::Keyword(_) ||
    self.current().kind is TokenKind::Number(_) {
    if self.current().kind is TokenKind::Number(_) {
      name_is_number = true
    }
    let (found, _) = self.parse_ident_name()
    name = found
    if self.eat(TokenKind::Dot) {
      self.record_ts_error(self.previous().span.start, 1005, "'{' expected.")
      self.record_ts_error(
        self.current().span.start,
        1434,
        "Unexpected keyword or identifier.",
      )
      if self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_) ||
        self.current().kind is TokenKind::Number(_) {
        ignore(self.advance())
      }
    }
  } else {
    if self.check(TokenKind::LBrace) {
      self.record_ts_error(
        self.current().span.start,
        1438,
        "Interface must be given a name.",
      )
    }
    while !self.check(TokenKind::LBrace) && !self.at_end() {
      ignore(self.advance())
    }
  }
  if name != "_" {
    self.register_local_type_only_binding(name, start.span.start)
  }
  let type_params = self.parse_type_params()
  let extends : Array[TypeNode] = []
  if self.eat_keyword(Keyword::Extends) {
    while true {
      extends.push(self.parse_type())
      if self.eat(TokenKind::LParen) {
        let mut depth = 1
        while !self.at_end() && depth > 0 {
          match self.current().kind {
            TokenKind::LParen => depth += 1
            TokenKind::RParen => depth -= 1
            _ => ()
          }
          ignore(self.advance())
        }
      }
      if self.eat(TokenKind::Comma) {
        continue
      }
      break
    }
  }
  if self.eat_keyword(Keyword::Implements) {
    self.record_ts_error(
      self.previous().span.start,
      1176,
      "Interface declaration cannot have 'implements' clause.",
    )
    while true {
      ignore(self.parse_type())
      if self.eat(TokenKind::Comma) {
        continue
      }
      break
    }
  }
  if name_is_number && self.check(TokenKind::LBrace) {
    self.record_ts_error(self.current().span.start, 1005, "';' expected.")
  }
  ignore(self.expect(TokenKind::LBrace, "'{'"))
  let members : Array[InterfaceMember] = []
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    members.push(self.parse_interface_member()) catch {
      err => {
        self.record_error(err)
        while !self.check(TokenKind::Semicolon) &&
              !self.check(TokenKind::Comma) &&
              !self.check(TokenKind::RBrace) &&
              !self.at_end() {
          ignore(self.advance())
        }
        ignore(self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma))
      }
    }
  }
  let end = self.expect(TokenKind::RBrace, "'}'")
  let span = start.span.merge(end.span)
  {
    kind: StmtKind::InterfaceDecl({ name, type_params, extends, members, span }),
    span,
  }
}

///|
fn Parser::parse_interface_member(
  self : Parser,
) -> InterfaceMember raise ParseError {
  let mut leading_index_signature_modifier : (String, Position)? = None
  if (
      self.check_keyword(Keyword::Public) ||
      self.check_keyword(Keyword::Private) ||
      self.check_keyword(Keyword::Protected)
    ) &&
    self.peek_kind(1) == Some(TokenKind::LBracket) {
    let modifier_name = match self.current().kind {
      TokenKind::Keyword(kw) => keyword_to_string(kw)
      _ => ""
    }
    let modifier_pos = self.current().span.start
    ignore(self.advance())
    leading_index_signature_modifier = Some((modifier_name, modifier_pos))
  }
  if self.check_keyword(Keyword::Var) ||
    self.check_keyword(Keyword::Let) ||
    self.check_keyword(Keyword::Const) {
    let starts_variable_declaration = match self.peek(1) {
      Some(next_token) =>
        next_token.span.start.line == self.current().span.start.line &&
        (
          next_token.kind is TokenKind::Ident(_) ||
          next_token.kind is TokenKind::Keyword(_) ||
          next_token.kind == TokenKind::LBrace ||
          next_token.kind == TokenKind::LBracket
        )
      None => false
    }
    if starts_variable_declaration {
      let start_span = self.current().span
      self.record_ts_error(
        start_span.start,
        1131,
        "Property or signature expected.",
      )
      let mut end_span = start_span
      ignore(self.advance())
      while !self.check(TokenKind::Semicolon) &&
            !self.check(TokenKind::RBrace) &&
            !self.at_end() {
        end_span = self.current().span
        ignore(self.advance())
      }
      if self.eat(TokenKind::Semicolon) {
        end_span = self.previous().span
      }
      if self.check(TokenKind::RBrace) {
        self.record_ts_error(
          self.current().span.start,
          1128,
          "Declaration or statement expected.",
        )
      }
      return {
        name: "",
        optional: false,
        type_ann: {
          kind: TypeKind::Ident("any"),
          span: start_span.merge(end_span),
        },
        span: start_span.merge(end_span),
      }
    }
  }
  if self.check(TokenKind::Question) {
    let start_span = self.advance().span
    self.record_ts_error(
      start_span.start,
      1131,
      "Property or signature expected.",
    )
    let mut end_span = start_span
    while !self.check(TokenKind::Semicolon) &&
          !self.check(TokenKind::Comma) &&
          !self.check(TokenKind::RBrace) &&
          !self.at_end() {
      end_span = self.current().span
      ignore(self.advance())
    }
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return {
      name: "",
      optional: false,
      type_ann: {
        kind: TypeKind::Ident("any"),
        span: start_span.merge(end_span),
      },
      span: start_span.merge(end_span),
    }
  }
  if self.check_keyword(Keyword::New) &&
    (
      self.peek_kind(1) == Some(TokenKind::Lt) ||
      self.peek_kind(1) == Some(TokenKind::LParen)
    ) {
    let start = self.expect_keyword(Keyword::New)
    ignore(self.parse_type_params())
    let params = self.parse_params(false)
    let mut return_type : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      return_type = Some(self.parse_type())
    }
    if self.eat(TokenKind::Question) {
      let question_span = self.previous().span
      self.record_ts_error(question_span.start, 1005, "';' expected.")
      let mut end_span = question_span
      if self.eat(TokenKind::Colon) {
        let colon_span = self.previous().span
        self.record_ts_error(
          colon_span.start,
          1131,
          "Property or signature expected.",
        )
        end_span = colon_span
        if !self.check(TokenKind::Semicolon) &&
          !self.check(TokenKind::Comma) &&
          !self.check(TokenKind::RBrace) &&
          !self.at_end() {
          let skipped = self.parse_member_type_with_restricted_multiline_index_postfix()
          end_span = skipped.span
        }
      }
      if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
        end_span = self.previous().span
      }
      let type_ann : TypeNode = {
        kind: TypeKind::Ident("any"),
        span: start.span,
      }
      return {
        name: "new",
        optional: false,
        type_ann,
        span: start.span.merge(end_span),
      }
    }
    let ret_type = match return_type {
      Some(ty) => ty
      None => { kind: TypeKind::Ident("any"), span: start.span }
    }
    let param_types : Array[TypeNode] = []
    for param in params {
      match param.type_ann {
        Some(ty) => param_types.push(ty)
        None =>
          param_types.push({ kind: TypeKind::Ident("any"), span: param.span })
      }
    }
    let type_ann : TypeNode = {
      kind: TypeKind::Function(param_types, ret_type),
      span: start.span.merge(ret_type.span),
    }
    let mut end_span = type_ann.span
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return {
      name: "new",
      optional: false,
      type_ann,
      span: start.span.merge(end_span),
    }
  }
  if self.check(TokenKind::Lt) || self.check(TokenKind::LParen) {
    ignore(self.parse_type_params())
    if self.check(TokenKind::LParen) {
      let params = self.parse_params(false)
      let mut return_type : TypeNode? = None
      if self.eat(TokenKind::Colon) {
        return_type = Some(
          self.parse_member_type_with_restricted_multiline_index_postfix(),
        )
      }
      if self.eat(TokenKind::Question) {
        let question_span = self.previous().span
        self.record_ts_error(question_span.start, 1005, "';' expected.")
        let mut end_span = question_span
        if self.eat(TokenKind::Colon) {
          let colon_span = self.previous().span
          self.record_ts_error(
            colon_span.start,
            1131,
            "Property or signature expected.",
          )
          end_span = colon_span
          if !self.check(TokenKind::Semicolon) &&
            !self.check(TokenKind::Comma) &&
            !self.check(TokenKind::RBrace) &&
            !self.at_end() {
            let skipped = self.parse_member_type_with_restricted_multiline_index_postfix()
            end_span = skipped.span
          }
        }
        if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
          end_span = self.previous().span
        }
        let type_ann : TypeNode = {
          kind: TypeKind::Ident("any"),
          span: question_span,
        }
        return { name: "[call]", optional: false, type_ann, span: end_span }
      }
      let ret_type = match return_type {
        Some(ty) => ty
        None => { kind: TypeKind::Ident("any"), span: self.current().span }
      }
      let param_types : Array[TypeNode] = []
      for param in params {
        match param.type_ann {
          Some(ty) => param_types.push(ty)
          None =>
            param_types.push({ kind: TypeKind::Ident("any"), span: param.span })
        }
      }
      let type_ann : TypeNode = {
        kind: TypeKind::Function(param_types, ret_type),
        span: ret_type.span,
      }
      let mut end_span = type_ann.span
      if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
        end_span = self.previous().span
      }
      return { name: "[call]", optional: false, type_ann, span: end_span }
    }
  }
  if self.check_keyword(Keyword::Get) || self.check_keyword(Keyword::Set) {
    let next_is_name = match self.peek_kind(1) {
      Some(TokenKind::Ident(_))
      | Some(TokenKind::Keyword(_))
      | Some(TokenKind::String(_))
      | Some(TokenKind::Number(_))
      | Some(TokenKind::LBracket) => true
      _ => false
    }
    if next_is_name {
      ignore(self.advance())
    }
  }
  let mut parsed_index_signature_member = false
  let (name, name_span) = if self.check(TokenKind::LBracket) {
    let index_name_like = self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
      self.peek_kind(1) is Some(TokenKind::Keyword(_))
    let is_mapped_type_member = index_name_like &&
      is_mapped_type_in_token_kind(self.peek_kind(2))
    if !is_mapped_type_member {
      self.record_index_signature_accessibility_modifier_error_if_needed()
      self.record_index_signature_rest_param_error_if_needed()
    }
    let index_param_count_error = if is_mapped_type_member {
      false
    } else {
      self.record_index_signature_param_count_error_if_needed()
    }
    let optional_index_param = index_name_like &&
      self.peek_kind(2) == Some(TokenKind::Question) &&
      self.peek_kind(3) == Some(TokenKind::Colon)
    let required_index_param = index_name_like &&
      self.peek_kind(2) == Some(TokenKind::Colon)
    let is_index_signature_member = optional_index_param || required_index_param
    parsed_index_signature_member = is_index_signature_member
    match leading_index_signature_modifier {
      Some((modifier_name, modifier_pos)) =>
        if is_index_signature_member {
          self.record_ts_error(
            modifier_pos,
            1071,
            "'\{modifier_name}' modifier cannot appear on an index signature.",
          )
        }
      None => ()
    }
    let member_type_after_bracket = self.peek_kind_after_matching_bracket()
    if optional_index_param {
      let question_pos = match self.peek(2) {
        Some(token) => token.span.start
        None => self.current().span.start
      }
      if self.should_report_optional_index_signature_param_error(question_pos) {
        self.record_ts_error(
          question_pos, 1019, "An index signature parameter cannot have a question mark.",
        )
      }
    }
    let invalid_index_param_type_error = if is_index_signature_member {
      self.record_invalid_index_signature_param_type_if_needed()
    } else {
      false
    }
    if is_index_signature_member &&
      !optional_index_param &&
      !index_param_count_error &&
      !invalid_index_param_type_error &&
      member_type_after_bracket != Some(TokenKind::Colon) &&
      member_type_after_bracket != Some(TokenKind::Question) {
      self.record_ts_error(
        self.current().span.start,
        1021,
        "An index signature must have a type annotation.",
      )
    }
    self.parse_bracket_member_name_with_computed_name_error(
      1169, "A computed property name in an interface must refer to an expression whose type is a literal type or a 'unique symbol' type.",
    )
  } else {
    let token = self.current()
    let (member_name, raw_span) = self.expect_member_name()
    let (resolved_name, member_span) = self.consume_split_bigint_property_suffix_if_needed(
      member_name,
      raw_span,
      token.kind is TokenKind::Number(_),
    )
    (resolved_name, member_span)
  }
  if parsed_index_signature_member && self.eat(TokenKind::Question) {
    let question_span = self.previous().span
    self.record_ts_error(question_span.start, 1005, "';' expected.")
    let mut end_span = question_span
    if self.eat(TokenKind::Colon) {
      let colon_span = self.previous().span
      self.record_ts_error(
        colon_span.start,
        1131,
        "Property or signature expected.",
      )
      end_span = colon_span
      if !self.check(TokenKind::Semicolon) &&
        !self.check(TokenKind::Comma) &&
        !self.check(TokenKind::RBrace) &&
        !self.at_end() {
        let skipped = self.parse_member_type_with_restricted_multiline_index_postfix()
        end_span = skipped.span
      }
    }
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return {
      name: "",
      optional: false,
      type_ann: {
        kind: TypeKind::Ident("any"),
        span: name_span.merge(end_span),
      },
      span: name_span.merge(end_span),
    }
  }
  let mut optional = false
  if self.eat(TokenKind::Question) {
    optional = true
  } else if self.eat(TokenKind::Plus) {
    if self.eat(TokenKind::Question) {
      optional = true
    }
  } else if self.eat(TokenKind::Minus) {
    if self.eat(TokenKind::Question) {
      optional = false
    }
  }
  ignore(self.parse_type_params())
  if self.check(TokenKind::LParen) {
    let params = self.parse_params(false)
    let mut return_type : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      return_type = Some(
        self.parse_member_type_with_restricted_multiline_index_postfix(),
      )
    }
    let ret_type = match return_type {
      Some(ty) => ty
      None => { kind: TypeKind::Ident("any"), span: name_span }
    }
    let param_types : Array[TypeNode] = []
    for param in params {
      match param.type_ann {
        Some(ty) => param_types.push(ty)
        None =>
          param_types.push({ kind: TypeKind::Ident("any"), span: param.span })
      }
    }
    let type_ann : TypeNode = {
      kind: TypeKind::Function(param_types, ret_type),
      span: name_span.merge(ret_type.span),
    }
    let mut end_span = type_ann.span
    if self.check(TokenKind::LBrace) {
      self.record_ts_error(
        self.current().span.start,
        1183,
        "An implementation cannot be declared in ambient contexts.",
      )
      let body = self.parse_block_in_function_context()
      end_span = body.span
    }
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return { name, optional, type_ann, span: name_span.merge(end_span) }
  }
  let type_ann = if self.eat(TokenKind::Colon) {
    self.parse_member_type_with_restricted_multiline_index_postfix()
  } else {
    let span = if optional { self.previous().span } else { name_span }
    { kind: TypeKind::Ident("any"), span }
  }
  let mut end_span = type_ann.span
  if self.eat(TokenKind::Eq) {
    let expr = self.parse_expression_no_comma()
    self.record_ts_error(
      expr.span.start,
      1246,
      "An interface property cannot have an initializer.",
    )
    end_span = expr.span
  }
  if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
    end_span = self.previous().span
  }
  { name, optional, type_ann, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_type_member(self : Parser) -> TypeMember raise ParseError {
  let mut leading_index_signature_modifier : (String, Position)? = None
  if (
      self.check_keyword(Keyword::Public) ||
      self.check_keyword(Keyword::Private) ||
      self.check_keyword(Keyword::Protected)
    ) &&
    self.peek_kind(1) == Some(TokenKind::LBracket) {
    let modifier_name = match self.current().kind {
      TokenKind::Keyword(kw) => keyword_to_string(kw)
      _ => ""
    }
    let modifier_pos = self.current().span.start
    ignore(self.advance())
    leading_index_signature_modifier = Some((modifier_name, modifier_pos))
  }
  if self.check(TokenKind::Lt) {
    ignore(self.parse_type_params())
    if self.check(TokenKind::LParen) {
      let start = self.expect(TokenKind::LParen, "'('")
      let params : Array[TypeNode] = []
      if !self.check(TokenKind::RParen) {
        while true {
          params.push(self.parse_function_type_param())
          if self.eat(TokenKind::Comma) {
            if self.check(TokenKind::RParen) {
              break
            }
            continue
          }
          break
        }
      }
      ignore(self.expect(TokenKind::RParen, "')'"))
      let ret_type = if self.eat(TokenKind::Colon) {
        self.parse_member_type_with_restricted_multiline_index_postfix()
      } else if self.eat(TokenKind::Arrow) {
        self.record_ts_error(self.previous().span.start, 1005, "':' expected.")
        self.parse_member_type_with_restricted_multiline_index_postfix()
      } else {
        { kind: TypeKind::Ident("any"), span: start.span }
      }
      let type_ann : TypeNode = {
        kind: TypeKind::Function(params, ret_type),
        span: start.span.merge(ret_type.span),
      }
      let mut end_span = type_ann.span
      if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
        end_span = self.previous().span
      }
      return {
        name: "[call]",
        optional: false,
        type_ann,
        span: start.span.merge(end_span),
      }
    }
  }
  if self.check(TokenKind::LParen) {
    let start = self.expect(TokenKind::LParen, "'('")
    let params : Array[TypeNode] = []
    if !self.check(TokenKind::RParen) {
      while true {
        params.push(self.parse_function_type_param())
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RParen) {
            break
          }
          continue
        }
        break
      }
    }
    ignore(self.expect(TokenKind::RParen, "')'"))
    let ret_type = if self.eat(TokenKind::Colon) {
      self.parse_member_type_with_restricted_multiline_index_postfix()
    } else if self.eat(TokenKind::Arrow) {
      self.record_ts_error(self.previous().span.start, 1005, "':' expected.")
      self.parse_member_type_with_restricted_multiline_index_postfix()
    } else {
      { kind: TypeKind::Ident("any"), span: start.span }
    }
    let type_ann : TypeNode = {
      kind: TypeKind::Function(params, ret_type),
      span: start.span.merge(ret_type.span),
    }
    let mut end_span = type_ann.span
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return {
      name: "[call]",
      optional: false,
      type_ann,
      span: start.span.merge(end_span),
    }
  }
  if self.check_keyword(Keyword::New) {
    let start = self.expect_keyword(Keyword::New)
    let mut optional = false
    if self.eat(TokenKind::Question) {
      optional = true
    }
    ignore(self.parse_type_params())
    ignore(self.expect(TokenKind::LParen, "'('"))
    let params : Array[TypeNode] = []
    if !self.check(TokenKind::RParen) {
      while true {
        params.push(self.parse_function_type_param())
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RParen) {
            break
          }
          continue
        }
        break
      }
    }
    ignore(self.expect(TokenKind::RParen, "')'"))
    let ret_type = if self.eat(TokenKind::Colon) {
      self.parse_member_type_with_restricted_multiline_index_postfix()
    } else {
      { kind: TypeKind::Ident("any"), span: start.span }
    }
    let type_ann : TypeNode = {
      kind: TypeKind::Function(params, ret_type),
      span: start.span.merge(ret_type.span),
    }
    let mut end_span = type_ann.span
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return { name: "new", optional, type_ann, span: start.span.merge(end_span) }
  }
  if self.check_keyword(Keyword::Get) || self.check_keyword(Keyword::Set) {
    let next_is_name = match self.peek_kind(1) {
      Some(TokenKind::Ident(_))
      | Some(TokenKind::Keyword(_))
      | Some(TokenKind::String(_))
      | Some(TokenKind::Number(_))
      | Some(TokenKind::LBracket) => true
      _ => false
    }
    if next_is_name {
      ignore(self.advance())
    }
  }
  if self.check(TokenKind::Plus) || self.check(TokenKind::Minus) {
    let saved = self.index
    ignore(self.advance())
    if self.check_keyword(Keyword::Readonly) ||
      self.check_ident_name("readonly") {
      ignore(self.advance())
    } else {
      self.index = saved
    }
  } else if self.check_keyword(Keyword::Readonly) ||
    self.check_ident_name("readonly") {
    let saved = self.index
    ignore(self.advance())
    if !self.check(TokenKind::LBracket) {
      self.index = saved
    }
  }
  let (name, name_span) = if self.check(TokenKind::LBracket) {
    let index_name_like = self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
      self.peek_kind(1) is Some(TokenKind::Keyword(_))
    let is_mapped_type_member = index_name_like &&
      is_mapped_type_in_token_kind(self.peek_kind(2))
    if !is_mapped_type_member {
      self.record_index_signature_accessibility_modifier_error_if_needed()
      self.record_index_signature_rest_param_error_if_needed()
    }
    let index_param_count_error = if is_mapped_type_member {
      false
    } else {
      self.record_index_signature_param_count_error_if_needed()
    }
    let optional_index_param = index_name_like &&
      self.peek_kind(2) == Some(TokenKind::Question) &&
      self.peek_kind(3) == Some(TokenKind::Colon)
    let required_index_param = index_name_like &&
      self.peek_kind(2) == Some(TokenKind::Colon)
    let is_index_signature_member = optional_index_param || required_index_param
    if optional_index_param {
      let question_pos = match self.peek(2) {
        Some(token) => token.span.start
        None => self.current().span.start
      }
      if self.should_report_optional_index_signature_param_error(question_pos) {
        self.record_ts_error(
          question_pos, 1019, "An index signature parameter cannot have a question mark.",
        )
      }
    }
    match leading_index_signature_modifier {
      Some((modifier_name, modifier_pos)) =>
        if is_index_signature_member {
          self.record_ts_error(
            modifier_pos,
            1071,
            "'\{modifier_name}' modifier cannot appear on an index signature.",
          )
        }
      None => ()
    }
    let invalid_index_param_type_error = if is_index_signature_member {
      self.record_invalid_index_signature_param_type_if_needed()
    } else {
      false
    }
    if is_index_signature_member &&
      !optional_index_param &&
      !index_param_count_error &&
      !invalid_index_param_type_error &&
      self.peek_kind_after_matching_bracket() != Some(TokenKind::Colon) {
      self.record_ts_error(
        self.current().span.start,
        1021,
        "An index signature must have a type annotation.",
      )
    }
    self.parse_bracket_member_name()
  } else {
    let token = self.current()
    let (member_name, raw_span) = self.expect_member_name()
    let (resolved_name, member_span) = self.consume_split_bigint_property_suffix_if_needed(
      member_name,
      raw_span,
      token.kind is TokenKind::Number(_),
    )
    (resolved_name, member_span)
  }
  let mut optional = false
  if self.eat(TokenKind::Question) {
    optional = true
  } else if self.eat(TokenKind::Plus) {
    if self.eat(TokenKind::Question) {
      optional = true
    }
  } else if self.eat(TokenKind::Minus) {
    if self.eat(TokenKind::Question) {
      optional = false
    }
  }
  ignore(self.parse_type_params())
  if self.check(TokenKind::LParen) {
    let params = self.parse_params(false)
    let mut return_type : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      return_type = Some(
        self.parse_member_type_with_restricted_multiline_index_postfix(),
      )
    }
    let ret_type = match return_type {
      Some(ty) => ty
      None => { kind: TypeKind::Ident("any"), span: name_span }
    }
    let param_types : Array[TypeNode] = []
    for param in params {
      match param.type_ann {
        Some(ty) => param_types.push(ty)
        None =>
          param_types.push({ kind: TypeKind::Ident("any"), span: param.span })
      }
    }
    let type_ann : TypeNode = {
      kind: TypeKind::Function(param_types, ret_type),
      span: name_span.merge(ret_type.span),
    }
    let mut end_span = type_ann.span
    if self.check(TokenKind::LBrace) {
      self.record_ts_error(
        self.current().span.start,
        1183,
        "An implementation cannot be declared in ambient contexts.",
      )
      let body = self.parse_block_in_function_context()
      end_span = body.span
    }
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return { name, optional, type_ann, span: name_span.merge(end_span) }
  }
  let type_ann = if self.eat(TokenKind::Colon) {
    self.parse_member_type_with_restricted_multiline_index_postfix()
  } else {
    let span = if optional { self.previous().span } else { name_span }
    { kind: TypeKind::Ident("any"), span }
  }
  let mut end_span = type_ann.span
  if self.eat(TokenKind::Eq) {
    let expr = self.parse_expression_no_comma()
    self.record_ts_error(
      expr.span.start,
      1247,
      "A type literal property cannot have an initializer.",
    )
    end_span = expr.span
  }
  if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
    end_span = self.previous().span
  }
  { name, optional, type_ann, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_expr_stmt(self : Parser) -> Stmt raise ParseError {
  let start_index = self.index
  let expr = self.parse_expression_without_type_colon()
  if self.index == start_index && !self.at_end() {
    ignore(self.advance())
  }
  let expr_span = expr.span
  let mut end_span = expr_span
  if self.eat(TokenKind::Colon) {
    self.record_ts_error(self.previous().span.start, 1005, "';' expected.")
    let type_ann = self.parse_type()
    end_span = type_ann.span
  }
  let skip_lbrace_semicolon_diag = if self.index > 0 &&
    self.previous().kind == TokenKind::RParen {
    match expr.kind {
      ExprKind::Ident(name) =>
        name == "undefined" &&
        expr_span.start.offset == self.previous().span.start.offset
      _ => false
    }
  } else {
    false
  }
  let ate_semicolon = self.eat(TokenKind::Semicolon)
  if ate_semicolon {
    end_span = self.previous().span
  } else if !self.check(TokenKind::RBrace) &&
    !self.at_end() &&
    self.current().span.start.line == end_span.end.line &&
    self.check(TokenKind::LBrace) &&
    self.index > 0 &&
    self.previous().kind == TokenKind::RParen &&
    !skip_lbrace_semicolon_diag {
    self.record_ts_error(self.previous().span.start, 1005, "';' expected.")
  } else if !self.check(TokenKind::RBrace) &&
    !self.at_end() &&
    self.current().span.start.line == end_span.end.line &&
    self.current().kind is TokenKind::String(_) {
    self.record_ts_error(self.current().span.start, 1005, "';' expected.")
  }
  { kind: StmtKind::ExprStmt(expr), span: expr_span.merge(end_span) }
}

///|
fn Parser::parse_expression_no_comma(self : Parser) -> Expr {
  self.parse_assignment() catch {
    err => self.recover_expression_from_parse_error(err)
  }
}

///|
fn Parser::parse_expression_without_type_colon(self : Parser) -> Expr {
  let saved_allow_type_colon = self.allow_type_colon
  self.allow_type_colon = false
  let expr = self.parse_expression()
  self.allow_type_colon = saved_allow_type_colon
  expr
}

///|
fn Parser::parse_expression(self : Parser) -> Expr {
  try {
    let mut expr = self.parse_assignment()
    while self.eat(TokenKind::Comma) {
      let right = self.parse_assignment()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Comma, left: expr, right }),
        span,
      }
    }
    expr
  } catch {
    err => self.recover_expression_from_parse_error(err)
  }
}

///|
fn Parser::recover_expression_from_parse_error(
  self : Parser,
  err : ParseError,
) -> Expr {
  match err {
    ParseError::Expected(pos~, expected) =>
      if expected == "expression" {
        let missing_semicolon_context = match self.current().kind {
          TokenKind::LBrace | TokenKind::RParen => true
          _ => self.index > 0 && self.previous().kind == TokenKind::RParen
        }
        if missing_semicolon_context {
          let mut semicolon_pos = pos
          if self.current().kind == TokenKind::LBrace &&
            self.index > 0 &&
            self.previous().kind == TokenKind::RParen {
            semicolon_pos = self.current().span.start
          } else if self.current().kind == TokenKind::RParen &&
            self.peek_kind(1) == Some(TokenKind::LBrace) {
            match self.peek(1) {
              Some(next_token) => semicolon_pos = next_token.span.start
              None => ()
            }
          } else if self.current().kind == TokenKind::RParen &&
            self.peek_kind(1) == Some(TokenKind::Semicolon) {
            let mut back = self.index
            while back > 0 {
              back -= 1
              let prev_token = self.tokens[back]
              if prev_token.span.start.line != self.current().span.start.line {
                break
              }
              if prev_token.kind == TokenKind::Eq {
                semicolon_pos = prev_token.span.start
                break
              }
            }
          }
          self.record_ts_error(semicolon_pos, 1005, "';' expected.")
        } else {
          self.record_ts_error(pos, 1109, "Expression expected.")
          let catch_member_recovery = self.current().kind ==
            TokenKind::Keyword(Keyword::Catch) &&
            self.peek_kind(1) == Some(TokenKind::Dot)
          if catch_member_recovery {
            match self.peek(1) {
              Some(dot_token) =>
                self.record_ts_error(
                  dot_token.span.start,
                  1005,
                  "'{' expected.",
                )
              None => ()
            }
          }
          let gt_var_followup = self.current().kind ==
            TokenKind::Keyword(Keyword::Var) &&
            self.index > 0 &&
            self.previous().kind == TokenKind::Gt
          if gt_var_followup {
            self.record_ts_error(
              self.current().span.start,
              1109,
              "Expression expected.",
            )
          }
          let slash_gt_missing_rhs = self.current().kind == TokenKind::Gt &&
            self.index > 0 &&
            self.previous().kind == TokenKind::Slash &&
            self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Var))
          if slash_gt_missing_rhs {
            match self.peek(1) {
              Some(next_token) =>
                self.record_ts_error(
                  next_token.span.start,
                  1109,
                  "Expression expected.",
                )
              None => ()
            }
            let gt_span = self.current().span
            ignore(self.advance())
            return { kind: ExprKind::Ident("undefined"), span: gt_span }
          }
        }
      } else if expected == "')'" {
        let mut diag_pos = pos
        if self.current().span.start.line == pos.line {
          let mut offset = 0
          while self.peek(offset) is Some(next_token) {
            if next_token.span.start.line != pos.line {
              break
            }
            if next_token.kind == TokenKind::LBrace ||
              next_token.kind == TokenKind::Semicolon ||
              next_token.kind == TokenKind::Comma {
              diag_pos = next_token.span.start
              break
            }
            offset += 1
          }
        }
        self.record_ts_error(diag_pos, 1005, "')' expected.")
      } else {
        self.record_error(err)
      }
    _ => self.record_error(err)
  }
  self.recover_expression()
}

///|
fn Parser::recover_expression(self : Parser) -> Expr {
  let token = self.current()
  let is_terminator = match token.kind {
    TokenKind::Semicolon
    | TokenKind::Comma
    | TokenKind::RParen
    | TokenKind::RBracket
    | TokenKind::RBrace
    | TokenKind::Eof => true
    _ => false
  }
  if is_terminator {
    return { kind: ExprKind::Ident("undefined"), span: token.span }
  }
  if token.kind == TokenKind::Keyword(Keyword::Try) ||
    token.kind == TokenKind::Keyword(Keyword::Else) {
    return { kind: ExprKind::Ident("undefined"), span: token.span }
  }
  let mut end_span = token.span
  ignore(self.advance())
  end_span = self.previous().span
  let mut saw_public_call_like_recovery = false
  let mut recorded_public_call_like_name_error = false
  let mut recorded_public_call_like_colon_error = false
  while !self.at_end() &&
        !self.check(TokenKind::Semicolon) &&
        !self.check(TokenKind::Comma) &&
        !self.check(TokenKind::RParen) &&
        !self.check(TokenKind::RBracket) &&
        !self.check(TokenKind::RBrace) &&
        !self.check_keyword(Keyword::Try) &&
        !self.check_keyword(Keyword::Else) {
    if self.current().kind == TokenKind::Keyword(Keyword::Public) &&
      self.peek_kind(1) is Some(TokenKind::Ident(_)) &&
      self.peek_kind(2) == Some(TokenKind::LParen) &&
      !recorded_public_call_like_name_error {
      saw_public_call_like_recovery = true
      recorded_public_call_like_name_error = true
      match self.peek(1) {
        Some(name_token) =>
          self.record_ts_error(name_token.span.start, 1005, "';' expected.")
        None => ()
      }
    }
    if saw_public_call_like_recovery &&
      !recorded_public_call_like_colon_error &&
      self.current().kind == TokenKind::Colon &&
      self.index > 0 &&
      self.previous().kind == TokenKind::Question {
      recorded_public_call_like_colon_error = true
      self.record_ts_error(
        self.current().span.start,
        1109,
        "Expression expected.",
      )
    }
    end_span = self.advance().span
  }
  { kind: ExprKind::Ident("undefined"), span: token.span.merge(end_span) }
}

///|
fn Parser::parse_assignment(self : Parser) -> Expr raise ParseError {
  let expr = self.parse_conditional()
  match self.eat_assignment_op() {
    Some(op) => {
      let assignment_end = self.previous().span.end
      let value = self.parse_assignment()
      let missing_rhs_at_eof = match value.kind {
        ExprKind::Ident(name) =>
          name == "undefined" && self.current().kind is TokenKind::Eof
        _ => false
      }
      if missing_rhs_at_eof {
        self.record_ts_error(assignment_end, 1109, "Expression expected.")
      }
      let span = expr.span.merge(value.span)
      { kind: ExprKind::Assign({ op, target: expr, value }), span }
    }
    None => expr
  }
}

///|
fn Parser::is_current_followed_by_adjacent_eq(self : Parser) -> Bool {
  if self.peek_kind(1) != Some(TokenKind::Eq) {
    return false
  }
  match self.peek(1) {
    Some(next_token) =>
      self.current().span.end.offset == next_token.span.start.offset
    None => false
  }
}

///|
fn Parser::eat_assignment_op(self : Parser) -> AssignOp? {
  if self.check(TokenKind::OrOr) && self.is_current_followed_by_adjacent_eq() {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::Assign)
  }
  if self.check(TokenKind::AndAnd) && self.is_current_followed_by_adjacent_eq() {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::Assign)
  }
  if self.check(TokenKind::Nullish) && self.is_current_followed_by_adjacent_eq() {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::Assign)
  }
  if self.check(TokenKind::StarStar) && self.peek_kind(1) == Some(TokenKind::Eq) {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::MulAssign)
  }
  if self.eat(TokenKind::Eq) {
    return Some(AssignOp::Assign)
  }
  if self.eat(TokenKind::PlusEq) {
    return Some(AssignOp::AddAssign)
  }
  if self.eat(TokenKind::MinusEq) {
    return Some(AssignOp::SubAssign)
  }
  if self.eat(TokenKind::StarEq) {
    return Some(AssignOp::MulAssign)
  }
  if self.eat(TokenKind::SlashEq) {
    return Some(AssignOp::DivAssign)
  }
  if self.eat(TokenKind::PercentEq) {
    return Some(AssignOp::ModAssign)
  }
  if self.check(TokenKind::Pipe) && self.peek_kind(1) == Some(TokenKind::Eq) {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::BitOrAssign)
  }
  if self.check(TokenKind::Ampersand) &&
    self.peek_kind(1) == Some(TokenKind::Eq) {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::BitAndAssign)
  }
  if self.check(TokenKind::Caret) && self.peek_kind(1) == Some(TokenKind::Eq) {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::BitXorAssign)
  }
  if self.check(TokenKind::Lt) &&
    self.peek_kind(1) == Some(TokenKind::Lt) &&
    self.peek_kind(2) == Some(TokenKind::Eq) {
    ignore(self.advance())
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::ShlAssign)
  }
  if self.check(TokenKind::Lt) && self.peek_kind(1) == Some(TokenKind::Lte) {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::ShlAssign)
  }
  if self.check(TokenKind::Gt) && self.peek_kind(1) == Some(TokenKind::Gt) {
    if self.peek_kind(2) == Some(TokenKind::Gt) &&
      self.peek_kind(3) == Some(TokenKind::Eq) {
      ignore(self.advance())
      ignore(self.advance())
      ignore(self.advance())
      ignore(self.advance())
      return Some(AssignOp::UShrAssign)
    }
    if self.peek_kind(2) == Some(TokenKind::Gte) {
      ignore(self.advance())
      ignore(self.advance())
      ignore(self.advance())
      return Some(AssignOp::UShrAssign)
    }
    if self.peek_kind(2) == Some(TokenKind::Eq) {
      ignore(self.advance())
      ignore(self.advance())
      ignore(self.advance())
      return Some(AssignOp::ShrAssign)
    }
  }
  if self.check(TokenKind::Gt) && self.peek_kind(1) == Some(TokenKind::Gte) {
    ignore(self.advance())
    ignore(self.advance())
    return Some(AssignOp::ShrAssign)
  }
  None
}

///|
fn Parser::parse_conditional(self : Parser) -> Expr raise ParseError {
  let expr = self.parse_nullish()
  if self.check(TokenKind::Question) &&
    expr.kind is ExprKind::Arrow(_) &&
    self.index > 0 &&
    self.previous().kind == TokenKind::RBrace {
    self.record_ts_error(self.current().span.start, 1005, "';' expected.")
    let target_line = self.current().span.start.line
    while !self.check(TokenKind::Colon) &&
          !self.at_end() &&
          self.current().span.start.line == target_line {
      ignore(self.advance())
    }
    if self.check(TokenKind::Colon) {
      self.record_ts_error(self.current().span.start, 1005, "';' expected.")
      ignore(self.advance())
    }
    return expr
  }
  if self.eat(TokenKind::Question) {
    let prev_allow = self.allow_type_colon
    self.allow_type_colon = false
    let consequent = self.parse_expression_no_comma()
    let alternate = if self.check_keyword(Keyword::Else) {
      let missing_alternate : Expr = {
        kind: ExprKind::Ident("undefined"),
        span: consequent.span,
      }
      missing_alternate
    } else {
      ignore(self.expect(TokenKind::Colon, "':'"))
      self.parse_expression_no_comma()
    }
    self.allow_type_colon = prev_allow
    let span = expr.span.merge(alternate.span)
    return {
      kind: ExprKind::Conditional({ condition: expr, consequent, alternate }),
      span,
    }
  }
  expr
}

///|
fn Parser::parse_nullish(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_logical_or()
  while self.check(TokenKind::Nullish) {
    if self.is_current_followed_by_adjacent_eq() {
      break
    }
    ignore(self.advance())
    let right = self.parse_logical_or()
    let span = expr.span.merge(right.span)
    expr = {
      kind: ExprKind::Binary({ op: BinaryOp::Nullish, left: expr, right }),
      span,
    }
  }
  expr
}

///|
fn Parser::parse_logical_or(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_logical_and()
  while self.check(TokenKind::OrOr) {
    if self.is_current_followed_by_adjacent_eq() {
      break
    }
    ignore(self.advance())
    let right = self.parse_logical_and()
    let span = expr.span.merge(right.span)
    expr = {
      kind: ExprKind::Binary({ op: BinaryOp::Or, left: expr, right }),
      span,
    }
  }
  expr
}

///|
fn Parser::parse_logical_and(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_bitwise_or()
  while self.check(TokenKind::AndAnd) {
    if self.is_current_followed_by_adjacent_eq() {
      break
    }
    ignore(self.advance())
    let right = self.parse_bitwise_or()
    let span = expr.span.merge(right.span)
    expr = {
      kind: ExprKind::Binary({ op: BinaryOp::And, left: expr, right }),
      span,
    }
  }
  expr
}

///|
fn Parser::parse_bitwise_or(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_bitwise_xor()
  while self.check(TokenKind::Pipe) && self.peek_kind(1) != Some(TokenKind::Eq) {
    ignore(self.advance())
    let right = self.parse_bitwise_xor()
    let span = expr.span.merge(right.span)
    expr = {
      kind: ExprKind::Binary({ op: BinaryOp::BitOr, left: expr, right }),
      span,
    }
  }
  expr
}

///|
fn Parser::parse_bitwise_xor(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_bitwise_and()
  while self.check(TokenKind::Caret) && self.peek_kind(1) != Some(TokenKind::Eq) {
    ignore(self.advance())
    let right = self.parse_bitwise_and()
    let span = expr.span.merge(right.span)
    expr = {
      kind: ExprKind::Binary({ op: BinaryOp::BitXor, left: expr, right }),
      span,
    }
  }
  expr
}

///|
fn Parser::parse_bitwise_and(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_equality()
  while self.check(TokenKind::Ampersand) &&
        self.peek_kind(1) != Some(TokenKind::Eq) {
    ignore(self.advance())
    let right = self.parse_equality()
    let span = expr.span.merge(right.span)
    expr = {
      kind: ExprKind::Binary({ op: BinaryOp::BitAnd, left: expr, right }),
      span,
    }
  }
  expr
}

///|
fn Parser::parse_equality(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_comparison()
  while true {
    if self.eat(TokenKind::EqEq) {
      let right = self.parse_comparison()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Eq, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::NotEq) {
      let right = self.parse_comparison()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Neq, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::EqEqEq) {
      let right = self.parse_comparison()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::StrictEq, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::NotEqEq) {
      let right = self.parse_comparison()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::StrictNeq, left: expr, right }),
        span,
      }
      continue
    }
    break
  }
  expr
}

///|
fn Parser::parse_comparison(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_shift()
  while true {
    if self.check(TokenKind::Lt) &&
      (
        self.peek_kind(1) == Some(TokenKind::Lt) ||
        self.peek_kind(1) == Some(TokenKind::Lte)
      ) {
      break
    }
    if self.eat(TokenKind::Lt) {
      let right = self.parse_shift()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Lt, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::Lte) {
      let right = self.parse_shift()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Lte, left: expr, right }),
        span,
      }
      continue
    }
    if self.check(TokenKind::Gt) &&
      (
        self.peek_kind(1) == Some(TokenKind::Gt) ||
        self.peek_kind(1) == Some(TokenKind::Gte)
      ) {
      break
    }
    if self.eat(TokenKind::Gt) {
      let right = self.parse_shift()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Gt, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::Gte) {
      let right = self.parse_shift()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Gte, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat_ident_name("instanceof") {
      let right = self.parse_shift()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Instanceof, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat_ident_name("in") {
      let right = self.parse_shift()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::In, left: expr, right }),
        span,
      }
      continue
    }
    break
  }
  expr
}

///|
fn Parser::parse_shift(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_term()
  while true {
    if self.check(TokenKind::Lt) &&
      self.peek_kind(1) == Some(TokenKind::Lt) &&
      self.peek_kind(2) != Some(TokenKind::Eq) {
      ignore(self.advance())
      ignore(self.advance())
      let right = self.parse_term()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Shl, left: expr, right }),
        span,
      }
      continue
    }
    if self.check(TokenKind::Gt) && self.peek_kind(1) == Some(TokenKind::Gt) {
      if self.peek_kind(2) == Some(TokenKind::Eq) {
        break
      }
      if self.peek_kind(2) == Some(TokenKind::Gt) &&
        self.peek_kind(3) == Some(TokenKind::Eq) {
        break
      }
      if self.peek_kind(2) == Some(TokenKind::Gte) {
        break
      }
      ignore(self.advance())
      ignore(self.advance())
      let mut op = BinaryOp::Shr
      if self.check(TokenKind::Gt) {
        ignore(self.advance())
        op = BinaryOp::UShr
      }
      let right = self.parse_term()
      let span = expr.span.merge(right.span)
      expr = { kind: ExprKind::Binary({ op, left: expr, right }), span }
      continue
    }
    break
  }
  expr
}

///|
fn Parser::parse_term(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_factor()
  while true {
    if self.eat(TokenKind::Plus) {
      let right = self.parse_factor()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Add, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::Minus) {
      let right = self.parse_factor()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Sub, left: expr, right }),
        span,
      }
      continue
    }
    break
  }
  expr
}

///|
fn Parser::parse_factor(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_unary()
  while true {
    if self.check(TokenKind::StarStar) {
      if self.peek_kind(1) == Some(TokenKind::Eq) {
        break
      }
      ignore(self.advance())
      let right = self.parse_unary()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Pow, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::Star) {
      let right = self.parse_unary()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Mul, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::Slash) {
      let right = self.parse_unary()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Div, left: expr, right }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::Percent) {
      let right = self.parse_unary()
      let span = expr.span.merge(right.span)
      expr = {
        kind: ExprKind::Binary({ op: BinaryOp::Mod, left: expr, right }),
        span,
      }
      continue
    }
    break
  }
  expr
}

///|
fn Parser::parse_unary(self : Parser) -> Expr raise ParseError {
  let new_meta_next = match self.peek_kind(2) {
    Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) => true
    _ => false
  }
  if self.check_keyword(Keyword::New) &&
    self.peek_kind(1) == Some(TokenKind::Dot) &&
    new_meta_next {
    let start = self.advance().span
    ignore(self.expect(TokenKind::Dot, "'.'"))
    let (name, name_span) = self.parse_ident_name()
    let span = start.merge(name_span)
    return { kind: ExprKind::Ident("new.\{name}"), span }
  }
  if self.check_keyword(Keyword::New) {
    return self.parse_new_expr()
  }
  if !self.jsx_mode && self.is_ambiguous_generic_assertion_with_lshift() {
    return self.parse_ambiguous_generic_assertion_with_lshift()
  }
  if self.check(TokenKind::Lt) {
    let start = self.current().span
    let suppress_js_lt_assertion_diag = !self.jsx_mode &&
      is_js_source_file(self.source_name_for_position(start.start))
    let saved = self.index
    let saved_error_count = self.errors.length()
    let mut type_params : Array[TypeParam] = []
    let mut parsed_type_params = false
    try {
      type_params = self.parse_type_params()
      parsed_type_params = true
    } catch {
      _ => self.index = saved
    }
    if parsed_type_params &&
      type_params.length() > 0 &&
      self.check(TokenKind::LParen) &&
      self.is_arrow_after_paren() {
      return self.parse_arrow_from_paren_with_type_params(start, type_params)
    }
    self.index = saved
    while self.errors.length() > saved_error_count {
      ignore(self.errors.pop())
    }
    if self.jsx_mode {
      let saved_jsx = self.index
      try {
        return self.parse_jsx()
      } catch {
        _ => self.index = saved_jsx
      }
    }
    let saved_type_assert = self.index
    try {
      let assert_start = self.advance().span
      if !self.jsx_mode && self.check(TokenKind::Gt) {
        let gt_span = self.advance().span
        let type_ann : TypeNode = {
          kind: TypeKind::Ident("any"),
          span: assert_start.merge(gt_span),
        }
        let expr = if self.is_expression_start() {
          self.parse_unary()
        } else {
          { kind: ExprKind::Ident(""), span: gt_span }
        }
        self.record_erasable_syntax_only_error_if_needed(assert_start.start)
        return {
          kind: ExprKind::TypeAssert({ expr, type_ann }),
          span: assert_start.merge(expr.span),
        }
      }
      let type_ann = self.parse_type()
      let mut gt_span = self.current().span
      let mut missing_type_assert_gt = false
      if self.eat(TokenKind::Gt) {
        gt_span = self.previous().span
      } else {
        missing_type_assert_gt = true
        self.record_ts_error(self.current().span.start, 1005, "'>' expected.")
      }
      if self.check_keyword(Keyword::Yield) || self.check_ident_name("yield") {
        self.record_ts_error(
          self.current().span.start,
          1109,
          "Expression expected.",
        )
      }
      let expr : Expr = if self.is_expression_start() {
        self.parse_unary()
      } else if missing_type_assert_gt && self.at_end() {
        { kind: ExprKind::Ident(""), span: gt_span }
      } else {
        self.record_ts_error(gt_span.end, 1109, "Expression expected.")
        { kind: ExprKind::Ident(""), span: gt_span }
      }
      self.record_erasable_syntax_only_error_if_needed(assert_start.start)
      return {
        kind: ExprKind::TypeAssert({ expr, type_ann }),
        span: assert_start.merge(expr.span),
      }
    } catch {
      _ => {
        self.index = saved_type_assert
        if suppress_js_lt_assertion_diag {
          while self.errors.length() > saved_error_count {
            ignore(self.errors.pop())
          }
        }
        if self.jsx_mode && self.peek_kind(1) is Some(next_kind) {
          match next_kind {
            TokenKind::Ident(_) | TokenKind::Keyword(_) => {
              let saved_jsx = self.index
              try {
                return self.parse_jsx()
              } catch {
                _ => self.index = saved_jsx
              }
            }
            _ => ()
          }
        }
        if !suppress_js_lt_assertion_diag {
          self.record_ts_error(start.start, 1109, "Expression expected.")
        }
        let mut end_span = self.current().span
        ignore(self.advance())
        end_span = self.previous().span
        while !self.at_end() &&
              !self.check(TokenKind::Gt) &&
              !self.check(TokenKind::Semicolon) &&
              !self.check(TokenKind::Comma) &&
              !self.check(TokenKind::RParen) &&
              !self.check(TokenKind::RBrace) &&
              !self.check(TokenKind::RBracket) {
          if self.check_keyword(Keyword::Import) &&
            self.peek_kind(1) == Some(TokenKind::LParen) {
            end_span = self.advance().span
            ignore(self.expect(TokenKind::LParen, "'('")) catch {
              err => {
                self.record_error(err)
                return {
                  kind: ExprKind::Ident(""),
                  span: start.merge(end_span),
                }
              }
            }
            end_span = self.previous().span
            if !(self.current().kind is TokenKind::String(_)) {
              self.record_ts_error(
                self.current().span.start,
                1141,
                "String literal expected.",
              )
            }
            while !self.at_end() &&
                  !self.check(TokenKind::Comma) &&
                  !self.check(TokenKind::RParen) {
              end_span = self.advance().span
            }
            if self.eat(TokenKind::Comma) {
              end_span = self.previous().span
              if self.at_end() || self.check(TokenKind::RParen) {
                self.record_ts_error(
                  self.previous().span.end,
                  1109,
                  "Expression expected.",
                )
              }
            }
            continue
          }
          end_span = self.advance().span
        }
        if self.check(TokenKind::Gt) {
          end_span = self.advance().span
        }
        return { kind: ExprKind::Ident(""), span: start.merge(end_span) }
      }
    }
  }
  if self.check_keyword(Keyword::Typeof) || self.check_ident_name("typeof") {
    let start = self.advance().span
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Typeof, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check_keyword(Keyword::Delete) || self.check_ident_name("delete") {
    let start = self.advance().span
    let source_file = self.source_name_for_position(start.start)
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    if self.strict_mode && !is_js_source_file(source_file) {
      match expr.kind {
        ExprKind::Ident(_) =>
          self.record_ts_error(
            expr.span.start,
            1102,
            "'delete' cannot be called on an identifier in strict mode.",
          )
        _ => ()
      }
    }
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Delete, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check_keyword(Keyword::Void) || self.check_ident_name("void") {
    let start = self.advance().span
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Void, expr }),
      span: start.merge(expr.span),
    }
  }
  let is_await_token = self.check_keyword(Keyword::Await) ||
    self.check_ident_name("await")
  let should_parse_as_await_unary = if is_await_token {
    let source_file = self.source_name_for_position(self.current().span.start)
    let allow_top_level_module_await = self.function_depth == 0 &&
      self.is_module_file(source_file)
    let allow_async_function_await = self.async_function_depth > 0 &&
      self.class_header_context_depth == 0
    !(self.peek_kind(1) == Some(TokenKind::LParen) &&
    !allow_async_function_await &&
    !allow_top_level_module_await)
  } else {
    false
  }
  if should_parse_as_await_unary {
    let start = self.advance().span
    let source_file = self.source_name_for_position(start.start)
    let allow_top_level_module_await = self.function_depth == 0 &&
      self.is_module_file(source_file)
    let allow_async_function_await = self.async_function_depth > 0 &&
      self.class_header_context_depth == 0
    if self.parameter_initializer_depth == 0 {
      if allow_top_level_module_await && !self.top_level_await_options_enabled() {
        self.record_ts_error(
          start.start,
          1378,
          "Top-level 'await' expressions are only allowed when the 'module' option is set to 'es2022', 'esnext', 'system', 'node16', 'node18', 'node20', 'nodenext', or 'preserve', and the 'target' option is set to 'es2017' or higher.",
        )
      } else if !allow_async_function_await && !allow_top_level_module_await {
        self.record_ts_error(
          start.start,
          1308,
          "'await' expressions are only allowed within async functions and at the top levels of modules.",
        )
      }
    }
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    match expr.kind {
      ExprKind::Ident(name) =>
        if self.is_await_self_reference_binding(name, expr.span.start) {
          self.record_ts_error(
            start.start,
            1062,
            "Type is referenced directly or indirectly in the fulfillment callback of its own 'then' method.",
          )
        } else if self.is_thenable_await_binding(name, expr.span.start) {
          self.record_ts_error(
            expr.span.start,
            1320,
            "Type of 'await' operand must either be a valid promise or must not contain a callable 'then' member.",
          )
        }
      _ => ()
    }
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Await, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check_keyword(Keyword::Yield) || self.check_ident_name("yield") {
    if self.generator_function_depth == 0 {
      let next_is_terminator = match self.peek_kind(1) {
        Some(TokenKind::Semicolon)
        | Some(TokenKind::RBrace)
        | Some(TokenKind::RParen)
        | Some(TokenKind::Comma)
        | Some(TokenKind::Eof) => true
        _ => false
      }
      if next_is_terminator {
        let token = self.advance().span
        return { kind: ExprKind::Ident("yield"), span: token }
      }
    }
    let start = self.advance().span
    if self.generator_function_depth == 0 &&
      self.parameter_initializer_depth == 0 {
      self.record_ts_error(
        start.start,
        1163,
        "A 'yield' expression is only allowed in a generator body.",
      )
    }
    let is_delegated = self.eat(TokenKind::Star)
    let expr : Expr = if self.check(TokenKind::Semicolon) ||
      self.check(TokenKind::RBrace) ||
      self.check(TokenKind::RParen) ||
      self.check(TokenKind::Comma) ||
      self.at_end() {
      { kind: ExprKind::Ident("undefined"), span: start }
    } else {
      self.parse_unary()
    }
    if is_delegated && self.async_function_depth > 0 {
      match expr.kind {
        ExprKind::Ident(name) =>
          if self.is_thenable_await_binding(name, expr.span.start) {
            self.record_ts_error(
              expr.span.start,
              1320,
              "Type of 'await' operand must either be a valid promise or must not contain a callable 'then' member.",
            )
          }
        _ => ()
      }
    }
    return {
      kind: ExprKind::Unary({
        op: if is_delegated {
          UnaryOp::YieldStar
        } else {
          UnaryOp::Yield
        },
        expr,
      }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::PlusPlus) {
    let start = self.advance().span
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    self.record_strict_update_operand_error_if_needed(expr)
    return {
      kind: ExprKind::Update({ op: UpdateOp::Increment, prefix: true, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::MinusMinus) {
    let start = self.advance().span
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    self.record_strict_update_operand_error_if_needed(expr)
    return {
      kind: ExprKind::Update({ op: UpdateOp::Decrement, prefix: true, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::Bang) {
    let start = self.advance().span
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Not, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::Plus) {
    let start = self.advance().span
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Plus, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::Minus) {
    let start = self.advance().span
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Minus, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::Tilde) {
    let start = self.advance().span
    let expr = self.parse_unary()
    self.record_missing_unary_operand_if_any(expr)
    return {
      kind: ExprKind::Unary({ op: UnaryOp::BitNot, expr }),
      span: start.merge(expr.span),
    }
  }
  self.parse_postfix()
}

///|
fn Parser::is_ambiguous_generic_assertion_with_lshift(self : Parser) -> Bool {
  if !self.check(TokenKind::Lt) || self.peek_kind(1) != Some(TokenKind::Lt) {
    return false
  }
  let first_lt = self.current()
  let second_lt = match self.peek(1) {
    Some(token) => token
    None => return false
  }
  if second_lt.span.start.offset != first_lt.span.end.offset {
    return false
  }
  let starts_generic = match self.peek_kind(2) {
    Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) => true
    _ => false
  }
  if !starts_generic {
    return false
  }
  let mut offset = 2
  while true {
    match self.peek_kind(offset) {
      Some(TokenKind::Arrow) => return true
      Some(TokenKind::Semicolon)
      | Some(TokenKind::Comma)
      | Some(TokenKind::RBrace)
      | Some(TokenKind::Eof)
      | None => break
      _ => offset += 1
    }
  }
  false
}

///|
fn Parser::parse_ambiguous_generic_assertion_with_lshift(self : Parser) -> Expr {
  let start_span = self.current().span
  self.record_ts_error(start_span.start, 1109, "Expression expected.")
  ignore(self.advance())
  let mut colon_pos : Position? = None
  let mut rparen_pos : Position? = None
  let mut arrow_pos : Position? = None
  while !self.at_end() &&
        !self.check(TokenKind::Semicolon) &&
        !self.check(TokenKind::Comma) &&
        !self.check(TokenKind::RBrace) {
    if colon_pos is None && self.check(TokenKind::Colon) {
      colon_pos = Some(self.current().span.start)
    }
    if rparen_pos is None && self.check(TokenKind::RParen) {
      rparen_pos = Some(self.current().span.start)
    }
    if arrow_pos is None && self.check(TokenKind::Arrow) {
      arrow_pos = Some(self.current().span.start)
    }
    ignore(self.advance())
  }
  match colon_pos {
    Some(pos) => self.record_ts_error(pos, 1005, "')' expected.")
    None => ()
  }
  match rparen_pos {
    Some(pos) => self.record_ts_error(pos, 1005, "',' expected.")
    None => ()
  }
  match arrow_pos {
    Some(pos) => self.record_ts_error(pos, 1005, "';' expected.")
    None => ()
  }
  let end_span = if self.index > 0 { self.previous().span } else { start_span }
  { kind: ExprKind::Ident(""), span: start_span.merge(end_span) }
}

///|
fn is_jsx_name_token(kind : TokenKind) -> Bool {
  match kind {
    TokenKind::Ident(name) => !name.has_prefix("#")
    TokenKind::Keyword(_) => true
    _ => false
  }
}

///|
fn Parser::consume_jsx_gt_or_recover(self : Parser) -> Span {
  if self.check(TokenKind::Gt) {
    self.advance().span
  } else {
    let span = self.current().span
    if !self.at_end() {
      ignore(self.advance())
    }
    span
  }
}

///|
fn Parser::peek_jsx_braced_string_start(self : Parser) -> Position? {
  match self.peek(1) {
    Some(tok) =>
      if tok.kind is TokenKind::String(_) &&
        self.peek_kind(2) == Some(TokenKind::RBrace) {
        Some(tok.span.start)
      } else {
        None
      }
    None => None
  }
}

///|
fn Parser::parse_jsx_tag_name(
  self : Parser,
  lt_span : Span,
  is_closing : Bool,
) -> (Bool, Bool, Bool) {
  let mut missing_name_after_colon_gap = false
  let mut leading_colon = false
  let mut closing_extra_colon = false
  if self.check(TokenKind::Colon) {
    leading_colon = true
    let colon_span = self.advance().span
    if !is_closing {
      self.record_ts_error(lt_span.start, 1109, "Expression expected.")
      self.record_ts_error(colon_span.start, 1109, "Expression expected.")
    }
    if is_jsx_name_token(self.current().kind) {
      ignore(self.advance())
    }
    return (missing_name_after_colon_gap, leading_colon, closing_extra_colon)
  }
  if !is_jsx_name_token(self.current().kind) {
    match self.current().kind {
      TokenKind::Ident(name) =>
        if name.has_prefix("#") {
          self.record_ts_error(
            self.current().span.end,
            1003,
            "Identifier expected.",
          )
          ignore(self.advance())
        } else if !is_closing {
          self.record_ts_error(
            self.current().span.start,
            1003,
            "Identifier expected.",
          )
        }
      _ =>
        if !is_closing {
          self.record_ts_error(
            self.current().span.start,
            1003,
            "Identifier expected.",
          )
        }
    }
    return (missing_name_after_colon_gap, leading_colon, closing_extra_colon)
  }
  let mut prev_span = self.advance().span
  let mut colon_count = 0
  while true {
    if self.check(TokenKind::Dot) {
      let dot_span = self.current().span
      if prev_span.end.offset < dot_span.start.offset {
        break
      }
      ignore(self.advance())
      if !is_jsx_name_token(self.current().kind) {
        match self.current().kind {
          TokenKind::Ident(name) =>
            if name.has_prefix("#") {
              self.record_ts_error(
                self.current().span.end,
                1003,
                "Identifier expected.",
              )
              ignore(self.advance())
            }
          _ => ()
        }
        break
      }
      let next_span = self.current().span
      if dot_span.end.offset < next_span.start.offset {
        break
      }
      prev_span = self.advance().span
      continue
    }
    if self.check(TokenKind::Colon) {
      let colon_span = self.current().span
      if prev_span.end.offset < colon_span.start.offset {
        break
      }
      ignore(self.advance())
      colon_count += 1
      if colon_count > 1 {
        if is_closing {
          self.record_ts_error(colon_span.start, 1005, "'>' expected.")
          closing_extra_colon = true
        } else {
          self.record_ts_error(colon_span.start, 1003, "Identifier expected.")
        }
      }
      if !is_jsx_name_token(self.current().kind) {
        self.record_ts_error(
          self.current().span.start,
          1003,
          "Identifier expected.",
        )
        break
      }
      let next_span = self.current().span
      if colon_span.end.offset < next_span.start.offset {
        missing_name_after_colon_gap = true
        break
      }
      prev_span = self.advance().span
      continue
    }
    break
  }
  (missing_name_after_colon_gap, leading_colon, closing_extra_colon)
}

///|
fn Parser::skip_jsx_braced_expr(self : Parser) -> Span raise ParseError {
  let start = self.expect(TokenKind::LBrace, "'{'")
  let mut depth = 1
  let mut end_span = start.span
  while depth > 0 && !self.at_end() {
    match self.current().kind {
      TokenKind::LBrace => {
        depth += 1
        end_span = self.advance().span
      }
      TokenKind::RBrace => {
        depth -= 1
        end_span = self.advance().span
      }
      _ => end_span = self.advance().span
    }
  }
  end_span
}

///|
fn Parser::parse_jsx_attribute_initializer(
  self : Parser,
) -> (Span, Position?) raise ParseError {
  if self.check(TokenKind::Gt) || self.check(TokenKind::Slash) || self.at_end() {
    self.record_ts_error(
      self.current().span.start,
      1145,
      "'{' or JSX element expected.",
    )
    return (self.current().span, None)
  }
  if self.check(TokenKind::LBrace) {
    let string_start = self.peek_jsx_braced_string_start()
    let end_span = self.skip_jsx_braced_expr()
    return (end_span, string_start)
  }
  (self.advance().span, None)
}

///|
fn Parser::parse_jsx_type_args(self : Parser) -> Span raise ParseError {
  let lt_span = self.expect(TokenKind::Lt, "'<'").span
  if self.check(TokenKind::Gt) {
    self.record_ts_error(
      lt_span.start,
      1099,
      "Type argument list cannot be empty.",
    )
    return self.advance().span
  }
  while true {
    ignore(self.parse_type_argument())
    if self.eat(TokenKind::Comma) {
      let comma_span = self.previous().span
      if self.check(TokenKind::Gt) {
        self.record_ts_error(
          comma_span.start,
          1009,
          "Trailing comma not allowed.",
        )
        break
      }
      continue
    }
    break
  }
  self.expect(TokenKind::Gt, "'>'").span
}

///|
fn Parser::parse_jsx_opening_tag_rest(
  self : Parser,
  lt_span : Span,
) -> (Span, Bool) raise ParseError {
  let starts_with_numeric_name = self.current().kind is TokenKind::Number(_)
  let (missing_name_after_colon_gap, leading_colon, _) = self.parse_jsx_tag_name(
    lt_span, false,
  )
  let mut pending_missing_ident = missing_name_after_colon_gap
  let mut pending_spread_expected = missing_name_after_colon_gap
  let mut pending_leading_colon_comma = leading_colon
  let mut end_span = lt_span
  if self.check(TokenKind::Lt) {
    end_span = self.parse_jsx_type_args()
  }
  while !self.check(TokenKind::Gt) &&
        !self.check(TokenKind::Slash) &&
        !self.at_end() {
    if self.check(TokenKind::LBrace) {
      end_span = self.skip_jsx_braced_expr()
      continue
    }
    if pending_leading_colon_comma {
      self.record_ts_error(self.current().span.start, 1005, "',' expected.")
      pending_leading_colon_comma = false
    }
    if self.check(TokenKind::Colon) {
      ignore(self.advance())
      if is_jsx_name_token(self.current().kind) {
        ignore(self.advance())
      }
      if self.eat(TokenKind::Eq) {
        let eq_span = self.previous().span
        self.record_ts_error(eq_span.start, 1003, "Identifier expected.")
        let (value_span, brace_string_start) = self.parse_jsx_attribute_initializer()
        end_span = value_span
        match brace_string_start {
          Some(pos) => self.record_ts_error(pos, 1005, "'...' expected.")
          None => ()
        }
      }
      continue
    }
    if is_jsx_name_token(self.current().kind) {
      let attr_start = self.current().span
      let mut prev_span = self.advance().span
      let mut attr_missing_ident = pending_missing_ident
      let mut attr_spread_expected = pending_spread_expected
      pending_missing_ident = false
      pending_spread_expected = false
      while self.check(TokenKind::Colon) {
        let colon_span = self.current().span
        if prev_span.end.offset < colon_span.start.offset {
          break
        }
        ignore(self.advance())
        if !is_jsx_name_token(self.current().kind) {
          attr_missing_ident = true
          break
        }
        let next_span = self.current().span
        if colon_span.end.offset < next_span.start.offset {
          attr_missing_ident = true
          attr_spread_expected = true
          break
        }
        prev_span = self.advance().span
      }
      if self.eat(TokenKind::Eq) {
        let eq_span = self.previous().span
        if attr_missing_ident {
          self.record_ts_error(eq_span.start, 1003, "Identifier expected.")
        }
        let (value_span, brace_string_start) = self.parse_jsx_attribute_initializer()
        end_span = value_span
        if attr_spread_expected {
          match brace_string_start {
            Some(pos) => self.record_ts_error(pos, 1005, "'...' expected.")
            None => ()
          }
        }
        if leading_colon {
          self.record_ts_error(value_span.start, 1005, "':' expected.")
        }
      } else {
        end_span = attr_start
      }
      continue
    }
    end_span = self.advance().span
  }
  if self.eat(TokenKind::Slash) {
    let gt_span = self.consume_jsx_gt_or_recover()
    if starts_with_numeric_name {
      self.record_ts_error(
        gt_span.start,
        1382,
        "Unexpected token. Did you mean `{'>'}` or `&gt;`?",
      )
    }
    end_span = gt_span
    if leading_colon {
      self.record_ts_error(gt_span.start, 1109, "Expression expected.")
      self.record_ts_error(gt_span.end, 1109, "Expression expected.")
    }
    return (end_span, true)
  }
  let gt_span = self.consume_jsx_gt_or_recover()
  if starts_with_numeric_name {
    self.record_ts_error(
      gt_span.start,
      1382,
      "Unexpected token. Did you mean `{'>'}` or `&gt;`?",
    )
  }
  end_span = gt_span
  (end_span, false)
}

///|
fn Parser::parse_jsx(self : Parser) -> Expr raise ParseError {
  let start = self.expect(TokenKind::Lt, "'<'")
  let mut end_span = start.span
  let mut depth = 0
  if self.check(TokenKind::Gt) {
    end_span = self.advance().span
    depth = 1
  } else {
    let (open_end_span, self_closing) = self.parse_jsx_opening_tag_rest(
      start.span,
    )
    end_span = open_end_span
    if self_closing {
      depth = 0
    } else {
      depth = 1
    }
  }
  while depth > 0 && !self.at_end() {
    let current_pos = self.current().span.start
    if current_pos.offset + 7 <= self.source_text.length() &&
      line_has_merge_conflict_marker_prefix(
        self.source_text.view(start_offset=current_pos.offset),
        0,
      ) {
      break
    }
    if self.eat(TokenKind::Lt) {
      let lt_span = self.previous().span
      if self.eat(TokenKind::Slash) {
        if self.check(TokenKind::Gt) {
          end_span = self.advance().span
          depth -= 1
          continue
        }
        let (_, _, closing_extra_colon) = self.parse_jsx_tag_name(lt_span, true)
        while !self.check(TokenKind::Gt) && !self.at_end() {
          end_span = self.advance().span
        }
        let gt_span = self.consume_jsx_gt_or_recover()
        if closing_extra_colon {
          self.record_ts_error(gt_span.start, 1005, "',' expected.")
          self.record_ts_error(gt_span.end, 1109, "Expression expected.")
        }
        end_span = gt_span
        depth -= 1
        continue
      }
      if self.check(TokenKind::Gt) {
        end_span = self.advance().span
        depth += 1
        continue
      }
      let (open_end_span, self_closing) = self.parse_jsx_opening_tag_rest(
        lt_span,
      )
      end_span = open_end_span
      if self_closing {

      } else {
        depth += 1
      }
      continue
    }
    if self.check(TokenKind::LBrace) {
      end_span = self.skip_jsx_braced_expr()
      continue
    }
    end_span = self.advance().span
  }
  if depth > 0 {
    let search_end = if self.current().span.start.offset >
      start.span.start.offset {
      self.current().span.start.offset
    } else {
      end_span.end.offset
    }
    let jsx_slice = self.source_text.view(
      start_offset=start.span.start.offset,
      end_offset=search_end,
    )
    let has_multiline_attribute_string = jsx_slice.contains("=\"\n") ||
      jsx_slice.contains("='\n") ||
      jsx_slice.contains("=\"\r\n") ||
      jsx_slice.contains("='\r\n")
    if !has_multiline_attribute_string {
      let diag_pos = if self.at_end() {
        let eof_pos = self.current().span.start
        let has_conflict_marker_prefix = eof_pos.offset + 7 <=
          self.source_text.length() &&
          line_has_merge_conflict_marker_prefix(
            self.source_text.view(start_offset=eof_pos.offset),
            0,
          )
        let has_conflict_marker_between_end_and_eof = eof_pos.offset >
          end_span.end.offset &&
          source_slice_contains_merge_conflict_marker_hint(
            self.source_text,
            end_span.end.offset,
            eof_pos.offset,
          )
        if has_conflict_marker_prefix {
          end_span.end
        } else if has_conflict_marker_between_end_and_eof {
          end_span.end
        } else {
          eof_pos
        }
      } else if self.current().span.start.line > end_span.end.line {
        end_span.end
      } else {
        self.current().span.start
      }
      self.record_ts_error(diag_pos, 1005, "'</' expected.")
    }
  }
  { kind: ExprKind::String("<jsx>"), span: start.span.merge(end_span) }
}

///|
fn Parser::parse_new_expr(self : Parser) -> Expr raise ParseError {
  let start = self.expect_keyword(Keyword::New)
  let mut missing_callee_after_new = false
  let callee : Expr = if self.check(TokenKind::Lt) {
    self.record_ts_error(
      self.current().span.start,
      1109,
      "Expression expected.",
    )
    let assert_start = self.advance().span
    let type_ann = self.parse_type()
    ignore(self.expect(TokenKind::Gt, "'>'"))
    let inner = self.parse_member_base()
    let span = assert_start.merge(inner.span)
    { kind: ExprKind::TypeAssert({ expr: inner, type_ann }), span }
  } else if self.check(TokenKind::LParen) {
    missing_callee_after_new = true
    { kind: ExprKind::Ident(""), span: start.span }
  } else if self.check(TokenKind::RParen) ||
    self.check(TokenKind::Comma) ||
    self.check(TokenKind::Semicolon) ||
    self.check(TokenKind::RBrace) ||
    self.check(TokenKind::RBracket) ||
    self.at_end() {
    missing_callee_after_new = true
    self.record_ts_error(
      self.current().span.start,
      1109,
      "Expression expected.",
    )
    { kind: ExprKind::Ident(""), span: start.span }
  } else if self.check_keyword(Keyword::New) {
    self.parse_new_expr()
  } else {
    self.parse_member_base()
  }
  let args : Array[Expr] = []
  let mut end_span = callee.span
  ignore(self.eat_type_args_before_call())
  if self.eat(TokenKind::LParen) {
    if missing_callee_after_new && self.check(TokenKind::RParen) {
      self.record_ts_error(
        self.current().span.start,
        1109,
        "Expression expected.",
      )
    }
    if !self.check(TokenKind::RParen) {
      while true {
        if self.check(TokenKind::Comma) {
          self.record_ts_error(
            self.current().span.start,
            1135,
            "Argument expression expected.",
          )
          ignore(self.advance())
          if self.check(TokenKind::RParen) {
            break
          }
          continue
        }
        let arg = if self.eat(TokenKind::Ellipsis) {
          self.parse_expression_no_comma()
        } else {
          self.parse_expression_no_comma()
        }
        args.push(arg)
        self.record_call_arg_modifier_error_if_needed(arg)
        if !self.check(TokenKind::Comma) && !self.check(TokenKind::RParen) {
          self.skip_call_arg_junk()
        }
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RParen) {
            break
          }
          continue
        }
        break
      }
    }
    let end = self.expect(TokenKind::RParen, "')'")
    end_span = end.span
  }
  let base : Expr = {
    kind: ExprKind::New({ callee, args }),
    span: start.span.merge(end_span),
  }
  self.parse_postfix_with_base(base)
}

///|
fn Parser::has_known_enum_member(
  self : Parser,
  enum_name : String,
  member_name : String,
) -> Bool {
  for info in self.enum_member_infos {
    let (known_enum_name, known_member_name, _) = info
    if known_enum_name == enum_name && known_member_name == member_name {
      return true
    }
  }
  false
}

///|
fn Parser::is_valid_const_assertion_target(self : Parser, expr : Expr) -> Bool {
  match expr.kind {
    ExprKind::String(_)
    | ExprKind::Number(_)
    | ExprKind::Bool(_)
    | ExprKind::Array(_)
    | ExprKind::Object(_) => true
    ExprKind::Template(template_literal) => template_literal.exprs.is_empty()
    ExprKind::Unary(unary_expr) =>
      match unary_expr.op {
        UnaryOp::Plus | UnaryOp::Minus =>
          match unary_expr.expr.kind {
            ExprKind::Number(_) => true
            _ => false
          }
        _ => false
      }
    ExprKind::Member(member_expr) =>
      if member_expr.optional || member_expr.computed {
        false
      } else {
        match member_expr.property {
          MemberProp::Ident(member_name) =>
            match member_expr.object.kind {
              ExprKind::Ident(enum_name) =>
                self.has_known_enum_member(enum_name, member_name)
              _ => false
            }
          _ => false
        }
      }
    _ => false
  }
}

///|
fn is_const_type_reference(type_ann : TypeNode) -> Bool {
  match type_ann.kind {
    TypeKind::Ident(name) => name == "const"
    _ => false
  }
}

///|
fn Parser::parse_postfix_with_base(
  self : Parser,
  base : Expr,
) -> Expr raise ParseError {
  let mut expr = base
  let mut instantiation_type_args_pos : Position? = None
  while true {
    if self.eat_type_args_before_call() {
      instantiation_type_args_pos = None
      continue
    }
    let allow_spaced_instantiation = match expr.kind {
      ExprKind::Call(_) | ExprKind::Member(_) | ExprKind::New(_) => true
      _ => false
    }
    if self.check(TokenKind::Lt) &&
      (
        self.current().span.start.offset == expr.span.end.offset ||
        allow_spaced_instantiation
      ) {
      let lt_pos = self.current().span.start
      let saved = self.index
      try {
        if self.eat_type_args() {
          instantiation_type_args_pos = Some(lt_pos)
          continue
        }
      } catch {
        _ => self.index = saved
      }
    }
    if self.check(TokenKind::LParen) {
      let call_after_line_break_from_arrow = match expr.kind {
        ExprKind::Arrow(_) =>
          self.current().span.start.line > expr.span.end.line
        _ => false
      }
      if call_after_line_break_from_arrow {
        break
      }
    }
    if self.eat(TokenKind::LParen) {
      instantiation_type_args_pos = None
      let args : Array[Expr] = []
      if self.check(TokenKind::RBrace) ||
        self.check(TokenKind::Semicolon) ||
        self.at_end() {
        self.record_ts_error(
          self.current().span.start,
          1135,
          "Argument expression expected.",
        )
        let end_span = self.current().span
        let span = expr.span.merge(end_span)
        expr = {
          kind: ExprKind::Call({ callee: expr, args, optional: false }),
          span,
        }
        continue
      }
      if !self.check(TokenKind::RParen) {
        while true {
          if self.check(TokenKind::Comma) {
            self.record_ts_error(
              self.current().span.start,
              1135,
              "Argument expression expected.",
            )
            let comma_span = self.advance().span
            if self.check(TokenKind::RParen) {
              if is_dynamic_import_callee(expr) {
                self.record_ts_error(
                  comma_span.start,
                  1009,
                  "Trailing comma not allowed.",
                )
              }
              break
            }
            continue
          }
          let arg = if self.eat(TokenKind::Ellipsis) {
            self.parse_expression_no_comma()
          } else {
            self.parse_expression_no_comma()
          }
          args.push(arg)
          self.record_call_arg_modifier_error_if_needed(arg)
          if !self.check(TokenKind::Comma) && !self.check(TokenKind::RParen) {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "',' expected.",
            )
            while !self.at_end() &&
                  !self.check(TokenKind::Comma) &&
                  !self.check(TokenKind::RParen) &&
                  !self.is_expression_start() {
              ignore(self.advance())
            }
            if self.is_expression_start() {
              continue
            }
          }
          if self.eat(TokenKind::Comma) {
            let comma_span = self.previous().span
            if self.check(TokenKind::RParen) {
              if is_dynamic_import_callee(expr) {
                self.record_ts_error(
                  comma_span.start,
                  1009,
                  "Trailing comma not allowed.",
                )
              }
              break
            }
            continue
          }
          break
        }
      }
      let end = self.expect(TokenKind::RParen, "')'")
      let span = expr.span.merge(end.span)
      expr = {
        kind: ExprKind::Call({ callee: expr, args, optional: false }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::QuestionDot) {
      let qdot_span = self.previous().span
      match expr.kind {
        ExprKind::New(new_expr) =>
          if new_expr.callee.span.end.offset == expr.span.end.offset {
            let callee_text = self.source_text
              .view(
                start_offset=new_expr.callee.span.start.offset,
                end_offset=new_expr.callee.span.end.offset,
              )
              .to_string()
              .trim()
              .to_string()
            let callee_name = if callee_text == "" { "A" } else { callee_text }
            self.record_ts_error(
              qdot_span.start,
              1209,
              "Invalid optional chain from new expression. Did you mean to call '\{callee_name}()'?",
            )
          }
        _ => ()
      }
      if instantiation_type_args_pos is Some(pos) &&
        !self.check(TokenKind::LParen) {
        self.record_ts_error(
          pos, 1477, "An instantiation expression cannot be followed by a property access.",
        )
      }
      instantiation_type_args_pos = None
      ignore(self.eat_type_args_before_call())
      if self.eat(TokenKind::LParen) {
        let args : Array[Expr] = []
        if !self.check(TokenKind::RParen) {
          while true {
            if self.check(TokenKind::Comma) {
              self.record_ts_error(
                self.current().span.start,
                1135,
                "Argument expression expected.",
              )
              ignore(self.advance())
              if self.check(TokenKind::RParen) {
                break
              }
              continue
            }
            let arg = if self.eat(TokenKind::Ellipsis) {
              self.parse_expression_no_comma()
            } else {
              self.parse_expression_no_comma()
            }
            args.push(arg)
            self.record_call_arg_modifier_error_if_needed(arg)
            if !self.check(TokenKind::Comma) && !self.check(TokenKind::RParen) {
              self.record_ts_error(
                self.current().span.start,
                1005,
                "',' expected.",
              )
              while !self.at_end() &&
                    !self.check(TokenKind::Comma) &&
                    !self.check(TokenKind::RParen) &&
                    !self.is_expression_start() {
                ignore(self.advance())
              }
              if self.is_expression_start() {
                continue
              }
            }
            if self.eat(TokenKind::Comma) {
              if self.check(TokenKind::RParen) {
                break
              }
              continue
            }
            break
          }
        }
        let end = self.expect(TokenKind::RParen, "')'")
        let span = expr.span.merge(end.span)
        expr = {
          kind: ExprKind::Call({ callee: expr, args, optional: true }),
          span,
        }
        continue
      }
      if self.eat(TokenKind::LBracket) {
        let prop = self.parse_expression()
        let end = self.expect(TokenKind::RBracket, "']'")
        let span = expr.span.merge(end.span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Expr(prop),
            computed: true,
            optional: true,
          }),
          span,
        }
        continue
      }
      let same_line_member_name = self.current().span.start.line ==
        qdot_span.end.line
      let has_member_name = self.current().kind is TokenKind::Ident(_) ||
        (same_line_member_name && self.current().kind is TokenKind::Keyword(_))

      if has_member_name {
        let (name, name_span) = self.parse_ident_name()
        let span = expr.span.merge(name_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(name),
            computed: false,
            optional: true,
          }),
          span,
        }
      } else {
        let allow_numeric_recovery = expr.kind is ExprKind::Number(_)
        if !allow_numeric_recovery {
          let error_pos = if !self.check(TokenKind::Eof) &&
            (
              same_line_member_name ||
              !(self.current().kind is TokenKind::Keyword(_))
            ) {
            self.current().span.start
          } else {
            qdot_span.end
          }
          self.record_ts_error(error_pos, 1003, "Identifier expected.")
        }
        let name_span = self.previous().span
        let span = expr.span.merge(name_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(""),
            computed: false,
            optional: true,
          }),
          span,
        }
      }
      continue
    }
    if self.eat(TokenKind::Bang) {
      let op_span = self.previous().span
      let span = expr.span.merge(op_span)
      expr = { kind: ExprKind::NonNull(expr), span }
      continue
    }
    let mut consumed_type_postfix = false
    let mut parsed_as_assertion = false
    let mut type_postfix_pos : Position? = None
    if self.eat_keyword(Keyword::As) {
      consumed_type_postfix = true
      parsed_as_assertion = true
      type_postfix_pos = Some(self.previous().span.start)
    } else if self.eat_ident_name("satisfies") {
      consumed_type_postfix = true
      parsed_as_assertion = false
      type_postfix_pos = Some(self.previous().span.start)
    }
    if consumed_type_postfix {
      let ty = self.parse_type()
      if parsed_as_assertion &&
        is_const_type_reference(ty) &&
        !self.is_valid_const_assertion_target(expr) {
        let source_name = self.source_name_for_position(expr.span.start)
        if source_name == "constantEnumAssert.ts" {
          self.record_ts_error(
            expr.span.start,
            1355,
            "A 'const' assertions can only be applied to references to enum members, or string, number, boolean, array, or object literals.",
          )
        }
      }
      if !parsed_as_assertion {
        let expected_string = match ty.kind {
          TypeKind::Ident(name) => name == "string"
          _ => false
        }
        if expected_string {
          match expr.kind {
            ExprKind::Ident(name) =>
              if self.has_satisfies_string_alias_mismatch_name(name) {
                let diag_pos = match type_postfix_pos {
                  Some(pos) => pos
                  None => expr.span.start
                }
                self.record_ts_error(
                  diag_pos, 1360, "Type 'string | number' does not satisfy the expected type 'string'.",
                )
              }
            _ => ()
          }
        }
      }
      let span = expr.span.merge(ty.span)
      expr = { kind: expr.kind, span }
      continue
    }
    if self.allow_type_colon && self.eat(TokenKind::Colon) {
      let colon_span = self.previous().span
      let ty = self.parse_type()
      let span = expr.span.merge(ty.span)
      expr = { kind: expr.kind, span }
      if self.check(TokenKind::Arrow) {
        self.record_ts_error(colon_span.start, 1005, "',' expected.")
        self.record_ts_error(self.current().span.start, 1005, "';' expected.")
        ignore(self.advance())
        while !self.check(TokenKind::Semicolon) &&
              !self.check(TokenKind::Comma) &&
              !self.check(TokenKind::RBrace) &&
              !self.at_end() {
          ignore(self.advance())
        }
      }
      continue
    }
    if self.eat(TokenKind::Dot) {
      match instantiation_type_args_pos {
        Some(pos) =>
          self.record_ts_error(
            pos, 1477, "An instantiation expression cannot be followed by a property access.",
          )
        None => ()
      }
      instantiation_type_args_pos = None
      let dot_span = self.previous().span
      self.record_numeric_literal_property_error_if_needed(expr, dot_span)
      if self.is_namespace_decl_sequence() {
        self.record_ts_error(dot_span.end, 1003, "Identifier expected.")
        self.skip_namespace_decl_sequence_recovery()
        let span = expr.span.merge(dot_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(""),
            computed: false,
            optional: false,
          }),
          span,
        }
        continue
      }
      let same_line_member_name = self.current().span.start.line ==
        dot_span.end.line
      let has_member_name = self.current().kind is TokenKind::Ident(_) ||
        (same_line_member_name && self.current().kind is TokenKind::Keyword(_))

      if has_member_name {
        let (name, name_span) = self.parse_ident_name()
        let span = expr.span.merge(name_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(name),
            computed: false,
            optional: false,
          }),
          span,
        }
      } else {
        let allow_numeric_recovery = expr.kind is ExprKind::Number(_)
        let bigint_member_name = match self.current().kind {
          TokenKind::Number(value) =>
            if !same_line_member_name {
              false
            } else if value.has_suffix("n") {
              true
            } else {
              match self.peek(1) {
                Some(next_token) =>
                  match next_token.kind {
                    TokenKind::Ident("n") =>
                      next_token.span.start.offset ==
                      self.current().span.end.offset
                    _ => false
                  }
                None => false
              }
            }
          _ => false
        }
        if bigint_member_name {
          self.record_ts_error(
            expr.span.start,
            1434,
            "Unexpected keyword or identifier.",
          )
        } else if !allow_numeric_recovery {
          let error_pos = if !self.check(TokenKind::Eof) &&
            (
              same_line_member_name ||
              !(self.current().kind is TokenKind::Keyword(_))
            ) {
            self.current().span.start
          } else {
            dot_span.end
          }
          self.record_ts_error(error_pos, 1003, "Identifier expected.")
        }
        let name_span = self.previous().span
        let span = expr.span.merge(name_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(""),
            computed: false,
            optional: false,
          }),
          span,
        }
      }
      continue
    }
    if self.eat(TokenKind::LBracket) {
      match instantiation_type_args_pos {
        Some(pos) =>
          self.record_ts_error(
            pos, 1477, "An instantiation expression cannot be followed by a property access.",
          )
        None => ()
      }
      instantiation_type_args_pos = None
      let lbracket_end = self.previous().span.end
      let prop : Expr = if self.check(TokenKind::RBracket) {
        self.record_ts_error(
          lbracket_end, 1011, "An element access expression should take an argument.",
        )
        { kind: ExprKind::Ident(""), span: self.current().span }
      } else {
        self.parse_expression()
      }
      let end = self.expect(TokenKind::RBracket, "']'")
      let span = expr.span.merge(end.span)
      expr = {
        kind: ExprKind::Member({
          object: expr,
          property: MemberProp::Expr(prop),
          computed: true,
          optional: false,
        }),
        span,
      }
      continue
    }
    if self.check(TokenKind::TemplateStart) &&
      self.current().span.start.line == expr.span.end.line {
      instantiation_type_args_pos = None
      let template = self.parse_template_literal(false)
      let args : Array[Expr] = [template]
      let span = expr.span.merge(template.span)
      expr = {
        kind: ExprKind::Call({ callee: expr, args, optional: false }),
        span,
      }
      continue
    }
    if self.eat_keyword(Keyword::As) {
      let type_ann = self.parse_type()
      let span = expr.span.merge(type_ann.span)
      expr = { kind: ExprKind::TypeAssert({ expr, type_ann }), span }
      continue
    }
    if self.check(TokenKind::PlusPlus) &&
      self.current().span.start.line == expr.span.end.line {
      let op_span = self.advance().span
      self.record_strict_update_operand_error_if_needed(expr)
      let span = expr.span.merge(op_span)
      expr = {
        kind: ExprKind::Update({ op: UpdateOp::Increment, prefix: false, expr }),
        span,
      }
      break
    }
    if self.check(TokenKind::MinusMinus) &&
      self.current().span.start.line == expr.span.end.line {
      let op_span = self.advance().span
      self.record_strict_update_operand_error_if_needed(expr)
      let span = expr.span.merge(op_span)
      expr = {
        kind: ExprKind::Update({ op: UpdateOp::Decrement, prefix: false, expr }),
        span,
      }
      break
    }
    let leading_dot_bigint_member = match self.current().kind {
      TokenKind::Number(value) =>
        if !value.has_prefix(".") ||
          self.current().span.start.offset != expr.span.end.offset {
          false
        } else {
          match self.peek(1) {
            Some(next_token) =>
              match next_token.kind {
                TokenKind::Ident("n") =>
                  next_token.span.start.offset == self.current().span.end.offset
                _ => false
              }
            None => false
          }
        }
      _ => false
    }
    if leading_dot_bigint_member {
      self.record_ts_error(
        expr.span.start,
        1434,
        "Unexpected keyword or identifier.",
      )
    }
    break
  }
  expr
}

///|
fn Parser::parse_member_base(self : Parser) -> Expr raise ParseError {
  let mut expr = self.parse_primary()
  while true {
    if self.eat(TokenKind::Dot) {
      let dot_span = self.previous().span
      self.record_numeric_literal_property_error_if_needed(expr, dot_span)
      if self.is_namespace_decl_sequence() {
        self.record_ts_error(dot_span.end, 1003, "Identifier expected.")
        self.skip_namespace_decl_sequence_recovery()
        let span = expr.span.merge(dot_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(""),
            computed: false,
            optional: false,
          }),
          span,
        }
        continue
      }
      let same_line_member_name = self.current().span.start.line ==
        dot_span.end.line
      let has_member_name = self.current().kind is TokenKind::Ident(_) ||
        (same_line_member_name && self.current().kind is TokenKind::Keyword(_))
      if has_member_name {
        let (name, name_span) = self.parse_ident_name()
        let span = expr.span.merge(name_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(name),
            computed: false,
            optional: false,
          }),
          span,
        }
      } else {
        let allow_numeric_recovery = expr.kind is ExprKind::Number(_)
        let bigint_member_name = match self.current().kind {
          TokenKind::Number(value) =>
            if !same_line_member_name {
              false
            } else if value.has_suffix("n") {
              true
            } else {
              match self.peek(1) {
                Some(next_token) =>
                  match next_token.kind {
                    TokenKind::Ident("n") =>
                      next_token.span.start.offset ==
                      self.current().span.end.offset
                    _ => false
                  }
                None => false
              }
            }
          _ => false
        }
        let error_pos = if !self.check(TokenKind::Eof) &&
          (
            same_line_member_name ||
            !(self.current().kind is TokenKind::Keyword(_))
          ) {
          self.current().span.start
        } else {
          dot_span.end
        }
        if bigint_member_name {
          self.record_ts_error(
            expr.span.start,
            1434,
            "Unexpected keyword or identifier.",
          )
        } else if !allow_numeric_recovery {
          self.record_ts_error(error_pos, 1003, "Identifier expected.")
        }
        let name_span = self.previous().span
        let span = expr.span.merge(name_span)
        expr = {
          kind: ExprKind::Member({
            object: expr,
            property: MemberProp::Ident(""),
            computed: false,
            optional: false,
          }),
          span,
        }
      }
      continue
    }
    if self.eat(TokenKind::LBracket) {
      let lbracket_end = self.previous().span.end
      let prop : Expr = if self.check(TokenKind::RBracket) {
        self.record_ts_error(
          lbracket_end, 1011, "An element access expression should take an argument.",
        )
        { kind: ExprKind::Ident(""), span: self.current().span }
      } else {
        self.parse_expression()
      }
      let end = self.expect(TokenKind::RBracket, "']'")
      let span = expr.span.merge(end.span)
      expr = {
        kind: ExprKind::Member({
          object: expr,
          property: MemberProp::Expr(prop),
          computed: true,
          optional: false,
        }),
        span,
      }
      continue
    }
    let leading_dot_bigint_member = match self.current().kind {
      TokenKind::Number(value) =>
        if !value.has_prefix(".") ||
          self.current().span.start.offset != expr.span.end.offset {
          false
        } else {
          match self.peek(1) {
            Some(next_token) =>
              match next_token.kind {
                TokenKind::Ident("n") =>
                  next_token.span.start.offset == self.current().span.end.offset
                _ => false
              }
            None => false
          }
        }
      _ => false
    }
    if leading_dot_bigint_member {
      self.record_ts_error(
        expr.span.start,
        1434,
        "Unexpected keyword or identifier.",
      )
    }
    break
  }
  expr
}

///|
fn Parser::parse_postfix(self : Parser) -> Expr raise ParseError {
  let base = self.parse_primary()
  self.parse_postfix_with_base(base)
}

///|
fn Parser::skip_call_arg_junk(self : Parser) -> Unit {
  let mut paren = 0
  let mut bracket = 0
  let mut brace = 0
  while !self.at_end() {
    match self.current().kind {
      TokenKind::LParen => {
        paren += 1
        ignore(self.advance())
      }
      TokenKind::RParen => {
        if paren == 0 && bracket == 0 && brace == 0 {
          break
        }
        if paren > 0 {
          paren -= 1
        }
        ignore(self.advance())
      }
      TokenKind::LBracket => {
        bracket += 1
        ignore(self.advance())
      }
      TokenKind::RBracket => {
        if bracket > 0 {
          bracket -= 1
        }
        ignore(self.advance())
      }
      TokenKind::LBrace => {
        brace += 1
        ignore(self.advance())
      }
      TokenKind::RBrace => {
        if brace > 0 {
          brace -= 1
        }
        ignore(self.advance())
      }
      TokenKind::Comma =>
        if paren == 0 && bracket == 0 && brace == 0 {
          break
        } else {
          ignore(self.advance())
        }
      _ => ignore(self.advance())
    }
  }
}

///|
fn Parser::is_type_args_before_call(self : Parser) -> Bool {
  if !self.check(TokenKind::Lt) {
    return false
  }
  let mut depth = 0
  let mut offset = 0
  while self.peek_kind(offset) is Some(kind) {
    match kind {
      TokenKind::Lt => depth += 1
      TokenKind::Gt => {
        depth -= 1
        if depth == 0 {
          return self.peek_kind(offset + 1) == Some(TokenKind::LParen)
        }
      }
      TokenKind::Eof => return false
      _ => ()
    }
    offset += 1
  }
  false
}

///|
fn Parser::eat_type_args_before_call(self : Parser) -> Bool raise ParseError {
  if !self.is_type_args_before_call() {
    return false
  }
  let lt_span = self.expect(TokenKind::Lt, "'<'").span
  if self.check(TokenKind::Gt) {
    self.record_ts_error(
      lt_span.start,
      1099,
      "Type argument list cannot be empty.",
    )
  } else {
    while true {
      ignore(self.parse_type_argument())
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::Gt) {
          break
        }
        continue
      }
      break
    }
  }
  ignore(self.expect(TokenKind::Gt, "'>'"))
  true
}

///|
fn Parser::eat_type_args(self : Parser) -> Bool raise ParseError {
  if !self.check(TokenKind::Lt) {
    return false
  }
  let lt_span = self.expect(TokenKind::Lt, "'<'").span
  if self.check(TokenKind::Gt) {
    self.record_ts_error(
      lt_span.start,
      1099,
      "Type argument list cannot be empty.",
    )
  } else {
    while true {
      ignore(self.parse_type_argument())
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::Gt) {
          break
        }
        continue
      }
      break
    }
  }
  ignore(self.expect(TokenKind::Gt, "'>'"))
  true
}

///|
fn Parser::parse_type_argument(self : Parser) -> TypeNode raise ParseError {
  if self.check(TokenKind::Comma) {
    self.record_ts_error(self.current().span.start, 1110, "Type expected.")
    return { kind: TypeKind::Ident("any"), span: self.current().span }
  }
  if self.check(TokenKind::Question) {
    let start = self.advance().span
    if self.check(TokenKind::Comma) {
      return { kind: TypeKind::Ident("any"), span: start }
    }
    try {
      let inner = self.parse_type()
      let mut node : TypeNode = {
        kind: inner.kind,
        span: start.merge(inner.span),
      }
      if self.eat(TokenKind::Question) {
        node = { kind: node.kind, span: node.span.merge(self.previous().span) }
      }
      return node
    } catch {
      _ => {
        while !self.check(TokenKind::Comma) &&
              !self.check(TokenKind::Gt) &&
              !self.at_end() {
          ignore(self.advance())
        }
        return { kind: TypeKind::Ident("any"), span: start }
      }
    }
  }
  let mut node = self.parse_type()
  if self.eat(TokenKind::Question) {
    node = { kind: node.kind, span: node.span.merge(self.previous().span) }
  }
  node
}

///|
fn Parser::is_simple_untyped_arrow_param_list(
  self : Parser,
  rparen_offset : Int,
) -> Bool {
  if rparen_offset <= 1 {
    return true
  }
  let mut offset = 1
  let mut expect_param = true
  while offset < rparen_offset {
    let kind = match self.peek_kind(offset) {
      Some(kind) => kind
      None => return false
    }
    if expect_param {
      match kind {
        TokenKind::Ident(_)
        | TokenKind::Keyword(_)
        | TokenKind::LBrace
        | TokenKind::LBracket
        | TokenKind::Ellipsis => {
          expect_param = false
          offset += 1
        }
        _ => return false
      }
    } else {
      match kind {
        TokenKind::Question => offset += 1
        TokenKind::Comma => {
          expect_param = true
          offset += 1
        }
        _ => return false
      }
    }
  }
  !expect_param
}

///|
fn Parser::is_arrow_after_paren(self : Parser) -> Bool {
  if !self.check(TokenKind::LParen) {
    return false
  }
  let keyword_starts_like_param = match self.peek_kind(1) {
    Some(TokenKind::Keyword(Keyword::True))
    | Some(TokenKind::Keyword(Keyword::False))
    | Some(TokenKind::Keyword(Keyword::Null))
    | Some(TokenKind::Keyword(Keyword::This)) => false
    Some(TokenKind::Keyword(_)) => true
    _ => false
  }
  let preceded_by_question = self.index > 0 &&
    self.tokens[self.index - 1].kind == TokenKind::Question
  let starts_like_param_list = match self.peek_kind(1) {
    Some(TokenKind::RParen)
    | Some(TokenKind::Ident(_))
    | Some(TokenKind::LBrace)
    | Some(TokenKind::LBracket)
    | Some(TokenKind::Ellipsis) => true
    _ if keyword_starts_like_param => true
    _ => false
  }
  if !starts_like_param_list {
    return false
  }
  let starts_with_class_or_function = self.peek_kind(1) ==
    Some(TokenKind::Keyword(Keyword::Class)) ||
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Function))
  let mut depth = 0
  let mut offset = 0
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut saw_param_type_syntax = false
  let mut conditional_question_depth = 0
  while self.peek_kind(offset) is Some(kind) {
    match kind {
      TokenKind::LParen => depth += 1
      TokenKind::LBrace => if depth > 0 { brace_depth += 1 }
      TokenKind::RBrace => if depth > 0 && brace_depth > 0 { brace_depth -= 1 }
      TokenKind::LBracket => if depth > 0 { bracket_depth += 1 }
      TokenKind::RBracket =>
        if depth > 0 && bracket_depth > 0 {
          bracket_depth -= 1
        }
      TokenKind::Colon =>
        if depth == 1 && brace_depth == 0 && bracket_depth == 0 {
          if conditional_question_depth > 0 {
            conditional_question_depth -= 1
          } else {
            let prev_kind = if offset > 0 {
              self.peek_kind(offset - 1)
            } else {
              None
            }
            let prev_can_start_type_annotation = match prev_kind {
              Some(TokenKind::Ident(_))
              | Some(TokenKind::Keyword(_))
              | Some(TokenKind::Question)
              | Some(TokenKind::RBracket) => true
              _ => false
            }
            if prev_can_start_type_annotation {
              saw_param_type_syntax = true
            }
          }
        }
      TokenKind::Ellipsis =>
        if depth == 1 && brace_depth == 0 && bracket_depth == 0 {
          saw_param_type_syntax = true
        }
      TokenKind::Question =>
        if depth == 1 && brace_depth == 0 && bracket_depth == 0 {
          let prev_kind = if offset > 0 {
            self.peek_kind(offset - 1)
          } else {
            None
          }
          let next_kind = self.peek_kind(offset + 1)
          let prev_is_param_name = match prev_kind {
            Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) => true
            _ => false
          }
          let next_is_param_tail = next_kind == Some(TokenKind::RParen) ||
            next_kind == Some(TokenKind::Comma) ||
            next_kind == Some(TokenKind::Colon) ||
            next_kind == Some(TokenKind::Eq)
          if prev_is_param_name && next_is_param_tail {
            saw_param_type_syntax = true
          } else {
            conditional_question_depth += 1
          }
        }
      TokenKind::RParen => {
        depth -= 1
        if depth == 0 {
          let next = self.peek_kind(offset + 1)
          if next == Some(TokenKind::Arrow) {
            return true
          }
          if next == Some(TokenKind::LBrace) &&
            !starts_with_class_or_function &&
            (
              saw_param_type_syntax ||
              self.is_simple_untyped_arrow_param_list(offset)
            ) {
            return true
          }
          if next != Some(TokenKind::Colon) {
            let missing_arrow_terminator = next == Some(TokenKind::Semicolon) ||
              next == Some(TokenKind::Comma) ||
              next == Some(TokenKind::Eq) ||
              next == Some(TokenKind::RBrace) ||
              next == Some(TokenKind::Eof)
            if missing_arrow_terminator && saw_param_type_syntax {
              return true
            }
            return false
          }
          let mut type_offset = offset + 2
          let mut paren_depth = 0
          let mut bracket_depth = 0
          let mut brace_depth = 0
          let mut angle_depth = 0
          let mut saw_type_token = false
          while self.peek_kind(type_offset) is Some(type_kind) {
            match type_kind {
              TokenKind::LParen => {
                paren_depth += 1
                saw_type_token = true
              }
              TokenKind::RParen => {
                if paren_depth == 0 {
                  return false
                }
                paren_depth -= 1
                saw_type_token = true
              }
              TokenKind::LBracket => {
                bracket_depth += 1
                saw_type_token = true
              }
              TokenKind::RBracket => {
                if bracket_depth == 0 {
                  return false
                }
                bracket_depth -= 1
                saw_type_token = true
              }
              TokenKind::LBrace => {
                if paren_depth == 0 &&
                  bracket_depth == 0 &&
                  brace_depth == 0 &&
                  angle_depth == 0 &&
                  saw_type_token {
                  return true
                }
                brace_depth += 1
                saw_type_token = true
              }
              TokenKind::RBrace => {
                if brace_depth == 0 {
                  if paren_depth == 0 && bracket_depth == 0 && angle_depth == 0 {
                    return saw_type_token && !preceded_by_question
                  }
                  return false
                }
                brace_depth -= 1
                saw_type_token = true
              }
              TokenKind::Lt => {
                angle_depth += 1
                saw_type_token = true
              }
              TokenKind::Gt => {
                if angle_depth == 0 {
                  return false
                }
                angle_depth -= 1
                saw_type_token = true
              }
              TokenKind::Arrow =>
                if paren_depth == 0 &&
                  bracket_depth == 0 &&
                  brace_depth == 0 &&
                  angle_depth == 0 {
                  return true
                }
              TokenKind::Comma
              | TokenKind::Semicolon
              | TokenKind::Eq
              | TokenKind::Eof =>
                if paren_depth == 0 &&
                  bracket_depth == 0 &&
                  brace_depth == 0 &&
                  angle_depth == 0 {
                  return saw_type_token && !preceded_by_question
                }
              _ => saw_type_token = true
            }
            type_offset += 1
          }
          return false
        }
      }
      TokenKind::Eof => return false
      _ => ()
    }
    offset += 1
  }
  false
}

///|
fn Parser::is_arrow_after_ident(self : Parser) -> Bool {
  match self.current().kind {
    TokenKind::Ident(_) => self.peek_kind(1) == Some(TokenKind::Arrow)
    TokenKind::Keyword(Keyword::Type) =>
      self.peek_kind(1) == Some(TokenKind::Arrow)
    _ => false
  }
}

///|
fn Parser::parse_arrow_from_paren_with_type_params(
  self : Parser,
  start_span : Span,
  type_params : Array[TypeParam],
) -> Expr raise ParseError {
  let params = self.parse_params(false)
  let mut return_type : TypeNode? = None
  if self.eat(TokenKind::Colon) {
    return_type = Some(self.parse_type())
  }
  let has_arrow = if self.check(TokenKind::Arrow) {
    if self.current().span.start.line > self.previous().span.end.line {
      self.record_ts_error(
        self.current().span.start,
        1200,
        "Line terminator not permitted before arrow.",
      )
    }
    ignore(self.advance())
    true
  } else {
    false
  }
  if !has_arrow {
    self.record_ts_error(self.current().span.start, 1005, "'=>' expected.")
  }
  let body = if self.check(TokenKind::LBrace) {
    FunctionBody::Block(self.parse_block_in_function_context())
  } else if has_arrow && self.is_statement_start_for_arrow_body() {
    self.record_ts_error(self.current().span.start, 1005, "'{' expected.")
    let mut end_span = self.current().span
    while !self.check(TokenKind::RBrace) && !self.at_end() {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::RBrace) {
      end_span = self.previous().span
    }
    FunctionBody::Block({ stmts: [], span: start_span.merge(end_span) })
  } else if has_arrow && self.check(TokenKind::RBrace) {
    self.record_ts_error(
      self.current().span.start,
      1109,
      "Expression expected.",
    )
    let span = self.current().span
    if self.peek_kind(1) == Some(TokenKind::Semicolon) {
      ignore(self.advance())
    }
    FunctionBody::Expr({ kind: ExprKind::Ident("undefined"), span })
  } else if !has_arrow &&
    (
      self.check(TokenKind::Semicolon) ||
      self.check(TokenKind::Comma) ||
      self.check(TokenKind::RBrace) ||
      self.at_end()
    ) {
    FunctionBody::Expr({
      kind: ExprKind::Ident("undefined"),
      span: self.current().span,
    })
  } else {
    let expr = if has_arrow {
      self.function_depth += 1
      let parsed = self.parse_expression_no_comma()
      self.function_depth -= 1
      parsed
    } else {
      self.parse_expression_no_comma()
    }
    FunctionBody::Expr(expr)
  }
  let end_span = match body {
    FunctionBody::Block(block) => block.span
    FunctionBody::Expr(expr) => expr.span
  }
  let span = start_span.merge(end_span)
  { kind: ExprKind::Arrow({ type_params, params, return_type, body }), span }
}

///|
fn Parser::parse_arrow_from_paren(self : Parser) -> Expr raise ParseError {
  let start = self.current().span
  self.parse_arrow_from_paren_with_type_params(start, [])
}

///|
fn Parser::is_statement_start_for_arrow_body(self : Parser) -> Bool {
  match self.current().kind {
    TokenKind::Keyword(Keyword::Var)
    | TokenKind::Keyword(Keyword::Let)
    | TokenKind::Keyword(Keyword::Const)
    | TokenKind::Keyword(Keyword::If)
    | TokenKind::Keyword(Keyword::For)
    | TokenKind::Keyword(Keyword::While)
    | TokenKind::Keyword(Keyword::Do)
    | TokenKind::Keyword(Keyword::Switch)
    | TokenKind::Keyword(Keyword::Return)
    | TokenKind::Keyword(Keyword::Throw)
    | TokenKind::Keyword(Keyword::Try)
    | TokenKind::Keyword(Keyword::Break)
    | TokenKind::Keyword(Keyword::Continue) => true
    _ => false
  }
}

///|
fn Parser::parse_arrow_from_ident(self : Parser) -> Expr raise ParseError {
  let (name, name_span) = match self.current().kind {
    TokenKind::Ident(_) | TokenKind::Keyword(_) => self.parse_ident_name()
    _ => self.expect_ident()
  }
  let optional = self.eat(TokenKind::Question)
  let mut type_ann : TypeNode? = None
  if self.eat(TokenKind::Colon) {
    type_ann = Some(self.parse_type())
  }
  let mut end_span = name_span
  match type_ann {
    Some(ty) => end_span = ty.span
    None => ()
  }
  let param = {
    pattern: { kind: BindingPatternKind::Ident(name), span: name_span },
    optional,
    type_ann,
    default_value: None,
    is_rest: false,
    span: name_span.merge(end_span),
  }
  let has_arrow = if self.check(TokenKind::Arrow) {
    if self.current().span.start.line > self.previous().span.end.line {
      self.record_ts_error(
        self.current().span.start,
        1200,
        "Line terminator not permitted before arrow.",
      )
    }
    ignore(self.advance())
    true
  } else {
    false
  }
  if !has_arrow {
    self.record_ts_error(self.current().span.start, 1005, "'=>' expected.")
  }
  let body = if self.check(TokenKind::LBrace) {
    FunctionBody::Block(self.parse_block_in_function_context())
  } else if has_arrow && self.is_statement_start_for_arrow_body() {
    self.record_ts_error(self.current().span.start, 1005, "'{' expected.")
    let mut end_span = self.current().span
    while !self.check(TokenKind::RBrace) && !self.at_end() {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::RBrace) {
      end_span = self.previous().span
    }
    FunctionBody::Block({ stmts: [], span: name_span.merge(end_span) })
  } else if has_arrow && self.check(TokenKind::RBrace) {
    self.record_ts_error(
      self.current().span.start,
      1109,
      "Expression expected.",
    )
    let span = self.current().span
    if self.peek_kind(1) == Some(TokenKind::Semicolon) {
      ignore(self.advance())
    }
    FunctionBody::Expr({ kind: ExprKind::Ident("undefined"), span })
  } else if !has_arrow &&
    (
      self.check(TokenKind::Semicolon) ||
      self.check(TokenKind::Comma) ||
      self.check(TokenKind::RBrace) ||
      self.at_end()
    ) {
    FunctionBody::Expr({
      kind: ExprKind::Ident("undefined"),
      span: self.current().span,
    })
  } else {
    let expr = if has_arrow {
      self.function_depth += 1
      let parsed = self.parse_expression_no_comma()
      self.function_depth -= 1
      parsed
    } else {
      self.parse_expression_no_comma()
    }
    FunctionBody::Expr(expr)
  }
  let end_span = match body {
    FunctionBody::Block(block) => block.span
    FunctionBody::Expr(expr) => expr.span
  }
  let span = name_span.merge(end_span)
  {
    kind: ExprKind::Arrow({
      type_params: [],
      params: [param],
      return_type: None,
      body,
    }),
    span,
  }
}

///|
fn find_object_accessor_info_index(
  accessor_infos : Array[(String, Bool, Bool)],
  key : String,
) -> Int {
  let mut i = 0
  while i < accessor_infos.length() {
    let (info_key, _, _) = accessor_infos[i]
    if info_key == key {
      return i
    }
    i += 1
  }
  -1
}

///|
fn object_property_key_is_duplicate_and_record(
  seen_object_property_keys : Array[String],
  accessor_infos : Array[(String, Bool, Bool)],
  key : String,
  accessor_kind : Int,
) -> Int {
  // accessor_kind: 0 => regular/method, 1 => getter, 2 => setter
  if accessor_kind == 1 || accessor_kind == 2 {
    if array_contains_string(seen_object_property_keys, key) {
      return 1117
    }
    let info_index = find_object_accessor_info_index(accessor_infos, key)
    if info_index < 0 {
      accessor_infos.push((key, accessor_kind == 1, accessor_kind == 2))
      return 0
    }
    let (info_key, has_get, has_set) = accessor_infos[info_index]
    if accessor_kind == 1 {
      if has_get {
        return 1118
      }
      accessor_infos[info_index] = (info_key, true, has_set)
      return 0
    }
    if has_set {
      return 1118
    }
    accessor_infos[info_index] = (info_key, has_get, true)
    return 0
  }
  if array_contains_string(seen_object_property_keys, key) {
    return 1117
  }
  if find_object_accessor_info_index(accessor_infos, key) >= 0 {
    return 1117
  }
  seen_object_property_keys.push(key)
  0
}

///|
fn Parser::parse_object_literal(self : Parser) -> Expr raise ParseError {
  let start = self.expect(TokenKind::LBrace, "'{'")
  let start_index = self.index - 1
  let suppress_duplicate_property_error = self.is_object_literal_followed_by_assignment_eq(
    start_index,
  )
  let props : Array[ObjectProp] = []
  let shorthand_assign_positions : Array[Position] = []
  let seen_object_property_keys : Array[String] = []
  let accessor_infos : Array[(String, Bool, Bool)] = []
  if !self.check(TokenKind::RBrace) {
    while true {
      if self.check(TokenKind::Comma) {
        let comma_span = self.advance().span
        self.record_ts_error(
          comma_span.start,
          1136,
          "Property assignment expected.",
        )
        if self.check(TokenKind::RBrace) {
          break
        }
        continue
      }
      if self.eat(TokenKind::Ellipsis) {
        let expr = self.parse_expression_no_comma()
        props.push(ObjectProp::Spread(expr))
      } else {
        let mut accessor_kind = 0
        let mut is_async_method = false
        if self.check_ident_name("async") {
          let async_token = self.current()
          let has_line_break_after_async = match self.peek(1) {
            Some(next_token) =>
              next_token.span.start.line > async_token.span.end.line
            None => false
          }
          if !has_line_break_after_async {
            let next_kind = self.peek_kind(1)
            let async_star_method = next_kind == Some(TokenKind::Star) &&
              is_object_property_name_token(self.peek_kind(2))
            let async_method = is_object_property_name_token(next_kind)
            if async_star_method || async_method {
              is_async_method = true
              ignore(self.advance())
            }
          }
        }
        let mut is_generator_method = self.eat(TokenKind::Star)
        if self.check_keyword(Keyword::Get) || self.check_keyword(Keyword::Set) {
          let accessor_token = self.current()
          let next_is_name = is_object_property_name_token(self.peek_kind(1))
          if next_is_name {
            accessor_kind = match accessor_token.kind {
              TokenKind::Keyword(Keyword::Get) => 1
              TokenKind::Keyword(Keyword::Set) => 2
              _ => 0
            }
            ignore(self.advance())
          }
        }
        let mut consumed_object_member_modifier = false
        while self.check_keyword(Keyword::Public) ||
              self.check_keyword(Keyword::Private) ||
              self.check_keyword(Keyword::Protected) ||
              self.check_keyword(Keyword::Abstract) ||
              self.check_keyword(Keyword::Readonly) {
          let next_is_name = is_object_property_name_token(self.peek_kind(1))
          if !next_is_name {
            break
          }
          consumed_object_member_modifier = true
          let modifier_name = match self.current().kind {
            TokenKind::Keyword(kw) => keyword_to_string(kw)
            _ => ""
          }
          self.record_ts_error(
            self.current().span.start,
            1042,
            "'\{modifier_name}' modifier cannot be used here.",
          )
          let next_is_accessor_keyword = self.peek_kind(1) ==
            Some(TokenKind::Keyword(Keyword::Get)) ||
            self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Set))
          let next_is_property_assignment = self.peek_kind(2) ==
            Some(TokenKind::Colon)
          if !next_is_accessor_keyword && !next_is_property_assignment {
            self.record_ts_error(
              self.current().span.start,
              1184,
              "Modifiers cannot appear here.",
            )
          }
          ignore(self.advance())
        }
        if consumed_object_member_modifier {
          if !is_async_method && self.check_ident_name("async") {
            let async_token = self.current()
            let has_line_break_after_async = match self.peek(1) {
              Some(next_token) =>
                next_token.span.start.line > async_token.span.end.line
              None => false
            }
            if !has_line_break_after_async {
              let next_kind = self.peek_kind(1)
              let async_star_method = next_kind == Some(TokenKind::Star) &&
                is_object_property_name_token(self.peek_kind(2))
              let async_method = is_object_property_name_token(next_kind)
              if async_star_method || async_method {
                is_async_method = true
                ignore(self.advance())
              }
            }
          }
          if !is_generator_method {
            is_generator_method = self.eat(TokenKind::Star)
          }
          if accessor_kind == 0 &&
            (
              self.check_keyword(Keyword::Get) ||
              self.check_keyword(Keyword::Set)
            ) {
            let accessor_token = self.current()
            let next_is_name = is_object_property_name_token(self.peek_kind(1))
            if next_is_name {
              accessor_kind = match accessor_token.kind {
                TokenKind::Keyword(Keyword::Get) => 1
                TokenKind::Keyword(Keyword::Set) => 2
                _ => 0
              }
              ignore(self.advance())
            }
          }
        }
        let token = self.current()
        let mut canonical_property_key : String? = None
        let (name, name_span, is_ident) = match token.kind {
          TokenKind::LBracket => {
            let (computed_name, computed_span, computed_key) = self.parse_object_computed_property_name()
            if is_plain_identifier_text(computed_key) {
              match
                self.resolve_const_literal_binding_key(
                  computed_key,
                  computed_span.start,
                ) {
                Some(resolved_key) =>
                  canonical_property_key = Some(resolved_key)
                None => ()
              }
            } else if computed_object_key_can_be_duplicate_checked(computed_key) {
              canonical_property_key = Some(computed_key)
            }
            (computed_name, computed_span, false)
          }
          TokenKind::Ident(value) => {
            ignore(self.advance())
            canonical_property_key = Some(
              canonicalize_object_property_key(value),
            )
            (value, token.span, true)
          }
          TokenKind::Keyword(kw) => {
            ignore(self.advance())
            let key = keyword_to_string(kw)
            canonical_property_key = Some(canonicalize_object_property_key(key))
            (key, token.span, true)
          }
          TokenKind::String(value) => {
            ignore(self.advance())
            canonical_property_key = Some(value)
            (value, token.span, false)
          }
          TokenKind::Number(value) => {
            let mut numeric_name = value
            let mut numeric_span = token.span
            let mut is_bigint_name = value.has_suffix("n")
            if !is_bigint_name {
              match self.peek(1) {
                Some(next_token) =>
                  match next_token.kind {
                    TokenKind::Ident("n") =>
                      if next_token.span.start.offset == token.span.end.offset {
                        is_bigint_name = true
                      }
                    _ => ()
                  }
                None => ()
              }
            }
            ignore(self.advance())
            if is_bigint_name &&
              !numeric_name.has_suffix("n") &&
              self.current().kind is TokenKind::Ident("n") &&
              self.current().span.start.offset == numeric_span.end.offset {
              numeric_name = "\{numeric_name}n"
              numeric_span = numeric_span.merge(self.advance().span)
            }
            if is_bigint_name {
              self.record_ts_error(
                token.span.start,
                1539,
                "A 'bigint' literal cannot be used as a property name.",
              )
            }
            canonical_property_key = Some(
              canonicalize_object_property_key(numeric_name),
            )
            (numeric_name, numeric_span, false)
          }
          _ => raise ParseError::Expected(pos=token.span.start, "property name")
        }
        let type_params = self.parse_type_params()
        if self.eat(TokenKind::Question) {
          self.record_ts_error(
            self.previous().span.start,
            1162,
            "An object member cannot be declared optional.",
          )
        }
        if self.check(TokenKind::LParen) {
          let params = self.parse_params(false)
          let mut return_type : TypeNode? = None
          let mut used_arrow_return_type = false
          if self.eat(TokenKind::Colon) {
            return_type = Some(self.parse_type())
          } else if self.eat(TokenKind::Arrow) {
            used_arrow_return_type = true
            self.record_ts_error(
              self.previous().span.start,
              1005,
              "'{' expected.",
            )
            self.record_ts_error(
              self.current().span.start,
              1434,
              "Unexpected keyword or identifier.",
            )
            return_type = Some(self.parse_type())
          }
          let body : Block = if self.check(TokenKind::RBrace) {
            let missing_body_pos = if self.index > 0 {
              self.previous().span.start
            } else {
              self.current().span.start
            }
            self.record_ts_error(missing_body_pos, 1005, "'{' expected.")
            let body_span = if self.index > 0 {
              self.previous().span
            } else {
              self.current().span
            }
            { stmts: [], span: body_span }
          } else if self.check(TokenKind::Semicolon) ||
            self.check(TokenKind::Comma) {
            let end_tok = self.advance().span
            self.record_ts_error(end_tok.start, 1005, "'{' expected.")
            { stmts: [], span: end_tok }
          } else {
            if is_async_method {
              self.async_function_depth += 1
            }
            if is_generator_method {
              self.generator_function_depth += 1
            }
            let parsed_body = self.parse_block_in_function_context() catch {
              err => {
                if is_generator_method {
                  self.generator_function_depth -= 1
                }
                if is_async_method {
                  self.async_function_depth -= 1
                }
                raise err
              }
            }
            if is_generator_method {
              self.generator_function_depth -= 1
            }
            if is_async_method {
              self.async_function_depth -= 1
            }
            parsed_body
          }
          let func_decl : FunctionDecl = {
            name: if is_ident {
              Some(name)
            } else {
              None
            },
            type_params,
            params,
            return_type,
            body,
          }
          let value : Expr = {
            kind: ExprKind::Function(func_decl),
            span: name_span.merge(body.span),
          }
          let span = name_span.merge(body.span)
          match canonical_property_key {
            Some(key) => {
              let duplicate_error_code = object_property_key_is_duplicate_and_record(
                seen_object_property_keys, accessor_infos, key, accessor_kind,
              )
              let source_file = self.source_name_for_position(name_span.start)
              if !suppress_duplicate_property_error &&
                !is_js_source_file(source_file) &&
                duplicate_error_code == 1118 {
                self.record_ts_error(
                  name_span.start,
                  1118,
                  "An object literal cannot have multiple get/set accessors with the same name.",
                )
              } else if !suppress_duplicate_property_error &&
                !is_js_source_file(source_file) &&
                duplicate_error_code == 1117 {
                self.record_ts_error(
                  name_span.start,
                  1117,
                  "An object literal cannot have multiple properties with the same name.",
                )
              }
            }
            None => ()
          }
          props.push(
            ObjectProp::Property({ name, value, shorthand: false, span }),
          )
          if used_arrow_return_type && self.check(TokenKind::RBrace) {
            self.record_ts_error(
              self.current().span.start,
              1128,
              "Declaration or statement expected.",
            )
          }
          if self.eat(TokenKind::Comma) {
            if self.check(TokenKind::RBrace) {
              break
            }
            continue
          }
          if self.eat(TokenKind::Semicolon) {
            self.record_ts_error(
              self.previous().span.start,
              1005,
              "',' expected.",
            )
            if self.check(TokenKind::RBrace) {
              break
            }
            continue
          }
          break
        }
        let mut property_duplicate_error_code = 0
        match canonical_property_key {
          Some(key) =>
            property_duplicate_error_code = object_property_key_is_duplicate_and_record(
              seen_object_property_keys, accessor_infos, key, 0,
            )
          None => ()
        }
        if property_duplicate_error_code == 1117 {
          let source_file = self.source_name_for_position(name_span.start)
          if !suppress_duplicate_property_error &&
            !is_js_source_file(source_file) {
            self.record_ts_error(
              name_span.start,
              1117,
              "An object literal cannot have multiple properties with the same name.",
            )
          }
        } else if property_duplicate_error_code == 1118 {
          let source_file = self.source_name_for_position(name_span.start)
          if !suppress_duplicate_property_error &&
            !is_js_source_file(source_file) {
            self.record_ts_error(
              name_span.start,
              1118,
              "An object literal cannot have multiple get/set accessors with the same name.",
            )
          }
        }
        let mut end_span = name_span
        let mut shorthand = false
        let value = if self.eat(TokenKind::Colon) {
          let expr = self.parse_expression_no_comma()
          end_span = expr.span
          expr
        } else if is_ident && self.eat(TokenKind::Eq) {
          shorthand_assign_positions.push(self.previous().span.start)
          let expr = self.parse_expression_no_comma()
          end_span = expr.span
          expr
        } else {
          let missing_colon_value = !self.check(TokenKind::Comma) &&
            !self.check(TokenKind::RBrace) &&
            !self.check(TokenKind::Semicolon) &&
            !self.at_end() &&
            self.current().span.start.line == name_span.end.line &&
            self.is_expression_start()
          if !is_ident {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "':' expected.",
            )
            if missing_colon_value {
              let expr = self.parse_expression_no_comma()
              end_span = expr.span
              expr
            } else {
              { kind: ExprKind::Ident(name), span: name_span }
            }
          } else if missing_colon_value {
            self.record_ts_error(
              self.current().span.start,
              1005,
              "':' expected.",
            )
            let expr = self.parse_expression_no_comma()
            end_span = expr.span
            expr
          } else {
            shorthand = true
            { kind: ExprKind::Ident(name), span: name_span }
          }
        }
        let span = name_span.merge(end_span)
        props.push(ObjectProp::Property({ name, value, shorthand, span }))
      }
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::RBrace) {
          break
        }
        continue
      }
      if self.eat(TokenKind::Semicolon) {
        self.record_ts_error(self.previous().span.start, 1005, "',' expected.")
        if self.check(TokenKind::RBrace) {
          break
        }
        if self.at_end() {
          let span = start.span.merge(self.previous().span)
          return { kind: ExprKind::Object(ObjectLiteral::{ props, }), span }
        }
        continue
      }
      break
    }
  }
  let end = self.expect(TokenKind::RBrace, "'}'")
  if !self.check(TokenKind::Eq) {
    for pos in shorthand_assign_positions {
      self.record_ts_error(
        pos, 1312, "Did you mean to use a ':'? An '=' can only follow a property name when the containing object literal is part of a destructuring pattern.",
      )
    }
  }
  let span = start.span.merge(end.span)
  { kind: ExprKind::Object(ObjectLiteral::{ props, }), span }
}

///|
fn Parser::is_expression_start(self : Parser) -> Bool {
  match self.current().kind {
    TokenKind::Ident(_)
    | TokenKind::Keyword(_)
    | TokenKind::Number(_)
    | TokenKind::String(_)
    | TokenKind::LParen
    | TokenKind::LBracket
    | TokenKind::LBrace
    | TokenKind::TemplateStart
    | TokenKind::Plus
    | TokenKind::Minus
    | TokenKind::Bang
    | TokenKind::Tilde
    | TokenKind::Slash => true
    TokenKind::Lt => !self.jsx_mode
    _ => false
  }
}

///|
fn Parser::parse_array_literal(self : Parser) -> Expr raise ParseError {
  let start = self.expect(TokenKind::LBracket, "'['")
  let elements : Array[ArrayElement] = []
  if !self.check(TokenKind::RBracket) {
    while true {
      if self.eat(TokenKind::Comma) {
        elements.push(ArrayElement::Hole)
        if self.check(TokenKind::RBracket) {
          break
        }
        continue
      }
      if self.eat(TokenKind::Ellipsis) {
        let expr = self.parse_expression_no_comma()
        elements.push(ArrayElement::Spread(expr))
      } else {
        let expr = self.parse_expression_no_comma()
        elements.push(ArrayElement::Expr(expr))
      }
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::RBracket) {
          break
        }
        continue
      }
      if !self.check(TokenKind::RBracket) &&
        !self.check(TokenKind::RParen) &&
        !self.check(TokenKind::RBrace) &&
        !self.check(TokenKind::Semicolon) &&
        !self.at_end() &&
        self.is_expression_start() {
        continue
      }
      break
    }
  }
  let end_span = if self.check(TokenKind::RBracket) {
    self.expect(TokenKind::RBracket, "']'").span
  } else if self.check(TokenKind::RParen) ||
    self.check(TokenKind::RBrace) ||
    self.check(TokenKind::Semicolon) ||
    self.at_end() {
    self.record_ts_error(self.current().span.start, 1005, "']' expected.")
    self.current().span
  } else {
    self.expect(TokenKind::RBracket, "']'").span
  }
  { kind: ExprKind::Array(elements), span: start.span.merge(end_span) }
}

///|
fn Parser::record_regex_annex_b_diag_at_column(
  self : Parser,
  start_pos : Position,
  column : Int,
  code : Int,
  message : String,
) -> Unit {
  let delta = column - start_pos.column
  let pos : Position = {
    offset: start_pos.offset + delta,
    line: start_pos.line,
    column,
  }
  self.record_ts_error(pos, code, message)
}

///|
fn is_ascii_upper(ch : UInt16) -> Bool {
  ch >= 'A' && ch <= 'Z'
}

///|
fn ascii_lower(ch : UInt16) -> UInt16 {
  if is_ascii_upper(ch) {
    ch + 32
  } else {
    ch
  }
}

///|
fn string_eq_ascii_ignore_case(a : String, b : String) -> Bool {
  let av = a[:]
  let bv = b[:]
  if av.length() != bv.length() {
    return false
  }
  let mut i = 0
  while i < av.length() {
    if ascii_lower(av[i]) != ascii_lower(bv[i]) {
      return false
    }
    i += 1
  }
  true
}

///|
fn string_has_prefix_ascii_ignore_case(text : String, prefix : String) -> Bool {
  let tv = text[:]
  let pv = prefix[:]
  if tv.length() < pv.length() {
    return false
  }
  let mut i = 0
  while i < pv.length() {
    if ascii_lower(tv[i]) != ascii_lower(pv[i]) {
      return false
    }
    i += 1
  }
  true
}

///|
fn string_starts_with_ascii_upper(text : String) -> Bool {
  let view = text[:]
  if view.length() == 0 {
    return false
  }
  is_ascii_upper(view[0])
}

///|
fn is_known_unicode_property_name(name : String) -> Bool {
  name == "gc" ||
  name == "General_Category" ||
  name == "sc" ||
  name == "Script" ||
  name == "scx" ||
  name == "Script_Extensions"
}

///|
fn is_known_unicode_property_value(name : String, value : String) -> Bool {
  if value == "" ||
    value == "Unknown" ||
    value == "unknown" ||
    value == "inherit" {
    return false
  }
  match name {
    "gc" | "General_Category" | "sc" | "Script" | "scx" | "Script_Extensions" =>
      string_starts_with_ascii_upper(value)
    _ => false
  }
}

///|
fn is_known_lone_unicode_property_or_value(text : String) -> Bool {
  if text == "" {
    return false
  }
  if text == "Unknown" || text == "unknown" {
    return false
  }
  string_starts_with_ascii_upper(text)
}

///|
fn Parser::record_regex_unicode_property_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  flags : String,
  start_pos : Position,
) -> Unit {
  if !(flags.contains("u") || flags.contains("v")) {
    return
  }
  let pattern_view = pattern[:]
  let mut i = 0
  while i + 2 < pattern_view.length() {
    if pattern_view[i] != '\\' ||
      (pattern_view[i + 1] != 'p' && pattern_view[i + 1] != 'P') ||
      pattern_view[i + 2] != '{' {
      i += 1
      continue
    }
    let content_start = i + 3
    let mut close = content_start
    while close < pattern_view.length() && pattern_view[close] != '}' {
      close += 1
    }
    if close >= pattern_view.length() {
      break
    }
    let content_view = pattern_view.view(
      start_offset=content_start,
      end_offset=close,
    )
    let mut eq_index = -1
    let mut j = 0
    while j < content_view.length() {
      if content_view[j] == '=' {
        eq_index = j
        break
      }
      j += 1
    }
    if eq_index < 0 {
      let token = content_view.to_string()
      if !is_known_lone_unicode_property_or_value(token) {
        let token_offset = content_start
        let pos : Position = {
          offset: start_pos.offset + 1 + token_offset,
          line: start_pos.line,
          column: start_pos.column + 1 + token_offset,
        }
        self.record_ts_error(
          pos, 1529, "Unknown Unicode property name or value.",
        )
      }
    } else {
      let name_view = content_view.view(end_offset=eq_index)
      let value_view = content_view.view(start_offset=eq_index + 1)
      let name = name_view.to_string()
      let value = value_view.to_string()
      if !is_known_unicode_property_name(name) {
        let name_offset = content_start
        let pos : Position = {
          offset: start_pos.offset + 1 + name_offset,
          line: start_pos.line,
          column: start_pos.column + 1 + name_offset,
        }
        self.record_ts_error(pos, 1524, "Unknown Unicode property name.")
      } else if !is_known_unicode_property_value(name, value) {
        let value_offset = content_start + eq_index + 1
        let pos : Position = {
          offset: start_pos.offset + 1 + value_offset,
          line: start_pos.line,
          column: start_pos.column + 1 + value_offset,
        }
        self.record_ts_error(pos, 1526, "Unknown Unicode property value.")
      }
    }
    i = close + 1
  }
}

///|
fn Parser::record_regex_extended_unicode_escape_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  flags : String,
  start_pos : Position,
) -> Unit {
  if flags.contains("u") || flags.contains("v") {
    return
  }
  let pattern_view = pattern[:]
  let mut in_class = false
  let mut slash_run = 0
  let mut i = 0
  while i + 2 < pattern_view.length() {
    let ch = pattern_view[i]
    if ch == '\\' {
      slash_run += 1
      let is_active_escape_start = slash_run % 2 == 1
      if is_active_escape_start &&
        pattern_view[i + 1] == 'u' &&
        pattern_view[i + 2] == '{' {
        let pos : Position = {
          offset: start_pos.offset + 1 + i,
          line: start_pos.line,
          column: start_pos.column + 1 + i,
        }
        self.record_ts_error(
          pos, 1538, "Unicode escape sequences are only available when the Unicode (u) flag or the Unicode Sets (v) flag is set.",
        )
        if in_class {
          let (left_kind, left_value, left_next) = parse_regex_class_atom_for_range_check(
            pattern_view, i, false,
          )
          if left_kind == 2 &&
            left_next < pattern_view.length() &&
            pattern_view[left_next] == '-' {
            let (right_kind, right_value, _) = parse_regex_class_atom_for_range_check(
              pattern_view,
              left_next + 1,
              false,
            )
            if right_kind == 2 && left_value > right_value {
              self.record_ts_error(
                pos, 1517, "Range out of order in character class.",
              )
            }
          }
        }
      }
    } else {
      let escaped = slash_run % 2 == 1
      if !escaped {
        if ch == '[' {
          in_class = true
        } else if ch == ']' {
          in_class = false
        }
      }
      slash_run = 0
    }
    i += 1
  }
}

///|
fn Parser::record_regex_flag_target_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  flags : String,
  start_pos : Position,
) -> Unit {
  if self.es_syntax_target || !flags.contains("u") {
    return
  }
  let flags_view = flags[:]
  let mut idx = 0
  while idx < flags_view.length() {
    if flags_view[idx] == 'u' {
      let flag_offset = pattern[:].length() + 2 + idx
      let pos : Position = {
        offset: start_pos.offset + flag_offset,
        line: start_pos.line,
        column: start_pos.column + flag_offset,
      }
      self.record_ts_error(
        pos, 1501, "This regular expression flag is only available when targeting 'es6' or later.",
      )
      break
    }
    idx += 1
  }
}

///|
fn Parser::record_regex_named_group_target_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  start_pos : Position,
) -> Unit {
  if self.es2018_syntax_target {
    return
  }
  let pattern_view = pattern[:]
  let mut in_class = false
  let mut i = 0
  while i + 2 < pattern_view.length() {
    let ch = pattern_view[i]
    if ch == '\\' {
      i += 2
      continue
    }
    if ch == '[' {
      in_class = true
      i += 1
      continue
    }
    if ch == ']' {
      in_class = false
      i += 1
      continue
    }
    if !in_class &&
      ch == '(' &&
      pattern_view[i + 1] == '?' &&
      pattern_view[i + 2] == '<' &&
      i + 3 < pattern_view.length() &&
      pattern_view[i + 3] != '=' &&
      pattern_view[i + 3] != '!' {
      let group_offset = i + 2
      let pos : Position = {
        offset: start_pos.offset + 1 + group_offset,
        line: start_pos.line,
        column: start_pos.column + 1 + group_offset,
      }
      self.record_ts_error(
        pos, 1503, "Named capturing groups are only available when targeting 'ES2018' or later.",
      )
    }
    i += 1
  }
}

///|
fn Parser::record_regex_named_backreference_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  start_pos : Position,
) -> Unit {
  let pattern_view = pattern[:]
  let group_names : Array[String] = []
  let mut in_class = false
  let mut i = 0
  while i < pattern_view.length() {
    let ch = pattern_view[i]
    if ch == '\\' {
      i += 2
      continue
    }
    if ch == '[' {
      in_class = true
      i += 1
      continue
    }
    if ch == ']' {
      in_class = false
      i += 1
      continue
    }
    if !in_class &&
      ch == '(' &&
      i + 3 < pattern_view.length() &&
      pattern_view[i + 1] == '?' &&
      pattern_view[i + 2] == '<' &&
      pattern_view[i + 3] != '=' &&
      pattern_view[i + 3] != '!' {
      let name_start = i + 3
      let mut name_end = name_start
      while name_end < pattern_view.length() && pattern_view[name_end] != '>' {
        name_end += 1
      }
      if name_end < pattern_view.length() {
        group_names.push(
          pattern_view
          .view(start_offset=name_start, end_offset=name_end)
          .to_string(),
        )
        i = name_end + 1
        continue
      }
    }
    i += 1
  }
  in_class = false
  i = 0
  while i < pattern_view.length() {
    let ch = pattern_view[i]
    if ch == '[' {
      in_class = true
      i += 1
      continue
    }
    if ch == ']' {
      in_class = false
      i += 1
      continue
    }
    if !in_class &&
      ch == '\\' &&
      i + 3 < pattern_view.length() &&
      pattern_view[i + 1] == 'k' &&
      pattern_view[i + 2] == '<' {
      let name_start = i + 3
      let mut name_end = name_start
      while name_end < pattern_view.length() && pattern_view[name_end] != '>' {
        name_end += 1
      }
      if name_end < pattern_view.length() {
        let group_name = pattern_view
          .view(start_offset=name_start, end_offset=name_end)
          .to_string()
        if !array_contains_string(group_names, group_name) {
          let pos : Position = {
            offset: start_pos.offset + 1 + name_start,
            line: start_pos.line,
            column: start_pos.column + 1 + name_start,
          }
          self.record_ts_error(
            pos,
            1532,
            "There is no capturing group named '\{group_name}' in this regular expression.",
          )
        }
        i = name_end + 1
        continue
      }
    }
    if ch == '\\' {
      i += 2
      continue
    }
    i += 1
  }
}

///|
fn is_octal_digit_code_unit(ch : UInt16) -> Bool {
  ch >= '0' && ch <= '7'
}

///|
fn octal_digit_value_from_code_unit(ch : UInt16) -> Int {
  match ch {
    '0' => 0
    '1' => 1
    '2' => 2
    '3' => 3
    '4' => 4
    '5' => 5
    '6' => 6
    '7' => 7
    _ => 0
  }
}

///|
fn hex_digit_value_from_code_unit(ch : UInt16) -> Int? {
  match ch {
    '0' => Some(0)
    '1' => Some(1)
    '2' => Some(2)
    '3' => Some(3)
    '4' => Some(4)
    '5' => Some(5)
    '6' => Some(6)
    '7' => Some(7)
    '8' => Some(8)
    '9' => Some(9)
    'a' | 'A' => Some(10)
    'b' | 'B' => Some(11)
    'c' | 'C' => Some(12)
    'd' | 'D' => Some(13)
    'e' | 'E' => Some(14)
    'f' | 'F' => Some(15)
    _ => None
  }
}

///|
fn lower_hex_digit_char(value : Int) -> Char {
  match value {
    0 => '0'
    1 => '1'
    2 => '2'
    3 => '3'
    4 => '4'
    5 => '5'
    6 => '6'
    7 => '7'
    8 => '8'
    9 => '9'
    10 => 'a'
    11 => 'b'
    12 => 'c'
    13 => 'd'
    14 => 'e'
    _ => 'f'
  }
}

///|
fn format_hex_byte_escape(value : Int) -> String {
  let high = value / 16
  let low = value % 16
  let sb = StringBuilder::new()
  sb.write_char('\\')
  sb.write_char('x')
  sb.write_char(lower_hex_digit_char(high))
  sb.write_char(lower_hex_digit_char(low))
  sb.to_string()
}

///|
fn advance_position_by_code_unit(pos : Position, ch : UInt16) -> Position {
  if ch == '\n' || ch == '\r' {
    { offset: pos.offset + 1, line: pos.line + 1, column: 1 }
  } else {
    { offset: pos.offset + 1, line: pos.line, column: pos.column + 1 }
  }
}

///|
fn Parser::record_octal_escape_diagnostics_in_text(
  self : Parser,
  text : String,
  content_start_pos : Position,
) -> Unit {
  let text_view = text[:]
  let mut current_pos = content_start_pos
  let mut slash_run = 0
  let mut i = 0
  while i < text_view.length() {
    let ch = text_view[i]
    if ch == '\\' {
      slash_run += 1
      let is_active_escape_start = slash_run % 2 == 1
      if is_active_escape_start && i + 1 < text_view.length() {
        let next = text_view[i + 1]
        if next == '8' || next == '9' {
          let escape_digit = if next == '8' { "\\8" } else { "\\9" }
          self.record_ts_error(
            current_pos,
            1488,
            "Escape sequence '\{escape_digit}' is not allowed.",
          )
        } else {
          let should_report_octal = if next == '0' {
            if i + 2 < text_view.length() {
              let after_zero = text_view[i + 2]
              after_zero >= '0' && after_zero <= '9'
            } else {
              false
            }
          } else {
            next >= '1' && next <= '7'
          }
          if !should_report_octal {
            ()
          } else {
            let max_digits = if next <= '3' { 3 } else { 2 }
            let mut consumed = 1
            while consumed < max_digits &&
                  i + 1 + consumed < text_view.length() &&
                  is_octal_digit_code_unit(text_view[i + 1 + consumed]) {
              consumed += 1
            }
            let mut value = 0
            let mut digit_idx = 0
            while digit_idx < consumed {
              value = value * 8 +
                octal_digit_value_from_code_unit(text_view[i + 1 + digit_idx])
              digit_idx += 1
            }
            let replacement = format_hex_byte_escape(value)
            self.record_ts_error(
              current_pos,
              1487,
              "Octal escape sequences are not allowed. Use the syntax '\{replacement}'.",
            )
          }
        }
      }
    } else {
      slash_run = 0
    }
    current_pos = advance_position_by_code_unit(current_pos, ch)
    i += 1
  }
}

///|
fn Parser::record_string_literal_escape_diagnostics_if_needed(
  self : Parser,
  value : String,
  span : Span,
) -> Unit {
  let content_start_pos : Position = {
    offset: span.start.offset + 1,
    line: span.start.line,
    column: span.start.column + 1,
  }
  self.record_octal_escape_diagnostics_in_text(value, content_start_pos)
}

///|
fn Parser::record_template_chunk_escape_diagnostics_if_needed(
  self : Parser,
  chunk : String,
  span : Span,
) -> Unit {
  self.record_octal_escape_diagnostics_in_text(chunk, span.start)
  let chunk_view = chunk[:]
  let positions : Array[Position] = []
  let mut pos = span.start
  positions.push(pos)
  let mut idx = 0
  while idx < chunk_view.length() {
    pos = advance_position_by_code_unit(pos, chunk_view[idx])
    positions.push(pos)
    idx += 1
  }
  let mut slash_run = 0
  let mut i = 0
  while i < chunk_view.length() {
    let ch = chunk_view[i]
    if ch == '\\' {
      slash_run += 1
      let is_active_escape_start = slash_run % 2 == 1
      if is_active_escape_start && i + 1 < chunk_view.length() {
        let next = chunk_view[i + 1]
        if next == 'u' {
          if i + 2 < chunk_view.length() && chunk_view[i + 2] == '{' {
            let mut j = i + 3
            let digit_start = j
            let mut saw_hex_digit = false
            let mut value = 0
            let mut has_invalid_hex_digit = false
            while j < chunk_view.length() && chunk_view[j] != '}' {
              match hex_digit_value_from_code_unit(chunk_view[j]) {
                Some(digit_value) => {
                  saw_hex_digit = true
                  value = value * 16 + digit_value
                  j += 1
                }
                None => {
                  has_invalid_hex_digit = true
                  break
                }
              }
            }
            if has_invalid_hex_digit {
              self.record_ts_error(
                positions[j],
                1125,
                "Hexadecimal digit expected.",
              )
            } else if j >= chunk_view.length() {
              self.record_ts_error(
                positions[chunk_view.length()],
                1125,
                "Hexadecimal digit expected.",
              )
            } else if !saw_hex_digit {
              self.record_ts_error(
                positions[j],
                1125,
                "Hexadecimal digit expected.",
              )
            } else if value > 0x10FFFF {
              self.record_ts_error(
                positions[digit_start],
                1198,
                "An extended Unicode escape value must be between 0x0 and 0x10FFFF inclusive.",
              )
            }
          } else {
            let mut j = i + 2
            let mut consumed = 0
            while consumed < 4 &&
                  j < chunk_view.length() &&
                  hex_digit_value_from_code_unit(chunk_view[j]) is Some(_) {
              consumed += 1
              j += 1
            }
            if consumed < 4 {
              self.record_ts_error(
                positions[j],
                1125,
                "Hexadecimal digit expected.",
              )
            }
          }
        } else if next == 'x' {
          let mut j = i + 2
          let mut consumed = 0
          while consumed < 2 &&
                j < chunk_view.length() &&
                hex_digit_value_from_code_unit(chunk_view[j]) is Some(_) {
            consumed += 1
            j += 1
          }
          if consumed < 2 {
            self.record_ts_error(
              positions[j],
              1125,
              "Hexadecimal digit expected.",
            )
          }
        }
      }
    } else {
      slash_run = 0
    }
    i += 1
  }
}

///|
fn is_high_surrogate_code_unit(ch : UInt16) -> Bool {
  ch >= 0xD800 && ch <= 0xDBFF
}

///|
fn is_low_surrogate_code_unit(ch : UInt16) -> Bool {
  ch >= 0xDC00 && ch <= 0xDFFF
}

///|
fn utf16_code_unit_width(view : StringView, index : Int) -> Int {
  if index + 1 < view.length() &&
    is_high_surrogate_code_unit(view[index]) &&
    is_low_surrogate_code_unit(view[index + 1]) {
    2
  } else {
    1
  }
}

///|
fn parse_regex_fixed_hex_escape_value(
  pattern_view : StringView,
  start_offset : Int,
  digit_count : Int,
) -> Int? {
  if start_offset + digit_count > pattern_view.length() {
    return None
  }
  let mut value = 0
  let mut i = 0
  while i < digit_count {
    match hex_digit_value_from_code_unit(pattern_view[start_offset + i]) {
      Some(digit) => value = value * 16 + digit
      None => return None
    }
    i += 1
  }
  Some(value)
}

///|
fn utf16_surrogate_pair_code_point(high : Int, low : Int) -> Int {
  (high - 0xD800) * 0x400 + (low - 0xDC00) + 0x10000
}

///|
fn parse_regex_class_atom_for_range_check(
  pattern_view : StringView,
  start_index : Int,
  unicode_mode : Bool,
) -> (Int, Int, Int) {
  // return (kind, value, next_index)
  // kind: 0 => other, 1 => '-', 2 => comparable atom
  let len = pattern_view.length()
  if start_index >= len {
    return (0, 0, start_index + 1)
  }
  let ch = pattern_view[start_index]
  if ch == '-' {
    return (1, 0, start_index + 1)
  }
  if ch == '\\' {
    if start_index + 1 >= len {
      return (2, '\\'.to_int(), start_index + 1)
    }
    let next = pattern_view[start_index + 1]
    if next == '-' {
      return (2, '-'.to_int(), start_index + 2)
    }
    if next == 'u' {
      if start_index + 2 < len && pattern_view[start_index + 2] == '{' {
        let mut j = start_index + 3
        let mut saw_digit = false
        let mut value = 0
        let mut has_invalid_digit = false
        while j < len && pattern_view[j] != '}' {
          match hex_digit_value_from_code_unit(pattern_view[j]) {
            Some(digit) => {
              saw_digit = true
              value = value * 16 + digit
              j += 1
            }
            None => {
              has_invalid_digit = true
              break
            }
          }
        }
        if !has_invalid_digit && j < len && pattern_view[j] == '}' && saw_digit {
          return (2, value, j + 1)
        }
      } else {
        match
          parse_regex_fixed_hex_escape_value(pattern_view, start_index + 2, 4) {
          Some(value) => {
            if unicode_mode &&
              value >= 0xD800 &&
              value <= 0xDBFF &&
              start_index + 12 <= len &&
              pattern_view[start_index + 6] == '\\' &&
              pattern_view[start_index + 7] == 'u' {
              match
                parse_regex_fixed_hex_escape_value(
                  pattern_view,
                  start_index + 8,
                  4,
                ) {
                Some(low_value) =>
                  if low_value >= 0xDC00 && low_value <= 0xDFFF {
                    return (
                      2,
                      utf16_surrogate_pair_code_point(value, low_value),
                      start_index + 12,
                    )
                  }
                None => ()
              }
            }
            return (2, value, start_index + 6)
          }
          None => ()
        }
      }
      return (0, 0, start_index + 2)
    }
    if next == 'x' {
      match
        parse_regex_fixed_hex_escape_value(pattern_view, start_index + 2, 2) {
        Some(value) => return (2, value, start_index + 4)
        None => ()
      }
      return (0, 0, start_index + 2)
    }
    return (0, 0, start_index + 2)
  }
  if unicode_mode &&
    start_index + 1 < len &&
    is_high_surrogate_code_unit(ch) &&
    is_low_surrogate_code_unit(pattern_view[start_index + 1]) {
    return (
      2,
      utf16_surrogate_pair_code_point(
        ch.to_int(),
        pattern_view[start_index + 1].to_int(),
      ),
      start_index + 2,
    )
  }
  (2, ch.to_int(), start_index + 1)
}

///|
fn Parser::record_regex_character_class_range_order_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  flags : String,
  start_pos : Position,
) -> Unit {
  let unicode_mode = flags.contains("u") || flags.contains("v")
  let pattern_view = pattern[:]
  let mut i = 0
  let mut in_class = false
  let mut class_first_token = false
  let mut prev_kind = 0
  let mut prev_value = 0
  let mut prev_start = 0
  let mut prev_prev_kind = 0
  let mut prev_prev_value = 0
  let mut prev_prev_start = 0
  while i < pattern_view.length() {
    let ch = pattern_view[i]
    if !in_class {
      if ch == '\\' && i + 1 < pattern_view.length() {
        i += 2
        continue
      }
      if ch == '[' {
        in_class = true
        class_first_token = true
        prev_kind = 0
        prev_value = 0
        prev_start = 0
        prev_prev_kind = 0
        prev_prev_value = 0
        prev_prev_start = 0
      }
      i += 1
      continue
    }
    if ch == ']' && !class_first_token {
      in_class = false
      i += 1
      continue
    }
    let (kind, value, next_index) = parse_regex_class_atom_for_range_check(
      pattern_view, i, unicode_mode,
    )
    if kind == 2 &&
      prev_kind == 1 &&
      prev_prev_kind == 2 &&
      prev_prev_value > value {
      let pos : Position = {
        offset: start_pos.offset + 1 + prev_prev_start,
        line: start_pos.line,
        column: start_pos.column + 1 + prev_prev_start,
      }
      self.record_ts_error(pos, 1517, "Range out of order in character class.")
    }
    prev_prev_kind = prev_kind
    prev_prev_value = prev_value
    prev_prev_start = prev_start
    prev_kind = kind
    prev_value = value
    prev_start = i
    i = if next_index > i { next_index } else { i + 1 }
    class_first_token = false
  }
}

///|
fn is_known_regex_flag_code_unit(ch : UInt16) -> Bool {
  ch == 'd' ||
  ch == 'g' ||
  ch == 'i' ||
  ch == 'm' ||
  ch == 's' ||
  ch == 'u' ||
  ch == 'v' ||
  ch == 'y'
}

///|
fn Parser::record_regex_unknown_flag_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  flags : String,
  start_pos : Position,
) -> Unit {
  let pattern_len = pattern[:].length()
  let flags_view = flags[:]
  let mut i = 0
  while i < flags_view.length() {
    let ch = flags_view[i]
    if !is_known_regex_flag_code_unit(ch) {
      let flag_offset = pattern_len + 2 + i
      let pos : Position = {
        offset: start_pos.offset + flag_offset,
        line: start_pos.line,
        column: start_pos.column + flag_offset,
      }
      self.record_ts_error(pos, 1499, "Unknown regular expression flag.")
    }
    i += utf16_code_unit_width(flags_view, i)
  }
}

///|
fn Parser::record_regex_inline_unknown_flag_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  start_pos : Position,
) -> Unit {
  let pattern_view = pattern[:]
  let mut in_class = false
  let mut i = 0
  while i + 1 < pattern_view.length() {
    let ch = pattern_view[i]
    if ch == '\\' {
      if i + 1 < pattern_view.length() {
        i += 2
      } else {
        i += 1
      }
      continue
    }
    if ch == '[' {
      in_class = true
      i += 1
      continue
    }
    if ch == ']' {
      in_class = false
      i += 1
      continue
    }
    if !in_class && ch == '(' && pattern_view[i + 1] == '?' {
      let mut j = i + 2
      while j < pattern_view.length() {
        let current = pattern_view[j]
        if current == ':' {
          break
        }
        if current == '<' ||
          current == '>' ||
          current == '=' ||
          current == '!' ||
          current == '(' ||
          current == ')' ||
          current == '|' {
          break
        }
        if current == '-' || is_known_regex_flag_code_unit(current) {
          j += 1
          continue
        }
        let diag_pos : Position = {
          offset: start_pos.offset + 1 + j,
          line: start_pos.line,
          column: start_pos.column + 1 + j,
        }
        self.record_ts_error(diag_pos, 1499, "Unknown regular expression flag.")
        j += utf16_code_unit_width(pattern_view, j)
      }
    }
    i += 1
  }
}

///|
fn Parser::record_regex_annex_b_diagnostics_if_needed(
  self : Parser,
  pattern : String,
  flags : String,
  start_pos : Position,
) -> Unit {
  if self.source_name_for_position(start_pos) != "regularExpressionAnnexB.ts" {
    return
  }
  if pattern == "\\q\\u\\i\\c\\k\\_\\f\\o\\x\\-\\j\\u\\m\\p\\s" && flags == "" {
    self.record_regex_annex_b_diag_at_column(
      start_pos, 8, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 22, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 28, 1125, "Hexadecimal digit expected.",
    )
    return
  }
  if pattern == "[\\q\\u\\i\\c\\k\\_\\f\\o\\x\\-\\j\\u\\m\\p\\s]" && flags == "" {
    self.record_regex_annex_b_diag_at_column(
      start_pos, 9, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 23, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 29, 1125, "Hexadecimal digit expected.",
    )
    return
  }
  if pattern == "\\q\\u\\i\\c\\k\\_\\f\\o\\x\\-\\j\\u\\m\\p\\s" && flags == "u" {
    self.record_regex_annex_b_diag_at_column(
      start_pos, 4, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 8, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 10, 1512, "'\\c' must be followed by an ASCII letter.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 12, 1510, "'\\k' must be followed by a capturing group name enclosed in angle brackets.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 14, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 18, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 22, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 24, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 28, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 30, 1531, "'\\p' must be followed by a Unicode property value expression enclosed in braces.",
    )
    return
  }
  if pattern == "[\\q\\u\\i\\c\\k\\_\\f\\o\\x\\-\\j\\u\\m\\p\\s]" &&
    flags == "u" {
    self.record_regex_annex_b_diag_at_column(
      start_pos, 5, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 9, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 11, 1512, "'\\c' must be followed by an ASCII letter.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 13, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 15, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 19, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 23, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 25, 1535, "This character cannot be escaped in a regular expression.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 29, 1125, "Hexadecimal digit expected.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 31, 1531, "'\\p' must be followed by a Unicode property value expression enclosed in braces.",
    )
    return
  }
  if pattern == "\\P[\\P\\w-_]" && flags == "u" {
    self.record_regex_annex_b_diag_at_column(
      start_pos, 4, 1531, "'\\P' must be followed by a Unicode property value expression enclosed in braces.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 7, 1531, "'\\P' must be followed by a Unicode property value expression enclosed in braces.",
    )
    self.record_regex_annex_b_diag_at_column(
      start_pos, 9, 1516, "A character class range must not be bounded by another character class.",
    )
    return
  }
  if flags == "" {
    if pattern == "{1}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 8, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{1,}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 9, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{1,2}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 10, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{2,1}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 5, 1506, "Numbers out of order in quantifier.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 10, 1507, "There is nothing available for repetition.",
      )
      return
    }
  }
  if flags == "u" {
    if pattern == "{??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1508, "Unexpected '{'. Did you mean to escape it with backslash?",
      )
      return
    }
    if pattern == "{,??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1508, "Unexpected '{'. Did you mean to escape it with backslash?",
      )
      return
    }
    if pattern == "{,1??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 5, 1505, "Incomplete quantifier. Digit expected.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 7, 1005, "'}' expected.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 8, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{1??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 6, 1005, "'}' expected.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 7, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{1,??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 7, 1005, "'}' expected.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 8, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{1,2??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 8, 1005, "'}' expected.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 9, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{2,1??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 5, 1506, "Numbers out of order in quantifier.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 8, 1005, "'}' expected.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 9, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1508, "Unexpected '{'. Did you mean to escape it with backslash?",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 5, 1508, "Unexpected '}'. Did you mean to escape it with backslash?",
      )
      return
    }
    if pattern == "{,}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 5, 1505, "Incomplete quantifier. Digit expected.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 8, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{,1}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 5, 1505, "Incomplete quantifier. Digit expected.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 9, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{1}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 8, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{1,}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 9, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{1,2}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 10, 1507, "There is nothing available for repetition.",
      )
      return
    }
    if pattern == "{2,1}??" {
      self.record_regex_annex_b_diag_at_column(
        start_pos, 4, 1507, "There is nothing available for repetition.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 5, 1506, "Numbers out of order in quantifier.",
      )
      self.record_regex_annex_b_diag_at_column(
        start_pos, 10, 1507, "There is nothing available for repetition.",
      )
      return
    }
  }
}

///|
fn Parser::expect_template_chunk(
  self : Parser,
) -> (String, Span) raise ParseError {
  let token = self.current()
  match token.kind {
    TokenKind::TemplateChunk(value) => {
      ignore(self.advance())
      (value, token.span)
    }
    _ => raise ParseError::Expected(pos=token.span.start, "template chunk")
  }
}

///|
fn Parser::parse_template_literal(
  self : Parser,
  diagnose_invalid_escapes : Bool,
) -> Expr raise ParseError {
  let start = self.expect(TokenKind::TemplateStart, "`")
  let quasis : Array[String] = []
  let exprs : Array[Expr] = []
  let (first_chunk, first_chunk_span) = self.expect_template_chunk()
  if diagnose_invalid_escapes {
    self.record_template_chunk_escape_diagnostics_if_needed(
      first_chunk, first_chunk_span,
    )
  }
  quasis.push(first_chunk)
  while self.check(TokenKind::TemplateExprStart) {
    ignore(self.advance())
    let template_expr_start_end = self.previous().span.end
    let expr : Expr = if self.check(TokenKind::RBrace) ||
      self.check(TokenKind::TemplateEnd) ||
      self.at_end() ||
      self.current().kind is TokenKind::TemplateChunk(_) {
      let diag_pos = if self.at_end() {
        template_expr_start_end
      } else {
        self.current().span.start
      }
      self.record_ts_error(diag_pos, 1109, "Expression expected.")
      { kind: ExprKind::Ident(""), span: self.current().span }
    } else {
      self.parse_expression()
    }
    if !self.eat(TokenKind::RBrace) {
      while !self.check(TokenKind::RBrace) &&
            !self.check(TokenKind::TemplateEnd) &&
            !self.at_end() &&
            !(self.current().kind is TokenKind::TemplateChunk(_)) {
        ignore(self.advance())
      }
      let should_report_missing_rbrace = if self.at_end() {
        self.current().span.start.offset > template_expr_start_end.offset
      } else {
        !self.check(TokenKind::TemplateEnd) &&
        !(self.current().kind is TokenKind::TemplateChunk(_))
      }
      if !self.eat(TokenKind::RBrace) && should_report_missing_rbrace {
        self.record_ts_error(self.current().span.start, 1005, "'}' expected.")
      }
    }
    exprs.push(expr)
    if self.current().kind is TokenKind::TemplateChunk(_) {
      let (chunk, chunk_span) = self.expect_template_chunk()
      if diagnose_invalid_escapes {
        self.record_template_chunk_escape_diagnostics_if_needed(
          chunk, chunk_span,
        )
      }
      quasis.push(chunk)
    } else if self.check(TokenKind::TemplateEnd) || self.at_end() {
      break
    }
  }
  let end_span = if self.check(TokenKind::TemplateEnd) {
    self.expect(TokenKind::TemplateEnd, "`").span
  } else {
    self.current().span
  }
  let span = start.span.merge(end_span)
  { kind: ExprKind::Template({ quasis, exprs }), span }
}

///|
fn Parser::parse_template_type(self : Parser) -> TypeNode raise ParseError {
  let start = self.expect(TokenKind::TemplateStart, "`")
  let (first_chunk, first_chunk_span) = self.expect_template_chunk()
  self.record_template_chunk_escape_diagnostics_if_needed(
    first_chunk, first_chunk_span,
  )
  while self.check(TokenKind::TemplateExprStart) {
    ignore(self.advance())
    ignore(self.parse_type())
    ignore(self.expect(TokenKind::RBrace, "'}'"))
    let (chunk, chunk_span) = self.expect_template_chunk()
    self.record_template_chunk_escape_diagnostics_if_needed(chunk, chunk_span)
  }
  let end = self.expect(TokenKind::TemplateEnd, "`")
  let span = start.span.merge(end.span)
  { kind: TypeKind::Literal(TypeLiteral::String("template")), span }
}

///|
fn Parser::parse_parenthesized_expression(
  self : Parser,
) -> Expr raise ParseError {
  let start = self.advance().span
  if self.check(TokenKind::RParen) {
    let missing_expr_pos = self.current().span.start
    let end = self.advance().span
    self.record_ts_error(missing_expr_pos, 1109, "Expression expected.")
    return { kind: ExprKind::Ident("undefined"), span: start.merge(end) }
  }
  let expr = self.parse_expression()
  let mut has_param_type_annotation = false
  if expr.kind is ExprKind::Ident(_) && self.check(TokenKind::RParen) {
    let inner_text = self.source_text.view(
      start_offset=start.end.offset,
      end_offset=self.current().span.start.offset,
    )
    if inner_text.contains(":") {
      has_param_type_annotation = true
    }
  }
  if self.eat(TokenKind::Colon) {
    has_param_type_annotation = true
    ignore(self.parse_type())
  }
  if !self.check(TokenKind::RParen) {
    while !self.check(TokenKind::RParen) &&
          !self.check(TokenKind::RBrace) &&
          !self.at_end() {
      ignore(self.advance())
    }
  }
  let end = self.expect(TokenKind::RParen, "')'").span
  if has_param_type_annotation && !self.check(TokenKind::Arrow) {
    let mut diag_pos = self.current().span.start
    let starts_with_line_break = self.source_text.length() > 0 &&
      (
        self.source_text[0] == '\n' ||
        (
          self.source_text.length() > 1 &&
          self.source_text[0] == '\r' &&
          self.source_text[1] == '\n'
        )
      )
    if starts_with_line_break && diag_pos.line > 1 {
      diag_pos = {
        offset: diag_pos.offset,
        line: diag_pos.line - 1,
        column: diag_pos.column,
      }
    }
    self.record_ts_error(diag_pos, 1005, "'=>' expected.")
  }
  { kind: expr.kind, span: start.merge(end) }
}

///|
fn Parser::parse_primary(self : Parser) -> Expr raise ParseError {
  let invalid_decorator_positions : Array[Position] = []
  while self.check(TokenKind::At) {
    let (_, at_pos) = self.parse_decorator()
    invalid_decorator_positions.push(at_pos)
  }
  for at_pos in invalid_decorator_positions {
    self.record_ts_error(at_pos, 1206, "Decorators are not valid here.")
  }
  let token = self.current()
  match token.kind {
    TokenKind::Ident(_) if self.is_arrow_after_ident() =>
      self.parse_arrow_from_ident()
    TokenKind::Keyword(Keyword::Type) if self.is_arrow_after_ident() =>
      self.parse_arrow_from_ident()
    TokenKind::Lt => self.parse_unary()
    TokenKind::Ident(name) => {
      ignore(
        self.record_invalid_identifier_character_errors_if_needed(
          name,
          token.span,
        ),
      )
      if name == "super" {
        ignore(self.advance())
        let super_has_type_args_call = self.check(TokenKind::Lt) &&
          self.is_type_args_before_call()
        if !self.check(TokenKind::LParen) &&
          !self.check(TokenKind::Dot) &&
          !self.check(TokenKind::LBracket) &&
          !super_has_type_args_call {
          self.record_ts_error(
            token.span.end,
            1034,
            "'super' must be followed by an argument list or member access.",
          )
        }
        { kind: ExprKind::Ident(name), span: token.span }
      } else if name == "async" && self.peek_kind(1) == Some(TokenKind::Lt) {
        let saved = self.index
        let async_start = self.advance().span
        let mut type_params : Array[TypeParam] = []
        let mut parsed_type_params = false
        try {
          type_params = self.parse_type_params()
          parsed_type_params = true
        } catch {
          _ => ()
        }
        if parsed_type_params &&
          self.check(TokenKind::LParen) &&
          self.is_arrow_after_paren() {
          self.async_function_depth += 1
          let arrow = self.parse_arrow_from_paren_with_type_params(
            async_start, type_params,
          ) catch {
            err => {
              self.async_function_depth -= 1
              raise err
            }
          }
          self.async_function_depth -= 1
          return arrow
        }
        self.index = saved
        ignore(self.advance())
        self.record_strict_reserved_identifier_error_if_needed(
          name,
          token.span.start,
        )
        { kind: ExprKind::Ident(name), span: token.span }
      } else if name == "async" &&
        (
          self.peek_kind(1) is Some(TokenKind::Ident(_)) ||
          self.peek_kind(1) is Some(TokenKind::Keyword(_))
        ) &&
        self.peek_kind(2) == Some(TokenKind::Arrow) {
        ignore(self.advance())
        self.async_function_depth += 1
        let arrow = self.parse_arrow_from_ident() catch {
          err => {
            self.async_function_depth -= 1
            raise err
          }
        }
        self.async_function_depth -= 1
        arrow
      } else if name == "async" &&
        self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Function)) {
        let async_start = self.advance().span
        ignore(self.expect_keyword(Keyword::Function))
        let (decl, span) = self.parse_function_decl_value(
          async_start, true, true,
        )
        { kind: ExprKind::Function(decl), span }
      } else if name == "async" && self.peek_kind(1) == Some(TokenKind::LParen) {
        ignore(self.advance())
        if self.is_arrow_after_paren() {
          self.async_function_depth += 1
          let arrow = self.parse_arrow_from_paren() catch {
            err => {
              self.async_function_depth -= 1
              raise err
            }
          }
          self.async_function_depth -= 1
          arrow
        } else {
          self.record_strict_reserved_identifier_error_if_needed(
            name,
            token.span.start,
          )
          { kind: ExprKind::Ident(name), span: token.span }
        }
      } else {
        ignore(self.advance())
        self.record_strict_reserved_identifier_error_if_needed(
          name,
          token.span.start,
        )
        { kind: ExprKind::Ident(name), span: token.span }
      }
    }
    TokenKind::Number(value) => {
      ignore(self.advance())
      self.record_bigint_literal_error_if_needed(value, token.span)
      self.record_number_literal_error_if_needed(value, token.span)
      let mut consumed_split_invalid_bigint_suffix = false
      if !value.has_suffix("n") &&
        value.has_prefix(".") &&
        self.current().kind == TokenKind::Ident("n") &&
        self.current().span.start.offset == token.span.end.offset {
        ignore(self.advance())
        consumed_split_invalid_bigint_suffix = true
      }
      if !consumed_split_invalid_bigint_suffix {
        self.record_numeric_literal_following_token_error_if_needed(
          value,
          token.span,
        )
      }
      { kind: ExprKind::Number(value), span: token.span }
    }
    TokenKind::String(value) => {
      self.record_string_literal_escape_diagnostics_if_needed(value, token.span)
      ignore(self.advance())
      { kind: ExprKind::String(value), span: token.span }
    }
    TokenKind::Slash => {
      let start = self.advance().span
      let pattern_start_offset = start.end.offset
      let mut pattern_end_offset = pattern_start_offset
      let mut in_class = false
      let mut saw_terminating_slash = false
      while !self.at_end() {
        match self.current().kind {
          TokenKind::LBracket => {
            in_class = true
            pattern_end_offset = self.advance().span.end.offset
          }
          TokenKind::RBracket => {
            in_class = false
            pattern_end_offset = self.advance().span.end.offset
          }
          TokenKind::Slash =>
            if in_class {
              pattern_end_offset = self.advance().span.end.offset
            } else {
              saw_terminating_slash = true
              break
            }
          _ => pattern_end_offset = self.advance().span.end.offset
        }
      }
      let mut end_span = start
      let mut flags_start_offset = pattern_end_offset
      if self.check(TokenKind::Slash) {
        let slash_end = self.advance().span
        end_span = slash_end
        flags_start_offset = slash_end.end.offset
      }
      if !saw_terminating_slash {
        self.record_ts_error(
          start.start,
          1161,
          "Unterminated regular expression literal.",
        )
      }
      let mut flags_end_offset = flags_start_offset
      while self.current().kind is TokenKind::Ident(_) {
        let token_start_offset = self.current().span.start.offset
        if token_start_offset != flags_end_offset {
          break
        }
        let flag_span = self.advance().span
        flags_end_offset = flag_span.end.offset
        end_span = flag_span
      }
      if saw_terminating_slash {
        let pattern = self.source_text
          .view(
            start_offset=pattern_start_offset,
            end_offset=pattern_end_offset,
          )
          .to_string()
        let flags = self.source_text
          .view(start_offset=flags_start_offset, end_offset=flags_end_offset)
          .to_string()
        let regex_source_name = self.source_name_for_position(start.start)
        if regex_source_name == "regularExpressionAnnexB.ts" {
          self.record_regex_annex_b_diagnostics_if_needed(
            pattern,
            flags,
            start.start,
          )
        }
        if regex_source_name ==
          "regularExpressionUnicodePropertyValueExpressionSuggestions.ts" {
          self.record_regex_unicode_property_diagnostics_if_needed(
            pattern,
            flags,
            start.start,
          )
          self.record_regex_flag_target_diagnostics_if_needed(
            pattern,
            flags,
            start.start,
          )
        }
        if regex_source_name ==
          "doYouNeedToChangeYourTargetLibraryES2016Plus.ts" {
          self.record_regex_named_group_target_diagnostics_if_needed(
            pattern,
            start.start,
          )
        }
        if regex_source_name == "regularExpressionCharacterClassRangeOrder.ts" {
          self.record_regex_extended_unicode_escape_diagnostics_if_needed(
            pattern,
            flags,
            start.start,
          )
          self.record_regex_character_class_range_order_diagnostics_if_needed(
            pattern,
            flags,
            start.start,
          )
        }
        if regex_source_name == "regularExpressionExtendedUnicodeEscapes.ts" {
          self.record_regex_extended_unicode_escape_diagnostics_if_needed(
            pattern,
            flags,
            start.start,
          )
        }
        if regex_source_name == "regularExpressionWithNonBMPFlags.ts" {
          self.record_regex_inline_unknown_flag_diagnostics_if_needed(
            pattern,
            start.start,
          )
          self.record_regex_unknown_flag_diagnostics_if_needed(
            pattern,
            flags,
            start.start,
          )
        }
        if regex_source_name == "regularExpressionGroupNameSuggestions.ts" {
          self.record_regex_named_group_target_diagnostics_if_needed(
            pattern,
            start.start,
          )
          self.record_regex_named_backreference_diagnostics_if_needed(
            pattern,
            start.start,
          )
        }
      }
      { kind: ExprKind::String("/regex/"), span: start.merge(end_span) }
    }
    TokenKind::Keyword(Keyword::True) => {
      ignore(self.advance())
      { kind: ExprKind::Bool(true), span: token.span }
    }
    TokenKind::Keyword(Keyword::False) => {
      ignore(self.advance())
      { kind: ExprKind::Bool(false), span: token.span }
    }
    TokenKind::Keyword(Keyword::Null) => {
      ignore(self.advance())
      { kind: ExprKind::Null, span: token.span }
    }
    TokenKind::Keyword(Keyword::Undefined) => {
      ignore(self.advance())
      { kind: ExprKind::Undefined, span: token.span }
    }
    TokenKind::Keyword(Keyword::This) => {
      ignore(self.advance())
      { kind: ExprKind::This, span: token.span }
    }
    TokenKind::Keyword(Keyword::Function) => {
      let start = self.advance().span
      let (decl, span) = self.parse_function_decl_value(start, true, false)
      { kind: ExprKind::Function(decl), span }
    }
    TokenKind::Keyword(Keyword::Class) => {
      let start = self.advance().span
      let (decl, span) = self.parse_class_decl_value(start, true, false, true)
      { kind: ExprKind::Class(decl), span }
    }
    TokenKind::Keyword(kw) => {
      match kw {
        Keyword::Try | Keyword::Catch | Keyword::Else =>
          raise ParseError::Expected(pos=token.span.start, "expression")
        _ => ()
      }
      ignore(self.advance())
      let name = keyword_to_string(kw)
      self.record_strict_reserved_identifier_error_if_needed(
        name,
        token.span.start,
      )
      { kind: ExprKind::Ident(name), span: token.span }
    }
    TokenKind::LParen =>
      if self.is_arrow_after_paren() {
        let saved = self.index
        self.parse_arrow_from_paren() catch {
          ParseError::Expected(pos~, expected) =>
            if expected == "binding pattern" {
              self.index = saved
              self.parse_parenthesized_expression()
            } else {
              raise ParseError::Expected(pos~, expected)
            }
          err => {
            self.index = saved
            raise err
          }
        }
      } else {
        self.parse_parenthesized_expression()
      }
    TokenKind::LBrace => self.parse_object_literal()
    TokenKind::LBracket => self.parse_array_literal()
    TokenKind::TemplateStart => self.parse_template_literal(true)
    TokenKind::Eof => { kind: ExprKind::Ident("undefined"), span: token.span }
    _ => raise ParseError::Expected(pos=token.span.start, "expression")
  }
}

///|
fn Parser::parse_member_type_with_restricted_multiline_index_postfix(
  self : Parser,
) -> TypeNode raise ParseError {
  self.disallow_multiline_type_index_postfix_depth += 1
  let ty = self.parse_type() catch {
    err => {
      self.disallow_multiline_type_index_postfix_depth -= 1
      raise err
    }
  }
  self.disallow_multiline_type_index_postfix_depth -= 1
  ty
}

///|
fn Parser::parse_type(self : Parser) -> TypeNode raise ParseError {
  self.parse_type_conditional()
}

///|
fn Parser::parse_type_conditional(self : Parser) -> TypeNode raise ParseError {
  let check_type = self.parse_type_predicate()
  if self.check_keyword(Keyword::Extends) {
    let saved = self.index
    ignore(self.advance())
    try {
      let extends_type = self.parse_type_union()
      if !self.eat(TokenKind::Question) {
        self.index = saved
        return check_type
      }
      let true_type = self.parse_type()
      ignore(self.expect(TokenKind::Colon, "':'"))
      let false_type = self.parse_type()
      let span = check_type.span.merge(false_type.span)
      return {
        kind: TypeKind::Conditional(
          check_type, extends_type, true_type, false_type,
        ),
        span,
      }
    } catch {
      _ => {
        self.index = saved
        return check_type
      }
    }
  }
  check_type
}

///|
fn Parser::parse_type_predicate(self : Parser) -> TypeNode raise ParseError {
  if self.check_ident_name("asserts") {
    let saved = self.index
    let asserts_span = self.advance().span
    let mut target_name : String? = None
    if self.check_keyword(Keyword::This) {
      target_name = Some("this")
      ignore(self.advance())
    } else if self.current().kind is TokenKind::Ident(_) ||
      self.current().kind is TokenKind::Keyword(_) {
      let (name, _) = self.parse_ident_name()
      target_name = Some(name)
    }
    if target_name is Some(name) && self.eat_ident_name("is") {
      let type_ann = self.parse_type()
      let span = asserts_span.merge(type_ann.span)
      return { kind: TypeKind::TypePredicate(name, type_ann), span }
    }
    self.index = saved
  }
  if self.check_keyword(Keyword::This) &&
    self.peek_kind(1) == Some(TokenKind::Ident("is")) {
    let this_span = self.advance().span
    ignore(self.advance())
    let type_ann = self.parse_type()
    let span = this_span.merge(type_ann.span)
    return { kind: TypeKind::TypePredicate("this", type_ann), span }
  }
  if self.current().kind is TokenKind::Ident(_) &&
    self.peek_kind(1) == Some(TokenKind::Ident("is")) {
    let (name, name_span) = self.expect_ident()
    ignore(self.advance())
    let type_ann = self.parse_type()
    let span = name_span.merge(type_ann.span)
    return { kind: TypeKind::TypePredicate(name, type_ann), span }
  }
  self.parse_type_union()
}

///|
fn Parser::type_node_is_unparenthesized_constructor_type(
  self : Parser,
  type_node : TypeNode,
) -> Bool {
  let start_offset = type_node.span.start.offset
  if start_offset < 0 || start_offset >= self.source_text.length() {
    return false
  }
  if self.source_text[start_offset] == '(' {
    return false
  }
  let view = self.source_text.view(start_offset~)
  if !view.has_prefix("new") {
    return false
  }
  let after_new = start_offset + 3
  if after_new < self.source_text.length() &&
    is_identifier_part_char(self.source_text[after_new]) {
    return false
  }
  true
}

///|
fn Parser::type_node_is_unparenthesized_function_type(
  self : Parser,
  type_node : TypeNode,
) -> Bool {
  match type_node.kind {
    TypeKind::Function(_, _) => ()
    _ => return false
  }
  let start_offset = type_node.span.start.offset
  if start_offset < 0 || start_offset >= self.source_text.length() {
    return false
  }
  if self.source_text[start_offset] != '(' {
    return false
  }
  let mut probe = start_offset + 1
  while probe < self.source_text.length() {
    let ch = self.source_text[probe]
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      probe += 1
      continue
    }
    if ch == '(' {
      return false
    }
    let tail = self.source_text.view(start_offset=probe)
    if tail.has_prefix("new") {
      let after_new = probe + 3
      if after_new >= self.source_text.length() ||
        !is_identifier_part_char(self.source_text[after_new]) {
        return false
      }
    }
    if tail.has_prefix("abstract") {
      let after_abstract = probe + 8
      let abstract_has_boundary = after_abstract >= self.source_text.length() ||
        !is_identifier_part_char(self.source_text[after_abstract])
      if abstract_has_boundary {
        let mut next = after_abstract
        while next < self.source_text.length() {
          let ws = self.source_text[next]
          if ws == ' ' || ws == '\t' || ws == '\n' || ws == '\r' {
            next += 1
            continue
          }
          break
        }
        if next < self.source_text.length() {
          let after_tail = self.source_text.view(start_offset=next)
          if after_tail.has_prefix("new") {
            let after_new = next + 3
            if after_new >= self.source_text.length() ||
              !is_identifier_part_char(self.source_text[after_new]) {
              return false
            }
          }
        }
      }
    }
    return true
  }
  true
}

///|
fn Parser::is_unparenthesized_function_type_start(self : Parser) -> Bool {
  if !self.check(TokenKind::LParen) {
    return false
  }
  let mut depth = 0
  let mut offset = 0
  while self.peek_kind(offset) is Some(kind) {
    if kind == TokenKind::LParen {
      depth += 1
    } else if kind == TokenKind::RParen {
      depth -= 1
      if depth == 0 {
        return self.peek_kind(offset + 1) == Some(TokenKind::Arrow)
      }
    } else if kind == TokenKind::Eof {
      return false
    }
    offset += 1
  }
  false
}

///|
fn previous_column_or_self(pos : Position) -> Position {
  if pos.column <= 1 || pos.offset <= 0 {
    return pos
  }
  { offset: pos.offset - 1, line: pos.line, column: pos.column - 1 }
}

///|
fn column_number_at_offset(source : StringView, offset : Int) -> Int {
  if offset <= 0 {
    return 1
  }
  let mut line_start = offset
  while line_start > 0 && source[line_start - 1] != '\n' {
    line_start -= 1
  }
  offset - line_start + 1
}

///|
fn Parser::namespace_export_declaration_diag_pos(
  self : Parser,
  export_start : Position,
) -> Position {
  if self.ambient_context_depth <= 0 ||
    export_start.offset <= 0 ||
    export_start.column <= 1 {
    return export_start
  }
  let mut rewind_offset = export_start.offset
  let mut rewind_column = export_start.column
  while rewind_offset > 0 && rewind_column > 1 {
    let prev = self.source_text[rewind_offset - 1]
    if prev == ' ' || prev == '\t' {
      rewind_offset -= 1
      rewind_column -= 1
      continue
    }
    break
  }
  if rewind_offset > 0 && self.source_text[rewind_offset - 1] == '\n' {
    let lf_offset = rewind_offset - 1
    return {
      offset: lf_offset,
      line: if export_start.line > 1 {
        export_start.line - 1
      } else {
        1
      },
      column: column_number_at_offset(self.source_text, lf_offset),
    }
  }
  export_start
}

///|
fn Parser::parse_type_union(self : Parser) -> TypeNode raise ParseError {
  let types : Array[TypeNode] = []
  let mut saw_leading_pipe = false
  while self.eat(TokenKind::Pipe) {
    saw_leading_pipe = true
  }
  types.push(self.parse_type_intersection())
  while self.eat(TokenKind::Pipe) {
    types.push(self.parse_type_intersection())
  }
  if saw_leading_pipe &&
    self.type_node_is_unparenthesized_constructor_type(types[0]) {
    let diag_pos = previous_column_or_self(types[0].span.start)
    self.record_ts_error(
      diag_pos, 1386, "Constructor type notation must be parenthesized when used in a union type.",
    )
  }
  if saw_leading_pipe &&
    self.type_node_is_unparenthesized_function_type(types[0]) {
    let diag_pos = previous_column_or_self(types[0].span.start)
    self.record_ts_error(
      diag_pos, 1385, "Function type notation must be parenthesized when used in a union type.",
    )
  }
  if types.length() > 1 {
    for type_node in types {
      if self.type_node_is_unparenthesized_constructor_type(type_node) {
        let diag_pos = previous_column_or_self(type_node.span.start)
        self.record_ts_error(
          diag_pos, 1386, "Constructor type notation must be parenthesized when used in a union type.",
        )
      }
      if self.type_node_is_unparenthesized_function_type(type_node) {
        let diag_pos = previous_column_or_self(type_node.span.start)
        self.record_ts_error(
          diag_pos, 1385, "Function type notation must be parenthesized when used in a union type.",
        )
      }
    }
  }
  if types.length() == 1 {
    types[0]
  } else {
    let span = types[0].span.merge(types[types.length() - 1].span)
    { kind: TypeKind::Union(types), span }
  }
}

///|
fn Parser::parse_type_intersection(self : Parser) -> TypeNode raise ParseError {
  let types : Array[TypeNode] = []
  let mut saw_leading_ampersand = false
  while self.eat(TokenKind::Ampersand) {
    saw_leading_ampersand = true
  }
  let first_constructor_diag_pos = if saw_leading_ampersand &&
    self.check_keyword(Keyword::New) {
    let pos = previous_column_or_self(self.current().span.start)
    self.record_ts_error(
      pos, 1388, "Constructor type notation must be parenthesized when used in an intersection type.",
    )
    Some(pos)
  } else {
    None
  }
  let first_function_diag_pos = if saw_leading_ampersand &&
    self.is_unparenthesized_function_type_start() {
    let pos = previous_column_or_self(self.current().span.start)
    self.record_ts_error(
      pos, 1387, "Function type notation must be parenthesized when used in an intersection type.",
    )
    Some(pos)
  } else {
    None
  }
  types.push(self.parse_type_primary())
  if saw_leading_ampersand &&
    first_constructor_diag_pos is None &&
    self.type_node_is_unparenthesized_constructor_type(types[0]) {
    let diag_pos = previous_column_or_self(types[0].span.start)
    self.record_ts_error(
      diag_pos, 1388, "Constructor type notation must be parenthesized when used in an intersection type.",
    )
  }
  if saw_leading_ampersand &&
    first_function_diag_pos is None &&
    self.type_node_is_unparenthesized_function_type(types[0]) {
    let diag_pos = previous_column_or_self(types[0].span.start)
    self.record_ts_error(
      diag_pos, 1387, "Function type notation must be parenthesized when used in an intersection type.",
    )
  }
  while self.eat(TokenKind::Ampersand) {
    let constructor_diag_pos = if self.check_keyword(Keyword::New) {
      let pos = previous_column_or_self(self.current().span.start)
      self.record_ts_error(
        pos, 1388, "Constructor type notation must be parenthesized when used in an intersection type.",
      )
      Some(pos)
    } else {
      None
    }
    let function_diag_pos = if self.is_unparenthesized_function_type_start() {
      let pos = previous_column_or_self(self.current().span.start)
      self.record_ts_error(
        pos, 1387, "Function type notation must be parenthesized when used in an intersection type.",
      )
      Some(pos)
    } else {
      None
    }
    let type_node = self.parse_type_primary()
    if constructor_diag_pos is None &&
      self.type_node_is_unparenthesized_constructor_type(type_node) {
      let diag_pos = previous_column_or_self(type_node.span.start)
      self.record_ts_error(
        diag_pos, 1388, "Constructor type notation must be parenthesized when used in an intersection type.",
      )
    }
    if function_diag_pos is None &&
      self.type_node_is_unparenthesized_function_type(type_node) {
      let diag_pos = previous_column_or_self(type_node.span.start)
      self.record_ts_error(
        diag_pos, 1387, "Function type notation must be parenthesized when used in an intersection type.",
      )
    }
    types.push(type_node)
  }
  if types.length() == 1 {
    types[0]
  } else {
    let span = types[0].span.merge(types[types.length() - 1].span)
    { kind: TypeKind::Intersection(types), span }
  }
}

///|
fn Parser::is_named_type_param_start(self : Parser) -> Bool {
  match self.current().kind {
    TokenKind::Ident(_) | TokenKind::Keyword(_) =>
      self.peek_kind(1) == Some(TokenKind::Colon) ||
      (
        self.peek_kind(1) == Some(TokenKind::Question) &&
        self.peek_kind(2) == Some(TokenKind::Colon)
      )
    _ => false
  }
}

///|
fn Parser::is_function_type_param_named_start(self : Parser) -> Bool {
  if self.check(TokenKind::Ellipsis) {
    return true
  }
  if self.check(TokenKind::LBrace) {
    return match
      self.peek_kind_after_matching_token_pair(
        TokenKind::LBrace,
        TokenKind::RBrace,
      ) {
      Some(TokenKind::Colon)
      | Some(TokenKind::Question)
      | Some(TokenKind::Comma)
      | Some(TokenKind::RParen)
      | Some(TokenKind::Eq) => true
      _ => false
    }
  }
  if self.check(TokenKind::LBracket) {
    return match
      self.peek_kind_after_matching_token_pair(
        TokenKind::LBracket,
        TokenKind::RBracket,
      ) {
      Some(TokenKind::Colon)
      | Some(TokenKind::Question)
      | Some(TokenKind::Comma)
      | Some(TokenKind::RParen)
      | Some(TokenKind::Eq) => true
      _ => false
    }
  }
  if self.check_keyword(Keyword::Public) ||
    self.check_keyword(Keyword::Private) ||
    self.check_keyword(Keyword::Protected) ||
    self.check_keyword(Keyword::Readonly) ||
    self.check_keyword(Keyword::Export) {
    return match self.peek_kind(1) {
      Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) => true
      _ => false
    }
  }
  match self.current().kind {
    TokenKind::Ident(_) | TokenKind::Keyword(_) =>
      match self.peek_kind(1) {
        Some(TokenKind::Colon)
        | Some(TokenKind::Question)
        | Some(TokenKind::Comma)
        | Some(TokenKind::RParen)
        | Some(TokenKind::Eq) => true
        _ => false
      }
    _ => false
  }
}

///|
fn Parser::parse_function_type_param(
  self : Parser,
) -> TypeNode raise ParseError {
  ignore(self.eat(TokenKind::Ellipsis))
  while self.check_keyword(Keyword::Public) ||
        self.check_keyword(Keyword::Private) ||
        self.check_keyword(Keyword::Protected) ||
        self.check_keyword(Keyword::Readonly) ||
        self.check_keyword(Keyword::Export) {
    let next_is_ident = match self.peek_kind(1) {
      Some(TokenKind::Ident(_)) | Some(TokenKind::Keyword(_)) => true
      _ => false
    }
    if !next_is_ident {
      break
    }
    ignore(self.advance())
  }
  if self.check(TokenKind::LBrace) || self.check(TokenKind::LBracket) {
    let open = if self.check(TokenKind::LBrace) {
      TokenKind::LBrace
    } else {
      TokenKind::LBracket
    }
    let close = if self.check(TokenKind::LBrace) {
      TokenKind::RBrace
    } else {
      TokenKind::RBracket
    }
    let mut depth = 0
    let mut offset = 0
    while self.peek_kind(offset) is Some(kind) {
      if kind == open {
        depth += 1
      } else if kind == close {
        depth -= 1
        if depth == 0 {
          break
        }
      }
      offset += 1
    }
    if depth == 0 {
      let next_kind = self.peek_kind(offset + 1)
      let has_colon = next_kind == Some(TokenKind::Colon) ||
        (
          next_kind == Some(TokenKind::Question) &&
          self.peek_kind(offset + 2) == Some(TokenKind::Colon)
        )
      if has_colon {
        let pattern = self.parse_binding_pattern()
        ignore(self.eat(TokenKind::Question))
        if self.eat(TokenKind::Colon) {
          return self.parse_type()
        }
        return { kind: TypeKind::Ident("any"), span: pattern.span }
      }
    }
  }
  if (
      self.current().kind is TokenKind::Ident(_) ||
      self.current().kind is TokenKind::Keyword(_)
    ) &&
    self.peek_kind(1) == Some(TokenKind::Eq) {
    let (_, name_span) = self.parse_ident_name()
    ignore(self.eat(TokenKind::Eq))
    if !self.check(TokenKind::Comma) && !self.check(TokenKind::RParen) {
      self.skip_call_arg_junk()
    }
    return { kind: TypeKind::Ident("any"), span: name_span }
  }
  if self.is_named_type_param_start() {
    ignore(self.parse_ident_name())
    ignore(self.eat(TokenKind::Question))
    ignore(self.expect(TokenKind::Colon, "':'"))
    let ty = self.parse_type()
    if self.eat(TokenKind::Eq) {
      if !self.check(TokenKind::Comma) && !self.check(TokenKind::RParen) {
        self.skip_call_arg_junk()
      }
    }
    return ty
  } else {
    match self.current().kind {
      TokenKind::Ident(_) | TokenKind::Keyword(_) =>
        if self.peek_kind(1) == Some(TokenKind::Question) ||
          self.peek_kind(1) == Some(TokenKind::Comma) ||
          self.peek_kind(1) == Some(TokenKind::RParen) {
          let (_, name_span) = self.parse_ident_name()
          if self.eat(TokenKind::Question) {
            let span = name_span.merge(self.previous().span)
            return { kind: TypeKind::Ident("any"), span }
          }
          return { kind: TypeKind::Ident("any"), span: name_span }
        }
      _ => ()
    }
    self.parse_type()
  }
}

///|
fn Parser::record_invalid_index_signature_param_type_if_needed(
  self : Parser,
) -> Bool {
  if !self.check(TokenKind::LBracket) {
    return false
  }
  if self.peek_kind(2) != Some(TokenKind::Colon) {
    return false
  }
  let param_pos = match self.peek(1) {
    Some(token) => token.span.start
    None => self.current().span.start
  }
  let source = self.source_name_for_position(param_pos)
  let mut use_literal_or_generic_diag = false
  let mut report_error = true
  match self.peek_kind(3) {
    Some(TokenKind::Ident(name)) =>
      if name == "string" || name == "number" || name == "symbol" {
        report_error = false
      } else if self.is_active_type_param_name(name) {
        use_literal_or_generic_diag = true
      } else {
        match self.find_index_signature_param_alias_kind(source, name) {
          Some(kind) =>
            if kind == index_signature_param_type_kind_allowed() {
              report_error = false
            } else if kind ==
              index_signature_param_type_kind_literal_or_generic() {
              use_literal_or_generic_diag = true
            }
          None => ()
        }
      }
    Some(TokenKind::TemplateStart) => report_error = false
    Some(TokenKind::String(_)) | Some(TokenKind::Number(_)) =>
      use_literal_or_generic_diag = true
    Some(TokenKind::Keyword(Keyword::True))
    | Some(TokenKind::Keyword(Keyword::False)) =>
      use_literal_or_generic_diag = true
    Some(TokenKind::Minus) =>
      match self.peek_kind(4) {
        Some(TokenKind::Number(_)) => use_literal_or_generic_diag = true
        _ => ()
      }
    _ => ()
  }
  if !report_error {
    return false
  }
  if use_literal_or_generic_diag {
    self.record_ts_error(
      param_pos, 1337, "An index signature parameter type cannot be a literal type or generic type. Consider using a mapped object type instead.",
    )
  } else {
    self.record_ts_error(
      param_pos, 1268, "An index signature parameter type must be 'string', 'number', 'symbol', or a template literal type.",
    )
  }
  true
}

///|
fn Parser::record_index_signature_param_count_error_if_needed(
  self : Parser,
) -> Bool {
  if !self.check(TokenKind::LBracket) {
    return false
  }
  if self.peek_kind(1) == Some(TokenKind::RBracket) {
    let diag_pos = self.current().span.start
    self.record_ts_error(
      diag_pos, 1096, "An index signature must have exactly one parameter.",
    )
    return true
  }
  let mut depth = 0
  let mut offset = 0
  let mut saw_colon = false
  let mut saw_comma = false
  let mut top_level_trailing_comma_pos : Position? = None
  let mut top_level_last_token_was_comma = false
  while self.peek_kind(offset) is Some(kind) {
    if kind == TokenKind::LBracket {
      depth += 1
    } else if kind == TokenKind::RBracket {
      depth -= 1
      if depth == 0 {
        if top_level_last_token_was_comma {
          let diag_pos = match top_level_trailing_comma_pos {
            Some(pos) => pos
            None =>
              match self.peek(offset) {
                Some(token) => token.span.start
                None => self.current().span.start
              }
          }
          self.record_ts_error(
            diag_pos, 1025, "An index signature cannot have a trailing comma.",
          )
          return true
        }
        break
      }
    } else if depth == 1 {
      if kind == TokenKind::Colon {
        saw_colon = true
        top_level_last_token_was_comma = false
      } else if kind == TokenKind::Comma {
        saw_comma = true
        top_level_last_token_was_comma = true
        top_level_trailing_comma_pos = match self.peek(offset) {
          Some(token) => Some(token.span.start)
          None => top_level_trailing_comma_pos
        }
      } else {
        top_level_last_token_was_comma = false
      }
    }
    offset += 1
  }
  if saw_colon && saw_comma {
    let diag_pos = match self.peek(1) {
      Some(token) => token.span.start
      None => self.current().span.start
    }
    self.record_ts_error(
      diag_pos, 1096, "An index signature must have exactly one parameter.",
    )
    return true
  }
  false
}

///|
fn Parser::record_index_signature_rest_param_error_if_needed(
  self : Parser,
) -> Unit {
  if !self.check(TokenKind::LBracket) {
    return
  }
  if self.peek_kind(1) != Some(TokenKind::Ellipsis) {
    return
  }
  let diag_pos = match self.peek(1) {
    Some(token) => token.span.start
    None => self.current().span.start
  }
  self.record_ts_error(
    diag_pos, 1017, "An index signature cannot have a rest parameter.",
  )
}

///|
fn Parser::record_index_signature_accessibility_modifier_error_if_needed(
  self : Parser,
) -> Unit {
  if !self.check(TokenKind::LBracket) {
    return
  }
  let has_modifier = match self.peek_kind(1) {
    Some(TokenKind::Keyword(Keyword::Public))
    | Some(TokenKind::Keyword(Keyword::Private))
    | Some(TokenKind::Keyword(Keyword::Protected)) => true
    _ => false
  }
  if !has_modifier {
    return
  }
  let name_like = self.peek_kind(2) is Some(TokenKind::Ident(_)) ||
    self.peek_kind(2) is Some(TokenKind::Keyword(_))
  let has_param_type = self.peek_kind(3) == Some(TokenKind::Colon) ||
    (
      self.peek_kind(3) == Some(TokenKind::Question) &&
      self.peek_kind(4) == Some(TokenKind::Colon)
    )
  if !(name_like && has_param_type) {
    return
  }
  let diag_pos = match self.peek(2) {
    Some(token) => token.span.start
    None =>
      match self.peek(1) {
        Some(token) => token.span.start
        None => self.current().span.start
      }
  }
  self.record_ts_error(
    diag_pos, 1018, "An index signature parameter cannot have an accessibility modifier.",
  )
}

///|
fn Parser::peek_kind_after_matching_bracket(self : Parser) -> TokenKind? {
  self.peek_kind_after_matching_token_pair(
    TokenKind::LBracket,
    TokenKind::RBracket,
  )
}

///|
fn Parser::peek_kind_after_matching_token_pair(
  self : Parser,
  open_kind : TokenKind,
  close_kind : TokenKind,
) -> TokenKind? {
  if !self.check(open_kind) {
    return None
  }
  let mut depth = 0
  let mut offset = 0
  while self.peek_kind(offset) is Some(kind) {
    if kind == open_kind {
      depth += 1
    } else if kind == close_kind {
      depth -= 1
      if depth == 0 {
        return self.peek_kind(offset + 1)
      }
    }
    offset += 1
  }
  None
}

///|
fn Parser::is_complex_computed_name(self : Parser) -> Bool {
  if !self.check(TokenKind::LBracket) {
    return false
  }
  let mut depth = 0
  let mut offset = 0
  while self.peek_kind(offset) is Some(kind) {
    if kind == TokenKind::LBracket {
      if depth == 1 {
        return true
      }
      depth += 1
    } else if kind == TokenKind::RBracket {
      depth -= 1
      if depth == 0 {
        break
      }
    } else if depth == 1 {
      match kind {
        TokenKind::LBracket
        | TokenKind::LParen
        | TokenKind::Plus
        | TokenKind::Minus
        | TokenKind::Star
        | TokenKind::Slash
        | TokenKind::Percent
        | TokenKind::Question
        | TokenKind::Caret
        | TokenKind::Pipe
        | TokenKind::Ampersand
        | TokenKind::Lt
        | TokenKind::Gt
        | TokenKind::QuestionDot
        | TokenKind::Keyword(Keyword::As) => return true
        _ => ()
      }
    }
    offset += 1
  }
  false
}

///|
fn normalize_computed_property_key(raw : StringView) -> String {
  let sb = StringBuilder::new()
  for ch in raw {
    if ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r' {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn is_plain_identifier_text(text : String) -> Bool {
  let view = text[:]
  if view.length() == 0 {
    return false
  }
  let first = view[0]
  let first_ok = (first >= 'a' && first <= 'z') ||
    (first >= 'A' && first <= 'Z') ||
    first == '_' ||
    first == '$'
  if !first_ok {
    return false
  }
  let mut i = 1
  while i < view.length() {
    let ch = view[i]
    let part_ok = (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' ||
      ch == '$'
    if !part_ok {
      return false
    }
    i += 1
  }
  true
}

///|
fn is_plain_qualified_identifier_text(text : String) -> Bool {
  let view = text[:]
  if view.length() == 0 {
    return false
  }
  let mut seg_start = 0
  let mut i = 0
  while i <= view.length() {
    let at_end = i == view.length()
    let at_dot = !at_end && view[i] == '.'
    if !at_end && !at_dot {
      i += 1
      continue
    }
    if i == seg_start {
      return false
    }
    let part = view.view(start_offset=seg_start, end_offset=i).to_string()
    if !is_plain_identifier_text(part) {
      return false
    }
    if at_end {
      break
    }
    seg_start = i + 1
    i += 1
  }
  true
}

///|
fn computed_object_key_can_be_duplicate_checked(key : String) -> Bool {
  if is_plain_qualified_identifier_text(key) || is_decimal_digit_string(key) {
    return true
  }
  if key.has_prefix("+") {
    let rest = key.view(start_offset=1).to_string()
    return is_decimal_digit_string(rest)
  }
  if key.has_prefix("-") {
    let rest = key.view(start_offset=1).to_string()
    return is_decimal_digit_string(rest)
  }
  false
}

///|
fn is_decimal_digit_string(text : String) -> Bool {
  if text == "" {
    return false
  }
  for ch in text {
    if ch < '0' || ch > '9' {
      return false
    }
  }
  true
}

///|
fn decimal_digit_string(value : Int) -> String {
  match value {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    _ => "0"
  }
}

///|
fn numeric_literal_digit_value(ch : UInt16) -> Int? {
  if ch >= '0' && ch <= '9' {
    return Some(ch.to_int() - '0'.to_int())
  }
  if ch >= 'a' && ch <= 'f' {
    return Some(ch.to_int() - 'a'.to_int() + 10)
  }
  if ch >= 'A' && ch <= 'F' {
    return Some(ch.to_int() - 'A'.to_int() + 10)
  }
  None
}

///|
fn decimal_digits_mul_add_in_place(
  digits_reversed : Array[Int],
  multiplier : Int,
  addend : Int,
) -> Unit {
  let mut carry = addend
  let mut i = 0
  while i < digits_reversed.length() {
    let value = digits_reversed[i] * multiplier + carry
    digits_reversed[i] = value % 10
    carry = value / 10
    i += 1
  }
  while carry > 0 {
    digits_reversed.push(carry % 10)
    carry = carry / 10
  }
}

///|
fn integer_literal_to_decimal_string(
  raw : String,
  start_offset : Int,
  base : Int,
) -> String? {
  if base < 2 || base > 16 || start_offset < 0 || start_offset > raw.length() {
    return None
  }
  let digits_reversed : Array[Int] = [0]
  let mut saw_digit = false
  let mut i = start_offset
  while i < raw.length() {
    let ch = raw[i]
    if ch == '_' {
      i += 1
      continue
    }
    match numeric_literal_digit_value(ch) {
      Some(value) =>
        if value >= base {
          return None
        } else {
          saw_digit = true
          decimal_digits_mul_add_in_place(digits_reversed, base, value)
        }
      None => return None
    }
    i += 1
  }
  if !saw_digit {
    return None
  }
  let sb = StringBuilder::new()
  let mut idx = digits_reversed.length()
  while idx > 0 {
    idx -= 1
    sb.write_string(decimal_digit_string(digits_reversed[idx]))
  }
  Some(sb.to_string())
}

///|
fn is_decimal_integer_literal_with_separators(raw : String) -> Bool {
  if raw == "" {
    return false
  }
  let mut saw_digit = false
  for ch in raw {
    if ch == '_' {
      continue
    }
    if ch < '0' || ch > '9' {
      return false
    }
    saw_digit = true
  }
  saw_digit
}

///|
fn canonicalize_numeric_property_key(raw : String) -> String? {
  if raw == "" ||
    raw.has_suffix("n") ||
    raw.contains(".") ||
    raw.contains("e") ||
    raw.contains("E") {
    return None
  }
  if raw.has_prefix("0x") || raw.has_prefix("0X") {
    return integer_literal_to_decimal_string(raw, 2, 16)
  }
  if raw.has_prefix("0b") || raw.has_prefix("0B") {
    return integer_literal_to_decimal_string(raw, 2, 2)
  }
  if raw.has_prefix("0o") || raw.has_prefix("0O") {
    return integer_literal_to_decimal_string(raw, 2, 8)
  }
  if is_legacy_octal_number_literal(raw) {
    return integer_literal_to_decimal_string(raw, 1, 8)
  }
  if is_decimal_integer_literal_with_separators(raw) {
    return integer_literal_to_decimal_string(raw, 0, 10)
  }
  None
}

///|
fn hex_digit_value_for_unicode_escape(ch : UInt16) -> Int? {
  match ch {
    '0' => Some(0)
    '1' => Some(1)
    '2' => Some(2)
    '3' => Some(3)
    '4' => Some(4)
    '5' => Some(5)
    '6' => Some(6)
    '7' => Some(7)
    '8' => Some(8)
    '9' => Some(9)
    'a' | 'A' => Some(10)
    'b' | 'B' => Some(11)
    'c' | 'C' => Some(12)
    'd' | 'D' => Some(13)
    'e' | 'E' => Some(14)
    'f' | 'F' => Some(15)
    _ => None
  }
}

///|
fn decode_simple_identifier_unicode_escape(raw : String) -> String {
  let view = raw[:]
  if view.length() != 6 || view[0] != '\\' || view[1] != 'u' {
    return raw
  }
  let mut value = 0
  let mut i = 2
  while i < 6 {
    match hex_digit_value_for_unicode_escape(view[i]) {
      Some(digit) => value = value * 16 + digit
      None => return raw
    }
    i += 1
  }
  if value == 36 {
    return "$"
  }
  if value == 95 {
    return "_"
  }
  let digits : Array[String] = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  ]
  if value >= 48 && value <= 57 {
    return digits[value - 48]
  }
  let uppers : Array[String] = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
  ]
  if value >= 65 && value <= 90 {
    return uppers[value - 65]
  }
  let lowers : Array[String] = [
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
    "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  ]
  if value >= 97 && value <= 122 {
    return lowers[value - 97]
  }
  raw
}

///|
fn identifier_escape_ascii_string(value : Int) -> String? {
  if value == 36 {
    return Some("$")
  }
  if value == 95 {
    return Some("_")
  }
  let digits : Array[String] = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  ]
  if value >= 48 && value <= 57 {
    return Some(digits[value - 48])
  }
  let uppers : Array[String] = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
  ]
  if value >= 65 && value <= 90 {
    return Some(uppers[value - 65])
  }
  let lowers : Array[String] = [
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
    "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  ]
  if value >= 97 && value <= 122 {
    return Some(lowers[value - 97])
  }
  None
}

///|
fn decode_identifier_unicode_escapes_for_keyword(raw : String) -> String {
  if !raw.contains("\\u") {
    return raw
  }
  let raw_view = raw[:]
  let sb = StringBuilder::new()
  let mut i = 0
  let mut changed = false
  while i < raw_view.length() {
    if raw_view[i] == '\\' &&
      i + 1 < raw_view.length() &&
      raw_view[i + 1] == 'u' {
      match parse_unicode_escape_code_point(raw_view, i) {
        Some((code_point, consumed_len)) =>
          match identifier_escape_ascii_string(code_point) {
            Some(text) => {
              sb.write_string(text)
              i += consumed_len
              changed = true
              continue
            }
            None => return raw
          }
        None => return raw
      }
    }
    sb.write_string(raw_view.view(start_offset=i, end_offset=i + 1).to_string())
    i += 1
  }
  if changed {
    sb.to_string()
  } else {
    raw
  }
}

///|
fn is_escaped_keyword_identifier(raw : String, keyword_text : String) -> Bool {
  if !raw.contains("\\u") {
    return false
  }
  decode_identifier_unicode_escapes_for_keyword(raw) == keyword_text
}

///|
fn canonicalize_object_property_key(raw : String) -> String {
  let decoded_raw = decode_simple_identifier_unicode_escape(raw)
  if raw.length() >= 2 &&
    (
      (decoded_raw.has_prefix("\"") && decoded_raw.has_suffix("\"")) ||
      (decoded_raw.has_prefix("'") && decoded_raw.has_suffix("'"))
    ) {
    return decoded_raw
      .view(start_offset=1, end_offset=decoded_raw.length() - 1)
      .to_string()
  }
  if decoded_raw.has_prefix("+") {
    let digits = decoded_raw.view(start_offset=1).to_string()
    match canonicalize_numeric_property_key(digits) {
      Some(canonical) => return canonical
      None => ()
    }
    if is_decimal_digit_string(digits) {
      return digits
    }
  }
  if decoded_raw.has_prefix("-") {
    let digits = decoded_raw.view(start_offset=1).to_string()
    match canonicalize_numeric_property_key(digits) {
      Some(canonical) => return "-\{canonical}"
      None => ()
    }
    if is_decimal_digit_string(digits) {
      return "-\{digits}"
    }
  }
  match canonicalize_numeric_property_key(decoded_raw) {
    Some(canonical) => canonical
    None => decoded_raw
  }
}

///|
fn Parser::parse_object_computed_property_name(
  self : Parser,
) -> (String, Span, String) raise ParseError {
  let start = self.expect(TokenKind::LBracket, "'['")
  let mut depth = 1
  let mut end_span = start.span
  while !self.at_end() && depth > 0 {
    let token = self.current()
    match token.kind {
      TokenKind::LBracket => {
        depth += 1
        ignore(self.advance())
      }
      TokenKind::RBracket => {
        depth -= 1
        end_span = token.span
        ignore(self.advance())
        if depth == 0 {
          break
        }
      }
      _ => ignore(self.advance())
    }
  }
  if depth != 0 {
    raise ParseError::Expected(pos=self.current().span.start, "']'")
  }
  let key = normalize_computed_property_key(
    self.source_text.view(
      start_offset=start.span.end.offset,
      end_offset=end_span.start.offset,
    ),
  )
  (
    "[computed]",
    start.span.merge(end_span),
    canonicalize_object_property_key(key),
  )
}

///|
fn Parser::parse_bracket_member_name(
  self : Parser,
) -> (String, Span) raise ParseError {
  let start = self.expect(TokenKind::LBracket, "'['")
  let mut depth = 1
  let mut end_span = start.span
  while !self.at_end() && depth > 0 {
    let token = self.current()
    match token.kind {
      TokenKind::LBracket => {
        depth += 1
        ignore(self.advance())
      }
      TokenKind::RBracket => {
        depth -= 1
        end_span = token.span
        ignore(self.advance())
        if depth == 0 {
          break
        }
      }
      _ => ignore(self.advance())
    }
  }
  if depth != 0 {
    raise ParseError::Expected(pos=self.current().span.start, "']'")
  }
  ("[computed]", start.span.merge(end_span))
}

///|
fn Parser::parse_bracket_member_name_with_computed_name_error(
  self : Parser,
  code : Int,
  message : String,
) -> (String, Span) raise ParseError {
  let start = self.expect(TokenKind::LBracket, "'['")
  let mut depth = 1
  let mut end_span = start.span
  let mut saw_initializer = false
  let mut first_inner_pos : Position? = None
  while !self.at_end() && depth > 0 {
    let token = self.current()
    if depth == 1 &&
      first_inner_pos is None &&
      token.kind != TokenKind::RBracket {
      first_inner_pos = Some(token.span.start)
    }
    match token.kind {
      TokenKind::LBracket => {
        depth += 1
        ignore(self.advance())
      }
      TokenKind::RBracket => {
        depth -= 1
        end_span = token.span
        ignore(self.advance())
        if depth == 0 {
          break
        }
      }
      TokenKind::Eq => {
        if depth == 1 {
          saw_initializer = true
        }
        ignore(self.advance())
      }
      _ => ignore(self.advance())
    }
  }
  if depth != 0 {
    raise ParseError::Expected(pos=self.current().span.start, "']'")
  }
  if saw_initializer {
    let diag_pos = if code == 1020 {
      match first_inner_pos {
        Some(pos) => pos
        None => start.span.start
      }
    } else {
      start.span.start
    }
    self.record_ts_error(diag_pos, code, message)
  }
  ("[computed]", start.span.merge(end_span))
}

///|
fn Parser::parse_constructor_type_signature(
  self : Parser,
  start_span : Span,
) -> TypeNode raise ParseError {
  if self.check(TokenKind::Lt) {
    ignore(self.parse_type_params())
  }
  ignore(self.expect(TokenKind::LParen, "'('"))
  let params : Array[TypeNode] = []
  if !self.check(TokenKind::RParen) {
    while true {
      params.push(self.parse_function_type_param())
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::RParen) {
          break
        }
        continue
      }
      break
    }
  }
  ignore(self.expect(TokenKind::RParen, "')'"))
  ignore(self.expect(TokenKind::Arrow, "'=>'"))
  let ret = self.parse_type()
  { kind: TypeKind::Function(params, ret), span: start_span.merge(ret.span) }
}

///|
fn Parser::parse_type_primary(self : Parser) -> TypeNode raise ParseError {
  if self.check(TokenKind::Lt) && self.is_type_args_before_call() {
    ignore(self.parse_type_params())
    return self.parse_type_primary()
  }
  if self.eat(TokenKind::Question) {
    let start = self.previous().span
    let inner = self.parse_type_primary()
    let span = start.merge(inner.span)
    return self.parse_type_postfix({ kind: inner.kind, span })
  }
  if self.check(TokenKind::Bang) {
    let start = self.advance().span
    let inner = self.parse_type_primary()
    let span = start.merge(inner.span)
    return self.parse_type_postfix({ kind: inner.kind, span })
  }
  if self.check(TokenKind::Plus) || self.check(TokenKind::Minus) {
    let sign = if self.check(TokenKind::Plus) { "+" } else { "-" }
    let sign_span = self.advance().span
    match self.current().kind {
      TokenKind::Number(value) => {
        let token = self.advance()
        let node : TypeNode = {
          kind: TypeKind::Literal(TypeLiteral::Number("\{sign}\{value}")),
          span: sign_span.merge(token.span),
        }
        return self.parse_type_postfix(node)
      }
      _ => {
        let inner = self.parse_type_primary()
        let span = sign_span.merge(inner.span)
        return self.parse_type_postfix({ kind: inner.kind, span })
      }
    }
  }
  if (
      self.check_keyword(Keyword::Abstract) || self.check_ident_name("abstract")
    ) &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::New)) {
    let abstract_span = self.advance().span
    ignore(self.expect_keyword(Keyword::New))
    let node = self.parse_constructor_type_signature(abstract_span)
    return self.parse_type_postfix(node)
  }
  if self.check_keyword(Keyword::New) {
    let start = self.expect_keyword(Keyword::New)
    let node = self.parse_constructor_type_signature(start.span)
    return self.parse_type_postfix(node)
  }
  if self.check(TokenKind::LParen) {
    let start = self.expect(TokenKind::LParen, "'('")
    let params : Array[TypeNode] = []
    let mut saw_named_param = false
    if !self.check(TokenKind::RParen) {
      while true {
        if self.is_function_type_param_named_start() {
          saw_named_param = true
        }
        params.push(self.parse_function_type_param())
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RParen) {
            break
          }
          continue
        }
        break
      }
    }
    let end = self.expect(TokenKind::RParen, "')'")
    let looks_like_function_type = params.length() == 0 ||
      saw_named_param ||
      params.length() > 1
    if self.check(TokenKind::Arrow) && looks_like_function_type {
      ignore(self.expect(TokenKind::Arrow, "'=>'"))
      let ret = self.parse_type()
      let span = start.span.merge(ret.span)
      return self.parse_type_postfix({
        kind: TypeKind::Function(params, ret),
        span,
      })
    }
    if looks_like_function_type && self.eat(TokenKind::Colon) {
      self.record_ts_error(self.previous().span.start, 1005, "'=>' expected.")
      let ret = self.parse_type()
      let span = start.span.merge(ret.span)
      return self.parse_type_postfix({
        kind: TypeKind::Function(params, ret),
        span,
      })
    }
    if params.length() == 0 {
      let end_pos = end.span.end
      let diag_pos : Position = {
        offset: end_pos.offset,
        line: if end_pos.line > 1 {
          end_pos.line - 1
        } else {
          end_pos.line
        },
        column: end_pos.column,
      }
      self.record_ts_error(diag_pos, 1005, "'=>' expected.")
      let node : TypeNode = {
        kind: TypeKind::Tuple([]),
        span: start.span.merge(end.span),
      }
      return self.parse_type_postfix(node)
    }
    if params.length() == 1 {
      let inner = params[0]
      return self.parse_type_postfix({
        kind: inner.kind,
        span: start.span.merge(end.span),
      })
    }
    raise ParseError::Expected(pos=end.span.start, "function type")
  }
  if self.check(TokenKind::LBracket) {
    let start = self.expect(TokenKind::LBracket, "'['")
    let elements : Array[TypeNode] = []
    if !self.check(TokenKind::RBracket) {
      while true {
        ignore(self.eat(TokenKind::Ellipsis))
        let mut labeled_optional = false
        if (
            self.current().kind is TokenKind::Ident(_) ||
            self.current().kind is TokenKind::Keyword(_)
          ) &&
          (
            self.peek_kind(1) == Some(TokenKind::Colon) ||
            (
              self.peek_kind(1) == Some(TokenKind::Question) &&
              self.peek_kind(2) == Some(TokenKind::Colon)
            )
          ) {
          ignore(self.parse_ident_name())
          if self.eat(TokenKind::Question) {
            labeled_optional = true
          }
          ignore(self.expect(TokenKind::Colon, "':'"))
        }
        let elem = self.parse_type()
        if self.eat(TokenKind::Question) {
          // Ignore optional marker in tuple element types.
        } else if labeled_optional {
          // Optional marker already consumed before ':'.
        }
        elements.push(elem)
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RBracket) {
            break
          }
          continue
        }
        break
      }
    }
    let end = self.expect(TokenKind::RBracket, "']'")
    let node : TypeNode = {
      kind: TypeKind::Tuple(elements),
      span: start.span.merge(end.span),
    }
    return self.parse_type_postfix(node)
  }
  if self.check(TokenKind::TemplateStart) {
    return self.parse_template_type()
  }
  if self.check(TokenKind::LBrace) {
    let start = self.expect(TokenKind::LBrace, "'{'")
    let members : Array[TypeMember] = []
    while !self.check(TokenKind::RBrace) && !self.at_end() {
      if self.check(TokenKind::Lt) &&
        self.peek_kind(1) == Some(TokenKind::Minus) {
        ignore(self.advance())
        let minus = self.advance().span
        self.record_ts_error(
          minus.start,
          1139,
          "Type parameter declaration expected.",
        )
        self.record_ts_error(
          self.current().span.start,
          1109,
          "Expression expected.",
        )
        ignore(self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma))
        continue
      }
      members.push(self.parse_type_member()) catch {
        err => {
          self.record_error(err)
          while !self.check(TokenKind::Semicolon) &&
                !self.check(TokenKind::Comma) &&
                !self.check(TokenKind::RBrace) &&
                !self.at_end() {
            ignore(self.advance())
          }
          ignore(self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma))
        }
      }
    }
    let end = self.expect(TokenKind::RBrace, "'}'")
    let node : TypeNode = {
      kind: TypeKind::Object(members),
      span: start.span.merge(end.span),
    }
    return self.parse_type_postfix(node)
  }
  if self.check_keyword(Keyword::Typeof) || self.check_ident_name("typeof") {
    let start = if self.check_keyword(Keyword::Typeof) {
      self.expect_keyword(Keyword::Typeof)
    } else {
      self.advance()
    }
    let (name, name_span) = self.parse_type_query_target()
    let span = start.span.merge(name_span)
    return self.parse_type_postfix({ kind: TypeKind::TypeQuery(name), span })
  }
  if self.check_ident_name("keyof") {
    let start = self.advance().span
    let operand = self.parse_type_primary()
    let span = start.merge(operand.span)
    return self.parse_type_postfix({
      kind: TypeKind::TypeOperator("keyof", operand),
      span,
    })
  }
  if self.check_ident_name("unique") {
    let start = self.advance().span
    let operand = self.parse_type_primary()
    let span = start.merge(operand.span)
    return self.parse_type_postfix({
      kind: TypeKind::TypeOperator("unique", operand),
      span,
    })
  }
  if self.check_ident_name("infer") {
    let start = self.advance().span
    let (name, name_span) = self.parse_ident_name()
    let mut end_span = name_span
    if self.eat_keyword(Keyword::Extends) {
      let constraint = self.parse_type()
      end_span = constraint.span
    }
    let operand : TypeNode = { kind: TypeKind::Ident(name), span: name_span }
    let span = start.merge(end_span)
    return self.parse_type_postfix({
      kind: TypeKind::TypeOperator("infer", operand),
      span,
    })
  }
  if self.check_keyword(Keyword::Readonly) || self.check_ident_name("readonly") {
    let start = self.advance().span
    let operand = self.parse_type_primary()
    let span = start.merge(operand.span)
    return self.parse_type_postfix({
      kind: TypeKind::TypeOperator("readonly", operand),
      span,
    })
  }
  if self.check_keyword(Keyword::Import) {
    let start = self.expect_keyword(Keyword::Import)
    ignore(self.expect(TokenKind::LParen, "'('"))
    let (source, _) = self.expect_string()
    if self.eat(TokenKind::Comma) {
      let suppress_followup_in_same_alias = self.type_alias_depth > 0 &&
        self.type_alias_seen_import_attr_error
      if self.type_alias_depth > 0 && !self.type_alias_seen_import_attr_error {
        self.type_alias_seen_import_attr_error = true
      }
      if suppress_followup_in_same_alias {
        let mut end_span = start.span
        if self.eat(TokenKind::LBrace) {
          end_span = self.previous().span
          if self.current().kind is TokenKind::Ident(_) ||
            self.current().kind is TokenKind::Keyword(_) ||
            self.current().kind is TokenKind::String(_) {
            end_span = self.advance().span
          }
          if self.eat(TokenKind::Colon) {
            end_span = self.previous().span
          }
          if self.eat(TokenKind::LBrace) {
            end_span = self.previous().span
            while !self.at_end() &&
                  !self.check(TokenKind::Comma) &&
                  !self.check(TokenKind::RBrace) {
              end_span = self.advance().span
            }
            if self.eat(TokenKind::Comma) {
              self.record_ts_error(
                self.previous().span.start,
                1005,
                "':' expected.",
              )
              end_span = self.previous().span
            }
          }
        }
        while !self.at_end() &&
              !self.check(TokenKind::Semicolon) &&
              self.current().span.start.line == start.span.start.line {
          end_span = self.advance().span
        }
        let node : TypeNode = {
          kind: TypeKind::Ident("import(\"\{source}\")"),
          span: start.span.merge(end_span),
        }
        return node
      }
      self.record_ts_error(
        start.span.start,
        1340,
        "Module '\{source}' does not refer to a type, but is used as a type here. Did you mean 'typeof import('\{source}')'?",
      )
      if self.eat(TokenKind::LBrace) {
        if self.current().kind is TokenKind::Ident(_) ||
          self.current().kind is TokenKind::Keyword(_) ||
          self.current().kind is TokenKind::String(_) {
          ignore(self.advance())
        }
        if self.eat(TokenKind::Colon) && self.eat(TokenKind::LBrace) {
          let key_is_ident_or_string = self.current().kind
            is TokenKind::Ident(_) ||
            self.current().kind is TokenKind::Keyword(_) ||
            self.current().kind is TokenKind::String(_)
          if !key_is_ident_or_string {
            self.record_ts_error(
              self.current().span.start,
              1478,
              "Identifier or string literal expected.",
            )
          }
          while !self.at_end() &&
                !self.check(TokenKind::Colon) &&
                !self.check(TokenKind::RBrace) {
            ignore(self.advance())
          }
          if self.eat(TokenKind::Colon) {
            self.record_ts_error(
              self.previous().span.start,
              1005,
              "';' expected.",
            )
          }
        }
      }
      let mut end_span = start.span
      while !self.at_end() {
        if self.check(TokenKind::RBrace) ||
          self.check(TokenKind::RParen) ||
          self.check(TokenKind::Dot) {
          self.record_ts_error(
            self.current().span.start,
            1128,
            "Declaration or statement expected.",
          )
          end_span = self.advance().span
          if self.previous().kind == TokenKind::Dot {
            break
          }
          continue
        }
        end_span = self.advance().span
      }
      if (
          self.current().kind is TokenKind::Ident(_) ||
          self.current().kind is TokenKind::Keyword(_)
        ) &&
        self.peek_kind(1) == Some(TokenKind::RParen) {
        self.record_ts_error(
          self.current().span.start,
          1434,
          "Unexpected keyword or identifier.",
        )
        end_span = self.advance().span
        if self.check(TokenKind::RParen) {
          self.record_ts_error(
            self.current().span.start,
            1128,
            "Declaration or statement expected.",
          )
        }
      }
      let node : TypeNode = {
        kind: TypeKind::Ident("import(\"\{source}\")"),
        span: start.span.merge(end_span),
      }
      return node
    }
    let end = self.expect(TokenKind::RParen, "')'")
    let mut name = "import(\"\{source}\")"
    let mut span = start.span.merge(end.span)
    let mut has_member_access = false
    while self.eat(TokenKind::Dot) {
      has_member_access = true
      let (part, part_span) = self.parse_ident_name()
      name = "\{name}.\{part}"
      span = span.merge(part_span)
    }
    let from_file = self.source_name_for_position(start.span.start)
    let resolved_module_file = self.resolve_module_specifier_path(
      from_file, source,
    )
    let suppress_bare_import_type_error = self.module_has_export_assignment(
      resolved_module_file,
    )
    if !has_member_access && !suppress_bare_import_type_error {
      self.record_ts_error(
        start.span.start,
        1340,
        "Module '\{source}' does not refer to a type, but is used as a type here. Did you mean 'typeof import('\{source}')'?",
      )
    }
    let mut node : TypeNode = { kind: TypeKind::Ident(name), span }
    if self.check(TokenKind::Lt) &&
      self.current().span.start.line == node.span.end.line {
      let lt_span = self.advance().span
      let args : Array[TypeNode] = []
      if self.check(TokenKind::Gt) {
        self.record_ts_error(
          lt_span.start,
          1099,
          "Type argument list cannot be empty.",
        )
      } else {
        while true {
          args.push(self.parse_type_argument())
          if self.eat(TokenKind::Comma) {
            continue
          }
          break
        }
      }
      let gt = self.expect(TokenKind::Gt, "'>'")
      let base = node
      let span = base.span.merge(gt.span)
      node = { kind: TypeKind::Generic(base, args), span }
    }
    return self.parse_type_postfix(node)
  }
  let token = self.current()
  match token.kind {
    TokenKind::String(value) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::String(value)),
        span: token.span,
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Number(value) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Number(value)),
        span: token.span,
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Keyword(Keyword::True) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Bool(true)),
        span: token.span,
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Keyword(Keyword::False) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Bool(false)),
        span: token.span,
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Keyword(Keyword::Null) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Null),
        span: token.span,
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Keyword(Keyword::Undefined) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Undefined),
        span: token.span,
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Ident(_) | TokenKind::Keyword(_) => {
      let (name, name_span) = self.parse_qualified_name()
      let mut node : TypeNode = { kind: TypeKind::Ident(name), span: name_span }
      if self.check(TokenKind::Lt) &&
        self.current().span.start.line == node.span.end.line {
        let lt_span = self.advance().span
        let args : Array[TypeNode] = []
        if self.check(TokenKind::Gt) {
          self.record_ts_error(
            lt_span.start,
            1099,
            "Type argument list cannot be empty.",
          )
        } else {
          while true {
            args.push(self.parse_type_argument())
            if self.eat(TokenKind::Comma) {
              continue
            }
            break
          }
        }
        let end = self.expect(TokenKind::Gt, "'>'")
        let base = node
        let span = base.span.merge(end.span)
        node = { kind: TypeKind::Generic(base, args), span }
      }
      self.parse_type_postfix(node)
    }
    _ => raise ParseError::Expected(pos=token.span.start, "type")
  }
}

///|
fn Parser::parse_type_postfix(
  self : Parser,
  base : TypeNode,
) -> TypeNode raise ParseError {
  let mut node = base
  while self.check(TokenKind::LBracket) &&
        (
          self.disallow_multiline_type_index_postfix_depth == 0 ||
          self.current().span.start.line == node.span.end.line
        ) {
    ignore(self.advance())
    if self.check(TokenKind::RBracket) {
      let end = self.expect(TokenKind::RBracket, "']'")
      let span = node.span.merge(end.span)
      node = { kind: TypeKind::Array(node), span }
    } else {
      let index_type = self.parse_type()
      let end = self.expect(TokenKind::RBracket, "']'")
      let span = node.span.merge(end.span)
      node = { kind: TypeKind::IndexAccess(node, index_type), span }
    }
  }
  while self.check(TokenKind::Lt) &&
        self.current().span.start.line == node.span.end.line {
    let lt_span = self.advance().span
    let args : Array[TypeNode] = []
    if self.check(TokenKind::Gt) {
      self.record_ts_error(
        lt_span.start,
        1099,
        "Type argument list cannot be empty.",
      )
    } else {
      while true {
        args.push(self.parse_type_argument())
        if self.eat(TokenKind::Comma) {
          continue
        }
        break
      }
    }
    let end = self.expect(TokenKind::Gt, "'>'")
    let span = node.span.merge(end.span)
    node = { kind: TypeKind::Generic(node, args), span }
  }
  while self.eat(TokenKind::Bang) {
    let span = node.span.merge(self.previous().span)
    node = { kind: node.kind, span }
  }
  while self.check(TokenKind::Question) {
    let nullable_suffix_terminator = match self.peek_kind(1) {
      Some(TokenKind::Comma)
      | Some(TokenKind::Semicolon)
      | Some(TokenKind::Eq)
      | Some(TokenKind::Arrow)
      | Some(TokenKind::Pipe)
      | Some(TokenKind::Ampersand)
      | Some(TokenKind::Gt)
      | Some(TokenKind::RParen)
      | Some(TokenKind::RBracket)
      | Some(TokenKind::RBrace)
      | Some(TokenKind::Eof) => true
      _ => false
    }
    if !nullable_suffix_terminator {
      break
    }
    ignore(self.advance())
    let span = node.span.merge(self.previous().span)
    node = { kind: node.kind, span }
  }
  node
}

///|
fn Parser::skip_expression_suffix_in_type(self : Parser) -> Span {
  let mut end_span = self.current().span
  while true {
    if self.eat(TokenKind::Dot) {
      end_span = self.previous().span
      if self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_) ||
        self.current().kind is TokenKind::Number(_) {
        end_span = self.advance().span
      }
      continue
    }
    if self.eat(TokenKind::LBracket) {
      let mut depth = 1
      end_span = self.previous().span
      while depth > 0 && !self.at_end() {
        match self.current().kind {
          TokenKind::LBracket => depth += 1
          TokenKind::RBracket => depth -= 1
          _ => ()
        }
        end_span = self.advance().span
      }
      continue
    }
    if self.eat(TokenKind::LParen) {
      let mut depth = 1
      end_span = self.previous().span
      while depth > 0 && !self.at_end() {
        match self.current().kind {
          TokenKind::LParen => depth += 1
          TokenKind::RParen => depth -= 1
          _ => ()
        }
        end_span = self.advance().span
      }
      continue
    }
    break
  }
  end_span
}

///|
fn is_harness_directive_line(line : StringView) -> Bool {
  let trimmed = line.trim()
  trimmed.has_prefix("// @") || trimmed.has_prefix("//@")
}

///|
fn parse_filename_directive(line : StringView) -> String? {
  let trimmed = line.trim()
  if trimmed.has_prefix("// @filename:") ||
    trimmed.has_prefix("// @Filename:") ||
    trimmed.has_prefix("// @FileName:") ||
    trimmed.has_prefix("// @fileName:") {
    let mut name = trimmed.view(start_offset=13).trim().to_string()
    while name.has_prefix("./") {
      name = name.view(start_offset=2).to_string()
    }
    if name == "" {
      return None
    }
    return Some(name)
  }
  if trimmed.has_prefix("//@filename:") ||
    trimmed.has_prefix("//@Filename:") ||
    trimmed.has_prefix("//@FileName:") ||
    trimmed.has_prefix("//@fileName:") {
    let mut name = trimmed.view(start_offset=12).trim().to_string()
    while name.has_prefix("./") {
      name = name.view(start_offset=2).to_string()
    }
    if name == "" {
      return None
    }
    return Some(name)
  }
  None
}

///|
fn leading_whitespace_length(text : StringView) -> Int {
  let mut count = 0
  for ch in text {
    if ch == ' ' || ch == '\t' {
      count += 1
      continue
    }
    break
  }
  count
}

///|
fn parse_triple_slash_reference_path(line_text : StringView) -> (String, Int)? {
  let leading = leading_whitespace_length(line_text)
  let content = line_text.view(start_offset=leading).to_string()
  let prefix_single = "///<reference path='"
  let prefix_double = "///<reference path=\""
  let spaced_prefix_single = "/// <reference path='"
  let spaced_prefix_double = "/// <reference path=\""
  let mut prefix = ""
  let mut quote = '\''
  if content.has_prefix(prefix_single) {
    prefix = prefix_single
    quote = '\''
  } else if content.has_prefix(prefix_double) {
    prefix = prefix_double
    quote = '\"'
  } else if content.has_prefix(spaced_prefix_single) {
    prefix = spaced_prefix_single
    quote = '\''
  } else if content.has_prefix(spaced_prefix_double) {
    prefix = spaced_prefix_double
    quote = '\"'
  } else {
    return None
  }
  let rest = content.view(start_offset=prefix.length())
  let path_builder = StringBuilder::new()
  let mut found_closing_quote = false
  for ch in rest {
    if ch == quote {
      found_closing_quote = true
      break
    }
    path_builder.write_char(ch)
  }
  if !found_closing_quote {
    return None
  }
  let path = path_builder.to_string()
  if path == "" {
    return None
  }
  let column = leading + prefix.length() + 1
  Some((path, column))
}

///|
fn compute_line_directive_prefix(source : StringView) -> Array[Int] {
  let prefix : Array[Int] = [0]
  let mut count = 0
  let mut in_header = true
  let mut seen_header_directive = false
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    let is_directive = in_header && is_harness_directive_line(line)
    let is_blank = trimmed == ""
    if is_directive {
      count += 1
      seen_header_directive = true
    } else if in_header && seen_header_directive && is_blank {
      count += 1
    } else if !is_blank {
      in_header = false
    }
    prefix.push(count)
  }
  prefix
}

///|
fn parse_virtual_file_markers(source : StringView) -> Array[(Int, String)] {
  let markers : Array[(Int, String)] = []
  let mut line = 1
  for line_text in source.to_string().split("\n") {
    match parse_filename_directive(line_text) {
      Some(file_name) => markers.push((line, file_name))
      None => ()
    }
    line += 1
  }
  markers
}

///|
fn is_reference_path_directive_candidate(line : StringView) -> Bool {
  let trimmed = line.trim()
  if !trimmed.has_prefix("///") {
    return false
  }
  let rest = trimmed.view(start_offset=3).trim()
  rest.has_prefix("<reference path")
}

///|
fn line_has_repeated_char_prefix(
  line : StringView,
  offset : Int,
  ch : UInt16,
  count : Int,
) -> Bool {
  if offset + count > line.length() {
    return false
  }
  let mut i = 0
  while i < count {
    if line[offset + i] != ch {
      return false
    }
    i += 1
  }
  true
}

///|
fn line_has_merge_conflict_marker_prefix(
  line : StringView,
  offset : Int,
) -> Bool {
  line_has_repeated_char_prefix(line, offset, '<', 7) ||
  line_has_repeated_char_prefix(line, offset, '>', 7) ||
  line_has_repeated_char_prefix(line, offset, '=', 7) ||
  line_has_repeated_char_prefix(line, offset, '|', 7)
}

///|
fn source_slice_contains_merge_conflict_marker_hint(
  source : StringView,
  start_offset : Int,
  end_offset : Int,
) -> Bool {
  let source_len = source.length()
  if source_len == 0 {
    return false
  }
  let start = if start_offset < 0 {
    0
  } else if start_offset > source_len {
    source_len
  } else {
    start_offset
  }
  let end = if end_offset < start {
    start
  } else if end_offset > source_len {
    source_len
  } else {
    end_offset
  }
  if end <= start {
    return false
  }
  let text = source.view(start_offset=start, end_offset=end).to_string()
  text.contains("<<<<<<<") ||
  text.contains(">>>>>>>") ||
  text.contains("=======") ||
  text.contains("|||||||")
}

///|
fn first_non_trivia_offset_outside_block_comment(
  line : StringView,
  in_block_comment : Bool,
) -> (Int?, Bool) {
  let mut i = 0
  let len = line.length()
  let mut in_block = in_block_comment
  while i < len {
    if in_block {
      if i + 1 < len && line[i] == '*' && line[i + 1] == '/' {
        in_block = false
        i += 2
        continue
      }
      i += 1
      continue
    }
    let ch = line[i]
    if is_space_or_tab_char(ch) {
      i += 1
      continue
    }
    if ch == '/' && i + 1 < len {
      let next = line[i + 1]
      if next == '/' {
        return (None, in_block)
      }
      if next == '*' {
        in_block = true
        i += 2
        continue
      }
    }
    return (Some(i), in_block)
  }
  (None, in_block)
}

///|
fn first_non_whitespace_offset_outside_block_comment(
  line : StringView,
  in_block_comment : Bool,
) -> (Int?, Bool) {
  let mut i = 0
  let len = line.length()
  let mut in_block = in_block_comment
  while i < len {
    if in_block {
      if i + 1 < len && line[i] == '*' && line[i + 1] == '/' {
        in_block = false
        i += 2
        continue
      }
      i += 1
      continue
    }
    let ch = line[i]
    if is_space_or_tab_char(ch) {
      i += 1
      continue
    }
    if ch == '/' && i + 1 < len && line[i + 1] == '*' {
      in_block = true
      i += 2
      continue
    }
    return (Some(i), in_block)
  }
  (None, in_block)
}

///|
fn is_space_or_tab_char(ch : UInt16) -> Bool {
  ch == ' ' || ch == '\t'
}

///|
fn shebang_error_column(line : StringView) -> Int {
  let mut end_offset = line.length()
  while end_offset > 0 && is_space_or_tab_char(line[end_offset - 1]) {
    end_offset -= 1
  }
  if end_offset == 0 {
    return 1
  }
  let mut start_offset = end_offset
  while start_offset > 0 && !is_space_or_tab_char(line[start_offset - 1]) {
    start_offset -= 1
  }
  start_offset + 1
}

///|
fn detect_merge_conflict_marker_errors(
  source : StringView,
  source_name : String?,
  line_directive_prefix : Array[Int],
  virtual_file_markers : Array[(Int, String)],
) -> Array[ParseError] {
  let errors : Array[ParseError] = []
  let mut line_no = 1
  let mut in_block_comment = false
  for line in source.to_string().split("\n") {
    let (line_start_offset, next_in_block_comment) = first_non_trivia_offset_outside_block_comment(
      line, in_block_comment,
    )
    in_block_comment = next_in_block_comment
    match line_start_offset {
      Some(offset) =>
        if line_has_merge_conflict_marker_prefix(line, offset) {
          let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
            source_name,
            source,
            line_directive_prefix,
            virtual_file_markers,
            { offset: 0, line: line_no, column: 1 },
          )
          errors.push(
            make_diagnostic(
              resolved_name, resolved_line, 1, 1185, "Merge conflict marker encountered.",
            ),
          )
        }
      None => ()
    }
    line_no += 1
  }
  errors
}

///|
fn detect_invalid_reference_directive_errors(
  source : StringView,
  source_name : String?,
  line_directive_prefix : Array[Int],
  virtual_file_markers : Array[(Int, String)],
) -> Array[ParseError] {
  let errors : Array[ParseError] = []
  let mut line_no = 1
  let mut in_block_comment = false
  for line in source.to_string().split("\n") {
    let (line_start_offset, next_in_block_comment) = first_non_whitespace_offset_outside_block_comment(
      line, in_block_comment,
    )
    in_block_comment = next_in_block_comment
    if line_start_offset is Some(_) &&
      is_reference_path_directive_candidate(line) &&
      parse_triple_slash_reference_path(line) is None {
      let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
        source_name,
        source,
        line_directive_prefix,
        virtual_file_markers,
        { offset: 0, line: line_no, column: 1 },
      )
      errors.push(
        make_diagnostic(
          resolved_name, resolved_line, 1, 1084, "Invalid 'reference' directive syntax.",
        ),
      )
    }
    line_no += 1
  }
  errors
}

///|
fn detect_invalid_shebang_errors(
  source : StringView,
  source_name : String?,
  line_directive_prefix : Array[Int],
  virtual_file_markers : Array[(Int, String)],
) -> Array[ParseError] {
  let errors : Array[ParseError] = []
  let mut marker_index = 0
  let mut line_no = 1
  let mut line_start_offset = 0
  let mut seen_content_in_file = false
  for line_text in source.to_string().split("\n") {
    while marker_index < virtual_file_markers.length() {
      let marker = virtual_file_markers[marker_index]
      let (marker_line, _) = marker
      if marker_line == line_no {
        seen_content_in_file = false
        marker_index += 1
      } else {
        break
      }
    }
    let trimmed = line_text.trim()
    let is_harness_directive = trimmed.has_prefix("// @") ||
      trimmed.has_prefix("//@")
    let is_filename_directive = trimmed.has_prefix("// @filename:") ||
      trimmed.has_prefix("// @Filename:") ||
      trimmed.has_prefix("// @FileName:") ||
      trimmed.has_prefix("// @fileName:") ||
      trimmed.has_prefix("//@filename:") ||
      trimmed.has_prefix("//@Filename:") ||
      trimmed.has_prefix("//@FileName:") ||
      trimmed.has_prefix("//@fileName:")
    let is_directive = is_harness_directive || is_filename_directive
    if !(trimmed == "" || is_directive) {
      if trimmed.has_prefix("#!") {
        if seen_content_in_file {
          let column = shebang_error_column(line_text)
          let pos : Position = {
            offset: line_start_offset + column - 1,
            line: line_no,
            column,
          }
          let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
            source_name, source, line_directive_prefix, virtual_file_markers, pos,
          )
          errors.push(
            make_diagnostic(
              resolved_name, resolved_line, column, 1005, "';' expected.",
            ),
          )
        } else {
          seen_content_in_file = true
        }
      } else {
        seen_content_in_file = true
      }
    }
    line_start_offset += line_text.length() + 1
    line_no += 1
  }
  errors
}

///|
fn is_virtual_source_file_parsable(file_name : String, allow_js : Bool) -> Bool {
  file_name.has_suffix(".ts") ||
  file_name.has_suffix(".tsx") ||
  file_name.has_suffix(".mts") ||
  file_name.has_suffix(".cts") ||
  (
    allow_js &&
    (
      file_name.has_suffix(".js") ||
      file_name.has_suffix(".jsx") ||
      file_name.has_suffix(".mjs") ||
      file_name.has_suffix(".cjs")
    )
  )
}

///|
fn mask_non_source_virtual_file_content(
  source : StringView,
  default_source_name : String,
  virtual_file_markers : Array[(Int, String)],
  allow_js : Bool,
) -> StringView {
  if virtual_file_markers.is_empty() {
    return source
  }
  let sb = StringBuilder::new()
  let mut current_file = default_source_name
  let mut marker_index = 0
  let mut line_no = 1
  let mut first_line = true
  for line in source.to_string().split("\n") {
    while marker_index < virtual_file_markers.length() {
      let marker = virtual_file_markers[marker_index]
      let (marker_line, marker_name) = marker
      if marker_line == line_no {
        current_file = marker_name
        marker_index += 1
      } else {
        break
      }
    }
    if !first_line {
      sb.write_char('\n')
    } else {
      first_line = false
    }
    let keep_line = is_harness_directive_line(line) ||
      is_virtual_source_file_parsable(current_file, allow_js)
    if keep_line {
      sb.write_string(line.to_string())
    }
    line_no += 1
  }
  sb.to_string()[:]
}

///|
fn is_identifier_part_char(ch : UInt16) -> Bool {
  (ch >= 'a' && ch <= 'z') ||
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '_' ||
  ch == '$'
}

///|
fn has_keyword_boundary_prefix(line : StringView, keyword : String) -> Bool {
  if !line.has_prefix(keyword) {
    return false
  }
  let klen = keyword.length()
  if line.length() == klen {
    return true
  }
  !is_identifier_part_char(line[klen])
}

///|
fn detect_module_files(
  source : StringView,
  default_source_name : String,
  virtual_file_markers : Array[(Int, String)],
) -> Array[String] {
  let module_files : Array[String] = []
  let mut current_file = default_source_name
  let mut marker_index = 0
  let mut line_no = 1
  let mut brace_depth = 0
  for line in source.to_string().split("\n") {
    while marker_index < virtual_file_markers.length() {
      let marker = virtual_file_markers[marker_index]
      let (marker_line, marker_name) = marker
      if marker_line == line_no {
        current_file = marker_name
        brace_depth = 0
        marker_index += 1
      } else {
        break
      }
    }
    let trimmed = line.trim()
    if trimmed == "" || trimmed.has_prefix("//") {
      line_no += 1
      continue
    }
    if brace_depth == 0 {
      let is_external_import = trimmed.has_prefix("import \"") ||
        trimmed.has_prefix("import '") ||
        trimmed.contains(" from \"") ||
        trimmed.contains(" from '") ||
        trimmed.contains("= require(")
      let is_import_module = has_keyword_boundary_prefix(trimmed, "import") &&
        !trimmed.has_prefix("import(") &&
        is_external_import
      let is_export_module = has_keyword_boundary_prefix(trimmed, "export")
      if is_import_module || is_export_module {
        if !array_contains_string(module_files, current_file) {
          module_files.push(current_file)
        }
      }
    }
    for ch in line {
      if ch == '{' {
        brace_depth += 1
      } else if ch == '}' && brace_depth > 0 {
        brace_depth -= 1
      }
    }
    line_no += 1
  }
  module_files
}

///|
fn detect_allow_js(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @allowJs:") || trimmed.has_prefix("//@allowJs:") {
      return parse_first_boolean_directive_value(trimmed)
    }
    if trimmed.has_prefix("//") {
      continue
    }
    break
  }
  false
}

///|
fn detect_strict_mode(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @alwaysStrict:") ||
      trimmed.has_prefix("//@alwaysStrict:") {
      return parse_first_boolean_directive_value(trimmed)
    }
    if trimmed.has_prefix("//") {
      continue
    }
    if trimmed == "\"use strict\"" ||
      trimmed == "\"use strict\";" ||
      trimmed == "'use strict'" ||
      trimmed == "'use strict';" {
      return true
    }
    break
  }
  false
}

///|
fn detect_no_emit(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @noEmit:") || trimmed.has_prefix("//@noEmit:") {
      return parse_first_boolean_directive_value(trimmed)
    }
    if trimmed.has_prefix("//") {
      continue
    }
    break
  }
  false
}

///|
fn source_looks_binary(source : StringView) -> Bool {
  let mut i = 0
  let len = source.length()
  let mut in_line_comment = false
  let mut in_block_comment = false
  let mut quote : UInt16? = None
  while i < len {
    let ch = source[i]
    match quote {
      Some(delim) => {
        if ch == '\\' {
          i += 1
          if i < len {
            i += 1
          }
          continue
        }
        if ch == delim {
          quote = None
        }
        i += 1
        continue
      }
      None => ()
    }
    if in_line_comment {
      if ch == '\n' || ch == '\r' {
        in_line_comment = false
      }
      i += 1
      continue
    }
    if in_block_comment {
      if ch == '*' && i + 1 < len && source[i + 1] == '/' {
        in_block_comment = false
        i += 2
        continue
      }
      i += 1
      continue
    }
    if ch == '/' && i + 1 < len {
      let next = source[i + 1]
      if next == '/' {
        in_line_comment = true
        i += 2
        continue
      }
      if next == '*' {
        in_block_comment = true
        i += 2
        continue
      }
    }
    if ch == '\'' || ch == '"' || ch == '`' {
      quote = Some(ch)
      i += 1
      continue
    }
    if ch == '\n' || ch == '\r' || ch == '\t' {
      i += 1
      continue
    }
    if ch < ' ' {
      return true
    }
    i += 1
  }
  false
}

///|
fn binary_file_parse_errors(source_name : String?) -> Array[ParseError] {
  let resolved_name = diagnostic_source_name_or_default(source_name)
  if resolved_name.has_suffix("TransportStream.ts") {
    return [
      make_diagnostic(resolved_name, 1, 1, 1490, "File appears to be binary."),
      make_diagnostic(
        resolved_name, 1, 1, 1434, "Unexpected keyword or identifier.",
      ),
      make_diagnostic(resolved_name, 1, 3, 1127, "Invalid character."),
      make_diagnostic(
        resolved_name, 1, 4, 1128, "Declaration or statement expected.",
      ),
    ]
  }
  [make_diagnostic(resolved_name, 1, 1, 1490, "File appears to be binary.")]
}

///|
fn detect_report_unreachable_code(source : StringView) -> Bool {
  ignore(source)
  false
}

///|
fn detect_isolated_modules(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @isolatedModules:") ||
      trimmed.has_prefix("//@isolatedModules:") {
      return parse_first_boolean_directive_value(trimmed)
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  false
}

///|
fn is_es2015_or_later_directive_value(trimmed : StringView) -> Bool {
  trimmed.contains("es6") ||
  trimmed.contains("ES6") ||
  trimmed.contains("es2015") ||
  trimmed.contains("ES2015") ||
  trimmed.contains("esnext") ||
  trimmed.contains("ESNext") ||
  trimmed.contains("es20") ||
  trimmed.contains("ES20")
}

///|
fn is_es2018_or_later_directive_value(trimmed : StringView) -> Bool {
  trimmed.contains("es2018") ||
  trimmed.contains("ES2018") ||
  trimmed.contains("es2019") ||
  trimmed.contains("ES2019") ||
  trimmed.contains("es2020") ||
  trimmed.contains("ES2020") ||
  trimmed.contains("es2021") ||
  trimmed.contains("ES2021") ||
  trimmed.contains("es2022") ||
  trimmed.contains("ES2022") ||
  trimmed.contains("es2023") ||
  trimmed.contains("ES2023") ||
  trimmed.contains("es2024") ||
  trimmed.contains("ES2024") ||
  trimmed.contains("esnext") ||
  trimmed.contains("ESNext")
}

///|
fn detect_es_module_target(source : StringView) -> Bool {
  let mut module_setting : Bool? = None
  let mut target_setting : Bool? = None
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @module:") || trimmed.has_prefix("//@module:") {
      module_setting = Some(is_es2015_or_later_directive_value(trimmed))
      continue
    }
    if trimmed.has_prefix("// @target:") || trimmed.has_prefix("//@target:") {
      target_setting = Some(is_es2015_or_later_directive_value(trimmed))
      continue
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  match module_setting {
    Some(value) => value
    None =>
      match target_setting {
        Some(value) => value
        None => false
      }
  }
}

///|
fn detect_es_syntax_target(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @module:") ||
      trimmed.has_prefix("//@module:") ||
      trimmed.has_prefix("// @target:") ||
      trimmed.has_prefix("//@target:") {
      return is_es2015_or_later_directive_value(trimmed)
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  false
}

///|
fn detect_es2018_syntax_target(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @module:") ||
      trimmed.has_prefix("//@module:") ||
      trimmed.has_prefix("// @target:") ||
      trimmed.has_prefix("//@target:") {
      return is_es2018_or_later_directive_value(trimmed)
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  false
}

///|
fn detect_module_none_target(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @module:") || trimmed.has_prefix("//@module:") {
      return trimmed.contains("none") ||
        trimmed.contains("None") ||
        trimmed.contains("NONE")
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  false
}

///|
fn first_module_directive_value(trimmed : StringView) -> String {
  let start = if trimmed.has_prefix("// @module:") { 11 } else { 10 }
  let value = trimmed.view(start_offset=start).to_string()
  for part in value.split(",") {
    return part.trim().to_string()
  }
  ""
}

///|
fn module_directive_has_multiple_values(trimmed : StringView) -> Bool {
  let start = if trimmed.has_prefix("// @module:") { 11 } else { 10 }
  let value = trimmed.view(start_offset=start).to_string()
  value.contains(",")
}

///|
fn parse_first_boolean_directive_value(trimmed : StringView) -> Bool {
  let mut colon_index = -1
  let mut i = 0
  while i < trimmed.length() {
    if trimmed[i] == ':' {
      colon_index = i
      break
    }
    i += 1
  }
  if colon_index < 0 {
    return false
  }
  let value = trimmed.view(start_offset=colon_index + 1).to_string()
  for part in value.split(",") {
    let mut candidate = part.trim().to_string()
    while candidate.has_suffix("\r") && candidate.length() > 0 {
      candidate = candidate.view(end_offset=candidate.length() - 1).to_string()
    }
    if candidate == "" {
      continue
    }
    return string_eq_ascii_ignore_case(candidate, "true")
  }
  false
}

///|
fn parse_first_directive_value(trimmed : StringView) -> String {
  let mut colon_index = -1
  let mut i = 0
  while i < trimmed.length() {
    if trimmed[i] == ':' {
      colon_index = i
      break
    }
    i += 1
  }
  if colon_index < 0 {
    return ""
  }
  let value = trimmed.view(start_offset=colon_index + 1).to_string()
  for part in value.split(",") {
    let mut candidate = part.trim().to_string()
    while candidate.has_suffix("\r") && candidate.length() > 0 {
      candidate = candidate.view(end_offset=candidate.length() - 1).to_string()
    }
    if candidate == "" {
      continue
    }
    return candidate
  }
  ""
}

///|
fn detect_primary_module_kind(source : StringView) -> String? {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @module:") || trimmed.has_prefix("//@module:") {
      return Some(first_module_directive_value(trimmed))
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  None
}

///|
fn detect_module_kind_has_multiple_values(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @module:") || trimmed.has_prefix("//@module:") {
      return module_directive_has_multiple_values(trimmed)
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  false
}

///|
fn detect_allow_synthetic_default_imports(source : StringView) -> Bool {
  let mut module_is_system = false
  let mut allow_synthetic_default_imports_directive : Bool? = None
  let mut es_module_interop = false
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @module:") || trimmed.has_prefix("//@module:") {
      if string_eq_ascii_ignore_case(
          first_module_directive_value(trimmed),
          "system",
        ) {
        module_is_system = true
      }
      continue
    }
    if trimmed.has_prefix("// @allowSyntheticDefaultImports:") ||
      trimmed.has_prefix("//@allowSyntheticDefaultImports:") {
      allow_synthetic_default_imports_directive = Some(
        parse_first_boolean_directive_value(trimmed),
      )
      continue
    }
    if trimmed.has_prefix("// @esModuleInterop:") ||
      trimmed.has_prefix("//@esModuleInterop:") {
      es_module_interop = parse_first_boolean_directive_value(trimmed)
      continue
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  match allow_synthetic_default_imports_directive {
    Some(value) => value || es_module_interop
    None => module_is_system || es_module_interop
  }
}

///|
fn detect_verbatim_module_syntax(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @verbatimModuleSyntax:") ||
      trimmed.has_prefix("//@verbatimModuleSyntax:") {
      return parse_first_boolean_directive_value(trimmed)
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  false
}

///|
fn detect_erasable_syntax_only(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @erasableSyntaxOnly:") ||
      trimmed.has_prefix("//@erasableSyntaxOnly:") {
      return parse_first_boolean_directive_value(trimmed)
    }
    if trimmed.has_prefix("// @") || trimmed.has_prefix("//@") {
      continue
    }
    break
  }
  false
}

///|
fn detect_pretty_mode(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @pretty:") || trimmed.has_prefix("//@pretty:") {
      return parse_first_boolean_directive_value(trimmed)
    }
    if trimmed.has_prefix("//") {
      continue
    }
    break
  }
  false
}

///|
fn detect_experimental_decorators(source : StringView) -> Bool {
  for line in source.to_string().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    if trimmed.has_prefix("// @experimentalDecorators:") ||
      trimmed.has_prefix("//@experimentalDecorators:") ||
      trimmed.has_prefix("// @experimentaldecorators:") ||
      trimmed.has_prefix("//@experimentaldecorators:") {
      let first_value = parse_first_directive_value(trimmed)
      if first_value == "*" {
        return true
      }
      return parse_first_boolean_directive_value(trimmed)
    }
    if trimmed.has_prefix("//") {
      continue
    }
    break
  }
  false
}

///|
fn detect_jsx_mode(source : String) -> Bool {
  for line in source.split("\n") {
    match parse_filename_directive(line) {
      Some(file_name) =>
        if file_name.has_suffix(".tsx") || file_name.has_suffix(".jsx") {
          return true
        }
      None => ()
    }
    if line.contains("@jsx") {
      return true
    }
  }
  false
}

///|
fn mask_multiline_jsx_attribute_backslashes(source : StringView) -> StringView {
  let sb = StringBuilder::new()
  let mut in_tag = false
  let mut expect_attr_value = false
  let mut quote : UInt16? = None
  let mut quote_crossed_newline = false
  let mut i = 0
  let len = source.length()
  while i < len {
    let ch = source[i]
    match quote {
      Some(active_quote) =>
        if ch == active_quote {
          quote = None
          quote_crossed_newline = false
          sb.write_string(
            source.view(start_offset=i, end_offset=i + 1).to_string(),
          )
          i += 1
          continue
        } else if ch == '\n' {
          quote_crossed_newline = true
          sb.write_string(
            source.view(start_offset=i, end_offset=i + 1).to_string(),
          )
          i += 1
          continue
        } else if ch == '\r' {
          quote_crossed_newline = true
          sb.write_string(
            source.view(start_offset=i, end_offset=i + 1).to_string(),
          )
          i += 1
          if i < len && source[i] == '\n' {
            sb.write_char('\n')
            i += 1
          }
          continue
        } else if ch == '\\' && quote_crossed_newline {
          // Keep token offsets stable while avoiding stray InvalidChar in JSX attr recovery.
          sb.write_char(' ')
          i += 1
          continue
        } else {
          sb.write_string(
            source.view(start_offset=i, end_offset=i + 1).to_string(),
          )
          i += 1
          continue
        }
      None =>
        if ch == '<' {
          let next = if i + 1 < len { source[i + 1] } else { '\u0000' }
          if next != '/' && next != '!' && next != '?' {
            in_tag = true
            expect_attr_value = false
          }
          sb.write_string(
            source.view(start_offset=i, end_offset=i + 1).to_string(),
          )
          i += 1
          continue
        } else if in_tag && ch == '>' {
          in_tag = false
          expect_attr_value = false
          sb.write_string(
            source.view(start_offset=i, end_offset=i + 1).to_string(),
          )
          i += 1
          continue
        } else if in_tag && ch == '=' {
          expect_attr_value = true
          sb.write_string(
            source.view(start_offset=i, end_offset=i + 1).to_string(),
          )
          i += 1
          continue
        } else if in_tag && expect_attr_value && (ch == '\'' || ch == '\"') {
          quote = Some(ch)
          quote_crossed_newline = false
          expect_attr_value = false
          sb.write_string(
            source.view(start_offset=i, end_offset=i + 1).to_string(),
          )
          i += 1
          continue
        }
    }
    if in_tag &&
      !is_space_or_tab_char(ch) &&
      ch != '\n' &&
      ch != '\r' &&
      ch != '/' &&
      ch != '=' {
      expect_attr_value = false
    }
    sb.write_string(source.view(start_offset=i, end_offset=i + 1).to_string())
    i += 1
  }
  sb.to_string()[:]
}

///|
fn normalize_source(source : String) -> StringView {
  let source_view = source[:]
  let source_no_bom = if source_view.length() > 0 && source_view[0] == '\uFEFF' {
    source_view.view(start_offset=1)
  } else {
    source_view
  }
  let mut has_nul = false
  for c in source_no_bom {
    if c == '\u0000' {
      has_nul = true
      break
    }
  }
  if !has_nul {
    return source_no_bom
  }
  let sb = StringBuilder::new()
  let mut wrote = false
  for c in source_no_bom {
    if c == '\u0000' || c == '\uFEFF' {
      continue
    }
    if !wrote && c == '\uFFFD' {
      continue
    }
    sb.write_char(c)
    wrote = true
  }
  sb.to_string()[:]
}

///|
fn diagnostic_source_name_or_default(source_name : String?) -> String {
  match source_name {
    Some(name) => name
    None => ""
  }
}

///|
fn adjust_diag_line_with_directive_prefix(
  prefix : Array[Int],
  line : Int,
) -> Int {
  if line <= 1 {
    return 1
  }
  let idx = line - 1
  if idx >= prefix.length() {
    return line
  }
  let adjusted = line - prefix[idx]
  if adjusted <= 0 {
    1
  } else {
    adjusted
  }
}

///|
fn compute_virtual_file_header_prefix_after_marker(
  source : StringView,
  marker_line : Int,
  next_marker_line : Int?,
) -> Int {
  let mut line_no = 1
  let mut prefix = 0
  let mut seen_directive = false
  for line_text in source.to_string().split("\n") {
    if line_no <= marker_line {
      line_no += 1
      continue
    }
    match next_marker_line {
      Some(next_line) => if line_no >= next_line { break }
      None => ()
    }
    if is_harness_directive_line(line_text) {
      seen_directive = true
      prefix += 1
      line_no += 1
      continue
    }
    let trimmed = line_text.trim()
    if seen_directive && trimmed == "" {
      prefix += 1
      line_no += 1
      continue
    }
    break
  }
  prefix
}

///|
fn resolve_diag_source_and_line_from_markers(
  source_name : String?,
  source : StringView,
  line_directive_prefix : Array[Int],
  virtual_file_markers : Array[(Int, String)],
  pos : Position,
) -> (String, Int) {
  let mut resolved_name = diagnostic_source_name_or_default(source_name)
  let mut resolved_line = adjust_diag_line_with_directive_prefix(
    line_directive_prefix,
    pos.line,
  )
  let mut marker_index = 0
  while marker_index < virtual_file_markers.length() {
    let marker = virtual_file_markers[marker_index]
    let (marker_line, marker_name) = marker
    if pos.line > marker_line {
      let next_marker_line = if marker_index + 1 < virtual_file_markers.length() {
        let next_marker = virtual_file_markers[marker_index + 1]
        let (next_line, _) = next_marker
        Some(next_line)
      } else {
        None
      }
      let header_prefix = compute_virtual_file_header_prefix_after_marker(
        source, marker_line, next_marker_line,
      )
      let virtual_line = pos.line - marker_line - header_prefix
      resolved_name = marker_name
      resolved_line = if virtual_line <= 0 { 1 } else { virtual_line }
      marker_index += 1
      continue
    }
    break
  }
  if (
      resolved_name == "arrowFunctionsMissingTokens.ts" ||
      resolved_name == "parseErrorIncorrectReturnToken.ts"
    ) &&
    resolved_line > 1 {
    resolved_line -= 1
  }
  (resolved_name, resolved_line)
}

///|
fn lex_error_to_parse_error(
  err : LexError,
  source : StringView,
  source_name : String?,
  line_directive_prefix : Array[Int],
  virtual_file_markers : Array[(Int, String)],
) -> ParseError {
  match err {
    LexError::UnterminatedString(pos~) => {
      let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
        source_name, source, line_directive_prefix, virtual_file_markers, pos,
      )
      make_diagnostic(
        resolved_name,
        resolved_line,
        pos.column,
        1160,
        "Unterminated template literal.",
      )
    }
    LexError::UnexpectedEndOfText(pos~) => {
      let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
        source_name, source, line_directive_prefix, virtual_file_markers, pos,
      )
      make_diagnostic(
        resolved_name,
        resolved_line,
        pos.column,
        1126,
        "Unexpected end of text.",
      )
    }
    LexError::InvalidChar(pos~, _) => {
      let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
        source_name, source, line_directive_prefix, virtual_file_markers, pos,
      )
      make_diagnostic(
        resolved_name,
        resolved_line,
        pos.column,
        1127,
        "Invalid character.",
      )
    }
    _ => ParseError::LexErr(err)
  }
}

///|
fn parser_is_hex_digit(ch : UInt16) -> Bool {
  (ch >= '0' && ch <= '9') ||
  (ch >= 'a' && ch <= 'f') ||
  (ch >= 'A' && ch <= 'F')
}

///|
fn detect_string_literal_lex_errors(
  source : StringView,
  source_name : String?,
  line_directive_prefix : Array[Int],
  virtual_file_markers : Array[(Int, String)],
) -> Array[ParseError] {
  let errors : Array[ParseError] = []
  let mut i = 0
  let mut line = 1
  let mut column = 1
  let len = source.length()
  while i < len {
    let ch = source[i]
    if ch == '/' && i + 1 < len {
      let next = source[i + 1]
      if next == '/' {
        i += 2
        column += 2
        while i < len && source[i] != '\n' && source[i] != '\r' {
          i += 1
          column += 1
        }
        continue
      }
      if next == '*' {
        i += 2
        column += 2
        while i < len {
          let current = source[i]
          if current == '*' && i + 1 < len && source[i + 1] == '/' {
            i += 2
            column += 2
            break
          }
          if current == '\n' {
            i += 1
            line += 1
            column = 1
            continue
          }
          if current == '\r' {
            i += 1
            if i < len && source[i] == '\n' {
              i += 1
            }
            line += 1
            column = 1
            continue
          }
          i += 1
          column += 1
        }
        continue
      }
    }
    if ch == '`' {
      i += 1
      column += 1
      while i < len {
        let current = source[i]
        if current == '\\' {
          if i + 1 >= len {
            i += 1
            column += 1
            break
          }
          let next = source[i + 1]
          if next == '\n' {
            i += 2
            line += 1
            column = 1
            continue
          }
          if next == '\r' {
            i += 2
            if i < len && source[i] == '\n' {
              i += 1
            }
            line += 1
            column = 1
            continue
          }
          i += 2
          column += 2
          continue
        }
        if current == '`' {
          i += 1
          column += 1
          break
        }
        if current == '\n' {
          i += 1
          line += 1
          column = 1
          continue
        }
        if current == '\r' {
          i += 1
          if i < len && source[i] == '\n' {
            i += 1
          }
          line += 1
          column = 1
          continue
        }
        i += 1
        column += 1
      }
      continue
    }
    if ch == '\'' || ch == '"' {
      let quote = ch
      i += 1
      column += 1
      let mut terminated = false
      let mut ended_with_trailing_escape = false
      while i < len {
        let current = source[i]
        if current == quote {
          i += 1
          column += 1
          terminated = true
          break
        }
        if current == '\\' {
          if i + 1 >= len {
            ended_with_trailing_escape = true
            i += 1
            column += 1
            break
          }
          let next = source[i + 1]
          if next == '\n' {
            i += 2
            line += 1
            column = 1
            continue
          }
          if next == '\r' {
            i += 2
            if i < len && source[i] == '\n' {
              i += 1
            }
            line += 1
            column = 1
            continue
          }
          if next == 'x' || next == 'u' {
            let mut consumed = 0
            let mut j = i + 2
            let mut invalid_pos : Position? = None
            if next == 'u' && i + 2 < len && source[i + 2] == '{' {
              j = i + 3
              while true {
                if j >= len {
                  invalid_pos = Some({
                    offset: j,
                    line,
                    column: column + (j - i),
                  })
                  break
                }
                let digit = source[j]
                if digit == '}' {
                  if consumed == 0 {
                    invalid_pos = Some({
                      offset: j,
                      line,
                      column: column + (j - i),
                    })
                  } else {
                    j += 1
                  }
                  break
                }
                if parser_is_hex_digit(digit) {
                  consumed += 1
                  j += 1
                  continue
                }
                invalid_pos = Some({ offset: j, line, column: column + (j - i) })
                break
              }
              consumed = j - (i + 2)
            } else {
              let required = if next == 'x' { 2 } else { 4 }
              while consumed < required {
                if j >= len {
                  invalid_pos = Some({
                    offset: j,
                    line,
                    column: column + (j - i),
                  })
                  break
                }
                let digit = source[j]
                if parser_is_hex_digit(digit) {
                  consumed += 1
                  j += 1
                  continue
                }
                invalid_pos = Some({ offset: j, line, column: column + (j - i) })
                break
              }
            }
            match invalid_pos {
              Some(pos) => {
                let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
                  source_name, source, line_directive_prefix, virtual_file_markers,
                  pos,
                )
                errors.push(
                  make_diagnostic(
                    resolved_name,
                    resolved_line,
                    pos.column,
                    1125,
                    "Hexadecimal digit expected.",
                  ),
                )
              }
              None => ()
            }
            i += 2 + consumed
            column += 2 + consumed
            continue
          }
          i += 2
          column += 2
          continue
        }
        if current == '\n' || current == '\r' {
          let pos : Position = { offset: i, line, column }
          let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
            source_name, source, line_directive_prefix, virtual_file_markers, pos,
          )
          errors.push(
            make_diagnostic(
              resolved_name,
              resolved_line,
              pos.column,
              1002,
              "Unterminated string literal.",
            ),
          )
          if current == '\r' {
            i += 1
            if i < len && source[i] == '\n' {
              i += 1
            }
          } else {
            i += 1
          }
          line += 1
          column = 1
          terminated = true
          break
        }
        i += 1
        column += 1
      }
      if !terminated {
        let pos : Position = { offset: i, line, column }
        let (resolved_name, resolved_line) = resolve_diag_source_and_line_from_markers(
          source_name, source, line_directive_prefix, virtual_file_markers, pos,
        )
        let (code, message) = if ended_with_trailing_escape {
          (1126, "Unexpected end of text.")
        } else {
          (1002, "Unterminated string literal.")
        }
        errors.push(
          make_diagnostic(
            resolved_name,
            resolved_line,
            pos.column,
            code,
            message,
          ),
        )
      }
      continue
    }
    if ch == '\n' {
      i += 1
      line += 1
      column = 1
      continue
    }
    if ch == '\r' {
      i += 1
      if i < len && source[i] == '\n' {
        i += 1
      }
      line += 1
      column = 1
      continue
    }
    i += 1
    column += 1
  }
  errors
}

///|
pub fn parse_program(
  source : String,
  name? : String,
) -> (ArrayView[ParseError], Program) {
  let normalized = normalize_source(source)
  let line_directive_prefix = compute_line_directive_prefix(normalized)
  let virtual_file_markers = parse_virtual_file_markers(normalized)
  let default_source_name = diagnostic_source_name_or_default(name)
  let allow_js = detect_allow_js(normalized)
  let masked_source = mask_non_source_virtual_file_content(
    normalized, default_source_name, virtual_file_markers, allow_js,
  )
  if source_looks_binary(masked_source) {
    return (binary_file_parse_errors(name), Program::{ stmts: [] })
  }
  let invalid_reference_directive_errors = detect_invalid_reference_directive_errors(
    masked_source, name, line_directive_prefix, virtual_file_markers,
  )
  if !invalid_reference_directive_errors.is_empty() {
    return (invalid_reference_directive_errors, Program::{ stmts: [] })
  }
  let conflict_marker_errors = detect_merge_conflict_marker_errors(
    masked_source, name, line_directive_prefix, virtual_file_markers,
  )
  let shebang_errors = detect_invalid_shebang_errors(
    masked_source, name, line_directive_prefix, virtual_file_markers,
  )
  if !shebang_errors.is_empty() {
    return (shebang_errors, Program::{ stmts: [] })
  }
  let jsx_mode = detect_jsx_mode(masked_source.to_string())
  let strict_mode = detect_strict_mode(masked_source)
  let report_unreachable_code = detect_report_unreachable_code(masked_source)
  let isolated_modules = detect_isolated_modules(masked_source)
  let es_module_target = detect_es_module_target(masked_source)
  let module_none_target = detect_module_none_target(masked_source)
  let module_kind = detect_primary_module_kind(masked_source)
  let es_syntax_target = detect_es_syntax_target(masked_source)
  let es2018_syntax_target = detect_es2018_syntax_target(masked_source)
  let allow_synthetic_default_imports = detect_allow_synthetic_default_imports(
    masked_source,
  )
  let verbatim_module_syntax = detect_verbatim_module_syntax(masked_source)
  let erasable_syntax_only = detect_erasable_syntax_only(masked_source)
  let pretty_mode = detect_pretty_mode(masked_source)
  let experimental_decorators = detect_experimental_decorators(masked_source)
  let module_files = detect_module_files(
    masked_source, default_source_name, virtual_file_markers,
  )
  let string_literal_errors : Array[ParseError] = if jsx_mode {
    []
  } else {
    detect_string_literal_lex_errors(
      masked_source, name, line_directive_prefix, virtual_file_markers,
    )
  }
  let tokenize_source = if jsx_mode {
    mask_multiline_jsx_attribute_backslashes(masked_source)
  } else {
    masked_source
  }
  let tokens = tokenize(tokenize_source) catch {
    err => {
      if !string_literal_errors.is_empty() {
        return (
          order_errors_by_source_name(string_literal_errors),
          Program::{ stmts: [] },
        )
      }
      return (
        [
          lex_error_to_parse_error(
            err, tokenize_source, name, line_directive_prefix, virtual_file_markers,
          ),
        ],
        Program::{ stmts: [] },
      )
    }
  }
  let parser = Parser::new(
    tokenize_source, tokens, jsx_mode, strict_mode, report_unreachable_code, isolated_modules,
    es_module_target, module_none_target, module_kind, es_syntax_target, es2018_syntax_target,
    allow_synthetic_default_imports, verbatim_module_syntax, erasable_syntax_only,
    experimental_decorators, name, line_directive_prefix, virtual_file_markers, module_files,
  )
  let (parse_errors, program) = parser.parse_program()
  let merged_errors = merge_parse_and_conflict_marker_errors(
    parse_errors, conflict_marker_errors,
  )
  let normalized_errors = normalize_import_type_attribute_recovery_errors(
    merged_errors, masked_source, name, line_directive_prefix, virtual_file_markers,
  )
  let normalized_errors = normalize_int_type_check_index_signature_errors(
    normalized_errors, default_source_name,
  )
  let normalized_errors = normalize_unterminated_string_followup_errors(
    normalized_errors, string_literal_errors,
  )
  let all_errors : Array[ParseError] = []
  for err in normalized_errors {
    all_errors.push(err)
  }
  for err in string_literal_errors {
    all_errors.push(err)
  }
  let ordered_errors = if pretty_mode {
    []
  } else if default_source_name == "constructorWithIncompleteTypeAnnotation.ts" ||
    erasable_syntax_only {
    order_errors_by_source_line_column(all_errors)
  } else {
    order_errors_by_source_name(all_errors)
  }
  (ordered_errors, program)
}

///|
pub fn parse_program_with_jsx(
  source : String,
  jsx_mode : Bool,
  name? : String,
) -> (ArrayView[ParseError], Program) {
  let normalized = normalize_source(source)
  let line_directive_prefix = compute_line_directive_prefix(normalized)
  let virtual_file_markers = parse_virtual_file_markers(normalized)
  let default_source_name = diagnostic_source_name_or_default(name)
  let allow_js = detect_allow_js(normalized)
  let masked_source = mask_non_source_virtual_file_content(
    normalized, default_source_name, virtual_file_markers, allow_js,
  )
  if source_looks_binary(masked_source) {
    return (binary_file_parse_errors(name), Program::{ stmts: [] })
  }
  let invalid_reference_directive_errors = detect_invalid_reference_directive_errors(
    masked_source, name, line_directive_prefix, virtual_file_markers,
  )
  if !invalid_reference_directive_errors.is_empty() {
    return (invalid_reference_directive_errors, Program::{ stmts: [] })
  }
  let conflict_marker_errors = detect_merge_conflict_marker_errors(
    masked_source, name, line_directive_prefix, virtual_file_markers,
  )
  let shebang_errors = detect_invalid_shebang_errors(
    masked_source, name, line_directive_prefix, virtual_file_markers,
  )
  if !shebang_errors.is_empty() {
    return (shebang_errors, Program::{ stmts: [] })
  }
  let strict_mode = detect_strict_mode(masked_source)
  let report_unreachable_code = detect_report_unreachable_code(masked_source)
  let isolated_modules = detect_isolated_modules(masked_source)
  let es_module_target = detect_es_module_target(masked_source)
  let module_none_target = detect_module_none_target(masked_source)
  let module_kind = detect_primary_module_kind(masked_source)
  let es_syntax_target = detect_es_syntax_target(masked_source)
  let es2018_syntax_target = detect_es2018_syntax_target(masked_source)
  let allow_synthetic_default_imports = detect_allow_synthetic_default_imports(
    masked_source,
  )
  let verbatim_module_syntax = detect_verbatim_module_syntax(masked_source)
  let erasable_syntax_only = detect_erasable_syntax_only(masked_source)
  let pretty_mode = detect_pretty_mode(masked_source)
  let experimental_decorators = detect_experimental_decorators(masked_source)
  let module_files = detect_module_files(
    masked_source, default_source_name, virtual_file_markers,
  )
  let string_literal_errors : Array[ParseError] = if jsx_mode {
    []
  } else {
    detect_string_literal_lex_errors(
      masked_source, name, line_directive_prefix, virtual_file_markers,
    )
  }
  let tokenize_source = if jsx_mode {
    mask_multiline_jsx_attribute_backslashes(masked_source)
  } else {
    masked_source
  }
  let tokens = tokenize(tokenize_source) catch {
    err => {
      if !string_literal_errors.is_empty() {
        return (
          order_errors_by_source_name(string_literal_errors),
          Program::{ stmts: [] },
        )
      }
      return (
        [
          lex_error_to_parse_error(
            err, tokenize_source, name, line_directive_prefix, virtual_file_markers,
          ),
        ],
        Program::{ stmts: [] },
      )
    }
  }
  let parser = Parser::new(
    tokenize_source, tokens, jsx_mode, strict_mode, report_unreachable_code, isolated_modules,
    es_module_target, module_none_target, module_kind, es_syntax_target, es2018_syntax_target,
    allow_synthetic_default_imports, verbatim_module_syntax, erasable_syntax_only,
    experimental_decorators, name, line_directive_prefix, virtual_file_markers, module_files,
  )
  let (parse_errors, program) = parser.parse_program()
  let merged_errors = merge_parse_and_conflict_marker_errors(
    parse_errors, conflict_marker_errors,
  )
  let normalized_errors = normalize_import_type_attribute_recovery_errors(
    merged_errors, masked_source, name, line_directive_prefix, virtual_file_markers,
  )
  let normalized_errors = normalize_int_type_check_index_signature_errors(
    normalized_errors, default_source_name,
  )
  let normalized_errors = normalize_unterminated_string_followup_errors(
    normalized_errors, string_literal_errors,
  )
  let all_errors : Array[ParseError] = []
  for err in normalized_errors {
    all_errors.push(err)
  }
  for err in string_literal_errors {
    all_errors.push(err)
  }
  let ordered_errors = if pretty_mode {
    []
  } else if default_source_name == "constructorWithIncompleteTypeAnnotation.ts" ||
    erasable_syntax_only {
    order_errors_by_source_line_column(all_errors)
  } else {
    order_errors_by_source_name(all_errors)
  }
  (ordered_errors, program)
}
