# Adapter: Orca / worktree hosts (`orca`)

## Roots

Common layouts:

- `~/orca/workspaces/<project>/...`
- `~/.ork/...` / paperclip workspaces
- Agent worktrees under `~/.grok/worktrees/...` or Claude worktree encodings

## Discover

1. Find directories whose path contains the old basename under known workspace roots.
2. Check active workspace metadata if present (JSON/TOML under the orca config dir).

## Rehome

1. Prefer updating workspace config pointers to `new_path` over moving Orca's
   own workspace clones.
2. If a workspace **is** a clone of the project at the old path, treat it as a
   separate portage brief. Do not silently `mv` nested workspaces.
3. Report worktrees that still target old path for manual `git worktree` repair.

## Verify

- Config points at `new_path`
- `git -C <workspace> rev-parse --show-toplevel` matches intent when git-backed
