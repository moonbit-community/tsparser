// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts, src/compiler/utilities.ts,
// src/compiler/program.ts, and src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// One untranslated entry from TypeScript's English diagnostic catalog.
pub struct DiagnosticMessage {
  upstream_symbol : String
  key : String
  category : DiagnosticCategory
  code : Int
  message : String
  placeholder_count : Int
  reports_unnecessary : Bool?
  reports_deprecated : Bool?
}

///|
fn _make_diagnostic_message(
  upstream_symbol : String,
  key : String,
  category : DiagnosticCategory,
  code : Int,
  message : String,
  placeholder_count : Int,
  reports_unnecessary? : Bool,
  reports_deprecated? : Bool,
) -> DiagnosticMessage {
  {
    upstream_symbol,
    key,
    category,
    code,
    message,
    placeholder_count,
    reports_unnecessary,
    reports_deprecated,
  }
}

///|
pub fn DiagnosticMessage::upstream_symbol(self : DiagnosticMessage) -> String {
  self.upstream_symbol
}

///|
pub fn DiagnosticMessage::key(self : DiagnosticMessage) -> String {
  self.key
}

///|
pub fn DiagnosticMessage::category(
  self : DiagnosticMessage,
) -> DiagnosticCategory {
  self.category
}

///|
pub fn DiagnosticMessage::code(self : DiagnosticMessage) -> Int {
  self.code
}

///|
pub fn DiagnosticMessage::message(self : DiagnosticMessage) -> String {
  self.message
}

///|
pub fn DiagnosticMessage::placeholder_count(self : DiagnosticMessage) -> Int {
  self.placeholder_count
}

///|
pub fn DiagnosticMessage::reports_unnecessary(
  self : DiagnosticMessage,
) -> Bool? {
  self.reports_unnecessary
}

///|
pub fn DiagnosticMessage::reports_deprecated(self : DiagnosticMessage) -> Bool? {
  self.reports_deprecated
}

///|
/// A parser diagnostic argument. TypeScript accepts only strings and numbers.
pub enum DiagnosticArgument {
  DiagnosticString(String)
  DiagnosticNumber(Int)
}

///|
pub fn DiagnosticArgument::text(value : String) -> DiagnosticArgument {
  DiagnosticString(value)
}

///|
pub fn DiagnosticArgument::number(value : Int) -> DiagnosticArgument {
  DiagnosticNumber(value)
}

///|
fn DiagnosticArgument::_to_string(self : DiagnosticArgument) -> String {
  match self {
    DiagnosticString(value) => value
    DiagnosticNumber(value) => value.to_string()
  }
}

///|
/// A preformatted multiline diagnostic message. `next=None` is distinct from
/// a present empty child list, matching TypeScript's message-chain shape.
pub struct DiagnosticMessageChain {
  message_text : String
  category : DiagnosticCategory
  code : Int
  next : ReadOnlyArray[DiagnosticMessageChain]?
}

///|
pub fn DiagnosticMessageChain::message_text(
  self : DiagnosticMessageChain,
) -> String {
  self.message_text
}

///|
pub fn DiagnosticMessageChain::category(
  self : DiagnosticMessageChain,
) -> DiagnosticCategory {
  self.category
}

///|
pub fn DiagnosticMessageChain::code(self : DiagnosticMessageChain) -> Int {
  self.code
}

///|
pub fn DiagnosticMessageChain::next(
  self : DiagnosticMessageChain,
) -> ReadOnlyArray[DiagnosticMessageChain]? {
  self.next
}

///|
/// The exact `string | DiagnosticMessageChain` union used by diagnostics.
pub enum DiagnosticMessageText {
  DiagnosticTextValue(String)
  DiagnosticChainValue(DiagnosticMessageChain)
}

///|
/// A diagnostic can have no location, a detached filename/range, or an
/// attached SourceFile/range. Detached diagnostics deliberately retain only
/// the filename, as in TypeScript; source text is used only during creation.
pub enum DiagnosticLocation {
  NoDiagnosticLocation
  DetachedDiagnosticLocation(String)
  AttachedDiagnosticLocation(Node)
}

///|
/// Immutable public diagnostic data. Related-information ordering and
/// attached/detached location states are preserved without exposing a mutable
/// array handle.
pub struct Diagnostic {
  location : DiagnosticLocation
  start : Int?
  length : Int?
  message_text : DiagnosticMessageText
  category : DiagnosticCategory
  code : Int
  reports_unnecessary : Bool?
  reports_deprecated : Bool?
  related_information : ReadOnlyArray[Diagnostic]?
}

///|
fn _make_diagnostic(
  location : DiagnosticLocation,
  start : Int?,
  length : Int?,
  message_text : DiagnosticMessageText,
  category : DiagnosticCategory,
  code : Int,
  reports_unnecessary : Bool?,
  reports_deprecated : Bool?,
  related_information : ReadOnlyArray[Diagnostic]?,
) -> Diagnostic {
  {
    location,
    start,
    length,
    message_text,
    category,
    code,
    reports_unnecessary,
    reports_deprecated,
    related_information,
  }
}

///|
pub fn Diagnostic::file(self : Diagnostic) -> Node? {
  match self.location {
    AttachedDiagnosticLocation(file) => Some(file)
    NoDiagnosticLocation | DetachedDiagnosticLocation(_) => None
  }
}

///|
fn _source_file_name(source_file : Node) -> String {
  guard source_file.kind().to_int() == 308 else {
    abort("expected a SourceFile node")
  }
  match source_file.field("fileName") {
    Some(Text(Some(file_name))) => file_name
    _ => ""
  }
}

///|
pub fn Diagnostic::file_name(self : Diagnostic) -> String? {
  match self.location {
    DetachedDiagnosticLocation(file_name) => Some(file_name)
    AttachedDiagnosticLocation(file) => Some(_source_file_name(file))
    NoDiagnosticLocation => None
  }
}

///|
pub fn Diagnostic::is_detached(self : Diagnostic) -> Bool {
  self.location is DetachedDiagnosticLocation(_)
}

///|
pub fn Diagnostic::is_attached(self : Diagnostic) -> Bool {
  self.location is AttachedDiagnosticLocation(_)
}

///|
pub fn Diagnostic::start(self : Diagnostic) -> Int? {
  self.start
}

///|
pub fn Diagnostic::length(self : Diagnostic) -> Int? {
  self.length
}

///|
pub fn Diagnostic::message_text(self : Diagnostic) -> DiagnosticMessageText {
  self.message_text
}

///|
pub fn Diagnostic::category(self : Diagnostic) -> DiagnosticCategory {
  self.category
}

///|
pub fn Diagnostic::code(self : Diagnostic) -> Int {
  self.code
}

///|
pub fn Diagnostic::reports_unnecessary(self : Diagnostic) -> Bool? {
  self.reports_unnecessary
}

///|
pub fn Diagnostic::reports_deprecated(self : Diagnostic) -> Bool? {
  self.reports_deprecated
}

///|
pub fn Diagnostic::related_information(
  self : Diagnostic,
) -> ReadOnlyArray[Diagnostic]? {
  self.related_information
}

///|
/// Replaces every `{n}` placeholder using TypeScript's decimal-index rule.
/// A referenced argument must be present; numbers use their decimal spelling.
pub fn format_string_from_diagnostic_arguments(
  text : String,
  arguments : ReadOnlyArray[DiagnosticArgument],
) -> String {
  let output = StringBuilder::new()
  let mut copy_start = 0
  let mut position = 0
  while position < text.length() {
    if text[position].to_int() == CharacterCodes::open_brace() {
      let mut cursor = position + 1
      let mut index = 0
      let mut has_digit = false
      while cursor < text.length() {
        let code_unit = text[cursor].to_int()
        if code_unit >= CharacterCodes::digit_0() &&
          code_unit <= CharacterCodes::digit_9() {
          has_digit = true
          index = index * 10 + code_unit - CharacterCodes::digit_0()
          cursor += 1
        } else {
          break
        }
      }
      if has_digit &&
        cursor < text.length() &&
        text[cursor].to_int() == CharacterCodes::close_brace() {
        output.write_string(
          text.unsafe_substring(start=copy_start, end=position),
        )
        match arguments.get(index) {
          Some(argument) => output.write_string(argument._to_string())
          None => abort("diagnostic placeholder argument is missing")
        }
        position = cursor + 1
        copy_start = position
        continue
      }
    }
    position += 1
  }
  output.write_string(
    text.unsafe_substring(start=copy_start, end=text.length()),
  )
  output.to_string()
}

///|
fn _format_diagnostic_message(
  message : DiagnosticMessage,
  arguments : ReadOnlyArray[DiagnosticArgument],
) -> String {
  if arguments.is_empty() {
    message.message()
  } else {
    format_string_from_diagnostic_arguments(message.message(), arguments)
  }
}

///|
fn _flatten_diagnostic_chain_into(
  output : StringBuilder,
  chain : DiagnosticMessageChain,
  new_line : String,
  indent : Int,
) -> Unit {
  if indent > 0 {
    output.write_string(new_line)
    output.write_string("  ".repeat(indent))
  }
  output.write_string(chain.message_text())
  match chain.next() {
    Some(children) =>
      for child in children {
        _flatten_diagnostic_chain_into(output, child, new_line, indent + 1)
      }
    None => ()
  }
}

///|
/// Flattens message text with TypeScript's two-space indentation per chain
/// level. Plain string messages ignore the optional indent, as upstream does.
pub fn DiagnosticMessageText::flatten(
  self : DiagnosticMessageText,
  new_line : String,
  indent? : Int = 0,
) -> String {
  match self {
    DiagnosticTextValue(text) => text
    DiagnosticChainValue(chain) => {
      let output = StringBuilder::new()
      _flatten_diagnostic_chain_into(output, chain, new_line, indent)
      output.to_string()
    }
  }
}

///|
fn _chain_diagnostic_messages(
  details : ReadOnlyArray[DiagnosticMessageChain]?,
  message : DiagnosticMessage,
  arguments : ReadOnlyArray[DiagnosticArgument],
) -> DiagnosticMessageChain {
  {
    message_text: _format_diagnostic_message(message, arguments),
    category: message.category(),
    code: message.code(),
    next: details,
  }
}

///|
fn _assert_diagnostic_location(
  source_text : SourceText,
  start : Int,
  length : Int,
) -> Unit {
  guard start >= 0 && length >= 0 && start <= source_text.length() else {
    abort("invalid diagnostic location")
  }
  guard start + length <= source_text.length() else {
    abort("diagnostic extends beyond source text")
  }
}

///|
fn _create_detached_diagnostic(
  file_name : String,
  source_text : String,
  start : Int,
  length : Int,
  message : DiagnosticMessage,
  arguments : ReadOnlyArray[DiagnosticArgument],
) -> Diagnostic {
  let source = SourceText::new(source_text)
  let actual_length = if start + length > source.length() {
    source.length() - start
  } else {
    length
  }
  _assert_diagnostic_location(source, start, actual_length)
  _make_diagnostic(
    DetachedDiagnosticLocation(file_name),
    Some(start),
    Some(actual_length),
    DiagnosticTextValue(_format_diagnostic_message(message, arguments)),
    message.category(),
    message.code(),
    message.reports_unnecessary(),
    None,
    None,
  )
}

///|
fn _create_file_diagnostic(
  file : Node,
  start : Int,
  length : Int,
  message : DiagnosticMessage,
  arguments : ReadOnlyArray[DiagnosticArgument],
) -> Diagnostic {
  _assert_diagnostic_location(_source_file_text(file), start, length)
  _make_diagnostic(
    AttachedDiagnosticLocation(file),
    Some(start),
    Some(length),
    DiagnosticTextValue(_format_diagnostic_message(message, arguments)),
    message.category(),
    message.code(),
    message.reports_unnecessary(),
    message.reports_deprecated(),
    None,
  )
}

///|
fn _create_compiler_diagnostic(
  message : DiagnosticMessage,
  arguments : ReadOnlyArray[DiagnosticArgument],
) -> Diagnostic {
  _make_diagnostic(
    NoDiagnosticLocation,
    None,
    None,
    DiagnosticTextValue(_format_diagnostic_message(message, arguments)),
    message.category(),
    message.code(),
    message.reports_unnecessary(),
    message.reports_deprecated(),
    None,
  )
}

///|
fn _create_compiler_diagnostic_from_chain(
  chain : DiagnosticMessageChain,
  related_information? : ReadOnlyArray[Diagnostic],
) -> Diagnostic {
  let message_text = match chain.next() {
    Some(_) => DiagnosticChainValue(chain)
    None => DiagnosticTextValue(chain.message_text())
  }
  _make_diagnostic(
    NoDiagnosticLocation,
    None,
    None,
    message_text,
    chain.category(),
    chain.code(),
    None,
    None,
    related_information,
  )
}

///|
fn _copy_diagnostic_with(
  diagnostic : Diagnostic,
  location : DiagnosticLocation,
  related_information : ReadOnlyArray[Diagnostic]?,
) -> Diagnostic {
  _make_diagnostic(
    location,
    diagnostic.start(),
    diagnostic.length(),
    diagnostic.message_text(),
    diagnostic.category(),
    diagnostic.code(),
    diagnostic.reports_unnecessary(),
    diagnostic.reports_deprecated(),
    related_information,
  )
}

///|
fn _attach_file_to_diagnostic(
  diagnostic : Diagnostic,
  file : Node,
) -> Diagnostic {
  let detached_file_name = match diagnostic.location {
    DetachedDiagnosticLocation(file_name) => file_name
    NoDiagnosticLocation | AttachedDiagnosticLocation(_) =>
      abort("diagnostic is not detached")
  }
  guard detached_file_name == _source_file_name(file) else {
    abort("detached diagnostic filename does not match SourceFile")
  }
  let start = match diagnostic.start() {
    Some(start) => start
    None => abort("detached diagnostic has no start")
  }
  let length = match diagnostic.length() {
    Some(length) => length
    None => abort("detached diagnostic has no length")
  }
  _assert_diagnostic_location(_source_file_text(file), start, length)
  let attached_related = match diagnostic.related_information() {
    Some(related) => {
      let result : Array[Diagnostic] = []
      for item in related {
        match item.location {
          DetachedDiagnosticLocation(file_name) if file_name ==
            detached_file_name =>
            result.push(_attach_file_to_diagnostic(item, file))
          _ => result.push(item)
        }
      }
      Some(ReadOnlyArray::from_array(result))
    }
    None => None
  }
  _copy_diagnostic_with(
    diagnostic,
    AttachedDiagnosticLocation(file),
    attached_related,
  )
}

///|
fn _add_related_information(
  diagnostic : Diagnostic,
  related_information : ReadOnlyArray[Diagnostic],
) -> Diagnostic {
  if related_information.is_empty() {
    return diagnostic
  }
  let combined : Array[Diagnostic] = []
  match diagnostic.related_information() {
    Some(existing) =>
      for item in existing {
        combined.push(item)
      }
    None => ()
  }
  for item in related_information {
    combined.push(item)
  }
  _copy_diagnostic_with(
    diagnostic,
    diagnostic.location,
    Some(ReadOnlyArray::from_array(combined)),
  )
}

///|
fn _parse_error_at_position(
  finish_state : NodeFinishState,
  diagnostics : Array[Diagnostic],
  file_name : String,
  source_text : String,
  start : Int,
  length : Int,
  message : DiagnosticMessage,
  arguments : ReadOnlyArray[DiagnosticArgument],
) -> Diagnostic? {
  let mut duplicate = false
  if diagnostics.length() > 0 {
    duplicate = diagnostics[diagnostics.length() - 1].start() == Some(start)
  }
  let result = if duplicate {
    None
  } else {
    let diagnostic = _create_detached_diagnostic(
      file_name, source_text, start, length, message, arguments,
    )
    diagnostics.push(diagnostic)
    Some(diagnostic)
  }
  finish_state._mark_parse_error()
  result
}

///|
fn _no_diagnostic_arguments() -> ReadOnlyArray[DiagnosticArgument] {
  ReadOnlyArray::from_array([])
}
