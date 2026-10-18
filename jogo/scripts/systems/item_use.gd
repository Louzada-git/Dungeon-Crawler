extends RefCounted
class_name ItemUse
## Using items from the backpack: equip weapons, eat, treat wounds.
## Effects come from the item data (food, stamina_gain, heal, stops_bleeding,
## revela_mapa). Food that also has "heal" heals when eaten.

static func use(game: DungeonGame, id: String) -> bool:
	var inventory = game.inventory
	var player = game.player
	if inventory.count(id) <= 0:
		return false
	var data: Dictionary = Items.info(id)
	if data.has("protection"):
		if inventory.armor == id:
			inventory.take_off()
			game.message("Tirou: " + data["name"])
		else:
			inventory.wear(id)
			game.message("Vestiu: %s. Proteção de %d%%." % [data["name"], roundi(game.sheet.armor_protection(id) * 100)])
		return true
	if data.has("damage"):
		inventory.equip(id)
		game.message("Equipado: " + data["name"])
		return true
	var sheet = game.sheet
	if data.has("food"):
		var wants_food: bool = player.food < 100
		var wants_stamina: bool = float(data.get("stamina_gain", 0.0)) >= 30.0 and player.stamina < player.max_stamina
		var wants_heal: bool = data.has("heal") and player.health < player.max_health
		if not (wants_food or wants_stamina or wants_heal):
			game.message("Você já está alimentado.")
			return false
		player.food = minf(100, player.food + float(data["food"]))
		player.stamina = minf(player.max_stamina, player.stamina + float(data.get("stamina_gain", 0.0)))
		if data.has("heal"):
			player.health = minf(player.max_health, player.health + float(data["heal"]) * sheet.heal_mult())
	elif data.has("heal"):
		if player.health >= player.max_health and not player.bleeding:
			game.message("Você não precisa de tratamento agora.")
			return false
		var was_bleeding: bool = player.bleeding
		if data.get("stops_bleeding", false):
			player.bleeding = false
		var before: float = player.health
		player.health = minf(player.max_health, player.health + float(data["heal"]) * sheet.heal_mult())
		# Treating a real wound trains Tratamento.
		sheet.award("tratamento", (player.health - before) * 0.5 + (8.0 if was_bleeding and not player.bleeding else 0.0))
	elif data.get("revela_mapa", false):
		if game.reveal_floor() == 0:
			game.message("Este andar já está todo no mapa.")
			return false
		game.message("O andar inteiro agora aparece no mapa  [M].", 3)
	else:
		return false
	inventory.remove(id)
	game.ui.refresh_inventory()
	return true
