---
eyebrow: NOTA INTERNA · CASE · MAIO 2026
title: Customer Success na CASE · Como a Rotina do CS Funciona
lead: Este documento foi escrito a partir da pauta da reunião com a Eloise. Cobre o papel do consultor, as rotinas, a agenda da operação, uma calculadora de capacidade e os tópicos que conversamos.
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

/* ROTINAS · accordion sem numeração */
.cs-rotinas { list-style: none; padding: 0; margin: 18px 0; border: 1px solid #2a4d3e; border-radius: 8px; overflow: hidden; }
.cs-rotinas > li { border-bottom: 1px solid #2a4d3e; }
.cs-rotinas > li:last-child { border-bottom: none; }
.cs-rot-trigger { width: 100%; text-align: left; padding: 14px 18px; background: #0e2419; border: none; color: #f2f2c0; font: inherit; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 12px; transition: background 0.15s; font-size: 0.94em; }
.cs-rot-trigger:hover { background: rgba(42,110,74,0.18); }
.cs-rot-trigger::before { content: "▸"; color: #5fd8a0; transition: transform 0.2s; font-size: 0.85em; }
.cs-rot-trigger.open::before { transform: rotate(90deg); }
.cs-rot-trigger .tag { margin-left: auto; font-size: 0.7em; font-weight: 600; text-transform: uppercase; letter-spacing: 0.06em; padding: 2px 8px; border-radius: 3px; }
.cs-rot-trigger .tag.fix { background: #1a3d2e; color: #5fd8a0; }
.cs-rot-trigger .tag.call { background: #2a3d5e; color: #b8c4e0; }
.cs-rot-trigger .tag.foco { background: #4d2a6e; color: #d4b8e0; }
.cs-rot-body { padding: 0 18px; max-height: 0; overflow: hidden; transition: max-height 0.3s ease-out, padding 0.3s ease-out; background: #0a1814; }
.cs-rot-body.open { padding: 14px 18px 18px; max-height: 4000px; }
.cs-rot-body .row { display: grid; grid-template-columns: 110px 1fr; gap: 12px; padding: 6px 0; border-bottom: 1px dashed #1a3d2e; font-size: 0.88em; }
.cs-rot-body .row:last-child { border-bottom: none; }
.cs-rot-body .row .key { color: #7fb89a; font-size: 0.78em; text-transform: uppercase; letter-spacing: 0.06em; font-weight: 600; }
.cs-rot-body .row .val { color: #d4d4c0; line-height: 1.55; }
.cs-rot-body .pipeline { margin-top: 10px; padding: 10px 12px; border-radius: 6px; background: rgba(26,61,46,0.25); border: 1px solid #2a4d3e; font-size: 0.85em; }
.cs-rot-body .pipeline ol { margin: 6px 0 0 18px; padding: 0; }
.cs-rot-body .pipeline ol li { padding: 3px 0; }
.cs-rot-body .pipeline .cs { color: #5fd8a0; font-weight: 600; }

/* AGENDA · semana lúdica */
.cs-agenda { width: 100%; border-collapse: collapse; margin: 18px 0; font-size: 0.82em; }
.cs-agenda th, .cs-agenda td { border: 1px solid #2a4d3e; padding: 8px 10px; text-align: center; vertical-align: middle; }
.cs-agenda th { background: #1a3d2e; color: #fff; text-transform: uppercase; letter-spacing: 0.06em; font-size: 0.74em; font-weight: 600; }
.cs-agenda td.period { background: #0e2419; color: #7fb89a; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; font-size: 0.74em; width: 90px; }
.cs-agenda .a-fix { display: inline-block; padding: 4px 10px; border-radius: 4px; font-size: 0.78em; font-weight: 600; }
.cs-agenda .fix-daily { background: #2a4d3e; color: #b8d4c2; }
.cs-agenda .fix-pulse { background: #1a3d2e; color: #5fd8a0; border: 1px solid #2a6e4a; }
.cs-agenda .fix-conf { background: #3d2a4d; color: #d4b8e0; }
.cs-agenda .fix-rond { background: #5e4a1a; color: #e0d4b8; }
.cs-agenda .fix-weekly { background: #4d1a3d; color: #e0b8d4; }
.cs-agenda .a-livre { padding: 6px 8px; border: 1px dashed #4a5a4a; border-radius: 4px; color: #8a9a90; font-size: 0.78em; font-style: italic; }
.cs-anchors { margin: 10px 0; padding: 10px 14px; background: rgba(26,61,46,0.18); border-left: 3px solid #5fd8a0; border-radius: 0 4px 4px 0; font-size: 0.85em; }
.cs-anchors b { color: #5fd8a0; }

/* CALCULADORA · capacidade interativa */
.cs-calc { margin: 20px 0; padding: 20px; border: 1px solid #2a6e4a; border-radius: 10px; background: rgba(26,61,46,0.2); }
.cs-calc h4 { margin: 0 0 4px 0; color: #5fd8a0; font-size: 0.95em; text-transform: uppercase; letter-spacing: 0.08em; }
.cs-calc p.hint { margin: 0 0 14px 0; font-size: 0.84em; color: #8a9a90; }
.cs-calc-inputs { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 18px; }
.cs-calc-inputs label { display: flex; flex-direction: column; gap: 4px; font-size: 0.78em; color: #7fb89a; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600; }
.cs-calc-inputs input { background: #0a1814; border: 1px solid #2a4d3e; color: #f2f2c0; padding: 8px 10px; border-radius: 4px; font: inherit; font-size: 1.1em; font-weight: 600; text-align: center; }
.cs-calc-inputs input:focus { outline: none; border-color: #5fd8a0; }
.cs-calc-out { display: grid; grid-template-columns: 1fr 2fr; gap: 18px; align-items: center; padding: 14px 18px; background: #0a1814; border-radius: 6px; }
.cs-calc-pct { font-size: 2.6em; font-weight: 700; line-height: 1; }
.cs-calc-pct.ok { color: #5fd8a0; }
.cs-calc-pct.warn { color: #d4a857; }
.cs-calc-pct.bad { color: #d47857; }
.cs-calc-bar { height: 6px; background: #2a4d3e; border-radius: 3px; overflow: hidden; margin: 10px 0; }
.cs-calc-bar > i { display: block; height: 100%; transition: width 0.25s ease-out; }
.cs-calc-bar > i.ok { background: linear-gradient(90deg, #5fd8a0, #2a6e4a); }
.cs-calc-bar > i.warn { background: linear-gradient(90deg, #d4a857, #6e4d1a); }
.cs-calc-bar > i.bad { background: linear-gradient(90deg, #d47857, #6e2a1a); }
.cs-calc-status { font-size: 0.88em; color: #d4d4c0; line-height: 1.5; }
.cs-calc-status .label { font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; font-size: 0.78em; }

.cs-pair { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 18px 0; }
.cs-pair > div { padding: 14px; border-radius: 8px; }
.cs-pair .yes { border: 1px solid #2a6e4a; background: rgba(42,110,74,0.12); }
.cs-pair .no { border: 1px solid #6e2a4a; background: rgba(110,42,74,0.12); }
.cs-pair h4 { margin: 0 0 10px 0; font-size: 0.9em; text-transform: uppercase; letter-spacing: 0.08em; }
.cs-pair .yes h4 { color: #5fd8a0; }
.cs-pair .no h4 { color: #d47ca0; }
.cs-pair ul { margin: 0; padding-left: 18px; font-size: 0.88em; line-height: 1.65; }
</style>

# 1. A Pauta da Reunião

Em **14 de maio de 2026**, Felipe e Eloise sentaram para um alinhamento de pré-contratação. A pauta foi simples: **como a rotina do CS funciona aqui dentro**.

Este documento responde a essa pauta. Mostra o papel do consultor, as rotinas que ele opera, a agenda em que essas rotinas se distribuem, e uma calculadora para dimensionar capacidade. No final, um resumo curto dos tópicos que apareceram na conversa.

::: callout quote O princípio que sustenta tudo
**CS ensina. CS não faz.**
O consultor sustenta o processo enquanto o mentorado aprende a carregar o próprio negócio. Adulto aprende quando aplica critério em problema real, não quando assiste outra pessoa resolver.
:::

---

# 2. O Papel do Consultor de CS

O consultor é o **dono operacional** de uma carteira de até 20 mentorados. Pensa nele como um gerente de conta que cuida da saúde do negócio do cliente — mas **não produz pelo cliente**.

<div class="cs-pair">
  <div class="yes">
    <h4>✓ O que o consultor faz</h4>
    <ul>
      <li>Dá critério para o mentorado decidir</li>
      <li>Revisa o raciocínio</li>
      <li>Cobra prazo e qualidade</li>
      <li>Aponta gaps no dossiê (não reescreve)</li>
      <li>Orienta calendário editorial</li>
      <li>Transforma pedido repetido em ativo reutilizável</li>
    </ul>
  </div>
  <div class="no">
    <h4>✕ O que o consultor não faz</h4>
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
    <h4>Combinados rastreáveis</h4>
    <p><b>100%</b> no ClickUp · zero promessa solta · tudo vira tarefa com prazo e dono.</p>
  </div>
  <div class="cs-card">
    <h4>Carteira ativa</h4>
    <p>Até <b>20 mentorados</b> por consultor para manter qualidade.</p>
  </div>
  <div class="cs-card">
    <h4>Aproveitamento sustentável</h4>
    <p><b>67%</b> da semana em reuniões · 33% para foco, prep extra e contingência.</p>
  </div>
  <div class="cs-card">
    <h4>Reuniões com prep</h4>
    <p><b>100%</b> · sem preparação no turno anterior, remarca.</p>
  </div>
</div>

---

# 3. As Rotinas do CS

O trabalho do consultor cai em três tipos: **rotinas fixas** (acontecem todo dia/semana/mês no mesmo lugar), **reuniões com mentorado** (variam entre onboarding, dossiê e alinhamentos), e **trabalho de foco profundo** (solo, sem mentorado).

Clica em cada rotina para ver detalhamento.

<ol class="cs-rotinas" data-cs-rotinas>

<li>
<button class="cs-rot-trigger">Daily / Stand-up Assíncrono<span class="tag fix">Fixa · diária</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Registro curto de progresso. Não é reunião — é nota no ClickUp.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Segunda a quinta, no início do dia (entre 8h e 9h).</span></div>
<div class="row"><span class="key">Duração</span><span class="val">~15 minutos.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">3 linhas no canal do time: o que fechei ontem, o que farei hoje, onde travei.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">"Tá tudo bem" sem trazer bloqueio real. Daily sem update útil consome tempo do time e não devolve nada.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Rondas de WhatsApp<span class="tag fix">Fixa · diária</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Varrer conversas com mentorados, responder pendências, cobrar retorno, fechar loops.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">4 a 5 vezes ao longo do dia · cedo, antes do almoço, meio da tarde, fim de expediente.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">~10 minutos cada · fecha quando a fila zera, não pelo relógio.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">2 frentes: <b>proativa</b> (situar o mentorado em que etapa está, fixar planejamento no grupo) e <b>reativa</b> (varrer dúvidas não respondidas, organizar lista para áudios dos especialistas).</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">"Rolando conversas" — ficar no WhatsApp o dia todo sem objetivo claro. Ronda tem início, meio e fim.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Confirmação de Reuniões · 15 dias<span class="tag fix">Fixa · diária</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Funil de confirmação das reuniões marcadas para os próximos 15 dias. Só quem ainda não confirmou entra na lista do dia.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Fim da manhã, todo dia útil.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">~10 minutos.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Olha quem ainda não confirmou a reunião dos próximos 15 dias e manda mensagem direta. Se confirmou, sai da fila.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">Confirmar tudo na véspera. Se alguém desmarca em cima da hora, não dá tempo de remanejar nem avisar a produção do dossiê.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Dedo no Pulso<span class="tag fix">Fixa · semanal</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Revisão semanal da carteira inteira. O consultor olha cada mentorado e responde 4 perguntas: tá vendendo? tá executando o plano? tá produzindo conteúdo? onde travou?</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Toda segunda-feira pela manhã.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">60 minutos.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Postura "segunda é o dia mundial do recomeço" — vamos do zero se precisar, sem culpa por não ter começado.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">Entrar na semana cego, sem ter olhado o mapa da carteira. O resto da semana vira reação a quem grita mais alto.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Weekly Produto + CS<span class="tag fix">Fixa · semanal</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Reunião do time interno (Kaique, Marisa, Lara, Heitor, Felipe) para alinhar prioridades da próxima semana, ancoradas nos aprendizados da semana que está fechando.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Toda sexta-feira, 15h–16h30.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">90 minutos.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Cada um chega com 1 bloqueio, 1 aprendizado, 1 pergunta. Saída: direcionamento de agenda da semana que vem alinhado entre Produto e CS.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">"Ritual passivo" — comparecer sem preparar nada. Cria ilusão de alinhamento.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Raio-X dos Mentorados<span class="tag fix">Fixa · mensal</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Análise estratégica concentrada em uma única semana do mês. Resolve o "matar um leão por dia" da operação.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Última semana do mês. Seg–qui = Ronda Completa (varrer carteira). Sexta 15h = Raio-X com Queila e Hugo.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">4 dias úteis de varredura + 2h de validação com estrategistas.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Na varredura, o consultor analisa por mentorado: Instagram, plano, dossiê, sinais. Output: plano sugerido por mentorado. No Raio-X, ele chega <b>com plano pronto</b> — estrategistas <b>validam</b>, não constroem do zero. Distribuição na segunda seguinte.</span></div>
<div class="row"><span class="key">Por que funciona</span><span class="val">Concentra análise (libera 3 semanas para execução pura), transforma estrategistas em revisores (não produtores), gera ritmo para o mentorado (plano novo todo início de mês), e alimenta a padronização (gargalos identificados viram ferramentas).</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Onboarding<span class="tag call">Reunião · variável</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Primeira reunião com o mentorado novo. Serve para <b>alinhar expectativa</b>, não para descoberta profunda.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">No início da jornada do mentorado, na semana de entrada.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">60 min de call + 30 min de prep no turno anterior + 15 min de buffer pós · <b>105 min totais</b>.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Cliente sai entendendo: pessoas do grupo, canais, responsáveis, acessos, aulas, call de estratégia, próximos 30 dias, contrato. Termina com PDF de resumo enviado.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">Tratar como "descoberta profunda do cliente". Não é. É alinhamento de expectativa para o cliente saber como a mentoria funciona.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Apresentação de Dossiê<span class="tag call">Reunião · variável</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Call em que o consultor apresenta o dossiê estratégico já produzido para o mentorado.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Após a versão final do dossiê estar aprovada na cadeia de produção.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">90 min de call + 60 min de prep no turno anterior + 15 min de buffer · <b>165 min totais</b>.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Foco: validar oferta/produto, depois funil, depois geração de demanda por conteúdo. Dossiê <b>simplificado</b>: storytelling longo fica como material interno, não no centro da apresentação.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">Chegar sem ter estudado o dossiê final no turno anterior. Cliente percebe na hora — vira call de atualização genérica em vez de avanço real.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Revisão / Alinhamentos<span class="tag call">Reunião · variável</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Calls de apoio com o mentorado: alinhar execução, tirar dúvidas estratégicas mediadas, ajustar plano de ação.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Conforme a fase do mentorado pede. Cap operacional: 4 a 6 slots por semana, default 5.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">60 min de call + 30 min de prep + 15 min de buffer · <b>105 min totais</b>.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Plano de ação gerado na reunião vira tarefa no ClickUp com responsável, prazo e entrega esperada. Sem promessa solta.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">Aceitar reunião em cima da hora como regra. Padrão é 7 dias de antecedência. Exceção exige pauta e convite imediato.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Revisão de Dossiê<span class="tag foco">Foco profundo · solo</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Trabalho solo do consultor para ler o dossiê produzido pelo estrategista, comentar no documento, apontar gaps e incoerências. <b>Não é reunião.</b></span></div>
<div class="row"><span class="key">Quando</span><span class="val">Encaixado em blocos de foco profundo, em algum momento entre a 1ª entrega e a apresentação ao cliente.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">Variável (~60 min por dossiê), em bloco de foco sem interrupção.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Lê o documento, comenta na lateral, aponta o que está frágil ou incompleto. Não reescreve.</span></div>
<div class="pipeline">
<b>Pipeline real do dossiê</b> · 7 estágios (o consultor entra nos pontos marcados em verde):
<ol>
<li>Pós-call do mentorado · estrategista captura pontos discutidos</li>
<li>1ª Entrega · estrategista produz primeira versão</li>
<li class="cs">Revisão da 1ª Entrega · <b>consultor</b> comenta no doc, aponta gaps · não reescreve</li>
<li>Execução dos ajustes · estrategista incorpora apontamentos</li>
<li class="cs">Aprovação final · <b>consultor</b> confirma que está pronto</li>
<li>Entrega ao cliente · documento sobe para o mentorado</li>
<li class="cs">Call de Apresentação · <b>consultor</b> apresenta (vide rotina acima)</li>
</ol>
</div>
<div class="row"><span class="key">Armadilha</span><span class="val">"Consultor escrevendo dossiê" — quando o estrategista atrasa e o consultor começa a reescrever parágrafos para ajudar. O papel correto quando a cadeia atrasa é <b>cobrador</b>, não substituto.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Construção de Ferramentas e Checklists<span class="tag foco">Foco profundo · solo</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Quando uma demanda aparece repetidamente entre mentorados, o consultor cria um ativo reutilizável (ferramenta, checklist, vídeo curto, tutorial) em vez de responder individualmente.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Em blocos de foco profundo. Insumo principal: gargalos identificados na Ronda Completa do Raio-X.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">Variável — geralmente bloco ≥ 2h sem interrupção.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Identifica padrão de pedido repetido → transforma em ativo escalável → distribui com suporte dos consultores. Resolve 1 vez e atende 10 mentorados.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">"Foco fatiado" — tentar construir ferramenta em pedaços de 15 minutos entre outras atividades. Bloco ≥ 2h é regra.</span></div>
</div>
</li>

<li>
<button class="cs-rot-trigger">Padronização de Processos<span class="tag foco">Foco profundo · solo</span></button>
<div class="cs-rot-body">
<div class="row"><span class="key">O que é</span><span class="val">Documentar o que funcionou e o que não funcionou em cada ciclo. Atualizar templates de onboarding/dossiê/follow-up. Propor mudanças no manual.</span></div>
<div class="row"><span class="key">Quando</span><span class="val">Após o Raio-X mensal (com gargalos frescos) e ao longo do mês em blocos de foco profundo.</span></div>
<div class="row"><span class="key">Duração</span><span class="val">Variável.</span></div>
<div class="row"><span class="key">Como fazer</span><span class="val">Pega o aprendizado do ciclo, atualiza o template, propõe a mudança. Próximo ciclo executa com o template novo.</span></div>
<div class="row"><span class="key">Armadilha</span><span class="val">Deixar a lição na cabeça e não no template. Próximo consultor (ou Eloise no onboarding) repete o erro.</span></div>
</div>
</li>

</ol>

<script>
(function() {
  function init() {
    document.querySelectorAll('[data-cs-rotinas] .cs-rot-trigger:not([data-init])').forEach(btn => {
      btn.setAttribute('data-init', '1');
      btn.addEventListener('click', () => {
        const body = btn.nextElementSibling;
        btn.classList.toggle('open');
        body.classList.toggle('open');
      });
    });
  }
  init();
  document.addEventListener('wikia:unlocked', init);
})();
</script>

---

# 4. A Agenda da Operação

A semana modelo do consultor combina **rotinas-âncora** (acontecem sempre no mesmo horário, todo dia ou toda semana) e **blocos livres** (preenchidos conforme a semana pede — uma reunião ou um bloco de foco).

<div class="cs-anchors">
<b>As âncoras fixas da semana:</b><br>
Daily no início do dia · Rondas de WhatsApp 4 a 5×/dia · Confirmação de Reuniões 15d no fim da manhã · Dedo no Pulso na segunda · Weekly Produto+CS na sexta tarde · Raio-X na última semana do mês.
</div>

<table class="cs-agenda">
<thead>
<tr><th></th><th>Segunda</th><th>Terça</th><th>Quarta</th><th>Quinta</th><th>Sexta</th></tr>
</thead>
<tbody>
<tr>
  <td class="period">Manhã</td>
  <td><span class="a-fix fix-daily">Daily</span><br><span class="a-fix fix-pulse">Dedo no Pulso</span></td>
  <td><span class="a-fix fix-daily">Daily</span><br><span class="a-livre">Reunião ou Foco</span></td>
  <td><span class="a-fix fix-daily">Daily</span><br><span class="a-livre">Reunião ou Foco</span></td>
  <td><span class="a-fix fix-daily">Daily</span><br><span class="a-livre">Reunião ou Foco</span></td>
  <td><span class="a-fix fix-daily">Daily</span><br><span class="a-livre">Foco ou Buffer</span></td>
</tr>
<tr>
  <td class="period">Fim manhã</td>
  <td colspan="5" style="background:rgba(61,42,77,0.15);"><span class="a-fix fix-conf">Confirmação de Reuniões dos próximos 15 dias</span></td>
</tr>
<tr>
  <td class="period">Tarde</td>
  <td><span class="a-livre">Reunião ou Foco</span></td>
  <td><span class="a-livre">Reunião ou Foco</span></td>
  <td><span class="a-livre">Reunião ou Foco</span></td>
  <td><span class="a-livre">Reunião ou Foco</span></td>
  <td><span class="a-fix fix-weekly">Weekly Produto + CS · 15h–16h30</span></td>
</tr>
<tr>
  <td class="period">Contínuo</td>
  <td colspan="5" style="background:rgba(94,74,26,0.12);"><span class="a-fix fix-rond">Rondas de WhatsApp · 4 a 5 vezes ao longo do dia</span></td>
</tr>
</tbody>
</table>

::: callout tip Como o consultor preenche os blocos livres
**"Reunião"** pode ser uma das três: Onboarding, Apresentação de Dossiê, ou Revisão/Alinhamentos.
**"Foco"** pode ser uma das três: Revisão de Dossiê (leitura solo), Construção de Ferramentas, ou Padronização de Processos.

A cabeça do consultor distribui esses blocos conforme a semana pede. Segunda-feira costuma ser mais carregada de foco (depois do Dedo no Pulso) e sem reunião com mentorado, para recuperar visibilidade. Terça/quarta/quinta concentram as calls. Sexta tem buffer de manhã e Weekly à tarde.
:::

---

# 5. Capacidade do Consultor · Cabe ou Não Cabe?

A pergunta que orientou esta seção: **se eu precisar fazer muitas reuniões na semana, ainda cabe na minha agenda?**

A conta tem duas pontas. Por um lado, o consultor tem **28 horas líquidas por semana** para reuniões (40h brutas menos 12h de rotinas-âncora + foco mínimo). Por outro, cada reunião consome **prep + call + buffer**:

- **Onboarding** · 30 + 60 + 15 = **105 min**
- **Apresentação de Dossiê** · 60 + 90 + 15 = **165 min**
- **Revisão / Alinhamentos** · 30 + 60 + 15 = **105 min**

A calculadora abaixo aplica essa conta direto. Mexe nos campos e vê o que acontece.

<div class="cs-calc" id="cs-calc">
  <h4>Calculadora · capacidade semanal do consultor</h4>
  <p class="hint">Inputs · ajuste os números para simular sua semana</p>
  <div class="cs-calc-inputs">
    <label>Mentorados na carteira<input type="number" id="cs-i-ment" value="20" min="1" max="40"></label>
    <label>Onboardings na semana<input type="number" id="cs-i-onb" value="1" min="0" max="10"></label>
    <label>Apresentações de Dossiê<input type="number" id="cs-i-dos" value="3" min="0" max="10"></label>
    <label>Revisões / Alinhamentos<input type="number" id="cs-i-rev" value="5" min="0" max="10"></label>
  </div>
  <div class="cs-calc-out">
    <div>
      <div class="cs-calc-pct ok" id="cs-o-pct">67%</div>
    </div>
    <div>
      <div class="cs-calc-bar"><i class="ok" id="cs-o-bar" style="width:67%"></i></div>
      <div class="cs-calc-status">
        <span class="label" id="cs-o-label" style="color:#d4a857;">Sustentável · apertado</span><br>
        <span id="cs-o-detail">5h15 sobrando na semana para foco profundo, prep extra e contingência.</span>
      </div>
    </div>
  </div>
</div>

<script>
(function() {
  function fmt(min) {
    const h = Math.floor(Math.abs(min) / 60);
    const m = Math.abs(min) % 60;
    return (min < 0 ? '−' : '') + h + 'h' + (m < 10 ? '0' : '') + m;
  }
  function calc() {
    const onb = +document.getElementById('cs-i-onb').value || 0;
    const dos = +document.getElementById('cs-i-dos').value || 0;
    const rev = +document.getElementById('cs-i-rev').value || 0;
    const total = onb*105 + dos*165 + rev*105;
    const cap = 1680;
    const pct = Math.round(total / cap * 100);
    const sobra = cap - total;
    const pctEl = document.getElementById('cs-o-pct');
    const barEl = document.getElementById('cs-o-bar');
    const lblEl = document.getElementById('cs-o-label');
    const detEl = document.getElementById('cs-o-detail');
    pctEl.textContent = pct + '%';
    barEl.style.width = Math.min(pct, 100) + '%';
    let cls, label, detail;
    if (pct < 55) {
      cls = 'ok'; label = 'Folgada'; lblEl.style.color = '#5fd8a0';
      detail = fmt(sobra) + ' sobrando na semana. Bastante espaço para foco profundo, gravação de conteúdo, absorção de imprevistos.';
    } else if (pct < 75) {
      cls = 'ok'; label = 'Sustentável · típica'; lblEl.style.color = '#5fd8a0';
      detail = fmt(sobra) + ' sobrando na semana para foco profundo, prep extra e contingência.';
    } else if (pct < 95) {
      cls = 'warn'; label = 'No limite · sustentável só por 1 semana isolada'; lblEl.style.color = '#d4a857';
      detail = fmt(sobra) + ' de sobra apenas. Foco profundo cai para o mínimo. Qualquer imprevisto força hora extra.';
    } else if (pct <= 100) {
      cls = 'warn'; label = 'Saturado · sem margem'; lblEl.style.color = '#d4a857';
      detail = fmt(sobra) + ' de sobra. Toda contingência sumiu. Imprevisto = hora extra garantida.';
    } else {
      cls = 'bad'; label = 'Estoura · inviável recorrente'; lblEl.style.color = '#d47857';
      detail = 'Estoura em ' + fmt(total - cap) + '. Reuniões precisam ser reduzidas ou redistribuídas para semana seguinte.';
    }
    pctEl.className = 'cs-calc-pct ' + cls;
    barEl.className = cls;
    lblEl.textContent = label;
    detEl.textContent = detail;
  }
  function bind() {
    ['cs-i-ment','cs-i-onb','cs-i-dos','cs-i-rev'].forEach(id => {
      const el = document.getElementById(id);
      if (el && !el.dataset.init) {
        el.dataset.init = '1';
        el.addEventListener('input', calc);
      }
    });
    calc();
  }
  bind();
  document.addEventListener('wikia:unlocked', bind);
})();
</script>

::: callout warn O que a calculadora revela
Carteira de 20 mentorados com **1 Onb + 3 Dossiê + 5 Revisões** dá 67% — sustentável. Sobe para **2 Onb + 4 Dossiê + 5 Revisões** e já vai a 83%, no limite. Acima disso, qualquer imprevisto vira hora extra. **Esse teto afeta decisões de venda e expansão da equipe.**
:::

---

# 6. Tópicos da Reunião com a Eloise

A conversa de 14/05 não criou regra nova. Ela validou e reforçou o que o manual de CS já estabelecia, e identificou pontos que estavam verbalizados mas não consolidados. Os principais tópicos discutidos:

A reunião abriu com o **diagnóstico do que vinha falhando**: combinados que se perdiam fora do ClickUp, reuniões mal preparadas, dossiês apresentados sem revisão prévia, dúvidas estratégicas do cliente ficando sem resposta. Felipe deixou claro à Eloise que o problema central não é falta de sofisticação estratégica — é falha no básico operacional.

A partir disso, conversamos sobre o **papel do consultor como dono operacional do mentorado** — equivalente a um Product Owner. O consultor é a ponte entre o cliente e a equipe interna, traduz a necessidade do mentorado para os especialistas e devolve resposta. Não existe call semanal individual com Hugo e Queila como padrão; o consultor é quem media.

Discutimos as **rotinas-âncora** que precisam estar sempre presentes (Daily, Rondas, Confirmação 15d, Dedo no Pulso, Weekly), os **três tipos de reunião com mentorado** (Onboarding, Apresentação de Dossiê, Revisão/Alinhamentos), e o **trabalho de foco profundo** que cabe ao consultor solo (revisão de dossiê, construção de ferramentas, padronização).

Conversamos sobre o **Raio-X mensal** como engrenagem central da operação: concentrar análise estratégica em uma semana resolve o ciclo de "matar um leão por dia" e transforma Hugo e Queila em revisores em vez de produtores de plano do zero.

Falamos sobre o **escopo da consultoria**: educa e revisa, não executa pelo mentorado. Calendário editorial pode ser revisado com antecedência; copy não se escreve pelo cliente. Pedidos repetidos viram ativos reutilizáveis (aulas, ferramentas, vídeos).

A Eloise validou a estrutura e fez observações sobre **visibilidade do mentorado** (proposta de documento fixado no grupo) e sobre **disponibilidade pessoal** (compromissos em outra consultoria nas quintas e sextas). Combinamos uma entrada **gradual** dela na operação, começando como observadora em reuniões com Felipe e acompanhando a Lara, antes de assumir mentorados próprios.

::: callout info Como esses tópicos se conectam ao Manual de CS
Tudo o que apareceu na conversa está consolidado no **Manual do CS** (ClickUp Doc `8cj22vu-11751`) e no documento **CS Rotinas** (`8cj22vu-11311`). O manual é a consolidação dos erros que o time aprendeu ao longo da jornada — cada decisão verbalizada na reunião corresponde a uma lição operacional registrada lá. Este handoff é a versão executiva desse mesmo conteúdo.
:::
