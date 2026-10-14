extends SceneTree
# Moves the adventurer's animations (17-bone own rig) onto the PSX character
# (Mixamo rig) and exports one .glb with mesh, repainted texture and animations.
#   godot --headless --path . -s res://bake.gd -- <out.glb>
# Method: for each mapped bone, the rotation the source bone makes away from its
# rest pose (in world space) is applied to the target bone's rest pose; hips
# translation follows the pelvis, scaled by the height ratio.

const MAP := {
	"mixamorig_Hips": "pelvis",
	"mixamorig_Spine": "spine",
	"mixamorig_Neck": "neck",
	"mixamorig_Head": "head",
	"mixamorig_LeftArm": "arm-left",
	"mixamorig_LeftForeArm": "forearm-left",
	"mixamorig_LeftHand": "hand-left",
	"mixamorig_RightArm": "arm-right",
	"mixamorig_RightForeArm": "forearm-right",
	"mixamorig_RightHand": "hand-right",
	"mixamorig_LeftUpLeg": "thigh-left",
	"mixamorig_LeftLeg": "shin-left",
	"mixamorig_LeftFoot": "foot-left",
	"mixamorig_RightUpLeg": "thigh-right",
	"mixamorig_RightLeg": "shin-right",
	"mixamorig_RightFoot": "foot-right",
}
## Attachment points the game uses: old bone -> new bone.
const MOUNTS := {"hand-right": "mixamorig_RightHand", "hand-left": "mixamorig_LeftHand", "spine": "mixamorig_Spine"}
const FPS := 30.0

func _initialize() -> void:
	run()

func world_rest(sk: Skeleton3D, b: int) -> Transform3D:
	return sk.global_transform * sk.get_bone_global_rest(b)

func run() -> void:
	await process_frame
	var out: String = OS.get_cmdline_user_args()[0]
	var src: Node3D = load("res://p/aventureiro_mixamo.glb").instantiate()
	root.add_child(src)
	var dst: Node3D = load("res://p/Character_16.fbx").instantiate()
	dst.name = "AventureiroPSX"
	root.add_child(dst)
	await process_frame
	var sk_s: Skeleton3D = src.find_children("*", "Skeleton3D", true, false)[0]
	var ap_s: AnimationPlayer = src.find_children("*", "AnimationPlayer", true, false)[0]
	var sk_t: Skeleton3D = dst.find_children("*", "Skeleton3D", true, false)[0]
	for old in dst.find_children("*", "AnimationPlayer", true, false):
		old.get_parent().remove_child(old)
		old.free()
	# Height ratio for the hips translation.
	var pelvis: int = sk_s.find_bone("pelvis")
	var hips: int = sk_t.find_bone("mixamorig_Hips")
	var k: float = world_rest(sk_t, hips).origin.y / world_rest(sk_s, pelvis).origin.y
	# Target bones in parent-first order (indices are already parent-first in both rigs).
	var lib := AnimationLibrary.new()
	var skel_path: String = str(dst.get_path_to(sk_t))
	for name in ap_s.get_animation_list():
		var anim_s: Animation = ap_s.get_animation(name)
		var anim := Animation.new()
		anim.length = anim_s.length
		anim.loop_mode = anim_s.loop_mode
		var tracks: Dictionary = {}
		for bone_name in MAP:
			var t: int = anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(t, "%s:%s" % [skel_path, bone_name])
			tracks[bone_name] = t
		var pos_track: int = anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(pos_track, "%s:mixamorig_Hips" % skel_path)
		var frames: int = maxi(1, ceili(anim_s.length * FPS))
		ap_s.play(name)
		for f in frames + 1:
			var time: float = minf(f / FPS, anim_s.length)
			ap_s.seek(time, true)
			sk_s.force_update_all_bone_transforms()
			var world_t: Array = []
			world_t.resize(sk_t.get_bone_count())
			for b in sk_t.get_bone_count():
				var bname: String = sk_t.get_bone_name(b)
				var parent: int = sk_t.get_bone_parent(b)
				var parent_world: Transform3D = sk_t.global_transform if parent < 0 else world_t[parent]
				var rest_local: Transform3D = sk_t.get_bone_rest(b)
				if MAP.has(bname):
					var sb: int = sk_s.find_bone(MAP[bname])
					var pose_w: Transform3D = sk_s.global_transform * sk_s.get_bone_global_pose(sb)
					var rest_w: Transform3D = world_rest(sk_s, sb)
					var delta: Basis = pose_w.basis.orthonormalized() * rest_w.basis.orthonormalized().inverse()
					var target_basis: Basis = delta * world_rest(sk_t, b).basis.orthonormalized()
					var origin: Vector3 = (parent_world * rest_local).origin
					if b == hips:
						origin = world_rest(sk_t, hips).origin + (pose_w.origin - rest_w.origin) * k
					world_t[b] = Transform3D(target_basis, origin)
					var local_basis: Basis = parent_world.basis.orthonormalized().inverse() * target_basis
					anim.rotation_track_insert_key(tracks[bname], time, local_basis.get_rotation_quaternion())
					if b == hips:
						anim.position_track_insert_key(pos_track, time, parent_world.affine_inverse() * origin)
				else:
					world_t[b] = parent_world * rest_local
		lib.add_animation(name, anim)
		print("BAKED ", name, " frames=", frames + 1, " length=", anim_s.length)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	dst.add_child(player)
	player.owner = dst
	player.add_animation_library("", lib)
	# Repainted texture.
	var mat := StandardMaterial3D.new()
	mat.resource_name = "aventureiro_psx"
	mat.albedo_texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://p/aventureiro_psx.png")))
	mat.roughness = 0.95
	for m in dst.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			m.mesh.surface_set_material(s, mat)
	# Mount corrections: where the old bones sat, seen from the new bones (rest pose).
	for old_name in MOUNTS:
		var c: Transform3D = world_rest(sk_t, sk_t.find_bone(MOUNTS[old_name])).affine_inverse() * world_rest(sk_s, sk_s.find_bone(old_name))
		var q: Quaternion = c.basis.get_rotation_quaternion()
		print("MOUNT|%s|%s|%s|%s" % [old_name, MOUNTS[old_name], var_to_str(q), var_to_str(c.origin)])
	for n in dst.find_children("*", "", true, false):
		if n.owner == null and n != dst:
			n.owner = dst
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: int = doc.append_from_scene(dst, state)
	if err == OK:
		err = doc.write_to_filesystem(state, out)
	print("EXPORT err=", err, " -> ", out)
	quit()
