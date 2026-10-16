extends RefCounted
class_name Vfx
## Short visual effects (blood, impacts, sparks, dust, smoke) and the torch
## flames. Each effect is a quad facing the camera whose shader picks the frame
## of a sheet in assets/vfx (cut from the Brackeys VFX Bundle, CC0, by
## arte/fontes/vfx/preparar_vfx.py). Sheets are small and read without
## smoothing, so they match the PSX filter; data/efeitos.json sets size, speed,
## colour and blending. One-shot effects free themselves when the sheet ends.

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, BLEND;
uniform sampler2D sheet : source_color, filter_nearest;
uniform vec2 grid = vec2(1.0);
uniform float frames = 1.0;
uniform float frame = 0.0;
uniform float fps = 0.0;
uniform bool vertical = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float fade = 1.0;
void vertex() {
	vec3 s = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	if (vertical) {
		vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz));
		vec3 back = normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0)));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right * s.x, 0.0), vec4(0.0, s.y, 0.0, 0.0), vec4(back * s.z, 0.0), MODEL_MATRIX[3]);
	} else {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s.x, INV_VIEW_MATRIX[1] * s.y, INV_VIEW_MATRIX[2] * s.z, MODEL_MATRIX[3]);
	}
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	float f;
	if (fps > 0.0) {
		// Looping (torches): each one starts at its own frame, from its position.
		float phase = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233))) * 43758.5453) * frames;
		f = mod(floor(TIME * fps + phase), frames);
	} else {
		f = clamp(floor(frame), 0.0, frames - 1.0);
	}
	UV = (UV + vec2(mod(f, grid.x), floor(f / grid.x))) / grid;
}
void fragment() {
	vec4 c = texture(sheet, UV) * tint;
	ALBEDO = c.rgb;
	ALPHA = c.a * fade;
}
"""

static var SHEETS: Dictionary = _read("res://assets/vfx/folhas.json").get("folhas", {})
static var EFFECTS: Dictionary = _read("res://data/efeitos.json").get("efeitos", {})
static var _shaders: Dictionary = {}
static var _materials: Dictionary = {}
static var _quads: Dictionary = {}
static var _rng := RandomNumberGenerator.new()

static func _read(path: String) -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return raw if raw is Dictionary else {}

static func info(id: String) -> Dictionary:
	return EFFECTS.get(id, {})

static func sheet_of(id: String) -> Dictionary:
	return SHEETS.get(str(info(id).get("folha", "")), {})

## Seconds a one-shot effect lasts (its frames at its speed).
static func duration(id: String) -> float:
	return float(sheet_of(id).get("quadros", 1)) / maxf(1.0, float(info(id).get("fps", 24)))

static func _shader(additive: bool) -> Shader:
	if not _shaders.has(additive):
		var shader := Shader.new()
		shader.code = SHADER.replace("BLEND", "blend_add" if additive else "blend_mix")
		_shaders[additive] = shader
	return _shaders[additive]

## The effect's material (shared by looping effects; one-shot ones copy it).
static func material(id: String) -> ShaderMaterial:
	if _materials.has(id):
		return _materials[id]
	var e: Dictionary = info(id)
	var sheet: Dictionary = sheet_of(id)
	var mat := ShaderMaterial.new()
	mat.shader = _shader(bool(e.get("aditivo", false)))
	mat.set_shader_parameter("sheet", load("res://assets/vfx/%s.png" % str(e.get("folha", ""))))
	mat.set_shader_parameter("grid", Vector2(float(sheet.get("colunas", 1)), float(sheet.get("linhas", 1))))
	mat.set_shader_parameter("frames", float(sheet.get("quadros", 1)))
	mat.set_shader_parameter("fps", float(e.get("fps", 24)) if bool(e.get("repete", false)) else 0.0)
	mat.set_shader_parameter("vertical", bool(e.get("vertical", false)))
	var tint := Color(str(e.get("cor", "ffffff")))
	var light: float = float(e.get("brilho", 1.0))
	tint = Color(tint.r * light, tint.g * light, tint.b * light, float(e.get("alfa", 1.0)))
	mat.set_shader_parameter("tint", tint)
	_materials[id] = mat
	return mat

## Quad with the frame's proportions, `tamanho` metres wide.
static func quad(id: String) -> QuadMesh:
	if not _quads.has(id):
		var sheet: Dictionary = sheet_of(id)
		var width: float = float(info(id).get("tamanho", 1.0))
		var mesh := QuadMesh.new()
		mesh.size = Vector2(width, width * float(sheet.get("altura", 1)) / maxf(1.0, float(sheet.get("largura", 1))))
		_quads[id] = mesh
	return _quads[id]

static func _node(id: String, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "Efeito_" + id
	node.mesh = quad(id)
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.set_meta("efeito", id)
	return node

## Plays effect `id` once at `pos` (world) under `parent` (the game).
## `size` scales it; `tint` multiplies its colour.
static func burst(parent: Node, id: String, pos: Vector3, size: float = 1.0, tint: Color = Color.WHITE) -> MeshInstance3D:
	if parent == null or not parent.is_inside_tree() or not EFFECTS.has(id) or sheet_of(id).is_empty():
		return null
	var e: Dictionary = info(id)
	var mat: ShaderMaterial = material(id).duplicate()
	mat.set_shader_parameter("tint", mat.get_shader_parameter("tint") * tint)
	var node := _node(id, mat)
	node.add_to_group("efeitos")
	node.scale = Vector3.ONE * size
	parent.add_child(node)
	# Toward the camera, so the effect is not swallowed by the body it hits.
	var camera: Camera3D = parent.get_viewport().get_camera_3d()
	var toward: Vector3 = camera.global_transform.basis.z if camera else Vector3.UP
	node.global_position = pos + toward * float(e.get("frente", 0.3))
	var frames: float = float(sheet_of(id).get("quadros", 1))
	var life: float = duration(id)
	var tween := node.create_tween()
	tween.tween_method(func(f: float): mat.set_shader_parameter("frame", f), 0.0, frames, life)
	if float(e.get("sobe", 0.0)) != 0.0:
		tween.parallel().tween_property(node, "position:y", node.position.y + float(e["sobe"]) * size, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if bool(e.get("desvanece", false)):
		tween.parallel().tween_method(func(a: float): mat.set_shader_parameter("fade", a), 1.0, 0.0, life).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(node.queue_free)
	return node

## A looping effect that stays (torch and campfire flames); its base sits at `pos`.
static func flame(parent: Node, pos: Vector3, size: float = 1.0, id: String = "chama") -> MeshInstance3D:
	if not EFFECTS.has(id) or sheet_of(id).is_empty():
		return null
	var node := _node(id, material(id))
	node.add_to_group("chamas")
	node.scale = Vector3.ONE * size
	parent.add_child(node)
	# The flame in the sheet starts a little above the bottom of the frame.
	node.position = pos + Vector3(0, quad(id).size.y * size * 0.38, 0)
	return node

static func jitter(amount: float) -> Vector3:
	return Vector3(_rng.randf_range(-amount, amount), _rng.randf_range(-amount, amount) * 0.6, _rng.randf_range(-amount, amount))

## Chest height of a monster or the adventurer.
static func body_point(body: Node3D, height: float = 1.15) -> Vector3:
	var factor: float = 1.0
	if body is DungeonEnemy:
		factor = float(body.stats.get("scale", 1.0))
	return body.global_position + Vector3(0, height * factor, 0)

## A blow landing on a monster: blood (sparks off armour the weapon does not
## crush), the flash of the hit and, for strong blows, a bigger burst.
static func enemy_hit(game, enemy, strong: bool, through_armor: bool) -> void:
	var at: Vector3 = body_point(enemy) + jitter(0.12)
	if enemy.armored and not through_armor:
		burst(game, "faisca", at)
		burst(game, "gota", at)
	else:
		burst(game, "sangue", at)
	burst(game, "impacto", at, 0.8)
	if strong:
		burst(game, "golpe_forte", at)

## Dust kicked up at the feet (dodge, dash, a blow on the ground).
static func dust(game, pos: Vector3, count: int = 1, spread: float = 0.25, size: float = 1.0) -> void:
	for i in count:
		var offset := jitter(spread)
		offset.y = 0.0
		burst(game, "poeira", pos + offset + Vector3(0, 0.25, 0), size * _rng.randf_range(0.8, 1.15))

## Dust all around a circle (Pancada, Golpe esmagador).
static func dust_ring(game, center: Vector3, radius: float) -> void:
	for i in 7:
		var a: float = TAU * i / 7.0 + _rng.randf_range(-0.2, 0.2)
		burst(game, "poeira", center + Vector3(sin(a), 0, cos(a)) * radius * 0.75 + Vector3(0, 0.25, 0), _rng.randf_range(0.8, 1.2))


## Seconds the blade trail takes to fade (captures hold it longer).
static var trail_time: float = 0.18

## Pale trail of the blade over the swept part of the swing (the same capsules
## the hitbox used), fading quickly.
static func swing_trail(game, samples: Array) -> void:
	if samples.size() < 2:
		return
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1, 1, 1, 0.7)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	var quads: int = 0
	for i in samples.size() - 1:
		var a: Array = samples[i]
		var b: Array = samples[i + 1]
		if (a[1] as Vector3).distance_to(b[1]) > 1.2:
			continue
		var fade0: float = float(i) / (samples.size() - 1)
		var fade1: float = float(i + 1) / (samples.size() - 1)
		var c0 := Color(0.95, 0.93, 0.86, 0.25 + 0.65 * fade0)
		var c1 := Color(0.95, 0.93, 0.86, 0.25 + 0.65 * fade1)
		var in0: Vector3 = (a[0] as Vector3).lerp(a[1], 0.45)
		var in1: Vector3 = (b[0] as Vector3).lerp(b[1], 0.45)
		for v in [[in0, c0], [a[1], c0], [b[1], c1], [in0, c0], [b[1], c1], [in1, c1]]:
			mesh.surface_set_color(v[1])
			mesh.surface_add_vertex(v[0])
		quads += 1
	if quads == 0:
		mesh.surface_add_vertex(Vector3.ZERO)
		mesh.surface_add_vertex(Vector3.ZERO)
		mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.material_override = mat
	game.add_child(node)
	var fade := node.create_tween()
	fade.tween_property(mat, "albedo_color:a", 0.0, trail_time)
	fade.tween_callback(node.queue_free)


## Makes the torch and campfire lights tremble. One per floor; only lights
## near the camera are updated, a few times per second.
class Flicker extends Node:
	const RATE := 1.0 / 15.0
	const NEAR := 26.0
	var lights: Array = []
	var time: float = 0.0
	var wait: float = 0.0

	func add(light: OmniLight3D) -> void:
		light.set_meta("energia", light.light_energy)
		lights.append(light)

	func _process(delta: float) -> void:
		time += delta
		wait -= delta
		if wait > 0.0:
			return
		wait = RATE
		# The camera rig (the camera's parent) sits on the point being looked at.
		var camera: Camera3D = get_viewport().get_camera_3d()
		var rig: Node = camera.get_parent() if camera else null
		var focus: Vector3 = rig.global_position if rig is Node3D else Vector3.ZERO
		for i in lights.size():
			var light: OmniLight3D = lights[i]
			if not is_instance_valid(light):
				continue
			var d: Vector3 = light.global_position - focus
			d.y = 0.0
			if rig is Node3D and d.length() > NEAR:
				continue
			var k: float = 0.86 + 0.09 * sin(time * 7.3 + i * 1.7) + 0.05 * sin(time * 17.9 + i * 3.1)
			light.light_energy = float(light.get_meta("energia")) * k
