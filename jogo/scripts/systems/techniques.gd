extends RefCounted
class_name Techniques
## Player-made techniques (data/tecnicas.json): a form plus components in slots.
## The numbers start from the weapon in hand (CharacterSheet.weapon_stats); the
## form's effects apply, then each component in slot order acts on what is
## already assembled to its left ("multiplica" scales current values, including
## what earlier components added; "soma" adds a fixed amount).

static var RAW: Dictionary = _load()
static var FORMS: Dictionary = RAW.get("formas", {})
static var COMPONENTS: Dictionary = RAW.get("componentes", {})
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

static func component_name(id: String) -> String:
	return str(COMPONENTS.get(id, {}).get("name", id))

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

static func component_unlocked(sheet: CharacterSheet, id: String) -> bool:
	return COMPONENTS.has(id) and meets(sheet, COMPONENTS[id].get("requer", {}))

## Does the weapon in hand fit the form (style and, for some forms, weapon branch)?
static func form_fits(form_id: String, weapon_id: String) -> bool:
	var form: Dictionary = FORMS.get(form_id, {})
	if not style_of(weapon_id) in form.get("estilos", []):
		return false
	var branch: String = str(form.get("ramo_arma", ""))
	return branch == "" or branch in CharacterSheet.path_of(weapon_id)

static func component_fits(id: String, weapon_id: String) -> bool:
	var styles: Array = COMPONENTS.get(id, {}).get("estilos", [])
	return styles.is_empty() or style_of(weapon_id) in styles

## Slots open for this weapon: 1 + (mastery - 1) / espaco_a_cada_dominio, capped by the form.
static func open_slots(sheet: CharacterSheet, form_id: String, weapon_id: String) -> int:
	var every: int = maxi(1, int(rule("espaco_a_cada_dominio", 5)))
	var mastery: int = sheet.mastery(CharacterSheet.path_of(weapon_id)) if not CharacterSheet.path_of(weapon_id).is_empty() else 1
	return mini(int(FORMS.get(form_id, {}).get("espacos", 1)), 1 + (mastery - 1) / every)

## Mastery needed for slot number n (1-based).
static func mastery_for_slot(n: int) -> int:
	return 1 + (n - 1) * maxi(1, int(rule("espaco_a_cada_dominio", 5)))

## Forms that suit a weapon style, basic first.
static func forms_for(weapon_id: String) -> Array:
	var out: Array = []
	for id in FORMS:
		if form_fits(id, weapon_id):
			out.append(id)
	return out

## Why a technique cannot be used with this weapon now; "" when it can.
static func problem(sheet: CharacterSheet, recipe: Dictionary, weapon_id: String) -> String:
	var form_id: String = str(recipe.get("form", ""))
	if not FORMS.has(form_id):
		return "Forma desconhecida."
	var form: Dictionary = FORMS[form_id]
	if not form_unlocked(sheet, form_id):
		return "%s ainda trancado: precisa de %s." % [form_name(form_id), requirement_text(form.get("requer", {}))]
	if not form_fits(form_id, weapon_id):
		return "%s não serve para %s." % [form_name(form_id), "as mãos vazias" if weapon_id == "" else str(Items.info(weapon_id).get("name", weapon_id)).to_lower()]
	var comps: Array = recipe.get("components", [])
	var slots: int = open_slots(sheet, form_id, weapon_id)
	if comps.size() > slots:
		return "Só %d %s com o domínio atual desta arma." % [slots, "espaço" if slots == 1 else "espaços"]
	var seen: Dictionary = {}
	for id in comps:
		if not COMPONENTS.has(id):
			return "Componente desconhecido."
		if seen.has(id):
			return "%s repetido." % component_name(id)
		seen[id] = true
		if not component_unlocked(sheet, id):
			return "%s ainda trancado: precisa de %s." % [component_name(id), requirement_text(COMPONENTS[id].get("requer", {}))]
		if not component_fits(id, weapon_id):
			return "%s não combina com esta arma." % component_name(id)
	return ""

## Final numbers of the technique with this weapon: weapon_stats + form + components.
static func stats(sheet: CharacterSheet, recipe: Dictionary, weapon_id: String) -> Dictionary:
	var s: Dictionary = sheet.weapon_stats(weapon_id).duplicate(true)
	if not s.has("damage"):
		return s
	s["hits"] = 1
	s["dash"] = 0.0
	var style: String = style_of(weapon_id)
	var form: Dictionary = FORMS.get(str(recipe.get("form", "")), {})
	for effect in form.get("efeitos", []):
		apply(s, effect, style)
	var comps: Array = recipe.get("components", [])
	for id in comps:
		for effect in COMPONENTS.get(id, {}).get("efeitos", []):
			apply(s, effect, style)
	s["recarga"] = float(form.get("recarga", 1.5)) + rule("recarga_por_componente", 0.75) * comps.size()
	s["technique"] = str(recipe.get("name", form_name(str(recipe.get("form", "")))))
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

## Short lines describing the technique for the editor and tooltips.
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
