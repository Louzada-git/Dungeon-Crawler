extends Control
# Original line icons, drawn at UI resolution without external image assets.
var kind: String = "pack"
var tint: Color = Color("c9cbb5")
var bleeding: bool = false

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func line(points: Array, color: Color, width: float = 1.5) -> void:
 var transformed = PackedVector2Array()
 for point in points:
  transformed.append(Vector2(point[0],point[1])*size/32.0)
 draw_polyline(transformed,color,width,true)

func _draw() -> void:
 var c = tint
 match kind:
  "pack":
   line([[9,9],[9,5],[23,5],[23,9]],c)
   line([[6,10],[26,10],[27,28],[5,28],[6,10]],c)
   line([[8,17],[24,17],[24,25],[8,25],[8,17]],c)
   line([[12,10],[12,15],[20,15],[20,10]],c)
  "health":
   line([[16,27],[4,15],[4,9],[8,5],[12,5],[16,10],[20,5],[24,5],[28,9],[28,15],[16,27]],c)
   line([[7,16],[12,16],[15,12],[18,21],[21,16],[26,16]],c)
  "map":
   line([[3,7],[11,4],[21,8],[29,5],[29,26],[21,29],[11,25],[3,28],[3,7]],c)
   line([[11,4],[11,25]],c);line([[21,8],[21,29]],c)
  "pause":
   line([[11,6],[11,26]],c,3);line([[22,6],[22,26]],c,3)
  "sword":
   line([[7,26],[24,5],[28,3],[27,8],[10,29]],c)
   line([[4,21],[14,29]],c,2)
  "food":
   line([[5,24],[5,14],[8,8],[14,5],[22,5],[27,10],[27,24],[5,24]],c)
   line([[11,8],[14,12]],c);line([[18,7],[21,11]],c)
  "bandage":
   line([[4,10],[10,4],[28,22],[22,28],[4,10]],c)
   line([[10,16],[16,10],[22,16],[16,22],[10,16]],c)
  "stamina":
   line([[20,3],[7,19],[16,18],[12,29],[26,12],[17,13],[20,3]],c)
  "body":
   draw_arc(Vector2(.5,.13)*size,size.x*.09,0,TAU,32,c,1.5,true)
   line([[13,7],[8,8],[6,14],[4,20],[6,21],[9,15],[10,12],[11,18],[10,24],[9,30],[12,30],[15,21],[17,21],[20,30],[23,30],[22,24],[21,18],[22,12],[23,15],[26,21],[28,20],[26,14],[24,8],[19,7]],c)
   line([[12,10],[16,11],[20,10]],c)
   line([[16,11],[16,17]],c)
   if bleeding:
    # Whole-body condition only: the prototype has no localized wounds.
    draw_arc(Vector2(.5,.55)*size,size.x*.21,0,TAU,32,Color("c57065"),2,true)
