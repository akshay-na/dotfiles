import { fail } from "./cli.ts";

/** Read an env var, or `fallback` when unset/empty. */
export function getEnv(name: string, fallback = ""): string {
  const value = Deno.env.get(name);
  return value && value.length > 0 ? value : fallback;
}

/** Require a non-empty env var. */
export function requireEnv(name: string, example?: string): string {
  const value = Deno.env.get(name);
  if (value && value.length > 0) return value;
  fail(
    `Required env ${name} is not set`,
    example ?? `export ${name}="<value>"`,
  );
}

/** Require several env vars; fail once listing every missing name. */
export function requireEnvs(
  specs: Array<{ name: string; example?: string }>,
): Record<string, string> {
  const missing: string[] = [];
  const examples: string[] = [];
  const values: Record<string, string> = {};

  for (const spec of specs) {
    const value = Deno.env.get(spec.name);
    if (value && value.length > 0) {
      values[spec.name] = value;
    } else {
      missing.push(spec.name);
      examples.push(spec.example ?? `export ${spec.name}="<value>"`);
    }
  }

  if (missing.length > 0) {
    fail(
      `The following environment variables are not set: ${missing.join(", ")}`,
      examples.join("\n  "),
    );
  }

  return values;
}
