extends CanvasLayer
## HUD root. Layout and reading follow Project Zomboid: tool bar on the left,
## collapsible inventory windows at the top, condition and status indicators
## on the right, quick slots at the bottom. Pieces live in scripts/ui/.

const HELP_ROWS := [
	[["W", "A", "S", "D"], "Mover (setas também)"],
	[["Shift"], "Correr — gasta fôlego"],
	[["Espaço"], "Esquivar — 25 de fôlego"],
	[["Botão dir."], "Mirar e andar em guarda"],
	[["Botão esq."], "Atacar na direção do cursor"],
	[["E"], "Vasculhar, abrir baú, descansar"],
	[["I", "Tab"], "Mochila (pausa o jogo)"],
	[["M"], "Mapa explorado (pausa o jogo)"],
	[["H"], "Condição física"],
	[["1", "2", "3"], "Mochila · comer · bandagem"],
	[["F5"], "Salvar  ·  Esc: pausa"],
]

var game
var root: Control
var hud: Control
var modal: Control
var dim: ColorRect
var flash: ColorRect
var vignette: TextureRect
var sidebar: UiSidebar
var inventory: UiInventory
var inventory_panel: UiWindow
var status_panel: UiStatusPanel
var moodles: UiMoodles
var hotbar: UiHotbar
var hands: PanelContainer
var hands_icon: TextureRect
var hands_fallback: UiIcon
var hands_name: Label
var hands_stats: Label
var area_label: Label
var objective: Label
var prompt_row: HBoxContainer
var toast_row: HBoxContainer
var badge_row: HBoxContainer
var prompt_box: PanelContainer
var prompt_key: Label
var prompt_text: Label
var toast: PanelContainer
var toast_label: Label
var paused_badge: PanelContainer
var health_panel: UiHealthWindow
var map_panel: UiWindow
var full_map: DungeonMapView
var mini_map: DungeonMapView
var pause_panel: UiWindow
var pause_title: Label
var pause_note: Label
var controls_box: Control
var sound_button: Button
var pause_confirm: bool = false
var ending_panel: UiWindow
var end_title: Label
var end_note: Label
var end_stats: GridContainer
var _time: float = 0.0
var _last_hands: String = ""
var _last_prompt: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiStyle.build_theme()
	add_child(root)
	_build_effects()
	_build_hud()
	_build_modals()
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.7, 0.12, 0.06, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	update_hud()

# --- construction ------------------------------------------------------------

func _build_effects() -> void:
	# Red edges when life is low, under every panel.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.55, 0.02, 0.02, 0.0))
	gradient.set_color(1, Color(0.55, 0.02, 0.02, 0.85))
	gradient.add_point(0.55, Color(0.55, 0.02, 0.02, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	texture.width = 256
	texture.height = 160
	vignette = TextureRect.new()
	vignette.texture = texture
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.modulate.a = 0.0
	root.add_child(vignette)

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	sidebar = UiSidebar.new()
	hud.add_child(sidebar)
	sidebar.add_tool("inventory", "bag", "Mochila", "I", toggle_inventory)
	sidebar.add_tool("health", "pulse", "Condição física", "H", toggle_health)
	sidebar.add_tool("map", "map", "Mapa explorado", "M", toggle_map)
	sidebar.add_gap(10)
	sidebar.add_tool("pause", "gear", "Pausa e controles", "Esc", toggle_pause)
	# Objective tracker, top right
	var tracker := VBoxContainer.new()
	tracker.add_theme_constant_override("separation", 1)
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.position = Vector2(1100, 6)
	tracker.custom_minimum_size = Vector2(330, 0)
	hud.add_child(tracker)
	area_label = UiStyle.shadowed(UiStyle.label("", 16, UiStyle.TEXT, "semibold"))
	area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tracker.add_child(area_label)
	var objective_row := HBoxContainer.new()
	objective_row.alignment = BoxContainer.ALIGNMENT_END
	objective_row.add_theme_constant_override("separation", 5)
	objective_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.add_child(objective_row)
	objective_row.add_child(UiIcon.new("flag", UiStyle.ACCENT, 14))
	objective = UiStyle.shadowed(UiStyle.label("", 13, UiStyle.ACCENT, "medium"))
	objective_row.add_child(objective)
	status_panel = UiStatusPanel.new(game)
	status_panel.position = Vector2(1110, 58)
	status_panel.open_requested.connect(toggle_health)
	hud.add_child(status_panel)
	moodles = UiMoodles.new(game)
	moodles.position = Vector2(1386, 160)
	hud.add_child(moodles)
	hotbar = UiHotbar.new(game, self)
	hotbar.position = Vector2(720 - 99, 900 - 72)
	hud.add_child(hotbar)
	_build_hands()
	_build_prompts()
	inventory = UiInventory.new(game, self)
	hud.add_child(inventory)
	inventory_panel = inventory.bag_window
	health_panel = UiHealthWindow.new(game, self)
	health_panel.hide()
	hud.add_child(health_panel)
	mini_map = DungeonMapView.new()
	mini_map.game = game
	mini_map.hide()
	hud.add_child(mini_map)

func _build_hands() -> void:
	hands = HandsCard.new()
	hands.ui = self
	hands.position = Vector2(12, 900 - 86)
	hands.custom_minimum_size = Vector2(330, 74)
	hands.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PANEL, UiStyle.BORDER_SOFT, 1, Vector4(8, 6, 12, 6)))
	hands.mouse_filter = Control.MOUSE_FILTER_STOP
	hands.tooltip_text = "Em mãos"
	hud.add_child(hands)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hands.add_child(row)
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(60, 60)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)
	hands_icon = TextureRect.new()
	hands_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hands_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hands_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hands_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(hands_icon)
	hands_fallback = UiIcon.new("hand", UiStyle.MUTED)
	hands_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hands_fallback.offset_left = 12
	hands_fallback.offset_top = 12
	hands_fallback.offset_right = -12
	hands_fallback.offset_bottom = -12
	frame.add_child(hands_fallback)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	col.add_child(UiStyle.caps("Em mãos", 10, UiStyle.DIM))
	hands_name = UiStyle.label("", 16, UiStyle.TEXT, "semibold")
	col.add_child(hands_name)
	hands_stats = UiStyle.label("", 12, UiStyle.MUTED)
	col.add_child(hands_stats)

## Full-width row that keeps its child centered as the text changes size.
func _center_row(y: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.position = Vector2(0, y)
	row.size = Vector2(1440, 0)
	hud.add_child(row)
	return row

func _build_prompts() -> void:
	prompt_row = _center_row(900 - 128)
	toast_row = _center_row(900 - 172)
	badge_row = _center_row(900 - 116)
	prompt_box = PanelContainer.new()
	var pill := UiStyle.box(Color(0.03, 0.03, 0.028, 0.78), UiStyle.BORDER_SOFT, 1, Vector4(8, 5, 14, 5))
	prompt_box.add_theme_stylebox_override("panel", pill)
	prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_row.add_child(prompt_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_box.add_child(row)
	var cap := UiStyle.keycap("E", 13)
	row.add_child(cap)
	prompt_key = cap.get_child(0)
	prompt_text = UiStyle.label("", 15, UiStyle.TEXT, "medium")
	prompt_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(prompt_text)
	toast = PanelContainer.new()
	toast.add_theme_stylebox_override("panel", UiStyle.box(Color(0.03, 0.03, 0.028, 0.72), Color(0, 0, 0, 0), 0, Vector4(16, 6, 16, 7)))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_row.add_child(toast)
	toast_label = UiStyle.shadowed(UiStyle.label("", 14, UiStyle.TEXT))
	toast.add_child(toast_label)
	paused_badge = PanelContainer.new()
	paused_badge.add_theme_stylebox_override("panel", UiStyle.box(Color(0.03, 0.03, 0.028, 0.86), UiStyle.ACCENT_DARK, 1, Vector4(14, 5, 14, 6)))
	paused_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(paused_badge)
	var badge_line := HBoxContainer.new()
	badge_line.add_theme_constant_override("separation", 8)
	paused_badge.add_child(badge_line)
	badge_line.add_child(UiStyle.caps("Pausado", 12, UiStyle.ACCENT))
	badge_line.add_child(UiStyle.label("o tempo para enquanto a mochila ou o mapa estão abertos", 13, UiStyle.MUTED))
	paused_badge.hide()

func _build_modals() -> void:
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(modal)
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(dim)
	modal.hide()
	_build_map()
	_build_pause()
	_build_ending()

func _centered(window: UiWindow) -> void:
	window.position = (Vector2(1440, 900) - window.custom_minimum_size) * 0.5
	modal.add_child(window)
	window.hide()

func _build_map() -> void:
	map_panel = UiWindow.new("Mapa explorado  ·  As Cisternas", UiIcon.new("map", UiStyle.TEXT), 1060, 740)
	map_panel.close_requested.connect(close_all)
	_centered(map_panel)
	full_map = DungeonMapView.new()
	full_map.game = game
	full_map.large = true
	full_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	full_map.clip_contents = true
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiStyle.box(Color(0.015, 0.018, 0.018, 0.96), UiStyle.BORDER_SOFT, 1, Vector4(0, 0, 0, 0)))
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(full_map)
	map_panel.body.add_child(frame)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 18)
	map_panel.body.add_child(legend)
	for entry in [["arrow", Color("faf0d6"), "Você"], ["tent", Color("79c9a4"), "Abrigo"], ["chest", Color("c99a5b"), "Recipiente com itens"], ["diamond", Color("4f665f"), "Área explorada"]]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		item.add_child(UiIcon.new(entry[0], entry[1], 16))
		item.add_child(UiStyle.label(entry[2], 13, UiStyle.MUTED))
		legend.add_child(item)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.add_child(spacer)
	legend.add_child(UiStyle.label("Só aparece o que você já viu.", 13, UiStyle.DIM))
	legend.add_child(UiStyle.keycap("M"))
	legend.add_child(UiStyle.label("fecha", 13, UiStyle.DIM))

func _build_pause() -> void:
	pause_panel = UiWindow.new("Pausa", UiIcon.new("gear", UiStyle.TEXT), 780, 430)
	pause_panel.close_requested.connect(close_all)
	_centered(pause_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pause_panel.body.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size.x = 230
	row.add_child(left)
	pause_title = UiStyle.label("Um momento de respiro", 20, UiStyle.TEXT, "semibold")
	pause_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(pause_title)
	left.add_child(UiStyle.label("O tempo está parado.", 13, UiStyle.MUTED))
	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	left.add_child(gap)
	for entry in [["Continuar", close_all], ["Salvar expedição", func(): game.save_game(); close_all()]]:
		var b := UiStyle.button(entry[0], entry[1])
		b.custom_minimum_size.y = 34
		left.add_child(b)
	sound_button = UiStyle.button("Som: ligado", func():
		game.sound.enabled = not game.sound.enabled
		sound_button.text = "Som: ligado" if game.sound.enabled else "Som: desligado"
	)
	sound_button.custom_minimum_size.y = 34
	left.add_child(sound_button)
	var restart := UiStyle.button("Nova expedição", confirm_restart)
	restart.custom_minimum_size.y = 34
	left.add_child(restart)
	var quit := UiStyle.button("Salvar e sair", func():
		if game.save_game(false):
			get_tree().quit()
	)
	quit.custom_minimum_size.y = 34
	left.add_child(quit)
	pause_note = UiStyle.label("", 13, UiStyle.WARN)
	pause_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(pause_note)
	row.add_child(VSeparator.new())
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	right.add_child(UiStyle.caps("Controles", 11, UiStyle.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 7)
	right.add_child(grid)
	controls_box = grid
	for entry in HELP_ROWS:
		var keys := HBoxContainer.new()
		keys.add_theme_constant_override("separation", 3)
		keys.custom_minimum_size.x = 170
		keys.alignment = BoxContainer.ALIGNMENT_END
		for key in entry[0]:
			keys.add_child(UiStyle.keycap(key, 12))
		grid.add_child(keys)
		grid.add_child(UiStyle.label(entry[1], 13, UiStyle.TEXT))

func _build_ending() -> void:
	ending_panel = UiWindow.new("Fim da incursão", UiIcon.new("flag", UiStyle.TEXT), 640, 330, false)
	_centered(ending_panel)
	ending_panel.draggable = false
	end_title = UiStyle.label("", 28, UiStyle.TEXT, "bold")
	ending_panel.body.add_child(end_title)
	end_note = UiStyle.label("", 15, UiStyle.MUTED)
	end_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_panel.body.add_child(end_note)
	var rule := ColorRect.new()
	rule.color = UiStyle.BORDER_SOFT
	rule.custom_minimum_size.y = 1
	ending_panel.body.add_child(rule)
	end_stats = GridContainer.new()
	end_stats.columns = 2
	end_stats.add_theme_constant_override("h_separation", 24)
	end_stats.add_theme_constant_override("v_separation", 6)
	ending_panel.body.add_child(end_stats)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ending_panel.body.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	ending_panel.body.add_child(buttons)
	var again := UiStyle.button("Nova expedição — reiniciar progresso", func(): game.restart())
	again.custom_minimum_size.y = 36
	buttons.add_child(again)
	var leave := UiStyle.button("Sair", func(): get_tree().quit(), 110)
	leave.custom_minimum_size.y = 36
	buttons.add_child(leave)

# --- per frame -----------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	if game == null or game.player == null:
		return
	var low: float = clampf((35.0 - game.player.health) / 35.0, 0.0, 1.0)
	var target: float = 0.0
	if game.player.health > 0 and low > 0:
		target = low * (0.55 + 0.25 * sin(_time * (2.2 + low * 2.5)))
	vignette.modulate.a = lerpf(vignette.modulate.a, target, minf(1.0, delta * 6.0))
	# The game node stops while paused; keep the HUD current from here.
	if get_tree().paused:
		update_hud()

func update_hud() -> void:
	if game == null or game.player == null or status_panel == null:
		return
	status_panel.refresh()
	moodles.refresh()
	hotbar.refresh()
	inventory.update_bars()
	if health_panel.visible:
		health_panel.refresh()
	sidebar.set_active("inventory", inventory.is_open)
	sidebar.set_active("health", health_panel.visible)
	sidebar.set_active("map", map_panel.visible)
	sidebar.set_active("pause", pause_panel.visible)
	_update_hands()
	var area: String = game.layout.room_name(game.player.position)
	if area_label.text != area:
		area_label.text = area
	objective.text = "Retorne ao abrigo com o selo" if game.inventory.count("seal") > 0 else "Recupere o selo das cisternas"
	_update_prompt()
	_update_toast()
	if full_map.is_visible_in_tree():
		full_map.queue_redraw()

func _update_hands() -> void:
	var id: String = game.inventory.equipped
	if id == _last_hands:
		return
	_last_hands = id
	var data: Dictionary = Items.info(id)
	hands.item_id = id
	if id == "":
		hands_icon.texture = null
		hands_fallback.visible = true
		hands_name.text = "Mãos vazias"
		hands_stats.text = "Equipe uma arma pela mochila  [I]"
		return
	hands_fallback.visible = false
	hands_icon.texture = UiStyle.item_icon(id)
	hands_name.text = str(data.get("name", id))
	hands_stats.text = "Dano %d  ·  Alcance %s m  ·  Fôlego %d" % [int(data.get("damage", 0)), UiStyle.fmt(float(data.get("range", 1.5))), int(data.get("cost", 10))]

func _update_prompt() -> void:
	var raw: String = "" if any_panel() or game.ended else game.interaction_text()
	if raw != _last_prompt:
		_last_prompt = raw
		if raw == "":
			prompt_box.hide()
		else:
			var key: String = "E"
			var text: String = raw
			if raw.begins_with("E "):
				text = raw.substr(1).strip_edges()
			var parts: PackedStringArray = text.split("  ·  ")
			var action: String = parts[0].strip_edges().to_lower()
			action = action.substr(0, 1).to_upper() + action.substr(1)
			prompt_key.text = key
			prompt_text.text = action + ("  ·  " + "  ·  ".join(parts.slice(1)) if parts.size() > 1 else "")
			prompt_box.show()
	paused_badge.visible = inventory.is_open and not game.ended

func _update_toast() -> void:
	var active: bool = game.message_time > 0 and game.message_text != "" and not game.ended
	toast.visible = active
	if not active:
		return
	if toast_label.text != game.message_text:
		toast_label.text = game.message_text
	toast.modulate.a = clampf(game.message_time / 0.6, 0.0, 1.0)
	toast_row.position.y = 900 - 172 if (prompt_box.visible or paused_badge.visible) else 900 - 128

# --- panels --------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if game == null or game.ended:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_H:
			toggle_health()
			get_viewport().set_input_as_handled()
			return
		if not any_panel() and event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
			if event.physical_keycode == KEY_1:
				toggle_inventory()
			else:
				quick_use("ration" if event.physical_keycode == KEY_2 else "bandage")
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map"):
		toggle_map()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("escape"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func any_panel() -> bool:
	return modal.visible or (inventory != null and inventory.is_open)

func hide_panels() -> void:
	for p in [map_panel, pause_panel, ending_panel]:
		p.hide()
	if inventory.is_open:
		inventory.set_open(false)
	modal.hide()

func close_all() -> void:
	if game.ended:
		return
	hide_panels()
	get_tree().paused = false
	pause_confirm = false
	update_hud()

func open_inventory(container: Dictionary = {}) -> void:
	if game.ended:
		return
	hide_panels()
	inventory.open(container)
	get_tree().paused = true
	update_hud()

func toggle_inventory() -> void:
	if game.ended:
		return
	if inventory.is_open:
		close_all()
	else:
		open_inventory(game.nearest_container())

func toggle_health() -> void:
	if game.ended:
		return
	health_panel.visible = not health_panel.visible
	if health_panel.visible:
		health_panel.refresh()
		health_panel.reset_size()
		health_panel.move_to(health_panel.position)
	update_hud()

func toggle_map() -> void:
	if game.ended:
		return
	if map_panel.visible:
		close_all()
		return
	hide_panels()
	modal.show()
	dim.show()
	map_panel.show()
	full_map.queue_redraw()
	get_tree().paused = true
	update_hud()

func toggle_pause() -> void:
	if any_panel():
		close_all()
		return
	hide_panels()
	pause_confirm = false
	pause_title.text = "Um momento de respiro"
	pause_note.text = ""
	controls_box.modulate.a = 1.0
	modal.show()
	dim.show()
	pause_panel.show()
	get_tree().paused = true
	update_hud()

func confirm_restart() -> void:
	if pause_confirm:
		game.restart()
		return
	pause_confirm = true
	pause_title.text = "Recomeçar a expedição?"
	pause_note.text = "Isso apaga o progresso salvo desta expedição. Clique de novo em “Nova expedição” para confirmar; “Continuar” mantém o progresso."
	controls_box.modulate.a = 0.35

func quick_use(id: String) -> void:
	if game.ended or (any_panel() and not inventory.is_open):
		return
	game.use_item(id)
	refresh_inventory()
	update_hud()

func refresh_inventory() -> void:
	if inventory:
		inventory.refresh()

# Inventory actions kept on the root for the game code and tests.
func select_item(id: String) -> void:
	inventory.select_item(id)

func select_loot(id: String) -> void:
	inventory.select_loot(id)

func use_selected() -> void:
	inventory.use_selected()

func drop_selected() -> void:
	inventory.drop_selected()

func take_selected() -> void:
	inventory.take_selected()

func take_all() -> void:
	inventory.take_all()

func damage_flash() -> void:
	flash.color.a = 0.25
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.4)

func show_ending(success: bool) -> void:
	hide_panels()
	health_panel.hide()
	modal.show()
	dim.show()
	ending_panel.show()
	ending_panel.set_title("Incursão concluída" if success else "Fim da expedição")
	end_title.text = "Você voltou com o selo" if success else "A expedição terminou"
	end_title.add_theme_color_override("font_color", UiStyle.ACCENT if success else Color("e08a72"))
	end_note.text = "Você recuperou o selo e atravessou as cisternas." if success else "Os corredores cobram cada descuido."
	for child in end_stats.get_children():
		child.queue_free()
	var coins: int = game.inventory.count("coin")
	for entry in [["Monstros derrotados", str(game.kills)], ["Golpes recebidos", str(game.hits_received)], ["Carga trazida", "%s kg" % UiStyle.fmt(game.inventory.weight())], ["Moedas na mochila", str(coins)]]:
		end_stats.add_child(UiStyle.label(entry[0], 14, UiStyle.DIM))
		end_stats.add_child(UiStyle.label(entry[1], 14, UiStyle.TEXT, "semibold"))
	get_tree().paused = true

class HandsCard extends PanelContainer:
	var ui
	var item_id: String = ""
	func _make_custom_tooltip(_for_text: String) -> Object:
		if item_id == "":
			return UiStyle.tip("Mãos vazias", "Equipe uma arma pela mochila  [I].")
		return UiItemTooltip.build(item_id, 1, true)
