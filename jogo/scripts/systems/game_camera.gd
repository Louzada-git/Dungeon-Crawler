extends Node3D
class_name GameCamera
## Orthographic isometric camera that follows a target, with zoom and a short shake.

const MIN_ZOOM := 13.0
const MAX_ZOOM := 27.0
var camera: Camera3D
var target: Node3D
var zoom: float = 16.0
var shake: float = 0.0
var strength: float = 0.0

func _ready() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = zoom
	camera.position = Vector3(12, 9.798, 12)
	camera.look_at_from_position(camera.position, Vector3.ZERO)
	camera.far = 100
	camera.current = true
	snap()

func snap() -> void:
	if target:
		position = target.position

func zoom_by(amount: float) -> void:
	zoom = clampf(zoom + amount, MIN_ZOOM, MAX_ZOOM)

func impact(value: float) -> void:
	shake = 0.16
	strength = value

func _process(delta: float) -> void:
	if target == null:
		return
	position = position.lerp(target.position, 1.0 - exp(-delta * 9))
	camera.size = lerpf(camera.size, zoom, 1.0 - exp(-delta * 10))
	shake = maxf(0, shake - delta)
	var amount: float = strength * shake / 0.16
	camera.h_offset = sin(shake * 180) * amount
	camera.v_offset = cos(shake * 155) * amount * 0.6
