extends SceneTree

# Regression for first-person camera interpolation at render rates above physics.
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.max_fps = 144
	var scene := load("res://scenes/main/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var player := get_first_node_in_group("player") as PlayerController
	player.global_position = Vector3(3.8, 0.0, 11.8)
	player.rotation.y = PI
	player.velocity = Vector3.ZERO
	player.reset_camera_interpolation()
	for frame in 30: await physics_frame
	Input.action_press("move_right")
	for frame in 18: await physics_frame
	var previous_position := player.camera.global_position
	var previous_tick := Engine.get_physics_frames()
	var frames_between_ticks := 0
	var smooth_frames_between_ticks := 0
	var repeated_positions := 0
	var maximum_step := 0.0
	for frame in 60:
		await process_frame
		await create_timer(0.0).timeout
		var step := player.camera.global_position.distance_to(previous_position)
		if step < 0.000001: repeated_positions += 1
		if Engine.get_physics_frames() == previous_tick:
			frames_between_ticks += 1
			if step > 0.000001: smooth_frames_between_ticks += 1
		maximum_step = maxf(maximum_step, step)
		previous_position = player.camera.global_position
		previous_tick = Engine.get_physics_frames()
	Input.action_release("move_right")
	_expect(frames_between_ticks >= 10, "Motion test did not run faster than physics")
	_expect(smooth_frames_between_ticks >= int(frames_between_ticks * 0.75), "Camera interpolation is inactive between physics ticks")
	print("CAMERA_MOTION repeated=", repeated_positions, "/60 interpolated_frames=", smooth_frames_between_ticks, "/", frames_between_ticks, " max_step_m=", maximum_step)

	player._apply_mouse_look(Vector2(19.0, -11.0))
	_expect(player.camera.global_basis.is_equal_approx(player.head.global_basis), "Mouse look gained interpolation delay")
	await physics_frame
	await process_frame
	_expect(player.interaction_raycast.global_transform.is_equal_approx(player.head.global_transform), "Interaction ray moved away from the physical eye")
	var bin := get_first_node_in_group("trash_bin") as Node3D
	player.global_position = bin.global_position + Vector3(0.0, 0.1, -1.0)
	player.velocity = Vector3.ZERO
	player.head.look_at(bin.global_position + Vector3(0.0, 0.7, 0.0))
	player.reset_camera_interpolation()
	await physics_frame
	await process_frame
	_expect(player.get_interaction_target() == bin, "Camera smoothing broke aiming at the exit trash bin")
	player.respawn()
	_expect(player.camera.global_transform.is_equal_approx(player.head.global_transform), "Respawn leaves the camera at the old location")
	player._process(0.0)
	_expect(player.camera.global_transform.is_equal_approx(player.head.global_transform), "Camera streaks after respawn")
	_expect(int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d")) == Viewport.MSAA_4X, "MSAA 4x is not configured")
	_expect(not root.use_taa, "Unexpected temporal antialiasing in the playtest")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	scene.queue_free()
	await process_frame
	if _failures.is_empty():
		print("PHASE_4_MOTION_OK")
		quit(0)
	else:
		print("PHASE_4_MOTION_FAILED: ", ", ".join(_failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)
