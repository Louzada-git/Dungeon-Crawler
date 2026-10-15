extends Node
class_name PsxFilter
## PlayStation-style look, applied on top of the normal scene:
## - post-process below the HUD: the frame is sampled in big pixels (about LINES
##   rows), reduced to 15-bit colour with 4×4 ordered dithering;
## - opaque materials swap to a shader that snaps vertices to the same coarse
##   grid (the PS1 wobble) and reads textures without smoothing.
## The HUD stays sharp. Turning it off restores every original material.

const LINES: float = 300.0
const COLOR_LEVELS: float = 32.0

const POST_SHADER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float pixel_size = 3.0;
uniform float levels = 32.0;
uniform bool dither = true;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void fragment() {
	vec2 cell = SCREEN_PIXEL_SIZE * pixel_size;
	vec2 block = floor(SCREEN_UV / cell);
	// Average the block (like rendering at low resolution) so thin lines in
	// textures do not break into random dots.
	int taps = int(clamp(pixel_size, 1.0, 4.0));
	vec3 c = vec3(0.0);
	for (int y = 0; y < taps; y++) {
		for (int x = 0; x < taps; x++) {
			vec2 offset = (vec2(float(x), float(y)) + 0.5) / float(taps);
			c += texture(screen, (block + offset) * cell).rgb;
		}
	}
	c /= float(taps * taps);
	if (dither) {
		ivec2 p = ivec2(mod(block, 4.0));
		c += (BAYER[p.y * 4 + p.x] / 16.0 - 0.47) / (levels - 1.0);
	}
	c = floor(clamp(c, 0.0, 1.0) * (levels - 1.0) + 0.5) / (levels - 1.0);
	COLOR = vec4(c, 1.0);
}
"""

const SURFACE_SHADER := """
shader_type spatial;
render_mode CULL_MODE;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform bool use_vertex_color = false;
uniform float roughness = 1.0;
uniform float metallic = 0.0;
uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);
uniform float snap_lines = 300.0;
void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 grid = vec2(snap_lines * VIEWPORT_SIZE.x / max(VIEWPORT_SIZE.y, 1.0), snap_lines) * 0.5;
	clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	POSITION = clip;
}
void fragment() {
	vec4 c = albedo;
	if (use_texture) {
		c *= texture(albedo_texture, UV);
	}
	if (use_vertex_color) {
		c *= COLOR;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = emission * emission_energy;
}
"""

var enabled: bool = true
var layer: CanvasLayer
var screen: ColorRect
var post: ShaderMaterial
var _shaders: Dictionary = {}
## Original material id -> PSX copy (shared like the original).
var _converted: Dictionary = {}
var _pending: Array = []
## Text in the world (monster health, signs) would turn into smudges in big
## pixels: while the filter is on each Label3D is hidden from the camera and
## drawn as a sharp 2D label above the filter, at its projected position.
var overlay: Control
var _labels: Dictionary = {}

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	screen = ColorRect.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = POST_SHADER
	post = ShaderMaterial.new()
	post.shader = shader
	screen.material = post
	layer.add_child(screen)
	overlay = Control.new()
	overlay.name = "RotulosDoMundo"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	get_viewport().size_changed.connect(_update_scale)
	_update_scale()
	screen.visible = enabled

## Pixel size that keeps roughly LINES rows on any window height.
func pixel_size() -> float:
	var h: float = float(get_viewport().get_visible_rect().size.y)
	return maxf(1.0, roundf(h / LINES))

func _update_scale() -> void:
	if post:
		post.set_shader_parameter("pixel_size", pixel_size())

func set_enabled(on: bool) -> void:
	if on == enabled:
		return
	enabled = on
	if screen:
		screen.visible = on
	for node in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		if on:
			apply(node)
		else:
			restore(node)

func _on_node_added(node: Node) -> void:
	if node is GeometryInstance3D:
		# Meshes and materials are often assigned right after add_child.
		if _pending.is_empty():
			_flush.call_deferred()
		_pending.append(node)

func _flush() -> void:
	var nodes: Array = _pending
	_pending = []
	if not enabled:
		return
	for node in nodes:
		if is_instance_valid(node) and node.is_inside_tree():
			apply(node)

## Swaps the opaque, lit materials of one mesh for their PSX copies.
func apply(node: Node) -> void:
	if not node is GeometryInstance3D:
		return
	if node is Label3D:
		_lift(node)
		return
	var geo: GeometryInstance3D = node
	if geo.material_override != null:
		var swapped: Material = psx_material(geo.material_override)
		if swapped != geo.material_override:
			if not geo.has_meta("psx_override"):
				geo.set_meta("psx_override", geo.material_override)
			geo.material_override = swapped
		return
	if geo is MultiMeshInstance3D:
		_apply_multimesh(geo)
		return
	if not geo is MeshInstance3D or geo.mesh == null:
		return
	var mesh_node: MeshInstance3D = geo
	var originals: Array = mesh_node.get_meta("psx_surfaces", [])
	var record: bool = originals.is_empty()
	for i in mesh_node.mesh.get_surface_count():
		var current: Material = mesh_node.get_surface_override_material(i)
		var source: Material = current if current != null else mesh_node.mesh.surface_get_material(i)
		if record:
			originals.append(current)
		if source == null:
			continue
		var swapped: Material = psx_material(source)
		if swapped != source:
			mesh_node.set_surface_override_material(i, swapped)
	if record:
		mesh_node.set_meta("psx_surfaces", originals)

## Batched tiles keep their materials in the mesh: swap in a copy of the mesh
## whose surfaces use the PSX materials (one copy per original mesh).
var _meshes: Dictionary = {}

func _apply_multimesh(geo: MultiMeshInstance3D) -> void:
	if geo.multimesh == null or geo.multimesh.mesh == null or geo.has_meta("psx_mesh"):
		return
	var source: Mesh = geo.multimesh.mesh
	var key: int = source.get_instance_id()
	if not _meshes.has(key):
		var copy: Mesh = source
		if source is ArrayMesh:
			copy = source.duplicate()
			for i in copy.get_surface_count():
				var mat: Material = copy.surface_get_material(i)
				if mat != null:
					copy.surface_set_material(i, psx_material(mat))
		_meshes[key] = copy
	if _meshes[key] != source:
		geo.set_meta("psx_mesh", source)
		geo.multimesh.mesh = _meshes[key]

func restore(node: Node) -> void:
	if not node is GeometryInstance3D:
		return
	if node is Label3D:
		_drop(node)
		return
	var geo: GeometryInstance3D = node
	if geo is MultiMeshInstance3D and geo.has_meta("psx_mesh"):
		geo.multimesh.mesh = geo.get_meta("psx_mesh")
		geo.remove_meta("psx_mesh")
	if geo.has_meta("psx_override"):
		geo.material_override = geo.get_meta("psx_override")
		geo.remove_meta("psx_override")
	if geo is MeshInstance3D and geo.has_meta("psx_surfaces"):
		var originals: Array = geo.get_meta("psx_surfaces")
		for i in mini(originals.size(), geo.get_surface_override_material_count()):
			geo.set_surface_override_material(i, originals[i])
		geo.remove_meta("psx_surfaces")

## Opaque lit StandardMaterial3D -> PSX ShaderMaterial (cached); anything else
## (transparent rings, unshaded markers, already converted) stays as it is.
func psx_material(source: Material) -> Material:
	if not source is BaseMaterial3D:
		return source
	var m: BaseMaterial3D = source
	if m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or m.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL or m.no_depth_test or m.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return source
	var key: int = m.get_instance_id()
	if _converted.has(key):
		return _converted[key]
	var copy := ShaderMaterial.new()
	copy.shader = _shader_for(m.cull_mode)
	copy.set_shader_parameter("albedo", m.albedo_color)
	copy.set_shader_parameter("use_texture", m.albedo_texture != null)
	if m.albedo_texture != null:
		copy.set_shader_parameter("albedo_texture", m.albedo_texture)
	copy.set_shader_parameter("use_vertex_color", m.vertex_color_use_as_albedo)
	copy.set_shader_parameter("roughness", m.roughness)
	copy.set_shader_parameter("metallic", m.metallic)
	if m.emission_enabled:
		copy.set_shader_parameter("emission", m.emission)
		copy.set_shader_parameter("emission_energy", m.emission_energy_multiplier)
	copy.set_shader_parameter("uv1_scale", m.uv1_scale)
	copy.set_shader_parameter("uv1_offset", m.uv1_offset)
	copy.set_shader_parameter("snap_lines", LINES)
	copy.set_meta("psx_source", m)
	_converted[key] = copy
	return copy

func _shader_for(cull: int) -> Shader:
	if not _shaders.has(cull):
		var mode: String = {BaseMaterial3D.CULL_BACK: "cull_back", BaseMaterial3D.CULL_FRONT: "cull_front", BaseMaterial3D.CULL_DISABLED: "cull_disabled"}.get(cull, "cull_back")
		var shader := Shader.new()
		shader.code = SURFACE_SHADER.replace("CULL_MODE", mode)
		_shaders[cull] = shader
	return _shaders[cull]

# --- world text ----------------------------------------------------------------

func _lift(label: Label3D) -> void:
	var key: int = label.get_instance_id()
	if _labels.has(key) or overlay == null:
		return
	label.set_meta("psx_layers", label.layers)
	label.layers = 0
	var flat := Label.new()
	flat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if label.font != null:
		flat.add_theme_font_override("font", label.font)
	overlay.add_child(flat)
	_labels[key] = {"label": label, "flat": flat, "size": 0}

func _drop(label: Label3D) -> void:
	var key: int = label.get_instance_id()
	if not _labels.has(key):
		return
	_labels[key]["flat"].queue_free()
	_labels.erase(key)
	if label.has_meta("psx_layers"):
		label.layers = label.get_meta("psx_layers")
		label.remove_meta("psx_layers")

## Screen size in pixels of text that is `height` metres tall.
func text_pixels(height: float, camera: Camera3D, at: Vector3 = Vector3.ZERO) -> int:
	var view: float = float(get_viewport().get_visible_rect().size.y)
	var world: float = camera.size
	if camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		# Perspective (third person): height the view covers at that distance.
		var distance: float = maxf(0.5, camera.global_position.distance_to(at))
		world = 2.0 * distance * tan(deg_to_rad(camera.fov) * 0.5)
	return clampi(roundi(height * view / maxf(world, 0.01)), 9, 40)

func _process(_delta: float) -> void:
	if _labels.is_empty():
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	for key in _labels.keys():
		var entry: Dictionary = _labels[key]
		var label = entry["label"]
		var flat: Label = entry["flat"]
		if not is_instance_valid(label):
			flat.queue_free()
			_labels.erase(key)
			continue
		var show: bool = enabled and camera != null and label.is_visible_in_tree() and label.text != "" and not camera.is_position_behind(label.global_position)
		# Third person (perspective): a wall between the camera and the text hides it.
		if show and camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
			var query := PhysicsRayQueryParameters3D.create(camera.global_position, label.global_position, 1)
			show = camera.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
		flat.visible = show
		if not show:
			continue
		var px: int = text_pixels(label.font_size * label.pixel_size, camera, label.global_position)
		if px != entry["size"]:
			entry["size"] = px
			flat.add_theme_font_size_override("font_size", px)
			flat.add_theme_constant_override("outline_size", maxi(1, roundi(px * float(label.outline_size) / maxf(label.font_size, 1.0))))
		flat.text = label.text
		flat.add_theme_color_override("font_color", label.modulate)
		flat.add_theme_color_override("font_outline_color", label.outline_modulate)
		flat.size = flat.get_combined_minimum_size()
		flat.position = (camera.unproject_position(label.global_position) - flat.size * 0.5).round()
