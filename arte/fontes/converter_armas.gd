extends SceneTree
# Converts chosen pack models into the game's weapon convention and exports .glb:
# origin at the grip, +Y towards the tip, blade width on X, thickness on Z, metres.
#   godot --headless --path . -s res://convert.gd -- <out_dir>
# "y" / "x": target axis expressed in source coordinates. Z = X × Y (no mirroring).
# "grip": grip height as a fraction of the length from the bottom end.
# "thick": extra scale on X/Z (keeps thin ammunition visible after shrinking).
# "grip_x": "max" takes the handle centre from the outermost vertices (bow wood, not string).
# Without "y" (Polyy models, posed at an angle): the main axis of the vertices
# (principal component) becomes +Y and the second one +X; "flip": true turns it
# upside down when the tip ends up at the bottom.
# "texture": largest side of the albedo texture in pixels (Polyy models: 128, PSX
# size); normal, roughness, metal and occlusion maps are dropped.

const K := "res://p/kickin/Low Poly Weapon Pack - by Kickin It Studios.fbx_%s.fbx"
const R := "res://p/rpg/%s.glb"
const P := "res://p/polyy/%s_low.glb"

var jobs := [
	{"id": "adaga", "src": R % "Dagger_06", "length": 0.42, "grip": 0.16},
	{"id": "katana", "src": K % "Offset_Sword", "y": Vector3(0, 0, -1), "x": Vector3(1, 0, 0), "length": 1.00, "grip": 0.13},
	{"id": "montante", "src": R % "Long_Sword_07", "length": 1.60, "grip": 0.10},
	{"id": "machado", "src": R % "Axe_05", "x": Vector3(-1, 0, 0), "length": 0.78, "grip": 0.24},
	{"id": "maca", "src": R % "Mace_07", "length": 0.79, "grip": 0.25},
	{"id": "martelo", "src": R % "Hammer_07", "length": 1.27, "grip": 0.20, "thick": 0.65},
	{"id": "spear", "src": R % "Spear_05", "length": 2.60, "grip": 0.27, "thick": 0.6},
	{"id": "lanca_longa", "src": R % "Spear_07", "length": 3.10, "grip": 0.26, "thick": 0.55},
	{"id": "alabarda", "src": K % "Halberd", "y": Vector3(0, 0, -1), "x": Vector3(-1, 0, 0), "length": 2.62, "grip": 0.23},
	{"id": "arco", "src": K % "Bow", "y": Vector3(1, 0, 0), "x": Vector3(0, 0, -1), "length": 1.16, "grip": 0.5, "grip_x": "max"},
	{"id": "besta", "src": K % "Crossbow", "y": Vector3(0, 0, -1), "x": Vector3(1, 0, 0), "length": 0.79, "grip": 0.30},
	{"id": "flecha", "src": K % "Broadhead_Arrow", "y": Vector3(0, 0, -1), "x": Vector3(1, 0, 0), "length": 0.73, "grip": 0.0, "thick": 1.2},
	{"id": "virote", "src": K % "Bullet_Arrow", "y": Vector3(0, 0, -1), "x": Vector3(1, 0, 0), "length": 0.45, "grip": 0.0, "thick": 1.8},
	# 16/10/2026: the 50 new items.
	{"id": "espada_curta", "src": R % "Short_Sword_03", "length": 0.78, "grip": 0.15},
	{"id": "faca", "src": R % "Dagger_02", "length": 0.36, "grip": 0.20},
	{"id": "espada_larga", "src": P % "knights_longsword", "length": 1.05, "grip": 0.12, "flip": true},
	{"id": "florete", "src": P % "duelists_rapier", "length": 1.05, "grip": 0.11},
	{"id": "alfanje", "src": P % "falchion", "length": 0.90, "grip": 0.14},
	{"id": "espadao", "src": P % "highland_claymore", "length": 1.55, "grip": 0.12},
	{"id": "punhal", "src": P % "rogues_dagger", "length": 0.40, "grip": 0.18},
	{"id": "maca_cravos", "src": P % "spiked_mace", "length": 0.80, "grip": 0.22},
	{"id": "estrela", "src": P % "morning_star", "length": 0.95, "grip": 0.20},
	{"id": "malho", "src": P % "giants_maul", "length": 1.45, "grip": 0.20},
	{"id": "martelo_guerra", "src": P % "warhammer", "length": 1.00, "grip": 0.22},
	{"id": "machado_duplo", "src": P % "twin_moon_battle_axe", "length": 1.30, "grip": 0.20},
	{"id": "picareta", "src": P % "war_pick", "length": 0.95, "grip": 0.22},
	{"id": "tridente", "src": P % "tidal_trident", "length": 2.30, "grip": 0.30},
	{"id": "foice", "src": P % "reapers_scythe", "length": 1.90, "grip": 0.25},
]

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var only: Array = OS.get_cmdline_user_args().slice(1)
	for job in jobs:
		if not only.is_empty() and not job["id"] in only:
			continue
		convert_job(job, out)
	quit()

func vertices(node: Node, space: Node3D) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for m in node.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:
			continue
		var t := Transform3D.IDENTITY
		var walk: Node = m
		while walk != space and walk is Node3D:
			t = walk.transform * t
			walk = walk.get_parent()
		for s in m.mesh.get_surface_count():
			for v in m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				pts.append(t * v)
	return pts

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
			mat.emission_enabled = false
			mat.metallic = 0.0
			mat.roughness = 1.0
			m.set_surface_override_material(i, mat)

## Main and second axes of a point cloud (principal components, power iteration).
func principal_axes(pts: PackedVector3Array) -> Array:
	var mean := Vector3.ZERO
	for p in pts:
		mean += p
	mean /= pts.size()
	var cov := [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
	for p in pts:
		var d: Vector3 = p - mean
		for i in 3:
			for j in 3:
				cov[i][j] += d[i] * d[j]
	var first: Vector3 = _dominant(cov, Vector3(0.3, 1.0, 0.2))
	var deflated := [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
	var lam: float = _apply(cov, first).dot(first)
	for i in 3:
		for j in 3:
			deflated[i][j] = cov[i][j] - lam * first[i] * first[j]
	var second: Vector3 = _dominant(deflated, Vector3(1.0, 0.1, 0.3).cross(first).normalized())
	second = (second - first * second.dot(first)).normalized()
	return [first, second]

func _apply(m: Array, v: Vector3) -> Vector3:
	return Vector3(m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z, m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z, m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z)

func _dominant(m: Array, start: Vector3) -> Vector3:
	var v: Vector3 = start.normalized()
	for i in 60:
		var n: Vector3 = _apply(m, v)
		if n.length() < 1e-9:
			break
		v = n.normalized()
	return v

func convert_job(job: Dictionary, out: String) -> void:
	var holder := Node3D.new()
	holder.name = job["id"]
	var mover := Node3D.new()
	mover.name = "empunhadura"
	var scaler := Node3D.new()
	scaler.name = "escala"
	var pivot := Node3D.new()
	pivot.name = "orientacao"
	holder.add_child(mover)
	mover.add_child(scaler)
	scaler.add_child(pivot)
	var inst: Node3D = load(job["src"]).instantiate()
	pivot.add_child(inst)
	root.add_child(holder)
	var y: Vector3 = job.get("y", Vector3.UP)
	var x: Vector3 = job.get("x", Vector3.RIGHT)
	if not job.has("y") and job["src"].begins_with(P.get_slice("%", 0)):
		var axes: Array = principal_axes(vertices(inst, holder))
		y = axes[0]
		x = axes[1]
	if job.get("flip", false):
		y = -y
		x = -x
	var z: Vector3 = x.cross(y)
	pivot.basis = Basis(x, y, z).transposed()
	var pts := vertices(inst, holder)
	var lo := pts[0]
	var hi := pts[0]
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var s: float = float(job["length"]) / (hi.y - lo.y)
	var thick: float = float(job.get("thick", 1.0))
	scaler.scale = Vector3(s * thick, s, s * thick)
	pts = vertices(inst, holder)
	lo = pts[0]
	hi = pts[0]
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var gy: float = lo.y + float(job["grip"]) * (hi.y - lo.y)
	var band: float = maxf(0.02, 0.03 * (hi.y - lo.y))
	var sum := Vector3.ZERO
	var n: int = 0
	var max_x: float = -INF
	for p in pts:
		if absf(p.y - gy) <= band:
			sum += p
			n += 1
			max_x = maxf(max_x, p.x)
	var c: Vector3 = sum / n if n > 0 else (lo + hi) * 0.5
	if job.get("grip_x", "") == "max" and n > 0:
		c.x = max_x - 0.015
	mover.position = -Vector3(c.x, gy, c.z)
	pts = vertices(inst, holder)
	lo = pts[0]
	hi = pts[0]
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var texture_size: int = int(job.get("texture", 128 if job["src"].begins_with(P.get_slice("%", 0)) else 0))
	if texture_size > 0:
		shrink_textures(holder, texture_size)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: int = doc.append_from_scene(holder, state)
	if err == OK:
		err = doc.write_to_filesystem(state, "%s/%s.glb" % [out, job["id"]])
	print("CONVERTED|%s|%s|err=%d|size=%s|min=%s|max=%s|grip_points=%d" % [job["id"], job["src"].get_file(), err, (hi - lo).snapped(Vector3.ONE * 0.001), lo.snapped(Vector3.ONE * 0.001), hi.snapped(Vector3.ONE * 0.001), n])
	holder.free()
