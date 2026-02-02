///|
// test "gen" {
//   let tsfiles = @fs.read_dir("./tsfiles")
//   let buf = StringBuilder::new()
//   for file in tsfiles {
//     if file.has_suffix(".ts") || file.has_suffix(".tsx") {
//       let test_block =
//         $|test "\{file}" {
//         $|  check_tsfile("\{file}")
//         #|}
//         #|
//       buf.write_string(test_block)
//     }
//   }
//   @fs.write_string_to_file("./tsfiles_test", buf.to_string())
// }

///|
fn check_tsfile(filename : String) -> Unit raise {
  let basename = if filename.chop_suffix(".ts") is Some(base) {
    base
  } else if filename.chop_suffix(".tsx") is Some(base) {
    base
  } else {
    fail("\{filename} not a typescript file")
  }
  if @fs.path_exists("./tsfiles/\{basename}.errors.txt") {
    let errors = @fs.read_file_to_string("./tsfiles/\{basename}.errors.txt")
    if errors lexmatch? (_, "error TS1[[:digit:]]{3}", _) {
      return // contain syntax error, just return
    }
  }
  let bytes = @fs.read_file_to_bytes("./tsfiles/\{filename}")
  if filename.has_suffix(".tsx") {
    ignore(parse_program_bytes_with_jsx(bytes, true))
  } else {
    ignore(parse_program_bytes(bytes))
  }
}
