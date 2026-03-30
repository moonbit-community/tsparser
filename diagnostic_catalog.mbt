///|
priv enum ExpectedSyntax {
  Identifier
  Expression
  StringLiteral
  Type
  TypeArgument
  BindingPattern
  MemberName
  PropertyName
  TemplateChunk
  JSXAttributeValue
  CaseOrDefault
  FunctionType
  EndOfFile
  Token(String)
}

///|
fn format_diagnostic_message(code : Int, args : Array[String]) -> String {
  match ts_diagnostic_template(code) {
    Some(template) => format_diagnostic_template(template, args)
    None => "Diagnostic message missing for TS\{code}."
  }
}

///|
fn format_diagnostic_template(
  template : String,
  args : Array[String],
) -> String {
  let sb = StringBuilder::new()
  let mut index = 0
  while index < template.length() {
    if template[index] == '{' {
      let mut placeholder_end = index + 1
      let mut placeholder_index = 0
      let mut saw_digit = false
      while placeholder_end < template.length() {
        let ch = template[placeholder_end]
        if ch >= '0' && ch <= '9' {
          saw_digit = true
          placeholder_index = placeholder_index * 10 +
            ch.to_int() -
            '0'.to_int()
          placeholder_end += 1
          continue
        }
        break
      }
      if saw_digit &&
        placeholder_end < template.length() &&
        template[placeholder_end] == '}' {
        if placeholder_index < args.length() {
          sb.write_string(args[placeholder_index])
        } else {
          sb.write_string(
            template
            .view(start_offset=index, end_offset=placeholder_end + 1)
            .to_string(),
          )
        }
        index = placeholder_end + 1
        continue
      }
    }
    sb.write_string(
      template.view(start_offset=index, end_offset=index + 1).to_string(),
    )
    index += 1
  }
  sb.to_string()
}

///|
fn expected_syntax_code_and_args(
  expected : ExpectedSyntax,
) -> (Int, Array[String]) {
  match expected {
    ExpectedSyntax::Identifier => (1003, [])
    ExpectedSyntax::Expression => (1109, [])
    ExpectedSyntax::StringLiteral => (1141, [])
    ExpectedSyntax::Type => (1110, [])
    ExpectedSyntax::TypeArgument => (1140, [])
    ExpectedSyntax::BindingPattern => (1180, [])
    ExpectedSyntax::MemberName => (1003, [])
    ExpectedSyntax::PropertyName => (1136, [])
    ExpectedSyntax::TemplateChunk => (1005, ["}"])
    ExpectedSyntax::JSXAttributeValue => (1145, [])
    ExpectedSyntax::CaseOrDefault => (1130, [])
    ExpectedSyntax::FunctionType => (1110, [])
    ExpectedSyntax::EndOfFile => (1012, [])
    ExpectedSyntax::Token(text) => (1005, [text])
  }
}

///|
fn diagnostic_matches_message(
  error_code : Int,
  error_msg : String,
  code : Int,
  args : Array[String],
) -> Bool {
  error_code == code && error_msg == format_diagnostic_message(code, args)
}
