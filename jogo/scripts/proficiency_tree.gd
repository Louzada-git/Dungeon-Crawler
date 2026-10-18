extends RefCounted
class_name ProficiencyTree
## Data from data/proficiencias.json: attributes, level curve, branches
## (roots and specializations) and the perks each branch unlocks.

const PATH := "res://data/proficiencias.json"
static var RAW: Dictionary = _load()
static var DATA: Dictionary = RAW.get("ramos", {})
static var ATTRIBUTES: Dictionary = RAW.get("atributos", {})
const ATTRIBUTE_ORDER := ["forca", "vigor", "agilidade", "destreza"]

static func _load() -> Dictionary:
	return DataFile.read(PATH, "ramos")

static func section(key: String) -> Dictionary:
	return RAW.get(key, {})

static func display_name(id: String) -> String:
	return str(DATA.get(id, {}).get("name", id))

static func attribute_name(id: String) -> String:
	return str(ATTRIBUTES.get(id, {}).get("name", id))

## "Espadas › Katana" for a weapon's path.
static func path_text(path: Array) -> String:
	var names: PackedStringArray = []
	for id in path:
		names.append(display_name(str(id)))
	return " › ".join(names)

## Groups in display order: [{id, name}].
static func groups() -> Array:
	return RAW.get("grupos", [])

## Group of a branch (specializations inherit it from their root).
static func group_of(id: String) -> String:
	var node: Dictionary = DATA.get(id, {})
	while node.has("parent"):
		node = DATA.get(node["parent"], {})
	return str(node.get("grupo", ""))

static func roots() -> Array:
	var out: Array = []
	for id in DATA:
		if not DATA[id].has("parent"):
			out.append(id)
	return out

static func children(id: String) -> Array:
	var out: Array = []
	for other in DATA:
		if DATA[other].get("parent", "") == id:
			out.append(other)
	return out

## Total experience needed to reach level n (level 1 needs nothing).
static func xp_for_level(n: int) -> float:
	if n <= 1:
		return 0.0
	var c: Dictionary = section("curva")
	return float(c.get("a", 260)) * (pow(float(c.get("r", 1.24)), n - 1) - 1.0)

static func level_for_xp(xp: float, cap: int = 99) -> int:
	var top: int = mini(cap, int(section("curva").get("nivel_maximo", 30)))
	var n: int = 1
	while n < top and xp >= xp_for_level(n + 1):
		n += 1
	return n

## Share of an action's experience for each branch of a path (sums to 1).
static func shares(count: int) -> Array:
	var table: Dictionary = section("divisao")
	if table.has(str(count)):
		return table[str(count)]
	var out: Array = []
	for i in count:
		out.append(1.0 / count)
	return out
