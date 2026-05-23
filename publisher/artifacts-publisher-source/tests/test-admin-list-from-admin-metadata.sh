#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
RENDER_ADMIN_SCRIPT="${SOURCE_ROOT}/scripts/render-admin.py"
TMP_PARENT="${TMP_PARENT:-${SOURCE_ROOT}/.test-tmp/admin-list-from-admin-metadata-tests}"

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
const { webcrypto } = require('crypto');

const adminHtmlPath = process.argv[2];
const html = fs.readFileSync(adminHtmlPath, 'utf8');

if (!html.includes('/_admin.enc')) {
  throw new Error('admin client does not fetch encrypted admin metadata');
}
if (html.includes('Object.keys(vault')) {
  throw new Error('admin client still derives article list from vault keys');
}
for (const selector of [
  '.admin-grid',
  '.admin-row',
  '.admin-row-pwd',
  '.admin-row-actions',
  '.admin-actions',
  '.btn',
  '.iconbtn',
  '.admin-row-released',
  '@media (max-width: 760px)',
]) {
  if (!html.includes(selector)) {
    throw new Error(`admin visual contract selector missing: ${selector}`);
  }
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
global.crypto = webcrypto;
global.navigator = { clipboard: { writeText: async () => {} } };
global.confirm = () => true;
global.setTimeout = () => 0;
global.btoa = (value) => Buffer.from(value, 'binary').toString('base64');
global.atob = (value) => Buffer.from(value, 'base64').toString('binary');

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
            bu: 'staging',
            project: 'growth-engine',
            slug: 'admin-listed-article',
            title: 'Admin Listed Article',
            output_url: 'staging/growth-engine/admin-listed-article/',
            release_status: 'unreleased',
            scope: 'article',
          },
          {
            bu: 'gobbi',
            project: 'strategy',
            slug: 'metadata-only-article',
            title: 'Metadata Only Article',
            output_url: 'gobbi/strategy/metadata-only-article/',
            release_status: 'unreleased',
            scope: 'article',
          },
        ],
      };
    }
    if (blob === 'VAULT_BLOB') {
      return {
        'admin-listed-article': { password: 'from-vault', tema: 'legacy-tema' },
        'vault-only-article': { password: 'must-not-render', tema: 'legacy-tema' },
      };
    }
    throw new Error('unknown encrypted blob');
  },
};

vm.runInThisContext(mainMatch[1], { filename: 'admin-inline.js' });

(async () => {
  const ok = await window.__admin.unlock('masterpass');
  if (!ok) throw new Error('unlock returned false');

  const listHtml = elements['admin-articles'].innerHTML;
  const countText = elements['admin-list-count'].textContent;
  const state = window.__admin.state();

  if (state.adminArticles.length !== 2) {
    throw new Error(`expected 2 admin metadata records, got ${state.adminArticles.length}`);
  }
  if (!listHtml.includes('Admin Listed Article')) {
    throw new Error('metadata-backed article with vault password is missing');
  }
  if (!listHtml.includes('Metadata Only Article')) {
    throw new Error('metadata-backed article without vault password is missing');
  }
  if (listHtml.includes('vault-only-article') || listHtml.includes('must-not-render')) {
    throw new Error('vault-only record leaked into article list');
  }
  if (!listHtml.includes('sem senha no vault')) {
    throw new Error('metadata-only article did not render missing-vault state');
  }
  if (countText !== '2 artigos') {
    throw new Error(`expected count text "2 artigos", got ${JSON.stringify(countText)}`);
  }
  if (elements['admin-state'].dataset.state !== 'unlocked') {
    throw new Error('admin did not enter unlocked state');
  }
})().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
NODE

cat <<EOF
---
type: report
title: Admin List From Encrypted Metadata Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-05
  - admin-client
related:
  - '[[PHASE-05-ADMIN]]'
  - '[[CMS-CONTRACT]]'
---

# Admin List From Encrypted Metadata Test

## Executive Summary

The admin client now gets the article universe from decrypted \`_admin.enc\`.
The password vault can enrich matching rows, but a vault-only record does not
create an admin article row.

\`\`\`text
_admin.enc
   |
   v
article list

_passwords.enc
   |
   v
password merge only
\`\`\`

## Deterministic Checks

| Check | Result |
|---|---|
| Admin client fetches \`_admin.enc\` | PASS |
| Template no longer contains \`Object.keys(vault)\` list logic | PASS |
| Metadata-backed article with vault password renders | PASS |
| Metadata-backed article without vault password renders | PASS |
| Vault-only record is not listed as an article | PASS |
| Count comes from metadata records | PASS |
| Unlocked admin visual selectors are bundled into generated HTML | PASS |

## Images Analyzed

0
EOF
