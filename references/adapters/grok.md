# Adapter: Grok (`grok`)

## Roots

| Artifact | Path pattern |
|---|---|
| Sessions | `~/.grok/sessions/<url-encoded-abs-path>/` |
| Trust | `~/.grok/trusted_folders.toml` keys like `[folders."/abs/path"]` |
| Active sessions | `~/.grok/active_sessions.json` |
| Worktrees | `~/.grok/worktrees/...` (path may embed project name) |
| Relocations locks | `~/.grok/relocations/*.lock` (session locks; not a path map) |

Encoding: full absolute path as a **URL-encoded** directory name
(`/` becomes `%2F`). Example: `/Users/a/www/uova` becomes
`%2FUsers%2Fa%2Fwww%2Fuova`.

## Discover

1. URL-encode `old_path`; test dir under `sessions/`.
2. Read `trusted_folders.toml` for the raw path key.
3. Search `active_sessions.json` and recent session metadata for the path.
4. List worktrees whose path contains the old basename when relevant.

```bash
python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$OLD"
```

## Rehome

1. Backup `trusted_folders.toml` and `active_sessions.json`.
2. If `sessions/<old-enc>` exists and dest is free: rename to `sessions/<new-enc>`.
   If dest exists: stop; choose merge vs clean in the manifest.
3. Rewrite trust table key from old path to new (`trusted = true` preserved).
4. Rewrite any active_sessions entries pointing at old path.
5. Leave `relocations/*.lock` alone unless a lock path embeds the project path
   and is clearly stale (report only).

`scripts/portage-apply.sh` covers session dir rename and trust file keys.

## Verify

- New session encoding dir exists when old had sessions
- `trusted_folders.toml` has new path; old key absent
- Grok started from `new_path` sees prior sessions, or files are readable under new-enc
