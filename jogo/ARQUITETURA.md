# Arquitetura do projeto Godot

Mapa rápido de onde cada coisa vive. Atualizado na etapa 8 (13/10/2026).

## Dados (`data/`)

| Arquivo | Conteúdo |
| --- | --- |
| `itens.json` | Catálogo de itens: categoria, peso, modelo, números de combate e efeitos de consumo. `name`/`description` são chaves de texto. |
| `inimigos.json` | Tipos de monstro: vida, dano, preparo do golpe, velocidade, recuo, escala, espólio e `firmeza` (tempo sem poder ser atordoado de novo depois de um atordoamento). |
| `mundos/cisternas.json` | Descrição do mundo atual: salas, corredores, bloqueios, mobília, recipientes, monstros, início e abrigo. Cada recipiente e monstro tem `id` fixo. |
| `textos.csv` | Textos de conteúdo por chave (coluna `pt_BR`). Outro idioma = nova coluna. |
| `saque.json` | Tabelas de saque por tipo de sala: `[item, peso, mínimo, máximo, andar mínimo]`. |
| `salas.json` | Nomes de sala por tipo, com gênero, e complementos. |
| `tecnicas.json` | Habilidades e objetos: efeitos, requisitos por proficiência, cópias, slots, recarga e barra. |
| `efeitos.json` | Efeitos visuais: folha, tamanho, velocidade, cor, brilho, mistura aditiva, se fica em pé, se repete, se sobe e se desvanece. |
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
| `world_builder.gd` | Ambiente, pisos, paredes, tochas, fogueira do abrigo, mobília e recipientes em 3D. |
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
| `systems/techniques.gd`, `technique_book.gd` | Habilidades: cálculo, validação, destrave e cópias (`Techniques`); montagem, barra e recarga do aventureiro (`TechniqueBook`). |
| `ui/ui_technique_window.gd` | Janela de habilidades (T). |
| `systems/psx_filter.gd` | Filtro de PlayStation: pós-processamento, materiais com vértices presos à grade e texto do mundo nítido. |
| `systems/vfx.gd` | Efeitos visuais (`Vfx`): sangue, clarões, faíscas, poeira, fumaça, chamas e o tremor das luzes de fogo. |
| `ui.gd` + `ui/` | HUD: um arquivo por painel (ver comentários no topo de cada um). |

## Armas

- **Estilos** (`style` em `itens.json`): `slash` (arco com `angle` e `targets`), `thrust` (linha reta com `width`; `targets` > 1 atravessa), `smash` (círculo à frente com `area_offset` e `area_radius`) e `shoot` (projétil com `ammo`, `projectile_speed`, `pierce`).
- **Efeitos:** `sneak_mult` (monstro desprevenido), `bleed` (`dps`, `time`), `crush` (monstros `armored`), `stagger` (segundos), `knockback` (3 é o normal).
- **Tempo do golpe:** `windup` é o preparo até o golpe acertar; `cooldown` é o golpe inteiro. O delay depois do acerto (`cooldown` − `windup`) depende do peso da arma (`classe`: leve, media, pesada); armas pesadas têm muito dano por golpe e delay alto. Lentidão e trava de virar duram 90% do `cooldown`; a esquiva volta na metade do delay (`DungeonPlayer.DODGE_AFTER`) e corta a lentidão. A animação dura `windup` / `impacto` para acertar no fim do preparo. Números e tabela em `BALANCO.md`.
- **Modelo:** `Visuals.item_model(id)` usa `assets/armas/<id>.glb` se existir; senão os `blocks` provisórios; senão o modelo compartilhado de `model`. Na mão: `rotacao_mao`, `escala_mao`, `alinhar_ao_golpe` e `mao` (`esquerda` para o arco).
- **Animação:** `animacao` é o nome desejado; enquanto o personagem não a tiver, `DungeonPlayer.attack_animation` usa a mais próxima.
- Especificação para modelos e animações: `../arte/ARMAS_ESPEC.md`.

## Atributos e proficiências

- **Atributos** (Força, Vigor, Agilidade, Destreza) são escolhidos no início de cada run (painel "Novo aventureiro"): 25 pontos (`criacao.pontos`), começando em 5 cada, ou seja, 5 livres; de 2 a 9 por atributo. Mudam carga, vida, fôlego, esquiva e passo, e definem o potencial de cada ramo: velocidade de aprendizado (0,6 + 0,08 × atributo) e nível máximo (10 + 4 × atributo).
- **Fôlego** (`folego` em `proficiencias.json`): recuperação 20,8/s (7,8 com fome), corrida 8/s, esquiva 12,5 (−0,5 por Agilidade acima de 5, −0,3 por nível de Acrobacia, mínimo 5), guarda metade do dano segurado (mínimo 2). Gastos pela metade e recuperação ×1,3 em 15/10/2026, junto com os custos das armas, dos objetos e dos talentos.
- **Arma inicial:** o mesmo painel deixa escolher qualquer arma de `itens.json` (as que têm `style`) ou os punhos; `main.choose_weapon` troca a espada pela escolhida. Arco e besta vêm com `criacao.municao_inicial` (20) flechas ou virotes.
- **Árvore** (`proficiencias.json`, versão 3), inspirada nas perícias de Oblivion e agrupada em três `grupos`:
  - *Combate:* Lâminas › (Espadas › Espada reta, Katana, Montante; Adagas), Contundentes › (Maça, Martelo, Machados, Desarmado), Hastes › (Lança, Alabarda), Bloqueio, Armadura pesada, Atletismo.
  - *Furtividade:* Furtividade, Pontaria › (Arcos, Bestas), Armadura leve, Acrobacia, Arrombamento.
  - *Sobrevivência:* Tratamento.
  - Fora por enquanto: magia, Alquimia, Reparo (precisa de durabilidade por item), Comércio e Oratória (precisam de mercadores).
- **Experiência** vem do que o personagem faz:

| Ramo | Treina com |
| --- | --- |
| Caminho da arma | dano causado (o monstro inteiro vale o seu `xp` em `inimigos.json`, +25% por andar); sangramento também conta |
| Contundentes › Desarmado | socos (sem arma equipada; perfil `punhos` em `proficiencias.json`). Desde 15/10/2026 o soco é contundente: treina e usa os talentos de Contundentes, como a maça e o martelo |
| Bloqueio | dano segurado pela guarda (botão direito com arma corpo a corpo ou punhos, golpe de frente) |
| Armadura leve / pesada | dano absorvido pela armadura vestida |
| Atletismo | metros corridos fora do abrigo; ×5 quando algum monstro está te perseguindo |
| Furtividade | andar agachado (C) perto de um monstro que não te viu (limite por monstro, `sneak_budget`) e ataques furtivos |
| Acrobacia | escapar de um golpe esquivando |
| Arrombamento | cada tentativa com gazua; abrir ensina 4× mais que falhar |
| Tratamento | curar um ferimento real |

- **Divisão:** a experiência de um golpe se divide pelo caminho da arma sem contar duas vezes (`divisao`: 1 ramo 100%; 2 ramos 50/50; 3 ramos 40/35/25, da raiz para a ponta). **Domínio** de uma arma = nível que a soma da experiência do caminho alcança, por isso armas de um, dois ou três ramos evoluem no mesmo ritmo, e praticar uma espada ajuda as outras pela raiz. Cada nível de domínio dá +4% de dano e −2% de fôlego (até −30%).
- **Efeitos por nível** (`dominio`, dobrados em 15/10/2026): guarda +2,4%/nível; proteção da armadura +4%/nível e penalidades −5%/nível; corrida −2,4% de fôlego/nível; distância de detecção agachado −3%/nível; chance de arrombar +8 pontos/nível; esquiva −0,3 de fôlego/nível (a esquiva custa a metade desde a revisão do fôlego); cura +4%/nível. Os limites de cada função da ficha continuam (guarda até 85%, proteção até 70%, penalidade até 40% do original, esquiva no mínimo 10 de fôlego etc.), agora alcançados na metade dos níveis.
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

## Habilidades

Decisões de 15/10/2026: só físicas por enquanto (a magia vem depois); montar em qualquer lugar fora de combate; tudo destrava pela proficiência. Modelo do dono do projeto: cada **habilidade** existe uma vez, com características fixas, e tem **slots** onde vão **objetos**; quanto maior o nível, mais slots; objetos vão em qualquer habilidade onde façam sentido; cada cópia de objeto fica em uma habilidade por vez, e a proficiência dá mais cópias.

- **Dados** (`tecnicas.json`, versão 2): `formas` = habilidades (`slots` máximos, `slot_a_cada`, `recarga`, `efeitos`, `requer`); `objetos` (`requer`, `copias` = níveis do ramo que dão cada cópia, `estilos` só onde não faria sentido, `efeitos`).
- **Montagem** em `game.techniques` (`TechniqueBook`): `configs` (habilidade → objetos na ordem dos slots), barra de 4 (teclas 4 a 7, cada habilidade num lugar só) e recarga por habilidade. Mudanças valem na hora.
- **Números:** `Techniques.stats` parte de `CharacterSheet.weapon_stats` da arma em mãos, aplica os efeitos da habilidade e depois os de cada objeto **na ordem dos slots**. `multiplica` escala o valor atual, inclusive o que objetos anteriores somaram; `soma` acrescenta (`disparo` dá outro valor em armas de disparo); `minimo` garante um piso; `define` troca o valor.
- **Habilidades básicas** (Corte, Estocada, Pancada, Disparo, Soco) são o golpe normal da arma; slots pelo domínio da arma (1 + (domínio − 1) / 5, até 3). **Destraváveis:** Corte giratório (Lâminas 4), Investida (Hastes 4), Golpe esmagador (Contundentes 4), Tiro mirado (Pontaria 4), Sequência de socos (Desarmado 4); o Golpe esmagador aceita os punhos, que são contundentes; slots pelo nível do ramo: 1 + (nível − nível de destrave) / 4, até 2 (1 na Sequência).
- **Objetos e cópias:** um por ramo de proficiência (25). Raízes e ramos sem arma: Lâmina afiada (Lâminas 3/9/15), Força (Contundentes 3/9/15), Alcance (Hastes 3/9), Rapidez (Acrobacia 3/9), Impacto (Bloqueio 3/9), Avanço (Atletismo 3/10), Emboscada (Furtividade 3/10), Perfurante (Pontaria 3/10), Ombrada (Armadura pesada 3/9), Leveza (Armadura leve 3/9), Fresta (Arrombamento 3/9), Bálsamo (Tratamento 3/9). Especializações, nos níveis 4 e 12: Golpe duplo (Espadas), Equilíbrio (Espada reta), Saque rápido (Katana), Varredura (Montante), Ponto vital (Adagas), Cravos (Maça), Tremor (Martelo, só pancada), Talho fundo (Machados), Ponta rápida (Lança), Gancho (Alabarda), Soco-inglês (Desarmado), Saraivada (Arcos, só disparo), Disparo pesado (Bestas, só disparo). Campo novo `cura` (vida por acerto, em `Combat.apply_hit`). A janela mostra primeiro os objetos que o aventureiro tem e rola o resto. Cópias em uso acima das que o aventureiro tem tornam a habilidade inválida, com o motivo (acontece depois da morte).
- **Recarga:** a da habilidade + 0,75 s por objeto. **Treino:** golpes treinam o caminho da arma; cada objeto usado dá 1,5 de experiência ao ramo que o dá.
- **Execução:** `DungeonPlayer.use_technique(slot)` valida (`Techniques.problem`), mira no cursor e chama o mesmo `attack()` do golpe normal; campos novos `hits` e `dash`.
- **Fora de combate:** `main.in_combat()`; com monstro caçando, a janela mostra o aviso e não muda nada; a barra continua livre.
- **Avisos:** subir de nível anuncia habilidade nova e cópia nova de objeto. Os bônus passivos de nível 5 e 10 da proficiência passaram a se chamar **talentos**.
- **Save e morte:** o save guarda a montagem e a barra (lê também o formato anterior, de receitas com nome); o conhecimento guarda a montagem, que volta no próximo aventureiro com a barra vazia.
- Captura: `tests/techniques_capture.gd`.

## Filtro PSX

- **Pós-processamento** (`PsxFilter.POST_SHADER`) num `CanvasLayer` de camada 0, abaixo do HUD (camada 1): a imagem é tirada em blocos de cerca de 300 linhas (`LINES`; 3 px numa janela de 900), cada bloco é a média dos seus pixels, e a cor cai para 15 bits (`COLOR_LEVELS` = 32 por canal) com pontilhado ordenado 4×4.
- **Materiais:** todo `StandardMaterial3D` opaco e iluminado vira um `ShaderMaterial` (`SURFACE_SHADER`) com a mesma cor, textura, cor de vértice, rugosidade, metal e emissão, textura lida sem suavização e vértices presos à mesma grade de 300 linhas (o tremido do PS1). A troca acontece quando o nó entra na árvore (`node_added`, adiada para o fim do quadro); lotes de `MultiMeshInstance3D` recebem uma cópia da malha. Materiais transparentes, sem sombra (anéis, chamas) e com `no_depth_test` ficam como estão.
- **Texto do mundo:** cada `Label3D` sai da câmera (`layers = 0`) e é desenhado como `Label` 2D nítido na posição projetada, com o mesmo tamanho na tela (`font_size × pixel_size × altura da janela / camera.size`).
- **Liga/desliga:** botão "Filtro PSX" na pausa; `main.set_psx` guarda a escolha em `user://configuracoes.cfg` (`[video] psx`). Desligar devolve os materiais originais, guardados em metadados de cada nó. Padrão: ligado.
- Captura de comparação: `tests/psx_capture.gd`.

## Efeitos visuais

- **Folhas:** `assets/vfx/*.png`, pequenas (32 a 69 px por quadro), feitas a partir do Brackeys VFX Bundle por `../arte/fontes/vfx/preparar_vfx.py`; a grade de cada uma fica em `assets/vfx/folhas.json`. O importador está com `detect_3d/compress_to=0`, para o editor não comprimir as folhas.
- **Desenho:** cada efeito é um `MeshInstance3D` com `QuadMesh` e o `ShaderMaterial` de `Vfx.SHADER`, que vira o quadro para a câmera (ou só em volta do eixo Y, nas chamas), escolhe o quadro da folha e lê sem suavizar. O filtro PSX não troca esse material; a imagem final passa pelo pós-processamento como o resto.
- **Efeitos de uma vez** (`Vfx.burst`): cópia do material com o quadro avançado por um `Tween`; o nó entra no grupo `efeitos` e se apaga quando a folha acaba. Ficam um pouco à frente do corpo, na direção da câmera, para não sumirem dentro dele.
- **Chamas** (`Vfx.flame`): grupo `chamas`, um material só para todas; o quadro sai do tempo e da posição, sem script por tocha. As luzes de tocha e da fogueira tremem por `Vfx.Flicker` (um nó por andar, `LuzesTremulas`), 15 vezes por segundo e só perto da câmera.
- **Onde aparecem:** acerto em monstro (`Combat.apply_hit` → `Vfx.enemy_hit`: sangue e clarão; faíscas em blindado sem arma que esmaga; estouro grande em ataque furtivo, armadura esmagada ou atordoamento forte); sangramento (gota a cada 0,5 s); morte (fumaça); aventureiro ferido (sangue) e guarda (faíscas do lado do golpe); esquiva e avanço (poeira); pancada no chão (anel de poeira); flecha na parede (clarão e poeira).
- Captura: `tests/vfx_capture.gd`.

## Testes e ferramentas

O jogo exportado não leva `tests/`, `tools/` nem documentos (`export_presets.cfg`: `exclude_filter`); as suítes rodam pelo projeto. Pacotes de entrega: `../empacotar.sh` (jogo, revisão, documentos e arte separados). Capturas de revisão ficam em `../revisao/`.

- `tests/runtime_test.gd`: suíte no mundo fixo. `godot --headless --path jogo -- --test`.
- `tests/labyrinth_test.gd`: suíte do labirinto. `godot --headless --path jogo -- --test-labirinto --seed=777`.
- `tests/generator_check.gd`: gera muitos andares e aponta problemas. `godot --headless --path jogo -s res://tests/generator_check.gd -- 60 4`.
- `tests/labyrinth_capture.gd`: capturas do labirinto (precisa de tela).
- `tests/weapons_capture.gd`: armas em mãos e em uso (precisa de tela).
- `tests/proficiency_capture.gd`: criação de personagem, janela de proficiências e aviso de nível (precisa de tela).
- `tests/skills_capture.gd`: armaduras no corpo, guarda, furtivo, baú trancado, dica de armadura e janela agrupada (precisa de tela).
- `tests/psx_capture.gd`: as mesmas cenas com e sem o filtro PSX (precisa de tela).
- `tests/techniques_capture.gd`: janela de habilidades, Corte giratório em uso e janela travada em combate (precisa de tela).
- `tests/vfx_capture.gd`: tochas, fogueira, sangue, golpe forte, faíscas, poeira, fumaça e o mesmo acerto sem o filtro (precisa de tela).
- `tests/hud_capture.gd`: capturas do HUD para revisão (precisa de tela).
- `tools/render_icons.gd`: gera os ícones dos itens a partir dos modelos.

## Ainda por fazer na etapa 8

Os textos da interface (botões, dicas, mensagens) ainda estão no código. Eles vão para `textos.csv` quando o idioma da versão 1.0 for decidido (etapa 3), para não traduzir duas vezes.
