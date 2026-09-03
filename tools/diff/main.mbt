///|
async fn main {
  run_cli(@env.args()) catch {
    DiffError(message) => fail("error: \{message}")
    error => fail("error: \{error}")
  }
}

///|
async fn run_cli(args : Array[String]) -> Unit {
  guard @tsparser.SyntaxKind::from_int(9) is Some(_) else {
    raise DiffError("root package SyntaxKind import probe failed")
  }
  let options = parse_options(args)
  let inputs = read_manifest(options.manifest)
  if options.verify_shards {
    let counts = prove_shards(inputs, options.shard_count)
    let count_text = counts.map(fn(count) { count.to_string() }).join(",")
    println(
      "SHARD_PROOF total=\{inputs.length()} shard_count=\{options.shard_count} counts=\{count_text}",
    )
    return
  }
  if options.synthetic_regression {
    for difference in synthetic_regression_differences("synthetic.ts") {
      println(difference.render())
    }
    raise DiffError("synthetic regression differences found")
  }
  match (options.expected_stream, options.actual_stream) {
    (Some(expected_path), Some(actual_path)) => {
      let file = match options.one_file {
        Some(file) => file
        None => "<stream>"
      }
      let differences = compare_ndjson_files(
        expected_path,
        actual_path,
        file,
        options.max_failures,
      )
      for difference in differences {
        println(difference.render())
      }
      println("SUMMARY compared_streams=true failures=\{differences.length()}")
      if !differences.is_empty() {
        raise DiffError("stream differences found")
      }
      return
    }
    _ => ()
  }
  let selected = select_inputs(inputs, options)
  guard !selected.is_empty() else { raise DiffError("selection is empty") }
  guard options.expected_legacy_ast is None || selected.length() == 1 else {
    raise DiffError("--expected-legacy-ast requires a single selected input")
  }
  guard options.actual_legacy_ast is None || selected.length() == 1 else {
    raise DiffError("--actual-legacy-ast requires a single selected input")
  }
  let differences : Array[Difference] = []
  let mut compared = 0
  for input in selected {
    let remaining = options.max_failures - differences.length()
    if remaining <= 0 {
      break
    }
    for
      difference in compare_parser_input(
        input,
        options.expected_legacy_ast,
        options.actual_legacy_ast,
        remaining,
      ) {
      differences.push(difference)
    }
    compared += 1
  }
  for difference in differences {
    println(difference.render())
  }
  println(
    "SUMMARY selected=\{selected.length()} compared=\{compared} failures=\{differences.length()} truncated=\{compared < selected.length()}",
  )
  if !differences.is_empty() {
    raise DiffError("parser differences found")
  }
}
