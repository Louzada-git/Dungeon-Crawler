extends HBoxContainer
class_name UiHotbar
## Bottom of the screen: the quick bar (keys 1 to 9, any item, game.quick_bar)
## and then the habilidade bar (keys chosen by the player, with recharge).
## Items go in by dragging from the backpack, from the backpack's menu, or by
## selecting one in the backpack and pressing its number; right click empties.

const ITEM_SIZE := Vector2(52, 60)
const TECH_SIZE := Vector2(50, 60)

var game
var ui
var slots: Array = []
var _last: Dictionary = {}

func _init(game_ref, ui_ref) -> void:
	game = game_ref
	ui = ui_ref
	add_theme_constant_override("separation", 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in QuickBar.SIZE:
		_slot(i)
	var gap := Control.new()
	gap.custom_minimum_size.x = 12
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gap)
	for i in Techniques.bar_size():
		_technique_slot(i)

## Total width, for centering the bar.
func bar_width() -> float:
	return ITEM_SIZE.x * QuickBar.SIZE + TECH_SIZE.x * Techniques.bar_size() + 4.0 * (QuickBar.SIZE + Techniques.bar_size() - 1) + 12.0 + 4.0

static func _style(b: Button) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", UiStyle.box(Color(0.04, 0.04, 0.037, 0.86), UiStyle.BORDER_SOFT, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("hover", UiStyle.box(Color(0.13, 0.125, 0.11, 0.94), UiStyle.ACCENT_DARK, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("pressed", UiStyle.box(Color(0.2, 0.18, 0.13, 0.96), UiStyle.ACCENT, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("disabled", UiStyle.box(Color(0.03, 0.03, 0.028, 0.8), Color(0.15, 0.15, 0.14), 1, Vector4(0, 0, 0, 0)))

# --- quick bar ---------------------------------------------------------------------

func _slot(index: int) -> void:
	var b := SlotButton.new()
	b.provider = tooltip_for.bind(index)
	b.index = index
	b.hotbar = self
	b.custom_minimum_size = ITEM_SIZE
	b.tooltip_text = "item"  # non-empty so the custom tooltip appears
	_style(b)
	b.pressed.connect(func(): ui.press_quick(index))
	var tex := TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tex)
	tex.position = Vector2(6, 9)
	tex.size = Vector2(40, 40)
	var key_label := UiStyle.shadowed(UiStyle.label(str(index + 1), 11, UiStyle.ACCENT, "bold"))
	b.add_child(key_label)
	key_label.position = Vector2(5, 2)
	var count := UiStyle.shadowed(UiStyle.label("", 13, UiStyle.TEXT, "bold"))
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_child(count)
	count.position = Vector2(12, 38)
	count.size = Vector2(36, 18)
	# Thin bar along the bottom: the weapon in hand or the armor being worn.
	var active := ColorRect.new()
	active.color = UiStyle.ACCENT
	active.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(active)
	active.position = Vector2(4, ITEM_SIZE.y - 4)
	active.size = Vector2(ITEM_SIZE.x - 8, 2)
	active.visible = false
	var flash := ColorRect.new()
	flash.color = Color(1, 0.95, 0.8, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(b)
	slots.append({"button": b, "texture": tex, "count": count, "active": active, "flash": flash, "item": ""})

func refresh() -> void:
	for i in slots.size():
		_fill(i, game.quick_bar.at(i))
	refresh_techniques()

## How many to show on a slot: the ammunition of a ranged weapon, the stack of
## anything else that stacks, nothing for a weapon or armor (-1).
func amount_for(id: String) -> int:
	var data: Dictionary = Items.info(id)
	var ammo: String = game.ammo_for(data)
	if ammo != "":
		return game.inventory.count(ammo)
	if data.has("damage") or data.has("protection"):
		return -1
	return game.inventory.count(id)

func _fill(index: int, id: String) -> void:
	var slot: Dictionary = slots[index]
	var have: int = game.inventory.count(id) if id != "" else 0
	var amount: int = amount_for(id) if id != "" else -1
	var active: bool = id != "" and (game.inventory.equipped == id or game.inventory.armor == id)
	var key := "%s|%d|%d|%s" % [id, have, amount, active]
	if _last.get(index, "") == key:
		return
	var before: String = _last.get(index, "")
	_last[index] = key
	slot["item"] = id
	slot["active"].visible = active
	if id == "":
		slot["texture"].texture = null
		slot["count"].text = ""
		return
	slot["texture"].texture = UiStyle.item_icon(id)
	slot["texture"].modulate = Color(1, 1, 1, 1.0 if have > 0 and amount != 0 else 0.3)
	if amount >= 0:
		slot["count"].text = str(amount)
		slot["count"].add_theme_color_override("font_color", UiStyle.TEXT if amount > 0 else UiStyle.BAD)
		# Flash when a unit was spent.
		var parts := before.split("|")
		if parts.size() == 4 and parts[0] == id and int(parts[2]) > amount:
			flash(index)
	else:
		slot["count"].text = "" if have > 0 else "0"
		slot["count"].add_theme_color_override("font_color", UiStyle.BAD)

func flash(index: int) -> void:
	var rect: ColorRect = slots[index]["flash"]
	rect.color.a = 0.45
	var tween := rect.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(rect, "color:a", 0.0, 0.35)

func tooltip_for(index: int) -> Control:
	var id: String = game.quick_bar.at(index)
	if id == "":
		return UiStyle.tip("Espaço %d vazio" % (index + 1), "Arraste um item da mochila para cá,\nou selecione o item na mochila e aperte %d.\nQualquer item: armas, armaduras, comida, curativos." % (index + 1))
	var count: int = game.inventory.count(id)
	var tip := UiItemTooltip.build(id, maxi(count, 1), game.inventory.equipped == id)
	var action: String = QuickBar.action_name(game, id)
	var hint: String = ("Clique ou [%d]: %s" % [index + 1, action.to_lower()]) if action != "" else "Fica na barra para ver quantos restam"
	if count <= 0:
		hint = "Nenhum na mochila agora"
	tip.add_child(UiStyle.label(hint, 12, UiStyle.ACCENT, "medium"))
	tip.add_child(UiStyle.label("Botão direito: tirar da barra", 12, UiStyle.DIM))
	return tip

# --- habilidade bar ----------------------------------------------------------------

## Technique slots: [button, icon, recharge shade, key, time] per bar position.
var tech_slots: Array = []

func _technique_slot(index: int) -> void:
	var b := SlotButton.new()
	b.provider = technique_tooltip.bind(index)
	b.custom_minimum_size = TECH_SIZE
	b.tooltip_text = "habilidade"
	_style(b)
	b.pressed.connect(func():
		if game.techniques.at_slot(index) == "":
			ui.toggle_techniques()
		else:
			game.player.use_technique(index)
	)
	var icon := UiIcon.new("golpe", UiStyle.ACCENT)
	b.add_child(icon)
	icon.position = Vector2(9, 16)
	icon.size = Vector2(32, 32)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(shade)
	shade.position = Vector2(1, 1)
	shade.size = Vector2(TECH_SIZE.x - 2, 0)
	var key_label := UiStyle.shadowed(UiStyle.label("", 11, UiStyle.ACCENT, "bold"))
	b.add_child(key_label)
	key_label.position = Vector2(5, 2)
	var time := UiStyle.shadowed(UiStyle.label("", 12, UiStyle.TEXT, "bold"))
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(time)
	time.position = Vector2(0, 40)
	time.size = Vector2(TECH_SIZE.x, 16)
	add_child(b)
	tech_slots.append({"button": b, "icon": icon, "shade": shade, "key": key_label, "time": time})

func refresh_techniques() -> void:
	var book: TechniqueBook = game.techniques
	var weapon: String = game.inventory.equipped
	for i in tech_slots.size():
		var slot: Dictionary = tech_slots[i]
		slot["key"].text = game.technique_key_name(i)
		var form_id: String = book.at_slot(i)
		var icon: UiIcon = slot["icon"]
		if form_id == "":
			icon.set_kind("dot", Color(1, 1, 1, 0.12))
			slot["shade"].size.y = 0
			slot["time"].text = ""
			continue
		var ok: bool = Techniques.problem(game.sheet, book, form_id, weapon) == ""
		var kind: String = str(Techniques.FORMS.get(form_id, {}).get("icone", "golpe"))
		icon.set_kind(kind, UiStyle.ACCENT if ok else UiStyle.BAD.darkened(0.2))
		var ratio: float = book.recharge_ratio(form_id)
		slot["shade"].size.y = (TECH_SIZE.y - 2.0) * ratio
		slot["time"].text = UiStyle.fmt(book.remaining(form_id), 1 if book.remaining(form_id) < 10 else 0) if ratio > 0.0 else ""

func technique_tooltip(index: int) -> Control:
	var book: TechniqueBook = game.techniques
	var form_id: String = book.at_slot(index)
	var key: String = game.technique_key_name(index)
	if form_id == "":
		return UiStyle.tip("Espaço de habilidade vazio  [%s]" % key, "T abre as habilidades; lá você põe uma na barra\ne escolhe a tecla de cada espaço.\nClique para abrir.")
	var weapon: String = game.inventory.equipped
	var problem: String = Techniques.problem(game.sheet, book, form_id, weapon)
	var objs: Array = book.objects(form_id)
	var tip := UiStyle.tip(Techniques.form_name(form_id), ("Objetos: " + ", ".join(objs.map(func(o): return Techniques.object_name(o)))) if not objs.is_empty() else "Sem objetos", UiStyle.ACCENT)
	if problem != "":
		tip.add_child(UiStyle.label(problem, 12, UiStyle.BAD, "medium"))
	else:
		for row in Techniques.summary(Techniques.stats(game.sheet, form_id, objs, weapon)):
			tip.add_child(UiStyle.label("%s: %s" % [row[0], row[1]], 12, UiStyle.MUTED))
	tip.add_child(UiStyle.label("Tecla [%s] ou clique: usar na direção do cursor" % key, 12, UiStyle.ACCENT, "medium"))
	return tip

class SlotButton extends Button:
	var provider: Callable
	## Quick bar position (-1 on the habilidade bar).
	var index: int = -1
	var hotbar
	func _make_custom_tooltip(_for_text: String) -> Object:
		return provider.call() if provider.is_valid() else null
	func _gui_input(event: InputEvent) -> void:
		if index >= 0 and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			hotbar.game.quick_bar.remove(index)
			accept_event()
	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return index >= 0 and data is Dictionary and data.get("type", "") == "item" and Items.DATA.has(str(data.get("id", "")))
	func _drop_data(_at: Vector2, data: Variant) -> void:
		hotbar.game.quick_bar.assign(index, str(data["id"]))
		hotbar.game.message("%s no espaço %d da barra." % [Items.info(str(data["id"])).get("name", data["id"]), index + 1], 2)
