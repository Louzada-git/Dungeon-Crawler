extends CanvasLayer

const INK = Color("181b17")
const TEXT = Color("dcddd5")
const MUTED = Color("a8aca0")
const GOLD = Color("c1bd8f")
var game
var root: Control
var hud: Control
var modal: Control
var inventory_panel: PanelContainer
var map_panel: PanelContainer
var pause_panel: PanelContainer
var ending_panel: PanelContainer
const HELP = "WASD: mover · Botão direito: mirar · Esquerdo: atacar\nShift: correr · Espaço: esquivar · E: interagir\nI / Tab: mochila · M: mapa · Roda do mouse: zoom\nH: condição física · 2: ração · 3: bandagem\nF5: salvar · Esc: pausa\n\nA mochila e o mapa pausam esta versão para um jogador."
var pause_confirm: bool = false
var bars: Dictionary = {}
var health_note: Label
var area_label: Label
var objective: Label
var message_label: Label
var prompt: Label
var weapon_label: Label
var weight_label: Label
var mini_map: DungeonMapView
var full_map: DungeonMapView
var inventory_rows: VBoxContainer
var loot_rows: VBoxContainer
var selection_detail: Label
var loot_title: Label
var backpack_title: Label
var use_button: Button
var drop_button: Button
var take_button: Button
var take_all_button: Button
var loot: Dictionary = {}
var selected: String = ""
var selected_loot: String = ""
var flash: ColorRect
var dim: ColorRect
var health_panel: PanelContainer
var body_glyph: Control
var condition_label: Label
var quick_food: Button
var quick_bandage: Button
var bag_strip: Button
var loot_strip: Button
const Glyph = preload("res://scripts/ui_glyph.gd")
var sound_button: Button
var pause_title: Label
var pause_note: Label
var end_title: Label
var end_note: Label
var inventory_note: Label

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 root = Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root)
 var theme = Theme.new()
 theme.default_font_size = 13
 theme.set_color("font_color","Label",TEXT)
 theme.set_color("font_color","Button",TEXT)
 theme.set_color("font_hover_color","Button",Color("ffffff"))
 theme.set_color("font_disabled_color","Button",Color("66695f"))
 theme.set_stylebox("normal","Button",box(Color("20221f"),Color("494b43"),0))
 theme.set_stylebox("hover","Button",box(Color("36392e"),GOLD,0))
 theme.set_stylebox("pressed","Button",box(Color("434735"),GOLD,0))
 theme.set_stylebox("disabled","Button",box(Color("171915"),Color("2d3029"),0))
 theme.set_stylebox("focus","Button",box(Color(0,0,0,0),GOLD,0))
 root.theme = theme
 build_hud()
 build_modals()
 flash = ColorRect.new()
 flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 flash.color = Color(0.7,0.12,0.06,0)
 flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(flash)
 update_hud()

func box(bg: Color, border: Color = Color("4c4e44"), radius: int = 0) -> StyleBoxFlat:
 var style = StyleBoxFlat.new()
 style.bg_color = bg
 style.border_color = border
 style.set_border_width_all(1)
 style.set_corner_radius_all(radius)
 style.content_margin_left = 7
 style.content_margin_right = 7
 style.content_margin_top = 3
 style.content_margin_bottom = 3
 return style

func label(text: String, size: int = 13, color: Color = TEXT) -> Label:
 var node = Label.new()
 node.text = text
 node.add_theme_font_size_override("font_size",size)
 node.add_theme_color_override("font_color",color)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return node

func button(text: String, callback: Callable) -> Button:
 var node = Button.new()
 node.text = text
 node.custom_minimum_size.y = 25
 node.pressed.connect(callback)
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 return node

func panel_at(parent: Control, rect: Rect2) -> PanelContainer:
 var p = PanelContainer.new()
 p.add_theme_stylebox_override("panel",box(Color(0.065,0.075,0.06,0.94)))
 parent.add_child(p)
 p.position = rect.position
 p.size = rect.size
 p.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return p

func glyph_button(kind: String, hint: String, callback: Callable, extent: Vector2 = Vector2(36,36)) -> Button:
 var b = button("",callback)
 b.custom_minimum_size = extent
 b.tooltip_text = hint
 var g = Glyph.new()
 g.kind = kind
 b.add_child(g)
 g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 g.offset_left = 6
 g.offset_top = 6
 g.offset_right = -6
 g.offset_bottom = -6
 return b

func build_hud() -> void:
 hud = Control.new()
 root.add_child(hud)
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var tools = VBoxContainer.new()
 hud.add_child(tools)
 tools.position = Vector2(8,8)
 tools.add_theme_constant_override("separation",5)
 tools.add_child(glyph_button("pack","Inventário [I]",toggle_inventory))
 tools.add_child(glyph_button("health","Condição física [H]",toggle_health))
 tools.add_child(glyph_button("map","Mapa explorado [M]",toggle_map))
 tools.add_child(glyph_button("pause","Pausa e controles [Esc]",toggle_pause))
 var strips = HBoxContainer.new()
 hud.add_child(strips)
 strips.position = Vector2(54,8)
 strips.add_theme_constant_override("separation",4)
 bag_strip = button("Inventário [I]",toggle_inventory)
 bag_strip.custom_minimum_size.x = 330
 bag_strip.alignment = HORIZONTAL_ALIGNMENT_LEFT
 strips.add_child(bag_strip)
 loot_strip = button("Arredores [E]",func(): open_inventory(game.nearest_loot()))
 loot_strip.custom_minimum_size.x = 330
 loot_strip.alignment = HORIZONTAL_ALIGNMENT_LEFT
 strips.add_child(loot_strip)
 area_label = label("",13,TEXT)
 hud.add_child(area_label)
 area_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
 area_label.offset_left = -300
 area_label.offset_right = -14
 area_label.offset_top = 10
 area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 objective = label("",11,MUTED)
 hud.add_child(objective)
 objective.set_anchors_preset(Control.PRESET_TOP_RIGHT)
 objective.offset_left = -300
 objective.offset_right = -14
 objective.offset_top = 31
 objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 var status = VBoxContainer.new()
 hud.add_child(status)
 status.set_anchors_preset(Control.PRESET_TOP_RIGHT)
 status.offset_left = -66
 status.offset_right = -12
 status.offset_top = 67
 status.add_theme_constant_override("separation",8)
 for entry in [["health","health","Vida",Color("bd857c")],["stamina","stamina","Fôlego",Color("b4bf93")],["food","food","Saciedade",Color("c1ad7c")]]:
  var badge = VBoxContainer.new()
  var badge_frame = PanelContainer.new()
  badge_frame.add_theme_stylebox_override("panel",box(Color(0.055,0.06,0.045,0.93),Color("4c4e44")))
  status.add_child(badge_frame)
  badge_frame.add_child(badge)
  badge.add_theme_constant_override("separation",1)
  var b = glyph_button(entry[1],entry[2]+" · condição [H]",toggle_health,Vector2(38,34))
  badge.add_child(b)
  var meter = ProgressBar.new()
  meter.show_percentage = false
  meter.custom_minimum_size = Vector2(38,4)
  meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var empty = StyleBoxFlat.new()
  empty.bg_color = Color("252820")
  var fill = StyleBoxFlat.new()
  fill.bg_color = entry[3]
  meter.add_theme_stylebox_override("background",empty)
  meter.add_theme_stylebox_override("fill",fill)
  badge.add_child(meter)
  var value = label("100",11,entry[3])
  value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  badge.add_child(value)
  bars[entry[0]] = [meter,value]
 var quick = HBoxContainer.new()
 hud.add_child(quick)
 quick.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
 quick.offset_left = -73
 quick.offset_right = 73
 quick.offset_top = -64
 quick.offset_bottom = -17
 quick.add_theme_constant_override("separation",4)
 quick.add_child(glyph_button("sword","Arma equipada · abrir inventário [1]",toggle_inventory,Vector2(46,46)))
 quick_food = glyph_button("food","Comer ração [2]",func(): quick_use("ration"),Vector2(46,46))
 quick_bandage = glyph_button("bandage","Usar bandagem [3]",func(): quick_use("bandage"),Vector2(46,46))
 quick.add_child(quick_food)
 quick.add_child(quick_bandage)
 for i in 3:
  var key = label(str(i+1),10,GOLD)
  quick.get_child(i).add_child(key)
  key.position = Vector2(3,1)
 weapon_label = label("",12,TEXT)
 hud.add_child(weapon_label)
 weapon_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
 weapon_label.offset_left = 12
 weapon_label.offset_top = -45
 weight_label = label("",11,MUTED)
 hud.add_child(weight_label)
 weight_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
 weight_label.offset_left = 12
 weight_label.offset_top = -25
 prompt = label("",13,GOLD)
 hud.add_child(prompt)
 prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
 prompt.offset_left = -410
 prompt.offset_right = 410
 prompt.offset_top = -98
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 message_label = label("",12,TEXT)
 hud.add_child(message_label)
 message_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
 message_label.offset_left = -430
 message_label.offset_right = 430
 message_label.offset_top = -126
 message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 for text_node in [area_label,objective,weapon_label,weight_label,prompt,message_label]:
  text_node.add_theme_color_override("font_shadow_color",Color.BLACK)
  text_node.add_theme_constant_override("shadow_offset_x",1)
  text_node.add_theme_constant_override("shadow_offset_y",1)
 mini_map = DungeonMapView.new()
 mini_map.game = game
 hud.add_child(mini_map)
 mini_map.hide()
 build_health()

func build_health() -> void:
 health_panel = panel_at(hud,Rect2(0,0,290,290))
 health_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
 health_panel.offset_left = -308
 health_panel.offset_right = -18
 health_panel.offset_top = -314
 health_panel.offset_bottom = -24
 var col = VBoxContainer.new()
 health_panel.add_child(col)
 var title_row = HBoxContainer.new()
 col.add_child(title_row)
 var title = label("CONDIÇÃO FÍSICA",12,TEXT)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title_row.add_child(title)
 title_row.add_child(button("×",toggle_health))
 col.add_child(HSeparator.new())
 var content = HBoxContainer.new()
 content.size_flags_vertical = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",12)
 col.add_child(content)
 body_glyph = Glyph.new()
 body_glyph.kind = "body"
 body_glyph.custom_minimum_size = Vector2(105,213)
 body_glyph.tint = Color("a9aa9e")
 content.add_child(body_glyph)
 var notes = VBoxContainer.new()
 notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 notes.add_theme_constant_override("separation",12)
 content.add_child(notes)
 notes.add_child(label("Estado geral",12,MUTED))
 condition_label = label("",13,TEXT)
 notes.add_child(condition_label)
 health_note = label("",12,MUTED)
 health_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 health_note.custom_minimum_size.x = 130
 notes.add_child(health_note)
 notes.add_child(button("Bandagem [3]",func(): quick_use("bandage")))
 col.add_child(label("H  fechar     ·     I  abrir mochila",11,MUTED))
 health_panel.hide()

func toggle_health() -> void:
 if not game.ended:
  health_panel.visible = not health_panel.visible

func quick_use(id: String) -> void:
 if game.ended or (any_panel() and not inventory_panel.visible):
  return
 game.use_item(id)
 refresh_inventory()

func make_modal(size: Vector2) -> PanelContainer:
 var p = PanelContainer.new()
 modal.add_child(p)
 p.set_anchors_preset(Control.PRESET_CENTER)
 p.offset_left = -size.x*0.5
 p.offset_right = size.x*0.5
 p.offset_top = -size.y*0.5
 p.offset_bottom = size.y*0.5
 p.custom_minimum_size = size
 p.add_theme_stylebox_override("panel",box(Color(0.045,0.052,0.039,0.95),Color("5a5d50"),0))
 p.hide()
 return p

func build_modals() -> void:
 modal = Control.new()
 root.add_child(modal)
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
 dim = ColorRect.new()
 modal.add_child(dim)
 dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 dim.color = Color(0.015,0.025,0.03,0.80)
 modal.hide()
 build_inventory()
 build_map()
 build_pause()
 build_ending()

func table_header(parent: Control) -> void:
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation",0)
 parent.add_child(row)
 for entry in [["Item",190],["Categoria",86],["Qtd.",37],["Peso",51]]:
  var text = label(entry[0],11,MUTED)
  text.custom_minimum_size.x = entry[1]
  row.add_child(text)
 parent.add_child(HSeparator.new())

func build_inventory() -> void:
 inventory_panel = make_modal(Vector2(784,306))
 inventory_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
 inventory_panel.offset_left = 54
 inventory_panel.offset_top = 40
 inventory_panel.offset_right = 838
 inventory_panel.offset_bottom = 346
 var outer = VBoxContainer.new()
 outer.add_theme_constant_override("separation",5)
 inventory_panel.add_child(outer)
 var heading = HBoxContainer.new()
 outer.add_child(heading)
 var title = label("INVENTÁRIO",12)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 heading.add_child(title)
 heading.add_child(label("PAUSADO",11,GOLD))
 heading.add_child(button("×  [I]",close_all))
 outer.add_child(HSeparator.new())
 var body = HBoxContainer.new()
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",10)
 outer.add_child(body)
 var left = VBoxContainer.new()
 left.custom_minimum_size.x = 374
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(left)
 backpack_title = label("",12,GOLD)
 left.add_child(backpack_title)
 table_header(left)
 var inv_scroll = ScrollContainer.new()
 inv_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 inv_scroll.custom_minimum_size = Vector2(374,110)
 inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 left.add_child(inv_scroll)
 inventory_rows = VBoxContainer.new()
 inventory_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 inventory_rows.add_theme_constant_override("separation",1)
 inv_scroll.add_child(inventory_rows)
 selection_detail = label("Selecione um item.",11,MUTED)
 selection_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 selection_detail.custom_minimum_size.y = 46
 left.add_child(selection_detail)
 var actions = HBoxContainer.new()
 left.add_child(actions)
 use_button = button("Usar / equipar",use_selected)
 drop_button = button("Deixar 1 no chão",drop_selected)
 actions.add_child(use_button)
 actions.add_child(drop_button)
 body.add_child(VSeparator.new())
 var right = VBoxContainer.new()
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(right)
 loot_title = label("",12,GOLD)
 loot_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 right.add_child(loot_title)
 table_header(right)
 var loot_scroll = ScrollContainer.new()
 loot_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 loot_scroll.custom_minimum_size = Vector2(374,110)
 loot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 right.add_child(loot_scroll)
 loot_rows = VBoxContainer.new()
 loot_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 loot_rows.add_theme_constant_override("separation",1)
 loot_scroll.add_child(loot_rows)
 var tip = label("Limite: 18 kg. Acima de 11 kg, movimento mais lento.
O peso da tabela considera a pilha inteira.",11,MUTED)
 tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 tip.custom_minimum_size.y = 46
 right.add_child(tip)
 var transfer_actions = HBoxContainer.new()
 right.add_child(transfer_actions)
 take_button = button("Pegar 1",take_selected)
 take_all_button = button("Pegar o que couber",take_all)
 transfer_actions.add_child(take_button)
 transfer_actions.add_child(take_all_button)
 outer.add_child(HSeparator.new())
 inventory_note = label("",11,GOLD)
 inventory_note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 outer.add_child(inventory_note)

func item_row(id: String, count: int, active: bool, callback: Callable, equipped: bool = false) -> Button:
 var data = Items.info(id)
 var row = button("",callback)
 row.custom_minimum_size.y = 25
 row.tooltip_text = data["name"]+"\n"+data["description"]
 var normal = box(Color("3a402e") if active else Color(0.10,0.12,0.085,0.78),Color("5e644b") if active else Color("242820"))
 normal.content_margin_left = 0
 normal.content_margin_right = 0
 row.add_theme_stylebox_override("normal",normal)
 var columns = HBoxContainer.new()
 columns.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(columns)
 columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 columns.offset_left = 4
 columns.add_theme_constant_override("separation",0)
 var category: String = {"ARMA":"Arma","ALIMENTO":"Alimento","TRATAMENTO":"Tratamento","MATERIAL":"Material","TESOURO":"Tesouro","OBJETIVO":"Objetivo"}.get(data["tag"],data["tag"])
 var fields = [[("◆ " if equipped else "")+data["name"],186],[category,86],[str(count),37],["%.2f" % (count*data["weight"]),51]]
 for field in fields:
  var text = label(field[0],12,TEXT if active else MUTED)
  text.custom_minimum_size.x = field[1]
  text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  columns.add_child(text)
 return row

func build_map() -> void:
 map_panel = make_modal(Vector2(990,700))
 var col = VBoxContainer.new()
 map_panel.add_child(col)
 var row = HBoxContainer.new()
 col.add_child(row)
 var title = label("AS CISTERNAS",28)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(title)
 row.add_child(button("Fechar  [M]",close_all))
 col.add_child(label("A escuridão guarda os caminhos que você ainda não percorreu.",16,MUTED))
 full_map = DungeonMapView.new()
 full_map.game = game
 full_map.large = true
 full_map.custom_minimum_size = Vector2(920,550)
 full_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
 col.add_child(full_map)
 col.add_child(label("● Você        ● Abrigo        ■ Recipiente com itens             EXPEDIÇÃO PAUSADA",14,GOLD))

func build_pause() -> void:
 pause_panel = make_modal(Vector2(590,440))
 var col = VBoxContainer.new()
 col.add_theme_constant_override("separation",13)
 pause_panel.add_child(col)
 pause_title = label("UM MOMENTO DE RESPIRO",25)
 col.add_child(pause_title)
 pause_note = label("WASD: mover · Botão direito: mirar · Esquerdo: atacar\nShift: correr · Espaço: esquivar · E: interagir\nI / Tab: mochila · M: mapa · Roda do mouse: zoom\nH: condição física · 2: ração · 3: bandagem\nF5: salvar · Esc: pausa\n\nA mochila e o mapa pausam esta versão para um jogador.",16,MUTED)
 col.add_child(pause_note)
 col.add_child(button("Continuar",close_all))
 col.add_child(button("Salvar expedição",func(): game.save_game(); close_all()))
 sound_button = button("Som: ligado",func():
  game.sound.enabled = not game.sound.enabled
  sound_button.text = "Som: ligado" if game.sound.enabled else "Som: desligado"
 )
 col.add_child(sound_button)
 col.add_child(button("Nova expedição",confirm_restart))
 col.add_child(button("Salvar e sair",func():
  if game.save_game(false):
   get_tree().quit()
 ))

func build_ending() -> void:
 ending_panel = make_modal(Vector2(590,340))
 var col = VBoxContainer.new()
 col.add_theme_constant_override("separation",20)
 ending_panel.add_child(col)
 end_title = label("",29)
 col.add_child(end_title)
 end_note = label("",17,MUTED)
 end_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 col.add_child(end_note)
 col.add_child(button("Nova expedição — reiniciar progresso",func(): game.restart()))
 col.add_child(button("Sair",func(): get_tree().quit()))

func _input(event: InputEvent) -> void:
 if game.ended:
  return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode == KEY_H:
   toggle_health()
   get_viewport().set_input_as_handled()
   return
  if not any_panel() and event.physical_keycode in [KEY_1,KEY_2,KEY_3]:
   if event.physical_keycode == KEY_1:
    toggle_inventory()
   else:
    quick_use("ration" if event.physical_keycode==KEY_2 else "bandage")
   get_viewport().set_input_as_handled()
   return
 if event.is_action_pressed("inventory"):
  toggle_inventory()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("map"):
  toggle_map()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("escape"):
  toggle_pause()
  get_viewport().set_input_as_handled()

func any_panel() -> bool:
 return modal.visible

func hide_panels() -> void:
 dim.show()
 for p in [inventory_panel,map_panel,pause_panel,ending_panel]:
  p.hide()

func close_all() -> void:
 if game.ended:
  return
 hide_panels()
 modal.hide()
 get_tree().paused = false
 pause_confirm = false

func open_inventory(container: Dictionary = {}) -> void:
 hide_panels()
 loot = container
 selected = ""
 selected_loot = ""
 refresh_inventory()
 modal.show()
 inventory_panel.show()
 dim.hide()
 get_tree().paused = true

func toggle_inventory() -> void:
 if game.ended:
  return
 if inventory_panel.visible:
  close_all()
 else:
  open_inventory(game.nearest_loot())

func toggle_map() -> void:
 if game.ended:
  return
 if map_panel.visible:
  close_all()
  return
 hide_panels()
 modal.show()
 map_panel.show()
 full_map.queue_redraw()
 get_tree().paused = true

func toggle_pause() -> void:
 if any_panel():
  close_all()
  return
 hide_panels()
 pause_confirm = false
 pause_title.text = "UM MOMENTO DE RESPIRO"
 pause_note.text = HELP
 modal.show()
 pause_panel.show()
 get_tree().paused = true

func confirm_restart() -> void:
 if pause_confirm:
  game.restart()
  return
 pause_confirm = true
 pause_title.text = "RECOMEÇAR A EXPEDIÇÃO?"
 pause_note.text = "Isso apaga o progresso salvo desta expedição.\n\nClique de novo em ‘Nova expedição’ para confirmar.\nContinuar mantém seu progresso atual."

func clear_rows(container: VBoxContainer) -> void:
 for child in container.get_children():
  container.remove_child(child)
  child.queue_free()

func refresh_inventory() -> void:
 clear_rows(inventory_rows)
 clear_rows(loot_rows)
 backpack_title.text = "SUA MOCHILA   ·   %.1f / 18 kg" % game.inventory.weight()
 if game.inventory.count(selected) == 0:
  selected = ""
 for id in game.inventory.stacks:
  var row = item_row(id,game.inventory.count(id),selected==id,select_item.bind(id),game.inventory.equipped==id)
  inventory_rows.add_child(row)
 if game.inventory.stacks.is_empty():
  inventory_rows.add_child(label("A mochila está vazia.",12,MUTED))
 if selected != "":
  var data = Items.info(selected)
  selection_detail.text = "%s · %.2f kg/un.\n%s" % [data["tag"],data["weight"],data["description"]]
  use_button.text = "Equipar" if data.has("damage") else "Usar"
  use_button.disabled = not data.has("damage") and selected not in ["ration","bandage"]
  drop_button.disabled = false
 else:
  selection_detail.text = "Selecione um item para inspecionar.\n◆ indica a arma equipada."
  use_button.disabled = true
  drop_button.disabled = true
 if loot.is_empty():
  loot_title.text = "EXPLORAÇÃO"
  loot_rows.add_child(label("Aproxime-se de um baú ou dos\nitens no chão e pressione E.\n\nComida recupera saciedade.\nBandagens tratam ferimentos.\nArmas mudam alcance, dano e custo.",12,MUTED))
  take_button.disabled = true
  take_all_button.disabled = true
 else:
  loot_title.text = str(loot["name"]).to_upper()
  if not loot["items"].has(selected_loot):
   selected_loot = ""
  for id in loot["items"]:
   var row = item_row(id,loot["items"][id],selected_loot==id,select_loot.bind(id))
   loot_rows.add_child(row)
  if loot["items"].is_empty():
   loot_rows.add_child(label("Você recolheu tudo daqui.",12,MUTED))
  take_button.disabled = selected_loot == ""
  take_all_button.disabled = loot["items"].is_empty()
 update_hud()

func select_item(id: String) -> void:
 selected = id
 refresh_inventory()

func select_loot(id: String) -> void:
 selected_loot = id
 refresh_inventory()

func use_selected() -> void:
 game.use_item(selected)
 refresh_inventory()

func drop_selected() -> void:
 game.drop_item(selected)
 refresh_inventory()

func take_selected() -> void:
 if loot.is_empty() or selected_loot == "":
  return
 if game.inventory.transfer_from(loot["items"],selected_loot,1) == 0:
  game.message("A mochila está cheia. Deixe algo para trás.")
 refresh_inventory()

func take_all() -> void:
 if loot.is_empty():
  return
 var transferred: int = 0
 for id in loot["items"].keys():
  transferred += game.inventory.transfer_from(loot["items"],id,int(loot["items"][id]))
 game.message("Itens recolhidos." if loot["items"].is_empty() else "A mochila atingiu o limite. Parte dos itens ficou no recipiente.")
 refresh_inventory()

func update_hud() -> void:
 if game.player == null or bars.is_empty():
  return
 for key in bars:
  bars[key][0].value = game.player.get(key)
  bars[key][1].text = str(ceili(game.player.get(key)))
 health_note.text = "SANGRANDO · use uma bandagem" if game.player.bleeding else "Sem ferimentos abertos"
 condition_label.text = "Vida: %d / 100\nFôlego: %d / 100\nSaciedade: %d / 100" % [ceili(game.player.health),ceili(game.player.stamina),ceili(game.player.food)]
 body_glyph.bleeding = game.player.bleeding
 body_glyph.queue_redraw()
 bag_strip.text = "Inventário [I]                         %.1f / 18 kg" % game.inventory.weight()
 var nearby: Dictionary = game.nearest_loot()
 loot_strip.text = "Arredores · "+str(nearby.get("name","nenhum recipiente"))
 quick_food.disabled = game.inventory.count("ration")==0
 quick_bandage.disabled = game.inventory.count("bandage")==0
 quick_food.tooltip_text = "Comer ração [2] · %d disponíveis" % game.inventory.count("ration")
 quick_bandage.tooltip_text = "Usar bandagem [3] · %d disponíveis" % game.inventory.count("bandage")
 health_note.modulate = Color("f69073") if game.player.bleeding else Color.WHITE
 area_label.text = game.layout.room_name(game.player.position)
 objective.text = "RETORNE AO ABRIGO" if game.inventory.count("seal") > 0 else "RECUPERE O SELO"
 weapon_label.text = Items.info(game.inventory.equipped).get("name","Sem arma · golpes com as mãos")
 weight_label.text = "MOCHILA  %.1f / 18 kg%s" % [game.inventory.weight(),"  ·  PESADA" if game.inventory.weight() > 11 else ""]
 prompt.text = game.interaction_text()
 message_label.text = game.message_text if game.message_time > 0 else ""
 if inventory_note:
  inventory_note.text = game.message_text if game.message_time > 0 else "E vasculha recipientes próximos. I fecha a mochila."
 mini_map.queue_redraw()
 if full_map.visible:
  full_map.queue_redraw()

func damage_flash() -> void:
 flash.color.a = 0.25
 var tween = create_tween()
 tween.tween_property(flash,"color:a",0.0,0.4)

func show_ending(success: bool) -> void:
 hide_panels()
 modal.show()
 ending_panel.show()
 end_title.text = "VOCÊ VOLTOU COM O SELO" if success else "A EXPEDIÇÃO TERMINOU"
 end_note.text = ("Você recuperou o selo e atravessou as cisternas.\n" if success else "Os corredores cobram cada descuido.\n") + "\nMonstros derrotados: %d\nCarga trazida: %.1f kg\n\nNova expedição reinicia este protótipo." % [game.kills,game.inventory.weight()]
 get_tree().paused = true
