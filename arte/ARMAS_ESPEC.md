# Armas — especificação para modelos e animações

Esta é a ficha para quem for fazer os modelos 3D e as animações das armas, armaduras e perícias, seja você, outra IA ou um artista. Desde 14/10/2026 as armas usam modelos dos pacotes RPG Weapons e Low Poly Weapon Pack (lista em `jogo/ASSETS.md`); as armaduras e a gazua continuam como **blocos provisórios**. Quando chegar um arquivo com o nome certo, o jogo passa a usar esse modelo sozinho, inclusive no lugar das armas atuais.

Os números de jogo (dano, alcance, tempos) ficam em `jogo/data/itens.json`. As medidas abaixo são do modelo provisório: servem de referência de tamanho, não de forma final.

## Modelos

### Regras que todo modelo precisa seguir

| Regra | Valor |
| --- | --- |
| Formato | `.glb` (glTF binário) |
| Nome e pasta | `jogo/assets/armas/<id>.glb`, com o `id` exato da tabela abaixo |
| Escala | metros reais (1 unidade = 1 m) |
| Origem (0, 0, 0) | **o ponto onde a mão segura** |
| Eixo +Y | aponta para a ponta da lâmina, a cabeça da arma ou o cano da besta |
| Eixo +X | lado do fio no machado e na alabarda; no arco, a corda fica do lado −X |
| Eixo Z | espessura (a lâmina fica "de frente" para +Z) |
| Tamanho | até cerca de 3.000 triângulos; estilo low-poly estilizado, coerente com os modelos atuais |
| Materiais | simples (cor base, rugosidade, metálico); texturas opcionais |
| Não incluir | animação, esqueleto, câmera, luz ou chão |

Depois de colocar o arquivo, abra o projeto na Godot uma vez para ela importar o modelo. O ícone da mochila é gerado por `godot --path jogo --rendering-driver opengl3 -s res://tools/render_icons.gd`; se preferir, me peça.

### Armas

| id | Nome | Comprimento | Mãos | Onde fica o cabo (origem) | Forma |
| --- | --- | --- | --- | --- | --- |
| `adaga` | Adaga | 0,42 m | 1 | no meio do cabo; lâmina de 0,26 m acima | lâmina reta e estreita, guarda curta de latão, pomo pequeno |
| `katana` | Katana | 1,00 m | 2 | 0,10 m acima do fim do cabo | cabo longo envolto em tecido escuro, tsuba redonda, lâmina levemente curva para +X |
| `montante` | Montante | 1,60 m | 2 | 0,20 m acima do pomo | cabo longo de couro, guarda larga (0,36 m), lâmina larga e reta de 1,1 m |
| `machado` | Machado de guerra | 0,78 m | 1 | 0,19 m acima da ponta de baixo | cabo de madeira; cabeça a 0,5 m com o fio para +X e um pequeno esporão para −X |
| `maca` | Maça de flanges | 0,79 m | 1 | 0,20 m acima do pomo | cabo de madeira; cabeça de ferro com quatro flanges a 0,47 m |
| `martelo` | Martelo de guerra | 1,27 m | 2 | 0,25 m acima do fim do cabo | cabo longo; cabeça de 0,34 m no topo, face plana em +X e espigão em −X |
| `alabarda` | Alabarda | 2,62 m | 2 | 0,60 m acima do pé da haste | haste de madeira; lâmina de machado em +X, gancho em −X e ponta de lança no topo |
| `arco` | Arco curto | 1,16 m (altura) | 2 | no centro da empunhadura | dois braços curvos de madeira em ±Y, corda em −X. **Segurado na mão esquerda** |
| `besta` | Besta | 0,79 m | 2 | no gatilho, embaixo da coronha | coronha ao longo de +Y; arco de aço de 0,62 m atravessado em X na frente; corda e estribo |

| id | Munição | Comprimento | Origem | Forma |
| --- | --- | --- | --- | --- |
| `flecha` | Flecha | 0,73 m | no fim, nas penas | haste fina, ponta de ferro em +Y, penas vermelhas perto da origem |
| `virote` | Virote | 0,45 m | no fim, nas penas | haste grossa e curta, ponta de ferro em +Y |

As armas antigas (`sword`, `espada_guarda`, `spear`, `lanca_longa`) já têm modelo próprio. Um arquivo novo com o id delas também as substitui.

### Armaduras e ferramenta

As armaduras ficam presas ao osso `spine` do personagem (a 1,05 m do chão; os ombros ficam a 1,42 m, a cabeça a 1,56 m). Vale a mesma pasta e o mesmo formato das armas: `jogo/assets/armas/<id>.glb`.

| id | Nome | Tipo | Origem (0, 0, 0) | Forma |
| --- | --- | --- | --- | --- |
| `gibao` | Gibão acolchoado | leve | no osso da coluna: 0,1 m acima da cintura, no centro do tronco | colete de tecido grosso acolchoado, em gomos verticais, cor de linho; ombreiras macias |
| `couro` | Armadura de couro | leve | igual | peitoral de couro marrom com cintas, fivela de latão e ombreiras de couro |
| `cota` | Cota de malha | pesada | igual | túnica de anéis de ferro até a coxa, mangas curtas, cinto de couro |
| `placas` | Armadura de placas | pesada | igual | peitoral e costeiro de aço, ombreiras grandes, faixas de aço na cintura |
| `gazua` | Gazua | ferramenta | no cabo | haste fina de 0,14 m com a ponta dobrada, cabo curto escuro |

Regras próprias das armaduras: o modelo veste o tronco do personagem atual (largura de ombro a ombro de cerca de 0,45 m, profundidade de 0,3 m) sem cobrir a cabeça, os braços abaixo do cotovelo e as pernas; +Y para cima, o peito para +Z; até 2.500 triângulos. Se ficar fora do lugar, o campo `corpo` de `itens.json` (`pos` e `escala`) ajusta sem mexer no arquivo. O modelo não se deforma com a animação: é uma peça rígida presa à coluna.

### Pedido pronto para a IA de modelos

> Crie um modelo 3D low-poly estilizado de **[nome]**, arma medieval para um jogo de câmera isométrica. Exporte em .glb, em escala real (metros), com comprimento total de **[comprimento]**. A origem (0,0,0) fica exatamente **[onde fica o cabo]**. A ponta ou a cabeça da arma aponta para +Y. **[Forma]**. Até 3.000 triângulos, materiais simples (cor base, rugosidade, metálico). Sem luzes, câmeras, esqueleto ou animação. Nome do arquivo: **[id].glb**.

## Animações

### Como o jogo usa

- Desde 14/10/2026 o personagem é `jogo/assets/originais/aventureiro_psx.glb`, que já usa o **esqueleto padrão do Mixamo** (`mixamorig_*`). As animações atuais vieram do modelo anterior (`aventureiro_mixamo.glb`) por `arte/fontes/personagem_psx/transferir_animacoes.gd`.
- Cada arma diz o nome da animação que quer no campo `animacao` de `itens.json`. **Enquanto a animação não existir, o jogo usa a mais próxima que já tem**: corte para golpes, estocada para hastes e besta, guarda para o arco.
- O jogo **estica ou encolhe a animação** para caber na duração abaixo. O que importa é a proporção: o golpe precisa acertar no momento indicado.

### Regras para os arquivos de animação

| Regra | Valor |
| --- | --- |
| Esqueleto | padrão do Mixamo (`mixamorig`: Hips, Spine2, Neck, Head, Arm, ForeArm, Hand, UpLeg, Leg, Foot de cada lado) |
| Formato | FBX, sem pele (só esqueleto), 24 quadros por segundo |
| Deslocamento | no lugar: o quadril não pode andar para frente (quem move o personagem é o jogo) |
| Pasta | `arte/fontes/mixamo/<animacao>.fbx` |
| Mãos | a arma fica na mão direita; o arco fica na mão esquerda |

Depois de colocar os arquivos, me avise: eu acrescento cada um ao `aplicar_mixamo.py`, gero de novo o personagem e confiro em jogo. O Blender não está instalado aqui; se você rodar o script no seu computador, a lista fica no topo dele, em `MOTIONS`.

### Animações das armas

| Animação | Armas | Duração | Impacto em | Movimento |
| --- | --- | --- | --- | --- |
| `golpe_espada` | Espada de viajante, Espada da guarda | 0,56 s | 0,22 s (39%) | corte horizontal com uma mão, da direita para a esquerda |
| `golpe_adaga` | Adaga | 0,32 s | 0,12 s (37%) | golpe curto e rápido na altura do peito, quase sem preparo |
| `golpe_katana` | Katana | 0,45 s | 0,16 s (36%) | corte diagonal rápido com as duas mãos, de cima à direita para baixo à esquerda |
| `golpe_montante` | Montante | 0,99 s | 0,45 s (45%) | grande corte horizontal com as duas mãos, girando o tronco, arco de cerca de 160° |
| `golpe_machado` | Machado de guerra | 0,63 s | 0,26 s (41%) | golpe diagonal de cima para baixo com uma mão |
| `golpe_maca` | Maça de flanges | 0,65 s | 0,26 s (40%) | golpe pesado de cima para baixo com uma mão |
| `pancada_martelo` | Martelo de guerra | 1,22 s | 0,60 s (49%) | ergue o martelo acima da cabeça com as duas mãos e bate no chão cerca de 1,3 m à frente |
| `estocada_lanca` | Lança, Lança longa | 0,77 s | 0,30 s (39%) | estocada reta com as duas mãos (hoje usa a estocada adaptada do Mixamo) |
| `estocada_alabarda` | Alabarda | 0,85 s | 0,34 s (40%) | estocada reta e longa com as duas mãos, com um passo à frente |
| `disparo_arco` | Arco curto | 0,68 s | 0,35 s (52%) | arco na mão esquerda; a direita puxa a corda até o rosto e solta no impacto |
| `disparo_besta` | Besta | 1,44 s | 0,25 s (17%) | besta no ombro, dispara logo; o resto da animação é a recarga, puxando a corda de volta |

### Animações do personagem para as perícias novas

| Animação | Quando | Duração | Impacto em | Movimento |
| --- | --- | --- | --- | --- |
| `soco` | ataque sem arma | 0,40 s | 0,14 s (35%) | soco reto com a direita, guarda alta com a esquerda |
| `bloqueio` | segurando o botão direito com arma corpo a corpo ou punhos (repetida) | 1,0 s em loop | — | arma erguida na diagonal na frente do corpo, pernas afastadas, leve balanço |
| `furtivo` | agachado e parado (repetida) | 1,6 s em loop | — | agachado, joelhos dobrados, tronco inclinado para a frente, arma baixa |
| `furtivo_andar` | agachado e andando (repetida) | 1,0 s em loop (um ciclo de dois passos) | — | caminhada agachada e lenta, passos curtos, no lugar |

O jogo usa cada uma assim que ela existir no personagem; até lá, ataque, guarda e caminhada normais.

### Pedido pronto para a IA de animações

> Crie uma animação para o esqueleto padrão do Mixamo (mixamorig): **[movimento]**. Duração de **[duração]** a 24 quadros por segundo, sem deslocamento da raiz (o personagem fica no lugar). O momento do impacto deve ser em **[impacto]**. A arma fica na mão **[direita/esquerda]**. Exporte em FBX só com o esqueleto, com o nome **[animação].fbx**.
