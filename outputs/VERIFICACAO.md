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

## HUD no estilo Project Zomboid — 13/10/2026

- Interface refeita em `jogo/scripts/ui/` (um arquivo por painel). `ui.gd` ficou só com a montagem e a API usada pelo jogo e pelos testes.
- Suíte ampliada para **145 verificações, zero falhas**, no projeto (Godot 4.7.2 headless) e no **executável Linux exportado** com o novo HUD.
- Novas verificações: ícone para todos os itens, fonte carregada, cada indicador de estado ligado à regra real (sangramento, níveis de ferimento, fome, fôlego abaixo da esquiva e do custo da arma, carga, perseguição, abrigo), painel e barra rápida mostrando os valores atuais, guardar em baú e arrastar nos dois sentidos conservando quantidades, pilha única ao deixar vários itens no mesmo lugar, baú vazio que pode ser aberto, menu de contexto, ordenação, peças do HUD dentro da tela e sem sobreposição, janelas abertas sem cobrir condição e indicadores, janela arrastada mantendo o título na tela.
- Arrastar e soltar testado também com eventos reais de mouse na janela renderizada.
- Capturas conferidas em 1280×800 e 1440×900, renderizadas por software (Mesa llvmpipe, OpenGL 4.5) numa tela virtual: exploração, aviso de ação, inventário com dica, menu de contexto, arrasto, condição com indicadores, aba Personagem, mapa, pausa, barra rápida e final.
- Ainda falta o teste humano: sensação de uso, tamanho das letras na sua tela e velocidade das dicas.

## Etapas 7 e 8 — Git e organização — 13/10/2026

- Git local com histórico: estado recebido → plano e HUD → organização.
- Itens, monstros e mundo saem do código para `jogo/data/`; recipientes e monstros ganham ids fixos; `main.gd` cai de 500 para 250 linhas, com os sistemas em `scripts/systems/`.
- Suíte com **216 verificações, zero falhas**. Novas: catálogos completos e traduzidos, armas com números coerentes, mundo com ids únicos e tudo sobre o piso, monstros usando os dados do tipo, mundo mínimo escrito à mão gerando rotas (base para o gerador procedural) e save antigo sem ids carregando.
- Comparação de capturas antes e depois: o mundo renderizado é o mesmo.

## Labirinto procedural — 13/10/2026

- Gerador validado em 240 andares (60 sementes × 4 andares): toda sala, baú, monstro e escada alcançável a partir do início; um chefe e um selo por andar; ids únicos; mesma semente gera o mesmo andar e sementes diferentes geram andares diferentes. 7 ms (1º andar) a 91 ms (4º andar) por geração.
- Montagem em jogo: 1º andar instantâneo, 3º andar (40 salas, 69 monstros) em 0,12 s, 4º andar (60 salas, 139 monstros) em 0,25 s, sem queda de quadros na física.
- Suíte do labirinto: **37 verificações, zero falhas** — andar validado em jogo, descida selada com o chefe vivo, golpe em área acertando ao redor, fúria, barra do chefe, relicário com o selo, descida e subida, chegada nos lugares certos, vida dos monstros por andar, mistura de tipos, baú esvaziado e monstro morto continuam assim ao voltar, save versão 2 ida e volta, entrega de selo, morte apagando o save da expedição e guardando semente e mapa, tela de recomeço.
- Suíte do mundo fixo: **242 verificações, zero falhas**.
- Capturas renderizadas: abrigo gerado, sala de combate, golpe em área do chefe, chefe furioso, mapa do andar, descida aberta, 2º andar, tela de morte.
- Recomeço após a morte conferido: mesma semente e mapa explorado carregados.
- Falta: teste humano, equilíbrio de dano e quantidade de monstros, e desempenho em placa de vídeo real.

## Armas novas — 14/10/2026

- Projeto restaurado a partir do pacote entregue em 13/10 e conferido antes de mexer: 242 + 37 verificações, zero falhas. Histórico do Git reconstruído a partir dos três pacotes (original, HUD, labirinto).
- Suíte do mundo fixo: **341 verificações, zero falhas**; suíte do labirinto: **38, zero falhas**; as duas também no executável Linux exportado.
- Novas verificações: toda arma tem modelo (blocos quando não há .glb) e é segurada pelo personagem; adaga ×2,5 em monstro desprevenido e normal depois; katana em até dois alvos; machado abre sangramento de 5/s que termina no tempo certo e pode matar; maça ×1,5 em blindado, normal em comum, e atordoa mais; martelo acerta toda a área à frente e nada atrás; alabarda atravessa um e acerta o segundo; montante em arco largo; arco não dispara sem flechas, gasta uma por disparo, a flecha voa, acerta a 6 m, fica presa e volta com os pertences; metade das flechas que erram fica no chão; besta atravessa dois; munição presa sobrevive ao save; dica do martelo; arsenal de teste; flecha em voo some ao trocar de andar.
- Gerador revalidado com as tabelas de saque novas (90 andares, zero problemas). Em 100 sementes, todo 1º andar tem pelo menos uma arma além da espada inicial (média de 3,5 armas e 13 flechas ou virotes).
- Capturas conferidas: todas as armas em mãos, ícones gerados dos blocos, besta em uso, dica completa da besta, arco na mão esquerda.
- Falta: modelos e animações finais (outra IA, conforme `arte/ARMAS_ESPEC.md`) e o teste humano do equilíbrio.

## Atributos e proficiências — 14/10/2026

- Suíte do mundo fixo: **382 verificações, zero falhas**; suíte do labirinto: **41, zero falhas**; as duas também no executável Linux.
- Verificações novas: divisão da experiência sem contar duas vezes; mesmo domínio com um ou dois ramos em 12 rodadas seguidas; espada reta ajudando a katana pela raiz; Força 9 aprendendo ×1,32 e chegando ao nível 46; ramo parando no nível máximo; monstro raso quase sem ensinar a quem domina; habilidades mudando a katana (alvo extra, preparo mais curto); domínio aumentando dano e reduzindo fôlego; golpe, sangramento, esquiva e tratamento ensinando os ramos certos; curativo sem ferimento sem ensinar nada; aviso de nível; atributos mudando mochila, vida, fôlego e custo da esquiva; save com atributos e mochila acima de 18 kg; janela de proficiências; domínio na dica da arma; regras do painel de criação; save do labirinto com o aventureiro e conhecimento sem proficiências após a morte; golpe no labirinto ensinando.
- Simulação do ritmo com o código do jogo, na semente 777 (70% dos monstros e o chefe de cada andar). Domínio (bônus de dano):

| Andar | Adaga | Katana | Martelo | Martelo, Força 9 | Espada reta → Katana no 3º |
| --- | --- | --- | --- | --- | --- |
| 1 (11 mortes) | 6 (+10%) | 6 (+10%) | 6 (+10%) | 7 | 4 |
| 2 (22 mortes) | 10 (+18%) | 10 (+18%) | 10 (+18%) | 11 | 8 |
| 3 (46 mortes) | 14 (+26%) | 14 (+26%) | 14 (+26%) | 15 | 13 |
| 4 (95 mortes) | 18 (+34%) | 18 (+34%) | 18 (+34%) | 19 | 18 |
| 5 (166 mortes) | 22 (+42%) | 22 (+42%) | 22 (+42%) | 23 | 21 |
| 6 (345 mortes) | 25 (+48%) | 25 (+48%) | 25 (+48%) | 26 | 25 |
| 7 (688 mortes) | 29 (+56%) | 29 (+56%) | 29 (+56%) | 30 | 29 |

Repetir o 1º andar (1x → 6, 2x → 8, 5x → 10, 10x → 11, 20x → 12, 50x → 14) mostra que monstros fracos param de ensinar; na prática os monstros não renascem, então isso só pesaria se voltarem a existir.
- Capturas conferidas: painel de novo aventureiro, janela de proficiências com dica de ramo e aviso de nível.
- Falta: teste humano do ritmo e os números das habilidades.

## Perícias no estilo Oblivion, sem magia — 14/10/2026

- Suíte do mundo fixo: **452 verificações, zero falhas**; suíte do labirinto: **47, zero falhas**; as duas também no executável Linux.
- Verificações novas no mundo fixo: Lâminas, Contundentes e Pontaria como raízes; ramos agrupados em Combate, Furtividade e Sobrevivência; save antigo com Esquiva virando Acrobacia e ramo desconhecido descartado; golpe ensinando Lâminas, Espadas e Espada reta na divisão 40/35/25; soco sem arma (8 de dano, ensina Desarmado, mais forte no nível 5); guarda segurando 40% de frente, gastando fôlego, sem interromper e ensinando Bloqueio; golpe pelas costas passando; pancada do chefe não bloqueável; guarda quebrando sem fôlego; guarda de punhos com 25%; arco sem guarda; Bloqueio nível 10; vestir a cota pelo inventário e vê-la no tronco; proteção, lentidão e barulho da cota; armadura absorvendo e ensinando Armadura pesada; guarda e armadura somando (20 → 12 → 9); mochila marcando a armadura vestida; dica da armadura; armadura vestida no save; Armadura pesada nível 10 protegendo mais e pesando menos; couro sem perder velocidade; Armadura leve nível 5 silenciosa; largar a armadura tirando-a do corpo; corrida ensinando Atletismo cinco vezes mais quando perseguido; Atletismo nível 5; indicador de furtivo; animações de furtivo com reserva; detecção agachado de frente (metade) e por trás (30%); monstro real a 5 m sem notar quem passa agachado e ensinando Furtividade; limite de furtividade por monstro; o mesmo monstro notando de pé; ataque furtivo ×1,5 com espada ensinando Furtividade; Furtividade nível 10; baú trancado pedindo gazua, escondendo o conteúdo e recusando retirar itens; chance de 40% numa fechadura média; tentativa falha com e sem quebra da gazua; fechadura cedendo e abrindo o baú; abrir ensinando mais que tentar; chances por dificuldade; Arrombamento nível 10; fechadura no save; save com fechadura inválida recusado.
- Verificações novas no labirinto: baús em jogo com as fechaduras da descrição do andar; baú arrombado continuando aberto ao voltar ao andar e o outro continuando trancado; em 12 andares gerados, 31% dos baús trancados, relicário do chefe nunca trancado, fechaduras do 3º andar mais difíceis que as do 1º (média 2,43 contra 1,90).
- As fechaduras usam um gerador próprio: as sementes antigas geram os mesmos andares, monstros e saque de antes.
- Simulação do ritmo atualizada para os caminhos novos (semente 777, 70% dos monstros e o chefe de cada andar). Domínio:

| Andar | Adaga (2 ramos) | Katana (3) | Martelo (2) | Punhos (1) | Martelo, Força 9 | Espada reta → Katana no 3º |
| --- | --- | --- | --- | --- | --- | --- |
| 1 (9 mortes) | 5 | 5 | 5 | 5 | 6 | 5 |
| 2 (21 mortes) | 10 | 10 | 10 | 10 | 11 | 9 |
| 3 (47 mortes) | 14 | 14 | 14 | 14 | 15 | 14 |
| 4 (94 mortes) | 18 | 18 | 18 | 18 | 19 | 18 |
| 5 (163 mortes) | 21 | 21 | 21 | 21 | 23 | 21 |
| 6 (343 mortes) | 25 | 25 | 25 | 25 | 26 | 25 |
| 7 (696 mortes) | 29 | 29 | 29 | 29 | 30 | 29 |

Caminhos de um, dois ou três ramos andam no mesmo ritmo. Trocar de espada no 3º andar agora quase não custa nada, porque Lâminas e Espadas são compartilhadas.
- Capturas conferidas: as quatro armaduras no corpo, guarda e furtivo com os indicadores, aviso "Arrombar · 20% de chance", baú trancado, baú aberto, dica da cota de malha, janela de proficiências agrupada (início, meio e fim) com dica de ramo.
- Falta: animações próprias de soco, guarda e agachado (outra IA, conforme `arte/ARMAS_ESPEC.md`), modelos finais das armaduras e o teste humano do equilíbrio.

## Armas com modelos de pacotes — 14/10/2026

- Suíte do mundo fixo: **465 verificações, zero falhas**; suíte do labirinto: **47, zero falhas**; as duas também no executável Linux.
- Verificação nova: cada uma das 13 armas e munições carrega o modelo real (não os blocos), no comprimento da ficha (±2 cm) e com a empunhadura na origem.
- Licenças conferidas: RPG Weapons é CC0 (página do autor, o pacote não traz o arquivo); o leia-me do Low Poly Weapon Pack permite uso em jogos e proíbe revenda.
- Conversão conferida em vista frontal e lateral com eixos: ponta em +Y, fio do machado e da alabarda em +X, corda do arco em −X, empunhadura no cabo.
- Capturas conferidas: as 12 armas na mão (espada, katana, montante, adaga, machado, maça, martelo, lança, lança longa, alabarda, arco, besta), besta em uso e ícones novos. Lanças e martelo foram afinados depois da primeira captura.

## Filtro PSX — 14/10/2026

- Suíte do mundo fixo: **477 verificações, zero falhas**; suíte do labirinto: **47, zero falhas**; as duas também no executável Linux.
- Verificações novas: filtro entre o 3D e o HUD; tamanho do pixel conforme a janela; personagem, monstros, chão e paredes em lote com materiais PSX; anéis e marcadores intocados; arma equipada com o filtro ligado convertida no quadro seguinte; nome do monstro como rótulo 2D; botão da pausa desligando; materiais e texto originais de volta; preferência salva; rótulos 2D sumindo; religar reaplicando tudo.
- Capturas conferidas lado a lado (sem e com filtro): abrigo, sala com monstro, perto do personagem e inventário aberto. A primeira versão pegava um só pixel por bloco e quebrava as juntas finas do piso em pontinhos; agora cada bloco é a média dos pixels. O nome do monstro, que virava um borrão vermelho, agora é desenhado nítido acima do filtro.
- O tremido dos vértices só aparece em movimento; conferir jogando.

