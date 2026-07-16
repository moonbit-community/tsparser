///|
fn normalize_manifest_path(path : String) -> String raise DiffError {
  let normalized = path.replace_all(old="\\", new="/")
  let normalized = match normalized.strip_prefix("./") {
    Some(rest) => rest.to_owned()
    None => normalized
  }
  guard !normalized.is_empty() else {
    raise DiffError("manifest path is empty")
  }
  guard !normalized.has_prefix("/") else {
    raise DiffError("manifest path must be relative: \{path}")
  }
  let segments = normalized.split("/")
  let result : Array[String] = []
  for segment in segments {
    match segment {
      "" | "." => ()
      ".." => raise DiffError("manifest path escapes the repository: \{path}")
      value => result.push(value.to_owned())
    }
  }
  guard !result.is_empty() else { raise DiffError("manifest path is empty") }
  result.join("/")
}

///|
fn parse_manifest_input(line : String) -> Result[String, String] {
  try @json.parse(line) catch {
    error => Err("invalid manifest JSON: \{error}")
  } noraise {
    Object(fields) =>
      match fields.get_from_string("input") {
        Some(String(input)) => Ok(input)
        Some(_) => Err("manifest input must be a string")
        None => Err("manifest record is missing input")
      }
    _ => Err("manifest record must be a JSON object")
  }
}

///|
async fn read_manifest(path : String) -> Array[String] {
  let reader = LineReader::open(path)
  let inputs : Array[String] = []
  let seen : Map[String, Int] = Map([])
  let mut line_number = 0
  let mut finished = false
  while !finished {
    match reader.next() {
      End => finished = true
      ReadError(message) => {
        ignore(reader.close())
        raise DiffError("cannot read \{path}: \{message}")
      }
      Line(line) => {
        line_number += 1
        if !line.is_blank() {
          let input = match parse_manifest_input(line) {
            Ok(value) => value
            Err(message) => {
              ignore(reader.close())
              raise DiffError("\{path}:\{line_number}: \{message}")
            }
          }
          let normalized = normalize_manifest_path(input)
          match seen.get(normalized) {
            Some(previous_line) => {
              ignore(reader.close())
              raise DiffError(
                "duplicate manifest input \{normalized} at lines \{previous_line} and \{line_number}",
              )
            }
            None => {
              seen[normalized] = line_number
              inputs.push(normalized)
            }
          }
        }
      }
    }
  }
  guard reader.close() else { raise DiffError("cannot close manifest \{path}") }
  inputs.sort()
  inputs
}

///|
fn select_inputs(
  inputs : Array[String],
  options : DiffOptions,
) -> Array[String] raise DiffError {
  let candidates = match options.one_file {
    Some(one_file) => {
      let normalized = normalize_manifest_path(one_file)
      guard inputs.contains(normalized) else {
        raise DiffError(
          "--one-file is not present in the manifest: \{normalized}",
        )
      }
      [normalized]
    }
    None =>
      inputs.filter(fn(path) {
        match options.filter {
          Some(filter) => path.contains(filter)
          None => true
        }
      })
  }
  if options.one_file is Some(_) {
    return candidates
  }
  let selected : Array[String] = []
  candidates.eachi(fn(index, path) {
    if index % options.shard_count == options.shard_index {
      selected.push(path)
    }
  })
  selected
}

///|
fn prove_shards(
  inputs : Array[String],
  shard_count : Int,
) -> Array[Int] raise DiffError {
  guard shard_count > 0 else { raise DiffError("shard count must be positive") }
  let counts = Array::make(shard_count, 0)
  let assignments = Array::make(inputs.length(), 0)
  inputs.eachi(fn(index, _path) {
    let shard = index % shard_count
    counts[shard] = counts[shard] + 1
    assignments[index] = assignments[index] + 1
  })
  assignments.eachi((index, count) => {
    guard count == 1 else {
      raise DiffError(
        "manifest index \{index} belongs to \{count} shards instead of exactly one",
      )
    }
  })
  let mut total = 0
  for count in counts {
    total += count
  }
  guard total == inputs.length() else {
    raise DiffError(
      "shard proof assigned \{total} entries from a manifest of \{inputs.length()}",
    )
  }
  counts
}
