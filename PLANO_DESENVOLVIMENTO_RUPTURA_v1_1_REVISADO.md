# RUPTURA — Plano de Desenvolvimento e Game Design Document

**Versão:** 1.3 — executivo de terno preto, direção corporativa e mira pelo movimento

**Data:** 26/10/2026

**Status:** Pré-produção — próximo trabalho: prototipação; produção da campanha condicionada à vertical slice  
**Equipe:** Otávio + Codex; múltiplas instâncias podem executar tarefas independentes, com integração centralizada  
**Nome:** provisório, sujeito a pesquisa de marca antes de publicação

> **Visão:** Jogo single-player de ação 2D em pixel art, com combate corpo a corpo e à distância, interatividade física, explosões, exploração horizontal e vertical, progressão permanente, sete líderes como chefões e campanha narrativa concluída. Direção estética: pixel art minimalista, corporativa e sombria, inspirada na síntese visual de Superfighters, com identidade própria. Prioridades: combate divertido, apresentação bonita e legível, recompensas significativas, dificuldade progressiva e desempenho em notebooks antigos. Linux é o ambiente de desenvolvimento e teste desde o primeiro dia; Dell Inspiron 15 5547 é referência de hardware, com a GPU efetivamente disponível.

---

## 1. Princípios inegociáveis

1. **Primeiro a diversão:** se uma arena com um inimigo, uma pistola e uma caixa não for divertida, não adicionar conteúdo para mascarar isso.
2. **Controle preciso, física expressiva:** movimentação do jogador responsiva e consistente no passo fixo de física; física mais livre em objetos, detritos e impactos.
3. **Muitos caminhos, campanha contida:** mapas exploráveis em ambas as direções, com verticalidade, sem mundo aberto nem geração procedural na v1.
4. **Destruição intencional:** barris, vidros, caixas, coberturas e poucos segmentos estruturais marcados; nada de destruição per-pixel universal.
5. **Armas como escolhas, não números crescentes:** cada desbloqueio abre novas estratégias; pistola inicial continua viável.
6. **Todos os chefões ensinam ou testam mecânicas:** padrões legíveis, contrajogo, uso contextual do cenário.
7. **Narrativa com consequência coletiva:** derrubar chefes não resolve tudo; provas precisam chegar aos trabalhadores, que passam a se organizar e recusar o regime.
8. **Compatibilidade desde o primeiro dia:** testes regulares em Linux desde o Marco 0, no hardware-alvo e em executáveis exportados; Windows tem validação própria antes de qualquer anúncio de suporte.
9. **Escopo controlado:** jogo solo primeiro; cooperativo local e online ficam fora do lançamento inicial.
10. **Criação original:** usar jogos existentes como referência de mecânica, não copiar nomes, sprites, fases, personagens ou assets.
11. **Paridade de combate entre entradas:** teclado/mouse e controle precisam ser divertidos; não deixar o gamepad para uma adaptação tardia.
12. **Legibilidade acima de espetáculo:** em cada troca de tiros, entender de onde veio o ataque, para onde se mira e quais objetos têm colisão.
13. **Produção sustentável:** uma pessoa decide e joga; Codex implementa, auxilia na criação de conteúdo e verifica. Paralelismo não substitui direção artística, revisão e playtest humano.
14. **Dificuldade que ensina:** apresentar, praticar e combinar antes de cobrar domínio; recompensar aprendizado e experimentação sem exigir grind.

### 1.1 Três pilares que devem diferenciar o RUPTURA

- **Combate físico improvisado:** tiros, golpes, impulsos e objetos interativos geram combinações compreensíveis, sem simulação cara.
- **Arenas com direção tática:** possibilidade real de recuar, trocar de altura, explorar coberturas e escolher ângulos; verticalidade não deve virar plataformas excessivamente precisas.
- **Chefões como quebra-cabeças de ação:** cada liderança modifica a arena e exige um uso criativo de habilidade, arma ou cenário, não apenas mais dano.

**Teste de identidade:** se uma arena com uma pistola, um oponente e um barril não produzir escolhas interessantes por três minutos, não avançar à produção de novos inimigos, capítulos ou efeitos.

## 2. Proposta criativa

- **Gênero:** ação / run-and-gun com combate físico e exploração leve.
- **Câmera:** lateral 2D, acompanhamento suave com limites e enquadramento especial nos chefões.
- **Fluxo:** missão -> exploração e combate -> descoberta de provas -> confronto -> retorno ao esconderijo -> desbloqueios -> missão seguinte.
- **Duração de referência:** campanha compacta de aproximadamente **2–4 horas na primeira conclusão**, hipótese incluindo exploração e novas tentativas. Prólogo de 5–10 min e capítulos de aproximadamente 12–25 min de percurso bem-sucedido; medir separadamente percurso, exploração e retries. Não alongar conteúdo para cumprir duração. A slice de 12–20 min pode se tornar a base do capítulo 1 completo, sem expansão obrigatória.
- **Estrutura:** prólogo curto + sete capítulos; 1 chefe por capítulo; cada capítulo possui 1–2 setores compactos, usando módulos compartilhados; três ambientes curtos na slice não obrigam três setores extensos por capítulo.
- **Rejogabilidade:** rotas opcionais, domínio do combate e armas com funções diferentes. Estatísticas discretas de tempo/segredos são opcionais e não geram punição por jogar devagar. Ranking, modo desafio e pontuação complexa ficam após a campanha.
- **Plataformas:** **Linux nativo é a plataforma primária de desenvolvimento, teste e lançamento.** Windows é alvo secundário da v1, condicionado a testes em Windows real antes de anunciar suporte. Exportar Linux desde o Marco 0; preparar exportação Windows cedo e validar quando houver equipamento/sessão disponível, com uma rodada obrigatória antes da demo multiplataforma. Mouse/teclado e gamepad com dois analógicos entram desde o protótipo. Wine/Proton não substituem validação de Windows nativo.
- **Distribuição:** executável offline; avaliação de itch.io e Steam quando houver demo estável.
- **Classificação indicativa:** avaliar pela intensidade da violência da versão final.

### 2.1 Fantasia do jogador

Começar ferido e quase desarmado, ainda no terno preto de executivo. Improvisar com o cenário. Aprender a enfrentar esquadrões antes considerados invencíveis. Apropriar-se de tecnologia inimiga. Descobrir como o sistema funciona. Não apenas vencer sete confrontos, mas permitir que uma população manipulada entenda o que está acontecendo e aja.

### 2.2 Loop principal

**Observar -> escolher rota -> enfrentar inimigos -> usar o ambiente -> coletar recursos/provas -> chegar a um objetivo -> derrotar o chefe -> receber uma nova capacidade -> explorar alternativas futuras.**

Revisitas são **opcionais e locais**; o jogador não deve atravessar repetidamente capítulos inteiros para abrir uma porta obrigatória. Não assumir estrutura metroidvania completa.

### 2.3 Escopo negativo da v1

Não incluir campanha de 4–6 horas como compromisso, suporte obrigatório a múltiplas distribuições Linux, versões para consoles, Steam Deck certificado, nem mundo aberto, MMO, multiplayer online, economia online, microtransações, veículos livres por toda a campanha, sistema de crafting extenso, geração procedural integral, deformação real de todos os terrenos, dublagem completa nem árvore de talentos com dezenas de atributos.

---

## 3. História e universo

### 3.1 Sinopse

Na república fictícia de **Valera**, a organização privada **VÉRTICE** se apresenta como a solução para crises de segurança, abastecimento e infraestrutura. Na realidade, seus sete diretores coordenam um projeto de golpe de Estado. O objetivo é substituir as instituições por um regime autoritário, converter serviços básicos em monopólios, retirar liberdades e impor trabalho compulsório para ampliar seus lucros.

O protagonista, conhecido pelo codinome **Espectro**, era executivo da VÉRTICE e aspirava a um cargo de diretor. Ao encontrar atas e contratos que comprovavam o plano, recusou-se a endossar operações contra civis. A diretoria o traiu: foi gravemente ferido e abandonado como morto. Sobrevive por pouco graças a uma trabalhadora de manutenção que o encontra, leva a um abrigo e o ajuda a se recuperar.

Inicialmente motivado pela sobrevivência e pela vingança, Espectro percebe que eliminar os líderes não basta: muitos trabalhadores, soldados e técnicos sustentam a organização por desconhecimento, medo ou coerção. A vitória real depende de obter registros incontestáveis das operações, restaurar meios de comunicação e divulgá-los para que esses grupos recuperem poder de decisão.

### 3.2 Personagens centrais

- **Espectro:** protagonista; executivo de terno preto, antes aspirante a uma diretoria, agora ferido e perseguido pelos próprios superiores. Sua evolução é mecânica e ética: de sobrevivente isolado a aliado de uma resistência coletiva.
- **Lia:** técnica de manutenção que o resgata; opera o esconderijo, ajuda na engenharia e conecta o protagonista a trabalhadores organizados. Possui objetivos próprios e não é apenas suporte passivo.
- **Nara:** operadora de comunicação que ajuda a validar provas, contestar a propaganda e alcançar instalações desconectadas.
- **Trabalhadores da VÉRTICE:** não são massa anônima; aparecem como NPCs com medos, necessidades e perspectivas diferentes. Alguns colaboram, outros recusam, outros mudam após ver provas.
- **Sete diretores:** lideranças de áreas que mantêm o golpe. A ordem segue escala de poder e aumenta a complexidade dos confrontos.

### 3.3 Estrutura dos sete capítulos

| Capítulo | Área e revelação | Diretor / posição | Confronto | Nova possibilidade |
|---|---|---|---|---|
| 1 — **Cinzas** | Arquivo corporativo restrito; atas da execução forjada | **Mara “Chacal”**, chefe da segurança interna (7ª) | Combate ágil, golpes, empurrões e uso de cobertura | Esquiva aprimorada + **desbloqueio permanente** da espingarda (a versão da vertical slice pode aparecer antes como pickup temporário) |
| 2 — **Carga Morta** | Docas e ferrovias; transporte de armamentos disfarçados de suprimentos | **Ívo “Lastro”**, diretor de logística (6º) | Guindastes, cargas móveis, explosivos | Granadas e interação com mecanismos pesados |
| 3 — **Queda de Energia** | Usina e rede subterrânea; cortes programados para subjugar bairros | **Selene “Arco”**, diretora de energia (5ª) | Armadilhas elétricas, zonas seguras e terminais | Ferramenta de desativação e abertura de novos caminhos |
| 4 — **Linha de Montagem** | Fábrica militar; trabalhadores submetidos a coerção | **Dário “Forja”**, diretor industrial (4º) | Armadura modular, peças destrutíveis e ondas curtas | Disparo perfurante / arma pesada contextual |
| 5 — **Voz Única** | Torre de mídia; documentos sobre desinformação do golpe | **Vera “Sinal”**, diretora de propaganda (3ª) | Drones, alarmes, hologramas e sabotagem de transmissão | Acesso a frequências e áreas secretas |
| 6 — **Cerco** | Complexo paramilitar e centro de detenção; ordens repressivas | **General Ravel “Bastião”**, comando de forças armadas privadas (2º) | Blindado em arena fixa com mudança roteirizada de cobertura | Variação da esquiva existente e reforço aliado roteirizado |
| 7 — **Ruptura** | Sede central; plano de tomada definitiva do governo | **Augusto Voss**, diretor supremo (1º) | Confronto multifase com versões aprimoradas de mecânicas antigas | Conclusão: acesso ao arquivo central e transmissão pública |

A coluna de confrontos/recompensas indica intenção de design; cada capítulo deve adaptar esses exemplos ao orçamento de componentes compartilhados. Guindastes, terminais e frequências começam como variações do mesmo sistema simples de interação; drones e hologramas não exigem novos controladores se sprites/props e eventos roteirizados resolverem o encontro.

Os nomes são provisórios. A progressão da narrativa deve ser construída com ações, conversas curtas, documentos facultativos e mudanças visíveis no mundo — não com longas cutscenes.

### 3.4 Final planejado

Após o sétimo duelo, Espectro obtém o arquivo central — mas o chefe final tentou preparar uma narrativa que culparia o protagonista pelos crimes da organização. As provas coletadas em cada capítulo autenticam os registros. Lia e Nara restabelecem canais de comunicação. Trabalhadores, técnicos e unidades militares recusam as ordens dos dirigentes; operações de produção forçada são paralisadas e o golpe se desestrutura.

A vitória é **coletiva**, não a posse do governo por Espectro. O epílogo mostra a continuidade do trabalho de reconstrução e o protagonista aceitando que derrubar o comando foi apenas o começo.

### 3.5 Sistema narrativo simples

- Todo capítulo concede **uma prova-chave obrigatória**; provas adicionais opcionais aprofundam a história.
- As provas são vistas no esconderijo em um painel cronológico.
- O esconderijo começa como uma tela funcional com painel e conversas curtas; um hub explorável só entra se houver benefício comprovado.
- O nível de conscientização pública é representado por acontecimentos da história, **sem criar um medidor complexo ou finais que obriguem a coletar tudo**.
- Diálogos são breves e podem ser pulados/revistos.
- O jogador nunca precisa ler documentos longos para compreender o objetivo imediato.

---

## 4. Mecânicas de jogo

### 4.1 Controle

- **Teclado/mouse:** A/D mover; S agachar/descer plataformas; espaço pular; cursor mirar em 360°; botão esquerdo atirar; direito golpe; Shift esquivar; E interagir; R recarregar; roda/1/2 trocar arma; G granada.
- **Controle com dois analógicos (layout de referência Xbox):** analógico esquerdo mover e orientar a mira; direito mirar no modo independente opcional; RT atirar; RB golpe; A pular; B esquivar; X recarregar; Y trocar arma; LB granada; direcional para cima interagir. Testar também um preset com **LB pular, A granada**, preservando o polegar direito na mira; comparar conforto antes de escolher o padrão. Agachar/descer plataforma: direcional para baixo, com alternativa remapeável. Oferecer remapeamento e operação completa de menus por gamepad.
- Margem de tolerância ao sair da borda (**coyote time**) e **jump buffer** para salto responsivo.
- O combate distingue **direção de movimento**, **direção da mira** e **orientação visual do corpo**, sem inverter controles quando o cursor/analógico cruza o personagem.
- Controles remapeáveis, ícones dinâmicos conforme dispositivo e possibilidade de alternar mouse/teclado e gamepad antes da demo pública.
- Evitar que o jogador perca agência por animações excessivamente longas. Priorizar *input buffering*, *hitstop* curto e feedback sonoro/visual.

#### 4.1.1 Mira no controle — protótipo obrigatório

**Decisão do usuário em26/10/2026:** o analógico esquerdo move e orienta a mira por padrão, incluindo direções verticais/diagonais; soltar mantém a última direção válida. A opção de mira independente usa o analógico direito, com direção contínua e retenção ao centralizar. Mouse mantém mira independente. A assistência leve de alvos é outra opção, separada do modo de analógico.

- Usar vetor radial do esquerdo por padrão e do direito no modo independente (ex.: `Input.get_vector`), deadzone radial configurável e **reter a última direção válida** ao soltar o analógico. Começar avaliando deadzone ~0,15–0,25; ajustar com controles reais.
- Mira de tiro **contínua em 360°**, mas animação inicial econômica: corpo e braço/arma independentes, com sprites direcionais ou rotação de pivô conforme qualidade visual. Evitar exigir dezenas de sprites para cada arma antes do teste.
- Testar **assistência leve e opcional** no gamepad, limitada a alvos visíveis/próximos à linha de tiro; não curvar projéteis de maneira arbitrária, não atravessar paredes e não aplicar no mouse.
- Retículo visível a distância útil, feedback claro de origem do tiro, obstáculos e cobertura; testar ângulos de 45°, tiros para cima e alvos em alturas diferentes.
- A câmera pode olhar discretamente adiante na direção de mira, mas **sem oscilar** quando o analógico passa pelo centro; respeitar os limites da fase.
- **Critério de aceite:** pessoas com gamepad conseguem acertar inimigos no mesmo plano e em plataformas superiores, durante movimento e esquiva, sem sentir que o jogo exige mouse. Comparar tempo de eliminação, tiros desperdiçados e relatos de controle em pelo menos duas arenas.


### 4.2 Movimento

**MVP:** andar, correr, pular, agachar, descer plataforma unilateral, receber knockback, esquivar.  
**Depois:** agarrar borda, salto na parede ou mobilidade alternativa; somente se os mapas justificarem.

O jogador é `CharacterBody2D`, com lógica própria de velocidade, aceleração, atrito e estado, e não um boneco ragdoll sempre ativo. Física reativa em eventos de impactos pode ser representada por animações e forças limitadas.

### 4.3 Combate

- **Corpo a corpo:** golpe rápido, golpe forte opcional, chute contextual, interrupção, empurrão e possibilidade de desarmar inimigos. Começar com um golpe rápido e um empurrão contextual no mesmo botão, conforme distância/estado; golpe forte, desarme e agarrões ficam fora do compromisso inicial e só entram se melhorarem a arena sem aumentar demais animações e estados.
- **Armas de fogo:** pistola e espingarda na slice; submetralhadora e rifle na campanha somente após validação de função distinta. Meta máxima inicial: quatro armas portáteis + granada; arma pesada é objeto contextual que reutiliza o sistema de disparo. Cada arma tem função perceptível, sem lista inflada de variantes.
- **Inventário:** 2 armas equipadas + 1 consumível explosivo. Armas extras são obtidas de inimigos/caixas e podem ser trocadas. A progressão libera modelos e capacidades, não capacidade infinita de carregar armas.
- **Dano:** jogador e inimigos sofrem dano com feedback claro, breve invulnerabilidade quando apropriado e proteção contra dano instantâneo inevitável.
- **Munição:** estoques modestos e itens disponíveis em arenas; o combate corpo a corpo continua útil.
- **Combos emergentes:** tiro em objeto, explosão, queda de cobertura, knockback e ataque final.
- **Legibilidade:** ataques inimigos precisam ter trajetória ou aviso visual/sonoro identificável; projéteis e efeitos não devem esconder a mira. Revisar separadamente tiros horizontais, diagonais e entre diferentes alturas.

**Regra de design:** arma rara não deve invalidar permanentemente uma arma inicial; situacionalidade é preferível a escalada puramente numérica.

#### 4.3.1 Regras a fechar no Marco 2

- **Origem do tiro:** calcular a mira a partir da arma, converter corretamente coordenadas de tela/mundo e testar proximidade de paredes. Verificar obstrução entre personagem e boca da arma; não disparar através de cobertura só porque o cano atravessou o colisor.
- **Cancelamentos:** esquiva pode cancelar recarga antes da transferência de munição; recarga transfere munição em um único evento. Golpe tem preparação curta, contato e recuperação explícitos. Documentar quais ações podem interromper cada fase, evitando estados presos e duplicação de disparos.
- **Esquiva:** ponto inicial de teste de 0,25–0,35 s, com janela de invulnerabilidade menor que a animação e cooldown visível por postura/feedback. Ajustar por teste; perigos persistentes precisam de regra explícita e consistente.
- **Dano recebido:** impedir múltiplos acertos instantâneos da mesma fonte; testar proteção breve contra sequências inevitáveis, sem acumular stun indefinidamente. Valores ficam em dados e são registrados no balanceamento.
- **Disparos inimigos:** tiros rápidos exigem preparação e indicação clara da linha de ataque; projéteis desviáveis devem permanecer visíveis no fundo escuro.
- **Recursos:** checkpoint pré-chefe oferece uma condição inicial viável e repetível. Uma tentativa ruim não pode obrigar a repetir capítulos para recuperar munição.

### 4.4 Física e destruição

Camadas de interação:

1. **Visual apenas:** flashes, poeira, faíscas e fragmentos desenhados, sem colisão.
2. **Interação simples:** caixas com vida, vidros, barris, interruptores, portas e coberturas frágeis.
3. **Corpos físicos reais:** poucos barris, caixas grandes, objetos empurráveis e detritos importantes.
4. **Eventos roteirizados:** plataformas que caem ou estruturas que se desmancham em momentos marcados, com efeito convincente e custo previsível.

Explosões aplicam dano por distância com checagem de obstáculos quando necessário, impulso limitada a corpos elegíveis, efeitos 2D e reação em cadeia com travas para impedir loops infinitos.

**Não implementar:** destruição universal de TileMapLayer por pixel; centenas de partes físicas persistentes; ragdolls complexos simulados o tempo todo.

### 4.5 Inimigos comuns

| Arquétipo | Comportamento principal | Aprendizado que exige |
|---|---|---|
| Recruta | Avança, atira, recua ao perder cobertura | Fundamentos |
| Batedor | Rápido, tenta flanquear e saltar | Mirar sob pressão |
| Escudeiro | Usa escudo e protege colegas | Explosivos, reposicionamento |
| Atirador | Mantém distância, tiro telegrafado | Uso de cobertura e rota alternativa |
| Demolidor | Lança explosivos com aviso | Mobilidade e interação com objetos |
| Técnico | Aciona alarmes, torres ou drones | Priorizar ameaças |
| Elite | Combina 2 comportamentos | Síntese das habilidades |

**Escopo inicial de IA:** recruta e batedor na slice; inimigo protegido é inicialmente um recruta posicionado em cobertura, sem terceiro controlador. Na campanha, priorizar atirador e demolidor; escudeiro/técnico/elite são candidatos sujeitos ao custo, preferindo combinar comportamentos existentes.

A IA usa máquina de estados finitos: patrulha, percebe, busca cobertura, ataca, recua, investiga e atordoado. Line-of-sight por raycast; navegação simples por pontos e links de plataformas; **não** construir um sistema genérico de IA de mundo aberto. No Marco 2, provar uma rota horizontal, um salto/link autorizado e uma queda entre plataformas. Cobertura destruída invalida seu ponto de uso. Se a navegação falhar, limitar as rotas do arquétipo e redesenhar a arena; não prometer travessia de qualquer geometria.

### 4.6 Chefões

- **Orçamento por chefe:** uma mecânica ambiental exclusiva, até três padrões principais e no máximo duas fases; o final pode recombinar padrões existentes. Reutilizar componentes de ataque, dano e transição, preservando silhueta, ritmo e contramedida próprios.
- Cada chefão tem **3 regras legíveis**: padrão de ataque, vulnerabilidade e contramedida ambiental.
- Fases adicionais alteram o espaço e ritmo de combate, não apenas multiplicam HP.
- Sem golpes inevitáveis ou longa invulnerabilidade que frustre o jogador.
- Checkpoint imediatamente anterior à arena.
- Meta de retry: recuperar o controle em até 5 s após confirmar a nova tentativa, medida no hardware-alvo. Introduções puláveis após a primeira tentativa.
- Pelo menos uma estratégia alternativa legítima (armamento, posicionamento ou uso do cenário).

### 4.7 Progressão

Três eixos:

1. **Equipamentos:** armas e ferramentas obtidas ao derrotar chefes ou explorar setores.
2. **Mobilidade/combate:** novos movimentos e aperfeiçoamentos que mudam a forma de jogar.
3. **Narrativa:** evidências que revelam a dimensão da conspiração e alteram a reação dos aliados.

Desbloqueios são persistidos automaticamente após marcos e checkpoints. Evitar *grinding*, moedas sem função e árvores de talento infladas.

### 4.8 Dificuldade progressiva e sensação de conquista

**Curva:** ensinar uma ameaça isolada -> praticar com rota de fuga -> combinar duas ameaças conhecidas -> testar no chefe -> oferecer recompensa e respiro. A ordem dos líderes representa poder narrativo; a dificuldade cresce por decisões e combinações, sem exigir que cada encontro seja mais difícil que o anterior.

| Etapa | O que ensina/testa | Limite inicial de pressão a validar |
|---|---|---|
| Prólogo | Mover, mirar, golpear e usar cobertura | 1–2 recrutas, preparação longa e recuperação próxima |
| Cinzas | Alternar tiro/golpe e trocar de altura | 2–3 ameaças; barril apresentado em situação segura |
| Carga Morta | Ler explosivos e reposicionar | 3–4 ameaças; introduzir um perigo ambiental por vez |
| Queda de Energia | Escolher rota e reconhecer zonas seguras | Combinar ameaças conhecidas com perigo telegrafado |
| Linha de Montagem | Priorizar alvos e explorar vulnerabilidade | Introduzir proteção frontal sem exigir arma única |
| Voz Única | Controlar pressão e interromper dispositivos | Reutilizar atacantes com dispositivo simples e visível |
| Cerco | Administrar espaço e recursos | Encontros mais densos intercalados com recuperação |
| Ruptura | Sintetizar o aprendizado | Combinações já ensinadas; nenhuma habilidade obrigatória inédita |

As quantidades são hipóteses de design; 6–10 inimigos é cenário de estresse, não meta de densidade. Evitar aumentar simultaneamente velocidade, dano, quantidade e resistência. Recuo e leitura precisam continuar úteis.

- **Padrão:** experiência principal, sem grind, com checkpoints após trechos difíceis e antes de chefes. **Assistido:** maior tolerância a dano, mais recursos e telegraphs mais longos, sem remover conteúdo ou penalizar final. **Desafio:** só após balancear o padrão; adiado se consumir QA excessivo.
- A dificuldade pode ser alterada no pause; registrar a seleção separadamente e aplicá-la no próximo retry/checkpoint, sem reiniciar a campanha e sem alterar um ataque já em andamento. Sem ajuste secreto que altere regras durante uma tentativa.
- Cada recompensa tem apresentação curta e uso prático logo depois: experimentar a arma, abrir uma rota ou perceber mudança no mundo. Novos movimentos ampliam escolhas; o controle básico deve ser bom desde o início.
- Vitória comunica domínio: som de impacto, reação visível, pausa breve, resolução do encontro e consequência narrativa. Evitar excesso de flashes, shake ou números cobrindo a ação.
- Medir mortes por encontro, tentativas de chefe, recursos no checkpoint e causa relatada de morte. Picos sem aprendizagem ou sensação de inevitabilidade exigem revisão da arena antes de aumentar HP ou distribuir upgrades.

---

## 5. Projeto de fases e experiência

### 5.1 Esquema de capítulo

**Entrada de baixo risco -> apresentação da mecânica -> confronto intermediário -> exploração alternativa -> combinação de perigos -> área de recuperação -> chefão -> epílogo curto e recompensa.**

Cada capítulo deve oferecer:

- 1–2 setores compactos e reconhecíveis, com variação de paleta, props e geometria sobre módulos reutilizados;
- uma rota principal inequívoca e 1–2 atalhos ou caminhos opcionais;
- trechos que permitam voltar à esquerda, subir e descer;
- 1–2 eventos de física memoráveis, não explosões em todas as telas;
- checkpoint após trechos difíceis;
- ambientação narrativa integrada aos elementos do cenário.

### 5.2 Vertical slice: “Cinzas”

**Objetivo:** provar que vale a pena produzir os outros seis capítulos. É uma missão representativa que pode se tornar o capítulo 1 completo. Validar qualidade e custo de produção antes de prometer expansão.

Conteúdo fechado:

- uma missão de 12–20 minutos, dividida em ruína, pátio e arena final;
- movimentação completa de MVP (sem habilidades avançadas), com mira testada no mouse e no gamepad;
- pistola, espingarda como **pickup temporário antes do chefe** (desbloqueio permanente após a vitória) e golpe corpo a corpo;
- dois arquétipos: recruta e batedor; variar posições e cobertura sem exigir terceiro tipo;
- caixas, vidro e barril explosivo;
- um chefão (Mara/Chacal) com 2 fases e checkpoint;
- uma prova narrativa, uma cena de introdução curta e um diálogo de desfecho;
- HUD, pause, opções gráficas, volume, salvamento e tela de conclusão;
- uma arena com arte e áudio próximos do acabamento final, para medir qualidade e esforço de autoria;
- exportação Linux com métricas no notebook; build Windows e validação nativa se a demo também anunciar essa plataforma.

**Critério de aprovação:** jogadores externos com **mouse/teclado e gamepad** conseguem aprender os controles sem explicação longa, repetir a fase voluntariamente, compreender por que morreram e perceber caminhos alternativos. Registrar feedback separado por dispositivo. Aplicar o protocolo da seção 5.4. Se isso falhar, consertar controles, ritmo ou legibilidade **antes** da campanha completa.

### 5.3 Direção de arte — minimalismo industrial sombrio

**Referência de intenção:** Superfighters orienta a síntese dos personagens pequenos, cenários compactos e ação física legível. RUPTURA desenvolve paleta, silhuetas, animações, cenários e interface próprios. A atmosfera sombria vem de cor, composição e som; plataformas e ameaças continuam reconhecíveis.

- **Paleta:** começar com 16–24 cores por conjunto de ambiente, cinzas azulados/carvão, ferrugem e tons dessaturados; âmbar para interação/luz, vermelho para ameaça e um acento distinto para o protagonista. Forma, contorno e animação também comunicam função.
- **Escala:** testar personagens de aproximadamente 16–24 pixels de altura e tiles de 16 pixels na arena piloto, antes de fixar. Usar silhuetas simples e 3–5 animações prioritárias por ator; arma/braço independentes para mira. Confirmar que pés, cabeça, direção e arma são distinguíveis na tela real.
- **Profundidade:** fundo com menor contraste, plano jogável bem separado e primeiro plano sem encobrir ameaças. Limitar decoração e parallax; colisão deve corresponder ao que se vê.
- **Luz:** sombras e volumes majoritariamente pintados nos tiles, com poucos acentos luminosos. Iluminação dinâmica é opcional; o perfil mínimo preserva sinais e leitura sem depender dela. Sem bloom obrigatório, neblina que esconda tiros ou pretos que apaguem o jogador.
- **Beleza por consistência:** bordas, densidade de detalhe, escala dos pixels, materiais e animação seguem uma pequena folha de estilo. Variar módulos com composição e props autorais; não aumentar detalhe isolado até romper a unidade.
- **Feedback:** impacto curto, recoil, estilhaço econômico e áudio por material. Reservar os efeitos maiores para momentos significativos, mantendo retículo e telegraphs visíveis.
- **UI:** tipografia legível em tamanho real, HUD discreto com vida/munição e objetivos curtos; menus acessíveis por mouse e controle. Não exigir fonte pixelada para textos longos.
- **Pipeline:** Otávio aprova uma prancha com personagem, tiles, props, HUD e explosão, vista dentro do jogo. Codex auxilia na criação de assets originais, ferramentas e importação; cada recurso passa por inspeção visual e registro de origem/licença. A geração de assets não elimina curadoria ou ajustes manuais.
- **Orçamento da slice:** um kit industrial modular, um protagonista, dois inimigos derivados de uma base, Chacal com silhueta própria, duas armas, três props interativos e um conjunto pequeno de impactos. Provar variedade em ruína/pátio/arena com esse kit antes de produzir outro bioma.

### 5.4 Protocolo de playtest e aprovação

1. **Interno a cada incremento:** Otávio joga a build Linux por 10–20 min, registrando versão, dispositivo e três pontos: o que foi satisfatório, o que foi confuso e o que frustrou. Codex corrige problemas reproduzíveis e mantém uma lista curta de hipóteses.
2. **Rodada externa na slice:** buscar 3–5 voluntários, incluindo pessoas menos familiarizadas com ação. Cobrir pelo menos duas sessões de mouse/teclado e duas de gamepad; sessões podem ser das mesmas pessoas, alternando a ordem. Feedback de Otávio continua valioso, mas não substitui quem desconhece os controles. Não presumir equipe de QA contratada.
3. **Observar antes de orientar:** registrar se cada pessoa se move, mira, ataca e encontra a primeira rota sem ajuda em até 3 min; onde pede ajuda; quantas tentativas leva; se identifica a causa das mortes; e se usa uma segunda rota/objeto. Fazer perguntas abertas antes de sugerir respostas.
4. **Gate inicial:** pelo menos 80% aprendem as ações essenciais em até 3 min sem intervenção; pelo menos 80% das mortes discutidas têm causa identificável; nenhuma sessão encontra softlock ou perda de progresso. Registrar contagens brutas junto das porcentagens, pois a amostra é pequena. Esses limiares orientam iteração, não comprovam aceitação de mercado.
5. **Qualidade percebida:** perguntar se a pessoa quer tentar novamente, o que mudaria na próxima tentativa e o que achou bonito/confuso. Repetição voluntária é evidência qualitativa; não obrigar dez repetições nem aprovar apenas por uma nota média.
6. **Gate de produção:** combate satisfatório nos dois dispositivos, arte representativa aprovada dentro do jogo, desempenho medido, save/retry confiáveis e custo de criação registrado. Sem voluntários disponíveis, continuar ajustes locais e ferramentas, mantendo a aprovação externa pendente antes de expandir a campanha.

---

## 6. Stack e ferramentas

| Domínio | Escolha | Observação |
|---|---|---|
| Engine | **Godot 4.7.2 Stable (padrão)** | Versão confirmada no arquivo oficial (18/08/2026); fixar versão no repositório; não migrar automaticamente para 4.8 beta |
| Linguagem | **GDScript tipado** | `class_name`, tipagem explícita, eventos via signals |
| Renderer | **Compatibility** | Compatibilidade com placas antigas; verificar OpenGL 3.3 / drivers |
| Física | **Godot Physics 2D** | `CharacterBody2D`, `Area2D`, `RigidBody2D` em objetos selecionados |
| Mundo | **TileMapLayer + cenas de props** | Colisão simplificada e objetos reutilizáveis |
| UI | **Control / Theme** | Não adotar webview ou frontend externo |
| Dados | **Resource `.tres` / `.res`** | Definições tipadas de armas, inimigos e upgrades; JSON somente para dados simples/saves |
| Arte | **LibreSprite ou Aseprite; Krita** | Spritesheets, tilesets, efeitos |
| Som | **Audacity, LMMS, Bfxr/ChipTone (opcional)** | Licenças dos efeitos e músicas auditadas |
| Fonte | **Git local; GitHub opcional** | Histórico desde o Marco 0; repositório remoto e LFS quando necessários |
| IDE / agente | **VS Code + Codex** | Tarefas pequenas com critérios de aceite |
| Testes | **GUT quando compatível; scripts headless** | Validar compatibilidade da versão antes de fixar add-on |
| CI | **Scripts locais primeiro; GitHub Actions quando houver remoto** | Importação headless, testes e exportação reproduzíveis; headless não comprova renderização/input |
| Documentação | **Markdown no repositório** | GDD, arquitetura, checklists, ADRs |
| Distribuição | **Pacote Linux executável; ZIP Windows quando validado** | Preservar permissão de execução no pacote Linux; sem instalador próprio inicialmente |

**Por que não Docker?** O jogo deve compilar e rodar nativamente, com desempenho previsível. Docker só poderia ser útil em uma tarefa específica de CI, mas não na experiência de desenvolvimento nem para jogar.

**Por que não backend?** Saves e progresso são locais. Requisitos online só surgem se o produto realmente ganhar recursos que dependam de servidores.

### 6.1 Referências técnicas

Fixar engine e templates de exportação na mesma versão, registrar origem e checksum. Consultar a documentação correspondente à versão fixada quando disponível; URLs `stable` abaixo podem mudar. A validação real de GPU, sistema e input pertence aos registros de teste.

- Versão estável e arquivo oficial: https://godotengine.org/download/archive/
- Visão geral dos renderizadores: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- Requisitos do engine: https://docs.godotengine.org/en/stable/about/system_requirements.html
- Otimização: https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html
- `CharacterBody2D`: https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
- Documentação do Inspiron 5547: https://www.dell.com/support/product-details/pt-br/product/inspiron-15-5547-laptop/resources/manuals

---

## 7. Arquitetura proposta

### 7.1 Organização de diretórios

```text
ruptura/
├── project.godot
├── README.md
├── AGENTS.md
├── docs/
│   ├── GDD.md
│   ├── ROADMAP.md
│   ├── ARCHITECTURE.md
│   ├── PERFORMANCE.md
│   ├── NARRATIVE.md
│   └── adr/
├── assets/
│   ├── art/
│   │   ├── characters/
│   │   ├── environments/
│   │   ├── effects/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
├── game/
│   ├── core/
│   │   ├── game_session.gd
│   │   ├── save_service.gd
│   │   └── transition_service.gd
│   ├── actor/
│   │   ├── components/
│   │   ├── player/
│   │   └── enemies/
│   ├── combat/
│   │   ├── damage/
│   │   ├── weapons/
│   │   ├── projectiles/
│   │   └── explosions/
│   ├── world/
│   │   ├── interactables/
│   │   ├── hazards/
│   │   └── levels/
│   ├── bosses/
│   ├── progression/
│   ├── narrative/
│   └── ui/
├── data/
│   ├── weapons/
│   ├── enemies/
│   ├── abilities/
│   └── missions/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── perf/
├── tools/
│   └── validation/
└── .github/workflows/
```

### 7.2 Princípios da arquitetura

- **Composição antes de herança profunda:** `HealthComponent`, `HitboxComponent`, `HurtboxComponent`, `WeaponComponent`, `InteractableComponent` quando cada um provar utilidade.
- **Configuração orientada a dados:** `WeaponDefinition : Resource`, `EnemyDefinition : Resource`, `AbilityDefinition : Resource`, `MissionDefinition : Resource`.
- **Responsabilidade por sistema:** controlador de player cuida de intenção e estado; uma camada mínima de leitura de entrada transforma mouse ou gamepad em **vetor de mira**; `CombatResolver` cuida de dano; `LevelDirector` administra eventos da fase; `ProgressionService` cuida de desbloqueios.
- **Signals para eventos relevantes:** `health_changed`, `weapon_fired`, `object_destroyed`, `evidence_found`, `boss_defeated`.
- **Autoload mínimo:** `GameSession`, `SaveService`, `AudioService`, talvez `SceneRouter`; não criar um `GameManager` monolítico.
- **Estados claros do jogador:** `grounded`, `airborne`, `dodging`, `melee_attack`, `stunned`, `dead` com transições testáveis.
- **Uso consciente de física:** evitar depender de `RigidBody2D` para todo inimigo vivo; utilizar `CharacterBody2D` + reações controladas e eventuais efeitos de corpo ao morrer.
- **Injeção simples de dependências:** referências exportadas e cenas instanciadas com configuração; não construir framework genérico.
- **Evitar sincronizar ticks de IA para todos no mesmo quadro:** distribuir ciclos de percepção conforme a distância e prioridade.

### 7.3 Contratos de dados propostos

**WeaponDefinition** (configuração compartilhada, sem mutação em runtime): `id`, `display_name`, `damage`, `fire_rate`, `magazine_size`, `initial_reserve_ammo`, `reload_time`, `spread`, `recoil`, `range`, `projectile_type`, `sound_id`, `sprite`, `unlock_id`.

**WeaponState** (por instância): munição no pente/reserva, cooldown e estado da recarga. Nunca gravar esses valores no `Resource` compartilhado.

**EnemyDefinition**: `id`, `max_health`, `movement_speed`, `detection_range`, `accuracy`, `preferred_distance`, `weapon_id`, `behavior_profile`, `loot_table`.

**MissionDefinition**: `id`, `scene_path`, `chapter`, `prerequisites`, `evidence_reward`, `unlock_reward`, `checkpoint_ids`, `boss_id`.

**SaveData** (JSON versionado): `schema_version`, `profile_id`, `unlocked_missions`, `completed_missions`, `unlocked_weapons`, `unlocked_abilities`, `collected_evidence`, `checkpoint`. Usar validação ao carregar e manter opção de fallback em caso de arquivo corrompido.

**SettingsData** (arquivo separado): preferências de áudio/vídeo, remapeamento, assistência e dificuldade selecionada; não faz parte do rollback de uma tentativa. Mudanças de dificuldade entram na próxima restauração de checkpoint, com aviso claro ao jogador.

**Política de checkpoint:** persistir missão/checkpoint estáveis, inventário e condição inicial de recursos, provas e desbloqueios confirmados. Reiniciar inimigos, boss e objetos transitórios a partir da cena; sem serializar toda a física. Ao morrer, reconstruir a mesma condição do checkpoint, sem duplicar recompensas. Vida/munição pré-chefe têm mínimo viável definido por autoria.

**Escrita segura:** escrever arquivo temporário no diretório do save, fechar e validar antes de substituir o principal; preservar último backup válido. Validar tipos, limites, IDs e versão. Corrupção de ambos oferece recomeço explícito, sem apagar silenciosamente arquivos. Migrações devem declarar versões suportadas. Preferências de vídeo/input ficam separadas da restauração de tentativa e não voltam ao morrer.

### 7.4 Testes que merecem automação

- Dano por explosão não atinge a mesma entidade múltiplas vezes pelo mesmo evento.
- Armas recarregam, consomem munição e respeitam cooldown.
- Inimigos e chefões não permanecem presos no estado de ataque após interrupção.
- Saves criados em versão anterior têm migração/fallback seguro.
- Checkpoints reaparecem em local válido e restauram progressão sem duplicar recompensas.
- Abrir fase por `MissionDefinition` não quebra cenas e recursos.
- Transições de fase e reset de boss não deixam objetos ativos da tentativa anterior.

---

## 8. Requisitos de desempenho e limites

### 8.1 Hardware-alvo

**Dell Inspiron 15 5547**, em configurações que podem possuir Intel HD Graphics 4400 e AMD Radeon R7 M265 2 GB DDR3. Existem variações de CPU, memória, sistema operacional e driver; validar o hardware exato antes de afirmar compatibilidade.

**Metas iniciais, não garantias:**

- **60 FPS** na maior parte da campanha, inclusive em combate, se viável no equipamento-alvo.
- Prioridade a **frametime regular**, não apenas média alta.
- **30 FPS como modo alternativo** caso testes mostrem necessidade; a física e a jogabilidade devem permanecer corretas.
- Resolução interna de trabalho **480x270** ou **640x360**, escolhida após teste de legibilidade; escalonamento inteiro quando apropriado.
- Identificar primeiro a GPU/driver realmente usados no Linux; testar integrada e dedicada quando disponíveis, sem pressupor funcionamento da AMD. Registrar diferenças de driver, temperatura e energia. Windows tem medições independentes.
- Começar com **perfil base e efeitos reduzidos**, ambos legíveis. Adicionar outros presets somente quando existirem efeitos que justifiquem custo e QA; não produzir três configurações por obrigação.

### 8.2 Orçamentos de engenharia a validar

Estes números servem como **guardrails experimentais**, não como limiares comprovados de hardware:

- ~6–10 inimigos simultaneamente ativos em arenas comuns, com escalabilidade.
- ~10–20 objetos dinâmicos reais em uma cena de maior complexidade, com redução automática/por autoria quando necessário.
- Partículas principalmente visuais (sprites ou GPUParticles/CPUParticles testadas); reciclagem de efeitos.
- Caminhos fora da câmera: desativar processamento e colisões desnecessárias; cuidado para não quebrar eventos persistentes.
- Explosões: processar alvos apenas na região próxima e aplicar limites de cadeia.
- Ativar navegação e busca de cobertura apenas nos inimigos relevantes.
- Evitar instanciar dezenas de nós complexos no mesmo frame; pré-carregar eventos conhecidos e usar pooling somente após medição.
- Tiros rápidos: preferir raycasts/hitscan quando adequado; projéteis físicos apenas quando sua trajetória tiver valor de gameplay.
- **Frame budget de referência:** 60 FPS implicam ~16,7 ms por quadro; 30 FPS ~33,3 ms. Esses valores são metas de tempo total, não orçamento exclusivo de script ou GPU. Evitar otimizações que causem picos de frametime.
- **Pixels e UI:** testar 480×270 e 640×360 em monitores 1366×768, com escala, bordas e HUD legível. Decidir explicitamente entre pixel art com escala inteira e interface independente; não comprometer pontaria por retículo minúsculo.

### 8.3 Como medir

Criar uma arena de benchmark com configurações reproduzíveis:

1. Ambiente vazio, movimento do jogador.
2. Três inimigos, troca de tiros.
3. Dez inimigos, cobertura e explosões sequenciais.
4. Arena de boss com objetos e efeitos simultâneos.
5. Repetir pelo menos 10 minutos em executável exportado, anotando FPS médio, **1% low (definido pelo método de coleta)**, frametime, uso de memória e picos. Comparar com as mesmas condições no notebook-alvo.
6. Repetir trecho de mira intensa com gamepad e mouse, e registrar quedas perceptíveis de resposta em ambos a 30 e 60 FPS.
7. Rodar no Linux de desenvolvimento desde o Marco 0: anotar distribuição, versão, sessão X11/Wayland, kernel, driver e GPU efetiva. Testar foco, fullscreen/janela, redimensionamento, troca de dispositivo e reconexão do gamepad. Validar outras sessões/distribuições antes de afirmar suporte a elas.
8. Rodar o pacote fora do editor e de sua pasta de desenvolvimento, com caminhos sensíveis a maiúsculas/minúsculas, permissão executável e save em diretório de usuário. Windows exige teste nativo próprio; exportação bem-sucedida não comprova funcionamento.

**Gate inicial de desempenho:** no perfil base Linux e no trecho comum de combate, buscar p95 de frametime ≤16,7 ms e p99 ≤33,3 ms; registrar separadamente carregamentos e stutters. Se inviável após análise, decidir explicitamente pelo perfil reduzido ou alvo de 30 FPS (p95 ≤33,3 ms e p99 ≤50 ms), sem transformar queda ocasional em aprovação. São critérios de projeto a recalibrar com o benchmark, não garantia prévia.

Registrar hardware, driver, resolução, perfil gráfico, hash do commit e versão da Godot. Se o desempenho cair, medir antes de otimizar.

### 8.4 Acessibilidade e ergonomia

- Remapeamento de teclas.
- Controle independente de música, ambiente e efeitos.
- Shake de câmera reduzível/desativável.
- Flash reduzível e alternativa a avisos apenas por cor.
- Legibilidade do cursor, retículo de gamepad e personagem em todas as fases.
- Diferenciar visualmente aliados, inimigos e objetos interativos.
- Dificuldades com parâmetros explícitos, sem esconder informação.

---

## 9. Plano de execução — marcos e critérios de saída

**Cadência:** ciclos curtos com uma build jogável ao final. Os esforços abaixo são tetos iniciais para descobrir problemas, em horas de atenção humana de Otávio (direção, jogo, revisão, ajustes e integração), e não previsões de prazo. Tempo de execução do Codex é registrado separadamente. Ao atingir o teto, revisar escopo e bloqueios antes de renovar o orçamento; não avançar sem cumprir o gate. Disponibilidade semanal e gastos ainda não foram informados, portanto não há data de lançamento comprometida.

| Etapa | Orçamento inicial de atenção humana | Decisão ao final |
|---|---|---|
| Marco 0 | 4–8 h | Conseguimos abrir, exportar e medir em Linux? |
| Marco 1 | 8–16 h | Movimento e mira são confortáveis nos dois dispositivos? |
| Marco 2 | 12–24 h | O núcleo de combate sustenta novas tentativas? |
| Marco 3 | 8–16 h | Física e apresentação são legíveis e têm custo controlado? |
| Marco 4 | 24–48 h | A slice prova diversão, acabamento e capacidade de produção? |

Total de referência até a slice: **56–112 h de atenção humana**, a recalibrar após cada marco. Não inclui compromisso de contratação nem garantia de conclusão dentro dessa faixa. Não presumir compra de assets, serviços pagos ou equipe externa; qualquer gasto novo depende de decisão de Otávio. Playtest voluntário não é mão de obra de produção.

### Marco 0 — Fundação Linux

**Entregáveis:** Git local, engine e templates fixados, Compatibility, README, AGENTS.md, cena inicial/menu mínimo, arena vazia, exportação Linux e medição inicial. Criar tarefas locais reproduzíveis de importação/verificação/exportação; preparar preset Windows sem presumir validação nativa. Registrar distribuição, sessão gráfica, hardware e driver reais. Criar somente pastas utilizadas.

**Saída:** projeto e pacote Linux abrem fora do editor no equipamento de teste, sem erros bloqueantes; input, áudio e gravação em diretório de usuário funcionam; existe medição inicial. Se o computador de desenvolvimento não for o Dell, registrar o teste no Dell como pendência explícita do gate de compatibilidade.

### Marco 1 — Sensação de controle

**Entregáveis:** personagem, câmera, andar/correr, salto, agachar/descer plataformas, esquiva, colisões, sprites temporários coerentes com a escala escolhida, mira desacoplada em 360°, deadzone e retículo. Comparar presets de gamepad com salto em A e em LB. Remapeamento mínimo e troca de dispositivo.

**Saída:** sessão Linux de movimento e pontaria em plataformas, a 30 e 60 FPS, sem inversão inesperada, input perdido ou câmera oscilante. Otávio registra ajustes e uma configuração aprovada para continuar; não exigir que uma arena vazia prove toda a diversão do jogo.

### Marco 2 — Arena de combate e navegação

**Entregáveis:** pistola, espingarda, golpe/empurrão, dano, hitstop curto, dois inimigos, caixas e barril, áudio provisório. Contratos mínimos de entrada, arma/dano e estado por instância. Fechar regras da seção 4.3.1. Provar links de plataforma e invalidação de cobertura.

**Saída:** arena de 3–5 min jogável e repetível em Linux, nos dois dispositivos, com escolhas de rota/objeto; mortes compreensíveis e ausência de estados presos. Registrar feedback interno e buscar uma rodada externa pequena já aqui. Sem resposta satisfatória, iterar nesta arena antes de adicionar inimigos ou capítulos.

### Marco 3 — Física, desempenho e prova estética

**Entregáveis:** impulso, cobertura destrutível, cadeia limitada, benchmark reproduzível, efeitos reduzidos e primeira arena com paleta, silhuetas, tiles, arma e impactos representativos. Pooling apenas quando medição justificar.

**Saída:** combate e explosões legíveis, metas de frametime avaliadas em exportação Linux no Dell, sem acúmulo de corpos/efeitos após dez resets. Otávio aprova a aparência dentro do jogo. Se não houver acesso ao Dell, continuar autoria local sem declarar compatibilidade aprovada.

### Marco 4 — Vertical slice “Cinzas”

**Entregáveis:** missão de 12–20 min com três ambientes curtos feitos do mesmo kit, dois arquétipos, Chacal com até duas fases, uma prova, desbloqueio, HUD, pause/opções, checkpoint/save seguro, tutorial e áudio. Uma arena deve representar acabamento final; os demais trechos precisam manter escala e legibilidade coerentes. Remapeamento completo antes de demo pública.

**Saída:** missão finalizável do zero, fechando/reabrindo o jogo, com retry confiável; protocolo externo da seção 5.4 executado, visual aprovado e benchmark registrado. Medir esforço real de criar uma arena, um chefe e um conjunto de assets. A slice pode virar o capítulo 1 sem alongamento artificial.

### Marco 5 — Reutilização e previsão da campanha

**Entregáveis:** segundo trecho/arena usando sistemas existentes, progressão e painel de provas mínimos, ferramentas pequenas de autoria e regressão. Consolidar contratos; não construir editor genérico. Esboçar os seis chefes restantes em papel/cenas mínimas e validar cedo os dois de maior risco.

**Saída:** segunda arena criada sem copiar controladores inteiros; principais riscos dos chefes restantes conhecidos. Estimar restante com esforço observado, disponibilidade semanal declarada e reserva inicial de 30% para integração/QA. Rever a reserva com os dados reais, sem contar múltiplos agentes como multiplicação linear de produtividade.

### Marco 6 — Campanha completa em greybox

**Entregáveis:** prólogo e sete capítulos compactos, todos os chefes, recompensas, evidências e final funcional. Produzir um capítulo por vez, mantendo a campanha anterior finalizável. Reusar arte do kit aprovado onde útil; não adiar descobertas de legibilidade para o fim.

**Saída:** campanha inteira concluível, sem softlocks, com curva de dificuldade e tempos observados por encontro. Validar progressão e final antes de investir em novos kits visuais.

### Marco 7 — Acabamento integrado

**Entregáveis:** completar arte, áudio e textos a partir do padrão já aprovado; corrigir diferenças de qualidade, transições e feedback. Mostrar consequências coletivas por pequenos eventos roteirizados, rádio e mudanças nos cenários. Validar builds Linux continuamente e Windows nativo antes de confirmar lançamento nessa plataforma.

**Saída:** identidade consistente, ameaças legíveis e recompensa perceptível; narrativa compreensível sem documentos longos. Congelar conteúdo e focar defeitos.

### Marco 8 — QA e lançamento

**Entregáveis:** campanha e save testados em instalação limpa, balanceamento, acessibilidade básica, licenças, créditos, pacotes reproduzíveis e documentação das configurações suportadas. Linux obrigatório; Windows entra se validado, ou fica explicitamente adiado. Preparar demo sem exigir integração com loja.

**Saída:** campanha finalizável no Linux suportado com desempenho documentado, sem bugs bloqueantes conhecidos, progresso recuperável e limitações declaradas. Publicação/distribuição externa é uma decisão separada de Otávio após revisar a build.

**Regra de avanço:** arquivos existentes e testes headless não aprovam diversão, estética, input ou compatibilidade gráfica. Cada marco precisa de build, evidências e registro de pendências. Não iniciar a produção em massa dos capítulos enquanto a slice não cumprir seu gate.

---

## 10. Prioridades e cortes para produção solo

### P0 — Provar o núcleo

Movimento, mira mouse/gamepad, uma arena, pistola/espingarda, golpe/empurrão, dois inimigos, barril/caixa, navegação limitada e exportação Linux medida. Um alvo com padrões testa o contrato de boss; o chefe completo pertence à slice.

### P1 — Entregar uma slice bonita e gratificante

Chacal, três ambientes curtos no mesmo kit, arte representativa, áudio, save/checkpoint/retry, menus/remapeamento e uma consequência narrativa visível. Windows só é anunciado com teste nativo. Sem terceiro arquétipo obrigatório.

### P2 — Completar campanha compacta

Prólogo e sete líderes, capítulos de 1–2 setores, curva de dificuldade, até quatro armas portáteis, granada, variações de ameaças e final coletivo. Ferramentas e arte adicionais precisam justificar seu custo com conteúdo reutilizável.

### P3 — Após a campanha, se houver interesse e capacidade

Modo desafio/ranking, dificuldade extra, arenas adicionais, localizações e dispositivos incomuns. Cooperativo exige novo planejamento técnico e não é compromisso de atualização. Acessibilidade básica e gamepad permanecem pré-lançamento.

**Ordem de corte:** ranking/desafios -> novos presets/efeitos caros -> armas e arquétipos redundantes -> rotas e setores extras -> fases extras de chefes -> animações secundárias/cutscenes -> sistemas exclusivos de um único capítulo. Preferir mecanismo compartilhado com composição distinta por chefe. Preservar controle, legibilidade, save/retry, sete líderes, arco narrativo e testes Linux no hardware-alvo.

**Escopo mínimo da campanha:** prólogo breve, sete missões compactas de um setor com arena final, dois arquétipos básicos e variações em dados, duas armas portáteis + granada, um kit industrial com variações por capítulo e sete confrontos com combinações distintas de padrões compartilhados. Recompensas podem ser ferramentas contextuais e consequências narrativas; não exigir sete sistemas permanentes inéditos. Duração pode ficar abaixo da referência de 2–4 h se o resultado for mais consistente. Se até esse mínimo exceder a capacidade observada, Otávio revisa o compromisso de campanha antes de produção adicional, sem mascarar o problema com mais geração de código.

---

## 11. Critérios de qualidade

### Funcionais

- A campanha tem começo, meio e fim.
- São sete líderes, enfrentados em ordem de poder.
- Exploração suporta ir para a direita, voltar à esquerda e usar rotas verticais.
- Todas as mortes relevantes são explicáveis por telegraph, posição ou erro recuperável.
- A campanha não depende de conexão à internet.
- Recompensas, upgrades e evidências persistem após fechar o jogo.
- Conteúdo opcional não bloqueia a conclusão canônica.

### Técnicos

- Sem erros ou avisos críticos no console de release.
- FPS e memória documentados em cenários comparáveis no Inspiron.
- Sem acúmulo ilimitado de corpos, partículas, timers ou projectiles.
- Save com versão e recuperação segura.
- Execução estável em exportação Linux desde o início, na configuração declarada; Windows validado nativamente antes de anunciar suporte.
- Arte e sons com licenças rastreadas.

### Experiência

- O controle parece ágil mesmo sem upgrades, tanto no mouse/teclado quanto no gamepad.
- A estética minimalista e sombria preserva silhuetas, plataformas, retículo e avisos.
- Encontros apresentam, praticam e combinam ameaças; a vitória e os desbloqueios produzem feedback claro e oportunidades de uso.
- Fases novas introduzem risco/mecânica, não apenas novos fundos.
- O jogador entende quem são os sete líderes e o que cada um sustenta.
- A prova final é construída ao longo do jogo e sua divulgação tem consequência visível.
- O final mostra a participação autônoma dos trabalhadores.

---

## 12. Riscos e mitigação

| Risco | Gravidade | Mitigação |
|---|---|---|
| Física destrutiva estoura orçamento | Alta | Objetos marcados, colisores simples, limite de corpos, benchmark antes da campanha |
| Controles parecem desajeitados | Crítica | Prototipar movimentação isoladamente e fazer playtests curtos |
| Gamepad oferece mira muito inferior ao mouse | Alta | Analógico direito no P0, assistência limitada/opt-in e playtest comparativo antes da slice |
| Exploração vertical cria tiros injustos ou câmera confusa | Alta | Arenas com ângulos testados, retículo legível, telegraphs e deslocamento de câmera com limite |
| Escopo excede disponibilidade humana | Crítica | Medir esforço por marco, limitar trabalho em andamento e usar campanha compacta; duração não é compromisso |
| Escopo dos 7 chefes atrasa tudo | Alta | Limitar padrões/fases, reusar componentes, provar cedo os dois mais arriscados e cortar sistemas exclusivos |
| Codex cria scripts monolíticos | Alta | Especificar arquitetura, testes, revisão e tarefas pequenas |
| Arte leva mais tempo que código | Alta | Arena representativa no Marco 3/4, folha de estilo, kit modular e orçamento medido por asset |
| Instâncias Codex divergem ou conflitam | Alta | Contratos estáveis, propriedade de arquivos, branches/worktrees isoladas e integração por responsável único |
| Estética escura prejudica leitura | Alta | Contraste por plano, silhuetas distintas e teste em tela real com efeitos reduzidos |
| Linux funciona só no editor ou em uma máquina | Alta | Pacote nativo desde o Marco 0, matriz real de driver/sessão e teste fora da pasta de desenvolvimento |
| Incompatibilidade de GPU/driver | Alta | Compatibility, testes no Dell real, perfis gráficos, checagem de exportação |
| Narrativa vira exposição excessiva | Média | Mostrar operações e documentos curtos, cenas curtas, ritmo mantido |
| Dificuldade inconsistente | Alta | Testadores externos e telegraphs, checkpoints antes de chefes |
| Bugs em save/progressão | Alta | Save versionado, backups, testes automatizados e manual de regressão |
| Uso indevido de assets de referências | Alta | Criação autoral e catálogo de licenças |

---

## 13. Como trabalhar — Otávio + Codex

### 13.1 Responsabilidades e ritmo

- **Otávio:** direção criativa, prioridades, aprovação estética, playtest de sensação/legibilidade, decisões de escopo e publicação. Não precisa especificar cada arquivo para pedir uma melhoria; Codex inspeciona o projeto e propõe um recorte implementável.
- **Codex:** implementação, testes automatizados pertinentes, diagnóstico, ferramentas de autoria, documentação e apoio na criação de conteúdo original. Relata o que executou, o que observou e o que depende de teste humano. Não declara diversão ou qualidade visual comprovadas apenas por compilação.
- **Unidade de trabalho:** um resultado jogável pequeno, com objetivo, limites, critérios de aceite e verificação. Registrar contratos/arquivos afetados depois de inspecionar o estado atual.
- **Limite:** uma tarefa central em integração por vez. Depois de cada incremento, importar/verificar, exportar quando pertinente e jogar a cena afetada. Ao fim de cada ciclo, atualizar esforço e uma lista curta de defeitos/hipóteses.
- **Fonte de verdade:** este documento é o plano vigente. `docs/GDD.md`, `ROADMAP.md`, `ARCHITECTURE.md`, `PERFORMANCE.md` e `AGENTS.md` serão criados incrementalmente no Marco 0; evitar duplicar regras divergentes. Até existirem, ler este arquivo diretamente.
- **Orçamento:** registrar horas de atenção humana, tempo de execução dos agentes, retrabalho e eventuais gastos aprovados. Reduzir escopo quando revisão e integração se tornarem o gargalo.

### 13.2 Múltiplas instâncias Codex

O projeto admite trabalho paralelo quando solicitado e houver tarefas independentes. Este plano descreve o processo; não exige paralelismo em toda tarefa.

1. Um Codex responsável pela integração mantém a build jogável e define contratos mínimos antes de dividir trabalho. Começar com uma instância; adicionar outra quando isso reduzir um gargalo observado.
2. Delegar por fronteira: testes de save, documentação de benchmark ou props de uma biblioteca são candidatos; dois agentes alterando simultaneamente o controlador do jogador não são.
3. Cada tarefa informa base/commit, arquivos sob responsabilidade, interface esperada e critérios de aceite. Preferir branches e worktrees separados, com diretórios de saída distintos para builds/assets.
4. `project.godot`, InputMap, autoloads, contratos compartilhados e cena principal têm um responsável por vez. Mudanças nesses pontos são sequenciais; conflitos exigem revisão e teste, sem aceitar automaticamente uma versão.
5. Usar a mesma versão de engine/templates e preservar identificadores/referências de recursos gerenciados pelo projeto. Não versionar caches locais da Godot; evitar importar simultaneamente a mesma cópia do projeto.
6. Integrar um conjunto pequeno por vez: revisar diff, importar em headless, executar testes relevantes, abrir/exportar e verificar comportamento. Um agente revisor pode ajudar, mas Otávio continua responsável pelo aceite de sensação e estética.
7. Agentes extras não autorizam novos sistemas, novos assets pagos ou aumento de escopo. Priorizar correção, autoria repetitiva bem definida e verificação independente.

### 13.3 Convenções técnicas

1. Inspecionar antes de editar; preservar a cena jogável existente e preferir composição simples.
2. Mudanças pequenas, rastreáveis, sem frameworks sem necessidade observada; commits por resultado coerente.
3. Não adicionar assets externos sem origem/licença; registrar também recursos originais/gerados e sua curadoria.
4. Relatar arquivos alterados, verificações executadas, resultados e pendências. Sem Godot disponível, declarar que importação/exportação não foram executadas.
5. Não atualizar engine/renderizador sem decisão registrada; engine e templates usam a mesma versão.
6. Headless verifica estrutura/lógica; sessão gráfica e controle físico verificam renderização/input. Não confundir os dois.
7. Sem backend, telemetria, contas ou dependências online desnecessárias. Testes locais e scripts simples vêm antes de infraestrutura de CI.
8. Testes automatizados focam regressões de dano, munição, estados, save e reset. Não criar testes que apenas repitam detalhes internos de mudanças visuais reversíveis.
9. Publicação, mensagens externas e gastos dependem de instrução própria; preparar artefatos revisáveis antes dessa decisão.

### 13.4 Primeiro backlog

- [ ] Registrar distribuição/sessão Linux, hardware, GPU/driver, disponibilidade semanal e ferramentas existentes.
- [ ] Inicializar Git, documentação mínima e projeto na engine/templates fixados, Compatibility.
- [ ] Criar menu mínimo e arena temporária; exportar Linux, executar fora do editor e registrar medição inicial.
- [ ] Criar Player/InputMap e implementar movimento, câmera, coyote time e jump buffer.
- [ ] Implementar vetor de mira único, deadzone, última direção válida e retículo; testar dois presets de gamepad.
- [ ] Testar alvos à esquerda/direita e acima/abaixo, paredes próximas e perda/retorno de foco.
- [ ] Criar overlay de frametime/FPS e captura simples para benchmark local.
- [ ] Implementar vida/dano, pistola e primeiro recruta com feedback provisório.
- [ ] Adicionar golpe/empurrão, barril, segunda arma, pickups/munição/recarga e batedor.
- [ ] Provar navegação limitada, obstrução de tiro e cobertura destruída.
- [ ] Medir cenários com 3/6/10 inimigos e resets repetidos em Linux no Dell.
- [ ] Produzir pequena prancha de estilo e uma arena industrial escura com acabamento representativo.
- [ ] Registrar esforço real, feedback interno e próximos cortes antes de ampliar conteúdo.
- [ ] Preparar exportação Windows e registrar a disponibilidade de teste nativo; não bloquear a prototipação Linux por essa pendência.

### 13.5 Prompt inicial para implementação futura

> Leia o plano vigente `PLANO_DESENVOLVIMENTO_RUPTURA_v1_1_REVISADO.md` (conteúdo v1.3) e as instruções/documentos do projeto que já existirem. Trabalhamos com Otávio + Codex; você pode propor divisão de tarefas independentes, sem presumir equipe adicional. Execute o Marco 0 e o início do Marco 1 em Godot 4.7.2, GDScript tipado e Compatibility: projeto limpo, Git local, documentação mínima, menu, arena temporária, personagem responsivo, câmera e overlay de desempenho. Linux nativo é desenvolvimento e teste desde o início: exporte, execute fora do editor e registre hardware/driver/sessão reais. Desde o começo, ofereça mira 360° com mouse ou analógico direito, movimento desacoplado, deadzone e última direção válida. Teste alvos em alturas diferentes e presets que permitam pular e mirar. A direção visual é pixel art minimalista industrial e sombria, inspirada na síntese de Superfighters, com assets originais e boa legibilidade. Não implemente os sete capítulos agora. Use placeholders próprios simples e mantenha um incremento jogável. Sem backend, multiplayer ou shaders caros. Informe arquivos alterados, testes realmente executados, resultados, esforço observado e pendências; não declare compatibilidade, input ou qualidade sem a verificação correspondente.

---

## 14. Definition of Done do projeto

- [ ] Executar offline em pacote Linux na configuração suportada, com resultados reais no hardware-alvo. Windows só é incluído e anunciado após validação nativa.
- [ ] Ter prólogo, sete missões compactas e sete líderes diferenciados, com campanha concluída e sem duração mínima artificial.
- [ ] Ter exploração horizontal/vertical útil, combate próximo e à distância, física seletiva e explosões significativas.
- [ ] Ter controles confortáveis, mira 360° e menus operáveis com teclado/mouse e gamepad; remapeamento e opções básicas de acessibilidade.
- [ ] Apresentar estética minimalista industrial sombria consistente, com silhuetas, tiros, plataformas e avisos legíveis no perfil mínimo.
- [ ] Ensinar antes de combinar ameaças; oferecer dificuldade padrão e assistida, checkpoints justos e retry rápido.
- [ ] Comunicar impacto, vitória, desbloqueio e consequências no mundo; permitir experimentar recompensas sem grind.
- [ ] Persistir equipamentos/provas/progresso, com checkpoint reproduzível, backup e recuperação testados nas versões suportadas.
- [ ] Entregar a narrativa do agente traído, provas, conspiração e vitória coletiva dos trabalhadores sem exigir leitura extensa.
- [ ] Concluir playtests externos, campanha em instalação limpa, regressão de save e QA das plataformas anunciadas.
- [ ] Creditar ferramentas/assets e manter origem/licenças rastreáveis.

**Decisão principal:** provar uma vertical slice bonita, divertida e gratificante em Linux, com mouse/teclado e gamepad, antes da campanha. Produzir mais conteúdo depende de qualidade observada e capacidade real de autoria/revisão.

---

## 15. Registro de revisão e decisões abertas

### 15.1 Histórico

- **v1.3 — 26/10/2026, instrução direta de Otávio:** protagonista passa a executivo de terno preto e ex-aspirante a diretor; origem anterior de agente militar substituída. Direção corporativa mais escura, paleta inspirada na síntese de cores de Superfighters com assets originais. Analógico esquerdo move/orienta, direito preciso independente opcional. Inimigos padrão mais perigosos por cadência, mobilidade e dano, preservando avisos e modo assistido. O escopo de campanha e gates humanos não são ampliados por essa revisão.

- **v1.1:** gamepad antecipado, mira 360°, espingarda temporária antes do desbloqueio, identidade jogável e contratos mínimos antes da slice.
- **v1.2 — 25/10/2026:** Linux passa a plataforma primária desde o Marco 0; Windows condicionado à validação nativa. Equipe explicitada como Otávio + Codex, com processo opcional de múltiplas instâncias. Direção estética minimalista industrial sombria, prova artística antecipada, campanha compacta e sem obrigação de 4–6 horas. Limites por arma/inimigo/chefe, política de cortes, curva de dificuldade, recompensas, playtest observável, checkpoints e escrita segura. Marcos ganham orçamento inicial de atenção humana, controle de esforço e gates de qualidade/capacidade.

**Nome do arquivo:** mantido para preservar referências existentes; a versão vigente é a do cabeçalho. Ao desmembrar a documentação no Marco 0, registrar os destinos sem criar duas fontes de verdade.

### 15.2 Decisões a validar

- Disponibilidade semanal e orçamento real de Otávio; os tetos por marco não são prazo de lançamento.
- Hardware Linux exato, GPU ativa, driver e sessão gráfica; disponibilidade de validação Windows nativa.
- 480×270 ou 640×360, tamanho do personagem, escala inteira e UI independente na tela real.
- Preset de gamepad, cancelamentos, esquiva e assistência de mira após comparação jogável.
- Quantidade de ameaças/objetos e percentis de frametime após benchmark; não tratar hipóteses como compatibilidade comprovada.
- Custo humano observado de uma arena, um chefe e um kit de arte; projeção da campanha apenas após a slice.
- Duração real e necessidade de armas/arquétipos extras. Cortar repetição e recursos redundantes antes de ampliar conteúdo.
- Disponibilidade de voluntários para a rodada externa; manter esse gate pendente se não houver evidência.
