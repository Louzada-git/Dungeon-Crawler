extends RefCounted
class_name UiItemTooltip
## Rich tooltip for items: icon, name, category, weight, description and,
## for weapons, the numbers the combat code actually uses.

static func build(id: String, count: int = 1, equipped: bool = false) -> Control:
	var data: Dictionary = Items.info(id)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.custom_minimum_size.x = 280
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)
	var tex := TextureRect.new()
	tex.texture = UiStyle.item_icon(id)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(46, 46)
	head.add_child(tex)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 1)
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(names)
	names.add_child(UiStyle.label(str(data.get("name", id)), 15, UiStyle.TEXT, "semibold"))
	var cat: Array = UiStyle.category(str(data.get("tag", "")))
	var subtitle: String = cat[0] + ("  ·  em mãos" if equipped else "")
	names.add_child(UiStyle.label(subtitle, 12, cat[1], "medium"))
	var rule := ColorRect.new()
	rule.color = UiStyle.BORDER_SOFT
	rule.custom_minimum_size.y = 1
	root.add_child(rule)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 3)
	root.add_child(grid)
	var unit: float = float(data.get("weight", 0.0))
	_row(grid, "Peso", "%s kg" % UiStyle.fmt(unit, 2) + ("   (%s kg no total)" % UiStyle.fmt(unit * count, 2) if count > 1 else ""))
	if count > 1:
		_row(grid, "Quantidade", str(count))
	if data.has("damage"):
		_row(grid, "Dano", "%d" % int(data["damage"]))
		_row(grid, "Alcance", "%s m" % UiStyle.fmt(float(data.get("range", 1.5)), 1))
		_row(grid, "Fôlego por golpe", "%d" % int(data.get("cost", 10)))
		_row(grid, "Preparação", "%s s" % UiStyle.fmt(float(data.get("windup", 0.22)), 2))
		_row(grid, "Recuperação", "%s s" % UiStyle.fmt(float(data.get("cooldown", 0.62)), 2))
		var shape: String = "Corte em arco de %d°" % int(float(data.get("angle", 55.0)) * 2) if data.get("style", "") == "slash" else "Estocada em linha reta"
		_row(grid, "Golpe", shape)
		var targets: int = int(data.get("targets", 1))
		_row(grid, "Alvos", "até %d" % targets if targets > 1 else "primeiro da linha")
	elif id == "ration":
		_row(grid, "Efeito", "+35 saciedade, +12 fôlego")
	elif id == "bandage":
		_row(grid, "Efeito", "Estanca sangramento, +18 vida")
	var desc := UiStyle.label(str(data.get("description", "")), 13, UiStyle.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 280
	root.add_child(desc)
	return root

static func _row(grid: GridContainer, key: String, value: String) -> void:
	grid.add_child(UiStyle.label(key, 13, UiStyle.DIM))
	grid.add_child(UiStyle.label(value, 13, UiStyle.TEXT, "medium"))
