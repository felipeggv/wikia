/* Admin locked shell: no catalog metadata is rendered before masterpass unlock. */
.wk-tree-admin-shell {
  list-style: none;
  margin: 0 4px;
  padding: 4px var(--s-4) 4px var(--s-3);
  color: var(--text-dim);
  font-size: 11px;
  line-height: 1.45;
}

.wk-tree-admin-shell-label {
  display: flex;
  align-items: flex-start;
  gap: 6px;
  color: var(--text-main);
  font-size: 11.5px;
  font-weight: 500;
}

.wk-tree-admin-shell-label .folder-icon {
  width: 14px;
  height: 14px;
  color: var(--accent);
  flex-shrink: 0;
  margin-top: 1px;
}

.wk-tree-admin-shell-note,
.wk-recents-admin-shell {
  margin: 4px 0 0;
  color: var(--text-dim);
  font-size: 10.5px;
  line-height: 1.45;
}

.wk-recents-admin-shell {
  list-style: none;
  padding: 0 var(--s-4);
}

.wk-search-btn[aria-disabled="true"] {
  opacity: 0.55;
  cursor: not-allowed;
}

.admin-main {
  justify-content: stretch;
  padding: var(--s-7) var(--s-6) var(--s-9);
}

.admin-main .wk-content {
  max-width: min(1180px, calc(100vw - var(--s-6) * 2));
}

#admin-state {
  width: 100%;
}

#admin-state[data-state="locked"] .admin-unlocked,
#admin-state[data-state="unlocked"] .admin-lock {
  display: none;
}

.admin-lock {
  min-height: calc(100vh - var(--topbar-h) - var(--s-7) - var(--s-9));
  display: grid;
  place-items: center;
}

.admin-lock-card {
  width: min(520px, 100%);
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--bg-sidebar);
  padding: var(--s-7);
  box-shadow: 0 18px 56px rgba(0, 0, 0, 0.22);
}

.admin-lock-badge {
  display: inline-flex;
  align-items: center;
  min-height: 22px;
  padding: 0 8px;
  border: 1px solid var(--border);
  border-radius: 4px;
  color: var(--accent);
  background: var(--accent-dim);
  font-size: 10px;
  font-weight: 600;
  line-height: 1;
  text-transform: uppercase;
}

.admin-lock-title {
  margin: var(--s-4) 0 var(--s-2);
  font-size: 1.5em;
}

.admin-lock-lead,
.admin-lock-footnote {
  color: var(--text-dim);
  font-size: 12px;
  line-height: 1.6;
}

.admin-lock form {
  display: grid;
  gap: var(--s-3);
  margin-top: var(--s-5);
}

.admin-lock label {
  color: var(--text-dim);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
}

.admin-lock input {
  min-height: 38px;
  border: 1px solid var(--border);
  border-radius: 4px;
  background: var(--bg-main);
  color: var(--text-main);
  font: inherit;
  padding: 0 var(--s-3);
  outline: none;
}

.admin-lock input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--accent-dim);
}

.admin-lock button,
.btn,
.iconbtn {
  border: 1px solid var(--border);
  border-radius: 4px;
  background: var(--accent);
  color: var(--bg-main);
  cursor: pointer;
  font: inherit;
  font-size: 11px;
  font-weight: 600;
  line-height: 1;
}

.admin-lock button {
  min-height: 38px;
  padding: 0 var(--s-4);
  text-align: center;
}

.admin-lock button:hover,
.btn:hover,
.iconbtn:hover {
  filter: brightness(1.08);
}

.admin-lock button:disabled,
.btn:disabled,
.iconbtn:disabled {
  cursor: not-allowed;
  opacity: 0.48;
  filter: none;
}

.admin-lock-err {
  min-height: 18px;
  color: var(--danger, #ff6b6b);
  font-size: 11px;
}

.admin-lock-footnote {
  margin-top: var(--s-5);
  padding-top: var(--s-4);
  border-top: 1px solid var(--border);
}

.admin-lock-footnote .prompt {
  color: var(--text-main);
  font-size: 10.5px;
  margin-bottom: var(--s-2);
}

.admin-unlocked {
  width: 100%;
}

.admin-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(320px, 380px);
  gap: var(--s-5);
  align-items: start;
}

.admin-list,
.admin-actions {
  min-width: 0;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--bg-sidebar);
}

.admin-list {
  overflow: hidden;
}

.admin-list-header {
  min-height: 48px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--s-3);
  padding: 0 var(--s-4);
  border-bottom: 1px solid var(--border);
}

.admin-list-title {
  color: var(--text-main);
  font-size: 12px;
  font-weight: 600;
}

.admin-list-count {
  color: var(--text-dim);
  font-size: 11px;
  font-variant-numeric: tabular-nums;
}

#admin-articles {
  list-style: none;
  margin: 0;
  padding: 0;
}

.admin-row {
  display: grid;
  grid-template-columns: minmax(220px, 1fr) minmax(150px, 220px);
  gap: var(--s-3);
  align-items: center;
  padding: var(--s-3) var(--s-4);
  border-bottom: 1px solid var(--border);
  cursor: pointer;
}

.admin-row:last-child {
  border-bottom: none;
}

.admin-row:hover,
.admin-row.current {
  background: var(--accent-dim);
}

.admin-row-main {
  min-width: 0;
}

.admin-row-slug {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  min-width: 0;
  color: var(--text-main);
  font-size: 12px;
  font-weight: 600;
  line-height: 1.45;
}

.admin-row-tema,
.admin-actions-tema,
.admin-actions-hint {
  color: var(--text-dim);
  font-size: 10.5px;
  line-height: 1.45;
}

.admin-row-released {
  display: inline-flex;
  align-items: center;
  max-width: 100%;
  min-height: 18px;
  padding: 0 6px;
  border: 1px solid var(--border);
  border-radius: 4px;
  color: var(--accent);
  background: var(--accent-dim);
  font-size: 9.5px;
  font-weight: 600;
  line-height: 1;
  text-transform: uppercase;
}

.admin-row-pwd {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: var(--s-2);
  min-width: 0;
}

.admin-row-pwd .pwd,
.admin-actions-pwd code {
  display: inline-flex;
  align-items: center;
  max-width: 100%;
  min-height: 28px;
  overflow: hidden;
  padding: 0 var(--s-2);
  border: 1px solid var(--border);
  border-radius: 4px;
  background: var(--bg-main);
  color: var(--text-main);
  font-size: 11px;
  line-height: 1;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.admin-row-actions,
.admin-actions-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: var(--s-2);
}

.admin-row-actions {
  grid-column: 1 / -1;
  justify-content: flex-start;
}

.admin-actions-buttons {
  justify-content: flex-end;
}

.btn {
  min-height: 30px;
  padding: 0 var(--s-3);
  white-space: nowrap;
}

.btn-secondary {
  background: transparent;
  color: var(--text-main);
}

.btn-secondary:hover {
  border-color: var(--accent);
  background: var(--accent-dim);
}

.iconbtn {
  width: 30px;
  height: 30px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 30px;
  padding: 0;
  background: transparent;
  color: var(--text-main);
}

.iconbtn:hover {
  border-color: var(--accent);
  background: var(--accent-dim);
}

.admin-actions {
  position: sticky;
  top: calc(var(--topbar-h) + var(--s-5));
  padding: var(--s-4);
}

.admin-actions-empty {
  display: grid;
  place-items: center;
  min-height: 180px;
  color: var(--text-dim);
  font-size: 12px;
}

.admin-actions-header {
  padding-bottom: var(--s-3);
  border-bottom: 1px solid var(--border);
}

.admin-actions-slug {
  color: var(--text-main);
  font-size: 13px;
  font-weight: 600;
  line-height: 1.45;
  overflow-wrap: anywhere;
}

.admin-actions-pwd {
  margin: var(--s-4) 0;
}

.admin-actions-pwd code {
  width: 100%;
  justify-content: flex-start;
  min-height: 34px;
}

.admin-actions-hint {
  margin: 0 0 var(--s-4);
}

.admin-actions-buttons + .admin-actions-buttons {
  margin-top: var(--s-2);
}

.admin-empty {
  list-style: none;
  padding: var(--s-5);
  color: var(--text-dim);
  font-size: 12px;
}

.admin-toast {
  position: fixed;
  right: var(--s-5);
  bottom: var(--s-5);
  z-index: 1000;
  max-width: min(420px, calc(100vw - var(--s-5) * 2));
  transform: translateY(12px);
  opacity: 0;
  pointer-events: none;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-sidebar);
  color: var(--text-main);
  padding: var(--s-3) var(--s-4);
  font-size: 12px;
  line-height: 1.45;
  box-shadow: 0 14px 42px rgba(0, 0, 0, 0.28);
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.admin-toast.show {
  transform: translateY(0);
  opacity: 1;
}

.admin-toast[data-kind="error"] {
  border-color: var(--danger, #ff6b6b);
}

.admin-toast[data-kind="success"] {
  border-color: var(--success, #7ad66d);
}

@media (max-width: 1180px) {
  .admin-grid {
    grid-template-columns: 1fr;
  }

  .admin-actions {
    position: static;
  }
}

@media (max-width: 760px) {
  .admin-main {
    padding: var(--s-5) var(--s-3) var(--s-7);
  }

  .admin-main .wk-content {
    max-width: 100%;
  }

  .admin-lock-card {
    padding: var(--s-5);
  }

  .admin-row {
    grid-template-columns: 1fr;
    gap: var(--s-2);
  }

  .admin-row-pwd,
  .admin-row-actions,
  .admin-actions-buttons {
    justify-content: flex-start;
  }

  .btn {
    flex: 1 1 auto;
  }
}
