extends SceneTree
# Converts chosen pack models into the game's weapon convention and exports .glb:
# origin at the grip, +Y towards the tip, blade width on X, thickness on Z, metres.
#   godot --headless --path . -s res://convert.gd -- <out_dir>
# "y" / "x": target axis expressed in source coordinates. Z = X × Y (no mirroring).
# "grip": grip height as a fraction of the length from the bottom end.
# "thick": extra scale on X/Z (keeps thin ammunition visible after shrinking).
# "grip_x": "max" takes the handle centre from the outermost vertices (bow wood, not string).

const K := "res://p/kickin/Low Poly Weapon Pack - by Kickin It Studios.fbx_%s.fbx"
const R := "res://p/rpg/%s.glb"

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
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: int = doc.append_from_scene(holder, state)
	if err == OK:
		err = doc.write_to_filesystem(state, "%s/%s.glb" % [out, job["id"]])
	print("CONVERTED|%s|%s|err=%d|size=%s|min=%s|max=%s|grip_points=%d" % [job["id"], job["src"].get_file(), err, (hi - lo).snapped(Vector3.ONE * 0.001), lo.snapped(Vector3.ONE * 0.001), hi.snapped(Vector3.ONE * 0.001), n])
	holder.free()
