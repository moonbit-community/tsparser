///|
async test "async line reader streams CRLF and LF lines" {
  let reader = LineReader::open("tools/diff/testdata/lines.txt")
  inspect(reader.next().map_line_for_test(), content="Line(\"alpha\")")
  inspect(reader.next().map_line_for_test(), content="Line(\"beta\")")
  inspect(reader.next().map_line_for_test(), content="Line(\"omega\")")
  inspect(reader.next().map_line_for_test(), content="End")
  assert_true(reader.close())
  inspect(
    reader.next().map_line_for_test(),
    content="Error(\"line reader is closed\")",
  )
}

///|
fn StreamItem::map_line_for_test(self : StreamItem) -> String {
  match self {
    Line(line) => "Line(\"\{line}\")"
    End => "End"
    ReadError(message) => "Error(\"\{message}\")"
  }
}

///|
test "manifest input parsing is structured JSON" {
  debug_inspect(
    parse_manifest_input("{\"input\":\"tsfiles/a\\u002ets\"}"),
    content="Ok(\"tsfiles/a.ts\")",
  )
  debug_inspect(
    parse_manifest_input("{\"input\":1}"),
    content="Err(\"manifest input must be a string\")",
  )
}

///|
test "manifest paths normalize and reject escapes" {
  inspect(normalize_manifest_path("./tsfiles\\a.ts"), content="tsfiles/a.ts")
  try normalize_manifest_path("../outside.ts") catch {
    DiffError(message) =>
      inspect(
        message,
        content="manifest path escapes the repository: ../outside.ts",
      )
  } noraise {
    _ => fail("expected an escaping path to fail")
  }
}

///|
test "sorted index sharding covers every input exactly once" {
  let inputs = ["a", "b", "c", "d", "e", "f", "g"]
  debug_inspect(prove_shards(inputs, 3), content="[3, 2, 2]")
}

///|
test "all required CLI parameters parse" {
  let options = parse_options([
    "diff", "--manifest", "manifest.jsonl", "--shard-index", "2", "--shard-count",
    "4", "--filter", "jsx", "--max-failures", "7", "--one-file", "tsfiles/a.ts",
  ])
  inspect(options.manifest, content="manifest.jsonl")
  inspect(options.shard_index, content="2")
  inspect(options.shard_count, content="4")
  match options.filter {
    Some(filter) => inspect(filter, content="jsx")
    None => fail("expected --filter")
  }
  inspect(options.max_failures, content="7")
  match options.one_file {
    Some(one_file) => inspect(one_file, content="tsfiles/a.ts")
    None => fail("expected --one-file")
  }
  assert_false(options.verify_shards)
  assert_false(options.synthetic_regression)
  assert_true(options.expected_stream is None)
  assert_true(options.actual_stream is None)
  assert_true(options.expected_legacy_ast is None)
  assert_true(options.actual_legacy_ast is None)
}

///|
test "legacy projection line map recognizes ECMAScript separators" {
  assert_eq(legacy_line_starts("a\u2028b\u2029c\r\nd\ne"), [0, 2, 4, 7, 9])
}

///|
async test "legacy stream comparator handles chunks indentation and EOF" {
  let exact = LegacyStreamComparator::open("tools/diff/testdata/stream.txt")
  exact.write("alpha")
  exact.spaces(2)
  exact.write("omega\n")
  assert_true(exact.finish() is None)

  let mismatch = LegacyStreamComparator::open("tools/diff/testdata/stream.txt")
  mismatch.write("alpha  omXga\n")
  match mismatch.finish() {
    Some(message) => assert_true(message.contains("byte mismatch at 9"))
    None => fail("expected a byte mismatch")
  }

  let short = LegacyStreamComparator::open("tools/diff/testdata/stream.txt")
  short.write("alpha  omega")
  match short.finish() {
    Some(message) => assert_true(message.contains("actual=-1"))
    None => fail("expected an end-of-stream mismatch")
  }
}

///|
async test "legacy stream comparator refills its bounded buffer" {
  let path = "_build/legacy_stream_comparator_refill.txt"
  let prefix = "a".repeat(legacy_stream_buffer_size - 3)
  let suffix = "tail"
  @fs.write_file(path, prefix + "XYZ" + suffix, create_mode=CreateOrTruncate)
  let exact = LegacyStreamComparator::open(path)
  exact.write(prefix)
  exact.write("XYZ")
  exact.write(suffix)
  assert_true(exact.finish() is None)
  let mismatch = LegacyStreamComparator::open(path)
  mismatch.write(prefix)
  mismatch.write("XYQ")
  match mismatch.finish() {
    Some(message) =>
      assert_true(
        message.contains("byte mismatch at \{legacy_stream_buffer_size - 1}"),
      )
    None => fail("expected a byte mismatch across the refill boundary")
  }
  @fs.remove(path)
}

///|
test "synthetic regression reports kind position child order and diagnostic" {
  let differences = synthetic_regression_differences("synthetic.ts")
  debug_inspect(
    differences.map(fn(difference) { difference.field }),
    content="[\"kind.value\", \"pos.raw_offset\", \"child_edges\", \"diagnostic.code\"]",
  )
  inspect(differences[0].path, content="/statements/0/name")
  inspect(differences[1].path, content="/statements/0")
  inspect(differences[2].path, content="/statements/0")
  inspect(differences[3].path, content="/parse_diagnostics/0")
}

///|
async test "NDJSON comparison streams and locates four semantic difference classes" {
  let differences = compare_ndjson_files(
    "tools/diff/testdata/expected.ndjson", "tools/diff/testdata/actual.ndjson", "fixture.ts",
    10,
  )
  debug_inspect(
    differences.map(fn(difference) { difference.field }),
    content="[\"kind.value\", \"pos.raw_offset\", \"child_edges\", \"diagnostic.code\"]",
  )
  inspect(differences[0].path, content="/statements/0/name")
  inspect(differences[3].path, content="/parse_diagnostics/0")
  inspect(differences[0].expected, content="80")
  inspect(differences[0].actual, content="9")
}

///|
async test "NDJSON comparison ignores JSON object member order" {
  assert_eq(
    compare_ndjson_files(
      "tools/diff/testdata/order-expected.ndjson", "tools/diff/testdata/order-actual.ndjson",
      "fixture.ts", 1,
    ).length(),
    0,
  )
}
