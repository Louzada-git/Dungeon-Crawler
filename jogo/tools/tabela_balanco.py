"""Tabela de balanço das armas contra os monstros, lida dos dados do jogo.

Uso (da pasta jogo/):
    python3 tools/tabela_balanco.py [itens.json] [inimigos.json] [proficiencias.json]

Para cada arma, no domínio 1 e sem talentos nem habilidades: tempo do golpe
(preparo e ciclo até o próximo golpe, com o delay do peso), quando a esquiva libera, dano por segundo num alvo (com
sangramento), contra blindado, fôlego por golpe, quantos golpes seguidos um
fôlego cheio aguenta, e quantos golpes e quanto tempo para derrubar cada
monstro no 1º andar. O mesmo modelo de tempo de DungeonPlayer.attack.
"""
import json
import math
import sys

ITENS = sys.argv[1] if len(sys.argv) > 1 else "data/itens.json"
INIMIGOS = sys.argv[2] if len(sys.argv) > 2 else "data/inimigos.json"
PROF = sys.argv[3] if len(sys.argv) > 3 else "data/proficiencias.json"

itens = json.load(open(ITENS, encoding="utf-8"))["itens"]
monstros = json.load(open(INIMIGOS, encoding="utf-8"))["inimigos"]
prof = json.load(open(PROF, encoding="utf-8"))
folego = prof.get("folego", {})
REGEN = float(folego.get("recuperacao", 16.0))

armas = {k: v for k, v in itens.items() if "style" in v}
punhos = dict(prof["punhos"])
armas["(punhos)"] = punhos

NOMES = {"corrompido": "Corr.", "espreitador": "Espr.", "guardiao": "Guard.", "brutamontes": "Brut.", "chefe": "Chefe"}


PESO = 0.1  # DungeonPlayer.DELAY_PER_KG: segundos a mais por kg, só para golpear de novo


def ciclo(a):
    """Preparo, golpe (lentidão e esquiva contam daqui) e ciclo até o próximo golpe."""
    w = float(a.get("windup", 0.22))
    c = max(float(a.get("cooldown", 0.62)), w + 0.15)
    return w, c, c + PESO * float(a.get("weight", 0.0))


def linha(nome, a):
    w, golpe, c = ciclo(a)
    dano = float(a["damage"])
    sangra = float(a.get("bleed", {}).get("dps", 0.0))
    dps = dano / c + sangra
    blind = dano * float(a.get("crush", 1.0)) / c
    custo = float(a.get("cost", 10.0))
    # Regeneração quando a lentidão do golpe acabou (último 10% do golpe e o delay do peso).
    liquido = custo - REGEN * (c - 0.9 * golpe)
    seguidos = "%.0f" % (100.0 / liquido) if liquido > 0 else "sem fim"
    esquiva = w + (golpe - w) * 0.5
    mortes = []
    for m in ["corrompido", "espreitador", "guardiao", "brutamontes", "chefe"]:
        info = monstros[m]
        vida = float(info["health"])
        por_golpe = dano * (float(a.get("crush", 1.0)) if info.get("armored") else 1.0)
        golpes = math.ceil(vida / por_golpe)
        mortes.append("%d (%.1f s)" % (golpes, w + (golpes - 1) * c))
    alvos = a.get("targets", 1)
    return "| %s | %.0f | %.2f | %.2f | %.2f | %.0f | %.0f | %.1f | %s | %s | %s |" % (
        nome, dano, w, c, esquiva, dps, blind, custo, seguidos, alvos, " | ".join(mortes))


print("| Arma | Dano | Preparo | Ciclo | Esquiva | DPS | DPS blind. | Fôlego | Seguidos | Alvos | " + " | ".join(NOMES.values()) + " |")
print("|" + " --- |" * (10 + len(NOMES)))
for nome, a in armas.items():
    print(linha(nome, a))
print()
print("| Monstro | Vida | Dano | Preparo | Firmeza |")
print("| --- | --- | --- | --- | --- |")
for m, info in monstros.items():
    print("| %s | %.0f | %.0f | %.2f | %s |" % (m, info["health"], info["damage"], info.get("windup", 0.65), info.get("firmeza", "—")))
