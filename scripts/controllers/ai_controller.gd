extends Node
var unit: UnitBody
var world: Node3D
var decision_remaining: float = 0.0
var target: Node3D
var flank_phase: int = 0
var flank: bool = false
var navigation_goal := Vector3.ZERO

func _ready() -> void:
	decision_remaining = float(unit.unit_id % 10) * 0.02
	flank = unit.unit_id % 5 >= 3

func _physics_process(delta: float) -> void:
	if world.match_over or not unit.is_alive:
		unit.movement_intent = Vector2.ZERO
		if not unit.is_alive:
			flank_phase = 0
		return
	decision_remaining -= delta
	if decision_remaining <= 0:
		decision_remaining = world.config.ai_interval
		target = world.nearest_enemy(unit, 3.0 if flank else 8.0)
		if not target:
			target = world.bases[1 - unit.team]
	if not is_instance_valid(target) or not target.is_alive:
		unit.movement_intent = Vector2.ZERO
		return
	navigation_goal = world.bases[1 - unit.team].global_position if flank else target.global_position
	if flank and flank_phase == 0:
		navigation_goal = Vector3(18 if unit.team == 0 else -18, 0, -26 if unit.team == 0 else 26)
		if unit.global_position.distance_to(navigation_goal) < 2:
			flank_phase = 1
			navigation_goal = world.bases[1 - unit.team].global_position
	var difference: Vector3 = navigation_goal - unit.global_position
	difference.y = 0
	unit.face_point(navigation_goal)
	var direction := difference.normalized() if difference.length() > 2.1 else Vector3.ZERO
	# Soft separation, same collision-free steering for every AI.
	for friend in world.units:
		if friend == unit or not friend.is_alive:
			continue
		var away: Vector3 = unit.global_position - friend.global_position
		away.y = 0
		var distance_squared := away.length_squared()
		if distance_squared > 0.001 and distance_squared < 1.0:
			direction += away.normalized() * 0.65
	unit.movement_intent = Vector2(direction.x, direction.z).limit_length()
	var enemy_base: Stronghold = world.bases[1 - unit.team]
	if flank and unit.global_position.distance_to(enemy_base.global_position) <= world.combat.ATTACK_RANGE:
		target = enemy_base
		unit.face_point(enemy_base.global_position)
	var combat_distance: float = unit.global_position.distance_to(target.global_position)
	if combat_distance <= world.combat.ATTACK_RANGE:
		unit.face_point(target.global_position)
		world.combat.try_attack(unit, target)
	if combat_distance <= world.combat.SKILL_RANGE and target is UnitBody:
		world.combat.try_skill(unit)
