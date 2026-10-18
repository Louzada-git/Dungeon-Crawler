extends RefCounted
class_name Combat
## Resolves the player's committed strike. A melee blow hits what the weapon
## touches over its swing (see Hitbox): slash and smash hit up to "targets" in
## the order the blade reached them, a thrust goes through up to "targets" along
## the shaft; shoot fires a projectile with ammunition. Effects: sneak_mult
## (unaware monsters), bleed, crush (armored monsters), stagger, knockback and
## cura (health back to the adventurer for each blow that lands).

static func resolve_player_attack(game: DungeonGame) -> void:
	var player = game.player
	# Each committed swing resolves once, even if another callback arrives.
	if player.resolved_serial == player.attack_serial or player.health <= 0:
		return
	player.resolved_serial = player.attack_serial
	var weapon: Dictionary = player.attack_weapon
	var style: String = str(weapon.get("style", "slash"))
	if style == "shoot":
		_shoot(game, weapon)
		return
	var samples: Array = Hitbox.player_samples(game, weapon)
	var touched: Array = Hitbox.touched(game, samples)
	Vfx.swing_trail(game, samples)
	var head: Vector3 = _head(game, samples)
	if style == "smash":
		_smash_fx(game, head, not touched.is_empty())
	var limit: int = mini(touched.size(), int(weapon.get("targets", 6 if style == "smash" else 1)))
	var notes: Array = []
	# Techniques may strike more than once (Golpe duplo, Sequência de socos).
	for strike in maxi(1, int(weapon.get("hits", 1))):
		for i in limit:
			var direction: Vector3 = player.attack_facing
			if style == "smash":
				var away: Vector3 = touched[i].position - head
				away.y = 0
				if away.length() > 0.05:
					direction = away.normalized()
			var note: String = apply_hit(game, touched[i], weapon, direction)
			if note != "" and not notes.has(note):
				notes.append(note)
	if limit > 0:
		if style != "smash":
			game.sound.play_at("hit", touched[0].global_position, 0.8)
			game.camera_impact(0.045 if float(weapon.get("knockback", 3.0)) <= 3.0 else 0.08)
		game.message(" ".join(notes) if not notes.is_empty() else ("Pancada certeira." if style == "smash" else "Acerto. Preserve o fôlego para recuar."), 1.3)

## Where the head of the weapon was when the blow landed (the sample nearest
## the middle of the swept window), on the ground.
static func _head(game: DungeonGame, samples: Array) -> Vector3:
	if samples.is_empty():
		return game.player.position + game.player.attack_facing * 1.0
	@warning_ignore("integer_division")
	var tip: Vector3 = samples[samples.size() / 2][1]
	return Vector3(tip.x, game.player.position.y, tip.z)

## The heavy head hits the ground: dust, a small shockwave and a shake.
static func _smash_fx(game: DungeonGame, head: Vector3, landed: bool) -> void:
	var ring = Visuals.ring(0.7, Color(0.92, 0.78, 0.52, 0.85), 0.12)
	game.add_child(ring)
	ring.position = head + Vector3(0, 0.07, 0)
	ring.scale = Vector3.ONE * 0.55
	var wave = ring.create_tween()
	wave.tween_property(ring, "scale", Vector3.ONE, 0.12)
	wave.parallel().tween_property(ring.material_override, "albedo_color:a", 0.0, 0.35)
	wave.tween_callback(ring.queue_free)
	Vfx.dust_ring(game, head, 0.6)
	game.camera_impact(0.12)
	game.sound.play_at("hit", head, 0.9 if landed else 0.45)

## Damage and effects of one hit. Returns a short note for the message line.
static func apply_hit(game: DungeonGame, enemy, weapon: Dictionary, direction: Vector3, damage: float = -1.0) -> String:
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

## Releases a projectile and spends one unit of ammunition.
static func _shoot(game: DungeonGame, weapon: Dictionary) -> void:
	var count: int = maxi(1, int(weapon.get("hits", 1)))
	for i in count:
		# Extra shots of a technique fan out a little.
		_shoot_one(game, weapon, deg_to_rad(5.0) * (i - (count - 1) * 0.5))

static func _shoot_one(game: DungeonGame, weapon: Dictionary, spread: float) -> void:
	var player = game.player
	var ammo: String = game.ammo_for(weapon)
	if ammo != "":
		if not game.inventory.remove(ammo, 1):
			game.message("Sem munição.", 1.5)
			return
		weapon = Items.with_ammo(weapon, ammo)
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
