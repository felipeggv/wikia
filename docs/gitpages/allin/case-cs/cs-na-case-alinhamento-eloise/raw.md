---
eyebrow: NOTA INTERNA · CASE · MAIO 2026
title: Customer Success na CASE · Alinhamento Eloise + Manual Resumido
lead: O que foi conversado com a Eloise, de onde vieram essas decisões, e como o trabalho do consultor está desenhado hoje. Documento para alinhar a sócia/sócios antes de qualquer próxima conversa sobre o tema.
tags: [case, customer-success, operacao, alinhamento]
bu: allin
project: case-cs
slug: cs-na-case-alinhamento-eloise
date: 2026-05-19
---

<style>
.cs-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 14px; margin: 18px 0; }
.cs-card { border: 1px solid #2a4d3e; border-radius: 8px; padding: 16px; background: rgba(26,61,46,0.15); }
.cs-card h4 { margin: 0 0 8px 0; font-size: 0.95em; text-transform: uppercase; letter-spacing: 0.08em; color: #7fb89a; }
.cs-card p { margin: 0; font-size: 0.92em; line-height: 1.55; }
.cs-card.warn { border-color: #6e4d1a; background: rgba(110,77,26,0.15); }
.cs-card.warn h4 { color: #d4a857; }
.cs-card.ok { border-color: #2a6e4a; background: rgba(42,110,74,0.18); }
.cs-card.ok h4 { color: #5fd8a0; }
.cs-card.purple { border-color: #4d2a6e; background: rgba(77,42,110,0.18); }
.cs-card.purple h4 { color: #b88adf; }

.cs-agenda { width: 100%; border-collapse: collapse; margin: 22px 0; font-size: 0.78em; }
.cs-agenda th, .cs-agenda td { border: 1px solid #2a4d3e; padding: 6px 8px; text-align: left; vertical-align: top; }
.cs-agenda th { background: #1a3d2e; color: #fff; text-transform: uppercase; letter-spacing: 0.06em; font-size: 0.72em; font-weight: 600; }
.cs-agenda td.hour { background: #0e2419; color: #7fb89a; font-weight: 600; font-size: 0.72em; width: 78px; white-space: nowrap; }
.cs-agenda .slot { display: block; padding: 3px 5px; border-radius: 3px; font-size: 0.72em; font-weight: 600; text-transform: uppercase; letter-spacing: 0.03em; line-height: 1.3; text-align: center; }
.slot-daily { background: #2a4d3e; color: #b8d4c2; }
.slot-pulse { background: #1a3d2e; color: #5fd8a0; border: 1px solid #2a6e4a; }
.slot-onb { background: #2a3d5e; color: #b8c4e0; }
.slot-dos { background: #4d2a6e; color: #d4b8e0; }
.slot-rev { background: #2a4d6e; color: #b8d4e0; }
.slot-conf { background: #3d2a4d; color: #d4b8e0; }
.slot-rond { background: #5e4a1a; color: #e0d4b8; }
.slot-weekly { background: #4d1a3d; color: #e0b8d4; }
.slot-tool { background: #1a4d5e; color: #b8d4e0; }
.slot-padr { background: #4d3a1a; color: #e0c4a8; }
.slot-foco { background: #1a1a2a; color: #6a8aaa; border: 1px solid #2a3d4a; }
.slot-livre { background: #0e1419; color: #4a4a4a; }

.cs-month { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; margin: 20px 0; }
.cs-month-step { padding: 12px 10px; border-radius: 6px; border: 1px solid #2a4d3e; }
.cs-month-step .lbl { font-size: 0.7em; text-transform: uppercase; letter-spacing: 0.1em; color: #7fb89a; font-weight: 700; }
.cs-month-step .ttl { font-size: 0.9em; font-weight: 600; margin: 4px 0 6px 0; }
.cs-month-step .desc { font-size: 0.78em; line-height: 1.4; color: #c4d4cc; }
.cs-month-step.exec { background: rgba(26,61,46,0.25); }
.cs-month-step.scan { background: rgba(110,77,26,0.2); border-color: #5e4a1a; }
.cs-month-step.scan .lbl { color: #d4a857; }
.cs-month-step.raio { background: rgba(77,26,61,0.25); border-color: #4d1a3d; }
.cs-month-step.raio .lbl { color: #e0b8d4; }
.cs-month-step.dist { background: rgba(42,110,74,0.2); border-color: #2a6e4a; }
.cs-month-step.dist .lbl { color: #5fd8a0; }

.cs-cap { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; margin: 20px 0; }
.cs-cap-cell { padding: 10px; border-radius: 6px; border: 1px solid #2a4d3e; background: #0e2419; text-align: center; }
.cs-cap-cell .pct { font-size: 1.7em; font-weight: 700; color: #5fd8a0; }
.cs-cap-cell.warn .pct { color: #d4a857; }
.cs-cap-cell.bad .pct { color: #d47857; }
.cs-cap-cell.ok .pct { color: #5fd8a0; }
.cs-cap-cell .nm { font-size: 0.72em; text-transform: uppercase; letter-spacing: 0.08em; color: #7fb89a; margin-top: 4px; }
.cs-cap-cell .sub { font-size: 0.68em; color: #8a9a90; margin-top: 6px; line-height: 1.3; }
.cs-cap-cell .bar { height: 4px; background: #2a4d3e; border-radius: 2px; margin: 8px 0; overflow: hidden; }
.cs-cap-cell .bar > i { display: block; height: 100%; background: linear-gradient(90deg, #5fd8a0, #2a6e4a); }
.cs-cap-cell.warn .bar > i { background: linear-gradient(90deg, #d4a857, #6e4d1a); }
.cs-cap-cell.bad .bar > i { background: linear-gradient(90deg, #d47857, #6e2a1a); }

.cs-dossie { display: flex; flex-direction: column; gap: 6px; margin: 18px 0; }
.cs-dossie-row { display: grid; grid-template-columns: 24px 1fr; gap: 12px; align-items: center; padding: 10px 14px; border: 1px solid #2a4d3e; border-radius: 6px; background: #0e2419; }
.cs-dossie-row .num { font-size: 0.7em; font-weight: 700; color: #7fb89a; text-align: center; }
.cs-dossie-row .info .stage { font-size: 0.7em; text-transform: uppercase; letter-spacing: 0.08em; color: #7fb89a; font-weight: 600; }
.cs-dossie-row .info .name { font-size: 0.92em; font-weight: 600; margin-top: 2px; }
.cs-dossie-row .info .desc { font-size: 0.78em; color: #8a9a90; margin-top: 3px; }
.cs-dossie-row.cs { border-color: #5fd8a0; background: rgba(42,110,74,0.18); }
.cs-dossie-row.cs .stage { color: #5fd8a0; }
.cs-dossie-row.cs .info::after { content: " ← CONSULTOR ATUA AQUI"; font-size: 0.72em; color: #5fd8a0; font-weight: 700; letter-spacing: 0.06em; }

.cs-pair { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 18px 0; }
.cs-pair > div { padding: 14px; border-radius: 8px; }
.cs-pair .yes { border: 1px solid #2a6e4a; background: rgba(42,110,74,0.12); }
.cs-pair .no { border: 1px solid #6e2a4a; background: rgba(110,42,74,0.12); }
.cs-pair h4 { margin: 0 0 10px 0; font-size: 0.9em; text-transform: uppercase; letter-spacing: 0.08em; }
.cs-pair .yes h4 { color: #5fd8a0; }
.cs-pair .no h4 { color: #d47ca0; }
.cs-pair ul { margin: 0; padding-left: 18px; font-size: 0.88em; line-height: 1.65; }

.cs-legend { display: flex; flex-wrap: wrap; gap: 8px; margin: 10px 0 18px 0; font-size: 0.74em; }
.cs-legend .item { display: inline-flex; align-items: center; gap: 5px; padding: 3px 8px; border-radius: 4px; background: rgba(26,61,46,0.3); }
.cs-legend .dot { width: 10px; height: 10px; border-radius: 2px; display: inline-block; }
</style>

## Como Ler Este Documento

Está organizado em **5 blocos**, do mais importante pro mais detalhado:

```
1.  O que foi alinhado com a Eloise          ← o ponto central
2.  De onde veio esse alinhamento            ← origem e contexto
3.  O papel do Consultor de CS               ← responsabilidades resumidas
4.  Agenda da operação                       ← visual da semana e do mês
5.  O ciclo Raio-X (mensal)                  ← onde os estrategistas entram
```

---

# 1. Resumo do Alinhamento com a Eloise

Reunião de **14/05/2026** entre Felipe e Eloise. Conversa de pré-contratação para alinhar expectativa antes de ela entrar no time de CS.

<div class="cs-grid">
  <div class="cs-card ok">
    <h4>O que ficou decidido</h4>
    <p>O consultor é o <b>dono operacional</b> do mentorado. Toda reunião tem <b>preparação prévia</b> e <b>pós-reunião</b>. Toda promessa vira tarefa rastreável. CS ensina, não executa pelo mentorado. Dossiês ficam mais enxutos. Daily volta segunda a quinta no início do dia.</p>
  </div>
  <div class="cs-card">
    <h4>O que entra com a Eloise</h4>
    <p>Entrada <b>gradual</b>: ela acompanha reuniões, observa a Lara, estuda o manual de CS e começa por mentorados de baixa criticidade. Disponibilidade parcial (segunda 8h-9h fora; quinta e sexta presenciais em outra consultoria).</p>
  </div>
  <div class="cs-card warn">
    <h4>O que ainda depende de aval</h4>
    <p>Aval da diretoria para a entrada. Conversa com Queila e Hugo. Contrato e onboarding. Seleção dos mentorados iniciais. SLA formal de resposta. Ferramenta de visibilidade para o mentorado sem dar acesso ao ClickUp.</p>
  </div>
</div>

### As 17 Decisões Operacionais que Saíram da Reunião

<table class="cs-agenda">
<thead><tr><th style="width: 30px;">#</th><th>Decisão</th></tr></thead>
<tbody>
<tr><td>1</td><td>Toda reunião com mentorado tem <b>preparação prévia</b> + <b>pós-reunião</b> obrigatórios</td></tr>
<tr><td>2</td><td>Consultor é o <b>dono operacional</b> do mentorado · ponte com o time interno</td></tr>
<tr><td>3</td><td>Onboarding serve para <b>alinhar expectativa</b>, não para descoberta profunda</td></tr>
<tr><td>4</td><td>Dúvidas estratégicas passam pelo consultor antes de chegar aos sócios</td></tr>
<tr><td>5</td><td>Não existe call semanal individual com os sócios como padrão</td></tr>
<tr><td>6</td><td>Reuniões em cima da hora são exceção · padrão: <b>7 dias</b> de antecedência</td></tr>
<tr><td>7</td><td><b>Mudanças no dossiê</b> solicitadas pelo mentorado têm prazo oficial de <b>5 dias úteis</b></td></tr>
<tr><td>8</td><td>ClickUp é o canal oficial interno · planos de ação viram tarefa com prazo e dono</td></tr>
<tr><td>9</td><td>Consultoria educa e revisa · não executa pelo mentorado</td></tr>
<tr><td>10</td><td>CS começa pelo "arroz com feijão" antes de qualquer sofisticação</td></tr>
<tr><td>11</td><td>Entrada da Eloise é <b>gradual</b> · experimento com mentorados de baixa criticidade</td></tr>
<tr><td>12</td><td>Núcleo operacional: Felipe + Eloise + Lara + Marisa + Kaique</td></tr>
<tr><td>13</td><td>Daily volta segunda a quinta no início do dia (horário entre 8h e 9h em aberto)</td></tr>
<tr><td>14</td><td>Encontro de sexta para aprendizados da semana + planejamento da próxima</td></tr>
<tr><td>15</td><td>Aulas de terça e quarta às 19h precisam de consultor de apoio</td></tr>
<tr><td>16</td><td>Dossiês <b>simplificados</b>: foco em oferta/produto, funil e geração de demanda</td></tr>
<tr><td>17</td><td>Pedidos repetidos viram <b>ativos reutilizáveis</b> (aula, ferramenta, vídeo)</td></tr>
</tbody>
</table>

### O que é Preparação e o que é Pós-Reunião?

<div class="cs-grid">
  <div class="cs-card ok">
    <h4>Preparação prévia</h4>
    <p>Antes da reunião acontecer, o consultor lê o último follow-up, revisa os combinados pendentes, abre o material em produção e chega à call com 3 a 5 perguntas/pontos de pauta. <b>Sem isso, a reunião acontece no escuro.</b> Tempo: 30 a 60 minutos dependendo do tipo.</p>
  </div>
  <div class="cs-card ok">
    <h4>Pós-reunião</h4>
    <p>Depois da call, o consultor registra os combinados no ClickUp (com responsável e prazo), envia o follow-up para o mentorado, e atualiza o contexto interno. <b>Sem isso, a reunião vira só transcrição sem encaminhamento.</b> Tempo: 15 minutos de buffer logo após a call.</p>
  </div>
</div>

---

# 2. De Onde Veio Esse Alinhamento

> O manual de CS é a **consolidação dos erros que o time aprendeu ao longo da jornada**. Cada decisão da seção 1 corresponde a uma lição operacional: combinados que se perderam, reuniões mal preparadas, dossiês apresentados sem revisão, dúvidas estratégicas que ficaram sem resposta. O documento existe para que esses erros não se repitam.

::: callout info Fontes consolidadas
- **Manual do CS** · ClickUp Doc `8cj22vu-11751`
- **CS Rotinas** · ClickUp Doc `8cj22vu-11311`
- **Skill `copiloto-cs`** · planejamento de semana automatizado
- **Reunião Eloise + Felipe** · 14/05/2026

A reunião com a Eloise não criou regras do zero — ela validou e reforçou o que o manual já estabelecia, e identificou o que ainda estava verbalizado mas não consolidado.
:::

---

# 3. O Papel do Consultor de CS

::: callout quote Princípio-âncora
**CS ensina. CS não faz.**
O consultor sustenta o processo enquanto o mentorado aprende a carregar o próprio negócio. Adulto aprende quando aplica critério em problema real, não quando assiste outra pessoa resolver.
:::

<div class="cs-pair">
  <div class="yes">
    <h4>✓ Consultor sustenta</h4>
    <ul>
      <li>Dá critério para o mentorado decidir</li>
      <li>Revisa o raciocínio</li>
      <li>Cobra prazo e qualidade</li>
      <li>Aponta gaps no dossiê (não reescreve)</li>
      <li>Orienta calendário editorial</li>
      <li>Transforma pedido repetido em ativo</li>
    </ul>
  </div>
  <div class="no">
    <h4>✕ Consultor não executa</h4>
    <ul>
      <li>Não decide no lugar do mentorado</li>
      <li>Não reescreve a entrega</li>
      <li>Não alivia toda tensão para evitar desconforto</li>
      <li>Não escreve copy pelo mentorado</li>
      <li>Não escreve o dossiê (cabe ao estrategista)</li>
      <li>Não responde individualmente a dúvidas que viram aula</li>
    </ul>
  </div>
</div>

### Métricas de Sucesso

<div class="cs-grid">
  <div class="cs-card">
    <h4>SLA WhatsApp</h4>
    <p><b>≤ 1 hora</b> de primeira resposta em horário comercial. Sem SLA em fim de semana.</p>
  </div>
  <div class="cs-card">
    <h4>Rondas por dia</h4>
    <p><b>4 a 5</b> rondas de WhatsApp. Fecha quando a fila zera, não quando o relógio bate.</p>
  </div>
  <div class="cs-card">
    <h4>Reuniões com prep</h4>
    <p><b>100%</b> · sem preparação no turno anterior, remarca.</p>
  </div>
  <div class="cs-card">
    <h4>Combinados rastreáveis</h4>
    <p><b>100%</b> · zero promessa solta · tudo vira tarefa com prazo e dono.</p>
  </div>
  <div class="cs-card">
    <h4>Carteira ativa</h4>
    <p>Até <b>20 mentorados</b> por consultor para manter qualidade.</p>
  </div>
  <div class="cs-card">
    <h4>Aproveitamento sustentável</h4>
    <p><b>67%</b> da semana em reuniões · 33% para foco, prep extra e contingência.</p>
  </div>
</div>

### Responsabilidades de Background (além das reuniões)

<div class="cs-grid">
  <div class="cs-card purple">
    <h4>Construção de ferramentas e checklists</h4>
    <p>Quando uma demanda aparece <b>repetidamente</b> entre mentorados, o consultor cria um ativo reutilizável: ferramenta, checklist, vídeo curto ou tutorial. Em vez de responder 10 vezes individualmente, resolve 1 vez e distribui.</p>
  </div>
  <div class="cs-card purple">
    <h4>Padronização de processos</h4>
    <p>O consultor documenta o que funcionou e o que não funcionou em cada ciclo. Atualiza templates de onboarding/dossiê/follow-up. Propõe mudanças no manual quando a prática mostrar que algo precisa mudar.</p>
  </div>
</div>

### Cadeia de Ajuda

```
Consultor CS  →  Dono da tarefa  →  Felipe  →  Sócios (Hugo e Queila)
   primeiro       quando a dúvida    impasse,        risco financeiro,
   diagnóstico    depende da etapa   risco alto,     cancelamento,
                  ou área            mudança de      jurídico, regra
                                     regra           que vira política
```

---

# 4. Pipeline do Dossiê · Cadeia Real

O dossiê é o **artefato central** da mentoria. Tem uma cadeia padrão de produção entre estrategista e consultor. Esta é a sequência real que aparece no ClickUp:

<div class="cs-dossie">
  <div class="cs-dossie-row">
    <div class="num">1</div>
    <div class="info">
      <div class="stage">Pós call de revisão</div>
      <div class="name">Pós-call com mentorado</div>
      <div class="desc">Estrategista captura os pontos de oferta/produto/funil discutidos na call inicial</div>
    </div>
  </div>
  <div class="cs-dossie-row">
    <div class="num">2</div>
    <div class="info">
      <div class="stage">Estágio 1</div>
      <div class="name">1ª Entrega</div>
      <div class="desc">Estrategista produz a primeira versão do dossiê</div>
    </div>
  </div>
  <div class="cs-dossie-row cs">
    <div class="num">3</div>
    <div class="info">
      <div class="stage">Estágio 2 · Revisor</div>
      <div class="name">Revisão da 1ª Entrega</div>
      <div class="desc">Consultor lê, comenta no documento, aponta gaps e incoerências. Não reescreve.</div>
    </div>
  </div>
  <div class="cs-dossie-row">
    <div class="num">4</div>
    <div class="info">
      <div class="stage">Estágio 3</div>
      <div class="name">Execução dos ajustes</div>
      <div class="desc">Estrategista incorpora os apontamentos do consultor</div>
    </div>
  </div>
  <div class="cs-dossie-row cs">
    <div class="num">5</div>
    <div class="info">
      <div class="stage">Estágio 4 · Aprovador</div>
      <div class="name">Aprovação final</div>
      <div class="desc">Consultor confirma que o documento está pronto para apresentar</div>
    </div>
  </div>
  <div class="cs-dossie-row">
    <div class="num">6</div>
    <div class="info">
      <div class="stage">Estágio 5</div>
      <div class="name">Entrega ao cliente</div>
      <div class="desc">Documento sobe para o mentorado em formato final</div>
    </div>
  </div>
  <div class="cs-dossie-row cs">
    <div class="num">7</div>
    <div class="info">
      <div class="stage">Estágio 6 · Apresentador</div>
      <div class="name">Call de apresentação do dossiê</div>
      <div class="desc">Consultor apresenta o dossiê para o mentorado · estuda o material no turno anterior</div>
    </div>
  </div>
</div>

::: callout tip Onde o consultor entra
O **estrategista** é dono dos estágios de produção e ajustes. O **consultor (Felipe ou Eloise)** entra como **revisor** na 1ª entrega, como **aprovador final** antes da entrega ao cliente, e como **apresentador** na call. Existe ainda um quarto papel: **cobrador** — quando a cadeia atrasa, o consultor cria ação imediata para destravar, sem virar substituto do estrategista.
:::

---

# 5. Agenda da Operação

A vida do consultor opera em **camadas de tempo**. Esta agenda mostra como uma semana modelo se distribui ao longo do dia, com cores por tipo de atividade.

<div class="cs-legend">
  <span class="item"><span class="dot" style="background:#2a4d3e;"></span> Daily</span>
  <span class="item"><span class="dot" style="background:#1a3d2e;"></span> Dedo no Pulso</span>
  <span class="item"><span class="dot" style="background:#2a3d5e;"></span> Onboarding</span>
  <span class="item"><span class="dot" style="background:#4d2a6e;"></span> Dossiê</span>
  <span class="item"><span class="dot" style="background:#2a4d6e;"></span> Revisão</span>
  <span class="item"><span class="dot" style="background:#3d2a4d;"></span> Confirmação 15d</span>
  <span class="item"><span class="dot" style="background:#5e4a1a;"></span> Rondas WhatsApp</span>
  <span class="item"><span class="dot" style="background:#4d1a3d;"></span> Weekly</span>
  <span class="item"><span class="dot" style="background:#1a4d5e;"></span> Construção de ferramentas</span>
  <span class="item"><span class="dot" style="background:#4d3a1a;"></span> Padronização</span>
  <span class="item"><span class="dot" style="background:#1a1a2a;"></span> Foco profundo</span>
</div>

## 5.1 · Agenda Modelo · Semana Padrão

<table class="cs-agenda">
<thead><tr><th>Horário</th><th>Segunda</th><th>Terça</th><th>Quarta</th><th>Quinta</th><th>Sexta</th></tr></thead>
<tbody>
<tr>
  <td class="hour">08:00 – 08:30</td>
  <td><span class="slot slot-daily">Daily</span></td>
  <td><span class="slot slot-daily">Daily</span></td>
  <td><span class="slot slot-daily">Daily</span></td>
  <td><span class="slot slot-daily">Daily</span></td>
  <td><span class="slot slot-daily">Daily</span></td>
</tr>
<tr>
  <td class="hour">08:30 – 09:00</td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
</tr>
<tr>
  <td class="hour">09:00 – 10:00</td>
  <td><span class="slot slot-pulse">Dedo no Pulso</span></td>
  <td><span class="slot slot-onb">Onboarding</span></td>
  <td><span class="slot slot-dos">Dossiê (prep)</span></td>
  <td><span class="slot slot-rev">Revisão</span></td>
  <td><span class="slot slot-foco">Foco profundo</span></td>
</tr>
<tr>
  <td class="hour">10:00 – 11:00</td>
  <td><span class="slot slot-tool">Construção de ferramentas</span></td>
  <td><span class="slot slot-onb">Onboarding</span></td>
  <td><span class="slot slot-dos">Dossiê (call)</span></td>
  <td><span class="slot slot-rev">Revisão</span></td>
  <td><span class="slot slot-foco">Foco profundo</span></td>
</tr>
<tr>
  <td class="hour">11:00 – 11:30</td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-dos">Dossiê (call)</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
</tr>
<tr>
  <td class="hour">11:30 – 12:00</td>
  <td><span class="slot slot-conf">Confirm. 15d</span></td>
  <td><span class="slot slot-conf">Confirm. 15d</span></td>
  <td><span class="slot slot-conf">Confirm. 15d</span></td>
  <td><span class="slot slot-conf">Confirm. 15d</span></td>
  <td><span class="slot slot-conf">Confirm. 15d</span></td>
</tr>
<tr>
  <td class="hour">12:00 – 13:30</td>
  <td colspan="5" style="text-align:center; color:#6a6a6a;">— almoço —</td>
</tr>
<tr>
  <td class="hour">13:30 – 14:00</td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
</tr>
<tr>
  <td class="hour">14:00 – 15:00</td>
  <td><span class="slot slot-padr">Padronização</span></td>
  <td><span class="slot slot-rev">Revisão</span></td>
  <td><span class="slot slot-onb">Onboarding</span></td>
  <td><span class="slot slot-dos">Dossiê (prep)</span></td>
  <td><span class="slot slot-livre">Buffer</span></td>
</tr>
<tr>
  <td class="hour">15:00 – 16:30</td>
  <td><span class="slot slot-foco">Foco profundo</span></td>
  <td><span class="slot slot-rev">Revisão</span></td>
  <td><span class="slot slot-onb">Onboarding</span></td>
  <td><span class="slot slot-dos">Dossiê (call)</span></td>
  <td><span class="slot slot-weekly">Weekly Produto+CS</span></td>
</tr>
<tr>
  <td class="hour">16:30 – 17:30</td>
  <td><span class="slot slot-tool">Construção de ferramentas</span></td>
  <td><span class="slot slot-padr">Padronização</span></td>
  <td><span class="slot slot-foco">Foco profundo</span></td>
  <td><span class="slot slot-rev">Revisão</span></td>
  <td><span class="slot slot-weekly">Weekly Produto+CS</span></td>
</tr>
<tr>
  <td class="hour">17:30 – 18:00</td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
  <td><span class="slot slot-rond">Ronda WA</span></td>
</tr>
</tbody>
</table>

::: callout tip Como ler a agenda
**Segunda** é o dia mais "interno": Dedo no Pulso, construção de ferramentas, padronização, foco. Sem reunião com mentorado.
**Terça/quarta/quinta** concentram as calls com mentorado (onboarding, dossiê, revisão).
**Sexta** tem buffer + Weekly Produto+CS no fim da tarde.
**Toda hora extrema do dia** é Daily (manhã) e Ronda WA (manhã e fim de tarde).
:::

## 5.2 · As Rotinas por Tipo

<div class="cs-grid">
  <div class="cs-card">
    <h4>Diárias</h4>
    <p><b>Daily</b> (~15min · stand-up assíncrono no ClickUp)<br>
    <b>Rondas WhatsApp</b> (4 a 5× · ~10min cada)<br>
    <b>Confirmação de reuniões</b> dos próximos 15 dias (~10min)</p>
  </div>
  <div class="cs-card">
    <h4>Semanais</h4>
    <p><b>Dedo no Pulso</b> · segunda 9h–10h<br>
    <b>Weekly Produto + CS</b> · sexta 15h–16h30<br>
    <b>Reuniões com mentorado</b> · terça/quarta/quinta</p>
  </div>
  <div class="cs-card">
    <h4>Mensais</h4>
    <p><b>Ronda Completa</b> · última semana (seg–qui)<br>
    <b>Raio-X com Estrategistas</b> · última sexta 15h<br>
    <b>Distribuição de planos novos</b> · segunda seguinte</p>
  </div>
  <div class="cs-card purple">
    <h4>Contínuas · Background</h4>
    <p><b>Construção de ferramentas e checklists</b> · transforma pedidos repetidos em ativos reutilizáveis<br>
    <b>Padronização de processos</b> · documenta lições, atualiza templates, propõe mudanças no manual</p>
  </div>
</div>

---

# 6. O Ciclo Mensal · Raio-X

## 6.1 · Por que o Raio-X existe

::: callout quote A pergunta que originou o ciclo
**"A gente vive matando um leão por dia. Como sair desse loop?"** — observação da operação atual.
:::

O time vinha operando em **modo apagar incêndio**: cada semana surgia um novo problema, cada mentorado precisava de atenção pontual, e os estrategistas (Hugo e Queila) gastavam horas construindo planos do zero em reuniões longas. Ninguém tinha visão consolidada da carteira.

O Raio-X foi desenhado para **resolver três problemas ao mesmo tempo**:

<div class="cs-grid">
  <div class="cs-card">
    <h4>1 · Concentração de análise</h4>
    <p>Em vez de análise estratégica difusa toda semana, concentra em <b>uma única semana do mês</b>. Os outros 75% do mês ficam livres para execução pura.</p>
  </div>
  <div class="cs-card">
    <h4>2 · Estrategistas como revisores</h4>
    <p>Consultor chega à reunião <b>com plano pronto</b> por mentorado. Estrategistas validam e ajustam — não constroem do zero. Reunião de 2h vira validação eficiente.</p>
  </div>
  <div class="cs-card">
    <h4>3 · Ritmo para o mentorado</h4>
    <p>Cada mentorado recebe <b>plano novo todo início de mês</b>. Sai do limbo de "executa quando puder". Cadência clara: executa 3 semanas → é revisado → recebe plano novo.</p>
  </div>
</div>

## 6.2 · Como o ciclo funciona na prática

<div class="cs-month">
  <div class="cs-month-step exec">
    <div class="lbl">Semana 1</div>
    <div class="ttl">Execução</div>
    <div class="desc">Mentorado toca o plano aprovado. Consultor faz só Dedo no Pulso na segunda.</div>
  </div>
  <div class="cs-month-step exec">
    <div class="lbl">Semana 2</div>
    <div class="ttl">Execução</div>
    <div class="desc">Continua execução pura. Sem ronda profunda. Sem análise estratégica.</div>
  </div>
  <div class="cs-month-step exec">
    <div class="lbl">Semana 3</div>
    <div class="ttl">Execução</div>
    <div class="desc">Última semana de execução pura antes da varredura.</div>
  </div>
  <div class="cs-month-step scan">
    <div class="lbl">Semana 4 · seg–qui</div>
    <div class="ttl">Ronda Completa</div>
    <div class="desc">Consultor varre carteira inteira: Instagram, plano, dossiê, sinais. Output: plano sugerido por mentorado.</div>
  </div>
  <div class="cs-month-step raio">
    <div class="lbl">Semana 4 · sexta 15h</div>
    <div class="ttl">Raio-X</div>
    <div class="desc">2h com Hugo e Queila. Consultor chega com plano pronto. Estrategistas validam, não constroem.</div>
  </div>
</div>

<div class="cs-month" style="grid-template-columns: 1fr; margin-top: 8px;">
  <div class="cs-month-step dist">
    <div class="lbl">Semana seguinte · segunda</div>
    <div class="ttl">Distribuição → Volta ao topo do ciclo</div>
    <div class="desc">Consultor envia o plano aprovado para cada mentorado individualmente. Mentorado começa a executar. Próximas 3 semanas voltam a ser execução pura.</div>
  </div>
</div>

::: callout tip O ganho secreto do Raio-X
Além de organizar a operação, a Ronda Completa gera <b>insumo sistemático para os ativos de escala</b>: ao varrer 20 mentorados de uma vez, o consultor identifica gargalos recorrentes que viram ferramentas, checklists, aulas. É a engrenagem que alimenta a "construção de ferramentas" da seção 5.2.
:::

---

# 7. Capacidade do Consultor · Cabe ou Não Cabe?

::: callout quote A pergunta que originou esta seção
**"Se eu precisar fazer muitas reuniões, cabe na minha agenda?"**
:::

Esta pergunta vem da preocupação real do consultor: a carteira é de **20 mentorados** e cada um pode pedir onboarding, dossiê ou revisão em diferentes semanas. **Antes de aceitar mais um mentorado ou mais uma call extra, o consultor precisa saber se ainda cabe.**

A resposta exige uma conta simples: quantas horas tem na semana × quanto cada tipo de reunião consome.

## 7.1 · Custo total de cada reunião

Reunião não é só a hora da call. Inclui **preparação prévia** (no turno anterior) e **buffer pós-call** (para registrar no ClickUp).

<div class="cs-grid">
  <div class="cs-card">
    <h4>Onboarding</h4>
    <p>60min reunião + 15min buffer + 30min prep = <b>105 minutos</b></p>
  </div>
  <div class="cs-card">
    <h4>Dossiê</h4>
    <p>90min reunião + 15min buffer + 60min prep = <b>165 minutos</b></p>
  </div>
  <div class="cs-card">
    <h4>Revisão</h4>
    <p>60min reunião + 15min buffer + 30min prep = <b>105 minutos</b></p>
  </div>
</div>

## 7.2 · Quantas horas sobram para reuniões na semana

```
Jornada bruta             40 horas
Tirando atividades fixas  -12 horas
                          ─────────
Disponível para calls   = 28 horas (1.680 minutos)
```

As 12 horas fixas vão para: rondas de WhatsApp, dailies, Dedo no Pulso, Weekly, Raio-X amortizado mensalmente, foco profundo mínimo, construção de ferramentas e padronização.

## 7.3 · Cenários reais da carteira de 20 mentorados

<div class="cs-cap">
  <div class="cs-cap-cell ok">
    <div class="pct">41%</div>
    <div class="bar"><i style="width: 41%;"></i></div>
    <div class="nm">Folgada</div>
    <div class="sub">1 Onb · 1 Dos · 4 Rev</div>
  </div>
  <div class="cs-cap-cell ok">
    <div class="pct">54%</div>
    <div class="bar"><i style="width: 54%;"></i></div>
    <div class="nm">Folgada+</div>
    <div class="sub">1 Onb · 1 Dos · 6 Rev</div>
  </div>
  <div class="cs-cap-cell warn">
    <div class="pct">67%</div>
    <div class="bar"><i style="width: 67%;"></i></div>
    <div class="nm">Típica</div>
    <div class="sub">1 Onb · 3 Dos · 5 Rev</div>
  </div>
  <div class="cs-cap-cell warn">
    <div class="pct">83%</div>
    <div class="bar"><i style="width: 83%;"></i></div>
    <div class="nm">Pesada</div>
    <div class="sub">2 Onb · 4 Dos · 5 Rev</div>
  </div>
  <div class="cs-cap-cell bad">
    <div class="pct">105%</div>
    <div class="bar"><i style="width: 100%;"></i></div>
    <div class="nm">Estoura</div>
    <div class="sub">5 Onb · 5 Dos · 4 Rev</div>
  </div>
</div>

::: callout warn Resposta direta à pergunta
**Sim, cabe — até o cenário "Pesada".** Acima disso, o consultor está roubando tempo de foco profundo, contingência ou hora extra. **A carteira de 20 mentorados com 67% de aproveitamento é o ponto sustentável.** Mais que isso, qualquer imprevisto vira problema. Isso afeta decisões de venda e de expansão da equipe — saber esse teto evita prometer ao cliente um nível de atenção que não cabe.
:::

---

::: callout success Resumo do estado atual
**Existe** · desenho operacional consolidado em manual, princípios claros, calendário calibrado, capacidade dimensionada.

**Em curso** · entrada gradual da Eloise no CS · transição operacional do time.

**O Raio-X é a engrenagem central** · concentra análise estratégica em 1 semana/mês, transforma estrategistas em revisores, gera ritmo para o mentorado e alimenta a padronização.
:::
