extends SceneTree
# The hitboxes over the swing, for review: the adventurer (or a monster) frozen
# at the impact of each attack with every capsule of the swept window drawn
# (red = before the impact, yellow = after).
#   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1440x900 -s res://tests/hitbox_capture.gd
var out: String
var game
var marks: Array = []

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/hitbox")
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	run()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT " + name)

func clear_marks() -> void:
	for m in marks:
		m.queue_free()
	marks.clear()

func draw_capsule(cap: Array, color: Color) -> void:
	var a: Vector3 = cap[0]
	var b: Vector3 = cap[1]
	var mesh := CapsuleMesh.new()
	mesh.radius = float(cap[2])
	mesh.height = a.distance_to(b) + 2.0 * float(cap[2])
	mesh.radial_segments = 8
	mesh.rings = 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	game.add_child(node)
	var up: Vector3 = (b - a).normalized()
	var side: Vector3 = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	node.global_transform = Transform3D(Basis(side, up, side.cross(up)), (a + b) * 0.5)
	marks.append(node)

func show_samples(samples: Array, impact_index: int) -> void:
	for i in samples.size():
		var c: Color = Color(1, 0.2, 0.1, 0.35) if i < impact_index else Color(1, 0.9, 0.2, 0.35)
		draw_capsule(samples[i], c)

## A floor cell with floor all around it (3 cells each way), away from the merchant.
func open_cell() -> Vector2i:
	for c in game.layout.floors:
		var ok: bool = (game.merchant == null or game.layout.to_world(c).distance_to(game.merchant.position) > 5.0) and not game.layout.is_safe(game.layout.to_world(c))
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				ok = ok and game.layout.is_floor(c + Vector2i(dx, dy))
		if ok:
			return c
	return Vector2i(5, 12)

func run() -> void:
	await frames(30)
	for e in game.enemies:
		e.set_physics_process(false)
		e.visible = false
	if game.choosing_character:
		game.ui.creation_panel.confirmed.emit(game.ui.creation_panel.choice())
	await frames(5)
	game.ui.visible = false if "visible" in game.ui else true
	Vfx.trail_time = 4.0
	var p = game.player
	p.set_physics_process(false)
	p.position = game.layout.to_world(open_cell())
	p.facing = Vector3.RIGHT
	p.attack_facing = Vector3.RIGHT
	p.visual.rotation.y = atan2(1.0, 0.0)
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.fov = 50
	cam.current = true
	var sk: Skeleton3D = Visuals.skeleton(p.visual)
	p.animator.active = false
	var list: Array = ["", "sword", "katana", "adaga", "florete", "machado", "maca", "montante", "martelo", "spear", "alabarda", "foice"]
	for id in list:
		if id != "":
			game.inventory.add(id)
		game.inventory.equipped = id
		p.refresh_weapon()
		p.attack_item = id
		var w: Dictionary = game.sheet.weapon_stats(id)
		var name: String = p.attack_animation(w)
		var span: Vector2 = Hitbox.window(DungeonPlayer.MODEL, p.animator, name, float(w.get("impacto", 0.39)))
		var impact: float = Animacoes.impact(DungeonPlayer.MODEL, name, float(w.get("impacto", 0.39))) * p.animator.get_animation(name).length
		var samples: Array = Hitbox.player_samples(game, w)
		clear_marks()
		show_samples(samples, roundi((impact - span.x) / maxf(0.001, span.y - span.x) * Hitbox.STEPS))
		Hitbox.pose_at(p.animator, sk, name, impact)
		p._process(0.0)
		for m in marks:
			m.visible = false
		cam.global_position = p.global_position + Vector3(0.6, 1.6, 4.2)
		cam.look_at(p.global_position + Vector3(0.7, 0.9, 0))
		await shot("%s-limpo" % [id if id != "" else "punhos"])
		if id == "sword":
			Vfx.swing_trail(game, samples)
			await shot("sword-rastro")
		draw_capsule(Hitbox.player_weapon(p, id, w, Vector3.ZERO), Color(0.2, 1.0, 0.3, 0.45))
		for m in marks:
			m.visible = true
		for view in [["lado", Vector3(0.6, 1.6, 4.2)], ["cima", Vector3(-0.4, 4.6, 1.2)]]:
			cam.global_position = p.global_position + view[1]
			cam.look_at(p.global_position + Vector3(0.7, 0.9, 0))
			await shot("%s-%s" % [id if id != "" else "punhos", view[0]])
	clear_marks()
	# In play: the blade's trail right after the blow lands.
	p.animator.active = true
	cam.global_position = p.global_position + Vector3(0.6, 1.6, 4.2)
	cam.look_at(p.global_position + Vector3(0.7, 0.9, 0))
	game.inventory.equipped = "sword"
	p.refresh_weapon()
	var foe = game.enemies[0]
	foe.visible = true
	foe.position = p.position + Vector3(1.5, 0, 0.2)
	foe.visual.rotation.y = atan2(-1.0, 0.0)
	game.camera_rig.snap()
	await frames(20)
	p.cooldown = 0
	p.stamina = 100
	p.facing = Vector3.RIGHT
	p.visual.rotation.y = atan2(1.0, 0.0)
	p.attack()
	await create_timer(float(p.attack_weapon.get("windup", 0.22))).timeout
	game.resolve_player_attack()
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/jogo-rastro-espada.png")
	print("SHOT jogo-rastro-espada")
	# A monster throwing itself into the claw.
	await create_timer(1.0).timeout
	p.health = 100
	foe.health = foe.maximum_health
	foe.position = p.position + Vector3(1.7, 0, 0)
	foe.aggro = true
	foe.memory = 3.0
	foe.cooldown = 0
	foe.attack_recovery = 0
	foe.set_physics_process(true)
	for i in 120:
		await process_frame
		if foe.windup > 0 and foe.windup < 0.12:
			break
	foe.set_physics_process(false)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/jogo-bote-monstro.png")
	print("SHOT jogo-bote-monstro")
	foe.visible = false
	p.animator.active = false
	p.visible = false
	for kind in ["corrompido", "espreitador", "brutamontes", "guardiao", "chefe"]:
		var e := DungeonEnemy.new()
		e.game = game
		e.kind = kind
		e.position = p.position
		game.add_child(e)
		await frames(2)
		e.set_physics_process(false)
		e.committed = Vector3.RIGHT
		e.visual.rotation.y = atan2(1.0, 0.0)
		e.animator.active = false
		var esk: Skeleton3D = Visuals.skeleton(e.visual)
		var samples: Array = Hitbox.monster_samples(e)
		var model: String = str(e.stats.get("model", ""))
		var impact: float = Animacoes.impact(model, "attack", 0.5) * e.animator.get_animation("attack").length
		clear_marks()
		show_samples(samples, roundi(Hitbox.BEFORE / (Hitbox.BEFORE + Hitbox.AFTER) * Hitbox.STEPS))
		draw_capsule(Hitbox.player_body(p) if false else [e.global_position + Vector3(e.reach + 0.2, 0.35, 0), e.global_position + Vector3(e.reach + 0.2, 1.4, 0), 0.35], Color(0.3, 0.6, 1.0, 0.25))
		Hitbox.pose_at(e.animator, esk, "attack", impact)
		e._lean(1.0)
		var size: float = float(e.stats.get("scale", 1.0))
		cam.global_position = e.global_position + Vector3(0.9, 1.7, 4.6) * maxf(1.0, size * 0.8)
		cam.look_at(e.global_position + Vector3(0.9, 1.0 * size, 0))
		await shot("monstro-%s" % kind)
		e.queue_free()
	DirAccess.remove_absolute(game.save_path)
	quit()
