extends UiWindow
class_name UiCreationPanel
## "New adventurer": spends the attribute points at the start of every run
## (a death starts a new adventurer in the same labyrinth).

signal confirmed(values: Dictionary)

var values: Dictionary = {}
var value_labels: Dictionary = {}
var minus_buttons: Dictionary = {}
var plus_buttons: Dictionary = {}
var points_label: Label
var start_button: Button
var total: int = 20
var low: int = 2
var high: int = 9

func _init() -> void:
	super._init("Novo aventureiro", UiIcon.new("star", UiStyle.ACCENT), 700, 400, false)
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
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)
	points_label = UiStyle.label("", 14, UiStyle.TEXT, "medium")
	body.add_child(points_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	body.add_child(buttons)
	var even := UiStyle.button("Equilibrado", func(): reset(), 140)
	even.custom_minimum_size.y = 36
	buttons.add_child(even)
	start_button = UiStyle.button("Começar expedição", func(): confirmed.emit(values.duplicate()), 220)
	start_button.custom_minimum_size.y = 36
	buttons.add_child(start_button)
	reset()

func reset() -> void:
	var start: int = int(ProficiencyTree.section("criacao").get("padrao", 5))
	for id in ProficiencyTree.ATTRIBUTE_ORDER:
		values[id] = start
	refresh()

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
