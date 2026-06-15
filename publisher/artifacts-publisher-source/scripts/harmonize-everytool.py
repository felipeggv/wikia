#!/usr/bin/env python3
"""
harmonize-everytool.py — harmoniza HTML inline legado à paleta EverTool.

Artigos antigos foram escritos com <div style="..."> de cores próprias
(verde-água, azul, branco puro, bordas sólidas). Este pós-processador troca
SÓ os valores de cor/estilo inline para o vocabulário EverTool — preservando
texto, números, estrutura e imagens base64 byte a byte.

Regras:
  · verde-água  #2fb380 → #bed78e  (verde-limão, destaque EverTool)
  · azul        #3b9ae1 → #5b675b  (accent neutro — EverTool proíbe azul)
  · roxo        #a06ee1 → #5b675b  (frio → accent)
  · rosa        #e0556e → #d0a795  (salmão warning EverTool)
  · branco puro #fff/#ffffff → #f2f2c0  (creme — texto EverTool)
  · bordas sólidas claras → tracejado quente (filete editorial)
  · fundos branco-sutil → surface esverdeado sutil

Uso: harmonize-everytool.py <arquivo.md|html> [--write]
     sem --write: imprime um resumo das substituições (dry-run)
"""
import sys
import re

# (padrão, substituto, rótulo)  — ordem importa (mais específico primeiro)
RULES = [
    # cores hex (o '#' nunca aparece em base64, então é seguro)
    (r'#2fb380', '#bed78e', 'verde-água→verde-limão'),
    (r'#3b9ae1', '#5b675b', 'azul→accent'),
    (r'#a06ee1', '#5b675b', 'roxo→accent'),
    (r'#e0556e', '#d0a795', 'rosa→salmão'),
    (r'#ffffff\b', '#f2f2c0', 'branco→creme'),
    (r'#fff\b', '#f2f2c0', 'branco→creme'),
    # bordas sólidas claras → tracejado quente EverTool
    (r'border:1px solid rgba\(255,255,255,\.08\)',
     'border:1px dashed rgba(242,242,192,.15)', 'borda→dashed'),
    (r'border-left:4px solid', 'border-left:2px solid', 'barra 4px→2px'),
    # fundos branco-sutil → surface esverdeado sutil
    (r'background:rgba\(255,255,255,\.0[26]\)',
     'background:rgba(190,215,142,.03)', 'fundo branco→surface'),
    (r'rgba\(255,255,255,\.08\)', 'rgba(242,242,192,.15)', 'linha clara→quente'),
    (r'rgba\(255,255,255,\.0[56]\)', 'rgba(242,242,192,.10)', 'linha clara→quente'),
]


def protect_base64(text):
    """Tira os blobs data:image de cena pra não tocar neles."""
    blobs = []
    def stash(m):
        blobs.append(m.group(0))
        return f'\x00B64_{len(blobs)-1}\x00'
    text = re.sub(r'data:image/[^"\')]+', stash, text)
    return text, blobs


def restore_base64(text, blobs):
    for i, b in enumerate(blobs):
        text = text.replace(f'\x00B64_{i}\x00', b)
    return text


def harmonize(text):
    text, blobs = protect_base64(text)
    counts = {}
    for pat, repl, label in RULES:
        text, n = re.subn(pat, repl, text)
        if n:
            counts[label] = counts.get(label, 0) + n
    text = restore_base64(text, blobs)
    return text, counts


def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    path = sys.argv[1]
    write = '--write' in sys.argv
    src = open(path, encoding='utf-8').read()
    out, counts = harmonize(src)
    total = sum(counts.values())
    for label, n in counts.items():
        print(f"  {label:28} {n}")
    print(f"  {'TOTAL substituições':28} {total}")
    if write:
        open(path, 'w', encoding='utf-8').write(out)
        print(f"\n✓ escrito: {path}")
    else:
        print("\n(dry-run — use --write para aplicar)")


if __name__ == '__main__':
    main()
