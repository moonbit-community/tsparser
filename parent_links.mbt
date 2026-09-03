// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/utilities.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
fn _is_jsdoc_node(node : Node) -> Bool {
  let kind = node.kind().to_int()
  kind >= 310 && kind <= 352
}

///|
fn _parent_is(node : Node, expected : Node) -> Bool {
  match node.parent() {
    Some(parent) => parent.same_identity(expected)
    None => false
  }
}

///|
fn _bind_jsdoc_descendants(root : Node, incremental : Bool) -> Unit {
  let result : Unit? = for_each_child_recursively(root, fn(child, parent) {
    if incremental && _parent_is(child, parent) {
      TraversalControl::skip()
    } else {
      child._set_parent(Some(parent))
      TraversalControl::proceed()
    }
  })
  ignore(result)
}

///|
fn _bind_attached_jsdoc(host : Node, incremental : Bool) -> Unit {
  match host.jsdoc() {
    Some(documents) =>
      for document in documents.elements() {
        if !(incremental && _parent_is(document, host)) {
          document._set_parent(Some(host))
        }
        _bind_jsdoc_descendants(document, incremental)
      }
    None => ()
  }
}

///|
/// Internal equivalent of TypeScript's `setParentRecursive`.
///
/// Attached JSDoc is not a normal `for_each_child(host)` edge. For a normal
/// syntax root it is bound through the dedicated host path; a JSDoc root uses
/// only its ordinary JSDoc child ordering. Incremental mode skips a subtree
/// whose existing parent already matches, matching the upstream fast path.
fn _set_parent_recursive(root : Node, incremental? : Bool = false) -> Node {
  let root_is_jsdoc = _is_jsdoc_node(root)
  let result : Unit? = for_each_child_recursively(root, fn(child, parent) {
    if incremental && _parent_is(child, parent) {
      TraversalControl::skip()
    } else {
      child._set_parent(Some(parent))
      if !root_is_jsdoc {
        _bind_attached_jsdoc(child, incremental)
      }
      TraversalControl::proceed()
    }
  })
  ignore(result)
  root
}
