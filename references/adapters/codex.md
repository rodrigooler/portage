# Adapter: Codex (`codex`)

## Roots

| Artifact | Path pattern |
|---|---|
| Thread cwd | `~/.codex/state_5.sqlite` (probe schema; often `threads.cwd`) |
| Project config | `~/.codex/config.toml` sections like `[projects."/abs/path"]` |
| Global state | `~/.codex/.codex-global-state.json` |
| Session rollouts | `~/.codex/sessions/**/rollout-*.jsonl` |
| Session index | `~/.codex/session_index.jsonl` |

Also check `~/.codex/sqlite/` for alternate db layouts on newer installs.

## Discover

1. `sqlite3` distinct `cwd` values matching `old_path` (or missing-on-disk ghost cwds).
2. Search `config.toml` for `[projects."..."]` and `source =` lines.
3. Search sessions and global state for the path string.

Schema probe (completion criterion: you saw the real table and column names):

```bash
sqlite3 ~/.codex/state_5.sqlite ".schema" | head -100
```

## Rehome

1. Close Codex.
2. Backup sqlite (+ wal/shm), `config.toml`, global state.
3. `UPDATE` thread cwd old to new only after schema is confirmed.
4. Rewrite `config.toml` section headers and path values (structured TOML edit preferred).
5. Replace path strings in global state and matching rollout files.
6. Patch `session_index.jsonl` if it stores cwd or workspace paths.

`scripts/portage-apply.sh` covers SQLite cwd, config.toml project headers, and a
best-effort pass over session jsonl files.

## Verify

- Thread count for new cwd is greater than zero when threads existed
- `config.toml` has the new path section; old section gone
- Residual old path under `~/.codex` is listed or confirmed none
