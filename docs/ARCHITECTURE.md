# Arquitetura do protótipo

`game/core/main.tscn` inicializa InputMap, menu, arena e overlay. `input_setup.gd` é responsável exclusivo pelas ações e pelo preset temporário A/LB. Não há autoloads ou serviços de campanha neste ciclo.

`prototype_arena.tscn` contém cenário e geometria criada no script, sem jogador. Expõe spawn e limites. `player.tscn` é CharacterBody2D com movimento e mira independente. Máscara17 colide com mundo(layer1) e plataformas(layer5); jogador usa layer2. Posição do jogador representa os pés. Câmera criada pelo integrador acompanha sem depender da mira.

`performance_overlay.gd` acompanha frames renderizados, omite2s de aquecimento e grava CSV por captura. Não captura headless. A UI usa CanvasLayer, e a geometria do mundo usa coordenadas nativas640×360 com escala inteira. Desenhos são placeholders de código originais.

Propriedade durante implementação paralela: especialista de controle em `game/actor/player/`; especialista de cenário em `game/world/levels/`; especialista QA em `tools/validation/` e `docs/PERFORMANCE.md`; integrador nos arquivos compartilhados. Importação/exportação sequenciais pelo integrador. Arquivos compartilhados não recebem versões concorrentes.
