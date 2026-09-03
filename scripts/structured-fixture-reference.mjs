#!/usr/bin/env node

import fs from "node:fs";

import { fullAstRecords, parseReferenceSourceFile, writeNdjson } from "./ts-reference.mjs";

function compactRecord(record) {
  if (record.record === "header") {
    return {
      record: "header",
      schema: "typescript-6.0.3-parser-structure-v1",
      file_name: record.file_name,
      text_utf16_length: record.text_utf16_length,
    };
  }
  if (record.record === "node") {
    const compact = {
      record: record.record,
      path: record.path,
      parent_path: record.parent_path,
      field: record.field,
      index: record.index,
      traversal: record.traversal,
      kind: record.kind.value,
      pos: record.pos.raw_offset,
      end: record.end.raw_offset,
      flags: record.flags,
      transform_flags: record.transform_flags,
      fields: record.fields,
      child_edges: record.child_edges,
    };
    if (Object.hasOwn(record, "token_text")) compact.token_text = record.token_text;
    if (Object.hasOwn(record, "token_flags")) compact.token_flags = record.token_flags;
    return compact;
  }
  return {
    record: record.record,
    path: record.path,
    parent_path: record.parent_path,
    field: record.field,
    traversal: record.traversal,
    pos: record.pos?.raw_offset ?? record.pos,
    end: record.end?.raw_offset ?? record.end,
    length: record.length,
    has_trailing_comma: record.has_trailing_comma,
    transform_flags: record.transform_flags,
  };
}

function main(argv) {
  const [input, output] = argv;
  if (!input || !output || argv.length !== 2) {
    throw new Error("usage: node scripts/structured-fixture-reference.mjs <input> <output.ndjson>");
  }
  const sourceFile = parseReferenceSourceFile(input, { fileName: input });
  const fd = fs.openSync(output, "w");
  try {
    writeNdjson((function* () {
      for (const record of fullAstRecords(sourceFile)) yield compactRecord(record);
    })(), fd);
  } finally {
    fs.closeSync(fd);
  }
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
}
