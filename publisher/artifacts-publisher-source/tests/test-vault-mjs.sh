#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
VAULT_SCRIPT="${SOURCE_ROOT}/scripts/vault.mjs"
FIXTURE_DIR="${FIXTURE_DIR:-}"
EXPECTED_JSON="${EXPECTED_JSON:-}"
FIXTURE_VAULT="${FIXTURE_VAULT:-}"
TMP_PARENT="${TMP_PARENT:-${SOURCE_ROOT}/.test-tmp/vault-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

read_expected_masterpass() {
  node - "$EXPECTED_JSON" <<'NODE'
const fs = require('node:fs');
const expected = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (!expected.masterpass) throw new Error('expected.json missing masterpass');
process.stdout.write(expected.masterpass);
NODE
}

emit_expected_entries() {
  node - "$EXPECTED_JSON" <<'NODE'
const fs = require('node:fs');
const expected = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
for (const entry of expected.entries || []) {
  for (const key of ['slug', 'password', 'tema']) {
    if (!entry[key]) throw new Error(`fixture entry missing ${key}`);
  }
  process.stdout.write(`${entry.slug}\t${entry.password}\t${entry.tema}\n`);
}
NODE
}

assert_list() {
  local json_file="$1"
  local expected_count="$2"
  local expected_slugs_csv="$3"

  node - "$json_file" "$expected_count" "$expected_slugs_csv" <<'NODE'
const fs = require('node:fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const expectedCount = Number(process.argv[3]);
const expectedSlugs = process.argv[4].split(',').filter(Boolean).sort();
const actualSlugs = [...(payload.slugs || [])].sort();

if (payload.ok !== true) throw new Error('list response ok flag was not true');
if (payload.entries !== expectedCount) {
  throw new Error(`list count mismatch: expected ${expectedCount}, got ${payload.entries}`);
}
if (JSON.stringify(actualSlugs) !== JSON.stringify(expectedSlugs)) {
  throw new Error(`slug mismatch: expected ${expectedSlugs.join(',')}, got ${actualSlugs.join(',')}`);
}
NODE
}

assert_entry() {
  local json_file="$1"
  local expected_password="$2"
  local expected_tema="$3"
  local slug="$4"

  node - "$json_file" "$expected_password" "$expected_tema" "$slug" <<'NODE'
const fs = require('node:fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const expectedPassword = process.argv[3];
const expectedTema = process.argv[4];
const slug = process.argv[5];

if (payload.password !== expectedPassword) {
  throw new Error(`${slug} password did not round-trip`);
}
if (payload.tema !== expectedTema) {
  throw new Error(`${slug} tema mismatch: expected ${expectedTema}, got ${payload.tema}`);
}
NODE
}

assert_write_result() {
  local json_file="$1"
  local slug="$2"
  local expected_count="$3"

  node - "$json_file" "$slug" "$expected_count" <<'NODE'
const fs = require('node:fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const expectedSlug = process.argv[3];
const expectedCount = Number(process.argv[4]);

if (payload.ok !== true) throw new Error(`${expectedSlug} write ok flag was not true`);
if (payload.slug !== expectedSlug) throw new Error(`slug mismatch: expected ${expectedSlug}, got ${payload.slug}`);
if (payload.entries !== expectedCount) {
  throw new Error(`entry count mismatch: expected ${expectedCount}, got ${payload.entries}`);
}
NODE
}

assert_delete_result() {
  local json_file="$1"
  local slug="$2"
  local expected_existed="$3"
  local expected_count="$4"

  node - "$json_file" "$slug" "$expected_existed" "$expected_count" <<'NODE'
const fs = require('node:fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const expectedSlug = process.argv[3];
const expectedExisted = process.argv[4] === 'true';
const expectedCount = Number(process.argv[5]);

if (payload.ok !== true) throw new Error(`${expectedSlug} delete ok flag was not true`);
if (payload.slug !== expectedSlug) throw new Error(`slug mismatch: expected ${expectedSlug}, got ${payload.slug}`);
if (payload.existed !== expectedExisted) {
  throw new Error(`delete existed mismatch: expected ${expectedExisted}, got ${payload.existed}`);
}
if (payload.entries !== expectedCount) {
  throw new Error(`entry count mismatch after delete: expected ${expectedCount}, got ${payload.entries}`);
}
NODE
}

assert_init_result() {
  local json_file="$1"
  local expected_count="$2"

  node - "$json_file" "$expected_count" <<'NODE'
const fs = require('node:fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const expectedCount = Number(process.argv[3]);

if (payload.ok !== true) throw new Error('init ok flag was not true');
if (!payload.path) throw new Error('init response missing path');
if (payload.entries !== expectedCount) {
  throw new Error(`init count mismatch: expected ${expectedCount}, got ${payload.entries}`);
}
NODE
}

require_file "$VAULT_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

if [[ -z "$FIXTURE_DIR" ]]; then
  FIXTURE_DIR="${RUN_DIR}/fixture-vault"
  EXPECTED_JSON="${FIXTURE_DIR}/expected.json"
  FIXTURE_VAULT="${FIXTURE_DIR}/_passwords.enc"
  mkdir -p "$FIXTURE_DIR"
  cat > "$EXPECTED_JSON" <<'JSON'
{
  "masterpass": "fixture-masterpass-vault",
  "entries": [
    {
      "slug": "fixture-alpha",
      "password": "fixture-alpha-pass",
      "tema": "fixtures"
    },
    {
      "slug": "fixture-beta",
      "password": "fixture-beta-pass",
      "tema": "fixtures"
    }
  ]
}
JSON
  WIKIA_MASTERPASS="fixture-masterpass-vault" node "$VAULT_SCRIPT" init "$FIXTURE_VAULT" --force >/dev/null
  WIKIA_MASTERPASS="fixture-masterpass-vault" node "$VAULT_SCRIPT" set "$FIXTURE_VAULT" fixture-alpha fixture-alpha-pass --tema fixtures >/dev/null
  WIKIA_MASTERPASS="fixture-masterpass-vault" node "$VAULT_SCRIPT" set "$FIXTURE_VAULT" fixture-beta fixture-beta-pass --tema fixtures >/dev/null
else
  EXPECTED_JSON="${EXPECTED_JSON:-${FIXTURE_DIR}/expected.json}"
  FIXTURE_VAULT="${FIXTURE_VAULT:-${FIXTURE_DIR}/_passwords.enc}"
fi

require_file "$EXPECTED_JSON"
require_file "$FIXTURE_VAULT"

WORK_VAULT="${RUN_DIR}/_passwords.enc"
EMPTY_VAULT="${RUN_DIR}/empty.enc"
MASTERPASS="$(read_expected_masterpass)"
cp "$FIXTURE_VAULT" "$WORK_VAULT"

INITIAL_LIST="${RUN_DIR}/list-initial.json"
env WIKIA_MASTERPASS="$MASTERPASS" node "$VAULT_SCRIPT" list "$WORK_VAULT" > "$INITIAL_LIST"
assert_list "$INITIAL_LIST" 2 "fixture-alpha,fixture-beta"

while IFS=$'\t' read -r slug password tema; do
  GET_JSON="${RUN_DIR}/get-${slug}.json"
  env WIKIA_MASTERPASS="$MASTERPASS" node "$VAULT_SCRIPT" get "$WORK_VAULT" "$slug" > "$GET_JSON"
  assert_entry "$GET_JSON" "$password" "$tema" "$slug"
done < <(emit_expected_entries)

NEW_SLUG="fixture-gamma"
NEW_PASSWORD="fixture-gamma-pass"
NEW_TEMA="fixtures"
SET_JSON="${RUN_DIR}/set-${NEW_SLUG}.json"
printf '%s' "$MASTERPASS" | node "$VAULT_SCRIPT" set "$WORK_VAULT" - "$NEW_SLUG" "$NEW_PASSWORD" "$NEW_TEMA" > "$SET_JSON"
assert_write_result "$SET_JSON" "$NEW_SLUG" 3

AFTER_SET_LIST="${RUN_DIR}/list-after-set.json"
env WIKIA_MASTERPASS="$MASTERPASS" node "$VAULT_SCRIPT" list "$WORK_VAULT" > "$AFTER_SET_LIST"
assert_list "$AFTER_SET_LIST" 3 "fixture-alpha,fixture-beta,fixture-gamma"

GET_NEW_JSON="${RUN_DIR}/get-${NEW_SLUG}.json"
env WIKIA_MASTERPASS="$MASTERPASS" node "$VAULT_SCRIPT" get "$WORK_VAULT" "$NEW_SLUG" > "$GET_NEW_JSON"
assert_entry "$GET_NEW_JSON" "$NEW_PASSWORD" "$NEW_TEMA" "$NEW_SLUG"

DEL_JSON="${RUN_DIR}/del-${NEW_SLUG}.json"
env WIKIA_MASTERPASS="$MASTERPASS" node "$VAULT_SCRIPT" del "$WORK_VAULT" "$NEW_SLUG" > "$DEL_JSON"
assert_delete_result "$DEL_JSON" "$NEW_SLUG" true 2

FINAL_LIST="${RUN_DIR}/list-final.json"
env WIKIA_MASTERPASS="$MASTERPASS" node "$VAULT_SCRIPT" list "$WORK_VAULT" > "$FINAL_LIST"
assert_list "$FINAL_LIST" 2 "fixture-alpha,fixture-beta"

INIT_JSON="${RUN_DIR}/init-empty.json"
printf '%s' "$MASTERPASS" | node "$VAULT_SCRIPT" init "$EMPTY_VAULT" - > "$INIT_JSON"
assert_init_result "$INIT_JSON" 0

EMPTY_LIST="${RUN_DIR}/list-empty.json"
env WIKIA_MASTERPASS="$MASTERPASS" node "$VAULT_SCRIPT" list "$EMPTY_VAULT" > "$EMPTY_LIST"
assert_list "$EMPTY_LIST" 0 ""

cat <<EOF
---
type: report
title: Vault Fixture Round-trip Test
created: $(date +%F)
tags:
  - wikia-cms
  - vault
  - fixture-test
related:
  - '[[PHASE-02-VAULT]]'
---

# Vault Fixture Round-trip Test

## Executive Summary

The fixture vault round-trip test passed. It used only fake fixture data from:

\`\`\`text
${FIXTURE_DIR}
\`\`\`

## Flow

\`\`\`text
fixture _passwords.enc
   |
   v
temporary working copy
   |
   +-- list existing fake slugs
   +-- get existing fake entries
   +-- set one new fake slug
   +-- get the new fake slug
   +-- delete the new fake slug
   +-- confirm original fake slugs remain
   +-- init and list an empty fake vault
\`\`\`

## Results

| Check | Result |
|---|---|
| Fixture vault copied before mutation | PASS |
| Initial list count equals 2 | PASS |
| Existing fixture entries decrypt correctly | PASS |
| New fixture slug can be set | PASS |
| New fixture slug can be read back | PASS |
| New fixture slug can be deleted | PASS |
| Final list returns to original 2 slugs | PASS |
| Empty fake vault can be initialized and listed | PASS |
| Password output in evidence | none |

## Slugs Verified

- fixture-alpha
- fixture-beta
- fixture-gamma

EOF
