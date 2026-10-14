# Plano de produção — 100 etapas até uma versão pronta para a Steam

**Data:** 13/10/2026  
**Projeto:** Dungepm (nome provisório)  
**Ponto de partida:** já existe um protótipo Godot 3D com câmera isométrica, movimentação, combate básico, inventário, mapa, salvamento, modelos próprios e uma pequena incursão. As etapas abaixo partem desse protótipo; nenhuma etapa é marcada como concluída apenas porque existe uma implementação provisória.

## Visão e regra de conclusão

Jogo solo de sobrevivência e exploração em tempo real. Cada jogador tem um labirinto procedural próprio, definido por uma semente e persistente entre incursões. Atributos definem potencial; proficiências adquiridas pelo uso liberam habilidades. Uma ação pode treinar vários ramos e receber contribuições de todos os ramos aplicáveis: espada + katana + escola rápida; magia + elementalismo + fogo. Técnicas físicas e mágicas aceitam componentes em espaços compatíveis. Equipamentos têm categorias, propriedades e usos distintos. O visual usa modelos 3D estilizados com câmera isométrica e interface legível.

O objetivo da etapa 100 é uma **versão 1.0 completa, estável e apta a ser lançada na Steam**, após cumprir as verificações da plataforma. O ato de pagar a taxa, enviar para revisão ou publicar depende da conta do titular e das decisões comerciais dele. Esta lista apresenta dependências de produção, não uma agenda rigidamente sequencial nem uma estimativa de duração: cadastro Steamworks, página da loja e testes externos podem ocorrer em paralelo às etapas de conteúdo, respeitando seus prazos. Requisitos de conteúdo são metas de lançamento propostas e podem ser ajustados após testes, sem perder os sistemas centrais.

**Marcos de avaliação:** 20 = fundação técnica confiável; 40 = labirinto e progressão jogáveis; 60 = combinações e itens sustentam builds; 80 = campanha completa; 100 = build candidata a lançamento, aprovada nos critérios internos e nos requisitos aplicáveis da Steam.

## Modelo e esforço recomendados para as etapas 1–5

| Etapa | Modelo Codex | Esforço | Motivo |
| --- | --- | --- | --- |
| 1 · Inventariar o protótipo | GPT-6.1 Sol | Médio | Inspeção técnica de cenas, scripts, assets e testes existentes. |
| 2 · Definir a promessa do jogo | GPT-6 Astra | Médio | Sintetizar as ideias em uma visão criativa clara e coerente. |
| 3 · Fixar o escopo da versão 1.0 | GPT-6 Astra | Alto | Resolver dependências e limites de um projeto grande sem perder os sistemas centrais. |
| 4 · Dar identidade própria ao projeto | GPT-6 Astra | Médio | Desenvolver nomes, mundo e direção autoral a partir das inspirações; revisão formal de direitos, se necessária, fica fora do escopo do modelo. |
| 5 · Decidir a consequência da morte | GPT-6 Astra | Alto | Comparar o efeito das regras de morte sobre labirinto persistente, itens, proficiências e motivação para recomeçar. |

Se o consumo for uma preocupação, GPT-6.1 Sol em esforço médio é uma alternativa adequada para as cinco; aumentar para alto nas etapas 3 e 5 quando houver decisões conflitantes. A recomendação acima prioriza qualidade de decisão. Fonte: [seleção de modelos](https://developers.openai.com/api/docs/guides/model-selection) e [esforço de raciocínio](https://developers.openai.com/api/docs/guides/reasoning) da documentação oficial da OpenAI.

## 1–10 · Consolidar o protótipo e fixar o produto

1. **Inventariar o protótipo — concluída em 13/10/2026.** [Diagnóstico e evidências](INVENTARIO_PROTOTIPO.md): 87 verificações passaram no projeto e no executável Linux; duas lacunas adicionais de persistência foram reproduzidas.
2. **Definir a promessa do jogo — concluída em 13/10/2026.** [Visão de uma página](VISAO_JOGO.md): fantasia, ciclo de incursão, público alvo e relações entre os sistemas; regras de morte e limites da versão 1.0 permanecem nas etapas seguintes.
3. **Fixar o escopo da versão 1.0 — em andamento.** [Decisões de escopo](ESCOPO_V1.md): sempre single player, Windows e Linux, teclado/mouse e experiência extremamente longa confirmados; conteúdo será definido junto. Duração total e final ficam para discussão posterior.
4. **Dar identidade própria ao projeto.** Criar nomes, personagens, símbolos, monstros e lore originais; revisar semelhanças diretas com as obras de inspiração.
5. **Decidir a consequência da morte.** Definir destino do personagem, do labirinto, dos itens e do conhecimento descoberto.
6. **Especificar o ciclo completo.** Preparação, entrada, exploração, retirada, recuperação e nova incursão precisam formar um fluxo fechado.
7. **Definir metas e calendário comercial.** Fixar objetivos de duração, variedade, desempenho e uma janela que permita iniciar Steamworks e a página “Em breve” com antecedência.
8. **Organizar dados e código.** Separar regras de itens, habilidades, inimigos, salas e progressão das cenas que os exibem.
9. **Automatizar a exportação local.** Produzir builds reproduzíveis e registrar versão, plataforma e mudanças de cada uma.
10. **Criar um roteiro de teste repetível.** Validar movimento, inventário, combate, morte, save e retorno ao abrigo antes de novas expansões.

## 11–20 · Combate, exploração e sobrevivência fundamentais

11. **Ajustar movimentação e câmera.** Garantir leitura de direção, obstáculos, profundidade e alvos.
12. **Fechar o combate básico.** Preparação, impacto, defesa, esquiva e recuperação devem ter sinais visuais e sonoros claros.
13. **Padronizar alcance e colisões.** Espada, lança, projéteis e paredes devem obedecer às mesmas regras espaciais.
14. **Criar estados de ferimento.** Feridas afetam decisões e têm formas legíveis de tratamento.
15. **Balancear fôlego e carga.** Correr, lutar e carregar saque apresentam escolhas reais, sem espera excessiva.
16. **Completar recursos de expedição.** Comida, cura e luz pressionam a viagem em uma escala compreensível.
17. **Melhorar inventário e equipamentos.** Comparar, transferir, equipar, usar e descartar itens sem ambiguidade.
18. **Melhorar o mapa explorado.** Mostrar descoberta, marcos e anotações sem revelar o desconhecido.
19. **Criar a retirada.** Voltar à base encerra a incursão, preserva consequências e entrega recompensas.
20. **Validar uma incursão completa.** Um testador consegue preparar, explorar, sobreviver ou morrer e entender o resultado.

## 21–30 · Labirinto procedural próprio e persistente

21. **Definir a semente por jogador.** A mesma semente reconstrói a mesma estrutura em qualquer carregamento.
22. **Criar a estrutura de regiões.** Andares, setores, salas, corredores e conexões seguem regras explícitas.
23. **Gerar um caminho principal válido.** Entrada, objetivo e retorno são alcançáveis em toda semente aceita.
24. **Gerar ramificações úteis.** Atalhos, riscos e recompensas criam escolhas de rota.
25. **Distribuir tipos de sala.** Combate, recurso, repouso, evento, segredo e guardião têm funções distintas.
26. **Distribuir ameaças por profundidade.** Dificuldade e recompensas escalam sem saltos impossíveis.
27. **Persistir mudanças do mundo.** Portas abertas, baús, inimigos, atalhos e anotações sobrevivem ao save.
28. **Carregar setores sob demanda.** O labirinto cresce sem manter tudo ativo na memória.
29. **Testar muitas sementes.** Detectar mapas impossíveis, gargalos, sobreposição e repetição excessiva.
30. **Validar retorno ao mesmo labirinto.** Uma nova incursão reconhece rotas e alterações da anterior.

## 31–40 · Atributos e proficiências em múltiplos ramos

31. **Definir atributos.** Cada atributo explica um potencial concreto, sem substituir habilidades aprendidas.
32. **Definir a estrutura de proficiências.** Registrar raízes, especializações, escolas e tipos de equipamento como ramos que podem se sobrepor.
33. **Implementar experiência por uso relevante.** Ações em situações válidas geram progresso; repetição sem desafio não domina a progressão.
34. **Distribuir progresso entre ramos participantes.** O total ganho por ação é controlado; raiz, especialização e subtipo recebem parcelas.
35. **Somar contribuições aplicáveis.** Magia + Elementalismo + Fogo e Espadas + Katana + Escola Rápida funcionam sem dupla contagem acidental.
36. **Implementar requisitos de habilidade.** Domínio em um ou mais ramos libera golpes, magias, passivas e espaços de modificação.
37. **Criar treino de escolas de espada.** Real, brutal, fluida, rápida e pesada avançam pelas ações correspondentes.
38. **Criar treino de tipos de espada.** Espada leve, katana e outros tipos crescem pelo equipamento efetivamente usado.
39. **Criar treino mágico hierárquico.** Magia pura fortalece a raiz mais rápido; uso elemental divide progresso entre Magia, Elementalismo e elemento.
40. **Validar igualdade de ritmo.** Com esforço comparável, a habilidade praticada progride em dano no mesmo ritmo total, ainda que fortaleça ramos diferentes.

## 41–50 · Técnicas físicas, magia e combinações

41. **Definir a ficha de técnica.** Alcance, dano de origem, tempo, custo, alvo, animação e requisitos são dados verificáveis.
42. **Implementar golpes básicos montáveis.** Corte vertical, estocada e ataques equivalentes são úteis sem modificadores.
43. **Criar espaços de componentes.** Imbuimentos, características e outros espaços têm compatibilidades explícitas.
44. **Criar componentes físicos.** Avanço, ruptura de guarda, ampliação de arco e outras alterações mudam comportamento.
45. **Criar magia pura.** Técnicas arcanas exercitam a raiz de Magia e mostram seu valor próprio.
46. **Criar elementalismo.** Fogo, vento e outros elementos têm efeitos distintos além da quantidade de dano.
47. **Unir combate físico e magia.** Esgrima + Elementalismo produz técnicas híbridas utilizáveis e treináveis.
48. **Implementar ordem e interação dos componentes.** Combinações dependentes da sequência têm resultados previsíveis.
49. **Validar receitas antes de equipar.** A interface explica efeito, custo, requisitos e motivo de incompatibilidade.
50. **Salvar técnicas criadas.** O jogador pode nomear, equipar, modificar e recuperar receitas após carregar o jogo.

## 51–60 · Itens, categorias e diversidade de builds

51. **Definir categorias de itens.** Armas, armaduras, consumíveis, materiais, focos, componentes, relíquias e itens de missão têm regras próprias.
52. **Criar propriedades e etiquetas.** Tipo, peso, material, alcance, dano e afinidades determinam compatibilidade com proficiências e técnicas.
53. **Criar modelos base de itens.** Gerar variações de dados a partir de bases sem transformar cada item em uma cópia numérica.
54. **Criar espadas funcionalmente distintas.** Espada leve, katana, espada pesada e outras formas oferecem decisões de alcance, custo e ritmo.
55. **Criar outras famílias de armas.** Lança, arco, escudo e foco mágico participam da progressão e das combinações.
56. **Criar armaduras e acessórios.** Proteção, mobilidade, resistência e espaços disponíveis apresentam compensações.
57. **Criar consumíveis e materiais.** Cura, preparo, manutenção e produção alimentam a exploração.
58. **Criar relíquias e itens singulares.** Efeitos especiais alteram estratégias sem invalidar equipamentos comuns.
59. **Atingir uma biblioteca de centenas de itens.** Meta proposta: pelo menos 200 entradas nomeadas, com utilidade, obtenção e diferenças verificadas.
60. **Testar diversidade de builds.** Pelo menos cinco estilos viáveis completam a mesma incursão por meios diferentes.

## 61–70 · Mundo, inimigos, progressão e campanha

61. **Criar base segura funcional.** Armazenar, reparar, preparar técnicas e escolher expedições em um fluxo curto.
62. **Criar economia de expedição.** Saque, gasto e manutenção incentivam risco calculado sem obrigar repetição vazia.
63. **Criar famílias de monstros.** Cada família ensina sinais, fraquezas e escolhas próprias de combate.
64. **Criar inimigos de elite e guardiões.** Encontros especiais testam posicionamento, preparo e adaptação de build.
65. **Criar companheiros recrutáveis controlados por IA.** Personagens com funções e custos diferentes podem acompanhar uma incursão; autonomia e possíveis ordens seguem as decisões de escopo.
66. **Criar comandos e comportamento do grupo.** Aliados seguem, lutam, recuam e administram perigo de modo legível.
67. **Criar descobertas e objetivos.** Segredos e marcos conduzem o jogador a setores mais profundos.
68. **Criar início e dificuldade progressiva.** Setores iniciais ensinam na prática; os avançados exigem domínio dos sistemas.
69. **Implementar a estrutura de conclusão definida posteriormente.** A experiência extremamente longa deve seguir a decisão futura sobre objetivos finais e desfecho; essa escolha foi adiada pelo usuário.
70. **Testar a campanha do início ao fim.** Uma partida completa não depende de ferramentas de desenvolvimento.

## 71–80 · Apresentação, clareza e experiência de lançamento

71. **Fixar direção visual própria.** Personagens, cenários, armas e efeitos compartilham escala, paleta e leitura.
72. **Completar modelos modulares.** Equipamentos principais aparecem nos personagens sem exigir um modelo inteiro para cada combinação.
73. **Completar animações essenciais.** Locomoção, escolas de golpe, dano, magia, morte e interação correspondem às regras.
74. **Completar efeitos e áudio.** Impactos, elementos, ambiente e interface comunicam ação sem esconder perigos.
75. **Refinar a interface de proficiências.** Mostrar ramos, contribuições, desbloqueios e progresso de forma compreensível.
76. **Refinar o editor de técnicas.** Experimentar componentes, comparar resultados e corrigir combinações é rápido.
77. **Concluir acessibilidade básica.** Remapeamento de teclas, escalas de texto, volume separado e sinais que não dependam só de cor.
78. **Concluir opções e retomada.** Gráficos, áudio, controles e saves funcionam depois de fechar e reabrir o jogo.
79. **Preparar textos e localização inicial.** Português consistente; inglês entra como requisito se a página prometer suporte.
80. **Validar uma versão de conteúdo completo.** Todos os sistemas prometidos, a campanha e o final estão acessíveis.

## 81–90 · Qualidade, desempenho e direitos de uso

81. **Congelar recursos da versão 1.0.** Novas ideias entram em uma lista futura; correções e acabamento têm prioridade.
82. **Testar saves e migrações.** Carregar versões antigas, recuperar falhas e preservar labirinto e técnicas do jogador.
83. **Testar geração em escala.** Executar milhares de sementes e partidas simuladas para achar mapas inviáveis e erros raros.
84. **Testar combinações em escala.** Verificar custos, interações, progressão e casos extremos dos componentes.
85. **Testar equilíbrio com jogadores externos.** Medir mortes, retiradas, builds usadas, itens ignorados e pontos de confusão.
86. **Corrigir travamentos e bloqueios.** Nenhum erro conhecido impede avançar, salvar, retornar ou concluir a campanha.
87. **Medir e otimizar desempenho.** Estabelecer metas de FPS, carregamento, memória e tamanho de instalação nos computadores alvo.
88. **Revisar originalidade e licenças.** Conferir nomes, arte, áudio, fontes, modelos, animações, créditos e permissões de distribuição.
89. **Testar Windows e Linux.** Instalar builds limpas nos dois sistemas e conferir inicialização, controles, áudio, gráficos, salvamento e atualização.
90. **Preparar candidata de lançamento.** Build versionada, notas de versão, backup e plano de correção rápida.

## 91–100 · Preparar a Steam e fechar a versão 1.0

91. **Conferir o cadastro Steamworks iniciado com antecedência.** Titular conclui verificação, dados bancários/fiscais e taxa Steam Direct quando decidir publicar.
92. **Preparar a página da loja.** Nome final, descrição fiel, idiomas, requisitos de sistema, preço proposto, artes e capturas reais.
93. **Concluir o questionário de conteúdo.** Informar violência e eventual conteúdo gerado com IA que será consumido pelo jogador, conforme o material efetivamente usado.
94. **Enviar a página para revisão.** Corrigir retornos da Valve e publicar a página “Em breve” com a antecedência exigida.
95. **Configurar depots e inicialização.** Enviar builds via SteamPipe e verificar instalação, execução e atualização pelo cliente Steam.
96. **Testar em ramo privado.** Convidados instalam, jogam, salvam, atualizam e concluem a campanha pela distribuição real.
97. **Concluir checklists e revisão da build.** Enviar a build para análise após a página; atender os apontamentos recebidos.
98. **Fazer a verificação final.** Checar jogo completo, estabilidade, saves, direitos, créditos, loja, preço, suporte e plano de atualização.
99. **Aprovar a candidata 1.0.** Titular avalia build e página finais; decisões comerciais e momento da publicação ficam definidos.
100. **Entregar o jogo completo pronto para lançamento na Steam.** Build 1.0 testada, campanha concluível, conteúdo prometido presente, página e build aprovadas nos fluxos aplicáveis; o titular pode acionar a publicação.

## Dependências da Steam consultadas em 13/10/2026

- [Steam Direct](https://partner.steamgames.com/steamdirect/): taxa de US$ 100 por produto; para os primeiros títulos, espera de 30 dias após o pagamento e página “Em breve” pública por pelo menos duas semanas antes do lançamento.
- [Processo de lançamento](https://partner.steamgames.com/doc/store/releasing): página e build têm checklists e revisões separados; a página é enviada antes da build, e o titular aciona a publicação quando estiver pronto.
- [Questionário de conteúdo](https://partner.steamgames.com/doc/gettingstarted/contentsurvey): inclui conteúdo maduro e conteúdo gerado por IA que integra o jogo.
- [SteamPipe](https://partner.steamgames.com/doc/sdk/uploading): ferramenta de envio e teste de builds e depots.

Conferir esses requisitos novamente quando o cadastro e a publicação se aproximarem, pois procedimentos da plataforma podem mudar.
