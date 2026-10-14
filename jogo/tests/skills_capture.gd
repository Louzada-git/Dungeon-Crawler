extends SceneTree
# Captures of the Oblivion-inspired branches: armor on the body, guard, sneaking,
# locked chest, armor tooltip and the grouped proficiency window.
#   godot --path . --rendering-driver opengl3 -s res://tests/skills_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/pericias")
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

func pose(p, animation: String) -> void:
	p.facing = Vector3(1, 0, -0.35).normalized()
	p.visual.rotation.y = atan2(p.facing.x, p.facing.z)
	Visuals.play(p.animator, animation)

func run() -> void:
	await frames(30)
	var p = game.player
	for e in game.enemies:
		e.set_physics_process(false)
	var spot: Vector3 = game.layout.to_world(game.layout.spawn + Vector2i(1, 1))
	p.position = spot
	p.set_physics_process(false)
	game.camera_rig.snap()
	game.camera_rig.zoom = 5.5
	game.camera.size = 5.5
	game.ui.hud.visible = false
	game.inventory.restore({"stacks": {}, "equipped": ""})
	game.inventory.add("sword")
	game.inventory.equip("sword")
	for id in ["gibao", "couro", "cota", "placas"]:
		game.inventory.add(id)
		game.inventory.wear(id)
		pose(p, "idle")
		await frames(12)
		await shot("corpo-" + id)
		game.inventory.remove(id)
	game.ui.hud.visible = true
	# Guard and sneaking in a room, with the indicators on the HUD.
	game.inventory.add("cota")
	game.inventory.wear("cota")
	var room: Rect2i = game.layout.rooms[1]["rect"]
	p.position = game.layout.to_world(room.get_center())
	game.camera_rig.zoom = 9.0
	game.camera.size = 9.0
	game.camera_rig.snap()
	var foe = game.enemies[0]
	foe.visible = true
	foe.position = p.position + Vector3(1.6, 0, -0.6)
	foe.visual.rotation.y = atan2(-1.0, 0.35)
	p.aiming = true
	pose(p, "guard")
	await frames(10)
	await shot("guarda")
	p.aiming = false
	p.sneaking = true
	foe.position = p.position + Vector3(3.2, 0, -1.2)
	foe.visual.rotation.y = atan2(1.0, -0.35)
	pose(p, "guard")
	await frames(10)
	await shot("furtivo")
	p.sneaking = false
	foe.position = game.layout.to_world(game.layout.rooms[-1]["rect"].get_center())
	# Locked chest beside the adventurer.
	var chest: Dictionary = game.add_loot("Baú reforçado", game.layout.to_cell(p.position) + Vector2i(1, 0), {"gema": 2, "flecha": 6}, true, "captura_tranca", 3)
	game.inventory.add("gazua", 2)
	await frames(6)
	await shot("bau-trancado-prompt")
	game.ui.open_inventory(chest)
	await frames(6)
	await shot("bau-trancado")
	game.attempt_lockpick(chest, 0.0)
	await frames(6)
	await shot("bau-arrombado")
	game.ui.close_all()
	# Armor tooltip from the backpack.
	game.ui.open_inventory({})
	game.inventory.add("placas")
	game.ui.refresh_inventory()
	game.ui.select_item("cota")
	await frames(4)
	var row = game.ui.inventory.bag_list.row_for("cota")
	hover(row.get_global_rect().get_center())
	await create_timer(0.8).timeout
	await shot("dica-cota")
	hover(Vector2(900, 80))
	game.ui.close_all()
	# Grouped proficiency window.
	var sheet = game.sheet
	sheet.award_path(CharacterSheet.path_of("sword"), 1200.0)
	sheet.award("bloqueio", 260.0)
	sheet.award("armadura_pesada", 420.0)
	sheet.award("atletismo", 90.0)
	sheet.award("furtividade", 300.0)
	sheet.award("arrombamento", 140.0)
	sheet.award("acrobacia", 60.0)
	sheet.award("tratamento", 30.0)
	game.ui.level_banner.queue.clear()
	game.ui.toggle_proficiencies()
	await create_timer(0.3).timeout
	await shot("proficiencias-topo")
	var window = game.ui.prof_window
	var scroll: ScrollContainer = window.find_children("*", "ScrollContainer", true, false)[0]
	scroll.scroll_vertical = int(window.rows["hastes"].position.y)
	await frames(4)
	await shot("proficiencias-meio")
	scroll.scroll_vertical = 100000
	await frames(4)
	hover(window.rows["furtividade"].get_global_rect().get_center())
	await create_timer(0.8).timeout
	await shot("proficiencias-fim")
	quit()
