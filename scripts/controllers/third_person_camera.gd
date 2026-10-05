extends Camera3D
## Orbit camera; flat arena keeps the camera clear of decorative geometry.
var follow_target: Node3D
var yaw: float = 0.0
var pitch: float = 0.32
var distance: float = 6.5
var sensitivity: float = 0.003

func _ready() -> void:
	current = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch + event.relative.y * sensitivity, 0.15, 0.95)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(4.5, distance - 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(16.0, distance + 1.0)
		elif event.button_index == MOUSE_BUTTON_LEFT and DisplayServer.get_name() != "headless":
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	if not is_instance_valid(follow_target):
		return
	var focus := follow_target.global_position + Vector3(0, 1.3, 0)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	global_position = focus + offset
	look_at(focus + Vector3(-sin(yaw), 0, -cos(yaw)) * 2.0)
