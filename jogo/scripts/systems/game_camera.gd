extends Node3D
class_name GameCamera
## The game camera, in one of two modes (choice in the pause menu, saved in the
## user settings):
## - "iso": orthographic isometric camera that follows a target, with zoom;
## - "terceira": third person, behind the character, turned by the mouse, on a
##   spring arm that stops at walls so the camera never goes through them.
## Both keep the short shake of impacts.

const MIN_ZOOM := 13.0
const MAX_ZOOM := 27.0
const ISO := "iso"
const THIRD := "terceira"
## Third person: arm length limits (wheel), pivot height, look limits.
const MIN_ARM := 2.0
const MAX_ARM := 6.0
const PIVOT_HEIGHT := 1.55
const MIN_PITCH := -1.15
const MAX_PITCH := 0.35

var mode: String = ISO
## Active camera (the iso one or the third-person one).
var camera: Camera3D
var iso_camera: Camera3D
var third_camera: Camera3D
var target: Node3D
var zoom: float = 16.0
var shake: float = 0.0
var strength: float = 0.0
## Third person: turn (yaw), look up/down (pitch), arm length and mouse speed.
var yaw: float = PI * 0.25
var pitch: float = -0.26
var arm_length: float = 3.3
var sensitivity: float = 0.0035
var yaw_node: Node3D
var pitch_node: Node3D
var arm: SpringArm3D

func _ready() -> void:
	iso_camera = Camera3D.new()
	add_child(iso_camera)
	iso_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	iso_camera.size = zoom
	iso_camera.position = Vector3(12, 9.798, 12)
	iso_camera.look_at_from_position(iso_camera.position, Vector3.ZERO)
	iso_camera.far = 100
	# Third person: pivot at shoulder height, turned by yaw and pitch, camera at the end of the arm.
	yaw_node = Node3D.new()
	yaw_node.name = "Giro"
	add_child(yaw_node)
	yaw_node.position.y = PIVOT_HEIGHT
	pitch_node = Node3D.new()
	pitch_node.name = "Inclinacao"
	yaw_node.add_child(pitch_node)
	arm = SpringArm3D.new()
	arm.name = "Braco"
	arm.collision_mask = 1
	arm.margin = 0.25
	var probe := SphereShape3D.new()
	probe.radius = 0.25
	arm.shape = probe
	pitch_node.add_child(arm)
	# A little over the right shoulder, so the character does not hide the aim.
	arm.position = Vector3(0.45, 0.0, 0.0)
	third_camera = Camera3D.new()
	third_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	third_camera.fov = 68.0
	third_camera.near = 0.08
	third_camera.far = 90.0
	arm.add_child(third_camera)
	set_mode(mode)
	snap()

## Switches between "iso" and "terceira"; the active camera becomes current.
func set_mode(value: String) -> void:
	mode = THIRD if value == THIRD else ISO
	camera = third_camera if mode == THIRD else iso_camera
	if is_inside_tree():
		camera.current = true
	_apply_third()

func third_person() -> bool:
	return mode == THIRD

func _apply_third() -> void:
	if yaw_node == null:
		return
	yaw_node.rotation.y = yaw
	pitch_node.rotation.x = pitch
	arm.spring_length = arm_length

## Ground direction the camera looks at (for walking, aiming and blows in third person).
func forward() -> Vector3:
	if mode == THIRD:
		return Vector3(-sin(yaw), 0, -cos(yaw))
	return Vector3(-1, 0, -1).normalized()

func right() -> Vector3:
	var f: Vector3 = forward()
	return Vector3(-f.z, 0, f.x)

## Walking direction for the input axis (x right, y down/back), on the ground.
func move_direction(axis: Vector2) -> Vector3:
	if mode == THIRD:
		return (right() * axis.x - forward() * axis.y).normalized()
	return Vector3(axis.x + axis.y, 0, axis.y - axis.x).normalized()

## Mouse motion while the cursor is captured (third person).
func look(relative: Vector2) -> void:
	yaw -= relative.x * sensitivity
	pitch = clampf(pitch - relative.y * sensitivity, MIN_PITCH, MAX_PITCH)
	_apply_third()

## Faces the camera behind a direction (used when switching to third person).
func look_along(direction: Vector3) -> void:
	direction.y = 0
	if direction.length() < 0.01:
		return
	direction = direction.normalized()
	yaw = atan2(-direction.x, -direction.z)
	_apply_third()

func snap() -> void:
	if target:
		position = target.position

func zoom_by(amount: float) -> void:
	if mode == THIRD:
		arm_length = clampf(arm_length + amount * 0.3, MIN_ARM, MAX_ARM)
		_apply_third()
	else:
		zoom = clampf(zoom + amount, MIN_ZOOM, MAX_ZOOM)

func impact(value: float) -> void:
	shake = 0.16
	strength = value

func _process(delta: float) -> void:
	if target == null:
		return
	position = position.lerp(target.position, 1.0 - exp(-delta * (14.0 if mode == THIRD else 9.0)))
	iso_camera.size = lerpf(iso_camera.size, zoom, 1.0 - exp(-delta * 10))
	shake = maxf(0, shake - delta)
	var amount: float = strength * shake / 0.16 * (0.5 if mode == THIRD else 1.0)
	camera.h_offset = sin(shake * 180) * amount
	camera.v_offset = cos(shake * 155) * amount * 0.6
