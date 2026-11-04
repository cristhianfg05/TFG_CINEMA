extends SceneTree

const OUTPUT_DIR := "res://.godot/room_04_polish_visual"
const SAVE_PATH := "res://.godot/room_04_polish_visual_save.json"


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.size = Vector2i(1280, 800)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	main.get_node("GameIntro").complete_immediately()
	main.get_node("GameplayHUD").set_gameplay_hud_visible(false)
	var camera := Camera3D.new()
	camera.fov = 76.0
	camera.far = 100.0
	main.add_child(camera)
	camera.current = true
	var room4 := main.get_node("Room04Blockout") as Node3D
	await _shot(main, camera, "01_room4_five_steps", room4.to_global(Vector3(-44.0, 1.7, -10.4)), room4.to_global(Vector3(-44.0, 2.1, -19.0)))
	await _shot(main, camera, "02_room4_wide_aisle", room4.to_global(Vector3(-44.0, 2.3, -24.0)), room4.to_global(Vector3(-44.0, 2.3, -35.0)))
	await _shot(main, camera, "03_room4_seats_from_screen", room4.to_global(Vector3(-44.0, 2.8, -53.0)), room4.to_global(Vector3(-44.0, 2.0, -38.0)))
	await _shot(main, camera, "04_room3_large_speaker", Vector3(-15.2, 2.0, 51.2), Vector3(-19.6, 2.0, 55.3))
	await _shot(main, camera, "05_room4_witch_ground", room4.to_global(Vector3(-47.0, 1.6, -5.5)), room4.to_global(Vector3(-46.9, 1.0, -8.59)))
	var manager := main.get_node("GameplayManager")
	manager.collect_collectible("arcade_reel_rescue_normal_poster")
	main.get_node("UpgradeMenu").open_menu(&"collectibles", "arcade_reel_rescue_normal_poster")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var poster_image := ProjectSettings.globalize_path("%s/06_collectible_poster.png" % OUTPUT_DIR)
	print("CAPTURE 06_collectible_poster ", root.get_texture().get_image().save_png(poster_image))
	main.get_node("UpgradeMenu").close_menu()
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("ROOM_04_POLISH_VISUAL_CAPTURE_DONE")
	quit(0)


func _shot(main: Node3D, camera: Camera3D, label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position = at
	main.get_node("Player").global_position = Vector3(at.x, 1.0, at.z)
	camera.look_at(target)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, label])
	print("CAPTURE ", label, " ", root.get_texture().get_image().save_png(output))
