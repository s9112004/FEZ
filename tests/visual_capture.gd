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
	quit(result)
