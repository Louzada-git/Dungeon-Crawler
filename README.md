# Dungepm — As Cisternas

Dungeon crawler de sobrevivência com cara de PlayStation 1, feito na Godot 4.7.

Você desce pelas cisternas com uma mochila, um pouco de comida e uma arma. Cada expedição gera um labirinto novo. Explore as salas, cuide da fome, do fôlego e dos ferimentos, derrote o guardião de cada andar para abrir a descida e volte ao abrigo com os selos. Se o aventureiro morrer, ele não volta: o próximo começa do zero, mas lembra o mapa que você já explorou.

![Uma sala do 1º andar, na câmera isométrica](revisao/terceira/04-mesmo-lugar-isometrica.png)

## Baixar e jogar

Não precisa instalar nada: o jogo inteiro vai dentro do executável.

| Sistema | Download | Como abrir |
|---|---|---|
| Windows (64 bits) | [Dungepm-windows.zip](https://github.com/Louzada-git/Dungeon-Crawler/raw/main/downloads/Dungepm-windows.zip) (42 MB) | Extraia (botão direito → **Extrair tudo**) e abra `Dungepm.exe`. Se o Windows avisar que o programa não é conhecido, clique em **Mais informações → Executar assim mesmo**. |
| Linux (64 bits) | [Dungepm-linux.tar.xz](https://github.com/Louzada-git/Dungeon-Crawler/raw/main/downloads/Dungepm-linux.tar.xz) (23 MB) | Extraia e abra `linux/Dungepm.x86_64`. Se não abrir com dois cliques: `chmod +x Dungepm.x86_64` e `./Dungepm.x86_64`. |

Precisa de placa de vídeo com OpenGL 3.3. O jogo é em português. Os créditos e as licenças vão junto nos dois pacotes.

## O que tem no jogo

**Labirinto**
- Gerado por semente a cada expedição. O 1º andar tem 10 salas, e cada andar seguinte é maior (20, 40, 60…).
- Salas de combate, de suprimentos, de tesouro, covis com guardião de elite e a câmara do chefe, que guarda o selo e a descida.
- Baús abertos e monstros mortos continuam assim quando você volta a um andar. Alguns baús são trancados e precisam de gazua.

**Sobrevivência**
- Fome, fôlego, carga da mochila e ferimentos que sangram até você tratar com bandagens ou unguento.
- O abrigo do 1º andar é o único lugar seguro: lá você descansa, salva e entrega os selos.

**Combate**
- 13 armas, cada uma com seu jeito: espadas e katana cortam em arco, lanças e alabarda estocam em linha, maça e martelo esmagam (e furam armadura), o machado faz sangrar, a adaga mata quem não te viu, e arco e besta atiram flechas e virotes que dá para recolher.
- Arma pesada bate forte e demora para golpear de novo: cada kg da arma soma 0,1 s de espera.
- Guarda com o botão direito, esquiva, corrida, andar agachado e ataque furtivo.
- Cinco tipos de monstro: corrompido, espreitador (rápido), brutamontes (resistente), guardião de elite e o guardião do andar, com golpe em área e fúria na metade da vida.

**Personagem**
- No começo você distribui 25 pontos entre Força, Vigor, Agilidade e Destreza e escolhe a arma inicial (ou começa de punhos).
- Proficiências que sobem com o uso, no estilo de Oblivion, em três grupos: Combate, Furtividade e Sobrevivência. Os ramos dão talentos a partir do nível 5.
- Habilidades com objetos encaixados: cada objeto muda a habilidade (Lâmina afiada faz sangrar, Alcance aumenta o golpe, Golpe duplo acerta duas vezes…), e a ordem dos objetos importa. As teclas das habilidades são você quem escolhe.
- Barra rápida de 1 a 9 com qualquer item.

**Visual**
- Filtro PSX: imagem em pixels grandes, cores reduzidas, texturas sem suavizar e vértices que tremem, como no PS1. Pode desligar.
- Câmera isométrica ou em terceira pessoa, à sua escolha.
- Sangue, faíscas, poeira, fumaça e tochas com chama animada.

| | |
|---|---|
| ![Terceira pessoa, com um monstro à frente](revisao/terceira/02-sala-com-monstro.png) | ![O guardião do andar e o anel do golpe em área](revisao/labirinto/03-chefe-golpe-em-area.png) |
| Câmera em terceira pessoa | O guardião do andar avisa o golpe em área com um anel vermelho |
| ![Janela de habilidades, com objetos e teclas](revisao/barra/02-teclas-das-habilidades.png) | ![Barra rápida com vários itens](revisao/barra/01-barra-rapida.png) |
| Habilidades: objetos, prévia e teclas | Barra rápida de 1 a 9 |

## Controles

| Ação | Controle |
|---|---|
| Mover | WASD ou setas |
| Atacar | Botão esquerdo |
| Mirar / guarda | Segurar botão direito |
| Correr | Shift |
| Esquivar | Espaço |
| Andar agachado | C |
| Interagir / abrir baú / arrombar | E |
| Inventário | I ou Tab |
| Mapa explorado | M |
| Condição física | H |
| Barra rápida (qualquer item) | 1 a 9 |
| Proficiências | P |
| Habilidades: montar e trocar teclas | T |
| Habilidades: usar | Q, R, F, G (ou as que você escolher) |
| Câmera isométrica ou terceira pessoa | Esc → Câmera |
| Aproximar / afastar câmera | Roda do mouse |
| Terceira pessoa: soltar o cursor | Segurar Alt |
| Pausar | Esc |
| Salvar no abrigo | F5 |

## Primeiros passos

1. Monte o aventureiro: distribua os pontos e escolha a arma.
2. No abrigo, pegue o que precisar dos baús. Comida e bandagens ocupam a barra rápida desde o começo.
3. Explore o andar. Chegue agachado (C) em monstros que ainda não te viram para um ataque furtivo.
4. Quando o fôlego acabar, você não esquiva nem segura a guarda. Recue antes disso.
5. O guardião do andar fica na sala mais distante. Derrote-o para pegar o selo e abrir a descida.
6. Volte ao abrigo e use o ponto de descanso (E) para salvar e entregar os selos.

## Rodar pelo código

1. Instale a [Godot 4.7.2](https://godotengine.org/download/).
2. Abra `jogo/project.godot` e aperte F5.

Testes automáticos (da pasta `jogo/`):

```
godot --headless --path . -- --test
godot --headless --path . -- --test-labirinto --seed=777
```

O primeiro testa o mundo fixo (combate, inventário, save, HUD, habilidades, câmera…), e o segundo testa o labirinto gerado. Para gerar os executáveis, use os presets **Linux** e **Windows** de `jogo/export_presets.cfg`, e depois `./empacotar.sh` para montar os pacotes.

## Estrutura

| Pasta | O que tem |
|---|---|
| `jogo/` | Projeto da Godot: cenas, scripts, dados em JSON e assets. O mapa do código está em `jogo/ARQUITETURA.md`, e os números de armas e monstros em `jogo/BALANCO.md`. |
| `jogo/data/` | Itens, monstros, proficiências, habilidades, saque, efeitos e textos. Dá para balancear o jogo sem mexer no código. |
| `outputs/` | Guia do jogador com as novidades de cada versão (`LEIA-ME.md`) e o registro dos testes (`VERIFICACAO.md`). |
| `downloads/` | Os pacotes para Windows e Linux. |
| `arte/` | Fontes da arte e os scripts que preparam modelos, texturas e efeitos. |
| `revisao/` | Capturas de tela de cada etapa. |

