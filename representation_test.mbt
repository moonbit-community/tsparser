///|
test "public representation surface is importable" {
  guard @tsparser.SyntaxKind::from_int(9) is Some(kind) else {
    fail("numeric literal kind must be public")
  }
  inspect(kind.to_int(), content="9")
  inspect(kind.runtime_name(), content="FirstLiteralToken")
  inspect(
    @tsparser.TransformFlags::has_computed_flags().bits(),
    content="2147483648",
  )
}
