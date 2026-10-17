extends SceneTree
# Builds the game's characters on the Mixamo rig of the Characters PSX pack
# (Elbolilloduro, CC0): mesh, texture and the animations the game uses.
#   godot --headless --path . -s res://personagens.gd -- <out_dir> [ids...]
# Animation sources: the Universal Animation Library (Quaternius, CC0; Unreal
# mannequin bone names), the Mixamo files of ../mixamo/ (same rig as the
# characters), and poses written below for the attacks the library lacks.
# Method: first the target is put in the source's reference pose (each limb
# bone turned to point where the source bone points in its T-pose; the
# characters' own rest has the arms down). Then each mapped bone takes the
# rotation its source bone makes away from the reference, in world space, on
# top of that matched pose; the hips move like the source pelvis, scaled by hip height.

const FPS := 30.0
const UAL := "res://p/ual/UAL1_Standard.glb"
const MIXAMO := "res://p/mixamo/%s.fbx"

const UAL_MAP := {
	"mixamorig_Hips": "pelvis", "mixamorig_Spine": "spine_01", "mixamorig_Spine1": "spine_02", "mixamorig_Spine2": "spine_03",
	"mixamorig_Neck": "neck_01", "mixamorig_Head": "Head",
	"mixamorig_LeftShoulder": "clavicle_l", "mixamorig_LeftArm": "upperarm_l", "mixamorig_LeftForeArm": "lowerarm_l", "mixamorig_LeftHand": "hand_l",
	"mixamorig_RightShoulder": "clavicle_r", "mixamorig_RightArm": "upperarm_r", "mixamorig_RightForeArm": "lowerarm_r", "mixamorig_RightHand": "hand_r",
	"mixamorig_LeftUpLeg": "thigh_l", "mixamorig_LeftLeg": "calf_l", "mixamorig_LeftFoot": "foot_l", "mixamorig_LeftToeBase": "ball_l",
	"mixamorig_RightUpLeg": "thigh_r", "mixamorig_RightLeg": "calf_r", "mixamorig_RightFoot": "foot_r", "mixamorig_RightToeBase": "ball_r",
}

## Where the game holds weapons (DungeonPlayer.MOUNTS): hand bone, then this
## correction, then the weapon at (0, 0.035, 0) turned by its rest rotation.
## Since 17/10/2026 a natural grip: the handle runs along the axis the fingers
## wrap around (blade out of the thumb side), the head or edge (+X) toward the
## knuckles, the origin inside the closed fist (see FIST).
const GRIP := {
	"mixamorig_RightHand": [Quaternion(0.63048505783081, 0.77200245857239, -0.05100067332387, 0.06244818121195), Vector3(-0.03210743889213, 0.06280439347029, 0.02609892003238)],
	"mixamorig_LeftHand": [Quaternion(0.67360925674438, 0.73670476675034, -0.0400165617466, 0.04376482963562), Vector3(-0.03327637538314, 0.06309830397367, -0.02205528132617)],
}
## Finger curl (degrees, the three joints of the mitten hand): a closed fist
## around the handle, or a relaxed hand. The left hand curls the other way.
const FIST := [70.0, 80.0, 60.0]
const RELAXED_HAND := [20.0, 25.0, 15.0]
## Segment of each bone for the written poses: bone -> child.
const SEGMENT := {
	"mixamorig_Neck": "mixamorig_Head", "mixamorig_Head": "mixamorig_HeadTop_End",
	"mixamorig_LeftArm": "mixamorig_LeftForeArm", "mixamorig_LeftForeArm": "mixamorig_LeftHand",
	"mixamorig_RightArm": "mixamorig_RightForeArm", "mixamorig_RightForeArm": "mixamorig_RightHand",
	"mixamorig_LeftUpLeg": "mixamorig_LeftLeg", "mixamorig_LeftLeg": "mixamorig_LeftFoot",
	"mixamorig_RightUpLeg": "mixamorig_RightLeg", "mixamorig_RightLeg": "mixamorig_RightFoot",
}
## Short names for the written poses.
const SHORT := {
	"braco_d": "mixamorig_RightArm", "antebraco_d": "mixamorig_RightForeArm",
	"braco_e": "mixamorig_LeftArm", "antebraco_e": "mixamorig_LeftForeArm",
	"coxa_d": "mixamorig_RightUpLeg", "canela_d": "mixamorig_RightLeg",
	"coxa_e": "mixamorig_LeftUpLeg", "canela_e": "mixamorig_LeftLeg",
	"cabeca": "mixamorig_Neck",
}

## Limb bones aligned to the source reference: bone -> the child that gives its direction.
const ALIGN := {
	"mixamorig_LeftShoulder": "mixamorig_LeftArm", "mixamorig_LeftArm": "mixamorig_LeftForeArm", "mixamorig_LeftForeArm": "mixamorig_LeftHand",
	"mixamorig_RightShoulder": "mixamorig_RightArm", "mixamorig_RightArm": "mixamorig_RightForeArm", "mixamorig_RightForeArm": "mixamorig_RightHand",
	"mixamorig_LeftUpLeg": "mixamorig_LeftLeg", "mixamorig_LeftLeg": "mixamorig_LeftFoot", "mixamorig_LeftFoot": "mixamorig_LeftToeBase",
	"mixamorig_RightUpLeg": "mixamorig_RightLeg", "mixamorig_RightLeg": "mixamorig_RightFoot", "mixamorig_RightFoot": "mixamorig_RightToeBase",
}

# Written attacks. Directions in the character's space (+X its left, +Y up, +Z
# forward); see edit_pose for the keys. "impacto": when the blow lands (seconds).

## Weapon ready in front (guard, and where the attacks start and end): blade
## forward and up, cutting side down.
const READY := {"braco_d": Vector3(-0.25, -0.8, 0.5), "antebraco_d": Vector3(-0.05, -0.05, 1.0), "arma_d": [Vector3(0.05, 0.55, 0.83), Vector3(0, -0.83, 0.55)]}
## Two-handed ready: the right hand in front of the belly, the left on the handle.
const READY_2H := {"braco_d": Vector3(-0.2, -0.85, 0.5), "antebraco_d": Vector3(0.35, -0.1, 0.93), "arma_d": [Vector3(0.1, 0.5, 0.86), Vector3(0, -0.86, 0.5)]}
## Carried while walking and running: the arm stops swinging the weapon around.
const CARRY := {"braco_d": Vector3(-0.2, -0.92, 0.3), "antebraco_d": Vector3(-0.1, -0.4, 0.91), "arma_d": [Vector3(0.05, 0.4, 0.92), Vector3(0, -0.92, 0.4)]}
## Standing still: arm relaxed, the tip a little down (long weapons stay off the floor).
const RELAXED := {"braco_d": Vector3(-0.15, -0.97, 0.15), "antebraco_d": Vector3(-0.1, -0.6, 0.8), "arma_d": [Vector3(0.1, -0.22, 0.97), Vector3(0, -0.97, -0.22)]}

## Two hands on a swing weapon (montante, marreta, malho, machado de duas lâminas):
## the left hand below the right on the handle.
const LOW_2H := {"braco_d": Vector3(-0.1, -0.95, 0.25), "antebraco_d": Vector3(0.4, -0.5, 0.75), "arma_d": [Vector3(0.15, -0.35, 0.92), Vector3(0, -0.92, -0.35)], "duas_maos": -0.22}
const CARRY_2H := {"braco_d": Vector3(-0.15, -0.85, 0.45), "antebraco_d": Vector3(0.6, 0.1, 0.8), "arma_d": [Vector3(0.35, 0.9, 0.25), Vector3(0.1, -0.25, 0.96)], "duas_maos": -0.22}
const GUARD_2H := {"braco_d": READY_2H["braco_d"], "antebraco_d": READY_2H["antebraco_d"], "arma_d": READY_2H["arma_d"], "duas_maos": -0.22}
const BLOCK_2H := {"braco_d": Vector3(-0.45, 0.3, 0.85), "antebraco_d": Vector3(0.55, 0.75, 0.35), "arma_d": [Vector3(0.98, 0.1, 0.15), Vector3(0, 1, 0)], "duas_maos": -0.2}
## Poles (lanças, pique, alabarda, tridente, foice): standing, the pole upright in
## the right hand; walking, slanted forward; in guard and crouched, both hands with
## the left one ahead on the shaft.
const POLE_REST := {"braco_d": Vector3(-0.2, -0.9, 0.3), "antebraco_d": Vector3(-0.15, -0.25, 0.95), "arma_d": [Vector3(0, 0.97, 0.2), Vector3(0, -0.2, 0.97)]}
const POLE_CARRY := {"braco_d": Vector3(-0.2, -0.92, 0.3), "antebraco_d": Vector3(-0.1, -0.4, 0.91), "arma_d": [Vector3(0, 0.75, 0.65), Vector3(0, -0.65, 0.75)]}
const POLE_LOW := {"braco_d": Vector3(-0.35, -0.8, 0.45), "antebraco_d": Vector3(-0.1, -0.4, 0.9), "arma_d": [Vector3(0, -0.1, 1), Vector3(1, 0, 0)], "duas_maos": 0.45}
const POLE_BLOCK := {"braco_d": Vector3(-0.5, 0.35, 0.8), "antebraco_d": Vector3(0.45, 0.8, 0.35), "arma_d": [Vector3(1, 0.05, 0.1), Vector3(0, 1, 0)], "duas_maos": 0.45}
## Crossbow at the waist with both hands.
const XBOW_CARRY := {"braco_d": Vector3(-0.25, -0.9, 0.3), "antebraco_d": Vector3(0.2, -0.3, 0.93), "arma_d": [Vector3(0.1, -0.1, 1), Vector3(1, 0, 0)], "duas_maos": 0.3}
## Bow in the left hand, the right arm free.
const BOW_CARRY := {"braco_e": Vector3(0.15, -0.97, 0.1), "antebraco_e": Vector3(0.1, -0.7, 0.7), "arma_e": [Vector3(0, 0.9, 0.4), Vector3(1, 0, 0)]}
## Empty hands: block with the forearms up.
const BLOCK_FISTS := {"braco_d": Vector3(-0.3, -0.3, 0.9), "antebraco_d": Vector3(0.5, 0.8, 0.3), "braco_e": Vector3(0.3, -0.3, 0.9), "antebraco_e": Vector3(-0.5, 0.8, 0.3)}

## Sword: from over the right shoulder, a step in with the right foot and the
## blade diagonally down across the front, ending low on the left (above the floor).
const SLASH := [
	[0.0, READY],
	[0.13, {"giro": -12, "braco_d": Vector3(-0.35, 0.3, 0.6), "antebraco_d": Vector3(-0.1, 0.9, 0.4), "arma_d": [Vector3(-0.05, 0.95, -0.2), Vector3(0.1, 0.25, 0.96)]}],
	[0.26, {"giro": -30, "inclina": -6, "braco_d": Vector3(-0.55, 0.75, -0.35), "antebraco_d": Vector3(-0.2, 0.95, 0.15), "arma_d": [Vector3(-0.15, 0.55, -0.82), Vector3(0.3, 0.8, 0.5)]}],
	[0.40, {"giro": 22, "inclina": 18, "quadril": Vector3(0, -0.08, 0.22), "braco_d": Vector3(0.05, -0.12, 0.99), "antebraco_d": Vector3(0.3, -0.22, 0.93), "arma_d": [Vector3(0.42, -0.28, 0.86), Vector3(0.6, -0.75, -0.2)], "coxa_d": Vector3(-0.1, -0.72, 0.68), "canela_d": Vector3(-0.05, -1.0, 0.05), "coxa_e": Vector3(0.15, -0.82, -0.55), "canela_e": Vector3(0.1, -0.95, -0.3)}],
	[0.52, {"giro": 32, "inclina": 18, "quadril": Vector3(0, -0.08, 0.22), "braco_d": Vector3(0.4, -0.45, 0.8), "antebraco_d": Vector3(0.75, -0.4, 0.52), "arma_d": [Vector3(0.88, -0.38, 0.28), Vector3(0.2, -0.2, -0.95)], "coxa_d": Vector3(-0.1, -0.72, 0.68), "canela_d": Vector3(-0.05, -1.0, 0.05), "coxa_e": Vector3(0.15, -0.82, -0.55), "canela_e": Vector3(0.1, -0.95, -0.3)}],
	[0.72, {"giro": 10, "braco_d": Vector3(0.0, -0.6, 0.8), "antebraco_d": Vector3(0.2, -0.3, 0.93), "arma_d": [Vector3(0.3, -0.1, 0.95), Vector3(0, -0.95, 0)]}],
	[0.95, READY],
]
## Rapier: arm back, then a lunge with the right leg and the point straight ahead.
const LUNGE_READY := {"braco_d": Vector3(-0.3, -0.7, 0.65), "antebraco_d": Vector3(-0.05, 0.05, 1.0), "arma_d": [Vector3(0, 0.25, 0.97), Vector3(0, -0.97, 0.25)]}
const LUNGE_OUT := {"giro": 28, "inclina": 12, "quadril": Vector3(0, -0.1, 0.18), "braco_d": Vector3(-0.05, 0.05, 1.0), "antebraco_d": Vector3(0, 0.03, 1.0), "arma_d": [Vector3(0, 0, 1), Vector3(0, -1, 0)], "coxa_d": Vector3(-0.1, -0.7, 0.7), "canela_d": Vector3(-0.05, -1.0, 0.05), "coxa_e": Vector3(0.15, -0.8, -0.58), "canela_e": Vector3(0.1, -0.95, -0.3)}
const LUNGE := [
	[0.0, LUNGE_READY],
	[0.16, {"giro": -20, "braco_d": Vector3(-0.45, -0.8, -0.35), "antebraco_d": Vector3(-0.1, 0.1, 0.99), "arma_d": [Vector3(0, 0.1, 1), Vector3(0, -1, 0.1)]}],
	[0.30, LUNGE_OUT],
	[0.42, LUNGE_OUT],
	[0.8, LUNGE_READY],
]
## Dagger: the fist pulled back to the waist, then a short jab with the point
## straight ahead (a punch would turn the blade up out of the thumb side).
const STAB_READY := {"braco_d": Vector3(-0.25, -0.85, 0.45), "antebraco_d": Vector3(-0.1, 0.05, 0.99), "arma_d": [Vector3(0.05, 0.35, 0.94), Vector3(0, -0.94, 0.35)]}
const STAB_OUT := {"giro": 14, "inclina": 8, "braco_d": Vector3(-0.05, -0.3, 0.95), "antebraco_d": Vector3(0.05, -0.02, 1.0), "arma_d": [Vector3(0, -0.02, 1), Vector3(0, -1, -0.02)]}
const STAB := [
	[0.0, STAB_READY],
	[0.12, {"giro": -18, "braco_d": Vector3(-0.35, -0.8, -0.45), "antebraco_d": Vector3(-0.1, 0.1, 0.99), "arma_d": [Vector3(0, 0.15, 0.99), Vector3(0, -0.99, 0.15)]}],
	[0.26, STAB_OUT],
	[0.36, STAB_OUT],
	[0.75, STAB_READY],
]
## Sling: right arm back and up, thrown forward over the shoulder.
const THROW_READY := {"braco_d": Vector3(-0.3, -0.9, 0.2), "antebraco_d": Vector3(-0.2, -0.5, 0.85)}
const THROW := [
	[0.0, THROW_READY],
	[0.22, {"giro": -35, "inclina": -8, "braco_d": Vector3(-0.7, 0.35, -0.6), "antebraco_d": Vector3(-0.3, 0.9, -0.3), "braco_e": Vector3(0.3, 0.1, 0.95), "antebraco_e": Vector3(0.1, 0.2, 0.97)}],
	[0.32, {"giro": 25, "inclina": 12, "braco_d": Vector3(-0.2, 0.45, 0.87), "antebraco_d": Vector3(0, 0.3, 0.95), "braco_e": Vector3(0.6, -0.6, 0.5), "antebraco_e": Vector3(0.3, -0.7, 0.6)}],
	[0.42, {"giro": 30, "inclina": 15, "braco_d": Vector3(0.1, -0.3, 0.95), "antebraco_d": Vector3(0.2, -0.5, 0.85), "braco_e": Vector3(0.6, -0.7, 0.3), "antebraco_e": Vector3(0.3, -0.8, 0.5)}],
	[0.75, THROW_READY],
]
const CHOP := [
	[0.0, READY],
	[0.15, {"giro": -10, "braco_d": Vector3(-0.3, 0.35, 0.6), "antebraco_d": Vector3(-0.1, 0.9, 0.3), "arma_d": [Vector3(0, 0.85, -0.5), Vector3(0, 0.5, 0.85)]}],
	[0.30, {"giro": -25, "inclina": -8, "braco_d": Vector3(-0.25, 0.85, -0.45), "antebraco_d": Vector3(-0.1, 0.55, -0.85), "arma_d": [Vector3(0, 0.3, -0.95), Vector3(0, 0.95, 0.3)]}],
	[0.44, {"giro": 15, "inclina": 28, "braco_d": Vector3(-0.1, -0.4, 0.9), "antebraco_d": Vector3(-0.05, -0.65, 0.75), "arma_d": [Vector3(0, -0.55, 0.85), Vector3(0, -0.85, -0.55)]}],
	[0.56, {"giro": 18, "inclina": 30, "braco_d": Vector3(-0.12, -0.6, 0.78), "antebraco_d": Vector3(-0.05, -0.85, 0.5), "arma_d": [Vector3(0, -0.8, 0.6), Vector3(0, -0.6, -0.8)]}],
	[0.95, READY],
]
const SWING := [
	[0.0, READY],
	[0.14, {"giro": -15, "braco_d": Vector3(-0.5, 0.2, 0.5), "antebraco_d": Vector3(-0.3, 0.85, 0.15), "arma_d": [Vector3(-0.2, 0.9, -0.3), Vector3(0.5, 0.3, 0.8)]}],
	[0.28, {"giro": -35, "inclina": -5, "braco_d": Vector3(-0.75, 0.55, -0.35), "antebraco_d": Vector3(-0.4, 0.8, -0.45), "arma_d": [Vector3(-0.3, 0.6, -0.75), Vector3(0.6, 0.7, 0.2)]}],
	[0.36, {"giro": 5, "inclina": 10, "braco_d": Vector3(-0.1, 0.0, 1.0), "antebraco_d": Vector3(0.1, -0.1, 0.99), "arma_d": [Vector3(0.25, -0.1, 0.96), Vector3(0.45, -0.88, -0.2)]}],
	[0.42, {"giro": 25, "inclina": 15, "braco_d": Vector3(0.2, -0.15, 0.97), "antebraco_d": Vector3(0.5, -0.3, 0.8), "arma_d": [Vector3(0.75, -0.25, 0.6), Vector3(0.2, -0.95, -0.1)]}],
	[0.54, {"giro": 35, "inclina": 18, "braco_d": Vector3(0.45, -0.35, 0.8), "antebraco_d": Vector3(0.7, -0.45, 0.55), "arma_d": [Vector3(0.8, -0.5, 0.3), Vector3(0, -0.6, -0.8)]}],
	[0.9, READY],
]
const SWEEP := [
	[0.0, {"braco_d": READY_2H["braco_d"], "antebraco_d": READY_2H["antebraco_d"], "arma_d": READY_2H["arma_d"], "duas_maos": -0.14}],
	[0.19, {"giro": -20, "braco_d": Vector3(-0.45, 0.1, 0.65), "antebraco_d": Vector3(-0.2, 0.75, 0.6), "arma_d": [Vector3(-0.25, 0.95, 0.1), Vector3(0.1, -0.1, 0.99)], "duas_maos": -0.14}],
	[0.38, {"giro": -45, "inclina": -5, "braco_d": Vector3(-0.85, 0.35, -0.3), "antebraco_d": Vector3(-0.6, 0.45, -0.6), "arma_d": [Vector3(-0.55, 0.45, -0.7), Vector3(0.1, -0.75, 0.6)], "duas_maos": -0.14}],
	[0.56, {"giro": 30, "inclina": 10, "braco_d": Vector3(0.25, 0.0, 0.97), "antebraco_d": Vector3(0.55, 0.05, 0.83), "arma_d": [Vector3(0.85, 0.05, 0.5), Vector3(0.5, -0.1, -0.85)], "duas_maos": -0.14}],
	[0.72, {"giro": 50, "inclina": 10, "braco_d": Vector3(0.55, -0.1, 0.8), "antebraco_d": Vector3(0.85, -0.1, 0.5), "arma_d": [Vector3(0.95, -0.1, -0.25), Vector3(-0.25, 0, -0.95)], "duas_maos": -0.14}],
	[1.15, {"braco_d": READY_2H["braco_d"], "antebraco_d": READY_2H["antebraco_d"], "arma_d": READY_2H["arma_d"], "duas_maos": -0.14}],
]
const SLAM := [
	[0.0, {"braco_d": READY_2H["braco_d"], "antebraco_d": READY_2H["antebraco_d"], "arma_d": READY_2H["arma_d"], "duas_maos": -0.25}],
	[0.5, {"giro": -10, "inclina": -15, "braco_d": Vector3(-0.15, 0.95, -0.2), "antebraco_d": Vector3(0, 0.7, -0.7), "arma_d": [Vector3(0, 0.2, -0.98), Vector3(-1, 0, 0)], "duas_maos": -0.25}],
	[0.68, {"inclina": 40, "quadril": Vector3(0, -0.22, 0.05), "braco_d": Vector3(-0.1, -0.5, 0.85), "antebraco_d": Vector3(0, -0.75, 0.65), "arma_d": [Vector3(0, -0.85, 0.5), Vector3(-1, 0, 0)], "duas_maos": -0.25}],
	[0.85, {"inclina": 40, "quadril": Vector3(0, -0.22, 0.05), "braco_d": Vector3(-0.1, -0.5, 0.85), "antebraco_d": Vector3(0, -0.75, 0.65), "arma_d": [Vector3(0, -0.85, 0.5), Vector3(-1, 0, 0)], "duas_maos": -0.25}],
	[1.35, {"braco_d": READY_2H["braco_d"], "antebraco_d": READY_2H["antebraco_d"], "arma_d": READY_2H["arma_d"], "duas_maos": -0.25}],
]
## Scythe: both hands on the snath (the left one up the shaft), a reaping
## sweep from the right to the left with the blade leading.
const REAP_GUARD := {"braco_d": Vector3(-0.35, -0.75, 0.55), "antebraco_d": Vector3(-0.1, -0.2, 0.98), "arma_d": [Vector3(0, 0.1, 1), Vector3(1, -0.1, 0)], "duas_maos": 0.45}
const REAP := [
	[0.0, REAP_GUARD],
	[0.35, {"giro": -45, "inclina": -5, "braco_d": Vector3(-0.55, -0.6, 0.55), "antebraco_d": Vector3(-0.35, -0.1, 0.93), "arma_d": [Vector3(-0.75, 0.25, 0.6), Vector3(0.6, -0.2, 0.75)], "duas_maos": 0.45}],
	[0.55, {"giro": 25, "inclina": 12, "braco_d": Vector3(-0.2, -0.55, 0.8), "antebraco_d": Vector3(0.15, -0.25, 0.95), "arma_d": [Vector3(0.3, -0.15, 0.94), Vector3(0.95, -0.1, -0.3)], "duas_maos": 0.45}],
	[0.72, {"giro": 45, "inclina": 12, "braco_d": Vector3(0.1, -0.6, 0.78), "antebraco_d": Vector3(0.5, -0.25, 0.82), "arma_d": [Vector3(0.85, -0.2, 0.45), Vector3(0.45, -0.1, -0.88)], "duas_maos": 0.45}],
	[1.15, REAP_GUARD],
]
const SPEAR_GUARD := {"braco_d": Vector3(-0.35, -0.75, 0.55), "antebraco_d": Vector3(-0.1, -0.2, 0.98), "arma_d": [Vector3(0, 0, 1), Vector3(1, 0, 0)], "duas_maos": 0.45}
const THRUST := [
	[0.0, SPEAR_GUARD],
	[0.30, {"giro": -25, "inclina": -5, "braco_d": Vector3(-0.45, -0.7, -0.55), "antebraco_d": Vector3(-0.15, -0.1, 0.98), "arma_d": [Vector3(0, 0.05, 1), Vector3(1, 0, 0)], "duas_maos": 0.45}],
	[0.45, {"giro": 15, "inclina": 18, "braco_d": Vector3(-0.25, -0.25, 0.93), "antebraco_d": Vector3(-0.1, -0.1, 0.99), "arma_d": [Vector3(0, 0, 1), Vector3(1, 0, 0)], "duas_maos": 0.45}],
	[0.60, {"giro": 15, "inclina": 18, "braco_d": Vector3(-0.25, -0.25, 0.93), "antebraco_d": Vector3(-0.1, -0.1, 0.99), "arma_d": [Vector3(0, 0, 1), Vector3(1, 0, 0)], "duas_maos": 0.45}],
	[0.95, SPEAR_GUARD],
]
const BOW_READY := {"braco_e": Vector3(0.2, -0.6, 0.75), "antebraco_e": Vector3(0.1, -0.3, 0.95), "arma_e": [Vector3(0, 0.95, 0.3), Vector3(1, 0, 0)], "braco_d": Vector3(-0.2, -0.95, 0.2), "antebraco_d": Vector3(0, -0.7, 0.7)}
const BOW := [
	[0.0, BOW_READY],
	[0.25, {"giro": 20, "braco_e": Vector3(0.1, 0.08, 0.99), "antebraco_e": Vector3(0.05, 0.08, 0.99), "arma_e": [Vector3(0, 1, 0), Vector3(1, 0, 0)], "braco_d": Vector3(-0.4, 0.05, 0.9), "antebraco_d": Vector3(0.5, 0.1, 0.85)}],
	[0.5, {"giro": 25, "braco_e": Vector3(0.1, 0.08, 0.99), "antebraco_e": Vector3(0.05, 0.08, 0.99), "arma_e": [Vector3(0, 1, 0), Vector3(1, 0, 0)], "braco_d": Vector3(-0.85, 0.12, -0.5), "antebraco_d": Vector3(0.8, 0.15, 0.55)}],
	[0.58, {"giro": 25, "braco_e": Vector3(0.1, 0.08, 0.99), "antebraco_e": Vector3(0.05, 0.08, 0.99), "arma_e": [Vector3(0, 1, 0), Vector3(1, 0, 0)], "braco_d": Vector3(-0.9, 0.15, -0.4), "antebraco_d": Vector3(-0.3, 0.3, -0.9)}],
	[0.9, BOW_READY],
]
const XBOW_GUARD := {"braco_d": Vector3(-0.35, -0.5, 0.8), "antebraco_d": Vector3(-0.05, 0.1, 0.99), "arma_d": [Vector3(0, 0.05, 1), Vector3(1, 0, 0)], "duas_maos": 0.3}
const XBOW := [
	[0.0, XBOW_GUARD],
	[0.15, {"inclina": 5, "braco_d": Vector3(-0.3, -0.3, 0.9), "antebraco_d": Vector3(0, 0.05, 1), "arma_d": [Vector3(0, 0, 1), Vector3(1, 0, 0)], "duas_maos": 0.3}],
	[0.2, {"inclina": 5, "braco_d": Vector3(-0.3, -0.3, 0.9), "antebraco_d": Vector3(0, 0.05, 1), "arma_d": [Vector3(0, 0, 1), Vector3(1, 0, 0)], "duas_maos": 0.3}],
	[0.28, {"inclina": -5, "braco_d": Vector3(-0.3, -0.2, 0.85), "antebraco_d": Vector3(0, 0.3, 0.95), "arma_d": [Vector3(0, 0.3, 0.95), Vector3(1, 0, 0)], "duas_maos": 0.3}],
	[0.7, XBOW_GUARD],
]
const BLOCK := {"braco_d": Vector3(-0.5, -0.1, 0.85), "antebraco_d": Vector3(0.4, 0.6, 0.7), "arma_d": [Vector3(0.9, 0.2, 0.3), Vector3(0, 1, 0)]}
## Monsters: the right arm cocked back over the shoulder (elbow out, the body
## turned away), then a swipe down across the front, leaning into it.
const CLAW := [
	[0.0, {}],
	[0.35, {"giro": -40, "inclina": -10, "braco_d": Vector3(-0.75, 0.45, -0.5), "antebraco_d": Vector3(-0.3, 0.85, 0.4), "braco_e": Vector3(0.45, -0.3, 0.85), "antebraco_e": Vector3(0.3, 0.2, 0.93)}],
	[0.5, {"giro": 25, "inclina": 22, "braco_d": Vector3(0.1, -0.3, 0.95), "antebraco_d": Vector3(0.4, -0.5, 0.77), "braco_e": Vector3(0.5, -0.7, -0.2), "antebraco_e": Vector3(0.3, -0.8, 0.3)}],
	[0.62, {"giro": 38, "inclina": 25, "braco_d": Vector3(0.45, -0.6, 0.66), "antebraco_d": Vector3(0.7, -0.65, 0.3), "braco_e": Vector3(0.5, -0.8, -0.3), "antebraco_e": Vector3(0.3, -0.85, 0.3)}],
	[1.0, {}],
]
const BOSS_SLAM := [
	[0.0, {}],
	[0.55, {"inclina": -12, "braco_d": Vector3(-0.2, 0.97, -0.1), "antebraco_d": Vector3(-0.1, 0.95, 0.3), "braco_e": Vector3(0.2, 0.97, -0.1), "antebraco_e": Vector3(0.1, 0.95, 0.3)}],
	[0.72, {"inclina": 40, "quadril": Vector3(0, -0.2, 0.05), "braco_d": Vector3(-0.2, -0.6, 0.75), "antebraco_d": Vector3(-0.1, -0.9, 0.4), "braco_e": Vector3(0.2, -0.6, 0.75), "antebraco_e": Vector3(0.1, -0.9, 0.4)}],
	[0.95, {"inclina": 40, "quadril": Vector3(0, -0.2, 0.05), "braco_d": Vector3(-0.2, -0.6, 0.75), "antebraco_d": Vector3(-0.1, -0.9, 0.4), "braco_e": Vector3(0.2, -0.6, 0.75), "antebraco_e": Vector3(0.1, -0.9, 0.4)}],
	[1.5, {}],
]
const MONSTER_GUARD := {"inclina": 15, "braco_d": Vector3(-0.3, -0.6, 0.7), "antebraco_d": Vector3(-0.1, -0.3, 0.95), "braco_e": Vector3(0.3, -0.6, 0.7), "antebraco_e": Vector3(0.1, -0.3, 0.95)}

func stretched(keys: Array, factor: float) -> Array:
	var out: Array = []
	for k in keys:
		out.append([float(k[0]) * factor, k[1]])
	return out

var SETS := {
	"aventureiro": [
		{"name": "idle", "src": "ual", "anim": "Idle", "loop": true, "segura": RELAXED},
		{"name": "walk", "src": "ual", "anim": "Jog_Fwd", "loop": true, "segura": CARRY},
		{"name": "run", "src": "ual", "anim": "Sprint", "loop": true, "segura": CARRY},
		{"name": "guard", "src": "ual", "anim": "Sword_Idle", "loop": true, "segura": READY},
		{"name": "furtivo", "src": "ual", "anim": "Crouch_Idle", "loop": true},
		{"name": "furtivo_andar", "src": "ual", "anim": "Crouch_Fwd", "loop": true},
		{"name": "dodge", "src": "ual", "anim": "Roll", "from": 0.05, "to": 1.25},
		{"name": "hit", "src": "ual", "anim": "Hit_Chest"},
		{"name": "die", "src": "ual", "anim": "Death01"},
		{"name": "soco", "src": "ual", "anim": "Punch_Cross", "impacto": "auto"},
		{"name": "golpe_adaga", "src": "pose", "base": "Sword_Idle", "keys": STAB, "impacto": 0.26},
		{"name": "golpe_espada", "src": "pose", "base": "Sword_Idle", "keys": SLASH, "impacto": 0.40},
		{"name": "attack", "src": "pose", "base": "Sword_Idle", "keys": SLASH, "impacto": 0.40},
		{"name": "estocada_florete", "src": "pose", "base": "Sword_Idle", "keys": LUNGE, "impacto": 0.30},
		{"name": "golpe_katana", "src": "mixamo", "anim": "sword and shield slash (3)", "from": 0.25, "to": 0.95, "impacto": 0.55},
		{"name": "arremesso", "src": "pose", "base": "Idle", "keys": THROW, "impacto": 0.32},
		{"name": "golpe_machado", "src": "pose", "base": "Sword_Idle", "keys": CHOP, "impacto": 0.44},
		{"name": "golpe_maca", "src": "pose", "base": "Sword_Idle", "keys": SWING, "impacto": 0.42},
		{"name": "golpe_montante", "src": "pose", "base": "Sword_Idle", "keys": SWEEP, "impacto": 0.56},
		{"name": "golpe_foice", "src": "pose", "base": "Sword_Idle", "keys": REAP, "impacto": 0.55},
		{"name": "pancada_martelo", "src": "pose", "base": "Sword_Idle", "keys": SLAM, "impacto": 0.68},
		{"name": "estocada_lanca", "src": "pose", "base": "Sword_Idle", "keys": THRUST, "impacto": 0.45},
		{"name": "stab", "src": "pose", "base": "Sword_Idle", "keys": THRUST, "impacto": 0.45},
		{"name": "estocada_alabarda", "src": "pose", "base": "Sword_Idle", "keys": stretched(THRUST, 1.15), "impacto": 0.45 * 1.15},
		{"name": "disparo_arco", "src": "pose", "base": "Idle", "keys": BOW, "impacto": 0.55},
		{"name": "disparo_besta", "src": "pose", "base": "Idle", "keys": XBOW, "impacto": 0.2},
		{"name": "bloqueio", "src": "pose", "base": "Sword_Idle", "keys": [[0.0, BLOCK], [1.0, BLOCK]], "loop": true},
	],
	"monstro": [
		{"name": "idle", "src": "ual", "anim": "Idle", "loop": true},
		{"name": "walk", "src": "ual", "anim": "Walk", "loop": true},
		{"name": "run", "src": "ual", "anim": "Jog_Fwd", "loop": true},
		{"name": "guard", "src": "pose", "base": "Idle", "keys": [[0.0, MONSTER_GUARD], [1.0, MONSTER_GUARD]], "loop": true},
		{"name": "attack", "src": "pose", "base": "Idle", "keys": CLAW, "impacto": 0.5},
		{"name": "pancada", "src": "pose", "base": "Idle", "keys": BOSS_SLAM, "impacto": 0.72},
		{"name": "hit", "src": "ual", "anim": "Hit_Head"},
		{"name": "die", "src": "ual", "anim": "Death01"},
	],
	"mercador": [
		{"name": "idle", "src": "ual", "anim": "Idle", "loop": true},
		{"name": "falar", "src": "ual", "anim": "Idle_Talking", "loop": true},
	],
}

var CHARACTERS := {
	"aventureiro_psx": {"model": "res://p/Character_16.fbx", "texture": "res://p/aventureiro_psx.png", "set": "aventureiro"},
	"mercador": {"model": "res://p/Character_16.fbx", "texture": "res://p/mercador.png", "set": "mercador"},
	"afogado": {"model": "res://p/psx/Character_Monster_06.fbx", "texture": "res://p/psx/Character_Monster_06.png", "set": "monstro"},
	"carnical": {"model": "res://p/psx/Character_Monster_07.fbx", "texture": "res://p/psx/Character_Monster_07.png", "set": "monstro"},
	"inchado": {"model": "res://p/psx/Character_Monster_08.fbx", "texture": "res://p/psx/Character_Monster_08.png", "set": "monstro"},
	"carcereiro": {"model": "res://p/psx/Character_Killer_08.fbx", "texture": "res://p/psx/Character_Killer_08.png", "set": "monstro"},
	"capataz": {"model": "res://p/psx/Character_Killer_05.fbx", "texture": "res://p/psx/Character_Killer_05.png", "set": "monstro"},
}

var _sources: Dictionary = {}
## Impact moment of each attack, as a fraction of its length (for data/animacoes.json).
var impacts: Dictionary = {}

func _initialize() -> void:
	SETS["aventureiro"].append_array(carry_variants())
	run()

## The adventurer's standing, moving, guard, crouch and block animations for each
## way of carrying: _livre (empty hands), _duas (two hands on a swing weapon),
## _haste (poles), _besta (crossbow) and _arco (bow in the left hand). Without
## a suffix: one-handed weapons. Crouched, a two-handed weapon stays slanted up
## (held low it would go through the floor).
func carry_variants() -> Array:
	var out: Array = []
	# Empty hands: the library's own arms, a boxing guard, forearms up to block.
	out.append({"name": "idle_livre", "src": "ual", "anim": "Idle", "loop": true})
	out.append({"name": "walk_livre", "src": "ual", "anim": "Jog_Fwd", "loop": true})
	out.append({"name": "run_livre", "src": "ual", "anim": "Sprint", "loop": true})
	out.append({"name": "guard_livre", "src": "ual", "anim": "Punch_Cross", "to": 0.05, "loop": true})
	out.append({"name": "bloqueio_livre", "src": "pose", "base": "Sword_Idle", "keys": [[0.0, BLOCK_FISTS], [1.0, BLOCK_FISTS]], "loop": true})
	var ways := {
		"_duas": {"idle": LOW_2H, "walk": CARRY_2H, "run": CARRY_2H, "guard": GUARD_2H, "furtivo": CARRY_2H, "furtivo_andar": CARRY_2H, "bloqueio": BLOCK_2H},
		"_haste": {"idle": POLE_REST, "walk": POLE_CARRY, "run": POLE_CARRY, "guard": SPEAR_GUARD, "furtivo": POLE_LOW, "furtivo_andar": POLE_LOW, "bloqueio": POLE_BLOCK},
		"_besta": {"idle": XBOW_CARRY, "walk": XBOW_CARRY, "run": XBOW_CARRY, "guard": XBOW_GUARD, "furtivo": XBOW_CARRY, "furtivo_andar": XBOW_CARRY},
		"_arco": {"idle": BOW_CARRY, "walk": BOW_CARRY, "run": BOW_CARRY, "guard": BOW_READY, "furtivo": BOW_CARRY, "furtivo_andar": BOW_CARRY},
	}
	var sources := {"idle": "Idle", "walk": "Jog_Fwd", "run": "Sprint", "guard": "Sword_Idle", "furtivo": "Crouch_Idle", "furtivo_andar": "Crouch_Fwd"}
	for suffix in ways:
		for anim in ways[suffix]:
			var hold: Dictionary = ways[suffix][anim]
			if anim == "bloqueio":
				out.append({"name": anim + suffix, "src": "pose", "base": "Sword_Idle", "keys": [[0.0, hold], [1.0, hold]], "loop": true})
			else:
				out.append({"name": anim + suffix, "src": "ual", "anim": sources[anim], "loop": true, "segura": hold})
	return out

func run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var only: Array = args.slice(1)
	# "catalogo": every model in p/psx with just the idle, to choose from.
	if "catalogo" in only:
		SETS["catalogo"] = [{"name": "idle", "src": "ual", "anim": "Idle", "loop": true}]
		CHARACTERS.clear()
		for f in DirAccess.get_files_at("res://p/psx"):
			if f.ends_with(".fbx"):
				CHARACTERS[f.get_basename()] = {"model": "res://p/psx/" + f, "texture": "res://p/psx/" + f.get_basename() + ".png", "set": "catalogo"}
		only = []
	for id in CHARACTERS:
		if only.is_empty() or id in only:
			await build(id, CHARACTERS[id], out)
	quit()

func world(sk: Skeleton3D, b: int, rest: bool) -> Transform3D:
	return sk.global_transform * (sk.get_bone_global_rest(b) if rest else sk.get_bone_global_pose(b))

## A source scene (cached) with its skeleton, player and reference pose (world transforms).
func source(kind: String, anim: String) -> Dictionary:
	var path: String = UAL if kind == "ual" else MIXAMO % anim
	if _sources.has(path):
		return _sources[path]
	var node: Node3D = load(path).instantiate()
	root.add_child(node)
	var sk: Skeleton3D = node.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = node.find_children("*", "AnimationPlayer", true, false)[0]
	var ref: Dictionary = {}
	if kind == "ual":
		ap.play("A_TPose")
		ap.seek(0.0, true)
		sk.force_update_all_bone_transforms()
		for b in sk.get_bone_count():
			ref[b] = world(sk, b, false)
	else:
		for b in sk.get_bone_count():
			ref[b] = world(sk, b, true)
	var entry := {"node": node, "sk": sk, "ap": ap, "ref": ref, "map": UAL_MAP if kind == "ual" else {}}
	_sources[path] = entry
	return entry

## Retargeted pose of the target at time t of a source animation: local
## rotations per bone and the hips position.
func retarget_frame(src: Dictionary, anim_name: String, t: float, sk_t: Skeleton3D, tref: Array, pairs: Dictionary, k: float) -> Dictionary:
	var sk_s: Skeleton3D = src["sk"]
	var ap_s: AnimationPlayer = src["ap"]
	ap_s.play(anim_name)
	ap_s.seek(t, true)
	sk_s.force_update_all_bone_transforms()
	var hips: int = sk_t.find_bone("mixamorig_Hips")
	var locals: Array = []
	locals.resize(sk_t.get_bone_count())
	var world_t: Array = []
	world_t.resize(sk_t.get_bone_count())
	var hips_pos: Vector3 = sk_t.get_bone_rest(hips).origin
	for b in sk_t.get_bone_count():
		var parent: int = sk_t.get_bone_parent(b)
		var parent_world: Transform3D = sk_t.global_transform if parent < 0 else world_t[parent]
		var rest_local: Transform3D = sk_t.get_bone_rest(b)
		if pairs.has(b):
			var sb: int = pairs[b]
			var pose_w: Transform3D = world(sk_s, sb, false)
			var ref_w: Transform3D = src["ref"][sb]
			var delta: Basis = pose_w.basis.orthonormalized() * ref_w.basis.orthonormalized().inverse()
			var target_basis: Basis = delta * tref[b].basis.orthonormalized()
			var origin: Vector3 = (parent_world * rest_local).origin
			if b == hips:
				origin = world(sk_t, hips, true).origin + (pose_w.origin - ref_w.origin) * k
				hips_pos = parent_world.affine_inverse() * origin
			world_t[b] = Transform3D(target_basis, origin)
			locals[b] = (parent_world.basis.orthonormalized().inverse() * target_basis).get_rotation_quaternion()
		else:
			world_t[b] = parent_world * rest_local
			locals[b] = rest_local.basis.get_rotation_quaternion()
	return {"locals": locals, "hips": hips_pos}

## A written pose: the base pose with edits. Directions are in the character's
## space (+X its left, +Y up, +Z forward). Keys: SHORT names -> direction of the
## bone's segment; "giro" (torso turn, degrees, + to its left), "inclina"
## (torso lean, + forward), "quadril" (hips offset), "arma_d" / "arma_e":
## [blade, edge] of the weapon in the right / left hand.
func edit_pose(base: Dictionary, edits: Dictionary, sk_t: Skeleton3D, hold: Vector3, left_basis: Variant = null) -> Dictionary:
	var locals: Array = base["locals"].duplicate()
	var hips: int = sk_t.find_bone("mixamorig_Hips")
	var hips_pos: Vector3 = base["hips"] + edits.get("quadril", Vector3.ZERO)
	var aims: Dictionary = {}
	for key in edits:
		if SHORT.has(key):
			aims[SHORT[key]] = Vector3(edits[key]).normalized()
	var world_t: Array = []
	world_t.resize(sk_t.get_bone_count())
	for b in sk_t.get_bone_count():
		var parent: int = sk_t.get_bone_parent(b)
		var parent_world: Transform3D = sk_t.global_transform if parent < 0 else world_t[parent]
		var origin: Vector3 = hips_pos if b == hips else sk_t.get_bone_rest(b).origin
		var w: Transform3D = parent_world * Transform3D(Basis(locals[b]), origin)
		var bname: String = sk_t.get_bone_name(b)
		if bname == "mixamorig_Spine" and (edits.has("giro") or edits.has("inclina")):
			var turn := Basis(Vector3.UP, deg_to_rad(float(edits.get("giro", 0.0)))) * Basis(Vector3.RIGHT, deg_to_rad(float(edits.get("inclina", 0.0))))
			w.basis = turn * w.basis
		if aims.has(bname):
			var child: int = sk_t.find_bone(SEGMENT[bname])
			var d: Vector3 = ((w * sk_t.get_bone_rest(child)).origin - w.origin).normalized()
			if d.dot(aims[bname]) < 0.9999:
				w.basis = Basis(Quaternion(d, aims[bname])) * w.basis
		for side in [["arma_d", "mixamorig_RightHand"], ["arma_e", "mixamorig_LeftHand"]]:
			if bname == side[1] and edits.has(side[0]):
				w.basis = hand_for_weapon(edits[side[0]], side[1], hold)
		if bname == "mixamorig_LeftHand" and left_basis != null:
			w.basis = left_basis
		world_t[b] = w
		locals[b] = (parent_world.basis.orthonormalized().inverse() * w.basis.orthonormalized()).get_rotation_quaternion()
	return {"locals": locals, "hips": hips_pos, "world": world_t}

## A written pose with both hands on the weapon ("duas_maos": where the left
## hand grips, metres along the blade from the right hand; + towards the tip):
## the left arm reaches it by two-bone IK, elbow down and out.
func make_pose(base: Dictionary, edits: Dictionary, sk_t: Skeleton3D, hold: Vector3) -> Dictionary:
	var pose: Dictionary = edit_pose(base, edits, sk_t, hold)
	if not edits.has("duas_maos"):
		return pose
	var w: Array = pose["world"]
	var hand: Transform3D = w[sk_t.find_bone("mixamorig_RightHand")]
	var weapon: Transform3D = hand * Transform3D(Basis(GRIP["mixamorig_RightHand"][0]), GRIP["mixamorig_RightHand"][1]) * Transform3D(Basis.from_euler(hold * PI / 180.0), Vector3(0, 0.035, 0))
	var target: Vector3 = weapon.origin + weapon.basis.y.normalized() * float(edits["duas_maos"])
	var s_pos: Vector3 = w[sk_t.find_bone("mixamorig_LeftArm")].origin
	var e_pos: Vector3 = w[sk_t.find_bone("mixamorig_LeftForeArm")].origin
	var h_pos: Vector3 = w[sk_t.find_bone("mixamorig_LeftHand")].origin
	var a: float = s_pos.distance_to(e_pos)
	var b: float = e_pos.distance_to(h_pos)
	var to: Vector3 = target - s_pos
	var d: float = clampf(to.length(), 0.01, (a + b) * 0.999)
	var dir: Vector3 = to.normalized()
	var along: float = (a * a - b * b + d * d) / (2.0 * d)
	var up: float = sqrt(maxf(0.0, a * a - along * along))
	var hint: Vector3 = Vector3(0.45, -1.0, -0.15)
	var bend: Vector3 = (hint - dir * hint.dot(dir)).normalized()
	var elbow: Vector3 = s_pos + dir * along + bend * up
	var hand_at: Vector3 = s_pos + dir * d
	var more: Dictionary = edits.duplicate()
	more["braco_e"] = elbow - s_pos
	more["antebraco_e"] = hand_at - elbow
	return edit_pose(base, more, sk_t, hold, hand.basis.orthonormalized())

## Hand rotation that puts the held weapon's blade (+Y) and edge (+X) where asked.
func hand_for_weapon(spec: Array, hand: String, hold: Vector3) -> Basis:
	var blade: Vector3 = Vector3(spec[0]).normalized()
	var edge: Vector3 = Vector3(spec[1])
	edge = (edge - blade * edge.dot(blade)).normalized()
	var weapon_basis := Basis(edge, blade, edge.cross(blade))
	var held: Basis = Basis(GRIP[hand][0]) * Basis.from_euler(hold * PI / 180.0)
	return weapon_basis * held.inverse()

## A written animation: key poses over the base pose, eased in between.
func written(a: Dictionary, dst: Node3D, sk_t: Skeleton3D) -> Animation:
	var src: Dictionary = source("ual", a["base"])
	var sk_s: Skeleton3D = src["sk"]
	var pairs: Dictionary = {}
	for b in sk_t.get_bone_count():
		var sb: int = sk_s.find_bone(UAL_MAP.get(sk_t.get_bone_name(b), "-"))
		if sb >= 0:
			pairs[b] = sb
	var tref: Array = matched_reference(sk_t, src, pairs)
	var hips: int = sk_t.find_bone("mixamorig_Hips")
	var k: float = world(sk_t, hips, true).origin.y / maxf(0.01, src["ref"][pairs[hips]].origin.y)
	var base: Dictionary = retarget_frame(src, a["base"], float(a.get("base_t", 0.0)), sk_t, tref, pairs, k)
	var hold: Vector3 = a.get("pega", Vector3.ZERO)
	var keys: Array = []
	for key in a["keys"]:
		keys.append([float(key[0]), make_pose(base, key[1], sk_t, hold)])
	if a.has("impacto"):
		impacts[a["name"]] = float(a["impacto"]) / float(keys[-1][0])
	var anim := Animation.new()
	anim.length = float(keys[-1][0])
	anim.loop_mode = Animation.LOOP_LINEAR if a.get("loop", false) else Animation.LOOP_NONE
	var skel_path: String = str(dst.get_path_to(sk_t))
	var tracks: Dictionary = {}
	for b in sk_t.get_bone_count():
		var t: int = anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(t, "%s:%s" % [skel_path, sk_t.get_bone_name(b)])
		tracks[b] = t
	var pos_track: int = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos_track, "%s:mixamorig_Hips" % skel_path)
	var frames: int = maxi(1, ceili(anim.length * FPS))
	for f in frames + 1:
		var time: float = minf(f / FPS, anim.length)
		var i: int = 0
		while i < keys.size() - 2 and time > keys[i + 1][0]:
			i += 1
		var k0: Array = keys[i]
		var k1: Array = keys[mini(i + 1, keys.size() - 1)]
		var span: float = maxf(0.0001, k1[0] - k0[0])
		var x: float = clampf((time - k0[0]) / span, 0.0, 1.0)
		x = x * x * (3.0 - 2.0 * x)
		for b in sk_t.get_bone_count():
			var q: Quaternion = Quaternion(k0[1]["locals"][b]).slerp(Quaternion(k1[1]["locals"][b]), x)
			anim.rotation_track_insert_key(tracks[b], time, q)
		anim.position_track_insert_key(pos_track, time, Vector3(k0[1]["hips"]).lerp(Vector3(k1[1]["hips"]), x))
	return anim

## The left hand holds something in this animation (two hands or the bow).
func holds_left(a: Dictionary) -> bool:
	var poses: Array = []
	if a.has("segura"):
		poses.append(a["segura"])
	for key in a.get("keys", []):
		poses.append(key[1])
	for pose in poses:
		if pose.has("duas_maos") or pose.has("arma_e"):
			return true
	return a["name"] in ["golpe_katana"]

## Constant finger curl tracks (replacing any the source had).
func fingers(anim: Animation, dst: Node3D, sk_t: Skeleton3D, right: Array, left: Array) -> void:
	var skel_path: String = str(dst.get_path_to(sk_t))
	for side in [["Right", right, 1.0], ["Left", left, -1.0]]:
		for j in 3:
			var bone: String = "mixamorig_%sHandIndex%d" % [side[0], j + 1]
			var b: int = sk_t.find_bone(bone)
			if b < 0:
				continue
			var path := NodePath("%s:%s" % [skel_path, bone])
			var old: int = anim.find_track(path, Animation.TYPE_ROTATION_3D)
			if old >= 0:
				anim.remove_track(old)
			var t: int = anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(t, path)
			var q: Quaternion = sk_t.get_bone_rest(b).basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, deg_to_rad(float(side[1][j])) * float(side[2]))
			anim.rotation_track_insert_key(t, 0.0, q)
			anim.rotation_track_insert_key(t, anim.length, q)

func build(id: String, spec: Dictionary, out: String) -> void:
	var dst: Node3D = load(spec["model"]).instantiate()
	dst.name = id
	root.add_child(dst)
	await process_frame
	var sk_t: Skeleton3D = dst.find_children("*", "Skeleton3D", true, false)[0]
	for old in dst.find_children("*", "AnimationPlayer", true, false):
		old.get_parent().remove_child(old)
		old.free()
	var lib := AnimationLibrary.new()
	for a in SETS[spec["set"]]:
		var anim: Animation = written(a, dst, sk_t) if a["src"] == "pose" else bake(a, dst, sk_t)
		if anim and spec["set"] == "aventureiro":
			fingers(anim, dst, sk_t, FIST, FIST if holds_left(a) else RELAXED_HAND)
		if anim:
			lib.add_animation(a["name"], anim)
			print("BAKED|%s|%s|%.2f s" % [id, a["name"], anim.length])
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	dst.add_child(player)
	player.owner = dst
	player.add_animation_library("", lib)
	if spec.get("texture", "") != "":
		var mat := StandardMaterial3D.new()
		mat.resource_name = id
		mat.albedo_texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(spec["texture"])))
		mat.roughness = 0.95
		for m in dst.find_children("*", "MeshInstance3D", true, false):
			for s in m.mesh.get_surface_count():
				m.mesh.surface_set_material(s, mat)
	for n in dst.find_children("*", "", true, false):
		if n.owner == null and n != dst:
			n.owner = dst
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err: int = doc.append_from_scene(dst, state)
	if err == OK:
		err = doc.write_to_filesystem(state, "%s/%s.glb" % [out, id])
	print("EXPORT|%s|err=%d" % [id, err])
	var table: Dictionary = {}
	var path: String = out + "/animacoes.json"
	if FileAccess.file_exists(path):
		table = JSON.parse_string(FileAccess.get_file_as_string(path))
	var mine: Dictionary = {}
	for name in impacts:
		mine[name] = snappedf(impacts[name], 0.01)
	table[id] = mine
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(table, " ", true))
	f.close()
	impacts.clear()
	dst.queue_free()

## The target put in the source's reference pose: world transforms per bone.
func matched_reference(sk_t: Skeleton3D, src: Dictionary, pairs: Dictionary) -> Array:
	var sk_s: Skeleton3D = src["sk"]
	var out: Array = []
	out.resize(sk_t.get_bone_count())
	for b in sk_t.get_bone_count():
		var parent: int = sk_t.get_bone_parent(b)
		var parent_world: Transform3D = sk_t.global_transform if parent < 0 else out[parent]
		var w: Transform3D = parent_world * sk_t.get_bone_rest(b)
		var bname: String = sk_t.get_bone_name(b)
		if ALIGN.has(bname) and pairs.has(b):
			var child: int = sk_t.find_bone(ALIGN[bname])
			if child >= 0 and pairs.has(child):
				var d_t: Vector3 = ((w * sk_t.get_bone_rest(child)).origin - w.origin).normalized()
				var d_s: Vector3 = (src["ref"][pairs[child]].origin - src["ref"][pairs[b]].origin).normalized()
				if d_t.length() > 0.5 and d_s.length() > 0.5 and d_t.dot(d_s) < 0.9999:
					var q := Quaternion(d_t, d_s)
					w = Transform3D(Basis(q) * w.basis, w.origin)
		out[b] = w
	return out

## One animation for the target rig, sampled at FPS.
func bake(a: Dictionary, dst: Node3D, sk_t: Skeleton3D) -> Animation:
	var src: Dictionary = source(a["src"], a["anim"])
	var sk_s: Skeleton3D = src["sk"]
	var ap_s: AnimationPlayer = src["ap"]
	var anim_name: String = a["anim"] if a["src"] == "ual" else ap_s.get_animation_list()[0]
	if not ap_s.has_animation(anim_name):
		print("MISSING|", anim_name)
		return null
	var anim_s: Animation = ap_s.get_animation(anim_name)
	var t0: float = float(a.get("from", 0.0))
	var t1: float = float(a.get("to", anim_s.length))
	if t1 <= 0.0 or t1 > anim_s.length:
		t1 = anim_s.length
	var speed: float = float(a.get("speed", 1.0))
	var length: float = (t1 - t0) / speed
	var map: Dictionary = src["map"]
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if a.get("loop", false) else Animation.LOOP_NONE
	var skel_path: String = str(dst.get_path_to(sk_t))
	var tracks: Dictionary = {}
	var pairs: Dictionary = {}
	for b in sk_t.get_bone_count():
		var tname: String = sk_t.get_bone_name(b)
		var sname: String = map.get(tname, tname) if not map.is_empty() else tname
		var sb: int = sk_s.find_bone(sname)
		if sb < 0:
			continue
		pairs[b] = sb
		var t: int = anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(t, "%s:%s" % [skel_path, tname])
		tracks[b] = t
	var hips: int = sk_t.find_bone("mixamorig_Hips")
	var s_hips: int = pairs.get(hips, -1)
	var tref: Array = matched_reference(sk_t, src, pairs)
	var pos_track: int = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos_track, "%s:mixamorig_Hips" % skel_path)
	var k: float = world(sk_t, hips, true).origin.y / maxf(0.01, src["ref"][s_hips].origin.y)
	var frames: int = maxi(1, ceili(length * FPS))
	var rhand: int = sk_t.find_bone("mixamorig_RightHand")
	var best_reach: float = -INF
	var best_time: float = 0.0
	ap_s.play(anim_name)
	var hold: Vector3 = a.get("pega", Vector3.ZERO)
	for f in frames + 1:
		var time: float = minf(f / FPS, length)
		ap_s.seek(t0 + time * speed, true)
		sk_s.force_update_all_bone_transforms()
		var world_t: Array = []
		world_t.resize(sk_t.get_bone_count())
		var locals: Array = []
		locals.resize(sk_t.get_bone_count())
		var hips_local: Vector3 = sk_t.get_bone_rest(hips).origin
		for b in sk_t.get_bone_count():
			var parent: int = sk_t.get_bone_parent(b)
			var parent_world: Transform3D = sk_t.global_transform if parent < 0 else world_t[parent]
			var rest_local: Transform3D = sk_t.get_bone_rest(b)
			if pairs.has(b):
				var sb: int = pairs[b]
				var pose_w: Transform3D = world(sk_s, sb, false)
				var ref_w: Transform3D = src["ref"][sb]
				var delta: Basis = pose_w.basis.orthonormalized() * ref_w.basis.orthonormalized().inverse()
				var target_basis: Basis = delta * tref[b].basis.orthonormalized()
				var origin: Vector3 = (parent_world * rest_local).origin
				if b == hips:
					origin = world(sk_t, hips, true).origin + (pose_w.origin - ref_w.origin) * k
					hips_local = parent_world.affine_inverse() * origin
				world_t[b] = Transform3D(target_basis, origin)
				locals[b] = (parent_world.basis.orthonormalized().inverse() * target_basis).get_rotation_quaternion()
			else:
				world_t[b] = parent_world * rest_local
				locals[b] = rest_local.basis.get_rotation_quaternion()
		if a.has("segura"):
			var held: Dictionary = make_pose({"locals": locals, "hips": hips_local}, a["segura"], sk_t, hold)
			locals = held["locals"]
			world_t = held["world"]
		for b in tracks:
			anim.rotation_track_insert_key(tracks[b], time, locals[b])
		anim.position_track_insert_key(pos_track, time, hips_local)
		var reach: float = world_t[rhand].origin.z - world_t[hips].origin.z + 0.5 * world_t[rhand].origin.y
		if reach > best_reach:
			best_reach = reach
			best_time = time
	var hit = a.get("impacto", "")
	if hit is String and hit == "auto":
		impacts[a["name"]] = best_time / maxf(0.001, length)
	elif hit is float or hit is int:
		# Seconds into the trimmed source clip.
		impacts[a["name"]] = float(hit) / (t1 - t0)
	return anim
