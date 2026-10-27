# RUPTURA

Build **0.4.3 — corredor de abertura / protagonista da referência**, em Godot4.7.2 stable, GDScript e Compatibility. Linux é o alvo primário. O [plano v1.5](PLANO_DESENVOLVIMENTO_RUPTURA_v1_1_REVISADO.md) continua como fonte de design.

## Jogar

```bash
./builds/linux/ruptura.x86_64
```

Se a Radeon bloquear na reativação do driver, use `DRI_PRIME=pci-0000_00_02_0 ./builds/linux/ruptura.x86_64` para iniciar pela Intel integrada deste equipamento. A inicialização automática da Radeon apresentou bloqueio no ciclo anterior; veja as evidências de cada pacote nos registros de build.

O executável tem os recursos embutidos e pode ser copiado para outra pasta. No menu, escolha **Jogar corredor / início** para o novo trecho. Há um guarda junto à saída; depois do confronto, use **E / ↑** na porta para retomar Cinzas. O corredor não grava sobre o progresso existente. **Continuar Cinzas** e **Nova missão Cinzas** continuam disponíveis. Para abrir o projeto no editor, use `project.godot` com Godot4.7.2.

A entrega contém **três setores** (Arquivo Morto, Operações e Conselho), quatro encontros comuns, Chacal em duas fases, dois registros opcionais e uma prova obrigatória com transmissão final. Há rotas altas, suprimentos, caixas, vidro e barris explosivos. O laboratório de combate0.2 permanece acessível pelo menu.

Escolha **Nova missão Cinzas** para começar ou **Continuar Cinzas** para retomar. Avance para leste; após limpar Arquivo Morto/Operações, pressione **E** junto ao portão de saída. No conselho, enfrente Chacal, recolha os registros e use o transmissor. Espere os avisos dos ataques: a recuperação do chefe abre uma oportunidade de dano; barris podem quebrar sua postura. A espingarda aparece no percurso e fica disponível nos checkpoints posteriores.

Ao limpar uma área, vida e armamento são reabastecidos e o checkpoint é gravado. Morte oferece retry; fechar/reabrir retoma o último checkpoint. Objetos e inimigos transitórios são reconstruídos, e dano parcial do chefe é descartado. Segredos e contagem de quedas persistem. Concluir a transmissão mostra o resultado; F5 ou o botão permite repetir. Detalhes no [guia de Cinzas](docs/CINZAS.md).

| Ação | Teclado/mouse | Controle de referência Xbox |
|---|---|---|
| Mover | A/D ou setas | Analógico esquerdo |
| Correr | Ctrl | Clique no analógico esquerdo |
| Saltar | Espaço; soltar reduz altura | A; preset alternativo LB |
| Agachar / descer plataforma | S / S+Espaço | ↓ / ↓+salto |
| Esquivar | Shift | B |
| Mirar | Mouse | Esquerdo acompanha movimento; direito independente opcional |
| Atirar | Mouse esquerdo | RT |
| Golpear / empurrar | Mouse direito | RB |
| Recarregar | R | X |
| Trocar arma | 1/2/Q ou roda | Y ou → |
| Interagir | E | ↑ |
| Retomar checkpoint | F5 | Back ou botão na tela de morte |
| Menu / pause | Esc | Start |

F2 alterna salto A/LB; também há botão nas opções operável por controle. F3 alterna limite30/60FPS com física a60Hz; F4 mostra diagnóstico; F6 captura10s de frametimes após2s de aquecimento; F11 alterna tela cheia. Os atalhos de diagnóstico não substituem medição comparável.

Opções incluem assistência leve de mira só no controle, deadzone radial, efeitos reduzidos, tremor de câmera opcional, volume, remapeamento das teclas de movimento/ações principais e modo assistido. A dificuldade é aplicada no próximo retry: avisos inimigos45% mais longos e dano inimigo42% do padrão, combinando modificadores explícitos de inimigo/jogador. O gamepad possui os dois presets de salto, mas ainda não tem remapeamento completo.

## Save e verificação

A missão fica em `user://cinzas.json`, o laboratório em `checkpoint.json` e preferências em `settings.json`, normalmente `~/.local/share/godot/app_userdata/RUPTURA/`. Gravação usa temporário validado e backup do último arquivo válido. Corrupção tenta recuperar o backup; se ambos estiverem inválidos, a interface pede Nova missão e preserva os arquivos até essa escolha. Não há contas, backend ou conexão exigida para jogar.

```bash
python3 tools/validation/validate.py check
python3 tools/validation/validate.py export-linux
```

`GODOT_BIN` pode indicar outro caminho para a engine4.7.2. A suíte verifica movimento, munição, recarga, cobertura, dano, explosões, inimigos, navegação, save e fluxo do encontro. Fixtures de save usam diretórios isolados; não sobrescrevem o progresso real. Veja [PERFORMANCE](docs/PERFORMANCE.md), [arquitetura](docs/ARCHITECTURE.md) e [roteiro de playtest](docs/PLAYTEST.md).

Esta build amplia o protótipo em direção à slice de Cinzas, com chefão e desfecho; a campanha de sete capítulos não está implementada. Sons e parte da arte têm autoria nativa; o corredor e o protagonista usam o material fornecido por Otávio, conforme o registro0.4.3. A apresentação continua sujeita a curadoria. Conforto, balanceamento, controle físico, áudio audível e desempenho prolongado precisam de playtest. Windows tem apenas preset de preparação e não foi validado nativamente.

## Pixel art e movimento0.3.1

Personagens usam atlas originais com contorno de1pixel e paletas próprias. Oito poses de passada são percorridas pela distância real; andar de costas inverte o ciclo sem inverter a mira. Salto/ápice/queda, pouso curto, agachar, esquiva, reação e morte têm poses distintas. Braço e arma ficam independentes do corpo e as armas possuem32direções visuais. A mira física continua em360°. Cenários, caixas, barris, vidro e pickups ganharam textura e detalhes próprios.

A origem dos sprites e ferramentas de regeneração estão em [ART_DIRECTION](docs/ART_DIRECTION.md). Prévia estática: `reports/pixel-art-sheet.png`; animação APNG: `reports/movement-preview.png` (abrir em navegador compatível). As prévias são capturas de revisão; não substituem jogar e avaliar conforto. Velocidades, colisores, dano e regras de combate foram preservados.

## Direção corporativa e controle0.4

Espectro agora é um executivo de terno preto que aspirava a uma diretoria da VÉRTICE. O visual usa camisa clara, gravata, lapelas e sapatos, sem máscara ou uniforme militar. Arquivos, operações e conselho adotam paleta mais escura, mobiliário de escritório e divisórias. A referência de síntese cromática é Superfighters; sprites e cenários são originais.

No gamepad, o esquerdo move horizontalmente e orienta a mira em360°, inclusive vertical/diagonal. Ao centralizar, a última direção fica retida. Para mover e mirar separadamente, abra **Opções e controles → Mira independente no direito**. Nesse modo, o direito mantém a direção ao soltar, enquanto o esquerdo continua movendo. Essa opção é diferente de Assistência leve no controle. Mouse/teclado continuam independentes.

O padrão ficou mais difícil por maior dano, cadência, mobilidade e reposicionamento dos guardas. A vida dos inimigos foi preservada:55recruta,40batedor,420Chacal. O modo assistido continua disponível no próximo retry, com avisos mais longos e dano reduzido. Veja os números atuais em [COMBAT_RULES](docs/COMBAT_RULES.md).

## Refinamento das referências0.4.1

As referências locais fornecidas orientaram uma nova silhueta do executivo e interiores mais ricos: janelas altas com cidade, persianas, recepção, sofás, plantas, luz quente, quadros e detalhes de ocupação. A arte foi desenhada pelo código do projeto; os PNGs de referência ficam fora do executável. A geometria e as rotas existentes foram preservadas.

O batedor agora respeita o cone anunciado; o aviso do avanço da Chacal cobre todo seu alcance. Vida, dano e cadência permanecem os da0.4. Prévia dos setores em `reports/reference-review/`, prancha em `reports/pixel-art-sheet.png` e animação em `reports/movement-preview.png`. Validação e pacote: [BUILD_0_4_1](docs/BUILD_0_4_1.md).

## Acabamento0.4.2

Fundos bitmap originais e sprites redesenhados em densidade2× compõem a apresentação1280×720, com câmera2× e o mesmo campo lógico de640×360. O HUD compacto libera espaço para a arquitetura. Passarelas usam a pedra pintada do piso e consoles de aço; a aresta quente identifica o topo físico, enquanto as vergas decorativas ficam recuadas em sombra. Layouts e colisores permanecem iguais.

A recarga articula arma, mãos e carregador a partir do tempo real do controlador, inclusive parado, agachado e em movimento. A prévia `reports/movement-preview.png` foi remontada com os160quadros completos,12FPS e13,33s. Capturas atualizadas em `reports/reference-review/` e comparação em `reports/reference-comparison.png`. Resultado e limites da verificação em [BUILD_0_4_2](docs/BUILD_0_4_2.md); aceite artístico e playtest humano continuam pendentes.

## Corredor e protagonista0.4.3

A abertura usa o próprio panorama fornecido, inteiro e sem repetição. O protagonista vem dos pixels da folha: cabelo, rosto, roupa rasgada, gravata, mãos, arma e poses originais. A escala e a câmera do corredor exibem os dois assets em1:1 na janela1280×720. As poses horizontais usam os recortes inteiros; mira em ângulos ausentes e recarga com deslocamento combinam camadas da mesma folha para continuar jogáveis. Não se trata de uma nova geração aproximando o desenho.

Importação reproduzível: `tools/art/import_reference_art.gd`. Capturas locais: `reports/corridor-review/{entrance,middle,exit,hero-poses}.png`; animação: `reports/corridor-review/movement-preview.png`. O uso direto desses assets foi solicitado em27/10/2026 e substitui, para eles, a restrição anterior de apenas inspiração. Os registros de autoria0.4.2 acima descrevem a build anterior. Veja [BUILD_0_4_3](docs/BUILD_0_4_3.md).
