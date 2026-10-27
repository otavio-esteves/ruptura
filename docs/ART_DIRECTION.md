# Corredor e protagonista0.4.3 — apresentação vigente

Pedido de27/10/2026: corredor da referência como início de fase e personagem literalmente igual à folha. O panorama é copiado sem alterações para `assets/art/reference/office-corridor.png`;37poses são organizadas em atlas por `tools/art/import_reference_art.gd`. Há recortes diretos e separação de poses vizinhas por silhueta nas regiões onde contornos encostam. Não há reamostragem de cores na autoria. O herói anterior continua arquivado no atlas nativo, mas o renderer do protagonista usa a nova folha.

`reference_hero.gd` preserva recortes inteiros nas poses horizontais. Nos ângulos que a folha não oferece, braços/arma são articulados a partir dos mesmos pixels; o tórax oculto usa a pose de punhos da folha. Recarga parada usa poses completas; agachada/em movimento combina a base corporal com braços da recarga. Essas composições são adaptações, não cópias pixel a pixel de uma pose que não existe na fonte. A folha oferece uma única arma visual; pistola e espingarda conservam munição, dano e identificação no HUD, compartilhando a arte desse armamento. A origem física de disparo acompanha o mesmo pivô e cano, inclusive com obstrução antes da boca da arma.

No corredor, escala3/16 e câmera16/3 produzem1pixel de tela por pixel fornecido, na janela1280×720. A cena horizontal tem407,25unidades de largura e mantém o chão em620; câmera vertical em−45. Não há repetição do panorama ou plataformas sobrepostas. O guarda e a porta fornecem um trecho jogável; o menu mantém acesso separado a Cinzas e ao laboratório.

O novo uso literal foi explicitamente solicitado e substitui a proibição anterior de copiar essas duas imagens. A origem agora é o material fornecido pelo usuário, não imagegen ou autoria nativa original. Os registros abaixo continuam históricos. Capturas em `reports/corridor-review/`, captura de movimento com `--fixed-fps 12` e montagem a partir de `reports/corridor-movement-frames/`. Aceite artístico e conforto continuam humanos.

---

# Acabamento0.4.2 — apresentação vigente

A direção atual usa três fundos bitmap originais, gerados com imagegen, e atores redesenhados em densidade2× pelo código nativo. Prompts e hashes em [ART_PROMPTS_0_4_2](ART_PROMPTS_0_4_2.md); critérios e rodadas de comparação em [REFERENCE_TARGET](REFERENCE_TARGET.md). Os registros0.4/0.4.1 abaixo descrevem a evolução anterior; a adoção dos bitmaps e da nova resolução substitui a restrição anterior ao desenho de cenários inteiramente por primitivas.

`tools/art/build_actor_atlas.gd` delega a autoria a `detail_actor_recipe.gd`. Células comuns64×80 e chefe96×96 são desenhadas nos mesmos retângulos lógicos32×40/48×48 e pivôs. Armas usam células96×96 para32direções. Viewport1280×720/câmera2× preservam o campo lógico640×360. A recarga usa `action=reload` e `action_progress` do controlador real; o renderer não transfere munição.

Passarelas reaproveitam a pedra pintada do térreo, com consoles de aço e uma linha quente no topo físico. As faixas decorativas entre vãos recebem sombra e não têm aresta clara contínua. Arte estática, sem nova luz dinâmica ou mudança de colisão.

Prancha vigente:960×1024, incluindo recarga parada, agachada e em movimento. Captura de movimento:160quadros a12FPS,13,33s. Usar `--fixed-fps 12` é obrigatório: o tempo simulado deve permanecer correto mesmo quando a gravação de PNGs demora. A ferramenta rejeita uma execução com delta diferente. Montar o APNG apenas após a captura terminar com sucesso. Os quadros e o APNG são relatórios locais, fora da exportação e do Git.

---

# Referências fornecidas / refinamento0.4.1

Em26/10/2026, Otávio acrescentou duas referências locais: `references/Pixel-Art Corporate Lobby Brawl Stage.png` e `references/Retro Pixel Action Hero Sprite Sheet.png`. Elas orientam composição e acabamento: cidade por trás de janelas altas, persianas, luz quente, madeira, plantas e sinais de ocupação; executivo de cabelo expressivo, terno carvão, camisa clara, gravata vinho e poses angulares. Os desenhos continuam autorais, construídos no pipeline nativo; as imagens de referência não são recortadas em assets nem entram no pacote exportado. A procedência/licença das referências não foi informada, portanto não são distribuídas com a build.

Esta revisão preserva tamanho dos atores, pivôs, câmera, física, layouts e colisores. A maior densidade visual precisa manter as bordas de colisão, os avisos e o terno legíveis na escala de jogo. Decoração estática não recebe luz dinâmica ou processamento por pixel a cada quadro.

A ferramenta `tools/art/preview_mission.gd` captura os três setores com HUD e atores reais em uma sessão gráfica. Usa um diretório de perfil temporário exclusivo e não grava no progresso normal. Saídas: `reports/reference-review/archive.png`, `operations.png` e `boardroom.png`, além de `boardroom-warning.png` com o aviso da segunda fase e efeitos reduzidos. Execute depois de gerar/importar os atlas:

```bash
"$GODOT_BIN" --path . --script tools/art/preview_mission.gd
```

São cenas congeladas para revisar arte e contraste; a animação continua sendo registrada por `record_movement.gd`. Ambas complementam o playtest e não aprovam diversão ou conforto.

# Direção corporativa0.4

Decisão direta do usuário: o protagonista é executivo e ex-aspirante a diretor, em terno preto, camisa clara e gravata. O cenário representa Arquivo Morto, Centro de Operações e Conselho Executivo. Base cromática carvão/cinza, oliva frio e marrons/vinho dessaturados, com âmbar para leitura funcional. A faixa cinza do plano de fundo preserva a silhueta do terno preto; não há overlay que escureça HUD ou avisos.

Referência visual consultada: [imagens oficiais de Superfighters Deluxe](https://store.steampowered.com/app/855860/Superfighters_Deluxe/) e [página do estúdio](https://mythologicinteractive.com/SuperfightersDeluxe). É uma leitura de síntese, paleta e contraste; nenhum sprite ou cenário foi reutilizado.

Paleta do executivo: terno#2b3037, sombra#1c2027, lapelas#3b4148, aresta#484f57, camisa#c4c2b6, gravata#242124, calça#24272c e sapatos#17191d. Roupa militar, visor e máscara anteriores foram removidos de todas as poses. Guardas usam oliva, couro e vinho discretos; a Chacal mantém leitura própria e variação da fase2. As receitas continuam no gerador nativo abaixo.

---

# Pipeline de pixel art e animação

Pixel art industrial sombria, com silhuetas pequenas e ameaça legível. O plano vigente continua sendo a referência de escopo; esta folha orienta o incremento visual e não aprova estética ou sensação de controle.

## Paleta e leitura

- Fundos: azul carvão `#101921`, aço escuro `#19252d` e variações pouco contrastantes por setor. Tubos, cabos e sucata ficam atrás da faixa de contraste dos atores.
- Superfícies sólidas: aço médio e aresta clara. Plataformas unilaterais mantêm o topo âmbar. Textura usa poucos clusters de 1–3 pixels e não cria falsas bordas de colisão.
- Espectro: terno carvão, camisa clara, gravata e rosto visível. Recruta: capacete compacto, uniforme cobre/industrial e postura mais rígida. Batedor: silhueta leve e lenço visível, distinguível pela forma além da cor. Chacal: ombreiras e armadura mais largas; detalhes quentes indicam autoridade e a segunda fase.
- Âmbar comunica aviso; coral comunica ameaça/impacto; verde frio comunica recurso/interação. Efeitos preservam o contraste do retículo e dos avisos de ataque.

As cores exatas dos personagens são centralizadas no gerador do atlas. A prancha usa o mesmo renderer do jogo, evitando uma segunda interpretação dos sprites.

## Grade e animação

Desenhar e posicionar os sprites na grade de pixels; usar filtragem nearest e escala inteira. Origem nos pés, com pivôs consistentes entre poses. Braço e arma miram independentemente do corpo, mantendo movimento desacoplado da orientação. Arredondamento visual não modifica a posição física ou os colisores.

O ciclo de corrida avança pela distância percorrida. Pé de apoio e quadril precisam alternar contato, passagem e extensão; ao parar, retornar a uma pose de apoio sem manter o ciclo correndo no lugar. Corpo, pernas e braço têm pequenas diferenças de fase, preservando uma silhueta clara. Salto, ápice, queda e pouso têm poses distintas; agachar e esquivar reduzem a silhueta, sem alterar a regra física para acomodar a arte. Recuo afeta braço/arma brevemente. Dano e morte devem ser reconhecíveis com efeitos reduzidos e sem flash obrigatório.

O contrato `PixelActor.draw_actor(canvas, pose)` recebe `kind`, `state`, `cycle`, `facing`, `aim`, `recoil`, `flash`, `phase` e, quando necessário, `crouch_moving`, `weapon`, `action`, `action_progress`. Estados visuais e fases de ataque vêm do ator; o helper não decide acertos, invulnerabilidade ou transições de combate. Avisos, barras e tracers continuam com seus responsáveis originais.

## Autoria e revisão

`tools/art/build_actor_atlas.gd` constrói o atlas de pixels original do projeto. Alterar esse código e regenerar os assets mantém o resultado reproduzível, com origem rastreável e sem copiar imagens de referência. `game/visuals/pixel_actor.gd` escolhe as poses e compõe corpo, braço e arma. O gerador e o renderer pertencem ao integrador; não editar imagens geradas independentemente do código de autoria.

Após gerar/importar o atlas, executar em sessão gráfica, sem `--headless`:

```bash
/home/otavio/Downloads/Apps/Godot_v4.7.2-stable_linux.x86_64 --path . --script tools/art/preview_actors.gd
```

A ferramenta salva `reports/pixel-art-sheet.png` em 960×1024: quatro personagens, idle, oito pontos do ciclo de corrida, salto/ápice/queda/pouso, agachar, esquiva, dano, morte, recuo e oito direções de mira. Corpos e estados aparecem em 2×; mira em 1×. Cada pose é um nó visual isolado; não instancia missão, input, áudio ou save. A prancha mostra poses estáticas: revisar também o ciclo em movimento e a legibilidade na arena, em escala real e com efeitos reduzidos.

O aceite visual e de conforto permanece pendente até a revisão humana. Importação, PNG gerado e testes de lógica não comprovam qualidade artística.

## Atlas e revisão de movimento

Os arquivos em `assets/art/actors/` são PNGs originais, gerados a partir de receitas de pixels no repositório. São cinco atlas de corpo (Espectro, recruta, batedor, Chacal e sua paleta de fase2) e três de armas (pistola, espingarda, lâmina), sem imagem externa. O retângulo lógico comum ocupa32×40 com origem(16,36); Chacal48×48 com origem(24,44). Na0.4.2, as células de autoria têm o dobro dessas dimensões. Oito poses de passada alternam apoio, passagem e balanço. Células adicionais representam respiração, crouch, salto/ápice/queda, pouso, esquiva, reação e morte; algumas células de timing repetem poses. Armas têm32 direções rasterizadas antecipadamente. Tiros continuam com mira física contínua.

Regeneração e captura:

```bash
"$GODOT_BIN" --headless --path . --script tools/art/build_actor_atlas.gd
python3 tools/validation/validate.py import
"$GODOT_BIN" --path . --script tools/art/preview_actors.gd
"$GODOT_BIN" --path . --fixed-fps 12 --script tools/art/record_movement.gd
python3 tools/art/assemble_apng.py reports/movement-frames reports/movement-preview.png
```

A última ferramenta apenas empacota os PNGs capturados em uma animação APNG, sem repintura, interpolação ou dependências externas. O vídeo curto usa o controlador real num cenário isolado de revisão, com entradas roteirizadas e sem missão ou saves. Mostra passada, recuo, corrida, salto/pouso, crouch, esquiva e recuo de tiro a12 quadros por segundo. A captura de revisão ignora perda de foco apenas nessa fixture; o jogo mantém sua pausa normal ao perder foco. Não é um benchmark ou playtest humano.

Passadas usam deslocamento real pós-colisão; não avançam correndo contra parede. O recuo percorre o ciclo ao contrário sem inverter a mira. Aterrissagem dura100ms visualmente; armamento e retículo permanecem separados do atlas corporal. Colisores, velocidades, gravidade, janelas de esquiva e dano foram preservados.
