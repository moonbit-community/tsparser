// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// Returns TypeScript's `First*` and `Last*` classification aliases without
/// conflating them with declaration names or runtime reverse-enum names.
pub fn SyntaxKind::classification_markers(
  self : SyntaxKind,
) -> ReadOnlyArray[String] {
  let names : Array[String] = match self.to_int() {
    0 => ["FirstToken"]
    2 => ["FirstTriviaToken"]
    7 => ["LastTriviaToken"]
    9 => ["FirstLiteralToken"]
    15 => ["LastLiteralToken", "FirstTemplateToken"]
    18 => ["LastTemplateToken"]
    19 => ["FirstPunctuation"]
    30 => ["FirstBinaryOperator"]
    64 => ["FirstAssignment"]
    65 => ["FirstCompoundAssignment"]
    79 =>
      [
        "LastAssignment", "LastCompoundAssignment", "LastPunctuation", "LastBinaryOperator",
      ]
    83 => ["FirstReservedWord", "FirstKeyword"]
    118 => ["LastReservedWord"]
    119 => ["FirstFutureReservedWord"]
    127 => ["LastFutureReservedWord"]
    128 => ["FirstContextualKeyword"]
    166 => ["LastKeyword", "LastToken", "LastContextualKeyword"]
    167 => ["FirstNode"]
    183 => ["FirstTypeNode"]
    206 => ["LastTypeNode"]
    244 => ["FirstStatement"]
    260 => ["LastStatement"]
    310 => ["FirstJSDocNode"]
    328 => ["FirstJSDocTagNode"]
    352 => ["LastJSDocNode", "LastJSDocTagNode"]
    _ => []
  }
  ReadOnlyArray::from_array(names)
}
