extends RefCounted
class_name ShopSystem
## The merchant in the entrance room of every floor (data/loja.json): what he
## sells there, prices, buying and selling for coins, and where he stands.
## Each floor keeps its own stock (floor state and save); what you sell to him
## goes into it, so you can buy it back.

const PATH := "res://data/loja.json"
## How close the player must be to talk to him.
const REACH := 2.3
static var DATA: Dictionary = _load()

static func _load() -> Dictionary:
	return DataFile.read(PATH)

## Stock of a floor: everything in "sempre" plus the "sorteio" rolls allowed at
## that depth. Same labyrinth seed and floor, same stock.
static func roll_stock(labyrinth_seed: int, floor_number: int) -> Dictionary:
	var stock: Dictionary = {}
	for entry in DATA.get("sempre", []):
		stock[str(entry[0])] = int(entry[1])
	var table: Dictionary = DATA.get("sorteio", {})
	var entries: Array = table.get("entries", []).filter(func(e): return int(e[4]) <= floor_number)
	if entries.is_empty():
		return stock
	var rng := RandomNumberGenerator.new()
	rng.seed = LabyrinthGenerator.floor_seed(labyrinth_seed, floor_number) ^ 24301
	var total: float = 0.0
	for entry in entries:
		total += float(entry[1])
	var rolls: Array = table.get("rolls", [5, 8])
	for i in rng.randi_range(int(rolls[0]), int(rolls[1])):
		var pick: float = rng.randf() * total
		for entry in entries:
			pick -= float(entry[1])
			if pick <= 0.0:
				var id: String = str(entry[0])
				stock[id] = int(stock.get(id, 0)) + rng.randi_range(int(entry[2]), int(entry[3]))
				break
	return stock

## A stock read from a save: known items with positive amounts only.
static func clean_stock(raw) -> Dictionary:
	var out: Dictionary = {}
	if raw is Dictionary:
		for id in raw:
			if Items.DATA.has(id) and (raw[id] is int or raw[id] is float) and int(raw[id]) > 0:
				out[str(id)] = int(raw[id])
	return out

## What the merchant charges: the item's value, a little more on each floor down.
static func buy_price(floor_number: int, id: String) -> int:
	var value: float = float(Items.DATA.get(id, {}).get("valor", 0))
	if value <= 0.0 or id == "coin":
		return 0
	return maxi(1, ceili(value * (1.0 + float(DATA.get("compra", 0.1)) * (floor_number - 1))))

## What he pays: a fraction of the value (0 = he does not buy it).
static func sell_price(id: String) -> int:
	if id == "coin":
		return 0
	return floori(float(Items.DATA.get(id, {}).get("valor", 0)) * float(DATA.get("venda", 0.4)))

## How many of an item the player can sell now: the weapon in hand and the
## armor worn stay with the player.
static func sellable(game: DungeonGame, id: String) -> int:
	if sell_price(id) <= 0:
		return 0
	var n: int = game.inventory.count(id)
	if id == game.inventory.equipped or id == game.inventory.armor:
		n -= 1
	return maxi(0, n)

## Buys up to "amount"; returns how many came (stock, coins and backpack room permitting).
static func buy(game: DungeonGame, id: String, amount: int = 1) -> int:
	var price: int = buy_price(game.current_floor, id)
	if price <= 0:
		return 0
	var n: int = mini(amount, int(game.shop_stock.get(id, 0)))
	@warning_ignore("integer_division")
	n = mini(n, game.inventory.count("coin") / price)
	if n <= 0:
		return 0
	var got: int = game.inventory.add(id, n)
	if got <= 0:
		return 0
	game.inventory.remove("coin", got * price)
	game.shop_stock[id] = int(game.shop_stock[id]) - got
	if int(game.shop_stock[id]) <= 0:
		game.shop_stock.erase(id)
	return got

## Sells up to "amount"; returns how many went.
static func sell(game: DungeonGame, id: String, amount: int = 1) -> int:
	var n: int = mini(amount, sellable(game, id))
	if n <= 0:
		return 0
	game.inventory.remove(id, n)
	game.inventory.add("coin", n * sell_price(id))
	game.shop_stock[id] = int(game.shop_stock.get(id, 0)) + n
	return n

## Where the merchant stands: in the entrance room (the one with the arrival
## point), against a wall, not in a doorway, away from the arrival, the shelter
## fire, the stairs and the chests; nearest to the arrival among those.
## (-1, -1) when the room has no place.
static func merchant_cell(game: DungeonGame) -> Vector2i:
	var layout = game.layout
	var room := Rect2i()
	for r in layout.rooms:
		if r["rect"].has_point(layout.spawn):
			room = r["rect"]
			break
	if room.size == Vector2i.ZERO:
		return Vector2i(-1, -1)
	var busy: Array = [layout.spawn, layout.camp, layout.camp_exit]
	for key in ["stairs_up", "stairs_down"]:
		if layout.world.get(key) != null:
			busy.append(DungeonLayout.cell(layout.world[key]))
	for c in game.containers:
		busy.append(layout.to_cell(Vector3(c["pos"][0], 0, c["pos"][1])))
	for strict in [true, false]:
		var best := Vector2i(-1, -1)
		var best_score: float = -INF
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				var cell := Vector2i(x, y)
				if not layout.is_floor(cell) or layout.pathfinder.is_point_solid(cell):
					continue
				var crowded: bool = false
				for b in busy:
					var gap: int = maxi(absi(b.x - cell.x), absi(b.y - cell.y))
					if gap <= (1 if strict else 0):
						crowded = true
				if crowded:
					continue
				var walls: int = 0
				var doorway: bool = false
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var nb: Vector2i = cell + d
					if not layout.is_floor(nb):
						walls += 1
					elif not room.has_point(nb):
						doorway = true
				if doorway or (strict and walls == 0):
					continue
				var score: float = walls * 10.0 - Vector2(cell).distance_to(Vector2(layout.spawn))
				if score > best_score:
					best_score = score
					best = cell
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)

## Centre of the entrance room, for the merchant to face.
static func room_center(game: DungeonGame) -> Vector3:
	for r in game.layout.rooms:
		if r["rect"].has_point(game.layout.spawn):
			return game.layout.to_world(r["rect"].get_center())
	return game.layout.to_world(game.layout.spawn)
