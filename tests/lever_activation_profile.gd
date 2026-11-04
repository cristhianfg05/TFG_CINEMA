extends SceneTree

# Isolated graphical profile: distinguish synchronous save, first video start,
# and the first rendered frame after a cleaned room's lever is raised.
const SAVE_PATH := "res://.godot/lever_activation_profile_save.json"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	main.get_node("GameIntro").complete_immediately()
	var manager := main.get_node("GameplayManager") as GameplayManager
	await process_frame
	var save_start := Time.get_ticks_usec()
	manager._save_progress()
	var save_ms := float(Time.get_ticks_usec() - save_start) / 1000.0
	var movie := main.get_node("CinemaMovieSystem/Room01Movie")
	for attempt in 20:
		if movie._shader_prewarmed:
			break
		await process_frame
	manager.room_trash_remaining["room_01"] = 0
	var activation_start := Time.get_ticks_usec()
	var first_ok := manager.activate_room(&"room_01")
	var first_ms := float(Time.get_ticks_usec() - activation_start) / 1000.0
	var frame_start := Time.get_ticks_usec()
	await process_frame
	var first_frame_ms := float(Time.get_ticks_usec() - frame_start) / 1000.0
	manager.room_trash_remaining["room_02"] = 0
	activation_start = Time.get_ticks_usec()
	var second_ok := manager.activate_room(&"room_02")
	var second_ms := float(Time.get_ticks_usec() - activation_start) / 1000.0
	print("LEVER_ACTIVATION_PROFILE ", {
		"save_ms": snappedf(save_ms, 0.1),
		"shader_prewarmed": movie._shader_prewarmed,
		"first_ok": first_ok,
		"room_01_activation_ms": snappedf(first_ms, 0.1),
		"first_frame_ms": snappedf(first_frame_ms, 0.1),
		"second_ok": second_ok,
		"room_02_activation_ms": snappedf(second_ms, 0.1),
		"room_01_video": main.get_node("CinemaMovieSystem/Room01Movie").is_showing_movie(),
	})
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0 if first_ok and second_ok else 1)
