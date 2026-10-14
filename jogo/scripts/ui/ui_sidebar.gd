extends VBoxContainer
class_name UiSidebar
## Left column of tool buttons, like Project Zomboid's side bar.

var buttons: Dictionary = {}
var markers: Dictionary = {}

func _init() -> void:
	add_theme_constant_override("separation", 4)
	position = Vector2(8, 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func add_tool(id: String, icon_kind: String, hint: String, key: String, callback: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(44, 44)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = "%s  [%s]" % [hint, key]
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(callback)
	b.add_theme_stylebox_override("normal", UiStyle.box(Color(0.045, 0.045, 0.042, 0.86), UiStyle.BORDER_SOFT, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("hover", UiStyle.box(Color(0.14, 0.135, 0.12, 0.94), UiStyle.ACCENT_DARK, 1, Vector4(0, 0, 0, 0)))
	b.add_theme_stylebox_override("pressed", UiStyle.box(Color(0.2, 0.18, 0.13, 0.96), UiStyle.ACCENT, 1, Vector4(0, 0, 0, 0)))
	var icon := UiIcon.new(icon_kind, Color("dcd8cc"))
	b.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 9
	icon.offset_top = 7
	icon.offset_right = -9
	icon.offset_bottom = -11
	var key_label := UiStyle.label(key, 9, UiStyle.DIM, "semibold")
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_child(key_label)
	key_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	key_label.offset_right = -3
	key_label.offset_top = 31
	var marker := ColorRect.new()
	marker.color = UiStyle.ACCENT
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.visible = false
	b.add_child(marker)
	marker.position = Vector2(0, 0)
	marker.size = Vector2(3, 44)
	add_child(b)
	buttons[id] = b
	markers[id] = marker
	return b

func add_gap(height: float = 8.0) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gap)

func set_active(id: String, active: bool) -> void:
	if markers.has(id) and markers[id].visible != active:
		markers[id].visible = active
		var icon: UiIcon = buttons[id].get_child(0)
		icon.set_kind(icon.kind, UiStyle.ACCENT if active else Color("dcd8cc"))
