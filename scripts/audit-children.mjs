#!/usr/bin/env node

import fs from "node:fs";
import ts from "typescript";

import {
  parseMode,
  parseTsvText as parseTsv,
  renderTsv,
} from "./audit-support.mjs";
import { verifyInstalledTypeScript } from "./upstream-config.mjs";

const AUDIT_PATH = "docs/upstream-audit/for-each-child.tsv";
const IMPLEMENTATION_PATH = "for_each_child.mbt";
const TEST_PATH = "for_each_child_wbtest.mbt";
const COMPLETE_STATUS = "complete";

function parseArguments(argv) {
  return parseMode(
    argv,
    ["verify", "write"],
    "usage: node scripts/audit-children.mjs (--verify|--write)",
  );
}

function matchingBracket(text, openingBracket) {
  let depth = 0;
  let quote;
  let escaped = false;
  for (let index = openingBracket; index < text.length; index++) {
    const character = text[index];
    if (quote) {
      if (escaped) {
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === quote) {
        quote = undefined;
      }
      continue;
    }
    if (character === '"') {
      quote = character;
    } else if (character === "[") {
      depth++;
    } else if (character === "]") {
      depth--;
      if (depth === 0) return index;
    }
  }
  throw new Error("unterminated child-slot array");
}

function visitSequences(armBody) {
  const sequences = [];
  let offset = 0;
  while (true) {
    const visit = armBody.indexOf("visit([", offset);
    if (visit < 0) break;
    const openingBracket = visit + "visit(".length;
    const closingBracket = matchingBracket(armBody, openingBracket);
    const arraySource = armBody.slice(openingBracket + 1, closingBracket);
    const slots = [];
    const slotPattern = /(Single|List|FlatList)\("([^"\\]+)"\)/g;
    for (const match of arraySource.matchAll(slotPattern)) {
      const prefix = {
        Single: "node",
        List: "nodes",
        FlatList: "flat",
      }[match[1]];
      slots.push(`${prefix}:${match[2]}`);
    }
    sequences.push(slots);
    offset = closingBracket + 1;
  }
  return sequences;
}

function implementationOrders(source) {
  const matchStart = source.indexOf("match node.kind().to_int() {");
  if (matchStart < 0) throw new Error("could not locate for_each_child match");
  const matchSource = source.slice(matchStart);
  const armPattern = /^\s+((?:\d+\s*(?:\|\s*\d+\s*)*))=>/gm;
  const arms = [...matchSource.matchAll(armPattern)];
  const orders = new Map();
  const alternatives = new Map();
  for (let index = 0; index < arms.length; index++) {
    const arm = arms[index];
    const bodyStart = arm.index + arm[0].length;
    const bodyEnd = index + 1 < arms.length ? arms[index + 1].index : matchSource.length;
    const body = matchSource.slice(bodyStart, bodyEnd);
    const kinds = [...arm[1].matchAll(/\d+/g)].map((value) =>
      Number.parseInt(value[0], 10)
    );
    const sequences = visitSequences(body);
    const dynamic = kinds.some((kind) => kind === 342 || kind === 349 || kind === 347);
    if ((!dynamic && sequences.length !== 1) || (dynamic && sequences.length !== 2)) {
      throw new Error(
        `kind arm ${kinds.join("|")} has ${sequences.length} visit sequences`,
      );
    }
    for (const kind of kinds) {
      if (orders.has(kind)) throw new Error(`duplicate child arm for kind ${kind}`);
      if (kind === 342 || kind === 349) {
        orders.set(kind, sequences[1]);
        alternatives.set(kind, sequences[0]);
      } else if (kind === 347) {
        orders.set(kind, sequences[1]);
        alternatives.set(kind, sequences[0]);
      } else {
        orders.set(kind, sequences[0]);
      }
    }
  }
  return { orders, alternatives };
}

function testOrders(source) {
  const orders = new Map();
  const contractPattern = /_child_contract\(\s*\[([\d,\s]+)\],\s*"([^"\\]*)"/g;
  for (const match of source.matchAll(contractPattern)) {
    const kinds = [...match[1].matchAll(/\d+/g)].map((value) =>
      Number.parseInt(value[0], 10)
    );
    const order = match[2] === "" ? [] : match[2].split(" -> ");
    for (const kind of kinds) {
      if (orders.has(kind)) throw new Error(`duplicate test contract for kind ${kind}`);
      orders.set(kind, order);
    }
  }
  return orders;
}

function upstreamOrder(kind, options = {}) {
  const makeFieldValue = (field) => {
    const flattenedChild = {
      kind: ts.SyntaxKind.Identifier,
      auditField: field,
      auditFlattened: true,
    };
    const value = [flattenedChild];
    value.kind =
      field === "typeExpression" && options.typeExpressionIsJSDoc
        ? ts.SyntaxKind.JSDocTypeExpression
        : ts.SyntaxKind.Identifier;
    value.auditField = field;
    return value;
  };
  const node = new Proxy(
    { kind },
    {
      get(target, field) {
        if (field === "kind") return kind;
        if (field === "isNameFirst") return Boolean(options.isNameFirst);
        if (typeof field !== "string") return target[field];
        return makeFieldValue(field);
      },
    },
  );
  const order = [];
  ts.forEachChild(
    node,
    (child) => {
      order.push(
        `${child.auditFlattened ? "flat" : "node"}:${child.auditField}`,
      );
    },
    (children) => {
      order.push(`nodes:${children.auditField}`);
    },
  );
  return order;
}

function assertOrder(symbol, expected, actual, suffix = "") {
  if (JSON.stringify(expected) !== JSON.stringify(actual)) {
    throw new Error(
      `${symbol}${suffix} expected ${expected.join(" -> ")}, ` +
        `got ${actual.join(" -> ")}`,
    );
  }
}

function main(argv) {
  const mode = parseArguments(argv);
  verifyInstalledTypeScript(ts.version);
  const audit = parseTsv(fs.readFileSync(AUDIT_PATH, "utf8"));
  const rows = audit.rows;
  if (rows.length !== 175) {
    throw new Error(`expected 175 forEachChild rows, found ${rows.length}`);
  }
  const symbols = new Set(rows.map((row) => row.upstream_symbol));
  if (symbols.size !== rows.length) {
    throw new Error(`${AUDIT_PATH} contains duplicate symbols`);
  }
  const implementation = implementationOrders(
    fs.readFileSync(IMPLEMENTATION_PATH, "utf8"),
  );
  const tests = testOrders(fs.readFileSync(TEST_PATH, "utf8"));
  const expectedKinds = new Set();
  for (const row of rows) {
    const name = row.upstream_symbol.slice("SyntaxKind.".length);
    const kind = ts.SyntaxKind[name];
    if (typeof kind !== "number") {
      throw new Error(`unknown TypeScript kind: ${row.upstream_symbol}`);
    }
    expectedKinds.add(kind);
    const actual = implementation.orders.get(kind);
    if (!actual) throw new Error(`${row.upstream_symbol} has no MoonBit branch`);
    const expected = upstreamOrder(kind);
    assertOrder(row.upstream_symbol, expected, actual);
    const tested = tests.get(kind);
    if (!tested) throw new Error(`${row.upstream_symbol} has no MoonBit test fixture`);
    assertOrder(row.upstream_symbol, expected, tested, "[test]");
  }
  for (const kind of implementation.orders.keys()) {
    if (!expectedKinds.has(kind)) {
      throw new Error(`unexpected MoonBit child branch for kind ${kind}`);
    }
  }
  for (const kind of tests.keys()) {
    if (!expectedKinds.has(kind)) {
      throw new Error(`unexpected MoonBit child test for kind ${kind}`);
    }
  }
  assertOrder(
    "SyntaxKind.JSDocParameterTag",
    upstreamOrder(ts.SyntaxKind.JSDocParameterTag, { isNameFirst: true }),
    implementation.alternatives.get(ts.SyntaxKind.JSDocParameterTag),
    "[isNameFirst]",
  );
  assertOrder(
    "SyntaxKind.JSDocPropertyTag",
    upstreamOrder(ts.SyntaxKind.JSDocPropertyTag, { isNameFirst: true }),
    implementation.alternatives.get(ts.SyntaxKind.JSDocPropertyTag),
    "[isNameFirst]",
  );
  assertOrder(
    "SyntaxKind.JSDocTypedefTag",
    upstreamOrder(ts.SyntaxKind.JSDocTypedefTag, {
      typeExpressionIsJSDoc: true,
    }),
    implementation.alternatives.get(ts.SyntaxKind.JSDocTypedefTag),
    "[JSDocTypeExpression]",
  );
  if (mode === "write") {
    for (const row of rows) {
      row.moonbit_implementation = IMPLEMENTATION_PATH;
      row.test_location = TEST_PATH;
      row.status = COMPLETE_STATUS;
    }
    fs.writeFileSync(AUDIT_PATH, renderTsv(audit.headers, rows));
    console.log("closed 175/175 forEachChild audit rows");
    return;
  }
  for (const row of rows) {
    if (
      row.moonbit_implementation !== IMPLEMENTATION_PATH ||
      row.test_location !== TEST_PATH ||
      row.status !== COMPLETE_STATUS
    ) {
      throw new Error(`${row.upstream_symbol} has stale progress columns`);
    }
  }
  console.log(
    "verified 175/175 forEachChild branches/tests and 3 dynamic JSDoc orders",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
