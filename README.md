# Dungepm — As Cisternas

Dungeon crawler de sobrevivência com cara de PlayStation 1, feito na Godot 4.7. Cada expedição gera um labirinto novo: explore as salas, cuide da comida, do fôlego e dos ferimentos, derrote o chefe do andar, desça mais fundo e volte ao abrigo com os selos.

![Uma sala do 1º andar, na câmera isométrica](revisao/terceira/04-mesmo-lugar-isometrica.png)

## Baixar e jogar

Não precisa instalar nada: o jogo inteiro vai dentro do executável.

| Sistema | Download | Como abrir |
|---|---|---|
| Windows (64 bits) | [Dungepm-windows.zip](https://github.com/Louzada-git/Dungeon-Crawler/raw/main/downloads/Dungepm-windows.zip) (42 MB) | Extraia (botão direito → **Extrair tudo**) e abra `Dungepm.exe`. Se o Windows avisar que o programa não é conhecido, clique em **Mais informações → Executar assim mesmo**. |
| Linux (64 bits) | [Dungepm-linux.tar.xz](https://github.com/Louzada-git/Dungeon-Crawler/raw/main/downloads/Dungepm-linux.tar.xz) (23 MB) | Extraia e abra `linux/Dungepm.x86_64`. Se não abrir com dois cliques: `chmod +x Dungepm.x86_64` e `./Dungepm.x86_64`. |

Os créditos e as licenças vão junto, nos dois pacotes. Precisa de placa de vídeo com OpenGL 3.3. O jogo é em português.

![Terceira pessoa, com um monstro à frente](revisao/terceira/02-sala-com-monstro.png)

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
| Pausar | Esc |
| Salvar no abrigo | F5 |

## O projeto

- `jogo/`: projeto da Godot 4.7.2 (renderizador Compatibility). A arquitetura está em `jogo/ARQUITETURA.md`, e os números de armas e monstros em `jogo/BALANCO.md`.
- `outputs/LEIA-ME.md`: o que mudou em cada versão e como cada sistema funciona.
- `arte/`: fontes da arte e scripts que preparam os assets.
- `revisao/`: capturas de tela de cada etapa.

Créditos dos assets de terceiros em `outputs/linux/CREDITOS.txt` e `jogo/ASSETS.md`.
