// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts and src/compiler/scanner.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
priv struct ParserSignatureFlags(UInt)

///|
fn ParserSignatureFlags::none() -> ParserSignatureFlags {
  ParserSignatureFlags(0U)
}

///|
fn ParserSignatureFlags::yield_flag() -> ParserSignatureFlags {
  ParserSignatureFlags(1U)
}

///|
fn ParserSignatureFlags::await_flag() -> ParserSignatureFlags {
  ParserSignatureFlags(2U)
}

///|
fn ParserSignatureFlags::type_flag() -> ParserSignatureFlags {
  ParserSignatureFlags(4U)
}

///|
fn ParserSignatureFlags::ignore_missing_open_brace() -> ParserSignatureFlags {
  ParserSignatureFlags(16U)
}

///|
fn ParserSignatureFlags::jsdoc() -> ParserSignatureFlags {
  ParserSignatureFlags(32U)
}

///|
fn ParserSignatureFlags::bits(self : ParserSignatureFlags) -> UInt {
  let ParserSignatureFlags(bits) = self
  bits
}

///|
fn ParserSignatureFlags::union(
  self : ParserSignatureFlags,
  other : ParserSignatureFlags,
) -> ParserSignatureFlags {
  ParserSignatureFlags(self.bits() | other.bits())
}

///|
priv enum SpeculationKind {
  TryParse
  Lookahead
  Reparse
}

///|
fn SpeculationKind::to_int(self : SpeculationKind) -> Int {
  match self {
    TryParse => 0
    Lookahead => 1
    Reparse => 2
  }
}

///|
priv struct EscapeSequenceScanningFlags(UInt)

///|
fn EscapeSequenceScanningFlags::string_flag() -> EscapeSequenceScanningFlags {
  EscapeSequenceScanningFlags(1U)
}

///|
fn EscapeSequenceScanningFlags::report_errors() -> EscapeSequenceScanningFlags {
  EscapeSequenceScanningFlags(2U)
}

///|
fn EscapeSequenceScanningFlags::regular_expression() -> EscapeSequenceScanningFlags {
  EscapeSequenceScanningFlags(4U)
}

///|
fn EscapeSequenceScanningFlags::annex_b() -> EscapeSequenceScanningFlags {
  EscapeSequenceScanningFlags(8U)
}

///|
fn EscapeSequenceScanningFlags::any_unicode_mode() -> EscapeSequenceScanningFlags {
  EscapeSequenceScanningFlags(16U)
}

///|
fn EscapeSequenceScanningFlags::atom_escape() -> EscapeSequenceScanningFlags {
  EscapeSequenceScanningFlags(32U)
}

///|
fn EscapeSequenceScanningFlags::report_invalid_escape_errors() -> EscapeSequenceScanningFlags {
  EscapeSequenceScanningFlags(6U)
}

///|
fn EscapeSequenceScanningFlags::allow_extended_unicode_escape() -> EscapeSequenceScanningFlags {
  EscapeSequenceScanningFlags(17U)
}

///|
fn EscapeSequenceScanningFlags::bits(
  self : EscapeSequenceScanningFlags,
) -> UInt {
  let EscapeSequenceScanningFlags(bits) = self
  bits
}

///|
priv enum ClassSetExpressionType {
  Unknown
  ClassUnion
  ClassIntersection
  ClassSubtraction
}

///|
fn ClassSetExpressionType::to_int(self : ClassSetExpressionType) -> Int {
  match self {
    Unknown => 0
    ClassUnion => 1
    ClassIntersection => 2
    ClassSubtraction => 3
  }
}

///|
/// Exact indices used as bit positions by the parser list-recovery machinery.
priv struct ParsingContext(Int)

///|
fn ParsingContext::source_elements() -> ParsingContext {
  ParsingContext(0)
}

///|
fn ParsingContext::block_statements() -> ParsingContext {
  ParsingContext(1)
}

///|
fn ParsingContext::switch_clauses() -> ParsingContext {
  ParsingContext(2)
}

///|
fn ParsingContext::switch_clause_statements() -> ParsingContext {
  ParsingContext(3)
}

///|
fn ParsingContext::type_members() -> ParsingContext {
  ParsingContext(4)
}

///|
fn ParsingContext::class_members() -> ParsingContext {
  ParsingContext(5)
}

///|
fn ParsingContext::enum_members() -> ParsingContext {
  ParsingContext(6)
}

///|
fn ParsingContext::heritage_clause_element() -> ParsingContext {
  ParsingContext(7)
}

///|
fn ParsingContext::variable_declarations() -> ParsingContext {
  ParsingContext(8)
}

///|
fn ParsingContext::object_binding_elements() -> ParsingContext {
  ParsingContext(9)
}

///|
fn ParsingContext::array_binding_elements() -> ParsingContext {
  ParsingContext(10)
}

///|
fn ParsingContext::argument_expressions() -> ParsingContext {
  ParsingContext(11)
}

///|
fn ParsingContext::object_literal_members() -> ParsingContext {
  ParsingContext(12)
}

///|
fn ParsingContext::jsx_attributes() -> ParsingContext {
  ParsingContext(13)
}

///|
fn ParsingContext::jsx_children() -> ParsingContext {
  ParsingContext(14)
}

///|
fn ParsingContext::array_literal_members() -> ParsingContext {
  ParsingContext(15)
}

///|
fn ParsingContext::parameters() -> ParsingContext {
  ParsingContext(16)
}

///|
fn ParsingContext::jsdoc_parameters() -> ParsingContext {
  ParsingContext(17)
}

///|
fn ParsingContext::rest_properties() -> ParsingContext {
  ParsingContext(18)
}

///|
fn ParsingContext::type_parameters() -> ParsingContext {
  ParsingContext(19)
}

///|
fn ParsingContext::type_arguments() -> ParsingContext {
  ParsingContext(20)
}

///|
fn ParsingContext::tuple_element_types() -> ParsingContext {
  ParsingContext(21)
}

///|
fn ParsingContext::heritage_clauses() -> ParsingContext {
  ParsingContext(22)
}

///|
fn ParsingContext::import_or_export_specifiers() -> ParsingContext {
  ParsingContext(23)
}

///|
fn ParsingContext::import_attributes() -> ParsingContext {
  ParsingContext(24)
}

///|
fn ParsingContext::jsdoc_comment() -> ParsingContext {
  ParsingContext(25)
}

///|
fn ParsingContext::count() -> Int {
  26
}

///|
fn ParsingContext::to_int(self : ParsingContext) -> Int {
  let ParsingContext(value) = self
  value
}

///|
fn ParsingContext::bit(self : ParsingContext) -> UInt {
  1U << self.to_int()
}

///|
priv enum Tristate {
  False
  True
  Unknown
}

///|
fn Tristate::to_int(self : Tristate) -> Int {
  match self {
    False => 0
    True => 1
    Unknown => 2
  }
}

///|
priv enum JSDocState {
  BeginningOfLine
  SawAsterisk
  SavingComments
  SavingBackticks
}

///|
fn JSDocState::to_int(self : JSDocState) -> Int {
  match self {
    BeginningOfLine => 0
    SawAsterisk => 1
    SavingComments => 2
    SavingBackticks => 3
  }
}

///|
priv struct PropertyLikeParse(UInt)

///|
fn PropertyLikeParse::property() -> PropertyLikeParse {
  PropertyLikeParse(1U)
}

///|
fn PropertyLikeParse::parameter() -> PropertyLikeParse {
  PropertyLikeParse(2U)
}

///|
fn PropertyLikeParse::callback_parameter() -> PropertyLikeParse {
  PropertyLikeParse(4U)
}

///|
fn PropertyLikeParse::bits(self : PropertyLikeParse) -> UInt {
  let PropertyLikeParse(bits) = self
  bits
}

///|
fn _invalid_position() -> Int {
  -1
}

///|
/// Staging hook for the complete private const-enum contract. It disappears
/// once parser/scanner paths naturally consume every member.
#warnings("-unused_value")
fn _internal_state_contract_values() -> Unit {
  ignore(ParserSignatureFlags::none().bits())
  ignore(ParserSignatureFlags::yield_flag().bits())
  ignore(ParserSignatureFlags::await_flag().bits())
  ignore(ParserSignatureFlags::type_flag().bits())
  ignore(ParserSignatureFlags::ignore_missing_open_brace().bits())
  ignore(ParserSignatureFlags::jsdoc().bits())
  ignore(SpeculationKind::TryParse.to_int())
  ignore(SpeculationKind::Lookahead.to_int())
  ignore(SpeculationKind::Reparse.to_int())
  ignore(EscapeSequenceScanningFlags::string_flag().bits())
  ignore(EscapeSequenceScanningFlags::report_errors().bits())
  ignore(EscapeSequenceScanningFlags::regular_expression().bits())
  ignore(EscapeSequenceScanningFlags::annex_b().bits())
  ignore(EscapeSequenceScanningFlags::any_unicode_mode().bits())
  ignore(EscapeSequenceScanningFlags::atom_escape().bits())
  ignore(EscapeSequenceScanningFlags::report_invalid_escape_errors().bits())
  ignore(EscapeSequenceScanningFlags::allow_extended_unicode_escape().bits())
  ignore(ClassSetExpressionType::Unknown.to_int())
  ignore(ClassSetExpressionType::ClassUnion.to_int())
  ignore(ClassSetExpressionType::ClassIntersection.to_int())
  ignore(ClassSetExpressionType::ClassSubtraction.to_int())
  let contexts = [
    ParsingContext::source_elements(),
    ParsingContext::block_statements(),
    ParsingContext::switch_clauses(),
    ParsingContext::switch_clause_statements(),
    ParsingContext::type_members(),
    ParsingContext::class_members(),
    ParsingContext::enum_members(),
    ParsingContext::heritage_clause_element(),
    ParsingContext::variable_declarations(),
    ParsingContext::object_binding_elements(),
    ParsingContext::array_binding_elements(),
    ParsingContext::argument_expressions(),
    ParsingContext::object_literal_members(),
    ParsingContext::jsx_attributes(),
    ParsingContext::jsx_children(),
    ParsingContext::array_literal_members(),
    ParsingContext::parameters(),
    ParsingContext::jsdoc_parameters(),
    ParsingContext::rest_properties(),
    ParsingContext::type_parameters(),
    ParsingContext::type_arguments(),
    ParsingContext::tuple_element_types(),
    ParsingContext::heritage_clauses(),
    ParsingContext::import_or_export_specifiers(),
    ParsingContext::import_attributes(),
    ParsingContext::jsdoc_comment(),
  ]
  for context in contexts {
    ignore(context.to_int())
    ignore(context.bit())
  }
  ignore(ParsingContext::count())
  ignore(Tristate::False.to_int())
  ignore(Tristate::True.to_int())
  ignore(Tristate::Unknown.to_int())
  ignore(JSDocState::BeginningOfLine.to_int())
  ignore(JSDocState::SawAsterisk.to_int())
  ignore(JSDocState::SavingComments.to_int())
  ignore(JSDocState::SavingBackticks.to_int())
  ignore(PropertyLikeParse::property().bits())
  ignore(PropertyLikeParse::parameter().bits())
  ignore(PropertyLikeParse::callback_parameter().bits())
  ignore(_invalid_position())
}
