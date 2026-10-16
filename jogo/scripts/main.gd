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
## Habilidades set up by the player (objetos in slots, bar of 4, recharges).
var techniques := TechniqueBook.new()
## Quick bar, keys 1 to 9: any item in any slot.
var quick_bar := QuickBar.new()
## Keys of the habilidade bar, chosen by the player (user settings); never the number row.
var technique_keys: Array = []
## True while the "new adventurer" panel waits for the player.
var choosing_character: bool = false
var layout: DungeonLayout
var player: DungeonPlayer
var camera: Camera3D
var camera_rig: GameCamera
## Third person: whether the cursor should be captured right now (see update_cursor).
var cursor_captured: bool = false
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
var message_text: String = "Prepare a mochila. O carcereiro está no fundo das cisternas."
var message_time: float = 8.0
var test_mode: bool = false
# Labyrinth state
var generated: bool = false
var seed: int = 0
var floor: int = 1
var deepest: int = 1
var floor_states: Dictionary = {}
var knowledge: Dictionary = {}
## Fractions of missed ammunition still owed to the floor (see Projectile._fall).
var ammo_recovery: Dictionary = {}
## Ammunition picked on the quick bar; used whenever the weapon fires it.
var chosen_ammo: String = ""
## The merchant of this floor (ShopSystem) and what he has to sell.
var merchant: Node3D
var shop_stock: Dictionary = {}
var _skip_load: bool = false
## PlayStation-style filter (pause menu); preference kept in settings_path.
var psx: PsxFilter
var settings_path: String = "user://configuracoes.cfg"

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
	if test_mode or "--test-labirinto" in args:
		settings_path = "user://teste_configuracoes.cfg"
	psx = PsxFilter.new()
	psx.name = "FiltroPSX"
	psx.enabled = load_setting("video", "psx", true)
	add_child(psx)
	# Progression is off in the fixed test world so its exact numbers stay put.
	sheet.enabled = generated
	if generated:
		message_text = "Prepare a mochila. A descida fica na sala do capataz."
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
	quick_bar.defaults("sword")
	load_technique_keys()
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
	quick_bar.changed.connect(ui.update_hud)
	set_camera_mode(str(load_setting("video", "camera", GameCamera.ISO)), false)
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

func load_setting(section: String, key: String, fallback: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) != OK:
		return fallback
	return cfg.get_value(section, key, fallback)

func save_setting(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(settings_path)
	cfg.set_value(section, key, value)
	cfg.save(settings_path)

## "iso" (isometric, the default) or "terceira" (third person behind the
## character, turned by the mouse). Switches the camera, the front walls (whole
## in third person), the fog and the cursor, and remembers the choice.
func set_camera_mode(value: String, remember: bool = true) -> void:
	var third: bool = value == GameCamera.THIRD
	if third and not camera_rig.third_person():
		camera_rig.look_along(player.facing if player else Vector3.FORWARD)
	camera_rig.set_mode(value)
	camera = camera_rig.camera
	WorldBuilder.apply_view(world_root, third)
	var env_node = get_node_or_null("Ambiente")
	if env_node and env_node.environment:
		env_node.environment.fog_enabled = third
	if remember:
		save_setting("video", "camera", camera_rig.mode)
	update_cursor()
	if ui:
		ui.on_camera_mode()

func third_person() -> bool:
	return camera_rig != null and camera_rig.third_person()

## Third person: the mouse turns the camera (cursor captured) unless a window,
## a menu or Alt needs the cursor. Called every frame by the HUD, which keeps
## running while the game is paused (inventory, map, pause menu).
func update_cursor() -> void:
	cursor_captured = third_person() and not ended and not choosing_character and ui != null and not ui.cursor_needed()
	var wanted: int = Input.MOUSE_MODE_CAPTURED if cursor_captured else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != wanted:
		Input.mouse_mode = wanted

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and third_person() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rig.look(event.relative)

## Turns the PlayStation-style filter on or off and remembers the choice.
func set_psx(on: bool) -> void:
	psx.set_enabled(on)
	save_setting("video", "psx", on)

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
			# How the habilidades were set up is knowledge: the next adventurer remembers it (the bar starts empty).
			techniques.restore(known.get("tecnicas", {}), false)
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

## Called by the "new adventurer" panel: attributes and, in "arma", the
## starting weapon (any weapon id, "" for bare fists) instead of the sword.
func start_character(values: Dictionary) -> void:
	sheet.reset(values)
	if values.has("arma"):
		choose_weapon(str(values["arma"]))
	apply_attributes(true)
	choosing_character = false
	message("Atributos definem o seu potencial. As proficiências crescem com o uso: P mostra o progresso.", 7)

## Swaps the starting sword for the chosen weapon (bows and crossbows come with
## ammunition); the weapon takes the sword's place in the quick bar.
func choose_weapon(id: String) -> void:
	if id != "" and not Items.DATA.get(id, {}).has("style"):
		return
	var slot: int = quick_bar.slot_of("sword")
	if slot >= 0 and id != "sword":
		quick_bar.remove(slot)
		if id != "":
			quick_bar.assign(slot, id)
	if inventory.count("sword") > 0 and id != "sword":
		inventory.remove("sword", inventory.count("sword"))
	if id == "":
		inventory.unequip()
	else:
		if inventory.count(id) == 0:
			inventory.add(id)
		var ammo: String = str(Items.DATA[id].get("ammo", ""))
		if ammo != "" and inventory.count(ammo) == 0:
			inventory.add(ammo, UiCreationPanel.starting_ammo())
		inventory.equip(id)
	if player:
		player.refresh_weapon()

# --- habilidade keys ---------------------------------------------------------------

func load_technique_keys() -> void:
	technique_keys = InputSetup.TECHNIQUE_KEYS.duplicate()
	var saved = load_setting("teclas", "habilidades", [])
	if saved is Array:
		for i in mini(saved.size(), technique_keys.size()):
			var code = saved[i]
			if (code is int or code is float) and InputSetup.reserved(int(code)) == "" and not int(code) in technique_keys.slice(0, i):
				technique_keys[i] = int(code)

## Bar position used by a key, or -1.
func technique_slot_for_key(code: int) -> int:
	return technique_keys.find(code)

## Binds a key to bar position `slot`. Returns "" when done, else why not.
## A key already on another position swaps with it.
func set_technique_key(slot: int, code: int) -> String:
	if slot < 0 or slot >= technique_keys.size():
		return "Posição inválida."
	var why: String = InputSetup.reserved(code)
	if why != "":
		return "%s já é usada: %s." % [InputSetup.key_name(code), why]
	var other: int = technique_slot_for_key(code)
	if other >= 0 and other != slot:
		technique_keys[other] = technique_keys[slot]
	technique_keys[slot] = code
	save_setting("teclas", "habilidades", technique_keys.duplicate())
	if ui:
		ui.refresh_technique_keys()
	return ""

func technique_key_name(slot: int) -> String:
	return InputSetup.key_name(int(technique_keys[slot])) if slot >= 0 and slot < technique_keys.size() else "?"

func on_dodged(amount: float) -> void:
	sheet.award("acrobacia", amount * 0.8, floor)

## A blow on the adventurer: what the guard held trains Bloqueio, what the armor absorbed trains its branch.
func on_hit_taken(blocked: float, absorbed: float) -> void:
	if blocked > 0:
		sheet.award("bloqueio", blocked * 0.8, floor)
	var branch: String = CharacterSheet.armor_branch(inventory.armor)
	if absorbed > 0 and branch != "":
		sheet.award(branch, absorbed, floor)

## A monster is hunting the adventurer: techniques cannot be changed now.
func in_combat() -> bool:
	if is_safe():
		return false
	for e in enemies:
		if e.alive and e.aggro:
			return true
	return false

## Each objeto in a habilidade trains the branch that gives it.
func on_technique_used(form_id: String) -> void:
	for id in techniques.objects(form_id):
		var branch: String = Techniques.object_branch(id)
		if branch != "":
			sheet.award(branch, Techniques.rule("xp_por_objeto", 1.5), floor)

## Running trains Atletismo, mostly when something is chasing.
func on_sprint(distance: float) -> void:
	if not sheet.enabled:
		return
	var chased: bool = false
	for e in enemies:
		if e.alive and e.aggro:
			chased = true
			break
	sheet.award("atletismo", distance * (0.15 if chased else 0.03), floor)

## Sneaking close to a monster that has not noticed you trains Furtividade (limited per monster).
func on_sneak_near(enemy, delta: float) -> void:
	if not sheet.enabled or enemy.sneak_budget <= 0:
		return
	var gain: float = minf(enemy.sneak_budget, 2.0 * delta * (1.0 + 0.25 * (enemy.level - 1)))
	enemy.sneak_budget -= gain
	sheet.award("furtividade", gain, enemy.level)

const LOCK_NAMES := ["", "simples", "média", "difícil", "de mestre"]

## Tries to open a locked chest with a lockpick. roll and break_roll: 0..1 to
## fix the dice (tests), -1 for random.
func attempt_lockpick(container: Dictionary, roll: float = -1.0, break_roll: float = -1.0) -> bool:
	var difficulty: int = int(container.get("lock", 0))
	if difficulty <= 0:
		return true
	var tool: String = lockpick_tool()
	if tool == "":
		message("Fechadura %s. Você precisa de uma gazua." % LOCK_NAMES[difficulty], 3)
		return false
	var spec: Dictionary = Items.DATA[tool]["arrombar"]
	var tool_name: String = str(Items.info(tool).get("name", tool))
	var value: float = randf() if roll < 0 else roll
	var scale: float = 1.0 + 0.25 * (floor - 1)
	if value < pick_chance_with(tool, difficulty):
		container.erase("lock")
		sheet.award("arrombamento", 12.0 * difficulty * scale, floor)
		sound.play_at("loot", player.global_position, 0.7)
		if spec.get("sempre", false):
			inventory.remove(tool)
			message("%s abriu e ficou presa na fechadura." % tool_name, 2.5)
		else:
			message("A fechadura cedeu.", 2)
		if ui:
			ui.open_inventory(container)
		return true
	sheet.award("arrombamento", 3.0 * difficulty * scale, floor)
	var snap: float = randf() if break_roll < 0 else break_roll
	if snap < sheet.pick_break_chance() * float(spec.get("quebra", 1.0)):
		inventory.remove(tool)
		message("%s quebrou. Restam %d." % [tool_name, inventory.count(tool)], 2.5)
	else:
		message("Não abriu. Tente de novo.", 2)
	if ui:
		ui.refresh_inventory()
	return false

## Containers and monsters from the floor description.
func setup_content() -> void:
	for entry in layout.world["containers"]:
		add_loot(str(tr(entry["name"])), DungeonLayout.cell(entry["cell"]), entry["items"], entry.get("chest", true), entry["id"], int(entry.get("lock", 0)))
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
	place_merchant()

## The merchant goes in the entrance room with a fresh stock for this floor
## (a saved stock replaces it afterwards, in apply_floor_state or the save).
func place_merchant() -> void:
	merchant = null
	shop_stock = ShopSystem.roll_stock(seed, floor)
	var cell: Vector2i = ShopSystem.merchant_cell(self)
	if cell.x < 0:
		return
	layout.pathfinder.set_point_solid(cell, true)
	merchant = WorldBuilder.merchant(self, layout.to_world(cell), ShopSystem.room_center(self))

func near_merchant() -> bool:
	return merchant != null and is_instance_valid(merchant) and player.position.distance_to(merchant.position) < ShopSystem.REACH

func add_loot(title: String, cell: Vector2i, items: Dictionary, chest: bool = true, id: String = "", lock: int = 0) -> Dictionary:
	return ContainerSystem.add(self, title, cell, items, chest, id, lock)

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
	elif event.is_action_pressed("sneak"):
		player.toggle_sneak()
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

## Marks every floor cell of this floor as explored (the sketched map item).
## Returns how many cells were new.
func reveal_floor() -> int:
	var added: int = 0
	for cell in layout.floors:
		if not discovered.has(cell):
			discovered[cell] = true
			added += 1
	return added

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

## Fixed world only: the monster whose death is the goal ("guardian" in the world file).
func fixed_guardian() -> DungeonEnemy:
	var id: String = str(layout.world.get("guardian", ""))
	for e in enemies:
		if e.uid == id:
			return e
	return null

## Fixed world only: the guardian is dead, so going back to the shelter ends the run.
func fixed_goal_done() -> bool:
	var g := fixed_guardian()
	return not generated and g != null and not g.alive

func objective_text() -> String:
	if not generated:
		return "Volte ao abrigo" if fixed_goal_done() else "Derrote o carcereiro"
	if boss_alive():
		return "Derrote o capataz do %dº andar" % floor
	return "Desça ao %dº andar ou volte ao abrigo" % (floor + 1)

# --- floors ------------------------------------------------------------------------

func snapshot_floor() -> Dictionary:
	var cs: Array = []
	for c in containers:
		cs.append({"id": c["id"], "name": c["name"], "pos": c["pos"], "items": c["items"].duplicate(), "chest": c["chest"], "lock": int(c.get("lock", 0))})
	var es: Dictionary = {}
	for e in enemies:
		es[e.uid] = {"health": e.health, "alive": e.alive, "pos": [e.position.x, e.position.z], "stuck": e.stuck.duplicate()}
	return {"containers": cs, "enemies": es, "shop": shop_stock.duplicate()}

func apply_floor_state(state: Dictionary) -> void:
	for c in containers:
		c["node"].queue_free()
	containers.clear()
	for data in state.get("containers", []):
		var copy: Dictionary = data.duplicate(true)
		containers.append(copy)
		WorldBuilder.add_container(self, copy)
	if state.get("shop") is Dictionary:
		shop_stock = ShopSystem.clean_stock(state["shop"])
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
		message("%dº andar. %s" % [n, "A descida fica na sala do capataz." if boss_alive() else "Este andar já foi vencido."], 5)
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

## What the weapon fires now: the chosen ammunition if it fits and is in the
## backpack, else the first it takes that is in the backpack, else its main one
## ("" for weapons without ammunition).
func ammo_for(weapon: Dictionary) -> String:
	var list: Array = Items.ammo_list(weapon)
	if list.is_empty():
		return ""
	if chosen_ammo in list and inventory.count(chosen_ammo) > 0:
		return chosen_ammo
	for id in list:
		if inventory.count(id) > 0:
			return id
	return list[0]

## The lockpicking tool used next (Items.lockpicks order), "" when there is none.
func lockpick_tool() -> String:
	for id in Items.lockpicks():
		if inventory.count(id) > 0:
			return id
	return ""

## Chance of opening a lock of this difficulty with this tool.
func pick_chance_with(tool: String, difficulty: int) -> float:
	var spec: Dictionary = Items.DATA.get(tool, {}).get("arrombar", {})
	if spec.get("sempre", false):
		return 1.0
	return minf(0.98, sheet.pick_chance(difficulty) + float(spec.get("bonus", 0.0)))

func interaction_text() -> String:
	if has_shelter() and player.position.distance_to(camp_position) < 1.6:
		if fixed_goal_done():
			return "E   VOLTAR PARA CASA"
		return "E   DESCANSAR E SALVAR NO ABRIGO"
	if near_merchant():
		return "E   LOJA  ·  comprar e vender com o mercador"
	if generated:
		if _near(stairs_up_cell()):
			return "E   SUBIR  ·  para o %dº andar" % (floor - 1)
		if _near(stairs_down_cell()):
			return ("E   DESCER  ·  trancada até o capataz cair" if boss_alive() else "E   DESCER  ·  para o %dº andar" % (floor + 1))
	var loot = nearest_container()
	if not loot.is_empty():
		var difficulty: int = int(loot.get("lock", 0))
		if difficulty > 0:
			var tool: String = lockpick_tool()
			if tool == "":
				return "E   TRANCADO  ·  %s  ·  fechadura %s, precisa de gazua" % [loot["name"], LOCK_NAMES[difficulty]]
			return "E   ARROMBAR  ·  %s  ·  fechadura %s, %d%% de chance" % [loot["name"], LOCK_NAMES[difficulty], roundi(pick_chance_with(tool, difficulty) * 100)]
		var empty: bool = loot["items"].is_empty()
		return ("E   ABRIR  ·  " if empty else "E   VASCULHAR  ·  ") + loot["name"] + ("  (vazio)" if empty else "")
	return ""

func interact() -> void:
	if has_shelter() and player.position.distance_to(camp_position) < 1.6:
		if fixed_goal_done():
			won = true
			save_game(false)
			end_run(true)
			return
		player.stamina = player.max_stamina
		save_game(false)
		message("Expedição salva. Coma e cuide dos ferimentos antes de sair.")
		return
	if near_merchant():
		if ui:
			ui.open_shop()
		return
	if generated:
		if _near(stairs_up_cell()):
			change_floor(floor - 1, false)
			return
		if _near(stairs_down_cell()):
			if boss_alive():
				message("A descida está trancada. Derrote o capataz deste andar.", 3)
			else:
				change_floor(floor + 1, true)
			return
	var loot = nearest_container()
	if not loot.is_empty():
		if int(loot.get("lock", 0)) > 0:
			attempt_lockpick(loot)
			return
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
		message("O capataz caiu. A descida para o %dº andar está aberta." % (floor + 1), 6)
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
		file.store_string(JSON.stringify({"version": 1, "seed": seed, "deepest": deepest, "knowledge": SaveSystem.pack_knowledge(knowledge), "tecnicas": {"configs": techniques.configs.duplicate(true)}}))
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
	# The exported game does not carry the tests.
	if not ResourceLoader.exists("res://tests/runtime_test.gd"):
		print("Os testes não vão no jogo exportado; rode-os pelo projeto.")
		get_tree().quit(2)
		return
	var harness = load("res://tests/runtime_test.gd").new()
	add_child(harness)
	harness.run(self, "--capture" in OS.get_cmdline_user_args())

func run_labyrinth_tests() -> void:
	if not ResourceLoader.exists("res://tests/labyrinth_test.gd"):
		print("Os testes não vão no jogo exportado; rode-os pelo projeto.")
		get_tree().quit(2)
		return
	var harness = load("res://tests/labyrinth_test.gd").new()
	add_child(harness)
	harness.run(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player):
		if not test_mode and player.health > 0 and not ended:
			save_game(false)
		get_tree().quit()
