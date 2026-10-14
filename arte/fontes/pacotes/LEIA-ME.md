# Pacotes de terceiros usados nas armas

Só os arquivos de origem escolhidos estão aqui, com as licenças. O pacote completo fica com o dono do projeto.

| Pasta | Pacote | Licença |
| --- | --- | --- |
| `rpg_weapons_binbun/` | [RPG Weapons](https://binbun3d.itch.io/rpg-weapons), Binbun | CC0 |
| `low_poly_weapon_pack_kickin_it/` | Low Poly Weapon Pack, Kickin' It Studios (itch.io) | uso livre em jogos, inclusive comercial; não pode revender os modelos; crédito apreciado |

`../converter_armas.gd` gera `jogo/assets/armas/<id>.glb` a partir destes arquivos. Uso:

1. Crie um projeto Godot vazio fora de `jogo/`, com `p/rpg/` (os `.glb` e `Texture.png` de `rpg_weapons_binbun/`) e `p/kickin/` (os `.fbx` de `low_poly_weapon_pack_kickin_it/`, com o prefixo `Low Poly Weapon Pack - by Kickin It Studios.fbx_` no nome, como no pacote original).
2. Copie `converter_armas.gd` para a raiz desse projeto e rode `godot --headless --path . --import` e depois `godot --headless --path . -s res://converter_armas.gd -- <pasta de saída> [ids...]`.
3. Copie os `.glb` gerados para `jogo/assets/armas/` e rode `tools/render_icons.gd` para refazer os ícones.

Cada linha da lista `jobs` diz o modelo de origem, a orientação (`y`, `x`), o comprimento final em metros, a altura da empunhadura (`grip`, fração a partir de baixo) e, se preciso, `thick` (afina ou engrossa sem mudar o comprimento).
