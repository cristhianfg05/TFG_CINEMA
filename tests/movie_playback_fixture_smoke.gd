extends SceneTree

const SAVE_PATH := "res://.godot/movie_playback_fixture_smoke_save.json"
const FIXTURE_ROOT := "res://.godot/movie_smoke_fixture"
var failures: Array[String] = []
var room1_order: Array[int] = []
var room2_order: Array[int] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists(FIXTURE_ROOT + "/room_1/Movie_4.ogv"):
		print("MOVIE_PLAYBACK_FIXTURE_SKIPPED: temporary OGV fixture not present")
		quit(0)
		return
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	var room1 := main.get_node("CinemaMovieSystem/Room01Movie") as CinemaMovieController
	var room2 := main.get_node("CinemaMovieSystem/Room02Movie") as CinemaMovieController
	room1.movie_folder = FIXTURE_ROOT + "/room_1"
	room2.movie_folder = FIXTURE_ROOT + "/room_2"
	room1.clip_completed.connect(func(_room_id: StringName, number: int) -> void: room1_order.append(number))
	room2.clip_completed.connect(func(_room_id: StringName, number: int) -> void: room2_order.append(number))
	root.add_child(main)
	await process_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	var player := main.get_node("Player") as PlayerController
	manager.room_trash_remaining["room_01"] = 0
	manager.room_trash_remaining["room_02"] = 0
	manager.state_changed.emit()
	_expect(manager.activate_room(&"room_01") and manager.activate_room(&"room_02"), "Both clean rooms did not activate")
	_expect(room1.is_showing_movie() and room2.is_showing_movie(), "Both rooms did not begin video playback")
	await create_timer(0.9).timeout
	var seat := main.get_node("Room02Blockout/Room02Seat_05_02_03/CinemaSeatInteraction") as CinemaSeatInteractable
	_expect(player.sit_in_cinema_seat(seat), "Could not sit during Room 2 playback")
	await create_timer(3.1).timeout
	_expect(room1_order.size() >= 5 and room1_order.slice(0, 5) == [1, 2, 3, 4, 1], "Room 1 clips did not sequence and loop")
	_expect(room2_order.size() >= 5 and room2_order.slice(0, 5) == [1, 2, 3, 4, 1], "Room 2 clips did not sequence and loop")
	_expect(room1.is_showing_movie() and room2.is_showing_movie(), "One of two simultaneous video players stopped")
	_expect(room1.get_cycle_length() > 1.9 and room2.get_cycle_length() > 1.9, "Real clip lengths were not read")
	_expect(manager.is_movie_watched(&"room_02"), "A complete uninterrupted seated cycle did not complete the objective")
	_expect(not manager.is_movie_watched(&"room_01"), "Unwatched Room 1 completed")
	_expect(player.stand_up_from_cinema_seat(), "Could not stand after playback")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("MOVIE_PLAYBACK_FIXTURE_SMOKE_OK")
		quit(0)
	else:
		print("MOVIE_PLAYBACK_FIXTURE_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
