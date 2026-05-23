#!/usr/bin/env node
// extract-template.mjs — extrai conteúdo de <template id="ap-content-tpl"> via
// balance-scan (respeita <template> aninhados, ex: playground inert templates).
//
// Uso:
//   node extract-template.mjs <html-file> <plaintext-out-file>
//     - Lê <html-file>, encontra o template outer "ap-content-tpl"
//     - Faz scan balanceado de <template>/</template> até depth voltar a 0
//     - Escreve o conteúdo extraído em <plaintext-out-file>
//     - Re-escreve <html-file> sem o bloco <template id="ap-content-tpl">...</template>
//
// Por que existe (em vez de usar regex non-greedy):
//   /<template id="ap-content-tpl">([\s\S]*?)<\/template>/ pega o PRIMEIRO
//   </template>, que pode ser de um <template> aninhado (playground). Isso
//   trunca o conteúdo, deixa tag órfã no plaintext e perde o footer do artigo.
//
// Trade-off: parser de string simples (não DOM). Suficiente porque:
//   - Não temos <template> dentro de strings (atributos, comentários) no nosso
//     gerador (md-to-html.py + render-artifact.py)
//   - Balance-scan é O(n) no tamanho do HTML

import { readFileSync, writeFileSync } from 'fs';

const [, , htmlPath, outPath] = process.argv;
if (!htmlPath || !outPath) {
  console.error('Usage: extract-template.mjs <html-file> <plaintext-out-file>');
  process.exit(1);
}

const html = readFileSync(htmlPath, 'utf8');

const OPEN_MARKER = '<template id="ap-content-tpl">';
const startIdx = html.indexOf(OPEN_MARKER);
if (startIdx === -1) {
  console.error('ERR: no <template id="ap-content-tpl">');
  process.exit(1);
}
const contentStart = startIdx + OPEN_MARKER.length;

// Walk forward, counting nested <template ...> opens and </template> closes.
const OPEN_TAG = /<template(?:\s[^>]*)?>/gi;
const CLOSE_TAG = /<\/template\s*>/gi;

let depth = 1;
let pos = contentStart;
let closeStart = -1;
let closeEnd = -1;

while (depth > 0) {
  OPEN_TAG.lastIndex = pos;
  CLOSE_TAG.lastIndex = pos;
  const o = OPEN_TAG.exec(html);
  const c = CLOSE_TAG.exec(html);

  if (!c) {
    console.error('ERR: unbalanced <template> (no matching </template>)');
    process.exit(1);
  }

  if (o && o.index < c.index) {
    depth++;
    pos = o.index + o[0].length;
  } else {
    depth--;
    if (depth === 0) {
      closeStart = c.index;
      closeEnd = c.index + c[0].length;
    }
    pos = c.index + c[0].length;
  }
}

const content = html.slice(contentStart, closeStart);
const newHtml = html.slice(0, startIdx) + html.slice(closeEnd);

writeFileSync(outPath, content);
writeFileSync(htmlPath, newHtml);

console.error(`extract-template: extracted ${content.length} bytes; html now ${newHtml.length} bytes`);
