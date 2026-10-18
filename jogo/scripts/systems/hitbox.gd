extends RefCounted
class_name Hitbox
## Hits by touch (16/10/2026): a blow lands on whoever the weapon touches.
## The weapon, the fist or the claw is a capsule that follows the attack
## animation (grip to tip); bodies are capsules standing on the ground. When the
## blow lands, the swing is replayed from a little before the impact moment to a
## little after (BEFORE and AFTER, fractions of the animation) and everything the
## capsule went through is hit, in the order it was touched. The wind-up behind
## the back does not count: only positions with the tip in front of the body.
## Deterministic: no physics timing, the same swing always hits the same way.

const STEPS := 12
## Part of the animation before the impact that counts (the downswing) and after it.
const BEFORE := 0.14
const AFTER := 0.12
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.75
## Thickness of the weapon capsule by style: blade, point, heavy head, fist.
const RADIUS := {"slash": 0.12, "thrust": 0.10, "smash": 0.26, "punhos": 0.13}
## Claws reach this far past the hand (times the monster's size), this thick.
const CLAW := 0.32
const CLAW_RADIUS := 0.16
## Positions of the blade around the body in a spinning blow.
const SPIN := 16

static var _extent: Dictionary = {}

## Closest distance between segments p1-q1 and p2-q2 (Ericson, Real-Time Collision Detection 5.1.9).
static func segment_distance(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var d1: Vector3 = q1 - p1
	var d2: Vector3 = q2 - p2
	var r: Vector3 = p1 - p2
	var a: float = d1.dot(d1)
	var e: float = d2.dot(d2)
	var f: float = d2.dot(r)
	var s: float = 0.0
	var t: float = 0.0
	if a <= 1e-9 and e <= 1e-9:
		return p1.distance_to(p2)
	if a <= 1e-9:
		t = clampf(f / e, 0.0, 1.0)
	else:
		var c: float = d1.dot(r)
		if e <= 1e-9:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b: float = d1.dot(d2)
			var denom: float = a * e - b * b
			s = clampf((b * f - c * e) / denom, 0.0, 1.0) if denom > 1e-9 else 0.0
			t = (b * s + f) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)
	return (p1 + d1 * s).distance_to(p2 + d2 * t)

## A capsule [a, b, radius] touches another.
static func touches(capsule: Array, body: Array) -> bool:
	return segment_distance(capsule[0], capsule[1], body[0], body[1]) <= float(capsule[2]) + float(body[2])

## Body of a monster: the same capsule as its collision shape.
static func enemy_body(enemy) -> Array:
	var r: float = float(enemy.stats.get("radius", 0.4))
	var h: float = maxf(1.5 * float(enemy.stats.get("scale", 1.0)), r * 2.0 + 0.1)
	var at: Vector3 = enemy.global_position
	return [at + Vector3(0, r, 0), at + Vector3(0, h - r, 0), r]

static func player_body(player) -> Array:
	var at: Vector3 = player.global_position
	return [at + Vector3(0, PLAYER_RADIUS, 0), at + Vector3(0, PLAYER_HEIGHT - PLAYER_RADIUS, 0), PLAYER_RADIUS]

## Lowest and highest point of a weapon model along its blade (+Y), in metres
## from the grip, before the scale it gets in the hand: measured once from the vertices.
static func extent(id: String) -> Vector2:
	if _extent.has(id):
		return _extent[id]
	var out := Vector2(0.0, 0.9)
	if Items.DATA.has(id):
		var model: Node3D = Visuals.item_model(id)
		var lo: float = INF
		var hi: float = -INF
		for m in model.find_children("*", "MeshInstance3D", true, false):
			if m.mesh == null:
				continue
			var t := Transform3D.IDENTITY
			var walk: Node = m
			while walk != null and walk != model:
				t = walk.transform * t
				walk = walk.get_parent()
			for s in m.mesh.get_surface_count():
				for v in m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
					var y: float = (t * v).y
					lo = minf(lo, y)
					hi = maxf(hi, y)
		model.free()
		if hi > lo:
			out = Vector2(lo, hi)
	_extent[id] = out
	return out

## Puts the skeleton in the pose of animation `name` at `t` seconds, straight
## from its tracks (bones it does not key go to rest). Independent of what the
## AnimationPlayer is playing or blending, so a blow is the same every time.
static func pose_at(anim: AnimationPlayer, sk: Skeleton3D, name: String, t: float) -> void:
	var a: Animation = anim.get_animation(name)
	sk.reset_bone_poses()
	for i in a.get_track_count():
		var kind: int = a.track_get_type(i)
		if kind != Animation.TYPE_ROTATION_3D and kind != Animation.TYPE_POSITION_3D and kind != Animation.TYPE_SCALE_3D:
			continue
		var bone: int = sk.find_bone(a.track_get_path(i).get_concatenated_subnames())
		if bone < 0:
			continue
		if kind == Animation.TYPE_ROTATION_3D:
			sk.set_bone_pose_rotation(bone, a.rotation_track_interpolate(i, t))
		elif kind == Animation.TYPE_POSITION_3D:
			sk.set_bone_pose_position(bone, a.position_track_interpolate(i, t))
		else:
			sk.set_bone_pose_scale(bone, a.scale_track_interpolate(i, t))
	sk.force_update_all_bone_transforms()

static func save_pose(sk: Skeleton3D) -> Array:
	var out: Array = []
	for b in sk.get_bone_count():
		out.append([sk.get_bone_pose_position(b), sk.get_bone_pose_rotation(b), sk.get_bone_pose_scale(b)])
	return out

static func load_pose(sk: Skeleton3D, pose: Array) -> void:
	for b in pose.size():
		sk.set_bone_pose_position(b, pose[b][0])
		sk.set_bone_pose_rotation(b, pose[b][1])
		sk.set_bone_pose_scale(b, pose[b][2])
	sk.force_update_all_bone_transforms()

## Skeleton space to world as if the body faced `facing` (the committed line of
## the blow), whatever angle the model has turned to so far.
static func facing_view(body: Node3D, visual: Node3D, sk: Skeleton3D, facing: Vector3) -> Transform3D:
	var flat := Vector3(facing.x, 0, facing.z)
	if flat.length() < 0.01:
		return sk.global_transform
	var turned := Transform3D(Basis(Vector3.UP, atan2(flat.x, flat.z)) * Basis.from_scale(visual.scale), body.global_position + Vector3(0, visual.position.y, 0))
	return turned * visual.global_transform.affine_inverse() * sk.global_transform

static func bone_at(sk: Skeleton3D, view: Transform3D, bone: String) -> Transform3D:
	return view * sk.get_bone_global_pose(sk.find_bone(bone))

## The player's weapon (or fist) as a capsule [grip end, tip, radius] at the
## current pose. "extra" = [more reach, more thickness] from habilidades.
static func player_weapon(player, item: String, weapon: Dictionary, extra: Vector3, sk: Skeleton3D = null, view = null) -> Array:
	var style: String = str(weapon.get("style", "slash"))
	if sk == null:
		sk = Visuals.skeleton(player.visual)
	if sk == null or sk.find_bone("mixamorig_RightHand") < 0:
		var chest: Vector3 = player.global_position + Vector3(0, 1.1, 0)
		return [chest, chest + player.attack_facing.normalized() * (float(weapon.get("range", 1.5)) + extra.x), RADIUS.get(style, 0.12) + extra.y]
	var to_world: Transform3D = view if view != null else sk.global_transform
	if item == "":
		var fore: Vector3 = bone_at(sk, to_world, "mixamorig_RightForeArm").origin
		var hand: Vector3 = bone_at(sk, to_world, "mixamorig_RightHand").origin
		var along: Vector3 = (hand - fore).normalized()
		return [fore.lerp(hand, 0.5), hand + along * (0.12 + extra.x), RADIUS["punhos"] + extra.y]
	var data: Dictionary = Items.info(item)
	var entry: Array = DungeonPlayer.MOUNTS["hand-left" if str(data.get("mao", "direita")) == "esquerda" else "hand-right"]
	var held: Transform3D = bone_at(sk, to_world, entry[0]) * Transform3D(Basis(entry[1]), entry[2]) * Transform3D(Basis.from_euler(player.rest_rotation(data) * PI / 180.0), Vector3(0, 0.035, 0))
	var axis: Vector3 = held.basis.y.normalized()
	if data.get("alinhar_ao_golpe", false):
		# Poles are held along the committed attack line while the blow lasts.
		axis = player.attack_facing.normalized()
	var size: Vector2 = extent(item) * player.hand_scale(item, data).y
	# From the hand to the tip: the pommel or the butt of a pole behind the hand does not strike.
	return [held.origin + axis * maxf(size.x, 0.0), held.origin + axis * (size.y + extra.x), RADIUS.get(style, 0.12) + extra.y]

## What habilidades, objetos and proficiency perks add to the bare weapon:
## x = reach (range), y = thickness (a bigger area, a wider thrust, a wider arc),
## z = longer stretch of the swing that counts, before and after (a wider arc).
static func extras(base: Dictionary, weapon: Dictionary) -> Vector3:
	var more_reach: float = maxf(0.0, float(weapon.get("range", 0.0)) - float(base.get("range", 0.0)))
	var arc: float = maxf(0.0, float(weapon.get("angle", 0.0)) - float(base.get("angle", 0.0)))
	var thick: float = arc / 500.0
	thick += maxf(0.0, float(weapon.get("area_radius", 0.0)) - float(base.get("area_radius", 0.0)))
	thick += maxf(0.0, float(weapon.get("width", 0.0)) - float(base.get("width", 0.0)))
	return Vector3(more_reach, thick, minf(0.2, arc / 300.0))

## The window of an animation that counts for the blow, in seconds.
static func window(model: String, anim: AnimationPlayer, name: String, fallback: float, wider: float = 0.0) -> Vector2:
	var length: float = anim.get_animation(name).length
	var impact: float = Animacoes.impact(model, name, fallback) * length
	return Vector2(maxf(0.0, impact - (BEFORE + wider) * length), minf(length, impact + (AFTER + wider) * length))

## The tip is ahead of the body (along `facing`, from `origin`).
static func ahead(cap: Array, origin: Vector3, facing: Vector3) -> bool:
	var flat := Vector3(facing.x, 0, facing.z).normalized()
	return (cap[1] - origin).dot(flat) > 0.05

## The capsules the player's current blow goes through, from a little before
## its impact to a little after. A spinning blow (arc of 150° or more, Corte
## giratório) also turns them all around the player.
static func player_samples(game: DungeonGame, weapon: Dictionary) -> Array:
	var player = game.player
	var item: String = str(player.attack_item)
	var extra: Vector3 = extras(CharacterSheet.base_stats(item), weapon)
	var anim: AnimationPlayer = player.animator
	var sk: Skeleton3D = Visuals.skeleton(player.visual)
	var name: String = player.attack_animation(weapon)
	var samples: Array = []
	if anim != null and sk != null and anim.has_animation(name):
		var span: Vector2 = window(DungeonPlayer.MODEL, anim, name, float(weapon.get("impacto", 0.39)), extra.z)
		var view: Transform3D = facing_view(player, player.visual, sk, player.attack_facing)
		var keep: Array = save_pose(sk)
		for i in STEPS + 1:
			pose_at(anim, sk, name, lerpf(span.x, span.y, float(i) / STEPS))
			var cap: Array = player_weapon(player, item, weapon, extra, sk, view)
			if ahead(cap, player.global_position, player.attack_facing):
				samples.append(cap)
		load_pose(sk, keep)
	else:
		samples.append(player_weapon(player, item, weapon, extra))
	if float(weapon.get("angle", 0.0)) >= 150.0 and not samples.is_empty():
		# The body turns all the way round with the blade at its farthest.
		var center: Vector3 = player.global_position
		var far: Array = samples[0]
		for cap in samples:
			if Vector2(cap[1].x - center.x, cap[1].z - center.z).length() > Vector2(far[1].x - center.x, far[1].z - center.z).length():
				far = cap
		for k in range(1, SPIN):
			var yaw: float = TAU * float(k) / SPIN
			samples.append([center + (far[0] - center).rotated(Vector3.UP, yaw), center + (far[1] - center).rotated(Vector3.UP, yaw), far[2]])
	return samples

## The monsters a set of capsules touches, in the order they were touched
## (walls in between stop the blow).
static func touched(game: DungeonGame, samples: Array) -> Array:
	var player = game.player
	var order: Array = []
	for enemy in game.enemies:
		if not enemy.alive:
			continue
		var body: Array = enemy_body(enemy)
		for i in samples.size():
			if touches(samples[i], body) and game.clear_line(player.position, enemy.position):
				order.append([i, enemy])
				break
	order.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1].position.distance_squared_to(player.position) < b[1].position.distance_squared_to(player.position)))
	return order.map(func(e): return e[1])

## The claw of a monster's attack as a capsule: forearm to past the hand.
static func monster_claw(enemy, sk: Skeleton3D, view: Transform3D) -> Array:
	var size: float = float(enemy.stats.get("scale", 1.0))
	var fore: Vector3 = bone_at(sk, view, "mixamorig_RightForeArm").origin
	var hand: Vector3 = bone_at(sk, view, "mixamorig_RightHand").origin
	var along: Vector3 = (hand - fore).normalized()
	return [fore, hand + along * CLAW * size, CLAW_RADIUS * size]

## The capsules a monster's attack goes through around its impact moment, with
## the claw moved forward by the lunge (the monster throws itself "lunge" metres
## into the blow; the model leans the same, see DungeonEnemy._lean).
static func monster_samples(enemy) -> Array:
	var anim: AnimationPlayer = enemy.animator
	var sk: Skeleton3D = Visuals.skeleton(enemy.visual) if enemy.visual else null
	var lunge: float = float(enemy.stats.get("lunge", 0.0))
	var size: float = float(enemy.stats.get("scale", 1.0))
	if anim == null or sk == null or not anim.has_animation("attack") or sk.find_bone("mixamorig_RightHand") < 0:
		var chest: Vector3 = enemy.global_position + Vector3(0, 1.1 * size, 0)
		return [[chest, chest + enemy.committed * enemy.reach, CLAW_RADIUS * size]]
	var model: String = str(enemy.stats.get("model", ""))
	var span: Vector2 = window(model, anim, "attack", 0.5)
	var view: Transform3D = facing_view(enemy, enemy.visual, sk, enemy.committed)
	var keep: Array = save_pose(sk)
	var samples: Array = []
	for i in STEPS + 1:
		var t: float = lerpf(span.x, span.y, float(i) / STEPS)
		pose_at(anim, sk, "attack", t)
		var forward: Vector3 = Vector3(enemy.committed.x, 0, enemy.committed.z).normalized() * lunge
		var claw: Array = monster_claw(enemy, sk, view)
		var cap: Array = [claw[0] + forward, claw[1] + forward, claw[2]]
		if ahead(cap, enemy.global_position, enemy.committed):
			samples.append(cap)
	load_pose(sk, keep)
	return samples

## A monster's attack reaches the player.
static func monster_hits(game: DungeonGame, enemy) -> bool:
	var body: Array = player_body(game.player)
	for cap in monster_samples(enemy):
		if touches(cap, body):
			return true
	return false

## How far the bare weapon reaches from the adventurer's centre over its blow
## (tip plus thickness), in metres: what the item shows as "Alcance".
static func reach(game: DungeonGame, item: String) -> float:
	var player = game.player
	var keep_item: String = player.attack_item
	var keep_facing: Vector3 = player.attack_facing
	player.attack_item = item
	player.attack_facing = Vector3.FORWARD
	var far: float = 0.0
	for cap in player_samples(game, CharacterSheet.base_stats(item)):
		for pt in [cap[0], cap[1]]:
			var off: Vector3 = pt - player.global_position
			far = maxf(far, Vector2(off.x, off.z).length() + float(cap[2]))
	player.attack_item = keep_item
	player.attack_facing = keep_facing
	return far
