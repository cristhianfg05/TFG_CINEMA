extends SceneTree

const WARMUP_FRAMES := 60
const SAMPLE_FRAMES := 180


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	var view := "characters"
	var scene_path := "res://scenes/art/phase_4_character_showcase.tscn"
	if "--props" in arguments:
		view = "props"
		scene_path = "res://scenes/art/phase_4_props_showcase.tscn"
	elif "--gameplay" in arguments or "--manager" in arguments:
		view = "manager" if "--manager" in arguments else "gameplay"
		scene_path = "res://scenes/main/main.tscn"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load the Phase 4 showcase")
		quit(1)
		return

	var showcase := packed.instantiate()
	root.add_child(showcase)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	if view == "manager":
		var player := get_first_node_in_group("player") as Node3D
		player.global_position = Vector3(3.8, 0.0, 10.3)
		player.rotation.y = PI
		player.reset_camera_interpolation()
		player.set_physics_process(false)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var warmup_started := Time.get_ticks_usec()
	var warmup_frames := 0
	while warmup_frames < WARMUP_FRAMES or Time.get_ticks_usec() - warmup_started < 2000000:
		await process_frame
		warmup_frames += 1

	var process_time_total := 0.0
	var physics_time_total := 0.0
	var fps_total := 0.0
	var gpu_ms_total := 0.0
	var render_cpu_ms_total := 0.0
	var sample_started := Time.get_ticks_usec()
	var sample_frames := 0
	while sample_frames < SAMPLE_FRAMES or Time.get_ticks_usec() - sample_started < 5000000:
		await process_frame
		sample_frames += 1
		process_time_total += Performance.get_monitor(Performance.TIME_PROCESS)
		physics_time_total += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		fps_total += Performance.get_monitor(Performance.TIME_FPS)
		gpu_ms_total += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		render_cpu_ms_total += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
	var sample_seconds := float(Time.get_ticks_usec() - sample_started) / 1000000.0

	await RenderingServer.frame_post_draw
	var screenshot_path := ProjectSettings.globalize_path("res://.godot/phase_4_%s_final.png" % view)
	var screenshot_error := root.get_texture().get_image().save_png(screenshot_path)
	var report := {
		"view": view,
		"resolution": "1920x1080",
		"renderer": RenderingServer.get_video_adapter_name(),
		"average_fps": snappedf(sample_frames / sample_seconds, 0.1),
		"fps_monitor_average": snappedf(fps_total / sample_frames, 0.1),
		"sample_frames": sample_frames,
		"sample_seconds": snappedf(sample_seconds, 0.001),
		"measurement_note": "Static automated view; hidden/offscreen window can change compositor pacing. Manual sustained playtest still required.",
		"average_process_ms": snappedf(process_time_total / sample_frames * 1000.0, 0.01),
		"average_physics_ms": snappedf(physics_time_total / sample_frames * 1000.0, 0.01),
		"average_gpu_ms": snappedf(gpu_ms_total / sample_frames, 0.01),
		"average_render_cpu_ms": snappedf(render_cpu_ms_total / sample_frames, 0.01),
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"static_memory_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"screenshot": screenshot_path if screenshot_error == OK else "error:%d" % screenshot_error,
	}
	print("PHASE4_PROFILE " + JSON.stringify(report))
	var report_file := FileAccess.open("res://.godot/phase_4_%s_profile.json" % view, FileAccess.WRITE)
	if report_file:
		report_file.store_string(JSON.stringify(report, "\t"))
	showcase.queue_free()
	await process_frame
	quit(0)
