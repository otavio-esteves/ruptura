# Arquitetura do protótipo0.2

`main.tscn` integra menu, opções, mundo e serviços locais. É o único responsável por montar a cena e coordenar pausa/retry. A arena usa `PROCESS_MODE_PAUSABLE`; menu/HUD e integração continuam processando durante pausa. O InputMap é instalado antes dos atores por `input_setup.gd`; opções reaplicam bindings preservando os eixos e botões do controle.

`prototype_arena.tscn` contém geometria e fundo industrial. Alvos visuais podem ser ativados ao abrir a cena diretamente, mas são omitidos no combate. `combat_director.gd` compõe três encontros, props, pickups, links de navegação e terminal, expõe objetivo/rádio e emite checkpoints. Não controla dano ou armas.

`player.tscn` trata movimento, mira e reação ao dano; `health_component.gd` concentra vida, janela de proteção e morte. `WeaponController` filho do player cuida de munição por instância, seleção, recarga, tiro e golpe. Configuração de armas é compartilhada como constantes imutáveis; estado de runtime fica nos dicionários da instância. `CombatFlash` usa coordenadas de mundo, TTL e limite de12 efeitos.

`enemy.tscn` usa a mesma vida, estados explícitos e dois perfis de comportamento. Raios de LOS e preparação antecedem ataques. Links autorados limitam navegação; não há promessa de travessia de geometria arbitrária. `destructible.tscn` representa caixa/barril/vidro; a explosão fotografa alvos e LOS antes de aplicar dano e difere cadeias. `pickup.tscn` aceita apenas jogador vivo e coleta uma vez.

Protocolo de dano: `receive_damage(amount, impulse, source)->bool`, grupo `damageable`. Jogador layer2; inimigos4; props8; mundo1; plataforma16. Corpos de atores usam mask25 (mundo/props/plataformas), e o tiro do jogador usa31 excluindo seu próprio RID. Inimigos ignoram camada4 nos tiros; explosões atingem ambos os lados com LOS. Atores têm origem nos pés.

`local_store.gd` guarda checkpoint versionado (estágio, evidência, conclusão) e settings separados. Checkpoints restauram receitas autoradas de vida/armamento, sem serializar física. Arquivo temporário é validado antes da substituição, e apenas o principal válido vira backup. Caminhos injetáveis isolam as fixtures de teste. O default do perfil real só é usado pelo jogo.

`combat_hud.gd` apresenta vida/arma/objetivo/rádio e retry. `sound_bank.gd` sintetiza sons originais com oito vozes limitadas, sem assets externos; headless omite playback. `performance_overlay.gd` mede frames com relógio monotônico e rejeita captura sem foco. Não há autoloads, backend ou serviços de campanha.

Neste ciclo os três especialistas tiveram propriedade exclusiva de armas, inimigos e props/testes. O integrador manteve health/player/main/InputMap/save/HUD e executou a engine sequencialmente. Primitivas gráficas e síntese de áudio são recursos originais provisórios, sem assets de jogos de referência.

## Expansão0.3

`main.gd` seleciona Cinzas ou laboratório; as opções foram extraídas para `options_panel.gd` com rolagem/foco de gamepad. Os schemas e arquivos dos dois modos são independentes. `cinzas_sector.tscn` cria apenas geometria/arte/dados de autoria, selecionados antes de entrar na árvore. `get_stage_layout` descreve encontros, props, recursos, segredos e saídas; o diretor instancia os sistemas existentes a partir disso.

`cinzas_director.gd` controla estágios0..6, checkpoints, saídas manuais, documentos opcionais e prova/transmissão. A interface de HUD/retry é compartilhada com o laboratório. `chacal.tscn` reutiliza Health e protocolo de dano, acrescentando padrões e duas fases; não altera armas ou controlador de inimigo comum. `field_document.gd` interage por proximidade+E, registra uma descoberta e concede recursos uma única vez.

O save novo `cinzas.json` contém stage/evidence/completed/boss_defeated/shotgun_unlocked/secrets/deaths. Arquivo separado evita reinterpretar o progresso antigo de laboratório. Backup também usa temporário validado antes de substituir o backup anterior. Não serializamos a física ou a vida parcial do boss. Settings acrescentam aim_assist/aim_deadzone/reduced_effects/screen_shake. A assistência está no vetor de mira do jogador, limitada a controle/cone/distância/LOS; raycasts de dano continuam retos.

Efeitos usam TTL e limites existentes. Setores desenham o fundo uma vez, sem processamento por frame; colisão usa somente superfícies jogáveis. O HUD limpa sua referência ao chefe após morte e permanece vivo entre setores/retries; attach substitui suas referências e limpa o resultado anterior. Rebuild remove referências ao mundo antigo antes de montar o novo. Testes usam caminhos injetáveis para manter saves reais intactos.

## Arte e animação0.3.1

`PixelActor` é um renderer sem lógica de jogo. Ele seleciona regiões de atlas, espelha o corpo pela orientação e compõe braço/arma pela mira. Armas são rasterizadas em32direções; raycasts continuam contínuos. `tools/art/build_actor_atlas.gd` é a fonte de autoria das imagens em `assets/art/actors/`, não uma dependência runtime. Texturas são carregadas/cacheadas uma vez pelo helper. Não há geração de pixels por frame no jogo.

Cada ator produz um dicionário de pose a partir do estado físico/combat existente. O ciclo de passos usa deslocamento pós-colisão, com sinal relativo ao facing; aterrissagem usa100ms apenas visuais. A geração de atlas e o desenho não modificam posição, colisores, velocidade ou dano. Snapping ocorre no render2D; o passo de física continua60Hz. `preview_actors.gd` e `record_movement.gd` são ferramentas isoladas, sem acesso a saves; APNG é montada a partir dos PNGs sem resampling.

## Controle e pressão0.4

InputMap separa `move_aim_*` (vetor radial do analógico esquerdo) de `aim_*` (direito), sem vincular as novas ações ao teclado. `independent_aim=false` seleciona o esquerdo; true seleciona o direito. Ambos mantêm última direção válida. A origem/física de tiros e o mouse não mudaram. Settings valida bool estrito e usa false em arquivos antigos; a opção é aplicada ao ator em tempo real e persistida separadamente dos checkpoints.

A dificuldade dos atores usa constantes nomeadas para HP, dano, preparo, recuperação e velocidade. O recruta usa `_reposition_speed` apenas na recuperação em chão estável, com ray de suporte e colisão real; não reutiliza navegação de salto nessa manobra. Para antes do próximo aviso. O ataque comum ganhou guard de resolução única, assim como os padrões da Chacal. Os arquivos/IDs do save e os layouts dos três setores não mudaram; apenas apresentação corporativa, textos, controle e parâmetros de combate foram revisados.

## Apresentação0.4.2

Viewport1280×720/câmera2× mantêm o campo de640×360unidades e as regras físicas. Atores são desenhados em64×80/96×96pixels de autoria nos mesmos retângulos/pivôs lógicos; `detail_actor_recipe.gd` substitui as primitivas antigas por receitas detalhadas. Armas usam96×96 por direção, mapeadas a48×48lógico. O renderer não muda mira/hitboxes.

O player fornece `action=reload` e progresso pela snapshot do controlador real. Corpo em movimento/agachado conserva seu ciclo; braços, arma e carregador seguem o progresso visual. Cancelamento/transferência de munição permanecem no controlador. Flash de boca e partículas de impacto usam posições reais de tiro e não existem para disparo obstruído na boca.

`cinzas_sector.gd` carrega três bitmaps originais cacheados de `assets/art/environments/`, compõe recortes estáticos por setor e mantém geometria/layouts/nav separados da decoração. Meios pixels de mundo representam pixels de tela na câmera2×. Os PNGs fornecidos em `references/` são apenas insumos de direção e não entram no pacote. Não há luz dinâmica, shader caro ou processamento de textura por pixel no runtime.
