///|
fn token_spans_are_adjacent(left : Token, right : Token) -> Bool {
  left.span.end.offset == right.span.start.offset
}

///|
fn token_at(tokens : Array[Token], index : Int) -> Token? {
  if index >= 0 && index < tokens.length() {
    Some(tokens[index])
  } else {
    None
  }
}

///|
priv enum LessThanRescanKind {
  Lt
  Lte
  Shl
  ShlAssign
} derive(Eq)

///|
priv struct LessThanRescan {
  kind : LessThanRescanKind
  width : Int
}

///|
fn rescan_less_than_token(tokens : Array[Token], index : Int) -> LessThanRescan {
  match token_at(tokens, index) {
    Some(current) =>
      match current.kind {
        Lte => { kind: Lte, width: 1 }
        Lt =>
          match token_at(tokens, index + 1) {
            Some(next) =>
              if !token_spans_are_adjacent(current, next) {
                { kind: Lt, width: 1 }
              } else {
                match next.kind {
                  Lte => { kind: ShlAssign, width: 2 }
                  Lt =>
                    match token_at(tokens, index + 2) {
                      Some(third) =>
                        if token_spans_are_adjacent(next, third) &&
                          third.kind == Eq {
                          { kind: ShlAssign, width: 3 }
                        } else {
                          { kind: Shl, width: 2 }
                        }
                      None => { kind: Shl, width: 2 }
                    }
                  _ => { kind: Lt, width: 1 }
                }
              }
            None => { kind: Lt, width: 1 }
          }
        _ => { kind: Lt, width: 1 }
      }
    None => { kind: Lt, width: 1 }
  }
}

///|
priv enum GreaterThanRescanKind {
  Gt
  Gte
  Shr
  ShrAssign
  UShr
  UShrAssign
} derive(Eq)

///|
priv struct GreaterThanRescan {
  kind : GreaterThanRescanKind
  width : Int
}

///|
fn rescan_greater_than_token(
  tokens : Array[Token],
  index : Int,
) -> GreaterThanRescan {
  match token_at(tokens, index) {
    Some(current) =>
      match current.kind {
        Gte => { kind: Gte, width: 1 }
        Gt =>
          match token_at(tokens, index + 1) {
            Some(next) =>
              if !token_spans_are_adjacent(current, next) {
                { kind: Gt, width: 1 }
              } else {
                match next.kind {
                  Gte => { kind: ShrAssign, width: 2 }
                  Gt =>
                    match token_at(tokens, index + 2) {
                      Some(third) =>
                        if !token_spans_are_adjacent(next, third) {
                          { kind: Shr, width: 2 }
                        } else {
                          match third.kind {
                            Gte => { kind: UShrAssign, width: 3 }
                            Gt =>
                              match token_at(tokens, index + 3) {
                                Some(fourth) =>
                                  if token_spans_are_adjacent(third, fourth) &&
                                    fourth.kind == Eq {
                                    { kind: UShrAssign, width: 4 }
                                  } else {
                                    { kind: UShr, width: 3 }
                                  }
                                None => { kind: UShr, width: 3 }
                              }
                            Eq => { kind: ShrAssign, width: 3 }
                            _ => { kind: Shr, width: 2 }
                          }
                        }
                      None => { kind: Shr, width: 2 }
                    }
                  _ => { kind: Gt, width: 1 }
                }
              }
            None => { kind: Gt, width: 1 }
          }
        _ => { kind: Gt, width: 1 }
      }
    None => { kind: Gt, width: 1 }
  }
}

///|
priv enum QuestionRescanKind {
  Question
  QuestionDot
  Nullish
  NullishAssign
} derive(Eq)

///|
priv struct QuestionRescan {
  kind : QuestionRescanKind
  width : Int
}

///|
fn rescan_question_token(tokens : Array[Token], index : Int) -> QuestionRescan {
  match token_at(tokens, index) {
    Some(current) =>
      match current.kind {
        Question => { kind: Question, width: 1 }
        QuestionDot => { kind: QuestionDot, width: 1 }
        Nullish =>
          match token_at(tokens, index + 1) {
            Some(next) =>
              if token_spans_are_adjacent(current, next) && next.kind == Eq {
                { kind: NullishAssign, width: 2 }
              } else {
                { kind: Nullish, width: 1 }
              }
            None => { kind: Nullish, width: 1 }
          }
        _ => { kind: Question, width: 1 }
      }
    None => { kind: Question, width: 1 }
  }
}

///|
priv enum HashRescanKind {
  Hash
  PrivateIdent
} derive(Eq)

///|
priv struct HashRescan {
  kind : HashRescanKind
  name : String?
}

///|
fn rescan_hash_token(tokens : Array[Token], index : Int) -> HashRescan {
  match token_at(tokens, index) {
    Some(current) =>
      match current.kind {
        PrivateIdent(name) => { kind: PrivateIdent, name: Some(name) }
        Ident("#") => { kind: Hash, name: None }
        _ => { kind: Hash, name: None }
      }
    None => { kind: Hash, name: None }
  }
}

///|
priv struct SlashRescan {
  pattern_start_offset : Int
  pattern_end_offset : Int
  flags_start_offset : Int
  flags_end_offset : Int
  scan_end_offset : Int
  terminated : Bool
}

///|
fn rescan_slash_token(
  source : StringView,
  tokens : Array[Token],
  index : Int,
) -> SlashRescan {
  match token_at(tokens, index) {
    Some(current) =>
      match current.kind {
        Slash | SlashEq => {
          let regex_scan = rescan_regex_literal(
            source,
            current.span.start.offset,
          )
          let scan_end_offset = if regex_scan.terminated {
            regex_scan.flags_end_offset
          } else {
            regex_scan.pattern_end_offset
          }
          {
            pattern_start_offset: current.span.start.offset + 1,
            pattern_end_offset: regex_scan.pattern_end_offset,
            flags_start_offset: regex_scan.flags_start_offset,
            flags_end_offset: regex_scan.flags_end_offset,
            scan_end_offset,
            terminated: regex_scan.terminated,
          }
        }
        _ => {
          let fallback_start = current.span.start.offset
          {
            pattern_start_offset: fallback_start,
            pattern_end_offset: fallback_start,
            flags_start_offset: fallback_start,
            flags_end_offset: fallback_start,
            scan_end_offset: fallback_start,
            terminated: false,
          }
        }
      }
    None =>
      {
        pattern_start_offset: 0,
        pattern_end_offset: 0,
        flags_start_offset: 0,
        flags_end_offset: 0,
        scan_end_offset: 0,
        terminated: false,
      }
  }
}

///|
priv enum TemplateRescanKind {
  NoSubstitution
  Head
  Middle
  Tail
} derive(Eq)

///|
priv struct TemplateRescan {
  kind : TemplateRescanKind
  chunk : String
  chunk_span : Span
  end_span : Span
  width : Int
  terminated : Bool
}

///|
fn rescan_template_token(
  tokens : Array[Token],
  index : Int,
  is_head : Bool,
) -> TemplateRescan {
  let fallback_span = match token_at(tokens, index) {
    Some(token) => token.span
    None => {
      let pos = Position::{ offset: 0, line: 1, column: 1 }
      span_from(pos, pos)
    }
  }
  let fallback_kind = if is_head {
    TemplateRescanKind::NoSubstitution
  } else {
    Tail
  }
  match token_at(tokens, index) {
    Some(current) =>
      match current.kind {
        TemplateChunk(chunk) =>
          match token_at(tokens, index + 1) {
            Some(next) =>
              if token_spans_are_adjacent(current, next) {
                match next.kind {
                  TemplateExprStart =>
                    {
                      kind: if is_head {
                        Head
                      } else {
                        Middle
                      },
                      chunk,
                      chunk_span: current.span,
                      end_span: next.span,
                      width: 2,
                      terminated: true,
                    }
                  TemplateEnd =>
                    {
                      kind: if is_head {
                        NoSubstitution
                      } else {
                        Tail
                      },
                      chunk,
                      chunk_span: current.span,
                      end_span: next.span,
                      width: 2,
                      terminated: true,
                    }
                  _ =>
                    {
                      kind: fallback_kind,
                      chunk,
                      chunk_span: current.span,
                      end_span: current.span,
                      width: 1,
                      terminated: false,
                    }
                }
              } else {
                {
                  kind: fallback_kind,
                  chunk,
                  chunk_span: current.span,
                  end_span: current.span,
                  width: 1,
                  terminated: false,
                }
              }
            None =>
              {
                kind: fallback_kind,
                chunk,
                chunk_span: current.span,
                end_span: current.span,
                width: 1,
                terminated: false,
              }
          }
        _ =>
          {
            kind: fallback_kind,
            chunk: "",
            chunk_span: current.span,
            end_span: current.span,
            width: 0,
            terminated: false,
          }
      }
    None =>
      {
        kind: fallback_kind,
        chunk: "",
        chunk_span: fallback_span,
        end_span: fallback_span,
        width: 0,
        terminated: false,
      }
  }
}
