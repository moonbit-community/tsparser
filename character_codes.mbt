// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/types.ts at 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
/// Namespace for the exact numeric values in TypeScript's internal
/// `CharacterCodes` const enum. Values are UTF-16 code units except for EOF.
priv struct CharacterCodes(Unit)

///|
fn CharacterCodes::eof() -> Int {
  -1
}

///|
fn CharacterCodes::null_character() -> Int {
  0
}

///|
fn CharacterCodes::max_ascii_character() -> Int {
  0x7f
}

///|
fn CharacterCodes::line_feed() -> Int {
  0x0a
}

///|
fn CharacterCodes::carriage_return() -> Int {
  0x0d
}

///|
fn CharacterCodes::line_separator() -> Int {
  0x2028
}

///|
fn CharacterCodes::paragraph_separator() -> Int {
  0x2029
}

///|
fn CharacterCodes::next_line() -> Int {
  0x0085
}

///|
fn CharacterCodes::space() -> Int {
  0x0020
}

///|
fn CharacterCodes::non_breaking_space() -> Int {
  0x00a0
}

///|
fn CharacterCodes::en_quad() -> Int {
  0x2000
}

///|
fn CharacterCodes::em_quad() -> Int {
  0x2001
}

///|
fn CharacterCodes::en_space() -> Int {
  0x2002
}

///|
fn CharacterCodes::em_space() -> Int {
  0x2003
}

///|
fn CharacterCodes::three_per_em_space() -> Int {
  0x2004
}

///|
fn CharacterCodes::four_per_em_space() -> Int {
  0x2005
}

///|
fn CharacterCodes::six_per_em_space() -> Int {
  0x2006
}

///|
fn CharacterCodes::figure_space() -> Int {
  0x2007
}

///|
fn CharacterCodes::punctuation_space() -> Int {
  0x2008
}

///|
fn CharacterCodes::thin_space() -> Int {
  0x2009
}

///|
fn CharacterCodes::hair_space() -> Int {
  0x200a
}

///|
fn CharacterCodes::zero_width_space() -> Int {
  0x200b
}

///|
fn CharacterCodes::narrow_no_break_space() -> Int {
  0x202f
}

///|
fn CharacterCodes::ideographic_space() -> Int {
  0x3000
}

///|
fn CharacterCodes::mathematical_space() -> Int {
  0x205f
}

///|
fn CharacterCodes::ogham() -> Int {
  0x1680
}

///|
fn CharacterCodes::replacement_character() -> Int {
  0xfffd
}

///|
fn CharacterCodes::underscore() -> Int {
  0x5f
}

///|
fn CharacterCodes::dollar() -> Int {
  0x24
}

///|
fn CharacterCodes::digit_0() -> Int {
  0x30
}

///|
fn CharacterCodes::digit_1() -> Int {
  0x31
}

///|
fn CharacterCodes::digit_2() -> Int {
  0x32
}

///|
fn CharacterCodes::digit_3() -> Int {
  0x33
}

///|
fn CharacterCodes::digit_4() -> Int {
  0x34
}

///|
fn CharacterCodes::digit_5() -> Int {
  0x35
}

///|
fn CharacterCodes::digit_6() -> Int {
  0x36
}

///|
fn CharacterCodes::digit_7() -> Int {
  0x37
}

///|
fn CharacterCodes::digit_8() -> Int {
  0x38
}

///|
fn CharacterCodes::digit_9() -> Int {
  0x39
}

///|
fn CharacterCodes::lower_a() -> Int {
  0x61
}

///|
fn CharacterCodes::lower_b() -> Int {
  0x62
}

///|
fn CharacterCodes::lower_c() -> Int {
  0x63
}

///|
fn CharacterCodes::lower_d() -> Int {
  0x64
}

///|
fn CharacterCodes::lower_e() -> Int {
  0x65
}

///|
fn CharacterCodes::lower_f() -> Int {
  0x66
}

///|
fn CharacterCodes::lower_g() -> Int {
  0x67
}

///|
fn CharacterCodes::lower_h() -> Int {
  0x68
}

///|
fn CharacterCodes::lower_i() -> Int {
  0x69
}

///|
fn CharacterCodes::lower_j() -> Int {
  0x6a
}

///|
fn CharacterCodes::lower_k() -> Int {
  0x6b
}

///|
fn CharacterCodes::lower_l() -> Int {
  0x6c
}

///|
fn CharacterCodes::lower_m() -> Int {
  0x6d
}

///|
fn CharacterCodes::lower_n() -> Int {
  0x6e
}

///|
fn CharacterCodes::lower_o() -> Int {
  0x6f
}

///|
fn CharacterCodes::lower_p() -> Int {
  0x70
}

///|
fn CharacterCodes::lower_q() -> Int {
  0x71
}

///|
fn CharacterCodes::lower_r() -> Int {
  0x72
}

///|
fn CharacterCodes::lower_s() -> Int {
  0x73
}

///|
fn CharacterCodes::lower_t() -> Int {
  0x74
}

///|
fn CharacterCodes::lower_u() -> Int {
  0x75
}

///|
fn CharacterCodes::lower_v() -> Int {
  0x76
}

///|
fn CharacterCodes::lower_w() -> Int {
  0x77
}

///|
fn CharacterCodes::lower_x() -> Int {
  0x78
}

///|
fn CharacterCodes::lower_y() -> Int {
  0x79
}

///|
fn CharacterCodes::lower_z() -> Int {
  0x7a
}

///|
fn CharacterCodes::upper_a() -> Int {
  0x41
}

///|
fn CharacterCodes::upper_b() -> Int {
  0x42
}

///|
fn CharacterCodes::upper_c() -> Int {
  0x43
}

///|
fn CharacterCodes::upper_d() -> Int {
  0x44
}

///|
fn CharacterCodes::upper_e() -> Int {
  0x45
}

///|
fn CharacterCodes::upper_f() -> Int {
  0x46
}

///|
fn CharacterCodes::upper_g() -> Int {
  0x47
}

///|
fn CharacterCodes::upper_h() -> Int {
  0x48
}

///|
fn CharacterCodes::upper_i() -> Int {
  0x49
}

///|
fn CharacterCodes::upper_j() -> Int {
  0x4a
}

///|
fn CharacterCodes::upper_k() -> Int {
  0x4b
}

///|
fn CharacterCodes::upper_l() -> Int {
  0x4c
}

///|
fn CharacterCodes::upper_m() -> Int {
  0x4d
}

///|
fn CharacterCodes::upper_n() -> Int {
  0x4e
}

///|
fn CharacterCodes::upper_o() -> Int {
  0x4f
}

///|
fn CharacterCodes::upper_p() -> Int {
  0x50
}

///|
fn CharacterCodes::upper_q() -> Int {
  0x51
}

///|
fn CharacterCodes::upper_r() -> Int {
  0x52
}

///|
fn CharacterCodes::upper_s() -> Int {
  0x53
}

///|
fn CharacterCodes::upper_t() -> Int {
  0x54
}

///|
fn CharacterCodes::upper_u() -> Int {
  0x55
}

///|
fn CharacterCodes::upper_v() -> Int {
  0x56
}

///|
fn CharacterCodes::upper_w() -> Int {
  0x57
}

///|
fn CharacterCodes::upper_x() -> Int {
  0x58
}

///|
fn CharacterCodes::upper_y() -> Int {
  0x59
}

///|
fn CharacterCodes::upper_z() -> Int {
  0x5a
}

///|
fn CharacterCodes::ampersand() -> Int {
  0x26
}

///|
fn CharacterCodes::asterisk() -> Int {
  0x2a
}

///|
fn CharacterCodes::at() -> Int {
  0x40
}

///|
fn CharacterCodes::backslash() -> Int {
  0x5c
}

///|
fn CharacterCodes::backtick() -> Int {
  0x60
}

///|
fn CharacterCodes::bar() -> Int {
  0x7c
}

///|
fn CharacterCodes::caret() -> Int {
  0x5e
}

///|
fn CharacterCodes::close_brace() -> Int {
  0x7d
}

///|
fn CharacterCodes::close_bracket() -> Int {
  0x5d
}

///|
fn CharacterCodes::close_paren() -> Int {
  0x29
}

///|
fn CharacterCodes::colon() -> Int {
  0x3a
}

///|
fn CharacterCodes::comma() -> Int {
  0x2c
}

///|
fn CharacterCodes::dot() -> Int {
  0x2e
}

///|
fn CharacterCodes::double_quote() -> Int {
  0x22
}

///|
fn CharacterCodes::equals() -> Int {
  0x3d
}

///|
fn CharacterCodes::exclamation() -> Int {
  0x21
}

///|
fn CharacterCodes::greater_than() -> Int {
  0x3e
}

///|
fn CharacterCodes::hash() -> Int {
  0x23
}

///|
fn CharacterCodes::less_than() -> Int {
  0x3c
}

///|
fn CharacterCodes::minus() -> Int {
  0x2d
}

///|
fn CharacterCodes::open_brace() -> Int {
  0x7b
}

///|
fn CharacterCodes::open_bracket() -> Int {
  0x5b
}

///|
fn CharacterCodes::open_paren() -> Int {
  0x28
}

///|
fn CharacterCodes::percent() -> Int {
  0x25
}

///|
fn CharacterCodes::plus() -> Int {
  0x2b
}

///|
fn CharacterCodes::question() -> Int {
  0x3f
}

///|
fn CharacterCodes::semicolon() -> Int {
  0x3b
}

///|
fn CharacterCodes::single_quote() -> Int {
  0x27
}

///|
fn CharacterCodes::slash() -> Int {
  0x2f
}

///|
fn CharacterCodes::tilde() -> Int {
  0x7e
}

///|
fn CharacterCodes::backspace() -> Int {
  0x08
}

///|
fn CharacterCodes::form_feed() -> Int {
  0x0c
}

///|
fn CharacterCodes::byte_order_mark() -> Int {
  0xfeff
}

///|
fn CharacterCodes::tab() -> Int {
  0x09
}

///|
fn CharacterCodes::vertical_tab() -> Int {
  0x0b
}

///|
/// Keeps the complete const-enum surface auditable before every value is used
/// by the scanner. 
fn _character_codes_contract_values() -> ReadOnlyArray[Int] {
  let CharacterCodes(marker) = CharacterCodes(())
  ignore(marker)
  ReadOnlyArray::from_array([
    CharacterCodes::eof(),
    CharacterCodes::null_character(),
    CharacterCodes::max_ascii_character(),
    CharacterCodes::line_feed(),
    CharacterCodes::carriage_return(),
    CharacterCodes::line_separator(),
    CharacterCodes::paragraph_separator(),
    CharacterCodes::next_line(),
    CharacterCodes::space(),
    CharacterCodes::non_breaking_space(),
    CharacterCodes::en_quad(),
    CharacterCodes::em_quad(),
    CharacterCodes::en_space(),
    CharacterCodes::em_space(),
    CharacterCodes::three_per_em_space(),
    CharacterCodes::four_per_em_space(),
    CharacterCodes::six_per_em_space(),
    CharacterCodes::figure_space(),
    CharacterCodes::punctuation_space(),
    CharacterCodes::thin_space(),
    CharacterCodes::hair_space(),
    CharacterCodes::zero_width_space(),
    CharacterCodes::narrow_no_break_space(),
    CharacterCodes::ideographic_space(),
    CharacterCodes::mathematical_space(),
    CharacterCodes::ogham(),
    CharacterCodes::replacement_character(),
    CharacterCodes::underscore(),
    CharacterCodes::dollar(),
    CharacterCodes::digit_0(),
    CharacterCodes::digit_1(),
    CharacterCodes::digit_2(),
    CharacterCodes::digit_3(),
    CharacterCodes::digit_4(),
    CharacterCodes::digit_5(),
    CharacterCodes::digit_6(),
    CharacterCodes::digit_7(),
    CharacterCodes::digit_8(),
    CharacterCodes::digit_9(),
    CharacterCodes::lower_a(),
    CharacterCodes::lower_b(),
    CharacterCodes::lower_c(),
    CharacterCodes::lower_d(),
    CharacterCodes::lower_e(),
    CharacterCodes::lower_f(),
    CharacterCodes::lower_g(),
    CharacterCodes::lower_h(),
    CharacterCodes::lower_i(),
    CharacterCodes::lower_j(),
    CharacterCodes::lower_k(),
    CharacterCodes::lower_l(),
    CharacterCodes::lower_m(),
    CharacterCodes::lower_n(),
    CharacterCodes::lower_o(),
    CharacterCodes::lower_p(),
    CharacterCodes::lower_q(),
    CharacterCodes::lower_r(),
    CharacterCodes::lower_s(),
    CharacterCodes::lower_t(),
    CharacterCodes::lower_u(),
    CharacterCodes::lower_v(),
    CharacterCodes::lower_w(),
    CharacterCodes::lower_x(),
    CharacterCodes::lower_y(),
    CharacterCodes::lower_z(),
    CharacterCodes::upper_a(),
    CharacterCodes::upper_b(),
    CharacterCodes::upper_c(),
    CharacterCodes::upper_d(),
    CharacterCodes::upper_e(),
    CharacterCodes::upper_f(),
    CharacterCodes::upper_g(),
    CharacterCodes::upper_h(),
    CharacterCodes::upper_i(),
    CharacterCodes::upper_j(),
    CharacterCodes::upper_k(),
    CharacterCodes::upper_l(),
    CharacterCodes::upper_m(),
    CharacterCodes::upper_n(),
    CharacterCodes::upper_o(),
    CharacterCodes::upper_p(),
    CharacterCodes::upper_q(),
    CharacterCodes::upper_r(),
    CharacterCodes::upper_s(),
    CharacterCodes::upper_t(),
    CharacterCodes::upper_u(),
    CharacterCodes::upper_v(),
    CharacterCodes::upper_w(),
    CharacterCodes::upper_x(),
    CharacterCodes::upper_y(),
    CharacterCodes::upper_z(),
    CharacterCodes::ampersand(),
    CharacterCodes::asterisk(),
    CharacterCodes::at(),
    CharacterCodes::backslash(),
    CharacterCodes::backtick(),
    CharacterCodes::bar(),
    CharacterCodes::caret(),
    CharacterCodes::close_brace(),
    CharacterCodes::close_bracket(),
    CharacterCodes::close_paren(),
    CharacterCodes::colon(),
    CharacterCodes::comma(),
    CharacterCodes::dot(),
    CharacterCodes::double_quote(),
    CharacterCodes::equals(),
    CharacterCodes::exclamation(),
    CharacterCodes::greater_than(),
    CharacterCodes::hash(),
    CharacterCodes::less_than(),
    CharacterCodes::minus(),
    CharacterCodes::open_brace(),
    CharacterCodes::open_bracket(),
    CharacterCodes::open_paren(),
    CharacterCodes::percent(),
    CharacterCodes::plus(),
    CharacterCodes::question(),
    CharacterCodes::semicolon(),
    CharacterCodes::single_quote(),
    CharacterCodes::slash(),
    CharacterCodes::tilde(),
    CharacterCodes::backspace(),
    CharacterCodes::form_feed(),
    CharacterCodes::byte_order_mark(),
    CharacterCodes::tab(),
    CharacterCodes::vertical_tab(),
  ])
}
