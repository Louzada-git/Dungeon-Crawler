extends SceneTree
# Captures of the adventurer creation, proficiency window and level notice.
#   godot --path . --rendering-driver opengl3 -s res://tests/proficiency_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/proficiencias")
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

func hover(canvas: Vector2) -> void:
	var scale: Vector2 = Vector2(root.get_window().size) / Vector2(1440, 900)
	var event := InputEventMouseMotion.new()
	event.position = canvas * scale
	event.global_position = event.position
	root.get_viewport().push_input(event)

func run() -> void:
	await frames(30)
	for e in game.enemies:
		e.set_physics_process(false)
	game.choosing_character = true
	game.ui.show_creation()
	var panel = game.ui.creation_panel
	panel._change("vigor", -1)
	panel._change("forca", 1)
	panel._change("destreza", -1)
	panel._change("forca", 1)
	await shot("01-novo-aventureiro")
	panel.confirmed.emit(panel.values.duplicate())
	await frames(5)
	var sheet = game.sheet
	sheet.award_path(["espadas", "espada_reta"], 1400.0)
	sheet.award_path(["espadas", "katana"], 300.0)
	sheet.award_path(["contundentes", "martelo"], 450.0)
	sheet.award("esquiva", 120.0)
	sheet.award("tratamento", 40.0)
	game.ui.level_banner.queue.clear()
	game.ui.level_banner._time = 0
	game.ui.toggle_proficiencies()
	await create_timer(0.3).timeout
	var row = game.ui.prof_window.rows["espadas"]
	hover(row.get_global_rect().get_center())
	await create_timer(0.8).timeout
	await shot("02-proficiencias")
	hover(Vector2(900, 600))
	game.ui.toggle_proficiencies()
	sheet.award("adagas", 400.0)
	await create_timer(0.6).timeout
	await shot("03-aviso-de-nivel")
	quit()
