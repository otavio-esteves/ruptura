# Build0.4.2 — retomada e acabamento

Data:27/10/2026. Fonte do executável: commit `445d2fa9ab9cbce88a3ddd8cd8db8565394fa7f9`. Godot4.7.2 stable, GDScript tipado, Compatibility, Linux x86_64. O trabalho interrompido foi preservado em `8c00de7`; os ajustes finais de cenário e documentação artística estão no commit de fonte acima.

## Resultado

Três fundos bitmap originais e atlas nativos em densidade2× compõem a apresentação1280×720/câmera2×, mantendo o campo lógico640×360. O executivo, a direção corporativa, a mira pelo movimento e a dificuldade reforçada continuam. A recarga visual usa o progresso real do controlador, com arma, mãos e carregador articulados; não transfere munição pelo renderer.

As passarelas agora usam a pedra pintada do térreo em vez da testeira clara chapada. Consoles de aço dão apoio visual, e uma linha quente marca o topo físico. As faixas decorativas do fundo ficam recuadas em sombra, sem aresta clara contínua. Layouts, colisores, navegação, física e regras de save foram preservados.

## Verificação executada

- Suíte completa:834 verificações aprovadas, saída0, sem erros ou avisos. Abrange movimento, combate, recarga, navegação, inimigos, chefe, persistência, missão, mira e dificuldade.
- Importação e exportação Linux release concluídas sem erros ou avisos. Lista de92recursos exportados conferida: sem arquivos de `references/`, `reports/`, `tools/`, `tests/` ou `docs/` no executável.
- Novas capturas gráficas de menu/opções, Arquivo, rota alta, Operações e Conselho; aviso da fase2 com efeitos reduzidos. Inspeção local das imagens confirma a distinção de material/valor entre apoio real e decoração recuada. Comparação lado a lado regenerada.
- APNG remontado com todos os160quadros salvos, substituindo a montagem interrompida de54quadros. Conferidas sequência contínua, quantidade e duração:12FPS,13,33s. Inspecionadas amostras de corrida, salto, esquiva e recarga parada/agachada/em movimento. Não foi feita nova captura do controlador neste fechamento; os160quadros são da captura recuperada.
- Executável copiado para diretório temporário fora do projeto, iniciado graficamente com `--quit-after 180 -- --auto-mission`, perfil isolado e `DRI_PRIME=pci-0000_00_02_0`. Intel HD4400 confirmada no log, saída0, escrita de `prototype_probe.txt` no perfil temporário e nenhum erro/aviso. Áudio em driver Dummy: audição não avaliada.
- `git diff --check` passou. Testes e capturas usam perfis isolados; o smoke portátil não usa o progresso real.

## Artefatos locais

- Executável: `builds/linux/ruptura.x86_64`, 78,255,520bytes.
- SHA-256 do executável: `40ba44e0bc612e4df467259ba86909a839d2ca2c3139a8610966a3425334ac21`.
- Manifesto: `builds/linux/BUILD_INFO.json`, com o commit de fonte e resultados.
- Pacote: `builds/ruptura-0.4.2-linux-x86_64.tar.gz`, com executável, manifesto, instruções, guias e prévias originais. A prancha que contém referências fica apenas no relatório local e não é distribuída. Checksum próprio no arquivo `.tar.gz.sha256` adjacente.
- Binário0.4.1 preservado em `builds/archive/ruptura-0.4.1.x86_64`; pacote0.4.1 anterior mantido.
- Capturas: `reports/reference-review/`; comparação: `reports/reference-comparison.png`; animação: `reports/movement-preview.png`; prancha: `reports/pixel-art-sheet.png`.
- Logs locais: `/tmp/ruptura-042-{import,check,export,preview,comparison}.log` e `reports/portable-042-intel.log`.

## Limites

Este fechamento verifica estrutura, lógica, imagens estáticas e inicialização gráfica do pacote. A composição continua modular; aceite artístico comparado às referências, fluidez/conforto a30/60FPS, controle físico, diversão, balanceamento, áudio audível e desempenho prolongado continuam pendentes. As medições0.4.1 não aprovam o desempenho da apresentação0.4.2. Não houve teste nativo Windows, publicação ou expansão da campanha.
