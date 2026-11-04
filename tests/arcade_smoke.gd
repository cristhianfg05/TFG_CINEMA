extends SceneTree

const SAVE_PATH := "res://.godot/arcade_smoke_save.json"

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
	var manager = get_first_node_in_group("gameplay_manager")
	var player = get_first_node_in_group("player") as Node3D
	var arcade = get_first_node_in_group("arcade_minigame")
	var hud = main.get_node("GameplayHUD")
	var machine = main.find_child("FutureArcadeMachine", true, false)
	var second_machine = main.find_child("LeftCorridorArcade", true, false)
	_expect(manager != null and arcade != null and machine != null, "Arcade dependencies are missing")
	_expect(second_machine != null and machine.has_node("ObjectiveVisibility") and second_machine.has_node("ObjectiveVisibility"), "Both arcades need camera-discovery sensors")
	_expect(manager.get_total_collectible_count() == 14, "Collection was not expanded to fourteen slots")
	var intro = get_first_node_in_group("game_intro")
	if intro and intro.has_method("complete_immediately"):
		intro.complete_immediately()
	await process_frame
	manager.first_room_exit_seen = true
	_expect(_objective(manager, "arcade_found").is_empty() and _objective(manager, "arcade_second").is_empty(), "Arcade objectives appeared before the machines were seen")
	_expect(machine.get_interaction_prompt().is_empty(), "Arcade can be used from too far away")
	player.global_position = machine.global_position + Vector3(1.25, 0.1, 0.0)
	_expect(machine.get_interaction_prompt() == "[E] Jugar a Rescata el carrete", "Arcade prompt is not exact")
	var previous_mouse_mode := Input.mouse_mode
	_expect(arcade.open_arcade(machine), "Arcade did not open")
	if DisplayServer.get_name() != "headless":
		_expect(Input.mouse_mode == Input.MOUSE_MODE_HIDDEN, "First arcade did not hide the cursor")
	_expect(not bool(_objective(manager, "arcade_found").get("completed", true)), "Finding the first arcade must reveal, not complete, its objective")
	_expect(_objective(manager, "arcade_second").is_empty(), "The second arcade objective appeared before its machine was seen")
	_expect(arcade.is_open() and paused, "Arcade did not lock the world")
	arcade._mode = arcade.Mode.MENU
	arcade._start_run(0)
	_expect(arcade._duration() == 150.0 and arcade._required_repairs() == 36, "Normal arcade duration or quota is wrong")
	var starting_lives: int = arcade._integrity
	arcade._try_repair()
	_expect(arcade._integrity == starting_lives - 1, "An early repair must cost one life")
	arcade._defects.append({"lane": 1, "y": 143.0, "kind": 0, "bonus": false})
	arcade._try_repair()
	_expect(arcade._repairs == 1 and arcade._combo == 1 and arcade._score == 100, "A timed repair must restore a frame and start a combo")
	arcade._defects.append({"lane": 1, "y": 143.0, "kind": 0, "bonus": true})
	arcade._try_repair()
	_expect(arcade._repairs == 3 and arcade._integrity == starting_lives, "A bonus reel must give two frames and restore one life")
	arcade._defects.clear()
	arcade._defects.append({"lane": 1, "y": 100.0, "kind": 0, "bonus": false})
	arcade._stage_banner_time = 0.0
	arcade._spawn_elapsed = 0.0
	Input.action_press("move_backward")
	arcade._update_run(0.5)
	Input.action_release("move_backward")
	_expect(float(arcade._defects[0].y) < 100.0 + arcade._defect_speed() * 0.5 and arcade._focus < 100.0, "Holding S must slow the film and consume focus")
	arcade._repairs = 0
	arcade._elapsed = arcade._duration()
	arcade._update_run(0.01)
	_expect(arcade._mode == arcade.Mode.DEFEAT, "Surviving the timer without enough film must not award the poster")
	arcade._start_run(0)
	arcade._repairs = arcade._required_repairs()
	arcade._elapsed = arcade._duration()
	arcade._update_run(0.01)
	_expect(manager.is_collectible_found("arcade_reel_rescue_normal_poster"), "Normal arcade victory did not persist its poster")
	_expect(hud._objective_sound.playing and hud._objective_sound.process_mode == Node.PROCESS_MODE_ALWAYS and hud._objective_sound.stream.resource_path.ends_with("objective_piano_candidate_02.wav"), "Winning an arcade poster did not play the approved collectible piano during the paused minigame")
	_expect(not bool(_objective(manager, "arcade_found").get("completed", true)), "Normal arcade victory completed a Difficult objective")
	arcade._start_run(1)
	_expect(arcade._duration() == 180.0 and arcade._required_repairs() == 50, "Difficult arcade duration or quota is wrong")
	arcade._repairs = arcade._required_repairs()
	arcade._elapsed = arcade._duration()
	arcade._update_run(0.01)
	_expect(manager.is_collectible_found("arcade_reel_rescue_hard_poster"), "Hard arcade victory did not persist its poster")
	_expect(bool(_objective(manager, "arcade_found").get("completed", false)), "Difficult arcade victory did not complete the first objective")
	var muted_arcade_completion := false
	for objective_toast in hud._objective_queue:
		if String(objective_toast.get("title", "")) == "¿Tienen consolas?" and bool(objective_toast.get("mute_sound", false)):
			muted_arcade_completion = true
	_expect(muted_arcade_completion, "The arcade prize and objective toast would play the piano twice")
	arcade.close_arcade()
	_expect(not paused and not arcade.is_open(), "Arcade did not restore world pause state")
	if DisplayServer.get_name() != "headless":
		_expect(Input.mouse_mode == previous_mouse_mode, "First arcade did not restore the cursor mode")
	manager.mark_second_arcade_discovered()
	_expect(not bool(_objective(manager, "arcade_second").get("completed", true)), "Seeing the unimplemented second arcade must leave its objective pending")
	_expect(manager.collect_collectible("arcade_second_game_hard_poster"), "Reserved Difficult reward for the second arcade is unavailable")
	_expect(bool(_objective(manager, "arcade_second").get("completed", false)), "The second arcade objective is not wired to its future Difficult victory reward")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("ARCADE_SMOKE_OK")
		quit(0)
	else:
		print("ARCADE_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _objective(manager: Node, objective_id: String) -> Dictionary:
	for objective in manager.get_cinema_objectives():
		if String(objective.get("id", "")) == objective_id:
			return objective
	return {}
