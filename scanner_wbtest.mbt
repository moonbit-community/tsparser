///|
fn _scanner_test_snapshot(
  text : String,
  skip_trivia? : Bool = true,
  target? : ScriptTarget = ScriptTarget::latest(),
  variant? : LanguageVariant = LanguageVariant::standard(),
  script_kind? : ScriptKind = ScriptKind::ts(),
  jsdoc_mode? : JSDocParsingMode = JSDocParsingMode::parse_all(),
) -> (Array[String], Array[String], Array[String]) {
  let errors : Array[String] = []
  let scanner = _create_scanner(
    target,
    skip_trivia,
    language_variant=variant,
    text~,
  )
  scanner._set_script_kind(script_kind)
  scanner._set_jsdoc_parsing_mode(jsdoc_mode)
  scanner._set_on_error(
    Some(fn(message, position, length, argument) {
      let argument_text = match argument {
        Some(DiagnosticString(value)) => value
        Some(DiagnosticNumber(value)) => value.to_string()
        None => "-"
      }
      errors.push(
        message.code().to_string() +
        "@" +
        position.to_string() +
        ":" +
        length.to_string() +
        ":" +
        argument_text,
      )
    }),
  )
  let tokens : Array[String] = []
  while true {
    let kind = scanner._scan()
    let value = match scanner._token_value() {
      Some(value) => value
      None => "<undefined>"
    }
    tokens.push(
      kind.to_int().to_string() +
      "@" +
      scanner._token_full_start().to_string() +
      ":" +
      scanner._token_start().to_string() +
      ":" +
      scanner._token_end().to_string() +
      ":" +
      scanner._token_text() +
      ":" +
      value +
      ":" +
      scanner._token_flags().bits().to_string(),
    )
    if kind.to_int() == 1 {
      break
    }
  }
  let directives : Array[String] = []
  match scanner._comment_directives() {
    Some(items) =>
      for item in items {
        directives.push(
          item.range().pos().to_string() +
          ":" +
          item.range().end().to_string() +
          ":" +
          item.directive_type().to_int().to_string(),
        )
      }
    None => ()
  }
  (tokens, errors, directives)
}

///|
fn _scanner_error_snapshot(text : String) -> Array[String] {
  let (_, errors, _) = _scanner_test_snapshot(text)
  errors
}

///|
test "scanner ordinary tokens trivia and directives" {
  debug_inspect(
    _scanner_test_snapshot(
      "#!/usr/bin/env node\r\n/** @see x */ const x = 1; // @ts-expect-error\n x",
    ),
    content=(
      #|(
      #|  [
      #|    "87@0:35:40:const:const:3",
      #|    "80@40:41:42:x:x:0",
      #|    "64@42:43:44:=:x:0",
      #|    "9@44:45:46:1:1:0",
      #|    "27@46:46:47:;:1:0",
      #|    "80@47:69:70:x:x:1",
      #|    "1@70:70:70::x:0",
      #|  ],
      #|  [],
      #|  ["48:67:0"],
      #|)
    ),
  )
}

///|
test "scanner numeric string template and unicode literals" {
  debug_inspect(
    _scanner_test_snapshot(
      "0 077 08 0xff 0b101 0o17 1_234 1.5e2 12n \"a\\n\\u{1f600}\" `a\\n${x}tail` \\u0069f \u{10400}",
    ),
    content=(
      #|(
      #|  [
      #|    "9@0:0:1:0:0:0",
      #|    "9@1:2:5:077:63:32",
      #|    "9@5:6:8:08:8:8192",
      #|    "9@8:9:13:0xff:255:64",
      #|    "9@13:14:19:0b101:5:128",
      #|    "9@19:20:24:0o17:15:256",
      #|    "9@24:25:30:1_234:1234:512",
      #|    "9@30:31:36:1.5e2:150:16",
      #|    "10@36:37:40:12n:12n:0",
      #|    "11@40:41:55:\"a\\n\\u{1f600}\":a\n😀:8",
      #|    "16@55:56:62:`a\\n${:a\n:0",
      #|    "80@62:62:63:x:x:0",
      #|    "20@63:63:64:}:x:0",
      #|    "80@64:64:68:tail:tail:0",
      #|    "15@68:68:80:` \\u0069f 𐐀: if 𐐀:1028",
      #|    "1@80:80:80:: if 𐐀:0",
      #|  ],
      #|  ["1121@2:3:0o77", "1489@6:2:-", "1160@80:0:-"],
      #|  [],
      #|)
    ),
  )
}

///|
test "scanner JavaScript numeric value spelling boundaries" {
  debug_inspect(
    _scanner_test_snapshot(
      "1e21 1e20 1e-6 1e-7 9007199254740993 0xffffffffffffffff 100000000000000000000 0.0000009999999999999999",
    ),
    content=(
      #|(
      #|  [
      #|    "9@0:0:4:1e21:1e+21:16",
      #|    "9@4:5:9:1e20:100000000000000000000:16",
      #|    "9@9:10:14:1e-6:0.000001:16",
      #|    "9@14:15:19:1e-7:1e-7:16",
      #|    "9@19:20:36:9007199254740993:9007199254740992:0",
      #|    "9@36:37:55:0xffffffffffffffff:18446744073709552000:64",
      #|    "9@55:56:77:100000000000000000000:100000000000000000000:0",
      #|    "9@77:78:102:0.0000009999999999999999:0.000001:0",
      #|    "1@102:102:102::0.000001:0",
      #|  ],
      #|  [],
      #|  [],
      #|)
    ),
  )
}

///|
test "scanner numeric overflow follows JavaScript Infinity" {
  debug_inspect(
    _scanner_test_snapshot("1e999 1e-999"),
    content=(
      #|(
      #|  [
      #|    "9@0:0:5:1e999:Infinity:16",
      #|    "9@5:6:12:1e-999:0:16",
      #|    "1@12:12:12::0:0",
      #|  ],
      #|  [],
      #|  [],
      #|)
    ),
  )
}

///|
test "scanner BigInt radix values and huge legacy octal replacement" {
  debug_inspect(
    _scanner_test_snapshot(
      "0xffn 0XABCn 0b1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111n 0o7777777777777777777777777777777777777777n 0777777777777777777777777 077777777777777777777777777777777777777777777777777777777777777777",
    ),
    content=(
      #|(
      #|  [
      #|    "10@0:0:5:0xffn:0xffn:64",
      #|    "10@5:6:12:0XABCn:0xabcn:64",
      #|    "10@12:13:116:0b1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111n:1267650600228229401496703205375n:128",
      #|    "10@116:117:160:0o7777777777777777777777777777777777777777n:1329227995784915872903807060280344575n:256",
      #|    "9@160:161:186:0777777777777777777777777:4.722366482869645e+21:32",
      #|    "9@186:187:253:077777777777777777777777777777777777777777777777777777777777777777:5.021681388309345e+58:32",
      #|    "1@253:253:253::5.021681388309345e+58:0",
      #|  ],
      #|  [
      #|    "1121@161:25:0o1000000000000000000000000",
      #|    "1121@187:66:0o100000000000000000000000000000000000000000000000000000000000000000",
      #|  ],
      #|  [],
      #|)
    ),
  )
}

///|
test "scanner public error families" {
  let fixtures = [
    "\"unterminated", "/*", "077", "1e", "0xg", "\"a\\", "\u0000", "`x", "0b2", "0o8",
    "<<<<<<< HEAD\n", "\"\\u{110000}\"", "\"\\u{1x\"", "1abc", "1e2n", "1.0n", "\"\\1\"",
    "\"\\8\"", "08", "�", "1__2 1_", "x\n#!y",
  ]
  let actual : Array[String] = []
  for fixture in fixtures {
    actual.push(fixture + " => " + _scanner_error_snapshot(fixture).join(","))
  }
  debug_inspect(
    actual,
    content=(
      #|[
      #|  "\"unterminated => 1002@13:0:-",
      #|  "/* => 1010@2:0:-",
      #|  "077 => 1121@0:3:0o77",
      #|  "1e => 1124@2:0:-",
      #|  "0xg => 1125@2:0:-",
      #|  "\"a\\ => 1126@3:0:-,1002@3:0:-",
      #|  "\u{00} => 1127@0:1:-",
      #|  "`x => 1160@2:0:-",
      #|  "0b2 => 1177@2:0:-",
      #|  "0o8 => 1178@2:0:-",
      #|  "<<<<<<< HEAD\n => 1185@0:7:-",
      #|  "\"\\u{110000}\" => 1198@4:6:-",
      #|  "\"\\u{1x\" => 1199@5:0:-",
      #|  "1abc => 1351@1:3:-",
      #|  "1e2n => 1352@0:4:-",
      #|  "1.0n => 1353@0:4:-",
      #|  "\"\\1\" => 1487@1:2:\\x01",
      #|  "\"\\8\" => 1488@1:2:\\8",
      #|  "08 => 1489@0:2:-",
      #|  "� => 1490@0:0:-",
      #|  "1__2 1_ => 6189@2:1:-,6188@6:1:-",
      #|  "x\n#!y => 18026@2:2:-",
      #|]
    ),
  )
}

///|
test "scanner punctuation maximal matching" {
  debug_inspect(
    _scanner_test_snapshot(
      "{ } ( ) [ ] . ... ; , ?. < </ > <= >= == != === !== => + - * ** / % ++ -- << & | ^ ! ~ && || ? : @ ?? # = += -= *= **= /= %= <<= &= |= ||= &&= ??= ^= ``",
      variant=LanguageVariant::jsx(),
    ),
    content=(
      #|(
      #|  [
      #|    "19@0:0:1:{:<undefined>:0",
      #|    "20@1:2:3:}:<undefined>:0",
      #|    "21@3:4:5:(:<undefined>:0",
      #|    "22@5:6:7:):<undefined>:0",
      #|    "23@7:8:9:[:<undefined>:0",
      #|    "24@9:10:11:]:<undefined>:0",
      #|    "25@11:12:13:.:<undefined>:0",
      #|    "26@13:14:17:...:<undefined>:0",
      #|    "27@17:18:19:;:<undefined>:0",
      #|    "28@19:20:21:,:<undefined>:0",
      #|    "29@21:22:24:?.:<undefined>:0",
      #|    "30@24:25:26:<:<undefined>:0",
      #|    "31@26:27:29:</:<undefined>:0",
      #|    "32@29:30:31:>:<undefined>:0",
      #|    "33@31:32:34:<=:<undefined>:0",
      #|    "32@34:35:36:>:<undefined>:0",
      #|    "64@36:36:37:=:<undefined>:0",
      #|    "35@37:38:40:==:<undefined>:0",
      #|    "36@40:41:43:!=:<undefined>:0",
      #|    "37@43:44:47:===:<undefined>:0",
      #|    "38@47:48:51:!==:<undefined>:0",
      #|    "39@51:52:54:=>:<undefined>:0",
      #|    "40@54:55:56:+:<undefined>:0",
      #|    "41@56:57:58:-:<undefined>:0",
      #|    "42@58:59:60:*:<undefined>:0",
      #|    "43@60:61:63:**:<undefined>:0",
      #|    "44@63:64:65:/:<undefined>:0",
      #|    "45@65:66:67:%:<undefined>:0",
      #|    "46@67:68:70:++:<undefined>:0",
      #|    "47@70:71:73:--:<undefined>:0",
      #|    "48@73:74:76:<<:<undefined>:0",
      #|    "51@76:77:78:&:<undefined>:0",
      #|    "52@78:79:80:|:<undefined>:0",
      #|    "53@80:81:82:^:<undefined>:0",
      #|    "54@82:83:84:!:<undefined>:0",
      #|    "55@84:85:86:~:<undefined>:0",
      #|    "56@86:87:89:&&:<undefined>:0",
      #|    "57@89:90:92:||:<undefined>:0",
      #|    "58@92:93:94:?:<undefined>:0",
      #|    "59@94:95:96:::<undefined>:0",
      #|    "60@96:97:98:@:<undefined>:0",
      #|    "61@98:99:101:??:<undefined>:0",
      #|    "81@101:102:103:#:#:0",
      #|    "64@103:104:105:=:#:0",
      #|    "65@105:106:108:+=:#:0",
      #|    "66@108:109:111:-=:#:0",
      #|    "67@111:112:114:*=:#:0",
      #|    "68@114:115:118:**=:#:0",
      #|    "69@118:119:121:/=:#:0",
      #|    "70@121:122:124:%=:#:0",
      #|    "71@124:125:128:<<=:#:0",
      #|    "74@128:129:131:&=:#:0",
      #|    "75@131:132:134:|=:#:0",
      #|    "76@134:135:138:||=:#:0",
      #|    "77@138:139:142:&&=:#:0",
      #|    "78@142:143:146:??=:#:0",
      #|    "79@146:147:149:^=:#:0",
      #|    "15@149:150:152:``::0",
      #|    "1@152:152:152:::0",
      #|  ],
      #|  ["1127@102:1:-"],
      #|  [],
      #|)
    ),
  )
}

///|
test "scanner regexp and contextual rescans" {
  let greater = _create_scanner(ScriptTarget::latest(), true, text=">>>=")
  inspect(
    greater._scan().to_int(),
    content=(
      #|32
    ),
  )
  inspect(
    greater._re_scan_greater_token().to_int(),
    content=(
      #|73
    ),
  )
  inspect(
    greater._token_text(),
    content=(
      #|>>>=
    ),
  )
  let regexp = _create_scanner(ScriptTarget::latest(), true, text="/a[\\/]b/gu")
  inspect(
    regexp._scan().to_int(),
    content=(
      #|44
    ),
  )
  inspect(
    regexp._re_scan_slash_token().to_int(),
    content=(
      #|14
    ),
  )
  inspect(
    regexp._token_text(),
    content=(
      #|/a[\/]b/gu
    ),
  )
  let less_than = _create_scanner(ScriptTarget::latest(), true, text="<<")
  inspect(
    less_than._scan().to_int(),
    content=(
      #|48
    ),
  )
  inspect(
    less_than._re_scan_less_than_token().to_int(),
    content=(
      #|30
    ),
  )
  let question = _create_scanner(ScriptTarget::latest(), true, text="??")
  inspect(
    question._scan().to_int(),
    content=(
      #|61
    ),
  )
  inspect(
    question._re_scan_question_token().to_int(),
    content=(
      #|58
    ),
  )
  let asterisk = _create_scanner(ScriptTarget::latest(), true, text="*=")
  inspect(
    asterisk._scan().to_int(),
    content=(
      #|67
    ),
  )
  inspect(
    asterisk._re_scan_asterisk_equals_token().to_int(),
    content=(
      #|64
    ),
  )
  let hash = _create_scanner(ScriptTarget::latest(), true, text="#x")
  inspect(
    hash._scan().to_int(),
    content=(
      #|81
    ),
  )
  inspect(
    hash._re_scan_hash_token().to_int(),
    content=(
      #|63
    ),
  )
  let template = _create_scanner(ScriptTarget::latest(), true, text="}tail`")
  inspect(
    template._scan().to_int(),
    content=(
      #|20
    ),
  )
  inspect(
    template._re_scan_template_token(false).to_int(),
    content=(
      #|18
    ),
  )
  debug_inspect(
    template._token_value(),
    content=(
      #|Some("tail")
    ),
  )
  let template_head_errors : Array[Int] = []
  let template_head = _create_scanner(
    ScriptTarget::latest(),
    true,
    text="`\\8`",
  )
  template_head._set_on_error(
    Some(fn(message, _, _, _) { template_head_errors.push(message.code()) }),
  )
  ignore(template_head._scan())
  inspect(
    template_head._re_scan_template_head_or_no_substitution().to_int(),
    content=(
      #|15
    ),
  )
  inspect(
    template_head._required_token_value(),
    content=(
      #|8
    ),
  )
  debug_inspect(
    template_head_errors,
    content=(
      #|[1488]
    ),
  )
  let jsx_text = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text="text<",
  )
  inspect(
    jsx_text._scan().to_int(),
    content=(
      #|80
    ),
  )
  inspect(
    jsx_text._re_scan_jsx_token().to_int(),
    content=(
      #|12
    ),
  )
  inspect(
    jsx_text._token_text(),
    content=(
      #|text
    ),
  )
  let jsx_attribute = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text="\"a\\n\"",
  )
  ignore(jsx_attribute._scan())
  inspect(
    jsx_attribute._required_token_value(),
    content=(
      #|a
      #|
    ),
  )
  inspect(
    jsx_attribute._re_scan_jsx_attribute_value().to_int(),
    content=(
      #|11
    ),
  )
  inspect(
    jsx_attribute._required_token_value(),
    content=(
      #|a\n
    ),
  )
}

///|
test "scanner six-field speculation and range restoration" {
  let scanner = _create_scanner(
    ScriptTarget::latest(),
    true,
    text="let alpha = 1",
  )
  inspect(
    scanner._scan().to_int(),
    content=(
      #|121
    ),
  )
  let looked = scanner._look_ahead(fn() {
    let next = scanner._scan()
    (next.to_int(), scanner._token_text())
  })
  debug_inspect(
    looked,
    content=(
      #|(80, "alpha")
    ),
  )
  debug_inspect(
    (scanner._token().to_int(), scanner._token_text()),
    content=(
      #|(121, "let")
    ),
  )
  let failed : Int? = scanner._try_scan(fn() {
    ignore(scanner._scan())
    None
  })
  debug_inspect(
    failed,
    content=(
      #|None
    ),
  )
  debug_inspect(
    (scanner._token().to_int(), scanner._token_text()),
    content=(
      #|(121, "let")
    ),
  )
  let ranged = scanner._scan_range(4, 5, fn() {
    let kind = scanner._scan()
    (kind.to_int(), scanner._token_text())
  })
  debug_inspect(
    ranged,
    content=(
      #|(80, "alpha")
    ),
  )
  debug_inspect(
    (scanner._token().to_int(), scanner._token_text()),
    content=(
      #|(121, "let")
    ),
  )
}

///|
test "scanner successful try-scan setters ranges and JSDoc asterisks" {
  let accepted = _create_scanner(ScriptTarget::latest(), true, text="let alpha")
  ignore(accepted._scan())
  let result : Int? = accepted._try_scan(fn() {
    Some(accepted._scan().to_int())
  })
  debug_inspect(
    result,
    content=(
      #|Some(80)
    ),
  )
  debug_inspect(
    (accepted._token().to_int(), accepted._token_text()),
    content=(
      #|(80, "alpha")
    ),
  )

  let ranged = _create_scanner(
    ScriptTarget::latest(),
    true,
    text="let // @ts-ignore\nx",
  )
  ignore(ranged._scan())
  let directive_count = ranged._scan_range(4, 13, fn() {
    ignore(ranged._scan())
    match ranged._comment_directives() {
      Some(items) => items.length()
      None => 0
    }
  })
  inspect(
    directive_count,
    content=(
      #|1
    ),
  )
  debug_inspect(
    ranged._comment_directives(),
    content=(
      #|None
    ),
  )
  debug_inspect(
    (ranged._token().to_int(), ranged._token_text()),
    content=(
      #|(121, "let")
    ),
  )

  let reset = _create_scanner(ScriptTarget::latest(), true, text="old")
  ignore(reset._scan())
  reset._set_script_target(ScriptTarget::es5())
  reset._set_language_variant(LanguageVariant::jsx())
  reset._set_script_kind(ScriptKind::js())
  reset._set_jsdoc_parsing_mode(JSDocParsingMode::parse_none())
  reset._set_text("xx let yy", start=3, length=3)
  inspect(
    reset._scan().to_int(),
    content=(
      #|121
    ),
  )
  debug_inspect(
    (
      reset._text(),
      reset._token_full_start(),
      reset._token_start(),
      reset._token_end(),
      reset.language_version.to_int(),
      reset.language_variant.to_int(),
      reset.script_kind.to_int(),
      reset.jsdoc_parsing_mode.to_int(),
    ),
    content=(
      #|("xx let yy", 3, 3, 6, 1, 1, 1, 1)
    ),
  )

  let asterisks = _create_scanner(ScriptTarget::latest(), true, text="\n * foo")
  asterisks._set_skip_jsdoc_leading_asterisks(true)
  inspect(
    asterisks._scan().to_int(),
    content=(
      #|80
    ),
  )
  inspect(
    asterisks._token_text(),
    content=(
      #|foo
    ),
  )
  inspect(
    asterisks._token_flags().bits(),
    content=(
      #|32769
    ),
  )
  asterisks._set_skip_jsdoc_leading_asterisks(false)
}

///|
test "scanner directive and HTML-like comment reference boundaries" {
  let directives : Array[String] = []
  for
    fixture in [
      "/* @ts-ignore */x", "/* first\n * @ts-expect-error */x", "// @ts-check\n// @ts-nocheck\n// @ts-ignore x\ny",
      "/* @ts-ignore\n * tail */x", "/// @ts-expect-error x\ny",
    ] {
    let (_, _, found) = _scanner_test_snapshot(fixture)
    directives.push(fixture + " => " + found.join(","))
  }
  debug_inspect(
    directives,
    content=(
      #|[
      #|  "/* @ts-ignore */x => 0:16:1",
      #|  "/* first\n * @ts-expect-error */x => 9:31:0",
      #|  "// @ts-check\n// @ts-nocheck\n// @ts-ignore x\ny => 28:43:1",
      #|  "/* @ts-ignore\n * tail */x => ",
      #|  "/// @ts-expect-error x\ny => 0:22:0",
      #|]
    ),
  )
  let html = _create_scanner(ScriptTarget::latest(), false, text="<!--x\n-->y")
  let html_tokens : Array[String] = []
  while true {
    let kind = html._scan()
    html_tokens.push(kind.to_int().to_string() + ":" + html._token_text())
    if kind.to_int() == 1 {
      break
    }
  }
  debug_inspect(
    html_tokens,
    content=(
      #|[
      #|  "30:<",
      #|  "54:!",
      #|  "47:--",
      #|  "80:x",
      #|  "4:\n",
      #|  "47:--",
      #|  "32:>",
      #|  "80:y",
      #|  "1:",
      #|]
    ),
  )
}

///|
test "scanner unicode identifiers and ESNext invalid rescan" {
  debug_inspect(
    _scanner_test_snapshot("\\u0069f \\u{10400} 𐐀x a‌b"),
    content=(
      #|(
      #|  [
      #|    "101@0:0:7:\\u0069f:if:1024",
      #|    "80@7:8:17:\\u{10400}:𐐀:8",
      #|    "80@17:18:21:𐐀x:𐐀x:0",
      #|    "80@21:22:25:a‌b:a‌b:0",
      #|    "1@25:25:25::a‌b:0",
      #|  ],
      #|  [],
      #|  [],
      #|)
    ),
  )
  let es5 = _create_scanner(ScriptTarget::es5(), true, text="𐐀x")
  inspect(
    es5._scan().to_int(),
    content=(
      #|0
    ),
  )
  inspect(
    es5._token_end(),
    content=(
      #|2
    ),
  )
  inspect(
    es5._re_scan_invalid_identifier().to_int(),
    content=(
      #|80
    ),
  )
  inspect(
    es5._token_end(),
    content=(
      #|3
    ),
  )
  inspect(
    es5._token_value().unwrap(),
    content=(
      #|𐐀x
    ),
  )
}

///|
test "scanner JSX text identifiers and attributes" {
  let text = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text="hello\n  world<div",
  )
  inspect(
    text._scan_jsx_token().to_int(),
    content=(
      #|12
    ),
  )
  inspect(
    text._token_value().unwrap(),
    content=(
      #|hello
      #|  world
    ),
  )
  inspect(
    text._scan_jsx_token().to_int(),
    content=(
      #|30
    ),
  )
  inspect(
    text._scan().to_int(),
    content=(
      #|80
    ),
  )
  inspect(
    text._scan_jsx_identifier().to_int(),
    content=(
      #|80
    ),
  )
  inspect(
    text._token_value().unwrap(),
    content=(
      #|div
    ),
  )
  let whitespace = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text="  \n  <",
  )
  inspect(
    whitespace._scan_jsx_token().to_int(),
    content=(
      #|13
    ),
  )
  let identifier = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text="custom-element-x ",
  )
  inspect(
    identifier._scan().to_int(),
    content=(
      #|80
    ),
  )
  inspect(
    identifier._scan_jsx_identifier().to_int(),
    content=(
      #|80
    ),
  )
  inspect(
    identifier._token_text(),
    content=(
      #|custom-element-x
    ),
  )
  inspect(
    identifier._token_value().unwrap(),
    content=(
      #|custom-element-x
    ),
  )
  let attribute = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text="\"a\\n\nb\"",
  )
  inspect(
    attribute._scan_jsx_attribute_value().to_int(),
    content=(
      #|11
    ),
  )
  inspect(
    attribute._token_value().unwrap(),
    content=(
      #|a\n
      #|b
    ),
  )
  inspect(
    attribute._token_flags().bits(),
    content=(
      #|0
    ),
  )
}

///|
test "scanner template tagged escape and JSX text diagnostics" {
  let template_snapshots : Array[String] = []
  for tagged in [true, false] {
    let errors : Array[String] = []
    let template = _create_scanner(ScriptTarget::latest(), true, text="`\\8`")
    template._set_on_error(
      Some(fn(message, position, length, argument) {
        let argument_text = match argument {
          Some(DiagnosticString(value)) => value
          Some(DiagnosticNumber(value)) => value.to_string()
          None => "-"
        }
        errors.push(
          message.code().to_string() +
          "@" +
          position.to_string() +
          ":" +
          length.to_string() +
          ":" +
          argument_text,
        )
      }),
    )
    let initial = template._scan()
    template_snapshots.push(
      tagged.to_string() +
      ":initial=" +
      initial.to_int().to_string() +
      ":" +
      template._required_token_value() +
      ":" +
      template._token_flags().bits().to_string(),
    )
    let rescanned = template._re_scan_template_token(tagged)
    template_snapshots.push(
      tagged.to_string() +
      ":rescan=" +
      rescanned.to_int().to_string() +
      ":" +
      template._required_token_value() +
      ":" +
      template._token_flags().bits().to_string() +
      ":" +
      errors.join(","),
    )
  }
  debug_inspect(
    template_snapshots,
    content=(
      #|[
      #|  "true:initial=15:\\8:2048",
      #|  "true:rescan=15:\\8:2048:",
      #|  "false:initial=15:\\8:2048",
      #|  "false:rescan=15:8:2048:1488@1:2:\\8",
      #|]
    ),
  )
  let jsx_errors : Array[String] = []
  let jsx = _create_scanner(
    ScriptTarget::latest(),
    true,
    language_variant=LanguageVariant::jsx(),
    text="x}y>z",
  )
  jsx._set_on_error(
    Some(fn(message, position, length, argument) {
      let argument_text = match argument {
        Some(DiagnosticString(value)) => value
        Some(DiagnosticNumber(value)) => value.to_string()
        None => "-"
      }
      jsx_errors.push(
        message.code().to_string() +
        "@" +
        position.to_string() +
        ":" +
        length.to_string() +
        ":" +
        argument_text,
      )
    }),
  )
  inspect(
    jsx._scan_jsx_token().to_int(),
    content=(
      #|12
    ),
  )
  inspect(
    jsx._required_token_value(),
    content=(
      #|x}y>z
    ),
  )
  debug_inspect(
    jsx_errors,
    content=(
      #|["1381@1:1:-", "1382@3:1:-"]
    ),
  )
}

///|
test "scanner JSDoc token and comment-text modes" {
  let tokens = _create_scanner(
    ScriptTarget::latest(),
    false,
    text=" @param foo-bar\r\n`code` {x}",
  )
  let output : Array[String] = []
  while true {
    let kind = tokens._scan_jsdoc_token()
    output.push(
      kind.to_int().to_string() +
      ":" +
      tokens._token_text() +
      ":" +
      tokens._token_flags().bits().to_string(),
    )
    if kind.to_int() == 1 {
      break
    }
  }
  debug_inspect(
    output,
    content=(
      #|[
      #|  "5: :0",
      #|  "60:@:0",
      #|  "80:param:0",
      #|  "5: :0",
      #|  "80:foo-bar:0",
      #|  "4:\r\n:1",
      #|  "62:`:0",
      #|  "80:code:0",
      #|  "62:`:0",
      #|  "5: :0",
      #|  "19:{:0",
      #|  "80:x:0",
      #|  "20:}:0",
      #|  "1::0",
      #|]
    ),
  )
  let comment = _create_scanner(
    ScriptTarget::latest(),
    false,
    text="description @tag `inside @ text` {link}",
  )
  inspect(
    comment._scan_jsdoc_comment_text_token(false).to_int(),
    content=(
      #|82
    ),
  )
  inspect(
    comment._token_value().unwrap(),
    content=(
      #|description 
    ),
  )
  inspect(
    comment._scan_jsdoc_token().to_int(),
    content=(
      #|60
    ),
  )
  inspect(
    comment._scan_jsdoc_comment_text_token(false).to_int(),
    content=(
      #|82
    ),
  )
  inspect(
    comment._scan_jsdoc_comment_text_token(true).to_int(),
    content=(
      #|62
    ),
  )
  inspect(
    comment._token_value().unwrap(),
    content=(
      #|tag 
    ),
  )
}

///|
test "scanner ScriptKind and JSDoc parsing-mode gating" {
  let preceding_jsdoc = fn(
    text : String,
    kind : ScriptKind,
    mode : JSDocParsingMode,
  ) -> Bool {
    let scanner = _create_scanner(ScriptTarget::latest(), true, text~)
    scanner._set_script_kind(kind)
    scanner._set_jsdoc_parsing_mode(mode)
    ignore(scanner._scan())
    scanner._token_flags().contains(TokenFlags::preceding_jsdoc_comment())
  }
  debug_inspect(
    [
      preceding_jsdoc(
        "/** plain */x",
        ScriptKind::ts(),
        JSDocParsingMode::parse_all(),
      ),
      preceding_jsdoc(
        "/** plain */x",
        ScriptKind::js(),
        JSDocParsingMode::parse_none(),
      ),
      preceding_jsdoc(
        "/** plain */x",
        ScriptKind::js(),
        JSDocParsingMode::parse_for_type_errors(),
      ),
      preceding_jsdoc(
        "/** plain */x",
        ScriptKind::ts(),
        JSDocParsingMode::parse_for_type_errors(),
      ),
      preceding_jsdoc(
        "/** @see x */y",
        ScriptKind::ts(),
        JSDocParsingMode::parse_for_type_errors(),
      ),
      preceding_jsdoc(
        "/** @link x */y",
        ScriptKind::tsx(),
        JSDocParsingMode::parse_for_type_info(),
      ),
      preceding_jsdoc(
        "/** plain */x",
        ScriptKind::jsx(),
        JSDocParsingMode::parse_for_type_info(),
      ),
    ],
    content=(
      #|[true, false, true, false, true, false, true]
    ),
  )
}
