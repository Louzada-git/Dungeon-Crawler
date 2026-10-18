extends UiWindow
class_name UiTechniqueWindow
## Habilidades (T). Left: every habilidade, open or still locked. Right: the
## chosen one — fixed traits, its slots (more with the level of its branch),
## the objetos the adventurer owns (copies free / total), a live preview and the
## bar (keys chosen by the player, changed here too). Changes apply at once,
## only out of combat. Does not pause.

var game: DungeonGame
var ui
var selected: String = ""
var list_box: VBoxContainer
var hab_title: Label
var traits_label: Label
var unlock_label: Label
var slot_box: HBoxContainer
var object_box: GridContainer
var object_scroll: ScrollContainer
var preview: GridContainer
var problem_label: Label
var combat_label: Label
var assign_box: HBoxContainer
## Buttons that change the key of each bar position, and the line under them.
var key_buttons: Array = []
var key_hint: Label
## Bar position waiting for a key press (-1 when none); ui._input feeds capture_key.
var capturing: int = -1
var _signature: String = ""

func _init(game_ref, ui_ref) -> void:
	super._init("Habilidades", UiIcon.new("golpe", UiStyle.ACCENT), 840, 670)
	game = game_ref
	ui = ui_ref
	position = Vector2(80, 70)
	close_requested.connect(func(): ui.toggle_techniques())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 240
	left.add_theme_constant_override("separation", 6)
	row.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 3)
	scroll.add_child(list_box)
	var rule := ColorRect.new()
	rule.color = UiStyle.BORDER_SOFT
	rule.custom_minimum_size.x = 1
	row.add_child(rule)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	combat_label = UiStyle.label("Monstros te caçando: as habilidades só mudam fora de combate.", 13, UiStyle.BAD, "medium")
	combat_label.visible = false
	right.add_child(combat_label)
	hab_title = UiStyle.label("", 18, UiStyle.TEXT, "semibold")
	right.add_child(hab_title)
	traits_label = UiStyle.label("", 13, UiStyle.MUTED)
	traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	traits_label.custom_minimum_size.x = 540
	right.add_child(traits_label)
	unlock_label = UiStyle.label("", 12, UiStyle.DIM)
	right.add_child(unlock_label)
	right.add_child(UiStyle.caps("Slots  ·  cada objeto age sobre o que está à esquerda dele", 10, UiStyle.DIM))
	slot_box = HBoxContainer.new()
	slot_box.add_theme_constant_override("separation", 6)
	right.add_child(slot_box)
	right.add_child(UiStyle.caps("Objetos  ·  livres / cópias  ·  um por proficiência; ganhe mais subindo o nível", 10, UiStyle.DIM))
	# One objeto per proficiency branch: the ones you have come first, the rest scroll.
	object_scroll = ScrollContainer.new()
	object_scroll.custom_minimum_size.y = 132
	object_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(object_scroll)
	object_box = GridContainer.new()
	object_box.columns = 3
	object_box.add_theme_constant_override("h_separation", 4)
	object_box.add_theme_constant_override("v_separation", 4)
	object_scroll.add_child(object_box)
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
	problem_label.custom_minimum_size.x = 540
	right.add_child(problem_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	right.add_child(actions)
	var on_bar := UiStyle.label("Na barra:", 13, UiStyle.MUTED)
	on_bar.custom_minimum_size.x = 64
	actions.add_child(on_bar)
	assign_box = HBoxContainer.new()
	assign_box.add_theme_constant_override("separation", 3)
	actions.add_child(assign_box)
	for i in Techniques.bar_size():
		var b := UiStyle.button("", assign.bind(i))
		b.custom_minimum_size = Vector2(76, 32)
		b.clip_text = true
		assign_box.add_child(b)
	var off := UiStyle.button("Tirar da barra", func(): unassign())
	off.custom_minimum_size.y = 32
	assign_box.add_child(off)
	# The keys of the four bar positions: the player's choice (not the number row,
	# which is the quick bar; the numeric keypad is fine).
	var keys_row := HBoxContainer.new()
	keys_row.add_theme_constant_override("separation", 4)
	right.add_child(keys_row)
	var keys_title := UiStyle.label("Teclas:", 13, UiStyle.MUTED)
	keys_title.custom_minimum_size.x = 64
	keys_row.add_child(keys_title)
	for i in Techniques.bar_size():
		var k := UiStyle.button("", start_capture.bind(i))
		k.custom_minimum_size = Vector2(98, 30)
		k.clip_text = true
		k.tooltip_text = "Trocar a tecla do %dº espaço da barra" % (i + 1)
		keys_row.add_child(k)
		key_buttons.append(k)
	key_hint = UiStyle.label("", 12, UiStyle.DIM)
	key_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	key_hint.custom_minimum_size.x = 540
	right.add_child(key_hint)

func start_capture(slot: int) -> void:
	capturing = slot
	_show_keys()

## The key pressed while waiting. Esc cancels; the number row and the game's own
## keys are refused; a key already on another position swaps with it.
func capture_key(code: int) -> void:
	var slot: int = capturing
	capturing = -1
	if code == KEY_ESCAPE:
		_show_keys()
		return
	var why: String = game.set_technique_key(slot, code)
	_show_keys(why)

func _show_keys(problem: String = "") -> void:
	for i in key_buttons.size():
		key_buttons[i].text = "aperte…" if i == capturing else "%dº  %s" % [i + 1, game.technique_key_name(i)]
	for i in assign_box.get_child_count() - 1:
		assign_box.get_child(i).text = game.technique_key_name(i)
	if problem != "":
		key_hint.text = problem
		key_hint.add_theme_color_override("font_color", UiStyle.BAD)
	elif capturing >= 0:
		key_hint.text = "Aperte a tecla para o %dº espaço (Esc cancela). Os números de cima são da barra rápida; os do teclado numérico podem." % (capturing + 1)
		key_hint.add_theme_color_override("font_color", UiStyle.ACCENT)
	else:
		key_hint.text = "Clique numa tecla para trocar. Os números de cima são da barra rápida; o teclado numérico pode."
		key_hint.add_theme_color_override("font_color", UiStyle.DIM)

func locked() -> bool:
	return game.in_combat()

func open() -> void:
	if selected == "" or not Techniques.FORMS.has(selected):
		var forms: Array = Techniques.forms_for(game.inventory.equipped)
		selected = forms[0] if not forms.is_empty() else Techniques.FORMS.keys()[0]
	refresh(true)

func select(form_id: String) -> void:
	selected = form_id
	refresh(true)

## Objetos you have and that fit the weapon first, then the others you have,
## then the ones still locked (in data order inside each group).
func object_order(weapon: String) -> Array:
	var groups: Array = [[], [], []]
	for id in Techniques.OBJECTS:
		if Techniques.copies(game.sheet, id) <= 0:
			groups[2].append(id)
		elif Techniques.object_fits(id, weapon):
			groups[0].append(id)
		else:
			groups[1].append(id)
	return groups[0] + groups[1] + groups[2]

func editable() -> bool:
	return not locked() and Techniques.form_unlocked(game.sheet, selected)

func free_copies(id: String) -> int:
	return Techniques.copies(game.sheet, id) - game.techniques.in_use(id)

func add_object(id: String) -> void:
	if not editable() or free_copies(id) <= 0 or not Techniques.object_fits(id, game.inventory.equipped):
		return
	var objs: Array = game.techniques.objects(selected).duplicate()
	if objs.size() >= Techniques.open_slots(game.sheet, selected, game.inventory.equipped):
		game.message("Sem slot livre em %s. Tire um objeto ou suba %s." % [Techniques.form_name(selected), _slot_measure()], 2.5)
		return
	objs.append(id)
	game.techniques.set_objects(selected, objs)
	refresh(true)

func remove_object(slot: int) -> void:
	if not editable():
		return
	var objs: Array = game.techniques.objects(selected).duplicate()
	if slot < objs.size():
		objs.remove_at(slot)
		game.techniques.set_objects(selected, objs)
		refresh(true)

## Moves an objeto one slot to the left (order changes the result).
func move_left(slot: int) -> void:
	if not editable():
		return
	var objs: Array = game.techniques.objects(selected).duplicate()
	if slot <= 0 or slot >= objs.size():
		return
	var tmp = objs[slot - 1]
	objs[slot - 1] = objs[slot]
	objs[slot] = tmp
	game.techniques.set_objects(selected, objs)
	refresh(true)

func assign(slot: int) -> void:
	if not editable():
		return
	game.techniques.assign(slot, selected)
	refresh(true)

func unassign() -> void:
	if locked():
		return
	var bar: Array = game.techniques.bar
	for i in bar.size():
		if bar[i] == selected:
			game.techniques.assign(i, "")
	refresh(true)

## The window shows levels, not raw experience, which grows every frame while
## running or sneaking near a monster: rebuilding the buttons then would swallow
## clicks. Levels of every branch and the mastery of the weapon in hand.
func _levels_signature(weapon: String) -> String:
	var parts: PackedStringArray = []
	for branch in ProficiencyTree.DATA:
		parts.append(str(game.sheet.level(branch)))
	var path: Array = CharacterSheet.path_of(weapon)
	parts.append("dominio:%d" % (game.sheet.mastery(path) if not path.is_empty() else 1))
	return ",".join(parts)

## What grows this habilidade's slots, in words.
func _slot_measure() -> String:
	if Techniques.basic(selected):
		return "o domínio da arma"
	return ProficiencyTree.display_name(str(Techniques.FORMS[selected]["requer"].keys()[0]))

func refresh(force: bool = false) -> void:
	if not visible:
		return
	var book: TechniqueBook = game.techniques
	var weapon: String = game.inventory.equipped
	var sig: String = "%s|%s|%s|%s|%s" % [selected, JSON.stringify(book.snapshot()), weapon, locked(), _levels_signature(weapon)]
	if sig == _signature and not force:
		return
	_signature = sig
	var off: bool = not editable()
	combat_label.visible = locked()
	_show_keys()
	_fill_list()
	var form: Dictionary = Techniques.FORMS.get(selected, {})
	var unlocked: bool = Techniques.form_unlocked(game.sheet, selected)
	hab_title.text = Techniques.form_name(selected)
	traits_label.text = str(form.get("texto", ""))
	if Techniques.basic(selected):
		unlock_label.text = "Básica: o golpe da arma em mãos. Slots crescem com o domínio da arma."
	elif unlocked:
		unlock_label.text = "Destravada com %s. Slots crescem com %s." % [Techniques.requirement_text(form["requer"]), _slot_measure()]
	else:
		unlock_label.text = "Trancada: precisa de %s." % Techniques.requirement_text(form["requer"])
	# Slots
	_clear(slot_box)
	var objs: Array = book.objects(selected)
	var open_slots: int = Techniques.open_slots(game.sheet, selected, weapon) if unlocked else 0
	for i in int(form.get("slots", 1)):
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		slot_box.add_child(cell)
		if i < objs.size():
			var id: String = objs[i]
			if i > 0:
				var left_button := UiStyle.button("◀", move_left.bind(i))
				left_button.tooltip_text = "Passar para a esquerda"
				left_button.disabled = off
				cell.add_child(left_button)
			var b := UiStyle.button("%d. %s  ✕" % [i + 1, Techniques.object_name(id)], remove_object.bind(i))
			b.tooltip_text = "Clique para tirar.\n" + str(Techniques.OBJECTS.get(id, {}).get("texto", ""))
			b.disabled = off
			b.custom_minimum_size = Vector2(150, 30)
			cell.add_child(b)
		else:
			var need: int = Techniques.level_for_slot(selected, i + 1)
			var text: String
			if i < open_slots:
				text = "%d. vazio" % (i + 1)
			elif Techniques.basic(selected):
				text = "%d. domínio %d" % [i + 1, need]
			else:
				text = "%d. %s %d" % [i + 1, _slot_measure(), need]
			var empty := UiStyle.label(text, 13, UiStyle.DIM if i < open_slots else UiStyle.BAD.darkened(0.3))
			empty.custom_minimum_size = Vector2(150, 30)
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.mouse_filter = Control.MOUSE_FILTER_STOP
			empty.tooltip_text = "Clique num objeto abaixo para pôr aqui." if i < open_slots else "Este slot abre quando %s chegar a %d." % [_slot_measure(), need]
			cell.add_child(empty)
	# Objetos
	_clear(object_box)
	for id in object_order(weapon):
		var have: int = Techniques.copies(game.sheet, id)
		var free: int = have - book.in_use(id)
		var fits: bool = Techniques.object_fits(id, weapon)
		var label: String
		if have == 0:
			var branch: String = Techniques.object_branch(id)
			label = "%s  ·  %s %d" % [Techniques.object_name(id), ProficiencyTree.display_name(branch), int(Techniques.OBJECTS[id]["requer"][branch])]
		else:
			label = "%s  %d/%d" % [Techniques.object_name(id), maxi(free, 0), have]
		var b := UiStyle.button(label, add_object.bind(id))
		var next: int = Techniques.next_copy_level(game.sheet, id)
		var tip: String = "%s (%s)\n%s" % [Techniques.object_name(id), ProficiencyTree.display_name(Techniques.object_branch(id)), str(Techniques.OBJECTS[id].get("texto", ""))]
		if have == 0:
			tip += "\nDestrava com %s." % Techniques.requirement_text(Techniques.OBJECTS[id].get("requer", {}))
		elif next > 0:
			tip += "\nPróxima cópia: %s nível %d." % [ProficiencyTree.display_name(Techniques.object_branch(id)), next]
		if not fits:
			tip += "\nNão faz sentido com a arma em mãos."
		b.tooltip_text = tip
		b.disabled = off or free <= 0 or not fits
		b.custom_minimum_size = Vector2(178, 28)
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		object_box.add_child(b)
	# Preview
	_clear(preview)
	var problem: String = Techniques.problem(game.sheet, book, selected, weapon)
	var base: Dictionary = game.sheet.weapon_stats(weapon)
	if Techniques.form_fits(selected, weapon):
		for row in Techniques.summary(Techniques.stats(game.sheet, selected, objs, weapon), game.sheet.weapon_stats(weapon)):
			preview.add_child(UiStyle.label(row[0], 13, UiStyle.MUTED))
			preview.add_child(UiStyle.label(row[1], 13, UiStyle.TEXT, "medium"))
		if base.has("damage"):
			preview.add_child(UiStyle.label("Golpe normal", 12, UiStyle.DIM))
			preview.add_child(UiStyle.label("dano %s, fôlego %s, preparo %s s" % [UiStyle.fmt(base["damage"]), UiStyle.num(float(base.get("cost", 10.0))), UiStyle.fmt(base.get("windup", 0.22), 2)], 12, UiStyle.DIM))
	problem_label.text = problem if problem != "" else "Pronta para usar com a arma em mãos."
	problem_label.add_theme_color_override("font_color", UiStyle.BAD if problem != "" else UiStyle.GOOD)
	for b in assign_box.get_children():
		b.disabled = locked() or (not unlocked and b.text != "Tirar da barra")

func _fill_list() -> void:
	_clear(list_box)
	var book: TechniqueBook = game.techniques
	var weapon: String = game.inventory.equipped
	var fit: Array = Techniques.forms_for(weapon)
	var others: Array = Techniques.FORMS.keys().filter(func(f): return not f in fit)
	for group in [["Com a arma em mãos", fit], ["Outras armas", others]]:
		if group[1].is_empty():
			continue
		list_box.add_child(UiStyle.caps(group[0], 10, UiStyle.DIM))
		for form_id in group[1]:
			var unlocked: bool = Techniques.form_unlocked(game.sheet, form_id)
			var keys: PackedStringArray = []
			for s in book.bar.size():
				if book.bar[s] == form_id:
					keys.append(game.technique_key_name(s))
			var line: String
			if unlocked:
				line = "%d objeto%s%s" % [book.objects(form_id).size(), "" if book.objects(form_id).size() == 1 else "s", ("  ·  barra [%s]" % ",".join(keys)) if not keys.is_empty() else ""]
			else:
				line = "trancada  ·  " + Techniques.requirement_text(Techniques.FORMS[form_id].get("requer", {}))
			var b := UiStyle.button("%s\n%s" % [Techniques.form_name(form_id), line], select.bind(form_id))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size = Vector2(230, 44)
			if form_id == selected:
				b.add_theme_stylebox_override("normal", UiStyle.box(Color(0.86, 0.72, 0.40, 0.22), UiStyle.ACCENT, 1))
			if not unlocked or not form_id in fit:
				b.add_theme_color_override("font_color", UiStyle.DIM)
			list_box.add_child(b)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
