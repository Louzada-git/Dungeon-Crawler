extends HBoxContainer
class_name UiHotbar
## Quick slots at the bottom of the screen: equipped weapon, ration, bandage,
## then the technique bar (keys 4-7) with its recharge.

var game
var ui
var slots: Array = []
var _last: Dictionary = {}

func _init(game_ref, ui_ref) -> void:
	game = game_ref
	ui = ui_ref
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot("1", func(): ui.toggle_inventory())
	_slot("2", func(): ui.quick_use("ration"))
	_slot("3", func(): ui.quick_use("bandage"))
	var gap := Control.new()
	gap.custom_minimum_size.x = 8
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gap)
	for i in Techniques.bar_size():
		_technique_slot(i)

## Technique slots: [button, icon, recharge shade, state] per bar position.
var tech_slots: Array = []

func _technique_slot(index: int) -> void:
	var b := SlotButton.new()
	b.provider = technique_tooltip.bind(index)
	b.custom_minimum_size = Vector2(52, 60)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func():
		if game.techniques.at_slot(index) == "":
			ui.toggle_techniques()
		else:
			game.player.use_technique(index)
	)
	b.add_theme_stylebox_override("normal", UiStyle.box(Color(0.04, 0.04, 0.037, 0.86), UiStyle.BORDER_SOFT, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("hover", UiStyle.box(Color(0.13, 0.125, 0.11, 0.94), UiStyle.ACCENT_DARK, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("pressed", UiStyle.box(Color(0.2, 0.18, 0.13, 0.96), UiStyle.ACCENT, 1, Vector4(0, 0, 0, 0)))
	var icon := UiIcon.new("golpe", UiStyle.ACCENT)
	b.add_child(icon)
	icon.position = Vector2(10, 14)
	icon.size = Vector2(32, 32)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(shade)
	shade.position = Vector2(1, 1)
	shade.size = Vector2(50, 0)
	var key_label := UiStyle.shadowed(UiStyle.label(str(index + 4), 11, UiStyle.ACCENT, "bold"))
	b.add_child(key_label)
	key_label.position = Vector2(5, 2)
	var time := UiStyle.shadowed(UiStyle.label("", 12, UiStyle.TEXT, "bold"))
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(time)
	time.position = Vector2(0, 40)
	time.size = Vector2(52, 16)
	add_child(b)
	tech_slots.append({"button": b, "icon": icon, "shade": shade, "time": time})

func refresh_techniques() -> void:
	var book: TechniqueBook = game.techniques
	var weapon: String = game.inventory.equipped
	for i in tech_slots.size():
		var slot: Dictionary = tech_slots[i]
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
		slot["shade"].size.y = 58.0 * ratio
		slot["time"].text = UiStyle.fmt(book.remaining(form_id), 1 if book.remaining(form_id) < 10 else 0) if ratio > 0.0 else ""

func technique_tooltip(index: int) -> Control:
	var book: TechniqueBook = game.techniques
	var form_id: String = book.at_slot(index)
	if form_id == "":
		return UiStyle.tip("Espaço de habilidade vazio", "T abre as habilidades; lá você põe uma na barra.\nClique para abrir.")
	var weapon: String = game.inventory.equipped
	var problem: String = Techniques.problem(game.sheet, book, form_id, weapon)
	var objs: Array = book.objects(form_id)
	var tip := UiStyle.tip(Techniques.form_name(form_id), ("Objetos: " + ", ".join(objs.map(func(o): return Techniques.object_name(o)))) if not objs.is_empty() else "Sem objetos", UiStyle.ACCENT)
	if problem != "":
		tip.add_child(UiStyle.label(problem, 12, UiStyle.BAD, "medium"))
	else:
		for row in Techniques.summary(Techniques.stats(game.sheet, form_id, objs, weapon)):
			tip.add_child(UiStyle.label("%s: %s" % [row[0], row[1]], 12, UiStyle.MUTED))
	tip.add_child(UiStyle.label("Tecla [%d] ou clique: usar na direção do cursor" % (index + 4), 12, UiStyle.ACCENT, "medium"))
	return tip

func _slot(key: String, callback: Callable) -> void:
	var b := SlotButton.new()
	b.provider = tooltip_for.bind(slots.size())
	b.custom_minimum_size = Vector2(60, 60)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(callback)
	b.add_theme_stylebox_override("normal", UiStyle.box(Color(0.04, 0.04, 0.037, 0.86), UiStyle.BORDER_SOFT, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("hover", UiStyle.box(Color(0.13, 0.125, 0.11, 0.94), UiStyle.ACCENT_DARK, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("pressed", UiStyle.box(Color(0.2, 0.18, 0.13, 0.96), UiStyle.ACCENT, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("disabled", UiStyle.box(Color(0.03, 0.03, 0.028, 0.8), Color(0.15, 0.15, 0.14), 1, Vector4(0, 0, 0, 0)))
	var tex := TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tex)
	tex.position = Vector2(8, 7)
	tex.size = Vector2(44, 44)
	var fallback := UiIcon.new("hand", Color("a8a59a"))
	b.add_child(fallback)
	fallback.position = Vector2(14, 12)
	fallback.size = Vector2(32, 32)
	fallback.visible = false
	var key_label := UiStyle.shadowed(UiStyle.label(key, 11, UiStyle.ACCENT, "bold"))
	b.add_child(key_label)
	key_label.position = Vector2(5, 2)
	var count := UiStyle.shadowed(UiStyle.label("", 13, UiStyle.TEXT, "bold"))
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_child(count)
	count.position = Vector2(20, 38)
	count.size = Vector2(36, 18)
	var flash := ColorRect.new()
	flash.color = Color(1, 0.95, 0.8, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(b)
	slots.append({"button": b, "texture": tex, "fallback": fallback, "count": count, "flash": flash, "item": ""})

func refresh() -> void:
	var weapon: String = game.inventory.equipped
	var ammo: String = str(Items.info(weapon).get("ammo", ""))
	_fill(0, weapon, game.inventory.count(ammo) if ammo != "" else -1)
	_fill(1, "ration", game.inventory.count("ration"))
	_fill(2, "bandage", game.inventory.count("bandage"))
	refresh_techniques()

func _fill(index: int, id: String, amount: int) -> void:
	var slot: Dictionary = slots[index]
	var key := "%s|%d" % [id, amount]
	if _last.get(index, "") == key:
		return
	var before: String = _last.get(index, "")
	_last[index] = key
	var b: Button = slot["button"]
	slot["item"] = id
	if id == "":
		slot["texture"].texture = null
		slot["fallback"].visible = true
		slot["count"].text = ""
		b.tooltip_text = "Mãos vazias"
		return
	slot["fallback"].visible = false
	slot["texture"].texture = UiStyle.item_icon(id)
	b.tooltip_text = str(Items.info(id).get("name", id))
	if amount >= 0:
		slot["count"].text = str(amount)
		slot["count"].add_theme_color_override("font_color", UiStyle.TEXT if amount > 0 else UiStyle.BAD)
		slot["texture"].modulate = Color(1, 1, 1, 1.0 if amount > 0 else 0.3)
		# Flash when a unit was spent.
		var parts := before.split("|")
		if parts.size() == 2 and parts[0] == id and int(parts[1]) > amount:
			flash(index)
	else:
		slot["count"].text = ""
		slot["texture"].modulate = Color.WHITE

func flash(index: int) -> void:
	var rect: ColorRect = slots[index]["flash"]
	rect.color.a = 0.45
	var tween := rect.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(rect, "color:a", 0.0, 0.35)

func tooltip_for(index: int) -> Control:
	var id: String = slots[index]["item"]
	if id == "":
		return UiStyle.tip("Mãos vazias", "Golpes sem arma. Equipe uma arma pela mochila  [1].")
	var count: int = game.inventory.count(id)
	var tip := UiItemTooltip.build(id, maxi(count, 1), index == 0)
	var hint: String = ["Clique ou [1]: abrir mochila", "Clique ou [2]: comer", "Clique ou [3]: aplicar"][index]
	tip.add_child(UiStyle.label(hint, 12, UiStyle.ACCENT, "medium"))
	return tip

class SlotButton extends Button:
	var provider: Callable
	func _make_custom_tooltip(_for_text: String) -> Object:
		return provider.call() if provider.is_valid() else null
