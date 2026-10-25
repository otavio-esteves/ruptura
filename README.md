# RUPTURA

Build **0.2 — protótipo de combate**, em Godot4.7.2 stable, GDScript e Compatibility. Linux é o alvo primário. O [plano v1.2](PLANO_DESENVOLVIMENTO_RUPTURA_v1_1_REVISADO.md) continua como fonte de design.

## Jogar

```bash
./builds/linux/ruptura.x86_64
```

O executável tem os recursos embutidos e pode ser copiado para outra pasta. No menu, escolha **Continuar / jogar** ou **Nova missão**. Para abrir o projeto no editor, use `project.godot` com Godot4.7.2.

A missão curta contém três encontros: um recruta protegido por caixa, uma combinação com batedor e uma defesa do terminal. Avance para leste, elimine as ameaças, recolha os registros e pressione **E** perto do transmissor. Não há cronômetro obrigatório. A espingarda está no chão do pátio; caixas, vidros e barris podem ser destruídos. Barris ferem ambos os lados e podem explodir em cadeia. Recuar e subir pelas plataformas ajuda a mudar os ângulos.

Ao limpar uma área, vida e armamento são reabastecidos e o checkpoint é gravado. Morte oferece retry imediato; fechar/reabrir retoma o último checkpoint. O cenário transitório é reconstruído no retry. Concluir a transmissão mostra o resultado; F5 ou o botão permite repetir a missão.

| Ação | Teclado/mouse | Controle de referência Xbox |
|---|---|---|
| Mover | A/D ou setas | Analógico esquerdo |
| Correr | Ctrl | Clique no analógico esquerdo |
| Saltar | Espaço; soltar reduz altura | A; preset alternativo LB |
| Agachar / descer plataforma | S / S+Espaço | ↓ / ↓+salto |
| Esquivar | Shift | B |
| Mirar | Mouse | Analógico direito; mantém direção ao soltar |
| Atirar | Mouse esquerdo | RT |
| Golpear / empurrar | Mouse direito | RB |
| Recarregar | R | X |
| Trocar arma | 1/2/Q ou roda | Y ou → |
| Interagir | E | ↑ |
| Retomar checkpoint | F5 | Back ou botão na tela de morte |
| Menu / pause | Esc | Start |

F2 alterna salto A/LB; também há botão nas opções operável por controle. F3 alterna limite30/60FPS com física a60Hz; F4 mostra diagnóstico; F6 captura10s de frametimes após2s de aquecimento; F11 alterna tela cheia. Os atalhos de diagnóstico não substituem medição comparável.

Opções incluem volume, remapeamento das teclas de movimento/ações principais e modo assistido. A dificuldade é aplicada no próximo retry: avisos inimigos30% mais longos e dano inimigo42% do padrão, combinando modificadores explícitos de inimigo/jogador. O gamepad possui os dois presets de salto, mas ainda não tem remapeamento completo.

## Save e verificação

Checkpoint e preferências ficam separados em `user://checkpoint.json` e `settings.json`, normalmente `~/.local/share/godot/app_userdata/RUPTURA/`. Gravação usa temporário validado e backup do último arquivo válido. Corrupção tenta recuperar o backup; se ambos estiverem inválidos, a interface pede Nova missão e preserva os arquivos até essa escolha. Não há contas, backend ou conexão exigida para jogar.

```bash
python3 tools/validation/validate.py check
python3 tools/validation/validate.py export-linux
```

`GODOT_BIN` pode indicar outro caminho para a engine4.7.2. A suíte verifica movimento, munição, recarga, cobertura, dano, explosões, inimigos, navegação, save e fluxo do encontro. Fixtures de save usam diretórios isolados; não sobrescrevem o progresso real. Veja [PERFORMANCE](docs/PERFORMANCE.md), [arquitetura](docs/ARCHITECTURE.md) e [roteiro de playtest](docs/PLAYTEST.md).

Esta build é um recorte do Marco2. Arte e sons são provisórios e originais, ainda sem chefão/campanha. Conforto, balanceamento, controle físico, áudio audível e desempenho prolongado precisam de playtest. Windows tem apenas preset de preparação e não foi validado nativamente.
