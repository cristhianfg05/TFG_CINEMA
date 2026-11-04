extends SceneTree

const TRASH_SCENE := preload("res://scenes/gameplay/trash_item.tscn")
const POPCORN := preload("res://resources/trash/popcorn.tres")
const TICKET := preload("res://resources/trash/ticket.tres")
const PointerTheme := preload("res://scripts/pointer_theme.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_packed := load("res://scenes/main/main.tscn") as PackedScene
	_expect(main_packed != null, "Main scene does not load")
	if main_packed == null:
		_finish()
		return
	var main := main_packed.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get_node_or_null("ExitDoor") == null, "The obsolete standalone blue door still exists")
	var room := main.get_node_or_null("Room01Blockout")
	var integrated_door := room.get_node_or_null("ExitDoor") if room else null
	_expect(integrated_door != null, "The integrated room exit door is missing")
	_expect(integrated_door != null and integrated_door.is_in_group("exit_door"), "The integrated exit has no mechanics")
	_expect(integrated_door != null and integrated_door.get_node_or_null("RollerShutterDoor") is RollerShutterDoor, "Room 1 exit is not the shared roller-shutter component")
	_expect(room != null and room.get_node_or_null("DoorFrameLeft") == null and room.get_node_or_null("DoorFrameRight") == null, "Legacy Room 1 door frame overlaps the roller-shutter rails")
	_expect(room != null and room.get_node_or_null("VestibuleFloorA") == null and room.get_node_or_null("VestibuleBackWall") == null, "The future corridor area behind the exit is not empty")
	var manager = get_first_node_in_group("gameplay_manager")
	var hud = get_first_node_in_group("gameplay_hud")
	var player = get_first_node_in_group("player")
	_expect(hud._crosshair is TextureRect and hud._crosshair.is_visible_in_tree(), "Gameplay reticle is missing or hidden")
	_expect(hud._crosshair.texture == hud.RETICLE_DEFAULT, "Gameplay does not start with the supplied default reticle")
	_expect(hud._crosshair.size.is_equal_approx(Vector2(128, 128)), "Gameplay reticle is not using its native canvas size")
	var viewport_center: Vector2 = hud.get_viewport().get_visible_rect().size * 0.5
	var reticle_center: Vector2 = hud._crosshair.global_position + hud._crosshair.size * 0.5
	_expect(
		reticle_center.distance_to(viewport_center) <= 1.0,
		"Gameplay reticle is not centered: reticle=%s viewport=%s" % [reticle_center, viewport_center]
	)
	manager.bag_volume = manager.bag_capacity
	manager.state_changed.emit()
	_expect(hud._crosshair.texture == hud.RETICLE_BAG_FULL, "Full bag did not switch to the supplied full-bag reticle")
	manager.bag_volume = 0
	manager.state_changed.emit()
	_expect(hud._crosshair.texture == hud.RETICLE_DEFAULT, "Emptying the bag did not restore the default reticle")
	# A repeated rejection can happen immediately after multi-pickup due to the
	# shared cooldown. Its vibration must never reinterpret the centered offsets
	# as an absolute screen position.
	hud._play_pickup_rejected_feedback()
	await create_timer(0.05).timeout
	hud._play_pickup_rejected_feedback()
	await create_timer(0.30).timeout
	reticle_center = hud._crosshair.global_position + hud._crosshair.size * 0.5
	viewport_center = hud.get_viewport().get_visible_rect().size * 0.5
	_expect(
		reticle_center.distance_to(viewport_center) <= 1.0,
		"Rejected multi-pickup left the gameplay reticle away from center: reticle=%s viewport=%s" % [reticle_center, viewport_center]
	)
	var default_cursor := PointerTheme._load_cursor(PointerTheme.CURSOR_DEFAULT_PATH)
	var clickable_cursor := PointerTheme._load_cursor(PointerTheme.CURSOR_CLICKABLE_PATH)
	_expect(default_cursor != null and default_cursor.get_size() == Vector2(64, 64), "Default menu cursor was not resized safely")
	_expect(clickable_cursor != null and clickable_cursor.get_size() == Vector2(64, 64), "Clickable menu cursor was not resized safely")
	_expect(hud != null and hud._coin_panel is PanelContainer, "Gameplay coin counter is not using the standard HUD card")
	_expect(hud != null and hud._coin_panel.name == "CoinCounterCard", "Legacy coin container is still active")
	_expect(hud != null and hud._coin_panel.size.x <= 250.0, "Coin counter card is still oversized")
	var coin_row := hud._coin_panel.get_node("ContentMargins/CoinRow") as HBoxContainer
	var coin_icon := coin_row.get_node("CoinIcon") as TextureRect
	_expect(coin_icon == hud._coin_icon and coin_icon.position.x < hud._coins_label.position.x, "Coin icon is not on the left of the counter")
	await create_timer(0.20).timeout
	hud._pulse_coin_counter()
	await create_timer(0.05).timeout
	_expect(hud._coin_panel.scale.is_equal_approx(Vector2.ONE), "Coin reward still animates the whole counter card")
	_expect(not coin_icon.scale.is_equal_approx(Vector2.ONE), "The counter coin has no accordion feedback on reward arrival")
	await create_timer(0.35).timeout
	_expect(coin_icon.scale.is_equal_approx(Vector2.ONE), "Counter coin feedback did not settle cleanly")
	hud._animate_coin_reward(7, Vector3.ZERO)
	await process_frame
	var reward_popup := hud._coin_flight_layer.get_child(0) as Control
	var reward_start := reward_popup.position
	_expect(is_zero_approx(reward_popup.rotation) and reward_popup.scale.is_equal_approx(Vector2.ONE), "Coin reward still appears with rotation or scaling")
	await create_timer(0.82).timeout
	_expect(reward_popup.position.distance_to(reward_start) > 5.0, "Coin reward does not travel directly toward the counter")
	_expect(is_zero_approx(reward_popup.rotation) and reward_popup.scale.is_equal_approx(Vector2.ONE), "Coin reward rotates or shrinks while travelling")
	await create_timer(0.40).timeout
	_expect(hud._coin_flight_layer.get_child_count() == 0, "Coin reward popup did not disappear after reaching the counter")
	var progress_panel := hud.get_node("HUDRoot/RoomProgress") as PanelContainer
	var progress_margin := progress_panel.get_node("ContentMargins") as MarginContainer
	_expect(progress_panel.position.x <= 18.0 and progress_panel.position.y <= 16.0, "Room progress panel still has excessive outer margin")
	_expect(progress_margin.get_theme_constant("margin_left") <= 11 and progress_margin.get_theme_constant("margin_bottom") <= 3, "Room progress content still has excessive padding")
	_expect(hud._clean_label.get_theme_font_size("font_size") >= 30 and hud._clean_label.has_theme_font_override("font"), "Room progress number is not large and bold")
	_expect(hud._clean_bar.position.y > 0.0 and absf((hud._clean_bar.position.y + hud._clean_bar.size.y * 0.5) - (hud._clean_label.position.y + hud._clean_label.size.y * 0.5)) <= 1.0, "Progress bar and percentage are not horizontally aligned")
	var inventory_counters := hud.get_node("HUDRoot/InventoryCounters") as VBoxContainer
	_expect(inventory_counters.offset_top <= -222.0, "Inventory counters were not moved upward")
	_expect(inventory_counters.get_child_count() == 2, "Trash and lost-item counters are not separated")
	_expect(
		inventory_counters.get_child(0).size.is_equal_approx(inventory_counters.get_child(1).size),
		"Inventory counter cards do not have matching dimensions: %s vs %s" % [
			inventory_counters.get_child(0).size,
			inventory_counters.get_child(1).size,
		]
	)
	_expect(hud._bag_label.text == "0" and hud._trash_capacity_label.text == "10" and hud._lost_item_label.text == "0 / 1", "Inventory counters do not use the charged trash icon layout")
	var trash_icon := inventory_counters.get_child(0).get_node("ContentMargins/CounterRow/Icon") as Control
	var lost_icon := inventory_counters.get_child(1).get_node("ContentMargins/CounterRow/Icon") as TextureRect
	_expect((trash_icon.get_node("EmptyIcon") as TextureRect).texture.resource_path.ends_with("bolsa_icono.png"), "Trash counter is not using the supplied icon")
	_expect(lost_icon.texture.resource_path.ends_with("objetosPerdidos_icono.png"), "Lost-item counter is not using the supplied icon")
	_expect(hud._get_general_icon("hand").resource_path.ends_with("mano_icono.png"), "Manual tool is not using the supplied icon")
	_expect(hud._get_general_icon("vacuum").resource_path.ends_with("aspiradora_icono.png"), "Vacuum is not using the supplied icon")
	_expect(hud != null and hud._ability_stack.get_child_count() == 0, "An active ability is visible before being purchased")
	_expect(hud != null and hud._sprint_bar != null and not hud._sprint_bar.visible, "Sprint stamina bar is visible before Sprint is used")
	var sprint_background := hud._sprint_bar.get_theme_stylebox("background") as StyleBoxFlat
	var sprint_fill := hud._sprint_bar.get_theme_stylebox("fill") as StyleBoxFlat
	_expect(sprint_background.bg_color.is_equal_approx(hud.SPRINT_EMPTY) and sprint_fill.bg_color.is_equal_approx(hud.GOLD), "Sprint bar does not use dark-red spent stamina and gold remaining stamina")
	_expect(is_equal_approx(hud._sprint_bar.anchor_left, 0.5) and is_equal_approx(hud._sprint_bar.anchor_right, 0.5), "Sprint stamina bar is not horizontally centered")
	_expect(is_equal_approx(hud._carried_sack_view.position.x, inventory_counters.position.x), "Carried sack icon is not left-aligned with the inventory counters")
	_expect(hud._carried_sack_view.size.x > trash_icon.size.x and not hud._carried_sack_view.visible, "Carried sack icon has the wrong size or is visible without a carried sack")
	manager.trash_collected.emit()
	manager.trash_collected.emit()
	_expect(hud._trash_icon_pulse_running and hud._pending_trash_icon_pulses == 1, "Multiple trash icon pulses were not queued")
	await create_timer(0.15).timeout
	_expect(not trash_icon.scale.is_equal_approx(Vector2.ONE), "Collected trash does not animate the bag counter icon")
	await create_timer(0.50).timeout
	_expect(not hud._trash_icon_pulse_running and trash_icon.scale.is_equal_approx(Vector2.ONE), "Queued bag counter pulses did not settle cleanly")
	var entrance_bin := main.get_node("TrashBin")
	_expect(entrance_bin.position.z >= 14.45 and is_equal_approx(absf(entrance_bin.rotation_degrees.y), 180.0), "Exit trash bin is not flush with the rear wall and facing the screen")
	_expect((entrance_bin.get_absorption_point() - entrance_bin.global_position).is_equal_approx(Vector3.UP * 0.68), "Trash-bin absorption radius is not centered on its opening")
	var bin_forward: Vector3 = entrance_bin.global_basis.z.normalized()
	var bin_opening: Vector3 = entrance_bin.get_absorption_point()
	_expect(entrance_bin.is_position_in_acceptance_arc(bin_opening + bin_forward * 0.8), "Trash bin rejects sacks from its front")
	_expect(entrance_bin.is_position_in_acceptance_arc(bin_opening + Vector3.RIGHT * 0.8), "Trash bin rejects sacks from its side")
	_expect(not entrance_bin.is_position_in_acceptance_arc(bin_opening - bin_forward * 0.8), "Trash bin still accepts sacks through its back")
	var bin_base_scale: Vector3 = entrance_bin.get_node("Model").scale
	entrance_bin.play_deposit_animation()
	entrance_bin.play_deposit_animation()
	_expect(entrance_bin._deposit_animation_running and entrance_bin._pending_deposit_pulses == 1, "Concurrent bin feedback was not queued")
	await create_timer(0.15).timeout
	_expect(not entrance_bin.get_node("Model").scale.is_equal_approx(bin_base_scale), "Trash bin deposit has no accordion motion")
	await create_timer(0.72).timeout
	_expect(not entrance_bin._deposit_animation_running and entrance_bin.get_node("Model").scale.is_equal_approx(bin_base_scale), "Trash bin animation did not settle after queued deliveries")
	var upgrade_menu = get_first_node_in_group("upgrade_menu")
	_expect(upgrade_menu != null and upgrade_menu._section_bar.get_child_count() == 4, "Tab menu must expose abilities, objectives and two archives")
	_expect(upgrade_menu != null and upgrade_menu._section_bar.get_child(2).text == "?" and upgrade_menu._section_bar.get_child(3).text == "?", "Locked collection tabs must only show question marks")
	_expect(upgrade_menu != null and upgrade_menu._tab_bar.get_child_count() == 3, "Ability menu must expose Limpieza, Vacuum and Boti only")
	_expect(upgrade_menu != null and upgrade_menu._tab_bar.get_child(1).disabled and upgrade_menu._tab_bar.get_child(1).text == "?", "Unpurchased tools must remain anonymous and disabled")
	_expect(upgrade_menu != null and upgrade_menu._section_bar.get_child(2).disabled and upgrade_menu._section_bar.get_child(3).disabled, "Empty collection sections must be disabled")
	_expect(upgrade_menu._section_bar.get_child(0).mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "Available menu tab does not use the clickable cursor")
	_expect(upgrade_menu._section_bar.get_child(2).mouse_default_cursor_shape == Control.CURSOR_ARROW, "Disabled menu tab still uses the clickable cursor")
	_expect(hud != null and hud._tool_slots.get_child_count() == 1, "HUD must only show the manual tool before purchases")
	var hand_card := hud._tool_slots.get_child(0) as PanelContainer
	var hand_style := hand_card.get_theme_stylebox("panel") as StyleBoxFlat
	var hand_icon := hand_card.get_node("Content/Icon") as TextureRect
	var hand_key := hand_card.get_node("Content/Key") as Label
	_expect(hand_style.border_color.is_equal_approx(hud.GOLD), "Selected manual tool does not have a gold border")
	_expect(hand_icon.size.x >= 74.0 and hand_icon.position.y <= 0.0, "Manual tool icon is not large and raised")
	_expect(hand_key.position.x <= 9.0 and hand_key.position.y <= 4.0 and hand_key.get_theme_font_size("font_size") >= 31, "Tool shortcut is not large inside the top-left corner")
	_expect(hud != null and hud.get_node_or_null("HUDRoot/CurrentObjective") == null, "Future CineSweep HUD is visible before unlock")
	upgrade_menu.open_menu()
	await process_frame
	_expect(not paused, "Opening the Tab menu paused gameplay")
	_expect(hud._coin_canvas.layer > upgrade_menu.layer, "HUD coin counter remains below the Tab shade")
	upgrade_menu._select_branch(&"sprint")
	_expect("Recarga completa" in upgrade_menu._detail_description.text, "Sprint upgrade does not explain its recharge trait")
	_expect(upgrade_menu._frame.size.y <= 620.0, "Tab menu container is still too tall")
	_expect(upgrade_menu._frame.size.x <= 1365.0, "Tab menu container is still too wide")
	var menu_title := upgrade_menu._menu_shell.get_node("MenuTitle") as Label
	var title_gap: float = upgrade_menu._frame.position.y - (menu_title.position.y + menu_title.size.y)
	var section_gap: float = upgrade_menu._frame.position.y - (upgrade_menu._section_bar.position.y + upgrade_menu._section_bar.size.y)
	_expect(title_gap >= 0.0 and title_gap <= 20.0, "Menu title is not aligned close to the container")
	_expect(section_gap >= 0.0 and section_gap <= 20.0, "Primary tabs are not aligned close to the container")
	for section_button in upgrade_menu._section_bar.get_children():
		_expect(section_button.has_theme_font_override("font") and section_button.get_theme_font_size("font_size") >= 28, "Primary menu tabs are not large and bold")
	for ability_button in upgrade_menu._tab_bar.get_children():
		_expect(ability_button.has_theme_font_override("font") and ability_button.get_theme_font_size("font_size") >= 25, "Ability tabs are not large and bold")
	var cost_row := upgrade_menu._frame.find_child("UpgradeCost", true, false) as HBoxContainer
	var cost_icon := cost_row.get_node("CoinIcon") as TextureRect
	_expect(cost_row.alignment == BoxContainer.ALIGNMENT_BEGIN, "Upgrade cost is not aligned to the left")
	_expect((cost_row.get_child(0) as Label).get_theme_font_size("font_size") >= 32, "Cost title is still too small")
	_expect(cost_icon.custom_minimum_size.x >= 50.0 and upgrade_menu._detail_cost.get_theme_font_size("font_size") >= 38, "Cost icon or value is still too small")
	upgrade_menu._select_category(&"collection")
	await process_frame
	var collection_tree_id: int = upgrade_menu._tree.get_instance_id()
	_expect(upgrade_menu._tree.get_child_count() == 8, "Limpieza does not show its eight upgrade branches")
	_expect("MANOS ÁGILES" in upgrade_menu._detail_title.text, "Collection tab did not select its first branch")
	upgrade_menu._select_category(&"vacuum")
	await process_frame
	upgrade_menu._select_category(&"collection")
	await process_frame
	_expect(upgrade_menu._tree.get_instance_id() == collection_tree_id, "Collection upgrade tree was rebuilt during a repeated tab switch")
	var replacement_icons := {
		"sprint": "upgrade_sprint_gold.png",
		"quick_hands": "upgrade_agile_hands_gold.png",
		"reinforced_bag": "upgrade_reinforced_bag_gold.png",
		"multi_pickup": "upgrade_multiple_pickup_gold.png",
		"manual_reach": "upgrade_manual_reach_gold.png",
		"sealed_bags": "upgrade_sealed_bags_gold.png",
		"recycle_value": "upgrade_recycling_value_gold.png",
		"all_seeing_eye": "upgrade_eye_all_trash.png",
		"vacuum_reach": "upgrade_vacuum_reach_gold.png",
		"vacuum_battery": "upgrade_vacuum_battery_gold.png",
		"vacuum_recharge": "upgrade_vacuum_recharge_gold.png",
		"boti_capacity": "upgrade_boti_capacity_gold.png",
		"boti_rest": "upgrade_boti_rest_gold.png",
		"boti_speed": "upgrade_boti_speed_gold.png",
	}
	for branch_id in replacement_icons:
		var replacement := upgrade_menu._load_icon(branch_id) as Texture2D
		_expect(replacement != null and replacement.resource_path.ends_with(replacement_icons[branch_id]), "Tab upgrade icon was not replaced for %s" % branch_id)
		_expect(replacement != null and replacement.get_width() <= 256 and replacement.get_height() <= 256, "Tab upgrade icon was imported above its UI resolution for %s" % branch_id)
	upgrade_menu.close_menu()
	_expect(hud._coin_canvas.layer == 11, "HUD coin counter layer was not restored after closing Tab")
	var pause_menu = get_first_node_in_group("pause_menu")
	for pause_button in pause_menu._overlay.find_children("*", "Button", true, false):
		_expect(pause_button.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "Clickable pause option does not use the supplied hand cursor")
	var tool_shop = get_first_node_in_group("tool_shop_panel")
	for shop_button in tool_shop._cards.find_children("*", "Button", true, false):
		_expect(shop_button.disabled and shop_button.mouse_default_cursor_shape == Control.CURSOR_ARROW, "Unavailable shop option still uses the clickable cursor")
	var main_menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(main_menu)
	await process_frame
	for menu_button in main_menu.find_children("*", "Button", true, false):
		var expected_cursor := Control.CURSOR_ARROW if menu_button.disabled else Control.CURSOR_POINTING_HAND
		_expect(menu_button.mouse_default_cursor_shape == expected_cursor, "Main-menu cursor does not match the button state")
	main_menu.queue_free()
	await process_frame

	var loose_door := (load("res://scenes/gameplay/exit_door.tscn") as PackedScene).instantiate()
	root.add_child(loose_door)
	await process_frame
	var loose_shutter := loose_door.shutter as RollerShutterDoor
	_expect(loose_door.get_node_or_null("RightPanel") == null, "Exit still contains a second door leaf")
	_expect(loose_shutter != null and loose_shutter.get_slat_nodes().size() == 14, "Room exit is not using the reusable roller shutter")
	loose_door.open_door()
	await create_timer(1.30).timeout
	await physics_frame
	_expect(loose_shutter != null and is_equal_approx(loose_shutter.openness, 1.0), "Exit roller shutter did not open upwards")
	_expect(loose_door.door_panel.collision_layer == 0, "Open exit door collision remained active")

	var popcorn := TRASH_SCENE.instantiate()
	popcorn.definition = POPCORN
	root.add_child(popcorn)
	var ticket := TRASH_SCENE.instantiate()
	ticket.definition = TICKET
	root.add_child(ticket)
	await process_frame
	_expect(popcorn.lock_rotation, "Popcorn can still roll")
	_expect(popcorn.get_node("Collision").shape is BoxShape3D, "Popcorn still uses a rolling collision")
	_expect(ticket.lock_rotation, "Flat tickets can still tip into the floor")
	_expect(ticket.get_visual_bottom_local_y() >= 0.011, "Flat ticket visual has no floor clearance")
	_expect((ticket.get_node("Collision").shape as BoxShape3D).size.y >= 0.045, "Flat ticket collider is too thin")

	main.queue_free()
	loose_door.queue_free()
	popcorn.queue_free()
	ticket.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("LATEST_POLISH_SMOKE_OK")
		quit(0)
	else:
		print("LATEST_POLISH_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)
