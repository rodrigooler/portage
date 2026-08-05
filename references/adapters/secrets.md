# Adapter: encrypted secrets (`secrets`)

## Roots

`~/.claude-secrets/<name>.env.age` (and similar age/sops layouts).

Names are usually **slugs** (`skyw3b-uova-v1-....env.age`), not absolute paths.
Portage only acts when the basename embeds the old project slug the user is
retiring.

## Discover

```bash
ls ~/.claude-secrets 2>/dev/null | grep -F "<old-basename-or-slug>"
```

## Rehome

1. Renaming the `.env.age` file is optional and only when the user wants the
   slug to match the new project name.
2. Never decrypt secrets into the chat or into unencrypted files.
3. If a secret file is renamed, update any docs or scripts that reference the old
   filename (search `~/.claude`, vault, project README) without printing values.

## Verify

- Expected filename present if renamed
- Decrypt still works in the user's normal load recipe (user runs it; agent
  confirms exit code only if the user authorizes a decrypt test)
