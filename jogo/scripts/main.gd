extends Node3D
## Game root: builds the current floor from its description, owns the
## expedition state and wires the systems in scripts/systems/.
##
## Two modes:
## - labyrinth (normal game): floors generated from a seed; stairs between
##   floors; the shelter on floor 1 saves; death restarts the same labyrinth
##   and keeps the explored map (decision of 13/10/2026).
## - fixed world (data/mundos/cisternas.json): used by the automated tests.

const KNOWLEDGE_PATH := "user://conhecimento.json"

var sound
var aim_marker: AimMarker
var save_path: String = "user://expedicao_v1.json"
var knowledge_path: String = KNOWLEDGE_PATH
var inventory = InventoryData.new()
## The adventurer of this run: attributes and proficiencies.
var sheet := CharacterSheet.new()
## True while the "new adventurer" panel waits for the player.
var choosing_character: bool = false
var layout: DungeonLayout
var player: DungeonPlayer
var camera: Camera3D
var camera_rig: GameCamera
var ui
var world_root: Node3D
var stairs_sign: Label3D
var enemies: Array[DungeonEnemy] = []
var containers: Array[Dictionary] = []
var discovered: Dictionary = {}
var camp_position: Vector3
var kills: int = 0
var hits_received: int = 0
var won: bool = false
var ended: bool = false
var last_discover: Vector2i = Vector2i(-99, -99)
var message_text: String = "Prepare sua mochila. Explore e recupere o selo das cisternas."
var message_time: float = 8.0
var test_mode: bool = false
# Labyrinth state
var generated: bool = false
var seed: int = 0
var floor: int = 1
var deepest: int = 1
var seals_delivered: int = 0
var floor_states: Dictionary = {}
var knowledge: Dictionary = {}
## Fractions of missed ammunition still owed to the floor (see Projectile._fall).
var ammo_recovery: Dictionary = {}
var _skip_load: bool = false

func _ready() -> void:
	TranslationServer.set_locale("pt_BR")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	test_mode = "--test" in args or "--capture" in args
	generated = not test_mode
	if test_mode:
		save_path = "user://teste_base_v1.json"
	if "--test-labirinto" in args:
		save_path = "user://teste_labirinto.json"
		knowledge_path = "user://teste_conhecimento.json"
	get_tree().auto_accept_quit = false
	InputSetup.configure()
	# Progression is off in the fixed test world so its exact numbers stay put.
	sheet.enabled = generated
	if generated:
		message_text = "Prepare sua mochila. O guardião do andar guarda o selo e a descida."
		_choose_seed(args)
		layout = DungeonLayout.new(LabyrinthGenerator.generate(seed, floor))
	else:
		layout = DungeonLayout.new()
	camp_position = layout.to_world(layout.camp)
	sound = preload("res://scripts/game_audio.gd").new()
	add_child(sound)
	WorldBuilder.environment(self)
	WorldBuilder.build(self)
	inventory.add("sword")
	inventory.add("ration", 3)
	inventory.add("bandage", 3)
	inventory.equip("sword")
	player = DungeonPlayer.new()
	player.game = self
	add_child(player)
	player.position = layout.to_world(layout.spawn)
	apply_attributes(true)
	camera_rig = GameCamera.new()
	camera_rig.target = player
	add_child(camera_rig)
	camera = camera_rig.camera
	var light := OmniLight3D.new()
	player.add_child(light)
	light.position = Vector3(0, 2, 0)
	light.light_color = Color("d8e2de")
	light.light_energy = 0.25
	light.omni_range = 7
	aim_marker = AimMarker.new()
	add_child(aim_marker)
	setup_content()
	if generated:
		discovered = knowledge.get(floor, {})
		knowledge[floor] = discovered
	ui = preload("res://scripts/ui.gd").new()
	ui.game = self
	add_child(ui)
	inventory.changed.connect(on_inventory_changed)
	sheet.level_up.connect(ui.on_level_up)
	sheet.perk_unlocked.connect(ui.on_perk_unlocked)
	var loaded: bool = false
	if not test_mode and not _skip_load and FileAccess.file_exists(save_path):
		loaded = load_game()
	if generated and not loaded and not _skip_load and not "--test-labirinto" in args:
		choosing_character = true
		ui.show_creation()
	discover()
	if test_mode:
		call_deferred("run_test_mode")
	elif "--test-labirinto" in args:
		call_deferred("run_labyrinth_tests")

## Seed and floor: from --seed=N, from the expedition save, from the knowledge
## kept after a death, or a new random labyrinth.
func _choose_seed(args: PackedStringArray) -> void:
	for arg in args:
		if arg.begins_with("--seed="):
			seed = int(arg.substr(7))
			_skip_load = true
			return
	if FileAccess.file_exists(save_path):
		var raw = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if raw is Dictionary and raw.get("version") == SaveSystem.VERSION and raw.get("mode") == "labirinto":
			seed = int(raw.get("seed", 0))
			floor = maxi(1, int(raw.get("floor", 1)))
			return
	if FileAccess.file_exists(knowledge_path):
		var known = JSON.parse_string(FileAccess.get_file_as_string(knowledge_path))
		if known is Dictionary and known.has("seed"):
			seed = int(known["seed"])
			knowledge = SaveSystem.parse_knowledge(known.get("knowledge", {}))
			deepest = int(known.get("deepest", 1))
			message_text = "Mesmo labirinto, do começo. O que você descobriu continua no mapa."
			return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	seed = rng.randi_range(1, 999999999)

## Limits that come from the attributes. fill = start at full health and stamina.
func apply_attributes(fill: bool) -> void:
	inventory.capacity = sheet.capacity()
	inventory.comfort = sheet.comfort()
	if player:
		player.max_health = sheet.max_health()
		player.max_stamina = sheet.max_stamina()
		if fill:
			player.health = player.max_health
			player.stamina = player.max_stamina
		else:
			player.health = minf(player.health, player.max_health)
			player.stamina = minf(player.stamina, player.max_stamina)
	if ui:
		ui.update_hud()

## Called by the "new adventurer" panel.
func start_character(values: Dictionary) -> void:
	sheet.reset(values)
	apply_attributes(true)
	choosing_character = false
	message("Atributos definem o seu potencial. As proficiências crescem com o uso: P mostra o progresso.", 7)

func on_dodged(amount: float) -> void:
	sheet.award("esquiva", amount * 0.8, floor)

## Containers and monsters from the floor description.
func setup_content() -> void:
	for entry in layout.world["containers"]:
		add_loot(str(tr(entry["name"])), DungeonLayout.cell(entry["cell"]), entry["items"], entry.get("chest", true), entry["id"])
	var index: int = 0
	for entry in layout.world["enemies"]:
		var enemy := DungeonEnemy.new()
		enemy.game = self
		enemy.enemy_id = index
		enemy.uid = entry["id"]
		enemy.kind = entry["type"]
		enemy.level = int(entry.get("level", 1))
		enemy.position = layout.to_world(DungeonLayout.cell(entry["cell"]))
		add_child(enemy)
		enemies.append(enemy)
		index += 1

func add_loot(title: String, cell: Vector2i, items: Dictionary, chest: bool = true, id: String = "") -> Dictionary:
	return ContainerSystem.add(self, title, cell, items, chest, id)

func _process(delta: float) -> void:
	if player == null or ui == null:
		return
	message_time = maxf(0, message_time - delta)
	discover()
	for loot in containers:
		loot["ring"].visible = not loot["items"].is_empty()
	aim_marker.refresh(self)
	ui.update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if ui == null or ended or choosing_character:
		return
	if event.is_action_pressed("inventory"):
		ui.toggle_inventory()
	elif event.is_action_pressed("map"):
		ui.toggle_map()
	elif event.is_action_pressed("escape"):
		ui.toggle_pause()
	elif event.is_action_pressed("save"):
		save_game()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("dodge"):
		player.dodge()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			player.request_attack()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_rig.zoom_by(-1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_rig.zoom_by(1.5)

# --- exploration ---------------------------------------------------------------

func discover() -> void:
	var cell = layout.to_cell(player.position)
	if cell == last_discover:
		return
	last_discover = cell
	for x in range(cell.x - 5, cell.x + 6):
		for y in range(cell.y - 5, cell.y + 6):
			var p := Vector2i(x, y)
			if layout.is_floor(p) and p.distance_to(cell) <= 5.5 and clear_line(player.position, layout.to_world(p)):
				discovered[p] = true

func clear_line(a: Vector3, b: Vector3) -> bool:
	if a.distance_squared_to(b) < 0.001:
		return true
	var query := PhysicsRayQueryParameters3D.create(a + Vector3(0, 0.8, 0), b + Vector3(0, 0.8, 0), 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func is_safe() -> bool:
	return layout.is_safe(player.position)

func has_shelter() -> bool:
	return layout.world.get("has_shelter", true)

func boss() -> DungeonEnemy:
	for e in enemies:
		if e.boss:
			return e
	return null

func boss_alive() -> bool:
	var b := boss()
	return b != null and b.alive

func stairs_down_cell() -> Variant:
	return DungeonLayout.cell(layout.world["stairs_down"]) if layout.world.has("stairs_down") else null

func stairs_up_cell() -> Variant:
	return DungeonLayout.cell(layout.world["stairs_up"]) if layout.world.get("stairs_up") != null else null

func _near(cell: Variant, distance: float = 2.3) -> bool:
	return cell != null and player.position.distance_to(layout.to_world(cell)) < distance

func objective_text() -> String:
	if not generated:
		return "Retorne ao abrigo com o selo" if inventory.count("seal") > 0 else "Recupere o selo das cisternas"
	if inventory.count("seal") > 0:
		return "Leve o selo ao abrigo — ou desça mais"
	if boss_alive():
		return "Derrote o guardião do %dº andar" % floor
	return "Desça ao %dº andar ou volte ao abrigo" % (floor + 1)

# --- floors ------------------------------------------------------------------------

func snapshot_floor() -> Dictionary:
	var cs: Array = []
	for c in containers:
		cs.append({"id": c["id"], "name": c["name"], "pos": c["pos"], "items": c["items"].duplicate(), "chest": c["chest"]})
	var es: Dictionary = {}
	for e in enemies:
		es[e.uid] = {"health": e.health, "alive": e.alive, "pos": [e.position.x, e.position.z], "stuck": e.stuck.duplicate()}
	return {"containers": cs, "enemies": es}

func apply_floor_state(state: Dictionary) -> void:
	for c in containers:
		c["node"].queue_free()
	containers.clear()
	for data in state.get("containers", []):
		var copy: Dictionary = data.duplicate(true)
		containers.append(copy)
		WorldBuilder.add_container(self, copy)
	var saved: Dictionary = state.get("enemies", {})
	for e in enemies:
		if saved.has(e.uid):
			SaveSystem.restore_enemy(e, saved[e.uid])

## Leaves the current floor for floor n. Going down arrives at the entrance of
## the new floor; going up arrives next to its stairs down.
func change_floor(n: int, going_down: bool) -> void:
	if not generated or n < 1:
		return
	if ui:
		ui.close_all()
	floor_states[floor] = snapshot_floor()
	WorldBuilder.clear(self)
	floor = n
	deepest = maxi(deepest, n)
	layout = DungeonLayout.new(LabyrinthGenerator.generate(seed, n))
	camp_position = layout.to_world(layout.camp)
	WorldBuilder.build(self)
	setup_content()
	if floor_states.has(n):
		apply_floor_state(floor_states[n])
	discovered = knowledge.get(n, {})
	knowledge[n] = discovered
	if going_down:
		player.position = layout.to_world(layout.spawn)
	else:
		player.position = layout.to_world(_free_neighbour(stairs_down_cell()))
	player.reset_transients()
	camera_rig.snap()
	last_discover = Vector2i(-99, -99)
	discover()
	sound.play_at("step", player.global_position, 0.6)
	if going_down:
		message("%dº andar. %s" % [n, "O guardião deste andar guarda o próximo selo." if boss_alive() else "Este andar já foi vencido."], 5)
	else:
		message("De volta ao %dº andar." % n, 3)

func _free_neighbour(cell: Vector2i) -> Vector2i:
	for d in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		var c: Vector2i = cell + d
		if layout.is_floor(c) and not layout.pathfinder.is_point_solid(c):
			return c
	return cell

# --- containers and items --------------------------------------------------------

func nearby_containers(reach: float = ContainerSystem.REACH) -> Array:
	return ContainerSystem.nearby(self, reach)

func nearest_container() -> Dictionary:
	return ContainerSystem.nearest(self)

func nearest_loot() -> Dictionary:
	return ContainerSystem.nearest_with_items(self)

func store_item(id: String, amount: int, container: Dictionary) -> int:
	return ContainerSystem.store(self, id, amount, container)

func drop_item(id: String, amount: int = 1) -> bool:
	return ContainerSystem.drop(self, id, amount)

func use_item(id: String) -> bool:
	return ItemUse.use(self, id)

func interaction_text() -> String:
	if has_shelter() and player.position.distance_to(camp_position) < 1.6:
		if inventory.count("seal") > 0:
			return "E   ENTREGAR O SELO NO ABRIGO" if generated else "E   RETORNAR COM O SELO"
		return "E   DESCANSAR E SALVAR NO ABRIGO"
	if generated:
		if _near(stairs_up_cell()):
			return "E   SUBIR  ·  para o %dº andar" % (floor - 1)
		if _near(stairs_down_cell()):
			return ("E   DESCER  ·  selada pelo guardião" if boss_alive() else "E   DESCER  ·  para o %dº andar" % (floor + 1))
	var loot = nearest_container()
	if not loot.is_empty():
		var empty: bool = loot["items"].is_empty()
		return ("E   ABRIR  ·  " if empty else "E   VASCULHAR  ·  ") + loot["name"] + ("  (vazio)" if empty else "")
	return ""

func interact() -> void:
	if has_shelter() and player.position.distance_to(camp_position) < 1.6:
		var seals: int = inventory.count("seal")
		if seals > 0 and not generated:
			won = true
			save_game(false)
			end_run(true)
			return
		player.stamina = player.max_stamina
		if seals > 0:
			inventory.remove("seal", seals)
			seals_delivered += seals
			save_game(false)
			message("Selo entregue no abrigo. Selos guardados: %d. Expedição salva." % seals_delivered, 6)
		else:
			save_game(false)
			message("Expedição salva. Alimente-se e trate ferimentos antes de sair.")
		return
	if generated:
		if _near(stairs_up_cell()):
			change_floor(floor - 1, false)
			return
		if _near(stairs_down_cell()):
			if boss_alive():
				message("A descida está selada. Derrote o guardião deste andar.", 3)
			else:
				change_floor(floor + 1, true)
			return
	var loot = nearest_container()
	if not loot.is_empty():
		sound.play_at("loot", player.global_position, 0.6)
		ui.open_inventory(loot)
		Visuals.play(Visuals.animation(loot["node"]), "open", false)

## Development tool (pause menu): a chest with every weapon and ammunition.
## Remove before release.
func spawn_test_arsenal() -> Dictionary:
	var items: Dictionary = {}
	for id in Items.DATA:
		var tag: String = str(Items.DATA[id].get("tag", ""))
		if tag == "ARMA":
			items[id] = 1
		elif tag == "MUNICAO":
			items[id] = 40
	var cell: Vector2i = layout.to_cell(player.position)
	for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		if layout.is_floor(cell + d) and not layout.pathfinder.is_point_solid(cell + d):
			cell = cell + d
			break
	var chest: Dictionary = add_loot(str(tr("RECIPIENTE_ARSENAL")), cell, items, true)
	message("Arsenal de teste ao seu lado. E para abrir.", 4)
	return chest

func on_inventory_changed() -> void:
	if player:
		player.refresh_weapon()

# --- combat ------------------------------------------------------------------

func resolve_player_attack() -> void:
	Combat.resolve_player_attack(self)

func camera_impact(strength: float) -> void:
	camera_rig.impact(strength)

func enemy_defeated(enemy: DungeonEnemy) -> void:
	kills += 1
	var title: String = str(tr("RECIPIENTE_DESPOJOS" if enemy.boss else "RECIPIENTE_PERTENCES"))
	var items: Dictionary = EnemyTypes.info(enemy.kind).get("loot", {}).duplicate()
	for ammo in enemy.stuck:
		items[ammo] = int(items.get(ammo, 0)) + int(enemy.stuck[ammo])
	enemy.stuck.clear()
	add_loot(title, layout.to_cell(enemy.position), items, false)
	if enemy.boss:
		if is_instance_valid(stairs_sign):
			stairs_sign.modulate = Color("9fdc8f")
		camera_impact(0.2)
		message("O guardião caiu. A descida para o %dº andar está aberta." % (floor + 1), 6)
	else:
		message("Área mais segura. E para recolher os pertences.", 3)

func flash_damage() -> void:
	ui.damage_flash()

# --- flow ----------------------------------------------------------------------

func message(text: String, duration: float = 4.0) -> void:
	message_text = text
	message_time = duration
	if ui:
		ui.update_hud()

func end_run(success: bool) -> void:
	if ended:
		return
	ended = true
	if not success:
		# Death ends the run: its save goes, what the player learned stays.
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
		write_knowledge()
	ui.show_ending(success)

func save_game(notify_user: bool = true) -> bool:
	var ok: bool = SaveSystem.write(self, notify_user)
	if ok:
		write_knowledge()
	return ok

func load_game() -> bool:
	return SaveSystem.read(self)

func valid_save(raw) -> bool:
	return SaveSystem.valid(self, raw)

## Knowledge kept across deaths: seed, explored map per floor, deepest floor.
func write_knowledge() -> void:
	if not generated:
		return
	var file := FileAccess.open(knowledge_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"version": 1, "seed": seed, "deepest": deepest, "knowledge": SaveSystem.pack_knowledge(knowledge)}))
		file.close()

## After a death: same labyrinth from the start, knowledge kept.
func restart_same() -> void:
	get_tree().paused = false
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	write_knowledge()
	get_tree().reload_current_scene()

## New expedition: a new labyrinth, nothing kept.
func restart() -> void:
	get_tree().paused = false
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	if generated and FileAccess.file_exists(knowledge_path):
		DirAccess.remove_absolute(knowledge_path)
	get_tree().reload_current_scene()

func run_test_mode() -> void:
	var harness = load("res://tests/runtime_test.gd").new()
	add_child(harness)
	harness.run(self, "--capture" in OS.get_cmdline_user_args())

func run_labyrinth_tests() -> void:
	var harness = load("res://tests/labyrinth_test.gd").new()
	add_child(harness)
	harness.run(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player):
		if not test_mode and player.health > 0 and not ended:
			save_game(false)
		get_tree().quit()
