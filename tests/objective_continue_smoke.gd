extends SceneTree

const SAVE_PATH := "res://.godot/objective_continue_smoke_save.json"
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	root.size = Vector2i(1920, 1080)
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var first := scene.instantiate()
	root.add_child(first)
	await process_frame
	await physics_frame
	await process_frame
	var manager := first.get_node("GameplayManager") as GameplayManager
	manager.debug_unlock_and_clean_all()
	manager.first_room_exit_seen = true
	manager.lobby_unlocked = true
	manager.right_corridor_unlocked = true
	manager._save_progress()
	first.queue_free()
	await process_frame

	var continued := scene.instantiate()
	continued.get_node("GameIntro").run_in_headless = true
	root.add_child(continued)
	await process_frame
	await physics_frame
	await process_frame
	var restored := continued.get_node("GameplayManager") as GameplayManager
	var hud := continued.get_node("GameplayHUD")
	_expect(restored.loaded_save, "Continue did not load the test save")
	_expect(hud._objective_queue.is_empty() and not hud._objective_toast_active and not hud._objective_panel.visible, "Continue replayed objective toasts: %s" % str(hud._objective_queue))
	# Defer even a real completion until the intro makes HUDRoot visible.
	hud._objective_queue.append({"kind": &"completed", "title": "Limpia la Sala 2", "description": "La sala de romance está completamente limpia."})
	hud._show_next_objective_toast()
	_expect(not hud._objective_panel.visible and hud._objective_queue.size() == 1, "Objective toast appeared behind the hidden intro HUD")
	continued.get_node("GameIntro").complete_immediately()
	await process_frame
	# A completion earned after loading still uses the compact, centered panel.
	_expect(hud._objective_panel.visible and hud._objective_toast_active, "Objective completion did not appear after the intro")
	await process_frame
	var panel_rect: Rect2 = hud._objective_panel.get_global_rect()
	_expect(panel_rect.size.x >= 565.0 and panel_rect.size.x <= 575.0, "Objective toast width is wrong: %s" % str(panel_rect))
	_expect(panel_rect.size.y >= 100.0 and panel_rect.size.y <= 160.0, "Objective toast height is wrong: %s" % str(panel_rect))
	_expect(absf(panel_rect.get_center().x - 960.0) < 2.0, "Objective toast is not centered: %s" % str(panel_rect))
	continued.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("OBJECTIVE_CONTINUE_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
