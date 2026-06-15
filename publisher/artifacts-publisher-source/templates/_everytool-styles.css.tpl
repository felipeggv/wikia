/* =========================================================================
   EVERTOOL — overlay de tema editorial para a wikia
   Estilo "Every.to / Context Window" na identidade Maestro.
   Aplicado POR CIMA de _styles.css.tpl (mesmo chassi, conteúdo re-vestido).

   Princípios:
     · Serif (Newsreader) = display  · Mono (JetBrains) = funcional
     · Verde (--success / #bed78e) = ÚNICO destaque. Zero azul/ciano.
     · Filetes tracejados, números tabulares, sem footer gigante.

   Todos os tokens DERIVAM da injeção de tema do chassi (var(--success),
   var(--accent), var(--text-main)…) — nenhum hex novo hard-coded.
   Invariante 5 (tema por placeholder) preservada.
   ========================================================================= */

:root {
  /* fontes */
  --et-serif: "Newsreader", Georgia, "Times New Roman", serif;
  --et-mono: var(--font);

  /* cores derivadas do tema injetado */
  --et-text: var(--text-main);
  --et-body: var(--text-dim);
  --et-green: var(--success);
  --et-accent: var(--accent);
  --et-warn: var(--warning);

  --et-meta: color-mix(in oklab, var(--text-dim) 80%, var(--bg-main));
  --et-dim:  color-mix(in oklab, var(--text-dim) 55%, var(--bg-main));
  --et-surface:   color-mix(in oklab, var(--bg-activity) 70%, var(--bg-main));
  --et-surface-2: var(--bg-activity);

  --et-dash: color-mix(in oklab, var(--text-main) 15%, transparent);
  --et-line: color-mix(in oklab, var(--text-main) 9%,  transparent);
  --et-green-soft: color-mix(in oklab, var(--success) 12%, transparent);
  --et-warn-soft:  color-mix(in oklab, var(--warning) 12%, transparent);
}

/* seleção em verde */
.wk-article ::selection { background: var(--et-green); color: #0c1206; }

/* =========================================================================
   CABEÇALHO DO ARTIGO  (eyebrow → kicker · h1 → serif · lead → serif)
   ========================================================================= */
.wk-article-header {
  border-bottom: none;
  margin-bottom: var(--s-6);
}
.wk-article .wk-eyebrow {
  font-family: var(--et-mono);
  font-size: 11px; font-weight: 600;
  letter-spacing: 0.18em; text-transform: uppercase;
  color: var(--et-green);
}
.wk-article-header h1 {
  font-family: var(--et-serif);
  font-weight: 500;
  font-size: clamp(34px, 5vw, 54px);
  line-height: 1.05; letter-spacing: -0.02em;
  color: var(--et-text);
  text-wrap: balance;
  margin: var(--s-3) 0 var(--s-4);
}
.wk-article .wk-lead {
  font-family: var(--et-serif);
  font-weight: 400;
  font-size: clamp(19px, 2.3vw, 23px);
  line-height: 1.45; color: var(--et-meta);
  text-wrap: pretty;
  margin: 0 0 var(--s-5);
}
.wk-article .wk-meta-row {
  border-top: 1px dashed var(--et-dash);
  border-bottom: 1px dashed var(--et-dash);
  padding: var(--s-3) 0;
  font-family: var(--et-mono);
  font-size: 11px; letter-spacing: 0.06em; text-transform: uppercase;
  color: var(--et-dim);
  font-variant-numeric: tabular-nums;
}
.wk-article .wk-meta-row .dot { color: var(--et-dash); }
.wk-article .wk-meta-row .tag {
  border: 1px dashed var(--et-dash); border-radius: 999px;
  color: var(--et-meta); text-transform: uppercase;
}
.wk-article .wk-meta-row .tag:hover {
  border-color: var(--et-green); border-style: solid; color: var(--et-text);
}

/* breadcrumb */
.wk-article .wk-breadcrumb {
  font-family: var(--et-mono); font-size: 11px;
  letter-spacing: 0.06em; color: var(--et-dim);
}
.wk-article .wk-breadcrumb a:hover { color: var(--et-green); }

/* =========================================================================
   CORPO  (mono) — headings de seção, prosa, listas, código, citação, tabela
   ========================================================================= */
.wk-article h1 {
  font-family: var(--et-serif);
  font-weight: 500;
  font-size: clamp(30px, 4vw, 44px);
  line-height: 1.08; letter-spacing: -0.02em;
  color: var(--et-text); text-wrap: balance;
  margin: var(--s-7) 0 var(--s-4);
}
.wk-article h2 {
  font-family: var(--et-mono);
  font-weight: 600; font-size: 13px;
  letter-spacing: 0.16em; text-transform: uppercase;
  color: var(--et-green);
  margin: var(--s-8) 0 var(--s-2);
  padding-bottom: var(--s-2);
  border-bottom: 1px dashed var(--et-dash);
}
.wk-article h3 {
  font-family: var(--et-serif);
  font-weight: 600; font-size: 25px;
  line-height: 1.25; letter-spacing: -0.01em;
  color: var(--et-text); text-wrap: balance;
  margin: var(--s-6) 0 var(--s-3);
}
.wk-article h4 {
  font-family: var(--et-mono);
  font-weight: 600; font-size: 12px; letter-spacing: 0.1em;
  text-transform: uppercase; color: var(--et-meta);
  margin: var(--s-5) 0 var(--s-2);
}
.wk-article p { color: var(--et-body); text-wrap: pretty; }
.wk-article li { color: var(--et-body); }
.wk-article li::marker { color: var(--et-green); }
.wk-article a {
  color: var(--et-green);
  text-decoration: underline;
  text-decoration-color: color-mix(in oklab, var(--success) 45%, transparent);
  text-underline-offset: 3px; text-decoration-thickness: 1px;
}
.wk-article a:hover { text-decoration-color: var(--et-green); color: var(--et-green); }
.wk-article strong { color: var(--et-text); font-weight: 600; }
.wk-article em { font-style: italic; color: var(--et-meta); }
.wk-article hr { border-top: 1px dashed var(--et-dash); }

.wk-article code {
  font-family: var(--et-mono); font-size: 0.82em;
  background: var(--et-surface);
  border: 1px dashed var(--et-dash);
  border-radius: 3px; color: var(--et-text);
}
.wk-article pre {
  font-family: var(--et-mono);
  background: var(--et-surface);
  border: 1px dashed var(--et-dash);
  border-left: 2px solid var(--et-accent);
  border-radius: 6px;
}
.wk-article pre code { border: none; background: transparent; }

/* citação → pull-quote serifada com barra verde */
.wk-article blockquote {
  font-family: var(--et-serif); font-style: italic;
  font-size: clamp(21px, 2.6vw, 27px); line-height: 1.32;
  color: var(--et-text); text-wrap: balance;
  border-left: 2px solid var(--et-green);
  padding: 2px 0 2px var(--s-5);
  margin: var(--s-7) 0; background: transparent;
}

/* tabela editorial tracejada, números tabulares */
.wk-article table {
  font-family: var(--et-mono); font-size: 13px;
  font-variant-numeric: tabular-nums;
  border: none;
}
.wk-article th {
  background: transparent; color: var(--et-dim);
  font-size: 10px; letter-spacing: 0.12em; text-transform: uppercase;
  border-bottom: 1px dashed var(--et-dash);
}
.wk-article td { border-bottom: 1px dashed var(--et-dash); color: var(--et-body); }
.wk-article tr:hover td { background: var(--et-green-soft); }

/* =========================================================================
   FOOTER mínimo
   ========================================================================= */
.wk-article-footer {
  border-top: 1px dashed var(--et-dash);
  font-family: var(--et-mono);
}
.wk-article-footer .tag {
  border: 1px dashed var(--et-dash); border-radius: 999px;
  color: var(--et-meta); text-transform: uppercase; font-size: 10px;
}
.wk-article-footer .tag:hover { border-color: var(--et-green); color: var(--et-text); }
.wk-article-footer .meta { color: var(--et-dim); font-variant-numeric: tabular-nums; }
.wk-article-footer .meta .accent { color: var(--et-green); }

/* =========================================================================
   COMPONENTE — callout (filete tracejado editorial)
   ========================================================================= */
.wk-article .ap-callout {
  background: var(--et-surface);
  border-left: 2px solid var(--et-accent);
  border-radius: 0 6px 6px 0;
}
.wk-article .ap-callout[data-variant="tip"],
.wk-article .ap-callout[data-variant="success"] {
  border-left-color: var(--et-green); background: var(--et-green-soft);
}
.wk-article .ap-callout[data-variant="warn"] {
  border-left-color: var(--et-warn); background: var(--et-warn-soft);
}
.wk-article .ap-callout[data-variant="quote"] {
  border-left-color: var(--et-dim); background: transparent;
  font-family: var(--et-serif); font-style: italic;
}
.wk-article .ap-callout-title {
  font-family: var(--et-mono); font-size: 10px; font-weight: 700;
  letter-spacing: 0.16em; text-transform: uppercase; color: var(--et-green);
}
.wk-article .ap-callout[data-variant="warn"] .ap-callout-title { color: var(--et-warn); }

/* =========================================================================
   COMPONENTE — comparator (tabs com sublinhado verde)
   ========================================================================= */
.wk-article .ap-comparator {
  border: 1px dashed var(--et-dash); border-radius: 8px;
  background: var(--et-surface); overflow: hidden;
}
.wk-article .ap-comp-tabs { border-bottom: 1px dashed var(--et-dash); }
.wk-article .ap-comp-tabs button {
  font-family: var(--et-mono); font-size: 12px; font-weight: 600;
  color: var(--et-dim); letter-spacing: 0.04em;
  border-right: 1px dashed var(--et-dash); background: transparent;
}
.wk-article .ap-comp-tabs button:hover { color: var(--et-text); }
.wk-article .ap-comp-tabs button.active,
.wk-article .ap-comp-tabs button[aria-selected="true"] {
  color: var(--et-text); box-shadow: inset 0 -2px 0 var(--et-green);
}

/* =========================================================================
   COMPONENTE — accordion (trilho verde no aberto)
   ========================================================================= */
.wk-article .ap-accordion-seq {
  border: 1px dashed var(--et-dash); border-radius: 8px; overflow: hidden;
}
.wk-article .ap-acc-trigger {
  font-family: var(--et-mono); font-size: 14px; font-weight: 600;
  color: var(--et-text); background: var(--et-surface);
  border-bottom: 1px dashed var(--et-dash);
}
.wk-article .ap-acc-trigger:hover { background: var(--et-green-soft); }
.wk-article .ap-acc-trigger[aria-expanded="true"],
.wk-article .ap-accordion-seq li.open .ap-acc-trigger {
  background: var(--et-green-soft);
  box-shadow: inset 2px 0 0 var(--et-green);
}
.wk-article .ap-acc-body { color: var(--et-body); }

/* =========================================================================
   COMPONENTE — key-stats (números mono grandes, filete por trend)
   ========================================================================= */
.wk-article .ap-key-stats {
  display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 0 var(--s-6); margin: var(--s-7) 0;
}
.wk-article .ap-key-stat {
  padding: var(--s-4) 0 var(--s-3);
  border-top: 1px dashed var(--et-dash);
  display: flex; flex-direction: column; gap: 6px;
}
.wk-article .ap-key-stat-label {
  order: -1; font-family: var(--et-mono); font-size: 10px;
  letter-spacing: 0.16em; text-transform: uppercase; color: var(--et-dim);
}
.wk-article .ap-key-stat-value {
  font-family: var(--et-mono); font-size: 40px; font-weight: 600;
  line-height: 0.95; letter-spacing: -0.03em; color: var(--et-text);
  font-variant-numeric: tabular-nums;
}
.wk-article .ap-key-stat-delta {
  font-family: var(--et-mono); font-size: 10px; letter-spacing: 0.08em;
  text-transform: uppercase; color: var(--et-dim);
}
.wk-article .ap-key-stat[data-trend="up"]   { border-top-color: var(--et-green); }
.wk-article .ap-key-stat[data-trend="up"]   .ap-key-stat-delta { color: var(--et-green); }
.wk-article .ap-key-stat[data-trend="down"] .ap-key-stat-delta { color: var(--et-warn); }

/* =========================================================================
   BLOCOS NOVOS DO EVERTOOL (parser emite .et-* diretamente)
   ========================================================================= */
/* TL;DR */
.wk-article .et-tldr {
  border: 1px dashed var(--et-dash); border-radius: 8px;
  padding: var(--s-4) var(--s-5); margin: var(--s-6) 0; background: var(--et-surface);
}
.wk-article .et-tldr .lbl {
  font-family: var(--et-mono); font-size: 10px; font-weight: 700;
  letter-spacing: 0.18em; text-transform: uppercase; color: var(--et-green);
  margin-bottom: var(--s-2);
}
.wk-article .et-tldr p {
  font-family: var(--et-serif); font-size: 18px; line-height: 1.5;
  color: var(--et-text); margin: 0;
}

/* takeaways (checklist verde) */
.wk-article .et-takeaways { list-style: none; padding: 0; margin: var(--s-6) 0; display: grid; gap: var(--s-3); }
.wk-article .et-takeaways li { position: relative; padding-left: 28px; color: var(--et-body); line-height: 1.5; }
.wk-article .et-takeaways li::marker { content: ""; }
.wk-article .et-takeaways li::before {
  content: ""; position: absolute; left: 0; top: 6px;
  width: 14px; height: 8px;
  border-left: 2px solid var(--et-green); border-bottom: 2px solid var(--et-green);
  transform: rotate(-45deg);
}

/* steps (numerais serifados) */
.wk-article .et-steps { list-style: none; counter-reset: et-step; padding: 0; margin: var(--s-6) 0; }
.wk-article .et-steps > li {
  counter-increment: et-step; display: grid; grid-template-columns: auto 1fr;
  gap: var(--s-5); padding: var(--s-5) 0; border-top: 1px dashed var(--et-dash);
}
.wk-article .et-steps > li::before {
  content: counter(et-step, decimal-leading-zero);
  font-family: var(--et-serif); font-size: 30px; line-height: 1;
  color: var(--et-green); font-variant-numeric: tabular-nums;
}
.wk-article .et-steps .st-t { font-family: var(--et-serif); font-size: 20px; color: var(--et-text); margin: 0 0 4px; }
.wk-article .et-steps .st-d { margin: 0; color: var(--et-body); font-size: 14px; line-height: 1.55; }

/* deflist / manifesto */
.wk-article .et-dl {
  display: grid; grid-template-columns: 1fr 1fr; gap: 1px;
  background: var(--et-dash); border: 1px dashed var(--et-dash);
  border-radius: 6px; overflow: hidden; margin: var(--s-6) 0;
}
.wk-article .et-dl > div { display: flex; gap: 10px; padding: 9px 14px; background: var(--et-surface); font-family: var(--et-mono); font-size: 12px; margin: 0; }
.wk-article .et-dl dt { color: var(--et-green); margin: 0; width: 90px; flex-shrink: 0; font-weight: 600; }
.wk-article .et-dl dt::after { content: ":"; }
.wk-article .et-dl dd { color: var(--et-text); margin: 0; font-variant-numeric: tabular-nums; }
@media (max-width: 560px) { .wk-article .et-dl { grid-template-columns: 1fr; } }

/* kb list (títulos serifados) */
.wk-article .et-kb-item { padding: var(--s-6) 0; border-top: 1px dashed var(--et-dash); }
.wk-article .et-kb-item:last-child { border-bottom: 1px dashed var(--et-dash); }
.wk-article .et-kb-item h3 {
  font-family: var(--et-serif); font-weight: 600; font-size: 24px;
  line-height: 1.25; margin: 0 0 6px; color: var(--et-text);
}
.wk-article .et-kb-item h3 a:hover { color: var(--et-green); }
.wk-article .et-kb-item .byl { font-family: var(--et-mono); font-size: 11px; color: var(--et-dim); font-style: italic; margin: 0 0 var(--s-3); }
.wk-article .et-kb-item .byl .cat { color: var(--et-green); font-style: normal; }
.wk-article .et-kb-item p { margin: 0; color: var(--et-body); font-size: 14px; line-height: 1.55; }

/* =========================================================================
   FEED / HOME — lista de conhecimento editorial (títulos serifados)
   ========================================================================= */
.wk-feed .feed-title {
  font-family: var(--et-serif); font-weight: 600;
  font-size: 22px; line-height: 1.25; letter-spacing: -0.01em;
  color: var(--et-text);
}
.wk-feed .feed-title:hover { color: var(--et-green); }
.wk-feed li { border-bottom: 1px dashed var(--et-dash); }
.wk-feed .feed-meta { font-family: var(--et-mono); color: var(--et-dim); font-variant-numeric: tabular-nums; }
.wk-feed .feed-meta .accent { color: var(--et-green); }
.wk-feed .feed-snippet { color: var(--et-body); }
.wk-feed .feed-link { color: var(--et-green); }

.wk-section-title {
  font-family: var(--et-mono); font-size: 13px; font-weight: 600;
  letter-spacing: 0.16em; text-transform: uppercase; color: var(--et-green);
}

/* =========================================================================
   CHASSI — toque editorial leve (mantém layout, harmoniza tom)
   ========================================================================= */
.wk-brand { font-family: var(--et-mono); letter-spacing: 0.04em; }
