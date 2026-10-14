extends PanelContainer
class_name UiWindow
## Dark translucent window with a title bar, in the spirit of Project Zomboid:
## drag by the title, optional collapse to the title bar only, close button.

signal close_requested
signal title_clicked

const TITLE_HEIGHT := 28.0

var title_bar: PanelContainer
var title_row: HBoxContainer
var title_icon: Control
var title_label: Label
var extras: HBoxContainer
var body: VBoxContainer
var content_margin: MarginContainer
var close_button: Button
var collapse_button: Button
var draggable: bool = true
var collapsible: bool = false
var collapsed: bool = false
var expanded_height: float = 300.0
var _dragging: bool = false
var _moved: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _init(title: String = "", icon: Control = null, width: float = 400.0, height: float = 300.0, closable: bool = true) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	expanded_height = height
	custom_minimum_size = Vector2(width, height)
	size = custom_minimum_size
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PANEL, UiStyle.BORDER, 1, Vector4(1, 1, 1, 1)))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	title_bar = PanelContainer.new()
	title_bar.custom_minimum_size.y = TITLE_HEIGHT
	title_bar.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.TITLE, Color(0, 0, 0, 0), 0, Vector4(8, 0, 4, 0)))
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	title_bar.gui_input.connect(_on_title_input)
	title_bar.mouse_entered.connect(func(): _paint_title(true))
	title_bar.mouse_exited.connect(func(): _paint_title(false))
	column.add_child(title_bar)
	title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_bar.add_child(title_row)
	if icon:
		title_icon = icon
		icon.custom_minimum_size = Vector2(18, 18)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		title_row.add_child(icon)
	title_label = UiStyle.caps(title, 12, UiStyle.TEXT)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_row.add_child(title_label)
	extras = HBoxContainer.new()
	extras.add_theme_constant_override("separation", 8)
	extras.mouse_filter = Control.MOUSE_FILTER_IGNORE
	extras.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(extras)
	collapse_button = UiStyle.flat_button("▾", toggle_collapse, 13)
	collapse_button.visible = false
	collapse_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(collapse_button)
	close_button = UiStyle.flat_button("×", func(): close_requested.emit(), 18)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.tooltip_text = "Fechar"
	close_button.visible = closable
	title_row.add_child(close_button)
	var rule := ColorRect.new()
	rule.color = UiStyle.BORDER_SOFT
	rule.custom_minimum_size.y = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	content_margin = MarginContainer.new()
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		content_margin.add_theme_constant_override("margin_" + side, 8)
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(content_margin)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_child(body)

func set_title(text: String) -> void:
	title_label.text = text.to_upper()

func set_collapsible(value: bool) -> void:
	collapsible = value
	collapse_button.visible = value

func set_collapsed(value: bool) -> void:
	collapsed = value
	content_margin.visible = not value
	collapse_button.text = "▸" if value else "▾"
	var height: float = TITLE_HEIGHT + 2 if value else expanded_height
	custom_minimum_size.y = height
	size.y = height
	_paint_title(false)

func _paint_title(hover: bool) -> void:
	var base: Color = UiStyle.TITLE if not collapsed else Color(0.07, 0.069, 0.064, 0.9)
	if hover:
		base = UiStyle.TITLE_HOVER
	title_bar.add_theme_stylebox_override("panel", UiStyle.box(base, Color(0, 0, 0, 0), 0, Vector4(8, 0, 4, 0)))

func toggle_collapse() -> void:
	set_collapsed(not collapsed)

func _on_title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click and collapsible:
				toggle_collapse()
				return
			_dragging = draggable
			_moved = false
			_drag_offset = get_global_mouse_position() - global_position
		else:
			if _dragging and not _moved:
				title_clicked.emit()
			_dragging = false
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var target: Vector2 = get_global_mouse_position() - _drag_offset
		if target.distance_to(global_position) > 2.0 or _moved:
			_moved = true
			move_to(target)
		accept_event()

## Keeps at least the title bar on screen.
func move_to(target: Vector2) -> void:
	var view: Vector2 = get_viewport_rect().size
	target.x = clampf(target.x, 0.0, maxf(0.0, view.x - size.x))
	target.y = clampf(target.y, 0.0, maxf(0.0, view.y - TITLE_HEIGHT))
	global_position = target
