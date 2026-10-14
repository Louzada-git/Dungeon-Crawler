extends Control
class_name UiInventory
## Backpack and surroundings as two Project Zomboid style windows.
## Collapsed they are compact title bars at the top of the screen; opened they
## show sortable tables, container tabs, actions, a context menu and drag & drop.

const BAG_POS := Vector2(60, 8)
const LOOT_POS := Vector2(570, 8)
const WIDTH := 500.0
const HEIGHT := 396.0

enum Action { USE, UNEQUIP, DROP_ONE, DROP_ALL, STORE_ONE, STORE_ALL, TAKE_ONE, TAKE_STACK, TAKE_EVERYTHING, USE_FROM_LOOT }

var game
var ui
var bag_window: UiWindow
var loot_window: UiWindow
var bag_list: UiItemList
var loot_list: UiItemList
var weight_meter: Control
var weight_label: Label
var loot_info: Label
var title_take_all: Button
var loot_tabs: VBoxContainer
var bag_detail: Label
var loot_detail: Label
var use_button: Button
var drop_button: Button
var store_button: Button
var take_button: Button
var take_stack_button: Button
var take_all_button: Button
var lock_button: Button
var menu: PopupMenu
var menu_source: String = ""
var menu_item: String = ""
var loot: Dictionary = {}
var nearby: Array = []
var is_open: bool = false

func _init(game_ref, ui_ref) -> void:
	game = game_ref
	ui = ui_ref
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	_build_bag()
	_build_loot()
	menu = PopupMenu.new()
	menu.id_pressed.connect(_on_menu)
	add_child(menu)
	set_open(false)

# --- construction ------------------------------------------------------------

func _build_bag() -> void:
	bag_window = UiWindow.new("Mochila", UiIcon.new("bag", UiStyle.TEXT), WIDTH, HEIGHT)
	bag_window.position = BAG_POS
	bag_window.close_requested.connect(func(): ui.close_all())
	bag_window.title_clicked.connect(_on_title_clicked)
	add_child(bag_window)
	weight_meter = Control.new()
	weight_meter.custom_minimum_size = Vector2(96, 8)
	weight_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	weight_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weight_meter.draw.connect(_draw_weight)
	bag_window.extras.add_child(weight_meter)
	weight_label = UiStyle.label("", 13, UiStyle.TEXT, "medium")
	weight_label.custom_minimum_size.x = 84
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bag_window.extras.add_child(weight_label)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_window.body.add_child(body)
	bag_list = UiItemList.new("bag")
	bag_list.empty_text = "A mochila está vazia."
	bag_list.item_selected.connect(func(_id): _refresh_buttons())
	bag_list.item_activated.connect(func(id): _primary_bag(id))
	bag_list.item_context.connect(func(id, at): _open_menu("bag", id, at))
	bag_list.item_dropped.connect(_on_drop_into_bag)
	body.add_child(bag_list)
	var strip := VBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	body.add_child(strip)
	var tab := _tab_button(null, "bag", "Mochila · o que você carrega", Callable())
	_style_tab(tab, true)
	strip.add_child(tab)
	bag_detail = UiStyle.label("", 12, UiStyle.MUTED)
	bag_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bag_detail.custom_minimum_size.y = 34
	bag_detail.max_lines_visible = 2
	bag_window.body.add_child(bag_detail)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	bag_window.body.add_child(actions)
	use_button = UiStyle.button("Usar", use_selected)
	drop_button = UiStyle.button("Deixar no chão", drop_selected)
	store_button = UiStyle.button("Guardar  →", store_selected)
	for b in [use_button, drop_button, store_button]:
		actions.add_child(b)
	var hint := UiStyle.label("Clique duplo usa  ·  botão direito: ações  ·  arraste para guardar", 11, UiStyle.DIM)
	bag_window.body.add_child(hint)
	bag_window.set_drag_forwarding(Callable(), bag_list._can_drop_data, bag_list._drop_data)

func _build_loot() -> void:
	loot_window = UiWindow.new("Arredores", UiIcon.new("chest", UiStyle.TEXT), WIDTH, HEIGHT)
	loot_window.position = LOOT_POS
	loot_window.close_requested.connect(func(): ui.close_all())
	loot_window.title_clicked.connect(_on_title_clicked)
	add_child(loot_window)
	loot_info = UiStyle.label("", 13, UiStyle.MUTED, "medium")
	loot_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	loot_window.extras.add_child(loot_info)
	title_take_all = UiStyle.flat_button("Pegar tudo", func(): take_all(), 12)
	title_take_all.add_theme_color_override("font_color", UiStyle.ACCENT)
	title_take_all.tooltip_text = "Pegar tudo o que couber na mochila"
	loot_window.extras.add_child(title_take_all)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	loot_window.body.add_child(body)
	loot_list = UiItemList.new("loot")
	loot_list.empty_text = "Nada aqui."
	loot_list.item_selected.connect(func(_id): _refresh_buttons())
	loot_list.item_activated.connect(func(id): take(id, int(loot.get("items", {}).get(id, 0))))
	loot_list.item_context.connect(func(id, at): _open_menu("loot", id, at))
	loot_list.item_dropped.connect(_on_drop_into_loot)
	body.add_child(loot_list)
	loot_tabs = VBoxContainer.new()
	loot_tabs.add_theme_constant_override("separation", 4)
	body.add_child(loot_tabs)
	loot_detail = UiStyle.label("", 12, UiStyle.MUTED)
	loot_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_detail.custom_minimum_size.y = 34
	loot_detail.max_lines_visible = 2
	loot_window.body.add_child(loot_detail)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	loot_window.body.add_child(actions)
	take_button = UiStyle.button("Pegar 1", take_selected)
	take_stack_button = UiStyle.button("Pegar a pilha", func(): take(loot_list.selected_id, int(loot.get("items", {}).get(loot_list.selected_id, 0))))
	take_all_button = UiStyle.button("Pegar tudo", take_all)
	lock_button = UiStyle.button("Arrombar", func():
		game.attempt_lockpick(loot)
		_after_change())
	lock_button.visible = false
	for b in [take_button, take_stack_button, take_all_button, lock_button]:
		actions.add_child(b)
	var hint := UiStyle.label("Clique duplo pega a pilha  ·  arraste para a mochila", 11, UiStyle.DIM)
	loot_window.body.add_child(hint)
	loot_window.set_drag_forwarding(Callable(), loot_list._can_drop_data, loot_list._drop_data)

func _tab_button(texture: Texture2D, icon_kind: String, hint: String, callback: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(36, 36)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = hint
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if callback.is_valid():
		b.pressed.connect(callback)
	var picture: Control
	if texture:
		var tex := TextureRect.new()
		tex.texture = texture
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture = tex
	else:
		picture = UiIcon.new(icon_kind, UiStyle.TEXT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = 5
	picture.offset_top = 5
	picture.offset_right = -5
	picture.offset_bottom = -5
	return b

func _style_tab(b: Button, active: bool) -> void:
	var normal := UiStyle.box(Color(0.86, 0.72, 0.40, 0.16) if active else Color(0.10, 0.10, 0.09, 0.9), UiStyle.ACCENT if active else UiStyle.BORDER_SOFT, 1, Vector4(0, 0, 0, 0))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", UiStyle.box(Color(1, 1, 1, 0.08), UiStyle.ACCENT_DARK if not active else UiStyle.ACCENT, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("pressed", normal)

# --- state -------------------------------------------------------------------

func set_open(value: bool) -> void:
	is_open = value
	for w in [bag_window, loot_window]:
		w.set_collapsed(not value)
		w.close_button.visible = value
		w.title_bar.tooltip_text = "" if value else "Abrir mochila  [I]"
	if value:
		refresh()
	else:
		menu.hide()
		title_take_all.visible = false
	update_bars()

func open(container: Dictionary = {}) -> void:
	nearby = game.nearby_containers()
	loot = container
	if loot.is_empty() and not nearby.is_empty():
		loot = nearby[0]
	if not loot.is_empty() and not nearby.has(loot):
		nearby.insert(0, loot)
	bag_list.selected_id = ""
	loot_list.selected_id = ""
	set_open(true)

func _on_title_clicked() -> void:
	if not is_open:
		ui.toggle_inventory()

func refresh() -> void:
	if not is_open:
		update_bars()
		return
	var current: Array = game.nearby_containers()
	for entry in nearby:
		if entry == loot and not current.has(entry):
			current.insert(0, entry)
	nearby = current
	bag_list.set_items(game.inventory.stacks, game.inventory.equipped, game.inventory.armor)
	loot_list.empty_text = "Nada por perto.\nAproxime-se de um baú ou de itens no chão e pressione E." if loot.is_empty() else "Vazio. Arraste itens da mochila para guardar aqui."
	if locked():
		loot_list.empty_text = "Trancado: fechadura %s.\nUse uma gazua para arrombar." % game.LOCK_NAMES[int(loot["lock"])]
	loot_list.set_items(loot.get("items", {}) if not loot.is_empty() and not locked() else {})
	_rebuild_tabs()
	_refresh_buttons()
	update_bars()

## The open container is locked: its contents stay hidden until it is picked.
func locked() -> bool:
	return not loot.is_empty() and int(loot.get("lock", 0)) > 0

func _rebuild_tabs() -> void:
	for child in loot_tabs.get_children():
		loot_tabs.remove_child(child)
		child.queue_free()
	for entry in nearby:
		var chest: bool = entry.get("chest", true)
		var count: int = 0
		for id in entry["items"]:
			count += int(entry["items"][id])
		var hint: String = "%s\n%d %s" % [entry["name"], count, "item" if count == 1 else "itens"]
		if int(entry.get("lock", 0)) > 0:
			hint = "%s\ntrancado" % entry["name"]
		var b := _tab_button(UiStyle.item_icon("container_chest" if chest else "container_sack"), "", hint, _switch_to.bind(entry))
		_style_tab(b, entry == loot)
		loot_tabs.add_child(b)

func _switch_to(entry: Dictionary) -> void:
	loot = entry
	loot_list.selected_id = ""
	refresh()

func update_bars() -> void:
	var weight: float = game.inventory.weight()
	weight_label.text = "%s / %s kg" % [UiStyle.fmt(weight), UiStyle.fmt(game.inventory.capacity, 0)]
	weight_label.add_theme_color_override("font_color", UiStyle.TEXT if weight <= game.inventory.comfort else UiStyle.WARN)
	weight_meter.queue_redraw()
	var target: Dictionary = loot if is_open else game.nearest_container()
	if target.is_empty():
		loot_window.set_title("Arredores")
		loot_info.text = "nada por perto" if not is_open else ""
		loot_info.add_theme_color_override("font_color", UiStyle.DIM)
	else:
		loot_window.set_title("Arredores  ·  " + str(target["name"]))
		var count: int = 0
		var w: float = 0.0
		for id in target["items"]:
			count += int(target["items"][id])
			w += float(Items.info(id).get("weight", 0.0)) * int(target["items"][id])
		# Open, the totals move to the footer to leave room for the title.
		loot_info.text = "" if is_open else (("%d %s  ·  %s kg" % [count, "item" if count == 1 else "itens", UiStyle.fmt(w)]) if count > 0 else "vazio")
		if int(target.get("lock", 0)) > 0 and not is_open:
			loot_info.text = "trancado"
		loot_info.add_theme_color_override("font_color", UiStyle.ACCENT)
	loot_window.title_bar.tooltip_text = "" if is_open else ("Vasculhar  [E]" if not target.is_empty() else "Abrir mochila  [I]")

func _draw_weight() -> void:
	var r := Rect2(Vector2.ZERO, weight_meter.size)
	weight_meter.draw_rect(r, Color(0.13, 0.13, 0.12, 0.95))
	var weight: float = game.inventory.weight()
	var ratio: float = clampf(weight / game.inventory.capacity, 0.0, 1.0)
	var color: Color = UiStyle.GOOD if weight <= game.inventory.comfort else (UiStyle.WARN if weight <= lerpf(game.inventory.comfort, game.inventory.capacity, 0.57) else UiStyle.BAD)
	weight_meter.draw_rect(Rect2(0, 0, r.size.x * ratio, r.size.y), color)
	var comfort_x: float = r.size.x * game.inventory.comfort / game.inventory.capacity
	weight_meter.draw_rect(Rect2(comfort_x, -2, 1, r.size.y + 4), Color(1, 1, 1, 0.65))
	weight_meter.draw_rect(r, Color(0, 0, 0, 0.7), false, 1.0)

func _refresh_buttons() -> void:
	var id: String = bag_list.selected_id
	var data: Dictionary = Items.info(id)
	var has_target: bool = not loot.is_empty()
	if id == "":
		bag_detail.text = "Selecione um item. Passe o mouse para ver detalhes."
		use_button.text = "Usar"
		use_button.disabled = true
		drop_button.disabled = true
		store_button.disabled = true
	else:
		var cat: Array = UiStyle.category(str(data.get("tag", "")))
		bag_detail.text = "%s  ·  %s kg/un.  ·  %s" % [cat[0], UiStyle.fmt(float(data.get("weight", 0.0)), 2), data.get("description", "")]
		use_button.text = _use_label(id)
		use_button.disabled = not _usable(id)
		drop_button.disabled = false
		store_button.disabled = not has_target or locked()
	store_button.tooltip_text = ("Guardar em: " + str(loot["name"])) if has_target else "Abra um recipiente próximo para guardar"
	var lid: String = loot_list.selected_id
	var items: Dictionary = loot.get("items", {}) if has_target and not locked() else {}
	lock_button.visible = locked()
	if locked():
		var d: int = int(loot["lock"])
		lock_button.text = "Arrombar  ·  %d%%" % roundi(game.sheet.pick_chance(d) * 100)
		lock_button.disabled = game.inventory.count("gazua") <= 0
		lock_button.tooltip_text = "Gazuas na mochila: %d. Uma tentativa que falha pode quebrar a gazua." % game.inventory.count("gazua")
	take_button.disabled = lid == "" or not items.has(lid)
	take_stack_button.disabled = take_button.disabled
	take_all_button.disabled = items.is_empty()
	title_take_all.visible = is_open and not items.is_empty()
	if not has_target:
		loot_detail.text = "Recipientes a até 2,4 m aparecem nas abas à direita."
	elif locked():
		loot_detail.text = "Fechadura %s  ·  chance de abrir: %d%%  ·  gazuas: %d" % [game.LOCK_NAMES[int(loot["lock"])], roundi(game.sheet.pick_chance(int(loot["lock"])) * 100), game.inventory.count("gazua")]
	elif lid != "" and items.has(lid):
		var ld: Dictionary = Items.info(lid)
		loot_detail.text = "%s  ·  %d × %s kg  ·  %s" % [UiStyle.category(str(ld.get("tag", "")))[0], int(items[lid]), UiStyle.fmt(float(ld.get("weight", 0.0)), 2), ld.get("description", "")]
	else:
		var count: int = 0
		var w: float = 0.0
		for key in items:
			count += int(items[key])
			w += float(Items.info(key).get("weight", 0.0)) * int(items[key])
		loot_detail.text = "Aqui: %d %s, %s kg  ·  livre na mochila: %s kg" % [count, "item" if count == 1 else "itens", UiStyle.fmt(w), UiStyle.fmt(game.inventory.capacity - game.inventory.weight())]

func _use_label(id: String) -> String:
	if Items.info(id).has("damage"):
		return "Guardar arma" if game.inventory.equipped == id else "Equipar"
	if Items.info(id).has("protection"):
		return "Tirar" if game.inventory.armor == id else "Vestir"
	return {"ration": "Comer", "bandage": "Aplicar bandagem"}.get(id, "Usar")

func _usable(id: String) -> bool:
	var data: Dictionary = Items.info(id)
	return data.has("damage") or data.has("protection") or data.has("heal") or data.has("food")

# --- actions -----------------------------------------------------------------

func select_item(id: String) -> void:
	bag_list.select(id)

func select_loot(id: String) -> void:
	loot_list.select(id)

func use_selected() -> void:
	_primary_bag(bag_list.selected_id)

func _primary_bag(id: String) -> void:
	if id == "":
		return
	if Items.info(id).has("damage") and game.inventory.equipped == id:
		game.inventory.unequip()
		game.message("Arma guardada na mochila.")
	else:
		game.use_item(id)
	_after_change()

func drop_selected() -> void:
	if bag_list.selected_id != "":
		game.drop_item(bag_list.selected_id, 1)
		_after_change()

func store_selected() -> void:
	if bag_list.selected_id != "" and not loot.is_empty():
		store(bag_list.selected_id, 1)

func store(id: String, amount: int) -> void:
	if locked():
		game.message("Trancado. Arrombe antes de guardar algo aqui.", 2)
		return
	if loot.is_empty():
		game.drop_item(id, amount)
	else:
		game.store_item(id, amount, loot)
	_after_change()

func take_selected() -> void:
	take(loot_list.selected_id, 1)

func take(id: String, amount: int) -> void:
	if loot.is_empty() or locked() or id == "" or amount <= 0:
		return
	if game.inventory.transfer_from(loot["items"], id, amount) == 0:
		game.message("A mochila está cheia. Deixe algo para trás.")
	else:
		game.sound.play_at("loot", game.player.global_position, 0.35)
	_after_change()

func take_all() -> void:
	if loot.is_empty() or locked():
		return
	for id in loot["items"].keys():
		game.inventory.transfer_from(loot["items"], id, int(loot["items"][id]))
	game.message("Itens recolhidos." if loot["items"].is_empty() else "A mochila atingiu o limite. Parte dos itens ficou no recipiente.")
	game.sound.play_at("loot", game.player.global_position, 0.45)
	_after_change()

func _after_change() -> void:
	refresh()
	ui.update_hud()

func _on_drop_into_bag(data: Dictionary) -> void:
	if data.get("source") == "loot":
		take(str(data["id"]), int(loot.get("items", {}).get(data["id"], 0)))

func _on_drop_into_loot(data: Dictionary) -> void:
	if data.get("source") == "bag":
		store(str(data["id"]), game.inventory.count(str(data["id"])))

# --- context menu --------------------------------------------------------------

func _open_menu(source: String, id: String, at: Vector2) -> void:
	menu_source = source
	menu_item = id
	menu.clear()
	var data: Dictionary = Items.info(id)
	menu.add_separator(str(data.get("name", id)))
	if source == "bag":
		var n: int = game.inventory.count(id)
		if _usable(id):
			if data.has("damage") and game.inventory.equipped == id:
				menu.add_item("Guardar arma na mochila", Action.UNEQUIP)
			else:
				menu.add_item(_use_label(id), Action.USE)
		menu.add_separator()
		menu.add_item("Deixar 1 no chão", Action.DROP_ONE)
		if n > 1:
			menu.add_item("Deixar todos no chão (%d)" % n, Action.DROP_ALL)
		if not loot.is_empty():
			menu.add_separator()
			menu.add_item("Guardar 1 em %s" % loot["name"], Action.STORE_ONE)
			if n > 1:
				menu.add_item("Guardar todos (%d)" % n, Action.STORE_ALL)
	else:
		var n: int = int(loot.get("items", {}).get(id, 0))
		menu.add_item("Pegar 1", Action.TAKE_ONE)
		if n > 1:
			menu.add_item("Pegar a pilha (%d)" % n, Action.TAKE_STACK)
		if id in ["ration", "bandage"]:
			menu.add_item(_use_label(id) + " daqui", Action.USE_FROM_LOOT)
		menu.add_separator()
		menu.add_item("Pegar tudo do recipiente", Action.TAKE_EVERYTHING)
	menu.reset_size()
	var view: Vector2 = get_viewport_rect().size
	var pos: Vector2 = at + Vector2(4, 4)
	pos.x = minf(pos.x, view.x - menu.size.x - 4)
	pos.y = minf(pos.y, view.y - menu.size.y - 4)
	# Embedded popups live in the same design space as the HUD canvas.
	menu.position = Vector2i(pos)
	menu.popup()

func _on_menu(action: int) -> void:
	var id: String = menu_item
	match action:
		Action.USE:
			_primary_bag(id)
		Action.UNEQUIP:
			_primary_bag(id)
		Action.DROP_ONE:
			game.drop_item(id, 1)
			_after_change()
		Action.DROP_ALL:
			game.drop_item(id, game.inventory.count(id))
			_after_change()
		Action.STORE_ONE:
			store(id, 1)
		Action.STORE_ALL:
			store(id, game.inventory.count(id))
		Action.TAKE_ONE:
			take(id, 1)
		Action.TAKE_STACK:
			take(id, int(loot.get("items", {}).get(id, 0)))
		Action.TAKE_EVERYTHING:
			take_all()
		Action.USE_FROM_LOOT:
			# Take one and use it immediately, as long as it fits.
			if take_one_and_use(id):
				_after_change()

func take_one_and_use(id: String) -> bool:
	## Takes one unit and uses it at once; if it is not needed now it stays in the backpack.
	if loot.is_empty() or int(loot["items"].get(id, 0)) <= 0:
		return false
	if game.inventory.transfer_from(loot["items"], id, 1) == 0:
		game.message("A mochila está cheia. Deixe algo para trás.")
		return false
	game.use_item(id)
	return true
