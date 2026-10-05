extends Node3D
## Original procedural joint rig. Gameplay physics stays on UnitBody.
var team_material: StandardMaterial3D
var torso: Node3D
var right_arm: Node3D
var left_arm: Node3D
var right_leg: Node3D
var left_leg: Node3D
var cloak: Node3D
var phase: float = 0
var action_remaining: float = 0
var action_duration: float = 0.45
var skill_action: bool = false
var speed_ratio: float = 0
var hit_flash: float = 0

func _ready() -> void:
	team_material = _mat(Color(0.1, 0.38, 0.7))
	var metal := _mat(Color(0.48, 0.57, 0.65), 0.6)
	var trim := _mat(Color(0.76, 0.57, 0.27), 0.4)
	var leather := _mat(Color(0.12, 0.14, 0.19))
	var skin := _mat(Color(0.72, 0.53, 0.38))
	torso = _pivot(self, "TorsoPivot", Vector3(0, 1.13, 0))
	_cylinder(torso, "Coat", Vector3(0, -0.22, 0), 0.23, 0.32, 0.52, team_material)
	_cylinder(torso, "Breastplate", Vector3(0, 0.05, 0), 0.29, 0.22, 0.44, metal)
	_box(torso, "Belt", Vector3(0, -0.16, 0), Vector3(0.55, 0.08, 0.34), leather)
	_box(torso, "Buckle", Vector3(0, -0.16, -0.18), Vector3(0.09, 0.08, 0.03), trim)
	_sphere(torso, "Head", Vector3(0, 0.46, 0), 0.19, skin)
	_cylinder(torso, "Helmet", Vector3(0, 0.59, 0.025), 0.15, 0.22, 0.19, metal)
	_box(torso, "Brow", Vector3(0, 0.53, -0.17), Vector3(0.35, 0.035, 0.05), trim)
	_box(torso, "EyeLeft", Vector3(-0.068, 0.46, -0.171), Vector3(0.045, 0.024, 0.025), leather)
	_box(torso, "EyeRight", Vector3(0.068, 0.46, -0.171), Vector3(0.045, 0.024, 0.025), leather)
	_box(torso, "Nose", Vector3(0, 0.41, -0.193), Vector3(0.048, 0.06, 0.045), skin)
	_cylinder(torso, "Plume", Vector3(0, 0.76, 0.04), 0.015, 0.075, 0.21, team_material)
	left_arm = _pivot(torso, "LeftArmPivot", Vector3(-0.34, 0.16, 0))
	right_arm = _pivot(torso, "RightArmPivot", Vector3(0.34, 0.16, 0))
	for arm in [left_arm, right_arm]:
		_sphere(arm, "Pauldron", Vector3.ZERO, 0.15, metal)
		_cylinder(arm, "Sleeve", Vector3(0, -0.16, 0), 0.1, 0.085, 0.3, team_material)
		_cylinder(arm, "Bracer", Vector3(0, -0.36, 0), 0.085, 0.07, 0.19, metal)
		_sphere(arm, "Hand", Vector3(0, -0.47, 0), 0.075, leather)
	var sword := _pivot(right_arm, "Sword", Vector3(0, -0.47, -0.04))
	_box(sword, "Grip", Vector3(0, 0, -0.06), Vector3(0.07, 0.08, 0.16), leather)
	_box(sword, "Guard", Vector3(0, 0, -0.16), Vector3(0.25, 0.07, 0.055), trim)
	_box(sword, "Blade", Vector3(0, 0, -0.57), Vector3(0.095, 0.035, 0.78), metal)
	var shield := _pivot(left_arm, "Shield", Vector3(-0.08, -0.3, -0.08))
	_cylinder(shield, "Rim", Vector3.ZERO, 0.28, 0.28, 0.055, trim).rotation.z = PI / 2
	_cylinder(shield, "Face", Vector3(-0.034, 0, 0), 0.25, 0.25, 0.025, team_material).rotation.z = PI / 2
	_sphere(shield, "Boss", Vector3(-0.064, 0, 0), 0.09, metal)
	left_leg = _pivot(self, "LeftLegPivot", Vector3(-0.14, 0.72, 0))
	right_leg = _pivot(self, "RightLegPivot", Vector3(0.14, 0.72, 0))
	for leg in [left_leg, right_leg]:
		_cylinder(leg, "Leg", Vector3(0, -0.2, 0), 0.09, 0.075, 0.4, leather)
		_cylinder(leg, "Greave", Vector3(0, -0.47, 0), 0.085, 0.075, 0.23, metal)
		_box(leg, "Boot", Vector3(0, -0.64, -0.045), Vector3(0.17, 0.15, 0.28), leather)
	cloak = _pivot(torso, "CloakPivot", Vector3(0, 0.18, 0.19))
	_cylinder(cloak, "Mantle", Vector3(0, -0.4, 0.08), 0.12, 0.35, 0.75, team_material).scale = Vector3(1, 1, 0.22)

func set_team(team: int) -> void:
	team_material.albedo_color = Color(0.12, 0.4, 0.7) if team == 0 else Color(0.72, 0.19, 0.12)

func play_attack(skill: bool) -> void:
	skill_action = skill
	action_duration = 0.65 if skill else 0.45
	action_remaining = action_duration

func update_motion(delta: float, speed: float, hurt: bool, protected: bool) -> void:
	speed_ratio = clampf(speed / 6.0, 0, 1.5)
	phase += delta * (9.0 if speed_ratio > 0.1 else 2.0)
	action_remaining = maxf(0, action_remaining - delta)
	var stride := sin(phase) * 0.6 * speed_ratio
	left_leg.rotation.x = stride
	right_leg.rotation.x = -stride
	left_arm.rotation.x = -stride * 0.55
	right_arm.rotation = Vector3(stride * 0.55, 0, -0.12)
	torso.position.y = 1.13 + (absf(sin(phase)) * 0.025 * speed_ratio if speed_ratio > 0.1 else sin(phase) * 0.008)
	torso.rotation = Vector3(0, 0, 0)
	cloak.rotation.x = 0.15 + speed_ratio * 0.22 + sin(phase) * 0.06
	if action_remaining > 0:
		var progress := 1.0 - action_remaining / action_duration
		var swing := sin(progress * PI)
		right_arm.rotation.x = -1.3 * swing
		right_arm.rotation.y = lerpf(-0.8, 1.4, progress) * swing
		torso.rotation.y = swing * (0.6 if skill_action else 0.25)
		if skill_action:
			left_arm.rotation.x = -1.1 * swing
			torso.position.y += swing * 0.12
	if hurt:
		torso.rotation.x = -0.16
	team_material.emission_enabled = hurt or protected
	team_material.emission = Color(0.5, 0.7, 1) if protected else Color(0.65, 0.15, 0.05)
	team_material.emission_energy_multiplier = 0.45

func _mat(color: Color, metallic: float = 0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.65
	return material

func _pivot(parent: Node3D, part_name: String, at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = at
	parent.add_child(pivot)
	return pivot

func _mesh(parent: Node3D, part_name: String, at: Vector3, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.position = at
	part.mesh = mesh
	part.material_override = mat
	parent.add_child(part)
	return part

func _box(parent: Node3D, part_name: String, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, part_name, at, mesh, mat)

func _cylinder(parent: Node3D, part_name: String, at: Vector3, top: float, bottom: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	return _mesh(parent, part_name, at, mesh, mat)

func _sphere(parent: Node3D, part_name: String, at: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 12
	mesh.rings = 8
	return _mesh(parent, part_name, at, mesh, mat)
