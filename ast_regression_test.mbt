///|
test "as and satisfies should build dedicated expr nodes" {
  let source =
    #|const asserted = value as Foo
    #|const checked = value satisfies Foo
    #|const literal = { answer: 42 } as const
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  {
                    kind: As(
                      {
                        expr: { kind: Ident("value"), .. },
                        type_ann: { kind: Ident("Foo"), .. },
                      }
                    ),
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  {
                    kind: Satisfies(
                      {
                        expr: { kind: Ident("value"), .. },
                        type_ann: { kind: Ident("Foo"), .. },
                      }
                    ),
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  {
                    kind: As(
                      {
                        expr: { kind: Object(_), .. },
                        type_ann: { kind: Ident("const"), .. },
                      }
                    ),
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
    ]
}

///|
test "decorators should be stored on class and class members" {
  let source =
    #|// @experimentalDecorators: true
    #|@sealed
    #|class Box {
    #|  @logged
    #|  value: string
    #|}
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: ClassDecl(
          {
            decorators: [{ kind: Ident("sealed"), .. }],
            members: [
              {
                decorators: [{ kind: Ident("logged"), .. }],
                kind: Field(Ident("value"), Some(_), None),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
    ]
}

///|
test "class static block should become a class member" {
  let source =
    #|class Counter {
    #|  static value = 0
    #|  static {
    #|    this.value = 1
    #|  }
    #|}
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: ClassDecl(
          {
            members: [
              {
                kind: Field(Ident("value"), None, Some(_)),
                is_static: true,
                ..,
              },
              {
                kind: StaticBlock({ stmts: [{ kind: ExprStmt(_), .. }], .. }),
                is_static: true,
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
    ]
}

///|
test "private identifiers should have dedicated token and ast nodes" {
  let source =
    #|class Box {
    #|  #value = 1
    #|  has(obj: object) {
    #|    return #value in obj
    #|  }
    #|  read() {
    #|    return this.#value
    #|  }
    #|}
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: ClassDecl(
          {
            members: [
              { kind: Field(Private("value"), None, Some(_)), .. },
              {
                kind: Method(
                  Ident("has"),
                  _,
                  None,
                  {
                    stmts: [
                      {
                        kind: Return(
                          Some(
                            {
                              kind: Binary(
                                {
                                  op: In,
                                  left: { kind: PrivateIdent("value"), .. },
                                  right: { kind: Ident("obj"), .. },
                                }
                              ),
                              ..,
                            }
                          )
                        ),
                        ..,
                      },
                    ],
                    ..,
                  }
                ),
                ..,
              },
              {
                kind: Method(
                  Ident("read"),
                  _,
                  None,
                  {
                    stmts: [
                      {
                        kind: Return(
                          Some(
                            {
                              kind: Member(
                                {
                                  object: { kind: This, .. },
                                  property: Private("value"),
                                  computed: false,
                                  optional: false,
                                }
                              ),
                              ..,
                            }
                          )
                        ),
                        ..,
                      },
                    ],
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
    ]
}

///|
test "type members should preserve structured names" {
  let source =
    #|interface Shape {
    #|  "label"?: string
    #|  0: number
    #|  (): void
    #|  new (): Shape
    #|}
    #|type Boxify<T> = { readonly [K in keyof T as K]?: T[K] }
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: InterfaceDecl(
          {
            members: [
              { name: Named(String("label")), optional: true, .. },
              { name: Named(Number("0")), optional: false, .. },
              { name: Call, optional: false, .. },
              { name: Construct, optional: false, .. },
            ],
            ..,
          }
        ),
        ..,
      },
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: MappedType(
                {
                  readonly_modifier: Some(Add),
                  type_param_name: "K",
                  source_type: { kind: TypeOperator("keyof", _), .. },
                  name_type: Some({ kind: Ident("K"), .. }),
                  optional_modifier: Some(Add),
                  value_type: Some({ kind: IndexAccess(_, _), .. }),
                }
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
    ]
}

///|
test "structured type nodes should preserve dedicated kinds" {
  let source =
    #|type Greeting<T extends string> = `hello ${T}!`
    #|type Loader = import("pkg").Loader<string>
    #|type Unwrap<T> = T extends Promise<infer U> ? U : T
    #|type Factory = abstract new <T>(value: T) => Box<T>
    #|type Wrapped = (Foo | Bar)[]
  let (errors, program) = parse_program(source)
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: TemplateLiteral(
                { quasis: ["hello ", "!"], types: [{ kind: Ident("T"), .. }] }
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: ImportType(
                {
                  argument: "pkg",
                  attributes: None,
                  qualifier: Some("Loader"),
                  type_args: [{ kind: Ident("string"), .. }],
                  is_typeof: false,
                }
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: Conditional(
                _,
                {
                  kind: Generic(
                    { kind: Ident("Promise"), .. },
                    [{ kind: InferType({ type_param: { name: "U", .. } }), .. }]
                  ),
                  ..,
                },
                { kind: Ident("U"), .. },
                { kind: Ident("T"), .. }
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: Constructor(
                {
                  is_abstract: true,
                  type_params: [{ name: "T", .. }],
                  params: [{ type_ann: Some({ kind: Ident("T"), .. }), .. }],
                  return_type: {
                    kind: Generic(
                      { kind: Ident("Box"), .. },
                      [{ kind: Ident("T"), .. }]
                    ),
                    ..,
                  },
                }
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
      {
        kind: TypeAliasDecl(
          {
            value: {
              kind: Array(
                {
                  kind: Parenthesized(
                    {
                      inner: {
                        kind: Union(
                          [
                            { kind: Ident("Foo"), .. },
                            { kind: Ident("Bar"), .. },
                          ]
                        ),
                        ..,
                      },
                    }
                  ),
                  ..,
                }
              ),
              ..,
            },
            ..,
          }
        ),
        ..,
      },
    ]
}

///|
test "jsx should build structured element and fragment nodes" {
  let source =
    #|const view = <div foo="bar" {...props}>hi {value}<span /></div>
    #|const frag = <><Item<string> key="x" />{value}</>
  let (errors, program) = parse_program_with_jsx(source, true, name="view.tsx")
  assert_true(errors is [])
  guard program.stmts
    is [
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  {
                    kind: JSXElement(
                      {
                        name: "div",
                        attrs: [
                          Attribute(
                            { name: "foo", value: Some(String("bar")), .. }
                          ),
                          Spread({ expr: { kind: Ident("props"), .. }, .. }),
                        ],
                        children: [
                          Text("hi "),
                          Expr({ expr: { kind: Ident("value"), .. }, .. }),
                          Element(
                            {
                              kind: JSXElement(
                                {
                                  name: "span",
                                  attrs: [],
                                  children: [],
                                  self_closing: true,
                                  closing_name: None,
                                  ..,
                                }
                              ),
                              ..,
                            }
                          ),
                        ],
                        self_closing: false,
                        closing_name: Some("div"),
                        ..,
                      }
                    ),
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
      {
        kind: VarDecl(
          {
            decls: [
              {
                init: Some(
                  {
                    kind: JSXFragment(
                      {
                        children: [
                          Element(
                            {
                              kind: JSXElement(
                                {
                                  name: "Item",
                                  type_args: [{ kind: Ident("string"), .. }],
                                  attrs: [
                                    Attribute(
                                      {
                                        name: "key",
                                        value: Some(String("x")),
                                        ..,
                                      }
                                    ),
                                  ],
                                  self_closing: true,
                                  closing_name: None,
                                  ..,
                                }
                              ),
                              ..,
                            }
                          ),
                          Expr({ expr: { kind: Ident("value"), .. }, .. }),
                        ],
                        ..,
                      }
                    ),
                    ..,
                  }
                ),
                ..,
              },
            ],
            ..,
          }
        ),
        ..,
      },
    ]
}
