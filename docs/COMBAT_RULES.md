# Regras vigentes0.4

A dificuldade padrão aumenta cadência, dano e mobilidade, preservando avisos/LOS/dano único e a vida anterior dos inimigos.

| Oponente | HP | Dano | Aviso | Recuperação | Velocidade |
|---|---:|---:|---:|---:|---:|
|Recruta|55|12|0,60s|0,85s|100px/s|
|Batedor|40|18|0,36s|0,75s|145px/s|

O recruta reposiciona na recuperação para manter160–240px do alvo e planta os pés nos últimos0,20s. Colisão física e sondagem de chão impedem atravessar paredes ou se jogar de passarelas nessa manobra. O ataque continua com direção travada e não atravessa cobertura.

Chacal mantém420HP e duas fases aos50%. Danos: avanço24, rajada18, onda30. Avisos:0,60/0,72/0,85s; recuperação0,85s ou1,10s no avanço bloqueado/onda. Cada padrão resolve um único contato de dano. Introdução1s, transição de fase0,8s e contrajogo por cobertura/barril/plataforma foram preservados.

No assistido, o aviso inimigo é multiplicado por1,45 e seu dano por0,7; o jogador também mantém redução0,6, resultando em42% do dano padrão. A seleção entra no próximo retry. Armas, munição, colisores, vida do jogador e janelas de esquiva não mudaram nesta revisão.

Mira por movimento: analógico esquerdo em360° com deadzone e retenção. Mira independente opcional: direito em360°, retido ao soltar. Nenhum dos modos altera a direção dos controles de movimento. Assistência leve de alvos é um parâmetro separado. Mouse mantém mira independente.

---

# Histórico — regras de combate0.2

- Pistola:24 de dano, pente12, reserva72, intervalo0,22s, recarga1s, alcance800px. Espingarda:cinco pellets de10, pente6/reserva24, intervalo0,65s, recarga1,5s, alcance420px. Pellets no mesmo alvo são agregados em um acerto. Tiro pode ser mantido; não há projétil físico.
- O raio entre ombro e boca da arma bloqueia tiros cujo cano atravessaria cobertura. Raios incluem cenário, atores e props; chão/plataformas também obstruem. Disparo bloqueado ainda consome munição.
- Recarga transfere o total necessário uma única vez ao completar. Esquiva, morte, pause ou troca de arma cancelam antes dessa transferência. Golpe cancela recarga, aplica24 e empurra em alcance35px, com recuperação0,45s e LOS. Não há ataque forte/desarme.
- Esquiva dura0,28s, com proteção de0,15s no trecho central; recuperação fica vulnerável. Cooldown posterior0,65s. Dano aceito concede0,55s de proteção; impulso ocupa o controle horizontal por no máximo0,12s. Dano não acumula stun indefinidamente.
- Recruta tem55HP, prepara tiro por0,8s e recupera1,1s; batedor tem40HP, prepara golpe por0,45s e recupera1s. Dano8/12 respectivamente. Direção de ataque fica travada durante aviso. Interrupção por impulso>=80 dura0,16s, com proteção contra stun repetido por0,45s. Sem dano contínuo só por tocar inimigos.
- Caixa45HP, barril25HP, vidro8HP. Barril explode em raio110px com dano65 e queda por distância (mínimo35%). LOS é calculada antes de aplicar qualquer dano daquela onda; destruir cobertura não faz a mesma onda atravessá-la. Cada entidade recebe uma aplicação por explosão; cadeias são diferidas, com efeitos de0,38s e no máximo64 alvos/evento. A proteção do jogador também se aplica às ondas.
- Cada área limpa fornece checkpoint com vida100 e armamento cheio. Estágios0/1 começam de pistola; estágio2 em diante dispõe também de espingarda. Pickups de munição/vida e arma reaparecem na reconstrução. Não persistimos a tentativa parcialmente concluída ou poses de objetos.

Valores são hipóteses iniciais para playtest. Explosão, golpes e tiros já têm regressões automatizadas; conforto, justiça dos encontros e disponibilidade de recursos ainda precisam ser observados jogando.

## Acrescentado na0.3

Chacal e progressão de Cinzas estão descritas em [CINZAS](CINZAS.md). A arena do laboratório mantém as regras0.2. A missão tem checkpoints próprios: shotgun_unlocked registra pickup e acompanha os checkpoints posteriores, enquanto uma nova missão começa do zero. Documentos opcionais persistem na mesma tentativa de missão e não concedem recompensa repetida no retry. A conclusão depende somente da prova obrigatória, chefão e transmissor.

A assistência opcional corrige até22% da diferença angular para um alvo visível dentro de7°/360px. Não altera raycasts ou aplica correção ao mouse. Deadzone é configurável entre0,1 e0,35; direção válida permanece ao centralizar. Nenhum dos novos parâmetros foi aprovado por teste físico de gamepad.
