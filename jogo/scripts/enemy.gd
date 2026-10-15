extends CharacterBody3D
class_name DungeonEnemy
## Monster driven by its type in data/inimigos.json, scaled by the floor level.
## Bosses add a telegraphed area slam every third attack and get furious below
## half health. Monsters far from the player sleep to keep big floors cheap.

const SLEEP_DISTANCE := 26.0

var game
var enemy_id: int
var uid: String = ""
var kind: String = "corrompido"
var level: int = 1
var stats: Dictionary = {}
var home: Vector3
var health: float = 65.0
var maximum_health: float = 65.0
var heavy: bool = false
var boss: bool = false
var enraged: bool = false
var damage_scale: float = 1.0
var speed: float = 2.6
var reach: float = 1.8
var attacks_done: int = 0
var slamming: bool = false
var animator: AnimationPlayer
var visual: Node3D
var telegraph: MeshInstance3D
var slam_ring: MeshInstance3D
var health_label: Label3D
var windup: float = 0.0
var cooldown: float = 0.0
var stagger: float = 0.0
var committed: Vector3 = Vector3.FORWARD
var path: Array[Vector2i] = []
var repath: float = 0
var last_seen: Vector3
var memory: float = 0.0
var impulse: Vector3 = Vector3.ZERO
var attack_recovery: float = 0.0
var step_time: float = 0.0
var aggro: bool = false
var alive: bool = true
var armored: bool = false
var bleed_time: float = 0.0
var bleed_dps: float = 0.0
## Seconds to the next drop of blood shown while bleeding.
var bleed_fx: float = 0.0
## Proficiency path of the weapon that opened the wound (bleeding damage teaches it).
var bleed_path: Array = []
## Ammunition stuck in this monster; it drops with its belongings.
var stuck: Dictionary = {}
## What sneaking near this monster can still teach (Furtividade).
var sneak_budget: float = 0.0

func _ready() -> void:
	stats = EnemyTypes.info(kind)
	heavy = kind == "guardiao"
	boss = stats.get("boss", false)
	armored = stats.get("armored", false)
	var scaling: Dictionary = LabyrinthGenerator.scaling(level)
	damage_scale = scaling["damage"]
	speed = float(stats.get("speed", 2.6))
	reach = float(stats.get("reach", 1.8))
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	home = position
	last_seen = home
	var scale_factor: float = float(stats.get("scale", 1.0))
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = float(stats.get("radius", 0.4))
	capsule.height = maxf(1.5 * scale_factor, capsule.radius * 2.0 + 0.1)
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5 + 0.01
	add_child(shape)
	visual = Visuals.model(stats.get("model", "character-orc"), scale_factor)
	add_child(visual)
	var tint: String = str(stats.get("tint", ""))
	if tint != "":
		Visuals.tint(visual, Color(tint))
	animator = Visuals.animation(visual)
	telegraph = Visuals.attack_arc(reach * 1.03, Color(0.91, 0.39, 0.24, 0.65), 0.95, 0.10)
	add_child(telegraph)
	telegraph.position.y = 0.07
	telegraph.visible = false
	if boss:
		slam_ring = Visuals.ring(float(stats.get("slam_radius", 3.0)), Color(0.95, 0.30, 0.18, 0.75), 0.22)
		add_child(slam_ring)
		slam_ring.position.y = 0.08
		slam_ring.visible = false
	health_label = Label3D.new()
	health_label.position.y = 2.05 * scale_factor
	health_label.font_size = 32
	health_label.pixel_size = 0.007
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.modulate = Color("ecb9a7")
	health_label.no_depth_test = true
	health_label.font = UiStyle.font("semibold")
	health_label.outline_size = 8
	health_label.outline_modulate = Color(0, 0, 0, 0.85)
	add_child(health_label)
	maximum_health = float(stats.get("health", 65.0)) * scaling["health"]
	sneak_budget = float(stats.get("xp", 20)) * (1.0 + 0.25 * (level - 1)) * 0.5
	health = maximum_health

func display_name() -> String:
	return EnemyTypes.display_name(kind)

func _physics_process(delta: float) -> void:
	if not alive or game.player.health <= 0:
		return
	tick_bleed(delta)
	if not alive:
		return
	var player = game.player
	var distance: float = global_position.distance_to(player.global_position)
	if distance > SLEEP_DISTANCE and not aggro:
		visible = false
		return
	visible = distance < 20 and game.clear_line(player.global_position, global_position)
	health_label.visible = not boss and (aggro or health < maximum_health)
	health_label.text = "%s  %d%s" % [display_name(), ceil(health), "  · sangrando" if bleed_time > 0 else ""]
	health_label.modulate = Color("ff8f7a") if bleed_time > 0 else Color("ecb9a7")
	cooldown = maxf(0, cooldown - delta)
	stagger = maxf(0, stagger - delta)
	memory = maxf(0, memory - delta)
	attack_recovery = maxf(0, attack_recovery - delta)
	if stagger > 0:
		velocity = impulse
		velocity.y = -2
		move_and_slide()
		impulse = impulse.move_toward(Vector3.ZERO, 16 * delta)
		return
	if windup > 0:
		windup -= delta
		if slamming:
			slam_ring.visible = true
			slam_ring.scale = Vector3.ONE * (0.92 + 0.08 * sin(windup * 30))
		else:
			telegraph.visible = true
			telegraph.scale = Vector3.ONE * (1.0 + sin(windup * 24) * 0.035)
		if windup <= 0:
			_strike(player)
		return
	var can_see: bool = game.clear_line(global_position, player.global_position)
	var sight: float = float(stats.get("sight", 7.5))
	if not game.is_safe() and distance < sight * player.detection_mult(self) and can_see:
		aggro = true
		last_seen = player.global_position
		memory = 3.0
	elif player.sneaking and not aggro and can_see and distance < sight and not game.is_safe():
		game.on_sneak_near(self, delta)
	if aggro and can_see and not game.is_safe():
		last_seen = player.global_position
		memory = 3.0
	if game.is_safe() or distance > 16:
		aggro = false
	if memory <= 0 and not (boss and aggro and distance < 12):
		aggro = false
	if attack_recovery > 0:
		return
	if aggro and distance < reach and can_see and cooldown <= 0:
		_begin_attack(player)
		return
	var target: Vector3 = last_seen if aggro else home
	var direction := Vector3.ZERO
	if global_position.distance_to(target) > (1.4 if aggro else 0.25):
		repath -= delta
		if repath <= 0:
			path = game.layout.route(global_position, target)
			repath = 0.4
		if path.size() > 1:
			var next = game.layout.to_world(path[1])
			if global_position.distance_to(next) < 0.24:
				path.pop_front()
			direction = (next - global_position).normalized()
		elif can_see and aggro:
			direction = (target - global_position).normalized()
	direction.y = 0
	velocity = direction * speed
	velocity.y = -2
	move_and_slide()
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), minf(1, delta * 10))
	if cooldown < 0.75:
		Visuals.play(animator, "walk" if direction.length() > 0.1 else "guard" if aggro else "idle")
	step_time -= delta
	if direction.length() > 0.1 and step_time <= 0:
		game.sound.play_at("step", global_position, 0.22 if not boss else 0.5)
		step_time = 0.55

func _begin_attack(player) -> void:
	slamming = boss and attacks_done % 3 == 2
	windup = float(stats.get("slam_windup", 1.1)) if slamming else float(stats.get("windup", 0.65))
	if enraged:
		windup *= 0.75
	committed = (player.global_position - global_position).normalized()
	visual.rotation.y = atan2(committed.x, committed.z)
	telegraph.rotation.y = visual.rotation.y
	if animator.has_animation("attack"):
		animator.play("attack", 0.08, animator.get_animation("attack").length / (windup + 0.30))

func _strike(player) -> void:
	telegraph.visible = false
	if slam_ring:
		slam_ring.visible = false
	attack_recovery = 0.30
	attacks_done += 1
	game.sound.play_at("swing", global_position, 0.45 if not boss else 0.9)
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0
	var sees: bool = game.clear_line(global_position, player.global_position)
	if slamming:
		game.camera_impact(0.16)
		if not game.is_safe() and offset.length() < float(stats.get("slam_radius", 3.0)) and sees:
			player.receive_damage(float(stats.get("slam_damage", 30.0)) * damage_scale, offset.normalized(), false)
	elif not game.is_safe() and offset.length() < reach + 0.2 and committed.dot(offset.normalized()) >= cos(0.95) and sees:
		player.receive_damage(float(stats.get("damage", 17.0)) * damage_scale, committed)
	slamming = false
	cooldown = 1.2 if not enraged else 0.85

## hit: optional "stagger" (seconds) and "knockback" (weapon force; 3 is the base).
func receive_damage(amount: float, direction: Vector3 = Vector3.ZERO, hit: Dictionary = {}) -> void:
	if not alive:
		return
	health -= amount
	# Bosses flinch briefly instead of being stun-locked.
	if boss:
		stagger = 0.12 if hit.has("stagger") else 0.06
	else:
		stagger = float(hit.get("stagger", 0.25))
	impulse = direction.normalized() * float(stats.get("knockback", 3.0)) * float(hit.get("knockback", 3.0)) / 3.0
	if animator.has_animation("hit") and not (boss and windup > 0):
		animator.play("hit", 0.04, animator.get_animation("hit").length / maxf(0.25, minf(stagger, 0.6)))
	if not boss:
		windup = 0
		telegraph.visible = false
	aggro = true
	last_seen = game.player.global_position
	memory = 3.0
	if boss and not enraged and health > 0 and health < maximum_health * 0.5:
		enraged = true
		speed *= 1.35
		Visuals.tint(visual, Color(1.35, 0.75, 0.65))
		game.message("%s se enfurece!" % display_name(), 3)
		game.camera_impact(0.12)
	if health <= 0:
		_die()

func apply_bleed(dps: float, time: float, path: Array = []) -> void:
	if not alive:
		return
	bleed_path = path
	bleed_dps = maxf(bleed_dps, dps)
	bleed_time = maxf(bleed_time, time)

func tick_bleed(delta: float) -> void:
	if bleed_time <= 0 or not alive:
		return
	var step: float = minf(delta, bleed_time)
	bleed_time -= step
	var dealt: float = minf(bleed_dps * step, maxf(0.0, health))
	health -= bleed_dps * step
	game.sheet.award_damage(self, dealt, bleed_path)
	bleed_fx -= step
	if bleed_fx <= 0.0:
		bleed_fx = 0.5
		if visible:
			Vfx.burst(game, "gota", Vfx.body_point(self, 0.9) + Vfx.jitter(0.15))
	if bleed_time <= 0:
		bleed_dps = 0
	if health <= 0:
		_die()

func _die() -> void:
	if not alive:
		return
	alive = false
	bleed_time = 0
	collision_layer = 0
	collision_mask = 0
	health_label.visible = false
	telegraph.visible = false
	if slam_ring:
		slam_ring.visible = false
	Visuals.play(animator, "die", false)
	Vfx.burst(game, "fumaca_morte", global_position + Vector3(0, 0.7, 0), float(stats.get("scale", 1.0)))
	game.enemy_defeated(self)
