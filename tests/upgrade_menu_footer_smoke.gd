extends SceneTree

const SAVE_PATH := "res://.godot/upgrade_menu_footer_smoke_save.json"

var failures: Array[String] = []


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
	await physics_frame
	main.get_node("GameIntro").complete_immediately()
	var manager := main.get_node("GameplayManager") as GameplayManager
	var menu := main.get_node("UpgradeMenu") as UpgradeMenu
	manager.collect_collectible("capitan_orbita")
	menu._hide_discovery_notification()
	menu.open_menu(&"collectibles")
	for frame in 30:
		await process_frame
	var footer := menu._menu_shell.get_node("TabHint") as HBoxContainer
	var content_rect := menu._collectibles_view.get_global_rect()
	var footer_rect := footer.get_global_rect()
	_expect(footer_rect.position.y >= content_rect.end.y + 24.0, "Shortcut hints overlap the collectibles panel")
	_expect(footer_rect.end.y <= float(root.size.y) - 24.0, "Shortcut hints are clipped by the bottom of the screen")
	var tab_key := footer.get_node("TABKey") as PanelContainer
	var esc_key := footer.get_node("ESCKey") as PanelContainer
	_expect(tab_key.get_child(0).text == "TAB" and footer.get_node("TABLabel").text == "CERRAR", "TAB Cerrar hint is incomplete")
	_expect(esc_key.get_child(0).text == "ESC" and footer.get_node("ESCLabel").text == "SALIR", "ESC Salir hint is incomplete")
	_expect(is_equal_approx(tab_key.global_position.y, esc_key.global_position.y) and esc_key.global_position.x > tab_key.global_position.x, "ESC is not aligned to the right of TAB")
	if DisplayServer.get_name() != "headless":
		var output_dir := ProjectSettings.globalize_path("res://docs/pipeline/screenshots/upgrade_menu_footer")
		DirAccess.make_dir_recursive_absolute(output_dir)
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		_expect(image.save_png(output_dir.path_join("collectibles.png")) == OK, "Could not save collectibles footer screenshot")
	var escape := InputEventAction.new()
	escape.action = &"pause"
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	_expect(not menu.is_open() and not paused, "ESC did not exit Collectibles")
	menu.open_menu(&"abilities")
	Input.parse_input_event(escape)
	await process_frame
	_expect(not menu.is_open(), "ESC hint was shown but did not exit Abilities")
	menu.open_menu(&"collectibles")
	var tab := InputEventAction.new()
	tab.action = &"upgrade_menu"
	tab.pressed = true
	Input.parse_input_event(tab)
	await process_frame
	_expect(not menu.is_open(), "TAB did not close Collectibles")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("UPGRADE_MENU_FOOTER_SMOKE_OK")
		quit(0)
	else:
		print("UPGRADE_MENU_FOOTER_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
