// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
priv struct NodeFinishState {
  mut context_flags : NodeFlags
  mut parse_error_before_next_finished_node : Bool
}

///|
fn _new_node_finish_state() -> NodeFinishState {
  {
    context_flags: NodeFlags::none(),
    parse_error_before_next_finished_node: false,
  }
}

///|
fn NodeFinishState::_set_context_flags(
  self : NodeFinishState,
  flags : NodeFlags,
) -> Unit {
  self.context_flags = flags
}

///|
fn NodeFinishState::_mark_parse_error(self : NodeFinishState) -> Unit {
  self.parse_error_before_next_finished_node = true
}

///|
fn NodeFinishState::_has_pending_parse_error(self : NodeFinishState) -> Bool {
  self.parse_error_before_next_finished_node
}

///|
fn _finish_node(
  state : NodeFinishState,
  node : Node,
  pos : Int,
  end : Int,
) -> Node {
  node._set_text_range(pos, end)
  if state.context_flags.bits() != 0U {
    node._add_flags(state.context_flags)
  }
  if state.parse_error_before_next_finished_node {
    state.parse_error_before_next_finished_node = false
    node._add_flags(NodeFlags::this_node_has_error())
  }
  node
}

///|
fn _finish_node_array(array : NodeArray, pos : Int, end : Int) -> NodeArray {
  array._set_text_range(pos, end)
  array
}

///|
fn _create_missing_node(
  state : NodeFinishState,
  kind : SyntaxKind,
  position : Int,
) -> Node {
  let result = match kind.to_int() {
    80 => _factory_create_identifier("")
    9 => _factory_create_numeric_literal("")
    11 => _factory_create_string_literal("")
    15 | 16 | 17 | 18 =>
      _factory_create_template_literal_like_node(kind, "", raw_text="")
    283 => _factory_create_missing_declaration()
    _ => _factory_create_token(kind)
  }
  _finish_node(state, result, position, position)
}

///|
/// Whether the parser can construct a real parse-tree payload for this kind.
/// Bundle and the emit/transform-only synthetic tail remain deliberately
/// unconstructable even though their numeric SyntaxKind values are preserved.
pub fn SyntaxKind::is_parser_constructable(self : SyntaxKind) -> Bool {
  let value = self.to_int()
  value >= 0 &&
  value <= 352 &&
  !(value >= 2 && value <= 8) &&
  value != 303 &&
  value != 309
}
