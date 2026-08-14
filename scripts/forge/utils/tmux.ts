import { CommandNotFoundError, run } from "./process.ts";

export type TmuxOptions = {
  dryRun?: boolean;
  throwOnError?: boolean;
  inherit?: boolean;
};

async function tmux(
  args: string[],
  options: TmuxOptions = {},
): Promise<{ stdout: string; stderr: string; code: number }> {
  try {
    return await run("tmux", args, {
      dryRun: options.dryRun,
      throwOnError: options.throwOnError ?? true,
      inherit: options.inherit,
    });
  } catch (err) {
    if (err instanceof CommandNotFoundError) {
      throw new Error("tmux is not installed or not on PATH", { cause: err });
    }
    throw err;
  }
}

export function paneTarget(
  session: string,
  window: string,
  pane?: number | string,
): string {
  if (pane === undefined) return `${session}:${window}`;
  return `${session}:${window}.${pane}`;
}

export async function hasSession(
  name: string,
  options: TmuxOptions = {},
): Promise<boolean> {
  try {
    const result = await tmux(["has-session", "-t", name], {
      ...options,
      throwOnError: false,
    });
    return result.code === 0;
  } catch {
    return false;
  }
}

export async function hasWindow(
  session: string,
  window: string,
  options: TmuxOptions = {},
): Promise<boolean> {
  const result = await tmux(["list-windows", "-t", session], {
    ...options,
    throwOnError: false,
  });
  if (result.code !== 0) return false;
  return result.stdout.split("\n").some((line) => line.includes(window));
}

export async function ensureSession(
  name: string,
  options: TmuxOptions & { cwd?: string; windowName?: string } = {},
): Promise<void> {
  if (await hasSession(name, options)) return;
  const args = ["new-session", "-d", "-s", name];
  if (options.windowName) args.push("-n", options.windowName);
  if (options.cwd) args.push("-c", options.cwd);
  await tmux(args, options);
}

export async function ensureWindow(
  session: string,
  window: string,
  options: TmuxOptions & { cwd?: string } = {},
): Promise<void> {
  if (await hasWindow(session, window, options)) return;
  const args = ["new-window", "-t", session, "-n", window];
  if (options.cwd) args.push("-c", options.cwd);
  await tmux(args, options);
}

export async function paneCount(
  session: string,
  window: string,
  options: TmuxOptions = {},
): Promise<number> {
  const result = await tmux(["list-panes", "-t", `${session}:${window}`], {
    ...options,
    throwOnError: false,
  });
  if (result.code !== 0 || !result.stdout.trim()) return 0;
  return result.stdout.trim().split("\n").length;
}

export async function splitWindow(
  session: string,
  window: string,
  options: TmuxOptions & { cwd?: string; direction?: "h" | "v" } = {},
): Promise<void> {
  const dir = options.direction === "v" ? "-v" : "-h";
  const args = ["split-window", dir, "-t", `${session}:${window}`];
  if (options.cwd) args.push("-c", options.cwd);
  await tmux(args, options);
}

/** Ensure a window has at least `minPanes` panes (default 2). */
export async function ensureSplitWindow(
  session: string,
  window: string,
  options: TmuxOptions & { cwd?: string; minPanes?: number } = {},
): Promise<void> {
  const minPanes = options.minPanes ?? 2;
  await ensureWindow(session, window, options);
  const count = await paneCount(session, window, options);
  if (count >= minPanes) return;
  await tmux(["select-window", "-t", `${session}:${window}`], options);
  await splitWindow(session, window, options);
}

/** Send keys. Pass `enter: false` to skip the trailing Enter. */
export async function sendKeys(
  target: string,
  keys: string,
  options: TmuxOptions & { enter?: boolean } = {},
): Promise<void> {
  const args = ["send-keys", "-t", target, keys];
  if (options.enter !== false) args.push("Enter");
  await tmux(args, options);
}

export async function interruptPane(
  target: string,
  options: TmuxOptions & { times?: number } = {},
): Promise<void> {
  const times = options.times ?? 2;
  for (let i = 0; i < times; i++) {
    await tmux(["send-keys", "-t", target, "C-c"], options);
  }
}

/** Attach, or switch-client when already inside tmux. */
export async function attachOrSwitch(
  session: string,
  options: TmuxOptions = {},
): Promise<void> {
  if (Deno.env.get("TMUX")) {
    await tmux(["switch-client", "-t", session], options);
    return;
  }
  await tmux(["attach-session", "-t", session], {
    ...options,
    inherit: true,
  });
}

export async function selectWindow(
  session: string,
  window: string,
  options: TmuxOptions = {},
): Promise<void> {
  await tmux(["select-window", "-t", `${session}:${window}`], options);
}
