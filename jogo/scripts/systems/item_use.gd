extends RefCounted
class_name ItemUse
## Using items from the backpack: equip weapons, eat, treat wounds.
## Effects come from the item data (food, stamina_gain, heal, stops_bleeding).

static func use(game, id: String) -> bool:
	var inventory = game.inventory
	var player = game.player
	if inventory.count(id) <= 0:
		return false
	var data: Dictionary = Items.info(id)
	if data.has("damage"):
		inventory.equip(id)
		game.message("Equipado: " + data["name"])
		return true
	if data.has("food"):
		if player.food >= 100:
			game.message("Você já está alimentado.")
			return false
		player.food = minf(100, player.food + float(data["food"]))
		player.stamina = minf(100, player.stamina + float(data.get("stamina_gain", 0.0)))
	elif data.has("heal"):
		if player.health >= 100 and not player.bleeding:
			game.message("Você não precisa de tratamento agora.")
			return false
		if data.get("stops_bleeding", false):
			player.bleeding = false
		player.health = minf(100, player.health + float(data["heal"]))
	else:
		return false
	inventory.remove(id)
	game.ui.refresh_inventory()
	return true
