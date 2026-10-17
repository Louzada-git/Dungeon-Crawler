"""Monta as folhas de revisão das animações a partir de work/auditoria/.

Uso (da pasta jogo/), depois de tests/auditoria_capture.gd:
    python3 tools/auditoria_folhas.py [saída]

Cada animação vira uma folha: a linha de cima é a vista de lado, a de baixo a
de frente; os quadros vão da esquerda (começo) para a direita (fim).
"""
import os
import sys

from PIL import Image, ImageDraw

SRC = os.path.join("..", "work", "auditoria")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(SRC, "folhas")
os.makedirs(OUT, exist_ok=True)

for name in sorted(os.listdir(SRC)):
    folder = os.path.join(SRC, name)
    if not os.path.isdir(folder) or name == "folhas":
        continue
    rows = []
    for view in ("lado", "frente"):
        frames = sorted((f for f in os.listdir(folder) if f.startswith(view + "_")), key=lambda f: int(f.split("_")[1].split(".")[0]))
        if frames:
            rows.append([Image.open(os.path.join(folder, f)).convert("RGB") for f in frames])
    if not rows:
        continue
    w, h = rows[0][0].size
    # Middle of the picture, where the character is.
    box = (int(w * 0.22), int(h * 0.04), int(w * 0.78), int(h * 0.96))
    cw, ch = (box[2] - box[0]) // 2, (box[3] - box[1]) // 2
    sheet = Image.new("RGB", (cw * len(rows[0]), ch * len(rows) + 24), (20, 20, 20))
    draw = ImageDraw.Draw(sheet)
    draw.text((6, 4), name, fill=(240, 230, 200))
    for r, row in enumerate(rows):
        for c, im in enumerate(row):
            sheet.paste(im.crop(box).resize((cw, ch)), (c * cw, 24 + r * ch))
            draw.text((c * cw + 4, 24 + r * ch + 4), str(c), fill=(255, 255, 0))
    sheet.save(os.path.join(OUT, name + ".png"))
    print(name)
