extends SceneTree
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func _run() -> void:
	var world = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	world.effects_enabled = false
	for controller in world.controllers:
		controller.set_physics_process(false)
	check(world.units.size() == 20, "exactly 20 units")
	check(world.controllers.size() == 20, "19 AI and one player controller")
	check(world.alive_count(0) == 10 and world.alive_count(1) == 10, "10 per team")
	var player: UnitBody = world.player
	var friend: UnitBody = world.units[1]
	var enemy: UnitBody = world.units[10]
	for unit in world.units:
		unit.position = Vector3(25, 0, 25)
	player.position = Vector3.ZERO
	enemy.position = Vector3(0, 0, -2)
	friend.position = Vector3(0, 0, -1)
	player.face_point(enemy.position)
	check(world.combat.try_attack(player, enemy), "basic attack fires")
	check(enemy.hp == 74, "basic attack applies exact damage")
	check(friend.hp == 100, "basic attack excludes friendly target")
	check(not world.combat.try_attack(player, enemy) and enemy.hp == 74, "attack cooldown enforced")
	player.attack_remaining = 0
	enemy.position.z = -10
	world.combat.try_attack(player, enemy)
	check(enemy.hp == 74, "range enforced")
	player.attack_remaining = 0
	enemy.position = Vector3(0, 0, 2)
	world.combat.try_attack(player, enemy)
	check(enemy.hp == 74, "facing enforced")
	enemy.position = Vector3(0, 0, -2)
	check(world.combat.try_skill(player), "skill fires")
	check(enemy.hp == 32 and friend.hp == 100, "AoE damage without friendly fire")
	check(not world.combat.try_skill(player), "skill cooldown enforced")
	world.cycle_lock_target()
	check(world.locked_target == enemy, "locks nearby enemy")
	enemy.take_damage(100, player.team)
	check(not enemy.is_alive and enemy.hp == 0 and not enemy.visible, "death removes actor from battle")
	check(world.locked_target == null, "death clears target lock")
	check(not world.combat.try_skill(enemy), "dead unit cannot attack")
	var death_position := enemy.position
	enemy.movement_intent = Vector2.ONE
	enemy._physics_process(0.1)
	check(enemy.position == death_position, "dead unit cannot move")
	world._physics_process(world.config.respawn_delay + 0.1)
	check(enemy.is_alive and enemy.hp == 100 and enemy.visible, "scheduled respawn restores full health")
	check(enemy.position.distance_to(world.spawn_position(1, 0)) < 0.01, "respawn at friendly spawn")
	player.take_damage(50, player.team)
	check(player.hp == 100, "damage API rejects friendly fire")
	var controller = world.controllers.back()
	world.camera.yaw = PI / 2
	Input.action_press("move_forward")
	controller._physics_process(0.1)
	Input.action_release("move_forward")
	check(player.movement_intent.x < -0.9 and absf(player.movement_intent.y) < 0.01, "movement relative to camera")
	player.position = Vector3(0, 0, -22)
	player.face_point(world.bases[1].position)
	player.attack_remaining = 0
	world.combat.try_attack(player, world.bases[1])
	check(world.bases[1].hp == 1174, "base receives combat damage")
	world.bases[1].take_damage(9999, 0)
	check(world.match_over and world.winner == 0, "enemy base destruction wins")
	var remaining_hp: float = world.bases[0].hp
	check(not world.combat.try_skill(enemy) and world.bases[0].hp == remaining_hp, "combat stops on result")
	enemy.take_damage(999, 0)
	world._physics_process(10)
	check(not enemy.is_alive, "respawn stops on result")
	world.queue_free()
	await process_frame
	var second = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(second)
	await physics_frame
	second.bases[0].take_damage(9999, 1)
	check(second.match_over and second.winner == 1, "own base destruction loses")
	print("BATTLE CHECKS: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
