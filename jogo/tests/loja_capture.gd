extends SceneTree
# The merchant and the shop window, for review.
#   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1440x900 -s res://tests/loja_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/loja")
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
	var m: Node3D = game.merchant
	var toward: Vector3 = (ShopSystem.room_center(game) - m.position).normalized()
	p.position = m.position + toward * 1.6
	p.facing = -toward
	game.camera_rig.snap()
	await frames(30)
	await shot("01-mercador-no-abrigo")
	game.inventory.add("coin", 64)
	game.inventory.add("gema", 2)
	game.inventory.add("anel_prata")
	game.inventory.add("ore", 2)
	game.ui.open_shop()
	game.ui.shop_window.stock_list.select("flecha")
	game.ui.shop_window.refresh()
	await frames(6)
	await shot("02-loja")
	game.ui.close_all()
	game.set_camera_mode(GameCamera.THIRD, false)
	game.camera_rig.look_along(m.position - p.position)
	game.camera_rig.snap()
	p.facing = game.camera_rig.forward()
	await frames(30)
	await shot("03-mercador-terceira-pessoa")
	DirAccess.remove_absolute(game.save_path)
	quit()
