extends SceneTree

const SAVE_PATH := "user://cinema_cleaner_save.json"
const UpgradeCatalog := preload("res://resources/upgrades/upgrade_catalog.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_delete_save()
	_expect(UpgradeCatalog.BRANCHES.size() == 14, "Upgrade catalog must contain 14 independent branches after retiring Grabber")
	_expect(UpgradeCatalog.TOOL_DEFINITIONS.size() == 2, "Tool shop must contain Vacuum and Boti only")
	_expect(int(UpgradeCatalog.TOOL_DEFINITIONS.vacuum.cost) == 650, "Vacuum price changed")
	_expect(int(UpgradeCatalog.TOOL_DEFINITIONS.boti.cost) == 1600, "Boti price changed")

	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_expect(packed != null, "Gameplay scene failed to load")
	if packed == null:
		_finish()
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var manager = get_first_node_in_group("gameplay_manager")
	var player = get_first_node_in_group("player")
	var upgrade_menu = get_first_node_in_group("upgrade_menu")
	var tool_shop = get_first_node_in_group("tool_shop_panel")
	var exit_door = get_first_node_in_group("exit_door")
	var pause_menu = get_first_node_in_group("pause_menu")
	var hud = get_first_node_in_group("gameplay_hud")
	var initial_trash_layout_seed := int(manager._trash_layout_seed) if manager else 0
	_expect(manager != null, "Gameplay manager is missing")
	_expect(player != null, "Player is missing")
	_expect(upgrade_menu != null, "UpgradeMenu is missing")
	_expect(tool_shop != null, "ToolShopPanel is missing")
	_expect(get_nodes_in_group("manager_npc").is_empty(), "Manager must not be in room one")
	_expect(get_nodes_in_group("lost_found").size() == 1, "Manager office must contain its lost-items box")
	_expect(_room_one_trash().size() == 400, "Room one must contain its definitive 400 trash items")
	_expect(get_nodes_in_group("lost_item").size() == 1, "The first lost item is missing")
	_expect(exit_door != null and not exit_door.is_open, "Tutorial exit must start closed below 95 percent")
	_expect(exit_door != null and exit_door.door_panel.collision_layer == 1, "Closed tutorial exit does not block passage")

	if manager and player:
		_expect(manager.bag_volume is int, "Bag volume must use integer units")
		_expect(manager.bag_capacity == 10, "Initial bag capacity must be 10")
		_expect(is_equal_approx(manager.pickup_cooldown, 0.75), "Initial pickup cooldown must be 0.75 s")
		_expect(is_equal_approx(player.crouch_speed, 1.5), "Initial crouch speed must be 1.5 m/s")
		_expect(not bool(player.get_sprint_state().unlocked), "Sprint must begin locked")
		_expect(is_equal_approx(player.interaction_raycast.target_position.length(), 2.25), "Base pickup ray lacks floor-height allowance")
		var sprint_definition: Dictionary = manager.get_upgrade_state(&"sprint")
		_expect(int(sprint_definition.current_level) == 0, "Upgrade state lacks current_level")
		_expect(int(sprint_definition.max_level) == 5, "Upgrade state lacks max_level")
		_expect(String(sprint_definition.icon_path).ends_with("sprint.svg"), "Upgrade state lacks icon_path")
		_expect(not manager.purchase_upgrade(&"quick_hands"), "Upgrade purchase succeeded without enough coins")
		_expect(manager.get_upgrade_level(&"quick_hands") == 0, "Failed purchase changed the upgrade level")
		var cooldown_notices: Array[String] = []
		manager.notification_requested.connect(func(message: String) -> void: cooldown_notices.append(message))
		manager._pickup_cooldown_remaining = 0.5
		var cooldown_item = _room_one_trash()[0]
		_expect(not manager.request_collect(cooldown_item, player), "Pickup cooldown stopped working")
		_expect(cooldown_notices.is_empty(), "Pickup cooldown still shows a wait notification")
		_expect("espera" not in String(cooldown_item.get_interaction_prompt()).to_lower(), "Pickup prompt still mentions waiting")
		manager._pickup_cooldown_remaining = 0.0

		var watch = get_nodes_in_group("lost_item")[0]
		_expect(manager.collect_lost_item(watch), "Lost watch could not be collected")
		await process_frame
		_expect(hud != null and hud._lost_icon_pulse_running, "Lost-item counter icon did not animate on collection")
		_expect(manager.bag_volume == 0, "Lost items must not consume trash capacity")
		_expect(manager.deposit_lost_items(), "Future office deposit operation failed")
		_expect(manager.coins == 25, "The lost item must be worth 25 coins")
		var lost_box_packed := load("res://scenes/gameplay/lost_found_box.tscn") as PackedScene
		var lost_box := lost_box_packed.instantiate()
		main.add_child(lost_box)
		manager.lost_item_state = "carried"
		_expect("+25 monedas" in lost_box.get_interaction_prompt(), "Future lost-items box advertises an obsolete reward")
		manager.lost_item_state = "returned"
		lost_box.queue_free()
		await process_frame

		manager.coins = 5000
		_expect(manager.purchase_upgrade(&"quick_hands"), "Quick Hands I purchase failed")
		_expect(manager.get_upgrade_level(&"quick_hands") == 1, "Quick Hands level did not advance")
		_expect(is_equal_approx(manager.pickup_cooldown, 0.60), "Quick Hands I value is incorrect")
		_expect(manager.purchase_upgrade(&"reinforced_bag"), "Reinforced Bag I purchase failed")
		_expect(manager.bag_capacity == 15, "Reinforced Bag I must set capacity to 15")
		_expect(manager.purchase_upgrade(&"sprint"), "Sprint I purchase failed")
		var sprint_state: Dictionary = player.get_sprint_state()
		_expect(bool(sprint_state.unlocked), "Sprint I did not unlock sprint")
		_expect(is_equal_approx(player.sprint_speed, 5.2), "Sprint I speed is incorrect")
		_expect(is_equal_approx(float(sprint_state.duration), 3.0), "Sprint I duration is incorrect")
		_expect(is_equal_approx(float(sprint_state.recharge_time), 7.0), "Sprint I recharge time is incorrect")
		_expect(hud != null and not hud._sprint_bar.visible, "Sprint bar must remain hidden before sprint is used")
		player.set_physics_process(false)
		Input.action_press("sprint")
		player._update_sprint(0.70, true)
		var sprint_after_use := float(player.get_sprint_state().remaining)
		hud._update_sprint_bar(0.0)
		_expect(is_equal_approx(sprint_after_use, 2.30), "Sprint did not consume its persistent stamina")
		_expect(hud._sprint_bar.visible and hud._sprint_bar.value < 100.0, "Sprint use did not reveal the centered stamina bar")
		Input.action_release("sprint")
		player._update_sprint(0.70, false)
		var sprint_after_recharge := float(player.get_sprint_state().remaining)
		_expect(is_equal_approx(sprint_after_recharge, 2.60), "Sprint I does not recharge over seven seconds")
		Input.action_press("sprint")
		player._update_sprint(0.20, true)
		_expect(is_equal_approx(float(player.get_sprint_state().remaining), 2.40), "Re-pressing Sprint reset the remaining stamina")
		player._update_sprint(3.0, true)
		player._update_sprint(0.30, true)
		var exhausted_sprint: Dictionary = player.get_sprint_state()
		_expect(bool(exhausted_sprint.exhausted) and not bool(exhausted_sprint.is_sprinting), "Holding Sprint after exhaustion causes stop-start movement")
		Input.action_release("sprint")
		player._update_sprint(0.10, false)
		_expect(not bool(player.get_sprint_state().exhausted), "Releasing Sprint did not clear the exhausted state after recharge began")
		player.set_physics_process(true)
		_expect(manager.purchase_upgrade(&"manual_reach"), "Manual Reach I purchase failed")
		_expect(is_equal_approx(player.interaction_raycast.target_position.length(), 2.5), "Manual Reach I was not applied")

		_expect(not manager.purchase_upgrade(&"vacuum_reach"), "A locked Vacuum branch was purchasable")
		_expect(not manager.purchase_tool(&"grabber") and not manager.owns_tool(&"grabber"), "Retired Grabber can still be purchased")
		_expect(manager.purchase_tool(&"vacuum"), "Vacuum purchase failed")
		_expect(manager.owns_tool(&"hand_vacuum"), "Vacuum ownership was not recorded")
		_expect(manager.purchase_upgrade(&"vacuum_reach"), "Vacuum Reach I purchase failed")
		_expect(is_equal_approx(manager.vacuum_reach, 2.0), "Vacuum Reach I value is incorrect")
		_expect(upgrade_menu != null and not upgrade_menu._is_category_locked(&"vacuum"), "Bought Vacuum tab stayed locked")
		_expect(manager.cycle_hand_vacuum() and manager.equipped_tool.is_empty(), "Wheel cycle did not switch Vacuum to Hand")
		_expect(manager.cycle_hand_vacuum() and manager.equipped_tool == "vacuum", "Wheel cycle did not switch Hand to Vacuum")

		_expect(manager.purchase_upgrade(&"sealed_bags"), "Sealed Bags I purchase failed")
		manager.bag_volume = manager.bag_capacity
		manager._pending_base_value = manager.bag_capacity
		var coins_before_sack: int = manager.coins
		_expect(manager.try_seal_full_bag(), "A full bag could not be sealed")
		_expect(manager.bag_volume == 0, "Sealing did not empty the active bag")
		_expect(manager.get_node("SealedBags").get_child_count() == 1, "Sealed sack did not appear in the world")
		var sack = manager.get_node("SealedBags").get_child(0)
		var sack_forward_offset: Vector3 = sack.global_position - player.global_position
		_expect(sack_forward_offset.dot(-player.global_basis.z) > 0.8, "New sack did not appear in front of the player")
		_expect(is_equal_approx(sack.get_node("Model").scale.x, 6.9) and is_equal_approx((sack.get_node("CollisionShape3D").shape as SphereShape3D).radius, 0.57), "Sealed sack is not close to the requested 1.1 m size")
		var sack_spawn_height: float = sack.global_position.y
		_expect(sack.linear_velocity.y < 0.0, "New sack is not falling immediately")
		await create_timer(0.35).timeout
		_expect(sack.global_position.y < sack_spawn_height - 0.20, "New sack did not fall toward the floor")
		_expect(manager.pick_up_sealed_bag(sack), "Sealed sack could not be picked up")
		await process_frame
		var carry_hud = get_first_node_in_group("gameplay_hud")
		_expect(not manager.carried_sack.is_empty(), "Sack payload was not carried")
		_expect(sack.get_parent() == player.get_sack_carry_anchor() and not sack.is_world_model_visible(), "Carried sack world mesh was not hidden")
		_expect(carry_hud != null and carry_hud._carried_sack_view.visible, "Carried sack is not represented by a stable HUD element")
		var player_transform_before_wall_test: Transform3D = player.global_transform
		player.global_position = Vector3(-10.40, 0.10, 0.0)
		player.rotation_degrees.y = 90.0
		player.reset_camera_interpolation()
		await process_frame
		_expect(manager.drop_carried_sack(), "Sack could not find a safe drop point beside a wall")
		await physics_frame
		_expect(sack.get_absorption_probe_position().x > -10.55, "Dropped sack crossed the left wall")
		_expect(manager.pick_up_sealed_bag(sack), "Wall-safe sack could not be picked up again")
		player.global_transform = player_transform_before_wall_test
		player.reset_camera_interpolation()
		await process_frame
		var short_press := InputEventAction.new()
		short_press.action = &"interact"
		short_press.pressed = true
		player._unhandled_input(short_press)
		await create_timer(0.10).timeout
		var short_release := InputEventAction.new()
		short_release.action = &"interact"
		short_release.pressed = false
		player._unhandled_input(short_release)
		await physics_frame
		_expect(manager.carried_sack.is_empty() and sack.get_parent() == manager.get_node("SealedBags"), "Short E press did not drop the sack")
		_expect(sack.is_world_model_visible() and not carry_hud._carried_sack_view.visible, "Dropped sack did not return from HUD to the world")
		_expect(manager.pick_up_sealed_bag(sack), "Dropped sack could not be picked up again")
		var long_press := InputEventAction.new()
		long_press.action = &"interact"
		long_press.pressed = true
		player._unhandled_input(long_press)
		await create_timer(player.sack_throw_hold_time + 0.08).timeout
		var long_release := InputEventAction.new()
		long_release.action = &"interact"
		long_release.pressed = false
		player._unhandled_input(long_release)
		await physics_frame
		_expect(manager.carried_sack.is_empty() and sack.linear_velocity.length() >= 6.0, "Held E did not throw the sack")
		_expect(sack.linear_velocity.y >= 3.0 and sack.linear_damp <= 0.3 and sack.angular_velocity.length() < 1.0, "Sack launch is not using the smooth ballistic arc")
		var arc_start_height: float = sack.global_position.y
		await create_timer(0.16).timeout
		_expect(sack.global_position.y > arc_start_height, "Thrown sack does not rise into a parabola")
		var trash_bin := get_first_node_in_group("trash_bin") as Node3D
		var absorption_point: Vector3 = trash_bin.get_absorption_point()
		_expect(is_equal_approx(sack.BIN_ABSORB_DISTANCE, 1.0) and is_equal_approx(manager.CARRIED_SACK_ABSORB_DISTANCE, 1.0), "Sack delivery radius is not exactly one metre")
		var sack_collision := sack.get_node("CollisionShape3D") as CollisionShape3D
		var sack_collision_radius := (sack_collision.shape as SphereShape3D).radius
		var rotated_collision_offset: Vector3 = sack_collision.global_position - sack.global_position
		var target_collision_center := absorption_point + Vector3.RIGHT * (1.0 + sack_collision_radius - 0.05)
		sack.global_position = target_collision_center - rotated_collision_offset
		_expect(sack.is_within_absorption_radius(absorption_point, 1.0), "The one-metre bin trigger does not detect the sack's collision surface")
		sack.linear_velocity = Vector3.ZERO
		await create_timer(0.70).timeout
		_expect(manager.coins == coins_before_sack + 15, "Sack deposited the wrong integer value")
		_expect(not is_instance_valid(sack), "Sack was not absorbed when its surface entered the bin's one-metre side radius")

		manager.remaining_trash = 20
		manager._evaluate_room_completion()
		await process_frame
		_expect(manager.get_clean_percent() == 95, "Clean percent must reach 95 with 380/400 trash")
		_expect(manager.room_completed, "Room did not complete at 95 percent")
		_expect(exit_door != null and exit_door.is_open, "Exit did not open without shop requirements")
		manager.bag_volume = manager.bag_capacity
		manager._pending_base_value = manager.bag_capacity
		manager.state_changed.emit()
		hud._update_active_ability_hud()
		var sack_ability_widgets: Dictionary = hud._ability_cards.get("sealed_bags", {})
		_expect(not sack_ability_widgets.is_empty(), "Sealed Bags did not unlock its numbered HUD card")
		if not sack_ability_widgets.is_empty():
			_expect((sack_ability_widgets.status as Label).text == "0 / 1", "HUD does not preserve the compact active sack count")
		_expect(manager.try_seal_full_bag(), "A second sack could not be left for persistence testing")
		var persistent_sack = manager.get_node("SealedBags").get_child(0)
		_expect(String(persistent_sack.created_room_id) == "room_01" and not persistent_sack.delivered, "Sack metadata is incomplete")

	if upgrade_menu:
		_expect(not upgrade_menu.is_open(), "Upgrade menu must start closed")
		var tab_event := InputEventKey.new()
		tab_event.keycode = KEY_TAB
		tab_event.physical_keycode = KEY_TAB
		tab_event.pressed = true
		Input.parse_input_event(tab_event)
		await process_frame
		_expect(not paused and upgrade_menu.is_open(), "Upgrade menu paused gameplay while opening")
		var close_tab_event := InputEventKey.new()
		close_tab_event.keycode = KEY_TAB
		close_tab_event.physical_keycode = KEY_TAB
		close_tab_event.pressed = true
		Input.parse_input_event(close_tab_event)
		await process_frame
		_expect(not paused and not upgrade_menu.is_open(), "A second Tab press did not close the upgrade menu")
		_expect(pause_menu == null or not pause_menu.is_open(), "PauseMenu opened over the upgrade menu")
	if tool_shop:
		_expect(not tool_shop.is_open(), "Future tool shop must start inaccessible and hidden")
		tool_shop.open_shop()
		var modal_tab := InputEventAction.new()
		modal_tab.action = &"upgrade_menu"
		modal_tab.pressed = true
		Input.parse_input_event(modal_tab)
		await process_frame
		_expect(not upgrade_menu.is_open(), "Tab opened UpgradeMenu over another modal")
		tool_shop.close_shop()
		var desk_packed := load("res://scenes/characters/manager.tscn") as PackedScene
		var desk := desk_packed.instantiate()
		main.add_child(desk)
		await process_frame
		_expect(desk.is_in_group("manager_desk"), "Future manager desk has the wrong role")
		_expect(desk.get_interaction_prompt() == "E — Abrir mesa de herramientas", "Manager desk still advertises old upgrades")
		desk.interact(player)
		_expect(tool_shop.is_open(), "Manager desk did not open ToolShopPanel")
		tool_shop.close_shop()
		desk.queue_free()
		await process_frame

	main.queue_free()
	await process_frame
	var loaded := packed.instantiate()
	root.add_child(loaded)
	await process_frame
	await physics_frame
	var loaded_manager = get_first_node_in_group("gameplay_manager")
	var loaded_exit_door = get_first_node_in_group("exit_door")
	if loaded_manager:
		_expect(loaded_manager._trash_layout_seed == initial_trash_layout_seed, "Procedural trash layout seed did not persist")
		_expect(loaded_manager.get_upgrade_level(&"quick_hands") == 1, "Upgrade levels did not persist")
		_expect(loaded_manager.owns_tool(&"vacuum") and not loaded_manager.owns_tool(&"grabber"), "Vacuum ownership or Grabber retirement did not persist")
		_expect(loaded_manager.room_completed, "Room completion did not persist")
		_expect(not loaded_manager.is_exit_unlocked(), "Historical completion reopened a fresh Tutorial run below 95 percent")
		_expect(loaded_exit_door != null and not loaded_exit_door.is_open, "Tutorial exit did not restart closed after loading")
		_expect(loaded_manager.lost_item_state == "returned", "Lost-item state did not persist")
		_expect(loaded_manager.get_node("SealedBags").get_child_count() == 1, "Active sacks did not persist")
		if loaded_manager.get_node("SealedBags").get_child_count() == 1:
			var loaded_sack = loaded_manager.get_node("SealedBags").get_child(0)
			_expect(loaded_sack.contained_units == 15 and loaded_sack.contained_base_value == 15, "Persisted sack payload changed")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	loaded.queue_free()
	await process_frame
	_delete_save()
	call_deferred("_finish")


func _room_one_trash() -> Array[Node]:
	var result: Array[Node] = []
	for item in get_nodes_in_group("trash_item"):
		if item.has_method("get_room_id") and item.get_room_id() == &"room_01":
			result.append(item)
	return result


func _delete_save() -> void:
	var save_path := OS.get_environment("CINEMA_CLEANER_TEST_SAVE_PATH")
	if save_path.is_empty():
		save_path = SAVE_PATH
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


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
