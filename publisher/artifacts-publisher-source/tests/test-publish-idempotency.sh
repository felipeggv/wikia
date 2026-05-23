#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${WIKIA_TEST_SOURCE_ROOT:-${SOURCE_ROOT:-$(cd "$TEST_DIR/.." && pwd)}}"
APP_ROOT="$(cd "$SOURCE_ROOT/../.." && pwd)"
PUBLISH_SCRIPT="${SOURCE_ROOT}/scripts/publish.sh"
TMP_PARENT="${WIKIA_TEST_TMP_PARENT:-${TMP_PARENT:-$APP_ROOT/.tmp/wikia-tests/publish-idempotency-tests}}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
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

require_validate_json() {
  local label="$1"
  local validate_json="$2"
  local validate_err="$3"

  if [[ ! -s "$validate_json" ]]; then
    printf 'publish %s produced empty validation JSON\n' "$label" >&2
    sed -n '1,220p' "$validate_err" >&2 || true
    fail "publish ${label} produced empty validation JSON"
  fi

  if ! python3 - "$validate_json" >/dev/null <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("validate_only") is not True:
    raise SystemExit("validate_only was not true")
PY
  then
    printf 'publish %s produced invalid validation JSON\n' "$label" >&2
    sed -n '1,220p' "$validate_json" >&2 || true
    sed -n '1,220p' "$validate_err" >&2 || true
    fail "publish ${label} produced invalid validation JSON"
  fi
}

sync_generated_to_origin() {
  local validate_json="$1"
  local workdir
  workdir="$(workdir_from_json "$validate_json")"

  rm -rf "${ORIGIN_REPO}/docs/gitpages"
  mkdir -p "${ORIGIN_REPO}/docs"
  cp -R "${workdir}/docs/gitpages" "${ORIGIN_REPO}/docs/"

  "$REAL_GIT" -C "$ORIGIN_REPO" add \
    docs/.nojekyll \
    docs/gitpages/.nojekyll \
    docs/gitpages/_catalog.json \
    docs/gitpages/index.html \
    docs/gitpages/search.json \
    docs/gitpages/staging/index.html \
    docs/gitpages/staging/idempotency/index.html \
    docs/gitpages/staging/idempotency/repeatable-canonical-record/index.html
  "$REAL_GIT" -C "$ORIGIN_REPO" \
    -c user.name="Publish Idempotency Fixture" \
    -c user.email="publish-idempotency@example.invalid" \
    commit -m "fixture publish sync" >/dev/null
}

run_publish_validate() {
  local raw_md="$1"
  local validate_json="$2"
  local validate_err="$3"

  PUBLISH_TEST_ORIGIN="$ORIGIN_REPO" REAL_GIT="$REAL_GIT" WIKIA_PUBLISH_TMP_PARENT="${RUN_DIR}/publish-workdirs" PATH="${FAKE_BIN}:$PATH" \
    bash "$PUBLISH_SCRIPT" \
      --title "Repeatable Canonical Record" \
      --content "$raw_md" \
      --repo fixture/wiki \
      --no-gate \
      --bu staging \
      --project idempotency \
      --slug repeatable-canonical-record \
      --validate \
      > "$validate_json" \
      2> "$validate_err"
}

require_file "$PUBLISH_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

REAL_GIT="$(command -v git)"
ORIGIN_REPO="${RUN_DIR}/origin"
FAKE_BIN="${RUN_DIR}/bin"
mkdir -p "$ORIGIN_REPO/docs/gitpages" "$FAKE_BIN"
touch "$ORIGIN_REPO/docs/.nojekyll" "$ORIGIN_REPO/docs/gitpages/.nojekyll"

"$REAL_GIT" -C "$ORIGIN_REPO" init >/dev/null
"$REAL_GIT" -C "$ORIGIN_REPO" add docs/.nojekyll docs/gitpages/.nojekyll
"$REAL_GIT" -C "$ORIGIN_REPO" \
  -c user.name="Publish Idempotency Fixture" \
  -c user.email="publish-idempotency@example.invalid" \
  commit -m "initial fixture" >/dev/null

cat > "${FAKE_BIN}/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "clone" ]]; then
  dest="${@: -1}"
  "$REAL_GIT" clone "$PUBLISH_TEST_ORIGIN" "$dest"
  exit 0
fi

if [[ "${1:-}" == "push" ]]; then
  echo "git push must not run during publish idempotency validation" >&2
  exit 70
fi

exec "$REAL_GIT" "$@"
SH
chmod +x "${FAKE_BIN}/git"

cat > "${FAKE_BIN}/gh" <<'SH'
#!/usr/bin/env bash
echo "gh must not run during publish idempotency validation" >&2
exit 71
SH
chmod +x "${FAKE_BIN}/gh"

RAW_V1="${RUN_DIR}/raw-v1.md"
cat > "$RAW_V1" <<'EOF'
---
bu: staging
project: idempotency
slug: repeatable-canonical-record
title: First Growth Playbook
date: 2026-05-19
tags: [growth, public]
gate: null
---

# First Growth Playbook

FIRST_DEPENDENT_VIEW_MARKER
EOF

FIRST_JSON="${RUN_DIR}/first.json"
FIRST_ERR="${RUN_DIR}/first.err"
run_publish_validate "$RAW_V1" "$FIRST_JSON" "$FIRST_ERR"
require_validate_json "first" "$FIRST_JSON" "$FIRST_ERR"
sync_generated_to_origin "$FIRST_JSON"

FIRST_FACTS="${RUN_DIR}/first-facts.json"
python3 - "$FIRST_JSON" "$FIRST_FACTS" <<'PY'
import json
import sys
from pathlib import Path

validate_json, facts_path = [Path(arg) for arg in sys.argv[1:3]]
payload = json.loads(validate_json.read_text(encoding="utf-8"))
workdir = Path(payload["workdir"])
catalog = json.loads((workdir / "docs/gitpages/_catalog.json").read_text(encoding="utf-8"))
records = catalog.get("records") or []
if len(records) != 1:
    raise SystemExit(f"expected one first catalog record, got {len(records)}")
record = records[0]
for field in ("article_id", "canonical_key", "idempotency_key", "raw_hash", "scope"):
    if not record.get(field):
        raise SystemExit(f"first record missing {field}")
if record["canonical_key"] != "staging/idempotency/repeatable-canonical-record":
    raise SystemExit(f"canonical key mismatch: {record['canonical_key']}")
Path(facts_path).write_text(json.dumps({
    "article_id": record["article_id"],
    "canonical_key": record["canonical_key"],
    "idempotency_key": record["idempotency_key"],
    "raw_hash": record["raw_hash"],
}, sort_keys=True), encoding="utf-8")
PY

RAW_V2="${RUN_DIR}/raw-v2.md"
cat > "$RAW_V2" <<'EOF'
---
bu: staging
project: idempotency
slug: repeatable-canonical-record
title: Second Growth Playbook
date: 2026-05-19
tags: [growth, updated]
gate: null
---

# Second Growth Playbook

UPDATED_DEPENDENT_VIEW_MARKER
EOF

SECOND_JSON="${RUN_DIR}/second.json"
SECOND_ERR="${RUN_DIR}/second.err"
run_publish_validate "$RAW_V2" "$SECOND_JSON" "$SECOND_ERR"
require_validate_json "second" "$SECOND_JSON" "$SECOND_ERR"

python3 - "$FIRST_FACTS" "$SECOND_JSON" <<'PY'
import json
import sys
from pathlib import Path

first_facts = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
payload = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
if payload.get("validate_only") is not True:
    raise SystemExit("second publish did not run in validation mode")
if payload.get("would_push") is not False:
    raise SystemExit("second publish attempted to push")

workdir = Path(payload["workdir"])
public_root = workdir / "docs/gitpages"
catalog = json.loads((public_root / "_catalog.json").read_text(encoding="utf-8"))
records = catalog.get("records") or []
if len(records) != 1:
    raise SystemExit(f"republish created duplicate catalog records: {len(records)}")

record = records[0]
if record["article_id"] != first_facts["article_id"]:
    raise SystemExit("republish changed the canonical article_id")
if record["canonical_key"] != first_facts["canonical_key"]:
    raise SystemExit("republish changed the canonical route key")
if record["raw_hash"] == first_facts["raw_hash"]:
    raise SystemExit("republish did not update raw_hash for edited raw.md")
if record["idempotency_key"] == first_facts["idempotency_key"]:
    raise SystemExit("republish did not update idempotency_key for edited raw.md")
if record["title_public"] != "Second Growth Playbook":
    raise SystemExit("catalog did not update the public title")

expected_staged = {
    "docs/gitpages/_catalog.json",
    "docs/gitpages/index.html",
    "docs/gitpages/search.json",
    "docs/gitpages/staging/index.html",
    "docs/gitpages/staging/idempotency/index.html",
    "docs/gitpages/staging/idempotency/repeatable-canonical-record/index.html",
}
staged = set(payload.get("staged_paths") or [])
missing = sorted(expected_staged - staged)
if missing:
    raise SystemExit(f"dependent publish paths were not staged: {missing}")

expected_marker = "Second Growth Playbook"
checks = {
    "article": public_root / "staging/idempotency/repeatable-canonical-record/index.html",
    "home": public_root / "index.html",
    "search": public_root / "search.json",
    "bu": public_root / "staging/index.html",
    "project": public_root / "staging/idempotency/index.html",
}
for label, path in checks.items():
    text = path.read_text(encoding="utf-8")
    if expected_marker not in text:
        raise SystemExit(f"{label} was not regenerated with the updated title")
PY

sync_generated_to_origin "$SECOND_JSON"
THIRD_JSON="${RUN_DIR}/third.json"
THIRD_ERR="${RUN_DIR}/third.err"
run_publish_validate "$RAW_V2" "$THIRD_JSON" "$THIRD_ERR"
require_validate_json "third" "$THIRD_JSON" "$THIRD_ERR"

python3 - "$SECOND_JSON" "$THIRD_JSON" <<'PY'
import json
import sys
from pathlib import Path

second = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
third = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

def record(payload):
    workdir = Path(payload["workdir"])
    catalog = json.loads((workdir / "docs/gitpages/_catalog.json").read_text(encoding="utf-8"))
    records = catalog.get("records") or []
    if len(records) != 1:
        raise SystemExit(f"expected one catalog record, got {len(records)}")
    return records[0]

second_record = record(second)
third_record = record(third)
for field in ("article_id", "canonical_key", "raw_hash", "scope", "idempotency_key"):
    if third_record[field] != second_record[field]:
        raise SystemExit(f"exact republish changed {field}")
PY

cat <<EOF
---
type: report
title: Publish Idempotency Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-06
  - publish
  - idempotency
related:
  - '[[PHASE-06-PUBLISH]]'
  - '[[CMS-CONTRACT]]'
---

# Publish Idempotency Test

## Executive Summary

The publish pipeline updated the same canonical catalog record when the same
BU/project/slug was republished, and an exact repeat kept the same idempotency
key.

\`\`\`text
first publish
   |
   v
one catalog record
   |
   v
republish edited raw.md -> same article_id, new raw_hash/idempotency_key
   |
   v
republish same raw.md -> same idempotency_key, no duplicate record
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Catalog record includes canonical_key | PASS |
| Catalog record includes idempotency_key | PASS |
| Edited republish kept the same article_id | PASS |
| Edited republish kept one catalog record | PASS |
| Edited republish updated raw_hash | PASS |
| Edited republish updated idempotency_key | PASS |
| Home, search, BU, project, and article outputs were regenerated | PASS |
| Exact republish kept the same idempotency_key | PASS |
| Fake git push guard was not triggered | PASS |
| Fake gh guard was not triggered | PASS |

## Images Analyzed

0
EOF
