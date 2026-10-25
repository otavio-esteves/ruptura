# Regras de combate0.2

- Pistola:24 de dano, pente12, reserva72, intervalo0,22s, recarga1s, alcance800px. Espingarda:cinco pellets de10, pente6/reserva24, intervalo0,65s, recarga1,5s, alcance420px. Pellets no mesmo alvo são agregados em um acerto. Tiro pode ser mantido; não há projétil físico.
- O raio entre ombro e boca da arma bloqueia tiros cujo cano atravessaria cobertura. Raios incluem cenário, atores e props; chão/plataformas também obstruem. Disparo bloqueado ainda consome munição.
- Recarga transfere o total necessário uma única vez ao completar. Esquiva, morte, pause ou troca de arma cancelam antes dessa transferência. Golpe cancela recarga, aplica24 e empurra em alcance35px, com recuperação0,45s e LOS. Não há ataque forte/desarme.
- Esquiva dura0,28s, com proteção de0,15s no trecho central; recuperação fica vulnerável. Cooldown posterior0,65s. Dano aceito concede0,55s de proteção; impulso ocupa o controle horizontal por no máximo0,12s. Dano não acumula stun indefinidamente.
- Recruta tem55HP, prepara tiro por0,8s e recupera1,1s; batedor tem40HP, prepara golpe por0,45s e recupera1s. Dano8/12 respectivamente. Direção de ataque fica travada durante aviso. Interrupção por impulso>=80 dura0,16s, com proteção contra stun repetido por0,45s. Sem dano contínuo só por tocar inimigos.
- Caixa45HP, barril25HP, vidro8HP. Barril explode em raio110px com dano65 e queda por distância (mínimo35%). LOS é calculada antes de aplicar qualquer dano daquela onda; destruir cobertura não faz a mesma onda atravessá-la. Cada entidade recebe uma aplicação por explosão; cadeias são diferidas, com efeitos de0,38s e no máximo64 alvos/evento. A proteção do jogador também se aplica às ondas.
- Cada área limpa fornece checkpoint com vida100 e armamento cheio. Estágios0/1 começam de pistola; estágio2 em diante dispõe também de espingarda. Pickups de munição/vida e arma reaparecem na reconstrução. Não persistimos a tentativa parcialmente concluída ou poses de objetos.

Valores são hipóteses iniciais para playtest. Explosão, golpes e tiros já têm regressões automatizadas; conforto, justiça dos encontros e disponibilidade de recursos ainda precisam ser observados jogando.
