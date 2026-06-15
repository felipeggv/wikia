#!/usr/bin/env python3
"""
theme_resolver.py — decide qual stylesheet alimenta {{STYLES_CSS}}.

Tema padrão: 'everytool' (estilo editorial Maestro). Para voltar ao tema
mono clássico, exporte WIKIA_THEME=classic antes de buildar/publicar.

O EverTool é um OVERLAY: o _styles.css.tpl clássico (chassi + base) é sempre
carregado primeiro; quando o tema é everytool, concatena-se o overlay
_everytool-styles.css.tpl por cima (mesmas classes, conteúdo re-vestido).
Assim o chassi (topbar/sidebar/drawer/busca) nunca quebra — invariante 1.
"""
import os
from pathlib import Path

_CLASSIC_ALIASES = {'classic', 'wikia', 'mono', 'legacy', 'off'}


def active_theme():
    return os.environ.get('WIKIA_THEME', 'everytool').strip().lower()


def serif_enabled():
    """True quando o tema ativo usa a fonte serifada (Newsreader)."""
    return active_theme() not in _CLASSIC_ALIASES


def resolve_styles(templates_dir, theme_vars_css):
    """Retorna o CSS completo para {{STYLES_CSS}}, honrando WIKIA_THEME."""
    templates_dir = Path(templates_dir)
    base = (templates_dir / '_styles.css.tpl').read_text().replace('{{THEME_VARS}}', theme_vars_css)
    if not serif_enabled():
        return base
    overlay_path = templates_dir / '_everytool-styles.css.tpl'
    if not overlay_path.exists():
        return base
    overlay = overlay_path.read_text().replace('{{THEME_VARS}}', theme_vars_css)
    return base + "\n\n/* ===== EVERTOOL THEME OVERLAY ===== */\n" + overlay
