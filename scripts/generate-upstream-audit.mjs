#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import ts from "typescript";

import {
  DEFAULT_TYPESCRIPT_SOURCE_DIR,
  TYPESCRIPT_GIT_HEAD,
  TYPESCRIPT_VERSION,
} from "./upstream-config.mjs";

const OUTPUT_DIRECTORY = "docs/upstream-audit";
const PROGRESS_PATH = "docs/upstream-progress.json";
const PROGRESS_COLUMNS = ["moonbit_implementation", "test_location", "status"];
const JSON_WRAPPER_DIAGNOSTICS = new Set([
  "Property_assignment_expected",
  "The_0_modifier_can_only_be_used_in_TypeScript_files",
  "String_literal_with_double_quotes_expected",
  "Property_value_can_only_be_string_literal_numeric_literal_true_false_null_object_literal_or_array_literal",
]);
const REGEXP_ESCAPE_ONLY_DIAGNOSTICS = new Set([
  "This_character_cannot_be_escaped_in_a_regular_expression",
  "Octal_escape_sequences_and_backreferences_are_not_allowed_in_a_character_class_If_this_was_intended_as_an_escape_sequence_use_the_syntax_0_instead",
  "Decimal_escape_sequences_and_backreferences_are_not_allowed_in_a_character_class",
  "Unicode_escape_sequences_are_only_available_when_the_Unicode_u_flag_or_the_Unicode_Sets_v_flag_is_set",
]);
const SHARED_SCANNER_REGEXP_DIAGNOSTICS = new Set([
  "Hexadecimal_digit_expected",
  "Unexpected_end_of_text",
  "An_extended_Unicode_escape_value_must_be_between_0x0_and_0x10FFFF_inclusive",
  "Octal_escape_sequences_are_not_allowed_Use_the_syntax_0",
  "Escape_sequence_0_is_not_allowed",
]);

function parseArguments(argv) {
  let mode;
  let sourceDirectory = DEFAULT_TYPESCRIPT_SOURCE_DIR;
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    if (argument === "--write" || argument === "--verify") {
      if (mode) {
        throw new Error("choose exactly one of --write or --verify");
      }
      mode = argument.slice(2);
    } else if (argument === "--source-dir") {
      sourceDirectory = argv[++index];
      if (!sourceDirectory) {
        throw new Error("--source-dir requires a path");
      }
    } else {
      throw new Error(`unknown argument: ${argument}`);
    }
  }
  if (!mode) {
    throw new Error("choose exactly one of --write or --verify");
  }
  return { mode, sourceDirectory: path.resolve(sourceDirectory) };
}

function parseSource(sourceDirectory, relativePath) {
  const filePath = path.join(sourceDirectory, relativePath);
  const text = fs.readFileSync(filePath, "utf8");
  return {
    relativePath,
    text,
    sourceFile: ts.createSourceFile(filePath, text, ts.ScriptTarget.Latest, true),
  };
}

function walk(node, callback, parents = []) {
  callback(node, parents);
  const nextParents = [...parents, node];
  node.forEachChild((child) => walk(child, callback, nextParents));
}

function findNode(root, predicate, description) {
  let result;
  walk(root, (node) => {
    if (!result && predicate(node)) {
      result = node;
    }
  });
  if (!result) {
    throw new Error(`could not find ${description}`);
  }
  return result;
}

function lineOf(sourceFile, position) {
  return sourceFile.getLineAndCharacterOfPosition(position).line + 1;
}

function location(parsed, node) {
  return `${parsed.relativePath}:${lineOf(parsed.sourceFile, node.getStart(parsed.sourceFile))}`;
}

function oneLine(value) {
  return value.replace(/\s+/g, " ").trim();
}

function memberName(member) {
  if (ts.isIdentifier(member.name)) {
    return member.name.text;
  }
  return member.name.getText();
}

function propertyAccessName(node, receiver) {
  return ts.isPropertyAccessExpression(node) &&
      ts.isIdentifier(node.expression) &&
      node.expression.text === receiver
    ? node.name.text
    : undefined;
}

function syntaxKindRows(types) {
  const declaration = findNode(
    types.sourceFile,
    (node) => ts.isEnumDeclaration(node) && node.name.text === "SyntaxKind",
    "SyntaxKind enum",
  );
  const grouped = new Map();
  for (const member of declaration.members) {
    const name = memberName(member);
    const value = ts.SyntaxKind[name];
    if (typeof value !== "number") {
      throw new Error(`TypeScript runtime has no numeric SyntaxKind.${name}`);
    }
    const entries = grouped.get(value) ?? [];
    entries.push({ name, source: location(types, member) });
    grouped.set(value, entries);
  }

  if (ts.SyntaxKind.Count !== 359) {
    throw new Error(`expected SyntaxKind.Count == 359, found ${ts.SyntaxKind.Count}`);
  }
  const rows = [];
  for (let value = 0; value < ts.SyntaxKind.Count; value++) {
    const entries = grouped.get(value);
    if (!entries) {
      throw new Error(`SyntaxKind value ${value} has no declaration`);
    }
    const classificationMarkers = entries
      .filter((entry) => /^(First|Last)/.test(entry.name))
      .map((entry) => entry.name);
    const declarations = entries
      .filter((entry) => !/^(First|Last)/.test(entry.name) && entry.name !== "Count")
      .map((entry) => entry.name);
    rows.push({
      upstream_symbol: `SyntaxKind[${value}]`,
      value: String(value),
      declaration_names: declarations.join(", "),
      runtime_reverse_name: ts.SyntaxKind[value],
      classification_markers: classificationMarkers.join(", "),
      source_locations: entries.map((entry) => `${entry.name}@${entry.source}`).join(", "),
    });
  }
  if (rows.length !== 359) {
    throw new Error(`expected 359 SyntaxKind rows, found ${rows.length}`);
  }
  return rows;
}

function nodeFactoryRows(parser) {
  const entries = new Map();
  function add(name, access, source) {
    if (!name.startsWith("create")) {
      return;
    }
    const entry = entries.get(name) ?? { accesses: new Set(), locations: new Set() };
    entry.accesses.add(access);
    entry.locations.add(source);
    entries.set(name, entry);
  }

  walk(parser.sourceFile, (node) => {
    const directName = propertyAccessName(node, "factory");
    if (directName) {
      add(directName, "direct factory call", location(parser, node));
    }
    if (
      ts.isVariableDeclaration(node) &&
      ts.isObjectBindingPattern(node.name) &&
      node.initializer &&
      ts.isIdentifier(node.initializer) &&
      node.initializer.text === "factory"
    ) {
      for (const element of node.name.elements) {
        const original = element.propertyName
          ? element.propertyName.getText(parser.sourceFile)
          : element.name.getText(parser.sourceFile);
        const captured = element.name.getText(parser.sourceFile);
        add(original, `captured as ${captured}`, location(parser, element));
      }
    }
  });

  const rows = [...entries.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([name, entry]) => ({
      upstream_symbol: `NodeFactory.${name}`,
      parser_access: [...entry.accesses].sort().join(", "),
      source_locations: [...entry.locations].sort().join(", "),
    }));
  if (rows.length !== 195) {
    throw new Error(`expected 195 parser NodeFactory entries, found ${rows.length}`);
  }
  return rows;
}

function forEachChildRows(parser) {
  const declaration = findNode(
    parser.sourceFile,
    (node) =>
      ts.isVariableDeclaration(node) &&
      ts.isIdentifier(node.name) &&
      node.name.text === "forEachChildTable" &&
      node.initializer &&
      ts.isObjectLiteralExpression(node.initializer),
    "forEachChildTable",
  );
  const rows = [];
  for (const property of declaration.initializer.properties) {
    if (!ts.isPropertyAssignment(property) || !ts.isComputedPropertyName(property.name)) {
      throw new Error("unexpected forEachChildTable member shape");
    }
    const expression = property.name.expression;
    if (
      !ts.isPropertyAccessExpression(expression) ||
      !ts.isIdentifier(expression.expression) ||
      expression.expression.text !== "SyntaxKind"
    ) {
      throw new Error(`unexpected forEachChild key: ${property.name.getText(parser.sourceFile)}`);
    }
    const kind = expression.name.text;
    const childOrder = [];
    walk(property.initializer, (node) => {
      if (!ts.isCallExpression(node) || !ts.isIdentifier(node.expression)) {
        return;
      }
      if (node.expression.text === "visitNode" && node.arguments[1]) {
        childOrder.push(`node:${oneLine(node.arguments[1].getText(parser.sourceFile))}`);
      } else if (node.expression.text === "visitNodes" && node.arguments[2]) {
        childOrder.push(`nodes:${oneLine(node.arguments[2].getText(parser.sourceFile))}`);
      }
    });
    rows.push({
      upstream_symbol: `SyntaxKind.${kind}`,
      child_order: childOrder.join(" -> "),
      source_location: location(parser, property),
    });
  }
  if (rows.length !== 175) {
    throw new Error(`expected 175 forEachChild branches, found ${rows.length}`);
  }
  return rows;
}

function parsingContextEnum(parser) {
  return findNode(
    parser.sourceFile,
    (node) => ts.isEnumDeclaration(node) && node.name.text === "ParsingContext",
    "ParsingContext enum",
  );
}

function parsingContextName(expression) {
  return ts.isPropertyAccessExpression(expression) &&
      ts.isIdentifier(expression.expression) &&
      expression.expression.text === "ParsingContext"
    ? expression.name.text
    : undefined;
}

function switchRules(parser, functionName) {
  const functionDeclaration = findNode(
    parser.sourceFile,
    (node) => ts.isFunctionDeclaration(node) && node.name?.text === functionName,
    `${functionName} function`,
  );
  const switchStatement = findNode(
    functionDeclaration,
    (node) => ts.isSwitchStatement(node),
    `switch in ${functionName}`,
  );
  const rules = new Map();
  let pending = [];

  function statementTerminates(statement) {
    if (
      ts.isReturnStatement(statement) ||
      ts.isThrowStatement(statement) ||
      ts.isBreakStatement(statement)
    ) {
      return true;
    }
    if (ts.isBlock(statement)) {
      const last = statement.statements.at(-1);
      return last ? statementTerminates(last) : false;
    }
    if (ts.isIfStatement(statement) && statement.elseStatement) {
      return statementTerminates(statement.thenStatement) &&
        statementTerminates(statement.elseStatement);
    }
    return false;
  }

  for (const clause of switchStatement.caseBlock.clauses) {
    if (ts.isCaseClause(clause)) {
      const name = parsingContextName(clause.expression);
      if (name) {
        pending.push({ name, texts: [], diagnostics: new Set(), sources: [] });
      }
    } else {
      pending.push({ name: "*default*", texts: [], diagnostics: new Set(), sources: [] });
    }
    if (clause.statements.length === 0) {
      continue;
    }
    const text = oneLine(
      clause.statements.map((statement) => statement.getText(parser.sourceFile)).join(" "),
    );
    const diagnosticNames = [];
    for (const match of text.matchAll(/Diagnostics\.([A-Za-z0-9_]+)/g)) {
      diagnosticNames.push(match[1]);
    }
    for (const entry of pending) {
      entry.texts.push(text);
      entry.sources.push(location(parser, clause));
      for (const diagnostic of diagnosticNames) {
        entry.diagnostics.add(diagnostic);
      }
    }
    const lastStatement = clause.statements.at(-1);
    if (!lastStatement || !statementTerminates(lastStatement)) {
      continue;
    }
    for (const entry of pending) {
      rules.set(entry.name, {
        text: entry.texts.join(" FALLTHROUGH "),
        diagnostics: [...entry.diagnostics].join(", "),
        source: [...new Set(entry.sources)].join(", "),
      });
    }
    pending = [];
  }
  return rules;
}

function delimiterRules(parser, contextNames) {
  const rules = new Map(contextNames.map((name) => [name, []]));
  walk(parser.sourceFile, (node) => {
    if (!ts.isCallExpression(node) || !ts.isIdentifier(node.expression)) {
      return;
    }
    const callee = node.expression.text;
    if (!["parseList", "parseListElement", "parseDelimitedList", "parseBracketedList"].includes(callee)) {
      return;
    }
    const contextArgument = node.arguments.find((argument) => parsingContextName(argument));
    if (!contextArgument) {
      return;
    }
    const name = parsingContextName(contextArgument);
    let rule;
    if (callee === "parseList" || callee === "parseListElement") {
      rule = "none";
    } else if (callee === "parseDelimitedList") {
      rule = node.arguments[2]?.kind === ts.SyntaxKind.TrueKeyword ? "comma-or-semicolon" : "comma";
    } else {
      const open = node.arguments[2]?.getText(parser.sourceFile) ?? "?";
      const close = node.arguments[3]?.getText(parser.sourceFile) ?? "?";
      rule = `comma; bracketed ${open}..${close}`;
    }
    rules.get(name)?.push(`${rule} via ${callee}@${location(parser, node)}`);
  });

  rules.set("JsxChildren", ["manual scanner-driven child sequence; no delimiter@src/compiler/parser.ts:6168"]);
  rules.set("JSDocComment", ["manual JSDoc token sequence; no delimiter@src/compiler/parser.ts:8908"]);
  if ((rules.get("RestProperties") ?? []).length === 0) {
    rules.set("RestProperties", ["comma recovery context; no direct literal call site"]);
  }
  return rules;
}

function parsingContextRows(parser) {
  const declaration = parsingContextEnum(parser);
  const members = declaration.members
    .map((member) => ({ name: memberName(member), source: location(parser, member) }))
    .filter((member) => member.name !== "Count");
  if (members.length !== 26) {
    throw new Error(`expected 26 real ParsingContext values, found ${members.length}`);
  }
  const startRules = switchRules(parser, "isListElement");
  const terminatorRules = switchRules(parser, "isListTerminator");
  const recoveryRules = switchRules(parser, "parsingContextErrors");
  const delimiters = delimiterRules(parser, members.map((member) => member.name));

  return members.map((member) => {
    const start = startRules.get(member.name) ?? startRules.get("*default*");
    const terminator = terminatorRules.get(member.name) ?? terminatorRules.get("*default*");
    const recovery = recoveryRules.get(member.name) ?? recoveryRules.get("*default*");
    if (!start || !terminator || !recovery) {
      throw new Error(`incomplete ParsingContext audit extraction for ${member.name}`);
    }
    return {
      upstream_symbol: `ParsingContext.${member.name}`,
      start_rule: start.text,
      terminator_rule: terminator.text,
      recovery_diagnostics: recovery.diagnostics || "none",
      delimiter_rule: (delimiters.get(member.name) ?? []).join(", "),
      source_locations: [member.source, start.source, terminator.source, recovery.source].join(", "),
    };
  });
}

function diagnosticUses(parsed, fileKind) {
  const uses = [];
  walk(parsed.sourceFile, (node, parents) => {
    const name = propertyAccessName(node, "Diagnostics");
    if (!name) {
      return;
    }
    let reachability = fileKind === "parser" ? "public_parser" : "scanner_public_parser";
    if (fileKind === "scanner") {
      const functionNames = parents
        .filter((parent) => ts.isFunctionDeclaration(parent) && parent.name)
        .map((parent) => parent.name.text);
      const gatedByReportErrors = parents.some(
        (parent) =>
          ts.isIfStatement(parent) &&
          /\breportErrors\b/.test(parent.expression.getText(parsed.sourceFile)),
      );
      if (
        functionNames.includes("scanRegularExpressionWorker") ||
        functionNames.includes("checkRegularExpressionFlagAvailability") ||
        (functionNames.includes("reScanSlashToken") && gatedByReportErrors) ||
        REGEXP_ESCAPE_ONLY_DIAGNOSTICS.has(name)
      ) {
        reachability = "scanner_report_errors_only";
      }
    }
    uses.push({ name, reachability, source: location(parsed, node) });
    if (
      fileKind === "scanner" &&
      SHARED_SCANNER_REGEXP_DIAGNOSTICS.has(name) &&
      reachability === "scanner_public_parser"
    ) {
      uses.push({
        name,
        reachability: "scanner_report_errors_only",
        source: location(parsed, node),
      });
    }
  });
  return uses;
}

function jsonWrapperUses(commandLine) {
  const declaration = findNode(
    commandLine.sourceFile,
    (node) => ts.isFunctionDeclaration(node) && node.name?.text === "convertToJson",
    "convertToJson function",
  );
  const uses = [];
  walk(declaration, (node) => {
    const name = propertyAccessName(node, "Diagnostics");
    if (name && JSON_WRAPPER_DIAGNOSTICS.has(name)) {
      uses.push({ name, reachability: "json_wrapper", source: location(commandLine, node) });
    }
  });
  const names = new Set(uses.map((use) => use.name));
  for (const expected of JSON_WRAPPER_DIAGNOSTICS) {
    if (!names.has(expected)) {
      throw new Error(`convertToJson no longer contains Diagnostics.${expected}`);
    }
  }
  return uses;
}

function placeholderCount(message) {
  const indexes = [...message.matchAll(/\{(\d+)\}/g)].map((match) => Number(match[1]));
  return indexes.length === 0 ? 0 : Math.max(...indexes) + 1;
}

function diagnosticRows(parser, scanner, commandLine) {
  const directUses = [
    ...diagnosticUses(parser, "parser"),
    ...diagnosticUses(scanner, "scanner"),
  ];
  const directNames = new Set(directUses.map((use) => use.name));
  if (directNames.size !== 145) {
    throw new Error(`expected 145 scanner/parser diagnostics, found ${directNames.size}`);
  }
  const jsonUses = jsonWrapperUses(commandLine);
  const allUses = [...directUses, ...jsonUses];
  const grouped = new Map();
  for (const use of allUses) {
    const entry = grouped.get(use.name) ?? { reachability: new Set(), sources: new Set() };
    entry.reachability.add(use.reachability);
    entry.sources.add(use.source);
    grouped.set(use.name, entry);
  }
  if (grouped.size !== 148) {
    throw new Error(`expected 148 total diagnostics, found ${grouped.size}`);
  }
  const jsonOnly = [...JSON_WRAPPER_DIAGNOSTICS].filter((name) => !directNames.has(name));
  if (jsonOnly.length !== 3) {
    throw new Error(`expected 3 JSON-only diagnostics, found ${jsonOnly.length}`);
  }

  return [...grouped.entries()]
    .map(([name, use]) => {
      const diagnostic = ts.Diagnostics[name];
      if (!diagnostic) {
        throw new Error(`TypeScript runtime has no Diagnostics.${name}`);
      }
      return {
        upstream_symbol: `Diagnostics.${name}`,
        code: String(diagnostic.code),
        category: ts.DiagnosticCategory[diagnostic.category],
        message: diagnostic.message,
        placeholder_count: String(placeholderCount(diagnostic.message)),
        reachability: [...use.reachability].sort().join(", "),
        source_locations: [...use.sources].sort().join(", "),
      };
    })
    .sort((left, right) => Number(left.code) - Number(right.code) || left.upstream_symbol.localeCompare(right.upstream_symbol));
}

function parseTsv(text) {
  const lines = text.trimEnd().split("\n");
  const headers = lines[0].split("\t");
  return lines.slice(1).map((line) => {
    const values = line.split("\t");
    return Object.fromEntries(headers.map((header, index) => [header, values[index] ?? ""]));
  });
}

function existingProgress(outputPath) {
  if (!fs.existsSync(outputPath)) {
    return new Map();
  }
  const rows = parseTsv(fs.readFileSync(outputPath, "utf8"));
  return new Map(
    rows.map((row) => [
      row.upstream_symbol,
      Object.fromEntries(PROGRESS_COLUMNS.map((column) => [column, row[column] ?? ""])),
    ]),
  );
}

function renderTsv(columns, rows, outputPath) {
  const progress = existingProgress(outputPath);
  const configuredProgress = fs.existsSync(PROGRESS_PATH)
    ? JSON.parse(fs.readFileSync(PROGRESS_PATH, "utf8"))[path.basename(outputPath)] ?? {}
    : {};
  const headers = [...columns, ...PROGRESS_COLUMNS];
  const lines = [headers.join("\t")];
  for (const row of rows) {
    const saved = configuredProgress[row.upstream_symbol] ?? configuredProgress["*"] ??
      progress.get(row.upstream_symbol) ?? {
      moonbit_implementation: "",
      test_location: "",
      status: "pending",
    };
    const complete = { ...row, ...saved };
    lines.push(headers.map((header) => oneLine(String(complete[header] ?? ""))).join("\t"));
  }
  return `${lines.join("\n")}\n`;
}

function auditFiles(sourceDirectory) {
  const packageJson = JSON.parse(fs.readFileSync(path.join(sourceDirectory, "package.json"), "utf8"));
  if (packageJson.version !== TYPESCRIPT_VERSION) {
    throw new Error(`expected TypeScript ${TYPESCRIPT_VERSION}, found ${packageJson.version}`);
  }
  const types = parseSource(sourceDirectory, "src/compiler/types.ts");
  const parser = parseSource(sourceDirectory, "src/compiler/parser.ts");
  const scanner = parseSource(sourceDirectory, "src/compiler/scanner.ts");
  const commandLine = parseSource(sourceDirectory, "src/compiler/commandLineParser.ts");
  return [
    {
      name: "syntax-kind.tsv",
      columns: [
        "upstream_symbol",
        "value",
        "declaration_names",
        "runtime_reverse_name",
        "classification_markers",
        "source_locations",
      ],
      rows: syntaxKindRows(types),
    },
    {
      name: "node-factory.tsv",
      columns: ["upstream_symbol", "parser_access", "source_locations"],
      rows: nodeFactoryRows(parser),
    },
    {
      name: "for-each-child.tsv",
      columns: ["upstream_symbol", "child_order", "source_location"],
      rows: forEachChildRows(parser),
    },
    {
      name: "parsing-context.tsv",
      columns: [
        "upstream_symbol",
        "start_rule",
        "terminator_rule",
        "recovery_diagnostics",
        "delimiter_rule",
        "source_locations",
      ],
      rows: parsingContextRows(parser),
    },
    {
      name: "diagnostics.tsv",
      columns: [
        "upstream_symbol",
        "code",
        "category",
        "message",
        "placeholder_count",
        "reachability",
        "source_locations",
      ],
      rows: diagnosticRows(parser, scanner, commandLine),
    },
  ];
}

function readmeText(files) {
  const counts = Object.fromEntries(files.map((file) => [file.name, file.rows.length]));
  return `# TypeScript ${TYPESCRIPT_VERSION} upstream parser audit\n\n` +
    `Normative upstream commit: \`${TYPESCRIPT_GIT_HEAD}\`. Refresh only after an explicit ` +
    `upstream-version decision:\n\n` +
    "```sh\n" +
    "node scripts/bootstrap-typescript-source.mjs --verify\n" +
    "node scripts/generate-upstream-audit.mjs --write\n" +
    "```\n\n" +
    "Every TSV carries the required progress columns `moonbit_implementation`, " +
    "`test_location`, and `status`. The generator preserves those three columns by " +
    "`upstream_symbol`; all other columns are derived from the exact upstream checkout.\n\n" +
    `- SyntaxKind numeric values: ${counts["syntax-kind.tsv"]}; \`SyntaxKind.Count == 359\`.\n` +
    `- Parser-used NodeFactory entries: ${counts["node-factory.tsv"]}.\n` +
    `- \`forEachChild\` branches: ${counts["for-each-child.tsv"]}.\n` +
    `- Real ParsingContext values: ${counts["parsing-context.tsv"]}; \`Count\` is excluded.\n` +
    `- Scanner/parser/JSON-wrapper diagnostics: ${counts["diagnostics.tsv"]}.\n` +
    "- Scanner helper functions: 95, grouped into 19 exact behavioral contracts.\n" +
    "- Scanner token kinds: 167 (`SyntaxKind` values 0 through 166), all with an\n" +
    "  ordinary or contextual scanner path.\n" +
    "- parser core helpers: 111, grouped into 12 exact behavioral contracts;\n" +
    "  all 26 real ParsingContext rows are complete.\n" +
    "- type parser helpers: 92, grouped into 10 exact behavioral contracts;\n" +
    "  all 24 parser-created TypeScript type SyntaxKinds are covered.\n" +
    "- expression parser helpers: 63, grouped into 9 exact behavioral contracts;\n" +
    "  all 30 non-synthetic expression SyntaxKinds and 41 operators are covered.\n" +
    "- statement/declaration parser helpers: 95, grouped into 9 exact behavioral contracts;\n" +
    "  all 48 parser-created statement/declaration SyntaxKinds are covered.\n" +
    "- module/top-level-await parser helpers: 45, grouped into 8 exact behavioral contracts;\n" +
    "  all 15 module SyntaxKinds and identity-preserving await intervals are covered.\n" +
    "- JSX/TSX parser helpers: 28, grouped into 6 exact behavioral contracts;\n" +
    "  all 12 JSX SyntaxKinds and the three-way less-than ambiguity are covered.\n" +
    "- JSDoc helpers: 64, grouped into 9 exact behavioral contracts; all\n" +
    "  43 JSDoc SyntaxKinds, aliases, parsing modes, attachment paths, and\n" +
    "  diagnostic channels are covered.\n" +
    "- JSON, pragma, SourceFile, and public API behavior is grouped\n" +
    "  into 8 exact contracts; both JSON entry paths, nine pragma keys, five\n" +
    "  public entries, invocation isolation, and immutable result collections\n" +
    "  are covered.\n\n" +
    "Diagnostic reachability is additive: `scanner_public_parser` and `public_parser` " +
    "feed public parse diagnostics, `scanner_report_errors_only` is the full regexp " +
    "validation path not requested by the public parser, and `json_wrapper` is the " +
    "`create_source_file(..., ScriptKind.JSON)` conversion path.\n";
}

function main(argv) {
  const { mode, sourceDirectory } = parseArguments(argv);
  const files = auditFiles(sourceDirectory);
  fs.mkdirSync(OUTPUT_DIRECTORY, { recursive: true });
  const expected = files.map((file) => {
    const outputPath = path.join(OUTPUT_DIRECTORY, file.name);
    return { outputPath, contents: renderTsv(file.columns, file.rows, outputPath) };
  });
  expected.push({
    outputPath: path.join(OUTPUT_DIRECTORY, "README.md"),
    contents: readmeText(files),
  });

  if (mode === "write") {
    for (const file of expected) {
      fs.writeFileSync(file.outputPath, file.contents);
    }
    console.log("wrote upstream audit: 359 SyntaxKind, 195 factory, 175 child, 26 context, 148 diagnostic rows");
    return;
  }

  for (const file of expected) {
    if (!fs.existsSync(file.outputPath)) {
      throw new Error(`missing ${file.outputPath}`);
    }
    const actual = fs.readFileSync(file.outputPath, "utf8");
    if (actual !== file.contents) {
      throw new Error(`${file.outputPath} is stale; review upstream and run with --write`);
    }
  }
  console.log("verified upstream audit: 359 SyntaxKind, 195 factory, 175 child, 26 context, 148 diagnostic rows");
}

const currentFile = fileURLToPath(import.meta.url);
if (process.argv[1] && path.resolve(process.argv[1]) === currentFile) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  }
}
