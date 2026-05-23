#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${WIKIA_TEST_SOURCE_ROOT:-${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}}"
APP_ROOT="$(cd "$SOURCE_ROOT/../.." && pwd)"
PUBLISH_SCRIPT="${SOURCE_ROOT}/scripts/publish.sh"
PUBLIC_CATALOG_SCRIPT="${SOURCE_ROOT}/scripts/public_catalog.py"
TMP_PARENT="${WIKIA_TEST_TMP_PARENT:-${TMP_PARENT:-$APP_ROOT/.tmp/wikia-tests/publish-private-source-tests}}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$PUBLISH_SCRIPT"
require_file "$PUBLIC_CATALOG_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

REAL_GIT="$(command -v git)"
ORIGIN_REPO="${RUN_DIR}/origin"
FAKE_BIN="${RUN_DIR}/bin"
PRIVATE_SOURCE_ROOT="${RUN_DIR}/private-source"
mkdir -p "$ORIGIN_REPO/docs/gitpages" "$FAKE_BIN" "$PRIVATE_SOURCE_ROOT"
touch "$ORIGIN_REPO/docs/.nojekyll" "$ORIGIN_REPO/docs/gitpages/.nojekyll"

"$REAL_GIT" -C "$ORIGIN_REPO" init >/dev/null
"$REAL_GIT" -C "$ORIGIN_REPO" add docs/.nojekyll docs/gitpages/.nojekyll
"$REAL_GIT" -C "$ORIGIN_REPO" \
  -c user.name="Publish Private Source Fixture" \
  -c user.email="publish-private-source@example.invalid" \
  commit -m "initial fixture" >/dev/null

LEGACY_PUBLIC_ARTICLE="${ORIGIN_REPO}/docs/gitpages/gobbi/confidential-funnels/sealed-playbook"
mkdir -p "$LEGACY_PUBLIC_ARTICLE"
cat > "${LEGACY_PUBLIC_ARTICLE}/raw.md" <<'EOF'
---
bu: gobbi
project: confidential-funnels
slug: sealed-playbook
title: Legacy Public Private Raw
date: 2026-05-18
tags: [private, legacy]
gate: vault
---

# Legacy Public Private Raw

LEGACY_PRIVATE_BODY_MARKER_NEVER_PUBLISH
EOF
"$REAL_GIT" -C "$ORIGIN_REPO" add docs/gitpages/gobbi/confidential-funnels/sealed-playbook/raw.md
"$REAL_GIT" -C "$ORIGIN_REPO" \
  -c user.name="Publish Private Source Fixture" \
  -c user.email="publish-private-source@example.invalid" \
  commit -m "legacy public private raw fixture" >/dev/null

cat > "${FAKE_BIN}/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "clone" ]]; then
  dest="${@: -1}"
  "$REAL_GIT" clone "$PUBLISH_TEST_ORIGIN" "$dest"
  exit 0
fi

if [[ "${1:-}" == "push" ]]; then
  echo "git push must not run during publish private-source validation" >&2
  exit 70
fi

exec "$REAL_GIT" "$@"
SH
chmod +x "${FAKE_BIN}/git"

cat > "${FAKE_BIN}/gh" <<'SH'
#!/usr/bin/env bash
echo "gh must not run during publish private-source validation" >&2
exit 71
SH
chmod +x "${FAKE_BIN}/gh"

RAW_MD="${RUN_DIR}/incoming-private.md"
cat > "$RAW_MD" <<'EOF'
---
bu: gobbi
project: confidential-funnels
slug: sealed-playbook
title: Executive Acquisition Map
date: 2026-05-19
tags: [private, acquisition]
gate: vault
---

# Executive Acquisition Map

PRIVATE_BODY_MARKER_NEVER_PUBLISH

This private acquisition thesis must exist only inside the encrypted payload.
EOF

VALIDATE_JSON="${RUN_DIR}/validate.json"
PUBLISH_TEST_ORIGIN="$ORIGIN_REPO" REAL_GIT="$REAL_GIT" WIKIA_PUBLISH_TMP_PARENT="${RUN_DIR}/publish-workdirs" PATH="${FAKE_BIN}:$PATH" \
  bash "$PUBLISH_SCRIPT" \
    --title "Executive Acquisition Map" \
    --content "$RAW_MD" \
    --repo fixture/wiki \
    --password "fixture-article-password" \
    --bu gobbi \
    --project confidential-funnels \
    --slug sealed-playbook \
    --private-source-root "$PRIVATE_SOURCE_ROOT" \
    --validate \
    > "$VALIDATE_JSON" \
    2> "${RUN_DIR}/validate.err"

python3 - "$VALIDATE_JSON" "$PRIVATE_SOURCE_ROOT" <<'PY'
import json
import sys
from pathlib import Path

validate_path = Path(sys.argv[1])
private_source_root = Path(sys.argv[2])
payload = json.loads(validate_path.read_text(encoding="utf-8"))

if payload.get("validate_only") is not True:
    raise SystemExit("publish did not run in validation mode")
if payload.get("would_push") is not False:
    raise SystemExit("publish validation attempted to push")

workdir = Path(payload["workdir"])
public_root = workdir / "docs" / "gitpages"
article_dir = public_root / "gobbi" / "confidential-funnels" / "sealed-playbook"
article_html = article_dir / "index.html"
public_raw = article_dir / "raw.md"
private_raw = private_source_root / "gobbi" / "confidential-funnels" / "sealed-playbook" / "raw.md"
catalog_path = public_root / "_catalog.json"
search_path = public_root / "search.json"
home_path = public_root / "index.html"
bu_path = public_root / "gobbi" / "index.html"
project_path = public_root / "gobbi" / "confidential-funnels" / "index.html"

for required in (article_html, private_raw, catalog_path, search_path, home_path, bu_path, project_path):
    if not required.is_file():
        raise SystemExit(f"missing expected output: {required}")
if public_raw.exists():
    raise SystemExit(f"private raw markdown was written to public output: {public_raw}")

staged = set(payload.get("staged_paths") or [])
if "docs/gitpages/gobbi/confidential-funnels/sealed-playbook/raw.md" not in staged:
    raise SystemExit("legacy public private raw.md deletion was not staged")
for path in staged:
    if path.endswith("/raw.md") and not path.endswith("/sealed-playbook/raw.md"):
        raise SystemExit(f"public raw markdown was staged: {path}")
for required in (
    "docs/gitpages/_catalog.json",
    "docs/gitpages/gobbi/confidential-funnels/sealed-playbook/index.html",
):
    if required not in staged:
        raise SystemExit(f"missing staged path: {required}")

article_text = article_html.read_text(encoding="utf-8")
if "ap-gate-script" not in article_text:
    raise SystemExit("gated article did not include the unlock script")
if "<template id=\"ap-content-tpl\">" in article_text:
    raise SystemExit("plaintext article template remained in public HTML")
if "Protected article" not in article_text:
    raise SystemExit("gated page did not use a sanitized public title")

leak_markers = [
    "Executive Acquisition Map",
    "PRIVATE_BODY_MARKER_NEVER_PUBLISH",
    "LEGACY_PRIVATE_BODY_MARKER_NEVER_PUBLISH",
    "private acquisition thesis",
    "private, acquisition",
]
public_texts = {
    "article": article_text,
    "catalog": catalog_path.read_text(encoding="utf-8"),
    "search": search_path.read_text(encoding="utf-8"),
    "home": home_path.read_text(encoding="utf-8"),
    "bu": bu_path.read_text(encoding="utf-8"),
    "project": project_path.read_text(encoding="utf-8"),
}
for label, text in public_texts.items():
    for marker in leak_markers:
        if marker in text:
            raise SystemExit(f"{label} leaked private marker: {marker}")

catalog = json.loads(public_texts["catalog"])
records = catalog.get("records") or []
if len(records) != 1:
    raise SystemExit(f"expected one catalog record, got {len(records)}")
record = records[0]
checks = {
    "title_visible": False,
    "title_public": None,
    "gate_status": "gated",
    "release_status": "unreleased",
    "scope": "article",
    "tags": [],
    "output_url": "gobbi/confidential-funnels/sealed-playbook/",
}
for key, expected in checks.items():
    if record.get(key) != expected:
        raise SystemExit(f"catalog {key} mismatch: expected {expected!r}, got {record.get(key)!r}")

search = json.loads(public_texts["search"])
if search != []:
    raise SystemExit(f"private gated article should not appear in public search: {search}")
PY

cat <<EOF
---
type: report
title: Publish Private Source Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-06
  - publish
  - privacy
related:
  - '[[PHASE-06-PUBLISH]]'
  - '[[CMS-CONTRACT]]'
---

# Publish Private Source Test

## Executive Summary

The publish pipeline rendered a gated article from a private source tree while
keeping plaintext \`raw.md\` out of the public GitHub Pages output.

\`\`\`text
private-source/raw.md
   |
   v
publish.sh --validate
   |
   +-- docs/gitpages/.../index.html encrypted gate
   +-- docs/gitpages/_catalog.json sanitized
   +-- docs/gitpages/search.json public-only
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Private source raw.md was preserved outside docs/gitpages | PASS |
| Legacy public private raw.md was deleted | PASS |
| Public article raw.md was not written | PASS |
| Public raw.md deletion was staged explicitly | PASS |
| Gated article HTML includes unlock script | PASS |
| Plaintext article template was removed after encryption | PASS |
| Private title did not appear in public article/catalog/search/index pages | PASS |
| Private body marker did not appear in public article/catalog/search/index pages | PASS |
| Public catalog record hides private title and tags | PASS |
| Public search excludes the gated private article | PASS |
| Fake git push guard was not triggered | PASS |
| Fake gh guard was not triggered | PASS |

## Images Analyzed

0
EOF
