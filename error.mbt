///|
pub(all) suberror ParseError {
  UnexpectedEof(pos~ : Position)
  UnexpectedToken(pos~ : Position, String)
  Expected(pos~ : Position, String)
  InvalidChar(pos~ : Position, Byte)
  UnterminatedString(pos~ : Position)
  UnterminatedComment(pos~ : Position)
  InvalidNumber(pos~ : Position, String)
} derive(Eq, Show, ToJson)
