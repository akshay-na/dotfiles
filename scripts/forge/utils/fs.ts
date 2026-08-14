import { fail } from "./cli.ts";

export async function pathExists(path: string): Promise<boolean> {
  try {
    await Deno.stat(path);
    return true;
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) return false;
    throw err;
  }
}

export async function isFile(path: string): Promise<boolean> {
  try {
    const stat = await Deno.stat(path);
    return stat.isFile;
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) return false;
    throw err;
  }
}

export async function isDir(path: string): Promise<boolean> {
  try {
    const stat = await Deno.stat(path);
    return stat.isDirectory;
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) return false;
    throw err;
  }
}

export async function requireFile(path: string): Promise<string> {
  if (!(await isFile(path))) {
    fail(`Required file not found: ${path}`);
  }
  return path;
}

export async function requireDir(path: string, label = path): Promise<string> {
  if (!path) {
    fail(`Required directory is empty: ${label}`);
  }
  if (!(await isDir(path))) {
    fail(`${label} is not a directory: ${path}`);
  }
  return path;
}

export async function ensureDir(path: string): Promise<string> {
  await Deno.mkdir(path, { recursive: true });
  return path;
}

export async function readText(path: string): Promise<string> {
  return await Deno.readTextFile(path);
}

export async function writeText(path: string, contents: string): Promise<void> {
  await Deno.writeTextFile(path, contents);
}

export async function appendText(
  path: string,
  contents: string,
): Promise<void> {
  await Deno.writeTextFile(path, contents, { append: true });
}
