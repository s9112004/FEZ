extends Node3D
const PlayerController = preload("res://scripts/controllers/player_controller.gd")
const AIController = preload("res://scripts/controllers/ai_controller.gd")
const OrbitCamera = preload("res://scripts/controllers/third_person_camera.gd")
const CombatSystem = preload("res://scripts/combat/combat_system.gd")
const BattleHUD = preload("res://scripts/ui/battle_hud.gd")
var config := BattleConfig.new()
var player: UnitBody
var camera: Camera3D
var combat: Node
var units: Array[UnitBody] = []
var bases: Array[Stronghold] = []
var damage_targets: Array[Node3D] = []
var controllers: Array[Node] = []
var locked_target: UnitBody
var match_over: bool = false
var winner: int = -1
var elapsed: float = 0.0
var lock_marker: MeshInstance3D
var effects_enabled: bool = true

func _ready() -> void:
	_register_inputs()
	_build_arena()
	combat = CombatSystem.new()
	combat.world = self
	add_child(combat)
	for team in range(2):
		var base := Stronghold.new()
		base.name = "AzureBase" if team == 0 else "EmberBase"
		base.team = team
		base.max_hp = config.base_hp
		base.hp = config.base_hp
		base.position = Vector3(0, 0, 24 if team == 0 else -24)
		base.destroyed.connect(_on_base_destroyed)
		add_child(base)
		bases.append(base)
		damage_targets.append(base)
	for team in range(2):
		for slot in range(config.team_size):
			_spawn_unit(team, slot)
	camera = OrbitCamera.new()
	camera.follow_target = player
	add_child(camera)
	var player_controller := PlayerController.new()
	player_controller.unit = player
	player_controller.camera = camera
	player_controller.world = self
	add_child(player_controller)
	controllers.append(player_controller)
	var hud := BattleHUD.new()
	hud.world = self
	add_child(hud)
	lock_marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.65
	ring.outer_radius = 0.78
	lock_marker.mesh = ring
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.9, 0.1)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lock_marker.material_override = material
	lock_marker.visible = false
	add_child(lock_marker)
	print("MATCH START: %d vs %d; 1 player, %d AI" % [config.team_size, config.team_size, controllers.size() - 1])

func _spawn_unit(team: int, slot: int) -> void:
	var unit := UnitBody.new()
	unit.team = team
	unit.unit_id = units.size()
	unit.is_player = team == 0 and slot == 0
	unit.name = "Player" if unit.is_player else "Unit_%d" % unit.unit_id
	unit.movement_speed = config.movement_speed
	unit.arena_half_size = config.arena_half_size
	unit.position = spawn_position(team, slot)
	unit.died.connect(_on_unit_died)
	add_child(unit)
	units.append(unit)
	damage_targets.append(unit)
	if unit.is_player:
		player = unit
	else:
		var controller := AIController.new()
		controller.unit = unit
		controller.world = self
		add_child(controller)
		controllers.append(controller)

func spawn_position(team: int, slot: int) -> Vector3:
	if slot == 0:
		return Vector3(0, 0.1, 15 if team == 0 else -15)
	return Vector3((slot % 5 - 2) * 1.8, 0.1, (19.0 - (slot / 5) * 1.8) * (1 if team == 0 else -1))

func _physics_process(delta: float) -> void:
	if match_over:
		return
	elapsed += delta
	for unit in units:
		if not unit.is_alive:
			unit.respawn_remaining = maxf(0, unit.respawn_remaining - delta)
			if unit.respawn_remaining <= 0:
				unit.respawn(spawn_position(unit.team, unit.unit_id % config.team_size))
	if is_instance_valid(locked_target) and (not locked_target.is_alive or locked_target.global_position.distance_to(player.global_position) > 24):
		locked_target = null

func _process(_delta: float) -> void:
	if not lock_marker:
		return
	lock_marker.visible = is_instance_valid(locked_target) and locked_target.is_alive and player.is_alive and not match_over
	if lock_marker.visible:
		lock_marker.global_position = locked_target.global_position + Vector3(0, 0.06, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart()

func restart() -> void:
	get_tree().reload_current_scene()

func nearest_enemy(unit: UnitBody, radius: float) -> UnitBody:
	var closest: UnitBody
	var best_distance := radius * radius
	for candidate in units:
		if not candidate.is_alive or candidate.team == unit.team:
			continue
		var distance := unit.global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			closest = candidate
	return closest

func cycle_lock_target() -> void:
	var candidates: Array[UnitBody] = []
	for unit in units:
		if unit.is_alive and unit.team != player.team and unit.global_position.distance_to(player.global_position) <= 24:
			candidates.append(unit)
	if candidates.is_empty():
		locked_target = null
		return
	var index := candidates.find(locked_target)
	locked_target = candidates[(index + 1) % candidates.size()]

func alive_count(team: int) -> int:
	var count := 0
	for unit in units:
		if unit.team == team and unit.is_alive:
			count += 1
	return count

func _on_unit_died(unit: UnitBody) -> void:
	unit.respawn_remaining = config.respawn_delay
	if locked_target == unit:
		locked_target = null

func _on_base_destroyed(base: Stronghold) -> void:
	if match_over:
		return
	match_over = true
	winner = 1 - base.team
	locked_target = null
	for unit in units:
		unit.movement_intent = Vector2.ZERO
		unit.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("MATCH END: winning team %d at %.1fs" % [winner, elapsed])

func show_attack_effect(unit: UnitBody, radius: float, skill: bool) -> void:
	if not effects_enabled:
		return
	var effect := preload("res://scripts/visuals/combat_effect.gd").new()
	add_child(effect)
	effect.global_position = unit.global_position + Vector3(0, 0.12, 0)
	effect.rotation.y = atan2(-unit.facing.x, -unit.facing.z)
	effect.setup(unit.team, radius, skill)

func _build_arena() -> void:
	add_child(preload("res://assets/environment/arena_visual.tscn").instantiate())
	var ground := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(config.arena_half_size * 2.0, 1.0, config.arena_half_size * 2.0)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	ground.add_child(collider)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.38, 0.29)
	visual.material_override = material
	ground.add_child(visual)
	ground.position.y = -0.5
	add_child(ground)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.4
	add_child(light)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.16, 0.24, 0.32)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.7, 0.8, 1)
	settings.ambient_light_energy = 0.5
	environment.environment = settings
	add_child(environment)

func _register_inputs() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"dodge": [KEY_SPACE], "lock_target": [KEY_TAB], "skill": [KEY_Q], "restart": [KEY_R]
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in bindings[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", click)
