# Assets e procedência

## Biblioteca ativa: criação própria

Todos os modelos usados pelo jogo estão em `assets/originais/`. Geometria, texturas procedurais e esqueleto foram criados para este projeto usando Blender. O aventureiro agora usa também animações gratuitas do Mixamo, adaptadas ao esqueleto original. Não houve compra, assinatura, geração por serviço pago ou importação de imagens de Project Zomboid.

- Fonte editável: `../arte/fontes/dungepm_modelos.blend`.
- Gerador reproduzível: `../arte/fontes/gerar_modelos.py`.
- Texturas fonte: `../arte/texturas/`.
- Inventário técnico de meshes e triângulos: `assets/originais/MANIFESTO.json`.
- Referências visuais e observações: `../arte/REFERENCIAS.md`.
- Regeneração: `blender --background --factory-startup --python arte/fontes/gerar_modelos.py` a partir da raiz do projeto.

Os modelos de `assets/originais/` são produção original do projeto. As armas vêm de dois pacotes de terceiros (seção "Armas" abaixo). Não foi atribuída uma licença pública de redistribuição ao código ou à arte; essa escolha fica com o proprietário do projeto.

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

## Personagem

O aventureiro é o `Character_16` do pacote [Characters PSX](https://elbolilloduro.itch.io/characters-psx), de Elbolilloduro, licença CC0 (conferida na página do autor em 14/10/2026). O rig é o esqueleto padrão do Mixamo; a [FAQ da Adobe](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) permite usar personagens e animações do Mixamo em jogos comerciais. A textura foi repintada para este projeto (roupa medieval; rosto, mãos e cabelo do original) e as animações são as do aventureiro anterior, transferidas para o novo esqueleto. Arquivo: `assets/originais/aventureiro_psx.glb`; fontes e ferramentas em `../arte/fontes/personagem_psx/`. O modelo anterior (`aventureiro_mixamo.glb`, criação própria) fica fora do jogo, em `../arte/fontes/personagem_psx/origem_animacoes/`, como fonte das animações.

## Armas

As armas usam modelos de dois pacotes gratuitos, escolhidos pelo dono do projeto em 14/10/2026 e convertidos para a convenção do jogo (empunhadura na origem, ponta em +Y, metros) por `../arte/fontes/converter_armas.gd`. Os arquivos de origem escolhidos e as licenças estão em `../arte/fontes/pacotes/`. Os créditos vão junto do jogo em `outputs/linux/CREDITOS.txt`.

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

- **RPG Weapons**, Binbun — [binbun3d.itch.io/rpg-weapons](https://binbun3d.itch.io/rpg-weapons). CC0: uso comercial livre, sem atribuição obrigatória. O pacote baixado não traz arquivo de licença; os termos foram conferidos na página em 14/10/2026.
- **Low Poly Weapon Pack**, Kickin' It Studios (itch.io). O leia-me do pacote permite usar e modificar em qualquer jogo ou projeto e proíbe revender os modelos como modelos 3D; crédito não é obrigatório, mas é apreciado.
- Nenhum dos dois foi gerado por IA, até onde as páginas informam.
- `sword` e `espada_guarda` continuam com a espada original do projeto (`assets/originais/espada.glb`).

## Pacotes recebidos e ainda não usados

Recebidos em 14/10/2026. Nada destes pacotes está no jogo ainda; registrado aqui para quando forem usados.

| Pacote | Autor | Licença | Observação |
| --- | --- | --- | --- |
| PSX Dungeon | [Goblinatron](https://goblinatron.itch.io/psx-dungeon) | CC BY 4.0: créditos precisam citar "Goblinatron" | Kit PSX de masmorra; as texturas são três atlas (`Dungeon_Map`, `Doors_Map`, `CratesAndBarrels_Map`) |
| Characters PSX | [Elbolilloduro](https://elbolilloduro.itch.io/characters-psx) | CC0 | Em uso: `Character_16` é o aventureiro. Os outros 112 (9 monstros) ainda não |
| Fantasy Props MegaKit | [Quaternius](https://quaternius.com) | CC0 | Versão gratuita |
| Universal Animation Library | Quaternius | CC0 | 43 animações num esqueleto próprio |
| Brackeys VFX Bundle | Brackeys (texturas de Picster, Kenney, Thomas Iché, CodeManu) | CC0 | Fogo, fumaça, faíscas, sequências animadas |
| 3D Fantasy Weapons Pack | Polyy | CC0, **gerado por IA** | Exige declaração de IA na Steam |
| Victorian Study | FoxDev | Crédito a "FoxDev" em projetos comerciais | Mobília vitoriana |
| Models + 512 (props de masmorra) | desconhecido | **sem licença** | Não usar sem confirmar a origem |
| LowPolyDungeon_FBX | desconhecido | **sem licença** | Veio sem texturas |

## Modelos provisórios

As quatro armaduras (gibão, couro, cota de malha, placas) e a gazua aparecem como **blocos** montados em tempo de execução a partir do campo `blocks` de `data/itens.json` (`Visuals.blocks`). São formas originais e provisórias. Um arquivo `assets/armas/<id>.glb` substitui os blocos automaticamente; a especificação está em `../arte/ARMAS_ESPEC.md`. Se os modelos vierem de uma ferramenta de IA, registre aqui a ferramenta e os termos de uso, porque a Steam pede essa informação no questionário de conteúdo.

## Animações e sons de gameplay

Nove ações originais no rig próprio: `idle`, `guard`, `walk`, `run`, `attack`, `stab`, `dodge`, `hit`, `die`. Ações criadas pelo gerador Blender do projeto.

Cinco sons provisórios originais em `assets/audio/`, gerados localmente por `../arte/fontes/gerar_audio.py`. Não há gravações, músicas ou sons baixados de terceiros.

## Mixamo

O aventureiro usa quatro animações do pacote **Sword And Shield Pack**: `slash (3)` para o golpe de espada, `attack (4)` como base da estocada, `impact` e `death`. Caminhada, corrida, repouso, guarda e esquiva usam movimentos próprios do esqueleto original. A caminhada e a corrida do pacote foram retiradas do jogo após inspeção visual, porque cruzavam os pés no nosso modelo. Fonte: [Mixamo](https://www.mixamo.com/), pacote baixado em 13/10/2026 pela conta Adobe do projeto. A [FAQ oficial da Adobe](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) permite incorporar personagens e animações gratuitamente em jogos pessoais e comerciais. Os FBX selecionados estão em `../arte/fontes/mixamo/`; a adaptação reproduzível está em `../arte/fontes/aplicar_mixamo.py`. O modelo, suas texturas e seu esqueleto continuam originais do projeto.

A estocada usa o corpo de `sword and shield attack (4).fbx`, com adaptação própria dos braços para alcançar a haste. A orientação da lança fica alinhada à direção comprometida do golpe. O dano é limitado a uma faixa linear de 3,2 m e ao primeiro alvo.
