///|
priv struct Parser {
  tokens : Array[Token]
  mut index : Int
  jsx_mode : Bool
  mut allow_type_colon : Bool
  errors : Array[ParseError]
}

///|
fn Parser::new(tokens : Array[Token], jsx_mode : Bool) -> Parser {
  { tokens, index: 0, jsx_mode, allow_type_colon: true, errors: [] }
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
    raise ParseError::Expected(pos=self.current().span.start, "keyword \{kw}")
  }
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
fn Parser::record_error(self : Parser, err : ParseError) -> Unit {
  self.errors.push(err)
}

///|
fn Parser::record_expected(self : Parser, expected : String) -> Unit {
  self.record_error(
    ParseError::Expected(pos=self.current().span.start, expected),
  )
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
    if !self.check(TokenKind::RParen) {
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
          _ => ignore(self.advance())
        }
      }
    }
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
    TokenKind::Ident(_) | TokenKind::Keyword(_) | TokenKind::Number(_) =>
      self.parse_ident_name()
    _ => raise ParseError::Expected(pos=token.span.start, "module specifier")
  }
}

///|
fn Parser::parse_program(self : Parser) -> Program {
  let start = self.current().span.start
  let stmts : Array[Stmt] = []
  while !self.at_end() {
    stmts.push(self.parse_stmt()) catch {
      err => {
        self.record_error(err)
        while !self.check(TokenKind::Semicolon) &&
              !self.check(TokenKind::RBrace) &&
              !self.at_end() {
          ignore(self.advance())
        }
        ignore(self.eat(TokenKind::Semicolon))
      }
    }
  }
  let end = self.current().span.end
  { stmts, errors: self.errors, span: span_from(start, end) }
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
  match (self.peek_kind(1), self.peek_kind(2)) {
    (Some(TokenKind::LBracket), _) => true
    (Some(TokenKind::String(_)), Some(TokenKind::Colon)) => true
    (Some(TokenKind::Number(_)), Some(TokenKind::Colon)) => true
    _ => false
  }
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
fn Parser::parse_namespace_decl(
  self : Parser,
  start_span : Span,
) -> Stmt raise ParseError {
  let (decl, span) = self.parse_namespace_decl_value(start_span)
  { kind: StmtKind::NamespaceDecl(decl), span }
}

///|
fn Parser::parse_decorator(self : Parser) -> Unit raise ParseError {
  ignore(self.expect(TokenKind::At, "'@'"))
  ignore(self.parse_postfix())
}

///|
fn Parser::eat_declare_modifier(self : Parser) -> Bool {
  match self.current().kind {
    TokenKind::Ident(name) =>
      if name == "declare" {
        ignore(self.advance())
        true
      } else {
        false
      }
    TokenKind::Keyword(kw) =>
      if keyword_to_string(kw) == "declare" {
        ignore(self.advance())
        true
      } else {
        false
      }
    _ => false
  }
}

///|
fn Parser::eat_export_modifiers(self : Parser) -> Unit {
  while self.check_keyword(Keyword::Public) ||
        self.check_keyword(Keyword::Private) ||
        self.check_keyword(Keyword::Protected) ||
        self.check_keyword(Keyword::Static) {
    ignore(self.advance())
  }
}

///|
fn Parser::parse_stmt(self : Parser) -> Stmt raise ParseError {
  while self.check(TokenKind::At) {
    self.parse_decorator()
  }
  if self.is_label_start() {
    let (label, label_span) = self.parse_ident_name()
    ignore(self.expect(TokenKind::Colon, "':'"))
    let stmt = self.parse_stmt()
    let span = label_span.merge(stmt.span)
    return { kind: StmtKind::Labeled({ label, stmt }), span }
  }
  if self.is_namespace_decl_start() {
    let start = self.advance().span
    return self.parse_namespace_decl(start)
  }
  if self.eat_declare_modifier() {
    if self.check_keyword(Keyword::Export) {
      return self.parse_export_decl()
    }
    return self.parse_exported_declaration()
  }
  if self.check_keyword(Keyword::Abstract) &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) {
    ignore(self.advance())
    let start = self.expect_keyword(Keyword::Class).span
    return self.parse_class_decl(start)
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
        self.parse_import_decl()
      }
    TokenKind::Keyword(Keyword::Export) => self.parse_export_decl()
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
      self.parse_class_decl(start)
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
    TokenKind::Keyword(Keyword::Type) => self.parse_type_alias()
    TokenKind::Keyword(Keyword::Interface) => self.parse_interface_decl()
    TokenKind::LBrace => {
      if self.is_object_literal_stmt_start() {
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
      { kind: StmtKind::Empty, span: token.span }
    }
    TokenKind::Semicolon => {
      let token = self.advance()
      { kind: StmtKind::Empty, span: token.span }
    }
    TokenKind::RBrace => {
      let token = self.advance()
      { kind: StmtKind::Empty, span: token.span }
    }
    _ => self.parse_expr_stmt()
  }
}

///|
fn Parser::parse_var_decl_items(
  self : Parser,
  kind : VarKind,
) -> (VarDecl, Span) raise ParseError {
  let decls : Array[VarDeclarator] = []
  let mut last_span = self.current().span
  while true {
    let pattern = self.parse_binding_pattern()
    let mut type_ann : TypeNode? = None
    ignore(self.eat(TokenKind::Bang))
    if self.eat(TokenKind::Colon) {
      type_ann = Some(self.parse_type())
    }
    let mut init : Expr? = None
    if self.eat(TokenKind::Eq) {
      init = Some(self.parse_expression_no_comma())
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
    let mut end_span = start_span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    } else if self.at_end() {
      end_span = self.current().span
    }
    let span = start_span.merge(end_span)
    return { kind: StmtKind::VarDecl({ kind, decls: [] }), span }
  }
  let (decl, last_span) = self.parse_var_decl_items(kind)
  let mut last_span = last_span
  if self.eat(TokenKind::Semicolon) {
    last_span = self.previous().span
  }
  let span = start_span.merge(last_span)
  { kind: StmtKind::VarDecl(decl), span }
}

///|
fn Parser::parse_function_decl(
  self : Parser,
  start_span : Span,
) -> Stmt raise ParseError {
  let (decl, span) = self.parse_function_decl_value(start_span, false)
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
  let mut constraint : TypeNode? = None
  if self.eat_keyword(Keyword::Extends) {
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
  params
}

///|
fn Parser::parse_function_decl_value(
  self : Parser,
  start_span : Span,
  allow_anonymous : Bool,
) -> (FunctionDecl, Span) raise ParseError {
  ignore(self.eat(TokenKind::Star))
  let mut name : String? = None
  if self.current().kind is TokenKind::Ident(_) ||
    self.current().kind is TokenKind::Keyword(_) {
    let (found, _) = self.parse_ident_name()
    name = Some(found)
  } else if !allow_anonymous {
    raise ParseError::Expected(pos=self.current().span.start, "identifier")
  }
  let type_params = self.parse_type_params()
  let params = if self.check(TokenKind::LParen) {
    self.parse_params(false)
  } else if self.check(TokenKind::LBrace) {
    []
  } else {
    self.parse_params(false)
  }
  let mut return_type : TypeNode? = None
  if self.eat(TokenKind::Colon) {
    return_type = Some(self.parse_type())
  }
  if self.check(TokenKind::Semicolon) || self.check(TokenKind::Comma) {
    let end_tok = self.advance().span
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
    let body : Block = { stmts: [], span: end_span }
    let span = start_span.merge(end_span)
    return ({ name, type_params, params, return_type, body }, span)
  }
  let body = self.parse_block()
  let span = start_span.merge(body.span)
  ({ name, type_params, params, return_type, body }, span)
}

///|
fn Parser::parse_import_decl(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Import)
  let mut is_type_only = false
  if self.eat_keyword(Keyword::Type) {
    is_type_only = true
  }
  let mut default_name : String? = None
  let mut ns_name : String? = None
  let named : Array[ImportSpec] = []
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
  if (
      self.current().kind is TokenKind::Ident(_) ||
      self.current().kind is TokenKind::Keyword(_)
    ) &&
    self.peek_kind(1) == Some(TokenKind::Eq) {
    let (name, _) = self.parse_ident_name()
    ignore(self.expect(TokenKind::Eq, "'='"))
    let value = self.parse_expression()
    end_span = value.span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    return { kind: StmtKind::ImportAssign({ name, value, span }), span }
  }
  if self.current().kind is TokenKind::Ident(_) ||
    self.current().kind is TokenKind::Keyword(_) {
    let (name, name_span) = self.parse_ident_name()
    default_name = Some(name)
    end_span = name_span
    if self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
  } else if self.eat(TokenKind::Comma) {
    end_span = self.previous().span
  }
  if self.eat(TokenKind::Star) {
    ignore(self.expect_keyword(Keyword::As))
    let (ns, ns_span) = self.parse_ident_name()
    ns_name = Some(ns)
    end_span = ns_span
  } else if self.eat(TokenKind::LBrace) {
    if !self.check(TokenKind::RBrace) {
      while true {
        named.push(self.parse_import_spec())
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RBrace) {
            break
          }
          continue
        }
        break
      }
    }
    let end = self.expect(TokenKind::RBrace, "'}'")
    end_span = end.span
  }
  if self.eat(TokenKind::Comma) {
    end_span = self.previous().span
  }
  if !(self.eat_keyword(Keyword::From) ||
    self.eat_ident_name("from") ||
    self.eat_ident_name("From")) {
    ignore(self.expect_keyword(Keyword::From))
  }
  let (source, source_span) = self.expect_module_specifier()
  end_span = source_span
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
fn Parser::parse_import_spec(self : Parser) -> ImportSpec raise ParseError {
  let mut is_type_only = false
  if self.eat_keyword(Keyword::Type) {
    is_type_only = true
  }
  let (name, name_span) = if self.check(TokenKind::Star) {
    let token = self.advance()
    ("*", token.span)
  } else {
    self.expect_member_name()
  }
  let mut as_name : String? = None
  let mut end_span = name_span
  if self.eat_keyword(Keyword::As) {
    let (alias_name, alias_span) = self.expect_member_name()
    as_name = Some(alias_name)
    end_span = alias_span
  }
  { is_type_only, name, as_name, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_export_decl(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Export)
  if self.eat_keyword(Keyword::Default) {
    if self.check_keyword(Keyword::Abstract) &&
      self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) {
      ignore(self.advance())
      let class_start = self.expect_keyword(Keyword::Class).span
      let (decl, decl_span) = self.parse_class_decl_value(class_start, true)
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
      let (decl, decl_span) = self.parse_function_decl_value(func_start, true)
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
      let (decl, decl_span) = self.parse_class_decl_value(class_start, true)
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
  ignore(self.eat_declare_modifier())
  if self.check_keyword(Keyword::Export) &&
    self.peek_kind(1) == Some(TokenKind::Eq) {
    ignore(self.advance())
    ignore(self.expect(TokenKind::Eq, "'='"))
    let expr = self.parse_expression()
    let mut end_span = expr.span
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    return { kind: StmtKind::ExportDecl(ExportDecl::Assign(expr)), span }
  }
  if self.eat(TokenKind::Eq) {
    let expr = self.parse_expression()
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
    let star_span = self.previous().span
    let mut as_name : String? = None
    let mut end_span = star_span
    if self.eat_keyword(Keyword::As) {
      let (alias_name, alias_span) = self.expect_ident()
      as_name = Some(alias_name)
      end_span = alias_span
    }
    let mut from_source : String? = None
    if self.eat_keyword(Keyword::From) {
      let (source, source_span) = self.expect_module_specifier()
      from_source = Some(source)
      end_span = source_span
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
    let specs : Array[ExportSpec] = []
    if !self.check(TokenKind::RBrace) {
      while true {
        specs.push(self.parse_export_spec())
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
    let mut end_span = self.current().span
    if self.eat(TokenKind::RBrace) {
      end_span = self.previous().span
    } else {
      while !self.at_end() &&
            !self.check_keyword(Keyword::From) &&
            !self.check(TokenKind::Semicolon) {
        ignore(self.advance())
      }
      end_span = self.current().span
    }
    if self.eat_keyword(Keyword::From) {
      let (source, source_span) = self.expect_module_specifier()
      from_source = Some(source)
      end_span = source_span
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    let span = start.span.merge(end_span)
    let named = { is_type_only: named_type_only, specs, from: from_source }
    return { kind: StmtKind::ExportDecl(ExportDecl::Named(named)), span }
  }
  let decl = self.parse_exported_declaration()
  let span = start.span.merge(decl.span)
  { kind: StmtKind::ExportDecl(ExportDecl::Declaration(decl)), span }
}

///|
fn Parser::parse_export_spec(self : Parser) -> ExportSpec raise ParseError {
  let mut is_type_only = false
  if self.eat_keyword(Keyword::Type) {
    is_type_only = true
  }
  let (name, name_span) = self.parse_ident_name()
  let mut as_name : String? = None
  let mut end_span = name_span
  if self.eat_keyword(Keyword::As) {
    let (alias_name, alias_span) = self.expect_member_name()
    as_name = Some(alias_name)
    end_span = alias_span
  }
  { is_type_only, name, as_name, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_exported_declaration(self : Parser) -> Stmt raise ParseError {
  ignore(self.eat_declare_modifier())
  self.eat_export_modifiers()
  if self.check_ident_name("async") &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Function)) {
    let async_start = self.advance().span
    ignore(self.expect_keyword(Keyword::Function))
    let (decl, span) = self.parse_function_decl_value(async_start, false)
    return { kind: StmtKind::FunctionDecl(decl), span }
  }
  if self.check_ident_name("global") &&
    self.peek_kind(1) == Some(TokenKind::LBrace) {
    let start = self.advance().span
    let body = self.parse_block()
    let span = start.merge(body.span)
    return {
      kind: StmtKind::NamespaceDecl({ name: "global", body, span }),
      span,
    }
  }
  if self.is_namespace_decl_start() {
    let start = self.advance().span
    return self.parse_namespace_decl(start)
  }
  if self.check_keyword(Keyword::Abstract) &&
    self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Class)) {
    ignore(self.advance())
    let start = self.expect_keyword(Keyword::Class).span
    return self.parse_class_decl(start)
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
      self.parse_class_decl(start)
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
  let (name, _) = if self.current().kind is TokenKind::String(_) {
    self.expect_string()
  } else {
    self.parse_qualified_name()
  }
  if self.eat(TokenKind::Semicolon) {
    let end_span = self.previous().span
    let body : Block = { stmts: [], span: end_span }
    let span = start_span.merge(end_span)
    return ({ name, body, span }, span)
  }
  let body = self.parse_block()
  let span = start_span.merge(body.span)
  ({ name, body, span }, span)
}

///|
fn Parser::parse_class_decl(
  self : Parser,
  start_span : Span,
) -> Stmt raise ParseError {
  let (decl, span) = self.parse_class_decl_value(start_span, false)
  { kind: StmtKind::ClassDecl(decl), span }
}

///|
fn Parser::parse_class_decl_value(
  self : Parser,
  start_span : Span,
  allow_anonymous : Bool,
) -> (ClassDecl, Span) raise ParseError {
  let mut name : String? = None
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
  let type_params = self.parse_type_params()
  let mut extends : Expr? = None
  let implements : Array[TypeNode] = []
  if self.eat_keyword(Keyword::Extends) {
    let mut base = self.parse_member_base()
    ignore(self.eat_type_args())
    base = self.parse_postfix_with_base(base)
    extends = Some(base)
  }
  if self.eat_keyword(Keyword::Implements) {
    while true {
      implements.push(self.parse_type())
      if self.eat(TokenKind::Comma) {
        continue
      }
      break
    }
  }
  while self.eat(TokenKind::Comma) {

  }
  ignore(self.expect(TokenKind::LBrace, "'{' "))
  let members : Array[ClassMember] = []
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    if self.eat(TokenKind::Semicolon) {
      continue
    }
    if self.eat(TokenKind::Comma) {
      continue
    }
    if self.check_keyword(Keyword::Static) &&
      self.peek_kind(1) == Some(TokenKind::LBrace) {
      ignore(self.advance())
      ignore(self.parse_block())
      continue
    }
    if self.check_keyword(Keyword::Try) {
      ignore(self.parse_try_stmt())
      continue
    }
    members.push(self.parse_class_member()) catch {
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
  let span = start_span.merge(end.span)
  ({ name, type_params, extends, implements, members, span }, span)
}

///|
fn Parser::parse_class_member(self : Parser) -> ClassMember raise ParseError {
  let start_span = self.current().span
  while self.check(TokenKind::At) {
    self.parse_decorator()
  }
  let mut is_static = false
  let mut is_readonly = false
  let mut access : AccessModifier? = None
  let mut accessor : String? = None
  while true {
    match self.current().kind {
      TokenKind::Keyword(Keyword::Static) => {
        ignore(self.advance())
        is_static = true
        continue
      }
      TokenKind::Ident("declare") => {
        ignore(self.advance())
        continue
      }
      TokenKind::Keyword(Keyword::Readonly) => {
        ignore(self.advance())
        is_readonly = true
        continue
      }
      TokenKind::Keyword(Keyword::Abstract) => {
        ignore(self.advance())
        continue
      }
      TokenKind::Keyword(Keyword::Public) => {
        ignore(self.advance())
        access = Some(AccessModifier::Public)
        continue
      }
      TokenKind::Keyword(Keyword::Private) => {
        ignore(self.advance())
        access = Some(AccessModifier::Private)
        continue
      }
      TokenKind::Keyword(Keyword::Protected) => {
        ignore(self.advance())
        access = Some(AccessModifier::Protected)
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
            continue
          }
          _ => ()
        }
      _ => ()
    }
    break
  }
  ignore(self.eat(TokenKind::Star))
  let is_name_start = self.check(TokenKind::LBracket) ||
    (match self.current().kind {
      TokenKind::Ident(_)
      | TokenKind::Keyword(_)
      | TokenKind::String(_)
      | TokenKind::Number(_) => true
      _ => false
    })
  if !is_name_start {
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
  let (name, name_span) = if self.check(TokenKind::LBracket) {
    self.parse_bracket_member_name()
  } else {
    let token = self.current()
    let (found, span) = self.expect_member_name()
    match token.kind {
      TokenKind::Ident(_) | TokenKind::Keyword(_) => is_plain_name = true
      _ => ()
    }
    (found, span)
  }
  let mut name_end_span = name_span
  if self.eat(TokenKind::Question) {
    name_end_span = self.previous().span
  }
  if self.eat(TokenKind::Bang) {
    name_end_span = self.previous().span
  }
  if accessor is None &&
    is_plain_name &&
    name == "constructor" &&
    self.check(TokenKind::LParen) {
    let params = self.parse_params(true)
    let body : Block = if self.check(TokenKind::LBrace) {
      self.parse_block()
    } else {
      let end_span = if self.check(TokenKind::RBrace) {
        self.current().span
      } else if self.check(TokenKind::Semicolon) || self.check(TokenKind::Comma) {
        self.advance().span
      } else {
        self.current().span
      }
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
  if accessor == Some("get") {
    ignore(self.parse_params(false))
    let mut return_type : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      return_type = Some(self.parse_type())
    }
    let body : Block = if self.check(TokenKind::LBrace) {
      self.parse_block()
    } else {
      let end_span = if self.check(TokenKind::RBrace) {
        self.current().span
      } else if self.check(TokenKind::Semicolon) || self.check(TokenKind::Comma) {
        self.advance().span
      } else {
        self.current().span
      }
      { stmts: [], span: end_span }
    }
    let span = start_span.merge(body.span)
    return {
      kind: ClassMemberKind::Getter(name, return_type, body),
      is_static,
      access,
      is_readonly,
      span,
    }
  }
  if accessor == Some("set") {
    let params = self.parse_params(false)
    if self.eat(TokenKind::Colon) {
      ignore(self.parse_type())
    }
    let body : Block = if self.check(TokenKind::LBrace) {
      self.parse_block()
    } else {
      let end_span = if self.check(TokenKind::RBrace) {
        self.current().span
      } else if self.check(TokenKind::Semicolon) || self.check(TokenKind::Comma) {
        self.advance().span
      } else {
        self.current().span
      }
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
    let params = self.parse_params(false)
    let mut return_type : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      return_type = Some(self.parse_type())
    }
    let body : Block = if self.check(TokenKind::LBrace) {
      self.parse_block()
    } else {
      let end_span = if self.check(TokenKind::RBrace) {
        self.current().span
      } else if self.check(TokenKind::Semicolon) || self.check(TokenKind::Comma) {
        self.advance().span
      } else {
        self.current().span
      }
      { stmts: [], span: end_span }
    }
    let span = start_span.merge(body.span)
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
  let mut init : Expr? = None
  if self.eat(TokenKind::Eq) {
    init = Some(self.parse_expression())
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
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
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
      { kind: BindingPatternKind::Ident(name), span: token.span }
    }
    TokenKind::Keyword(kw) => {
      ignore(self.advance())
      {
        kind: BindingPatternKind::Ident(keyword_to_string(kw)),
        span: token.span,
      }
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
    let expr = self.parse_expression_no_comma()
    default_value = Some(expr)
    end_span = expr.span
  }
  { pattern, default_value, span: pattern.span.merge(end_span) }
}

///|
fn Parser::parse_object_pattern(
  self : Parser,
) -> BindingPattern raise ParseError {
  let start = self.expect(TokenKind::LBrace, "'{' ")
  let props : Array[ObjectPatternProp] = []
  if !self.check(TokenKind::RBrace) {
    while true {
      if self.eat(TokenKind::Ellipsis) {
        let rest_pattern = self.parse_binding_pattern()
        props.push(ObjectPatternProp::Rest(rest_pattern))
      } else {
        let (key, key_span) = if self.check(TokenKind::LBracket) {
          self.parse_bracket_member_name()
        } else {
          self.expect_member_name()
        }
        let mut shorthand = true
        let binding = if self.eat(TokenKind::Colon) {
          shorthand = false
          self.parse_binding_element()
        } else {
          let pattern : BindingPattern = {
            kind: BindingPatternKind::Ident(key),
            span: key_span,
          }
          let mut default_value : Expr? = None
          let mut end_span = key_span
          if self.eat(TokenKind::Eq) {
            let expr = self.parse_expression_no_comma()
            default_value = Some(expr)
            end_span = expr.span
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
            !self.check(TokenKind::RBrace) &&
            !self.at_end() {
        ignore(self.advance())
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
        elems.push(ArrayPatternElem::Rest(rest_pattern))
        if self.eat(TokenKind::Comma) {
          if self.check(TokenKind::RBracket) {
            break
          }
        }
        break
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
  if !self.check(TokenKind::RParen) {
    while true {
      let param = self.parse_param(allow_param_property_modifiers)
      if param.is_rest &&
        self.check(TokenKind::Comma) &&
        self.peek_kind(1) != Some(TokenKind::RParen) {
        self.record_error(
          ParseError::UnexpectedToken(
            pos=self.current().span.start,
            "rest parameter must be last",
          ),
        )
      }
      params.push(param)
      if self.eat(TokenKind::Comma) {
        if self.check(TokenKind::RParen) {
          break
        }
        continue
      }
      break
    }
  }
  if self.check(TokenKind::RParen) {
    ignore(self.expect(TokenKind::RParen, "')'"))
  } else if self.check(TokenKind::RBrace) || self.at_end() {
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
  while self.check(TokenKind::At) {
    self.parse_decorator()
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
      ignore(self.advance())
      continue
    }
    match self.current().kind {
      TokenKind::Keyword(Keyword::Public)
      | TokenKind::Keyword(Keyword::Private)
      | TokenKind::Keyword(Keyword::Protected)
      | TokenKind::Keyword(Keyword::Readonly) =>
        if next_is_param {
          if !allow_param_property_modifiers {
            self.record_error(
              ParseError::UnexpectedToken(
                pos=self.current().span.start,
                "parameter modifiers are only allowed in constructors",
              ),
            )
          }
          ignore(self.advance())
          continue
        } else {
          break
        }
      TokenKind::Keyword(Keyword::Export) =>
        if next_is_param {
          self.record_error(
            ParseError::UnexpectedToken(
              pos=self.current().span.start,
              "export modifier is not allowed on parameters",
            ),
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
  let pattern : BindingPattern = if is_rest &&
    (self.check(TokenKind::RParen) || self.check(TokenKind::Comma)) {
    self.record_expected("identifier")
    { kind: BindingPatternKind::Ident(""), span: self.current().span }
  } else {
    self.parse_binding_pattern()
  }
  let mut optional = false
  if self.eat(TokenKind::Question) {
    optional = true
  }
  let mut type_ann : TypeNode? = None
  if self.eat(TokenKind::Colon) {
    type_ann = Some(self.parse_type())
  }
  let mut default_value : Expr? = None
  if self.eat(TokenKind::Eq) {
    default_value = Some(self.parse_expression_no_comma())
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
fn Parser::parse_block(self : Parser) -> Block raise ParseError {
  let start = self.expect(TokenKind::LBrace, "'{' ")
  let stmts : Array[Stmt] = []
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    stmts.push(self.parse_stmt())
  }
  let end_span = if self.check(TokenKind::RBrace) {
    self.advance().span
  } else if self.at_end() {
    self.current().span
  } else {
    self.expect(TokenKind::RBrace, "'}'").span
  }
  { stmts, span: start.span.merge(end_span) }
}

///|
fn Parser::parse_return_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Return)
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
  let condition = self.parse_expression()
  ignore(self.expect(TokenKind::RParen, "')'"))
  let then_branch = self.parse_stmt()
  let mut else_branch : Stmt? = None
  let mut end_span = then_branch.span
  if self.eat_keyword(Keyword::Else) {
    let else_stmt = self.parse_stmt()
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
  ignore(self.expect(TokenKind::LParen, "'('"))
  let condition = self.parse_expression()
  ignore(self.expect(TokenKind::RParen, "')'"))
  let body = self.parse_stmt()
  { kind: StmtKind::While(condition, body), span: start.span.merge(body.span) }
}

///|
fn Parser::parse_do_while_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Do)
  let body = self.parse_stmt()
  ignore(self.expect_keyword(Keyword::While))
  ignore(self.expect(TokenKind::LParen, "'('"))
  let condition = self.parse_expression()
  let end_paren = self.expect(TokenKind::RParen, "')'")
  let mut end_span = end_paren.span
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
  ignore(self.eat_keyword(Keyword::Await) || self.eat_ident_name("await"))
  ignore(self.expect(TokenKind::LParen, "'('"))
  if self.check(TokenKind::RParen) {
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
    let (decl, _) = self.parse_var_decl_items(kind)
    if self.eat_ident_name("in") {
      for_left = Some(ForInLeft::Var(decl))
    } else if self.eat_ident_name("of") {
      for_left = Some(ForInLeft::Var(decl))
      is_for_of = true
    } else {
      init = Some(ForInit::Var(decl))
      ignore(self.expect(TokenKind::Semicolon, "';'"))
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
      ignore(self.expect(TokenKind::RParen, "')'"))
      let body = self.parse_stmt()
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
    condition = Some(self.parse_expression())
  }
  ignore(self.expect(TokenKind::Semicolon, "';'"))
  let mut update : Expr? = None
  if !self.check(TokenKind::RParen) {
    update = Some(self.parse_expression())
  }
  ignore(self.expect(TokenKind::RParen, "')'"))
  let body = self.parse_stmt()
  {
    kind: StmtKind::For({ init, condition, update, body }),
    span: start.span.merge(body.span),
  }
}

///|
fn Parser::parse_switch_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Switch)
  ignore(self.expect(TokenKind::LParen, "'('"))
  let discriminant = self.parse_expression()
  ignore(self.expect(TokenKind::RParen, "')'"))
  ignore(self.expect(TokenKind::LBrace, "'{' "))
  let cases : Array[SwitchCase] = []
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    if self.eat_keyword(Keyword::Case) {
      let case_expr = self.parse_expression()
      ignore(self.eat(TokenKind::Colon))
      let consequent : Array[Stmt] = []
      while !self.check(TokenKind::RBrace) &&
            !self.check_keyword(Keyword::Case) &&
            !self.check_keyword(Keyword::Default) &&
            !self.at_end() {
        consequent.push(self.parse_stmt())
      }
      cases.push({ case_expr: Some(case_expr), consequent })
      continue
    }
    if self.eat_keyword(Keyword::Default) {
      ignore(self.eat(TokenKind::Colon))
      let consequent : Array[Stmt] = []
      while !self.check(TokenKind::RBrace) &&
            !self.check_keyword(Keyword::Case) &&
            !self.check_keyword(Keyword::Default) &&
            !self.at_end() {
        consequent.push(self.parse_stmt())
      }
      cases.push({ case_expr: None, consequent })
      continue
    }
    raise ParseError::Expected(pos=self.current().span.start, "case or default")
  }
  let end = self.expect(TokenKind::RBrace, "'}'")
  let span = start.span.merge(end.span)
  { kind: StmtKind::Switch({ discriminant, cases }), span }
}

///|
fn Parser::parse_break_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Break)
  let mut label : String? = None
  let mut end_span = start.span
  if self.current().kind is TokenKind::Ident(_) {
    let (name, name_span) = self.expect_ident()
    label = Some(name)
    end_span = name_span
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
    label = Some(name)
    end_span = name_span
  }
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  { kind: StmtKind::Continue(label), span: start.span.merge(end_span) }
}

///|
fn Parser::parse_throw_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Throw)
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
  { name, type_ann, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_try_stmt(self : Parser) -> Stmt raise ParseError {
  let start = self.expect_keyword(Keyword::Try)
  let block = self.parse_block()
  let mut handler : CatchClause? = None
  let mut finalizer : Block? = None
  let mut end_span = block.span
  if self.eat_keyword(Keyword::Catch) {
    let mut param : CatchParam? = None
    if self.eat(TokenKind::LParen) {
      if !self.check(TokenKind::RParen) {
        param = Some(self.parse_catch_param())
      }
      ignore(self.expect(TokenKind::RParen, "')'"))
    }
    let body = self.parse_block()
    end_span = body.span
    handler = Some({ param, body })
  }
  if self.eat_keyword(Keyword::Finally) {
    let final_block = self.parse_block()
    end_span = final_block.span
    finalizer = Some(final_block)
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
  let (name, _) = self.parse_ident_name()
  let type_params = self.parse_type_params()
  let any_node : TypeNode = { kind: TypeKind::Ident("any"), span: start.span }
  let value = if self.eat(TokenKind::Eq) {
    if self.check_keyword(Keyword::Import) &&
      self.peek_kind(1) != Some(TokenKind::LParen) {
      any_node
    } else {
      self.parse_type()
    }
  } else if self.check_keyword(Keyword::Import) &&
    self.peek_kind(1) != Some(TokenKind::LParen) {
    any_node
  } else {
    match self.current().kind {
      TokenKind::LBrace
      | TokenKind::LParen
      | TokenKind::LBracket
      | TokenKind::TemplateStart
      | TokenKind::Ident(_)
      | TokenKind::Keyword(_)
      | TokenKind::Number(_) => self.parse_type()
      _ => any_node
    }
  }
  let mut end_span = value.span
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  let span = start.span.merge(end_span)
  { kind: StmtKind::TypeAliasDecl({ name, type_params, value, span }), span }
}

///|
fn Parser::parse_enum_decl(
  self : Parser,
  start_span : Span,
  is_const : Bool,
) -> Stmt raise ParseError {
  let (name, _) = self.parse_ident_name()
  ignore(self.expect(TokenKind::LBrace, "'{' "))
  let members : Array[EnumMember] = []
  while !self.check(TokenKind::RBrace) && !self.at_end() {
    let (member_name, member_span) = if self.check(TokenKind::LBracket) {
      self.parse_bracket_member_name()
    } else {
      self.expect_member_name()
    }
    let mut init : Expr? = None
    if self.eat(TokenKind::Eq) {
      init = Some(self.parse_expression_no_comma())
    }
    let mut end_span = member_span
    match init {
      Some(expr) => end_span = expr.span
      None => ()
    }
    members.push({ name: member_name, init, span: member_span.merge(end_span) })
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
  if self.current().kind is TokenKind::Ident(_) ||
    self.current().kind is TokenKind::Keyword(_) ||
    self.current().kind is TokenKind::Number(_) {
    let (found, _) = self.parse_qualified_name()
    name = found
  } else {
    while !self.check(TokenKind::LBrace) && !self.at_end() {
      ignore(self.advance())
    }
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
    while true {
      ignore(self.parse_type())
      if self.eat(TokenKind::Comma) {
        continue
      }
      break
    }
  }
  ignore(self.expect(TokenKind::LBrace, "'{' "))
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
  if self.check_keyword(Keyword::New) {
    let start = self.expect_keyword(Keyword::New)
    ignore(self.parse_type_params())
    let params = self.parse_params(false)
    let mut return_type : TypeNode? = None
    if self.eat(TokenKind::Colon) {
      return_type = Some(self.parse_type())
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
        return_type = Some(self.parse_type())
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
  let (name, name_span) = if self.check(TokenKind::LBracket) {
    self.parse_bracket_member_name()
  } else {
    self.expect_member_name()
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
      return_type = Some(self.parse_type())
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
      let body = self.parse_block()
      end_span = body.span
    }
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return { name, optional, type_ann, span: name_span.merge(end_span) }
  }
  let type_ann = if self.eat(TokenKind::Colon) {
    self.parse_type()
  } else {
    let span = if optional { self.previous().span } else { name_span }
    { kind: TypeKind::Ident("any"), span }
  }
  let mut end_span = type_ann.span
  if self.eat(TokenKind::Eq) {
    let expr = self.parse_expression_no_comma()
    end_span = expr.span
  }
  if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
    end_span = self.previous().span
  }
  { name, optional, type_ann, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_type_member(self : Parser) -> TypeMember raise ParseError {
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
        self.parse_type()
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
      self.parse_type()
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
      self.parse_type()
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
      name: "new",
      optional: false,
      type_ann,
      span: start.span.merge(end_span),
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
  let (name, name_span) = if self.check(TokenKind::LBracket) {
    self.parse_bracket_member_name()
  } else {
    self.expect_member_name()
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
      return_type = Some(self.parse_type())
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
      let body = self.parse_block()
      end_span = body.span
    }
    if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
      end_span = self.previous().span
    }
    return { name, optional, type_ann, span: name_span.merge(end_span) }
  }
  let type_ann = if self.eat(TokenKind::Colon) {
    self.parse_type()
  } else {
    let span = if optional { self.previous().span } else { name_span }
    { kind: TypeKind::Ident("any"), span }
  }
  let mut end_span = type_ann.span
  if self.eat(TokenKind::Semicolon) || self.eat(TokenKind::Comma) {
    end_span = self.previous().span
  }
  { name, optional, type_ann, span: name_span.merge(end_span) }
}

///|
fn Parser::parse_expr_stmt(self : Parser) -> Stmt raise ParseError {
  let start_index = self.index
  let expr = self.parse_expression()
  if self.index == start_index && !self.at_end() {
    ignore(self.advance())
  }
  let expr_span = expr.span
  let mut end_span = expr_span
  if self.eat(TokenKind::Colon) {
    let type_ann = self.parse_type()
    end_span = type_ann.span
  }
  if self.eat(TokenKind::Semicolon) {
    end_span = self.previous().span
  }
  { kind: StmtKind::ExprStmt(expr), span: expr_span.merge(end_span) }
}

///|
fn Parser::parse_expression_no_comma(self : Parser) -> Expr raise ParseError {
  self.parse_assignment()
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
    err => {
      self.record_error(err)
      self.recover_expression()
    }
  }
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
  let mut end_span = token.span
  ignore(self.advance())
  end_span = self.previous().span
  while !self.at_end() &&
        !self.check(TokenKind::Semicolon) &&
        !self.check(TokenKind::Comma) &&
        !self.check(TokenKind::RParen) &&
        !self.check(TokenKind::RBracket) &&
        !self.check(TokenKind::RBrace) {
    end_span = self.advance().span
  }
  { kind: ExprKind::Ident("undefined"), span: token.span.merge(end_span) }
}

///|
fn Parser::parse_assignment(self : Parser) -> Expr raise ParseError {
  let expr = self.parse_conditional()
  match self.eat_assignment_op() {
    Some(op) => {
      let value = self.parse_assignment()
      let span = expr.span.merge(value.span)
      { kind: ExprKind::Assign({ op, target: expr, value }), span }
    }
    None => expr
  }
}

///|
fn Parser::eat_assignment_op(self : Parser) -> AssignOp? {
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
  if self.eat(TokenKind::Question) {
    let prev_allow = self.allow_type_colon
    self.allow_type_colon = false
    let consequent = self.parse_expression_no_comma()
    ignore(self.expect(TokenKind::Colon, "':'"))
    let alternate = self.parse_expression_no_comma()
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
  while self.eat(TokenKind::Nullish) {
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
  while self.eat(TokenKind::OrOr) {
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
  while self.eat(TokenKind::AndAnd) {
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
    if self.eat(TokenKind::StarStar) {
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
  if self.check(TokenKind::Lt) {
    let start = self.current().span
    let saved = self.index
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
      let type_ann = self.parse_type()
      ignore(self.expect(TokenKind::Gt, "'>'"))
      let expr = self.parse_unary()
      return {
        kind: ExprKind::TypeAssert({ expr, type_ann }),
        span: assert_start.merge(expr.span),
      }
    } catch {
      _ => {
        self.index = saved_type_assert
        if self.peek_kind(1) is Some(next_kind) {
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
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Typeof, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check_keyword(Keyword::Delete) || self.check_ident_name("delete") {
    let start = self.advance().span
    let expr = self.parse_unary()
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Delete, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check_keyword(Keyword::Void) || self.check_ident_name("void") {
    let start = self.advance().span
    let expr = self.parse_unary()
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Void, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check_keyword(Keyword::Await) || self.check_ident_name("await") {
    let start = self.advance().span
    let expr = self.parse_unary()
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Await, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check_keyword(Keyword::Yield) || self.check_ident_name("yield") {
    let start = self.advance().span
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
    return {
      kind: ExprKind::Update({ op: UpdateOp::Increment, prefix: true, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::MinusMinus) {
    let start = self.advance().span
    let expr = self.parse_unary()
    return {
      kind: ExprKind::Update({ op: UpdateOp::Decrement, prefix: true, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::Bang) {
    let start = self.advance().span
    let expr = self.parse_unary()
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Not, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::Plus) {
    let start = self.advance().span
    let expr = self.parse_unary()
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Plus, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::Minus) {
    let start = self.advance().span
    let expr = self.parse_unary()
    return {
      kind: ExprKind::Unary({ op: UnaryOp::Minus, expr }),
      span: start.merge(expr.span),
    }
  }
  if self.check(TokenKind::Tilde) {
    let start = self.advance().span
    let expr = self.parse_unary()
    return {
      kind: ExprKind::Unary({ op: UnaryOp::BitNot, expr }),
      span: start.merge(expr.span),
    }
  }
  self.parse_postfix()
}

///|
fn Parser::skip_jsx_tag_name(self : Parser) -> Unit {
  match self.current().kind {
    TokenKind::Ident(_) | TokenKind::Keyword(_) => ignore(self.advance())
    _ => ()
  }
  while self.check(TokenKind::Dot) || self.check(TokenKind::Colon) {
    ignore(self.advance())
    match self.current().kind {
      TokenKind::Ident(_) | TokenKind::Keyword(_) => ignore(self.advance())
      _ => break
    }
  }
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
fn Parser::parse_jsx(self : Parser) -> Expr raise ParseError {
  let start = self.expect(TokenKind::Lt, "'<'")
  let mut end_span = start.span
  let mut depth = 0
  if self.check(TokenKind::Gt) {
    end_span = self.advance().span
    depth = 1
  } else {
    self.skip_jsx_tag_name()
    while !self.check(TokenKind::Gt) &&
          !self.check(TokenKind::Slash) &&
          !self.at_end() {
      if self.check(TokenKind::LBrace) {
        end_span = self.skip_jsx_braced_expr()
        continue
      }
      end_span = self.advance().span
    }
    if self.eat(TokenKind::Slash) {
      let gt_span = if self.check(TokenKind::Gt) {
        self.advance().span
      } else {
        let span = self.current().span
        if !self.at_end() {
          ignore(self.advance())
        }
        span
      }
      end_span = gt_span
      depth = 0
    } else {
      let gt_span = if self.check(TokenKind::Gt) {
        self.advance().span
      } else {
        let span = self.current().span
        if !self.at_end() {
          ignore(self.advance())
        }
        span
      }
      end_span = gt_span
      depth = 1
    }
  }
  while depth > 0 && !self.at_end() {
    if self.eat(TokenKind::Lt) {
      if self.eat(TokenKind::Slash) {
        if self.check(TokenKind::Gt) {
          end_span = self.advance().span
          depth -= 1
          continue
        }
        self.skip_jsx_tag_name()
        while !self.check(TokenKind::Gt) && !self.at_end() {
          end_span = self.advance().span
        }
        let gt_span = if self.check(TokenKind::Gt) {
          self.advance().span
        } else {
          let span = self.current().span
          if !self.at_end() {
            ignore(self.advance())
          }
          span
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
      self.skip_jsx_tag_name()
      while !self.check(TokenKind::Gt) &&
            !self.check(TokenKind::Slash) &&
            !self.at_end() {
        if self.check(TokenKind::LBrace) {
          end_span = self.skip_jsx_braced_expr()
          continue
        }
        end_span = self.advance().span
      }
      if self.eat(TokenKind::Slash) {
        let gt_span = if self.check(TokenKind::Gt) {
          self.advance().span
        } else {
          let span = self.current().span
          if !self.at_end() {
            ignore(self.advance())
          }
          span
        }
        end_span = gt_span
      } else {
        let gt_span = if self.check(TokenKind::Gt) {
          self.advance().span
        } else {
          let span = self.current().span
          if !self.at_end() {
            ignore(self.advance())
          }
          span
        }
        end_span = gt_span
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
  { kind: ExprKind::String("<jsx>"), span: start.span.merge(end_span) }
}

///|
fn Parser::parse_new_expr(self : Parser) -> Expr raise ParseError {
  let start = self.expect_keyword(Keyword::New)
  let callee : Expr = if self.check(TokenKind::Lt) {
    let assert_start = self.advance().span
    let type_ann = self.parse_type()
    ignore(self.expect(TokenKind::Gt, "'>'"))
    let inner = self.parse_member_base()
    let span = assert_start.merge(inner.span)
    { kind: ExprKind::TypeAssert({ expr: inner, type_ann }), span }
  } else if self.check(TokenKind::LParen) {
    { kind: ExprKind::Ident(""), span: start.span }
  } else {
    self.parse_member_base()
  }
  let args : Array[Expr] = []
  let mut end_span = callee.span
  ignore(self.eat_type_args_before_call())
  if self.eat(TokenKind::LParen) {
    if !self.check(TokenKind::RParen) {
      while true {
        if self.eat(TokenKind::Ellipsis) {
          args.push(self.parse_expression_no_comma())
        } else {
          args.push(self.parse_expression_no_comma())
        }
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
fn Parser::parse_postfix_with_base(
  self : Parser,
  base : Expr,
) -> Expr raise ParseError {
  let mut expr = base
  while true {
    if self.eat_type_args_before_call() {
      continue
    }
    if self.check(TokenKind::Lt) {
      let saved = self.index
      try {
        if self.eat_type_args() {
          continue
        }
      } catch {
        _ => self.index = saved
      }
    }
    if self.eat(TokenKind::LParen) {
      let args : Array[Expr] = []
      if self.check(TokenKind::RBrace) ||
        self.check(TokenKind::Semicolon) ||
        self.at_end() {
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
          if self.eat(TokenKind::Ellipsis) {
            args.push(self.parse_expression_no_comma())
          } else {
            args.push(self.parse_expression_no_comma())
          }
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
      let span = expr.span.merge(end.span)
      expr = {
        kind: ExprKind::Call({ callee: expr, args, optional: false }),
        span,
      }
      continue
    }
    if self.eat(TokenKind::QuestionDot) {
      if self.eat(TokenKind::LParen) {
        let args : Array[Expr] = []
        if !self.check(TokenKind::RParen) {
          while true {
            if self.eat(TokenKind::Ellipsis) {
              args.push(self.parse_expression_no_comma())
            } else {
              args.push(self.parse_expression_no_comma())
            }
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
      if self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_) {
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
    if self.eat_keyword(Keyword::As) || self.eat_ident_name("satisfies") {
      let ty = self.parse_type()
      let span = expr.span.merge(ty.span)
      expr = { kind: expr.kind, span }
      continue
    }
    if self.allow_type_colon && self.eat(TokenKind::Colon) {
      let ty = self.parse_type()
      let span = expr.span.merge(ty.span)
      expr = { kind: expr.kind, span }
      continue
    }
    if self.eat(TokenKind::Dot) {
      if self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_) {
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
      let prop : Expr = if self.check(TokenKind::RBracket) {
        self.record_expected("expression")
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
    if self.eat_keyword(Keyword::As) {
      let type_ann = self.parse_type()
      let span = expr.span.merge(type_ann.span)
      expr = { kind: ExprKind::TypeAssert({ expr, type_ann }), span }
      continue
    }
    if self.eat(TokenKind::PlusPlus) {
      let op_span = self.previous().span
      let span = expr.span.merge(op_span)
      expr = {
        kind: ExprKind::Update({ op: UpdateOp::Increment, prefix: false, expr }),
        span,
      }
      break
    }
    if self.eat(TokenKind::MinusMinus) {
      let op_span = self.previous().span
      let span = expr.span.merge(op_span)
      expr = {
        kind: ExprKind::Update({ op: UpdateOp::Decrement, prefix: false, expr }),
        span,
      }
      break
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
      if self.current().kind is TokenKind::Ident(_) ||
        self.current().kind is TokenKind::Keyword(_) {
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
      let prop : Expr = if self.check(TokenKind::RBracket) {
        self.record_expected("expression")
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
  ignore(self.expect(TokenKind::Lt, "'<'"))
  if !self.check(TokenKind::Gt) {
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
  ignore(self.expect(TokenKind::Lt, "'<'"))
  if !self.check(TokenKind::Gt) {
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
  if self.check(TokenKind::Question) {
    let start = self.advance().span
    if self.check(TokenKind::Comma) || self.check(TokenKind::Gt) {
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
fn Parser::is_arrow_after_paren(self : Parser) -> Bool {
  if !self.check(TokenKind::LParen) {
    return false
  }
  let mut depth = 0
  let mut offset = 0
  while self.peek_kind(offset) is Some(kind) {
    match kind {
      TokenKind::LParen => depth += 1
      TokenKind::RParen => {
        depth -= 1
        if depth == 0 {
          let next = self.peek_kind(offset + 1)
          if next == Some(TokenKind::Arrow) {
            return true
          }
          if next != Some(TokenKind::Colon) {
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
              TokenKind::Comma | TokenKind::Semicolon | TokenKind::Eq =>
                if paren_depth == 0 &&
                  bracket_depth == 0 &&
                  brace_depth == 0 &&
                  angle_depth == 0 {
                  return false
                }
              TokenKind::Eof => return false
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
    TokenKind::Ident(_) => {
      let mut offset = 1
      if self.peek_kind(offset) == Some(TokenKind::Question) {
        offset += 1
      }
      if self.peek_kind(offset) == Some(TokenKind::Arrow) {
        return true
      }
      if self.peek_kind(offset) != Some(TokenKind::Colon) {
        return false
      }
      offset += 1
      let mut paren_depth = 0
      let mut bracket_depth = 0
      let mut brace_depth = 0
      let mut angle_depth = 0
      while self.peek_kind(offset) is Some(kind) {
        match kind {
          TokenKind::LParen => paren_depth += 1
          TokenKind::RParen => {
            if paren_depth == 0 {
              return false
            }
            paren_depth -= 1
          }
          TokenKind::LBracket => bracket_depth += 1
          TokenKind::RBracket => {
            if bracket_depth == 0 {
              return false
            }
            bracket_depth -= 1
          }
          TokenKind::LBrace => brace_depth += 1
          TokenKind::RBrace => {
            if brace_depth == 0 {
              return false
            }
            brace_depth -= 1
          }
          TokenKind::Lt => angle_depth += 1
          TokenKind::Gt => {
            if angle_depth == 0 {
              return false
            }
            angle_depth -= 1
          }
          TokenKind::Arrow =>
            if paren_depth == 0 &&
              bracket_depth == 0 &&
              brace_depth == 0 &&
              angle_depth == 0 {
              return true
            }
          TokenKind::Comma | TokenKind::Semicolon | TokenKind::Eq =>
            if paren_depth == 0 &&
              bracket_depth == 0 &&
              brace_depth == 0 &&
              angle_depth == 0 {
              return false
            }
          TokenKind::Eof => return false
          _ => ()
        }
        offset += 1
      }
      false
    }
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
  if !self.eat(TokenKind::Arrow) {
    if !self.check(TokenKind::LBrace) {
      ignore(self.expect(TokenKind::Arrow, "'=>'"))
    }
  }
  let body = if self.check(TokenKind::LBrace) {
    FunctionBody::Block(self.parse_block())
  } else if self.is_statement_start_for_arrow_body() {
    let mut end_span = self.current().span
    while !self.check(TokenKind::Semicolon) &&
          !self.check(TokenKind::RBrace) &&
          !self.at_end() {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    FunctionBody::Block({ stmts: [], span: start_span.merge(end_span) })
  } else {
    FunctionBody::Expr(self.parse_expression_no_comma())
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
    TokenKind::RBrace => true
    _ => false
  }
}

///|
fn Parser::parse_arrow_from_ident(self : Parser) -> Expr raise ParseError {
  let (name, name_span) = self.expect_ident()
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
  if !self.eat(TokenKind::Arrow) {
    if !self.check(TokenKind::LBrace) {
      ignore(self.expect(TokenKind::Arrow, "'=>'"))
    }
  }
  let body = if self.check(TokenKind::LBrace) {
    FunctionBody::Block(self.parse_block())
  } else if self.is_statement_start_for_arrow_body() {
    let mut end_span = self.current().span
    while !self.check(TokenKind::Semicolon) &&
          !self.check(TokenKind::RBrace) &&
          !self.at_end() {
      end_span = self.advance().span
    }
    if self.eat(TokenKind::Semicolon) {
      end_span = self.previous().span
    }
    FunctionBody::Block({ stmts: [], span: name_span.merge(end_span) })
  } else {
    FunctionBody::Expr(self.parse_expression_no_comma())
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
fn Parser::parse_object_literal(self : Parser) -> Expr raise ParseError {
  let start = self.expect(TokenKind::LBrace, "'{' ")
  let props : Array[ObjectProp] = []
  if !self.check(TokenKind::RBrace) {
    while true {
      if self.eat(TokenKind::Ellipsis) {
        let expr = self.parse_expression_no_comma()
        props.push(ObjectProp::Spread(expr))
      } else {
        if self.check_ident_name("async") &&
          self.peek_kind(1) == Some(TokenKind::Star) {
          ignore(self.advance())
        }
        ignore(self.eat(TokenKind::Star))
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
        if self.check_keyword(Keyword::Public) ||
          self.check_keyword(Keyword::Private) ||
          self.check_keyword(Keyword::Protected) ||
          self.check_keyword(Keyword::Readonly) {
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
        let token = self.current()
        let (name, name_span, is_ident) = match token.kind {
          TokenKind::LBracket => {
            let (computed_name, computed_span) = self.parse_bracket_member_name()
            (computed_name, computed_span, false)
          }
          TokenKind::Ident(value) => {
            ignore(self.advance())
            (value, token.span, true)
          }
          TokenKind::Keyword(kw) => {
            ignore(self.advance())
            (keyword_to_string(kw), token.span, true)
          }
          TokenKind::String(value) => {
            ignore(self.advance())
            (value, token.span, false)
          }
          TokenKind::Number(value) => {
            ignore(self.advance())
            (value, token.span, false)
          }
          _ => raise ParseError::Expected(pos=token.span.start, "property name")
        }
        let type_params = self.parse_type_params()
        ignore(self.eat(TokenKind::Question))
        if self.check(TokenKind::LParen) {
          let params = self.parse_params(false)
          let mut return_type : TypeNode? = None
          if self.eat(TokenKind::Colon) {
            return_type = Some(self.parse_type())
          } else if self.eat(TokenKind::Arrow) {
            return_type = Some(self.parse_type())
          }
          let body : Block = if self.check(TokenKind::Semicolon) ||
            self.check(TokenKind::Comma) {
            let end_tok = self.advance().span
            { stmts: [], span: end_tok }
          } else {
            self.parse_block()
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
          props.push(
            ObjectProp::Property({ name, value, shorthand: false, span }),
          )
          if self.eat(TokenKind::Comma) || self.eat(TokenKind::Semicolon) {
            if self.check(TokenKind::RBrace) {
              break
            }
            continue
          }
          break
        }
        let mut end_span = name_span
        let mut shorthand = false
        let value = if self.eat(TokenKind::Colon) {
          let expr = self.parse_expression_no_comma()
          end_span = expr.span
          expr
        } else if is_ident && self.eat(TokenKind::Eq) {
          let expr = self.parse_expression_no_comma()
          end_span = expr.span
          expr
        } else {
          if !is_ident {
            raise ParseError::Expected(pos=token.span.start, "':'")
          }
          shorthand = true
          { kind: ExprKind::Ident(name), span: name_span }
        }
        let span = name_span.merge(end_span)
        props.push(ObjectProp::Property({ name, value, shorthand, span }))
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
    | TokenKind::Tilde => true
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
    self.current().span
  } else {
    self.expect(TokenKind::RBracket, "']'").span
  }
  { kind: ExprKind::Array(elements), span: start.span.merge(end_span) }
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
fn Parser::parse_template_literal(self : Parser) -> Expr raise ParseError {
  let start = self.expect(TokenKind::TemplateStart, "`")
  let quasis : Array[String] = []
  let exprs : Array[Expr] = []
  let (first_chunk, _) = self.expect_template_chunk()
  quasis.push(first_chunk)
  while self.check(TokenKind::TemplateExprStart) {
    ignore(self.advance())
    let expr : Expr = if self.check(TokenKind::RBrace) {
      self.record_expected("expression")
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
      ignore(self.eat(TokenKind::RBrace))
    }
    exprs.push(expr)
    if self.current().kind is TokenKind::TemplateChunk(_) {
      let (chunk, _) = self.expect_template_chunk()
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
  ignore(self.expect_template_chunk())
  while self.check(TokenKind::TemplateExprStart) {
    ignore(self.advance())
    ignore(self.parse_type())
    ignore(self.expect(TokenKind::RBrace, "'}'"))
    ignore(self.expect_template_chunk())
  }
  let end = self.expect(TokenKind::TemplateEnd, "`")
  let span = start.span.merge(end.span)
  { kind: TypeKind::Literal(TypeLiteral::String("template")), span }
}

///|
fn Parser::parse_primary(self : Parser) -> Expr raise ParseError {
  while self.check(TokenKind::At) {
    self.parse_decorator()
  }
  let token = self.current()
  match token.kind {
    TokenKind::Ident(_) if self.is_arrow_after_ident() =>
      self.parse_arrow_from_ident()
    TokenKind::Lt =>
      if self.is_arrow_after_paren() {
        let start = self.current().span
        let saved = self.index
        let mut type_params : Array[TypeParam] = []
        try {
          type_params = self.parse_type_params()
        } catch {
          _ => self.index = saved
        }
        if self.check(TokenKind::LParen) && self.is_arrow_after_paren() {
          return self.parse_arrow_from_paren_with_type_params(
            start, type_params,
          )
        }
        self.index = saved
        self.parse_postfix()
      } else {
        self.parse_postfix()
      }
    TokenKind::Ident(name) =>
      if name == "async" && self.peek_kind(1) == Some(TokenKind::Lt) {
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
          return self.parse_arrow_from_paren_with_type_params(
            async_start, type_params,
          )
        }
        self.index = saved
        ignore(self.advance())
        { kind: ExprKind::Ident(name), span: token.span }
      } else if name == "async" &&
        self.peek_kind(1) == Some(TokenKind::Keyword(Keyword::Function)) {
        let async_start = self.advance().span
        ignore(self.expect_keyword(Keyword::Function))
        let (decl, span) = self.parse_function_decl_value(async_start, true)
        { kind: ExprKind::Function(decl), span }
      } else if name == "async" && self.peek_kind(1) == Some(TokenKind::LParen) {
        ignore(self.advance())
        if self.is_arrow_after_paren() {
          self.parse_arrow_from_paren()
        } else {
          { kind: ExprKind::Ident(name), span: token.span }
        }
      } else {
        ignore(self.advance())
        { kind: ExprKind::Ident(name), span: token.span }
      }
    TokenKind::Number(value) => {
      ignore(self.advance())
      { kind: ExprKind::Number(value), span: token.span }
    }
    TokenKind::String(value) => {
      ignore(self.advance())
      { kind: ExprKind::String(value), span: token.span }
    }
    TokenKind::Slash => {
      let start = self.advance().span
      let mut in_class = false
      while !self.at_end() {
        match self.current().kind {
          TokenKind::LBracket => {
            in_class = true
            ignore(self.advance())
          }
          TokenKind::RBracket => {
            in_class = false
            ignore(self.advance())
          }
          TokenKind::Slash =>
            if in_class {
              ignore(self.advance())
            } else {
              break
            }
          _ => ignore(self.advance())
        }
      }
      let mut end_span = start
      if self.check(TokenKind::Slash) {
        end_span = self.advance().span
      }
      while self.current().kind is TokenKind::Ident(_) {
        end_span = self.advance().span
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
      let (decl, span) = self.parse_function_decl_value(start, true)
      { kind: ExprKind::Function(decl), span }
    }
    TokenKind::Keyword(Keyword::Class) => {
      let start = self.advance().span
      let (decl, span) = self.parse_class_decl_value(start, true)
      { kind: ExprKind::Class(decl), span }
    }
    TokenKind::Keyword(kw) => {
      ignore(self.advance())
      let name = keyword_to_string(kw)
      { kind: ExprKind::Ident(name), span: token.span }
    }
    TokenKind::LParen =>
      if self.is_arrow_after_paren() {
        self.parse_arrow_from_paren()
      } else {
        let start = self.advance().span
        if self.check(TokenKind::RParen) {
          let end = self.advance().span
          return { kind: ExprKind::Ident("undefined"), span: start.merge(end) }
        }
        let expr = self.parse_expression()
        if self.eat(TokenKind::Colon) {
          ignore(self.parse_type())
        }
        if !self.check(TokenKind::RParen) {
          while !self.check(TokenKind::RParen) && !self.at_end() {
            ignore(self.advance())
          }
        }
        let end = self.expect(TokenKind::RParen, "')'").span
        { kind: expr.kind, span: start.merge(end) }
      }
    TokenKind::LBrace => self.parse_object_literal()
    TokenKind::LBracket => self.parse_array_literal()
    TokenKind::TemplateStart => self.parse_template_literal()
    TokenKind::Eof => { kind: ExprKind::Ident("undefined"), span: token.span }
    _ => raise ParseError::Expected(pos=token.span.start, "expression")
  }
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
fn Parser::parse_type_union(self : Parser) -> TypeNode raise ParseError {
  let types : Array[TypeNode] = []
  while self.eat(TokenKind::Pipe) {

  }
  types.push(self.parse_type_intersection())
  while self.eat(TokenKind::Pipe) {
    types.push(self.parse_type_intersection())
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
  while self.eat(TokenKind::Ampersand) {

  }
  types.push(self.parse_type_primary())
  while self.eat(TokenKind::Ampersand) {
    types.push(self.parse_type_primary())
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
  if self.check(TokenKind::LBrace) || self.check(TokenKind::LBracket) {
    return true
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
    self.record_error(
      ParseError::UnexpectedToken(
        pos=self.current().span.start,
        "parameter modifiers are not allowed in function types",
      ),
    )
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
    if self.check(TokenKind::Arrow) &&
      (params.length() == 0 || saw_named_param || params.length() > 1) {
      ignore(self.expect(TokenKind::Arrow, "'=>'"))
      let ret = self.parse_type()
      let span = start.span.merge(ret.span)
      return self.parse_type_postfix({
        kind: TypeKind::Function(params, ret),
        span,
      })
    }
    if params.length() == 0 {
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
    let start = self.expect(TokenKind::LBrace, "'{' ")
    let members : Array[TypeMember] = []
    while !self.check(TokenKind::RBrace) && !self.at_end() {
      if self.check(TokenKind::Lt) &&
        self.peek_kind(1) == Some(TokenKind::Minus) {
        ignore(self.advance())
        ignore(self.advance())
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
    if !self.check(TokenKind::RParen) {
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
          _ => ignore(self.advance())
        }
      }
    }
    let end = self.expect(TokenKind::RParen, "')'")
    let mut name = "import(\"\{source}\")"
    let mut span = start.span.merge(end.span)
    while self.eat(TokenKind::Dot) {
      let (part, part_span) = self.parse_ident_name()
      name = "\{name}.\{part}"
      span = span.merge(part_span)
    }
    let mut node : TypeNode = { kind: TypeKind::Ident(name), span }
    if self.eat(TokenKind::Lt) {
      let args : Array[TypeNode] = []
      if !self.check(TokenKind::Gt) {
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
      if self.check(TokenKind::Dot) {
        let end_span = self.skip_expression_suffix_in_type()
        return { kind: node.kind, span: node.span.merge(end_span) }
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Number(value) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Number(value)),
        span: token.span,
      }
      if self.check(TokenKind::Dot) {
        let end_span = self.skip_expression_suffix_in_type()
        return { kind: node.kind, span: node.span.merge(end_span) }
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Keyword(Keyword::True) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Bool(true)),
        span: token.span,
      }
      if self.check(TokenKind::Dot) {
        let end_span = self.skip_expression_suffix_in_type()
        return { kind: node.kind, span: node.span.merge(end_span) }
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Keyword(Keyword::False) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Bool(false)),
        span: token.span,
      }
      if self.check(TokenKind::Dot) {
        let end_span = self.skip_expression_suffix_in_type()
        return { kind: node.kind, span: node.span.merge(end_span) }
      }
      self.parse_type_postfix(node)
    }
    TokenKind::Keyword(Keyword::Null) => {
      ignore(self.advance())
      let node : TypeNode = {
        kind: TypeKind::Literal(TypeLiteral::Null),
        span: token.span,
      }
      if self.check(TokenKind::Dot) {
        let end_span = self.skip_expression_suffix_in_type()
        return { kind: node.kind, span: node.span.merge(end_span) }
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
      if self.eat(TokenKind::Lt) {
        let args : Array[TypeNode] = []
        if !self.check(TokenKind::Gt) {
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
  while self.eat(TokenKind::LBracket) {
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
  while self.eat(TokenKind::Lt) {
    let args : Array[TypeNode] = []
    if !self.check(TokenKind::Gt) {
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
fn detect_jsx_mode(source : String) -> Bool {
  for line in source.split("\n") {
    if line.contains("@filename") {
      if line.contains(".tsx") || line.contains(".jsx") {
        return true
      }
    }
    if line.contains("@jsx") {
      return true
    }
  }
  if source.contains("<>") || source.contains("</>") {
    return true
  }
  false
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
pub fn parse_program(source : String) -> Program raise LexError {
  let normalized = normalize_source(source)
  let tokens = tokenize(normalized)
  let jsx_mode = detect_jsx_mode(normalized.to_string())
  let parser = Parser::new(tokens, jsx_mode)
  parser.parse_program()
}

///|
pub fn parse_program_with_jsx(
  source : String,
  jsx_mode : Bool,
) -> Program raise LexError {
  let normalized = normalize_source(source)
  let tokens = tokenize(normalized)
  let parser = Parser::new(tokens, jsx_mode)
  parser.parse_program()
}
