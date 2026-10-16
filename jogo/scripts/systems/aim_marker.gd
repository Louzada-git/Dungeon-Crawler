extends Node3D
class_name AimMarker
## Ring under the cursor while aiming; snaps to an enemy and shows if it is in reach.

var ring: MeshInstance3D

func _ready() -> void:
	ring = Visuals.ring(0.20, Color("c7c5ac"), 0.025)
	add_child(ring)
	visible = false

func refresh(game) -> void:
	# Third person aims with the crosshair in the middle of the screen instead.
	visible = game.player.aiming and not game.ui.any_panel() and not game.ended and not game.third_person()
	if not visible:
		return
	var mouse = get_viewport().get_mouse_position()
	var point = Plane(Vector3.UP, 0.65).intersects_ray(game.camera.project_ray_origin(mouse), game.camera.project_ray_normal(mouse))
	if point == null:
		hide()
		return
	var pos: Vector3 = point
	pos.y = 0.06
	if not game.layout.is_floor(game.layout.to_cell(pos)):
		hide()
		return
	position = pos
	scale = Vector3.ONE
	var color := Color("a6a799")
	for enemy in game.enemies:
		if enemy.alive and enemy.position.distance_to(pos) < 0.9 and game.clear_line(game.player.position, enemy.position):
			position = enemy.position + Vector3.UP * 0.06
			scale = Vector3.ONE * 2.5
			# "range" is how far the blade goes from the adventurer; the body adds its radius.
			var reach: float = float(game.sheet.weapon_stats(game.inventory.equipped).get("range", 1.5)) + float(enemy.stats.get("radius", 0.4))
			color = Color("d9bd81") if game.player.position.distance_to(enemy.position) <= reach else Color("8d7a65")
			break
	ring.material_override.albedo_color = color
