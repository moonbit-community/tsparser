///|
test "should raise TS1003" {
  let source =
    #|(...) => {}
  debug_inspect(
    parse_program(source, name="").0[0],
    content=(
      #|Diagnostic("(1,5): error TS1003: Identifier expected.")
    ),
  )
}
