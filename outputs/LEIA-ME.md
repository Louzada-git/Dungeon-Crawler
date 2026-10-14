# Dungepm — As Cisternas

## Novo: atributos e proficiências (14/10/2026)

- **Novo aventureiro:** no começo de cada run você distribui 20 pontos entre Força, Vigor, Agilidade e Destreza (de 2 a 9 cada). Eles mudam carga, vida, fôlego e esquiva, e definem quão rápido e até onde cada proficiência pode crescer.
- **Proficiências crescem com o uso:** acertar monstros treina o caminho da arma (por exemplo Espadas › Katana), esquivar de um golpe treina Esquiva, tratar um ferimento treina Tratamento.
- **Domínio da arma:** cada nível dá +2% de dano e −1% de fôlego por golpe. Armas que compartilham a raiz se ajudam: praticar com a espada reta também adianta a katana.
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
| Mirar | Segurar botão direito |
| Atacar na direção do cursor | Botão esquerdo |
| Correr | Shift |
| Esquivar | Espaço |
| Interagir / abrir baú | E, perto do alvo |
| Inventário | I ou Tab |
| Mapa explorado | M |
| Condição física | H |
| Comer / usar bandagem | 2 / 3 |
| Abrir equipamento | 1 |
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
