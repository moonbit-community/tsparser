// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/factory/nodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// An immutable TypeScript node list with parser-owned range and flag metadata.
/// The element storage is copied into a `ReadOnlyArray`; parser construction
/// may finish only the metadata and never exposes a mutable element handle.
pub struct NodeArray {
  elements : ReadOnlyArray[Node]
  mut pos : Int
  mut end : Int
  mut has_trailing_comma : Bool
  mut transform_flags : TransformFlags
}

///|
fn _make_node_array(
  elements : Array[Node],
  pos : Int,
  end : Int,
  has_trailing_comma : Bool,
  transform_flags : TransformFlags,
) -> NodeArray {
  {
    elements: ReadOnlyArray::from_array(elements),
    pos,
    end,
    has_trailing_comma,
    transform_flags,
  }
}

///|
fn NodeArray::_set_text_range(self : NodeArray, pos : Int, end : Int) -> Unit {
  self.pos = pos
  self.end = end
}

///|
fn NodeArray::_set_has_trailing_comma(
  self : NodeArray,
  has_trailing_comma : Bool,
) -> Unit {
  self.has_trailing_comma = has_trailing_comma
}

///|
fn NodeArray::_set_transform_flags(
  self : NodeArray,
  transform_flags : TransformFlags,
) -> Unit {
  self.transform_flags = transform_flags
}

///|
pub fn NodeArray::elements(self : NodeArray) -> ReadOnlyArray[Node] {
  self.elements
}

///|
pub fn NodeArray::length(self : NodeArray) -> Int {
  self.elements.length()
}

///|
pub fn NodeArray::get(self : NodeArray, index : Int) -> Node? {
  self.elements.get(index)
}

///|
pub fn NodeArray::pos(self : NodeArray) -> Int {
  self.pos
}

///|
pub fn NodeArray::end(self : NodeArray) -> Int {
  self.end
}

///|
pub fn NodeArray::has_trailing_comma(self : NodeArray) -> Bool {
  self.has_trailing_comma
}

///|
pub fn NodeArray::transform_flags(self : NodeArray) -> TransformFlags {
  self.transform_flags
}

///|
pub fn NodeArray::same_identity(self : NodeArray, other : NodeArray) -> Bool {
  physical_equal(self, other)
}
