///|
test "parse var and function" {
  let source =
    #|let x: number = 1 + 2 * 3;
    #|function add(a: number, b: number): number {
    #|  return a + b;
    #|}
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  assert_eq(program.stmts.length(), 2)
  match program.stmts[0].kind {
    StmtKind::VarDecl(decl) => assert_eq(decl.decls.length(), 1)
    _ => fail("expected var declaration")
  }
}

///|
test "parse type alias and interface" {
  let source =
    #|type ID = string | number;
    #|interface Person {
    #|  name: string;
    #|  age?: number;
    #|}
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::TypeAliasDecl(decl) => assert_eq(decl.name, "ID")
    _ => fail("expected type alias")
  }
  match program.stmts[1].kind {
    StmtKind::InterfaceDecl(decl) => {
      assert_eq(decl.name, "Person")
      assert_eq(decl.members.length(), 2)
    }
    _ => fail("expected interface")
  }
}

///|
test "parse call and member" {
  let (errors, program) = parse_program("foo.bar(1, 2)")
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::ExprStmt(expr) =>
      match expr.kind {
        ExprKind::Call(call) =>
          match call.callee.kind {
            ExprKind::Member(member_expr) =>
              match member_expr.property {
                MemberProp::Ident(name) => assert_eq(name, "bar")
                _ => fail("expected identifier member")
              }
            _ => fail("expected member expression")
          }
        _ => fail("expected call expression")
      }
    _ => fail("expected expression statement")
  }
}

///|
test "parse import export class" {
  let source =
    #|import Foo, { bar as baz } from "mod";
    #|export { baz };
    #|class Person extends Human implements Named {
    #|  constructor(name: string) { this.name = name; }
    #|  greet(): void { return; }
    #|  age: number;
    #|}
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  assert_eq(program.stmts.length(), 3)
  match program.stmts[0].kind {
    StmtKind::ImportDecl(decl) => {
      assert_eq(decl.default_name, Some("Foo"))
      assert_eq(decl.from, "mod")
    }
    _ => fail("expected import declaration")
  }
  match program.stmts[1].kind {
    StmtKind::ExportDecl(_) => ()
    _ => fail("expected export declaration")
  }
  match program.stmts[2].kind {
    StmtKind::ClassDecl(decl) => assert_eq(decl.name, Some("Person"))
    _ => fail("expected class declaration")
  }
}

///|
test "parse arrow object array new as" {
  let source =
    #|let f = (x, y) => x + y;
    #|let g = x => ({ value: x });
    #|let h = x: number => x;
    #|let a = [1, 2];
    #|let o = { a: 1, b };
    #|let n = new Foo(1) as Bar;
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  assert_eq(program.stmts.length(), 6)
  match program.stmts[2].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].init {
        Some(expr) =>
          match expr.kind {
            ExprKind::Arrow(arrow) =>
              match arrow.params[0].type_ann {
                Some(ty) =>
                  match ty.kind {
                    TypeKind::Ident(name) => assert_eq(name, "number")
                    _ => fail("expected identifier type")
                  }
                None => fail("expected parameter type")
              }
            _ => fail("expected arrow function")
          }
        None => fail("expected initializer")
      }
    _ => fail("expected var declaration")
  }
  match program.stmts[5].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].init {
        Some(expr) =>
          match expr.kind {
            ExprKind::New(new_expr) => {
              match new_expr.callee.kind {
                ExprKind::Ident(name) => assert_eq(name, "Foo")
                _ => fail("expected new expression callee")
              }
              assert_eq(new_expr.args.length(), 1)
            }
            _ => fail("expected new expression")
          }
        None => fail("expected initializer")
      }
    _ => fail("expected var declaration")
  }
}

///|
test "parse export default forms" {
  let source =
    #|export default function greet() { return; }
    #|export default class { }
    #|export default 42;
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  assert_eq(program.stmts.length(), 3)
  match program.stmts[0].kind {
    StmtKind::ExportDecl(ExportDecl::Default(def)) =>
      match def {
        ExportDefault::Function(decl) => assert_eq(decl.name, Some("greet"))
        _ => fail("expected export default function")
      }
    _ => fail("expected export default declaration")
  }
  match program.stmts[1].kind {
    StmtKind::ExportDecl(ExportDecl::Default(def)) =>
      match def {
        ExportDefault::Class(decl) => assert_eq(decl.name, None)
        _ => fail("expected export default class")
      }
    _ => fail("expected export default declaration")
  }
  match program.stmts[2].kind {
    StmtKind::ExportDecl(ExportDecl::Default(def)) =>
      match def {
        ExportDefault::Expr(expr) =>
          match expr.kind {
            ExprKind::Number(value) => assert_eq(value, "42")
            _ => fail("expected number literal")
          }
        _ => fail("expected export default expr")
      }
    _ => fail("expected export default declaration")
  }
}

///|
test "parse class modifiers and accessors" {
  let source =
    #|class Box {
    #|  public readonly id: number;
    #|  private static count: number = 0;
    #|  protected get size(): number { return this._size; }
    #|  set size(value: number) { this._size = value; }
    #|}
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::ClassDecl(decl) => {
      assert_eq(decl.name, Some("Box"))
      assert_eq(decl.members.length(), 4)
      let id_member = decl.members[0]
      assert_eq(id_member.is_readonly, true)
      match id_member.access {
        Some(AccessModifier::Public) => ()
        _ => fail("expected public access")
      }
      match id_member.kind {
        ClassMemberKind::Field(name, _, _) => assert_eq(name, "id")
        _ => fail("expected field")
      }
      let count_member = decl.members[1]
      assert_eq(count_member.is_static, true)
      match count_member.access {
        Some(AccessModifier::Private) => ()
        _ => fail("expected private access")
      }
      match count_member.kind {
        ClassMemberKind::Field(name, _, _) => assert_eq(name, "count")
        _ => fail("expected field")
      }
      let getter_member = decl.members[2]
      match getter_member.access {
        Some(AccessModifier::Protected) => ()
        _ => fail("expected protected access")
      }
      match getter_member.kind {
        ClassMemberKind::Getter(name, _, _) => assert_eq(name, "size")
        _ => fail("expected getter")
      }
      let setter_member = decl.members[3]
      match setter_member.kind {
        ClassMemberKind::Setter(name, _, _) => assert_eq(name, "size")
        _ => fail("expected setter")
      }
    }
    _ => fail("expected class declaration")
  }
}

///|
test "parse extended types" {
  let source =
    #|type Pair = [number, string];
    #|type Opts = { name: string; age?: number; "tag": "x" };
    #|type Both = Foo & Bar;
    #|type Mode = "on" | "off" | 0 | true | null;
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::TypeAliasDecl(decl) =>
      match decl.value.kind {
        TypeKind::Tuple(elements) => assert_eq(elements.length(), 2)
        _ => fail("expected tuple type")
      }
    _ => fail("expected type alias")
  }
  match program.stmts[1].kind {
    StmtKind::TypeAliasDecl(decl) =>
      match decl.value.kind {
        TypeKind::Object(members) => {
          assert_eq(members.length(), 3)
          assert_eq(members[1].optional, true)
          match members[2].type_ann.kind {
            TypeKind::Literal(TypeLiteral::String(value)) =>
              assert_eq(value, "x")
            _ => fail("expected string literal type")
          }
        }
        _ => fail("expected object type")
      }
    _ => fail("expected type alias")
  }
  match program.stmts[2].kind {
    StmtKind::TypeAliasDecl(decl) =>
      match decl.value.kind {
        TypeKind::Intersection(types) => assert_eq(types.length(), 2)
        _ => fail("expected intersection type")
      }
    _ => fail("expected type alias")
  }
  match program.stmts[3].kind {
    StmtKind::TypeAliasDecl(decl) =>
      match decl.value.kind {
        TypeKind::Union(types) => assert_eq(types.length(), 5)
        _ => fail("expected union type")
      }
    _ => fail("expected type alias")
  }
}

///|
test "parse for and do while" {
  let source =
    #|for (let i = 0; i < 3; i++) { if (i == 1) break; }
    #|for (const item of items) { continue; }
    #|for (key in obj) { }
    #|do { value++; } while (value < 10);
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  assert_eq(program.stmts.length(), 4)
  match program.stmts[0].kind {
    StmtKind::For(stmt) =>
      match stmt.update {
        Some(expr) =>
          match expr.kind {
            ExprKind::Update(update) => assert_eq(update.prefix, false)
            _ => fail("expected update expression")
          }
        None => fail("expected update expression")
      }
    _ => fail("expected for statement")
  }
  match program.stmts[1].kind {
    StmtKind::ForOf(_) => ()
    _ => fail("expected for-of statement")
  }
  match program.stmts[2].kind {
    StmtKind::ForIn(_) => ()
    _ => fail("expected for-in statement")
  }
  match program.stmts[3].kind {
    StmtKind::DoWhile(_) => ()
    _ => fail("expected do-while statement")
  }
}

///|
test "parse switch and try" {
  let source =
    #|switch (mode) {
    #|  case 1: count += 1; break;
    #|  default: throw err;
    #|}
    #|try { risky(); } catch (e: Error) { handle(e); } finally { cleanup(); }
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::Switch(stmt) => assert_eq(stmt.cases.length(), 2)
    _ => fail("expected switch statement")
  }
  match program.stmts[1].kind {
    StmtKind::Try(stmt) =>
      match stmt.handler {
        Some(handler) =>
          match handler.param {
            Some(param) => assert_eq(param.name, "e")
            None => fail("expected catch param")
          }
        None => fail("expected catch clause")
      }
    _ => fail("expected try statement")
  }
}

///|
test "parse enum interface extends and conditional" {
  let source =
    #|const enum Color { Red = 1, Green, Blue = 4 }
    #|interface Box extends Size, Shape { value: string; }
    #|let flag = ok ? 1 : 2;
    #|count += 1;
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  assert_eq(program.stmts.length(), 4)
  match program.stmts[0].kind {
    StmtKind::EnumDecl(decl) => {
      assert_eq(decl.is_const, true)
      assert_eq(decl.members.length(), 3)
    }
    _ => fail("expected enum declaration")
  }
  match program.stmts[1].kind {
    StmtKind::InterfaceDecl(decl) => assert_eq(decl.extends.length(), 2)
    _ => fail("expected interface declaration")
  }
  match program.stmts[2].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].init {
        Some(expr) =>
          match expr.kind {
            ExprKind::Conditional(_) => ()
            _ => fail("expected conditional expression")
          }
        None => fail("expected initializer")
      }
    _ => fail("expected var declaration")
  }
  match program.stmts[3].kind {
    StmtKind::ExprStmt(expr) =>
      match expr.kind {
        ExprKind::Assign(assign) =>
          match assign.op {
            AssignOp::AddAssign => ()
            _ => fail("expected add-assign")
          }
        _ => fail("expected assignment expression")
      }
    _ => fail("expected expression statement")
  }
}

///|
test "parse optional chaining nullish template" {
  let source = "let value = foo?.bar?.(1) ?? `hi ${name}`;"
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].init {
        Some(expr) =>
          match expr.kind {
            ExprKind::Binary(bin) => {
              match bin.op {
                BinaryOp::Nullish => ()
                _ => fail("expected nullish operator")
              }
              match bin.left.kind {
                ExprKind::Call(call) => assert_eq(call.optional, true)
                _ => fail("expected optional call")
              }
              match bin.right.kind {
                ExprKind::Template(tmpl) => {
                  assert_eq(tmpl.quasis.length(), 2)
                  assert_eq(tmpl.exprs.length(), 1)
                }
                _ => fail("expected template literal")
              }
            }
            _ => fail("expected nullish coalescing")
          }
        None => fail("expected initializer")
      }
    _ => fail("expected var declaration")
  }
}

///|
test "parse destructuring and spread" {
  let source =
    #|const { a, b: c = 2, ...rest } = obj;
    #|let [x, , ...ys] = arr;
    #|let o = { ...base, a: 1, b };
    #|let arr2 = [0, ...xs, , 3];
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  assert_eq(program.stmts.length(), 4)
  match program.stmts[0].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].pattern.kind {
        BindingPatternKind::Object(obj) => assert_eq(obj.props.length(), 3)
        _ => fail("expected object pattern")
      }
    _ => fail("expected var declaration")
  }
  match program.stmts[1].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].pattern.kind {
        BindingPatternKind::Array(arr) =>
          match arr.elems[1] {
            ArrayPatternElem::Hole => ()
            _ => fail("expected hole element")
          }
        _ => fail("expected array pattern")
      }
    _ => fail("expected var declaration")
  }
  match program.stmts[2].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].init {
        Some(expr) =>
          match expr.kind {
            ExprKind::Object(obj) =>
              match obj.props[0] {
                ObjectProp::Spread(_) => ()
                _ => fail("expected spread property")
              }
            _ => fail("expected object literal")
          }
        None => fail("expected initializer")
      }
    _ => fail("expected var declaration")
  }
  match program.stmts[3].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].init {
        Some(expr) =>
          match expr.kind {
            ExprKind::Array(elements) =>
              match elements[2] {
                ArrayElement::Hole => ()
                _ => fail("expected hole element")
              }
            _ => fail("expected array literal")
          }
        None => fail("expected initializer")
      }
    _ => fail("expected var declaration")
  }
}

///|
test "parse type-only import export" {
  let source =
    #|import type Foo, { type Bar as Baz, Qux } from "mod";
    #|export type { Foo, type Bar as Baz };
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::ImportDecl(decl) => {
      assert_eq(decl.is_type_only, true)
      assert_eq(decl.named.length(), 2)
      assert_eq(decl.named[0].is_type_only, true)
      assert_eq(decl.named[1].is_type_only, false)
    }
    _ => fail("expected import declaration")
  }
  match program.stmts[1].kind {
    StmtKind::ExportDecl(ExportDecl::Named(named)) => {
      assert_eq(named.is_type_only, true)
      assert_eq(named.specs.length(), 2)
      assert_eq(named.specs[0].is_type_only, false)
      assert_eq(named.specs[1].is_type_only, true)
    }
    _ => fail("expected export named declaration")
  }
}

///|
test "parse type parameters" {
  let source =
    #|type Pair<T, U = string> = [T, U];
    #|interface Box<T> extends Size<T> { value: T; }
    #|class Foo<T extends Bar> { }
    #|function id<T>(x: T): T { return x; }
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::TypeAliasDecl(decl) => assert_eq(decl.type_params.length(), 2)
    _ => fail("expected type alias")
  }
  match program.stmts[1].kind {
    StmtKind::InterfaceDecl(decl) => assert_eq(decl.type_params.length(), 1)
    _ => fail("expected interface")
  }
  match program.stmts[2].kind {
    StmtKind::ClassDecl(decl) => assert_eq(decl.type_params.length(), 1)
    _ => fail("expected class")
  }
  match program.stmts[3].kind {
    StmtKind::FunctionDecl(decl) => assert_eq(decl.type_params.length(), 1)
    _ => fail("expected function")
  }
}

///|
test "collect statement parse errors" {
  let (errors, _) = parse_program("function (x) {}")
  assert_true(errors.length() > 0)
}

///|
test "collect expression recovery errors" {
  let (errors, program) = parse_program("foo(,);")
  assert_true(errors.length() > 0)
  assert_true(program.stmts.length() > 0)
}

///|
test "invalid rest-only arrow parameter reports error" {
  let (errors, _) = parse_program("(... ) => {};")
  assert_true(errors.length() > 0)
}

///|
test "invalid accessibility modifier in arrow parameter reports error" {
  let (errors, _) = parse_program("(public foo) => {};")
  assert_true(errors.length() > 0)
}

///|
test "invalid accessibility modifier in function type reports error" {
  let (errors, _) = parse_program("declare const foo: (public bar) => baz;")
  assert_true(errors.length() > 0)
}

///|
test "parse undefined type literal" {
  let (errors, program) = parse_program("type U = undefined;")
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::TypeAliasDecl(decl) =>
      match decl.value.kind {
        TypeKind::Literal(TypeLiteral::Undefined) => ()
        _ => fail("expected undefined type literal")
      }
    _ => fail("expected type alias")
  }
}

///|
test "distinguish yield star from yield" {
  let source =
    #|function* g() {
    #|  yield* source;
    #|  yield source;
    #|}
    #|
  let (errors, program) = parse_program(source)
  assert_eq(errors.length(), 0)
  match program.stmts[0].kind {
    StmtKind::FunctionDecl(decl) => {
      match decl.body.stmts[0].kind {
        StmtKind::ExprStmt(expr) =>
          match expr.kind {
            ExprKind::Unary(unary) =>
              match unary.op {
                UnaryOp::YieldStar => ()
                _ => fail("expected yield-star")
              }
            _ => fail("expected unary expression")
          }
        _ => fail("expected expression statement")
      }
      match decl.body.stmts[1].kind {
        StmtKind::ExprStmt(expr) =>
          match expr.kind {
            ExprKind::Unary(unary) =>
              match unary.op {
                UnaryOp::Yield => ()
                _ => fail("expected yield")
              }
            _ => fail("expected unary expression")
          }
        _ => fail("expected expression statement")
      }
    }
    _ => fail("expected function declaration")
  }
}

///|
test "empty element access reports error" {
  let (errors, program) = parse_program("foo[];")
  assert_true(errors.length() > 0)
  match program.stmts[0].kind {
    StmtKind::ExprStmt(expr) =>
      match expr.kind {
        ExprKind::Member(member_expr) =>
          match member_expr.property {
            MemberProp::Expr(prop) =>
              match prop.kind {
                ExprKind::Ident(name) => assert_eq(name, "")
                _ => fail("expected placeholder identifier")
              }
            _ => fail("expected computed member")
          }
        _ => fail("expected member expression")
      }
    _ => fail("expected expression statement")
  }
}

///|
test "empty template interpolation reports error" {
  let (errors, program) = parse_program("`${}`;")
  assert_true(errors.length() > 0)
  match program.stmts[0].kind {
    StmtKind::ExprStmt(expr) =>
      match expr.kind {
        ExprKind::Template(tmpl) =>
          match tmpl.exprs[0].kind {
            ExprKind::Ident(name) => assert_eq(name, "")
            _ => fail("expected placeholder identifier")
          }
        _ => fail("expected template literal")
      }
    _ => fail("expected expression statement")
  }
}

///|
test "rest parameter must be last" {
  let (errors, _) = parse_program("function foo(...bar, baz) {}")
  assert_true(errors.length() > 0)
}

///|
test "new type must use constructor signature form" {
  let (errors, _) = parse_program("type Foo = abstract new Bar;")
  assert_true(errors.length() > 0)
}
