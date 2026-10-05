extends Node
## Translates input into movement/combat intent, never applies damage directly.
var unit: UnitBody
var camera: Camera3D
var world: Node3D

func _physics_process(_delta: float) -> void:
	if not unit.is_alive or world.match_over:
		unit.movement_intent = Vector2.ZERO
		return
	var axes := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw: float = camera.yaw
	var direction := Vector3(axes.x, 0, axes.y).rotated(Vector3.UP, yaw)
	unit.movement_intent = Vector2(direction.x, direction.z)
	if Input.is_action_just_pressed("lock_target"):
		world.cycle_lock_target()
	if is_instance_valid(world.locked_target) and world.locked_target.is_alive:
		unit.face_point(world.locked_target.global_position)
	elif direction.length_squared() > 0.01:
		unit.face_point(unit.global_position + direction)
	if Input.is_action_just_pressed("dodge"):
		unit.start_dodge()
	if Input.is_action_pressed("attack"):
		if not is_instance_valid(world.locked_target):
			unit.face_point(unit.global_position + Vector3(-sin(yaw), 0, -cos(yaw)))
		world.combat.try_attack(unit, world.locked_target)
	if Input.is_action_just_pressed("skill"):
		world.combat.try_skill(unit)
