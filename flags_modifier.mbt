// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
pub fn ModifierFlags::none() -> ModifierFlags {
  ModifierFlags::from_bits(0U)
}

///|
pub fn ModifierFlags::public_flag() -> ModifierFlags {
  ModifierFlags::from_bits(1U)
}

///|
pub fn ModifierFlags::private_flag() -> ModifierFlags {
  ModifierFlags::from_bits(2U)
}

///|
pub fn ModifierFlags::protected_flag() -> ModifierFlags {
  ModifierFlags::from_bits(4U)
}

///|
pub fn ModifierFlags::readonly_flag() -> ModifierFlags {
  ModifierFlags::from_bits(8U)
}

///|
pub fn ModifierFlags::override_flag() -> ModifierFlags {
  ModifierFlags::from_bits(16U)
}

///|
pub fn ModifierFlags::export_flag() -> ModifierFlags {
  ModifierFlags::from_bits(32U)
}

///|
pub fn ModifierFlags::abstract_flag() -> ModifierFlags {
  ModifierFlags::from_bits(64U)
}

///|
pub fn ModifierFlags::ambient() -> ModifierFlags {
  ModifierFlags::from_bits(128U)
}

///|
pub fn ModifierFlags::static_flag() -> ModifierFlags {
  ModifierFlags::from_bits(256U)
}

///|
pub fn ModifierFlags::accessor() -> ModifierFlags {
  ModifierFlags::from_bits(512U)
}

///|
pub fn ModifierFlags::async_flag() -> ModifierFlags {
  ModifierFlags::from_bits(1024U)
}

///|
pub fn ModifierFlags::default_flag() -> ModifierFlags {
  ModifierFlags::from_bits(2048U)
}

///|
pub fn ModifierFlags::const_flag() -> ModifierFlags {
  ModifierFlags::from_bits(4096U)
}

///|
pub fn ModifierFlags::in_flag() -> ModifierFlags {
  ModifierFlags::from_bits(8192U)
}

///|
pub fn ModifierFlags::out_flag() -> ModifierFlags {
  ModifierFlags::from_bits(16384U)
}

///|
pub fn ModifierFlags::decorator() -> ModifierFlags {
  ModifierFlags::from_bits(32768U)
}

///|
pub fn ModifierFlags::deprecated() -> ModifierFlags {
  ModifierFlags::from_bits(65536U)
}

///|
pub fn ModifierFlags::jsdoc_public() -> ModifierFlags {
  ModifierFlags::from_bits(8388608U)
}

///|
pub fn ModifierFlags::jsdoc_private() -> ModifierFlags {
  ModifierFlags::from_bits(16777216U)
}

///|
pub fn ModifierFlags::jsdoc_protected() -> ModifierFlags {
  ModifierFlags::from_bits(33554432U)
}

///|
pub fn ModifierFlags::jsdoc_readonly() -> ModifierFlags {
  ModifierFlags::from_bits(67108864U)
}

///|
pub fn ModifierFlags::jsdoc_override() -> ModifierFlags {
  ModifierFlags::from_bits(134217728U)
}

///|
pub fn ModifierFlags::syntactic_or_jsdoc_modifiers() -> ModifierFlags {
  ModifierFlags::from_bits(31U)
}

///|
pub fn ModifierFlags::syntactic_only_modifiers() -> ModifierFlags {
  ModifierFlags::from_bits(65504U)
}

///|
pub fn ModifierFlags::syntactic_modifiers() -> ModifierFlags {
  ModifierFlags::from_bits(65535U)
}

///|
pub fn ModifierFlags::jsdoc_cache_only_modifiers() -> ModifierFlags {
  ModifierFlags::from_bits(260046848U)
}

///|
pub fn ModifierFlags::jsdoc_only_modifiers() -> ModifierFlags {
  ModifierFlags::from_bits(65536U)
}

///|
pub fn ModifierFlags::non_cache_only_modifiers() -> ModifierFlags {
  ModifierFlags::from_bits(131071U)
}

///|
pub fn ModifierFlags::has_computed_jsdoc_modifiers() -> ModifierFlags {
  ModifierFlags::from_bits(268435456U)
}

///|
pub fn ModifierFlags::has_computed_flags() -> ModifierFlags {
  ModifierFlags::from_bits(536870912U)
}

///|
pub fn ModifierFlags::accessibility_modifier() -> ModifierFlags {
  ModifierFlags::from_bits(7U)
}

///|
pub fn ModifierFlags::parameter_property_modifier() -> ModifierFlags {
  ModifierFlags::from_bits(31U)
}

///|
pub fn ModifierFlags::non_public_accessibility_modifier() -> ModifierFlags {
  ModifierFlags::from_bits(6U)
}

///|
pub fn ModifierFlags::typescript_modifier() -> ModifierFlags {
  ModifierFlags::from_bits(28895U)
}

///|
pub fn ModifierFlags::export_default() -> ModifierFlags {
  ModifierFlags::from_bits(2080U)
}

///|
pub fn ModifierFlags::all() -> ModifierFlags {
  ModifierFlags::from_bits(131071U)
}

///|
pub fn ModifierFlags::modifier() -> ModifierFlags {
  ModifierFlags::from_bits(98303U)
}
