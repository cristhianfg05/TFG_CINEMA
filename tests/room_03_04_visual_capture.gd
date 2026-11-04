extends SceneTree

# Visual QA for the Action/Fear room pass. Keeps earlier layout captures intact.
const OUTPUT_DIR := "res://docs/pipeline/screenshots/room_03_action_room_04_fear"
const SAVE_PATH := "res://.godot/room_03_04_visual_capture_save.json"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1440, 900)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	main.get_node("GameIntro").complete_immediately()
	main.get_node("GameplayHUD").set_gameplay_hud_visible(false)
	var camera := Camera3D.new()
	camera.fov = 76.0
	camera.far = 80.0
	main.add_child(camera)
	camera.current = true
	await _shot(main, camera, "01_room3_action", Vector3(-9.4, 3.0, 30.0), Vector3(-9.4, 3.2, 57.0))
	await _shot(main, camera, "02_room3_outer_aisle", Vector3(-22.25, 2.2, 34.0), Vector3(-22.25, 2.2, 49.0))
	await _shot(main, camera, "03_room3_inside_frame", Vector3(-8.0, 1.7, 28.0), Vector3(-8.0, 2.1, 25.0))
	await _shot(main, camera, "04_room4_from_entrance", Vector3(27.9, 1.7, 17.0), Vector3(27.9, 3.5, -38.7))
	await _shot(main, camera, "05_room4_hanging_decor", Vector3(27.9, 2.5, 3.0), Vector3(27.9, 5.8, -24.0))
	await _shot(main, camera, "06_room4_screen", Vector3(27.9, 3.0, -28.0), Vector3(27.9, 3.6, -38.7))
	await _shot(main, camera, "07_room4_witch_sign", Vector3(25.8, 1.7, 19.0), Vector3(23.9, 1.45, 15.4))
	await _shot(main, camera, "08_room2_inside_frame", Vector3(9.0, 2.0, 28.0), Vector3(9.0, 2.2, 25.0))
	await _shot(main, camera, "09_room1_vestibule_joint", Vector3(14.5, 1.7, 0.0), Vector3(11.7, 1.7, 0.0))
	await _shot(main, camera, "10_final_wall_height", Vector3(25.0, 2.0, 20.0), Vector3(36.9, 4.0, 20.0))
	await _shot(main, camera, "11_room2_outer_aisle", Vector3(8.2, 2.2, 34.0), Vector3(8.2, 2.2, 49.0))
	await _shot(main, camera, "12_room4_inside_frame", Vector3(27.9, 1.7, 12.0), Vector3(27.9, 2.1, 15.0))
	await _shot(main, camera, "13_room1_inside_frame", Vector3(9.0, 1.7, 12.0), Vector3(9.0, 2.1, 15.0))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("ROOM_03_04_VISUAL_CAPTURE_DONE")
	quit(0)


func _shot(main: Node3D, camera: Camera3D, label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position = at
	main.get_node("Player").global_position = Vector3(at.x, 1.0, at.z)
	camera.look_at(target)
	await create_timer(0.3).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, label])
	print("CAPTURE ", label, " ", root.get_texture().get_image().save_png(output))
