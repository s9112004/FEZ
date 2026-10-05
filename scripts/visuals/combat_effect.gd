extends Node3D
## Short-lived original mesh effects; no downloaded textures.
func setup(team: int, radius: float, skill: bool) -> void:
	var color := Color(0.3, 0.85, 1, 0.75) if team == 0 else Color(1, 0.45, 0.18, 0.75)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var duration := 0.65 if skill else 0.35
	var mesh := MeshInstance3D.new()
	if skill:
		var ring := TorusMesh.new()
		ring.inner_radius = radius - 0.15
		ring.outer_radius = radius
		ring.rings = 16
		ring.ring_segments = 24
		mesh.mesh = ring
		scale = Vector3(0.12, 1, 0.12)
		for index in range(8):
			var shard := MeshInstance3D.new()
			var crystal := CylinderMesh.new()
			crystal.top_radius = 0
			crystal.bottom_radius = 0.09
			crystal.height = 0.65
			crystal.radial_segments = 4
			shard.mesh = crystal
			shard.material_override = mat
			var angle := index * TAU / 8.0
			shard.position = Vector3(sin(angle) * radius, 0.6, cos(angle) * radius)
			add_child(shard)
		create_tween().tween_property(self, "scale", Vector3.ONE, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		var vertices := PackedVector3Array()
		for index in range(20):
			var a := lerpf(-1.0, 1.0, index / 20.0)
			var b := lerpf(-1.0, 1.0, (index + 1) / 20.0)
			var outer_a := Vector3(sin(a) * radius, 0.8, -cos(a) * radius)
			var inner_a := outer_a * Vector3(0.76, 1, 0.76)
			var outer_b := Vector3(sin(b) * radius, 0.8, -cos(b) * radius)
			var inner_b := outer_b * Vector3(0.76, 1, 0.76)
			vertices.append_array(PackedVector3Array([inner_a, outer_a, outer_b, inner_a, outer_b, inner_b]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var arc := ArrayMesh.new()
		arc.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.mesh = arc
	mesh.material_override = mat
	add_child(mesh)
	var tween := create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	tween.tween_callback(queue_free)
