#!/bin/bash
# Gera os pacotes de entrega em ../entrega (ou no diretório passado).
# O pacote do jogo leva só o que importa para jogar e para abrir o projeto na Godot;
# capturas de revisão e documentos/fontes de arte vão em pacotes separados.
set -e
cd "$(dirname "$0")"
OUT="${1:-../entrega}"
mkdir -p "$OUT"
rm -f "$OUT"/Dungepm-*.zip "$OUT"/Dungepm-*.tar.xz
# 1. Executável Linux, com licenças e créditos.
tar -C outputs -cJf "$OUT/Dungepm-linux.tar.xz" linux
# 2. Projeto do jogo (pasta jogo/ da Godot) e o guia de como jogar.
zip -qr "$OUT/Dungepm-jogo.zip" jogo outputs/LEIA-ME.md -x "jogo/.godot/*" "*__pycache__*" "*.blend1"
# 3. Capturas de revisão.
zip -qr "$OUT/Dungepm-revisao.zip" revisao
# 4. Planejamento, verificação e fontes de arte.
zip -qr "$OUT/Dungepm-documentos-e-arte.zip" *.md outputs/VERIFICACAO.md arte empacotar.sh -x "*.blend1"
ls -la "$OUT"
