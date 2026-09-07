extends SceneTree

const WARMUP_FRAMES := 30
const SAMPLE_FRAMES := 120


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/art/phase_4_character_showcase.tscn") as PackedScene
	if packed == null:
		push_error("Could not load the Phase 4 showcase")
		quit(1)
		return

	var showcase := packed.instantiate()
	root.add_child(showcase)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for _frame in WARMUP_FRAMES:
		await process_frame

	var process_time_total := 0.0
	var physics_time_total := 0.0
	var fps_total := 0.0
	for _frame in SAMPLE_FRAMES:
		await process_frame
		process_time_total += Performance.get_monitor(Performance.TIME_PROCESS)
		physics_time_total += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		fps_total += Performance.get_monitor(Performance.TIME_FPS)

	var screenshot_path := ProjectSettings.globalize_path("res://.godot/phase_4_showcase.png")
	var screenshot_error := root.get_texture().get_image().save_png(screenshot_path)
	var report := {
		"renderer": RenderingServer.get_video_adapter_name(),
		"average_fps": snappedf(fps_total / SAMPLE_FRAMES, 0.1),
		"average_process_ms": snappedf(process_time_total / SAMPLE_FRAMES * 1000.0, 0.01),
		"average_physics_ms": snappedf(physics_time_total / SAMPLE_FRAMES * 1000.0, 0.01),
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"static_memory_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"screenshot": screenshot_path if screenshot_error == OK else "error:%d" % screenshot_error,
	}
	print("PHASE4_PROFILE " + JSON.stringify(report))
	showcase.queue_free()
	await process_frame
	quit(0)
