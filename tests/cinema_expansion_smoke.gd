extends SceneTree

const SAVE_PATH := "res://.godot/cinema_expansion_smoke_save.json"
const REQUIRED := [&"room_01", &"left_corridor", &"manager_office", &"room_02", &"room_03"]
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
	await process_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	var expansion := main.get_node("CinemaExpansionBlockout") as CinemaExpansionBlockout
	var room3 := main.get_node("Room03Blockout") as CinemaNewAuditorium
	var room4 := main.get_node("Room04Blockout") as CinemaNewAuditorium
	var hud := main.get_node("GameplayHUD")
	_expect(manager != null and expansion != null and room3 != null and room4 != null, "Expansion nodes missing")
	_expect(manager.room_trash_totals.get("lobby", 0) == 555 and manager.room_trash_unit_totals.get("lobby", 0) == 590, "Combined entrance and vestibule trash totals are incorrect")
	_expect(manager.room_trash_totals.get("right_corridor", 0) == 90 and manager.room_trash_unit_totals.get("right_corridor", 0) == 100, "Physical left corridor trash totals are incorrect")
	_expect(manager.room_trash_totals.get("room_03", 0) == 440 and manager.room_trash_unit_totals.get("room_03", 0) == 470, "Room 3 trash totals are incorrect")
	_expect(manager.room_trash_totals.get("room_04", 0) == 660 and manager.room_trash_unit_totals.get("room_04", 0) == 680, "Room 4 trash totals are incorrect")
	_expect(not manager.lobby_unlocked and not expansion._lobby_shutter.is_open, "Lobby begins unlocked")
	_expect(not manager.right_corridor_unlocked and not expansion._right_shutter.is_open, "Left corridor begins unlocked")
	_expect(not expansion.get_node("LobbyMainEntranceShutter").is_open, "Unauthored exterior entrance must remain safely closed")
	_expect(room3.find_children("Room03Seat_*", "StaticBody3D", false, false).size() == 162, "Room 3 must match Room 2's three six-seat blocks over nine rows")
	_expect(room4.find_children("Room04Seat_*", "StaticBody3D", false, false).size() == 144, "Room 4 needs 18 rows with 4 + 4 seats")
	_expect(room4.find_children("AisleSlope_*", "StaticBody3D", false, false).size() == 3, "Room 4 needs three aisles")
	_expect(room4.find_children("EntranceRamp_*", "StaticBody3D", false, false).size() == 3, "Room 4 entrance ramps missing")
	_expect(room4.find_children("EntranceStep_*", "Node3D", false, false).size() == 15, "Room 4 needs five step visuals per aisle")
	_expect(room3.find_children("EntranceStep_*", "Node3D", false, false).size() == 12 and room3.find_children("EntranceStepLight_*", "Node3D", false, false).size() == 12, "Room 3 must copy Room 2's three lit steps per aisle")
	_expect(room3.find_children("WallGrille_*", "Node3D", false, false).size() == 12 and room3.find_children("WallLightA_*", "Node3D", false, false).size() == 12 and room3.find_children("WallLightB_*", "Node3D", false, false).size() == 12, "Room 3 side bays need grilles and two lights like Room 2")
	var room1 := main.get_node("Room01Blockout")
	var room2 := main.get_node("Room02Blockout")
	_expect(room1.find_children("WallGlowA_*", "OmniLight3D", false, false).size() == 12 and room2.find_children("Room02WallGlowA_*", "OmniLight3D", false, false).size() == 12, "Rooms 1/2 must light each horizontal lamp")
	_expect(room3.find_children("WallGlowA_*", "OmniLight3D", false, false).size() == 12 and room4.find_children("WallGlowA_*", "OmniLight3D", false, false).size() == 20, "Rooms 3/4 must light each horizontal lamp")
	var room2_step := room2.get_node("Room02RearAccess_00_00") as Node3D
	_expect(is_equal_approx((room2_step.get_child(0) as MeshInstance3D).mesh.size.x, 1.42), "Room 2 side stair is still narrower than its aisle")
	_expect(room3._carpet.resource_path.ends_with("room_03_action_carpet.tres") and room4._carpet.resource_path.ends_with("room_04_fear_carpet.tres"), "Action and fear floors are not assigned to Rooms 3/4")
	_expect(is_equal_approx(room3._width, 27.25) and absf(room3._center_x - room3._width * 0.5 - (room3._center_x + room3._aisle_offsets[0] - 0.6)) < 0.15, "Room 3 outer aisle still leaves a large strip before the wall")
	_expect(room4.find_children("FearBats_*", "Node3D", false, false).size() == 12 and room4.find_children("FearSkull_*", "Node3D", false, false).size() == 6, "Room 4 fear decorations missing")
	_expect(room4.find_children("FearCobweb_*", "Node3D", false, false).size() == 4 and room4.find_children("FearTornCurtain_*", "Node3D", false, false).size() == 2, "Room 4 screen or corners lack fear decorations")
	_expect(room3.find_children("ActionStar_*", "Node3D", false, false).size() == 8 and room4.has_node("FearWitchSignLeftOfDoor"), "Action stars or witch sign missing")
	_expect(room3.has_node("EntryDoorInteriorFrameTop") and room4.has_node("EntryDoorInteriorFrameTop"), "Rooms 3/4 need interior black doorway trim")
	_expect(main.get_node("Room02Blockout").has_node("Room02EntryDoorInteriorFrameTop") and main.get_node("Room01Blockout").has_node("Room01DoorInteriorFrameTop"), "Rooms 1/2 need interior black doorway trim")
	_expect((main.get_node("Player/Head/Camera3D") as Camera3D).far >= 75.0, "Room 4 screen is clipped from the entrance")
	var room3_aisle_widths := [1.2, 1.5, 1.5, 1.2]
	for aisle_index in room3_aisle_widths.size():
		var step := room3.get_node("EntranceStep_%02d_00" % aisle_index) as Node3D
		var slope := room3.get_node("EntranceRamp_%02d" % aisle_index) as Node3D
		var width: float = room3_aisle_widths[aisle_index]
		_expect(is_equal_approx((step.get_child(0) as MeshInstance3D).mesh.size.x, width) and is_equal_approx((slope.get_child(1) as MeshInstance3D).mesh.size.x, width), "Room 3 step and walking slope leave an aisle-width gap")
		var aisle_x: float = room3._center_x + room3._aisle_offsets[aisle_index]
		var last_ground := -1.0
		for z in [30.6, 31.4, 32.2]:
			var ground_query := PhysicsRayQueryParameters3D.create(Vector3(aisle_x, 3.0, z), Vector3(aisle_x, -1.0, z), 1)
			var ground_hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(ground_query)
			_expect(not ground_hit.is_empty(), "Room 3 entrance aisle has a collision gap")
			if not ground_hit.is_empty():
				var ground_y: float = ground_hit.position.y
				_expect(ground_y > last_ground + 0.1, "Room 3 entrance ramp does not climb toward the seats")
				last_ground = ground_y
	_expect(is_equal_approx(room3.get_node("EntranceStep_00_00").position.z, 30.88) and is_equal_approx(room3.get_node("EntranceStep_00_02").position.z, 32.58), "Room 3 steps do not match Room 2's landing")
	var floating_lamp := false
	for fixture in main.get_node("LeftWingBlockout").get_children():
		if fixture is MeshInstance3D and fixture.name.begins_with("WarmWallLight") and is_equal_approx(fixture.position.x, -8.0):
			floating_lamp = true
	_expect(not floating_lamp, "The floating wall lamp still crosses Room 3's doorway")
	_expect(room3.get_node_or_null("Screen") != null and room4.get_node_or_null("Screen") != null, "Screens missing")
	_expect(main.get_node("CinemaMovieSystem/Room03Movie")._surface != null and main.get_node("CinemaMovieSystem/Room04Movie")._surface != null, "Movie controllers have no display surfaces")
	_expect(main.get_node("CinemaRoomAudioSystem/Room03Audio")._static_players.size() == 2 and main.get_node("CinemaRoomAudioSystem/Room04Audio")._static_players.size() == 2, "New rooms need two working 3D audio sources")
	_expect(expansion.get_node_or_null("FutureFinalRoomBrickBarrier") != null, "Blender brick barrier is missing")
	_expect(is_equal_approx(room3._min_z, 25.0) and is_equal_approx(room3._max_z, 57.0) and room3._center_x - room3._width * 0.5 < -19.0, "Room 3 must start at the original corridor and extend beyond Manager")
	_expect(room3._center_x + room3._width * 0.5 < 7.5, "Room 3 must leave a gap to unchanged Room 2")
	_expect(room4.global_position.is_equal_approx(Vector3(71.9, 0.0, 24.0)) and is_equal_approx(room4._max_z + room4.global_position.z, 15.0), "Room 4 is not rectangular and directly below the left corridor")
	_expect(main.get_node("LeftWingBlockout/CorridorFloor").position.is_equal_approx(Vector3(-0.5, -0.1, 20.0)), "Original right corridor footprint changed")
	_expect(main.get_node("LeftWingBlockout/OfficeFloor").position.is_equal_approx(Vector3(-15.5, -0.1, 20.0)), "Manager must fill the right end of the corridor")
	_expect(expansion.get_node("LobbyFloor").position.is_equal_approx(Vector3(14.95, -0.1, 5.0)), "Vestibule west edge still clips Room 1")
	_expect(expansion.get_node("LobbyRoom01SideLower_00").position.x - 0.12 > 11.24, "Vestibule side wall still intersects Room 1")
	_expect(expansion.get_node("LeftCorridorFloor").position.is_equal_approx(Vector3(27.7, -0.1, 20.0)), "Left corridor must be a straight strip opposite Manager")
	_expect(not expansion.has_node("LeftCorridorBranchFloor") and not expansion.has_node("LobbyRoom01SideFloor"), "Old L-shaped map geometry remains")
	_expect(is_equal_approx(expansion._lobby_shutter.position.z, 18.5) and is_equal_approx(expansion._right_shutter.position.z, 18.5), "The two vestibule shutters must be opposite at the same height")
	_expect(is_equal_approx(expansion._lobby_shutter.opening_width, 3.0) and is_equal_approx(expansion._right_shutter.opening_width, 3.0), "Vestibule door widths do not match")
	_expect(expansion.get_node("FutureFinalRoomBrickBarrier").position.is_equal_approx(Vector3(36.85, 0.0, 20.0)), "Final-room wall must be opposite Manager beyond the left corridor")
	_expect(expansion.has_node("FinalBarrierUpper") and expansion.has_node("FinalWallSouthUpper") and expansion.has_node("FinalWallNorthUpper"), "Final wall does not reach the other wall heights")
	_expect(expansion.get_node("LeftCorridorArcade").position.is_equal_approx(Vector3(21.5, 0.0, 24.05)) and main.get_node("LeftWingBlockout/FutureArcadeMachine").position.x < -10.0, "Blue arcade markers are not in both corridors")
	var corridor_bin := expansion.get_node("LeftCorridorTrashBin") as StaticBody3D
	_expect(corridor_bin.position.is_equal_approx(Vector3(23.4, 0.0, 23.85)) and corridor_bin.get("room_id") == &"right_corridor" and not expansion.has_node("LobbyTrashBin"), "The vestibule bin is not beside the left-wing arcade")
	_expect(bool(corridor_bin.call("is_position_in_acceptance_arc", Vector3(23.4, 1.0, 22.4))), "The moved bin cannot accept a sack from the corridor")
	_expect(is_equal_approx(room3.get_node("Room03EntryPosterFrame").position.z, 24.60) and is_equal_approx(room4.get_node("Room04EntryPosterFrame").global_position.x, 30.9), "The Room 3 poster must sit against its wall and the Room 4 poster must follow its entrance")
	_expect(room3.has_node("EntryWestWingBase_00") and room3.has_node("EntryDoorHeader") and room3.has_node("EntryDoorFrameTop"), "Room 3 entrance lacks a floor base, white header or doorway border")
	_expect(expansion.has_node("LobbyRightGateTop") and expansion.has_node("LobbyLeftGateTop") and expansion.has_node("LobbyEntranceTop"), "Vestibule shutters lack the new doorway borders")
	_expect(main.get_node("Room02Blockout").find_children("Room02HeartLight_*", "Node3D", false, false).is_empty(), "Floor heart lights remain in Room 2")
	_expect(hud.get_node_or_null("HUDRoot/ObjectiveToast") != null, "Objective toast is missing")
	# Every required area individually at 94% must keep the double shutter shut.
	for candidate in REQUIRED:
		for area in REQUIRED:
			var total := int(manager.room_trash_totals[String(area)])
			manager.room_trash_remaining[String(area)] = floori(total * 0.05)
		var candidate_total := int(manager.room_trash_totals[String(candidate)])
		manager.room_trash_remaining[String(candidate)] = ceili(candidate_total * 0.06)
		manager.state_changed.emit()
		_expect(not manager.lobby_unlocked, "Lobby opened with %s below 95%%" % candidate)
	for area in REQUIRED:
		var total := int(manager.room_trash_totals[String(area)])
		manager.room_trash_remaining[String(area)] = floori(total * 0.05)
	manager.state_changed.emit()
	_expect(manager.lobby_unlocked and expansion._lobby_shutter.is_open, "Five areas at 95% did not open lobby")
	manager.first_room_exit_seen = true
	_expect(_has_objective(manager.get_cinema_objectives(), "Limpia el vestíbulo"), "Lobby cleaning objective missing")
	manager.room_trash_remaining["lobby"] = 34
	manager.state_changed.emit()
	_expect(not manager.right_corridor_unlocked, "Left corridor opened with lobby at 94%")
	manager.room_trash_remaining["lobby"] = 27
	manager.state_changed.emit()
	_expect(manager.right_corridor_unlocked and expansion._right_shutter.is_open, "Lobby at 95% did not open left corridor")
	_expect(_has_objective(manager.get_cinema_objectives(), "Limpia la Sala 4"), "Room 4 objective missing")
	_expect(hud._objective_panel.visible and hud._objective_toast_kind == &"new", "New objective toast did not appear")
	_expect(not hud._objective_slot.visible and hud._objective_tab_hint.visible, "New objective toast must not show a stamp")
	_expect(hud._objective_sound.stream != null and hud._objective_sound.stream.resource_path.ends_with("objective_piano_candidate_02.wav"), "Approved objective piano 02 is not integrated")
	_expect(hud._objective_new_sound.stream != null and hud._objective_new_sound.stream.resource_path.ends_with("objective_new_question_candidate_03.wav"), "Approved new-objective piano 03 is not integrated")
	_expect(hud._objective_new_sound.bus == &"UI" and hud._objective_sound.bus == &"UI", "Objective sounds must use the UI bus")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	main.get_node("UpgradeMenu")._input(tab)
	_expect(main.get_node("UpgradeMenu").is_open() and main.get_node("UpgradeMenu")._section == &"objectives", "Tab during new objective toast must open objectives")
	_expect(not hud._objective_panel.visible, "New objective toast should dismiss when Tab opens the menu")
	main.get_node("UpgradeMenu").close_menu()
	hud._objective_queue.clear() # Other newly revealed objectives are independently queued.
	manager.room_completed = true
	manager.state_changed.emit()
	_expect(hud._objective_toast_kind == &"completed" and hud._objective_slot.visible, "Completion toast must display its stamp slot")
	await create_timer(1.2).timeout
	_expect(hud._objective_stamp.position.y > -5.0, "Objective stamp did not fall into its slot")
	var seat3 := room3.get_node("Room03Seat_01_01/CinemaSeatInteraction") as CinemaSeatInteractable
	var seat4 := room4.get_node("Room04Seat_01_01/CinemaSeatInteraction") as CinemaSeatInteractable
	_expect(seat3.collision_layer == 0 and seat4.collision_layer == 0, "New seats activate before cleaning and lever")
	for id in [&"room_03", &"room_04"]:
		manager.room_trash_remaining[String(id)] = 0
	manager.state_changed.emit()
	var room3_player := main.get_node("Player") as PlayerController
	room3_player.global_position = Vector3(-9.4, 1.0, 40.0)
	room3_player.set_current_room_id(&"room_03")
	_expect(main.get_node("CinemaRoomAudioSystem/Room03Audio/Static_01").volume_db > -30.0, "Room 3 interference must be audible before its lever is activated")
	var lever_box := main.get_node("LeftWingBlockout/ManagerLeverBox")
	lever_box.get_node("Room03Lever").interact(main.get_node("Player"))
	await create_timer(0.5).timeout
	lever_box.get_node("Room04Lever").interact(main.get_node("Player"))
	await create_timer(0.5).timeout
	_expect(manager.is_room_activated(&"room_03") and manager.is_room_activated(&"room_04"), "Manager's levers 3/4 cannot activate the new rooms")
	_expect(seat3.collision_layer == 2 and seat4.collision_layer == 2, "Seats did not activate with movie")
	for frame in 90:
		await physics_frame
	_expect(main.get_node("CinemaRoomAudioSystem/Room03Audio/Static_01").volume_db <= -75.0, "Room 3 static did not fade out after lever activation")
	_expect(_passage_clear(main, Vector3(9.0, 1.55, 18.5), Vector3(13.0, 1.55, 18.5)), "Right-corridor to vestibule shutter is obstructed")
	_expect(_passage_clear(main, Vector3(16.5, 1.55, 18.5), Vector3(20.5, 1.55, 18.5)), "Vestibule to left-corridor shutter is obstructed")
	_expect(_passage_clear(main, Vector3(-8.0, 1.55, 23.0), Vector3(-8.0, 1.55, 27.0)), "Room 3 doorway is obstructed")
	_expect(_passage_clear(main, Vector3(27.9, 1.55, 17.0), Vector3(27.9, 1.55, 13.0)), "Room 4 doorway is obstructed")
	_expect(not _passage_clear(main, Vector3(35.0, 1.55, 20.0), Vector3(38.5, 1.55, 20.0)), "Final-room brick barrier no longer blocks the reserved room")
	_expect(not _passage_clear(main, Vector3(-15.5, 0.6, 23.5), Vector3(-15.5, -0.6, 23.5)), "Manager floor still has a fall-through hole")
	main.get_node("GameIntro").complete_immediately()
	var player := main.get_node("Player") as PlayerController
	player.global_position = Vector3(seat3.aisle_x, seat3.seat_body.global_position.y + 0.1, seat3.seat_body.global_position.z + 0.8)
	var room3_entry := player.global_position
	_expect(player.sit_in_cinema_seat(seat3), "Player could not sit in a clean, activated Room 3 seat")
	await create_timer(0.7).timeout
	_expect(player.is_sitting() and not player.is_seat_transitioning(), "Sit-down camera transition did not finish")
	var seated_position := player.global_position
	var exit_position := player._find_safe_seat_exit(seat3)
	_expect(Vector2(exit_position.x, exit_position.z).distance_to(Vector2(room3_entry.x, room3_entry.z)) < 0.15, "Room 3 stand-up target is not the row used to select the seat")
	_expect(player.stand_up_from_cinema_seat(), "Player could not start standing up")
	_expect(player.is_sitting() and player.collision_layer == 0, "Seat released the player before the stand-up animation")
	await create_timer(0.22).timeout
	_expect(player.is_sitting() and player.global_position.distance_to(seated_position) > 0.05 and player.global_position.distance_to(exit_position) > 0.05, "Standing up still teleports instead of animating")
	_expect(player.head.position.y > 1.18 and player.head.position.y < player.standing_eye_height, "Eye height does not rise smoothly")
	await create_timer(0.5).timeout
	var exit_offset := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(exit_position.x, exit_position.z))
	_expect(not player.is_sitting() and player.collision_layer == 1 and exit_offset < 0.1, "Standing up did not finish at a safe exit (sitting=%s, layer=%s, horizontal offset=%.3f)" % [player.is_sitting(), player.collision_layer, exit_offset])
	player.global_position = Vector3(seat4.aisle_x, seat4.seat_body.global_position.y + 0.1, seat4.seat_body.global_position.z - 0.8)
	var room4_entry := player.global_position
	_expect(seat4.can_be_selected_from(player) and player.sit_in_cinema_seat(seat4), "Player could not select a Room 4 seat from its own aisle")
	await create_timer(0.7).timeout
	var room4_exit := player._find_safe_seat_exit(seat4)
	_expect(Vector2(room4_exit.x, room4_exit.z).distance_to(Vector2(room4_entry.x, room4_entry.z)) < 0.15, "Room 4 stand-up target is not the row used to select the seat")
	_expect(player.stand_up_from_cinema_seat(), "Player could not stand from Room 4")
	await create_timer(0.7).timeout
	_expect(not player.is_sitting() and Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(room4_entry.x, room4_entry.z)) < 0.15, "Room 4 stand-up moved the player to another row")
	expansion.get_node("LeftCorridorZone")._on_body_entered(player)
	_expect(player.get_current_room_id() == &"right_corridor" and hud._room_title.text == "PASILLO — ALA IZQUIERDA", "New left corridor HUD title does not match its physical side")
	await create_timer(1.0).timeout
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("CINEMA_EXPANSION_SMOKE_OK")
		quit(0)
	else:
		print("CINEMA_EXPANSION_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _has_objective(objectives: Array[Dictionary], title: String) -> bool:
	for objective in objectives:
		if String(objective.title) == title:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _passage_clear(main: Node3D, start: Vector3, finish: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(start, finish, 1)
	return main.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
