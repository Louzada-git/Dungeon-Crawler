extends SceneTree
# Converts Quaternius Fantasy Props MegaKit models (CC0) into item models:
# origin at the centre of the base, largest side "size" metres, albedo texture
# down to "texture" pixels (PSX size) and no other maps. Exports .glb.
#   godot --headless --path . -s res://converter_itens.gd -- <out_dir> [ids...]
# Sources in p/mk/: the .gltf, .bin and T_*.png files of the pack (Exports/glTF).

const M := "res://p/mk/%s.gltf"

var jobs := [
	{"id": "cenoura", "src": M % "Carrot", "size": 0.20},
	{"id": "chave_mestra", "src": M % "Key_Metal", "size": 0.13},
	{"id": "mapa", "src": M % "Scroll_1", "size": 0.30},
	{"id": "calice", "src": M % "Chalice", "size": 0.20},
	{"id": "castical", "src": M % "CandleStick", "size": 0.28},
	{"id": "cerveja", "src": M % "Mug", "size": 0.14},
	{"id": "vinho", "src": M % "Bottle_1", "size": 0.30},
	{"id": "garrafada", "src": M % "Potion_2", "size": 0.20},
	{"id": "cha", "src": M % "Potion_4", "size": 0.18},
	{"id": "mel", "src": M % "Pot_1_Lid", "size": 0.14},
	{"id": "arnica", "src": M % "SmallBottle", "size": 0.12},
]

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var only: Array = OS.get_cmdline_user_args().slice(1)
	for job in jobs:
		if only.is_empty() or job["id"] in only:
			convert_job(job, out)
	quit()

func bounds(node: Node, space: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:
			continue
		var t := Transform3D.IDENTITY
		var walk: Node = m
		while walk != space and walk is Node3D:
			t = walk.transform * t
			walk = walk.get_parent()
		var b: AABB = t * m.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func convert_job(job: Dictionary, out: String) -> void:
	var holder := Node3D.new()
	holder.name = job["id"]
	var mover := Node3D.new()
	holder.add_child(mover)
	var inst: Node3D = load(job["src"]).instantiate()
	mover.add_child(inst)
	root.add_child(holder)
	var box := bounds(inst, holder)
	var s: float = float(job["size"]) / maxf(box.size.x, maxf(box.size.y, box.size.z))
	mover.scale = Vector3.ONE * s
	box = bounds(inst, holder)
	mover.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z)
	shrink_textures(holder, int(job.get("texture", 64)))
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: int = doc.append_from_scene(holder, state)
	if err == OK:
		err = doc.write_to_filesystem(state, "%s/%s.glb" % [out, job["id"]])
	print("CONVERTED|%s|%s|err=%d|size=%s" % [job["id"], job["src"].get_file(), err, bounds(inst, holder).size.snapped(Vector3.ONE * 0.001)])
	holder.free()

## Albedo down to "size" pixels on the largest side; the other maps go away.
func shrink_textures(node: Node, size: int) -> void:
	for m in node.find_children("*", "MeshInstance3D", true, false):
		for i in m.mesh.get_surface_count():
			var mat = m.get_active_material(i)
			if not mat is BaseMaterial3D:
				continue
			mat = mat.duplicate()
			if mat.albedo_texture != null:
				var img: Image = mat.albedo_texture.get_image()
				if img.is_compressed():
					img.decompress()
				var scale: float = float(size) / maxf(img.get_width(), img.get_height())
				if scale < 1.0:
					img.resize(maxi(1, int(img.get_width() * scale)), maxi(1, int(img.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
				mat.albedo_texture = ImageTexture.create_from_image(img)
			mat.normal_enabled = false
			mat.normal_texture = null
			mat.roughness_texture = null
			mat.metallic_texture = null
			mat.ao_enabled = false
			mat.ao_texture = null
			mat.metallic = 0.0
			mat.roughness = 1.0
			m.set_surface_override_material(i, mat)
