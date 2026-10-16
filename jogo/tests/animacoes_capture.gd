extends SceneTree
# New animations and characters in the game, for review: blows with several
# weapons at the moment they land, the monsters side by side, the boss slam.
#   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1440x900 -s res://tests/animacoes_capture.gd -- --seed=4242
var out: String
var game

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/animacoes")
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	run()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT " + name)

## Swings the weapon and takes the picture when the blow lands.
func blow(id: String, name: String) -> void:
	var p = game.player
	# Only the weapon being shown in the backpack, so it always fits.
	game.inventory.restore({"stacks": {}, "equipped": ""})
	game.inventory.add(id)
	if Items.info(id).has("ammo"):
		game.inventory.add(str(Items.info(id)["ammo"]), 5)
	game.inventory.equip(id)
	p.refresh_weapon()
	await frames(4)
	p.cooldown = 0
	p.attack_timer = 0
	p.attack_wait = 0
	p.stamina = 100
	p.attack()
	var t: float = 0.0
	while p.attack_wait > 0.02 and t < 3.0:
		await process_frame
		t += game.get_process_delta_time()
	await shot(name)
	await create_timer(1.2).timeout

func run() -> void:
	await frames(30)
	for e in game.enemies:
		e.set_physics_process(false)
	if game.choosing_character:
		game.ui.creation_panel.confirmed.emit(game.ui.creation_panel.choice())
	await frames(5)
	var p = game.player
	var center: Vector3 = game.layout.to_world(game.layout.rooms[1]["rect"].get_center())
	p.position = center
	p.facing = Vector3(1, 0, 1).normalized()
	game.set_camera_mode(GameCamera.THIRD, false)
	var rig = game.camera_rig
	rig.look_along(Vector3(1, 0, 0.45))
	rig.arm_length = 3.0
	rig.snap()
	game.ui.hud.visible = false
	await frames(20)
	p.facing = Vector3(0, 0, 1)
	await blow("sword", "01-espada")
	await blow("martelo", "02-martelo")
	await blow("machado", "03-machado")
	await blow("montante", "04-montante")
	await blow("spear", "05-lanca")
	await blow("arco", "06-arco")
	# Monsters side by side.
	var kinds: Array = ["corrompido", "espreitador", "brutamontes", "guardiao", "chefe"]
	var x: float = -3.6
	for i in kinds.size():
		var e: DungeonEnemy = null
		for candidate in game.enemies:
			if candidate.kind == kinds[i] and candidate.alive:
				e = candidate
				break
		if e == null:
			continue
		e.position = center + Vector3(x, 0, 3.4)
		e.visible = true
		e.visual.rotation.y = PI
		Visuals.play(e.animator, "guard" if i % 2 == 0 else "idle")
		x += 1.8
	p.position = center + Vector3(0, 0, -1.5)
	rig.look_along(Vector3(0, 0, 1))
	rig.arm_length = 5.5
	rig.snap()
	await frames(30)
	await shot("07-monstros")
	var boss: DungeonEnemy = game.boss()
	if boss:
		boss.position = center + Vector3(0, 0, 2.2)
		boss.visible = true
		boss.visual.rotation.y = PI
		boss.slamming = true
		boss.animator.play("pancada", 0.0, 1.0)
		await create_timer(boss.animator.get_animation("pancada").length * 0.72).timeout
		await shot("08-chefe-pancada")
	DirAccess.remove_absolute(game.save_path)
	quit()
