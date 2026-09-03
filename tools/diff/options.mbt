///|
fn parse_non_negative_decimal(
  name : String,
  value : String,
) -> Int raise DiffError {
  guard !value.is_empty() else {
    raise DiffError("\{name} requires a decimal integer")
  }
  let mut result = 0
  for code_unit in value.code_units() {
    let code = code_unit.to_int()
    guard code >= 48 && code <= 57 else {
      raise DiffError("\{name} requires a decimal integer, got \{value}")
    }
    let digit = code - 48
    guard result <= (0x7fffffff - digit) / 10 else {
      raise DiffError("\{name} is too large: \{value}")
    }
    result = result * 10 + digit
  }
  result
}

///|
fn take_option_value(
  args : Array[String],
  index : Int,
  name : String,
) -> String raise DiffError {
  guard index + 1 < args.length() else {
    raise DiffError("missing value for \{name}")
  }
  args[index + 1]
}

///|
fn parse_options(args : Array[String]) -> DiffOptions raise DiffError {
  let mut manifest : String? = None
  let mut shard_index = 0
  let mut shard_count = 1
  let mut filter : String? = None
  let mut max_failures = 20
  let mut one_file : String? = None
  let mut verify_shards = false
  let mut synthetic_regression = false
  let mut expected_stream : String? = None
  let mut actual_stream : String? = None
  let mut expected_legacy_ast : String? = None
  let mut actual_legacy_ast : String? = None
  let mut index = 1
  while index < args.length() {
    let argument = args[index]
    match argument {
      "--manifest" => {
        manifest = Some(take_option_value(args, index, argument))
        index += 2
      }
      "--shard-index" => {
        shard_index = parse_non_negative_decimal(
          argument,
          take_option_value(args, index, argument),
        )
        index += 2
      }
      "--shard-count" => {
        shard_count = parse_non_negative_decimal(
          argument,
          take_option_value(args, index, argument),
        )
        index += 2
      }
      "--filter" => {
        filter = Some(take_option_value(args, index, argument))
        index += 2
      }
      "--max-failures" => {
        max_failures = parse_non_negative_decimal(
          argument,
          take_option_value(args, index, argument),
        )
        index += 2
      }
      "--one-file" => {
        one_file = Some(take_option_value(args, index, argument))
        index += 2
      }
      "--verify-shards" => {
        verify_shards = true
        index += 1
      }
      "--synthetic-regression" => {
        synthetic_regression = true
        index += 1
      }
      "--expected-stream" => {
        expected_stream = Some(take_option_value(args, index, argument))
        index += 2
      }
      "--actual-stream" => {
        actual_stream = Some(take_option_value(args, index, argument))
        index += 2
      }
      "--expected-legacy-ast" => {
        expected_legacy_ast = Some(take_option_value(args, index, argument))
        index += 2
      }
      "--actual-legacy-ast" => {
        actual_legacy_ast = Some(take_option_value(args, index, argument))
        index += 2
      }
      "--help" | "-h" =>
        raise DiffError(
          "usage: diff --manifest PATH [--shard-index N --shard-count N] [--filter TEXT] [--max-failures N] [--one-file PATH] [--verify-shards] [--synthetic-regression] [--expected-stream PATH --actual-stream PATH] [--expected-legacy-ast PATH] [--actual-legacy-ast PATH]",
        )
      _ => raise DiffError("unknown argument: \{argument}")
    }
  }
  guard manifest is Some(manifest) else {
    raise DiffError("--manifest is required")
  }
  guard shard_count > 0 else {
    raise DiffError("--shard-count must be positive")
  }
  guard shard_index < shard_count else {
    raise DiffError(
      "--shard-index \{shard_index} is outside shard count \{shard_count}",
    )
  }
  guard max_failures > 0 else {
    raise DiffError("--max-failures must be positive")
  }
  guard (expected_stream is Some(_)) == (actual_stream is Some(_)) else {
    raise DiffError(
      "--expected-stream and --actual-stream must be provided together",
    )
  }
  DiffOptions::{
    manifest,
    shard_index,
    shard_count,
    filter,
    max_failures,
    one_file,
    verify_shards,
    synthetic_regression,
    expected_stream,
    actual_stream,
    expected_legacy_ast,
    actual_legacy_ast,
  }
}
