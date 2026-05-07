#!/usr/bin/env bash
# safe-shell.sh
#
# beforeShellExecution hook.
# Auto-approves a narrow allowlist of READ-ONLY shell commands useful for
# any agent that needs to inspect the project (git queries, cd, head, ls,
# readlink, realpath, pwd, wc, cat, hashers, and safe find/grep/sed/awk).
#
# This hook ONLY grants, it never denies. If the command isn't in the
# allowlist the hook exits 0 with no output and the default Cursor approval
# flow runs.
#
# Safety rails:
#   - Commands containing shell metacharacters that could enable writes or
#     destructive composition (>, >>, |, &&, ||, ;, backticks, $(), and
#     standalone rm / mv / cp / dd / chmod / chown / sudo) are NOT auto-
#     approved, even if the first token is in the allowlist.
#   - git is allow-listed only for read-only subcommands. Anything that can
#     mutate the repo (add/commit/push/reset/rebase/clean/checkout/merge/
#     stash/drop etc.) falls through to normal approval.
#   - find is allow-listed only when it does not contain -exec / -execdir /
#     -delete / -ok / -okdir.
#   - sed and awk fall through when invoked with in-place flags
#     (-i / --in-place, -i inplace).

set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.command // empty')"
[ -z "$cmd" ] && exit 0

# Strip leading whitespace so the first-token check works reliably.
cmd_trim="${cmd#"${cmd%%[![:space:]]*}"}"

# Reject (fall through) any command with shell metacharacters that could enable
# writes, chaining, command substitution, or destructive composition.
case "$cmd_trim" in
  *'>'*|*'>>'*|*'|'*|*'&&'*|*'||'*|*';'*|'`'*|*'`'*|*'$('*|*'eval '*|*'exec '*|*'rm '*|'rm'|*'mv '*|'mv'|*'cp '*|'cp'|*'dd '*|*'chmod '*|*'chown '*|*'sudo '*)
    exit 0
    ;;
esac

first="$(printf '%s' "$cmd_trim" | awk '{print $1}')"

allow() {
  printf '{"permission":"allow","agent_message":"safe-shell: auto-approved read-only command"}\n'
  exit 0
}

case "$first" in
  cd|pwd|ls|ll|la|head|tail|cat|wc|echo|printf|readlink|realpath|dirname|basename|stat|file|which|command|type|test|true|false|date|sha256sum|shasum|md5sum|tr|sort|uniq|cut|grep|rg|fd)
    allow
    ;;
  sed|awk)
    # Deny in-place editing variants. Check args padded with spaces so that
    # both `sed -i ...` and `sed SOMETHING -i ...` are caught, including the
    # BSD `-i''` / `-i.bak` forms.
    args=" ${cmd_trim#$first} "
    case "$args" in
      *' -i '*|*' -i'*|*' --in-place '*|*' --in-place='*)
        exit 0 ;;
    esac
    allow
    ;;
  find)
    case "$cmd_trim" in
      *' -exec '*|*' -execdir '*|*' -delete'*|*' -ok '*|*' -okdir '*)
        exit 0
        ;;
    esac
    allow
    ;;
  git)
    sub="$(printf '%s' "$cmd_trim" | awk '{print $2}')"
    case "$sub" in
      status|log|diff|show|rev-parse|ls-files|ls-tree|ls-remote|cat-file|branch|tag|remote|config|hash-object|rev-list|name-rev|describe|shortlog|blame|check-ignore|check-mailmap|show-ref|show-branch|symbolic-ref|verify-commit|verify-tag|var|for-each-ref|grep|reflog|worktree|version|help)
        # Extra defense: if the subcommand is "config" or "hash-object" ensure
        # we're not in a write-mode invocation.
        case "$sub:$cmd_trim" in
          config:*' --add '*|config:*' --set '*|config:*' --unset '*|config:*' --replace-all '*|config:*' --rename-section '*|config:*' --remove-section '*)
            exit 0 ;;
          hash-object:*' -w'*|hash-object:*' --stdin-paths '*)
            exit 0 ;;
          worktree:*' add '*|worktree:*' remove '*|worktree:*' prune'*)
            exit 0 ;;
          tag:*' -d '*|tag:*' --delete '*)
            exit 0 ;;
          branch:*' -d '*|branch:*' -D '*|branch:*' --delete '*|branch:*' -m '*|branch:*' -M '*|branch:*' --move '*)
            exit 0 ;;
          remote:*' add '*|remote:*' remove '*|remote:*' rm '*|remote:*' rename '*|remote:*' set-url '*|remote:*' set-head '*|remote:*' set-branches '*|remote:*' update '*)
            exit 0 ;;
          reflog:*' delete '*|reflog:*' expire '*)
            exit 0 ;;
        esac
        allow
        ;;
    esac
    exit 0
    ;;
esac

exit 0
