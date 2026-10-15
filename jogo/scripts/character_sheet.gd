extends RefCounted
class_name CharacterSheet
## The adventurer of the current run: attributes (potential) and experience
## per proficiency branch (practice). Numbers live in data/proficiencias.json.
##
## Rules
## - An action's experience is split among the branches of its path
##   (Espadas › Katana) with shares that sum to 1: nothing is counted twice.
## - A weapon's mastery comes from the summed experience of its path, so a
##   weapon with one branch and a weapon with two grow at the same pace for
##   the same effort, and practice with one sword helps every sword.
## - The attribute of each branch sets how fast it learns and its top level.
## - Experience fades when mastery is far above the monster's floor
##   (beating weak monsters does not keep teaching).

signal level_up(branch: String, level: int)
signal perk_unlocked(branch: String, perk: Dictionary)

var attrs: Dictionary = {}
var xp: Dictionary = {}
var enabled: bool = true

func _init() -> void:
	reset()

func reset(values: Dictionary = {}) -> void:
	attrs = {}
	var start: int = int(ProficiencyTree.section("criacao").get("padrao", 5))
	for id in ProficiencyTree.ATTRIBUTE_ORDER:
		attrs[id] = int(values.get(id, start))
	xp = {}

func attr(id: String) -> int:
	return int(attrs.get(id, 5))

# --- attributes -------------------------------------------------------------------

func capacity() -> float:
	return InventoryData.CAPACITY + 1.5 * (attr("forca") - 5)

func comfort() -> float:
	return InventoryData.COMFORT + 1.0 * (attr("forca") - 5)

func max_health() -> float:
	return 100.0 + 6.0 * (attr("vigor") - 5)

func hunger_mult() -> float:
	return 1.0 - 0.04 * (attr("vigor") - 5)

func max_stamina() -> float:
	return 100.0 + 5.0 * (attr("agilidade") - 5)

func speed_mult() -> float:
	return 1.0 + 0.015 * (attr("agilidade") - 5)

func stamina_regen_mult() -> float:
	return 1.0 + 0.06 * (attr("destreza") - 5)

## Stamina rule from proficiencias.json "folego" (costs halved and regeneration ×1,3 on 15/10/2026).
func stamina_rule(key: String, fallback: float) -> float:
	return float(ProficiencyTree.section("folego").get(key, fallback))

func dodge_cost() -> float:
	var cost: float = stamina_rule("esquiva", 12.5) - stamina_rule("esquiva_por_agilidade", 0.5) * (attr("agilidade") - 5)
	cost -= _per_level("esquiva_por_nivel", 0.3) * (level("acrobacia") - 1)
	cost += _perk_sum("acrobacia", "dodge_cost")
	return maxf(stamina_rule("esquiva_minima", 5.0), cost)

func heal_mult() -> float:
	return 1.0 + _per_level("cura_por_nivel", 0.02) * (level("tratamento") - 1) + _perk_sum("tratamento", "heal_mult")

func _per_level(key: String, fallback: float) -> float:
	return float(ProficiencyTree.section("dominio").get(key, fallback))

## Share of a frontal blow the guard holds (fists hold less than a weapon).
func block_reduction(item_id: String) -> float:
	var base: float = 0.25 if item_id == "" else 0.4
	return minf(0.85, base + _per_level("bloqueio_por_nivel", 0.012) * (level("bloqueio") - 1) + _perk_sum("bloqueio", "block_reduction"))

## Stamina per point of damage held by the guard.
func block_cost_mult() -> float:
	return maxf(0.2, 1.0 + _perk_sum("bloqueio", "block_cost"))

## Stamina the guard spends to hold `held` damage.
func block_cost(held: float) -> float:
	return maxf(stamina_rule("guarda_minima", 2.0), held * stamina_rule("guarda_por_dano", 0.5) * block_cost_mult())

static func armor_branch(armor_id: String) -> String:
	var path: Array = Items.DATA.get(armor_id, {}).get("proficiencias", [])
	return str(path[0]) if not path.is_empty() else ""

## Share of each blow the worn armor absorbs.
func armor_protection(armor_id: String) -> float:
	if armor_id == "":
		return 0.0
	var branch: String = armor_branch(armor_id)
	var base: float = float(Items.DATA.get(armor_id, {}).get("protection", 0.0))
	return minf(0.7, base * (1.0 + _per_level("armadura_por_nivel", 0.02) * (level(branch) - 1)) + _perk_sum(branch, "armor_protection"))

## How much of the armor's penalties still apply (practice and perks lower it).
func armor_penalty_mult(armor_id: String) -> float:
	if armor_id == "":
		return 0.0
	var branch: String = armor_branch(armor_id)
	return maxf(0.4, 1.0 - _per_level("penalidade_por_nivel", 0.025) * (level(branch) - 1)) * maxf(0.0, 1.0 + _perk_sum(branch, "armor_penalty"))

func armor_speed_penalty(armor_id: String) -> float:
	return float(Items.DATA.get(armor_id, {}).get("speed_penalty", 0.0)) * armor_penalty_mult(armor_id)

func armor_regen_penalty(armor_id: String) -> float:
	return float(Items.DATA.get(armor_id, {}).get("regen_penalty", 0.0)) * armor_penalty_mult(armor_id)

func armor_noise(armor_id: String) -> float:
	if armor_id == "":
		return 0.0
	var branch: String = armor_branch(armor_id)
	if _perk_sum(branch, "armor_noise") <= -1.0:
		return 0.0
	return float(Items.DATA.get(armor_id, {}).get("noise", 0.0)) * armor_penalty_mult(armor_id)

func sprint_cost_mult() -> float:
	return maxf(0.5, 1.0 - _per_level("corrida_por_nivel", 0.012) * (level("atletismo") - 1)) * maxf(0.2, 1.0 + _perk_sum("atletismo", "sprint_cost"))

## Fraction of the normal sight range at which monsters notice a sneaking adventurer.
func sneak_detection_mult() -> float:
	var m: float = 0.5 * maxf(0.5, 1.0 - _per_level("furtivo_por_nivel", 0.015) * (level("furtividade") - 1))
	return maxf(0.15, m * (1.0 + _perk_sum("furtividade", "detection")))

## Damage multiplier for any weapon against an unaware monster while sneaking.
func sneak_attack_mult() -> float:
	return 1.5 + _perk_sum("furtividade", "sneak_bonus")

## Chance to open a lock of difficulty 1 (simple) to 4 (master).
func pick_chance(difficulty: int) -> float:
	var chance: float = 0.6 + _per_level("arrombar_por_nivel", 0.04) * (level("arrombamento") - 1) - 0.2 * (difficulty - 1) + _perk_sum("arrombamento", "pick_chance")
	return clampf(chance, 0.05, 0.95)

func pick_break_chance() -> float:
	return clampf(0.5 * (1.0 + _perk_sum("arrombamento", "pick_break")), 0.0, 1.0)

# --- branches ------------------------------------------------------------------------

func branch_attribute(branch: String) -> String:
	return str(ProficiencyTree.DATA.get(branch, {}).get("atributo", "destreza"))

## Learning speed from the branch's attribute.
func potential(branch: String) -> float:
	var p: Dictionary = ProficiencyTree.section("potencial")
	return float(p.get("base", 0.6)) + float(p.get("por_ponto", 0.08)) * attr(branch_attribute(branch))

func cap(branch: String) -> int:
	var p: Dictionary = ProficiencyTree.section("potencial")
	return int(p.get("nivel_base", 6)) + int(p.get("nivel_por_ponto", 2)) * attr(branch_attribute(branch))

func level(branch: String) -> int:
	return ProficiencyTree.level_for_xp(float(xp.get(branch, 0.0)), cap(branch))

## Progress inside the current level, 0..1 (1 when the branch is at its cap).
func progress(branch: String) -> float:
	var n: int = level(branch)
	if n >= cap(branch):
		return 1.0
	var a: float = ProficiencyTree.xp_for_level(n)
	var b: float = ProficiencyTree.xp_for_level(n + 1)
	return clampf((float(xp.get(branch, 0.0)) - a) / (b - a), 0.0, 1.0)

static func path_of(item_id: String) -> Array:
	if item_id == "":
		return ProficiencyTree.section("punhos").get("proficiencias", [])
	return Items.DATA.get(item_id, {}).get("proficiencias", [])

## Empty hands fight with the fists profile of proficiencias.json.
static func base_stats(item_id: String) -> Dictionary:
	if item_id == "":
		var fists: Dictionary = ProficiencyTree.section("punhos").duplicate(true)
		fists.erase("_sobre")
		return fists
	return Items.info(item_id).duplicate(true)

func path_xp(path: Array) -> float:
	var total: float = 0.0
	for branch in path:
		total += float(xp.get(branch, 0.0))
	return total

func mastery_cap(path: Array) -> int:
	if path.is_empty():
		return 1
	var total: int = 0
	for branch in path:
		total += cap(branch)
	return roundi(float(total) / path.size())

## Mastery of a weapon: the level its whole path's experience reaches.
func mastery(path: Array) -> int:
	if path.is_empty():
		return 1
	return ProficiencyTree.level_for_xp(path_xp(path), mastery_cap(path))

func damage_mult(path: Array) -> float:
	return 1.0 + float(ProficiencyTree.section("dominio").get("dano_por_nivel", 0.03)) * (mastery(path) - 1)

func cost_mult(path: Array) -> float:
	var d: Dictionary = ProficiencyTree.section("dominio")
	return maxf(float(d.get("folego_minimo", 0.7)), 1.0 - float(d.get("folego_por_nivel", 0.015)) * (mastery(path) - 1))

func active_perks(branch: String) -> Array:
	var out: Array = []
	var n: int = level(branch)
	for perk in ProficiencyTree.DATA.get(branch, {}).get("perks", []):
		if n >= int(perk.get("nivel", 99)):
			out.append(perk)
	return out

func next_perk(branch: String) -> Dictionary:
	var n: int = level(branch)
	for perk in ProficiencyTree.DATA.get(branch, {}).get("perks", []):
		if n < int(perk.get("nivel", 99)):
			return perk
	return {}

func _perk_sum(branch: String, key: String) -> float:
	var total: float = 0.0
	for perk in active_perks(branch):
		total += float(perk.get("mods", {}).get(key, 0.0))
	return total

## Weapon numbers for this adventurer: base data, plus unlocked perks of the
## branches on its path, plus the mastery bonus to damage and stamina cost.
func weapon_stats(item_id: String) -> Dictionary:
	var stats: Dictionary = base_stats(item_id)
	if not enabled or not stats.has("damage"):
		return stats
	var path: Array = path_of(item_id)
	for branch in path:
		for perk in active_perks(branch):
			var mods: Dictionary = perk.get("mods", {})
			for key in mods:
				if not (stats.has(key) or key == "recover_bonus" or key.contains(".")):
					continue
				if key.contains("."):
					var parts: PackedStringArray = key.split(".")
					if stats.has(parts[0]) and stats[parts[0]] is Dictionary:
						stats[parts[0]][parts[1]] = float(stats[parts[0]].get(parts[1], 0.0)) + float(mods[key])
				elif stats.has(key) or key in ["recover_bonus"]:
					var value: float = float(stats.get(key, 0.0)) + float(mods[key])
					stats[key] = int(value) if key == "targets" else value
	stats["damage"] = float(stats["damage"]) * damage_mult(path)
	stats["cost"] = maxf(1.0, float(stats.get("cost", 10.0)) * cost_mult(path))
	stats["mastery"] = mastery(path)
	return stats

# --- experience ----------------------------------------------------------------------

func _decay(current: int, enemy_level: int) -> float:
	if enemy_level <= 0:
		return 1.0
	var a: Dictionary = ProficiencyTree.section("anti_repeticao")
	var limit: float = float(a.get("margem", 3)) + float(a.get("por_andar", 4)) * enemy_level
	return pow(0.5, maxf(0.0, current - limit) / float(a.get("meia_vida", 1.5)))

## Experience for one branch; returns what was actually added.
func award(branch: String, amount: float, enemy_level: int = 0) -> float:
	if not enabled or amount <= 0 or not ProficiencyTree.DATA.has(branch):
		return 0.0
	return _add(branch, amount * _decay(level(branch), enemy_level))

## Experience for a weapon path, split without double counting.
func award_path(path: Array, amount: float, enemy_level: int = 0) -> float:
	if not enabled or amount <= 0 or path.is_empty():
		return 0.0
	var decay: float = _decay(mastery(path), enemy_level)
	var split: Array = ProficiencyTree.shares(path.size())
	var added: float = 0.0
	for i in path.size():
		added += _add(str(path[i]), amount * float(split[i]) * decay)
	return added

## What a monster teaches for the damage dealt to it.
func award_damage(enemy, dealt: float, path: Array) -> float:
	if dealt <= 0 or enemy == null:
		return 0.0
	var value: float = float(EnemyTypes.info(enemy.kind).get("xp", 20)) * (1.0 + 0.25 * (enemy.level - 1))
	return award_path(path, value * clampf(dealt / enemy.maximum_health, 0.0, 1.0), enemy.level)

func _add(branch: String, amount: float) -> float:
	var before: int = level(branch)
	var limit: float = ProficiencyTree.xp_for_level(cap(branch))
	var old: float = float(xp.get(branch, 0.0))
	var gain: float = amount * potential(branch)
	var now: float = minf(limit, old + gain)
	xp[branch] = now
	var after: int = level(branch)
	for n in range(before + 1, after + 1):
		level_up.emit(branch, n)
		for perk in ProficiencyTree.DATA.get(branch, {}).get("perks", []):
			if int(perk.get("nivel", 99)) == n:
				perk_unlocked.emit(branch, perk)
	return now - old

# --- save ------------------------------------------------------------------------------

func snapshot() -> Dictionary:
	return {"attrs": attrs.duplicate(), "xp": xp.duplicate()}

func restore(data) -> bool:
	if not data is Dictionary or not data.get("attrs") is Dictionary or not data.get("xp") is Dictionary:
		return false
	var values: Dictionary = {}
	for id in ProficiencyTree.ATTRIBUTE_ORDER:
		var v = data["attrs"].get(id, 5)
		if not (v is int or v is float) or v < 1 or v > 10:
			return false
		values[id] = int(v)
	var points: Dictionary = {}
	var renamed: Dictionary = ProficiencyTree.section("migracao")
	for branch in data["xp"]:
		var v = data["xp"][branch]
		if not (v is int or v is float) or not is_finite(float(v)) or v < 0:
			return false
		# Branches renamed between versions keep their experience; unknown ones are dropped.
		var id: String = str(renamed.get(branch, branch))
		if ProficiencyTree.DATA.has(id):
			points[id] = float(points.get(id, 0.0)) + float(v)
	attrs = values
	xp = points
	return true
