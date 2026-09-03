// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts and src/compiler/parser.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// One captured argument of a leading-comment pragma. `pos` and `end` are
/// present only for arguments whose TypeScript pragma declaration requests a
/// UTF-16 capture span.
pub struct PragmaArgument {
  name : String
  value : String
  pos : Int?
  end : Int?
} derive(Eq, Debug)

///|
pub fn PragmaArgument::name(self : PragmaArgument) -> String {
  self.name
}

///|
pub fn PragmaArgument::value(self : PragmaArgument) -> String {
  self.value
}

///|
pub fn PragmaArgument::pos(self : PragmaArgument) -> Int? {
  self.pos
}

///|
pub fn PragmaArgument::end(self : PragmaArgument) -> Int? {
  self.end
}

///|
/// One occurrence stored under a SourceFile pragma-map key.
pub struct PragmaOccurrence {
  arguments : ReadOnlyArray[PragmaArgument]
  range : CommentRange
} derive(Eq, Debug)

///|
pub fn PragmaOccurrence::arguments(
  self : PragmaOccurrence,
) -> ReadOnlyArray[PragmaArgument] {
  self.arguments
}

///|
pub fn PragmaOccurrence::range(self : PragmaOccurrence) -> CommentRange {
  self.range
}

///|
/// A SourceFile pragma-map entry. Entry order is first occurrence order and
/// occurrence order is source order, matching JavaScript `Map` plus arrays.
pub struct PragmaEntry {
  name : String
  occurrences : ReadOnlyArray[PragmaOccurrence]
} derive(Eq, Debug)

///|
pub fn PragmaEntry::name(self : PragmaEntry) -> String {
  self.name
}

///|
pub fn PragmaEntry::occurrences(
  self : PragmaEntry,
) -> ReadOnlyArray[PragmaOccurrence] {
  self.occurrences
}

///|
/// A path, types, or lib triple-slash reference.
pub struct FileReference {
  file_name : String
  pos : Int
  end : Int
  resolution_mode : ResolutionMode?
  preserve : Bool?
} derive(Eq, Debug)

///|
pub fn FileReference::file_name(self : FileReference) -> String {
  self.file_name
}

///|
pub fn FileReference::pos(self : FileReference) -> Int {
  self.pos
}

///|
pub fn FileReference::end(self : FileReference) -> Int {
  self.end
}

///|
pub fn FileReference::resolution_mode(self : FileReference) -> ResolutionMode? {
  self.resolution_mode
}

///|
pub fn FileReference::preserve(self : FileReference) -> Bool? {
  self.preserve
}

///|
/// One `amd-dependency` pragma after field processing.
pub struct AmdDependency {
  name : String?
  path : String
} derive(Eq, Debug)

///|
pub fn AmdDependency::name(self : AmdDependency) -> String? {
  self.name
}

///|
pub fn AmdDependency::path(self : AmdDependency) -> String {
  self.path
}

///|
/// The latest leading `ts-check` or `ts-nocheck` directive.
pub struct CheckJsDirective {
  enabled : Bool
  pos : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn CheckJsDirective::enabled(self : CheckJsDirective) -> Bool {
  self.enabled
}

///|
pub fn CheckJsDirective::pos(self : CheckJsDirective) -> Int {
  self.pos
}

///|
pub fn CheckJsDirective::end(self : CheckJsDirective) -> Int {
  self.end
}
