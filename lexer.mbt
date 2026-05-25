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
    mode: Normal,
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
  { kind, span: span_from(start, self.position()) }
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
    None => self.mode = Normal
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
let merge_conflict_marker_length = 7

///|
fn source_is_conflict_marker_trivia(source : StringView, pos : Int) -> Bool {
  if pos < 0 || pos >= source.length() {
    return false
  }
  if pos > 0 && !is_line_break_code_unit(source[pos - 1]) {
    return false
  }
  let ch = source[pos]
  if ch != '<' && ch != '>' && ch != '=' && ch != '|' {
    return false
  }
  if pos + merge_conflict_marker_length >= source.length() {
    return false
  }
  let mut i = 0
  while i < merge_conflict_marker_length {
    if source[pos + i] != ch {
      return false
    }
    i += 1
  }
  ch == '=' || source[pos + merge_conflict_marker_length] == ' '
}

///|
fn scan_conflict_marker_trivia(source : StringView, start : Int) -> Int {
  if start < 0 || start >= source.length() {
    return start
  }
  let ch = source[start]
  let len = source.length()
  let mut pos = start
  if ch == '<' || ch == '>' {
    while pos < len && !is_line_break_code_unit(source[pos]) {
      pos += 1
    }
    return pos
  }
  while pos < len {
    let current = source[pos]
    if (current == '=' || current == '>') &&
      current != ch &&
      source_is_conflict_marker_trivia(source, pos) {
      break
    }
    pos += 1
  }
  pos
}

///|
fn Lexer::is_conflict_marker_trivia(self : Lexer) -> Bool {
  source_is_conflict_marker_trivia(self.source, self.pos)
}

///|
fn Lexer::scan_conflict_marker_trivia_token(
  self : Lexer,
  start : Position,
) -> Token {
  let end_offset = scan_conflict_marker_trivia(self.source, self.pos)
  while self.pos < end_offset {
    self.bump()
  }
  { kind: ConflictMarkerTrivia, span: span_from(start, self.position()) }
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
fn Lexer::slash_likely_in_regex_literal(
  self : Lexer,
  slash_offset : Int,
) -> Bool {
  if slash_offset < 0 ||
    slash_offset >= self.source.length() ||
    self.source[slash_offset] != '/' {
    return false
  }
  let mut line_start = slash_offset
  while line_start > 0 {
    let prev = self.source[line_start - 1]
    if is_line_break_code_unit(prev) {
      break
    }
    line_start -= 1
  }
  let mut candidate = slash_offset
  while candidate > line_start {
    candidate -= 1
    if self.source[candidate] != '/' {
      continue
    }
    if candidate + 1 < self.source.length() {
      let next = self.source[candidate + 1]
      if next == '/' || next == '*' {
        continue
      }
    }
    let mut cursor = candidate + 1
    let mut in_escape = false
    let mut in_character_class = false
    let mut reached_target = false
    while cursor < slash_offset {
      let ch = self.source[cursor]
      if is_line_break_code_unit(ch) {
        break
      }
      if in_escape {
        in_escape = false
        cursor += 1
        continue
      }
      if ch == '\\' {
        in_escape = true
        cursor += 1
        continue
      }
      if ch == '[' {
        in_character_class = true
        cursor += 1
        continue
      }
      if ch == ']' {
        in_character_class = false
        cursor += 1
        continue
      }
      if ch == '/' && !in_character_class {
        break
      }
      cursor += 1
    }
    if cursor == slash_offset && in_character_class {
      reached_target = true
    }
    if reached_target {
      return true
    }
  }
  false
}

///|
fn keyword_from_ident(name : String) -> Keyword? {
  match name {
    "let" => Some(Let)
    "const" => Some(Const)
    "var" => Some(Var)
    "function" => Some(Function)
    "return" => Some(Return)
    "if" => Some(If)
    "else" => Some(Else)
    "while" => Some(While)
    "for" => Some(For)
    "do" => Some(Do)
    "switch" => Some(Switch)
    "case" => Some(Case)
    "type" => Some(Type)
    "typeof" => Some(Typeof)
    "interface" => Some(Interface)
    "enum" => Some(Enum)
    "true" => Some(True)
    "false" => Some(False)
    "null" => Some(Null)
    "undefined" => Some(Undefined)
    "this" => Some(This)
    "delete" => Some(Delete)
    "void" => Some(Void)
    "await" => Some(Await)
    "yield" => Some(Yield)
    "new" => Some(New)
    "class" => Some(Class)
    "extends" => Some(Extends)
    "implements" => Some(Implements)
    "export" => Some(Export)
    "import" => Some(Import)
    "from" => Some(From)
    "as" => Some(As)
    "default" => Some(Default)
    "abstract" => Some(Abstract)
    "public" => Some(Public)
    "private" => Some(Private)
    "protected" => Some(Protected)
    "readonly" => Some(Readonly)
    "static" => Some(Static)
    "get" => Some(Get)
    "set" => Some(Set)
    "break" => Some(Break)
    "continue" => Some(Continue)
    "try" => Some(Try)
    "catch" => Some(Catch)
    "finally" => Some(Finally)
    "throw" => Some(Throw)
    _ => None
  }
}

///|
fn keyword_from_raw_ident(name : String) -> Keyword? {
  let decoded = decode_identifier_unicode_escapes_for_keyword(name)
  keyword_from_ident(decoded)
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
        _ => ()
      }
    }
    let input = self.remaining()
    lexmatch input with longest {
      ("[[:space:]]+", rest) => {
        self.consume_prefix(input, rest)
        progressed = true
      }
      ("//[^\n]*", rest) =>
        if self.slash_likely_in_regex_literal(self.pos) {

        } else {
          self.consume_prefix(input, rest)
          progressed = true
        }
      ("/\*", _) => {
        let slash_is_regex = self.pos > 0 &&
          self.source[self.pos - 1] == '\\' &&
          self.backslash_likely_in_regex_literal(self.pos - 1)
        if !slash_is_regex {
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
            raise UnterminatedComment(pos=comment_start)
          }
          progressed = true
        }
      }
      _ => ()
    }
  }
}

///|
fn Lexer::slice_to_string(self : Lexer, start : Int, end_ : Int) -> String {
  self.source.view(start_offset=start, end_offset=end_).to_owned()
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
        raise InvalidChar(pos=escape_pos, '\\')
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
        None => raise UnexpectedEndOfText(pos=self.position())
      }
    } else {
      self.bump()
    }
  }
  self.slice_to_string(content_start, self.pos)
}

///|
priv struct RegexLiteralScanResult {
  pattern_end_offset : Int
  flags_start_offset : Int
  flags_end_offset : Int
  terminated : Bool
}

///|
fn rescan_regex_literal(
  source : StringView,
  slash_offset : Int,
) -> RegexLiteralScanResult {
  let len = source.length()
  let mut cursor = slash_offset + 1
  let mut in_escape = false
  let mut in_character_class = false
  while cursor < len {
    let ch = source[cursor]
    if is_line_break_code_unit(ch) {
      return {
        pattern_end_offset: cursor,
        flags_start_offset: cursor,
        flags_end_offset: cursor,
        terminated: false,
      }
    }
    if in_escape {
      in_escape = false
      cursor += 1
      continue
    }
    if ch == '\\' {
      in_escape = true
      cursor += 1
      continue
    }
    if ch == '[' {
      in_character_class = true
      cursor += 1
      continue
    }
    if ch == ']' {
      in_character_class = false
      cursor += 1
      continue
    }
    if ch == '/' && !in_character_class {
      let pattern_end_offset = cursor
      let flags_start_offset = cursor + 1
      let mut flags_end_offset = flags_start_offset
      if flags_end_offset < len && is_ident_start(source[flags_end_offset]) {
        flags_end_offset += 1
        while flags_end_offset < len && is_ident_part(source[flags_end_offset]) {
          flags_end_offset += 1
        }
      }
      return {
        pattern_end_offset,
        flags_start_offset,
        flags_end_offset,
        terminated: true,
      }
    }
    cursor += 1
  }
  {
    pattern_end_offset: len,
    flags_start_offset: len,
    flags_end_offset: len,
    terminated: false,
  }
}

///|
fn Lexer::next_template_token(self : Lexer) -> Token {
  let chunk_start_pos = self.position()
  let start = self.pos
  while self.peek() is Some(b) {
    if b == '`' {
      let chunk = self.slice_to_string(start, self.pos)
      let chunk_span = span_from(chunk_start_pos, self.position())
      let chunk_token = Token::{ kind: TemplateChunk(chunk), span: chunk_span }
      let end_start = self.position()
      self.bump()
      let end_token = Token::{
        kind: TemplateEnd,
        span: span_from(end_start, self.position()),
      }
      self.pending.push(end_token)
      self.pop_mode()
      return chunk_token
    }
    if b == '$' && self.peek_n(1) == Some('{') {
      let chunk = self.slice_to_string(start, self.pos)
      let chunk_span = span_from(chunk_start_pos, self.position())
      let chunk_token = Token::{ kind: TemplateChunk(chunk), span: chunk_span }
      let expr_start = self.position()
      self.bump()
      self.bump()
      let expr_token = Token::{
        kind: TemplateExprStart,
        span: span_from(expr_start, self.position()),
      }
      self.pending.push(expr_token)
      self.push_mode(TemplateExpr)
      self.template_expr_depth = 0
      return chunk_token
    }
    self.bump()
  }
  let chunk = self.slice_to_string(start, self.pos)
  let chunk_span = span_from(chunk_start_pos, self.position())
  self.pop_mode()
  { kind: TemplateChunk(chunk), span: chunk_span }
}

///|
fn Lexer::next_punct_token(self : Lexer, start : Position) -> Token? {
  let input = self.remaining()
  lexmatch input with longest {
    ("\.\.\.", rest) =>
      Some(self.token_from_match(Ellipsis, start, input, rest))
    ("\?\?", rest) => Some(self.token_from_match(Nullish, start, input, rest))
    ("\?\.", rest) =>
      Some(self.token_from_match(QuestionDot, start, input, rest))
    ("\+\+", rest) => Some(self.token_from_match(PlusPlus, start, input, rest))
    ("\+=", rest) => Some(self.token_from_match(PlusEq, start, input, rest))
    ("\+", rest) => Some(self.token_from_match(Plus, start, input, rest))
    ("--", rest) => Some(self.token_from_match(MinusMinus, start, input, rest))
    ("-=", rest) => Some(self.token_from_match(MinusEq, start, input, rest))
    ("-", rest) => Some(self.token_from_match(Minus, start, input, rest))
    ("\*\*", rest) => Some(self.token_from_match(StarStar, start, input, rest))
    ("\*=", rest) => Some(self.token_from_match(StarEq, start, input, rest))
    ("\*", rest) => Some(self.token_from_match(Star, start, input, rest))
    ("/=", rest) => Some(self.token_from_match(SlashEq, start, input, rest))
    ("/", rest) => Some(self.token_from_match(Slash, start, input, rest))
    ("%=", rest) => Some(self.token_from_match(PercentEq, start, input, rest))
    ("%", rest) => Some(self.token_from_match(Percent, start, input, rest))
    ("===", rest) => Some(self.token_from_match(EqEqEq, start, input, rest))
    ("==", rest) => Some(self.token_from_match(EqEq, start, input, rest))
    ("=>", rest) => Some(self.token_from_match(Arrow, start, input, rest))
    ("=", rest) => Some(self.token_from_match(Eq, start, input, rest))
    ("!==", rest) => Some(self.token_from_match(NotEqEq, start, input, rest))
    ("!=", rest) => Some(self.token_from_match(NotEq, start, input, rest))
    ("!", rest) => Some(self.token_from_match(Bang, start, input, rest))
    ("<=", rest) => Some(self.token_from_match(Lte, start, input, rest))
    ("<", rest) => Some(self.token_from_match(Lt, start, input, rest))
    (">=", rest) => Some(self.token_from_match(Gte, start, input, rest))
    (">", rest) => Some(self.token_from_match(Gt, start, input, rest))
    ("&&", rest) => Some(self.token_from_match(AndAnd, start, input, rest))
    ("&", rest) => Some(self.token_from_match(Ampersand, start, input, rest))
    ("\|\|", rest) => Some(self.token_from_match(OrOr, start, input, rest))
    ("\|", rest) => Some(self.token_from_match(Pipe, start, input, rest))
    ("\(", rest) => Some(self.token_from_match(LParen, start, input, rest))
    ("\)", rest) => Some(self.token_from_match(RParen, start, input, rest))
    ("[{]", rest) => Some(self.token_from_match(LBrace, start, input, rest))
    ("[}]", rest) => Some(self.token_from_match(RBrace, start, input, rest))
    ("\[", rest) => Some(self.token_from_match(LBracket, start, input, rest))
    ("\]", rest) => Some(self.token_from_match(RBracket, start, input, rest))
    (",", rest) => Some(self.token_from_match(Comma, start, input, rest))
    (";", rest) => Some(self.token_from_match(Semicolon, start, input, rest))
    (":", rest) => Some(self.token_from_match(Colon, start, input, rest))
    ("\.", rest) => Some(self.token_from_match(Dot, start, input, rest))
    ("@", rest) => Some(self.token_from_match(At, start, input, rest))
    ("\?", rest) => Some(self.token_from_match(Question, start, input, rest))
    ("~", rest) => Some(self.token_from_match(Tilde, start, input, rest))
    ("\^", rest) => Some(self.token_from_match(Caret, start, input, rest))
    _ => None
  }
}

///|
fn Lexer::next_token(self : Lexer) -> Token raise LexError {
  if self.pending.length() > 0 {
    return self.pending.unsafe_pop()
  }
  if self.mode == Template {
    return self.next_template_token()
  }
  self.skip_ws_and_comments()
  let start = self.position()
  if self.is_conflict_marker_trivia() {
    return self.scan_conflict_marker_trivia_token(start)
  }
  let token = match self.peek() {
    None => Token::{ kind: Eof, span: span_from(start, start) }
    Some(b) =>
      if is_ident_start(b) {
        let name = self.read_ident()
        let end = self.position()
        match keyword_from_raw_ident(name) {
          Some(kw) => { kind: Keyword(kw), span: span_from(start, end) }
          None => { kind: Ident(name), span: span_from(start, end) }
        }
      } else if is_digit(b) {
        let number = self.read_number()
        let end = self.position()
        { kind: Number(number), span: span_from(start, end) }
      } else {
        match b {
          '`' => {
            self.bump()
            self.push_mode(Template)
            { kind: TemplateStart, span: span_from(start, self.position()) }
          }
          '\'' | '"' => {
            self.bump()
            let value = self.read_string(b)
            let end = self.position()
            { kind: String(value), span: span_from(start, end) }
          }
          '\\' => {
            if self.peek_n(1) == Some('u') {
              let saved_pos = self.pos
              let saved_line = self.line
              let saved_column = self.column
              try {
                let ident = self.read_ident()
                let end = self.position()
                match keyword_from_raw_ident(ident) {
                  Some(kw) =>
                    return { kind: Keyword(kw), span: span_from(start, end) }
                  None =>
                    return { kind: Ident(ident), span: span_from(start, end) }
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
              { kind: Ident("\\"), span: span_from(start, self.position()) }
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
              raise InvalidChar(pos=start, '\\')
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
                { kind: PrivateIdent(name), span: span_from(start, end) }
              } catch {
                _ => {
                  self.pos = saved_pos
                  self.line = saved_line
                  self.column = saved_column
                  { kind: Ident("#"), span: span_from(start, self.position()) }
                }
              }
            } else {
              { kind: Ident("#"), span: span_from(start, self.position()) }
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
              {
                kind: Number(self.slice_to_string(start.offset, self.pos)),
                span: span_from(start, self.position()),
              }
            } else {
              match self.next_punct_token(start) {
                Some(token) => token
                None => raise InvalidChar(pos=start, '.')
              }
            }
          other =>
            match self.next_punct_token(start) {
              Some(token) => token
              None => raise InvalidChar(pos=start, other)
            }
        }
      }
  }
  if self.mode == TemplateExpr {
    match token.kind {
      LBrace => self.template_expr_depth += 1
      RBrace =>
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
    if token.kind is Eof {
      break
    }
  }
  tokens
}
