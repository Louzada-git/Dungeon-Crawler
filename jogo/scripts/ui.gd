extends CanvasLayer
## HUD root. Layout and reading follow Project Zomboid: tool bar on the left,
## collapsible inventory windows at the top, condition and status indicators
## on the right, quick slots at the bottom. Pieces live in scripts/ui/.

const HELP_ROWS := [
	[["W", "A", "S", "D"], "Mover (setas também)"],
	[["Shift"], "Correr — gasta fôlego"],
	[["Espaço"], "Esquivar — 12,5 de fôlego"],
	[["Botão dir."], "Mirar e erguer a guarda"],
	[["Mouse"], "Terceira pessoa: virar a câmera  ·  Alt solta o cursor"],
	[["C"], "Andar furtivo (agachado)"],
	[["Botão esq."], "Atacar na direção do cursor"],
	[["E"], "Vasculhar, abrir baú, descansar"],
	[["I", "Tab"], "Mochila (pausa o jogo)"],
	[["M"], "Mapa explorado (pausa o jogo)"],
	[["H"], "Condição física"],
	[["1", "…", "9"], "Barra rápida: qualquer item (arraste da mochila)"],
	[["@habilidades"], "Habilidades da barra  ·  T: montar e trocar teclas"],
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
var boss_bar: UiBossBar
var prof_window: UiProficiencyWindow
var tech_window: UiTechniqueWindow
var creation_panel: UiCreationPanel
var level_banner: UiLevelBanner
var hands_caption: Label
var end_buttons: HBoxContainer
var health_panel: UiHealthWindow
var map_panel: UiWindow
var full_map: DungeonMapView
var mini_map: DungeonMapView
var pause_panel: UiWindow
var pause_title: Label
var pause_note: Label
var controls_box: Control
## Key caps of the habilidade row in the controls list.
var technique_help_keys: HBoxContainer
var sound_button: Button
var psx_button: Button
var camera_button: Button
## Third person: small cross in the middle of the screen, where blows and shots go.
var crosshair: Control
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
	UiItemTooltip.inventory = game.inventory
	UiItemTooltip.sheet = game.sheet
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
	sidebar.add_tool("skills", "book", "Proficiências", "P", toggle_proficiencies)
	sidebar.add_tool("techniques", "golpe", "Habilidades", "T", toggle_techniques)
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
	_build_crosshair()
	hotbar = UiHotbar.new(game, self)
	# Centered, clear of the "em mãos" card on the left (it ends at x 342).
	hotbar.position = Vector2(maxf(352.0, roundf(720.0 - hotbar.bar_width() * 0.5)), 900 - 72)
	hud.add_child(hotbar)
	_build_hands()
	_build_prompts()
	boss_bar = UiBossBar.new(game)
	hud.add_child(boss_bar)
	inventory = UiInventory.new(game, self)
	hud.add_child(inventory)
	inventory_panel = inventory.bag_window
	health_panel = UiHealthWindow.new(game, self)
	health_panel.hide()
	hud.add_child(health_panel)
	prof_window = UiProficiencyWindow.new(game, self)
	prof_window.hide()
	hud.add_child(prof_window)
	tech_window = UiTechniqueWindow.new(game, self)
	tech_window.hide()
	hud.add_child(tech_window)
	level_banner = UiLevelBanner.new()
	hud.add_child(level_banner)
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
	hands_caption = UiStyle.caps("Em mãos", 10, UiStyle.DIM)
	col.add_child(hands_caption)
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
	prompt_box.hide()
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
	creation_panel = UiCreationPanel.new()
	_centered(creation_panel)
	creation_panel.confirmed.connect(_on_creation_confirmed)
	refresh_technique_keys()

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
	for entry in [["arrow", Color("faf0d6"), "Você"], ["tent", Color("79c9a4"), "Abrigo"], ["chest", Color("c99a5b"), "Recipiente com itens"], ["play", Color("9fdc8f"), "Descida (vermelha: selada)"], ["diamond", Color("4f665f"), "Área explorada"]]:
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
	psx_button = UiStyle.button(psx_label(), func():
		game.set_psx(not game.psx.enabled)
		psx_button.text = psx_label()
	)
	psx_button.custom_minimum_size.y = 34
	psx_button.tooltip_text = "Visual de PlayStation: imagem em pixels grandes, cores com pontilhado\ne vértices que tremem. O HUD continua nítido."
	left.add_child(psx_button)
	camera_button = UiStyle.button(camera_label(), func():
		game.set_camera_mode(GameCamera.ISO if game.third_person() else GameCamera.THIRD)
	)
	camera_button.custom_minimum_size.y = 34
	camera_button.tooltip_text = "Isométrica: vista de cima, mira pelo cursor.\nTerceira pessoa: câmera atrás do personagem, o mouse vira a câmera e\nos golpes vão para onde ela olha. Alt solta o cursor; janelas também."
	left.add_child(camera_button)
	var arsenal := UiStyle.button("Arsenal de teste", func(): game.spawn_test_arsenal(); close_all())
	arsenal.custom_minimum_size.y = 34
	arsenal.tooltip_text = "Ferramenta de desenvolvimento: um baú com todas as armas\ne munição aparece ao seu lado. Sai antes do lançamento."
	left.add_child(arsenal)
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
		if entry[0][0] == "@habilidades":
			# The player's own keys, filled by refresh_technique_keys.
			technique_help_keys = keys
		else:
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
	end_buttons = buttons

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
	# The game node stops while paused (inventory, map, pause menu), so the cursor
	# and the HUD are kept current from here, which always runs.
	game.update_cursor()
	if get_tree().paused:
		update_hud()

func update_hud() -> void:
	if game == null or game.player == null or status_panel == null:
		return
	if crosshair:
		crosshair.visible = game.third_person() and not cursor_needed()
	status_panel.refresh()
	moodles.refresh()
	hotbar.refresh()
	inventory.update_bars()
	if health_panel.visible:
		health_panel.refresh()
	sidebar.set_active("inventory", inventory.is_open)
	sidebar.set_active("health", health_panel.visible)
	sidebar.set_active("skills", prof_window.visible)
	if prof_window.visible:
		prof_window.refresh()
	sidebar.set_active("techniques", tech_window.visible)
	if tech_window.visible:
		tech_window.refresh()
	sidebar.set_active("map", map_panel.visible)
	sidebar.set_active("pause", pause_panel.visible)
	_update_hands()
	var area: String = game.layout.room_name(game.player.position)
	if game.generated:
		area = "%dº andar  ·  %s" % [game.floor, area]
	if area_label.text != area:
		area_label.text = area
	objective.text = game.objective_text()
	boss_bar.refresh()
	_update_prompt()
	_update_toast()
	if full_map.is_visible_in_tree():
		full_map.queue_redraw()

func _update_hands() -> void:
	var id: String = game.inventory.equipped
	var ammo_key: String = str(Items.info(id).get("ammo", ""))
	var path: Array = CharacterSheet.path_of(id)
	var mastery: int = game.sheet.mastery(path) if game.sheet.enabled and not path.is_empty() else 0
	hands_caption.text = ("EM MÃOS  ·  DOMÍNIO %d" % mastery) if mastery > 0 else "EM MÃOS"
	var key: String = id + ("|%d" % game.inventory.count(ammo_key) if ammo_key != "" else "") + "|m%d" % mastery
	if key == _last_hands:
		return
	_last_hands = key
	var data: Dictionary = game.sheet.weapon_stats(id)
	hands.item_id = id
	if id == "":
		hands_icon.texture = null
		hands_fallback.visible = true
		hands_name.text = "Mãos vazias"
		hands_stats.text = "Punhos  ·  Dano %d  ·  Fôlego %s" % [roundi(float(data.get("damage", 8))), UiStyle.num(float(data.get("cost", 4)))]
		return
	hands_fallback.visible = false
	hands_icon.texture = UiStyle.item_icon(id)
	hands_name.text = str(data.get("name", id))
	hands_stats.text = "Dano %d  ·  Alcance %s m  ·  Fôlego %s" % [roundi(float(data.get("damage", 0))), UiStyle.fmt(float(data.get("range", 1.5))), UiStyle.num(float(data.get("cost", 10)))]
	var ammo: String = str(data.get("ammo", ""))
	if ammo != "":
		hands_stats.text = "Dano %d  ·  Alcance %s m  ·  %ss: %d" % [roundi(float(data.get("damage", 0))), UiStyle.fmt(float(data.get("range", 1.5)), 0), str(Items.info(ammo).get("name", ammo)), game.inventory.count(ammo)]

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
	if game == null or game.ended or game.choosing_character:
		return
	if typing():
		return
	# Choosing a key for a habilidade slot (T window): the next key press is it.
	if tech_window != null and tech_window.capturing >= 0 and event is InputEventKey and event.pressed and not event.echo:
		tech_window.capture_key(event.physical_keycode)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			toggle_techniques()
			get_viewport().set_input_as_handled()
			return
		var tech_slot: int = game.technique_slot_for_key(event.physical_keycode)
		if not any_panel() and tech_slot >= 0:
			game.player.use_technique(tech_slot)
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_H:
			toggle_health()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_P:
			toggle_proficiencies()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_9:
			var quick: int = event.physical_keycode - KEY_1
			# Backpack open with an item selected: the number puts it in that slot.
			var picked: String = inventory.bag_list.selected_id if inventory.is_open else ""
			if picked == "" and inventory.is_open:
				picked = inventory.loot_list.selected_id
			if picked != "":
				game.quick_bar.assign(quick, picked)
				game.message("%s no espaço %d da barra rápida." % [Items.info(picked).get("name", picked), quick + 1], 2)
				get_viewport().set_input_as_handled()
				return
			if not any_panel():
				press_quick(quick)
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

func camera_label() -> String:
	return "Câmera: terceira pessoa" if game.third_person() else "Câmera: isométrica"

## The camera changed: button text, crosshair, controls list.
func on_camera_mode() -> void:
	if camera_button:
		camera_button.text = camera_label()
	update_hud()

## Third person: the cursor is needed (not captured) while a window, a menu or Alt is up.
func cursor_needed() -> bool:
	if any_panel() or game.choosing_character or game.ended:
		return true
	for w in [tech_window, prof_window, health_panel]:
		if w != null and w.visible:
			return true
	return Input.is_key_pressed(KEY_ALT)

func _build_crosshair() -> void:
	crosshair = Control.new()
	crosshair.name = "Mira"
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.position = Vector2(720, 450)
	crosshair.draw.connect(func():
		var c := Color(0.92, 0.88, 0.76, 0.85)
		var shade := Color(0, 0, 0, 0.6)
		for d in [Vector2(1, 1), Vector2.ZERO]:
			var col: Color = shade if d != Vector2.ZERO else c
			crosshair.draw_rect(Rect2(Vector2(-1, -9) + d, Vector2(2, 6)), col)
			crosshair.draw_rect(Rect2(Vector2(-1, 3) + d, Vector2(2, 6)), col)
			crosshair.draw_rect(Rect2(Vector2(-9, -1) + d, Vector2(6, 2)), col)
			crosshair.draw_rect(Rect2(Vector2(3, -1) + d, Vector2(6, 2)), col)
	)
	hud.add_child(crosshair)
	crosshair.visible = false

func psx_label() -> String:
	return "Filtro PSX: ligado" if game.psx.enabled else "Filtro PSX: desligado"

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

## A text field has the keyboard (technique name): game keys stay quiet.
func typing() -> bool:
	return get_viewport().gui_get_focus_owner() is LineEdit

func toggle_techniques() -> void:
	if game.ended or game.choosing_character:
		return
	tech_window.visible = not tech_window.visible
	if tech_window.visible:
		tech_window.open()
		tech_window.move_to(tech_window.position)
	update_hud()

func toggle_proficiencies() -> void:
	if game.ended or game.choosing_character:
		return
	prof_window.visible = not prof_window.visible
	if prof_window.visible:
		prof_window.refresh()
		prof_window.move_to(prof_window.position)
	update_hud()

## Start of a new run: the attribute points.
func show_creation() -> void:
	hide_panels()
	modal.show()
	dim.show()
	creation_panel.reset()
	creation_panel.show()
	get_tree().paused = true

func _on_creation_confirmed(values: Dictionary) -> void:
	creation_panel.hide()
	modal.hide()
	get_tree().paused = false
	game.start_character(values)
	update_hud()

func on_level_up(branch: String, level: int) -> void:
	level_banner.push("%s  ·  nível %d" % [ProficiencyTree.display_name(branch), level])
	# Habilidades and objetos that this level gives.
	for form_id in Techniques.FORMS:
		var req: Dictionary = Techniques.FORMS[form_id].get("requer", {})
		if int(req.get(branch, -1)) == level:
			level_banner.push("Nova habilidade: %s" % Techniques.form_name(form_id), "T para montar  ·  " + str(Techniques.FORMS[form_id].get("texto", "")))
	for id in Techniques.OBJECTS:
		if Techniques.object_branch(id) == branch and level in Techniques.OBJECTS[id].get("copias", []).map(func(v): return int(v)):
			var n: int = Techniques.copies(game.sheet, id)
			level_banner.push("Objeto: %s" % Techniques.object_name(id), "%s  ·  agora %d %s" % [str(Techniques.OBJECTS[id].get("texto", "")), n, "cópia" if n == 1 else "cópias"])
	if game.sound:
		game.sound.play_at("loot", game.player.global_position, 0.4)

func on_perk_unlocked(branch: String, perk: Dictionary) -> void:
	level_banner.push("Talento: %s" % perk.get("name", ""), "%s  ·  %s" % [ProficiencyTree.display_name(branch), perk.get("text", "")])

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
	map_panel.set_title("Mapa explorado  ·  %dº andar" % game.floor if game.generated else "Mapa explorado  ·  As Cisternas")
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
	pause_note.text = ("Isso descarta este labirinto, a expedição salva e o mapa conhecido. Clique de novo em “Nova expedição” para confirmar; “Continuar” mantém tudo." if game.generated else "Isso apaga o progresso salvo desta expedição. Clique de novo em “Nova expedição” para confirmar; “Continuar” mantém o progresso.")
	controls_box.modulate.a = 0.35

## Presses quick bar slot `index` (key or click): equips, wears, eats, treats.
func press_quick(index: int) -> void:
	if game.ended or game.choosing_character:
		return
	game.quick_bar.use(game, index)
	refresh_inventory()
	update_hud()

## The habilidade keys changed: bar labels, the controls list and the T window.
func refresh_technique_keys() -> void:
	if hotbar:
		hotbar.refresh_techniques()
	if technique_help_keys:
		for child in technique_help_keys.get_children():
			child.queue_free()
		for i in game.technique_keys.size():
			technique_help_keys.add_child(UiStyle.keycap(game.technique_key_name(i), 12))
	if tech_window and tech_window.visible:
		tech_window.refresh(true)

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
	end_title.add_theme_color_override("font_color", UiStyle.ACCENT if success else Color("e08a72"))
	for child in end_buttons.get_children():
		child.queue_free()
	var rows: Array = []
	if game.generated and not success:
		end_title.text = "Você morreu no %dº andar" % game.floor
		end_note.text = "O labirinto continua o mesmo. Você recomeça do zero, mas o mapa que explorou fica com você."
		rows = [["Andar mais fundo", "%dº" % game.deepest], ["Monstros derrotados", str(game.kills)], ["Moedas na mochila", str(game.inventory.count("coin"))], ["Golpes recebidos", str(game.hits_received)]]
		_end_button("Recomeçar no mesmo labirinto", func(): game.restart_same())
		_end_button("Sair", func(): get_tree().quit(), 110)
	else:
		end_title.text = "Você voltou vivo" if success else "A expedição terminou"
		end_note.text = "O guardião caiu e você saiu das cisternas com o que conseguiu carregar." if success else "Os corredores cobram cada descuido."
		rows = [["Monstros derrotados", str(game.kills)], ["Golpes recebidos", str(game.hits_received)], ["Carga trazida", "%s kg" % UiStyle.fmt(game.inventory.weight())], ["Moedas na mochila", str(game.inventory.count("coin"))]]
		_end_button("Nova expedição — reiniciar progresso", func(): game.restart())
		_end_button("Sair", func(): get_tree().quit(), 110)
	for child in end_stats.get_children():
		child.queue_free()
	for entry in rows:
		end_stats.add_child(UiStyle.label(entry[0], 14, UiStyle.DIM))
		end_stats.add_child(UiStyle.label(entry[1], 14, UiStyle.TEXT, "semibold"))
	get_tree().paused = true

func _end_button(text: String, callback: Callable, width: float = 0.0) -> void:
	var b := UiStyle.button(text, callback, width)
	b.custom_minimum_size.y = 36
	end_buttons.add_child(b)

class HandsCard extends PanelContainer:
	var ui
	var item_id: String = ""
	func _make_custom_tooltip(_for_text: String) -> Object:
		if item_id == "":
			return UiStyle.tip("Mãos vazias", "Equipe uma arma pela mochila  [I].")
		return UiItemTooltip.build(item_id, 1, true)
