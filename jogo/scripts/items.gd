extends RefCounted
class_name Items
## Item catalog loaded from data/itens.json. Names and descriptions are keys
## in data/textos.csv and come back translated from info().

const PATH := "res://data/itens.json"
## Items taken out of the game. Old saves may still have them; SaveSystem drops them.
const REMOVED := ["seal"]
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

## Removes the items in REMOVED from an {id: amount} dictionary, in place.
static func drop_removed(stacks) -> void:
	if stacks is Dictionary:
		for id in REMOVED:
			stacks.erase(id)

## Ammunition a weapon fires: its "ammo" first, then the ones in "ammo_extra".
static func ammo_list(weapon: Dictionary) -> Array:
	var out: Array = []
	if str(weapon.get("ammo", "")) != "":
		out.append(str(weapon["ammo"]))
	for extra in weapon.get("ammo_extra", []):
		out.append(str(extra))
	return out

## True when the weapon fires this ammunition.
static func fires(weapon_id: String, ammo: String) -> bool:
	return ammo in ammo_list(DATA.get(weapon_id, {}))

## The weapon's numbers with the ammunition's own effect: "damage_mult"
## (multiplies), "bleed" (the stronger one wins), "knockback" and "pierce" (add).
static func with_ammo(weapon: Dictionary, ammo: String) -> Dictionary:
	var a: Dictionary = DATA.get(ammo, {})
	if not (a.has("damage_mult") or a.has("bleed") or a.has("knockback") or a.has("pierce")):
		return weapon
	var w: Dictionary = weapon.duplicate(true)
	w["damage"] = float(w.get("damage", 0.0)) * float(a.get("damage_mult", 1.0))
	if a.has("bleed"):
		var mine: Dictionary = w.get("bleed", {})
		if float(a["bleed"].get("dps", 0.0)) * float(a["bleed"].get("time", 0.0)) > float(mine.get("dps", 0.0)) * float(mine.get("time", 0.0)):
			w["bleed"] = a["bleed"].duplicate()
	if a.has("knockback"):
		w["knockback"] = float(w.get("knockback", 3.0)) + float(a["knockback"])
	if a.has("pierce"):
		w["pierce"] = int(w.get("pierce", 1)) + int(a["pierce"])
	return w

## Lockpicking tools ("arrombar" in the data), in the order they get used:
## "ordem" lowest first. "bonus" adds to the chance, "quebra" multiplies the
## chance of breaking on a miss, "sempre" opens any lock and is used up.
static func lockpicks() -> Array:
	var out: Array = []
	for id in DATA:
		if DATA[id].has("arrombar"):
			out.append(id)
	out.sort_custom(func(a, b): return int(DATA[a]["arrombar"].get("ordem", 9)) < int(DATA[b]["arrombar"].get("ordem", 9)))
	return out

## Drops translated copies, e.g. after a language change.
static func clear_cache() -> void:
	_resolved.clear()
