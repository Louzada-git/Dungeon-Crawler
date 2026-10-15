# Balanço de combate

Revisão de 15/10/2026, depois do teste do dono do projeto com amigos:

- **Fôlego** (Bruno): todos os gastos pela metade (armas, objetos, talentos, esquiva, corrida, guarda) e recuperação 1,3× mais rápida. Regras em `data/proficiencias.json`, seção `folego`.
- **Delay** (Pedro, com o martelo): o corte geral para um terço tirava quase todo o delay. Agora cada arma tem o seu, pelo peso (`classe` em `data/itens.json`). As leves perderam cerca de um terço do delay que tinham antes do teste; as médias, cerca de 30%; as pesadas, só 10 a 15%. A esquiva volta na metade do delay depois do golpe.
- **Atordoamento em cadeia:** cada golpe atordoava e cancelava o ataque do monstro, e com golpes rápidos (ou o martelo sem delay) o monstro nunca atacava. Agora, depois de atordoado, o monstro fica firme por um tempo (`firmeza` em `data/inimigos.json`): os golpes ainda ferem, mas não cancelam o ataque. É preciso esquivar ou segurar na guarda.
- **Danos:** as armas foram acertadas para um dano por segundo parecido, num alvo, de 35 a 49. Cada uma compensa o resto com outra vantagem: alcance (lanças, arco, besta), área (montante, martelo), sangramento (machado), armadura esmagada e atordoamento (maça, martelo) ou furtivo (adaga). Os monstros ganharam cerca de 25% de vida e um pouco de dano.

## Regras do tempo do golpe

- `windup` (preparo): do clique até o golpe acertar. Não mudou.
- `cooldown`: o golpe inteiro, do clique até poder golpear de novo. Delay depois do golpe = `cooldown` − `windup`.
- Lentidão e trava de virar: 90% do `cooldown`.
- Esquiva: liberada em `windup` + metade do delay (`DungeonPlayer.DODGE_AFTER`). Esquivar corta a lentidão, mas o próximo golpe ainda espera o `cooldown`.
- A animação do golpe dura `windup` / `impacto`, para o golpe visível cair no fim do preparo.

## Tabela (domínio 1, sem talentos nem habilidades, monstros do 1º andar)

Gerada por `tools/tabela_balanco.py` a partir dos dados (rodar da pasta `jogo/`). "Esquiva" é quando ela volta, contando do clique. "Seguidos" são quantos golpes um fôlego cheio aguenta sem parar. As colunas dos monstros dizem quantos golpes e quanto tempo até derrubar.

| Arma | Dano | Preparo | Ciclo | Esquiva | DPS | DPS blind. | Fôlego | Seguidos | Alvos | Corr. | Espr. | Guard. | Brut. | Chefe |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sword | 24 | 0.22 | 0.50 | 0.36 | 48 | 48 | 8.5 | 13 | 3 | 4 (1.7 s) | 3 (1.2 s) | 5 (2.2 s) | 8 (3.7 s) | 24 (11.7 s) |
| spear | 28 | 0.30 | 0.68 | 0.49 | 41 | 41 | 11.5 | 10 | 1 | 3 (1.7 s) | 2 (1.0 s) | 5 (3.0 s) | 7 (4.4 s) | 20 (13.2 s) |
| espada_guarda | 26 | 0.23 | 0.53 | 0.38 | 49 | 49 | 9.5 | 12 | 3 | 4 (1.8 s) | 2 (0.8 s) | 5 (2.4 s) | 7 (3.4 s) | 22 (11.4 s) |
| lanca_longa | 34 | 0.33 | 0.84 | 0.58 | 40 | 40 | 13.0 | 9 | 1 | 3 (2.0 s) | 2 (1.2 s) | 4 (2.9 s) | 6 (4.5 s) | 17 (13.8 s) |
| adaga | 12 | 0.12 | 0.30 | 0.21 | 40 | 40 | 4.5 | 26 | 1 | 7 (1.9 s) | 5 (1.3 s) | 10 (2.8 s) | 15 (4.3 s) | 47 (13.9 s) |
| katana | 18 | 0.16 | 0.38 | 0.27 | 47 | 47 | 8.5 | 13 | 2 | 5 (1.7 s) | 3 (0.9 s) | 7 (2.4 s) | 10 (3.6 s) | 32 (11.9 s) |
| montante | 46 | 0.45 | 1.04 | 0.75 | 44 | 44 | 15.0 | 8 | 4 | 2 (1.5 s) | 2 (1.5 s) | 3 (2.5 s) | 4 (3.6 s) | 13 (12.9 s) |
| machado | 23 | 0.26 | 0.57 | 0.41 | 45 | 40 | 9.0 | 13 | 2 | 4 (2.0 s) | 3 (1.4 s) | 6 (3.1 s) | 8 (4.2 s) | 25 (13.9 s) |
| maca | 26 | 0.26 | 0.60 | 0.43 | 43 | 65 | 9.5 | 12 | 1 | 4 (2.1 s) | 2 (0.9 s) | 4 (2.1 s) | 5 (2.7 s) | 15 (8.7 s) |
| martelo | 55 | 0.60 | 1.28 | 0.94 | 43 | 56 | 16.0 | 7 | 6 | 2 (1.9 s) | 1 (0.6 s) | 2 (1.9 s) | 3 (3.2 s) | 8 (9.6 s) |
| alabarda | 34 | 0.34 | 0.88 | 0.61 | 39 | 39 | 12.5 | 9 | 2 | 3 (2.1 s) | 2 (1.2 s) | 4 (3.0 s) | 6 (4.7 s) | 17 (14.4 s) |
| arco | 22 | 0.35 | 0.63 | 0.49 | 35 | 35 | 5.0 | 27 | 1 | 4 (2.2 s) | 3 (1.6 s) | 6 (3.5 s) | 8 (4.8 s) | 26 (16.1 s) |
| besta | 50 | 0.25 | 1.40 | 0.82 | 36 | 36 | 4.0 | 92 | 1 | 2 (1.6 s) | 1 (0.2 s) | 3 (3.0 s) | 4 (4.4 s) | 12 (15.6 s) |
| (punhos) | 8 | 0.14 | 0.34 | 0.24 | 24 | 24 | 4.0 | 30 | 1 | 10 (3.2 s) | 7 (2.2 s) | 15 (4.9 s) | 22 (7.3 s) | 70 (23.6 s) |

| Monstro | Vida | Dano | Preparo | Firmeza |
| --- | --- | --- | --- | --- |
| corrompido | 80 | 18 | 0.65 | 1.2 |
| guardiao | 120 | 26 | 0.85 | 1.6 |
| espreitador | 50 | 12 | 0.45 | 0.9 |
| brutamontes | 175 | 32 | 1.00 | 2.0 |
| chefe | 560 | 30 | 0.90 | — |

Por andar, os monstros ganham +30% de vida e +15% de dano. Cada nível de domínio dá +4% de dano e −2% de fôlego (até −30%).

## Ainda em aberto

- Os números são de planilha. Falta jogar de novo e ver se o 1º andar ficou no ponto, sem estar fácil nem frustrante.
- As armas pesadas ficaram com dano por segundo um pouco abaixo da espada num alvo só, porque acertam vários e atordoam. Se ainda parecerem fracas jogando, o primeiro ajuste é o dano delas.
