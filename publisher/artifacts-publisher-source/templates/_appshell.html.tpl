<!-- Search modal (global) -->
<div id="wk-search-modal" onclick="wkCloseSearch(event)">
  <div class="wk-search-card" onclick="event.stopPropagation()">
    <input type="text" id="wk-search-input" placeholder="Buscar artigos por título, tema, tag..." autocomplete="off">
    <div id="wk-search-results"></div>
  </div>
</div>

<!-- Playground drawer (right side) -->
<div id="wk-drawer-backdrop"></div>
<div id="wk-drawer" aria-hidden="true">
  <div id="wk-drawer-header">
    <div>
      <div class="label">TESTE INTERATIVO</div>
      <div class="title" id="wk-drawer-title">—</div>
    </div>
    <button id="wk-drawer-close" aria-label="Fechar drawer">×</button>
  </div>
  <div id="wk-drawer-content"></div>
</div>

<script>
(function() {
  // ============ SIDEBAR TOGGLE ============
  const burger = document.getElementById('wk-burger');
  const SK = 'wikia-sidebar-state';
  function applySidebar(state) { document.body.dataset.sidebar = state; }
  applySidebar(localStorage.getItem(SK) || 'expanded');
  burger?.addEventListener('click', () => {
    const cur = document.body.dataset.sidebar || 'expanded';
    const next = cur === 'collapsed' ? 'expanded' : 'collapsed';
    applySidebar(next);
    localStorage.setItem(SK, next);
  });

  // ============ WIDTH TOGGLE ============
  const WK = 'wikia-content-width';
  function applyWidth(w) {
    document.body.dataset.width = w;
    document.querySelectorAll('.wk-width-toggle button').forEach(b => b.classList.toggle('active', b.dataset.width === w));
  }
  applyWidth(localStorage.getItem(WK) || 'compact');
  document.querySelectorAll('.wk-width-toggle button').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const w = e.currentTarget.dataset.width;
      applyWidth(w);
      localStorage.setItem(WK, w);
    });
  });

  // ============ TREE EXPAND/COLLAPSE ============
  // ============ WAVE 2 TREE TOGGLE (.wk-tree-bu / .wk-tree-project) ============
  // Click on chevron toggles; click on label-text/folder-icon navigates via the <a>.
  // BU/project containers persist expanded state in localStorage.
  const TKW2 = 'wikia-tree-state-w2';
  let w2State = {};
  try { w2State = JSON.parse(localStorage.getItem(TKW2) || '{}'); } catch {}

  function w2Toggle(node, key) {
    const isOpen = node.dataset.expanded === 'true';
    node.dataset.expanded = isOpen ? 'false' : 'true';
    w2State[key] = !isOpen;
    localStorage.setItem(TKW2, JSON.stringify(w2State));
  }

  // BU nodes
  document.querySelectorAll('.wk-tree-bu:not(.wk-tree-bu-empty)').forEach(node => {
    const key = 'bu:' + node.dataset.bu;
    const hasCurrent = !!node.querySelector('.wk-current-article, .wk-current-project');
    const explicit = w2State[key];
    node.dataset.expanded = (explicit !== undefined ? explicit : (hasCurrent || node.classList.contains('wk-current-bu'))) ? 'true' : 'false';

    const link = node.querySelector(':scope > .wk-tree-bu-link');
    link?.addEventListener('click', (e) => {
      // Chevron click → toggle (do NOT navigate)
      if (e.target.closest('.chev')) {
        e.preventDefault();
        e.stopPropagation();
        w2Toggle(node, key);
      }
      // Otherwise: native <a> navigation proceeds
    });
  });

  // Project nodes
  document.querySelectorAll('.wk-tree-project').forEach(node => {
    const key = 'proj:' + (node.closest('.wk-tree-bu')?.dataset.bu || '?') + '/' + node.dataset.project;
    const hasCurrent = !!node.querySelector('.wk-current-article');
    const explicit = w2State[key];
    node.dataset.expanded = (explicit !== undefined ? explicit : (hasCurrent || node.classList.contains('wk-current-project'))) ? 'true' : 'false';

    const link = node.querySelector(':scope > .wk-tree-project-link');
    link?.addEventListener('click', (e) => {
      if (e.target.closest('.chev')) {
        e.preventDefault();
        e.stopPropagation();
        w2Toggle(node, key);
      }
    });
  });

  // ============ SEARCH MODAL (⌘K) ============
  const modal = document.getElementById('wk-search-modal');
  const searchInput = document.getElementById('wk-search-input');
  const searchResults = document.getElementById('wk-search-results');
  const searchBtn = document.getElementById('wk-search-btn');
  const adminStateRoot = document.getElementById('admin-state');
  let searchIndex = [];
  let selectedIdx = 0;
  let filtered = [];
  let searchIndexLoaded = false;

  function isAdminLockedShell() {
    return adminStateRoot?.dataset.state === 'locked';
  }

  function loadSearchIndex() {
    if (searchIndexLoaded || isAdminLockedShell()) return;
    searchIndexLoaded = true;
    const wikiBase = document.documentElement.dataset.wikiBase || '';
    fetch(wikiBase + '/search.json').then(r => r.json()).then(d => { searchIndex = d; }).catch(() => {});
  }

  if (isAdminLockedShell()) {
    searchBtn?.setAttribute('aria-disabled', 'true');
    searchBtn?.setAttribute('title', 'Busca disponivel apos unlock');
  }

  function openSearch() {
    if (isAdminLockedShell()) return;
    loadSearchIndex();
    modal?.classList.add('open');
    searchInput.value = '';
    selectedIdx = 0;
    renderResults('');
    setTimeout(() => searchInput?.focus(), 50);
  }
  window.wkOpenSearch = openSearch;
  window.wkCloseSearch = (e) => {
    if (e && e.target.id !== 'wk-search-modal') return;
    modal?.classList.remove('open');
  };

  searchBtn?.addEventListener('click', openSearch);

  document.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') { e.preventDefault(); openSearch(); }
    if ((e.metaKey || e.ctrlKey) && e.key === '\\') { e.preventDefault(); burger?.click(); }
    if (e.key === 'Escape') modal?.classList.remove('open');
  });

  // ============ PLAYGROUND DRAWER ============
  const drawer = document.getElementById('wk-drawer');
  const drawerBackdrop = document.getElementById('wk-drawer-backdrop');
  const drawerTitle = document.getElementById('wk-drawer-title');
  const drawerContent = document.getElementById('wk-drawer-content');
  const drawerClose = document.getElementById('wk-drawer-close');

  function openDrawer(templateId) {
    const tpl = document.getElementById(templateId);
    if (!tpl) return;
    drawerTitle.textContent = tpl.dataset.title || 'Teste interativo';
    drawerContent.innerHTML = tpl.innerHTML;
    // Re-executa scripts injetados
    drawerContent.querySelectorAll('script').forEach(old => {
      const s = document.createElement('script');
      if (old.src) s.src = old.src; else s.textContent = old.textContent;
      old.replaceWith(s);
    });
    drawer.classList.add('open');
    drawerBackdrop.classList.add('open');
    drawer.setAttribute('aria-hidden', 'false');
  }
  function closeDrawer() {
    drawer.classList.remove('open');
    drawerBackdrop.classList.remove('open');
    drawer.setAttribute('aria-hidden', 'true');
    drawerContent.innerHTML = '';
  }
  window.wkOpenDrawer = openDrawer;
  window.wkCloseDrawer = closeDrawer;

  // Event delegation: triggers virão DEPOIS da decifragem AES, então NÃO usar querySelectorAll no load
  document.addEventListener('click', (e) => {
    const t = e.target.closest('[data-playground-trigger]');
    if (t) openDrawer(t.dataset.playgroundTrigger);
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && drawer?.classList.contains('open')) closeDrawer();
  });
  drawerClose?.addEventListener('click', closeDrawer);
  drawerBackdrop?.addEventListener('click', closeDrawer);

  // Load search.json (relative to wiki base). Admin waits until unlock.
  if (!isAdminLockedShell()) loadSearchIndex();

  function score(item, q) {
    const txt = (item.title + ' ' + item.tema + ' ' + (item.tags || []).join(' ') + ' ' + (item.snippet || '')).toLowerCase();
    let s = 0;
    for (const t of q.split(/\s+/).filter(Boolean)) {
      if (txt.includes(t)) s += 1;
      if ((item.title || '').toLowerCase().includes(t)) s += 3;
    }
    return s;
  }

  function renderResults(q) {
    if (!q) {
      // Show recent 8
      filtered = searchIndex.slice(0, 8);
    } else {
      filtered = searchIndex.map(i => ({i, s: score(i, q)})).filter(x => x.s > 0).sort((a,b) => b.s - a.s).slice(0, 10).map(x => x.i);
    }
    if (!filtered.length) {
      searchResults.innerHTML = `<div style="padding:24px;text-align:center;color:var(--text-dim);font-size:13px">Nenhum resultado para "${q}"</div>`;
      return;
    }
    searchResults.innerHTML = filtered.map((it, idx) => `
      <a href="${(document.documentElement.dataset.wikiBase || '')}/${it.url}" class="item ${idx === selectedIdx ? 'selected' : ''}" data-i="${idx}">
        <div class="title">${it.title}</div>
        <div class="meta">${it.tema} · ${it.date}${(it.tags||[]).length ? ' · ' + it.tags.join(', ') : ''}</div>
      </a>
    `).join('');
  }

  searchInput?.addEventListener('input', () => { selectedIdx = 0; renderResults(searchInput.value.trim()); });
  searchInput?.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowDown') { e.preventDefault(); selectedIdx = Math.min(selectedIdx + 1, filtered.length - 1); renderResults(searchInput.value.trim()); }
    if (e.key === 'ArrowUp') { e.preventDefault(); selectedIdx = Math.max(selectedIdx - 1, 0); renderResults(searchInput.value.trim()); }
    if (e.key === 'Enter') { e.preventDefault(); const target = filtered[selectedIdx]; if (target) location.href = (document.documentElement.dataset.wikiBase || '') + '/' + target.url; }
  });
})();
</script>
