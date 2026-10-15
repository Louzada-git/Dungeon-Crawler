extends RefCounted
class_name WorldBuilder
## Builds the 3D scene of a floor from its description: floor and wall tiles
## (as MultiMeshes, so floors with hundreds of rooms stay light), colliders,
## torches, furniture, shelter (with its campfire), stairs and containers.

const FURNITURE_SIZE := {
	"mesa": Vector3(1.4, 0.8, 0.75), "catre": Vector3(0.85, 0.55, 1.95), "banco": Vector3(1.03, 0.48, 0.38),
	"pilar": Vector3(0.49, 2.35, 0.49), "rochas": Vector3(0.9, 0.5, 0.9),
}

static func prop(world: Node3D, id: String, pos: Vector3, rotation: float = 0.0, factor: float = 1.0) -> Node3D:
	var node = Visuals.model(id, factor)
	world.add_child(node)
	node.position = pos
	node.rotation.y = rotation
	return node

static func environment(game) -> void:
	var node := WorldEnvironment.new()
	node.name = "Ambiente"
	var env := Environment.new()
	# Dark depth fog, only in third person (main.set_camera_mode): it hides the far
	# end of long halls and the open sky over the walls.
	env.fog_light_color = Color("161915")
	env.fog_density = 0.045
	env.fog_sky_affect = 0.0
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("161915")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b8b6a5")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	node.environment = env
	game.add_child(node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -35, 0)
	sun.light_color = Color("ded3b8")
	sun.light_energy = 0.70
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70
	game.add_child(sun)

## Removes the current floor: scene, containers and monsters.
static func clear(game) -> void:
	if is_instance_valid(game.world_root):
		game.world_root.queue_free()
	for c in game.containers:
		if is_instance_valid(c.get("node")):
			c["node"].queue_free()
	for e in game.enemies:
		if is_instance_valid(e):
			e.queue_free()
	game.containers.clear()
	game.enemies.clear()
	for shot in game.get_tree().get_nodes_in_group("projeteis"):
		shot.queue_free()

## One MultiMeshInstance3D per model for repeated tiles (`model` when the
## batch has its own name, like the two sets of front walls).
static func _batch(world: Node3D, id: String, transforms: Array, model: String = "") -> MultiMeshInstance3D:
	if transforms.is_empty():
		return null
	var scene: Node3D = Visuals.model(model if model != "" else id, 1.0)
	var mesh_node: MeshInstance3D = null
	for child in scene.get_children():
		if child is MeshInstance3D:
			mesh_node = child
			break
	if mesh_node == null:
		scene.free()
		return null
	var local: Transform3D = mesh_node.transform
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh_node.mesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i] * local)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.name = "Lote_" + id
	if mesh_node.material_override:
		instance.material_override = mesh_node.material_override
	world.add_child(instance)
	scene.free()
	return instance

## Front walls: cut low for the isometric camera (so the room shows), whole in
## third person (the camera is down among them).
static func apply_view(world: Node3D, third_person: bool) -> void:
	if not is_instance_valid(world):
		return
	var low = world.get_node_or_null("Lote_parede_frente_baixa")
	var tall = world.get_node_or_null("Lote_parede_frente_alta")
	if low:
		low.visible = not third_person
	if tall:
		tall.visible = third_person

static func build(game) -> void:
	var layout = game.layout
	var world := Node3D.new()
	world.name = "Dungeon"
	game.add_child(world)
	game.world_root = world
	var flicker := Vfx.Flicker.new()
	flicker.name = "LuzesTremulas"
	world.add_child(flicker)
	var extent := Vector3(layout.size.x * DungeonLayout.CELL + 8, 1, layout.size.y * DungeonLayout.CELL + 8)
	Visuals.collider(world, extent, Vector3(extent.x * 0.5 - 4, -0.48, extent.z * 0.5 - 4)).name = "Ground"
	var tiles := {"piso": [], "piso_b": [], "parede": []}
	# Front walls in two versions: low (isometric cutaway) and whole (third person).
	var front_low: Array = []
	var front_tall: Array = []
	var walls: Dictionary = {}
	var room_cells: Dictionary = {}
	for room in layout.rooms:
		var r: Rect2i = room["rect"]
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				room_cells[Vector2i(x, y)] = true
	for cell in layout.floors:
		var center: Vector3 = layout.to_world(cell)
		# Four half-metre slabs per model, 4 models per navigation cell.
		for x in [-0.5, 0.5]:
			for z in [-0.5, 0.5]:
				var id: String = "piso_b" if (cell.x * 13 + cell.y * 7) % 5 == 0 else "piso"
				tiles[id].append(Transform3D(Basis(), center + Vector3(x, 0, z)))
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var adjacent: Vector2i = cell + offset
			if layout.is_floor(adjacent):
				continue
			walls[adjacent] = true
			var basis := Basis(Vector3.UP, PI / 2 if offset.x != 0 else 0.0)
			var at := center + Vector3(offset.x, 0, offset.y)
			# Keep foreground cutaways while back walls retain human-scale height.
			if offset.x > 0 or offset.y > 0:
				front_low.append(Transform3D(basis.scaled(Vector3(1, 0.19, 1)), at))
				front_tall.append(Transform3D(basis, at))
				continue
			if (cell.x + cell.y) % 5 == 0 and room_cells.has(cell):
				torch(world, center + Vector3(offset.x * 0.75, 1.24, offset.y * 0.75))
			tiles["parede"].append(Transform3D(basis, at))
	for id in tiles:
		_batch(world, id, tiles[id])
	_batch(world, "parede_frente_baixa", front_low, "parede")
	_batch(world, "parede_frente_alta", front_tall, "parede")
	apply_view(world, game.camera_rig != null and game.camera_rig.third_person())
	var body := StaticBody3D.new()
	body.name = "Paredes"
	world.add_child(body)
	var box := BoxShape3D.new()
	box.size = Vector3(2, 3, 2)
	for cell in walls:
		var shape := CollisionShape3D.new()
		shape.shape = box
		shape.position = layout.to_world(cell) + Vector3(0, 1.5, 0)
		body.add_child(shape)
	# Furniture is placed against room boundaries, outside the navigation lane.
	for entry in layout.world["furniture"]:
		var cell: Vector2i = DungeonLayout.cell(entry["cell"])
		var at: Vector3 = layout.to_world(cell)
		var id: String = entry["model"]
		var turn: float = deg_to_rad(float(entry.get("rotation", 0.0)))
		prop(world, id, at, turn)
		var size: Vector3 = FURNITURE_SIZE.get(id, Vector3(0.72, 0.8, 0.72))
		if turn != 0.0:
			size = Vector3(size.z, size.y, size.x)
		Visuals.collider(world, size, at + Vector3(0, size.y / 2, 0))
		layout.pathfinder.set_point_solid(cell, true)
		if id == "mesa":
			prop(world, "vaso", at + Vector3(0.3, 0.81, 0))
			prop(world, "saco", at + Vector3(-0.3, 0.81, 0), 0, 0.6)
		elif id == "caixote":
			prop(world, "saco", at + Vector3(0.12, 0.66, 0), 0, 0.75)
	if layout.world.get("has_shelter", true):
		var camp = prop(world, "escada", layout.to_world(layout.camp_exit), PI)
		camp.name = "SaidaDoAbrigo"
		var camp_ring = Visuals.ring(1.1, Color("b3c6a1"), 0.035)
		world.add_child(camp_ring)
		camp_ring.position = game.camp_position + Vector3(0, 0.06, 0)
		_sign(world, "ABRIGO", game.camp_position + Vector3(0, 1.8, 0), Color("c7d1b3"))
		campfire(world, game.camp_position)
	if layout.world.get("stairs_up") != null:
		var up: Vector2i = DungeonLayout.cell(layout.world["stairs_up"])
		prop(world, "escada", layout.to_world(up), PI).name = "EscadaSobe"
		_sign(world, "SUBIDA", layout.to_world(up) + Vector3(0, 1.8, 0), Color("a9c8d6"))
	if layout.world.has("stairs_down"):
		var down: Vector2i = DungeonLayout.cell(layout.world["stairs_down"])
		var stairs = prop(world, "escada", layout.to_world(down), _stairs_turn(layout, down))
		stairs.name = "EscadaDesce"
		game.stairs_sign = _sign(world, "DESCIDA", layout.to_world(down) + Vector3(0, 1.8, 0), Color("d98a6a"))

## Faces the stairs into the room from the wall they lean on.
static func _stairs_turn(layout, cell: Vector2i) -> float:
	if not layout.is_floor(cell + Vector2i.LEFT):
		return PI
	if not layout.is_floor(cell + Vector2i.RIGHT):
		return 0.0
	if not layout.is_floor(cell + Vector2i.UP):
		return PI / 2
	return -PI / 2

static func _sign(world: Node3D, text: String, pos: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = 30
	label.pixel_size = 0.006
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font = UiStyle.caps_font()
	label.outline_size = 8
	label.outline_modulate = Color(0, 0, 0, 0.8)
	world.add_child(label)
	return label

static func torch(world: Node3D, pos: Vector3) -> void:
	prop(world, "tocha", pos)
	var light := OmniLight3D.new()
	world.add_child(light)
	light.position = pos + Vector3(0, 0.65, 0)
	light.light_color = Color("ffd394")
	light.light_energy = 1.3
	light.omni_range = 4.5
	_tremble(world, light)
	Vfx.flame(world, pos + Vector3(0, 0.64, 0))

## Lights registered here tremble like fire (Vfx.Flicker, one per floor).
static func _tremble(world: Node3D, light: OmniLight3D) -> void:
	var flicker = world.get_node_or_null("LuzesTremulas")
	if flicker:
		flicker.add(light)

const LOG_COLOR := Color("4a3322")

## Campfire in the shelter, in the middle of the resting ring: three crossed
## logs, embers, flames and a warm light. A small collider keeps the adventurer
## beside the fire instead of in it (resting works up to 1,6 m away).
static func campfire(world: Node3D, pos: Vector3) -> Node3D:
	var fire := Node3D.new()
	fire.name = "Fogueira"
	world.add_child(fire)
	fire.position = pos
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.3
	cylinder.height = 0.5
	shape.shape = cylinder
	shape.position.y = 0.25
	body.add_child(shape)
	fire.add_child(body)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = LOG_COLOR
	wood.roughness = 0.95
	var piece := CylinderMesh.new()
	piece.top_radius = 0.065
	piece.bottom_radius = 0.075
	piece.height = 0.78
	piece.radial_segments = 6
	piece.rings = 1
	for i in 3:
		var part := MeshInstance3D.new()
		part.mesh = piece
		part.material_override = wood
		fire.add_child(part)
		# Lying down, crossed at the centre and a little raised there.
		part.basis = Basis(Vector3.UP, TAU * i / 3.0 + 0.3) * Basis(Vector3.RIGHT, PI / 2 - 0.22)
		part.position = Vector3(0, 0.09, 0)
	var embers := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.26
	disc.bottom_radius = 0.30
	disc.height = 0.04
	disc.radial_segments = 8
	embers.mesh = disc
	embers.material_override = Visuals.material(Color("8a2f12"), true)
	embers.position.y = 0.02
	fire.add_child(embers)
	Vfx.flame(fire, Vector3(0, 0.05, 0), 1.6)
	Vfx.flame(fire, Vector3(0.09, 0.04, 0.06), 1.15)
	Vfx.flame(fire, Vector3(-0.08, 0.04, -0.05), 1.25)
	var light := OmniLight3D.new()
	fire.add_child(light)
	light.position = Vector3(0, 0.7, 0)
	light.light_color = Color("ffb067")
	light.light_energy = 1.7
	light.omni_range = 6.0
	_tremble(world, light)
	return fire

static func add_container(game, data: Dictionary) -> Node3D:
	var holder := Node3D.new()
	game.add_child(holder)
	holder.position = Vector3(data["pos"][0], 0, data["pos"][1])
	prop(holder, "bau" if data.get("chest", true) else "saco", Vector3.ZERO)
	var ring = Visuals.ring(0.63, Color("b6a274"), 0.025)
	holder.add_child(ring)
	ring.position.y = 0.06
	data["node"] = holder
	data["ring"] = ring
	return holder
