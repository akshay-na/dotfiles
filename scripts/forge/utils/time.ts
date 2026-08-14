function pad(n: number): string {
  return String(n).padStart(2, "0");
}

/** UTC ISO-8601 without milliseconds (`2026-08-13T11:20:00Z`). */
export function isoTimestamp(date = new Date()): string {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}

/** Local `YYYY-MM-DD HH:MM:SS` (pingme.sh / rfc-style logs). */
export function localTimestamp(date = new Date()): string {
  return [
    `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`,
    `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`,
  ].join(" ");
}
