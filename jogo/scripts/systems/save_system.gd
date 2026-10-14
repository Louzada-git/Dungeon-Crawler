extends RefCounted
class_name SaveSystem
## Expedition save (JSON, format version 2): the current floor in full, the
## state of other visited floors, the labyrinth seed and the explored map.
## Knowledge that survives death is also written apart by main.write_knowledge().

const VERSION := 2

static func write(game, notify_user: bool = true) -> bool:
	if game.ended and not game.won:
		return false
	var loot_data: Array = []
	for loot in game.containers:
		loot_data.append({"id": loot.get("id", ""), "name": loot["name"], "pos": loot["pos"], "items": loot["items"], "chest": loot["chest"], "lock": int(loot.get("lock", 0))})
	var enemy_data: Array = []
	for enemy in game.enemies:
		enemy_data.append({"id": enemy.uid, "health": enemy.health, "alive": enemy.alive, "pos": [enemy.position.x, enemy.position.z], "stuck": enemy.stuck.duplicate()})
	var explored: Array = []
	for cell in game.discovered:
		explored.append([cell.x, cell.y])
	var p = game.player
	var data := {"sheet": game.sheet.snapshot(), "version": VERSION, "mode": "labirinto" if game.generated else "fixo", "seed": game.seed, "floor": game.floor, "deepest": game.deepest, "seals": game.seals_delivered, "floors": _pack_floors(game), "knowledge": pack_knowledge(game.knowledge), "world": game.layout.world.get("id", ""), "inventory": game.inventory.snapshot(), "player": {"pos": [p.position.x, p.position.z], "health": p.health, "stamina": p.stamina, "food": p.food, "bleeding": p.bleeding}, "containers": loot_data, "enemies": enemy_data, "explored": explored, "kills": game.kills, "hits": game.hits_received, "won": game.won}
	var file := FileAccess.open(game.save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		game.message("Não foi possível salvar a expedição.")
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	if DirAccess.rename_absolute(game.save_path + ".tmp", game.save_path) != OK:
		game.message("Falha ao concluir o salvamento.")
		return false
	if notify_user:
		game.message("Expedição salva.")
	return true

static func read(game) -> bool:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	if not valid(game, raw):
		game.message("O save não pôde ser lido. Iniciando uma expedição nova.")
		return false
	# The adventurer first: Força sets how much the backpack can hold.
	if raw.has("sheet"):
		game.sheet.restore(raw["sheet"])
	game.apply_attributes(false)
	if not game.inventory.restore(raw["inventory"]):
		return false
	var p = game.player
	var pd: Dictionary = raw["player"]
	p.position = Vector3(pd["pos"][0], 0, pd["pos"][1])
	p.health = pd["health"]
	p.stamina = pd["stamina"]
	p.food = pd["food"]
	p.bleeding = pd["bleeding"]
	p.reset_transients()
	for loot in game.containers:
		loot["node"].queue_free()
	game.containers.clear()
	for data in raw["containers"]:
		if str(data.get("id", "")) == "":
			data["id"] = _legacy_id(game, data)
		game.containers.append(data)
		WorldBuilder.add_container(game, data)
	for i in game.enemies.size():
		var data: Dictionary = raw["enemies"][i]
		var enemy = game.enemies[i]
		# Match by id when the save has ids; older saves follow the order.
		if str(data.get("id", "")) != "" and data["id"] != enemy.uid:
			for other in raw["enemies"]:
				if other.get("id", "") == enemy.uid:
					data = other
					break
		restore_enemy(enemy, data)
	if game.generated:
		game.floor_states = _parse_floors(raw.get("floors", {}))
		var known: Dictionary = parse_knowledge(raw.get("knowledge", {}))
		for f in known:
			if f != game.floor:
				game.knowledge[f] = known[f]
		game.seals_delivered = int(raw.get("seals", 0))
		game.deepest = maxi(int(raw.get("deepest", 1)), game.floor)
	game.discovered.clear()
	for cell in raw["explored"]:
		game.discovered[Vector2i(cell[0], cell[1])] = true
	game.kills = raw["kills"]
	game.hits_received = raw["hits"]
	game.won = raw["won"]
	game.last_discover = Vector2i(-99, -99)
	game.camera_rig.position = p.position
	game.message("Expedição retomada. I abre a mochila; M abre o mapa.", 6)
	return true

static func restore_enemy(enemy, data: Dictionary) -> void:
	enemy.health = data["health"]
	enemy.alive = data["alive"]
	enemy.position = Vector3(data["pos"][0], 0, data["pos"][1])
	enemy.collision_layer = 4 if enemy.alive else 0
	enemy.collision_mask = 7 if enemy.alive else 0
	enemy.windup = 0
	enemy.aggro = false
	enemy.memory = 0
	enemy.stagger = 0
	enemy.attack_recovery = 0
	enemy.telegraph.hide()
	enemy.stuck = {}
	var stuck = data.get("stuck", {})
	if stuck is Dictionary:
		for key in stuck:
			if Items.DATA.has(key):
				enemy.stuck[key] = int(stuck[key])
	if not enemy.alive:
		enemy.health_label.visible = false
		Visuals.play(enemy.animator, "die", false)

static func pack_knowledge(knowledge: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for f in knowledge:
		var cells: Array = []
		for c in knowledge[f]:
			cells.append([c.x, c.y])
		out[str(f)] = cells
	return out

static func parse_knowledge(raw) -> Dictionary:
	var out: Dictionary = {}
	if not raw is Dictionary:
		return out
	for key in raw:
		var cells: Dictionary = {}
		if raw[key] is Array:
			for c in raw[key]:
				if c is Array and c.size() == 2:
					cells[Vector2i(int(c[0]), int(c[1]))] = true
		out[int(key)] = cells
	return out

static func _pack_floors(game) -> Dictionary:
	var out: Dictionary = {}
	for f in game.floor_states:
		if f != game.floor:
			out[str(f)] = game.floor_states[f]
	return out

static func _parse_floors(raw) -> Dictionary:
	var out: Dictionary = {}
	if raw is Dictionary:
		for key in raw:
			if raw[key] is Dictionary:
				out[int(key)] = raw[key]
	return out

## Saves written before containers had ids: match the world description by position.
static func _legacy_id(game, data: Dictionary) -> String:
	var cell: Vector2i = game.layout.to_cell(Vector3(data["pos"][0], 0, data["pos"][1]))
	if data.get("chest", true):
		for entry in game.layout.world["containers"]:
			if DungeonLayout.cell(entry["cell"]) == cell:
				return entry["id"]
	return ContainerSystem.unique_id(game)

static func valid(game, raw) -> bool:
	if not raw is Dictionary or raw.get("version") != VERSION:
		return false
	for key in ["inventory", "player"]:
		if not raw.get(key) is Dictionary:
			return false
	for key in ["containers", "enemies", "explored"]:
		if not raw.get(key) is Array:
			return false
	if raw["enemies"].size() != game.enemies.size():
		return false
	if game.generated and (int(raw.get("seed", -1)) != game.seed or int(raw.get("floor", -1)) != game.floor):
		return false
	var p: Dictionary = raw["player"]
	if not valid_pos(game, p.get("pos")):
		return false
	for key in ["health", "stamina", "food"]:
		if not p.get(key) is float and not p.get(key) is int:
			return false
		if not is_finite(float(p[key])) or p[key] < (0.01 if key == "health" else 0.0) or p[key] > 400:
			return false
	if not p.get("bleeding") is bool or not raw.get("won") is bool:
		return false
	for key in ["kills", "hits"]:
		if not (raw.get(key) is float or raw.get(key) is int) or raw[key] < 0:
			return false
	for e in raw["enemies"]:
		if not e is Dictionary or not valid_pos(game, e.get("pos")) or not e.get("alive") is bool:
			return false
		if not (e.get("health") is float or e.get("health") is int) or not is_finite(float(e["health"])):
			return false
	for loot in raw["containers"]:
		if not loot is Dictionary or not valid_pos(game, loot.get("pos")) or not loot.get("items") is Dictionary or not loot.get("name") is String or not loot.get("chest") is bool:
			return false
		if loot.has("id") and not loot["id"] is String:
			return false
		if loot.has("lock") and (not (loot["lock"] is int or loot["lock"] is float) or loot["lock"] < 0 or loot["lock"] > 4):
			return false
		for id in loot["items"]:
			var n = loot["items"][id]
			if not Items.DATA.has(id) or not (n is float or n is int) or n < 1 or n > 10000 or n != int(n):
				return false
	for cell in raw["explored"]:
		if not cell is Array or cell.size() != 2 or not (cell[0] is float or cell[0] is int) or not (cell[1] is float or cell[1] is int):
			return false
	var check := InventoryData.new()
	if raw.has("sheet"):
		var sheet := CharacterSheet.new()
		if not sheet.restore(raw["sheet"]):
			return false
		check.capacity = sheet.capacity()
	return check.restore(raw["inventory"])

static func valid_pos(game, pos) -> bool:
	if not pos is Array or pos.size() != 2:
		return false
	for value in pos:
		if not (value is float or value is int) or not is_finite(float(value)):
			return false
	return game.layout.is_floor(game.layout.to_cell(Vector3(pos[0], 0, pos[1])))
