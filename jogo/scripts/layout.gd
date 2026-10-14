extends RefCounted
class_name DungeonLayout

const CELL: float = 2.0
const SIZE = Vector2i(33, 27)
const SPAWN = Vector2i(4, 21)
const RELIC = Vector2i(27, 5)
var floors: Dictionary = {}
var rooms: Array[Dictionary] = []
var pathfinder = AStarGrid2D.new()

func _init() -> void:
 rooms = [
  {"name":"Abrigo da entrada", "rect":Rect2i(2, 18, 7, 7)},
  {"name":"Galeria da guarda", "rect":Rect2i(3, 8, 8, 7)},
  {"name":"Depósito esquecido", "rect":Rect2i(16, 17, 8, 7)},
  {"name":"Salão das cisternas", "rect":Rect2i(16, 5, 8, 8)},
  {"name":"Câmara do selo", "rect":Rect2i(26, 2, 5, 8)}
 ]
 for room in rooms:
  carve(room["rect"])
 for corridor in [Rect2i(5, 14, 2, 5), Rect2i(8, 20, 9, 2), Rect2i(10, 10, 7, 2), Rect2i(19, 12, 2, 6), Rect2i(23, 7, 4, 2)]:
  carve(corridor)
 # Stone islands provide cover and make routes meaningful.
 for cell in [Vector2i(6,10), Vector2i(7,10), Vector2i(19,8), Vector2i(20,8), Vector2i(19,9), Vector2i(20,9), Vector2i(20,20)]:
  floors.erase(cell)
 pathfinder.region = Rect2i(Vector2i.ZERO, SIZE)
 pathfinder.cell_size = Vector2(CELL, CELL)
 pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 pathfinder.update()
 for x in SIZE.x:
  for y in SIZE.y:
   pathfinder.set_point_solid(Vector2i(x,y), not floors.has(Vector2i(x,y)))

func carve(rect: Rect2i) -> void:
 for x in range(rect.position.x, rect.end.x):
  for y in range(rect.position.y, rect.end.y):
   floors[Vector2i(x,y)] = true

func to_world(cell: Vector2i) -> Vector3:
 return Vector3(cell.x * CELL, 0, cell.y * CELL)

func to_cell(pos: Vector3) -> Vector2i:
 return Vector2i(roundi(pos.x / CELL), roundi(pos.z / CELL))

func is_floor(cell: Vector2i) -> bool:
 return floors.has(cell)

func room_name(pos: Vector3) -> String:
 var cell = to_cell(pos)
 for room in rooms:
  if room["rect"].has_point(cell):
   return room["name"]
 return "Passagem subterrânea"

func route(from: Vector3, to: Vector3) -> Array[Vector2i]:
 var a = to_cell(from)
 var b = to_cell(to)
 if not floors.has(a) or not floors.has(b):
  return []
 return pathfinder.get_id_path(a, b)
