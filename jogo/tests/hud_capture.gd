extends SceneTree
# Visual capture of the HUD in its main states, for review.
# Needs a display (real or virtual) and the Compatibility renderer:
#   godot --path . --rendering-driver opengl3 -s res://tests/hud_capture.gd
# Output: ../work/hud/*.png
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/hud")
	DirAccess.make_dir_recursive_absolute(out)
	# Always start from a fresh expedition; this capture never keeps a save.
	DirAccess.remove_absolute("user://expedicao_v1.json")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	game = main
	run()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT " + name)

## Moves the mouse to a point in the 1440x900 design space.
func hover(canvas: Vector2) -> void:
	var scale: Vector2 = Vector2(root.get_window().size) / Vector2(1440, 900)
	var event := InputEventMouseMotion.new()
	event.position = canvas * scale
	event.global_position = event.position
	root.get_viewport().push_input(event)

func click(canvas: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	var scale: Vector2 = Vector2(root.get_window().size) / Vector2(1440, 900)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.pressed = pressed
		event.position = canvas * scale
		event.global_position = event.position
		root.get_viewport().push_input(event)
		await frames(1)

func row_center(list: UiItemList, id: String) -> Vector2:
	var row: UiItemRow = list.row_for(id)
	return row.get_global_rect().get_center() if row else Vector2.ZERO

func run() -> void:
	await frames(40)
	var p = game.player
	var ui = game.ui
	# 1. Shelter, idle.
	await shot("01-abrigo")
	# 2. Next to the shelter reserve: prompt + collapsed bars show the container.
	p.position = Vector3(game.containers[0]["pos"][0] + 1.2, 0, game.containers[0]["pos"][1])
	game.camera_rig.position = p.position
	game.message("Prepare a mochila. O guardião da câmara está no fundo das cisternas.", 6)
	await frames(10)
	await shot("02-perto-do-bau")
	# 3. Inventory open on the reserve, item selected, tooltip on a row.
	ui.open_inventory(game.containers[0])
	game.inventory.add("spear")
	game.inventory.add("ore", 2)
	ui.refresh_inventory()
	ui.select_item("sword")
	await frames(5)
	hover(row_center(ui.inventory.bag_list, "sword"))
	await create_timer(0.8).timeout
	await shot("03-inventario-tooltip")
	# 4. Context menu on a loot row.
	hover(Vector2(700, 600))
	await frames(4)
	var loot_row: Vector2 = row_center(ui.inventory.loot_list, "ration")
	await click(loot_row, MOUSE_BUTTON_RIGHT)
	await frames(6)
	await shot("04-inventario-menu")
	ui.inventory.menu.hide()
	# Real drag & drop: press on a backpack row, move over the other window, release.
	var ore_before: int = int(game.containers[0]["items"].get("ore", 0))
	var start: Vector2 = row_center(ui.inventory.bag_list, "ore")
	var target: Vector2 = ui.inventory.loot_list.get_global_rect().get_center()
	hover(start)
	await frames(2)
	var scale: Vector2 = Vector2(root.get_window().size) / Vector2(1440, 900)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start * scale
	press.global_position = press.position
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.get_viewport().push_input(press)
	await frames(2)
	for i in 12:
		var motion := InputEventMouseMotion.new()
		motion.position = start.lerp(target, (i + 1) / 12.0) * scale
		motion.global_position = motion.position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.relative = (target - start) * scale / 12.0
		root.get_viewport().push_input(motion)
		await frames(1)
	await shot("04b-arrastando")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = target * scale
	release.global_position = release.position
	root.get_viewport().push_input(release)
	await frames(4)
	print("DRAG ore baú: %d -> %d, mochila: %d" % [ore_before, int(game.containers[0]["items"].get("ore", 0)), game.inventory.count("ore")])
	await shot("04c-depois-de-arrastar")
	ui.close_all()
	# 5. Trouble: bleeding, hurt, hungry, winded, heavy, hunted. Health window open.
	p.position = game.layout.to_world(Vector2i(9, 11))
	game.camera_rig.position = p.position
	p.health = 31
	p.bleeding = true
	p.food = 8
	p.stamina = 14
	game.inventory.add("ore", 5)
	game.enemies[1].aggro = true
	game.enemies[1].alive = true
	for e in game.enemies:
		e.set_physics_process(false)
	p.set_physics_process(false)
	ui.toggle_health()
	await create_timer(0.5).timeout
	hover(ui.moodles.get_child(0).get_global_rect().get_center())
	await create_timer(0.7).timeout
	await shot("05-condicao-e-indicadores")
	ui.toggle_health()
	hover(ui.moodles.get_child(0).get_global_rect().get_center())
	await create_timer(0.7).timeout
	await shot("05b-indicador-tooltip")
	ui.health_panel._show_tab("character")
	ui.toggle_health()
	await frames(4)
	hover(Vector2(720, 450))
	await create_timer(0.2).timeout
	await shot("06-personagem")
	ui.toggle_health()
	ui.health_panel._show_tab("health")
	# 7. Map after walking a route.
	for cell in game.layout.pathfinder.get_id_path(game.layout.spawn, Vector2i(18, 10)):
		p.position = game.layout.to_world(cell)
		game.discover()
	ui.toggle_map()
	await frames(4)
	await shot("07-mapa")
	ui.close_all()
	# 8. Pause.
	ui.toggle_pause()
	await shot("08-pausa")
	ui.close_all()
	# 9. Hotbar tooltip and equipped card while fighting near an enemy.
	p.health = 64
	p.bleeding = false
	p.food = 70
	p.stamina = 80
	game.inventory.remove("ore", 7)
	game.enemies[1].aggro = false
	p.position = game.layout.to_world(Vector2i(5, 12))
	game.camera_rig.position = p.position
	game.enemies[0].position = p.position + Vector3(1.6, 0, 0)
	game.enemies[0].aggro = true
	hover(ui.hotbar.slots[2]["button"].get_global_rect().get_center())
	await create_timer(0.7).timeout
	await shot("09-combate-barra-rapida")
	# 10. Ending.
	game.inventory.add("seal")
	p.position = game.camp_position
	game.interact()
	await frames(4)
	await shot("10-final")
	DirAccess.remove_absolute("user://expedicao_v1.json")
	quit()
