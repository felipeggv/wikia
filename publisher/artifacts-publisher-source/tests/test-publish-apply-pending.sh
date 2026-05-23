#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PUBLISH_SCRIPT="${SOURCE_ROOT}/scripts/publish.sh"
VAULT_SCRIPT="${SOURCE_ROOT}/scripts/vault.mjs"
SYNC_STATE_SCRIPT="${SOURCE_ROOT}/scripts/sync-cms-state.py"
TMP_PARENT="${TMP_PARENT:-${SOURCE_ROOT}/.test-tmp/publish-apply-pending-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  if [[ "${KEEP_FAILED_TEST_DIR:-}" == "1" && -n "${RUN_DIR:-}" ]]; then
    trap - EXIT
    printf 'DEBUG_DIR: %s\n' "$RUN_DIR" >&2
  fi
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

workdir_from_json() {
  python3 - "$1" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(payload["workdir"])
PY
}

require_file "$PUBLISH_SCRIPT"
require_file "$VAULT_SCRIPT"
require_file "$SYNC_STATE_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

REAL_GIT="$(command -v git)"
ORIGIN_REPO="${RUN_DIR}/origin"
PUBLIC_ROOT="${ORIGIN_REPO}/docs/gitpages"
PRIVATE_SOURCE_ROOT="${RUN_DIR}/private-source"
FAKE_BIN="${RUN_DIR}/bin"
MASTERPASS_FILE="${RUN_DIR}/masterpass.txt"
MASTERPASS_VALUE="fixture-masterpass-apply-pending"
mkdir -p "$PUBLIC_ROOT" "$PRIVATE_SOURCE_ROOT" "$FAKE_BIN"
touch "${ORIGIN_REPO}/docs/.nojekyll" "${PUBLIC_ROOT}/.nojekyll"
printf '%s\n' "$MASTERPASS_VALUE" > "$MASTERPASS_FILE"
printf '%s\n' '[]' > "${PUBLIC_ROOT}/_released.json"
printf '%s\n' '{}' > "${PUBLIC_ROOT}/_pending-changes.json"

write_raw() {
  local bu="$1"
  local project="$2"
  local slug="$3"
  local title="$4"
  local tags="$5"
  local marker="$6"
  local dir="${PRIVATE_SOURCE_ROOT}/${bu}/${project}/${slug}"
  mkdir -p "$dir"
  cat > "${dir}/raw.md" <<EOF
---
bu: ${bu}
project: ${project}
slug: ${slug}
title: ${title}
date: 2026-05-19
tags: [${tags}]
gate: vault
---

# ${title}

${marker}
EOF
}

write_raw staging apply-pending release-target "Release Funnel Memo" "growth, release" "RELEASE_BODY_MARKER"
write_raw gobbi secure rotate-target "Rotation Secret Plan" "private, rotate" "ROTATE_BODY_MARKER_NEVER_PUBLIC"
write_raw gobbi secure remove-target "Removal Secret Plan" "private, remove" "REMOVE_BODY_MARKER_NEVER_PUBLIC"
write_raw vita sales scope-target "Scope Secret Plan" "private, scope" "SCOPE_BODY_MARKER_NEVER_PUBLIC"

mkdir -p "${PUBLIC_ROOT}/gobbi/secure/remove-target"
printf '%s\n' '<html><body>STALE_REMOVE_PAGE</body></html>' > "${PUBLIC_ROOT}/gobbi/secure/remove-target/index.html"

WIKIA_MASTERPASS="$MASTERPASS_VALUE" node "$VAULT_SCRIPT" init "${PUBLIC_ROOT}/_passwords.enc" --force >/dev/null
WIKIA_MASTERPASS="$MASTERPASS_VALUE" node "$VAULT_SCRIPT" set "${PUBLIC_ROOT}/_passwords.enc" rotate-target old-rotate-password --tema secure >/dev/null
WIKIA_MASTERPASS="$MASTERPASS_VALUE" node "$VAULT_SCRIPT" set "${PUBLIC_ROOT}/_passwords.enc" remove-target remove-secret --tema secure >/dev/null
WIKIA_MASTERPASS="$MASTERPASS_VALUE" node "$VAULT_SCRIPT" set "${PUBLIC_ROOT}/_passwords.enc" scope-target scope-secret --tema sales >/dev/null

python3 "$SYNC_STATE_SCRIPT" "$PUBLIC_ROOT" "$PRIVATE_SOURCE_ROOT" \
  --released "${PUBLIC_ROOT}/_released.json" \
  --cms-db "${RUN_DIR}/initial-admin-state.sqlite3" \
  --admin-metadata-out "${RUN_DIR}/initial-admin-metadata.json" \
  --json > "${RUN_DIR}/initial-sync.json"

cat > "${PUBLIC_ROOT}/_pending-changes.json" <<'EOF'
{
  "schema_version": 1,
  "release": [
    {
      "key": "staging/apply-pending/release-target",
      "bu": "staging",
      "project": "apply-pending",
      "slug": "release-target",
      "target_release_status": "released"
    }
  ],
  "rotate": [
    {
      "key": "gobbi/secure/rotate-target",
      "bu": "gobbi",
      "project": "secure",
      "slug": "rotate-target",
      "vault_key": "rotate-target"
    }
  ],
  "remove": [
    {
      "key": "gobbi/secure/remove-target",
      "bu": "gobbi",
      "project": "secure",
      "slug": "remove-target",
      "vault_key": "remove-target",
      "target_release_status": "removed"
    }
  ],
  "scope": [
    {
      "key": "vita/sales/scope-target",
      "bu": "vita",
      "project": "sales",
      "slug": "scope-target",
      "from_scope": "article",
      "to_scope": "bu"
    }
  ],
  "intents": []
}
EOF

"$REAL_GIT" -C "$ORIGIN_REPO" init >/dev/null
"$REAL_GIT" -C "$ORIGIN_REPO" add docs/.nojekyll docs/gitpages
"$REAL_GIT" -C "$ORIGIN_REPO" \
  -c user.name="Publish Apply Pending Fixture" \
  -c user.email="publish-apply-pending@example.invalid" \
  commit -m "initial apply-pending fixture" >/dev/null

cat > "${FAKE_BIN}/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "clone" ]]; then
  dest="${@: -1}"
  "$REAL_GIT" clone "$PUBLISH_TEST_ORIGIN" "$dest"
  exit 0
fi

if [[ "${1:-}" == "push" ]]; then
  echo "git push must not run during publish apply-pending validation" >&2
  exit 70
fi

exec "$REAL_GIT" "$@"
SH
chmod +x "${FAKE_BIN}/git"

cat > "${FAKE_BIN}/gh" <<'SH'
#!/usr/bin/env bash
echo "gh must not run during publish apply-pending validation" >&2
exit 71
SH
chmod +x "${FAKE_BIN}/gh"

VALIDATE_JSON="${RUN_DIR}/validate.json"
if ! PUBLISH_TEST_ORIGIN="$ORIGIN_REPO" REAL_GIT="$REAL_GIT" PATH="${FAKE_BIN}:$PATH" \
  bash "$PUBLISH_SCRIPT" \
      --apply-pending \
      --repo fixture/wiki \
      --private-source-root "$PRIVATE_SOURCE_ROOT" \
      --masterpass-file "$MASTERPASS_FILE" \
      --validate \
      > "$VALIDATE_JSON" \
      2> "${RUN_DIR}/validate.err"; then
  sed -n '1,220p' "${RUN_DIR}/validate.err" >&2 || true
  fail "publish apply-pending validation failed"
fi

WORKDIR="$(workdir_from_json "$VALIDATE_JSON")"
RESULT_PUBLIC_ROOT="${WORKDIR}/docs/gitpages"

python3 - "$VALIDATE_JSON" "$RESULT_PUBLIC_ROOT" <<'PY'
import json
import sys
from pathlib import Path

validate_path = Path(sys.argv[1])
public_root = Path(sys.argv[2])
payload = json.loads(validate_path.read_text(encoding="utf-8"))
if payload.get("validate_only") is not True:
    raise SystemExit("publish did not run in validation mode")
if payload.get("would_push") is not False:
    raise SystemExit("publish validation attempted to push")

required_staged = {
    "docs/gitpages/_admin.enc",
    "docs/gitpages/_catalog.json",
    "docs/gitpages/_passwords.enc",
    "docs/gitpages/_pending-changes.json",
    "docs/gitpages/_released.json",
    "docs/gitpages/admin/index.html",
    "docs/gitpages/index.html",
    "docs/gitpages/search.json",
    "docs/gitpages/staging/index.html",
    "docs/gitpages/staging/apply-pending/index.html",
    "docs/gitpages/staging/apply-pending/release-target/index.html",
    "docs/gitpages/gobbi/secure/rotate-target/index.html",
    "docs/gitpages/gobbi/secure/remove-target/index.html",
    "docs/gitpages/vita/sales/scope-target/index.html",
}
staged = set(payload.get("staged_paths") or [])
missing = sorted(required_staged - staged)
if missing:
    raise SystemExit(f"missing staged paths: {missing}")
for path in staged:
    if path.endswith("/raw.md"):
        raise SystemExit(f"public raw markdown was staged: {path}")
    if path.endswith(".sqlite3") or path.endswith("_admin.db"):
        raise SystemExit(f"plaintext CMS state was staged: {path}")

catalog = json.loads((public_root / "_catalog.json").read_text(encoding="utf-8"))
records = {row["canonical_key"]: row for row in catalog.get("records", [])}
release = records["staging/apply-pending/release-target"]
rotate = records["gobbi/secure/rotate-target"]
removed = records["gobbi/secure/remove-target"]
scoped = records["vita/sales/scope-target"]

if release["release_status"] != "released" or release["gate_status"] != "public" or release["scope"] != "public":
    raise SystemExit(f"release record mismatch: {release}")
if release["title_public"] != "Release Funnel Memo" or release["tags"] != ["growth", "release"]:
    raise SystemExit("released record did not expose public title and tags")
if rotate["release_status"] != "unreleased" or rotate["gate_status"] != "gated":
    raise SystemExit(f"rotate record mismatch: {rotate}")
if removed["release_status"] != "removed" or removed["title_visible"] is not False:
    raise SystemExit(f"removed record mismatch: {removed}")
if scoped["scope"] != "bu" or scoped["release_status"] != "unreleased":
    raise SystemExit(f"scope record mismatch: {scoped}")

pending = json.loads((public_root / "_pending-changes.json").read_text(encoding="utf-8"))
if pending != {}:
    raise SystemExit(f"pending queue was not cleared: {pending}")
released = json.loads((public_root / "_released.json").read_text(encoding="utf-8"))
if "staging/apply-pending/release-target" not in released:
    raise SystemExit(f"released ledger missing canonical key: {released}")

search_text = (public_root / "search.json").read_text(encoding="utf-8")
home_text = (public_root / "index.html").read_text(encoding="utf-8")
bu_text = (public_root / "staging/index.html").read_text(encoding="utf-8")
project_text = (public_root / "staging/apply-pending/index.html").read_text(encoding="utf-8")
released_html = (public_root / "staging/apply-pending/release-target/index.html").read_text(encoding="utf-8")
rotate_html = (public_root / "gobbi/secure/rotate-target/index.html").read_text(encoding="utf-8")
scope_html = (public_root / "vita/sales/scope-target/index.html").read_text(encoding="utf-8")
admin_html = (public_root / "admin/index.html").read_text(encoding="utf-8")

for label, text in {
    "search": search_text,
    "home": home_text,
    "bu": bu_text,
    "project": project_text,
}.items():
    if "Release Funnel Memo" not in text:
        raise SystemExit(f"{label} was not regenerated from released state")

for label, text in {
    "search": search_text,
    "home": home_text,
    "bu": bu_text,
    "project": project_text,
    "rotate": rotate_html,
    "scope": scope_html,
}.items():
    for marker in (
        "Rotation Secret Plan",
        "ROTATE_BODY_MARKER_NEVER_PUBLIC",
        "Removal Secret Plan",
        "REMOVE_BODY_MARKER_NEVER_PUBLIC",
        "Scope Secret Plan",
        "SCOPE_BODY_MARKER_NEVER_PUBLIC",
    ):
        if marker in text:
            raise SystemExit(f"{label} leaked private marker: {marker}")

if "ap-gate-script" in released_html or "RELEASE_BODY_MARKER" not in released_html:
    raise SystemExit("released article was not rendered as public plaintext")
if "ap-gate-script" not in rotate_html or "ap-gate-script" not in scope_html:
    raise SystemExit("gated articles were not rendered with encrypted gates")
if (public_root / "gobbi/secure/remove-target/index.html").exists():
    raise SystemExit("removed article page still exists")
if "/_admin.enc" not in admin_html:
    raise SystemExit("admin shell does not reference encrypted admin metadata")
if "Rotation Secret Plan" in (public_root / "_admin.enc").read_text(encoding="utf-8"):
    raise SystemExit("_admin.enc contains plaintext private title")
PY

WIKIA_MASTERPASS="$MASTERPASS_VALUE" node "$VAULT_SCRIPT" get "${RESULT_PUBLIC_ROOT}/_passwords.enc" rotate-target > "${RUN_DIR}/rotated.json"
python3 - "${RUN_DIR}/rotated.json" <<'PY'
import json
import sys
from pathlib import Path

entry = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if entry.get("password") == "old-rotate-password":
    raise SystemExit("rotate-target password did not change")
PY

if WIKIA_MASTERPASS="$MASTERPASS_VALUE" node "$VAULT_SCRIPT" get "${RESULT_PUBLIC_ROOT}/_passwords.enc" remove-target > "${RUN_DIR}/removed-vault.json" 2>/dev/null; then
  fail "remove-target still exists in vault"
fi

WIKIA_MASTERPASS="$MASTERPASS_VALUE" node "$VAULT_SCRIPT" list "${RESULT_PUBLIC_ROOT}/_admin.enc" > "${RUN_DIR}/admin-enc-list.json"
python3 - "${RUN_DIR}/admin-enc-list.json" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if "records" not in payload.get("slugs", []):
    raise SystemExit("_admin.enc did not decrypt as metadata object")
PY

cat <<EOF
---
type: report
title: Publish Apply Pending Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-06
  - publish
  - apply-pending
related:
  - '[[PHASE-06-PUBLISH]]'
  - '[[CMS-CONTRACT]]'
---

# Publish Apply Pending Test

## Executive Summary

The publish pipeline applied pending release, rotate, remove, and scope intents
before regenerating public and admin outputs from one CMS state.

\`\`\`text
_pending-changes.json
   |
   v
apply-pending -> catalog + released ledger + vault
   |
   v
sync-cms-state -> _catalog.json + admin state + _admin.enc
   |
   v
admin, search, home, BU, project, article pages
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| \`--apply-pending\` implied rebuild-all behavior | PASS |
| Pending queue was cleared after apply | PASS |
| Released ledger stored canonical BU/project/slug key | PASS |
| Catalog release state was public/released | PASS |
| Catalog rotate target stayed gated/unreleased | PASS |
| Catalog remove target was marked removed | PASS |
| Catalog scope target changed to BU scope | PASS |
| Rotated vault password changed | PASS |
| Removed vault entry stayed removed after rebuild | PASS |
| Encrypted \`_admin.enc\` was generated and decryptable | PASS |
| Search, home, BU, and project pages reflected released state | PASS |
| Released article rendered without gate | PASS |
| Gated article pages rendered with encrypted gates | PASS |
| Removed article page was deleted | PASS |
| No public output leaked private fixture markers | PASS |
| Fake git push guard was not triggered | PASS |
| Fake gh guard was not triggered | PASS |

## Images Analyzed

0
EOF
