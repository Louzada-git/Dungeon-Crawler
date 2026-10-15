extends RefCounted
class_name TechniqueBook
## The adventurer's habilidades: which objetos sit in each one (in slot order),
## the bar (keys 4-7) pointing at habilidades and their recharge. The
## arrangement is knowledge: it survives death (main.write_knowledge); the bar
## and recharges do not.

signal changed

## Habilidade id -> [objeto ids], in slot order.
var configs: Dictionary = {}
## Bar slot -> habilidade id, "" when empty.
var bar: Array = []
## Habilidade id -> seconds left, and the full time of the current recharge.
var recharge: Dictionary = {}
var recharge_total: Dictionary = {}

func _init() -> void:
	clear()

func clear() -> void:
	configs = {}
	bar = []
	for i in Techniques.bar_size():
		bar.append("")
	recharge = {}
	recharge_total = {}

func objects(form_id: String) -> Array:
	return configs.get(form_id, [])

## Copies of an objeto placed across all habilidades (except `skip`).
func in_use(id: String, skip: String = "") -> int:
	var n: int = 0
	for form_id in configs:
		if form_id != skip:
			n += configs[form_id].count(id)
	return n

func set_objects(form_id: String, objs: Array) -> void:
	var clean: Array = []
	for id in objs:
		if Techniques.OBJECTS.has(str(id)):
			clean.append(str(id))
	if clean.is_empty():
		configs.erase(form_id)
	else:
		configs[form_id] = clean
	recharge.erase(form_id)
	changed.emit()

func assign(slot: int, form_id: String) -> void:
	if slot < 0 or slot >= bar.size():
		return
	# One place on the bar per habilidade.
	for i in bar.size():
		if bar[i] == form_id:
			bar[i] = ""
	bar[slot] = form_id if Techniques.FORMS.has(form_id) else ""
	changed.emit()

func at_slot(slot: int) -> String:
	return str(bar[slot]) if slot >= 0 and slot < bar.size() else ""

func remaining(form_id: String) -> float:
	return float(recharge.get(form_id, 0.0))

func start(form_id: String, seconds: float) -> void:
	recharge[form_id] = seconds
	recharge_total[form_id] = seconds

## 0..1 of the recharge still to go (for the bar).
func recharge_ratio(form_id: String) -> float:
	var total: float = float(recharge_total.get(form_id, 0.0))
	return clampf(remaining(form_id) / total, 0.0, 1.0) if total > 0.0 else 0.0

func tick(delta: float) -> void:
	for k in recharge.keys():
		recharge[k] = float(recharge[k]) - delta
		if recharge[k] <= 0.0:
			recharge.erase(k)

func snapshot() -> Dictionary:
	return {"versao": 2, "configs": configs.duplicate(true), "bar": bar.duplicate()}

## Tolerant: unknown habilidades and objetos are dropped. Reads the first
## format too (named recipes): the first recipe of each form becomes its setup.
func restore(data, with_bar: bool = true) -> void:
	clear()
	if not data is Dictionary:
		return
	if data.get("configs") is Dictionary:
		for form_id in data["configs"]:
			var objs = data["configs"][form_id]
			if Techniques.FORMS.has(str(form_id)) and objs is Array:
				set_objects(str(form_id), objs)
	elif data.get("recipes") is Array:
		var old_index: Array = []
		for r in data["recipes"]:
			var form_id: String = str(r.get("form", "")) if r is Dictionary else ""
			old_index.append(form_id)
			if Techniques.FORMS.has(form_id) and not configs.has(form_id) and r.get("components") is Array:
				set_objects(form_id, r["components"])
		if with_bar and data.get("bar") is Array:
			for i in mini(data["bar"].size(), bar.size()):
				var v = data["bar"][i]
				if (v is int or v is float) and int(v) >= 0 and int(v) < old_index.size() and Techniques.FORMS.has(old_index[int(v)]) and not old_index[int(v)] in bar:
					bar[i] = old_index[int(v)]
		changed.emit()
		return
	var b = data.get("bar", [])
	if with_bar and b is Array:
		for i in mini(b.size(), bar.size()):
			var f: String = str(b[i])
			bar[i] = f if Techniques.FORMS.has(f) and not f in bar else ""
	changed.emit()
