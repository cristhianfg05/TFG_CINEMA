extends SceneTree

const SELECT_PATH := "res://assets/audio/sfx/arcade/arcade_menu_soft_pim_03.wav"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var reel := ArcadeReelRescue.new()
	var usher := ArcadeLastUsherSurvivor.new()
	root.add_child(reel)
	root.add_child(usher)
	await process_frame
	var ok := reel._select_audio.stream != null
	ok = ok and reel._select_audio.stream.resource_path == SELECT_PATH
	ok = ok and reel._select_audio.bus == "UI"
	ok = ok and is_equal_approx(reel._select_audio.volume_db, -10.0)
	ok = ok and usher._select_audio.stream != null
	ok = ok and usher._select_audio.stream.resource_path == SELECT_PATH
	ok = ok and usher._select_audio.bus == "UI"
	ok = ok and is_equal_approx(usher._select_audio.volume_db, -10.0)
	reel._select_audio.play()
	usher._select_audio.play()
	ok = ok and reel._select_audio.playing and usher._select_audio.playing
	reel._select_audio.stop()
	usher._select_audio.stop()
	var move := InputEventAction.new()
	move.action = "move_right"
	move.pressed = true
	move.strength = 1.0
	reel._mode = ArcadeReelRescue.Mode.MENU
	reel._menu_selection = 0
	Input.parse_input_event(move)
	await process_frame
	ok = ok and reel._menu_selection == 1 and reel._select_audio.playing
	reel._select_audio.stop()
	reel._mode = ArcadeReelRescue.Mode.DEFEAT
	reel._defeat_selection = 0
	Input.parse_input_event(move)
	await process_frame
	ok = ok and reel._defeat_selection == 1 and reel._select_audio.playing
	reel._select_audio.stop()
	reel._mode = ArcadeReelRescue.Mode.CLOSED
	usher._mode = ArcadeLastUsherSurvivor.Mode.MENU
	usher._menu_selection = 0
	Input.parse_input_event(move)
	await process_frame
	ok = ok and usher._menu_selection == 1 and usher._select_audio.playing
	usher._select_audio.stop()
	usher._mode = ArcadeLastUsherSurvivor.Mode.UPGRADE
	usher._upgrade_selection = 0
	Input.parse_input_event(move)
	await process_frame
	ok = ok and usher._upgrade_selection == 1 and usher._select_audio.playing
	usher._select_audio.stop()
	usher._mode = ArcadeLastUsherSurvivor.Mode.DEFEAT
	usher._defeat_selection = 0
	Input.parse_input_event(move)
	await process_frame
	ok = ok and usher._defeat_selection == 1 and usher._select_audio.playing
	usher._select_audio.stop()
	reel.queue_free()
	usher.queue_free()
	for frame in 3:
		await process_frame
	if ok:
		print("ARCADE_MENU_SOFT_PIM_BOTH_OK")
		quit(0)
	else:
		push_error("Both arcade menus must use the approved soft pim on UI")
		quit(1)
