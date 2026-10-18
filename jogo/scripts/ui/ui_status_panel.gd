extends PanelContainer
class_name UiStatusPanel
## Compact condition panel: icon, value and bar for each vital sign.

signal open_requested

var game: DungeonGame
var cells: Dictionary = {}

## [id, icon, title]; the tooltip text comes from tip_text, with this adventurer's numbers.
const ENTRIES := [
	["health", "heart", "Vida"],
	["stamina", "lungs", "Fôlego"],
	["food", "bread", "Saciedade"],
	["load", "weight", "Carga"],
]

## Tooltip of a cell, from the rules as they are now for this adventurer.
func tip_text(id: String) -> String:
	match id:
		"health":
			return "Vida atual. Não se recupera sozinha: uma bandagem restaura %d." % UiMoodles.bandage_heal(game)
		"stamina":
			return "Gasto ao correr, golpear e esquivar. Recupera %s por segundo parado ou caminhando." % UiStyle.fmt(game.player.stamina_regen(game.player.food <= DungeonPlayer.HUNGRY), 1)
		"food":
			return "Cai com o tempo, mais rápido correndo. Abaixo de %d, o fôlego recupera devagar." % roundi(DungeonPlayer.HUNGRY)
		"load":
			return "Peso na mochila. " + UiMoodles.load_rule(game)
	return ""

func _init(game_ref: DungeonGame) -> void:
	game = game_ref
	custom_minimum_size = Vector2(320, 0)
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PANEL, UiStyle.BORDER_SOFT, 1, Vector4(8, 5, 8, 7)))
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Abrir condição física  [H]"
	gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_requested.emit()
	)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(head)
	var title := UiStyle.caps("Condição", 11, UiStyle.MUTED)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UiStyle.caps("H", 10, UiStyle.DIM))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(grid)
	for entry in ENTRIES:
		var cell := Cell.new()
		cell.title = entry[2]
		cell.text_of = tip_text.bind(entry[0])
		cell.add_theme_constant_override("separation", 3)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.tooltip_text = entry[2]
		grid.add_child(cell)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(row)
		var icon := UiIcon.new(entry[1], UiStyle.TEXT, 18)
		row.add_child(icon)
		var value := UiStyle.label("", 14, UiStyle.TEXT, "semibold")
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value)
		var meter := UiStyle.bar(Vector2(0, 5), UiStyle.GOOD)
		cell.add_child(meter)
		var caption := UiStyle.caps(entry[2], 9, UiStyle.DIM)
		cell.add_child(caption)
		cells[entry[0]] = {"icon": icon, "value": value, "bar": meter, "last": ""}

func refresh() -> void:
	var p = game.player
	if p == null:
		return
	_set_cell("health", p.health / p.max_health * 100.0, str(ceili(p.health)), p.health / p.max_health)
	_set_cell("stamina", p.stamina / p.max_stamina * 100.0, str(ceili(p.stamina)), p.stamina / p.max_stamina)
	_set_cell("food", p.food, str(ceili(p.food)), p.food / 100.0)
	var w: float = game.inventory.weight()
	var load_ratio: float = 1.0 if w <= game.inventory.comfort else (0.45 if w <= lerpf(game.inventory.comfort, game.inventory.capacity, 0.57) else 0.15)
	_set_cell("load", w / game.inventory.capacity * 100.0, UiStyle.fmt(w) + " kg", load_ratio)

func _set_cell(id: String, bar_value: float, text: String, ratio: float) -> void:
	var cell: Dictionary = cells[id]
	var color: Color = UiStyle.value_color(ratio)
	if id == "health" and game.player.bleeding:
		color = UiStyle.BLOOD
	var key := "%s|%s" % [text, color.to_html()]
	cell["bar"].value = bar_value
	if cell["last"] == key:
		return
	cell["last"] = key
	cell["value"].text = text
	cell["value"].add_theme_color_override("font_color", UiStyle.TEXT if ratio >= 0.3 else color.lightened(0.2))
	cell["icon"].set_kind(cell["icon"].kind, UiStyle.TEXT if ratio >= 0.6 else color.lightened(0.15))
	UiStyle.set_bar_color(cell["bar"], color)

class Cell extends VBoxContainer:
	var title: String = ""
	var text_of: Callable
	func _make_custom_tooltip(_for_text: String) -> Object:
		return UiStyle.tip(title, str(text_of.call()) + "\nClique para abrir a condição física  [H].")
