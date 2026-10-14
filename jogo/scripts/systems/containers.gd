extends RefCounted
class_name ContainerSystem
## Chests and ground piles: creation with stable ids, lookup within reach,
## storing and dropping. Containers are plain dictionaries kept in game.containers:
## {id, name, pos: [x, z], items: {item_id: count}, chest: bool, node, ring}.

const REACH := 2.4

static func add(game, title: String, cell: Vector2i, items: Dictionary, chest: bool = true, id: String = "") -> Dictionary:
	var pos: Vector3 = game.layout.to_world(cell)
	var clean: Dictionary = {}
	for key in items:
		clean[key] = int(items[key])
	var data: Dictionary = {"id": id if id != "" else unique_id(game), "name": title, "pos": [pos.x, pos.z], "items": clean, "chest": chest}
	game.containers.append(data)
	WorldBuilder.add_container(game, data)
	return data

## Ids for piles created during play ("pilha_N"); world containers keep the ids of the description.
static func unique_id(game) -> String:
	var used: Dictionary = {}
	for c in game.containers:
		used[str(c.get("id", ""))] = true
	var n: int = game.containers.size()
	while used.has("pilha_%d" % n):
		n += 1
	return "pilha_%d" % n

static func position_of(container: Dictionary) -> Vector3:
	return Vector3(container["pos"][0], 0, container["pos"][1])

## Containers within reach for the inventory tabs: chests even when empty
## (items can be stored in them) and ground piles that still hold something.
static func nearby(game, reach: float = REACH) -> Array:
	var found: Array = []
	var origin: Vector3 = game.player.position
	for c in game.containers:
		if c["items"].is_empty() and not c.get("chest", true):
			continue
		var p := position_of(c)
		if p.distance_to(origin) < reach and game.clear_line(origin, p):
			found.append(c)
	found.sort_custom(func(a, b): return position_of(a).distance_squared_to(origin) < position_of(b).distance_squared_to(origin))
	return found

static func nearest(game) -> Dictionary:
	var found: Array = nearby(game)
	return found[0] if not found.is_empty() else {}

## Nearest container that still has items.
static func nearest_with_items(game) -> Dictionary:
	for c in nearby(game):
		if not c["items"].is_empty():
			return c
	return {}

static func store(game, id: String, amount: int, container: Dictionary) -> int:
	amount = mini(amount, game.inventory.count(id))
	if amount <= 0 or container.is_empty() or not game.containers.has(container):
		return 0
	if not game.inventory.remove(id, amount):
		return 0
	container["items"][id] = int(container["items"].get(id, 0)) + amount
	game.sound.play_at("loot", game.player.global_position, 0.35)
	game.message("Guardado em %s: %s ×%d." % [container["name"], Items.info(id)["name"], amount])
	game.ui.refresh_inventory()
	return amount

static func drop(game, id: String, amount: int = 1) -> bool:
	amount = mini(amount, game.inventory.count(id))
	if amount <= 0 or not game.inventory.remove(id, amount):
		return false
	# Reuse a ground pile on the same spot instead of stacking new ones.
	var pile: Dictionary = {}
	for c in game.containers:
		if not c.get("chest", true) and position_of(c).distance_to(game.player.position) < 0.9:
			pile = c
			break
	if pile.is_empty():
		add(game, str(TranslationServer.translate("RECIPIENTE_DEIXADOS")), game.layout.to_cell(game.player.position), {id: amount}, false)
	else:
		pile["items"][id] = int(pile["items"].get(id, 0)) + amount
	game.ui.refresh_inventory()
	game.message("Item deixado no chão. Use E para recuperá-lo." if amount == 1 else "%d itens deixados no chão. Use E para recuperá-los." % amount)
	return true
