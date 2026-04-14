---
name: kb-identity
description: Agent-based project identity derivation for Knowledge Base. Reads git config directly without shell commands. Worktree-safe — all worktrees of the same repo derive the same identity.
version: 1
input_schema:
  required:
    - name: project_root
      type: string
      description: Absolute path to the project root directory
output_schema:
  required:
    - name: status
      type: string
      description: Result status - success, not_git_repo, or error
    - name: project_name
      type: string
      description: Human-readable project name (lowercase, from repo name or folder)
    - name: full_identity
      type: string
      description: Unique identity across orgs - "<project_name>-<identity_hash>"
    - name: kb_path
      type: string
      description: Full path to KB directory for this project
  optional:
    - name: identity_hash
      type: string
      description: First 8 chars of SHA256(remote_url) for uniqueness
    - name: remote_url
      type: string
      description: Git remote origin URL if available
    - name: is_worktree
      type: boolean
      description: Whether the project is a git worktree
    - name: main_repo_path
      type: string
      description: Path to main repo if this is a worktree
    - name: derived_from
      type: string
      description: Source of project name - "remote_origin" or "folder_name"
    - name: error
      type: string
      description: Error message if status is not success
pre_checks:
  - description: Project root must be provided
    validation: project_root is not empty
  - description: Project root should be absolute path
    validation: project_root starts with /
post_checks:
  - description: Status is always returned
    validation: status is not empty
  - description: Success returns required identity fields
    validation: if status is success then project_name and full_identity and kb_path are returned
cacheable: true
cache_ttl_minutes: 60
---

# kb-identity Skill

Derive project identity for Knowledge Base operations. This skill reads git configuration directly without shell commands, making it portable and worktree-safe.

## Overview

The KB uses project identity to:
- Determine the KB path: `~/.cursor/docs/knowledge-base/projects/<project_name>/`
- Ensure all worktrees of the same repo share one KB
- Generate unique identities across different organizations (same repo name, different orgs)

## Algorithm

### Step 1: Locate git directory

Read the `.git` entry at `project_root`:

```
if .git does not exist:
    return { status: "not_git_repo", error: "No .git found at project_root" }

if .git is a FILE (not directory):
    # This is a worktree
    is_worktree = true
    
    # Read .git file content
    # Format: "gitdir: /path/to/main/.git/worktrees/<name>"
    git_file_content = read_file(project_root/.git)
    
    # Parse gitdir path
    gitdir_line = extract line starting with "gitdir:"
    worktree_git_path = gitdir_line after "gitdir: " (trimmed)
    
    # Navigate to main repo's .git directory
    # worktree_git_path is like: /main/repo/.git/worktrees/feature-branch
    # Main .git is: /main/repo/.git
    main_git_path = worktree_git_path up to and including ".git" (before "/worktrees/")
    main_repo_path = parent of main_git_path
    
    git_config_path = main_git_path + "/config"

else:
    # Normal checkout
    is_worktree = false
    main_repo_path = null
    git_config_path = project_root + "/.git/config"
```

### Step 2: Read git config

Read the git config file and parse INI format:

```
config_content = read_file(git_config_path)

# Parse INI format to find [remote "origin"] section
# Look for:
#   [remote "origin"]
#       url = <remote_url>

remote_url = extract url from [remote "origin"] section

if remote_url not found:
    remote_url = null
    derived_from = "folder_name"
else:
    derived_from = "remote_origin"
```

### Step 3: Extract repo name from URL

Handle common git URL patterns:

```
if remote_url is null:
    project_name = basename(project_root).lowercase()
else:
    # Pattern matching for common formats:
    
    # HTTPS: https://github.com/owner/repo.git
    # HTTPS no .git: https://github.com/owner/repo
    if remote_url starts with "https://":
        path = URL path after host
        project_name = last path segment, remove .git suffix
    
    # SSH: git@github.com:owner/repo.git
    if remote_url starts with "git@":
        path = part after ":"
        project_name = last path segment, remove .git suffix
    
    # SSH protocol: ssh://git@host/path/repo.git
    if remote_url starts with "ssh://":
        path = URL path
        project_name = last path segment, remove .git suffix
    
    # GitLab subgroups: gitlab.com/group/subgroup/repo.git
    # Same logic — take last segment
    
    project_name = project_name.lowercase()
    project_name = remove .git suffix if present
```

### Step 4: Generate identity hash

Create a unique identity to distinguish same-named repos across orgs:

```
if remote_url is not null:
    # SHA256 of remote URL, first 8 characters
    identity_hash = sha256(remote_url).substring(0, 8)
    full_identity = project_name + "-" + identity_hash
else:
    # No remote, use folder path for uniqueness
    identity_hash = sha256(project_root).substring(0, 8)
    full_identity = project_name + "-" + identity_hash
```

### Step 5: Determine KB path

```
kb_path = "~/.cursor/docs/knowledge-base/projects/" + project_name + "/"
# Expand ~ to actual home directory
```

### Step 6: Return result

```
return {
    status: "success",
    project_name: project_name,
    full_identity: full_identity,
    identity_hash: identity_hash,
    kb_path: kb_path,
    remote_url: remote_url,
    is_worktree: is_worktree,
    main_repo_path: main_repo_path,
    derived_from: derived_from
}
```

## Examples

### Normal checkout with GitHub remote

```
Input: project_root = "/Users/dev/myapp"

.git is a directory
.git/config contains:
    [remote "origin"]
        url = git@github.com:acme/myapp.git

Output:
    status: "success"
    project_name: "myapp"
    identity_hash: "a1b2c3d4"
    full_identity: "myapp-a1b2c3d4"
    kb_path: "/Users/dev/.cursor/docs/knowledge-base/projects/myapp/"
    remote_url: "git@github.com:acme/myapp.git"
    is_worktree: false
    derived_from: "remote_origin"
```

### Git worktree

```
Input: project_root = "/Users/dev/myapp-feature"

.git is a FILE containing:
    gitdir: /Users/dev/myapp/.git/worktrees/myapp-feature

Main repo's .git/config contains:
    [remote "origin"]
        url = git@github.com:acme/myapp.git

Output:
    status: "success"
    project_name: "myapp"
    identity_hash: "a1b2c3d4"  # Same as main checkout!
    full_identity: "myapp-a1b2c3d4"
    kb_path: "/Users/dev/.cursor/docs/knowledge-base/projects/myapp/"
    remote_url: "git@github.com:acme/myapp.git"
    is_worktree: true
    main_repo_path: "/Users/dev/myapp"
    derived_from: "remote_origin"
```

### No remote (local-only repo)

```
Input: project_root = "/Users/dev/experiments/local-project"

.git is a directory
.git/config has no [remote "origin"] section

Output:
    status: "success"
    project_name: "local-project"
    identity_hash: "e5f6g7h8"  # From SHA256 of project_root
    full_identity: "local-project-e5f6g7h8"
    kb_path: "/Users/dev/.cursor/docs/knowledge-base/projects/local-project/"
    remote_url: null
    is_worktree: false
    derived_from: "folder_name"
```

## INI Parsing Notes

Git config uses INI format. To parse:

1. Split by lines
2. Look for section headers: `[section]` or `[section "name"]`
3. Within sections, look for `key = value` or `key=value`
4. Handle whitespace (leading tabs/spaces are common)

Example config structure:
```ini
[core]
    repositoryformatversion = 0
    filemode = true
[remote "origin"]
    url = git@github.com:owner/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
    remote = origin
    merge = refs/heads/main
```

## Error Handling

| Condition | Status | Error |
|-----------|--------|-------|
| `.git` not found | `not_git_repo` | "No .git found at {project_root}" |
| Cannot read `.git/config` | `error` | "Cannot read git config at {path}" |
| Worktree gitdir parse failure | `error` | "Cannot parse worktree gitdir" |
| Invalid remote URL format | Continue | Use folder name fallback |

## Caching

Results are cacheable for 60 minutes. The cache key is `project_root`.

Cache invalidation triggers:
- `.git/config` modification
- Worktree creation/deletion
- Remote URL change
