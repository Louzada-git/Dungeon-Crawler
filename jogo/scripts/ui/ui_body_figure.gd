extends Control
class_name UiBodyFigure
## Front view of the body split in regions, tinted by overall condition.
## The simulation has no localized wounds yet, so every region shares the
## same tint; bleeding adds animated drops on the torso.

var health: float = 100.0
var bleeding: bool = false
var _time: float = 0.0

func _init() -> void:
	custom_minimum_size = Vector2(124, 262)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if bleeding and is_visible_in_tree():
		_time += delta
		queue_redraw()

func set_state(value: float, is_bleeding: bool) -> void:
	if absf(value - health) < 0.5 and is_bleeding == bleeding:
		return
	health = value
	bleeding = is_bleeding
	queue_redraw()

static func condition_color(value: float) -> Color:
	var stops := [[0.0, Color("6e1b1b")], [0.25, Color("b2402c")], [0.5, Color("cf8a4a")], [0.75, Color("d6c48f")], [1.0, Color("cfccc2")]]
	var r: float = clampf(value / 100.0, 0.0, 1.0)
	for i in range(1, stops.size()):
		if r <= stops[i][0]:
			var t: float = (r - stops[i - 1][0]) / (stops[i][0] - stops[i - 1][0])
			return stops[i - 1][1].lerp(stops[i][1], t)
	return stops[-1][1]

func _map(p: Vector2) -> Vector2:
	# Design space is 100 x 220.
	var f: float = minf(size.x / 100.0, size.y / 220.0)
	return (size - Vector2(100, 220) * f) * 0.5 + p * f

func _part(points: Array, fill: Color) -> void:
	var poly := PackedVector2Array()
	for p in points:
		poly.append(_map(Vector2(p[0], p[1])))
	draw_colored_polygon(poly, fill)
	var closed := poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, Color(0.05, 0.04, 0.035, 0.95), 1.2, true)

func _limb(a: Vector2, b: Vector2, wa: float, wb: float, fill: Color) -> void:
	var dir: Vector2 = (b - a).normalized()
	var n := Vector2(-dir.y, dir.x)
	_part([[a.x + n.x * wa * 0.5, a.y + n.y * wa * 0.5], [b.x + n.x * wb * 0.5, b.y + n.y * wb * 0.5], [b.x - n.x * wb * 0.5, b.y - n.y * wb * 0.5], [a.x - n.x * wa * 0.5, a.y - n.y * wa * 0.5]], fill)

func _ellipse(c: Vector2, rx: float, ry: float, fill: Color) -> void:
	var pts: Array = []
	for i in 28:
		var a: float = TAU * i / 28.0
		pts.append([c.x + cos(a) * rx, c.y + sin(a) * ry])
	_part(pts, fill)

func _draw() -> void:
	var base: Color = condition_color(health)
	var side: Color = base.darkened(0.12)
	# Soft floor shadow
	var f: float = minf(size.x / 100.0, size.y / 220.0)
	draw_circle(_map(Vector2(50, 214)), 1.0, Color(0, 0, 0, 0))
	draw_set_transform(_map(Vector2(50, 214)), 0, Vector2(1.0, 0.18))
	draw_circle(Vector2.ZERO, 34 * f, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# Head and neck
	_ellipse(Vector2(50, 19), 10.5, 13, base)
	_part([[45, 31], [55, 31], [56, 40], [44, 40]], side)
	# Torso (chest + abdomen) and pelvis
	_part([[29, 41], [71, 41], [73, 53], [67, 78], [33, 78], [27, 53]], base)
	_part([[33, 78], [67, 78], [64, 106], [36, 106]], side)
	_part([[36, 106], [64, 106], [67, 121], [55, 128], [45, 128], [33, 121]], base.darkened(0.06))
	# Arms (viewer's left is the body's right side)
	for s in [-1.0, 1.0]:
		var x0: float = 50.0 + s * 19.0
		_limb(Vector2(x0, 45), Vector2(50 + s * 26, 82), 11, 9, side)
		_limb(Vector2(50 + s * 26, 83), Vector2(50 + s * 31, 117), 9, 7, base)
		_ellipse(Vector2(50 + s * 32, 124), 5, 6.5, side)
		# Legs
		_limb(Vector2(50 + s * 8.5, 124), Vector2(50 + s * 9.5, 166), 15, 11, base)
		_limb(Vector2(50 + s * 9.5, 167), Vector2(50 + s * 10, 203), 10, 8, side)
		_part([[50 + s * 6, 203], [50 + s * 14, 203], [50 + s * 17, 211], [50 + s * 5, 211]], base.darkened(0.1))
	if bleeding:
		var pulse: float = 0.55 + 0.45 * sin(_time * 5.0)
		for drop in [[44.0, 62.0, 0.0], [57.0, 70.0, 0.9], [49.0, 88.0, 1.7]]:
			var c: Vector2 = _map(Vector2(drop[0], drop[1] + fmod(_time * 6.0 + drop[2] * 4.0, 8.0)))
			var r: float = 3.2 * f
			var color := Color(0.75, 0.08, 0.06, 0.55 + 0.4 * pulse)
			draw_circle(c, r, color)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.9, -r * 0.3), c + Vector2(r * 0.9, -r * 0.3), c + Vector2(0, -r * 2.4)]), color)
