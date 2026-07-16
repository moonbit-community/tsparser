// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts, src/compiler/utilities.ts, and src/compiler/parser.ts
// at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// ECMAScript/JSON parsing target with TypeScript's explicit numeric values.
pub struct ScriptTarget(Int) derive(Eq, Compare, Debug)

///|
pub fn ScriptTarget::from_int(value : Int) -> ScriptTarget? {
  if (value >= 0 && value <= 12) || value == 99 || value == 100 {
    Some(ScriptTarget(value))
  } else {
    None
  }
}

///|
pub fn ScriptTarget::to_int(self : ScriptTarget) -> Int {
  let ScriptTarget(value) = self
  value
}

///|
pub fn ScriptTarget::es3() -> ScriptTarget {
  ScriptTarget(0)
}

///|
pub fn ScriptTarget::es5() -> ScriptTarget {
  ScriptTarget(1)
}

///|
pub fn ScriptTarget::es2015() -> ScriptTarget {
  ScriptTarget(2)
}

///|
pub fn ScriptTarget::es2016() -> ScriptTarget {
  ScriptTarget(3)
}

///|
pub fn ScriptTarget::es2017() -> ScriptTarget {
  ScriptTarget(4)
}

///|
pub fn ScriptTarget::es2018() -> ScriptTarget {
  ScriptTarget(5)
}

///|
pub fn ScriptTarget::es2019() -> ScriptTarget {
  ScriptTarget(6)
}

///|
pub fn ScriptTarget::es2020() -> ScriptTarget {
  ScriptTarget(7)
}

///|
pub fn ScriptTarget::es2021() -> ScriptTarget {
  ScriptTarget(8)
}

///|
pub fn ScriptTarget::es2022() -> ScriptTarget {
  ScriptTarget(9)
}

///|
pub fn ScriptTarget::es2023() -> ScriptTarget {
  ScriptTarget(10)
}

///|
pub fn ScriptTarget::es2024() -> ScriptTarget {
  ScriptTarget(11)
}

///|
pub fn ScriptTarget::es2025() -> ScriptTarget {
  ScriptTarget(12)
}

///|
pub fn ScriptTarget::es_next() -> ScriptTarget {
  ScriptTarget(99)
}

///|
pub fn ScriptTarget::latest() -> ScriptTarget {
  ScriptTarget::es_next()
}

///|
pub fn ScriptTarget::latest_standard() -> ScriptTarget {
  ScriptTarget::es2025()
}

///|
pub fn ScriptTarget::json() -> ScriptTarget {
  ScriptTarget(100)
}

///|
pub fn ScriptTarget::runtime_name(self : ScriptTarget) -> String {
  match self.to_int() {
    0 => "ES3"
    1 => "ES5"
    2 => "ES2015"
    3 => "ES2016"
    4 => "ES2017"
    5 => "ES2018"
    6 => "ES2019"
    7 => "ES2020"
    8 => "ES2021"
    9 => "ES2022"
    10 => "ES2023"
    11 => "ES2024"
    12 => "LatestStandard"
    99 => "Latest"
    100 => "JSON"
    _ => abort("invalid ScriptTarget")
  }
}

///|
/// Source-language mode selected by an explicit option or file extension.
pub struct ScriptKind(Int) derive(Eq, Compare, Debug)

///|
pub fn ScriptKind::from_int(value : Int) -> ScriptKind? {
  if value >= 0 && value <= 7 {
    Some(ScriptKind(value))
  } else {
    None
  }
}

///|
pub fn ScriptKind::to_int(self : ScriptKind) -> Int {
  let ScriptKind(value) = self
  value
}

///|
pub fn ScriptKind::unknown() -> ScriptKind {
  ScriptKind(0)
}

///|
pub fn ScriptKind::js() -> ScriptKind {
  ScriptKind(1)
}

///|
pub fn ScriptKind::jsx() -> ScriptKind {
  ScriptKind(2)
}

///|
pub fn ScriptKind::ts() -> ScriptKind {
  ScriptKind(3)
}

///|
pub fn ScriptKind::tsx() -> ScriptKind {
  ScriptKind(4)
}

///|
pub fn ScriptKind::external_file() -> ScriptKind {
  ScriptKind(5)
}

///|
pub fn ScriptKind::json() -> ScriptKind {
  ScriptKind(6)
}

///|
pub fn ScriptKind::deferred() -> ScriptKind {
  ScriptKind(7)
}

///|
pub fn ScriptKind::runtime_name(self : ScriptKind) -> String {
  match self.to_int() {
    0 => "Unknown"
    1 => "JS"
    2 => "JSX"
    3 => "TS"
    4 => "TSX"
    5 => "External"
    6 => "JSON"
    7 => "Deferred"
    _ => abort("invalid ScriptKind")
  }
}

///|
/// Returns TypeScript's raw file-name inference result. Unknown extensions map
/// to `Unknown`; `infer_or_ts` applies the parser's TS fallback.
pub fn ScriptKind::from_file_name(file_name : String) -> ScriptKind {
  let lower = file_name.to_lower()
  if lower.has_suffix(".js") ||
    lower.has_suffix(".cjs") ||
    lower.has_suffix(".mjs") {
    ScriptKind::js()
  } else if lower.has_suffix(".jsx") {
    ScriptKind::jsx()
  } else if lower.has_suffix(".ts") ||
    lower.has_suffix(".cts") ||
    lower.has_suffix(".mts") {
    ScriptKind::ts()
  } else if lower.has_suffix(".tsx") {
    ScriptKind::tsx()
  } else if lower.has_suffix(".json") {
    ScriptKind::json()
  } else {
    ScriptKind::unknown()
  }
}

///|
pub fn ScriptKind::infer_or_ts(file_name : String) -> ScriptKind {
  let inferred = ScriptKind::from_file_name(file_name)
  if inferred == ScriptKind::unknown() {
    ScriptKind::ts()
  } else {
    inferred
  }
}

///|
pub struct LanguageVariant(Int) derive(Eq, Compare, Debug)

///|
pub fn LanguageVariant::standard() -> LanguageVariant {
  LanguageVariant(0)
}

///|
pub fn LanguageVariant::jsx() -> LanguageVariant {
  LanguageVariant(1)
}

///|
pub fn LanguageVariant::to_int(self : LanguageVariant) -> Int {
  let LanguageVariant(value) = self
  value
}

///|
pub fn LanguageVariant::from_script_kind(kind : ScriptKind) -> LanguageVariant {
  if kind == ScriptKind::js() ||
    kind == ScriptKind::jsx() ||
    kind == ScriptKind::tsx() ||
    kind == ScriptKind::json() {
    LanguageVariant::jsx()
  } else {
    LanguageVariant::standard()
  }
}

///|
pub struct JSDocParsingMode(Int) derive(Eq, Compare, Debug)

///|
pub fn JSDocParsingMode::parse_all() -> JSDocParsingMode {
  JSDocParsingMode(0)
}

///|
pub fn JSDocParsingMode::parse_none() -> JSDocParsingMode {
  JSDocParsingMode(1)
}

///|
pub fn JSDocParsingMode::parse_for_type_errors() -> JSDocParsingMode {
  JSDocParsingMode(2)
}

///|
pub fn JSDocParsingMode::parse_for_type_info() -> JSDocParsingMode {
  JSDocParsingMode(3)
}

///|
pub fn JSDocParsingMode::to_int(self : JSDocParsingMode) -> Int {
  let JSDocParsingMode(value) = self
  value
}

///|
/// The two non-undefined `ResolutionMode` values are the corresponding
/// TypeScript `ModuleKind` numbers.
pub struct ResolutionMode(Int) derive(Eq, Compare, Debug)

///|
pub fn ResolutionMode::common_js() -> ResolutionMode {
  ResolutionMode(1)
}

///|
pub fn ResolutionMode::es_next() -> ResolutionMode {
  ResolutionMode(99)
}

///|
pub fn ResolutionMode::from_int(value : Int) -> ResolutionMode? {
  match value {
    1 | 99 => Some(ResolutionMode(value))
    _ => None
  }
}

///|
pub fn ResolutionMode::to_int(self : ResolutionMode) -> Int {
  let ResolutionMode(value) = self
  value
}

///|
pub struct DiagnosticCategory(Int) derive(Eq, Compare, Debug)

///|
pub fn DiagnosticCategory::warning() -> DiagnosticCategory {
  DiagnosticCategory(0)
}

///|
pub fn DiagnosticCategory::error() -> DiagnosticCategory {
  DiagnosticCategory(1)
}

///|
pub fn DiagnosticCategory::suggestion() -> DiagnosticCategory {
  DiagnosticCategory(2)
}

///|
pub fn DiagnosticCategory::message() -> DiagnosticCategory {
  DiagnosticCategory(3)
}

///|
pub fn DiagnosticCategory::to_int(self : DiagnosticCategory) -> Int {
  let DiagnosticCategory(value) = self
  value
}

///|
pub enum CommentDirectiveType {
  ExpectError
  Ignore
} derive(Eq, Debug)

///|
pub fn CommentDirectiveType::from_int(value : Int) -> CommentDirectiveType? {
  match value {
    0 => Some(ExpectError)
    1 => Some(Ignore)
    _ => None
  }
}

///|
pub fn CommentDirectiveType::to_int(self : CommentDirectiveType) -> Int {
  match self {
    ExpectError => 0
    Ignore => 1
  }
}

///|
pub enum Extension {
  Ts
  Tsx
  Dts
  Js
  Jsx
  Json
  TsBuildInfo
  Mjs
  Mts
  Dmts
  Cjs
  Cts
  Dcts
} derive(Eq, Debug)

///|
pub fn Extension::all() -> ReadOnlyArray[Extension] {
  ReadOnlyArray::from_array([
    Ts,
    Tsx,
    Dts,
    Js,
    Jsx,
    Json,
    TsBuildInfo,
    Mjs,
    Mts,
    Dmts,
    Cjs,
    Cts,
    Dcts,
  ])
}

///|
pub fn Extension::text(self : Extension) -> String {
  match self {
    Ts => ".ts"
    Tsx => ".tsx"
    Dts => ".d.ts"
    Js => ".js"
    Jsx => ".jsx"
    Json => ".json"
    TsBuildInfo => ".tsbuildinfo"
    Mjs => ".mjs"
    Mts => ".mts"
    Dmts => ".d.mts"
    Cjs => ".cjs"
    Cts => ".cts"
    Dcts => ".d.cts"
  }
}

///|
fn _base_file_name(file_name : String) -> StringView {
  let after_slash = match file_name.rev_split_once("/") {
    Some((_directory, base)) => base
    None => file_name.view()
  }
  match after_slash.rev_split_once("\\") {
    Some((_directory, base)) => base
    None => after_slash
  }
}

///|
/// Implements `.d.ts`/`.d.cts`/`.d.mts` recognition and TypeScript's
/// case-sensitive `.d.*.ts` fallback.
pub fn is_declaration_file_name(file_name : String) -> Bool {
  if file_name.has_suffix(".d.ts") ||
    file_name.has_suffix(".d.cts") ||
    file_name.has_suffix(".d.mts") {
    return true
  }
  if !file_name.has_suffix(".ts") {
    return false
  }
  _base_file_name(file_name).contains(".d.")
}
