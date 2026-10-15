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
| `tecnicas.json` | Técnicas: formas, componentes, requisitos por proficiência e regras (espaços por domínio, recarga, barra). |
| `proficiencias.json` | Grupos, ramos de proficiência (raízes e especializações), curva, efeitos por nível, perfil dos punhos e migração de nomes; as armas e armaduras indicam o caminho que treinam. |

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
| `player.gd`, `enemy.gd` | Personagem e monstros (movimento, golpes, IA). O modelo do personagem é `DungeonPlayer.MODEL`; `MOUNTS` diz em que osso ficam as mãos e o tronco em rigs com outros nomes (Mixamo) e a correção que mantém armas e armaduras no lugar. |
| `systems/combat.gd` | Resolução do golpe do jogador. |
| `systems/containers.gd` | Baús e pilhas no chão: ids, proximidade, guardar, deixar. |
| `systems/item_use.gd` | Comer, tratar, equipar a partir dos dados do item. |
| `systems/save_system.gd` | Save JSON (versão 2), validação, estado por andar e conhecimento. |
| `systems/labyrinth_generator.gd` | Gera um andar por semente e o valida (alcance, chefe, selo, ids). |
| `systems/projectile.gd` | Flechas e virotes em voo: paredes, monstros atravessados, munição presa e recuperável. |
| `proficiency_tree.gd` | Leitura de `proficiencias.json`: atributos, curva, ramos e habilidades. |
| `character_sheet.gd` | O aventureiro da run: atributos, experiência por ramo, domínio das armas, habilidades desbloqueadas e efeitos dos atributos. |
| `systems/game_camera.gd`, `systems/aim_marker.gd`, `systems/input_setup.gd` | Câmera, marcador de mira, teclas. |
| `systems/techniques.gd`, `technique_book.gd` | Técnicas: cálculo, validação e destrave (`Techniques`); receitas, barra e recarga do aventureiro (`TechniqueBook`). |
| `ui/ui_technique_window.gd` | Editor de técnicas (T). |
| `systems/psx_filter.gd` | Filtro de PlayStation: pós-processamento, materiais com vértices presos à grade e texto do mundo nítido. |
| `ui.gd` + `ui/` | HUD: um arquivo por painel (ver comentários no topo de cada um). |

## Armas

- **Estilos** (`style` em `itens.json`): `slash` (arco com `angle` e `targets`), `thrust` (linha reta com `width`; `targets` > 1 atravessa), `smash` (círculo à frente com `area_offset` e `area_radius`) e `shoot` (projétil com `ammo`, `projectile_speed`, `pierce`).
- **Efeitos:** `sneak_mult` (monstro desprevenido), `bleed` (`dps`, `time`), `crush` (monstros `armored`), `stagger` (segundos), `knockback` (3 é o normal).
- **Modelo:** `Visuals.item_model(id)` usa `assets/armas/<id>.glb` se existir; senão os `blocks` provisórios; senão o modelo compartilhado de `model`. Na mão: `rotacao_mao`, `escala_mao`, `alinhar_ao_golpe` e `mao` (`esquerda` para o arco).
- **Animação:** `animacao` é o nome desejado; enquanto o personagem não a tiver, `DungeonPlayer.attack_animation` usa a mais próxima.
- Especificação para modelos e animações: `../arte/ARMAS_ESPEC.md`.

## Atributos e proficiências

- **Atributos** (Força, Vigor, Agilidade, Destreza) são escolhidos no início de cada run (painel "Novo aventureiro"). Mudam carga, vida, fôlego, esquiva e passo, e definem o potencial de cada ramo: velocidade de aprendizado (0,6 + 0,08 × atributo) e nível máximo (10 + 4 × atributo).
- **Árvore** (`proficiencias.json`, versão 3), inspirada nas perícias de Oblivion e agrupada em três `grupos`:
  - *Combate:* Lâminas › (Espadas › Espada reta, Katana, Montante; Adagas), Contundentes › (Maça, Martelo, Machados), Hastes › (Lança, Alabarda), Desarmado, Bloqueio, Armadura pesada, Atletismo.
  - *Furtividade:* Furtividade, Pontaria › (Arcos, Bestas), Armadura leve, Acrobacia, Arrombamento.
  - *Sobrevivência:* Tratamento.
  - Fora por enquanto: magia, Alquimia, Reparo (precisa de durabilidade por item), Comércio e Oratória (precisam de mercadores).
- **Experiência** vem do que o personagem faz:

| Ramo | Treina com |
| --- | --- |
| Caminho da arma | dano causado (o monstro inteiro vale o seu `xp` em `inimigos.json`, +25% por andar); sangramento também conta |
| Desarmado | socos (sem arma equipada; perfil `punhos` em `proficiencias.json`) |
| Bloqueio | dano segurado pela guarda (botão direito com arma corpo a corpo ou punhos, golpe de frente) |
| Armadura leve / pesada | dano absorvido pela armadura vestida |
| Atletismo | metros corridos fora do abrigo; ×5 quando algum monstro está te perseguindo |
| Furtividade | andar agachado (C) perto de um monstro que não te viu (limite por monstro, `sneak_budget`) e ataques furtivos |
| Acrobacia | escapar de um golpe esquivando |
| Arrombamento | cada tentativa com gazua; abrir ensina 4× mais que falhar |
| Tratamento | curar um ferimento real |

- **Divisão:** a experiência de um golpe se divide pelo caminho da arma sem contar duas vezes (`divisao`: 1 ramo 100%; 2 ramos 50/50; 3 ramos 40/35/25, da raiz para a ponta). **Domínio** de uma arma = nível que a soma da experiência do caminho alcança, por isso armas de um, dois ou três ramos evoluem no mesmo ritmo, e praticar uma espada ajuda as outras pela raiz. Cada nível de domínio dá +2% de dano e −1% de fôlego.
- **Efeitos por nível** (`dominio`): guarda +1,2%/nível; proteção da armadura +2%/nível e penalidades −2,5%/nível; corrida −1,2% de fôlego/nível; distância de detecção agachado −1,5%/nível; chance de arrombar +4 pontos/nível; esquiva −0,3 de fôlego/nível; cura +2%/nível.
- **Habilidades** (`perks`) destravam por nível de ramo. As das armas mudam os números da arma (`CharacterSheet.weapon_stats`); as outras entram nas funções da ficha (`block_reduction`, `armor_protection`, `armor_penalty_mult`, `armor_noise`, `sprint_cost_mult`, `sneak_detection_mult`, `sneak_attack_mult`, `pick_chance`, `pick_break_chance`, `dodge_cost`, `heal_mult`).
- **Anti-repetição:** acima de 3 + 4 × andar do monstro, a experiência cai pela metade a cada 1,5 nível.
- **Save antigo:** `migracao` renomeia ramos (Esquiva → Acrobacia); ramos desconhecidos são descartados.
- **Morte:** o save da run (com o aventureiro) é apagado; o conhecimento não guarda proficiências.
- Simulação do ritmo com o código real: `godot --headless --path jogo -s res://tests/progression_sim.gd`.

## Guarda, armaduras, furtividade e fechaduras

- **Guarda** (`DungeonPlayer.can_block`, `receive_damage`): segurando o botão direito com arma corpo a corpo ou punhos, golpes num cone de 140° à frente perdem 40% (punhos: 25%) e gastam fôlego igual ao dano segurado (mínimo 4). Sem fôlego a guarda quebra. A pancada em área do chefe não é bloqueável (`blockable = false`). Arco e besta não bloqueiam.
- **Armaduras** (tag `ARMADURA` em `itens.json`): `armor_type` leve ou pesada, `protection` (parte de cada golpe absorvida, depois da guarda), `speed_penalty`, `regen_penalty` (recuperação de fôlego) e `noise` (aumenta a distância em que os monstros te notam). Vestir/tirar pelo inventário; `InventoryData.armor` vai no save. Aparece no tronco do personagem (osso `spine`); o campo `corpo` (`pos`, `escala`) ajusta os blocos provisórios.
- **Furtividade** (C): passo a 55%, quase sem som de passos. Um monstro nota a `sight × detection_mult`: de pé 1,0; agachado 0,5 de frente e 0,3 fora do cone de visão dele (120°); correndo 1,47; armadura barulhenta multiplica tudo. Golpe agachado em monstro desprevenido: ×1,5 com qualquer arma (×2 com a habilidade), somando ao bônus próprio da adaga.
- **Fechaduras:** baús podem ter `lock` 1–4 (simples, média, difícil, de mestre). Trancado, o conteúdo fica escondido e nada entra ou sai. Gazua (`FERRAMENTA`): chance = 60% − 20% por dificuldade acima de simples + 4% por nível de Arrombamento (+15% com a habilidade), entre 5% e 95%; falhar quebra a gazua em 50% das vezes (25% com a habilidade). `main.attempt_lockpick(container, roll, break_roll)` aceita dados fixos nos testes.
- **Gerador:** `LabyrinthGenerator._roll_lock` sorteia fechaduras com um gerador próprio, então ligar ou ajustar fechaduras não muda o resto do andar de uma semente. Tesouro 80%, covil 40%, suprimentos 25%, combate 15%; o relicário do chefe nunca. Dificuldade 1 + (andar − 1) / 2, +1 no tesouro, ±1, entre 1 e 4.
- **Animações opcionais:** quando o personagem tiver `soco`, `bloqueio`, `furtivo` ou `furtivo_andar`, o jogo usa; até lá, ataque, guarda e caminhada normais.

## Técnicas

Decisões de 15/10/2026: só técnicas físicas por enquanto (a magia fica para depois); montar e trocar em qualquer lugar fora de combate; componentes destravam só pela proficiência.

- **Receita** = forma + componentes nos espaços, com nome dado pelo jogador. Fica em `game.techniques` (`TechniqueBook`): até 12 receitas, barra de 4 (teclas 4 a 7) e recarga por receita.
- **Números:** `Techniques.stats` parte de `CharacterSheet.weapon_stats` da arma em mãos (domínio e habilidades já aplicados), aplica os efeitos da forma e depois os de cada componente **na ordem dos espaços**. `multiplica` escala o valor atual, inclusive o que componentes anteriores somaram; `soma` acrescenta um valor fixo (`disparo` dá outro valor para armas de disparo); `minimo` garante um piso; `define` troca o valor. Campos com ponto (`bleed.dps`) mexem num grupo.
- **Formas básicas** (`corte`, `estocada`, `pancada`, `disparo`, `soco`) são o golpe normal da arma; com componentes, viram técnica. **Formas destravadas** por nível de ramo: Corte giratório (Lâminas 4), Investida (Hastes 4), Golpe esmagador (Contundentes 4, só arma contundente), Tiro mirado (Pontaria 4), Sequência de socos (Desarmado 4).
- **Componentes** (nível 3 ou 4 do ramo): Lâmina afiada, Força, Alcance, Rapidez, Impacto, Avanço, Emboscada, Golpe duplo, Perfurante. Alguns só servem em certos estilos (`estilos`).
- **Espaços:** 1 + (domínio da arma − 1) / 5, até o máximo da forma (3 nas básicas).
- **Recarga:** a da forma + 0,75 s por componente. **Treino:** os golpes treinam o caminho da arma como sempre; cada componente usado dá 1,5 de experiência ao ramo que o destravou.
- **Execução:** `DungeonPlayer.use_technique(slot)` valida (`Techniques.problem`), mira no cursor e chama o mesmo `attack()` do golpe normal com os números da técnica. Novos campos: `hits` (golpes seguidos; em disparos, projéteis em leque), `dash` (avanço durante o preparo). Preparos longos seguram o personagem até o golpe sair.
- **Fora de combate:** `main.in_combat()` = algum monstro vivo caçando fora do abrigo. Com ele, o editor mostra o aviso e não muda nada; usar técnicas da barra continua livre.
- **Save e morte:** o save guarda receitas e barra; o conhecimento (`conhecimento.json`) guarda as receitas, que voltam no próximo aventureiro com a barra vazia. Componentes trancados para o novo aventureiro aparecem com o motivo.
- Captura: `tests/techniques_capture.gd`.

## Filtro PSX

- **Pós-processamento** (`PsxFilter.POST_SHADER`) num `CanvasLayer` de camada 0, abaixo do HUD (camada 1): a imagem é tirada em blocos de cerca de 300 linhas (`LINES`; 3 px numa janela de 900), cada bloco é a média dos seus pixels, e a cor cai para 15 bits (`COLOR_LEVELS` = 32 por canal) com pontilhado ordenado 4×4.
- **Materiais:** todo `StandardMaterial3D` opaco e iluminado vira um `ShaderMaterial` (`SURFACE_SHADER`) com a mesma cor, textura, cor de vértice, rugosidade, metal e emissão, textura lida sem suavização e vértices presos à mesma grade de 300 linhas (o tremido do PS1). A troca acontece quando o nó entra na árvore (`node_added`, adiada para o fim do quadro); lotes de `MultiMeshInstance3D` recebem uma cópia da malha. Materiais transparentes, sem sombra (anéis, chamas) e com `no_depth_test` ficam como estão.
- **Texto do mundo:** cada `Label3D` sai da câmera (`layers = 0`) e é desenhado como `Label` 2D nítido na posição projetada, com o mesmo tamanho na tela (`font_size × pixel_size × altura da janela / camera.size`).
- **Liga/desliga:** botão "Filtro PSX" na pausa; `main.set_psx` guarda a escolha em `user://configuracoes.cfg` (`[video] psx`). Desligar devolve os materiais originais, guardados em metadados de cada nó. Padrão: ligado.
- Captura de comparação: `tests/psx_capture.gd`.

## Testes e ferramentas

- `tests/runtime_test.gd`: suíte no mundo fixo. `godot --headless --path jogo -- --test`.
- `tests/labyrinth_test.gd`: suíte do labirinto. `godot --headless --path jogo -- --test-labirinto --seed=777`.
- `tests/generator_check.gd`: gera muitos andares e aponta problemas. `godot --headless --path jogo -s res://tests/generator_check.gd -- 60 4`.
- `tests/labyrinth_capture.gd`: capturas do labirinto (precisa de tela).
- `tests/weapons_capture.gd`: armas em mãos e em uso (precisa de tela).
- `tests/proficiency_capture.gd`: criação de personagem, janela de proficiências e aviso de nível (precisa de tela).
- `tests/skills_capture.gd`: armaduras no corpo, guarda, furtivo, baú trancado, dica de armadura e janela agrupada (precisa de tela).
- `tests/psx_capture.gd`: as mesmas cenas com e sem o filtro PSX (precisa de tela).
- `tests/techniques_capture.gd`: editor de técnicas, Corte giratório em uso e editor travado em combate (precisa de tela).
- `tests/hud_capture.gd`: capturas do HUD para revisão (precisa de tela).
- `tools/render_icons.gd`: gera os ícones dos itens a partir dos modelos.

## Ainda por fazer na etapa 8

Os textos da interface (botões, dicas, mensagens) ainda estão no código. Eles vão para `textos.csv` quando o idioma da versão 1.0 for decidido (etapa 3), para não traduzir duas vezes.
