extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for number in range(1, 11):
		var path := "res://assets/models/source/collectibles/%d.glb" % number
		var scene := load(path) as PackedScene
		if scene == null:
			push_error("COLLECTIBLE_ASSET_LOAD_FAILED %d" % number)
			continue
		var root_node := scene.instantiate() as Node3D
		var stats := {"meshes": 0, "surfaces": 0, "triangles": 0, "materials": 0, "bounds": AABB(), "has_bounds": false}
		_scan(root_node, Transform3D.IDENTITY, stats)
		print("COLLECTIBLE_ASSET %02d meshes=%d surfaces=%d triangles=%d materials=%d size=%s center=%s" % [
			number, stats.meshes, stats.surfaces, stats.triangles, stats.materials,
			str((stats.bounds as AABB).size), str((stats.bounds as AABB).get_center()),
		])
		root_node.free()
	quit()


func _scan(node: Node, inherited: Transform3D, stats: Dictionary) -> void:
	var current := inherited
	if node is Node3D:
		current = inherited * (node as Node3D).transform
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh := instance.mesh
		if mesh != null:
			stats.meshes += 1
			stats.surfaces += mesh.get_surface_count()
			for surface_index in mesh.get_surface_count():
				stats.triangles += mesh.surface_get_array_len(surface_index) / 3 if mesh.surface_get_primitive_type(surface_index) == Mesh.PRIMITIVE_TRIANGLES else 0
				if mesh.surface_get_material(surface_index) != null:
					stats.materials += 1
			var bounds := _transform_aabb(mesh.get_aabb(), current)
			if stats.has_bounds:
				stats.bounds = (stats.bounds as AABB).merge(bounds)
			else:
				stats.bounds = bounds
				stats.has_bounds = true
	for child in node.get_children():
		_scan(child, current, stats)


func _transform_aabb(bounds: AABB, transform: Transform3D) -> AABB:
	var transformed := AABB(transform * bounds.get_endpoint(0), Vector3.ZERO)
	for endpoint in range(1, 8):
		transformed = transformed.expand(transform * bounds.get_endpoint(endpoint))
	return transformed
