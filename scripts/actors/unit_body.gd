class_name UnitBody
extends CharacterBody3D
signal died(unit: UnitBody)
signal health_changed
var team: int = 0
var unit_id: int = 0
var is_player: bool = false
var is_alive: bool = true
var max_hp: float = 100.0
var hp: float = 100.0
var respawn_remaining: float = 0.0
var attack_remaining: float = 0.0
var skill_remaining: float = 0.0
var movement_intent := Vector2.ZERO
var movement_speed: float = 6.0
var arena_half_size: float = 30.0
var gravity: float = 20.0
var facing := Vector3.FORWARD
var visual: Node3D
var flash_remaining: float = 0.0
var health_label: Label3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 # Ground only; steering separates crowds without physics jams.
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	visual = preload("res://assets/characters/scout.tscn").instantiate()
	visual.name = "Visual"
	add_child(visual)
	var color := Color(0.12, 0.45, 0.9) if team == 0 else Color(0.9, 0.18, 0.12)
	for part_name in ["Torso", "Shield"]:
		var mesh := visual.get_node(part_name) as MeshInstance3D
		var mat := mesh.material_override.duplicate() as StandardMaterial3D
		mat.albedo_color = color
		mesh.material_override = mat
	health_label = Label3D.new()
	health_label.position.y = 2.1
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 32
	health_label.pixel_size = 0.006
	health_label.modulate = color.lightened(0.3)
	add_child(health_label)
	_refresh_label()

func _physics_process(delta: float) -> void:
	attack_remaining = maxf(0, attack_remaining - delta)
	skill_remaining = maxf(0, skill_remaining - delta)
	flash_remaining = maxf(0, flash_remaining - delta)
	visual.scale = Vector3.ONE * (1.06 if flash_remaining > 0 else 1.0)
	if not is_alive:
		velocity = Vector3.ZERO
		return
	var intent := movement_intent.limit_length()
	velocity.x = intent.x * movement_speed
	velocity.z = intent.y * movement_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	position.x = clampf(position.x, -arena_half_size + 0.5, arena_half_size - 0.5)
	position.z = clampf(position.z, -arena_half_size + 0.5, arena_half_size - 0.5)

func face_point(point: Vector3) -> void:
	var direction := point - global_position
	direction.y = 0
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
		visual.rotation.y = atan2(-facing.x, -facing.z)

func take_damage(amount: float, source_team: int) -> void:
	if not is_alive or source_team == team or amount <= 0:
		return
	hp = maxf(0, hp - amount)
	flash_remaining = 0.15
	_refresh_label()
	health_changed.emit()
	if hp == 0:
		is_alive = false
		movement_intent = Vector2.ZERO
		velocity = Vector3.ZERO
		visible = false
		died.emit(self)

func respawn(at_position: Vector3) -> void:
	global_position = at_position
	hp = max_hp
	is_alive = true
	visible = true
	respawn_remaining = 0
	attack_remaining = 0
	skill_remaining = 0
	movement_intent = Vector2.ZERO
	velocity = Vector3.ZERO
	_refresh_label()
	health_changed.emit()

func _refresh_label() -> void:
	if health_label:
		health_label.text = ("YOU " if is_player else "") + str(int(hp))
