/** Align columns like `column -t` (gerrit CLI tables). */
export function formatTable(rows: string[][], separator = "  "): string {
  if (rows.length === 0) return "";
  const colCount = Math.max(...rows.map((row) => row.length));
  const widths = Array.from({ length: colCount }, (_, i) =>
    Math.max(...rows.map((row) => (row[i] ?? "").length)),
  );
  return rows
    .map((row) =>
      Array.from({ length: colCount }, (_, i) =>
        (row[i] ?? "").padEnd(widths[i]),
      ).join(separator),
    )
    .join("\n");
}

export function printTable(rows: string[][], separator = "  "): void {
  console.log(formatTable(rows, separator));
}

/** Parse TSV (from `jq @tsv`) into a table. */
export function tsvToRows(tsv: string): string[][] {
  return tsv
    .split("\n")
    .filter((line) => line.length > 0)
    .map((line) => line.split("\t"));
}
