extends RefCounted
class_name EnemyTypes
## Monster types loaded from data/inimigos.json.

const PATH := "res://data/inimigos.json"
static var DATA: Dictionary = _load()

static func _load() -> Dictionary:
	return DataFile.read(PATH, "inimigos").get("inimigos", {})

static func info(kind: String) -> Dictionary:
	return DATA.get(kind, {})

static func display_name(kind: String) -> String:
	return str(TranslationServer.translate(str(info(kind).get("name", kind))))
