extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(world)
	var original_yaw: float = world.camera.yaw
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 0)
	Input.parse_input_event(motion)
	await process_frame
	await process_frame
	if absf(world.camera.yaw - original_yaw) < 0.1:
		push_error("Mouse orbit input failed in graphical runtime")
		quit(1)
		return
	world.camera.yaw = original_yaw
	print("PASS: graphical mouse orbit input")
	for frame in range(60):
		await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	if screenshot.is_empty():
		push_error("Rendered screenshot is empty")
		quit(1)
		return
	var result := screenshot.save_png("/workspace/validation-logs/mistfront-prototype.png")
	print("VISUAL CAPTURE: ", result)
	if result != OK:
		quit(result)
		return
	# Staged close combat to inspect pose, target bar and live effect rendering.
	for controller in world.controllers:
		controller.set_physics_process(false)
	for unit in world.units:
		unit.movement_intent = Vector2.ZERO
	var enemy: UnitBody = world.units[10]
	enemy.position = world.player.position + Vector3(0.8, 0, -2.0)
	world.units[11].position = world.player.position + Vector3(-1.3, 0, -2.3)
	world.locked_target = enemy
	world.player.face_point(enemy.position)
	world.combat.try_skill(world.player)
	for frame in range(9):
		await physics_frame
	await RenderingServer.frame_post_draw
	result = root.get_texture().get_image().save_png("/workspace/validation-logs/combat-feedback.png")
	print("COMBAT CAPTURE: ", result)
	quit(result)
