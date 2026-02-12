///|
pub struct Position {
  offset : Int
  line : Int
  column : Int
} derive(Eq, Debug)

///|
pub struct Span {
  start : Position
  end : Position
} derive(Eq, Debug)

///|
fn span_from(start : Position, end : Position) -> Span {
  { start, end }
}

///|
pub fn Span::merge(self : Span, other : Span) -> Span {
  { start: self.start, end: other.end }
}
