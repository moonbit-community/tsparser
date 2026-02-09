///|
pub(all) suberror LexError {
  InvalidChar(pos~ : Position, UInt16)
  UnterminatedString(pos~ : Position)
  UnterminatedComment(pos~ : Position)
  InvalidNumber(pos~ : Position, String)
} derive(Eq, Show, ToJson)

///|
pub(all) suberror ParseError {
  LexErr(LexError)
  UnexpectedEof(pos~ : Position)
  UnexpectedToken(pos~ : Position, String)
  Expected(pos~ : Position, String)
} derive(Eq, Show, ToJson)
