import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import {
  generateBaselineFiles,
  parseSourceFile,
  serializeNode,
} from "./ts-parse-baseline.mjs";

test("writes parser errors using existing tsfiles errors baseline format", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "tsparser-baseline-"));
  const astOut = path.join(dir, "ClassDeclaration26.ast.json");
  const errorsOut = path.join(dir, "ClassDeclaration26.errors.txt");

  try {
    generateBaselineFiles("tsfiles/ClassDeclaration26.ts", astOut, errorsOut);

    assert.equal(
      fs.readFileSync(errorsOut, "utf8"),
      fs.readFileSync("tsfiles/ClassDeclaration26.errors.txt", "utf8"),
    );

    const ast = JSON.parse(fs.readFileSync(astOut, "utf8"));
    assert.equal(ast.kind, "SourceFile");
    assert.ok(Array.isArray(ast.children));
    const sourceFile = parseSourceFile("tsfiles/ClassDeclaration26.ts");
    assert.equal(
      fs.readFileSync(astOut, "utf8"),
      JSON.stringify(serializeNode(sourceFile, sourceFile), null, 2) + "\n",
    );
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("skips ast output that exceeds the configured byte limit", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "tsparser-baseline-"));
  const input = path.join(dir, "large.ts");
  const astOut = path.join(dir, "large.ast.json");
  const errorsOut = path.join(dir, "large.errors.txt");
  const warnings = [];

  try {
    fs.writeFileSync(input, "const value = a + b;\n");
    fs.writeFileSync(astOut, "stale ast\n");

    generateBaselineFiles(input, astOut, errorsOut, {
      maxAstBytes: 1,
      warn: (message) => warnings.push(message),
    });

    assert.equal(fs.existsSync(astOut), false);
    assert.equal(fs.readFileSync(errorsOut, "utf8"), "");
    assert.equal(warnings.length, 1);
    assert.match(warnings[0], /skipped AST baseline for .*large\.ts/);
    assert.match(warnings[0], /exceeded 1 B/);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});
