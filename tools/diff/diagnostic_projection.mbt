///|
fn diagnostic_json_int(value : Int) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
fn diagnostic_category_runtime_name(
  category : @tsparser.DiagnosticCategory,
) -> String {
  match category.to_int() {
    0 => "Warning"
    1 => "Error"
    2 => "Suggestion"
    3 => "Message"
    _ => abort("invalid diagnostic category")
  }
}

///|
fn diagnostic_chain_json(chain : @tsparser.DiagnosticMessageChain) -> Json {
  let children : Array[Json] = []
  match chain.next() {
    Some(next) =>
      for child in next {
        children.push(diagnostic_chain_json(child))
      }
    None => ()
  }
  Json::object(
    Map([
      ("kind", Json::string("chain")),
      ("message_text", Json::string(chain.message_text())),
      ("category", diagnostic_json_int(chain.category().to_int())),
      (
        "category_name",
        Json::string(diagnostic_category_runtime_name(chain.category())),
      ),
      ("code", diagnostic_json_int(chain.code())),
      ("next", Json::array(children)),
    ]),
  )
}

///|
fn diagnostic_message_json(message : @tsparser.DiagnosticMessageText) -> Json {
  match message {
    @tsparser.DiagnosticTextValue(text) =>
      Json::object(
        Map([("kind", Json::string("text")), ("text", Json::string(text))]),
      )
    @tsparser.DiagnosticChainValue(chain) => diagnostic_chain_json(chain)
  }
}

///|
fn diagnostic_location_json(
  raw_offset : Int,
  source : String,
  starts : Array[Int],
) -> Json {
  let clipped = legacy_clamp(raw_offset, source.length())
  let line = legacy_line_index(starts, clipped)
  Json::object(
    Map([
      ("raw_offset", diagnostic_json_int(raw_offset)),
      ("clipped_offset", diagnostic_json_int(clipped)),
      ("line", diagnostic_json_int(line + 1)),
      ("column", diagnostic_json_int(clipped - starts[line] + 1)),
    ]),
  )
}

///|
fn diagnostic_json(
  diagnostic : @tsparser.Diagnostic,
  fallback_file_name : String,
  source : String,
  starts : Array[Int],
) -> Json {
  let start = diagnostic.start().unwrap_or(0)
  let length = diagnostic.length().unwrap_or(0)
  let fields : Map[String, Json] = Map([
    (
      "file_name",
      match diagnostic.file_name() {
        Some(file_name) => Json::string(file_name)
        None => Json::string(fallback_file_name)
      },
    ),
    ("start", diagnostic_json_int(start)),
    ("length", diagnostic_json_int(length)),
    ("category", diagnostic_json_int(diagnostic.category().to_int())),
    (
      "category_name",
      Json::string(diagnostic_category_runtime_name(diagnostic.category())),
    ),
    ("code", diagnostic_json_int(diagnostic.code())),
    ("message_text", diagnostic_message_json(diagnostic.message_text())),
    ("location", diagnostic_location_json(start, source, starts)),
  ])
  match diagnostic.reports_unnecessary() {
    Some(value) => fields["reports_unnecessary"] = Json::boolean(value)
    None => ()
  }
  match diagnostic.reports_deprecated() {
    Some(value) => fields["reports_deprecated"] = Json::boolean(value)
    None => ()
  }
  match diagnostic.related_information() {
    Some(related) => {
      let items : Array[Json] = []
      for item in related {
        items.push(diagnostic_json(item, fallback_file_name, source, starts))
      }
      fields["related_information"] = Json::array(items)
    }
    None => ()
  }
  Json::object(fields)
}

///|
fn source_file_jsdoc_diagnostics(
  source_file : @tsparser.Node,
) -> ReadOnlyArray[@tsparser.Diagnostic] {
  match source_file.field("jsDocDiagnostics") {
    Some(@tsparser.DiagnosticList(Some(diagnostics))) => diagnostics
    _ => ReadOnlyArray::from_array([])
  }
}

///|
fn diagnostic_records(
  input : String,
  source : String,
  source_file : @tsparser.Node,
) -> Array[Json] {
  let records : Array[Json] = []
  let starts = legacy_line_starts(source)
  let file_name = input
  let parse_diagnostics = legacy_parse_diagnostics(source_file)
  for index = 0; index < parse_diagnostics.length(); index = index + 1 {
    records.push(
      Json::object(
        Map([
          ("record", Json::string("parse_diagnostic")),
          ("index", diagnostic_json_int(index)),
          (
            "diagnostic",
            diagnostic_json(parse_diagnostics[index], file_name, source, starts),
          ),
        ]),
      ),
    )
  }
  let jsdoc_diagnostics = source_file_jsdoc_diagnostics(source_file)
  for index = 0; index < jsdoc_diagnostics.length(); index = index + 1 {
    records.push(
      Json::object(
        Map([
          ("record", Json::string("jsdoc_diagnostic")),
          ("index", diagnostic_json_int(index)),
          (
            "diagnostic",
            diagnostic_json(jsdoc_diagnostics[index], file_name, source, starts),
          ),
        ]),
      ),
    )
  }
  records
}

///|
async fn compare_diagnostic_reference(
  expected_path : String,
  input : String,
  actual : Array[Json],
  max_failures : Int,
) -> Array[Difference] {
  let reader = LineReader::open(expected_path)
  let differences : Array[Difference] = []
  let mut index = 0
  let mut finished = false
  while !finished && differences.length() < max_failures {
    let expected_item = reader.next()
    if index >= actual.length() {
      match expected_item {
        End => finished = true
        ReadError(message) => {
          ignore(reader.close())
          raise DiffError("cannot read \{expected_path}: \{message}")
        }
        Line(expected_line) => {
          differences.push(Difference::{
            file: input,
            path: "/diagnostics/\{index}",
            field: "stream.length",
            expected: clip_report(expected_line),
            actual: "<end-of-stream>",
          })
          finished = true
        }
      }
    } else {
      match expected_item {
        End => {
          differences.push(Difference::{
            file: input,
            path: "/diagnostics/\{index}",
            field: "stream.length",
            expected: "<end-of-stream>",
            actual: clip_report(actual[index].stringify()),
          })
          finished = true
        }
        ReadError(message) => {
          ignore(reader.close())
          raise DiffError("cannot read \{expected_path}: \{message}")
        }
        Line(expected_line) => {
          let expected = parse_ndjson_record(expected_line)
          match expected {
            Ok(expected) =>
              if expected != actual[index] {
                differences.push(
                  difference_for_records(input, index, expected, actual[index]),
                )
              }
            Err(message) => raise DiffError("\{expected_path}: \{message}")
          }
          index += 1
        }
      }
    }
  }
  guard reader.close() else { raise DiffError("cannot close \{expected_path}") }
  differences
}
