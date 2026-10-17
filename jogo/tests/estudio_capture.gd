extends SceneTree
# Every frame of every animation with every weapon, for review: a bare studio
# (no dungeon), a row of copies of the adventurer, each posed at the next frame
# (30 per second, as the animations are baked), seen from the side and from the
# front. Saves work/estudio/<weapon>/<animation>/<view>_<n>.png; compose them
# with tools/estudio_folhas.py.
#   xvfb-run godot --path . --rendering-driver opengl3 -s res://tests/estudio_capture.gd [-- ids... | --anims=a,b]
# Without ids: the fists and every weapon.
const FPS := 30.0
const WIDTH := 18.0
var out: String
var view: SubViewport
var world: Node3D
var cam: Camera3D
var copies: Array = []
var holder := DungeonPlayer.new()

func _initialize() -> void:
	out = ProjectSettings.globalize_path("res://../work/estudio")
	DirAccess.make_dir_recursive_absolute(out)
	run()

func frames(n: int) -> void:
	for i in n:
		await process_frame

func setup() -> void:
	# A viewport of its own: the window keeps the game's aspect, the sheets are wide.
	view = SubViewport.new()
	view.size = Vector2i(2400, 360)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	world = Node3D.new()
	view.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.21, 0.23)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.62, 0.62, 0.62)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.9
	world.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 20)
	floor_mesh.mesh = plane
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.36, 0.35, 0.32))
	img.set_pixel(1, 1, Color(0.36, 0.35, 0.32))
	img.set_pixel(1, 0, Color(0.30, 0.29, 0.27))
	img.set_pixel(0, 1, Color(0.30, 0.29, 0.27))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_scale = Vector3(40, 10, 1)
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(cam)
	cam.current = true

## Length of a weapon's model (to space the copies).
func reach_of(id: String) -> float:
	if id == "":
		return 0.8
	var e: Vector2 = Hitbox.extent(id) * holder.hand_scale(id, Items.info(id)).y
	return e.y - e.x

## A copy of the adventurer holding `id`.
func make_copy(id: String) -> Dictionary:
	var m: Node3D = Visuals.model(DungeonPlayer.MODEL, 1.0)
	world.add_child(m)
	var ap: AnimationPlayer = Visuals.animation(m)
	ap.active = false
	var sk: Skeleton3D = Visuals.skeleton(m)
	var weapon: Node3D = null
	if id != "":
		var data: Dictionary = Items.info(id)
		var entry: Array = DungeonPlayer.MOUNTS["hand-left" if str(data.get("mao", "direita")) == "esquerda" else "hand-right"]
		var at := BoneAttachment3D.new()
		sk.add_child(at)
		at.bone_name = entry[0]
		var grip := Node3D.new()
		grip.transform = Transform3D(Basis(entry[1]), entry[2])
		at.add_child(grip)
		weapon = Visuals.item_model(id)
		grip.add_child(weapon)
		weapon.position = Vector3(0, 0.035, 0)
		weapon.rotation_degrees = holder.rest_rotation(data)
		weapon.scale = holder.hand_scale(id, data)
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0022
	label.font_size = 20
	label.outline_size = 6
	label.modulate = Color(1, 0.92, 0.5)
	m.add_child(label)
	label.position = Vector3(0, 2.15, 0)
	return {"model": m, "anim": ap, "sk": sk, "weapon": weapon, "label": label}

func clear_copies() -> void:
	for c in copies:
		c["model"].queue_free()
	copies.clear()

## The animations a weapon is seen in: standing, moving, guard, crouch, block,
## dodge, damage, death and its attack, in the variant for how it is carried.
func animations_for(id: String, ap: AnimationPlayer) -> Array:
	var data: Dictionary = Items.info(id) if id != "" else CharacterSheet.base_stats("")
	var suffix: String = "_livre" if id == "" else ("_" + str(data["porte"]) if data.has("porte") else "")
	var names: Array = []
	var base: Array = ["idle", "walk", "run", "guard", "furtivo", "furtivo_andar"]
	if str(data.get("style", "")) != "shoot":
		base.append("bloqueio")
	for n in base:
		names.append(n + suffix if ap.has_animation(n + suffix) else n)
	names.append_array(["dodge", "hit", "die"])
	names.append(DungeonPlayer.attack_animation_for(data, ap))
	return names

func run() -> void:
	await frames(3)
	setup()
	var args: Array = OS.get_cmdline_user_args()
	var only_anims: Array = []
	var ids: Array = []
	for a in args:
		if str(a).begins_with("--anims="):
			only_anims = str(a).substr(8).split(",")
		else:
			ids.append(str(a) if str(a) != "punhos" else "")
	if ids.is_empty():
		ids.append("")
		for id in Items.DATA:
			if Items.DATA[id].has("style"):
				ids.append(id)
	for id in ids:
		var spacing: float = maxf(2.2, reach_of(id) * 1.05 + 1.0)
		var count: int = maxi(3, floori(WIDTH / spacing))
		var tall: float = maxf(2.6, reach_of(id) + 1.3)
		clear_copies()
		for i in count:
			copies.append(make_copy(id))
		await frames(2)
		var names: Array = animations_for(id, copies[0]["anim"])
		var meta_dir: String = "%s/%s" % [out, id if id != "" else "punhos"]
		DirAccess.make_dir_recursive_absolute(meta_dir)
		var meta := FileAccess.open(meta_dir + "/meta.json", FileAccess.WRITE)
		meta.store_string(JSON.stringify({"count": count, "spacing": spacing, "tall": tall, "width": view.size.x, "height": view.size.y, "animations": names}))
		meta.close()
		var data: Dictionary = Items.info(id) if id != "" else {}
		for name in names:
			if not only_anims.is_empty() and not name in only_anims:
				continue
			var length: float = copies[0]["anim"].get_animation(name).length
			var total: int = maxi(1, ceili(length * FPS - 0.001)) + 1
			var dir: String = "%s/%s/%s" % [out, id if id != "" else "punhos", name]
			DirAccess.make_dir_recursive_absolute(dir)
			var attack: bool = name == names[-1]
			for side_name in ["lado", "frente"]:
				var batch: int = 0
				var f: int = 0
				while f < total:
					for i in count:
						var c: Dictionary = copies[i]
						var frame: int = f + i
						var m: Node3D = c["model"]
						m.visible = frame < total
						m.position = Vector3((i - (count - 1) * 0.5) * spacing, 0, 0)
						m.rotation.y = atan2(1.0, 0.0) if side_name == "lado" else atan2(1.0, 1.0)
						if frame >= total:
							continue
						var t: float = minf(length, frame / FPS)
						Hitbox.pose_at(c["anim"], c["sk"], name, t)
						c["label"].text = "%d · %.2fs" % [frame, t]
						var w: Node3D = c["weapon"]
						if w != null and attack and data.get("alinhar_ao_golpe", false):
							var facing := Vector3(1, 0, 0) if side_name == "lado" else Vector3(1, 0, 1).normalized()
							DungeonPlayer.aim_held(w, c["sk"], data, facing, holder.hand_scale(id, data))
						elif w != null:
							w.rotation_degrees = holder.rest_rotation(data)
					cam.size = tall
					cam.global_position = Vector3(0, tall * 0.42, 12)
					cam.rotation = Vector3.ZERO
					await frames(2)
					await RenderingServer.frame_post_draw
					self.view.get_texture().get_image().save_png("%s/%s_%02d.png" % [dir, side_name, batch])
					batch += 1
					f += count
			print("FILM %s %s %d frames" % [id if id != "" else "punhos", name, total])
	clear_copies()
	quit()
