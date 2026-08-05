# Stores: discovery order

A **store** is one place that holds path **bindings**. Portage walks stores in
this order so session history is rebound before secondary indexes.

| Order | Store id | Typical location | Adapter |
|---|---|---|---|
| 1 | `claude` | `~/.claude/projects/`, `~/.claude.json`, history/todos/file-history | [`adapters/claude.md`](adapters/claude.md) |
| 2 | `codex` | `~/.codex/state_5.sqlite`, `config.toml`, sessions, global state | [`adapters/codex.md`](adapters/codex.md) |
| 3 | `grok` | `~/.grok/sessions/`, `trusted_folders.toml`, active session index | [`adapters/grok.md`](adapters/grok.md) |
| 4 | `cbm` | codebase-memory project id (path with `/` replaced by `-`) | [`adapters/cbm.md`](adapters/cbm.md) |
| 5 | `vault` | Obsidian / brain notes that cite the path or project slug | [`adapters/vault.md`](adapters/vault.md) |
| 6 | `secrets` | `~/.claude-secrets/*.env.age` names (slug, not always path) | [`adapters/secrets.md`](adapters/secrets.md) |
| 7 | `orca` | Orca/worktree workspace roots | [`adapters/orca.md`](adapters/orca.md) |
| 8 | `generic` | User-named extras (Cursor, Windsurf, others) | [`adapters/generic.md`](adapters/generic.md) |

## Presence test

If the root path or primary file is missing, record `store_absent` and continue.
Absence is success for that row, not a failure.

## Hit shape

```text
store=<id> kind=live|ghost|content encoding=<raw|slash-dash|url> from=<path-or-encoded> to_suggest=<path-or-empty> evidence=<file-or-query>
```

## Encoding cheat sheet

| Encoding | Rule | Example |
|---|---|---|
| `raw` | absolute path as-is | `/Users/x/www/uova` |
| `slash-dash` | `/` and often `.` become `-` | `-Users-x-www-uova` |
| `url` | path URL-encoded as dir name | `%2FUsers%2Fx%2Fwww%2Fuova` |

Slash-dash decode is **lossy** when path segments contain `-`. Prefer an
authoritative map (`.claude.json` project keys) over naive reverse substitution.

## Optional external tools

If another CLI that rehomes Claude or Codex state is already installed and on PATH, you may use it as an accelerator after the Portage manifest is approved. Still verify with the adapters in this skill. Prefer the scripts shipped in this repository over fetching any remote executable.
