extends SceneTree

# Ventana oculta con renderer real: captura la herramienta equipada y activa.
const SAVE_PATH := "res://.godot/vacuum_visual_capture_save.json"
const OUTPUT_PATH := "res://docs/pipeline/screenshots/vacuum/vacuum_active.png"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/pipeline/screenshots/vacuum"))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	main.get_node("GameIntro").complete_immediately()
	var manager := main.get_node("GameplayManager") as GameplayManager
	var hud := main.get_node("GameplayHUD")
	manager.coins = 999999
	manager.purchase_tool(&"vacuum")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	manager.set_vacuum_trigger_held(true)
	manager._update_vacuum(0.08)
	hud._update_vacuum_hud(0.08)
	for frame in 45:
		await process_frame
	var first_wisp_before: Vector3 = hud._vacuum_wind_streaks[0].position
	await create_timer(0.12).timeout
	var wisps_animated: bool = hud._vacuum_wind_streaks[0].position.distance_to(first_wisp_before) > 0.02
	var active_audio_ok := manager.vacuum_audio.playing and manager.vacuum_transition_audio.bus == &"Tools"
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	print("VACUUM_VISUAL_CAPTURE ", image.get_size(), " error=", error)
	print("WIND_VISIBLE=", hud._vacuum_wind_root.visible, " WIND_TARGET=", hud._vacuum_nozzle_anchor.global_position, " VIEWMODEL_SCALE=", hud.VACUUM_VIEWMODEL_SCALE)
	print("VACUUM_ACTIVE_AUDIO=", active_audio_ok, " loop_volume_db=", manager.vacuum_audio.volume_db)
	print("WISPS_ANIMATED=", wisps_animated)
	var model: Node3D = hud._vacuum_view_root.get_node("AxisCorrection/Model")
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var geometry := mesh as MeshInstance3D
		print("MODEL_MESH ", geometry.name, " bounds=", geometry.get_aabb(), " at=", geometry.global_position)
		for end_x in [-0.385, 0.385]:
			var end_world := geometry.to_global(Vector3(end_x, 0.14, 0.0))
			print("MODEL_END ", end_x, " world=", end_world, " screen=", hud._vacuum_viewport.get_camera_3d().unproject_position(end_world))
	manager.set_vacuum_trigger_held(false)
	await create_timer(0.2).timeout
	var stopped_audio_ok := not manager.vacuum_audio.playing
	stopped_audio_ok = stopped_audio_ok and manager.vacuum_transition_audio.playing
	print("VACUUM_STOP_AUDIO=", stopped_audio_ok)
	var wind_count_ok: bool = hud._vacuum_wind_streaks.size() == 24
	main.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0 if active_audio_ok and stopped_audio_ok and wind_count_ok and wisps_animated else 1)
