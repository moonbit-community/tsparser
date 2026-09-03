#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import ts from "typescript";

const UNDEFINED_VALUE = Object.freeze({ state: "undefined" });
const COMPILER_ONLY_FIELDS = new Set([
  "id",
  "modifierFlagsCache",
  "parent",
  "original",
  "emitNode",
  "symbol",
  "localSymbol",
  "locals",
  "nextContainer",
  "endFlowNode",
  "returnFlowNode",
  "flowNode",
  "jsDocCache",
  "links",
]);
const NODE_BASE_FIELDS = new Set([
  "kind",
  "pos",
  "end",
  "flags",
  "transformFlags",
]);
const SOURCE_FILE_METADATA_FIELDS = new Set([
  "text",
  "fileName",
  "path",
  "resolvedPath",
  "originalFileName",
  "languageVersion",
  "languageVariant",
  "scriptKind",
  "isDeclarationFile",
  "hasNoDefaultLib",
  "nodeCount",
  "identifierCount",
  "symbolCount",
  "parseDiagnostics",
  "bindDiagnostics",
  "bindSuggestionDiagnostics",
  "lineMap",
  "externalModuleIndicator",
  "setExternalModuleIndicator",
  "pragmas",
  "checkJsDirective",
  "referencedFiles",
  "typeReferenceDirectives",
  "libReferenceDirectives",
  "amdDependencies",
  "commentDirectives",
  "identifiers",
  "packageJsonLocations",
  "packageJsonScope",
  "imports",
  "moduleAugmentations",
  "ambientModuleNames",
  "classifiableNames",
  "impliedNodeFormat",
  "jsDocParsingMode",
  "jsDocDiagnostics",
]);

const syntaxKindDeclarations = new Map();
for (const name of Object.keys(ts.SyntaxKind)) {
  if (/^\d+$/.test(name)) {
    continue;
  }
  const value = ts.SyntaxKind[name];
  if (typeof value !== "number") {
    continue;
  }
  const names = syntaxKindDeclarations.get(value) ?? [];
  names.push(name);
  syntaxKindDeclarations.set(value, names);
}

function scriptKindForPath(filePath) {
  switch (path.extname(filePath).toLowerCase()) {
    case ".js":
    case ".cjs":
    case ".mjs":
      return ts.ScriptKind.JS;
    case ".jsx":
      return ts.ScriptKind.JSX;
    case ".tsx":
      return ts.ScriptKind.TSX;
    case ".json":
      return ts.ScriptKind.JSON;
    default:
      return ts.ScriptKind.TS;
  }
}

function languageVariantForScriptKind(scriptKind) {
  return scriptKind === ts.ScriptKind.JSX || scriptKind === ts.ScriptKind.TSX
    ? ts.LanguageVariant.JSX
    : ts.LanguageVariant.Standard;
}

function parseEnumOption(enumObject, value, optionName) {
  if (value === undefined) {
    return undefined;
  }
  if (/^-?\d+$/.test(value)) {
    const numeric = Number(value);
    if (typeof enumObject[numeric] === "string") {
      return numeric;
    }
  }
  const parsed = enumObject[value];
  if (typeof parsed !== "number") {
    throw new Error(`invalid ${optionName}: ${value}`);
  }
  return parsed;
}

export function createReferenceSourceFile(fileName, sourceText, options = {}) {
  const scriptKind = options.scriptKind ?? scriptKindForPath(fileName);
  const languageVersion = options.languageVersion ?? ts.ScriptTarget.Latest;
  const jsDocParsingMode = options.jsDocParsingMode ?? ts.JSDocParsingMode.ParseAll;
  return ts.createSourceFile(
    fileName,
    sourceText,
    { languageVersion, jsDocParsingMode },
    options.setParentNodes ?? false,
    scriptKind,
  );
}

export function parseReferenceSourceFile(inputPath, options = {}) {
  const readPath = path.resolve(inputPath);
  return createReferenceSourceFile(
    options.fileName ?? inputPath,
    fs.readFileSync(readPath, "utf8"),
    options,
  );
}

function isNode(value) {
  return value !== null &&
    typeof value === "object" &&
    typeof value.kind === "number" &&
    typeof value.pos === "number" &&
    typeof value.end === "number";
}

function isNodeArray(value) {
  return Array.isArray(value) &&
    typeof value.pos === "number" &&
    typeof value.end === "number";
}

function isNodeList(value) {
  return Array.isArray(value) &&
    !isNodeArray(value) &&
    value.length > 0 &&
    value.every((element) => isNode(element));
}

function isChildCollection(value) {
  return isNodeArray(value) || isNodeList(value);
}

function jsonPointerSegment(value) {
  return value.replaceAll("~", "~0").replaceAll("/", "~1");
}

function childPath(parentPath, field, index) {
  const base = parentPath === "/"
    ? `/${jsonPointerSegment(field)}`
    : `${parentPath}/${jsonPointerSegment(field)}`;
  return index === undefined ? base : `${base}/${index}`;
}

function isExcludedNodeField(node, key) {
  return COMPILER_ONLY_FIELDS.has(key) ||
    NODE_BASE_FIELDS.has(key) ||
    (node.kind === ts.SyntaxKind.SourceFile && SOURCE_FILE_METADATA_FIELDS.has(key));
}

function childEdges(node) {
  const ownEntries = Object.entries(node)
    .filter(([key, value]) =>
      !isExcludedNodeField(node, key) && (isNode(value) || isChildCollection(value))
    );
  const claimed = new Set();
  const claimedValues = new Set();
  const collectionProgress = new Map();
  const result = [];

  function claim(value, traversal) {
    const match = ownEntries.find(([key, candidate]) =>
      !claimed.has(key) && candidate === value
    );
    if (match) {
      const [field] = match;
      claimed.add(field);
      claimedValues.add(value);
      result.push({ field, value, traversal });
      return;
    }
    const collectionMatch = ownEntries.find(([, candidate]) => {
      if (!isChildCollection(candidate)) {
        return false;
      }
      const nextIndex = collectionProgress.get(candidate) ?? 0;
      return nextIndex < candidate.length && candidate[nextIndex] === value;
    });
    if (!collectionMatch) {
      throw new Error(
        `could not map ${traversal} child of ${ts.SyntaxKind[node.kind]} at ${node.pos}`,
      );
    }
    const [field, collection] = collectionMatch;
    const nextIndex = collectionProgress.get(collection) ?? 0;
    if (nextIndex === 0) {
      claimed.add(field);
      claimedValues.add(collection);
      result.push({ field, value: collection, traversal });
    }
    collectionProgress.set(collection, nextIndex + 1);
  }

  ts.forEachChild(
    node,
    (child) => {
      claim(child, "forEachChild");
      return undefined;
    },
    (children) => {
      claim(children, "forEachChild");
      return undefined;
    },
  );
  for (const [collection, visited] of collectionProgress) {
    if (visited !== collection.length) {
      throw new Error(
        `forEachChild visited ${visited}/${collection.length} elements of ` +
          `${ts.SyntaxKind[node.kind]} child collection at ${node.pos}`,
      );
    }
  }
  for (const [field, value] of ownEntries) {
    if (!claimed.has(field) && !claimedValues.has(value)) {
      result.push({ field, value, traversal: "parser_extra" });
      claimed.add(field);
      claimedValues.add(value);
    }
  }
  return result;
}

function locationOf(sourceFile, rawOffset) {
  const clippedOffset = Math.max(0, Math.min(rawOffset, sourceFile.text.length));
  const lineAndCharacter = sourceFile.getLineAndCharacterOfPosition(clippedOffset);
  return {
    raw_offset: rawOffset,
    clipped_offset: clippedOffset,
    line: lineAndCharacter.line + 1,
    column: lineAndCharacter.character + 1,
  };
}

function syntaxKindProjection(kind) {
  const names = syntaxKindDeclarations.get(kind) ?? [];
  return {
    value: kind,
    runtime_reverse_name: ts.SyntaxKind[kind],
    declaration_names: names.filter((name) => !/^(?:First|Last)/.test(name) && name !== "Count"),
    classification_markers: names.filter((name) => /^(?:First|Last)/.test(name)),
  };
}

function normalizeScalar(value) {
  if (value === undefined) {
    return UNDEFINED_VALUE;
  }
  if (
    value === null ||
    typeof value === "string" ||
    typeof value === "boolean"
  ) {
    return value;
  }
  if (typeof value === "number") {
    if (Number.isFinite(value)) {
      return value;
    }
    return { number: String(value) };
  }
  if (typeof value === "bigint") {
    return { bigint: value.toString() };
  }
  if (Array.isArray(value)) {
    return value.map(normalizeScalar);
  }
  if (value instanceof RegExp) {
    return { regexp: value.source, flags: value.flags };
  }
  if (value !== null && typeof value === "object") {
    const normalized = {};
    for (const key of Object.keys(value).sort()) {
      const child = value[key];
      if (typeof child !== "function") {
        normalized[key] = normalizeScalar(child);
      }
    }
    return normalized;
  }
  throw new Error(`unsupported scalar field type: ${typeof value}`);
}

function parserFields(node) {
  const fields = {};
  for (const key of Object.keys(node).sort()) {
    if (isExcludedNodeField(node, key)) {
      continue;
    }
    const value = node[key];
    if (isNode(value) || isChildCollection(value) || typeof value === "function") {
      continue;
    }
    fields[key] = normalizeScalar(value);
  }
  return fields;
}

function tokenText(node, sourceFile) {
  if (node.kind < ts.SyntaxKind.FirstToken || node.kind > ts.SyntaxKind.LastToken) {
    return undefined;
  }
  try {
    return node.getText(sourceFile);
  } catch (error) {
    return { unavailable: error instanceof Error ? error.message : String(error) };
  }
}

function nodeRecord(node, sourceFile, frame, edges) {
  const record = {
    record: "node",
    path: frame.path,
    parent_path: frame.parentPath ?? null,
    field: frame.field ?? null,
    index: frame.index ?? null,
    traversal: frame.traversal ?? "root",
    kind: syntaxKindProjection(node.kind),
    pos: locationOf(sourceFile, node.pos),
    end: locationOf(sourceFile, node.end),
    flags: node.flags ?? 0,
    transform_flags: node.transformFlags ?? 0,
    fields: parserFields(node),
    child_edges: edges.map((edge) => ({
      field: edge.field,
      shape: isNodeArray(edge.value)
        ? "node_array"
        : isNodeList(edge.value)
          ? "node_list"
          : "node",
      traversal: edge.traversal,
      length: isChildCollection(edge.value) ? edge.value.length : undefined,
    })),
  };
  const text = tokenText(node, sourceFile);
  if (text !== undefined) {
    record.token_text = text;
  }
  if (Object.hasOwn(node, "tokenFlags")) {
    record.token_flags = node.tokenFlags;
  }
  return record;
}

function nodeArrayRecord(nodeArray, sourceFile, frame) {
  return {
    record: "node_array",
    path: frame.path,
    parent_path: frame.parentPath,
    field: frame.field,
    traversal: frame.traversal,
    pos: locationOf(sourceFile, nodeArray.pos),
    end: locationOf(sourceFile, nodeArray.end),
    length: nodeArray.length,
    has_trailing_comma: Object.hasOwn(nodeArray, "hasTrailingComma")
      ? nodeArray.hasTrailingComma
      : UNDEFINED_VALUE,
    transform_flags: Object.hasOwn(nodeArray, "transformFlags")
      ? nodeArray.transformFlags
      : UNDEFINED_VALUE,
  };
}

function nodeListRecord(nodeList, frame) {
  return {
    record: "node_list",
    path: frame.path,
    parent_path: frame.parentPath,
    field: frame.field,
    traversal: frame.traversal,
    length: nodeList.length,
    pos: UNDEFINED_VALUE,
    end: UNDEFINED_VALUE,
    has_trailing_comma: UNDEFINED_VALUE,
    transform_flags: UNDEFINED_VALUE,
  };
}

export function* fullAstRecords(sourceFile) {
  yield {
    record: "header",
    schema: "typescript-6.0.3-full-ast-v1",
    file_name: sourceFile.fileName,
    text_utf16_length: sourceFile.text.length,
    text_utf8_sha256: crypto.createHash("sha256").update(sourceFile.text).digest("hex"),
  };
  const stack = [{ type: "node", value: sourceFile, path: "/" }];
  while (stack.length > 0) {
    const frame = stack.pop();
    if (frame.type === "node_array" || frame.type === "node_list") {
      const nodeList = frame.value;
      yield frame.type === "node_array"
        ? nodeArrayRecord(nodeList, sourceFile, frame)
        : nodeListRecord(nodeList, frame);
      for (let index = nodeList.length - 1; index >= 0; index--) {
        stack.push({
          type: "node",
          value: nodeList[index],
          path: childPath(frame.parentPath, frame.field, index),
          parentPath: frame.parentPath,
          field: frame.field,
          index,
          traversal: frame.traversal,
        });
      }
      continue;
    }

    const node = frame.value;
    const edges = childEdges(node);
    yield nodeRecord(node, sourceFile, frame, edges);
    for (let index = edges.length - 1; index >= 0; index--) {
      const edge = edges[index];
      const path_ = childPath(frame.path, edge.field);
      stack.push({
        type: isNodeArray(edge.value)
          ? "node_array"
          : isNodeList(edge.value)
            ? "node_list"
            : "node",
        value: edge.value,
        path: path_,
        parentPath: frame.path,
        field: edge.field,
        traversal: edge.traversal,
      });
    }
  }
}

export function serializeDiagnosticMessage(messageText) {
  if (typeof messageText === "string") {
    return { kind: "text", text: messageText };
  }
  return {
    kind: "chain",
    message_text: messageText.messageText,
    category: messageText.category,
    category_name: ts.DiagnosticCategory[messageText.category],
    code: messageText.code,
    next: (messageText.next ?? []).map(serializeDiagnosticMessage),
  };
}

export function serializeDiagnostic(diagnostic, fallbackSourceFile) {
  const sourceFile = diagnostic.file ?? fallbackSourceFile;
  const start = diagnostic.start ?? 0;
  const result = {
    file_name: sourceFile?.fileName ?? null,
    start,
    length: diagnostic.length ?? 0,
    category: diagnostic.category,
    category_name: ts.DiagnosticCategory[diagnostic.category],
    code: diagnostic.code,
    message_text: serializeDiagnosticMessage(diagnostic.messageText),
  };
  if (sourceFile) {
    result.location = locationOf(sourceFile, start);
  }
  if (diagnostic.reportsUnnecessary !== undefined) {
    result.reports_unnecessary = diagnostic.reportsUnnecessary;
  }
  if (diagnostic.reportsDeprecated !== undefined) {
    result.reports_deprecated = diagnostic.reportsDeprecated;
  }
  if (diagnostic.skippedOn !== undefined) {
    result.skipped_on = diagnostic.skippedOn;
  }
  if (diagnostic.relatedInformation !== undefined) {
    result.related_information = diagnostic.relatedInformation
      .map((related) => serializeDiagnostic(related, sourceFile));
  }
  return result;
}

export function* diagnosticRecords(sourceFile) {
  for (let index = 0; index < sourceFile.parseDiagnostics.length; index++) {
    yield {
      record: "parse_diagnostic",
      index,
      diagnostic: serializeDiagnostic(sourceFile.parseDiagnostics[index], sourceFile),
    };
  }
  const jsDocDiagnostics = sourceFile.jsDocDiagnostics ?? [];
  for (let index = 0; index < jsDocDiagnostics.length; index++) {
    yield {
      record: "jsdoc_diagnostic",
      index,
      diagnostic: serializeDiagnostic(jsDocDiagnostics[index], sourceFile),
    };
  }
}

function indexNodePaths(sourceFile) {
  const paths = new WeakMap();
  const stack = [{ node: sourceFile, path: "/" }];
  while (stack.length > 0) {
    const { node, path: nodePath } = stack.pop();
    paths.set(node, nodePath);
    const edges = childEdges(node);
    for (let edgeIndex = edges.length - 1; edgeIndex >= 0; edgeIndex--) {
      const edge = edges[edgeIndex];
      if (isChildCollection(edge.value)) {
        for (let index = edge.value.length - 1; index >= 0; index--) {
          stack.push({
            node: edge.value[index],
            path: childPath(nodePath, edge.field, index),
          });
        }
      } else {
        stack.push({ node: edge.value, path: childPath(nodePath, edge.field) });
      }
    }
  }
  return paths;
}

function normalizeMetadata(value, nodePaths, seen = new WeakSet()) {
  if (value === undefined) {
    return UNDEFINED_VALUE;
  }
  if (
    value === null ||
    typeof value === "string" ||
    typeof value === "number" ||
    typeof value === "boolean"
  ) {
    return value;
  }
  if (typeof value === "bigint") {
    return { bigint: value.toString() };
  }
  if (isNode(value)) {
    return {
      node_path: nodePaths.get(value) ?? null,
      kind: syntaxKindProjection(value.kind),
      pos: value.pos,
      end: value.end,
    };
  }
  if (seen.has(value)) {
    return { state: "cycle" };
  }
  seen.add(value);
  let result;
  if (Array.isArray(value)) {
    result = value.map((item) => normalizeMetadata(item, nodePaths, seen));
  } else if (value instanceof Map) {
    result = [...value].map(([key, item]) => [
      normalizeMetadata(key, nodePaths, seen),
      normalizeMetadata(item, nodePaths, seen),
    ]);
  } else if (value instanceof Set) {
    result = [...value].map((item) => normalizeMetadata(item, nodePaths, seen));
  } else {
    result = {};
    for (const key of Object.keys(value).sort()) {
      if (typeof value[key] !== "function") {
        result[key] = normalizeMetadata(value[key], nodePaths, seen);
      }
    }
  }
  seen.delete(value);
  return result;
}

export function sourceFileProjection(sourceFile) {
  const nodePaths = indexNodePaths(sourceFile);
  return {
    record: "source_file",
    schema: "typescript-6.0.3-source-file-v1",
    file_name: sourceFile.fileName,
    text_utf16_length: sourceFile.text.length,
    language_version: sourceFile.languageVersion,
    language_version_name: ts.ScriptTarget[sourceFile.languageVersion],
    language_variant: sourceFile.languageVariant,
    language_variant_name: ts.LanguageVariant[sourceFile.languageVariant],
    script_kind: sourceFile.scriptKind,
    script_kind_name: ts.ScriptKind[sourceFile.scriptKind],
    is_declaration_file: sourceFile.isDeclarationFile,
    has_no_default_lib: sourceFile.hasNoDefaultLib,
    implied_node_format: normalizeMetadata(sourceFile.impliedNodeFormat, nodePaths),
    node_count: sourceFile.nodeCount,
    identifier_count: sourceFile.identifierCount,
    symbol_count: sourceFile.symbolCount,
    statements: normalizeMetadata(sourceFile.statements, nodePaths),
    end_of_file_token: normalizeMetadata(sourceFile.endOfFileToken, nodePaths),
    identifiers: normalizeMetadata(sourceFile.identifiers, nodePaths),
    pragmas: normalizeMetadata(sourceFile.pragmas, nodePaths),
    referenced_files: normalizeMetadata(sourceFile.referencedFiles, nodePaths),
    type_reference_directives: normalizeMetadata(sourceFile.typeReferenceDirectives, nodePaths),
    lib_reference_directives: normalizeMetadata(sourceFile.libReferenceDirectives, nodePaths),
    amd_dependencies: normalizeMetadata(sourceFile.amdDependencies, nodePaths),
    comment_directives: normalizeMetadata(sourceFile.commentDirectives, nodePaths),
    external_module_indicator: normalizeMetadata(sourceFile.externalModuleIndicator, nodePaths),
    jsdoc_parsing_mode: normalizeMetadata(sourceFile.jsDocParsingMode, nodePaths),
    parse_diagnostic_count: sourceFile.parseDiagnostics.length,
    jsdoc_diagnostic_count: (sourceFile.jsDocDiagnostics ?? []).length,
  };
}

function scannerErrorProjection(message, length, argument, scanner) {
  return {
    start: scanner?.getTextPos() ?? 0,
    length,
    code: message.code,
    category: message.category,
    category_name: ts.DiagnosticCategory[message.category],
    message: message.message,
    arguments: argument === undefined ? [] : [normalizeScalar(argument)],
  };
}

export function* scannerRecords(sourceText, options = {}) {
  const errors = [];
  const scriptKind = options.scriptKind ?? ts.ScriptKind.TS;
  const languageVariant = options.languageVariant ?? languageVariantForScriptKind(scriptKind);
  let scanner;
  scanner = ts.createScanner(
    options.languageVersion ?? ts.ScriptTarget.Latest,
    options.skipTrivia ?? false,
    languageVariant,
    sourceText,
    (message, length, argument) => {
      errors.push(scannerErrorProjection(message, length, argument, scanner));
    },
  );
  scanner.setScriptKind(scriptKind);
  scanner.setJSDocParsingMode(options.jsDocParsingMode ?? ts.JSDocParsingMode.ParseAll);
  let errorIndex = 0;
  let tokenIndex = 0;
  while (true) {
    const kind = scanner.scan();
    const tokenErrors = errors.slice(errorIndex);
    errorIndex = errors.length;
    yield {
      record: "scanner_token",
      index: tokenIndex,
      kind: syntaxKindProjection(kind),
      full_start: scanner.getTokenFullStart(),
      start: scanner.getTokenStart(),
      end: scanner.getTokenEnd(),
      raw_text: scanner.getTokenText(),
      value: scanner.getTokenValue(),
      flags: scanner.getTokenFlags(),
      numeric_literal_flags: scanner.getNumericLiteralFlags(),
      has_unicode_escape: scanner.hasUnicodeEscape(),
      has_extended_unicode_escape: scanner.hasExtendedUnicodeEscape(),
      has_preceding_line_break: scanner.hasPrecedingLineBreak(),
      has_preceding_jsdoc_comment: scanner.hasPrecedingJSDocComment(),
      has_preceding_jsdoc_leading_asterisks: scanner.hasPrecedingJSDocLeadingAsterisks(),
      is_unterminated: scanner.isUnterminated(),
      diagnostics: tokenErrors,
    };
    tokenIndex++;
    if (kind === ts.SyntaxKind.EndOfFileToken) {
      break;
    }
  }
  yield {
    record: "scanner_summary",
    token_count: tokenIndex,
    diagnostics: errors,
    comment_directives: scanner.getCommentDirectives() ?? [],
  };
}

export function writeNdjson(records, fileDescriptor = 1) {
  let buffer = "";
  for (const record of records) {
    buffer += `${JSON.stringify(record)}\n`;
    if (buffer.length >= 64 * 1024) {
      fs.writeSync(fileDescriptor, buffer);
      buffer = "";
    }
  }
  if (buffer.length > 0) {
    fs.writeSync(fileDescriptor, buffer);
  }
}

function parseCli(argv) {
  const [mode, inputPath, ...rest] = argv;
  if (!mode || !inputPath || !["full-ast", "diagnostics", "source-file", "scanner"].includes(mode)) {
    throw new Error(
      "usage: node scripts/ts-reference.mjs <full-ast|diagnostics|source-file|scanner> <input> " +
        "[--set-parent-nodes] [--script-kind NAME] [--language-version NAME] [--jsdoc-mode NAME] [--skip-trivia]",
    );
  }
  const options = {};
  for (let index = 0; index < rest.length; index++) {
    const argument = rest[index];
    if (argument === "--set-parent-nodes") {
      options.setParentNodes = true;
    } else if (argument === "--skip-trivia") {
      options.skipTrivia = true;
    } else if (argument === "--script-kind") {
      options.scriptKind = parseEnumOption(ts.ScriptKind, rest[++index], "script kind");
    } else if (argument === "--language-version") {
      options.languageVersion = parseEnumOption(ts.ScriptTarget, rest[++index], "language version");
    } else if (argument === "--jsdoc-mode") {
      options.jsDocParsingMode = parseEnumOption(ts.JSDocParsingMode, rest[++index], "JSDoc mode");
    } else {
      throw new Error(`unknown argument: ${argument}`);
    }
  }
  return { mode, inputPath, options };
}

function main(argv) {
  const { mode, inputPath, options } = parseCli(argv);
  if (mode === "scanner") {
    const sourceText = fs.readFileSync(inputPath, "utf8");
    options.scriptKind ??= scriptKindForPath(inputPath);
    writeNdjson(scannerRecords(sourceText, options));
    return;
  }
  const sourceFile = parseReferenceSourceFile(inputPath, options);
  if (mode === "full-ast") {
    writeNdjson(fullAstRecords(sourceFile));
  } else if (mode === "diagnostics") {
    writeNdjson(diagnosticRecords(sourceFile));
  } else {
    writeNdjson([sourceFileProjection(sourceFile)]);
  }
}

const currentFile = fileURLToPath(import.meta.url);
if (process.argv[1] && path.resolve(process.argv[1]) === currentFile) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.stack : String(error));
    process.exitCode = 1;
  }
}
