extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1536, 864)
	var arcade := ArcadeLastUsherSurvivor.new()
	root.add_child(arcade)
	await process_frame
	arcade._screen.visible = true
	arcade._mode = ArcadeLastUsherSurvivor.Mode.MENU
	await _capture("menu")
	arcade._menu_selection = 2
	await _capture("menu_long")
	arcade._menu_selection = 0
	arcade._mode = ArcadeLastUsherSurvivor.Mode.HOW_TO
	await _capture("manual")
	arcade._start_run(0)
	arcade._banner_time = 0.0
	arcade._invulnerable = 0.0
	arcade._enemies.clear()
	arcade._animation = 0.5
	await _capture("idle")
	arcade._walking = true
	await _capture("walking")
	arcade._walking = false
	arcade._survival_branch = 3
	arcade._dash_time = 0.16
	arcade._facing = Vector2.RIGHT
	await _capture("dash")
	arcade._dash_time = 0.0
	await _capture("gameplay")
	arcade._level = 6
	arcade._orbital_branch = 2
	arcade._enemies = [
		{"pos": Vector2(-100, -27), "kind": ArcadeLastUsherSurvivor.EnemyKind.SHADOW, "phase": 0.0, "stun": 0.0, "hit_flash": 0.0, "hp": 1, "orbit_cooldown": 0.0, "ghost_timer": 3.0, "ghost_fade": 0.0, "ghost_swapped": false},
		{"pos": Vector2(-47, 25), "kind": ArcadeLastUsherSurvivor.EnemyKind.PATROLLER, "phase": 0.0, "stun": 0.0, "hit_flash": 0.0, "hp": 2, "orbit_cooldown": 0.0, "laser_cooldown": 3.0, "laser_warning": 0.0, "laser_direction": Vector2.ZERO},
		{"pos": Vector2(94, -34), "kind": ArcadeLastUsherSurvivor.EnemyKind.SPRINTER, "phase": 0.0, "stun": 0.0, "hit_flash": 0.0, "hp": 2, "orbit_cooldown": 0.0},
	]
	arcade._opening_wave_pending = false
	arcade._spawn_cooldown = 999.0
	arcade._pickups = [{"pos": Vector2(52, 8), "kind": "film", "age": 0.0}, {"pos": Vector2(123, 27), "kind": "heart", "age": 0.0}]
	await _capture("swarm")
	var eye_index := -1
	for index in arcade._enemies.size():
		if int(arcade._enemies[index]["kind"]) == ArcadeLastUsherSurvivor.EnemyKind.PATROLLER:
			eye_index = index
			break
	var aiming_eye: Dictionary = arcade._enemies[eye_index]
	aiming_eye["laser_warning"] = 0.6
	aiming_eye["laser_direction"] = (arcade._player_pos - Vector2(aiming_eye["pos"])).normalized()
	arcade._enemies[eye_index] = aiming_eye
	await _capture("eye_laser_warning")
	arcade._enemy_lasers.append({"pos": Vector2(aiming_eye["pos"]), "direction": Vector2(aiming_eye["laser_direction"]), "age": 0.16, "hit": false})
	await _capture("eye_laser_fire")
	arcade._enemy_lasers.clear()
	arcade._enemies.clear()
	arcade._spawn_enemy(ArcadeLastUsherSurvivor.EnemyKind.PATROLLER)
	var distant_eye: Dictionary = arcade._enemies[0]
	distant_eye["pos"] = arcade._player_pos + Vector2(0, -160)
	distant_eye["laser_cooldown"] = 0.0
	arcade._enemies[0] = distant_eye
	arcade._update_enemies(0.02)
	await _capture("eye_offscreen_warning")
	arcade._player_pos = Vector2.ZERO
	arcade._facing = Vector2.UP
	arcade._enemies = [{"pos": Vector2(0, -35), "kind": ArcadeLastUsherSurvivor.EnemyKind.SHADOW, "phase": 0.0, "stun": 0.0, "hit_flash": 0.0, "hp": 2, "orbit_cooldown": 0.0, "ghost_timer": 3.0, "ghost_fade": 0.0, "ghost_swapped": false}]
	arcade._damage_enemy(0, 1)
	await _capture("impact")
	arcade._damage_enemy(0, 1)
	await _capture("death_fade")
	arcade._mode = ArcadeLastUsherSurvivor.Mode.UPGRADE
	arcade._level = 2
	arcade._orbital_branch = 0
	arcade._survival_branch = 0
	await _capture("upgrade")
	arcade._shot_branch = 5
	arcade._upgrade_selection = 1
	await _capture("upgrade_two")
	arcade._survival_branch = 3
	await _capture("upgrade_one")
	arcade._stage = 1
	arcade._start_stage(false)
	await _capture("act_transition")
	arcade._stage = 3
	arcade._start_stage()
	arcade._banner_time = 0.0
	arcade._invulnerable = 0.0
	arcade._spawn_boss()
	var visible_boss: Dictionary = arcade._enemies.back()
	visible_boss["pos"] = Vector2(-64, -25)
	arcade._enemies[arcade._enemies.size() - 1] = visible_boss
	arcade._boss_warning = 0.6
	await _capture("boss")
	arcade._boss_orbital_lasers()
	await _capture("boss_laser_warning")
	arcade._update_laser_zones(1.0)
	await _capture("boss_laser_strike")
	arcade._boss_charge = 1.0
	await _capture("boss_charge")
	arcade._mode = ArcadeLastUsherSurvivor.Mode.VICTORY
	arcade._feedback = "CARTEL DESBLOQUEADO"
	await _capture("victory")
	arcade._mode = ArcadeLastUsherSurvivor.Mode.DEFEAT
	arcade._feedback = "SE ACABÓ LA FUNCIÓN"
	arcade._defeat_selection = 1
	await _capture("defeat")
	arcade._screen.visible = false
	arcade.queue_free()
	for frame in 4:
		await process_frame
	quit(0)


func _capture(label: String) -> void:
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://.godot/arcade_last_usher_%s.png" % label)
	var result := image.save_png(path)
	print("ARCADE_LAST_USHER_VISUAL ", label, " ", image.get_size(), " ", result)
