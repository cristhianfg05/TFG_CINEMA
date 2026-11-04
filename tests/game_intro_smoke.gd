extends SceneTree

const SAVE_PATH := "res://.godot/game_intro_smoke_save.json"
var _failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_expect(packed != null, "Main scene failed to load")
	if packed == null:
		_finish()
		return
	var main := packed.instantiate()
	var intro := main.get_node_or_null("GameIntro") as GameIntro
	_expect(intro != null, "Game intro is missing from the Tutorial")
	if intro == null:
		_finish()
		return
	intro.run_in_headless = true
	root.add_child(main)
	await process_frame
	await process_frame
	await physics_frame

	var player := get_first_node_in_group("player") as PlayerController
	var global_music := main.get_node("CinemaGlobalMusic")
	var global_player := global_music.get_node("Player") as AudioStreamPlayer
	var room1_audio = main.get_node("CinemaRoomAudioSystem/Room01Audio")
	var room2_audio = main.get_node("CinemaRoomAudioSystem/Room02Audio")
	var room1_static := room1_audio.get_node("Static_01") as AudioStreamPlayer3D
	var room2_static := room2_audio.get_node("Static_01") as AudioStreamPlayer3D
	var room2_music := room2_audio.get_node("Music_01") as AudioStreamPlayer3D
	var hud = get_first_node_in_group("gameplay_hud")
	var upgrade_menu = get_first_node_in_group("upgrade_menu")
	var pause_menu = get_first_node_in_group("pause_menu")
	_expect(intro.is_active() and not intro.is_opening(), "Intro did not start with closed eyes")
	_expect(global_player.stream != null and global_player.bus == &"Music", "Cinema music is not assigned to the global Music bus")
	_expect((global_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "Cinema music does not loop")
	_expect((global_player.stream as AudioStreamWAV).loop_end > 0, "Cinema music loop has no end sample")
	_expect(not global_player.playing, "Cinema music started before the stand-up event")
	_expect(global_player.volume_db <= -30.0, "Cinema music is too loud for background ambience")
	_expect(room1_static.stream != null and room2_static.stream != null and room2_music.stream != null, "Room audio streams are missing")
	_expect((room2_static.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "Room static does not loop")
	_expect((room2_music.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD and is_equal_approx(room2_music.stream.get_length(), 18.0), "Room 2 music does not use its prepared loop")
	_expect(not room1_static.playing and not room2_static.playing and not room2_music.playing, "Room audio started before the stand-up event")
	_expect(is_equal_approx(intro.eyelid_open_duration, 0.85), "Eye opening is not using the slower timing")
	_expect(player != null and player.is_game_intro_active(), "Player controls are not locked during the intro")
	_expect(player != null and player.global_position.distance_to(Vector3(-1.54, 0.1, -10.1)) <= 0.05, "Player does not start in front of a first-row seat")
	_expect(player != null and absf(player.global_position.x) > 1.0, "Player still starts in the centre aisle")
	_expect(player != null and absf(player.head.position.y - 0.92) <= 0.01, "Seated eye height is incorrect")
	_expect(player != null and absf(rad_to_deg(player.head.rotation.x) + 68.0) <= 0.1, "Intro camera is not looking down")
	_expect(intro._overlay.visible and intro._top_eyelid.anchor_bottom >= 0.5 and intro._bottom_eyelid.anchor_top <= 0.5, "Closed eyelids do not cover the viewport")
	_expect(intro._prompt_row.get_child(0).text == "PULSA" and intro._prompt_row.get_child(2).text == "PARA LEVANTARTE", "Stand-up prompt text is incorrect")
	var key_panel := intro._prompt_row.get_child(1) as PanelContainer
	var key_style := key_panel.get_theme_stylebox("panel") as StyleBoxFlat
	_expect((key_panel.get_node("KeyText") as Label).text == "E" and key_style.border_color == intro.GOLD and key_style.border_width_left == 2, "E key does not use the gold menu-key treatment")
	_expect(hud != null and not hud._hud_root_control.visible and not hud._coin_canvas.visible, "Gameplay HUD is visible before standing up")
	_expect(intro._audio_player.stream == null, "Intro already contains audio before its asset is supplied")

	var seated_position := player.global_position
	Input.action_press("move_forward")
	for frame in 12:
		await physics_frame
	Input.action_release("move_forward")
	_expect(player.global_position.is_equal_approx(seated_position), "Player moved while seated")

	var tab_event := InputEventAction.new()
	tab_event.action = &"upgrade_menu"
	tab_event.pressed = true
	Input.parse_input_event(tab_event)
	await process_frame
	_expect(not upgrade_menu.is_open(), "Tab menu opened before the intro finished")
	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	Input.parse_input_event(pause_event)
	await process_frame
	_expect(not paused and not pause_menu.is_open(), "Pause menu opened during the intro")

	var stand_event := InputEventAction.new()
	stand_event.action = &"interact"
	stand_event.pressed = true
	Input.parse_input_event(stand_event)
	await create_timer(0.25).timeout
	_expect(intro.is_active() and intro.is_opening(), "E did not begin the stand-up animation")
	_expect(not global_player.playing, "Cinema music started while the player was still standing up")
	_expect(not room1_static.playing and not room2_static.playing and not room2_music.playing, "Room audio started while the player was still standing up")
	_expect(intro._top_eyelid.anchor_bottom < 0.52 and intro._bottom_eyelid.anchor_top > 0.48, "Eyes did not begin opening")
	_expect(player.head.position.y > 0.92 and player.head.rotation.x > deg_to_rad(-68.0), "Camera did not begin rising and looking forward")
	await create_timer(1.20).timeout
	await process_frame
	_expect(not intro.is_active() and not player.is_game_intro_active(), "Intro did not hand control back to the player")
	_expect(not intro._overlay.visible, "Intro overlay remained visible after standing")
	_expect(absf(player.head.position.y - player.standing_eye_height) <= 0.01 and is_zero_approx(player.head.rotation.x), "Camera did not finish at standing forward view")
	_expect(hud._hud_root_control.visible and hud._coin_canvas.visible, "Gameplay HUD did not appear when the game began")
	_expect(global_player.playing, "Cinema music did not start after the intro completed")
	_expect(room1_static.playing and room2_static.playing, "Disabled rooms did not start their speaker static after the intro")
	_expect(not room2_music.playing, "Room 2 music started before activation")
	var room2 := main.get_node("Room02Blockout")
	_expect(room2_static.global_position.is_equal_approx(room2.get_node("Room02CinemaSpeakerLeft").global_position + Vector3.UP * 1.72), "Room 2 static is not emitted from its cinema speaker")
	_expect(room2_static.bus == &"Ambience" and room2_static.max_distance <= 11.0 and room2_static.attenuation_model != AudioStreamPlayer3D.ATTENUATION_DISABLED, "Room static is not localized around its speaker")
	player.set_current_room_id(&"left_corridor")
	_expect(global_player.playing and is_equal_approx(global_player.volume_db, float(global_music.get("base_volume_db"))), "Cinema music changed at the corridor boundary")
	player.global_position = Vector3(0.0, 0.1, 20.0)
	player.set_current_room_id(&"room_01")
	_expect(global_player.playing, "Cinema music did not continue on returning")
	player.global_position = Vector3(11.85, 0.1, 55.4)
	player.set_current_room_id(&"left_corridor")
	_expect(room2_static.playing and not room2_music.playing, "Room 2 audio changed before activation")
	player.global_position = Vector3(0.0, 0.1, 20.0)

	var walking_start := player.global_position
	Input.action_press("move_forward")
	for frame in 24:
		await physics_frame
	Input.action_release("move_forward")
	_expect(player.global_position.z < walking_start.z - 0.25, "Player control was not restored after the intro")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	main.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if _failures.is_empty():
		print("GAME_INTRO_SMOKE_OK")
		quit(0)
	else:
		print("GAME_INTRO_SMOKE_FAILED: %s" % " | ".join(_failures))
		quit(1)
