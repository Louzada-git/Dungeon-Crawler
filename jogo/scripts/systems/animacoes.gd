extends RefCounted
class_name Animacoes
## When each attack animation lands its blow (data/animacoes.json, written by
## arte/fontes/personagem_psx/personagens.gd): a fraction of the animation's
## length, per model. Used to time the animation to the attack's preparation.

const PATH := "res://data/animacoes.json"
static var DATA: Dictionary = _load()

static func _load() -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary:
		push_error("Tabela de animações inválida: " + PATH)
		return {}
	return raw.get("modelos", {})

## Fraction of the animation where the blow lands; "fallback" when unknown.
static func impact(model: String, anim: String, fallback: float) -> float:
	return float(DATA.get(model, {}).get(anim, fallback))
