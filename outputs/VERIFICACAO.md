# Verificação — modelos próprios integrados

Data: 10/10/2026.

- Godot 4.7.2, renderizador GL Compatibility; Blender 5.2.0.
- Importação dos 23 GLBs concluída sem erro de recurso ou script.
- Testes do projeto: **74 verificações, zero falhas**.
- Testes do executável Linux exportado: **74 verificações, zero falhas**.
- Incluem colisão real contra catre, movimentação contra paredes, cinco salas conectadas, rotas para todos os recipientes, ataques dos monstros, direção e alcance dos golpes, inventário, alimento, bandagem, coleta, peso, equipar/descartar, pausa, mapa, salvamento/carregamento e conclusão da incursão.
- Verificação visual na GPU AMD/OpenGL: abrigo, combate, inventário, mapa e estudo de arte renderizados. Orientação da espada corrigida após inspeção do personagem.
- Rig, mão direita e animações idle/walk/attack/die carregam no jogador; animação de ataque carrega no monstro.
- Exportação não contém arquivos do pacote Kenney; biblioteca ativa é `assets/originais`.
- Sem benchmark formal de desempenho ou validação em outros sistemas operacionais nesta etapa.

Logs completos da execução de desenvolvimento ficam em `work/` no projeto local.

## Atualização do HUD

Capturas conferidas em 1440×900 e 1280×800. Inventário em tabela, seleção e transferência preservados. Atalhos H e 2 verificados pelo fluxo de eventos da engine; H abre o painel sem pausar, 2 consome uma ração e recupera saciedade. Nenhum erro de script nos testes ou nas capturas.

## Movimento e combate

74 verificações passaram no executável exportado atualizado. As verificações novas cobrem resolução única de dano, primeiro alvo da lança, cone estreito, preparação sem dano antecipado, arma e direção comprometidas durante o ataque, entrada guardada na recuperação, orientação ao caminhar e frenagem ao soltar movimento. As nove ações de animação carregam no jogador.

Capturas de gameplay verificadas em OpenGL após a importação. Sons são provisórios e originais; a avaliação de qualidade sonora continua dependente de ouvir em diferentes dispositivos.

## Golpe de espada Mixamo — 13/10/2026

O golpe próprio foi substituído por `sword and shield slash (3).fbx`, do pacote Sword And Shield Pack. O movimento foi adaptado ao esqueleto do aventureiro e à espada presa à mão direita. As fases de preparo, impacto e recuperação foram capturadas em OpenGL. O dano continua resolvido após a preparação. Projeto e executável: **81 verificações, zero falhas**.

## Integração Mixamo — 13/10/2026

Duas animações do pacote Sword And Shield Pack continuam ativas no aventureiro: impacto e morte. Caminhada e corrida foram refeitas no esqueleto próprio após inspeção quadro a quadro mostrar cruzamento dos pés com a adaptação Mixamo. O corte de espada ganhou rotação do tronco, passo, mudança de punho e sincronização com a janela de dano. Importação Godot concluída sem erro. A suíte do projeto passou com **80 verificações, zero falhas**, incluindo caminhada e corrida próprias, corte alinhado à arma e reação Mixamo durante o jogo, além de física, inventário, combate e salvamento. Capturas de repouso, movimento, lança e três fases do corte renderizadas em OpenGL após a integração.

## Estocada longa — 13/10/2026

Base Mixamo `attack (4)` com braços adaptados para empurrar a lança em linha reta. Haste alinhada à direção do ataque. Capturas de preparo, impacto e recuo conferidas. Testes cobrem alvo a 3,05 m, alvo lateral, além do alcance, atrás do jogador e primeiro alvo bloqueando o segundo. Projeto e executável: **87 verificações, zero falhas**.
