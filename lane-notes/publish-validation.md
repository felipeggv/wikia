---
type: analysis
title: Descoberta da Lane de Validação de Publicação
created: 2026-05-23
tags:
  - wikia-cms
  - publish
  - validation
  - lane-discovery
related:
  - '[[CMS-CONTRACT]]'
  - '[[PHASE-06-PUBLISH]]'
  - '[[PHASE-07-VALIDATION]]'
---

# Descoberta da Lane de Validação de Publicação

## Resumo Executivo

A lane de validação de publicação é o caixa da loja do Wikia: ela confere quais arquivos gerados podem sair para o GitHub Pages, garante que o modo de validação não faz push, e deveria confirmar que o pacote público não vazou fonte privada nem saiu fora do catálogo CMS.

```text
private-source/{bu}/{project}/{slug}/raw.md
   |
   v
publish.sh
   |
   +-- gera paginas, catalogo, busca e admin
   +-- filtra paths permitidos em docs/gitpages
   +-- --validate retorna JSON, sem push
   |
   v
validate-state.sh
   |
   +-- sem raw.md privado no publico
   +-- sem segredo em texto puro
   +-- sidebar, busca e catalogo em sincronia
```

A implementação atual já tem proteções úteis, mas a validação está dividida em duas checagens separadas:

| Camada | O que confere | Lacuna atual |
|---|---|---|
| `publish.sh --validate` | Staging explícito, sem push, JSON de validação | Não chama `validate-state.sh` antes de declarar sucesso |
| `validate-state.sh --public-root ... --json` | Regras do output público gerado | O caminho padrão parece resolver para o lugar errado se `--public-root` não for passado |
| Testes shell | Publish validation, private source, idempotência, apply-pending, smoke flow | Testes usam caminho absoluto antigo de Auto Run e podem testar código velho ou escrever fora desta worktree |

## Propriedade

| Área | Arquivos principais | Responsabilidade |
|---|---|---|
| Entrada de publicação | `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/publish.sh` | Clonar repo alvo, renderizar output, lidar com `--validate`, `--dry-run`, `--rebuild-all`, `--apply-pending`, stagear só arquivos gerados permitidos e fazer push só no modo real |
| Validador de estado público | `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/validate-state.sh` | Varrer output público procurando `raw.md` privado, segredo em texto puro, sidebar duplicada, marcador legado, contagem desatualizada e divergência entre busca/catalogo |
| Fila admin pendente | `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/apply-pending.py` | Aplicar intents de release, rotate, remove e scope antes do rebuild completo |
| Contrato de catálogo | `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts/public_catalog.py` | Manter um registro público seguro por BU/project/slug e impedir vazamento de título, corpo ou tags privadas em registros gateados |
| Testes focados | `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/tests/test-publish-validation.sh` e testes irmãos | Provar modo de validação, filtro de staging, separação de private-source, idempotência, fila pendente e smoke flow |

## Achados

### O Que Já Funciona

| Checagem | Evidência |
|---|---|
| Stage amplo de Git é evitado | `publish.sh` coleta mudanças só em `docs/.nojekyll` e `docs/gitpages`, rejeita renames/copies e usa `git add --` com paths explícitos |
| Modo de validação evita push | `publish.sh --validate` emite JSON com `validate_only: true`, `would_push: false`, `changed`, `workdir` e `staged_paths`, depois sai antes de commit/push |
| Masterpass em texto puro via CLI é rejeitado | `publish.sh --masterpass` só aceita `-`; rebuild-all resolve segredo por stdin, arquivo ou `WIKIA_MASTERPASS` |
| Publicação com private-source tem caminho previsto | Publicação de artigo único pode copiar a fonte para `--private-source-root`, remover `raw.md` público e publicar HTML/catalogo/busca sanitizados |
| Rebuild-all atualiza superfícies CMS juntas | Rebuild-all sincroniza estado CMS, gera `_admin.enc`, reconstrói artigos, home, busca, admin, páginas de BU e páginas de projeto |
| `validate-state.sh` tem regras públicas úteis | Confere `raw.md` gateado, segredo aparente, wrappers duplicados, `wk-tree-tema`, contagens de sidebar, chaves duplicadas de catálogo e URLs divergentes entre busca/catalogo |

```text
allowlist do publish.sh
   |
   +-- permitido: docs/gitpages/.../index.html + catalogo/admin/busca/ledgers
   +-- permitido: deletar raw.md publico legado
   +-- recusado: paths inesperados, renames, copies
```

### Riscos

| Prioridade | Risco | Por que importa |
|---|---|---|
| Alta | `publish.sh --validate` não roda `validate-state.sh` | Uma publicação pode passar no "modo validação" mesmo gerando HTML público com problemas de catalogo/sidebar/busca/privacidade. Analogia: o caixa confirma o preço, mas ninguém olha se o pacote está certo. |
| Alta | Testes hardcodeiam `/Users/felipegobbi/Documents/VibeworkV2/Auto Run Docs/2026-05-19-Wikia-CMS-Refactor` | Rodar testes desta worktree pode validar uma cópia velha do código ou criar arquivos fora da lane atual. O harness deve apontar para o repo atual por padrão. |
| Alta | O root padrão de `validate-state.sh` provavelmente está errado | Pelo layout atual, o padrão vira algo como `publisher/wikia/docs/gitpages`, não `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/docs/gitpages`; hoje os chamadores precisam passar `--public-root`. |
| Média | Existem dois contratos JSON de validação | `publish.sh --validate` reporta staging; `validate-state.sh --json` reporta issues de estado. CI ou Auto Run precisam de um comando claro para decidir passou/falhou. |
| Média | `publish.sh` ainda monta `TREE_JSON`/`RECENTS_JSON` a partir de paths legados `research/...` | A árvore principal do artigo vem do catálogo, mas "recentes" pode ficar vazio/desatualizado para Wave 2 BU/project se não for reconstruído pelo catálogo. |
| Média | A allowlist de stage é estreita de propósito | Isso é bom para segurança, mas qualquer novo tipo de arquivo gerado em `docs/gitpages` vai falhar até ser explicitamente permitido e coberto por teste. |

## Mudanças Propostas

1. Fazer `publish.sh --validate` rodar `validate-state.sh --public-root "$GITPAGES" --json` depois do render e antes de retornar sucesso.
2. Incluir o payload da validação de estado dentro do JSON de validação do publish:

```json
{
  "validate_only": true,
  "would_push": false,
  "changed": true,
  "staged_paths": [],
  "state_validation": {
    "ok": true,
    "issue_count": 0,
    "issues": []
  }
}
```

3. Rodar a mesma validação de estado antes do commit/push real. Se falhar, abortar antes de `git commit`, `git push` ou `gh api`.
4. Corrigir o root padrão de `validate-state.sh` para o `docs/gitpages` da app/worktree, mantendo `--public-root` como override explícito.
5. Tornar testes portáveis derivando `SOURCE_ROOT` da localização do próprio teste, com overrides opcionais por ambiente:

```text
arquivo de teste
   |
   v
../scripts
   |
   v
implementacao da worktree atual
```

6. Usar um diretório temporário permitido, como `${TMPDIR:-/tmp}/wikia-tests`, exceto quando o chamador passar `WIKIA_TEST_TMP_PARENT`.
7. Extrair o setup duplicado de fake `git`/`gh` para um helper compartilhado só depois da correção de portabilidade; não criar helper antes do formato repetido estabilizar.
8. Reconstruir "recentes" de artigos a partir do catálogo público, não apenas de diretórios legados `research/...`.

## Testes Focados Para Rodar Depois

Estes testes só devem ser rodados depois da correção dos caminhos hardcoded, porque os scripts atuais escrevem na pasta antiga de Auto Run.

| Teste | Objetivo |
|---|---|
| `publisher/artifacts-publisher-source/tests/test-publish-validation.sh` | Provar que validate mode stageia só paths gerados aprovados, rejeita masterpass inseguro e nunca faz push |
| `publisher/artifacts-publisher-source/tests/test-validate-state.sh` | Provar que output público limpo passa e output sujo falha em todas as regras do validador |
| `publisher/artifacts-publisher-source/tests/test-publish-private-source.sh` | Provar que `raw.md` privado fica fora de `docs/gitpages` e catalogo/busca/home públicos ficam sanitizados |
| `publisher/artifacts-publisher-source/tests/test-publish-idempotency.sh` | Provar que republicar o mesmo BU/project/slug atualiza um único registro canônico e páginas dependentes |
| `publisher/artifacts-publisher-source/tests/test-publish-apply-pending.sh` | Provar que intents de release, rotate, remove e scope reconstruem todos os outputs dependentes com segurança |
| `publisher/artifacts-publisher-source/tests/test-phase-07-smoke.sh` | Provar o caminho completo: vault, migração, renderers, admin shell e publish dry-run |

Adicionar dois testes focados:

| Novo Teste | Resultado Esperado |
|---|---|
| `test-publish-runs-state-validation.sh` | Um output gerado propositalmente inválido faz `publish.sh --validate` sair com erro e nenhum push é tentado |
| `test-validate-state-default-root.sh` | Rodar `validate-state.sh --json` a partir da worktree valida o `docs/gitpages` atual por padrão, enquanto `--public-root` ainda sobrescreve o alvo |

## Testes Não Rodados

Nenhum teste foi executado nesta tarefa de descoberta. Os testes shell atuais usam um caminho antigo hardcoded e criariam arquivos temporários fora da área de escrita permitida desta lane.

## Imagens Analisadas

0
