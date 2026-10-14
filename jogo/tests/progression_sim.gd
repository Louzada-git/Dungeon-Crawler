extends SceneTree
# Simulates proficiency pace with the real CharacterSheet over generated floors.
#   godot --headless --path . -s res://tests/progression_sim.gd
# Each floor: 70% of its monsters and the boss killed with one weapon.

class FakeEnemy:
	var kind: String
	var level: int
	var maximum_health: float
	func _init(k: String, l: int) -> void:
		kind = k
		level = l
		maximum_health = float(EnemyTypes.info(k).get("health", 65.0)) * LabyrinthGenerator.scaling(l)["health"]

func floor_kills(seed: int, floor: int) -> Array:
	var desc: Dictionary = LabyrinthGenerator.generate(seed, floor)
	var regular: Array = []
	var bosses: Array = []
	for e in desc["enemies"]:
		if EnemyTypes.info(e["type"]).get("boss", false):
			bosses.append(e["type"])
		else:
			regular.append(e["type"])
	return regular.slice(0, roundi(regular.size() * 0.7)) + bosses

func play(sheet: CharacterSheet, path: Array, kinds: Array, floor: int) -> void:
	for kind in kinds:
		var e := FakeEnemy.new(kind, floor)
		sheet.award_damage(e, e.maximum_health, path)

func _initialize() -> void:
	var paths := {"Adaga": CharacterSheet.path_of("adaga"), "Katana": CharacterSheet.path_of("katana"), "Martelo": CharacterSheet.path_of("martelo"), "Punhos": CharacterSheet.path_of("")}
	var sheets: Dictionary = {}
	for name in paths:
		sheets[name] = CharacterSheet.new()
	var strong := CharacterSheet.new()
	strong.reset({"forca": 9, "vigor": 4, "agilidade": 4, "destreza": 3})
	var mixed := CharacterSheet.new()
	print("SIM andar | " + " | ".join(paths.keys()) + " | Martelo com Força 9 | Espada reta → Katana no 3º")
	for floor in range(1, 8):
		var kills: Array = floor_kills(777, floor)
		for name in paths:
			play(sheets[name], paths[name], kills, floor)
		play(strong, CharacterSheet.path_of("martelo"), kills, floor)
		play(mixed, CharacterSheet.path_of("sword") if floor < 3 else CharacterSheet.path_of("katana"), kills, floor)
		var cells: PackedStringArray = []
		for name in paths:
			var s: CharacterSheet = sheets[name]
			cells.append("%d (+%d%%)" % [s.mastery(paths[name]), roundi((s.damage_mult(paths[name]) - 1) * 100)])
		cells.append("%d" % strong.mastery(CharacterSheet.path_of("martelo")))
		cells.append("%d" % mixed.mastery(CharacterSheet.path_of("katana")))
		print("SIM %d (%d mortes) | %s" % [floor, kills.size(), " | ".join(cells)])
	# Grinding the first floor again and again.
	var grinder := CharacterSheet.new()
	var first: Array = floor_kills(777, 1)
	var line: PackedStringArray = []
	for run in range(1, 51):
		play(grinder, CharacterSheet.path_of("sword"), first, 1)
		if run in [1, 2, 5, 10, 20, 50]:
			line.append("%dx → %d" % [run, grinder.mastery(CharacterSheet.path_of("sword"))])
	print("SIM repetir o 1º andar: " + ", ".join(line))
	quit()
