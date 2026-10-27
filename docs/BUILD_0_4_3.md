# Build0.4.3 — corredor e protagonista da referência

Data:27/10/2026. Fonte do executável: `9a3b76ac4954003dd7535f0a7e60b757c830f61a`. Godot4.7.2 stable, Compatibility, Linux x86_64.

## Entrega

Pedido direto: construir o corredor como início de fase e deixar o protagonista literalmente igual à folha fornecida. Para esses dois assets, o uso direto substitui a orientação anterior de apenas inspiração. O panorama é uma cópia byte a byte da imagem fornecida; o atlas organiza37poses do herói, sem reamostrar as cores. As quatro poses de apoio foram comparadas byte a byte com os respectivos recortes da fonte e são idênticas. A separação de silhuetas evita pedaços de poses vizinhas nas áreas de corrida/queda onde os contornos se encostam.

A entrada **Jogar corredor / início** abre a recepção horizontal: elevador, balcão, mesas, bebedouro, máquina, lounge e porta, sem repetir o panorama ou sobrepor plataformas. Escala3/16 e câmera16/3 exibem cenário e protagonista em1:1 na janela1280×720. O chão físico em620 concorda com os pés; um guarda protege a saída. E/↑ junto à porta retoma o checkpoint vigente de Cinzas. Abrir, limpar e repetir o corredor não substitui os saves da missão ou do laboratório.

As poses horizontais conservam os recortes inteiros. Mira em ângulos ausentes articula braços/arma da mesma folha e recompõe o tórax oculto com pixels da pose de punhos. A recarga parada usa poses completas; recarga agachada/em movimento combina a base de locomoção com os braços fornecidos. Essas composições são adaptações; não equivalem a poses idênticas inexistentes na folha. Há uma única arma visual na fonte, compartilhada pelos loadouts lógicos de pistola/espingarda; dano, munição e identificação no HUD continuam separados. A origem física e a obstrução antes do cano acompanham o rig importado.

## Evidências

- Suíte completa final:857 verificações aprovadas, sem erros/avisos. Inclui20 novas verificações do corredor e3 regressões da arma real do protagonista: obstrução antes do cano, gasto de munição e acerto após remover a parede.
- Testes de fluxo confirmam chão/parede reais, guarda único, saída, retry e preservação de um checkpoint já existente no estágio2 com estatísticas. Fixtures de missão/settings ficam em diretórios isolados.
- Novas capturas gráficas de entrada, meio, saída, poses, oito direções de mira e recarga. Comparação com as fontes em `reports/corridor-review/reference-comparison.png`. Inspeção local não é aceite artístico humano.
- Nova captura do controlador real:160quadros1280×720 a12FPS,13,33s simulados, com `--fixed-fps 12`. APNG remontado e número/dimensão/duração de todos os quadros conferidos. Amostras de corrida, esquiva e recarga inspecionadas. A fixture repete o fundo para sustentar o percurso longo; a cena jogável usa um único panorama.
- Importação/exportação sem erros/avisos.114recursos conferidos; JSON dos pivôs incluído explicitamente. Pastas `references/` e `reports/` continuam fora dos recursos exportados; os assets de uso direto ficam em `assets/art/reference/`.
- Executável iniciado de uma pasta temporária fora do projeto com `--quit-after 180 -- --auto-corridor`, perfil isolado e `DRI_PRIME=pci-0000_00_02_0`. Intel HD4400 confirmada, saída0, escrita do probe isolado confirmada, sem erros/avisos e sem criar `cinzas.json` ou `checkpoint.json`. Áudio Dummy; audição não avaliada.

## Artefatos

- Executável: `builds/linux/ruptura.x86_64`, 82838408bytes; SHA-256 `cd43b63ff1bca9f9f366b9d281f7b581be3969252d74162016bc98661ea60432`.
- Manifesto: `builds/linux/BUILD_INFO.json`; pacote: `builds/ruptura-0.4.3-linux-x86_64.tar.gz`, com checksum `.sha256` adjacente.
- O pacote contém executável, manifesto, licença, instruções, guias e três capturas do corredor. A animação de148MB e a prancha de comparação ficam apenas nos relatórios locais.
- Capturas: `reports/corridor-review/{entrance,middle,exit,hero-poses}.png`; animação: `reports/corridor-review/movement-preview.png`.
- Fontes de importação: `references/Pixel-Art Corporate Lobby Brawl Stage.png` e `references/Retro Pixel Action Hero Sprite Sheet.png`; ferramenta: `tools/art/import_reference_art.gd`.
- Logs locais: `/tmp/ruptura-043-{art-import,import,check,preview,movement,animation,integrity,comparison,export}.log` e `reports/portable-043-intel.log`.
- Binário0.4.2 preservado em `builds/archive/ruptura-0.4.2.x86_64`; pacote anterior mantido.

Aceite visual, conforto em controle físico, diversão/balanceamento, audição e desempenho prolongado continuam pendentes. Não houve aprovação dos gates humanos, produção de outros capítulos ou validação Windows.
