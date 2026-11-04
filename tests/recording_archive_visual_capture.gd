extends SceneTree

const SAVE_PATH := "res://.godot/recording_archive_visual_save.json"
const OUTPUT_PATH := "res://.godot/recording_archive_visual.png"


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
	main.get_node("GameIntro").complete_immediately()
	var manager := main.get_node("GameplayManager") as GameplayManager
	manager.discover_recording("02")
	manager.discover_recording("03")
	var menu := main.get_node("UpgradeMenu") as UpgradeMenu
	menu.open_menu(&"recordings", "02")
	for frame in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	print("RECORDING_ARCHIVE_VISUAL_CAPTURE size=", image.get_size(), " error=", result)
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0 if result == OK else 1)
