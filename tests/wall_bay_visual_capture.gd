extends SceneTree

# Local visual QA for the four lateral-wall modules. Screenshots stay in
# .godot/ so running this test never overwrites curated documentation images.
const OUTPUT_DIR := "res://.godot/wall_bay_visual"
const SAVE_PATH := "res://.godot/wall_bay_visual_capture_save.json"


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
	await _shot(main, camera, "01_sala_1", Vector3(-5.8, 3.9, -2.5), Vector3(-11.1, 3.7, -2.5))
	await _shot(main, camera, "02_sala_2", Vector3(13.0, 3.9, 43.7), Vector3(7.5, 3.7, 43.7))
	await _shot(main, camera, "03_sala_3", Vector3(-17.5, 3.9, 43.7), Vector3(-23.0, 3.7, 43.7))
	var room4 := main.get_node("Room04Blockout") as Node3D
	await _shot(main, camera, "04_sala_4_centro", room4.to_global(Vector3(-47.5, 3.9, -33.3)), room4.to_global(Vector3(-53.0, 3.7, -33.3)))
	await _shot(main, camera, "05_sala_4_ultimo_tramo", room4.to_global(Vector3(-47.5, 3.9, -11.7)), room4.to_global(Vector3(-53.0, 3.7, -11.7)))
	await _shot(main, camera, "06_papelera_junto_recreativa", Vector3(26.0, 2.0, 20.3), Vector3(22.5, 1.2, 24.0))
	await _shot(main, camera, "07_sala_3_pantalla", Vector3(-9.4, 3.1, 48.0), Vector3(-9.4, 3.5, 56.7))
	await _shot(main, camera, "08_sala_4_pantalla", room4.to_global(Vector3(-44.0, 3.1, -52.0)), room4.to_global(Vector3(-44.0, 3.5, -62.7)))
	await _shot(main, camera, "09_sala_4_pared_entrada", room4.to_global(Vector3(-44.0, 3.2, -20.0)), room4.to_global(Vector3(-44.0, 3.5, -9.0)))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("WALL_BAY_VISUAL_CAPTURE_DONE")
	quit(0)


func _shot(main: Node3D, camera: Camera3D, label: String, at: Vector3, target: Vector3) -> void:
	camera.global_position = at
	main.get_node("Player").global_position = Vector3(at.x, 1.0, at.z)
	camera.look_at(target)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, label])
	print("CAPTURE ", label, " ", root.get_texture().get_image().save_png(output))
