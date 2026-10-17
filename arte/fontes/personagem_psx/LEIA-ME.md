# Personagens PSX

## Desde 16/10/2026: `personagens.gd`

Todos os personagens do jogo saem de `personagens.gd`: o aventureiro, o mercador e os cinco monstros. Eles usam modelos do pacote [Characters PSX](https://elbolilloduro.itch.io/characters-psx), de Elbolilloduro (CC0), todos no rig do Mixamo, e as mesmas animações:

- **Universal Animation Library** (Quaternius, CC0; ver `../ual/`): parado, andar, correr, guarda, agachar, esquiva, dano, morte e soco. No parado, no andar, na corrida e na guarda, o braço da arma fica numa pose fixa por cima do movimento (`segura`: relaxado, carregando ou pronto na frente), para a arma não balançar solta.
- **`../mixamo/`**: o corte do sabre (`sword and shield slash (3)`).
- **Poses escritas no próprio script**: espada (com um passo à frente), estocada da adaga, estocada do florete, arremesso da funda, machado, maça, montante, ceifada da foice, marreta, lança, alabarda, arco, besta, bloqueio, a garra dos monstros e a pancada do capataz. Os golpes começam e terminam com a arma pronta na frente (`READY`), a mesma pose da guarda. Cada pose diz para onde apontam os braços, as pernas e a arma, quanto o tronco gira e inclina, e onde a mão esquerda segura armas de duas mãos (por IK). O script faz a transição entre as poses.

A transferência entre esqueletos funciona em dois passos. Primeiro o alvo é posto na mesma pose de referência da origem: os ossos dos membros giram até apontar como no T-pose da origem, porque os personagens do pacote vêm de braços para baixo. Depois cada osso recebe a rotação que o osso de origem faz a partir dessa referência.

| Personagem | Modelo | Textura |
| --- | --- | --- |
| aventureiro_psx | `Character_16.fbx` | `aventureiro_psx.png` (repintada) |
| mercador | `Character_16.fbx` | `mercador.png` (a do aventureiro com a túnica vinho) |
| afogado | `monstros/Character_Monster_06.fbx` | `monstros/Character_Monster_06.png` |
| carnical | `monstros/Character_Monster_07.fbx` | `monstros/Character_Monster_07.png` |
| inchado | `monstros/Character_Monster_08.fbx` | `monstros/Character_Monster_08.png` |
| carcereiro | `monstros/Character_Killer_08.fbx` | `monstros/Character_Killer_08.png` |
| capataz | `monstros/Character_Killer_05.fbx` | `monstros/Character_Killer_05.png` |

**Pegada e jeito de carregar (17/10/2026).** A arma fica dentro da mão fechada: `GRIP` (o mesmo que `DungeonPlayer.MOUNTS` no jogo) põe o cabo no eixo em que os dedos se fecham, a lâmina saindo do lado do polegar, a cabeça ou o gume para o lado dos nós dos dedos. Os três ossos do indicador da mão-luva ganham trilhas de punho fechado (`FIST`) em todas as animações do aventureiro; a mão esquerda fecha só onde segura o cabo ou o arco e fica meio aberta no resto (`RELAXED_HAND`). `carry_variants()` acrescenta o parado, andar, correr, guarda, agachado e bloqueio para cada jeito de carregar (`porte` no item): `_duas` (as duas mãos no cabo, baixa parado e inclinada para cima andando e agachado), `_haste` (de pé na mão direita parado, inclinada andando, com a esquerda à frente na guarda e agachado), `_besta` (na cintura com as duas mãos), `_arco` (na mão esquerda) e `_livre` (mãos vazias: braços soltos da biblioteca, guarda de punhos e antebraços erguidos no bloqueio).

O script também grava `animacoes.json`, com o momento do impacto de cada golpe, que vai para `jogo/data/animacoes.json`. O jogo usa esse valor para o golpe acertar no fim do preparo.

Para refazer: num projeto Godot à parte, monte `p/` com `Character_16.fbx`, `aventureiro_psx.png`, `mercador.png`, `p/psx/` (os arquivos de `monstros/`), `p/mixamo/` (os `.fbx` de `../mixamo/`) e `p/ual/UAL1_Standard.glb`. Depois rode `godot --headless --path . -s res://personagens.gd -- <saída> [ids...]`. Com `catalogo` no lugar dos ids, ele monta todo modelo de `p/psx/` só com a animação de parado, para escolher.

## Antes (14/10/2026): repintura e transferência do rig próprio

O aventureiro do jogo (`jogo/assets/originais/aventureiro_psx.glb`) é o `Character_16` do pacote
[Characters PSX](https://elbolilloduro.itch.io/characters-psx), de Elbolilloduro (CC0), com rig
Mixamo, textura repintada como aventureiro medieval e as animações do aventureiro anterior.

| Arquivo | O que é |
| --- | --- |
| `Character_16.fbx`, `Character_16_original.png` | Modelo e textura originais do pacote |
| `aventureiro_psx.png` | Textura repintada: túnica verde, mangas de linho, braçadeiras, cinto com fivela, alça de bolsa, calça de lã, botas |
| `exportar_triangulos.gd` | Godot: grava UV e posição 3D (pose de repouso, com a pele aplicada) de cada triângulo em `tris.json` |
| `mapear_textura.py` | Gera `pos.npy`: a posição 3D de cada pixel da textura |
| `repintar_textura.py` | Repinta por região do corpo, mantendo as dobras do original como sombreado; pele, rosto e cabelo ficam |
| `transferir_animacoes.gd` | Godot: leva as 13 animações do rig próprio (`aventureiro_mixamo.glb`) para o rig Mixamo e exporta o `.glb`; imprime as correções dos pontos de mão e tronco (`MOUNT`) usadas em `DungeonPlayer.MOUNTS` |

Refazer: num projeto Godot à parte com `p/Character_16.fbx`, `p/aventureiro_psx.png` e `p/aventureiro_mixamo.glb` (de `origem_animacoes/`, com as texturas)
(+ texturas), rode `exportar_triangulos.gd`, depois `python3 mapear_textura.py <pasta> 512`,
`python3 repintar_textura.py <pasta> p/Character_16_original.png p/aventureiro_psx.png` e por fim
`godot --headless --path . -s res://transferir_animacoes.gd -- <saída>/aventureiro_psx.glb`.

Como o rig é o padrão do Mixamo, animações novas feitas para o esqueleto do Mixamo servem direto neste personagem.
