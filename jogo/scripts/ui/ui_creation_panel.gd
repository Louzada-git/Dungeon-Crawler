extends UiWindow
class_name UiCreationPanel
## "New adventurer": spends the attribute points and picks the starting weapon
## (any weapon, or bare fists) at the start of every run (a death starts a new
## adventurer in the same labyrinth). confirmed carries the attributes plus
## "arma" (item id, "" for the fists).

signal confirmed(values: Dictionary)

var values: Dictionary = {}
var value_labels: Dictionary = {}
var minus_buttons: Dictionary = {}
var plus_buttons: Dictionary = {}
var points_label: Label
var start_button: Button
var total: int = 25
## Starting weapon ("" = fists) and its buttons.
var weapon: String = "sword"
var weapon_buttons: Dictionary = {}
var weapon_label: Label
var low: int = 2
var high: int = 9

func _init() -> void:
	super._init("Novo aventureiro", UiIcon.new("star", UiStyle.ACCENT), 700, 560, false)
	draggable = false
	var rules: Dictionary = ProficiencyTree.section("criacao")
	total = int(rules.get("pontos", 20))
	low = int(rules.get("minimo", 2))
	high = int(rules.get("maximo", 9))
	var intro := UiStyle.label("Atributos são o potencial do personagem: mudam vida, fôlego e carga, e definem a rapidez e o limite do aprendizado em cada proficiência. As proficiências em si só crescem com o uso.", 14, UiStyle.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = 660
	body.add_child(intro)
	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	body.add_child(grid)
	for id in ProficiencyTree.ATTRIBUTE_ORDER:
		var info: Dictionary = ProficiencyTree.ATTRIBUTES.get(id, {})
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		grid.add_child(row)
		var attr_label := UiStyle.label(str(info.get("name", id)), 16, UiStyle.TEXT, "semibold")
		attr_label.custom_minimum_size.x = 104
		attr_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(attr_label)
		var minus := UiStyle.button("−", _change.bind(id, -1), 34)
		row.add_child(minus)
		var value := UiStyle.label("", 20, UiStyle.ACCENT, "bold")
		value.custom_minimum_size.x = 30
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(value)
		var plus := UiStyle.button("+", _change.bind(id, 1), 34)
		row.add_child(plus)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		var effect := UiStyle.label(str(info.get("text", "")), 12, UiStyle.MUTED)
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect.custom_minimum_size.x = 440
		col.add_child(effect)
		var governs: PackedStringArray = []
		for b in ProficiencyTree.DATA:
			if ProficiencyTree.DATA[b].get("atributo", "") == id:
				governs.append(ProficiencyTree.display_name(b))
		var potential := UiStyle.label("Potencial: " + ", ".join(governs), 11, UiStyle.DIM)
		potential.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		potential.custom_minimum_size.x = 440
		col.add_child(potential)
		value_labels[id] = value
		minus_buttons[id] = minus
		plus_buttons[id] = plus
	_build_weapons()
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)
	points_label = UiStyle.label("", 14, UiStyle.TEXT, "medium")
	body.add_child(points_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	body.add_child(buttons)
	var even := UiStyle.button("Recomeçar", func(): reset(), 140)
	even.custom_minimum_size.y = 36
	buttons.add_child(even)
	start_button = UiStyle.button("Começar expedição", func(): confirmed.emit(choice()), 220)
	start_button.custom_minimum_size.y = 36
	buttons.add_child(start_button)
	reset()

func reset() -> void:
	var start: int = int(ProficiencyTree.section("criacao").get("padrao", 5))
	for id in ProficiencyTree.ATTRIBUTE_ORDER:
		values[id] = start
	pick_weapon("sword")
	refresh()

## Attributes plus the chosen weapon, as sent to main.start_character.
func choice() -> Dictionary:
	var out: Dictionary = values.duplicate()
	out["arma"] = weapon
	return out

## Every weapon in the item data, then the bare fists.
static func weapon_ids() -> Array:
	var out: Array = []
	for id in Items.DATA:
		if Items.DATA[id].has("style"):
			out.append(id)
	out.append("")
	return out

func _build_weapons() -> void:
	body.add_child(UiStyle.caps("Arma inicial  ·  qualquer uma", 11, UiStyle.MUTED))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	body.add_child(grid)
	var group := ButtonGroup.new()
	for id in weapon_ids():
		var b := UiStyle.button("" if id != "" else "Punhos", pick_weapon.bind(id))
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(92, 46)
		if id != "":
			b.icon = UiStyle.item_icon(id)
			b.expand_icon = true
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.tooltip_text = _weapon_name(id)
		grid.add_child(b)
		weapon_buttons[id] = b
	weapon_label = UiStyle.label("", 13, UiStyle.TEXT)
	weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_label.custom_minimum_size.x = 660
	body.add_child(weapon_label)

func _weapon_name(id: String) -> String:
	return "Punhos (sem arma)" if id == "" else str(Items.info(id).get("name", id))

func pick_weapon(id: String) -> void:
	if not weapon_buttons.has(id):
		return
	weapon = id
	for other in weapon_buttons:
		weapon_buttons[other].set_pressed_no_signal(other == id)
	var data: Dictionary = CharacterSheet.base_stats(id)
	var line: String = "%s  ·  dano %s  ·  alcance %s m  ·  treina %s" % [_weapon_name(id), UiStyle.fmt(data.get("damage", 0.0), 0), UiStyle.fmt(data.get("range", 0.0)), ProficiencyTree.path_text(CharacterSheet.path_of(id))]
	var ammo: String = str(data.get("ammo", ""))
	if ammo != "":
		line += "  ·  vem com %d %ss" % [starting_ammo(), str(Items.info(ammo).get("name", ammo)).to_lower()]
	weapon_label.text = line

## Ammunition that comes with a starting bow or crossbow.
static func starting_ammo() -> int:
	return int(ProficiencyTree.section("criacao").get("municao_inicial", 20))

func spent() -> int:
	var n: int = 0
	for id in values:
		n += int(values[id])
	return n

func _change(id: String, step: int) -> void:
	var next: int = int(values[id]) + step
	if next < low or next > high:
		return
	if step > 0 and spent() >= total:
		return
	values[id] = next
	refresh()

func refresh() -> void:
	var left: int = total - spent()
	for id in values:
		value_labels[id].text = str(values[id])
		minus_buttons[id].disabled = int(values[id]) <= low
		plus_buttons[id].disabled = int(values[id]) >= high or left <= 0
	points_label.text = "Pontos livres: %d" % left if left > 0 else "Todos os pontos distribuídos."
	points_label.add_theme_color_override("font_color", UiStyle.WARN if left > 0 else UiStyle.GOOD)
	start_button.disabled = left != 0
