extends SceneTree

# Use the non-headless OpenGL renderer for repeatable local spot measurements.
const SAVE_PATH := "res://.godot/cinema_expansion_profile_save.json"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	root.size = Vector2i(1280, 720)
	var started := Time.get_ticks_usec()
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	if OS.get_environment("CINEMA_PROFILE_NO_MOVIES") == "1":
		for movie in main.get_node("CinemaMovieSystem").get_children():
			movie.movie_folder = "res://.godot/profile_missing_movies"
	root.add_child(main)
	await process_frame
	await physics_frame
	var ready_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var intro = main.get_node("GameIntro")
	if intro.has_method("complete_immediately"):
		intro.complete_immediately()
	main.get_node("GameplayHUD").set_gameplay_hud_visible(false)
	var camera := Camera3D.new()
	camera.fov = 76.0
	camera.far = 80.0
	main.add_child(camera)
	camera.current = true
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var samples := []
	for setup in [
		{"name": "lobby", "at": Vector3(14.75, 1.7, -10), "target": Vector3(14.75, 1.8, 22)},
		{"name": "room_03", "at": Vector3(-9.4, 3.0, 30), "target": Vector3(-9.4, 3.2, 57)},
		{"name": "room_04", "at": Vector3(27.9, 5.5, 9), "target": Vector3(27.9, 0.8, -34)},
	]:
		camera.position = setup.at
		camera.look_at(setup.target)
		main.get_node("Player").global_position = setup.at
		for frame in 45:
			await process_frame
		var process_sum := 0.0
		var physics_sum := 0.0
		var gpu_sum := 0.0
		var render_sum := 0.0
		var sample_started := Time.get_ticks_usec()
		for frame in 120:
			await process_frame
			process_sum += Performance.get_monitor(Performance.TIME_PROCESS)
			physics_sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
			gpu_sum += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
			render_sum += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
		var seconds := float(Time.get_ticks_usec() - sample_started) / 1000000.0
		samples.append({
			"view": setup.name,
			"average_fps": snappedf(120.0 / seconds, 0.1),
			"process_ms": snappedf(process_sum / 120.0 * 1000.0, 0.01),
			"physics_ms": snappedf(physics_sum / 120.0 * 1000.0, 0.01),
			"render_cpu_ms": snappedf(render_sum / 120.0, 0.01),
			"render_gpu_ms": snappedf(gpu_sum / 120.0, 0.01),
			"visible_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
			"visible_primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
			"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		})
	var report := {
		"renderer": RenderingServer.get_video_adapter_name(),
		"resolution": "1280x720",
		"scene_ready_ms": snappedf(ready_ms, 0.1),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"seat_count": get_nodes_in_group("room_02_seat").size() + get_nodes_in_group("room_03_seat").size() + get_nodes_in_group("room_04_seat").size() + 120,
		"trash_count": get_nodes_in_group("trash_item").size(),
		"static_memory_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"samples": samples,
		"note": "Hidden-window synthetic views; manual playtest is still required.",
	}
	print("CINEMA_EXPANSION_PROFILE " + JSON.stringify(report))
	var file := FileAccess.open("res://.godot/cinema_expansion_profile.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0)
