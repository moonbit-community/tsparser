// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts and src/compiler/types.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// Exact TypeScript keyword lookup. Escaped spellings are intentionally absent;
/// the scanner classifies those after escape processing.
fn _string_to_keyword(text : String) -> SyntaxKind? {
  let value = match text {
    "break" => 83
    "case" => 84
    "catch" => 85
    "class" => 86
    "const" => 87
    "continue" => 88
    "debugger" => 89
    "default" => 90
    "delete" => 91
    "do" => 92
    "else" => 93
    "enum" => 94
    "export" => 95
    "extends" => 96
    "false" => 97
    "finally" => 98
    "for" => 99
    "function" => 100
    "if" => 101
    "import" => 102
    "in" => 103
    "instanceof" => 104
    "new" => 105
    "null" => 106
    "return" => 107
    "super" => 108
    "switch" => 109
    "this" => 110
    "throw" => 111
    "true" => 112
    "try" => 113
    "typeof" => 114
    "var" => 115
    "void" => 116
    "while" => 117
    "with" => 118
    "implements" => 119
    "interface" => 120
    "let" => 121
    "package" => 122
    "private" => 123
    "protected" => 124
    "public" => 125
    "static" => 126
    "yield" => 127
    "abstract" => 128
    "accessor" => 129
    "as" => 130
    "asserts" => 131
    "assert" => 132
    "any" => 133
    "async" => 134
    "await" => 135
    "boolean" => 136
    "constructor" => 137
    "declare" => 138
    "get" => 139
    "infer" => 140
    "intrinsic" => 141
    "is" => 142
    "keyof" => 143
    "module" => 144
    "namespace" => 145
    "never" => 146
    "out" => 147
    "readonly" => 148
    "require" => 149
    "number" => 150
    "object" => 151
    "satisfies" => 152
    "set" => 153
    "string" => 154
    "symbol" => 155
    "type" => 156
    "undefined" => 157
    "unique" => 158
    "unknown" => 159
    "using" => 160
    "from" => 161
    "global" => 162
    "bigint" => 163
    "override" => 164
    "of" => 165
    "defer" => 166
    _ => -1
  }
  if value < 0 {
    None
  } else {
    Some(SyntaxKind(value))
  }
}

///|
fn _string_to_token(text : String) -> SyntaxKind? {
  match _string_to_keyword(text) {
    Some(keyword) => Some(keyword)
    None => {
      let value = match text {
        "{" => 19
        "}" => 20
        "(" => 21
        ")" => 22
        "[" => 23
        "]" => 24
        "." => 25
        "..." => 26
        ";" => 27
        "," => 28
        "?." => 29
        "<" => 30
        "</" => 31
        ">" => 32
        "<=" => 33
        ">=" => 34
        "==" => 35
        "!=" => 36
        "===" => 37
        "!==" => 38
        "=>" => 39
        "+" => 40
        "-" => 41
        "*" => 42
        "**" => 43
        "/" => 44
        "%" => 45
        "++" => 46
        "--" => 47
        "<<" => 48
        ">>" => 49
        ">>>" => 50
        "&" => 51
        "|" => 52
        "^" => 53
        "!" => 54
        "~" => 55
        "&&" => 56
        "||" => 57
        "?" => 58
        ":" => 59
        "@" => 60
        "??" => 61
        "`" => 62
        "#" => 63
        "=" => 64
        "+=" => 65
        "-=" => 66
        "*=" => 67
        "**=" => 68
        "/=" => 69
        "%=" => 70
        "<<=" => 71
        ">>=" => 72
        ">>>=" => 73
        "&=" => 74
        "|=" => 75
        "||=" => 76
        "&&=" => 77
        "??=" => 78
        "^=" => 79
        _ => -1
      }
      if value < 0 {
        None
      } else {
        Some(SyntaxKind(value))
      }
    }
  }
}

///|
fn _token_to_string(kind : SyntaxKind) -> String? {
  let text = match kind.to_int() {
    19 => "{"
    20 => "}"
    21 => "("
    22 => ")"
    23 => "["
    24 => "]"
    25 => "."
    26 => "..."
    27 => ";"
    28 => ","
    29 => "?."
    30 => "<"
    31 => "</"
    32 => ">"
    33 => "<="
    34 => ">="
    35 => "=="
    36 => "!="
    37 => "==="
    38 => "!=="
    39 => "=>"
    40 => "+"
    41 => "-"
    42 => "*"
    43 => "**"
    44 => "/"
    45 => "%"
    46 => "++"
    47 => "--"
    48 => "<<"
    49 => ">>"
    50 => ">>>"
    51 => "&"
    52 => "|"
    53 => "^"
    54 => "!"
    55 => "~"
    56 => "&&"
    57 => "||"
    58 => "?"
    59 => ":"
    60 => "@"
    61 => "??"
    62 => "`"
    63 => "#"
    64 => "="
    65 => "+="
    66 => "-="
    67 => "*="
    68 => "**="
    69 => "/="
    70 => "%="
    71 => "<<="
    72 => ">>="
    73 => ">>>="
    74 => "&="
    75 => "|="
    76 => "||="
    77 => "&&="
    78 => "??="
    79 => "^="
    83 => "break"
    84 => "case"
    85 => "catch"
    86 => "class"
    87 => "const"
    88 => "continue"
    89 => "debugger"
    90 => "default"
    91 => "delete"
    92 => "do"
    93 => "else"
    94 => "enum"
    95 => "export"
    96 => "extends"
    97 => "false"
    98 => "finally"
    99 => "for"
    100 => "function"
    101 => "if"
    102 => "import"
    103 => "in"
    104 => "instanceof"
    105 => "new"
    106 => "null"
    107 => "return"
    108 => "super"
    109 => "switch"
    110 => "this"
    111 => "throw"
    112 => "true"
    113 => "try"
    114 => "typeof"
    115 => "var"
    116 => "void"
    117 => "while"
    118 => "with"
    119 => "implements"
    120 => "interface"
    121 => "let"
    122 => "package"
    123 => "private"
    124 => "protected"
    125 => "public"
    126 => "static"
    127 => "yield"
    128 => "abstract"
    129 => "accessor"
    130 => "as"
    131 => "asserts"
    132 => "assert"
    133 => "any"
    134 => "async"
    135 => "await"
    136 => "boolean"
    137 => "constructor"
    138 => "declare"
    139 => "get"
    140 => "infer"
    141 => "intrinsic"
    142 => "is"
    143 => "keyof"
    144 => "module"
    145 => "namespace"
    146 => "never"
    147 => "out"
    148 => "readonly"
    149 => "require"
    150 => "number"
    151 => "object"
    152 => "satisfies"
    153 => "set"
    154 => "string"
    155 => "symbol"
    156 => "type"
    157 => "undefined"
    158 => "unique"
    159 => "unknown"
    160 => "using"
    161 => "from"
    162 => "global"
    163 => "bigint"
    164 => "override"
    165 => "of"
    166 => "defer"
    _ => ""
  }
  if text == "" {
    None
  } else {
    Some(text)
  }
}

///|
fn _character_code_to_regular_expression_flag(
  code : Int,
) -> RegularExpressionFlags? {
  match code {
    0x64 => Some(RegularExpressionFlags::has_indices())
    0x67 => Some(RegularExpressionFlags::global())
    0x69 => Some(RegularExpressionFlags::ignore_case())
    0x6d => Some(RegularExpressionFlags::multiline())
    0x73 => Some(RegularExpressionFlags::dot_all())
    0x75 => Some(RegularExpressionFlags::unicode())
    0x76 => Some(RegularExpressionFlags::unicode_sets())
    0x79 => Some(RegularExpressionFlags::sticky())
    _ => None
  }
}

///|
fn _regular_expression_flag_to_character_code(
  flag : RegularExpressionFlags,
) -> Int? {
  match flag.bits() {
    1U => Some(0x64)
    2U => Some(0x67)
    4U => Some(0x69)
    8U => Some(0x6d)
    16U => Some(0x73)
    32U => Some(0x75)
    64U => Some(0x76)
    128U => Some(0x79)
    _ => None
  }
}

///|
priv enum LanguageFeature {
  Classes
  ForOf
  Generators
  Iteration
  SpreadElements
  RestElements
  TaggedTemplates
  DestructuringAssignment
  BindingPatterns
  ArrowFunctions
  BlockScopedVariables
  ObjectAssign
  RegularExpressionFlagsUnicode
  RegularExpressionFlagsSticky
  Exponentiation
  AsyncFunctions
  ForAwaitOf
  AsyncGenerators
  AsyncIteration
  ObjectSpreadRest
  RegularExpressionFlagsDotAll
  BindinglessCatch
  BigInt
  NullishCoalesce
  OptionalChaining
  LogicalAssignment
  TopLevelAwait
  ClassFields
  PrivateNamesAndClassStaticBlocks
  RegularExpressionFlagsHasIndices
  ShebangComments
  RegularExpressionFlagsUnicodeSets
  UsingAndAwaitUsing
  ClassAndClassElementDecorators
}

///|
fn LanguageFeature::minimum_target(self : LanguageFeature) -> ScriptTarget {
  match self {
    Classes
    | ForOf
    | Generators
    | Iteration
    | SpreadElements
    | RestElements
    | TaggedTemplates
    | DestructuringAssignment
    | BindingPatterns
    | ArrowFunctions
    | BlockScopedVariables
    | ObjectAssign
    | RegularExpressionFlagsUnicode
    | RegularExpressionFlagsSticky => ScriptTarget::es2015()
    Exponentiation => ScriptTarget::es2016()
    AsyncFunctions => ScriptTarget::es2017()
    ForAwaitOf
    | AsyncGenerators
    | AsyncIteration
    | ObjectSpreadRest
    | RegularExpressionFlagsDotAll => ScriptTarget::es2018()
    BindinglessCatch => ScriptTarget::es2019()
    BigInt | NullishCoalesce | OptionalChaining => ScriptTarget::es2020()
    LogicalAssignment => ScriptTarget::es2021()
    TopLevelAwait
    | ClassFields
    | PrivateNamesAndClassStaticBlocks
    | RegularExpressionFlagsHasIndices => ScriptTarget::es2022()
    ShebangComments => ScriptTarget::es2023()
    RegularExpressionFlagsUnicodeSets => ScriptTarget::es2024()
    UsingAndAwaitUsing | ClassAndClassElementDecorators =>
      ScriptTarget::es_next()
  }
}

///|
fn _regular_expression_flag_minimum_target(
  flag : RegularExpressionFlags,
) -> ScriptTarget? {
  match flag.bits() {
    1U =>
      Some(LanguageFeature::RegularExpressionFlagsHasIndices.minimum_target())
    16U => Some(LanguageFeature::RegularExpressionFlagsDotAll.minimum_target())
    32U => Some(LanguageFeature::RegularExpressionFlagsUnicode.minimum_target())
    64U =>
      Some(LanguageFeature::RegularExpressionFlagsUnicodeSets.minimum_target())
    128U => Some(LanguageFeature::RegularExpressionFlagsSticky.minimum_target())
    _ => None
  }
}

///|
/// Keeps private lookup-table members lint-clean while preserving the scanner
/// table contract.
#warnings("-unused_value")
fn _scanner_table_contract_values() -> Unit {
  ignore(_string_to_token("break"))
  ignore(_token_to_string(SyntaxKind(19)))
  ignore(_character_code_to_regular_expression_flag(0x64))
  ignore(
    _regular_expression_flag_to_character_code(
      RegularExpressionFlags::has_indices(),
    ),
  )
  ignore(
    _regular_expression_flag_minimum_target(
      RegularExpressionFlags::has_indices(),
    ),
  )
  let features = [
    LanguageFeature::Classes,
    LanguageFeature::ForOf,
    LanguageFeature::Generators,
    LanguageFeature::Iteration,
    LanguageFeature::SpreadElements,
    LanguageFeature::RestElements,
    LanguageFeature::TaggedTemplates,
    LanguageFeature::DestructuringAssignment,
    LanguageFeature::BindingPatterns,
    LanguageFeature::ArrowFunctions,
    LanguageFeature::BlockScopedVariables,
    LanguageFeature::ObjectAssign,
    LanguageFeature::RegularExpressionFlagsUnicode,
    LanguageFeature::RegularExpressionFlagsSticky,
    LanguageFeature::Exponentiation,
    LanguageFeature::AsyncFunctions,
    LanguageFeature::ForAwaitOf,
    LanguageFeature::AsyncGenerators,
    LanguageFeature::AsyncIteration,
    LanguageFeature::ObjectSpreadRest,
    LanguageFeature::RegularExpressionFlagsDotAll,
    LanguageFeature::BindinglessCatch,
    LanguageFeature::BigInt,
    LanguageFeature::NullishCoalesce,
    LanguageFeature::OptionalChaining,
    LanguageFeature::LogicalAssignment,
    LanguageFeature::TopLevelAwait,
    LanguageFeature::ClassFields,
    LanguageFeature::PrivateNamesAndClassStaticBlocks,
    LanguageFeature::RegularExpressionFlagsHasIndices,
    LanguageFeature::ShebangComments,
    LanguageFeature::RegularExpressionFlagsUnicodeSets,
    LanguageFeature::UsingAndAwaitUsing,
    LanguageFeature::ClassAndClassElementDecorators,
  ]
  for feature in features {
    ignore(feature.minimum_target())
  }
}
