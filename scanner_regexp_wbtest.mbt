///|
fn _regexp_error_snapshot(
  text : String,
  target? : ScriptTarget = ScriptTarget::latest(),
) -> Array[String] {
  let errors : Array[String] = []
  let scanner = _create_scanner(target, true, text~)
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
  guard scanner._scan().to_int() == 44 else {
    abort("regexp fixture must start with a slash token")
  }
  ignore(scanner._re_scan_slash_token(report_errors=true))
  errors
}

///|
test "scanner full regexp grammar diagnostics" {
  let fixtures : Array[String] = [
    "/a/gguvz", "/(?<foo>a)(?<foo>b)\\k<foa>\\3/u", "/(?:(?<x>a)|(?<x>b))/u", "/{,2}{3,2}*a++/u",
    "/(?im-s:abc)(?g:)(?-:)/", "/[\\d-a][z-a]/u", "/\\c1\\8\\q/u", "/[a&&b--c]/v",
    "/[\\q{ab|c}--\\p{Basic_Emoji}]/v", "/[^\\q{ab}]/v", "/[&&a]/v", "/[!!]/v", "/\\p{General_Categor=Letter}/u",
    "/\\p{General_Category=Lettr}/u", "/\\p{Basic_Emoji}/u", "/\\P{Basic_Emoji}/v",
    "/\\p{NoSuch}/u", "/\\p/u", "/\\p{L}/", "/\\k/u", "/(a)\\2/u", "/\\1/u", "/(/u",
    "/\\xZ/u", "/\\uZZZZ/u", "/\\07/u", "/[\\1]/u", "/[\\8]/u", "/\\u{61}/", "/\\u{110000}/u",
    "/\\u{}/u", "/\\u{1/", "/]/u", "/\\q/v", "/(?<>a)/u", "/[\\qX]/v", "/\\p{=L}/u",
    "/\\p{gc=}/u", "/\\p{}/u", "/\\k(?<x>a)/", "/\\k/", "/[a&b]/v", "/[a---b]/v",
    "/[a&&&b]/v", "/[\\q{}]/v", "/[\\q{a|}]/v",
  ]
  let actual : Array[String] = []
  for fixture in fixtures {
    actual.push(fixture + " => " + _regexp_error_snapshot(fixture).join(","))
  }
  actual.push(
    "/a/d@ES5 => " +
    _regexp_error_snapshot("/a/d", target=ScriptTarget::es5()).join(","),
  )
  actual.push(
    "/(?<x>a)/u@ES2017 => " +
    _regexp_error_snapshot("/(?<x>a)/u", target=ScriptTarget::es2017()).join(
      ",",
    ),
  )
  debug_inspect(
    actual,
    content=(
      #|[
      #|  "/a/gguvz => 1500@4:1:-,1502@6:1:-,1499@7:1:-",
      #|  "/(?<foo>a)(?<foo>b)\\k<foa>\\3/u => 1515@13:3:-,1532@22:3:foa,1533@27:1:2",
      #|  "/(?:(?<x>a)|(?<x>b))/u => ",
      #|  "/{,2}{3,2}*a++/u => 1505@2:0:-,1507@1:4:-,1506@6:3:-,1507@5:5:-,1507@10:1:-,1507@13:1:-",
      #|  "/(?im-s:abc)(?g:)(?-:)/ => 1509@14:1:-,1504@19:1:-",
      #|  "/[\\d-a][z-a]/u => 1516@2:2:-,1517@8:3:-",
      #|  "/\\c1\\8\\q/u => 1512@1:2:-,1535@6:2:-,1534@5:1:-",
      #|  "/[a&&b--c]/v => 1519@6:2:-",
      #|  "/[\\q{ab|c}--\\p{Basic_Emoji}]/v => ",
      #|  "/[^\\q{ab}]/v => 1518@3:6:-",
      #|  "/[&&a]/v => 1520@2:0:-",
      #|  "/[!!]/v => 1522@2:2:-",
      #|  "/\\p{General_Categor=Letter}/u => 1524@4:15:-,1369@4:15:General_Category",
      #|  "/\\p{General_Category=Lettr}/u => 1526@21:5:-,1369@21:5:Letter",
      #|  "/\\p{Basic_Emoji}/u => 1528@4:11:-",
      #|  "/\\P{Basic_Emoji}/v => 1518@4:11:-",
      #|  "/\\p{NoSuch}/u => 1529@4:6:-",
      #|  "/\\p/u => 1531@1:2:p",
      #|  "/\\p{L}/ => 1530@1:5:-",
      #|  "/\\k/u => 1510@1:2:-",
      #|  "/(a)\\2/u => 1533@5:1:1",
      #|  "/\\1/u => 1534@2:1:-",
      #|  "/(/u => 1005@2:0:)",
      #|  "/\\xZ/u => 1125@3:0:-",
      #|  "/\\uZZZZ/u => 1125@3:0:-",
      #|  "/\\07/u => 1487@1:3:\\x07",
      #|  "/[\\1]/u => 1536@2:2:\\x01",
      #|  "/[\\8]/u => 1537@2:2:-",
      #|  "/\\u{61}/ => 1538@1:6:-",
      #|  "/\\u{110000}/u => 1198@4:6:-",
      #|  "/\\u{}/u => 1125@4:0:-",
      #|  "/\\u{1/ => 1126@5:0:-,1538@1:4:-",
      #|  "/]/u => 1508@1:1:]",
      #|  "/\\q/v => 1511@1:2:-",
      #|  "/(?<>a)/u => 1514@4:0:-",
      #|  "/[\\qX]/v => 1521@2:2:-",
      #|  "/\\p{=L}/u => 1523@4:0:-",
      #|  "/\\p{gc=}/u => 1525@7:0:-",
      #|  "/\\p{}/u => 1527@4:0:-",
      #|  "/\\k(?<x>a)/ => 1510@1:2:-",
      #|  "/\\k/ => ",
      #|  "/[a&b]/v => 1508@3:1:a,1508@3:1:&",
      #|  "/[a---b]/v => 1508@5:1:-,1005@6:0:--",
      #|  "/[a&&&b]/v => 1508@5:1:&",
      #|  "/[\\q{}]/v => ",
      #|  "/[\\q{a|}]/v => ",
      #|  "/a/d@ES5 => 1501@3:1:es2022",
      #|  "/(?<x>a)/u@ES2017 => 1503@3:3:-",
      #|]
    ),
  )
}

///|
test "scanner regexp unterminated recovery and validator-only trailing escape" {
  let fixtures = [
    "/abc\nrest", "/[abc\nrest", "/abc) tail", "/abc] tail", "/abc} tail", "/abc;   ",
    "/(abc\nrest", "/{1,2\nrest", "/abc\\\nrest",
  ]
  let recovered : Array[String] = []
  for fixture in fixtures {
    let errors : Array[String] = []
    let scanner = _create_scanner(ScriptTarget::latest(), true, text=fixture)
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
    ignore(scanner._scan())
    let kind = scanner._re_scan_slash_token()
    recovered.push(
      fixture +
      " => " +
      kind.to_int().to_string() +
      ":" +
      scanner._token_end().to_string() +
      ":" +
      scanner._token_text() +
      ":" +
      scanner._token_flags().bits().to_string() +
      ":" +
      errors.join(","),
    )
  }
  debug_inspect(
    recovered,
    content=(
      #|[
      #|  "/abc\nrest => 14:4:/abc:4:1161@0:4:-",
      #|  "/[abc\nrest => 14:5:/[abc:4:1161@0:5:-",
      #|  "/abc) tail => 14:4:/abc:4:1161@0:4:-",
      #|  "/abc] tail => 14:4:/abc:4:1161@0:4:-",
      #|  "/abc} tail => 14:4:/abc:4:1161@0:4:-",
      #|  "/abc;    => 14:4:/abc:4:1161@0:4:-",
      #|  "/(abc\nrest => 14:5:/(abc:4:1161@0:5:-",
      #|  "/{1,2\nrest => 14:5:/{1,2:4:1161@0:5:-",
      #|  "/abc\\\nrest => 14:5:/abc\\:4:1161@0:5:-",
      #|]
    ),
  )

  let direct_errors : Array[String] = []
  let direct = _create_scanner(ScriptTarget::latest(), true, text="\\")
  direct._set_on_error(
    Some(fn(message, position, length, _) {
      direct_errors.push(
        message.code().to_string() +
        "@" +
        position.to_string() +
        ":" +
        length.to_string(),
      )
    }),
  )
  _validate_regular_expression(
    direct,
    RegularExpressionFlags::unicode(),
    true,
    false,
  )
  debug_inspect(
    direct_errors,
    content=(
      #|["1513@0:1"]
    ),
  )
}
