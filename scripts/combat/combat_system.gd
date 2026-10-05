extends Node
## Single authority for player and AI attacks. No controllers write HP.
const ATTACK_RANGE: float = 2.8
const ATTACK_DAMAGE: float = 18.0
const ATTACK_COOLDOWN: float = 0.8
const SKILL_RANGE: float = 4.5
const SKILL_DAMAGE: float = 28.0
const SKILL_COOLDOWN: float = 5.0
var world: Node3D

func try_attack(attacker: UnitBody, preferred: Node3D = null) -> bool:
	if world.match_over or not attacker.is_alive or attacker.attack_remaining > 0 or attacker.dodge_remaining > 0:
		return false
	var target: Node3D = null
	if _valid_target(attacker, preferred, ATTACK_RANGE, true):
		target = preferred
	else:
		var best_distance := INF
		for candidate in world.damage_targets:
			if _valid_target(attacker, candidate, ATTACK_RANGE, true):
				var distance := attacker.global_position.distance_squared_to(candidate.global_position)
				if distance < best_distance:
					best_distance = distance
					target = candidate
	attacker.attack_remaining = ATTACK_COOLDOWN
	attacker.spawn_guard = 0
	attacker.visual.play_attack(false)
	world.show_attack_effect(attacker, ATTACK_RANGE, false)
	if target:
		target.take_damage(ATTACK_DAMAGE, attacker.team)
	return true

func try_skill(attacker: UnitBody) -> bool:
	if world.match_over or not attacker.is_alive or attacker.skill_remaining > 0 or attacker.dodge_remaining > 0:
		return false
	attacker.skill_remaining = SKILL_COOLDOWN
	attacker.spawn_guard = 0
	attacker.visual.play_attack(true)
	world.show_attack_effect(attacker, SKILL_RANGE, true)
	for target in world.damage_targets:
		if _valid_target(attacker, target, SKILL_RANGE, false):
			target.take_damage(SKILL_DAMAGE, attacker.team)
			if world.match_over:
				break
	return true

func _valid_target(attacker: UnitBody, target: Node3D, radius: float, check_facing: bool) -> bool:
	if not is_instance_valid(target) or not target.is_alive or target.team == attacker.team:
		return false
	var difference := target.global_position - attacker.global_position
	difference.y = 0
	if difference.length_squared() > radius * radius:
		return false
	return not check_facing or difference.length_squared() < 0.01 or attacker.facing.dot(difference.normalized()) >= 0.3
