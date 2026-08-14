/** Deno OS id: `darwin` | `linux` | `windows` | … */
export function osName(): typeof Deno.build.os {
  return Deno.build.os;
}

export function hostname(): string {
  return Deno.hostname();
}

/** True when no GUI display is available (SSH / headless Linux). */
export function isHeadless(): boolean {
  if (Deno.build.os === "darwin") return false;
  return !Deno.env.get("DISPLAY");
}
