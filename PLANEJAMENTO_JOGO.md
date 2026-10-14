# Planejamento do jogo — histórico (congelado em 13/10/2026)

> **Este arquivo não é mais o documento vivo.** A direção atual está no [plano de 100 etapas](PLANO_100_ETAPAS.md), no [escopo da 1.0](ESCOPO_V1.md) e na [visão do jogo](VISAO_JOGO.md). O conteúdo abaixo é mantido como registro de produção até 13/10/2026 e não deve ser usado como referência de decisões.
>
> **Pontos superados conhecidos:**
> - A numeração da seção 13 (Etapa 0 a 5) é antiga. A "Etapa 3" daqui (evolução por prática) **não** é a etapa 3 do plano atual (fixar o escopo). O teste de sensação marcado aqui como pendente virou a etapa 6 do plano.
> - Seções 3 e 14: dungeon feita à mão, geração procedural como possibilidade distante e publicação fora do escopo foram substituídas pelo labirinto procedural persistente por jogador e pelo objetivo de lançar na Steam. Multiplayer continua fora: o jogo é sempre single player.
> - Seção 17: "ainda não há áudio" está superado; há cinco sons próprios. `outputs/COMO_JOGAR.md` não existe; as instruções estão em `outputs/LEIA-ME.md`.
> - Seção "Gameplay": "nenhum download Mixamo foi incorporado" está superado; animações do Sword And Shield Pack foram integradas em 13/10/2026 (ver `outputs/VERIFICACAO.md`).
> - Seções 12 e 17: a biblioteca ativa é `jogo/assets/originais`; os modelos Kenney ainda estão no diretório do projeto, mas não entram na exportação.
>
> As decisões mais recentes do usuário incluem labirinto procedural persistente por jogador, centenas de itens categorizados, atributos como potencial, proficiências hierárquicas e sobrepostas que liberam habilidades, escolas de espada, magia elemental e técnicas combinadas.

**Projeto:** Project Dungepm (nome de trabalho)  
**Estado:** primeira base jogável implementada, 10 de outubro de 2026  
**Engine usada:** Godot 4.7.2 stable  
**Responsabilidades:** o assistente implementa o jogo, integra os assets, verifica o funcionamento e mantém este documento atualizado. O usuário decide a direção criativa e aprova cada etapa antes do início dela.

> **Prioridade atual definida pelo usuário:** primeiro jogabilidade, inventário e mapa. Técnicas ficam para depois da base. A criação de técnicas continua sendo a direção futura do jogo.

> Este arquivo registra o que já foi decidido, as propostas de trabalho e as perguntas que ainda precisam de resposta. Uma proposta não vira decisão definitiva apenas por estar escrita aqui.

## 1. Visão do jogo

Um **dungeon crawler medieval de sobrevivência** em tempo real. O jogador prepara uma incursão, explora uma masmorra perigosa, enfrenta monstros, administra recursos e tenta voltar vivo com descobertas que ampliam suas possibilidades. A inspiração em *Project Zomboid* está na forma de jogar, na atenção às necessidades do personagem, no peso das escolhas e na dificuldade. A inspiração em *Skyrim* está na evolução por prática. A atmosfera e a importância de ler o combate podem lembrar *Dark Souls*, sem copiar mundo, personagens, interface ou conteúdo desses jogos.

O diferencial é um **sistema universal de criação de técnicas**. O jogador não recebe uma lista fechada de habilidades nem escolhe uma classe fixa. Ele aprende peças ao praticar diferentes disciplinas e monta suas próprias ações, efeitos contínuos e combinações híbridas. Espada + fogo pode produzir uma lâmina flamejante; arco + fogo, uma flecha incendiária; espada + movimento, uma técnica de avanço e corte.

### Pilares

1. **Preparar, arriscar e retornar.** Cada incursão exige suprimentos, espaço no inventário e uma avaliação do risco de continuar ou voltar.
2. **Evoluir fazendo.** A prática melhora o domínio de uma disciplina e revela novas possibilidades, sem classes obrigatórias.
3. **Criar técnicas compreensíveis.** Peças combinadas em sequência geram resultados previsíveis o bastante para permitir planejamento e variados o bastante para recompensar experimentação.
4. **Combate perigoso.** Posicionamento, tempo, alcance, fadiga e condições do personagem importam mais que apertar habilidades sem pensar.
5. **Um mundo coerente.** Monstros, salas, recursos e equipamentos precisam fazer sentido dentro do cenário, em vez de existir apenas como obstáculos ou números.

## 2. O que já foi decidido

- O projeto será um **jogo próprio feito na Godot**, não um mod de *Project Zomboid*.
- O cenário-base é medieval/fantasia, com **dungeons e monstros**.
- A sobrevivência deve ter gerenciamento de recursos, alimentação e consequências para ferimentos e desgaste.
- A evolução ocorre **pelo que o personagem faz**.
- **Não existem classes fixas.** “Arqueiro”, “espadachim” e “mago” descrevem especializações construídas pelo jogador.
- A criação de técnicas vale para **todas as disciplinas**, não só magia. O jogador monta as próprias habilidades a partir de peças.
- As peças podem ser combinadas entre disciplinas: a progressão é aberta e permite técnicas híbridas.
- A **ordem** das peças deve alterar o resultado.
- Técnicas preparadas são usadas por uma **barra de atalhos** durante a exploração e o combate.
- A implementação, a busca de assets, a integração e os testes ficam com o assistente. Assets externos precisam ser gratuitos e ter licença adequada; modelos 3D gerados por IA são uma possibilidade, não uma dependência inicial.
- Antes de começar **cada etapa de implementação**, o assistente apresenta em poucas linhas o que fará e espera a aprovação do usuário. Ao terminar, mostra o que funciona e propõe a próxima etapa.

## 3. Hipóteses de trabalho a validar

Estas escolhas permitem planejar o primeiro protótipo, mas ainda podem mudar:

- **Visão:** câmera isométrica sobre um mundo 3D, inspirada na leitura espacial de *Project Zomboid*.
- **Plataformas de lançamento:** Windows e Linux, com teclado e mouse. **Sempre single player**, conforme decisões explícitas de 13/10/2026.
- **Estrutura inicial:** um acampamento seguro e uma dungeon pequena, construída à mão. Geração procedural pode vir depois, se contribuir para o jogo.
- **Arte inicial:** 3D estilizado e legível, com iluminação escura, silhuetas claras e efeitos contidos. A direção visual final será aprovada separadamente.
- **Preparação:** um número limitado de técnicas equipadas na barra, mesmo que o personagem conheça muitas combinações.

## 4. Ciclo principal de jogo

1. **No acampamento:** conferir estado do personagem, reparar equipamento, guardar itens, preparar comida e suprimentos, montar técnicas e escolher a próxima incursão.
2. **Na entrada da dungeon:** decidir o que levar. Mais recursos aumentam segurança, mas ocupam peso e espaço para espólios.
3. **Na exploração:** observar ameaças, administrar luz e orientação, procurar passagens e recursos, evitar ou enfrentar monstros.
4. **Depois de cada confronto:** tratar ferimentos, recuperar fôlego, gastar consumíveis ou adaptar o plano. O estado do personagem afeta o próximo combate.
5. **Na decisão de retorno:** ponderar se vale explorar mais uma sala ou sair com o que foi encontrado.
6. **Após voltar:** transformar a experiência em domínio de disciplinas, novas peças e melhores preparações.

O jogo deve criar histórias de sobrevivência a partir dessas decisões. A tensão precisa vir da combinação dos sistemas, sem fazer o jogador repetir tarefas burocráticas a cada minuto.

## 5. Sistema de técnicas: núcleo do projeto

### 5.1 Objetivo

Em vez de cadastrar centenas de habilidades prontas, o jogo interpreta uma **receita composta pelo jogador**. Cada peça possui uma função, requisitos, custo e regras de compatibilidade. Uma técnica completa é validada antes de ser equipada e executada.

### 5.2 Peças propostas

| Família | O que define | Exemplos iniciais |
| --- | --- | --- |
| Origem | De onde parte a ação | corpo, espada, arco, foco mágico |
| Ativação | Quando ela acontece | botão pressionado, após esquiva, ao atingir um alvo |
| Ação | O que acontece primeiro | golpe, disparo, impulso, canalização |
| Transformação | Como o efeito existente muda | incendiar, perfurar, dividir, ampliar alcance |
| Condição | Em que situação a peça opera | alvo próximo, arma equipada, fôlego suficiente |

Essas famílias são uma proposta de organização interna. Na interface, as peças devem parecer fáceis de entender e combinar, sem exigir que o jogador aprenda termos de programação.

### 5.3 A ordem importa

Cada peça processa o resultado que recebeu da anterior. **Dividir → Explodir** pode criar vários projéteis que explodem; **Explodir → Dividir** pode criar uma explosão central que espalha fragmentos. O resultado exato depende das regras definidas e testadas no protótipo. Combinações impossíveis devem ser explicadas na interface, não falhar silenciosamente.

Exemplos de intenção de design:

- **Espada + fogo:** imbuir uma lâmina por alguns golpes; consome foco ou outro recurso além do desgaste normal da arma.
- **Arco + perfuração + fragmentação:** uma flecha atravessa o primeiro alvo e se divide depois, com custo de munição ou fôlego proporcional.
- **Movimento + espada + onda:** um avanço seguido de um corte que projeta energia em alcance curto.
- **Esquiva + velocidade + custo de fôlego:** efeito condicionado que o jogador construiu, em vez de uma passiva fixa.

Esses exemplos descrevem a fantasia desejada; números, animações e regras exatas ainda não estão aprovados.

### 5.4 Regras técnicas para manter o sistema viável

- Cada peça terá **entradas e saídas definidas**, para verificar se pode seguir a peça anterior.
- Cada receita terá um **limite de complexidade**: quantidade de peças, custo total e exigências de domínio.
- O jogo mostrará **prévia do efeito, custo e motivo de invalidade** antes de equipar.
- A receita salva será composta por identificadores e parâmetros, permitindo balanceamento e gravação de jogo.
- A execução usará um conjunto pequeno de efeitos reutilizáveis, como dano, movimento, projétil, área e estado, combinados em vez de programar cada técnica individualmente.
- Custos e consequências devem crescer com o poder. Uma técnica forte pode exigir fôlego, foco, munição, tempo de preparo ou expor o personagem durante a execução.
- A interface deve permitir salvar, renomear, duplicar e comparar receitas quando o sistema amadurecer.

### 5.5 Barra de atalhos

O primeiro protótipo deve permitir montar técnicas fora do combate e equipar algumas em atalhos numéricos. Quantidade de espaços, possibilidade de trocar técnicas dentro da dungeon e limites de preparação ainda dependem de decisão e teste. O primeiro teste deve privilegiar clareza e controle, não quantidade de opções.

## 6. Evolução por prática

O personagem progride em disciplinas como espada, arco, magia, defesa, movimentação e sobrevivência. A lista final será definida após testar o núcleo. Usar uma disciplina em situações relevantes dá experiência nela; ações repetidas sem risco ou aprendizado não devem virar o melhor jeito de evoluir.

O domínio pode liberar:

- peças novas e variações das existentes;
- maior controle sobre custos e estabilidade;
- capacidade de sustentar receitas mais complexas;
- uso mais eficiente de ferramentas e equipamentos associados.

Disciplinas não bloqueiam umas às outras. Um personagem que pratica espada e magia pode combinar ambas. O objetivo é que a especialização surja das escolhas de jogo, mas que experimentar outro caminho continue possível.

**Questão de balanceamento:** evoluir não pode eliminar a tensão da sobrevivência nem fazer uma única combinação ser sempre a melhor. Isso será medido em testes de jogo, não decidido só por números no papel.

## 7. Sobrevivência e recursos

### Núcleo inicial

- **Fome e alimento:** comer sustenta o personagem; longos períodos sem comida trazem consequências graduais.
- **Fôlego:** ações físicas e técnicas exigem energia; exaustão prejudica fuga e combate.
- **Ferimentos:** dano pode deixar efeitos que permanecem após a luta e pedem tratamento.
- **Peso e espaço:** levar suprimentos demais reduz mobilidade ou capacidade de recolher achados.
- **Luz:** tochas ou outras fontes de luz ajudam a perceber caminhos e ameaças, mas consomem recursos.
- **Equipamento:** armas, armaduras e ferramentas têm utilidade e podem sofrer desgaste.

Água, sono, temperatura, doenças e sanidade são **possibilidades futuras**, não compromissos do primeiro protótipo. Cada medidor adicional precisa criar decisões interessantes; caso só acrescente manutenção repetitiva, não entra.

### Princípio de ritmo

Necessidades devem pressionar a **expedição inteira**, não interromper cada combate. O jogador deve entender por que ficou em perigo e que decisão poderia ter tomado antes.

## 8. Combate e monstros

O combate será em tempo real e perigoso. O jogador precisa perceber intenção e alcance do inimigo, escolher quando atacar, recuar, esquivar ou gastar uma técnica. Golpes básicos devem ser úteis; a barra de técnicas amplia possibilidades, não substitui movimento e posicionamento.

No primeiro protótipo, três papéis de monstro são suficientes para testar decisões distintas:

1. **Ameaça comum:** aproximação direta e ataque legível.
2. **Ameaça rápida:** pressiona distância e esquiva.
3. **Ameaça resistente ou de área:** exige atenção ao espaço e uso inteligente de recursos.

Nomes, aparência e história desses monstros serão definidos junto da identidade do mundo. Inteligência artificial, animações e dano devem ser ajustados com sessões jogáveis, não apenas com estimativas.

## 9. Dungeon, exploração e recompensas

O primeiro mapa terá salas com funções claras: entrada segura, encontro simples, escolha de rota, recurso útil, ameaça maior e saída. A dungeon deve permitir ao jogador decidir se luta, contorna ou recua em alguns pontos.

Recompensas possíveis:

- comida, munição e materiais de manutenção;
- equipamentos com vantagens e custos diferentes;
- peças de técnicas ou pistas de uso;
- atalhos, informações e caminhos para futuras incursões.

Evitar que toda recompensa seja apenas aumento de dano. Novas opções de técnica, acesso e preparo devem ser tão interessantes quanto números maiores.

## 10. Interface e experiência

O jogador precisa ler rapidamente vida, fôlego, condição geral, arma equipada, consumíveis essenciais e técnicas preparadas. Os detalhes de inventário, ferimentos e construção de receitas podem ficar em telas próprias. A criação de técnicas deve mostrar em tempo real: sequência, efeito previsto, custo, requisito faltante e botão de teste quando houver ambiente seguro.

O primeiro protótipo prioriza interface funcional e legível. Direção visual, animações e efeitos serão refinados depois que o sistema central provar que é divertido.

## 11. Direção técnica na Godot

- **Cenas separadas** para personagem, monstros, itens, acampamento, dungeon e interface.
- **Dados separados da lógica** para peças de técnica, itens e estatísticas. Isso facilita adicionar conteúdo sem duplicar código.
- **Um interpretador de receitas** que valide a combinação, calcule custos e produza ações de jogo.
- **Persistência de personagem e receitas** antes de ampliar o conteúdo.
- **Ferramentas de depuração** para inspecionar efeito, dano, custo e motivo de invalidez de uma técnica.
- **Testes focados nas regras de combinação e gravação**, porque falhas nesses sistemas afetariam todo o jogo.

A escolha entre GDScript e C# será feita na preparação do protótipo. A proposta inicial é GDScript para iterar rápido; partes com necessidade comprovada de desempenho podem ser revistas depois.

## 12. Assets e licenças

Prioridade inicial: assets gratuitos com permissão clara de uso no jogo e visual coerente entre si. Para cada asset externo integrado, registrar **nome, autor, URL, licença, exigência de crédito e eventual modificação**. “Gratuito para baixar” não basta se a licença não permitir o uso pretendido.

Modelos 3D gerados por IA podem preencher lacunas pontuais, desde que o serviço escolhido permita o uso no projeto e o resultado tenha qualidade e consistência suficientes. Não depender desse caminho para começar o protótipo. Nenhum serviço pago ou compra de asset entra automaticamente no planejamento.

## 13. Escopo e etapas de produção

### Etapa 0 — Preparação do projeto — concluída

Projeto Godot configurado em `jogo/`, com cenas, scripts separados por responsabilidade, modelos CC0, licenças e exportação para Linux. A engine abre e executa a cena.

### Etapa 1 — Base de jogabilidade, inventário e mapa — implementada

**Prioridade solicitada pelo usuário:** adiar técnicas e construir primeiro a base.

**Entrega:** câmera isométrica, movimento, corrida, esquiva, combate básico, vida e fôlego; cinco áreas conectadas com duas rotas; baús, coleta, inventário por peso, equipamento e descarte; mapa descoberto por exploração; comida e bandagens; retorno ao abrigo, save e retomada.

**Verificação:** importação sem erros, 45 verificações automáticas de regras e simulação passando, captura e inspeção visual do jogo, da mochila, do mapa e do combate. Executável Linux preparado para teste do usuário.

**Pendente:** o usuário experimentar a sensação dos controles, combate, ritmo de exploração e inventário. O cumprimento técnico não significa que o equilíbrio e a sensação de jogo estejam aprovados.

### Etapa 2 — Ajustar e consolidar a base — aguardando retorno

**Objetivo:** corrigir o que aparecer no teste do usuário e melhorar câmera, leitura, combate, navegação ou interação conforme as prioridades indicadas. Áudio e apresentação podem entrar num recorte aprovado.

**Antes de começar:** apresentar as melhorias concretas e pedir aprovação. Não avançar automaticamente para técnicas.

### Etapa 3 — Evolução por prática — futura

**Objetivo:** disciplinas melhoram com uso relevante e persistem no save. O personagem continua sem classes fixas.

**Antes de começar:** apresentar disciplinas iniciais e ritmo de evolução para aprovação.

### Etapa 4 — Técnicas criadas pelo jogador — futura

**Objetivo:** depois da base consolidada, implementar editor de sequências, validação, custos, barra de atalhos e peças combináveis entre espada, arco e magia. Demonstrar espada de fogo e efeito dependente da ordem das peças.

**Antes de começar:** aprovar uma gramática pequena e exemplos claros. Não implementar antecipadamente apenas porque é o diferencial futuro.

### Etapa 5 — Conteúdo e expansão — futura

**Objetivo:** expandir dungeon, monstros, itens, peças, áudio e arte consistente, preservando o ritmo aprovado.

**Antes de começar:** apresentar o pacote de conteúdo e as fontes dos assets para aprovação.

Cada etapa pode ser subdividida se ficar grande demais para uma revisão clara. **O assistente não inicia uma etapa nova sem o “sim” do usuário para aquela etapa.** Dentro de uma etapa aprovada, correções e testes necessários fazem parte da execução autorizada; mudanças relevantes de direção voltam para aprovação.

## 14. Fora do primeiro protótipo

- Mundo aberto extenso e várias regiões.
- Multiplayer.
- Centenas de peças e combinações sem testar uma gramática menor.
- Geração procedural complexa da dungeon.
- Sistema completo de NPCs, facções ou missões.
- Gráficos fotorrealistas.
- Publicação comercial ou em lojas.

Esses itens podem ser reavaliados depois da primeira versão jogável. O objetivo inicial é comprovar que **sobrevivência + dungeon + evolução por prática + técnicas construídas pelo jogador** funciona como jogo.

## 15. Decisões em aberto

1. **Morte e recuperação:** morte permanente, recuperação de itens ou outro modelo? A escolha afeta risco e progressão.
2. **Remontagem de técnicas:** possível a qualquer momento ou apenas em locais seguros?
3. **Câmera e controles:** confirmar isométrica 3D e decidir movimento por teclado, clique ou combinação.
4. **Tom do mundo:** fantasia sombria, fantasia mais aventureira ou outro recorte.
5. **Ritmo de magia e técnicas:** raras e decisivas ou frequentes com custo menor?
6. **Limite de técnicas equipadas:** quantos atalhos iniciais ajudam a tomar decisões sem restringir demais?
7. **História:** narrativa central, descoberta ambiental ou foco quase completo em sobrevivência sistêmica?

Essas perguntas serão trazidas **quando influenciarem a próxima etapa**, com opções curtas e uma recomendação. Não é necessário responder a todas agora.

## 16. Como vamos trabalhar juntos

O usuário não precisa ler este arquivo para acompanhar o projeto. Antes de cada etapa, o assistente enviará uma mensagem curta com:

1. **O que será construído.**
2. **O que ficará jogável ou verificável ao final.**
3. **As escolhas criativas que precisam de aprovação naquele momento.**

Depois da aprovação, o assistente executa a etapa, testa, mostra o resultado e atualiza este plano quando houver decisões novas. Se surgir uma mudança grande no meio do trabalho, apresenta a proposta antes de adotá-la. O arquivo é a memória de produção; as mensagens no chat são a interface de decisão do usuário.

## 17. Estado da primeira entrega

A orientação mais recente do usuário substitui o protótipo inicialmente centrado nas técnicas: **jogabilidade, inventário e mapa vêm primeiro**. Essa correção autorizou construir a base descrita na etapa 1.

### Arquivos

- `jogo/project.godot`: projeto editável.
- `jogo/scripts/`: jogador, inimigos, inventário, itens, layout, cenário, interface, mapa e persistência.
- `jogo/tests/runtime_test.gd`: verificações de regras, interface e simulação em execução real da Godot.
- `jogo/ASSETS.md`: fontes, licenças e adaptações dos modelos.
- `outputs/linux/Dungepm.x86_64`: versão Linux independente do editor.
- `outputs/COMO_JOGAR.md`: controles, regras provisórias e limites da entrega.
- `outputs/base-jogavel.png`, `outputs/inventario.png`, `outputs/mapa.png`, `outputs/combate.png`: capturas da aplicação real.

### O que já existe

Cinco áreas conectadas por duas rotas, sete monstros, dois tipos de arma, cinco recipientes iniciais, saque dos monstros, descoberta do mapa, coleta parcial por peso, consumíveis, equipamento, descarte recuperável e objetivo de recuperar o selo e retornar à entrada. A mochila suporta 18 kg e reduz a velocidade acima de 11 kg. O save preserva jogador, inventário, recipientes, inimigos e mapa descoberto.

### Regras provisórias e limitações

- Câmera 3D isométrica; WASD/setas movem em relação à tela; mouse mira e ataca; Shift corre; Espaço esquiva.
- I/Tab abre a mochila, M abre o mapa e E interage. Mochila e mapa pausam esta versão solo.
- Primeiro visual usa Mini Dungeon 2.0 de Kenney (CC0), com ajuste de escala e materiais; não é uma aprovação de direção de arte final.
- Ainda não há áudio, evolução por prática, técnicas, multiplayer, desgaste de armas ou dungeon procedural.
- Morte leva à tela de encerramento. Reiniciar a expedição apaga o save; sair após morrer preserva o último save vivo. Isso é comportamento de teste, não a regra definitiva de morte.
- Comida, dano, fôlego, carga e frequência de sangramento usam valores provisórios para avaliação.
- Próximo passo: usuário testar e indicar o que precisa mudar na base; propor o próximo recorte e aguardar aprovação.

## Atualização — modelos próprios e integração visual (10/10/2026)

A orientação mais recente substitui a compra ou busca de modelos externos: vamos produzir os modelos e texturas do projeto. Project Zomboid orienta câmera, proporções, materialidade e leitura espacial. A análise está em `arte/REFERENCIAS.md`.

Nesta etapa: biblioteca Blender original, personagem humano e monstro animados, espada e lança, chão e alvenaria modular, mobília medieval aplicada ao mapa funcional. Preservar inventário, alimentação, ferimentos, coleta, exploração e retorno ao abrigo. Validar colisões e caminhos após inserir móveis. Técnicas, magia e evolução detalhada permanecem para depois da base jogável.

A integração foi autorizada por “continue, analise gameplays e prints de project zomboid, coloque os modelos e etc”. Pequenos ajustes de escala, iluminação e desempenho são realizados durante a implementação. Alterações grandes na identidade continuam sendo discutidas antes.

## HUD — referência enviada pelo usuário (10/10/2026)

Aplicar a composição da captura enviada: inventário compacto no alto à esquerda, bordas retas, fundo preto translúcido, tabela de itens, ferramentas na lateral esquerda e condição física à direita. Centro da tela reservado à exploração. Ícones e silhueta desenhados originalmente em `ui_glyph.gd`.

Atalhos: I/Tab inventário, H condição física, M mapa, 1 inventário/equipamento, 2 ração, 3 bandagem. O inventário mantém a pausa da versão solo; o painel de saúde pode ser consultado durante a exploração. O desenho do corpo representa a condição geral, sem inventar ferimentos localizados que o jogo ainda não simula.

## Gameplay — movimento e combate (10/10/2026)

- Caminhada orienta o corpo para a direção do movimento. Botão direito mantém mira; botão esquerdo mira e compromete o golpe. A direção permanece travada até a recuperação.
- Aceleração e frenagem curtas, corrida limitada por fôlego, movimento reduzido ao mirar e ao recuar em guarda.
- Espada: cone de 55° de cada lado, até três alvos, preparação de 0,22 s. Lança: cone estreito de 22°, primeiro alvo, preparação de 0,30 s. Dano, peso e custo continuam nos dados dos itens.
- Um ataque causa dano uma única vez. Cliques nos últimos 0,16 s de recuperação podem iniciar o próximo golpe; não há repetição automática ao segurar o botão.
- Acertos interrompem e recuam monstros, respeitando colisões. Ferimentos interrompem o ataque pendente do personagem. Esquiva tem animação própria, deslocamento pela física e janela curta de proteção.
- Monstros sinalizam a direção do ataque, têm recuperação e perseguem a última posição vista por até três segundos após perderem visão. Paredes ocultam monstros sem linha de visão direta.
- Animações próprias atualizadas: idle, guard, walk, run, attack, stab, dodge, hit, die. Deslocamento fica sob responsabilidade da física, evitando que a animação atravesse paredes.
- Sons próprios gerados localmente: passos, deslocamento da arma, impacto, ferimento e coleta. Som pode ser desligado na pausa. Efeito curto e discreto na câmera ao receber/acertar golpes.
- Mixamo foi consultado e permite o uso de animações em jogos conforme FAQ da Adobe; o download na sessão disponível exige login. Integração de animações Mixamo permanece dependente desse acesso. Nenhum download Mixamo foi incorporado nesta etapa.
