extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const SAVE_PATH := "res://.godot/collectible_posters_visual_save.json"


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
	var poster_ids := [
		"arcade_reel_rescue_normal_poster",
		"arcade_reel_rescue_hard_poster",
		"arcade_second_game_normal_poster",
		"arcade_second_game_hard_poster",
	]
	for poster_id in poster_ids:
		manager.collect_collectible(poster_id)
	var menu := get_first_node_in_group("upgrade_menu")
	for index in poster_ids.size():
		menu.open_menu(&"collectibles", poster_ids[index])
		for frame in 5:
			await process_frame
			await RenderingServer.frame_post_draw
		var path := "res://.godot/collectible_poster_%02d_visual.png" % (index + 1)
		print("COLLECTIBLE_POSTER_VISUAL %s error=%d" % [path, root.get_texture().get_image().save_png(path)])
		menu.close_menu()
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit()
