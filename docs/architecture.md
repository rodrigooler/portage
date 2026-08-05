# Architecture

## Pieces

```text
                 +------------------+
  user / agent   |  SKILL.md steps  |
                 +--------+---------+
                          |
          +---------------+---------------+
          |               |               |
          v               v               v
   references/*     portage-discover   portage-apply
   (adapters)         (read-only)       (mutate)
          |               |               |
          +-------+-------+-------+-------+
                  v               v
            on-disk stores (claude, codex, grok, ...)
```

- **Skill**: intake, which adapters to load, manifest language, verify, report.
- **references/**: durable knowledge per store. Loaded only when that store matters.
- **scripts/**: deterministic filesystem and SQLite work with low token cost.

## Why adapters are separate files

Each tool encodes paths differently and keeps state in different formats. Putting every recipe in `SKILL.md` would force the agent to load Codex rules when the machine only has Claude. Progressive disclosure keeps the top of the skill short.

## Encodings

| Name | Rule | Used by |
|---|---|---|
| raw | Absolute path string | Codex cwd, Grok trust keys, many configs |
| slash-dash | `/` and often `.` become `-` | Claude project dirs |
| url | Path fully URL-encoded as a directory name | Grok sessions |
| slug | Human project name inside a filename | age secrets |

Slash-dash decode is lossy when folder names already contain hyphens. Prefer keys in `.claude.json` over guessing the reverse map.

## Apply order

1. Claude session trees and `.claude.json`
2. Codex SQLite and config
3. Grok sessions and trust

History first, secondary indexes later. Vault and CBM sit outside the core apply script on purpose: they need judgment (which notes to edit, whether to reindex).

## Extending

See [CONTRIBUTING.md](../CONTRIBUTING.md) and [references/extending.md](../references/extending.md). New stores get an adapter file, a row in `stores.md`, and optional scan/apply functions in the scripts.
