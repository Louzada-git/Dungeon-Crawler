# Direção visual — estudo e integração 01

## Referências consultadas em 10/10/2026

- [Página oficial de Project Zomboid na Steam](https://store.steampowered.com/app/108600/Project_Zomboid/): galeria e trechos do trailer com gameplay, observados no navegador. Cenas exteriores com multidão, barricadas, mobiliário e iluminação noturna. Foi uma análise de trechos, não uma sessão completa jogada.
- [Captura oficial: rua e lojas](https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/108600/ss_0dc0cb896202ecfa344a0af981b695f2349317e1.1920x1080.jpg): relação entre pessoas, veículos, fachadas e objetos pequenos; perspectiva fixa; variações de sujeira no piso.
- [Captura de interior publicada por The Nerd Stash](https://image.thenerdstash.com/2024/12/Project-Zomboid-Day-One-Tips.jpg): camas e mesas em escala humana, paredes e cobertura recortadas, personagem pequeno no ambiente, inventários compactos na faixa superior.
- [The Indie Stone — Under the Hood](https://projectzomboid.com/blog/news/2017/03/under-the-hood/): contexto técnico dos personagens em 3D.

## Observações e decisões para este jogo

1. **Proporção:** corpo humano de 1,79 m, cabeça pequena, equipamentos em escala real. Substitui o personagem de cabeça grande do bloco inicial.
2. **Projeção:** câmera ortográfica fixa, aproximadamente 30° de elevação e diagonais 2:1. É a interpretação geométrica adotada para a referência, não uma medição da configuração interna de PZ.
3. **Superfície:** texturas próprias de 128 px, cores contidas, madeira com fibras, alvenaria com juntas e desgaste. A aparência vem da textura e da silhueta; a interface continua legível em resolução normal.
4. **Ambiente:** abrigo com catres, mesa e mantimentos; depósito com caixas e barris; cisternas de pedra. Objetos grandes têm colisão e participam do planejamento das rotas dos monstros.
5. **Leitura:** paredes de fundo altas e paredes de frente recortadas. O protótipo usa corte fixo, ainda sem oclusão dinâmica por cômodo.
6. **Luz:** luz ambiente discreta, luz quente nas tochas e sombras do personagem e objetos. Nenhum sistema completo de dia/noite nesta etapa.
7. **Movimento:** animações próprias iniciais de repouso, caminhada, ataque e queda. Precisam de refinamento de peso e transições após a avaliação jogável.
8. **Inventário:** preserva as duas listas funcionais de mochila e recipiente, peso, coleta e uso de itens. A versão atual pausa ao abrir; inventário simultâneo à exploração é uma decisão futura de gameplay.

## Autoria e limites

As referências foram observadas para orientar composição, proporções e leitura. Não foram usadas como texturas nem incluídas na distribuição. Os modelos, texturas e movimentos próprios desta biblioteca são gerados pelo código editável em `fontes/gerar_modelos.py`, com fonte Blender em `fontes/dungepm_modelos.blend`. As duas animações Mixamo usadas pelo aventureiro estão documentadas em `../jogo/ASSETS.md`.

Esta é uma primeira direção artística aplicada ao jogo. O personagem, as animações e a repetição das superfícies ainda são de protótipo. A dungeon continua medieval, com monstros e recursos limitados; técnicas e magia seguem fora desta etapa.
