extends RefCounted
class_name UiStyle
## Shared palette, fonts, theme and small builders for the HUD.
## Layout and reading follow Project Zomboid (dark translucent windows,
## thin borders, compact tables, status icons); the art is original.

const PANEL := Color(0.030, 0.030, 0.028, 0.86)
const PANEL_SOLID := Color(0.055, 0.055, 0.050, 0.97)
const TITLE := Color(0.125, 0.122, 0.112, 0.97)
const TITLE_HOVER := Color(0.165, 0.160, 0.145, 0.98)
const BORDER := Color(0.36, 0.35, 0.32, 0.95)
const BORDER_SOFT := Color(0.23, 0.225, 0.21, 0.95)
const TEXT := Color("ebe8df")
const MUTED := Color("a8a59a")
const DIM := Color("75736b")
const ACCENT := Color("dcc083")
const ACCENT_DARK := Color("8a7446")
const GOOD := Color("7cb663")
const WARN := Color("d9ab45")
const BAD := Color("d25c3f")
const BLOOD := Color("b8322a")
const ROW_ALT := Color(1, 1, 1, 0.035)
const ROW_HOVER := Color(1, 1, 1, 0.08)
const ROW_SELECTED := Color(0.86, 0.72, 0.40, 0.20)
const SHADOW := Color(0, 0, 0, 0.85)

## Category id -> [label, color, sort order]
const CATEGORIES := {
	"ARMA": ["Arma", Color("dc9f80"), 0],
	"MUNICAO": ["Munição", Color("d2b48a"), 1],
	"TRATAMENTO": ["Tratamento", Color("8cc6b6"), 2],
	"ALIMENTO": ["Alimento", Color("bfca7c"), 3],
	"MATERIAL": ["Material", Color("aaa6c2"), 4],
	"TESOURO": ["Tesouro", Color("e0c46c"), 5],
	"OBJETIVO": ["Objetivo", Color("e39bd6"), 6],
}

static var _fonts: Dictionary = {}
static var _icons: Dictionary = {}

static func font(weight: String = "regular") -> Font:
	if not _fonts.has(weight):
		var file: String = {"regular": "Inter-Regular", "medium": "Inter-Medium", "semibold": "Inter-SemiBold", "bold": "Inter-Bold"}.get(weight, "Inter-Regular")
		var base: FontFile = load("res://assets/fontes/%s.otf" % file)
		_fonts[weight] = base
	return _fonts[weight]

## Small caps style used for window titles and section labels.
static func caps_font() -> Font:
	if not _fonts.has("caps"):
		var variation := FontVariation.new()
		variation.base_font = font("semibold")
		variation.spacing_glyph = 1
		_fonts["caps"] = variation
	return _fonts["caps"]

static func category(tag: String) -> Array:
	return CATEGORIES.get(tag, [tag.capitalize(), MUTED, 9])

## Rendered icon for an item or container id (assets/ui/icones/<id>.png).
static func item_icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var path := "res://assets/ui/icones/%s.png" % id
		_icons[id] = load(path) if ResourceLoader.exists(path) else null
	return _icons[id]

static func value_color(ratio: float) -> Color:
	if ratio >= 0.6:
		return GOOD
	if ratio >= 0.3:
		return WARN
	return BAD

static func box(bg: Color, border: Color = BORDER, width: int = 1, margin: Vector4 = Vector4(8, 4, 8, 4)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = margin.x
	style.content_margin_top = margin.y
	style.content_margin_right = margin.z
	style.content_margin_bottom = margin.w
	style.anti_aliasing = false
	return style

static func empty_box() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

static func label(text: String, size: int = 14, color: Color = TEXT, weight: String = "regular") -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", font(weight))
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func caps(text: String, size: int = 12, color: Color = MUTED) -> Label:
	var node := label(text.to_upper(), size, color)
	node.add_theme_font_override("font", caps_font())
	return node

static func shadowed(node: Label) -> Label:
	node.add_theme_color_override("font_shadow_color", SHADOW)
	node.add_theme_constant_override("shadow_offset_x", 1)
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.add_theme_constant_override("shadow_outline_size", 2)
	return node

static func button(text: String, callback: Callable, min_width: float = 0.0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(min_width, 28)
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(callback)
	return node

## Flat icon-only button (title bar close, collapse arrows).
static func flat_button(text: String, callback: Callable, size: int = 16) -> Button:
	var node := button(text, callback)
	node.custom_minimum_size = Vector2(24, 22)
	node.add_theme_font_size_override("font_size", size)
	for state in ["normal", "disabled", "focus"]:
		node.add_theme_stylebox_override(state, empty_box())
	node.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 0, Vector4(4, 0, 4, 0)))
	node.add_theme_stylebox_override("pressed", box(Color(1, 1, 1, 0.14), Color(0, 0, 0, 0), 0, Vector4(4, 0, 4, 0)))
	node.add_theme_color_override("font_color", MUTED)
	node.add_theme_color_override("font_hover_color", TEXT)
	return node

## Keyboard key drawn as a small cap, used in prompts and the controls table.
static func keycap(key: String, size: int = 12) -> PanelContainer:
	var cap := PanelContainer.new()
	var style := box(Color(0.16, 0.155, 0.14, 0.96), Color(0.55, 0.53, 0.48), 1, Vector4(6, 1, 6, 2))
	style.border_width_bottom = 2
	style.set_corner_radius_all(3)
	cap.add_theme_stylebox_override("panel", style)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := label(key, size, TEXT, "semibold")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(text)
	cap.custom_minimum_size.x = 22
	return cap

## Thin bar (status cells, weight, health rows).
static func bar(min_size: Vector2, fill: Color) -> ProgressBar:
	var meter := ProgressBar.new()
	meter.show_percentage = false
	meter.custom_minimum_size = min_size
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.max_value = 100
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.13, 0.13, 0.12, 0.95)
	back.border_color = Color(0, 0, 0, 0.6)
	back.set_border_width_all(1)
	var front := StyleBoxFlat.new()
	front.bg_color = fill
	meter.add_theme_stylebox_override("background", back)
	meter.add_theme_stylebox_override("fill", front)
	return meter

static func set_bar_color(meter: ProgressBar, color: Color) -> void:
	var fill: StyleBoxFlat = meter.get_theme_stylebox("fill")
	if fill.bg_color != color:
		fill = fill.duplicate()
		fill.bg_color = color
		meter.add_theme_stylebox_override("fill", fill)

## Two-level tooltip body: bold title and muted explanation.
static func tip(title: String, text: String = "", accent: Color = TEXT) -> Control:
	var box_node := VBoxContainer.new()
	box_node.add_theme_constant_override("separation", 3)
	box_node.add_child(label(title, 14, accent, "semibold"))
	if text != "":
		var body := label(text, 13, MUTED)
		box_node.add_child(body)
	return box_node

static func fmt(value: float, decimals: int = 1) -> String:
	# Portuguese decimal comma.
	return (("%." + str(decimals) + "f") % value).replace(".", ",")

static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font("regular")
	t.default_font_size = 14
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.44, 0.41))
	t.set_font("font", "Button", font("medium"))
	t.set_font_size("font_size", "Button", 13)
	t.set_stylebox("normal", "Button", box(Color(0.12, 0.118, 0.108, 0.96), BORDER_SOFT, 1, Vector4(12, 3, 12, 4)))
	t.set_stylebox("hover", "Button", box(Color(0.19, 0.182, 0.16, 0.98), ACCENT_DARK, 1, Vector4(12, 3, 12, 4)))
	t.set_stylebox("pressed", "Button", box(Color(0.24, 0.215, 0.16, 0.98), ACCENT, 1, Vector4(12, 3, 12, 4)))
	t.set_stylebox("disabled", "Button", box(Color(0.075, 0.074, 0.07, 0.9), Color(0.17, 0.168, 0.16), 1, Vector4(12, 3, 12, 4)))
	t.set_stylebox("focus", "Button", empty_box())
	# Tooltips
	var tip := box(PANEL_SOLID, BORDER, 1, Vector4(10, 7, 10, 8))
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", 13)
	t.set_font("font", "TooltipLabel", font("regular"))
	# Context menus
	t.set_stylebox("panel", "PopupMenu", box(PANEL_SOLID, BORDER, 1, Vector4(4, 4, 4, 4)))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.86, 0.72, 0.40, 0.22), Color(0, 0, 0, 0), 0, Vector4(4, 2, 4, 2)))
	var separator := StyleBoxLine.new()
	separator.color = BORDER_SOFT
	separator.thickness = 1
	t.set_stylebox("separator", "PopupMenu", separator)
	t.set_stylebox("labeled_separator_left", "PopupMenu", separator)
	t.set_stylebox("labeled_separator_right", "PopupMenu", separator)
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_color("font_disabled_color", "PopupMenu", DIM)
	t.set_color("font_separator_color", "PopupMenu", MUTED)
	t.set_font("font", "PopupMenu", font("regular"))
	t.set_font("font_separator", "PopupMenu", caps_font())
	t.set_font_size("font_size", "PopupMenu", 13)
	t.set_font_size("font_separator_size", "PopupMenu", 11)
	t.set_constant("v_separation", "PopupMenu", 7)
	t.set_constant("item_start_padding", "PopupMenu", 10)
	t.set_constant("item_end_padding", "PopupMenu", 14)
	# Scrollbars: thin, dark
	var track := box(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, Vector4(0, 0, 0, 0))
	var grab := box(Color(0.42, 0.41, 0.38, 0.85), Color(0, 0, 0, 0), 0, Vector4(0, 0, 0, 0))
	var grab_hi := box(Color(0.62, 0.58, 0.48, 0.95), Color(0, 0, 0, 0), 0, Vector4(0, 0, 0, 0))
	for kind in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", kind, track)
		t.set_stylebox("grabber", kind, grab)
		t.set_stylebox("grabber_highlight", kind, grab_hi)
		t.set_stylebox("grabber_pressed", kind, grab_hi)
	var line := StyleBoxLine.new()
	line.color = BORDER_SOFT
	line.thickness = 1
	t.set_stylebox("separator", "HSeparator", line)
	var vline := StyleBoxLine.new()
	vline.color = BORDER_SOFT
	vline.thickness = 1
	vline.vertical = true
	t.set_stylebox("separator", "VSeparator", vline)
	return t
