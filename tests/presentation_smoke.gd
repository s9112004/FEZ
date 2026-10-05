extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	var world = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	for controller in world.controllers:
		controller.set_physics_process(false)
	var player: UnitBody = world.player
	var visual = player.visual
	visual.update_motion(0.1, 6, false, false)
	check(absf(visual.left_leg.rotation.x) > 0.1, "walking animates legs")
	check(visual.left_leg.rotation.x * visual.right_leg.rotation.x < 0, "walk alternates legs")
	visual.play_attack(false)
	visual.update_motion(0.15, 0, false, false)
	check(visual.right_arm.rotation.x < -0.5, "sword attack swings arm")
	visual.play_attack(true)
	visual.update_motion(0.2, 0, false, false)
	check(visual.left_arm.rotation.x < -0.5, "skill animates both arms")
	visual.update_motion(1.0, 0, false, false)
	check(visual.action_remaining == 0 and absf(visual.right_arm.rotation.x) < 0.01, "attack returns to idle")
	world.show_attack_effect(player, 2.8, false)
	world.show_attack_effect(player, 4.5, true)
	var effect_script = load("res://scripts/visuals/combat_effect.gd")
	var effect_count := 0
	for child in world.get_children():
		if child.get_script() == effect_script:
			effect_count += 1
	check(effect_count == 2, "sword and shockwave effects instantiated")
	player.take_damage(18, 1)
	check(absf(player.health_fill.scale.x - 0.9) < 0.01, "head health fill matches HP")
	check(absf((player.health_fill.offset.x - 48) * player.health_fill.scale.x + 48) < 0.01, "health fill keeps its left edge fixed")
	player.hurt_guard = 0
	player.take_damage(999, 1)
	player._physics_process(0.25)
	check(not player.is_alive and player.visual.rotation.z > 0.5, "dead body falls without fighting")
	player._physics_process(0.6)
	check(not player.visible, "corpse hides after fall")
	player.respawn(world.spawn_position(0, 0))
	check(player.visible and player.visual.rotation.z == 0 and player.health_fill.visible, "respawn resets death pose and bars")
	for frame in range(50):
		await physics_frame
	effect_count = 0
	for child in world.get_children():
		if child.get_script() == effect_script:
			effect_count += 1
	check(effect_count == 0, "effects clean up after their lifetime")
	print("PRESENTATION CHECKS: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
