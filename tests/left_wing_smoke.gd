extends SceneTree

const SAVE_PATH := "res://.godot/left_wing_smoke_save.json"
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var manager = get_first_node_in_group("gameplay_manager")
	var player = get_first_node_in_group("player")
	var hud = get_first_node_in_group("gameplay_hud")
	var shop = get_first_node_in_group("tool_shop_panel")
	_expect(manager != null, "GameplayManager missing")
	_expect(shop != null, "Reused ToolShopPanel missing")
	var intro = get_first_node_in_group("game_intro")
	if intro and intro.has_method("complete_immediately"):
		intro.complete_immediately()
		await process_frame
	_expect(get_nodes_in_group("trash_bin").size() == 2, "Room 1 and the still-cleanable vestibule each need one trash bin")
	var corridor_items: Array[Node] = []
	var office_items: Array[Node] = []
	for item in get_nodes_in_group("trash_item"):
		if item.get_room_id() == &"left_corridor": corridor_items.append(item)
		if item.get_room_id() == &"manager_office": office_items.append(item)
	_expect(corridor_items.size() == 120, "Corridor must contain exactly 120 fixed trash objects")
	_expect(office_items.size() == 18, "Office must contain exactly 18 fixed trash objects")
	_expect(_unit_total(corridor_items) == 135, "Corridor must contain exactly 135 trash units")
	_expect(_unit_total(office_items) == 20, "Office must contain exactly 20 trash units")
	_expect(int(manager.room_trash_totals.get("left_corridor", 0)) == 120, "Corridor progress was not registered")
	_expect(int(manager.room_trash_totals.get("manager_office", 0)) == 18, "Office progress was not registered")
	var collected_fixed_id := String(corridor_items[0].world_item_id)
	manager.bag_capacity = 100
	_expect(manager.try_collect(corridor_items[0], true), "Fixed corridor trash could not be collected")
	await process_frame
	_expect(int(manager.room_trash_remaining.left_corridor) == 119, "Corridor progress did not update independently")

	var room_two = main.get_node("LeftWingBlockout/Room02Access")
	var office_door = main.get_node("LeftWingBlockout/ManagerOfficeAccess")
	var corridor_ceiling = main.get_node("LeftWingBlockout/CorridorCeiling")
	var ceiling_collision := corridor_ceiling.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D
	var ceiling_shape := ceiling_collision.shape as BoxShape3D
	_expect(corridor_ceiling.position.z - ceiling_shape.size.z * 0.5 >= 15.35, "Corridor ceiling still intersects Room 1's rear wall")
	_expect(room_two.position.x == 9.0 and room_two.shutter.opening_width == 3.0 and not room_two.shutter.is_open, "Future Room 2 shutter is not directly opposite Room 1, wide and closed")
	_expect(office_door.shutter.opening_width == 1.6 and not office_door.shutter.is_open, "Office shutter is not narrow and initially closed")
	var left_wing = main.get_node("LeftWingBlockout")
	_expect(main.has_node("LeftWingBlockout/FutureArcadeMachine") and left_wing.find_children("CorridorStool_*", "StaticBody3D", true, false).size() == 5, "Five stools around the corridor table are missing")
	_expect(left_wing.has_node("CorridorRoundTable") and left_wing.has_node("CorridorVendingMachine"), "Round table or supplied vending machine is missing")
	_expect(left_wing.has_node("Room02WallArmchair") and left_wing.has_node("Room02WallPotatoDisplay"), "Room 2 wall armchair or potato display is missing")
	_expect(is_equal_approx(absf(left_wing.get_node("Room02WallArmchair/Model").rotation_degrees.y), 180.0) and is_equal_approx(absf(left_wing.get_node("Room02WallPotatoDisplay/Model").rotation_degrees.y), 180.0), "Room 2 wall decorations were not rotated 180 degrees")
	_expect(is_equal_approx(absf(left_wing.get_node("FutureArcadeMachine/Model").rotation_degrees.y), 180.0), "Arcade machine was not rotated 180 degrees")
	_expect(left_wing.get_node("CorridorVendingMachine").position.z < 17.0 and left_wing.get_node("CorridorVendingMachine/Model").rotation_degrees.is_zero_approx(), "Vending machine did not receive its additional 180-degree turn beside Room 1")
	_expect(is_equal_approx(left_wing.get_node("CorridorVendingMachine").position.z, 15.89), "Vending machine is not close to the Room 1 wall")
	_expect(is_equal_approx(left_wing.get_node("FutureArcadeMachine").position.x, -10.75) and left_wing.get_node("FutureArcadeMachine").position.z < 25.0, "Right-corridor arcade is not at the blue marker")
	_expect(left_wing.has_node("Room01EntryPosterFrame") and left_wing.get_node("Room01EntryPosterDisplay").position.y > 1.3, "Room 1 entry poster or raised display is missing")
	_expect(left_wing.get_node("Room01EntryPosterDisplay").position.z - left_wing.get_node("Room01EntryPosterFrame").position.z < 0.15, "Room 1 poster image floats ahead of its frame")
	var room3_entry_panel = main.get_node("Room03Blockout/EntryWestWingPanel_00")
	_expect(room3_entry_panel.get_child(0).mesh.size.x <= 4.6, "Room 3 entry wine panel texture is stretched")
	var corridor_zone = main.get_node("LeftWingBlockout/LeftCorridorZone")
	var return_zone = main.get_node("LeftWingBlockout/Room01ReturnZone")
	corridor_zone._on_body_entered(player)
	_expect(player.get_current_room_id() == &"left_corridor", "Corridor room detection failed")
	_expect(hud._room_title.text == "PASILLO — ALA DERECHA", "Original corridor HUD title must say right wing")
	manager._all_seeing_active_remaining = 5.0
	manager._all_seeing_room_id = &"left_corridor"
	return_zone._on_body_entered(player)
	_expect(player.get_current_room_id() == &"room_01", "Returning to Room 1 did not restore its room ID")
	_expect(hud._room_title.text == "SALA 1 — TUTORIAL", "Returning to Room 1 did not restore the Tutorial HUD title")
	_expect(manager._all_seeing_room_id == &"room_01", "All-Seeing Eye did not follow the player back into Room 1")
	manager._all_seeing_active_remaining = 0.0
	manager.room_completed = true
	manager.state_changed.emit()
	for frame in 90: await physics_frame
	_expect(office_door.shutter.is_open and office_door.shutter.collision_shape.disabled, "Office shutter did not open with synchronized collision")
	_expect(not room_two.shutter.is_open, "Room 2 opened before the right wing and office reached 95%")
	manager.room_trash_remaining["room_01"] = 0
	manager.room_trash_remaining["left_corridor"] = 0
	manager.room_trash_remaining["manager_office"] = 0
	manager.state_changed.emit()
	for frame in 90: await physics_frame
	_expect(room_two.shutter.is_open and room_two.shutter.collision_shape.disabled, "Room 2 shutter did not open after right wing and office progression")

	var displays := get_nodes_in_group("tool_display")
	_expect(displays.size() == 2, "Vacuum and Boti must both appear on the desk")
	for display in displays:
		_expect(display.get_interaction_prompt() == "[E] Inspeccionar", "Tool display prompt is incorrect")
	manager.coins = 649
	shop.open_tool(&"hand_vacuum", displays[0])
	_expect(shop.is_open() and paused, "Tool inspection did not use the existing modal pause flow")
	_expect(shop._buy_button.disabled and shop._state_label.text == "Monedas insuficientes", "Insufficient-money state is incorrect")
	shop.close_shop()
	manager.coins = 3000
	shop.open_tool(&"hand_vacuum", displays[0])
	shop._purchase_current()
	_expect(manager.coins == 2350 and manager.owns_tool(&"hand_vacuum"), "Vacuum purchase did not deduct exactly 650 once")
	shop._purchase_current()
	_expect(manager.coins == 2350, "Vacuum could be purchased twice")
	shop.close_shop()
	await process_frame
	_expect(not is_instance_valid(displays[0]), "Purchased display remained on the desk after closing")
	_expect(manager.equipped_tool == "vacuum", "Purchased vacuum was not integrated with equipment")
	# The headless display server cannot enter captured mouse mode, so validate
	# the exact wheel-cycle endpoint called by PlayerController here.
	_expect(manager.cycle_hand_vacuum() and manager.equipped_tool.is_empty(), "Equipment cycle did not switch from Vacuum to Hand")
	_expect(manager.cycle_hand_vacuum() and manager.equipped_tool == "vacuum", "Equipment cycle did not switch from Hand to Vacuum")
	shop.open_tool(&"boti", displays[1])
	shop._purchase_current()
	_expect(manager.coins == 750 and manager.owns_tool(&"boti"), "Boti purchase did not deduct exactly 1600 once")
	shop.close_shop()
	await process_frame
	_expect(manager.equipped_tool == "vacuum" and not manager.equip_tool(&"boti"), "Boti incorrectly entered the hand-held equipment cycle")
	_expect(hud._tool_slots.get_child_count() == 2, "Boti incorrectly added a third hand-held HUD slot")

	main.queue_free()
	await process_frame
	var loaded := packed.instantiate()
	root.add_child(loaded)
	await process_frame
	await physics_frame
	var loaded_manager = get_first_node_in_group("gameplay_manager")
	_expect(loaded_manager.owns_tool(&"hand_vacuum") and loaded_manager.owns_tool(&"boti") and loaded_manager.coins == 750, "Tool ownership or economy did not survive reload")
	var loaded_ids: Array[String] = []
	for display in get_nodes_in_group("tool_display"):
		loaded_ids.append(String(display.tool_id))
	_expect("hand_vacuum" not in loaded_ids and "boti" not in loaded_ids, "Purchased models reappeared on the desk")
	_expect(loaded_manager.is_world_trash_collected(collected_fixed_id), "Collected fixed trash was not persisted")
	var loaded_corridor_count := 0
	for item in get_nodes_in_group("trash_item"):
		if item.get_room_id() == &"left_corridor": loaded_corridor_count += 1
	_expect(loaded_corridor_count == 119 and int(loaded_manager.room_trash_remaining.left_corridor) == 119, "Collected corridor trash reappeared after loading")
	loaded_manager.reset_authored_room_trash_for_debug()
	_expect(not loaded_manager.is_world_trash_collected(collected_fixed_id), "Debug reset did not clear authored-room trash IDs")
	_expect(int(loaded_manager.room_trash_remaining.left_corridor) == 120 and int(loaded_manager.room_trash_remaining.manager_office) == 18, "Debug reset did not restore corridor and office totals")
	var debug_complete_event := InputEventKey.new()
	debug_complete_event.keycode = KEY_F8
	debug_complete_event.pressed = true
	debug_complete_event.ctrl_pressed = true
	debug_complete_event.shift_pressed = true
	loaded_manager._input(debug_complete_event)
	await process_frame
	_expect(loaded_manager.coins == 999999 and loaded_manager.room_completed, "Debug completion did not unlock progression and test money")
	_expect(not loaded_manager.owns_tool(&"grabber") and loaded_manager.owns_tool(&"hand_vacuum") and loaded_manager.owns_tool(&"boti"), "Debug completion did not respect the retired Grabber catalog")
	_expect(int(loaded_manager.room_trash_remaining.left_corridor) == 0 and int(loaded_manager.room_trash_remaining.manager_office) == 0, "Debug completion did not clean authored rooms")
	_expect(get_nodes_in_group("trash_item").is_empty(), "Debug completion left physical trash in the world")
	var loaded_upgrade_menu = get_first_node_in_group("upgrade_menu")
	_expect(not loaded_upgrade_menu._is_category_locked(&"vacuum") and not loaded_upgrade_menu._is_category_locked(&"boti"), "Purchased tool upgrade tabs did not unlock")
	loaded.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("LEFT_WING_SMOKE_OK")
		quit(0)
	else:
		print("LEFT_WING_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _unit_total(items: Array[Node]) -> int:
	var total := 0
	for item in items: total += int(item.definition.size_units)
	return total


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
