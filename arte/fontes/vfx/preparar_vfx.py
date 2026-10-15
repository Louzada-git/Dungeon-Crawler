"""Prepara as folhas de efeitos do jogo a partir dos originais do Brackeys VFX Bundle (CC0).

Uso (da raiz do repositório):
    python3 arte/fontes/vfx/preparar_vfx.py

Para cada efeito: recorta os quadros da folha original, descarta os quadros
vazios do começo e do fim, pega um a cada `passo` quadros, reduz cada quadro
para `largura` pixels (estilo PSX: o jogo lê sem suavizar) e monta uma folha
nova quase quadrada em jogo/assets/vfx/<id>.png. A grade de cada folha vai para
jogo/assets/vfx/folhas.json, que o jogo lê (scripts/systems/vfx.gd).
"""
import json
import math
import os

from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ORIGINAIS = os.path.join(AQUI, "originais")
SAIDA = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "jogo", "assets", "vfx"))

# id: (arquivo original, colunas, linhas, largura final do quadro em px (0 = original), passo)
FOLHAS = {
    "sangue": ("blood_impact_6x5.png", 6, 5, 0, 1),
    "impacto": ("impact_white_6x4.png", 6, 4, 48, 1),
    "golpe_forte": ("big_hit_6x5.png", 6, 5, 64, 1),
    "chama": ("flame_01_16x4.png", 16, 4, 32, 4),
    "fumaca": ("cloud_01_8x8.png", 8, 8, 48, 4),
}


def quadros(img, cols, rows):
    fw, fh = img.width // cols, img.height // rows
    return [img.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh)) for r in range(rows) for c in range(cols)]


def vazio(quadro):
    return quadro.getchannel("A").getextrema()[1] < 10


def reduzir(quadro, largura):
    if largura <= 0 or largura >= quadro.width:
        return quadro
    altura = max(1, round(quadro.height * largura / quadro.width))
    # Alfa pré-multiplicado: evita bordas escuras ao reduzir.
    return quadro.convert("RGBa").resize((largura, altura), Image.LANCZOS).convert("RGBA")


def main():
    os.makedirs(SAIDA, exist_ok=True)
    info = {}
    for ident, (arquivo, cols, rows, largura, passo) in FOLHAS.items():
        img = Image.open(os.path.join(ORIGINAIS, arquivo)).convert("RGBA")
        todos = quadros(img, cols, rows)
        cheios = [i for i, q in enumerate(todos) if not vazio(q)]
        usados = todos[cheios[0]:cheios[-1] + 1][::passo]
        usados = [reduzir(q, largura) for q in usados]
        n = len(usados)
        gc = math.ceil(math.sqrt(n))
        gr = math.ceil(n / gc)
        fw, fh = usados[0].size
        folha = Image.new("RGBA", (gc * fw, gr * fh), (0, 0, 0, 0))
        for i, q in enumerate(usados):
            folha.paste(q, ((i % gc) * fw, (i // gc) * fh))
        destino = os.path.join(SAIDA, ident + ".png")
        folha.save(destino, optimize=True)
        info[ident] = {"colunas": gc, "linhas": gr, "quadros": n, "largura": fw, "altura": fh, "origem": arquivo}
        print("%-12s %2d quadros %3dx%-3d  folha %4dx%-4d  %6d bytes" % (ident, n, fw, fh, folha.width, folha.height, os.path.getsize(destino)))
    with open(os.path.join(SAIDA, "folhas.json"), "w", encoding="utf-8") as f:
        json.dump({"_sobre": "Gerado por arte/fontes/vfx/preparar_vfx.py; não editar à mão.", "folhas": info}, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
