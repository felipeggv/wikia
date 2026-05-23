---
name: artifacts-publisher
description: "Publica artefatos em wikia — blog/wiki interno do Felipe Gobbi. Maestro dark green theme, 100% JetBrains Mono, Obsidian file-tree sidebar, layout centered com toggle compact/wide, AES-GCM gate cross-page, componentes pedagógicos (comparator/accordion-seq/mermaid-zoom/callout/playground), drawer lateral pra playgrounds interativos. Multi-tenant por BU em wave 2."
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Skill
---

## *help

**Title:** Artifacts Publisher — wikia
**Repo:** `felipeggv/wikia` (default; wave 2: roteia por BU)
**URL base:** `https://felipeggv.github.io/wikia/gitpages/`

**Usage:**
- `/global:skills:artifacts-publisher "<título>" --content <md> [flags]`
- `--full` invoca **visual-explainer** automaticamente
- `--enrich` adiciona Codex + Gemini routing

---

# Wikia — blog/wiki interno

## Filosofia

Blog interno em **GitHub Pages**, com gate AES, layout estilo Obsidian + Mintlify + Linear docs. Audiência: não-dev (estratégia, marketing, design). Tipografia Maestro real (100% JetBrains Mono, EM-based).

## Arquitetura

```
felipeggv/wikia (atual — wave 1)
  /docs/.nojekyll
  /docs/gitpages/
    index.html              ← chronological feed
    search.json             ← full-text index
    research/
      <tema>/
        artifacts/
          <slug>/
            index.html      ← gated AES-GCM
            raw.md          ← source

WAVE 2 (em desenvolvimento):
felipeggv/wikia-vitascience  ← BU: health
felipeggv/wikia-aleyemma     ← BU: marketing LATAM
felipeggv/wikia-case         ← BU: healthcare profs
felipeggv/wikia-personal     ← BU: pessoal
felipeggv/wikia              ← central admin (agrega todas)
```

## Layout 3-zonas

```
┌─ TOPBAR sticky 48px ──────────────────────────────────────┐
│ [☰] ■ wikia · knowledge  [⌘K Buscar]  [□ compact / ▭ wide]│
├──────────┬────────────────────────────────────────────────┤
│ SIDEBAR  │ CONTENT (centered, max-w 720 ou 960)           │
│ (Obsidian│                                                │
│  file-   │ Article com:                                   │
│  tree)   │ - Breadcrumb                                   │
│ 280 px   │ - Eyebrow + H1 + Lead                          │
│ ↔ 48 px  │ - Meta-row (date, tags)                        │
│ collap-  │ - Body (JetBrains Mono EM-based)               │
│ sável    │ - Componentes pedagógicos                      │
│          │ - Footer (tags clicáveis)                      │
└──────────┴────────────────────────────────────────────────┘
                                                       ┌─ DRAWER ─┐
                                                       │ playground│
                                                       │ (480px,   │
                                                       │  right)   │
                                                       └───────────┘
```

## Lifecycle architecture

**Princípio:** o chassi de navegação fica SEMPRE fora do gate cifrado. Só o conteúdo do artigo entra cifrado.

```
┌─ DOM at page load (antes do unlock) ─────────────────────────────┐
│                                                                  │
│  CHASSI (plaintext, visível desde o page load):                  │
│  ├── topbar (48px) — ⌘K, width toggle, theme                     │
│  ├── sidebar (280px ↔ 48px) — file-tree, collapse                │
│  └── appshell JS — width toggle, drawer, search, navegação       │
│                                                                  │
│  GATE (placeholder visível, ocupa #ap-content-mount):            │
│  └── form de senha + dica + AES-GCM unlock                       │
│                                                                  │
│  TEMPLATE CIFRADO (inerte, dentro de <template id="ap-content-tpl">): │
│  ├── breadcrumb                                                  │
│  ├── header (eyebrow + h1 + lead + meta-row)                     │
│  ├── content (body do artigo + componentes)                      │
│  └── footer (tags clicáveis + border-top)                        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │ password correct
                              ▼
┌─ DOM after unlock ───────────────────────────────────────────────┐
│                                                                  │
│  CHASSI (intocado — mesmo DOM, mesmo JS já rodando)              │
│                                                                  │
│  CONTENT (decifrado IN-PLACE, substitui #ap-content-mount):      │
│  └── breadcrumb + header + content + footer                      │
│                                                                  │
│  EVENTO: window.dispatchEvent(new Event('wikia:unlocked'))       │
│  → componentes async (mermaid) escutam e re-init                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Por quê:** se o chassi vai dentro do template cifrado, ele só existe DEPOIS da decifragem. Isso quebra:
- Width toggle (botões existem mas listener não tá registrado antes do unlock)
- Drawer (playground)
- Search (⌘K)
- Sidebar interativa
- Mermaid (mermaid.run() roda no page load, mas SVG-target não existe ainda)

**Regras de implementação:**

1. **Chassi fora do gate** — topbar + sidebar + appshell JS são renderizados direto no `<body>`, fora de qualquer `<template>`.
2. **Só content cifrado** — apenas breadcrumb + header + body + footer entram no `<template id="ap-content-tpl">` que vira o payload AES-GCM.
3. **Decifragem in-place** — gate substitui o conteúdo do `#ap-content-mount` no lugar, sem trocar a estrutura do chassi.
4. **Re-init via evento** — após decifrar, dispatchar `wikia:unlocked` no `window`. Componentes que precisam de DOM-target (mermaid, código highlight, etc) escutam o evento e re-rodam.

```javascript
// Pattern de re-init para componentes async
window.addEventListener('wikia:unlocked', () => {
  if (window.mermaid) {
    window.mermaid.run({ querySelector: '.ap-mermaid-zoom code.language-mermaid' });
  }
});
```

## Tipografia (Maestro real, extraída de app.asar)

```
Family: JetBrains Mono (única)
Body: 14px / weight 400 / line-height 1.7
Headings (todos color textMain, weight 600):
  h1: 1.5em (~21px) · article header: 1.7em
  h2: 1.3em (~18px)
  h3: 1.15em (~16px)
  h4: 1.05em (~15px)
UI/meta/pills: 10-11px uppercase tracking 0.1em
```

## Componentes pedagógicos

Cada componente passa pelo **filtro pedagógico**:
> Esse componente vai aumentar DRASTICAMENTE a absorção do leitor?

### `::: comparator` — contraste A/B/C

```
::: comparator
### Opção A
texto A com markdown completo
### Opção B
texto B
:::
```

### `::: accordion-seq` — progressive disclosure

```
::: accordion-seq
### Passo 1
conteúdo
### Passo 2
conteúdo
:::
```

### `::: mermaid-zoom` — diagrama explorável

Auto-injeta `config: flowchart: curve: linear` pra visual retinho. Suporta zoom (scroll), pan (drag), fullscreen.

```
::: mermaid-zoom
flowchart LR
    A --> B --> C
:::
```

### `::: callout` — destaque inline

Variants: `info | tip | warn | success | quote`. Cor automática via theme tokens.

```
::: callout tip Métrica-chave
LTV/CAC deve ser > 3 dentro de 18 meses.
:::
```

### `::: playground` — drawer lateral direito

Aparece como botão "abrir playground" no body. Click → abre drawer 480px à direita com HTML/JS puro.

```
::: playground Calculadora de Pricing
<input type="range" id="x" min="0" max="100" value="50">
<output id="y">50</output>
<script>
  document.getElementById('x').addEventListener('input', e => {
    document.getElementById('y').textContent = e.target.value * 2;
  });
</script>
:::
```

## Auth — wave 1 (atual)

Senha única do wiki via `sessionStorage` key `wikia-master-key`. Cross-page na mesma aba/sessão. Fechou a aba, desloga.

## Auth — wave 2 (multi-tenant BU)

```
Cada repo tem sua senha:
  WIKIA_PASS_VITASCIENCE=xxx
  WIKIA_PASS_ALEYEMMA=yyy
  WIKIA_PASS_CASE=zzz
  WIKIA_PASS_PERSONAL=aaa

Você (admin) tem:
  WIKIA_MASTER=master-pwd → destrava qualquer repo
```

Inferência da BU usa modelo do **project-registry.yaml** do Q-Processor:
1. Path do `--content` dentro de `BU-X/` → infere BU
2. `--bu vitascience` override explícito
3. Prompt se ambíguo

## Multi-model routing

| Modelo | CLI | Quando |
|--------|-----|--------|
| Claude | direto (Skill/Bash) | Texto criativo, decisões pedagógicas, HTML inline |
| Codex GPT-5.5 xhigh | `codex exec -p` | Tabelas formais, números, specs sérias |
| Gemini | `gemini -p` | Pesquisa web, validação de fatos |

`--enrich` ativa Codex + Gemini. Sem ela, só Claude.

## Visual-explainer integration

`--full` flag **obriga** o invoker (Claude no chat) a chamar `Skill('visual-explainer:generate-web-diagram', ...)` antes do publish. Output (SVG/HTML inline) é colado no markdown.

Critério: se o artigo tem ≥1 conceito visual (framework, fluxo, comparação) → invoca.

## Files

```
~/.claude/skills/artifacts-publisher/
├── SKILL.md                    ← este arquivo
├── components/
│   ├── comparator.html
│   ├── accordion-seq.html
│   └── mermaid-zoom.html
├── references/
│   └── theme-fallback.json
├── templates/
│   ├── _head.html.tpl
│   ├── _styles.css.tpl
│   ├── _topbar.html.tpl
│   ├── _sidebar.html.tpl
│   ├── _appshell.html.tpl
│   ├── artifact.html.tpl
│   ├── wiki-home.html.tpl
│   └── gate.html.tpl
└── scripts/
    ├── publish.sh              ← orquestrador
    ├── render-artifact.py
    ├── render-wiki.py
    ├── build-search-index.py
    ├── md-to-html.py           ← parser (suporta ::: blocks + HTML passthrough)
    ├── model-router.sh         ← claude/codex/gemini
    ├── gate.sh + encrypt.mjs   ← AES-256-GCM
    ├── theme-fetch.sh
    └── slugify.sh
```

## Estado de desenvolvimento

| Feature | Status |
|---|---|
| Maestro dark green palette | ✅ |
| JetBrains Mono EM-based | ✅ |
| Topbar 48px + ⌘K + width toggle | ✅ |
| Sidebar Obsidian file-tree (icons/indent) | ✅ |
| Content centered + drawer right | ✅ |
| AES-GCM gate cross-page por sessão (sessionStorage) | ✅ |
| HTML inline passthrough | ✅ |
| Componentes: comparator, accordion-seq, mermaid-zoom, callout, playground | ✅ |
| Mermaid auto-injeta curve: linear | ✅ |
| Multi-model routing (Claude/Codex/Gemini) | ✅ |
| Visual-explainer trigger no --full | ✅ |
| Multi-tenant por BU + master key | 🚧 wave 2 |
| Comentários anchor-based (Recogito + Cloudflare D1) | 🚧 wave 3 |
