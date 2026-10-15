extends RefCounted
class_name Combat
## Resolves the player's committed strike. Weapon styles come from the item
## data: slash (arc), thrust (straight line, pierces "targets"), smash (area in
## front) and shoot (projectile with ammunition). Effects: sneak_mult (unaware
## monsters), bleed, crush (armored monsters), stagger, knockback and cura
## (health back to the adventurer for each blow that lands).

static func resolve_player_attack(game) -> void:
	var player = game.player
	# Each committed swing resolves once, even if another callback arrives.
	if player.resolved_serial == player.attack_serial or player.health <= 0:
		return
	player.resolved_serial = player.attack_serial
	var weapon: Dictionary = player.attack_weapon
	match str(weapon.get("style", "slash")):
		"shoot":
			_shoot(game, weapon)
			return
		"smash":
			_smash(game, weapon)
			return
	var reach: float = weapon.get("range", 1.5)
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
	var notes: Array = []
	# Techniques may strike more than once (Golpe duplo, Sequência de socos).
	for strike in maxi(1, int(weapon.get("hits", 1))):
		for i in limit:
			var note: String = apply_hit(game, candidates[i], weapon, player.attack_facing)
			if note != "" and not notes.has(note):
				notes.append(note)
	if limit > 0:
		game.sound.play_at("hit", candidates[0].global_position, 0.8)
		game.camera_impact(0.045 if float(weapon.get("knockback", 3.0)) <= 3.0 else 0.08)
		game.message(" ".join(notes) if not notes.is_empty() else "Acerto. Preserve o fôlego para recuar.", 1.3)

## Damage and effects of one hit. Returns a short note for the message line.
static func apply_hit(game, enemy, weapon: Dictionary, direction: Vector3, damage: float = -1.0) -> String:
	var amount: float = float(weapon.get("damage", 9.0)) if damage < 0 else damage
	var note: String = ""
	if weapon.has("sneak_mult") and not enemy.aggro:
		amount *= float(weapon["sneak_mult"])
		note = "Ataque furtivo!"
	var sneak: bool = game.player.sneaking and not enemy.aggro
	if sneak:
		amount *= game.sheet.sneak_attack_mult()
		note = "Ataque furtivo!"
	if weapon.has("crush") and enemy.armored:
		amount *= float(weapon["crush"])
		note = "Esmagou a armadura!"
	var hit: Dictionary = {}
	if weapon.has("stagger"):
		hit["stagger"] = float(weapon["stagger"])
	if weapon.has("knockback"):
		hit["knockback"] = float(weapon["knockback"])
	var before: float = enemy.health
	var path: Array = weapon.get("proficiencias", [])
	# Strong blows (sneak attacks, crushed armour, heavy stuns) get a bigger burst.
	var strong: bool = note != "" or float(weapon.get("stagger", 0.0)) >= 1.1 or float(weapon.get("knockback", 3.0)) >= 6.0
	enemy.receive_damage(amount, direction, hit)
	Vfx.enemy_hit(game, enemy, strong, weapon.has("crush"))
	# Practice: the monster teaches in proportion to the damage that landed.
	var dealt: float = clampf(minf(amount, before), 0.0, before)
	game.sheet.award_damage(enemy, dealt, path)
	# Bálsamo (Tratamento): each blow that lands heals the adventurer.
	if weapon.has("cura") and dealt > 0.0 and game.player.health > 0.0:
		game.player.health = minf(game.player.max_health, game.player.health + float(weapon["cura"]))
	if sneak:
		var value: float = float(EnemyTypes.info(enemy.kind).get("xp", 20)) * (1.0 + 0.25 * (enemy.level - 1))
		game.sheet.award("furtividade", value * 0.3 * dealt / enemy.maximum_health, enemy.level)
	if weapon.has("bleed") and enemy.alive:
		enemy.apply_bleed(float(weapon["bleed"].get("dps", 4.0)), float(weapon["bleed"].get("time", 4.0)), path)
		if note == "":
			note = "Ferida aberta: o monstro sangra."
	return note

## Heavy blow on the ground in front: everything in the circle is hit.
static func _smash(game, weapon: Dictionary) -> void:
	var player = game.player
	var center: Vector3 = player.position + player.attack_facing * float(weapon.get("area_offset", 1.3))
	var radius: float = float(weapon.get("area_radius", 1.6))
	var ring = Visuals.ring(radius, Color(0.92, 0.78, 0.52, 0.85), 0.16)
	game.add_child(ring)
	ring.position = center + Vector3(0, 0.07, 0)
	# Shockwave: grows to full size and fades.
	ring.scale = Vector3.ONE * 0.55
	var wave = ring.create_tween()
	wave.tween_property(ring, "scale", Vector3.ONE, 0.12)
	wave.parallel().tween_property(ring.material_override, "albedo_color:a", 0.0, 0.4)
	wave.tween_callback(ring.queue_free)
	Vfx.dust_ring(game, center, radius)
	var hits: Array = []
	for enemy in game.enemies:
		if not enemy.alive:
			continue
		var offset: Vector3 = enemy.position - center
		offset.y = 0
		if offset.length() <= radius + float(enemy.stats.get("radius", 0.4)) * 0.5 and game.clear_line(player.position, enemy.position):
			hits.append(enemy)
	hits.sort_custom(func(a, b): return a.position.distance_squared_to(center) < b.position.distance_squared_to(center))
	var notes: Array = []
	for strike in maxi(1, int(weapon.get("hits", 1))):
		for i in mini(hits.size(), int(weapon.get("targets", 6))):
			var away: Vector3 = hits[i].position - center
			away.y = 0
			var note: String = apply_hit(game, hits[i], weapon, away.normalized() if away.length() > 0.05 else player.attack_facing)
			if note != "" and not notes.has(note):
				notes.append(note)
	game.camera_impact(0.12)
	game.sound.play_at("hit", center, 0.9 if not hits.is_empty() else 0.45)
	if not hits.is_empty():
		game.message(" ".join(notes) if not notes.is_empty() else "Pancada certeira.", 1.3)

## Releases a projectile and spends one unit of ammunition.
static func _shoot(game, weapon: Dictionary) -> void:
	var count: int = maxi(1, int(weapon.get("hits", 1)))
	for i in count:
		# Extra shots of a technique fan out a little.
		_shoot_one(game, weapon, deg_to_rad(5.0) * (i - (count - 1) * 0.5))

static func _shoot_one(game, weapon: Dictionary, spread: float) -> void:
	var player = game.player
	var ammo: String = str(weapon.get("ammo", ""))
	if ammo != "":
		if not game.inventory.remove(ammo, 1):
			game.message("Sem munição.", 1.5)
			return
	var shot := Projectile.new()
	shot.game = game
	shot.weapon = weapon
	shot.ammo = ammo
	shot.direction = player.attack_facing.normalized().rotated(Vector3.UP, spread)
	shot.speed = float(weapon.get("projectile_speed", 22.0))
	shot.max_distance = float(weapon.get("range", 14.0))
	shot.pierce = int(weapon.get("pierce", 1))
	game.add_child(shot)
	shot.global_position = player.position + Vector3(0, 1.15, 0) + shot.direction * 0.45
	game.sound.play_at("swing", player.global_position, 0.5)
	game.ui.refresh_inventory()

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
