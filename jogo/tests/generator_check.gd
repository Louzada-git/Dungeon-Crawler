extends SceneTree
# Generates many floors and reports problems, sizes and timing.
#   godot --headless --path . -s res://tests/generator_check.gd -- <seeds> <max_floor>
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds: int = int(args[0]) if args.size() > 0 else 50
	var max_floor: int = int(args[1]) if args.size() > 1 else 3
	var failures: int = 0
	for floor_number in range(1, max_floor + 1):
		var t0 := Time.get_ticks_msec()
		var cells: int = 0
		var enemies: int = 0
		var chests: int = 0
		var bad: int = 0
		for s in seeds:
			var d: Dictionary = LabyrinthGenerator.generate(1000 + s * 37, floor_number)
			var problems: Array = LabyrinthGenerator.validate(d)
			if not problems.is_empty():
				bad += 1
				if bad <= 3:
					print("seed %d floor %d: %s" % [1000 + s * 37, floor_number, str(problems)])
			cells += d["size"][0] * d["size"][1]
			enemies += d["enemies"].size()
			chests += d["containers"].size()
		failures += bad
		print("FLOOR %d: %d seeds, %d with problems, avg grid %d cells, avg enemies %.1f, avg chests %.1f, %.0f ms/floor" % [floor_number, seeds, bad, roundi(float(cells) / seeds), float(enemies) / seeds, float(chests) / seeds, float(Time.get_ticks_msec() - t0) / seeds])
	var a = JSON.stringify(LabyrinthGenerator.generate(4242, 2))
	var b = JSON.stringify(LabyrinthGenerator.generate(4242, 2))
	print("DETERMINISTIC ", a == b, "  DIFFERENT SEEDS DIFFER ", a != JSON.stringify(LabyrinthGenerator.generate(4243, 2)))
	print("GENERATOR FAILURES %d" % failures)
	quit(0 if failures == 0 else 1)
