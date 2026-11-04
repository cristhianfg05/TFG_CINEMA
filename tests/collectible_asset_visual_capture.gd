extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1200, 900)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("28282b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("ddd6cf")
	environment.environment.ambient_light_energy = 0.9
	stage.add_child(environment)
	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(3.0, 0.04, 3.0)
	floor.mesh = floor_mesh
	floor.position.y = -0.02
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("513342")
	floor_material.roughness = 1.0
	floor.material_override = floor_material
	stage.add_child(floor)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var camera := Camera3D.new()
	camera.fov = 30.0
	camera.look_at_from_position(Vector3(0, 1.7, 2.45), Vector3(0, 0.1, 0), Vector3.UP)
	stage.add_child(camera)
	camera.current = true
	for number in [1, 5, 8, 9]:
		var model := (load("res://assets/models/source/collectibles/%d.glb" % number) as PackedScene).instantiate() as Node3D
		stage.add_child(model)
		model.rotation_degrees.x = -90.0
		var lowest := INF
		for child in model.find_children("*", "MeshInstance3D", true, false):
			var instance := child as MeshInstance3D
			var bounds := instance.mesh.get_aabb()
			for corner in 8:
				lowest = minf(lowest, instance.to_global(bounds.get_endpoint(corner)).y)
		model.position.y = -lowest + 0.012
		for frame in 6:
			await process_frame
			await RenderingServer.frame_post_draw
		var path := "res://.godot/collectible_%02d_visual.png" % number
		print("COLLECTIBLE_VISUAL %d error=%d %s" % [number, root.get_texture().get_image().save_png(path), path])
		model.queue_free()
		await process_frame
	stage.queue_free()
	await process_frame
	quit()
