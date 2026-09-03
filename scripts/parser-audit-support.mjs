import { assert } from "./audit-support.mjs";

export function testBlock(source, name) {
  const marker = `test ${JSON.stringify(name)} {`;
  const start = source.indexOf(marker);
  assert(start >= 0, `missing white-box test ${name}`);
  const nextBlock = source.indexOf("\n///|", start + marker.length);
  const end = nextBlock >= 0 ? nextBlock : source.length;
  return source.slice(start, end);
}

export function decodeMoonBitString(text) {
  return JSON.parse(text);
}

export function extractStringPairs(block) {
  const pattern = /\(\s*("(?:\\.|[^"\\])*")\s*,\s*("(?:\\.|[^"\\])*")\s*,?\s*\)/gs;
  return [...block.matchAll(pattern)].map((match) => [
    decodeMoonBitString(match[1]),
    decodeMoonBitString(match[2]),
  ]);
}

export function extractStringStringIntegerTriples(block) {
  const pattern = /\(\s*("(?:\\.|[^"\\])*")\s*,\s*("(?:\\.|[^"\\])*")\s*,\s*(\d+)\s*,?\s*\)/gs;
  return [...block.matchAll(pattern)].map((match) => [
    decodeMoonBitString(match[1]),
    decodeMoonBitString(match[2]),
    Number(match[3]),
  ]);
}

export function extractStringIntegerPairs(block) {
  const pattern = /\(\s*("(?:\\.|[^"\\])*")\s*,\s*(\d+)\s*,?\s*\)/gs;
  return [...block.matchAll(pattern)].map((match) => [
    decodeMoonBitString(match[1]),
    Number(match[2]),
  ]);
}

export function extractStringIntegerTriples(block) {
  const pattern = /\(\s*("(?:\\.|[^"\\])*")\s*,\s*(\d+)\s*,\s*(\d+)\s*,?\s*\)/gs;
  return [...block.matchAll(pattern)].map((match) => [
    decodeMoonBitString(match[1]),
    Number(match[2]),
    Number(match[3]),
  ]);
}

export function relativeDiagnostics(file, base = 0) {
  return file.parseDiagnostics.map((diagnostic) => ({
    code: diagnostic.code,
    start: diagnostic.start - base,
    length: diagnostic.length,
  }));
}
