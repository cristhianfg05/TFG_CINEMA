extends SceneTree

const SAVE_PATH := "res://.godot/recording_intro_smoke_save.json"
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	_remove_test_save()
	root.size = Vector2i(1920, 1080)
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	var intro := main.get_node("GameIntro") as GameIntro
	intro.run_in_headless = true
	root.add_child(main)
	await process_frame
	await process_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	var hud := main.get_node("GameplayHUD")
	_expect(intro._recording_canvas.layer > intro.layer and intro._overlay.visible, "Closed eyelids cover the recording on the E screen")
	_expect(not manager.loaded_save, "A new game was identified as a continued save")
	_expect(intro._recording_state == &"cassette_open" and intro._recording_panel.visible, "The recording did not start with the E prompt")
	# Scene startup can outlast this short clip on the headless audio clock.
	# Restart it before testing the manually advanced recording timeline.
	intro._cassette_player.play()
	var caption := intro._recording_panel.find_child("RecordingCaption", true, false) as Label
	_expect(caption != null and caption.text == "Grabación 01 - Manager", "Recording 01 narrator is not shown in the caption")
	_expect(intro._cassette_player.playing and not intro._typing_player.playing, "The cassette must precede the typing")
	_expect(intro._cassette_player.bus == &"UI" and intro._typing_player.bus == &"UI", "Recording players are not routed to UI")
	_expect((intro._typing_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "The approved typing sound is not looped")
	_expect(hud._recording_layout_active and hud._recording_layout_tween.is_running(), "The HUD did not start rising with the recording")
	await create_timer(0.43).timeout
	var panel_rect := intro._recording_panel.get_global_rect()
	var sprint_rect: Rect2 = hud._sprint_bar.get_global_rect()
	var tools_rect: Rect2 = hud._tool_slots.get_global_rect()
	var battery_rect: Rect2 = hud._vacuum_battery_gauge.get_global_rect()
	var prompt_rect: Rect2 = hud._prompt_label.get_global_rect()
	_expect(panel_rect.size.x > sprint_rect.size.x and not panel_rect.intersects(sprint_rect) and panel_rect.end.y <= 1080.0, "The recording overlaps stamina or leaves the screen")
	_expect(not panel_rect.intersects(tools_rect) and not panel_rect.intersects(battery_rect), "The bottom-right inventory or battery overlaps the recording")
	_expect(tools_rect.position.x > 1920.0 * 0.75 and tools_rect.end.x <= 1920.0 and battery_rect.end.x <= 1920.0, "The inventory and battery are not anchored inside the bottom-right corner")
	_expect(prompt_rect.end.y < sprint_rect.position.y, "Gameplay prompt overlaps the stamina bar")
	var panel_style := intro._recording_panel.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(panel_style.bg_color.a < 1.0, "The text box is not translucent")

	intro._update_recording(intro.CASSETTE_STREAM.get_length() + 0.1)
	_expect(intro._recording_state == &"typing" and intro._recording_text.visible_characters == 1, "The first line did not begin after the cassette")
	_expect(not intro._cassette_player.playing and intro._typing_player.playing, "Typing audio is not limited to the writing phase")
	intro.complete_immediately()
	_expect(intro._recording_panel.visible, "Standing up cut off the recording")
	_expect(intro._recording_canvas.layer < hud.layer and intro.layer > hud.layer, "The recording did not move behind the HUD after standing")
	paused = true
	intro._update_recording(2.0)
	_expect(intro._recording_state == &"typing" and not intro._recording_panel.visible and intro._typing_player.stream_paused, "Pausing did not suspend the recording")
	paused = false
	intro._update_recording(0.0)
	_expect(intro._recording_panel.visible and not intro._typing_player.stream_paused, "The recording did not resume after pause")
	for index in intro.RECORDING_LINES.size():
		var line: String = intro.RECORDING_LINES[index]
		_expect(intro._recording_text.text == line and intro._recording_line_index == index, "Unexpected recording line %d" % index)
		_expect(intro._recording_text.get_line_count() <= 2, "Recording line %d occupies more than two visual lines" % index)
		intro._update_recording(line.length() * intro.RECORDING_CHAR_INTERVAL)
		_expect(intro._recording_state == &"hold" and intro._recording_text.visible_characters == line.length(), "Line %d did not finish typing" % index)
		_expect(not intro._typing_player.playing, "Typing audio continues during the one-second hold")
		intro._update_recording(0.45)
		_expect(intro._recording_state == &"hold", "Line %d was shown for less than one second" % index)
		intro._update_recording(0.56)
		if index + 1 < intro.RECORDING_LINES.size():
			_expect(intro._recording_state == &"typing" and intro._typing_player.playing, "The next line did not begin typing")
	_expect(intro._recording_state == &"cassette_close" and intro._cassette_player.playing and intro._recording_text.text.is_empty(), "The cassette did not close the recording after the text")
	var raised_tools_y: float = hud._tool_slots.offset_top
	intro._update_recording(intro.CASSETTE_STREAM.get_length() + 0.1)
	_expect(intro._recording_state == &"idle" and not intro._recording_panel.visible, "The recording panel did not close")
	_expect(not hud._recording_layout_active and hud._recording_layout_tween.is_running(), "The HUD did not start returning to its resting position")
	await create_timer(0.14).timeout
	_expect(hud._tool_slots.offset_top > raised_tools_y and hud._tool_slots.offset_top < hud.TOOLS_NORMAL_POSITION.y, "The HUD return is not animated")
	await create_timer(0.30).timeout
	_expect(is_equal_approx(hud._tool_slots.offset_top, hud.TOOLS_NORMAL_POSITION.y) and is_equal_approx(hud._vacuum_battery_gauge.offset_top, hud.BATTERY_NORMAL_POSITION.y) and is_equal_approx(hud._sprint_bar.offset_top, hud.SPRINT_NORMAL_POSITION.y), "The HUD did not settle at the bottom after the recording")
	hud.set_recording_layout_active(true)
	await create_timer(0.14).timeout
	_expect(hud._tool_slots.offset_top < hud.TOOLS_NORMAL_POSITION.y and hud._tool_slots.offset_top > hud.TOOLS_RECORDING_POSITION.y, "The HUD rise is not animated")
	await create_timer(0.30).timeout
	_expect(is_equal_approx(hud._tool_slots.offset_top, hud.TOOLS_RECORDING_POSITION.y), "The HUD did not finish rising")
	hud.set_recording_layout_active(false, false)
	manager._save_progress()
	main.queue_free()
	await process_frame

	var continued := scene.instantiate()
	var continued_intro := continued.get_node("GameIntro") as GameIntro
	continued_intro.run_in_headless = true
	root.add_child(continued)
	await process_frame
	await process_frame
	_expect((continued.get_node("GameplayManager") as GameplayManager).loaded_save, "The saved game was not recognized")
	_expect(continued_intro.is_active() and continued_intro._recording_state == &"idle" and not continued_intro._recording_panel.visible, "Continue replayed the first recording")
	var continued_hud := continued.get_node("GameplayHUD")
	_expect(is_equal_approx(continued_hud._tool_slots.offset_top, continued_hud.TOOLS_NORMAL_POSITION.y), "Continue did not start with the HUD at rest")
	continued.queue_free()
	await process_frame
	_remove_test_save()
	if failures.is_empty():
		print("RECORDING_INTRO_SMOKE_OK")
		quit(0)
	else:
		print("RECORDING_INTRO_SMOKE_FAILED: %s" % " | ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _remove_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
