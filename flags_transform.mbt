// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
pub fn TransformFlags::contains_typescript() -> TransformFlags {
  TransformFlags::from_bits(1U)
}

///|
pub fn TransformFlags::contains_jsx() -> TransformFlags {
  TransformFlags::from_bits(2U)
}

///|
pub fn TransformFlags::contains_es_next() -> TransformFlags {
  TransformFlags::from_bits(4U)
}

///|
pub fn TransformFlags::contains_es2022() -> TransformFlags {
  TransformFlags::from_bits(8U)
}

///|
pub fn TransformFlags::contains_es2021() -> TransformFlags {
  TransformFlags::from_bits(16U)
}

///|
pub fn TransformFlags::contains_es2020() -> TransformFlags {
  TransformFlags::from_bits(32U)
}

///|
pub fn TransformFlags::contains_es2019() -> TransformFlags {
  TransformFlags::from_bits(64U)
}

///|
pub fn TransformFlags::contains_es2018() -> TransformFlags {
  TransformFlags::from_bits(128U)
}

///|
pub fn TransformFlags::contains_es2017() -> TransformFlags {
  TransformFlags::from_bits(256U)
}

///|
pub fn TransformFlags::contains_es2016() -> TransformFlags {
  TransformFlags::from_bits(512U)
}

///|
pub fn TransformFlags::contains_es2015() -> TransformFlags {
  TransformFlags::from_bits(1024U)
}

///|
pub fn TransformFlags::contains_generator() -> TransformFlags {
  TransformFlags::from_bits(2048U)
}

///|
pub fn TransformFlags::contains_destructuring_assignment() -> TransformFlags {
  TransformFlags::from_bits(4096U)
}

///|
pub fn TransformFlags::contains_typescript_class_syntax() -> TransformFlags {
  TransformFlags::from_bits(8192U)
}

///|
pub fn TransformFlags::contains_lexical_this() -> TransformFlags {
  TransformFlags::from_bits(16384U)
}

///|
pub fn TransformFlags::contains_rest_or_spread() -> TransformFlags {
  TransformFlags::from_bits(32768U)
}

///|
pub fn TransformFlags::contains_object_rest_or_spread() -> TransformFlags {
  TransformFlags::from_bits(65536U)
}

///|
pub fn TransformFlags::contains_computed_property_name() -> TransformFlags {
  TransformFlags::from_bits(131072U)
}

///|
pub fn TransformFlags::contains_block_scoped_binding() -> TransformFlags {
  TransformFlags::from_bits(262144U)
}

///|
pub fn TransformFlags::contains_binding_pattern() -> TransformFlags {
  TransformFlags::from_bits(524288U)
}

///|
pub fn TransformFlags::contains_yield() -> TransformFlags {
  TransformFlags::from_bits(1048576U)
}

///|
pub fn TransformFlags::contains_await() -> TransformFlags {
  TransformFlags::from_bits(2097152U)
}

///|
pub fn TransformFlags::contains_hoisted_declaration_or_completion() -> TransformFlags {
  TransformFlags::from_bits(4194304U)
}

///|
pub fn TransformFlags::contains_dynamic_import() -> TransformFlags {
  TransformFlags::from_bits(8388608U)
}

///|
pub fn TransformFlags::contains_class_fields() -> TransformFlags {
  TransformFlags::from_bits(16777216U)
}

///|
pub fn TransformFlags::contains_decorators() -> TransformFlags {
  TransformFlags::from_bits(33554432U)
}

///|
pub fn TransformFlags::contains_possible_top_level_await() -> TransformFlags {
  TransformFlags::from_bits(67108864U)
}

///|
pub fn TransformFlags::contains_lexical_super() -> TransformFlags {
  TransformFlags::from_bits(134217728U)
}

///|
pub fn TransformFlags::contains_update_expression_for_identifier() -> TransformFlags {
  TransformFlags::from_bits(268435456U)
}

///|
pub fn TransformFlags::contains_private_identifier_in_expression() -> TransformFlags {
  TransformFlags::from_bits(536870912U)
}

///|
pub fn TransformFlags::assert_typescript() -> TransformFlags {
  TransformFlags::from_bits(1U)
}

///|
pub fn TransformFlags::assert_jsx() -> TransformFlags {
  TransformFlags::from_bits(2U)
}

///|
pub fn TransformFlags::assert_es_next() -> TransformFlags {
  TransformFlags::from_bits(4U)
}

///|
pub fn TransformFlags::assert_es2022() -> TransformFlags {
  TransformFlags::from_bits(8U)
}

///|
pub fn TransformFlags::assert_es2021() -> TransformFlags {
  TransformFlags::from_bits(16U)
}

///|
pub fn TransformFlags::assert_es2020() -> TransformFlags {
  TransformFlags::from_bits(32U)
}

///|
pub fn TransformFlags::assert_es2019() -> TransformFlags {
  TransformFlags::from_bits(64U)
}

///|
pub fn TransformFlags::assert_es2018() -> TransformFlags {
  TransformFlags::from_bits(128U)
}

///|
pub fn TransformFlags::assert_es2017() -> TransformFlags {
  TransformFlags::from_bits(256U)
}

///|
pub fn TransformFlags::assert_es2016() -> TransformFlags {
  TransformFlags::from_bits(512U)
}

///|
pub fn TransformFlags::assert_es2015() -> TransformFlags {
  TransformFlags::from_bits(1024U)
}

///|
pub fn TransformFlags::assert_generator() -> TransformFlags {
  TransformFlags::from_bits(2048U)
}

///|
pub fn TransformFlags::assert_destructuring_assignment() -> TransformFlags {
  TransformFlags::from_bits(4096U)
}

///|
pub fn TransformFlags::outer_expression_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147483648U)
}

///|
pub fn TransformFlags::property_access_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147483648U)
}

///|
pub fn TransformFlags::node_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147483648U)
}

///|
pub fn TransformFlags::arrow_function_excludes() -> TransformFlags {
  TransformFlags::from_bits(2222792704U)
}

///|
pub fn TransformFlags::function_excludes() -> TransformFlags {
  TransformFlags::from_bits(2357026816U)
}

///|
pub fn TransformFlags::constructor_excludes() -> TransformFlags {
  TransformFlags::from_bits(2357018624U)
}

///|
pub fn TransformFlags::method_or_accessor_excludes() -> TransformFlags {
  TransformFlags::from_bits(2289909760U)
}

///|
pub fn TransformFlags::property_excludes() -> TransformFlags {
  TransformFlags::from_bits(2281717760U)
}

///|
pub fn TransformFlags::class_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147622912U)
}

///|
pub fn TransformFlags::module_excludes() -> TransformFlags {
  TransformFlags::from_bits(2353291264U)
}

///|
pub fn TransformFlags::type_excludes() -> TransformFlags {
  TransformFlags::from_bits(4294967294U)
}

///|
pub fn TransformFlags::object_literal_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147688448U)
}

///|
pub fn TransformFlags::array_literal_or_call_or_new_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147516416U)
}

///|
pub fn TransformFlags::variable_declaration_list_excludes() -> TransformFlags {
  TransformFlags::from_bits(2148073472U)
}

///|
pub fn TransformFlags::parameter_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147483648U)
}

///|
pub fn TransformFlags::catch_clause_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147549184U)
}

///|
pub fn TransformFlags::binding_pattern_excludes() -> TransformFlags {
  TransformFlags::from_bits(2147516416U)
}

///|
pub fn TransformFlags::contains_lexical_this_or_super() -> TransformFlags {
  TransformFlags::from_bits(134234112U)
}

///|
pub fn TransformFlags::property_name_propagating_flags() -> TransformFlags {
  TransformFlags::from_bits(134234112U)
}
