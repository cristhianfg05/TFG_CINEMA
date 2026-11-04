extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const SAVE_PATH := "res://.godot/collectible_menu_visual_save.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	root.size = Vector2i(1920, 1080)
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var intro := get_first_node_in_group("game_intro")
	if intro and intro.has_method("complete_immediately"):
		intro.complete_immediately()
	var manager := get_first_node_in_group("gameplay_manager")
	manager.collect_collectible("capitan_orbita")
	manager.collect_collectible("reina_refresco")
	var menu := get_first_node_in_group("upgrade_menu")
	menu.open_menu(&"collectibles", "reina_refresco")
	for frame in 8:
		await process_frame
		await RenderingServer.frame_post_draw
	print("COLLECTIBLE_MENU_VISUAL error=", root.get_texture().get_image().save_png("res://.godot/collectible_menu_visual.png"))
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit()
