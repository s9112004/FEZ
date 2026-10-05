extends Control
var world: Node3D
var refresh: float = 0

func _process(delta: float) -> void:
	refresh -= delta
	if refresh <= 0:
		refresh = 0.1
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.07, 0.1, 0.9))
	draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), Color(0.32, 0.42, 0.46), false, 1)
	draw_line(Vector2(size.x / 2, 8), Vector2(size.x / 2, size.y - 8), Color(0.3, 0.35, 0.25), 10)
	for base in world.bases:
		draw_rect(Rect2(_point(base.position) - Vector2(5, 5), Vector2(10, 10)), Color(0.2, 0.6, 1) if base.team == 0 else Color(1, 0.3, 0.2))
	for unit in world.units:
		if unit.is_alive:
			var point := _point(unit.position)
			draw_circle(point, 3, Color(0.2, 0.6, 1) if unit.team == 0 else Color(1, 0.3, 0.2))
			if unit.is_player:
				draw_arc(point, 6, 0, TAU, 16, Color.WHITE, 2)

func _point(at: Vector3) -> Vector2:
	var ratio: Vector2 = Vector2(at.x, at.z) / (world.config.arena_half_size * 2.0) + Vector2(0.5, 0.5)
	return Vector2(8, 8) + ratio * (size - Vector2(16, 16))
