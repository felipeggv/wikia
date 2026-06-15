---
name: artifacts-publisher
description: "Publica artigos na Wikia como CMS, usando private-source como fonte privada, catalogo unico como estado canonico, docs/gitpages como saida gerada para GitHub Pages, admin criptografado, navegacao por BU/projeto/artigo, validacao de estado e gate AES-GCM por sessao."
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
- Fonte de verdade: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/private-source/{bu}/{project}/{slug}/raw.md`
- Publisher: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/publisher/artifacts-publisher-source/scripts/publish.sh`
- Saida publica gerada: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/docs/gitpages`
- URL base: `https://felipeggv.github.io/wikia/gitpages/`

---

# Wikia — blog/wiki interno

## Filosofia

Wikia e um CMS estatico: o usuario escreve fontes privadas, o publisher gera catalogo/admin/search/paginas, e o GitHub Pages serve apenas o resultado. Nao trate `docs/gitpages` como editor manual. Analogia: `private-source` e o estoque, o catalogo e o ERP, `docs/gitpages` e a vitrine.

## Regras duras

1. Nunca commitar `private-source/**`.
2. Nunca editar HTML gerado como fonte de verdade.
3. Nunca hardcodar arvore de navegacao em pagina gerada.
4. Admin, busca, sidebar, BU pages, project pages e article pages devem sair do mesmo catalogo.
5. Sempre validar antes de push/deploy.
6. Nunca passar masterpass em texto claro no argumento; use stdin, arquivo local seguro ou `WIKIA_MASTERPASS`.

## Arquitetura

```
private-source/{bu}/{project}/{slug}/raw.md
   |
   v
publish.sh + sync-cms-state.py + public_catalog.py
   |
   +-- docs/gitpages/_catalog.json
   +-- docs/gitpages/_admin.enc
   +-- docs/gitpages/_passwords.enc
   +-- docs/gitpages/search.json
   +-- docs/gitpages/{bu}/index.html
   +-- docs/gitpages/{bu}/{project}/index.html
   +-- docs/gitpages/{bu}/{project}/{slug}/index.html
   |
   v
https://felipeggv.github.io/wikia/gitpages/
```

Modelo de agrupamento:

| Nivel | Origem | Saida |
|---|---|---|
| BU | `bu` no frontmatter/path | `/gitpages/{bu}/` |
| Projeto | `project` no frontmatter/path | `/gitpages/{bu}/{project}/` |
| Artigo | `slug` no frontmatter/path | `/gitpages/{bu}/{project}/{slug}/` |
| Recencia | `updated`/mtime/catalogo | home, search e recents |
| Permissao | `gate_status`, `release_status`, `scope` | gate, admin e navegacao |

Frontmatter minimo:

```markdown
---
title: "Titulo do artigo"
bu: gobbi
project: skills
slug: design-first-dev-workflow
tags:
  - workflow
  - design
gate: article
# Optional: show the article in BU/project indexes while content stays gated.
discoverable: true
scope: bu
---
```

Use `discoverable: true` only when the title/tags can appear publicly as a locked item. Keep it absent for fully hidden private articles.

Comando de validacao para novo artigo:

```bash
cd /Users/felipegobbi/Documents/VibeworkV2/apps/wikia
bash publisher/artifacts-publisher-source/scripts/publish.sh \
  --title "Titulo do artigo" \
  --content /Users/felipegobbi/Documents/VibeworkV2/apps/wikia/private-source/gobbi/skills/design-first-dev-workflow/raw.md \
  --bu gobbi \
  --project skills \
  --slug design-first-dev-workflow \
  --private-source-root /Users/felipegobbi/Documents/VibeworkV2/apps/wikia/private-source \
  --validate
```

Comando de publicacao controlada:

```bash
cd /Users/felipegobbi/Documents/VibeworkV2/apps/wikia
bash publisher/artifacts-publisher-source/scripts/publish.sh \
  --title "Titulo do artigo" \
  --content /Users/felipegobbi/Documents/VibeworkV2/apps/wikia/private-source/gobbi/skills/design-first-dev-workflow/raw.md \
  --bu gobbi \
  --project skills \
  --slug design-first-dev-workflow \
  --private-source-root /Users/felipegobbi/Documents/VibeworkV2/apps/wikia/private-source
```

Comando para aplicar mudancas pendentes do admin:

```bash
cd /Users/felipegobbi/Documents/VibeworkV2/apps/wikia
printf '%s' "$WIKIA_MASTERPASS" | bash publisher/artifacts-publisher-source/scripts/publish.sh \
  --title "(apply-pending)" \
  --rebuild-all \
  --apply-pending \
  --private-source-root /Users/felipegobbi/Documents/VibeworkV2/apps/wikia/private-source \
  --masterpass -
```

Validacao final do estado publico:

```bash
cd /Users/felipegobbi/Documents/VibeworkV2/apps/wikia
bash publisher/artifacts-publisher-source/scripts/validate-state.sh \
  --public-root docs/gitpages \
  --json
```

## Auditoria obrigatoria de artigo publicado

Publicacao so esta pronta quando a rota, o catalogo, o Admin e a navegacao
contam a mesma historia. Nao aceite "o HTML foi gerado" como conclusao.

```
private-source raw.md
   |
   v
_catalog.json + _admin.enc + _passwords.enc
   |
   v
admin, sidebar, busca, BU/project pages, article page
```

Checklist minimo depois de criar ou reconstruir artigo:

1. Confirmar que `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/docs/gitpages/_catalog.json` contem `bu/project/slug`.
2. Confirmar que `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/docs/gitpages/{bu}/{project}/{slug}/index.html` existe.
3. Confirmar que o Admin lista o artigo mesmo quando `_admin.enc` estiver atrasado; o Admin deve mesclar `_admin.enc` com `_catalog.json`.
4. Confirmar que o botao do Admin abre a URL do artigo e, quando houver senha no vault, injeta a senha correta em `sessionStorage` antes de navegar.
5. Rodar:

```bash
cd /Users/felipegobbi/Documents/VibeworkV2/apps/wikia
bash publisher/artifacts-publisher-source/tests/test-admin-list-from-admin-metadata.sh
bash publisher/artifacts-publisher-source/scripts/validate-state.sh --public-root docs/gitpages --json
```

Causa raiz do incidente Aleyemma: o artigo podia existir na rota e no catalogo,
mas a UI Admin antiga dependia demais do metadata criptografado. Quando
`_admin.enc` ficava atrasado apos publish pontual, o artigo recem-catalogado
nao aparecia no Admin. A regra correta e: `_admin.enc` e fonte privada rica,
`_catalog.json` e fallback publico seguro para existencia/rota.

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

## Tema EverTool (PADRÃO desde 2026-06)

Estilo editorial (inspirado em Every.to / Context Window), na identidade Maestro.
É o tema **padrão** de artigos e homes. Ativado automaticamente; sem flag.

```
Serif (Newsreader) → display: título, dek, subhead serifado, citação, kb
Mono (JetBrains)   → funcional: corpo, meta, labels, números, código
Verde (--success)  → ÚNICO destaque (categorias, links, números). Zero azul/ciano.
Filetes tracejados, números tabulares grandes, footer mínimo.
```

**Arquitetura (overlay, não-destrutiva):**
- `templates/_everytool-styles.css.tpl` — overlay aplicado POR CIMA do `_styles.css.tpl`.
  Re-veste as classes que o parser já emite (`.wk-article`, `.wk-lead`, `.ap-callout`,
  `.ap-key-stats`…) para o visual `.et-*`. Mesmo chassi → conteúdo editorial.
- `scripts/theme_resolver.py` — decide o stylesheet. Os 5 renderers chamam
  `resolve_styles(templates_dir, theme_vars)`.
- Todos os tokens `--et-*` DERIVAM da injeção de tema (`var(--success)`, `var(--accent)`,
  `var(--text-main)`…) — nenhum hex novo. Invariante de tema preservada.
- Newsreader carregada no `_head.html.tpl`.

**Toggle (escape hatch):** `export WIKIA_THEME=classic` antes de publicar/rebuildar
volta ao tema mono clássico (preservado). Default = `everytool`.

**Trocar o site inteiro para o tema atual:**
```bash
WIKIA_THEME=everytool ./scripts/publish.sh --rebuild-all   # + masterpass via stdin/env
```

### Blocos novos do EverTool (parser `:::`)

```
::: tldr           → resumo serifado de 1-2 frases
::: takeaways      → checklist verde (pontos-chave)
::: steps          → passo-a-passo com numerais serifados grandes
::: deflist        → term: valor (manifesto/spec)
::: kb             → lista de base de conhecimento (links + categoria)
```
(`::: key-stat`, `comparator`, `accordion-seq`, `callout`, `mermaid-zoom`, `playground`
continuam válidos — re-vestidos no visual EverTool.)

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

## Auth e escopo

```
article scope  -> so o artigo atual aparece no unlock publico
project scope  -> artigos do mesmo projeto aparecem no contexto autorizado
BU scope       -> artigos da mesma BU aparecem no contexto autorizado
public release -> artigo sem gate, indexado em busca publica
admin          -> painel criptografado em _admin.enc, nunca navegacao publica
```

O unlock publico usa `sessionStorage`, nao `localStorage`. O admin so monta lista de artigos depois de decryptar `_admin.enc`; antes disso a tela mostra apenas shell bloqueado.

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
publisher/artifacts-publisher-source/
├── SKILL.md                    ← este arquivo
├── components/
│   └── componentes pedagogicos
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
    ├── sync-cms-state.py       ← catalogo + admin metadata
    ├── public_catalog.py       ← regra unica de visibilidade
    ├── validate-state.sh       ← invariantes de saida publica
    ├── render-artifact.py
    ├── render-wiki.py
    ├── render-bu.py
    ├── render-project.py
    ├── render-admin.py
    ├── build-search-index.py
    ├── md-to-html.py           ← parser (suporta ::: blocks + HTML passthrough)
    ├── gate.sh + encrypt.mjs   ← AES-GCM
    ├── vault.mjs               ← vault criptografado
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
| Multi-tenant por BU/projeto/artigo | ✅ |
| Catalogo unico para home/search/sidebar/admin | ✅ |
| Admin bloqueado antes do unlock | ✅ |
| Publish validation antes de push | ✅ |
| Pending changes via admin + rebuild-all | ✅ |
| Comentários anchor-based (Recogito + Cloudflare D1) | 🚧 wave 3 |
