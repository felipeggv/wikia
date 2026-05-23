---
type: report
title: Verificacao Final da Lane Publish Validation
created: 2026-05-23
tags:
  - wikia-cms
  - publish
  - validation
  - final-check
related:
  - '[[PHASE-05E-VERIFY-PUBLISH-VALIDATION]]'
  - '[[CMS-CONTRACT]]'
  - '[[PHASE-06-PUBLISH]]'
  - '[[PHASE-07-VALIDATION]]'
---

# Verificacao Final da Lane Publish Validation

## Resumo Executivo

Status: PASS.

A lane de publish/validation foi verificada sem alterar codigo de implementacao
e sem deploy. O fluxo atual valida o estado publico antes de declarar sucesso
em `--validate` e antes de `commit/push`, falha de forma visivel quando o helper
do vault esta ausente, preserva o caminho de `--dry-run`, mantem idempotencia e
sincroniza catalogo, busca, admin, BU, projeto e artigo a partir do estado CMS.

```text
raw/CMS state
   |
   v
publish.sh
   |
   +-- render public output
   +-- stage only allowed generated paths
   +-- validate-state.sh
   |
   +-- PASS: validation JSON / no push
   +-- FAIL: loud error before commit/push
```

## Escopo

| Item | Status | Evidencia | Mismatch |
|---|---:|---|---|
| `publish.sh` valida estado antes do resultado de publish | PASS | `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/publish.sh` linhas 28-48 e 750-799 | Nenhum |
| Falha alto se helper do vault estiver ausente | PASS | Simulacao temporaria sem `vault.mjs` retornou status `1` com `MODULE_NOT_FOUND` | Nenhum |
| `--dry-run` continua preservando workdir sem deploy | PASS | `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/publish.sh` linhas 743-747 e smoke test | Nenhum |
| Idempotencia de republicacao | PASS | `test-publish-idempotency.sh` confirma um unico registro canonico e dependent views atualizadas | Nenhum |
| Arquivos publicos sincronizados com CMS state | PASS | Testes de catalogo, busca, admin, BU, projeto, artigo e sync atomico passaram | Nenhum |
| Deploy/push real | PASS | Nao executado por requisito da tarefa | Nenhum |

## Comandos Executados

Executados a partir de:

```text
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation
```

### Suite Focada

| Comando | Status |
|---|---:|
| `bash publisher/artifacts-publisher-source/tests/test-publish-validation.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-publish-runs-state-validation.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-publish-idempotency.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-publish-private-source.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-publish-apply-pending.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-validate-state.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-validate-state-default-root.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-sync-cms-state-atomic.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-build-search-index-catalog.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-catalog-navigation-model.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-public-catalog-visibility.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-render-admin-cms-state.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-vault-mjs.sh` | PASS |
| `bash publisher/artifacts-publisher-source/tests/test-phase-07-smoke.sh` | PASS |

### Helper Vault Ausente

Este comando usa uma copia temporaria da source dentro da worktree, remove
somente o helper nessa copia e executa `publish.sh --rebuild-all --dry-run`.
O objetivo e provar que a ausencia de `vault.mjs` nao e escondida.

```bash
bash -lc 'set -euo pipefail
CHECK_ROOT=".tmp/missing-vault-helper-check"
rm -rf "$CHECK_ROOT"
mkdir -p "$CHECK_ROOT"
cp -R publisher/artifacts-publisher-source "$CHECK_ROOT/source"
rm "$CHECK_ROOT/source/scripts/vault.mjs"
printf "%s\n" "fixture-masterpass-missing-vault" > "$CHECK_ROOT/masterpass.txt"
set +e
WIKIA_PUBLISH_TMP_PARENT="$PWD/$CHECK_ROOT/workdirs" bash "$CHECK_ROOT/source/scripts/publish.sh" \
  --rebuild-all \
  --dry-run \
  --repo fixture/wiki \
  --masterpass-file "$CHECK_ROOT/masterpass.txt" \
  --validate \
  > "$CHECK_ROOT/out.txt" \
  2> "$CHECK_ROOT/err.txt"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  printf "FAIL missing vault helper was silently accepted\n"
  sed -n "1,120p" "$CHECK_ROOT/out.txt"
  sed -n "1,120p" "$CHECK_ROOT/err.txt"
  exit 1
fi
if ! grep -E "vault\\.mjs|MODULE_NOT_FOUND|Cannot find module" "$CHECK_ROOT/out.txt" "$CHECK_ROOT/err.txt" >/dev/null; then
  printf "FAIL missing vault helper failed without a clear vault error\n"
  sed -n "1,160p" "$CHECK_ROOT/err.txt"
  exit 1
fi
printf "PASS missing vault helper failed loudly with status %s\n" "$rc"'
```

Resultado:

```text
PASS missing vault helper failed loudly with status 1
```

Erro relevante observado:

```text
Error: Cannot find module '/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/.tmp/missing-vault-helper-check/source/scripts/vault.mjs'
code: 'MODULE_NOT_FOUND'
```

## Leitura de Codigo

| Arquivo | O que foi confirmado |
|---|---|
| `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/publish.sh` | `run_state_validation` chama `validate-state.sh --public-root "$GITPAGES" --json`; `--validate` inclui `state_validation` no JSON e sai com o status do validador; publish real aborta antes de commit/push se a validacao falhar. |
| `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/publish.sh` | Rebuild usa `node "$VAULT_MJS" pack-json` e `node "$VAULT_MJS" set` sem mascarar erro; se o helper sumir, o processo falha. |
| `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/validate-state.sh` | O validador cobre `raw.md` privado, segredo em texto puro, sidebar duplicada, marcador legado, temp plaintext, escopo admin publico, contagem stale e divergencia search/catalog. |

## Resultado

| Resultado | Valor |
|---|---:|
| Testes focados executados | 14 |
| Testes focados passando | 14 |
| Status bloqueado | 0 |
| Mismatches encontrados | 0 |
| Deploy executado | Nao |
| Imagens analisadas | 0 |

