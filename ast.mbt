///|
pub struct Program {
  stmts : Array[Stmt]
} derive(Show, ToJson)

///|
pub struct Block {
  stmts : Array[Stmt]
  span : Span
} derive(Show, ToJson)

///|
pub struct Stmt {
  kind : StmtKind
  span : Span
} derive(Show, ToJson)

///|
pub enum StmtKind {
  ImportDecl(ImportDecl)
  ImportAssign(ImportAssignDecl)
  ExportDecl(ExportDecl)
  VarDecl(VarDecl)
  FunctionDecl(FunctionDecl)
  ClassDecl(ClassDecl)
  NamespaceDecl(NamespaceDecl)
  TypeAliasDecl(TypeAliasDecl)
  InterfaceDecl(InterfaceDecl)
  EnumDecl(EnumDecl)
  Return(Expr?)
  If(Expr, Stmt, Stmt?)
  While(Expr, Stmt)
  For(ForStmt)
  ForIn(ForInStmt)
  ForOf(ForOfStmt)
  DoWhile(DoWhileStmt)
  Switch(SwitchStmt)
  Break(String?)
  Continue(String?)
  Throw(Expr)
  Try(TryStmt)
  Labeled(LabeledStmt)
  ExprStmt(Expr)
  Block(Block)
  Empty
} derive(Show, ToJson)

///|
pub struct LabeledStmt {
  label : String
  stmt : Stmt
} derive(Show, ToJson)

///|
pub struct NamespaceDecl {
  name : String
  body : Block
  span : Span
} derive(Show, ToJson)

///|
pub enum VarKind {
  Let
  Const
  Var
} derive(Show, ToJson)

///|
pub struct VarDecl {
  kind : VarKind
  decls : Array[VarDeclarator]
} derive(Show, ToJson)

///|
pub struct BindingPattern {
  kind : BindingPatternKind
  span : Span
} derive(Show, ToJson)

///|
pub enum BindingPatternKind {
  Ident(String)
  Object(ObjectPattern)
  Array(ArrayPattern)
} derive(Show, ToJson)

///|
pub struct BindingElement {
  pattern : BindingPattern
  default_value : Expr?
  span : Span
} derive(Show, ToJson)

///|
pub struct ObjectPattern {
  props : Array[ObjectPatternProp]
} derive(Show, ToJson)

///|
pub enum ObjectPatternProp {
  Property(ObjectPatternProperty)
  Rest(BindingPattern)
} derive(Show, ToJson)

///|
pub struct ObjectPatternProperty {
  key : String
  binding : BindingElement
  shorthand : Bool
  span : Span
} derive(Show, ToJson)

///|
pub struct ArrayPattern {
  elems : Array[ArrayPatternElem]
} derive(Show, ToJson)

///|
pub enum ArrayPatternElem {
  Elem(BindingElement)
  Rest(BindingPattern)
  Hole
} derive(Show, ToJson)

///|
pub struct VarDeclarator {
  pattern : BindingPattern
  type_ann : TypeNode?
  init : Expr?
  span : Span
} derive(Show, ToJson)

///|
pub enum ForInit {
  Var(VarDecl)
  Expr(Expr)
} derive(Show, ToJson)

///|
pub enum ForInLeft {
  Var(VarDecl)
  Expr(Expr)
} derive(Show, ToJson)

///|
pub struct ForStmt {
  init : ForInit?
  condition : Expr?
  update : Expr?
  body : Stmt
} derive(Show, ToJson)

///|
pub struct ForInStmt {
  left : ForInLeft
  right : Expr
  body : Stmt
} derive(Show, ToJson)

///|
pub struct ForOfStmt {
  left : ForInLeft
  right : Expr
  body : Stmt
} derive(Show, ToJson)

///|
pub struct DoWhileStmt {
  body : Stmt
  condition : Expr
} derive(Show, ToJson)

///|
pub struct SwitchStmt {
  discriminant : Expr
  cases : Array[SwitchCase]
} derive(Show, ToJson)

///|
pub struct SwitchCase {
  case_expr : Expr?
  consequent : Array[Stmt]
} derive(Show, ToJson)

///|
pub struct TryStmt {
  block : Block
  handler : CatchClause?
  finalizer : Block?
} derive(Show, ToJson)

///|
pub struct CatchClause {
  param : CatchParam?
  body : Block
} derive(Show, ToJson)

///|
pub struct CatchParam {
  name : String
  type_ann : TypeNode?
  span : Span
} derive(Show, ToJson)

///|
pub struct TypeParam {
  name : String
  constraint : TypeNode?
  default_type : TypeNode?
  span : Span
} derive(Show, ToJson)

///|
pub struct FunctionDecl {
  name : String?
  type_params : Array[TypeParam]
  params : Array[Param]
  return_type : TypeNode?
  body : Block
} derive(Show, ToJson)

///|
pub struct Param {
  pattern : BindingPattern
  optional : Bool
  type_ann : TypeNode?
  default_value : Expr?
  is_rest : Bool
  span : Span
} derive(Show, ToJson)

///|
pub struct TypeAliasDecl {
  name : String
  type_params : Array[TypeParam]
  value : TypeNode
  span : Span
} derive(Show, ToJson)

///|
pub struct InterfaceDecl {
  name : String
  type_params : Array[TypeParam]
  extends : Array[TypeNode]
  members : Array[InterfaceMember]
  span : Span
} derive(Show, ToJson)

///|
pub struct EnumDecl {
  name : String
  members : Array[EnumMember]
  is_const : Bool
  span : Span
} derive(Show, ToJson)

///|
pub struct EnumMember {
  name : String
  init : Expr?
  span : Span
} derive(Show, ToJson)

///|
pub struct InterfaceMember {
  name : String
  optional : Bool
  type_ann : TypeNode
  span : Span
} derive(Show, ToJson)

///|
pub struct ImportDecl {
  is_type_only : Bool
  default_name : String?
  ns_name : String?
  named : Array[ImportSpec]
  from : String
  span : Span
} derive(Show, ToJson)

///|
pub struct ImportAssignDecl {
  name : String
  value : Expr
  span : Span
} derive(Show, ToJson)

///|
pub struct ImportSpec {
  is_type_only : Bool
  name : String
  as_name : String?
  span : Span
} derive(Show, ToJson)

///|
pub enum ExportDecl {
  Named(ExportNamed)
  Default(ExportDefault)
  Declaration(Stmt)
  Assign(Expr)
} derive(Show, ToJson)

///|
pub enum ExportDefault {
  Expr(Expr)
  Function(FunctionDecl)
  Class(ClassDecl)
} derive(Show, ToJson)

///|
pub struct ExportNamed {
  is_type_only : Bool
  specs : Array[ExportSpec]
  from : String?
} derive(Show, ToJson)

///|
pub struct ExportSpec {
  is_type_only : Bool
  name : String
  as_name : String?
  span : Span
} derive(Show, ToJson)

///|
pub struct ClassDecl {
  name : String?
  type_params : Array[TypeParam]
  extends : Expr?
  implements : Array[TypeNode]
  members : Array[ClassMember]
  span : Span
} derive(Show, ToJson)

///|
pub struct ClassMember {
  kind : ClassMemberKind
  is_static : Bool
  access : AccessModifier?
  is_readonly : Bool
  span : Span
} derive(Show, ToJson)

///|
pub enum ClassMemberKind {
  Constructor(Array[Param], Block)
  Method(String, Array[Param], TypeNode?, Block)
  Getter(String, TypeNode?, Block)
  Setter(String, Param, Block)
  Field(String, TypeNode?, Expr?)
} derive(Show, ToJson)

///|
pub enum AccessModifier {
  Public
  Private
  Protected
} derive(Show, ToJson)

///|
pub struct Expr {
  kind : ExprKind
  span : Span
} derive(Show, ToJson)

///|
pub enum ExprKind {
  Ident(String)
  Number(String)
  String(String)
  Bool(Bool)
  Null
  Undefined
  This
  Array(Array[ArrayElement])
  Object(ObjectLiteral)
  Function(FunctionDecl)
  Class(ClassDecl)
  Arrow(ArrowFunction)
  New(NewExpr)
  TypeAssert(TypeAssert)
  Template(TemplateLiteral)
  Unary(UnaryExpr)
  Update(UpdateExpr)
  NonNull(Expr)
  Binary(BinaryExpr)
  Conditional(ConditionalExpr)
  Assign(AssignExpr)
  Call(CallExpr)
  Member(MemberExpr)
} derive(Show, ToJson)

///|
pub enum ArrayElement {
  Expr(Expr)
  Spread(Expr)
  Hole
} derive(Show, ToJson)

///|
pub struct ObjectLiteral {
  props : Array[ObjectProp]
} derive(Show, ToJson)

///|
pub enum ObjectProp {
  Property(ObjectPropEntry)
  Spread(Expr)
} derive(Show, ToJson)

///|
pub struct ObjectPropEntry {
  name : String
  value : Expr
  shorthand : Bool
  span : Span
} derive(Show, ToJson)

///|
pub struct ArrowFunction {
  type_params : Array[TypeParam]
  params : Array[Param]
  return_type : TypeNode?
  body : FunctionBody
} derive(Show, ToJson)

///|
pub enum FunctionBody {
  Block(Block)
  Expr(Expr)
} derive(Show, ToJson)

///|
pub struct NewExpr {
  callee : Expr
  args : Array[Expr]
} derive(Show, ToJson)

///|
pub struct TemplateLiteral {
  quasis : Array[String]
  exprs : Array[Expr]
} derive(Show, ToJson)

///|
pub struct TypeAssert {
  expr : Expr
  type_ann : TypeNode
} derive(Show, ToJson)

///|
pub enum UpdateOp {
  Increment
  Decrement
} derive(Show, ToJson)

///|
pub struct UpdateExpr {
  op : UpdateOp
  prefix : Bool
  expr : Expr
} derive(Show, ToJson)

///|
pub enum UnaryOp {
  Plus
  Minus
  Not
  BitNot
  Typeof
  Delete
  Void
  Await
  Yield
  YieldStar
} derive(Show, ToJson)

///|
pub struct UnaryExpr {
  op : UnaryOp
  expr : Expr
} derive(Show, ToJson)

///|
pub enum BinaryOp {
  Add
  Sub
  Mul
  Div
  Mod
  Eq
  Neq
  StrictEq
  StrictNeq
  Lt
  Lte
  Gt
  Gte
  Instanceof
  In
  And
  Or
  Nullish
  BitAnd
  BitOr
  BitXor
  Shl
  Shr
  UShr
  Comma
  Pow
} derive(Show, ToJson)

///|
pub struct BinaryExpr {
  op : BinaryOp
  left : Expr
  right : Expr
} derive(Show, ToJson)

///|
pub struct ConditionalExpr {
  condition : Expr
  consequent : Expr
  alternate : Expr
} derive(Show, ToJson)

///|
pub enum AssignOp {
  Assign
  AddAssign
  SubAssign
  MulAssign
  DivAssign
  ModAssign
  BitAndAssign
  BitOrAssign
  BitXorAssign
  ShlAssign
  ShrAssign
  UShrAssign
} derive(Show, ToJson)

///|
pub struct AssignExpr {
  op : AssignOp
  target : Expr
  value : Expr
} derive(Show, ToJson)

///|
pub struct CallExpr {
  callee : Expr
  args : Array[Expr]
  optional : Bool
} derive(Show, ToJson)

///|
pub enum MemberProp {
  Ident(String)
  Expr(Expr)
} derive(Show, ToJson)

///|
pub struct MemberExpr {
  object : Expr
  property : MemberProp
  computed : Bool
  optional : Bool
} derive(Show, ToJson)

///|
pub struct TypeNode {
  kind : TypeKind
  span : Span
} derive(Show, ToJson)

///|
pub enum TypeKind {
  Ident(String)
  TypeQuery(String)
  Literal(TypeLiteral)
  Tuple(Array[TypeNode])
  Object(Array[TypeMember])
  Union(Array[TypeNode])
  Intersection(Array[TypeNode])
  Conditional(TypeNode, TypeNode, TypeNode, TypeNode)
  TypeOperator(String, TypeNode)
  TypePredicate(String, TypeNode)
  Array(TypeNode)
  IndexAccess(TypeNode, TypeNode)
  Generic(TypeNode, Array[TypeNode])
  Function(Array[TypeNode], TypeNode)
} derive(Show, ToJson)

///|
pub enum TypeLiteral {
  String(String)
  Number(String)
  Bool(Bool)
  Null
  Undefined
} derive(Show, ToJson)

///|
pub struct TypeMember {
  name : String
  optional : Bool
  type_ann : TypeNode
  span : Span
} derive(Show, ToJson)
