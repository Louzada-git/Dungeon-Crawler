extends RefCounted
class_name Items

const DATA = {
 "sword": {"name":"Espada de viajante", "tag":"ARMA", "weight":2.4, "damage":24.0, "range":2.1, "cost":17.0, "cooldown":0.62, "windup":0.22, "style":"slash", "angle":55.0, "targets":3, "description":"Equilibrada e confiável. Um corte custa 17 de fôlego.", "model":"weapon-sword"},
 "spear": {"name":"Lança da guarda", "tag":"ARMA", "weight":3.6, "damage":29.0, "range":3.2, "cost":23.0, "cooldown":0.85, "windup":0.30, "style":"thrust", "angle":7.0, "width":0.34, "targets":1, "description":"Estocada longa de 3,2 m em linha reta. Atinge o primeiro alvo e custa 23 de fôlego.", "model":"weapon-spear"},
 "ration": {"name":"Ração de viagem", "tag":"ALIMENTO", "weight":0.45, "description":"Restaura 35 de saciedade. Comer também ajuda na recuperação do fôlego.", "model":"pot"},
 "bandage": {"name":"Bandagem limpa", "tag":"TRATAMENTO", "weight":0.15, "description":"Estanca o sangramento e recupera 18 de vida.", "model":"potion"},
 "ore": {"name":"Ferro bruto", "tag":"MATERIAL", "weight":1.6, "description":"Material pesado. Leve só o que consegue carregar.", "model":"rocks"},
 "coin": {"name":"Moeda antiga", "tag":"TESOURO", "weight":0.02, "description":"Encontrada entre os pertences da antiga guarnição.", "model":"coin"},
 "seal": {"name":"Selo das cisternas", "tag":"OBJETIVO", "weight":0.6, "description":"Recupere este selo e retorne ao abrigo de entrada.", "model":"key"}
}

static func info(id: String) -> Dictionary:
 return DATA.get(id, {})
