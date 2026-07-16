// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
pub fn PragmaKindFlags::none() -> PragmaKindFlags {
  PragmaKindFlags::from_bits(0U)
}

///|
pub fn PragmaKindFlags::triple_slash_xml() -> PragmaKindFlags {
  PragmaKindFlags::from_bits(1U)
}

///|
pub fn PragmaKindFlags::single_line() -> PragmaKindFlags {
  PragmaKindFlags::from_bits(2U)
}

///|
pub fn PragmaKindFlags::multi_line() -> PragmaKindFlags {
  PragmaKindFlags::from_bits(4U)
}

///|
pub fn PragmaKindFlags::all() -> PragmaKindFlags {
  PragmaKindFlags::from_bits(7U)
}

///|
pub fn PragmaKindFlags::default_flags() -> PragmaKindFlags {
  PragmaKindFlags::from_bits(7U)
}

///|
pub fn RegularExpressionFlags::none() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(0U)
}

///|
pub fn RegularExpressionFlags::has_indices() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(1U)
}

///|
pub fn RegularExpressionFlags::global() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(2U)
}

///|
pub fn RegularExpressionFlags::ignore_case() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(4U)
}

///|
pub fn RegularExpressionFlags::multiline() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(8U)
}

///|
pub fn RegularExpressionFlags::dot_all() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(16U)
}

///|
pub fn RegularExpressionFlags::unicode() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(32U)
}

///|
pub fn RegularExpressionFlags::unicode_sets() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(64U)
}

///|
pub fn RegularExpressionFlags::sticky() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(128U)
}

///|
pub fn RegularExpressionFlags::any_unicode_mode() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(96U)
}

///|
pub fn RegularExpressionFlags::modifiers() -> RegularExpressionFlags {
  RegularExpressionFlags::from_bits(28U)
}
