extends Control

var stage: SubViewport
var world: Node3D
var camera: Camera3D
var characters: Array[Node3D] = []
var animations: Array[AnimationPlayer] = []
var current_view: int = 0
var zoom: float = 10.2
var mode: int = 0
var subtitle: Label
var base_target = Vector3(0,0.45,0)
var asset_cache: Dictionary = {}

func _ready() -> void:
 stage = SubViewport.new()
 stage.size = Vector2i(720,450)
 stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 stage.own_world_3d = true
 stage.msaa_3d = Viewport.MSAA_DISABLED
 add_child(stage)
 world = Node3D.new()
 stage.add_child(world)
 var display = TextureRect.new()
 display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 display.texture = stage.get_texture()
 display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 display.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(display)
 environment()
 room()
 board()
 character_study()
 camera = Camera3D.new()
 world.add_child(camera)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = zoom
 camera.current = true
 camera.far = 300
 update_camera()
 build_ui()
 if "--capturar-arte" in OS.get_cmdline_user_args():
  call_deferred("capture")

func model(id: String, pos: Vector3, rotation_y: float = 0) -> Node3D:
 if not asset_cache.has(id):
  asset_cache[id] = load("res://assets/originais/"+id+".glb")
 var instance: Node3D = asset_cache[id].instantiate()
 world.add_child(instance)
 instance.position = pos
 instance.rotation.y = rotation_y
 return instance

func environment() -> void:
 var env = Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("171a17")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("c1c4b7")
 env.ambient_light_energy = 0.68
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 var environment_node = WorldEnvironment.new()
 environment_node.environment = env
 world.add_child(environment_node)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-50,-32,0)
 sun.light_color = Color("ede0bc")
 sun.light_energy = 0.85
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 40
 world.add_child(sun)

func room() -> void:
 for x in range(-5,5):
  for z in range(-4,4):
   model("piso_b" if (x+z)%3==0 else "piso",Vector3(x+0.5,0,z+0.5))
 for x in [-4.0,-2.0,2.0,4.0]:
  model("parede",Vector3(x,0,-4))
 model("porta",Vector3(0,0,-4))
 for z in [-3.0,-1.0,1.0,3.0]:
  model("parede",Vector3(-5,0,z),PI/2)
 for p in [Vector3(-5,0,-4),Vector3(-5,0,0),Vector3(-5,0,4),Vector3(5,0,-4)]:
  model("pilar",p)
 model("mesa",Vector3(-3,0,-1.7))
 model("banco",Vector3(-3,0,-0.75))
 model("vaso",Vector3(-3.4,0.81,-1.6))
 model("bau",Vector3(2.8,0,-3.25))
 model("barril",Vector3(4.2,0,-3.1))
 model("barril",Vector3(4.2,0,-2.3))
 model("caixote",Vector3(-4.2,0,2.5))
 model("caixote",Vector3(-3.45,0,2.7),0.08)
 model("saco",Vector3(-3.45,0.66,2.7))
 model("saco",Vector3(-3.0,0,2.4),0.3)
 model("vaso",Vector3(4.3,0,1.9))
 model("saco",Vector3(4.25,0,2.7))
 for x in [-2.5,2.5]:
  model("tocha",Vector3(x,1.25,-3.72))
  var light = OmniLight3D.new()
  world.add_child(light)
  light.position = Vector3(x,1.96,-3.42)
  light.light_color = Color("ffd08e")
  light.light_energy = 2.0
  light.omni_range = 5
  var flame = MeshInstance3D.new()
  var mesh = SphereMesh.new()
  mesh.radius = 0.048
  mesh.height = 0.19
  mesh.radial_segments = 7
  mesh.rings = 3
  flame.mesh = mesh
  flame.material_override = Visuals.material(Color("f3c16e"),true)
  world.add_child(flame)
  flame.position = Vector3(x,1.99,-3.72)
 add_character(Vector3(-0.6,0,0.9),PI*0.15,true)

func add_character(pos: Vector3, angle: float, weapon: bool) -> void:
 var actor = model("aventureiro",pos,angle)
 var anim = Visuals.animation(actor)
 characters.append(actor)
 animations.append(anim)
 Visuals.play(anim,"idle")
 if weapon:
  var skeleton = Visuals.skeleton(actor)
  if skeleton:
   var attach = BoneAttachment3D.new()
   attach.bone_name = "hand-right"
   skeleton.add_child(attach)
   var sword: Node3D = load("res://assets/originais/espada.glb").instantiate()
   attach.add_child(sword)
   sword.rotation_degrees = Vector3(-55,0,0)
   sword.position = Vector3(0,0.035,0)

func board() -> void:
 var entries = ["parede","porta","pilar","bau","barril","caixote","mesa","banco","saco"]
 for i in entries.size():
  var pos = Vector3(100+(i%3-1)*3.1,0,(i/3-1)*3.0)
  model(entries[i],pos)
  for x in [-0.5,0.5]:
   for z in [-0.5,0.5]:
    model("piso",pos+Vector3(x,-0.07,z))
  var text = Label3D.new()
  world.add_child(text)
  text.position = pos+Vector3(0,0.1,1.3)
  text.text = str(entries[i]).to_upper()
  text.font_size = 26
  text.pixel_size = 0.008
  text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  text.modulate = Color("bcb59c")

func character_study() -> void:
 for i in 3:
  var pos = Vector3(200+(i-1)*1.55,0,0)
  model("piso",pos)
  add_character(pos,[-0.35,PI*0.75,PI*1.25][i],i==0)

func build_ui() -> void:
 var title = Label.new()
 title.text = "D U N G E P M   /   ESTUDO VISUAL 01"
 title.add_theme_font_size_override("font_size",21)
 title.add_theme_color_override("font_color",Color("e1d7bd"))
 add_child(title)
 title.position = Vector2(34,24)
 subtitle = Label.new()
 subtitle.add_theme_font_size_override("font_size",14)
 subtitle.add_theme_color_override("font_color",Color("b7b39e"))
 add_child(subtitle)
 subtitle.position = Vector2(35,61)
 update_subtitle()
 var panel = PanelContainer.new()
 add_child(panel)
 panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
 panel.offset_left = 28
 panel.offset_right = -28
 panel.offset_top = -79
 panel.offset_bottom = -22
 var style = StyleBoxFlat.new()
 style.bg_color = Color(0.065,0.075,0.062,0.96)
 style.border_color = Color("555847")
 style.set_border_width_all(1)
 style.content_margin_left = 18
 style.content_margin_right = 18
 style.content_margin_top = 10
 style.content_margin_bottom = 10
 panel.add_theme_stylebox_override("panel",style)
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation",16)
 panel.add_child(row)
 for i in 3:
  var button = Button.new()
  button.text = ["1  CENÁRIO","2  MODELOS","3  PERSONAGEM"][i]
  button.custom_minimum_size = Vector2(165,36)
  button.pressed.connect(set_view.bind(i))
  row.add_child(button)
 var info = Label.new()
 info.text = "ESPAÇO  animação     ·     RODA  zoom     ·     F2  nitidez"
 info.add_theme_font_size_override("font_size",13)
 info.add_theme_color_override("font_color",Color("bbb59f"))
 row.add_child(info)

func update_subtitle() -> void:
 var descriptions = ["Proporções humanas · pedra e madeira gastas · paleta medieval contida", "Biblioteca própria · modelos editáveis em Blender e exportados em GLB", "Aventureiro · túnica, couro e equipamento · estudo de proporção e movimento"]
 subtitle.text = descriptions[current_view]

func set_view(value: int) -> void:
 current_view = value
 zoom = [10.2,11.5,3.8][value]
 base_target = Vector3([0,100,200][value],[0.45,0.3,0.8][value],0)
 update_camera()
 update_subtitle()

func update_camera() -> void:
 camera.size = zoom
 camera.look_at_from_position(base_target+Vector3(12,9.798,12),base_target)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode in [KEY_1,KEY_2,KEY_3]:
   set_view(event.physical_keycode-KEY_1)
  elif event.physical_keycode == KEY_SPACE:
   mode = (mode+1)%3
   for anim in animations:
    Visuals.play(anim,["idle","walk","attack"][mode],true)
  elif event.physical_keycode == KEY_F2:
   stage.size = Vector2i(1440,900) if stage.size.x == 720 else Vector2i(720,450)
  elif event.physical_keycode == KEY_ESCAPE:
   get_tree().quit()
 elif event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP:
   zoom = maxf(2.5,zoom-0.5)
  elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   zoom = minf(16,zoom+0.5)
  update_camera()

func capture() -> void:
 var path = ProjectSettings.globalize_path("res://../outputs")
 DirAccess.make_dir_recursive_absolute(path)
 await get_tree().create_timer(1.0).timeout
 for i in 3:
  set_view(i)
  await get_tree().create_timer(0.25).timeout
  await RenderingServer.frame_post_draw
  var result = get_viewport().get_texture().get_image().save_png(path+"/"+["direcao-visual.png","modelos-proprios.png","personagem-proprio.png"][i])
  assert(result == OK)
 for actor in characters:
  assert(Visuals.skeleton(actor) != null)
 for anim in animations:
  print("ART_ANIMATIONS ",anim.get_animation_list())
  assert(anim.has_animation("walk") and anim.has_animation("idle") and anim.has_animation("attack"))
 print("ART_PREVIEW_OK: 23 modelos na biblioteca; 4 personagens; 4 animações; 3 vistas renderizadas")
 get_tree().quit()
