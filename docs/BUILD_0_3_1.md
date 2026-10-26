# Build0.3.1 — pixel art e movimento

Data:26/10/2026. Fontes: `162e6e57fb3a39fe4770a18cf3305a80cb2b3edf`. Godot4.7.2 stable, Compatibility, Linux x86_64.

## Resultado

Oito atlas PNG originais substituem os corpos temporários e o desenho simples das armas. Espectro, recruta, batedor e Chacal têm paletas/silhuetas próprias; a fase2 usa uma variação da armadura. A passada usa oito poses e deslocamento real pós-colisão, com ciclo invertido no recuo. Respiração, salto/ápice/queda, aterrissagem100ms, crouch, esquiva, reação e morte têm apresentação própria. Corpo e arma continuam independentes; armas são rasterizadas em32direções visuais com mira física contínua.

Materiais do cenário e props receberam clusters de ferrugem, rebites, juntas, madeira, aros e reflexos do vidro; pickups têm formas reconhecíveis. Filtros nearest e snapping visual mantêm os pixels definidos. Colisores, velocidade, gravidade, dano e regras de combate foram preservados. Fonte de autoria e ferramentas: [ART_DIRECTION](ART_DIRECTION.md).

## Evidências

- Suíte existente:746 verificações aprovadas, sem erros ou avisos no log.
- Importação e exportação Linux passaram. O pacote inclui os oito assets importados.
- Sessão gráfica: prancha dos quatro personagens, três setores, chefe e encerramento inspecionados; sem erros de console.
- Captura roteirizada de movimento com controlador real:109frames a12FPS, empacotados como APNG sem resampling. Fixture isolada, sem missão ou save; não equivale a playtest humano.
- Executável copiado para `/tmp/ruptura-pixel-release/` e iniciado nesse cwd por180frames: saída0, escrita em user:// confirmada, Radeon R7M260/Compatibility no Dell. Sem erros ou avisos críticos.
- Tar verificado: hash do executável coincide com manifesto, permissão executável preservada e ambas as prévias presentes.

## Artefatos

- `builds/linux/ruptura.x86_64`:73.696.904bytes; SHA-256 `975855de545d3e9a847afff19a00e99aa01028c16d856770541fdc78f4359667`.
- `builds/ruptura-0.3.1-linux-x86_64.tar.gz`:29.136.480bytes; SHA-256 `e22bb34873feee7f5696d8617932e1d55271f40995ebeb555a1382e133383762`.
- Prancha: `reports/pixel-art-sheet.png`,960×832.
- Prévia animada: `reports/movement-preview.png`, APNG960×360; abrir em navegador compatível. As prévias também acompanham o pacote.
- Build0.3 anterior preservada em `builds/archive/ruptura-0.3.x86_64`.

Aceite artístico, conforto, controle físico e benchmark prolongado continuam pendentes de avaliação. Não foram adicionados sistemas de campanha ou assets de terceiros neste incremento.
