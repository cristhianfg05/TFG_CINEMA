extends SceneTree

const SAVE_PATH := "res://.godot/manager_lever_overlap_smoke_save.json"
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var manager := get_first_node_in_group("gameplay_manager") as GameplayManager
	var box := main.get_node("LeftWingBlockout/ManagerLeverBox")
	_expect(box._audio_players.size() == 4, "Four independent lever voices are missing")
	for voice in box._audio_players:
		_expect(voice.stream == box.activation_sfx and voice.bus == &"Machines", "Lever voice has wrong stream or bus")
	manager.room_trash_remaining["room_01"] = 0
	manager.room_trash_remaining["room_02"] = 0
	manager.state_changed.emit()
	_expect(manager.can_activate_room(&"room_01") and manager.can_activate_room(&"room_02"), "Test rooms did not unlock")
	box.try_raise_lever(&"room_01", 1)
	box.try_raise_lever(&"room_01", 1)
	box.try_raise_lever(&"room_02", 2)
	_expect(box._lever_busy[0] and box._lever_busy[1], "Levers did not begin independently")
	var spark_count := box.find_children("ActivationSpark*", "MeshInstance3D", true, false).size()
	_expect(spark_count == 20, "Rapid activations created %d sparks, expected 20" % spark_count)
	await create_timer(0.55).timeout
	_expect(manager.is_room_activated(&"room_01") and manager.is_room_activated(&"room_02"), "Rapid activations did not finish")
	_expect(not box._lever_busy[0] and not box._lever_busy[1], "Lever busy flags remained set")
	_expect(box._lever_pivots[0].rotation_degrees.x < -79.0 and box._lever_pivots[1].rotation_degrees.x < -79.0, "Both levers did not stay raised")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("MANAGER_LEVER_OVERLAP_SMOKE_OK")
		quit(0)
	else:
		print("MANAGER_LEVER_OVERLAP_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
