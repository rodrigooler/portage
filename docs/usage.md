# Usage

## Typical flow

1. Decide old path and new path (absolute paths are best).
2. Run discover (or ask the agent for a dry-run portage).
3. Read the hit list / manifest. Nothing should surprise you.
4. Quit agents that might lock SQLite on that project.
5. Apply, or tell the agent to apply after you approve the manifest.
6. Open the project from the new path and confirm history is back.

## Skill branches

| You want | Say roughly | What runs |
|---|---|---|
| Preview only | "what would break if I rename X to Y" | Discover + manifest, stop |
| Full rehome | "rehome X to Y" / "apply" | Full sequence after approval |
| Already renamed | "I renamed X, sessions are gone" | Recover: find ghost bindings, rebind to current path |
| New tool support | "add Cursor as a store" | Extend path in `references/extending.md` |

## Discover CLI

```bash
./scripts/portage-discover.sh /Users/you/www/old-name /Users/you/www/new-name
```

Each hit looks like:

```text
store=claude kind=live encoding=slash-dash from=... to_suggest=... evidence=...
```

| Field | Meaning |
|---|---|
| `store` | Tool bucket |
| `kind` | `live` (path exists), `ghost` (binding left after path died), `absent` (tool not installed) |
| `encoding` | How the path is stored (`raw`, `slash-dash`, `url`, `slug`) |
| `from` | Current binding |
| `to_suggest` | Encoded new path when you passed a new path |
| `evidence` | File or query that produced the hit |

## Apply CLI

```bash
# Dry-run (default)
./scripts/portage-apply.sh /Users/you/www/old /Users/you/www/new

# Mutate
./scripts/portage-apply.sh --apply /Users/you/www/old /Users/you/www/new

# Only some stores
PORTAGE_STORES=claude,grok ./scripts/portage-apply.sh --apply /old /new
```

What apply does today:

| Store | Actions |
|---|---|
| Claude | Rename `~/.claude/projects/<enc>` and matching todos/file-history/shell-snapshots dirs when present; rewrite path keys inside `.claude.json` |
| Codex | Backup SQLite; `UPDATE` thread cwd when the schema matches; rewrite `config.toml` project headers that quote the old path; replace old path strings in matching session jsonl files (best effort) |
| Grok | Rename session dir under `~/.grok/sessions`; rewrite `trusted_folders.toml` folder keys |

What apply does **not** do (use the skill / manual steps):

- Move the project folder itself (`mv ~/www/old ~/www/new`)
- Rewrite Obsidian note bodies
- Reindex codebase-memory
- Rename `.env.age` secret files
- Merge two session trees when both old and new encodings already exist (script aborts that store with a clear message)

## After apply

1. `cd` into the new project path.
2. Start each agent once and confirm prior threads show up.
3. If something is missing, check the `.bak` files next to the configs you touched and the report lines from the script.

## Recover after a blind rename

You already ran `mv` and history vanished:

```bash
# old path is the previous location (may not exist on disk anymore)
./scripts/portage-discover.sh /Users/you/www/old-name /Users/you/www/new-name
./scripts/portage-apply.sh --apply /Users/you/www/old-name /Users/you/www/new-name
```

Discover still finds encoded dirs under `~/.claude/projects` and friends even when the project folder is gone.
