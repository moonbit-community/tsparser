///|
fn snapshot_errors(errors : ArrayView[ParseError]) -> Array[String] {
  let rendered : Array[String] = []
  for err in errors {
    rendered.push(err.to_string())
  }
  rendered
}

///|
fn snapshot_program(
  source : String,
  name? : String,
) -> (Array[String], Program) {
  let (errors, program) = match name {
    Some(file_name) => parse_program(source, name=file_name)
    None => parse_program(source)
  }
  (snapshot_errors(errors), program)
}

///|
fn snapshot_program_jsx(
  source : String,
  name? : String,
) -> (Array[String], Program) {
  let (errors, program) = match name {
    Some(file_name) => parse_program_with_jsx(source, true, name=file_name)
    None => parse_program_with_jsx(source, true)
  }
  (snapshot_errors(errors), program)
}

///|
test "baseline ast: jsx element fragment attribute child" {
  let source =
    #|const view = <div foo="bar" {...props}>hi {value}<span /></div>
    #|const frag = <><Item key="x" />{value}</>
  debug_inspect(
    snapshot_program_jsx(source, name="baseline.tsx"),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: VarDecl(
      #|          {
      #|            kind: Const,
      #|            decls: [
      #|              {
      #|                pattern: {
      #|                  kind: Ident("view"),
      #|                  span: {
      #|                    start: { offset: 6, line: 1, column: 7 },
      #|                    end: { offset: 10, line: 1, column: 11 },
      #|                  },
      #|                },
      #|                type_ann: None,
      #|                init: Some(
      #|                  {
      #|                    kind: JSXElement(
      #|                      {
      #|                        name: "div",
      #|                        type_args: [],
      #|                        attrs: [
      #|                          Attribute({ name: "foo", value: Some(...), span: { start: ..., end: ... } }),
      #|                          Spread({ expr: { kind: ..., span: ... }, span: { start: ..., end: ... } }),
      #|                        ],
      #|                        children: [
      #|                          Text("hi "),
      #|                          Expr({ expr: { kind: ..., span: ... }, span: { start: ..., end: ... } }),
      #|                          Element({ kind: JSXElement(...), span: { start: ..., end: ... } }),
      #|                        ],
      #|                        self_closing: false,
      #|                        closing_name: Some("div"),
      #|                        opening_span: {
      #|                          start: { offset: 13, line: 1, column: 14 },
      #|                          end: { offset: 39, line: 1, column: 40 },
      #|                        },
      #|                        closing_span: Some(
      #|                          {
      #|                            start: { offset: 57, line: 1, column: 58 },
      #|                            end: { offset: 63, line: 1, column: 64 },
      #|                          },
      #|                        ),
      #|                      },
      #|                    ),
      #|                    span: {
      #|                      start: { offset: 13, line: 1, column: 14 },
      #|                      end: { offset: 63, line: 1, column: 64 },
      #|                    },
      #|                  },
      #|                ),
      #|                span: {
      #|                  start: { offset: 6, line: 1, column: 7 },
      #|                  end: { offset: 63, line: 1, column: 64 },
      #|                },
      #|              },
      #|            ],
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 0, line: 1, column: 1 },
      #|          end: { offset: 63, line: 1, column: 64 },
      #|        },
      #|      },
      #|      {
      #|        kind: VarDecl(
      #|          {
      #|            kind: Const,
      #|            decls: [
      #|              {
      #|                pattern: {
      #|                  kind: Ident("frag"),
      #|                  span: {
      #|                    start: { offset: 70, line: 2, column: 7 },
      #|                    end: { offset: 74, line: 2, column: 11 },
      #|                  },
      #|                },
      #|                type_ann: None,
      #|                init: Some(
      #|                  {
      #|                    kind: JSXFragment(
      #|                      {
      #|                        children: [
      #|                          Element({ kind: JSXElement(...), span: { start: ..., end: ... } }),
      #|                          Expr({ expr: { kind: ..., span: ... }, span: { start: ..., end: ... } }),
      #|                        ],
      #|                        opening_span: {
      #|                          start: { offset: 77, line: 2, column: 14 },
      #|                          end: { offset: 79, line: 2, column: 16 },
      #|                        },
      #|                        closing_span: {
      #|                          start: { offset: 102, line: 2, column: 39 },
      #|                          end: { offset: 105, line: 2, column: 42 },
      #|                        },
      #|                      },
      #|                    ),
      #|                    span: {
      #|                      start: { offset: 77, line: 2, column: 14 },
      #|                      end: { offset: 105, line: 2, column: 42 },
      #|                    },
      #|                  },
      #|                ),
      #|                span: {
      #|                  start: { offset: 70, line: 2, column: 7 },
      #|                  end: { offset: 105, line: 2, column: 42 },
      #|                },
      #|              },
      #|            ],
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 64, line: 2, column: 1 },
      #|          end: { offset: 105, line: 2, column: 42 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: as satisfies as const" {
  let source =
    #|const asserted = value as Foo
    #|const checked = value satisfies Foo
    #|const literal = { answer: 42 } as const
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: VarDecl(
      #|          {
      #|            kind: Const,
      #|            decls: [
      #|              {
      #|                pattern: {
      #|                  kind: Ident("asserted"),
      #|                  span: {
      #|                    start: { offset: 6, line: 1, column: 7 },
      #|                    end: { offset: 14, line: 1, column: 15 },
      #|                  },
      #|                },
      #|                type_ann: None,
      #|                init: Some(
      #|                  {
      #|                    kind: As(
      #|                      {
      #|                        expr: {
      #|                          kind: Ident("value"),
      #|                          span: {
      #|                            start: { offset: 17, line: 1, column: 18 },
      #|                            end: { offset: 22, line: 1, column: 23 },
      #|                          },
      #|                        },
      #|                        type_ann: {
      #|                          kind: Ident("Foo"),
      #|                          span: {
      #|                            start: { offset: 26, line: 1, column: 27 },
      #|                            end: { offset: 29, line: 1, column: 30 },
      #|                          },
      #|                        },
      #|                      },
      #|                    ),
      #|                    span: {
      #|                      start: { offset: 17, line: 1, column: 18 },
      #|                      end: { offset: 29, line: 1, column: 30 },
      #|                    },
      #|                  },
      #|                ),
      #|                span: {
      #|                  start: { offset: 6, line: 1, column: 7 },
      #|                  end: { offset: 29, line: 1, column: 30 },
      #|                },
      #|              },
      #|            ],
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 0, line: 1, column: 1 },
      #|          end: { offset: 29, line: 1, column: 30 },
      #|        },
      #|      },
      #|      {
      #|        kind: VarDecl(
      #|          {
      #|            kind: Const,
      #|            decls: [
      #|              {
      #|                pattern: {
      #|                  kind: Ident("checked"),
      #|                  span: {
      #|                    start: { offset: 36, line: 2, column: 7 },
      #|                    end: { offset: 43, line: 2, column: 14 },
      #|                  },
      #|                },
      #|                type_ann: None,
      #|                init: Some(
      #|                  {
      #|                    kind: Satisfies(
      #|                      {
      #|                        expr: {
      #|                          kind: Ident("value"),
      #|                          span: {
      #|                            start: { offset: 46, line: 2, column: 17 },
      #|                            end: { offset: 51, line: 2, column: 22 },
      #|                          },
      #|                        },
      #|                        type_ann: {
      #|                          kind: Ident("Foo"),
      #|                          span: {
      #|                            start: { offset: 62, line: 2, column: 33 },
      #|                            end: { offset: 65, line: 2, column: 36 },
      #|                          },
      #|                        },
      #|                      },
      #|                    ),
      #|                    span: {
      #|                      start: { offset: 46, line: 2, column: 17 },
      #|                      end: { offset: 65, line: 2, column: 36 },
      #|                    },
      #|                  },
      #|                ),
      #|                span: {
      #|                  start: { offset: 36, line: 2, column: 7 },
      #|                  end: { offset: 65, line: 2, column: 36 },
      #|                },
      #|              },
      #|            ],
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 30, line: 2, column: 1 },
      #|          end: { offset: 65, line: 2, column: 36 },
      #|        },
      #|      },
      #|      {
      #|        kind: VarDecl(
      #|          {
      #|            kind: Const,
      #|            decls: [
      #|              {
      #|                pattern: {
      #|                  kind: Ident("literal"),
      #|                  span: {
      #|                    start: { offset: 72, line: 3, column: 7 },
      #|                    end: { offset: 79, line: 3, column: 14 },
      #|                  },
      #|                },
      #|                type_ann: None,
      #|                init: Some(
      #|                  {
      #|                    kind: As(
      #|                      {
      #|                        expr: {
      #|                          kind: Object({ props: [...] }),
      #|                          span: {
      #|                            start: { offset: 82, line: 3, column: 17 },
      #|                            end: { offset: 96, line: 3, column: 31 },
      #|                          },
      #|                        },
      #|                        type_ann: {
      #|                          kind: Ident("const"),
      #|                          span: {
      #|                            start: { offset: 100, line: 3, column: 35 },
      #|                            end: { offset: 105, line: 3, column: 40 },
      #|                          },
      #|                        },
      #|                      },
      #|                    ),
      #|                    span: {
      #|                      start: { offset: 82, line: 3, column: 17 },
      #|                      end: { offset: 105, line: 3, column: 40 },
      #|                    },
      #|                  },
      #|                ),
      #|                span: {
      #|                  start: { offset: 72, line: 3, column: 7 },
      #|                  end: { offset: 105, line: 3, column: 40 },
      #|                },
      #|              },
      #|            ],
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 66, line: 3, column: 1 },
      #|          end: { offset: 105, line: 3, column: 40 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: template literal type" {
  let source =
    #|type Greeting<T extends string> = `hello ${T}!`
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: TypeAliasDecl(
      #|          {
      #|            name: "Greeting",
      #|            type_params: [
      #|              {
      #|                name: "T",
      #|                variance: None,
      #|                constraint: Some(
      #|                  {
      #|                    kind: Ident("string"),
      #|                    span: {
      #|                      start: { offset: 24, line: 1, column: 25 },
      #|                      end: { offset: 30, line: 1, column: 31 },
      #|                    },
      #|                  },
      #|                ),
      #|                default_type: None,
      #|                span: {
      #|                  start: { offset: 14, line: 1, column: 15 },
      #|                  end: { offset: 30, line: 1, column: 31 },
      #|                },
      #|              },
      #|            ],
      #|            value: {
      #|              kind: TemplateLiteral(
      #|                {
      #|                  quasis: ["hello ", "!"],
      #|                  types: [
      #|                    {
      #|                      kind: Ident("T"),
      #|                      span: {
      #|                        start: { offset: 43, line: 1, column: 44 },
      #|                        end: { offset: 44, line: 1, column: 45 },
      #|                      },
      #|                    },
      #|                  ],
      #|                },
      #|              ),
      #|              span: {
      #|                start: { offset: 34, line: 1, column: 35 },
      #|                end: { offset: 47, line: 1, column: 48 },
      #|              },
      #|            },
      #|            span: {
      #|              start: { offset: 0, line: 1, column: 1 },
      #|              end: { offset: 47, line: 1, column: 48 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 0, line: 1, column: 1 },
      #|          end: { offset: 47, line: 1, column: 48 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: import type and import attributes" {
  let source =
    #|type Loader = import("pkg").Loader<string>
    #|type Attrs = import("pkg", { with: { "resolution-mode": "import" } }).Value
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  ["(2,14): error TS1340: Module 'pkg' does not refer to a type, but is used as a type here. Did you mean 'typeof import('pkg')'?"],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: TypeAliasDecl(
      #|          {
      #|            name: "Loader",
      #|            type_params: [],
      #|            value: {
      #|              kind: ImportType(
      #|                {
      #|                  argument: "pkg",
      #|                  attributes: None,
      #|                  qualifier: Some("Loader"),
      #|                  type_args: [
      #|                    {
      #|                      kind: Ident("string"),
      #|                      span: {
      #|                        start: { offset: 35, line: 1, column: 36 },
      #|                        end: { offset: 41, line: 1, column: 42 },
      #|                      },
      #|                    },
      #|                  ],
      #|                  is_typeof: false,
      #|                },
      #|              ),
      #|              span: {
      #|                start: { offset: 14, line: 1, column: 15 },
      #|                end: { offset: 42, line: 1, column: 43 },
      #|              },
      #|            },
      #|            span: {
      #|              start: { offset: 0, line: 1, column: 1 },
      #|              end: { offset: 42, line: 1, column: 43 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 0, line: 1, column: 1 },
      #|          end: { offset: 42, line: 1, column: 43 },
      #|        },
      #|      },
      #|      {
      #|        kind: TypeAliasDecl(
      #|          {
      #|            name: "Attrs",
      #|            type_params: [],
      #|            value: {
      #|              kind: ImportType(
      #|                {
      #|                  argument: "pkg",
      #|                  attributes: Some(
      #|                    {
      #|                      fields: [
      #|                        {
      #|                          name: "resolution-mode",
      #|                          value: {
      #|                            kind: String("import"),
      #|                            span: {
      #|                              start: { offset: 99, line: 2, column: 57 },
      #|                              end: { offset: 107, line: 2, column: 65 },
      #|                            },
      #|                          },
      #|                          span: {
      #|                            start: { offset: 80, line: 2, column: 38 },
      #|                            end: { offset: 107, line: 2, column: 65 },
      #|                          },
      #|                        },
      #|                      ],
      #|                      span: {
      #|                        start: { offset: 78, line: 2, column: 36 },
      #|                        end: { offset: 109, line: 2, column: 67 },
      #|                      },
      #|                    },
      #|                  ),
      #|                  qualifier: Some("Value"),
      #|                  type_args: [],
      #|                  is_typeof: false,
      #|                },
      #|              ),
      #|              span: {
      #|                start: { offset: 56, line: 2, column: 14 },
      #|                end: { offset: 118, line: 2, column: 76 },
      #|              },
      #|            },
      #|            span: {
      #|              start: { offset: 43, line: 2, column: 1 },
      #|              end: { offset: 118, line: 2, column: 76 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 43, line: 2, column: 1 },
      #|          end: { offset: 118, line: 2, column: 76 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: mapped type and infer type" {
  let source =
    #|type Boxify<T> = { readonly [K in keyof T as K]?: T[K] }
    #|type Awaited<T> = T extends Promise<infer U> ? U : T
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: TypeAliasDecl(
      #|          {
      #|            name: "Boxify",
      #|            type_params: [
      #|              {
      #|                name: "T",
      #|                variance: None,
      #|                constraint: None,
      #|                default_type: None,
      #|                span: {
      #|                  start: { offset: 12, line: 1, column: 13 },
      #|                  end: { offset: 13, line: 1, column: 14 },
      #|                },
      #|              },
      #|            ],
      #|            value: {
      #|              kind: MappedType(
      #|                {
      #|                  readonly_modifier: Some(Add),
      #|                  type_param_name: "K",
      #|                  source_type: {
      #|                    kind: TypeOperator(
      #|                      "keyof",
      #|                      {
      #|                        kind: Ident("T"),
      #|                        span: {
      #|                          start: { offset: 40, line: 1, column: 41 },
      #|                          end: { offset: 41, line: 1, column: 42 },
      #|                        },
      #|                      },
      #|                    ),
      #|                    span: {
      #|                      start: { offset: 34, line: 1, column: 35 },
      #|                      end: { offset: 41, line: 1, column: 42 },
      #|                    },
      #|                  },
      #|                  name_type: Some(
      #|                    {
      #|                      kind: Ident("K"),
      #|                      span: {
      #|                        start: { offset: 45, line: 1, column: 46 },
      #|                        end: { offset: 46, line: 1, column: 47 },
      #|                      },
      #|                    },
      #|                  ),
      #|                  optional_modifier: Some(Add),
      #|                  value_type: Some(
      #|                    {
      #|                      kind: IndexAccess(
      #|                        {
      #|                          kind: Ident("T"),
      #|                          span: {
      #|                            start: { offset: 50, line: 1, column: 51 },
      #|                            end: { offset: 51, line: 1, column: 52 },
      #|                          },
      #|                        },
      #|                        {
      #|                          kind: Ident("K"),
      #|                          span: {
      #|                            start: { offset: 52, line: 1, column: 53 },
      #|                            end: { offset: 53, line: 1, column: 54 },
      #|                          },
      #|                        },
      #|                      ),
      #|                      span: {
      #|                        start: { offset: 50, line: 1, column: 51 },
      #|                        end: { offset: 54, line: 1, column: 55 },
      #|                      },
      #|                    },
      #|                  ),
      #|                },
      #|              ),
      #|              span: {
      #|                start: { offset: 17, line: 1, column: 18 },
      #|                end: { offset: 56, line: 1, column: 57 },
      #|              },
      #|            },
      #|            span: {
      #|              start: { offset: 0, line: 1, column: 1 },
      #|              end: { offset: 56, line: 1, column: 57 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 0, line: 1, column: 1 },
      #|          end: { offset: 56, line: 1, column: 57 },
      #|        },
      #|      },
      #|      {
      #|        kind: TypeAliasDecl(
      #|          {
      #|            name: "Awaited",
      #|            type_params: [
      #|              {
      #|                name: "T",
      #|                variance: None,
      #|                constraint: None,
      #|                default_type: None,
      #|                span: {
      #|                  start: { offset: 70, line: 2, column: 14 },
      #|                  end: { offset: 71, line: 2, column: 15 },
      #|                },
      #|              },
      #|            ],
      #|            value: {
      #|              kind: Conditional(
      #|                {
      #|                  kind: Ident("T"),
      #|                  span: {
      #|                    start: { offset: 75, line: 2, column: 19 },
      #|                    end: { offset: 76, line: 2, column: 20 },
      #|                  },
      #|                },
      #|                {
      #|                  kind: Generic(
      #|                    {
      #|                      kind: Ident("Promise"),
      #|                      span: {
      #|                        start: { offset: 85, line: 2, column: 29 },
      #|                        end: { offset: 92, line: 2, column: 36 },
      #|                      },
      #|                    },
      #|                    [
      #|                      {
      #|                        kind: InferType(
      #|                          {
      #|                            type_param: {
      #|                              name: "U",
      #|                              variance: None,
      #|                              constraint: None,
      #|                              default_type: None,
      #|                              span: { start: ..., end: ... },
      #|                            },
      #|                          },
      #|                        ),
      #|                        span: {
      #|                          start: { offset: 93, line: 2, column: 37 },
      #|                          end: { offset: 100, line: 2, column: 44 },
      #|                        },
      #|                      },
      #|                    ],
      #|                  ),
      #|                  span: {
      #|                    start: { offset: 85, line: 2, column: 29 },
      #|                    end: { offset: 101, line: 2, column: 45 },
      #|                  },
      #|                },
      #|                {
      #|                  kind: Ident("U"),
      #|                  span: {
      #|                    start: { offset: 104, line: 2, column: 48 },
      #|                    end: { offset: 105, line: 2, column: 49 },
      #|                  },
      #|                },
      #|                {
      #|                  kind: Ident("T"),
      #|                  span: {
      #|                    start: { offset: 108, line: 2, column: 52 },
      #|                    end: { offset: 109, line: 2, column: 53 },
      #|                  },
      #|                },
      #|              ),
      #|              span: {
      #|                start: { offset: 75, line: 2, column: 19 },
      #|                end: { offset: 109, line: 2, column: 53 },
      #|              },
      #|            },
      #|            span: {
      #|              start: { offset: 57, line: 2, column: 1 },
      #|              end: { offset: 109, line: 2, column: 53 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 57, line: 2, column: 1 },
      #|          end: { offset: 109, line: 2, column: 53 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: constructor type and parenthesized type" {
  let source =
    #|type Factory = abstract new <T>(value: T) => Box<T>
    #|type Wrapped = (Foo | Bar)[]
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: TypeAliasDecl(
      #|          {
      #|            name: "Factory",
      #|            type_params: [],
      #|            value: {
      #|              kind: Constructor(
      #|                {
      #|                  type_params: [
      #|                    {
      #|                      name: "T",
      #|                      variance: None,
      #|                      constraint: None,
      #|                      default_type: None,
      #|                      span: {
      #|                        start: { offset: 29, line: 1, column: 30 },
      #|                        end: { offset: 30, line: 1, column: 31 },
      #|                      },
      #|                    },
      #|                  ],
      #|                  params: [
      #|                    {
      #|                      pattern: {
      #|                        kind: Ident("value"),
      #|                        span: {
      #|                          start: { offset: 32, line: 1, column: 33 },
      #|                          end: { offset: 37, line: 1, column: 38 },
      #|                        },
      #|                      },
      #|                      optional: false,
      #|                      type_ann: Some(
      #|                        {
      #|                          kind: Ident("T"),
      #|                          span: {
      #|                            start: { offset: 39, line: 1, column: 40 },
      #|                            end: { offset: 40, line: 1, column: 41 },
      #|                          },
      #|                        },
      #|                      ),
      #|                      default_value: None,
      #|                      is_rest: false,
      #|                      span: {
      #|                        start: { offset: 32, line: 1, column: 33 },
      #|                        end: { offset: 40, line: 1, column: 41 },
      #|                      },
      #|                    },
      #|                  ],
      #|                  return_type: {
      #|                    kind: Generic(
      #|                      {
      #|                        kind: Ident("Box"),
      #|                        span: {
      #|                          start: { offset: 45, line: 1, column: 46 },
      #|                          end: { offset: 48, line: 1, column: 49 },
      #|                        },
      #|                      },
      #|                      [
      #|                        {
      #|                          kind: Ident("T"),
      #|                          span: {
      #|                            start: { offset: 49, line: 1, column: 50 },
      #|                            end: { offset: 50, line: 1, column: 51 },
      #|                          },
      #|                        },
      #|                      ],
      #|                    ),
      #|                    span: {
      #|                      start: { offset: 45, line: 1, column: 46 },
      #|                      end: { offset: 51, line: 1, column: 52 },
      #|                    },
      #|                  },
      #|                  is_abstract: true,
      #|                },
      #|              ),
      #|              span: {
      #|                start: { offset: 15, line: 1, column: 16 },
      #|                end: { offset: 51, line: 1, column: 52 },
      #|              },
      #|            },
      #|            span: {
      #|              start: { offset: 0, line: 1, column: 1 },
      #|              end: { offset: 51, line: 1, column: 52 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 0, line: 1, column: 1 },
      #|          end: { offset: 51, line: 1, column: 52 },
      #|        },
      #|      },
      #|      {
      #|        kind: TypeAliasDecl(
      #|          {
      #|            name: "Wrapped",
      #|            type_params: [],
      #|            value: {
      #|              kind: Array(
      #|                {
      #|                  kind: Parenthesized(
      #|                    {
      #|                      inner: {
      #|                        kind: Union(
      #|                          [
      #|                            { kind: Ident("Foo"), span: { start: ..., end: ... } },
      #|                            { kind: Ident("Bar"), span: { start: ..., end: ... } },
      #|                          ],
      #|                        ),
      #|                        span: {
      #|                          start: { offset: 68, line: 2, column: 17 },
      #|                          end: { offset: 77, line: 2, column: 26 },
      #|                        },
      #|                      },
      #|                    },
      #|                  ),
      #|                  span: {
      #|                    start: { offset: 67, line: 2, column: 16 },
      #|                    end: { offset: 78, line: 2, column: 27 },
      #|                  },
      #|                },
      #|              ),
      #|              span: {
      #|                start: { offset: 67, line: 2, column: 16 },
      #|                end: { offset: 80, line: 2, column: 29 },
      #|              },
      #|            },
      #|            span: {
      #|              start: { offset: 52, line: 2, column: 1 },
      #|              end: { offset: 80, line: 2, column: 29 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 52, line: 2, column: 1 },
      #|          end: { offset: 80, line: 2, column: 29 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: decorator" {
  let source =
    #|// @experimentalDecorators: true
    #|@sealed
    #|class Box {
    #|  @logged
    #|  value: string
    #|}
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: ClassDecl(
      #|          {
      #|            name: Some("Box"),
      #|            decorators: [
      #|              {
      #|                kind: Ident("sealed"),
      #|                span: {
      #|                  start: { offset: 34, line: 2, column: 2 },
      #|                  end: { offset: 40, line: 2, column: 8 },
      #|                },
      #|              },
      #|            ],
      #|            type_params: [],
      #|            extends: None,
      #|            implements: [],
      #|            members: [
      #|              {
      #|                kind: Field(
      #|                  Ident("value"),
      #|                  Some(
      #|                    {
      #|                      kind: Ident("string"),
      #|                      span: {
      #|                        start: { offset: 72, line: 5, column: 10 },
      #|                        end: { offset: 78, line: 5, column: 16 },
      #|                      },
      #|                    },
      #|                  ),
      #|                  None,
      #|                ),
      #|                decorators: [
      #|                  {
      #|                    kind: Ident("logged"),
      #|                    span: {
      #|                      start: { offset: 56, line: 4, column: 4 },
      #|                      end: { offset: 62, line: 4, column: 10 },
      #|                    },
      #|                  },
      #|                ],
      #|                is_static: false,
      #|                access: None,
      #|                is_readonly: false,
      #|                span: {
      #|                  start: { offset: 55, line: 4, column: 3 },
      #|                  end: { offset: 78, line: 5, column: 16 },
      #|                },
      #|              },
      #|            ],
      #|            span: {
      #|              start: { offset: 41, line: 3, column: 1 },
      #|              end: { offset: 80, line: 6, column: 2 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 41, line: 3, column: 1 },
      #|          end: { offset: 80, line: 6, column: 2 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: class static block" {
  let source =
    #|class Counter {
    #|  static value = 0
    #|  static {
    #|    this.value = 1
    #|  }
    #|}
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: ClassDecl(
      #|          {
      #|            name: Some("Counter"),
      #|            decorators: [],
      #|            type_params: [],
      #|            extends: None,
      #|            implements: [],
      #|            members: [
      #|              {
      #|                kind: Field(
      #|                  Ident("value"),
      #|                  None,
      #|                  Some(
      #|                    {
      #|                      kind: Number("0"),
      #|                      span: {
      #|                        start: { offset: 33, line: 2, column: 18 },
      #|                        end: { offset: 34, line: 2, column: 19 },
      #|                      },
      #|                    },
      #|                  ),
      #|                ),
      #|                decorators: [],
      #|                is_static: true,
      #|                access: None,
      #|                is_readonly: false,
      #|                span: {
      #|                  start: { offset: 18, line: 2, column: 3 },
      #|                  end: { offset: 34, line: 2, column: 19 },
      #|                },
      #|              },
      #|              {
      #|                kind: StaticBlock(
      #|                  {
      #|                    stmts: [
      #|                      {
      #|                        kind: ExprStmt(
      #|                          {
      #|                            kind: Assign({ op: Assign, target: ..., value: ... }),
      #|                            span: {
      #|                              start: { offset: 50, line: 4, column: 5 },
      #|                              end: { offset: 64, line: 4, column: 19 },
      #|                            },
      #|                          },
      #|                        ),
      #|                        span: {
      #|                          start: { offset: 50, line: 4, column: 5 },
      #|                          end: { offset: 64, line: 4, column: 19 },
      #|                        },
      #|                      },
      #|                    ],
      #|                    span: {
      #|                      start: { offset: 44, line: 3, column: 10 },
      #|                      end: { offset: 68, line: 5, column: 4 },
      #|                    },
      #|                  },
      #|                ),
      #|                decorators: [],
      #|                is_static: true,
      #|                access: None,
      #|                is_readonly: false,
      #|                span: {
      #|                  start: { offset: 37, line: 3, column: 3 },
      #|                  end: { offset: 68, line: 5, column: 4 },
      #|                },
      #|              },
      #|            ],
      #|            span: {
      #|              start: { offset: 0, line: 1, column: 1 },
      #|              end: { offset: 70, line: 6, column: 2 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 0, line: 1, column: 1 },
      #|          end: { offset: 70, line: 6, column: 2 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: private field and in expression" {
  let source =
    #|class Box {
    #|  #value = 1
    #|  has(obj: object) {
    #|    return #value in obj
    #|  }
    #|}
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: ClassDecl(
      #|          {
      #|            name: Some("Box"),
      #|            decorators: [],
      #|            type_params: [],
      #|            extends: None,
      #|            implements: [],
      #|            members: [
      #|              {
      #|                kind: Field(
      #|                  Private("value"),
      #|                  None,
      #|                  Some(
      #|                    {
      #|                      kind: Number("1"),
      #|                      span: {
      #|                        start: { offset: 23, line: 2, column: 12 },
      #|                        end: { offset: 24, line: 2, column: 13 },
      #|                      },
      #|                    },
      #|                  ),
      #|                ),
      #|                decorators: [],
      #|                is_static: false,
      #|                access: None,
      #|                is_readonly: false,
      #|                span: {
      #|                  start: { offset: 14, line: 2, column: 3 },
      #|                  end: { offset: 24, line: 2, column: 13 },
      #|                },
      #|              },
      #|              {
      #|                kind: Method(
      #|                  Ident("has"),
      #|                  [
      #|                    {
      #|                      pattern: {
      #|                        kind: Ident("obj"),
      #|                        span: {
      #|                          start: { offset: 31, line: 3, column: 7 },
      #|                          end: { offset: 34, line: 3, column: 10 },
      #|                        },
      #|                      },
      #|                      optional: false,
      #|                      type_ann: Some(
      #|                        {
      #|                          kind: Ident("object"),
      #|                          span: {
      #|                            start: { offset: 36, line: 3, column: 12 },
      #|                            end: { offset: 42, line: 3, column: 18 },
      #|                          },
      #|                        },
      #|                      ),
      #|                      default_value: None,
      #|                      is_rest: false,
      #|                      span: {
      #|                        start: { offset: 31, line: 3, column: 7 },
      #|                        end: { offset: 42, line: 3, column: 18 },
      #|                      },
      #|                    },
      #|                  ],
      #|                  None,
      #|                  {
      #|                    stmts: [
      #|                      {
      #|                        kind: Return(Some({ kind: Binary(...), span: { start: ..., end: ... } })),
      #|                        span: {
      #|                          start: { offset: 50, line: 4, column: 5 },
      #|                          end: { offset: 70, line: 4, column: 25 },
      #|                        },
      #|                      },
      #|                    ],
      #|                    span: {
      #|                      start: { offset: 44, line: 3, column: 20 },
      #|                      end: { offset: 74, line: 5, column: 4 },
      #|                    },
      #|                  },
      #|                ),
      #|                decorators: [],
      #|                is_static: false,
      #|                access: None,
      #|                is_readonly: false,
      #|                span: {
      #|                  start: { offset: 27, line: 3, column: 3 },
      #|                  end: { offset: 74, line: 5, column: 4 },
      #|                },
      #|              },
      #|            ],
      #|            span: {
      #|              start: { offset: 0, line: 1, column: 1 },
      #|              end: { offset: 76, line: 6, column: 2 },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 0, line: 1, column: 1 },
      #|          end: { offset: 76, line: 6, column: 2 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}

///|
test "baseline ast: jsdoc comment" {
  let source =
    #|/**
    #| * docs
    #| */
    #|function greet(name: string) {
    #|  return name
    #|}
  debug_inspect(
    snapshot_program(source),
    content=(
      #|(
      #|  [],
      #|  {
      #|    stmts: [
      #|      {
      #|        kind: FunctionDecl(
      #|          {
      #|            name: Some("greet"),
      #|            type_params: [],
      #|            params: [
      #|              {
      #|                pattern: {
      #|                  kind: Ident("name"),
      #|                  span: {
      #|                    start: { offset: 31, line: 4, column: 16 },
      #|                    end: { offset: 35, line: 4, column: 20 },
      #|                  },
      #|                },
      #|                optional: false,
      #|                type_ann: Some(
      #|                  {
      #|                    kind: Ident("string"),
      #|                    span: {
      #|                      start: { offset: 37, line: 4, column: 22 },
      #|                      end: { offset: 43, line: 4, column: 28 },
      #|                    },
      #|                  },
      #|                ),
      #|                default_value: None,
      #|                is_rest: false,
      #|                span: {
      #|                  start: { offset: 31, line: 4, column: 16 },
      #|                  end: { offset: 43, line: 4, column: 28 },
      #|                },
      #|              },
      #|            ],
      #|            return_type: None,
      #|            body: {
      #|              stmts: [
      #|                {
      #|                  kind: Return(
      #|                    Some(
      #|                      {
      #|                        kind: Ident("name"),
      #|                        span: {
      #|                          start: { offset: 56, line: 5, column: 10 },
      #|                          end: { offset: 60, line: 5, column: 14 },
      #|                        },
      #|                      },
      #|                    ),
      #|                  ),
      #|                  span: {
      #|                    start: { offset: 49, line: 5, column: 3 },
      #|                    end: { offset: 60, line: 5, column: 14 },
      #|                  },
      #|                },
      #|              ],
      #|              span: {
      #|                start: { offset: 45, line: 4, column: 30 },
      #|                end: { offset: 62, line: 6, column: 2 },
      #|              },
      #|            },
      #|          },
      #|        ),
      #|        span: {
      #|          start: { offset: 16, line: 4, column: 1 },
      #|          end: { offset: 62, line: 6, column: 2 },
      #|        },
      #|      },
      #|    ],
      #|  },
      #|)
    ),
  )
}
