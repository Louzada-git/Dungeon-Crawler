extends SceneTree
# Weapon tips after the balance pass (weight, delay, when the dodge returns, stamina), for review.
#   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1440x900 -s res://tests/balanco_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/balanco")
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	run()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func run() -> void:
	await frames(30)
	for e in game.enemies:
		e.set_physics_process(false)
	if game.choosing_character:
		game.ui.creation_panel.confirmed.emit(game.ui.creation_panel.choice())
	await frames(5)
	var x: float = 40.0
	for id in ["adaga", "sword", "martelo", "besta"]:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.08, 0.07, 0.96), UiStyle.BORDER, 1, Vector4(10, 8, 10, 8)))
		panel.add_child(UiItemTooltip.build(id))
		game.ui.add_child(panel)
		panel.position = Vector2(x, 140)
		x += panel.get_combined_minimum_size().x + 10.0
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/01-dicas-das-armas.png")
	print("SHOT 01-dicas-das-armas")
	quit()
