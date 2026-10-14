extends VBoxContainer
class_name UiLevelBanner
## Short notice at the top of the screen when a proficiency levels up or an
## ability unlocks. Notices queue up and show one at a time.

var queue: Array = []
var card: PanelContainer
var title: Label
var detail: Label
var _time: float = 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	position = Vector2(0, 104)
	size = Vector2(1440, 0)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	card = PanelContainer.new()
	var style := UiStyle.box(Color(0.06, 0.055, 0.045, 0.9), UiStyle.ACCENT_DARK, 1, Vector4(18, 7, 18, 8))
	style.border_width_top = 2
	style.border_color = UiStyle.ACCENT
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(col)
	title = UiStyle.label("", 16, UiStyle.ACCENT, "semibold")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	detail = UiStyle.label("", 13, UiStyle.MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(detail)
	card.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func push(heading: String, text: String = "") -> void:
	# Several levels at once in the same branch collapse into the newest.
	for i in queue.size():
		if queue[i][0].split(" · ")[0] == heading.split(" · ")[0] and text == "" and queue[i][1] == "":
			queue[i] = [heading, text]
			return
	queue.append([heading, text])

func _process(delta: float) -> void:
	if _time > 0:
		_time -= delta
		card.modulate.a = clampf(_time / 0.4, 0.0, 1.0) if _time < 0.4 else minf(1.0, card.modulate.a + delta * 6.0)
		if _time <= 0:
			card.visible = false
		return
	if queue.is_empty():
		return
	var next: Array = queue.pop_front()
	title.text = next[0]
	detail.text = next[1]
	detail.visible = next[1] != ""
	card.modulate.a = 0.0
	card.visible = true
	_time = 2.8 if next[1] == "" else 4.0
