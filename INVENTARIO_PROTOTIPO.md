# Etapa 1 — inventário do protótipo

Data: 13/10/2026. Etapa concluída como diagnóstico do estado atual.

## Resultado

Existe uma pequena incursão jogável em Godot 3D, com movimento, combate, inventário, sobrevivência simples e salvamento. Ela comprova a base espacial e as interações, mas ainda não implementa o núcleo de progressão e personalização definido no brainstorm.

A suíte existente passou com **87 verificações e zero falhas no projeto** e **87 verificações e zero falhas no executável Linux**. Dois casos adicionais reproduziram lacunas de persistência descritas abaixo. Os testes usam arquivos próprios; o save normal do jogador não foi alterado.

## O que existe

| Área | Implementação encontrada | Limite atual |
| --- | --- | --- |
| Apresentação | Mundo 3D, câmera ortográfica, zoom, materiais e iluminação | Corte fixo de paredes; ainda sem opções completas e benchmark |
| Movimento | Caminhada, corrida, mira, esquiva, aceleração e frenagem | Teclas fixas; sensação dos controles precisa de teste humano |
| Combate | Direção comprometida, preparação, impacto, recuperação e interrupção | Espada e lança; não há escolas ou técnicas configuráveis |
| Inimigos | Perseguição, visão, memória curta, sinal de ataque e reação | Sete instâncias; um comportamento base com variante pesada |
| Inventário | Pilhas, categorias simples, peso, coleta, equipamento e descarte | Sete tipos de item; uma arma equipada; sem armaduras modulares |
| Sobrevivência | Vida, fôlego, saciedade, sangramento e bandagens | Valores fixos; sangramento a cada terceiro acerto recebido |
| Exploração | Cinco salas, corredores, duas rotas principais e mapa descoberto | Layout fixo, sem semente individual ou setores carregados sob demanda |
| Objetivo | Buscar o selo e retornar ao abrigo | Uma incursão curta; sem campanha e progressão entre viagens |
| Persistência | Inventário, personagem, recipientes, inimigos, mapa e contadores | JSON versão 1, um único slot, sem migrações ou backup recuperável |
| Áudio | Cinco sons WAV e opção de desligar som | Sons provisórios; configuração não é persistida |
| Arte | 24 GLBs no diretório ativo; manifesto com 23 bases; cinco sons | Inclui variante do aventureiro com animações adaptadas do Mixamo |
| Distribuição | Executável Linux independente e preset de exportação | Sem build Windows verificada ou distribuição pela Steam |

## Relação com o design atual

**Parcialmente atendido:** câmera e mundo 3D; sobrevivência; combate em tempo real; inventário categorizado; equipamentos com alcance e custo distintos; exploração e retorno.

**Ainda ausente:** labirinto procedural por jogador; persistência de semente e estado de setores; atributos como potencial; proficiências por uso; divisão de progresso entre ramos; escolas e subtipos de armas; magia pura e elementalista; desbloqueios por domínio; espaços de imbuimento e características; técnicas híbridas; centenas de itens; companheiros; economia; campanha completa.

**Precisa de especificação:** consequência definitiva da morte; relação de essências com as proficiências e componentes; duração e limites do labirinto; catálogo inicial de atributos, escolas e elementos. Essas decisões pertencem às próximas etapas de design.

## Lacunas reproduzidas

### A. Carregar uma vitória não restaura o encerramento

- Origem: `jogo/scripts/main.gd`, funções `interact()` e `load_game()`.
- Reprodução: adquirir o selo, retornar ao abrigo, salvar a vitória e carregar o arquivo em uma sessão sem estado de encerramento.
- Resultado: `won=true`, mas `ended=false` e a tela de conclusão permanece escondida.
- Impacto: o save registra sucesso, mas permite continuar a sessão como se a incursão não tivesse sido encerrada.
- Encaminhamento: definir e restaurar o estado do ciclo de expedição. Um teste de round-trip da vitória deve acompanhar a correção.

### B. Morrer mantém disponível o último save vivo

- Origem: `jogo/scripts/player.gd:die()`, `jogo/scripts/main.gd:save_game()` e menu de encerramento em `jogo/scripts/ui.gd`.
- Reprodução: salvar com 83 de vida, morrer e sair pelo botão de encerramento; o arquivo existente continua com 83 de vida.
- Resultado observado: vida atual `0`, vida salva `83`, arquivo preservado. A inicialização carrega esse arquivo se ele existir.
- Impacto: sair e abrir novamente permite retomar o estado anterior à morte; reiniciar pelo botão apaga o progresso.
- Encaminhamento: o comportamento é provisório e já constava da documentação antiga. A etapa 5 deve escolher a regra definitiva e tornar os dois caminhos consistentes.

## Limitações técnicas e documentais

- `layout.gd` fixa a geometria, as dimensões e posições importantes; `main.gd:setup_content()` fixa recipientes e inimigos. A geração procedural exigirá separar topologia, população e estado persistente.
- O save exige o mesmo número de inimigos e restaura por índice de array. Mundos variáveis precisam de identificadores estáveis e versão do gerador.
- `main.gd` concentra regras de combate, itens, objetivos e save; `ui.gd` concentra todos os painéis. Há scripts separados, mas a expansão requer dados e responsabilidades mais independentes.
- A capacidade de inventário, limites de vida e custos ainda são constantes ou números diretos; não estão ligados a atributos.
- O preset de exportação aponta para templates em um caminho absoluto desta máquina. Não há processo de build reproduzível documentado para outra máquina.
- O repositório não possui commits. Código e documentação aparecem como arquivos não rastreados; não existe histórico de versões para recuperar uma alteração.
- A documentação contém descrições antigas de arte, áudio e regras. O plano de 100 etapas registra as decisões mais recentes; o histórico antigo deve ser tratado como histórico.
- A seção de assets próprios diz que não há dependências de terceiros, mas o mesmo documento registra Mixamo e Godot. A descrição de procedência deve separar essas fontes com precisão antes da distribuição final.
- Não há validação atual de desempenho em máquinas alvo, resolução mínima, Windows, controle, acessibilidade completa ou integração Steam.

## Verificações realizadas

1. Leitura de scripts, projeto, configuração de exportação, catálogo de itens, layout, testes, manifesto de arte e documentação.
2. Execução headless da suíte existente no editor Godot 4.7.2: 87 verificações, zero falhas, saída 0.
3. Execução headless da mesma suíte no executável Linux: 87 verificações, zero falhas, saída 0.
4. Sondagem isolada de conclusão carregada e save após morte, com arquivo temporário próprio e removido ao final.
5. Inspeção das capturas existentes de exploração e inventário. Elas mostram o layout e a apresentação registrados; não substituem um novo teste manual nem medição de FPS.

Os logs desta execução estão em `work/etapa01-teste-projeto.log`, `work/etapa01-teste-executavel.log` e `work/etapa01-casos-limite.log`. A pasta `work/` é ignorada pelo Git. A sondagem reproduzível está em `work/etapa01_probe.gd`.

## Entrega da etapa e próximo trabalho

O inventário está completo: base existente, sistemas provisórios, lacunas do design e dois casos de persistência foram identificados com evidência. As correções de gameplay ficam registradas para as etapas de consolidação; este diagnóstico não altera as regras atuais.

A etapa 2 deve produzir uma visão de uma página que una sobrevivência, labirinto individual, proficiências em múltiplos ramos e técnicas criadas pelo jogador. A etapa 3 transforma essa visão em limites verificáveis da versão 1.0; a etapa 5 resolve a consequência da morte.
