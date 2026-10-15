# Dungepm — As Cisternas

## Novo: barra rápida, teclas das habilidades e delay do peso (15/10/2026)

- **Barra rápida de 1 a 9:** qualquer item em qualquer espaço. Arma equipa (apertando de novo, guarda e fica de punhos), armadura veste e tira, comida come, curativo aplica. Munição fica na barra só para mostrar quantas restam. Começa com a arma inicial no 1, rações no 2 e bandagens no 3.
- **Pôr itens na barra:** arraste da mochila para o espaço, ou use o menu do item (botão direito: "Pôr na barra rápida"), ou selecione o item com a mochila aberta e aperte o número. Botão direito no espaço tira o item. O espaço fica mesmo quando o item acaba (mostra 0).
- **Teclas das habilidades à sua escolha:** começam em **Q, R, F e G**. Para trocar, abra **T**, clique na tecla do espaço e aperte a nova. Vale qualquer tecla livre, inclusive o **teclado numérico** (Num 1, Num 2…). Os números de cima ficam para a barra rápida. Se a tecla já estiver em outro espaço, os dois trocam. A escolha fica salva.
- **Delay do peso** (sugestão do Pedro): depois do golpe, cada kg da arma soma 0,1 s antes de poder golpear de novo. Martelo (6,5 kg): +0,65 s; espada (2,4 kg): +0,24 s; adaga (0,8 kg): +0,08 s. Nesse tempo você anda normal e pode esquivar, só não golpeia. Os danos foram reacertados depois disso, e o chefe ficou com 500 de vida.

## Novo: atualização depois do teste (15/10/2026)

- **Fôlego** (pedido do Bruno): tudo gasta metade do fôlego, ou seja, golpes, objetos, esquiva (12,5), corrida e guarda. E o fôlego volta 1,3× mais rápido.
- **Delay pelo peso da arma** (pedido do Pedro): o corte para um terço tirava quase todo o delay. Agora cada arma tem o seu. As **leves** (adaga, katana) são rápidas e batem pouco. As **médias** (espadas, machado, maça, lança, arco) ficam no meio. As **pesadas** (montante, martelo, alabarda, lança longa, besta) batem muito e mantêm um delay alto: o martelo espera 0,68 s depois do golpe (eram 0,25 s na versão que vocês jogaram). A dica de cada arma mostra o peso e o delay.
- **Esquiva na metade do delay:** dá para esquivar a partir da metade do delay depois do golpe. A esquiva corta a lentidão do golpe, mas o próximo golpe ainda espera o tempo dele.
- **Sem atordoamento em cadeia:** antes, cada golpe cancelava o ataque do monstro, e ele nunca conseguia atacar. Agora, depois de atordoado, o monstro fica **firme** por um tempo: ainda leva dano, mas termina o ataque. Esquive ou segure na guarda.
- **Danos balanceados:** as armas ficaram com dano por segundo parecido. Cada uma compensa com outra vantagem: alcance, área, sangramento, atordoamento ou ataque furtivo. Os monstros têm cerca de 25% mais vida e um pouco mais de dano. Valores novos em `jogo/BALANCO.md`.

## Novo: ajustes de 15/10/2026

- **+5 pontos de atributo:** o novo aventureiro tem 25 pontos. Começa com 5 em cada e sobram 5 livres para pôr onde quiser (de 2 a 9 por atributo).
- **Arma inicial à escolha:** no mesmo painel você escolhe qualquer uma das 13 armas, ou começa de punhos. Arco e besta vêm com 20 flechas ou virotes.
- **Soco é contundente:** Desarmado agora fica dentro de Contundentes. Socar treina Contundentes e Desarmado, os talentos de Contundentes (como Atordoar) valem no soco, e o Golpe esmagador funciona de mãos vazias.
- **Um objeto por proficiência:** são 25 objetos, um para cada ramo. Os novos: Equilíbrio (Espada reta), Saque rápido (Katana), Varredura (Montante), Ponto vital (Adagas), Cravos (Maça), Tremor (Martelo), Talho fundo (Machados), Ponta rápida (Lança), Gancho (Alabarda), Soco-inglês (Desarmado), Ombrada (Armadura pesada), Saraivada (Arcos), Disparo pesado (Bestas), Leveza (Armadura leve), Fresta (Arrombamento) e Bálsamo (Tratamento, recupera vida a cada acerto). Os de especialização chegam nos níveis 4 e 12; os outros, no 3 e no 9. Na janela de habilidades, os que você tem aparecem primeiro e o resto rola.
- **Recuperação do ataque menor:** primeiro caiu para um terço em todas as armas; depois do teste, passou a depender do peso da arma (ver acima).
- **Bônus por nível dobrado:** cada nível de domínio dá +4% de dano e −2% de fôlego (até −30%). Os bônus por nível de Bloqueio, armaduras, Atletismo, Furtividade, Arrombamento, Acrobacia e Tratamento também dobraram. Os talentos dos níveis 5 e 10 não mudaram.

## Novo: efeitos visuais (15/10/2026)

Os efeitos vêm do Brackeys VFX Bundle que você mandou, reduzidos para o tamanho PSX (poucos pixels por quadro, lidos sem suavizar), então combinam com o filtro.

- **Acertos:** sangue e um clarão a cada golpe que pega. Em monstro blindado, faíscas no lugar do sangue, a não ser que a arma esmague armadura (maça, martelo).
- **Golpe forte:** ataque furtivo, armadura esmagada e golpes que atordoam muito (Golpe esmagador, Impacto) soltam um estouro dourado maior.
- **Sangramento:** o monstro pinga sangue enquanto a Lâmina afiada faz efeito.
- **Você:** sangue quando é ferido; faíscas do lado do golpe quando a guarda segura.
- **Poeira:** na esquiva, na Investida e no Avanço, e em volta da Pancada no chão. Flecha que bate na parede solta um clarão e poeira.
- **Morte:** o monstro solta uma fumaça clara ao cair.
- **Tochas** agora têm chama animada, e a luz delas treme. **Fogueira no abrigo**, dentro do círculo onde você descansa.

## Novo: habilidades e objetos (15/10/2026)

**T** abre as habilidades. A barra de habilidades usa as teclas que você escolher (padrão Q, R, F e G).

- **Habilidades:** cada uma existe uma vez, com características fixas. As básicas (Corte, Estocada, Pancada, Disparo, Soco) são o golpe da arma em mãos. Subindo proficiência destravam: **Corte giratório** (Lâminas 4), **Investida** (Hastes 4, avança 2,5 m), **Golpe esmagador** (Contundentes 4), **Tiro mirado** (Pontaria 4) e **Sequência de socos** (Desarmado 4).
- **Slots:** quanto maior o nível, mais slots. Nas básicas conta o domínio da arma (2 no domínio 6, 3 no 11). Nas destravadas conta o ramo dela: o Corte giratório ganha o 2º slot com Lâminas 8.
- **Objetos** vão nos slots e vêm da proficiência: Lâmina afiada, Força, Alcance, Rapidez, Impacto, Avanço, Emboscada, Golpe duplo e Perfurante. Cada cópia fica em uma habilidade por vez. Subir mais o ramo dá outra cópia (Força: nos níveis 3, 9 e 15 de Contundentes).
- **Qualquer objeto em qualquer habilidade onde faça sentido:** o Alcance da lança serve no Corte da espada. Só fica de fora o que não faz sentido, como sangramento num soco.
- **A ordem importa:** cada objeto age sobre o que está à esquerda dele. Lâmina afiada e depois Força deixa o sangramento mais forte; o contrário, não. O ◀ troca a ordem, e a prévia mostra o resultado na hora.
- Dá para editar as habilidades quando quiser, **fora de combate**. As mudanças valem na hora.
- Subir de nível avisa quando chega uma habilidade nova ou uma cópia nova de objeto. Os bônus passivos de nível 5 e 10 agora se chamam **talentos**, para não confundir.
- Se você morrer, o próximo aventureiro lembra como você montou as habilidades; o que ele ainda não destravou aparece trancado.
- Magia ainda não entrou. Quando entrar, os objetos dela também vão poder ir nas habilidades físicas.

## Novo: personagem PSX (14/10/2026)

O aventureiro agora é um personagem do pacote Characters PSX (Character_16, CC0), com a roupa repintada: túnica verde de lã, mangas de linho, braçadeiras e cinto de couro com fivela, alça de bolsa, calça marrom e botas. Rosto, mãos e cabelo são do original. Ele faz os mesmos movimentos de antes (andar, correr, golpes, estocada, esquiva, guarda, dano e morte) e segura as armas e veste as armaduras no mesmo lugar.

## Novo: filtro PSX (14/10/2026)

O jogo agora tem cara de PlayStation 1:

- A imagem do mundo sai em pixels grandes (cerca de 300 linhas, como os jogos de PS1), com cores reduzidas e pontilhado.
- As texturas não são suavizadas e os vértices tremem levemente quando a câmera anda, como no PS1.
- O HUD, as janelas e os nomes dos monstros continuam nítidos.
- **Esc → Filtro PSX** liga e desliga. A escolha fica salva. Começa ligado.

## Novo: armas com modelo de verdade (14/10/2026)

Os blocos provisórios das armas foram trocados por modelos dos pacotes que você mandou:

- **RPG Weapons** (Binbun, CC0): adaga, montante, machado, maça, martelo de guerra, lança e lança longa.
- **Low Poly Weapon Pack** (Kickin' It Studios): katana, alabarda, arco, besta, flechas e virotes.
- Nenhum pacote tinha uma katana de verdade; a "Offset Sword" (lâmina curva de um fio, guarda pequena, cabo longo) é a mais próxima.
- As lanças agora têm modelo do tamanho certo (2,6 m e 3,1 m) em vez do modelo curto esticado.
- A espada de viajante e a espada da guarda continuam com a espada própria do jogo. Armaduras e gazua seguem em blocos: nenhum pacote trouxe armadura vestível.
- Os ícones da mochila foram refeitos a partir dos modelos novos. Os créditos estão em `linux/CREDITOS.txt`.

## Novo: perícias no estilo Oblivion, ainda sem magia (14/10/2026)

A árvore de proficiências agora tem três grupos, como as perícias de Oblivion:

- **Combate:** Lâminas (espadas e adaga), Contundentes (maça, martelo e agora os machados), Hastes, **Desarmado**, **Bloqueio**, **Armadura pesada**, **Atletismo**.
- **Furtividade:** **Furtividade**, Pontaria (arco e besta), **Armadura leve**, **Acrobacia** (a antiga Esquiva) e **Arrombamento**.
- **Sobrevivência:** Tratamento.

O que mudou no jogo:

- **Socar:** sem arma em mãos, o botão esquerdo dá um soco (8 de dano, rápido e barato). Treina Contundentes › Desarmado.
- **Guarda:** segurar o botão direito com arma corpo a corpo (ou de punhos) segura 40% dos golpes que vêm de frente (25% com os punhos), gastando fôlego. Golpe pelas costas passa. Sem fôlego, a guarda quebra. A pancada em área do chefe não dá para segurar. Treina Bloqueio.
- **Armaduras:** gibão acolchoado e couro (leves), cota de malha e armadura de placas (pesadas). Vestir e tirar pelo inventário; a armadura aparece no corpo do personagem. As pesadas protegem mais, mas deixam o passo mais lento, o fôlego volta mais devagar e os monstros te notam de mais longe. O dano que a armadura absorve treina Armadura leve ou pesada, e o treino reduz essas desvantagens.
- **C para andar agachado:** passo lento e quase silencioso. Um monstro que te veria a 7,5 m só te nota a 3,75 m de frente, e a 2,25 m se você chegar por trás. Golpe agachado em quem não te viu: dano ×1,5 com qualquer arma (com a adaga, soma ao bônus dela). Treina Furtividade.
- **Correr** treina Atletismo, bem mais quando algo está te perseguindo.
- **Baús trancados:** parte dos baús vem com fechadura (simples, média, difícil ou de mestre), mais nos de tesouro e em andares fundos. O conteúdo fica escondido até você abrir. Com uma **gazua**, E tenta arrombar e mostra a chance; uma tentativa que falha pode quebrar a gazua. Você começa com 2 gazuas no abrigo. Treina Arrombamento.
- Cada novo ramo destrava um talento no nível 5 (alguns também no 10), por exemplo Guarda firme (bloquear gasta menos fôlego), Silenciosa (armadura leve sem barulho), Golpe pelas costas (ataque furtivo ×2) e Mão leve (gazuas quebram menos).

Ainda não entrou: magia e Alquimia, Reparo (precisa de desgaste por item), Comércio e Oratória (precisam de mercadores). Personagens sem arte própria para agachar e bloquear usam as animações de guarda e caminhada por enquanto.

## Novo: atributos e proficiências (14/10/2026)

- **Novo aventureiro:** no começo de cada run você distribui 25 pontos entre Força, Vigor, Agilidade e Destreza (de 2 a 9 cada) e escolhe a arma inicial. Eles mudam carga, vida, fôlego e esquiva, e definem quão rápido e até onde cada proficiência pode crescer.
- **Proficiências crescem com o uso:** acertar monstros treina o caminho da arma (por exemplo Lâminas › Espadas › Katana), esquivar de um golpe treina Acrobacia, tratar um ferimento treina Tratamento.
- **Domínio da arma:** cada nível dá +4% de dano e −2% de fôlego por golpe. Armas que compartilham a raiz se ajudam: praticar com a espada reta também adianta a katana.
- **Habilidades:** cada ramo desbloqueia uma habilidade no nível 5 ou 6, como Corte amplo (+1 alvo), Ferida funda (sangramento mais forte) e Recolher flechas.
- **P** abre a janela de proficiências. Ela não pausa o jogo. Um aviso no alto da tela mostra cada nível novo.
- Morrer leva o aventureiro junto: o próximo começa do zero, no mesmo labirinto e com o mapa que você já conhece.

## Novo: armas (14/10/2026)

Nove armas novas, ainda com modelo provisório de blocos:

- **Adaga:** rápida e barata; dano ×2,5 em monstro desprevenido (que ainda não te viu).
- **Katana:** corte rápido num arco estreito, até 2 alvos.
- **Montante:** duas mãos, arco largo, até 4 alvos e empurra; lento e cansativo.
- **Machado de guerra:** o monstro sangra 5 por segundo durante 5 s.
- **Maça de flanges:** atordoa quase 1 s e empurra; dano ×1,5 nos blindados (brutamontes, guardiões, chefe).
- **Martelo de guerra:** pancada no chão à frente que acerta todos na área.
- **Alabarda:** estocada longa que atravessa o primeiro inimigo.
- **Arco curto e besta:** ataque à distância com flechas e virotes. O que fica preso num monstro volta com os pertences dele; metade do que erra fica no chão para recolher.

As armas aparecem nos baús, mais nos de tesouro, nos covis e no relicário do chefe. Para testar todas de uma vez: **Esc → Arsenal de teste** coloca um baú com todas as armas e munição ao seu lado. É uma ferramenta de desenvolvimento e sai antes do lançamento.

## Novo: o labirinto (13/10/2026)

Cada expedição gera um labirinto a partir de uma semente. O 1º andar tem 10 salas; cada andar seguinte é maior (20, 40, 60…).

- **Abrigo** no 1º andar: E no ponto de descanso salva a expedição e entrega os selos que você trouxer.
- **Chefe do andar:** fica na sala mais distante, guarda o relicário com o selo e a **descida**. A descida só abre quando ele cai. Fique longe do anel vermelho no chão: é o golpe em área. Na metade da vida ele fica furioso.
- **Monstros:** corrompido, espreitador (rápido e frágil), brutamontes (lento e forte) e guardião de elite. Cada andar deixa todos mais fortes.
- **Itens novos:** espada da guarda, lança longa, unguento, tônico de fôlego, gemas.
- **Escadas:** SUBIDA e DESCIDA com E. Os baús abertos e os monstros mortos de cada andar continuam assim quando você volta.
- **Morte:** recomeça do zero no mesmo labirinto, mas o mapa que você explorou continua aparecendo. "Nova expedição" na pausa sorteia outro labirinto.
- Um save da versão anterior não é aproveitado: o jogo começa uma expedição nova.

## Jogar

Abra `linux/Dungepm.x86_64`. É um executável Linux independente; não precisa abrir a Godot nem programar.

Explore as cinco salas, gerencie comida e bandagens, encontre o selo e retorne ao abrigo. Os modelos próprios já estão no mapa jogável.

| Ação | Controle |
|---|---|
| Mover | WASD ou setas |
| Mirar / guarda | Segurar botão direito |
| Atacar na direção do cursor | Botão esquerdo |
| Correr | Shift |
| Esquivar | Espaço |
| Andar agachado | C |
| Interagir / abrir baú / arrombar | E, perto do alvo |
| Inventário | I ou Tab |
| Mapa explorado | M |
| Condição física | H |
| Barra rápida (qualquer item) | 1 a 9 |
| Proficiências | P |
| Habilidades: montar e trocar teclas | T |
| Habilidades: usar | Q, R, F, G (ou as que você escolher) |
| Aproximar / afastar câmera | Roda do mouse |
| Pausar | Esc |
| Salvar no abrigo | F5 |

O jogo salva também ao fechar a janela enquanto o personagem está vivo. Inventário, mapa e pausa interrompem a simulação nesta versão solo. Uma nova expedição pode ser iniciada pelo menu de pausa, com confirmação para substituir o progresso salvo.

## Esta entrega

- Biblioteca original de 23 modelos: aventureiro, corrompido, armas, pedra modular e objetos medievais.
- Texturas próprias, caminhada no esqueleto original e golpe de espada, reação de dano e morte adaptados do Mixamo.
- Câmera ortográfica com elevação de aproximadamente 30°, paredes de frente recortadas e iluminação de tochas.
- Mobília com colisão e caminhos de navegação atualizados.
- Inventário por peso, equipamento, coleta, alimento, bandagens, ferimentos, monstros e objetivo de extração.
- Godot: 87 verificações de integração passaram (consulte `VERIFICACAO.md`).

## Fontes editáveis

`Dungepm-fonte.zip` reúne o projeto Godot, a fonte Blender, o gerador de modelos, texturas, documentação e planejamento. O projeto de trabalho está em `/home/murilo/Documentos/ChatGPT/Game`.

As referências consultadas estão em `arte/REFERENCIAS.md` dentro do pacote. Nenhum asset foi comprado. A biblioteca atual foi criada para este jogo. Modelos Kenney do bloco antigo não entram nesta exportação.

## Limites atuais

Primeiro protótipo visual, com repetição de materiais e animações ainda simples. Paredes usam corte fixo, não oclusão dinâmica. A dungeon tem layout fixo, cinco salas e sete monstros. Não há geração procedural, áudio final, classes, progressão completa ou sistema de técnicas nesta entrega.

Próxima etapa sugerida: refinar peso do movimento e ataque, melhorar ocultação de paredes e preencher as salas com detalhes de uso e desgaste.

## HUD no estilo Project Zomboid — 13/10/2026

- **Barra lateral** (esquerda): mochila, condição física, mapa e pausa, com a tecla de cada um.
- **Mochila e Arredores** (alto): recolhidas, mostram peso com barra e o recipiente mais próximo; clique ou I para abrir. Abertas, viram tabelas com ícone de cada item, categoria, quantidade e peso. Clique no cabeçalho para ordenar.
  - **Clique duplo**: usa, equipa ou guarda a arma (mochila) e pega a pilha (arredores).
  - **Botão direito**: menu com as ações do item.
  - **Arrastar** entre as janelas: pega ou guarda a pilha inteira.
  - **Guardar em baús**: agora dá para deixar itens em baús, não só tirar. Baús vazios também abrem com E.
  - Abas à direita da janela Arredores alternam entre os recipientes próximos.
  - Passe o mouse sobre um item para ver peso, efeito e, nas armas, dano, alcance, fôlego, preparação e alvos.
- **Condição** (alto à direita): vida, fôlego, saciedade e carga com barras. Clique para abrir a janela de condição.
- **Indicadores de estado** (lateral direita): aparecem só quando a situação existe no jogo — sangrando, ferido, com fome, ofegante/exausto, carga pesada, perseguido, no abrigo, selo recuperado. A dica de cada um mostra a regra real.
- **Condição física** (H): aba Saúde com silhueta, barras e tratamentos; aba Personagem com arma, área, objetivo e contadores. Não pausa o jogo.
- **Em mãos** (embaixo à esquerda), **barra rápida** 1-2-3 com quantidades, aviso de ação com a tecla, mensagens e borda vermelha com vida baixa.
- Fonte Inter (licença livre) e ícones dos itens gerados a partir dos modelos do próprio jogo.

## Gameplay atualizada

Movimento com aceleração e frenagem curtas. O personagem olha para onde anda; ao segurar o botão direito, passa a mirar no cursor. Correr durante a mira é bloqueado. Recuar em guarda é mais lento.

A espada corta numa faixa ampla e pode atingir até três inimigos. A lança faz uma estocada estreita e acerta o primeiro alvo. Um clique nos últimos instantes da recuperação fica guardado para executar o próximo golpe. Acertos e ferimentos têm reação, recuo e som; o impacto pode interromper a preparação de um golpe.

Monstros mostram a direção do ataque e têm recuperação após atacar. Quando perdem a visão do jogador, investigam a última posição conhecida por um tempo curto. O marcador de mira destaca um alvo próximo do cursor e distingue alcance disponível.

Cinco sons próprios provisórios acompanham passos, arma, acerto, ferimento e coleta. Abra Esc para desligar o som.

O personagem usa golpe de espada, estocada adaptada, reação e morte do pacote Sword And Shield Pack do Mixamo, adaptados ao nosso esqueleto. Caminhada e corrida continuam próprias para evitar o cruzamento dos pés. Veja a fonte e a licença em `jogo/ASSETS.md` dentro do pacote.

A lança tem estocada de 3,2 m: preparo, extensão e recuo, com haste longa e dano somente no primeiro alvo da faixa estreita.
