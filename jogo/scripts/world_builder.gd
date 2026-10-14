extends RefCounted
class_name WorldBuilder

static func prop(world: Node3D, id: String, pos: Vector3, rotation: float = 0.0, factor: float = 1.0) -> Node3D:
 var node = Visuals.model(id,factor)
 world.add_child(node)
 node.position = pos
 node.rotation.y = rotation
 return node

static func build(game) -> void:
 var world = Node3D.new()
 world.name = "Dungeon"
 game.add_child(world)
 Visuals.collider(world,Vector3(100,1,100),Vector3(32,-0.48,26)).name = "Ground"
 var walls: Dictionary = {}
 for cell in game.layout.floors:
  var center: Vector3 = game.layout.to_world(cell)
  # Four half-metre slabs per model, 4 models per navigation cell.
  for x in [-0.5,0.5]:
   for z in [-0.5,0.5]:
    prop(world,"piso_b" if (cell.x*13+cell.y*7)%5==0 else "piso",center+Vector3(x,0,z))
  for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var adjacent: Vector2i = cell+offset
   if game.layout.is_floor(adjacent):
    continue
   walls[adjacent] = true
   var wall = prop(world,"parede",center+Vector3(offset.x,0,offset.y),PI/2 if offset.x!=0 else 0.0)
   # Keep foreground cutaways while back walls retain human-scale height.
   if offset.x > 0 or offset.y > 0:
    wall.scale.y = 0.19
   elif (cell.x+cell.y)%5==0:
    torch(world,center+Vector3(offset.x*0.75,1.24,offset.y*0.75))
 for cell in walls:
  Visuals.collider(world,Vector3(2,3,2),game.layout.to_world(cell)+Vector3(0,1.5,0))
 # Furniture is placed against room boundaries, outside the navigation lane.
 # These decorated edge cells are marked solid in the pathfinder below.
 var furniture = [
  [Vector2i(2,22),"catre",0.0],[Vector2i(2,23),"catre",0.0],
  [Vector2i(3,24),"mesa",0.0],[Vector2i(4,24),"banco",0.0],
  [Vector2i(7,24),"caixote",0.0],[Vector2i(8,24),"barril",0.0],
  [Vector2i(8,23),"saco",0.0],[Vector2i(3,8),"mesa",0.0],
  [Vector2i(4,8),"banco",0.0],[Vector2i(10,8),"caixote",0.0],
  [Vector2i(10,9),"barril",0.0],[Vector2i(3,13),"catre",0.0],
  [Vector2i(3,14),"catre",0.0],[Vector2i(16,23),"caixote",0.0],
  [Vector2i(17,23),"caixote",0.0],[Vector2i(18,23),"barril",0.0],
  [Vector2i(19,23),"barril",0.0],[Vector2i(23,17),"mesa",PI/2],
  [Vector2i(23,18),"saco",0.0],[Vector2i(16,5),"pilar",0.0],
  [Vector2i(23,5),"pilar",0.0],[Vector2i(16,12),"vaso",0.0],
  [Vector2i(23,12),"pilar",0.0],[Vector2i(26,2),"pilar",0.0],
  [Vector2i(30,2),"pilar",0.0],[Vector2i(30,4),"mesa",PI/2],
  [Vector2i(30,8),"caixote",0.0]
 ]
 for entry in furniture:
  var at: Vector3 = game.layout.to_world(entry[0])
  var id: String = entry[1]
  prop(world,id,at,entry[2])
  var size = Vector3(0.72,0.8,0.72)
  if id=="mesa": size = Vector3(1.4,0.8,0.75)
  if id=="catre": size = Vector3(0.85,0.55,1.95)
  if id=="banco": size = Vector3(1.03,0.48,0.38)
  if id=="pilar": size = Vector3(0.49,2.35,0.49)
  if entry[2]!=0.0: size=Vector3(size.z,size.y,size.x)
  Visuals.collider(world,size,at+Vector3(0,size.y/2,0))
  game.layout.pathfinder.set_point_solid(entry[0],true)
  if id=="mesa":
   prop(world,"vaso",at+Vector3(0.3,0.81,0))
   prop(world,"saco",at+Vector3(-0.3,0.81,0),0,0.6)
  elif id=="caixote":
   prop(world,"saco",at+Vector3(0.12,0.66,0),0,0.75)
 var camp = prop(world,"escada",game.layout.to_world(Vector2i(3,20)),PI)
 camp.name = "SaidaDoAbrigo"
 var camp_ring = Visuals.ring(1.1,Color("b3c6a1"),0.035)
 world.add_child(camp_ring)
 camp_ring.position = game.camp_position+Vector3(0,0.06,0)
 var camp_label = Label3D.new()
 camp_label.text = "ABRIGO"
 camp_label.position = game.camp_position+Vector3(0,1.8,0)
 camp_label.font_size = 30
 camp_label.pixel_size = 0.006
 camp_label.modulate = Color("c7d1b3")
 camp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 world.add_child(camp_label)

static func torch(world: Node3D, pos: Vector3) -> void:
 prop(world,"tocha",pos)
 var light = OmniLight3D.new()
 world.add_child(light)
 light.position = pos+Vector3(0,0.65,0)
 light.light_color = Color("ffd394")
 light.light_energy = 1.3
 light.omni_range = 4.5
 var flame = MeshInstance3D.new()
 var shape = SphereMesh.new()
 shape.radius = 0.055
 shape.height = 0.20
 flame.mesh = shape
 flame.material_override = Visuals.material(Color("ffce79"),true)
 world.add_child(flame)
 flame.position = light.position

static func add_container(game, data: Dictionary) -> Node3D:
 var holder = Node3D.new()
 game.add_child(holder)
 holder.position = Vector3(data["pos"][0],0,data["pos"][1])
 prop(holder,"bau" if data.get("chest",true) else "saco",Vector3.ZERO)
 var ring = Visuals.ring(0.63,Color("b6a274"),0.025)
 holder.add_child(ring)
 ring.position.y = 0.06
 data["node"] = holder
 data["ring"] = ring
 return holder
