extends SceneTree

# Historical visual QA for the superseded layout. For the corrected map use
# cinema_map_relayout_capture.gd, which writes to a separate screenshot folder.
const OUTPUT_DIR := "res://docs/pipeline/screenshots/cinema_expansion"
const SAVE_PATH := "res://.godot/cinema_expansion_capture_save.json"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1280, 720)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var intro = main.get_node("GameIntro")
	if intro.has_method("complete_immediately"):
		intro.complete_immediately()
		await process_frame
	main.get_node("GameplayHUD").set_gameplay_hud_visible(false)
	var camera := Camera3D.new()
	camera.name = "ExpansionQA_Camera"
	camera.fov = 76.0
	main.add_child(camera)
	camera.current = true
	await _shot(camera, "01_lobby_from_entrance", Vector3(-32, 1.65, -3.5), Vector3(-31, 1.8, 21))
	await _shot(camera, "02_lobby_to_left_corridor", Vector3(-30, 1.65, 24), Vector3(-12, 1.5, 24.7))
	await _shot(camera, "03_shutter_closed", Vector3(-8.0, 1.7, 24.7), Vector3(-12, 1.5, 24.7))
	await _shot(camera, "05_room_3", Vector3(-6, 3.1, 33), Vector3(-6, 2.7, 57))
	await _shot(camera, "06_room_4_top", Vector3(-44, 5.5, -14), Vector3(-44, 0.8, -51))
	await _shot(camera, "07_room_4_screen", Vector3(-44, 1.65, -45), Vector3(-44, 3.5, -62))
	await _shot(camera, "09_final_brick_barrier", Vector3(-49.0, 1.7, 6.5), Vector3(-56, 1.5, 6.5))
	await _shot(camera, "10_room_3_entry", Vector3(-4.0, 1.7, 26.5), Vector3(-8.5, 1.5, 29.0))
	var ceilings := main.find_children("*Ceiling*", "Node3D", true, false)
	for ceiling in ceilings:
		ceiling.visible = false
	var map_light := DirectionalLight3D.new()
	map_light.name = "TemporaryMapInspectionLight"
	map_light.rotation_degrees.x = -90.0
	map_light.light_energy = 1.7
	map_light.shadow_enabled = false
	main.add_child(map_light)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 148.0
	await _shot(camera, "08_top_down", Vector3(-28, 130, 0), Vector3(-28, 0, 0))
	map_light.queue_free()
	for ceiling in ceilings:
		ceiling.visible = true
	var manager := main.get_node("GameplayManager") as GameplayManager
	for area in [&"room_01", &"left_corridor", &"manager_office", &"room_02", &"room_03"]:
		manager.room_trash_remaining[String(area)] = 0
	manager.state_changed.emit()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	for frame in 90:
		await process_frame
	await _shot(camera, "04_shutter_open", Vector3(-8.0, 1.7, 24.7), Vector3(-16, 1.5, 24.7))
	manager.first_room_exit_seen = true
	manager.state_changed.emit()
	manager.room_trash_remaining["lobby"] = 6
	manager.state_changed.emit()
	var hud := main.get_node("GameplayHUD")
	hud.set_gameplay_hud_visible(true)
	await create_timer(0.7).timeout
	await _shot(camera, "11_new_objective", Vector3(-32, 1.65, -3.5), Vector3(-31, 1.8, 21))
	hud.consume_new_objective_tab()
	hud._objective_queue.clear()
	manager.room_completed = true
	manager.state_changed.emit()
	await create_timer(1.2).timeout
	await _shot(camera, "12_objective_stamp", Vector3(-32, 1.65, -3.5), Vector3(-31, 1.8, 21))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("CINEMA_EXPANSION_CAPTURE_DONE")
	quit(0)


func _shot(camera: Camera3D, label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position = at
	var up := Vector3.FORWARD if absf((target - at).normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
	camera.look_at(target, up)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, label])
	var error := image.save_png(output)
	print("CAPTURE ", label, " ", image.get_size(), " ", error)
