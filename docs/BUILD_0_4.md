# Build0.4 — executivo e direção corporativa

Data:26/10/2026. Fontes: `21b7780d27e5687df047c92c6bcaa59e4bb2ae27`. Godot4.7.2 stable, Compatibility, Linux x86_64.

## Resultado

Conforme confirmação do usuário, o esquerdo move e orienta a mira radial por padrão; o direito oferece mira independente pela opção persistida “Mira independente no direito”. A última direção fica retida ao centralizar. Mouse e assistência de mira permanecem separados dessa opção. Arquivos antigos assumem a opção desligada.

Espectro agora é um executivo de terno preto, antes aspirante a diretor. Atlas originais receberam camisa clara, gravata, lapelas, rosto, cabelo e sapatos. Os três setores são arquivo corporativo, operações e conselho, com mobiliário, vidro, persianas e paleta escura que preserva contraste do jogador, retículo e avisos. Geometria e colisores foram preservados. Referências e autoria: [ART_DIRECTION](ART_DIRECTION.md); premissa vigente no GDDv1.3.

Recruta e batedor mantêm55/40HP; Chacal mantém420HP. Maior pressão vem de mobilidade, cadência e dano. Recruta reposiciona durante recuperação com verificação de chão. Chefe mantém duas fases, avisos e recuperação vulnerável; modo assistido mantém reduções e avisos ampliados. Valores: [COMBAT_RULES](COMBAT_RULES.md).

## Verificação

- Suíte completa:829 verificações aprovadas, sem erros ou avisos no log; inclui controles, persistência e dificuldade.
- Importação e exportação Linux concluídas sem erros/avisos; oito atlas incluídos.
- Capturas gráficas dos setores, menu e chefe inspecionadas; cenário corporativo escuro e protagonista legível.
- Movimento capturado pelo controlador real:109frames a12FPS, APNG sem reamostragem. Captura roteirizada isolada de saves; não equivale a playtest.
- Executável iniciado fora do projeto em `/tmp/ruptura-corporate-release/`, por180frames: saída0, escrita em user:// confirmada, Radeon R7M260/Compatibility; sem erros no log.
- Tar conferido: hash do executável e manifesto coincidem, permissão executável e três prévias presentes.

## Artefatos

- `builds/linux/ruptura.x86_64`:73698968bytes; SHA-256 `130acc62b6f6d5ad305bf9c7aec18cefc8d6461d5659875b0e8d50f804303609`.
- `builds/ruptura-0.4-linux-x86_64.tar.gz`:29267655bytes; SHA-256 `e355f95a4741902f2e910a18af39523d9ff1f2405a992f4d357775c89c02e1e1`.
- `reports/corporate-archive.png`: captura do arquivo; `reports/pixel-art-sheet.png`: prancha; `reports/movement-preview.png`: animação APNG.
- Executável anterior preservado em `builds/archive/ruptura-0.3.1.x86_64`.

Conforto em gamepad físico, balanceamento por playtest humano, aceite artístico e benchmark prolongado seguem pendentes. Não há aprovação nova de desempenho, publicação externa ou assets pagos neste incremento.
