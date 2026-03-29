///|
pub enum ScriptKind {
  Ts
  Tsx
  Js
  Jsx
  Dts
  Json
} derive(Eq, Debug)

///|
pub enum JsDocParsingMode {
  ParseAll
  ParseNone
} derive(Eq, Debug)

///|
pub struct ParseOptions {
  file_name : String
  script_kind : ScriptKind
  language_target : String?
  jsx_mode : Bool
  strict_mode : Bool
  module_kind : String?
  jsdoc_parsing_mode : JsDocParsingMode
  allow_js : Bool
  has_multi_target_directive : Bool
  report_unreachable_code : Bool
  isolated_modules : Bool
  allow_synthetic_default_imports : Bool
  verbatim_module_syntax : Bool
  erasable_syntax_only : Bool
  experimental_decorators : Bool
} derive(Debug)

///|
pub enum CommentKind {
  Line
  Block
  JsDoc
} derive(Debug)

///|
pub struct CommentRange {
  kind : CommentKind
  span : Span
  text : String
} derive(Debug)

///|
pub enum CommentDirectiveKind {
  TsIgnore
  TsExpectError
  TsNoCheck
  TsCheck
} derive(Debug)

///|
pub struct CommentDirective {
  kind : CommentDirectiveKind
  span : Span
  text : String
} derive(Debug)

///|
pub struct SourceFile {
  file_name : String
  script_kind : ScriptKind
  is_declaration_file : Bool
  stmts : Array[Stmt]
  parse_errors : Array[ParseError]
  comment_directives : Array[CommentDirective]
  comments : Array[CommentRange]
  strict_mode : Bool
  module_kind : String?
  language_target : String?
  jsx_mode : Bool
  jsdoc_parsing_mode : JsDocParsingMode
  external_module_indicator : Bool
  identifiers : Array[String]
} derive(Debug)
