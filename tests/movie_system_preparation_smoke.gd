extends SceneTree

const SAVE_PATH := "res://.godot/movie_system_preparation_smoke_save.json"
var failures: Array[String] = []


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
	var room1 := main.get_node("CinemaMovieSystem/Room01Movie") as CinemaMovieController
	var room2 := main.get_node("CinemaMovieSystem/Room02Movie") as CinemaMovieController
	var poster1 := main.get_node("LeftWingBlockout/Room01EntryPosterDisplay") as MeshInstance3D
	var poster2 := main.get_node("Room02Blockout/Room02EntryPosterDisplay") as MeshInstance3D
	var seat1 := main.get_node("Room01Blockout/Seat_L_01_01/CinemaSeatInteraction") as CinemaSeatInteractable
	var seat2 := main.get_node("Room02Blockout/Room02Seat_01_01_01/CinemaSeatInteraction") as CinemaSeatInteractable
	_expect(room1.get_missing_clips().is_empty() and room1.clip_count == 3 and room2.get_missing_clips().size() == 4, "Available and pending video slots were not detected")
	_expect(not room1.is_showing_movie() and not room2.is_showing_movie(), "A screen activated without clips")
	_expect(room1._surface != null and room2._surface != null and not room1._surface.visible and not room2._surface.visible, "Blank movie overlays are visible")
	_expect(room1._surface.material_override is ShaderMaterial and room2._surface.material_override is ShaderMaterial, "Reusable movie filter is not assigned")
	_expect(poster1.material_override is ShaderMaterial and poster2.material_override is ShaderMaterial, "Room 1/2 posters are not using the aged material")
	_expect(seat1.collision_layer == 0 and seat2.collision_layer == 0, "Seats are targetable before activation")
	var usable_count := 0
	for seat in get_nodes_in_group("cinema_seat"):
		_expect(seat.seat_body.get_meta("seat_variant") != "ButacaPlegada", "A folded seat is interactable")
		usable_count += 1
	var legacy_usable_count := get_nodes_in_group("cinema_seat").filter(func(seat): return seat.room_id in [&"room_01", &"room_02"]).size()
	_expect(legacy_usable_count == 225 and usable_count > legacy_usable_count, "Room 1/2 seat count changed or the new rooms have no seats")
	_expect(manager.get_cinema_objectives().is_empty(), "Later objectives appeared before Room 1 exit")
	player.set_current_room_id(&"left_corridor")
	_expect(not manager.first_room_exit_seen, "Room 1 exit objective appeared before Room 1 progression")
	player.set_current_room_id(&"room_01")
	manager.room_completed = true
	player.set_current_room_id(&"left_corridor")
	var objectives := manager.get_cinema_objectives()
	_expect(manager.first_room_exit_seen and objectives.size() == 2, "First Room 1 exit did not reveal the two available objectives")
	_expect(objectives[0].title == "Reactiva las películas 0/4" and objectives[1].title == "Limpia la Sala 2", "New objective titles or order are wrong")
	_expect(&"room_05" in manager.CINEMA_ROOM_IDS, "The special fifth room is not registered")
	manager.activated_rooms["room_05"] = true
	_expect(manager.get_cinema_objectives()[0].title == "Reactiva las películas 0/4", "Special final room incorrectly counts as an ordinary movie")
	manager.activated_rooms.erase("room_05")
	manager.room_trash_totals["room_05"] = 1
	manager.room_trash_remaining["room_05"] = 0
	_expect(not manager.can_activate_room(&"room_05"), "The special final room accepts an ordinary movie lever")
	manager.room_trash_totals.erase("room_05")
	manager.room_trash_remaining.erase("room_05")
	player.set_current_room_id(&"room_01")
	player.set_current_room_id(&"left_corridor")
	_expect(manager.get_cinema_objectives().size() == 2, "Room 1 exit objectives appeared twice")
	manager.room_trash_remaining["room_01"] = 1
	manager.state_changed.emit()
	_expect(not manager.can_activate_room(&"room_01") and seat1.collision_layer == 0, "Incomplete room unlocked lever or seat")
	manager.room_trash_remaining["room_01"] = 0
	manager.state_changed.emit()
	_expect(manager.can_activate_room(&"room_01") and seat1.collision_layer == 0, "Clean room allowed seating before movie activation")
	_expect(manager.activate_room(&"room_01"), "Clean Room 1 did not activate")
	_expect(seat1.collision_layer == 2 and room1.is_showing_movie(), "Activated seat or Room 1 movie playback is wrong")
	_expect(manager.get_cinema_objectives()[0].title == "Reactiva las películas 1/4", "Activation counter did not advance")
	_expect(manager.get_cinema_objectives().size() == 3 and manager.get_cinema_objectives()[2].title == "¿De qué será esta película?", "Per-room viewing objective missing")
	player.global_position = seat1.seat_body.global_position + Vector3(0.0, 0.0, 1.1)
	_expect(seat1.get_interaction_prompt().is_empty() and not player.sit_in_cinema_seat(seat1), "Room 1 seat can be selected from behind")
	player.global_position = seat1.seat_body.global_position + Vector3(0.0, 0.0, -1.1)
	_expect(seat1.get_interaction_prompt().begins_with("[E]"), "Eligible front-side seat has no prompt")
	var room1_entry := player.global_position
	_expect(player.sit_in_cinema_seat(seat1), "Player could not sit in Room 1")
	_expect(player.is_sitting() and player.get_current_room_id() == &"room_01", "Player sitting state or room is wrong")
	_expect(player.is_seat_transitioning() and not player.stand_up_from_cinema_seat(), "Seating transition can be interrupted")
	await create_timer(0.7).timeout
	_expect(player.head.global_position.distance_to(seat1.seat_body.global_position) < 1.5, "Seated camera is too far from seat")
	_expect(not player.is_seat_transitioning(), "Seating transition did not finish")
	var room1_exit := player._find_safe_seat_exit(seat1)
	_expect(Vector2(room1_exit.x, room1_exit.z).distance_to(Vector2(room1_entry.x, room1_entry.z)) < 0.15, "Room 1 stand-up target is not the row used to select the seat")
	_expect(player.stand_up_from_cinema_seat() and player.is_seat_transitioning(), "Player could not begin standing up")
	await create_timer(0.7).timeout
	_expect(not player.is_sitting(), "Room 1 stand-up animation did not finish")
	_expect(Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(room1_entry.x, room1_entry.z)) < 0.15, "Room 1 stand-up moved the player to another row")
	_expect(not manager.is_movie_watched(&"room_01"), "Incomplete watch was marked complete")
	manager.room_trash_remaining["room_02"] = 0
	manager.state_changed.emit()
	_expect(manager.activate_room(&"room_02") and seat2.collision_layer == 2, "Room 2 seat did not unlock after activation")
	_expect(manager.get_cinema_objectives()[0].title == "Reactiva las películas 2/4", "Second activation counter did not advance")
	player.global_position = seat2.seat_body.global_position + Vector3(0.0, 0.0, -1.1)
	_expect(seat2.get_interaction_prompt().is_empty() and not player.sit_in_cinema_seat(seat2), "Room 2 seat can be selected from behind")
	player.global_position = seat2.seat_body.global_position + Vector3(0.0, 0.0, 1.1)
	var room2_entry := player.global_position
	_expect(player.sit_in_cinema_seat(seat2), "Player could not sit in Room 2")
	await create_timer(0.7).timeout
	_expect(player.get_current_room_id() == &"room_02" and absf(wrapf(player.rotation.y - PI, -PI, PI)) < 0.02, "Room 2 seat faces away from screen")
	var room2_exit := player._find_safe_seat_exit(seat2)
	_expect(Vector2(room2_exit.x, room2_exit.z).distance_to(Vector2(room2_entry.x, room2_entry.z)) < 0.15, "Room 2 stand-up target is not the row used to select the seat")
	_expect(player.stand_up_from_cinema_seat(), "Player could not stand from Room 2")
	await create_timer(0.7).timeout
	_expect(not player.is_sitting(), "Room 2 stand-up animation did not finish")
	_expect(Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(room2_entry.x, room2_entry.z)) < 0.15, "Room 2 stand-up moved the player to another row")
	room2._clip_lengths = [2.0, 3.0, 4.0, 5.0]
	room2._watching = true
	room2._watch_elapsed = 13.0
	room2._check_watch_complete()
	_expect(not manager.is_movie_watched(&"room_02"), "Partial movie cycle completed objective")
	room2._on_player_stood(&"room_02", &"mock")
	_expect(room2._watch_elapsed == 0.0 and not manager.is_movie_watched(&"room_02"), "Standing did not reset partial watch")
	room2._watching = true
	room2._watch_elapsed = 14.0
	room2._check_watch_complete()
	_expect(manager.is_movie_watched(&"room_02") and not manager.mark_movie_watched(&"room_02"), "Complete watch was not persisted exactly once")
	main.queue_free()
	await process_frame
	var restored := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(restored)
	await process_frame
	var restored_manager := restored.get_node("GameplayManager") as GameplayManager
	_expect(restored_manager.first_room_exit_seen and restored_manager.is_room_activated(&"room_01") and restored_manager.is_movie_watched(&"room_02"), "Movie objectives or activation did not survive reload")
	restored.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("MOVIE_SYSTEM_PREPARATION_SMOKE_OK")
		quit(0)
	else:
		print("MOVIE_SYSTEM_PREPARATION_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
