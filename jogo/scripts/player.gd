extends CharacterBody3D
class_name DungeonPlayer

const INPUT_BUFFER: float = 0.16
## The dodge comes back after this share of the delay that follows the blow.
const DODGE_AFTER: float = 0.5
## Extra wait before the next blow, per kg of the weapon (martelo 6,5 kg: +0,65 s).
## Only the next blow waits: no slowdown, the dodge is not held.
const DELAY_PER_KG: float = 0.1
## Health lost per second while bleeding and while starving.
const BLEED_PER_SECOND: float = 0.5
const STARVE_PER_SECOND: float = 0.2
## At or below this much food the stamina recovers slowly.
const HUNGRY: float = 10.0
var game
var visual: Node3D
var animator: AnimationPlayer
## Character model (assets/originais/<id>.glb) and where its hands and torso are.
const MODEL := "aventureiro_psx"
## Rigs with other bone names: [bone, rotation, offset] for each mount.
## Hands (17/10/2026): a natural grip in the closed fist; the handle runs along
## the axis the fingers wrap around, the head or edge (+X) toward the knuckles.
## The same values are GRIP in arte/fontes/personagem_psx/personagens.gd.
## The spine: from arte/fontes/personagem_psx/transferir_animacoes.gd (MOUNT lines).
const MOUNTS := {
	"hand-right": ["mixamorig_RightHand", Quaternion(0.63048505783081, 0.77200245857239, -0.05100067332387, 0.06244818121195), Vector3(-0.03210743889213, 0.06280439347029, 0.02609892003238)],
	"hand-left": ["mixamorig_LeftHand", Quaternion(0.67360925674438, 0.73670476675034, -0.0400165617466, 0.04376482963562), Vector3(-0.03327637538314, 0.06309830397367, -0.02205528132617)],
	"spine": ["mixamorig_Spine", Quaternion(0.039866824, 0.705982, -0.03986682, 0.705982), Vector3(0.0030038357, -0.06060183, -0.025849571)],
}
var weapon_mount: Node3D
var left_mount: Node3D
## Worn armor rides on the spine bone.
var armor_mount: Node3D
var worn_model: Node3D
var _worn_id: String = ""
var held_weapon: Node3D
## Item whose model is in the hand now (refresh_weapon rebuilds only when it changes).
var _held_id: String = ""
var facing: Vector3 = Vector3(0,0,-1)
var health: float = 100.0
var stamina: float = 100.0
## Set from the adventurer's attributes (CharacterSheet).
var max_health: float = 100.0
var max_stamina: float = 100.0
var food: float = 85.0
var bleeding: bool = false
var attack_timer: float = 0.0
var attack_wait: float = 0.0
## Technique dash: seconds left and speed.
var dash_time: float = 0.0
var dash_velocity: Vector3 = Vector3.ZERO
## Seconds to the next puff of dust during a dash.
var dash_fx: float = 0.0
var attack_weapon: Dictionary = {}
## Item held when the blow started ("" = fists): the hitbox follows its model.
var attack_item: String = ""
var attack_facing: Vector3 = Vector3.FORWARD
var attack_serial: int = 0
var resolved_serial: int = -1
var attack_buffer: float = 0.0
var cooldown: float = 0.0
var dodge_timer: float = 0.0
## Seconds until the dodge is free again after a blow (half of its delay).
var dodge_lock: float = 0.0
var dodge_direction: Vector3
var invulnerable: float = 0.0
var walking: bool = false
var sprinting: bool = false
var aiming: bool = false
## Crouched and quiet (C): slower, harder to notice.
var sneaking: bool = false
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
	visual = Visuals.model(MODEL,1.0)
	add_child(visual)
	animator = Visuals.animation(visual)
	var skel = Visuals.skeleton(visual)
	if skel:
		weapon_mount = mount(skel,"hand-right")
		left_mount = mount(skel,"hand-left")
		armor_mount = mount(skel,"spine")
	var marker = Visuals.ring(0.43,Color("cbb88a"),0.025)
	marker.position.y = 0.04
	add_child(marker)
	var listener = AudioListener3D.new()
	add_child(listener)
	listener.make_current()
	refresh_weapon()

## Suffix of the standing and moving animations for the way the weapon in hand
## is carried (data "porte": duas, haste, besta, arco; empty hands: livre).
func carry_suffix() -> String:
	var id: String = game.inventory.equipped if game else ""
	if id == "":
		return "_livre"
	var way: String = str(Items.info(id).get("porte",""))
	return "_" + way if way != "" else ""

## Animation for moving or standing still, in the variant for the way the weapon
## is carried when the rig has it. Optional animations made for the rig
## (furtivo, furtivo_andar, bloqueio) replace the stand-ins when they exist.
func locomotion(moving: float) -> Array:
	var pose: Array = _locomotion(moving)
	var carried: String = str(pose[0]) + carry_suffix()
	if animator != null and animator.has_animation(carried):
		pose[0] = carried
	return pose

func _locomotion(moving: float) -> Array:
	var has = func(n: String) -> bool: return animator != null and animator.has_animation(n)
	if moving > 0.3:
		if sneaking and not sprinting and has.call("furtivo_andar"):
			return ["furtivo_andar",true,clampf(moving/2.0,0.45,1.25)]
		return ["run" if sprinting else "walk",true,clampf(moving/(5.7 if sprinting else 3.5),0.45,1.25)]
	if aiming and can_block() and has.call("bloqueio"):
		return ["bloqueio",true,1.0]
	if sneaking and has.call("furtivo"):
		return ["furtivo",true,1.0]
	return ["guard" if aiming or sneaking else "idle",true,1.0]

## Attachment that follows a bone of the original rig, or the matching bone of
## another rig with the correction from MOUNTS.
func mount(skel: Skeleton3D, bone: String) -> Node3D:
	var attach := BoneAttachment3D.new()
	skel.add_child(attach)
	if skel.find_bone(bone) >= 0 or not MOUNTS.has(bone):
		attach.bone_name = bone
		return attach
	var entry: Array = MOUNTS[bone]
	attach.bone_name = entry[0]
	var grip := Node3D.new()
	grip.name = "ponto_" + bone
	grip.transform = Transform3D(Basis(entry[1]), entry[2])
	attach.add_child(grip)
	return grip

## Puts the equipped weapon's model in the hand. Called on every change of the
## backpack; the model is rebuilt only when the weapon itself changes (eating or
## shooting an arrow keeps the one in hand).
func refresh_weapon() -> void:
	refresh_armor()
	if weapon_mount == null:
		return
	var id: String = game.inventory.equipped
	if id == _held_id and (id == "" or is_instance_valid(held_weapon)):
		return
	_held_id = id
	for hand in [weapon_mount,left_mount]:
		for child in hand.get_children():
			child.queue_free()
	held_weapon = null
	if id == "":
		return
	var data: Dictionary = Items.info(id)
	var weapon = Visuals.item_model(id)
	held_weapon = weapon
	# "mao": "esquerda" holds the weapon in the left hand (bows).
	(left_mount if str(data.get("mao","direita")) == "esquerda" else weapon_mount).add_child(weapon)
	weapon.position = Vector3(0,0.035,0)
	weapon.rotation_degrees = rest_rotation(data)
	weapon.scale = hand_scale(id,data)

## Shows the worn armor on the torso. Data "corpo": {"pos":[x,y,z], "escala":[x,y,z]}
## places it relative to the spine bone (models made for the rig use the defaults).
func refresh_armor() -> void:
	if armor_mount == null:
		return
	var id: String = game.inventory.armor
	if id == _worn_id and (id == "" or is_instance_valid(worn_model)):
		return
	if is_instance_valid(worn_model):
		worn_model.queue_free()
	worn_model = null
	_worn_id = id
	if id == "":
		return
	var data: Dictionary = Items.info(id)
	var place: Dictionary = data.get("corpo",{})
	worn_model = Visuals.item_model(id)
	armor_mount.add_child(worn_model)
	var pos: Array = place.get("pos",[0,0,0])
	var size: Array = place.get("escala",[1,1,1])
	worn_model.position = Vector3(pos[0],pos[1],pos[2])
	worn_model.scale = Vector3(size[0],size[1],size[2])

## Angle of the weapon in the fist: data "rotacao_mao", else the natural grip
## (the handle straight through the fist).
func rest_rotation(data: Dictionary) -> Vector3:
	if data.has("rotacao_mao"):
		var r: Array = data["rotacao_mao"]
		return Vector3(r[0],r[1],r[2])
	return Vector3.ZERO

## "escala_mao" stretches the old short spear model; models made for the item use 1.
func hand_scale(id: String, data: Dictionary) -> Vector3:
	if data.has("escala_modelo") and Visuals.has_custom_model(id):
		return Vector3.ONE * float(data["escala_modelo"])
	if data.has("escala_mao") and not Visuals.has_custom_model(id) and not data.has("blocks"):
		var s: Array = data["escala_mao"]
		return Vector3(s[0],s[1],s[2])
	return Vector3.ONE

func _process(_delta: float) -> void:
	if not is_instance_valid(held_weapon):
		return
	var data: Dictionary = Items.info(game.inventory.equipped)
	if not data.get("alinhar_ao_golpe",false):
		return
	var size: Vector3 = hand_scale(game.inventory.equipped,data)
	if attack_timer > 0 and attack_weapon.get("alinhar_ao_golpe",false):
		# Keep the pole aimed down the committed attack line while both arms reach.
		aim_held(held_weapon,Visuals.skeleton(visual),data,attack_facing,size)
	else:
		held_weapon.rotation_degrees = rest_rotation(data)
		held_weapon.scale = size

## Points a held weapon along `axis` (its +Y), the head or edge (+X) level, from
## the hand bone's current pose (the bone attachment only follows at the end of
## the frame, so its transform may still be the last one).
static func aim_held(weapon: Node3D, skel: Skeleton3D, data: Dictionary, axis: Vector3, size: Vector3) -> void:
	if weapon == null or skel == null:
		return
	var entry: Array = MOUNTS["hand-left" if str(data.get("mao","direita")) == "esquerda" else "hand-right"]
	var bone: int = skel.find_bone(entry[0])
	if bone < 0:
		return
	var parent: Basis = (skel.global_transform*skel.get_bone_global_pose(bone)).basis.orthonormalized()*Basis(entry[1])
	var forward: Vector3 = axis.normalized()
	var side: Vector3 = Vector3.UP.cross(forward).normalized()
	weapon.basis = parent.inverse()*Basis(side,forward,side.cross(forward))*Basis.from_scale(size)

func aim_mouse() -> void:
	if game.camera == null:
		return
	# Third person: blows and aim go where the camera looks.
	if game.third_person():
		facing = game.camera_rig.forward()
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

## Plays a one-shot action (blow, dodge, hit) so that it lasts `duration`
## seconds. The walk leaves its own pace in speed_scale (slower while speeding
## up or carrying weight), which would stretch the action: it goes back to 1.
func animate_action(anim_name: String, duration: float) -> void:
	if anim_name in ["hit", "attack", "stab"] and animator and animator.has_animation("mixamo_"+anim_name):
		anim_name = "mixamo_"+anim_name
	if animator and animator.has_animation(anim_name):
		animator.speed_scale = 1.0
		animator.play(anim_name,0.0 if anim_name in ["mixamo_attack", "mixamo_stab"] else 0.07,animator.get_animation(anim_name).length/duration)
		if anim_name in ["mixamo_attack", "mixamo_stab"]:
			animator.seek(0.0,true)

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	cooldown = maxf(0,cooldown-delta)
	game.techniques.tick(delta)
	invulnerable = maxf(0,invulnerable-delta)
	dodge_lock = maxf(0,dodge_lock-delta)
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
	if game.ui and game.ui.typing():
		input_axis = Vector2.ZERO
	if test_direction != Vector2.ZERO:
		input_axis = test_direction
	# Isometric: screen-aligned; third person: relative to where the camera looks.
	var direction: Vector3 = game.camera_rig.move_direction(input_axis) if game.camera_rig else Vector3(input_axis.x+input_axis.y,0,input_axis.y-input_axis.x).normalized()
	aiming = Input.is_action_pressed("aim") and hurt_timer <= 0
	walking = direction.length_squared() > 0.01
	if attack_timer <= 0 and dodge_timer <= 0:
		if aiming:
			aim_mouse()
		elif walking:
			facing = direction
	sprinting = walking and Input.is_action_pressed("sprint") and not aiming and stamina > 4 and attack_timer <= 0 and hurt_timer <= 0 and dodge_timer <= 0
	if sprinting:
		sneaking = false
	var armor: String = game.inventory.armor
	var speed: float = 3.5
	if sprinting:
		speed = 5.7
		stamina = maxf(0,stamina-game.sheet.stamina_rule("corrida",8.0)*delta*game.sheet.sprint_cost_mult())
	elif attack_timer <= 0 and dodge_timer <= 0 and hurt_timer <= 0:
		stamina = minf(max_stamina,stamina+stamina_regen(food <= HUNGRY)*delta)
	if sneaking:
		speed *= 0.55
	speed *= 1.0 - game.sheet.armor_speed_penalty(armor)
	if aiming:
		speed *= 0.75 if direction.dot(facing) >= 0 else 0.55
	speed *= game.sheet.speed_mult()
	if game.inventory.weight() > game.inventory.comfort:
		speed *= lerpf(1.0,0.72,(game.inventory.weight()-game.inventory.comfort)/(game.inventory.capacity-game.inventory.comfort))
	if attack_timer > 0:
		speed *= 0.30
	if hurt_timer > 0:
		speed *= 0.20
	var horizontal = motion_velocity
	horizontal = horizontal.move_toward(direction*speed,(18.0 if walking else 26.0)*delta)
	if dodge_timer > 0:
		dodge_timer = maxf(0,dodge_timer-delta)
		horizontal = dodge_direction*8.0
	elif dash_time > 0:
		# Technique dash (Investida, Avanço): forward during the wind-up.
		dash_time = maxf(0,dash_time-delta)
		horizontal = dash_velocity
		dash_fx -= delta
		if dash_fx <= 0:
			dash_fx = 0.08
			Vfx.dust(game,global_position,1,0.15,0.8)
	motion_velocity = horizontal
	impulse = impulse.move_toward(Vector3.ZERO,12*delta)
	velocity = horizontal+impulse
	velocity.y = -2
	move_and_slide()
	if sprinting and horizontal.length() > 3.0 and not game.is_safe():
		game.on_sprint(horizontal.length()*delta)
	var look = attack_facing if attack_timer > 0 else facing
	visual.rotation.y = lerp_angle(visual.rotation.y,atan2(look.x,look.z),minf(1,delta*18))
	# One-shot actions start only on entry; they are not restarted on every frame.
	if hurt_timer <= 0 and attack_timer <= 0 and dodge_timer <= 0:
		var pose: Array = locomotion(horizontal.length())
		Visuals.play(animator,pose[0],pose[1],pose[2])
	step_time -= delta
	if horizontal.length() > 0.5 and dodge_timer <= 0 and step_time <= 0:
		game.sound.play_at("step",global_position,0.48 if sprinting else (0.1 if sneaking else 0.28))
		step_time = 0.25 if sprinting else 0.42
	food = maxf(0,food-delta*(0.07 if sprinting else 0.025)*game.sheet.hunger_mult())
	if bleeding:
		health = maxf(0,health-delta*BLEED_PER_SECOND)
	if food <= 0:
		health = maxf(0,health-delta*STARVE_PER_SECOND)
	if health <= 0:
		die()

## Stamina recovered per second while resting from blows, fed or hungry, with
## this adventurer's Destreza and the armor worn (the HUD texts show it too).
func stamina_regen(hungry: bool) -> float:
	var base: float = game.sheet.stamina_rule("recuperacao_com_fome",7.8) if hungry else game.sheet.stamina_rule("recuperacao",20.8)
	return base*game.sheet.stamina_regen_mult()*(1.0-game.sheet.armor_regen_penalty(game.inventory.armor))

## Normal attack with the weapon in hand, or a technique when `stats` is given
## (Techniques.stats: same fields plus hits, dash and recarga).
func attack(stats: Dictionary = {}) -> bool:
	if cooldown > 0 or dodge_timer > 0 or hurt_timer > 0 or health <= 0:
		return false
	var weapon = stats if not stats.is_empty() else game.sheet.weapon_stats(game.inventory.equipped)
	var cost: float = weapon.get("cost",10.0)
	var ammo: String = game.ammo_for(weapon)
	if ammo != "" and game.inventory.count(ammo) <= 0:
		game.message("Sem %ss. Procure mais nos baús e nos corpos dos monstros." % str(Items.info(ammo).get("name",ammo)).to_lower())
		return false
	if stamina < cost:
		game.message("Sem fôlego. Recue para recuperar.")
		return false
	stamina -= cost
	attack_weapon = weapon.duplicate()
	attack_item = game.inventory.equipped
	attack_facing = facing
	attack_serial += 1
	# "cooldown" is the whole blow; heavy weapons carry a long delay after it lands.
	# A long wind-up (heavy techniques) keeps the adventurer committed until the blow lands.
	var windup: float = float(weapon.get("windup",0.22))
	cooldown = maxf(float(weapon.get("cooldown",0.62)),windup+0.15)
	attack_timer = cooldown*0.90
	attack_wait = windup
	# The dodge comes back halfway through the delay after the blow.
	dodge_lock = windup+(cooldown-windup)*DODGE_AFTER
	# The weapon's weight holds the next blow a little longer (and only that).
	cooldown += weight_delay(weapon)
	var dash: float = float(weapon.get("dash",0.0))
	if dash > 0.0:
		dash_time = maxf(0.12,float(attack_wait))
		dash_velocity = facing.normalized()*dash/dash_time
		dash_fx = 0
	# The swing animation lands on the wind-up: it lasts windup / "impacto" (its share before the hit).
	# The animation is timed so its blow lands when the preparation ends.
	var anim: String = attack_animation(weapon)
	animate_action(anim,windup/clampf(Animacoes.impact(MODEL,anim,float(weapon.get("impacto",0.39))),0.1,0.9))
	game.sound.play_at("swing",global_position,0.65)
	return true

## Extra seconds before the next blow from the weapon's weight.
static func weight_delay(weapon: Dictionary) -> float:
	return maxf(0.0,float(weapon.get("weight",0.0)))*DELAY_PER_KG

## Uses the habilidade on bar slot `slot` (keys chosen by the player) toward the cursor
## (aim = false keeps the current facing; used by tests).
func use_technique(slot: int, aim: bool = true) -> bool:
	var book: TechniqueBook = game.techniques
	var form_id: String = book.at_slot(slot)
	if form_id == "":
		game.message("Espaço [%s] da barra vazio. T abre as habilidades." % game.technique_key_name(slot),2)
		return false
	if health <= 0 or hurt_timer > 0 or dodge_timer > 0 or cooldown > 0:
		return false
	var weapon: String = game.inventory.equipped
	var problem: String = Techniques.problem(game.sheet,book,form_id,weapon)
	if problem != "":
		game.message(problem,2.5)
		return false
	if book.remaining(form_id) > 0:
		game.message("%s recarrega em %s s." % [Techniques.form_name(form_id),UiStyle.fmt(book.remaining(form_id))],1.5)
		return false
	if aim:
		aim_mouse()
	var stats: Dictionary = Techniques.stats(game.sheet,form_id,book.objects(form_id),weapon)
	if not attack(stats):
		return false
	book.start(form_id,float(stats.get("recarga",1.5)))
	game.on_technique_used(form_id)
	return true

## The animation made for the weapon when the rig has it; else the closest existing one.
func attack_animation(weapon: Dictionary) -> String:
	return attack_animation_for(weapon,animator)

static func attack_animation_for(weapon: Dictionary, animator: AnimationPlayer) -> String:
	var wanted: String = str(weapon.get("animacao",""))
	if wanted != "" and animator and animator.has_animation(wanted):
		return wanted
	match str(weapon.get("style","slash")):
		"thrust":
			return "stab"
		"shoot":
			return "guard"
	return "attack"

func dodge_cost() -> float:
	return game.sheet.dodge_cost()

func dodge() -> bool:
	var cost: float = dodge_cost()
	if stamina < cost or dodge_timer > 0 or dodge_lock > 0 or attack_wait > 0 or hurt_timer > 0 or health <= 0:
		return false
	# Dodging out of the delay after a blow cuts it (the next blow still waits its time).
	attack_timer = 0
	var input = Input.get_vector("left","right","up","down")
	if test_direction != Vector2.ZERO:
		input = test_direction
	var dir: Vector3 = game.camera_rig.move_direction(input) if game.camera_rig else Vector3(input.x+input.y,0,input.y-input.x).normalized()
	dodge_direction = dir if input.length()>0 else facing
	stamina -= cost
	dodge_timer = 0.25
	invulnerable = 0.20
	attack_buffer = 0
	animate_action("dodge",dodge_timer)
	game.sound.play_at("step",global_position,0.55)
	Vfx.dust(game,global_position-dodge_direction*0.2,2,0.2)
	return true

func toggle_sneak() -> void:
	if health <= 0:
		return
	sneaking = not sneaking
	game.message("Furtivo: os monstros só te notam de mais perto, e menos ainda por trás." if sneaking else "De pé.", 2.5)

## The guard is up while aiming (right button) with a melee weapon or bare hands.
func can_block() -> bool:
	if not aiming or attack_timer > 0 or dodge_timer > 0 or hurt_timer > 0 or health <= 0:
		return false
	return str(CharacterSheet.base_stats(game.inventory.equipped).get("style","slash")) != "shoot"

## How far monsters notice the adventurer, relative to their normal sight.
func detection_mult(enemy = null) -> float:
	var noise: float = game.sheet.armor_noise(game.inventory.armor)
	if sprinting:
		return 1.47*(1.0+noise)
	if not sneaking:
		return 1.0+noise*0.5
	var m: float = game.sheet.sneak_detection_mult()*(1.0+noise)
	if enemy != null and enemy.visual != null:
		var forward := Vector3(sin(enemy.visual.rotation.y),0,cos(enemy.visual.rotation.y))
		var to_me: Vector3 = global_position-enemy.global_position
		to_me.y = 0
		# Outside the monster's 120° view cone: from behind it notices even later.
		if to_me.length() > 0.01 and forward.dot(to_me.normalized()) < 0.5:
			m *= 0.6
	return m

## blockable = false for blows that cannot be parried (a boss slam on the ground).
func receive_damage(amount: float, from: Vector3 = Vector3.ZERO, blockable: bool = true) -> void:
	if health <= 0:
		return
	if invulnerable > 0:
		# A blow that lands during the dodge window trains Acrobacia.
		if dodge_timer > 0 and amount > 0:
			game.on_dodged(amount)
		return
	var blocked: float = 0.0
	if blockable and from.length() > 0.01 and can_block():
		var toward: Vector3 = -from
		toward.y = 0
		if facing.dot(toward.normalized()) >= cos(deg_to_rad(70.0)):
			var reduction: float = game.sheet.block_reduction(game.inventory.equipped)
			var cost: float = game.sheet.block_cost(amount*reduction)
			if stamina >= cost:
				stamina -= cost
				blocked = amount*reduction
			else:
				stamina = 0
				game.message("Guarda quebrada: sem fôlego para segurar o golpe.",2)
	var rest: float = amount-blocked
	var absorbed: float = rest*game.sheet.armor_protection(game.inventory.armor)
	var taken: float = rest-absorbed
	game.on_hit_taken(blocked,absorbed)
	if blocked > 0:
		# A parried blow: no wound, a short recoil.
		health = maxf(0,health-taken)
		invulnerable = 0.35
		impulse = from.normalized()*0.8
		game.sound.play_at("hit",global_position,0.55)
		# Sparks where the guard met the blow, between the adventurer and the attacker.
		Vfx.burst(game,"faisca",Vfx.body_point(self,1.15)-from.normalized()*0.35)
		game.camera_impact(0.05)
		if health <= 0:
			die()
		return
	amount = taken
	health = maxf(0,health-amount)
	invulnerable = 0.7
	hurt_timer = 0.23
	attack_timer = 0
	attack_wait = 0
	dodge_lock = 0
	attack_buffer = 0
	dash_time = 0
	impulse = from.normalized()*1.8
	animate_action("hit",hurt_timer)
	game.sound.play_at("hurt",global_position,0.8)
	Vfx.burst(game,"sangue",Vfx.body_point(self)+Vfx.jitter(0.1),0.85)
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
	dodge_lock = 0
	hurt_timer = 0
	invulnerable = 0
	dash_time = 0
	resolved_serial = attack_serial

func die() -> void:
	health = 0
	attack_wait = 0
	attack_buffer = 0
	Visuals.play(animator,"die",false)
	game.end_run(false)
