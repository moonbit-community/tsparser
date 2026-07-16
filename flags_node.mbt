// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
pub fn NodeFlags::let_flag() -> NodeFlags {
  NodeFlags::from_bits(1U)
}

///|
pub fn NodeFlags::const_flag() -> NodeFlags {
  NodeFlags::from_bits(2U)
}

///|
pub fn NodeFlags::using_flag() -> NodeFlags {
  NodeFlags::from_bits(4U)
}

///|
pub fn NodeFlags::await_using() -> NodeFlags {
  NodeFlags::from_bits(6U)
}

///|
pub fn NodeFlags::nested_namespace() -> NodeFlags {
  NodeFlags::from_bits(8U)
}

///|
pub fn NodeFlags::synthesized() -> NodeFlags {
  NodeFlags::from_bits(16U)
}

///|
pub fn NodeFlags::namespace_flag() -> NodeFlags {
  NodeFlags::from_bits(32U)
}

///|
pub fn NodeFlags::optional_chain() -> NodeFlags {
  NodeFlags::from_bits(64U)
}

///|
pub fn NodeFlags::export_context() -> NodeFlags {
  NodeFlags::from_bits(128U)
}

///|
pub fn NodeFlags::contains_this() -> NodeFlags {
  NodeFlags::from_bits(256U)
}

///|
pub fn NodeFlags::has_implicit_return() -> NodeFlags {
  NodeFlags::from_bits(512U)
}

///|
pub fn NodeFlags::has_explicit_return() -> NodeFlags {
  NodeFlags::from_bits(1024U)
}

///|
pub fn NodeFlags::global_augmentation() -> NodeFlags {
  NodeFlags::from_bits(2048U)
}

///|
pub fn NodeFlags::has_async_functions() -> NodeFlags {
  NodeFlags::from_bits(4096U)
}

///|
pub fn NodeFlags::disallow_in_context() -> NodeFlags {
  NodeFlags::from_bits(8192U)
}

///|
pub fn NodeFlags::yield_context() -> NodeFlags {
  NodeFlags::from_bits(16384U)
}

///|
pub fn NodeFlags::decorator_context() -> NodeFlags {
  NodeFlags::from_bits(32768U)
}

///|
pub fn NodeFlags::await_context() -> NodeFlags {
  NodeFlags::from_bits(65536U)
}

///|
pub fn NodeFlags::disallow_conditional_types_context() -> NodeFlags {
  NodeFlags::from_bits(131072U)
}

///|
pub fn NodeFlags::this_node_has_error() -> NodeFlags {
  NodeFlags::from_bits(262144U)
}

///|
pub fn NodeFlags::javascript_file() -> NodeFlags {
  NodeFlags::from_bits(524288U)
}

///|
pub fn NodeFlags::this_node_or_any_sub_nodes_has_error() -> NodeFlags {
  NodeFlags::from_bits(1048576U)
}

///|
pub fn NodeFlags::has_aggregated_child_data() -> NodeFlags {
  NodeFlags::from_bits(2097152U)
}

///|
pub fn NodeFlags::possibly_contains_dynamic_import() -> NodeFlags {
  NodeFlags::from_bits(4194304U)
}

///|
pub fn NodeFlags::possibly_contains_import_meta() -> NodeFlags {
  NodeFlags::from_bits(8388608U)
}

///|
pub fn NodeFlags::jsdoc() -> NodeFlags {
  NodeFlags::from_bits(16777216U)
}

///|
pub fn NodeFlags::ambient() -> NodeFlags {
  NodeFlags::from_bits(33554432U)
}

///|
pub fn NodeFlags::in_with_statement() -> NodeFlags {
  NodeFlags::from_bits(67108864U)
}

///|
pub fn NodeFlags::json_file() -> NodeFlags {
  NodeFlags::from_bits(134217728U)
}

///|
pub fn NodeFlags::type_cached() -> NodeFlags {
  NodeFlags::from_bits(268435456U)
}

///|
pub fn NodeFlags::deprecated() -> NodeFlags {
  NodeFlags::from_bits(536870912U)
}

///|
pub fn NodeFlags::unreachable_flag() -> NodeFlags {
  NodeFlags::from_bits(1073741824U)
}

///|
pub fn NodeFlags::block_scoped() -> NodeFlags {
  NodeFlags::from_bits(7U)
}

///|
pub fn NodeFlags::constant() -> NodeFlags {
  NodeFlags::from_bits(6U)
}

///|
pub fn NodeFlags::reachability_check_flags() -> NodeFlags {
  NodeFlags::from_bits(1536U)
}

///|
pub fn NodeFlags::reachability_and_emit_flags() -> NodeFlags {
  NodeFlags::from_bits(5632U)
}

///|
pub fn NodeFlags::context_flags() -> NodeFlags {
  NodeFlags::from_bits(101441536U)
}

///|
pub fn NodeFlags::type_excludes_flags() -> NodeFlags {
  NodeFlags::from_bits(81920U)
}

///|
pub fn NodeFlags::permanently_set_incremental_flags() -> NodeFlags {
  NodeFlags::from_bits(12582912U)
}

///|
pub fn NodeFlags::identifier_has_extended_unicode_escape() -> NodeFlags {
  NodeFlags::from_bits(256U)
}

///|
pub fn NodeFlags::identifier_is_in_jsdoc_namespace() -> NodeFlags {
  NodeFlags::from_bits(4096U)
}
