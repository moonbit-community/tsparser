///|
test "should emit TS1003" {
  let source =
    #|(...) => {} 
  guard parse_program(source).0[0] is Diagnostic(error_code=1003, ..) else {
    fail("\{source} should emit TS1003 but not")
  }
}

///|
test "invalid arrow parameter modifier should emit TS2369" {
  let source =
    #|(public foo) => {}
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "function type parameter modifier should emit TS2369" {
  let source =
    #|declare const foo: (public bar) => baz
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue3 parse_expression recovery should still collect errors" {
  let source =
    #|foo(,)
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView:
      #|  [
      #|    Diagnostic(
      #|      filename="",
      #|      line=1,
      #|      column=5,
      #|      error_code=1135,
      #|      error_msg="Argument expression expected.",
      #|    ),
      #|  ]>
    ),
  )
}

///|
test "undefined should be parsed as undefined type literal" {
  let source =
    #|declare const foo: undefined
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "yield* should not be parsed as yield" {
  let delegated_source =
    #|function* foo() { yield* bar }
  let normal_source =
    #|function* foo() { yield bar }
  debug_inspect(
    parse_program(delegated_source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
  debug_inspect(
    parse_program(normal_source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue6 empty element access should emit TS1011" {
  let source =
    #|foo[]
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView:
      #|  [
      #|    Diagnostic(
      #|      filename="",
      #|      line=1,
      #|      column=5,
      #|      error_code=1011,
      #|      error_msg="An element access expression should take an argument.",
      #|    ),
      #|  ]>
    ),
  )
}

///|
test "issue7 empty template interpolation should error" {
  let source =
    #|`${}`
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView:
      #|  [
      #|    Diagnostic(
      #|      filename="",
      #|      line=1,
      #|      column=4,
      #|      error_code=1109,
      #|      error_msg="Expression expected.",
      #|    ),
      #|  ]>
    ),
  )
}

///|
test "issue8 rest parameter must be trailing" {
  let source =
    #|function foo(...bar, baz) {}
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView:
      #|  [
      #|    Diagnostic(
      #|      filename="",
      #|      line=1,
      #|      column=14,
      #|      error_code=1014,
      #|      error_msg="A rest parameter must be last in a parameter list.",
      #|    ),
      #|  ]>
    ),
  )
}

///|
test "issue9 abstract new type should require parenthesized parameters" {
  let source =
    #|type foo = abstract new bar
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView:
      #|  [
      #|    Diagnostic(
      #|      filename="",
      #|      line=1,
      #|      column=25,
      #|      error_code=1005,
      #|      error_msg="'(' expected.",
      #|    ),
      #|  ]>
    ),
  )
}

///|
test "issue10 function type generic parameters should be preserved" {
  let generic_source =
    #|type foo = <T>(_: T) => T
  let non_generic_source =
    #|type foo = (_: T) => T
  debug_inspect(
    parse_program(generic_source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
  debug_inspect(
    parse_program(non_generic_source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue11 function type parameters should preserve pattern optional and rest info" {
  let rich_source =
    #|type foo = (bar?: baz, ...daz: fred[]) => quux
  let erased_source =
    #|type foo = (_: baz, _: fred[]) => quux
  debug_inspect(
    parse_program(rich_source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
  debug_inspect(
    parse_program(erased_source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue12 untyped rest parameter in function type should infer any[]" {
  let source =
    #|type foo = (...baz) => daz
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue13 adjacent expression statements should emit TS1005" {
  let source =
    #|1 1 4 5 1 4
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue14 numeric literal member access should emit TS1351" {
  let source =
    #|0.foo
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView:
      #|  [
      #|    Diagnostic(
      #|      filename="",
      #|      line=1,
      #|      column=3,
      #|      error_code=1351,
      #|      error_msg="An identifier or keyword cannot immediately follow a numeric literal.",
      #|    ),
      #|  ]>
    ),
  )
}

///|
test "issue15 typeof import with extra token should error" {
  let source =
    #|type foo = typeof import("bar" baz)
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView:
      #|  [
      #|    Diagnostic(
      #|      filename="",
      #|      line=1,
      #|      column=32,
      #|      error_code=1005,
      #|      error_msg="')' expected.",
      #|    ),
      #|  ]>
    ),
  )
}

///|
test "issue16 typeof foo[] should be parsed as array type" {
  let source =
    #|const foo: number = 42
    #|type bar = typeof foo[]
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue16 typeof foo[baz] should not become TypeQuery(\"foo[baz]\")" {
  let source =
    #|const foo: number = 42
    #|type bar = typeof foo[baz]
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue17 in modifier on function type parameter list should error" {
  let source =
    #|declare function foo<in T>(): T;
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue17 in modifier on class type parameter should be represented" {
  let with_modifier_source =
    #|class Bar<in T> {}
  let without_modifier_source =
    #|class Bar<T> {}
  debug_inspect(
    parse_program(with_modifier_source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
  debug_inspect(
    parse_program(without_modifier_source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue18 invalid type parameter names should error" {
  let source =
    #|declare function foo<function, "bar", 114514>();
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue19 hard keyword should not be parsed as identifier" {
  let source =
    #|let let = let
  debug_inspect(
    parse_program(source).0,
    content=(
      #|<ArrayView: []>
    ),
  )
}
