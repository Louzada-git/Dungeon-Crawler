# Balanço de combate

Revisão de 15/10/2026, depois do teste do dono do projeto com amigos:

- **Fôlego** (Bruno): todos os gastos pela metade (armas, objetos, talentos, esquiva, corrida, guarda) e recuperação 1,3× mais rápida. Regras em `data/proficiencias.json`, seção `folego`.
- **Delay** (Pedro, com o martelo): o corte geral para um terço tirava quase todo o delay. Agora cada arma tem o seu, pelo peso (`classe` em `data/itens.json`). As leves perderam cerca de um terço do delay que tinham antes do teste; as médias, cerca de 30%; as pesadas, só 10 a 15%. A esquiva volta na metade do delay depois do golpe.
- **Atordoamento em cadeia:** cada golpe atordoava e cancelava o ataque do monstro, e com golpes rápidos (ou o martelo sem delay) o monstro nunca atacava. Agora, depois de atordoado, o monstro fica firme por um tempo (`firmeza` em `data/inimigos.json`): os golpes ainda ferem, mas não cancelam o ataque. É preciso esquivar ou segurar na guarda.
- **Delay do peso** (pedido do Pedro, regra do dono do projeto): depois do golpe, cada kg da arma soma 0,1 s antes do próximo golpe (martelo, 6,5 kg: +0,65 s; espada, 2,4 kg: +0,24 s; soco conta como 1 kg). Esse tempo só impede golpear (e usar habilidades): o personagem anda normal e pode esquivar. Os danos foram reacertados depois disso, para as armas pesadas não perderem o lugar.
- **Danos:** as armas foram acertadas para um dano por segundo parecido, num alvo: de 24 a 33 com o delay do peso. Cada uma compensa o resto com outra vantagem: alcance (lanças, arco, besta), área (montante, martelo), sangramento (machado), armadura esmagada e atordoamento (maça, martelo) ou furtivo (adaga). Os monstros ganharam cerca de 25% de vida e um pouco de dano.

## Regras do tempo do golpe

- `windup` (preparo): do clique até o golpe acertar. Não mudou.
- `cooldown`: o golpe inteiro. Delay depois do golpe = `cooldown` − `windup`.
- Delay do peso: + `weight` × 0,1 s (`DungeonPlayer.DELAY_PER_KG`) até o próximo golpe, sem lentidão e sem travar a esquiva.
- Lentidão e trava de virar: 90% do `cooldown`.
- Esquiva: liberada em `windup` + metade do delay (`DungeonPlayer.DODGE_AFTER`). Esquivar corta a lentidão, mas o próximo golpe ainda espera o `cooldown`.
- A animação do golpe dura `windup` / `impacto`, para o golpe visível cair no fim do preparo.

## Tabela (domínio 1, sem talentos nem habilidades, monstros do 1º andar)

Gerada por `tools/tabela_balanco.py` a partir dos dados (rodar da pasta `jogo/`). "Ciclo" é do clique até poder golpear de novo, já com o delay do peso. "Esquiva" é quando ela volta, contando do clique. "Sem fim" quer dizer que o fôlego volta mais rápido do que o golpe gasta. "Seguidos" são quantos golpes um fôlego cheio aguenta sem parar. As colunas dos monstros dizem quantos golpes e quanto tempo até derrubar.

| Arma | Dano | Preparo | Ciclo | Esquiva | DPS | DPS blind. | Fôlego | Seguidos | Alvos | Corr. | Espr. | Guard. | Brut. | Chefe |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sword | 24 | 0.22 | 0.74 | 0.36 | 32 | 32 | 8.5 | 41 | 3 | 4 (2.4 s) | 3 (1.7 s) | 5 (3.2 s) | 8 (5.4 s) | 21 (15.0 s) |
| spear | 29 | 0.30 | 1.04 | 0.49 | 28 | 28 | 11.5 | 38 | 1 | 3 (2.4 s) | 2 (1.3 s) | 5 (4.5 s) | 7 (6.5 s) | 18 (18.0 s) |
| espada_guarda | 27 | 0.23 | 0.83 | 0.38 | 33 | 33 | 9.5 | 46 | 3 | 3 (1.9 s) | 2 (1.1 s) | 5 (3.6 s) | 7 (5.2 s) | 19 (15.2 s) |
| lanca_longa | 34 | 0.33 | 1.26 | 0.58 | 27 | 27 | 13.0 | 40 | 1 | 3 (2.9 s) | 2 (1.6 s) | 4 (4.1 s) | 6 (6.6 s) | 15 (18.0 s) |
| adaga | 10 | 0.12 | 0.38 | 0.21 | 26 | 26 | 4.5 | 45 | 1 | 8 (2.8 s) | 5 (1.6 s) | 12 (4.3 s) | 18 (6.6 s) | 50 (18.7 s) |
| katana | 17 | 0.16 | 0.52 | 0.27 | 33 | 33 | 8.5 | 21 | 2 | 5 (2.2 s) | 3 (1.2 s) | 8 (3.8 s) | 11 (5.4 s) | 30 (15.2 s) |
| montante | 47 | 0.45 | 1.59 | 0.75 | 30 | 30 | 15.0 | 72 | 4 | 2 (2.0 s) | 2 (2.0 s) | 3 (3.6 s) | 4 (5.2 s) | 11 (16.4 s) |
| machado | 22 | 0.26 | 0.85 | 0.41 | 31 | 26 | 9.0 | 50 | 2 | 4 (2.8 s) | 3 (2.0 s) | 6 (4.5 s) | 8 (6.2 s) | 23 (19.0 s) |
| maca | 27 | 0.26 | 0.92 | 0.43 | 29 | 44 | 9.5 | 63 | 1 | 3 (2.1 s) | 2 (1.2 s) | 3 (2.1 s) | 5 (3.9 s) | 13 (11.3 s) |
| martelo | 56 | 0.60 | 1.93 | 0.94 | 29 | 38 | 16.0 | sem fim | 6 | 2 (2.5 s) | 1 (0.6 s) | 2 (2.5 s) | 3 (4.5 s) | 7 (12.2 s) |
| alabarda | 36 | 0.34 | 1.38 | 0.61 | 26 | 26 | 12.5 | 371 | 2 | 3 (3.1 s) | 2 (1.7 s) | 4 (4.5 s) | 5 (5.9 s) | 14 (18.3 s) |
| arco | 18 | 0.35 | 0.75 | 0.49 | 24 | 24 | 5.0 | 84 | 1 | 5 (3.4 s) | 3 (1.9 s) | 7 (4.8 s) | 10 (7.1 s) | 28 (20.6 s) |
| besta | 43 | 0.25 | 1.80 | 0.82 | 24 | 24 | 4.0 | sem fim | 1 | 2 (2.0 s) | 2 (2.0 s) | 3 (3.8 s) | 5 (7.4 s) | 12 (20.0 s) |
| (punhos) | 8 | 0.14 | 0.44 | 0.24 | 18 | 18 | 4.0 | 82 | 1 | 10 (4.1 s) | 7 (2.8 s) | 15 (6.3 s) | 22 (9.4 s) | 63 (27.4 s) |

| Monstro | Vida | Dano | Preparo | Firmeza |
| --- | --- | --- | --- | --- |
| corrompido | 80 | 18 | 0.65 | 1.2 |
| guardiao | 120 | 26 | 0.85 | 1.6 |
| espreitador | 50 | 12 | 0.45 | 0.9 |
| brutamontes | 175 | 32 | 1.00 | 2.0 |
| chefe | 500 | 30 | 0.90 | — |

O chefe passou de 560 para 500 de vida depois do delay do peso. Por andar, os monstros ganham +30% de vida e +15% de dano. Cada nível de domínio dá +4% de dano e −2% de fôlego (até −30%).

## Ainda em aberto

- Os números são de planilha. Falta jogar de novo e ver se o 1º andar ficou no ponto, sem estar fácil nem frustrante.
- As armas pesadas ficaram com dano por segundo um pouco abaixo da espada num alvo só, porque acertam vários e atordoam. Se ainda parecerem fracas jogando, o primeiro ajuste é o dano delas.
