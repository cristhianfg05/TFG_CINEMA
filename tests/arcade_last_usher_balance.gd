extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arcade := ArcadeLastUsherSurvivor.new()
	root.add_child(arcade)
	await process_frame
	# This is a logic stress test; do not leave one-shot playback channels open at quit.
	arcade._pickup_audio.stream = null
	arcade._hit_audio.stream = null
	arcade._shot_audio.stream = null
	arcade._orbit_audio.stream = null
	arcade._tape_audio.stream = null
	arcade._heart_audio.stream = null
	var total_normal := 0.0
	var total_hard := 0.0
	for difficulty in 2:
		arcade._start_run(difficulty)
		for stage in 4:
			arcade._stage = stage
			arcade._start_stage()
			var expected_duration: float = (ArcadeLastUsherSurvivor.NORMAL_DURATIONS if difficulty == 0 else ArcadeLastUsherSurvivor.HARD_DURATIONS)[stage]
			_expect(is_equal_approx(arcade._stage_time_left, expected_duration), "Wrong stage duration")
			_expect(arcade._enemies.is_empty() and arcade._opening_wave_pending, "Act card did not clear the previous enemy wave")
			arcade._banner_time = 0.01
			arcade._update_game(0.02)
			_expect(arcade._enemies.size() >= 6 + stage * 2 + difficulty * 2, "Opening wave lost enemies")
			_expect(arcade._enemies.size() <= (6 + stage * 2 + difficulty * 2) * 3, "Opening packs exceeded budget")
			if difficulty == 0:
				total_normal += expected_duration
			else:
				total_hard += expected_duration
			for sample in 64:
				arcade._spawn_enemy(sample % 3)
				var enemy: Dictionary = arcade._enemies.back()
				var position := Vector2(enemy["pos"])
				_expect(position.distance_to(arcade._player_pos) >= ArcadeLastUsherSurvivor.SPAWN_DISTANCE.x and not ArcadeLastUsherSurvivor.ARENA.has_point(arcade._world_to_screen(position)), "Enemy must spawn outside the camera")
			arcade._enemies.clear()
			_expect(arcade._spawn_target() >= 14 and arcade._spawn_target() <= 46, "Spawn population target is outside budget")
			_expect(arcade._spawn_interval() >= 0.27 and arcade._spawn_interval() <= 0.72, "Spawn interval is outside budget")
		_expect(arcade._enemy_speed(ArcadeLastUsherSurvivor.EnemyKind.SPRINTER) < 82.0, "Sprinter outruns the player in a straight line")
		arcade._start_run(difficulty)
		arcade._banner_time = 0.0
		arcade._invulnerable = 999.0
		for frame in 1000:
			arcade._update_game(0.05)
			if arcade._mode == ArcadeLastUsherSurvivor.Mode.UPGRADE:
				arcade._upgrade_selection = 0 if arcade._shot_branch < 5 else (1 if arcade._orbital_branch < 5 else 2)
				arcade._apply_upgrade()
		_expect(arcade._mode == ArcadeLastUsherSurvivor.Mode.PLAYING, "Stress run ended too early")
		_expect(arcade._score > 0, "Auto fire did not score during stress run")
		_expect(arcade._enemies.size() <= arcade._spawn_target(), "Enemy cap was exceeded")
		_expect(arcade._score >= 0, "Invalid score after stress run")
	_expect(total_normal >= 300.0 and total_normal <= 360.0, "Normal run is outside the five-minute target")
	_expect(total_hard > total_normal, "Difficult run is not longer")
	arcade._start_run(0)
	var early_speed := arcade._enemy_speed(ArcadeLastUsherSurvivor.EnemyKind.SPRINTER)
	arcade._spawn_enemy(ArcadeLastUsherSurvivor.EnemyKind.SHADOW)
	var early_hp := int(arcade._enemies.back()["hp"])
	arcade._run_elapsed = 160.0
	arcade._spawn_enemy(ArcadeLastUsherSurvivor.EnemyKind.SHADOW)
	_expect(int(arcade._enemies.back()["hp"]) == early_hp + 2, "Enemy health did not strengthen over elapsed run time")
	_expect(arcade._enemy_speed(ArcadeLastUsherSurvivor.EnemyKind.SPRINTER) > early_speed, "Enemy movement did not strengthen over elapsed run time")
	arcade._run_elapsed = 400.0
	_expect(arcade._enemy_tier() == 3, "Enemy health progression exceeded its cap")
	arcade._orbital_branch = 0
	_expect(arcade._orbit_positions().is_empty(), "Orbiting reels unlock too early")
	arcade._orbital_branch = 1
	_expect(arcade._orbit_positions().size() == 1, "First reel upgrade is wrong")
	arcade._orbital_branch = 2
	_expect(arcade._orbit_positions().size() == 2, "Second reel upgrade is wrong")
	arcade._orbital_branch = 3
	_expect(arcade._orbit_positions().size() == 3, "Third reel upgrade is wrong")
	arcade._orbital_branch = 5
	_expect(arcade._orbit_positions().size() == 4, "Evolved orbital count is wrong")
	arcade.close_arcade()
	_expect(not arcade._shot_audio.playing and not arcade._tape_audio.playing, "Stress-test audio was not stopped")
	arcade.queue_free()
	for frame in 4:
		await process_frame
	if failures.is_empty():
		print("ARCADE_LAST_USHER_BALANCE_OK: 512 spawn checks, two 50-second stress runs")
		quit(0)
	else:
		print("ARCADE_LAST_USHER_BALANCE_FAILED: ", ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
