#!/usr/bin/env bash
# gate.sh — aplica AES-GCM gate no HTML (substitui {{GATE_BLOCK}})
# Uso: gate.sh <html-file> <password> [bu-slug]
# bu-slug é opcional. Quando setado, isola o localStorage de unlock por BU
# (impede que senha de um artigo destrave artigos de outras BUs).
set -euo pipefail
HTML_FILE="${1:-}"; PASSWORD="${2:-}"; BU_SLUG="${3:-wiki}"
[ -z "$HTML_FILE" ] || [ -z "$PASSWORD" ] && { echo "Usage: gate.sh <html-file> <password> [bu-slug]" >&2; exit 1; }
[ ! -f "$HTML_FILE" ] && { echo "ERR: $HTML_FILE not found" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GATE_TPL="$SKILL_DIR/templates/gate.html.tpl"

# Pipeline corrigida (PG-03): extract-template (balance-scan) → encrypt-blob.
# Razão: encrypt.mjs original usa regex non-greedy /<template id="ap-content-tpl">([\s\S]*?)<\/template>/
# que para no PRIMEIRO </template>, truncando conteúdo quando há <template> aninhado
# (ex: playground inert). extract-template.mjs faz balance-scan e devolve o
# conteúdo correto; encrypt-blob.mjs criptografa o plaintext já extraído.
PLAINTEXT_FILE="${HTML_FILE}.plaintext.tmp"
node "$SCRIPT_DIR/extract-template.mjs" "$HTML_FILE" "$PLAINTEXT_FILE"
ENCRYPTED_JSON=$(node "$SCRIPT_DIR/encrypt-blob.mjs" "$PLAINTEXT_FILE" "$HTML_FILE" "$PASSWORD")
rm -f "$PLAINTEXT_FILE"

python3 - "$HTML_FILE" "$GATE_TPL" "$ENCRYPTED_JSON" "$BU_SLUG" <<'PYEOF'
import sys, json
html_path, tpl_path, enc_json, bu_slug = sys.argv[1:]
data = json.loads(enc_json)
with open(tpl_path) as f: gate_tpl = f.read()
gate = (gate_tpl
  .replace('{{ENCRYPTED_PAYLOAD}}', data['payload'])
  .replace('{{SALT}}', data['salt'])
  .replace('{{IV}}', data['iv'])
  .replace('{{SLUG}}', data.get('slug', 'artifact'))
  .replace('{{REPO_NAME}}', data.get('repo', 'vibework-knowledge'))
  .replace('{{BU_SLUG}}', bu_slug)
)
with open(html_path) as f: html = f.read()
html = html.replace('{{GATE_BLOCK}}', gate)
with open(html_path, 'w') as f: f.write(html)
print(f'Gate applied: {html_path} (BU={bu_slug})', file=sys.stderr)
PYEOF
