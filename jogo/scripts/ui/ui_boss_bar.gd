extends VBoxContainer
class_name UiBossBar
## Boss name and health across the top of the screen while it is fighting.

var game
var title: Label
var state: Label
var bar: Control
var _shown_health: float = 1.0
var _target: DungeonEnemy

func _init(game_ref) -> void:
	game = game_ref
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 3)
	custom_minimum_size = Vector2(560, 0)
	position = Vector2(720 - 280, 48)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	title = UiStyle.shadowed(UiStyle.label("", 16, Color("f0d9c8"), "semibold"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	state = UiStyle.shadowed(UiStyle.caps("", 11, Color("ff9a7a")))
	row.add_child(state)
	bar = Control.new()
	bar.custom_minimum_size = Vector2(560, 12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	add_child(bar)
	visible = false

func refresh() -> void:
	var b: DungeonEnemy = game.boss() if game.has_method("boss") else null
	var show: bool = b != null and b.alive and b.aggro and not game.ended
	visible = show
	if not show:
		_target = null
		return
	if _target != b:
		_target = b
		_shown_health = b.health / b.maximum_health
	title.text = "%s  ·  %dº andar" % [b.display_name(), b.level]
	state.text = "Furioso" if b.enraged else ""
	bar.queue_redraw()

func _process(delta: float) -> void:
	if _target and visible:
		_shown_health = move_toward(_shown_health, _target.health / _target.maximum_health, delta * 0.6)
		bar.queue_redraw()

func _draw_bar() -> void:
	if _target == null:
		return
	var r := Rect2(Vector2.ZERO, bar.size)
	bar.draw_rect(r, Color(0.05, 0.03, 0.03, 0.9))
	var real: float = clampf(_target.health / _target.maximum_health, 0, 1)
	# Recent damage trails behind in a lighter color.
	bar.draw_rect(Rect2(1, 1, (r.size.x - 2) * _shown_health, r.size.y - 2), Color(0.95, 0.75, 0.55, 0.7))
	bar.draw_rect(Rect2(1, 1, (r.size.x - 2) * real, r.size.y - 2), Color("b8322a") if not _target.enraged else Color("e0442c"))
	bar.draw_rect(Rect2(r.size.x * 0.5, 0, 1, r.size.y), Color(1, 1, 1, 0.35))
	bar.draw_rect(r, Color(0.75, 0.55, 0.4, 0.9), false, 1.0)
