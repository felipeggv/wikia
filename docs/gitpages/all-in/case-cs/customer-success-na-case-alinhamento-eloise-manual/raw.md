---
eyebrow: NOTA INTERNA · CASE · MAIO 2026
title: Customer Success na CASE · Alinhamento Eloise + Manual Resumido
lead: O que foi conversado com a Eloise, de onde vieram essas decisões, e como o trabalho do consultor está desenhado hoje. Documento para alinhar a sócia/sócios antes de qualquer próxima conversa sobre o tema.
tags: case, customer-success, operacao, mentoria, alinhamento
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

.cs-week { width: 100%; border-collapse: collapse; margin: 22px 0; font-size: 0.85em; }
.cs-week th, .cs-week td { border: 1px solid #2a4d3e; padding: 8px 10px; text-align: left; vertical-align: top; }
.cs-week th { background: #1a3d2e; color: #fff; text-transform: uppercase; letter-spacing: 0.08em; font-size: 0.78em; font-weight: 600; }
.cs-week td.lab { background: #0e2419; color: #7fb89a; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; font-size: 0.72em; width: 95px; }
.cs-tag { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 0.72em; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; }
.tag-daily { background: #2a4d3e; color: #b8d4c2; }
.tag-calls { background: #2a3d5e; color: #b8c4e0; }
.tag-pulse { background: #1a3d2e; color: #5fd8a0; }
.tag-rond { background: #5e4a1a; color: #e0d4b8; }
.tag-conf { background: #3d2a4d; color: #d4b8e0; }
.tag-weekly { background: #4d1a3d; color: #e0b8d4; }
.tag-free { background: #1a1a1a; color: #6a6a6a; }

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

.cs-flow { display: flex; gap: 8px; margin: 16px 0; flex-wrap: wrap; }
.cs-flow-step { flex: 1; min-width: 140px; padding: 10px 12px; border: 1px solid #2a4d3e; border-radius: 6px; background: #0e2419; position: relative; font-size: 0.85em; }
.cs-flow-step .num { font-size: 0.65em; color: #7fb89a; text-transform: uppercase; letter-spacing: 0.08em; font-weight: 700; }
.cs-flow-step .nm { font-weight: 600; margin-top: 2px; }
.cs-flow-step .sub { font-size: 0.75em; color: #8a9a90; margin-top: 4px; line-height: 1.4; }
.cs-flow-arrow { display: flex; align-items: center; color: #5fd8a0; font-weight: 700; }

.cs-pair { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 18px 0; }
.cs-pair > div { padding: 14px; border-radius: 8px; }
.cs-pair .yes { border: 1px solid #2a6e4a; background: rgba(42,110,74,0.12); }
.cs-pair .no { border: 1px solid #6e2a4a; background: rgba(110,42,74,0.12); }
.cs-pair h4 { margin: 0 0 10px 0; font-size: 0.9em; text-transform: uppercase; letter-spacing: 0.08em; }
.cs-pair .yes h4 { color: #5fd8a0; }
.cs-pair .no h4 { color: #d47ca0; }
.cs-pair ul { margin: 0; padding-left: 18px; font-size: 0.88em; line-height: 1.65; }
</style>

## Como Ler Este Documento

Está organizado em **5 blocos**, do mais importante pro mais detalhado:

```
1.  O que foi alinhado com a Eloise          ← o ponto central
2.  De onde veio esse alinhamento            ← origem e contexto
3.  O papel do Consultor de CS               ← responsabilidades resumidas
4.  Agenda da operação                       ← visual da semana e do mês
5.  Pendências em aberto                     ← decisões que faltam
```

---

# 1. Resumo do Alinhamento com a Eloise

Reunião de **14/05/2026** entre Felipe e Eloise. Conversa de pré-contratação para alinhar expectativa antes de ela entrar no time de CS.

<div class="cs-grid">
  <div class="cs-card ok">
    <h4>O que ficou decidido</h4>
    <p>O consultor é o <b>dono operacional</b> do mentorado. Toda reunião tem pré e pós. Toda promessa vira tarefa rastreável. CS ensina, não executa pelo mentorado. Dossiês ficam mais enxutos. Daily volta segunda a quinta no início do dia.</p>
  </div>
  <div class="cs-card">
    <h4>O que entra com a Eloise</h4>
    <p>Entrada <b>gradual</b>: ela acompanha reuniões, observa a Lara, estuda o manual de CS e começa por mentorados de baixa criticidade. Disponibilidade parcial (segunda 8h-9h fora; quinta e sexta presenciais em outra consultoria).</p>
  </div>
  <div class="cs-card warn">
    <h4>O que ainda depende de aval</h4>
    <p>Aval da diretoria para a entrada. Conversa com Keira e Ruba. Contrato e onboarding. Seleção dos mentorados iniciais. SLA formal de resposta. Ferramenta de visibilidade para o mentorado sem dar acesso ao ClickUp.</p>
  </div>
</div>

### As 17 Decisões Operacionais que Saíram da Reunião

<table class="cs-week">
<thead><tr><th style="width: 30px;">#</th><th>Decisão</th></tr></thead>
<tbody>
<tr><td>1</td><td>Toda reunião com mentorado tem <b>pré e pós</b> obrigatórios</td></tr>
<tr><td>2</td><td>Consultor é o <b>dono operacional</b> do mentorado · ponte com o time interno</td></tr>
<tr><td>3</td><td>Onboarding serve para <b>alinhar expectativa</b>, não para descoberta profunda</td></tr>
<tr><td>4</td><td>Dúvidas estratégicas passam pelo consultor antes de chegar aos sócios</td></tr>
<tr><td>5</td><td>Não existe call semanal individual com os sócios como padrão</td></tr>
<tr><td>6</td><td>Reuniões em cima da hora são exceção · padrão: <b>7 dias</b> de antecedência</td></tr>
<tr><td>7</td><td>Mudanças solicitadas pelo mentorado têm prazo oficial de <b>5 dias úteis</b></td></tr>
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
    <p><b>100%</b> · sem preparo no turno anterior, remarca.</p>
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

### Cadeia de Ajuda

<div class="cs-flow">
  <div class="cs-flow-step"><div class="num">Degrau 1</div><div class="nm">Consultor CS</div><div class="sub">Primeiro diagnóstico e tentativa responsável</div></div>
  <div class="cs-flow-arrow">→</div>
  <div class="cs-flow-step"><div class="num">Degrau 2</div><div class="nm">Dono da tarefa</div><div class="sub">Quando a dúvida depende daquela entrega ou área</div></div>
  <div class="cs-flow-arrow">→</div>
  <div class="cs-flow-step"><div class="num">Degrau 3</div><div class="nm">Felipe</div><div class="sub">Impasse, risco alto, mudança de regra</div></div>
  <div class="cs-flow-arrow">→</div>
  <div class="cs-flow-step"><div class="num">Degrau 4</div><div class="nm">Sócios</div><div class="sub">Risco financeiro · cancelamento · jurídico · regra que vira política</div></div>
</div>

### Pipeline do Dossiê · O Consultor Entra em 3 Momentos

<div class="cs-flow">
  <div class="cs-flow-step"><div class="num">Estágio 1</div><div class="nm">Esboço</div><div class="sub">Estrategista monta a primeira versão</div></div>
  <div class="cs-flow-arrow">→</div>
  <div class="cs-flow-step" style="border-color: #5fd8a0;"><div class="num" style="color: #5fd8a0;">CS · Revisor</div><div class="nm">Leva de revisão</div><div class="sub">Lê o esboço, comenta no doc, aponta gaps · <b>não reescreve</b></div></div>
  <div class="cs-flow-arrow">→</div>
  <div class="cs-flow-step"><div class="num">Estágio 3</div><div class="nm">Correções</div><div class="sub">Estrategista executa os apontamentos</div></div>
  <div class="cs-flow-arrow">→</div>
  <div class="cs-flow-step" style="border-color: #5fd8a0;"><div class="num" style="color: #5fd8a0;">CS · Estudante</div><div class="nm">Estudo final</div><div class="sub">Turno antes da apresentação · chega com domínio</div></div>
</div>

<p style="font-size: 0.85em; color: #8a9a90; margin-top: -8px;">O <b>terceiro</b> papel do consultor é <b>Cobrador</b>: quando a cadeia atrasa, ele cria ação imediata para destravar — sem virar substituto do estrategista.</p>

---

# 4. Agenda da Operação

A vida do consultor opera em **três camadas de tempo**.

## 4.1 · A Semana Modelo

<table class="cs-week">
<thead>
<tr><th></th><th>Segunda</th><th>Terça</th><th>Quarta</th><th>Quinta</th><th>Sexta</th></tr>
</thead>
<tbody>
<tr>
  <td class="lab">Início</td>
  <td><span class="cs-tag tag-daily">Daily</span></td>
  <td><span class="cs-tag tag-daily">Daily</span></td>
  <td><span class="cs-tag tag-daily">Daily</span></td>
  <td><span class="cs-tag tag-daily">Daily</span></td>
  <td><span class="cs-tag tag-daily">Daily</span></td>
</tr>
<tr>
  <td class="lab">Manhã</td>
  <td><span class="cs-tag tag-pulse">Dedo no Pulso</span><br><span style="font-size: 0.75em; color: #8a9a90;">9h–10h · revisa carteira</span></td>
  <td><span class="cs-tag tag-calls">Calls</span><br><span style="font-size: 0.75em; color: #8a9a90;">Onboarding / Dossiê / Revisão</span></td>
  <td><span class="cs-tag tag-calls">Calls</span><br><span style="font-size: 0.75em; color: #8a9a90;">Onboarding / Dossiê / Revisão</span></td>
  <td><span class="cs-tag tag-calls">Calls</span><br><span style="font-size: 0.75em; color: #8a9a90;">Onboarding / Dossiê / Revisão</span></td>
  <td><span class="cs-tag tag-free">Livre / Buffer</span></td>
</tr>
<tr>
  <td class="lab">~11h30</td>
  <td><span class="cs-tag tag-conf">Confirm. 15d</span></td>
  <td><span class="cs-tag tag-conf">Confirm. 15d</span></td>
  <td><span class="cs-tag tag-conf">Confirm. 15d</span></td>
  <td><span class="cs-tag tag-conf">Confirm. 15d</span></td>
  <td><span class="cs-tag tag-conf">Confirm. 15d</span></td>
</tr>
<tr>
  <td class="lab">Tarde</td>
  <td><span class="cs-tag tag-free">Livre</span></td>
  <td><span class="cs-tag tag-free">Livre</span></td>
  <td><span class="cs-tag tag-free">Livre</span></td>
  <td><span class="cs-tag tag-free">Livre</span></td>
  <td><span class="cs-tag tag-weekly">Weekly 15h–16h30</span></td>
</tr>
<tr>
  <td class="lab">Contínuo</td>
  <td colspan="5" style="text-align: center;"><span class="cs-tag tag-rond">Rondas WhatsApp · 4 a 5 vezes ao longo do dia</span></td>
</tr>
</tbody>
</table>

<p style="font-size: 0.82em; color: #8a9a90; margin-top: -6px;"><b>Regra da segunda:</b> sem reunião com mentorado. Dia reservado para planejar, revisar carteira e recuperar visibilidade.</p>

## 4.2 · As Rotinas por Tipo

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
</div>

## 4.3 · O Ciclo Mensal · Raio-X

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
    <div class="desc">4 dias varrendo carteira inteira: Instagram, plano, dossiê, sinais. Output: plano sugerido por mentorado.</div>
  </div>
  <div class="cs-month-step raio">
    <div class="lbl">Semana 4 · sexta 15h</div>
    <div class="ttl">Raio-X</div>
    <div class="desc">2h com estrategistas. Consultor chega com plano pronto. Estrategistas validam, não constroem.</div>
  </div>
</div>

<div class="cs-month" style="grid-template-columns: 1fr; margin-top: 8px;">
  <div class="cs-month-step dist">
    <div class="lbl">Semana seguinte · segunda</div>
    <div class="ttl">Distribuição → Volta ao topo do ciclo</div>
    <div class="desc">Consultor envia o plano aprovado para cada mentorado individualmente. Mentorado começa a executar. Próximas 3 semanas voltam a ser execução pura.</div>
  </div>
</div>

::: callout tip Por que esse desenho funciona
**Mata um leão por mês, não um por dia.** Concentrar análise profunda em uma semana evita o ciclo de caos. Estrategistas viram revisores, não produtores — reunião de 2h vira validação, não construção do zero. Mentorado sente cadência clara: executa 3 semanas, é revisado, recebe plano novo.
:::

## 4.4 · Capacidade do Consultor · Carteira de 20 Mentorados

Cada reunião tem **custo total** = reunião + buffer pós + preparação prévia.

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

**Jornada:** 40h brutas · −12h de atividades fixas (rondas, dailies, weekly, raio-x amortizado, foco) · **= 28h líquidas para calls.**

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

::: callout warn Recado da capacidade
Carteira de 20 mentorados/consultor com 67% de aproveitamento é **sustentável, mas apertada**. Os 33% que sobram pagam foco profundo, prep extra e imprevistos. Acima desse volume, qualquer escapada vira hora extra ou compromete qualidade. Isso afeta decisões de venda e expansão da equipe.
:::

---

# 5. Pendências em Aberto

Decisões verbalizadas mas que ainda não foram fechadas formalmente.

<div class="cs-grid">
  <div class="cs-card warn">
    <h4>Visibilidade para o mentorado</h4>
    <p>Mentorado não acessa ClickUp. Alternativas em discussão: doc fixado no WhatsApp, Google Agenda, Google Tasks, Notion, sistema próprio. <b>Falta decidir ferramenta e dono.</b></p>
  </div>
  <div class="cs-card warn">
    <h4>SLA formal de resposta</h4>
    <p>Usado verbalmente como "1 hora" e "prazo razoável". <b>Falta o SLA oficial e mensurável</b> por canal.</p>
  </div>
  <div class="cs-card warn">
    <h4>Horário final da daily</h4>
    <p>Em aberto entre 8h, 8h30 e 9h. <b>Falta bater o horário.</b></p>
  </div>
  <div class="cs-card warn">
    <h4>Escala terça/quarta 19h</h4>
    <p>Aulas precisam de consultor de apoio. <b>Falta definir nominalmente quem cobre cada dia.</b></p>
  </div>
  <div class="cs-card warn">
    <h4>Prazo de revisões internas</h4>
    <p>Calendário editorial tem 7 dias. <b>Falta prazo geral para outras revisões.</b></p>
  </div>
  <div class="cs-card warn">
    <h4>Madrinha da Eloise</h4>
    <p>Sugerida a Lara. <b>Falta confirmar.</b></p>
  </div>
  <div class="cs-card warn">
    <h4>Redistribuição da carteira</h4>
    <p>Eloise + consultora atual + substituição. <b>Falta lista nominal de quem fica com quem.</b></p>
  </div>
  <div class="cs-card warn">
    <h4>Rito único de sexta</h4>
    <p>Mencionado encontro de aprendizado de manhã e Weekly à tarde. <b>Falta decidir se coexistem ou se uma absorve a outra.</b></p>
  </div>
  <div class="cs-card warn">
    <h4>Processo de ativos reutilizáveis</h4>
    <p>Princípio decidido: pedidos repetidos viram aula/ferramenta/tutorial. <b>Falta dono operacional do processo.</b></p>
  </div>
</div>

::: callout success Resumo do estado atual
**Existe** · desenho operacional consolidado em manual, princípios claros, calendário calibrado, capacidade dimensionada.

**Em curso** · entrada gradual da Eloise no CS · transição operacional do time.

**Travado** · decisões da seção 5 acima · não há urgência única, é um pacote de "destrava de operação".
:::
