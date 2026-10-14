# Assets e procedência

## Biblioteca ativa: criação própria

Todos os modelos usados pelo jogo estão em `assets/originais/`. Geometria, texturas procedurais e esqueleto foram criados para este projeto usando Blender. O aventureiro agora usa também animações gratuitas do Mixamo, adaptadas ao esqueleto original. Não houve compra, assinatura, geração por serviço pago ou importação de imagens de Project Zomboid.

- Fonte editável: `../arte/fontes/dungepm_modelos.blend`.
- Gerador reproduzível: `../arte/fontes/gerar_modelos.py`.
- Texturas fonte: `../arte/texturas/`.
- Inventário técnico de meshes e triângulos: `assets/originais/MANIFESTO.json`.
- Referências visuais e observações: `../arte/REFERENCIAS.md`.
- Regeneração: `blender --background --factory-startup --python arte/fontes/gerar_modelos.py` a partir da raiz do projeto.

Os arquivos são produção original do projeto, sem dependências de licença de assets de terceiros. Não foi atribuída uma licença pública de redistribuição ao código ou à arte; essa escolha fica com o proprietário do projeto.

## Histórico do bloco inicial

A pasta `assets/kenney/` conserva os modelos usados no primeiro bloco funcional, com o texto original da licença CC0. Estão fora do carregamento e da exportação atual.

Fonte anterior: [Kenney — Mini Dungeon](https://kenney.nl/assets/mini-dungeon), CC0. Não existem modelos desse pacote na cena jogável atual.

## Engine

Godot é software livre sob licença MIT. A licença da engine deve acompanhar a distribuição executável. Consulte [Godot — License](https://godotengine.org/license/) para os avisos de terceiros distribuídos com a engine.

## Interface

Ícones de mochila, saúde, mapa, espada, comida, bandagem e fôlego, além da silhueta corporal: desenhos vetoriais originais implementados em `scripts/ui_glyph.gd`. A captura fornecida pelo usuário foi usada como referência de organização visual e não integra os assets distribuídos.

## Animações e sons de gameplay

Nove ações originais no rig próprio: `idle`, `guard`, `walk`, `run`, `attack`, `stab`, `dodge`, `hit`, `die`. Ações criadas pelo gerador Blender do projeto.

Cinco sons provisórios originais em `assets/audio/`, gerados localmente por `../arte/fontes/gerar_audio.py`. Não há gravações, músicas ou sons baixados de terceiros.

## Mixamo

O aventureiro usa quatro animações do pacote **Sword And Shield Pack**: `slash (3)` para o golpe de espada, `attack (4)` como base da estocada, `impact` e `death`. Caminhada, corrida, repouso, guarda e esquiva usam movimentos próprios do esqueleto original. A caminhada e a corrida do pacote foram retiradas do jogo após inspeção visual, porque cruzavam os pés no nosso modelo. Fonte: [Mixamo](https://www.mixamo.com/), pacote baixado em 13/10/2026 pela conta Adobe do projeto. A [FAQ oficial da Adobe](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) permite incorporar personagens e animações gratuitamente em jogos pessoais e comerciais. Os FBX selecionados estão em `../arte/fontes/mixamo/`; a adaptação reproduzível está em `../arte/fontes/aplicar_mixamo.py`. O modelo, suas texturas e seu esqueleto continuam originais do projeto.

A estocada usa o corpo de `sword and shield attack (4).fbx`, com adaptação própria dos braços para alcançar a haste. A orientação da lança fica alinhada à direção comprometida do golpe. O dano é limitado a uma faixa linear de 3,2 m e ao primeiro alvo.
