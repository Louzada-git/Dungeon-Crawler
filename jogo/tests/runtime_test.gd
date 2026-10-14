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
 game.player.position = game.layout.to_world(DungeonLayout.SPAWN)
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
 p.position = game.layout.to_world(DungeonLayout.SPAWN)
 game.discover()
 check(game.discovered.size() > 10 and not game.discovered.has(DungeonLayout.RELIC),"Mapa revela só a região explorada")
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
 for cell in game.layout.pathfinder.get_id_path(DungeonLayout.SPAWN,Vector2i(18,10)):
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
