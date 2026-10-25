# Build0.2 — registro de entrega

Data:25/10/2026. Fontes: `64ce9181f488171df536c60b13625d2d90ee4343`. Engine: `4.7.2.stable.official.ed1daf0bf`.

Artefato local: `builds/linux/ruptura.x86_64`, Linux x86_64 release, PCK embutido,73.605.760 bytes. SHA-256: `ceaea459ff96e1443b6a29a3c90488c5e0fa77e4902d18bf5bc8c896dbbb9a80`. Manifesto local em `builds/linux/BUILD_INFO.json`.

Exportação concluída sem erros. Binário copiado para `/tmp/ruptura-combat-release/` e executado com esse diretório como cwd por180 frames, fora do editor e do projeto: saída0, Compatibility na Radeon R7M260, escrita em `user://prototype_probe.txt` confirmada, sem erros ou avisos críticos no log. Abertura, HUD e disparo também exercitados graficamente no runtime de desenvolvimento; capturas de menu/opções/combate inspecionadas.

Verificação:171 checks da suíte completa e mais duas regressões do remapeamento, total173 aprovados. O fluxo automático confirma os três encontros, evidência, transmissão, persistência, morte e retry. Esse teste elimina inimigos por API para testar o diretor; não comprova diversão ou balanceamento. Navegação testa salto com pouso real e queda de plataforma. Dez resets confirmam jogador único e quantidade esperada de props. Arquivos de teste de save usam diretórios isolados.

Três especialistas trabalharam em armas, inimigos e objetos. Revisão e integração central corrigiram obstrução de cano, interrupção da navegação, knockback contra chão, colisão de agachar com props, corrupção do save e conflitos/cancelamento de remapeamento. Sem publicação ou gastos pagos. Tempo humano não medido.

Pendentes: playtest do recorte, gamepad físico, audição, balanceamento, validação de foco/fullscreen em uso humano e benchmark prolongado comparável. Windows não validado. Não há Chacal nem campanha nesta build. Roteiro em [PLAYTEST](PLAYTEST.md); controles no [README](../README.md).
