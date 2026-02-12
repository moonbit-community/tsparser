///|
priv enum LexerMode {
  Normal
  Template
  TemplateExpr
} derive(Eq)

///|
priv struct Lexer {
  source : StringView
  mut pos : Int
  mut line : Int
  mut column : Int
  mut mode : LexerMode
  mode_stack : Array[LexerMode]
  mut template_expr_depth : Int
  pending : Array[Token]
}

///|
fn Lexer::new(input : StringView) -> Lexer {
  let source = input
  {
    source,
    pos: 0,
    line: 1,
    column: 1,
    mode: LexerMode::Normal,
    mode_stack: [],
    template_expr_depth: 0,
    pending: [],
  }
}

///|
fn Lexer::position(self : Lexer) -> Position {
  { offset: self.pos, line: self.line, column: self.column }
}

///|
fn Lexer::peek(self : Lexer) -> UInt16? {
  if self.pos < self.source.length() {
    Some(self.source[self.pos])
  } else {
    None
  }
}

///|
fn Lexer::peek_n(self : Lexer, n : Int) -> UInt16? {
  let idx = self.pos + n
  if idx < self.source.length() {
    Some(self.source[idx])
  } else {
    None
  }
}

///|
fn Lexer::bump(self : Lexer) -> Unit {
  if self.pos < self.source.length() {
    let b = self.source[self.pos]
    self.pos += 1
    if b == '\n' {
      self.line += 1
      self.column = 1
    } else {
      self.column += 1
    }
  }
}

///|
fn Lexer::bump_n(self : Lexer, n : Int) -> Unit {
  for _ in 0..<n {
    self.bump()
  }
}

///|
fn Lexer::remaining(self : Lexer) -> StringView {
  self.source.view(start_offset=self.pos)
}

///|
fn Lexer::consume_prefix(
  self : Lexer,
  input : StringView,
  rest : StringView,
) -> Unit {
  let consumed_units = input.length() - rest.length()
  self.bump_n(consumed_units)
}

///|
fn Lexer::token_from_match(
  self : Lexer,
  kind : TokenKind,
  start : Position,
  input : StringView,
  rest : StringView,
) -> Token {
  self.consume_prefix(input, rest)
  Token::{ kind, span: span_from(start, self.position()) }
}

///|
fn Lexer::push_mode(self : Lexer, mode : LexerMode) -> Unit {
  self.mode_stack.push(self.mode)
  self.mode = mode
}

///|
fn Lexer::pop_mode(self : Lexer) -> Unit {
  match self.mode_stack.pop() {
    Some(prev) => self.mode = prev
    None => self.mode = LexerMode::Normal
  }
}

///|
fn is_digit(b : UInt16) -> Bool {
  b >= '0' && b <= '9'
}

///|
fn is_hex_digit(b : UInt16) -> Bool {
  is_digit(b) || (b >= 'a' && b <= 'f') || (b >= 'A' && b <= 'F')
}

///|
fn is_bin_digit(b : UInt16) -> Bool {
  b == '0' || b == '1'
}

///|
fn is_oct_digit(b : UInt16) -> Bool {
  b >= '0' && b <= '7'
}

///|
fn is_alpha(b : UInt16) -> Bool {
  (b >= 'a' && b <= 'z') ||
  (b >= 'A' && b <= 'Z') ||
  b == '_' ||
  b == '$' ||
  (b >= 0x80 && b != 0x85)
}

///|
fn is_ident_start(b : UInt16) -> Bool {
  is_alpha(b)
}

///|
fn is_ident_part(b : UInt16) -> Bool {
  is_alpha(b) || is_digit(b)
}

///|
fn is_line_break_code_unit(ch : UInt16) -> Bool {
  ch == '\n' || ch == '\r'
}

///|
fn Lexer::backslash_likely_in_regex_literal(
  self : Lexer,
  backslash_offset : Int,
) -> Bool {
  if backslash_offset < 0 || backslash_offset >= self.source.length() {
    return false
  }
  if self.source[backslash_offset] != '\\' {
    return false
  }
  let mut i = backslash_offset
  while i > 0 {
    let prev = self.source[i - 1]
    if is_line_break_code_unit(prev) {
      return false
    }
    if prev == '/' {
      if i < self.source.length() {
        let next = self.source[i]
        if next == '/' || next == '*' {
          return false
        }
      }
      let mut j = backslash_offset + 1
      while j < self.source.length() {
        let ch = self.source[j]
        if is_line_break_code_unit(ch) {
          return false
        }
        if ch == '/' {
          return true
        }
        j += 1
      }
      return false
    }
    i -= 1
  }
  false
}

///|
fn keyword_from_ident(name : String) -> Keyword? {
  match name {
    "let" => Some(Keyword::Let)
    "const" => Some(Keyword::Const)
    "var" => Some(Keyword::Var)
    "function" => Some(Keyword::Function)
    "return" => Some(Keyword::Return)
    "if" => Some(Keyword::If)
    "else" => Some(Keyword::Else)
    "while" => Some(Keyword::While)
    "for" => Some(Keyword::For)
    "do" => Some(Keyword::Do)
    "switch" => Some(Keyword::Switch)
    "case" => Some(Keyword::Case)
    "type" => Some(Keyword::Type)
    "typeof" => Some(Keyword::Typeof)
    "interface" => Some(Keyword::Interface)
    "enum" => Some(Keyword::Enum)
    "true" => Some(Keyword::True)
    "false" => Some(Keyword::False)
    "null" => Some(Keyword::Null)
    "undefined" => Some(Keyword::Undefined)
    "this" => Some(Keyword::This)
    "delete" => Some(Keyword::Delete)
    "void" => Some(Keyword::Void)
    "await" => Some(Keyword::Await)
    "yield" => Some(Keyword::Yield)
    "new" => Some(Keyword::New)
    "class" => Some(Keyword::Class)
    "extends" => Some(Keyword::Extends)
    "implements" => Some(Keyword::Implements)
    "export" => Some(Keyword::Export)
    "import" => Some(Keyword::Import)
    "from" => Some(Keyword::From)
    "as" => Some(Keyword::As)
    "default" => Some(Keyword::Default)
    "abstract" => Some(Keyword::Abstract)
    "public" => Some(Keyword::Public)
    "private" => Some(Keyword::Private)
    "protected" => Some(Keyword::Protected)
    "readonly" => Some(Keyword::Readonly)
    "static" => Some(Keyword::Static)
    "get" => Some(Keyword::Get)
    "set" => Some(Keyword::Set)
    "break" => Some(Keyword::Break)
    "continue" => Some(Keyword::Continue)
    "try" => Some(Keyword::Try)
    "catch" => Some(Keyword::Catch)
    "finally" => Some(Keyword::Finally)
    "throw" => Some(Keyword::Throw)
    _ => None
  }
}

///|
fn Lexer::skip_ws_and_comments(self : Lexer) -> Unit raise LexError {
  let mut progressed = true
  while progressed {
    progressed = false
    if self.peek() == Some(0x85) {
      self.bump()
      progressed = true
      continue
    }
    if self.column == 1 {
      let input = self.remaining()
      lexmatch input with longest {
        ("#![^\n]*", rest) => {
          self.consume_prefix(input, rest)
          progressed = true
          continue
        }
        ("<<<<<<<[^\n]*", rest) => {
          self.consume_prefix(input, rest)
          progressed = true
          continue
        }
        (">>>>>>>[^\n]*", rest) => {
          self.consume_prefix(input, rest)
          progressed = true
          continue
        }
        ("=======[^\n]*", rest) => {
          self.consume_prefix(input, rest)
          progressed = true
          continue
        }
        ("\|\|\|\|\|\|\|[^\n]*", rest) => {
          self.consume_prefix(input, rest)
          progressed = true
          continue
        }
        _ => ()
      }
    }
    let input = self.remaining()
    lexmatch input with longest {
      ("[[:space:]]+", rest) => {
        self.consume_prefix(input, rest)
        progressed = true
      }
      ("//[^\n]*", rest) => {
        self.consume_prefix(input, rest)
        progressed = true
      }
      ("/\*", _) => {
        let comment_start = self.position()
        self.bump_n(2)
        let mut closed = false
        while self.peek() is Some(b) {
          if b == '*' && self.peek_n(1) == Some('/') {
            self.bump_n(2)
            closed = true
            break
          }
          self.bump()
        }
        if !closed {
          raise LexError::UnterminatedComment(pos=comment_start)
        }
        progressed = true
      }
      _ => ()
    }
  }
}

///|
fn Lexer::slice_to_string(self : Lexer, start : Int, end_ : Int) -> String {
  self.source.view(start_offset=start, end_offset=end_).to_string()
}

///|
fn Lexer::read_ident(self : Lexer) -> String raise LexError {
  let start = self.pos
  while self.peek() is Some(b) {
    if is_ident_part(b) {
      self.bump()
      continue
    }
    if b == '\\' && self.peek_n(1) == Some('u') {
      let escape_pos = self.position()
      let saved_pos = self.pos
      let saved_line = self.line
      let saved_column = self.column
      self.bump()
      self.bump()
      let mut valid_escape = true
      if self.peek() == Some('{') {
        self.bump()
        let mut saw_hex = false
        while self.peek() is Some(b2) && b2 != '}' {
          if !is_hex_digit(b2) {
            valid_escape = false
            break
          }
          saw_hex = true
          self.bump()
        }
        if valid_escape && (self.peek() != Some('}') || !saw_hex) {
          valid_escape = false
        }
        if valid_escape {
          self.bump()
        }
      } else {
        let mut count = 0
        while valid_escape && count < 4 {
          match self.peek() {
            Some(ch) =>
              if is_hex_digit(ch) {
                self.bump()
                count += 1
              } else {
                valid_escape = false
              }
            None => valid_escape = false
          }
        }
      }
      if valid_escape {
        continue
      }
      if saved_pos == start {
        raise LexError::InvalidChar(pos=escape_pos, '\\')
      }
      self.pos = saved_pos
      self.line = saved_line
      self.column = saved_column
      break
    }
    break
  }
  self.slice_to_string(start, self.pos)
}

///|
fn Lexer::read_number(self : Lexer) -> String {
  let start = self.pos
  if self.peek() == Some('0') {
    match self.peek_n(1) {
      Some('x') | Some('X') => {
        self.bump()
        self.bump()
        while self.peek() is Some(b) && (is_hex_digit(b) || b == '_') {
          self.bump()
        }
        if self.peek() == Some('n') {
          self.bump()
        }
        return self.slice_to_string(start, self.pos)
      }
      Some('b') | Some('B') => {
        self.bump()
        self.bump()
        while self.peek() is Some(b) && (is_bin_digit(b) || b == '_') {
          self.bump()
        }
        if self.peek() == Some('n') {
          self.bump()
        }
        return self.slice_to_string(start, self.pos)
      }
      Some('o') | Some('O') => {
        self.bump()
        self.bump()
        while self.peek() is Some(b) && (is_oct_digit(b) || b == '_') {
          self.bump()
        }
        if self.peek() == Some('n') {
          self.bump()
        }
        return self.slice_to_string(start, self.pos)
      }
      _ => ()
    }
  }
  while self.peek() is Some(b) && (is_digit(b) || b == '_') {
    self.bump()
  }
  if self.peek() == Some('.') {
    match self.peek_n(1) {
      Some(next) if is_digit(next) => {
        self.bump()
        while self.peek() is Some(b) && (is_digit(b) || b == '_') {
          self.bump()
        }
      }
      _ => ()
    }
  }
  match self.peek() {
    Some('e') | Some('E') => {
      self.bump()
      if self.peek() == Some('+') || self.peek() == Some('-') {
        self.bump()
      }
      while self.peek() is Some(b) && (is_digit(b) || b == '_') {
        self.bump()
      }
    }
    _ => ()
  }
  if self.peek() == Some('n') {
    self.bump()
  }
  self.slice_to_string(start, self.pos)
}

///|
fn Lexer::read_string(self : Lexer, quote : UInt16) -> String raise LexError {
  let content_start = self.pos
  while self.peek() is Some(b) {
    if b == quote {
      let value = self.slice_to_string(content_start, self.pos)
      self.bump()
      return value
    }
    if b == '\n' || b == '\r' {
      return self.slice_to_string(content_start, self.pos)
    }
    if b == '\\' {
      self.bump()
      match self.peek() {
        Some('\r') => {
          self.bump()
          if self.peek() == Some('\n') {
            self.bump()
          }
        }
        Some('\n') => self.bump()
        Some(_) => self.bump()
        None => raise LexError::UnexpectedEndOfText(pos=self.position())
      }
    } else {
      self.bump()
    }
  }
  self.slice_to_string(content_start, self.pos)
}

///|
fn Lexer::next_template_token(self : Lexer) -> Token raise LexError {
  let chunk_start_pos = self.position()
  let start = self.pos
  while self.peek() is Some(b) {
    if b == '`' {
      let chunk = self.slice_to_string(start, self.pos)
      let chunk_span = span_from(chunk_start_pos, self.position())
      let chunk_token = Token::{
        kind: TokenKind::TemplateChunk(chunk),
        span: chunk_span,
      }
      let end_start = self.position()
      self.bump()
      let end_token = Token::{
        kind: TokenKind::TemplateEnd,
        span: span_from(end_start, self.position()),
      }
      self.pending.push(end_token)
      self.pop_mode()
      return chunk_token
    }
    if b == '$' && self.peek_n(1) == Some('{') {
      let chunk = self.slice_to_string(start, self.pos)
      let chunk_span = span_from(chunk_start_pos, self.position())
      let chunk_token = Token::{
        kind: TokenKind::TemplateChunk(chunk),
        span: chunk_span,
      }
      let expr_start = self.position()
      self.bump()
      self.bump()
      let expr_token = Token::{
        kind: TokenKind::TemplateExprStart,
        span: span_from(expr_start, self.position()),
      }
      self.pending.push(expr_token)
      self.push_mode(LexerMode::TemplateExpr)
      self.template_expr_depth = 0
      return chunk_token
    }
    self.bump()
  }
  raise LexError::UnterminatedString(pos=self.position())
}

///|
fn Lexer::next_punct_token(self : Lexer, start : Position) -> Token? {
  let input = self.remaining()
  lexmatch input with longest {
    ("\.\.\.", rest) =>
      Some(self.token_from_match(TokenKind::Ellipsis, start, input, rest))
    ("\?\?", rest) =>
      Some(self.token_from_match(TokenKind::Nullish, start, input, rest))
    ("\?\.", rest) =>
      Some(self.token_from_match(TokenKind::QuestionDot, start, input, rest))
    ("\+\+", rest) =>
      Some(self.token_from_match(TokenKind::PlusPlus, start, input, rest))
    ("\+=", rest) =>
      Some(self.token_from_match(TokenKind::PlusEq, start, input, rest))
    ("\+", rest) =>
      Some(self.token_from_match(TokenKind::Plus, start, input, rest))
    ("--", rest) =>
      Some(self.token_from_match(TokenKind::MinusMinus, start, input, rest))
    ("-=", rest) =>
      Some(self.token_from_match(TokenKind::MinusEq, start, input, rest))
    ("-", rest) =>
      Some(self.token_from_match(TokenKind::Minus, start, input, rest))
    ("\*\*", rest) =>
      Some(self.token_from_match(TokenKind::StarStar, start, input, rest))
    ("\*=", rest) =>
      Some(self.token_from_match(TokenKind::StarEq, start, input, rest))
    ("\*", rest) =>
      Some(self.token_from_match(TokenKind::Star, start, input, rest))
    ("/=", rest) =>
      Some(self.token_from_match(TokenKind::SlashEq, start, input, rest))
    ("/", rest) =>
      Some(self.token_from_match(TokenKind::Slash, start, input, rest))
    ("%=", rest) =>
      Some(self.token_from_match(TokenKind::PercentEq, start, input, rest))
    ("%", rest) =>
      Some(self.token_from_match(TokenKind::Percent, start, input, rest))
    ("===", rest) =>
      Some(self.token_from_match(TokenKind::EqEqEq, start, input, rest))
    ("==", rest) =>
      Some(self.token_from_match(TokenKind::EqEq, start, input, rest))
    ("=>", rest) =>
      Some(self.token_from_match(TokenKind::Arrow, start, input, rest))
    ("=", rest) =>
      Some(self.token_from_match(TokenKind::Eq, start, input, rest))
    ("!==", rest) =>
      Some(self.token_from_match(TokenKind::NotEqEq, start, input, rest))
    ("!=", rest) =>
      Some(self.token_from_match(TokenKind::NotEq, start, input, rest))
    ("!", rest) =>
      Some(self.token_from_match(TokenKind::Bang, start, input, rest))
    ("<=", rest) =>
      Some(self.token_from_match(TokenKind::Lte, start, input, rest))
    ("<", rest) =>
      Some(self.token_from_match(TokenKind::Lt, start, input, rest))
    (">=", rest) =>
      Some(self.token_from_match(TokenKind::Gte, start, input, rest))
    (">", rest) =>
      Some(self.token_from_match(TokenKind::Gt, start, input, rest))
    ("&&", rest) =>
      Some(self.token_from_match(TokenKind::AndAnd, start, input, rest))
    ("&", rest) =>
      Some(self.token_from_match(TokenKind::Ampersand, start, input, rest))
    ("\|\|", rest) =>
      Some(self.token_from_match(TokenKind::OrOr, start, input, rest))
    ("\|", rest) =>
      Some(self.token_from_match(TokenKind::Pipe, start, input, rest))
    ("\(", rest) =>
      Some(self.token_from_match(TokenKind::LParen, start, input, rest))
    ("\)", rest) =>
      Some(self.token_from_match(TokenKind::RParen, start, input, rest))
    ("[{]", rest) =>
      Some(self.token_from_match(TokenKind::LBrace, start, input, rest))
    ("[}]", rest) =>
      Some(self.token_from_match(TokenKind::RBrace, start, input, rest))
    ("\[", rest) =>
      Some(self.token_from_match(TokenKind::LBracket, start, input, rest))
    ("\]", rest) =>
      Some(self.token_from_match(TokenKind::RBracket, start, input, rest))
    (",", rest) =>
      Some(self.token_from_match(TokenKind::Comma, start, input, rest))
    (";", rest) =>
      Some(self.token_from_match(TokenKind::Semicolon, start, input, rest))
    (":", rest) =>
      Some(self.token_from_match(TokenKind::Colon, start, input, rest))
    ("\.", rest) =>
      Some(self.token_from_match(TokenKind::Dot, start, input, rest))
    ("@", rest) =>
      Some(self.token_from_match(TokenKind::At, start, input, rest))
    ("\?", rest) =>
      Some(self.token_from_match(TokenKind::Question, start, input, rest))
    ("~", rest) =>
      Some(self.token_from_match(TokenKind::Tilde, start, input, rest))
    ("\^", rest) =>
      Some(self.token_from_match(TokenKind::Caret, start, input, rest))
    _ => None
  }
}

///|
fn Lexer::next_token(self : Lexer) -> Token raise LexError {
  if self.pending.length() > 0 {
    return self.pending.unsafe_pop()
  }
  if self.mode == LexerMode::Template {
    return self.next_template_token()
  }
  self.skip_ws_and_comments()
  let start = self.position()
  let token = match self.peek() {
    None => Token::{ kind: TokenKind::Eof, span: span_from(start, start) }
    Some(b) =>
      if is_ident_start(b) {
        let name = self.read_ident()
        let end = self.position()
        match keyword_from_ident(name) {
          Some(kw) =>
            Token::{ kind: TokenKind::Keyword(kw), span: span_from(start, end) }
          None =>
            Token::{ kind: TokenKind::Ident(name), span: span_from(start, end) }
        }
      } else if is_digit(b) {
        let number = self.read_number()
        let end = self.position()
        Token::{ kind: TokenKind::Number(number), span: span_from(start, end) }
      } else {
        match b {
          '`' => {
            self.bump()
            self.push_mode(LexerMode::Template)
            Token::{
              kind: TokenKind::TemplateStart,
              span: span_from(start, self.position()),
            }
          }
          '\'' | '"' => {
            self.bump()
            let value = self.read_string(b)
            let end = self.position()
            Token::{
              kind: TokenKind::String(value),
              span: span_from(start, end),
            }
          }
          '\\' => {
            if self.peek_n(1) == Some('u') {
              let saved_pos = self.pos
              let saved_line = self.line
              let saved_column = self.column
              try {
                let ident = self.read_ident()
                return Token::{
                  kind: TokenKind::Ident(ident),
                  span: span_from(start, self.position()),
                }
              } catch {
                _ => {
                  self.pos = saved_pos
                  self.line = saved_line
                  self.column = saved_column
                }
              }
            }
            if self.backslash_likely_in_regex_literal(start.offset) {
              self.bump()
              Token::{
                kind: TokenKind::Ident("\\"),
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              if self.peek() == Some('\n') {
                self.bump()
                return self.next_token()
              }
              if self.peek() == Some('\r') {
                self.bump()
                if self.peek() == Some('\n') {
                  self.bump()
                }
                return self.next_token()
              }
              raise LexError::InvalidChar(pos=start, '\\')
            }
          }
          '#' => {
            self.bump()
            let starts_private_ident = match self.peek() {
              Some(next_b) =>
                is_ident_start(next_b) ||
                (next_b == '\\' && self.peek_n(1) == Some('u'))
              None => false
            }
            if starts_private_ident {
              let saved_pos = self.pos
              let saved_line = self.line
              let saved_column = self.column
              try {
                let name = self.read_ident()
                let end = self.position()
                Token::{
                  kind: TokenKind::Ident("#\{name}"),
                  span: span_from(start, end),
                }
              } catch {
                _ => {
                  self.pos = saved_pos
                  self.line = saved_line
                  self.column = saved_column
                  Token::{
                    kind: TokenKind::Ident("#"),
                    span: span_from(start, self.position()),
                  }
                }
              }
            } else {
              Token::{
                kind: TokenKind::Ident("#"),
                span: span_from(start, self.position()),
              }
            }
          }
          '.' =>
            if self.peek_n(1) is Some(next) && is_digit(next) {
              self.bump()
              while self.peek() is Some(ch) && (is_digit(ch) || ch == '_') {
                self.bump()
              }
              match self.peek() {
                Some('e') | Some('E') => {
                  self.bump()
                  if self.peek() == Some('+') || self.peek() == Some('-') {
                    self.bump()
                  }
                  while self.peek() is Some(ch) && (is_digit(ch) || ch == '_') {
                    self.bump()
                  }
                }
                _ => ()
              }
              Token::{
                kind: TokenKind::Number(
                  self.slice_to_string(start.offset, self.pos),
                ),
                span: span_from(start, self.position()),
              }
            } else {
              match self.next_punct_token(start) {
                Some(token) => token
                None => raise LexError::InvalidChar(pos=start, '.')
              }
            }
          other =>
            match self.next_punct_token(start) {
              Some(token) => token
              None => raise LexError::InvalidChar(pos=start, other)
            }
        }
      }
  }
  if self.mode == LexerMode::TemplateExpr {
    match token.kind {
      TokenKind::LBrace => self.template_expr_depth += 1
      TokenKind::RBrace =>
        if self.template_expr_depth == 0 {
          self.pop_mode()
        } else {
          self.template_expr_depth -= 1
        }
      _ => ()
    }
  }
  token
}

///|
fn tokenize(source : StringView) -> Array[Token] raise LexError {
  let lexer = Lexer::new(source)
  let tokens : Array[Token] = []
  while true {
    let token = lexer.next_token()
    tokens.push(token)
    if token.kind is TokenKind::Eof {
      break
    }
  }
  tokens
}
