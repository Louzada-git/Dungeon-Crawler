extends RefCounted
class_name ProficiencyTree
## Proficiency branches from data/proficiencias.json (roots and specializations).

const PATH := "res://data/proficiencias.json"
static var DATA: Dictionary = _load()

static func _load() -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary or not raw.get("ramos") is Dictionary:
		push_error("Árvore de proficiências inválida: " + PATH)
		return {}
	return raw["ramos"]

static func display_name(id: String) -> String:
	return str(DATA.get(id, {}).get("name", id))

## "Espadas › Katana" for a weapon's path.
static func path_text(path: Array) -> String:
	var names: PackedStringArray = []
	for id in path:
		names.append(display_name(str(id)))
	return " › ".join(names)
