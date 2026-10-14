"""Recria o aventureiro com movimentos Mixamo no esqueleto original.

Executar da raiz do projeto:
blender --background --factory-startup --python arte/fontes/aplicar_mixamo.py
"""

from pathlib import Path
import bpy
import math
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "jogo/assets/originais/aventureiro.glb"
RAW = ROOT / "arte/fontes/mixamo"
OUTPUT = ROOT / "jogo/assets/originais/aventureiro_mixamo.glb"

MOTIONS = {
    "mixamo_stab": "sword and shield attack (4).fbx",
    "mixamo_attack": "sword and shield slash (3).fbx",
    "mixamo_hit": "sword and shield impact.fbx",
    "mixamo_die": "sword and shield death.fbx",
}

BONES = {
    "pelvis": "Hips",
    "spine": "Spine2",
    "neck": "Neck",
    "head": "Head",
}
for side in ("left", "right"):
    mix = side.title()
    BONES.update({
        f"arm-{side}": f"{mix}Arm",
        f"forearm-{side}": f"{mix}ForeArm",
        f"hand-{side}": f"{mix}Hand",
        f"thigh-{side}": f"{mix}UpLeg",
        f"shin-{side}": f"{mix}Leg",
        f"foot-{side}": f"{mix}Foot",
    })

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
target = bpy.data.objects["Aventureiro"]
mesh = next(o for o in bpy.data.objects if o.type == "MESH")
bpy.context.scene.render.fps = 24
ordered_bones = sorted(BONES, key=lambda name: len(target.pose.bones[name].parent_recursive))

def aim_arm(side, goal, frame):
    """Bake a two-bone reach onto the Mixamo body movement for a polearm grip."""
    bpy.context.view_layer.update()
    upper = target.pose.bones['arm-'+side]
    lower = target.pose.bones['forearm-'+side]
    shoulder = upper.head.copy()
    direction = goal-shoulder
    a, b = upper.bone.length, lower.bone.length
    distance = max(abs(a-b)+0.001, min(direction.length, a+b-0.005))
    direction.normalize()
    along = (a*a-b*b+distance*distance)/(2*distance)
    pole = Vector((-1 if side == 'right' else 1, 0.5, -0.3))
    pole = (pole-direction*pole.dot(direction)).normalized()
    elbow = shoulder+direction*along+pole*math.sqrt(max(0,a*a-along*along))
    wrist = shoulder+direction*distance
    for bone, vector in [(upper,elbow-shoulder),(lower,wrist-elbow)]:
        matrix = vector.to_track_quat('Y','Z').to_matrix().to_4x4()
        matrix.translation = bone.head
        bone.matrix = matrix
        bpy.context.view_layer.update()
        bone.keyframe_insert(data_path='rotation_quaternion',frame=frame,group=bone.name)

for action_name, filename in MOTIONS.items():
    before_objects = set(bpy.data.objects)
    before_actions = set(bpy.data.actions)
    bpy.ops.import_scene.fbx(filepath=str(RAW / filename))
    imported = set(bpy.data.objects) - before_objects
    source = next(o for o in imported if o.type == "ARMATURE")
    source_action = source.animation_data.action
    start, end = (round(v) for v in source_action.frame_range)
    action = bpy.data.actions.new(action_name)
    action.use_fake_user = True
    target.animation_data.action = action
    for frame in range(start, end + 1):
        bpy.context.scene.frame_set(frame)
        posed_rotations = {}
        for bone_name in ordered_bones:
            source_name = BONES[bone_name]
            src = source.pose.bones["mixamorig:" + source_name]
            dst = target.pose.bones[bone_name]
            desired_world = (source.matrix_world @ src.matrix).to_quaternion()
            desired = target.matrix_world.to_quaternion().inverted() @ desired_world
            parent = dst.parent
            rest = dst.bone.matrix_local.to_quaternion()
            if parent:
                parent_rest = parent.bone.matrix_local.to_quaternion()
                parent_pose = posed_rotations.get(parent.name, parent_rest)
                rotation_before_basis = parent_pose @ parent_rest.inverted() @ rest
            else:
                rotation_before_basis = rest
            dst.rotation_mode = "QUATERNION"
            dst.rotation_quaternion = rotation_before_basis.inverted() @ desired
            posed_rotations[bone_name] = desired
            dst.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=bone_name)
        # The game owns horizontal displacement. Keep the foot cycle's vertical bob.
        src_hips = source.pose.bones["mixamorig:Hips"]
        rest_height = (source.matrix_world @ src_hips.bone.head_local).z
        posed_height = (source.matrix_world @ src_hips.matrix.translation).z
        pelvis = target.pose.bones["pelvis"]
        pelvis.location = (0, 0, max(-0.15, min(0.15, posed_height - rest_height)))
        pelvis.keyframe_insert(data_path="location", frame=frame, group="pelvis")
        if action_name == 'mixamo_stab':
            phase = (frame-start)/(end-start)
            # Retract, drive straight forward at the damage window, then recover.
            keys = [(0,0),(.18,-.25),(.39,1),(.48,1),(.78,0),(1,0)]
            extension = 0.0
            for (t0,v0),(t1,v1) in zip(keys,keys[1:]):
                if phase <= t1:
                    t = max(0,(phase-t0)/(t1-t0))
                    extension = v0+(v1-v0)*t*t*(3-2*t)
                    break
            aim_arm('right',Vector((-.12,-.10-.34*extension,1.24)),frame)
            aim_arm('left',Vector((-.12,-.32-.18*extension,1.24)),frame)

    # Remove the FBX skeleton and its imported action, leaving only our character.
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)
    for other in set(bpy.data.actions) - before_actions:
        if other != action:
            bpy.data.actions.remove(other)
    print(f"RETARGET {action_name}: {end - start + 1} frames")

target.animation_data.action = bpy.data.actions["idle"]
bpy.context.scene.frame_set(1)
bpy.ops.object.select_all(action="DESELECT")
target.select_set(True)
mesh.select_set(True)
bpy.context.view_layer.objects.active = target
bpy.ops.export_scene.gltf(
    filepath=str(OUTPUT),
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_frame_range=False,
    export_optimize_animation_size=True,
    export_yup=True,
)
print(f"WROTE {OUTPUT}")
