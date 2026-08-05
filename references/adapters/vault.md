# Adapter: vault / brain memory (`vault`)

## Roots

- Obsidian vault paths the brief named (example layout:
  `~/Documents/obsidian-brain/companies/{company}/{project}/`)
- Project `memory.md` and notes that embed absolute paths
- Session notes under `sessions/` that cite the old path

Vault **slug** (`companies/obo/uova`) is not the same object as the filesystem
project path (`~/www/uova`). Portage treats them separately: rehome path
citations always; rename the note folder only when the user asks.

## Discover

1. Existence test on the vault root.
2. Search note titles and bodies for `old_path` and the project basename.
3. If MCP `obsidian-brain` (or similar) is connected: `search_notes` for the path
   and project name; cap results; read only hits that will be edited.

## Rehome

Default (no explicit note-move):

1. For each note with absolute `old_path` strings: replace with `new_path`
   (structured edit; keep surrounding prose language as-is).
2. Report slug folders that still use the old project name.

When the user asked to move the project note folder:

1. Move `companies/.../old-slug` to `new-slug` only with an explicit slug pair.
2. Fix `[[wikilinks]]` that break. Wikilinks resolve by filename, so renaming
   files breaks backlinks. Prefer path-string updates inside notes over mass
   file renames unless the user owns that cost.

## Verify

- Search vault for `old_path`: residual list empty or itemized
- If folder moved: new folder exists, old absent, sample backlinks checked
