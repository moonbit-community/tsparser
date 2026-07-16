///|
fn stress_decimal(name : String, text : String) -> Int {
  guard !text.is_empty() else { abort("missing value for " + name) }
  let mut result = 0
  for code_unit in text.code_units() {
    let code = code_unit.to_int()
    guard code >= 48 && code <= 57 else {
      abort("invalid decimal for " + name + ": " + text)
    }
    result = result * 10 + code - 48
  }
  result
}

///|
fn stress_script_kind(path : String) -> @tsparser.ScriptKind {
  let lower = path.to_lower()
  if lower.has_suffix(".tsx") {
    @tsparser.ScriptKind::tsx()
  } else if lower.has_suffix(".jsx") {
    @tsparser.ScriptKind::jsx()
  } else if lower.has_suffix(".js") ||
    lower.has_suffix(".cjs") ||
    lower.has_suffix(".mjs") {
    @tsparser.ScriptKind::js()
  } else if lower.has_suffix(".json") {
    @tsparser.ScriptKind::json()
  } else {
    @tsparser.ScriptKind::ts()
  }
}

///|
async fn stress_read_source(path : String) -> String {
  let bytes = @fs.read_file(path).binary() catch {
    error => abort("cannot read " + path + ": \{error}")
  }
  @utf8.decode_lossy(bytes.view())
}

///|
fn stress_traverse(root : @tsparser.Node) -> Int {
  let stack = [root]
  let mut count = 0
  while !stack.is_empty() {
    let node = stack.pop().unwrap()
    count += 1
    ignore(
      @tsparser.for_each_child(
        node,
        fn(child) -> Unit? {
          stack.push(child)
          None
        },
        list_callback=fn(array) -> Unit? {
          for child in array.elements() {
            stack.push(child)
          }
          None
        },
      ),
    )
  }
  count
}

///|
async fn stress_parse_file(
  path : String,
  parents : Bool,
  traverse : Bool,
) -> Int {
  let source = stress_read_source(path)
  let file = @tsparser.create_source_file(
    path,
    source,
    language_version=@tsparser.ScriptTarget::latest(),
    script_kind=stress_script_kind(path),
    set_parent_nodes=parents,
  )
  if traverse {
    stress_traverse(file)
  } else {
    file.kind().to_int() + file.end()
  }
}

///|
async fn stress_manifest_inputs(path : String) -> Array[String] {
  let inputs : Array[String] = []
  for line in stress_read_source(path).split("\n") {
    if line.is_blank() {
      continue
    }
    let record = @json.parse(line) catch {
      error => abort("invalid stress manifest record: \{error}")
    }
    match record {
      Object(fields) =>
        match fields.get_from_string("input") {
          Some(String(input)) => inputs.push(input)
          _ => abort("stress manifest record is missing input")
        }
      _ => abort("stress manifest record must be an object")
    }
  }
  inputs.sort()
  inputs
}

///|
fn stress_argument(args : Array[String], name : String) -> String? {
  for index = 1; index + 1 < args.length(); index = index + 1 {
    if args[index] == name {
      return Some(args[index + 1])
    }
  }
  None
}

///|
fn stress_flag(args : Array[String], name : String) -> Bool {
  args.contains(name)
}

///|
async fn main {
  let args = @env.args()
  let parents = stress_argument(args, "--parents").unwrap_or("false") == "true"
  let traverse = stress_flag(args, "--traverse")
  let iterations = stress_decimal(
    "--iterations",
    stress_argument(args, "--iterations").unwrap_or("1"),
  )
  guard iterations > 0 else { abort("--iterations must be positive") }
  let mut checksum = 0
  match stress_argument(args, "--input") {
    Some(input) =>
      for _iteration = 0; _iteration < iterations; _iteration = _iteration + 1 {
        checksum = stress_parse_file(input, parents, traverse)
      }
    None =>
      match stress_argument(args, "--manifest") {
        Some(manifest) => {
          let inputs = stress_manifest_inputs(manifest)
          let progress_every = stress_decimal(
            "--progress-every",
            stress_argument(args, "--progress-every").unwrap_or("100"),
          )
          for iteration = 0; iteration < iterations; iteration = iteration + 1 {
            for index, input in inputs {
              checksum = stress_parse_file(input, parents, traverse)
              let completed = index + 1
              if progress_every > 0 && completed % progress_every == 0 {
                @stdio.stdout.write(
                  "PROGRESS iteration=\{iteration} completed=\{completed} checksum=\{checksum}\n",
                )
              }
            }
          }
        }
        None => abort("usage: stress --input PATH | --manifest PATH")
      }
  }
  @stdio.stdout.write("STRESS_OK checksum=\{checksum}\n")
}
