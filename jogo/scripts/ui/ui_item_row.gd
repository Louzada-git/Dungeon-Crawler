extends Control
class_name UiItemRow
## One inventory line: icon, name, category, quantity, weight.
## Click selects, double click uses, right click opens actions, drag moves the stack.

const HEIGHT := 30.0

var list  # UiItemList
var item_id: String = ""
var count: int = 0
var index: int = 0
var selected: bool = false
var equipped: bool = false
var hovered: bool = false

func _init(owner_list, id: String, amount: int, row_index: int) -> void:
	list = owner_list
	item_id = id
	count = amount
	index = row_index
	custom_minimum_size = Vector2(0, HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = id  # non-empty so the custom tooltip appears
	mouse_entered.connect(func(): hovered = true; queue_redraw())
	mouse_exited.connect(func(): hovered = false; queue_redraw())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			list.select(item_id)
			if event.double_click:
				list.item_activated.emit(item_id)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			list.select(item_id)
			list.item_context.emit(item_id, get_global_transform() * event.position)
			accept_event()

func _get_drag_data(_at: Vector2) -> Variant:
	list.select(item_id)
	var preview := HBoxContainer.new()
	preview.add_theme_constant_override("separation", 6)
	var tex := TextureRect.new()
	tex.texture = UiStyle.item_icon(item_id)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(34, 34)
	preview.add_child(tex)
	var text := UiStyle.shadowed(UiStyle.label("%s ×%d" % [Items.info(item_id).get("name", item_id), count], 13, UiStyle.TEXT, "medium"))
	preview.add_child(text)
	preview.modulate = Color(1, 1, 1, 0.9)
	set_drag_preview(preview)
	return {"type": "item", "source": list.source_id, "id": item_id, "count": count}

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	return list._can_drop_data(at, data)

func _drop_data(at: Vector2, data: Variant) -> void:
	list._drop_data(at, data)

func _make_custom_tooltip(_for_text: String) -> Object:
	return UiItemTooltip.build(item_id, count, equipped)

func _draw() -> void:
	var data: Dictionary = Items.info(item_id)
	var w: float = size.x
	var bg := Color(0, 0, 0, 0)
	if index % 2 == 1:
		bg = UiStyle.ROW_ALT
	if hovered:
		bg = UiStyle.ROW_HOVER
	if selected:
		bg = UiStyle.ROW_SELECTED
	if bg.a > 0:
		draw_rect(Rect2(Vector2.ZERO, size), bg)
	if selected:
		draw_rect(Rect2(0, 0, 2, size.y), UiStyle.ACCENT)
	var icon: Texture2D = UiStyle.item_icon(item_id)
	if icon:
		draw_texture_rect(icon, Rect2(6, 2, 26, 26), false)
	var regular: Font = UiStyle.font("regular")
	var medium: Font = UiStyle.font("medium")
	var cols: Array = list.columns(w)
	var baseline: float = size.y * 0.5 + 5
	var name_x: float = 38
	var name_width: float = cols[0] - name_x - 6
	var name_color: Color = UiStyle.TEXT if (selected or hovered) else Color("dcd9cf")
	var tag_width: float = 0.0
	if equipped:
		tag_width = medium.get_string_size("EM MÃOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 10
	var shown := fit(regular, str(data.get("name", item_id)), 14, name_width - tag_width)
	draw_string(regular, Vector2(name_x, baseline), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, name_color)
	if equipped:
		var tx: float = name_x + regular.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 7
		draw_rect(Rect2(tx, size.y * 0.5 - 7, tag_width - 4, 14), Color(0.86, 0.72, 0.40, 0.22))
		draw_string(medium, Vector2(tx + 3, size.y * 0.5 + 4), "EM MÃOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiStyle.ACCENT)
	var cat: Array = UiStyle.category(str(data.get("tag", "")))
	draw_string(regular, Vector2(cols[0], baseline), fit(regular, cat[0], 13, cols[1] - cols[0] - 4), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, cat[1])
	draw_string(medium, Vector2(cols[1], baseline), str(count), HORIZONTAL_ALIGNMENT_RIGHT, cols[2] - cols[1] - 8, 13, UiStyle.TEXT)
	var weight: float = float(data.get("weight", 0.0)) * count
	draw_string(regular, Vector2(cols[2], baseline), UiStyle.fmt(weight, 2), HORIZONTAL_ALIGNMENT_RIGHT, w - cols[2] - 8, 13, UiStyle.MUTED)

static func fit(f: Font, text: String, font_size: int, width: float) -> String:
	if f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return text
	var cut: String = text
	while cut.length() > 1 and f.get_string_size(cut + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		cut = cut.substr(0, cut.length() - 1)
	return cut.strip_edges() + "…"
