// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/factory/baseNodeFactory.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// A typed value stored in a kind-specific syntax-node field.
///
/// Optional upstream properties retain their `undefined`/present distinction
/// inside the corresponding option. Node and NodeArray values retain their
/// original identities; this representation never copies or lowers the AST.
pub enum NodeFieldValue {
  Undefined
  NodeRef(Node?)
  NodeList(NodeArray?)
  Text(String?)
  Boolean(Bool?)
  Integer(Int?)
  Unsigned(UInt?)
  Kind(SyntaxKind?)
  TokenFlagSet(TokenFlags)
  NodeFlagSet(NodeFlags)
  TransformFlagSet(TransformFlags)
  ExternalModuleIndicatorValue(ExternalModuleIndicator?)
  TextList(ReadOnlyArray[String]?)
  IntegerList(ReadOnlyArray[Int]?)
  DiagnosticList(ReadOnlyArray[Diagnostic]?)
  CommentDirectiveList(ReadOnlyArray[CommentDirective]?)
  PragmaMapValue(ReadOnlyArray[PragmaEntry]?)
  CheckJsDirectiveValue(CheckJsDirective?)
  FileReferenceList(ReadOnlyArray[FileReference]?)
  AmdDependencyList(ReadOnlyArray[AmdDependency]?)
}

///|
/// Keeps the complete field-value surface checked while the 195 factory
/// entries are being ported. The suppression is scoped to this staging hook.
#warnings("-unused_value")
fn _node_field_value_contract_values() -> ReadOnlyArray[NodeFieldValue] {
  ReadOnlyArray::from_array([
    Undefined,
    NodeRef(None),
    NodeList(None),
    Text(None),
    Boolean(None),
    Integer(None),
    Unsigned(None),
    Kind(None),
    TokenFlagSet(TokenFlags::from_bits(0U)),
    NodeFlagSet(NodeFlags::none()),
    TransformFlagSet(TransformFlags::none()),
    ExternalModuleIndicatorValue(None),
    TextList(None),
    IntegerList(None),
    DiagnosticList(None),
    CommentDirectiveList(None),
    PragmaMapValue(None),
    CheckJsDirectiveValue(None),
    FileReferenceList(None),
    AmdDependencyList(None),
  ])
}

///|
/// One parser-visible property on a syntax node. The property name is the
/// exact TypeScript spelling used by the field reference.
pub struct NodeField {
  name : String
  value : NodeFieldValue
}

///|
pub fn NodeField::name(self : NodeField) -> String {
  self.name
}

///|
pub fn NodeField::value(self : NodeField) -> NodeFieldValue {
  self.value
}

///|
fn _node_field(name : String, value : NodeFieldValue) -> NodeField {
  { name, value }
}

///|
fn _node_ref_field(name : String, value : Node?) -> NodeField {
  _node_field(name, NodeRef(value))
}

///|
fn _undefined_field(name : String) -> NodeField {
  _node_field(name, Undefined)
}

///|
fn _node_list_field(name : String, value : NodeArray?) -> NodeField {
  _node_field(name, NodeList(value))
}

///|
fn _text_field(name : String, value : String?) -> NodeField {
  _node_field(name, Text(value))
}

///|
fn _boolean_field(name : String, value : Bool?) -> NodeField {
  _node_field(name, Boolean(value))
}

///|
fn _integer_field(name : String, value : Int?) -> NodeField {
  _node_field(name, Integer(value))
}

///|
fn _kind_field(name : String, value : SyntaxKind?) -> NodeField {
  _node_field(name, Kind(value))
}

///|
fn _token_flags_field(name : String, value : TokenFlags) -> NodeField {
  _node_field(name, TokenFlagSet(value))
}

///|
fn _external_module_indicator_field(
  name : String,
  value : ExternalModuleIndicator?,
) -> NodeField {
  _node_field(name, ExternalModuleIndicatorValue(value))
}

///|
/// The kind-specific data owned by a syntax node.
///
/// `Children` is retained only for the stage-1 representation probe. Parser
/// nodes use `Fields`; emit-only and transform-only kinds have no public
/// constructor and therefore cannot acquire an invented payload.
pub enum NodePayload {
  Empty
  Children(NodeArray)
  Fields(ReadOnlyArray[NodeField])
}

///|
/// A stable reference to a parser node. Public fields are read-only outside the
/// package. The parser and private factory can finish ranges, flags, payload,
/// and parent links during construction.
///
/// `Node` deliberately has no structural `Eq`, `Show`, or recursive `Debug`
/// implementation because parent links form cycles.
pub struct Node {
  kind : SyntaxKind
  mut pos : Int
  mut end : Int
  mut flags : NodeFlags
  mut transform_flags : TransformFlags
  mut parent : Node?
  mut jsdoc : NodeArray?
  mut payload : NodePayload
}

///|
fn _make_node(
  kind : SyntaxKind,
  pos : Int,
  end : Int,
  flags : NodeFlags,
  transform_flags : TransformFlags,
  children : NodeArray?,
) -> Node {
  let payload = match children {
    Some(children) => Children(children)
    None => Empty
  }
  { kind, pos, end, flags, transform_flags, parent: None, jsdoc: None, payload }
}

///|
/// Allocates an unfinished parser node. TypeScript's parser-specific base
/// factory initializes fresh nodes at `0..0` before `finish_node` assigns the
/// actual range (its public synthetic factory instead uses `-1..-1`).
fn _make_fields_node(
  kind : SyntaxKind,
  fields : Array[NodeField],
  transform_flags? : TransformFlags = TransformFlags::none(),
) -> Node {
  {
    kind,
    pos: 0,
    end: 0,
    flags: NodeFlags::none(),
    transform_flags,
    parent: None,
    jsdoc: None,
    payload: Fields(ReadOnlyArray::from_array(fields)),
  }
}

///|
fn Node::_set_parent(self : Node, parent : Node?) -> Unit {
  self.parent = parent
}

///|
fn Node::_set_text_range(self : Node, pos : Int, end : Int) -> Unit {
  self.pos = pos
  self.end = end
}

///|
fn Node::_set_flags(self : Node, flags : NodeFlags) -> Unit {
  self.flags = flags
}

///|
fn Node::_add_flags(self : Node, flags : NodeFlags) -> Unit {
  self.flags = self.flags.union(flags)
}

///|
fn Node::_set_transform_flags(self : Node, flags : TransformFlags) -> Unit {
  self.transform_flags = flags
}

///|
fn Node::_add_transform_flags(self : Node, flags : TransformFlags) -> Unit {
  self.transform_flags = self.transform_flags.union(flags)
}

///|
fn Node::_set_fields(self : Node, fields : Array[NodeField]) -> Unit {
  self.payload = Fields(ReadOnlyArray::from_array(fields))
}

///|
fn Node::_set_jsdoc(self : Node, jsdoc : NodeArray?) -> Unit {
  self.jsdoc = jsdoc
}

///|
pub fn Node::kind(self : Node) -> SyntaxKind {
  self.kind
}

///|
pub fn Node::pos(self : Node) -> Int {
  self.pos
}

///|
pub fn Node::end(self : Node) -> Int {
  self.end
}

///|
pub fn Node::flags(self : Node) -> NodeFlags {
  self.flags
}

///|
pub fn Node::transform_flags(self : Node) -> TransformFlags {
  self.transform_flags
}

///|
pub fn Node::parent(self : Node) -> Node? {
  self.parent
}

///|
/// JSDoc attached directly to this host. As in TypeScript, this is traversed by
/// the dedicated JSDoc parent path rather than ordinary `for_each_child`.
pub fn Node::jsdoc(self : Node) -> NodeArray? {
  self.jsdoc
}

///|
/// Returns the immutable kind-specific field list, or an empty list for a bare
/// token and for the old representation probe.
pub fn Node::fields(self : Node) -> ReadOnlyArray[NodeField] {
  match self.payload {
    Fields(fields) => fields
    Empty | Children(_) => ReadOnlyArray::from_array([])
  }
}

///|
/// Looks up a parser-visible property by its exact TypeScript field name.
pub fn Node::field(self : Node, name : String) -> NodeFieldValue? {
  match self.payload {
    Fields(fields) => {
      for field in fields {
        if field.name() == name {
          return Some(field.value())
        }
      }
      None
    }
    Empty | Children(_) => None
  }
}

///|
/// A flattened child view in the normative `for_each_child` source order.
/// The old `Children` payload remains available only to the stage-1
/// representation probe.
pub fn Node::children(self : Node) -> NodeArray? {
  match self.payload {
    Empty => None
    Children(children) => Some(children)
    Fields(_) => {
      let children : Array[Node] = []
      let result : Unit? = for_each_child(self, fn(child) {
        children.push(child)
        None
      })
      ignore(result)
      if children.length() == 0 {
        None
      } else {
        Some(
          _make_node_array(
            children,
            self.pos,
            self.end,
            false,
            TransformFlags::none(),
          ),
        )
      }
    }
  }
}

///|
/// Tests whether two references designate the same syntax node.
pub fn Node::same_identity(self : Node, other : Node) -> Bool {
  physical_equal(self, other)
}

///|
fn _count_nodes_iterative(root : Node) -> Int {
  let stack = [root]
  let mut count = 0
  while stack.length() > 0 {
    match stack.pop() {
      Some(node) => {
        count += 1
        match node.children() {
          Some(children) =>
            for child in children.elements() {
              stack.push(child)
            }
          None => ()
        }
      }
      None => ()
    }
  }
  count
}
