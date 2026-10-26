# Cinzas — recorte jogável0.4

Esta build expande a missão de prototipação com três setores e Chacal. É um candidato para playtest da slice, sem aprovação de diversão, estética, duração ou compatibilidade prolongada. A produção dos outros capítulos continua fora deste ciclo.

## Fluxo

| Estágio | Setor e objetivo | Checkpoint/recompensa |
|---|---|---|
|0|Arquivo Morto: enfrentar um recruta protegido|Vida e armamento repostos ao limpar|
|1|Arquivo Morto: combinar recruta/batedor; rota alta opcional|Espingarda temporária no percurso; saída manual no portão leste|
|2|Operações: três ameaças, alturas e coberturas|Checkpoint do novo setor com espingarda disponível|
|3|Operações: defesa do acesso ao conselho|Saída manual no portão leste; checkpoint antes da Chacal|
|4|Conselho: Chacal em duas fases|Vitória confirmada; espingarda e acesso aos registros|
|5|Pós-chefe: recolher prova e transmitir|Prova obrigatória persistida antes da transmissão|
|6|Desfecho: trabalhadores interrompem as cargas|Conclusão salva; repetir missão ou voltar ao laboratório|

O checkpoint do setor seguinte é registrado assim que a área anterior fica segura. É possível continuar explorando e sair com E/↑ no portão; fechar o jogo ou usar retry nessa situação retoma diretamente o próximo setor. Morte durante uma tentativa reconstrói inimigos/objetos e restaura a receita de recursos, sem persistir dano parcial do chefe. Documentos opcionais e contagem de mortes permanecem.

As rotas altas oferecem suprimentos e dois registros: atas restritas de execuções e contratos de trabalho compulsório. Chegue perto do documento e pressione E/↑. Ambos são opcionais; encontrar um recupera recursos e registra a descoberta, sem conceder a recompensa novamente no retry. Não são necessários para o final.

## Chacal

420HP, fase2 aos50%, com dano e cadência reforçados na0.4. Até três padrões: avanço horizontal, rajada de direção travada e salto com onda no chão na segunda fase. Os avisos antecedem os ataques; subir, recuar e esquivar são contramedidas diferentes. Cada padrão aceita no máximo um contato de dano no jogador.

A recuperação aumenta o dano recebido em40%. O avanço danifica a cobertura atingida e termina em recuperação; barris podem reagir e quebrar a postura. Explosões fortes atordoam por0,9s com cooldown3s; o golpe do jogador não permite stun infinito. A onda do salto permanece no piso anunciado, mesmo sob passarelas. A vida e fase são restauradas integralmente no retry anterior ao confronto.

## Apresentação e controles

Os setores usam desenhos originais de fundo, materiais e módulos corporativos com paletas distintas; não há assets de referências nem luzes dinâmicas caras. HUD apresenta objetivo, cooldown da esquiva, vida do chefe/fase, rádio e resumo da missão. A introdução é um rádio curto com movimento disponível. O final mostra a recusa coletiva das ordens e figuras de trabalhadores junto ao transmissor.

Opções: volume, modo assistido aplicado no próximo retry, presets de salto A/LB, deadzone radial0,1–0,35, assistência de mira opcional só no controle, efeitos reduzidos e tremor de câmera desativado por padrão. A assistência corrige levemente a direção dentro de7°, até360px, com linha de visão; não curva tiros nem se aplica ao mouse. Efeitos reduzidos encurtam tracers, reduzem fragmentos e suprimem o flash do jogador, preservando avisos de perigo.

A arquitetura, schemas e limites estão em [ARCHITECTURE](ARCHITECTURE.md), [COMBAT_RULES](COMBAT_RULES.md) e [PERFORMANCE](PERFORMANCE.md). Ainda faltam playtest humano, gamepad físico, audição e medição longa no pacote. Não há duração mínima prometida para este recorte.

Na0.4, a mira padrão do controle acompanha o analógico esquerdo. A opção de mira independente no direito permite recuo e tiro em direções diferentes; a assistência de alvos continua separada e opcional. Espectro era executivo, aspirava a uma diretoria e foi descartado quando recusou as ordens. Essa atualização está registrada no GDDv1.3.
