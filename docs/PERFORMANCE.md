# Desempenho e verificação Linux

Referência de escopo e gates: plano vigente, seções 8, 9 e 13. Este registro não aprova conforto, aparência ou compatibilidade por testes headless.

## Ambiente observado — 25/10/2026

- DMI: Dell Inc. Inspiron 5547, revisão A13. É o notebook-alvo do plano.
- CPU Intel Core i7-4510U, 2 núcleos/4 threads; MemTotal observado 16.261.896 kB (~15,5 GiB).
- Debian GNU/Linux 13.7 (trixie), kernel 6.12.111+deb13-amd64, x86_64.
- Sessão Wayland; DISPLAY=:0 e WAYLAND_DISPLAY=wayland-0.
- Sonda `glxinfo -B`: renderização direta acelerada Intel HD Graphics 4400 (HSW GT2), Mesa 25.0.7-2+deb13u1, OpenGL Compatibility 4.6.
- PCI também identifica AMD Topaz XT (família Radeon R7 M260/M265 e variantes), driver amdgpu; seu uso pelo jogo não foi verificado. Intel usa i915.
- Engine executada para identificação: 4.7.2.stable.official.ed1daf0bf.
- Templates de exportação ausentes na inspeção inicial. Ferramentas não os baixam automaticamente. Engine e templates precisam ter a mesma versão.

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

Para medir o pacote, copiar executável e `.pck` gerados para uma pasta temporária fora do projeto, entrar nessa pasta e executar graficamente:

```bash
./ruptura.x86_64 -- --auto-arena --benchmark-seconds=600
```

O overlay integrado descarta 2 s de aquecimento e então gera `user://benchmarks/<timestamp>.csv` com coluna `frame_ms`. Na configuração padrão Linux, `user://` fica sob `~/.local/share/godot/app_userdata/RUPTURA/`; conferir o caminho exibido pelo jogo. Benchmark headless deve ser rejeitado pela coleta. Registrar separadamente observações de carregamento e percurso feito; uma arena sem inimigos não representa combate.

```bash
python3 tools/validation/summarize_frames.py /caminho/benchmark.csv --output reports/benchmark-summary.json
```

O resumo usa intervalos de tempo real por frame renderizado, em milissegundos. Média de FPS = `1000 / média(frame_ms)`. Percentis p95/p99 usam nearest rank: ordenar N intervalos e selecionar índice `ceil(p*N)-1`. O **1% low** é `1000 / média dos ceil(N*0.01) maiores intervalos`; para N<100 usa ao menos um frame. Não equivale a 1/p99. Nenhuma amostra é removida silenciosamente: valores vazios, não finitos, zero ou negativos causam falha; stutters presentes permanecem no resultado. Nenhum filtro de aquecimento é aplicado pelo resumo. A soma dos intervalos informa duração observada.

## Verificação das ferramentas neste ciclo

Executados: identificação da engine, coleta de ambiente e verificação das fórmulas com sequência 1..100 ms (p95=95, p99=99, 1% low=10 FPS), amostra única e rejeição de conjuntos vazios/valores inválidos. Importação/exportação e execução gráfica são responsabilidade da integração centralizada; seu resultado deve ser registrado após a integração.

## Pendências do gate

- Importar e executar o projeto integrado sem erros.
- Instalar/verificar templates idênticos à engine; exportar e executar Linux fora do editor e da árvore do projeto.
- Capturar 10 minutos no pacote gráfico, com resolução/perfil/cap de FPS e commit; medir memória e observar stutters.
- Validar input, áudio, gravação em `user://`, foco, redimensionamento, fullscreen e reconexão de controle físico.
- Comparar mira e movimento a 30/60 FPS com mouse/teclado e gamepad real.
- Cenários com inimigos, explosões e boss ficam para os marcos próprios; não aprovados pelo benchmark vazio.
- Windows exige validação nativa própria; não executada.

As metas experimentais do plano são p95≤16,7 ms/p99≤33,3 ms a 60 FPS ou, por decisão explícita, p95≤33,3 ms/p99≤50 ms a 30 FPS. Este registro não declara nenhuma meta atingida.
