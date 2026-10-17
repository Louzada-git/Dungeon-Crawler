"""Folhas de revisão de todos os frames de todas as animações com cada arma.

Uso (da pasta jogo/), depois de tests/estudio_capture.gd:
    python3 tools/estudio_folhas.py [saída] [--jpg]

Para cada arma e animação, uma folha: em cima as fileiras de lado, embaixo as
de frente; o número sobre cada boneco é o frame (30 por segundo) e o tempo.
Também monta um índice por arma (index.html) para abrir no navegador.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

SRC = os.path.join("..", "work", "estudio")
args = [a for a in sys.argv[1:] if not a.startswith("--")]
JPG = "--jpg" in sys.argv
OUT = args[0] if args else os.path.join(SRC, "folhas")
os.makedirs(OUT, exist_ok=True)

index = []
for weapon in sorted(os.listdir(SRC)):
    wdir = os.path.join(SRC, weapon)
    if not os.path.isdir(wdir) or weapon == "folhas":
        continue
    sheets = []
    # Only the band where the copies stand (the rest of the row is empty floor).
    meta = json.load(open(os.path.join(wdir, "meta.json")))
    used = meta["count"] * meta["spacing"] * meta["height"] / meta["tall"]
    left = max(0, int(meta["width"] / 2 - used / 2))
    right = min(meta["width"], int(meta["width"] / 2 + used / 2))
    for anim in sorted(os.listdir(wdir)):
        adir = os.path.join(wdir, anim)
        if not os.path.isdir(adir):
            continue
        rows = []
        for view in ("lado", "frente"):
            for f in sorted(x for x in os.listdir(adir) if x.startswith(view + "_")):
                im = Image.open(os.path.join(adir, f)).convert("RGB")
                rows.append((view, im.crop((left, 0, right, im.size[1]))))
        if not rows:
            continue
        w, h = rows[0][1].size
        sheet = Image.new("RGB", (w, h * len(rows) + 28), (16, 16, 18))
        draw = ImageDraw.Draw(sheet)
        draw.text((8, 7), "%s  ·  %s  ·  em cima de lado, embaixo de frente" % (weapon, anim), fill=(240, 230, 200))
        for i, (view, im) in enumerate(rows):
            sheet.paste(im, (0, 28 + i * h))
        os.makedirs(os.path.join(OUT, weapon), exist_ok=True)
        name = "%s.%s" % (anim, "jpg" if JPG else "png")
        if JPG:
            sheet.save(os.path.join(OUT, weapon, name), quality=75)
        else:
            sheet.save(os.path.join(OUT, weapon, name), optimize=True)
        sheets.append(name)
    index.append((weapon, sheets))
    print(weapon, len(sheets))

with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as f:
    f.write("<!doctype html><meta charset='utf-8'><title>Dungepm · frames</title>"
            "<style>body{background:#111;color:#eee;font:14px sans-serif;margin:16px}img{max-width:100%;display:block;margin:6px 0 18px}a{color:#e8c66a}</style>")
    f.write("<h1>Todos os frames, todas as animações, cada arma</h1><p>")
    f.write(" · ".join("<a href='#%s'>%s</a>" % (w, w) for w, _ in index))
    f.write("</p>")
    for w, sheets in index:
        f.write("<h2 id='%s'>%s</h2>" % (w, w))
        for s in sheets:
            f.write("<h3>%s</h3><img loading='lazy' src='%s/%s'>" % (s.rsplit(".", 1)[0], w, s))
