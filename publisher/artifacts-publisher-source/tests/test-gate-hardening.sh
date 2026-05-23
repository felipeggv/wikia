#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${TEST_DIR}/.." && pwd)"
GATE_SCRIPT="${SOURCE_ROOT}/scripts/gate.sh"
STRIP_GATE_SCRIPT="${SOURCE_ROOT}/scripts/strip-gate.py"
TMP_PARENT="${SOURCE_ROOT}/tests/.tmp/gate-hardening-tests"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$GATE_SCRIPT"
require_file "$STRIP_GATE_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
cleanup() {
  rm -rf "$RUN_DIR"
  rmdir "$TMP_PARENT" "${SOURCE_ROOT}/tests/.tmp" 2>/dev/null || true
}
trap cleanup EXIT

SUCCESS_HTML="${RUN_DIR}/success.html"
cat > "$SUCCESS_HTML" <<'HTML'
<!doctype html>
<html>
  <body>
    <main>
      <template id="ap-content-tpl">
        <article>
          <h1>Secret Fixture</h1>
          <p>PRIVATE_BODY_MARKER_NEVER_PUBLIC</p>
          <template data-kind="nested">nested inert template</template>
        </article>
      </template>
      {{GATE_BLOCK}}
    </main>
  </body>
</html>
HTML

bash "$GATE_SCRIPT" "$SUCCESS_HTML" "fixture-password" "staging" >/dev/null

python3 - "$SUCCESS_HTML" <<'PY'
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "{{GATE_BLOCK}}": False,
    '<template id="ap-content-tpl">': False,
    "PRIVATE_BODY_MARKER_NEVER_PUBLIC": False,
    "sessionStorage.setItem": True,
    "sessionStorage.getItem": True,
    "localStorage.setItem": False,
    "localStorage.getItem": False,
}
for marker, should_exist in checks.items():
    present = marker in text
    if present != should_exist:
        state = "present" if present else "missing"
        raise SystemExit(f"unexpected gate output for {marker!r}: {state}")
PY

FAIL_HTML="${RUN_DIR}/failure.html"
cat > "$FAIL_HTML" <<'HTML'
<!doctype html>
<html>
  <body>
    <template id="ap-content-tpl">
      <article>
        <p>FAILURE_PRIVATE_BODY_MARKER</p>
      </article>
    </template>
    {{GATE_BLOCK}}
  </body>
</html>
HTML

REAL_NODE="$(command -v node)"
FAKE_BIN="${RUN_DIR}/bin"
mkdir -p "$FAKE_BIN"
cat > "${FAKE_BIN}/node" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == *"/encrypt-blob.mjs" ]]; then
  echo "fixture encrypt failure" >&2
  exit 91
fi

exec "$REAL_NODE" "$@"
SH
chmod +x "${FAKE_BIN}/node"

if REAL_NODE="$REAL_NODE" PATH="${FAKE_BIN}:$PATH" bash "$GATE_SCRIPT" "$FAIL_HTML" "fixture-password" "staging" \
  > "${RUN_DIR}/failure.out" 2> "${RUN_DIR}/failure.err"; then
  fail "gate.sh unexpectedly succeeded when encrypt-blob.mjs was forced to fail"
fi

if find "$RUN_DIR" -type f \( -name '*.plaintext.tmp' -o -name 'wikia-gate-plaintext.*' \) | grep -q .; then
  fail "gate.sh left a plaintext temp file inside the publish fixture after failure"
fi

ALREADY_GATED_HTML="${RUN_DIR}/already-gated.html"
cat > "$ALREADY_GATED_HTML" <<'HTML'
<!doctype html>
<html>
  <body>
    <main>
      <div class="ap-gate-wrap">
        <div id="ap-gate">
          <div class="ap-gate-card">locked</div>
        </div>
        <div id="ap-content-mount" style="display:none"></div>
      </div>
      <style>
        .ap-gate-wrap { display: block; }
        #ap-gate { display: flex; }
        .ap-gate-card { color: red; }
      </style>
      <script id="ap-gate-script">window.__fixtureGate = true;</script>
      <article>
        <h1>Released Fixture</h1>
        <p>RELEASED_BODY_MARKER</p>
      </article>
    </main>
  </body>
</html>
HTML

python3 "$STRIP_GATE_SCRIPT" "$ALREADY_GATED_HTML" >/dev/null

python3 - "$ALREADY_GATED_HTML" <<'PY'
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "ap-gate-wrap": False,
    "ap-gate-card": False,
    'id="ap-gate"': False,
    'id="ap-gate-script"': False,
    "RELEASED_BODY_MARKER": True,
}
for marker, should_exist in checks.items():
    present = marker in text
    if present != should_exist:
        state = "present" if present else "missing"
        raise SystemExit(f"unexpected strip-gate output for {marker!r}: {state}")
PY

cat <<EOF
---
type: report
title: Gate Hardening Test
created: $(date +%F)
tags:
  - wikia-cms
  - security
  - gate
related:
  - '[[Wikia Permission Contract Group Chat]]'
---

# Gate Hardening Test

## Executive Summary

The gate pipeline now keeps plaintext out of public output even on failure,
stores unlock state only in the current browser session, and strips stale gate
wrappers from already-gated release pages.

\`\`\`text
rendered article
   |
   +-- gate.sh success -> encrypted shell + session-only unlock
   +-- gate.sh failure -> no plaintext temp file left in publish output
   |
   v
strip-gate.py -> removes stale gate wrapper/style/script from released page
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Successful gate removed plaintext template content from public HTML | PASS |
| Gate shell uses \`sessionStorage\` instead of \`localStorage\` | PASS |
| Forced encryption failure did not leave plaintext temp files in output | PASS |
| \`strip-gate.py\` removed stale wrapper, CSS, and gate script | PASS |
| Released article body survived stale-wrapper stripping | PASS |

## Images Analyzed

0
EOF
