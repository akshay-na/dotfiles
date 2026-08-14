import { fail } from "./cli.ts";
import { dryRun as logDryRun, info } from "./log.ts";
import { run } from "./process.ts";

export const DEFAULT_SSH_OPTS = [
  "-o",
  "BatchMode=yes",
  "-o",
  "ConnectTimeout=15",
] as const;

export const DEFAULT_RSYNC_EXCLUDES = [
  ".git/",
  ".venv/",
  "__pycache__/",
  "*.pyc",
] as const;

export type SshOptions = {
  dryRun?: boolean;
  extraOpts?: string[];
};

function sshArgs(host: string, extraOpts: string[] = []): string[] {
  return [...DEFAULT_SSH_OPTS, ...extraOpts, host];
}

/** Run a remote command over SSH. */
export async function ssh(
  host: string,
  remoteCommand: string,
  options: SshOptions = {},
): Promise<void> {
  const args = [...sshArgs(host, options.extraOpts), remoteCommand];
  if (options.dryRun) {
    logDryRun(`ssh ${host} ${remoteCommand}`);
    return;
  }
  await run("ssh", args);
}

/**
 * Pipe `script` to `ssh host 'sudo -n bash -s'` (passwordless sudo).
 * Used by sandbox deploys.
 */
export async function sshSudoScript(
  host: string,
  script: string,
  options: SshOptions = {},
): Promise<void> {
  if (!script.trim()) {
    fail(`Empty remote script for ${host}`);
  }
  if (options.dryRun) {
    logDryRun(`ssh ${host} sudo -n bash -s <<'SCRIPT'`);
    console.log(script.trimEnd());
    console.log("SCRIPT");
    return;
  }
  info(`Running remote sudo script on ${host}...`);
  try {
    await run("ssh", [...sshArgs(host, options.extraOpts), "sudo -n bash -s"], {
      stdin: script,
    });
  } catch {
    fail(
      `Remote sudo script failed on ${host}`,
      `Ensure passwordless sudo is configured for ${host}`,
    );
  }
}

export type RsyncOptions = SshOptions & {
  delete?: boolean;
  excludes?: string[];
  chownRoot?: boolean;
};

/** rsync `src/` to `host:remoteDir/` via `sudo rsync` on the remote. */
export async function rsyncToRemote(
  src: string,
  host: string,
  remoteDir: string,
  options: RsyncOptions = {},
): Promise<void> {
  const excludes = options.excludes ?? [...DEFAULT_RSYNC_EXCLUDES];
  const rsyncArgs = [
    "-az",
    ...(options.delete === false ? [] : ["--delete"]),
    "--rsync-path=sudo rsync",
    ...excludes.flatMap((pattern) => ["--exclude", pattern]),
    `${src.replace(/\/?$/, "/")}`,
    `${host}:${remoteDir.replace(/\/?$/, "/")}`,
  ];

  if (options.dryRun) {
    logDryRun(`rsync ${rsyncArgs.join(" ")}`);
    return;
  }

  await ssh(host, `sudo -n mkdir -p '${remoteDir}'`, options);
  await run("rsync", rsyncArgs);
  if (options.chownRoot !== false) {
    await ssh(host, `sudo -n chown -R root:root '${remoteDir}'`, options);
  }
}

function hostLineRe(host: string): RegExp {
  const escaped = host.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`^\\s*Host\\s+${escaped}(\\s|$)`, "m");
}

/** True when `Host <name>` exists in ~/.ssh/config or ~/.ssh/config.d/*. */
export async function sshConfigHasHost(host: string): Promise<boolean> {
  const home = Deno.env.get("HOME") ?? "";
  const files: string[] = [`${home}/.ssh/config`];
  try {
    for await (const entry of Deno.readDir(`${home}/.ssh/config.d`)) {
      if (entry.isFile) files.push(`${home}/.ssh/config.d/${entry.name}`);
    }
  } catch {
    // no config.d
  }
  const re = hostLineRe(host);
  for (const file of files) {
    try {
      const text = await Deno.readTextFile(file);
      if (re.test(text)) return true;
    } catch {
      // missing file
    }
  }
  return false;
}
