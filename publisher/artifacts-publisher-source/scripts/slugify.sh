#!/usr/bin/env bash
set -euo pipefail
INPUT="${1:-}"
[ -z "$INPUT" ] && { echo "ERR: slugify requires arg" >&2; exit 1; }
ICONV_OUT=$(echo "$INPUT" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null; true)
if [ -z "$ICONV_OUT" ]; then ICONV_OUT="$INPUT"; fi
echo "$ICONV_OUT" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g; s/-{2,}/-/g'
