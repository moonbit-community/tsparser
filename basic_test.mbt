///|
test "parse var and function" {
  let source =
    #|let x: number = 1 + 2 * 3;
    #|function add(a: number, b: number): number {
    #|  return a + b;
    #|}
    #|
  let program = parse_program(source)
  inspect(program.stmts.length(), content="2")
  match program.stmts[0].kind {
    StmtKind::VarDecl(decl) => inspect(decl.decls.length(), content="1")
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
  let program = parse_program(source)
  match program.stmts[0].kind {
    StmtKind::TypeAliasDecl(decl) => inspect(decl.name, content="ID")
    _ => fail("expected type alias")
  }
  match program.stmts[1].kind {
    StmtKind::InterfaceDecl(decl) => {
      inspect(decl.name, content="Person")
      inspect(decl.members.length(), content="2")
    }
    _ => fail("expected interface")
  }
}

///|
test "parse call and member" {
  let program = parse_program("foo.bar(1, 2)")
  match program.stmts[0].kind {
    StmtKind::ExprStmt(expr) =>
      match expr.kind {
        ExprKind::Call(call) =>
          match call.callee.kind {
            ExprKind::Member(member_expr) =>
              match member_expr.property {
                MemberProp::Ident(name) => inspect(name, content="bar")
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
  let program = parse_program(source)
  inspect(program.stmts.length(), content="3")
  match program.stmts[0].kind {
    StmtKind::ImportDecl(decl) => {
      inspect(decl.default_name, content="Some(\"Foo\")")
      inspect(decl.from, content="mod")
    }
    _ => fail("expected import declaration")
  }
  match program.stmts[1].kind {
    StmtKind::ExportDecl(_) => ()
    _ => fail("expected export declaration")
  }
  match program.stmts[2].kind {
    StmtKind::ClassDecl(decl) => inspect(decl.name, content="Some(\"Person\")")
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
  let program = parse_program(source)
  inspect(program.stmts.length(), content="6")
  match program.stmts[2].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].init {
        Some(expr) =>
          match expr.kind {
            ExprKind::Arrow(arrow) =>
              match arrow.params[0].type_ann {
                Some(ty) =>
                  match ty.kind {
                    TypeKind::Ident(name) => inspect(name, content="number")
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
                ExprKind::Ident(name) => inspect(name, content="Foo")
                _ => fail("expected new expression callee")
              }
              inspect(new_expr.args.length(), content="1")
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
  let program = parse_program(source)
  inspect(program.stmts.length(), content="3")
  match program.stmts[0].kind {
    StmtKind::ExportDecl(ExportDecl::Default(def)) =>
      match def {
        ExportDefault::Function(decl) =>
          inspect(decl.name, content="Some(\"greet\")")
        _ => fail("expected export default function")
      }
    _ => fail("expected export default declaration")
  }
  match program.stmts[1].kind {
    StmtKind::ExportDecl(ExportDecl::Default(def)) =>
      match def {
        ExportDefault::Class(decl) => inspect(decl.name, content="None")
        _ => fail("expected export default class")
      }
    _ => fail("expected export default declaration")
  }
  match program.stmts[2].kind {
    StmtKind::ExportDecl(ExportDecl::Default(def)) =>
      match def {
        ExportDefault::Expr(expr) =>
          match expr.kind {
            ExprKind::Number(value) => inspect(value, content="42")
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
  let program = parse_program(source)
  match program.stmts[0].kind {
    StmtKind::ClassDecl(decl) => {
      inspect(decl.name, content="Some(\"Box\")")
      inspect(decl.members.length(), content="4")
      let id_member = decl.members[0]
      inspect(id_member.is_readonly, content="true")
      inspect(id_member.access, content="Some(Public)")
      match id_member.kind {
        ClassMemberKind::Field(name, _, _) => inspect(name, content="id")
        _ => fail("expected field")
      }
      let count_member = decl.members[1]
      inspect(count_member.is_static, content="true")
      inspect(count_member.access, content="Some(Private)")
      match count_member.kind {
        ClassMemberKind::Field(name, _, _) => inspect(name, content="count")
        _ => fail("expected field")
      }
      let getter_member = decl.members[2]
      inspect(getter_member.access, content="Some(Protected)")
      match getter_member.kind {
        ClassMemberKind::Getter(name, _, _) => inspect(name, content="size")
        _ => fail("expected getter")
      }
      let setter_member = decl.members[3]
      match setter_member.kind {
        ClassMemberKind::Setter(name, _, _) => inspect(name, content="size")
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
  let program = parse_program(source)
  match program.stmts[0].kind {
    StmtKind::TypeAliasDecl(decl) =>
      match decl.value.kind {
        TypeKind::Tuple(elements) => inspect(elements.length(), content="2")
        _ => fail("expected tuple type")
      }
    _ => fail("expected type alias")
  }
  match program.stmts[1].kind {
    StmtKind::TypeAliasDecl(decl) =>
      match decl.value.kind {
        TypeKind::Object(members) => {
          inspect(members.length(), content="3")
          inspect(members[1].optional, content="true")
          match members[2].type_ann.kind {
            TypeKind::Literal(TypeLiteral::String(value)) =>
              inspect(value, content="x")
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
        TypeKind::Intersection(types) => inspect(types.length(), content="2")
        _ => fail("expected intersection type")
      }
    _ => fail("expected type alias")
  }
  match program.stmts[3].kind {
    StmtKind::TypeAliasDecl(decl) =>
      match decl.value.kind {
        TypeKind::Union(types) => inspect(types.length(), content="5")
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
  let program = parse_program(source)
  inspect(program.stmts.length(), content="4")
  match program.stmts[0].kind {
    StmtKind::For(stmt) =>
      match stmt.update {
        Some(expr) =>
          match expr.kind {
            ExprKind::Update(update) => inspect(update.prefix, content="false")
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
  let program = parse_program(source)
  match program.stmts[0].kind {
    StmtKind::Switch(stmt) => inspect(stmt.cases.length(), content="2")
    _ => fail("expected switch statement")
  }
  match program.stmts[1].kind {
    StmtKind::Try(stmt) =>
      match stmt.handler {
        Some(handler) =>
          match handler.param {
            Some(param) => inspect(param.name, content="e")
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
  let program = parse_program(source)
  inspect(program.stmts.length(), content="4")
  match program.stmts[0].kind {
    StmtKind::EnumDecl(decl) => {
      inspect(decl.is_const, content="true")
      inspect(decl.members.length(), content="3")
    }
    _ => fail("expected enum declaration")
  }
  match program.stmts[1].kind {
    StmtKind::InterfaceDecl(decl) => inspect(decl.extends.length(), content="2")
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
        ExprKind::Assign(assign) => inspect(assign.op, content="AddAssign")
        _ => fail("expected assignment expression")
      }
    _ => fail("expected expression statement")
  }
}

///|
test "parse optional chaining nullish template" {
  let source = "let value = foo?.bar?.(1) ?? `hi ${name}`;"
  let program = parse_program(source)
  match program.stmts[0].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].init {
        Some(expr) =>
          match expr.kind {
            ExprKind::Binary(bin) => {
              inspect(bin.op, content="Nullish")
              match bin.left.kind {
                ExprKind::Call(call) => inspect(call.optional, content="true")
                _ => fail("expected optional call")
              }
              match bin.right.kind {
                ExprKind::Template(tmpl) => {
                  inspect(tmpl.quasis.length(), content="2")
                  inspect(tmpl.exprs.length(), content="1")
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
  let program = parse_program(source)
  inspect(program.stmts.length(), content="4")
  match program.stmts[0].kind {
    StmtKind::VarDecl(decl) =>
      match decl.decls[0].pattern.kind {
        BindingPatternKind::Object(obj) =>
          inspect(obj.props.length(), content="3")
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
  let program = parse_program(source)
  match program.stmts[0].kind {
    StmtKind::ImportDecl(decl) => {
      inspect(decl.is_type_only, content="true")
      inspect(decl.named.length(), content="2")
      inspect(decl.named[0].is_type_only, content="true")
      inspect(decl.named[1].is_type_only, content="false")
    }
    _ => fail("expected import declaration")
  }
  match program.stmts[1].kind {
    StmtKind::ExportDecl(ExportDecl::Named(named)) => {
      inspect(named.is_type_only, content="true")
      inspect(named.specs.length(), content="2")
      inspect(named.specs[0].is_type_only, content="false")
      inspect(named.specs[1].is_type_only, content="true")
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
  let program = parse_program(source)
  match program.stmts[0].kind {
    StmtKind::TypeAliasDecl(decl) =>
      inspect(decl.type_params.length(), content="2")
    _ => fail("expected type alias")
  }
  match program.stmts[1].kind {
    StmtKind::InterfaceDecl(decl) =>
      inspect(decl.type_params.length(), content="1")
    _ => fail("expected interface")
  }
  match program.stmts[2].kind {
    StmtKind::ClassDecl(decl) => inspect(decl.type_params.length(), content="1")
    _ => fail("expected class")
  }
  match program.stmts[3].kind {
    StmtKind::FunctionDecl(decl) =>
      inspect(decl.type_params.length(), content="1")
    _ => fail("expected function")
  }
}
