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

## Acerto por toque (16/10/2026)

O golpe corpo a corpo deixou de ser uma área. Agora ele acerta quem a arma toca: a arma (ou o punho) é uma cápsula da empunhadura até a ponta do modelo, que segue a animação do golpe, e cada corpo é uma cápsula em pé. No momento do impacto o jogo repassa o movimento um pouco antes e um pouco depois e acerta quem a cápsula atravessou, na ordem em que tocou. O preparo atrás das costas não conta. Código em `scripts/systems/hitbox.gd`.

- **Alcance** de cada arma corpo a corpo é o que a ponta alcança no movimento, medido por `tools/medir_alcance.gd` e gravado em `range`. Ficou menor que os números antigos, que eram de uma área: a espada foi de 2,1 para 1,5 m, a lança de 3,2 para 2,4 m, o machado de 1,9 para 1,1 m. Contra um monstro, some o raio do corpo dele (0,4 m nos comuns).
- **Alvos** continua sendo o máximo por golpe, mas só conta quem a arma toca. A marreta acerta quem estiver onde a cabeça desce, não um círculo de 1,6 m.
- **Habilidades e talentos:** Braço longo e o talento Alcance esticam a ponta; Meia-lua e Varredura fazem o golpe contar por um trecho maior do movimento; Estrondo e Tremor engrossam a cabeça da marreta; o Corte giratório leva a lâmina à volta inteira.
- **Monstros** acertam com a garra (antebraço até além da mão) na animação de ataque, e se jogam para a frente no golpe (`lunge`, coluna "Bote"). Isso leva o toque até perto da distância em que decidem atacar (`reach`, coluna "Ataca a"). Recuar durante o preparo escapa. O capataz atacava a 2,4 m e passou para 2,2 m, com bote de 0,75 m. A pancada dele continua em área, avisada pelo anel vermelho.
- O sabre tinha o impacto marcado cedo demais (a lâmina passava atrás do ombro). O impacto foi para o momento em que a lâmina cruza a frente.
- **Pegada nova (17/10/2026):** a arma passou para dentro da mão fechada e as armas de duas mãos e as hastes ganharam jeito próprio de carregar. Os alcances foram medidos de novo e mudaram no máximo 0,1 m: adaga, faca e punhal 0,8 m; pique 2,8 m; sabre 2,0 m; montante 2,0 m; alfanje 1,5 m; machado de duas lâminas 1,6 m; picareta 1,3 m; foice 1,8 m (agora com a ceifada própria). A adaga ganhou uma estocada curta (o soco deixava a lâmina para cima) e a maça passa na frente com o braço esticado, para acertar o monstro logo à frente.

## Tabela (domínio 1, sem talentos nem habilidades, monstros do 1º andar)

Gerada por `tools/tabela_balanco.py` a partir dos dados (rodar da pasta `jogo/`). "Alcance" é o da hitbox nas armas corpo a corpo e o do disparo nas de longe. "Ciclo" é do clique até poder golpear de novo, já com o delay do peso. "Esquiva" é quando ela volta, contando do clique. "Sem fim" quer dizer que o fôlego volta mais rápido do que o golpe gasta. "Seguidos" são quantos golpes um fôlego cheio aguenta sem parar. As colunas dos monstros dizem quantos golpes e quanto tempo até derrubar.

| Arma | Dano | Alcance | Preparo | Ciclo | Esquiva | DPS | DPS blind. | Fôlego | Seguidos | Alvos | Corr. | Espr. | Guard. | Brut. | Chefe |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sword | 24 | 1.5 | 0.22 | 0.74 | 0.36 | 32 | 32 | 8.5 | 41 | 3 | 4 (2.4 s) | 3 (1.7 s) | 5 (3.2 s) | 8 (5.4 s) | 21 (15.0 s) |
| spear | 29 | 2.4 | 0.30 | 1.04 | 0.49 | 28 | 28 | 11.5 | 38 | 1 | 3 (2.4 s) | 2 (1.3 s) | 5 (4.5 s) | 7 (6.5 s) | 18 (18.0 s) |
| espada_guarda | 27 | 1.5 | 0.23 | 0.83 | 0.38 | 33 | 33 | 9.5 | 46 | 3 | 3 (1.9 s) | 2 (1.1 s) | 5 (3.6 s) | 7 (5.2 s) | 19 (15.2 s) |
| lanca_longa | 34 | 2.8 | 0.33 | 1.26 | 0.58 | 27 | 27 | 13.0 | 40 | 1 | 3 (2.9 s) | 2 (1.6 s) | 4 (4.1 s) | 6 (6.6 s) | 15 (18.0 s) |
| adaga | 10 | 0.8 | 0.12 | 0.38 | 0.21 | 26 | 26 | 4.5 | 45 | 1 | 8 (2.8 s) | 5 (1.6 s) | 12 (4.3 s) | 18 (6.6 s) | 50 (18.7 s) |
| katana | 17 | 2.0 | 0.16 | 0.52 | 0.27 | 33 | 33 | 8.5 | 21 | 2 | 5 (2.2 s) | 3 (1.2 s) | 8 (3.8 s) | 11 (5.4 s) | 30 (15.2 s) |
| montante | 47 | 2.0 | 0.45 | 1.59 | 0.75 | 30 | 30 | 15.0 | 72 | 4 | 2 (2.0 s) | 2 (2.0 s) | 3 (3.6 s) | 4 (5.2 s) | 11 (16.4 s) |
| machado | 22 | 1.1 | 0.26 | 0.85 | 0.41 | 31 | 26 | 9.0 | 50 | 2 | 4 (2.8 s) | 3 (2.0 s) | 6 (4.5 s) | 8 (6.2 s) | 23 (19.0 s) |
| maca | 27 | 1.0 | 0.26 | 0.92 | 0.43 | 29 | 44 | 9.5 | 63 | 1 | 3 (2.1 s) | 2 (1.2 s) | 3 (2.1 s) | 5 (3.9 s) | 13 (11.3 s) |
| martelo | 56 | 1.7 | 0.60 | 1.93 | 0.94 | 29 | 38 | 16.0 | sem fim | 6 | 2 (2.5 s) | 1 (0.6 s) | 2 (2.5 s) | 3 (4.5 s) | 7 (12.2 s) |
| alabarda | 36 | 2.5 | 0.34 | 1.38 | 0.61 | 26 | 26 | 12.5 | 371 | 2 | 3 (3.1 s) | 2 (1.7 s) | 4 (4.5 s) | 5 (5.9 s) | 14 (18.3 s) |
| arco | 18 | 14.0 | 0.35 | 0.75 | 0.49 | 24 | 24 | 5.0 | 84 | 1 | 5 (3.4 s) | 3 (1.9 s) | 7 (4.8 s) | 10 (7.1 s) | 28 (20.6 s) |
| besta | 43 | 16.0 | 0.25 | 1.80 | 0.82 | 24 | 24 | 4.0 | sem fim | 1 | 2 (2.0 s) | 2 (2.0 s) | 3 (3.8 s) | 5 (7.4 s) | 12 (20.0 s) |
| espada_curta | 20 | 1.3 | 0.19 | 0.62 | 0.32 | 32 | 32 | 7.0 | 43 | 2 | 4 (2.0 s) | 3 (1.4 s) | 6 (3.3 s) | 9 (5.2 s) | 25 (15.1 s) |
| espada_larga | 30 | 1.6 | 0.25 | 0.92 | 0.41 | 33 | 33 | 10.5 | 45 | 3 | 3 (2.1 s) | 2 (1.2 s) | 4 (3.0 s) | 6 (4.8 s) | 17 (15.0 s) |
| florete | 18 | 1.6 | 0.17 | 0.51 | 0.29 | 35 | 35 | 7.0 | 26 | 1 | 5 (2.2 s) | 3 (1.2 s) | 7 (3.2 s) | 10 (4.8 s) | 28 (13.9 s) |
| alfanje | 18 | 1.5 | 0.17 | 0.56 | 0.29 | 34 | 32 | 8.0 | 26 | 2 | 5 (2.4 s) | 3 (1.3 s) | 7 (3.5 s) | 10 (5.2 s) | 28 (15.3 s) |
| espadao | 52 | 1.9 | 0.48 | 1.72 | 0.79 | 30 | 30 | 16.0 | 123 | 4 | 2 (2.2 s) | 1 (0.5 s) | 3 (3.9 s) | 4 (5.6 s) | 10 (16.0 s) |
| faca | 8 | 0.8 | 0.10 | 0.30 | 0.18 | 27 | 27 | 3.5 | 47 | 1 | 10 (2.8 s) | 7 (1.9 s) | 15 (4.3 s) | 22 (6.4 s) | 63 (18.7 s) |
| punhal | 12 | 0.8 | 0.13 | 0.39 | 0.23 | 33 | 31 | 5.0 | 35 | 1 | 7 (2.5 s) | 5 (1.7 s) | 10 (3.6 s) | 15 (5.6 s) | 42 (16.1 s) |
| maca_cravos | 25 | 1.1 | 0.26 | 0.94 | 0.43 | 30 | 37 | 9.5 | 85 | 1 | 4 (3.1 s) | 2 (1.2 s) | 4 (3.1 s) | 5 (4.0 s) | 15 (13.4 s) |
| estrela | 35 | 1.2 | 0.32 | 1.21 | 0.55 | 29 | 43 | 12.0 | 70 | 2 | 3 (2.7 s) | 2 (1.5 s) | 3 (2.7 s) | 4 (3.9 s) | 10 (11.2 s) |
| malho | 70 | 1.8 | 0.72 | 2.50 | 1.14 | 28 | 39 | 19.0 | sem fim | 7 | 2 (3.2 s) | 1 (0.7 s) | 2 (3.2 s) | 2 (3.2 s) | 6 (13.2 s) |
| martelo_guerra | 40 | 1.5 | 0.42 | 1.33 | 0.69 | 30 | 42 | 12.0 | 47 | 4 | 2 (1.8 s) | 2 (1.8 s) | 3 (3.1 s) | 4 (4.4 s) | 9 (11.1 s) |
| machado_duplo | 40 | 1.6 | 0.40 | 1.50 | 0.69 | 33 | 27 | 14.0 | 87 | 3 | 2 (1.9 s) | 2 (1.9 s) | 3 (3.4 s) | 5 (6.4 s) | 13 (18.4 s) |
| picareta | 26 | 1.3 | 0.27 | 0.90 | 0.45 | 29 | 52 | 9.5 | 42 | 1 | 4 (3.0 s) | 2 (1.2 s) | 3 (2.1 s) | 4 (3.0 s) | 11 (9.3 s) |
| tridente | 27 | 2.1 | 0.30 | 1.04 | 0.50 | 26 | 26 | 11.0 | 40 | 2 | 3 (2.4 s) | 2 (1.3 s) | 5 (4.5 s) | 7 (6.5 s) | 19 (19.0 s) |
| foice | 38 | 1.8 | 0.42 | 1.40 | 0.71 | 31 | 27 | 13.0 | 38 | 4 | 3 (3.2 s) | 2 (1.8 s) | 4 (4.6 s) | 5 (6.0 s) | 14 (18.6 s) |
| arco_longo | 26 | 18.0 | 0.45 | 1.01 | 0.65 | 26 | 26 | 6.5 | 71 | 1 | 4 (3.5 s) | 2 (1.5 s) | 5 (4.5 s) | 7 (6.5 s) | 20 (19.6 s) |
| besta_pesada | 62 | 18.0 | 0.30 | 2.60 | 1.12 | 24 | 24 | 5.0 | sem fim | 1 | 2 (2.9 s) | 1 (0.3 s) | 2 (2.9 s) | 3 (5.5 s) | 9 (21.1 s) |
| funda | 12 | 11.0 | 0.30 | 0.52 | 0.40 | 23 | 23 | 4.0 | 39 | 1 | 7 (3.4 s) | 5 (2.4 s) | 10 (5.0 s) | 15 (7.6 s) | 42 (21.6 s) |
| (punhos) | 8 | 0.8 | 0.14 | 0.44 | 0.24 | 18 | 18 | 4.0 | 82 | 1 | 10 (4.1 s) | 7 (2.8 s) | 15 (6.3 s) | 22 (9.4 s) | 63 (27.4 s) |

| Monstro | Vida | Dano | Preparo | Firmeza | Ataca a | Bote |
| --- | --- | --- | --- | --- | --- | --- |
| corrompido | 80 | 18 | 0.65 | 1.2 | 1.8 m | 0.50 m |
| guardiao | 120 | 26 | 0.85 | 1.6 | 1.8 m | 0.40 m |
| espreitador | 50 | 12 | 0.45 | 0.9 | 1.8 m | 0.70 m |
| brutamontes | 175 | 32 | 1.00 | 2.0 | 1.8 m | 0.45 m |
| chefe | 500 | 30 | 0.90 | — | 2.2 m | 0.75 m |

O chefe passou de 560 para 500 de vida depois do delay do peso. Por andar, os monstros ganham +30% de vida e +15% de dano. Cada nível de domínio dá +4% de dano e −2% de fôlego (até −30%).

## Ainda em aberto

- Os números são de planilha. Falta jogar de novo e ver se o 1º andar ficou no ponto, sem estar fácil nem frustrante.
- As armas pesadas ficaram com dano por segundo um pouco abaixo da espada num alvo só, porque acertam vários e atordoam. Se ainda parecerem fracas jogando, o primeiro ajuste é o dano delas.
- Com o acerto por toque, as armas curtas (adaga, faca, punhal, maça, machado) precisam chegar a menos de 1,5 m do monstro, quase o alcance da garra. Se ficarem arriscadas demais jogando, dá para subir o dano delas ou dar um passo à frente no golpe (`dash`).
