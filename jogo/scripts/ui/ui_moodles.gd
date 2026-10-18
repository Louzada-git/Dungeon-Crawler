extends VBoxContainer
class_name UiMoodles
## Status indicators on the right edge (Project Zomboid "moodles").
## Each one appears only while the condition is real in the simulation and
## its tooltip states the actual rule behind it.

const LEVEL_COLORS := [
	Color("8a8a3a"),  # 1 – mild (olive/yellow)
	Color("b8762d"),  # 2 – orange
	Color("b2402c"),  # 3 – red
	Color("6e1717"),  # 4 – dark red
]
const POSITIVE := Color("3f7a3b")

var game
var tiles: Dictionary = {}
var _signature: String = ""

func _init(game_ref) -> void:
	game = game_ref
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Current list of active indicators, most severe first.
func compute() -> Array:
	var p = game.player
	var out: Array = []
	if p == null or p.health <= 0:
		return out
	var bandage: String = "Use uma bandagem" + game.quick_bar.key_hint("bandage") + "."
	var ration: String = "Coma uma ração" + game.quick_bar.key_hint("ration") + "."
	if p.bleeding:
		out.append({"id": "bleeding", "icon": "drop", "level": 3, "title": "Sangrando", "text": "Perde %s de vida por segundo até ser tratado.\n%s" % [UiStyle.fmt(DungeonPlayer.BLEED_PER_SECOND, 1), bandage]})
	var life: float = p.health / p.max_health
	if life < 0.75:
		var lv: int = 1 if life >= 0.5 else (2 if life >= 0.25 else (3 if life >= 0.12 else 4))
		var names := ["Machucado", "Ferido", "Gravemente ferido", "À beira da morte"]
		out.append({"id": "hurt", "icon": "heart_crack", "level": lv, "title": names[lv - 1], "text": "Vida %d de %d. A vida não se recupera sozinha;\numa bandagem restaura %d." % [ceili(p.health), roundi(p.max_health), bandage_heal(game)]})
	if p.food <= 0:
		out.append({"id": "food", "icon": "bread", "level": 4, "title": "Inanição", "text": "Perde %s de vida por segundo e o fôlego recupera devagar.\n%s" % [UiStyle.fmt(DungeonPlayer.STARVE_PER_SECOND, 1), ration]})
	elif p.food <= DungeonPlayer.HUNGRY:
		out.append({"id": "food", "icon": "bread", "level": 2, "title": "Faminto", "text": "Saciedade %d. O fôlego recupera %s por segundo em vez de %s.\n%s" % [ceili(p.food), UiStyle.fmt(p.stamina_regen(true), 1), UiStyle.fmt(p.stamina_regen(false), 1), ration]})
	elif p.food <= 30:
		out.append({"id": "food", "icon": "bread", "level": 1, "title": "Com fome", "text": "Saciedade %d. Ainda sem efeito; abaixo de %d\no fôlego passa a recuperar devagar." % [ceili(p.food), roundi(DungeonPlayer.HUNGRY)]})
	var held: Dictionary = game.sheet.weapon_stats(game.inventory.equipped)
	var ammo: String = game.ammo_for(held)
	if ammo != "" and game.inventory.count(ammo) <= 0:
		out.append({"id": "ammo", "icon": "arrow", "level": 2, "title": "Sem munição", "text": "%s sem %ss. Procure nos baús, no chão\nonde os disparos erraram e nos corpos dos monstros." % [str(held.get("name", "")), str(Items.info(ammo).get("name", ammo)).to_lower()]})
	var cost: float = float(held.get("cost", 10.0))
	if p.stamina < cost:
		out.append({"id": "stamina", "icon": "lungs", "level": 3, "title": "Exausto", "text": "Fôlego %d: abaixo dos %s que a arma exige por golpe.\nRecue e recupere o fôlego." % [floori(p.stamina), UiStyle.num(cost)]})
	elif p.stamina < p.dodge_cost():
		out.append({"id": "stamina", "icon": "lungs", "level": 2, "title": "Ofegante", "text": "Fôlego %d: abaixo dos %s necessários para esquivar." % [floori(p.stamina), UiStyle.num(p.dodge_cost())]})
	var w: float = game.inventory.weight()
	if w > game.inventory.comfort:
		var factor: float = lerpf(1.0, 0.72, (w - game.inventory.comfort) / (game.inventory.capacity - game.inventory.comfort))
		var lv2: int = 1 if w <= lerpf(game.inventory.comfort, game.inventory.capacity, 0.57) else 2
		out.append({"id": "load", "icon": "weight", "level": lv2, "title": "Carga pesada" if lv2 == 1 else "Sobrecarregado", "text": "%s kg na mochila: %d%% mais lento.\n%s" % [UiStyle.fmt(w), roundi((1.0 - factor) * 100.0), load_rule(game)]})
	var hunters: int = 0
	for enemy in game.enemies:
		if enemy.alive and enemy.aggro:
			hunters += 1
	if hunters > 0:
		out.append({"id": "hunted", "icon": "eye", "level": 2 if hunters == 1 else 3, "title": "Perseguido", "text": ("Um monstro está atrás de você." if hunters == 1 else "%d monstros estão atrás de você." % hunters) + "\nNo abrigo eles desistem e não atacam."})
	if p.sneaking:
		var sight: float = DungeonEnemy.SIGHT * p.detection_mult()
		out.append({"id": "sneak", "icon": "eye_off", "level": 0, "title": "Furtivo", "text": "Um monstro comum te nota a %s m de frente e %s m por trás\n(de pé: %s m). Ataque em desprevenido: dano ×%s.  [C] levanta." % [UiStyle.fmt(sight), UiStyle.fmt(sight * 0.6), UiStyle.num(DungeonEnemy.SIGHT), UiStyle.fmt(game.sheet.sneak_attack_mult(), 1)]})
	if p.can_block():
		out.append({"id": "guard", "icon": "shield", "level": 0, "title": "Em guarda", "text": "Golpes de frente perdem %d%% do dano; cada bloqueio gasta fôlego.\nNão segura a pancada em área do capataz." % roundi(game.sheet.block_reduction(game.inventory.equipped) * 100)})
	if game.is_safe():
		out.append({"id": "safe", "icon": "tent", "level": 0, "title": "No abrigo", "text": "Monstros não atacam aqui.\nNo ponto de descanso, E salva a expedição."})
	return out

## What a bandage heals for this adventurer (Tratamento makes it more).
static func bandage_heal(owner_game) -> int:
	return roundi(float(Items.info("bandage").get("heal", 0.0)) * owner_game.sheet.heal_mult())

## The weight rule for this adventurer (Força moves both limits).
static func load_rule(owner_game) -> String:
	return "Acima de %s kg o passo pesa; o limite é %s kg." % [UiStyle.num(owner_game.inventory.comfort), UiStyle.num(owner_game.inventory.capacity)]

func refresh() -> void:
	var list: Array = compute()
	var parts: PackedStringArray = []
	for m in list:
		parts.append("%s:%d:%s" % [m["id"], m["level"], m["text"]])
	var signature := "|".join(parts)
	if signature == _signature:
		return
	_signature = signature
	var keep: Dictionary = {}
	var order: int = 0
	for m in list:
		keep[m["id"]] = true
		var tile: Control = tiles.get(m["id"])
		var fresh: bool = tile == null
		if fresh:
			tile = Tile.new(self)
			var icon := UiIcon.new(m["icon"], Color("f3eee2"))
			tile.add_child(icon)
			icon.position = Vector2(7, 6)
			icon.size = Vector2(30, 30)
			add_child(tile)
			tiles[m["id"]] = tile
		var previous: int = tile.get_meta("level", -1)
		tile.set_meta("level", m["level"])
		tile.set_meta("title", m["title"])
		tile.set_meta("text", m["text"])
		tile.tooltip_text = m["title"]
		move_child(tile, order)
		order += 1
		tile.queue_redraw()
		if fresh or previous != m["level"]:
			_pop(tile)
	for id in tiles.keys():
		if not keep.has(id):
			tiles[id].queue_free()
			tiles.erase(id)

func _pop(tile: Control) -> void:
	tile.scale = Vector2(1.35, 1.35)
	var tween := tile.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(tile, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "rotation", 0.08, 0.06)
	tween.tween_property(tile, "rotation", -0.08, 0.08)
	tween.tween_property(tile, "rotation", 0.0, 0.06)

func _draw_tile(tile: Control) -> void:
	var level: int = tile.get_meta("level", 1)
	var base: Color = POSITIVE if level == 0 else LEVEL_COLORS[clampi(level - 1, 0, 3)]
	var r := Rect2(Vector2.ZERO, tile.size)
	tile.draw_rect(r, base.darkened(0.25))
	tile.draw_rect(Rect2(2, 2, r.size.x - 4, r.size.y * 0.5 - 2), base.lightened(0.08))
	tile.draw_rect(Rect2(2, r.size.y * 0.5, r.size.x - 4, r.size.y * 0.5 - 2), base)
	tile.draw_rect(r, base.lightened(0.35), false, 1.0)
	tile.draw_rect(r.grow(-1), Color(0, 0, 0, 0.35), false, 1.0)
	# Severity pips along the bottom edge.
	if level > 0:
		for i in level:
			tile.draw_rect(Rect2(5 + i * 6, r.size.y - 5, 4, 2), Color(1, 1, 1, 0.85))

class Tile extends Control:
	var owner_list
	func _init(list) -> void:
		owner_list = list
		custom_minimum_size = Vector2(44, 44)
		mouse_filter = Control.MOUSE_FILTER_STOP
		pivot_offset = Vector2(22, 22)
	func _draw() -> void:
		owner_list._draw_tile(self)
	func _make_custom_tooltip(_for_text: String) -> Object:
		var level: int = get_meta("level", 1)
		var color: Color = Color("8fd07f") if level == 0 else Color("f0b07a").lerp(Color("ff7a66"), clampf((level - 1) / 3.0, 0, 1))
		return UiStyle.tip(get_meta("title", ""), get_meta("text", ""), color)
