extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const UpgradeCatalog := preload("res://resources/upgrades/upgrade_catalog.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var intro = get_first_node_in_group("game_intro")
	if intro and intro.has_method("complete_immediately"):
		intro.complete_immediately()
	await process_frame

	_expect(UpgradeCatalog.CATEGORIES == [&"collection", &"vacuum", &"boti"], "Retired Player or Grabber categories still exist")
	_expect(UpgradeCatalog.CATEGORY_TITLES.collection == "LIMPIEZA", "The combined category is not named Limpieza")
	var cleaning := UpgradeCatalog.get_category_branches(&"collection")
	_expect(cleaning.size() == 8, "Limpieza does not contain its eight branches")
	if cleaning.size() >= 4:
		_expect([cleaning[0].id, cleaning[1].id, cleaning[2].id] == ["quick_hands", "reinforced_bag", "sealed_bags"], "The first three cleaning abilities are out of order")
		_expect(String(cleaning[3].id) == "sprint", "Sprint was not moved into Limpieza")
	_expect(UpgradeCatalog.get_branch(&"crouch_speed").is_empty(), "Crouched-running upgrade still exists")
	var eye := UpgradeCatalog.get_branch(&"all_seeing_eye")
	_expect((eye.costs as Array) == [120, 300, 700] and (eye.cooldowns as Array) == [180.0, 120.0, 60.0], "All-seeing eye balance is not centralized")
	_expect(InputMap.has_action(&"ability_1") and InputMap.has_action(&"ability_2"), "Numbered ability actions are missing")

	var straw_radius := 0.0
	var smallest_radius := INF
	for item in get_nodes_in_group("trash_item"):
		var focus := item.get_node_or_null("InteractionArea/FocusRadius") as CollisionShape3D
		if focus == null or not focus.shape is SphereShape3D:
			continue
		var radius := (focus.shape as SphereShape3D).radius
		smallest_radius = minf(smallest_radius, radius)
		if String(item.definition.id) == "straw":
			straw_radius = maxf(straw_radius, radius)
	_expect(smallest_radius >= 0.30, "General trash assistance radius was not enlarged")
	_expect(straw_radius >= 0.54, "Straw assistance radius regressed")

	var manager = get_first_node_in_group("gameplay_manager")
	var hud = get_first_node_in_group("gameplay_hud")
	var player = get_first_node_in_group("player")
	var upgrade_menu = get_first_node_in_group("upgrade_menu")
	_expect(manager != null and hud != null, "Gameplay manager or HUD is missing")
	if manager == null or hud == null:
		_finish()
		return
	manager.bag_volume = 5
	manager.bag_capacity = 10
	hud._update_state()
	_expect(hud._bag_label.text == "5" and hud._trash_capacity_label.text == "10", "Trash count and capacity are not separated")
	var trash_card := hud.get_node("HUDRoot/InventoryCounters/TrashCounter") as PanelContainer
	var lost_card := hud.get_node("HUDRoot/InventoryCounters/LostItemCounter") as PanelContainer
	_expect(trash_card.custom_minimum_size == Vector2(250, 90) and lost_card.custom_minimum_size == Vector2(250, 90), "Inventory counters are not compact and tall")
	_expect(hud._trash_counter_icon.custom_minimum_size == Vector2(70, 70), "Trash icon was not enlarged")
	_expect(is_equal_approx(hud._trash_icon_fill_mask.size.y, 35.0), "Trash icon mask is not half filled at half capacity")
	_expect(hud._journal_shortcut != null and hud._journal_shortcut.get_node_or_null("Content/TabBadge") != null, "Journal shortcut or its Tab badge is missing")
	_expect(not hud._journal_shortcut is PanelContainer and hud.JOURNAL_ICON.resource_path.ends_with("icon_objectives.png"), "Journal shortcut still has a frame or uses the old icon")
	_expect(upgrade_menu != null and upgrade_menu._section_bar.get_child_count() == 4, "Objectives were not added after Abilities")
	if upgrade_menu:
		manager._found_document_ids.clear()
		manager._found_collectible_ids.clear()
		manager.room_completed = false
		upgrade_menu._select_primary_section(&"objectives")
		_expect(upgrade_menu._objectives_list.get_child_count() == 1, "Undiscovered objectives are revealed too early")
		manager._found_document_ids["Doc1"] = true
		manager._found_collectible_ids["capitan_orbita"] = true
		manager._sync_document_definition_state("Doc1")
		manager._sync_collectible_definition_state("capitan_orbita")
		upgrade_menu._refresh_objectives()
		_expect(upgrade_menu._objectives_list.get_child_count() == 3, "Document and collectible objectives were not discovered")
		upgrade_menu._select_primary_section(&"abilities")
		upgrade_menu._select_category(&"collection")
		_expect(upgrade_menu._tree_scroll_hint.visible and "DESLIZA" in upgrade_menu._tree_scroll_hint.text, "The ability scroll has no visible downward hint")
		_expect(upgrade_menu._tree_scroll.get_v_scroll_bar().custom_minimum_size.x >= 18.0, "The ability scrollbar is still too thin")
	manager.upgrade_levels = {"sealed_bags": 1, "all_seeing_eye": 1}
	manager.ability_ready_at_unix.clear()
	manager._apply_upgrades()
	manager.state_changed.emit()
	await process_frame
	hud._update_active_ability_hud()
	_expect(hud._ability_cards.size() == 2, "Unlocked active abilities are not shown under the money")
	_expect(hud._ability_cards.has("sealed_bags") and hud._ability_cards.has("all_seeing_eye"), "An active ability card is missing")
	_expect(hud.get_node_or_null("HUDRoot/SackCount") == null, "The old sack text still exists")
	if hud._ability_cards.has("sealed_bags"):
		var sack_status := (hud._ability_cards.sealed_bags as Dictionary).status as Label
		_expect(sack_status.text == "0 / 1", "Sealed bags do not use the compact counter")
	_expect(hud._carried_sack_view != null, "The carried sack icon was removed")

	var room_two_item = get_nodes_in_group("trash_item")[0]
	room_two_item.room_id = &"room_02"
	_expect(manager.try_use_active_ability(1), "The all-seeing eye cannot be activated")
	var ability_state := manager.get_active_ability_states()[1] as Dictionary
	_expect(float(ability_state.cooldown_remaining) > 179.0, "The all-seeing cooldown did not start")
	_expect(float(ability_state.active_remaining) > 4.9, "The first-level reveal duration is wrong")
	var revealed_count := 0
	for item in get_nodes_in_group("trash_item"):
		for mesh in item.find_children("*", "MeshInstance3D", true, false):
			if (mesh as MeshInstance3D).material_overlay != null:
				revealed_count += 1
				break
	_expect(revealed_count > 200, "The ability does not reveal the room's trash")
	_expect(_first_mesh(room_two_item).material_overlay == null, "The eye revealed trash from another room")
	player.set_current_room_id(&"room_02")
	await physics_frame
	_expect(_first_mesh(room_two_item).material_overlay != null, "The eye did not follow the player into the next room")
	var old_room_still_visible := false
	for item in get_nodes_in_group("trash_item"):
		if item != room_two_item and _first_mesh(item).material_overlay != null:
			old_room_still_visible = true
			break
	_expect(not old_room_still_visible, "Trash from the previous room remains revealed")
	_expect(not manager.try_use_active_ability(1), "The eye can be reused during cooldown")
	manager._all_seeing_active_remaining = 0.001
	await physics_frame
	await physics_frame
	var lingering_overlay := false
	for item in get_nodes_in_group("trash_item"):
		for mesh in item.find_children("*", "MeshInstance3D", true, false):
			if (mesh as MeshInstance3D).material_overlay != null:
				lingering_overlay = true
				break
		if lingering_overlay:
			break
	_expect(not lingering_overlay, "The reveal overlay remains after the active duration")
	_finish()


func _first_mesh(item: Node) -> MeshInstance3D:
	return item.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ACTIVE_ABILITIES_SMOKE_OK")
		quit(0)
	else:
		print("ACTIVE_ABILITIES_SMOKE_FAILED: %s" % str(_failures))
		quit(1)
