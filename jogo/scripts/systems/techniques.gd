extends RefCounted
class_name Techniques
## Habilidades (data/tecnicas.json). Each one exists once, with fixed traits,
## and has slots for objetos. The numbers start from the weapon in hand
## (CharacterSheet.weapon_stats); the habilidade's effects apply, then each
## objeto in slot order acts on what is already assembled to its left
## ("multiplica" scales current values, including what earlier objetos added;
## "soma" adds a fixed amount). Habilidades and objetos unlock by branch level;
## each level in an objeto's "copias" gives one more copy, and a copy sits in
## one habilidade at a time.

static var RAW: Dictionary = _load()
static var FORMS: Dictionary = RAW.get("formas", {})
static var OBJECTS: Dictionary = RAW.get("objetos", {})
static var RULES: Dictionary = RAW.get("regras", {})

static func _load() -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/tecnicas.json"))
	return raw if raw is Dictionary else {}

static func rule(key: String, fallback: float) -> float:
	return float(RULES.get(key, fallback))

static func bar_size() -> int:
	return int(rule("barra", 4))

## "punhos" for empty hands, else the weapon's attack style.
static func style_of(weapon_id: String) -> String:
	if weapon_id == "":
		return "punhos"
	return str(Items.info(weapon_id).get("style", "slash"))

static func form_name(form_id: String) -> String:
	return str(FORMS.get(form_id, {}).get("name", form_id))

static func object_name(id: String) -> String:
	return str(OBJECTS.get(id, {}).get("name", id))

## "Lâminas nível 4" for a requirement dictionary; "" when there is none.
static func requirement_text(req: Dictionary) -> String:
	var parts: PackedStringArray = []
	for branch in req:
		parts.append("%s nível %d" % [ProficiencyTree.display_name(branch), int(req[branch])])
	return ", ".join(parts)

static func meets(sheet: CharacterSheet, req: Dictionary) -> bool:
	for branch in req:
		if sheet.level(branch) < int(req[branch]):
			return false
	return true

static func form_unlocked(sheet: CharacterSheet, form_id: String) -> bool:
	return FORMS.has(form_id) and meets(sheet, FORMS[form_id].get("requer", {}))

## Is it one of the basic habilidades (the weapon's own blow, always open)?
static func basic(form_id: String) -> bool:
	return not FORMS.get(form_id, {}).has("requer")

## Does the weapon in hand fit the habilidade (style and, for some, weapon branch)?
static func form_fits(form_id: String, weapon_id: String) -> bool:
	var form: Dictionary = FORMS.get(form_id, {})
	if not style_of(weapon_id) in form.get("estilos", []):
		return false
	var branch: String = str(form.get("ramo_arma", ""))
	return branch == "" or branch in CharacterSheet.path_of(weapon_id)

static func object_fits(id: String, weapon_id: String) -> bool:
	var styles: Array = OBJECTS.get(id, {}).get("estilos", [])
	return styles.is_empty() or style_of(weapon_id) in styles

## Branch and level that open the objeto's copies.
static func object_branch(id: String) -> String:
	var req: Dictionary = OBJECTS.get(id, {}).get("requer", {})
	return str(req.keys()[0]) if not req.is_empty() else ""

## Copies the adventurer has of an objeto (one per level reached in "copias").
static func copies(sheet: CharacterSheet, id: String) -> int:
	var branch: String = object_branch(id)
	if branch == "":
		return 0
	var n: int = 0
	for lv in OBJECTS[id].get("copias", [OBJECTS[id]["requer"][branch]]):
		if sheet.level(branch) >= int(lv):
			n += 1
	return n

## Level of the branch where the next copy comes; -1 when there is no more.
static func next_copy_level(sheet: CharacterSheet, id: String) -> int:
	var branch: String = object_branch(id)
	for lv in OBJECTS.get(id, {}).get("copias", []):
		if sheet.level(branch) < int(lv):
			return int(lv)
	return -1

## Level that grows a habilidade's slots: weapon mastery for the basic ones,
## else the branch that unlocked it.
static func slot_level(sheet: CharacterSheet, form_id: String, weapon_id: String) -> int:
	if basic(form_id):
		var path: Array = CharacterSheet.path_of(weapon_id)
		return sheet.mastery(path) if not path.is_empty() else 1
	var req: Dictionary = FORMS[form_id]["requer"]
	return sheet.level(str(req.keys()[0]))

## Level where the habilidade starts counting slots (1 for the basic ones).
static func start_level(form_id: String) -> int:
	var req: Dictionary = FORMS.get(form_id, {}).get("requer", {})
	return int(req.values()[0]) if not req.is_empty() else 1

static func slot_step(form_id: String) -> int:
	return maxi(1, int(FORMS.get(form_id, {}).get("slot_a_cada", rule("slot_a_cada_basica", 5))))

static func open_slots(sheet: CharacterSheet, form_id: String, weapon_id: String) -> int:
	var lv: int = slot_level(sheet, form_id, weapon_id)
	return clampi(1 + maxi(0, lv - start_level(form_id)) / slot_step(form_id), 1, int(FORMS.get(form_id, {}).get("slots", 1)))

## Level (of the habilidade's own measure) that opens slot n (1-based).
static func level_for_slot(form_id: String, n: int) -> int:
	return start_level(form_id) + (n - 1) * slot_step(form_id)

## Habilidades for a weapon style, basic first.
static func forms_for(weapon_id: String) -> Array:
	var out: Array = []
	for id in FORMS:
		if form_fits(id, weapon_id):
			out.append(id)
	return out

## Why a habilidade cannot be used with this weapon now; "" when it can.
static func problem(sheet: CharacterSheet, book, form_id: String, weapon_id: String) -> String:
	if not FORMS.has(form_id):
		return "Habilidade desconhecida."
	var form: Dictionary = FORMS[form_id]
	if not form_unlocked(sheet, form_id):
		return "%s ainda trancada: precisa de %s." % [form_name(form_id), requirement_text(form.get("requer", {}))]
	if not form_fits(form_id, weapon_id):
		return "%s não serve para %s." % [form_name(form_id), "as mãos vazias" if weapon_id == "" else str(Items.info(weapon_id).get("name", weapon_id)).to_lower()]
	var objs: Array = book.objects(form_id)
	var slots: int = open_slots(sheet, form_id, weapon_id)
	if objs.size() > slots:
		return "%s tem %d %s agora; tire objetos." % [form_name(form_id), slots, "slot" if slots == 1 else "slots"]
	for id in objs:
		if not OBJECTS.has(id):
			return "Objeto desconhecido."
		if not object_fits(id, weapon_id):
			return "%s não faz sentido com esta arma." % object_name(id)
		var have: int = copies(sheet, id)
		var used: int = book.in_use(id)
		if used > have:
			return "%s: você tem %d %s e usa %d." % [object_name(id), have, "cópia" if have == 1 else "cópias", used]
	return ""

## Final numbers with this weapon: weapon_stats + habilidade + objetos in order.
static func stats(sheet: CharacterSheet, form_id: String, objs: Array, weapon_id: String) -> Dictionary:
	var s: Dictionary = sheet.weapon_stats(weapon_id).duplicate(true)
	if not s.has("damage"):
		return s
	s["hits"] = 1
	s["dash"] = 0.0
	var style: String = style_of(weapon_id)
	var form: Dictionary = FORMS.get(form_id, {})
	for effect in form.get("efeitos", []):
		apply(s, effect, style)
	for id in objs:
		for effect in OBJECTS.get(id, {}).get("efeitos", []):
			apply(s, effect, style)
	s["recarga"] = float(form.get("recarga", 1.5)) + rule("recarga_por_objeto", 0.75) * objs.size()
	s["technique"] = form_name(form_id)
	s["cost"] = maxf(1.0, float(s.get("cost", 10.0)))
	s["windup"] = maxf(0.05, float(s.get("windup", 0.22)))
	return s

## One effect on the running numbers. "campo" may be "group.key" (bleed.dps).
static func apply(s: Dictionary, effect: Dictionary, style: String) -> void:
	var field: String = str(effect.get("campo", ""))
	var target: Dictionary = s
	var key: String = field
	if field.contains("."):
		var parts: PackedStringArray = field.split(".")
		if not s.has(parts[0]) or not s[parts[0]] is Dictionary:
			if effect.has("multiplica"):
				return
			s[parts[0]] = {}
		target = s[parts[0]]
		key = parts[1]
	var has_value: bool = target.has(key)
	var current: float = float(target.get(key, effect.get("base", 0.0)))
	if effect.has("define"):
		current = float(effect["define"])
	elif effect.has("soma"):
		var amount: float = float(effect["soma"])
		if style == "shoot" and effect.has("disparo"):
			amount = float(effect["disparo"])
		current += amount
	elif effect.has("multiplica"):
		if not has_value and not effect.has("base"):
			return
		current *= float(effect["multiplica"])
	elif effect.has("minimo"):
		current = maxf(current, float(effect["minimo"]))
	target[key] = int(roundi(current)) if key in ["targets", "pierce", "hits"] else current

## Short lines describing the result for the editor and tooltips.
static func summary(s: Dictionary) -> Array:
	var rows: Array = []
	if not s.has("damage"):
		return rows
	var hits: int = int(s.get("hits", 1))
	rows.append(["Dano", ("%d × %s" % [hits, UiStyle.fmt(s["damage"])]) if hits > 1 else UiStyle.fmt(s["damage"])])
	rows.append(["Alcance", "%s m" % UiStyle.fmt(s.get("range", 1.5))])
	var style: String = str(s.get("style", "slash"))
	if style == "slash":
		rows.append(["Arco", "volta inteira" if float(s.get("angle", 55)) >= 179.0 else "%d°" % roundi(float(s.get("angle", 55)) * 2.0)])
	if int(s.get("targets", 1)) > 1 or style == "smash":
		rows.append(["Alvos", "até %d" % int(s.get("targets", 1))])
	if int(s.get("pierce", 1)) > 1:
		rows.append(["Atravessa", "%d inimigos" % int(s["pierce"])])
	rows.append(["Fôlego", UiStyle.fmt(s["cost"], 0)])
	rows.append(["Preparo", "%s s" % UiStyle.fmt(s["windup"], 2)])
	rows.append(["Recarga", "%s s" % UiStyle.fmt(s.get("recarga", 0.0))])
	var extra: PackedStringArray = []
	if float(s.get("dash", 0.0)) > 0.0:
		extra.append("avança %s m" % UiStyle.fmt(s["dash"]))
	if s.get("bleed") is Dictionary and float(s["bleed"].get("dps", 0.0)) > 0.0:
		extra.append("sangra %s/s por %s s" % [UiStyle.fmt(s["bleed"]["dps"]), UiStyle.fmt(s["bleed"].get("time", 4.0), 0)])
	if s.has("sneak_mult"):
		extra.append("×%s em desprevenido" % UiStyle.fmt(s["sneak_mult"]))
	if float(s.get("stagger", 0.0)) > 0.0:
		extra.append("atordoa %s s" % UiStyle.fmt(s["stagger"]))
	if s.has("crush"):
		extra.append("×%s em blindado" % UiStyle.fmt(s["crush"]))
	if not extra.is_empty():
		rows.append(["Efeitos", ", ".join(extra)])
	return rows
