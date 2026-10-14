# Dungepm — As Cisternas

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

## HUD compacto

Interface atualizada conforme a captura enviada: tabela de inventário no alto à esquerda, painéis escuros translúcidos, indicadores nas bordas e painel corporal opcional. Ícones originais desenhados no próprio jogo. O centro da tela fica livre durante a exploração.

## Gameplay atualizada

Movimento com aceleração e frenagem curtas. O personagem olha para onde anda; ao segurar o botão direito, passa a mirar no cursor. Correr durante a mira é bloqueado. Recuar em guarda é mais lento.

A espada corta numa faixa ampla e pode atingir até três inimigos. A lança faz uma estocada estreita e acerta o primeiro alvo. Um clique nos últimos instantes da recuperação fica guardado para executar o próximo golpe. Acertos e ferimentos têm reação, recuo e som; o impacto pode interromper a preparação de um golpe.

Monstros mostram a direção do ataque e têm recuperação após atacar. Quando perdem a visão do jogador, investigam a última posição conhecida por um tempo curto. O marcador de mira destaca um alvo próximo do cursor e distingue alcance disponível.

Cinco sons próprios provisórios acompanham passos, arma, acerto, ferimento e coleta. Abra Esc para desligar o som.

O personagem usa golpe de espada, estocada adaptada, reação e morte do pacote Sword And Shield Pack do Mixamo, adaptados ao nosso esqueleto. Caminhada e corrida continuam próprias para evitar o cruzamento dos pés. Veja a fonte e a licença em `jogo/ASSETS.md` dentro do pacote.

A lança tem estocada de 3,2 m: preparo, extensão e recuo, com haste longa e dano somente no primeiro alvo da faixa estreita.
