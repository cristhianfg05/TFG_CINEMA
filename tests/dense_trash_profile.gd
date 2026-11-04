extends SceneTree

const WARMUP_PHYSICS_FRAMES := 120
const SAMPLE_PHYSICS_FRAMES := 180


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var load_started := Time.get_ticks_usec()
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var ready_ms := float(Time.get_ticks_usec() - load_started) / 1000.0
	for frame in WARMUP_PHYSICS_FRAMES:
		await physics_frame

	var sample_started := Time.get_ticks_usec()
	var physics_monitor_total := 0.0
	for frame in SAMPLE_PHYSICS_FRAMES:
		await physics_frame
		physics_monitor_total += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	var sample_ms := float(Time.get_ticks_usec() - sample_started) / 1000.0
	var trash_count := get_nodes_in_group("trash_item").size()
	var report := {
		"trash_count": trash_count,
		"scene_ready_ms": snappedf(ready_ms, 0.01),
		"sample_frames": SAMPLE_PHYSICS_FRAMES,
		"wall_ms_per_physics_frame": snappedf(sample_ms / SAMPLE_PHYSICS_FRAMES, 0.001),
		"physics_monitor_ms": snappedf(physics_monitor_total / SAMPLE_PHYSICS_FRAMES * 1000.0, 0.001),
		"static_memory_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
	}
	print("DENSE_TRASH_PROFILE " + JSON.stringify(report))
	main.queue_free()
	await process_frame
	quit(0)
