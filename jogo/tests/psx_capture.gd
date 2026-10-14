extends SceneTree
# Same scenes with the PSX filter on and off, for review.
#   godot --path . --rendering-driver opengl3 -s res://tests/psx_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/psx")
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

func both(name: String) -> void:
	game.psx.set_enabled(true)
	await frames(4)
	await shot(name + "-psx")
	game.psx.set_enabled(false)
	await frames(4)
	await shot(name + "-normal")
	game.psx.set_enabled(true)

func run() -> void:
	await frames(30)
	var p = game.player
	for e in game.enemies:
		e.set_physics_process(false)
	# Shelter
	await both("01-abrigo")
	# A room with a monster that already noticed the adventurer.
	var room: Rect2i = game.layout.rooms[1]["rect"]
	p.position = game.layout.to_world(room.get_center())
	game.camera_rig.snap()
	var foe = game.enemies[0]
	foe.position = p.position + Vector3(2.0, 0, -0.8)
	foe.visible = true
	foe.aggro = true
	foe.health = foe.maximum_health * 0.6
	foe.health_label.visible = true
	foe.health_label.text = "%s  %d" % [foe.display_name(), ceil(foe.health)]
	foe.visual.rotation.y = atan2(-1.0, 0.4)
	p.facing = Vector3(1, 0, -0.4).normalized()
	p.visual.rotation.y = atan2(p.facing.x, p.facing.z)
	game.inventory.add("martelo")
	game.inventory.equip("martelo")
	await frames(6)
	await both("02-sala")
	# Close-up: character, weapon and textures.
	game.camera_rig.zoom = 5.5
	game.camera.size = 5.5
	game.camera_rig.snap()
	await frames(4)
	await both("03-perto")
	game.camera_rig.zoom = 9.0
	game.camera.size = 9.0
	game.camera_rig.snap()
	# Inventory open: HUD must stay sharp.
	game.ui.open_inventory({})
	await frames(4)
	await both("04-inventario")
	game.ui.close_all()
	quit()
