extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var unit = world.player
	# Disable the input adapter while testing the shared physics contract.
	for child in world.get_children():
		if child.get_script() == load("res://scripts/controllers/player_controller.gd"):
			child.set_physics_process(false)
	var start: Vector3 = unit.position
	unit.movement_intent = Vector2(1, 0)
	for frame in range(60):
		await physics_frame
	if unit.position.x < start.x + 4.0:
		_fail("Movement did not advance the unit")
		return
	unit.movement_intent = Vector2.ZERO
	for frame in range(10):
		await physics_frame
	if absf(unit.position.y) > 0.1 or not unit.is_on_floor():
		_fail("Ground collision failed")
		return
	unit.position.x = 29.4
	unit.movement_intent = Vector2(1, 1)
	for frame in range(30):
		await physics_frame
	if unit.position.x > 29.5 or unit.velocity.length() > 6.1:
		_fail("Boundary or diagonal speed limit failed")
		return
	print("PASS: movement, ground collision, boundary, diagonal speed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
