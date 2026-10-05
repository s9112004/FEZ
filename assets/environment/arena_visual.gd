extends Node3D
## Original decorative geometry. Forts have no gameplay or collision yet.

func _ready() -> void:
	var stone := _material(Color(0.49, 0.46, 0.4))
	var path := _material(Color(0.56, 0.5, 0.36))
	_box("Road", Vector3(0, 0.015, 0), Vector3(7, 0.02, 48), path)
	for side in [-1, 1]:
		var team_color := Color(0.14, 0.43, 0.8) if side == 1 else Color(0.8, 0.23, 0.16)
		var cloth := _material(team_color)
		var z: float = side * 24.0
		_box("Fort", Vector3(0, 1.2, z), Vector3(7, 2.4, 3), stone)
		for x in [-4.0, 4.0]:
			_box("Tower", Vector3(x, 2, z), Vector3(2, 4, 3), stone)
		_box("BannerPole", Vector3(0, 4, z), Vector3(0.12, 3.5, 0.12), stone)
		_box("Banner", Vector3(0.85, 5, z), Vector3(1.7, 1, 0.08), cloth)
	for x in [-26.0, 26.0]:
		for z in [-16.0, 0.0, 16.0]:
			_box("Rock", Vector3(x, 0.7, z), Vector3(2.2, 1.4, 2.5), stone)

func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	return result

func _box(part_name: String, location: Vector3, size: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = material
	part.position = location
	add_child(part)
