#!/usr/bin/env bash
# publish.sh — wikia · publica artefato em /docs/gitpages/ no repo wikia
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TITLE=""; CONTENT=""; MODE="simple"; PASSWORD=""; NO_GATE="false"
SLUG=""; TEMA=""; REPO="felipeggv/wikia"
TAGS=""; ENRICH="false"; NO_REBUILD="false"; DRY_RUN="false"; VALIDATE_ONLY="false"
REBUILD_ALL="false"; APPLY_PENDING="false"; MASTERPASS=""
MASTERPASS_STDIN="false"; MASTERPASS_FILE=""
BU=""; PROJECT=""; PRIVATE_SOURCE_ROOT="${WIKIA_PRIVATE_SOURCE_ROOT:-}"

declare -a STAGE_PATHS=()

has_xtrace() {
  case "$-" in
    *x*) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_masterpass() {
  if [ -n "$MASTERPASS" ]; then
    return 0
  fi

  if [ "$MASTERPASS_STDIN" = "true" ]; then
    IFS= read -r MASTERPASS || true
  elif [ -n "$MASTERPASS_FILE" ]; then
    [ -f "$MASTERPASS_FILE" ] || { echo "ERR: masterpass file not found" >&2; exit 1; }
    MASTERPASS="$(tr -d '\r\n' < "$MASTERPASS_FILE")"
  elif [ -n "${WIKIA_MASTERPASS:-}" ]; then
    MASTERPASS="$WIKIA_MASTERPASS"
  fi

  [ -z "$MASTERPASS" ] && {
    echo "ERR: --rebuild-all requires masterpass via stdin, file, or environment" >&2
    exit 1
  }
  return 0
}

with_masterpass_env() {
  local had_xtrace="false"
  if has_xtrace; then
    had_xtrace="true"
    set +x
  fi

  WIKIA_MASTERPASS="$MASTERPASS" "$@"
  local status=$?

  if [ "$had_xtrace" = "true" ]; then
    set -x
  fi
  return "$status"
}

derive_vault_password_from_seed() {
  local seed_slug="$1"
  local had_xtrace="false"
  local result
  if has_xtrace; then
    had_xtrace="true"
    set +x
  fi

  result=$(printf '%s' "$MASTERPASS" | SEED_SLUG="$seed_slug" node - <<'NODE'
const crypto = require('node:crypto');
const fs = require('node:fs');
const slug = process.env.SEED_SLUG || '';
const masterpass = fs.readFileSync(0, 'utf8');
process.stdout.write(
  crypto.createHash('sha256').update(`seed:${slug}:${masterpass}`).digest('base64url').slice(0, 16)
);
NODE
)
  local status=$?

  if [ "$had_xtrace" = "true" ]; then
    set -x
  fi
  printf '%s' "$result"
  return "$status"
}

is_publish_stage_path() {
  local path="$1"
  local -a parts

  case "$path" in
    /*|../*|*/../*|*/..) return 1 ;;
    docs/.nojekyll|\
docs/gitpages/.nojekyll|\
docs/gitpages/index.html|\
docs/gitpages/search.json|\
docs/gitpages/_catalog.json|\
docs/gitpages/_admin.enc|\
docs/gitpages/_released.json|\
docs/gitpages/_pending-changes.json|\
docs/gitpages/_passwords.enc|\
docs/gitpages/admin/index.html)
      return 0
      ;;
  esac

  IFS='/' read -r -a parts <<< "$path"

  # Wave 2 layout: docs/gitpages/<bu>/index.html
  if [ "${#parts[@]}" -eq 4 ] &&
     [ "${parts[0]}" = "docs" ] &&
     [ "${parts[1]}" = "gitpages" ] &&
     [ "${parts[3]}" = "index.html" ]; then
    return 0
  fi

  # Wave 2 layout: docs/gitpages/<bu>/<project>/index.html
  if [ "${#parts[@]}" -eq 5 ] &&
     [ "${parts[0]}" = "docs" ] &&
     [ "${parts[1]}" = "gitpages" ] &&
     [ "${parts[4]}" = "index.html" ]; then
    return 0
  fi

  # Wave 2 layout: docs/gitpages/<bu>/<project>/<slug>/index.html
  if [ "${#parts[@]}" -eq 6 ] &&
     [ "${parts[0]}" = "docs" ] &&
     [ "${parts[1]}" = "gitpages" ] &&
     [ "${parts[5]}" = "index.html" ]; then
    return 0
  fi

  # Legacy layout kept for existing Wave 1 articles.
  if [ "${#parts[@]}" -eq 5 ] &&
     [ "${parts[0]}" = "docs" ] &&
     [ "${parts[1]}" = "gitpages" ] &&
     [ "${parts[2]}" = "research" ] &&
     [ "${parts[4]}" = "index.html" ]; then
    return 0
  fi

  if [ "${#parts[@]}" -eq 7 ] &&
     [ "${parts[0]}" = "docs" ] &&
     [ "${parts[1]}" = "gitpages" ] &&
     [ "${parts[2]}" = "research" ] &&
     [ "${parts[4]}" = "artifacts" ] &&
     [ "${parts[6]}" = "index.html" ]; then
    return 0
  fi

  return 1
}

is_publish_raw_markdown_path() {
  local path="$1"
  local -a parts

  case "$path" in
    /*|../*|*/../*|*/..) return 1 ;;
  esac

  IFS='/' read -r -a parts <<< "$path"

  # Wave 2 layout: docs/gitpages/<bu>/<project>/<slug>/raw.md
  if [ "${#parts[@]}" -eq 6 ] &&
     [ "${parts[0]}" = "docs" ] &&
     [ "${parts[1]}" = "gitpages" ] &&
     [ "${parts[5]}" = "raw.md" ]; then
    return 0
  fi

  # Legacy layout: docs/gitpages/research/<tema>/artifacts/<slug>/raw.md
  if [ "${#parts[@]}" -eq 7 ] &&
     [ "${parts[0]}" = "docs" ] &&
     [ "${parts[1]}" = "gitpages" ] &&
     [ "${parts[2]}" = "research" ] &&
     [ "${parts[4]}" = "artifacts" ] &&
     [ "${parts[6]}" = "raw.md" ]; then
    return 0
  fi

  return 1
}

collect_publish_stage_paths() {
  local entry status path
  STAGE_PATHS=()

  while IFS= read -r -d '' entry; do
    status="${entry:0:2}"
    path="${entry:3}"

    case "$status" in
      R*|C*)
        echo "ERR: refusing to stage renamed/copied publish path: $path" >&2
        exit 1
        ;;
    esac

    if ! is_publish_stage_path "$path"; then
      if is_publish_raw_markdown_path "$path" && [[ "$status" == *D* ]]; then
        STAGE_PATHS+=("$path")
        continue
      fi
      echo "ERR: refusing to stage unexpected publish path: $path" >&2
      exit 1
    fi
    STAGE_PATHS+=("$path")
  done < <(git status --porcelain=v1 -z -uall -- docs/.nojekyll docs/gitpages)
}

stage_publish_paths() {
  collect_publish_stage_paths
  if [ "${#STAGE_PATHS[@]}" -gt 0 ]; then
    git add -- "${STAGE_PATHS[@]}"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --content) CONTENT="$2"; shift 2 ;;
    --full) MODE="full"; shift ;;
    --simple) MODE="simple"; shift ;;
    --password) PASSWORD="$2"; shift 2 ;;
    --no-gate) NO_GATE="true"; shift ;;
    --slug) SLUG="$2"; shift 2 ;;
    --tema) TEMA="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --tags) TAGS="$2"; shift 2 ;;
    --enrich) ENRICH="true"; shift ;;
    --no-rebuild) NO_REBUILD="true"; shift ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --validate|--validate-only|--no-push) VALIDATE_ONLY="true"; shift ;;
    --rebuild-all) REBUILD_ALL="true"; shift ;;
    --apply-pending) APPLY_PENDING="true"; shift ;;
    --masterpass)
      [ $# -ge 2 ] || { echo "ERR: --masterpass requires '-'" >&2; exit 2; }
      [ "$2" = "-" ] || {
        echo "ERR: plaintext --masterpass values are unsafe; use stdin, file, or environment" >&2
        exit 2
      }
      MASTERPASS_STDIN="true"; shift 2
      ;;
    --masterpass-file) MASTERPASS_FILE="$2"; shift 2 ;;
    --bu) BU="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --private-source-root) PRIVATE_SOURCE_ROOT="$2"; shift 2 ;;
    *) echo "ERR: unknown flag $1" >&2; exit 1 ;;
  esac
done

if [ "$APPLY_PENDING" = "true" ]; then
  REBUILD_ALL="true"
fi

if [ "$REBUILD_ALL" = "true" ]; then
  resolve_masterpass
  # In rebuild mode, --title and --content are ignored; clear them.
  TITLE="(rebuild-all)"; CONTENT=""
fi

[ -z "$TITLE" ] && { echo "ERR: --title required" >&2; exit 1; }
if [ "$REBUILD_ALL" != "true" ]; then
  if [ -z "$CONTENT" ] || [ ! -f "$CONTENT" ]; then
    echo "ERR: --content must exist" >&2
    exit 1
  fi
fi

[ -z "$TEMA" ] && TEMA="$(date +%Y-%m)-artifacts"
[ -z "$SLUG" ] && SLUG=$(bash "$SCRIPT_DIR/slugify.sh" "$TITLE")
DATE=$(date +%Y-%m-%d)
REPO_OWNER="${REPO%/*}"
REPO_NAME="${REPO#*/}"
# Pages serve /docs subpath, conteudo em docs/gitpages → URL com /gitpages
WIKI_BASE="https://${REPO_OWNER}.github.io/${REPO_NAME}/gitpages"
URL="$WIKI_BASE/research/$TEMA/artifacts/$SLUG/"

echo "→ Fetching Maestro theme..." >&2
THEME_JSON=$(bash "$SCRIPT_DIR/theme-fetch.sh")

WORKDIR=$(mktemp -d -t wikia-XXXXXX)
trap "rm -rf '$WORKDIR'" EXIT

if [ "$DRY_RUN" = "true" ]; then
  mkdir -p "$WORKDIR/docs/gitpages/research/$TEMA/artifacts"
else
  echo "→ Cloning $REPO..." >&2
  git clone --depth 1 "https://github.com/$REPO.git" "$WORKDIR" >&2 2>&1 || {
    echo "ERR: clone failed" >&2; exit 1;
  }
fi

# Garante estrutura /docs/gitpages/
GITPAGES="$WORKDIR/docs/gitpages"
mkdir -p "$GITPAGES"
touch "$WORKDIR/docs/.nojekyll" "$GITPAGES/.nojekyll"

# Wave 2: resolve BU/project/slug for single-article publishes.
if [ "$REBUILD_ALL" != "true" ]; then
  if [ -z "$BU" ] || [ -z "$PROJECT" ] || [ -z "$SLUG" ]; then
    if [ -n "$CONTENT" ] && [ -f "$CONTENT" ]; then
      RESOLVER_JSON=$(python3 "$SCRIPT_DIR/bu_resolver.py" "$CONTENT" --no-interactive 2>/dev/null || echo '{}')
      [ -z "$BU" ] && BU=$(echo "$RESOLVER_JSON" | python3 -c "import json,sys; print(json.loads(sys.stdin.read() or '{}').get('bu',''))" 2>/dev/null || echo "")
      [ -z "$PROJECT" ] && PROJECT=$(echo "$RESOLVER_JSON" | python3 -c "import json,sys; print(json.loads(sys.stdin.read() or '{}').get('project',''))" 2>/dev/null || echo "")
      [ -z "$SLUG" ] && SLUG=$(echo "$RESOLVER_JSON" | python3 -c "import json,sys; print(json.loads(sys.stdin.read() or '{}').get('slug',''))" 2>/dev/null || echo "")
    fi
    [ -z "$BU" ] && { echo "ERR: BU unresolved — add frontmatter or pass --bu" >&2; exit 1; }
    [ -z "$PROJECT" ] && PROJECT="geral"
    [ -z "$SLUG" ] && { echo "ERR: slug unresolved" >&2; exit 1; }
  fi
  URL="$WIKI_BASE/$BU/$PROJECT/$SLUG/"
  ARTIFACT_DIR="$GITPAGES/$BU/$PROJECT/$SLUG"
else
  URL="$WIKI_BASE/"
  ARTIFACT_DIR="$GITPAGES"
fi

SOURCE_RAW="$CONTENT"
if [ "$REBUILD_ALL" != "true" ]; then
  mkdir -p "$ARTIFACT_DIR"
  if [ -n "$PRIVATE_SOURCE_ROOT" ]; then
    PRIVATE_ARTIFACT_DIR="$PRIVATE_SOURCE_ROOT/$BU/$PROJECT/$SLUG"
    mkdir -p "$PRIVATE_ARTIFACT_DIR"
    PRIVATE_RAW="$PRIVATE_ARTIFACT_DIR/raw.md"
    if [ "$CONTENT" != "$PRIVATE_RAW" ]; then
      cp "$CONTENT" "$PRIVATE_RAW"
    fi
    SOURCE_RAW="$PRIVATE_RAW"
    rm -f "$ARTIFACT_DIR/raw.md"
  fi

  if [ "$NO_GATE" = "true" ]; then
    CATALOG_GATE_STATUS="public"
    CATALOG_RELEASE_STATUS="released"
    CATALOG_SCOPE="public"
  else
    CATALOG_GATE_STATUS="gated"
    CATALOG_RELEASE_STATUS="unreleased"
    CATALOG_SCOPE="article"
  fi

  python3 "$SCRIPT_DIR/public_catalog.py" upsert-from-raw "$GITPAGES/_catalog.json" "$SOURCE_RAW" \
    --output-url "$BU/$PROJECT/$SLUG/" \
    --gate-status "$CATALOG_GATE_STATUS" \
    --release-status "$CATALOG_RELEASE_STATUS" \
    --scope "$CATALOG_SCOPE" \
    --json >/dev/null

  # Coleta tree completo (de TODOS artefatos no /docs/gitpages, incluindo o novo)
  # Primeiro: cria índice temporário com o novo artefato já incluído (placeholder vazio)
  mkdir -p "$ARTIFACT_DIR"
  [ ! -f "$ARTIFACT_DIR/index.html" ] && echo "<title>$TITLE</title>" > "$ARTIFACT_DIR/index.html"
fi

TREE_JSON=$(python3 - "$GITPAGES" <<'PYEOF'
import sys, re, json
from pathlib import Path
from collections import defaultdict
gp = Path(sys.argv[1])
by_tema = defaultdict(list)
research = gp / 'research'
if research.exists():
    for tema_dir in research.iterdir():
        if not tema_dir.is_dir(): continue
        arts_dir = tema_dir / 'artifacts'
        if not arts_dir.exists(): continue
        for art in arts_dir.iterdir():
            if not art.is_dir(): continue
            html = art / 'index.html'
            title = art.name
            if html.exists():
                m = re.search(r'<title>([^<]+)</title>', html.read_text(errors='ignore'))
                if m: title = m.group(1).split(' · ')[0].strip()
            by_tema[tema_dir.name].append({'slug': art.name, 'title': title, 'mtime': html.stat().st_mtime if html.exists() else 0})
tree = []
for tema in sorted(by_tema.keys(), reverse=True):
    arts = sorted(by_tema[tema], key=lambda x: x['mtime'], reverse=True)
    tree.append({'tema': tema, 'title': tema.replace('-', ' ').title(), 'artifacts': [{'slug': a['slug'], 'title': a['title']} for a in arts]})
print(json.dumps(tree, ensure_ascii=False))
PYEOF
)

RECENTS_JSON=$(python3 - "$GITPAGES" <<'PYEOF'
import sys, re, json
from pathlib import Path
from datetime import datetime
gp = Path(sys.argv[1])
items = []
research = gp / 'research'
if research.exists():
    for tema_dir in research.iterdir():
        if not tema_dir.is_dir(): continue
        arts_dir = tema_dir / 'artifacts'
        if not arts_dir.exists(): continue
        for art in arts_dir.iterdir():
            if not art.is_dir(): continue
            html = art / 'index.html'
            if not html.exists(): continue
            title = art.name
            m = re.search(r'<title>([^<]+)</title>', html.read_text(errors='ignore'))
            if m: title = m.group(1).split(' · ')[0].strip()
            mtime = html.stat().st_mtime
            items.append({'slug': art.name, 'title': title, 'tema': tema_dir.name, 'date_human': datetime.fromtimestamp(mtime).strftime('%d %b').upper(), 'url': f'research/{tema_dir.name}/artifacts/{art.name}/', 'mtime': mtime})
items.sort(key=lambda x: x['mtime'], reverse=True)
print(json.dumps(items, ensure_ascii=False))
PYEOF
)

if [ "$REBUILD_ALL" != "true" ]; then
echo "→ Rendering artifact ($MODE)..." >&2
PUBLIC_HEAD_TITLE=""
PUBLIC_HEAD_DESCRIPTION=""
if [ "$NO_GATE" != "true" ]; then
  PUBLIC_HEAD_TITLE="Protected article"
  PUBLIC_HEAD_DESCRIPTION="Encrypted wikia article. Unlock is required to read the content."
fi
WIKIA_PUBLIC_ROOT="$GITPAGES" \
WIKIA_PUBLIC_TITLE="$PUBLIC_HEAD_TITLE" \
WIKIA_PUBLIC_DESCRIPTION="$PUBLIC_HEAD_DESCRIPTION" \
python3 "$SCRIPT_DIR/render-artifact.py" \
  "$SOURCE_RAW" \
  "$THEME_JSON" \
  "$TITLE" "$SLUG" "$TEMA" "$REPO_NAME" "$DATE" "$TAGS" \
  "$( [ "$ENRICH" = "true" ] && echo "claude,codex,gemini" || echo "claude" )" \
  "$TREE_JSON" "$RECENTS_JSON" "$WIKI_BASE" > "$ARTIFACT_DIR/index.html"

# Gate ou strip
if [ "$NO_GATE" != "true" ]; then
  if [ -z "$PASSWORD" ]; then
    PASSWORD=$(openssl rand -base64 12 | tr -d /=+ | head -c 16)
  fi
  echo "→ Applying AES-GCM gate..." >&2
  bash "$SCRIPT_DIR/gate.sh" "$ARTIFACT_DIR/index.html" "$PASSWORD" "$BU"
else
  # Balance-scan extraction (PG-03 fix): regex non-greedy quebra com <template>
  # aninhado (playground inert). Anda <template>/</template> contando depth.
  python3 - "$ARTIFACT_DIR/index.html" <<'PYEOF'
import sys, re
path = sys.argv[1]
with open(path) as f: html = f.read()

OPEN_MARKER = '<template id="ap-content-tpl">'
start = html.find(OPEN_MARKER)
if start == -1:
    content = ''
    new_html = html
else:
    content_start = start + len(OPEN_MARKER)
    open_re = re.compile(r'<template(?:\s[^>]*)?>', re.IGNORECASE)
    close_re = re.compile(r'</template\s*>', re.IGNORECASE)
    depth = 1
    pos = content_start
    close_start = close_end = -1
    while depth > 0:
        o = open_re.search(html, pos)
        c = close_re.search(html, pos)
        if not c:
            raise SystemExit('ERR: unbalanced <template> in HTML')
        if o and o.start() < c.start():
            depth += 1
            pos = o.end()
        else:
            depth -= 1
            if depth == 0:
                close_start = c.start()
                close_end = c.end()
            pos = c.end()
    content = html[content_start:close_start]
    new_html = html[:start] + html[close_end:]

new_html = new_html.replace('{{GATE_BLOCK}}', content)
with open(path, 'w') as f: f.write(new_html)
PYEOF
fi
fi  # end REBUILD_ALL != true (single-article render path)

# Rebuild wiki home + search + BU home + project home
if [ "$NO_REBUILD" != "true" ] && [ "$REBUILD_ALL" != "true" ]; then
  echo "→ Rebuilding wiki home + search..." >&2
  python3 "$SCRIPT_DIR/render-wiki.py" "$GITPAGES" "$THEME_JSON" "$REPO_NAME" "$WIKI_BASE"
  python3 "$SCRIPT_DIR/build-search-index.py" "$GITPAGES"
  # Wave 2: also refresh the BU-home and project-home of the BU we just published into.
  # Without these calls, single-article publishes leave BU/project indexes stale
  # (they keep showing "Nenhum artigo publicado ainda" even after a successful publish).
  if [ -n "${BU:-}" ]; then
    echo "→ Rebuilding BU home ($BU) + project home ($PROJECT)..." >&2
    python3 "$SCRIPT_DIR/render-bu.py" "$GITPAGES" "$THEME_JSON" "$BU" "$WIKI_BASE" >&2
    if [ -n "${PROJECT:-}" ]; then
      python3 "$SCRIPT_DIR/render-project.py" "$GITPAGES" "$THEME_JSON" "$BU" "$PROJECT" "$WIKI_BASE" >&2 || true
    fi
  fi
fi

# Rebuild-all loop: iterate every article, re-render with current chassi, re-apply gate
if [ "$REBUILD_ALL" = "true" ]; then
  VAULT_PATH="$GITPAGES/_passwords.enc"
  RELEASED_PATH="$GITPAGES/_released.json"
  PENDING_PATH="$GITPAGES/_pending-changes.json"
  CMS_STATE_DIR="$WORKDIR/.wikia-cms-state"
  CMS_DB_PATH="$CMS_STATE_DIR/admin-state.sqlite3"
  ADMIN_METADATA_JSON="$CMS_STATE_DIR/admin-metadata.json"
  mkdir -p "$CMS_STATE_DIR"
  [ -f "$RELEASED_PATH" ] || printf '[]\n' > "$RELEASED_PATH"
  [ -f "$PENDING_PATH" ] || printf '{}\n' > "$PENDING_PATH"

  # Apply pending changes (release/rotate/remove) before rebuild
  if [ "$APPLY_PENDING" = "true" ] && [ -f "$PENDING_PATH" ]; then
    echo "→ Applying pending admin changes..." >&2
    with_masterpass_env python3 "$SCRIPT_DIR/apply-pending.py" \
      "$PENDING_PATH" "$VAULT_PATH" "$RELEASED_PATH" \
      --catalog-path "$GITPAGES/_catalog.json" >&2
  fi

  REBUILT_COUNT=0
  REMOVED_COUNT=0
  SKIPPED_COUNT=0
  REBUILD_RAW_ROOT="$GITPAGES"
  [ -n "$PRIVATE_SOURCE_ROOT" ] && REBUILD_RAW_ROOT="$PRIVATE_SOURCE_ROOT"
  VAULT_MJS="$SCRIPT_DIR/vault.mjs"
  # vault.mjs get — reads password+tema for slug
  # vault.mjs set — writes password+tema for slug

  echo "→ Syncing CMS state..." >&2
  python3 "$SCRIPT_DIR/sync-cms-state.py" "$GITPAGES" "$REBUILD_RAW_ROOT" \
    --released "$RELEASED_PATH" \
    --cms-db "$CMS_DB_PATH" \
    --admin-metadata-out "$ADMIN_METADATA_JSON" \
    --json > "$CMS_STATE_DIR/sync-summary.json"

  with_masterpass_env node "$VAULT_MJS" pack-json "$GITPAGES/_admin.enc" \
    < "$ADMIN_METADATA_JSON" >/dev/null

  PUBLIC_RAW_REMOVED_COUNT=0
  if [ -n "$PRIVATE_SOURCE_ROOT" ]; then
    PUBLIC_RAW_REMOVED_COUNT=$(python3 - "$GITPAGES" "$PRIVATE_SOURCE_ROOT" <<'PYEOF'
from pathlib import Path
import sys

public_root = Path(sys.argv[1]).resolve()
private_root = Path(sys.argv[2]).resolve()
removed = 0

for public_raw in sorted(public_root.rglob("raw.md")):
    try:
        rel = public_raw.resolve().relative_to(public_root)
    except ValueError:
        continue
    if (private_root / rel).is_file():
        public_raw.unlink()
        removed += 1

print(removed)
PYEOF
)
    echo "→ Removed $PUBLIC_RAW_REMOVED_COUNT public raw.md files mirrored in private source root" >&2
  fi

  echo "→ Rebuilding all articles..." >&2
  # Iterate every raw.md
  while IFS= read -r RAW_MD; do
    # Wave 2: resolve BU/project/slug per article (replaces legacy path-based extraction)
    RESOLVED=$(python3 "$SCRIPT_DIR/bu_resolver.py" "$RAW_MD" --no-interactive 2>/dev/null || echo '{}')
    BU=$(echo "$RESOLVED" | python3 -c "import json,sys; print(json.loads(sys.stdin.read() or '{}').get('bu',''))")
    PROJECT=$(echo "$RESOLVED" | python3 -c "import json,sys; print(json.loads(sys.stdin.read() or '{}').get('project',''))")
    SLUG=$(echo "$RESOLVED" | python3 -c "import json,sys; print(json.loads(sys.stdin.read() or '{}').get('slug',''))")
    if [ -z "$BU" ] || [ -z "$PROJECT" ] || [ -z "$SLUG" ]; then
      echo "  · skip-unresolved: $RAW_MD" >&2
      SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
      continue
    fi
    ART_DIR="$GITPAGES/$BU/$PROJECT/$SLUG"
    mkdir -p "$ART_DIR"
    # TEMA retained for backward-compat fields (vault metadata, render-artifact arg): use project as proxy
    TEMA="$PROJECT"

    STATE_JSON=$(python3 - "$GITPAGES/_catalog.json" "$BU" "$PROJECT" "$SLUG" <<'PYEOF'
import json
import sys
from pathlib import Path

catalog_path, bu, project, slug = sys.argv[1:5]
payload = json.loads(Path(catalog_path).read_text(encoding="utf-8"))
key = f"{bu}/{project}/{slug}"
for record in payload.get("records", []):
    if record.get("canonical_key") == key or (
        record.get("bu") == bu and record.get("project") == project and record.get("slug") == slug
    ):
        print(json.dumps(record, ensure_ascii=False, sort_keys=True))
        break
else:
    raise SystemExit(f"missing catalog record: {key}")
PYEOF
)

    RELEASE_STATUS=$(printf '%s' "$STATE_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('release_status',''))")
    GATE_STATUS=$(printf '%s' "$STATE_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('gate_status',''))")
    SCOPE=$(printf '%s' "$STATE_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('scope','article'))")

    if [ "$RELEASE_STATUS" = "removed" ]; then
      rm -f "$ART_DIR/index.html" "$ART_DIR/index.html.new"
      echo "  · removed: $BU/$PROJECT/$SLUG" >&2
      REMOVED_COUNT=$((REMOVED_COUNT + 1))
      continue
    fi

    ART_TITLE=$(python3 - "$SCRIPT_DIR" "$RAW_MD" "$SLUG" <<'PYEOF'
import sys

sys.path.insert(0, sys.argv[1])
from frontmatter_parser import parse_frontmatter_optional

fm = parse_frontmatter_optional(sys.argv[2]) or {}
print(fm.get("title") or sys.argv[3])
PYEOF
)

    if [ "$RELEASE_STATUS" = "released" ] || [ "$GATE_STATUS" = "public" ]; then
      CATALOG_SCOPE="public"
      PUBLIC_HEAD_TITLE=""
      PUBLIC_HEAD_DESCRIPTION=""
    else
      CATALOG_SCOPE="$SCOPE"
      PUBLIC_HEAD_TITLE="Protected article"
      PUBLIC_HEAD_DESCRIPTION="Encrypted wikia article. Unlock is required to read the content."
    fi

    # Re-render with current tree + chassi
    WIKIA_PUBLIC_ROOT="$GITPAGES" \
    WIKIA_PUBLIC_TITLE="$PUBLIC_HEAD_TITLE" \
    WIKIA_PUBLIC_DESCRIPTION="$PUBLIC_HEAD_DESCRIPTION" \
    python3 "$SCRIPT_DIR/render-artifact.py" \
      "$RAW_MD" "$THEME_JSON" \
      "$ART_TITLE" "$SLUG" "$TEMA" "$REPO_NAME" \
      "$(date -r "$ART_DIR/index.html" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)" \
      "" "claude" "$TREE_JSON" "$RECENTS_JSON" "$WIKI_BASE" \
      > "$ART_DIR/index.html.new"

    # Decide gate or release
    if [ "$RELEASE_STATUS" = "released" ] || [ "$GATE_STATUS" = "public" ]; then
      # Released: strip gate, inline content directly
      python3 "$SCRIPT_DIR/strip-gate.py" "$ART_DIR/index.html.new"
      echo "  · released: $SLUG" >&2
    else
      # Gated: look up password from vault
      ART_PASS=""
      while IFS= read -r VAULT_KEY; do
        [ -z "$VAULT_KEY" ] && continue
        ART_PASS=$(with_masterpass_env node "$VAULT_MJS" get "$VAULT_PATH" "$VAULT_KEY" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('password',''))" 2>/dev/null || true)
        [ -n "$ART_PASS" ] && break
      done < <(python3 - "$STATE_JSON" <<'PYEOF'
import json
import sys

record = json.loads(sys.argv[1])
tokens = [
    record.get("slug"),
    record.get("canonical_key"),
    record.get("output_url"),
    record.get("article_id"),
]
seen = set()
for token in tokens:
    token = str(token or "").strip().strip("/")
    if token and token not in seen:
        seen.add(token)
        print(token)
PYEOF
)
      if [ -z "$ART_PASS" ]; then
        # Slug missing from vault: generate + store
        ART_PASS=$(derive_vault_password_from_seed "$SLUG")
        with_masterpass_env node "$VAULT_MJS" set "$VAULT_PATH" "$SLUG" "$ART_PASS" --tema "$TEMA" >/dev/null
        echo "  · vault-add: $SLUG ($CATALOG_SCOPE scope)" >&2
      fi
      bash "$SCRIPT_DIR/gate.sh" "$ART_DIR/index.html.new" "$ART_PASS" "$BU"
    fi

    mv "$ART_DIR/index.html.new" "$ART_DIR/index.html"
    REBUILT_COUNT=$((REBUILT_COUNT + 1))
  done < <(find "$REBUILD_RAW_ROOT" -name "raw.md" -not -path "*/admin/*")

  echo "→ Rebuilding wiki home + search from CMS state..." >&2
  python3 "$SCRIPT_DIR/render-wiki.py" "$GITPAGES" "$THEME_JSON" "$REPO_NAME" "$WIKI_BASE"
  python3 "$SCRIPT_DIR/build-search-index.py" "$GITPAGES"

  # Render admin dashboard
  python3 "$SCRIPT_DIR/render-admin.py" "$GITPAGES" "$THEME_JSON" "$WIKI_BASE" --cms-state "$CMS_DB_PATH"

  # Wave 2: render BU homes + project homes
  for BU_DIR in "$GITPAGES"/staging "$GITPAGES"/vita "$GITPAGES"/allin "$GITPAGES"/aleyemma "$GITPAGES"/gobbi; do
    BU_SLUG=$(basename "$BU_DIR")
    mkdir -p "$BU_DIR"
    python3 "$SCRIPT_DIR/render-bu.py" "$GITPAGES" "$THEME_JSON" "$BU_SLUG" "$WIKI_BASE"
    for PROJ_DIR in "$BU_DIR"/*/; do
      [ -d "$PROJ_DIR" ] || continue
      PROJ_SLUG=$(basename "$PROJ_DIR")
      python3 "$SCRIPT_DIR/render-project.py" "$GITPAGES" "$THEME_JSON" "$BU_SLUG" "$PROJ_SLUG" "$WIKI_BASE"
    done
  done

  echo "→ Rebuilt $REBUILT_COUNT articles, removed $REMOVED_COUNT, skipped $SKIPPED_COUNT" >&2
fi

if [ "$DRY_RUN" = "true" ]; then
  echo "{\"dry_run\":true,\"workdir\":\"$WORKDIR\",\"artifact_dir\":\"$ARTIFACT_DIR\",\"url\":\"$URL\",\"password\":\"$PASSWORD\",\"slug\":\"$SLUG\",\"tema\":\"$TEMA\",\"mode\":\"$MODE\"}"
  trap - EXIT
  echo "→ Workdir preserved: $WORKDIR" >&2
  exit 0
fi

cd "$WORKDIR"
stage_publish_paths

if [ "$VALIDATE_ONLY" = "true" ]; then
  if git diff --cached --quiet; then
    HAS_CHANGES="false"
  else
    HAS_CHANGES="true"
  fi
  VALIDATE_ARGS=("$WORKDIR" "$URL" "$SLUG" "$TEMA" "$MODE" "$HAS_CHANGES")
  if [ "${#STAGE_PATHS[@]}" -gt 0 ]; then
    VALIDATE_ARGS+=("${STAGE_PATHS[@]}")
  fi
  python3 - "${VALIDATE_ARGS[@]}" <<'PYEOF'
import json
import sys

workdir, url, slug, tema, mode, has_changes, *stage_paths = sys.argv[1:]
print(json.dumps({
    "validate_only": True,
    "would_push": False,
    "changed": has_changes == "true",
    "workdir": workdir,
    "url": url,
    "slug": slug,
    "tema": tema,
    "mode": mode,
    "staged_paths": stage_paths,
}, ensure_ascii=False))
PYEOF
  trap - EXIT
  echo "→ Validation workdir preserved: $WORKDIR" >&2
  exit 0
fi

COMMIT_MSG="feat($SLUG): publish via wikia"
if git diff --cached --quiet; then
  COMMIT_SHA=$(git rev-parse HEAD)
else
  git -c commit.gpgsign=false commit -m "$COMMIT_MSG" >&2 2>&1
  COMMIT_SHA=$(git rev-parse HEAD)
  echo "→ Pushing..." >&2
  git push >&2 2>&1
fi

gh api -X POST "/repos/$REPO/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1 || true

echo "→ Polling Pages build..." >&2
for i in 1 2 3 4 5 6 7 8 9 10; do
  s=$(gh api "/repos/$REPO/pages/builds/latest" --jq .status 2>/dev/null || echo "?")
  echo "  build $i: $s" >&2
  if [ "$s" = "built" ]; then break; fi
  sleep 12
done

echo "{\"url\":\"$URL\",\"password\":\"$PASSWORD\",\"commit\":\"$COMMIT_SHA\",\"slug\":\"$SLUG\",\"tema\":\"$TEMA\",\"mode\":\"$MODE\",\"wiki\":\"$WIKI_BASE/\",\"models\":\"$([ "$ENRICH" = "true" ] && echo "claude,codex,gemini" || echo "claude")\"}"
