#!/usr/bin/env bash
# portage-apply.sh: rehome Claude / Codex / Grok bindings from OLD to NEW.
# Default is dry-run. Pass --apply to write (backs up first).
# Usage: portage-apply.sh [--apply] <old_path> <new_path>
# Optional: PORTAGE_STORES=claude,codex,grok

set -euo pipefail

APPLY=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --apply) APPLY=1 ;;
    -h|--help)
      cat <<'EOF'
usage: portage-apply.sh [--apply] <old_path> <new_path>

  default: print planned operations only
  --apply: backup then mutate

  PORTAGE_STORES=claude,codex,grok   (default: all three)
EOF
      exit 0
      ;;
    *) ARGS+=("$a") ;;
  esac
done

if [[ ${#ARGS[@]} -lt 2 ]]; then
  echo "usage: $0 [--apply] <old_path> <new_path>" >&2
  exit 2
fi

OLD="${ARGS[0]}"
NEW="${ARGS[1]}"
STORES="${PORTAGE_STORES:-claude,codex,grok}"

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
if not re.fullmatch(r"/[A-Za-z0-9._/\- ]*", abs_path):
    print(f"invalid path characters: {abs_path!r}", file=sys.stderr)
    sys.exit(2)
print(abs_path)
PY
}

OLD="$(validate_path "$OLD")"
NEW="$(validate_path "$NEW")"

if [[ "$OLD" == "$NEW" ]]; then
  echo "old and new paths are identical" >&2
  exit 2
fi

slash_dash() {
  python3 -c 'import sys; p=sys.argv[1]; print(p.replace("/", "-").replace(".", "-"))' "$1"
}

url_enc() {
  python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

ts() { date -u +%Y%m%dT%H%M%SZ; }

backup_file() {
  local f="$1"
  [[ -e "$f" ]] || return 0
  local b="${f}.bak"
  if [[ -e "$b" ]]; then
    b="${f}.bak.$(ts)"
  fi
  cp -a "$f" "$b"
  echo "backup $f -> $b"
}

log() { printf '%s\n' "$*"; }
plan() { log "PLAN: $*"; }
ok() { log "OK: $*"; }
skip() { log "SKIP: $*"; }
fail() { log "FAIL: $*" >&2; }

want_store() {
  case ",$STORES," in
    *",$1,"*) return 0 ;;
    *) return 1 ;;
  esac
}

mode_label="dry-run"
[[ "$APPLY" -eq 1 ]] && mode_label="apply"
log "# portage-apply mode=$mode_label"
log "# old=$OLD"
log "# new=$NEW"
log "# stores=$STORES"

# ---------- claude ----------
apply_claude() {
  want_store claude || return 0
  local old_enc new_enc
  old_enc="$(slash_dash "$OLD")"
  new_enc="$(slash_dash "$NEW")"
  local base="$HOME/.claude"
  local proj_old="$base/projects/$old_enc"
  local proj_new="$base/projects/$new_enc"

  if [[ ! -d "$base/projects" ]]; then
    skip "claude: no $base/projects"
    return 0
  fi

  if [[ -d "$proj_old" ]]; then
    if [[ -e "$proj_new" ]]; then
      fail "claude: destination exists: $proj_new (refuse merge)"
      return 1
    fi
    plan "claude: mv $proj_old -> $proj_new"
    if [[ "$APPLY" -eq 1 ]]; then
      mv "$proj_old" "$proj_new"
      ok "claude: renamed projects dir"
    fi
  else
    skip "claude: no projects dir for old encoding"
  fi

  local side
  for side in todos file-history shell-snapshots; do
    local s_old="$base/$side/$old_enc"
    local s_new="$base/$side/$new_enc"
    if [[ -d "$s_old" ]]; then
      if [[ -e "$s_new" ]]; then
        fail "claude: destination exists: $s_new"
        return 1
      fi
      plan "claude: mv $s_old -> $s_new"
      if [[ "$APPLY" -eq 1 ]]; then
        mv "$s_old" "$s_new"
        ok "claude: renamed $side"
      fi
    fi
  done

  local cj="$HOME/.claude.json"
  if [[ -f "$cj" ]] && grep -F -q "$OLD" "$cj" 2>/dev/null; then
    plan "claude: rewrite path keys in $cj"
    if [[ "$APPLY" -eq 1 ]]; then
      backup_file "$cj"
      python3 - "$OLD" "$NEW" "$cj" <<'PY'
import json, sys
old, new, path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

def rekey_dict(d):
    if not isinstance(d, dict):
        return d
    out = {}
    for k, v in d.items():
        nk = new if k == old else k
        out[nk] = rekey_dict(v) if isinstance(v, dict) else (
            [rekey_dict(x) for x in v] if isinstance(v, list) else (
                new if v == old else v
            )
        )
    return out

def walk(obj):
    if isinstance(obj, dict):
        return rekey_dict({k: walk(v) for k, v in obj.items()})
    if isinstance(obj, list):
        return [walk(x) for x in obj]
    if obj == old:
        return new
    if isinstance(obj, str) and old in obj:
        return obj.replace(old, new)
    return obj

# Prefer rekey on projects / githubRepoPaths, then string replace walk
if isinstance(data.get("projects"), dict) and old in data["projects"]:
    data["projects"][new] = data["projects"].pop(old)
if isinstance(data.get("githubRepoPaths"), dict):
    grp = data["githubRepoPaths"]
    # values or keys may hold paths
    data["githubRepoPaths"] = walk(grp)
data = walk(data)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
      ok "claude: updated .claude.json"
    fi
  else
    skip "claude: no .claude.json hit for old path"
  fi
}

# ---------- codex ----------
apply_codex() {
  want_store codex || return 0
  local root="$HOME/.codex"
  if [[ ! -d "$root" ]]; then
    skip "codex: no $root"
    return 0
  fi

  local db="$root/state_5.sqlite"
  if [[ -f "$db" ]] && command -v sqlite3 >/dev/null 2>&1; then
    local cnt
    cnt="$(sqlite3 "$db" "SELECT COUNT(*) FROM threads WHERE cwd = '$(printf '%s' "$OLD" | sed "s/'/''/g")';" 2>/dev/null || echo "")"
    if [[ -n "$cnt" && "$cnt" != "0" ]]; then
      plan "codex: UPDATE threads.cwd ($cnt rows) $OLD -> $NEW"
      if [[ "$APPLY" -eq 1 ]]; then
        backup_file "$db"
        [[ -f "${db}-wal" ]] && backup_file "${db}-wal"
        [[ -f "${db}-shm" ]] && backup_file "${db}-shm"
        sqlite3 "$db" "UPDATE threads SET cwd = '$(printf '%s' "$NEW" | sed "s/'/''/g")' WHERE cwd = '$(printf '%s' "$OLD" | sed "s/'/''/g")';"
        ok "codex: sqlite cwd updated"
      fi
    else
      skip "codex: no threads.cwd rows for old path (or schema mismatch)"
    fi
  else
    skip "codex: no state_5.sqlite or sqlite3 missing"
  fi

  local cfg="$root/config.toml"
  if [[ -f "$cfg" ]] && grep -F -q "$OLD" "$cfg" 2>/dev/null; then
    plan "codex: rewrite path strings in config.toml"
    if [[ "$APPLY" -eq 1 ]]; then
      backup_file "$cfg"
      python3 - "$OLD" "$NEW" "$cfg" <<'PY'
import sys
old, new, path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as f:
    text = f.read()
if old not in text:
    raise SystemExit(0)
with open(path, "w", encoding="utf-8") as f:
    f.write(text.replace(old, new))
PY
      ok "codex: config.toml updated"
    fi
  else
    skip "codex: no config.toml hit"
  fi

  local gstate="$root/.codex-global-state.json"
  if [[ -f "$gstate" ]] && grep -F -q "$OLD" "$gstate" 2>/dev/null; then
    plan "codex: rewrite $gstate"
    if [[ "$APPLY" -eq 1 ]]; then
      backup_file "$gstate"
      python3 - "$OLD" "$NEW" "$gstate" <<'PY'
import sys
old, new, path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as f:
    text = f.read()
with open(path, "w", encoding="utf-8") as f:
    f.write(text.replace(old, new))
PY
      ok "codex: global state updated"
    fi
  fi

  if [[ -d "$root/sessions" ]]; then
    local matches
    matches="$(grep -R -l -F --include='*.jsonl' --include='*.json' "$OLD" "$root/sessions" 2>/dev/null | head -200 || true)"
    if [[ -n "$matches" ]]; then
      local n
      n="$(printf '%s\n' "$matches" | grep -c . || true)"
      plan "codex: rewrite path in $n session file(s)"
      if [[ "$APPLY" -eq 1 ]]; then
        while IFS= read -r f; do
          [[ -z "$f" ]] && continue
          backup_file "$f"
          python3 - "$OLD" "$NEW" "$f" <<'PY'
import sys
old, new, path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8", errors="replace") as fh:
    text = fh.read()
with open(path, "w", encoding="utf-8") as fh:
    fh.write(text.replace(old, new))
PY
        done <<< "$matches"
        ok "codex: session files patched"
      fi
    else
      skip "codex: no session file hits"
    fi
  fi
}

# ---------- grok ----------
apply_grok() {
  want_store grok || return 0
  local root="$HOME/.grok"
  if [[ ! -d "$root" ]]; then
    skip "grok: no $root"
    return 0
  fi

  local old_enc new_enc
  old_enc="$(url_enc "$OLD")"
  new_enc="$(url_enc "$NEW")"
  local sess_old="$root/sessions/$old_enc"
  local sess_new="$root/sessions/$new_enc"

  if [[ -d "$sess_old" ]]; then
    if [[ -e "$sess_new" ]]; then
      fail "grok: destination exists: $sess_new (refuse merge)"
      return 1
    fi
    plan "grok: mv $sess_old -> $sess_new"
    if [[ "$APPLY" -eq 1 ]]; then
      mv "$sess_old" "$sess_new"
      ok "grok: renamed sessions dir"
    fi
  else
    skip "grok: no sessions dir for old encoding"
  fi

  local trust="$root/trusted_folders.toml"
  if [[ -f "$trust" ]] && grep -F -q "$OLD" "$trust" 2>/dev/null; then
    plan "grok: rewrite keys in trusted_folders.toml"
    if [[ "$APPLY" -eq 1 ]]; then
      backup_file "$trust"
      python3 - "$OLD" "$NEW" "$trust" <<'PY'
import sys
old, new, path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as f:
    text = f.read()
with open(path, "w", encoding="utf-8") as f:
    f.write(text.replace(old, new))
PY
      ok "grok: trusted_folders.toml updated"
    fi
  else
    skip "grok: no trusted_folders hit"
  fi

  local active="$root/active_sessions.json"
  if [[ -f "$active" ]] && grep -F -q "$OLD" "$active" 2>/dev/null; then
    plan "grok: rewrite active_sessions.json"
    if [[ "$APPLY" -eq 1 ]]; then
      backup_file "$active"
      python3 - "$OLD" "$NEW" "$active" <<'PY'
import sys
old, new, path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as f:
    text = f.read()
with open(path, "w", encoding="utf-8") as f:
    f.write(text.replace(old, new))
PY
      ok "grok: active_sessions.json updated"
    fi
  fi
}

rc=0
apply_claude || rc=1
apply_codex || rc=1
apply_grok || rc=1

if [[ "$APPLY" -eq 0 ]]; then
  log "# dry-run complete (re-run with --apply to write)"
else
  log "# apply complete"
fi
exit "$rc"
