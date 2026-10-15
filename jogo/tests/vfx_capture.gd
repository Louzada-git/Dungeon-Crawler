extends SceneTree
# Effects (Brackeys VFX, PSX-sized) for review: torches, campfire, blood, strong
# blow, sparks, dust and death smoke.
#   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1440x900 -s res://tests/vfx_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/efeitos")
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	run()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT " + name)

func place(at: Vector3) -> void:
	game.player.position = at
	game.camera_rig.snap()

func foe_at(i: int, at: Vector3):
	var foe = game.enemies[i]
	foe.set_physics_process(false)
	foe.position = at
	foe.visible = true
	return foe

func run() -> void:
	await frames(30)
	var p = game.player
	for e in game.enemies:
		e.set_physics_process(false)
	game.camera_rig.zoom = 11.0
	# 1. Torches along the walls of a room.
	var torch = game.get_tree().get_nodes_in_group("chamas")
	var lit: Vector3 = game.layout.to_world(game.layout.rooms[1]["rect"].get_center())
	for f in torch:
		if f.get_parent() == game.world_root:
			lit = f.global_position - Vector3(0, 0.9, 0) + Vector3(1.2, 0, 1.2)
			break
	place(Vector3(lit.x, 0, lit.z))
	await frames(40)
	await shot("01-tochas")
	# 2. Campfire in the shelter.
	place(game.camp_position + Vector3(-0.9, 0, -0.9))
	await frames(40)
	await shot("02-fogueira")
	# 3. Blood and the flash of a hit.
	var room: Rect2i = game.layout.rooms[1]["rect"]
	place(game.layout.to_world(room.get_center()))
	await frames(20)
	var foe = foe_at(0, p.position + Vector3(1.2, 0, 0.3))
	foe.aggro = true
	Combat.apply_hit(game, foe, {"damage": 1.0}, Vector3(1, 0, 0))
	await create_timer(0.12).timeout
	await shot("03-sangue")
	await create_timer(1.2).timeout
	# 4. Strong blow (sneak attack with a mace).
	foe.aggro = false
	foe.health = foe.maximum_health
	Combat.apply_hit(game, foe, {"damage": 1.0, "stagger": 1.5, "knockback": 6.0, "crush": 1.5}, Vector3(1, 0, 0))
	await create_timer(0.14).timeout
	await shot("04-golpe-forte")
	await create_timer(1.2).timeout
	# 5. Sparks on the guard and dust of a dodge.
	Vfx.burst(game, "faisca", Vfx.body_point(p, 1.15) + Vector3(0.35, 0, 0.1))
	p.test_direction = Vector2(-1, 0)
	p.stamina = p.max_stamina
	p.dodge()
	await create_timer(0.1).timeout
	await shot("05-faisca-e-poeira")
	p.test_direction = Vector2.ZERO
	await create_timer(1.2).timeout
	# 6. A blow on the ground: dust all around.
	place(game.layout.to_world(room.get_center()))
	await frames(10)
	Vfx.dust_ring(game, p.position + Vector3(1.3, 0, 0), 1.6)
	await create_timer(0.18).timeout
	await shot("06-pancada")
	await create_timer(1.2).timeout
	# 7. Death smoke and a bleeding monster.
	var other = foe_at(1 if game.enemies.size() > 1 else 0, p.position + Vector3(-1.4, 0, 0.6))
	other.alive = true
	other.apply_bleed(3.0, 4.0)
	foe.health = 1.0
	foe.receive_damage(5.0, Vector3(1, 0, 0))
	await create_timer(0.35).timeout
	other.tick_bleed(0.6)
	await create_timer(0.1).timeout
	await shot("07-morte-e-sangramento")
	# 8. The same hit with the PSX filter off, for comparison.
	game.set_psx(false)
	foe_at(2 if game.enemies.size() > 2 else 0, p.position + Vector3(1.2, 0, 0.3)).alive = true
	Combat.apply_hit(game, game.enemies[2 if game.enemies.size() > 2 else 0], {"damage": 1.0}, Vector3(1, 0, 0))
	await create_timer(0.12).timeout
	await shot("08-sem-filtro")
	game.set_psx(true)
	DirAccess.remove_absolute(game.settings_path)
	quit()
