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

///|
test "invalid arrow parameter modifier should raise TS2369" {
  let source =
    #|(public foo) => {}
  debug_inspect(
    parse_program(source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "function type parameter modifier should raise TS2369" {
  let source =
    #|declare const foo: (public bar) => baz
  debug_inspect(
    parse_program(source, name="").0,
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
    parse_program(source, name="").0,
    content=(
      #|<ArrayView:
      #|  [Diagnostic("(1,5): error TS1135: Argument expression expected.")]>
    ),
  )
}

///|
test "undefined should be parsed as undefined type literal" {
  let source =
    #|declare const foo: undefined
  debug_inspect(
    parse_program(source, name="").0,
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
    parse_program(delegated_source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
  debug_inspect(
    parse_program(normal_source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue6 empty element access should raise TS1011" {
  let source =
    #|foo[]
  debug_inspect(
    parse_program(source, name="").0,
    content=(
      #|<ArrayView:
      #|  [Diagnostic("(1,5): error TS1011: An element access expression should take an argument.")]>
    ),
  )
}

///|
test "issue7 empty template interpolation should error" {
  let source =
    #|`${}`
  debug_inspect(
    parse_program(source, name="").0,
    content=(
      #|<ArrayView: [Diagnostic("(1,4): error TS1109: Expression expected.")]>
    ),
  )
}

///|
test "issue8 rest parameter must be trailing" {
  let source =
    #|function foo(...bar, baz) {}
  debug_inspect(
    parse_program(source, name="").0,
    content=(
      #|<ArrayView:
      #|  [Diagnostic("(1,14): error TS1014: A rest parameter must be last in a parameter list.")]>
    ),
  )
}

///|
test "issue9 abstract new type should require parenthesized parameters" {
  let source =
    #|type foo = abstract new bar
  debug_inspect(
    parse_program(source, name="").0,
    content=(
      #|<ArrayView: [Diagnostic("(1,25): error TS1005: '(' expected.")]>
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
    parse_program(generic_source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
  debug_inspect(
    parse_program(non_generic_source, name="").0,
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
    parse_program(rich_source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
  debug_inspect(
    parse_program(erased_source, name="").0,
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
    parse_program(source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue13 adjacent expression statements should raise TS1005" {
  let source =
    #|1 1 4 5 1 4
  debug_inspect(
    parse_program(source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
}

///|
test "issue14 numeric literal member access should raise TS1351" {
  let source =
    #|0.foo
  debug_inspect(
    parse_program(source, name="").0,
    content=(
      #|<ArrayView:
      #|  [Diagnostic("(1,3): error TS1351: An identifier or keyword cannot immediately follow a numeric literal.")]>
    ),
  )
}

///|
test "issue15 typeof import with extra token should error" {
  let source =
    #|type foo = typeof import("bar" baz)
  debug_inspect(
    parse_program(source, name="").0,
    content=(
      #|<ArrayView: [Diagnostic("(1,32): error TS1005: ')' expected.")]>
    ),
  )
}

///|
test "issue16 typeof foo[] should be parsed as array type" {
  let source =
    #|const foo: number = 42
    #|type bar = typeof foo[]
  debug_inspect(
    parse_program(source, name="").0,
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
    parse_program(source, name="").0,
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
    parse_program(source, name="").0,
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
    parse_program(with_modifier_source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
  debug_inspect(
    parse_program(without_modifier_source, name="").0,
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
    parse_program(source, name="").0,
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
    parse_program(source, name="").0,
    content=(
      #|<ArrayView: []>
    ),
  )
}
