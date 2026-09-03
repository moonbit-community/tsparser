///|
suberror DiffError {
  DiffError(String)
} derive(Eq, Debug)

///|
priv struct DiffOptions {
  manifest : String
  shard_index : Int
  shard_count : Int
  filter : String?
  max_failures : Int
  one_file : String?
  verify_shards : Bool
  synthetic_regression : Bool
  expected_stream : String?
  actual_stream : String?
  expected_legacy_ast : String?
  actual_legacy_ast : String?
}

///|
priv struct Difference {
  file : String
  path : String
  field : String
  expected : String
  actual : String
}

///|
fn Difference::render(self : Difference) -> String {
  "DIFF file=\{self.file} path=\{self.path} field=\{self.field} expected=\{self.expected} actual=\{self.actual}"
}
