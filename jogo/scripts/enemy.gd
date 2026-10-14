extends CharacterBody3D
class_name DungeonEnemy

var game
var enemy_id: int
var home: Vector3
var health: float = 65.0
var maximum_health: float = 65.0
var heavy: bool = false
var animator: AnimationPlayer
var visual: Node3D
var telegraph: MeshInstance3D
var health_label: Label3D
var windup: float = 0.0
var cooldown: float = 0.0
var stagger: float = 0.0
var committed: Vector3 = Vector3.FORWARD
var path: Array[Vector2i] = []
var repath: float = 0
var last_seen: Vector3
var memory: float = 0.0
var impulse: Vector3 = Vector3.ZERO
var attack_recovery: float = 0.0
var step_time: float = 0.0
var aggro: bool = false
var alive: bool = true

func _ready() -> void:
 collision_layer = 4
 collision_mask = 1 | 2 | 4
 home = position
 last_seen = home
 var shape = CollisionShape3D.new()
 var capsule = CapsuleShape3D.new()
 capsule.radius = 0.4
 capsule.height = 1.5
 shape.shape = capsule
 shape.position.y = 0.76
 add_child(shape)
 visual = Visuals.model("character-orc", 1.18 if heavy else 1.0)
 add_child(visual)
 animator = Visuals.animation(visual)
 telegraph = Visuals.attack_arc(1.85,Color(0.91,0.39,0.24,0.65),0.95,0.10)
 add_child(telegraph)
 telegraph.position.y = 0.07
 telegraph.visible = false
 health_label = Label3D.new()
 health_label.position.y = 2.05
 health_label.font_size = 32
 health_label.pixel_size = 0.007
 health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 health_label.modulate = Color("ecb9a7")
 health_label.no_depth_test = true
 add_child(health_label)
 maximum_health = 95 if heavy else 65
 health = maximum_health

func _physics_process(delta: float) -> void:
 if not alive or game.player.health <= 0:
  return
 var player = game.player
 var distance: float = global_position.distance_to(player.global_position)
 visible = distance < 20 and game.clear_line(player.global_position,global_position)
 health_label.visible = aggro or health < maximum_health
 health_label.text = "%s  %d" % ["Guardião" if heavy else "Corrompido",ceil(health)]
 cooldown = maxf(0,cooldown-delta)
 stagger = maxf(0,stagger-delta)
 memory = maxf(0,memory-delta)
 attack_recovery = maxf(0,attack_recovery-delta)
 if stagger > 0:
  velocity = impulse
  velocity.y = -2
  move_and_slide()
  impulse = impulse.move_toward(Vector3.ZERO,16*delta)
  return
 if windup > 0:
  windup -= delta
  telegraph.visible = true
  telegraph.scale = Vector3.ONE * (1.0 + sin(windup*24)*0.035)
  if windup <= 0:
   telegraph.visible = false
   attack_recovery = 0.30
   game.sound.play_at("swing",global_position,0.45)
   var offset: Vector3 = player.global_position-global_position
   offset.y = 0
   if not game.is_safe() and offset.length() < 2.0 and committed.dot(offset.normalized()) >= cos(0.95) and game.clear_line(global_position,player.global_position):
    player.receive_damage(24 if heavy else 17,committed)
   cooldown = 1.2
  return
 var can_see: bool = game.clear_line(global_position,player.global_position)
 if not game.is_safe() and distance < (11.0 if player.sprinting else 7.5) and can_see:
  aggro = true
  last_seen = player.global_position
  memory = 3.0
 if aggro and can_see and not game.is_safe():
  last_seen = player.global_position
  memory = 3.0
 if game.is_safe() or distance > 16:
  aggro = false
 if memory <= 0:
  aggro = false
 if attack_recovery > 0:
  return
 if aggro and distance < 1.8 and can_see and cooldown <= 0:
  windup = 0.85 if heavy else 0.65
  committed = (player.global_position-global_position).normalized()
  visual.rotation.y = atan2(committed.x,committed.z)
  telegraph.rotation.y = visual.rotation.y
  if animator.has_animation("attack"):
   animator.play("attack",0.08,animator.get_animation("attack").length/(windup+0.30))
  return
 var target: Vector3 = last_seen if aggro else home
 var direction = Vector3.ZERO
 if global_position.distance_to(target) > (1.4 if aggro else 0.25):
  repath -= delta
  if repath <= 0:
   path = game.layout.route(global_position,target)
   repath = 0.4
  if path.size() > 1:
   var next = game.layout.to_world(path[1])
   if global_position.distance_to(next) < 0.24:
    path.pop_front()
   direction = (next-global_position).normalized()
  elif can_see and aggro:
   direction = (target-global_position).normalized()
 direction.y = 0
 velocity = direction * (1.85 if heavy else 2.6)
 velocity.y = -2
 move_and_slide()
 if direction.length() > 0.1:
  visual.rotation.y = lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),minf(1,delta*10))
 if cooldown < 0.75:
  Visuals.play(animator,"walk" if direction.length() > 0.1 else "guard" if aggro else "idle")
 step_time -= delta
 if direction.length()>0.1 and step_time<=0:
  game.sound.play_at("step",global_position,0.22)
  step_time = 0.55

func receive_damage(amount: float, direction: Vector3 = Vector3.ZERO) -> void:
 if not alive:
  return
 health -= amount
 stagger = 0.25
 impulse = direction.normalized()*(2.0 if heavy else 3.0)
 if animator.has_animation("hit"):
  animator.play("hit",0.04,animator.get_animation("hit").length/0.25)
 windup = 0
 telegraph.visible = false
 aggro = true
 last_seen = game.player.global_position
 memory = 3.0
 if health <= 0:
  alive = false
  collision_layer = 0
  collision_mask = 0
  health_label.visible = false
  Visuals.play(animator,"die",false)
  game.enemy_defeated(self)
