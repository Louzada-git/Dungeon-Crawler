extends UiWindow
class_name UiHealthWindow
## Condition window (H). Does not pause: it can stay open while exploring.

var game
var ui
var tabs: Dictionary = {}
var pages: Dictionary = {}
var figure: UiBodyFigure
var summary: Label
var rows: Dictionary = {}
var bleed_value: Label
var load_value: Label
var bandage_button: Button
var ration_button: Button
var info_grid: GridContainer
var info_values: Dictionary = {}
var current_tab: String = "health"
var subtitle: Label

func _init(game_ref, ui_ref) -> void:
	super._init("Condição física", UiIcon.new("pulse", UiStyle.TEXT), 400, 452)
	game = game_ref
	ui = ui_ref
	# Right side, below the inventory windows and left of the status column.
	position = Vector2(976, 412)
	close_requested.connect(func(): ui.toggle_health())
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 2)
	body.add_child(tab_row)
	for entry in [["health", "Saúde"], ["character", "Personagem"]]:
		var b := UiStyle.button(entry[1], _show_tab.bind(entry[0]), 110)
		tab_row.add_child(b)
		tabs[entry[0]] = b
	var rule := ColorRect.new()
	rule.color = UiStyle.BORDER_SOFT
	rule.custom_minimum_size.y = 1
	body.add_child(rule)
	_build_health_page()
	_build_character_page()
	_show_tab("health")

func _build_health_page() -> void:
	var page := HBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(page)
	pages["health"] = page
	figure = UiBodyFigure.new()
	page.add_child(figure)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 7)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(col)
	col.add_child(UiStyle.caps("Estado geral", 10, UiStyle.DIM))
	summary = UiStyle.label("", 17, UiStyle.TEXT, "semibold")
	col.add_child(summary)
	for entry in [["health", "Vida"], ["stamina", "Fôlego"], ["food", "Saciedade"]]:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		col.add_child(row)
		var line := HBoxContainer.new()
		row.add_child(line)
		var caption := UiStyle.label(entry[1], 13, UiStyle.MUTED)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(caption)
		var value := UiStyle.label("", 13, UiStyle.TEXT, "semibold")
		line.add_child(value)
		var meter := UiStyle.bar(Vector2(0, 6), UiStyle.GOOD)
		row.add_child(meter)
		rows[entry[0]] = [value, meter]
	var bleed_line := HBoxContainer.new()
	col.add_child(bleed_line)
	var bleed_name := UiStyle.label("Sangramento", 13, UiStyle.MUTED)
	bleed_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bleed_line.add_child(bleed_name)
	bleed_value = UiStyle.label("", 13, UiStyle.TEXT, "semibold")
	bleed_line.add_child(bleed_value)
	var load_line := HBoxContainer.new()
	col.add_child(load_line)
	var load_name := UiStyle.label("Carga", 13, UiStyle.MUTED)
	load_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_line.add_child(load_name)
	load_value = UiStyle.label("", 13, UiStyle.TEXT, "semibold")
	load_line.add_child(load_value)
	var gap := Control.new()
	gap.custom_minimum_size.y = 2
	col.add_child(gap)
	col.add_child(UiStyle.caps("Tratamento", 10, UiStyle.DIM))
	bandage_button = UiStyle.button("", func(): ui.quick_use("bandage"))
	bandage_button.clip_text = true
	bandage_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(bandage_button)
	ration_button = UiStyle.button("", func(): ui.quick_use("ration"))
	ration_button.clip_text = true
	ration_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(ration_button)
	var note := UiStyle.label("O desenho mostra a condição geral do corpo. Ferimentos por região ainda não são simulados.", 11, UiStyle.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 220
	col.add_child(note)

func _build_character_page() -> void:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(page)
	pages["character"] = page
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	page.add_child(head)
	var portrait := UiBodyFigure.new()
	portrait.custom_minimum_size = Vector2(46, 96)
	head.add_child(portrait)
	var names := VBoxContainer.new()
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(names)
	names.add_child(UiStyle.label("Aventureiro", 18, UiStyle.TEXT, "semibold"))
	subtitle = UiStyle.label("", 13, UiStyle.MUTED)
	names.add_child(subtitle)
	info_grid = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 16)
	info_grid.add_theme_constant_override("v_separation", 6)
	page.add_child(info_grid)
	for entry in [["weapon", "Em mãos"], ["damage", "Dano / alcance"], ["cost", "Fôlego por golpe"], ["area", "Área atual"], ["objective", "Objetivo"], ["depth", "Andar mais fundo"], ["seals", "Selos entregues"], ["kills", "Monstros derrotados"], ["hits", "Golpes recebidos"], ["load", "Carga"]]:
		info_grid.add_child(UiStyle.label(entry[1], 13, UiStyle.DIM))
		var value := UiStyle.label("", 13, UiStyle.TEXT, "medium")
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value.custom_minimum_size.x = 180
		info_grid.add_child(value)
		info_values[entry[0]] = value
	var note := UiStyle.label("Proficiências e técnicas aparecerão aqui quando forem implementadas.", 11, UiStyle.DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 360
	page.add_child(note)

func _show_tab(id: String) -> void:
	current_tab = id
	for key in pages:
		pages[key].visible = key == id
		var active: bool = key == id
		tabs[key].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.TITLE_HOVER if active else Color(0.07, 0.07, 0.065, 0.9), UiStyle.ACCENT if active else UiStyle.BORDER_SOFT, 1, Vector4(12, 3, 12, 4)))
		tabs[key].add_theme_color_override("font_color", UiStyle.ACCENT if active else UiStyle.MUTED)
	refresh()
	# Pages differ in height; drop the size the other page left behind.
	reset_size.call_deferred()

static func condition_name(health: float, bleeding: bool) -> Array:
	if health <= 0:
		return ["Morto", UiStyle.BAD]
	if bleeding and health < 50:
		return ["Ferido e sangrando", UiStyle.BAD]
	if bleeding:
		return ["Sangrando", UiStyle.BAD]
	if health < 25:
		return ["Gravemente ferido", UiStyle.BAD]
	if health < 50:
		return ["Ferido", UiStyle.WARN]
	if health < 75:
		return ["Machucado", UiStyle.WARN]
	return ["Saudável", UiStyle.GOOD]

func refresh() -> void:
	if not visible or game.player == null:
		return
	var p = game.player
	if pages["health"].visible:
		figure.set_state(p.health / p.max_health * 100.0, p.bleeding)
		var cond: Array = condition_name(p.health, p.bleeding)
		summary.text = cond[0]
		summary.add_theme_color_override("font_color", cond[1])
		for key in rows:
			var v: float = p.get(key)
			var top: float = {"health": p.max_health, "stamina": p.max_stamina}.get(key, 100.0)
			rows[key][0].text = "%d / %d" % [ceili(v), roundi(top)]
			rows[key][1].max_value = top
			rows[key][1].value = v
			UiStyle.set_bar_color(rows[key][1], UiStyle.value_color(v / top))
		bleed_value.text = "Sim  ·  −0,5 vida/s" if p.bleeding else "Não"
		bleed_value.add_theme_color_override("font_color", UiStyle.BAD if p.bleeding else UiStyle.GOOD)
		var w: float = game.inventory.weight()
		load_value.text = "%s kg  ·  %s" % [UiStyle.fmt(w), "normal" if w <= game.inventory.comfort else "pesada"]
		load_value.add_theme_color_override("font_color", UiStyle.TEXT if w <= game.inventory.comfort else UiStyle.WARN)
		var bandages: int = game.inventory.count("bandage")
		var rations: int = game.inventory.count("ration")
		bandage_button.text = "Bandagem  ·  %d   [3]" % bandages
		bandage_button.disabled = bandages == 0 or game.ended
		ration_button.text = "Ração  ·  %d   [2]" % rations
		ration_button.disabled = rations == 0 or game.ended
	else:
		var weapon: Dictionary = Items.info(game.inventory.equipped)
		info_values["weapon"].text = weapon.get("name", "Mãos vazias")
		info_values["damage"].text = ("%d  ·  %s m" % [int(weapon["damage"]), UiStyle.fmt(float(weapon.get("range", 1.5)))]) if weapon.has("damage") else "—"
		info_values["cost"].text = str(int(weapon.get("cost", 10)))
		info_values["area"].text = game.layout.room_name(p.position)
		info_values["objective"].text = game.objective_text()
		info_values["depth"].text = "%dº  (agora no %dº)" % [game.deepest, game.floor] if game.generated else "—"
		info_values["seals"].text = str(game.seals_delivered)
		subtitle.text = ("Labirinto %d" % game.seed) if game.generated else "Expedição às cisternas"
		info_values["kills"].text = str(game.kills)
		info_values["hits"].text = str(game.hits_received)
		info_values["load"].text = "%s de %s kg" % [UiStyle.fmt(game.inventory.weight()), UiStyle.fmt(game.inventory.capacity, 0)]
