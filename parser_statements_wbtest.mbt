///|
fn _collect_statement_kind_ranges(node : Node, result : Array[String]) -> Unit {
  result.push(
    node.kind().to_int().to_string() +
    "@" +
    node.pos().to_string() +
    ":" +
    node.end().to_string(),
  )
  ignore(
    for_each_child(node, fn(child) -> Unit? {
      _collect_statement_kind_ranges(child, result)
      None
    }),
  )
}

///|
fn _statement_shape(statements : NodeArray) -> String {
  let result : Array[String] = [
    "A@" +
    statements.pos().to_string() +
    ":" +
    statements.end().to_string() +
    ":" +
    (if statements.has_trailing_comma() { "1" } else { "0" }),
  ]
  for statement in statements.elements() {
    _collect_statement_kind_ranges(statement, result)
  }
  result.join(",")
}

///|
fn _diagnostic_shape(diagnostics : Array[Diagnostic]) -> String {
  diagnostics
  .map(fn(diagnostic) {
    diagnostic.code().to_string() +
    "@" +
    (match diagnostic.start() {
      Some(value) => value.to_string()
      None => "none"
    }) +
    ":" +
    (match diagnostic.length() {
      Some(value) => value.to_string()
      None => "none"
    })
  })
  .join(",")
}

///|
fn _collect_statement_array_shape(node : Node, result : Array[String]) -> Unit {
  result.push(
    "N" +
    node.kind().to_int().to_string() +
    "@" +
    node.pos().to_string() +
    ":" +
    node.end().to_string(),
  )
  ignore(
    for_each_child(
      node,
      fn(child) -> Unit? {
        _collect_statement_array_shape(child, result)
        None
      },
      list_callback=fn(array) -> Unit? {
        result.push(
          "A@" +
          array.pos().to_string() +
          ":" +
          array.end().to_string() +
          ":" +
          (if array.has_trailing_comma() { "1" } else { "0" }),
        )
        for child in array.elements() {
          _collect_statement_array_shape(child, result)
        }
        None
      },
    ),
  )
}

///|
fn _statement_array_shape(statements : NodeArray) -> String {
  let result : Array[String] = [
    "A@" +
    statements.pos().to_string() +
    ":" +
    statements.end().to_string() +
    ":" +
    (if statements.has_trailing_comma() { "1" } else { "0" }),
  ]
  for statement in statements.elements() {
    _collect_statement_array_shape(statement, result)
  }
  result.join(",")
}

///|
test "statement and declaration smoke matrix consumes complete inputs" {
  let fixtures = [
    (
      "{; x; if(a)b;else c; do{}while(d)e(); while(f)break; for(let i=0;i<2;i++) continue; for(const k in obj) x; for await (const v of xs) y;}",
      242,
    ),
    (
      "switch(x){case 1: y; break; default: try { throw e; } catch ({message:m}: E) { debugger; } finally { z; }}",
      256,
    ),
    (
      "let {a, b:c=1, ...rest}=obj, [x,,...ys]=arr; using resource = open(); await using asyncResource = open();",
      244,
    ),
    (
      "export default async function* f<T>({x}: P, [y]=[]): R { if(x) return await x; yield* y; }",
      263,
    ),
    (
      "@dec export abstract class C<T> extends B<T> implements I<T>, J { @d public static accessor value?: T = init; static { await work(); } constructor(public x:T) {} async *[key]<U>(u:U): Promise<U> { return u; } get item():T{return this.value;} set item(v:T){} readonly #field!: T; [idx: string]: unknown; ; }",
      264,
    ),
    (
      "export interface I<T> extends B<T> { readonly x?:T; m<U>(u:U):U; } export type Alias<T> = T extends U ? X : Y; export const enum E { A, B=1, [\"C\"]=2 } export namespace N.Inner { export const x=1; } declare module \"pkg\" { export interface X {} } declare global { interface Window {} }",
      265,
    ),
  ]
  for fixture in fixtures {
    let (source, first_kind) = fixture
    let (statements, diagnostics, token, _) = _parse_statements_for_test(source)
    assert_true(statements.length() > 0, msg=source)
    assert_eq(
      statements.get(0).unwrap().kind().to_int(),
      first_kind,
      msg=source,
    )
    assert_eq(_diagnostic_shape(diagnostics), "")
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "declaration-file context marks statements ambient and exported" {
  let (statements, diagnostics, token, flags) = _parse_statements_for_test(
    "const x: number; function f(): void; class C { x: number; }",
    file_name="ambient.d.ts",
  )
  assert_eq(statements.length(), 3)
  assert_eq(diagnostics.length(), 0)
  assert_eq(token.to_int(), 1)
  assert_true(flags.contains(NodeFlags::ambient()))
  for statement in statements.elements() {
    assert_true(statement.flags().contains(NodeFlags::ambient()))
    assert_false(statement.flags().contains(NodeFlags::export_context()))
  }
}

///|
test "do-while consumes only an explicit trailing semicolon" {
  let (statements, diagnostics, token, _) = _parse_statements_for_test(
    "do{}while(false)foo()",
  )
  assert_eq(statements.length(), 2)
  assert_eq(statements.get(0).unwrap().kind().to_int(), 247)
  assert_eq(statements.get(1).unwrap().kind().to_int(), 245)
  assert_eq(diagnostics.length(), 0)
  assert_eq(token.to_int(), 1)
}

///|
test "statement declaration preorder kinds and UTF-16 ranges match TypeScript" {
  let fixtures = [
    ("{}", "A@0:2:0,242@0:2"),
    (";", "A@0:1:0,243@0:1"),
    ("\"use strict\";x;", "A@0:15:0,245@0:13,11@0:12,245@13:15,80@13:14"),
    (
      "if(a)b;else c;", "A@0:14:0,246@0:14,80@3:4,245@5:7,80@5:6,245@11:14,80@11:13",
    ),
    (
      "do{}while(false)foo()", "A@0:21:0,247@0:16,242@2:4,97@10:15,245@16:21,214@16:21,80@16:19",
    ),
    ("while(a) break label;", "A@0:21:0,248@0:21,80@6:7,253@8:21,80@14:20"),
    (
      "for(let i=0;i<2;i++) continue;", "A@0:30:0,249@0:30,262@4:11,261@7:11,80@7:9,9@10:11,227@12:15,80@12:13,30@13:14,9@14:15,226@16:19,80@16:17,252@20:30",
    ),
    (
      "for(const k in obj) x;", "A@0:22:0,250@0:22,262@4:11,261@9:11,80@9:11,80@14:18,245@19:22,80@19:21",
    ),
    (
      "for await (const v of xs) y;", "A@0:28:0,251@0:28,135@3:9,262@11:18,261@16:18,80@16:18,80@21:24,245@25:28,80@25:27",
    ),
    ("return x;", "A@0:9:0,254@0:9,80@6:8"),
    ("with(x)y;", "A@0:9:0,255@0:9,80@5:6,245@7:9,80@7:8"),
    (
      "switch(x){case 1:y;break;default:z;}", "A@0:36:0,256@0:36,80@7:8,270@9:36,297@10:25,9@14:16,245@17:19,80@17:18,253@19:25,298@25:35,245@33:35,80@33:34",
    ),
    ("label: throw e;", "A@0:15:0,257@0:15,80@0:5,258@6:15,80@12:14"),
    (
      "try{}catch(e: E){}finally{}", "A@0:27:0,259@0:27,242@3:5,300@5:18,261@11:15,80@11:12,184@13:15,80@13:15,242@16:18,242@25:27",
    ),
    ("debugger;", "A@0:9:0,260@0:9"),
    (
      "let {a,b:c=1,...rest}=obj,[x,,...ys]=arr;", "A@0:41:0,244@0:41,262@0:40,261@3:25,207@3:21,209@5:6,80@5:6,209@7:12,80@7:8,80@9:10,9@11:12,209@13:20,26@13:16,80@16:20,80@22:25,261@26:40,208@26:36,209@27:28,80@27:28,233@29:29,209@30:35,26@30:33,80@33:35,80@37:40",
    ),
    (
      "using x=f(); await using y=g();", "A@0:31:0,244@0:12,262@0:11,261@5:11,80@5:7,214@8:11,80@8:9,244@12:31,262@12:30,261@24:30,80@24:26,214@27:30,80@27:28",
    ),
    (
      "function* f<T>(x:T):T{return x;}", "A@0:32:0,263@0:32,42@8:9,80@9:11,169@12:13,80@12:13,170@15:18,80@15:16,184@17:18,80@17:18,184@20:21,80@20:21,242@21:32,254@22:31,80@28:30",
    ),
    (
      "async function f(){await x;}", "A@0:28:0,263@0:28,134@0:5,80@14:16,242@18:28,245@19:27,224@19:26,80@24:26",
    ),
    (
      "function f(x:T):U;", "A@0:18:0,263@0:18,80@8:10,170@11:14,80@11:12,184@13:14,80@13:14,184@16:17,80@16:17",
    ),
    (
      "class C<T> extends B<T> implements I,J {}", "A@0:41:0,264@0:41,80@5:7,169@8:9,80@8:9,299@10:23,234@18:23,80@18:20,184@21:22,80@21:22,299@23:38,234@34:36,80@34:36,234@37:38,80@37:38",
    ),
    (
      "class C { constructor(public x:T){}; }", "A@0:38:0,264@0:38,80@5:7,177@9:35,170@22:32,125@22:28,80@28:30,184@31:32,80@31:32,242@33:35,241@35:36",
    ),
    (
      "class C { static { await x; } }", "A@0:31:0,264@0:31,80@5:7,176@9:29,242@16:29,245@18:27,224@18:26,80@24:26",
    ),
    (
      "class C { @d public static accessor x?:T=1; readonly #y!:U; [k:string]:V; }",
      "A@0:75:0,264@0:75,80@5:7,173@9:43,171@9:12,80@11:12,125@12:19,126@19:26,129@26:35,80@35:37,58@37:38,184@39:40,80@39:40,9@41:42,173@43:59,148@43:52,81@52:55,54@55:56,184@57:58,80@57:58,182@59:73,170@61:69,80@61:62,154@63:69,184@71:72,80@71:72",
    ),
    (
      "class C { async *[k]<T>(x:T):T{return x;} get x():T{return y;} set x(v:T){} }",
      "A@0:77:0,264@0:77,80@5:7,175@9:41,134@9:15,42@15:17,168@17:20,80@18:19,169@21:22,80@21:22,170@24:27,80@24:25,184@26:27,80@26:27,184@29:30,80@29:30,242@30:41,254@31:40,80@37:39,178@41:62,80@45:47,184@50:51,80@50:51,242@51:62,254@52:61,80@58:60,179@62:75,80@66:68,170@69:72,80@69:70,184@71:72,80@71:72,242@73:75",
    ),
    (
      "interface I<T> extends B<T>{readonly x?:T;m<U>(u:U):U;}", "A@0:55:0,265@0:55,80@9:11,169@12:13,80@12:13,299@14:27,234@22:27,80@22:24,184@25:26,80@25:26,172@28:42,148@28:36,80@36:38,58@38:39,184@40:41,80@40:41,174@42:54,80@42:43,169@44:45,80@44:45,170@47:50,80@47:48,184@49:50,80@49:50,184@52:53,80@52:53",
    ),
    (
      "type A<T>=T extends U?X:Y;", "A@0:26:0,266@0:26,80@4:6,169@7:8,80@7:8,195@10:25,184@10:11,80@10:11,184@19:21,80@19:21,184@22:23,80@22:23,184@24:25,80@24:25",
    ),
    (
      "const enum E{A,B=1,[\"C\"]=2}", "A@0:27:0,267@0:27,87@0:5,80@10:12,307@13:14,80@13:14,307@15:18,80@15:16,9@17:18,307@19:26,168@19:24,11@20:23,9@25:26",
    ),
    (
      "namespace N.Inner{export const x=1;}", "A@0:36:0,268@0:36,80@9:11,268@12:36,80@12:17,269@17:36,244@18:35,95@18:24,262@24:34,261@30:34,80@30:32,9@33:34",
    ),
    (
      "declare module \"x\"{interface I{}}", "A@0:33:0,268@0:33,138@0:7,11@14:18,269@18:33,265@19:32,80@28:30",
    ),
    (
      "declare global{interface Window{}}", "A@0:34:0,268@0:34,138@0:7,80@7:14,269@14:34,265@15:33,80@24:31",
    ),
    (
      "@d export default abstract class C{}", "A@0:36:0,264@0:36,171@0:2,80@1:2,95@2:9,90@9:17,128@17:26,80@32:34",
    ),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (statements, diagnostics, token, _) = _parse_statements_for_test(source)
    assert_eq(_statement_shape(statements), expected)
    assert_eq(_diagnostic_shape(diagnostics), "", msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "statement declaration NodeArray metadata matches TypeScript" {
  let fixtures = [
    (
      "{let x=1; if(x){x++;}}", "A@0:22:0,N242@0:22,A@1:21:0,N244@1:9,N262@1:8,A@4:8:0,N261@4:8,N80@4:6,N9@7:8,N246@9:21,N80@13:14,N242@15:21,A@16:20:0,N245@16:20,N226@16:19,N80@16:17",
    ),
    (
      "for(let i=0,j=1;i<2;i++){}", "A@0:26:0,N249@0:26,N262@4:15,A@7:15:0,N261@7:11,N80@7:9,N9@10:11,N261@12:15,N80@12:13,N9@14:15,N227@16:19,N80@16:17,N30@17:18,N9@18:19,N226@20:23,N80@20:21,N242@24:26,A@25:25:0",
    ),
    (
      "switch(x){case 1:y;default:z;}", "A@0:30:0,N256@0:30,N80@7:8,N270@9:30,A@10:29:0,N297@10:19,N9@14:16,A@17:19:0,N245@17:19,N80@17:18,N298@19:29,A@27:29:0,N245@27:29,N80@27:28",
    ),
    (
      "let {a,b:c=1,...rest}=obj,[x,,...ys]=arr;", "A@0:41:0,N244@0:41,N262@0:40,A@3:40:0,N261@3:25,N207@3:21,A@5:20:0,N209@5:6,N80@5:6,N209@7:12,N80@7:8,N80@9:10,N9@11:12,N209@13:20,N26@13:16,N80@16:20,N80@22:25,N261@26:40,N208@26:36,A@27:35:0,N209@27:28,N80@27:28,N233@29:29,N209@30:35,N26@30:33,N80@33:35,N80@37:40",
    ),
    (
      "function* f<T>(x:T):T{return x;}", "A@0:32:0,N263@0:32,N42@8:9,N80@9:11,A@12:13:0,N169@12:13,N80@12:13,A@15:18:0,N170@15:18,N80@15:16,N184@17:18,N80@17:18,N184@20:21,N80@20:21,N242@21:32,A@22:31:0,N254@22:31,N80@28:30",
    ),
    (
      "class C { @d public static accessor x?:T=1; async *[k]<U>(u:U):U{return u;} }",
      "A@0:77:0,N264@0:77,N80@5:7,A@9:75:0,N173@9:43,A@9:35:0,N171@9:12,N80@11:12,N125@12:19,N126@19:26,N129@26:35,N80@35:37,N58@37:38,N184@39:40,N80@39:40,N9@41:42,N175@43:75,A@43:49:0,N134@43:49,N42@49:51,N168@51:54,N80@52:53,A@55:56:0,N169@55:56,N80@55:56,A@58:61:0,N170@58:61,N80@58:59,N184@60:61,N80@60:61,N184@63:64,N80@63:64,N242@64:75,A@65:74:0,N254@65:74,N80@71:73",
    ),
    (
      "interface I<T> extends B<T>,C{m<U>(u:U):U;}", "A@0:43:0,N265@0:43,N80@9:11,A@12:13:0,N169@12:13,N80@12:13,A@14:29:0,N299@14:29,A@22:29:0,N234@22:27,N80@22:24,A@25:26:0,N184@25:26,N80@25:26,N234@28:29,N80@28:29,A@30:42:0,N174@30:42,N80@30:31,A@32:33:0,N169@32:33,N80@32:33,A@35:38:0,N170@35:38,N80@35:36,N184@37:38,N80@37:38,N184@40:41,N80@40:41",
    ),
    (
      "namespace N.Inner{const x=1;} enum E{A,B=1,}", "A@0:44:0,N268@0:29,N80@9:11,N268@12:29,N80@12:17,N269@17:29,A@18:28:0,N244@18:28,N262@18:27,A@23:27:0,N261@23:27,N80@23:25,N9@26:27,N267@29:44,N80@34:36,A@37:43:1,N307@37:38,N80@37:38,N307@39:42,N80@39:40,N9@41:42",
    ),
  ]
  for fixture in fixtures {
    let (source, expected) = fixture
    let (statements, diagnostics, token, _) = _parse_statements_for_test(source)
    assert_eq(_statement_array_shape(statements), expected, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "ASI boundaries and malformed declarations match parser diagnostics" {
  let asi_fixtures = [
    ("throw\nx;", "A@0:8:0,258@0:5,80@5:5,245@5:8,80@5:7"),
    ("return\nx;", "A@0:9:0,254@0:6,245@6:9,80@6:8"),
    ("break\nlabel;", "A@0:12:0,253@0:5,245@5:12,80@5:11"),
    ("for(let of xs){}", "A@0:16:0,251@0:16,262@4:7,80@10:13,242@14:16"),
  ]
  for fixture in asi_fixtures {
    let (source, expected) = fixture
    let (statements, diagnostics, token, _) = _parse_statements_for_test(source)
    assert_eq(_statement_shape(statements), expected, msg=source)
    assert_eq(diagnostics.length(), 0, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
  let recovery_fixtures = [
    ("var #x=1;", "18029@4:2"),
    ("const #x=1;", "18029@6:2"),
    ("function f(#x){}", "18009@11:2"),
    ("try{}", "1472@5:0"),
    ("let {a b}=x;", "1005@7:1"),
    ("function f(", "1005@11:0"),
    ("class C { x: ; }", "1110@13:1"),
  ]
  for fixture in recovery_fixtures {
    let (source, expected) = fixture
    let (_, diagnostics, token, _) = _parse_statements_for_test(source)
    assert_eq(_diagnostic_shape(diagnostics), expected, msg=source)
    assert_eq(token.to_int(), 1, msg=source)
  }
}

///|
test "declaration and class parser-only fields preserve invalid syntax" {
  let source = "declare export async function f():void; class C{@d static{} constructor<T>():U; get x<T>():U; set x<T>(v:U):V;}"
  let (statements, diagnostics, token, _) = _parse_statements_for_test(source)
  assert_eq(diagnostics.length(), 0)
  assert_eq(token.to_int(), 1)
  let function_node = statements.get(0).unwrap()
  assert_eq(function_node.kind().to_int(), 263)
  match _parser_node_field_list(function_node, "modifiers") {
    Some(modifiers) => {
      assert_eq(modifiers.length(), 3)
      assert_eq(modifiers.get(0).unwrap().kind().to_int(), 138)
      assert_eq(modifiers.get(1).unwrap().kind().to_int(), 95)
      assert_eq(modifiers.get(2).unwrap().kind().to_int(), 134)
      for modifier in modifiers.elements() {
        assert_true(modifier.flags().contains(NodeFlags::ambient()))
      }
    }
    None => fail("function modifiers are absent")
  }
  assert_true(function_node.flags().contains(NodeFlags::ambient()))
  let class_node = statements.get(1).unwrap()
  let members = _parser_node_field_list(class_node, "members").unwrap()
  assert_eq(members.length(), 4)
  let static_block = members.get(0).unwrap()
  assert_eq(static_block.kind().to_int(), 176)
  assert_eq(
    _parser_node_field_list(static_block, "modifiers").unwrap().length(),
    1,
  )
  let constructor_node = members.get(1).unwrap()
  assert_eq(constructor_node.kind().to_int(), 177)
  assert_eq(
    _parser_node_field_list(constructor_node, "typeParameters")
    .unwrap()
    .length(),
    1,
  )
  assert_eq(
    _parser_node_field_node(constructor_node, "type").unwrap().kind().to_int(),
    184,
  )
  let getter = members.get(2).unwrap()
  assert_eq(getter.kind().to_int(), 178)
  assert_eq(
    _parser_node_field_list(getter, "typeParameters").unwrap().length(),
    1,
  )
  let setter = members.get(3).unwrap()
  assert_eq(setter.kind().to_int(), 179)
  assert_eq(
    _parser_node_field_list(setter, "typeParameters").unwrap().length(),
    1,
  )
  assert_eq(
    _parser_node_field_node(setter, "type").unwrap().kind().to_int(),
    184,
  )
}

///|
test "variable and module flags match declaration syntax" {
  let source = "var a; let b; const c=1; using d=f(); await using e=g(); namespace N.Inner{} declare global{}"
  let (statements, diagnostics, token, _) = _parse_statements_for_test(source)
  assert_eq(statements.length(), 7)
  assert_eq(diagnostics.length(), 0)
  assert_eq(token.to_int(), 1)
  let expected_flags = [0U, 1U, 2U, 4U, 6U]
  for index in 0..<expected_flags.length() {
    let declaration_list = _parser_node_field_node(
      statements.get(index).unwrap(),
      "declarationList",
    ).unwrap()
    assert_eq(
      declaration_list.flags().intersect(NodeFlags::block_scoped()).bits(),
      expected_flags[index],
    )
  }
  let namespace_node = statements.get(5).unwrap()
  assert_true(namespace_node.flags().contains(NodeFlags::namespace_flag()))
  let nested = _parser_node_field_node(namespace_node, "body").unwrap()
  assert_true(nested.flags().contains(NodeFlags::namespace_flag()))
  assert_true(nested.flags().contains(NodeFlags::nested_namespace()))
  let global = statements.get(6).unwrap()
  assert_true(global.flags().contains(NodeFlags::ambient()))
  assert_true(global.flags().contains(NodeFlags::global_augmentation()))
}

///|
test "declaration filename variants set ambient context only" {
  for file_name in ["x.d.ts", "x.d.cts", "x.d.mts", "x.d.generated.ts"] {
    let (statements, diagnostics, token, flags) = _parse_statements_for_test(
      "interface I{}",
      file_name~,
    )
    assert_eq(diagnostics.length(), 0, msg=file_name)
    assert_eq(token.to_int(), 1, msg=file_name)
    assert_true(flags.contains(NodeFlags::ambient()), msg=file_name)
    assert_false(flags.contains(NodeFlags::export_context()), msg=file_name)
    assert_true(
      statements.get(0).unwrap().flags().contains(NodeFlags::ambient()),
      msg=file_name,
    )
  }
  let (ordinary, _, _, flags) = _parse_statements_for_test(
    "interface I{}",
    file_name="x.ts",
  )
  assert_false(flags.contains(NodeFlags::ambient()))
  assert_false(ordinary.get(0).unwrap().flags().contains(NodeFlags::ambient()))
}
