class_name UnitBody
extends CharacterBody3D
signal died(unit: UnitBody)
signal health_changed
var team: int = 0
var unit_id: int = 0
var is_player: bool = false
var is_alive: bool = true
var max_hp: float = 180.0
var hp: float = 180.0
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
var health_fill: Sprite3D
var hurt_guard: float = 0.0
var spawn_guard: float = 0.0
var dodge_remaining: float = 0.0
var dodge_cooldown: float = 0.0
var death_elapsed: float = 0.0
var dodge_direction := Vector2.ZERO

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
	visual = preload("res://assets/characters/sentinel.tscn").instantiate()
	visual.name = "Visual"
	add_child(visual)
	var color := Color(0.12, 0.45, 0.9) if team == 0 else Color(0.9, 0.18, 0.12)
	visual.set_team(team)
	health_label = Label3D.new()
	health_label.position.y = 2.3
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 24
	health_label.pixel_size = 0.006
	health_label.modulate = color.lightened(0.3)
	add_child(health_label)
	_build_health_bar(color)
	_refresh_label()

func _physics_process(delta: float) -> void:
	attack_remaining = maxf(0, attack_remaining - delta)
	skill_remaining = maxf(0, skill_remaining - delta)
	flash_remaining = maxf(0, flash_remaining - delta)
	hurt_guard = maxf(0, hurt_guard - delta)
	spawn_guard = maxf(0, spawn_guard - delta)
	dodge_remaining = maxf(0, dodge_remaining - delta)
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	visual.update_motion(delta, Vector2(velocity.x, velocity.z).length(), flash_remaining > 0, spawn_guard > 0 or dodge_remaining > 0)
	if not is_alive:
		death_elapsed += delta
		visual.rotation.z = minf(1.4, death_elapsed * 3.0)
		visual.position.y = -minf(0.45, death_elapsed)
		visible = death_elapsed < 0.7
		velocity = Vector3.ZERO
		return
	var intent := dodge_direction if dodge_remaining > 0 else movement_intent.limit_length()
	var speed := 16.0 if dodge_remaining > 0 else movement_speed
	velocity.x = intent.x * speed
	velocity.z = intent.y * speed
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
	if not is_alive or source_team == team or amount <= 0 or hurt_guard > 0 or spawn_guard > 0 or dodge_remaining > 0:
		return
	hp = maxf(0, hp - amount)
	hurt_guard = 0.4
	_show_damage(amount)
	flash_remaining = 0.15
	_refresh_label()
	health_changed.emit()
	if hp == 0:
		is_alive = false
		movement_intent = Vector2.ZERO
		velocity = Vector3.ZERO
		death_elapsed = 0
		health_label.visible = false
		health_fill.visible = false
		get_node("HealthBackground").visible = false
		died.emit(self)

func respawn(at_position: Vector3) -> void:
	global_position = at_position
	hp = max_hp
	is_alive = true
	visible = true
	visual.rotation.z = 0
	visual.position.y = 0
	visual.action_remaining = 0
	health_label.visible = true
	health_fill.visible = true
	get_node("HealthBackground").visible = true
	death_elapsed = 0
	respawn_remaining = 0
	attack_remaining = 0
	skill_remaining = 0
	hurt_guard = 0
	spawn_guard = 2.0
	dodge_remaining = 0
	dodge_cooldown = 0
	movement_intent = Vector2.ZERO
	velocity = Vector3.ZERO
	_refresh_label()
	health_changed.emit()

func _refresh_label() -> void:
	if health_label:
		health_label.text = ("YOU" if is_player else "AZURE" if team == 0 else "EMBER")
	if health_fill:
		var ratio := hp / max_hp
		health_fill.scale.x = ratio
		health_fill.offset.x = -48.0 * (1.0 - ratio) / ratio if ratio > 0 else 0

func start_dodge() -> bool:
	if not is_alive or dodge_cooldown > 0:
		return false
	dodge_direction = movement_intent.normalized() if movement_intent.length_squared() > 0.01 else Vector2(facing.x, facing.z)
	dodge_remaining = 0.25
	dodge_cooldown = 2.0
	return true

func _build_health_bar(color: Color) -> void:
	var image := Image.create(96, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var background := Sprite3D.new()
	background.name = "HealthBackground"
	background.texture = texture
	background.pixel_size = 0.012
	background.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	background.modulate = Color(0.035, 0.04, 0.06)
	background.position.y = 2.1
	add_child(background)
	health_fill = Sprite3D.new()
	health_fill.texture = texture
	health_fill.pixel_size = 0.012
	health_fill.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_fill.modulate = color.lightened(0.12)
	health_fill.position.y = 2.1
	health_fill.render_priority = 1
	add_child(health_fill)

func _show_damage(amount: float) -> void:
	var number := Label3D.new()
	number.text = "-%d" % amount
	number.font_size = 48
	number.pixel_size = 0.008
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.modulate = Color(1, 0.78, 0.25)
	number.position.y = 2.5
	add_child(number)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(number, "position:y", 3.2, 0.65)
	tween.tween_property(number, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(number.queue_free)
