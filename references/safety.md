# Safety (agent)

Human-oriented detail: [`docs/safety.md`](../docs/safety.md).

## Modes

| Mode | Writes | Default when |
|---|---|---|
| `dry-run` | none (read + report) | mode unset, Plan branch, first run on a new machine |
| `apply` | backups then mutations | user said apply/go after a **manifest**, or brief has both paths and clear apply intent |

Dry-run is the default. Apply is opt-in.

## Close-tools rule

Before apply on SQLite-backed stores (Codex `state_*.sqlite`, some Claude locks):

1. Ask the user to quit Claude Code, Codex, and Grok on that project.
2. If they decline, mark those rows `skipped` with reason `lock_risk` and continue others.

## Backup rule

Before the first write to a file or rename of a state directory:

- File: copy to `<name>.bak` (or `<name>.bak.<timestamp>` if `.bak` exists)
- Directory rename: destination must be absent, or merge strategy chosen in the manifest
- SQLite: `cp` the db and any `-wal`/`-shm` siblings with `.bak`

On failure: restore from `.bak` over the live file and report that restore ran.

## High-risk rows (need explicit go-ahead)

- Moving the project directory itself
- Merging two existing session trees for the same project
- DELETE of any binding (prefer rebind; delete only if the user orders it)

## Operating preferences

- Rebind and rename over delete
- Adapter order in `stores.md`
- Filesystem evidence over remembered paths
- One scannable manifest over silent multi-file edits
