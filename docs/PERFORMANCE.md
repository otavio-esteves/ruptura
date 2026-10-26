# Desempenho e verificação Linux

Referência de escopo e gates: plano vigente, seções 8, 9 e 13. Este registro não aprova conforto, aparência ou compatibilidade por testes headless.

## Ambiente observado — 25/10/2026

- DMI: Dell Inc. Inspiron 5547, revisão A13. É o notebook-alvo do plano.
- CPU Intel Core i7-4510U, 2 núcleos/4 threads; MemTotal observado 16.261.896 kB (~15,5 GiB).
- Debian GNU/Linux 13.7 (trixie), kernel 6.12.111+deb13-amd64, x86_64.
- Sessão Wayland; DISPLAY=:0 e WAYLAND_DISPLAY=wayland-0.
- Sonda `glxinfo -B`: renderização direta acelerada Intel HD Graphics 4400 (HSW GT2), Mesa 25.0.7-2+deb13u1, OpenGL Compatibility 4.6.
- PCI também identifica AMD Topaz XT, driver amdgpu. A Godot selecionou automaticamente a dedicada e registrou `AMD Radeon R7 M260 (radeonsi, iceland, ACO, DRM 3.61, 6.12.111+deb13-amd64)` no runtime gráfico. Intel usa i915.
- Engine executada para identificação: 4.7.2.stable.official.ed1daf0bf.
- Templates ausentes inicialmente; instalados pelo integrador após conferir SHA-512 oficial. Versão4.7.2 igual à engine; detalhes em [TOOLCHAIN](TOOLCHAIN.md). Fonte de energia AC conectada na verificação final.

O renderer da sonda GLX não comprova qual GPU a Godot efetivamente usará. Registrar também o cabeçalho de uma execução gráfica, resolução, limite de FPS, perfil, estado de energia e commit da build. Relatório completo local: `reports/environment.json`, gerado por `collect_environment.py`; não contém números de série.

## Comandos reproduzíveis

Executar da raiz do projeto, uma operação Godot por vez. `GODOT_BIN` pode apontar para outra instalação **4.7.2 estável**; padrão: `/home/otavio/Downloads/Apps/Godot_v4.7.2-stable_linux.x86_64`.

```bash
python3 tools/validation/collect_environment.py
python3 tools/validation/validate.py import
python3 tools/validation/validate.py check
python3 tools/validation/validate.py export-linux
```

`check` importa, executa 120 frames headless com `--auto-arena` e roda `tests/player_smoke.gd`, sem valor de benchmark. Os comandos falham se houver erros de processo, parser ou runtime emitidos pela engine. Cada subprocesso de importação/teste tem limite de 120 s; exportação, 180 s; identificação de engine, 15 s. O preset de exportação deve se chamar `Linux`; saída padrão `builds/linux/ruptura.x86_64`, com permissão executável. Exportação ausente ou malsucedida não equivale a suporte validado. Estes scripts não instalam dependências.

Para medir o pacote, copiar o executável gerado (PCK embutido) para uma pasta temporária fora do projeto, entrar nessa pasta e executar graficamente:

```bash
./ruptura.x86_64 -- --auto-arena --benchmark-seconds=600
```

O overlay integrado descarta 2 s de aquecimento e então gera `user://benchmarks/<timestamp>.csv` com coluna `frame_ms`. Na configuração padrão Linux, `user://` fica sob `~/.local/share/godot/app_userdata/RUPTURA/`; conferir o caminho exibido pelo jogo. Benchmark headless deve ser rejeitado pela coleta. Registrar separadamente observações de carregamento e percurso feito; uma arena sem inimigos não representa combate.

```bash
python3 tools/validation/summarize_frames.py /caminho/benchmark.csv --output reports/benchmark-summary.json
```

O coletor usa diferenças de `Time.get_ticks_usec()` entre frames, em milissegundos; não usa o delta ajustado pela engine. O CSV recebe um sidecar `.json` com GPU, engine, resolução e limite de FPS. Perda de foco ou abertura do menu cancela a captura sem produzir resultado; captura automática cancelada termina com código1. O resumo usa esses intervalos de tempo real por frame renderizado. Média de FPS = `1000 / média(frame_ms)`. Percentis p95/p99 usam nearest rank: ordenar N intervalos e selecionar índice `ceil(p*N)-1`. O **1% low** é `1000 / média dos ceil(N*0.01) maiores intervalos`; para N<100 usa ao menos um frame. Não equivale a 1/p99. Nenhuma amostra é removida silenciosamente: valores vazios, não finitos, zero ou negativos causam falha; stutters presentes permanecem no resultado. Nenhum filtro de aquecimento é aplicado pelo resumo. A soma dos intervalos informa duração observada.

## Verificação das ferramentas neste ciclo

Executados: identificação da engine, coleta de ambiente e verificação das fórmulas com sequência 1..100 ms (p95=95, p99=99, 1% low=10 FPS), amostra única e rejeição de conjuntos vazios/valores inválidos. Integração central executou importação, arena headless e21 verificações de jogador/menu, todas aprovadas. Exportação Linux release concluída e executável gráfico iniciado de `/tmp/ruptura-package`, fora do projeto, com saída0 após120 frames e sem erros. Escrita em `user://prototype_probe.txt` confirmada. Menu/arena capturados e inspecionados visualmente; tom sintetizado executou sem erro, mas audição não foi validada.

## Pendências do gate

- Capturar 10 minutos no pacote gráfico, com resolução/perfil/cap de FPS e commit; medir memória e observar stutters.
- Validar input, áudio, gravação em `user://`, foco, redimensionamento, fullscreen e reconexão de controle físico.
- Comparar mira e movimento a 30/60 FPS com mouse/teclado e gamepad real.
- Cenários com inimigos, explosões e boss ficam para os marcos próprios; não aprovados pelo benchmark vazio.
- Windows exige validação nativa própria; não executada.

As metas experimentais do plano são p95≤16,7 ms/p99≤33,3 ms a 60 FPS ou, por decisão explícita, p95≤33,3 ms/p99≤50 ms a 30 FPS. Este registro não declara nenhuma meta atingida.

## Evidências do pacote e medições exploratórias

Fonte do pacote: commit `908401e26c1f4bea269b26756b91b702ef95db5e`. Binário Linux x86_64 com73.547.568 bytes, SHA-256 `7b15c4104b58eba6bc80799ab54e06f964e7030d087d7eec41c0ab796728297b`. Manifesto local `builds/linux/BUILD_INFO.json`. Resolução interna640×360 e janela1280×720, cap60FPS, Compatibility; sem inimigos/combate. A sessão declarada é Wayland, sem afirmar backend nativo Wayland da janela Godot.

Antes da correção para relógio monotônico, duas sondagens no runtime de desenvolvimento produziram: AMD10s, média48,54FPS/p95 36,27ms/p99 51,88ms; Intel30s, média56,28FPS/p95 25,24ms/p99 34,03ms. A Intel foi selecionada com `DRI_PRIME=0`; a engine emitiu aviso sobre esse valor, mas identificou explicitamente Intel HD4400. São dados exploratórios baseados no delta da engine, sem controle suficiente de foco/carga; não são comparação conclusiva das GPUs e não aprovam meta alguma.

A tentativa de captura30s no pacote final foi cancelada por perda de foco e retornou1, sem CSV, como previsto. O smoke gráfico subsequente fora do diretório do projeto passou. Ainda é necessário medir o pacote final com janela ativa por10min e observar memória/stutters. Logs, capturas e relatórios brutos locais em `reports/` e `/tmp/ruptura-tools/`, não versionados.

## Ciclo0.2 — arena de combate

A build0.2 acrescenta combate e três encontros; os números exploratórios da0.1 acima não representam esse cenário. A suíte completa passou171 verificações, seguida por mais duas regressões de remapeamento no teste de menu. Inclui testes de munição/recarga/obstrução, dano/invulnerabilidade, explosões/LOS/cadeia, IA/ataque cancelado, salto/queda com colisão real, checkpoint/corrupção/settings e fluxo completo do encontro. Os testes de fluxo eliminam os inimigos por API para verificar o diretor; não simulam playtest de habilidade. Dez resets verificam uma única instância do jogador e o conjunto esperado de props. Saves de teste usam caminhos isolados.

Sessão gráfica local Compatibility na Radeon abriu menu/opções/arena e executou arma sem erros de console. Capturas em `reports/combat-{menu,options,arena}.png` inspecionadas. O menu inclui modo assistido, volume e remapeamento de teclado; gamepad tem presets, sem remapeamento completo. Audição e controle físico não verificados. Ainda não há dados suficientes para aprovar desempenho em combate ou sessenta FPS. Repetir benchmark prolongado no pacote exportado com janela ativa após o playtest.

## Ciclo0.3 — Cinzas expandido

Suíte consolidada:746 verificações aprovadas, sem erros ou avisos no log. A contagem inclui contratos de autoria dos layouts; não equivale a746 sessões de jogo. Cobre geometria/apoios reais dos três setores, padrões/fases/LOS da Chacal, dano único por ataque, impacto no piso avisado, cobertura atingida por dash, assistência de mira sem atravessar parede, corrupção/backup e fluxo completo com retry/segredos/transmissão/reabertura. Os testes de progressão eliminam inimigos por API; os de chefe exercitam tanto regras quanto colisões físicas em cenas de teste. Não comprovam diversão ou balanceamento.

A sessão gráfica de inspeção abriu ruína, pátio, duas fases do chefe, opções e encerramento na Radeon R7M260/Compatibility. Capturas em `reports/cinzas-*.png`. Os estados das capturas foram preparados por script para permitir inspeção repetível; não representam uma partida humana concluída. Arte de fundo estática e superfícies simples, sem luz dinâmica ou partículas permanentes. A função de assistência é opt-in e permanece pendente de avaliação com controle físico.

A aprovação do benchmark longo permanece aberta. As capturas exploratórias0.1 não valem para os cenários0.3. Para reproduzir a entrada de Cinzas no pacote, usar `-- --auto-mission --benchmark-seconds=600` com a janela ativa; a entrada parada não mede combate, chefe ou explosões. Para esses cenários, usar a mesma rota/atividade em capturas manuais e registrar o trecho. Guardar commit, GPU efetiva, estado de energia, resolução e opções junto dos CSVs.

## Polimento visual0.3.1

Novos atlas de pixels são gerados somente na autoria; o jogo seleciona regiões de texturas cacheadas. Passada e estados visuais acrescentam timers sem alterar a física. Fundo/material permanecem estáticos; não há luz dinâmica, shader caro ou ruído por pixel em runtime. Filtragem nearest e snapping de transforms atuam na apresentação.

A suíte de regressão existente passou746 verificações sem erros/avisos neste incremento. Capturas gráficas da missão e da prancha utilizaram a Radeon R7M260/Compatibility. `record_movement.gd` captura o controlador em um cenário de revisão isolado e roteirizado; não mede desempenho nem substitui teste humano. A prévia APNG usa os PNGs capturados sem interpolação. As medições antigas não aprovam desempenho da build0.3.1; o benchmark prolongado continua pendente.
