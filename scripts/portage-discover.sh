#!/usr/bin/env bash
# portage-discover.sh : read-only scan of known agent stores for path bindings.
# Usage: portage-discover.sh <old_path> [new_path]
# Exit 0 always when scan completes; prints hit lines on stdout.

set -euo pipefail

OLD="${1:-}"
NEW="${2:-}"

if [[ -z "$OLD" ]]; then
  echo "usage: $0 <old_path> [new_path]" >&2
  exit 2
fi

# Path data only: reject shell/control metacharacters before any use.
validate_path() {
  python3 - "$1" <<'PY'
import os, re, sys
raw = sys.argv[1]
if not raw or any(c in raw for c in "\n\r\0`$;&|<>(){}[]*?!\\"):
    print("invalid path (empty or metacharacters)", file=sys.stderr)
    sys.exit(2)
expanded = os.path.expanduser(raw)
abs_path = os.path.abspath(expanded)
# Allow common absolute path characters only after expand.
if not re.fullmatch(r"/[A-Za-z0-9._/\- ]*", abs_path):
    print(f"invalid path characters: {abs_path!r}", file=sys.stderr)
    sys.exit(2)
print(abs_path)
PY
}

OLD="$(validate_path "$OLD")"
[[ -n "$NEW" ]] && NEW="$(validate_path "$NEW")"

slash_dash() {
  # Claude-style: / and . → -
  python3 -c 'import sys; p=sys.argv[1]; print(p.replace("/", "-").replace(".", "-"))' "$1"
}

url_enc() {
  python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

hit() {
  # store kind encoding from to_suggest evidence
  printf 'store=%s kind=%s encoding=%s from=%s to_suggest=%s evidence=%s\n' "$@"
}

path_kind() {
  local p="$1"
  if [[ -e "$p" ]]; then
    echo live
  else
    echo ghost
  fi
}

echo "# portage discover"
echo "# old=$OLD"
echo "# new=${NEW:-}"
echo "# host=$(uname -s) user=$USER"

# --- claude ---
CLAUDE_ENC="$(slash_dash "$OLD")"
CLAUDE_DIR="$HOME/.claude/projects/$CLAUDE_ENC"
if [[ -d "$HOME/.claude/projects" ]]; then
  if [[ -d "$CLAUDE_DIR" ]]; then
    hit claude "$(path_kind "$OLD")" slash-dash "$CLAUDE_DIR" "${NEW:+$(slash_dash "$NEW")}" "$CLAUDE_DIR"
  else
    # partial: any dir that ends with basename encoding fragment
    base="$(basename "$OLD")"
    while IFS= read -r d; do
      [[ -z "$d" ]] && continue
      hit claude ghost slash-dash "$d" "${NEW:+$(slash_dash "$NEW")}" "$d"
    done < <(find "$HOME/.claude/projects" -maxdepth 1 -type d -name "*${base}*" 2>/dev/null | head -20)
  fi
  if [[ -f "$HOME/.claude.json" ]] && grep -F -q "$OLD" "$HOME/.claude.json" 2>/dev/null; then
    hit claude live raw "$OLD" "${NEW:-}" "$HOME/.claude.json"
  fi
else
  echo "store=claude kind=absent encoding= slash-dash from= to_suggest= evidence=$HOME/.claude/projects"
fi

# --- codex ---
if [[ -d "$HOME/.codex" ]]; then
  if [[ -f "$HOME/.codex/config.toml" ]] && grep -F -q "$OLD" "$HOME/.codex/config.toml" 2>/dev/null; then
    hit codex live raw "$OLD" "${NEW:-}" "$HOME/.codex/config.toml"
  fi
  DB="$HOME/.codex/state_5.sqlite"
  if [[ -f "$DB" ]] && command -v sqlite3 >/dev/null 2>&1; then
    # Best-effort: try common column names; ignore errors
    cnt="$(sqlite3 "$DB" "SELECT COUNT(*) FROM threads WHERE cwd = '$OLD';" 2>/dev/null || echo "")"
    if [[ -n "$cnt" && "$cnt" != "0" ]]; then
      hit codex live raw "$OLD" "${NEW:-}" "state_5.sqlite:threads.cwd count=$cnt"
    fi
  fi
  if grep -R -l -F --include='*.jsonl' --include='*.json' "$OLD" "$HOME/.codex/sessions" 2>/dev/null | head -1 | grep -q .; then
    hit codex live raw "$OLD" "${NEW:-}" "$HOME/.codex/sessions"
  fi
else
  echo "store=codex kind=absent encoding=raw from= to_suggest= evidence=$HOME/.codex"
fi

# --- grok ---
if [[ -d "$HOME/.grok" ]]; then
  GROK_ENC="$(url_enc "$OLD")"
  GROK_DIR="$HOME/.grok/sessions/$GROK_ENC"
  if [[ -d "$GROK_DIR" ]]; then
    hit grok "$(path_kind "$OLD")" url "$GROK_DIR" "${NEW:+$(url_enc "$NEW")}" "$GROK_DIR"
  fi
  if [[ -f "$HOME/.grok/trusted_folders.toml" ]] && grep -F -q "$OLD" "$HOME/.grok/trusted_folders.toml" 2>/dev/null; then
    hit grok live raw "$OLD" "${NEW:-}" "$HOME/.grok/trusted_folders.toml"
  fi
else
  echo "store=grok kind=absent encoding=url from= to_suggest= evidence=$HOME/.grok"
fi

# --- cbm cache (presence only) ---
if [[ -d "$HOME/.cache/codebase-memory-mcp" ]]; then
  enc="$(echo "$OLD" | tr '/' '-')"
  if find "$HOME/.cache/codebase-memory-mcp" -maxdepth 3 -iname "*$(basename "$OLD")*" 2>/dev/null | head -1 | grep -q .; then
    hit cbm live slash-dash "$enc" "${NEW:-}" "$HOME/.cache/codebase-memory-mcp"
  else
    echo "store=cbm kind=absent encoding=slash-dash from= to_suggest= evidence=$HOME/.cache/codebase-memory-mcp"
  fi
fi

# --- secrets (slug) ---
if [[ -d "$HOME/.claude-secrets" ]]; then
  base="$(basename "$OLD")"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    hit secrets live slug "$f" "" "$f"
  done < <(ls "$HOME/.claude-secrets" 2>/dev/null | grep -F "$base" || true)
fi

# --- vault default (read-only path mention count) ---
VAULT="${PORTAGE_VAULT:-$HOME/Documents/obsidian-brain}"
if [[ -d "$VAULT" ]]; then
  # cheap: filename match only in discover script; body search is agent-side
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    hit vault live raw "$OLD" "${NEW:-}" "$f"
  done < <(find "$VAULT" -type f -name '*.md' -path "*$(basename "$OLD")*" 2>/dev/null | head -30)
fi

echo "# done"
