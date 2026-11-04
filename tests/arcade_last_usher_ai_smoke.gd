extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arcade := ArcadeLastUsherSurvivor.new()
	root.add_child(arcade)
	await process_frame
	arcade._hit_audio.stream = null
	arcade._start_run(0)
	arcade._banner_time = 0.0
	arcade._invulnerable = 999.0
	arcade._enemies.clear()
	arcade._spawn_enemy(ArcadeLastUsherSurvivor.EnemyKind.SHADOW)
	var ghost: Dictionary = arcade._enemies[0]
	ghost["pos"] = Vector2(-100, 0)
	ghost["ghost_timer"] = 0.01
	arcade._enemies[0] = ghost
	arcade._update_enemies(0.02)
	_expect(float(arcade._enemies[0]["ghost_fade"]) > 0.0, "Ghost did not start fading")
	arcade._update_enemies(0.23)
	_expect(Vector2(arcade._enemies[0]["pos"]).is_equal_approx(Vector2(100, 0)), "Ghost did not mirror its position around the player")
	arcade._enemies.clear()
	arcade._spawn_enemy(ArcadeLastUsherSurvivor.EnemyKind.PATROLLER)
	var eye: Dictionary = arcade._enemies[0]
	eye["pos"] = Vector2(110, 0)
	eye["laser_cooldown"] = 0.0
	arcade._enemies[0] = eye
	arcade._update_enemies(0.02)
	var locked_direction := Vector2(arcade._enemies[0]["laser_direction"])
	_expect(float(arcade._enemies[0]["laser_warning"]) > 0.0, "Eye did not telegraph its laser")
	_expect(Vector2(arcade._enemies[0]["laser_target"]).is_equal_approx(Vector2.ZERO), "Eye did not mark the player's position")
	arcade._player_pos = Vector2(0, 45)
	arcade._update_enemies(1.21)
	_expect(arcade._enemy_lasers.size() == 1, "Eye did not fire after the warning")
	_expect(Vector2(arcade._enemy_lasers[0]["direction"]).is_equal_approx(locked_direction), "Eye laser re-aimed after the warning")
	arcade._enemy_lasers.clear()
	arcade._enemies.clear()
	arcade._player_pos = Vector2.ZERO
	arcade._spawn_enemy(ArcadeLastUsherSurvivor.EnemyKind.PATROLLER)
	var distant_eye: Dictionary = arcade._enemies[0]
	distant_eye["pos"] = Vector2(0, -160)
	distant_eye["laser_cooldown"] = 0.0
	arcade._enemies[0] = distant_eye
	arcade._update_enemies(0.02)
	_expect(not ArcadeLastUsherSurvivor.ARENA.grow(-16.0).has_point(arcade._world_to_screen(Vector2(arcade._enemies[0]["pos"]))), "Distant eye is unexpectedly visible in the test")
	_expect(ArcadeLastUsherSurvivor.ARENA.grow(-7.0).has_point(arcade._world_to_screen(Vector2(arcade._enemies[0]["laser_target"]))), "Off-screen eye warning target is not visible")
	arcade._update_enemies(0.9)
	_expect(arcade._enemy_lasers.is_empty(), "Off-screen eye fired before its warning ended")
	arcade._update_enemies(0.31)
	_expect(arcade._enemy_lasers.size() == 1, "Off-screen eye did not fire after the full warning")
	arcade._invulnerable = 0.0
	var lives_before_distant_laser := arcade._lives
	arcade._update_enemy_lasers(0.05)
	_expect(arcade._lives == lives_before_distant_laser, "Distant laser dealt damage before its beam reached the player")
	arcade._update_enemy_lasers(0.25)
	_expect(arcade._lives == lives_before_distant_laser - 1, "Distant laser never reached the player")
	arcade._invulnerable = 999.0
	arcade._hit_audio.stop()
	arcade._enemies.clear()
	arcade._spawn_sprinter_pack(4, Vector2(200, 0))
	_expect(arcade._enemies.size() == 4, "Golden bugs did not spawn as a pack")
	_expect(arcade._enemy_speed(ArcadeLastUsherSurvivor.EnemyKind.SPRINTER) > arcade._enemy_speed(ArcadeLastUsherSurvivor.EnemyKind.PATROLLER), "Golden bugs are not faster")
	arcade._opening_wave_pending = false
	arcade._stage = 1
	arcade._start_stage(false)
	_expect(arcade._enemies.size() == 4, "Act transition erased live enemies")
	arcade._spawn_cooldown = 0.0
	arcade._update_game(0.1)
	_expect(arcade._stage_elapsed > 0.0 and arcade._banner_time > 0.0 and arcade._enemies.size() > 4, "Act transition paused the game or enemy spawning")
	arcade._enemies.clear()
	arcade._stage = 3
	arcade._spawn_boss()
	var boss_index := arcade._enemies.size() - 1
	var boss_hp := int(arcade._enemies[boss_index]["hp"])
	arcade._damage_enemy(boss_index, ceili(float(boss_hp) * 0.49))
	_expect(arcade._boss_charge_target == 1 and arcade._boss_charge > 0.0, "Half-health charge did not start")
	arcade._update_boss_attack(1.3)
	_expect(arcade._boss_phase == 1 and arcade._enemies.size() == 11, "Half-health charge did not summon ten golden bugs")
	boss_index = 0
	arcade._damage_enemy(boss_index, ceili(float(boss_hp) * 0.24))
	_expect(arcade._boss_charge_target == 2 and arcade._boss_charge > 0.0, "Final charge did not start")
	arcade._update_boss_attack(1.1)
	_expect(arcade._boss_phase == 2, "Final phase did not activate")
	arcade._boss_orbital_lasers()
	_expect(arcade._laser_zones.size() >= 5, "Final phase did not add orbital laser zones")
	arcade._invulnerable = 0.0
	var lives_before_laser := arcade._lives
	arcade._update_laser_zones(1.2)
	_expect(float(arcade._laser_zones[0]["active"]) > 0.0, "Orbital laser did not fire after warning")
	_expect(arcade._lives == lives_before_laser - 1, "Orbital laser at the marked player position did not hit")
	arcade._hit_audio.stop()
	arcade.queue_free()
	for frame in 4:
		await process_frame
	if failures.is_empty():
		print("ARCADE_LAST_USHER_AI_OK")
		quit(0)
	else:
		print("ARCADE_LAST_USHER_AI_FAILED: ", ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
