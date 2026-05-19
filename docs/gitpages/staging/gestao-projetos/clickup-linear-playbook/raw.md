---
bu: staging
project: gestao-projetos
slug: clickup-linear-playbook
title: "Playbook Soviético: ClickUp com disciplina de Linear"
date: 2026-05-19
tags: [clickup, linear, playbook, gestao, processo, ia-agent]
gate: null
---

# Playbook Soviético: ClickUp com disciplina de Linear

> **Audiência:** times de 2-5 executores (humanos ou IA) operando em alta performance.
> **Promessa:** transformar o ClickUp de board bagunçado em funil único de produção, com gate de qualidade, hierarquia clara e fluxo executável por agente.

Linear venceu o mindshare porque impôs disciplina onde o resto deixou liberdade. ClickUp tem flexibilidade demais — e flexibilidade sem disciplina vira lixo. Este playbook é a disciplina.

---

## TL;DR — em 90 segundos

| Pilar | Decisão | Por quê |
|---|---|---|
| **Funil** | `BACKLOG → READY → IN PROGRESS → IN REVIEW → DONE → CANCELED` | Um e só um. Sem variações por time. |
| **Gate** | Só vira `Ready` quando 7 campos estão preenchidos | `Ready` é contrato, não promessa. |
| **Hierarquia** | Goal → Épico (Folder) → Projeto (List) → Issue (Task) → Checklist | Cada nível tem dono e cadência distintos. |
| **Estimativa** | Quem executa, estima. Sempre. | PO define prioridade. Executor define esforço. |
| **WIP** | 1 issue por executor em `In Progress` | Context switching mata produtividade. |
| **PR** | Max 400 linhas | Acima disso, rejeita. |
| **Backlog** | Max 50 issues, limpa toda sexta | Backlog infinito = lixo. |

---

## 1. O Funil Único

```
BACKLOG → READY → IN PROGRESS → IN REVIEW → DONE → CANCELED
```

| Status | Quem move | Condição de entrada | Condição de saída |
|---|---|---|---|
| **Backlog** | PO (ou PO-Agent) | Issue criada, com ou sem campos completos | Critérios completos + priorizada |
| **Ready** | PO | Issue totalmente qualificada | Executor puxou para sprint |
| **In Progress** | Executor | Executor começou o trabalho | PR aberta |
| **In Review** | Executor | PR aberta, aguardando review | PR aprovada e mergeada |
| **Done** | Automação | PR mergeada + deploy (se aplicável) | — |
| **Canceled** | PO | Escopo obsoleto, duplicada, ou fora de prioridade | — |

### Regra central

**`Ready` é o contrato.** Quando uma issue entra em `Ready`, ela está pronta para ser puxada por qualquer executor sem precisar de mais contexto. Tudo que não está `Ready` ainda está em gestação — mora no `Backlog`.

### Regras de ouro

- Executor **NUNCA** cria issue direto em `In Progress`
- Nada fica mais de 48h em `In Review` — se ficou, está bloqueado
- `Ready` tem no máximo 2-3 sprints de trabalho à frente
- Issues recém-criadas ficam em `Backlog` — a triagem acontece **dentro** do `Backlog`, não fora dele
- Se tem mais de 10 issues no `Backlog` sem critérios preenchidos, alguém não está fazendo triage

### Gate de Qualidade: Backlog → Ready

Uma issue só avança para `Ready` quando **todos** os campos abaixo estão preenchidos. O PO-Agent (ou PO humano) valida:

- [ ] Contexto preenchido (por quê?)
- [ ] Comportamento esperado descrito
- [ ] Critérios de aceite verificáveis (mínimo 2)
- [ ] Escopo técnico definido (se executor = IA)
- [ ] Estimativa acordada
- [ ] Prioridade atribuída (P0-P3)
- [ ] Dependências identificadas (ou "nenhuma")

**Se faltar qualquer um** → a issue **fica no Backlog** com comentário do que falta. Só vira `Ready` quando o gate passar.

### A View "Triage Queue"

Crie uma View salva chamada `Triage Queue` com o filtro:

```
status = Backlog
AND (
  critérios_de_aceite IS EMPTY
  OR escopo_técnico IS EMPTY
  OR estimativa IS EMPTY
)
```

Essa view é a fila de trabalho do PO (ou PO-Agent) — o que precisa ser qualificado antes de virar `Ready`. Não polui o funil, aparece quando o PO abre, some quando o trabalho é feito.

---

## 2. Hierarquia Completa

A confusão clássica é misturar camadas. Cada nível tem dono, propósito e cadência distintos.

```
GOAL (Objetivo estratégico — ClickUp Goals)
  └─ ÉPICO (Iniciativa — ClickUp Folder)
       └─ PROJETO (Entregável concreto — ClickUp List)
            └─ ISSUE (Unidade de trabalho — ClickUp Task)
                 └─ CHECKLIST (Passos de execução — Checklist nativa)
```

### Mapeamento ClickUp Definitivo

| Camada | ClickUp Native | Executável? | Tem PR? |
|---|---|---|---|
| Goal | Goal | Não | Não |
| Épico | Folder | Não | Não |
| Projeto | List | Não | Não |
| Issue | Task | **Sim** | **Sim** |
| Checklist | Checklist | Não | Não |

> **Por que Checklist e não Sub-task?** Sub-tasks no ClickUp ocupam o mesmo namespace de Tasks — isso polui o board e conflita com workflows que usam sub-tasks para paralelização (ex: worktrees). Checklist nativa é leve, não aparece no board, e cumpre o papel.

### Camada por camada

**Goal — Objetivo Estratégico.** Métrica ou resultado de negócio mensurável. Transcende épicos individuais. Cadência trimestral ou mensal. Quem cria: PO/fundador. Exemplos: *"Aumentar MRR em 30% até Q3"*, *"Reduzir churn para abaixo de 5%"*.

**Épico — Iniciativa.** Iniciativa estratégica de alto nível, dura semanas ou meses, contribui para um Goal. Quem cria: PO/fundador. A description do Folder contém o briefing estratégico: contexto, motivação, constraints, links. Qualquer executor lê isso antes de tocar em qualquer issue do épico. **Não é executável.** Não tem PR, não tem branch. É o norte.

**Projeto.** Entregável concreto dentro de um épico. Dura 1-4 sprints. Quem cria: PO/líder técnico. Também não é executável diretamente — agrupa issues.

**Issue — Unidade de Trabalho.** A menor unidade que gera valor. Tem branch, tem PR, tem deploy. Quem cria: PO escreve, executor valida. Quem estima: **sempre quem vai executar** (humano ou IA). Tamanho ideal: 1-3 dias (2-5 pontos). **Regra de ouro: se não cabe em 1 PR de 100-400 linhas, quebre.**

**Checklist — Passos de Execução.** Passos dentro de uma issue. Não é mini-issue. Quem cria: o executor que vai fazer. Nunca mais de 5 itens, nunca mais de 1 nível de profundidade. Não tem branch própria, não tem PR própria.

### Exemplo visual

```
Goal: Aumentar MRR em 30% até Q3
  └─ Folder (Épico): Lançar Área de Membros
     │  description: "Contexto: validação com 50 beta users..."
     │
     ├─ List (Projeto): Sistema de Autenticação
     │    ├─ Task: Criar endpoint /auth/login
     │    │    └─ Checklist: [schema, controller, validação, 3 testes]
     │    └─ Task: Implementar OAuth Google
     │         └─ Checklist: [credentials, rota, callback, redirect]
     │
     └─ List (Projeto): Dashboard do Aluno
          ├─ Task: Layout da sidebar
          └─ Task: API de progresso do curso
```

---

## 3. Template de Issue — quando o executor é IA

Quando o executor é humano, contexto implícito compensa uma issue rasa — o dev sabe o codebase, tem memória de sprints anteriores, pergunta no Slack.

**Quando o executor é IA, tudo que não está escrito não existe.** A IA opera literalmente sobre o que lê. Não assume, não pergunta (a menos que instruída), não "sabe" o que você quis dizer.

A issue bem escrita é a **mesa de trabalho** da IA — um workspace observável onde o PO acompanha progresso em tempo real. A IA pode (e deve) alterar a issue durante a execução: adicionar/remover checklists, atualizar descrição, postar comentários com decisões tomadas. Tudo fica rastreável.

### Template obrigatório

```markdown
## Contexto
Por que isso precisa ser feito? Qual o impacto no negócio? (1-3 frases)
Link para o Goal/Épico que justifica.

## Comportamento Esperado
O que o usuário vai ver/fazer quando terminar?
Descreva o estado final, não o caminho.

## Critérios de Aceite
- [ ] Critério verificável 1 (pass/fail, sem ambiguidade)
- [ ] Critério verificável 2
- [ ] Critério verificável 3
→ Cada critério deve ser testável com um "sim" ou "não".
→ Se não consegue verificar, não é critério — é desejo.

## Escopo Técnico
- Arquivos afetados: [lista explícita de paths]
- Stack/frameworks: [Next.js 14, Prisma, Tailwind, etc.]
- Dependências: [APIs, libs, serviços externos]
- Constraints: [não usar X, manter compatibilidade com Y]
- Branch base: [main, develop, feature/xyz]

## Referências
- Design: [link Figma / screenshot]
- Issues relacionadas: #123, #456
- Docs relevantes: [link]
- Código de referência: [path:linha ou PR anterior]

## Fora de Escopo (O que NÃO fazer)
- Não mexer em [módulo X]
- Não mudar a interface pública de [componente Y]
- Não refatorar código adjacente
```

### Template simplificado (issues < 2 pontos)

```markdown
## Contexto
[1 frase]

## Critérios de Aceite
- [ ] Critério 1
- [ ] Critério 2

## Escopo Técnico
- Arquivos: [paths]
- Constraints: [se houver]
```

### Regra de ouro

- **Issue para humano** = briefing (contexto + liberdade de interpretação)
- **Issue para IA** = contrato de escopo (explícito, delimitado, verificável)

Quanto mais ambíguo, mais risco de entrega errada — IA não "levanta a mão" quando não entende, ela assume.

### Campos mutáveis pela IA durante execução

| Campo | IA pode alterar? | Condição |
|---|---|---|
| Checklist | Sim | Documentar motivo em comentário |
| Description técnica | Sim | Apenas detalhes descobertos em execução |
| Critérios de aceite | **Não** | São contrato; só PO altera |
| Prioridade | **Não** | Decisão de negócio |
| Status | Sim | Segue o funil normalmente |
| Comentários | Sim | Para documentar decisões e descobertas |

---

## 4. Exemplos de tamanho de issue

O erro mais comum é criar issues grandes demais.

### Issues BOAS (1-3 dias, 2-5 pontos)

```
"Criar endpoint POST /api/checkout"
   Checklist:
   [ ] Definir schema do request body
   [ ] Implementar controller
   [ ] Adicionar validação
   [ ] Escrever 3 testes
   → 1 dia, 3 pontos

"Implementar login com Google OAuth"
   Checklist:
   [ ] Configurar Google OAuth credentials
   [ ] Criar rota /auth/google
   [ ] Tratar callback e salvar token
   [ ] Redirect para dashboard
   → 2 dias, 5 pontos

"Fix: email de confirmação não envia"
   Checklist:
   [ ] Reproduzir o bug
   [ ] Identificar causa raiz
   [ ] Aplicar fix
   [ ] Testar em staging
   → 4h, 1 ponto
```

### Issues RUINS (grandes demais — quebre)

```
"Implementar sistema de pagamento"
   → Grande demais. Quebre em:
   • Criar endpoint /checkout
   • Integrar Stripe SDK
   • Implementar webhook de confirmação
   • Criar página de sucesso/erro
   • Adicionar retry em caso de falha

"Refatorar todo o frontend"
   → Sem escopo definido. Quebre por área:
   • Refatorar componente de formulário
   • Extrair hooks compartilhados
   • Padronizar error handling

"Melhorar performance do site"
   → Vago. Quebre em ações mensuráveis:
   • Implementar lazy loading de imagens
   • Remover JS não utilizado (< 50kb)
   • Configurar CDN para assets estáticos
```

---

## 5. Estimativa

### Regra #1: Quem executa é quem estima. Sempre.

**PO define prioridade. Executor define esforço. Nunca o contrário.**

Se o PO diz "isso é 2 pontos" e o executor diz "isso é 5", vale 5. O executor conhece o código. O PO conhece o negócio. Cada um no seu papel.

### Estimativa com IA como executor

| Dimensão | Humano | IA |
|---|---|---|
| Base de estimativa | Experiência prévia | Complexidade técnica declarada |
| Confiança | Alta (sabe o codebase) | Proporcional à qualidade da issue |
| Risco | Mal-entendido | Ambiguidade não detectada |
| Validação | Peer review | Dry-run + revisão humana do plano |

A IA pode sugerir estimativa baseada em tamanho do escopo técnico, arquivos afetados, e histórico de issues similares. Mas o PO valida — especialmente em issues com risco de negócio.

### Escala Fibonacci

| Pontos | Tempo | Descrição |
|---|---|---|
| 1 | < 4h | Bug simples, mudança pontual |
| 2 | Meio dia | Feature pequena, bem definida |
| 3 | 1 dia | Feature média, escopo claro |
| 5 | 2 dias | Feature com 2-3 componentes conectados |
| 8 | 3-4 dias | Complexo, múltiplos sistemas (atenção: quebre) |
| 13+ | > 1 semana | **Grande demais — quebre obrigatoriamente** |

### Estimando na prática (2 devs)

1. PO apresenta a issue com contexto
2. Cada dev pensa num número (sem falar)
3. Ambos revelam ao mesmo tempo
4. Se concordam → segue
5. Se divergem → o que deu mais explica o risco que viu
6. Convergem num número

**Tempo total:** 2-3 minutos por issue.

### Quando não dá pra estimar

Se o executor diz "não sei estimar isso", significa uma de duas coisas:

1. **Falta contexto** → PO completa a descrição
2. **Falta pesquisa** → Cria uma "spike" (issue de pesquisa, 1-2 pontos, timeboxed) antes de estimar a issue real

---

## 6. Fluxo Diário

### Executor humano

```
08:30  Abre view "My Focus"
       → Vê o que tá In Progress

08:35  Se nada In Progress:
       → Puxa a próxima de Ready
       (maior prioridade primeiro)
       → NUNCA escolhe por gosto

08:40  Lê a issue inteira
       → Contexto, critérios, design
       → Se falta info: comenta e puxa outra

08:45  Cria branch (feat/123-nome-da-issue)

08:50-12:00  Coda

12:00  Almoço

13:00-17:00  Coda + review do colega

       Se terminou antes das 17h:
       → Abre PR
       → Move pra In Review
       → Revisa PR do colega
       → Puxa próxima issue

17:00  Standup assíncrono
       "Fiz: X. Amanhã: Y. Blocker: Z"
```

### Executor IA (Agent)

```
1. Agent recebe issue de Ready (via API, webhook, ou comando)
2. Lê description completa + checklist + Folder description (épico)
3. Cria branch (feat/ISSUE_ID-slug)
4. Executa:
   - Para cada item do checklist:
     → Implementa
     → Marca como done
     → Posta comentário com decisões/descobertas
5. Abre PR com:
   - Título: tipo + ID + descrição curta
   - Body: critérios de aceite como checklist (marcados)
   - Link pra issue
6. Move issue pra In Review
7. Aguarda review humano (ou code review IA + aprovação humana)
```

### Regras para executor IA

- Nunca alterar critérios de aceite
- Nunca mudar prioridade
- Documentar toda decisão não-trivial como comentário na issue
- Se encontrar complexidade maior que estimada → **comentar, não escalar silenciosamente**
- Se bloqueado (API indisponível, permissão, ambiguidade) → comentar e parar. **Não inventar solução.**

### O executor (humano ou IA) NUNCA:

- Cria issue sozinho (pede pro PO)
- Muda prioridade (pede pro PO)
- Trabalha em 2 issues ao mesmo tempo
- Fica mais de 4h travado sem comunicar
- Começa issue sem critério de aceite
- Estima issue que não vai executar

---

## 7. Papéis em time pequeno + IA

### PO (Product Owner) — humano

Define prioridade (decisão final), escreve/valida issues, aceita ou rejeita entrega, decide o que entra no sprint, negocia escopo com stakeholders.

### PO-Agent (IA) — assistente do PO

O PO-Agent reduz trabalho operacional do PO de **10min/dia para 2min/dia** (revisão do que a IA classificou).

| Atividade | PO-Agent faz? | PO valida? |
|---|---|---|
| Enriquecer issue nova (tags, links, tipo) | Sim | Sim (bulk) |
| Flagar issue sem critérios | Sim | Não (só age) |
| Sugerir prioridade | Sim | **Sim (obrigatório)** |
| Sugerir estimativa | Sim | Sim (com executor) |
| Mover Backlog → Ready | Sim (se gate ok) | Não |
| Cancelar issue obsoleta | **Não** | PO decide |
| Responder stakeholder | **Não** | PO decide |

**Modelo:** IA propõe, humano dispõe. O PO-Agent nunca decide prioridade final, nunca cancela issue sozinho, nunca define escopo.

### SM (Scrum Master) → dispensável com 2 devs

- O processo é o SM
- Se precisar: rotativo entre devs, a cada sprint
- Ou automatizado (PO-Agent assume guardianship do board)
- Responsabilidade: board atualizado, ninguém travado

### Dev / Agent-Dev (executor)

- Estima (sempre quem executa)
- Puxa issue de `Ready`
- Coda, testa, abre PR
- Revisa PR do colega (se humano) ou submete pra review (se IA)
- Comunica bloqueios em < 4h

---

## 8. Cadência semanal (sprint de 1 semana)

### Segunda — Sprint Planning (30 min)

- PO consulta Goals ativos para calibrar prioridades
- PO apresenta prioridades da semana (com sugestões do PO-Agent)
- Executores estimam issues novas (se houver)
- Cada executor puxa issues do `Ready`
- **Meta:** 10-16 pontos totais (5-8 por executor)
- Se sobrou capacidade, puxar mais. Se faltou, negociar escopo.

### Terça a Quinta — Execução

- Standup assíncrono (mensagem, não call)
- Code review cruzado contínuo
- PO faz triagem diária do Backlog (10 min — ou PO-Agent faz + PO revisa em 2 min) usando a View `Triage Queue`

### Sexta — Sprint Review + Retro (20 min)

- Demo rápida do que foi entregue
- Retro: "O que funcionou? O que travou? O que mudar?"
- PO move pendências pro próximo sprint
- **Limpar Backlog** (issues velhas, cancelar obsoletas)
- Comparar estimativa vs. real (calibrar velocity)

---

## 9. Capacidade e Backlog

### Quantas issues no Backlog?

| Total no Backlog | Diagnóstico |
|---|---|
| < 30 | Saudável |
| 30-50 | Aceitável, mas começando a acumular |
| 50-100 | Limpar. Muita coisa vai morrer sem ser feita |
| > 100 | **Backlog infinito = lixo. Cancelar em massa.** |

### Limpeza de Backlog

- **A cada 3 meses:** filtra tudo com mais de 90 dias
- Pergunta: "Se ninguém reclamou em 3 meses, precisava?"
- Cancela sem dó. **Backlog infinito = backlog inútil.**
- Ideias vagas vão pra um doc separado (Obsidian inbox), **NÃO** pro Backlog.

---

## 10. Contexto necessário antes de puxar uma issue

Antes de puxar uma issue, o executor precisa de:

1. **POR QUÊ** — contexto do negócio (1 frase) + link pro Goal/Épico
2. **O QUÊ** — comportamento esperado (estado final, não caminho)
3. **CRITÉRIOS** — checklist verificável (pass/fail)
4. **ESCOPO TÉCNICO** — arquivos, stack, constraints, fora de escopo (obrigatório para IA)
5. **DESIGN** — link do Figma ou screenshot (se tem UI)
6. **DEPENDÊNCIAS** — precisa de algo pronto antes?
7. **ESTIMATE** — pontos acordados com o executor
8. **ACESSO** — credenciais, ambientes, APIs

Se faltar qualquer um: executor comenta "falta contexto", marca o PO, puxa outra issue.

---

## 11. Priorização

### Framework P0-P3

| Prioridade | Critério | Ação |
|---|---|---|
| **P0** | Quebra produção / bloqueia receita | Larga tudo |
| **P1** | Alto impacto + tem deadline externo | Esta sprint |
| **P2** | Importante mas sem urgência | Próxima sprint |
| **P3** | Nice to have | Quando sobrar tempo |

### Decisão rápida

- Afeta receita agora? → **P0**
- Afeta muitos usuários? → **P1**
- Tem deadline externo? → **P1**
- Melhora mas não é urgente? → **P2**
- Ninguém reclamou? → **P3**

### Quem prioriza

- **PO** define prioridade (P0-P3)
- **PO-Agent** sugere classificação (PO confirma)
- **Dev/Agent** pode sugerir P0/P1 para bugs técnicos
- Ninguém mais muda prioridade sem passar pelo PO

---

## 12. Subtasks vs Checklist — quando usar cada

### Use **checklist** (padrão)

- Passos de execução dentro da mesma issue
- Criada pelo executor que vai fazer
- Max 5 itens, 1 nível de profundidade só

### Use **sub-task** (exceção)

- Trabalho que precisa rodar em paralelo com worktrees separadas
- Cada sub-task = branch própria, PR própria
- Exemplo: frontend e backend de uma mesma issue podem ser sub-tasks se devs diferentes vão executar simultaneamente

### Vira **issue separada** (não sub-task)

- Se tem dono diferente e não é paralelizável
- Se é de projeto diferente
- Se pode ser entregue independente
- Se tem mais de 5 itens → **issue grande demais, quebre**

---

## 13. Múltiplos projetos

- Cada executor trabalha em **1 projeto por sprint**. Context switching mata produtividade.
- Max **2 projetos ativos** simultaneamente (1 por executor).
- Reserve **20% da capacidade** para manutenção (bugs, infra): sprint de 16 pts → 3 pts para bugs.
- Se tem 3+ projetos urgentes: **priorize, não paralelize**. Melhor entregar 1 completo do que 3 pela metade.

---

## 14. Stack ideal de integrações

### Obrigatório

- **GitHub** — branch auto-criada pela issue. PR fecha issue com `Fixes #123`. Automação bidirecional.
- **Slack/Discord** — notificação de PR, review, deploy, blocker.

### Recomendado

- **Figma** — link direto na issue. Executor abre e vê o design.
- **Sentry** — bug detectado → issue criada automaticamente com stack trace.
- **Vercel/Railway** — PR mergeada → deploy automático. Preview na PR.

### Nice to have

- **Claude Code / Cursor** — agent lê issue direto da API do ClickUp, executa, posta resultado.
- **CI/CD (GitHub Actions)** — tests na PR. Só mergea se passar.

### Fluxo ideal integrado

```
Issue criada → PO-Agent valida campos → move pra Ready
→ executor puxa → branch auto-criada → executor coda → push
→ CI roda tests → PR aberta → notifica reviewer → review aprovada
→ merge → deploy automático → status = Done
```

---

## 15. IA vs Humano — matriz de responsabilidade

### IA executa (autônomo)

- Implementação de issue com escopo técnico claro
- Code review automático (bugs óbvios, segurança, style)
- Testes automatizados (coverage básica)
- Enriquecimento automático de issues no Backlog (classificar por stack trace, adicionar tags, identificar tipo)
- PR grande detectada (`500+ linhas, divide`)
- Limpeza de backlog (flag issues antigas)
- Validação de issue (campos obrigatórios, gate Backlog → Ready)

### IA sugere, humano decide

- Estimativa de pontos
- Classificação de prioridade (P0-P3)
- Arquitetura (propõe, PO/tech lead aprova)
- Cancelamento de issues antigas

### Humano sempre (IA não toca)

- **Priorização final** (IA não sabe o que importa pro negócio)
- Decisões arquiteturais irreversíveis
- Code review final em áreas críticas (pagamento, auth, dados sensíveis)
- Aceitar/cancelar issue
- Definir escopo estratégico
- Comunicação com stakeholders
- Negociação de prazo e recurso

---

## 16. Como o Top 1% opera

Os melhores times que usam Linear têm isso em comum:

1. **Backlog limpo.** Max 50 issues. Limpam toda sexta.
2. **Triagem diária dentro do Backlog.** 10 min. Uma pessoa (ou PO-Agent + validação). Tudo classificado em 24h via View `Triage Queue`.
3. **Sprints curtos.** 1 semana. Feedback rápido.
4. **Zero issue em Ready sem critério de aceite.**
5. **PR pequena.** Max 400 linhas. Acima disso, rejeita.
6. **Automação do fluxo.** GitHub ↔ ClickUp bidirecional. Zero update manual.
7. **WIP limit rigoroso.** 1 issue por executor em `In Progress`.
8. **Velocity tracking.** Planejam com dados, não feeling.
9. **Cancelam sem dó.** Issue parada 3 sprints? Cancelada.
10. **Escrevem bem.** Issues claras, escopo técnico completo, contexto de negócio.
11. **Issue = workspace.** O executor (humano ou IA) usa a issue como mesa de trabalho — checklists, comentários, decisões, tudo lá.

---

## 17. Setup recomendado no ClickUp

```
Space: Build
  Statuses: Backlog, Ready, In Progress, In Review, Done, Canceled

  Folders (= Épicos):
    - Lançar Área de Membros/
        ├─ List: Sistema de Autenticação    (= Projeto)
        ├─ List: Dashboard do Aluno         (= Projeto)
        └─ List: Integração Pagamento       (= Projeto)
    - Migrar Infra N8N/
        ├─ List: Migração Flows Make        (= Projeto)
        └─ List: Setup Ambiente N8N         (= Projeto)

  Goals (vinculados aos Folders):
    - "Aumentar MRR 30% Q3"  → vincula Folders relevantes
    - "Reduzir churn < 5%"   → vincula Folders relevantes

  Custom Fields:
    - Sprint Points    (number)
    - Owner            (people)
    - Executor Type    (dropdown: Human / AI-Agent)
    - Priority         (Urgent/High/Normal/Low — nativa)
    - Sprint/Cycle     (dropdown)
    - Blocked By       (relationship)

  Views:
    - Triage Queue        (Backlog + critérios incompletos — fila do PO-Agent)
    - Backlog             (Backlog ordenado por prioridade)
    - Ready               (Ready ordenado por prioridade — fila de execução)
    - Current Sprint      (cycle = atual, Board view por status)
    - My Focus            (assignee = eu, status in [In Progress, In Review])
    - AI Queue            (executor_type = AI-Agent, status = Ready)
    - Projects Overview   (agrupada por Folder, mostra % de tasks Done)
    - Stale Issues        (last updated > 30 dias, status != Done/Canceled)

  Automações:
    - Nova task → status = Backlog
    - PR merged (via GitHub) → status = Done
    - Issue sem owner no sprint → notificar PO
    - Pendência no fim do sprint → mover pro próximo
    - Issue em Backlog > 24h sem critérios → notificar PO
    - Issue em In Review > 48h → notificar reviewer + PO
    - Task movida pra Ready sem critérios → bloquear + notificar PO
    - Task movida pra Ready → validar gate automático (PO-Agent)
```

---

## Fechamento — o que importa de verdade

Linear ganhou porque impôs uma forma certa de operar. O ClickUp tem flexibilidade demais — e flexibilidade sem disciplina vira lixo. **Este playbook é a disciplina.**

Três compromissos não-negociáveis:

1. **Ready é contrato, não promessa.** Se a issue não passa no gate, não vira `Ready`.
2. **Quem executa estima, sempre.** PO define prioridade; executor define esforço.
3. **WIP = 1.** Um executor, uma issue em `In Progress`. Sem exceção.

O resto se ajusta. A disciplina sustenta.
