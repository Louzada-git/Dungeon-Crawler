extends Node3D
class_name Projectile
## Arrow or bolt in flight. Moves in straight steps, stops at walls, hits
## monsters along the way (pierce = how many it can go through). Ammunition
## stuck in a monster drops with its belongings; part of what misses can be
## picked up from the floor ("recover" in the item data).

var game: DungeonGame
var weapon: Dictionary = {}
var ammo: String = ""
var direction: Vector3 = Vector3.FORWARD
var speed: float = 22.0
var max_distance: float = 14.0
var pierce: int = 1
var traveled: float = 0.0
var _hit: Dictionary = {}

func _ready() -> void:
	add_to_group("projeteis")
	var model: Node3D = Visuals.item_model(ammo) if ammo != "" else Visuals.blocks([{"size": [0.02, 0.6, 0.02], "pos": [0, 0, 0], "color": "d9d0b8"}])
	add_child(model)
	var side: Vector3 = Vector3.UP.cross(direction).normalized()
	if side.length() < 0.5:
		side = Vector3.RIGHT
	model.basis = Basis(side, direction, side.cross(direction))
	model.position = -direction * 0.55

func _physics_process(delta: float) -> void:
	if game == null or game.ended:
		queue_free()
		return
	var step: float = speed * delta
	var from: Vector3 = global_position
	var to: Vector3 = from + direction * step
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var wall: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var end: Vector3 = wall["position"] if not wall.is_empty() else to
	var a := Vector2(from.x, from.z)
	var b := Vector2(end.x, end.z)
	var targets: Array = []
	for enemy in game.enemies:
		if not enemy.alive or _hit.has(enemy.get_instance_id()):
			continue
		var c := Vector2(enemy.global_position.x, enemy.global_position.z)
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(c, a, b)
		if closest.distance_to(c) <= float(enemy.stats.get("radius", 0.4)) + 0.15:
			targets.append([a.distance_to(closest), enemy])
	targets.sort_custom(func(x, y): return x[0] < y[0])
	for entry in targets:
		var enemy = entry[1]
		_hit[enemy.get_instance_id()] = true
		var note: String = Combat.apply_hit(game, enemy, weapon, direction)
		game.sound.play_at("hit", enemy.global_position, 0.7)
		game.camera_impact(0.04)
		game.message(note if note != "" else "Acerto à distância.", 1.2)
		pierce -= 1
		if pierce <= 0:
			if ammo != "":
				if enemy.alive:
					enemy.stuck[ammo] = int(enemy.stuck.get(ammo, 0)) + 1
				else:
					ContainerSystem.add_ground(game, enemy.global_position, ammo, 1)
			queue_free()
			return
	global_position = end
	traveled += step
	if not wall.is_empty() or traveled >= max_distance:
		if not wall.is_empty():
			Vfx.burst(game, "impacto", end, 0.5)
			Vfx.burst(game, "poeira", end - direction * 0.1, 0.6)
		_fall()
		queue_free()

## A miss: a share of the ammunition can be picked up where it fell.
func _fall() -> void:
	if ammo == "":
		return
	var share: float = float(Items.info(ammo).get("recover", 0.0)) + float(weapon.get("recover_bonus", 0.0))
	game.ammo_recovery[ammo] = float(game.ammo_recovery.get(ammo, 0.0)) + share
	if game.ammo_recovery[ammo] >= 1.0:
		game.ammo_recovery[ammo] -= 1.0
		ContainerSystem.add_ground(game, global_position - direction * 0.4, ammo, 1)
