#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FALLBACK="$SKILL_DIR/references/theme-fallback.json"
if command -v maestro-cli >/dev/null 2>&1; then
  if json=$(maestro-cli settings get customThemeColors 2>/dev/null); then
    echo "$json"; exit 0
  fi
fi
cat "$FALLBACK"
