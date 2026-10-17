extends SceneTree
# Every animation frame by frame, for review: the adventurer with the weapon of
# each attack, locomotion, dodge, damage and death; each monster; the merchant.
# Saves one picture per frame and view in work/auditoria/<anim>/; compose them
# with tools/auditoria_folhas.py.
#   xvfb-run godot --path . --rendering-driver opengl3 --resolution 960x720 -s res://tests/auditoria_capture.gd [-- names...]
var out: String
var game
var cam: Camera3D
var only: Array = []
const FRAMES := 8

## [name, animation, item in hand]; "" = the attack animation of that item.
const ADVENTURER := [
	["idle", "idle", "sword"], ["walk", "walk", "sword"], ["run", "run", "sword"], ["guard", "guard", "sword"],
	["furtivo", "furtivo", "sword"], ["furtivo_andar", "furtivo_andar", "sword"], ["dodge", "dodge", "sword"],
	["hit", "hit", "sword"], ["die", "die", "sword"], ["bloqueio", "bloqueio", "sword"],
	["soco", "", ""], ["adaga", "", "adaga"], ["florete", "", "florete"],
	["espada", "", "sword"], ["espada_larga", "", "espada_larga"], ["sabre", "", "katana"],
	["machado", "", "machado"], ["picareta", "", "picareta"], ["maca", "", "maca"],
	["estrela", "", "estrela"], ["montante", "", "montante"], ["foice", "", "foice"],
	["machado_duplo", "", "machado_duplo"], ["marreta", "", "martelo"], ["malho", "", "malho"],
	["lanca", "", "spear"], ["tridente", "", "tridente"], ["alabarda", "", "alabarda"],
	["arco", "", "arco"], ["besta", "", "besta"], ["funda", "", "funda"],
]
const MONSTERS := ["corrompido", "espreitador", "brutamontes", "guardiao", "chefe"]
const MONSTER_ANIMS := ["idle", "walk", "run", "guard", "attack", "hit", "die", "pancada"]

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/auditoria")
	DirAccess.make_dir_recursive_absolute(out)
	only = OS.get_cmdline_user_args()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	run()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(path: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(path)

func open_cell() -> Vector2i:
	for c in game.layout.floors:
		var ok: bool = (game.merchant == null or game.layout.to_world(c).distance_to(game.merchant.position) > 6.0) and not game.layout.is_safe(game.layout.to_world(c))
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				ok = ok and game.layout.is_floor(c + Vector2i(dx, dy))
		if ok:
			return c
	return Vector2i(5, 12)

## Two views: from the character's right side and from the front-left.
func views(center: Vector3, size: float) -> Array:
	return [["lado", center + Vector3(0.0, 1.0, 4.4) * size, center + Vector3(0.4, 0.95, 0) * size],
		["frente", center + Vector3(3.2, 1.3, -2.6) * size, center + Vector3(0.3, 0.9, 0) * size]]

func film(body: Node3D, visual: Node3D, anim: AnimationPlayer, name: String, label: String, size: float, after: Callable = Callable()) -> void:
	if not anim.has_animation(name):
		print("SKIP " + label)
		return
	var sk: Skeleton3D = Visuals.skeleton(visual)
	var length: float = anim.get_animation(name).length
	var dir: String = out + "/" + label
	DirAccess.make_dir_recursive_absolute(dir)
	for i in FRAMES:
		var t: float = length * float(i) / float(FRAMES - 1)
		Hitbox.pose_at(anim, sk, name, t)
		if after.is_valid():
			after.call()
		for v in views(body.global_position, size):
			cam.global_position = v[1]
			cam.look_at(v[2])
			await shot("%s/%s_%d.png" % [dir, v[0], i])
	print("FILM %s %.2fs" % [label, length])

func run() -> void:
	await frames(30)
	for e in game.enemies:
		e.set_physics_process(false)
		e.visible = false
	if game.choosing_character:
		game.ui.creation_panel.confirmed.emit(game.ui.creation_panel.choice())
	await frames(5)
	game.set_psx(false)
	game.ui.visible = false
	if game.merchant:
		game.merchant.visible = false
	cam = Camera3D.new()
	game.add_child(cam)
	cam.fov = 45
	cam.current = true
	var p = game.player
	p.set_physics_process(false)
	p.position = game.layout.to_world(open_cell())
	p.facing = Vector3.RIGHT
	p.attack_facing = Vector3.RIGHT
	p.visual.rotation.y = atan2(1.0, 0.0)
	p.animator.active = false
	for entry in ADVENTURER:
		if not only.is_empty() and not entry[0] in only:
			continue
		var id: String = entry[2]
		if id != "" and game.inventory.count(id) == 0:
			game.inventory.add(id)
		game.inventory.equipped = id
		p.refresh_weapon()
		p.attack_timer = 1.0
		p.attack_weapon = game.sheet.weapon_stats(id)
		p.attack_facing = Vector3.RIGHT
		await frames(2)
		var anim_name: String = entry[1] if entry[1] != "" else p.attack_animation(p.attack_weapon)
		await film(p, p.visual, p.animator, anim_name, "aventureiro-" + entry[0], 1.0, func(): p._process(0.0))
	p.visible = false
	for kind in MONSTERS:
		var e := DungeonEnemy.new()
		e.game = game
		e.kind = kind
		e.position = p.position
		game.add_child(e)
		await frames(2)
		e.set_physics_process(false)
		e.telegraph.visible = false
		e.health_label.visible = false
		e.visual.rotation.y = atan2(1.0, 0.0)
		e.animator.active = false
		var size: float = maxf(1.0, float(e.stats.get("scale", 1.0)) * 0.85)
		for a in MONSTER_ANIMS:
			if not only.is_empty() and not ("%s-%s" % [kind, a]) in only and not kind in only:
				continue
			await film(e, e.visual, e.animator, a, "%s-%s" % [kind, a], size)
		e.queue_free()
	if game.merchant and (only.is_empty() or "mercador" in only):
		var m: Node3D = game.merchant
		m.visible = true
		m.position = p.position
		var mv: Node3D = m.get_child(0) if m.get_child_count() > 0 else m
		var manim: AnimationPlayer = Visuals.animation(m)
		if manim:
			manim.active = false
			for a in ["idle", "falar"]:
				await film(m, Visuals.skeleton(m).get_parent() as Node3D if Visuals.skeleton(m) else mv, manim, a, "mercador-" + a, 1.0)
	DirAccess.remove_absolute(game.save_path)
	quit()
