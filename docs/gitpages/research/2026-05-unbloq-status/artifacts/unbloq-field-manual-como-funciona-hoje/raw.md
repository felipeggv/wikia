# unbloq — Field Manual: Como Funciona Hoje

> Documento operacional. Foco no **estado atual**, não no roadmap.
> Última coleta de dados: 2026-05-12. Sessão Maestro: `cb52fb7a-9b3a-4e19-a8ef-27f88d6bceda`.

::: callout info Resumo Operativo
**O unbloq é uma cabine de comando local para Felipe Gobbi orquestrar a sua operação multi-BU.** Hoje, **funciona** como pipeline de captura → categorização guiada via IA (Codex CLI) → handoff estruturado → render+apply ClickUp real → registro de execution_run → sincronização para review.

**Não funciona ainda:** ingestão WhatsApp/áudio/imagem, escrita de custom fields no ClickUp, review queue Epic 5, launch real do Maestro, UI.

**Métrica de hoje:** 14 tabelas SQLite, 17 eventos canônicos, 19 comandos CLI sob 6 scopes, ~12.000 LOC produção em TypeScript, 162 testes verdes, 63 commits desde 2026-05-03.
:::

---

## 1. Arquitetura Real

```text
┌──────────────────────────────────────────────────────────────────┐
│                          unbloq monorepo                          │
│                                                                   │
│  packages/                                                        │
│    cli/         <- 19 comandos sob 6 scopes (3144 LOC)            │
│    core/        <- engines deterministicas + IA wrappers (6287)   │
│    db/          <- SQLite com 14 tabelas + repositories (1985)    │
│    connectors/                                                    │
│      clickup/   <- gateway cup CLI subprocess (779)               │
│      gcal/      <- scaffold (1 linha)                             │
│      maestro/   <- scaffold (1 linha)                             │
│    ui/          <- scaffold (1 linha) — aguarda design brief      │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘

CLI orquestra
   |
   v
core (puro, deterministico) chama codex-runner pra IA
   |                                 |
   v                                 v
db (SQLite persistente)         clickup connector (cup CLI subprocess)
                                     |
                                     v
                                ClickUp real
```

::: callout tip Princípios estruturais
1. **Core é puro:** zero I/O. Funções deterministicas + tipos.
2. **DB usa SQLite via better-sqlite3:** schema declarado em uma string SQL gigante. Single writer.
3. **CLI é o entry point único:** o usuário só fala com CLI; CLI fala com core+db+connectors.
4. **Conectores externos são subprocess:** ClickUp via `cup`, IA via `codex exec`. Nada de chave API direta no código.
5. **Idempotência por idempotency_key:** cada entidade tem chave determinística; segunda chamada com mesmos inputs = duplicate, não nova row.
:::

---

## 2. Os 8 Sub-Sistemas Destrinchados

### A. Staging Capture

📍 **Onde mora:** `packages/core/src/staging.ts` + `packages/cli/src/index.ts` (handler `handleStagingAdd`)

🎯 **O que faz:** registra todo input bruto (texto, futuramente áudio/imagem) como um `staging_item` único, identificado por hash determinístico. Detecta duplicatas sem perder o original.

📥 **Input:** `--source <whatsapp|cli|quick_add|clickup_backlog>` + `--text "..."`

🔧 **Processing:** `captureRawInput()` normaliza o texto, computa `content_hash` SHA-256, gera `staging_item.id` estável, checa duplicate via `listStagingItems`, retorna `CaptureRawInputResult`.

📤 **Output:**
- `staging_items` row (id, source, raw_text, normalized_text, status='draft', idempotency_key, content_hash, external_refs, created_at)
- Evento: `staging_item_captured` (sempre) ou `duplicate_seen` (se duplicate)

🔌 **CLI:**
```bash
unbloq staging add --source whatsapp --text "Lançar feature de relatório semanal" --db ./db.sqlite --json
```

✅ **Exemplo real (smoke 2026-05-12):**
```json
{
  "id": "stg_2f897d325eb78c8f",
  "source": "cli",
  "normalized_text": "Lançar feature de relatório executivo semanal no unbloq",
  "status": "draft",
  "content_hash": "a5f9...3c1b"
}
```

⚠️ **Limitações:** só aceita `--text`. Não tem ingest WhatsApp nem áudio/imagem ainda (existe pipeline em `unblocq-pai` pra portar).

---

### B. DRCCD Pipeline

📍 **Onde mora:** `packages/core/src/drccd.ts` (455 LOC, sem IA)

🎯 **O que faz:** roda os 5 estágios canônicos (Descarregar → Reunir → Categorizar → Contextualizar → Distribuir) deterministicamente sobre um `staging_item`, classificando-o em uma `DrccdDistributionTarget`.

📥 **Input:** `StagingItem` + `DrccdPipelineContext` (opcional: now, defaultBu, existingItems)

🔧 **Processing:** 5 estágios sequenciais, cada um retorna `DrccdStageResult` com `status` (passed|blocked) + `reason_codes`.

| Estágio | Detecta |
|---|---|
| descarregar | raw_text presente, token_count, source |
| reunir | bu, profile, duplicate_of |
| categorizar | intent (implementation/draft/research/manual_decision/discard/unknown), action_verbs, risk_signals |
| contextualizar | summary, requires_human_decision, missing_inputs |
| distribuir | target (veredito/human_gate/needs_more_context), allowed_to_promote |

📤 **Output:** `DrccdPipelineResult` com `blocked: boolean`, `confidence: high|medium|low`, evento `drccd_pipeline_ran`.

🔌 **CLI:** roda automaticamente dentro de `unbloq staging decide <id>`.

✅ **Limitação importante:** DRCCD por si só usa **heurística regex**, sem IA. É RÁPIDO mas dá resultados secos. O DRD Wizard (sub-sistema D abaixo) é a camada IA-assistida sobre essa engine.

---

### C. VEREDITO

📍 **Onde mora:** `packages/core/src/veredito.ts`

🎯 **O que faz:** decide a rota final de um item via 4 entradas: `ai_task_decision`, `q_matrix`, `completeness signals` (vindos do DRCCD), e regras canônicas. Devolve `execution_mode` (autorun/spec_autorun/collab/manual) e `internal_route`.

📥 **Input:** resultado DRCCD + flags do usuário (`--ai-task-decision`, `--q-matrix`, `--confidence`).

🔧 **Processing:** tabela determinística:
```text
AI-GO + execute_now  → autorun
AI-DRAFT + execute_now → spec_autorun
YOURS → manual
SKIP → none
```
Cruza com completeness (storyContractComplete, requiresBusinessDecision, etc) e re-classifica para `YOURS/manual` quando blocker aparecer.

📤 **Output:** `VereditoResult` com `internal_route`, `execution_mode`, `disposition`, `confidence`, `reason_codes` + evento `veredito_applied`.

🔌 **CLI:** dentro de `unbloq staging decide <id>`.

✅ **Exemplo real (do smoke 2026-05-12 item 3):** Texto = "Corrigir bug crítico de vazamento de memória no DRCCD" + AI-GO forçado → `execution_mode: autorun`, `internal_route: autorun`, `confidence: high`.

---

### D. HumanGate (autonomy gate)

📍 **Onde mora:** `packages/core/src/human-gate.ts` (224 LOC)

🎯 **O que faz:** decide se a IA pode continuar sozinha ou se precisa parar e chamar humano. **8 checks deterministicos**, executados em ordem.

🔧 **Os 8 checks:**

```text
1. missing_specification        story_contract_complete = false           → blocked
2. business_decision             requires_business_decision = true          → blocked
3. functional_ambiguity          has_functional_ambiguity = true            → blocked
4. human_only_action             requires_human_only_action = true          → blocked
5. external_write_approval       has_unapproved_external_write = true       → blocked
6. confidence_floor              confidence = 'low'                          → blocked
7. confidence_for_autorun        medium + continue/dry_run (autorun path)   → blocked (NOVO 4-0C)
8. research_context              research sem context                        → blocked
```

📤 **Output:** `HumanGateResult` com `human_gate_required: boolean`, `allowed_next_action: continue|research|draft|dry_run|ask_human|stop`, `reason_codes[]`, evento `human_gate_evaluated`.

🔌 **CLI:** dentro de `unbloq staging decide <id>`.

✅ **Decisão chave (commit 7c6c1f5):** Confidence `medium` **bloqueia** caminho de execução (continue/dry_run) — só permite caminho de informação (research/draft). Isso forma a base do "autorun não tolera incerteza média".

---

### E. Planning + Timeline

📍 **Onde mora:** `packages/core/src/operational-estimate.ts`, `planning-blocks.ts`, `timeline-read-model.ts` + handlers CLI.

🎯 **O que faz:** estima custo operacional (tokens IA + capacidade humana), cria blocos de tempo, monta timeline por dia/semana.

🔌 **CLI:**
```bash
unbloq planning estimate <staging_id> --tool clickup --retry-risk medium
unbloq planning observe-estimate <estimate_id> --actual-total-tokens 4200
unbloq planning block create <staging_id> --starts-at "..." --ends-at "..." --bu vibework --session-type focus_work
unbloq planning timeline --mode day --day 2026-05-12 --bu vibework
```

📤 **Eventos:** `operational_estimate_recorded`, `estimate_observation_recorded`, `time_block_planned`, `session_task_link_created`, `timeline_read_model_rebuilt`, `timeline_cli_queried`.

⚠️ **Limitação:** funciona isolado. **Não está integrado** com o DRD wizard (você ainda precisa rodar `planning estimate` manualmente após `drd new`).

---

### F. Handoff Payload v1

📍 **Onde mora:** `packages/core/src/handoff-payload.ts` (758 LOC)

🎯 **O que faz:** transforma um `staging_item` decidido em um pacote de execução autocontido (`HandoffPayload`) que um agente IA pode consumir sem chat history. Versionado (`handoff_payload_v1`), idempotente.

📤 **HandoffPayload contém:**
- objective, context, sources (com required/present flags), constraints, micro_steps, anti_scope, definition_of_done, review_instructions, reason_codes, trace_refs
- execution_mode + ai_task_decision + human_gate_required (do VEREDITO/HumanGate)

🔌 **CLI:**
```bash
unbloq handoff build --staging-item-id stg_X --db ./db.sqlite --json
```

📤 **Evento:** `handoff_payload_created` (entity_type=handoff_payload).

✅ **Garantias:**
- `external_write_performed: false` sempre (anti-scope respeitado)
- `maestro_launched: false` sempre
- Idempotency key = SHA256(`unbloq:handoff_payload:<staging_id>:build:handoff_payload_v1:<sources_hash>`)
- 15 validation checks confirmando estrutura completa

---

### G. ClickUp Render + Apply

::: comparator
### render-handoff (preview, sem write)
- Renderiza HandoffPayload como Markdown ClickUp-safe (sem Mermaid, sem pipe tables).
- Persiste `clickup_handoff_previews` row + emite `clickup_handoff_preview_created`.
- `apply_contract.apply = false` SEMPRE.
- 10 seções obrigatórias: Handoff Briefing, Objective, Sources, Constraints, Micro Steps, Anti Scope, Definition of Done, Review Instructions, Reason Codes, Trace Refs.
- Sanitiza paths `/Users/...` para evitar references locais ilegíveis pro humano que lê no ClickUp.

### apply-handoff (escreve no ClickUp real)
- **Triple gate** antes de qualquer write:
  1. flag `--apply` presente
  2. env `UNBLOQ_CLICKUP_ALLOW_WRITE=1`
  3. `preview.validation.status === 'valid'` + `apply_contract.apply === false`
- Chama `cup update <task_id> --description "<markdown>"` via subprocess.
- Persiste `clickup_handoff_applications` row + emite **2 eventos** em transação: `clickup_handoff_applied` (entity=application) + `handoff_card_ready` (entity=clickup_task com entity_id=target_task_id).
- Idempotency key derivada de `preview_id + target_task_id`: segunda chamada com mesmo destino = duplicate, não escreve de novo.
:::

⚠️ **Limitação importante:** apply-handoff só escreve a **description** do card ClickUp. **NÃO escreve custom fields** (`ai_task_decision`, `execution_mode`, `bu`, `blocq_id`). Felipe sinalizou isso como bug em review.

---

### H. Execution Run + Sync

📍 **Onde mora:** `packages/core/src/execution-run.ts` + `execution-run-sync.ts`

🎯 **O que faz:** registra a intenção de executar um handoff via Maestro (preview, sem disparar) e depois sincroniza o output do runner externo de volta para gerar um `review_item`.

#### Preview (não dispara nada):

```bash
unbloq execution preview \
  --application-id cua_X \
  --arpb3-doc-path .maestro/playbooks/UNBLOQ-X.md \
  --target-agent-id unbloq-cc \
  --db ./db.sqlite --json
```

Emite `execution_run_preview_created` (status=`queued`, `maestro_launched: false` sempre).

#### Sync (recebe runner output, redact secrets, cria review_item):

```bash
unbloq execution sync \
  --execution-run-id exr_X \
  --runner-status succeeded \
  --output-summary "pipeline completed" \
  --artifact-ref file:///tmp/build.log \
  --db ./db.sqlite --json
```

Aplica `normalizeExecutionStatusUpdate` (mapeia 15 raw statuses → 5 canônicos), valida lifecycle (`queued → succeeded/failed/needs_review`), redacta secrets via regex (`sk-*`, `pk_*`, `Bearer *`, `*_TOKEN`, `*_SECRET`, `*_API_KEY`, `*_PASSWORD`, `password=*`), cria `review_item` com `required_decision` derivada (succeeded→approve, failed+retry→rerun, failed sem retry→escalate).

Emite **2 eventos** em transação: `execution_run_status_changed` + `execution_run_synced_for_review`.

⚠️ **Limitação:** o runner real é **Maestro**, mas a chamada não dispara o Maestro de fato. O `launch_plan` é só uma cota auditável de "comando que SERIA executado".

---

## 3. DRD Wizard — A Camada IA-Assistida (commit 6478eb4)

::: accordion-seq

### STEP 1/8 — Collecting

Lê **brain dump multi-linha do stdin** (até linha vazia ou Ctrl-D). Sem `--text` obrigatório. Felipe digita texto livre PT-BR como pensa.

### STEP 2/8 — Extracting (Codex CLI)

Invoca `codex exec --ephemeral --skip-git-repo-check --json --output-last-message <file>` com o prompt PT-BR `DRD_EXTRACT_PROMPT_PT`. Codex devolve `DrdExtractResponse` com array de items, cada um com `raw_text`, `short_name ≤70 chars`, `notes`.

Tempo: ~10-15s. Custo: pago via ChatGPT account do Felipe.

### STEP 3/8 — Extraction Approval (humano)

CLI imprime os items numerados. Felipe aprova ou edita short_name por índice. Approval é interativa via readline, com flag `UNBLOQ_DRD_AUTO_APPROVE=1` para smoke não-interativo.

### STEP 4/8 — Priming (Codex CLI)

Codex enriquece cada item com `bu` (vibework/vitascience/aleyemma/automedia/all-in/personal/gobbi), `bloq_id_hint` (slug sugerido ou null), `context_summary ≤200 chars`, `has_decision_implication`.

### STEP 5/8 — Priming Approval (humano)

Felipe revisa contexto. Pode editar `bu`, `bloq_id_hint`, `context_summary` por índice.

### STEP 6/8 — Scoring (Codex CLI)

Codex propõe **4 checks deterministicos** por item:
- `acao_clara`: true/false
- `tem_tool_match`: sempre false (placeholder até inventory existir)
- `decisao_humana`: true/false
- `urgencia`: hoje | semana | mes | sem_data

### STEP 7/8 — Final Approval + Computação

`computeCategoryFromChecks()` deriva a categoria deterministicamente:

```text
acao_clara=false                    → SKIP
decisao_humana=true                 → AI-DRAFT
tem_tool_match=true                 → AI-GO
acao_clara=true sem tool_match      → AI-GO (low_confidence)
```

Felipe pode editar qualquer check, recategorização é recomputada na hora.

### STEP 8/8 — Staging + Done

Items aprovados (não-SKIP) viram `staging_items` reais via `captureRawInput` + `saveStagingCapture`. Output JSON final com sumário e IDs.

:::

::: callout success Smoke real validado 2026-05-12

Dump enviado:
```text
lancar feature de relatorio executivo semanal no unbloq
ligar pro lab adriana sobre lote de fevereiro
pesquisar concorrentes de pricing da vita para Q2
corrigir bug critico no drccd que esta vazando memoria
talvez pensar em conteudo de video futuramente
```

Saída em ~40 segundos (3 chamadas Codex):

| # | short_name | bu | bloq_id_hint | checks | categoria |
|---|---|---|---|---|---|
| 0 | Lançar feature de relatório executivo semanal no unbloq | vibework | unbloq-relatorio-executivo-semanal | acao=T decisao=T urg=sem_data | **AI-DRAFT** |
| 1 | Ligar para o lab Adriana sobre lote de fevereiro | vitascience | null | acao=T decisao=T urg=sem_data | **AI-DRAFT** |
| 2 | Pesquisar concorrentes de pricing da Vita para Q2 | vitascience | vita-pricing-q2 | acao=T decisao=T urg=mes | **AI-DRAFT** |
| 3 | Corrigir bug crítico de vazamento de memória no DRCCD | vibework | drccd-memory-leak | acao=T decisao=F urg=sem_data | **AI-GO** |
| 4 | Pensar em conteúdo de vídeo futuramente | vibework | null | acao=F decisao=T urg=sem_data | **SKIP** |

session_id: `drd_4ee672480e3d7014` · 4 staging_items criados, 1 descartado.

Codex acertou:
- Detectou que "ligar pro lab" é vitascience pelo nome "Adriana" (cliente conhecida).
- Detectou "Q2" como urgência `mes`.
- Marcou "talvez pensar em" como `acao_clara=false` → SKIP.

:::

---

## 4. 14 Tabelas SQLite

| Tabela | Papel | Quem escreve |
|---|---|---|
| `staging_items` | inbox local de capturas brutas | staging add + drd new (passo 8) |
| `domain_events` | event log append-only (todos eventos canônicos) | TODOS os handlers |
| `drd_sessions` | state machine do DRD wizard (1 row por dump) | drd new + drd resume |
| `handoff_payloads` | payloads v1 versionados (com blob JSON full) | handoff build |
| `clickup_handoff_previews` | preview markdown ClickUp (sem write real) | clickup render-handoff |
| `clickup_handoff_applications` | registro de cup update REAL no ClickUp | clickup apply-handoff |
| `execution_runs` | preview de execução (com launch_plan Maestro) | execution preview + sync update |
| `review_items` | itens prontos para revisão humana | execution sync |
| `operational_estimates` | estimativas de tokens/capacidade | planning estimate |
| `estimate_observations` | variance entre estimado e real | planning observe-estimate |
| `time_blocks` | blocos de tempo planejados | planning block |
| `routine_sessions` | sessões de routine (focus/handoff/review) | planning block |
| `session_task_links` | links task↔session | planning block |
| `timeline_read_model_snapshots` | snapshots de timeline pra cache | planning timeline (rebuild) |

::: callout info Single-writer SQLite
Driver: `better-sqlite3`. Sem WAL mode explícito. **Race condition se 2 processos CLI rodarem em paralelo** — limitação conhecida, aceita pra single-user MVP.
:::

---

## 5. 17 Eventos Canônicos (Audit Trail)

```text
ENTRADA
   staging_item_captured       (+ duplicate_seen se duplicate)
   drccd_pipeline_ran
   veredito_applied
   human_gate_evaluated

PLANNING
   operational_estimate_recorded (ou estimate_observation_recorded)
   time_block_planned (ou time_block_plan_rejected)
   session_task_link_created
   timeline_read_model_rebuilt
   timeline_cli_queried

HANDOFF / CLICKUP
   handoff_payload_created
   clickup_handoff_preview_created
   clickup_distribution_confirmed (ou clickup_handoff_applied)
   handoff_card_ready                  (entity=clickup_task)

EXECUTION
   execution_run_preview_created
   execution_run_status_changed
   execution_run_synced_for_review     (entity=review_item)
```

::: callout warn Honest gap
O **DRD wizard NÃO emite domain_events próprios** ainda (drd_session_created, drd_session_completed). O smoke fresco mostrou só `staging_item_captured` × 4 no event log após `drd new` completo. A state machine vive em `drd_sessions` row, mas eventos do wizard não chegam ao log unificado. **Será corrigido em próxima onda**.
:::

---

## 6. Pipeline Ponta-A-Ponta (validado)

```text
INPUT TEXTO (brain dump)
   |
   v
[1] staging add OU drd new (com Codex CLI)
   |
   v
staging_item_captured  +  drccd_pipeline_ran  +  veredito_applied
                            +  human_gate_evaluated
   |
   v
[2] handoff build
   |
   v
handoff_payload_created
   |
   v
[3] clickup render-handoff  (preview, apply=false)
   |
   v
clickup_handoff_preview_created
   |
   v
[4] clickup apply-handoff  (--apply + env + gate)
   |
   v
clickup_handoff_applied  +  handoff_card_ready
                            (ClickUp card description escrita de verdade)
   |
   v
[5] execution preview --application-id <cua_X>
   |
   v
execution_run_preview_created
   |
   v
[6] execution sync --runner-status succeeded
   |
   v
execution_run_status_changed  +  execution_run_synced_for_review
                                  (review_item criado)
```

Total: até **11 eventos persistidos** no `domain_events` para um único item que percorre o pipeline inteiro.

---

## 7. O Que NÃO Funciona Hoje (lista honesta)

::: callout warn Anti-scope explícito ou pendente
- **WhatsApp ingestion** — `~/Documents/VibeworkV2/apps/unblocq-pai/src/adapters/waha.js` existe, NÃO foi portado.
- **Áudio / imagem transcription** — `unblocq-pai/src/media/transcriber.js` (Whisper) + `vision.js` existem, NÃO foram portados.
- **Apply de custom fields ClickUp** — `apply-handoff` só escreve description, NÃO escreve `ai_task_decision`, `execution_mode`, `bu`, `blocq_id`. Felipe flagou em review.
- **Review queue (Epic 5)** — 4 stories no backlog (UNBLOQ-5-01 a 5-04). Nenhum comando CLI ainda.
- **Maestro launch real** — `execution preview` registra o launch_plan, mas nunca dispara o Maestro de fato. Cota auditável só.
- **UI** — `packages/ui/` é scaffold de 1 linha. Bloqueada por design brief (CLAUDE.md rule).
- **Daily report** — DFR-001 deferido. Tabela `daily_reports` não existe.
- **Profile JSON** — `~/.unbloq/clickup-profile.json` precisa ser criado manualmente (sem comando `config init`).
- **DRD events no log unificado** — drd_session lifecycle não emite domain_events ainda.
- **Integração planning ↔ DRD** — `planning estimate` precisa ser chamado manualmente após `drd new`.
- **WAL mode SQLite** — 2 processos CLI paralelos podem lockar.
- **Migrations** — schema sem versionamento; mudança de coluna quebra DB existente.
- **all-in workspace** — cup tem profile `allin`, mas reorganização não foi feita (modelo de Lists-por-pessoa não bate com topology canônica).
- **Output em português 100%** — `handoff build` ainda gera markdown em inglês.
:::

---

## 8. CLI Completo (todos os 19 comandos)

| Scope | Comando | Função |
|---|---|---|
| `staging` | `add` | captura input bruto |
| `staging` | `list` | lista staging_items |
| `staging` | `show <id>` | inspeciona item |
| `staging` | `decide <id>` | roda DRCCD+VEREDITO+HumanGate |
| `staging` | `import-clickup-backlog --list <id>` | importa cards ClickUp como staging |
| `drd` | `new` | wizard interativo de brain dump |
| `drd` | `resume` | retoma sessão drd pausada (`--abort` cancela) |
| `drd` | `list` | lista sessões DRD |
| `handoff` | `build --staging-item-id <id>` | gera HandoffPayload v1 |
| `clickup` | `config` | mostra profile ClickUp atual |
| `clickup` | `render-handoff --payload-id <id>` | gera markdown preview ClickUp |
| `clickup` | `apply-handoff --preview-id <id> --apply` | escreve description no ClickUp real (triple gate) |
| `clickup` | `distribute <staging_id>` | preview create-task (legacy) |
| `clickup` | `preview-create-task --input <file>` | preview a partir de JSON externo |
| `planning` | `estimate <staging_id>` | estima tokens + capacidade |
| `planning` | `observe-estimate <estimate_id>` | registra variance |
| `planning` | `block create` | cria time_block + routine_session |
| `planning` | `timeline --mode day|week` | consulta timeline |
| `execution` | `preview --application-id <id>` | registra execution_run + launch_plan |
| `execution` | `sync --runner-status <status>` | sincroniza output runner → review_item |

::: callout tip Flags universais úteis
- `--db <path>` — override do SQLite path (default `~/.unbloq/db.sqlite`)
- `--json` — saída JSON em vez de texto
- `--received-at <iso>` — fixa timestamp (importante pra idempotência em testes)
- `UNBLOQ_DRD_AUTO_APPROVE=1` env — pula approvals do DRD wizard
- `UNBLOQ_CLICKUP_ALLOW_WRITE=1` env — destrava apply-handoff real
- `UNBLOQ_CUP_BINARY=<path>` env — override do binário cup pra testes
- `UNBLOQ_CODEX_BINARY=<path>` env — override do binário codex pra testes
:::

---

## 9. Próximos Passos (1 parágrafo só)

A próxima onda planejada migra o ClickUp para o modelo **workspace-topology** (1 list = 1 branch = 1 agent = 1 cwd) com lists tipadas (`build/`, `fix/`, `improve/`, `run/`, `decide/`, `research/`), implementa o **shell wrapper** `~/bin/unbloq` para invocação direta sem `node --experimental-strip-types`, conecta o **project field** custom do ClickUp ao DRD priming step, e abre os 4 cards de **Epic 5** (review queue) como a próxima frente executável. Em paralelo, o pipeline de **transcrição áudio/imagem** será portado de `unblocq-pai` pra destravar ingestão via WhatsApp.

---

## Apêndice: Identificação técnica

- **Repo:** `/Users/felipegobbi/Documents/VibeworkV2/apps/unbloq`
- **Branch atual:** `feature/rotina-perfeita-cc`
- **Último commit:** `6478eb4 feat(drd): brain-dump wizard guiado com Codex CLI (DRD)`
- **Stack:** Node 25+, TypeScript via `--experimental-strip-types`, better-sqlite3, cup CLI, codex CLI
- **Modelo IA usado pelo DRD:** Codex CLI default (modelo da conta ChatGPT do Felipe)
- **Tests verdes:** 162 (8 wizard + 9 codex-runner + 145 core legacy/Wave1/Epic4 + 24 db + 40 cli + 11 clickup)
- **Profiles cup ativos:** gobbi, allin, vita

> Documento gerado pelo agente `unbloq-cc` em 2026-05-12 a partir de inspeção direta de código + smoke real fresco.
