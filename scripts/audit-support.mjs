import fs from "node:fs";

export function assert(condition, message) {
  if (!condition) throw new Error(message);
}

export function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    throw new Error(
      `${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

export function assertDeepEqual(actual, expected, label) {
  assertEqual(JSON.stringify(actual), JSON.stringify(expected), label);
}

export function parseTsvText(text, source = "<tsv>") {
  const lines = text.trimEnd().split("\n");
  assert(lines.length > 0 && lines[0] !== "", `${source}: missing header`);
  const headers = lines[0].split("\t");
  const rows = lines.slice(1).map((line, rowIndex) => {
    const values = line.split("\t");
    assertEqual(values.length, headers.length, `${source}:${rowIndex + 2} row width`);
    return Object.fromEntries(
      headers.map((header, index) => [header, values[index]]),
    );
  });
  return { headers, rows };
}

export function readTsv(filePath) {
  return parseTsvText(fs.readFileSync(filePath, "utf8"), filePath);
}

export function renderTsv(headers, rows) {
  return `${[
    headers.join("\t"),
    ...rows.map((row) => headers.map((header) => row[header] ?? "").join("\t")),
  ].join("\n")}\n`;
}

export function splitList(value) {
  return value.split(";").map((item) => item.trim()).filter(Boolean);
}

export function parseMode(argv, allowedModes, usage) {
  if (
    argv.length !== 1 ||
    !allowedModes.some((mode) => argv[0] === `--${mode}`)
  ) {
    throw new Error(usage);
  }
  return argv[0].slice(2);
}
