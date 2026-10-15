extends SceneTree
# Quick bar (1-9, any item) and habilidade keys chosen by the player, for review.
#   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1440x900 -s res://tests/barra_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/barra")
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

func hover(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	var scale: Vector2 = Vector2(root.get_window().size) / Vector2(1440, 900)
	event.position = at * scale
	event.global_position = event.position
	root.get_viewport().push_input(event)

func run() -> void:
	await frames(30)
	for e in game.enemies:
		e.set_physics_process(false)
	if game.choosing_character:
		game.ui.creation_panel.confirmed.emit(game.ui.creation_panel.choice())
	await frames(5)
	var inv = game.inventory
	for id in ["katana", "couro", "tonico", "unguento", "gazua"]:
		inv.add(id)
	inv.add("flecha", 12)
	inv.add("arco")
	var bar = game.quick_bar
	bar.assign(3, "katana")
	bar.assign(4, "arco")
	bar.assign(5, "couro")
	bar.assign(6, "tonico")
	bar.assign(7, "unguento")
	inv.wear("couro")
	game.techniques.assign(0, "corte")
	game.set_technique_key(1, KEY_KP_1)
	game.ui.update_hud()
	await frames(10)
	hover(game.ui.hotbar.slots[4]["button"].get_global_rect().get_center())
	await create_timer(0.9).timeout
	await shot("01-barra-rapida")
	hover(Vector2(720, 300))
	game.ui.toggle_techniques()
	game.ui.tech_window.select("corte")
	game.ui.tech_window.start_capture(2)
	await frames(6)
	await shot("02-teclas-das-habilidades")
	game.ui.tech_window.capture_key(KEY_ESCAPE)
	game.ui.toggle_techniques()
	game.ui.toggle_pause()
	await frames(6)
	await shot("03-controles")
	game.ui.toggle_pause()
	DirAccess.remove_absolute(game.settings_path)
	quit()
