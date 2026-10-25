# Arquitetura do protótipo0.2

`main.tscn` integra menu, opções, mundo e serviços locais. É o único responsável por montar a cena e coordenar pausa/retry. A arena usa `PROCESS_MODE_PAUSABLE`; menu/HUD e integração continuam processando durante pausa. O InputMap é instalado antes dos atores por `input_setup.gd`; opções reaplicam bindings preservando os eixos e botões do controle.

`prototype_arena.tscn` contém geometria e fundo industrial. Alvos visuais podem ser ativados ao abrir a cena diretamente, mas são omitidos no combate. `combat_director.gd` compõe três encontros, props, pickups, links de navegação e terminal, expõe objetivo/rádio e emite checkpoints. Não controla dano ou armas.

`player.tscn` trata movimento, mira e reação ao dano; `health_component.gd` concentra vida, janela de proteção e morte. `WeaponController` filho do player cuida de munição por instância, seleção, recarga, tiro e golpe. Configuração de armas é compartilhada como constantes imutáveis; estado de runtime fica nos dicionários da instância. `CombatFlash` usa coordenadas de mundo, TTL e limite de12 efeitos.

`enemy.tscn` usa a mesma vida, estados explícitos e dois perfis de comportamento. Raios de LOS e preparação antecedem ataques. Links autorados limitam navegação; não há promessa de travessia de geometria arbitrária. `destructible.tscn` representa caixa/barril/vidro; a explosão fotografa alvos e LOS antes de aplicar dano e difere cadeias. `pickup.tscn` aceita apenas jogador vivo e coleta uma vez.

Protocolo de dano: `receive_damage(amount, impulse, source)->bool`, grupo `damageable`. Jogador layer2; inimigos4; props8; mundo1; plataforma16. Corpos de atores usam mask25 (mundo/props/plataformas), e o tiro do jogador usa31 excluindo seu próprio RID. Inimigos ignoram camada4 nos tiros; explosões atingem ambos os lados com LOS. Atores têm origem nos pés.

`local_store.gd` guarda checkpoint versionado (estágio, evidência, conclusão) e settings separados. Checkpoints restauram receitas autoradas de vida/armamento, sem serializar física. Arquivo temporário é validado antes da substituição, e apenas o principal válido vira backup. Caminhos injetáveis isolam as fixtures de teste. O default do perfil real só é usado pelo jogo.

`combat_hud.gd` apresenta vida/arma/objetivo/rádio e retry. `sound_bank.gd` sintetiza sons originais com oito vozes limitadas, sem assets externos; headless omite playback. `performance_overlay.gd` mede frames com relógio monotônico e rejeita captura sem foco. Não há autoloads, backend ou serviços de campanha.

Neste ciclo os três especialistas tiveram propriedade exclusiva de armas, inimigos e props/testes. O integrador manteve health/player/main/InputMap/save/HUD e executou a engine sequencialmente. Primitivas gráficas e síntese de áudio são recursos originais provisórios, sem assets de jogos de referência.
