import { error } from "./log.ts";

export type CommonFlags = {
  help: boolean;
  dryRun: boolean;
  yes: boolean;
  force: boolean;
  rest: string[];
};

/**
 * Parse argv for `--help`/`-h`, `--dry-run`, `--yes`/`-y`, and `--force`.
 * Remaining tokens stay in `rest` (unknown flags included so callers can fail fast).
 */
export function parseCommonFlags(args: string[]): CommonFlags {
  const rest: string[] = [];
  let help = false;
  let dryRun = false;
  let yes = false;
  let force = false;

  for (const arg of args) {
    if (arg === "--help" || arg === "-h") {
      help = true;
    } else if (arg === "--dry-run") {
      dryRun = true;
    } else if (arg === "--yes" || arg === "-y") {
      yes = true;
    } else if (arg === "--force") {
      force = true;
    } else {
      rest.push(arg);
    }
  }

  return { help, dryRun, yes, force, rest };
}

export type UsageOptions = {
  usage: string;
  summary?: string;
  options?: string[];
  examples: string[];
};

const DEFAULT_OPTIONS = [
  "  -h, --help     Show this help",
  "  --dry-run      Print planned actions without executing them",
  "  -y, --yes      Skip confirmation prompts",
  "  --force        Skip confirmations / overwrite",
];

/** Print usage with an Examples section. */
export function printUsage(spec: UsageOptions): void {
  const lines: string[] = [`Usage: ${spec.usage}`];
  if (spec.summary) {
    lines.push("", spec.summary);
  }
  lines.push("", "Options:");
  lines.push(...(spec.options ?? DEFAULT_OPTIONS));
  lines.push("", "Examples:");
  for (const example of spec.examples) {
    lines.push(`  ${example}`);
  }
  console.log(lines.join("\n"));
}

/** Exit 1 with an actionable error and a copy-pasteable example. */
export function fail(message: string, example?: string): never {
  error(message);
  if (example) {
    console.error(`  ${example}`);
  }
  Deno.exit(1);
}

/** Exit 0 after printing usage. */
export function exitHelp(spec: UsageOptions): never {
  printUsage(spec);
  Deno.exit(0);
}

/** Reject unknown flags left in `rest`. */
export function rejectUnknownFlags(rest: string[], spec: UsageOptions): void {
  const unknown = rest.find((token) => token.startsWith("-"));
  if (!unknown) return;
  error(`Unknown option: ${unknown}`);
  printUsage(spec);
  Deno.exit(1);
}

const encoder = new TextEncoder();
const decoder = new TextDecoder();

/** Read a line from `/dev/tty` when possible, else stdin. */
export async function prompt(message: string): Promise<string> {
  await Deno.stdout.write(encoder.encode(message));
  const buf = new Uint8Array(1024);
  try {
    using tty = await Deno.open("/dev/tty", { read: true });
    const n = await tty.read(buf);
    return decoder.decode(buf.subarray(0, n ?? 0)).replace(/\r?\n$/, "");
  } catch {
    const n = await Deno.stdin.read(buf);
    return decoder.decode(buf.subarray(0, n ?? 0)).replace(/\r?\n$/, "");
  }
}

/**
 * Ask y/N. `--yes` / `{ yes: true }` skips the prompt (agent-friendly).
 * Default is no unless `defaultYes` is set.
 */
export async function confirm(
  message: string,
  options: { yes?: boolean; defaultYes?: boolean } = {},
): Promise<boolean> {
  if (options.yes) return true;
  const suffix = options.defaultYes ? "[Y/n]" : "[y/N]";
  const answer = (await prompt(`${message} ${suffix} `)).trim().toLowerCase();
  if (!answer) return Boolean(options.defaultYes);
  return answer === "y" || answer === "yes";
}
