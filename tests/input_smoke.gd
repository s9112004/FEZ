extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run() -> void:
	var world = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await physics_frame
	for controller in world.controllers:
		if controller.unit != world.player:
			controller.set_physics_process(false)
	var start: Vector3 = world.player.position
	key(KEY_W, true)
	for frame in range(30):
		await physics_frame
	key(KEY_W, false)
	await physics_frame
	check(world.player.position.z < start.z - 2, "W input must move player via real controller")
	for unit in world.units:
		if unit != world.player:
			unit.position = Vector3(25, 0, 25)
	var enemy: UnitBody = world.units[10]
	enemy.position = world.player.position + Vector3(0, 0, -2)
	key(KEY_TAB, true)
	await physics_frame
	await physics_frame
	key(KEY_TAB, false)
	check(world.locked_target == enemy, "Tab input must lock enemy")
	key(KEY_Q, true)
	await physics_frame
	await physics_frame
	key(KEY_Q, false)
	check(enemy.hp == 152, "Q input must execute skill")
	for frame in range(26):
		await physics_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await physics_frame
	await physics_frame
	click.pressed = false
	Input.parse_input_event(click)
	check(enemy.hp == 134, "LMB input must execute normal attack")
	var before_dodge: Vector3 = world.player.position
	key(KEY_SPACE, true)
	for frame in range(16):
		await physics_frame
	key(KEY_SPACE, false)
	check(world.player.position.distance_to(before_dodge) > 3 and world.player.dodge_cooldown > 0, "Space input evades and starts cooldown")
	world.bases[1].take_damage(9999, 0)
	await process_frame
	await process_frame
	var hud: Node
	for child in world.get_children():
		if child.get_script() == load("res://scripts/ui/battle_hud.gd"):
			hud = child
	check(hud.result.text.contains("VICTORY") and hud.restart_button.visible, "HUD must show win and restart")
	key(KEY_R, true)
	await process_frame
	await process_frame
	await physics_frame
	key(KEY_R, false)
	check(is_instance_valid(current_scene) and current_scene != world, "R input must reload scene")
	check(current_scene.units.size() == 20 and not current_scene.match_over and current_scene.bases[1].hp == 3600, "restart restores new match")
	print("INPUT CHECKS: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
