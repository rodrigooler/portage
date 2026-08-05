# Contributing

## Ground rules

- Keep `SKILL.md` short. Tool detail goes in `references/adapters/`.
- Discover stays read-only.
- Apply must backup before write and support dry-run.
- No telemetry. No network calls required for core rehome.
- Docs and skill text: plain English, no em dash as punctuation, no marketing adjectives.

## Add a store

1. Write `references/adapters/<id>.md` with **Roots**, **Discover**, **Rehome**, **Verify**.
2. Add a row to `references/stores.md`.
3. If scanning is cheap, add a block to `scripts/portage-discover.sh`.
4. If mutation is safe and local, add a block to `scripts/portage-apply.sh` behind `PORTAGE_STORES`.
5. Run discover against a real path on your machine and note date/OS under `## Tested` on the adapter.

## Test locally

```bash
./scripts/portage-discover.sh "$HOME/www/some-project" "$HOME/www/some-project-renamed"
./scripts/portage-apply.sh "$HOME/www/some-project" "$HOME/www/some-project-renamed"
# only when you mean it:
# ./scripts/portage-apply.sh --apply ...
```

Prefer dry-run on a project you care about. For destructive tests, use a throwaway clone and synthetic paths under `/tmp` only if the stores under test accept them.

## Prose

When editing README or docs:

- Prefer short sentences and concrete verbs.
- Use commas, colons, or parentheses instead of em dashes.
- Skip filler ("it is important to note", "robust and scalable", automatic triads of adjectives).
- Code and path examples beat abstract claims.

## Pull requests

Say what store or doc you changed and how you verified it (command + observed result). Screenshots are optional; terminal output is enough.
