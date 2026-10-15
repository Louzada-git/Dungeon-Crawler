extends SceneTree
# Third-person camera, for review: shelter, a room with a monster, a corridor,
# the same spot in isometric for comparison.
#   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1440x900 -s res://tests/terceira_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/terceira")
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

func run() -> void:
	await frames(30)
	for e in game.enemies:
		e.set_physics_process(false)
	if game.choosing_character:
		game.ui.creation_panel.confirmed.emit(game.ui.creation_panel.choice())
	await frames(5)
	var p = game.player
	var rig: GameCamera = game.camera_rig
	game.set_camera_mode(GameCamera.THIRD, false)
	# 1. Shelter, looking at the campfire.
	p.position = game.camp_position + Vector3(2.2, 0, 2.2)
	rig.look_along(game.camp_position - p.position)
	rig.snap()
	p.facing = rig.forward()
	await frames(30)
	await shot("01-abrigo")
	# 2. A room with a monster in front.
	var room: Rect2i = game.layout.rooms[1]["rect"]
	p.position = game.layout.to_world(room.get_center())
	var foe = game.enemies[0]
	foe.position = p.position + Vector3(-1.6, 0, -2.4)
	foe.visible = true
	foe.aggro = true
	rig.look_along(foe.position - p.position)
	rig.snap()
	p.facing = rig.forward()
	await frames(30)
	await shot("02-sala-com-monstro")
	# 3. The same room, camera turned and lower.
	rig.look(Vector2(-600, 90))
	await frames(20)
	await shot("03-camera-girada")
	# 4. Isometric, same spot.
	game.set_camera_mode(GameCamera.ISO, false)
	rig.snap()
	await frames(20)
	await shot("04-mesmo-lugar-isometrica")
	quit()
