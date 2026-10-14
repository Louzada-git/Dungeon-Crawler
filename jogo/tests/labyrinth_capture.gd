extends SceneTree
# Captures of the generated labyrinth for review.
#   godot --path . --rendering-driver opengl3 -s res://tests/labyrinth_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/labirinto")
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

func go(cell: Vector2i) -> void:
	game.player.position = game.layout.to_world(cell)
	game.player.reset_transients()
	game.camera_rig.snap()
	game.last_discover = Vector2i(-99, -99)
	game.discover()

func room_of(kind: String) -> Dictionary:
	for r in game.layout.world["rooms"]:
		if r["type"] == kind:
			return r
	return {}

func center(room: Dictionary) -> Vector2i:
	var r: Rect2i = DungeonLayout.rect(room["rect"])
	return r.get_center()

func run() -> void:
	await frames(30)
	await shot("01-abrigo-gerado")
	# Walk the route to the boss so the map has something to show.
	var boss_room: Dictionary = room_of("chefe")
	var route: Array = game.layout.route(game.player.position, game.layout.to_world(center(boss_room)))
	for i in range(0, route.size(), 2):
		go(route[i])
	# A combat room with monsters awake.
	var fight: Dictionary = room_of("combate")
	go(center(fight) + Vector2i(-2, 0))
	for e in game.enemies:
		if DungeonLayout.rect(fight["rect"]).has_point(game.layout.to_cell(e.position)):
			e.aggro = true
			e.last_seen = game.player.position
	await create_timer(1.2).timeout
	await shot("02-sala-de-combate")
	# Boss fight, slam telegraph visible.
	var b = game.boss()
	go(game.layout.to_cell(b.position) + Vector2i(-2, 1))
	for e in game.enemies:
		if e != b:
			e.set_physics_process(false)
	b.aggro = true
	b.attacks_done = 2
	b.cooldown = 0
	b._begin_attack(game.player)
	await create_timer(0.5).timeout
	game.player.invulnerable = 5
	await shot("03-chefe-golpe-em-area")
	b.receive_damage(b.maximum_health * 0.6, Vector3.RIGHT)
	await create_timer(0.4).timeout
	await shot("04-chefe-furioso")
	game.ui.toggle_map()
	await frames(4)
	await shot("05-mapa-gerado")
	game.ui.close_all()
	b.receive_damage(9999, Vector3.RIGHT)
	await frames(10)
	var down = game.stairs_down_cell()
	go(game._free_neighbour(down))
	await frames(10)
	await shot("06-descida-aberta")
	game.interact()
	await frames(20)
	await shot("07-segundo-andar")
	game.player.invulnerable = 0
	game.player.receive_damage(999, Vector3.RIGHT)
	await create_timer(0.6).timeout
	await shot("08-morte")
	for path in [game.save_path, game.knowledge_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	quit()
