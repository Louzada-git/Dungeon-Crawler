extends Node
# Labyrinth mode suite: generated floors, stairs, per-floor state, boss,
# relic chest, save version 2 and the death rule.
#   godot --headless --path . -- --test-labirinto --seed=777

var checks: int = 0
var failures: Array[String] = []
var game

func check(condition: bool, note: String) -> void:
	checks += 1
	if not condition:
		failures.append(note)
		push_error("TEST FAIL: " + note)
	else:
		print("PASS: " + note)

func mean(list: Array) -> float:
	var total: float = 0.0
	for v in list:
		total += float(v)
	return total / maxf(1.0, list.size())

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func near(cell: Vector2i) -> void:
	game.player.position = game.layout.to_world(game._free_neighbour(cell))
	game.player.reset_transients()

func run(target) -> void:
	game = target
	process_mode = Node.PROCESS_MODE_ALWAYS
	for path in [game.save_path, game.knowledge_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	await frames(5)
	var p = game.player
	check(game.generated and game.seed == 777 and game.floor == 1, "Modo labirinto com a semente pedida")
	check(game.layout.rooms.size() == 10 and game.layout.world["mode"] == "labirinto", "1º andar tem 10 salas geradas")
	check(game.is_safe() and game.interaction_text() == "" or game.is_safe(), "Começa no abrigo, área segura")
	check(LabyrinthGenerator.validate(game.layout.world).is_empty(), "Andar em jogo passa na validação do gerador")
	check(game.world_root.get_node_or_null("Fogueira") != null and game.get_tree().get_nodes_in_group("chamas").filter(func(f): return game.world_root.is_ancestor_of(f)).size() > 3, "Andar gerado tem tochas com chama e a fogueira do abrigo")
	for e in game.enemies:
		e.set_physics_process(false)
	# Boss
	var boss: DungeonEnemy = game.boss()
	check(boss != null and boss.alive and boss.maximum_health >= 420, "Chefe presente com vida de chefe")
	near(game.stairs_down_cell())
	check(game.interaction_text().contains("trancada"), "Descida aparece trancada com o capataz vivo")
	game.interact()
	check(game.floor == 1, "Não desce enquanto o chefe vive")
	# Boss slam hits around it, even behind; fury below half life.
	p.position = boss.position + Vector3(-2.4, 0, 0)
	p.health = 100
	p.invulnerable = 0
	boss.aggro = true
	boss.attacks_done = 2
	boss.cooldown = 0
	boss.attack_recovery = 0
	boss.visual.rotation.y = 0
	boss._begin_attack(p)
	check(boss.slamming and boss.windup > 1.0, "Terceiro ataque do chefe é o golpe em área, com aviso longo")
	boss.set_physics_process(true)
	await frames(80)
	boss.set_physics_process(false)
	check(p.health < 100, "Golpe em área acerta o personagem ao redor do chefe")
	var base_speed: float = boss.speed
	boss.receive_damage(boss.maximum_health * 0.55, Vector3.RIGHT)
	check(boss.enraged and boss.speed > base_speed, "Chefe fica furioso abaixo da metade da vida")
	game.ui.update_hud()
	check(game.ui.boss_bar.visible, "Barra do chefe aparece no HUD durante a luta")
	boss.receive_damage(boss.maximum_health, Vector3.RIGHT)
	check(not boss.alive and not game.boss_alive(), "Chefe pode ser derrotado")
	check(game.objective_text().contains("2º andar"), "Objetivo passa a apontar a descida")
	var relic_id: String = ""
	for entry in game.layout.world["containers"]:
		if entry.get("objective", false):
			relic_id = entry["id"]
	var relic: Dictionary = {}
	for c in game.containers:
		if c["id"] == relic_id:
			relic = c
	check(not relic.is_empty() and int(relic["items"].get("coin", 0)) >= 12 and not Items.DATA.has("seal"), "Relicário do chefe guarda moedas e saque (o selo saiu do jogo)")
	# Floor 1 changes that must survive the trip.
	var chest: Dictionary = {}
	for c in game.containers:
		if c.get("chest", true) and not c["items"].is_empty() and c["id"] != relic_id and c["id"] != "s0_bau_0":
			chest = c
			break
	var chest_id: String = chest.get("id", "")
	if not chest.is_empty():
		chest["items"].clear()
	# Locks: what the floor description says is what the game shows; a picked lock stays open.
	var described: Dictionary = {}
	for entry in game.layout.world["containers"]:
		described[entry["id"]] = int(entry.get("lock", 0))
	var same_locks: bool = true
	for c in game.containers:
		if described.has(c["id"]):
			same_locks = same_locks and int(c.get("lock", 0)) == described[c["id"]]
	check(same_locks, "Baús do andar trazem as fechaduras da descrição")
	var picked: Dictionary = {}
	var kept: Dictionary = {}
	for c in game.containers:
		if c["id"] == chest_id or c["id"] == relic_id or not c.get("chest", true):
			continue
		if picked.is_empty():
			picked = c
		elif kept.is_empty():
			kept = c
	if not picked.is_empty() and not kept.is_empty():
		picked["lock"] = 2
		kept["lock"] = 3
		game.inventory.add("gazua")
		check(game.attempt_lockpick(picked, 0.0) and not picked.has("lock"), "Arromba um baú do 1º andar")
		game.ui.close_all()
	var picked_id: String = picked.get("id", "")
	var kept_id: String = kept.get("id", "")
	# Down to floor 2
	near(game.stairs_down_cell())
	check(game.interaction_text().contains("2º andar"), "Descida aberta depois do chefe")
	game.inventory.add("arco")
	game.inventory.add("flecha", 3)
	game.inventory.equip("arco")
	p.cooldown = 0
	p.attack_timer = 0
	p.attack_wait = 0
	p.stamina = 100
	p.facing = Vector3.RIGHT
	p.attack()
	game.resolve_player_attack()
	var flying: int = get_tree().get_nodes_in_group("projeteis").size()
	var t0 := Time.get_ticks_msec()
	game.interact()
	await frames(3)
	var build_ms: int = Time.get_ticks_msec() - t0
	check(flying == 1 and get_tree().get_nodes_in_group("projeteis").is_empty(), "Flecha em voo some ao trocar de andar")
	game.inventory.equip("sword")
	check(game.floor == 2 and game.layout.rooms.size() == 20, "Escada leva ao 2º andar, com 20 salas")
	check(game.world_root.get_node_or_null("Fogueira") == null and game.world_root.get_node_or_null("LuzesTremulas").lights.size() > 3, "2º andar sem abrigo não tem fogueira; luzes das tochas tremem")
	check(build_ms < 4000, "Andar 2 monta em menos de 4 s (%d ms)" % build_ms)
	check(game.layout.is_floor(game.layout.to_cell(p.position)) and game.layout.rooms[0]["rect"].has_point(game.layout.to_cell(p.position)), "Chega na entrada do 2º andar")
	check(not game.has_shelter() and game.stairs_up_cell() != null, "Andares fundos têm subida e não têm abrigo")
	var corrupt: DungeonEnemy = null
	for e in game.enemies:
		e.set_physics_process(false)
		if e.kind == "corrompido" and corrupt == null:
			corrupt = e
	if corrupt:
		check(is_equal_approx(corrupt.maximum_health, float(EnemyTypes.info("corrompido")["health"]) * 1.3), "Monstros do 2º andar têm mais vida")
		var xp_before: float = game.sheet.path_xp(CharacterSheet.path_of("sword"))
		corrupt.position = p.position + Vector3(1.2, 0, 0)
		corrupt.aggro = true
		game.inventory.equip("sword")
		p.cooldown = 0
		p.attack_timer = 0
		p.attack_wait = 0
		p.stamina = p.max_stamina
		p.facing = Vector3.RIGHT
		p.attack()
		game.resolve_player_attack()
		check(game.sheet.path_xp(CharacterSheet.path_of("sword")) > xp_before, "Golpe no labirinto ensina proficiência")
	var kinds: Dictionary = {}
	for e in game.enemies:
		kinds[e.kind] = true
	check(kinds.size() >= 3, "2º andar mistura tipos de monstro: " + str(kinds.keys()))
	# Change floor 2, go up, come back
	var victim: DungeonEnemy = game.enemies[1]
	var victim_id: String = victim.uid
	victim.receive_damage(9999, Vector3.RIGHT)
	near(game.stairs_up_cell())
	check(game.interaction_text().contains("1º andar"), "Subida leva de volta ao 1º andar")
	game.interact()
	await frames(3)
	check(game.floor == 1 and not game.boss_alive(), "Volta ao 1º andar com o chefe ainda derrotado")
	check(game.player.position.distance_to(game.layout.to_world(game.stairs_down_cell())) < 3.0, "Chega ao lado da descida ao subir")
	if chest_id != "":
		var same: Array = game.containers.filter(func(c): return c["id"] == chest_id)
		check(same.size() == 1 and same[0]["items"].is_empty(), "Baú esvaziado continua vazio ao voltar")
	if picked_id != "" and kept_id != "":
		var opened: Array = game.containers.filter(func(c): return c["id"] == picked_id)
		var still: Array = game.containers.filter(func(c): return c["id"] == kept_id)
		check(opened.size() == 1 and int(opened[0].get("lock", 0)) == 0 and still.size() == 1 and int(still[0].get("lock", 0)) == 3, "Fechadura arrombada continua aberta ao voltar; a outra continua trancada")
	near(game.stairs_down_cell())
	game.interact()
	await frames(3)
	var back: Array = game.enemies.filter(func(e): return e.uid == victim_id)
	check(back.size() == 1 and not back[0].alive, "Monstro morto no 2º andar continua morto")
	# Save version 2 round trip on floor 2
	for e in game.enemies:
		e.set_physics_process(false)
	game.inventory.add("gema", 2)
	check(game.save_game(false), "Save do labirinto é gravado")
	var raw = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(raw["version"] == 2 and raw["seed"] == 777 and raw["floor"] == 2 and raw["floors"].has("1"), "Save guarda semente, andar e o estado do 1º andar")
	check(raw.has("sheet") and game.sheet.enabled, "Save do labirinto guarda o aventureiro")
	game.inventory.remove("gema", 2)
	game.floor_states.clear()
	check(game.load_game() and game.inventory.count("gema") == 2 and game.floor_states.has(1), "Carregar restaura mochila e andares visitados")
	# A save from before the seal left the game still loads, without the seal.
	var old = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	old["inventory"]["stacks"]["seal"] = 1
	old["containers"][0]["items"]["seal"] = 1
	old["floors"]["1"]["containers"][0]["items"]["seal"] = 1
	old["seals"] = 2
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var no_seal: bool = game.load_game() and game.inventory.count("seal") == 0 and game.inventory.count("gema") == 2
	for c in game.containers:
		no_seal = no_seal and not c["items"].has("seal")
	for c in game.floor_states[1]["containers"]:
		no_seal = no_seal and not c["items"].has("seal")
	check(no_seal, "Save antigo com selos carrega sem o selo")
	# The shelter only rests and saves now.
	near(game.stairs_up_cell())
	game.interact()
	await frames(3)
	game.player.position = game.camp_position
	check(game.interaction_text().contains("SALVAR"), "Abrigo oferece descansar e salvar")
	DirAccess.remove_absolute(game.save_path)
	game.interact()
	check(not game.ended and FileAccess.file_exists(game.save_path), "Descansar no abrigo salva e a expedição continua")
	# Knowledge survives death
	var known_cells: int = game.knowledge[1].size()
	check(known_cells > 20, "Mapa do 1º andar foi explorado (%d células)" % known_cells)
	var packed = SaveSystem.parse_knowledge(SaveSystem.pack_knowledge(game.knowledge))
	check(packed[1].size() == known_cells and packed.has(2), "Conhecimento de todos os andares ida e volta pelo formato salvo")
	game.techniques.set_objects("corte", ["afiada"])
	game.techniques.assign(0, "corte")
	p.position = game.layout.to_world(game.layout.rooms[2]["rect"].get_center())
	p.invulnerable = 0
	p.receive_damage(500, Vector3.RIGHT)
	await frames(2)
	check(game.ended and not FileAccess.file_exists(game.save_path), "Morte encerra a expedição e apaga o save da expedição")
	var known = JSON.parse_string(FileAccess.get_file_as_string(game.knowledge_path))
	check(known is Dictionary and int(known["seed"]) == 777 and known["knowledge"]["1"].size() == known_cells, "Conhecimento e semente ficam guardados depois da morte")
	check(not known.has("sheet"), "Proficiências não sobrevivem à morte: o próximo aventureiro começa do zero")
	var next := TechniqueBook.new()
	next.restore(known.get("tecnicas", {}), false)
	check(next.objects("corte") == ["afiada"] and next.bar.all(func(v): return v == ""), "A montagem das habilidades sobrevive à morte como conhecimento; a barra começa vazia")
	var labels: Array = []
	for b in game.ui.end_buttons.get_children():
		labels.append(b.text)
	check(game.ui.ending_panel.visible and "Recomeçar no mesmo labirinto" in labels, "Tela final oferece recomeçar no mesmo labirinto")
	# Bigger floors stay buildable.
	var t1 := Time.get_ticks_msec()
	var d3: Dictionary = LabyrinthGenerator.generate(777, 3)
	check(LabyrinthGenerator.validate(d3).is_empty() and d3["rooms"].size() == 40, "3º andar gerado e válido (%d ms)" % (Time.get_ticks_msec() - t1))
	# Locked chests across seeds: deeper floors have harder locks, the boss relic is never locked.
	var locked_by_floor: Dictionary = {1: [], 3: []}
	var relic_locked: bool = false
	var chests: int = 0
	for s in 6:
		for fl in [1, 3]:
			var d: Dictionary = LabyrinthGenerator.generate(3000 + s * 11, fl)
			for entry in d["containers"]:
				if not entry.get("chest", true):
					continue
				chests += 1
				var lock: int = int(entry.get("lock", 0))
				if entry.get("objective", false) and lock > 0:
					relic_locked = true
				if lock > 0:
					locked_by_floor[fl].append(lock)
	var all_locks: Array = locked_by_floor[1] + locked_by_floor[3]
	var share: float = float(all_locks.size()) / maxf(1.0, chests)
	check(share > 0.1 and share < 0.7 and all_locks.all(func(v): return v >= 1 and v <= 4), "Parte dos baús gerados vem trancada (%d%% de %d)" % [roundi(share * 100), chests])
	check(not relic_locked, "Relicário do chefe nunca vem trancado")
	var avg1: float = mean(locked_by_floor[1])
	var avg2: float = mean(locked_by_floor[3])
	check(avg2 > avg1 + 0.5, "Fechaduras do 3º andar são mais difíceis que as do 1º (%s × %s)" % [UiStyle.fmt(avg1, 2), UiStyle.fmt(avg2, 2)])
	for path in [game.save_path, game.knowledge_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	get_tree().paused = false
	print("RESULT: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
