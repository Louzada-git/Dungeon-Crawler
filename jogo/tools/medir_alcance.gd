extends SceneTree
# Measures how far each melee weapon really reaches with its hitbox (the tip of
# the model over the swing of its own animation, see Hitbox.reach) and writes it
# as "range" in data/itens.json (and the fists' in data/proficiencias.json), so
# what the item shows as "Alcance" is what the blow touches.
#   godot --headless --path . -s res://tools/medir_alcance.gd
# Run again after changing a weapon model, its grip or its attack animation.
var game

func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	run()

func run() -> void:
	for i in 20:
		await process_frame
	for e in game.enemies:
		e.set_physics_process(false)
	if game.choosing_character:
		game.ui.creation_panel.confirmed.emit(game.ui.creation_panel.choice())
	game.player.set_physics_process(false)
	var path: String = ProjectSettings.globalize_path("res://data/itens.json")
	var text: String = FileAccess.get_file_as_string(path)
	for id in Items.DATA:
		if not str(Items.DATA[id].get("style", "")) in ["slash", "thrust", "smash"]:
			continue
		var value: float = snappedf(Hitbox.reach(game, id), 0.1)
		text = _set_range(text, '  "%s": {' % id, value)
		print("%s %.1f" % [id, value])
	_write(path, text)
	var fists_path: String = ProjectSettings.globalize_path("res://data/proficiencias.json")
	var fists: float = snappedf(Hitbox.reach(game, ""), 0.1)
	_write(fists_path, _set_range(FileAccess.get_file_as_string(fists_path), ' "punhos": {', fists))
	print("punhos %.1f" % fists)
	DirAccess.remove_absolute(game.save_path)
	quit()

## Replaces the first "range" after the line that opens the block.
func _set_range(text: String, opening: String, value: float) -> String:
	var at: int = text.find(opening)
	if at < 0:
		return text
	var start: int = text.find('"range": ', at)
	var end: int = text.find("\n", start)
	if start < 0 or end < 0:
		return text
	var line: String = text.substr(start, end - start)
	var comma: String = "," if line.ends_with(",") else ""
	return text.substr(0, start) + '"range": %s%s' % [str(value) if value != floorf(value) else "%.1f" % value, comma] + text.substr(end)

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
