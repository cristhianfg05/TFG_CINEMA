extends SceneTree

const SAVE_PATH := "res://.godot/hammer_progression_smoke_save.json"
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	_remove_save()
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	var right_wing := main.get_node("LeftWingBlockout")
	var expansion := main.get_node("CinemaExpansionBlockout")
	var pickup := right_wing.get_node("ManagerHammerPickup")
	var wall := expansion.get_node("FutureFinalRoomBrickBarrier")
	var hammer := main.get_node("HammerController")
	_expect(hammer._stone_audio.stream.resource_path == "res://assets/audio/sfx/hammer/hammer_stone_02.wav" and hammer._stone_audio.bus == &"World", "Approved stone hit was not assigned to the World bus")
	_expect(hammer._swing_audio.stream.resource_path == "res://assets/audio/sfx/hammer/hammer_swing_01.wav" and hammer._swing_audio.bus == &"Tools", "Approved swing 01 was not assigned to the Tools bus")
	_expect(hammer._pivot.get_node_or_null("HeldGripHand") != null, "The first-person hammer has no grip hand")
	_expect(hammer._grip_hand.find_children("*", "MeshInstance3D", true, false).size() == 1, "The hammer grip hand must be the imported single-mesh asset")
	var office := right_wing.get_node("ManagerOfficeAccess") as ProgressionShutter
	var room_two := right_wing.get_node("Room02Access") as ProgressionShutter
	_expect(not office.shutter.is_open and not room_two.shutter.is_open and not expansion._room_three_shutter.is_open and not expansion._lobby_shutter.is_open and not expansion._right_shutter.is_open and not expansion._room_four_shutter.is_open, "Later areas opened before cleaning")
	_expect(not manager.is_hammer_unlocked() and not manager.take_hammer(), "Hammer was available before 100%")
	_clean(manager, &"room_01", 96)
	manager._evaluate_room_completion()
	_expect(office.shutter.is_open and not room_two.shutter.is_open and not expansion._room_three_shutter.is_open, "Room 1 must open only right wing and office")
	_clean(manager, &"manager_office", 96)
	_clean(manager, &"left_corridor", 96)
	manager.state_changed.emit()
	_expect(room_two.shutter.is_open and expansion._room_three_shutter.is_open and not expansion._lobby_shutter.is_open, "Right wing and office did not open Rooms 2 and 3")
	_clean(manager, &"room_02", 96)
	_clean(manager, &"room_03", 96)
	manager.state_changed.emit()
	_expect(expansion._lobby_shutter.is_open and not expansion._right_shutter.is_open and not expansion._room_four_shutter.is_open, "Rooms 2 and 3 did not open only the vestibule")
	_clean(manager, &"lobby", 96)
	manager.state_changed.emit()
	_expect(expansion._right_shutter.is_open and expansion._room_four_shutter.is_open, "Clean vestibule did not open left wing and Room 4")
	_expect(not manager.is_hammer_unlocked(), "95% incorrectly unlocked hammer")
	for area in manager.HAMMER_REQUIRED_AREAS:
		_clean(manager, area, 100)
	manager.state_changed.emit()
	_expect(manager.is_hammer_unlocked() and pickup.get_interaction_prompt() == "[E] Coger maza", "100% did not unlock manager hammer")
	pickup.interact(main.get_node("Player"))
	await process_frame
	_expect(manager.hammer_taken and not pickup.visible and hammer._pivot.visible and hammer.is_cinematic_active(), "Hammer pickup cinematic did not start")
	_expect(hammer._grip_hand.visible, "The grip hand is hidden during pickup")
	var hud := main.get_node("GameplayHUD")
	_expect(not hud.is_gameplay_hud_visible() and not hud._coin_canvas.visible and main.get_node("Player")._cinematic_locked, "Pickup did not hide all HUD layers and lock movement")
	var menu := main.get_node("UpgradeMenu") as UpgradeMenu
	_expect(menu._is_hammer_cinematic_active(), "TAB menu did not recognize the pickup lock")
	var pause_menu := main.get_node("PauseMenu")
	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	pause_menu._input(pause_event)
	_expect(pause_menu.is_open() and paused, "ESC did not open pause during pickup cinematic")
	# The headless viewport keeps the first synthetic event marked handled;
	# resume through the same action as the pause menu's Continue button.
	pause_menu.toggle_pause()
	_expect(not pause_menu.is_open() and not paused, "Pause menu did not resume pickup cinematic")
	var tab_event := InputEventKey.new()
	tab_event.keycode = KEY_TAB
	tab_event.pressed = true
	menu._input(tab_event)
	_expect(not menu.is_open(), "TAB input opened the menu during pickup cinematic")
	menu.open_menu()
	_expect(not menu.is_open(), "TAB menu opened during pickup cinematic")
	await create_timer(2.0, true).timeout
	_expect(not hammer.is_cinematic_active() and hud.is_gameplay_hud_visible() and hud._coin_canvas.visible and not main.get_node("Player")._cinematic_locked, "Pickup did not restore HUD and control")
	var strike_positions := [Vector3(36.85, 0.75, 19.0), Vector3(36.85, 1.45, 21.0), Vector3(36.85, 1.85, 20.0)]
	for hit in 3:
		_expect(wall.hit_wall(strike_positions[hit]), "Brick wall rejected a valid hammer hit")
		_expect(manager.final_wall_damage == hit + 1 and not manager.final_wall_open, "Wall opened too early or did not save progressive damage")
	_expect(manager.final_wall_hit_points.size() == 3, "Impact positions were not recorded")
	_expect(not wall._brick_survives(1, -1.0, 3) and not wall._brick_survives(3, 1.0, 3) and wall._brick_survives(1, 2.6, 3), "Fracture did not follow the impact locations")
	var saved_hit_points := manager.final_wall_hit_points.duplicate()
	manager.final_wall_hit_points.clear()
	manager._load_progress()
	_expect(manager.final_wall_damage == 3 and manager.final_wall_hit_points == saved_hit_points, "Partial damage did not restore its impact positions from save")
	_expect(wall._fractured_visual.visible and not wall._authored_visual.visible, "Procedural fracture did not replace the intact face")
	_expect(wall._fractured_visual.multimesh.instance_count <= 105 and wall._debris.size() <= 24, "Fracture exceeded the brick/physics budget")
	var player := main.get_node("Player") as PlayerController
	player.global_position = Vector3(34.4, 0.15, 20.0)
	player.rotation.y = -PI * 0.5
	player.reset_camera_interpolation()
	await physics_frame
	var click := InputEventAction.new()
	click.action = &"primary_action"
	click.pressed = true
	# Headless SceneTree runs do not route synthetic input through the window.
	player._unhandled_input(click)
	_expect(hammer._swinging, "Primary action did not start the held hammer swing")
	await create_timer(0.20, true).timeout
	_expect(hammer._swing_audio.playing, "Approved wind sound did not play during the downswing")
	await create_timer(0.13, true).timeout
	_expect(manager.final_wall_open and manager.final_wall_damage == 4, "Click/swing did not hit and open the brick wall")
	_expect(hammer._stone_audio.playing and hammer._stone_audio.pitch_scale >= 0.97 and hammer._stone_audio.pitch_scale <= 1.03, "Approved stone hit did not play on wall impact")
	_expect(wall._debris.size() <= 42, "Collapse exceeded the transient rubble budget")
	_expect(main.get_node("Player")._cinematic_locked and not hud.is_gameplay_hud_visible() and not hud._coin_canvas.visible and not wall._fractured_visual.visible, "Collapse did not lock controls, hide HUD and clear the opening")
	_expect(hammer._grip_hand.visible, "The grip hand is hidden before placing the hammer")
	menu.open_menu()
	_expect(not menu.is_open(), "TAB menu opened during placement cinematic")
	await create_timer(2.5, true).timeout
	_expect(not main.get_node("Player")._cinematic_locked and hud.is_gameplay_hud_visible() and hud._coin_canvas.visible and hammer._mounted_hammer != null and not hammer._pivot.visible, "Hammer was not gently left on the adjacent wall after the animation")
	_expect(not hammer._grip_hand.visible, "The grip hand remained visible after releasing the hammer")
	_expect(player.global_position.distance_to(Vector3(35.20, player.global_position.y, 17.85)) < 0.25, "Player did not approach the side wall to leave the hammer")
	_expect(wall._debris.is_empty(), "Transient rubble was not removed")
	manager._save_progress()
	main.queue_free()
	await process_frame
	var restored := scene.instantiate()
	root.add_child(restored)
	await process_frame
	var restored_manager := restored.get_node("GameplayManager") as GameplayManager
	var restored_wall := restored.get_node("CinemaExpansionBlockout/FutureFinalRoomBrickBarrier")
	_expect(restored_manager.loaded_save and restored_manager.final_wall_open and restored_manager.hammer_taken, "Wall/hammer state did not survive save")
	_expect(restored_wall._collision.disabled and not restored_wall._authored_visual.visible, "Saved open passage was blocked on reload")
	_expect(restored.get_node("HammerController")._mounted_hammer != null, "Wall-mounted hammer was missing on reload")
	restored.queue_free()
	await process_frame
	var legacy_data := JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)) as Dictionary
	legacy_data["version"] = 12
	legacy_data["final_wall_damage"] = 3
	legacy_data["final_wall_open"] = false
	legacy_data.erase("final_wall_hit_points")
	var legacy_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy_data))
	legacy_file.close()
	var legacy_scene := scene.instantiate()
	root.add_child(legacy_scene)
	await process_frame
	var legacy_manager := legacy_scene.get_node("GameplayManager") as GameplayManager
	var legacy_wall := legacy_scene.get_node("CinemaExpansionBlockout/FutureFinalRoomBrickBarrier")
	_expect(legacy_manager.final_wall_damage == 3 and legacy_manager.final_wall_hit_points.size() == 3 and legacy_wall._fractured_visual.visible, "Version 12 partial wall progress did not migrate")
	legacy_scene.queue_free()
	await process_frame
	_remove_save()
	if failures.is_empty():
		print("HAMMER_PROGRESSION_SMOKE_OK")
		quit(0)
	else:
		print("HAMMER_PROGRESSION_SMOKE_FAILED: %s" % " | ".join(failures))
		quit(1)


func _clean(manager: GameplayManager, area: StringName, percent: int) -> void:
	var total := int(manager.room_trash_totals.get(String(area), 0))
	_expect(total > 0, "Missing trash budget for %s" % area)
	manager.room_trash_remaining[String(area)] = maxi(0, floori(float(total) * (100.0 - float(percent)) / 100.0))
	if area == &"room_01":
		manager.remaining_trash = manager.room_trash_remaining[String(area)]


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _remove_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
