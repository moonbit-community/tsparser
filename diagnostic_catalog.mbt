///|
fn ts_diagnostic_template(code : Int) -> String? {
  match code {
    1002 => Some("Unterminated string literal.")
    1003 => Some("Identifier expected.")
    1005 => Some("'{0}' expected.")
    1006 => Some("A file cannot have a reference to itself.")
    1009 => Some("Trailing comma not allowed.")
    1012 => Some("Unexpected token.")
    1011 => Some("An element access expression should take an argument.")
    1014 => Some("A rest parameter must be last in a parameter list.")
    1015 => Some("Parameter cannot have question mark and initializer.")
    1016 => Some("A required parameter cannot follow an optional parameter.")
    1019 => Some("An index signature parameter cannot have a question mark.")
    1020 => Some("An index signature parameter cannot have an initializer.")
    1021 => Some("An index signature must have a type annotation.")
    1028 => Some("Accessibility modifier already seen.")
    1029 => Some("'{0}' modifier must precede '{1}' modifier.")
    1030 => Some("'{0}' modifier already seen.")
    1031 => Some("'{0}' modifier cannot appear on class elements of this kind.")
    1034 =>
      Some("'super' must be followed by an argument list or member access.")
    1035 => Some("Only ambient modules can use quoted names.")
    1039 => Some("Initializers are not allowed in ambient contexts.")
    1042 => Some("'{0}' modifier cannot be used here.")
    1044 =>
      Some("'{0}' modifier cannot appear on a module or namespace element.")
    1046 =>
      Some(
        "Top-level declarations in .d.ts files must start with either a 'declare' or 'export' modifier.",
      )
    1047 => Some("A rest parameter cannot be optional.")
    1048 => Some("A rest parameter cannot have an initializer.")
    1051 => Some("A 'set' accessor cannot have an optional parameter.")
    1052 => Some("A 'set' accessor parameter cannot have an initializer.")
    1053 => Some("A 'set' accessor cannot have rest parameter.")
    1054 => Some("A 'get' accessor cannot have parameters.")
    1061 => Some("Enum member must have initializer.")
    1062 =>
      Some(
        "Type is referenced directly or indirectly in the fulfillment callback of its own 'then' method.",
      )
    1066 =>
      Some(
        "In ambient enum declarations member initializer must be constant expression.",
      )
    1068 =>
      Some(
        "Unexpected token. A constructor, method, accessor, or property was expected.",
      )
    1079 => Some("A '{0}' modifier cannot be used with an import declaration.")
    1084 => Some("Invalid 'reference' directive syntax.")
    1090 => Some("'{0}' modifier cannot appear on a parameter.")
    1092 => Some("Type parameters cannot appear on a constructor declaration.")
    1095 => Some("A 'set' accessor cannot have a return type annotation.")
    1096 => Some("An index signature must have exactly one parameter.")
    1098 => Some("Type parameter list cannot be empty.")
    1099 => Some("Type argument list cannot be empty.")
    1100 => Some("Invalid use of '{0}' in strict mode.")
    1101 => Some("'with' statements are not allowed in strict mode.")
    1102 => Some("'delete' cannot be called on an identifier in strict mode.")
    1103 =>
      Some(
        "'for await' loops are only allowed within async functions and at the top levels of modules.",
      )
    1109 => Some("Expression expected.")
    1110 => Some("Type expected.")
    1113 =>
      Some(
        "A 'default' clause cannot appear more than once in a 'switch' statement.",
      )
    1114 => Some("Duplicate label '{0}'.")
    1117 =>
      Some(
        "An object literal cannot have multiple properties with the same name.",
      )
    1118 =>
      Some(
        "An object literal cannot have multiple get/set accessors with the same name.",
      )
    1120 => Some("An export assignment cannot have modifiers.")
    1121 => Some("Octal literals are not allowed. Use the syntax '{0}'.")
    1123 => Some("Variable declaration list cannot be empty.")
    1124 => Some("Digit expected.")
    1125 => Some("Hexadecimal digit expected.")
    1126 => Some("Unexpected end of text.")
    1127 => Some("Invalid character.")
    1128 => Some("Declaration or statement expected.")
    1130 => Some("'case' or 'default' expected.")
    1131 => Some("Property or signature expected.")
    1134 => Some("Variable declaration expected.")
    1135 => Some("Argument expression expected.")
    1136 => Some("Property assignment expected.")
    1138 => Some("Parameter declaration expected.")
    1139 => Some("Type parameter declaration expected.")
    1140 => Some("Type argument expected.")
    1141 => Some("String literal expected.")
    1142 => Some("Line break not permitted here.")
    1144 => Some("'{' or ';' expected.")
    1145 => Some("'{' or JSX element expected.")
    1146 => Some("Declaration expected.")
    1147 =>
      Some("Import declarations in a namespace cannot reference a module.")
    1148 =>
      Some(
        "Cannot use imports, exports, or module augmentations when '--module' is 'none'.",
      )
    1155 => Some("'{0}' declarations must be initialized.")
    1156 => Some("'{0}' declarations can only be declared inside a block.")
    1160 => Some("Unterminated template literal.")
    1161 => Some("Unterminated regular expression literal.")
    1162 => Some("An object member cannot be declared optional.")
    1163 => Some("A 'yield' expression is only allowed in a generator body.")
    1166 =>
      Some(
        "A computed property name in a class property declaration must have a simple literal type or a 'unique symbol' type.",
      )
    1169 =>
      Some(
        "A computed property name in an interface must refer to an expression whose type is a literal type or a 'unique symbol' type.",
      )
    1172 => Some("'extends' clause already seen.")
    1173 => Some("'extends' clause must precede 'implements' clause.")
    1174 => Some("Classes can only extend a single class.")
    1175 => Some("'implements' clause already seen.")
    1176 => Some("Interface declaration cannot have 'implements' clause.")
    1177 => Some("Binary digit expected.")
    1178 => Some("Octal digit expected.")
    1180 => Some("Property destructuring pattern expected.")
    1181 => Some("Array element destructuring pattern expected.")
    1182 => Some("A destructuring declaration must have an initializer.")
    1184 => Some("Modifiers cannot appear here.")
    1185 => Some("Merge conflict marker encountered.")
    1186 => Some("A rest element cannot have an initializer.")
    1187 =>
      Some("A parameter property may not be declared using a binding pattern.")
    1191 => Some("An import declaration cannot have modifiers.")
    1192 => Some("Module '{0}' has no default export.")
    1194 => Some("Export declarations are not permitted in a namespace.")
    1197 => Some("Catch clause variable cannot have an initializer.")
    1198 =>
      Some(
        "An extended Unicode escape value must be between 0x0 and 0x10FFFF inclusive.",
      )
    1200 => Some("Line terminator not permitted before arrow.")
    1202 =>
      Some(
        "Import assignment cannot be used when targeting ECMAScript modules. Consider using 'import * as ns from \"mod\"', 'import {a} from \"mod\"', 'import d from \"mod\"', or another module format instead.",
      )
    1203 =>
      Some(
        "Export assignment cannot be used when targeting ECMAScript modules. Consider using 'export default' or another module format instead.",
      )
    1205 =>
      Some(
        "Re-exporting a type when '{0}' is enabled requires using 'export type'.",
      )
    1206 => Some("Decorators are not valid here.")
    1209 =>
      Some(
        "Invalid optional chain from new expression. Did you mean to call '{0}()'?",
      )
    1210 =>
      Some(
        "Code contained in a class is evaluated in JavaScript's strict mode which does not allow this use of '{0}'. For more information, see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Strict_mode.",
      )
    1211 =>
      Some(
        "A class declaration without the 'default' modifier must have a name.",
      )
    1212 =>
      Some("Identifier expected. '{0}' is a reserved word in strict mode.")
    1213 =>
      Some(
        "Identifier expected. '{0}' is a reserved word in strict mode. Class definitions are automatically in strict mode.",
      )
    1214 =>
      Some(
        "Identifier expected. '{0}' is a reserved word in strict mode. Modules are automatically in strict mode.",
      )
    1215 =>
      Some("Invalid use of '{0}'. Modules are automatically in strict mode.")
    1216 =>
      Some(
        "Identifier expected. '__esModule' is reserved as an exported marker when transforming ECMAScript modules.",
      )
    1218 =>
      Some(
        "Export assignment is not supported when '--module' flag is 'system'.",
      )
    1231 =>
      Some(
        "An export assignment must be at the top level of a file or module declaration.",
      )
    1232 =>
      Some(
        "An import declaration can only be used at the top level of a namespace or module.",
      )
    1233 =>
      Some(
        "An export declaration can only be used at the top level of a namespace or module.",
      )
    1234 =>
      Some(
        "An ambient module declaration is only allowed at the top level in a file.",
      )
    1235 =>
      Some(
        "A namespace declaration is only allowed at the top level of a namespace or module.",
      )
    1248 => Some("A class member cannot have the '{0}' keyword.")
    1250 =>
      Some(
        "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'.",
      )
    1251 =>
      Some(
        "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'. Class definitions are automatically in strict mode.",
      )
    1252 =>
      Some(
        "Function declarations are not allowed inside blocks in strict mode when targeting 'ES5'. Modules are automatically in strict mode.",
      )
    1254 =>
      Some(
        "A 'const' initializer in an ambient context must be a string or numeric literal or literal enum reference.",
      )
    1258 =>
      Some(
        "A default export must be at the top level of a file or module declaration.",
      )
    1259 =>
      Some("Module '{0}' can only be default-imported using the '{1}' flag")
    1260 => Some("Keywords cannot contain escape characters.")
    1262 =>
      Some(
        "Identifier expected. '{0}' is a reserved word at the top-level of a module.",
      )
    1264 =>
      Some(
        "Declarations with definite assignment assertions must also have type annotations.",
      )
    1327 => Some("String literal with double quotes expected.")
    1328 =>
      Some(
        "Property value can only be string literal, numeric literal, 'true', 'false', 'null', object literal or array literal.",
      )
    1269 =>
      Some(
        "Cannot use 'export import' on a type or type-only namespace when '{0}' is enabled.",
      )
    1270 =>
      Some(
        "Decorator function return type '{0}' is not assignable to type '{1}'.",
      )
    1271 =>
      Some(
        "Decorator function return type is '{0}' but is expected to be 'void' or 'any'.",
      )
    1274 =>
      Some(
        "'{0}' modifier can only appear on a type parameter of a class, interface or type alias",
      )
    1280 =>
      Some(
        "Namespaces are not allowed in global script files when '{0}' is enabled. If this file is not intended to be a global script, set 'moduleDetection' to 'force' or add an empty 'export {}' statement.",
      )
    1281 =>
      Some(
        "Cannot access '{0}' from another file without qualification when '{1}' is enabled. Use '{2}' instead.",
      )
    1287 =>
      Some(
        "A top-level 'export' modifier cannot be used on value declarations in a CommonJS module when 'verbatimModuleSyntax' is enabled.",
      )
    1292 =>
      Some(
        "'{0}' resolves to a type and must be marked type-only in this file before re-exporting when '{1}' is enabled. Consider using 'export type { {0} as default }'.",
      )
    1294 =>
      Some("This syntax is not allowed when 'erasableSyntaxOnly' is enabled.")
    1295 =>
      Some(
        "ECMAScript imports and exports cannot be written in a CommonJS file under 'verbatimModuleSyntax'. Adjust the 'type' field in the nearest 'package.json' to make this file an ECMAScript module, or adjust your 'verbatimModuleSyntax', 'module', and 'moduleResolution' settings in TypeScript.",
      )
    1300 =>
      Some("'with' statements are not allowed in an async function block.")
    1308 =>
      Some(
        "'await' expressions are only allowed within async functions and at the top levels of modules.",
      )
    1312 =>
      Some(
        "Did you mean to use a ':'? An '=' can only follow a property name when the containing object literal is part of a destructuring pattern.",
      )
    1313 => Some("The body of an 'if' statement cannot be the empty statement.")
    1317 =>
      Some("A parameter property cannot be declared using a rest parameter.")
    1319 =>
      Some("A default export can only be used in an ECMAScript-style module.")
    1320 =>
      Some(
        "Type of 'await' operand must either be a valid promise or must not contain a callable 'then' member.",
      )
    1329 =>
      Some(
        "'{0}' accepts too few arguments to be used as a decorator here. Did you mean to call it first and write '@{0}()'?",
      )
    1340 =>
      Some(
        "Module '{0}' does not refer to a type, but is used as a type here. Did you mean 'typeof import('{0}')'?",
      )
    1345 =>
      Some("An expression of type 'void' cannot be tested for truthiness.")
    1351 =>
      Some(
        "An identifier or keyword cannot immediately follow a numeric literal.",
      )
    1352 => Some("A bigint literal cannot use exponential notation.")
    1353 => Some("A bigint literal must be an integer.")
    1355 =>
      Some(
        "A 'const' assertions can only be applied to references to enum members, or string, number, boolean, array, or object literals.",
      )
    1359 =>
      Some(
        "Identifier expected. '{0}' is a reserved word that cannot be used here.",
      )
    1360 => Some("Type '{0}' does not satisfy the expected type '{1}'.")
    1378 =>
      Some(
        "Top-level 'await' expressions are only allowed when the 'module' option is set to 'es2022', 'esnext', 'system', 'node16', 'node18', 'node20', 'nodenext', or 'preserve', and the 'target' option is set to 'es2017' or higher.",
      )
    1381 => Some("Unexpected token. Did you mean `{'}'}` or `&rbrace;`?")
    1382 => Some("Unexpected token. Did you mean `{'>'}` or `&gt;`?")
    1385 =>
      Some(
        "Function type notation must be parenthesized when used in a union type.",
      )
    1386 =>
      Some(
        "Constructor type notation must be parenthesized when used in a union type.",
      )
    1387 =>
      Some(
        "Function type notation must be parenthesized when used in an intersection type.",
      )
    1388 =>
      Some(
        "Constructor type notation must be parenthesized when used in an intersection type.",
      )
    1389 => Some("'{0}' is not allowed as a variable declaration name.")
    1390 => Some("'{0}' is not allowed as a parameter name.")
    1432 =>
      Some(
        "Top-level 'for await' loops are only allowed when the 'module' option is set to 'es2022', 'esnext', 'system', 'node16', 'node18', 'node20', 'nodenext', or 'preserve', and the 'target' option is set to 'es2017' or higher.",
      )
    1434 => Some("Unexpected keyword or identifier.")
    1435 => Some("Unknown keyword or identifier. Did you mean '{0}'?")
    1437 => Some("Namespace must be given a name.")
    1438 => Some("Interface must be given a name.")
    1440 => Some("Variable declaration not allowed at this location.")
    1448 =>
      Some(
        "'{0}' resolves to a type-only declaration and must be re-exported using a type-only re-export when '{1}' is enabled.",
      )
    1477 =>
      Some(
        "An instantiation expression cannot be followed by a property access.",
      )
    1478 => Some("Identifier or string literal expected.")
    1487 =>
      Some("Octal escape sequences are not allowed. Use the syntax '{0}'.")
    1488 => Some("Escape sequence '{0}' is not allowed.")
    1489 => Some("Decimals with leading zeros are not allowed.")
    1490 => Some("File appears to be binary.")
    1499 => Some("Unknown regular expression flag.")
    1501 =>
      Some(
        "This regular expression flag is only available when targeting '{0}' or later.",
      )
    1503 =>
      Some(
        "Named capturing groups are only available when targeting 'ES2018' or later.",
      )
    1505 => Some("Incomplete quantifier. Digit expected.")
    1506 => Some("Numbers out of order in quantifier.")
    1507 => Some("There is nothing available for repetition.")
    1508 => Some("Unexpected '{0}'. Did you mean to escape it with backslash?")
    1510 =>
      Some(
        "'\\k' must be followed by a capturing group name enclosed in angle brackets.",
      )
    1512 => Some("'\\c' must be followed by an ASCII letter.")
    1516 =>
      Some(
        "A character class range must not be bounded by another character class.",
      )
    1517 => Some("Range out of order in character class.")
    1524 => Some("Unknown Unicode property name.")
    1526 => Some("Unknown Unicode property value.")
    1529 => Some("Unknown Unicode property name or value.")
    1531 =>
      Some(
        "'\\{0}' must be followed by a Unicode property value expression enclosed in braces.",
      )
    1532 =>
      Some(
        "There is no capturing group named '{0}' in this regular expression.",
      )
    1535 => Some("This character cannot be escaped in a regular expression.")
    1538 =>
      Some(
        "Unicode escape sequences are only available when the Unicode (u) flag or the Unicode Sets (v) flag is set.",
      )
    1539 => Some("A 'bigint' literal cannot be used as a property name.")
    2369 =>
      Some(
        "A parameter property is only allowed in a constructor implementation.",
      )
    6188 => Some("Numeric separators are not allowed here.")
    6189 => Some("Multiple consecutive numeric separators are not permitted.")
    7027 => Some("Unreachable code detected.")
    17002 => Some("Expected corresponding JSX closing tag for '{0}'.")
    17008 => Some("JSX element '{0}' has no corresponding closing tag.")
    17014 => Some("JSX fragment has no corresponding closing tag.")
    17015 => Some("Expected corresponding closing tag for JSX fragment.")
    18030 => Some("An optional chain cannot contain private identifiers.")
    _ => None
  }
}

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
