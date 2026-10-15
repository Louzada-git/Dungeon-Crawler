# Efeitos visuais — fontes

Originais tirados do **Brackeys VFX Bundle** (CC0), enviado pelo dono do projeto em 14/10/2026. Só os cinco arquivos usados estão aqui; o pacote inteiro tem 72 MB e fica fora do repositório.

| Arquivo em `originais/` | Pasta no pacote | Autor | Vira |
| --- | --- | --- | --- |
| `blood_impact_6x5.png` | `predrawn/` | CodeManu | `jogo/assets/vfx/sangue.png` |
| `impact_white_6x4.png` | `predrawn/` | CodeManu | `impacto.png` |
| `big_hit_6x5.png` | `predrawn/` | CodeManu | `golpe_forte.png` |
| `flame_01_16x4.png` | `flipbooks/` (era `.tga`) | Thomas Iché | `chama.png` |
| `cloud_01_8x8.png` | `flipbooks/` (era `.tga`) | Thomas Iché | `fumaca.png` |

`originais/LICENSE_E_CREDITOS.txt` é o arquivo de licença e créditos que veio no pacote.

## Regenerar

Da raiz do repositório:

```
python3 arte/fontes/vfx/preparar_vfx.py
```

O script (Python 3 com Pillow) recorta os quadros, descarta os vazios do começo e do fim, pega um a cada N quadros nas folhas longas (chama e fumaça: 64 → 16), reduz cada quadro para o tamanho PSX e monta folhas novas em `jogo/assets/vfx/`, junto com `folhas.json` (grade de cada folha). Depois, abrir o projeto na Godot (ou rodar `--import`) reimporta as folhas.

Tamanho, velocidade, cor e mistura de cada efeito no jogo ficam em `jogo/data/efeitos.json`, não aqui.
