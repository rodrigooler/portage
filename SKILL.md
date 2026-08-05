---
name: portage
description: >
  Portage rehomes agent bindings when a project directory is renamed or moved
  so sessions, trust, memory, and indexes keep working. Use when the user
  renames or moves a project folder, reports lost Claude/Codex/Grok history
  after a path change, wants to repath or rehome agent state, or has ghost
  paths after `mv`. Also use when another skill needs a safe multi-store path
  rebind. Prefer dry-run before apply.
license: MIT
metadata:
  short-description: Rehome agent bindings after a folder rename or move
  open-source: true
---

# Portage

Carry every **binding** across a path change the way a canoe is portaged between
rivers. The folder moves once. Tools that keyed state on the old path stay put
until you rehome them.

**Branches** (pick one primary; note any secondary):

| Branch | Signal | Mode |
|---|---|---|
| **Plan** | "what would break", "check first", ambiguous stack | Discover + **manifest** only |
| **Apply** | "rename and fix", "rehome it", old and new paths given | Full sequence including mutate |
| **Recover** | "history vanished", folder already renamed | Discover ghosts, rebind to current path |
| **Extend** | "add Cursor/Warp", "new store" | `references/extending.md` |

Do not narrate step numbers to the user. Run them. Report outcomes.

Deeper material loads on demand:

- Intake and context mining: [`references/intake.md`](references/intake.md)
- Known stores and discovery order: [`references/stores.md`](references/stores.md)
- Backup, close-tools, dry-run: [`references/safety.md`](references/safety.md)
- Per-tool adapters: [`references/adapters/`](references/adapters/)
- Adding stores: [`references/extending.md`](references/extending.md)
- Discover CLI: [`scripts/portage-discover.sh`](scripts/portage-discover.sh)
- Apply CLI: [`scripts/portage-apply.sh`](scripts/portage-apply.sh)
- Human docs: [`docs/usage.md`](docs/usage.md)

## Step 0: Safety gate

Read [`references/safety.md`](references/safety.md).

**Done when:** mode is explicit (`dry-run` or `apply`), tools that lock SQLite are
closed or the user accepts residual lock risk, and every mutate path will write
a `.bak` (or equivalent) before the first write.

## Step 1: Intake

Read [`references/intake.md`](references/intake.md). Fill a **portage brief** from
the user message first. Ask only for fields that still block discovery. Batch
missing fields in one message.

Minimum brief:

| Field | Required |
|---|---|
| `old_path` | yes (absolute or resolvable) |
| `new_path` | yes for Plan/Apply; for Recover, resolve from live cwd or basename search |
| `folder_state` | `still_at_old` \| `already_at_new` \| `unknown` |
| `agents` | list the user named; if empty, discover all present stores |
| `memory` | vault / brain / notes paths if any, or `none` / `unknown` |
| `scope` | `bindings_only` \| `move_folder_and_bindings` |
| `mode` | `dry-run` \| `apply` (default dry-run when unset) |

**Done when:** every required field has a value, assumptions are labeled, and
you can name which adapters will run.

## Step 2: Discover

Read [`references/stores.md`](references/stores.md). For each candidate store that
exists on this machine (and any the brief named), load its adapter under
`references/adapters/` and collect **hits**:

- live bindings on `old_path`
- **ghost paths** (encoded dirs or cwd rows whose target is missing)
- confidence of a suggested `new_path` when Recover

Prefer the discover script when present:

```bash
bash scripts/portage-discover.sh "$OLD_PATH" "$NEW_PATH"
```

**Done when:** you have a hit list for every present store (or an explicit
`store_absent` line), including stores checked with zero hits.

## Step 3: Manifest

Build a **manifest**: ordered rows of `{store, action, from, to, risk}`.
Show it before any mutate. Risk labels: `low` (rename empty metadata),
`medium` (rewrite config/session paths), `high` (SQLite, merge of two session
trees, moving the project folder).

**Done when:** the user has seen the full manifest (or mode is Plan and you stop
here). For Apply, you have an explicit go-ahead for high-risk rows, or the user's
original wording already authorized that scope (quote it).

Plan branch stops after this step.

## Step 4: Portage

For each manifest row, in store order from `stores.md`:

1. Backup per adapter (or run `scripts/portage-apply.sh` for claude/codex/grok).
2. Apply the rehome procedure.
3. Record result (`ok` / `skipped` / `failed` plus evidence).

When `scripts/portage-apply.sh` covers the store, prefer it over ad-hoc shell:

```bash
# dry-run
bash scripts/portage-apply.sh "$OLD_PATH" "$NEW_PATH"
# mutate
bash scripts/portage-apply.sh --apply "$OLD_PATH" "$NEW_PATH"
```

Move the project folder only if `scope` is `move_folder_and_bindings` and
`folder_state` is `still_at_old`. Rehome tool bindings before `mv` when the
adapter needs the old path present for rewrite; otherwise follow the adapter order.

**Done when:** every manifest row has a recorded result. No silent omissions.

## Step 5: Verify

For each store that reported `ok`, run the adapter verification (new encoding
exists, cwd rows updated, trust entry present, residual old path search).

Report leftovers as open items, not as success.

**Done when:** every `ok` row has a verification observation, and residual
old-path hits are listed or confirmed none.

## Step 6: Report

Outcome first:

1. What rehomed (store and status).
2. What stayed manual, failed, or skipped.
3. Residual ghost paths or old-path strings.
4. Suggested next open of each agent from `new_path`.
5. If memory/vault was in scope: notes updated or only searched.

**Done when:** a teammate who never saw the session can finish any leftover from
the report alone.
