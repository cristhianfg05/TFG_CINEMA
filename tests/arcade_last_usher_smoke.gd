extends SceneTree

const SAVE_PATH := "res://.godot/arcade_last_usher_smoke_save.json"
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
	main.get_node("GameIntro").complete_immediately()
	var manager := main.get_node("GameplayManager") as GameplayManager
	manager.first_room_exit_seen = true
	var player := main.get_node("Player") as PlayerController
	var machine := main.get_node("CinemaExpansionBlockout/LeftCorridorArcade") as ArcadeMachine
	var arcade := main.get_node("ArcadeLastUsher") as ArcadeLastUsherSurvivor
	_expect(machine != null and arcade != null, "Second cabinet does not use the survivor game")
	var music_stream := arcade._music.stream as AudioStreamWAV
	_expect(music_stream != null and music_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Approved arcade music is not looping")
	_expect(arcade._shot_audio.stream != null and arcade._orbit_audio.stream != null and arcade._tape_audio.stream != null and arcade._heart_audio.stream != null, "Approved arcade effects are missing")
	_expect(arcade._music.bus == "Machines" and arcade._orbit_audio.bus == "Machines", "Arcade audio uses the wrong bus")
	_expect(machine.has_node("ObjectiveVisibility") and machine.get_node("ObjectiveVisibility").arcade_index == 2, "Second cabinet discovery sensor is wrong")
	player.global_position = machine.global_position + Vector3(1.0, 0.0, 0.0)
	_expect(machine.get_interaction_prompt() == "[E] Jugar a El último acomodador", "Cabinet interaction prompt changed")
	var previous_mouse_mode := Input.mouse_mode
	machine.interact(player)
	_expect(arcade.is_open() and paused, "Cabinet did not pause the world")
	if DisplayServer.get_name() != "headless":
		_expect(Input.mouse_mode == Input.MOUSE_MODE_HIDDEN, "Second arcade did not hide the cursor")
	_expect(manager.second_arcade_discovered, "Cabinet did not reveal its objective")
	arcade._start_run(0)
	_expect(arcade._stage == 0 and arcade._enemies.is_empty() and arcade._lives == 5, "Enemies must be absent during the act card")
	arcade._banner_time = 0.01
	arcade._update_game(0.02)
	_expect(arcade._enemies.size() == 6, "Opening enemies did not appear after the act card")
	_expect(arcade._world_to_screen(arcade._player_pos) == ArcadeLastUsherSurvivor.CAMERA_CENTER, "Camera is not centered on player")
	var before := arcade._player_pos
	Input.action_press("move_right")
	Input.action_press("move_forward")
	arcade._move_player(0.1)
	Input.action_release("move_right")
	Input.action_release("move_forward")
	_expect(arcade._player_pos.x > before.x and arcade._player_pos.y < before.y, "Diagonal movement is not continuous")
	_expect(arcade._player_pos.distance_to(before) < 9.0, "Diagonal movement is faster than straight movement")
	arcade._player_pos = Vector2(500, 500)
	_expect(arcade._world_to_screen(arcade._player_pos) == ArcadeLastUsherSurvivor.CAMERA_CENTER, "Open-world camera stopped following the player")
	arcade._player_pos = Vector2(192, 135)
	arcade._facing = Vector2.UP
	arcade._enemies = [{"pos": Vector2(192, 110), "kind": ArcadeLastUsherSurvivor.EnemyKind.SHADOW, "hp": 4, "stun": 0.0, "hit_flash": 0.0, "phase": 0.0, "orbit_cooldown": 0.0}]
	arcade._fire_cooldown = 0.0
	arcade._auto_attack()
	_expect(arcade._shots.size() == 1, "Nearest-enemy auto fire did not shoot")
	_expect(arcade._shot_audio.playing, "Auto fire did not play the approved shot sound")
	arcade._update_shots(0.10)
	_expect(int(arcade._enemies[0]["hp"]) == 3, "Auto shot did not damage the target")
	_expect(float(arcade._enemies[0]["hit_flash"]) > 0.0 and not arcade._damage_numbers.is_empty(), "Shot lacks enemy impact feedback")
	arcade._damage_enemy(0, 3)
	_expect(arcade._enemies.is_empty() and arcade._death_effects.size() == 1, "Defeated enemy did not start fading out")
	arcade._update_death_effects(0.15)
	_expect(float(arcade._death_effects[0]["life"]) < 0.28, "Enemy death fade did not advance")
	arcade._update_death_effects(0.15)
	_expect(arcade._death_effects.is_empty(), "Enemy death fade did not finish")
	arcade._orbital_branch = 1
	arcade._animation = 0.0
	arcade._enemies = [{"pos": arcade._player_pos + Vector2(22, 0), "kind": ArcadeLastUsherSurvivor.EnemyKind.SHADOW, "hp": 2, "stun": 0.0, "hit_flash": 0.0, "phase": 0.0, "orbit_cooldown": 0.0}]
	arcade._update_orbit(0.1)
	_expect(int(arcade._enemies[0]["hp"]) == 1, "Unlocked orbital reel did not hit")
	_expect(arcade._orbit_audio_cooldown > 0.0 and arcade._orbit_audio.playing, "Orbital impact did not play its sound")
	arcade._dash_cooldown = 0.0
	arcade._facing = Vector2.RIGHT
	before = arcade._player_pos
	arcade._dash()
	_expect(arcade._dash_time == 0.0, "Dash should be locked before survival upgrade")
	arcade._survival_branch = 3
	arcade._dash()
	arcade._move_player(0.1)
	_expect(arcade._dash_cooldown > 0.0 and arcade._player_pos.x > before.x + 20.0, "Dash is not fluid")
	arcade._xp = arcade._xp_goal - 1
	arcade._collect_pickup("film")
	_expect(arcade._mode == ArcadeLastUsherSurvivor.Mode.UPGRADE and arcade._level == 2, "Completing a film did not offer an upgrade")
	_expect(arcade._tape_audio.playing and arcade._tape_audio_cooldown > 0.0, "Film pickup did not play the tape sound")
	arcade._upgrade_selection = 0
	arcade._apply_upgrade()
	_expect(arcade._mode == ArcadeLastUsherSurvivor.Mode.PLAYING and arcade._shot_branch == 1 and arcade._stage == 0, "Shot upgrade did not resume the same act")
	arcade._lives = 3
	arcade._collect_pickup("heart")
	_expect(arcade._lives == 4 and arcade._heart_audio.playing, "Heart pickup did not play the heart sound")
	arcade._shot_branch = 3
	arcade._shots.clear()
	arcade._enemies = [{"pos": arcade._player_pos + Vector2(0, -30), "kind": ArcadeLastUsherSurvivor.EnemyKind.SHADOW, "hp": 10, "stun": 0.0, "hit_flash": 0.0, "phase": 0.0, "orbit_cooldown": 0.0}]
	arcade._auto_attack()
	_expect(arcade._shots.size() == 2, "Third shot upgrade did not unlock double fire")
	arcade._shot_branch = 4
	arcade._shots.clear()
	arcade._auto_attack()
	_expect(arcade._shots.size() == 4, "Fourth shot upgrade did not unlock quadruple fire")
	arcade._enemies[0]["pos"] = arcade._player_pos + Vector2(0, -140)
	arcade._shots.clear()
	arcade._auto_attack()
	for frame in 80:
		arcade._update_shots(0.01)
	_expect(int(arcade._enemies[0]["hp"]) < 10, "Quadruple volley missed a distant aimed target")
	arcade._shot_branch = 5
	arcade._shots.clear()
	arcade._auto_attack()
	_expect(float(arcade._shots[0]["size"]) > 1.0, "Evolved bullet size was not applied")
	_expect(arcade._available_branches() == [1], "Completed branches should disappear from upgrade choices")
	arcade._upgrade_selection = 0
	arcade._step_upgrade(1)
	_expect(arcade._upgrade_selection == 1, "Upgrade navigation did not skip completed branches")
	arcade._enemies.clear()
	arcade._spawn_enemy(ArcadeLastUsherSurvivor.EnemyKind.SHADOW)
	var surviving_enemy: Dictionary = arcade._enemies[0]
	surviving_enemy["pos"] = arcade._player_pos + Vector2(70, 0)
	arcade._enemies[0] = surviving_enemy
	arcade._banner_time = 0.0
	arcade._stage_time_left = 0.01
	arcade._update_game(0.02)
	_expect(arcade._stage == 1 and arcade._mode == ArcadeLastUsherSurvivor.Mode.PLAYING and arcade._shot_branch == 5, "Act progression reset upgrades or added an extra card")
	_expect(arcade._enemies.size() == 1 and not arcade._opening_wave_pending, "Act transition erased the surviving enemy")
	arcade._banner_time = 0.01
	arcade._update_game(0.02)
	_expect(arcade._stage_elapsed > 0.0 and arcade._enemies.size() >= 1, "Next act paused or erased its enemies")
	arcade._orbital_branch = 5
	arcade._xp = arcade._xp_goal - 1
	arcade._collect_pickup("film")
	_expect(arcade._mode == ArcadeLastUsherSurvivor.Mode.PLAYING and arcade._available_branches().is_empty(), "Full upgrade tree still opens a card menu")
	arcade._stage = 3
	arcade._start_stage()
	arcade._spawn_boss()
	_expect(arcade._boss_alive(), "Final act did not spawn the boss")
	arcade._boss_attack_cooldown = 0.0
	arcade._update_boss_attack(0.02)
	_expect(arcade._boss_warning > 0.0 and arcade._laser_zones.is_empty(), "Boss attack is not telegraphed")
	arcade._update_boss_attack(0.8)
	_expect(not arcade._laser_zones.is_empty(), "Boss did not mark laser zones after the warning")
	for index in range(arcade._enemies.size() - 1, -1, -1):
		if int(arcade._enemies[index]["kind"]) == ArcadeLastUsherSurvivor.EnemyKind.BOSS:
			arcade._damage_enemy(index, 100)
			break
	_expect(arcade._mode == ArcadeLastUsherSurvivor.Mode.VICTORY and manager.is_collectible_found(ArcadeLastUsherSurvivor.NORMAL_POSTER_ID), "Normal victory did not grant its poster")
	_expect(not _objective_completed(manager, "arcade_second"), "Normal victory completed the Difficult objective")
	arcade._start_run(1)
	arcade._banner_time = 0.01
	arcade._update_game(0.02)
	_expect(arcade._lives == 4 and arcade._enemies.size() >= 8, "Difficult mode does not start harder")
	arcade._stage = 3
	arcade._start_stage()
	arcade._spawn_boss()
	for index in range(arcade._enemies.size() - 1, -1, -1):
		if int(arcade._enemies[index]["kind"]) == ArcadeLastUsherSurvivor.EnemyKind.BOSS:
			arcade._damage_enemy(index, 100)
			break
	_expect(manager.is_collectible_found(ArcadeLastUsherSurvivor.HARD_POSTER_ID) and _objective_completed(manager, "arcade_second"), "Difficult victory did not grant its poster and objective")
	arcade.close_arcade()
	_expect(not arcade.is_open() and not paused, "Cabinet did not restore the world")
	_expect(not arcade._music.playing and not arcade._shot_audio.playing and not arcade._tape_audio.playing, "Arcade audio continued after closing")
	if DisplayServer.get_name() != "headless":
		_expect(Input.mouse_mode == previous_mouse_mode, "Second arcade did not restore the cursor mode")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("ARCADE_LAST_USHER_SMOKE_OK")
		quit(0)
	else:
		print("ARCADE_LAST_USHER_SMOKE_FAILED: ", ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _objective_completed(manager: GameplayManager, objective_id: String) -> bool:
	for objective in manager.get_cinema_objectives():
		if String(objective.get("id", "")) == objective_id:
			return bool(objective.get("completed", false))
	return false
