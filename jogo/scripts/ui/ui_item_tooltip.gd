extends RefCounted
class_name UiItemTooltip
## Rich tooltip for items: icon, name, category, weight, description and,
## for weapons, the numbers the combat code actually uses.

## Backpack the tooltips read ammunition counts from (set by the HUD).
static var inventory = null
## Adventurer sheet for mastery and unlocked abilities (set by the HUD).
static var sheet = null

static func build(id: String, count: int = 1, equipped: bool = false) -> Control:
	var data: Dictionary = Items.info(id)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.custom_minimum_size.x = 280
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)
	var tex := TextureRect.new()
	tex.texture = UiStyle.item_icon(id)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(46, 46)
	head.add_child(tex)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 1)
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(names)
	names.add_child(UiStyle.label(str(data.get("name", id)), 15, UiStyle.TEXT, "semibold"))
	var cat: Array = UiStyle.category(str(data.get("tag", "")))
	var subtitle: String = cat[0] + ("  ·  em mãos" if equipped else "")
	names.add_child(UiStyle.label(subtitle, 12, cat[1], "medium"))
	var rule := ColorRect.new()
	rule.color = UiStyle.BORDER_SOFT
	rule.custom_minimum_size.y = 1
	root.add_child(rule)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 3)
	root.add_child(grid)
	var unit: float = float(data.get("weight", 0.0))
	_row(grid, "Peso", "%s kg" % UiStyle.fmt(unit, 2) + ("   (%s kg no total)" % UiStyle.fmt(unit * count, 2) if count > 1 else ""))
	if count > 1:
		_row(grid, "Quantidade", str(count))
	if data.has("damage"):
		_weapon_rows(grid, data)
	else:
		_item_rows(grid, id, data)
	var desc := UiStyle.label(str(data.get("description", "")), 13, UiStyle.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 280
	root.add_child(desc)
	return root

static func _row(grid: GridContainer, key: String, value: String) -> void:
	grid.add_child(UiStyle.label(key, 13, UiStyle.DIM))
	grid.add_child(UiStyle.label(value, 13, UiStyle.TEXT, "medium"))

static func _weapon_rows(grid: GridContainer, data: Dictionary) -> void:
	var style: String = str(data.get("style", "slash"))
	if data.has("proficiencias"):
		_row(grid, "Família", ProficiencyTree.path_text(data["proficiencias"]))
	_row(grid, "Empunhadura", "Duas mãos" if int(data.get("maos", 1)) == 2 else "Uma mão")
	if sheet != null and sheet.enabled and data.has("proficiencias"):
		var path: Array = data["proficiencias"]
		_row(grid, "Domínio", "nível %d  ·  +%d%% dano, −%d%% fôlego" % [sheet.mastery(path), roundi((sheet.damage_mult(path) - 1.0) * 100), roundi((1.0 - sheet.cost_mult(path)) * 100)])
	_row(grid, "Dano", "%d" % int(data["damage"]))
	_row(grid, "Alcance", "%s m" % UiStyle.fmt(float(data.get("range", 1.5)), 1))
	_row(grid, "Fôlego por golpe", UiStyle.num(float(data.get("cost", 10))))
	var windup: float = float(data.get("windup", 0.22))
	var delay: float = maxf(float(data.get("cooldown", 0.62)), windup + 0.15) - windup
	var heavy: float = DungeonPlayer.weight_delay(data)
	_row(grid, "Peso do golpe", {"leve": "Leve", "media": "Médio", "pesada": "Pesado"}.get(str(data.get("classe", "media")), "Médio"))
	_row(grid, "Preparação", "%s s" % UiStyle.fmt(windup, 2))
	_row(grid, "Delay depois do golpe", "%s s  ·  esquiva em %s s" % [UiStyle.fmt(delay + heavy, 2), UiStyle.fmt(delay * DungeonPlayer.DODGE_AFTER, 2)])
	if heavy > 0.0:
		_row(grid, "", "inclui %s s do peso (só para golpear de novo)" % UiStyle.fmt(heavy, 2))
	var targets: int = int(data.get("targets", 1))
	match style:
		"thrust":
			_row(grid, "Golpe", "Estocada em linha reta")
			_row(grid, "Alvos", "atravessa até %d" % targets if targets > 1 else "primeiro da linha")
		"smash":
			_row(grid, "Golpe", "Pancada no chão, raio de %s m" % UiStyle.fmt(float(data.get("area_radius", 1.6)), 1))
			_row(grid, "Alvos", "todos na área")
		"shoot":
			var pierce: int = int(data.get("pierce", 1))
			_row(grid, "Golpe", "Disparo à distância")
			_row(grid, "Alvos", "atravessa até %d" % pierce if pierce > 1 else "primeiro atingido")
			for ammo in Items.ammo_list(data):
				var have: String = ("  ·  %d na mochila" % inventory.count(ammo)) if inventory != null else ""
				_row(grid, "Munição", str(Items.info(ammo).get("name", ammo)) + have)
		_:
			_row(grid, "Golpe", "Corte em arco de %d°" % int(float(data.get("angle", 55.0)) * 2))
			_row(grid, "Alvos", "até %d" % targets if targets > 1 else "um")
	var specials: Array = []
	if data.has("sneak_mult"):
		specials.append("Furtivo: dano ×%s em monstro desprevenido" % UiStyle.fmt(float(data["sneak_mult"]), 1))
	if data.has("bleed"):
		specials.append("Sangramento: %d por segundo durante %d s" % [int(data["bleed"].get("dps", 4)), int(data["bleed"].get("time", 4))])
	if data.has("crush"):
		specials.append("Esmaga armadura: dano ×%s em blindados" % UiStyle.fmt(float(data["crush"]), 1))
	if data.has("stagger"):
		specials.append("Atordoa por %s s" % UiStyle.fmt(float(data["stagger"]), 1))
	if float(data.get("knockback", 3.0)) > 3.0:
		specials.append("Empurra forte")
	for i in specials.size():
		_row(grid, "Especial" if i == 0 else "", specials[i])

static func _item_rows(grid: GridContainer, id: String, data: Dictionary) -> void:
	var effects: PackedStringArray = []
	if data.get("stops_bleeding", false):
		effects.append("estanca sangramento")
	if data.has("heal"):
		effects.append("+%d vida" % int(data["heal"]))
	if data.has("food"):
		effects.append("+%d saciedade" % int(data["food"]))
	if data.has("stamina_gain"):
		effects.append("+%d fôlego" % int(data["stamina_gain"]))
	if not effects.is_empty():
		var text: String = ", ".join(effects)
		_row(grid, "Efeito", text.substr(0, 1).to_upper() + text.substr(1))
	if data.has("protection"):
		var heavy: bool = data.get("armor_type", "") == "pesada"
		_row(grid, "Tipo", "Armadura pesada" if heavy else "Armadura leve")
		var effective: float = sheet.armor_protection(id) if sheet != null else float(data["protection"])
		_row(grid, "Proteção", "%d%% de cada golpe" % roundi(effective * 100))
		var penalty_mult: float = sheet.armor_penalty_mult(id) if sheet != null else 1.0
		var penalties: PackedStringArray = []
		if float(data.get("speed_penalty", 0)) > 0:
			penalties.append("passo −%d%%" % roundi(float(data["speed_penalty"]) * penalty_mult * 100))
		if float(data.get("regen_penalty", 0)) > 0:
			penalties.append("fôlego recupera −%d%%" % roundi(float(data["regen_penalty"]) * penalty_mult * 100))
		_row(grid, "Penalidade", ", ".join(penalties) if not penalties.is_empty() else "nenhuma")
		var noise: float = sheet.armor_noise(id) if sheet != null else float(data.get("noise", 0))
		_row(grid, "Barulho", "monstros te notam %d%% mais longe" % roundi(noise * 50) if noise > 0 else "silenciosa")
		_row(grid, "Treina", ProficiencyTree.path_text(data.get("proficiencias", [])))
	if id == "gazua":
		_row(grid, "Uso", "abre baús trancados  [E]")
		if sheet != null:
			_row(grid, "Chance", "simples %d%%, média %d%%, difícil %d%%, mestre %d%%" % [roundi(sheet.pick_chance(1) * 100), roundi(sheet.pick_chance(2) * 100), roundi(sheet.pick_chance(3) * 100), roundi(sheet.pick_chance(4) * 100)])
	if data.get("tag", "") == "MUNICAO":
		var users: PackedStringArray = []
		for other in Items.DATA:
			if Items.fires(other, id):
				users.append(str(Items.info(other).get("name", other)))
		_row(grid, "Usada por", ", ".join(users))
		if float(data.get("recover", 0.0)) > 0:
			_row(grid, "Recuperação", "%d%% das que erram ficam no chão" % roundi(float(data["recover"]) * 100))
