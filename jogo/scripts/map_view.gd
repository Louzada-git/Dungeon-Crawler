extends Control
class_name DungeonMapView

var game
var large: bool = false

func _draw() -> void:
 if game == null:
  return
 var factor: float = minf(size.x/63.0,size.y/34.0)
 var center = size * Vector2(0.50,0.53)
 var origin = Vector2(16,13)
 for cell in game.discovered:
  if not game.layout.is_floor(cell):
   continue
  var p = project(Vector2(cell)-origin,factor)+center
  var poly = PackedVector2Array([p+Vector2(0,-factor*0.49),p+Vector2(factor*0.97,0),p+Vector2(0,factor*0.49),p+Vector2(-factor*0.97,0)])
  var color = Color("47625f")
  if cell.distance_to(game.layout.to_cell(game.player.position)) < 4:
   color = Color("73948b")
  draw_colored_polygon(poly,color)
 for loot in game.containers:
  var cell = game.layout.to_cell(Vector3(loot["pos"][0],0,loot["pos"][1]))
  if game.discovered.has(cell) and not loot["items"].is_empty():
   var p = project(Vector2(cell)-origin,factor)+center
   draw_rect(Rect2(p-Vector2(2.5,2.5),Vector2(5,5)),Color("e2b870"))
 var camp = project(Vector2(game.layout.to_cell(game.camp_position))-origin,factor)+center
 draw_circle(camp,4.0,Color("79dfc2"))
 var player = project(Vector2(game.player.position.x/2.0,game.player.position.z/2.0)-origin,factor)+center
 draw_circle(player,large_size(4.0),Color("faf0d6"))
 draw_arc(player,large_size(7.0),0,TAU,24,Color("d2ba86"),1.0,true)

func large_size(value: float) -> float:
 return value*1.3 if large else value

func project(point: Vector2, factor: float) -> Vector2:
 return Vector2(point.x-point.y,(point.x+point.y)*0.5)*factor
