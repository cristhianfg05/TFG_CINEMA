extends SceneTree

const SAVE_PATH := "user://cinema_cleaner_save.json"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_delete_save()
	var gameplay_scene := load("res://scenes/main/main.tscn") as PackedScene
	var menu_scene := load("res://scenes/main/main_menu.tscn") as PackedScene
	_expect(gameplay_scene != null, "Gameplay scene failed to load")
	_expect(menu_scene != null, "Main menu scene failed to load")
	_expect(load("res://resources/upgrades/quick_hands_1.tres") != null, "Quick Hands resource is missing")
	_expect(load("res://resources/upgrades/reinforced_bag_1.tres") != null, "Reinforced Bag resource is missing")
	if gameplay_scene == null:
		_finish()
		return

	var main := gameplay_scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var manager = get_first_node_in_group("gameplay_manager")
	var lost_found = get_first_node_in_group("lost_found")
	var manager_npc = get_first_node_in_group("manager_npc")
	var exit_door = get_first_node_in_group("exit_door")
	var pause_menu = get_first_node_in_group("pause_menu")
	_expect(manager != null, "Gameplay manager is missing")
	_expect(lost_found != null, "Lost-and-found box is missing")
	_expect(manager_npc != null, "Manager placeholder is missing")
	_expect(exit_door != null, "Exit door is missing")
	_expect(pause_menu != null, "Pause menu is missing")
	_expect(get_nodes_in_group("spectator").size() == 2, "Expected two spectators")
	_expect(get_nodes_in_group("screen_content").size() == 1, "Provisional screen content is missing")
	_expect(get_nodes_in_group("lost_item").size() == 1, "Expected one lost watch")
	_expect(get_nodes_in_group("trash_item").size() == 20, "Lost watch must not count as trash")

	if manager and lost_found:
		var watch = get_nodes_in_group("lost_item")[0]
		var bag_before: float = manager.bag_volume
		_expect(manager.collect_lost_item(watch), "Watch could not be stored safely")
		await process_frame
		_expect(manager.lost_item_state == "carried", "Watch was not marked as carried")
		_expect(is_equal_approx(manager.bag_volume, bag_before), "Watch entered the trash bag")
		_expect(manager.deposit_lost_items(), "Watch could not be deposited")
		_expect(manager.lost_item_state == "returned", "Watch was not marked as returned")
		_expect(manager.coins == 8, "Returning the watch awarded the wrong amount")
		_expect(FileAccess.file_exists(SAVE_PATH), "Autosave was not created")

	main.queue_free()
	await process_frame
	_delete_save()

	var penalty_main := gameplay_scene.instantiate()
	root.add_child(penalty_main)
	await process_frame
	await physics_frame
	manager = get_first_node_in_group("gameplay_manager")
	exit_door = get_first_node_in_group("exit_door")
	if manager:
		var penalty_watch = get_nodes_in_group("lost_item")[0]
		_expect(manager.destroy_lost_item(penalty_watch), "Watch destruction path failed")
		await process_frame
		_expect(manager.coins == -5, "Watch destruction penalty is not moderate and deterministic")
		_expect(manager.lost_item_state == "destroyed", "Destroyed watch state was not recorded")

		while manager.remaining_trash > 0:
			var made_progress := false
			for item in get_nodes_in_group("trash_item"):
				if is_instance_valid(item) and not item.is_queued_for_deletion():
					if manager.try_collect(item, true):
						made_progress = true
			await process_frame
			if manager.remaining_trash > 0:
				_expect(manager.empty_bag(), "Could not empty bag during progression test")
			if not made_progress and manager.remaining_trash > 0:
				_failures.append("Collection stopped before reaching 95 percent")
				break
		manager.empty_bag()
		_expect(manager.coins >= 30, "Destroying the watch caused an economy softlock")
		_expect(manager.try_purchase_next_upgrade(), "Quick Hands I could not be purchased")
		_expect(manager.has_upgrade(&"quick_hands_1"), "Quick Hands I was not applied")
		_expect(is_equal_approx(manager.pickup_cooldown, 0.15), "Quick Hands I has no gameplay effect")
		_expect(manager.try_purchase_next_upgrade(), "Reinforced Bag I could not be purchased")
		_expect(manager.has_upgrade(&"reinforced_bag_1"), "Reinforced Bag I was not applied")
		_expect(is_equal_approx(manager.bag_capacity, 20.0), "Reinforced Bag I did not set capacity to 20")
		await process_frame
		_expect(manager.room_completed, "Room completion was not recorded")
		_expect(exit_door != null and exit_door.is_open, "Exit did not open after meeting requirements")

	if pause_menu:
		pause_menu.toggle_pause()
		_expect(paused, "Pause menu did not pause the tree")
		_expect(pause_menu.get_node("PauseOverlay").visible, "Pause overlay is not visible")
		pause_menu.toggle_pause()
		_expect(not paused, "Pause menu did not resume the tree")

	penalty_main.queue_free()
	await process_frame

	var loaded_main := gameplay_scene.instantiate()
	root.add_child(loaded_main)
	await process_frame
	await physics_frame
	var loaded_manager = get_first_node_in_group("gameplay_manager")
	var loaded_door = get_first_node_in_group("exit_door")
	if loaded_manager:
		_expect(loaded_manager.has_upgrade(&"quick_hands_1"), "Quick Hands I did not persist")
		_expect(loaded_manager.has_upgrade(&"reinforced_bag_1"), "Reinforced Bag I did not persist")
		_expect(loaded_manager.room_completed, "Room completion did not persist")
		_expect(loaded_manager.lost_item_state == "destroyed", "Lost-item outcome did not persist")
		_expect(loaded_door != null and loaded_door.is_open, "Completed-room exit did not restore open")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	loaded_main.queue_free()
	await process_frame
	_delete_save()
	call_deferred("_finish")


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PHASE_3_SMOKE_OK")
		quit(0)
	else:
		print("PHASE_3_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)
