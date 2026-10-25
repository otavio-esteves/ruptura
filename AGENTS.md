# RUPTURA — instruções de implementação

O plano vigente é `PLANO_DESENVOLVIMENTO_RUPTURA_v1_1_REVISADO.md` (conteúdo v1.2). Não duplicar o GDD. Incremento atual: Marco 0 e início do Marco 1; sem campanha ou combate neste ciclo.

- Godot 4.7.2 estável, GDScript tipado, renderizador Compatibility, Linux primário.
- Integração centralizada: somente o orquestrador altera `project.godot`, InputMap, cena principal e contratos compartilhados. Não importar a mesma cópia do projeto em paralelo.
- Equipe explicitamente autorizada pelo usuário: até três subagentes com arquivos distintos. Cada responsável relata alterações, verificações e limitações. Não ampliar escopo.
- Player: `game/actor/player/player.tscn`, raiz CharacterBody2D, script `player.gd`. Interface pública: `aim_direction: Vector2`, `input_device: String`, `reset_to(spawn: Vector2)`. Ações: move_left/right, crouch, jump, dodge, aim_left/right/up/down. Analógico esquerdo move; direito mira; mouse mira no mundo. Colisão jogador layer 2, mask 1.
- Arena: `game/world/levels/prototype_arena.tscn`, raiz Node2D; `prototype_arena.gd`. Não instancia Player ou câmera. Expõe `spawn_position: Vector2` em coordenadas locais e `world_bounds: Rect2`. Geometria estática layer 1; plataformas unilaterais layer 5 (valor 16), mask do jogador inclui 1+16. Arena aproximadamente 1600×720, spawn seguro próximo de (120, 550). Sem física destrutiva ou combate neste ciclo.
- Overlay: será integrado em `game/ui/`; métricas e ferramentas externas em `tools/validation/` por especialista de QA. Não executar importação Godot até integração central.
- Placeholders originais desenhados com primitivas em código; nenhum asset externo. Caches `.godot/`, builds e relatórios locais não são versionados.
- Headless comprova estrutura/lógica; renderização, conforto e gamepad físico exigem evidências próprias. Nunca declarar gates humanos concluídos por automação.
