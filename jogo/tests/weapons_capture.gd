extends SceneTree
# Captures of every weapon in hand and of the new attacks, for review.
#   godot --path . --rendering-driver opengl3 -s res://tests/weapons_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/armas")
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

func equip(id: String) -> void:
	if game.inventory.count(id) == 0:
		game.inventory.add(id)
	game.inventory.equip(id)
	game.player.refresh_weapon()

func ready_attack(id: String, facing: Vector3) -> void:
	equip(id)
	var p = game.player
	p.cooldown = 0
	p.attack_timer = 0
	p.attack_wait = 0
	p.hurt_timer = 0
	p.stamina = 100
	p.facing = facing
	p.attack()

func run() -> void:
	await frames(30)
	var p = game.player
	game.ui.hud.visible = false
	for e in game.enemies:
		e.set_physics_process(false)
	var spot: Vector3 = game.layout.to_world(game.layout.spawn + Vector2i(1, 1))
	p.position = spot
	p.set_physics_process(false)
	game.camera_rig.snap()
	game.camera_rig.zoom = 5.5
	game.camera.size = 5.5
	game.inventory.restore({"stacks": {}, "equipped": ""})
	for id in ["sword", "katana", "montante", "adaga", "machado", "maca", "martelo", "spear", "alabarda", "arco", "besta"]:
		equip(id)
		p.facing = Vector3(1, 0, -0.35).normalized()
		p.visual.rotation.y = atan2(p.facing.x, p.facing.z)
		Visuals.play(p.animator, "idle")
		await frames(12)
		await shot("mao-" + id)
		game.inventory.remove(id)
	game.ui.hud.visible = true
	game.camera_rig.zoom = 13.0
	game.camera.size = 13.0
	# Hammer: ring at the moment of impact, two monsters inside.
	var e0 = game.enemies[0]
	var e1 = game.enemies[1]
	for e in [e0, e1]:
		e.visible = true
		e.alive = true
	e0.position = spot + Vector3(2.0, 0, 0.8)
	e1.position = spot + Vector3(2.4, 0, -0.9)
	ready_attack("martelo", Vector3.RIGHT)
	p.set_physics_process(true)
	for i in 60:
		await physics_frame
		if p.resolved_serial == p.attack_serial:
			break
	await shot("uso-martelo")
	await create_timer(1.2).timeout
	# Crossbow bolt in flight through two monsters.
	game.inventory.add("virote", 5)
	e0.position = spot + Vector3(3.5, 0, 0)
	e1.position = spot + Vector3(5.5, 0, 0)
	ready_attack("besta", Vector3.RIGHT)
	for i in 60:
		await physics_frame
		if p.resolved_serial == p.attack_serial:
			break
	await physics_frame
	await physics_frame
	await shot("uso-besta")
	await create_timer(0.8).timeout
	game.ui.open_inventory({})
	game.inventory.add("arco")
	game.inventory.add("flecha", 12)
	game.inventory.add("machado")
	game.ui.refresh_inventory()
	game.ui.select_item("besta")
	await frames(4)
	var row = game.ui.inventory.bag_list.row_for("besta")
	var event := InputEventMouseMotion.new()
	var scale: Vector2 = Vector2(root.get_window().size) / Vector2(1440, 900)
	event.position = row.get_global_rect().get_center() * scale
	event.global_position = event.position
	root.get_viewport().push_input(event)
	await create_timer(0.8).timeout
	await shot("dica-besta")
	quit()
