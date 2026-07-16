// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
pub fn TokenFlags::none() -> TokenFlags {
  TokenFlags::from_bits(0U)
}

///|
pub fn TokenFlags::preceding_line_break() -> TokenFlags {
  TokenFlags::from_bits(1U)
}

///|
pub fn TokenFlags::preceding_jsdoc_comment() -> TokenFlags {
  TokenFlags::from_bits(2U)
}

///|
pub fn TokenFlags::unterminated() -> TokenFlags {
  TokenFlags::from_bits(4U)
}

///|
pub fn TokenFlags::extended_unicode_escape() -> TokenFlags {
  TokenFlags::from_bits(8U)
}

///|
pub fn TokenFlags::scientific() -> TokenFlags {
  TokenFlags::from_bits(16U)
}

///|
pub fn TokenFlags::octal() -> TokenFlags {
  TokenFlags::from_bits(32U)
}

///|
pub fn TokenFlags::hex_specifier() -> TokenFlags {
  TokenFlags::from_bits(64U)
}

///|
pub fn TokenFlags::binary_specifier() -> TokenFlags {
  TokenFlags::from_bits(128U)
}

///|
pub fn TokenFlags::octal_specifier() -> TokenFlags {
  TokenFlags::from_bits(256U)
}

///|
pub fn TokenFlags::contains_separator() -> TokenFlags {
  TokenFlags::from_bits(512U)
}

///|
pub fn TokenFlags::unicode_escape() -> TokenFlags {
  TokenFlags::from_bits(1024U)
}

///|
pub fn TokenFlags::contains_invalid_escape() -> TokenFlags {
  TokenFlags::from_bits(2048U)
}

///|
pub fn TokenFlags::hex_escape() -> TokenFlags {
  TokenFlags::from_bits(4096U)
}

///|
pub fn TokenFlags::contains_leading_zero() -> TokenFlags {
  TokenFlags::from_bits(8192U)
}

///|
pub fn TokenFlags::contains_invalid_separator() -> TokenFlags {
  TokenFlags::from_bits(16384U)
}

///|
pub fn TokenFlags::preceding_jsdoc_leading_asterisks() -> TokenFlags {
  TokenFlags::from_bits(32768U)
}

///|
pub fn TokenFlags::binary_or_octal_specifier() -> TokenFlags {
  TokenFlags::from_bits(384U)
}

///|
pub fn TokenFlags::with_specifier() -> TokenFlags {
  TokenFlags::from_bits(448U)
}

///|
pub fn TokenFlags::string_literal_flags() -> TokenFlags {
  TokenFlags::from_bits(7176U)
}

///|
pub fn TokenFlags::numeric_literal_flags() -> TokenFlags {
  TokenFlags::from_bits(25584U)
}

///|
pub fn TokenFlags::template_literal_like_flags() -> TokenFlags {
  TokenFlags::from_bits(7176U)
}

///|
pub fn TokenFlags::is_invalid() -> TokenFlags {
  TokenFlags::from_bits(26656U)
}
