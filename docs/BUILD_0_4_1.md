# Build0.4.1 — referências visuais

Data:26/10/2026. Base: `7b2e82a29ec2e534cfad926fdf2aa3691c0d5994` mais alterações locais sem commit. Godot4.7.2 stable, GDScript tipado, Compatibility, Linux x86_64.

## Resultado

As duas imagens adicionadas por Otávio orientaram o refinamento autoral. Espectro ganhou cabelo irregular, rosto e mandíbula legíveis, terno ajustado, camisa clara, gravata vinho, abas de paletó e braços com apoio de segunda mão. Morte conserva rosto e roupa. Células/pivôs e física foram preservados.

Os setores receberam janelas altas com cidade, persianas, colunas, luz quente, recepção, escritórios, sofás, plantas, quadros, bebedouro e papéis. Uma segunda revisão das capturas corrigiu a escala dos móveis: mesas24px, balcão27px, sofá26px, armário56px; decoração apoiada no recuo em y606. Luminárias de parede aparecem no enquadramento do chão. Layouts, colisores, rotas e IDs de save continuam os mesmos.

O batedor respeita o cone travado que anuncia; o avanço da Chacal anuncia o alcance completo nas duas fases. Vida55/40/420, dano, cadência e modo assistido permanecem os da0.4. Três regressões verificam saída lateral do cone, acerto frontal e dano único.

## Evidências

- Suíte completa:832 verificações aprovadas; nenhum erro/aviso no log. Importação final e exportação Linux sem erros/avisos.
- Atlas regenerados a partir do código nativo; prancha gráfica960×832 e109quadros a12FPS do controlador real, empacotados em APNG sem interpolação.
- Capturas dos três setores e aviso de segunda fase com efeitos reduzidos inspecionados. Ferramenta nova `preview_mission.gd` usa perfil temporário exclusivo e não altera progresso real.
- Benchmark roteirizado de Operações com três inimigos, tiros/recarga e movimento,12s após2s de aquecimento:56,24FPS médios no limite60; p9530,32ms/p9934,25ms. Limite30:30,00FPS, p9534,61ms/p9937,20ms. Radeon R7M260,1280×720, AC conectada. Amostras curtas não atingem os limiares do plano e não aprovam desempenho; detalhes em [PERFORMANCE](PERFORMANCE.md).
- Executável copiado para `/tmp/ruptura-041-portable-d5h5l0o8/`, iniciado com perfil isolado e `DRI_PRIME=0`: Intel HD4400,180quadros, saída0 e escrita em user:// confirmada, sem erros/avisos. A tentativa automática anterior de selecionar Radeon bloqueou antes do carregamento do jogo; processo de sondagem observado em `rpm_resume` no kernel. A Radeon funcionou nas capturas e benchmarks do runtime de desenvolvimento anteriores. O guia registra a execução pela Intel, sem presumir corrigido o problema de driver.
- Referências excluídas dos presets de exportação e ignoradas pela importação. Relatórios locais recebem `.gdignore`, evitando importar CSVs como traduções. O primeiro export detectou esse aviso; o export final já passou limpo.

## Artefatos

- Executável: `builds/linux/ruptura.x86_64`,73.708.312bytes, SHA-256 `54b7eceb116a4660bb432d6149ade640ead429c61e6494558e1bf06489d56332`.
- Pacote: `builds/ruptura-0.4.1-linux-x86_64.tar.gz`, 29.262.816bytes, SHA-256 `69125b41c2ce52c22393dc5b886598dfde2a733b707f12d0778f94e700e63cda`. Contém executável, manifesto, instruções e três prévias; hash embutido/permissão executável conferidos.
- Capturas: `reports/reference-review/{archive,operations,boardroom,boardroom-warning}.png`; prancha `reports/pixel-art-sheet.png`; animação `reports/movement-preview.png`.
- Binário anterior preservado em `builds/archive/ruptura-0.4.x86_64`.

Três especialistas trabalharam em arquivos distintos, com integração, engine e testes centralizados. Não houve commits concorrentes, assets pagos, publicação ou expansão da campanha. Playtest humano de diversão/balanceamento, aceite artístico, conforto em gamepad físico, audição e benchmark prolongado seguem pendentes.
