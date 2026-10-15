extends SceneTree
# Technique editor, bar with recharge and a technique in use, for review.
#   godot --path . --rendering-driver opengl3 -s res://tests/techniques_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/tecnicas")
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

func teach(branch: String, level: int) -> void:
	game.sheet.award(branch, ProficiencyTree.xp_for_level(level) + 1.0)

func run() -> void:
	await frames(30)
	var p = game.player
	for e in game.enemies:
		e.set_physics_process(false)
	var sheet = game.sheet
	teach("laminas", 5)
	teach("contundentes", 3)
	teach("acrobacia", 3)
	teach("atletismo", 3)
	sheet.award_path(CharacterSheet.path_of("sword"), ProficiencyTree.xp_for_level(7) * 3.0)
	game.ui.level_banner.queue.clear()
	var book = game.techniques
	book.store({"name": "Corte sangrento", "form": "corte", "components": ["afiada", "forca"]})
	book.store({"name": "Giro", "form": "corte_giratorio", "components": ["rapidez"]})
	book.store({"name": "Arremetida", "form": "corte", "components": ["avanco"]})
	book.assign(0, 0)
	book.assign(1, 1)
	book.assign(2, 2)
	var room: Rect2i = game.layout.rooms[1]["rect"]
	p.position = game.layout.to_world(room.get_center())
	game.camera_rig.snap()
	game.ui.toggle_techniques()
	game.ui.tech_window.edit(0)
	await frames(6)
	await shot("01-editor")
	game.ui.toggle_techniques()
	# A monster in front; the spin, then the bar recharging.
	var foe = game.enemies[0]
	foe.position = p.position + Vector3(1.0, 0, 0.6)
	foe.visible = true
	foe.aggro = true
	var foe2 = game.enemies[1] if game.enemies.size() > 1 else null
	if foe2:
		foe2.position = p.position + Vector3(-1.1, 0, -0.4)
		foe2.visible = true
		foe2.aggro = true
	p.facing = Vector3(1, 0, 0.6).normalized()
	p.stamina = p.max_stamina
	p.use_technique(1, false)
	await create_timer(0.12).timeout
	await shot("02-giro")
	await create_timer(0.6).timeout
	game.ui.toggle_techniques()
	await frames(4)
	await shot("03-em-combate")
	game.ui.toggle_techniques()
	quit()
