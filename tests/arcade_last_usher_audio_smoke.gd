extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arcade := ArcadeLastUsherSurvivor.new()
	root.add_child(arcade)
	await process_frame
	var music := arcade._music.stream as AudioStreamWAV
	_check(music != null and music.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Selected music does not loop")
	_check(music != null and music.loop_end > 1000000, "Music loop ends too early")
	_check(arcade._orbit_audio.stream != null and arcade._orbit_audio.volume_db == -11.0, "Boosted orbit is not configured")
	_check(arcade.open_arcade(), "Arcade did not open")
	_check(arcade._music.playing, "Selected music did not start")
	await create_timer(0.2).timeout
	arcade._start_run(0)
	arcade._enemies = [{"pos": Vector2(0, -30), "kind": ArcadeLastUsherSurvivor.EnemyKind.SHADOW, "hp": 2, "stun": 0.0, "hit_flash": 0.0, "phase": 0.0, "orbit_cooldown": 0.0}]
	arcade._auto_attack()
	_check(arcade._shot_audio.playing, "Shot did not play")
	arcade._orbital_branch = 1
	arcade._animation = 0.0
	arcade._enemies = [{"pos": Vector2(22, 0), "kind": ArcadeLastUsherSurvivor.EnemyKind.SHADOW, "hp": 2, "stun": 0.0, "hit_flash": 0.0, "phase": 0.0, "orbit_cooldown": 0.0}]
	arcade._update_orbit(0.01)
	_check(arcade._orbit_audio.playing and arcade._orbit_audio_cooldown > 0.0, "Orbital impact did not play")
	arcade._collect_pickup("film")
	_check(arcade._tape_audio.playing and arcade._tape_audio_cooldown > 0.0, "Tape pickup did not play")
	arcade._collect_pickup("heart")
	_check(arcade._heart_audio.playing, "Heart pickup did not play")
	arcade.close_arcade()
	_check(not arcade._music.playing and not arcade._shot_audio.playing and not arcade._orbit_audio.playing and not arcade._tape_audio.playing and not arcade._heart_audio.playing, "Audio continued after closing")
	await create_timer(1.0).timeout # Deja que el servidor de audio retire las voces detenidas.
	arcade.queue_free()
	for frame in 4:
		await process_frame
	if failures.is_empty():
		print("ARCADE_LAST_USHER_AUDIO_OK")
		quit(0)
	else:
		print("ARCADE_LAST_USHER_AUDIO_FAILED: ", ", ".join(failures))
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
