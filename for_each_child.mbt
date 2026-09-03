// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
priv enum ChildSlot {
  Single(String)
  List(String)
  FlatList(String)
}

///|
fn[T] _visit_single_child(
  node : Node,
  field_name : String,
  callback : (Node) -> T?,
) -> T? {
  match node.field(field_name) {
    Some(NodeRef(Some(child))) => callback(child)
    _ => None
  }
}

///|
fn[T] _visit_flat_child_list(
  node : Node,
  field_name : String,
  callback : (Node) -> T?,
) -> T? {
  match node.field(field_name) {
    Some(NodeList(Some(children))) => {
      for child in children.elements() {
        match callback(child) {
          Some(result) => return Some(result)
          None => ()
        }
      }
      None
    }
    _ => None
  }
}

///|
fn[T] _visit_child_list(
  node : Node,
  field_name : String,
  callback : (Node) -> T?,
  list_callback : ((NodeArray) -> T?)?,
) -> T? {
  match node.field(field_name) {
    Some(NodeList(Some(children))) =>
      match list_callback {
        Some(list_callback) => list_callback(children)
        None => _visit_flat_child_list(node, field_name, callback)
      }
    _ => None
  }
}

///|
fn[T] _visit_child_slots(
  node : Node,
  callback : (Node) -> T?,
  list_callback : ((NodeArray) -> T?)?,
  slots : Array[ChildSlot],
) -> T? {
  for slot in slots {
    let result = match slot {
      Single(field_name) => _visit_single_child(node, field_name, callback)
      List(field_name) =>
        _visit_child_list(node, field_name, callback, list_callback)
      FlatList(field_name) => _visit_flat_child_list(node, field_name, callback)
    }
    match result {
      Some(result) => return Some(result)
      None => ()
    }
  }
  None
}

///|
fn _boolean_child_field(node : Node, field_name : String) -> Bool {
  match node.field(field_name) {
    Some(Boolean(Some(value))) => value
    _ => false
  }
}

///|
fn _jsdoc_typedef_type_expression_first(node : Node) -> Bool {
  match node.field("typeExpression") {
    Some(NodeRef(Some(type_expression))) =>
      type_expression.kind().to_int() == 310
    _ => false
  }
}

///|
/// Visits direct syntax children in TypeScript source order.
///
/// Returning `Some` from either callback stops traversal immediately. When
/// `list_callback` is omitted, NodeArray fields are flattened through
/// `callback`. JSDoc signature/property-tag lists that upstream always flattens
/// retain that behavior even when `list_callback` is present.
pub fn[T] for_each_child(
  node : Node,
  callback : (Node) -> T?,
  list_callback? : (NodeArray) -> T?,
) -> T? {
  let visit = fn(slots) {
    _visit_child_slots(node, callback, list_callback, slots)
  }
  match node.kind().to_int() {
    167 => visit([Single("left"), Single("right")])
    169 =>
      visit([
        List("modifiers"),
        Single("name"),
        Single("constraint"),
        Single("default"),
        Single("expression"),
      ])
    305 =>
      visit([
        List("modifiers"),
        Single("name"),
        Single("questionToken"),
        Single("exclamationToken"),
        Single("equalsToken"),
        Single("objectAssignmentInitializer"),
      ])
    306 => visit([Single("expression")])
    170 =>
      visit([
        List("modifiers"),
        Single("dotDotDotToken"),
        Single("name"),
        Single("questionToken"),
        Single("type"),
        Single("initializer"),
      ])
    173 =>
      visit([
        List("modifiers"),
        Single("name"),
        Single("questionToken"),
        Single("exclamationToken"),
        Single("type"),
        Single("initializer"),
      ])
    172 =>
      visit([
        List("modifiers"),
        Single("name"),
        Single("questionToken"),
        Single("type"),
        Single("initializer"),
      ])
    304 =>
      visit([
        List("modifiers"),
        Single("name"),
        Single("questionToken"),
        Single("exclamationToken"),
        Single("initializer"),
      ])
    261 =>
      visit([
        Single("name"),
        Single("exclamationToken"),
        Single("type"),
        Single("initializer"),
      ])
    209 =>
      visit([
        Single("dotDotDotToken"),
        Single("propertyName"),
        Single("name"),
        Single("initializer"),
      ])
    182 | 186 | 185 =>
      visit([
        List("modifiers"),
        List("typeParameters"),
        List("parameters"),
        Single("type"),
      ])
    180 | 181 =>
      visit([List("typeParameters"), List("parameters"), Single("type")])
    175 =>
      visit([
        List("modifiers"),
        Single("asteriskToken"),
        Single("name"),
        Single("questionToken"),
        Single("exclamationToken"),
        List("typeParameters"),
        List("parameters"),
        Single("type"),
        Single("body"),
      ])
    174 =>
      visit([
        List("modifiers"),
        Single("name"),
        Single("questionToken"),
        List("typeParameters"),
        List("parameters"),
        Single("type"),
      ])
    177 | 178 | 179 =>
      visit([
        List("modifiers"),
        Single("name"),
        List("typeParameters"),
        List("parameters"),
        Single("type"),
        Single("body"),
      ])
    263 | 219 =>
      visit([
        List("modifiers"),
        Single("asteriskToken"),
        Single("name"),
        List("typeParameters"),
        List("parameters"),
        Single("type"),
        Single("body"),
      ])
    220 =>
      visit([
        List("modifiers"),
        List("typeParameters"),
        List("parameters"),
        Single("type"),
        Single("equalsGreaterThanToken"),
        Single("body"),
      ])
    176 => visit([List("modifiers"), Single("body")])
    184 => visit([Single("typeName"), List("typeArguments")])
    183 =>
      visit([Single("assertsModifier"), Single("parameterName"), Single("type")])
    187 => visit([Single("exprName"), List("typeArguments")])
    188 => visit([List("members")])
    189 => visit([Single("elementType")])
    190 => visit([List("elements")])
    193 | 194 => visit([List("types")])
    195 =>
      visit([
        Single("checkType"),
        Single("extendsType"),
        Single("trueType"),
        Single("falseType"),
      ])
    196 => visit([Single("typeParameter")])
    206 =>
      visit([
        Single("argument"),
        Single("attributes"),
        Single("qualifier"),
        List("typeArguments"),
      ])
    303 => visit([Single("assertClause")])
    197 | 199 => visit([Single("type")])
    200 => visit([Single("objectType"), Single("indexType")])
    201 =>
      visit([
        Single("readonlyToken"),
        Single("typeParameter"),
        Single("nameType"),
        Single("questionToken"),
        Single("type"),
        List("members"),
      ])
    202 => visit([Single("literal")])
    203 =>
      visit([
        Single("dotDotDotToken"),
        Single("name"),
        Single("questionToken"),
        Single("type"),
      ])
    207 | 208 => visit([List("elements")])
    210 => visit([List("elements")])
    211 => visit([List("properties")])
    212 =>
      visit([Single("expression"), Single("questionDotToken"), Single("name")])
    213 =>
      visit([
        Single("expression"),
        Single("questionDotToken"),
        Single("argumentExpression"),
      ])
    214 | 215 =>
      visit([
        Single("expression"),
        Single("questionDotToken"),
        List("typeArguments"),
        List("arguments"),
      ])
    216 =>
      visit([
        Single("tag"),
        Single("questionDotToken"),
        List("typeArguments"),
        Single("template"),
      ])
    217 => visit([Single("type"), Single("expression")])
    218 => visit([Single("expression")])
    221 | 222 | 223 => visit([Single("expression")])
    225 => visit([Single("operand")])
    230 => visit([Single("asteriskToken"), Single("expression")])
    224 => visit([Single("expression")])
    226 => visit([Single("operand")])
    227 => visit([Single("left"), Single("operatorToken"), Single("right")])
    235 => visit([Single("expression"), Single("type")])
    236 => visit([Single("expression")])
    239 => visit([Single("expression"), Single("type")])
    237 => visit([Single("name")])
    228 =>
      visit([
        Single("condition"),
        Single("questionToken"),
        Single("whenTrue"),
        Single("colonToken"),
        Single("whenFalse"),
      ])
    231 => visit([Single("expression")])
    242 | 269 => visit([List("statements")])
    308 => visit([List("statements"), Single("endOfFileToken")])
    244 => visit([List("modifiers"), Single("declarationList")])
    262 => visit([List("declarations")])
    245 => visit([Single("expression")])
    246 =>
      visit([
        Single("expression"),
        Single("thenStatement"),
        Single("elseStatement"),
      ])
    247 => visit([Single("statement"), Single("expression")])
    248 => visit([Single("expression"), Single("statement")])
    249 =>
      visit([
        Single("initializer"),
        Single("condition"),
        Single("incrementor"),
        Single("statement"),
      ])
    250 =>
      visit([Single("initializer"), Single("expression"), Single("statement")])
    251 =>
      visit([
        Single("awaitModifier"),
        Single("initializer"),
        Single("expression"),
        Single("statement"),
      ])
    252 | 253 => visit([Single("label")])
    254 => visit([Single("expression")])
    255 => visit([Single("expression"), Single("statement")])
    256 => visit([Single("expression"), Single("caseBlock")])
    270 => visit([List("clauses")])
    297 => visit([Single("expression"), List("statements")])
    298 => visit([List("statements")])
    257 => visit([Single("label"), Single("statement")])
    258 => visit([Single("expression")])
    259 =>
      visit([Single("tryBlock"), Single("catchClause"), Single("finallyBlock")])
    300 => visit([Single("variableDeclaration"), Single("block")])
    171 => visit([Single("expression")])
    264 | 232 =>
      visit([
        List("modifiers"),
        Single("name"),
        List("typeParameters"),
        List("heritageClauses"),
        List("members"),
      ])
    265 =>
      visit([
        List("modifiers"),
        Single("name"),
        List("typeParameters"),
        List("heritageClauses"),
        List("members"),
      ])
    266 =>
      visit([
        List("modifiers"),
        Single("name"),
        List("typeParameters"),
        Single("type"),
      ])
    267 => visit([List("modifiers"), Single("name"), List("members")])
    307 => visit([Single("name"), Single("initializer")])
    268 => visit([List("modifiers"), Single("name"), Single("body")])
    272 => visit([List("modifiers"), Single("name"), Single("moduleReference")])
    273 =>
      visit([
        List("modifiers"),
        Single("importClause"),
        Single("moduleSpecifier"),
        Single("attributes"),
      ])
    274 => visit([Single("name"), Single("namedBindings")])
    301 => visit([List("elements")])
    302 => visit([Single("name"), Single("value")])
    271 => visit([List("modifiers"), Single("name")])
    275 | 281 => visit([Single("name")])
    276 | 280 => visit([List("elements")])
    279 =>
      visit([
        List("modifiers"),
        Single("exportClause"),
        Single("moduleSpecifier"),
        Single("attributes"),
      ])
    277 | 282 => visit([Single("propertyName"), Single("name")])
    278 => visit([List("modifiers"), Single("expression")])
    229 => visit([Single("head"), List("templateSpans")])
    240 => visit([Single("expression"), Single("literal")])
    204 => visit([Single("head"), List("templateSpans")])
    205 => visit([Single("type"), Single("literal")])
    168 => visit([Single("expression")])
    299 => visit([List("types")])
    234 => visit([Single("expression"), List("typeArguments")])
    284 => visit([Single("expression")])
    283 => visit([List("modifiers")])
    357 => visit([List("elements")])
    285 =>
      visit([
        Single("openingElement"),
        List("children"),
        Single("closingElement"),
      ])
    289 =>
      visit([
        Single("openingFragment"),
        List("children"),
        Single("closingFragment"),
      ])
    286 | 287 =>
      visit([Single("tagName"), List("typeArguments"), Single("attributes")])
    293 => visit([List("properties")])
    292 => visit([Single("name"), Single("initializer")])
    294 => visit([Single("expression")])
    295 => visit([Single("dotDotDotToken"), Single("expression")])
    288 => visit([Single("tagName")])
    296 => visit([Single("namespace"), Single("name")])
    191 | 192 | 310 | 316 | 315 | 317 | 319 => visit([Single("type")])
    318 => visit([List("parameters"), Single("type")])
    321 => visit([List("comment"), List("tags")])
    348 => visit([Single("tagName"), Single("name"), List("comment")])
    311 => visit([Single("name")])
    312 => visit([Single("left"), Single("right")])
    342 | 349 =>
      if _boolean_child_field(node, "isNameFirst") {
        visit([
          Single("tagName"),
          Single("name"),
          Single("typeExpression"),
          List("comment"),
        ])
      } else {
        visit([
          Single("tagName"),
          Single("typeExpression"),
          Single("name"),
          List("comment"),
        ])
      }
    331 => visit([Single("tagName"), List("comment")])
    330 | 329 => visit([Single("tagName"), Single("class"), List("comment")])
    346 =>
      visit([
        Single("tagName"),
        Single("constraint"),
        List("typeParameters"),
        List("comment"),
      ])
    347 =>
      if _jsdoc_typedef_type_expression_first(node) {
        visit([
          Single("tagName"),
          Single("typeExpression"),
          Single("fullName"),
          List("comment"),
        ])
      } else {
        visit([
          Single("tagName"),
          Single("fullName"),
          Single("typeExpression"),
          List("comment"),
        ])
      }
    339 =>
      visit([
        Single("tagName"),
        Single("fullName"),
        Single("typeExpression"),
        List("comment"),
      ])
    343 | 345 | 344 | 341 | 351 | 350 | 340 =>
      visit([Single("tagName"), Single("typeExpression"), List("comment")])
    324 =>
      visit([FlatList("typeParameters"), FlatList("parameters"), Single("type")])
    325 | 326 | 327 => visit([Single("name")])
    323 => visit([FlatList("jsDocPropertyTags")])
    328 | 333 | 334 | 335 | 336 | 337 | 332 | 338 =>
      visit([Single("tagName"), List("comment")])
    352 =>
      visit([
        Single("tagName"),
        Single("importClause"),
        Single("moduleSpecifier"),
        Single("attributes"),
        List("comment"),
      ])
    356 => visit([Single("expression")])
    _ => None
  }
}

///|
/// Controls explicit-stack descendant traversal.
pub enum TraversalControl[T] {
  TraversalContinue
  TraversalSkip
  TraversalStop(T)
}

///|
pub fn[T] TraversalControl::proceed() -> TraversalControl[T] {
  TraversalContinue
}

///|
pub fn[T] TraversalControl::skip() -> TraversalControl[T] {
  TraversalSkip
}

///|
pub fn[T] TraversalControl::stop(result : T) -> TraversalControl[T] {
  TraversalStop(result)
}

///|
priv enum TraversalWorkItem {
  WorkNode(Node, Node)
  WorkList(NodeArray, Node)
}

///|
fn _direct_child_work(parent : Node) -> Array[TraversalWorkItem] {
  let work : Array[TraversalWorkItem] = []
  let node_result : Unit? = for_each_child(
    parent,
    fn(child) {
      work.push(WorkNode(child, parent))
      None
    },
    list_callback=fn(children) {
      work.push(WorkList(children, parent))
      None
    },
  )
  ignore(node_result)
  work
}

///|
fn _push_work_in_reverse(
  stack : Array[TraversalWorkItem],
  work : Array[TraversalWorkItem],
) -> Unit {
  for offset in 0..<work.length() {
    stack.push(work[work.length() - 1 - offset])
  }
}

///|
/// Traverses descendants in depth-first preorder without using the call stack.
/// The root itself is not reported. `TraversalSkip` suppresses the current
/// node/list subtree, while `TraversalStop` returns immediately.
pub fn[T] for_each_child_recursively(
  root : Node,
  callback : (Node, Node) -> TraversalControl[T],
  list_callback? : (NodeArray, Node) -> TraversalControl[T],
) -> T? {
  let stack : Array[TraversalWorkItem] = []
  _push_work_in_reverse(stack, _direct_child_work(root))
  while stack.length() > 0 {
    match stack.pop() {
      Some(WorkList(children, parent)) => {
        let control = match list_callback {
          Some(list_callback) => list_callback(children, parent)
          None => TraversalContinue
        }
        match control {
          TraversalStop(result) => return Some(result)
          TraversalSkip => continue
          TraversalContinue => {
            let items : Array[TraversalWorkItem] = []
            for child in children.elements() {
              items.push(WorkNode(child, parent))
            }
            _push_work_in_reverse(stack, items)
          }
        }
      }
      Some(WorkNode(node, parent)) =>
        match callback(node, parent) {
          TraversalStop(result) => return Some(result)
          TraversalSkip => continue
          TraversalContinue =>
            _push_work_in_reverse(stack, _direct_child_work(node))
        }
      None => ()
    }
  }
  None
}
