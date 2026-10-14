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
 check(skeleton != null and skeleton.find_bone("hand-right") >= 0,"Rig original tem mão para equipar armas")
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
 check(enemy.health==36 and second.health==65,"Lança acerta o primeiro alvo, sem atravessá-lo")
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
  var expected: float = 36 if sample == Vector3(3.05,0,0) else 65
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
 inv.add("seal")
 p.position = game.camp_position
 game.interact()
 check(game.won and game.ended and game.ui.ending_panel.visible,"Retornar ao abrigo com o selo conclui a incursão")
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
 p.stamina = 20
 var list: Array = game.ui.moodles.compute()
 var by_id: Dictionary = {}
 for m in list:
  by_id[m["id"]] = m
 check(by_id.has("bleeding") and list[0]["id"] == "bleeding","Sangramento aparece primeiro entre os indicadores")
 check(by_id.has("hurt") and by_id["hurt"]["level"] == 2,"Vida 40 mostra nível 2 de ferimento")
 check(by_id.has("food") and by_id["food"]["level"] == 2,"Saciedade 9 mostra fome com efeito no fôlego")
 check(by_id.has("stamina") and by_id["stamina"]["title"] == "Ofegante","Fôlego 20 bloqueia esquiva e mostra Ofegante")
 p.stamina = 10
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
 check(ProficiencyTree.path_text(Items.info("katana")["proficiencias"]) == "Espadas › Katana","Arma indica o ramo de proficiência que treina")
 var at: Vector3 = game.layout.to_world(Vector2i(5,12))
 p.position = at
 var e0 = game.enemies[0]
 var e1 = game.enemies[1]
 var e2 = game.enemies[2]
 var guard = game.enemies[6]
 # Dagger: sneak attack on an unaware monster.
 fresh(e0,at+Vector3(1.1,0,0))
 swing("adaga",Vector3.RIGHT)
 check(is_equal_approx(e0.health,65.0-15.0*2.5),"Adaga: dano ×2,5 em monstro desprevenido")
 swing("adaga",Vector3.RIGHT)
 check(is_equal_approx(e0.health,65.0-15.0*2.5-15.0),"Adaga: dano normal quando o monstro já está alerta")
 inv.remove("adaga")
 # Katana: up to two targets in a narrow arc.
 fresh(e0,at+Vector3(1.2,0,0.2))
 fresh(e1,at+Vector3(1.5,0,-0.3))
 fresh(e2,at+Vector3(1.8,0,0.1))
 swing("katana",Vector3.RIGHT)
 var hit_count: int = [e0,e1,e2].filter(func(e): return e.health < 65.0).size()
 check(hit_count == 2,"Katana acerta até dois alvos")
 inv.remove("katana")
 # Axe: bleeding keeps hurting after the hit.
 fresh(e0,at+Vector3(1.2,0,0))
 fresh(e1,at+Vector3(-3,0,0))
 fresh(e2,at+Vector3(-3,0,2))
 swing("machado",Vector3.RIGHT)
 check(is_equal_approx(e0.health,39.0) and e0.bleed_time > 4.9,"Machado: golpe abre sangramento")
 e0.tick_bleed(1.0)
 check(is_equal_approx(e0.health,34.0),"Sangramento tira 5 de vida por segundo")
 e0.tick_bleed(5.0)
 check(e0.bleed_time == 0 and e0.health >= 13.9 and e0.alive,"Sangramento acaba depois do tempo")
 e0.health = 3
 e0.apply_bleed(5,5)
 var kills_before: int = game.kills
 e0.tick_bleed(1.0)
 check(not e0.alive and game.kills == kills_before+1,"Monstro pode morrer de sangramento")
 inv.remove("machado")
 # Mace: crushes armor and stuns longer.
 fresh(guard,at+Vector3(1.2,0,0))
 swing("maca",Vector3.RIGHT)
 check(is_equal_approx(guard.health,95.0-28.0*1.5) and guard.armored,"Maça: dano ×1,5 em monstro blindado")
 check(guard.stagger >= 0.89,"Maça atordoa por mais tempo")
 fresh(e0,at+Vector3(1.2,0,0))
 fresh(guard,game.layout.to_world(Vector2i(28,7)))
 swing("maca",Vector3.RIGHT)
 check(is_equal_approx(e0.health,65.0-28.0),"Maça: dano normal em monstro sem armadura")
 inv.remove("maca")
 # War hammer: area in front, nothing behind.
 fresh(e0,at+Vector3(1.3,0,1.0))
 fresh(e1,at+Vector3(2.2,0,-0.6))
 fresh(e2,at+Vector3(-1.5,0,0))
 swing("martelo",Vector3.RIGHT)
 check(is_equal_approx(e0.health,65.0-44.0) and is_equal_approx(e1.health,65.0-44.0),"Martelo acerta todos na área à frente")
 check(is_equal_approx(e2.health,65.0),"Martelo não acerta quem está atrás")
 inv.remove("martelo")
 # Halberd: pierces two in a line.
 fresh(e0,at+Vector3(1.3,0,0))
 fresh(e1,at+Vector3(2.4,0,0))
 fresh(e2,at+Vector3(3.3,0,0))
 swing("alabarda",Vector3.RIGHT)
 check(is_equal_approx(e0.health,32.0) and is_equal_approx(e1.health,32.0) and is_equal_approx(e2.health,65.0),"Alabarda atravessa o primeiro e acerta o segundo")
 inv.remove("alabarda")
 # Montante: wide arc, four targets.
 fresh(e0,at+Vector3(1.2,0,1.2))
 fresh(e1,at+Vector3(1.6,0,0))
 fresh(e2,at+Vector3(1.2,0,-1.2))
 swing("montante",Vector3.RIGHT)
 check([e0,e1,e2].all(func(e): return is_equal_approx(e.health,25.0)),"Montante acerta em arco largo")
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
 check(game.ui.hotbar.slots[0]["count"].text == "5","Barra rápida mostra as flechas do arco")
 check(swing("arco",Vector3.RIGHT) and inv.count("flecha") == 4,"Disparo gasta uma flecha")
 check(get_tree().get_nodes_in_group("projeteis").size() == 1,"Flecha voa como projétil")
 await wait_frames(30)
 check(is_equal_approx(e0.health,43.0) and int(e0.stuck.get("flecha",0)) == 1,"Flecha acerta à distância e fica presa no monstro")
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
 check(is_equal_approx(e0.health,20.0) and is_equal_approx(e1.health,20.0) and is_equal_approx(e2.health,65.0),"Besta atravessa dois inimigos")
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
 check(joined.contains("Contundentes › Martelo") and joined.contains("Pancada") and joined.contains("Duas mãos"),"Dica do martelo mostra família, golpe e empunhadura")
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
 var expected: float = 30.0*24.0/65.0
 check(is_equal_approx(e0.health,41.0) and is_equal_approx(float(sheet.xp.get("espadas",0)),expected*0.5) and is_equal_approx(float(sheet.xp.get("espada_reta",0)),expected*0.5),"Golpe ensina Espadas e Espada reta pelo dano causado")
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
 p.hurt_timer = 0
 p.health = p.max_health
 check(p.dodge(),"Esquiva funciona com o custo do personagem")
 p.receive_damage(17,Vector3.RIGHT)
 check(p.health == p.max_health and float(sheet.xp.get("esquiva",0)) > 0,"Escapar de um golpe esquivando ensina Esquiva")
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
 check(is_equal_approx(p.max_health,94.0) and is_equal_approx(p.max_stamina,95.0) and is_equal_approx(p.dodge_cost(),26.0),"Vigor e Agilidade 4: vida 94, fôlego 95, esquiva custa 26")
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
 panel._change("forca",1)
 check(panel.start_button.disabled == false and panel.values["forca"] == 5,"Criação não passa do total de pontos")
 panel._change("vigor",-1)
 panel._change("forca",1)
 panel._change("forca",1)
 check(panel.values["forca"] == 6 and panel.values["vigor"] == 4 and not panel.start_button.disabled,"Criação move pontos entre atributos")
 panel._change("agilidade",-1)
 check(panel.start_button.disabled,"Criação exige gastar todos os pontos")
 panel.reset()
 game.choosing_character = true
 game.ui.show_creation()
 check(get_tree().paused and panel.visible,"Criação de personagem pausa e aparece")
 panel.confirmed.emit({"forca":6,"vigor":4,"agilidade":5,"destreza":5})
 check(not get_tree().paused and not game.choosing_character and sheet.attr("forca") == 6 and sheet.xp.is_empty(),"Começar expedição aplica os atributos e zera a experiência")
 # Back to the fixed numbers for the rest of the suite.
 sheet.reset()
 sheet.enabled = false
 game.apply_attributes(true)
 inv.restore(saved_inventory)
 p.refresh_weapon()
 game.ui.close_all()
