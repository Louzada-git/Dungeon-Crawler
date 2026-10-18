extends RefCounted
class_name LabyrinthGenerator
## Builds one floor of the labyrinth from (seed, floor) as a world description,
## the same format as data/mundos/*.json. Same seed and floor -> same floor.
##
## Floors grow roughly exponentially (decision of 13/10/2026): 10, 20, 40, 60,
## 100, 200, 400 rooms, then doubling. Each floor has an entrance (the shelter on
## floor 1, stairs up below it), combat, supply, treasure and lair rooms, and a
## boss chamber at the far end that holds the relic chest and the stairs down.

const ROOMS_PER_FLOOR := [10, 20, 40, 60, 100, 200, 400]
const GAP := 3
const ENEMY_WEIGHTS := [
	{"corrompido": 6, "espreitador": 3},
	{"corrompido": 5, "espreitador": 3, "brutamontes": 2},
	{"corrompido": 4, "espreitador": 3, "brutamontes": 3},
]
const FURNITURE := {
	"abrigo": ["catre", "catre", "mesa", "banco", "caixote", "barril", "saco"],
	"entrada": ["barril", "caixote"],
	"suprimentos": ["mesa", "banco", "caixote", "caixote", "barril", "barril", "saco"],
	"tesouro": ["vaso", "vaso", "saco"],
	"covil": ["rochas", "rochas", "saco", "barril"],
	"combate": ["barril", "caixote", "saco", "vaso", "rochas"],
	"chefe": [],
}
## Models that are longer on X (tables, benches) or on Z (cots).
const LONG_X := ["mesa", "banco"]
const LONG_Z := ["catre"]

static var _loot: Dictionary = {}
static var _names: Dictionary = {}

static func room_target(floor: int) -> int:
	var i: int = floor - 1
	if i < ROOMS_PER_FLOOR.size():
		return ROOMS_PER_FLOOR[i]
	return ROOMS_PER_FLOOR[-1] * int(pow(2, i - ROOMS_PER_FLOOR.size() + 1))

## Monster strength by depth.
static func scaling(floor: int) -> Dictionary:
	return {"health": 1.0 + 0.3 * (floor - 1), "damage": 1.0 + 0.15 * (floor - 1)}

static func _data(path: String) -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}

static func loot_tables() -> Dictionary:
	if _loot.is_empty():
		_loot = _data("res://data/saque.json").get("tabelas", {})
	return _loot

static func room_names() -> Dictionary:
	if _names.is_empty():
		_names = _data("res://data/salas.json")
	return _names

static func floor_seed(seed: int, floor: int) -> int:
	return absi(seed * 1000003 + floor * 7919 + 17)

# --- public -----------------------------------------------------------------------

static func generate(seed: int, floor: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = floor_seed(seed, floor)
	var target: int = room_target(floor)
	var placed: Dictionary = _place_rooms(rng, target)
	var rects: Array = placed["rects"]
	var edges: Array = _connect(rng, rects, floor)
	var corridors: Array = _corridors(rng, rects, edges)
	var floors: Dictionary = {}
	for r in rects:
		_carve(floors, r)
	for c in corridors:
		_carve(floors, c)
	var graph: Array = _graph(rects.size(), edges)
	var depth: Array = _bfs(graph, 0)
	var types: Array = _assign_types(rng, rects, graph, depth, floor)
	var boss_index: int = types.find("chefe")
	var desc := {
		"versao": 1, "id": "labirinto_%d_%d" % [seed, floor], "name": "MUNDO_LABIRINTO_NOME",
		"mode": "labirinto", "seed": seed, "floor": floor, "cell_size": 2.0,
		"size": [placed["size"].x, placed["size"].y],
		"rooms": [], "corridors": [], "blocked": [], "furniture": [], "containers": [], "enemies": [],
	}
	for c in corridors:
		desc["corridors"].append([c.position.x, c.position.y, c.size.x, c.size.y])
	var used_names: Dictionary = {}
	var occupied: Dictionary = {}
	var entrance: Rect2i = rects[0]
	# Entrance points: shelter on floor 1, stairs up on deeper floors.
	var exit_cell := Vector2i(entrance.position.x + 1, entrance.position.y + 2)
	var camp_cell := Vector2i(entrance.position.x + 2, entrance.position.y + 2)
	var spawn_cell := Vector2i(entrance.position.x + 2, entrance.position.y + 3)
	desc["spawn"] = [spawn_cell.x, spawn_cell.y]
	desc["camp"] = [camp_cell.x, camp_cell.y]
	desc["camp_exit"] = [exit_cell.x, exit_cell.y]
	desc["has_shelter"] = floor == 1
	desc["stairs_up"] = [exit_cell.x, exit_cell.y] if floor > 1 else null
	for cell in [exit_cell, camp_cell, spawn_cell, spawn_cell + Vector2i(0, 1), camp_cell + Vector2i(1, 0)]:
		occupied[cell] = true
	for i in rects.size():
		var r: Rect2i = rects[i]
		var kind: String = types[i]
		var room := {"id": "sala_%d" % i, "name": _room_name(rng, kind, used_names, floor), "rect": [r.position.x, r.position.y, r.size.x, r.size.y], "type": kind, "safe": kind == "abrigo", "depth": depth[i]}
		desc["rooms"].append(room)
		_fill_room(rng, desc, i, r, kind, floors, occupied, floor)
	var boss_rect: Rect2i = rects[boss_index]
	var down: Vector2i = _free_edge(rng, boss_rect, floors, occupied, true)
	occupied[down] = true
	desc["stairs_down"] = [down.x, down.y]
	_ensure_reachable(desc, floors)
	return desc

## Problems with a description, empty when it is sound. Used by the tests.
static func validate(desc: Dictionary) -> Array:
	var problems: Array = []
	var layout := DungeonLayout.new(desc)
	var solid: Dictionary = {}
	for f in desc["furniture"]:
		solid[DungeonLayout.cell(f["cell"])] = true
	var reach: Dictionary = _flood(layout.floors, solid, layout.spawn)
	var bosses: int = 0
	var objectives: int = 0
	var ids: Dictionary = {}
	for room in desc["rooms"]:
		var r: Rect2i = DungeonLayout.rect(room["rect"])
		var any: bool = false
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				if reach.has(Vector2i(x, y)):
					any = true
		if not any:
			problems.append("sala inalcançável: " + room["id"])
	for c in desc["containers"]:
		var cell := DungeonLayout.cell(c["cell"])
		if not reach.has(cell):
			problems.append("recipiente inalcançável: " + c["id"])
		if ids.has(c["id"]):
			problems.append("id repetido: " + c["id"])
		ids[c["id"]] = true
		if c.get("objective", false):
			objectives += 1
		for item in c["items"]:
			if not Items.DATA.has(item):
				problems.append("item desconhecido: " + item)
	for e in desc["enemies"]:
		var cell := DungeonLayout.cell(e["cell"])
		if not reach.has(cell):
			problems.append("monstro inalcançável: " + e["id"])
		if not EnemyTypes.DATA.has(e["type"]):
			problems.append("tipo desconhecido: " + e["type"])
		if ids.has(e["id"]):
			problems.append("id repetido: " + e["id"])
		ids[e["id"]] = true
		if EnemyTypes.info(e["type"]).get("boss", false):
			bosses += 1
		if layout.is_safe(layout.to_world(cell)):
			problems.append("monstro na sala segura: " + e["id"])
		var entrance: Rect2i = DungeonLayout.rect(desc["rooms"][0]["rect"])
		if entrance.has_point(cell):
			problems.append("monstro na entrada: " + e["id"])
	for key in ["spawn", "camp", "camp_exit", "stairs_down"]:
		if not reach.has(DungeonLayout.cell(desc[key])):
			problems.append("ponto inalcançável: " + key)
	if bosses != 1:
		problems.append("chefes: %d" % bosses)
	if objectives != 1:
		problems.append("relicários: %d" % objectives)
	if desc["rooms"].size() != room_target(int(desc["floor"])):
		problems.append("salas: %d" % desc["rooms"].size())
	return problems

# --- layout -----------------------------------------------------------------------

static func _place_rooms(rng: RandomNumberGenerator, target: int) -> Dictionary:
	var area: float = target * 49.0 * 2.8
	var w: int = int(sqrt(area * 1.35))
	var h: int = int(area / w)
	while true:
		var rects: Array = []
		var ok: bool = true
		for i in target:
			var size := Vector2i(7, 7)
			if i > 0:
				size = Vector2i(rng.randi_range(5, 9), rng.randi_range(5, 8))
				if i % 7 == 3:
					size = Vector2i(rng.randi_range(9, 11), rng.randi_range(8, 10))
			var done: bool = false
			for attempt in 400:
				var pos := Vector2i(rng.randi_range(2, w - size.x - 2), rng.randi_range(2, h - size.y - 2))
				if i == 0:
					# Entrance near the bottom-left, so the floor unfolds away from it.
					pos = Vector2i(rng.randi_range(2, maxi(2, w / 5)), rng.randi_range(maxi(2, h - h / 4), h - size.y - 2))
				var candidate := Rect2i(pos, size)
				var free: bool = true
				for other in rects:
					if candidate.grow(GAP).intersects(other):
						free = false
						break
				if free:
					rects.append(candidate)
					done = true
					break
			if not done:
				ok = false
				break
		if ok:
			return {"rects": rects, "size": Vector2i(w, h)}
		w = int(w * 1.12) + 2
		h = int(h * 1.12) + 2
	return {}

static func _center(r: Rect2i) -> Vector2i:
	return r.position + r.size / 2

## Minimum spanning tree over room centers plus a few loops for shortcuts.
## Prim's tree in O(n²): every room outside the tree keeps its nearest room in
## the tree. Ties go the way the first version (an O(n³) search) went, to the
## room that joined the tree first and then the lowest index, so every seed keeps
## the labyrinth it always had (saves and the explored map depend on it).
static func _connect(rng: RandomNumberGenerator, rects: Array, floor: int) -> Array:
	var n: int = rects.size()
	var centers: Array = []
	for r in rects:
		centers.append(Vector2(_center(r)))
	var edges: Array = []
	var linked: Dictionary = {}
	var joined_at := PackedInt32Array()
	joined_at.resize(n)
	joined_at.fill(-1)
	var best := PackedFloat64Array()
	best.resize(n)
	var nearest := PackedInt32Array()
	nearest.resize(n)
	joined_at[0] = 0
	for b in n:
		best[b] = centers[0].distance_to(centers[b])
		nearest[b] = 0
	for joined in range(1, n):
		var pick: int = -1
		for b in n:
			if joined_at[b] >= 0:
				continue
			if pick < 0 or best[b] < best[pick] or (best[b] == best[pick] and joined_at[nearest[b]] < joined_at[nearest[pick]]):
				pick = b
		var a: int = nearest[pick]
		edges.append([a, pick])
		linked["%d-%d" % [mini(a, pick), maxi(a, pick)]] = true
		joined_at[pick] = joined
		for b in n:
			if joined_at[b] < 0:
				var d: float = centers[pick].distance_to(centers[b])
				if d < best[b]:
					best[b] = d
					nearest[b] = pick
	var loop_chance: float = 0.14 + 0.03 * mini(floor - 1, 4)
	for a in n:
		var near: Array = _two_nearest(centers, a)
		for k in mini(2, near.size()):
			var b: int = near[k][1]
			var key := "%d-%d" % [mini(a, b), maxi(a, b)]
			if not linked.has(key) and rng.randf() < loop_chance:
				linked[key] = true
				edges.append([a, b])
	return edges

## The two rooms nearest to room `a`, nearest first, as [distance, index]. A
## linear pass; only when distances tie around the first two places does it
## sort the whole list as the first version did, so the result never changes.
static func _two_nearest(centers: Array, a: int) -> Array:
	var d1: float = INF
	var d2: float = INF
	var d3: float = INF
	var i1: int = -1
	var i2: int = -1
	for b in centers.size():
		if b == a:
			continue
		var d: float = centers[a].distance_to(centers[b])
		if d < d1:
			d3 = d2
			d2 = d1
			i2 = i1
			d1 = d
			i1 = b
		elif d < d2:
			d3 = d2
			d2 = d
			i2 = b
		elif d < d3:
			d3 = d
	if i2 < 0:
		return [] if i1 < 0 else [[d1, i1]]
	if d1 < d2 and d2 < d3:
		return [[d1, i1], [d2, i2]]
	var near: Array = []
	for b in centers.size():
		if b != a:
			near.append([centers[a].distance_to(centers[b]), b])
	near.sort_custom(func(x, y): return x[0] < y[0])
	return near

## Two-cell wide L-shaped corridors between connected rooms.
static func _corridors(rng: RandomNumberGenerator, rects: Array, edges: Array) -> Array:
	var out: Array = []
	for e in edges:
		var a: Vector2i = _center(rects[e[0]])
		var b: Vector2i = _center(rects[e[1]])
		if rng.randf() < 0.5:
			out.append(_hseg(a.x, b.x, a.y))
			out.append(_vseg(a.y, b.y, b.x))
		else:
			out.append(_vseg(a.y, b.y, a.x))
			out.append(_hseg(a.x, b.x, b.y))
	return out

static func _hseg(x0: int, x1: int, y: int) -> Rect2i:
	return Rect2i(mini(x0, x1), y, absi(x1 - x0) + 2, 2)

static func _vseg(y0: int, y1: int, x: int) -> Rect2i:
	return Rect2i(x, mini(y0, y1), 2, absi(y1 - y0) + 2)

static func _carve(floors: Dictionary, r: Rect2i) -> void:
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			floors[Vector2i(x, y)] = true

static func _graph(n: int, edges: Array) -> Array:
	var g: Array = []
	for i in n:
		g.append([])
	for e in edges:
		g[e[0]].append(e[1])
		g[e[1]].append(e[0])
	return g

static func _bfs(graph: Array, start: int) -> Array:
	var dist: Array = []
	dist.resize(graph.size())
	dist.fill(-1)
	dist[start] = 0
	var queue: Array = [start]
	while not queue.is_empty():
		var a: int = queue.pop_front()
		for b in graph[a]:
			if dist[b] < 0:
				dist[b] = dist[a] + 1
				queue.append(b)
	return dist

# --- rooms --------------------------------------------------------------------------

static func _assign_types(rng: RandomNumberGenerator, rects: Array, graph: Array, depth: Array, floor: int) -> Array:
	var n: int = rects.size()
	var types: Array = []
	types.resize(n)
	types.fill("")
	types[0] = "abrigo" if floor == 1 else "entrada"
	# Boss: farthest room; among equals, the largest.
	var boss: int = 1
	for i in range(1, n):
		var better: bool = depth[i] > depth[boss] or (depth[i] == depth[boss] and rects[i].get_area() > rects[boss].get_area())
		if better:
			boss = i
	types[boss] = "chefe"
	# Seeded shuffle (Array.shuffle() would use the global generator).
	var order: Array = range(1, n)
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t = order[i]
		order[i] = order[j]
		order[j] = t
	var treasures: int = maxi(1, n / 8)
	var lairs: int = maxi(1, n / 10)
	for i in order:
		if types[i] != "":
			continue
		if graph[i].size() == 1 and treasures > 0 and depth[i] >= 2:
			types[i] = "tesouro"
			treasures -= 1
	for i in order:
		if types[i] != "":
			continue
		if lairs > 0 and depth[i] >= 2 and rects[i].get_area() >= 36:
			types[i] = "covil"
			lairs -= 1
	for i in order:
		if types[i] != "":
			continue
		types[i] = "suprimentos" if rng.randf() < 0.22 else "combate"
	return types

static func _room_name(rng: RandomNumberGenerator, kind: String, used: Dictionary, floor: int) -> String:
	var data: Dictionary = room_names()
	var bases: Array = data.get("nomes", {}).get(kind, [["Sala", "f"]])
	var base: Array = bases[rng.randi_range(0, bases.size() - 1)]
	if kind == "abrigo":
		return bases[0][0]
	if kind == "entrada":
		return base[0]
	if kind == "chefe":
		return base[0]
	var extras: Array = data.get("complementos", [["antigo", "antiga"]])
	for attempt in 30:
		base = bases[rng.randi_range(0, bases.size() - 1)]
		var extra: Array = extras[rng.randi_range(0, extras.size() - 1)]
		var name: String = "%s %s" % [base[0], extra[1] if base[1] == "f" else extra[0]]
		if not used.has(name):
			used[name] = true
			return name
	return "%s %d" % [bases[0][0], used.size() + 1]

static func _is_opening(cell: Vector2i, r: Rect2i, floors: Dictionary) -> bool:
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var out: Vector2i = cell + d
		if not r.has_point(out) and floors.has(out):
			return true
	return false

## A border cell of the room that does not block a doorway.
static func _free_edge(rng: RandomNumberGenerator, r: Rect2i, floors: Dictionary, occupied: Dictionary, prefer_top: bool = false) -> Vector2i:
	var cells: Array = []
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			var border: bool = x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1
			if not border:
				continue
			var c := Vector2i(x, y)
			if occupied.has(c) or _is_opening(c, r, floors):
				continue
			var near_door: bool = false
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if r.has_point(c + d) and _is_opening(c + d, r, floors):
					near_door = true
			if near_door:
				continue
			if prefer_top and y != r.position.y:
				continue
			cells.append(c)
	if cells.is_empty() and prefer_top:
		return _free_edge(rng, r, floors, occupied, false)
	if cells.is_empty():
		return r.position + Vector2i(1, 1)
	return cells[rng.randi_range(0, cells.size() - 1)]

static func _free_inside(rng: RandomNumberGenerator, r: Rect2i, occupied: Dictionary, margin: int = 1) -> Vector2i:
	for attempt in 40:
		var c := Vector2i(rng.randi_range(r.position.x + margin, r.end.x - 1 - margin), rng.randi_range(r.position.y + margin, r.end.y - 1 - margin))
		if not occupied.has(c):
			return c
	return Vector2i(-1, -1)

static func _roll_loot(rng: RandomNumberGenerator, table_id: String, floor: int) -> Dictionary:
	var table: Dictionary = loot_tables().get(table_id, {})
	var items: Dictionary = {}
	for key in table.get("fixed", {}):
		items[key] = int(table["fixed"][key])
	var rolls: Array = table.get("rolls", [0, 0])
	var entries: Array = []
	var total: float = 0.0
	for e in table.get("entries", []):
		if floor >= int(e[4]):
			entries.append(e)
			total += float(e[1])
	for i in rng.randi_range(int(rolls[0]), int(rolls[1])):
		if total <= 0:
			break
		var pick: float = rng.randf() * total
		for e in entries:
			pick -= float(e[1])
			if pick <= 0:
				items[e[0]] = int(items.get(e[0], 0)) + rng.randi_range(int(e[2]), int(e[3]))
				break
	return items

static func _pick_enemy(rng: RandomNumberGenerator, floor: int) -> String:
	var weights: Dictionary = ENEMY_WEIGHTS[mini(floor - 1, ENEMY_WEIGHTS.size() - 1)]
	var total: int = 0
	for k in weights:
		total += weights[k]
	var pick: int = rng.randi_range(1, total)
	for k in weights:
		pick -= weights[k]
		if pick <= 0:
			return k
	return "corrompido"

static func _fill_room(rng: RandomNumberGenerator, desc: Dictionary, index: int, r: Rect2i, kind: String, floors: Dictionary, occupied: Dictionary, floor: int) -> void:
	var tag := "s%d" % index
	# Furniture along the walls, away from doorways.
	var pieces: Array = FURNITURE.get(kind, [])
	var count: int = pieces.size()
	if kind == "combate":
		count = rng.randi_range(0, 3)
	for k in count:
		var model: String = pieces[k] if kind != "combate" else pieces[rng.randi_range(0, pieces.size() - 1)]
		var cell: Vector2i = _free_edge(rng, r, floors, occupied)
		if occupied.has(cell):
			continue
		occupied[cell] = true
		var vertical_edge: bool = cell.x == r.position.x or cell.x == r.end.x - 1
		var rotation: float = 0.0
		if model in LONG_X and vertical_edge:
			rotation = 90.0
		elif model in LONG_Z and not vertical_edge:
			rotation = 90.0
		desc["furniture"].append({"cell": [cell.x, cell.y], "model": model, "rotation": rotation})
	# Corner pillars in the boss chamber and stone islands in large rooms.
	if kind == "chefe":
		for corner in [r.position + Vector2i(1, 1), Vector2i(r.end.x - 2, r.position.y + 1), Vector2i(r.position.x + 1, r.end.y - 2), r.end - Vector2i(2, 2)]:
			if not occupied.has(corner):
				occupied[corner] = true
				desc["furniture"].append({"cell": [corner.x, corner.y], "model": "pilar", "rotation": 0.0})
	elif kind in ["combate", "covil"] and r.size.x >= 8 and r.size.y >= 7 and rng.randf() < 0.7:
		var c: Vector2i = _free_inside(rng, r, occupied, 2)
		if c.x >= 0:
			for d in [Vector2i.ZERO, Vector2i.RIGHT if rng.randf() < 0.5 else Vector2i.DOWN]:
				if not occupied.has(c + d):
					occupied[c + d] = true
					desc["blocked"].append([c.x + d.x, c.y + d.y])
	# Containers
	var chests: Array = []
	match kind:
		"abrigo":
			chests = [["abrigo", "RECIPIENTE_RESERVA"]]
		"suprimentos":
			chests = [["suprimentos", "RECIPIENTE_BAU"]]
			if r.get_area() >= 48:
				chests.append(["suprimentos", "RECIPIENTE_BAU"])
		"tesouro":
			chests = [["tesouro", "RECIPIENTE_BAU"]]
		"covil":
			if rng.randf() < 0.6:
				chests = [["covil", "RECIPIENTE_BAU"]]
		"combate":
			if rng.randf() < 0.35:
				chests = [["combate", "RECIPIENTE_BAU"]]
		"chefe":
			chests = [["chefe", "RECIPIENTE_BAU_CHEFE"]]
	var n: int = 0
	for chest in chests:
		var cell: Vector2i = _free_edge(rng, r, floors, occupied)
		if occupied.has(cell):
			continue
		occupied[cell] = true
		var entry := {"id": "%s_bau_%d" % [tag, n], "name": chest[1], "cell": [cell.x, cell.y], "items": _roll_loot(rng, chest[0], floor), "chest": true}
		var lock: int = _roll_lock(int(desc["seed"]), floor, index, n, kind)
		if lock > 0:
			entry["lock"] = lock
		if kind == "chefe":
			entry["objective"] = true  # the relic chest, guarded by the boss
		desc["containers"].append(entry)
		n += 1
	# Monsters
	var foes: Array = []
	var area: int = r.get_area()
	match kind:
		"combate":
			for i in clampi(roundi(area / 28.0 * (1.0 + 0.2 * (floor - 1))), 1, 4):
				foes.append(_pick_enemy(rng, floor))
		"suprimentos":
			if rng.randf() < 0.5:
				foes.append(_pick_enemy(rng, floor))
		"tesouro":
			for i in rng.randi_range(1, 2):
				foes.append(_pick_enemy(rng, floor))
		"covil":
			foes.append("guardiao")
			for i in rng.randi_range(1, 2):
				foes.append(_pick_enemy(rng, floor))
		"chefe":
			foes.append("chefe")
			if floor >= 3:
				foes.append("espreitador")
				foes.append("espreitador")
	var m: int = 0
	for foe in foes:
		var cell: Vector2i = _free_inside(rng, r, occupied, 1)
		if cell.x < 0:
			continue
		occupied[cell] = true
		desc["enemies"].append({"id": "%s_m%d" % [tag, m], "type": foe, "cell": [cell.x, cell.y], "level": floor})
		m += 1

## Locks use their own generator so the rest of the floor stays the same for a seed.
## Treasure is usually locked; supplies, lairs and combat rooms sometimes.
static func _roll_lock(seed: int, floor: int, room: int, chest: int, kind: String) -> int:
	var odds: float = {"tesouro": 0.8, "covil": 0.4, "suprimentos": 0.25, "combate": 0.15}.get(kind, 0.0)
	if odds <= 0.0:
		return 0
	var lr := RandomNumberGenerator.new()
	lr.seed = floor_seed(seed, floor) ^ (room * 7919 + chest * 104729 + 31)
	if lr.randf() >= odds:
		return 0
	var base: int = 1 + (floor - 1) / 2 + (1 if kind == "tesouro" else 0)
	return clampi(base + lr.randi_range(-1, 1), 1, 4)

static func _flood(floors: Dictionary, solid: Dictionary, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nb: Vector2i = c + d
			if floors.has(nb) and not solid.has(nb) and not seen.has(nb):
				seen[nb] = true
				queue.append(nb)
	return seen

## Drops stone islands and then furniture that cut off part of the floor.
static func _ensure_reachable(desc: Dictionary, floors: Dictionary) -> void:
	var open: Dictionary = floors.duplicate()
	for b in desc["blocked"]:
		open.erase(DungeonLayout.cell(b))
	var needed: Array = []
	for c in desc["containers"]:
		needed.append(DungeonLayout.cell(c["cell"]))
	for e in desc["enemies"]:
		needed.append(DungeonLayout.cell(e["cell"]))
	for key in ["stairs_down", "camp", "camp_exit"]:
		needed.append(DungeonLayout.cell(desc[key]))
	for room in desc["rooms"]:
		var r: Rect2i = DungeonLayout.rect(room["rect"])
		needed.append(_center(r))
	var spawn: Vector2i = DungeonLayout.cell(desc["spawn"])
	for pass_index in 4:
		var solid: Dictionary = {}
		for f in desc["furniture"]:
			solid[DungeonLayout.cell(f["cell"])] = true
		var reach: Dictionary = _flood(open, solid, spawn)
		var missing: bool = false
		for c in needed:
			if open.has(c) and not reach.has(c):
				missing = true
				break
		if not missing:
			return
		if pass_index == 0:
			desc["blocked"].clear()
			open = floors.duplicate()
		elif pass_index == 1:
			desc["furniture"] = desc["furniture"].filter(func(f): return f["model"] == "pilar")
		elif pass_index == 2:
			desc["furniture"].clear()
