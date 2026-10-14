extends VBoxContainer
class_name UiItemList
## Sortable item table used by the backpack and by nearby containers.

signal item_selected(id: String)
signal item_activated(id: String)
signal item_context(id: String, at: Vector2)
signal item_dropped(data: Dictionary)

var source_id: String = ""
var sort_key: String = "category"
var sort_ascending: bool = true
var selected_id: String = ""
var equipped_id: String = ""
var empty_text: String = "Vazio."
var header: Control
var scroll: ScrollContainer
var rows: VBoxContainer
var empty_label: Label
var _items: Dictionary = {}

const SORT_COLUMNS := [["name", "Item"], ["category", "Categoria"], ["count", "Qtd."], ["weight", "Peso"]]

func _init(id: String) -> void:
	source_id = id
	add_theme_constant_override("separation", 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header = Control.new()
	header.custom_minimum_size.y = 24
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.draw.connect(_draw_header)
	header.gui_input.connect(_header_input)
	header.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	header.resized.connect(header.queue_redraw)
	add_child(header)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(scroll)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(rows)
	empty_label = UiStyle.label("", 13, UiStyle.DIM)
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.custom_minimum_size = Vector2(200, 80)
	empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rows.add_child(empty_label)
	# Empty space and the header accept drops too, not only the rows.
	scroll.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)
	header.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)

## Column x positions for a given width: [category, quantity, weight].
func columns(w: float) -> Array:
	return [w - 192.0, w - 106.0, w - 62.0]

var worn_id: String = ""

func set_items(items: Dictionary, equipped: String = "", worn: String = "") -> void:
	_items = items.duplicate()
	equipped_id = equipped
	worn_id = worn
	if not _items.has(selected_id):
		selected_id = ""
	rebuild()

func ordered_ids() -> Array:
	var ids: Array = _items.keys()
	ids.sort_custom(_compare)
	return ids

func _compare(a: String, b: String) -> bool:
	var da: Dictionary = Items.info(a)
	var db: Dictionary = Items.info(b)
	var va: Variant
	var vb: Variant
	match sort_key:
		"name":
			va = str(da.get("name", a)).to_lower()
			vb = str(db.get("name", b)).to_lower()
		"count":
			va = int(_items[a])
			vb = int(_items[b])
		"weight":
			va = float(da.get("weight", 0.0)) * int(_items[a])
			vb = float(db.get("weight", 0.0)) * int(_items[b])
		_:
			va = UiStyle.category(str(da.get("tag", "")))[2] * 1000 + (0 if a == equipped_id else 1)
			vb = UiStyle.category(str(db.get("tag", "")))[2] * 1000 + (0 if b == equipped_id else 1)
	if va == vb:
		return str(da.get("name", a)) < str(db.get("name", b))
	return va < vb if sort_ascending else va > vb

func rebuild() -> void:
	for child in rows.get_children():
		if child != empty_label:
			rows.remove_child(child)
			child.queue_free()
	var ids: Array = ordered_ids()
	empty_label.text = empty_text
	empty_label.visible = ids.is_empty()
	var i: int = 0
	for id in ids:
		var row := UiItemRow.new(self, id, int(_items[id]), i)
		row.selected = id == selected_id
		row.equipped = id == equipped_id
		row.tag_text = "EM MÃOS" if id == equipped_id else ("VESTIDA" if id == worn_id else "")
		rows.add_child(row)
		i += 1
	header.queue_redraw()

func select(id: String) -> void:
	if selected_id != id:
		selected_id = id
		for row in rows.get_children():
			if row is UiItemRow:
				row.selected = row.item_id == id
				row.queue_redraw()
	item_selected.emit(id)

func row_for(id: String) -> UiItemRow:
	for row in rows.get_children():
		if row is UiItemRow and row.item_id == id:
			return row
	return null

func _header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cols: Array = columns(header.size.x)
		var x: float = event.position.x
		var key: String = "name"
		if x >= cols[2]:
			key = "weight"
		elif x >= cols[1]:
			key = "count"
		elif x >= cols[0]:
			key = "category"
		if key == sort_key:
			sort_ascending = not sort_ascending
		else:
			sort_key = key
			sort_ascending = key in ["name", "category"]
		rebuild()

func _draw_header() -> void:
	var w: float = header.size.x
	header.draw_rect(Rect2(Vector2.ZERO, header.size), Color(1, 1, 1, 0.045))
	header.draw_rect(Rect2(0, header.size.y - 1, w, 1), UiStyle.BORDER_SOFT)
	var f: Font = UiStyle.caps_font()
	var cols: Array = columns(w)
	var y: float = header.size.y * 0.5 + 4
	var spots := [[38.0, "Item", "name", HORIZONTAL_ALIGNMENT_LEFT, cols[0] - 38.0], [cols[0], "Categoria", "category", HORIZONTAL_ALIGNMENT_LEFT, cols[1] - cols[0]], [cols[1], "Qtd.", "count", HORIZONTAL_ALIGNMENT_RIGHT, cols[2] - cols[1] - 8], [cols[2], "Peso", "weight", HORIZONTAL_ALIGNMENT_RIGHT, w - cols[2] - 8]]
	for spot in spots:
		var active: bool = spot[2] == sort_key
		var text: String = spot[1].to_upper()
		if active:
			text = ("▴ " if sort_ascending else "▾ ") + text if spot[3] == HORIZONTAL_ALIGNMENT_RIGHT else text + (" ▴" if sort_ascending else " ▾")
		header.draw_string(f, Vector2(spot[0], y), text, spot[3], spot[4], 11, UiStyle.ACCENT if active else UiStyle.DIM)

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "item" and data.get("source", "") != source_id

func _drop_data(_at: Vector2, data: Variant) -> void:
	item_dropped.emit(data)
