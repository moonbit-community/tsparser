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
        TokenKind::Lte => { kind: LessThanRescanKind::Lte, width: 1 }
        TokenKind::Lt =>
          match token_at(tokens, index + 1) {
            Some(next) =>
              if !token_spans_are_adjacent(current, next) {
                { kind: LessThanRescanKind::Lt, width: 1 }
              } else {
                match next.kind {
                  TokenKind::Lte =>
                    { kind: LessThanRescanKind::ShlAssign, width: 2 }
                  TokenKind::Lt =>
                    match token_at(tokens, index + 2) {
                      Some(third) =>
                        if token_spans_are_adjacent(next, third) &&
                          third.kind == TokenKind::Eq {
                          { kind: LessThanRescanKind::ShlAssign, width: 3 }
                        } else {
                          { kind: LessThanRescanKind::Shl, width: 2 }
                        }
                      None => { kind: LessThanRescanKind::Shl, width: 2 }
                    }
                  _ => { kind: LessThanRescanKind::Lt, width: 1 }
                }
              }
            None => { kind: LessThanRescanKind::Lt, width: 1 }
          }
        _ => { kind: LessThanRescanKind::Lt, width: 1 }
      }
    None => { kind: LessThanRescanKind::Lt, width: 1 }
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
        TokenKind::Gte => { kind: GreaterThanRescanKind::Gte, width: 1 }
        TokenKind::Gt =>
          match token_at(tokens, index + 1) {
            Some(next) =>
              if !token_spans_are_adjacent(current, next) {
                { kind: GreaterThanRescanKind::Gt, width: 1 }
              } else {
                match next.kind {
                  TokenKind::Gte =>
                    { kind: GreaterThanRescanKind::ShrAssign, width: 2 }
                  TokenKind::Gt =>
                    match token_at(tokens, index + 2) {
                      Some(third) =>
                        if !token_spans_are_adjacent(next, third) {
                          { kind: GreaterThanRescanKind::Shr, width: 2 }
                        } else {
                          match third.kind {
                            TokenKind::Gte =>
                              {
                                kind: GreaterThanRescanKind::UShrAssign,
                                width: 3,
                              }
                            TokenKind::Gt =>
                              match token_at(tokens, index + 3) {
                                Some(fourth) =>
                                  if token_spans_are_adjacent(third, fourth) &&
                                    fourth.kind == TokenKind::Eq {
                                    {
                                      kind: GreaterThanRescanKind::UShrAssign,
                                      width: 4,
                                    }
                                  } else {
                                    {
                                      kind: GreaterThanRescanKind::UShr,
                                      width: 3,
                                    }
                                  }
                                None =>
                                  {
                                    kind: GreaterThanRescanKind::UShr,
                                    width: 3,
                                  }
                              }
                            TokenKind::Eq =>
                              {
                                kind: GreaterThanRescanKind::ShrAssign,
                                width: 3,
                              }
                            _ => { kind: GreaterThanRescanKind::Shr, width: 2 }
                          }
                        }
                      None => { kind: GreaterThanRescanKind::Shr, width: 2 }
                    }
                  _ => { kind: GreaterThanRescanKind::Gt, width: 1 }
                }
              }
            None => { kind: GreaterThanRescanKind::Gt, width: 1 }
          }
        _ => { kind: GreaterThanRescanKind::Gt, width: 1 }
      }
    None => { kind: GreaterThanRescanKind::Gt, width: 1 }
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
        TokenKind::Question => { kind: QuestionRescanKind::Question, width: 1 }
        TokenKind::QuestionDot =>
          { kind: QuestionRescanKind::QuestionDot, width: 1 }
        TokenKind::Nullish =>
          match token_at(tokens, index + 1) {
            Some(next) =>
              if token_spans_are_adjacent(current, next) &&
                next.kind == TokenKind::Eq {
                { kind: QuestionRescanKind::NullishAssign, width: 2 }
              } else {
                { kind: QuestionRescanKind::Nullish, width: 1 }
              }
            None => { kind: QuestionRescanKind::Nullish, width: 1 }
          }
        _ => { kind: QuestionRescanKind::Question, width: 1 }
      }
    None => { kind: QuestionRescanKind::Question, width: 1 }
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
        TokenKind::PrivateIdent(name) =>
          { kind: HashRescanKind::PrivateIdent, name: Some(name) }
        TokenKind::Ident("#") => { kind: HashRescanKind::Hash, name: None }
        _ => { kind: HashRescanKind::Hash, name: None }
      }
    None => { kind: HashRescanKind::Hash, name: None }
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
        TokenKind::Slash | TokenKind::SlashEq => {
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
    TemplateRescanKind::Tail
  }
  match token_at(tokens, index) {
    Some(current) =>
      match current.kind {
        TokenKind::TemplateChunk(chunk) =>
          match token_at(tokens, index + 1) {
            Some(next) =>
              if token_spans_are_adjacent(current, next) {
                match next.kind {
                  TokenKind::TemplateExprStart =>
                    {
                      kind: if is_head {
                        TemplateRescanKind::Head
                      } else {
                        TemplateRescanKind::Middle
                      },
                      chunk,
                      chunk_span: current.span,
                      end_span: next.span,
                      width: 2,
                      terminated: true,
                    }
                  TokenKind::TemplateEnd =>
                    {
                      kind: if is_head {
                        TemplateRescanKind::NoSubstitution
                      } else {
                        TemplateRescanKind::Tail
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
