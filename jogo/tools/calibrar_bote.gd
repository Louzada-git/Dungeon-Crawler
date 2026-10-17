extends SceneTree
# How far each monster's claw reaches the adventurer without the lunge, and the
# "lunge" (data/inimigos.json) that brings the touch to just past its attack
# distance ("reach" + 0.1 m). Run again after changing the monsters' attack
# animation or their models.
#   godot --headless --path . -s res://tools/calibrar_bote.gd
var game

func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	run()

func run() -> void:
	for i in 25:
		await process_frame
	if game.choosing_character:
		game.ui.creation_panel.confirmed.emit(game.ui.creation_panel.choice())
	for e in game.enemies:
		e.set_physics_process(false)
		e.position = Vector3(500, 0, 500)
	var p = game.player
	p.set_physics_process(false)
	var at: Vector3 = p.position
	for kind in ["corrompido", "espreitador", "brutamontes", "guardiao", "chefe"]:
		var e := DungeonEnemy.new()
		e.game = game
		e.kind = kind
		e.position = at + Vector3(4, 0, 0)
		game.add_child(e)
		await process_frame
		e.set_physics_process(false)
		e.stats["lunge"] = 0.0
		e.committed = Vector3.LEFT
		var lo: float = 0.3
		var hi: float = 4.0
		for it in 30:
			var mid: float = (lo + hi) * 0.5
			e.position = at + Vector3(mid, 0, 0)
			if Hitbox.monster_hits(game, e):
				lo = mid
			else:
				hi = mid
		print("BOTE|%s|reach %.2f|garra sem bote até %.2f m|lunge %.2f" % [kind, e.reach, lo, snappedf(maxf(0.0, e.reach + 0.1 - lo), 0.05)])
		e.queue_free()
	DirAccess.remove_absolute(game.save_path)
	quit()
