///|
priv enum LexerMode {
  Normal
  Template
  TemplateExpr
} derive(Eq)

///|
priv struct Lexer {
  bytes : Bytes
  mut pos : Int
  mut line : Int
  mut column : Int
  mut mode : LexerMode
  mode_stack : Array[LexerMode]
  mut template_expr_depth : Int
  pending : Array[Token]
}

///|
fn Lexer::new(input : String) -> Lexer {
  let bytes = @utf8.encode(input)
  let bom0 : Byte = 0xef
  let bom1 : Byte = 0xbb
  let bom2 : Byte = 0xbf
  let mut pos = 0
  if bytes.length() >= 3 &&
    bytes[0] == bom0 &&
    bytes[1] == bom1 &&
    bytes[2] == bom2 {
    pos = 3
  }
  {
    bytes,
    pos,
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
fn Lexer::peek(self : Lexer) -> Byte? {
  if self.pos < self.bytes.length() {
    Some(self.bytes[self.pos])
  } else {
    None
  }
}

///|
fn Lexer::peek_n(self : Lexer, n : Int) -> Byte? {
  let idx = self.pos + n
  if idx < self.bytes.length() {
    Some(self.bytes[idx])
  } else {
    None
  }
}

///|
fn Lexer::bump(self : Lexer) -> Unit {
  if self.pos < self.bytes.length() {
    let b = self.bytes[self.pos]
    self.pos += 1
    if b == b'\n' {
      self.line += 1
      self.column = 1
    } else {
      self.column += 1
    }
  }
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
fn is_whitespace(b : Byte) -> Bool {
  b == b' ' || b == b'\t' || b == b'\n' || b == b'\r'
}

///|
fn is_digit(b : Byte) -> Bool {
  b >= b'0' && b <= b'9'
}

///|
fn is_hex_digit(b : Byte) -> Bool {
  is_digit(b) || (b >= b'a' && b <= b'f') || (b >= b'A' && b <= b'F')
}

///|
fn is_bin_digit(b : Byte) -> Bool {
  b == b'0' || b == b'1'
}

///|
fn is_oct_digit(b : Byte) -> Bool {
  b >= b'0' && b <= b'7'
}

///|
fn is_alpha(b : Byte) -> Bool {
  (b >= b'a' && b <= b'z') ||
  (b >= b'A' && b <= b'Z') ||
  b == b'_' ||
  b == b'$' ||
  b >= 0x80
}

///|
fn is_ident_start(b : Byte) -> Bool {
  is_alpha(b)
}

///|
fn is_ident_part(b : Byte) -> Bool {
  is_alpha(b) || is_digit(b)
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
fn Lexer::is_conflict_marker_start(self : Lexer, ch : Byte) -> Bool {
  if self.peek() != Some(ch) {
    return false
  }
  let mut i = 1
  while i < 7 {
    if self.peek_n(i) != Some(ch) {
      return false
    }
    i += 1
  }
  true
}

///|
fn Lexer::skip_ws_and_comments(self : Lexer) -> Unit raise ParseError {
  let mut progressed = true
  while progressed {
    progressed = false
    if self.column == 1 &&
      self.peek() == Some(b'#') &&
      self.peek_n(1) == Some(b'!') {
      self.bump()
      self.bump()
      while self.peek() is Some(b) && b != b'\n' {
        self.bump()
      }
      progressed = true
      continue
    }
    if self.column == 1 &&
      (
        self.is_conflict_marker_start(b'<') ||
        self.is_conflict_marker_start(b'>') ||
        self.is_conflict_marker_start(b'=') ||
        self.is_conflict_marker_start(b'|')
      ) {
      while self.peek() is Some(b) && b != b'\n' {
        self.bump()
      }
      progressed = true
      continue
    }
    while self.peek() is Some(b) && is_whitespace(b) {
      self.bump()
      progressed = true
    }
    if self.peek() == Some(b'/') && self.peek_n(1) == Some(b'/') {
      self.bump()
      self.bump()
      while self.peek() is Some(b) && b != b'\n' {
        self.bump()
      }
      progressed = true
    } else if self.peek() == Some(b'/') && self.peek_n(1) == Some(b'*') {
      let start = self.position()
      self.bump()
      self.bump()
      let mut closed = false
      while self.peek() is Some(b) {
        if b == b'*' && self.peek_n(1) == Some(b'/') {
          self.bump()
          self.bump()
          closed = true
          break
        }
        self.bump()
      }
      if !closed {
        raise ParseError::UnterminatedComment(pos=start)
      }
      progressed = true
    }
  }
}

///|
fn Lexer::slice_to_string(self : Lexer, start : Int, end_ : Int) -> String {
  @utf8.decode_lossy(self.bytes[start:end_])
}

///|
fn Lexer::read_ident(self : Lexer) -> String {
  let start = self.pos
  while self.peek() is Some(b) {
    if is_ident_part(b) {
      self.bump()
      continue
    }
    if b == b'\\' && self.peek_n(1) == Some(b'u') {
      self.bump()
      self.bump()
      if self.peek() == Some(b'{') {
        self.bump()
        while self.peek() is Some(b2) && b2 != b'}' {
          self.bump()
        }
        if self.peek() == Some(b'}') {
          self.bump()
        }
      } else {
        let mut count = 0
        while self.peek() is Some(_) && count < 4 {
          self.bump()
          count += 1
        }
      }
      continue
    }
    break
  }
  self.slice_to_string(start, self.pos)
}

///|
fn Lexer::read_number(
  self : Lexer,
  start_pos : Position,
) -> String raise ParseError {
  let start = self.pos
  if self.peek() == Some(b'0') {
    match self.peek_n(1) {
      Some(b'x') | Some(b'X') => {
        self.bump()
        self.bump()
        while self.peek() is Some(b) && (is_hex_digit(b) || b == b'_') {
          self.bump()
        }
        if self.peek() == Some(b'n') {
          self.bump()
        }
        return self.slice_to_string(start, self.pos)
      }
      Some(b'b') | Some(b'B') => {
        self.bump()
        self.bump()
        while self.peek() is Some(b) && (is_bin_digit(b) || b == b'_') {
          self.bump()
        }
        if self.peek() == Some(b'n') {
          self.bump()
        }
        return self.slice_to_string(start, self.pos)
      }
      Some(b'o') | Some(b'O') => {
        self.bump()
        self.bump()
        while self.peek() is Some(b) && (is_oct_digit(b) || b == b'_') {
          self.bump()
        }
        if self.peek() == Some(b'n') {
          self.bump()
        }
        return self.slice_to_string(start, self.pos)
      }
      _ => ()
    }
  }
  while self.peek() is Some(b) && (is_digit(b) || b == b'_') {
    self.bump()
  }
  if self.peek() == Some(b'.') {
    match self.peek_n(1) {
      Some(next) if is_digit(next) => {
        self.bump()
        while self.peek() is Some(b) && (is_digit(b) || b == b'_') {
          self.bump()
        }
      }
      _ => ()
    }
  }
  match self.peek() {
    Some(b'e') | Some(b'E') => {
      self.bump()
      if self.peek() == Some(b'+') || self.peek() == Some(b'-') {
        self.bump()
      }
      let exp_start = self.pos
      while self.peek() is Some(b) && (is_digit(b) || b == b'_') {
        self.bump()
      }
      if self.pos == exp_start {
        raise ParseError::InvalidNumber(
          pos=start_pos,
          self.slice_to_string(start, self.pos),
        )
      }
    }
    _ => ()
  }
  if self.peek() == Some(b'n') {
    self.bump()
  }
  self.slice_to_string(start, self.pos)
}

///|
fn Lexer::read_string(self : Lexer, quote : Byte) -> String {
  let out : Array[Byte] = []
  while self.peek() is Some(b) {
    if b == quote {
      self.bump()
      let bytes = Bytes::from_array(out[:])
      return @utf8.decode_lossy(bytes[:])
    }
    if b == b'\\' {
      self.bump()
      out.push(b'\\')
      match self.peek() {
        Some(next) => {
          self.bump()
          out.push(next)
        }
        None => {
          let bytes = Bytes::from_array(out[:])
          return @utf8.decode_lossy(bytes[:])
        }
      }
    } else {
      self.bump()
      out.push(b)
    }
  }
  let bytes = Bytes::from_array(out[:])
  @utf8.decode_lossy(bytes[:])
}

///|
fn Lexer::next_template_token(self : Lexer) -> Token raise ParseError {
  let chunk_start_pos = self.position()
  let start = self.pos
  while self.peek() is Some(b) {
    if b == b'`' {
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
    if b == b'$' && self.peek_n(1) == Some(b'{') {
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
  raise ParseError::UnterminatedString(pos=chunk_start_pos)
}

///|
fn Lexer::next_token(self : Lexer) -> Token raise ParseError {
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
        let number = self.read_number(start)
        let end = self.position()
        Token::{ kind: TokenKind::Number(number), span: span_from(start, end) }
      } else {
        match b {
          b'`' => {
            self.bump()
            self.push_mode(LexerMode::Template)
            Token::{
              kind: TokenKind::TemplateStart,
              span: span_from(start, self.position()),
            }
          }
          b'\'' | b'"' => {
            self.bump()
            let value = self.read_string(b)
            let end = self.position()
            Token::{
              kind: TokenKind::String(value),
              span: span_from(start, end),
            }
          }
          b'(' => {
            self.bump()
            Token::{
              kind: TokenKind::LParen,
              span: span_from(start, self.position()),
            }
          }
          b')' => {
            self.bump()
            Token::{
              kind: TokenKind::RParen,
              span: span_from(start, self.position()),
            }
          }
          b'{' => {
            self.bump()
            Token::{
              kind: TokenKind::LBrace,
              span: span_from(start, self.position()),
            }
          }
          b'}' => {
            self.bump()
            Token::{
              kind: TokenKind::RBrace,
              span: span_from(start, self.position()),
            }
          }
          b'[' => {
            self.bump()
            Token::{
              kind: TokenKind::LBracket,
              span: span_from(start, self.position()),
            }
          }
          b']' => {
            self.bump()
            Token::{
              kind: TokenKind::RBracket,
              span: span_from(start, self.position()),
            }
          }
          b'\\' => {
            if self.peek_n(1) == Some(b'u') {
              let ident = self.read_ident()
              return Token::{
                kind: TokenKind::Ident(ident),
                span: span_from(start, self.position()),
              }
            }
            self.bump()
            if self.peek() == Some(b'\n') {
              self.bump()
              return self.next_token()
            }
            if self.peek() == Some(b'\r') {
              self.bump()
              if self.peek() == Some(b'\n') {
                self.bump()
              }
              return self.next_token()
            }
            Token::{
              kind: TokenKind::Ident("\\"),
              span: span_from(start, self.position()),
            }
          }
          b'#' => {
            self.bump()
            if self.peek() is Some(next_b) && is_ident_start(next_b) {
              let name = self.read_ident()
              let end = self.position()
              Token::{
                kind: TokenKind::Ident("#\{name}"),
                span: span_from(start, end),
              }
            } else {
              Token::{
                kind: TokenKind::Ident("#"),
                span: span_from(start, self.position()),
              }
            }
          }
          b',' => {
            self.bump()
            Token::{
              kind: TokenKind::Comma,
              span: span_from(start, self.position()),
            }
          }
          b';' => {
            self.bump()
            Token::{
              kind: TokenKind::Semicolon,
              span: span_from(start, self.position()),
            }
          }
          b':' => {
            self.bump()
            Token::{
              kind: TokenKind::Colon,
              span: span_from(start, self.position()),
            }
          }
          b'.' =>
            if self.peek_n(1) == Some(b'.') && self.peek_n(2) == Some(b'.') {
              self.bump()
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::Ellipsis,
                span: span_from(start, self.position()),
              }
            } else if self.peek_n(1) is Some(next) && is_digit(next) {
              self.bump()
              while self.peek() is Some(b) && (is_digit(b) || b == b'_') {
                self.bump()
              }
              match self.peek() {
                Some(b'e') | Some(b'E') => {
                  self.bump()
                  if self.peek() == Some(b'+') || self.peek() == Some(b'-') {
                    self.bump()
                  }
                  let exp_start = self.pos
                  while self.peek() is Some(b) && (is_digit(b) || b == b'_') {
                    self.bump()
                  }
                  if self.pos == exp_start {
                    raise ParseError::InvalidNumber(
                      pos=start,
                      self.slice_to_string(start.offset, self.pos),
                    )
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
              self.bump()
              Token::{
                kind: TokenKind::Dot,
                span: span_from(start, self.position()),
              }
            }
          b'@' => {
            self.bump()
            Token::{
              kind: TokenKind::At,
              span: span_from(start, self.position()),
            }
          }
          b'?' =>
            if self.peek_n(1) == Some(b'?') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::Nullish,
                span: span_from(start, self.position()),
              }
            } else if self.peek_n(1) == Some(b'.') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::QuestionDot,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Question,
                span: span_from(start, self.position()),
              }
            }
          b'+' =>
            if self.peek_n(1) == Some(b'+') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::PlusPlus,
                span: span_from(start, self.position()),
              }
            } else if self.peek_n(1) == Some(b'=') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::PlusEq,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Plus,
                span: span_from(start, self.position()),
              }
            }
          b'-' =>
            if self.peek_n(1) == Some(b'-') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::MinusMinus,
                span: span_from(start, self.position()),
              }
            } else if self.peek_n(1) == Some(b'=') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::MinusEq,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Minus,
                span: span_from(start, self.position()),
              }
            }
          b'*' =>
            if self.peek_n(1) == Some(b'*') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::StarStar,
                span: span_from(start, self.position()),
              }
            } else if self.peek_n(1) == Some(b'=') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::StarEq,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Star,
                span: span_from(start, self.position()),
              }
            }
          b'/' =>
            if self.peek_n(1) == Some(b'=') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::SlashEq,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Slash,
                span: span_from(start, self.position()),
              }
            }
          b'%' =>
            if self.peek_n(1) == Some(b'=') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::PercentEq,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Percent,
                span: span_from(start, self.position()),
              }
            }
          b'~' => {
            self.bump()
            Token::{
              kind: TokenKind::Tilde,
              span: span_from(start, self.position()),
            }
          }
          b'^' => {
            self.bump()
            Token::{
              kind: TokenKind::Caret,
              span: span_from(start, self.position()),
            }
          }
          b'=' =>
            if self.peek_n(1) == Some(b'=') {
              if self.peek_n(2) == Some(b'=') {
                self.bump()
                self.bump()
                self.bump()
                Token::{
                  kind: TokenKind::EqEqEq,
                  span: span_from(start, self.position()),
                }
              } else {
                self.bump()
                self.bump()
                Token::{
                  kind: TokenKind::EqEq,
                  span: span_from(start, self.position()),
                }
              }
            } else if self.peek_n(1) == Some(b'>') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::Arrow,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Eq,
                span: span_from(start, self.position()),
              }
            }
          b'!' =>
            if self.peek_n(1) == Some(b'=') {
              if self.peek_n(2) == Some(b'=') {
                self.bump()
                self.bump()
                self.bump()
                Token::{
                  kind: TokenKind::NotEqEq,
                  span: span_from(start, self.position()),
                }
              } else {
                self.bump()
                self.bump()
                Token::{
                  kind: TokenKind::NotEq,
                  span: span_from(start, self.position()),
                }
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Bang,
                span: span_from(start, self.position()),
              }
            }
          b'<' =>
            if self.peek_n(1) == Some(b'=') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::Lte,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Lt,
                span: span_from(start, self.position()),
              }
            }
          b'>' =>
            if self.peek_n(1) == Some(b'=') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::Gte,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Gt,
                span: span_from(start, self.position()),
              }
            }
          b'&' =>
            if self.peek_n(1) == Some(b'&') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::AndAnd,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Ampersand,
                span: span_from(start, self.position()),
              }
            }
          b'|' =>
            if self.peek_n(1) == Some(b'|') {
              self.bump()
              self.bump()
              Token::{
                kind: TokenKind::OrOr,
                span: span_from(start, self.position()),
              }
            } else {
              self.bump()
              Token::{
                kind: TokenKind::Pipe,
                span: span_from(start, self.position()),
              }
            }
          _ => raise ParseError::InvalidChar(pos=start, b)
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
fn tokenize(source : String) -> Array[Token] raise ParseError {
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
