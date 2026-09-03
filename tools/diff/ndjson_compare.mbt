///|
fn json_string_field(fields : Map[String, Json], key : String) -> String? {
  match fields.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn json_index_field(fields : Map[String, Json], key : String) -> String? {
  match fields.get(key) {
    Some(Number(_, repr=Some(repr))) => Some(repr)
    Some(Number(value, repr=None)) => Some("\{value}")
    _ => None
  }
}

///|
fn parse_ndjson_record(line : String) -> Result[Json, String] {
  try @json.parse(line) catch {
    error => Err("invalid NDJSON record: \{error}")
  } noraise {
    value => Ok(value)
  }
}

///|
fn json_semantically_equal(expected : Json, actual : Json) -> Bool {
  match (expected, actual) {
    (Object(expected_fields), Object(actual_fields)) => {
      if expected_fields.length() != actual_fields.length() {
        return false
      }
      for key, expected_value in expected_fields {
        match actual_fields.get(key) {
          Some(actual_value) =>
            if !json_semantically_equal(expected_value, actual_value) {
              return false
            }
          None => return false
        }
      }
      true
    }
    (Array(expected_items), Array(actual_items)) => {
      if expected_items.length() != actual_items.length() {
        return false
      }
      for index = 0; index < expected_items.length(); index = index + 1 {
        if !json_semantically_equal(expected_items[index], actual_items[index]) {
          return false
        }
      }
      true
    }
    _ => expected == actual
  }
}

///|
fn record_path(record : Json, line_index : Int) -> String {
  match record {
    Object(fields) =>
      match json_string_field(fields, "path") {
        Some(path) => path
        None => {
          let record_name = match json_string_field(fields, "record") {
            Some(name) => name
            None => "record"
          }
          let index = match json_index_field(fields, "index") {
            Some(index) => index
            None => line_index.to_string()
          }
          "/\{record_name}s/\{index}"
        }
      }
    _ => "/records/\{line_index}"
  }
}

///|
fn first_map_difference(
  expected : Map[String, Json],
  actual : Map[String, Json],
  preferred : Array[String],
) -> String? {
  for key in preferred {
    match (expected.get(key), actual.get(key)) {
      (Some(expected), Some(actual)) =>
        if !json_semantically_equal(expected, actual) {
          return Some(key)
        }
      (None, None) => ()
      _ => return Some(key)
    }
  }
  let keys : Array[String] = []
  for key, _value in expected {
    if !keys.contains(key) {
      keys.push(key)
    }
  }
  for key, _value in actual {
    if !keys.contains(key) {
      keys.push(key)
    }
  }
  keys.sort()
  for key in keys {
    match (expected.get(key), actual.get(key)) {
      (Some(expected), Some(actual)) =>
        if !json_semantically_equal(expected, actual) {
          return Some(key)
        }
      (None, None) => ()
      _ => return Some(key)
    }
  }
  None
}

///|
fn nested_difference(
  expected : Json?,
  actual : Json?,
  field : String,
) -> String {
  match (expected, actual) {
    (Some(Object(expected_fields)), Some(Object(actual_fields))) => {
      let preferred = match field {
        "kind" =>
          [
            "value", "runtime_reverse_name", "declaration_names", "classification_markers",
          ]
        "pos" | "end" => ["raw_offset", "clipped_offset", "line", "column"]
        "diagnostic" =>
          [
            "file_name", "start", "length", "category", "code", "message_text", "related_information",
          ]
        _ => []
      }
      match first_map_difference(expected_fields, actual_fields, preferred) {
        Some(nested) => "\{field}.\{nested}"
        None => field
      }
    }
    _ => field
  }
}

///|
fn first_record_field(expected : Json, actual : Json) -> String {
  match (expected, actual) {
    (Object(expected_fields), Object(actual_fields)) => {
      let record_name = match json_string_field(expected_fields, "record") {
        Some(name) => name
        None => ""
      }
      let preferred = if record_name.contains("diagnostic") {
        ["record", "index", "diagnostic"]
      } else {
        [
          "record", "path", "kind", "pos", "end", "flags", "transform_flags", "child_edges",
          "fields",
        ]
      }
      match first_map_difference(expected_fields, actual_fields, preferred) {
        Some(field) => {
          let nested = nested_difference(
            expected_fields.get(field),
            actual_fields.get(field),
            field,
          )
          nested
        }
        None => "record"
      }
    }
    _ => "record"
  }
}

///|
fn json_field_value(record : Json, field : String) -> Json? {
  match record {
    Object(fields) => {
      if field.strip_prefix("diagnostic.") is Some(diagnostic_field) {
        return match fields.get_from_string("diagnostic") {
          Some(Object(diagnostic)) =>
            diagnostic.get_from_string(diagnostic_field)
          _ => None
        }
      }
      let bare_field = field
      match bare_field.split_once(".") {
        Some((outer, inner)) =>
          match fields.get_from_string(outer) {
            Some(Object(nested)) => nested.get_from_string(inner)
            _ => None
          }
        None => fields.get(bare_field)
      }
    }
    _ => None
  }
}

///|
fn clip_report(value : String) -> String {
  let max_chars = 240
  if !value.char_length_ge(max_chars + 1) {
    return value
  }
  match value.offset_of_nth_char(max_chars) {
    Some(end) => value.unsafe_substring(start=0, end~) + "…"
    None => value
  }
}

///|
fn parse_result_report(result : Result[Json, String]) -> String {
  match result {
    Ok(_) => "<valid JSON>"
    Err(message) => message
  }
}

///|
fn json_report_value(value : Json?) -> String {
  match value {
    Some(value) => clip_report(value.stringify())
    None => "<missing>"
  }
}

///|
fn difference_for_records(
  file : String,
  line_index : Int,
  expected : Json,
  actual : Json,
) -> Difference {
  let field = first_record_field(expected, actual)
  Difference::{
    file,
    path: record_path(expected, line_index),
    field,
    expected: json_report_value(json_field_value(expected, field)),
    actual: json_report_value(json_field_value(actual, field)),
  }
}

///|
async fn compare_ndjson_files(
  expected_path : String,
  actual_path : String,
  file : String,
  max_failures : Int,
) -> Array[Difference] {
  guard max_failures > 0 else {
    raise DiffError("max failures must be positive")
  }
  let expected_reader = LineReader::open(expected_path)
  let actual_reader = LineReader::open(actual_path)
  let differences : Array[Difference] = []
  let mut line_index = 0
  let mut finished = false
  while !finished && differences.length() < max_failures {
    let expected_item = expected_reader.next()
    let actual_item = actual_reader.next()
    match (expected_item, actual_item) {
      (End, End) => finished = true
      (ReadError(message), _) => {
        ignore(expected_reader.close())
        ignore(actual_reader.close())
        raise DiffError("cannot read \{expected_path}: \{message}")
      }
      (_, ReadError(message)) => {
        ignore(expected_reader.close())
        ignore(actual_reader.close())
        raise DiffError("cannot read \{actual_path}: \{message}")
      }
      (End, Line(actual_line)) => {
        differences.push(Difference::{
          file,
          path: "/records/\{line_index}",
          field: "stream.length",
          expected: "<end-of-stream>",
          actual: clip_report(actual_line),
        })
        finished = true
      }
      (Line(expected_line), End) => {
        differences.push(Difference::{
          file,
          path: "/records/\{line_index}",
          field: "stream.length",
          expected: clip_report(expected_line),
          actual: "<end-of-stream>",
        })
        finished = true
      }
      (Line(expected_line), Line(actual_line)) => {
        if expected_line != actual_line {
          match
            (
              parse_ndjson_record(expected_line),
              parse_ndjson_record(actual_line),
            ) {
            (Ok(expected), Ok(actual)) =>
              if !json_semantically_equal(expected, actual) {
                differences.push(
                  difference_for_records(file, line_index, expected, actual),
                )
              }
            (expected_result, actual_result) =>
              differences.push(Difference::{
                file,
                path: "/records/\{line_index}",
                field: "ndjson",
                expected: clip_report(parse_result_report(expected_result)),
                actual: clip_report(parse_result_report(actual_result)),
              })
          }
        }
        line_index += 1
      }
    }
  }
  guard expected_reader.close() else {
    ignore(actual_reader.close())
    raise DiffError("cannot close \{expected_path}")
  }
  guard actual_reader.close() else {
    raise DiffError("cannot close \{actual_path}")
  }
  differences
}
