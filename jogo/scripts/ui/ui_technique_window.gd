extends UiWindow
class_name UiTechniqueWindow
## Technique editor (T): known techniques on the left; on the right the form,
## the slots (order matters: each component acts on what is to its left), the
## components unlocked by proficiency, a live preview and the bar (keys 4-7).
## Changes only out of combat. Does not pause.

var game
var ui
## Recipe being edited: index in the book (-1 = new) and the draft.
var editing: int = -1
var draft: Dictionary = {"name": "", "form": "corte", "components": []}
var list_box: VBoxContainer
var bar_box: HBoxContainer
var name_edit: LineEdit
var weapon_label: Label
var form_box: HFlowContainer
var slot_box: HBoxContainer
var component_box: GridContainer
var preview: GridContainer
var problem_label: Label
var combat_label: Label
var save_button: Button
var delete_button: Button
var assign_box: HBoxContainer
var _signature: String = ""

func _init(game_ref, ui_ref) -> void:
	super._init("Técnicas", UiIcon.new("golpe", UiStyle.ACCENT), 820, 600)
	game = game_ref
	ui = ui_ref
	position = Vector2(80, 70)
	close_requested.connect(func(): ui.toggle_techniques())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	# Left: known techniques and the bar.
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 230
	left.add_theme_constant_override("separation", 6)
	row.add_child(left)
	left.add_child(UiStyle.caps("Técnicas conhecidas", 10, UiStyle.DIM))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 3)
	scroll.add_child(list_box)
	var new_button := UiStyle.button("Nova técnica", func(): start_new())
	new_button.custom_minimum_size.y = 32
	left.add_child(new_button)
	left.add_child(UiStyle.caps("Barra  ·  teclas 4 a 7", 10, UiStyle.DIM))
	bar_box = HBoxContainer.new()
	bar_box.add_theme_constant_override("separation", 4)
	left.add_child(bar_box)
	var rule := ColorRect.new()
	rule.color = UiStyle.BORDER_SOFT
	rule.custom_minimum_size.x = 1
	row.add_child(rule)
	# Right: the editor.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	combat_label = UiStyle.label("Monstros te caçando: técnicas só mudam fora de combate.", 13, UiStyle.BAD, "medium")
	combat_label.visible = false
	right.add_child(combat_label)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Nome da técnica"
	name_edit.max_length = 28
	name_edit.text_changed.connect(func(t): draft["name"] = t; _refresh_preview())
	right.add_child(name_edit)
	weapon_label = UiStyle.caps("", 10, UiStyle.DIM)
	right.add_child(weapon_label)
	form_box = HFlowContainer.new()
	form_box.add_theme_constant_override("h_separation", 4)
	form_box.add_theme_constant_override("v_separation", 4)
	right.add_child(form_box)
	right.add_child(UiStyle.caps("Espaços  ·  cada componente age sobre o que está à esquerda dele", 10, UiStyle.DIM))
	slot_box = HBoxContainer.new()
	slot_box.add_theme_constant_override("separation", 6)
	right.add_child(slot_box)
	right.add_child(UiStyle.caps("Componentes  ·  destravam com a proficiência", 10, UiStyle.DIM))
	component_box = GridContainer.new()
	component_box.columns = 3
	component_box.add_theme_constant_override("h_separation", 4)
	component_box.add_theme_constant_override("v_separation", 4)
	right.add_child(component_box)
	var rule2 := ColorRect.new()
	rule2.color = UiStyle.BORDER_SOFT
	rule2.custom_minimum_size.y = 1
	right.add_child(rule2)
	preview = GridContainer.new()
	preview.columns = 2
	preview.add_theme_constant_override("h_separation", 14)
	preview.add_theme_constant_override("v_separation", 1)
	right.add_child(preview)
	problem_label = UiStyle.label("", 13, UiStyle.BAD, "medium")
	problem_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	problem_label.custom_minimum_size.x = 520
	right.add_child(problem_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	right.add_child(actions)
	save_button = UiStyle.button("Salvar", func(): save())
	save_button.custom_minimum_size = Vector2(90, 32)
	actions.add_child(save_button)
	delete_button = UiStyle.button("Esquecer", func(): forget())
	delete_button.custom_minimum_size = Vector2(90, 32)
	actions.add_child(delete_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	actions.add_child(UiStyle.label("Pôr na barra:", 13, UiStyle.MUTED))
	assign_box = HBoxContainer.new()
	assign_box.add_theme_constant_override("separation", 3)
	actions.add_child(assign_box)
	for i in Techniques.bar_size():
		var b := UiStyle.button(str(i + 4), assign.bind(i))
		b.custom_minimum_size = Vector2(32, 32)
		assign_box.add_child(b)

func locked() -> bool:
	return game.in_combat()

func open() -> void:
	if editing >= game.techniques.recipes.size():
		editing = -1
	if editing < 0 and draft["components"].is_empty() and draft["name"] == "":
		start_new()
	refresh(true)

## Fresh draft with the first form that fits the weapon in hand.
func start_new() -> void:
	editing = -1
	var forms: Array = Techniques.forms_for(game.inventory.equipped)
	draft = {"name": "", "form": forms[0] if not forms.is_empty() else "corte", "components": []}
	name_edit.text = ""
	refresh(true)

func edit(index: int) -> void:
	if index < 0 or index >= game.techniques.recipes.size():
		return
	editing = index
	draft = game.techniques.recipes[index].duplicate(true)
	name_edit.text = str(draft["name"])
	refresh(true)

func set_form(form_id: String) -> void:
	if locked():
		return
	draft["form"] = form_id
	var cap: int = Techniques.open_slots(game.sheet, form_id, game.inventory.equipped)
	while draft["components"].size() > cap:
		draft["components"].pop_back()
	refresh(true)

func add_component(id: String) -> void:
	if locked() or id in draft["components"]:
		return
	if draft["components"].size() >= Techniques.open_slots(game.sheet, draft["form"], game.inventory.equipped):
		game.message("Sem espaço livre. Tire um componente ou ganhe domínio na arma.", 2)
		return
	draft["components"].append(id)
	refresh(true)

func remove_component(slot: int) -> void:
	if locked() or slot >= draft["components"].size():
		return
	draft["components"].remove_at(slot)
	refresh(true)

## Moves a component one slot to the left (order changes the result).
func move_left(slot: int) -> void:
	if locked() or slot <= 0 or slot >= draft["components"].size():
		return
	var c: Array = draft["components"]
	var tmp = c[slot - 1]
	c[slot - 1] = c[slot]
	c[slot] = tmp
	refresh(true)

func save() -> int:
	if locked():
		return -1
	var index: int = game.techniques.store(draft, editing)
	if index < 0:
		game.message("Você já conhece técnicas demais. Esqueça uma antes.", 2.5)
		return -1
	editing = index
	draft = game.techniques.recipes[index].duplicate(true)
	name_edit.text = str(draft["name"])
	game.message("Técnica salva: %s." % draft["name"], 2)
	refresh(true)
	return index

func forget() -> void:
	if locked() or editing < 0:
		return
	game.techniques.remove(editing)
	start_new()

## Saves (if needed) and puts the draft on bar slot `slot`.
func assign(slot: int) -> void:
	if locked():
		return
	var index: int = save()
	if index >= 0:
		game.techniques.assign(slot, index)
		refresh(true)

func refresh(force: bool = false) -> void:
	if not visible:
		return
	var book: TechniqueBook = game.techniques
	var sig: String = "%s|%s|%s|%s|%s|%s" % [JSON.stringify(draft), editing, JSON.stringify(book.snapshot()), game.inventory.equipped, locked(), JSON.stringify(game.sheet.xp)]
	if sig == _signature and not force:
		return
	_signature = sig
	var off: bool = locked()
	combat_label.visible = off
	_fill_list()
	_fill_bar()
	var weapon: String = game.inventory.equipped
	weapon_label.text = "Forma  ·  em mãos: %s" % ("punhos" if weapon == "" else str(Items.info(weapon).get("name", weapon)))
	_clear(form_box)
	var forms: Array = Techniques.forms_for(weapon)
	if not draft["form"] in forms:
		forms.append(draft["form"])
	for id in forms:
		var unlocked: bool = Techniques.form_unlocked(game.sheet, id)
		var b := UiStyle.button(Techniques.form_name(id) if unlocked else "%s  ·  %s" % [Techniques.form_name(id), Techniques.requirement_text(Techniques.FORMS[id].get("requer", {}))], set_form.bind(id))
		b.tooltip_text = str(Techniques.FORMS[id].get("texto", ""))
		b.disabled = off or not unlocked
		if id == draft["form"]:
			b.add_theme_stylebox_override("normal", UiStyle.box(Color(0.86, 0.72, 0.40, 0.22), UiStyle.ACCENT, 1))
		form_box.add_child(b)
	_clear(slot_box)
	var form: Dictionary = Techniques.FORMS.get(draft["form"], {})
	var open_slots: int = Techniques.open_slots(game.sheet, draft["form"], weapon)
	for i in int(form.get("espacos", 1)):
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		slot_box.add_child(cell)
		if i < draft["components"].size():
			var id: String = draft["components"][i]
			if i > 0:
				var left_button := UiStyle.button("◀", move_left.bind(i))
				left_button.tooltip_text = "Passar para a esquerda"
				left_button.disabled = off
				cell.add_child(left_button)
			var b := UiStyle.button("%d. %s  ✕" % [i + 1, Techniques.component_name(id)], remove_component.bind(i))
			b.tooltip_text = "Clique para tirar.\n" + str(Techniques.COMPONENTS.get(id, {}).get("texto", ""))
			b.disabled = off
			b.custom_minimum_size = Vector2(150, 30)
			cell.add_child(b)
		else:
			var text: String = "%d. vazio" % (i + 1) if i < open_slots else "%d. domínio %d" % [i + 1, Techniques.mastery_for_slot(i + 1)]
			var empty := UiStyle.label(text, 13, UiStyle.DIM if i < open_slots else UiStyle.BAD.darkened(0.3))
			empty.custom_minimum_size = Vector2(150, 30)
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.tooltip_text = "Mais espaços abrem com o domínio da arma em mãos." if i >= open_slots else "Clique num componente abaixo para pôr aqui."
			empty.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.add_child(empty)
	_clear(component_box)
	for id in Techniques.COMPONENTS:
		var unlocked: bool = Techniques.component_unlocked(game.sheet, id)
		var fits: bool = Techniques.component_fits(id, weapon)
		var label: String = Techniques.component_name(id)
		if not unlocked:
			label += "  ·  " + Techniques.requirement_text(Techniques.COMPONENTS[id].get("requer", {}))
		elif not fits:
			label += "  ·  não nesta arma"
		var b := UiStyle.button(label, add_component.bind(id))
		b.tooltip_text = str(Techniques.COMPONENTS[id].get("texto", ""))
		b.disabled = off or not unlocked or not fits or id in draft["components"]
		b.custom_minimum_size = Vector2(176, 28)
		component_box.add_child(b)
	_refresh_preview()
	save_button.disabled = off
	delete_button.disabled = off or editing < 0
	for b in assign_box.get_children():
		b.disabled = off

func _refresh_preview() -> void:
	_clear(preview)
	var weapon: String = game.inventory.equipped
	var problem: String = Techniques.problem(game.sheet, draft, weapon)
	var base: Dictionary = game.sheet.weapon_stats(weapon)
	var s: Dictionary = Techniques.stats(game.sheet, draft, weapon)
	for row in Techniques.summary(s):
		preview.add_child(UiStyle.label(row[0], 13, UiStyle.MUTED))
		preview.add_child(UiStyle.label(row[1], 13, UiStyle.TEXT, "medium"))
	if base.has("damage"):
		preview.add_child(UiStyle.label("Golpe normal", 12, UiStyle.DIM))
		preview.add_child(UiStyle.label("dano %s, fôlego %s, preparo %s s" % [UiStyle.fmt(base["damage"]), UiStyle.fmt(base.get("cost", 10.0), 0), UiStyle.fmt(base.get("windup", 0.22), 2)], 12, UiStyle.DIM))
	problem_label.text = problem if problem != "" else "Pronta para usar com a arma em mãos."
	problem_label.add_theme_color_override("font_color", UiStyle.BAD if problem != "" else UiStyle.GOOD)

func _fill_list() -> void:
	_clear(list_box)
	var book: TechniqueBook = game.techniques
	if book.recipes.is_empty():
		var empty := UiStyle.label("Nenhuma ainda. Monte à direita e salve.", 12, UiStyle.DIM)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list_box.add_child(empty)
	for i in book.recipes.size():
		var r: Dictionary = book.recipes[i]
		var keys: PackedStringArray = []
		for s in book.bar.size():
			if book.bar[s] == i:
				keys.append(str(s + 4))
		var text: String = "%s\n%s%s" % [r["name"], Techniques.form_name(r["form"]), ("  ·  [%s]" % ",".join(keys)) if not keys.is_empty() else ""]
		var b := UiStyle.button(text, edit.bind(i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(220, 44)
		if i == editing:
			b.add_theme_stylebox_override("normal", UiStyle.box(Color(0.86, 0.72, 0.40, 0.22), UiStyle.ACCENT, 1))
		if Techniques.problem(game.sheet, r, game.inventory.equipped) != "":
			b.add_theme_color_override("font_color", UiStyle.MUTED)
		list_box.add_child(b)

func _fill_bar() -> void:
	_clear(bar_box)
	var book: TechniqueBook = game.techniques
	for s in book.bar.size():
		var r: Dictionary = book.at_slot(s)
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(54, 48)
		cell.add_theme_stylebox_override("panel", UiStyle.box(Color(1, 1, 1, 0.04), UiStyle.BORDER_SOFT, 1, Vector4(3, 2, 3, 2)))
		cell.tooltip_text = str(r.get("name", "vazio"))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(col)
		col.add_child(UiStyle.label(str(s + 4), 11, UiStyle.ACCENT, "bold"))
		var short := UiStyle.label(str(r.get("name", "—")).left(8), 11, UiStyle.TEXT if not r.is_empty() else UiStyle.DIM)
		col.add_child(short)
		bar_box.add_child(cell)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
