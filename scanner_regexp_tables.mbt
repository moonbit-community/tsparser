// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/scanner.ts and src/compiler/core.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

// ECMA-262 Tables 66-68 and the Unicode 15.1 property-value tables used by
// TypeScript's regular-expression grammar validator. Order is significant for
// spelling suggestions and therefore follows the upstream Set insertion order.

///|
let _regexp_non_binary_property_names : ReadOnlyArray[String] = [
  "General_Category", "gc", "Script", "sc", "Script_Extensions", "scx",
]

///|
fn _regexp_non_binary_property_kind(value : String) -> Int? {
  match value {
    "General_Category" | "gc" => Some(0)
    "Script" | "sc" => Some(1)
    "Script_Extensions" | "scx" => Some(2)
    _ => None
  }
}

///|
let _regexp_binary_properties : ReadOnlyArray[String] = [
  "ASCII", "ASCII_Hex_Digit", "AHex", "Alphabetic", "Alpha", "Any", "Assigned", "Bidi_Control",
  "Bidi_C", "Bidi_Mirrored", "Bidi_M", "Case_Ignorable", "CI", "Cased", "Changes_When_Casefolded",
  "CWCF", "Changes_When_Casemapped", "CWCM", "Changes_When_Lowercased", "CWL", "Changes_When_NFKC_Casefolded",
  "CWKCF", "Changes_When_Titlecased", "CWT", "Changes_When_Uppercased", "CWU", "Dash",
  "Default_Ignorable_Code_Point", "DI", "Deprecated", "Dep", "Diacritic", "Dia",
  "Emoji", "Emoji_Component", "EComp", "Emoji_Modifier", "EMod", "Emoji_Modifier_Base",
  "EBase", "Emoji_Presentation", "EPres", "Extended_Pictographic", "ExtPict", "Extender",
  "Ext", "Grapheme_Base", "Gr_Base", "Grapheme_Extend", "Gr_Ext", "Hex_Digit", "Hex",
  "IDS_Binary_Operator", "IDSB", "IDS_Trinary_Operator", "IDST", "ID_Continue", "IDC",
  "ID_Start", "IDS", "Ideographic", "Ideo", "Join_Control", "Join_C", "Logical_Order_Exception",
  "LOE", "Lowercase", "Lower", "Math", "Noncharacter_Code_Point", "NChar", "Pattern_Syntax",
  "Pat_Syn", "Pattern_White_Space", "Pat_WS", "Quotation_Mark", "QMark", "Radical",
  "Regional_Indicator", "RI", "Sentence_Terminal", "STerm", "Soft_Dotted", "SD",
  "Terminal_Punctuation", "Term", "Unified_Ideograph", "UIdeo", "Uppercase", "Upper",
  "Variation_Selector", "VS", "White_Space", "space", "XID_Continue", "XIDC", "XID_Start",
  "XIDS",
]

///|
let _regexp_binary_string_properties : ReadOnlyArray[String] = [
  "Basic_Emoji", "Emoji_Keycap_Sequence", "RGI_Emoji_Modifier_Sequence", "RGI_Emoji_Flag_Sequence",
  "RGI_Emoji_Tag_Sequence", "RGI_Emoji_ZWJ_Sequence", "RGI_Emoji",
]

///|
let _regexp_general_category_values : ReadOnlyArray[String] = [
  "C", "Other", "Cc", "Control", "cntrl", "Cf", "Format", "Cn", "Unassigned", "Co",
  "Private_Use", "Cs", "Surrogate", "L", "Letter", "LC", "Cased_Letter", "Ll", "Lowercase_Letter",
  "Lm", "Modifier_Letter", "Lo", "Other_Letter", "Lt", "Titlecase_Letter", "Lu",
  "Uppercase_Letter", "M", "Mark", "Combining_Mark", "Mc", "Spacing_Mark", "Me",
  "Enclosing_Mark", "Mn", "Nonspacing_Mark", "N", "Number", "Nd", "Decimal_Number",
  "digit", "Nl", "Letter_Number", "No", "Other_Number", "P", "Punctuation", "punct",
  "Pc", "Connector_Punctuation", "Pd", "Dash_Punctuation", "Pe", "Close_Punctuation",
  "Pf", "Final_Punctuation", "Pi", "Initial_Punctuation", "Po", "Other_Punctuation",
  "Ps", "Open_Punctuation", "S", "Symbol", "Sc", "Currency_Symbol", "Sk", "Modifier_Symbol",
  "Sm", "Math_Symbol", "So", "Other_Symbol", "Z", "Separator", "Zl", "Line_Separator",
  "Zp", "Paragraph_Separator", "Zs", "Space_Separator",
]

///|
let _regexp_script_values : ReadOnlyArray[String] = [
  "Adlm", "Adlam", "Aghb", "Caucasian_Albanian", "Ahom", "Arab", "Arabic", "Armi",
  "Imperial_Aramaic", "Armn", "Armenian", "Avst", "Avestan", "Bali", "Balinese",
  "Bamu", "Bamum", "Bass", "Bassa_Vah", "Batk", "Batak", "Beng", "Bengali", "Bhks",
  "Bhaiksuki", "Bopo", "Bopomofo", "Brah", "Brahmi", "Brai", "Braille", "Bugi", "Buginese",
  "Buhd", "Buhid", "Cakm", "Chakma", "Cans", "Canadian_Aboriginal", "Cari", "Carian",
  "Cham", "Cher", "Cherokee", "Chrs", "Chorasmian", "Copt", "Coptic", "Qaac", "Cpmn",
  "Cypro_Minoan", "Cprt", "Cypriot", "Cyrl", "Cyrillic", "Deva", "Devanagari", "Diak",
  "Dives_Akuru", "Dogr", "Dogra", "Dsrt", "Deseret", "Dupl", "Duployan", "Egyp",
  "Egyptian_Hieroglyphs", "Elba", "Elbasan", "Elym", "Elymaic", "Ethi", "Ethiopic",
  "Geor", "Georgian", "Glag", "Glagolitic", "Gong", "Gunjala_Gondi", "Gonm", "Masaram_Gondi",
  "Goth", "Gothic", "Gran", "Grantha", "Grek", "Greek", "Gujr", "Gujarati", "Guru",
  "Gurmukhi", "Hang", "Hangul", "Hani", "Han", "Hano", "Hanunoo", "Hatr", "Hatran",
  "Hebr", "Hebrew", "Hira", "Hiragana", "Hluw", "Anatolian_Hieroglyphs", "Hmng",
  "Pahawh_Hmong", "Hmnp", "Nyiakeng_Puachue_Hmong", "Hrkt", "Katakana_Or_Hiragana",
  "Hung", "Old_Hungarian", "Ital", "Old_Italic", "Java", "Javanese", "Kali", "Kayah_Li",
  "Kana", "Katakana", "Kawi", "Khar", "Kharoshthi", "Khmr", "Khmer", "Khoj", "Khojki",
  "Kits", "Khitan_Small_Script", "Knda", "Kannada", "Kthi", "Kaithi", "Lana", "Tai_Tham",
  "Laoo", "Lao", "Latn", "Latin", "Lepc", "Lepcha", "Limb", "Limbu", "Lina", "Linear_A",
  "Linb", "Linear_B", "Lisu", "Lyci", "Lycian", "Lydi", "Lydian", "Mahj", "Mahajani",
  "Maka", "Makasar", "Mand", "Mandaic", "Mani", "Manichaean", "Marc", "Marchen",
  "Medf", "Medefaidrin", "Mend", "Mende_Kikakui", "Merc", "Meroitic_Cursive", "Mero",
  "Meroitic_Hieroglyphs", "Mlym", "Malayalam", "Modi", "Mong", "Mongolian", "Mroo",
  "Mro", "Mtei", "Meetei_Mayek", "Mult", "Multani", "Mymr", "Myanmar", "Nagm", "Nag_Mundari",
  "Nand", "Nandinagari", "Narb", "Old_North_Arabian", "Nbat", "Nabataean", "Newa",
  "Nkoo", "Nko", "Nshu", "Nushu", "Ogam", "Ogham", "Olck", "Ol_Chiki", "Orkh", "Old_Turkic",
  "Orya", "Oriya", "Osge", "Osage", "Osma", "Osmanya", "Ougr", "Old_Uyghur", "Palm",
  "Palmyrene", "Pauc", "Pau_Cin_Hau", "Perm", "Old_Permic", "Phag", "Phags_Pa", "Phli",
  "Inscriptional_Pahlavi", "Phlp", "Psalter_Pahlavi", "Phnx", "Phoenician", "Plrd",
  "Miao", "Prti", "Inscriptional_Parthian", "Rjng", "Rejang", "Rohg", "Hanifi_Rohingya",
  "Runr", "Runic", "Samr", "Samaritan", "Sarb", "Old_South_Arabian", "Saur", "Saurashtra",
  "Sgnw", "SignWriting", "Shaw", "Shavian", "Shrd", "Sharada", "Sidd", "Siddham",
  "Sind", "Khudawadi", "Sinh", "Sinhala", "Sogd", "Sogdian", "Sogo", "Old_Sogdian",
  "Sora", "Sora_Sompeng", "Soyo", "Soyombo", "Sund", "Sundanese", "Sylo", "Syloti_Nagri",
  "Syrc", "Syriac", "Tagb", "Tagbanwa", "Takr", "Takri", "Tale", "Tai_Le", "Talu",
  "New_Tai_Lue", "Taml", "Tamil", "Tang", "Tangut", "Tavt", "Tai_Viet", "Telu", "Telugu",
  "Tfng", "Tifinagh", "Tglg", "Tagalog", "Thaa", "Thaana", "Thai", "Tibt", "Tibetan",
  "Tirh", "Tirhuta", "Tnsa", "Tangsa", "Toto", "Ugar", "Ugaritic", "Vaii", "Vai",
  "Vith", "Vithkuqi", "Wara", "Warang_Citi", "Wcho", "Wancho", "Xpeo", "Old_Persian",
  "Xsux", "Cuneiform", "Yezi", "Yezidi", "Yiii", "Yi", "Zanb", "Zanabazar_Square",
  "Zinh", "Inherited", "Qaai", "Zyyy", "Common", "Zzzz", "Unknown",
]

///|
fn _regexp_non_binary_property_values(kind : Int) -> ReadOnlyArray[String] {
  match kind {
    0 => _regexp_general_category_values
    1 | 2 => _regexp_script_values
    _ => abort("invalid regexp Unicode property kind")
  }
}

///|
fn _regexp_lone_property_candidates() -> ReadOnlyArray[String] {
  let values : Array[String] = []
  for value in _regexp_general_category_values {
    values.push(value)
  }
  for value in _regexp_binary_properties {
    values.push(value)
  }
  for value in _regexp_binary_string_properties {
    values.push(value)
  }
  ReadOnlyArray::from_array(values)
}

///|
fn _regexp_scaled_levenshtein(first : String, second : String) -> Int {
  let previous = Array::make(second.length() + 1, 0)
  let current = Array::make(second.length() + 1, 0)
  for index = 0; index <= second.length(); index = index + 1 {
    previous[index] = index * 10
  }
  for first_index = 1
      first_index <= first.length()
      first_index = first_index + 1 {
    current[0] = first_index * 10
    for second_index = 1
        second_index <= second.length()
        second_index = second_index + 1 {
      let first_code_unit = first[first_index - 1].to_int()
      let second_code_unit = second[second_index - 1].to_int()
      if first_code_unit == second_code_unit {
        current[second_index] = previous[second_index - 1]
      } else {
        let first_unit = first.unsafe_substring(
          start=first_index - 1,
          end=first_index,
        )
        let second_unit = second.unsafe_substring(
          start=second_index - 1,
          end=second_index,
        )
        let substitution = previous[second_index - 1] +
          (if first_unit.to_lower() == second_unit.to_lower() { 1 } else { 20 })
        current[second_index] = (previous[second_index] + 10)
          .min(current[second_index - 1] + 10)
          .min(substitution)
      }
    }
    for index = 0; index <= second.length(); index = index + 1 {
      previous[index] = current[index]
    }
  }
  previous[second.length()]
}

///|
fn _regexp_spelling_suggestion(
  name : String,
  candidates : ReadOnlyArray[String],
) -> String? {
  let maximum_length_difference = Int::max(2, name.length() * 34 / 100)
  let mut best_distance = (name.length() * 4 / 10 + 1) * 10
  let mut best_candidate : String? = None
  for candidate in candidates {
    if candidate != name &&
      Int::abs(candidate.length() - name.length()) <= maximum_length_difference &&
      (candidate.length() >= 3 || candidate.to_lower() == name.to_lower()) {
      let distance = _regexp_scaled_levenshtein(name, candidate)
      if distance < best_distance {
        best_distance = distance
        best_candidate = Some(candidate)
      }
    }
  }
  best_candidate
}
