extends SceneTree

const SAVE_PATH := "res://.godot/trash_bin_guidance_smoke_save.json"
const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	_delete_save()
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var intro = get_first_node_in_group("game_intro")
	if intro and intro.has_method("complete_immediately"):
		intro.complete_immediately()
	await process_frame

	var manager = get_first_node_in_group("gameplay_manager")
	var trash_bin = get_first_node_in_group("trash_bin")
	_expect(manager != null and trash_bin != null, "Guidance dependencies are missing")
	if manager == null or trash_bin == null:
		_finish()
		return
	_expect(not manager.is_trash_bin_guidance_active(), "Guidance starts active before filling the bag")
	_expect(not trash_bin.is_guidance_arrow_visible(), "Arrow is visible before filling the bag")
	var one_unit_item: Node = null
	for item in get_nodes_in_group("trash_item"):
		if int(item.definition.size_units) == 1:
			one_unit_item = item
			break
	_expect(one_unit_item != null, "No one-unit trash exists for the capacity transition")
	if one_unit_item:
		manager.bag_volume = manager.bag_capacity - 1
		manager._complete_trash_collection(one_unit_item)
		await process_frame
		_expect(manager.is_trash_bin_guidance_active(), "First full bag did not activate guidance")
		_expect(trash_bin.is_guidance_arrow_visible(), "The Room 1 bin arrow did not appear")
		var arrow := trash_bin.get_guidance_arrow() as Node3D
		_expect(arrow.get_node_or_null("Shaft") is MeshInstance3D and arrow.get_node_or_null("Point") is MeshInstance3D, "Arrow is not built from reusable 3D primitives")
		var initial_y := arrow.position.y
		var initial_scale := arrow.scale
		await create_timer(0.24).timeout
		_expect(not is_equal_approx(arrow.position.y, initial_y), "Arrow has no vertical bob animation")
		_expect(not arrow.scale.is_equal_approx(initial_scale), "Arrow has no accordion animation")
		var save := JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)) as Dictionary
		_expect(bool(save.get("trash_bin_guidance_triggered", false)) and not bool(save.get("trash_bin_guidance_completed", true)), "Active guidance was not saved")
		_expect(manager.empty_bag(), "Full bag could not be delivered during guidance")
		await process_frame
		_expect(not manager.is_trash_bin_guidance_active() and not trash_bin.is_guidance_arrow_visible(), "Guidance did not finish after the first delivery")

	main.queue_free()
	await process_frame
	var loaded := MAIN_SCENE.instantiate()
	root.add_child(loaded)
	await process_frame
	await physics_frame
	var loaded_manager = get_first_node_in_group("gameplay_manager")
	var loaded_bin = get_first_node_in_group("trash_bin")
	_expect(loaded_manager.trash_bin_guidance_triggered and loaded_manager.trash_bin_guidance_completed, "Completed guidance state did not survive reload")
	_expect(not loaded_bin.is_guidance_arrow_visible(), "Completed tutorial arrow reappeared after reload")
	loaded.queue_free()
	await process_frame
	_delete_save()
	_finish()


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("TRASH BIN GUIDANCE TEST: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("TRASH_BIN_GUIDANCE_SMOKE_OK")
		quit(0)
	else:
		print("TRASH_BIN_GUIDANCE_SMOKE_FAILED: %s" % _failures)
		quit(1)
