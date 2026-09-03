import { spawn } from "node:child_process";
import fs from "node:fs";

function appendCaptured(current, chunk, limit) {
  if (current.length >= limit) return current;
  return (current + chunk).slice(0, limit);
}

export function processGroupRssKib(processGroup) {
  let total = 0;
  let observed = false;
  for (const entry of fs.readdirSync("/proc", { withFileTypes: true })) {
    if (!entry.isDirectory() || !/^\d+$/.test(entry.name)) continue;
    const root = `/proc/${entry.name}`;
    try {
      const stat = fs.readFileSync(`${root}/stat`, "utf8");
      const close = stat.lastIndexOf(")");
      if (close < 0) continue;
      const fields = stat.slice(close + 2).split(" ");
      if (Number(fields[2]) !== processGroup) continue;
      observed = true;
      const status = fs.readFileSync(`${root}/status`, "utf8");
      const match = status.match(/^VmRSS:\s+(\d+)\s+kB$/m);
      if (match) total += Number(match[1]);
    } catch (error) {
      if (error?.code !== "ENOENT" && error?.code !== "ESRCH") throw error;
    }
  }
  return { observed, rssKib: total };
}

export function killProcessGroup(processGroup, signal) {
  try {
    process.kill(-processGroup, signal);
  } catch (error) {
    if (error?.code !== "ESRCH") throw error;
  }
}

export async function superviseProcess({
  command,
  args,
  timeoutMs,
  captureLimit,
  sampleIntervalMs,
  cwd = process.cwd(),
  env = process.env,
  onStdoutLine,
}) {
  const started = process.hrtime.bigint();
  const child = spawn(command, args, {
    cwd,
    detached: true,
    env,
    stdio: ["ignore", "pipe", "pipe"],
  });
  let stdout = "";
  let stderr = "";
  let pending = "";
  let peakRssKib = 0;
  let sampled = false;
  let timedOut = false;
  const progressSamples = [];
  const sample = (completed) => {
    const value = processGroupRssKib(child.pid);
    sampled ||= value.observed;
    peakRssKib = Math.max(peakRssKib, value.rssKib);
    if (completed !== undefined && value.observed) {
      progressSamples.push({ completed, rss_kib: value.rssKib });
    }
  };

  child.stdout.setEncoding("utf8");
  child.stderr.setEncoding("utf8");
  child.stdout.on("data", (chunk) => {
    stdout = appendCaptured(stdout, chunk, captureLimit);
    if (!onStdoutLine) return;
    pending += chunk;
    const lines = pending.split("\n");
    pending = lines.pop();
    for (const line of lines) onStdoutLine(line, sample);
  });
  child.stderr.on("data", (chunk) => {
    stderr = appendCaptured(stderr, chunk, captureLimit);
  });

  sample();
  const sampler = setInterval(sample, sampleIntervalMs);
  const timeout = setTimeout(() => {
    timedOut = true;
    killProcessGroup(child.pid, "SIGTERM");
    setTimeout(() => killProcessGroup(child.pid, "SIGKILL"), 1_000).unref();
  }, timeoutMs);
  const outcome = await new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("close", (code, signal) => resolve({ code, signal }));
  }).finally(() => {
    clearInterval(sampler);
    clearTimeout(timeout);
  });
  const wallMs = Number(process.hrtime.bigint() - started) / 1_000_000;
  if (!sampled) {
    throw new Error(`${command}: process group ${child.pid} was never sampled`);
  }
  return {
    ...outcome,
    stdout,
    stderr,
    peakRssKib,
    timedOut,
    wallMs,
    progressSamples,
  };
}
