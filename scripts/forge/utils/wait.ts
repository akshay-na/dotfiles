import { fail } from "./cli.ts";
import { info, ok } from "./log.ts";

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export type WaitOptions = {
  timeoutMs?: number;
  intervalMs?: number;
  label?: string;
  dryRun?: boolean;
};

/** Poll `probe` until it returns true or `timeoutMs` elapses. */
export async function waitUntil(
  probe: () => Promise<boolean> | boolean,
  options: WaitOptions = {},
): Promise<void> {
  const timeoutMs = options.timeoutMs ?? 60_000;
  const intervalMs = options.intervalMs ?? 2_000;
  const label = options.label ?? "condition";

  if (options.dryRun) {
    ok(`${label} dry-run: skipping wait`);
    return;
  }

  info(`Waiting for ${label}...`);
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    if (await probe()) {
      ok(`${label} is ready`);
      return;
    }
    await sleep(intervalMs);
  }

  fail(`${label} did not become ready within ${Math.round(timeoutMs / 1000)}s`);
}

/** Wait until `host:port` accepts a TCP connection. */
export async function waitForPort(
  host: string,
  port: number,
  options: WaitOptions = {},
): Promise<void> {
  const label = options.label ?? `${host}:${port}`;
  await waitUntil(
    async () => {
      try {
        const conn = await Deno.connect({ hostname: host, port });
        conn.close();
        return true;
      } catch {
        return false;
      }
    },
    { ...options, label },
  );
}
