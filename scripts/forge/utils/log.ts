import { localTimestamp } from "./time.ts";

const RESET = "\x1b[0m";
const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const BLUE = "\x1b[34m";
const MAGENTA = "\x1b[35m";
const CYAN = "\x1b[36m";

function paint(color: string, text: string): string {
  if (Deno.noColor) return text;
  return `${color}${text}${RESET}`;
}

function line(prefix: string, message: string): string {
  return `${prefix} ${message}`;
}

/** Print `[INFO]` to stdout. */
export function info(message: string): void {
  console.log(line(paint(BLUE, "[INFO]"), message));
}

/** Print `[OK]` to stdout. */
export function ok(message: string): void {
  console.log(line(paint(GREEN, "[OK]"), message));
}

/** Print `[SUCCESS]` to stdout (alias used by older scripts). */
export function success(message: string): void {
  console.log(line(paint(GREEN, "[SUCCESS]"), message));
}

/** Print `[WARN]` to stdout. */
export function warn(message: string): void {
  console.log(line(paint(YELLOW, "[WARN]"), message));
}

/** Print `[ERROR]` to stderr. */
export function error(message: string): void {
  console.error(line(paint(RED, "[ERROR]"), message));
}

/** Print `[STEP]` to stdout. */
export function step(message: string): void {
  console.log(line(paint(CYAN, "[STEP]"), message));
}

/** Print `[DRY-RUN]` to stdout. */
export function dryRun(message: string): void {
  console.log(line(paint(YELLOW, "[DRY-RUN]"), message));
}

/** Print a magenta banner around `title`. */
export function header(title: string): void {
  const bar = paint(MAGENTA, "================================");
  console.log(bar);
  console.log(paint(MAGENTA, title));
  console.log(bar);
}

/** Print a timestamped line, matching pingme.sh. */
export function timestamped(message: string): void {
  console.log(line(paint(BLUE, `[${localTimestamp()}]`), message));
}
