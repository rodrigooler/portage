# Extending Portage for other stacks

## When this branch runs

The user asks to support another agent or IDE, or discovery finds bindings in an
unknown root that mattered.

## Add an adapter (definition of done)

1. Create `references/adapters/<id>.md` with sections: **Roots**, **Discover**,
   **Rehome**, **Verify** (same headings as existing adapters).
2. Add one row to the table in `stores.md` with order, store id, typical
   location, and link.
3. If discovery can be automated cheaply, extend `scripts/portage-discover.sh`
   with a scan that prints the common hit line format.
4. Run one dry-run on a real machine path and paste hit lines under
   `## Tested` (date + OS) on the adapter.

## Encoding

State the encoding explicitly (`raw`, `slash-dash`, `url`, or a custom rule).
If decode is lossy, name the authoritative map file.

## Keep the top thin

- Tool-specific steps stay in adapters, not in `SKILL.md`.
- No cloud APIs or telemetry for core rehome.
- Rebind first. Do not delete user sessions as a fix.
