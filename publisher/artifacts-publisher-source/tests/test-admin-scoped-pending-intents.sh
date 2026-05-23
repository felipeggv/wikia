#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${WIKIA_TEST_SOURCE_ROOT:-$(cd "$TEST_DIR/.." && pwd)}"
APP_ROOT="$(cd "$SOURCE_ROOT/../.." && pwd)"
RENDER_ADMIN_SCRIPT="${SOURCE_ROOT}/scripts/render-admin.py"
TMP_PARENT="${WIKIA_TEST_TMP_PARENT:-$APP_ROOT/.tmp/wikia-tests/admin-scoped-pending-intents-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$RENDER_ADMIN_SCRIPT"
require_file "${SOURCE_ROOT}/templates/admin.html.tpl"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

PUBLIC_ROOT="${RUN_DIR}/gitpages"
mkdir -p "$PUBLIC_ROOT"

THEME_JSON='{"bgMain":"#0c0e0c","bgSidebar":"#0f100f","border":"#111311","textMain":"#f2f2c0"}'
WIKI_BASE='https://fixture.test/wikia'

python3 "$RENDER_ADMIN_SCRIPT" "$PUBLIC_ROOT" "$THEME_JSON" "$WIKI_BASE" \
  > "${RUN_DIR}/render-admin.stdout" 2> "${RUN_DIR}/render-admin.stderr"

ADMIN_HTML="${PUBLIC_ROOT}/admin/index.html"
require_file "$ADMIN_HTML"

node - "$ADMIN_HTML" <<'NODE'
const fs = require('fs');
const vm = require('vm');

const adminHtmlPath = process.argv[2];
const html = fs.readFileSync(adminHtmlPath, 'utf8');

for (const forbidden of [
  'encryptVault',
  'pending.vault',
  'pending.released',
  'pending.rotations',
  'docs/gitpages/_passwords.enc',
  'docs/gitpages/_released.json',
  '/tmp/wikia-clone',
  'git commit -m',
  'git push',
  'commit script',
]) {
  if (html.includes(forbidden)) {
    throw new Error(`admin browser still contains direct public-output mutation marker: ${forbidden}`);
  }
}

if (!html.includes('data-action="remove"')) {
  throw new Error('remove admin action is not rendered');
}
if (!html.includes('data-action="scope-project"') || !html.includes('data-action="scope-bu"')) {
  throw new Error('project/BU scope admin actions are not rendered');
}

const mainMatch = html.match(/<script>\s*(\(function \(\) \{\s*'use strict';[\s\S]*?\n\}\)\(\);)\s*<\/script>/);
if (!mainMatch) {
  throw new Error('could not extract admin inline script');
}

const elements = {};
function makeElement(id) {
  return {
    id,
    value: '',
    innerHTML: '',
    textContent: '',
    dataset: {},
    classList: { add() {}, remove() {} },
    addEventListener() {},
    focus() {},
    select() {},
    closest() { return null; },
  };
}
function getElementById(id) {
  if (!elements[id]) elements[id] = makeElement(id);
  return elements[id];
}

global.document = {
  documentElement: { dataset: { wikiBase: 'https://fixture.test/wikia' } },
  getElementById,
};
global.window = {};
global.navigator = { clipboard: { writeText: async () => {} } };
global.confirm = () => true;
global.setTimeout = () => 0;

const responses = {
  'https://fixture.test/wikia/_admin.enc': 'ADMIN_BLOB',
  'https://fixture.test/wikia/_passwords.enc': 'VAULT_BLOB',
  'https://fixture.test/wikia/_released.json': '[]',
  'https://fixture.test/wikia/_pending-changes.json': '{}',
};

global.fetch = async (url) => ({
  ok: Object.prototype.hasOwnProperty.call(responses, url),
  status: Object.prototype.hasOwnProperty.call(responses, url) ? 200 : 404,
  text: async () => responses[url] || '',
});

window.WikiaVault = {
  decryptVault: async (blob, masterpass) => {
    if (masterpass !== 'masterpass') throw new Error('bad masterpass');
    if (blob === 'ADMIN_BLOB') {
      return {
        records: [
          {
            article_id: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            bu: 'staging',
            project: 'growth-engine',
            slug: 'admin-listed-article',
            key: 'staging/growth-engine/admin-listed-article',
            title: 'Admin Listed Article',
            output_url: 'staging/growth-engine/admin-listed-article/',
            release_status: 'unreleased',
            scope: 'article',
          },
          {
            article_id: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            bu: 'gobbi',
            project: 'strategy',
            slug: 'remove-target',
            key: 'gobbi/strategy/remove-target',
            title: 'Remove Target',
            output_url: 'gobbi/strategy/remove-target/',
            release_status: 'unreleased',
            scope: 'article',
          },
          {
            article_id: 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
            bu: 'vita',
            project: 'sales',
            slug: 'scope-project-candidate',
            key: 'vita/sales/scope-project-candidate',
            title: 'Scope Project Candidate',
            output_url: 'vita/sales/scope-project-candidate/',
            release_status: 'unreleased',
            scope: 'article',
          },
          {
            article_id: 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
            bu: 'aleyemma',
            project: 'launch',
            slug: 'scope-bu-candidate',
            key: 'aleyemma/launch/scope-bu-candidate',
            title: 'Scope BU Candidate',
            output_url: 'aleyemma/launch/scope-bu-candidate/',
            release_status: 'unreleased',
            scope: 'project',
          },
        ],
      };
    }
    if (blob === 'VAULT_BLOB') {
      return {
        'admin-listed-article': { password: 'from-vault', tema: 'growth-engine' },
        'remove-target': { password: 'remove-secret', tema: 'strategy' },
      };
    }
    throw new Error('unknown encrypted blob');
  },
};

vm.runInThisContext(mainMatch[1], { filename: 'admin-inline.js' });

function assertUnchanged(label, actual, expected) {
  const actualJson = JSON.stringify(actual);
  const expectedJson = JSON.stringify(expected);
  if (actualJson !== expectedJson) {
    throw new Error(`${label} mutated browser-side: expected ${expectedJson}, got ${actualJson}`);
  }
}

(async () => {
  const ok = await window.__admin.unlock('masterpass');
  if (!ok) throw new Error('unlock returned false');

  const initial = window.__admin.state();
  const initialReleased = JSON.parse(JSON.stringify(initial.released));
  const initialVault = JSON.parse(JSON.stringify(initial.vault));

  await window.__admin.releaseArticle('staging/growth-engine/admin-listed-article');
  await window.__admin.rotatePassword('staging/growth-engine/admin-listed-article');
  await window.__admin.removeArticle('gobbi/strategy/remove-target');
  await window.__admin.changeArticleScope('vita/sales/scope-project-candidate', 'project');
  await window.__admin.changeArticleScope('aleyemma/launch/scope-bu-candidate', 'bu');

  const state = window.__admin.state();
  const pending = state.pending;

  assertUnchanged('released ledger', state.released, initialReleased);
  assertUnchanged('password vault', state.vault, initialVault);

  if (pending.schema_version !== 1) throw new Error('pending schema_version missing');
  if (pending.release.length !== 1) throw new Error(`expected 1 release intent, got ${pending.release.length}`);
  if (pending.rotate.length !== 1) throw new Error(`expected 1 rotate intent, got ${pending.rotate.length}`);
  if (pending.remove.length !== 1) throw new Error(`expected 1 remove intent, got ${pending.remove.length}`);
  if (pending.scope.length !== 2) throw new Error(`expected 2 scope intents, got ${pending.scope.length}`);
  if (pending.intents.length !== 5) throw new Error(`expected 5 indexed intents, got ${pending.intents.length}`);

  const releaseIntent = pending.release[0];
  if (releaseIntent.key !== 'staging/growth-engine/admin-listed-article') {
    throw new Error('release intent is not scoped by BU/project/slug');
  }
  if (releaseIntent.target_release_status !== 'released') {
    throw new Error('release intent missing target_release_status');
  }

  const rotateIntent = pending.rotate[0];
  if (rotateIntent.vault_key !== 'admin-listed-article') {
    throw new Error('rotate intent did not record the matched vault key');
  }
  if (JSON.stringify(rotateIntent).includes('from-vault')) {
    throw new Error('rotate intent leaked an existing password');
  }

  const removeIntent = pending.remove[0];
  if (removeIntent.key !== 'gobbi/strategy/remove-target') {
    throw new Error('remove intent is not scoped by BU/project/slug');
  }
  if (removeIntent.target_release_status !== 'removed') {
    throw new Error('remove intent missing target_release_status');
  }

  const scopeTargets = pending.scope.map((intent) => `${intent.key}:${intent.from_scope}->${intent.to_scope}`).sort();
  const expectedScopeTargets = [
    'aleyemma/launch/scope-bu-candidate:project->bu',
    'vita/sales/scope-project-candidate:article->project',
  ];
  if (JSON.stringify(scopeTargets) !== JSON.stringify(expectedScopeTargets)) {
    throw new Error(`scope intents mismatch: ${JSON.stringify(scopeTargets)}`);
  }

  const actionsHtml = elements['admin-actions'].innerHTML;
  for (const forbidden of ['docs/gitpages/_passwords.enc', 'docs/gitpages/_released.json', 'from-vault', 'remove-secret']) {
    if (actionsHtml.includes(forbidden)) {
      throw new Error(`pending panel leaked direct output or password marker: ${forbidden}`);
    }
  }
  if (!actionsHtml.includes('docs/gitpages/_pending-changes.json')) {
    throw new Error('pending panel does not stage _pending-changes.json');
  }
  if (!actionsHtml.includes('copy-pending-json')) {
    throw new Error('pending panel does not expose JSON-only copy action');
  }
})().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
NODE

cat <<EOF
---
type: report
title: Admin Scoped Pending Intents Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-05
  - admin-client
related:
  - '[[PHASE-05-ADMIN]]'
  - '[[CMS-CONTRACT]]'
---

# Admin Scoped Pending Intents Test

## Executive Summary

The admin client queues scoped pending intents for release, rotate, remove, and
project/BU scope changes. It does not mutate the release ledger or encrypted
password vault in browser memory.

\`\`\`text
admin click
   |
   v
scoped pending intent
   |
   v
_pending-changes.json only
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Release action queues scoped intent | PASS |
| Rotate action queues scoped intent without generating a browser password | PASS |
| Remove action queues scoped intent | PASS |
| Project scope change queues scoped intent | PASS |
| BU scope change queues scoped intent | PASS |
| Browser release ledger remains unchanged | PASS |
| Browser password vault remains unchanged | PASS |
| Pending panel stages only \`_pending-changes.json\` | PASS |
| Pending panel does not expose fixture passwords | PASS |

## Images Analyzed

0
EOF
