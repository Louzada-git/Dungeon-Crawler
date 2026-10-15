# Escopo da versão 1.0 — em definição

Etapa 3. Decisões construídas com o usuário.

## Confirmado

- **Sempre single player.** Decisão explícita do usuário em 13/10/2026. Vale para a versão 1.0 e para a direção permanente do projeto.
- **Plataformas de lançamento: Windows e Linux**, usando o projeto Godot existente. As duas builds precisam ser exportadas e verificadas em seus respectivos sistemas.
- **Controles de lançamento: somente teclado e mouse.** Suporte a controle não integra o escopo da versão 1.0.
- **NPCs e companheiros controlados por IA.** O grau de autonomia e as ordens que o jogador poderá dar serão definidos em conjunto.
- **Experiência extremamente longa.** O jogador pode ter a impressão de que o jogo é endless. Ordem de grandeza indicada pelo usuário: **100 a 200 horas para concluir uma run**. Estrutura de conclusão e condição de final continuam sem definição.
- **Forma do labirinto (etapa 4, decidida em 13/10/2026): longo, com fundo, não infinito.** Os andares crescem de forma aproximadamente exponencial — por exemplo 10 → 20 → 40 → … → 100 → 200 → 400 salas — até andares que exigem cerca de 20 horas de jogo para atravessar. A curva exata será ajustada em teste.
- **Técnicas (decidido em 15/10/2026):** primeiro só técnicas físicas, a magia entra depois; montar e trocar técnicas em qualquer lugar fora de combate; componentes destravam só pela proficiência (não por achados). As receitas criadas contam como conhecimento e sobrevivem à morte.
- **Consequência da morte (etapa 5, decidida em 13/10/2026): roguelite com memória.** Ao morrer, a run recomeça do zero na **mesma semente**: o mundo volta ao estado inicial e o jogador começa com um personagem novo, sem itens nem proficiências. **O conhecimento do jogador permanece:** mapa já explorado, passagens secretas descobertas, NPCs conhecidos, o que cada item e cada opção faz e receitas de técnicas já descobertas. O jogador recomeça fraco, porém mais esperto.
- O labirinto pertence à partida local do jogador e é definido por uma semente própria.

## Consequências das decisões de morte e labirinto

- O save passa a ter duas partes: o **estado da run** (personagem, itens, mundo alterado), que é apagado na morte, e o **conhecimento persistente**, que sobrevive a ela. Isso entra na etapa 9.
- Itens e opções precisam de um registro de conhecimento: o que o jogador já descobriu sobre eles. O formato desse registro será especificado nas etapas 20 e 62.
- Andares de centenas de salas tornam obrigatório o carregamento de setores sob demanda (etapa 36) e o teste de desempenho desde a etapa 35.

## A definir juntos

- **Núcleo obrigatório × metas de conteúdo × lista pós-lançamento.** Separar o que a 1.0 não pode deixar de ter do que tem meta numérica ajustável e do que pode vir em atualização. Fecha a etapa 3.
- **Idiomas de lançamento.** Português confirmado como base; decidir se inglês ou outros idiomas entram na 1.0. Os textos serão preparados por chave desde a etapa 8, qualquer que seja a decisão.
- Estrutura de campanha, condição de conclusão e continuidade após o final: discussão adiada por decisão do usuário.
- Extensão do conteúdo inicial da versão 1.0, preservando a intenção de uma experiência extremamente longa.
- Quantidade de inimigos, guardiões, itens, proficiências e componentes. Proposta: revisar na etapa 30, com o resultado da fatia vertical, e fixar antes da etapa 62.
- Papel, quantidade, autonomia e possíveis ordens dos companheiros controlados por IA. Proposta: reavaliar o tamanho desse sistema na etapa 30, porque ele é um dos mais caros do plano.

As metas numéricas do plano de 100 etapas continuam propostas até serem confirmadas neste documento.
