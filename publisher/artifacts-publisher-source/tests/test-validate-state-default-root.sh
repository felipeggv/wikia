#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${WIKIA_TEST_SOURCE_ROOT:-$(cd "$TEST_DIR/.." && pwd)}"
APP_ROOT="$(cd "$SOURCE_ROOT/../.." && pwd)"
VALIDATE_SCRIPT="${SOURCE_ROOT}/scripts/validate-state.sh"
TMP_PARENT="${WIKIA_TEST_TMP_PARENT:-$APP_ROOT/.tmp/wikia-tests/validate-state-default-root-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$VALIDATE_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

DEFAULT_JSON="${RUN_DIR}/default.json"
set +e
bash "$VALIDATE_SCRIPT" --json > "$DEFAULT_JSON" 2> "${RUN_DIR}/default.err"
DEFAULT_STATUS=$?
set -e

python3 - "$DEFAULT_JSON" "$SOURCE_ROOT" "$DEFAULT_STATUS" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
source_root = Path(sys.argv[2]).resolve()
expected = (source_root / "../.." / "docs" / "gitpages").resolve()
if Path(payload.get("public_root", "")).resolve() != expected:
    raise SystemExit(f"default public root mismatch: {payload.get('public_root')} != {expected}")
if int(sys.argv[3]) not in (0, 1):
    raise SystemExit(f"unexpected validator exit status: {sys.argv[3]}")
PY

OVERRIDE_ROOT="${RUN_DIR}/override-public"
mkdir -p "$OVERRIDE_ROOT"
OVERRIDE_JSON="${RUN_DIR}/override.json"
bash "$VALIDATE_SCRIPT" --public-root "$OVERRIDE_ROOT" --json > "$OVERRIDE_JSON"
python3 - "$OVERRIDE_JSON" "$OVERRIDE_ROOT" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
expected = Path(sys.argv[2]).resolve()
if Path(payload.get("public_root", "")).resolve() != expected:
    raise SystemExit(f"override public root mismatch: {payload.get('public_root')} != {expected}")
if payload.get("ok") is not True or payload.get("issue_count") != 0:
    raise SystemExit(f"override clean root should pass: {payload}")
PY

cat <<EOF
---
type: report
title: Validate State Default Root Test
created: $(date +%F)
tags:
  - wikia-cms
  - validation
  - default-root
related:
  - '[[PHASE-07-VALIDATION]]'
  - '[[CMS-CONTRACT]]'
---

# Validate State Default Root Test

## Executive Summary

The state validator resolves its default public root to this app worktree's
\`docs/gitpages\`, while \`--public-root\` still overrides the target.

\`\`\`text
validate-state.sh
   |
   +-- default: worktree/docs/gitpages
   +-- override: caller-provided public root
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Default root points at current worktree \`docs/gitpages\` | PASS |
| \`--public-root\` override is honored | PASS |
| Empty override root passes validation | PASS |

## Images Analyzed

0
EOF
