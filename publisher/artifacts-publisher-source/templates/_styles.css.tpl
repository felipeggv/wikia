/* =========================================================
   WIKIA · BLOG/WIKI INTERNO
   Maestro dark green + 100% JetBrains Mono
   Heading sizes EM-based (extraídos do Maestro app.asar):
     h1: 1.5em / h2: 1.3em / h3: 1.15em / h4: 1.05em
     todos color: textMain, weight 600
   Layout: topbar 48px + sidebar collapsible (280px↔48px) + content centered
   ========================================================= */
:root {
  /* Theme tokens (snapshot Maestro) */
  {{THEME_VARS}}

  /* ---------- Typography ---------- */
  --font: "JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  --body-size: 14px;
  --body-lh: 1.7;

  /* ---------- Layout ---------- */
  --topbar-h: 48px;
  --sidebar-w: 280px;
  --sidebar-collapsed-w: 48px;
  --content-compact: 720px;
  --content-wide: 960px;
  --content-w: var(--content-compact);

  /* ---------- Spacing ---------- */
  --s-1: 4px;
  --s-2: 8px;
  --s-3: 12px;
  --s-4: 16px;
  --s-5: 20px;
  --s-6: 24px;
  --s-7: 32px;
  --s-8: 48px;
  --s-9: 64px;

  /* ---------- Backwards-compat aliases ---------- */
  --font-sans: var(--font);
  --font-serif: var(--font);
  --font-mono: var(--font);
  --body-family: var(--font);
  --h1-family: var(--font);
  --h2-family: var(--font);
  --h3-family: var(--font);
  --ui-family: var(--font);
  --code-family: var(--font);
  --ui-size: 11px;
  --ui-weight: 600;
  --ui-tracking: 0.08em;
  --code-size: 13px;
  --text-xs: 11px;
  --text-sm: 13px;
  --text-base: 14px;
  --text-lg: 16px;
  --text-xl: 18px;
  --text-2xl: 21px;
  --text-3xl: 21px;
  --space-1: var(--s-1);
  --space-2: var(--s-2);
  --space-3: var(--s-3);
  --space-4: var(--s-4);
  --space-5: var(--s-5);
  --space-6: var(--s-6);
  --space-7: var(--s-7);
  --space-8: var(--s-8);
  --space-9: var(--s-9);
}

/* "wide" mode set on <body> by topbar toggle */
body[data-width="wide"] { --content-w: var(--content-wide); }

* { box-sizing: border-box; }
html, body {
  margin: 0;
  padding: 0;
  background: var(--bg-main);
  color: var(--text-main);
  font-family: var(--font);
  font-size: var(--body-size);
  line-height: var(--body-lh);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* =========================================================
   TOPBAR — sticky 48px
   ========================================================= */
.wk-topbar {
  position: sticky;
  top: 0;
  z-index: 100;
  height: var(--topbar-h);
  background: var(--bg-sidebar);
  border-bottom: 1px solid var(--border);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  padding: 0 var(--s-4);
  gap: var(--s-4);
  font-size: 13px;
}
.wk-topbar .wk-burger {
  width: 28px;
  height: 28px;
  background: transparent;
  border: 1px solid var(--border);
  border-radius: 4px;
  color: var(--text-dim);
  cursor: pointer;
  font: inherit;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  font-size: 14px;
}
.wk-topbar .wk-burger:hover { color: var(--text-main); border-color: var(--accent); }

.wk-topbar .wk-brand {
  font-family: var(--font);
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.wk-topbar .wk-brand::before {
  content: "■";
  color: var(--accent);
  font-size: 10px;
}
.wk-topbar .wk-brand .dim { color: var(--text-dim); font-weight: 400; margin-left: 4px; font-size: 11px; }

.wk-topbar .wk-spacer { flex: 1; }

.wk-topbar .wk-search-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: var(--bg-main);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: 4px 10px;
  color: var(--text-dim);
  cursor: pointer;
  font: inherit;
  font-size: 12px;
  min-width: 200px;
}
.wk-topbar .wk-search-btn:hover { border-color: var(--accent); color: var(--text-main); }
.wk-topbar .wk-search-btn .kbd {
  background: var(--accent-dim);
  border: 1px solid var(--border);
  padding: 1px 5px;
  border-radius: 2px;
  font-size: 10px;
  margin-left: auto;
  color: var(--text-dim);
}

.wk-topbar .wk-width-toggle {
  display: inline-flex;
  gap: 0;
  border: 1px solid var(--border);
  border-radius: 4px;
  overflow: hidden;
}
.wk-topbar .wk-width-toggle button {
  background: transparent;
  border: none;
  padding: 4px 10px;
  color: var(--text-dim);
  cursor: pointer;
  font: inherit;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}
.wk-topbar .wk-width-toggle button:hover { color: var(--text-main); }
.wk-topbar .wk-width-toggle button.active { background: var(--accent-dim); color: var(--accent); }
.wk-topbar .wk-width-toggle button svg { pointer-events: none; }

/* =========================================================
   APP SHELL — sidebar + main
   ========================================================= */
.wk-shell {
  display: grid;
  grid-template-columns: var(--sidebar-w) 1fr;
  min-height: calc(100vh - var(--topbar-h));
  transition: grid-template-columns 0.25s ease;
}
body[data-sidebar="collapsed"] .wk-shell {
  grid-template-columns: var(--sidebar-collapsed-w) 1fr;
}

/* =========================================================
   SIDEBAR — Obsidian file-tree
   ========================================================= */
.wk-sidebar {
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border);
  position: sticky;
  top: var(--topbar-h);
  height: calc(100vh - var(--topbar-h));
  overflow-y: auto;
  padding: var(--s-3) 0;
  font-size: 13px;
  transition: padding 0.25s ease;
}
body[data-sidebar="collapsed"] .wk-sidebar {
  overflow: hidden;
}
body[data-sidebar="collapsed"] .wk-sidebar > *:not(.wk-sidebar-rail) { display: none; }
.wk-sidebar-rail {
  display: none;
  flex-direction: column;
  align-items: center;
  padding-top: 8px;
  gap: 12px;
}
body[data-sidebar="collapsed"] .wk-sidebar-rail { display: flex; }
.wk-sidebar-rail .rail-icon {
  width: 28px;
  height: 28px;
  border: 1px solid var(--border);
  border-radius: 4px;
  color: var(--text-dim);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  background: var(--bg-main);
}

.wk-sidebar h4 {
  font-family: var(--font);
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--text-dim);
  margin: var(--s-4) 0 var(--s-2);
  padding: 0 var(--s-4);
}
.wk-sidebar h4:first-child { margin-top: 0; }

.wk-sidebar .wk-section {
  margin: 0;
}

/* =========================================================
   TREE — Obsidian file-system style
   Folders com chevron+folder icon, files com file-text icon,
   indent visível via guide-lines, hover sutil
   ========================================================= */
.wk-tree {
  list-style: none;
  padding: 0 0 0 0;
  margin: 0;
  font-size: 11.5px;
}

/* ============================================================
   WAVE 2 SIDEBAR TREE (BU/Project/Article)
   11.5px font, 4px padding, 12px chev, 14px folder, 10px count.
   Auto-flatten projects skip the project-folder layer (article renders directly under BU).
   Click on chevron toggles; click on label-text navigates.
   ============================================================ */
.wk-tree-bu { margin: 0; position: relative; list-style: none; }
.wk-tree-bu > .wk-tree-bu-link {
  display: flex;
  align-items: flex-start;
  gap: 4px;
  padding: 4px var(--s-4) 4px var(--s-3);
  text-decoration: none;
  color: var(--text-main);
  font-size: 11.5px;
  font-weight: 500;
  line-height: 1.4;
  border-radius: 3px;
  cursor: pointer;
  user-select: none;
  margin: 0 4px;
  transition: background 0.1s;
}
.wk-tree-bu > .wk-tree-bu-link:hover { background: var(--accent-dim); }
.wk-tree-bu > .wk-tree-bu-link .chev {
  display: inline-block;
  width: 12px;
  height: 12px;
  flex-shrink: 0;
  color: var(--text-dim);
  transition: transform 0.15s;
  margin-top: 2px;
  cursor: pointer;
}
.wk-tree-bu[data-expanded="true"] > .wk-tree-bu-link .chev { transform: rotate(90deg); }
.wk-tree-bu > .wk-tree-bu-link .folder-icon {
  display: inline-flex;
  width: 14px;
  height: 14px;
  color: var(--accent);
  flex-shrink: 0;
  margin-right: 2px;
  margin-top: 1px;
}
.wk-tree-bu[data-expanded="true"] > .wk-tree-bu-link .folder-icon { color: var(--success); }
.wk-tree-bu > .wk-tree-bu-link .label-text {
  flex: 1;
  min-width: 0;
  word-break: break-word;
  overflow-wrap: anywhere;
  white-space: normal;
}
.wk-tree-bu > .wk-tree-bu-link .count {
  color: var(--text-dim);
  font-size: 10px;
  margin-left: 4px;
  margin-top: 2px;
  font-weight: 400;
  font-variant-numeric: tabular-nums;
  flex-shrink: 0;
}
.wk-tree-bu.wk-current-bu > .wk-tree-bu-link { background: var(--accent-dim); }
.wk-tree-bu-empty > .wk-tree-bu-link .folder-icon { opacity: 0.45; }
.wk-tree-bu-empty > .wk-tree-bu-link .chev { visibility: hidden; }

.wk-tree-projects {
  list-style: none;
  margin: 0;
  padding: 0;
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.18s;
  position: relative;
}
.wk-tree-bu[data-expanded="true"] > .wk-tree-projects { max-height: 4000px; }
.wk-tree-projects::before {
  content: "";
  position: absolute;
  left: calc(var(--s-3) + 6px);
  top: 0;
  bottom: 0;
  width: 1px;
  background: var(--border);
}

.wk-tree-project { margin: 0; position: relative; list-style: none; }
.wk-tree-project > .wk-tree-project-link {
  display: flex;
  align-items: flex-start;
  gap: 4px;
  padding: 3px var(--s-4) 3px calc(var(--s-3) + 14px);
  text-decoration: none;
  color: var(--text-dim);
  font-size: 11px;
  line-height: 1.4;
  border-radius: 3px;
  margin: 0 4px;
  cursor: pointer;
  user-select: none;
}
.wk-tree-project > .wk-tree-project-link:hover { background: var(--accent-dim); color: var(--text-main); }
.wk-tree-project > .wk-tree-project-link .chev {
  width: 10px; height: 10px;
  color: var(--text-dim);
  flex-shrink: 0;
  margin-top: 3px;
  transition: transform 0.15s;
}
.wk-tree-project[data-expanded="true"] > .wk-tree-project-link .chev { transform: rotate(90deg); }
.wk-tree-project > .wk-tree-project-link .folder-icon {
  width: 12px; height: 12px;
  color: var(--text-dim);
  flex-shrink: 0;
  margin-top: 2px;
}
.wk-tree-project > .wk-tree-project-link .label-text {
  flex: 1; min-width: 0;
  word-break: break-word;
}
.wk-tree-project > .wk-tree-project-link .count {
  color: var(--text-dim);
  font-size: 10px;
  margin-left: 4px;
  margin-top: 2px;
  font-variant-numeric: tabular-nums;
  flex-shrink: 0;
}
.wk-tree-project.wk-current-project > .wk-tree-project-link { color: var(--text-main); }

.wk-tree-articles {
  list-style: none;
  margin: 0;
  padding: 0;
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.18s;
}
.wk-tree-project[data-expanded="true"] > .wk-tree-articles { max-height: 4000px; }

.wk-tree-article { margin: 0; list-style: none; }
.wk-tree-article > a {
  display: flex;
  align-items: flex-start;
  gap: 4px;
  padding: 3px var(--s-4) 3px calc(var(--s-3) + 18px);
  text-decoration: none;
  color: var(--text-dim);
  font-size: 11px;
  line-height: 1.4;
  border-radius: 3px;
  margin: 0 4px;
  position: relative;
  transition: background 0.1s, color 0.1s;
}
/* Auto-flatten articles (direct child of .wk-tree-projects with no project layer) have shallower indent */
.wk-tree-projects > .wk-tree-article > a {
  padding-left: calc(var(--s-3) + 14px);
}
.wk-tree-article > a:hover { color: var(--text-main); background: var(--accent-dim); }
.wk-tree-article > a:hover .file-icon { color: var(--accent); }
.wk-tree-article > a .file-icon {
  width: 12px;
  height: 12px;
  color: var(--text-dim);
  flex-shrink: 0;
  margin-top: 2px;
}
.wk-tree-article > a > span:not(.wk-gate-icon):not(.file-icon) {
  flex: 1; min-width: 0;
  word-break: break-word;
  overflow-wrap: anywhere;
  white-space: normal;
}
.wk-tree-article .wk-gate-icon {
  font-size: 10px;
  opacity: 0.7;
  flex-shrink: 0;
  margin-top: 1px;
}
.wk-tree-article.wk-current-article > a {
  color: var(--text-main);
  background: var(--accent-dim);
}
.wk-tree-article.wk-current-article > a .file-icon { color: var(--success); }
.wk-tree-article.wk-current-article > a::before {
  content: "";
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 2px;
  background: var(--accent);
}

/* Recents — agrupado por data (Wave 2.1) */
.wk-recents { list-style: none; padding: 0; margin: 0; }
.wk-recents-day {
  list-style: none;
  margin: 0 0 var(--s-3) 0;
  padding: 0;
}
.wk-recents-day:last-child { margin-bottom: 0; }
.wk-recents-date {
  display: block;
  font-size: 9.5px;
  color: var(--accent);
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  margin: 0 0 4px 0;
  padding: 0 var(--s-4);
}
.wk-recents-items {
  list-style: none;
  padding: 0;
  margin: 0;
}
.wk-recents-items li { margin: 0; }
.wk-recents-items a {
  color: var(--text-dim);
  text-decoration: none;
  font-size: 11px;
  line-height: 1.35;
  transition: all 0.12s;
  word-break: break-word;
  overflow-wrap: anywhere;
  white-space: normal;
  padding: 3px var(--s-4);
  /* Cap em 2 linhas pra não inflar a sidebar */
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.wk-recents-items a:hover { color: var(--text-main); background: var(--accent-dim); }

/* =========================================================
   MAIN — centered content
   ========================================================= */
.wk-main {
  padding: var(--s-7) var(--s-6) var(--s-9);
  display: flex;
  justify-content: center;
}
.wk-content {
  width: 100%;
  max-width: var(--content-w);
  transition: max-width 0.2s ease;
}

@media (max-width: 880px) {
  .wk-shell { grid-template-columns: 1fr !important; }
  .wk-sidebar { display: none !important; }
  body[data-sidebar="overlay"] .wk-sidebar {
    display: block !important;
    position: fixed;
    top: var(--topbar-h);
    left: 0;
    width: var(--sidebar-w);
    z-index: 90;
    box-shadow: 0 0 0 1px var(--border), 4px 0 24px rgba(0,0,0,0.4);
  }
  .wk-main { padding: var(--s-5) var(--s-4) var(--s-7); }
}

/* =========================================================
   BREADCRUMB (acima do título)
   ========================================================= */
.wk-breadcrumb {
  font-size: 10px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--text-dim);
  margin: 0 0 var(--s-5);
  font-weight: 600;
}
.wk-breadcrumb a { color: var(--text-dim); text-decoration: none; }
.wk-breadcrumb a:hover { color: var(--text-main); }
.wk-breadcrumb .sep { color: var(--accent); margin: 0 6px; }
.wk-breadcrumb .current { color: var(--text-main); }

/* =========================================================
   ARTICLE
   ========================================================= */
.wk-article-header {
  margin-bottom: var(--s-6);
  padding-bottom: var(--s-5);
  border-bottom: 1px solid var(--border);
}
.wk-eyebrow {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--accent);
  margin: 0 0 var(--s-2);
}

/* Headings: EM-based from Maestro app.asar */
.wk-article h1 {
  font-family: var(--font);
  font-weight: 600;
  font-size: 1.5em;
  line-height: 1.3;
  color: var(--text-main);
  margin: 16px 0 8px;
}
.wk-article h2 {
  font-family: var(--font);
  font-weight: 600;
  font-size: 1.3em;
  line-height: 1.35;
  color: var(--text-main);
  margin: 32px 0 12px;
}
.wk-article h3 {
  font-family: var(--font);
  font-weight: 600;
  font-size: 1.15em;
  line-height: 1.4;
  color: var(--text-main);
  margin: 24px 0 8px;
}
.wk-article h4 {
  font-family: var(--font);
  font-weight: 600;
  font-size: 1.05em;
  line-height: 1.45;
  color: var(--text-main);
  margin: 20px 0 8px;
}

/* H1 first in article header é maior (page title) */
.wk-article-header h1 {
  font-size: 1.7em;
  line-height: 1.2;
  margin: 0 0 var(--s-3);
}

.wk-lead {
  font-family: var(--font);
  font-size: var(--body-size);
  line-height: var(--body-lh);
  color: var(--text-dim);
  margin: 0 0 var(--s-4);
  font-weight: 400;
}
.wk-meta-row {
  display: flex;
  gap: var(--s-3);
  flex-wrap: wrap;
  align-items: center;
  font-size: 10px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--text-dim);
  font-weight: 600;
}
.wk-meta-row .tag {
  display: inline-block;
  padding: 2px 8px;
  background: var(--accent-dim);
  border: 1px solid var(--border);
  border-radius: 999px;
  color: var(--text-dim);
  text-decoration: none;
  font-weight: 600;
  transition: all 0.15s;
}
.wk-meta-row .tag:hover { color: var(--text-main); border-color: var(--accent); }
.wk-meta-row .dot { color: var(--accent); }

/* body content */
.wk-article p {
  font-family: var(--font);
  font-size: var(--body-size);
  font-weight: 400;
  line-height: var(--body-lh);
  color: var(--text-main);
  margin: 0 0 var(--s-3);
}
.wk-article ul, .wk-article ol {
  font-family: var(--font);
  font-size: var(--body-size);
  line-height: var(--body-lh);
  color: var(--text-main);
  padding-left: var(--s-5);
  margin: 0 0 var(--s-3);
}
.wk-article li { margin-bottom: var(--s-1); }
.wk-article li::marker { color: var(--accent); }
.wk-article a {
  color: var(--success);
  text-decoration: underline;
  text-decoration-color: var(--accent);
  text-underline-offset: 3px;
}
.wk-article a:hover { color: var(--text-main); text-decoration-color: var(--success); }
.wk-article strong { color: var(--text-main); font-weight: 700; }
.wk-article em { font-style: italic; color: var(--text-dim); }
.wk-article hr { border: none; border-top: 1px solid var(--border); margin: var(--s-6) 0; }

.wk-article code {
  font-family: var(--font);
  background: var(--bg-sidebar);
  border: 1px solid var(--border);
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 0.92em;
  color: var(--text-main);
}
.wk-article pre {
  background: var(--bg-sidebar);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: var(--s-3) var(--s-4);
  overflow-x: auto;
  font-family: var(--font);
  font-size: var(--code-size);
  line-height: 1.55;
  margin: var(--s-3) 0;
}
.wk-article pre code {
  background: transparent;
  border: none;
  padding: 0;
  color: var(--text-main);
}

.wk-article blockquote {
  margin: var(--s-4) 0;
  padding: var(--s-2) var(--s-4);
  border-left: 3px solid var(--accent);
  background: var(--bg-sidebar);
  border-radius: 0 4px 4px 0;
  color: var(--text-dim);
  font-style: italic;
}

.wk-article table {
  width: 100%;
  border-collapse: collapse;
  margin: var(--s-4) 0;
  font-family: var(--font);
  font-size: 13px;
}
.wk-article th, .wk-article td {
  text-align: left;
  padding: 8px 12px;
  border-bottom: 1px solid var(--border);
}
.wk-article th {
  color: var(--text-dim);
  font-weight: 600;
  font-size: 10px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  background: var(--bg-sidebar);
  border-bottom: 1px solid var(--accent);
}
.wk-article tr:hover td { background: var(--accent-dim); }

/* =========================================================
   ARTICLE FOOTER
   ========================================================= */
.wk-article-footer {
  margin-top: var(--s-8);
  padding-top: var(--s-4);
  border-top: 1px solid var(--border);
  font-size: 10px;
  color: var(--text-dim);
  display: flex;
  flex-direction: column;
  gap: var(--s-2);
}
.wk-article-footer .tags { display: flex; gap: 6px; flex-wrap: wrap; }
.wk-article-footer .meta {
  display: flex;
  gap: var(--s-3);
  align-items: center;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-weight: 600;
}
.wk-article-footer .meta .accent { color: var(--accent); }

/* =========================================================
   WIKI HOME — chronological feed (no cards)
   ========================================================= */
.wk-feed { list-style: none; padding: 0; margin: var(--s-7) 0 0; }
.wk-feed li { padding: var(--s-5) 0; border-bottom: 1px solid var(--border); }
.wk-feed li:first-child { padding-top: 0; }
.wk-feed li:last-child { border-bottom: none; }
.wk-feed .feed-meta {
  font-size: 10px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--text-dim);
  font-weight: 600;
  margin-bottom: var(--s-2);
}
.wk-feed .feed-meta .accent { color: var(--accent); margin-left: var(--s-2); }
.wk-feed .feed-title {
  font-size: 1.3em;
  font-weight: 600;
  color: var(--text-main);
  text-decoration: none;
  display: block;
  margin-bottom: var(--s-2);
  line-height: 1.3;
}
.wk-feed .feed-title:hover { color: var(--accent); }
.wk-feed .feed-snippet {
  font-size: 13px;
  color: var(--text-dim);
  line-height: 1.65;
  margin: 0 0 var(--s-2);
}
.wk-feed .feed-link {
  font-size: 11px;
  color: var(--accent);
  text-decoration: none;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  font-weight: 600;
}

/* =========================================================
   SEARCH MODAL (⌘K)
   ========================================================= */
#wk-search-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.7); backdrop-filter: blur(4px); z-index: 200; align-items: flex-start; justify-content: center; padding-top: 100px; }
#wk-search-modal.open { display: flex; }
#wk-search-modal .wk-search-card { width: 100%; max-width: 600px; background: var(--bg-sidebar); border: 1px solid var(--accent); border-radius: 6px; box-shadow: 0 24px 60px rgba(0,0,0,0.7); }
#wk-search-modal input { width: 100%; padding: 14px 18px; background: transparent; border: none; border-bottom: 1px solid var(--border); color: var(--text-main); font: inherit; font-size: 14px; outline: none; font-family: var(--font); }
#wk-search-results { max-height: 380px; overflow-y: auto; }
#wk-search-results .item { display: block; padding: 12px 18px; cursor: pointer; color: var(--text-dim); font-size: 13px; text-decoration: none; border-bottom: 1px solid var(--border); }
#wk-search-results .item:last-child { border-bottom: none; }
#wk-search-results .item:hover, #wk-search-results .item.selected { background: var(--accent-dim); color: var(--text-main); }
#wk-search-results .item .title { color: var(--text-main); font-weight: 600; }
#wk-search-results .item .meta { font-size: 10px; color: var(--text-dim); letter-spacing: 0.08em; text-transform: uppercase; margin-top: 3px; }

/* =========================================================
   SCROLLBAR + SELECTION
   ========================================================= */
::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-track { background: var(--bg-sidebar); }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: var(--accent); }
::selection { background: var(--accent); color: var(--accent-text); }

/* Legacy aliases for backwards compat */
.ap-article { /* old class name */ }
.ap-page { max-width: var(--content-w); margin: 0 auto; padding: var(--s-5); }

/* =========================================================
   CALLOUTS — inline highlights, variants via data-variant
   variants: info | tip | warn | success | quote
   ========================================================= */
.ap-callout {
  margin: var(--s-4) 0;
  padding: var(--s-3) var(--s-4);
  border-left: 3px solid var(--accent);
  background: var(--bg-sidebar);
  border-radius: 0 4px 4px 0;
  color: var(--text-main);
  font-size: var(--body-size);
  line-height: var(--body-lh);
  position: relative;
}
.ap-callout[data-variant="tip"]    { border-left-color: var(--success); background: rgba(190, 215, 142, 0.06); }
.ap-callout[data-variant="success"]{ border-left-color: var(--success); background: rgba(190, 215, 142, 0.08); }
.ap-callout[data-variant="warn"]   { border-left-color: var(--warning); background: rgba(208, 167, 149, 0.06); }
.ap-callout[data-variant="info"]   { border-left-color: var(--accent);  background: var(--bg-sidebar); }
.ap-callout[data-variant="quote"]  { border-left-color: var(--text-dim); background: transparent; font-style: italic; color: var(--text-dim); }

.ap-callout-title {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--success);
  margin-bottom: 6px;
}
.ap-callout[data-variant="warn"] .ap-callout-title { color: var(--warning); }
.ap-callout[data-variant="info"] .ap-callout-title { color: var(--accent); }
.ap-callout[data-variant="quote"] .ap-callout-title { color: var(--text-dim); }
.ap-callout-body > *:first-child { margin-top: 0; }
.ap-callout-body > *:last-child { margin-bottom: 0; }
.ap-callout-body p { margin-bottom: var(--s-2); font-size: var(--body-size); }

/* =========================================================
   PLAYGROUND TRIGGER (inline button + drawer right)
   ========================================================= */
.ap-playground-trigger {
  display: flex;
  align-items: center;
  gap: var(--s-3);
  margin: var(--s-4) 0;
  padding: var(--s-3) var(--s-4);
  background: var(--bg-sidebar);
  border: 1px solid var(--accent);
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
  text-align: left;
}
.ap-playground-trigger:hover {
  background: var(--accent-dim);
  border-color: var(--success);
  transform: translateY(-1px);
}
.ap-playground-trigger-icon {
  width: 36px;
  height: 36px;
  background: var(--accent-dim);
  border: 1px solid var(--accent);
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--success);
  font-size: 16px;
  flex-shrink: 0;
}
.ap-playground-trigger-body { flex: 1; min-width: 0; }
.ap-playground-trigger-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--success);
  margin-bottom: 2px;
}
.ap-playground-trigger-title {
  font-size: var(--body-size);
  color: var(--text-main);
  font-weight: 600;
}
.ap-playground-trigger-cta {
  color: var(--accent);
  font-size: 11px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  font-weight: 600;
}

/* Drawer */
#wk-drawer { position: fixed; top: 0; right: 0; bottom: 0; width: 480px; max-width: 100vw; background: var(--bg-sidebar); border-left: 1px solid var(--accent); z-index: 150; transform: translateX(100%); transition: transform 0.25s ease; box-shadow: -8px 0 24px rgba(0,0,0,0.5); display: flex; flex-direction: column; }
#wk-drawer.open { transform: translateX(0); }
#wk-drawer-header { padding: var(--s-4); border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; gap: var(--s-3); }
#wk-drawer-header .label { font-size: 10px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--success); font-weight: 600; }
#wk-drawer-header .title { font-size: var(--body-size); color: var(--text-main); font-weight: 600; margin-top: 2px; }
#wk-drawer-close { width: 28px; height: 28px; background: transparent; border: 1px solid var(--border); border-radius: 4px; color: var(--text-dim); cursor: pointer; font-size: 14px; }
#wk-drawer-close:hover { color: var(--text-main); border-color: var(--accent); }
#wk-drawer-content { flex: 1; overflow-y: auto; padding: var(--s-5); }
#wk-drawer-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,0.4); z-index: 140; opacity: 0; pointer-events: none; transition: opacity 0.25s; }
#wk-drawer-backdrop.open { opacity: 1; pointer-events: auto; }
@media (max-width: 700px) { #wk-drawer { width: 100vw; } }
