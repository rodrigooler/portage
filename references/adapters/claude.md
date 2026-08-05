# Adapter: Claude Code (`claude`)

## Roots

| Artifact | Path pattern |
|---|---|
| Sessions / project state | `~/.claude/projects/<slash-dash>/` |
| Project config map | `~/.claude.json` keys `projects`, `githubRepoPaths` |
| History index | `~/.claude/history.jsonl` |
| Todos / file-history / shell-snapshots | `~/.claude/{todos,file-history,shell-snapshots}/<slash-dash>/` |

Encoding: `/` and `.` become `-` (leading `-`). Authoritative reverse map: keys in
`.claude.json` `projects` when present.

## Discover

1. Encode `old_path` and look for a dir under `projects/`.
2. Search `.claude.json` for the raw `old_path` key.
3. Scan `history.jsonl` for the path string.
4. Note sibling trees (todos, file-history) with the same encoding.

## Rehome

1. Backup `.claude.json` and any dir you will rename.
2. Rename `projects/<old-enc>` to `projects/<new-enc>`. If dest exists: stop and
   ask (clean vs merge).
3. Rename matching dirs under todos/file-history/shell-snapshots when present.
4. Rewrite path strings inside session `.jsonl` files from old to new.
5. Update `.claude.json` project key and `githubRepoPaths` (structured edit;
   Python or jq preferred over blind sed).
6. Patch `history.jsonl` path fields.

`scripts/portage-apply.sh` covers steps 1-3 and 5 for the common case.
If `claude-mv` is on PATH and `scope` includes moving the folder, it may also
rewrite sessions and move the project tree. Verify afterward either way.

## Verify

- `test -d ~/.claude/projects/<new-enc>`
- Search for the old path under that tree; residuals must be listed or empty
- Opening Claude from `new_path` lists prior sessions, or session files are
  non-empty under the new encoding
