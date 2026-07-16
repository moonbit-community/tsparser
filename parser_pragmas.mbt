// Adapted and modified for MoonBit from Microsoft TypeScript 6.0.3
// src/compiler/parser.ts and src/compiler/types.ts at
// 050880ce59e30b356b686bd3144efe24f875ebc8.
// Licensed under Apache-2.0; see THIRD_PARTY_NOTICES.md.

///|
priv struct PendingPragmaEntry {
  name : String
  occurrences : Array[PragmaOccurrence]
}

///|
fn _pragma_is_space(code_unit : Int) -> Bool {
  is_white_space_like(code_unit)
}

///|
fn _pragma_skip_space(text : SourceText, start : Int, end : Int) -> Int {
  let mut position = start
  while position < end && _pragma_is_space(text.code_unit_at(position)) {
    position += 1
  }
  position
}

///|
fn _pragma_ascii_lower(code_unit : Int) -> Int {
  if code_unit >= CharacterCodes::upper_a() &&
    code_unit <= CharacterCodes::upper_z() {
    code_unit + CharacterCodes::lower_a() - CharacterCodes::upper_a()
  } else {
    code_unit
  }
}

///|
fn _pragma_region_equals_ignore_case(
  text : SourceText,
  start : Int,
  end : Int,
  expected : String,
) -> Bool {
  guard end - start == expected.length() else { return false }
  for index = 0; index < expected.length(); index = index + 1 {
    if _pragma_ascii_lower(text.code_unit_at(start + index)) !=
      _pragma_ascii_lower(expected[index].to_int()) {
      return false
    }
  }
  true
}

///|
fn _pragma_argument(
  name : String,
  value : String,
  value_start? : Int,
  value_end? : Int,
) -> PragmaArgument {
  { name, value, pos: value_start, end: value_end }
}

///|
fn _pragma_find_xml_argument(
  source : SourceText,
  comment_start : Int,
  comment_end : Int,
  name : String,
  capture_span : Bool,
) -> PragmaArgument? {
  let mut position = comment_start
  while position < comment_end {
    guard _pragma_is_space(source.code_unit_at(position)) else {
      position += 1
      continue
    }
    let name_start = _pragma_skip_space(source, position, comment_end)
    let name_end = name_start + name.length()
    if name_end > comment_end ||
      !_pragma_region_equals_ignore_case(source, name_start, name_end, name) {
      position = name_start + 1
      continue
    }
    let equals_position = _pragma_skip_space(source, name_end, comment_end)
    if equals_position >= comment_end ||
      source.code_unit_at(equals_position) != CharacterCodes::equals() {
      position = name_end
      continue
    }
    let quote_position = _pragma_skip_space(
      source,
      equals_position + 1,
      comment_end,
    )
    if quote_position >= comment_end {
      return None
    }
    let quote = source.code_unit_at(quote_position)
    if quote != CharacterCodes::single_quote() &&
      quote != CharacterCodes::double_quote() {
      position = quote_position + 1
      continue
    }
    let value_start = quote_position + 1
    let mut value_end = value_start
    while value_end < comment_end && source.code_unit_at(value_end) != quote {
      value_end += 1
    }
    if value_end >= comment_end {
      return None
    }
    let value = source.substring(value_start, end=value_end)
    return if capture_span {
      Some(_pragma_argument(name, value, value_start~, value_end~))
    } else {
      Some(_pragma_argument(name, value))
    }
  }
  None
}

///|
fn _pragma_occurrence(
  arguments : Array[PragmaArgument],
  range : CommentRange,
) -> PragmaOccurrence {
  { arguments: ReadOnlyArray::from_array(arguments), range }
}

///|
fn _extract_xml_pragma(
  source : SourceText,
  range : CommentRange,
) -> (String, PragmaOccurrence)? {
  guard range.kind().to_int() == 2 && range.end() - range.pos() >= 4 else {
    return None
  }
  let start = range.pos()
  guard source.code_unit_at(start) == CharacterCodes::slash() &&
    source.code_unit_at(start + 1) == CharacterCodes::slash() &&
    source.code_unit_at(start + 2) == CharacterCodes::slash() else {
    return None
  }
  let mut position = _pragma_skip_space(source, start + 3, range.end())
  guard position < range.end() &&
    source.code_unit_at(position) == CharacterCodes::less_than() else {
    return None
  }
  position += 1
  let name_start = position
  while position < range.end() &&
        !_pragma_is_space(source.code_unit_at(position)) {
    position += 1
  }
  guard position > name_start && position < range.end() else { return None }
  let name = source.substring(name_start, end=position).to_lower()
  let mut has_close = false
  for index = position; index + 1 < range.end(); index = index + 1 {
    if source.code_unit_at(index) == CharacterCodes::slash() &&
      source.code_unit_at(index + 1) == CharacterCodes::greater_than() {
      has_close = true
      break
    }
  }
  guard has_close else { return None }
  let arguments : Array[PragmaArgument] = []
  match name {
    "reference" =>
      for
        specification in [
          ("types", true),
          ("lib", true),
          ("path", true),
          ("no-default-lib", false),
          ("resolution-mode", false),
          ("preserve", false),
        ] {
        let (argument_name, capture_span) = specification
        match
          _pragma_find_xml_argument(
            source,
            position,
            range.end(),
            argument_name,
            capture_span,
          ) {
          Some(argument) => arguments.push(argument)
          None => ()
        }
      }
    "amd-dependency" => {
      match
        _pragma_find_xml_argument(source, position, range.end(), "path", false) {
        Some(path) => arguments.push(path)
        None => return None
      }
      match
        _pragma_find_xml_argument(source, position, range.end(), "name", false) {
        Some(name) => arguments.push(name)
        None => ()
      }
    }
    "amd-module" =>
      match
        _pragma_find_xml_argument(source, position, range.end(), "name", false) {
        Some(module_name) => arguments.push(module_name)
        None => return None
      }
    _ => return None
  }
  Some((name, _pragma_occurrence(arguments, range)))
}

///|
fn _extract_single_line_pragma(
  source : SourceText,
  range : CommentRange,
) -> (String, PragmaOccurrence)? {
  guard range.kind().to_int() == 2 && range.end() - range.pos() >= 3 else {
    return None
  }
  let start = range.pos()
  guard source.code_unit_at(start) == CharacterCodes::slash() &&
    source.code_unit_at(start + 1) == CharacterCodes::slash() else {
    return None
  }
  let mut position = start + 2
  if position < range.end() &&
    source.code_unit_at(position) == CharacterCodes::slash() {
    position += 1
  }
  position = _pragma_skip_space(source, position, range.end())
  guard position < range.end() &&
    source.code_unit_at(position) == CharacterCodes::at() else {
    return None
  }
  position += 1
  let name_start = position
  while position < range.end() &&
        !_pragma_is_space(source.code_unit_at(position)) &&
        source.code_unit_at(position) != CharacterCodes::colon() {
    position += 1
  }
  guard position > name_start else { return None }
  let name = source.substring(name_start, end=position).to_lower()
  guard name == "ts-check" || name == "ts-nocheck" else { return None }
  Some((name, _pragma_occurrence([], range)))
}

///|
fn _extract_multiline_pragmas(
  source : SourceText,
  range : CommentRange,
  output : Array[(String, PragmaOccurrence)],
) -> Unit {
  guard range.kind().to_int() == 3 else { return }
  let mut line_start = range.pos()
  while line_start < range.end() {
    let mut line_end = line_start
    while line_end < range.end() &&
          source.code_unit_at(line_end) != CharacterCodes::carriage_return() &&
          source.code_unit_at(line_end) != CharacterCodes::line_feed() {
      line_end += 1
    }
    let mut at = line_start
    while at < line_end && source.code_unit_at(at) != CharacterCodes::at() {
      at += 1
    }
    if at < line_end {
      let name_start = at + 1
      let mut name_end = name_start
      while name_end < line_end &&
            !_pragma_is_space(source.code_unit_at(name_end)) {
        name_end += 1
      }
      if name_end > name_start {
        let name = source.substring(name_start, end=name_end).to_lower()
        if name == "jsx" ||
          name == "jsxfrag" ||
          name == "jsximportsource" ||
          name == "jsxruntime" {
          let argument_start = _pragma_skip_space(source, name_end, line_end)
          if argument_start < line_end {
            let mut argument_end = argument_start
            while argument_end < line_end &&
                  !_pragma_is_space(source.code_unit_at(argument_end)) {
              argument_end += 1
            }
            let argument = _pragma_argument(
              "factory",
              source.substring(argument_start, end=argument_end),
            )
            output.push((name, _pragma_occurrence([argument], range)))
          }
        }
      }
    }
    if line_end < range.end() &&
      source.code_unit_at(line_end) == CharacterCodes::carriage_return() &&
      source.code_unit_at(line_end + 1) == CharacterCodes::line_feed() {
      line_end += 1
    }
    line_start = line_end + 1
  }
}

///|
fn _group_pragmas(
  flat : Array[(String, PragmaOccurrence)],
) -> ReadOnlyArray[PragmaEntry] {
  let pending : Array[PendingPragmaEntry] = []
  let indexes : Map[String, Int] = Map([])
  for item in flat {
    let (name, occurrence) = item
    match indexes.get(name) {
      Some(index) => pending[index].occurrences.push(occurrence)
      None => {
        indexes[name] = pending.length()
        pending.push({ name, occurrences: [occurrence] })
      }
    }
  }
  let result : Array[PragmaEntry] = []
  for entry in pending {
    result.push({
      name: entry.name,
      occurrences: ReadOnlyArray::from_array(entry.occurrences),
    })
  }
  ReadOnlyArray::from_array(result)
}

///|
fn _process_comment_pragmas(source_text : String) -> ReadOnlyArray[PragmaEntry] {
  let source = SourceText::new(source_text)
  let flat : Array[(String, PragmaOccurrence)] = []
  match get_leading_comment_ranges(source, 0) {
    Some(ranges) =>
      for range in ranges {
        match _extract_xml_pragma(source, range) {
          Some(pragma) => flat.push(pragma)
          None =>
            match _extract_single_line_pragma(source, range) {
              Some(pragma) => flat.push(pragma)
              None => _extract_multiline_pragmas(source, range, flat)
            }
        }
      }
    None => ()
  }
  _group_pragmas(flat)
}

///|
fn _pragma_get_argument(
  occurrence : PragmaOccurrence,
  name : String,
) -> PragmaArgument? {
  for argument in occurrence.arguments() {
    if argument.name() == name {
      return Some(argument)
    }
  }
  None
}

///|
fn ParserState::_report_pragma_diagnostic(
  self : ParserState,
  start : Int,
  length : Int,
  message : DiagnosticMessage,
) -> Unit {
  self.diagnostics.push(
    _create_detached_diagnostic(
      self.file_name,
      self.source_text,
      start,
      length,
      message,
      _no_diagnostic_arguments(),
    ),
  )
}

///|
fn ParserState::_parse_pragma_resolution_mode(
  self : ParserState,
  value : String?,
  diagnostic_range : PragmaArgument,
) -> ResolutionMode? {
  match value {
    None => None
    Some("import") => Some(ResolutionMode::es_next())
    Some("require") => Some(ResolutionMode::common_js())
    Some(_) => {
      let start = diagnostic_range.pos().unwrap()
      let end = diagnostic_range.end().unwrap()
      self._report_pragma_diagnostic(
        start,
        end - start,
        _diagnostic_message(1453),
      )
      None
    }
  }
}

///|
fn ParserState::_file_reference_from_pragma(
  self : ParserState,
  argument : PragmaArgument,
  resolution_mode_text : String?,
  preserve : Bool?,
) -> FileReference {
  let resolution_mode = self._parse_pragma_resolution_mode(
    resolution_mode_text, argument,
  )
  {
    file_name: argument.value(),
    pos: argument.pos().unwrap(),
    end: argument.end().unwrap(),
    resolution_mode,
    preserve,
  }
}

///|
fn ParserState::_process_pragmas_into_fields(
  self : ParserState,
  source_file : Node,
  pragmas : ReadOnlyArray[PragmaEntry],
) -> Unit {
  let referenced_files : Array[FileReference] = []
  let type_references : Array[FileReference] = []
  let lib_references : Array[FileReference] = []
  let amd_dependencies : Array[AmdDependency] = []
  let mut check_js : CheckJsDirective? = None
  let mut module_name : String? = None
  for entry in pragmas {
    match entry.name() {
      "reference" =>
        for occurrence in entry.occurrences() {
          let preserve = match _pragma_get_argument(occurrence, "preserve") {
            Some(value) if value.value() == "true" => Some(true)
            _ => None
          }
          let no_default_lib = match
            _pragma_get_argument(occurrence, "no-default-lib") {
            Some(value) => value.value() == "true"
            None => false
          }
          if !no_default_lib {
            let resolution_mode = _pragma_get_argument(
              occurrence, "resolution-mode",
            ).map(fn(argument) { argument.value() })
            match _pragma_get_argument(occurrence, "types") {
              Some(argument) =>
                type_references.push(
                  self._file_reference_from_pragma(
                    argument, resolution_mode, preserve,
                  ),
                )
              None =>
                match _pragma_get_argument(occurrence, "lib") {
                  Some(argument) => {
                    let reference = self._file_reference_from_pragma(
                      argument,
                      None,
                      preserve,
                    )
                    lib_references.push(reference)
                  }
                  None =>
                    match _pragma_get_argument(occurrence, "path") {
                      Some(argument) => {
                        let reference = self._file_reference_from_pragma(
                          argument,
                          None,
                          preserve,
                        )
                        referenced_files.push(reference)
                      }
                      None => {
                        let range = occurrence.range()
                        self._report_pragma_diagnostic(
                          range.pos(),
                          range.end() - range.pos(),
                          _diagnostic_message(1084),
                        )
                      }
                    }
                }
            }
          }
        }
      "amd-dependency" =>
        for occurrence in entry.occurrences() {
          let path = _pragma_get_argument(occurrence, "path").unwrap().value()
          let name = _pragma_get_argument(occurrence, "name").map(fn(argument) {
            argument.value()
          })
          amd_dependencies.push({ name, path })
        }
      "amd-module" =>
        for occurrence in entry.occurrences() {
          let range = occurrence.range()
          if module_name is Some(existing) && existing != "" {
            self._report_pragma_diagnostic(
              range.pos(),
              range.end() - range.pos(),
              _diagnostic_message(2458),
            )
          }
          module_name = Some(
            _pragma_get_argument(occurrence, "name").unwrap().value(),
          )
        }
      "ts-check" | "ts-nocheck" =>
        for occurrence in entry.occurrences() {
          let range = occurrence.range()
          match check_js {
            Some(current) if range.pos() <= current.pos() => ()
            _ =>
              check_js = Some({
                enabled: entry.name() == "ts-check",
                pos: range.pos(),
                end: range.end(),
              })
          }
        }
      "jsx" | "jsxfrag" | "jsximportsource" | "jsxruntime" => ()
      _ => abort("unhandled pragma kind")
    }
  }
  _parser_set_node_field(source_file, "pragmas", PragmaMapValue(Some(pragmas)))
  _parser_set_node_field(
    source_file,
    "checkJsDirective",
    CheckJsDirectiveValue(check_js),
  )
  _parser_set_node_field(
    source_file,
    "referencedFiles",
    FileReferenceList(Some(ReadOnlyArray::from_array(referenced_files))),
  )
  _parser_set_node_field(
    source_file,
    "typeReferenceDirectives",
    FileReferenceList(Some(ReadOnlyArray::from_array(type_references))),
  )
  _parser_set_node_field(
    source_file,
    "libReferenceDirectives",
    FileReferenceList(Some(ReadOnlyArray::from_array(lib_references))),
  )
  _parser_set_node_field(
    source_file,
    "amdDependencies",
    AmdDependencyList(Some(ReadOnlyArray::from_array(amd_dependencies))),
  )
  match module_name {
    Some(module_name) =>
      _parser_add_node_field(source_file, "moduleName", Text(Some(module_name)))
    None => ()
  }
}
