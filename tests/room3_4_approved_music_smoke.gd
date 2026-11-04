extends SceneTree

const SAVE_PATH := "res://.godot/room3_4_approved_music_smoke_save.json"

var _failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	_delete_save()
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	var player := main.get_node("Player") as PlayerController
	var global := main.get_node("CinemaGlobalMusic") as CinemaGlobalMusic
	var action := main.get_node("CinemaRoomAudioSystem/Room03Audio")
	var fear := main.get_node("CinemaRoomAudioSystem/Room04Audio")
	_check_configuration(action, "music_room3_action_01.wav", 12)
	_check_configuration(fear, "music_room4_fear_03.wav", 20)
	for room_id in [&"room_03", &"room_04"]:
		manager.room_trash_remaining[String(room_id)] = 0
		_expect(manager.activate_room(room_id), "%s music room could not be activated" % room_id)
		player.set_current_room_id(room_id)
		await create_timer(0.85).timeout
		var controller = action if room_id == &"room_03" else fear
		_expect(controller.get_node("Music_01").playing and controller.get_node("Music_02").playing, "%s large speakers are silent" % room_id)
		_expect(controller._side_music_players[0].playing and controller._side_music_players[-1].playing, "%s lateral speakers are silent" % room_id)
		_expect(controller.get_node("Static_01").volume_db <= -75.0 and global.is_ducked(), "%s static/global music did not crossfade" % room_id)
	player.set_current_room_id(&"left_corridor")
	_expect(not global.is_ducked(), "Global ambience did not recover on leaving the music rooms")
	main.queue_free()
	await process_frame
	var restored := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(restored)
	await process_frame
	for label in ["Room03Audio", "Room04Audio"]:
		var controller = restored.get_node("CinemaRoomAudioSystem/%s" % label)
		_expect(controller.get_node("Music_01").playing and controller._side_music_players[0].playing, "%s music did not resume from save" % label)
	restored.queue_free()
	await process_frame
	_delete_save()
	if _failures.is_empty():
		print("ROOM3_4_APPROVED_MUSIC_SMOKE_OK")
		quit(0)
	else:
		print("ROOM3_4_APPROVED_MUSIC_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)


func _check_configuration(controller: Node3D, expected_file: String, expected_wall_count: int) -> void:
	_expect(controller.enabled_music.resource_path.ends_with(expected_file), "%s has the wrong approved stream" % controller.name)
	_expect(controller._side_music_players.size() == expected_wall_count, "%s has missing wall emitters" % controller.name)
	_expect(not controller.get_node("Music_01").playing and not controller._side_music_players[0].playing, "%s music started before activation" % controller.name)
	_expect(controller.get_node("Music_01").bus == &"Music" and controller._side_music_players[0].bus == &"Music", "%s uses the wrong bus" % controller.name)
	_expect((controller.get_node("Music_01").stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s approved theme does not loop" % controller.name)


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)
