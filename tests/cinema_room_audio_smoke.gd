extends SceneTree

const SAVE_PATH := "res://.godot/cinema_room_audio_smoke_save.json"
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
	var manager := get_first_node_in_group("gameplay_manager") as GameplayManager
	var player := get_first_node_in_group("player") as PlayerController
	var box := main.get_node("LeftWingBlockout/ManagerLeverBox")
	var global := main.get_node("CinemaGlobalMusic")
	var room1 := main.get_node("CinemaRoomAudioSystem/Room01Audio")
	var room2 := main.get_node("CinemaRoomAudioSystem/Room02Audio")
	var room3 := main.get_node("CinemaRoomAudioSystem/Room03Audio")
	var room4 := main.get_node("CinemaRoomAudioSystem/Room04Audio")
	var rooms := [room1, room2, room3, room4]
	var wall_speaker_counts := [12, 12, 12, 20]
	for index in rooms.size():
		var controller = rooms[index]
		_expect(controller._side_speakers.size() == wall_speaker_counts[index], "Room %d lateral speaker count is wrong" % (index + 1))
		_expect(controller._side_static_player.bus == &"Ambience" and controller._side_static_timer.time_left > 0.0, "Room %d lateral interference is not scheduled" % (index + 1))
		_expect(is_equal_approx(controller._side_static_player.volume_db, -27.0), "Room %d lateral interference level is wrong" % (index + 1))
	_expect(room1._side_music_players.size() == 12 and room1._side_music_players[0].playing, "Room 1 lateral speakers do not play the approved theme after the intro")
	_expect(is_equal_approx(room1._side_music_players[0].volume_db, -39.0), "Room 1 lateral music level is wrong")
	_expect(room2._side_music_players.size() == 12 and not room2._side_music_players[0].playing, "Room 2 lateral theme started before activation")
	_expect(room3._side_music_players.size() == 12 and room4._side_music_players.size() == 20, "Approved Room 3/4 themes did not reach lateral speakers")
	_expect(not room3._side_music_players[0].playing and not room4._side_music_players[0].playing, "Room 3/4 themes started before activation")
	player.set_current_room_id(&"room_04")
	room4._on_side_static_timeout()
	_expect(room4._side_static_player.playing and room4._side_static_stop_timer.time_left > 0.0, "Room 4 lateral interference burst did not start")
	_expect(room4._side_static_timer.wait_time >= 18.0 and room4._side_static_timer.wait_time <= 32.0, "Lateral interference recurs too often")
	room4._side_static_stop_timer.stop()
	room4._side_static_player.stop()
	player.set_current_room_id(&"room_01")
	_expect(global.get_node("Player").playing, "Global cinema loop is not playing after headless intro")
	_expect(room1.get_node("Static_01").playing and room2.get_node("Static_01").playing, "Disabled room static is not playing")
	_expect(room3.get_node("Static_01").playing and room3.get_node("Static_02").playing, "Room 3 speaker interference is not playing")
	_expect(room3.get_node("Static_01").global_position.distance_to(main.get_node("Room03Blockout/Room03CinemaSpeakerLeft").global_position) < 2.0, "Room 3 interference is not emitted by its enlarged speaker")
	_expect(is_equal_approx(room3.get_node("Static_01").max_distance, 27.0) and room3.get_node("Static_01").volume_db <= -75.0, "Room 3 static should reach its seats without leaking into another room")
	player.set_current_room_id(&"room_03")
	await process_frame
	_expect(room3.get_node("Static_01").volume_db > -30.0, "Room 3 interference is inaudible inside the auditorium")
	player.set_current_room_id(&"room_01")
	await process_frame
	_expect(room3.get_node("Static_01").volume_db <= -75.0, "Room 3 interference leaks into the corridor or adjacent rooms")
	_expect(not room2.get_node("Music_01").playing, "Room 2 film music started while disabled")
	_expect(room1.get_node("Static_01").bus == &"Ambience" and room2.get_node("Music_01").bus == &"Music", "Speaker audio uses wrong buses")
	_expect(room1.get_node("Static_01").max_distance <= 12.0, "Speaker static travels too far")
	_expect(room1.get_node("Static_01").global_position.distance_to(main.get_node("Room01Blockout/CinemaSpeakerLeft").global_position) < 2.0, "Room 1 static is not at its physical speaker")
	_expect(room2.get_node("Music_01").global_position.distance_to(main.get_node("Room02Blockout/Room02CinemaSpeakerLeft").global_position) < 2.0, "Room 2 music is not at its physical speaker")
	_expect(not room1.has_enabled_music() and room2.has_enabled_music(), "Future Room 1 slot or existing Room 2 music is misconfigured")
	_expect(room3.has_enabled_music() and room4.has_enabled_music(), "Approved Room 3/4 music slots are empty")
	_expect(box.activation_sfx != null and box.activation_sfx.resource_path == "res://assets/audio/sfx/machines/manager_lever_cartoon_spark_03.wav", "Approved lever spark is not assigned")
	_expect(box._audio_players.size() == 4, "Levers need four independent SFX voices")
	for voice in box._audio_players:
		_expect(voice.stream == box.activation_sfx and voice.bus == &"Machines", "Lever voice is not routed to Machines with the approved spark")
	for number in 4:
		var hitbox := box.get_node("Room%02dLever" % (number + 1))
		_expect(hitbox is StaticBody3D and hitbox.get_interaction_prompt() != "", "Room %d lever is not individually interactable" % (number + 1))
		_expect(is_zero_approx(box._lever_pivots[number].rotation_degrees.x), "Room %d lever did not start down" % (number + 1))
	_expect(not manager.can_activate_room(&"room_03") and not manager.can_activate_room(&"room_04"), "Unclean new rooms must not activate")
	var lever1 := box.get_node("Room01Lever")
	lever1.interact(player)
	await process_frame
	_expect(not manager.is_room_activated(&"room_01"), "Incomplete Room 1 lever activated")
	_expect(is_zero_approx(box._lever_pivots[0].rotation_degrees.x), "Incomplete Room 1 lever moved")
	manager.room_trash_remaining["room_01"] = 1
	manager.state_changed.emit()
	_expect(not manager.can_activate_room(&"room_01"), "One remaining trash item did not lock Room 1")
	_expect(not lever1.get_interaction_prompt().contains("100%"), "Locked lever misleadingly displays 100%")
	manager.room_trash_remaining["room_01"] = 0
	manager.state_changed.emit()
	_expect(manager.can_activate_room(&"room_01") and lever1.get_interaction_prompt().begins_with("[E]"), "Clean Room 1 lever is not available")
	lever1.interact(player)
	_expect(box.find_children("ActivationSpark*", "MeshInstance3D", true, false).size() == 10, "Lever activation did not emit sparks")
	await create_timer(0.55).timeout
	_expect(manager.is_room_activated(&"room_01") and box._lever_pivots[0].rotation_degrees.x < -79.0, "Room 1 lever did not latch up")
	_expect(room1.is_activated() and not global.is_ducked(), "Room 1 without a movie song must keep global ambience")
	_expect(not manager.can_activate_room(&"room_01"), "Activated lever remained reusable")
	lever1.interact(player)
	_expect(box._lever_pivots[0].rotation_degrees.x < -79.0, "Already activated lever moved again")
	player.set_current_room_id(&"room_02")
	_expect(not global.is_ducked(), "Global ambience ducked inside disabled Room 2")
	var lever2 := box.get_node("Room02Lever")
	_expect(not manager.can_activate_room(&"room_02"), "Incomplete Room 2 lever unlocked")
	manager.room_trash_remaining["room_02"] = 0
	manager.state_changed.emit()
	_expect(manager.can_activate_room(&"room_02"), "Clean Room 2 lever remained locked")
	lever2.interact(player)
	await create_timer(0.55).timeout
	_expect(manager.is_room_activated(&"room_02") and room2.is_activated(), "Room 2 activation did not propagate")
	_expect(room2.get_node("Music_01").playing and global.is_ducked(), "Room 2 music or global ducking did not engage")
	_expect(room2._side_music_players[0].playing and room2._side_music_players[0].bus == &"Music", "Room 2 lateral music did not start with activation")
	await create_timer(0.8).timeout
	_expect(room2.get_node("Static_01").volume_db <= -75.0, "Room 2 static did not fade out")
	_expect(room2.get_node("Music_01").volume_db > -80.0, "Room 2 film music did not fade in")
	player.set_current_room_id(&"room_01")
	_expect(not global.is_ducked(), "Global ambience did not recover on leaving activated Room 2")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	_expect(saved is Dictionary and saved.get("version", 0) == manager.SAVE_VERSION and saved.get("activated_rooms", []).size() == 2, "Room activation was not persisted")
	main.queue_free()
	await process_frame
	var restored := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(restored)
	await process_frame
	_expect(restored.get_node("GameplayManager").is_room_activated(&"room_01") and restored.get_node("GameplayManager").is_room_activated(&"room_02"), "Activated rooms were not loaded")
	_expect(restored.get_node("LeftWingBlockout/ManagerLeverBox")._lever_pivots[1].rotation_degrees.x < -79.0, "Saved lever did not restore up")
	_expect(restored.get_node("CinemaRoomAudioSystem/Room02Audio").get_node("Music_01").playing, "Saved Room 2 music did not resume")
	restored.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("CINEMA_ROOM_AUDIO_SMOKE_OK")
		quit(0)
	else:
		print("CINEMA_ROOM_AUDIO_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
