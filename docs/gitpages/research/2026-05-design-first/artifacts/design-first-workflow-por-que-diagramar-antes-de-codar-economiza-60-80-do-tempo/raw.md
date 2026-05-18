# Design-First Workflow: por que diagramar antes de codar economiza 60-80% do tempo

> Como parar de pedir código pra IA sem antes ter validado visualmente o sistema. Uma proposta de skill em 6 fases, com gates humanos entre cada uma, mockup HTML navegável antes de qualquer linha de produção, e integração nativa com ClickUp.

---

## O problema (sem rodeio)

Você descreve uma ideia pra IA. Ela cospe código. O código não funciona ou não é o que você queria. Você corrige. Ela cospe de novo. Você corrige de novo. **80% do seu tempo evapora nesse loop** porque o sistema nunca foi validado antes da implementação.

A causa raiz é simples: **quem não consegue ler código não consegue validar código**. Mas todo mundo consegue validar um **diagrama** e um **mockup navegável**. Logo, o gargalo não é a IA — é a etapa de design que foi pulada.

::: callout warn O sintoma clássico
"Pedi pra IA fazer X. Ela fez Y. Pedi de novo. Ela fez Z. Depois de 4 horas, voltei pro X mas torto." — esse loop não é falha da IA. É falha de **não ter validado o desenho antes de pedir código**.
:::

---

## O diagrama macro (cole na cabeça)

<div style="margin:32px 0;padding:24px;background:#0a0e0a;border:1px solid #1a3a1f;border-radius:4px;">
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 460" role="img" aria-label="Design-First Workflow em 6 fases com gates de validação humana" style="width:100%;height:auto;display:block;background:#0a0e0a;font-family:'JetBrains Mono',ui-monospace,monospace;">
  <defs>
    <marker id="df-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
      <path d="M0,0 L10,5 L0,10 z" fill="#5a7a5e"/>
    </marker>
    <pattern id="df-grid" width="40" height="40" patternUnits="userSpaceOnUse">
      <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#13201a" stroke-width="0.5"/>
    </pattern>
  </defs>
  <rect width="1280" height="460" fill="url(#df-grid)"/>
  <text x="40" y="42" fill="#c8d4c5" font-size="13" font-weight="600" letter-spacing="0.12em">DESIGN-FIRST WORKFLOW</text>
  <text x="40" y="60" fill="#5a7a5e" font-size="10" letter-spacing="0.18em">SIX PHASES · HUMAN GATES BETWEEN EACH</text>
  <line x1="40" y1="74" x2="1240" y2="74" stroke="#1a3a1f" stroke-width="1"/>
  <g transform="translate(40,110)">
    <rect width="180" height="220" fill="#0f1a12" stroke="#1a3a1f" stroke-width="1.5" rx="2"/>
    <rect x="0" y="0" width="180" height="28" fill="#1a3a1f"/>
    <text x="12" y="19" fill="#c8d4c5" font-size="10" font-weight="600" letter-spacing="0.15em">01 · DISCOVERY</text>
    <g transform="translate(72,46)" stroke="#7a9a7e" stroke-width="1.4" fill="none" stroke-linecap="square">
      <rect x="0" y="0" width="36" height="24" rx="1"/>
      <path d="M8 24 L8 30 L16 24"/>
      <line x1="6" y1="8" x2="30" y2="8"/>
      <line x1="6" y1="14" x2="22" y2="14"/>
    </g>
    <text x="90" y="100" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">Entrevista</text>
    <text x="90" y="116" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">estruturada</text>
    <line x1="20" y1="130" x2="160" y2="130" stroke="#1a3a1f" stroke-width="1"/>
    <text x="90" y="150" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› brief.md</text>
    <text x="90" y="166" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› assumptions</text>
    <text x="90" y="182" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› 5 perguntas-chave</text>
    <rect x="56" y="194" width="68" height="18" fill="#1a3a1f" rx="1"/>
    <text x="90" y="207" text-anchor="middle" fill="#c8d4c5" font-size="9" font-weight="600" letter-spacing="0.1em">30 MIN</text>
  </g>
  <g transform="translate(244,110)">
    <rect width="180" height="220" fill="#0f1a12" stroke="#1a3a1f" stroke-width="1.5" rx="2"/>
    <rect x="0" y="0" width="180" height="28" fill="#1a3a1f"/>
    <text x="12" y="19" fill="#c8d4c5" font-size="10" font-weight="600" letter-spacing="0.15em">02 · DIAGRAM</text>
    <g transform="translate(64,42)" stroke="#7a9a7e" stroke-width="1.4" fill="none" stroke-linecap="square">
      <rect x="0" y="6" width="14" height="10"/>
      <rect x="38" y="0" width="14" height="10"/>
      <rect x="38" y="20" width="14" height="10"/>
      <line x1="14" y1="11" x2="38" y2="5"/>
      <line x1="14" y1="11" x2="38" y2="25"/>
    </g>
    <text x="90" y="100" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">Mermaid</text>
    <text x="90" y="116" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">flowchart</text>
    <line x1="20" y1="130" x2="160" y2="130" stroke="#1a3a1f" stroke-width="1"/>
    <text x="90" y="150" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› iterativo</text>
    <text x="90" y="166" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› linear / step</text>
    <text x="90" y="182" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› humano edita</text>
    <rect x="56" y="194" width="68" height="18" fill="#1a3a1f" rx="1"/>
    <text x="90" y="207" text-anchor="middle" fill="#c8d4c5" font-size="9" font-weight="600" letter-spacing="0.1em">45 MIN</text>
  </g>
  <g transform="translate(448,110)">
    <rect width="180" height="220" fill="#0f1a12" stroke="#1a3a1f" stroke-width="1.5" rx="2"/>
    <rect x="0" y="0" width="180" height="28" fill="#1a3a1f"/>
    <text x="12" y="19" fill="#c8d4c5" font-size="10" font-weight="600" letter-spacing="0.15em">03 · MOCKUP</text>
    <g transform="translate(64,42)" stroke="#7a9a7e" stroke-width="1.4" fill="none" stroke-linecap="square">
      <rect x="0" y="0" width="52" height="36"/>
      <line x1="0" y1="8" x2="52" y2="8"/>
      <circle cx="5" cy="4" r="1"/>
      <circle cx="10" cy="4" r="1"/>
      <line x1="6" y1="16" x2="30" y2="16"/>
      <line x1="6" y1="22" x2="46" y2="22"/>
      <line x1="6" y1="28" x2="36" y2="28"/>
    </g>
    <text x="90" y="100" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">HTML</text>
    <text x="90" y="116" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">wireframe</text>
    <line x1="20" y1="130" x2="160" y2="130" stroke="#1a3a1f" stroke-width="1"/>
    <text x="90" y="150" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› GitHub Pages</text>
    <text x="90" y="166" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› navegável</text>
    <text x="90" y="182" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› feio de propósito</text>
    <rect x="56" y="194" width="68" height="18" fill="#1a3a1f" rx="1"/>
    <text x="90" y="207" text-anchor="middle" fill="#c8d4c5" font-size="9" font-weight="600" letter-spacing="0.1em">60 MIN</text>
  </g>
  <g transform="translate(652,110)">
    <rect width="180" height="220" fill="#0f1a12" stroke="#1a3a1f" stroke-width="1.5" rx="2"/>
    <rect x="0" y="0" width="180" height="28" fill="#1a3a1f"/>
    <text x="12" y="19" fill="#c8d4c5" font-size="10" font-weight="600" letter-spacing="0.15em">04 · DISSECT</text>
    <g transform="translate(64,42)" stroke="#7a9a7e" stroke-width="1.4" fill="none" stroke-linecap="square">
      <rect x="14" y="6" width="24" height="24"/>
      <line x1="0" y1="12" x2="14" y2="12"/>
      <line x1="0" y1="24" x2="14" y2="24"/>
      <line x1="38" y1="18" x2="52" y2="18"/>
      <line x1="20" y1="14" x2="32" y2="14"/>
      <line x1="20" y1="22" x2="32" y2="22"/>
    </g>
    <text x="90" y="100" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">Inputs / Outputs</text>
    <text x="90" y="116" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">Contratos</text>
    <line x1="20" y1="130" x2="160" y2="130" stroke="#1a3a1f" stroke-width="1"/>
    <text x="90" y="150" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› por bloco</text>
    <text x="90" y="166" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› stack + função</text>
    <text x="90" y="182" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› 5 campos max</text>
    <rect x="56" y="194" width="68" height="18" fill="#1a3a1f" rx="1"/>
    <text x="90" y="207" text-anchor="middle" fill="#c8d4c5" font-size="9" font-weight="600" letter-spacing="0.1em">30 MIN</text>
  </g>
  <g transform="translate(856,110)">
    <rect width="180" height="220" fill="#0f1a12" stroke="#1a3a1f" stroke-width="1.5" rx="2"/>
    <rect x="0" y="0" width="180" height="28" fill="#1a3a1f"/>
    <text x="12" y="19" fill="#c8d4c5" font-size="10" font-weight="600" letter-spacing="0.15em">05 · PLAN</text>
    <g transform="translate(68,42)" stroke="#7a9a7e" stroke-width="1.4" fill="none" stroke-linecap="square">
      <rect x="0" y="0" width="14" height="8"/>
      <line x1="7" y1="8" x2="7" y2="32"/>
      <line x1="7" y1="16" x2="20" y2="16"/>
      <line x1="7" y1="24" x2="20" y2="24"/>
      <line x1="7" y1="32" x2="20" y2="32"/>
      <rect x="20" y="12" width="14" height="8"/>
      <rect x="20" y="20" width="14" height="8"/>
      <rect x="20" y="28" width="14" height="8"/>
    </g>
    <text x="90" y="100" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">ClickUp</text>
    <text x="90" y="116" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">hierarquia</text>
    <line x1="20" y1="130" x2="160" y2="130" stroke="#1a3a1f" stroke-width="1"/>
    <text x="90" y="150" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› folder → lists</text>
    <text x="90" y="166" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› tasks → subs</text>
    <text x="90" y="182" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› specs no card</text>
    <rect x="56" y="194" width="68" height="18" fill="#1a3a1f" rx="1"/>
    <text x="90" y="207" text-anchor="middle" fill="#c8d4c5" font-size="9" font-weight="600" letter-spacing="0.1em">20 MIN</text>
  </g>
  <g transform="translate(1060,110)">
    <rect width="180" height="220" fill="#0f1a12" stroke="#3a5a3e" stroke-width="1.5" rx="2"/>
    <rect x="0" y="0" width="180" height="28" fill="#3a5a3e"/>
    <text x="12" y="19" fill="#0a0e0a" font-size="10" font-weight="600" letter-spacing="0.15em">06 · BUILD</text>
    <g transform="translate(64,42)" stroke="#a8c4ab" stroke-width="1.4" fill="none" stroke-linecap="square">
      <rect x="0" y="0" width="52" height="8"/>
      <rect x="0" y="12" width="52" height="8"/>
      <rect x="0" y="24" width="52" height="8"/>
      <line x1="6" y1="4" x2="10" y2="4"/>
      <line x1="6" y1="16" x2="10" y2="16"/>
      <line x1="6" y1="28" x2="10" y2="28"/>
    </g>
    <text x="90" y="100" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">Módulo</text>
    <text x="90" y="116" text-anchor="middle" fill="#c8d4c5" font-size="11" font-weight="600">a módulo</text>
    <line x1="20" y1="130" x2="160" y2="130" stroke="#1a3a1f" stroke-width="1"/>
    <text x="90" y="150" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› ARPB3 playbook</text>
    <text x="90" y="166" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› verify-as-you-go</text>
    <text x="90" y="182" text-anchor="middle" fill="#8aa68d" font-size="9" letter-spacing="0.08em">› commit por bloco</text>
    <rect x="50" y="194" width="80" height="18" fill="#3a5a3e" rx="1"/>
    <text x="90" y="207" text-anchor="middle" fill="#0a0e0a" font-size="9" font-weight="600" letter-spacing="0.1em">VARIÁVEL</text>
  </g>
  <g transform="translate(232,200)">
    <line x1="-12" y1="20" x2="0" y2="20" stroke="#5a7a5e" stroke-width="1.5"/>
    <line x1="20" y1="20" x2="32" y2="20" stroke="#5a7a5e" stroke-width="1.5" marker-end="url(#df-arrow)"/>
    <rect x="0" y="8" width="20" height="24" fill="#0a0e0a" stroke="#5a7a5e" stroke-width="1.2" rx="1"/>
    <text x="10" y="24" text-anchor="middle" fill="#a8c4ab" font-size="11" font-weight="600">✓</text>
    <text x="10" y="56" text-anchor="middle" fill="#5a7a5e" font-size="8" letter-spacing="0.1em">GATE</text>
  </g>
  <g transform="translate(436,200)">
    <line x1="-12" y1="20" x2="0" y2="20" stroke="#5a7a5e" stroke-width="1.5"/>
    <line x1="20" y1="20" x2="32" y2="20" stroke="#5a7a5e" stroke-width="1.5" marker-end="url(#df-arrow)"/>
    <rect x="0" y="8" width="20" height="24" fill="#0a0e0a" stroke="#5a7a5e" stroke-width="1.2" rx="1"/>
    <text x="10" y="24" text-anchor="middle" fill="#a8c4ab" font-size="11" font-weight="600">✓</text>
    <text x="10" y="56" text-anchor="middle" fill="#5a7a5e" font-size="8" letter-spacing="0.1em">GATE</text>
  </g>
  <g transform="translate(640,200)">
    <line x1="-12" y1="20" x2="0" y2="20" stroke="#5a7a5e" stroke-width="1.5"/>
    <line x1="20" y1="20" x2="32" y2="20" stroke="#5a7a5e" stroke-width="1.5" marker-end="url(#df-arrow)"/>
    <rect x="0" y="8" width="20" height="24" fill="#0a0e0a" stroke="#5a7a5e" stroke-width="1.2" rx="1"/>
    <text x="10" y="24" text-anchor="middle" fill="#a8c4ab" font-size="11" font-weight="600">✓</text>
    <text x="10" y="56" text-anchor="middle" fill="#5a7a5e" font-size="8" letter-spacing="0.1em">GATE</text>
  </g>
  <g transform="translate(844,200)">
    <line x1="-12" y1="20" x2="0" y2="20" stroke="#5a7a5e" stroke-width="1.5"/>
    <line x1="20" y1="20" x2="32" y2="20" stroke="#5a7a5e" stroke-width="1.5" marker-end="url(#df-arrow)"/>
    <rect x="0" y="8" width="20" height="24" fill="#0a0e0a" stroke="#5a7a5e" stroke-width="1.2" rx="1"/>
    <text x="10" y="24" text-anchor="middle" fill="#a8c4ab" font-size="11" font-weight="600">✓</text>
    <text x="10" y="56" text-anchor="middle" fill="#5a7a5e" font-size="8" letter-spacing="0.1em">GATE</text>
  </g>
  <g transform="translate(1048,200)">
    <line x1="-12" y1="20" x2="0" y2="20" stroke="#5a7a5e" stroke-width="1.5"/>
    <line x1="20" y1="20" x2="32" y2="20" stroke="#5a7a5e" stroke-width="1.5" marker-end="url(#df-arrow)"/>
    <rect x="0" y="8" width="20" height="24" fill="#0a0e0a" stroke="#5a7a5e" stroke-width="1.2" rx="1"/>
    <text x="10" y="24" text-anchor="middle" fill="#a8c4ab" font-size="11" font-weight="600">✓</text>
    <text x="10" y="56" text-anchor="middle" fill="#5a7a5e" font-size="8" letter-spacing="0.1em">GATE</text>
  </g>
  <line x1="40" y1="370" x2="1240" y2="370" stroke="#1a3a1f" stroke-width="1"/>
  <g transform="translate(40,390)">
    <rect x="0" y="0" width="12" height="12" fill="#1a3a1f" stroke="#5a7a5e" stroke-width="1"/>
    <text x="20" y="10" fill="#8aa68d" font-size="10" letter-spacing="0.08em">FASE · entregável + timebox</text>
  </g>
  <g transform="translate(280,390)">
    <rect x="0" y="0" width="12" height="12" fill="#0a0e0a" stroke="#5a7a5e" stroke-width="1"/>
    <text x="6" y="10" text-anchor="middle" fill="#a8c4ab" font-size="9" font-weight="600">✓</text>
    <text x="20" y="10" fill="#8aa68d" font-size="10" letter-spacing="0.08em">GATE · validação humana obrigatória</text>
  </g>
  <g transform="translate(580,390)">
    <line x1="0" y1="6" x2="24" y2="6" stroke="#5a7a5e" stroke-width="1.5" marker-end="url(#df-arrow)"/>
    <text x="32" y="10" fill="#8aa68d" font-size="10" letter-spacing="0.08em">linha reta · sem bezier · engineering-style</text>
  </g>
  <text x="1240" y="400" text-anchor="end" fill="#5a7a5e" font-size="9" letter-spacing="0.18em">DESIGN-FIRST · 6 FASES · GATES HUMANOS</text>
  <text x="40" y="430" fill="#3a5a3e" font-size="9" letter-spacing="0.2em">VIBEWORK · WIKIA · 2026-05</text>
</svg>
</div>

A leitura é simples: **6 caixas, 5 gates humanos entre elas**. Você só passa de uma fase pra próxima quando o gate diz "ok, validei, pode seguir". Sem gate aprovado = não avança. É isso que mata o loop de idas e vindas no código.

---

## Fase 01 · DISCOVERY — entrevista estruturada

### O que é

Você (humano) descreve a ideia. A IA (Claude) te entrevista com **5 perguntas-chave** até ter um brief sólido. Não é conversa livre — é um roteiro com critério de saída.

### Inputs

- Ideia inicial (1 parágrafo)
- Contexto de negócio (qual BU, qual dor)

### Processo

::: mermaid-zoom
flowchart LR
    A[Ideia bruta] --> B[P1 problema]
    B --> C[P2 usuario]
    C --> D[P3 sucesso]
    D --> E[P4 o que nao e]
    E --> F[P5 constraints]
    F --> G[brief.md]
    G --> H{Humano valida?}
    H -- nao --> B
    H -- sim --> I[Proxima fase]
:::

### Outputs

- `brief.md` (≤ 2 páginas)
- `assumptions.md` (lista de premissas que precisam ser validadas)
- Sinal de "go" do humano

### Gate de saída

::: callout success Critério de "good enough"
Felipe consegue explicar o sistema em voz alta pra outra pessoa em ≤ 60 segundos, **sem ler o brief**. Se não consegue, volta pra perguntas.
:::

### Timebox

**30 minutos**. Mais que isso, escopo está grande demais — quebra em 2 ciclos.

---

## Fase 02 · DIAGRAM — mermaid iterativo

### O que é

A IA gera um **flowchart Mermaid** representando o sistema. Você edita, refaz, comenta. Itera até bater com sua cabeça.

### Por que Mermaid e não Figma/Miro?

::: comparator
### Mermaid (escolha)
- Texto → diagrama (versionável em git)
- IA gera/edita direto
- Linear / step* renderiza limpo
- Free, embebível em wiki/ClickUp/markdown
- Humano edita texto, não arrasta caixinhas

### Figma / Miro
- Visual rico, mas IA não edita bem
- Drag-and-drop dá liberdade demais → caos
- Pago / lock-in
- Não versiona em git
- Bom pra arte final, ruim pra iteração rápida
:::

### Regra de ouro do mermaid aqui

Sempre usar `curve: linear` ou `step*` no header — nunca bezier. Visual de **engineering**, não de marketing.

```
---
config:
  flowchart:
    curve: linear      ← linhas retas diagonais
    # OU
    curve: stepBefore  ← cotovelo antes do nó (90°)
    # OU
    curve: stepAfter   ← cotovelo depois do nó (90°)
---
flowchart LR
    A --> B --> C
```

::: callout tip Quando usar cada um
**linear** = fluxos lineares simples · **stepBefore** = quando o destino é um agregador (vários entram, 1 sai) · **stepAfter** = quando a fonte é um distribuidor (1 sai, vários entram).
:::

### Outputs

- `system.mmd` (arquivo Mermaid)
- `system.svg` (render preview)

### Gate de saída

Felipe olha o diagrama e fala: **"é exatamente isso"**. Sem "quase", sem "tá perto". Se tem "quase", volta pra editar.

### Timebox

**45 minutos**. Iteração média: 3-4 ciclos.

---

## Fase 03 · MOCKUP — HTML wireframe navegável

### O que é

A IA gera um **mockup HTML estático**, com várias telas linkadas, hospedado no **GitHub Pages**. Você clica, navega, simula o uso. Tudo mocado — dados fake, botões que fingem funcionar.

### Por que HTML e não Figma?

Porque você quer **clicar e sentir o fluxo**, não só ver telas estáticas. HTML estático te dá navegação real com 1/10 do esforço de protótipo Figma.

### Como deve ser o mockup

::: callout warn Mockup feio é mockup que funciona
**Wireframe-style preto e branco**, zero CSS bonito. Função: validar fluxo, não vender. Se você começar a "deixar bonitinho", o mockup vira projeto paralelo e você nunca chega na próxima fase.
:::

### Anatomia do mockup

```
docs/
  index.html              ← tela inicial (entry point)
  dashboard.html          ← tela do meio
  detail.html             ← tela final
  shared/
    style.css             ← 30 linhas no MAX, preto/branco
    nav.js                ← navegação fake (alert/console)
  README.md               ← "este é um mockup, dados fake"
```

### Outputs

- URL pública no GitHub Pages (`https://<user>.github.io/<projeto>-mockup/`)
- Permite compartilhar com stakeholder pra validação externa

### Gate de saída

Felipe clica no mockup e consegue **executar a tarefa principal de ponta a ponta** sem precisar de explicação. Se trava em algum passo, esse passo precisa ser revisto no diagrama (volta pra fase 2).

### Timebox

**60 minutos**.

---

## Fase 04 · DISSECT — explodir cada bloco em specs

### O que é

Pega o diagrama validado (fase 2) e o mockup validado (fase 3) e **explode cada bloco** em uma spec curta de 5 campos:

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| **Inputs** | O que entra | `usuario_id`, `data_inicio` |
| **Processo** | O que faz | "Calcula agregação semanal de eventos" |
| **Outputs** | O que sai | `dict{semana: int, total: int}` |
| **Stack** | Onde roda | Python script no `apps/ingest/` |
| **Contrato** | Validação | `total >= 0`, schema JSON anexo |

::: callout warn Limite de 5 campos
Mais que isso vira documentação morta. A spec **vai dentro do card do ClickUp**, não em um doc separado. Se não cabe no card, está over-spec.
:::

### Fluxo de dissecação

::: mermaid-zoom
---
config:
  flowchart:
    curve: stepBefore
---
flowchart TD
    A[Diagrama validado] --> B[Pega bloco 1]
    A --> C[Pega bloco 2]
    A --> D[Pega bloco N]
    B --> E[5 campos de spec]
    C --> E
    D --> E
    E --> F[specs.yaml]
    F --> G{I/O claros?}
    G -- nao --> H[Refina ou volta]
    G -- sim --> I[Proxima fase]
:::

### Outputs

- `specs.yaml` (1 entrada por bloco do diagrama)
- `contracts.yaml` (schemas JSON de I/O quando aplicável)

### Gate de saída

Toda spec é executável: outra IA (ou outro humano) leria a spec e produziria código equivalente, **sem precisar perguntar nada**.

### Timebox

**30 minutos**.

---

## Fase 05 · PLAN — quebrar seguindo Workspace Topology

::: callout warn Regra inegociável
Esta fase **DEVE** seguir a skill `/workspace:skills:topology` rigorosamente. Naming kebab-strict, modelo 1-list-1-agent, áreas-como-folders, e mapping ClickUp×Maestro×Disco. Sem isso, o sistema todo cai.
:::

### Os 3 eixos (decora isso)

A topologia do workspace tem **3 eixos** que ficam sincronizados:

```
PLANNING (ClickUp)    EXECUTION (Maestro)    STORAGE (Disco)
─────────────────────────────────────────────────────────────
workspace        ←→   (nao tem)         ←→   (nao tem)
space            ←→   group             ←→   BU folder
folder           ←→   (nao tem)         ←→   projeto
list             ←→   agent             ←→   branch git
task             ←→   tab               ←→   commit
```

**Regra de Ouro:** `1 list = 1 branch = 1 agent = 1 cwd`. N tabs no agent = N tasks da MESMA list.

### Naming kebab-strict (zero CamelCase, zero underscore, zero espaço)

| Camada | Padrão | Exemplo VÁLIDO | Exemplo INVÁLIDO |
|---|---|---|---|
| Workspace cup | profile fixo | `gobbi` `allin` `vita` | `Gobbi` `all_in` |
| Space ClickUp | kebab puro | `automedia` `aleyemma` `vitascience` | `AutoMedia` |
| Maestro group | `{workspace}-{space}` | `gobbi-automedia` `gobbi-aleyemma` | `automedia` |
| Maestro group (exceção) | só workspace | `allin` `vita` | `allin-all-in` |
| Folder ClickUp | kebab puro | `coverage-module` `operacoes` | `[Área] Coverage` |
| List ClickUp | `{tipo}/{slug-kebab}` | `build/upload-api` `fix/webhook-bug` | `Feature: Upload` |
| Agent Maestro | `{projeto}-{sigla}` | `coverage-module-cc` | `coverage_cc` |
| Sigla agent | sufixo de modelo | `-cc` (Claude Code) `-cdx` (Codex) `-oc` (OpenCode) `-gem` (Gemini) | `-claude` |
| Tab name | `{nome-task} \| task {id}` | `implementar upload \| task 86abc` | `Tab 1` |
| Disco | `VibeworkV2/{tipo}/{bu}/{projeto}` | `VibeworkV2/apps/automedia/coverage-module` | `~/projetos/coverage` |

### Os 6 task types universais (cobrem dev E marketing)

::: comparator
### build
Construir algo **novo** que não existia.

**Dev:** "Implementar endpoint POST /upload"
**Marketing:** "Gravar vídeo SHIFT 90 ep1", "Criar landing nova"

### fix
Consertar algo **quebrado** (comportamento errado).

**Dev:** "Webhook duplicando", "Cron falhando"
**Marketing:** "Headline com erro de português", "CTA quebrado"

### improve
Melhorar **existente** sem trocar finalidade.

**Dev:** "Otimizar query lenta", "Atualizar react-router"
**Marketing:** "Re-editar copy pós A/B", "Limpar tags Mautic"

### run
Executar trabalho **recorrente** em cadência fixa.

**Dev:** "Backup semanal", "Deploy quinzenal"
**Marketing:** "Drenar inbox 9h", "Postar carrossel diário"

### decide
Escolher entre **opções concretas** com deliverable (ADR).

**Dev:** "Veo 3 vs Runware (ADR)"
**Marketing:** "Definir preço SHIFT 90"

### research
Entender **antes** de agir (spike, customer dev).

**Dev:** "Por que essa query está lenta?"
**Marketing:** "Analisar copy do concorrente Y"
:::

::: callout tip Anti-padrão — quando NÃO criar task
"Pensar sobre X" → comentário num doc · "Lembrar de fazer Y" → comentário em task existente · "Conversar com cliente X" → evento de calendário · "Estudar curso Y" → bookmark (só vira `research` se gerar resumo/ADR).

Se a "task" não tem **deliverable verificável** (commit, doc, asset publicado, ação executada), ela não é task — é nota.
:::

### Hierarquia ClickUp pra design-first (exemplo concreto)

Suponha que o projeto cobaia se chame `lead-scoring` e mora no BU `vitascience`:

```
Workspace cup:   vita
Space ClickUp:   vitascience
Maestro group:   vita                       (excecao: space=workspace)
Folder ClickUp:  lead-scoring                (kebab puro, sem [Area])
  |
  +-- List: build/score-engine               (bloco 1 do diagrama)
  |   +-- Task type: build
  |   +-- Tasks:
  |       - "Implementar score-engine core"
  |           +-- Subtask: "Schema de input"
  |           +-- Subtask: "Funcao principal"
  |           +-- Subtask: "Testes"
  |       - "Documentar score-engine"
  |       - "Deploy score-engine"
  |
  +-- List: build/lead-ingestion             (bloco 2 do diagrama)
  |   +-- Tasks de tipo build...
  |
  +-- List: build/score-export               (bloco 3 do diagrama)
  |   +-- Tasks de tipo build...
  |
  +-- List: research/scoring-models          (estudo pre-build)
  +-- List: run/sync-leads-daily             (rotina pos-build)
```

**Mapping cross-axis:**

| ClickUp list | Maestro agent | Disco branch | Disco path |
|---|---|---|---|
| `build/score-engine` | `score-engine-cc` | `build/score-engine` | `VibeworkV2/apps/vitascience/score-engine/` |
| `build/lead-ingestion` | `lead-ingestion-cc` | `build/lead-ingestion` | `VibeworkV2/apps/vitascience/lead-ingestion/` |
| `build/score-export` | `score-export-cc` | `build/score-export` | `VibeworkV2/apps/vitascience/score-export/` |

---

### Branching Strategy — a Regra de Ouro do Paralelismo

::: callout warn Lei fundamental (decora isso)
```
REGRA 1 (sempre):
  1 list = 1 branch propria
  1 list = 1 agent = 1 cwd
  N tabs no agent = N tasks da MESMA list

REGRA 2 (condicional):
  trabalho SEQUENCIAL entre lists  ->  git checkout
  trabalho PARALELO entre lists    ->  git worktree add
                                       (1 worktree por list ativa simultanea)
```
Worktree **NÃO é antipattern** — é pré-requisito físico do paralelismo (git proíbe 2 branches checkoutadas no mesmo cwd). Antipattern é worktree-por-task dentro da MESMA list (use tabs do agent pra isso).
:::

### Decision tree de branching

::: mermaid-zoom
flowchart TD
    A[Vou comecar trabalho novo] --> B{1 frente ou N frentes simultaneas?}
    B -- 1 frente --> C[git checkout tipo/slug]
    C --> D[Trabalha, commita, PR, merge]
    D --> E[Proxima list: git checkout outra]

    B -- N frentes --> F[git worktree add por frente]
    F --> G[1 cwd separado por list]
    G --> H[1 agent Maestro por worktree]

    A --> I{Espiar outra branch 5 min?}
    I -- sim --> J[git stash + checkout + checkout volta + stash pop]
    J --> K[NAO cria worktree por isso]

    F --> L{2 frentes tocam o MESMO arquivo?}
    L -- sim --> M[NAO paraleliza]
    M --> N[Cria blocked-by no ClickUp]
    N --> O[B espera A mergear, B rebase, B continua]
    L -- nao --> H
:::

### Tabela de decisões rápidas

| Quero... | Faço... |
|---|---|
| Trabalhar em 1 list por vez (sequencial) | `git checkout {tipo}/{slug}` no projeto principal |
| Trabalhar em 2+ lists em paralelo | 1 worktree por list ativa: `git worktree add ../worktrees/{projeto}-{tipo}-{slug}` |
| Trabalhar em 2 tasks da MESMA list | 2 tabs no MESMO agent (mesma branch, mesma worktree) |
| Espiar outra branch rapidinho (5 min) | `git stash` → `checkout` → volta → `stash pop` (não cria worktree) |
| Mesma list em N branches diferentes | ❌ Anti-padrão. Cria outra list. |
| Worktree por task dentro da mesma list | ❌ Anti-padrão. Use tabs do agent. |

### Naming convention de branches e worktrees

```
LIST CLICKUP                          BRANCH GIT                            WORKTREE PATH
=============================         =============================         ===========================================
build/drccd-decision-engine           build/drccd-decision-engine           apps/worktrees/unbloq-build-drccd-decision-engine
build/review-loop                     build/review-loop                     apps/worktrees/unbloq-build-review-loop
fix/handoff-payload-validation        fix/handoff-payload-validation        apps/worktrees/unbloq-fix-handoff-payload-validation
improve/cleanup-logs                  improve/cleanup-logs                  apps/worktrees/coverage-module-improve-cleanup-logs

REGRA cristalizada:
  nome da list  =  nome da branch  =  {projeto}-{nome-da-list} no worktree path
  tudo kebab-case
  tipo (build/fix/improve/run/decide/research) faz parte do nome
  ZERO sufixo de agent no nome (-cc, -cdx ficam so no Maestro agent_name)
```

### Comandos nativos git (zero dependência de stack nova)

::: accordion-seq
### Criar worktree + branch nova de uma vez (caso comum)
```bash
cd VibeworkV2/apps/{projeto}
git worktree add ../worktrees/{projeto}-{tipo}-{slug} -b {tipo}/{slug}
```

### Criar worktree em branch que JÁ existe
```bash
git worktree add ../worktrees/{projeto}-{tipo}-{slug} {tipo}/{slug}
```

### Listar todas worktrees ativas
```bash
git worktree list
# saída exemplo:
# /VibeworkV2/apps/unbloq                            abc1234 [main]
# /VibeworkV2/apps/worktrees/unbloq-build-review     def5678 [build/review-loop]
# /VibeworkV2/apps/worktrees/unbloq-build-connect    ghi9012 [build/connectors]
```

### Sincronizar worktree com main (rebase ou merge)
```bash
cd ../worktrees/{projeto}-{tipo}-{slug}
git fetch origin
git rebase origin/main      # historico linear (preferido)
# OU
git merge origin/main       # merge commit
```

### Cleanup após PR mergeado
```bash
cd VibeworkV2/apps/{projeto}
git worktree remove ../worktrees/{projeto}-{tipo}-{slug}
git branch -d {tipo}/{slug}                    # branch local
git push origin --delete {tipo}/{slug}         # branch remote
# E remover entry do project-registry.yaml.clickup_lists
```
:::

### Política de merge entre worktrees paralelas

```
ORDEM DE MERGE = ORDEM DE DONE NO CLICKUP

  list 1 vai pra DONE  -> PR aberto -> merge em main
  list 2 vai pra DONE  -> rebase contra main atualizado -> PR -> merge
  list 3 vai pra DONE  -> rebase -> PR -> merge

REGRA DE CONFLITO:
  se 2 frentes paralelas vao mexer no MESMO arquivo:
  1. NAO paraleliza
  2. cria dependency no ClickUp (custom field "blocked-by")
  3. segunda frente espera primeira mergear
  4. segunda frente faz rebase
  5. continua o trabalho

Worktree NAO resolve conflito semantico — so permite ter 2 cwds.
Coordenacao humana ainda e necessaria.
```

### Resumo em 5 linhas (cole na cabeça)

::: callout success Branching strategy compacta
1. Toda list tem branch própria. ← lei (princípio 1)
2. Sequencial: `git checkout` resolve. ← simples, zero overhead
3. Paralelo: worktree obrigatório. ← física do git
4. Comandos: git nativo já basta. ← zero stack nova
5. Naming: list = branch = worktree. ← rastreabilidade 1:1
:::

### Por que ClickUp e não Jira/Notion?

Você já tem **sistema rodando** no ClickUp (`cup` CLI, custom fields, `ia_session_id`, attribution multi-tab, `project-registry.yaml` como fonte de verdade do mapping). Reaproveita.

### Fluxo automatizado da fase

::: accordion-seq
### Passo 1 · Detecta workspace + space
Lê path do `--content` pra inferir BU. Mapeia para profile `cup` correto (`gobbi`, `allin`, `vita`). Confirma via `~/.config/cup/config.json`.

### Passo 2 · Cria folder (kebab puro, sem decoração)
```bash
cup -p vita folder create vitascience lead-scoring
```
Nome do folder = nome do projeto, kebab puro. Sem `[Área]`, sem CamelCase, sem espaço.

### Passo 3 · Cria 1 list por bloco do diagrama
Pra cada bloco em `specs.yaml`, cria list com prefixo de tipo:
```bash
cup -p vita list create <folder_id> build/score-engine
cup -p vita list create <folder_id> build/lead-ingestion
```
Tipo padrão é `build` quando bloco gera algo novo. Use `improve` se bloco modifica existente, `fix` se bloco corrige bug, etc.

### Passo 4 · Cria tasks com os 6 task types
Pra cada list, cria 3 tasks padrão:
- 1 task `build` (implementar)
- 1 task `improve` (documentar — refina o existente)
- 1 task `run` (deploy — se for recorrente) ou `build` (se one-shot)

Spec do bloco vai na description da task "Implementar".

### Passo 5 · Cria subtasks com I/O da spec
Cada campo de spec.yaml (Schema input, Função principal, Testes) vira subtask.

### Passo 6 · Cria agent Maestro 1:1 com cada list
```bash
maestro-cli agent create score-engine-cc \
  --group vita \
  --cwd VibeworkV2/apps/vitascience/score-engine \
  --type claude-code
```
Sigla `-cc` = Claude Code (padrão). Sigla `-cdx` se for Codex, `-gem` se Gemini.

### Passo 7 · Cria branch git que espelha a list
```bash
cd VibeworkV2/apps/vitascience/score-engine
git checkout -b build/score-engine
```
Nome da branch = nome da list. Se paralelo, usa worktree:
```bash
git worktree add ../../worktrees/score-engine-build-score-engine build/score-engine
```

### Passo 8 · Registra mapping no project-registry.yaml
```yaml
projects:
  lead-scoring:
    bu: vitascience
    cup_workspace: vita
    clickup_space_id: <id>
    clickup_folder_id: <id>
    clickup_lists:
      - id: <list_id>
        name: build/score-engine
        agent: score-engine-cc
        branch: build/score-engine
        cwd: VibeworkV2/apps/vitascience/score-engine
```

### Passo 9 · Popula custom fields
Pra cada task: `ia_session_id` (CSV de tabs), `priority`, `estimate`.

### Passo 10 · Comenta hierarquia no folder
Posta comentário-resumo no folder com:
- Link pro diagrama validado (fase 2)
- Link pro mockup HTML (fase 3)
- Lista de blocos → lists → agents
- ASCII tree completo da hierarquia
:::

### Outputs

- Folder ClickUp pronto pra execução (kebab puro)
- N lists no formato `{tipo}/{slug-kebab}`
- N agents Maestro no formato `{projeto}-{sigla}`
- N branches git no formato `{tipo}/{slug-kebab}`
- N folders de disco em `VibeworkV2/{tipo}/{bu}/{projeto}/`
- `project-registry.yaml` atualizado com mapping cross-axis
- Comentário no folder com ASCII tree completo

### Validação obrigatória (checklist topology)

::: callout warn Antes de fechar a fase
- [ ] Workspace cup é um dos 3 fixos (`gobbi` / `allin` / `vita`)?
- [ ] Space é kebab-strict, sem acento, sem maiúscula?
- [ ] Maestro group segue `{workspace}-{space}` (ou excecão `allin`/`vita`)?
- [ ] Folder ClickUp é kebab puro (sem `[Área]`, sem espaço)?
- [ ] Toda list tem prefixo de tipo (`build/`, `fix/`, `improve/`, `run/`, `decide/`, `research/`)?
- [ ] Todo agent tem sufixo de modelo (`-cc`, `-cdx`, `-oc`, `-gem`)?
- [ ] cwd de cada agent aponta pra `VibeworkV2/{apps|services|tools|packages}/{bu}/{projeto}`?
- [ ] `project-registry.yaml` tem o mapping completo das 3 colunas (ClickUp / Maestro / Disco)?

Se qualquer item falha → **bloqueia**, volta pra fase 04 (dissect), refina, tenta de novo.
:::

### Gate de saída

Você abre o folder no ClickUp e vê **a hierarquia inteira em ASCII tree**. Cada list tem agent Maestro pareado. Cada agent tem cwd válido. `project-registry.yaml` tem mapping completo. Tudo kebab-strict.

### Timebox

**20 minutos** (90% automação via `cup`, `maestro-cli`, `git`).

---

## Fase 06 · BUILD — módulo a módulo

### O que é

Agora sim, **código de produção**. Cada task do ClickUp vira um Auto Run Playbook v3 (ARPB3). Você executa um bloco por vez.

### Por que módulo a módulo?

Porque cada módulo já tem:
- Diagrama validado (fase 2)
- Mockup que prova o fluxo (fase 3)
- Spec clara com I/O (fase 4)
- Task no ClickUp pra trackear (fase 5)

Quando a IA codar, **não tem ambiguidade**. Os erros caem 60-80%.

### Loop de execução

::: mermaid-zoom
flowchart LR
    A[Task ClickUp] --> B[Le spec]
    B --> C[Gera ARPB3]
    C --> D[Executa playbook]
    D --> E{Testes passam?}
    E -- nao --> F[Debug bloco isolado]
    F --> D
    E -- sim --> G[Commit]
    G --> H[Task to Done]
    H --> I[Proximo modulo]
:::

### Gate de saída

Cada módulo é **independentemente verificável**. Testes passam, commit feito, task fechada. Sem "vou consertar depois".

### Timebox

**Variável** — depende do escopo. Mas cada módulo individual deve ser ≤ 2h.

---

## Quanto isso economiza? (calculadora interativa)

::: playground Calculadora de economia design-first
<div style="font-family: 'JetBrains Mono', monospace; padding: 16px;">
  <p style="margin-bottom:16px;">Mexe nos sliders pra ver o impacto:</p>

  <label style="display:block; margin:12px 0;">
    <strong>Horas estimadas do projeto (sem design-first):</strong>
    <span id="dfp-base-val" style="float:right; font-weight:600;">40</span>h
    <input type="range" id="dfp-base" min="8" max="200" value="40" step="4" style="width:100%; margin-top:4px;">
  </label>

  <label style="display:block; margin:12px 0;">
    <strong>% do tempo perdido em idas e vindas hoje:</strong>
    <span id="dfp-loss-val" style="float:right; font-weight:600;">70</span>%
    <input type="range" id="dfp-loss" min="20" max="90" value="70" step="5" style="width:100%; margin-top:4px;">
  </label>

  <label style="display:block; margin:12px 0;">
    <strong>Eficácia do design-first (estimada):</strong>
    <span id="dfp-eff-val" style="float:right; font-weight:600;">75</span>%
    <input type="range" id="dfp-eff" min="40" max="90" value="75" step="5" style="width:100%; margin-top:4px;">
  </label>

  <div style="margin-top:24px; padding:16px; background:#0f1a12; border:1px solid #1a3a1f; border-radius:4px;">
    <div style="margin-bottom:8px;">Sem design-first: <strong id="dfp-without">40h</strong></div>
    <div style="margin-bottom:8px;">Investimento em fases 1-5: <strong id="dfp-design">~3h</strong></div>
    <div style="margin-bottom:8px;">Build (fase 6) reduzido: <strong id="dfp-build">~12h</strong></div>
    <div style="margin-top:12px; padding-top:12px; border-top:1px solid #1a3a1f;">
      <strong>Total com design-first: <span id="dfp-total">15h</span></strong>
      <br><strong style="color:#7aa07f;">Economia: <span id="dfp-saved">25h (62%)</span></strong>
    </div>
  </div>

  <script>
    (function() {
      function update() {
        const base = parseInt(document.getElementById('dfp-base').value);
        const loss = parseInt(document.getElementById('dfp-loss').value);
        const eff = parseInt(document.getElementById('dfp-eff').value);

        document.getElementById('dfp-base-val').textContent = base;
        document.getElementById('dfp-loss-val').textContent = loss;
        document.getElementById('dfp-eff-val').textContent = eff;

        const wasted = base * (loss / 100);
        const productive = base - wasted;
        const saved = wasted * (eff / 100);
        const designTime = 3;
        const newBuild = productive + (wasted - saved);
        const total = designTime + newBuild;
        const reduction = ((base - total) / base * 100);

        document.getElementById('dfp-without').textContent = base + 'h';
        document.getElementById('dfp-design').textContent = '~' + designTime + 'h';
        document.getElementById('dfp-build').textContent = '~' + newBuild.toFixed(1) + 'h';
        document.getElementById('dfp-total').textContent = total.toFixed(1) + 'h';
        document.getElementById('dfp-saved').textContent = (base - total).toFixed(1) + 'h (' + reduction.toFixed(0) + '%)';
      }
      document.getElementById('dfp-base').addEventListener('input', update);
      document.getElementById('dfp-loss').addEventListener('input', update);
      document.getElementById('dfp-eff').addEventListener('input', update);
      update();
    })();
  </script>
</div>
:::

---

## Benchmark de mercado — tem algo igual?

Não. Existem peças parecidas, mas nenhuma empacotada pra um marketer não-dev.

| Framework | O que tem em comum | O que falta pra esse workflow |
|-----------|--------------------|-------------------------------|
| **Shape Up (Basecamp)** | Pitch + fat marker sketch antes de codar | Sem mockup interativo, sem IA, sem quebra em tasks |
| **C4 Model (Simon Brown)** | Diagramação em 4 níveis (contexto → código) | Estático, sem validação interativa, sem mockup |
| **Design Sprint (Google)** | 5 dias estruturados (entender → prototipar → testar) | Foco UX, não arquitetura de sistema |
| **BMAD-METHOD** | Roles PO/Architect/Dev/QA | Sem etapa visual obrigatória antes de codar |
| **Spec-Driven Development** | Specs formais antes do código | Sem mockup, sem validação visual |

**Diferencial real:** a fase 3 (**mockup HTML navegável em GitHub Pages**) antes de qualquer linha de código de produção. Isso não existe empacotado em lugar nenhum.

---

## As 3 armadilhas que vão te morder

::: callout warn Armadilha 1 · Paralisia por diagramação
Você vai querer refinar o diagrama eternamente porque "sempre dá pra melhorar".

**Mitigação:** timebox brutal (45min máx) + critério explícito de saída ("eu consigo explicar em voz alta em 60s").
:::

::: callout warn Armadilha 2 · Mockup vira projeto paralelo
Você começa a estilizar, deixar bonito, adicionar features, e o mockup nunca termina.

**Mitigação:** template wireframe **feio de propósito** (CSS de 30 linhas, preto e branco). Função é validar fluxo, não vender.
:::

::: callout warn Armadilha 3 · Dissecação vira documentação morta
Você gera 50 specs detalhadas, ninguém lê durante o dev.

**Mitigação:** spec **dentro do card do ClickUp** (não em doc separado). Limite de 5 campos por bloco. Se não cabe no card, está over-spec.
:::

---

## Mapa de reaproveitamento (skills/agents já existentes)

Você **não precisa construir do zero**. O workspace já tem 80% das peças:

| Fase | Peça existente | Função |
|------|---------------|--------|
| 01 Discovery | `aios:agents:analyst` | Entrevista estruturada |
| 02 Diagram | `aios:agents:architect` | Geração de diagrama |
| 03 Mockup | `visual-explainer:generate-visual-plan` + `artifacts-publisher` | HTML wireframe + deploy GitHub Pages |
| 04 Dissect | `aios:agents:po` | Geração de specs |
| 05 Plan | `ClickUp-PM` + `global:skills:clickup-manager` | Hierarquia ClickUp |
| 06 Build | `ARPB3` (autorun-playbook-v3) | Execução com gates |

::: callout success Custo estimado de construção
- Skill do zero (full custom): **2 semanas**, risco alto
- **Orquestração das peças existentes: 2-3 dias**, risco baixo ← recomendado
- Workflow doc + checklist manual: **2 horas**, risco médio

**Sweet spot:** orquestrar o que já existe.
:::

---

## Como invocar (proposta de UX)

```bash
# Inicia um novo projeto design-first
/design-first start "Sistema de scoring de leads vitascience"

# Continua de onde parou
/design-first resume <slug>

# Pula direto pra fase X (se já tem material)
/design-first phase 4 --diagram system.mmd --mockup-url https://...

# Status
/design-first status
```

A skill é **uma orquestradora** — ela invoca os agents/skills certos em cada fase, mantém estado em arquivo local, e gera os artefatos.

---

## Próximos passos

::: accordion-seq
### Passo 1 · Validar este artigo
Você lê. Diz o que falta, o que sobra, o que está confuso.

### Passo 2 · Escolher cobaia
Pegamos um projeto real (pequeno) pra ser a primeira execução do workflow. Skill testada em projeto real fica 10x melhor que skill criada no vácuo.

### Passo 3 · Criar card ClickUp
Folder dedicado à skill design-first. List "Build skill". Tasks por fase.

### Passo 4 · Construir orquestrador (2-3 dias)
Skill `design-first` que chama os 6 agents/skills existentes na sequência certa.

### Passo 5 · Executar cobaia
Rodar o workflow completo no projeto cobaia. Documentar fricções.

### Passo 6 · Iterar a skill
Ajustar baseado na execução real. Publicar v1.0.
:::

---

## Decisão pendente

Antes de construir, 4 escolhas:

| # | Decisão | Recomendação |
|---|---------|--------------|
| 1 | **Escopo da skill** | Orquestradora completa (6 fases) |
| 2 | **Localização** | Global (`~/.claude/skills/design-first/`) |
| 3 | **Integração ClickUp** | Automática ao final da fase 5 |
| 4 | **Template mockup** | Wireframe puro (preto/branco, zero CSS bonito) |

::: callout tip Resposta curta
**Vale construir.** Vai economizar 60-80% do tempo de idas e vindas porque você valida o sistema *antes* de pedir uma linha de código. Comece pela orquestração das peças existentes — não construa nada do zero antes da primeira cobaia.
:::

---

## Apêndice · Mermaid presets pra esse workflow

```
---
config:
  flowchart:
    curve: linear       ← fluxo sequencial simples (use 80% das vezes)
    curve: stepBefore   ← cotovelo ANTES do nó destino (agregadores)
    curve: stepAfter    ← cotovelo DEPOIS do nó origem (distribuidores)
---
```

**Nunca** use `basis` ou `cardinal` aqui — esses são bezier suave, visual de marketing. Engenharia merece linha reta.
