#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import ts from "typescript";

const DEFAULT_MAX_AST_BYTES = 4 * 1024 * 1024;

class AstSizeLimitExceeded extends Error {
  constructor(limit, actual) {
    super(`AST JSON output exceeded ${formatBytes(limit)}`);
    this.name = "AstSizeLimitExceeded";
    this.limit = limit;
    this.actual = actual;
  }
}

function formatBytes(bytes) {
  if (bytes === 1) {
    return "1 B";
  }
  if (bytes > 0 && bytes % (1024 * 1024) === 0) {
    return `${bytes / (1024 * 1024)} MiB`;
  }
  if (bytes > 0 && bytes % 1024 === 0) {
    return `${bytes / 1024} KiB`;
  }
  return `${bytes} B`;
}

function parseMaxAstBytes(value) {
  if (value === undefined || value === "") {
    return DEFAULT_MAX_AST_BYTES;
  }
  const limit = Number(value);
  if (!Number.isFinite(limit) || limit < 0) {
    throw new Error(`invalid TS_PARSE_BASELINE_MAX_AST_BYTES: ${value}`);
  }
  return Math.floor(limit);
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

function defaultOutputPath(inputPath, suffix) {
  const ext = path.extname(inputPath);
  return inputPath.slice(0, inputPath.length - ext.length) + suffix;
}

function displayFileName(fileName) {
  return path.basename(fileName);
}

function createLocationResolver(sourceFile) {
  return function loc(pos) {
    const clampedPos = Math.max(0, Math.min(pos, sourceFile.text.length));
    const lineAndCharacter = sourceFile.getLineAndCharacterOfPosition(clampedPos);
    return {
      offset: clampedPos,
      line: lineAndCharacter.line + 1,
      column: lineAndCharacter.character + 1,
    };
  };
}

function jsonIndent(level) {
  return " ".repeat(level);
}

function tokenText(node, sourceFile) {
  if (ts.isIdentifier(node)) {
    return node.text;
  }
  if (ts.isPrivateIdentifier(node)) {
    return node.text;
  }
  if (ts.isStringLiteralLike(node) || ts.isNumericLiteral(node)) {
    return node.text;
  }
  if (node.kind >= ts.SyntaxKind.FirstToken && node.kind <= ts.SyntaxKind.LastToken) {
    return node.getText(sourceFile);
  }
  return undefined;
}

export function serializeNode(node, sourceFile) {
  const loc = createLocationResolver(sourceFile);
  const json = {
    kind: ts.SyntaxKind[node.kind],
    pos: loc(node.pos),
    end: loc(node.end),
  };
  const text = tokenText(node, sourceFile);
  if (text !== undefined) {
    json.text = text;
  }

  const children = [];
  ts.forEachChild(node, (child) => {
    children.push(serializeNode(child, sourceFile));
  });
  if (children.length > 0) {
    json.children = children;
  }

  return json;
}

function childNodes(node) {
  const children = [];
  ts.forEachChild(node, (child) => {
    children.push(child);
  });
  return children;
}

function writeJsonLocation(write, loc, pos, indent) {
  const value = loc(pos);
  write("{\n");
  write(`${jsonIndent(indent + 2)}"offset": ${value.offset},\n`);
  write(`${jsonIndent(indent + 2)}"line": ${value.line},\n`);
  write(`${jsonIndent(indent + 2)}"column": ${value.column}\n`);
  write(`${jsonIndent(indent)}}`);
}

function writeAstJsonFile(astPath, sourceFile, options = {}) {
  const maxAstBytes = options.maxAstBytes ??
    parseMaxAstBytes(process.env.TS_PARSE_BASELINE_MAX_AST_BYTES);
  const warn = options.warn ?? ((message) => console.error(message));
  const displayPath = options.inputPath ?? sourceFile.fileName;
  const tmpPath = `${astPath}.tmp-${process.pid}`;
  const loc = createLocationResolver(sourceFile);
  const fd = fs.openSync(tmpPath, "w");
  let chunks = [];
  let chunkLength = 0;
  let byteLength = 0;
  let closed = false;

  function flush() {
    if (chunks.length === 0) {
      return;
    }
    fs.writeSync(fd, chunks.join(""));
    chunks = [];
    chunkLength = 0;
  }

  function write(chunk) {
    const nextByteLength = byteLength + Buffer.byteLength(chunk, "utf8");
    if (maxAstBytes > 0 && nextByteLength > maxAstBytes) {
      throw new AstSizeLimitExceeded(maxAstBytes, nextByteLength);
    }
    byteLength = nextByteLength;
    chunks.push(chunk);
    chunkLength += chunk.length;
    if (chunkLength >= 1024 * 1024) {
      flush();
    }
  }

  try {
    const stack = [{ type: "node", node: sourceFile, indent: 0 }];
    while (stack.length > 0) {
      const frame = stack.pop();
      if (frame.type === "children") {
        if (frame.index >= frame.children.length) {
          write(`\n${jsonIndent(frame.indent + 2)}]\n`);
          write(`${jsonIndent(frame.indent)}}`);
          continue;
        }
        if (frame.index > 0) {
          write(",\n");
        }
        stack.push({
          type: "children",
          children: frame.children,
          index: frame.index + 1,
          indent: frame.indent,
        });
        stack.push({
          type: "node",
          node: frame.children[frame.index],
          indent: frame.indent + 4,
        });
        continue;
      }

      const { node, indent } = frame;
      const children = childNodes(node);
      const text = tokenText(node, sourceFile);
      write(`${jsonIndent(indent)}{\n`);
      write(`${jsonIndent(indent + 2)}"kind": ${JSON.stringify(ts.SyntaxKind[node.kind])},\n`);
      write(`${jsonIndent(indent + 2)}"pos": `);
      writeJsonLocation(write, loc, node.pos, indent + 2);
      write(",\n");
      write(`${jsonIndent(indent + 2)}"end": `);
      writeJsonLocation(write, loc, node.end, indent + 2);
      if (text !== undefined) {
        write(",\n");
        write(`${jsonIndent(indent + 2)}"text": ${JSON.stringify(text)}`);
      }
      if (children.length > 0) {
        write(",\n");
        write(`${jsonIndent(indent + 2)}"children": [\n`);
        stack.push({ type: "children", children, index: 0, indent });
      } else {
        write(`\n${jsonIndent(indent)}}`);
      }
    }
    write("\n");
    flush();
    fs.closeSync(fd);
    closed = true;
    fs.renameSync(tmpPath, astPath);
  } catch (error) {
    if (!closed) {
      try {
        fs.closeSync(fd);
      } catch {
        // Ignore close errors while preserving the original failure.
      }
    }
    try {
      fs.rmSync(tmpPath, { force: true });
    } catch {
      // Ignore cleanup errors while preserving the original failure.
    }
    if (error instanceof AstSizeLimitExceeded) {
      fs.rmSync(astPath, { force: true });
      warn(
        `warning: skipped AST baseline for ${displayPath}; output exceeded ${formatBytes(error.limit)}`,
      );
      return false;
    }
    throw error;
  }
  return true;
}

export function formatDiagnostic(sourceFile, diagnostic) {
  const loc = createLocationResolver(sourceFile);
  const start = loc(diagnostic.start ?? 0);
  const category = ts.DiagnosticCategory[diagnostic.category].toLowerCase();
  const message = ts.flattenDiagnosticMessageText(diagnostic.messageText, "\n");
  return `${displayFileName(sourceFile.fileName)}(${start.line},${start.column}): ${category} TS${diagnostic.code}: ${message}`;
}

export function parseSourceFile(inputPath) {
  const fileName = path.resolve(inputPath);
  const sourceText = fs.readFileSync(fileName, "utf8");
  return ts.createSourceFile(
    fileName,
    sourceText,
    ts.ScriptTarget.Latest,
    false,
    scriptKindForPath(fileName),
  );
}

export function generateBaselineFiles(inputPath, astOut, errorsOut, options = {}) {
  const sourceFile = parseSourceFile(inputPath);
  const astPath = astOut ?? defaultOutputPath(inputPath, ".ast.json");
  const errorsPath = errorsOut ?? defaultOutputPath(inputPath, ".errors.txt");
  const errors = sourceFile.parseDiagnostics
    .map((diagnostic) => formatDiagnostic(sourceFile, diagnostic))
    .join("\n");

  fs.mkdirSync(path.dirname(path.resolve(astPath)), { recursive: true });
  fs.mkdirSync(path.dirname(path.resolve(errorsPath)), { recursive: true });
  writeAstJsonFile(astPath, sourceFile, { ...options, inputPath });
  fs.writeFileSync(errorsPath, errors.length === 0 ? "" : `${errors}\n`);
}

function printUsage() {
  console.error(
    "usage: node scripts/ts-parse-baseline.mjs <input.ts|tsx|js|jsx> [ast.json] [errors.txt]",
  );
}

function main(argv) {
  const [inputPath, astOut, errorsOut] = argv;
  if (!inputPath || inputPath === "-h" || inputPath === "--help") {
    printUsage();
    return inputPath ? 0 : 1;
  }

  generateBaselineFiles(inputPath, astOut, errorsOut);
  return 0;
}

const currentFile = fileURLToPath(import.meta.url);
if (process.argv[1] && path.resolve(process.argv[1]) === currentFile) {
  process.exitCode = main(process.argv.slice(2));
}
