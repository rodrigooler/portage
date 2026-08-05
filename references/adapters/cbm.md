# Adapter: codebase-memory-mcp (`cbm`)

## Roots

Project id is typically the repo root with `/` replaced by `-` (confirm with live
MCP `list_projects` or server docs). Graph data lives under the MCP local cache
(often `~/.cache/codebase-memory-mcp`).

## Discover

1. Call MCP `list_projects` when available; match `old_path` or encoded form.
2. If MCP is unavailable: search cache dirs for the encoded project name.
3. Record whether a **ghost** project id exists without a live folder.

## Rehome

Prefer MCP lifecycle over hand-editing SQLite:

1. `index_repository` on `new_path` (creates or updates the new project).
2. When the API allows delete or rename of the old project id, remove or rename
   the ghost so agents stop resolving the stale graph. If only delete exists:
   delete old after the new index is healthy.
3. If MCP is down: report a manual step (re-open the agent in the new path and
   re-index). Leave cache surgery to the user.

## Verify

- `list_projects` / `index_status` shows `new_path` (or its project id) ready
- Old project id absent or marked stale in the report
- A trivial `search_graph` or `search_code` against the new project returns hits
  when the repo has source files
