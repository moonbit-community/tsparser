///|
pub(all) suberror LexError {
  InvalidChar(pos~ : Position, UInt16)
  UnterminatedString(pos~ : Position)
  UnexpectedEndOfText(pos~ : Position)
  UnterminatedComment(pos~ : Position)
  InvalidNumber(pos~ : Position, String)
} derive(Eq, Debug)

///|
pub(all) suberror ParseError {
  LexErr(LexError)
  UnexpectedEof(pos~ : Position)
  UnexpectedToken(pos~ : Position, String)
  Expected(pos~ : Position, String)
  Diagnostic(
    filename~ : String,
    line~ : Int,
    column~ : Int,
    error_code~ : Int,
    error_msg~ : String
  )
} derive(Eq, Debug)

///|
fn parse_error_to_string(err : ParseError) -> String {
  match err {
    ParseError::LexErr(inner) => "LexErr(\{@debug.to_string(inner)})"
    ParseError::UnexpectedEof(pos~) =>
      "UnexpectedEof(pos=\{@debug.to_string(pos)})"
    ParseError::UnexpectedToken(pos~, found) =>
      "UnexpectedToken(pos=\{@debug.to_string(pos)}, \{found.escape()})"
    ParseError::Expected(pos~, expected) =>
      "Expected(pos=\{@debug.to_string(pos)}, \{expected.escape()})"
    ParseError::Diagnostic(filename~, line~, column~, error_code~, error_msg~) =>
      "\{filename}(\{line},\{column}): error TS\{error_code}: \{error_msg}"
  }
}

///|
pub impl Show for ParseError with output(self, logger) {
  logger.write_string(parse_error_to_string(self))
}
