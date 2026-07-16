// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// Parser-owned node flags represented as an exact unsigned 32-bit bitset.
pub struct NodeFlags(UInt) derive(Eq, Debug)

///|
pub fn NodeFlags::from_bits(bits : UInt) -> NodeFlags {
  NodeFlags(bits)
}

///|
pub fn NodeFlags::bits(self : NodeFlags) -> UInt {
  let NodeFlags(bits) = self
  bits
}

///|
pub fn NodeFlags::none() -> NodeFlags {
  NodeFlags(0U)
}

///|
pub fn NodeFlags::union(self : NodeFlags, other : NodeFlags) -> NodeFlags {
  NodeFlags(self.bits().lor(other.bits()))
}

///|
pub fn NodeFlags::contains(self : NodeFlags, other : NodeFlags) -> Bool {
  self.bits().land(other.bits()) == other.bits()
}

///|
pub fn NodeFlags::intersect(self : NodeFlags, other : NodeFlags) -> NodeFlags {
  NodeFlags(self.bits().land(other.bits()))
}

///|
pub fn NodeFlags::without(self : NodeFlags, other : NodeFlags) -> NodeFlags {
  NodeFlags(self.bits().land(other.bits().lnot()))
}

///|
/// Parser-owned transform flags represented as an exact unsigned 32-bit bitset.
pub struct TransformFlags(UInt) derive(Eq, Debug)

///|
pub fn TransformFlags::from_bits(bits : UInt) -> TransformFlags {
  TransformFlags(bits)
}

///|
pub fn TransformFlags::bits(self : TransformFlags) -> UInt {
  let TransformFlags(bits) = self
  bits
}

///|
pub fn TransformFlags::none() -> TransformFlags {
  TransformFlags(0U)
}

///|
pub fn TransformFlags::has_computed_flags() -> TransformFlags {
  TransformFlags(0x80000000U)
}

///|
pub fn TransformFlags::union(
  self : TransformFlags,
  other : TransformFlags,
) -> TransformFlags {
  TransformFlags(self.bits().lor(other.bits()))
}

///|
pub fn TransformFlags::contains(
  self : TransformFlags,
  other : TransformFlags,
) -> Bool {
  self.bits().land(other.bits()) == other.bits()
}

///|
pub fn TransformFlags::intersect(
  self : TransformFlags,
  other : TransformFlags,
) -> TransformFlags {
  TransformFlags(self.bits().land(other.bits()))
}

///|
pub fn TransformFlags::without(
  self : TransformFlags,
  other : TransformFlags,
) -> TransformFlags {
  TransformFlags(self.bits().land(other.bits().lnot()))
}

///|
/// Scanner token flags represented as an exact unsigned 32-bit bitset.
pub struct TokenFlags(UInt) derive(Eq, Debug)

///|
pub fn TokenFlags::from_bits(bits : UInt) -> TokenFlags {
  TokenFlags(bits)
}

///|
pub fn TokenFlags::bits(self : TokenFlags) -> UInt {
  let TokenFlags(bits) = self
  bits
}

///|
pub fn TokenFlags::contains(self : TokenFlags, other : TokenFlags) -> Bool {
  self.bits().land(other.bits()) == other.bits()
}

///|
pub fn TokenFlags::union(self : TokenFlags, other : TokenFlags) -> TokenFlags {
  TokenFlags(self.bits().lor(other.bits()))
}

///|
pub fn TokenFlags::intersect(
  self : TokenFlags,
  other : TokenFlags,
) -> TokenFlags {
  TokenFlags(self.bits().land(other.bits()))
}

///|
pub fn TokenFlags::without(self : TokenFlags, other : TokenFlags) -> TokenFlags {
  TokenFlags(self.bits().land(other.bits().lnot()))
}

///|
/// Parser-visible modifier flags represented as an unsigned bitset.
pub struct ModifierFlags(UInt) derive(Eq, Debug)

///|
pub fn ModifierFlags::from_bits(bits : UInt) -> ModifierFlags {
  ModifierFlags(bits)
}

///|
pub fn ModifierFlags::bits(self : ModifierFlags) -> UInt {
  let ModifierFlags(bits) = self
  bits
}

///|
pub fn ModifierFlags::contains(
  self : ModifierFlags,
  other : ModifierFlags,
) -> Bool {
  self.bits().land(other.bits()) == other.bits()
}

///|
pub fn ModifierFlags::union(
  self : ModifierFlags,
  other : ModifierFlags,
) -> ModifierFlags {
  ModifierFlags(self.bits().lor(other.bits()))
}

///|
pub fn ModifierFlags::intersect(
  self : ModifierFlags,
  other : ModifierFlags,
) -> ModifierFlags {
  ModifierFlags(self.bits().land(other.bits()))
}

///|
pub struct PragmaKindFlags(UInt) derive(Eq, Debug)

///|
pub fn PragmaKindFlags::from_bits(bits : UInt) -> PragmaKindFlags {
  PragmaKindFlags(bits)
}

///|
pub fn PragmaKindFlags::bits(self : PragmaKindFlags) -> UInt {
  let PragmaKindFlags(bits) = self
  bits
}

///|
pub fn PragmaKindFlags::contains(
  self : PragmaKindFlags,
  other : PragmaKindFlags,
) -> Bool {
  self.bits().land(other.bits()) == other.bits()
}

///|
pub struct RegularExpressionFlags(UInt) derive(Eq, Debug)

///|
pub fn RegularExpressionFlags::from_bits(bits : UInt) -> RegularExpressionFlags {
  RegularExpressionFlags(bits)
}

///|
pub fn RegularExpressionFlags::bits(self : RegularExpressionFlags) -> UInt {
  let RegularExpressionFlags(bits) = self
  bits
}

///|
pub fn RegularExpressionFlags::contains(
  self : RegularExpressionFlags,
  other : RegularExpressionFlags,
) -> Bool {
  self.bits().land(other.bits()) == other.bits()
}

///|
pub fn RegularExpressionFlags::union(
  self : RegularExpressionFlags,
  other : RegularExpressionFlags,
) -> RegularExpressionFlags {
  RegularExpressionFlags(self.bits().lor(other.bits()))
}
