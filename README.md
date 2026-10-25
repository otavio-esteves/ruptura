# RUPTURA

Protótipo local de ação 2D. Incremento atual: fundação Linux e laboratório de movimento/mira, sem combate. Plano vigente: [GDD v1.2](PLANO_DESENVOLVIMENTO_RUPTURA_v1_1_REVISADO.md).

Godot **4.7.2 stable**, GDScript, Compatibility; física a 60Hz. Abra `project.godot` nessa versão e execute F6/F5 conforme a cena. A cena principal oferece menu, arena e teste de áudio sintetizado. A arena usa primitivas próprias como placeholders; ainda não é a arte final.

```bash
export GODOT_BIN=/home/otavio/Downloads/Apps/Godot_v4.7.2-stable_linux.x86_64
"$GODOT_BIN" --path .
```

Na arena: A/D ou setas movem; Ctrl corre; Espaço salta (soltar reduz altura); S agacha; S+Espaço desce plataforma; Shift esquiva. Mouse mira. Controle: analógico esquerdo move, direito mira, A salta, B esquiva, clique esquerdo corre, direcional baixo agacha/desce. F2 alterna salto A/LB para comparação; menus usam foco e ações de UI padrão da Godot. O preset é temporário e não implementa remapeamento completo.

R/Back reinicia posição e estados. Esc/Start volta ao menu; perda de foco interrompe o jogador. F3 alterna limite30/60FPS mantendo a física a60Hz. F6 mede10s após2s de aquecimento e grava CSV em `user://benchmarks/`. Retome a arena para jogar depois do menu.

Pacote Linux fica em `builds/linux/ruptura.x86_64`. Windows possui preset de preparação e depende de validação nativa. Scripts locais em `tools/validation/`; detalhes de medição em [PERFORMANCE](docs/PERFORMANCE.md). Builds, caches e relatórios brutos são ignorados pelo Git.

Não há campanha, save de progresso, armas ou inimigos neste incremento. Um arquivo de diagnóstico em `user://prototype_probe.txt` verifica escrita no diretório de usuário. Sensação de controle, gamepad físico, legibilidade, áudio audível e testes longos permanecem sujeitos a playtest.
