# Changelog

## 0.1.2

- Remove third-party executable script links from skill and docs (Snyk E005)
- Treat user-supplied paths as data only with validation in skill and CLI (Snyk W011)
- Add `references/security.md`

## 0.1.1

- Document `npx skills add` install for Claude Code, Grok, and Codex
- Link skills.sh directory listing and badge

## 0.1.0

- Skill `portage` with intake, discover, manifest, apply, verify, report
- Adapters for Claude, Codex, Grok, CBM, vault, secrets, Orca, generic
- `scripts/portage-discover.sh` (read-only)
- `scripts/portage-apply.sh` (dry-run by default; `--apply` mutates with backups)
- Human docs: README, usage, safety, architecture, CONTRIBUTING
