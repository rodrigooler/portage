# Portage

[![skills.sh](https://skills.sh/b/rodrigooler/portage)](https://skills.sh/rodrigooler/portage)

When you rename or move a project folder, coding agents keep pointing at the old path. Session history, trust lists, and local indexes do not follow the `mv`. Portage finds those bindings and rehomes them.

Directory listing: [skills.sh/rodrigooler/portage](https://skills.sh/rodrigooler/portage)

## Install (recommended)

Uses the [Vercel skills CLI](https://skills.sh) (`npx skills`). Global install (`-g`) puts the skill in your user agent dirs so every project can call `/portage`.

### Claude + Grok + Codex in one shot

```bash
npx skills add rodrigooler/portage \
  -g \
  -a claude-code -a grok -a codex \
  -s portage \
  -y
```

### One agent at a time

```bash
# Claude Code -> ~/.claude/skills/portage
npx skills add rodrigooler/portage -g -a claude-code -s portage -y

# Grok Build -> ~/.grok/skills/portage
npx skills add rodrigooler/portage -g -a grok -s portage -y

# Codex -> ~/.codex/skills/portage
npx skills add rodrigooler/portage -g -a codex -s portage -y
```

### Project-local (commit with the repo)

Omit `-g` so files land under the project (`.claude/skills`, `.grok/skills`, `.codex`/agents skills layout as the CLI chooses):

```bash
npx skills add rodrigooler/portage -a claude-code -a grok -a codex -s portage -y
```

### After install

In the agent:

```text
/portage
```

Or: `rehome ~/www/uova to ~/www/zk-project, dry-run first`.

Update later:

```bash
npx skills update portage -g -y
```

### Manual symlink (no npx)

```bash
git clone https://github.com/rodrigooler/portage.git
ln -sfn "$(pwd)/portage" ~/.claude/skills/portage
ln -sfn "$(pwd)/portage" ~/.grok/skills/portage
ln -sfn "$(pwd)/portage" ~/.codex/skills/portage
```

## The problem

Claude Code, Codex, Grok, and similar tools store state keyed by absolute path. If you rename `~/www/uova` to `~/www/zk-project`, the next session often looks empty. The data is still on disk under the old path encoding. You just cannot reach it from the new folder.

## What Portage is

1. An agent **skill** (`SKILL.md`) that walks intake, discovery, a written manifest, apply, and verify.
2. Shell helpers under `scripts/` for discover (read-only) and apply (with backups).

The skill is the orchestrator. The scripts are the mechanical bits you can also run by hand.

## Name

A portage is carrying a canoe between two rivers. Same boat, different water. Same sessions and trust, different folder path.

## CLI

```bash
chmod +x scripts/portage-discover.sh scripts/portage-apply.sh

# Read-only: list bindings for a path pair
./scripts/portage-discover.sh ~/www/uova ~/www/zk-project

# Preview mutations (default)
./scripts/portage-apply.sh ~/www/uova ~/www/zk-project

# Write (backs up first). Quit Claude/Codex/Grok on that project before this.
./scripts/portage-apply.sh --apply ~/www/uova ~/www/zk-project
```

Optional env:

| Variable | Effect |
|---|---|
| `PORTAGE_VAULT` | Vault root for filename scan in discover (default `~/Documents/obsidian-brain` if present) |
| `PORTAGE_STORES` | Comma list: `claude,codex,grok` (default all three core stores on apply) |

Apply covers Claude, Codex, and Grok state on disk. Vault note rewrites, CBM reindex, secrets renames, and Orca workspaces stay in the skill adapters (agent-mediated), so a human can approve each case.

## Stores

| Store | What gets rebound |
|---|---|
| Claude Code | `~/.claude/projects` (slash-dash path dirs), `.claude.json`, related history trees |
| Codex | Thread `cwd` in SQLite, `config.toml` project sections, session files when they embed the path |
| Grok | URL-encoded dirs under `~/.grok/sessions`, `trusted_folders.toml` |
| codebase-memory | Project id / reindex (skill) |
| Obsidian / brain vault | Absolute path strings in notes (skill; folder rename is opt-in) |
| `~/.claude-secrets` | Filename slug only if it matches the project name (skill; never dumps secrets) |
| Orca / worktrees | Workspace pointers (skill) |
| Other tools | `references/adapters/generic.md` describes how to add them |

Community scripts that only touch Claude and/or Codex can still help as accelerators. Portage still owns the multi-agent path, vault, and report:

- [claude-mv](https://github.com/curiouslychase/dotfiles/blob/main/scripts/claude-mv)
- [migrate-project](https://harnez.ai/posts/fix-broken-project-paths/)

## Safety

- Discover never writes.
- Apply defaults to dry-run. Mutations need `--apply`.
- Files are copied to `.bak` (or `.bak.<timestamp>`) before rewrite.
- Close Claude, Codex, and Grok for that project before apply so SQLite is not locked.
- Prefer rebind over delete. Session trees are not removed to "clean up".

Details: [docs/safety.md](docs/safety.md).

## Docs

| Doc | Audience |
|---|---|
| [docs/usage.md](docs/usage.md) | Humans running Portage day to day |
| [docs/safety.md](docs/safety.md) | Backups, locks, risk levels |
| [docs/architecture.md](docs/architecture.md) | How skill + stores + scripts fit |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Adding a store or fixing adapters |
| [SKILL.md](SKILL.md) | Instructions the agent follows |
| [references/](references/) | Intake, store table, per-tool adapters |

## Layout

```text
SKILL.md
README.md
CONTRIBUTING.md
LICENSE
docs/
  usage.md
  safety.md
  architecture.md
references/
  intake.md
  stores.md
  safety.md
  extending.md
  adapters/
scripts/
  portage-discover.sh
  portage-apply.sh
agents/
  openai.yaml
```

## License

MIT. See [LICENSE](LICENSE).
