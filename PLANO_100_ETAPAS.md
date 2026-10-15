# Plano de produção — 100 etapas até uma versão pronta para a Steam

**Revisão:** 13/10/2026 (reorganização do plano original da mesma data)  
**Projeto:** Dungepm (nome provisório)  
**Ponto de partida:** protótipo Godot 4.7.2 em 3D com câmera isométrica, movimentação, combate com espada e lança, inventário por peso, mapa descoberto, salvamento, modelos próprios e uma incursão de cinco salas fixas. Linha de base reconfirmada em 13/10/2026: **87 verificações, zero falhas** em execução headless. Nenhuma etapa é marcada como concluída só porque existe uma implementação provisória.

## Visão e regra de conclusão

Jogo solo de sobrevivência e exploração em tempo real. Cada jogador tem um labirinto procedural próprio, definido por uma semente e persistente entre incursões. Atributos definem potencial; proficiências adquiridas pelo uso liberam habilidades. Uma ação pode treinar vários ramos e receber contribuições de todos os ramos aplicáveis: espada + katana + escola rápida; magia + elementalismo + fogo. Técnicas físicas e mágicas aceitam componentes em espaços compatíveis. Equipamentos têm categorias, propriedades e usos distintos. O visual usa modelos 3D estilizados com câmera isométrica e interface legível. Detalhes em [VISAO_JOGO.md](VISAO_JOGO.md) e [ESCOPO_V1.md](ESCOPO_V1.md).

O objetivo da etapa 100 é uma **versão 1.0 completa, estável e apta a ser lançada na Steam**. Pagar a taxa, enviar para revisão e publicar dependem da conta do titular e das decisões comerciais dele.

## O que mudou nesta revisão

1. **Os sistemas se encontram cedo.** O plano anterior construía labirinto, proficiências, técnicas e itens um depois do outro, cada um por inteiro, e só os juntava perto da etapa 60. Agora uma **fatia vertical** (13–30) une todos em miniatura. Isso responde se o núcleo é divertido antes de produzir conteúdo em escala.
2. **Pessoas jogam em todos os marcos:** etapas 6, 29, 46, 68, 79 e 91. Antes, testadores externos só entravam na 85.
3. **Decisões que travam etapas foram antecipadas:** forma do labirinto (4), idiomas e tamanho da 1.0 (3) e regra de morte (5). As etapas 4 e 5 já foram decididas.
4. **Infraestrutura antes da expansão:** Git (7), separação de dados (8), save versionado (9) e build Windows testada (10). Antes, Windows só era testado na 89 e migração de save só aparecia na 82.
5. **A direção visual e o pipeline de arte vêm antes do conteúdo em massa** (48–49; antes, 71), para não refazer modelos.
6. **Steamworks e a página "Em breve" ficam no meio** (50–52), não no fim, para acumular listas de desejos.
7. As etapas **1, 2, 3 e 5 mantêm número e conteúdo**, e as referências nos outros documentos continuam válidas. A tabela de modelos e esforço saiu do plano.

As etapas têm tamanhos diferentes: decidir a regra de morte cabe numa conversa, enquanto chegar à meta de itens é um bloco grande de produção. **Os marcos medem o progresso; o número da etapa, não.** A lista mostra dependências, não uma agenda fixa. Itens de loja podem andar em paralelo, respeitando os prazos da Steam.

## Trabalho antecipado a pedido do usuário

- **13/10/2026 · HUD no estilo Project Zomboid — entregue.** Interface de exploração, inventário, condição física, mapa, pausa e final refeita com desenho próprio, seguindo a organização do Project Zomboid. Inclui janelas recolhíveis e arrastáveis, ícones gerados dos modelos, ordenação, menu de contexto, arrastar entre janelas, guardar em baús, indicadores de estado ligados às regras reais e fonte Inter (OFL). Antecipa partes das etapas 42 (inventário) e 84 (interfaces) e já separa o `ui.gd` por painel, parte da etapa 8. Verificação: 145 checagens no projeto e no executável Linux. Falta o teste humano.

- **13/10/2026 · Labirinto procedural — primeira versão entregue.** Andares gerados por semente (10, 20, 40, 60… salas), tipos de sala, mobília, saque por tabela, quatro tipos de monstro com força por profundidade, chefe por andar com golpe em área e fúria, escadas entre andares com estado guardado por andar, selos entregues no abrigo e a regra de morte (recomeça no mesmo labirinto mantendo o mapa). Cobre o essencial das etapas 9, 14, 15, 16, 27, 31, 32, 33 e 34 e parte da 36 (andares leves com MultiMesh e monstros que dormem longe). Verificação: gerador validado em 240 andares; suítes de 242 e 37 checagens. Falta o teste humano e o equilíbrio.

- **14/10/2026 · Armas novas com modelo provisório.** Adaga, katana, montante, machado, maça, martelo, alabarda, arco e besta, com flechas e virotes. Cada uma tem uma mecânica própria por dados (furtivo, sangramento, esmagar armadura, pancada em área, perfurar, projéteis) e indica o ramo de proficiência que vai treinar. Modelos de blocos substituíveis por `.glb`; especificação de modelos e animações em `arte/ARMAS_ESPEC.md`. Antecipa parte das etapas 20, 38 e 64.

- **14/10/2026 · Personagem PSX.** O aventureiro passa a ser o `Character_16` do Characters PSX (Elbolilloduro, CC0), com textura repintada e as animações anteriores transferidas para o rig Mixamo (`arte/fontes/personagem_psx/`).

- **14/10/2026 · Filtro PSX.** O dono do projeto gosta do estilo de PlayStation 1. Primeiro passo: filtro de pós-processamento e materiais com vértices presos à grade, ligável na pausa (`scripts/systems/psx_filter.gd`). Próximos passos possíveis, ainda não pedidos: labirinto com o PSX Dungeon (Goblinatron, CC BY 4.0), monstros do Characters PSX e efeitos do Brackeys VFX. Antecipa parte da etapa 47 (direção visual).

- **14/10/2026 · Armas com modelos de pacotes.** RPG Weapons (Binbun, CC0) e Low Poly Weapon Pack (Kickin' It Studios) no lugar dos blocos, convertidos por `arte/fontes/converter_armas.gd`. Antecipa parte da etapa 64.

- **14/10/2026 · Perícias no estilo Oblivion, sem magia.** Árvore em grupos (Combate, Furtividade, Sobrevivência) com Lâminas e Pontaria como raízes; Desarmado, Bloqueio com guarda no botão direito, armaduras leves e pesadas com Armadura leve/pesada, Atletismo, Furtividade (C agacha, ataque furtivo), Acrobacia (antiga Esquiva) e Arrombamento com baús trancados e gazuas. Antecipa parte das etapas 42 (armaduras básicas), 53 (árvore), 64 (escudo/guarda) e 65 (armaduras). Ficaram para depois: magia, Alquimia, Reparo, Comércio e Oratória.

- **15/10/2026 · Câmera em terceira pessoa.** Opção na pausa: câmera atrás do personagem com o mouse, paredes inteiras, névoa e mira no centro; a isométrica continua o padrão. Toca a etapa 48 (direção visual): vale decidir mais à frente qual das duas é a principal.

- **15/10/2026 · Barra rápida e teclas.** Barra rápida de 9 espaços (teclas 1 a 9) com qualquer item; teclas da barra de habilidades escolhidas pelo jogador (padrão Q, R, F, G; teclado numérico vale); delay do peso (0,1 s por kg antes do próximo golpe) e danos reacertados. Antecipa parte da etapa 85 (troca de teclas).

- **15/10/2026 · Atualização depois do primeiro teste com jogadores.** Fôlego com gastos pela metade e recuperação ×1,3; delay depois do golpe pelo peso da arma (pesadas com delay alto) e esquiva na metade dele; firmeza dos monstros contra atordoamento em cadeia; danos das armas e vida e dano dos monstros rebalanceados (`jogo/BALANCO.md`, `jogo/tools/tabela_balanco.py`). Avança a etapa 39 (combate base) e começa a 46 (teste com pessoas de fora).

- **15/10/2026 · Ajustes do dono do projeto.** +5 pontos de atributo (25), arma inicial à escolha (qualquer arma ou punhos), soco como contundente (Desarmado dentro de Contundentes), um objeto para cada um dos 25 ramos, recuperação depois do golpe em um terço e bônus por nível de domínio dobrado. Amplia a etapa 23 (16 objetos novos) e antecipa parte da 59 (biblioteca de componentes).

- **15/10/2026 · Efeitos visuais.** Sangue, clarão, faíscas, golpe forte, poeira, fumaça e chamas animadas das tochas e da fogueira nova do abrigo, com o Brackeys VFX Bundle (CC0) reduzido para o tamanho PSX (`scripts/systems/vfx.gd`, `data/efeitos.json`). O dono do projeto liberou o uso de todos os pacotes enviados; o PSX Modular Medieval (kit de vila) foi inventariado e ainda não entrou. Antecipa parte das etapas 39 (sinais visuais de impacto, defesa e esquiva) e 83 (efeitos).

- **14/10/2026 · Atributos e proficiências.** Etapas 17, 18 e 19 concluídas; habilidades por nível de ramo antecipam parte da 26, e a janela de proficiências, parte da 28. Técnicas montáveis continuam nas etapas 21 a 25.

## Marcos

| Etapa | Marco | Pergunta que o marco responde |
| --- | --- | --- |
| 12 | Fundação confiável | O projeto está versionado, com builds nas duas plataformas, save protegido e decisões bloqueantes tomadas? |
| 30 | Fatia vertical | Labirinto + proficiências + técnicas + itens, juntos e pequenos, são divertidos? |
| 46 | Labirinto longo | Várias incursões seguidas num mundo persistente se sustentam? |
| 52 | Página no ar | O jogo tem identidade, visual definido e presença na Steam? (decisão do titular) |
| 68 | Builds | Estilos diferentes de personagem completam o mesmo desafio por caminhos diferentes? |
| 80 | Conteúdo completo | Todos os sistemas prometidos e a estrutura de longo prazo estão acessíveis? |
| 90 | Acabamento | Recursos congelados, apresentação completa, saves e combinações testados em escala? |
| 100 | Versão 1.0 | Build candidata aprovada nos critérios internos e nos fluxos da Steam? |

## Decisões em aberto e onde elas bloqueiam

| Decisão | Situação | Precisa estar decidida antes de |
| --- | --- | --- |
| Núcleo obrigatório da 1.0 × lista pós-lançamento | Etapa 3 | 13 |
| Idiomas de lançamento | Etapa 3 | 51 (página) e 77 (textos); a etapa 8 já prepara textos por chave |
| Forma do labirinto | **Decidida** (etapa 4): longo, com fundo, andares exponenciais | — |
| Consequência da morte | **Decidida** (etapa 5): roguelite com memória | — |
| Metas numéricas de conteúdo | Propostas | Revisão na 30; fixar antes da 62 |
| Tamanho do sistema de companheiros na 1.0 | Confirmados no escopo; papel, autonomia e ordens em aberto | 71. Proposta: reavaliar na 30, com o resultado da fatia |
| Final, história e condição de conclusão | Adiados por decisão do usuário | 76 |

## 1–12 · Fundação e decisões que travam o resto

1. **Inventariar o protótipo — concluída em 13/10/2026.** [Diagnóstico e evidências](INVENTARIO_PROTOTIPO.md): 87 verificações passaram no projeto e no executável Linux; duas lacunas de persistência foram reproduzidas (A e B).
2. **Definir a promessa do jogo — concluída em 13/10/2026.** [Visão de uma página](VISAO_JOGO.md).
3. **Fixar o escopo da versão 1.0 — em andamento.** [Decisões de escopo](ESCOPO_V1.md). Já confirmados: sempre single player; Windows e Linux; teclado e mouse; experiência extremamente longa; NPCs e companheiros controlados por IA. Falta: separar o núcleo obrigatório das metas de conteúdo e da lista pós-lançamento, e decidir os idiomas de lançamento.
4. **Decidir a forma do labirinto — concluída em 13/10/2026.** Longo, com fundo, não infinito: 100 a 200 horas para concluir uma run. Andares crescem de forma aproximadamente exponencial (10 → 20 → 40 → … → 400 salas) até andares de cerca de 20 horas. Final e condição de conclusão continuam adiados. Ver [ESCOPO_V1.md](ESCOPO_V1.md).
5. **Decidir a consequência da morte — concluída em 13/10/2026.** Roguelite com memória: a run recomeça do zero na mesma semente, com mundo no estado inicial e personagem novo; o conhecimento do jogador (mapa explorado, passagens secretas, NPCs, o que itens e opções fazem, receitas) permanece. A correção da lacuna B segue essa regra na etapa 9.
6. **Testar a sensação da base atual.** O usuário joga o build Linux existente e registra o que incomoda em controle, câmera, combate, inventário e ritmo. As verificações automáticas provam que as regras funcionam, não que o jogo é divertido.
7. **Versionar o projeto — concluída em 13/10/2026 (local).** Git na raiz do projeto, com `.gitignore` para cache da Godot, `work/`, executáveis e backups `.blend1`. Histórico começa no estado recebido. Falta: repositório privado no GitHub para trabalhar de qualquer máquina.
8. **Separar dados, regras e cenas — concluída em 13/10/2026, exceto textos da interface.** Itens, monstros e o mundo em `jogo/data/`; recipientes e monstros com ids fixos; `main.gd` dividido em sistemas e `ui.gd` em painéis; textos de conteúdo por chave. Os textos da interface vão para chaves depois da decisão de idioma. Mapa em `jogo/ARQUITETURA.md`.
9. **Versionar e proteger o save.** Número de versão do formato, migração, backup recuperável e restauração por identificador em vez de índice. Separa o estado da run, apagado na morte, do conhecimento persistente. Corrige a lacuna A e aplica a regra da etapa 5, encerrando a lacuna B.
10. **Automatizar builds Linux e Windows.** Exportação sem caminhos absolutos, versão registrada em cada build e teste de fumaça no Windows desde já.
11. **Criar um roteiro de teste repetível.** Suíte automática headless mais uma lista curta de verificação manual, rodadas em cada marco.
12. **Ajustar a base conforme o teste da etapa 6.** Corrigir movimento, câmera, leitura dos golpes e inventário antes de construir em cima.

**Marco 12 — fundação confiável.**

## 13–30 · Fatia vertical: o jogo inteiro em miniatura

13. **Fechar a lista e o ciclo da fatia.** Conteúdo pequeno e fechado: um andar de 6 a 10 salas, duas famílias de monstros, Espadas › um tipo › uma escola, Magia › Elementalismo › Fogo, 3 ou 4 componentes, cerca de 15 itens. Ciclo: base → incursão → retirada ou morte → nova incursão. Nada além disso entra na fatia.
14. **Gerar um andar por semente.** A mesma semente reconstrói o mesmo andar; o caminho entrada → objetivo → retorno é garantido em toda semente aceita.
15. **Popular o andar por regras.** Salas de combate, recurso e repouso; monstros e recipientes distribuídos pelo gerador, não posicionados à mão.
16. **Persistir o andar.** Portas, baús, inimigos, mapa descoberto e alterações sobrevivem ao save, com a versão do gerador registrada.
17. **Ligar atributos ao que já existe — concluída em 14/10/2026.** Força, Vigor, Agilidade e Destreza, escolhidos no início de cada run. Três ou quatro atributos que alteram vida, carga, fôlego e potencial de treino, substituindo constantes atuais.
18. **Modelar as proficiências numa planilha — concluída em 14/10/2026** como simulação com o código real (`tests/progression_sim.gd`). Simular, antes de programar, a divisão do progresso entre ramos, a soma de contribuições sem dupla contagem, a igualdade de ritmo e a regra contra grind.
19. **Implementar as proficiências da fatia — concluída em 14/10/2026** para todas as armas, Esquiva e Tratamento. Os dois ramos da etapa 13, com experiência por uso relevante e persistência.
20. **Criar etiquetas de itens.** Tipo, material, peso, alcance e afinidades ligam itens a proficiências e técnicas. O treino por tipo de arma depende delas.
21. **Definir a ficha de técnica — concluída em 15/10/2026** (`data/tecnicas.json`). Alcance, origem do dano, tempo, custo, alvo, animação, requisitos e espaços como dados verificáveis.
22. **Converter os golpes atuais em técnicas — concluída em 15/10/2026**: corte, estocada, pancada, disparo e soco são as formas básicas. Corte e estocada viram fichas, sem perder o comportamento já ajustado e testado.
23. **Implementar espaços e componentes mínimos — concluída em 15/10/2026, sem o fogo** (nove objetos físicos; a ordem altera o resultado; o imbuimento de fogo espera a magia). Três ou quatro componentes, incluindo imbuimento de fogo; a ordem altera o resultado de forma previsível.
24. **Implementar a magia mínima.** Uma magia pura e uma de fogo, cada uma treinando os ramos corretos.
25. **Montar técnicas e equipar na barra — concluída em 15/10/2026** (janela de habilidades T, barra 4 a 7, só fora de combate; objetos com cópias, slots pelo nível do ramo). Editor mínimo com validação, custo e motivo de incompatibilidade.
26. **Liberar algo por domínio — concluída em 15/10/2026** (formas e componentes por nível de ramo; espaços pelo domínio da arma). Pelo menos um componente e uma técnica destravados por proficiência.
27. **Fechar o ciclo de incursão.** Retirada ou morte, retorno à base e nova incursão no mesmo labirinto. Na morte, a run recomeça na mesma semente e o conhecimento acumulado aparece no mapa e nas descrições.
28. **Criar uma interface mínima para proficiências e técnicas.** Pode ser feia, mas precisa ser compreensível.
29. **Testar a fatia com pessoas.** O usuário e de três a cinco pessoas de fora jogam. Medir se entendem as combinações, se escolhem caminhos diferentes e se querem voltar.
30. **Decidir pelo resultado.** Definir o que fica, muda ou sai; revisar metas de conteúdo, tamanho do sistema de companheiros e o [ESCOPO_V1.md](ESCOPO_V1.md).

**Marco 30 — o núcleo é divertido?** Mudar de rumo aqui custa pouco.

## 31–46 · Labirinto, combate e sobrevivência em escala

31. **Estruturar andares e setores** com o crescimento aproximadamente exponencial decidido na etapa 4.
32. **Gerar ramificações e atalhos persistentes** que criem escolhas de rota.
33. **Completar os tipos de sala:** evento, segredo, repouso e guardião.
34. **Escalar ameaças e recompensas por profundidade** sem saltos impossíveis.
35. **Fixar metas de desempenho.** FPS, memória, carregamento e configuração mínima, medidos a partir daqui.
36. **Carregar setores sob demanda** dentro dessas metas.
37. **Testar milhares de sementes automaticamente.** Detectar mapas impossíveis, gargalos, sobreposição e repetição excessiva.
38. **Padronizar alcance e colisões.** Espada, lança, projéteis, magias e paredes seguem as mesmas regras espaciais.
39. **Fechar o combate base.** Defesa, esquiva, impacto e recuperação com sinais visuais e sonoros claros.
40. **Criar estados de ferimento** legíveis e tratáveis.
41. **Balancear fôlego, carga, comida, cura e luz** para que pressionem a expedição inteira, não cada combate.
42. **Melhorar inventário e equipamento.** Comparar, transferir, equipar e descartar sem ambiguidade; armaduras básicas.
43. **Melhorar o mapa** com marcos e anotações, sem revelar o desconhecido.
44. **Criar famílias de monstros.** Comum, rápida e resistente ou de área, cada uma com sinais e fraquezas próprios.
45. **Criar a base segura funcional.** Guardar, reparar, preparar técnicas e escolher a próxima incursão num fluxo curto.
46. **Testar com pessoas de fora.** Incursões longas em vários andares; medir mortes, retiradas e pontos de confusão.

**Marco 46 — labirinto longo jogável.**

## 47–52 · Identidade, direção visual e loja

47. **Dar identidade própria ao projeto.** Nome, mundo, símbolos, monstros e lore originais; revisar semelhanças diretas com as obras de inspiração.
48. **Fixar a direção visual.** Escala, paleta, materiais, silhuetas e leitura, antes de modelar dezenas de itens e monstros.
49. **Definir o pipeline de arte.** Gerador Blender, texturas, convenções de nome e equipamentos modulares (como um item aparece no personagem).
50. **Iniciar o cadastro no Steamworks e a janela comercial.** O titular conclui verificação, dados bancários e fiscais e taxa quando decidir. O prazo de 30 dias da Steam começa a correr aqui.
51. **Preparar a página "Em breve".** Nome, descrição fiel, idiomas, requisitos de sistema e capturas reais.
52. **Publicar a página** e começar a acumular listas de desejos, por decisão do titular. Adiar este passo não bloqueia as etapas seguintes.

**Marco 52 — presença na Steam.**

## 53–68 · Progressão, técnicas e itens em escala

53. **Completar a árvore de proficiências.** Raízes, especializações, escolas e tipos de equipamento como ramos sobrepostos, com requisitos de desbloqueio.
54. **Criar o treino das escolas de espada:** real, brutal, fluida, rápida e pesada, cada uma avançando pelas ações correspondentes.
55. **Criar o treino dos tipos de espada:** leve, katana, pesada e outras, crescendo pelo equipamento efetivamente usado.
56. **Completar a magia pura.** Técnicas arcanas exercitam a raiz de Magia e têm valor próprio.
57. **Completar o elementalismo.** Fogo, vento e outros elementos com efeitos distintos além da quantidade de dano.
58. **Unir combate físico e magia.** Esgrima + Elementalismo produz técnicas híbridas utilizáveis e treináveis.
59. **Ampliar a biblioteca de componentes.** Avanço, ruptura de guarda, ampliação de arco e outros, com ordem e interações previsíveis.
60. **Completar o editor de técnicas.** Nomear, duplicar, comparar, modificar e recuperar receitas após carregar o jogo.
61. **Validar a igualdade de ritmo em simulação.** Com esforço comparável, o dano da habilidade praticada cresce no mesmo ritmo total, mesmo fortalecendo ramos diferentes.
62. **Definir as categorias de itens.** Armas, armaduras, consumíveis, materiais, focos, componentes, relíquias e itens de missão, cada uma com regras próprias.
63. **Criar modelos-base de itens.** Gerar variações de dados a partir de bases, sem transformar cada item numa cópia numérica.
64. **Criar outras famílias de armas.** Lança, arco, escudo e foco mágico participam da progressão e das combinações.
65. **Criar armaduras e acessórios** com compensações de proteção, mobilidade, resistência e espaços.
66. **Criar consumíveis, materiais, relíquias e itens singulares.** Efeitos especiais mudam estratégias sem invalidar equipamentos comuns.
67. **Atingir a meta de itens do escopo.** Proposta atual: pelo menos 200 entradas nomeadas, ou o número revisto na etapa 30, cada uma com utilidade, obtenção e diferenças verificadas.
68. **Testar a diversidade de builds com pessoas de fora.** Pelo menos cinco estilos viáveis completam a mesma incursão por meios diferentes.

**Marco 68 — combinações e itens sustentam builds.**

## 69–80 · Mundo, companheiros e estrutura de longo prazo

69. **Criar a economia de expedição.** Saque, gasto e manutenção incentivam risco calculado sem obrigar repetição vazia.
70. **Criar inimigos de elite e guardiões** que testem posicionamento, preparo e adaptação de build.
71. **Criar NPCs e companheiros controlados por IA,** com funções e custos diferentes, conforme o tamanho definido nas etapas 3 e 30.
72. **Criar comandos e comportamento do grupo.** Aliados seguem, lutam, recuam e administram perigo de forma legível.
73. **Equilibrar a progressão longa.** Simular dezenas de horas de experiência, profundidade e economia para manter tensão sem muro de grind.
74. **Criar descobertas e objetivos** que conduzam o jogador a setores mais profundos.
75. **Criar o início e a curva de dificuldade.** Os setores iniciais ensinam na prática; os avançados exigem domínio dos sistemas.
76. **Implementar a estrutura de longo prazo.** Aplicar a forma da etapa 4 e o final ou a condição de conclusão, quando o usuário decidir.
77. **Preparar textos e localização.** Português consistente; outros idiomas conforme a decisão da etapa 3.
78. **Combater a repetição.** Medir, em partidas longas, salas, encontros e recompensas repetidos e acrescentar variação onde a sensação de jogo sem fim se perde.
79. **Testar uma partida longa do início ao fim** sem ferramentas de desenvolvimento, com pessoas de fora.
80. **Validar a versão de conteúdo completo.** Todos os sistemas prometidos e a estrutura de longo prazo estão acessíveis.

**Marco 80 — conteúdo completo.**

## 81–90 · Apresentação e acabamento

81. **Completar os equipamentos modulares.** Os equipamentos principais aparecem nos personagens sem exigir um modelo inteiro para cada combinação.
82. **Completar as animações essenciais.** Locomoção, escolas de golpe, dano, magia, morte e interação correspondem às regras.
83. **Completar efeitos e áudio.** Impactos, elementos, ambiente e interface comunicam a ação sem esconder perigos.
84. **Finalizar as interfaces.** Proficiências, editor de técnicas, inventário e mapa claros e rápidos de usar.
85. **Concluir a acessibilidade básica.** Remapeamento de teclas, escala de texto, volumes separados e sinais que não dependam só de cor.
86. **Concluir opções e retomada.** Gráficos, áudio, controles e saves funcionam depois de fechar e reabrir o jogo.
87. **Atualizar a página e o trailer** com o visual final.
88. **Congelar os recursos da 1.0.** Novas ideias vão para a lista futura; correções e acabamento têm prioridade.
89. **Testar saves e migrações.** Carregar saves de todas as versões já testadas, recuperar falhas e preservar labirinto e técnicas.
90. **Testar geração e combinações em escala.** Milhares de sementes e partidas simuladas, mais casos extremos de componentes, custos e progressão.

**Marco 90 — acabamento.**

## 91–100 · Qualidade e lançamento

91. **Testar o equilíbrio com um grupo externo amplo.** Medir mortes, retiradas, builds usadas, itens ignorados e pontos de confusão.
92. **Corrigir travamentos e bloqueios.** Nenhum erro conhecido impede avançar, salvar, retornar ou concluir.
93. **Otimizar o desempenho** até as metas da etapa 35 nos computadores alvo.
94. **Revisar originalidade e licenças.** Nomes, arte, áudio, fontes, modelos, animações (incluindo Mixamo), Godot, créditos e permissões de distribuição.
95. **Preparar a candidata a lançamento.** Builds limpas instaladas e conferidas no Windows e no Linux; versão, notas, backup e plano de correção rápida.
96. **Concluir o questionário de conteúdo e a página.** Informar violência e eventual conteúdo gerado com IA usado no jogo; atualizar requisitos e capturas.
97. **Configurar depots e testar em ramo privado.** Envio pelo SteamPipe; convidados instalam, jogam, salvam e atualizam pela distribuição real.
98. **Enviar a build para revisão** e atender os apontamentos da Valve.
99. **Fazer a verificação final e aprovar a candidata.** Jogo completo, estabilidade, saves, direitos, créditos, loja, preço, suporte e plano de atualização; o titular aprova build e página.
100. **Entregar o jogo completo pronto para lançamento na Steam.** Build 1.0 testada, conteúdo prometido presente, página e build aprovadas nos fluxos aplicáveis; o titular pode acionar a publicação.

## Como trabalhamos

- Antes de cada etapa, o assistente apresenta em poucas linhas **o que será feito, o que ficará verificável no fim e as escolhas que precisam de aprovação**, e espera o "sim" do usuário.
- Dentro de uma etapa aprovada, as correções e os testes necessários fazem parte da execução. Mudanças relevantes de direção voltam para aprovação.
- Cada etapa termina com a suíte headless da Godot 4.7.2 passando, os testes novos que a etapa exigir, um commit (a partir da etapa 7) e este plano atualizado.
- Este arquivo, o [ESCOPO_V1.md](ESCOPO_V1.md) e a [VISAO_JOGO.md](VISAO_JOGO.md) são os documentos vivos. O [PLANEJAMENTO_JOGO.md](PLANEJAMENTO_JOGO.md) está congelado como histórico.

## Dependências da Steam consultadas em 13/10/2026

- [Steam Direct](https://partner.steamgames.com/steamdirect/): taxa de US$ 100 por produto; para os primeiros títulos, espera de 30 dias após o pagamento e página "Em breve" pública por pelo menos duas semanas antes do lançamento.
- [Processo de lançamento](https://partner.steamgames.com/doc/store/releasing): página e build têm checklists e revisões separados; a página é enviada antes da build, e o titular aciona a publicação quando estiver pronto.
- [Questionário de conteúdo](https://partner.steamgames.com/doc/gettingstarted/contentsurvey): inclui conteúdo maduro e conteúdo gerado por IA que integra o jogo.
- [SteamPipe](https://partner.steamgames.com/doc/sdk/uploading): ferramenta de envio e teste de builds e depots.

Conferir esses requisitos novamente na etapa 50 e antes da 96, pois os procedimentos da plataforma podem mudar.
