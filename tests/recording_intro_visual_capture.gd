extends SceneTree

const SAVE_PATH := "res://.godot/recording_intro_visual_capture_save.json"
const OUTPUT_PATH := "res://.godot/recording_intro_visual_capture.png"
const E_PROMPT_OUTPUT_PATH := "res://.godot/recording_intro_e_prompt_capture.png"
const RESTORED_OUTPUT_PATH := "res://.godot/recording_intro_hud_restored_capture.png"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	root.size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var intro := main.get_node("GameIntro") as GameIntro
	intro._update_recording(intro.CASSETTE_STREAM.get_length() + 0.1)
	intro._update_recording(1.2)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var e_image := root.get_texture().get_image()
	var visible_yellow_pixels := 0
	for y in range(930, 1055, 4):
		for x in range(620, 1300, 4):
			var pixel := e_image.get_pixel(x, y)
			if pixel.r > 0.45 and pixel.g > 0.25 and pixel.b < 0.2:
				visible_yellow_pixels += 1
	if visible_yellow_pixels < 10:
		push_error("Recording text is not visible on the E-to-stand screen")
		quit(1)
		return
	var e_error := e_image.save_png(ProjectSettings.globalize_path(E_PROMPT_OUTPUT_PATH))
	print("RECORDING_E_PROMPT_CAPTURE: ", e_error, " ", ProjectSettings.globalize_path(E_PROMPT_OUTPUT_PATH))
	intro.complete_immediately()
	intro._start_recording_line(3)
	intro._update_recording(20.0)
	await create_timer(0.35).timeout
	var hud := main.get_node("GameplayHUD")
	hud.set_process(false)
	hud._sprint_bar.visible = true
	hud._vacuum_battery_gauge.visible = true
	# A temporary HUD swatch over the subtitle verifies the actual canvas draw
	# order; it is removed before saving the clean screenshot.
	var order_probe := ColorRect.new()
	order_probe.color = Color.MAGENTA
	order_probe.position = Vector2(650, 960)
	order_probe.size = Vector2(24, 24)
	hud._hud_root_control.add_child(order_probe)
	await RenderingServer.frame_post_draw
	var probe_color := root.get_texture().get_image().get_pixel(662, 972)
	if probe_color.r < 0.85 or probe_color.b < 0.85 or probe_color.g > 0.15:
		push_error("Recording panel rendered above the HUD layer")
		quit(1)
		return
	order_probe.queue_free()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	print("RECORDING_INTRO_CAPTURE: ", error, " ", ProjectSettings.globalize_path(OUTPUT_PATH))
	hud.set_process(true)
	intro._update_recording(1.1)
	intro._update_recording(intro.CASSETTE_STREAM.get_length() + 0.1)
	await create_timer(0.45).timeout
	if intro._recording_panel.visible or not is_equal_approx(hud._tool_slots.offset_top, hud.TOOLS_NORMAL_POSITION.y):
		push_error("HUD did not return to its resting position after the recording")
		quit(1)
		return
	hud.set_process(false)
	hud._sprint_bar.visible = true
	hud._vacuum_battery_gauge.visible = true
	await RenderingServer.frame_post_draw
	var restored_error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(RESTORED_OUTPUT_PATH))
	print("RECORDING_HUD_RESTORED_CAPTURE: ", restored_error, " ", ProjectSettings.globalize_path(RESTORED_OUTPUT_PATH))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0 if error == OK and e_error == OK and restored_error == OK else 1)
