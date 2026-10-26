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

A ferramenta salva `reports/pixel-art-sheet.png` em 960×832: quatro personagens, idle, oito pontos do ciclo de corrida, salto/ápice/queda/pouso, agachar, esquiva, dano, morte, recuo e oito direções de mira. Corpos e estados aparecem em 2×; mira em 1×. Cada pose é um nó visual isolado; não instancia missão, input, áudio ou save. A prancha mostra poses estáticas: revisar também o ciclo em movimento e a legibilidade na arena, em escala real e com efeitos reduzidos.

O aceite visual e de conforto permanece pendente até a revisão humana. Importação, PNG gerado e testes de lógica não comprovam qualidade artística.

## Atlas e revisão de movimento

Os arquivos em `assets/art/actors/` são PNGs originais, gerados a partir de receitas de pixels no repositório. São cinco atlas de corpo (Espectro, recruta, batedor, Chacal e sua paleta de fase2) e três de armas (pistola, espingarda, lâmina), sem imagem externa. Corpo comum ocupa célula32×40 com origem(16,36); Chacal48×48 com origem(24,44). Oito poses de passada alternam apoio, passagem e balanço. Células adicionais representam respiração, crouch, salto/ápice/queda, pouso, esquiva, reação e morte; algumas células de timing repetem poses. Armas têm32 direções rasterizadas antecipadamente. Tiros continuam com mira física contínua.

Regeneração e captura:

```bash
"$GODOT_BIN" --headless --path . --script tools/art/build_actor_atlas.gd
python3 tools/validation/validate.py import
"$GODOT_BIN" --path . --script tools/art/preview_actors.gd
"$GODOT_BIN" --path . --script tools/art/record_movement.gd
python3 tools/art/assemble_apng.py reports/movement-frames reports/movement-preview.png
```

A última ferramenta apenas empacota os PNGs capturados em uma animação APNG, sem repintura, interpolação ou dependências externas. O vídeo curto usa o controlador real num cenário isolado de revisão, com entradas roteirizadas e sem missão ou saves. Mostra passada, recuo, corrida, salto/pouso, crouch, esquiva e recuo de tiro a12 quadros por segundo. A captura de revisão ignora perda de foco apenas nessa fixture; o jogo mantém sua pausa normal ao perder foco. Não é um benchmark ou playtest humano.

Passadas usam deslocamento real pós-colisão; não avançam correndo contra parede. O recuo percorre o ciclo ao contrário sem inverter a mira. Aterrissagem dura100ms visualmente; armamento e retículo permanecem separados do atlas corporal. Colisores, velocidades, gravidade, janelas de esquiva e dano foram preservados.
