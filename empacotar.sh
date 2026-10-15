#!/bin/bash
# Gera os pacotes de entrega em ../entrega (ou no diretório passado).
# O pacote do jogo leva só o que importa para jogar e para abrir o projeto na Godot;
# capturas de revisão e documentos/fontes de arte vão em pacotes separados.
set -e
cd "$(dirname "$0")"
OUT="${1:-../entrega}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
rm -f "$OUT"/Dungepm-*.zip "$OUT"/Dungepm-*.tar.xz
# 1. Executável Linux, com licenças e créditos.
tar -C outputs -cJf "$OUT/Dungepm-linux.tar.xz" linux
# 2. Projeto do jogo (pasta jogo/ da Godot) e o guia de como jogar.
zip -qr "$OUT/Dungepm-jogo.zip" jogo outputs/LEIA-ME.md -x "jogo/.godot/*" "*__pycache__*" "*.blend1"
# 3. Capturas de revisão, em JPG para caber no limite de envio (originais ficam em revisao/).
TMP="$(mktemp -d)"
python3 - "$TMP" <<'PY'
import os, sys
from PIL import Image
dest = sys.argv[1]
for root, _, files in os.walk("revisao"):
    for f in files:
        src = os.path.join(root, f)
        out_dir = os.path.join(dest, root)
        os.makedirs(out_dir, exist_ok=True)
        if f.lower().endswith(".png"):
            Image.open(src).convert("RGB").save(os.path.join(out_dir, f[:-4] + ".jpg"), quality=85)
        else:
            with open(src, "rb") as a, open(os.path.join(out_dir, f), "wb") as b:
                b.write(a.read())
PY
(cd "$TMP" && zip -qr "$OUT/Dungepm-revisao.zip" revisao)
rm -rf "$TMP"
# 4. Planejamento, verificação e fontes de arte.
zip -qr "$OUT/Dungepm-documentos-e-arte.zip" *.md outputs/VERIFICACAO.md arte empacotar.sh -x "*.blend1"
ls -la "$OUT"
