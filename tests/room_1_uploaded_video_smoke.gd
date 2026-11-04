extends SceneTree

const SAVE_PATH := "res://.godot/room_1_uploaded_video_smoke_save.json"
var failures: Array[String] = []
var completed_clips: Array[int] = []


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
	var manager := main.get_node("GameplayManager") as GameplayManager
	var player := main.get_node("Player") as PlayerController
	var movie := main.get_node("CinemaMovieSystem/Room01Movie") as CinemaMovieController
	var seat := main.get_node("Room01Blockout/Seat_L_01_01/CinemaSeatInteraction") as CinemaSeatInteractable
	movie.clip_completed.connect(func(_room_id: StringName, clip_number: int) -> void: completed_clips.append(clip_number))
	_expect(movie.clip_count == 3 and movie.get_missing_clips().is_empty(), "Room 1's three converted clips are missing")
	manager.room_trash_remaining["room_01"] = 0
	manager.state_changed.emit()
	_expect(manager.activate_room(&"room_01") and movie.is_showing_movie(), "Room 1 did not start its uploaded movie")
	player.global_position = seat.seat_body.global_position + Vector3(0.0, 0.0, -1.1)
	_expect(player.sit_in_cinema_seat(seat), "Could not sit for real-video watch test")
	await create_timer(0.75).timeout
	var deadline := Time.get_ticks_msec() + 34000
	while Time.get_ticks_msec() < deadline and (movie.completed_cycles < 1 or not manager.is_movie_watched(&"room_01")):
		await process_frame
	_expect(completed_clips.size() >= 3 and completed_clips.slice(0, 3) == [1, 2, 3], "Real clips did not play sequentially")
	_expect(movie.completed_cycles >= 1 and movie.current_clip == 0, "Movie did not loop to clip 1")
	_expect(manager.is_movie_watched(&"room_01"), "A full uninterrupted real-video viewing did not complete the objective")
	_expect(movie.get_cycle_length() > 23.5 and movie.get_cycle_length() < 24.5, "Real clip durations were not read")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("ROOM_1_UPLOADED_VIDEO_SMOKE_OK")
		quit(0)
	else:
		print("ROOM_1_UPLOADED_VIDEO_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
