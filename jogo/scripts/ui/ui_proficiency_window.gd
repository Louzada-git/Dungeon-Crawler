extends UiWindow
class_name UiProficiencyWindow
## Attributes and proficiencies (P). Does not pause: it can stay open while
## exploring, like the condition window.

var game
var ui
var attr_chips: Dictionary = {}
var weapon_title: Label
var weapon_path: Label
var weapon_bonus: Label
var weapon_perks: Label
var mastery_bar: ProgressBar
var rows: Dictionary = {}
var list: VBoxContainer

func _init(game_ref, ui_ref) -> void:
	super._init("Proficiências", UiIcon.new("book", UiStyle.TEXT), 500, 640)
	game = game_ref
	ui = ui_ref
	position = Vector2(60, 56)
	close_requested.connect(func(): ui.toggle_proficiencies())
	body.add_child(UiStyle.caps("Atributos · potencial", 10, UiStyle.DIM))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	body.add_child(chips)
	for id in ProficiencyTree.ATTRIBUTE_ORDER:
		var chip := Chip.new()
		chip.attr_id = id
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_theme_stylebox_override("panel", UiStyle.box(Color(1, 1, 1, 0.04), UiStyle.BORDER_SOFT, 1, Vector4(8, 4, 8, 5)))
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.tooltip_text = id
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(col)
		col.add_child(UiStyle.caps(ProficiencyTree.attribute_name(id), 9, UiStyle.DIM))
		var value := UiStyle.label("", 18, UiStyle.TEXT, "semibold")
		col.add_child(value)
		chips.add_child(chip)
		attr_chips[id] = value
	var rule := ColorRect.new()
	rule.color = UiStyle.BORDER_SOFT
	rule.custom_minimum_size.y = 1
	body.add_child(rule)
	body.add_child(UiStyle.caps("Em mãos · domínio", 10, UiStyle.DIM))
	var head := HBoxContainer.new()
	body.add_child(head)
	weapon_title = UiStyle.label("", 16, UiStyle.TEXT, "semibold")
	weapon_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(weapon_title)
	weapon_bonus = UiStyle.label("", 13, UiStyle.ACCENT, "medium")
	head.add_child(weapon_bonus)
	weapon_path = UiStyle.label("", 12, UiStyle.MUTED)
	body.add_child(weapon_path)
	mastery_bar = UiStyle.bar(Vector2(0, 6), UiStyle.ACCENT)
	body.add_child(mastery_bar)
	weapon_perks = UiStyle.label("", 12, UiStyle.MUTED)
	weapon_perks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_perks.custom_minimum_size.x = 460
	body.add_child(weapon_perks)
	var rule2 := ColorRect.new()
	rule2.color = UiStyle.BORDER_SOFT
	rule2.custom_minimum_size.y = 1
	body.add_child(rule2)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var order: Array = ProficiencyTree.roots()
	order.sort_custom(func(a, b): return int(a in ["esquiva", "tratamento"]) < int(b in ["esquiva", "tratamento"]))
	for root in order:
		_add_row(root, 0)
		for child in ProficiencyTree.children(root):
			_add_row(child, 1)
	var hint := UiStyle.label("Experiência vem do dano que você causa (dividida entre os ramos da arma), de escapar de golpes esquivando e de tratar ferimentos de verdade. Monstros de andares rasos ensinam pouco quando o domínio já está alto.", 11, UiStyle.DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 460
	body.add_child(hint)

func _add_row(branch: String, depth: int) -> void:
	var row := Row.new()
	row.window = self
	row.branch = branch
	row.depth = depth
	list.add_child(row)
	rows[branch] = row

func refresh() -> void:
	if not visible:
		return
	var sheet = game.sheet
	for id in attr_chips:
		attr_chips[id].text = str(sheet.attr(id))
	var weapon: String = game.inventory.equipped
	var path: Array = CharacterSheet.path_of(weapon)
	if weapon == "" or path.is_empty():
		weapon_title.text = "Mãos vazias"
		weapon_path.text = "Equipe uma arma para ver o domínio dela."
		weapon_bonus.text = ""
		weapon_perks.text = ""
		mastery_bar.value = 0
	else:
		var level: int = sheet.mastery(path)
		var top: int = sheet.mastery_cap(path)
		weapon_title.text = "%s  ·  nível %d de %d" % [Items.info(weapon).get("name", weapon), level, top]
		weapon_path.text = ProficiencyTree.path_text(path) + "   (" + "  +  ".join(path.map(func(b): return "%s %d" % [ProficiencyTree.display_name(b), sheet.level(b)])) + ")"
		weapon_bonus.text = "+%d%% dano  ·  −%d%% fôlego" % [roundi((sheet.damage_mult(path) - 1.0) * 100), roundi((1.0 - sheet.cost_mult(path)) * 100)]
		var low: float = ProficiencyTree.xp_for_level(level)
		var high: float = ProficiencyTree.xp_for_level(level + 1)
		mastery_bar.value = 100.0 if level >= top else clampf((sheet.path_xp(path) - low) / (high - low), 0, 1) * 100.0
		var perks: PackedStringArray = []
		for branch in path:
			for perk in sheet.active_perks(branch):
				perks.append("%s (%s)" % [perk["name"], perk["text"]])
		weapon_perks.text = ("Desbloqueado: " + "; ".join(perks)) if not perks.is_empty() else "Nenhuma habilidade desbloqueada ainda nesta arma."
	for branch in rows:
		rows[branch].active = branch in path
		rows[branch].queue_redraw()

class Chip extends PanelContainer:
	var attr_id: String = ""
	func _make_custom_tooltip(_for_text: String) -> Object:
		var info: Dictionary = ProficiencyTree.ATTRIBUTES.get(attr_id, {})
		var governs: PackedStringArray = []
		for b in ProficiencyTree.DATA:
			if ProficiencyTree.DATA[b].get("atributo", "") == attr_id:
				governs.append(ProficiencyTree.display_name(b))
		return UiStyle.tip(str(info.get("name", attr_id)), str(info.get("text", "")) + "\nPotencial (aprendizado e nível máximo): " + ", ".join(governs) + ".")

class Row extends Control:
	var window
	var branch: String = ""
	var depth: int = 0
	var active: bool = false
	var hovered: bool = false
	func _init() -> void:
		custom_minimum_size = Vector2(0, 34)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP
		tooltip_text = "ramo"
		mouse_entered.connect(func(): hovered = true; queue_redraw())
		mouse_exited.connect(func(): hovered = false; queue_redraw())
	func _draw() -> void:
		var sheet = window.game.sheet
		var w: float = size.x
		if active:
			draw_rect(Rect2(Vector2.ZERO, size), UiStyle.ROW_SELECTED)
			draw_rect(Rect2(0, 0, 2, size.y), UiStyle.ACCENT)
		elif hovered:
			draw_rect(Rect2(Vector2.ZERO, size), UiStyle.ROW_HOVER)
		var x: float = 8.0 + depth * 18.0
		var regular: Font = UiStyle.font("regular")
		var semibold: Font = UiStyle.font("semibold")
		var name_font: Font = semibold if depth == 0 else regular
		if depth > 0:
			draw_line(Vector2(x - 10, 4), Vector2(x - 10, size.y * 0.5), UiStyle.BORDER_SOFT, 1.0)
			draw_line(Vector2(x - 10, size.y * 0.5), Vector2(x - 3, size.y * 0.5), UiStyle.BORDER_SOFT, 1.0)
		var level: int = sheet.level(branch)
		var top: int = sheet.cap(branch)
		var attr: String = str(ProficiencyTree.ATTRIBUTES.get(sheet.branch_attribute(branch), {}).get("sigla", ""))
		draw_string(name_font, Vector2(x, 15), ProficiencyTree.display_name(branch), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.TEXT if level > 1 or active else Color("cfccc2"))
		draw_string(regular, Vector2(x, 29), attr, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UiStyle.DIM)
		var next: Dictionary = sheet.next_perk(branch)
		var perk_text: String = ""
		var perk_color: Color = UiStyle.DIM
		if not next.is_empty():
			perk_text = "nv %d: %s" % [int(next["nivel"]), next["name"]]
		elif not sheet.active_perks(branch).is_empty():
			perk_text = "✓ " + str(sheet.active_perks(branch)[-1]["name"])
			perk_color = UiStyle.ACCENT
		draw_string(regular, Vector2(x + 42, 29), perk_text, HORIZONTAL_ALIGNMENT_LEFT, 200, 10, perk_color)
		var bar := Rect2(w - 170, 12, 110, 6)
		draw_rect(bar, Color(0.13, 0.13, 0.12, 0.95))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * sheet.progress(branch), bar.size.y)), UiStyle.ACCENT if level < top else UiStyle.GOOD)
		draw_rect(bar, Color(0, 0, 0, 0.6), false, 1.0)
		draw_string(semibold, Vector2(w - 52, 19), "%d" % level, HORIZONTAL_ALIGNMENT_RIGHT, 26, 15, UiStyle.TEXT)
		draw_string(regular, Vector2(w - 24, 19), "/%d" % top, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiStyle.DIM)
	func _make_custom_tooltip(_for_text: String) -> Object:
		var sheet = window.game.sheet
		var data: Dictionary = ProficiencyTree.DATA.get(branch, {})
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		box.add_child(UiStyle.label(ProficiencyTree.display_name(branch), 15, UiStyle.TEXT, "semibold"))
		var level: int = sheet.level(branch)
		var xp: float = float(sheet.xp.get(branch, 0.0))
		var line: String = "Nível %d de %d" % [level, sheet.cap(branch)]
		if level < sheet.cap(branch):
			line += "  ·  faltam %d de experiência" % ceili(ProficiencyTree.xp_for_level(level + 1) - xp)
		box.add_child(UiStyle.label(line, 13, UiStyle.MUTED))
		box.add_child(UiStyle.label("Atributo: %s (aprende ×%s)" % [ProficiencyTree.attribute_name(sheet.branch_attribute(branch)), UiStyle.fmt(sheet.potential(branch), 2)], 13, UiStyle.MUTED))
		if data.has("text"):
			box.add_child(UiStyle.label(str(data["text"]), 13, UiStyle.MUTED))
		var weapons: PackedStringArray = []
		for id in Items.DATA:
			if branch in Items.DATA[id].get("proficiencias", []):
				weapons.append(str(Items.info(id).get("name", id)))
		if not weapons.is_empty():
			box.add_child(UiStyle.label("Treina com: " + ", ".join(weapons), 13, UiStyle.MUTED))
		for perk in data.get("perks", []):
			var unlocked: bool = level >= int(perk["nivel"])
			box.add_child(UiStyle.label("%s Nível %d · %s: %s" % ["✓" if unlocked else "·", int(perk["nivel"]), perk["name"], perk["text"]], 13, UiStyle.ACCENT if unlocked else UiStyle.DIM))
		return box
