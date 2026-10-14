extends Control
class_name DungeonMapView
## Explored map: only discovered floor is drawn, with wall edges, room names,
## containers, the shelter and the player's position and facing.

var game
var large: bool = false
const FLOOR := Color("33433f")
const FLOOR_NEAR := Color("4f665f")
const EDGE := Color("b9c2b0")
var ORIGIN := Vector2(16, 13)
const MIN_FACTOR := 9.0

func _draw() -> void:
	if game == null or game.player == null:
		return
	# Fit the whole floor; on big floors keep a readable scale centred on the player.
	var grid: Vector2 = Vector2(game.layout.size)
	var span: float = grid.x + grid.y + 2.0
	var factor: float = minf(size.x / span, size.y / (span * 0.5))
	ORIGIN = grid * 0.5
	var center: Vector2 = size * Vector2(0.50, 0.50)
	if factor < MIN_FACTOR:
		factor = MIN_FACTOR
		ORIGIN = Vector2(game.player.position.x / 2.0, game.player.position.z / 2.0)
	var here: Vector2i = game.layout.to_cell(game.player.position)
	var half := Vector2(factor * 0.97, factor * 0.49)
	for cell in game.discovered:
		if not game.layout.is_floor(cell):
			continue
		var p: Vector2 = project(Vector2(cell) - ORIGIN, factor) + center
		var top := p + Vector2(0, -half.y)
		var right := p + Vector2(half.x, 0)
		var bottom := p + Vector2(0, half.y)
		var left := p + Vector2(-half.x, 0)
		var near: float = clampf(1.0 - Vector2(cell).distance_to(Vector2(here)) / 5.0, 0.0, 1.0)
		draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), FLOOR.lerp(FLOOR_NEAR, near))
		var w: float = 1.6 if large else 1.0
		if not game.layout.is_floor(cell + Vector2i(1, 0)):
			draw_line(right, bottom, EDGE, w, true)
		if not game.layout.is_floor(cell + Vector2i(-1, 0)):
			draw_line(top, left, EDGE, w, true)
		if not game.layout.is_floor(cell + Vector2i(0, 1)):
			draw_line(bottom, left, EDGE, w, true)
		if not game.layout.is_floor(cell + Vector2i(0, -1)):
			draw_line(top, right, EDGE, w, true)
	if large:
		_draw_room_names(factor, center)
	for loot in game.containers:
		var cell: Vector2i = game.layout.to_cell(Vector3(loot["pos"][0], 0, loot["pos"][1]))
		if not game.discovered.has(cell):
			continue
		var p: Vector2 = project(Vector2(cell) - ORIGIN, factor) + center
		var chest: bool = loot.get("chest", true)
		var full: bool = not loot["items"].is_empty()
		if not full and not chest:
			continue
		var icon: Texture2D = UiStyle.item_icon("container_chest" if chest else "container_sack")
		var s: float = (22.0 if large else 12.0)
		if icon:
			draw_texture_rect(icon, Rect2(p - Vector2(s, s) * 0.5 - Vector2(0, s * 0.25), Vector2(s, s)), false, Color(1, 1, 1, 1.0 if full else 0.4))
	var t: float = 9.0 if large else 5.0
	if game.has_shelter():
		var camp: Vector2 = project(Vector2(game.layout.to_cell(game.camp_position)) - ORIGIN, factor) + center
		draw_colored_polygon(PackedVector2Array([camp + Vector2(0, -t * 1.3), camp + Vector2(t, t * 0.6), camp + Vector2(-t, t * 0.6)]), Color("79c9a4"))
		draw_colored_polygon(PackedVector2Array([camp + Vector2(0, -t * 0.2), camp + Vector2(t * 0.35, t * 0.6), camp + Vector2(-t * 0.35, t * 0.6)]), Color("1b2a24"))
	for entry in [[game.stairs_up_cell(), Color("8fc3e0"), -1.0], [game.stairs_down_cell(), Color("9fdc8f") if not game.boss_alive() else Color("e07a5a"), 1.0]]:
		var cell = entry[0]
		if cell == null or not game.discovered.has(cell):
			continue
		var p: Vector2 = project(Vector2(cell) - ORIGIN, factor) + center
		var dir: float = entry[2]
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, t * dir), p + Vector2(t, -t * 0.5 * dir), p + Vector2(-t, -t * 0.5 * dir)]), entry[1])
		draw_polyline(PackedVector2Array([p + Vector2(0, t * dir), p + Vector2(t, -t * 0.5 * dir), p + Vector2(-t, -t * 0.5 * dir), p + Vector2(0, t * dir)]), Color(0, 0, 0, 0.8), 1.2, true)
	var player: Vector2 = project(Vector2(game.player.position.x / 2.0, game.player.position.z / 2.0) - ORIGIN, factor) + center
	var facing3: Vector3 = game.player.facing
	var screen_dir: Vector2 = project(Vector2(facing3.x, facing3.z), 1.0).normalized()
	if screen_dir.length() < 0.1:
		screen_dir = Vector2.UP
	var a: float = (11.0 if large else 6.0)
	var side := Vector2(-screen_dir.y, screen_dir.x)
	draw_circle(player, a * 1.15, Color(0.95, 0.88, 0.7, 0.18))
	draw_colored_polygon(PackedVector2Array([player + screen_dir * a, player - screen_dir * a * 0.6 + side * a * 0.7, player - screen_dir * a * 0.25, player - screen_dir * a * 0.6 - side * a * 0.7]), Color("faf0d6"))
	draw_arc(player, a * 1.15, 0, TAU, 32, Color("d2ba86"), 1.2, true)

func _draw_room_names(factor: float, center: Vector2) -> void:
	var f: Font = UiStyle.caps_font()
	for room in game.layout.rooms:
		var rect: Rect2i = room["rect"]
		var seen: bool = false
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				if game.discovered.has(Vector2i(x, y)):
					seen = true
					break
			if seen:
				break
		if not seen:
			continue
		var c: Vector2 = project(Vector2(rect.position) + Vector2(rect.size) * 0.5 - Vector2(0.5, 0.5) - ORIGIN, factor) + center
		var text: String = str(room["name"]).to_upper()
		var w: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(f, c + Vector2(-w * 0.5 + 1, 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.85))
		draw_string(f, c + Vector2(-w * 0.5, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e6dfc9"))

func large_size(value: float) -> float:
	return value * 1.3 if large else value

func project(point: Vector2, factor: float) -> Vector2:
	return Vector2(point.x - point.y, (point.x + point.y) * 0.5) * factor
