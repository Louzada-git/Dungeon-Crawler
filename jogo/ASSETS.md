# Assets e procedência

## Resumo (16/10/2026)

| O quê | De onde | Licença |
| --- | --- | --- |
| Cenário, móveis, baús, tochas, moeda e os modelos antigos | Criação própria (Blender), `assets/originais/` | do projeto |
| Aventureiro, mercador e os cinco monstros | Characters PSX (Elbolilloduro) | CC0 |
| Animações | Universal Animation Library (Quaternius), um golpe do Mixamo e poses escritas no projeto | CC0 / termos do Mixamo |
| Armas | RPG Weapons (Binbun), Low Poly Weapon Pack (Kickin' It Studios), 3D Fantasy Weapons Pack (Polyy, **gerado por IA**) | CC0 / uso livre em jogos / CC0 |
| Objetos (comida, bebida, tesouros, ferramentas) | Fantasy Props MegaKit (Quaternius) | CC0 |
| Efeitos visuais | Brackeys VFX Bundle | CC0 |
| Fonte | Inter | SIL OFL 1.1 |

**Declaração de IA para a Steam:** as 13 armas do 3D Fantasy Weapons Pack (seção "Armas") foram geradas por IA pelo autor do pacote (polyy.ai). O dono do projeto autorizou o uso em 16/10/2026, sabendo que a página da Steam precisa declarar isso. Nenhum outro asset do jogo foi gerado por IA, até onde as páginas dos autores informam.

## Biblioteca própria

Os modelos próprios estão em `assets/originais/`. Geometria, texturas procedurais e esqueleto foram criados para este projeto usando Blender. Não houve compra, assinatura, geração por serviço pago ou importação de imagens de Project Zomboid.

- Fonte editável: `../arte/fontes/dungepm_modelos.blend`.
- Gerador reproduzível: `../arte/fontes/gerar_modelos.py`.
- Texturas fonte: `../arte/texturas/`.
- Inventário técnico de meshes e triângulos: `assets/originais/MANIFESTO.json`.
- Referências visuais e observações: `../arte/REFERENCIAS.md`.
- Regeneração: `blender --background --factory-startup --python arte/fontes/gerar_modelos.py` a partir da raiz do projeto.

Os modelos de `assets/originais/` feitos no Blender são produção original do projeto. Os personagens (`aventureiro_psx`, `mercador`, `afogado`, `carnical`, `inchado`, `carcereiro`, `capataz`) ficam na mesma pasta, mas vêm do Characters PSX (seção "Personagens"). As armas vêm de três pacotes de terceiros (seção "Armas") e os objetos novos do MegaKit (seção "Objetos"). Não foi atribuída uma licença pública de redistribuição ao código ou à arte; essa escolha fica com o proprietário do projeto.

## Histórico do bloco inicial

A pasta `../arte/historico/kenney/` conserva os modelos usados no primeiro bloco funcional, com o texto original da licença CC0. Ficam fora do jogo.

Fonte anterior: [Kenney — Mini Dungeon](https://kenney.nl/assets/mini-dungeon), CC0. Não existem modelos desse pacote na cena jogável atual.

## Engine

Godot é software livre sob licença MIT. A licença da engine deve acompanhar a distribuição executável. Consulte [Godot — License](https://godotengine.org/license/) para os avisos de terceiros distribuídos com a engine.

## Interface

A organização do HUD segue a leitura do Project Zomboid (barra lateral, janelas recolhíveis, tabela de itens, indicadores de estado), por decisão do usuário. Nenhuma imagem, ícone, fonte ou layout gráfico do Project Zomboid foi copiado; as capturas enviadas pelo usuário serviram só como referência e não integram os assets distribuídos.

- **Ícones dos itens e recipientes** (`assets/ui/icones/*.png`): renderizados a partir dos modelos originais do projeto por `tools/render_icons.gd`, com contorno escuro aplicado no próprio script. Regeneração: `godot --path jogo --rendering-driver opengl3 -s res://tools/render_icons.gd` (precisa de tela, real ou virtual).
- **Ícones de interface e silhueta corporal**: desenhos vetoriais originais em `scripts/ui/ui_icon.gd` e `scripts/ui/ui_body_figure.gd`.
- **Fonte Inter** (`assets/fontes/Inter-*.otf`): © 2016-2023 The Inter Project Authors, [rsms/inter](https://github.com/rsms/inter), versão 4.0, licença SIL Open Font License 1.1. Texto completo em `assets/fontes/OFL.txt`; ele precisa acompanhar o jogo distribuído (já copiado para `outputs/linux/LICENCA-FONTE-INTER.txt`). A OFL permite embutir a fonte em software, inclusive comercial, desde que a fonte não seja vendida sozinha.

## Personagens

Todos usam modelos do pacote [Characters PSX](https://elbolilloduro.itch.io/characters-psx), de Elbolilloduro, licença CC0 (conferida na página do autor em 14/10/2026), com o rig padrão do Mixamo. São montados por `../arte/fontes/personagem_psx/personagens.gd` (detalhes em `../arte/fontes/personagem_psx/LEIA-ME.md`).

| No jogo | Arquivo | Modelo do pacote |
| --- | --- | --- |
| Aventureiro | `assets/originais/aventureiro_psx.glb` | `Character_16`, textura repintada para o jogo (roupa medieval; rosto, mãos e cabelo do original) |
| Mercador | `assets/originais/mercador.glb` | `Character_16`, com a túnica vinho |
| Afogado (`corrompido`) | `assets/originais/afogado.glb` | `Character_Monster_06` |
| Carniçal (`espreitador`) | `assets/originais/carnical.glb` | `Character_Monster_07` |
| Inchado (`brutamontes`) | `assets/originais/inchado.glb` | `Character_Monster_08` |
| Carcereiro (`guardiao`) | `assets/originais/carcereiro.glb` | `Character_Killer_08` |
| Capataz (`chefe`) | `assets/originais/capataz.glb` | `Character_Killer_05` |

Os modelos anteriores (o aventureiro e o corrompido próprios) continuam em `assets/originais/` e em `../arte/fontes/personagem_psx/origem_animacoes/`, fora do jogo.

## Armas

As armas usam modelos de três pacotes gratuitos, escolhidos pelo dono do projeto (os dois primeiros em 14/10/2026, o terceiro em 16/10/2026) e convertidos para a convenção do jogo (empunhadura na origem, ponta em +Y, metros) por `../arte/fontes/converter_armas.gd`. Os arquivos de origem escolhidos e as licenças estão em `../arte/fontes/pacotes/`. Os créditos vão junto do jogo em `outputs/linux/CREDITOS.txt`.

| Arma (id) | Pacote | Modelo de origem |
| --- | --- | --- |
| `adaga` | RPG Weapons (Binbun) | Dagger_06 |
| `montante` | RPG Weapons | Long_Sword_07 |
| `machado` | RPG Weapons | Axe_05 |
| `maca` | RPG Weapons | Mace_07 |
| `martelo` | RPG Weapons | Hammer_07 (afinado a 65%) |
| `spear` | RPG Weapons | Spear_05, 2,6 m |
| `lanca_longa` | RPG Weapons | Spear_07, 3,1 m |
| `katana` | Low Poly Weapon Pack (Kickin' It Studios) | Offset_Sword |
| `alabarda` | Low Poly Weapon Pack | Halberd |
| `arco` | Low Poly Weapon Pack | Bow |
| `besta` | Low Poly Weapon Pack | Crossbow |
| `flecha` | Low Poly Weapon Pack | Broadhead_Arrow |
| `virote` | Low Poly Weapon Pack | Bullet_Arrow |
| `espada_curta` | RPG Weapons | Short_Sword_03 |
| `faca` | RPG Weapons | Dagger_02 |
| `espada_larga` | 3D Fantasy Weapons Pack (Polyy, IA) | knights_longsword |
| `florete` | 3D Fantasy Weapons Pack | duelists_rapier |
| `alfanje` | 3D Fantasy Weapons Pack | falchion |
| `espadao` | 3D Fantasy Weapons Pack | highland_claymore |
| `punhal` | 3D Fantasy Weapons Pack | rogues_dagger |
| `maca_cravos` | 3D Fantasy Weapons Pack | spiked_mace |
| `estrela` | 3D Fantasy Weapons Pack | morning_star |
| `malho` | 3D Fantasy Weapons Pack | giants_maul |
| `martelo_guerra` | 3D Fantasy Weapons Pack | warhammer |
| `machado_duplo` | 3D Fantasy Weapons Pack | twin_moon_battle_axe |
| `picareta` | 3D Fantasy Weapons Pack | war_pick |
| `tridente` | 3D Fantasy Weapons Pack | tidal_trident |
| `foice` | 3D Fantasy Weapons Pack | reapers_scythe |

Arco longo, besta pesada, flecha de osso, flecha larga e virote pesado usam o modelo de outro item (`base`), maior (`escala_modelo`) ou com outra cor (`tint`).

- **RPG Weapons**, Binbun — [binbun3d.itch.io/rpg-weapons](https://binbun3d.itch.io/rpg-weapons). CC0: uso comercial livre, sem atribuição obrigatória. O pacote baixado não traz arquivo de licença; os termos foram conferidos na página em 14/10/2026.
- **Low Poly Weapon Pack**, Kickin' It Studios (itch.io). O leia-me do pacote permite usar e modificar em qualquer jogo ou projeto e proíbe revender os modelos como modelos 3D; crédito não é obrigatório, mas é apreciado.
- **3D Fantasy Weapons Pack**, Polyy — CC0 (texto em `../arte/fontes/pacotes/polyy_fantasy_weapons/LICENSE.txt`). **Gerado por IA** no polyy.ai: a Steam pede a declaração. Usamos a versão de baixa resolução, com texturas reduzidas a 128 px; a lista de arquivos está em `../arte/fontes/pacotes/polyy_fantasy_weapons/LEIA-ME.md`.
- RPG Weapons e Low Poly Weapon Pack não foram gerados por IA, até onde as páginas informam.
- `sword` e `espada_guarda` continuam com a espada original do projeto (`assets/originais/espada.glb`).

## Objetos

Onze itens usam objetos do **Fantasy Props MegaKit** (versão gratuita), de [Quaternius](https://quaternius.com), CC0. Convertidos por `../arte/fontes/converter_itens.gd` (origem no centro da base, tamanho em metros, textura reduzida); a cor vem dos vértices do modelo.

| Item | Modelo do pacote |
| --- | --- |
| `cenoura` | Carrot |
| `chave_mestra` | Key_Metal |
| `mapa` | Scroll_1 |
| `calice` | Chalice |
| `castical` | CandleStick |
| `cerveja` | Mug |
| `vinho` | Bottle_1 |
| `garrafada` | Potion_2 |
| `cha` | Potion_4 |
| `mel` | Pot_1_Lid |
| `arnica` | SmallBottle |

Os ícones desses itens e das armas novas saem dos próprios modelos, por `tools/render_icons.gd`.

## Efeitos visuais

Sangue, clarão de acerto, faíscas, golpe forte, poeira, fumaça e as chamas das tochas e da fogueira vêm do **Brackeys VFX Bundle** (CC0), que junta texturas de outros autores:

| Folha do jogo (`assets/vfx/`) | Original no pacote | Autor |
| --- | --- | --- |
| `sangue.png` | `predrawn/blood_impact_6x5.png` | CodeManu ([VFX Free Pack](https://codemanu.itch.io/vfx-free-pack)) |
| `impacto.png` | `predrawn/impact_white_6x4.png` | CodeManu |
| `golpe_forte.png` | `predrawn/big_hit_6x5.png` | CodeManu |
| `chama.png` | `flipbooks/flame_01_16x4.tga` | Thomas Iché ([flipbooks gratuitos da Unity](https://unity.com/blog/engine-platform/free-vfx-image-sequences-flipbooks)) |
| `fumaca.png` | `flipbooks/cloud_01_8x8.tga` | Thomas Iché |

As folhas foram recortadas, reduzidas para tamanho PSX (32 a 69 px por quadro) e remontadas por `../arte/fontes/vfx/preparar_vfx.py`, que lê os originais guardados em `../arte/fontes/vfx/originais/` (com o arquivo de licença e créditos do pacote). CC0 não exige crédito; mesmo assim os autores estão em `outputs/linux/CREDITOS.txt`.

## Pacotes recebidos

Recebidos em 14/10/2026. Os marcados **Em uso** já estão no jogo; o resto fica registrado para quando for usado. Em 15/10/2026 o dono do projeto autorizou o uso de tudo o que enviou. Isso não muda a licença de quem fez cada pacote: os marcados como **sem licença** ou **origem não identificada** precisam ter o autor e os termos confirmados antes de entrar na versão vendida na Steam.

| Pacote | Autor | Licença | Observação |
| --- | --- | --- | --- |
| PSX Dungeon | [Goblinatron](https://goblinatron.itch.io/psx-dungeon) | CC BY 4.0: créditos precisam citar "Goblinatron" | Kit PSX de masmorra; as texturas são três atlas (`Dungeon_Map`, `Doors_Map`, `CratesAndBarrels_Map`) |
| Characters PSX | [Elbolilloduro](https://elbolilloduro.itch.io/characters-psx) | CC0 | **Em uso**: aventureiro, mercador e os cinco monstros (seção "Personagens") |
| Fantasy Props MegaKit | [Quaternius](https://quaternius.com) | CC0 | **Em uso**: 11 objetos (seção "Objetos"). Versão gratuita |
| Universal Animation Library | Quaternius | CC0 | **Em uso**: parte das 43 animações (seção "Animações") |
| Brackeys VFX Bundle | Brackeys (texturas de Picster, Kenney, Thomas Iché, CodeManu) | CC0 | **Em uso** (seção "Efeitos visuais"). O resto (explosões, vórtice, anéis, magia) fica para quando a magia entrar |
| 3D Fantasy Weapons Pack | Polyy | CC0, **gerado por IA** | **Em uso**: 13 armas (seção "Armas"). Exige declaração de IA na Steam |
| Victorian Study | FoxDev | Crédito a "FoxDev" em projetos comerciais | Mobília vitoriana |
| Models + 512 (props de masmorra) | desconhecido | **sem licença** | Não usar sem confirmar a origem |
| LowPolyDungeon_FBX | desconhecido | **sem licença** | Veio sem texturas |
| PSX Modular Medieval | **origem não identificada** | **sem licença no arquivo** | Kit de vila medieval PSX: 193 modelos (GLB e FBX) em paredes de reboco e pedra, pisos, vigas, telhados (azul, vermelho, palha), portas, janelas, escadas, trepadeiras e um mercado (barracas, barris, caixotes, cestos, comida). 9 texturas |

## Modelos provisórios

As dez armaduras, as gazuas, a funda e as pedras, parte da comida (pão, queijo, peixe, toucinho, bolacha, cogumelo), sutura, erva, anel de prata e dente de ouro aparecem como **blocos** montados em tempo de execução a partir do campo `blocks` de `data/itens.json` (`Visuals.blocks`). São formas originais e provisórias. Um arquivo `assets/armas/<id>.glb` substitui os blocos automaticamente; a especificação está em `../arte/ARMAS_ESPEC.md`. Se os modelos vierem de uma ferramenta de IA, registre aqui a ferramenta e os termos de uso, porque a Steam pede essa informação no questionário de conteúdo.

## Animações

Desde 16/10/2026 todas as animações dos personagens saem de `../arte/fontes/personagem_psx/personagens.gd`, que as transfere para o rig do Mixamo:

- **Universal Animation Library** (Quaternius, CC0; arquivos e lista em `../arte/fontes/ual/`): parado, andar, correr, guarda, agachado, esquiva, dano, morte, soco e o mercador falando. Andar e parado dos monstros também.
- **Mixamo** (Adobe): o corte do sabre, `sword and shield slash (3)` do pacote Sword And Shield, baixado em 13/10/2026 pela conta Adobe do projeto. A [FAQ oficial da Adobe](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) permite usar personagens e animações do Mixamo em jogos pessoais e comerciais. Os FBX estão em `../arte/fontes/mixamo/`.
- **Poses escritas no projeto:** golpes de espada, adaga, florete, machado, maça, montante, foice, marreta, lança e alabarda, arco, besta, funda, bloqueio, a garra dos monstros e a pancada do capataz; e, desde 17/10/2026, o jeito de carregar cada tipo de arma (duas mãos, haste, besta, arco, mãos vazias) e os dedos fechados no cabo.

O acerto dos golpes segue essas animações (`scripts/systems/hitbox.gd`): a arma acerta o que toca no movimento.

## Sons

Cinco sons provisórios originais em `assets/audio/`, gerados localmente por `../arte/fontes/gerar_audio.py`. Não há gravações, músicas ou sons baixados de terceiros.

## Histórico das animações

Até 15/10/2026 o aventureiro usava nove ações feitas no rig próprio (`idle`, `guard`, `walk`, `run`, `attack`, `stab`, `dodge`, `hit`, `die`) e quatro animações do Mixamo (`slash (3)`, `attack (4)`, `impact`, `death`), adaptadas por `../arte/fontes/aplicar_mixamo.py`. Foram substituídas pelo conjunto acima.
