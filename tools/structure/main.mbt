///|
priv enum StructureEdgeValue {
  StructureNode(@tsparser.Node)
  StructureList(@tsparser.NodeArray)
}

///|
priv struct StructureEdge {
  field : String
  value : StructureEdgeValue
  traversal : String
}

///|
priv enum StructureTraversed {
  TraversedNode(@tsparser.Node)
  TraversedList(@tsparser.NodeArray)
}

///|
priv enum StructureFrame {
  StructureNodeFrame(@tsparser.Node, String, String?, String?, Int?, String)
  StructureListFrame(@tsparser.NodeArray, String, String, String, String)
}

///|
fn structure_int(value : Int) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
fn structure_uint(value : UInt) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
fn structure_undefined() -> Json {
  Json::object(Map([("state", Json::string("undefined"))]))
}

///|
fn structure_optional_text(value : String?) -> Json {
  match value {
    Some(value) => Json::string(value)
    None => structure_undefined()
  }
}

///|
fn structure_optional_bool(value : Bool?) -> Json {
  match value {
    Some(value) => Json::boolean(value)
    None => structure_undefined()
  }
}

///|
fn structure_optional_int(value : Int?) -> Json {
  match value {
    Some(value) => structure_int(value)
    None => structure_undefined()
  }
}

///|
fn structure_scalar(value : @tsparser.NodeFieldValue) -> Json? {
  match value {
    @tsparser.Undefined => Some(structure_undefined())
    @tsparser.NodeRef(value) =>
      match value {
        Some(_) => None
        None => Some(structure_undefined())
      }
    @tsparser.NodeList(value) =>
      match value {
        Some(_) => None
        None => Some(structure_undefined())
      }
    @tsparser.Text(value) => Some(structure_optional_text(value))
    @tsparser.Boolean(value) => Some(structure_optional_bool(value))
    @tsparser.Integer(value) => Some(structure_optional_int(value))
    @tsparser.Unsigned(value) =>
      Some(
        match value {
          Some(value) => structure_uint(value)
          None => structure_undefined()
        },
      )
    @tsparser.Kind(value) =>
      Some(
        match value {
          Some(value) => structure_int(value.to_int())
          None => structure_undefined()
        },
      )
    @tsparser.TokenFlagSet(value) => Some(structure_uint(value.bits()))
    @tsparser.NodeFlagSet(value) => Some(structure_uint(value.bits()))
    @tsparser.TransformFlagSet(value) => Some(structure_uint(value.bits()))
    @tsparser.ExternalModuleIndicatorValue(value) =>
      Some(
        match value {
          Some(@tsparser.IndicatorTrue) => Json::boolean(true)
          Some(@tsparser.IndicatorNode(node)) =>
            Json::object(
              Map([
                ("kind", structure_int(node.kind().to_int())),
                ("pos", structure_int(node.pos())),
                ("end", structure_int(node.end())),
              ]),
            )
          None => structure_undefined()
        },
      )
    @tsparser.TextList(value) =>
      Some(
        match value {
          Some(values) => {
            let items : Array[Json] = []
            for value in values {
              items.push(Json::string(value))
            }
            Json::array(items)
          }
          None => structure_undefined()
        },
      )
    @tsparser.IntegerList(value) =>
      Some(
        match value {
          Some(values) => {
            let items : Array[Json] = []
            for value in values {
              items.push(structure_int(value))
            }
            Json::array(items)
          }
          None => structure_undefined()
        },
      )
    @tsparser.DiagnosticList(_)
    | @tsparser.CommentDirectiveList(_)
    | @tsparser.PragmaMapValue(_)
    | @tsparser.CheckJsDirectiveValue(_)
    | @tsparser.FileReferenceList(_)
    | @tsparser.AmdDependencyList(_) => Some(structure_undefined())
  }
}

///|
fn structure_is_source_metadata_field(name : String) -> Bool {
  match name {
    "text"
    | "fileName"
    | "path"
    | "resolvedPath"
    | "originalFileName"
    | "languageVersion"
    | "languageVariant"
    | "scriptKind"
    | "isDeclarationFile"
    | "hasNoDefaultLib"
    | "nodeCount"
    | "identifierCount"
    | "symbolCount"
    | "parseDiagnostics"
    | "bindDiagnostics"
    | "bindSuggestionDiagnostics"
    | "lineMap"
    | "externalModuleIndicator"
    | "setExternalModuleIndicator"
    | "pragmas"
    | "checkJsDirective"
    | "referencedFiles"
    | "typeReferenceDirectives"
    | "libReferenceDirectives"
    | "amdDependencies"
    | "commentDirectives"
    | "identifiers"
    | "packageJsonLocations"
    | "packageJsonScope"
    | "imports"
    | "moduleAugmentations"
    | "ambientModuleNames"
    | "classifiableNames"
    | "impliedNodeFormat"
    | "jsDocParsingMode"
    | "jsDocDiagnostics" => true
    _ => false
  }
}

///|
fn structure_kind_has_jsdoc_property(kind : Int) -> Bool {
  match kind {
    80
    | 169
    | 170
    | 172
    | 173
    | 174
    | 175
    | 176
    | 177
    | 178
    | 179
    | 180
    | 181
    | 182
    | 185
    | 186
    | 203
    | 211
    | 212
    | 213
    | 218
    | 219
    | 220
    | 227
    | 232
    | 241
    | 242
    | 243
    | 244
    | 245
    | 246
    | 247
    | 248
    | 249
    | 250
    | 251
    | 252
    | 253
    | 254
    | 255
    | 256
    | 257
    | 258
    | 259
    | 260
    | 261
    | 263
    | 264
    | 265
    | 266
    | 267
    | 268
    | 271
    | 272
    | 273
    | 278
    | 279
    | 282
    | 297
    | 304
    | 305
    | 306
    | 307
    | 318
    | 324 => true
    _ => false
  }
}

///|
fn structure_direct_node_field(
  fields : ReadOnlyArray[@tsparser.NodeField],
  child : @tsparser.Node,
) -> String? {
  for field in fields {
    match field.value() {
      @tsparser.NodeRef(Some(candidate)) if candidate.same_identity(child) =>
        return Some(field.name())
      _ => ()
    }
  }
  None
}

///|
fn structure_list_field(
  node : @tsparser.Node,
  fields : ReadOnlyArray[@tsparser.NodeField],
  list : @tsparser.NodeArray,
) -> String? {
  for field in fields {
    match field.value() {
      @tsparser.NodeList(Some(candidate)) if candidate.same_identity(list) =>
        return Some(field.name())
      _ => ()
    }
  }
  match node.jsdoc() {
    Some(jsdoc) if jsdoc.same_identity(list) => Some("jsDoc")
    _ => None
  }
}

///|
fn structure_containing_list_field(
  node : @tsparser.Node,
  fields : ReadOnlyArray[@tsparser.NodeField],
  child : @tsparser.Node,
) -> (String, @tsparser.NodeArray)? {
  for field in fields {
    match field.value() {
      @tsparser.NodeList(Some(list)) =>
        for element in list.elements() {
          if element.same_identity(child) {
            return Some((field.name(), list))
          }
        }
      _ => ()
    }
  }
  match node.jsdoc() {
    Some(list) =>
      for element in list.elements() {
        if element.same_identity(child) {
          return Some(("jsDoc", list))
        }
      }
    None => ()
  }
  None
}

///|
fn structure_child_edges(node : @tsparser.Node) -> Array[StructureEdge] {
  let fields = node.fields()
  let traversed : Array[StructureTraversed] = []
  ignore(
    @tsparser.for_each_child(
      node,
      fn(child) -> Unit? {
        traversed.push(TraversedNode(child))
        None
      },
      list_callback=fn(list) -> Unit? {
        traversed.push(TraversedList(list))
        None
      },
    ),
  )
  let claimed : Array[String] = []
  let edges : Array[StructureEdge] = []
  for item in traversed {
    match item {
      TraversedList(list) =>
        match structure_list_field(node, fields, list) {
          Some(field) if !claimed.contains(field) => {
            claimed.push(field)
            edges.push(StructureEdge::{
              field,
              value: StructureList(list),
              traversal: "forEachChild",
            })
          }
          _ => ()
        }
      TraversedNode(child) =>
        match structure_direct_node_field(fields, child) {
          Some(field) if !claimed.contains(field) => {
            claimed.push(field)
            edges.push(StructureEdge::{
              field,
              value: StructureNode(child),
              traversal: "forEachChild",
            })
          }
          _ =>
            match structure_containing_list_field(node, fields, child) {
              Some((field, list)) if !claimed.contains(field) => {
                claimed.push(field)
                edges.push(StructureEdge::{
                  field,
                  value: StructureList(list),
                  traversal: "forEachChild",
                })
              }
              _ => ()
            }
        }
    }
  }
  for field in fields {
    if claimed.contains(field.name()) {
      continue
    }
    match field.value() {
      @tsparser.NodeRef(Some(child)) => {
        claimed.push(field.name())
        edges.push(StructureEdge::{
          field: field.name(),
          value: StructureNode(child),
          traversal: "parser_extra",
        })
      }
      @tsparser.NodeList(Some(list)) => {
        claimed.push(field.name())
        edges.push(StructureEdge::{
          field: field.name(),
          value: StructureList(list),
          traversal: "parser_extra",
        })
      }
      _ => ()
    }
  }
  match node.jsdoc() {
    Some(list) if !claimed.contains("jsDoc") =>
      edges.push(StructureEdge::{
        field: "jsDoc",
        value: StructureList(list),
        traversal: "parser_extra",
      })
    _ => ()
  }
  edges
}

///|
fn structure_pointer_segment(value : String) -> String {
  value.replace_all(old="~", new="~0").replace_all(old="/", new="~1")
}

///|
fn structure_child_path(
  parent : String,
  field : String,
  index? : Int,
) -> String {
  let base = if parent == "/" {
    "/" + structure_pointer_segment(field)
  } else {
    parent + "/" + structure_pointer_segment(field)
  }
  match index {
    Some(index) => base + "/" + index.to_string()
    None => base
  }
}

///|
fn structure_edge_json(edge : StructureEdge) -> Json {
  let fields : Map[String, Json] = Map([
    ("field", Json::string(edge.field)),
    (
      "shape",
      Json::string(
        match edge.value {
          StructureNode(_) => "node"
          StructureList(_) =>
            if edge.field == "jsDoc" {
              "node_list"
            } else {
              "node_array"
            }
        },
      ),
    ),
    ("traversal", Json::string(edge.traversal)),
  ])
  match edge.value {
    StructureList(list) => fields["length"] = structure_int(list.length())
    StructureNode(_) => ()
  }
  Json::object(fields)
}

///|
fn structure_node_record(
  node : @tsparser.Node,
  source_file : @tsparser.Node,
  path : String,
  parent_path : String?,
  field_name : String?,
  index : Int?,
  traversal : String,
  edges : Array[StructureEdge],
) -> Json {
  let scalar_fields : Map[String, Json] = Map([])
  for field in node.fields() {
    if node.kind().to_int() == 308 &&
      structure_is_source_metadata_field(field.name()) {
      continue
    }
    match structure_scalar(field.value()) {
      Some(value) => scalar_fields[field.name()] = value
      None => ()
    }
  }
  if structure_kind_has_jsdoc_property(node.kind().to_int()) &&
    node.jsdoc() is None {
    scalar_fields["jsDoc"] = structure_undefined()
  }
  let record : Map[String, Json] = Map([
    ("record", Json::string("node")),
    ("path", Json::string(path)),
    (
      "parent_path",
      match parent_path {
        Some(value) => Json::string(value)
        None => Json::null()
      },
    ),
    (
      "field",
      match field_name {
        Some(value) => Json::string(value)
        None => Json::null()
      },
    ),
    (
      "index",
      match index {
        Some(value) => structure_int(value)
        None => Json::null()
      },
    ),
    ("traversal", Json::string(traversal)),
    ("kind", structure_int(node.kind().to_int())),
    ("pos", structure_int(node.pos())),
    ("end", structure_int(node.end())),
    ("flags", structure_uint(node.flags().bits())),
    ("transform_flags", structure_uint(node.transform_flags().bits())),
    ("fields", Json::object(scalar_fields)),
    ("child_edges", Json::array(edges.map(structure_edge_json))),
  ])
  if node.kind().to_int() >= 0 && node.kind().to_int() <= 166 {
    record["token_text"] = Json::string(node.text(source_file~))
  }
  match node.field("tokenFlags") {
    Some(@tsparser.TokenFlagSet(flags)) =>
      record["token_flags"] = structure_uint(flags.bits())
    _ => ()
  }
  Json::object(record)
}

///|
fn structure_list_record(
  list : @tsparser.NodeArray,
  path : String,
  parent_path : String,
  field : String,
  traversal : String,
) -> Json {
  if field == "jsDoc" {
    return Json::object(
      Map([
        ("record", Json::string("node_list")),
        ("path", Json::string(path)),
        ("parent_path", Json::string(parent_path)),
        ("field", Json::string(field)),
        ("traversal", Json::string(traversal)),
        ("pos", structure_undefined()),
        ("end", structure_undefined()),
        ("length", structure_int(list.length())),
        ("has_trailing_comma", structure_undefined()),
        ("transform_flags", structure_undefined()),
      ]),
    )
  }
  Json::object(
    Map([
      ("record", Json::string("node_array")),
      ("path", Json::string(path)),
      ("parent_path", Json::string(parent_path)),
      ("field", Json::string(field)),
      ("traversal", Json::string(traversal)),
      ("pos", structure_int(list.pos())),
      ("end", structure_int(list.end())),
      ("length", structure_int(list.length())),
      ("has_trailing_comma", Json::boolean(list.has_trailing_comma())),
      ("transform_flags", structure_uint(list.transform_flags().bits())),
    ]),
  )
}

///|
fn structure_records(
  input : String,
  source : String,
  source_file : @tsparser.Node,
) -> String {
  let output = StringBuilder::new()
  output.write_string(
    Json::object(
      Map([
        ("record", Json::string("header")),
        ("schema", Json::string("typescript-6.0.3-parser-structure-v1")),
        ("file_name", Json::string(input)),
        ("text_utf16_length", structure_int(source.length())),
      ]),
    ).stringify(),
  )
  output.write_char('\n')
  let stack : Array[StructureFrame] = [
    StructureNodeFrame(source_file, "/", None, None, None, "root"),
  ]
  while !stack.is_empty() {
    match stack.pop().unwrap() {
      StructureNodeFrame(node, path, parent_path, field_name, index, traversal) => {
        let edges = structure_child_edges(node)
        output.write_string(
          structure_node_record(
            node, source_file, path, parent_path, field_name, index, traversal, edges,
          ).stringify(),
        )
        output.write_char('\n')
        for edge_index = edges.length() - 1
            edge_index >= 0
            edge_index = edge_index - 1 {
          let edge = edges[edge_index]
          let child_path = structure_child_path(path, edge.field)
          match edge.value {
            StructureNode(child) =>
              stack.push(
                StructureNodeFrame(
                  child,
                  child_path,
                  Some(path),
                  Some(edge.field),
                  None,
                  edge.traversal,
                ),
              )
            StructureList(list) =>
              stack.push(
                StructureListFrame(
                  list,
                  child_path,
                  path,
                  edge.field,
                  edge.traversal,
                ),
              )
          }
        }
      }
      StructureListFrame(list, path, parent_path, field, traversal) => {
        output.write_string(
          structure_list_record(list, path, parent_path, field, traversal).stringify(),
        )
        output.write_char('\n')
        for index = list.length() - 1; index >= 0; index = index - 1 {
          stack.push(
            StructureNodeFrame(
              list.get(index).unwrap(),
              structure_child_path(parent_path, field, index~),
              Some(parent_path),
              Some(field),
              Some(index),
              traversal,
            ),
          )
        }
      }
    }
  }
  output.to_string()
}

///|
fn structure_script_kind(input : String) -> @tsparser.ScriptKind {
  let lower = input.to_lower()
  if lower.has_suffix(".tsx") {
    @tsparser.ScriptKind::tsx()
  } else if lower.has_suffix(".jsx") {
    @tsparser.ScriptKind::jsx()
  } else if lower.has_suffix(".js") {
    @tsparser.ScriptKind::js()
  } else if lower.has_suffix(".json") {
    @tsparser.ScriptKind::json()
  } else {
    @tsparser.ScriptKind::ts()
  }
}

///|
async fn main {
  let args = @env.args()
  guard args.length() == 3 else {
    abort("usage: structure <input> <output.ndjson>")
  }
  let input = args[1]
  let output = args[2]
  let bytes = @fs.read_file(input).binary() catch {
    error => abort("cannot read " + input + ": \{error}")
  }
  let source = @utf8.decode_lossy(bytes.view())
  let source_file = @tsparser.create_source_file(
    input,
    source,
    language_version=@tsparser.ScriptTarget::latest(),
    script_kind=structure_script_kind(input),
  )
  @fs.write_file(
    output,
    structure_records(input, source, source_file),
    create_mode=CreateOrTruncate,
  ) catch {
    error => abort("cannot write " + output + ": \{error}")
  }
}
