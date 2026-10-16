extends RefCounted
class_name QuickBar
## Quick bar at the bottom of the screen: 9 slots on keys 1 to 9, each pointing
## at an item of any kind. It points at the kind, not at one unit: the slot
## stays when the stack runs out (it shows 0) and works again when more turn
## up. An item sits in one slot at a time. Goes in the save; a new adventurer
## starts with the weapon, rations and bandages.

signal changed

const SIZE := 9

var slots: Array = []

func _init() -> void:
	clear()

func clear() -> void:
	slots = []
	for i in SIZE:
		slots.append("")

## The starting layout: weapon in 1 (none for the fists), rations in 2, bandages in 3.
func defaults(weapon: String = "sword") -> void:
	clear()
	slots[0] = weapon
	slots[1] = "ration"
	slots[2] = "bandage"
	changed.emit()

func at(slot: int) -> String:
	return str(slots[slot]) if slot >= 0 and slot < SIZE else ""

func slot_of(id: String) -> int:
	return slots.find(id) if id != "" else -1

func first_free() -> int:
	return slots.find("")

## Puts an item in a slot (moving it out of the slot it was in).
func assign(slot: int, id: String) -> void:
	if slot < 0 or slot >= SIZE or (id != "" and not Items.DATA.has(id)):
		return
	var before: int = slot_of(id)
	if before >= 0:
		slots[before] = ""
	slots[slot] = id
	changed.emit()

func remove(slot: int) -> void:
	if slot >= 0 and slot < SIZE and slots[slot] != "":
		slots[slot] = ""
		changed.emit()

## What pressing the slot does with this item ("Equipar", "Comer"...); "" when nothing.
static func action_name(game, id: String) -> String:
	if id == "":
		return ""
	var data: Dictionary = Items.info(id)
	if data.has("damage"):
		return "Guardar" if game.inventory.equipped == id else "Equipar"
	if data.has("protection"):
		return "Tirar" if game.inventory.armor == id else "Vestir"
	if data.has("food"):
		return "Comer"
	if data.has("heal"):
		return "Aplicar"
	return ""

## Presses a slot: equips or puts away a weapon, wears or takes off armor, eats,
## treats. Returns true when something happened.
func use(game, slot: int) -> bool:
	var id: String = at(slot)
	if id == "":
		game.message("Espaço %d vazio. Arraste um item da mochila para ele, ou selecione o item na mochila e aperte %d." % [slot + 1, slot + 1], 3)
		return false
	var data: Dictionary = Items.info(id)
	var name: String = str(data.get("name", id))
	if game.inventory.count(id) <= 0:
		game.message("Sem %s na mochila." % name.to_lower(), 2)
		return false
	if data.has("damage") and game.inventory.equipped == id:
		game.inventory.unequip()
		game.message("Guardou: %s. Punhos." % name, 2)
		return true
	if data.get("tag", "") == "MUNICAO":
		# Ammunition on the bar picks what the weapon fires.
		game.chosen_ammo = id
		var held: String = game.inventory.equipped
		if held != "" and Items.fires(held, id):
			game.message("Atirando: %s." % name.to_lower(), 2)
		else:
			var users: PackedStringArray = []
			for weapon in Items.DATA:
				if Items.fires(weapon, id):
					users.append(str(Items.info(weapon).get("name", weapon)).to_lower())
			game.message("Escolhida: %s. Serve em: %s." % [name.to_lower(), ", ".join(users)], 2.5)
		changed.emit()
		return true
	if action_name(game, id) == "":
		game.message("%s não se usa da barra." % name, 2)
		return false
	return game.use_item(id)

func snapshot() -> Array:
	return slots.duplicate()

## Tolerant: unknown items and odd values become empty slots.
func restore(data) -> void:
	clear()
	if data is Array:
		for i in mini(data.size(), SIZE):
			var id: String = str(data[i]) if data[i] is String else ""
			if Items.DATA.has(id) and slot_of(id) < 0:
				slots[i] = id
	changed.emit()
