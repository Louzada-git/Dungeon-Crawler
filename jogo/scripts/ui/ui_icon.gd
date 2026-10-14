extends Control
class_name UiIcon
## Original vector icons drawn on a 32-unit grid, filled with a darker
## outline so they stay readable at 16-32 px on dark panels.

var kind: String = "bag"
var tint: Color = Color("e2ded3")
var outline_color: Color = Color(0, 0, 0, 0.55)

func _init(icon_kind: String = "bag", color: Color = Color("e2ded3"), extent: float = 0.0) -> void:
	kind = icon_kind
	tint = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if extent > 0.0:
		custom_minimum_size = Vector2(extent, extent)

func set_kind(value: String, color: Color = tint) -> void:
	if value == kind and color == tint:
		return
	kind = value
	tint = color
	queue_redraw()

# --- 32-unit grid helpers -------------------------------------------------

func _f() -> float:
	return minf(size.x, size.y) / 32.0

func _o() -> Vector2:
	return (size - Vector2(32, 32) * _f()) * 0.5

func P(x: float, y: float) -> Vector2:
	return _o() + Vector2(x, y) * _f()

func pts(list: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in list:
		out.append(P(p[0], p[1]))
	return out

func fill(list: Array, color: Color, outline: bool = true) -> void:
	var poly := pts(list)
	draw_colored_polygon(poly, color)
	if outline:
		var closed := poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, outline_color, maxf(1.0, _f() * 0.9), true)

func stroke(list: Array, color: Color, width: float = 1.6) -> void:
	draw_polyline(pts(list), color, maxf(1.0, width * _f()), true)

func disc(x: float, y: float, r: float, color: Color, outline: bool = true) -> void:
	draw_circle(P(x, y), r * _f(), color)
	if outline:
		draw_arc(P(x, y), r * _f(), 0, TAU, 32, outline_color, maxf(1.0, _f() * 0.9), true)

func ring(x: float, y: float, r: float, color: Color, width: float = 1.6, a0: float = 0.0, a1: float = TAU) -> void:
	draw_arc(P(x, y), r * _f(), a0, a1, 32, color, maxf(1.0, width * _f()), true)

func ellipse(cx: float, cy: float, rx: float, ry: float, a0: float = 0.0, a1: float = TAU, steps: int = 24) -> Array:
	var out: Array = []
	for i in steps + 1:
		var a: float = lerpf(a0, a1, float(i) / steps)
		out.append([cx + cos(a) * rx, cy + sin(a) * ry])
	return out

func shade(c: Color, amount: float = 0.28) -> Color:
	return c.darkened(amount)

# --- icons -----------------------------------------------------------------

func _draw() -> void:
	var c := tint
	match kind:
		"bag":
			# Backpack with flap, pocket and carry loop.
			ring(16, 8.5, 3.6, shade(c, 0.1), 1.8, PI, TAU)
			fill([[7, 11], [25, 11], [26.5, 28], [5.5, 28]], c)
			fill([[7.5, 11], [24.5, 11], [23, 17], [9, 17]], shade(c, 0.22))
			fill([[11, 20], [21, 20], [21, 26], [11, 26]], shade(c, 0.35))
			disc(16, 17, 1.4, Color("2a2722"), false)
		"heart":
			_heart(c)
		"heart_crack":
			_heart(c)
			stroke([[16, 8], [13.5, 13], [18, 16], [14.5, 21], [16.5, 25]], Color(0.08, 0.04, 0.03, 0.9), 1.8)
		"pulse":
			_heart(c)
			stroke([[5, 15.5], [11, 15.5], [13.5, 11], [16.5, 21], [19, 15.5], [27, 15.5]], Color(0.08, 0.04, 0.03, 0.9), 1.7)
		"cross":
			fill([[12.5, 5], [19.5, 5], [19.5, 12.5], [27, 12.5], [27, 19.5], [19.5, 19.5], [19.5, 27], [12.5, 27], [12.5, 19.5], [5, 19.5], [5, 12.5], [12.5, 12.5]], c)
		"map":
			fill([[4, 8], [11.5, 5], [20.5, 8], [28, 5], [28, 24.5], [20.5, 27.5], [11.5, 24.5], [4, 27.5]], c)
			fill([[11.5, 5], [20.5, 8], [20.5, 27.5], [11.5, 24.5]], shade(c, 0.2), false)
			stroke([[7, 21], [10, 17], [14, 19], [18, 13], [22, 15]], Color(0.55, 0.16, 0.10, 0.95), 1.4)
			stroke([[22.5, 9.5], [25.5, 12.5]], Color(0.55, 0.16, 0.10, 0.95), 1.6)
			stroke([[25.5, 9.5], [22.5, 12.5]], Color(0.55, 0.16, 0.10, 0.95), 1.6)
		"book":
			# Open book with a ribbon: proficiencies.
			fill([[16, 8], [27, 5], [28, 24], [16, 27]], c)
			fill([[16, 8], [5, 5], [4, 24], [16, 27]], shade(c, 0.15))
			stroke([[16, 8], [16, 27]], Color(0.1, 0.09, 0.08, 0.9), 1.4)
			for y in [11.0, 15.0, 19.0]:
				stroke([[19, y], [25, y - 1.2]], shade(c, 0.45), 1.1)
				stroke([[13, y], [7, y - 1.2]], shade(c, 0.5), 1.1)
			fill([[21, 25.5], [24, 24.8], [24, 30], [22.5, 28.5], [21, 30]], Color("b8322a"), false)
		"shield":
			fill([[6, 6], [16, 3], [26, 6], [26, 15], [24, 21], [16, 29], [8, 21], [6, 15]], c)
			fill([[16, 3], [26, 6], [26, 15], [24, 21], [16, 29]], shade(c, 0.2), false)
			stroke([[16, 7], [16, 25]], shade(c, 0.45), 1.4)
		"eye_off":
			var top: Array = ellipse(16, 22, 13, 13, PI * 1.18, PI * 1.82, 14)
			var bottom: Array = ellipse(16, 10, 13, 13, PI * 0.18, PI * 0.82, 14)
			fill(top + bottom, c)
			disc(16, 16, 4.6, Color("26221d"), false)
			stroke([[5, 27], [27, 5]], Color("1d1b17"), 3.2)
			stroke([[5, 27], [27, 5]], c, 1.4)
		"star":
			var points: Array = []
			for i in 10:
				var a: float = -PI / 2 + TAU * i / 10.0
				var r: float = 12.5 if i % 2 == 0 else 5.5
				points.append([16 + cos(a) * r, 17 + sin(a) * r])
			fill(points, c)
		"gear":
			var teeth: Array = []
			for i in 32:
				var a: float = TAU * i / 32.0
				var r: float = 12.0 if (i % 4) < 2 else 9.2
				teeth.append([16 + cos(a) * r, 16 + sin(a) * r])
			fill(teeth, c)
			disc(16, 16, 4.0, Color("1c1b18"), false)
		"lungs":
			stroke([[16, 4], [16, 14]], shade(c, 0.1), 2.2)
			stroke([[16, 13], [12.5, 16.5]], shade(c, 0.1), 1.8)
			stroke([[16, 13], [19.5, 16.5]], shade(c, 0.1), 1.8)
			fill([[14, 11], [10.5, 9], [6.5, 12.5], [4.5, 19.5], [5, 26], [8.5, 28], [12.5, 26], [14.5, 20]], c)
			fill([[18, 11], [21.5, 9], [25.5, 12.5], [27.5, 19.5], [27, 26], [23.5, 28], [19.5, 26], [17.5, 20]], c)
		"bread":
			var dome: Array = ellipse(16, 18, 12, 9.5, PI, TAU, 20)
			dome.append([28, 24])
			dome.append([4, 24])
			fill(dome, c)
			fill([[4, 22], [28, 22], [27, 25.5], [5, 25.5]], shade(c, 0.25))
			for x in [10.0, 15.0, 20.0]:
				stroke([[x, 15], [x + 3.5, 11]], shade(c, 0.45), 1.5)
		"weight":
			ring(16, 9.5, 4.6, shade(c, 0.05), 2.6, PI * 1.05, TAU * 0.975)
			fill(ellipse(16, 20.5, 10, 8.5, 0, TAU, 24), c)
			fill([[9, 26.5], [23, 26.5], [21.5, 29], [10.5, 29]], shade(c, 0.3))
		"drop":
			var drop: Array = ellipse(16, 20, 7.5, 7.5, -0.2, PI + 0.2, 18)
			drop.append([16, 3.5])
			fill(drop, c)
			ring(13, 20.5, 3.2, Color(1, 1, 1, 0.45), 1.3, PI * 0.6, PI * 1.1)
		"tent":
			fill([[3.5, 26.5], [16, 6], [28.5, 26.5]], c)
			fill([[12, 26.5], [16, 15], [20, 26.5]], Color("1d1b17"), false)
			stroke([[2.5, 27], [29.5, 27]], shade(c, 0.2), 1.6)
			stroke([[16, 6], [16, 3]], shade(c, 0.2), 1.4)
		"eye":
			var top: Array = ellipse(16, 22, 13, 13, PI * 1.18, PI * 1.82, 14)
			var bottom: Array = ellipse(16, 10, 13, 13, PI * 0.18, PI * 0.82, 14)
			fill(top + bottom, c)
			disc(16, 16, 4.6, Color("26221d"), false)
			disc(17.3, 14.6, 1.3, Color(1, 1, 1, 0.8), false)
		"flag":
			stroke([[8, 4], [8, 29]], shade(c, 0.1), 2.0)
			fill([[8.5, 5], [26, 8.5], [19.5, 12.5], [26, 17], [8.5, 17]], c)
		"hand":
			fill([[9, 15], [9, 7.5], [11.5, 7.5], [11.5, 14], [12.5, 5.5], [15, 5.5], [15, 14], [16, 5], [18.5, 5], [18.5, 14], [19.5, 7], [22, 7], [22, 18], [24.5, 13], [26.5, 14], [23, 23], [20, 28], [11, 28], [9, 23]], c)
		"sound":
			fill([[5, 12], [10, 12], [16, 6], [16, 26], [10, 20], [5, 20]], c)
			ring(16, 16, 5.5, c, 1.8, -PI * 0.3, PI * 0.3)
			ring(16, 16, 10, c, 1.8, -PI * 0.3, PI * 0.3)
		"sound_off":
			fill([[5, 12], [10, 12], [16, 6], [16, 26], [10, 20], [5, 20]], c)
			stroke([[20, 12], [28, 20]], BAD_COLOR, 2.2)
			stroke([[28, 12], [20, 20]], BAD_COLOR, 2.2)
		"save":
			fill([[6, 5], [23, 5], [27, 9], [27, 27], [6, 27]], c)
			fill([[10, 5], [21, 5], [21, 12], [10, 12]], shade(c, 0.35), false)
			fill([[9, 17], [24, 17], [24, 27], [9, 27]], shade(c, 0.15), false)
		"play":
			fill([[9, 6], [26, 16], [9, 26]], c)
		"door":
			fill([[8, 4], [24, 4], [24, 28], [8, 28]], shade(c, 0.25))
			fill([[8, 4], [20, 7], [20, 30], [8, 28]], c)
			disc(17, 18, 1.3, Color("1d1b17"), false)
		"restart":
			ring(16, 16, 10, c, 2.6, PI * 0.15, PI * 1.85)
			fill([[24.5, 3.5], [27.5, 12.5], [18.5, 11]], c, false)
		"skull":
			fill(ellipse(16, 13.5, 10, 9.5, PI * 0.85, PI * 2.15, 20) + [[22, 22], [22, 27], [10, 27], [10, 22]], c)
			disc(12, 14.5, 2.8, Color("1d1b17"), false)
			disc(20, 14.5, 2.8, Color("1d1b17"), false)
			fill([[16, 18], [17.5, 21], [14.5, 21]], Color("1d1b17"), false)
		"chest":
			fill([[5, 13], [27, 13], [27, 27], [5, 27]], c)
			fill(ellipse(16, 13, 11, 6, PI, TAU, 16), shade(c, 0.12))
			fill([[5, 15], [27, 15], [27, 17], [5, 17]], shade(c, 0.45), false)
			fill([[14, 15], [18, 15], [18, 20], [14, 20]], Color("d8c27a"), false)
		"dot":
			disc(16, 16, 7, c)
		"diamond":
			fill([[16, 5], [27, 16], [16, 27], [5, 16]], c)
		"arrow":
			fill([[16, 3], [27, 27], [16, 21], [5, 27]], c)
		# Technique forms
		"golpe":
			var outer: Array = ellipse(15, 19, 13, 12, PI * 1.05, PI * 1.85, 14)
			var inner: Array = ellipse(17, 21, 8, 7, PI * 1.85, PI * 1.05, 14)
			fill(outer + inner, c)
		"giro":
			var ring_outer: Array = ellipse(16, 16, 12, 12, 0.3, TAU - 0.5, 20)
			var ring_inner: Array = ellipse(16, 16, 7.5, 7.5, TAU - 0.5, 0.3, 20)
			fill(ring_outer + ring_inner, c)
			fill([[27, 8], [29, 17], [21, 13]], c)
		"investida":
			fill([[4, 13], [19, 13], [19, 7], [29, 16], [19, 25], [19, 19], [4, 19]], c)
			stroke([[3, 9], [12, 9]], shade(c, 0.2), 1.6)
			stroke([[3, 23], [12, 23]], shade(c, 0.2), 1.6)
		"pancada":
			var burst: Array = []
			for i in 16:
				var a: float = -PI / 2 + TAU * i / 16.0
				var r: float = 13.0 if i % 2 == 0 else 6.0
				burst.append([16 + cos(a) * r, 16 + sin(a) * r])
			fill(burst, c)
		"disparo":
			stroke([[6, 26], [24, 8]], c, 2.4)
			fill([[27, 5], [26, 13], [19, 6]], c)
			fill([[5, 20], [9, 24], [4, 28], [2, 24]], shade(c, 0.15))
		"soco":
			fill([[8, 11], [22, 11], [26, 15], [26, 22], [22, 26], [10, 26], [7, 22]], c)
			for x in [11, 15, 19]:
				stroke([[x, 11], [x, 16]], shade(c, 0.4), 1.4)
			fill([[5, 14], [9, 13], [10, 20], [6, 21]], shade(c, 0.1))
		_:
			disc(16, 16, 9, c)

const BAD_COLOR := Color("d25c3f")

func _heart(c: Color) -> void:
	# Two lobes meet at the top notch (x = 16) so the outline never crosses itself.
	var notch: float = acos(5.5 / 6.5)
	var left: Array = ellipse(10.5, 12, 6.5, 6.3, PI * 0.75, TAU - notch, 14)
	var right: Array = ellipse(21.5, 12, 6.5, 6.3, PI + notch, PI * 2.25, 14)
	right.pop_front()
	fill(left + right + [[16, 28]], c)
