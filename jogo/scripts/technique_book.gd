extends RefCounted
class_name TechniqueBook
## The adventurer's techniques: recipes made in the editor, the bar (keys 4-7)
## pointing at recipes, and the recharge of each recipe. Recipes are knowledge:
## they survive death (main.write_knowledge); the bar and recharges do not.

signal changed

## [{"name": String, "form": String, "components": [String]}]
var recipes: Array = []
## Bar slot -> recipe index, -1 when empty.
var bar: Array = []
## Recipe index -> seconds left, and the full time of the current recharge.
var recharge: Dictionary = {}
var recharge_total: Dictionary = {}

func _init() -> void:
	clear()

func clear() -> void:
	recipes = []
	bar = []
	for i in Techniques.bar_size():
		bar.append(-1)
	recharge = {}

func limit() -> int:
	return int(Techniques.rule("limite_receitas", 12))

static func clean(recipe: Dictionary) -> Dictionary:
	var comps: Array = []
	for c in recipe.get("components", []):
		comps.append(str(c))
	var form: String = str(recipe.get("form", "corte"))
	var name: String = str(recipe.get("name", "")).strip_edges().left(28)
	if name == "":
		name = Techniques.form_name(form)
	return {"name": name, "form": form, "components": comps}

## Adds or replaces (index >= 0) a recipe; returns its index, -1 if the book is full.
func store(recipe: Dictionary, index: int = -1) -> int:
	var r: Dictionary = clean(recipe)
	if index >= 0 and index < recipes.size():
		recipes[index] = r
		recharge.erase(index)
	else:
		if recipes.size() >= limit():
			return -1
		recipes.append(r)
		index = recipes.size() - 1
	changed.emit()
	return index

func remove(index: int) -> void:
	if index < 0 or index >= recipes.size():
		return
	recipes.remove_at(index)
	for i in bar.size():
		if bar[i] == index:
			bar[i] = -1
		elif bar[i] > index:
			bar[i] -= 1
	var moved: Dictionary = {}
	for k in recharge:
		if k < index:
			moved[k] = recharge[k]
		elif k > index:
			moved[k - 1] = recharge[k]
	recharge = moved
	changed.emit()

func assign(slot: int, index: int) -> void:
	if slot < 0 or slot >= bar.size():
		return
	bar[slot] = index if index >= 0 and index < recipes.size() else -1
	changed.emit()

func at_slot(slot: int) -> Dictionary:
	if slot < 0 or slot >= bar.size() or bar[slot] < 0 or bar[slot] >= recipes.size():
		return {}
	return recipes[bar[slot]]

func remaining(index: int) -> float:
	return float(recharge.get(index, 0.0))

func start(index: int, seconds: float) -> void:
	recharge[index] = seconds
	recharge_total[index] = seconds

## 0..1 of the recharge still to go (for the bar).
func recharge_ratio(index: int) -> float:
	var total: float = float(recharge_total.get(index, 0.0))
	return clampf(remaining(index) / total, 0.0, 1.0) if total > 0.0 else 0.0

func tick(delta: float) -> void:
	for k in recharge.keys():
		recharge[k] = float(recharge[k]) - delta
		if recharge[k] <= 0.0:
			recharge.erase(k)

func snapshot() -> Dictionary:
	return {"recipes": recipes.duplicate(true), "bar": bar.duplicate()}

## Tolerant: unknown forms and components are dropped, the bar is checked.
func restore(data, with_bar: bool = true) -> void:
	clear()
	if not data is Dictionary:
		return
	var raw = data.get("recipes", [])
	if raw is Array:
		for r in raw:
			if r is Dictionary and Techniques.FORMS.has(str(r.get("form", ""))):
				var c: Dictionary = clean(r)
				c["components"] = c["components"].filter(func(id): return Techniques.COMPONENTS.has(id))
				if recipes.size() < limit():
					recipes.append(c)
	var b = data.get("bar", [])
	if with_bar and b is Array:
		for i in mini(b.size(), bar.size()):
			var v = b[i]
			bar[i] = int(v) if (v is int or v is float) and int(v) >= 0 and int(v) < recipes.size() else -1
	changed.emit()
