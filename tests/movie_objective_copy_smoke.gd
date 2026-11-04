extends SceneTree

const SAVE_PATH := "res://.godot/movie_objective_copy_smoke_save.json"

var _failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	_delete_save()
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	manager.first_room_exit_seen = true
	var room_ids := [&"room_01", &"room_02", &"room_03", &"room_04"]
	for index in room_ids.size():
		var room_id: StringName = room_ids[index]
		manager.activated_rooms[String(room_id)] = true
		var objective := _find_viewing_objective(manager, room_id)
		var expected := "Sala %d - Siéntate un rato y disfruta" % (index + 1)
		_expect(objective.get("title", "") == "¿De qué será esta película?", "Room %d title changed" % (index + 1))
		_expect(objective.get("description", "") == expected and objective.get("progress", "") == expected, "Room %d viewing copy is wrong" % (index + 1))
		_expect(not String(objective.get("description", "")).contains("ciclo") and not String(objective.get("progress", "")).contains("ciclo"), "Room %d still mentions a cycle" % (index + 1))
	manager.mark_movie_watched(&"room_01")
	var completed := _find_viewing_objective(manager, &"room_01")
	_expect(completed.get("progress", "") == "Sala 1 - Completado" and bool(completed.get("completed", false)), "Completed viewing copy is wrong")
	main.queue_free()
	await process_frame
	_delete_save()
	if _failures.is_empty():
		print("MOVIE_OBJECTIVE_COPY_SMOKE_OK")
		quit(0)
	else:
		print("MOVIE_OBJECTIVE_COPY_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)


func _find_viewing_objective(manager: GameplayManager, room_id: StringName) -> Dictionary:
	var objective_id := "movie_watched_%s" % room_id
	for objective in manager.get_cinema_objectives():
		if objective.get("id", "") == objective_id:
			return objective
	return {}


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)
