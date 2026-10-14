extends RefCounted
class_name Combat
## Resolves the player's committed strike against monsters.

static func resolve_player_attack(game) -> void:
	var player = game.player
	# Each committed swing resolves once, even if another callback arrives.
	if player.resolved_serial == player.attack_serial or player.health <= 0:
		return
	player.resolved_serial = player.attack_serial
	var weapon: Dictionary = player.attack_weapon
	var reach: float = weapon.get("range", 1.5)
	var damage: float = weapon.get("damage", 9.0)
	var half_angle: float = deg_to_rad(weapon.get("angle", 55.0))
	_show_arc(game, weapon, reach, half_angle)
	var candidates: Array = []
	for enemy in game.enemies:
		if not enemy.alive:
			continue
		var offset: Vector3 = enemy.position - player.position
		offset.y = 0
		var within_shape: bool = player.attack_facing.dot(offset.normalized()) >= cos(half_angle)
		if weapon.get("style", "") == "thrust":
			var forward: float = offset.dot(player.attack_facing)
			var sideways: float = (offset - player.attack_facing * forward).length()
			within_shape = forward > 0 and sideways <= float(weapon.get("width", 0.34))
		if offset.length() <= reach and within_shape and game.clear_line(player.position, enemy.position):
			candidates.append(enemy)
	candidates.sort_custom(func(a, b): return a.position.distance_squared_to(player.position) < b.position.distance_squared_to(player.position))
	var limit: int = mini(candidates.size(), int(weapon.get("targets", 1)))
	for i in limit:
		candidates[i].receive_damage(damage, player.attack_facing)
	if limit > 0:
		game.sound.play_at("hit", candidates[0].global_position, 0.8)
		game.camera_impact(0.045)
		game.message("Acerto. Preserve o fôlego para recuar.", 1.3)

static func _show_arc(game, weapon: Dictionary, reach: float, half_angle: float) -> void:
	var player = game.player
	var arc = Visuals.attack_arc(reach, Color(0.9, 0.80, 0.61, 0.30), half_angle, 0.06)
	game.add_child(arc)
	arc.position = player.position + Vector3(0, 0.12, 0)
	arc.rotation.y = atan2(player.attack_facing.x, player.attack_facing.z)
	game.get_tree().create_timer(0.12).timeout.connect(arc.queue_free)
	if weapon.get("style", "") == "slash":
		var trail = Visuals.attack_arc(minf(reach, 1.65), Color(0.74, 0.77, 0.74, 0.67), half_angle, 0.19)
		game.add_child(trail)
		trail.position = player.position + Vector3(0, 0.85, 0)
		trail.rotation.y = arc.rotation.y
		game.get_tree().create_timer(0.15).timeout.connect(trail.queue_free)
