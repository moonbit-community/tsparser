// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/utilities.ts, src/compiler/scanner.ts, and
// src/services/services.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _node_is_missing(node : Node) -> Bool {
  node.pos() == node.end() && node.pos() >= 0 && node.kind().to_int() != 1
}

///|
fn _node_is_present(node : Node) -> Bool {
  !_node_is_missing(node)
}

///|
fn _assert_real_node_range(node : Node) -> Unit {
  guard node.pos() >= 0 && node.end() >= 0 else {
    abort("node must have a real source position")
  }
}

///|
fn _source_file_text(source_file : Node) -> SourceText {
  guard source_file.kind().to_int() == 308 else {
    abort("expected a SourceFile node")
  }
  match source_file.field("text") {
    Some(Text(Some(text))) => SourceText::new(text)
    _ => abort("SourceFile has no source text")
  }
}

///|
fn _query_source_file(node : Node, source_file : Node?) -> Node {
  let source_file = match source_file {
    Some(source_file) => source_file
    None =>
      match node.source_file() {
        Some(source_file) => source_file
        None => abort("node is not connected to a SourceFile")
      }
  }
  guard source_file.kind().to_int() == 308 else {
    abort("expected a SourceFile node")
  }
  source_file
}

///|
/// Walks parent links to the containing SourceFile. This returns `None` when
/// parent filling was disabled and no SourceFile is reachable.
pub fn Node::source_file(self : Node) -> Node? {
  let mut current = self
  while current.kind().to_int() != 308 {
    match current.parent() {
      Some(parent) => current = parent
      None => return None
    }
  }
  Some(current)
}

///|
/// Returns the parser-owned full start, including leading trivia.
pub fn Node::full_start(self : Node) -> Int {
  _assert_real_node_range(self)
  self.pos()
}

///|
/// Returns `end - pos`, measured in UTF-16 code units.
pub fn Node::full_width(self : Node) -> Int {
  _assert_real_node_range(self)
  self.end() - self.pos()
}

///|
/// Returns the token start after TypeScript trivia skipping.
///
/// An explicit SourceFile permits this query when parent filling is disabled.
/// Missing nodes do not skip forward. JSDoc and JSX text stop before comments,
/// and `include_jsdoc_comment` selects an attached leading JSDoc root.
pub fn Node::start(
  self : Node,
  source_file? : Node,
  include_jsdoc_comment? : Bool = false,
) -> Int {
  _assert_real_node_range(self)
  if _node_is_missing(self) {
    return self.pos()
  }
  let source_file = _query_source_file(self, source_file)
  let source = _source_file_text(source_file)
  let kind = self.kind().to_int()
  if (kind >= 310 && kind <= 352) || kind == 12 {
    return skip_trivia(source, self.pos(), stop_at_comments=true)
  }
  if include_jsdoc_comment {
    match self.jsdoc() {
      Some(documents) =>
        match documents.get(0) {
          Some(document) => return document.start(source_file~)
          None => ()
        }
      None => ()
    }
  }
  if kind == 353 {
    match self.first_child() {
      Some(child) => return child.start(source_file~, include_jsdoc_comment~)
      None => ()
    }
  }
  skip_trivia(
    source,
    self.pos(),
    in_jsdoc=self.flags().contains(NodeFlags::jsdoc()),
  )
}

///|
/// Returns `end - start`, measured in UTF-16 code units.
pub fn Node::width(self : Node, source_file? : Node) -> Int {
  _assert_real_node_range(self)
  let start = match source_file {
    Some(source_file) => self.start(source_file~)
    None => self.start()
  }
  self.end() - start
}

///|
/// Returns the UTF-16 width of leading trivia.
pub fn Node::leading_trivia_width(self : Node, source_file? : Node) -> Int {
  _assert_real_node_range(self)
  let start = match source_file {
    Some(source_file) => self.start(source_file~)
    None => self.start()
  }
  start - self.pos()
}

///|
/// Returns source text from `pos` through `end`, including trivia.
pub fn Node::full_text(self : Node, source_file? : Node) -> String {
  _assert_real_node_range(self)
  let source_file = _query_source_file(self, source_file)
  _source_file_text(source_file).substring(self.pos(), end=self.end())
}

///|
/// Returns source text from token start through `end`.
pub fn Node::text(self : Node, source_file? : Node) -> String {
  _assert_real_node_range(self)
  let source_file = _query_source_file(self, source_file)
  let source = _source_file_text(source_file)
  source.substring(self.start(source_file~), end=self.end())
}

///|
/// Returns the first direct semantic child in `for_each_child` order.
pub fn Node::first_child(self : Node) -> Node? {
  for_each_child(self, child => Some(child))
}

///|
/// Returns the last present direct semantic child in `for_each_child` order.
/// Zero-width missing nodes are ignored, as in TypeScript's utility helper.
pub fn Node::last_child(self : Node) -> Node? {
  let mut last : Node? = None
  let result : Unit? = for_each_child(self, fn(child) {
    if _node_is_present(child) {
      last = Some(child)
    }
    None
  })
  ignore(result)
  last
}

///|
/// Counts direct semantic children, flattening NodeArray boundaries exactly as
/// `for_each_child` does when no list callback is supplied.
pub fn Node::child_count(self : Node) -> Int {
  let mut count = 0
  let result : Unit? = for_each_child(self, fn(_) {
    count += 1
    None
  })
  ignore(result)
  count
}

///|
fn _is_token_kind(node : Node) -> Bool {
  node.kind().to_int() < 167
}

///|
/// Finds the first parser-owned token descendant in semantic preorder.
/// Scanner-synthesized punctuation is intentionally not invented here.
pub fn Node::first_token(self : Node) -> Node? {
  for_each_child_recursively(self, fn(child, _) {
    if _is_jsdoc_node(child) {
      TraversalControl::skip()
    } else if _is_token_kind(child) {
      TraversalControl::stop(child)
    } else {
      TraversalControl::proceed()
    }
  })
}

///|
/// Finds the last parser-owned token descendant in semantic preorder.
/// Scanner-synthesized punctuation is intentionally not invented here.
pub fn Node::last_token(self : Node) -> Node? {
  let mut last : Node? = None
  let result : Unit? = for_each_child_recursively(self, fn(child, _) {
    if _is_token_kind(child) {
      last = Some(child)
      TraversalControl::skip()
    } else {
      TraversalControl::proceed()
    }
  })
  ignore(result)
  last
}

///|
/// Returns immutable UTF-16 line starts for a SourceFile.
pub fn Node::line_starts(self : Node) -> ReadOnlyArray[Int] {
  LineMap::new(_source_file_text(self)).starts()
}

///|
/// Converts a SourceFile UTF-16 offset to zero-based line and character.
pub fn Node::line_and_character_of_position(
  self : Node,
  position : Int,
) -> LineAndCharacter {
  LineMap::new(_source_file_text(self)).line_and_character_of_position(position)
}

///|
/// Converts a zero-based line/character pair to a SourceFile UTF-16 offset.
pub fn Node::position_of_line_and_character(
  self : Node,
  line : Int,
  character : Int,
  allow_edits? : Bool = false,
) -> Int {
  LineMap::new(_source_file_text(self)).position_of_line_and_character(
    line,
    character,
    allow_edits~,
  )
}
