///|
async fn diff_read_text(path : String) -> String {
  @fs.read_file(path).text() catch {
    error => raise DiffError("cannot read \{path}: \{error}")
  }
}

///|
async fn diff_read_source(path : String) -> String {
  let bytes = @fs.read_file(path).binary() catch {
    error => raise DiffError("cannot read \{path}: \{error}")
  }
  @utf8.decode_lossy(bytes.view())
}

///|
fn diff_script_kind(input : String) -> @tsparser.ScriptKind {
  if input.to_lower().has_suffix(".tsx") {
    @tsparser.ScriptKind::tsx()
  } else {
    @tsparser.ScriptKind::ts()
  }
}

///|
fn diagnostic_reference_path(input : String) -> String {
  let base = legacy_base_name(input)
  "references/diagnostics/" + legacy_baseline_path(base, ".jsonl")
}

///|
fn first_text_mismatch(expected : String, actual : String) -> Int {
  let limit = Int::min(expected.length(), actual.length())
  for index = 0; index < limit; index = index + 1 {
    if expected[index] != actual[index] {
      return index
    }
  }
  limit
}

///|
fn mismatch_excerpt(text : String, position : Int) -> String {
  let start = Int::max(0, position - 40)
  let end = Int::min(text.length(), position + 80)
  clip_report(legacy_json_string(text.unsafe_substring(start~, end~)))
}

///|
async fn compare_parser_input(
  input : String,
  expected_legacy_override : String?,
  actual_legacy_output : String?,
  max_failures : Int,
) -> Array[Difference] {
  let source = diff_read_source(input)
  let source_file = @tsparser.create_source_file(
    input,
    source,
    language_version=@tsparser.ScriptTarget::latest(),
    script_kind=diff_script_kind(input),
  )
  let differences : Array[Difference] = []
  let expected_ast_path = match expected_legacy_override {
    Some(path) => path
    None => legacy_baseline_path(input, ".ast.json")
  }
  let expected_ast_exists = @fs.exists(expected_ast_path)
  let actual_ast = if actual_legacy_output is Some(_) {
    Some(legacy_ast_projection(source_file, source))
  } else {
    None
  }
  match (actual_legacy_output, actual_ast) {
    (Some(path), Some(actual_ast)) =>
      @fs.write_file(path, actual_ast, create_mode=CreateOrTruncate) catch {
        error => raise DiffError("cannot write \{path}: \{error}")
      }
    _ => ()
  }
  if expected_ast_exists {
    match actual_ast {
      Some(actual_ast) => {
        let expected_ast = diff_read_text(expected_ast_path)
        if expected_ast != actual_ast {
          let mismatch = first_text_mismatch(expected_ast, actual_ast)
          differences.push(Difference::{
            file: input,
            path: "/",
            field: "legacy_ast.byte_\{mismatch}",
            expected: mismatch_excerpt(expected_ast, mismatch),
            actual: mismatch_excerpt(actual_ast, mismatch),
          })
        }
      }
      None =>
        match
          legacy_compare_ast_projection(expected_ast_path, source_file, source) {
          Some(message) =>
            differences.push(Difference::{
              file: input,
              path: "/",
              field: "legacy_ast.stream",
              expected: "byte-for-byte equality",
              actual: message,
            })
          None => ()
        }
    }
  }
  if differences.length() < max_failures {
    let expected_errors_path = legacy_baseline_path(input, ".errors.txt")
    let expected_errors = diff_read_text(expected_errors_path)
    let actual_errors = legacy_error_projection(input, source, source_file)
    if expected_errors != actual_errors {
      let mismatch = first_text_mismatch(expected_errors, actual_errors)
      differences.push(Difference::{
        file: input,
        path: "/parse_diagnostics",
        field: "legacy_errors.byte_\{mismatch}",
        expected: mismatch_excerpt(expected_errors, mismatch),
        actual: mismatch_excerpt(actual_errors, mismatch),
      })
    }
  }
  if differences.length() < max_failures {
    for
      difference in compare_diagnostic_reference(
        diagnostic_reference_path(input),
        input,
        diagnostic_records(input, source, source_file),
        max_failures - differences.length(),
      ) {
      differences.push(difference)
    }
  }
  differences
}
