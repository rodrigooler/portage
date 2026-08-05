# Intake: mining a portage brief

Intake is legwork on the human message, not a questionnaire ritual. Prefer
evidence already in the prompt, the shell cwd, and the filesystem. Ask only for
blockers.

## Leading signals in free text

Map language to brief fields:

| User language | Field |
|---|---|
| "renomeei", "renamed", "mv", "moved", "moved the folder" | `folder_state`: lean `already_at_new` if past tense; else ask |
| "uova to zk-project", two paths, old/new | `old_path`, `new_path` |
| "history disappeared", "sessions gone", "lost context" | branch **Recover** |
| "Claude", "Codex", "Grok", "Cursor", "Warp" | `agents` |
| "Obsidian", "vault", "brain", "memory.md" | `memory` present; chase path |
| "just fix pointers", "don't move the folder" | `scope` = `bindings_only` |
| "rename it for me" | `scope` = `move_folder_and_bindings` |
| "dry run", "what would change", "check first" | `mode` = `dry-run`, branch **Plan** |
| "do it", "apply", "go" | `mode` = `apply` only after a **manifest** existed or both paths plus apply intent are clear |

## Resolve paths

1. Expand `~` and make absolute.
2. If only basenames are given, search common parents: `~/www`, `~/code`,
   `~/projects`, `~/Developer`, `~/src`, and cwd parents. One match: use it.
   Many matches: list and ask.
3. If `old_path` is missing but Recover: scan stores for ghost basenames matching
   the project name the user said.
4. Do not invent a company/vault slug from the folder name alone. Ask or search
   the vault index.

## Memory surfaces (probe once)

When `memory` is `unknown`, check presence (cheap existence tests). Do not deep-read yet:

- Obsidian vault roots the user already uses (example: `~/Documents/obsidian-brain`)
- Project-local agent memory: `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.codex/`, `.grok/`
- Encrypted secrets naming that embeds the project slug (`~/.claude-secrets/*`)
- Issue trackers only if the user mentioned tickets

If a vault exists, ask once whether to update note paths or move the project note
folder. Default when silent: search and report residual path strings; mutate notes
only with an explicit yes.

## Stack fingerprint

Infer agents from what is installed and has state:

```text
~/.claude/projects                              Claude Code
~/.codex/state_5.sqlite or ~/.codex/sessions    Codex
~/.grok/sessions                                Grok
codebase-memory / CBM project list              graph index
~/orca or .orca                                 Orca workspaces
```

User-named agents win over fingerprint when they disagree. Include both and mark
the source.

## One-shot ask template (missing blockers only)

```text
Portage needs:
1. Old path (absolute)
2. New path (absolute)
3. Folder already moved? (yes/no)
4. Agents in play (or "all you find")
5. Memory/vault to update? (path or none)
6. Dry-run or apply?
```

Send only the numbered lines still empty.
