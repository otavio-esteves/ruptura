# Atualização0.4 — executivo / corporativo

Novo direcionamento autorizado pelo usuário: protagonista executivo de terno preto, antes aspirante a diretor; arte corporativa mais escura inspirada na síntese cromática de Superfighters; esquerdo move e orienta a mira, direito preciso independente opcional. A confirmação do usuário resolveu a menção inicial ambígua ao analógico esquerdo opcional.

Entregues nova roupa/rosto/paleta, três setores com escritórios e conselho, textos e GDDv1.3 coerentes, opção de mira persistida sem alterar saves da missão, inimigos com maior pressão por cadência/mobilidade/dano e reposicionamento com obstáculos. A aprovação de dificuldade/conforto/arte continua dependente de jogar. Não há ampliação da campanha neste ciclo.

---

# Atualização visual0.3.1

Pedido atual: melhorar pixel art e animação. Atlas originais e renderer compartilhado substituem os corpos temporários, com ciclos de passada, recuo, respiração, salto/ápice/queda, aterrissagem, crouch, esquiva, dano e morte. Armas independentes, materiais de cenário/props/item mais legíveis, filtragem nearest e snapping visual. Sem novos sistemas de campanha ou mudanças intencionais de física/combat.

Ferramentas de autoria e prévias em [ART_DIRECTION](ART_DIRECTION.md). Aceite de sensação/aparência permanece com playtest humano. A missão e o laboratório continuam com o escopo0.3 descrito abaixo.

---

# Estado atual — build0.3 Cinzas

Entregue um recorte maior da missão: três setores, quatro encontros comuns, Chacal em duas fases, rotas altas, dois documentos opcionais, prova obrigatória e transmissão com desfecho. Laboratório0.2 preservado como modo separado. Novos saves e opções de mira/efeitos, HUD do chefe e feedback de arma/movimento.

A implementação aproxima os conteúdos previstos para a slice, mas não aprova seus gates. Não há medição de duração, aceite artístico, playtest externo nos dois dispositivos ou benchmark prolongado aprovado. Os demais capítulos continuam fora da produção. Próximo trabalho orientado por [PLAYTEST](PLAYTEST.md), com ajustes e correções do recorte antes de novo conteúdo.

---

# Histórico — build0.2 de combate

Incremento atual: Marco2 em uma arena curta, com início de objetos interativos do Marco3. Não é aprovação da vertical slice nem início de produção da campanha.

Entregues: duas armas, recarga/cancelamento, golpe, dano/esquiva, dois inimigos, navegação autorada, props destrutíveis, explosões com LOS, pickups, três encontros, evidência/transmissão, HUD, retry e save versionado. Opções incluem volume, modo assistido no próximo retry, remapeamento de oito ações de teclado e preset A/LB acessível pelo menu.

A suíte integrada executou171 verificações; mais duas regressões de remapeamento foram acrescentadas e passaram no teste específico. Inclui percurso de missão, persistência, mortes, dez resets sem acumulação de entidades e salto/queda reais dos inimigos. Importação e sessão gráfica sem erros. Capturas de menu/opções/combate inspecionadas pelo integrador. A validação humana e o benchmark longo continuam abertos.

Próximo passo de produto: playtest de [PLAYTEST](PLAYTEST.md), ajustes de sensação/curva de dificuldade e só então avanço da slice. Não declarar campanha ou chefão completos. Horas humanas continuam não informadas; este ciclo usa três especialistas com integração central. Nenhum gasto pago/publicação.

---

# Histórico — ciclo inicial

O plano raiz define todos os marcos; este registro acompanha apenas o incremento atual.

- Marco0: Git e contratos criados, versão local confirmada4.7.2, projeto Compatibility, menu, arena, coleta de ambiente e ferramentas.
- Marco1 parcial: movimento, crouch, plataformas, coyote/buffer, esquiva, mira mouse/controle, preset A/LB, câmera e reset.
- Gates pendentes: playtest humano mouse/controle, áudio audível, remapeamento, foco/reconexão e conforto a30/60FPS. Uma captura automatizada curta não aprova benchmark de combate ou10min.
- Próximo ciclo: ajustar controle após feedback, depois iniciar pistola, dano e um recruta conforme Marco2. Não produzir capítulos antes da slice.

Disponibilidade semanal e horas de atenção humana de Otávio não informadas. Não inferir prazos nem declarar aceite humano a partir dos arquivos.

## Resultado do ciclo de25/10/2026

Três especialistas concluíram controle, cenário e QA; o integrador revisou e uniu as entregas. Importação,21 checks e exportação Linux passaram. Pacote gráfico executado fora do projeto no Dell; escrita local confirmada. Capturas foram inspecionadas e a sobreposição do menu corrigida. Benchmark final cancelado por perda de foco; gates de desempenho longo, sensação, controle físico e áudio audível continuam abertos. Marco0 tem fundação entregue, mas seu aceite completo permanece condicionado a essas verificações; Marco1 é parcial.

Execução dos agentes e integração: aproximadamente8min de relógio desde a base Git (19:35–19:43 BRT), com três frentes paralelas; não equivale à soma do tempo de computação. Tempo individual dos agentes não instrumentado. Atenção humana, retrabalho de playtest e disponibilidade semanal não medidos. Nenhum gasto pago ou publicação. Próximo incremento depende de feedback do laboratório de movimento antes de adicionar combate.
