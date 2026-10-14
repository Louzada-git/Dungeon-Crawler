extends RefCounted
class_name Items
## Item catalog loaded from data/itens.json. Names and descriptions are keys
## in data/textos.csv and come back translated from info().

const PATH := "res://data/itens.json"
static var DATA: Dictionary = _load()
static var _resolved: Dictionary = {}

static func _load() -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary or not raw.get("itens") is Dictionary:
		push_error("Catálogo de itens inválido: " + PATH)
		return {}
	return raw["itens"]

## Item data with text already translated. Treat the result as read-only.
static func info(id: String) -> Dictionary:
	if not DATA.has(id):
		return {}
	if not _resolved.has(id):
		var data: Dictionary = DATA[id].duplicate(true)
		data["name"] = str(TranslationServer.translate(str(data.get("name", id))))
		data["description"] = str(TranslationServer.translate(str(data.get("description", ""))))
		_resolved[id] = data
	return _resolved[id]

## Drops translated copies, e.g. after a language change.
static func clear_cache() -> void:
	_resolved.clear()
