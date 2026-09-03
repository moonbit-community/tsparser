///|
test "parser and scanner internal state enums match upstream" {
  let signature_values = [
    ParserSignatureFlags::none().bits(),
    ParserSignatureFlags::yield_flag().bits(),
    ParserSignatureFlags::await_flag().bits(),
    ParserSignatureFlags::type_flag().bits(),
    ParserSignatureFlags::ignore_missing_open_brace().bits(),
    ParserSignatureFlags::jsdoc().bits(),
  ]
  let expected_signature_values = [0U, 1U, 2U, 4U, 16U, 32U]
  for index in 0..<expected_signature_values.length() {
    assert_eq(signature_values[index], expected_signature_values[index])
  }
  assert_eq(SpeculationKind::TryParse.to_int(), 0)
  assert_eq(SpeculationKind::Lookahead.to_int(), 1)
  assert_eq(SpeculationKind::Reparse.to_int(), 2)
  let escape_values = [
    EscapeSequenceScanningFlags::string_flag().bits(),
    EscapeSequenceScanningFlags::report_errors().bits(),
    EscapeSequenceScanningFlags::regular_expression().bits(),
    EscapeSequenceScanningFlags::annex_b().bits(),
    EscapeSequenceScanningFlags::any_unicode_mode().bits(),
    EscapeSequenceScanningFlags::atom_escape().bits(),
    EscapeSequenceScanningFlags::report_invalid_escape_errors().bits(),
    EscapeSequenceScanningFlags::allow_extended_unicode_escape().bits(),
  ]
  let expected_escape_values = [1U, 2U, 4U, 8U, 16U, 32U, 6U, 17U]
  for index in 0..<expected_escape_values.length() {
    assert_eq(escape_values[index], expected_escape_values[index])
  }
  assert_eq(ClassSetExpressionType::Unknown.to_int(), 0)
  assert_eq(ClassSetExpressionType::ClassUnion.to_int(), 1)
  assert_eq(ClassSetExpressionType::ClassIntersection.to_int(), 2)
  assert_eq(ClassSetExpressionType::ClassSubtraction.to_int(), 3)
}

///|
test "all 26 ParsingContext bit positions are exact" {
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
  assert_eq(contexts.length(), ParsingContext::count())
  for index in 0..<contexts.length() {
    assert_eq(contexts[index].to_int(), index)
    assert_eq(contexts[index].bit(), 1U << index)
  }
}

///|
test "JSDoc and recovery state values are exact" {
  assert_eq(Tristate::False.to_int(), 0)
  assert_eq(Tristate::True.to_int(), 1)
  assert_eq(Tristate::Unknown.to_int(), 2)
  assert_eq(JSDocState::BeginningOfLine.to_int(), 0)
  assert_eq(JSDocState::SawAsterisk.to_int(), 1)
  assert_eq(JSDocState::SavingComments.to_int(), 2)
  assert_eq(JSDocState::SavingBackticks.to_int(), 3)
  assert_eq(PropertyLikeParse::property().bits(), 1U)
  assert_eq(PropertyLikeParse::parameter().bits(), 2U)
  assert_eq(PropertyLikeParse::callback_parameter().bits(), 4U)
  assert_eq(_invalid_position(), -1)
}
