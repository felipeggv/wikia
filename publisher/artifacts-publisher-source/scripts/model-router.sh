#!/usr/bin/env bash
# model-router.sh — roteia tarefa pra Claude/Codex/Gemini
# Uso: bash model-router.sh <model> <task-name> <prompt-file>
# Output (stdout): resposta do modelo
# Log: references/model-routing.log

set -euo pipefail
MODEL="${1:-}"; TASK="${2:-}"; PROMPT_FILE="${3:-}"
[ -z "$MODEL" ] || [ -z "$TASK" ] || [ -z "$PROMPT_FILE" ] && { echo "Usage: model-router.sh <model> <task-name> <prompt-file>" >&2; exit 1; }
[ ! -f "$PROMPT_FILE" ] && { echo "ERR: prompt file not found" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG="$SKILL_DIR/references/model-routing.log"
mkdir -p "$(dirname "$LOG")"

PROMPT=$(cat "$PROMPT_FILE")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_TS=$(date +%s)

run_with_timeout() {
  local cmd_pid
  ( "$@" ) &
  cmd_pid=$!
  ( sleep 120; kill -9 $cmd_pid 2>/dev/null ) &
  local sleep_pid=$!
  wait $cmd_pid 2>/dev/null
  local rc=$?
  kill -9 $sleep_pid 2>/dev/null
  wait $sleep_pid 2>/dev/null
  return $rc
}

case "$MODEL" in
  codex)
    if ! command -v codex >/dev/null 2>&1; then echo "ERR: codex CLI not found" >&2; exit 1; fi
    OUTPUT=$(echo "$PROMPT" | codex exec --skip-git-repo-check - 2>/dev/null || true)
    ;;
  gemini)
    if ! command -v gemini >/dev/null 2>&1; then echo "ERR: gemini CLI not found" >&2; exit 1; fi
    OUTPUT=$(gemini -p "$PROMPT" 2>/dev/null || true)
    ;;
  claude)
    if ! command -v claude >/dev/null 2>&1; then echo "ERR: claude CLI not found" >&2; exit 1; fi
    OUTPUT=$(echo "$PROMPT" | claude -p - 2>/dev/null || true)
    ;;
  *)
    echo "ERR: unknown model '$MODEL' (use: claude|codex|gemini)" >&2
    exit 1
    ;;
esac

END_TS=$(date +%s)
DURATION=$((END_TS - START_TS))
CHARS=${#OUTPUT}

echo "[$TIMESTAMP] model=$MODEL task=$TASK duration=${DURATION}s output_chars=$CHARS" >> "$LOG"

echo "$OUTPUT"
