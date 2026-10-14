# Arquitetura do projeto Godot

Mapa rápido de onde cada coisa vive. Atualizado na etapa 8 (13/10/2026).

## Dados (`data/`)

| Arquivo | Conteúdo |
| --- | --- |
| `itens.json` | Catálogo de itens: categoria, peso, modelo, números de combate e efeitos de consumo. `name`/`description` são chaves de texto. |
| `inimigos.json` | Tipos de monstro: vida, dano, preparo do golpe, velocidade, recuo, escala, espólio. |
| `mundos/cisternas.json` | Descrição do mundo atual: salas, corredores, bloqueios, mobília, recipientes, monstros, início e abrigo. Cada recipiente e monstro tem `id` fixo. |
| `textos.csv` | Textos de conteúdo por chave (coluna `pt_BR`). Outro idioma = nova coluna. |
| `saque.json` | Tabelas de saque por tipo de sala: `[item, peso, mínimo, máximo, andar mínimo]`. |
| `salas.json` | Nomes de sala por tipo, com gênero, e complementos. |

A descrição do mundo é a fronteira do labirinto procedural: `systems/labyrinth_generator.gd` produz esse formato a partir de (semente, andar). O mundo fixo `cisternas.json` continua existindo só para a suíte de testes.

## Labirinto

- **Andares:** 10, 20, 40, 60, 100, 200, 400 salas e depois dobra. Sala 0 é a entrada (abrigo no 1º andar, subida nos outros); a sala mais distante é a do chefe, com o relicário (selo + saque) e a descida.
- **Tipos de sala:** combate, suprimentos, tesouro (pontas sem saída), covil (guardião de elite) e chefe.
- **Monstros:** corrompido, espreitador (rápido), brutamontes (resistente), guardião (elite) e chefe. Vida +30% e dano +15% por andar. Monstros longe do jogador dormem.
- **Estado por andar:** baús e monstros de cada andar visitado ficam guardados; o mapa explorado é conhecimento e sobrevive à morte (`user://conhecimento.json`).
- **Save versão 2:** semente, andar atual, andares visitados, conhecimento, selos entregues.

## Código (`scripts/`)

| Arquivo | Responsabilidade |
| --- | --- |
| `main.gd` | Raiz do jogo: monta o mundo a partir dos dados, guarda o estado da expedição e liga os sistemas. Mantém a API usada pelo HUD e pelos testes. |
| `layout.gd` | Grade de piso, salas, sala segura e navegação, lidas da descrição do mundo. |
| `world_builder.gd` | Ambiente, pisos, paredes, tochas, mobília e recipientes em 3D. |
| `items.gd`, `enemy_types.gd` | Leitura dos catálogos; textos traduzidos em `Items.info()`. |
| `inventory.gd` | Mochila: pilhas, peso, equipar, transferir. |
| `player.gd`, `enemy.gd` | Personagem e monstros (movimento, golpes, IA). |
| `systems/combat.gd` | Resolução do golpe do jogador. |
| `systems/containers.gd` | Baús e pilhas no chão: ids, proximidade, guardar, deixar. |
| `systems/item_use.gd` | Comer, tratar, equipar a partir dos dados do item. |
| `systems/save_system.gd` | Save JSON (versão 2), validação, estado por andar e conhecimento. |
| `systems/labyrinth_generator.gd` | Gera um andar por semente e o valida (alcance, chefe, selo, ids). |
| `systems/game_camera.gd`, `systems/aim_marker.gd`, `systems/input_setup.gd` | Câmera, marcador de mira, teclas. |
| `ui.gd` + `ui/` | HUD: um arquivo por painel (ver comentários no topo de cada um). |

## Testes e ferramentas

- `tests/runtime_test.gd`: suíte no mundo fixo. `godot --headless --path jogo -- --test`.
- `tests/labyrinth_test.gd`: suíte do labirinto. `godot --headless --path jogo -- --test-labirinto --seed=777`.
- `tests/generator_check.gd`: gera muitos andares e aponta problemas. `godot --headless --path jogo -s res://tests/generator_check.gd -- 60 4`.
- `tests/labyrinth_capture.gd`: capturas do labirinto (precisa de tela).
- `tests/hud_capture.gd`: capturas do HUD para revisão (precisa de tela).
- `tools/render_icons.gd`: gera os ícones dos itens a partir dos modelos.

## Ainda por fazer na etapa 8

Os textos da interface (botões, dicas, mensagens) ainda estão no código. Eles vão para `textos.csv` quando o idioma da versão 1.0 for decidido (etapa 3), para não traduzir duas vezes.
