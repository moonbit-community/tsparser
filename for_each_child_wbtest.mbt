///|
priv struct ChildTraversalContract {
  kinds : ReadOnlyArray[Int]
  specification : String
}

///|
fn _child_contract(
  kinds : Array[Int],
  specification : String,
) -> ChildTraversalContract {
  { kinds: ReadOnlyArray::from_array(kinds), specification }
}

///|
fn _child_traversal_contracts() -> Array[ChildTraversalContract] {
  [
    _child_contract([167], "node:left -> node:right"),
    _child_contract(
      [169],
      "nodes:modifiers -> node:name -> node:constraint -> node:default -> node:expression",
    ),
    _child_contract(
      [305],
      "nodes:modifiers -> node:name -> node:questionToken -> node:exclamationToken -> node:equalsToken -> node:objectAssignmentInitializer",
    ),
    _child_contract([306], "node:expression"),
    _child_contract(
      [170],
      "nodes:modifiers -> node:dotDotDotToken -> node:name -> node:questionToken -> node:type -> node:initializer",
    ),
    _child_contract(
      [173],
      "nodes:modifiers -> node:name -> node:questionToken -> node:exclamationToken -> node:type -> node:initializer",
    ),
    _child_contract(
      [172],
      "nodes:modifiers -> node:name -> node:questionToken -> node:type -> node:initializer",
    ),
    _child_contract(
      [304],
      "nodes:modifiers -> node:name -> node:questionToken -> node:exclamationToken -> node:initializer",
    ),
    _child_contract(
      [261],
      "node:name -> node:exclamationToken -> node:type -> node:initializer",
    ),
    _child_contract(
      [209],
      "node:dotDotDotToken -> node:propertyName -> node:name -> node:initializer",
    ),
    _child_contract(
      [182, 186, 185],
      "nodes:modifiers -> nodes:typeParameters -> nodes:parameters -> node:type",
    ),
    _child_contract(
      [180, 181],
      "nodes:typeParameters -> nodes:parameters -> node:type",
    ),
    _child_contract(
      [175],
      "nodes:modifiers -> node:asteriskToken -> node:name -> node:questionToken -> node:exclamationToken -> nodes:typeParameters -> nodes:parameters -> node:type -> node:body",
    ),
    _child_contract(
      [174],
      "nodes:modifiers -> node:name -> node:questionToken -> nodes:typeParameters -> nodes:parameters -> node:type",
    ),
    _child_contract(
      [177, 178, 179],
      "nodes:modifiers -> node:name -> nodes:typeParameters -> nodes:parameters -> node:type -> node:body",
    ),
    _child_contract(
      [263, 219],
      "nodes:modifiers -> node:asteriskToken -> node:name -> nodes:typeParameters -> nodes:parameters -> node:type -> node:body",
    ),
    _child_contract(
      [220],
      "nodes:modifiers -> nodes:typeParameters -> nodes:parameters -> node:type -> node:equalsGreaterThanToken -> node:body",
    ),
    _child_contract([176], "nodes:modifiers -> node:body"),
    _child_contract([184], "node:typeName -> nodes:typeArguments"),
    _child_contract(
      [183],
      "node:assertsModifier -> node:parameterName -> node:type",
    ),
    _child_contract([187], "node:exprName -> nodes:typeArguments"),
    _child_contract([188], "nodes:members"),
    _child_contract([189], "node:elementType"),
    _child_contract([190], "nodes:elements"),
    _child_contract([193, 194], "nodes:types"),
    _child_contract(
      [195],
      "node:checkType -> node:extendsType -> node:trueType -> node:falseType",
    ),
    _child_contract([196], "node:typeParameter"),
    _child_contract(
      [206],
      "node:argument -> node:attributes -> node:qualifier -> nodes:typeArguments",
    ),
    _child_contract([303], "node:assertClause"),
    _child_contract([197, 199], "node:type"),
    _child_contract([200], "node:objectType -> node:indexType"),
    _child_contract(
      [201],
      "node:readonlyToken -> node:typeParameter -> node:nameType -> node:questionToken -> node:type -> nodes:members",
    ),
    _child_contract([202], "node:literal"),
    _child_contract(
      [203],
      "node:dotDotDotToken -> node:name -> node:questionToken -> node:type",
    ),
    _child_contract([207, 208, 210], "nodes:elements"),
    _child_contract([211], "nodes:properties"),
    _child_contract(
      [212],
      "node:expression -> node:questionDotToken -> node:name",
    ),
    _child_contract(
      [213],
      "node:expression -> node:questionDotToken -> node:argumentExpression",
    ),
    _child_contract(
      [214, 215],
      "node:expression -> node:questionDotToken -> nodes:typeArguments -> nodes:arguments",
    ),
    _child_contract(
      [216],
      "node:tag -> node:questionDotToken -> nodes:typeArguments -> node:template",
    ),
    _child_contract([217], "node:type -> node:expression"),
    _child_contract([218, 221, 222, 223, 224, 231, 236], "node:expression"),
    _child_contract([225, 226], "node:operand"),
    _child_contract([230], "node:asteriskToken -> node:expression"),
    _child_contract([227], "node:left -> node:operatorToken -> node:right"),
    _child_contract([235, 239], "node:expression -> node:type"),
    _child_contract([237], "node:name"),
    _child_contract(
      [228],
      "node:condition -> node:questionToken -> node:whenTrue -> node:colonToken -> node:whenFalse",
    ),
    _child_contract([242, 269], "nodes:statements"),
    _child_contract([308], "nodes:statements -> node:endOfFileToken"),
    _child_contract([244], "nodes:modifiers -> node:declarationList"),
    _child_contract([262], "nodes:declarations"),
    _child_contract([245, 254, 258, 294], "node:expression"),
    _child_contract(
      [246],
      "node:expression -> node:thenStatement -> node:elseStatement",
    ),
    _child_contract([247], "node:statement -> node:expression"),
    _child_contract([248], "node:expression -> node:statement"),
    _child_contract(
      [249],
      "node:initializer -> node:condition -> node:incrementor -> node:statement",
    ),
    _child_contract(
      [250],
      "node:initializer -> node:expression -> node:statement",
    ),
    _child_contract(
      [251],
      "node:awaitModifier -> node:initializer -> node:expression -> node:statement",
    ),
    _child_contract([252, 253], "node:label"),
    _child_contract([255], "node:expression -> node:statement"),
    _child_contract([256], "node:expression -> node:caseBlock"),
    _child_contract([270], "nodes:clauses"),
    _child_contract([297], "node:expression -> nodes:statements"),
    _child_contract([298], "nodes:statements"),
    _child_contract([257], "node:label -> node:statement"),
    _child_contract(
      [259],
      "node:tryBlock -> node:catchClause -> node:finallyBlock",
    ),
    _child_contract([300], "node:variableDeclaration -> node:block"),
    _child_contract([171, 284], "node:expression"),
    _child_contract(
      [264, 232, 265],
      "nodes:modifiers -> node:name -> nodes:typeParameters -> nodes:heritageClauses -> nodes:members",
    ),
    _child_contract(
      [266],
      "nodes:modifiers -> node:name -> nodes:typeParameters -> node:type",
    ),
    _child_contract([267], "nodes:modifiers -> node:name -> nodes:members"),
    _child_contract([307], "node:name -> node:initializer"),
    _child_contract([268], "nodes:modifiers -> node:name -> node:body"),
    _child_contract(
      [272],
      "nodes:modifiers -> node:name -> node:moduleReference",
    ),
    _child_contract(
      [273],
      "nodes:modifiers -> node:importClause -> node:moduleSpecifier -> node:attributes",
    ),
    _child_contract([274], "node:name -> node:namedBindings"),
    _child_contract([301, 357], "nodes:elements"),
    _child_contract([302], "node:name -> node:value"),
    _child_contract([271], "nodes:modifiers -> node:name"),
    _child_contract([275, 281], "node:name"),
    _child_contract([276, 280], "nodes:elements"),
    _child_contract(
      [279],
      "nodes:modifiers -> node:exportClause -> node:moduleSpecifier -> node:attributes",
    ),
    _child_contract([277, 282], "node:propertyName -> node:name"),
    _child_contract([278], "nodes:modifiers -> node:expression"),
    _child_contract([229, 204], "node:head -> nodes:templateSpans"),
    _child_contract([240], "node:expression -> node:literal"),
    _child_contract([205], "node:type -> node:literal"),
    _child_contract([168], "node:expression"),
    _child_contract([299], "nodes:types"),
    _child_contract([234], "node:expression -> nodes:typeArguments"),
    _child_contract([283], "nodes:modifiers"),
    _child_contract(
      [285],
      "node:openingElement -> nodes:children -> node:closingElement",
    ),
    _child_contract(
      [289],
      "node:openingFragment -> nodes:children -> node:closingFragment",
    ),
    _child_contract(
      [286, 287],
      "node:tagName -> nodes:typeArguments -> node:attributes",
    ),
    _child_contract([293], "nodes:properties"),
    _child_contract([292], "node:name -> node:initializer"),
    _child_contract([295], "node:dotDotDotToken -> node:expression"),
    _child_contract([288], "node:tagName"),
    _child_contract([296], "node:namespace -> node:name"),
    _child_contract([191, 192, 310, 316, 315, 317, 319], "node:type"),
    _child_contract([318], "nodes:parameters -> node:type"),
    _child_contract([321], "nodes:comment -> nodes:tags"),
    _child_contract([348], "node:tagName -> node:name -> nodes:comment"),
    _child_contract([311], "node:name"),
    _child_contract([312], "node:left -> node:right"),
    _child_contract(
      [342, 349],
      "node:tagName -> node:typeExpression -> node:name -> nodes:comment",
    ),
    _child_contract([331], "node:tagName -> nodes:comment"),
    _child_contract([330, 329], "node:tagName -> node:class -> nodes:comment"),
    _child_contract(
      [346],
      "node:tagName -> node:constraint -> nodes:typeParameters -> nodes:comment",
    ),
    _child_contract(
      [347, 339],
      "node:tagName -> node:fullName -> node:typeExpression -> nodes:comment",
    ),
    _child_contract(
      [343, 345, 344, 341, 351, 350, 340],
      "node:tagName -> node:typeExpression -> nodes:comment",
    ),
    _child_contract(
      [324],
      "flat:typeParameters -> flat:parameters -> node:type",
    ),
    _child_contract([325, 326, 327], "node:name"),
    _child_contract([323], "flat:jsDocPropertyTags"),
    _child_contract(
      [328, 333, 334, 335, 336, 337, 332, 338],
      "node:tagName -> nodes:comment",
    ),
    _child_contract(
      [352],
      "node:tagName -> node:importClause -> node:moduleSpecifier -> node:attributes -> nodes:comment",
    ),
    _child_contract([356], "node:expression"),
  ]
}

///|
priv enum ExpectedTraversalSlot {
  ExpectedNode(String)
  ExpectedNodes(String)
  ExpectedFlat(String)
}

///|
fn _expected_traversal_slots(
  specification : String,
) -> Array[ExpectedTraversalSlot] {
  let slots : Array[ExpectedTraversalSlot] = []
  for part in specification.split(" -> ") {
    let part = part.to_owned()
    match part.strip_prefix("node:") {
      Some(name) => slots.push(ExpectedNode(name.to_owned()))
      None =>
        match part.strip_prefix("nodes:") {
          Some(name) => slots.push(ExpectedNodes(name.to_owned()))
          None =>
            match part.strip_prefix("flat:") {
              Some(name) => slots.push(ExpectedFlat(name.to_owned()))
              None => abort("invalid child traversal specification")
            }
        }
    }
  }
  slots
}

///|
fn _child_marker(name : String, kind : Int, position : Int) -> Node {
  let marker = _make_fields_node(_syntax_kind(kind), [
    _text_field("auditLabel", Some(name)),
  ])
  marker._set_text_range(position, position + 1)
  marker
}

///|
fn _child_marker_label(node : Node) -> String {
  match node.field("auditLabel") {
    Some(Text(Some(label))) => label
    _ => abort("child traversal marker has no label")
  }
}

///|
fn _child_list_marker_label(nodes : NodeArray) -> String {
  match nodes.get(0) {
    Some(node) => _child_marker_label(node)
    None => abort("child traversal marker list is empty")
  }
}

///|
fn _child_traversal_fixture(
  kind : Int,
  slots : Array[ExpectedTraversalSlot],
  is_name_first? : Bool = false,
  typedef_type_expression_first? : Bool = false,
) -> Node {
  let fields : Array[NodeField] = []
  for index, slot in slots {
    let field_name = match slot {
      ExpectedNode(field_name)
      | ExpectedNodes(field_name)
      | ExpectedFlat(field_name) => field_name
    }
    let marker_kind = if typedef_type_expression_first &&
      field_name == "typeExpression" {
      310
    } else {
      80
    }
    let marker = _child_marker(field_name, marker_kind, index * 2 + 1)
    match slot {
      ExpectedNode(_) => fields.push(_node_ref_field(field_name, Some(marker)))
      ExpectedNodes(_) | ExpectedFlat(_) => {
        let list = _create_node_array([marker])
        list._set_text_range(marker.pos(), marker.end())
        fields.push(_node_list_field(field_name, Some(list)))
      }
    }
  }
  if kind == 342 || kind == 349 {
    fields.push(_boolean_field("isNameFirst", Some(is_name_first)))
  }
  _make_fields_node(_syntax_kind(kind), fields)
}

///|
fn _assert_string_sequence(
  label : String,
  actual : Array[String],
  expected : Array[String],
) -> Unit raise {
  assert_eq(actual.length(), expected.length(), msg=label + " length")
  for index in 0..<expected.length() {
    assert_eq(
      actual[index],
      expected[index],
      msg=label + " item " + index.to_string(),
    )
  }
}

///|
fn _assert_position_sequence(
  label : String,
  actual : Array[Int],
  expected_count : Int,
) -> Unit raise {
  assert_eq(actual.length(), expected_count, msg=label + " position length")
  for index in 0..<expected_count {
    assert_eq(
      actual[index],
      index * 2 + 1,
      msg=label + " position " + index.to_string(),
    )
  }
}

///|
fn _assert_child_traversal_contract(
  kind : Int,
  specification : String,
  is_name_first? : Bool = false,
  typedef_type_expression_first? : Bool = false,
) -> Unit raise {
  let slots = _expected_traversal_slots(specification)
  let node = _child_traversal_fixture(
    kind,
    slots,
    is_name_first~,
    typedef_type_expression_first~,
  )
  let flattened : Array[String] = []
  let flattened_positions : Array[Int] = []
  let flattened_result : Unit? = for_each_child(node, fn(child) {
    flattened.push("node:" + _child_marker_label(child))
    flattened_positions.push(child.pos())
    None
  })
  assert_eq(flattened_result, None)
  let expected_flattened : Array[String] = []
  for slot in slots {
    let field_name = match slot {
      ExpectedNode(field_name)
      | ExpectedNodes(field_name)
      | ExpectedFlat(field_name) => field_name
    }
    expected_flattened.push("node:" + field_name)
  }
  let label = "SyntaxKind[" + kind.to_string() + "]"
  _assert_string_sequence(label + " flattened", flattened, expected_flattened)
  _assert_position_sequence(
    label + " flattened",
    flattened_positions,
    slots.length(),
  )

  let with_lists : Array[String] = []
  let with_list_positions : Array[Int] = []
  let list_result : Unit? = for_each_child(
    node,
    fn(child) {
      with_lists.push("node:" + _child_marker_label(child))
      with_list_positions.push(child.pos())
      None
    },
    list_callback=fn(children) {
      with_lists.push("nodes:" + _child_list_marker_label(children))
      with_list_positions.push(children.pos())
      None
    },
  )
  assert_eq(list_result, None)
  let expected_with_lists : Array[String] = []
  for slot in slots {
    match slot {
      ExpectedNode(field_name) | ExpectedFlat(field_name) =>
        expected_with_lists.push("node:" + field_name)
      ExpectedNodes(field_name) =>
        expected_with_lists.push("nodes:" + field_name)
    }
  }
  _assert_string_sequence(label + " lists", with_lists, expected_with_lists)
  _assert_position_sequence(
    label + " lists",
    with_list_positions,
    slots.length(),
  )
}

///|
test "all 175 forEachChild branches preserve child and NodeArray source order" {
  let seen = Array::make(SyntaxKind::count(), false)
  let mut count = 0
  for contract in _child_traversal_contracts() {
    for kind in contract.kinds {
      assert_false(seen[kind], msg="duplicate traversal contract")
      seen[kind] = true
      count += 1
      _assert_child_traversal_contract(kind, contract.specification)
    }
  }
  assert_eq(count, 175)
}

///|
test "dynamic JSDoc child orders follow isNameFirst and typedef type shape" {
  let name_first = "node:tagName -> node:name -> node:typeExpression -> nodes:comment"
  _assert_child_traversal_contract(342, name_first, is_name_first=true)
  _assert_child_traversal_contract(349, name_first, is_name_first=true)
  _assert_child_traversal_contract(
    347,
    "node:tagName -> node:typeExpression -> node:fullName -> nodes:comment",
    typedef_type_expression_first=true,
  )
}

///|
test "for_each_child stops immediately and tokens have no children" {
  let slots = _expected_traversal_slots(
    "node:condition -> node:questionToken -> node:whenTrue",
  )
  let conditional = _child_traversal_fixture(228, slots)
  let visited : Array[String] = []
  let stopped = for_each_child(conditional, fn(child) {
    let label = _child_marker_label(child)
    visited.push(label)
    if label == "questionToken" {
      Some(label)
    } else {
      None
    }
  })
  assert_eq(stopped, Some("questionToken"))
  _assert_string_sequence("early stop", visited, ["condition", "questionToken"])

  let token_result : Unit? = for_each_child(
    _factory_create_token(_syntax_kind(19)),
    fn(_) { abort("token callback must not run") },
  )
  assert_eq(token_result, None)
}

///|
fn _label_traversal_node(node : Node, label : String) -> Node {
  let fields : Array[NodeField] = []
  for field in node.fields() {
    fields.push(field)
  }
  fields.push(_text_field("auditLabel", Some(label)))
  node._set_fields(fields)
  node
}

///|
fn _traversal_node_label(node : Node) -> String {
  match node.field("auditLabel") {
    Some(Text(Some(label))) => label
    _ => "kind:" + node.kind().to_int().to_string()
  }
}

///|
test "recursive child traversal is depth-first, reports parents, and honors skip" {
  let a = _label_traversal_node(_contract_identifier(text="a"), "a")
  let first = _label_traversal_node(
    _factory_create_expression_statement(a),
    "first",
  )
  let b = _label_traversal_node(_contract_identifier(text="b"), "b")
  let returned = _label_traversal_node(
    _factory_create_return_statement(Some(b)),
    "return",
  )
  let nested_statements = _create_node_array([returned])
  let second = _label_traversal_node(
    _factory_create_block(nested_statements),
    "second",
  )
  let root_statements = _create_node_array([first, second])
  let root = _label_traversal_node(
    _factory_create_block(root_statements),
    "root",
  )

  let order : Array[String] = []
  let parent_order : Array[String] = []
  let result : String? = for_each_child_recursively(
    root,
    fn(node, parent) {
      order.push("node:" + _traversal_node_label(node))
      parent_order.push(_traversal_node_label(parent))
      TraversalControl::proceed()
    },
    list_callback=fn(nodes, parent) {
      let label = if nodes.same_identity(root_statements) {
        "root-statements"
      } else if nodes.same_identity(nested_statements) {
        "nested-statements"
      } else {
        "unknown-list"
      }
      order.push("list:" + label)
      parent_order.push(_traversal_node_label(parent))
      TraversalControl::proceed()
    },
  )
  assert_eq(result, None)
  _assert_string_sequence("recursive order", order, [
    "list:root-statements", "node:first", "node:a", "node:second", "list:nested-statements",
    "node:return", "node:b",
  ])
  _assert_string_sequence("recursive parents", parent_order, [
    "root", "root", "first", "root", "second", "second", "return",
  ])

  let skipped : Array[String] = []
  let skip_result : String? = for_each_child_recursively(
    root,
    fn(node, _) {
      let label = _traversal_node_label(node)
      skipped.push(label)
      if label == "first" {
        TraversalControl::skip()
      } else {
        TraversalControl::proceed()
      }
    },
    list_callback=fn(nodes, _) {
      if nodes.same_identity(nested_statements) {
        TraversalControl::skip()
      } else {
        TraversalControl::proceed()
      }
    },
  )
  assert_eq(skip_result, None)
  _assert_string_sequence("recursive skip", skipped, ["first", "second"])

  let stopped : String? = for_each_child_recursively(root, fn(node, _) {
    let label = _traversal_node_label(node)
    if label == "second" {
      TraversalControl::stop(label)
    } else {
      TraversalControl::proceed()
    }
  })
  assert_eq(stopped, Some("second"))
}

///|
test "recursive child traversal handles deep trees without call-stack recursion" {
  let mut root = _contract_identifier(text="leaf")
  for _ in 0..<10000 {
    root = _factory_create_parenthesized_expression(root)
  }
  let mut count = 0
  let result : Unit? = for_each_child_recursively(root, fn(_, _) {
    count += 1
    TraversalControl::proceed()
  })
  assert_eq(result, None)
  assert_eq(count, 10000)
}
