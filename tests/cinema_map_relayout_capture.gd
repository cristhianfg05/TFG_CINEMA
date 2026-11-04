extends SceneTree

# Repeatable visual QA for the corrected room distribution. Uses a separate
# output folder so earlier expansion screenshots remain untouched.
const OUTPUT_DIR := "res://docs/pipeline/screenshots/cinema_map_layout_v2"
const SAVE_PATH := "res://.godot/cinema_map_relayout_capture_save.json"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1600, 1200)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	main.get_node("GameIntro").complete_immediately()
	main.get_node("GameplayHUD").set_gameplay_hud_visible(false)
	var camera := Camera3D.new()
	camera.fov = 76.0
	main.add_child(camera)
	camera.current = true
	await _shot(camera, "01_right_corridor", Vector3(-3.0, 1.7, 19.0), Vector3(-8.0, 1.7, 25.0))
	await _shot(camera, "02_right_to_vestibule", Vector3(8.5, 1.7, 18.5), Vector3(14.0, 1.7, 18.5))
	await _shot(camera, "03_thin_vestibule", Vector3(14.75, 1.7, -10.0), Vector3(14.75, 1.7, 22.0))
	await _shot(camera, "04_vestibule_to_left", Vector3(14.75, 1.7, 18.5), Vector3(28.5, 1.7, 18.5))
	await _shot(camera, "05_left_corridor_final_barrier", Vector3(20.5, 1.7, 20.0), Vector3(36.9, 1.7, 20.0))
	await _shot(camera, "06_room4_entrance", Vector3(27.5, 1.7, 19.0), Vector3(27.9, 1.7, 15.0))
	await _shot(camera, "07_room3", Vector3(-9.4, 3.0, 30.0), Vector3(-9.4, 3.2, 57.0))
	await _shot(camera, "08_room4", Vector3(27.9, 3.0, 9.0), Vector3(27.9, 3.2, -38.0))
	await _shot(camera, "09_room3_door", Vector3(-8.0, 1.7, 20.5), Vector3(-8.0, 2.0, 25.0))
	await _shot(camera, "14_room3_steps", Vector3(-4.975, 1.7, 29.0), Vector3(-4.975, 1.7, 35.0))
	await _shot(camera, "15_room3_sidewall", Vector3(-9.4, 2.2, 39.0), Vector3(-25.8, 3.7, 40.0))
	await _shot(camera, "10_room2_vestibule_joint", Vector3(8.0, 1.7, 21.0), Vector3(11.0, 2.0, 25.0))
	await _shot(camera, "11_manager_end", Vector3(-15.5, 1.7, 20.0), Vector3(-15.5, 1.7, 24.76))
	var manager := main.get_node("GameplayManager") as GameplayManager
	manager.room_trash_remaining["room_01"] = 0
	manager.activate_room(&"room_01")
	await create_timer(1.0).timeout
	print("MOVIE_BLUR_VISUAL_CHECK ", main.get_node("CinemaMovieSystem/Room01Movie").is_showing_movie())
	await _shot(camera, "13_room1_movie_blur", Vector3(0.0, 2.0, 5.0), Vector3(0.0, 3.55, -14.72))
	for ceiling in main.find_children("*Ceiling*", "Node3D", true, false):
		ceiling.visible = false
	for item in main.get_tree().get_nodes_in_group("trash_item"):
		(item as Node3D).visible = false
	var map_light := DirectionalLight3D.new()
	map_light.rotation_degrees.x = -90.0
	map_light.light_energy = 2.0
	map_light.shadow_enabled = false
	main.add_child(map_light)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 120.0
	await _shot(camera, "12_corrected_top_down", Vector3(6.0, 135.0, 9.0), Vector3(6.0, 0.0, 9.0))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("CINEMA_MAP_RELAYOUT_CAPTURE_DONE")
	quit(0)


func _shot(camera: Camera3D, label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position = at
	if camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		var player := get_first_node_in_group("player") as Node3D
		if player:
			player.global_position = Vector3(at.x, 1.0, at.z)
	var up := Vector3.BACK if absf((target - at).normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
	camera.look_at(target, up)
	if camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		await create_timer(0.3).timeout
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var output := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, label])
	print("CAPTURE ", label, " ", screenshot.get_size(), " ", screenshot.save_png(output))
