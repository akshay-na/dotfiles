import { fail } from "./cli.ts";
import { dryRun as logDryRun } from "./log.ts";

export class CommandNotFoundError extends Error {
  override readonly name = "CommandNotFoundError";
  constructor(public readonly command: string) {
    super(`Command not found: ${command}`);
  }
}

export type RunResult = {
  stdout: string;
  stderr: string;
  code: number;
};

export type RunOptions = {
  cwd?: string;
  env?: Record<string, string>;
  dryRun?: boolean;
  throwOnError?: boolean;
  stdin?: string;
  inherit?: boolean;
};

const decoder = new TextDecoder();

export function formatCommand(command: string, args: string[] = []): string {
  return [command, ...args].join(" ");
}

/** True when `name` is executable on PATH. */
export async function commandExists(name: string): Promise<boolean> {
  const probe = new Deno.Command("sh", {
    args: ["-c", 'command -v "$1"', "sh", name],
    stdout: "null",
    stderr: "null",
  });
  const { code } = await probe.output();
  return code === 0;
}

/** Exit if any of `names` is missing from PATH. */
export async function requireCommands(...names: string[]): Promise<void> {
  const missing: string[] = [];
  for (const name of names) {
    if (!(await commandExists(name))) missing.push(name);
  }
  if (missing.length === 0) return;
  fail(
    `Required command not found: ${missing.join(", ")}`,
    missing.map((name) => `Install ${name} and retry`).join("\n  "),
  );
}

/**
 * Run `command` via Deno.Command.
 * Captures stdout/stderr unless `inherit` is set.
 * Throws on spawn failure, and on non-zero exit when `throwOnError` is true (default).
 */
export async function run(
  command: string,
  args: string[] = [],
  options: RunOptions = {},
): Promise<RunResult> {
  const {
    cwd,
    env,
    dryRun = false,
    throwOnError = true,
    stdin,
    inherit = false,
  } = options;
  const display = formatCommand(command, args);

  if (dryRun) {
    logDryRun(display);
    return { stdout: "", stderr: "", code: 0 };
  }

  const io = inherit ? "inherit" : "piped";
  let output: Deno.CommandOutput;
  try {
    const child = new Deno.Command(command, {
      args,
      cwd,
      env,
      stdin: stdin !== undefined ? "piped" : inherit ? "inherit" : "null",
      stdout: io,
      stderr: io,
    });

    if (stdin !== undefined) {
      const spawned = child.spawn();
      const writer = spawned.stdin.getWriter();
      await writer.write(new TextEncoder().encode(stdin));
      await writer.close();
      output = await spawned.output();
    } else {
      output = await child.output();
    }
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) {
      throw new CommandNotFoundError(command);
    }
    throw err;
  }

  const result: RunResult = {
    stdout: inherit ? "" : decoder.decode(output.stdout),
    stderr: inherit ? "" : decoder.decode(output.stderr),
    code: output.code,
  };

  if (throwOnError && result.code !== 0) {
    const detail = result.stderr.trim() || result.stdout.trim();
    throw new Error(
      `${display} exited ${result.code}${detail ? `: ${detail}` : ""}`,
    );
  }

  return result;
}

/** First of `names` that exists on PATH. */
export async function firstOnPath(
  names: string[],
): Promise<string | undefined> {
  for (const name of names) {
    if (await commandExists(name)) return name;
  }
  return undefined;
}
