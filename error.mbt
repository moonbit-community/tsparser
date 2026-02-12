///|
pub(all) suberror LexError {
  InvalidChar(pos~ : Position, UInt16)
  UnterminatedString(pos~ : Position)
  UnexpectedEndOfText(pos~ : Position)
  UnterminatedComment(pos~ : Position)
  InvalidNumber(pos~ : Position, String)
} derive(Eq, Show, ToJson)

///|
pub(all) suberror ParseError {
  LexErr(LexError)
  UnexpectedEof(pos~ : Position)
  UnexpectedToken(pos~ : Position, String)
  Expected(pos~ : Position, String)
  Diagnostic(String)
} derive(Eq, ToJson)

///|
fn parse_error_to_string(err : ParseError) -> String {
  match err {
    ParseError::LexErr(inner) => "LexErr(\{inner.to_string()})"
    ParseError::UnexpectedEof(pos~) => "UnexpectedEof(pos=\{pos})"
    ParseError::UnexpectedToken(pos~, found) =>
      "UnexpectedToken(pos=\{pos}, \{found.escape()})"
    ParseError::Expected(pos~, expected) =>
      "Expected(pos=\{pos}, \{expected.escape()})"
    ParseError::Diagnostic(text) => text
  }
}

///|
pub impl Show for ParseError with output(self, logger) {
  logger.write_string(parse_error_to_string(self))
}

///|
pub impl Show for ParseError with to_string(self) {
  parse_error_to_string(self)
}
