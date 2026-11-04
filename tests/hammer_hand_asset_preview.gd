extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1400, 1000)
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("252a31")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c5cbd2")
	environment.environment.ambient_light_energy = 0.65
	scene.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -35, 0)
	light.light_energy = 1.4
	scene.add_child(light)
	var hand := (load("res://assets/pipeline/characters/hammer_grip_hand.glb") as PackedScene).instantiate() as Node3D
	scene.add_child(hand)
	var hammer := (load("res://assets/pipeline/props/manager_mallet.glb") as PackedScene).instantiate() as Node3D
	hammer.scale = Vector3.ONE * 0.45
	scene.add_child(hammer)
	var camera := Camera3D.new()
	camera.fov = 34
	camera.near = 0.005
	scene.add_child(camera)
	camera.current = true
	var views := {
		"hammer_right_hand_front": Vector3(0.14, 0.22, 0.35),
		"hammer_right_hand_back": Vector3(0.22, 0.23, -0.30),
		"hammer_right_hand_side": Vector3(0.36, 0.20, 0.05),
	}
	for name in views:
		camera.position = views[name]
		camera.look_at(Vector3(0.005, 0.157, 0.01))
		for frame in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://.godot/%s.png" % name)
		print("HAND_ASSET_PREVIEW ", name, " error=", error)
	scene.queue_free()
	await process_frame
	quit()
