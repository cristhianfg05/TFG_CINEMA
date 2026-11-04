extends SceneTree

const OUTPUT_DIR := "res://docs/pipeline/screenshots/room4_sign_update"
const SAVE_PATH := "res://.godot/room4_sign_update_capture_save.json"


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
	await _shot(camera, "01_room4_door_and_posters", Vector3(34.0, 1.8, 21.5), Vector3(28.0, 1.6, 15.4))
	await _shot(camera, "02_cartel_casa", Vector3(25.8, 1.7, 19.0), Vector3(25.0, 1.45, 15.4))
	await _shot(camera, "03_enlarged_skull", Vector3(27.9, 1.7, 17.5), Vector3(23.6, 0.65, 16.5))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("ROOM4_SIGN_UPDATE_CAPTURE_DONE")
	quit(0)


func _shot(camera: Camera3D, label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position = at
	camera.look_at(target)
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, label])
	print("CAPTURE ", label, " ", root.get_texture().get_image().save_png(output))
