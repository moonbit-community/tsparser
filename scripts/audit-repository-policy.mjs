#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

import { parseMode } from "./audit-support.mjs";

const CONFIG_NAMES = new Set([
  "moon.mod",
  "moon.mod.json",
  "moon.pkg",
  "moon.pkg.json",
]);
const SOURCE_SUFFIXES = [".mbt", ".mbti"];
const IGNORED_DIRECTORIES = new Set([
  ".git",
  ".mooncakes",
  "_build",
  "node_modules",
  "target",
]);
const TARGET_PATH = /(^|[\s"'`(=])target[\\/]/;

function sourceAndPackageFiles(directory) {
  const files = [];
  const stack = [directory];
  while (stack.length > 0) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.isDirectory()) {
        if (!IGNORED_DIRECTORIES.has(entry.name)) {
          stack.push(path.join(current, entry.name));
        }
      } else if (
        entry.isFile() &&
        (
          CONFIG_NAMES.has(entry.name) ||
          SOURCE_SUFFIXES.some((suffix) => entry.name.endsWith(suffix))
        )
      ) {
        files.push(path.join(current, entry.name));
      }
    }
  }
  return files.sort();
}

function verifyNoTargetRuntime() {
  const violations = [];
  for (const filePath of sourceAndPackageFiles(".")) {
    const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
    for (let index = 0; index < lines.length; index++) {
      if (TARGET_PATH.test(lines[index])) {
        violations.push(`${filePath}:${index + 1}:${lines[index].trim()}`);
      }
    }
  }
  if (violations.length > 0) {
    throw new Error(
      "MoonBit source or package configuration contains a runtime target/ dependency:\n" +
        violations.join("\n"),
    );
  }
}

function verifyNoMoonBitGenerators() {
  if (fs.existsSync("scripts/generate-scanner-unicode.mjs")) {
    throw new Error("obsolete scanner source generator still exists");
  }
  const directWritePattern =
    /(?:writeFileSync|appendFileSync|createWriteStream|\.writeFile|\.appendFile)\s*\([^\n]*(?:\.mbt|moon\.pkg)/;
  const compileProbeOnly = new Set(["audit-public-api.mjs"]);
  for (const name of fs.readdirSync("scripts").filter((item) => item.endsWith(".mjs"))) {
    const source = fs.readFileSync(`scripts/${name}`, "utf8");
    if (compileProbeOnly.has(name)) {
      if (
        !source.includes(".public-api-probes-") ||
        !source.includes("fs.rmSync(parent, { recursive: true, force: true })")
      ) {
        throw new Error(`${name} compile probes are not isolated and self-cleaning`);
      }
      continue;
    }
    if (directWritePattern.test(source)) {
      throw new Error(`${name} writes a MoonBit source or package file`);
    }
    const constants = new Map(
      [...source.matchAll(/^const\s+([A-Z][A-Z0-9_]*)\s*=\s*["']([^"']+)["'];/gm)]
        .map((match) => [match[1], match[2]]),
    );
    for (const match of source.matchAll(
      /(?:writeFileSync|appendFileSync|createWriteStream)\(\s*([A-Z][A-Z0-9_]*)\b/g,
    )) {
      const outputPath = constants.get(match[1]);
      if (outputPath?.endsWith(".mbt") || /(?:^|\/)moon\.pkg$/.test(outputPath ?? "")) {
        throw new Error(`${name} writes MoonBit source through ${match[1]}`);
      }
    }
  }
}

function main(argv) {
  parseMode(
    argv,
    ["verify"],
    "usage: node scripts/audit-repository-policy.mjs --verify",
  );
  verifyNoTargetRuntime();
  verifyNoMoonBitGenerators();
  console.log(
    "verified no runtime target dependency and no committed MoonBit source generators",
  );
}

try {
  main(process.argv.slice(2));
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
