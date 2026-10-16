extends Node

var checks: int = 0
var failures: Array[String] = []
var game

func check(condition: bool, note: String) -> void:
 checks += 1
 if not condition:
  failures.append(note)
  push_error("TEST FAIL: "+note)
 else:
  print("PASS: "+note)

func wait_frames(amount: int) -> void:
 for i in amount:
  await get_tree().physics_frame

## Waits for drawn frames (where _process runs, the HUD included). Several physics
## steps can happen before one of these when a frame is slow.
func wait_process(amount: int) -> void:
 for i in amount:
  await get_tree().process_frame

func run(target, capture: bool) -> void:
 game = target
 process_mode = Node.PROCESS_MODE_ALWAYS
 await wait_frames(10)
 if capture:
  await capture_views()
  return
 test_inventory()
 test_data()
 var health_key = InputEventKey.new()
 health_key.physical_keycode = KEY_H
 health_key.pressed = true
 Input.parse_input_event(health_key)
 Input.flush_buffered_events()
 await wait_frames(2)
 check(game.ui.health_panel.visible and not get_tree().paused,"H abre condição física sem interromper a exploração")
 game.ui.toggle_health()
 var food_before: int = game.inventory.count("ration")
 game.player.food = 40
 var food_key = InputEventKey.new()
 food_key.physical_keycode = KEY_2
 food_key.pressed = true
 Input.parse_input_event(food_key)
 Input.flush_buffered_events()
 await wait_frames(2)
 check(game.inventory.count("ration")==food_before-1 and game.player.food > 74,"Atalho 2 usa ração pelo fluxo real de entrada")
 game.inventory.add("ration")
 game.player.food = 85
 check(game.player.visual.scale.is_equal_approx(Vector3.ONE),"Personagem original usa escala humana em metros")
 var skeleton = Visuals.skeleton(game.player.visual)
 check(skeleton != null and (skeleton.find_bone("hand-right") >= 0 or skeleton.find_bone(DungeonPlayer.MOUNTS["hand-right"][0]) >= 0) and game.player.weapon_mount != null,"Rig do personagem tem mão para equipar armas")
 check(skeleton.find_bone("mixamorig_RightHand") >= 0 and game.player.weapon_mount.get_parent() is BoneAttachment3D,"Personagem PSX: arma presa à mão do rig Mixamo com a correção de posição")
 for animation_name in ["idle","guard","walk","run","attack","stab","dodge","hit","die"]:
  check(game.player.animator.has_animation(animation_name),"Animação original disponível: "+animation_name)
 for animation_name in ["mixamo_attack","mixamo_stab","mixamo_hit","mixamo_die"]:
  check(game.player.animator.has_animation(animation_name),"Animação Mixamo adaptada disponível: "+animation_name)
 check(game.enemies[0].animator.has_animation("attack"),"Monstro original tem animação de ataque")
 check(game.layout.pathfinder.is_point_solid(Vector2i(2,22)),"Móvel bloqueia a rota de navegação dos monstros")
 for container_data in game.containers:
  var destination = Vector3(container_data["pos"][0],0,container_data["pos"][1])
  check(game.layout.route(game.player.position,destination).size()>0,"Rota até recipiente preservada: "+container_data["name"])
 # Walk into the side of the cot to verify its real collider, not only navigation.
 game.player.position = game.layout.to_world(Vector2i(3,22))
 game.player.test_direction = Vector2(-1,-1)
 await wait_frames(50)
 game.player.test_direction = Vector2.ZERO
 check(game.player.position.x > 4.6,"Colisão do catre impede atravessar o móvel")
 game.player.position = game.layout.to_world(game.layout.spawn)
 for room in game.layout.rooms:
  var rect: Rect2i = room["rect"]
  var point: Vector3 = game.layout.to_world(rect.position+Vector2i(1,1))
  check(game.layout.route(game.player.position,point).size() > 0,"Mapa conectado: "+room["name"])
 var p = game.player
 var start: Vector3 = p.position
 p.motion_velocity = Vector3.ZERO
 p.velocity = Vector3.ZERO
 p.test_direction = Vector2(1,0)
 await wait_frames(30)
 check(p.animator.current_animation == "walk","Caminhada usa ciclo alinhado ao esqueleto próprio")
 Input.action_press("sprint")
 await wait_frames(10)
 check(p.animator.current_animation == "run","Corrida usa ciclo alinhado ao esqueleto próprio")
 Input.action_release("sprint")
 p.test_direction = Vector2.ZERO
 check(p.position.distance_to(start) > 1.0,"Movimento altera posição com física ativa")
 # Press against a north-west corner, ensuring wall collisions contain the player.
 p.position = game.layout.to_world(Vector2i(3,19))
 p.test_direction = Vector2(0,-1)
 await wait_frames(120)
 p.test_direction = Vector2.ZERO
 check(game.layout.is_floor(game.layout.to_cell(p.position)),"Paredes contêm o personagem ao correr contra o canto")
 p.position = start
 var inv = game.inventory
 var container: Dictionary = game.containers[0]
 var initial: int = inv.count("ration")+int(container["items"].get("ration",0))
 game.ui.open_inventory(container)
 game.ui.select_loot("ration")
 game.ui.take_selected()
 check(inv.count("ration")+int(container["items"].get("ration",0)) == initial,"Coleta pela interface conserva quantidade entre baú e mochila")
 check(get_tree().paused,"Mochila pausa a versão solo")
 p.food = 40
 var ration_count: int = inv.count("ration")
 game.ui.select_item("ration")
 game.ui.use_selected()
 check(p.food == 75 and inv.count("ration") == ration_count-1,"Comida pela interface restaura saciedade e consome um item")
 p.health = 52
 p.bleeding = true
 check(game.use_item("bandage") and not p.bleeding and p.health == 70,"Bandagem estanca ferimento e restaura vida")
 inv.add("spear")
 check(game.use_item("spear") and inv.equipped == "spear","Equipar lança muda a arma ativa")
 var before: int = inv.count("spear")
 game.drop_item("spear")
 check(inv.equipped == "" and inv.count("spear") == before-1,"Descartar a arma equipada remove o equipamento")
 check(game.containers[-1]["items"].get("spear") == 1,"Item descartado permanece recuperável no mapa")
 inv.equip("sword")
 game.ui.close_all()
 check(not get_tree().paused,"Fechar mochila retoma a simulação")
 game.ui.toggle_map()
 check(game.ui.map_panel.visible and get_tree().paused,"Mapa explorado abre e pausa")
 game.ui.close_all()
 # Isolate one enemy and exercise the real delayed attack / cooldown.
 var enemy = game.enemies[0]
 p.position = game.layout.to_world(Vector2i(5,12))
 enemy.position = p.position+Vector3(1.5,0,0)
 enemy.set_physics_process(false)
 p.set_physics_process(false)
 p.facing = Vector3.RIGHT
 p.stamina = 100
 p.cooldown = 0
 var hp: float = enemy.health
 check(p.attack(),"Ataque inicia com fôlego disponível")
 check(p.animator.current_animation == "mixamo_attack","Corte de espada usa animação Mixamo")
 check(not p.attack(),"Recuperação bloqueia spam de ataque")
 # Running player physics would update mouse aim; damage uses the committed direction below.
 game.resolve_player_attack()
 check(enemy.health == hp-24,"Golpe atinge um inimigo no alcance e direção corretos")
 game.resolve_player_attack()
 check(enemy.health == hp-24,"Um golpe não aplica dano duas vezes")
 p.attack_serial += 1
 p.attack_facing = Vector3.LEFT
 game.resolve_player_attack()
 check(enemy.health == hp-24,"Golpe não atinge inimigo atrás do personagem")
 var safe_pos: Vector3 = game.layout.to_world(Vector2i(5,19))
 p.position = safe_pos
 enemy.position = game.layout.to_world(Vector2i(5,17))
 check(not game.clear_line(p.position,game.layout.to_world(Vector2i(8,16))),"Paredes bloqueiam linha de visão e golpes")
 p.stamina = 0
 p.cooldown = 0
 check(not p.attack(),"Ataque sem fôlego é recusado")
 p.stamina = 100
 p.attack_timer = 0
 p.attack_wait = 0
 p.dodge_lock = 0
 p.health = 100
 p.hurt_timer = 0
 check(p.dodge() and p.invulnerable > 0,"Esquiva consome fôlego e concede invulnerabilidade curta")
 var player_hp: float = p.health
 p.receive_damage(17)
 check(p.health == player_hp,"Invulnerabilidade impede dano durante esquiva")
 p.invulnerable = 0
 p.receive_damage(17)
 check(p.health == player_hp-17,"Receber ataque reduz vida")
 check(p.animator.current_animation == "mixamo_hit","Ferimento reproduz reação Mixamo no jogo")
 p.health = 83
 p.food = 62
 p.bleeding = false
 p.position = safe_pos
 check(game.save_game(false),"Save é gravado com sucesso")
 var saved_inventory = inv.snapshot()
 p.health = 11
 inv.remove("ration")
 check(game.load_game(),"Save válido é carregado")
 check(p.health == 83 and inv.snapshot() == saved_inventory,"Save restaura estado do personagem e inventário")
 check(not game.valid_save({"version":1,"player":{}}),"Save incompleto é rejeitado")
 var malformed = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
 malformed["containers"][0]["items"] = {"not_an_item":3}
 check(not game.valid_save(malformed),"Save com item inexistente é rejeitado")
 # Observe the actual enemy state machine, beyond direct damage calls.
 game.hits_received = 0
 p.invulnerable = 0
 p.health = 100
 p.bleeding = false
 p.position = game.layout.to_world(Vector2i(5,12))
 for other in game.enemies:
  other.set_physics_process(false)
 enemy = game.enemies[0]
 enemy.position = p.position+Vector3(1.6,0,0)
 enemy.health = 65
 enemy.alive = true
 enemy.aggro = false
 enemy.cooldown = 0
 enemy.stagger = 0
 enemy.windup = 0
 enemy.set_physics_process(true)
 await wait_frames(4)
 check(enemy.windup > 0 and enemy.telegraph.visible,"Monstro sinaliza o golpe antes de causar dano")
 await wait_frames(48)
 check(p.health < 100,"Máquina de estados do monstro conclui ataque real")
 enemy.position = game.layout.to_world(Vector2i(9,12))
 enemy.aggro = true
 enemy.windup = 0
 enemy.cooldown = 1
 enemy.repath = 0
 var old_distance: float = enemy.position.distance_to(p.position)
 await wait_frames(35)
 check(enemy.position.distance_to(p.position) < old_distance-0.4,"Monstro persegue por caminhos navegáveis")
 enemy.set_physics_process(false)
 # Distinct spear targeting: only the nearest enemy in a narrow cone.
 inv.add("spear")
 p.position = game.layout.to_world(Vector2i(5,12))
 p.health = 100
 p.hurt_timer = 0
 p.cooldown = 0
 p.dodge_timer = 0
 p.stamina = 100
 inv.equip("spear")
 var second = game.enemies[1]
 enemy.alive = true
 enemy.health = 65
 enemy.position = p.position+Vector3(1.3,0,0)
 second.alive = true
 second.health = 65
 second.position = p.position+Vector3(2.4,0,0)
 p.facing = Vector3.RIGHT
 p.attack()
 game.resolve_player_attack()
 var spear_hit: float = 65.0-float(Items.info("spear")["damage"])
 check(enemy.health==spear_hit and second.health==65,"Lança acerta o primeiro alvo, sem atravessá-lo")
 p.cooldown = 0
 p.attack_timer = 0
 p.attack_wait = 0
 p.stamina = 100
 enemy.health = 65
 enemy.position = p.position+Vector3(1.8,0,1.0)
 p.attack()
 game.resolve_player_attack()
 check(enemy.health==65,"Estocada não atinge alvo fora da faixa estreita")
 second.position = game.layout.to_world(Vector2i(9,10))
 for sample in [Vector3(3.05,0,0),Vector3(3.05,0,0.7),Vector3(3.5,0,0),Vector3(-1.0,0,0)]:
  p.cooldown = 0
  p.attack_timer = 0
  p.attack_wait = 0
  p.stamina = 100
  enemy.health = 65
  enemy.position = p.position+sample
  p.attack()
  game.resolve_player_attack()
  var expected: float = spear_hit if sample == Vector3(3.05,0,0) else 65.0
  check(enemy.health == expected,"Alcance linear da lança: "+str(sample))
 check(p.animator.current_animation == "mixamo_stab","Estocada usa o movimento adaptado do Mixamo")
 # Real windup, committed aim, and inventory swap while the strike is pending.
 inv.equip("sword")
 enemy.health = 65
 enemy.position = p.position+Vector3(1.5,0,0)
 second.position = game.layout.to_world(Vector2i(9,10))
 p.cooldown = 0
 p.attack_timer = 0
 p.attack_wait = 0
 p.hurt_timer = 0
 p.dodge_timer = 0
 p.stamina = 100
 p.facing = Vector3.RIGHT
 p.attack()
 inv.equip("spear")
 p.facing = Vector3.LEFT
 p.set_physics_process(true)
 await wait_frames(5)
 check(enemy.health==65,"Preparação do golpe não causa dano antecipado")
 await wait_frames(12)
 check(enemy.health==41,"Golpe mantém arma e direção comprometidas durante preparação")
 p.set_physics_process(false)
 # A click during the final recovery window is retained and executes once.
 p.attack_wait = 0
 p.attack_timer = 0
 p.hurt_timer = 0
 p.dodge_timer = 0
 p.cooldown = 0.10
 p.stamina = 100
 var serial_before: int = p.attack_serial
 p.request_attack()
 p.set_physics_process(true)
 await wait_frames(8)
 p.set_physics_process(false)
 check(p.attack_serial==serial_before+1 and p.attack_buffer==0,"Clique no fim da recuperação inicia o próximo golpe uma vez")
 # Return to free movement and ensure walking faces the actual direction.
 p.attack_timer = 0
 p.attack_wait = 0
 p.hurt_timer = 0
 p.dodge_timer = 0
 p.impulse = Vector3.ZERO
 p.motion_velocity = Vector3.ZERO
 p.test_direction = Vector2(1,0)
 p.set_physics_process(true)
 await wait_frames(15)
 check(p.facing.dot(Vector3(1,0,-1).normalized())>.99,"Caminhada orienta personagem na direção do movimento")
 p.test_direction = Vector2.ZERO
 await wait_frames(12)
 check(Vector3(p.velocity.x,0,p.velocity.z).length()<0.05,"Soltar movimento freia o personagem sem deslizar")
 p.set_physics_process(false)
 inv.equip("sword")
 p.health = 83
 p.position = safe_pos
 game.discovered.clear()
 game.last_discover = Vector2i(-99,-99)
 p.position = game.layout.to_world(game.layout.spawn)
 game.discover()
 check(game.discovered.size() > 10 and not game.discovered.has(game.layout.relic),"Mapa revela só a região explorada")
 await test_hud()
 await test_weapons()
 await test_proficiencies()
 await test_skills()
 await test_psx()
 await test_techniques()
 await test_vfx()
 await test_balance()
 await test_quick_bar()
 await test_third_person()
 var guardian = game.fixed_guardian()
 check(guardian != null and guardian.uid == "camara_guardiao","Mundo fixo: o objetivo é o carcereiro da câmara")
 if guardian.alive:
  check(game.objective_text() == "Derrote o carcereiro" and not game.fixed_goal_done(),"Com o carcereiro vivo, o objetivo é derrotá-lo")
  guardian.receive_damage(guardian.maximum_health * 3, Vector3.RIGHT)
 check(not guardian.alive and game.objective_text() == "Volte ao abrigo","Carcereiro derrotado: o objetivo vira voltar ao abrigo")
 p.position = game.camp_position
 check(game.interaction_text().contains("VOLTAR"),"No abrigo, E encerra a expedição")
 game.interact()
 check(game.won and game.ended and game.ui.ending_panel.visible,"Voltar ao abrigo depois do carcereiro conclui a incursão")
 get_tree().paused = false
 DirAccess.remove_absolute(game.save_path)
 print("RESULT: %d checks, %d failures" % [checks,failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)

func test_inventory() -> void:
 var inventory = InventoryData.new()
 check(inventory.add("ore",100) == 11,"Capacidade limita quantidade adicionada")
 check(inventory.weight() <= 18,"Peso nunca ultrapassa capacidade")
 check(inventory.add("missing",1) == 0,"Itens inválidos são rejeitados")
 check(not inventory.remove("ore",12),"Remoção acima do estoque é recusada")
 check(not inventory.remove("ore",-1),"Remoção negativa não duplica itens")
 var source: Dictionary = {"ore":5}
 check(inventory.transfer_from(source,"ore",5) == 0 and source["ore"] == 5,"Baú não perde itens quando mochila está cheia")
 inventory.remove("ore",3)
 check(inventory.transfer_from(source,"ore",5) == 3 and source["ore"] == 2,"Transferência parcial conserva itens restantes")
 var snapshot = inventory.snapshot()
 check(not inventory.restore({"stacks":{"ore":500},"equipped":""}),"Save com inventário acima da capacidade é rejeitado")
 check(inventory.snapshot() == snapshot,"Falha ao carregar não corrompe inventário existente")
 check(not inventory.equip("ore"),"Material não pode ser equipado como arma")

func capture_views() -> void:
 var path = ProjectSettings.globalize_path("res://../outputs")
 DirAccess.make_dir_recursive_absolute(path)
 await get_tree().create_timer(1.0).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/base-jogavel.png")
 game.player.test_direction = Vector2(1,0)
 await get_tree().create_timer(0.30).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/movimento.png")
 game.player.test_direction = Vector2.ZERO
 game.inventory.add("spear")
 game.inventory.equip("spear")
 game.player.refresh_weapon()
 await get_tree().create_timer(0.25).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/lanca-parado.png")
 game.player.cooldown = 0
 game.player.stamina = 100
 game.player.attack()
 await get_tree().create_timer(0.14).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/lanca-preparo.png")
 for i in 30:
  if game.player.resolved_serial == game.player.attack_serial:
   break
  await get_tree().physics_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/lanca-impacto.png")
 await get_tree().create_timer(0.22).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/lanca-recuo.png")
 game.player.reset_transients()
 game.inventory.equip("sword")
 game.player.refresh_weapon()
 game.player.cooldown = 0
 game.player.stamina = 100
 game.player.attack()
 await get_tree().create_timer(0.11).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/corte-preparo.png")
 for i in 20:
  if game.player.resolved_serial == game.player.attack_serial:
   break
  await get_tree().physics_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/corte-impacto.png")
 await get_tree().create_timer(0.13).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/corte.png")
 game.player.reset_transients()
 game.ui.open_inventory(game.containers[0])
 game.ui.select_item("sword")
 game.ui.toggle_health()
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/inventario.png")
 get_viewport().get_texture().get_image().save_png(path+"/hud-referencia.png")
 game.ui.toggle_health()
 game.ui.close_all()
 # Show a meaningful explored route without revealing the whole map.
 for cell in game.layout.pathfinder.get_id_path(game.layout.spawn,Vector2i(18,10)):
  game.player.position = game.layout.to_world(cell)
  game.discover()
 game.ui.toggle_map()
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/mapa.png")
 game.ui.close_all()
 game.player.position = game.layout.to_world(Vector2i(5,12))
 game.camera_rig.position = game.player.position
 game.enemies[0].position = game.player.position+Vector3(1.6,0,0)
 game.player.set_physics_process(false)
 for other in game.enemies:
  other.set_physics_process(false)
 game.enemies[0].windup = 0
 game.enemies[0].cooldown = 0
 game.enemies[0].set_physics_process(true)
 await get_tree().create_timer(0.22).timeout
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(path+"/combate.png")
 print("CAPTURES SAVED "+path)
 get_tree().quit()

func moodle_ids() -> Array:
 var ids: Array = []
 for m in game.ui.moodles.compute():
  ids.append(m["id"])
 return ids

func rect_of(node: Control) -> Rect2:
 return node.get_global_rect()

func test_hud() -> void:
 var ui = game.ui
 var p = game.player
 var inv = game.inventory
 for id in Items.DATA:
  check(UiStyle.item_icon(id) != null,"Ícone renderizado existe para o item: "+id)
 check(UiStyle.item_icon("container_chest") != null and UiStyle.item_icon("container_sack") != null,"Ícones de baú e de itens no chão existem")
 check(UiStyle.font("regular") is FontFile and UiStyle.font("semibold") is FontFile,"Fonte Inter carrega nos pesos usados pela interface")
 # Status indicators follow the simulation rules, not guesses.
 p.position = game.layout.to_world(game.layout.spawn)
 p.health = 100
 p.bleeding = false
 p.food = 85
 p.stamina = 100
 check("safe" in moodle_ids() and not "bleeding" in moodle_ids(),"Indicador de abrigo aparece só na área segura")
 p.position = game.layout.to_world(Vector2i(9,11))
 for enemy in game.enemies:
  enemy.aggro = false
 check(moodle_ids().is_empty(),"Sem indicadores quando nada exige atenção: "+str(moodle_ids()))
 p.bleeding = true
 p.health = 40
 p.food = 9
 p.stamina = 10
 var list: Array = game.ui.moodles.compute()
 var by_id: Dictionary = {}
 for m in list:
  by_id[m["id"]] = m
 check(by_id.has("bleeding") and list[0]["id"] == "bleeding","Sangramento aparece primeiro entre os indicadores")
 check(by_id.has("hurt") and by_id["hurt"]["level"] == 2,"Vida 40 mostra nível 2 de ferimento")
 check(by_id.has("food") and by_id["food"]["level"] == 2,"Saciedade 9 mostra fome com efeito no fôlego")
 check(by_id.has("stamina") and by_id["stamina"]["title"] == "Ofegante","Fôlego 10 bloqueia esquiva (12,5) e mostra Ofegante")
 p.stamina = 5
 check(game.ui.moodles.compute().filter(func(m): return m["id"] == "stamina")[0]["title"] == "Exausto","Fôlego abaixo do custo da arma mostra Exausto")
 inv.add("ore",5)
 check("load" in moodle_ids(),"Carga acima de 11 kg mostra indicador de peso")
 game.enemies[2].aggro = true
 check("hunted" in moodle_ids(),"Monstro em perseguição mostra indicador")
 game.enemies[2].aggro = false
 game.ui.update_hud()
 await wait_frames(2)
 check(game.ui.moodles.get_child_count() == game.ui.moodles.compute().size(),"Coluna de indicadores mostra exatamente os estados ativos")
 check(game.ui.status_panel.cells["health"]["value"].text == "40","Painel de condição mostra a vida atual")
 check(game.ui.hotbar.slots[1]["count"].text == str(inv.count("ration")),"Barra rápida mostra quantidade de rações")
 inv.remove("ore",5)
 p.bleeding = false
 p.health = 100
 p.food = 85
 p.stamina = 100
 # Storing in a chest, dropping several units, drag & drop handlers.
 var chest: Dictionary = game.containers[1]
 p.position = Vector3(chest["pos"][0]+1.0,0,chest["pos"][1])
 check(game.nearby_containers().has(chest),"Baú próximo aparece nas abas de recipientes")
 inv.add("ore",3)
 var total_before: int = inv.count("ore")+int(chest["items"].get("ore",0))
 check(game.store_item("ore",2,chest) == 2 and inv.count("ore")+int(chest["items"].get("ore",0)) == total_before,"Guardar no baú conserva a quantidade total")
 ui.open_inventory(chest)
 check(ui.inventory.loot == chest and get_tree().paused,"Mochila abre no baú escolhido")
 ui.inventory._on_drop_into_bag({"type":"item","source":"loot","id":"ore","count":2})
 check(int(chest["items"].get("ore",0)) == 0 and inv.count("ore") == 3,"Arrastar do baú para a mochila pega a pilha")
 ui.inventory._on_drop_into_loot({"type":"item","source":"bag","id":"ore","count":3})
 check(int(chest["items"].get("ore",0)) == 3 and inv.count("ore") == 0,"Arrastar da mochila para o baú guarda a pilha")
 check(not ui.inventory.bag_list._can_drop_data(Vector2.ZERO,{"type":"item","source":"bag","id":"ore"}),"Lista não aceita itens arrastados dela mesma")
 ui.inventory.take("ore",3)
 # Weapon actions: unequip and re-equip through the inventory.
 inv.equip("sword")
 ui.inventory._primary_bag("sword")
 check(inv.equipped == "" and inv.count("sword") == 1,"Clique duplo na arma em mãos guarda a arma")
 ui.inventory._primary_bag("sword")
 check(inv.equipped == "sword","Clique duplo na arma guardada equipa de novo")
 ui.inventory._open_menu("bag","sword",Vector2(300,200))
 var labels: Array = []
 for i in ui.inventory.menu.item_count:
  labels.append(ui.inventory.menu.get_item_text(i))
 check("Guardar arma na mochila" in labels and "Deixar 1 no chão" in labels,"Menu de contexto oferece ações reais da arma")
 ui.inventory.menu.hide()
 # Sorting by weight puts the heaviest stack first when descending.
 ui.inventory.bag_list.sort_key = "weight"
 ui.inventory.bag_list.sort_ascending = false
 var ordered: Array = ui.inventory.bag_list.ordered_ids()
 var heaviest: float = 0.0
 for id in inv.stacks:
  heaviest = maxf(heaviest,Items.info(id)["weight"]*inv.count(id))
 check(is_equal_approx(Items.info(ordered[0])["weight"]*inv.count(ordered[0]),heaviest),"Ordenar por peso coloca a pilha mais pesada no topo")
 ui.inventory.bag_list.sort_key = "category"
 ui.inventory.bag_list.sort_ascending = true
 ui.close_all()
 # Dropping several units uses one pile on the same spot.
 p.position = game.layout.to_world(Vector2i(10,13))
 inv.add("ore",3)
 var piles_before: int = game.containers.size()
 game.drop_item("ore",2)
 game.drop_item("ore",1)
 check(game.containers.size() == piles_before+1 and game.containers[-1]["items"].get("ore") == 3,"Itens deixados no mesmo lugar formam uma única pilha")
 var pile: Dictionary = game.containers[-1]
 inv.transfer_from(pile["items"],"ore",3)
 # Empty chests can be opened to store things.
 var empty_chest: Dictionary = game.containers[3]
 var saved_items: Dictionary = empty_chest["items"].duplicate()
 empty_chest["items"].clear()
 p.position = Vector3(empty_chest["pos"][0]+1.0,0,empty_chest["pos"][1])
 check(game.nearest_container() == empty_chest and game.interaction_text().contains("vazio"),"Baú vazio pode ser aberto para guardar itens")
 empty_chest["items"] = saved_items
 inv.remove("ore",inv.count("ore"))
 # Layout: fixed HUD pieces never overlap and stay on screen at the design size.
 ui.update_hud()
 await wait_frames(2)
 var view := Rect2(Vector2.ZERO,Vector2(1440,900))
 var pieces := {"barra lateral":ui.sidebar,"mochila recolhida":ui.inventory.bag_window,"arredores recolhido":ui.inventory.loot_window,"painel de condição":ui.status_panel,"barra rápida":ui.hotbar,"em mãos":ui.hands}
 var names: Array = pieces.keys()
 for i in names.size():
  var r: Rect2 = rect_of(pieces[names[i]])
  check(view.encloses(r),"HUD dentro da tela: "+names[i])
  for j in range(i+1,names.size()):
   check(not r.intersects(rect_of(pieces[names[j]])),"HUD sem sobreposição: %s × %s" % [names[i],names[j]])
 ui.open_inventory(game.containers[0])
 await wait_frames(2)
 for window in [ui.inventory.bag_window,ui.inventory.loot_window]:
  check(not rect_of(window).intersects(rect_of(ui.status_panel)) and not rect_of(window).intersects(Rect2(ui.moodles.global_position,Vector2(44,400))),"Janela de inventário aberta não cobre condição nem indicadores")
 ui.close_all()
 ui.toggle_health()
 await wait_frames(3)
 check(not rect_of(ui.health_panel).intersects(Rect2(ui.moodles.global_position,Vector2(44,400))) and not rect_of(ui.health_panel).intersects(rect_of(ui.status_panel)),"Janela de condição não cobre indicadores nem painel de condição")
 ui.health_panel.move_to(Vector2(5000,-300))
 check(view.encloses(Rect2(ui.health_panel.position,Vector2(ui.health_panel.size.x,UiWindow.TITLE_HEIGHT))),"Arrastar janela para fora mantém a barra de título na tela")
 ui.health_panel.position = Vector2(976,412)
 ui.toggle_health()
 p.position = game.layout.to_world(game.layout.spawn)

func test_data() -> void:
 # Item catalog: every entry complete, text translated, numbers sane.
 check(Items.DATA.size() >= 7,"Catálogo de itens carrega de data/itens.json")
 for id in Items.DATA:
  var d: Dictionary = Items.info(id)
  var complete: bool = d.has("tag") and d.has("weight") and d.has("model") and float(d["weight"]) > 0
  check(complete and UiStyle.CATEGORIES.has(d["tag"]),"Item completo e com categoria conhecida: "+id)
  check(not str(d["name"]).begins_with("ITEM_") and not str(d["description"]).begins_with("ITEM_"),"Nome e descrição traduzidos: "+id)
  if d.has("damage"):
   check(float(d["range"]) > 0 and float(d["cost"]) > 0 and float(d["windup"]) < float(d["cooldown"]),"Arma com números coerentes: "+id)
 # Monster types
 for kind in EnemyTypes.DATA:
  var e: Dictionary = EnemyTypes.info(kind)
  check(float(e.get("health",0)) > 0 and float(e.get("speed",0)) > 0 and not EnemyTypes.display_name(kind).begins_with("INIMIGO_"),"Tipo de monstro completo: "+kind)
  for loot_id in e.get("loot",{}):
   check(Items.DATA.has(loot_id),"Espólio de %s usa item existente: %s" % [kind,loot_id])
 # World description: ids unique, everything placed on floor, references valid.
 var world: Dictionary = game.layout.world
 var ids: Dictionary = {}
 var unique: bool = true
 for c in world["containers"]:
  unique = unique and not ids.has(c["id"])
  ids[c["id"]] = true
  check(game.layout.is_floor(DungeonLayout.cell(c["cell"])),"Recipiente sobre o piso: "+c["id"])
  for item_id in c["items"]:
   check(Items.DATA.has(item_id),"Recipiente %s usa item existente: %s" % [c["id"],item_id])
 for e in world["enemies"]:
  unique = unique and not ids.has(e["id"])
  ids[e["id"]] = true
  check(EnemyTypes.DATA.has(e["type"]) and game.layout.is_floor(DungeonLayout.cell(e["cell"])),"Monstro com tipo válido sobre o piso: "+e["id"])
 check(unique,"Identificadores do mundo são únicos")
 for key in ["spawn","camp","camp_exit"]:
  check(game.layout.is_floor(DungeonLayout.cell(world[key])),"Ponto do mundo sobre o piso: "+key)
 for room in game.layout.rooms:
  check(not str(room["name"]).begins_with("SALA_"),"Nome de sala traduzido: "+room["id"])
 check(game.layout.is_safe(game.layout.to_world(game.layout.spawn)),"Início fica na sala segura")
 for c in game.containers:
  check(str(c.get("id","")) != "","Recipiente em jogo tem identificador: "+str(c["name"]))
 for enemy in game.enemies:
  check(enemy.uid != "" and enemy.maximum_health == float(EnemyTypes.info(enemy.kind)["health"]),"Monstro em jogo usa os dados do tipo: "+enemy.uid)
 # The description format is the seam for the future generator: a tiny
 # hand-written world builds floors, rooms and routes the same way.
 var tiny := {"id":"teste","name":"MUNDO_CISTERNAS_NOME","cell_size":2.0,"size":[12,6],"spawn":[1,1],"camp":[1,2],"camp_exit":[0,2],
  "rooms":[{"id":"a","name":"SALA_ABRIGO","rect":[0,0,4,4],"safe":true},{"id":"b","name":"SALA_GALERIA","rect":[8,0,4,4]}],
  "corridors":[[4,1,4,1]],"blocked":[],"furniture":[],"containers":[{"id":"x","name":"RECIPIENTE_RESERVA","cell":[9,1],"items":{},"chest":true,"objective":true}],"enemies":[]}
 var small := DungeonLayout.new(tiny)
 check(small.route(small.to_world(Vector2i(1,1)),small.to_world(Vector2i(10,2))).size() > 0 and small.relic == Vector2i(9,1),"Descrição mínima de mundo gera piso, rotas e objetivo")
 # Saves written before ids existed still load and get the world's ids back.
 check(game.save_game(false),"Save com identificadores é gravado")
 var raw = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
 for c in raw["containers"]:
  c.erase("id")
 for e in raw["enemies"]:
  e.erase("id")
 raw.erase("world")
 var file := FileAccess.open(game.save_path,FileAccess.WRITE)
 file.store_string(JSON.stringify(raw))
 file.close()
 check(game.load_game() and game.containers[0]["id"] == "reserva_entrada" and game.containers[4]["id"] == "relicario","Save antigo sem identificadores carrega e recupera os ids do mundo")

func fresh(enemy, pos: Vector3) -> void:
 enemy.set_physics_process(false)
 enemy.alive = true
 enemy.health = enemy.maximum_health
 enemy.aggro = false
 enemy.stagger = 0
 enemy.firm = 0
 enemy.windup = 0
 enemy.bleed_time = 0
 enemy.bleed_dps = 0
 enemy.stuck = {}
 enemy.impulse = Vector3.ZERO
 enemy.collision_layer = 4
 enemy.collision_mask = 7
 enemy.position = pos

func swing(id: String, facing: Vector3) -> bool:
 var p = game.player
 var inv = game.inventory
 if inv.count(id) == 0:
  inv.add(id)
 inv.equip(id)
 p.cooldown = 0
 p.attack_timer = 0
 p.attack_wait = 0
 p.hurt_timer = 0
 p.dodge_timer = 0
 p.stamina = 100
 p.facing = facing
 var ok: bool = p.attack()
 if ok:
  game.resolve_player_attack()
 return ok

func ground_count(id: String, near: Vector3, radius: float) -> int:
 var n: int = 0
 for c in game.containers:
  if not c.get("chest", true) and Vector3(c["pos"][0],0,c["pos"][1]).distance_to(near) < radius:
   n += int(c["items"].get(id,0))
 return n

func test_weapons() -> void:
 get_tree().paused = false
 var p = game.player
 var inv = game.inventory
 var saved_inventory: Dictionary = inv.snapshot()
 inv.restore({"stacks":{},"equipped":""})
 p.set_physics_process(false)
 for e in game.enemies:
  e.set_physics_process(false)
  e.position = game.layout.to_world(Vector2i(28,7))
 var weapons: Array = []
 for id in Items.DATA:
  if Items.DATA[id]["tag"] == "ARMA":
   weapons.append(id)
 check(weapons.size() >= 13,"Catálogo tem as armas novas (%d armas)" % weapons.size())
 for id in weapons:
  var model: Node3D = Visuals.item_model(id)
  var meshes: int = model.find_children("*","MeshInstance3D",true,false).size()
  check(meshes > 0 and (not Items.DATA[id].has("blocks") or model.get_meta("placeholder",false)),"Arma tem modelo (blocos provisórios quando não há .glb): "+id)
  model.free()
  inv.add(id)
  inv.equip(id)
  p.refresh_weapon()
  check(is_instance_valid(p.held_weapon),"Personagem segura a arma: "+id)
  inv.remove(id)
 check(ProficiencyTree.path_text(Items.info("katana")["proficiencias"]) == "Lâminas › Espadas › Sabre","Arma indica o ramo de proficiência que treina")
 # Real models from the asset packs: right length, grip at the origin.
 var lengths := {"adaga":0.42,"katana":1.0,"montante":1.6,"machado":0.78,"maca":0.79,"martelo":1.27,"spear":2.6,"lanca_longa":3.1,"alabarda":2.62,"arco":1.16,"besta":0.79,"flecha":0.73,"virote":0.45}
 for id in lengths:
  var real: Node3D = Visuals.item_model(id)
  add_child(real)
  var box := AABB()
  var first := true
  for mesh in real.find_children("*","MeshInstance3D",true,false):
   var b: AABB = mesh.global_transform*mesh.get_aabb()
   box = b if first else box.merge(b)
   first = false
  var grip_inside: bool = box.position.y <= 0.001 and box.end.y > 0.0
  check(Visuals.has_custom_model(id) and not real.get_meta("placeholder",false) and absf(box.size.y-lengths[id]) < 0.02 and grip_inside,"Modelo real de %s: %s m, empunhadura na origem" % [id,UiStyle.fmt(box.size.y,2)])
  real.free()
 var at: Vector3 = game.layout.to_world(Vector2i(5,12))
 p.position = at
 var e0 = game.enemies[0]
 var e1 = game.enemies[1]
 var e2 = game.enemies[2]
 var guard = game.enemies[6]
 # Dagger: sneak attack on an unaware monster.
 fresh(e0,at+Vector3(1.1,0,0))
 swing("adaga",Vector3.RIGHT)
 var dagger: float = float(Items.info("adaga")["damage"])
 check(is_equal_approx(e0.health,e0.maximum_health-dagger*2.5),"Adaga: dano ×2,5 em monstro desprevenido")
 swing("adaga",Vector3.RIGHT)
 check(is_equal_approx(e0.health,e0.maximum_health-dagger*2.5-dagger),"Adaga: dano normal quando o monstro já está alerta")
 inv.remove("adaga")
 # Katana: up to two targets in a narrow arc.
 fresh(e0,at+Vector3(1.2,0,0.2))
 fresh(e1,at+Vector3(1.5,0,-0.3))
 fresh(e2,at+Vector3(1.8,0,0.1))
 swing("katana",Vector3.RIGHT)
 var hit_count: int = [e0,e1,e2].filter(func(e): return e.health < e.maximum_health).size()
 check(hit_count == 2,"Katana acerta até dois alvos")
 inv.remove("katana")
 # Axe: bleeding keeps hurting after the hit.
 fresh(e0,at+Vector3(1.2,0,0))
 fresh(e1,at+Vector3(-3,0,0))
 fresh(e2,at+Vector3(-3,0,2))
 swing("machado",Vector3.RIGHT)
 var axe_left: float = e0.maximum_health-float(Items.info("machado")["damage"])
 check(is_equal_approx(e0.health,axe_left) and e0.bleed_time > 4.9,"Machado: golpe abre sangramento")
 e0.tick_bleed(1.0)
 check(is_equal_approx(e0.health,axe_left-5.0),"Sangramento tira 5 de vida por segundo")
 e0.tick_bleed(5.0)
 check(e0.bleed_time == 0 and e0.health >= axe_left-25.1 and e0.alive,"Sangramento acaba depois do tempo")
 e0.health = 3
 e0.apply_bleed(5,5)
 var kills_before: int = game.kills
 e0.tick_bleed(1.0)
 check(not e0.alive and game.kills == kills_before+1,"Monstro pode morrer de sangramento")
 inv.remove("machado")
 # Mace: crushes armor and stuns longer.
 fresh(guard,at+Vector3(1.2,0,0))
 swing("maca",Vector3.RIGHT)
 var mace: float = float(Items.info("maca")["damage"])
 check(is_equal_approx(guard.health,guard.maximum_health-mace*1.5) and guard.armored,"Maça: dano ×1,5 em monstro blindado")
 check(guard.stagger >= 0.89,"Maça atordoa por mais tempo")
 fresh(e0,at+Vector3(1.2,0,0))
 fresh(guard,game.layout.to_world(Vector2i(28,7)))
 swing("maca",Vector3.RIGHT)
 check(is_equal_approx(e0.health,e0.maximum_health-mace),"Maça: dano normal em monstro sem armadura")
 inv.remove("maca")
 # War hammer: area in front, nothing behind.
 fresh(e0,at+Vector3(1.3,0,1.0))
 fresh(e1,at+Vector3(2.2,0,-0.6))
 fresh(e2,at+Vector3(-1.5,0,0))
 swing("martelo",Vector3.RIGHT)
 var hammer_left: float = e0.maximum_health-float(Items.info("martelo")["damage"])
 check(is_equal_approx(e0.health,hammer_left) and is_equal_approx(e1.health,hammer_left),"Martelo acerta todos na área à frente")
 check(is_equal_approx(e2.health,e2.maximum_health),"Martelo não acerta quem está atrás")
 inv.remove("martelo")
 # Halberd: pierces two in a line.
 fresh(e0,at+Vector3(1.3,0,0))
 fresh(e1,at+Vector3(2.4,0,0))
 fresh(e2,at+Vector3(3.3,0,0))
 swing("alabarda",Vector3.RIGHT)
 var halberd_left: float = e0.maximum_health-float(Items.info("alabarda")["damage"])
 check(is_equal_approx(e0.health,halberd_left) and is_equal_approx(e1.health,halberd_left) and is_equal_approx(e2.health,e2.maximum_health),"Alabarda atravessa o primeiro e acerta o segundo")
 inv.remove("alabarda")
 # Montante: wide arc, four targets.
 fresh(e0,at+Vector3(1.2,0,1.2))
 fresh(e1,at+Vector3(1.6,0,0))
 fresh(e2,at+Vector3(1.2,0,-1.2))
 swing("montante",Vector3.RIGHT)
 check([e0,e1,e2].all(func(e): return is_equal_approx(e.health,e.maximum_health-float(Items.info("montante")["damage"]))),"Montante acerta em arco largo")
 inv.remove("montante")
 # Bow: needs arrows, spends one on release, projectile flies and sticks.
 fresh(e0,at+Vector3(6.0,0,0))
 fresh(e1,game.layout.to_world(Vector2i(28,7)))
 fresh(e2,game.layout.to_world(Vector2i(28,7)))
 inv.add("arco")
 inv.equip("arco")
 game.ui.update_hud()
 check("ammo" in moodle_ids(),"Indicador de sem munição com arco e sem flechas")
 check(not swing("arco",Vector3.RIGHT),"Arco sem flechas não dispara")
 inv.add("flecha",5)
 game.ui.update_hud()
 game.quick_bar.assign(0,"arco")
 game.ui.update_hud()
 check(game.ui.hotbar.slots[0]["count"].text == "5","Barra rápida mostra as flechas do arco")
 check(swing("arco",Vector3.RIGHT) and inv.count("flecha") == 4,"Disparo gasta uma flecha")
 check(get_tree().get_nodes_in_group("projeteis").size() == 1,"Flecha voa como projétil")
 await wait_frames(30)
 check(is_equal_approx(e0.health,e0.maximum_health-float(Items.info("arco")["damage"])) and int(e0.stuck.get("flecha",0)) == 1,"Flecha acerta à distância e fica presa no monstro")
 check(get_tree().get_nodes_in_group("projeteis").is_empty(),"Projétil some depois de acertar")
 e0.receive_damage(999,Vector3.RIGHT)
 check(int(game.containers[-1]["items"].get("flecha",0)) == 1,"Flecha presa volta com os pertences do monstro")
 # Misses into a wall: half of them can be picked up.
 var wall_side: Vector3 = at+Vector3(-4.0,0,0)
 var before: int = ground_count("flecha",wall_side,3.5)
 game.ammo_recovery.clear()
 swing("arco",Vector3.LEFT)
 await wait_frames(20)
 swing("arco",Vector3.LEFT)
 await wait_frames(20)
 check(ground_count("flecha",wall_side,3.5) == before+1,"Metade das flechas que erram fica no chão")
 inv.remove("arco")
 # Crossbow: pierces two.
 fresh(e0,at+Vector3(3.0,0,0))
 fresh(e1,at+Vector3(5.0,0,0))
 fresh(e2,at+Vector3(7.0,0,0))
 inv.add("virote",3)
 swing("besta",Vector3.RIGHT)
 await wait_frames(30)
 var bolt_left: float = e0.maximum_health-float(Items.info("besta")["damage"])
 check(is_equal_approx(e0.health,bolt_left) and is_equal_approx(e1.health,bolt_left) and is_equal_approx(e2.health,e2.maximum_health),"Besta atravessa dois inimigos")
 check(int(e1.stuck.get("virote",0)) == 1 and int(e0.stuck.get("virote",0)) == 0,"Virote fica preso no último atingido")
 # Stuck ammunition survives a save.
 game.ui.close_all()
 check(game.save_game(false),"Save com munição presa é gravado")
 e1.stuck = {}
 game.load_game()
 check(int(game.enemies[1].stuck.get("virote",0)) == 1,"Munição presa no monstro volta ao carregar")
 inv.remove("besta")
 # HUD text
 var tip: Control = UiItemTooltip.build("martelo")
 var texts: Array = []
 for node in tip.find_children("*","Label",true,false):
  texts.append(node.text)
 var joined: String = " | ".join(texts)
 check(joined.contains("Contundentes › Marreta") and joined.contains("Pancada") and joined.contains("Duas mãos"),"Dica da marreta mostra família, golpe e empunhadura")
 check(joined.contains("Pesado") and joined.contains("Delay depois do golpe") and joined.contains("1,33 s") and joined.contains("esquiva em 0,34 s") and joined.contains("inclui 0,65 s do peso") and joined.contains("16"),"Dica do martelo mostra o peso, o delay (com 0,65 s do peso), quando a esquiva volta e o fôlego")
 tip.free()
 # Test arsenal
 var chest: Dictionary = game.spawn_test_arsenal()
 var all_there: bool = true
 for id in weapons:
  all_there = all_there and int(chest["items"].get(id,0)) == 1
 check(all_there and int(chest["items"].get("flecha",0)) == 40,"Arsenal de teste traz todas as armas e munição")
 game.containers.erase(chest)
 chest["node"].queue_free()
 for e in [e0,e1,e2,guard]:
  fresh(e,game.layout.to_world(Vector2i(28,7)))
 inv.restore(saved_inventory)
 game.quick_bar.defaults("sword")
 p.refresh_weapon()
 game.ui.close_all()

func test_proficiencies() -> void:
 get_tree().paused = false
 var p = game.player
 var inv = game.inventory
 var sheet: CharacterSheet = game.sheet
 var saved_inventory: Dictionary = inv.snapshot()
 sheet.enabled = true
 sheet.reset()
 # Split without double counting; equal pace for one or two branches.
 var added: float = sheet.award_path(["espadas","katana"],100.0)
 check(is_equal_approx(added,100.0) and is_equal_approx(sheet.path_xp(["espadas","katana"]),100.0),"Experiência se divide entre os ramos sem contar duas vezes")
 var one := CharacterSheet.new()
 var two := CharacterSheet.new()
 for i in 12:
  one.award_path(["adagas"],300.0)
  two.award_path(["espadas","katana"],300.0)
  check(one.mastery(["adagas"]) == two.mastery(["espadas","katana"]),"Mesmo esforço, mesmo domínio com um ou dois ramos (rodada %d)" % (i+1))
 var cross := CharacterSheet.new()
 cross.award_path(["espadas","espada_reta"],2000.0)
 check(cross.mastery(["espadas","katana"]) > 1 and cross.mastery(["espadas","katana"]) < cross.mastery(["espadas","espada_reta"]),"Praticar espada reta ajuda a katana pela raiz Espadas")
 # Attributes: potential and cap.
 var strong := CharacterSheet.new()
 strong.reset({"forca":9,"vigor":4,"agilidade":4,"destreza":3})
 check(is_equal_approx(strong.award("martelo",100.0),132.0) and strong.cap("martelo") == 46 and sheet.cap("martelo") == 30,"Força 9: martelo aprende ×1,32 e chega ao nível 46")
 strong.award("martelo",1.0e9)
 check(strong.level("martelo") == 46 and is_equal_approx(float(strong.xp["martelo"]),ProficiencyTree.xp_for_level(46)),"Ramo para no nível máximo do atributo")
 # Anti-repetition: weak monsters teach little to a master.
 var master := CharacterSheet.new()
 master.award_path(["adagas"],ProficiencyTree.xp_for_level(16))
 var e_weak = game.enemies[0]
 var gained: float = master.award_damage(e_weak,e_weak.maximum_health,["adagas"])
 check(gained < 30.0*0.1,"Monstro do 1º andar quase não ensina a quem já domina (ganhou %s)" % UiStyle.fmt(gained,2))
 # Perks and mastery change the weapon.
 var base: Dictionary = Items.info("sword")
 check(is_equal_approx(sheet.weapon_stats("sword")["damage"],base["damage"]) or sheet.mastery(["espadas","espada_reta"]) > 1,"Sem domínio, arma com números base")
 var veteran := CharacterSheet.new()
 veteran.award_path(["espadas","katana"],ProficiencyTree.xp_for_level(14)*2.0)
 var kat: Dictionary = veteran.weapon_stats("katana")
 check(int(kat["targets"]) == int(Items.info("katana")["targets"])+1 and is_equal_approx(kat["windup"],Items.info("katana")["windup"]-0.04),"Habilidades desbloqueadas mudam a arma (Corte amplo, Saque rápido)")
 check(kat["damage"] > Items.info("katana")["damage"] and kat["cost"] < Items.info("katana")["cost"],"Domínio aumenta o dano e reduz o fôlego do golpe")
 # Practice in play: hits, bleeding, dodges, treatment.
 sheet.reset()
 p.position = game.layout.to_world(Vector2i(5,12))
 for e in game.enemies:
  fresh(e,game.layout.to_world(Vector2i(28,7)))
 var e0 = game.enemies[0]
 fresh(e0,p.position+Vector3(1.2,0,0))
 e0.aggro = true
 swing("sword",Vector3.RIGHT)
 var expected: float = 30.0*24.0/e0.maximum_health
 check(is_equal_approx(e0.health,e0.maximum_health-24.0) and is_equal_approx(float(sheet.xp.get("laminas",0)),expected*0.4) and is_equal_approx(float(sheet.xp.get("espadas",0)),expected*0.35) and is_equal_approx(float(sheet.xp.get("espada_reta",0)),expected*0.25),"Golpe ensina Lâminas, Espadas e Espada reta pelo dano causado")
 fresh(e0,p.position+Vector3(1.2,0,0))
 e0.aggro = true
 swing("machado",Vector3.RIGHT)
 var axe_before: float = float(sheet.xp.get("machados",0))
 e0.tick_bleed(2.0)
 check(float(sheet.xp.get("machados",0)) > axe_before,"Sangramento do machado também ensina Machados")
 inv.remove("machado")
 p.stamina = p.max_stamina
 p.dodge_timer = 0
 p.attack_timer = 0
 p.attack_wait = 0
 p.dodge_lock = 0
 p.hurt_timer = 0
 p.health = p.max_health
 check(p.dodge(),"Esquiva funciona com o custo do personagem")
 p.receive_damage(17,Vector3.RIGHT)
 check(p.health == p.max_health and float(sheet.xp.get("acrobacia",0)) > 0,"Escapar de um golpe esquivando ensina Acrobacia")
 p.dodge_timer = 0
 p.invulnerable = 0
 p.health = 50
 inv.add("bandage")
 game.use_item("bandage")
 var healed_xp: float = float(sheet.xp.get("tratamento",0))
 check(healed_xp > 0,"Tratar um ferimento ensina Tratamento")
 p.health = p.max_health
 game.use_item("bandage")
 check(is_equal_approx(float(sheet.xp.get("tratamento",0)),healed_xp),"Curativo sem ferimento não ensina nada")
 # Level-up notice
 game.ui.level_banner.queue.clear()
 sheet.award("adagas",500.0)
 check(not game.ui.level_banner.queue.is_empty() or game.ui.level_banner.card.visible,"Subir de nível mostra aviso na tela")
 # Attributes change the body and the backpack.
 sheet.reset({"forca":9,"vigor":4,"agilidade":4,"destreza":3})
 game.apply_attributes(true)
 check(is_equal_approx(inv.capacity,24.0) and is_equal_approx(inv.comfort,15.0),"Força 9: mochila de 24 kg, conforto até 15 kg")
 check(is_equal_approx(p.max_health,94.0) and is_equal_approx(p.max_stamina,95.0) and is_equal_approx(p.dodge_cost(),13.0),"Vigor e Agilidade 4: vida 94, fôlego 95, esquiva custa 13")
 inv.add("ore",12)
 check(inv.weight() > 18.0,"Com Força 9 cabe mais de 18 kg")
 sheet.award_path(["espadas","espada_reta"],777.0)
 var xp_before: Dictionary = sheet.xp.duplicate()
 game.ui.close_all()
 check(game.save_game(false),"Save com atributos e proficiências é gravado")
 sheet.reset()
 game.apply_attributes(true)
 check(game.load_game(),"Save com mochila acima de 18 kg (Força 9) carrega")
 check(sheet.attr("forca") == 9 and sheet.xp == xp_before and is_equal_approx(inv.capacity,24.0),"Atributos e experiência voltam do save")
 inv.remove("ore",inv.count("ore"))
 # Interface
 game.ui.toggle_proficiencies()
 await wait_frames(2)
 var window = game.ui.prof_window
 check(window.visible and window.rows.size() == ProficiencyTree.DATA.size(),"Janela de proficiências lista todos os ramos")
 inv.equip("sword")
 window.refresh()
 check(window.weapon_title.text.contains("nível") and window.rows["espada_reta"].active,"Janela destaca o caminho da arma em mãos")
 game.ui.toggle_proficiencies()
 var tip: Control = UiItemTooltip.build("sword")
 var texts: Array = []
 for node in tip.find_children("*","Label",true,false):
  texts.append(node.text)
 check(" ".join(texts).contains("Domínio"),"Dica da arma mostra o domínio")
 tip.free()
 var panel: UiCreationPanel = game.ui.creation_panel
 panel.reset()
 check(panel.total == 25 and panel.spent() == 20 and panel.start_button.disabled and label_text(panel).contains("Pontos livres: 5"),"Criação começa com 5 pontos livres a mais (25 no total)")
 for i in 3:
  panel._change("forca",1)
 panel._change("vigor",1)
 panel._change("vigor",1)
 check(panel.values["forca"] == 8 and panel.values["vigor"] == 7 and not panel.start_button.disabled,"Os 5 pontos livres vão em qualquer atributo")
 panel._change("agilidade",1)
 check(panel.values["agilidade"] == 5,"Criação não passa do total de pontos")
 panel._change("vigor",-1)
 panel._change("forca",1)
 check(panel.values["forca"] == 9 and panel.values["vigor"] == 6 and not panel.start_button.disabled,"Criação move pontos entre atributos")
 panel._change("forca",1)
 check(panel.values["forca"] == 9,"Atributo não passa do máximo")
 panel._change("agilidade",-1)
 check(panel.start_button.disabled,"Criação exige gastar todos os pontos")
 # Starting weapon: any weapon, or the fists.
 check(UiCreationPanel.weapon_ids().size() == 14 and panel.weapon == "sword" and panel.weapon_buttons["sword"].button_pressed,"Criação oferece todas as 13 armas e os punhos, com a espada marcada")
 panel.pick_weapon("katana")
 check(panel.choice()["arma"] == "katana" and panel.weapon_buttons["katana"].button_pressed and not panel.weapon_buttons["sword"].button_pressed and panel.weapon_label.text.contains("Sabre"),"Escolher a katana marca só ela e mostra o que ela treina")
 panel.pick_weapon("arco")
 check(panel.weapon_label.text.contains("20 flechas"),"Arco avisa que vem com flechas")
 panel.reset()
 game.choosing_character = true
 game.ui.show_creation()
 check(get_tree().paused and panel.visible and panel.weapon == "sword","Criação de personagem pausa e aparece")
 panel.confirmed.emit({"forca":8,"vigor":7,"agilidade":5,"destreza":5,"arma":"katana"})
 check(not get_tree().paused and not game.choosing_character and sheet.attr("forca") == 8 and sheet.attr("vigor") == 7 and sheet.xp.is_empty(),"Começar expedição aplica os atributos e zera a experiência")
 check(inv.equipped == "katana" and inv.count("sword") == 0 and inv.count("katana") == 1,"Começa com a arma escolhida em mãos, no lugar da espada")
 game.choose_weapon("besta")
 check(inv.equipped == "besta" and inv.count("virote") == 20,"Besta escolhida vem com 20 virotes")
 game.choose_weapon("")
 check(inv.equipped == "" and CharacterSheet.path_of(inv.equipped) == ["contundentes","desarmado"],"Punhos: começa sem arma em mãos, treinando Contundentes › Desarmado")
 # Back to the fixed numbers for the rest of the suite.
 sheet.reset()
 sheet.enabled = false
 game.apply_attributes(true)
 inv.restore(saved_inventory)
 p.refresh_weapon()
 game.ui.close_all()

func ready_player(p) -> void:
 p.cooldown = 0
 p.attack_timer = 0
 p.attack_wait = 0
 p.dodge_lock = 0
 p.hurt_timer = 0
 p.dodge_timer = 0
 p.invulnerable = 0
 p.bleeding = false

func label_text(node: Control) -> String:
 var texts: Array = []
 for child in node.find_children("*","Label",true,false):
  texts.append(child.text)
 return " | ".join(texts)

## Oblivion-inspired branches: Desarmado, Bloqueio, armors, Atletismo, Furtividade, Arrombamento.
func test_skills() -> void:
 get_tree().paused = false
 var p = game.player
 var inv = game.inventory
 var sheet: CharacterSheet = game.sheet
 var saved_inventory: Dictionary = inv.snapshot()
 var was_processing: bool = p.is_physics_processing()
 p.set_physics_process(false)
 sheet.enabled = true
 sheet.reset()
 game.apply_attributes(true)
 inv.restore({"stacks":{},"equipped":""})
 var at: Vector3 = game.layout.to_world(Vector2i(5,12))
 p.position = at
 p.sneaking = false
 p.sprinting = false
 p.aiming = false
 for e in game.enemies:
  fresh(e,game.layout.to_world(Vector2i(28,7)))
 var e0 = game.enemies[0]
 # --- Tree
 check(ProficiencyTree.path_text(CharacterSheet.path_of("adaga")) == "Lâminas › Adagas" and ProficiencyTree.path_text(CharacterSheet.path_of("besta")) == "Pontaria › Bestas" and CharacterSheet.path_of("machado") == ["contundentes","machados"],"Lâminas, Contundentes e Pontaria são raízes das armas")
 check(ProficiencyTree.group_of("katana") == "combate" and ProficiencyTree.group_of("arcos") == "furtividade" and ProficiencyTree.group_of("arrombamento") == "furtividade" and ProficiencyTree.group_of("tratamento") == "sobrevivencia","Ramos agrupados em Combate, Furtividade e Sobrevivência")
 var old := CharacterSheet.new()
 check(old.restore({"attrs":{"forca":5,"vigor":5,"agilidade":5,"destreza":5},"xp":{"esquiva":120.0,"ramo_sumido":50.0}}) and is_equal_approx(float(old.xp.get("acrobacia",0)),120.0) and not old.xp.has("esquiva") and not old.xp.has("ramo_sumido"),"Save antigo: Esquiva vira Acrobacia, ramo desconhecido é descartado")
 # --- Desarmado
 fresh(e0,at+Vector3(1.1,0,0))
 e0.aggro = true
 ready_player(p)
 p.stamina = p.max_stamina
 p.facing = Vector3.RIGHT
 check(p.attack(),"Sem arma, o personagem soca")
 game.resolve_player_attack()
 check(is_equal_approx(e0.health,e0.maximum_health-8.0) and float(sheet.xp.get("desarmado",0)) > 0,"Soco tira 8 de vida e ensina Desarmado")
 var brawler := CharacterSheet.new()
 brawler.award("desarmado",ProficiencyTree.xp_for_level(5)+1.0)
 check(brawler.weapon_stats("")["damage"] > 12.0,"Desarmado nível 5: soco mais forte (%s)" % UiStyle.fmt(brawler.weapon_stats("")["damage"],1))
 # --- Bloqueio
 inv.add("sword")
 inv.equip("sword")
 ready_player(p)
 p.facing = Vector3.RIGHT
 p.aiming = true
 p.health = p.max_health
 p.stamina = p.max_stamina
 check(p.can_block() and "guard" in moodle_ids(),"Botão direito com arma corpo a corpo levanta a guarda")
 p.receive_damage(20,Vector3.LEFT)
 check(is_equal_approx(p.health,p.max_health-12.0) and is_equal_approx(p.stamina,p.max_stamina-4.0) and p.hurt_timer == 0,"Guarda segura 40% do golpe de frente, gasta fôlego (metade do dano segurado) e não interrompe")
 check(float(sheet.xp.get("bloqueio",0)) > 0,"Segurar um golpe ensina Bloqueio")
 ready_player(p)
 p.health = p.max_health
 p.receive_damage(20,Vector3.RIGHT)
 check(is_equal_approx(p.health,p.max_health-20.0),"Golpe pelas costas passa pela guarda")
 ready_player(p)
 p.health = p.max_health
 p.receive_damage(30,Vector3.LEFT,false)
 check(is_equal_approx(p.health,p.max_health-30.0),"Pancada em área do chefe não é bloqueável")
 ready_player(p)
 p.health = p.max_health
 p.stamina = 2
 p.receive_damage(20,Vector3.LEFT)
 check(is_equal_approx(p.health,p.max_health-20.0) and p.stamina == 0,"Sem fôlego, a guarda quebra")
 inv.unequip()
 ready_player(p)
 p.health = p.max_health
 p.stamina = p.max_stamina
 p.receive_damage(20,Vector3.LEFT)
 check(is_equal_approx(p.health,p.max_health-15.0),"Guarda de punhos segura menos (25%)")
 inv.add("arco")
 inv.equip("arco")
 check(not p.can_block(),"Arco não bloqueia")
 inv.remove("arco")
 p.aiming = false
 var shield := CharacterSheet.new()
 shield.award("bloqueio",ProficiencyTree.xp_for_level(10)+1.0)
 check(shield.block_reduction("sword") > 0.6 and shield.block_cost_mult() < 0.8,"Bloqueio nível 10: guarda mais firme e mais barata")
 # --- Armaduras
 inv.add("cota")
 check(game.use_item("cota") and inv.armor == "cota","Vestir a cota de malha pelo inventário")
 check(is_instance_valid(p.worn_model) and p.worn_model.get_parent() == p.armor_mount and (p.armor_mount if p.armor_mount is BoneAttachment3D else p.armor_mount.get_parent()).bone_name in ["spine","mixamorig_Spine"],"Armadura vestida aparece no tronco do personagem")
 check(is_equal_approx(sheet.armor_protection("cota"),0.25) and is_equal_approx(sheet.armor_speed_penalty("cota"),0.06) and is_equal_approx(p.detection_mult(),1.125),"Cota: 25% de proteção, 6% mais lenta e barulhenta")
 ready_player(p)
 p.health = p.max_health
 p.receive_damage(20,Vector3.RIGHT)
 check(is_equal_approx(p.health,p.max_health-15.0) and float(sheet.xp.get("armadura_pesada",0)) > 0,"Armadura absorve parte do golpe e ensina Armadura pesada")
 inv.add("sword")
 inv.equip("sword")
 ready_player(p)
 p.aiming = true
 p.health = p.max_health
 p.stamina = p.max_stamina
 p.receive_damage(20,Vector3.LEFT)
 check(is_equal_approx(p.health,p.max_health-9.0),"Guarda e armadura somam: 20 → 12 → 9")
 p.aiming = false
 game.ui.open_inventory()
 var bag_row = game.ui.inventory.bag_list.row_for("cota")
 check(bag_row != null and bag_row.tag_text == "VESTIDA" and game.ui.inventory._use_label("cota") == "Tirar","Mochila marca a armadura vestida")
 game.ui.close_all()
 var armor_tip: Control = UiItemTooltip.build("cota")
 check(label_text(armor_tip).contains("Proteção"),"Dica da armadura mostra a proteção")
 armor_tip.free()
 game.ui.close_all()
 check(game.save_game(false),"Save com armadura vestida é gravado")
 inv.take_off()
 check(game.load_game() and inv.armor == "cota","Armadura vestida volta do save")
 var knight := CharacterSheet.new()
 knight.award("armadura_pesada",ProficiencyTree.xp_for_level(10)+1.0)
 check(knight.armor_protection("cota") > 0.3 and knight.armor_speed_penalty("cota") < 0.03,"Armadura pesada nível 10: protege mais e pesa menos")
 inv.add("couro")
 game.use_item("couro")
 check(inv.armor == "couro" and is_equal_approx(sheet.armor_speed_penalty("couro"),0.0) and is_equal_approx(sheet.armor_protection("couro"),0.15),"Couro: armadura leve, sem perder velocidade")
 var scout := CharacterSheet.new()
 scout.award("armadura_leve",ProficiencyTree.xp_for_level(5)+1.0)
 check(scout.armor_noise("couro") == 0.0 and scout.armor_protection("couro") > 0.19,"Armadura leve nível 5: silenciosa e mais protetora")
 inv.remove("couro")
 check(inv.armor == "" and p.worn_model == null,"Largar a armadura vestida tira ela do corpo")
 inv.remove("cota")
 # --- Atletismo
 for e in game.enemies:
  e.aggro = false
 var a0: float = float(sheet.xp.get("atletismo",0))
 game.on_sprint(10.0)
 var calm: float = float(sheet.xp.get("atletismo",0))-a0
 e0.aggro = true
 game.on_sprint(10.0)
 var chased: float = float(sheet.xp.get("atletismo",0))-a0-calm
 e0.aggro = false
 check(calm > 0 and is_equal_approx(chased,calm*5.0),"Correr ensina Atletismo, cinco vezes mais quando perseguido")
 var runner := CharacterSheet.new()
 runner.award("atletismo",ProficiencyTree.xp_for_level(5)+1.0)
 check(runner.sprint_cost_mult() < 0.75,"Atletismo nível 5: correr cansa menos")
 # --- Furtividade
 check(is_equal_approx(p.detection_mult(),1.0),"De pé, sem armadura: alcance de visão normal")
 p.toggle_sneak()
 check(p.sneaking and "sneak" in moodle_ids(),"C agacha e mostra o indicador de furtivo")
 var still: Array = p.locomotion(0.0)
 var walking: Array = p.locomotion(2.0)
 check(still[0] == ("furtivo" if p.animator.has_animation("furtivo") else "guard") and walking[0] == ("furtivo_andar" if p.animator.has_animation("furtivo_andar") else "walk"),"Furtivo usa as animações próprias quando existem, senão as provisórias")
 fresh(e0,at+Vector3(4.0,0,0))
 e0.visual.rotation.y = atan2(-1.0,0.0)
 var front: float = p.detection_mult(e0)
 e0.visual.rotation.y = atan2(1.0,0.0)
 var behind: float = p.detection_mult(e0)
 check(is_equal_approx(front,0.5) and is_equal_approx(behind,0.3),"Furtivo: notado a metade da distância de frente, menos ainda por trás")
 # Live: an unaware monster 5 m away facing the adventurer.
 fresh(e0,at+Vector3(5.0,0,0))
 e0.home = e0.position
 e0.visual.rotation.y = atan2(-1.0,0.0)
 e0.sneak_budget = 10.0
 var f0: float = float(sheet.xp.get("furtividade",0))
 e0.set_physics_process(true)
 await wait_frames(4)
 e0.set_physics_process(false)
 check(not game.is_safe() and not e0.aggro and float(sheet.xp.get("furtividade",0)) > f0 and e0.sneak_budget < 10.0,"Monstro não nota quem passa furtivo a 5 m, e isso ensina Furtividade")
 e0.sneak_budget = 1.0
 for i in 20:
  game.on_sneak_near(e0,1.0)
 check(e0.sneak_budget == 0.0,"Cada monstro só ensina furtividade até um limite")
 p.sneaking = false
 e0.position = at+Vector3(5.0,0,0)
 e0.set_physics_process(true)
 await wait_frames(2)
 e0.set_physics_process(false)
 check(e0.aggro,"De pé, o mesmo monstro nota a 5 m")
 p.sneaking = true
 fresh(e0,at+Vector3(1.2,0,0))
 inv.equip("sword")
 var s0: float = float(sheet.xp.get("furtividade",0))
 swing("sword",Vector3.RIGHT)
 check(is_equal_approx(e0.health,e0.maximum_health-24.0*1.5) and float(sheet.xp.get("furtividade",0)) > s0,"Ataque furtivo: dano ×1,5 com qualquer arma e ensina Furtividade")
 swing("sword",Vector3.RIGHT)
 check(is_equal_approx(e0.health,e0.maximum_health-36.0-24.0),"Monstro alerta leva dano normal")
 p.sneaking = false
 var shadow := CharacterSheet.new()
 shadow.award("furtividade",ProficiencyTree.xp_for_level(10)+1.0)
 check(shadow.sneak_detection_mult() < 0.4 and shadow.sneak_attack_mult() == 2.0,"Furtividade nível 10: menos visto, ataque furtivo ×2")
 # --- Arrombamento
 fresh(e0,game.layout.to_world(Vector2i(28,7)))
 p.position = at
 var chest: Dictionary = game.add_loot("Baú trancado",game.layout.to_cell(at),{"gema":2},true,"teste_tranca",2)
 check(game.interaction_text().contains("TRANCADO"),"Baú trancado pede gazua")
 check(not game.attempt_lockpick(chest) and int(chest.get("lock",0)) == 2,"Sem gazua o baú não abre")
 game.ui.open_inventory(chest)
 var panel = game.ui.inventory
 check(panel.locked() and panel.loot_list.ordered_ids().is_empty() and panel.lock_button.visible,"Baú trancado esconde o que guarda")
 panel.take("gema",1)
 panel.take_all()
 check(inv.count("gema") == 0 and int(chest["items"].get("gema",0)) == 2,"Não dá para tirar itens de um baú trancado")
 game.ui.close_all()
 inv.add("gazua",3)
 check(game.interaction_text().contains("ARROMBAR") and game.interaction_text().contains("40%"),"Com gazua, mostra a chance de abrir (fechadura média: 40%)")
 var k0: float = float(sheet.xp.get("arrombamento",0))
 check(not game.attempt_lockpick(chest,0.99,0.99) and inv.count("gazua") == 3 and int(chest["lock"]) == 2,"Tentativa falha sem quebrar a gazua")
 var k1: float = float(sheet.xp.get("arrombamento",0))
 check(not game.attempt_lockpick(chest,0.99,0.0) and inv.count("gazua") == 2,"Tentativa falha pode quebrar a gazua")
 var k2: float = float(sheet.xp.get("arrombamento",0))
 check(game.attempt_lockpick(chest,0.0) and not chest.has("lock") and game.ui.inventory.is_open,"Fechadura cede e o baú abre")
 var k3: float = float(sheet.xp.get("arrombamento",0))
 check(k1 > k0 and k3-k2 > (k1-k0)*3.0,"Tentar ensina Arrombamento; abrir ensina bem mais")
 game.ui.take_all()
 check(inv.count("gema") == 2,"Depois de aberto, o baú entrega o conteúdo")
 game.ui.close_all()
 check(is_equal_approx(sheet.pick_chance(1),0.6) and is_equal_approx(sheet.pick_chance(4),0.05) and is_equal_approx(sheet.pick_break_chance(),0.5),"Chance cai com a fechadura: simples 60%, de mestre 5%")
 var thief := CharacterSheet.new()
 thief.award("arrombamento",ProficiencyTree.xp_for_level(10)+1.0)
 check(thief.pick_chance(4) > 0.45 and is_equal_approx(thief.pick_break_chance(),0.25),"Arrombamento nível 10: abre fechaduras de mestre e quebra menos gazuas")
 game.containers.erase(chest)
 chest["node"].queue_free()
 var sealed: Dictionary = game.add_loot("Baú selado",game.layout.to_cell(at),{"gema":1},true,"teste_tranca2",3)
 check(game.save_game(false),"Save com baú trancado é gravado")
 sealed.erase("lock")
 game.load_game()
 var again: Array = game.containers.filter(func(c): return c["id"] == "teste_tranca2")
 check(again.size() == 1 and int(again[0].get("lock",0)) == 3,"Fechadura continua trancada depois de carregar")
 for c in again:
  game.containers.erase(c)
  c["node"].queue_free()
 var raw = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
 raw["containers"][0]["lock"] = "aberta"
 var file := FileAccess.open(game.save_path,FileAccess.WRITE)
 file.store_string(JSON.stringify(raw))
 file.close()
 check(not game.load_game(),"Save com fechadura inválida é recusado")
 # Back to the fixed numbers for the rest of the suite.
 for e in game.enemies:
  fresh(e,game.layout.to_world(Vector2i(28,7)))
 p.sneaking = false
 p.aiming = false
 sheet.reset()
 sheet.enabled = false
 game.apply_attributes(true)
 inv.restore(saved_inventory)
 p.refresh_weapon()
 p.set_physics_process(was_processing)
 game.ui.close_all()

func psx_surface(node: Node) -> bool:
 for mesh in node.find_children("*","MeshInstance3D",true,false):
  for i in mesh.get_surface_override_material_count():
   if mesh.get_surface_override_material(i) is ShaderMaterial:
    return true
 return false

## PlayStation-style filter: post-process, PSX materials, sharp world text, toggle.
func test_psx() -> void:
 get_tree().paused = false
 var p = game.player
 var psx: PsxFilter = game.psx
 game.set_psx(true)
 await wait_frames(2)
 check(psx.enabled and psx.screen.visible and psx.layer.layer < game.ui.layer,"Filtro PSX ligado fica entre o 3D e o HUD")
 check(psx.pixel_size() >= 1.0 and is_equal_approx(float(psx.post.get_shader_parameter("pixel_size")),psx.pixel_size()),"Tamanho do pixel acompanha a altura da janela")
 check(psx_surface(p.visual) and psx_surface(game.enemies[0].visual),"Personagem e monstros usam os materiais PSX")
 var batches: Array = game.world_root.find_children("*","MultiMeshInstance3D",true,false)
 check(not batches.is_empty() and batches.all(func(b): return b.has_meta("psx_mesh") or b.multimesh.mesh.get_surface_count() == 0),"Chão e paredes em lote também recebem os materiais PSX")
 check(game.aim_marker.ring.material_override is StandardMaterial3D,"Anéis e marcadores sem sombra ficam como estão")
 # A weapon equipped now is converted on the next frame.
 game.inventory.add("machado")
 game.inventory.equip("machado")
 await wait_frames(2)
 check(psx_surface(p.weapon_mount),"Arma equipada com o filtro ligado vira PSX")
 var label: Label3D = game.enemies[0].health_label
 check(label.layers == 0 and psx.overlay.get_child_count() > 0,"Texto do mundo vira rótulo 2D nítido acima do filtro")
 var ui_label_count: int = psx.overlay.get_child_count()
 # Off: everything back to the original materials, and the choice is saved.
 game.ui.toggle_pause()
 game.ui.psx_button.pressed.emit()
 await wait_frames(2)
 check(not psx.enabled and not psx.screen.visible and game.ui.psx_button.text == "Filtro PSX: desligado","Botão da pausa desliga o filtro")
 check(not psx_surface(p.visual) and not psx_surface(p.weapon_mount) and label.layers != 0,"Desligar devolve os materiais e o texto originais")
 check(game.load_setting("video","psx",true) == false,"Preferência do filtro fica salva")
 await wait_frames(2)
 check(psx.overlay.get_child_count() < ui_label_count or psx.overlay.get_children().all(func(c): return c.is_queued_for_deletion() or not c.visible),"Rótulos 2D somem com o filtro desligado")
 game.ui.psx_button.pressed.emit()
 await wait_frames(2)
 check(psx.enabled and psx_surface(p.visual) and psx_surface(p.weapon_mount) and game.ui.psx_button.text == "Filtro PSX: ligado","Ligar de novo reaplica o filtro")
 game.ui.close_all()
 game.inventory.remove("machado")
 game.inventory.equip("sword")
 DirAccess.remove_absolute(game.settings_path)

func teach(sheet: CharacterSheet, branch: String, level: int) -> void:
 sheet.award(branch, ProficiencyTree.xp_for_level(level) - float(sheet.xp.get(branch,0.0)) + 1.0)

## Habilidades: one of each, objetos with copies, slots by branch, order, use, lock.
func test_techniques() -> void:
 get_tree().paused = false
 var p = game.player
 var inv = game.inventory
 var sheet: CharacterSheet = game.sheet
 var book: TechniqueBook = game.techniques
 var saved_inventory: Dictionary = inv.snapshot()
 var was_processing: bool = p.is_physics_processing()
 p.set_physics_process(false)
 sheet.enabled = true
 sheet.reset()
 book.clear()
 inv.restore({"stacks":{"sword":1},"equipped":"sword"})
 var at: Vector3 = game.layout.to_world(Vector2i(5,12))
 p.position = at
 p.sneaking = false
 for e in game.enemies:
  fresh(e,game.layout.to_world(Vector2i(28,7)))
 check(Techniques.FORMS.size() >= 10 and Techniques.OBJECTS.size() >= 9,"Habilidades e objetos carregados")
 check(Techniques.forms_for("sword").has("corte") and not Techniques.forms_for("sword").has("estocada") and Techniques.forms_for("").has("soco"),"Habilidades conforme a arma em mãos")
 # Basic Corte with no objetos = the normal blow, plus a recharge.
 var base: Dictionary = sheet.weapon_stats("sword")
 var s0: Dictionary = Techniques.stats(sheet,"corte",[],"sword")
 check(Techniques.problem(sheet,book,"corte","sword") == "" and is_equal_approx(s0["damage"],base["damage"]) and is_equal_approx(s0["cost"],base["cost"]) and is_equal_approx(s0["recarga"],1.5),"Corte sem objetos tem os números do golpe normal")
 check(Techniques.problem(sheet,book,"corte_giratorio","sword").contains("Lâminas nível 4"),"Habilidade trancada diz o que falta")
 check(Techniques.copies(sheet,"forca") == 0 and Techniques.problem(sheet,book,"estocada","sword").contains("não serve"),"Sem proficiência não há objetos; habilidade de outra arma é recusada")
 # Copies by level.
 teach(sheet,"contundentes",3)
 check(Techniques.copies(sheet,"forca") == 1 and Techniques.next_copy_level(sheet,"forca") == 9,"Contundentes 3: uma cópia de Força; a próxima no nível 9")
 teach(sheet,"contundentes",9)
 check(Techniques.copies(sheet,"forca") == 2,"Contundentes 9: duas cópias de Força")
 # Slots: basic by weapon mastery, unlocked ones by their branch.
 check(Techniques.open_slots(sheet,"corte","sword") == 1,"Corte começa com 1 slot")
 sheet.award_path(CharacterSheet.path_of("sword"),ProficiencyTree.xp_for_level(11)*3.0)
 check(Techniques.open_slots(sheet,"corte","sword") == 3,"Domínio 11 na espada: Corte com 3 slots")
 teach(sheet,"laminas",4)
 var lam: int = sheet.level("laminas")
 check(Techniques.form_unlocked(sheet,"corte_giratorio") and Techniques.open_slots(sheet,"corte_giratorio","sword") == mini(2,1 + (lam-4)/4),"Corte giratório destrava e ganha slots pelo nível de Lâminas")
 teach(sheet,"laminas",3)
 teach(sheet,"acrobacia",3)
 teach(sheet,"hastes",3)
 # Order: each objeto acts on what is to its left.
 var a: Dictionary = Techniques.stats(sheet,"corte",["afiada","forca"],"sword")
 var b: Dictionary = Techniques.stats(sheet,"corte",["forca","afiada"],"sword")
 check(is_equal_approx(a["bleed"]["dps"],3.9) and is_equal_approx(b["bleed"]["dps"],3.0) and is_equal_approx(a["damage"],b["damage"]),"Força depois da Lâmina afiada fortalece o sangramento; antes, não")
 var w: float = sheet.weapon_stats("sword")["windup"]
 var c1: Dictionary = Techniques.stats(sheet,"corte",["forca","rapidez"],"sword")
 var c2: Dictionary = Techniques.stats(sheet,"corte",["rapidez","forca"],"sword")
 check(is_equal_approx(c1["windup"],(w+0.06)*0.6) and is_equal_approx(c2["windup"],w*0.6+0.06),"Rapidez encurta também o preparo que a Força somou antes dela")
 check(is_equal_approx(a["recarga"],1.5+2*0.75),"Cada objeto soma recarga")
 # Objetos from other weapons fit where it makes sense.
 var reach: Dictionary = Techniques.stats(sheet,"corte",["alcance"],"sword")
 check(Techniques.object_fits("alcance","sword") and is_equal_approx(reach["range"],base["range"]+0.5),"Alcance (das hastes) serve numa habilidade de espada")
 check(not Techniques.object_fits("afiada","martelo") and not Techniques.object_fits("afiada","") and Techniques.object_fits("afiada","arco"),"Lâmina afiada não faz sentido em pancada nem soco, mas serve em flecha")
 # Copies: one place at a time.
 book.set_objects("corte",["afiada","forca"])
 check(book.in_use("forca") == 1 and Techniques.problem(sheet,book,"corte","sword") == "","Corte com Lâmina afiada e Força")
 book.set_objects("corte_giratorio",["forca"])
 check(book.in_use("forca") == 2 and Techniques.problem(sheet,book,"corte_giratorio","sword") == "","Segunda cópia de Força no Corte giratório")
 sheet.xp["contundentes"] = ProficiencyTree.xp_for_level(3)
 check(Techniques.problem(sheet,book,"corte","sword").contains("usa 2"),"Com uma cópia só, usar Força em duas habilidades é recusado")
 teach(sheet,"contundentes",9)
 book.set_objects("corte_giratorio",[])
 # Bar and use.
 book.assign(0,"corte")
 book.assign(1,"corte_giratorio")
 book.assign(2,"corte")
 check(book.at_slot(0) == "" and book.at_slot(2) == "corte" and book.at_slot(1) == "corte_giratorio","Cada habilidade ocupa um lugar só na barra")
 book.assign(0,"corte")
 var e0 = game.enemies[0]
 fresh(e0,at+Vector3(1.2,0,0))
 e0.aggro = true
 ready_player(p)
 p.stamina = p.max_stamina
 p.facing = Vector3.RIGHT
 var expected: float = a["damage"]
 var xp_before: float = float(sheet.xp.get("contundentes",0))
 check(p.use_technique(0,false),"Tecla 4 usa a habilidade")
 game.resolve_player_attack()
 check(is_equal_approx(e0.health,e0.maximum_health-expected) and e0.bleed_time > 0 and is_equal_approx(e0.bleed_dps,3.9),"Corte com objetos: dano montado e sangramento de 3,9/s")
 check(book.remaining("corte") > 2.9 and float(sheet.xp.get("contundentes",0)) > xp_before,"Usar inicia a recarga e treina o ramo de cada objeto")
 ready_player(p)
 check(not p.use_technique(0,false),"Habilidade recarregando não sai")
 book.tick(10.0)
 # Spin hits behind too.
 fresh(e0,at+Vector3(-1.2,0,0))
 e0.aggro = true
 ready_player(p)
 p.stamina = p.max_stamina
 p.facing = Vector3.RIGHT
 check(p.use_technique(1,false),"Corte giratório sai")
 game.resolve_player_attack()
 check(e0.health < e0.maximum_health,"Corte giratório acerta quem está atrás")
 # Double hit.
 teach(sheet,"espadas",4)
 book.set_objects("corte",["duplo"])
 var duo: Dictionary = Techniques.stats(sheet,"corte",["duplo"],"sword")
 fresh(e0,at+Vector3(1.2,0,0))
 e0.aggro = true
 ready_player(p)
 p.stamina = p.max_stamina
 p.facing = Vector3.RIGHT
 book.tick(10.0)
 p.use_technique(0,false)
 game.resolve_player_attack()
 check(int(duo["hits"]) == 2 and is_equal_approx(e0.health,e0.maximum_health-2.0*duo["damage"]),"Golpe duplo acerta duas vezes com 65%")
 # Dash with a spear.
 teach(sheet,"hastes",4)
 inv.add("spear")
 inv.equip("spear")
 book.assign(3,"investida")
 fresh(e0,game.layout.to_world(Vector2i(28,7)))
 ready_player(p)
 p.stamina = p.max_stamina
 p.facing = Vector3.RIGHT
 check(p.use_technique(3,false) and p.dash_time > 0 and is_equal_approx(p.dash_velocity.length()*p.dash_time,2.5),"Investida avança 2,5 m no preparo")
 game.resolve_player_attack()
 p.dash_time = 0
 ready_player(p)
 check(not p.use_technique(0,false),"Habilidade de corte não sai com a lança")
 inv.equip("sword")
 book.set_objects("corte",["afiada","forca"])
 # Window: every habilidade, editable out of combat.
 game.ui.toggle_techniques()
 await wait_frames(2)
 var win: UiTechniqueWindow = game.ui.tech_window
 win.select("corte")
 check(win.visible and win.list_box.get_child_count() >= Techniques.FORMS.size() and win.problem_label.text.contains("Pronta"),"Janela lista todas as habilidades e mostra a prévia")
 win.move_left(1)
 check(book.objects("corte") == ["forca","afiada"],"Mudar a ordem na janela muda a habilidade")
 win.remove_object(0)
 win.add_object("alcance")
 check(book.objects("corte") == ["afiada","alcance"],"Tirar e pôr objetos na janela")
 win.select("corte_giratorio")
 win.add_object("forca")
 win.add_object("forca")
 check(book.objects("corte_giratorio").count("forca") == 1 or Techniques.open_slots(sheet,"corte_giratorio","sword") >= 2,"Slots limitam quantos objetos cabem")
 fresh(e0,at+Vector3(3,0,0))
 e0.aggro = true
 win.refresh(true)
 var before: Array = book.objects("corte_giratorio").duplicate()
 win.add_object("rapidez")
 check(game.in_combat() and win.combat_label.visible and book.objects("corte_giratorio") == before,"Com monstro caçando, a janela não muda nada")
 e0.aggro = false
 win.select("sequencia")
 win.assign(2)
 check(book.at_slot(2) != "sequencia","Habilidade trancada não vai para a barra")
 game.ui.toggle_techniques()
 # HUD bar.
 book.start("corte",4.0)
 book.tick(1.0)
 game.ui.update_hud()
 var hud_slot: Dictionary = game.ui.hotbar.tech_slots[0]
 check(hud_slot["shade"].size.y > 40.0 and hud_slot["time"].text == "3,0","Barra mostra a recarga")
 var tip: Control = game.ui.hotbar.technique_tooltip(0)
 check(label_text(tip).contains("Corte") and label_text(tip).contains("Objetos:"),"Dica da barra mostra a habilidade e os objetos")
 tip.free()
 book.recharge.clear()
 # Level-up notices.
 game.ui.level_banner.queue.clear()
 game.ui.on_level_up("pontaria",4)
 var texts: Array = game.ui.level_banner.queue.map(func(q): return str(q))
 check(" ".join(texts).contains("Nova habilidade: Tiro mirado"),"Subir de nível avisa habilidade nova")
 game.ui.level_banner.queue.clear()
 # The first bar key (Q unless the player changed it).
 fresh(e0,at+Vector3(1.2,0,0))
 e0.aggro = true
 ready_player(p)
 p.stamina = p.max_stamina
 var key := InputEventKey.new()
 key.physical_keycode = game.technique_keys[0]
 key.pressed = true
 game.ui._input(key)
 check(book.remaining("corte") > 0.0,"Tecla do 1º espaço (%s) usa a habilidade da barra" % game.technique_key_name(0))
 game.resolve_player_attack()
 # Save keeps the setup and the bar; old saves are read.
 var snap: Dictionary = book.snapshot()
 game.ui.close_all()
 check(game.save_game(false),"Save com habilidades é gravado")
 book.clear()
 check(game.load_game() and book.snapshot() == snap,"Habilidades e barra voltam do save")
 var old := TechniqueBook.new()
 old.restore({"recipes":[{"name":"X","form":"corte","components":["afiada","sumido"]},{"name":"Y","form":"corte","components":["forca"]},{"name":"Z","form":"inexistente","components":[]}],"bar":[1,0,2,"a"]})
 check(old.objects("corte") == ["afiada"] and old.bar == ["corte","","",""],"Save do formato anterior vira habilidades sem quebrar (uma montagem e um lugar na barra por habilidade)")
 var weird := TechniqueBook.new()
 weird.restore({"configs":{"corte":["forca","???"],"nada":["forca"]},"bar":["corte",3,"nada",""]})
 check(weird.objects("corte") == ["forca"] and weird.bar == ["corte","","",""],"Save estranho é limpo")
 # Back to the fixed numbers.
 for e in game.enemies:
  fresh(e,game.layout.to_world(Vector2i(28,7)))
 book.clear()
 sheet.reset()
 sheet.enabled = false
 game.apply_attributes(true)
 inv.restore(saved_inventory)
 p.refresh_weapon()
 p.set_physics_process(was_processing)
 game.ui.close_all()

## Live one-shot effects of one kind (Vfx.burst).
func effects(id: String) -> Array:
 return get_tree().get_nodes_in_group("efeitos").filter(func(n): return str(n.get_meta("efeito","")) == id and not n.is_queued_for_deletion())

## Effects (Brackeys VFX in PSX size): torches, campfire, hits, bleeding, guard, dodge, death.
func test_vfx() -> void:
 get_tree().paused = false
 var p = game.player
 var was_processing: bool = p.is_physics_processing()
 p.set_physics_process(false)
 check(Vfx.EFFECTS.size() >= 8 and Vfx.EFFECTS.keys().all(func(id): return not Vfx.sheet_of(id).is_empty() and ResourceLoader.exists("res://assets/vfx/%s.png" % Vfx.info(id)["folha"])),"Todo efeito tem sua folha em assets/vfx")
 var sheet_tex: Texture2D = load("res://assets/vfx/sangue.png")
 check(sheet_tex.get_width() <= 512 and Vfx.duration("sangue") > 0.3 and Vfx.duration("sangue") < 1.5,"Folhas pequenas (tamanho PSX) e efeitos curtos")
 # Torches and campfire.
 var flames: Array = get_tree().get_nodes_in_group("chamas")
 check(flames.size() > 3 and flames.all(func(f): return f.material_override is ShaderMaterial and float(f.material_override.get_shader_parameter("fps")) > 0.0),"Tochas com chama animada em vez da bolinha")
 check(flames.all(func(f): return f.material_override == flames[0].material_override),"Todas as chamas dividem um material (leve em andares grandes)")
 var fire: Node3D = game.world_root.get_node_or_null("Fogueira")
 check(fire != null and fire.global_position.distance_to(game.camp_position) < 0.1 and fire.find_children("*","OmniLight3D",true,false).size() == 1,"Fogueira no abrigo, com luz")
 # Walking into the fire stops beside it, still close enough to rest.
 var was_walking: bool = p.is_physics_processing()
 p.set_physics_process(true)
 ready_player(p)
 p.position = game.camp_position + Vector3(1.5,0,0)
 p.motion_velocity = Vector3.ZERO
 p.test_direction = Vector2(-0.5,-0.5)
 await wait_frames(60)
 p.test_direction = Vector2.ZERO
 await wait_frames(5)
 var gap: float = Vector2(p.position.x-game.camp_position.x,p.position.z-game.camp_position.z).length()
 check(gap > 0.45 and gap < 1.6 and game.interaction_text().to_lower().contains("descansar"),"Andar contra a fogueira para do lado dela, ainda perto para descansar (%s m)" % UiStyle.fmt(gap,2))
 p.set_physics_process(was_walking)
 var flicker = game.world_root.get_node_or_null("LuzesTremulas")
 check(flicker != null and flicker.lights.size() >= flames.size() - 2,"Luzes das tochas e da fogueira registradas para tremer")
 var near_light: OmniLight3D = fire.find_children("*","OmniLight3D",true,false)[0]
 p.position = game.camp_position + Vector3(1.5,0,0)
 game.camera_rig.snap()
 var energies: Array = []
 for i in 8:
  await get_tree().create_timer(0.07).timeout
  energies.append(near_light.light_energy)
 check(energies.max() - energies.min() > 0.02 and energies.max() <= float(near_light.get_meta("energia")) * 1.01,"Luz da fogueira treme sem passar da força original")
 # Hits on a monster.
 var foe = game.enemies[0]
 var room: Rect2i = game.layout.rooms[1]["rect"]
 p.position = game.layout.to_world(room.get_center())
 fresh(foe,p.position+Vector3(1.2,0,0))
 foe.visible = true
 foe.aggro = true
 p.sneaking = false
 var blood: int = effects("sangue").size()
 var flashes: int = effects("impacto").size()
 var strong: int = effects("golpe_forte").size()
 Combat.apply_hit(game,foe,{"damage":1.0},Vector3.RIGHT)
 check(effects("sangue").size() == blood+1 and effects("impacto").size() == flashes+1 and effects("golpe_forte").size() == strong,"Acerto comum: sangue e clarão, sem o estouro forte")
 var hit_node: Node3D = effects("sangue")[-1]
 check(absf(hit_node.global_position.y - (foe.global_position.y+1.15)) < 1.0 and hit_node.material_override != Vfx.material("sangue"),"Sangue na altura do peito e com material próprio (o quadro avança só nele)")
 Combat.apply_hit(game,foe,{"damage":1.0,"stagger":1.5},Vector3.RIGHT)
 check(effects("golpe_forte").size() == strong+1,"Golpe que atordoa forte mostra o estouro grande")
 foe.aggro = false
 strong = effects("golpe_forte").size()
 Combat.apply_hit(game,foe,{"damage":1.0,"sneak_mult":1.5},Vector3.RIGHT)
 check(effects("golpe_forte").size() == strong+1,"Ataque furtivo também mostra o estouro grande")
 foe.armored = true
 var sparks: int = effects("faisca").size()
 blood = effects("sangue").size()
 Combat.apply_hit(game,foe,{"damage":1.0},Vector3.RIGHT)
 check(effects("faisca").size() == sparks+1 and effects("sangue").size() == blood,"Blindado: faíscas em vez de sangue")
 Combat.apply_hit(game,foe,{"damage":1.0,"crush":1.5},Vector3.RIGHT)
 check(effects("sangue").size() == blood+1,"Arma que esmaga armadura tira sangue do blindado")
 foe.armored = bool(foe.stats.get("armored",false))
 # Bleeding drips while it lasts.
 var drops: int = effects("gota").size()
 foe.apply_bleed(3.0,4.0)
 foe.tick_bleed(0.3)
 foe.tick_bleed(0.3)
 check(effects("gota").size() >= drops+1,"Monstro sangrando pinga sangue")
 foe.bleed_time = 0
 foe.bleed_dps = 0
 # The adventurer: blood when hurt, sparks on the guard, dust on the dodge.
 ready_player(p)
 p.health = p.max_health
 p.stamina = p.max_stamina
 p.facing = Vector3.RIGHT
 p.aiming = true
 sparks = effects("faisca").size()
 p.receive_damage(10,Vector3.LEFT)
 check(effects("faisca").size() == sparks+1,"Golpe na guarda solta faíscas")
 # On screen (ignoring the push toward the camera) the sparks sit toward the attacker.
 var spark_node: Node3D = effects("faisca")[-1]
 var view: Vector3 = get_viewport().get_camera_3d().global_transform.basis.z
 var offset: Vector3 = spark_node.global_position - Vfx.body_point(p)
 offset -= view * offset.dot(view)
 check(offset.dot(Vector3.RIGHT) > 0.1,"Faíscas do lado de onde veio o golpe")
 p.aiming = false
 ready_player(p)
 blood = effects("sangue").size()
 p.receive_damage(10,Vector3.LEFT)
 check(effects("sangue").size() == blood+1,"Aventureiro ferido sangra")
 ready_player(p)
 p.stamina = p.max_stamina
 var dust: int = effects("poeira").size()
 p.test_direction = Vector2(1,0)
 p.dodge()
 p.test_direction = Vector2.ZERO
 check(effects("poeira").size() >= dust+2,"Esquiva levanta poeira")
 # Death: smoke (the belongings it drops are taken away again).
 var containers: int = game.containers.size()
 var kills: int = game.kills
 foe.health = 1.0
 foe.receive_damage(5.0,Vector3.RIGHT)
 check(not foe.alive and not effects("fumaca_morte").is_empty(),"Monstro morto solta fumaça")
 while game.containers.size() > containers:
  var extra: Dictionary = game.containers.pop_back()
  if is_instance_valid(extra.get("node")):
   extra["node"].queue_free()
 game.kills = kills
 # PSX filter leaves effect materials alone.
 if game.psx.enabled:
  check(game.psx.psx_material(Vfx.material("sangue")) == Vfx.material("sangue"),"Filtro PSX não troca o material dos efeitos")
 # One-shot effects free themselves.
 await get_tree().create_timer(1.3).timeout
 check(get_tree().get_nodes_in_group("efeitos").filter(func(n): return not n.is_queued_for_deletion()).is_empty(),"Efeitos somem sozinhos quando acabam")
 check(not get_tree().get_nodes_in_group("chamas").is_empty(),"Chamas das tochas continuam")
 fresh(foe,game.layout.to_world(Vector2i(28,7)))
 ready_player(p)
 p.health = p.max_health
 p.stamina = p.max_stamina
 p.set_physics_process(was_processing)

## 15/10/2026: fists are blunt, an objeto for every branch, a third of the
## recovery after a blow, and twice the bonus per level.
func test_balance() -> void:
 get_tree().paused = false
 var p = game.player
 var inv = game.inventory
 var sheet: CharacterSheet = game.sheet
 var saved_inventory: Dictionary = inv.snapshot()
 var was_processing: bool = p.is_physics_processing()
 p.set_physics_process(false)
 sheet.enabled = true
 sheet.reset()
 var room: Rect2i = game.layout.rooms[1]["rect"]
 p.position = game.layout.to_world(room.get_center())
 var foe = game.enemies[0]
 fresh(foe,p.position+Vector3(1.0,0,0))
 foe.visible = true
 # Fists are blunt.
 check(ProficiencyTree.DATA["desarmado"].get("parent","") == "contundentes" and CharacterSheet.path_of("") == ["contundentes","desarmado"] and ProficiencyTree.group_of("desarmado") == "combate","Soco é contundente: Desarmado fica dentro de Contundentes")
 sheet.award_path(CharacterSheet.path_of(""),100.0)
 check(float(sheet.xp.get("contundentes",0)) > 0 and float(sheet.xp.get("desarmado",0)) > 0,"Socar treina Contundentes e Desarmado")
 teach(sheet,"contundentes",5)
 check(float(sheet.weapon_stats("")["stagger"]) >= float(ProficiencyTree.section("punhos")["stagger"])+0.3,"Talento de Contundentes (Atordoar) vale no soco")
 check(Techniques.form_fits("golpe_esmagador","") and Techniques.form_unlocked(sheet,"golpe_esmagador") and Techniques.problem(sheet,game.techniques,"golpe_esmagador","") == "","Golpe esmagador serve com os punhos")
 # One objeto per branch.
 var with_object: Dictionary = {}
 for id in Techniques.OBJECTS:
  with_object[Techniques.object_branch(id)] = true
 check(ProficiencyTree.DATA.keys().all(func(b): return with_object.has(b)) and Techniques.OBJECTS.size() == ProficiencyTree.DATA.size(),"Todo ramo de proficiência dá um objeto (%d)" % Techniques.OBJECTS.size())
 var base: Dictionary = sheet.weapon_stats("sword")
 var s1: Dictionary = Techniques.stats(sheet,"corte",["ponto_vital","forca"],"sword")
 var s2: Dictionary = Techniques.stats(sheet,"corte",["forca","ponto_vital"],"sword")
 check(is_equal_approx(s1["damage"],(base["damage"]+4.0)*1.3) and s1["damage"] > s2["damage"],"Ponto vital antes da Força rende mais (soma antes de multiplicar)")
 var axe: Dictionary = Techniques.stats(sheet,"corte",["talho"],"machado")
 check(is_equal_approx(axe["bleed"]["dps"],float(sheet.weapon_stats("machado")["bleed"]["dps"])*1.6),"Talho fundo multiplica o sangramento do machado")
 var dry: Dictionary = Techniques.stats(sheet,"corte",["talho"],"sword")
 check(not dry.has("bleed"),"Talho fundo sem nada sangrando antes não faz nada")
 var hammer: Dictionary = Techniques.stats(sheet,"pancada",["tremor"],"martelo")
 check(is_equal_approx(hammer["area_radius"],float(sheet.weapon_stats("martelo")["area_radius"])+0.5) and not Techniques.object_fits("tremor","sword"),"Tremor aumenta o raio da pancada e só serve em pancadas")
 check(is_equal_approx(Techniques.stats(sheet,"corte",["fresta"],"sword")["crush"],1.4),"Fresta: a espada passa a valer ×1,4 em blindado")
 var volley: Dictionary = Techniques.stats(sheet,"disparo",["saraivada"],"arco")
 check(int(volley["hits"]) == 3 and is_equal_approx(volley["damage"],float(sheet.weapon_stats("arco")["damage"])*0.5) and not Techniques.object_fits("saraivada","sword"),"Saraivada: três projéteis com metade do dano, só em disparos")
 p.health = 50.0
 Combat.apply_hit(game,foe,Techniques.stats(sheet,"corte",["balsamo"],"sword"),Vector3.RIGHT)
 check(is_equal_approx(p.health,52.0),"Bálsamo: cada acerto recupera 2 de vida")
 p.health = p.max_health
 check(Techniques.summary(Techniques.stats(sheet,"corte",["balsamo"],"sword")).any(func(r): return str(r[1]).contains("cura 2")),"Prévia mostra a cura por acerto")
 # The habilidades window lists all objetos, the ones you have first, in a scroll.
 inv.restore({"stacks":{"sword":1},"equipped":"sword"})
 p.refresh_weapon()
 game.ui.toggle_techniques()
 var win = game.ui.tech_window
 win.select("corte")
 var order: Array = win.object_order("sword")
 check(order.size() == Techniques.OBJECTS.size() and Techniques.copies(sheet,order[0]) > 0 and Techniques.copies(sheet,order[-1]) == 0 and win.object_box.get_child_count() == order.size() and win.object_box.get_parent() is ScrollContainer,"Janela lista todos os objetos com rolagem, os que você tem primeiro")
 game.ui.toggle_techniques()
 # Delay after the blow by weight: heavy weapons keep a long one; the dodge comes back halfway.
 ready_player(p)
 p.stamina = p.max_stamina
 var w: Dictionary = sheet.weapon_stats("sword")
 var cycle: float = maxf(float(w["cooldown"]),float(w["windup"])+0.15)
 p.facing = Vector3.LEFT
 check(p.attack(),"Golpe para medir o delay")
 check(is_equal_approx(p.attack_wait,float(w["windup"])) and is_equal_approx(p.cooldown,cycle+float(w["weight"])*0.1) and is_equal_approx(p.attack_timer,cycle*0.9),"Golpe inteiro como nos dados, mais 0,1 s por kg antes do próximo golpe; a lentidão não conta o peso")
 check(is_equal_approx(p.dodge_lock,float(w["windup"])+(cycle-float(w["windup"]))*0.5),"Esquiva volta na metade do delay depois do golpe")
 check(not p.dodge(),"Sem esquiva antes da metade do delay")
 if p.animator and p.animator.is_playing() and p.animator.speed_scale > 0.0:
  var anim: Animation = p.animator.get_animation(p.animator.current_animation)
  check(is_equal_approx(p.animator.get_playing_speed()/p.animator.speed_scale,anim.length/(float(w["windup"])/float(w["impacto"]))),"Animação do golpe acerta no fim do preparo (dura preparo / impacto)")
 p.set_physics_process(true)
 await get_tree().create_timer(p.dodge_lock+0.03).timeout
 var still_slow: bool = p.attack_timer > 0.0
 check(still_slow and p.dodge() and p.attack_timer == 0.0,"Esquiva na metade do delay corta a lentidão do golpe")
 p.set_physics_process(false)
 var delays: Dictionary = {}
 for id in ["adaga","katana","sword","maca","montante","martelo","besta"]:
  var data: Dictionary = Items.info(id)
  delays[id] = float(data["cooldown"])-float(data["windup"])
 check(Items.info("martelo")["classe"] == "pesada" and Items.info("adaga")["classe"] == "leve" and delays["martelo"] > delays["sword"]*2.0 and delays["montante"] > delays["sword"]*1.8 and delays["adaga"] < delays["sword"] and float(Items.info("martelo")["cooldown"]) >= 1.25,"Armas pesadas têm muito dano e delay alto; leves, pouco dano e delay curto")
 # The weight delay: the hammer waits 0,65 s more for the next blow, moving and dodging freely.
 inv.restore({"stacks":{"martelo":1},"equipped":"martelo"})
 p.refresh_weapon()
 ready_player(p)
 p.stamina = p.max_stamina
 var hammer_stats: Dictionary = sheet.weapon_stats("martelo")
 check(p.attack(),"Golpe de martelo")
 game.resolve_player_attack()
 check(is_equal_approx(DungeonPlayer.weight_delay(hammer_stats),0.65) and is_equal_approx(p.cooldown,float(hammer_stats["cooldown"])+0.65),"Martelo (6,5 kg): 0,65 s a mais até o próximo golpe")
 # Right after the swing ends: free to move and dodge, not yet to strike.
 p.attack_wait = 0.0
 p.attack_timer = 0.0
 p.dodge_lock = 0.0
 p.cooldown = 0.5
 check(not p.attack() and p.dodge(),"Durante o delay do peso: sem golpe, mas a esquiva funciona")
 p.dodge_timer = 0.0
 inv.restore({"stacks":{"sword":1},"equipped":"sword"})
 p.refresh_weapon()
 # Stamina: costs halved, regeneration ×1,3.
 check(is_equal_approx(float(Items.info("sword")["cost"]),8.5) and is_equal_approx(float(Items.info("martelo")["cost"]),16.0) and is_equal_approx(float(ProficiencyTree.section("punhos")["cost"]),4.0),"Fôlego das armas pela metade (espada 8,5, martelo 16, soco 4)")
 check(is_equal_approx(sheet.dodge_cost(),12.5) and is_equal_approx(sheet.block_cost(20.0),10.0) and is_equal_approx(sheet.block_cost(1.0),2.0) and is_equal_approx(sheet.stamina_rule("corrida",0),8.0),"Esquiva 12,5, guarda metade do dano segurado (mínimo 2), corrida 8 por segundo")
 check(is_equal_approx(Techniques.OBJECTS["forca"]["efeitos"][2]["soma"],2.0) and is_equal_approx(float(ProficiencyTree.DATA["espada_reta"]["perks"][0]["mods"]["cost"]),-1.5),"Fôlego dos objetos e talentos pela metade")
 ready_player(p)
 p.stamina = 40.0
 p.food = 80.0
 inv.restore({"stacks":{"sword":1},"equipped":"sword"})
 p.set_physics_process(true)
 await get_tree().create_timer(0.5).timeout
 p.set_physics_process(false)
 var gained: float = p.stamina-40.0
 check(gained > 20.8*0.5*0.85 and gained < 20.8*0.5*1.15,"Fôlego volta 20,8 por segundo, 1,3× o de antes (%s em 0,5 s)" % UiStyle.fmt(gained))
 # Firmness: a stunned monster then holds its attack against blows for a while.
 fresh(foe,p.position+Vector3(1.0,0,0))
 foe.visible = true
 Combat.apply_hit(game,foe,{"damage":1.0},Vector3.RIGHT)
 check(foe.stagger > 0.0 and is_equal_approx(foe.firm,foe.stagger+float(EnemyTypes.info(foe.kind)["firmeza"])),"Primeiro golpe atordoa e deixa o monstro firme por um tempo")
 foe.stagger = 0.0
 foe.windup = 0.4
 Combat.apply_hit(game,foe,{"damage":1.0,"stagger":1.0},Vector3.RIGHT)
 check(foe.windup > 0.0 and foe.stagger == 0.0,"Monstro firme leva o dano mas não perde o ataque (sem atordoamento em cadeia)")
 foe.firm = 0.0
 Combat.apply_hit(game,foe,{"damage":1.0},Vector3.RIGHT)
 check(foe.windup == 0.0 and foe.stagger > 0.0,"Passada a firmeza, um golpe volta a interromper")
 # In play: hitting nonstop with the sword no longer keeps a monster from striking back.
 fresh(foe,p.position+Vector3(1.2,0,0))
 foe.visible = true
 foe.aggro = true
 foe.health = 100000.0
 ready_player(p)
 p.health = p.max_health
 p.stamina = p.max_stamina
 p.invulnerable = 0.0
 var swings: int = 0
 foe.set_physics_process(true)
 p.set_physics_process(true)
 for i in 180:
  await get_tree().physics_frame
  p.stamina = p.max_stamina
  if p.cooldown <= 0.0 and p.hurt_timer <= 0.0:
   p.facing = (foe.position-p.position).normalized()
   if p.attack():
    swings += 1
 foe.set_physics_process(false)
 p.set_physics_process(false)
 check(swings >= 3 and p.health < p.max_health,"Golpear sem parar não impede mais o monstro de revidar (%d golpes, vida %d)" % [swings,roundi(p.health)])
 p.health = p.max_health
 # Twice the bonus per level.
 sheet.reset()
 var path: Array = CharacterSheet.path_of("sword")
 sheet.award_path(path,ProficiencyTree.xp_for_level(6)+1.0)
 check(sheet.mastery(path) == 6 and is_equal_approx(sheet.damage_mult(path),1.2) and is_equal_approx(sheet.cost_mult(path),0.9),"Bônus por nível dobrado: domínio 6 dá +20% de dano e −10% de fôlego")
 teach(sheet,"acrobacia",6)
 check(is_equal_approx(sheet.dodge_cost(),8.5),"Acrobacia 6: esquiva 0,3 de fôlego mais barata por nível (12,5 − 1,5 − 2,5 do talento)")
 teach(sheet,"bloqueio",6)
 check(is_equal_approx(sheet.block_reduction("sword"),0.4+0.024*5),"Bloqueio 6: guarda segura 2,4% a mais por nível")
 # Back to the fixed numbers.
 fresh(foe,game.layout.to_world(Vector2i(28,7)))
 sheet.reset()
 sheet.enabled = false
 game.apply_attributes(true)
 inv.restore(saved_inventory)
 p.refresh_weapon()
 ready_player(p)
 p.set_physics_process(was_processing)
 game.ui.level_banner.queue.clear()

func press_key(code: int) -> void:
 var key := InputEventKey.new()
 key.physical_keycode = code
 key.pressed = true
 game.ui._input(key)

## Quick bar on 1 to 9 with any item; habilidade keys chosen by the player.
func test_quick_bar() -> void:
 get_tree().paused = false
 var p = game.player
 var inv = game.inventory
 var bar: QuickBar = game.quick_bar
 var hud: UiHotbar = game.ui.hotbar
 var saved_inventory: Dictionary = inv.snapshot()
 var was_processing: bool = p.is_physics_processing()
 p.set_physics_process(false)
 game.ui.close_all()
 bar.defaults("sword")
 inv.restore({"stacks":{"sword":1,"ration":3,"bandage":3,"katana":1,"couro":1,"flecha":6},"equipped":"sword"})
 p.refresh_weapon()
 game.ui.update_hud()
 check(QuickBar.SIZE == 9 and hud.slots.size() == 9 and bar.snapshot() == ["sword","ration","bandage","","","","","",""],"Barra rápida com 9 espaços; começa com arma, rações e bandagens")
 var right_edge: float = hud.position.x+hud.bar_width()
 check(hud.position.x >= game.ui.hands.position.x+game.ui.hands.custom_minimum_size.x and right_edge <= 1440.0,"Barra cabe na tela sem cobrir o cartão da arma")
 # Keys 1-9 use the slot.
 p.food = 50.0
 press_key(KEY_2)
 check(inv.count("ration") == 2 and p.food > 50.0,"Tecla 2: come a ração do espaço 2")
 bar.assign(3,"katana")
 bar.assign(4,"couro")
 press_key(KEY_4)
 check(inv.equipped == "katana","Arma em qualquer espaço: tecla 4 equipa a katana")
 game.ui.update_hud()
 check(hud.slots[3]["active"].visible and not hud.slots[0]["active"].visible,"Espaço da arma em mãos fica marcado")
 press_key(KEY_4)
 check(inv.equipped == "","Apertar de novo guarda a arma (punhos)")
 press_key(KEY_1)
 check(inv.equipped == "sword","Tecla 1 volta para a espada")
 press_key(KEY_5)
 check(inv.armor == "couro","Armadura na barra: tecla 5 veste")
 press_key(KEY_5)
 check(inv.armor == "","Apertar de novo tira a armadura")
 bar.assign(5,"flecha")
 game.ui.update_hud()
 check(hud.slots[5]["count"].text == "6" and not bar.use(game,5),"Munição na barra mostra quantas restam e não se usa")
 game.message_text = ""
 press_key(KEY_9)
 check(game.message_text.contains("vazio"),"Espaço vazio explica como pôr um item")
 inv.remove("ration",inv.count("ration"))
 game.ui.update_hud()
 check(bar.at(1) == "ration" and hud.slots[1]["count"].text == "0","Pilha acabou: o espaço fica, mostrando 0")
 # Putting items in: drag, menu, number with the backpack open; right click empties.
 var drop_ok: bool = hud.slots[6]["button"]._can_drop_data(Vector2.ZERO,{"type":"item","source":"bag","id":"bandage","count":3})
 hud.slots[6]["button"]._drop_data(Vector2.ZERO,{"type":"item","source":"bag","id":"bandage","count":3})
 check(drop_ok and bar.at(6) == "bandage" and bar.at(2) == "","Arrastar da mochila põe o item no espaço (e tira do espaço antigo)")
 game.ui.toggle_inventory()
 game.ui.select_item("katana")
 press_key(KEY_8)
 check(bar.at(7) == "katana" and bar.at(3) == "" and inv.equipped == "sword","Mochila aberta: item selecionado e tecla 8 põe na barra sem usar")
 game.ui.inventory._open_menu("bag","couro",Vector2(200,200))
 var menu_texts: Array = []
 for i in game.ui.inventory.menu.item_count:
  menu_texts.append(game.ui.inventory.menu.get_item_text(i))
 game.ui.inventory.menu.hide()
 check(menu_texts.any(func(t): return t.contains("Tirar da barra rápida (5)")),"Menu do item mostra a posição dele na barra")
 game.ui.inventory.quick_add("unguento")
 check(bar.slot_of("unguento") == 2,"Menu põe o item no primeiro espaço livre (3)")
 game.ui.toggle_inventory()
 var right := InputEventMouseButton.new()
 right.button_index = MOUSE_BUTTON_RIGHT
 right.pressed = true
 hud.slots[7]["button"]._gui_input(right)
 check(bar.at(7) == "","Botão direito tira o item da barra")
 # Save and odd data.
 var snap: Array = bar.snapshot()
 check(game.save_game(false),"Save com a barra rápida é gravado")
 bar.clear()
 check(game.load_game() and bar.snapshot() == snap,"Barra rápida volta do save")
 bar.restore(["sword",3,"nada","sword",null])
 check(bar.snapshot() == ["sword","","","","","","","",""],"Barra estranha no save é limpa")
 # Habilidade keys: Q R F G by default, any free key, never the number row.
 check(InputSetup.TECHNIQUE_KEYS == [KEY_Q,KEY_R,KEY_F,KEY_G] and game.technique_keys == InputSetup.TECHNIQUE_KEYS,"Teclas das habilidades começam em Q, R, F e G")
 check(game.set_technique_key(0,KEY_3).contains("barra rápida") and game.set_technique_key(0,KEY_E).contains("interagir") and game.set_technique_key(0,KEY_T).contains("habilidades"),"Números de cima e teclas do jogo são recusados, com o motivo")
 check(game.set_technique_key(0,KEY_KP_1) == "" and game.technique_key_name(0) == "Num 1","Teclado numérico pode (Num 1)")
 check(game.set_technique_key(1,KEY_KP_1) == "" and game.technique_keys[1] == KEY_KP_1 and game.technique_keys[0] == KEY_R,"Tecla já usada em outro espaço troca de lugar com ele")
 var saved_keys = game.load_setting("teclas","habilidades",[])
 check(saved_keys is Array and int(saved_keys[1]) == KEY_KP_1,"Teclas ficam salvas nas configurações")
 game.ui.update_hud()
 check(hud.tech_slots[1]["key"].text == "Num 1","Barra mostra a tecla escolhida")
 # Using a habilidade by its new key.
 var book: TechniqueBook = game.techniques
 book.clear()
 book.assign(1,"corte")
 ready_player(p)
 p.stamina = p.max_stamina
 press_key(KEY_KP_1)
 check(book.remaining("corte") > 0.0,"Num 1 usa a habilidade do espaço escolhido")
 game.resolve_player_attack()
 ready_player(p)
 book.recharge.clear()
 press_key(KEY_4)
 check(book.remaining("corte") == 0.0,"Tecla 4 não usa mais habilidade (é da barra rápida)")
 # Choosing in the T window.
 game.ui.toggle_techniques()
 var win: UiTechniqueWindow = game.ui.tech_window
 win.start_capture(2)
 check(win.key_buttons[2].text == "aperte…","Clicar na tecla espera a nova")
 press_key(KEY_V)
 check(game.technique_keys[2] == KEY_V and win.capturing == -1 and win.key_buttons[2].text.contains("V"),"A tecla apertada vira a do espaço")
 win.start_capture(3)
 press_key(KEY_ESCAPE)
 check(game.technique_keys[3] == KEY_G and win.capturing == -1,"Esc cancela a troca")
 win.start_capture(3)
 press_key(KEY_7)
 check(game.technique_keys[3] == KEY_G and win.key_hint.text.contains("barra rápida"),"Número de cima na janela é recusado com o motivo")
 check(win.assign_box.get_child(2).text == "V","Botões de pôr na barra mostram as teclas")
 game.ui.toggle_techniques()
 game.ui.toggle_pause()
 var help: Array = []
 for cap in game.ui.technique_help_keys.get_children():
  help.append(label_text(cap) if cap is Control else "")
 game.ui.toggle_pause()
 check(" ".join(help).contains("Num 1") and " ".join(help).contains("V"),"Lista de controles mostra as teclas atuais das habilidades")
 # Back to defaults.
 for i in 4:
  game.technique_keys[i] = InputSetup.TECHNIQUE_KEYS[i]
 DirAccess.remove_absolute(game.settings_path)
 game.ui.refresh_technique_keys()
 book.clear()
 bar.defaults("sword")
 inv.restore(saved_inventory)
 p.refresh_weapon()
 ready_player(p)
 p.set_physics_process(was_processing)
 game.ui.close_all()

## Third-person camera option: camera behind the character, mouse look, walls whole.
func test_third_person() -> void:
 get_tree().paused = false
 var p = game.player
 var rig: GameCamera = game.camera_rig
 var was_processing: bool = p.is_physics_processing()
 p.set_physics_process(false)
 game.ui.close_all()
 check(rig.mode == GameCamera.ISO and game.camera.projection == Camera3D.PROJECTION_ORTHOGONAL and not game.third_person(),"Câmera começa isométrica")
 var low = game.world_root.get_node_or_null("Lote_parede_frente_baixa")
 var tall = game.world_root.get_node_or_null("Lote_parede_frente_alta")
 check(low != null and tall != null and low.visible and not tall.visible,"Isométrica: paredes da frente cortadas baixas")
 # Pause button switches to third person and remembers.
 game.ui.toggle_pause()
 game.ui.camera_button.pressed.emit()
 game.ui.toggle_pause()
 await wait_frames(2)
 check(game.third_person() and game.camera == rig.third_camera and game.camera.current and game.camera.projection == Camera3D.PROJECTION_PERSPECTIVE,"Botão da pausa liga a terceira pessoa (câmera em perspectiva)")
 check(not low.visible and tall.visible and game.get_node("Ambiente").environment.fog_enabled,"Terceira pessoa: paredes inteiras e névoa escura")
 check(game.load_setting("video","camera","") == GameCamera.THIRD and game.ui.camera_button.text == "Câmera: terceira pessoa","Escolha da câmera fica salva")
 check(game.ui.crosshair.visible and not game.ui.cursor_needed(),"Mira no meio da tela e cursor preso ao mouse")
 game.ui.toggle_inventory()
 check(game.ui.cursor_needed() and not game.ui.crosshair.visible,"Mochila aberta solta o cursor")
 # Inventory, map and pause pause the game; the cursor must still come back.
 await wait_process(2)
 check(get_tree().paused and not game.cursor_captured,"Mochila aberta (jogo pausado): o cursor solta de verdade")
 game.ui.toggle_inventory()
 await wait_process(2)
 check(not get_tree().paused and game.cursor_captured,"Fechando a mochila, o cursor volta a ficar preso")
 for menu in [["Mapa aberto", game.ui.toggle_map], ["Menu de pausa aberto", game.ui.toggle_pause]]:
  menu[1].call()
  await wait_process(2)
  var freed: bool = get_tree().paused and not game.cursor_captured
  menu[1].call()
  await wait_process(2)
  check(freed and not get_tree().paused and game.cursor_captured,"%s solta o cursor; fechando, ele volta a ficar preso" % menu[0])
 game.ui.toggle_techniques()
 game.ui.update_hud()
 check(game.ui.cursor_needed(),"Janela de habilidades também solta o cursor")
 game.ui.toggle_techniques()
 # Camera relative movement, aim and blows.
 rig.look_along(Vector3.RIGHT)
 check(rig.forward().distance_to(Vector3.RIGHT) < 0.01 and rig.move_direction(Vector2(0,-1)).distance_to(Vector3.RIGHT) < 0.01 and rig.move_direction(Vector2(1,0)).distance_to(Vector3(0,0,1)) < 0.01,"W anda para onde a câmera olha; D para a direita dela")
 p.facing = Vector3.LEFT
 p.aim_mouse()
 check(p.facing.distance_to(Vector3.RIGHT) < 0.01,"Mirar e golpear vão para onde a câmera olha")
 ready_player(p)
 p.stamina = p.max_stamina
 p.test_direction = Vector2(1,0)
 p.dodge()
 p.test_direction = Vector2.ZERO
 check(p.dodge_direction.distance_to(Vector3(0,0,1)) < 0.01,"Esquiva também segue a câmera")
 p.dodge_timer = 0.0
 var yaw0: float = rig.yaw
 rig.look(Vector2(100,0))
 check(rig.yaw < yaw0,"Mouse para a direita gira a câmera")
 rig.look(Vector2(0,-100000))
 var top: float = rig.pitch
 rig.look(Vector2(0,100000))
 check(is_equal_approx(top,GameCamera.MAX_PITCH) and is_equal_approx(rig.pitch,GameCamera.MIN_PITCH),"Olhar para cima e para baixo tem limite")
 rig.pitch = -0.26
 rig.zoom_by(100.0)
 var far: float = rig.arm_length
 rig.zoom_by(-100.0)
 check(is_equal_approx(far,GameCamera.MAX_ARM) and is_equal_approx(rig.arm_length,GameCamera.MIN_ARM),"Roda do mouse aproxima e afasta, com limite")
 rig.arm_length = 3.3
 rig.look(Vector2.ZERO)
 # The arm stops at walls: put a wall right behind the character.
 var spot: Vector2i = Vector2i(-1,-1)
 for cell in game.layout.floors:
  if not game.layout.is_floor(cell+Vector2i.RIGHT) and game.layout.is_floor(cell+Vector2i.LEFT) and game.layout.is_floor(cell+Vector2i.LEFT*2):
   spot = cell
   break
 check(spot != Vector2i(-1,-1),"Achou um canto com parede para testar a câmera")
 p.position = game.layout.to_world(spot)+Vector3(0.3,0,0)
 rig.snap()
 rig.look_along(Vector3.LEFT)
 rig.pitch = 0.0
 rig.look(Vector2.ZERO)
 await wait_frames(6)
 var pulled: float = rig.arm.get_hit_length()
 check(pulled < rig.arm_length-0.4,"Câmera não atravessa a parede atrás do personagem (braço encolhe para %s m)" % UiStyle.fmt(pulled))
 rig.pitch = -0.26
 rig.look(Vector2.ZERO)
 # Back to isometric.
 game.set_camera_mode(GameCamera.ISO)
 await wait_frames(2)
 check(not game.third_person() and game.camera == rig.iso_camera and game.camera.current and low.visible and not tall.visible and not game.get_node("Ambiente").environment.fog_enabled and not game.ui.crosshair.visible,"Volta para a isométrica: câmera, paredes, névoa e mira como antes")
 check(rig.move_direction(Vector2(1,0)).distance_to(Vector3(1,0,-1).normalized()) < 0.01,"Isométrica: teclas como antes")
 DirAccess.remove_absolute(game.settings_path)
 p.position = game.layout.to_world(Vector2i(5,12))
 rig.snap()
 ready_player(p)
 p.set_physics_process(was_processing)
 game.ui.close_all()
