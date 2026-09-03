// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/diagnosticMessages.json at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// The explicit 148-entry parser/scanner/JSON diagnostic catalog.
fn _diagnostic_message(code : Int) -> DiagnosticMessage {
  match code {
    1002 =>
      _make_diagnostic_message(
        "Diagnostics.Unterminated_string_literal",
        "Unterminated_string_literal_1002",
        DiagnosticCategory::error(),
        1002,
        "Unterminated string literal.",
        0,
      )
    1003 =>
      _make_diagnostic_message(
        "Diagnostics.Identifier_expected",
        "Identifier_expected_1003",
        DiagnosticCategory::error(),
        1003,
        "Identifier expected.",
        0,
      )
    1005 =>
      _make_diagnostic_message(
        "Diagnostics._0_expected",
        "_0_expected_1005",
        DiagnosticCategory::error(),
        1005,
        "'{0}' expected.",
        1,
      )
    1007 =>
      _make_diagnostic_message(
        "Diagnostics.The_parser_expected_to_find_a_1_to_match_the_0_token_here",
        "The_parser_expected_to_find_a_1_to_match_the_0_token_here_1007",
        DiagnosticCategory::error(),
        1007,
        "The parser expected to find a '{1}' to match the '{0}' token here.",
        2,
      )
    1010 =>
      _make_diagnostic_message(
        "Diagnostics.Asterisk_Slash_expected",
        "Asterisk_Slash_expected_1010",
        DiagnosticCategory::error(),
        1010,
        "'*/' expected.",
        0,
      )
    1011 =>
      _make_diagnostic_message(
        "Diagnostics.An_element_access_expression_should_take_an_argument",
        "An_element_access_expression_should_take_an_argument_1011",
        DiagnosticCategory::error(),
        1011,
        "An element access expression should take an argument.",
        0,
      )
    1012 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_token",
        "Unexpected_token_1012",
        DiagnosticCategory::error(),
        1012,
        "Unexpected token.",
        0,
      )
    1034 =>
      _make_diagnostic_message(
        "Diagnostics.super_must_be_followed_by_an_argument_list_or_member_access",
        "super_must_be_followed_by_an_argument_list_or_member_access_1034",
        DiagnosticCategory::error(),
        1034,
        "'super' must be followed by an argument list or member access.",
        0,
      )
    1068 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_token_A_constructor_method_accessor_or_property_was_expected",
        "Unexpected_token_A_constructor_method_accessor_or_property_was_expected_1068",
        DiagnosticCategory::error(),
        1068,
        "Unexpected token. A constructor, method, accessor, or property was expected.",
        0,
      )
    1069 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_token_A_type_parameter_name_was_expected_without_curly_braces",
        "Unexpected_token_A_type_parameter_name_was_expected_without_curly_braces_1069",
        DiagnosticCategory::error(),
        1069,
        "Unexpected token. A type parameter name was expected without curly braces.",
        0,
      )
    1084 =>
      _make_diagnostic_message(
        "Diagnostics.Invalid_reference_directive_syntax",
        "Invalid_reference_directive_syntax_1084",
        DiagnosticCategory::error(),
        1084,
        "Invalid 'reference' directive syntax.",
        0,
      )
    1109 =>
      _make_diagnostic_message(
        "Diagnostics.Expression_expected",
        "Expression_expected_1109",
        DiagnosticCategory::error(),
        1109,
        "Expression expected.",
        0,
      )
    1110 =>
      _make_diagnostic_message(
        "Diagnostics.Type_expected",
        "Type_expected_1110",
        DiagnosticCategory::error(),
        1110,
        "Type expected.",
        0,
      )
    1121 =>
      _make_diagnostic_message(
        "Diagnostics.Octal_literals_are_not_allowed_Use_the_syntax_0",
        "Octal_literals_are_not_allowed_Use_the_syntax_0_1121",
        DiagnosticCategory::error(),
        1121,
        "Octal literals are not allowed. Use the syntax '{0}'.",
        1,
      )
    1124 =>
      _make_diagnostic_message(
        "Diagnostics.Digit_expected",
        "Digit_expected_1124",
        DiagnosticCategory::error(),
        1124,
        "Digit expected.",
        0,
      )
    1125 =>
      _make_diagnostic_message(
        "Diagnostics.Hexadecimal_digit_expected",
        "Hexadecimal_digit_expected_1125",
        DiagnosticCategory::error(),
        1125,
        "Hexadecimal digit expected.",
        0,
      )
    1126 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_end_of_text",
        "Unexpected_end_of_text_1126",
        DiagnosticCategory::error(),
        1126,
        "Unexpected end of text.",
        0,
      )
    1127 =>
      _make_diagnostic_message(
        "Diagnostics.Invalid_character",
        "Invalid_character_1127",
        DiagnosticCategory::error(),
        1127,
        "Invalid character.",
        0,
      )
    1128 =>
      _make_diagnostic_message(
        "Diagnostics.Declaration_or_statement_expected",
        "Declaration_or_statement_expected_1128",
        DiagnosticCategory::error(),
        1128,
        "Declaration or statement expected.",
        0,
      )
    1129 =>
      _make_diagnostic_message(
        "Diagnostics.Statement_expected",
        "Statement_expected_1129",
        DiagnosticCategory::error(),
        1129,
        "Statement expected.",
        0,
      )
    1130 =>
      _make_diagnostic_message(
        "Diagnostics.case_or_default_expected",
        "case_or_default_expected_1130",
        DiagnosticCategory::error(),
        1130,
        "'case' or 'default' expected.",
        0,
      )
    1131 =>
      _make_diagnostic_message(
        "Diagnostics.Property_or_signature_expected",
        "Property_or_signature_expected_1131",
        DiagnosticCategory::error(),
        1131,
        "Property or signature expected.",
        0,
      )
    1132 =>
      _make_diagnostic_message(
        "Diagnostics.Enum_member_expected",
        "Enum_member_expected_1132",
        DiagnosticCategory::error(),
        1132,
        "Enum member expected.",
        0,
      )
    1134 =>
      _make_diagnostic_message(
        "Diagnostics.Variable_declaration_expected",
        "Variable_declaration_expected_1134",
        DiagnosticCategory::error(),
        1134,
        "Variable declaration expected.",
        0,
      )
    1135 =>
      _make_diagnostic_message(
        "Diagnostics.Argument_expression_expected",
        "Argument_expression_expected_1135",
        DiagnosticCategory::error(),
        1135,
        "Argument expression expected.",
        0,
      )
    1136 =>
      _make_diagnostic_message(
        "Diagnostics.Property_assignment_expected",
        "Property_assignment_expected_1136",
        DiagnosticCategory::error(),
        1136,
        "Property assignment expected.",
        0,
      )
    1137 =>
      _make_diagnostic_message(
        "Diagnostics.Expression_or_comma_expected",
        "Expression_or_comma_expected_1137",
        DiagnosticCategory::error(),
        1137,
        "Expression or comma expected.",
        0,
      )
    1138 =>
      _make_diagnostic_message(
        "Diagnostics.Parameter_declaration_expected",
        "Parameter_declaration_expected_1138",
        DiagnosticCategory::error(),
        1138,
        "Parameter declaration expected.",
        0,
      )
    1139 =>
      _make_diagnostic_message(
        "Diagnostics.Type_parameter_declaration_expected",
        "Type_parameter_declaration_expected_1139",
        DiagnosticCategory::error(),
        1139,
        "Type parameter declaration expected.",
        0,
      )
    1140 =>
      _make_diagnostic_message(
        "Diagnostics.Type_argument_expected",
        "Type_argument_expected_1140",
        DiagnosticCategory::error(),
        1140,
        "Type argument expected.",
        0,
      )
    1142 =>
      _make_diagnostic_message(
        "Diagnostics.Line_break_not_permitted_here",
        "Line_break_not_permitted_here_1142",
        DiagnosticCategory::error(),
        1142,
        "Line break not permitted here.",
        0,
      )
    1144 =>
      _make_diagnostic_message(
        "Diagnostics.or_expected",
        "or_expected_1144",
        DiagnosticCategory::error(),
        1144,
        "'{' or ';' expected.",
        0,
      )
    1145 =>
      _make_diagnostic_message(
        "Diagnostics.or_JSX_element_expected",
        "or_JSX_element_expected_1145",
        DiagnosticCategory::error(),
        1145,
        "'{' or JSX element expected.",
        0,
      )
    1146 =>
      _make_diagnostic_message(
        "Diagnostics.Declaration_expected",
        "Declaration_expected_1146",
        DiagnosticCategory::error(),
        1146,
        "Declaration expected.",
        0,
      )
    1160 =>
      _make_diagnostic_message(
        "Diagnostics.Unterminated_template_literal",
        "Unterminated_template_literal_1160",
        DiagnosticCategory::error(),
        1160,
        "Unterminated template literal.",
        0,
      )
    1161 =>
      _make_diagnostic_message(
        "Diagnostics.Unterminated_regular_expression_literal",
        "Unterminated_regular_expression_literal_1161",
        DiagnosticCategory::error(),
        1161,
        "Unterminated regular expression literal.",
        0,
      )
    1177 =>
      _make_diagnostic_message(
        "Diagnostics.Binary_digit_expected",
        "Binary_digit_expected_1177",
        DiagnosticCategory::error(),
        1177,
        "Binary digit expected.",
        0,
      )
    1178 =>
      _make_diagnostic_message(
        "Diagnostics.Octal_digit_expected",
        "Octal_digit_expected_1178",
        DiagnosticCategory::error(),
        1178,
        "Octal digit expected.",
        0,
      )
    1179 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_token_expected",
        "Unexpected_token_expected_1179",
        DiagnosticCategory::error(),
        1179,
        "Unexpected token. '{' expected.",
        0,
      )
    1180 =>
      _make_diagnostic_message(
        "Diagnostics.Property_destructuring_pattern_expected",
        "Property_destructuring_pattern_expected_1180",
        DiagnosticCategory::error(),
        1180,
        "Property destructuring pattern expected.",
        0,
      )
    1181 =>
      _make_diagnostic_message(
        "Diagnostics.Array_element_destructuring_pattern_expected",
        "Array_element_destructuring_pattern_expected_1181",
        DiagnosticCategory::error(),
        1181,
        "Array element destructuring pattern expected.",
        0,
      )
    1185 =>
      _make_diagnostic_message(
        "Diagnostics.Merge_conflict_marker_encountered",
        "Merge_conflict_marker_encountered_1185",
        DiagnosticCategory::error(),
        1185,
        "Merge conflict marker encountered.",
        0,
      )
    1198 =>
      _make_diagnostic_message(
        "Diagnostics.An_extended_Unicode_escape_value_must_be_between_0x0_and_0x10FFFF_inclusive",
        "An_extended_Unicode_escape_value_must_be_between_0x0_and_0x10FFFF_inclusive_1198",
        DiagnosticCategory::error(),
        1198,
        "An extended Unicode escape value must be between 0x0 and 0x10FFFF inclusive.",
        0,
      )
    1199 =>
      _make_diagnostic_message(
        "Diagnostics.Unterminated_Unicode_escape_sequence",
        "Unterminated_Unicode_escape_sequence_1199",
        DiagnosticCategory::error(),
        1199,
        "Unterminated Unicode escape sequence.",
        0,
      )
    1209 =>
      _make_diagnostic_message(
        "Diagnostics.Invalid_optional_chain_from_new_expression_Did_you_mean_to_call_0",
        "Invalid_optional_chain_from_new_expression_Did_you_mean_to_call_0_1209",
        DiagnosticCategory::error(),
        1209,
        "Invalid optional chain from new expression. Did you mean to call '{0}()'?",
        1,
      )
    1223 =>
      _make_diagnostic_message(
        "Diagnostics._0_tag_already_specified",
        "_0_tag_already_specified_1223",
        DiagnosticCategory::error(),
        1223,
        "'{0}' tag already specified.",
        1,
      )
    1228 =>
      _make_diagnostic_message(
        "Diagnostics.A_type_predicate_is_only_allowed_in_return_type_position_for_functions_and_methods",
        "A_type_predicate_is_only_allowed_in_return_type_position_for_functions_and_methods_1228",
        DiagnosticCategory::error(),
        1228,
        "A type predicate is only allowed in return type position for functions and methods.",
        0,
      )
    1260 =>
      _make_diagnostic_message(
        "Diagnostics.Keywords_cannot_contain_escape_characters",
        "Keywords_cannot_contain_escape_characters_1260",
        DiagnosticCategory::error(),
        1260,
        "Keywords cannot contain escape characters.",
        0,
      )
    1327 =>
      _make_diagnostic_message(
        "Diagnostics.String_literal_with_double_quotes_expected",
        "String_literal_with_double_quotes_expected_1327",
        DiagnosticCategory::error(),
        1327,
        "String literal with double quotes expected.",
        0,
      )
    1328 =>
      _make_diagnostic_message(
        "Diagnostics.Property_value_can_only_be_string_literal_numeric_literal_true_false_null_object_literal_or_array_literal",
        "Property_value_can_only_be_string_literal_numeric_literal_true_false_null_object_literal_or_array_li_1328",
        DiagnosticCategory::error(),
        1328,
        "Property value can only be string literal, numeric literal, 'true', 'false', 'null', object literal or array literal.",
        0,
      )
    1351 =>
      _make_diagnostic_message(
        "Diagnostics.An_identifier_or_keyword_cannot_immediately_follow_a_numeric_literal",
        "An_identifier_or_keyword_cannot_immediately_follow_a_numeric_literal_1351",
        DiagnosticCategory::error(),
        1351,
        "An identifier or keyword cannot immediately follow a numeric literal.",
        0,
      )
    1352 =>
      _make_diagnostic_message(
        "Diagnostics.A_bigint_literal_cannot_use_exponential_notation",
        "A_bigint_literal_cannot_use_exponential_notation_1352",
        DiagnosticCategory::error(),
        1352,
        "A bigint literal cannot use exponential notation.",
        0,
      )
    1353 =>
      _make_diagnostic_message(
        "Diagnostics.A_bigint_literal_must_be_an_integer",
        "A_bigint_literal_must_be_an_integer_1353",
        DiagnosticCategory::error(),
        1353,
        "A bigint literal must be an integer.",
        0,
      )
    1357 =>
      _make_diagnostic_message(
        "Diagnostics.An_enum_member_name_must_be_followed_by_a_or",
        "An_enum_member_name_must_be_followed_by_a_or_1357",
        DiagnosticCategory::error(),
        1357,
        "An enum member name must be followed by a ',', '=', or '}'.",
        0,
      )
    1359 =>
      _make_diagnostic_message(
        "Diagnostics.Identifier_expected_0_is_a_reserved_word_that_cannot_be_used_here",
        "Identifier_expected_0_is_a_reserved_word_that_cannot_be_used_here_1359",
        DiagnosticCategory::error(),
        1359,
        "Identifier expected. '{0}' is a reserved word that cannot be used here.",
        1,
      )
    1369 =>
      _make_diagnostic_message(
        "Diagnostics.Did_you_mean_0",
        "Did_you_mean_0_1369",
        DiagnosticCategory::message(),
        1369,
        "Did you mean '{0}'?",
        1,
      )
    1381 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_token_Did_you_mean_or_rbrace",
        "Unexpected_token_Did_you_mean_or_rbrace_1381",
        DiagnosticCategory::error(),
        1381,
        "Unexpected token. Did you mean `{'}'}` or `&rbrace;`?",
        0,
      )
    1382 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_token_Did_you_mean_or_gt",
        "Unexpected_token_Did_you_mean_or_gt_1382",
        DiagnosticCategory::error(),
        1382,
        "Unexpected token. Did you mean `{'>'}` or `&gt;`?",
        0,
      )
    1385 =>
      _make_diagnostic_message(
        "Diagnostics.Function_type_notation_must_be_parenthesized_when_used_in_a_union_type",
        "Function_type_notation_must_be_parenthesized_when_used_in_a_union_type_1385",
        DiagnosticCategory::error(),
        1385,
        "Function type notation must be parenthesized when used in a union type.",
        0,
      )
    1386 =>
      _make_diagnostic_message(
        "Diagnostics.Constructor_type_notation_must_be_parenthesized_when_used_in_a_union_type",
        "Constructor_type_notation_must_be_parenthesized_when_used_in_a_union_type_1386",
        DiagnosticCategory::error(),
        1386,
        "Constructor type notation must be parenthesized when used in a union type.",
        0,
      )
    1387 =>
      _make_diagnostic_message(
        "Diagnostics.Function_type_notation_must_be_parenthesized_when_used_in_an_intersection_type",
        "Function_type_notation_must_be_parenthesized_when_used_in_an_intersection_type_1387",
        DiagnosticCategory::error(),
        1387,
        "Function type notation must be parenthesized when used in an intersection type.",
        0,
      )
    1388 =>
      _make_diagnostic_message(
        "Diagnostics.Constructor_type_notation_must_be_parenthesized_when_used_in_an_intersection_type",
        "Constructor_type_notation_must_be_parenthesized_when_used_in_an_intersection_type_1388",
        DiagnosticCategory::error(),
        1388,
        "Constructor type notation must be parenthesized when used in an intersection type.",
        0,
      )
    1389 =>
      _make_diagnostic_message(
        "Diagnostics._0_is_not_allowed_as_a_variable_declaration_name",
        "_0_is_not_allowed_as_a_variable_declaration_name_1389",
        DiagnosticCategory::error(),
        1389,
        "'{0}' is not allowed as a variable declaration name.",
        1,
      )
    1390 =>
      _make_diagnostic_message(
        "Diagnostics._0_is_not_allowed_as_a_parameter_name",
        "_0_is_not_allowed_as_a_parameter_name_1390",
        DiagnosticCategory::error(),
        1390,
        "'{0}' is not allowed as a parameter name.",
        1,
      )
    1433 =>
      _make_diagnostic_message(
        "Diagnostics.Neither_decorators_nor_modifiers_may_be_applied_to_this_parameters",
        "Neither_decorators_nor_modifiers_may_be_applied_to_this_parameters_1433",
        DiagnosticCategory::error(),
        1433,
        "Neither decorators nor modifiers may be applied to 'this' parameters.",
        0,
      )
    1434 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_keyword_or_identifier",
        "Unexpected_keyword_or_identifier_1434",
        DiagnosticCategory::error(),
        1434,
        "Unexpected keyword or identifier.",
        0,
      )
    1435 =>
      _make_diagnostic_message(
        "Diagnostics.Unknown_keyword_or_identifier_Did_you_mean_0",
        "Unknown_keyword_or_identifier_Did_you_mean_0_1435",
        DiagnosticCategory::error(),
        1435,
        "Unknown keyword or identifier. Did you mean '{0}'?",
        1,
      )
    1436 =>
      _make_diagnostic_message(
        "Diagnostics.Decorators_must_precede_the_name_and_all_keywords_of_property_declarations",
        "Decorators_must_precede_the_name_and_all_keywords_of_property_declarations_1436",
        DiagnosticCategory::error(),
        1436,
        "Decorators must precede the name and all keywords of property declarations.",
        0,
      )
    1437 =>
      _make_diagnostic_message(
        "Diagnostics.Namespace_must_be_given_a_name",
        "Namespace_must_be_given_a_name_1437",
        DiagnosticCategory::error(),
        1437,
        "Namespace must be given a name.",
        0,
      )
    1438 =>
      _make_diagnostic_message(
        "Diagnostics.Interface_must_be_given_a_name",
        "Interface_must_be_given_a_name_1438",
        DiagnosticCategory::error(),
        1438,
        "Interface must be given a name.",
        0,
      )
    1439 =>
      _make_diagnostic_message(
        "Diagnostics.Type_alias_must_be_given_a_name",
        "Type_alias_must_be_given_a_name_1439",
        DiagnosticCategory::error(),
        1439,
        "Type alias must be given a name.",
        0,
      )
    1440 =>
      _make_diagnostic_message(
        "Diagnostics.Variable_declaration_not_allowed_at_this_location",
        "Variable_declaration_not_allowed_at_this_location_1440",
        DiagnosticCategory::error(),
        1440,
        "Variable declaration not allowed at this location.",
        0,
      )
    1441 =>
      _make_diagnostic_message(
        "Diagnostics.Cannot_start_a_function_call_in_a_type_annotation",
        "Cannot_start_a_function_call_in_a_type_annotation_1441",
        DiagnosticCategory::error(),
        1441,
        "Cannot start a function call in a type annotation.",
        0,
      )
    1442 =>
      _make_diagnostic_message(
        "Diagnostics.Expected_for_property_initializer",
        "Expected_for_property_initializer_1442",
        DiagnosticCategory::error(),
        1442,
        "Expected '=' for property initializer.",
        0,
      )
    1443 =>
      _make_diagnostic_message(
        "Diagnostics.Module_declaration_names_may_only_use_or_quoted_strings",
        "Module_declaration_names_may_only_use_or_quoted_strings_1443",
        DiagnosticCategory::error(),
        1443,
        "Module declaration names may only use ' or \" quoted strings.",
        0,
      )
    1453 =>
      _make_diagnostic_message(
        "Diagnostics.resolution_mode_should_be_either_require_or_import",
        "resolution_mode_should_be_either_require_or_import_1453",
        DiagnosticCategory::error(),
        1453,
        "`resolution-mode` should be either `require` or `import`.",
        0,
      )
    1472 =>
      _make_diagnostic_message(
        "Diagnostics.catch_or_finally_expected",
        "catch_or_finally_expected_1472",
        DiagnosticCategory::error(),
        1472,
        "'catch' or 'finally' expected.",
        0,
      )
    1477 =>
      _make_diagnostic_message(
        "Diagnostics.An_instantiation_expression_cannot_be_followed_by_a_property_access",
        "An_instantiation_expression_cannot_be_followed_by_a_property_access_1477",
        DiagnosticCategory::error(),
        1477,
        "An instantiation expression cannot be followed by a property access.",
        0,
      )
    1478 =>
      _make_diagnostic_message(
        "Diagnostics.Identifier_or_string_literal_expected",
        "Identifier_or_string_literal_expected_1478",
        DiagnosticCategory::error(),
        1478,
        "Identifier or string literal expected.",
        0,
      )
    1487 =>
      _make_diagnostic_message(
        "Diagnostics.Octal_escape_sequences_are_not_allowed_Use_the_syntax_0",
        "Octal_escape_sequences_are_not_allowed_Use_the_syntax_0_1487",
        DiagnosticCategory::error(),
        1487,
        "Octal escape sequences are not allowed. Use the syntax '{0}'.",
        1,
      )
    1488 =>
      _make_diagnostic_message(
        "Diagnostics.Escape_sequence_0_is_not_allowed",
        "Escape_sequence_0_is_not_allowed_1488",
        DiagnosticCategory::error(),
        1488,
        "Escape sequence '{0}' is not allowed.",
        1,
      )
    1489 =>
      _make_diagnostic_message(
        "Diagnostics.Decimals_with_leading_zeros_are_not_allowed",
        "Decimals_with_leading_zeros_are_not_allowed_1489",
        DiagnosticCategory::error(),
        1489,
        "Decimals with leading zeros are not allowed.",
        0,
      )
    1490 =>
      _make_diagnostic_message(
        "Diagnostics.File_appears_to_be_binary",
        "File_appears_to_be_binary_1490",
        DiagnosticCategory::error(),
        1490,
        "File appears to be binary.",
        0,
      )
    1499 =>
      _make_diagnostic_message(
        "Diagnostics.Unknown_regular_expression_flag",
        "Unknown_regular_expression_flag_1499",
        DiagnosticCategory::error(),
        1499,
        "Unknown regular expression flag.",
        0,
      )
    1500 =>
      _make_diagnostic_message(
        "Diagnostics.Duplicate_regular_expression_flag",
        "Duplicate_regular_expression_flag_1500",
        DiagnosticCategory::error(),
        1500,
        "Duplicate regular expression flag.",
        0,
      )
    1501 =>
      _make_diagnostic_message(
        "Diagnostics.This_regular_expression_flag_is_only_available_when_targeting_0_or_later",
        "This_regular_expression_flag_is_only_available_when_targeting_0_or_later_1501",
        DiagnosticCategory::error(),
        1501,
        "This regular expression flag is only available when targeting '{0}' or later.",
        1,
      )
    1502 =>
      _make_diagnostic_message(
        "Diagnostics.The_Unicode_u_flag_and_the_Unicode_Sets_v_flag_cannot_be_set_simultaneously",
        "The_Unicode_u_flag_and_the_Unicode_Sets_v_flag_cannot_be_set_simultaneously_1502",
        DiagnosticCategory::error(),
        1502,
        "The Unicode (u) flag and the Unicode Sets (v) flag cannot be set simultaneously.",
        0,
      )
    1503 =>
      _make_diagnostic_message(
        "Diagnostics.Named_capturing_groups_are_only_available_when_targeting_ES2018_or_later",
        "Named_capturing_groups_are_only_available_when_targeting_ES2018_or_later_1503",
        DiagnosticCategory::error(),
        1503,
        "Named capturing groups are only available when targeting 'ES2018' or later.",
        0,
      )
    1504 =>
      _make_diagnostic_message(
        "Diagnostics.Subpattern_flags_must_be_present_when_there_is_a_minus_sign",
        "Subpattern_flags_must_be_present_when_there_is_a_minus_sign_1504",
        DiagnosticCategory::error(),
        1504,
        "Subpattern flags must be present when there is a minus sign.",
        0,
      )
    1505 =>
      _make_diagnostic_message(
        "Diagnostics.Incomplete_quantifier_Digit_expected",
        "Incomplete_quantifier_Digit_expected_1505",
        DiagnosticCategory::error(),
        1505,
        "Incomplete quantifier. Digit expected.",
        0,
      )
    1506 =>
      _make_diagnostic_message(
        "Diagnostics.Numbers_out_of_order_in_quantifier",
        "Numbers_out_of_order_in_quantifier_1506",
        DiagnosticCategory::error(),
        1506,
        "Numbers out of order in quantifier.",
        0,
      )
    1507 =>
      _make_diagnostic_message(
        "Diagnostics.There_is_nothing_available_for_repetition",
        "There_is_nothing_available_for_repetition_1507",
        DiagnosticCategory::error(),
        1507,
        "There is nothing available for repetition.",
        0,
      )
    1508 =>
      _make_diagnostic_message(
        "Diagnostics.Unexpected_0_Did_you_mean_to_escape_it_with_backslash",
        "Unexpected_0_Did_you_mean_to_escape_it_with_backslash_1508",
        DiagnosticCategory::error(),
        1508,
        "Unexpected '{0}'. Did you mean to escape it with backslash?",
        1,
      )
    1509 =>
      _make_diagnostic_message(
        "Diagnostics.This_regular_expression_flag_cannot_be_toggled_within_a_subpattern",
        "This_regular_expression_flag_cannot_be_toggled_within_a_subpattern_1509",
        DiagnosticCategory::error(),
        1509,
        "This regular expression flag cannot be toggled within a subpattern.",
        0,
      )
    1510 =>
      _make_diagnostic_message(
        "Diagnostics.k_must_be_followed_by_a_capturing_group_name_enclosed_in_angle_brackets",
        "k_must_be_followed_by_a_capturing_group_name_enclosed_in_angle_brackets_1510",
        DiagnosticCategory::error(),
        1510,
        "'\\k' must be followed by a capturing group name enclosed in angle brackets.",
        0,
      )
    1511 =>
      _make_diagnostic_message(
        "Diagnostics.q_is_only_available_inside_character_class",
        "q_is_only_available_inside_character_class_1511",
        DiagnosticCategory::error(),
        1511,
        "'\\q' is only available inside character class.",
        0,
      )
    1512 =>
      _make_diagnostic_message(
        "Diagnostics.c_must_be_followed_by_an_ASCII_letter",
        "c_must_be_followed_by_an_ASCII_letter_1512",
        DiagnosticCategory::error(),
        1512,
        "'\\c' must be followed by an ASCII letter.",
        0,
      )
    1513 =>
      _make_diagnostic_message(
        "Diagnostics.Undetermined_character_escape",
        "Undetermined_character_escape_1513",
        DiagnosticCategory::error(),
        1513,
        "Undetermined character escape.",
        0,
      )
    1514 =>
      _make_diagnostic_message(
        "Diagnostics.Expected_a_capturing_group_name",
        "Expected_a_capturing_group_name_1514",
        DiagnosticCategory::error(),
        1514,
        "Expected a capturing group name.",
        0,
      )
    1515 =>
      _make_diagnostic_message(
        "Diagnostics.Named_capturing_groups_with_the_same_name_must_be_mutually_exclusive_to_each_other",
        "Named_capturing_groups_with_the_same_name_must_be_mutually_exclusive_to_each_other_1515",
        DiagnosticCategory::error(),
        1515,
        "Named capturing groups with the same name must be mutually exclusive to each other.",
        0,
      )
    1516 =>
      _make_diagnostic_message(
        "Diagnostics.A_character_class_range_must_not_be_bounded_by_another_character_class",
        "A_character_class_range_must_not_be_bounded_by_another_character_class_1516",
        DiagnosticCategory::error(),
        1516,
        "A character class range must not be bounded by another character class.",
        0,
      )
    1517 =>
      _make_diagnostic_message(
        "Diagnostics.Range_out_of_order_in_character_class",
        "Range_out_of_order_in_character_class_1517",
        DiagnosticCategory::error(),
        1517,
        "Range out of order in character class.",
        0,
      )
    1518 =>
      _make_diagnostic_message(
        "Diagnostics.Anything_that_would_possibly_match_more_than_a_single_character_is_invalid_inside_a_negated_character_class",
        "Anything_that_would_possibly_match_more_than_a_single_character_is_invalid_inside_a_negated_characte_1518",
        DiagnosticCategory::error(),
        1518,
        "Anything that would possibly match more than a single character is invalid inside a negated character class.",
        0,
      )
    1519 =>
      _make_diagnostic_message(
        "Diagnostics.Operators_must_not_be_mixed_within_a_character_class_Wrap_it_in_a_nested_class_instead",
        "Operators_must_not_be_mixed_within_a_character_class_Wrap_it_in_a_nested_class_instead_1519",
        DiagnosticCategory::error(),
        1519,
        "Operators must not be mixed within a character class. Wrap it in a nested class instead.",
        0,
      )
    1520 =>
      _make_diagnostic_message(
        "Diagnostics.Expected_a_class_set_operand",
        "Expected_a_class_set_operand_1520",
        DiagnosticCategory::error(),
        1520,
        "Expected a class set operand.",
        0,
      )
    1521 =>
      _make_diagnostic_message(
        "Diagnostics.q_must_be_followed_by_string_alternatives_enclosed_in_braces",
        "q_must_be_followed_by_string_alternatives_enclosed_in_braces_1521",
        DiagnosticCategory::error(),
        1521,
        "'\\q' must be followed by string alternatives enclosed in braces.",
        0,
      )
    1522 =>
      _make_diagnostic_message(
        "Diagnostics.A_character_class_must_not_contain_a_reserved_double_punctuator_Did_you_mean_to_escape_it_with_backslash",
        "A_character_class_must_not_contain_a_reserved_double_punctuator_Did_you_mean_to_escape_it_with_backs_1522",
        DiagnosticCategory::error(),
        1522,
        "A character class must not contain a reserved double punctuator. Did you mean to escape it with backslash?",
        0,
      )
    1523 =>
      _make_diagnostic_message(
        "Diagnostics.Expected_a_Unicode_property_name",
        "Expected_a_Unicode_property_name_1523",
        DiagnosticCategory::error(),
        1523,
        "Expected a Unicode property name.",
        0,
      )
    1524 =>
      _make_diagnostic_message(
        "Diagnostics.Unknown_Unicode_property_name",
        "Unknown_Unicode_property_name_1524",
        DiagnosticCategory::error(),
        1524,
        "Unknown Unicode property name.",
        0,
      )
    1525 =>
      _make_diagnostic_message(
        "Diagnostics.Expected_a_Unicode_property_value",
        "Expected_a_Unicode_property_value_1525",
        DiagnosticCategory::error(),
        1525,
        "Expected a Unicode property value.",
        0,
      )
    1526 =>
      _make_diagnostic_message(
        "Diagnostics.Unknown_Unicode_property_value",
        "Unknown_Unicode_property_value_1526",
        DiagnosticCategory::error(),
        1526,
        "Unknown Unicode property value.",
        0,
      )
    1527 =>
      _make_diagnostic_message(
        "Diagnostics.Expected_a_Unicode_property_name_or_value",
        "Expected_a_Unicode_property_name_or_value_1527",
        DiagnosticCategory::error(),
        1527,
        "Expected a Unicode property name or value.",
        0,
      )
    1528 =>
      _make_diagnostic_message(
        "Diagnostics.Any_Unicode_property_that_would_possibly_match_more_than_a_single_character_is_only_available_when_the_Unicode_Sets_v_flag_is_set",
        "Any_Unicode_property_that_would_possibly_match_more_than_a_single_character_is_only_available_when_t_1528",
        DiagnosticCategory::error(),
        1528,
        "Any Unicode property that would possibly match more than a single character is only available when the Unicode Sets (v) flag is set.",
        0,
      )
    1529 =>
      _make_diagnostic_message(
        "Diagnostics.Unknown_Unicode_property_name_or_value",
        "Unknown_Unicode_property_name_or_value_1529",
        DiagnosticCategory::error(),
        1529,
        "Unknown Unicode property name or value.",
        0,
      )
    1530 =>
      _make_diagnostic_message(
        "Diagnostics.Unicode_property_value_expressions_are_only_available_when_the_Unicode_u_flag_or_the_Unicode_Sets_v_flag_is_set",
        "Unicode_property_value_expressions_are_only_available_when_the_Unicode_u_flag_or_the_Unicode_Sets_v__1530",
        DiagnosticCategory::error(),
        1530,
        "Unicode property value expressions are only available when the Unicode (u) flag or the Unicode Sets (v) flag is set.",
        0,
      )
    1531 =>
      _make_diagnostic_message(
        "Diagnostics._0_must_be_followed_by_a_Unicode_property_value_expression_enclosed_in_braces",
        "_0_must_be_followed_by_a_Unicode_property_value_expression_enclosed_in_braces_1531",
        DiagnosticCategory::error(),
        1531,
        "'\\{0}' must be followed by a Unicode property value expression enclosed in braces.",
        1,
      )
    1532 =>
      _make_diagnostic_message(
        "Diagnostics.There_is_no_capturing_group_named_0_in_this_regular_expression",
        "There_is_no_capturing_group_named_0_in_this_regular_expression_1532",
        DiagnosticCategory::error(),
        1532,
        "There is no capturing group named '{0}' in this regular expression.",
        1,
      )
    1533 =>
      _make_diagnostic_message(
        "Diagnostics.This_backreference_refers_to_a_group_that_does_not_exist_There_are_only_0_capturing_groups_in_this_regular_expression",
        "This_backreference_refers_to_a_group_that_does_not_exist_There_are_only_0_capturing_groups_in_this_r_1533",
        DiagnosticCategory::error(),
        1533,
        "This backreference refers to a group that does not exist. There are only {0} capturing groups in this regular expression.",
        1,
      )
    1534 =>
      _make_diagnostic_message(
        "Diagnostics.This_backreference_refers_to_a_group_that_does_not_exist_There_are_no_capturing_groups_in_this_regular_expression",
        "This_backreference_refers_to_a_group_that_does_not_exist_There_are_no_capturing_groups_in_this_regul_1534",
        DiagnosticCategory::error(),
        1534,
        "This backreference refers to a group that does not exist. There are no capturing groups in this regular expression.",
        0,
      )
    1535 =>
      _make_diagnostic_message(
        "Diagnostics.This_character_cannot_be_escaped_in_a_regular_expression",
        "This_character_cannot_be_escaped_in_a_regular_expression_1535",
        DiagnosticCategory::error(),
        1535,
        "This character cannot be escaped in a regular expression.",
        0,
      )
    1536 =>
      _make_diagnostic_message(
        "Diagnostics.Octal_escape_sequences_and_backreferences_are_not_allowed_in_a_character_class_If_this_was_intended_as_an_escape_sequence_use_the_syntax_0_instead",
        "Octal_escape_sequences_and_backreferences_are_not_allowed_in_a_character_class_If_this_was_intended__1536",
        DiagnosticCategory::error(),
        1536,
        "Octal escape sequences and backreferences are not allowed in a character class. If this was intended as an escape sequence, use the syntax '{0}' instead.",
        1,
      )
    1537 =>
      _make_diagnostic_message(
        "Diagnostics.Decimal_escape_sequences_and_backreferences_are_not_allowed_in_a_character_class",
        "Decimal_escape_sequences_and_backreferences_are_not_allowed_in_a_character_class_1537",
        DiagnosticCategory::error(),
        1537,
        "Decimal escape sequences and backreferences are not allowed in a character class.",
        0,
      )
    1538 =>
      _make_diagnostic_message(
        "Diagnostics.Unicode_escape_sequences_are_only_available_when_the_Unicode_u_flag_or_the_Unicode_Sets_v_flag_is_set",
        "Unicode_escape_sequences_are_only_available_when_the_Unicode_u_flag_or_the_Unicode_Sets_v_flag_is_se_1538",
        DiagnosticCategory::error(),
        1538,
        "Unicode escape sequences are only available when the Unicode (u) flag or the Unicode Sets (v) flag is set.",
        0,
      )
    2427 =>
      _make_diagnostic_message(
        "Diagnostics.Interface_name_cannot_be_0",
        "Interface_name_cannot_be_0_2427",
        DiagnosticCategory::error(),
        2427,
        "Interface name cannot be '{0}'.",
        1,
      )
    2457 =>
      _make_diagnostic_message(
        "Diagnostics.Type_alias_name_cannot_be_0",
        "Type_alias_name_cannot_be_0_2457",
        DiagnosticCategory::error(),
        2457,
        "Type alias name cannot be '{0}'.",
        1,
      )
    2458 =>
      _make_diagnostic_message(
        "Diagnostics.An_AMD_module_cannot_have_multiple_name_assignments",
        "An_AMD_module_cannot_have_multiple_name_assignments_2458",
        DiagnosticCategory::error(),
        2458,
        "An AMD module cannot have multiple name assignments.",
        0,
      )
    2657 =>
      _make_diagnostic_message(
        "Diagnostics.JSX_expressions_must_have_one_parent_element",
        "JSX_expressions_must_have_one_parent_element_2657",
        DiagnosticCategory::error(),
        2657,
        "JSX expressions must have one parent element.",
        0,
      )
    2754 =>
      _make_diagnostic_message(
        "Diagnostics.super_may_not_use_type_arguments",
        "super_may_not_use_type_arguments_2754",
        DiagnosticCategory::error(),
        2754,
        "'super' may not use type arguments.",
        0,
      )
    2809 =>
      _make_diagnostic_message(
        "Diagnostics.Declaration_or_statement_expected_This_follows_a_block_of_statements_so_if_you_intended_to_write_a_destructuring_assignment_you_might_need_to_wrap_the_whole_assignment_in_parentheses",
        "Declaration_or_statement_expected_This_follows_a_block_of_statements_so_if_you_intended_to_write_a_d_2809",
        DiagnosticCategory::error(),
        2809,
        "Declaration or statement expected. This '=' follows a block of statements, so if you intended to write a destructuring assignment, you might need to wrap the whole assignment in parentheses.",
        0,
      )
    2819 =>
      _make_diagnostic_message(
        "Diagnostics.Namespace_name_cannot_be_0",
        "Namespace_name_cannot_be_0_2819",
        DiagnosticCategory::error(),
        2819,
        "Namespace name cannot be '{0}'.",
        1,
      )
    6188 =>
      _make_diagnostic_message(
        "Diagnostics.Numeric_separators_are_not_allowed_here",
        "Numeric_separators_are_not_allowed_here_6188",
        DiagnosticCategory::error(),
        6188,
        "Numeric separators are not allowed here.",
        0,
      )
    6189 =>
      _make_diagnostic_message(
        "Diagnostics.Multiple_consecutive_numeric_separators_are_not_permitted",
        "Multiple_consecutive_numeric_separators_are_not_permitted_6189",
        DiagnosticCategory::error(),
        6189,
        "Multiple consecutive numeric separators are not permitted.",
        0,
      )
    8009 =>
      _make_diagnostic_message(
        "Diagnostics.The_0_modifier_can_only_be_used_in_TypeScript_files",
        "The_0_modifier_can_only_be_used_in_TypeScript_files_8009",
        DiagnosticCategory::error(),
        8009,
        "The '{0}' modifier can only be used in TypeScript files.",
        1,
      )
    8033 =>
      _make_diagnostic_message(
        "Diagnostics.A_JSDoc_typedef_comment_may_not_contain_multiple_type_tags",
        "A_JSDoc_typedef_comment_may_not_contain_multiple_type_tags_8033",
        DiagnosticCategory::error(),
        8033,
        "A JSDoc '@typedef' comment may not contain multiple '@type' tags.",
        0,
      )
    8034 =>
      _make_diagnostic_message(
        "Diagnostics.The_tag_was_first_specified_here",
        "The_tag_was_first_specified_here_8034",
        DiagnosticCategory::error(),
        8034,
        "The tag was first specified here.",
        0,
      )
    8039 =>
      _make_diagnostic_message(
        "Diagnostics.A_JSDoc_template_tag_may_not_follow_a_typedef_callback_or_overload_tag",
        "A_JSDoc_template_tag_may_not_follow_a_typedef_callback_or_overload_tag_8039",
        DiagnosticCategory::error(),
        8039,
        "A JSDoc '@template' tag may not follow a '@typedef', '@callback', or '@overload' tag",
        0,
      )
    17002 =>
      _make_diagnostic_message(
        "Diagnostics.Expected_corresponding_JSX_closing_tag_for_0",
        "Expected_corresponding_JSX_closing_tag_for_0_17002",
        DiagnosticCategory::error(),
        17002,
        "Expected corresponding JSX closing tag for '{0}'.",
        1,
      )
    17006 =>
      _make_diagnostic_message(
        "Diagnostics.An_unary_expression_with_the_0_operator_is_not_allowed_in_the_left_hand_side_of_an_exponentiation_expression_Consider_enclosing_the_expression_in_parentheses",
        "An_unary_expression_with_the_0_operator_is_not_allowed_in_the_left_hand_side_of_an_exponentiation_ex_17006",
        DiagnosticCategory::error(),
        17006,
        "An unary expression with the '{0}' operator is not allowed in the left-hand side of an exponentiation expression. Consider enclosing the expression in parentheses.",
        1,
      )
    17007 =>
      _make_diagnostic_message(
        "Diagnostics.A_type_assertion_expression_is_not_allowed_in_the_left_hand_side_of_an_exponentiation_expression_Consider_enclosing_the_expression_in_parentheses",
        "A_type_assertion_expression_is_not_allowed_in_the_left_hand_side_of_an_exponentiation_expression_Con_17007",
        DiagnosticCategory::error(),
        17007,
        "A type assertion expression is not allowed in the left-hand side of an exponentiation expression. Consider enclosing the expression in parentheses.",
        0,
      )
    17008 =>
      _make_diagnostic_message(
        "Diagnostics.JSX_element_0_has_no_corresponding_closing_tag",
        "JSX_element_0_has_no_corresponding_closing_tag_17008",
        DiagnosticCategory::error(),
        17008,
        "JSX element '{0}' has no corresponding closing tag.",
        1,
      )
    17014 =>
      _make_diagnostic_message(
        "Diagnostics.JSX_fragment_has_no_corresponding_closing_tag",
        "JSX_fragment_has_no_corresponding_closing_tag_17014",
        DiagnosticCategory::error(),
        17014,
        "JSX fragment has no corresponding closing tag.",
        0,
      )
    17015 =>
      _make_diagnostic_message(
        "Diagnostics.Expected_corresponding_closing_tag_for_JSX_fragment",
        "Expected_corresponding_closing_tag_for_JSX_fragment_17015",
        DiagnosticCategory::error(),
        17015,
        "Expected corresponding closing tag for JSX fragment.",
        0,
      )
    17021 =>
      _make_diagnostic_message(
        "Diagnostics.Unicode_escape_sequence_cannot_appear_here",
        "Unicode_escape_sequence_cannot_appear_here_17021",
        DiagnosticCategory::error(),
        17021,
        "Unicode escape sequence cannot appear here.",
        0,
      )
    18009 =>
      _make_diagnostic_message(
        "Diagnostics.Private_identifiers_cannot_be_used_as_parameters",
        "Private_identifiers_cannot_be_used_as_parameters_18009",
        DiagnosticCategory::error(),
        18009,
        "Private identifiers cannot be used as parameters.",
        0,
      )
    18016 =>
      _make_diagnostic_message(
        "Diagnostics.Private_identifiers_are_not_allowed_outside_class_bodies",
        "Private_identifiers_are_not_allowed_outside_class_bodies_18016",
        DiagnosticCategory::error(),
        18016,
        "Private identifiers are not allowed outside class bodies.",
        0,
      )
    18026 =>
      _make_diagnostic_message(
        "Diagnostics.can_only_be_used_at_the_start_of_a_file",
        "can_only_be_used_at_the_start_of_a_file_18026",
        DiagnosticCategory::error(),
        18026,
        "'#!' can only be used at the start of a file.",
        0,
      )
    18029 =>
      _make_diagnostic_message(
        "Diagnostics.Private_identifiers_are_not_allowed_in_variable_declarations",
        "Private_identifiers_are_not_allowed_in_variable_declarations_18029",
        DiagnosticCategory::error(),
        18029,
        "Private identifiers are not allowed in variable declarations.",
        0,
      )
    18030 =>
      _make_diagnostic_message(
        "Diagnostics.An_optional_chain_cannot_contain_private_identifiers",
        "An_optional_chain_cannot_contain_private_identifiers_18030",
        DiagnosticCategory::error(),
        18030,
        "An optional chain cannot contain private identifiers.",
        0,
      )
    _ => abort("diagnostic code is outside the parser catalog")
  }
}

///|
fn _diagnostic_catalog_codes() -> ReadOnlyArray[Int] {
  ReadOnlyArray::from_array([
    1002, 1003, 1005, 1007, 1010, 1011, 1012, 1034, 1068, 1069, 1084, 1109, 1110,
    1121, 1124, 1125, 1126, 1127, 1128, 1129, 1130, 1131, 1132, 1134, 1135, 1136,
    1137, 1138, 1139, 1140, 1142, 1144, 1145, 1146, 1160, 1161, 1177, 1178, 1179,
    1180, 1181, 1185, 1198, 1199, 1209, 1223, 1228, 1260, 1327, 1328, 1351, 1352,
    1353, 1357, 1359, 1369, 1381, 1382, 1385, 1386, 1387, 1388, 1389, 1390, 1433,
    1434, 1435, 1436, 1437, 1438, 1439, 1440, 1441, 1442, 1443, 1453, 1472, 1477,
    1478, 1487, 1488, 1489, 1490, 1499, 1500, 1501, 1502, 1503, 1504, 1505, 1506,
    1507, 1508, 1509, 1510, 1511, 1512, 1513, 1514, 1515, 1516, 1517, 1518, 1519,
    1520, 1521, 1522, 1523, 1524, 1525, 1526, 1527, 1528, 1529, 1530, 1531, 1532,
    1533, 1534, 1535, 1536, 1537, 1538, 2427, 2457, 2458, 2657, 2754, 2809, 2819,
    6188, 6189, 8009, 8033, 8034, 8039, 17002, 17006, 17007, 17008, 17014, 17015,
    17021, 18009, 18016, 18026, 18029, 18030,
  ])
}
