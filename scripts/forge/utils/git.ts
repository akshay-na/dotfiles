import { fail } from "./cli.ts";
import { run } from "./process.ts";

async function git(
  args: string[],
  options: { throwOnError?: boolean } = {},
): Promise<{ stdout: string; code: number }> {
  const result = await run("git", args, {
    throwOnError: options.throwOnError ?? true,
  });
  return { stdout: result.stdout.trim(), code: result.code };
}

/** `git rev-parse --git-dir` (works in worktrees). */
export async function gitDir(): Promise<string> {
  const result = await git(["rev-parse", "--git-dir"], { throwOnError: false });
  if (result.code !== 0 || !result.stdout) {
    fail("Not in a git repository");
  }
  return result.stdout;
}

/** `git rev-parse --show-toplevel`. */
export async function repoRoot(): Promise<string> {
  const result = await git(["rev-parse", "--show-toplevel"], {
    throwOnError: false,
  });
  if (result.code !== 0 || !result.stdout) {
    fail("Could not find git repository root");
  }
  return result.stdout;
}

export async function isWorktree(): Promise<boolean> {
  const dir = await gitDir();
  return dir.includes("worktrees");
}

export async function currentBranch(): Promise<string> {
  const symbolic = await git(["symbolic-ref", "--short", "HEAD"], {
    throwOnError: false,
  });
  if (symbolic.code === 0 && symbolic.stdout) return symbolic.stdout;
  const short = await git(["rev-parse", "--short", "HEAD"], {
    throwOnError: false,
  });
  if (short.code === 0 && short.stdout) return short.stdout;
  fail("Could not determine current branch");
}

export async function remoteUrl(remote = "origin"): Promise<string> {
  const result = await git(["config", "--get", `remote.${remote}.url`], {
    throwOnError: false,
  });
  return result.stdout;
}

export async function fetch(remote = "origin"): Promise<void> {
  await git(["fetch", remote]);
}

export async function isInsideWorkTree(): Promise<boolean> {
  const result = await git(["rev-parse", "--is-inside-work-tree"], {
    throwOnError: false,
  });
  return result.code === 0 && result.stdout === "true";
}

/** Repo name from `origin` URL, else the toplevel folder name. */
export async function originRepoName(remote = "origin"): Promise<string> {
  const url = await remoteUrl(remote);
  if (url) {
    const last = url.replace(/\/+$/, "").split("/").pop() ?? "";
    return last.replace(/\.git$/, "").toLowerCase();
  }
  const root = await repoRoot();
  const parts = root.split(/[/\\]/);
  return (parts[parts.length - 1] ?? "").toLowerCase();
}

export async function changedFiles(
  from = "HEAD@{1}",
  to = "HEAD",
): Promise<string[]> {
  const result = await git(["diff", "--name-only", from, to], {
    throwOnError: false,
  });
  if (!result.stdout) return [];
  return result.stdout.split("\n").filter((line) => line.length > 0);
}

export async function hasUncommittedChanges(): Promise<boolean> {
  const diff = await git(["diff", "--quiet"], { throwOnError: false });
  const cached = await git(["diff", "--cached", "--quiet"], {
    throwOnError: false,
  });
  const untracked = await git(["ls-files", "--others", "--exclude-standard"], {
    throwOnError: false,
  });
  return diff.code !== 0 || cached.code !== 0 || untracked.stdout.length > 0;
}

export async function stashIfDirty(message: string): Promise<boolean> {
  if (!(await hasUncommittedChanges())) return false;
  await git(["stash", "push", "-u", "-m", message]);
  return true;
}
