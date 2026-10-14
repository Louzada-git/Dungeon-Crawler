extends Node3D

var sound
var aim_marker: MeshInstance3D
var camera_shake: float = 0.0
var camera_strength: float = 0.0
var save_path: String = "user://expedicao_v1.json"
var inventory = InventoryData.new()
var layout = DungeonLayout.new()
var player: DungeonPlayer
var camera: Camera3D
var camera_rig: Node3D
var ui
var enemies: Array[DungeonEnemy] = []
var containers: Array[Dictionary] = []
var discovered: Dictionary = {}
var camp_position: Vector3
var kills: int = 0
var hits_received: int = 0
var won: bool = false
var ended: bool = false
var last_discover: Vector2i = Vector2i(-99,-99)
var message_text: String = "Prepare sua mochila. Explore e recupere o selo das cisternas."
var message_time: float = 8.0
var zoom: float = 16.0
var test_mode: bool = false

func _ready() -> void:
 test_mode = "--test" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_user_args()
 if test_mode:
  save_path = "user://teste_base_v1.json"
 get_tree().auto_accept_quit = false
 configure_inputs()
 camp_position = layout.to_world(Vector2i(4,20))
 sound = preload("res://scripts/game_audio.gd").new()
 add_child(sound)
 setup_environment()
 WorldBuilder.build(self)
 inventory.add("sword")
 inventory.add("ration",3)
 inventory.add("bandage",3)
 inventory.equip("sword")
 player = DungeonPlayer.new()
 player.game = self
 add_child(player)
 player.position = layout.to_world(DungeonLayout.SPAWN)
 camera_rig = Node3D.new()
 add_child(camera_rig)
 camera = Camera3D.new()
 camera_rig.add_child(camera)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = zoom
 camera.position = Vector3(12,9.798,12)
 camera.look_at_from_position(camera.position,Vector3.ZERO)
 camera.far = 100
 camera.current = true
 camera_rig.position = player.position
 var light = OmniLight3D.new()
 player.add_child(light)
 light.position = Vector3(0,2,0)
 light.light_color = Color("d8e2de")
 light.light_energy = 0.25
 light.omni_range = 7
 aim_marker = Visuals.ring(0.20,Color("c7c5ac"),0.025)
 aim_marker.visible = false
 add_child(aim_marker)
 setup_content()
 ui = preload("res://scripts/ui.gd").new()
 ui.game = self
 add_child(ui)
 inventory.changed.connect(on_inventory_changed)
 if not test_mode and FileAccess.file_exists(save_path):
  load_game()
 discover()
 if test_mode:
  call_deferred("run_test_mode")

func configure_inputs() -> void:
 var keys = {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"sprint":[KEY_SHIFT],"dodge":[KEY_SPACE],"interact":[KEY_E],"inventory":[KEY_I,KEY_TAB],"map":[KEY_M],"escape":[KEY_ESCAPE],"save":[KEY_F5]}
 for action in keys:
  if not InputMap.has_action(action):
   InputMap.add_action(action)
  for key in keys[action]:
   var event = InputEventKey.new()
   event.physical_keycode = key
   InputMap.action_add_event(action,event)

 if not InputMap.has_action("aim"):
  InputMap.add_action("aim")
 var aim_event = InputEventMouseButton.new()
 aim_event.button_index = MOUSE_BUTTON_RIGHT
 InputMap.action_add_event("aim",aim_event)

func setup_environment() -> void:
 var node = WorldEnvironment.new()
 var env = Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("161915")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("b8b6a5")
 env.ambient_light_energy = 0.55
 env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
 node.environment = env
 add_child(node)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-58,-35,0)
 sun.light_color = Color("ded3b8")
 sun.light_energy = 0.70
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 70
 add_child(sun)

func setup_content() -> void:
 add_loot("Reserva da entrada",Vector2i(6,22),{"ration":2,"bandage":2})
 add_loot("Baú da guarda",Vector2i(9,12),{"spear":1,"bandage":2,"coin":12})
 add_loot("Depósito de ferro",Vector2i(22,22),{"ore":8,"ration":2,"coin":8})
 add_loot("Mantimentos esquecidos",Vector2i(17,6),{"ration":2,"bandage":3})
 add_loot("Relicário das cisternas",DungeonLayout.RELIC,{"seal":1,"coin":20})
 var points = [Vector2i(6,12),Vector2i(9,10),Vector2i(19,21),Vector2i(21,18),Vector2i(18,10),Vector2i(22,7),Vector2i(28,7)]
 for index in points.size():
  var enemy = DungeonEnemy.new()
  enemy.game = self
  enemy.enemy_id = index
  enemy.heavy = index == points.size()-1
  enemy.position = layout.to_world(points[index])
  add_child(enemy)
  enemies.append(enemy)

func add_loot(title: String, cell: Vector2i, items: Dictionary, chest: bool = true) -> Dictionary:
 var pos = layout.to_world(cell)
 var data: Dictionary = {"name":title,"pos":[pos.x,pos.z],"items":items.duplicate(true),"chest":chest}
 containers.append(data)
 WorldBuilder.add_container(self,data)
 return data

func _process(delta: float) -> void:
 if player == null or ui == null:
  return
 camera_rig.position = camera_rig.position.lerp(player.position,1.0-exp(-delta*9))
 camera.size = lerpf(camera.size,zoom,1.0-exp(-delta*10))
 camera_shake = maxf(0,camera_shake-delta)
 var strength = camera_strength*camera_shake/0.16
 camera.h_offset = sin(camera_shake*180)*strength
 camera.v_offset = cos(camera_shake*155)*strength*0.6
 message_time = maxf(0,message_time-delta)
 discover()
 for loot in containers:
  loot["ring"].visible = not loot["items"].is_empty()
 update_aim_marker()
 ui.update_hud()

func update_aim_marker() -> void:
 aim_marker.visible = player.aiming and not ui.any_panel() and not ended
 if not aim_marker.visible:
  return
 var mouse = get_viewport().get_mouse_position()
 var point = Plane(Vector3.UP,0.65).intersects_ray(camera.project_ray_origin(mouse),camera.project_ray_normal(mouse))
 if point == null:
  aim_marker.hide()
  return
 var pos: Vector3 = point
 pos.y = 0.06
 if not layout.is_floor(layout.to_cell(pos)):
  aim_marker.hide()
  return
 aim_marker.position = pos
 aim_marker.scale = Vector3.ONE
 var color = Color("a6a799")
 for enemy in enemies:
  if enemy.alive and enemy.position.distance_to(pos)<0.9 and clear_line(player.position,enemy.position):
   aim_marker.position = enemy.position+Vector3.UP*0.06
   aim_marker.scale = Vector3.ONE*2.5
   color = Color("d9bd81") if player.position.distance_to(enemy.position)<=Items.info(inventory.equipped).get("range",1.5) else Color("8d7a65")
   break
 aim_marker.material_override.albedo_color = color

func _unhandled_input(event: InputEvent) -> void:
 if ui == null or ended:
  return
 if event.is_action_pressed("inventory"):
  ui.toggle_inventory()
 elif event.is_action_pressed("map"):
  ui.toggle_map()
 elif event.is_action_pressed("escape"):
  ui.toggle_pause()
 elif event.is_action_pressed("save"):
  save_game()
 elif event.is_action_pressed("interact"):
  interact()
 elif event.is_action_pressed("dodge"):
  player.dodge()
 elif event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_LEFT:
   player.request_attack()
  elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
   zoom = maxf(13,zoom-1.5)
  elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   zoom = minf(27,zoom+1.5)

func discover() -> void:
 var cell = layout.to_cell(player.position)
 if cell == last_discover:
  return
 last_discover = cell
 for x in range(cell.x-5,cell.x+6):
  for y in range(cell.y-5,cell.y+6):
   var p = Vector2i(x,y)
   if layout.is_floor(p) and p.distance_to(cell) <= 5.5 and clear_line(player.position,layout.to_world(p)):
    discovered[p] = true

func clear_line(a: Vector3, b: Vector3) -> bool:
 if a.distance_squared_to(b) < 0.001:
  return true
 var query = PhysicsRayQueryParameters3D.create(a+Vector3(0,0.8,0),b+Vector3(0,0.8,0),1)
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func is_safe() -> bool:
 return layout.rooms[0]["rect"].has_point(layout.to_cell(player.position))

func nearest_loot() -> Dictionary:
 var nearest: Dictionary = {}
 var best: float = 2.4
 for loot in containers:
  if loot["items"].is_empty():
   continue
  var p = Vector3(loot["pos"][0],0,loot["pos"][1])
  var d: float = p.distance_to(player.position)
  if d < best and clear_line(player.position,p):
   nearest = loot
   best = d
 return nearest

func interaction_text() -> String:
 if player.position.distance_to(camp_position) < 1.6:
  return "E   RETORNAR COM O SELO" if inventory.count("seal") > 0 else "E   DESCANSAR E SALVAR NO ABRIGO"
 var loot = nearest_loot()
 if not loot.is_empty():
  return "E   VASCULHAR  ·  " + loot["name"]
 return ""

func interact() -> void:
 if player.position.distance_to(camp_position) < 1.6:
  if inventory.count("seal") > 0:
   won = true
   save_game(false)
   end_run(true)
  else:
   player.stamina = 100
   save_game(false)
   message("Expedição salva. Alimente-se e trate ferimentos antes de sair.")
  return
 var loot = nearest_loot()
 if not loot.is_empty():
  sound.play_at("loot",player.global_position,0.6)
  ui.open_inventory(loot)
  var anim = Visuals.animation(loot["node"])
  Visuals.play(anim,"open",false)

func camera_impact(strength: float) -> void:
 camera_shake = 0.16
 camera_strength = strength

func resolve_player_attack() -> void:
 # Each committed swing resolves once, even if another callback arrives.
 if player.resolved_serial == player.attack_serial or player.health <= 0:
  return
 player.resolved_serial = player.attack_serial
 var weapon = player.attack_weapon
 var reach: float = weapon.get("range",1.5)
 var damage: float = weapon.get("damage",9.0)
 var half_angle: float = deg_to_rad(weapon.get("angle",55.0))
 var arc = Visuals.attack_arc(reach,Color(0.9,0.80,0.61,0.30),half_angle,0.06)
 add_child(arc)
 arc.position = player.position+Vector3(0,0.12,0)
 arc.rotation.y = atan2(player.attack_facing.x,player.attack_facing.z)
 get_tree().create_timer(0.12).timeout.connect(arc.queue_free)
 if weapon.get("style","") == "slash":
  var trail = Visuals.attack_arc(minf(reach,1.65),Color(0.74,0.77,0.74,0.67),half_angle,0.19)
  add_child(trail)
  trail.position = player.position+Vector3(0,0.85,0)
  trail.rotation.y = arc.rotation.y
  get_tree().create_timer(0.15).timeout.connect(trail.queue_free)
 var candidates: Array[DungeonEnemy] = []
 for enemy in enemies:
  if not enemy.alive:
   continue
  var offset: Vector3 = enemy.position-player.position
  offset.y = 0
  var within_shape: bool = player.attack_facing.dot(offset.normalized()) >= cos(half_angle)
  if weapon.get("style", "") == "thrust":
   var forward: float = offset.dot(player.attack_facing)
   var sideways: float = (offset-player.attack_facing*forward).length()
   within_shape = forward > 0 and sideways <= float(weapon.get("width",0.34))
  if offset.length() <= reach and within_shape and clear_line(player.position,enemy.position):
   candidates.append(enemy)
 candidates.sort_custom(func(a,b): return a.position.distance_squared_to(player.position)<b.position.distance_squared_to(player.position))
 var limit: int = mini(candidates.size(),int(weapon.get("targets",1)))
 for i in limit:
  var enemy = candidates[i]
  enemy.receive_damage(damage,player.attack_facing)
 if limit > 0:
  sound.play_at("hit",candidates[0].global_position,0.8)
  camera_impact(0.045)
  message("Acerto. Preserve o fôlego para recuar.",1.3)

func enemy_defeated(enemy: DungeonEnemy) -> void:
 kills += 1
 add_loot("Pertences do corrompido",layout.to_cell(enemy.position),{"coin":3,"bandage":1} if enemy.heavy else {"coin":2},false)
 message("Área mais segura. E para recolher os pertences.",3)

func use_item(id: String) -> bool:
 if inventory.count(id) <= 0:
  return false
 if Items.info(id).has("damage"):
  inventory.equip(id)
  message("Equipado: "+Items.info(id)["name"])
  return true
 if id == "ration":
  if player.food >= 100:
   message("Você já está alimentado.")
   return false
  player.food = minf(100,player.food+35)
  player.stamina = minf(100,player.stamina+12)
 elif id == "bandage":
  if player.health >= 100 and not player.bleeding:
   message("Você não precisa de tratamento agora.")
   return false
  player.bleeding = false
  player.health = minf(100,player.health+18)
 else:
  return false
 inventory.remove(id)
 ui.refresh_inventory()
 return true

func drop_item(id: String) -> bool:
 if not inventory.remove(id):
  return false
 add_loot("Itens deixados",layout.to_cell(player.position),{id:1},false)
 ui.refresh_inventory()
 message("Item deixado no chão. Use E para recuperá-lo.")
 return true

func on_inventory_changed() -> void:
 if player:
  player.refresh_weapon()

func flash_damage() -> void:
 ui.damage_flash()

func message(text: String, duration: float = 4.0) -> void:
 message_text = text
 message_time = duration
 if ui:
  ui.update_hud()

func end_run(success: bool) -> void:
 if ended:
  return
 ended = true
 ui.show_ending(success)

func save_game(notify_user: bool = true) -> bool:
 if ended and not won:
  return false
 var loot_data: Array = []
 for loot in containers:
  loot_data.append({"name":loot["name"],"pos":loot["pos"],"items":loot["items"],"chest":loot["chest"]})
 var enemy_data: Array = []
 for enemy in enemies:
  enemy_data.append({"health":enemy.health,"alive":enemy.alive,"pos":[enemy.position.x,enemy.position.z]})
 var explored: Array = []
 for cell in discovered:
  explored.append([cell.x,cell.y])
 var data = {"version":1,"inventory":inventory.snapshot(),"player":{"pos":[player.position.x,player.position.z],"health":player.health,"stamina":player.stamina,"food":player.food,"bleeding":player.bleeding},"containers":loot_data,"enemies":enemy_data,"explored":explored,"kills":kills,"hits":hits_received,"won":won}
 var file = FileAccess.open(save_path+".tmp",FileAccess.WRITE)
 if file == null:
  message("Não foi possível salvar a expedição.")
  return false
 file.store_string(JSON.stringify(data))
 file.close()
 var result = DirAccess.rename_absolute(save_path+".tmp",save_path)
 if result != OK:
  message("Falha ao concluir o salvamento.")
  return false
 if notify_user:
  message("Expedição salva.")
 return true

func load_game() -> bool:
 var raw = JSON.parse_string(FileAccess.get_file_as_string(save_path))
 if not valid_save(raw):
  message("O save não pôde ser lido. Iniciando uma expedição nova.")
  return false
 if not inventory.restore(raw["inventory"]):
  return false
 var p = raw["player"]
 player.position = Vector3(p["pos"][0],0,p["pos"][1])
 player.health = p["health"]
 player.stamina = p["stamina"]
 player.food = p["food"]
 player.bleeding = p["bleeding"]
 player.reset_transients()
 for loot in containers:
  loot["node"].queue_free()
 containers.clear()
 for data in raw["containers"]:
  containers.append(data)
  WorldBuilder.add_container(self,data)
 for i in enemies.size():
  var data = raw["enemies"][i]
  enemies[i].health = data["health"]
  enemies[i].alive = data["alive"]
  enemies[i].position = Vector3(data["pos"][0],0,data["pos"][1])
  enemies[i].collision_layer = 4 if enemies[i].alive else 0
  enemies[i].collision_mask = 7 if enemies[i].alive else 0
  enemies[i].windup = 0
  enemies[i].aggro = false
  enemies[i].memory = 0
  enemies[i].stagger = 0
  enemies[i].attack_recovery = 0
  enemies[i].telegraph.hide()
  if not enemies[i].alive:
   Visuals.play(enemies[i].animator,"die",false)
 discovered.clear()
 for cell in raw["explored"]:
  discovered[Vector2i(cell[0],cell[1])] = true
 kills = raw["kills"]
 hits_received = raw["hits"]
 won = raw["won"]
 last_discover = Vector2i(-99,-99)
 camera_rig.position = player.position
 message("Expedição retomada. I abre a mochila; M abre o mapa.",6)
 return true

func valid_save(raw) -> bool:
 if not raw is Dictionary or raw.get("version") != 1:
  return false
 for key in ["inventory","player"]:
  if not raw.get(key) is Dictionary:
   return false
 for key in ["containers","enemies","explored"]:
  if not raw.get(key) is Array:
   return false
 if raw["enemies"].size() != enemies.size():
  return false
 var p: Dictionary = raw["player"]
 if not valid_pos(p.get("pos")):
  return false
 for key in ["health","stamina","food"]:
  if not p.get(key) is float and not p.get(key) is int:
   return false
  if not is_finite(float(p[key])) or p[key] < (0.01 if key == "health" else 0.0) or p[key] > 100:
   return false
 if not p.get("bleeding") is bool or not raw.get("won") is bool:
  return false
 for key in ["kills","hits"]:
  if not (raw.get(key) is float or raw.get(key) is int) or raw[key] < 0:
   return false
 for e in raw["enemies"]:
  if not e is Dictionary or not valid_pos(e.get("pos")) or not e.get("alive") is bool:
   return false
  if not (e.get("health") is float or e.get("health") is int) or not is_finite(float(e["health"])):
   return false
 for loot in raw["containers"]:
  if not loot is Dictionary or not valid_pos(loot.get("pos")) or not loot.get("items") is Dictionary or not loot.get("name") is String or not loot.get("chest") is bool:
   return false
  for id in loot["items"]:
   var n = loot["items"][id]
   if not Items.DATA.has(id) or not (n is float or n is int) or n < 1 or n > 10000 or n != int(n):
    return false
 for cell in raw["explored"]:
  if not cell is Array or cell.size() != 2 or not (cell[0] is float or cell[0] is int) or not (cell[1] is float or cell[1] is int):
   return false
 var check = InventoryData.new()
 return check.restore(raw["inventory"])

func valid_pos(pos) -> bool:
 if not pos is Array or pos.size() != 2:
  return false
 for value in pos:
  if not (value is float or value is int) or not is_finite(float(value)):
   return false
 return layout.is_floor(layout.to_cell(Vector3(pos[0],0,pos[1])))

func restart() -> void:
 get_tree().paused = false
 if FileAccess.file_exists(save_path):
  DirAccess.remove_absolute(save_path)
 get_tree().reload_current_scene()

func run_test_mode() -> void:
 var harness = load("res://tests/runtime_test.gd").new()
 add_child(harness)
 harness.run(self, "--capture" in OS.get_cmdline_user_args())

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player):
  if not test_mode and player.health > 0:
   save_game(false)
  get_tree().quit()
