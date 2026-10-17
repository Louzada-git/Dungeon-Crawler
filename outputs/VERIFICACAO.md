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

## Personagem PSX — 14/10/2026

- Suíte do mundo fixo: **478 verificações, zero falhas**; suíte do labirinto: **47, zero falhas**; as duas também no executável Linux.
- Verificação nova: arma presa à mão do rig Mixamo com a correção de posição; as verificações existentes de animações (idle, guarda, andar, correr, golpe, estocada, esquiva, dano, morte), armadura no tronco e filtro PSX passam com o personagem novo.
- Textura: cada pixel foi ligado à sua posição 3D no corpo (pose de repouso com a pele aplicada) e repintado por região; vistas de frente e de lado conferidas.
- Animações: o modelo antigo e o novo foram renderizados lado a lado no mesmo quadro de dez animações, cada um com uma haste presa à mão como as armas; as poses e a direção da haste batem.
- Capturas conferidas: as 12 armas na mão, as quatro armaduras e a sala com e sem filtro.
- As armaduras de blocos ficam um pouco largas no corpo mais magro; são provisórias.

## Técnicas — 15/10/2026

- Suíte do mundo fixo: **517 verificações, zero falhas**; suíte do labirinto: **48, zero falhas**; as duas também no executável Linux.
- Verificações novas: fichas carregadas; formas conforme a arma; Corte sem componentes igual ao golpe normal; forma, componente e arma errados dizem o motivo; proficiência destrava; espaços pelo domínio (3 no domínio 11); ordem dos componentes mudando o sangramento (3,9 contra 3,0) e o preparo; recarga somada por componente; componente repetido e que não combina recusados; salvar e pôr na barra; usar contra monstro com o dano montado e o sangramento; recarga impedindo e liberando; componente treinando seu ramo; Corte giratório acertando atrás; Golpe duplo acertando duas vezes; Investida avançando 2,5 m; técnica de corte recusada na lança; editor listando, prevendo e mudando a ordem; editor travado com monstro caçando e liberado fora de combate; pôr na barra salvando a nova; esquecer tirando da barra; barra mostrando a recarga; dica da barra; tecla 4 do teclado; save com técnicas e barra; save estranho limpo; receitas sobrevivendo à morte com a barra vazia.
- Capturas conferidas: editor com prévia, Corte giratório acertando com a recarga na barra, editor travado em combate.
- Falta: teste humano dos números (dano, fôlego, recarga) e de quais componentes valem a pena.

## Habilidades e objetos (modelo do dono do projeto) — 15/10/2026

- Suíte do mundo fixo: **520 verificações, zero falhas**; suíte do labirinto: **48, zero falhas**; as duas também no executável Linux.
- Verificações do modelo novo: cópias de Força nos níveis 3 e 9 de Contundentes; Corte com 1 slot que vira 3 no domínio 11; Corte giratório destravado e com slots pelo nível de Lâminas; Alcance (das hastes) numa habilidade de espada; Lâmina afiada recusada em pancada e soco e aceita em flecha; segunda cópia de Força em outra habilidade; uso acima das cópias recusado com o motivo; cada habilidade num lugar só da barra; ordem, recarga, treino, giro, golpe duplo, investida e lança recusando corte como antes; janela listando todas as habilidades, trocando ordem, tirando e pondo objetos, travada em combate e sem pôr habilidade trancada na barra; barra e dica; aviso de habilidade nova ao subir de nível; tecla 4; save; save do formato anterior e save estranho lidos sem quebrar; montagem sobrevivendo à morte com a barra vazia.
- Captura conferida: janela com Corte (Lâmina afiada, Força e Alcance), cópias livres de cada objeto e habilidades trancadas com o requisito.

## Organização dos arquivos — 15/10/2026

- Pedido do dono do projeto: o que não importa para jogar fica fora do arquivo do jogo.
- Capturas de revisão foram de `outputs/` para `revisao/` e vão num pacote próprio. `outputs/` ficou com o executável Linux, o guia de jogo e esta verificação.
- Modelos antigos do Kenney (fora de uso) foram para `arte/historico/kenney/`; o modelo anterior do aventureiro, que só serve de fonte das animações, foi para `arte/fontes/personagem_psx/origem_animacoes/`.
- O executável não leva mais testes, ferramentas nem documentos. As suítes rodam pelo projeto: **520 verificações** no mundo fixo e **48** no labirinto, zero falhas. O executável foi aberto e rodou sem erros; pedir os testes a ele responde que eles não vão no jogo exportado.
- `empacotar.sh` gera quatro pacotes: `Dungepm-linux.tar.xz` (jogar), `Dungepm-jogo.zip` (projeto da Godot), `Dungepm-revisao.zip` (capturas) e `Dungepm-documentos-e-arte.zip` (planejamento, verificação e fontes de arte).

## Efeitos visuais — 15/10/2026

- Suíte do mundo fixo: **543 verificações, zero falhas**; suíte do labirinto: **50, zero falhas**.
- Verificações novas: todo efeito com folha pequena e curta; tochas com chama animada e material único; fogueira no abrigo com luz; luzes tremendo sem passar da força original; andar contra a fogueira para ao lado dela (0,64 m) e ainda deixa descansar; acerto comum com sangue e clarão, sem estouro forte; estouro forte em atordoamento forte e ataque furtivo; faíscas no blindado e sangue quando a arma esmaga a armadura; gotas durante o sangramento; faíscas na guarda do lado de onde veio o golpe; sangue no aventureiro ferido; poeira na esquiva; fumaça na morte; filtro PSX sem trocar o material dos efeitos; efeitos que somem sozinhos; no labirinto, tochas e fogueira no 1º andar e luzes tremendo no 2º, sem fogueira.
- Capturas conferidas (`revisao/efeitos/`): tochas, fogueira, sangue, golpe forte, faíscas e poeira, anel de poeira, fumaça e sangramento, e o mesmo acerto sem o filtro. Ajustes feitos depois de olhar: poeira e fumaça clareadas (escuras pareciam sombra), sangue subido para o peito, chama da tocha aditiva, maior e acima do copo da tocha.
- Falta: ver os efeitos em movimento, jogando, e decidir se o sangue fica do jeito que está (vermelho vivo).

## Ajustes do dono do projeto — 15/10/2026

- Pedido: +5 pontos de atributo, soco como contundente, objeto para todas as proficiências, arma inicial à escolha, recuperação depois do ataque em um terço e o dobro do bônus por nível.
- Suíte do mundo fixo: **574 verificações, zero falhas**; suíte do labirinto: **50, zero falhas**.
- Verificações novas: criação com 25 pontos e 5 livres, limite total e por atributo, 13 armas mais punhos com a espada marcada, katana escolhida no lugar da espada, besta com 20 virotes, punhos treinando Contundentes › Desarmado; Desarmado dentro de Contundentes, soco treinando os dois ramos e recebendo o talento Atordoar, Golpe esmagador de mãos vazias; 25 objetos para 25 ramos; Ponto vital antes da Força rendendo mais, Talho fundo multiplicando o sangramento do machado e sem efeito sem sangramento, Tremor só em pancada, Fresta ×1,4 na espada, Saraivada com três projéteis, Bálsamo curando 2 por acerto e aparecendo na prévia; janela com todos os objetos, os que você tem primeiro e com rolagem; preparo igual e recuperação, lentidão e trava em um terço, animação no mesmo ritmo, esquiva liberada antes do tempo antigo; domínio 6 com +20% de dano e −10% de fôlego, Acrobacia e Bloqueio com o dobro por nível.
- Capturas conferidas: criação com 5 pontos livres gastos e a katana escolhida; janela de proficiências com Desarmado dentro de Contundentes e a katana em mãos (+28% no domínio 8); janela de habilidades com os objetos novos e a rolagem.
- Falta: jogar para sentir o ritmo novo do combate. Com um terço da recuperação e o dobro do bônus por nível, o personagem fica bem mais forte, e os monstros ainda não foram ajustados.

## Atualização depois do teste com jogadores — 15/10/2026

- Pedidos: fôlego (gastos pela metade, recuperação ×1,3), delay alto nas armas pesadas, esquiva a partir da metade do delay, danos balanceados.
- Suíte do mundo fixo: **585 verificações, zero falhas**; suíte do labirinto: **50, zero falhas**.
- Verificações novas: golpe inteiro como nos dados (preparo, delay, lentidão); esquiva travada até a metade do delay e liberada depois, cortando a lentidão; animação acertando no fim do preparo; armas pesadas com delay mais que o dobro do da espada e leves com menos; fôlego das armas, objetos e talentos pela metade; esquiva 12,5, guarda metade do dano segurado, corrida 8/s; fôlego voltando cerca de 20,8 por segundo; primeiro golpe atordoa e deixa o monstro firme; monstro firme leva dano sem perder o ataque; passada a firmeza, o golpe volta a interromper; numa luta de verdade, 3 s golpeando sem parar com a espada (6 golpes) e o monstro ainda acerta duas vezes; dica do martelo com peso, delay, esquiva e fôlego.
- As verificações das armas agora leem o dano dos dados, em vez de números fixos.
- Tabela de balanço (`jogo/BALANCO.md`, gerada por `jogo/tools/tabela_balanco.py`): dano por segundo num alvo entre 35 (arco) e 49 (espada da guarda), soco 24; um corrompido do 1º andar cai em 1,5 a 2,2 s de golpes com qualquer arma.
- Captura conferida: dicas da adaga, espada, martelo e besta com peso, preparo, delay e esquiva. Descrições de itens que citavam o fôlego antigo foram corrigidas.
- Falta: jogar de novo. A firmeza deixa o combate bem mais difícil do que na versão testada, porque agora o monstro termina o ataque mesmo apanhando.

## Barra rápida, teclas das habilidades e delay do peso — 15/10/2026

- Pedidos: barra de 1 a 9 com qualquer item; teclas das habilidades escolhidas pelo jogador (não números, teclado numérico pode); delay depois do ataque pelo peso da arma (0,1 s por kg), só para golpear.
- Suíte do mundo fixo: **622 verificações, zero falhas**; suíte do labirinto: **50, zero falhas**.
- Verificações novas: 9 espaços com arma, rações e bandagens no começo; barra cabendo na tela sem cobrir o cartão da arma; tecla 2 come; katana em qualquer espaço equipa e, de novo, guarda; tecla 1 volta à espada; armadura veste e tira; munição só mostra a quantidade; espaço vazio explica; pilha acabada mostra 0; arrastar da mochila põe e tira do espaço antigo; mochila aberta + item selecionado + número põe sem usar; menu do item mostra a posição e põe no primeiro livre; botão direito tira; save e save estranho; teclas Q, R, F, G; número de cima, E e T recusados com o motivo; Num 1 aceito, troca de lugar com o outro espaço, fica salva, aparece na barra e usa a habilidade; tecla 4 não usa mais habilidade; janela T espera a tecla, aceita V, cancela com Esc, recusa número com o motivo e mostra as teclas nos botões; lista de controles com as teclas atuais; martelo com +0,65 s até o próximo golpe, sem golpe mas com esquiva nesse tempo; dica do martelo com o delay do peso.
- Capturas conferidas (`revisao/barra/`): barra com arma, comida, katana, arco com flechas, armadura vestida, tônico e unguento, e as teclas Q, Num 1, F, G; janela T esperando a tecla do 3º espaço; lista de controles.
- Tabela de balanço refeita com o delay do peso (`jogo/BALANCO.md`): dano por segundo num alvo de 24 a 33, soco 18; um corrompido cai em 2 a 3,4 s de golpes.

## Câmera em terceira pessoa — 15/10/2026

- Pedido: opção de câmera em terceira pessoa normal.
- Suíte do mundo fixo: **640 verificações, zero falhas**; suíte do labirinto: **50, zero falhas**.
- Verificações novas: começa isométrica com as paredes da frente cortadas; botão da pausa liga a terceira pessoa (perspectiva, câmera ativa), paredes inteiras e névoa; escolha salva; mira no centro e cursor preso; mochila e janela T soltam o cursor; W anda para onde a câmera olha e D para a direita dela; mirar, golpear e esquivar seguem a câmera; mouse gira, com limite para cima e para baixo; roda do mouse com limite; com uma parede atrás, o braço da câmera encolhe (0,4 m) em vez de atravessar; volta para a isométrica com câmera, paredes, névoa, mira e teclas como antes.
- Capturas conferidas (`revisao/terceira/`): abrigo com a fogueira, sala com monstro, câmera girada e o mesmo lugar na isométrica. Ajuste depois de olhar: câmera mais baixa e mais perto (1,55 m de ombro, braço 3,3 m, inclinação −15°), porque na primeira versão ela via por cima das paredes.
- Falta: jogar com mouse de verdade para acertar a sensibilidade (0,0035 rad por pixel) e ver se a terceira pessoa pede ajuste de combate (alcance, mira das flechas).

## Cursor, animações, loja, itens, nomes e acerto por toque — 16/10/2026

- Pedidos: cursor de volta nos menus da terceira pessoa; refazer animações e rigs (golpes, andar/correr/esquiva, monstros, pegada das armas); loja no início de cada andar; 50 itens de todos os tipos; tirar os selos e itens inúteis; nomes e descrições menos com cara de IA; golpe acertando por hitbox da arma contra o corpo, do jogador e dos monstros.
- Suíte do mundo fixo: **949 verificações, zero falhas**; suíte do labirinto: **53, zero falhas**.
- Verificações novas do acerto por toque: distância entre segmentos e toque entre cápsulas; cápsula da espada da empunhadura à ponta do modelo; alcance mostrado de todas as armas corpo a corpo e dos punhos igual ao medido da hitbox; preparo da espada atrás das costas sem acerto; estocada sem acerto ao lado da haste; lâmina do sabre passando pela frente no impacto; soco acerta ao alcance do punho e não além; Corte giratório leva a lâmina à volta inteira; Braço longo estica a lâmina; rastro da lâmina; garra do monstro só à frente dele, acertando na distância de ataque, sem acertar atrás nem além do alcance; o bote (`lunge`) é o que leva a garra até a distância de ataque, e o modelo avança junto; recuar durante o preparo escapa da garra na máquina de estados real; marreta acerta dois monstros onde a cabeça desce e nenhum longe dela; lança acerta até a ponta do modelo e não além.
- Testes antigos de área (alcance linear da lança a 3,05 m, marreta acertando num círculo) foram reescritos para a geometria do modelo.
- Capturas conferidas (`revisao/hitbox/`): cápsulas de cada arma ao longo do golpe, coincidindo com o modelo na mão no momento do impacto (verde); garra dos monstros com o bote; rastro da lâmina; monstro se jogando no golpe. Ajustes depois de olhar: o sabre tinha o impacto cedo demais (lâmina atrás do ombro), passou para 0,79 da animação; a cápsula da haste começa na mão (a ponta de trás da lança acertava quem estava atrás); o preparo atrás das costas deixou de contar.
- Capturas da loja (`revisao/loja/`) e das animações novas (`revisao/animacoes/`).
- Falta: jogar para sentir as armas curtas (adaga, faca, maça, machado), que agora precisam chegar a menos de 1,5 m do monstro.

## Revisão das animações — 16/10/2026, à noite

- Pedido: conferir se as animações estavam certas e corrigir o que não estivesse.
- Revisão quadro a quadro (`jogo/tests/auditoria_capture.gd` e `jogo/tools/auditoria_folhas.py`): 31 animações do aventureiro com a arma de cada golpe, 8 de cada monstro e 2 do mercador, de lado e de frente, 8 quadros cada.
- Problemas achados e corrigidos: arma balançando solta ao andar e correr; guarda com a arma pendurada para trás; armas longas entrando no chão parado; golpe de espada enterrando a lâmina no chão; florete sem estocada (usava o soco); funda lançada com a mão esquerda; garra dos monstros com o braço subindo reto.
- Sem mudança (conferidos): soco, adaga, sabre, machado, maça, montante, marreta, lança, alabarda, arco, besta, bloqueio, agachado, esquiva, dano, morte, monstros parados, andando, correndo, dano, morte e a pancada do capataz.
- Alcance medido de novo (`tools/medir_alcance.gd`) e bote dos monstros recalibrado (`tools/calibrar_bote.gd`).
- Suíte do mundo fixo: **951 verificações, zero falhas**; suíte do labirinto: **53, zero falhas**. Na primeira tentativa, o corte novo da espada alcançava só 1,3 m e nove verificações falharam (monstro a 1,5 m); o corte ganhou um passo à frente e voltou a 1,5 m.
- Capturas: antes e depois em `revisao/animacoes-correcao/`; `revisao/animacoes/` e `revisao/hitbox/` refeitas com as animações novas.
