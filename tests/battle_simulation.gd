extends SceneTree
var deaths: int = 0
var respawns: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	world.effects_enabled = false
	for unit in world.units:
		unit.died.connect(func(_unit): deaths += 1)
	var previously_dead: Dictionary = {}
	for frame in range(18000): # 300 seconds of actual scene physics at --fixed-fps 60.
		await physics_frame
		for unit in world.units:
			if unit.is_alive and previously_dead.get(unit.unit_id, false):
				respawns += 1
			previously_dead[unit.unit_id] = not unit.is_alive
		if world.match_over:
			break
	var base_damage: float = 2400 - world.bases[0].hp - world.bases[1].hp
	print("SIMULATION: %.1fs | deaths=%d respawns=%d base_damage=%.0f match_over=%s winner=%d" % [world.elapsed, deaths, respawns, base_damage, world.match_over, world.winner])
	if deaths == 0 or respawns == 0 or base_damage <= 0 or not world.match_over:
		push_error("AI battle failed to exercise combat, respawn, base damage and result")
		quit(1)
	else:
		print("PASS: 19 AI autonomously fight, respawn, attack base and finish match")
		quit(0)
