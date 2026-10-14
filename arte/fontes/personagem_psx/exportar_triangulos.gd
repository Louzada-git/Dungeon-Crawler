extends SceneTree
# Writes triangles (uv + rest-pose world position) of the skinned character to JSON.
func _initialize() -> void:
	run()
func run() -> void:
	await process_frame
	var n: Node3D = load("res://p/Character_16.fbx").instantiate()
	root.add_child(n)
	await process_frame
	var sk: Skeleton3D = n.find_children("*", "Skeleton3D", true, false)[0]
	var mi: MeshInstance3D = n.find_children("*", "MeshInstance3D", true, false)[0]
	var skin: Skin = mi.skin
	var bind_bone: Array = []
	for b in skin.get_bind_count():
		var idx: int = skin.get_bind_bone(b)
		if idx < 0:
			idx = sk.find_bone(skin.get_bind_name(b))
		bind_bone.append(idx)
	var arr: Array = mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var bones = arr[Mesh.ARRAY_BONES]
	var weights = arr[Mesh.ARRAY_WEIGHTS]
	var per: int = bones.size() / verts.size()
	var posed := PackedVector3Array()
	posed.resize(verts.size())
	for v in verts.size():
		var p := Vector3.ZERO
		for k in per:
			var w: float = weights[v * per + k]
			if w <= 0.0:
				continue
			var b: int = bones[v * per + k]
			var t: Transform3D = sk.global_transform * sk.get_bone_global_pose(bind_bone[b]) * skin.get_bind_pose(b)
			p += (t * verts[v]) * w
		posed[v] = p
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var tris: Array = []
	for i in range(0, idx.size(), 3):
		var t: Array = []
		for j in 3:
			var v: int = idx[i + j]
			t.append([uvs[v].x, uvs[v].y, posed[v].x, posed[v].y, posed[v].z])
		tris.append(t)
	var f := FileAccess.open("res://tris.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(tris))
	print("TRIS ", tris.size(), " verts ", verts.size(), " per ", per)
	quit()
