extends SceneTree
# Renders inventory icons from the game's own 3D models.
# Needs a display (real or virtual) and the Compatibility renderer:
#   godot --path . --rendering-driver opengl3 -s res://tools/render_icons.gd
# Output: res://assets/ui/icones/<id>.png (transparent, 128 px, dark outline).

const SIZE: int = 128
const OUT: String = "res://assets/ui/icones"
# Framing per model: [rotation in degrees, framing margin, camera pitch].
const FRAMING = {
	"espada": [Vector3(0, 0, -45), 1.06, 35.0],
	"lanca": [Vector3(0, 0, -45), 1.04, 35.0],
	"vaso": [Vector3(0, 20, 0), 1.30, 28.0],
	"bandagem": [Vector3(0, 30, 0), 1.25, 40.0],
	"rochas": [Vector3(0, 35, 0), 1.08, 55.0],
	"moeda": [Vector3(58, 0, -15), 1.22, 25.0],
	"selo": [Vector3(0, 25, 0), 1.25, 34.0],
	"bau": [Vector3(0, 30, 0), 1.18, 30.0],
	"saco": [Vector3(0, 20, 0), 1.25, 30.0],
}
const ALIASES = {"weapon-sword": "espada", "weapon-spear": "lanca", "pot": "vaso", "potion": "bandagem", "rocks": "rochas", "coin": "moeda", "key": "selo"}

## Every catalog item plus the two container kinds: [id, model name, framing].
## Items use Visuals.item_model (made-for-it .glb, block model or shared model);
## "icon_view" in the item data overrides the framing.
func entries() -> Array:
	var out: Array = [["container_chest", "bau", FRAMING["bau"]], ["container_sack", "saco", FRAMING["saco"]]]
	for id in Items.DATA:
		var data: Dictionary = Items.DATA[id]
		var model: String = ALIASES.get(data["model"], data["model"])
		var framing: Array = FRAMING.get(model, [Vector3(0, 0, -45), 1.06, 35.0] if data.get("tag", "") in ["ARMA", "MUNICAO"] else [Vector3.ZERO, 1.2, 30.0])
		if data.has("icon_view"):
			var v: Dictionary = data["icon_view"]
			framing = [Vector3(v["rot"][0], v["rot"][1], v["rot"][2]), float(v.get("margin", 1.06)), float(v.get("pitch", 35.0))]
		out.append([id, model, framing])
	return out

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	render_all()

func mesh_bounds(node: Node, acc: Array) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var box: AABB = node.global_transform * node.mesh.get_aabb()
		acc.append(box)
	for child in node.get_children():
		mesh_bounds(child, acc)

func render_all() -> void:
	for item in entries():
		var id: String = item[0]
		var framing: Array = item[2]
		var entry: Array = [item[1], framing[0], framing[1], framing[2]]
		var viewport := SubViewport.new()
		viewport.size = Vector2i(SIZE, SIZE)
		viewport.transparent_bg = true
		viewport.own_world_3d = true
		viewport.msaa_3d = Viewport.MSAA_4X
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var env := WorldEnvironment.new()
		var environment := Environment.new()
		environment.background_mode = Environment.BG_CLEAR_COLOR
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color("c9c4b6")
		environment.ambient_light_energy = 0.75
		environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.environment = environment
		viewport.add_child(env)
		var key := DirectionalLight3D.new()
		key.rotation_degrees = Vector3(-50, -35, 0)
		key.light_energy = 1.05
		key.light_color = Color("fff1d8")
		viewport.add_child(key)
		var rim := DirectionalLight3D.new()
		rim.rotation_degrees = Vector3(-20, 150, 0)
		rim.light_energy = 0.45
		rim.light_color = Color("b8c8d8")
		viewport.add_child(rim)
		var holder := Node3D.new()
		viewport.add_child(holder)
		var model: Node3D = Visuals.item_model(id) if Items.DATA.has(id) else load("res://assets/originais/%s.glb" % entry[0]).instantiate()
		holder.add_child(model)
		holder.rotation_degrees = entry[1]
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		viewport.add_child(camera)
		await process_frame
		var boxes: Array = []
		mesh_bounds(holder, boxes)
		var bounds: AABB = boxes[0]
		for box in boxes:
			bounds = bounds.merge(box)
		var center: Vector3 = bounds.get_center()
		var pitch: float = deg_to_rad(entry[3])
		var direction := Vector3(0, sin(pitch), cos(pitch)).normalized()
		camera.look_at_from_position(center + direction * 10.0, center, Vector3.UP)
		# Fit the projected bounds in the frame.
		var extent: float = 0.0
		var basis := camera.global_transform.basis
		for i in 8:
			var corner: Vector3 = bounds.get_endpoint(i) - center
			extent = maxf(extent, absf(corner.dot(basis.x)))
			extent = maxf(extent, absf(corner.dot(basis.y)))
		camera.size = extent * 2.0 * entry[2]
		camera.near = 0.05
		camera.far = 40.0
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = viewport.get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		outline(image, 3, Color(0.04, 0.035, 0.03, 0.92))
		image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, id]))
		print("ICON ", id)
		viewport.queue_free()
	quit()

func outline(image: Image, radius: int, color: Color) -> void:
	var w: int = image.get_width()
	var h: int = image.get_height()
	var source: Image = image.duplicate()
	for y in h:
		for x in w:
			var here: Color = source.get_pixel(x, y)
			if here.a >= 0.6:
				continue
			var best: float = 0.0
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					if dx * dx + dy * dy > radius * radius:
						continue
					var sx: int = x + dx
					var sy: int = y + dy
					if sx < 0 or sy < 0 or sx >= w or sy >= h:
						continue
					best = maxf(best, source.get_pixel(sx, sy).a)
			if best > 0.0:
				var edge := Color(color.r, color.g, color.b, color.a * best)
				image.set_pixel(x, y, edge.blend(here) if here.a > 0.0 else edge)
