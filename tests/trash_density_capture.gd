extends SceneTree

const OUTPUT_DIR := "res://.godot/trash_density_capture"
const SAVE_PATH := "res://.godot/trash_density_capture_save.json"


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
	main.get_node("GameIntro").complete_immediately()
	main.get_node("GameplayHUD").set_gameplay_hud_visible(false)
	var camera := Camera3D.new()
	camera.fov = 76.0
	camera.far = 80.0
	main.add_child(camera)
	camera.current = true
	await _shot(main, camera, "room1_rear", Vector3(0.0, 1.6, 13.7), Vector3(0.0, 0.8, 7.0))
	await _shot(main, camera, "room2_rear", Vector3(21.1, 1.6, 27.5), Vector3(21.1, 1.0, 39.0))
	await _shot(main, camera, "room3_rear", Vector3(-9.4, 1.6, 27.5), Vector3(-9.4, 1.0, 39.0))
	await _shot(main, camera, "room4_rear", Vector3(27.9, 1.6, 13.0), Vector3(27.9, 1.0, -1.0))
	await _shot(main, camera, "lobby", Vector3(14.75, 1.6, -8.0), Vector3(14.75, 0.8, 8.0))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("TRASH_DENSITY_CAPTURE_OK")
	quit(0)


func _shot(main: Node3D, camera: Camera3D, label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position = at
	main.get_node("Player").global_position = Vector3(at.x, 1.0, at.z)
	camera.look_at(target)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("%s/%s.jpg" % [OUTPUT_DIR, label])
	var error := root.get_texture().get_image().save_jpg(output, 0.65)
	print("TRASH_CAPTURE %s %s" % [label, error])
