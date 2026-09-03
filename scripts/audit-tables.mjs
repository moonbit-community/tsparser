#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import ts from "typescript";

import {
  DEFAULT_TYPESCRIPT_SOURCE_DIR,
  TYPESCRIPT_GIT_HEAD,
  TYPESCRIPT_VERSION,
} from "./upstream-config.mjs";

function parseArguments(argv) {
  let verify = false;
  let sourceDirectory = DEFAULT_TYPESCRIPT_SOURCE_DIR;
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    if (argument === "--verify") {
      verify = true;
    } else if (argument === "--source-dir") {
      sourceDirectory = argv[++index];
      if (!sourceDirectory) throw new Error("--source-dir requires a path");
    } else {
      throw new Error(`unknown argument: ${argument}`);
    }
  }
  if (!verify) {
    throw new Error(
      "usage: node scripts/audit-tables.mjs --verify [--source-dir <path>]",
    );
  }
  return path.resolve(sourceDirectory);
}

function sliceBetween(text, startMarker, endMarker) {
  const start = text.indexOf(startMarker);
  const end = text.indexOf(endMarker, start + startMarker.length);
  if (start < 0 || end < 0) {
    throw new Error(`could not locate ${startMarker} .. ${endMarker}`);
  }
  return text.slice(start, end);
}

function camelToSnake(name) {
  return name
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1_$2")
    .toLowerCase();
}

function moonCharacterName(upstreamName) {
  if (upstreamName === "_") return "underscore";
  if (upstreamName === "$") return "dollar";
  if (/^_[0-9]$/.test(upstreamName)) return `digit_${upstreamName[1]}`;
  if (/^[a-z]$/.test(upstreamName)) return `lower_${upstreamName}`;
  if (/^[A-Z]$/.test(upstreamName)) return `upper_${upstreamName.toLowerCase()}`;
  return camelToSnake(upstreamName);
}

function parseNumericLiteral(text) {
  const normalized = text.trim().replace(/U$/, "");
  if (!/^-?(?:0x[0-9a-f]+|[0-9]+)$/i.test(normalized)) {
    throw new Error(`unsupported numeric literal: ${text}`);
  }
  return Number.parseInt(normalized, 0);
}

function parseCharacterCodes(typesSource) {
  const block = sliceBetween(
    typesSource,
    "export const enum CharacterCodes {",
    "export interface ModuleResolutionHost",
  );
  const values = new Map();
  const pattern = /^\s*([_$A-Za-z0-9]+)\s*=\s*(-?(?:0x[0-9a-f]+|[0-9]+)),/gim;
  for (const match of block.matchAll(pattern)) {
    values.set(moonCharacterName(match[1]), parseNumericLiteral(match[2]));
  }
  return values;
}

function parseMoonCharacterCodes(moonSource) {
  const values = new Map();
  const pattern = /fn CharacterCodes::([a-z0-9_]+)\(\) -> Int \{\s*(-?(?:0x[0-9a-f]+|[0-9]+))\s*\}/gi;
  for (const match of moonSource.matchAll(pattern)) {
    values.set(match[1], parseNumericLiteral(match[2]));
  }
  return values;
}

function parseStringToNumberPairs(block) {
  const values = new Map();
  const pattern = /("(?:\\.|[^"\\])*")\s*=>\s*([0-9]+)/g;
  for (const match of block.matchAll(pattern)) {
    values.set(JSON.parse(match[1]), Number.parseInt(match[2], 10));
  }
  return values;
}

function parseNumberToStringPairs(block) {
  const values = new Map();
  const pattern = /^\s*([0-9]+)\s*=>\s*("(?:\\.|[^"\\])*")/gm;
  for (const match of block.matchAll(pattern)) {
    values.set(Number.parseInt(match[1], 10), JSON.parse(match[2]));
  }
  return values;
}

function assertMapsEqual(label, expected, actual) {
  const differences = [];
  for (const [key, expectedValue] of expected) {
    if (!actual.has(key)) {
      differences.push(`missing ${JSON.stringify(key)}`);
    } else if (actual.get(key) !== expectedValue) {
      differences.push(
        `${JSON.stringify(key)} expected ${JSON.stringify(expectedValue)}, got ${JSON.stringify(actual.get(key))}`,
      );
    }
  }
  for (const key of actual.keys()) {
    if (!expected.has(key)) differences.push(`unexpected ${JSON.stringify(key)}`);
  }
  if (differences.length > 0) {
    throw new Error(`${label} mismatch:\n${differences.slice(0, 20).join("\n")}`);
  }
}

const FLAG_TYPES = [
  "NodeFlags",
  "TransformFlags",
  "TokenFlags",
  "ModifierFlags",
  "PragmaKindFlags",
  "RegularExpressionFlags",
];

function flagMethodName(type, upstreamName) {
  const normalized = upstreamName
    .replaceAll("JSDoc", "Jsdoc")
    .replaceAll("TypeScript", "Typescript")
    .replaceAll("JavaScript", "Javascript")
    .replaceAll("JSON", "Json")
    .replaceAll("JSX", "Jsx")
    .replace(/ES(?=Next|[0-9])/, "Es");
  const base = camelToSnake(normalized);
  const suffixed = {
    NodeFlags: new Set(["Let", "Const", "Using", "Namespace", "Unreachable"]),
    ModifierFlags: new Set([
      "Public",
      "Private",
      "Protected",
      "Readonly",
      "Override",
      "Export",
      "Abstract",
      "Static",
      "Async",
      "Default",
      "Const",
      "In",
      "Out",
    ]),
  };
  if (suffixed[type]?.has(upstreamName)) return `${base}_flag`;
  if (type === "PragmaKindFlags" && upstreamName === "Default") {
    return "default_flags";
  }
  return base;
}

function expectedFlagValues() {
  const result = new Map();
  for (const type of FLAG_TYPES) {
    for (const [name, value] of Object.entries(ts[type])) {
      if (typeof value !== "number") continue;
      result.set(`${type}::${flagMethodName(type, name)}`, value >>> 0);
    }
  }
  return result;
}

function parseMoonFlagValues(source) {
  const result = new Map();
  const functionPattern = new RegExp(
    `pub fn (${FLAG_TYPES.join("|")})::([a-z0-9_]+)\\(\\) -> \\1 \\{([\\s\\S]*?)\\n?\\}`,
    "g",
  );
  for (const match of source.matchAll(functionPattern)) {
    const [, type, method, body] = match;
    const valuePattern = new RegExp(
      `(?:${type}::from_bits|${type})\\((0x[0-9a-f]+|[0-9]+)U\\)`,
      "i",
    );
    const valueMatch = valuePattern.exec(body);
    if (!valueMatch) {
      throw new Error(`could not read flag value from ${type}::${method}`);
    }
    result.set(`${type}::${method}`, parseNumericLiteral(valueMatch[1]));
  }
  return result;
}

function main(argv) {
  const sourceDirectory = parseArguments(argv);
  const packageJson = JSON.parse(
    fs.readFileSync("node_modules/typescript/package.json", "utf8"),
  );
  if (
    packageJson.version !== TYPESCRIPT_VERSION ||
    packageJson.gitHead !== TYPESCRIPT_GIT_HEAD ||
    ts.version !== TYPESCRIPT_VERSION
  ) {
    throw new Error("installed TypeScript runtime does not match the locked reference");
  }

  const typesSource = fs.readFileSync(
    path.join(sourceDirectory, "src/compiler/types.ts"),
    "utf8",
  );
  const moonCharacterSource = fs.readFileSync("character_codes.mbt", "utf8");
  const expectedCharacters = parseCharacterCodes(typesSource);
  const actualCharacters = parseMoonCharacterCodes(moonCharacterSource);
  assertMapsEqual("CharacterCodes", expectedCharacters, actualCharacters);

  const tablesSource = fs.readFileSync("scanner_tables.mbt", "utf8");
  const keywordBlock = sliceBetween(
    tablesSource,
    "fn _string_to_keyword",
    "fn _string_to_token",
  );
  const tokenBlock = sliceBetween(
    tablesSource,
    "fn _string_to_token",
    "fn _token_to_string",
  );
  const reverseBlock = sliceBetween(
    tablesSource,
    "fn _token_to_string",
    "fn _character_code_to_regular_expression_flag",
  );
  const actualKeywords = parseStringToNumberPairs(keywordBlock);
  const actualPunctuation = parseStringToNumberPairs(tokenBlock);
  const actualReverse = parseNumberToStringPairs(reverseBlock);

  const expectedKeywords = new Map(Object.entries(ts.textToKeywordObj));
  const expectedPunctuation = new Map();
  for (let kind = 19; kind <= 79; kind++) {
    expectedPunctuation.set(ts.tokenToString(kind), kind);
  }
  const expectedReverse = new Map();
  for (const [text, kind] of [...expectedPunctuation, ...expectedKeywords]) {
    expectedReverse.set(kind, text);
    if (ts.stringToToken(text) !== kind) {
      throw new Error(`TypeScript runtime token map is not self-consistent for ${text}`);
    }
  }
  assertMapsEqual("keyword text table", expectedKeywords, actualKeywords);
  assertMapsEqual("punctuation text table", expectedPunctuation, actualPunctuation);
  assertMapsEqual("reverse token text table", expectedReverse, actualReverse);

  const flagSource = [
    "flags.mbt",
    "flags_node.mbt",
    "flags_transform.mbt",
    "flags_token.mbt",
    "flags_modifier.mbt",
    "flags_misc.mbt",
  ]
    .map((file) => fs.readFileSync(file, "utf8"))
    .join("\n");
  const expectedFlags = expectedFlagValues();
  const actualFlags = parseMoonFlagValues(flagSource);
  assertMapsEqual("flag values", expectedFlags, actualFlags);

  console.log(
    `verified ${actualCharacters.size} CharacterCodes, ${actualKeywords.size} keywords, ` +
      `${actualPunctuation.size} punctuation tokens, ${actualReverse.size} reverse mappings, ` +
      `and ${actualFlags.size} flag values`,
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
