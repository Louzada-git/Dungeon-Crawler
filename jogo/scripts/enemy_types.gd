extends RefCounted
class_name EnemyTypes
## Monster types loaded from data/inimigos.json.

const PATH := "res://data/inimigos.json"
static var DATA: Dictionary = _load()

static func _load() -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary or not raw.get("inimigos") is Dictionary:
		push_error("Catálogo de inimigos inválido: " + PATH)
		return {}
	return raw["inimigos"]

static func info(kind: String) -> Dictionary:
	return DATA.get(kind, {})

static func display_name(kind: String) -> String:
	return str(TranslationServer.translate(str(info(kind).get("name", kind))))
