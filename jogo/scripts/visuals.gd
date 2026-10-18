extends RefCounted
class_name Visuals

static var cache: Dictionary = {}
static var material_cache: Dictionary = {}

## A model of assets/originais/<id>.glb, scaled by `factor` (scenes cached).
static func model(id: String, factor: float = 1.0) -> Node3D:
	var path: String = "res://assets/originais/%s.glb" % id
	var first: bool = not cache.has(path)
	if first:
		cache[path] = load(path)
	var instance: Node3D = cache[path].instantiate()
	if first:
		_set_loops(instance)
	instance.scale = Vector3.ONE * factor
	return instance

static func material(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if color.a < 1:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

static func ring(radius: float, color: Color, width: float = 0.055) -> MeshInstance3D:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 64:
		var a: float = TAU * i / 64.0
		var b: float = TAU * (i + 1) / 64.0
		var p = Vector3(sin(a),0,cos(a))
		var q = Vector3(sin(b),0,cos(b))
		for v in [p * radius, q * radius, p * (radius-width), q * radius, q * (radius-width), p * (radius-width)]:
			mesh.surface_add_vertex(v)
	mesh.surface_end()
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material(color, true)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

static func animation(root: Node) -> AnimationPlayer:
	for child in root.get_children():
		if child is AnimationPlayer:
			return child
		var found = animation(child)
		if found:
			return found
	return null

static func skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root
	for child in root.get_children():
		var found = skeleton(child)
		if found:
			return found
	return null

## Animations that loop: standing, moving, guard, crouch, block and talking,
## with their carry variants (idle_duas, walk_haste...). Every other one plays
## once. Set once per model when it is first loaded: the animations are shared
## by every copy of the model.
const LOOPING := ["idle", "walk", "run", "guard", "furtivo", "furtivo_andar", "bloqueio", "falar"]
const CARRY_SUFFIXES := ["_livre", "_duas", "_haste", "_besta", "_arco"]

static func loops(anim_name: String) -> bool:
	for suffix in CARRY_SUFFIXES:
		if anim_name.ends_with(suffix):
			return anim_name.trim_suffix(suffix) in LOOPING
	return anim_name in LOOPING

static func _set_loops(root: Node) -> void:
	var anim: AnimationPlayer = animation(root)
	if anim == null:
		return
	for anim_name in anim.get_animation_list():
		anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR if loops(anim_name) else Animation.LOOP_NONE

## Plays an animation if it is not already playing, at `speed` (the walk's pace).
static func play(anim: AnimationPlayer, anim_name: String, speed: float = 1.0) -> void:
	if anim == null or not anim.has_animation(anim_name):
		return
	anim.speed_scale = speed
	if anim.current_animation != anim_name or not anim.is_playing():
		anim.play(anim_name, 0.12)

static func collider(parent: Node3D, size: Vector3, pos: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	body.position = pos
	return body

static func tint(root: Node, color: Color) -> void:
	if root is MeshInstance3D:
		for index in root.mesh.get_surface_count():
			var original = root.get_active_material(index)
			if original is StandardMaterial3D:
				var key = str(original.get_instance_id())+str(color)
				if not material_cache.has(key):
					var tinted = original.duplicate()
					tinted.albedo_color *= color
					tinted.roughness = 0.95
					material_cache[key] = tinted
				root.set_surface_override_material(index,material_cache[key])
	for child in root.get_children():
		tint(child,color)

static func attack_arc(radius: float, color: Color, half_angle: float = 1.2, width: float = 0.25) -> MeshInstance3D:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 32:
		var a: float = -half_angle + 2.0*half_angle*i/32.0
		var b: float = -half_angle + 2.0*half_angle*(i+1)/32.0
		var p = Vector3(sin(a),0,cos(a))
		var q = Vector3(sin(b),0,cos(b))
		for v in [p*radius,q*radius,p*(radius-width),q*radius,q*(radius-width),p*(radius-width)]:
			mesh.surface_add_vertex(v)
	mesh.surface_end()
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material(color,true)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

## Model of an item, in this order: assets/armas/<id>.glb made for it,
## the provisional block model from its data ("blocks"), or the shared model
## named in "model" (tinted by "tint"). Grip at the origin, tip toward +Y.
static func item_model(id: String) -> Node3D:
	var data: Dictionary = Items.DATA.get(id,{})
	var custom := custom_model_path(id)
	if custom != "":
		if not cache.has(custom):
			cache[custom] = load(custom)
		var made: Node3D = cache[custom].instantiate()
		if custom.begins_with("res://assets/itens/"):
			use_vertex_colors(made)
		# "base" + "escala_modelo": another item's model, bigger or smaller (longbow from the bow).
		made.scale = Vector3.ONE * float(data.get("escala_modelo",1.0))
		if str(data.get("tint","")) != "":
			tint(made,Color(data["tint"]))
		return made
	if data.has("blocks"):
		return blocks(data["blocks"])
	var node := model(str(data.get("model","moeda")))
	if str(data.get("tint","")) != "":
		tint(node,Color(data["tint"]))
	return node

## Model made for the item: assets/armas/<id>.glb (weapons, ammo),
## assets/itens/<id>.glb (other items), or the model of its "base" item.
static func custom_model_path(id: String) -> String:
	for path in ["res://assets/armas/%s.glb" % id,"res://assets/itens/%s.glb" % id]:
		if ResourceLoader.exists(path):
			return path
	var base: String = str(Items.DATA.get(id,{}).get("base",""))
	if base != "" and base != id:
		return custom_model_path(base)
	return ""

## Props of the Quaternius MegaKit get their colour from the vertices (the
## texture is a grey trim sheet). glTF import leaves that off; turn it on.
static func use_vertex_colors(root: Node) -> void:
	for m in root.find_children("*","MeshInstance3D",true,false):
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var colors = m.mesh.surface_get_arrays(i)[Mesh.ARRAY_COLOR]
			var mat = m.get_active_material(i)
			if colors != null and colors.size() > 0 and mat is BaseMaterial3D and not mat.vertex_color_use_as_albedo:
				mat.vertex_color_use_as_albedo = true

static func has_custom_model(id: String) -> bool:
	return custom_model_path(id) != ""

## Provisional model made of boxes: [{size:[x,y,z], pos:[x,y,z], color, rot (degrees around Z)}].
static func blocks(list: Array) -> Node3D:
	var root := Node3D.new()
	root.name = "ModeloDeBlocos"
	root.set_meta("placeholder",true)
	for i in list.size():
		var entry: Dictionary = list[i]
		var mesh := BoxMesh.new()
		mesh.size = Vector3(entry["size"][0],entry["size"][1],entry["size"][2])
		var part := MeshInstance3D.new()
		part.name = "bloco_%d" % i
		part.mesh = mesh
		var key := "bloco_"+str(entry.get("color","aaaaaa"))
		if not material_cache.has(key):
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(str(entry.get("color","aaaaaa")))
			mat.roughness = 0.7
			mat.metallic = 0.15
			material_cache[key] = mat
		part.material_override = material_cache[key]
		part.position = Vector3(entry["pos"][0],entry["pos"][1],entry["pos"][2])
		part.rotation_degrees.z = float(entry.get("rot",0.0))
		root.add_child(part)
	return root
