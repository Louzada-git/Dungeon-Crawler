extends CharacterBody3D
class_name DungeonPlayer

const INPUT_BUFFER: float = 0.16
var game
var visual: Node3D
var animator: AnimationPlayer
var weapon_mount: BoneAttachment3D
var held_weapon: Node3D
var facing: Vector3 = Vector3(0,0,-1)
var health: float = 100.0
var stamina: float = 100.0
var food: float = 85.0
var bleeding: bool = false
var attack_timer: float = 0.0
var attack_wait: float = 0.0
var attack_weapon: Dictionary = {}
var attack_facing: Vector3 = Vector3.FORWARD
var attack_serial: int = 0
var resolved_serial: int = -1
var attack_buffer: float = 0.0
var cooldown: float = 0.0
var dodge_timer: float = 0.0
var dodge_direction: Vector3
var invulnerable: float = 0.0
var walking: bool = false
var sprinting: bool = false
var aiming: bool = false
var hurt_timer: float = 0.0
var impulse: Vector3 = Vector3.ZERO
var motion_velocity: Vector3 = Vector3.ZERO
var step_time: float = 0.0
var test_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
 collision_layer = 2
 collision_mask = 1 | 4
 var collision = CollisionShape3D.new()
 var capsule = CapsuleShape3D.new()
 capsule.radius = 0.34
 capsule.height = 1.4
 collision.shape = capsule
 collision.position.y = 0.72
 add_child(collision)
 visual = Visuals.model("aventureiro_mixamo",1.0)
 add_child(visual)
 animator = Visuals.animation(visual)
 var skel = Visuals.skeleton(visual)
 if skel:
  weapon_mount = BoneAttachment3D.new()
  weapon_mount.bone_name = "hand-right"
  skel.add_child(weapon_mount)
 var marker = Visuals.ring(0.43,Color("cbb88a"),0.025)
 marker.position.y = 0.04
 add_child(marker)
 var listener = AudioListener3D.new()
 add_child(listener)
 listener.make_current()
 refresh_weapon()

func refresh_weapon() -> void:
 if weapon_mount == null:
  return
 for child in weapon_mount.get_children():
  child.queue_free()
 held_weapon = null
 var id: String = game.inventory.equipped
 if id == "":
  return
 var weapon = Visuals.model(Items.info(id)["model"],1.0)
 held_weapon = weapon
 weapon_mount.add_child(weapon)
 weapon.position = Vector3(0,0.035,0)
 weapon.rotation_degrees.x = -85 if id == "spear" else -55
 if id == "spear":
  weapon.scale.y = 1.9

func _process(_delta: float) -> void:
 if not is_instance_valid(held_weapon) or game.inventory.equipped != "spear":
  return
 if attack_timer > 0 and attack_weapon.get("style", "") == "thrust":
  # Keep the pole aimed down the committed attack line while both arms reach.
  var axis: Vector3 = attack_facing.normalized()
  var side: Vector3 = Vector3.UP.cross(axis).normalized()
  held_weapon.global_basis = Basis(side,axis,side.cross(axis))*Basis.from_scale(Vector3(1,1.9,1))
 else:
  held_weapon.rotation_degrees = Vector3(-85,0,0)
  held_weapon.scale = Vector3(1,1.9,1)

func aim_mouse() -> void:
 if game.camera == null:
  return
 var mouse = get_viewport().get_mouse_position()
 var point = Plane(Vector3.UP,0.65).intersects_ray(game.camera.project_ray_origin(mouse),game.camera.project_ray_normal(mouse))
 if point != null:
  var target: Vector3 = point-global_position
  target.y = 0
  if target.length() > 0.25:
   facing = target.normalized()

func request_attack() -> void:
 if health <= 0 or hurt_timer > 0 or dodge_timer > 0:
  return
 if cooldown <= 0:
  aim_mouse()
  attack()
 elif cooldown <= INPUT_BUFFER:
  attack_buffer = INPUT_BUFFER

func animate_action(name: String, duration: float) -> void:
 if name in ["hit", "attack", "stab"] and animator and animator.has_animation("mixamo_"+name):
  name = "mixamo_"+name
 if animator and animator.has_animation(name):
  animator.play(name,0.0 if name in ["mixamo_attack", "mixamo_stab"] else 0.07,animator.get_animation(name).length/duration)
  if name in ["mixamo_attack", "mixamo_stab"]:
   animator.seek(0.0,true)

func _physics_process(delta: float) -> void:
 if health <= 0:
  return
 cooldown = maxf(0,cooldown-delta)
 invulnerable = maxf(0,invulnerable-delta)
 attack_timer = maxf(0,attack_timer-delta)
 hurt_timer = maxf(0,hurt_timer-delta)
 if attack_wait > 0:
  attack_wait -= delta
  if attack_wait <= 0:
   game.resolve_player_attack()
 if attack_buffer > 0:
  if cooldown <= 0 and hurt_timer <= 0 and dodge_timer <= 0:
   attack_buffer = 0
   aim_mouse()
   attack()
  else:
   attack_buffer = maxf(0,attack_buffer-delta)
 var input_axis = Input.get_vector("left","right","up","down")
 if test_direction != Vector2.ZERO:
  input_axis = test_direction
 var direction = Vector3(input_axis.x+input_axis.y,0,input_axis.y-input_axis.x).normalized()
 aiming = Input.is_action_pressed("aim") and hurt_timer <= 0
 walking = direction.length_squared() > 0.01
 if attack_timer <= 0 and dodge_timer <= 0:
  if aiming:
   aim_mouse()
  elif walking:
   facing = direction
 sprinting = walking and Input.is_action_pressed("sprint") and not aiming and stamina > 4 and attack_timer <= 0 and hurt_timer <= 0 and dodge_timer <= 0
 var speed: float = 3.5
 if sprinting:
  speed = 5.7
  stamina = maxf(0,stamina-16*delta)
 elif attack_timer <= 0 and dodge_timer <= 0 and hurt_timer <= 0:
  stamina = minf(100,stamina+(16.0 if food > 10 else 6.0)*delta)
 if aiming:
  speed *= 0.75 if direction.dot(facing) >= 0 else 0.55
 if game.inventory.weight() > InventoryData.COMFORT:
  speed *= lerpf(1.0,0.72,(game.inventory.weight()-InventoryData.COMFORT)/(InventoryData.CAPACITY-InventoryData.COMFORT))
 if attack_timer > 0:
  speed *= 0.30
 if hurt_timer > 0:
  speed *= 0.20
 var horizontal = motion_velocity
 horizontal = horizontal.move_toward(direction*speed,(18.0 if walking else 26.0)*delta)
 if dodge_timer > 0:
  dodge_timer = maxf(0,dodge_timer-delta)
  horizontal = dodge_direction*8.0
 motion_velocity = horizontal
 impulse = impulse.move_toward(Vector3.ZERO,12*delta)
 velocity = horizontal+impulse
 velocity.y = -2
 move_and_slide()
 var look = attack_facing if attack_timer > 0 else facing
 visual.rotation.y = lerp_angle(visual.rotation.y,atan2(look.x,look.z),minf(1,delta*18))
 # One-shot actions start only on entry; they are not restarted on every frame.
 if hurt_timer <= 0 and attack_timer <= 0 and dodge_timer <= 0:
  if horizontal.length() > 0.3:
   Visuals.play(animator,"run" if sprinting else "walk",true,clampf(horizontal.length()/(5.7 if sprinting else 3.5),0.45,1.25))
  else:
   Visuals.play(animator,"guard" if aiming else "idle")
 step_time -= delta
 if horizontal.length() > 0.5 and dodge_timer <= 0 and step_time <= 0:
  game.sound.play_at("step",global_position,0.48 if sprinting else 0.28)
  step_time = 0.25 if sprinting else 0.42
 food = maxf(0,food-delta*(0.07 if sprinting else 0.025))
 if bleeding:
  health = maxf(0,health-delta*0.5)
 if food <= 0:
  health = maxf(0,health-delta*0.2)
 if health <= 0:
  die()

func attack() -> bool:
 if cooldown > 0 or dodge_timer > 0 or hurt_timer > 0 or health <= 0:
  return false
 var weapon = Items.info(game.inventory.equipped)
 var cost: float = weapon.get("cost",10.0)
 if stamina < cost:
  game.message("Sem fôlego. Recue para recuperar.")
  return false
 stamina -= cost
 attack_weapon = weapon.duplicate()
 attack_facing = facing
 attack_serial += 1
 cooldown = weapon.get("cooldown",0.62)
 attack_timer = cooldown*0.90
 attack_wait = weapon.get("windup",0.22)
 animate_action("stab" if weapon.get("style","")=="thrust" else "attack",attack_timer)
 game.sound.play_at("swing",global_position,0.65)
 return true

func dodge() -> bool:
 if stamina < 25 or dodge_timer > 0 or attack_timer > 0 or hurt_timer > 0 or health <= 0:
  return false
 var input = Input.get_vector("left","right","up","down")
 if test_direction != Vector2.ZERO:
  input = test_direction
 dodge_direction = Vector3(input.x+input.y,0,input.y-input.x).normalized() if input.length()>0 else facing
 stamina -= 25
 dodge_timer = 0.25
 invulnerable = 0.20
 attack_buffer = 0
 animate_action("dodge",dodge_timer)
 game.sound.play_at("step",global_position,0.55)
 return true

func receive_damage(amount: float, from: Vector3 = Vector3.ZERO) -> void:
 if invulnerable > 0 or health <= 0:
  return
 health = maxf(0,health-amount)
 invulnerable = 0.7
 hurt_timer = 0.23
 attack_timer = 0
 attack_wait = 0
 attack_buffer = 0
 impulse = from.normalized()*1.8
 animate_action("hit",hurt_timer)
 game.sound.play_at("hurt",global_position,0.8)
 game.camera_impact(0.10)
 game.hits_received += 1
 if game.hits_received%3==0:
  bleeding = true
  game.message("Ferimento aberto! Use uma bandagem no inventário.")
 game.flash_damage()
 if health <= 0:
  die()

func reset_transients() -> void:
 motion_velocity = Vector3.ZERO
 velocity = Vector3.ZERO
 impulse = Vector3.ZERO
 attack_timer = 0
 attack_wait = 0
 attack_buffer = 0
 cooldown = 0
 dodge_timer = 0
 hurt_timer = 0
 invulnerable = 0
 resolved_serial = attack_serial

func die() -> void:
 health = 0
 attack_wait = 0
 attack_buffer = 0
 Visuals.play(animator,"die",false)
 game.end_run(false)
