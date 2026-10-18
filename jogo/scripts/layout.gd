extends RefCounted
class_name DungeonLayout
## Floor grid, rooms and navigation built from a world description
## (data/mundos/<id>.json). A procedural generator only needs to produce
## the same description format.

const CELL: float = 2.0
var world: Dictionary = {}
var size: Vector2i
var spawn: Vector2i
var camp: Vector2i
var camp_exit: Vector2i
var relic: Vector2i
var floors: Dictionary = {}
var rooms: Array[Dictionary] = []
## Index in `rooms` of each cell inside a room (the first room listed wins).
## Finding the room of a position is asked many times per frame (every monster
## checks the shelter), so it is a lookup instead of a walk over all rooms.
var room_of_cell: Dictionary = {}
var pathfinder = AStarGrid2D.new()

static func load_world(id: String) -> Dictionary:
	var path := "res://data/mundos/%s.json" % id
	var raw = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		push_error("Mundo inválido: " + path)
		return {}
	return raw

static func cell(value) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

static func rect(value) -> Rect2i:
	return Rect2i(int(value[0]), int(value[1]), int(value[2]), int(value[3]))

func _init(description: Dictionary = {}) -> void:
	world = description if not description.is_empty() else load_world("cisternas")
	size = cell(world["size"])
	spawn = cell(world["spawn"])
	camp = cell(world["camp"])
	camp_exit = cell(world["camp_exit"])
	for entry in world["rooms"]:
		rooms.append({"id": entry["id"], "name": str(TranslationServer.translate(entry["name"])), "rect": rect(entry["rect"]), "safe": entry.get("safe", false)})
	for i in rooms.size():
		var r: Rect2i = rooms[i]["rect"]
		carve(r)
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				if not room_of_cell.has(Vector2i(x, y)):
					room_of_cell[Vector2i(x, y)] = i
	for corridor in world["corridors"]:
		carve(rect(corridor))
	# Stone islands provide cover and make routes meaningful.
	for blocked in world["blocked"]:
		floors.erase(cell(blocked))
	relic = spawn
	for container in world["containers"]:
		if container.get("objective", false):
			relic = cell(container["cell"])
	pathfinder.region = Rect2i(Vector2i.ZERO, size)
	pathfinder.cell_size = Vector2(CELL, CELL)
	pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	pathfinder.update()
	for x in size.x:
		for y in size.y:
			pathfinder.set_point_solid(Vector2i(x, y), not floors.has(Vector2i(x, y)))

func carve(area: Rect2i) -> void:
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			floors[Vector2i(x, y)] = true

func to_world(c: Vector2i) -> Vector3:
	return Vector3(c.x * CELL, 0, c.y * CELL)

func to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x / CELL), roundi(pos.z / CELL))

func is_floor(c: Vector2i) -> bool:
	return floors.has(c)

## The room a position is in, or {} in a corridor.
func room_at(pos: Vector3) -> Dictionary:
	var i: int = room_of_cell.get(to_cell(pos), -1)
	return rooms[i] if i >= 0 else {}

func is_safe(pos: Vector3) -> bool:
	return room_at(pos).get("safe", false)

func room_name(pos: Vector3) -> String:
	var room: Dictionary = room_at(pos)
	return room["name"] if not room.is_empty() else str(TranslationServer.translate("SALA_PASSAGEM"))

func route(from: Vector3, to: Vector3) -> Array[Vector2i]:
	var a = to_cell(from)
	var b = to_cell(to)
	if not floors.has(a) or not floors.has(b):
		return []
	return pathfinder.get_id_path(a, b)
