///|
fn synthetic_regression_differences(file : String) -> Array[Difference] {
  [
    Difference::{
      file,
      path: "/statements/0/name",
      field: "kind.value",
      expected: "80",
      actual: "9",
    },
    Difference::{
      file,
      path: "/statements/0",
      field: "pos.raw_offset",
      expected: "0",
      actual: "1",
    },
    Difference::{
      file,
      path: "/statements/0",
      field: "child_edges",
      expected: "[name,initializer]",
      actual: "[initializer,name]",
    },
    Difference::{
      file,
      path: "/parse_diagnostics/0",
      field: "diagnostic.code",
      expected: "1005",
      actual: "1109",
    },
  ]
}
