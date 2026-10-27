# Alvo visual — referências fornecidas por Otávio

Pedido de26/10/2026: aproximar o jogo do nível de acabamento das duas imagens em `references/`, seguindo-as de perto. Esta folha descreve a comparação visual; não substitui o GDD, não amplia a campanha e não aprova gates de arte, diversão ou desempenho.

Fontes de observação: `Pixel-Art Corporate Lobby Brawl Stage.png`, `Retro Pixel Action Hero Sprite Sheet.png`, capturas sucessivas em `reports/reference-review/` e prancha `reports/pixel-art-sheet.png`. As notas abaixo distinguem a0.4.1 e as rodadas da0.4.2; esses caminhos de revisão são atualizados pela ferramenta. A procedência das referências não foi informada. Elas permanecem material de direção, sem distribuição no pacote; os assets implementados devem ter autoria documentada.

## O que define o alvo

O cenário de referência parece um escritório construído e ocupado: concreto/argamassa, metal, vidro, couro e madeira têm bordas, espessura e resposta à luz próprias. As janelas mostram vários planos da cidade, persianas e reflexos discretos. O teto e as luminárias fazem parte do enquadramento; móveis e objetos ocupam a faixa média. Plantas, papéis, manchas e impactos quebram a repetição sem cobrir toda a superfície. O piso tem profundidade e junta coerente, com a borda de circulação inequívoca.

O personagem usa uma silhueta angular e atlética: cabelo irregular volumoso, rosto em perfil/três quartos, ombros e antebraços com volume, paletó aberto, camisa e gravata visíveis, quadril articulado e botas grandes. O terno escuro tem planos de sombra, luz fria discreta e bordas quentes; rasgos formam acentos selecionados. Os sprites mostram transferência de peso e compressão, além de deslocamento de pernas. O corpo não se resume a retângulos com decoração interna.

## Lacunas da0.4.1, em ordem de impacto

1. **Composição e escala da arquitetura.** Nas capturas, janelas quase vazias tomam a maior parte da área. As mesas foram reduzidas à escala dos atores, mas isso fez a arquitetura parecer ainda maior. Aumentar móveis novamente não resolve: é preciso reduzir a altura percebida do recinto por pavimentos, travessas, mezaninos, persianas e teto visível. A referência oferece um recinto de escala humana e uma faixa ocupada contínua.
2. **Volume e identidade dos atores.** Espectro ainda tem rosto arredondado e corpo estreito; recruta e Chacal conservam cabeça/torso de blocos. A nova densidade precisa ser redesenhada com anatomia, contornos e roupa; interpolar ou duplicar os pixels existentes não cria acabamento.
3. **Materiais e luz.** Grandes áreas de cor lisa, bordas de espessura uniforme e poucas cores por objeto deixam cenário e atores planos. O alvo usa luz motivada por luminárias, reentrâncias escuras e espessura das peças. A luz deve estar pintada no asset, preservando custo e contraste.
4. **Integração entre camadas.** Um fundo mais detalhado fará plataformas metálicas, props e atores antigos parecerem sobrepostos de outro jogo. Passarelas precisam parecer parte da arquitetura corporativa, com apoio plausível, material compatível e topo funcional visível. Props destrutíveis devem ter a mesma densidade artística e continuar distintos do mobiliário não interativo.
5. **Variação com intenção.** A repetição regular dos vãos, mesas e cadeiras é muito evidente. Alterar conjuntos de objetos, desgaste e pontos de luz cria ritmo; ruído uniforme em todas as superfícies enfraquece esse resultado.
6. **Enquadramento/HUD.** Barras opacas e texto persistente ocupam cerca de um terço da altura da captura0.4.1. A faixa útil fica estreita e exclui teto/iluminação. A composição deve ser revista no jogo completo, com o HUD presente, sem avaliar apenas o fundo isolado.

## Decisões técnicas a conferir na integração

- Viewport1280×720 com câmera2× mantém o mesmo campo de640×360 unidades do mundo. Essa troca permite mostrar um pixel novo a cada0,5unidade, mas não aumenta o tamanho aparente do personagem: é aumento de resolução de autoria, não zoom artístico. Não declarar resolvida a composição só por alterar esses números.
- Atlas2× deve conservar retângulo lógico, pés e pivôs; braço, arma, cano físico e retículo precisam continuar concordando em oito direções. A arma que parece deslocada do ombro em um único quadrante já invalida o acabamento dessa pose.
- Cenário pintado precisa alinhar o piso em y620 e respeitar a geometria existente. Corrimão, bancada ou piso desenhado sem colisão pode prometer uma interação inexistente. A referência é majoritariamente horizontal, enquanto Cinzas tem rotas altas: usar arquitetura em níveis para compatibilizar essa diferença sem esconder a rota.
- Texturas densas devem ser lidas na resolução de jogo. Arquitetura detalhada não pode desaparecer numa redução excessiva, ganhar serrilhado irregular ou usar pixel aparente muito menor que o personagem.
- As imagens em `references/` e `reports/` são ignoradas pela importação. Ferramentas de comparação devem abri-las por `Image.load()`/`ImageTexture`, sem transformá-las em dependências exportadas.

## Roteiro de revisão visual

Inspecionar lado a lado a referência e capturas novas do Arquivo, Operações e Conselho. Repetir a comparação em enquadramento de jogo e em recortes com ator e mesa em alturas semelhantes. Exibir a captura inteira antes de ampliar; uma prancha ampliada pode mascarar que o ator é pequeno ou que a luz está fora da câmera.

| Área | Evidência procurada | Motivo para outra revisão |
|---|---|---|
| Espectro parado | Cabelo, nariz/mandíbula, camisa, gravata, lapelas, mãos e pés legíveis | Cabeça circular sem perfil, roupa monocromática, braços em linha reta |
| Corrida | Oito poses com apoio/passagem/extensão, inclinação e abas do paletó coerentes | Pernas apenas deslocadas, pé escorregando, corpo inteiro imóvel |
| Salto/agachar/esquiva | Silhuetas e distribuição de peso reconhecíveis sem efeitos | Corpo apenas rebaixado ou achatado, mãos separadas da arma |
| Mira | Cano e mãos coerentes nas oito direções, recuo curto | Punhos desconectados, suporte atravessando rosto/torso |
| Guarda e chefe | Materiais e nível de detalhe compatíveis com Espectro | Cabeça/quadril retangulares e armadura sem forma |
| Recinto | Teto/luz/parede/objetos/piso compõem uma altura humana | Campo dominado por janela vazia e móvel minúsculo na base |
| Materiais | Madeira, concreto, vidro, tecido e metal distintos pela forma e valores | Mesmo contorno, mesma textura e mesma luz em tudo |
| Cena em combate | Terno, cobertura, retículo e avisos lidos imediatamente | Fundo ganha mais contraste que atores e telegraphs |
| Rotas altas | Passarelas parecem construção do mesmo escritório | Placas flutuantes ou plataformas industriais sem apoio |
| Repetição | Trechos têm agrupamentos e marcas próprias | Mesmos módulos repetidos com ruído aleatório |

Ver o ciclo em movimento, em passos de30/60FPS e com efeitos reduzidos. A prancha só facilita a inspeção; nenhum desses itens é teste automatizado de qualidade. Aproximar o estilo e melhorar bastante o resultado não equivale, por si só, a atingir o acabamento da referência. Registrar lacunas remanescentes com exemplos concretos, sem substituir a comparação por uma contagem de testes de lógica.

## Primeira revisão renderizada da0.4.2

As primeiras capturas novas do Arquivo, Operações e Conselho e a prancha de atores foram inspecionadas. Há um salto claro em relação à0.4.1: o térreo agora tem materiais, volumes, iluminação quente/fria, desgaste selecionado e objetos com escala coerente. O teto e as luminárias entram no quadro, e o HUD reduzido deixa a arquitetura respirar. Os atores têm rosto em perfil, roupa articulada, mãos e pernas mais definidas; inimigos já compartilham o nível de detalhe do protagonista. Esses avanços corrigem as maiores limitações de resolução da versão anterior.

Esta primeira composição ainda não atinge o acabamento integrado da referência. O térreo detalhado é separado dos pavimentos altos por grandes áreas cinza; salas superiores parecem caixas recortadas e as plataformas claras continuam lendo como prateleiras sobrepostas. A solução prioritária é uma arquitetura contínua: pilares atravessando níveis, caixilhos alinhados, teto/rodapé/estrutura das passarelas ligados a esses apoios. Preencher o vazio com outra textura repetida não basta.

A repetição do mesmo conjunto de recepção, quadro, luminária e máquina de vendas já é perceptível numa única captura. Usar trechos maiores e variantes, ou posicionar pilares e transições nas emendas, preservando agrupamentos próprios por setor. O Conselho precisa manter identidade distinta do Arquivo; os dois não devem parecer o mesmo hall com emblemas diferentes.

A faixa sólida abaixo do piso pintado continua muito plana e esverdeada. Ela precisa concordar com a pedra, rodapé e valores do bitmap, com contato dos pés e topo físico inequívocos. A textura pintada não deve oferecer uma segunda linha de chão ambígua nem deslocar o personagem em profundidade aparente.

Na prancha de atores, apoio e corrida continuam mais eretos e estreitos que a referência. A passagem das pernas está visível, mas quadril, tórax e cabeça ainda mudam pouco de intenção; a referência usa avanço do peito/quadril, joelho comprimido e contrapeso. Aumentar a inclinação e a abertura da silhueta em poses específicas pode aproximar o gesto sem alterar a velocidade física. Agachar e esquiva precisam mostrar compressão dos membros, não só cabeça rebaixada. Essas poses estavam em revisão na integração; confirmar novamente após a próxima geração e observar o ciclo em movimento.

O que falta verificar na próxima rodada: ambiente alto sem colagem, emendas menos óbvias, piso/material contínuo, pose comprimida de agachar/esquiva e transferência de peso na corrida. Nenhuma conclusão sobre movimento completo ou conforto foi tirada apenas das imagens estáticas.

## Segunda revisão estática da0.4.2

Inspecionados `archive.png`, `archive-upper-route.png`, `operations.png`, `boardroom-warning.png` e a prancha atual com recarga. As críticas da primeira rodada sobre vazio cinza, salas recortadas, faixa sólida verde e Conselho igual ao Arquivo foram tratadas visivelmente. A arquitetura agora ocupa todo o campo em planos coerentes; o térreo tem acabamento e escala próximos da linguagem da referência, piso de pedra integrado e variações reconhecíveis por setor. O Conselho usa mesa e cadeiras contínuas em vez da recepção do Arquivo. Não é necessário transformar as rotas verticais existentes num único hall para preservar essa linguagem artística.

Em tamanho de jogo, Espectro e guardas se separam do mobiliário por contorno, rosto, camisa, mãos e postura; caixas, recursos e aviso da Chacal mantêm leitura funcional. A seta e a segunda fase do chefe são claras, e a recarga agora tem mãos/carregador e diferença visível entre apoio, agachado e movimento. Os sprites deixaram a construção em blocos da0.4.1. As poses comprimidas estão melhores; a prancha ainda não comprova timing de passos, fluidez ou contato durante transições, que precisam ser vistos na captura em movimento.

Há uma revisão tonal concreta a conferir: na captura da rota alta, as vergas horizontais do fundo têm linha clara contínua e podem parecer pisos transitáveis. A plataforma real se distingue pelo topo quente e maior volume, mas a borda do plano recuado ainda compete com esse sinal. Recuar/escurecer as bandas de fundo, reservando brilho de topo e massa estrutural para os apoios reais, evita prometer uma colisão inexistente sem alterar layouts ou física. Isso é uma questão de leitura; a geometria pode estar correta mesmo quando o desenho sugere outro apoio.

Fora essa possível ambiguidade dos apoios de fundo, não foi identificado outro bloqueador estático objetivo nas capturas revistas. A repetição de janelas e mobiliário persiste como linguagem modular, porém as mudanças de trecho e setor já reduzem o reinício óbvio da primeira versão. Essa conclusão registra inspeção visual local, não aceite humano do alvo, playtest de diversão ou aprovação de desempenho. Verificar novamente as vergas após a revisão tonal e assistir movimento/recarga no cenário antes de encerrar a integração.

## Ferramenta de pares

`tools/art/compare_references.gd` produz `reports/reference-comparison.png` em sessão gráfica. Mostra o panorama de referência, a captura atual e poses do renderer real junto do recorte do personagem de referência. Proporções das imagens são preservadas; as poses são aproximadas pela altura apenas na faixa de comparação. A ferramenta não carrega missão, input, áudio ou saves e não modifica as referências. Passar `-- --sector=operations` ou `-- --sector=boardroom` para trocar a captura. O integrador deve executá-la depois de gerar/importar os atlas e recapturar a missão.

## Integração retomada em27/10/2026

As passarelas agora reaproveitam recortes da pedra do próprio bitmap, com juntas e variação de material na mesma densidade do térreo. A testeira clara chapada foi substituída por uma face escura e consoles triangulares de aço com fixação aparente. Uma única linha quente de0,5unidade marca o topo físico, sem mudar retângulos, links de navegação ou colisores.

As faixas entre vãos decorativos perderam a aresta clara contínua e receberam sombra progressiva no fim do recorte. Recapturados térreo, rota alta, Operações e Conselho, incluindo aviso da segunda fase com efeitos reduzidos. Na inspeção dessas imagens, a passarela real se distingue das vergas recuadas por material, espessura, apoio e aresta. A composição continua modular e ainda exige aceite humano comparado às referências.

A animação APNG interrompida tinha54quadros, embora a pasta contivesse os160quadros completos da captura mais recente. Remontada a sequência inteira em12FPS,13,33s; quantidade, continuidade e duração foram conferidas. Inspeção de quadros da corrida, salto, esquiva e recarga parada/agachada/em movimento confirma poses e articulação de mãos/arma nas amostras. Inspeção de quadros não comprova fluidez, conforto ou resposta a30/60FPS; esses itens permanecem para avaliação jogável.
