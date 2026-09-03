///|
priv enum LegacyProjectionFrame {
  LegacyNodeFrame(@tsparser.Node, Int)
  LegacyChildrenFrame(Array[@tsparser.Node], Int, Int)
}

///|
fn legacy_indent(width : Int) -> String {
  " ".repeat(width)
}

///|
fn legacy_json_string(value : String) -> String {
  Json::string(value).stringify()
}

///|
fn legacy_line_starts(source : String) -> Array[Int] {
  let starts = [0]
  let mut position = 0
  while position < source.length() {
    match source[position].to_int() {
      0x0d => {
        position += 1
        if position < source.length() && source[position].to_int() == 0x0a {
          position += 1
        }
        starts.push(position)
      }
      0x0a => {
        position += 1
        starts.push(position)
      }
      0x2028 | 0x2029 => {
        position += 1
        starts.push(position)
      }
      _ => position += 1
    }
  }
  starts
}

///|
fn legacy_line_index(starts : Array[Int], position : Int) -> Int {
  let mut low = 0
  let mut high = starts.length() - 1
  while low <= high {
    let middle = low + ((high - low) >> 1)
    if starts[middle] <= position {
      low = middle + 1
    } else {
      high = middle - 1
    }
  }
  high
}

///|
fn legacy_clamp(position : Int, source_length : Int) -> Int {
  if position < 0 {
    0
  } else if position > source_length {
    source_length
  } else {
    position
  }
}

///|
async fn legacy_write_location(
  write : async (String) -> Unit,
  write_spaces : async (Int) -> Unit,
  position : Int,
  source_length : Int,
  line_starts : Array[Int],
  indent : Int,
) -> Unit {
  let clipped = legacy_clamp(position, source_length)
  let line = legacy_line_index(line_starts, clipped)
  write("{\n")
  write_spaces(indent + 2)
  write("\"offset\": ")
  write(clipped.to_string())
  write(",\n")
  write_spaces(indent + 2)
  write("\"line\": ")
  write((line + 1).to_string())
  write(",\n")
  write_spaces(indent + 2)
  write("\"column\": ")
  write((clipped - line_starts[line] + 1).to_string())
  write("\n")
  write_spaces(indent)
  write("}")
}

///|
fn legacy_node_children(node : @tsparser.Node) -> Array[@tsparser.Node] {
  let children : Array[@tsparser.Node] = []
  let result : Unit? = @tsparser.for_each_child(node, fn(child) {
    children.push(child)
    None
  })
  ignore(result)
  children
}

///|
fn legacy_node_text(
  node : @tsparser.Node,
  source_file : @tsparser.Node,
) -> String? {
  let kind = node.kind().to_int()
  if kind == 80 || kind == 81 {
    return match node.field("escapedText") {
      Some(@tsparser.Text(Some(value))) => {
        let text = if value.has_prefix("___") {
          value.unsafe_substring(start=1, end=value.length())
        } else {
          value
        }
        Some(text)
      }
      _ => None
    }
  }
  if kind == 9 || kind == 11 || kind == 15 {
    return match node.field("text") {
      Some(@tsparser.Text(Some(value))) => Some(value)
      _ => None
    }
  }
  if kind >= 0 && kind <= 166 {
    Some(node.text(source_file~))
  } else {
    None
  }
}

///|
async fn legacy_emit_ast_projection(
  source_file : @tsparser.Node,
  source : String,
  write : async (String) -> Unit,
  write_spaces : async (Int) -> Unit,
) -> Unit {
  let line_starts = legacy_line_starts(source)
  let stack : Array[LegacyProjectionFrame] = [LegacyNodeFrame(source_file, 0)]
  while !stack.is_empty() {
    match stack.pop().unwrap() {
      LegacyChildrenFrame(children, index, indent) =>
        if index >= children.length() {
          write("\n")
          write_spaces(indent + 2)
          write("]\n")
          write_spaces(indent)
          write("}")
        } else {
          if index > 0 {
            write(",\n")
          }
          stack.push(LegacyChildrenFrame(children, index + 1, indent))
          stack.push(LegacyNodeFrame(children[index], indent + 4))
        }
      LegacyNodeFrame(node, indent) => {
        let children = legacy_node_children(node)
        let text = legacy_node_text(node, source_file)
        write_spaces(indent)
        write("{\n")
        write_spaces(indent + 2)
        write("\"kind\": ")
        write(legacy_json_string(node.kind().runtime_name()))
        write(",\n")
        write_spaces(indent + 2)
        write("\"pos\": ")
        legacy_write_location(
          write,
          write_spaces,
          node.pos(),
          source.length(),
          line_starts,
          indent + 2,
        )
        write(",\n")
        write_spaces(indent + 2)
        write("\"end\": ")
        legacy_write_location(
          write,
          write_spaces,
          node.end(),
          source.length(),
          line_starts,
          indent + 2,
        )
        match text {
          Some(text) => {
            write(",\n")
            write_spaces(indent + 2)
            write("\"text\": ")
            write(legacy_json_string(text))
          }
          None => ()
        }
        if children.is_empty() {
          write("\n")
          write_spaces(indent)
          write("}")
        } else {
          write(",\n")
          write_spaces(indent + 2)
          write("\"children\": [\n")
          stack.push(LegacyChildrenFrame(children, 0, indent))
        }
      }
    }
  }
  write("\n")
}

///|
async fn legacy_ast_projection(
  source_file : @tsparser.Node,
  source : String,
) -> String {
  let output = StringBuilder::new()
  legacy_emit_ast_projection(
    source_file,
    source,
    chunk => output.write_string(chunk),
    width => output.write_string(legacy_indent(width)),
  )
  output.to_string()
}

///|
async fn legacy_compare_ast_projection(
  expected_path : String,
  source_file : @tsparser.Node,
  source : String,
) -> String? {
  try {
    let comparator = LegacyStreamComparator::open(expected_path)
    defer comparator.close()
    legacy_emit_ast_projection(
      source_file,
      source,
      chunk => comparator.write(chunk),
      width => comparator.spaces(width),
    )
    comparator.finish()
  } catch {
    error => Some("cannot compare expected stream: \{error}")
  } noraise {
    result => result
  }
}

///|
fn legacy_baseline_path(input : String, suffix : String) -> String {
  match input.rev_split_once(".") {
    Some((base, _)) => base.to_owned() + suffix
    None => input + suffix
  }
}

///|
fn legacy_base_name(path : String) -> String {
  match path.rev_split_once("/") {
    Some((_, name)) => name.to_owned()
    None => path
  }
}

///|
fn legacy_category_name(category : @tsparser.DiagnosticCategory) -> String {
  match category.to_int() {
    0 => "warning"
    1 => "error"
    2 => "suggestion"
    3 => "message"
    _ => abort("invalid diagnostic category")
  }
}

///|
fn legacy_parse_diagnostics(
  source_file : @tsparser.Node,
) -> ReadOnlyArray[@tsparser.Diagnostic] {
  match source_file.field("parseDiagnostics") {
    Some(@tsparser.DiagnosticList(Some(diagnostics))) => diagnostics
    _ => ReadOnlyArray::from_array([])
  }
}

///|
fn legacy_error_projection(
  input : String,
  source : String,
  source_file : @tsparser.Node,
) -> String {
  let output = StringBuilder::new()
  let starts = legacy_line_starts(source)
  let file_name = legacy_base_name(input)
  for diagnostic in legacy_parse_diagnostics(source_file) {
    let raw_start = diagnostic.start().unwrap_or(0)
    let start = legacy_clamp(raw_start, source.length())
    let line = legacy_line_index(starts, start)
    output.write_string(file_name)
    output.write_string("(")
    output.write_string((line + 1).to_string())
    output.write_string(",")
    output.write_string((start - starts[line] + 1).to_string())
    output.write_string("): ")
    output.write_string(legacy_category_name(diagnostic.category()))
    output.write_string(" TS")
    output.write_string(diagnostic.code().to_string())
    output.write_string(": ")
    output.write_string(diagnostic.message_text().flatten("\n"))
    output.write_string("\n")
  }
  output.to_string()
}
