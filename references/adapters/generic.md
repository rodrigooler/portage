# Adapter: generic / unknown tools (`generic`)

Use when the brief names a tool without a dedicated adapter (Cursor, Windsurf,
Aider, Continue, JetBrains AI, and similar) or when extending Portage mid-run.

## Discover protocol

For tool **T**:

1. Ask or recall **one** config root (example: `~/.cursor`,
   `~/Library/Application Support/...`).
2. Search that root for the absolute `old_path` string (files only; skip huge
   binary caches unless a known index format exists).
3. Classify each hit: `config`, `session`, `index`, or `cache`.
4. Prefer rebinding config and session. Treat pure cache as "delete cache /
   reindex" rather than rewrite.

## Rehome protocol

1. Backup each file you will edit.
2. Replace path strings with the same encoding the tool uses (detect from
   samples: raw, slash-dash, or url).
3. If the tool uses SQLite: schema-probe, then UPDATE cwd-like columns only.
4. Document what you did as a candidate for `references/adapters/<tool>.md`
   (Extend branch).

## Verify

- Search old path under the config root; residuals listed
- Tool opens the project from `new_path` without recreating empty state (user
  observation when automation cannot launch the GUI)
