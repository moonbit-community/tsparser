// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// A numeric TypeScript `SyntaxKind` value.
///
/// This wrapper deliberately does not rely on MoonBit enum ordinals: aliases
/// such as `FirstLiteralToken` must compare equal to their declared node kind.
pub struct SyntaxKind(Int) derive(Eq, Compare, Debug)

///|
/// Converts a numeric TypeScript kind into its checked wrapper.
pub fn SyntaxKind::from_int(value : Int) -> SyntaxKind? {
  if value >= 0 && value < 359 {
    Some(SyntaxKind(value))
  } else {
    None
  }
}

///|
/// Returns the exact TypeScript numeric kind.
pub fn SyntaxKind::to_int(self : SyntaxKind) -> Int {
  let SyntaxKind(value) = self
  value
}

///|
/// Returns the upstream `SyntaxKind.Count` sentinel. It is not itself a valid
/// node or token kind and is therefore rejected by `from_int`.
pub fn SyntaxKind::count() -> Int {
  359
}
