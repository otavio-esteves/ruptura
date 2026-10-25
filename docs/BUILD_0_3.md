# Build0.3 — Cinzas

Data:25/10/2026. Fontes do executável: `86b8d7f7cc4a48f5687a58060ce015b3dcddd171`. Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility, Linux x86_64.

Entregues três setores industriais originais, quatro encontros comuns, Chacal com duas fases/três padrões, dois documentos opcionais, prova obrigatória, transmissão e desfecho coletivo. HUD do chefe, cooldown de esquiva, resumo, retry, save separado da missão, assistência de mira opt-in no controle, deadzone e efeitos reduzidos. Laboratório0.2 preservado. Sem produção dos demais capítulos.

## Artefatos locais

- `builds/linux/ruptura.x86_64`:73.656.000 bytes, recursos embutidos, executável.
- SHA-256 do executável: `4e202e660b1a89b18ae83e8cd13b2cbd9a9b24c031342d1a85807e8420d51c5b`.
- `builds/ruptura-0.3-linux-x86_64.tar.gz`:28.446.135 bytes; inclui executável, manifesto, instruções e guias.
- SHA-256 do pacote: `3171ae46cbef2913de4e80c086de30ac78bcafe7826ae68b082e24fdd3177c4a`.
- Manifesto local: `builds/linux/BUILD_INFO.json`. Build0.2 preservada em `builds/archive/ruptura-0.2.x86_64`.

Exportação passou. Executável copiado para `/tmp/ruptura-cinzas-release/` abriu graficamente e produziu captura de10s; saída0. O conteúdo do tar foi extraído em `/tmp/ruptura-package-verify/`, checksum e permissão executável conferidos, e o binário extraído abriu por180 frames com esse diretório como cwd; saída0, escrita em user:// confirmada, sem erros ou avisos críticos. GPU efetiva registrada: Radeon R7M260/radeonsi, Mesa25.0.7, no Dell Inspiron5547.

## Verificação

Suíte consolidada:746 verificações aprovadas, sem erros/avisos. Após o ajuste de persistência do HUD entre setores/retries, os testes relevantes de missão e laboratório foram repetidos:80 verificações adicionais aprovadas, sem erros/avisos. Capturas finais de ruína/pátio/chefe/opções/encerramento inspecionadas em sessão gráfica.

Os testes verificam lógica e física em cenas controladas. O fluxo integrado mata inimigos por API; não equivale a uma partida humana ou avaliação de dificuldade. Testes de chefe incluem colisão real com caixa e pouso no piso anunciado. Capturas preparadas por script permitem inspecionar estados sem alegar playtest humano concluído. Todos os novos testes de missão usam arquivos isolados; progresso real não é substituído por fixtures.

## Captura curta de entrada

Janela1280×720, base640×360, cap60FPS,2s de aquecimento, entrada da ruína parada sem combate.582 frames/10,007s: média58,16FPS, p95=20,586ms, p99=36,936ms, máximo89,901ms;1%low17,26FPS pelo método documentado em PERFORMANCE. Houve trabalho de empacotamento na mesma sessão; não é benchmark controlado de combate. Os percentis não aprovam a meta experimental60FPS. Dados locais em `reports/cinzas-entry-benchmark.json` e user://benchmarks/2026-10-25T20-33-36.csv.

Pendentes: playtest de sensação/ritmo/arte, controle físico e reconexão, audição, memória/temperatura e benchmark prolongado em combate/boss. Windows não validado. A missão não possui duração mínima comprovada. Nenhuma publicação externa ou compra de assets foi realizada. Atenção humana e tempos individuais dos agentes não foram medidos.
