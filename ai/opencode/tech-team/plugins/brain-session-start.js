/**
 * brain-session-start.js — OpenCode parity for Cursor hooks/brain-session-start.sh
 *
 * On session.created (main sessions only), fail-open bootstrap:
 *   1. Resolve kb-identity slug from worktree/directory (git remote → slug)
 *   2. Invoke ~/ai-brain/scripts/brain-rebuild-session-index.sh (or dotfiles ai/ai-brain/scripts/) <session-id> <slug> --apply
 *
 * Kill switch: OPENCODE_BRAIN_BOOTSTRAP_DISABLED=1
 * Brain root override: OPENCODE_BRAIN_ROOT (default ~/ai-brain)
 *
 * Telemetry: optional delegation to Cursor hook JSONL via:
 *   echo '{"session_id":"...","workspace_root":"..."}' | bash ~/dotfiles/ai/cursor/tech-team/hooks/brain-session-start.sh
 * (same pre-migration guards + brainBootstrap event when Cursor telemetry is enabled)
 *
 * Stow target: ~/.config/opencode/plugins/brain-session-start.js (see PARITY.md)
 */

const DOTFILES_ROOT = process.env.DOTFILES_ROOT || `${process.env.HOME}/dotfiles`;
const BRAIN_SCRIPTS_STOWED = `${process.env.HOME}/ai-brain/scripts/brain-rebuild-session-index.sh`;
const REBUILD_SCRIPT = `${DOTFILES_ROOT}/ai/ai-brain/scripts/brain-rebuild-session-index.sh`;
const CURSOR_HOOK = `${DOTFILES_ROOT}/ai/cursor/tech-team/hooks/brain-session-start.sh`;

function resolveRebuildScript() {
  if (process.env.BRAIN_REBUILD_SCRIPT) return process.env.BRAIN_REBUILD_SCRIPT;
  try {
    const { existsSync } = require("node:fs");
    if (existsSync(BRAIN_SCRIPTS_STOWED)) return BRAIN_SCRIPTS_STOWED;
  } catch {
    /* fail-open */
  }
  return REBUILD_SCRIPT;
}

/** @param {string} url */
function repoNameFromRemote(url) {
  const u = url.trim();
  if (u.startsWith("http://") || u.startsWith("https://")) {
    const path = new URL(u).pathname.replace(/^\/+|\/+$/g, "");
    const name = path.split("/").pop() || "";
    return name.replace(/\.git$/i, "");
  }
  if (u.includes(":")) {
    const tail = u.split(":").pop() || "";
    return tail.replace(/\.git$/i, "");
  }
  return u.replace(/\.git$/i, "");
}

/**
 * @param {import("@opencode-ai/plugin").PluginInput} ctx
 * @param {string} root
 */
async function resolveSlug(ctx, root) {
  const { $ } = ctx;
  try {
    const top = await $`git -C ${root} rev-parse --show-toplevel`.quiet().text();
    const remote = await $`git -C ${top.trim()} remote get-url origin`.quiet().text();
    const name = repoNameFromRemote(remote.trim());
    if (name) return name.toLowerCase().replace(/[^a-z0-9._-]+/g, "-");
  } catch {
    /* fail-open */
  }
  const base = root.split("/").filter(Boolean).pop() || "";
  return base.toLowerCase().replace(/[^a-z0-9._-]+/g, "-") || "";
}

/** @param {import("@opencode-ai/plugin").PluginInput} ctx */
async function runRebuild(ctx, sessionId, slug) {
  const { $, client } = ctx;
  const script = resolveRebuildScript();
  try {
    await $`bash ${script} ${sessionId} ${slug} --apply`.quiet();
    await client?.app?.log?.({
      body: {
        service: "brain-session-start",
        level: "info",
        message: "brain bootstrap ok",
        extra: { sessionId, slug, script },
      },
    });
  } catch (err) {
    await client?.app?.log?.({
      body: {
        service: "brain-session-start",
        level: "warn",
        message: "brain bootstrap degraded",
        extra: {
          sessionId,
          slug,
          script,
          error: String(err?.message || err),
        },
      },
    });
  }
}

/** Optional: delegate full Cursor hook (telemetry + pre-migration guards). */
async function delegateCursorHook(ctx, sessionId, workspaceRoot) {
  const { $ } = ctx;
  const payload = JSON.stringify({
    session_id: sessionId,
    workspace_root: workspaceRoot,
  });
  try {
    await $`bash ${CURSOR_HOOK}`.stdin(payload).quiet();
  } catch {
    /* fail-open */
  }
}

/** @type {import("@opencode-ai/plugin").Plugin} */
export const BrainSessionStartPlugin = async (ctx) => {
  const { directory, worktree } = ctx;

  return {
    event: async ({ event }) => {
      if (process.env.OPENCODE_BRAIN_BOOTSTRAP_DISABLED === "1") return;
      if (event.type !== "session.created") return;

      const info = event.properties?.info;
      if (info?.parentID) return;

      const sessionId = info?.id || "nosession";
      const workspaceRoot = worktree || directory || process.cwd();

      const slug = await resolveSlug(ctx, workspaceRoot);
      if (!slug) return;

      await runRebuild(ctx, sessionId, slug);

      if (process.env.OPENCODE_BRAIN_DELEGATE_CURSOR_HOOK === "1") {
        await delegateCursorHook(ctx, sessionId, workspaceRoot);
      }
    },
  };
};
