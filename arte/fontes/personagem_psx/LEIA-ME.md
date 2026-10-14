# Personagem PSX

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

Refazer: num projeto Godot à parte com `p/Character_16.fbx`, `p/aventureiro_psx.png` e `p/aventureiro_mixamo.glb`
(+ texturas), rode `exportar_triangulos.gd`, depois `python3 mapear_textura.py <pasta> 512`,
`python3 repintar_textura.py <pasta> p/Character_16_original.png p/aventureiro_psx.png` e por fim
`godot --headless --path . -s res://transferir_animacoes.gd -- <saída>/aventureiro_psx.glb`.

Como o rig é o padrão do Mixamo, animações novas feitas para o esqueleto do Mixamo servem direto neste personagem.
