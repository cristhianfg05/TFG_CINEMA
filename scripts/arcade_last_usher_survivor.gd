class_name ArcadeLastUsherSurvivor
extends CanvasLayer

# Continuous-motion successor to the original grid prototype. The cabinet,
# objective and collectible contracts stay unchanged; the old script remains
# available for rollback.
const LOGICAL_SIZE := Vector2(384, 216)
const ARENA := Rect2(15, 40, 354, 146)
const CAMERA_CENTER := Vector2(192, 113)
const SPAWN_DISTANCE := Vector2(205, 245)
const NORMAL_POSTER_ID := "arcade_second_game_normal_poster"
const HARD_POSTER_ID := "arcade_second_game_hard_poster"
const STAGE_NAMES := ["ÚLTIMA RONDA", "SOMBRAS EN LA FILA", "APAGÓN", "REY DE LA PANTALLA"]
const NORMAL_DURATIONS := [70.0, 75.0, 80.0, 100.0]
const HARD_DURATIONS := [75.0, 80.0, 85.0, 110.0]
const USHER_TEXTURE := preload("res://assets/pipeline/arcade_last_usher_survivor/usher.png")
const SHADOW_TEXTURE := preload("res://assets/pipeline/arcade_last_usher_survivor/shadow.png")
const PATROLLER_TEXTURE := preload("res://assets/pipeline/arcade_last_usher_survivor/patroller.png")
const SPRINTER_TEXTURE := preload("res://assets/pipeline/arcade_last_usher_survivor/sprinter.png")
const BOSS_TEXTURE := preload("res://assets/pipeline/arcade_last_usher_survivor/boss.png")
const SELECT_STREAM := preload("res://assets/audio/sfx/arcade/arcade_menu_soft_pim_03.wav")
const PICKUP_STREAM := preload("res://assets/audio/sfx/arcade/arcade_repair_03.wav")
const HIT_STREAM := preload("res://assets/audio/sfx/arcade/arcade_error_03.wav")
const MUSIC_STREAM := preload("res://assets/audio/music/arcade/last_usher_music_03.wav")
const SHOT_STREAM := preload("res://assets/audio/sfx/arcade_last_usher/shot_02.wav")
const ORBIT_STREAM := preload("res://assets/audio/sfx/arcade_last_usher/orbit_01_boosted.wav")
const TAPE_STREAM := preload("res://assets/audio/sfx/arcade_last_usher/tape_pickup_02.wav")
const HEART_STREAM := preload("res://assets/audio/sfx/arcade_last_usher/heart_pickup_03.wav")

@export var use_legacy_music := false

enum Mode { CLOSED, BOOT, MENU, HOW_TO, PLAYING, UPGRADE, VICTORY, DEFEAT, EXIT }
enum EnemyKind { SHADOW, PATROLLER, SPRINTER, BOSS }

var _mode := Mode.CLOSED
var _screen: SurvivorScreen
var _manager: Node
var _music: AudioStreamPlayer
var _select_audio: AudioStreamPlayer
var _pickup_audio: AudioStreamPlayer
var _hit_audio: AudioStreamPlayer
var _shot_audio: AudioStreamPlayer
var _orbit_audio: AudioStreamPlayer
var _tape_audio: AudioStreamPlayer
var _heart_audio: AudioStreamPlayer
var _orbit_audio_cooldown := 0.0
var _tape_audio_cooldown := 0.0
var _paused_before_open := false
var _stored_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _transition := 0.0
var _animation := 0.0
var _menu_selection := 0
var _upgrade_selection := 0
var _defeat_selection := 0
var _difficulty := 0
var _stage := 0
var _stage_elapsed := 0.0
var _run_elapsed := 0.0
var _stage_time_left := 0.0
var _banner_time := 0.0
var _opening_wave_pending := false
var _feedback := ""
var _feedback_time := 0.0
var _score := 0
var _lives := 5
var _max_lives := 5
var _player_pos := Vector2.ZERO
var _facing := Vector2.UP
var _walking := false
var _invulnerable := 0.0
var _damage_flash := 0.0
var _dash_time := 0.0
var _dash_cooldown := 0.0
var _fire_cooldown := 0.0
var _magnet_time := 0.0
var _spawn_cooldown := 0.0
var _supply_cooldown := 0.0
var _boss_attack_cooldown := 3.0
var _boss_warning := 0.0
var _boss_spawned := false
var _boss_phase := 0
var _boss_charge := 0.0
var _boss_charge_target := 0
var _laser_zones: Array[Dictionary] = []
var _enemy_lasers: Array[Dictionary] = []
var _shot_branch := 0
var _orbital_branch := 0
var _survival_branch := 0
var _level := 1
var _xp := 0
var _xp_goal := 5
var _enemies: Array[Dictionary] = []
var _shots: Array[Dictionary] = []
var _enemy_shots: Array[Dictionary] = []
var _pickups: Array[Dictionary] = []
var _damage_numbers: Array[Dictionary] = []
var _death_effects: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("arcade_usher_minigame")
	_screen = SurvivorScreen.new()
	_screen.controller = self
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.visible = false
	add_child(_screen)
	_music = AudioStreamPlayer.new()
	_music.name = "LastUsherSurvivorMusic"
	_music.stream = _make_music_loop() if use_legacy_music else _make_approved_music_loop()
	_music.volume_db = -27.0 if use_legacy_music else -25.0
	_music.bus = "Machines"
	add_child(_music)
	_select_audio = _add_audio("SurvivorSelect", SELECT_STREAM, -10.0)
	_select_audio.bus = "UI"
	_pickup_audio = _add_audio("SurvivorPickup", PICKUP_STREAM, -9.0)
	_hit_audio = _add_audio("SurvivorHit", HIT_STREAM, -10.0)
	_shot_audio = _add_audio("SurvivorShot", SHOT_STREAM, -17.0)
	_orbit_audio = _add_audio("SurvivorOrbit", ORBIT_STREAM, -11.0)
	_tape_audio = _add_audio("SurvivorTapePickup", TAPE_STREAM, -3.0)
	_heart_audio = _add_audio("SurvivorHeartPickup", HEART_STREAM, -10.0)
	_shot_audio.max_polyphony = 4
	_orbit_audio.max_polyphony = 4
	_tape_audio.max_polyphony = 4


func _add_audio(label: String, stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = label
	player.stream = stream
	player.volume_db = volume
	player.bus = "Machines"
	add_child(player)
	return player


func is_open() -> bool:
	return _mode != Mode.CLOSED


func open_arcade(_source: Node3D = null) -> bool:
	if is_open() or _has_blocking_modal():
		return false
	_manager = get_tree().get_first_node_in_group("gameplay_manager")
	if _manager and _manager.has_method("set_vacuum_trigger_held"):
		_manager.set_vacuum_trigger_held(false)
	if _manager and _manager.has_method("mark_second_arcade_discovered"):
		_manager.mark_second_arcade_discovered()
	_paused_before_open = get_tree().paused
	_stored_mouse_mode = Input.mouse_mode
	_set_gameplay_hud_visible(false)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_mode = Mode.BOOT
	_transition = 0.0
	_screen.visible = true
	_music.play()
	return true


func close_arcade() -> void:
	if not is_open():
		return
	_mode = Mode.CLOSED
	_music.stop()
	for player in [_select_audio, _pickup_audio, _hit_audio, _shot_audio, _orbit_audio, _tape_audio, _heart_audio]:
		player.stop()
	_screen.visible = false
	get_tree().paused = _paused_before_open
	Input.mouse_mode = _stored_mouse_mode
	_set_gameplay_hud_visible(true)


func _process(delta: float) -> void:
	if _mode == Mode.CLOSED:
		return
	_animation += delta
	if _mode == Mode.BOOT:
		_transition += delta
		if _transition >= 0.35:
			_mode = Mode.MENU
	elif _mode == Mode.EXIT:
		_transition += delta
		if _transition >= 0.25:
			close_arcade()
			return
	elif _mode == Mode.PLAYING:
		_update_game(minf(delta, 0.05))
	_screen.queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_open() or get_viewport().is_input_handled():
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		_mode = Mode.EXIT
		_transition = 0.0
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	var direction := _direction_from_event(event)
	match _mode:
		Mode.MENU:
			if direction != Vector2.ZERO:
				_menu_selection = posmod(_menu_selection + (1 if direction.y > 0 or direction.x > 0 else -1), 3)
				_select_audio.play()
			elif _is_confirm(event):
				if _menu_selection == 2:
					_mode = Mode.HOW_TO
				else:
					_start_run(_menu_selection)
		Mode.HOW_TO:
			if _is_confirm(event):
				_mode = Mode.MENU
		Mode.PLAYING:
			if _banner_time <= 0.0:
				if event.is_action_pressed("jump"):
					_dash()
		Mode.UPGRADE:
			if direction != Vector2.ZERO:
				_step_upgrade(1 if direction.y > 0 or direction.x > 0 else -1)
				_select_audio.play()
			elif _is_confirm(event):
				_apply_upgrade()
		Mode.VICTORY:
			if _is_confirm(event):
				_mode = Mode.MENU
		Mode.DEFEAT:
			if direction != Vector2.ZERO:
				_defeat_selection = posmod(_defeat_selection + (1 if direction.y > 0 or direction.x > 0 else -1), 3)
				_select_audio.play()
			elif _is_confirm(event):
				match _defeat_selection:
					0: _start_run(_difficulty)
					1: _mode = Mode.MENU
					2: close_arcade()
	get_viewport().set_input_as_handled()


func _direction_from_event(event: InputEvent) -> Vector2:
	if event.is_action_pressed("move_forward"): return Vector2.UP
	if event.is_action_pressed("move_backward"): return Vector2.DOWN
	if event.is_action_pressed("move_left"): return Vector2.LEFT
	if event.is_action_pressed("move_right"): return Vector2.RIGHT
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP: return Vector2.UP
			KEY_DOWN: return Vector2.DOWN
			KEY_LEFT: return Vector2.LEFT
			KEY_RIGHT: return Vector2.RIGHT
	return Vector2.ZERO


func _movement_vector() -> Vector2:
	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	return direction.limit_length()


func _is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed("interact") or event.is_action_pressed("jump")


func _start_run(difficulty: int) -> void:
	_difficulty = difficulty
	_stage = 0
	_run_elapsed = 0.0
	_score = 0
	_level = 1
	_xp = 0
	_xp_goal = 5
	_shot_branch = 0
	_orbital_branch = 0
	_survival_branch = 0
	_max_lives = 5 if difficulty == 0 else 4
	_lives = _max_lives
	_player_pos = Vector2.ZERO
	_music.pitch_scale = 0.94 if difficulty == 0 else 1.05
	_start_stage(true)


func _start_stage(first_stage: bool = true) -> void:
	_mode = Mode.PLAYING
	_stage_elapsed = 0.0
	_stage_time_left = (NORMAL_DURATIONS if _difficulty == 0 else HARD_DURATIONS)[_stage]
	_banner_time = 1.8
	_feedback = ""
	_feedback_time = 0.0
	if first_stage:
		_facing = Vector2.UP
		_walking = false
		_invulnerable = 2.0
		_damage_flash = 0.0
		_dash_time = 0.0
		_dash_cooldown = 0.0
		_fire_cooldown = 0.3
		_spawn_cooldown = 0.6
		_magnet_time = 0.0
		_supply_cooldown = 18.0
		_boss_attack_cooldown = 3.0
		_boss_warning = 0.0
		_boss_spawned = false
		_boss_phase = 0
		_boss_charge = 0.0
		_laser_zones.clear()
		_enemy_lasers.clear()
		_orbit_audio_cooldown = 0.0
		_tape_audio_cooldown = 0.0
		_enemies.clear()
		_shots.clear()
		_enemy_shots.clear()
		_pickups.clear()
		_damage_numbers.clear()
		_death_effects.clear()
		_opening_wave_pending = true
	else:
		# Acts are continuous: no enemy/pickup wipe, invulnerability reset or pause.
		_spawn_cooldown = minf(_spawn_cooldown, 0.15)
	_music.pitch_scale = (0.94 if _difficulty == 0 else 1.05) + _stage * 0.035


func _spawn_opening_wave() -> void:
	_opening_wave_pending = false
	for index in 6 + _stage * 2 + _difficulty * 2:
		var angle := TAU * float(index) / float(6 + _stage * 2 + _difficulty * 2)
		var point := _player_pos + Vector2.RIGHT.rotated(angle) * (125.0 + float(index % 3) * 12.0)
		if index % 3 == EnemyKind.SPRINTER:
			_spawn_sprinter_pack(randi_range(3, 5), point)
		else:
			_spawn_enemy(index % 3)
			var opening_enemy: Dictionary = _enemies[_enemies.size() - 1]
			opening_enemy["pos"] = point
			_enemies[_enemies.size() - 1] = opening_enemy


func _update_game(delta: float) -> void:
	_banner_time = maxf(0.0, _banner_time - delta)
	_feedback_time = maxf(0.0, _feedback_time - delta)
	if _banner_time > 0.0 and _stage == 0:
		return
	if _opening_wave_pending:
		_spawn_opening_wave()
	_stage_elapsed += delta
	_run_elapsed += delta
	_stage_time_left -= delta
	if _stage_time_left <= 0.0:
		if _stage == 3:
			_finish_defeat("EL REY SIGUE EN PIE")
		else:
			_score += 300 + _lives * 75
			_stage += 1
			_start_stage(false)
		return
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_damage_flash = maxf(0.0, _damage_flash - delta)
	_dash_time = maxf(0.0, _dash_time - delta)
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_magnet_time = maxf(0.0, _magnet_time - delta)
	_fire_cooldown -= delta
	_orbit_audio_cooldown = maxf(0.0, _orbit_audio_cooldown - delta)
	_tape_audio_cooldown = maxf(0.0, _tape_audio_cooldown - delta)
	_move_player(delta)
	_update_damage_numbers(delta)
	_update_death_effects(delta)
	_update_enemies(delta)
	if _mode != Mode.PLAYING:
		return
	_update_orbit(delta)
	_update_shots(delta)
	if _mode != Mode.PLAYING:
		return
	_update_enemy_shots(delta)
	if _mode != Mode.PLAYING:
		return
	_update_enemy_lasers(delta)
	_update_laser_zones(delta)
	if _mode != Mode.PLAYING:
		return
	_update_pickups(delta)
	if _mode != Mode.PLAYING:
		return
	if _fire_cooldown <= 0.0:
		_auto_attack()
		_fire_cooldown = 0.40 if _shot_branch >= 1 else (0.49 if _difficulty == 0 else 0.52)
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0:
		_spawn_cooldown = _spawn_interval()
		var target := _spawn_target()
		if _enemies.size() < target:
			var kind := randi_range(0, 2)
			if kind == EnemyKind.SPRINTER and target - _enemies.size() >= 3:
				_spawn_sprinter_pack(mini(randi_range(3, 5), target - _enemies.size()))
			else:
				var batch := 2 if _enemies.size() < target / 2 else 1
				for index in mini(batch, target - _enemies.size()):
					_spawn_enemy(EnemyKind.SHADOW if kind == EnemyKind.SPRINTER else kind)
	_supply_cooldown -= delta
	if _supply_cooldown <= 0.0:
		_supply_cooldown = 27.0 if _difficulty == 0 else 34.0
		var kind := "heart" if _lives <= 2 or randf() < 0.45 else "magnet"
		_pickups.append({"pos": _random_nearby_point(), "kind": kind, "age": 0.0})
	if _stage == 3 and not _boss_spawned and _stage_elapsed >= 45.0:
		_spawn_boss()
	if _boss_spawned and _boss_alive():
		_update_boss_attack(delta)


func _move_player(delta: float) -> void:
	var direction := _movement_vector()
	_walking = direction != Vector2.ZERO and _dash_time <= 0.0
	if direction != Vector2.ZERO:
		_facing = direction
	var velocity := _facing * 225.0 if _dash_time > 0.0 else direction * (82.0 + (11.0 if _survival_branch >= 2 else 0.0))
	_player_pos += velocity * delta


func _world_to_screen(world_pos: Vector2) -> Vector2:
	return CAMERA_CENTER + world_pos - _player_pos


func _spawn_interval() -> float:
	var base: float = [0.72, 0.60, 0.49, 0.40][_stage]
	var duration: float = (NORMAL_DURATIONS if _difficulty == 0 else HARD_DURATIONS)[_stage]
	var progress := clampf(_stage_elapsed / duration, 0.0, 1.0)
	return maxf(0.27, base * (0.84 if _difficulty == 1 else 1.0) * (1.0 - progress * 0.16))


func _spawn_target() -> int:
	var duration: float = (NORMAL_DURATIONS if _difficulty == 0 else HARD_DURATIONS)[_stage]
	var progress := clampf(_stage_elapsed / duration, 0.0, 1.0)
	return [14, 20, 27, 35][_stage] + int(progress * 6.0) + (5 if _difficulty == 1 else 0)


func _spawn_enemy(kind: int) -> void:
	var point := _player_pos + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(SPAWN_DISTANCE.x, SPAWN_DISTANCE.y)
	var hp := (1 if kind == EnemyKind.SHADOW else 2) + _enemy_tier()
	if _difficulty == 1 and _stage >= 2:
		hp += 1
	_enemies.append({"pos": point, "kind": kind, "hp": hp, "stun": 0.0, "hit_flash": 0.0, "phase": randf() * TAU, "orbit_cooldown": 0.0,
		"ghost_timer": randf_range(3.0, 5.5), "ghost_fade": 0.0, "ghost_swapped": false,
		"laser_cooldown": randf_range(1.8, 3.3), "laser_warning": 0.0, "laser_direction": Vector2.ZERO, "laser_target": Vector2.ZERO})


func _spawn_sprinter_pack(count: int, center: Vector2 = Vector2.INF) -> void:
	if center == Vector2.INF:
		center = _player_pos + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(SPAWN_DISTANCE.x, SPAWN_DISTANCE.y)
	for index in count:
		_spawn_enemy(EnemyKind.SPRINTER)
		var member: Dictionary = _enemies[_enemies.size() - 1]
		member["pos"] = center + Vector2.RIGHT.rotated(TAU * float(index) / float(maxi(3, count))) * randf_range(5.0, 12.0)
		_enemies[_enemies.size() - 1] = member


func _spawn_boss() -> void:
	_boss_spawned = true
	var boss_hp := (38 if _difficulty == 0 else 56) + _enemy_tier() * 4
	_enemies.append({"pos": _player_pos + Vector2(0, -122), "kind": EnemyKind.BOSS, "hp": boss_hp, "max_hp": boss_hp, "stun": 0.0, "hit_flash": 0.0, "phase": 0.0, "orbit_cooldown": 0.0})
	_boss_attack_cooldown = 2.5
	_set_feedback("¡EL REY DE LA PANTALLA!", 2.5)


func _enemy_speed(kind: int) -> float:
	var base: float = [20.0, 27.0, 54.0, 22.0][kind]
	return base * (1.0 + _stage * 0.08) * (1.22 if _difficulty == 1 else 1.0) * (1.0 + minf(0.15, _run_elapsed * 0.0005))


func _enemy_tier() -> int:
	return mini(3, int(_run_elapsed / 80.0))


func _update_enemies(delta: float) -> void:
	for index in range(_enemies.size() - 1, -1, -1):
		var enemy: Dictionary = _enemies[index]
		if int(enemy["kind"]) != EnemyKind.BOSS and Vector2(enemy["pos"]).distance_to(_player_pos) > 430.0:
			_enemies.remove_at(index)
			continue
		enemy["stun"] = maxf(0.0, float(enemy["stun"]) - delta)
		enemy["hit_flash"] = maxf(0.0, float(enemy["hit_flash"]) - delta)
		enemy["orbit_cooldown"] = maxf(0.0, float(enemy["orbit_cooldown"]) - delta)
		enemy["phase"] = float(enemy["phase"]) + delta
		match int(enemy["kind"]):
			EnemyKind.SHADOW:
				_update_shadow(enemy, delta)
			EnemyKind.PATROLLER:
				_update_patroller(enemy, delta)
			EnemyKind.BOSS:
				if _boss_charge <= 0.0 and float(enemy["stun"]) <= 0.0:
					enemy["pos"] = Vector2(enemy["pos"]).move_toward(_player_pos, _enemy_speed(EnemyKind.BOSS) * delta)
			_:
				if float(enemy["stun"]) <= 0.0:
					enemy["pos"] = Vector2(enemy["pos"]).move_toward(_player_pos, _enemy_speed(int(enemy["kind"])) * delta)
		_enemies[index] = enemy
		if _invulnerable <= 0.0 and float(enemy.get("ghost_fade", 0.0)) <= 0.0 and Vector2(enemy["pos"]).distance_to(_player_pos) < (13.0 if int(enemy["kind"]) == EnemyKind.BOSS else 8.0):
			var push := (_player_pos - Vector2(enemy["pos"])).normalized()
			if push == Vector2.ZERO:
				push = Vector2.UP
			_player_pos += push * 7.0
			_take_hit()
			if _mode != Mode.PLAYING:
				return


func _update_shadow(enemy: Dictionary, delta: float) -> void:
	if float(enemy["ghost_fade"]) > 0.0:
		enemy["ghost_fade"] = maxf(0.0, float(enemy["ghost_fade"]) - delta)
		if not bool(enemy["ghost_swapped"]) and float(enemy["ghost_fade"]) <= 0.22:
			# Mirror the current offset, preserving the exact distance to the player.
			enemy["pos"] = _player_pos * 2.0 - Vector2(enemy["pos"])
			enemy["ghost_swapped"] = true
		return
	if float(enemy["stun"]) > 0.0:
		return
	enemy["ghost_timer"] = float(enemy["ghost_timer"]) - delta
	if float(enemy["ghost_timer"]) <= 0.0:
		enemy["ghost_fade"] = 0.44
		enemy["ghost_swapped"] = false
		enemy["ghost_timer"] = randf_range(3.8, 6.0)
		return
	var toward := (_player_pos - Vector2(enemy["pos"])).normalized()
	var side := Vector2(-toward.y, toward.x)
	var weave := sin(float(enemy["phase"]) * 3.4) * 0.62
	enemy["pos"] = Vector2(enemy["pos"]) + (toward + side * weave).normalized() * _enemy_speed(EnemyKind.SHADOW) * delta


func _update_patroller(enemy: Dictionary, delta: float) -> void:
	if float(enemy["laser_warning"]) > 0.0:
		enemy["laser_warning"] = maxf(0.0, float(enemy["laser_warning"]) - delta)
		if float(enemy["laser_warning"]) <= 0.0:
			_enemy_lasers.append({"pos": Vector2(enemy["pos"]), "direction": Vector2(enemy["laser_direction"]), "age": 0.0, "hit": false})
		return
	if float(enemy["stun"]) > 0.0:
		return
	var offset := _player_pos - Vector2(enemy["pos"])
	var distance := offset.length()
	var toward := offset.normalized()
	var radial := 0.0
	if distance > 132.0:
		radial = 1.0
	elif distance < 93.0:
		radial = -1.0
	var strafe := Vector2(-toward.y, toward.x) * sin(float(enemy["phase"]) * 0.8) * 0.42
	enemy["pos"] = Vector2(enemy["pos"]) + (toward * radial + strafe).limit_length(1.0) * _enemy_speed(EnemyKind.PATROLLER) * delta
	enemy["laser_cooldown"] = float(enemy["laser_cooldown"]) - delta
	if float(enemy["laser_cooldown"]) <= 0.0 and distance <= 170.0:
		enemy["laser_target"] = _player_pos
		enemy["laser_direction"] = (_player_pos - Vector2(enemy["pos"])).normalized()
		enemy["laser_warning"] = 1.2
		enemy["laser_cooldown"] = randf_range(3.0, 4.3)


func _orbit_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if _orbital_branch == 0:
		return positions
	var count := 4 if _orbital_branch >= 5 else mini(3, _orbital_branch)
	for index in count:
		var angle := _animation * (4.4 if _orbital_branch >= 5 else 3.6) + TAU * float(index) / float(count)
		positions.append(_player_pos + Vector2.RIGHT.rotated(angle) * (25.0 if _orbital_branch >= 5 else 22.0))
	return positions


func _update_orbit(_delta: float) -> void:
	var reels := _orbit_positions()
	if reels.is_empty():
		return
	for index in range(_enemies.size() - 1, -1, -1):
		var enemy: Dictionary = _enemies[index]
		if float(enemy["orbit_cooldown"]) > 0.0:
			continue
		for reel in reels:
			if Vector2(enemy["pos"]).distance_to(reel) < (15.0 if int(enemy["kind"]) == EnemyKind.BOSS else 8.0):
				enemy["orbit_cooldown"] = 0.7 if _orbital_branch >= 5 else 0.9
				_enemies[index] = enemy
				_damage_enemy(index, mini(_shot_damage(), 2 if _orbital_branch >= 4 else 1))
				if _orbit_audio.stream != null and _orbit_audio_cooldown <= 0.0:
					_orbit_audio.pitch_scale = randf_range(0.97, 1.03)
					_orbit_audio.play()
					_orbit_audio_cooldown = 0.15
				if _mode != Mode.PLAYING:
					return
				break


func _auto_attack() -> void:
	var closest := -1
	var best := 150.0
	for index in _enemies.size():
		var distance := _player_pos.distance_to(Vector2(_enemies[index]["pos"]))
		if distance < best:
			best = distance
			closest = index
	if closest < 0:
		return
	var direction := (Vector2(_enemies[closest]["pos"]) - _player_pos).normalized()
	var count := 4 if _shot_branch >= 4 else (2 if _shot_branch >= 3 else 1)
	for index in count:
		var angle := (float(index) - float(count - 1) * 0.5) * (0.05 if count == 4 else 0.06)
		var shot_direction := direction.rotated(angle)
		_shots.append({"pos": _player_pos + shot_direction * 8.0, "velocity": shot_direction * 190.0, "life": 1.0, "damage": _shot_damage(), "size": 1.6 if _shot_branch >= 5 else 1.0})
	if _shot_audio.stream != null:
		_shot_audio.pitch_scale = randf_range(0.97, 1.03)
		_shot_audio.play()


func _shot_damage() -> int:
	return 2 if _shot_branch >= 2 else 1


func _update_shots(delta: float) -> void:
	for shot_index in range(_shots.size() - 1, -1, -1):
		var shot: Dictionary = _shots[shot_index]
		shot["pos"] = Vector2(shot["pos"]) + Vector2(shot["velocity"]) * delta
		shot["life"] = float(shot["life"]) - delta
		if float(shot["life"]) <= 0.0 or Vector2(shot["pos"]).distance_to(_player_pos) > 330.0:
			_shots.remove_at(shot_index)
			continue
		var hit := false
		for enemy_index in range(_enemies.size() - 1, -1, -1):
			if float(_enemies[enemy_index].get("ghost_fade", 0.0)) > 0.0:
				continue
			var radius := 13.0 if int(_enemies[enemy_index]["kind"]) == EnemyKind.BOSS else 7.0
			if Vector2(shot["pos"]).distance_to(Vector2(_enemies[enemy_index]["pos"])) <= radius:
				_damage_enemy(enemy_index, int(shot["damage"]))
				hit = true
				break
		if hit:
			_shots.remove_at(shot_index)
		else:
			_shots[shot_index] = shot


func _damage_enemy(index: int, amount: int) -> void:
	var enemy: Dictionary = _enemies[index]
	var hit_direction := (Vector2(enemy["pos"]) - _player_pos).normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = Vector2.UP
	enemy["pos"] = Vector2(enemy["pos"]) + hit_direction * (2.0 if int(enemy["kind"]) == EnemyKind.BOSS else 4.0)
	enemy["hit_flash"] = 0.13
	_damage_numbers.append({"pos": Vector2(enemy["pos"]), "life": 0.36, "damage": amount})
	enemy["hp"] = int(enemy["hp"]) - amount
	if int(enemy["hp"]) > 0:
		_enemies[index] = enemy
		if int(enemy["kind"]) == EnemyKind.BOSS:
			var health_ratio := float(enemy["hp"]) / float(enemy["max_hp"])
			if _boss_phase == 0 and health_ratio <= 0.52:
				_begin_boss_charge(1)
			elif _boss_phase == 1 and _boss_charge <= 0.0 and health_ratio <= 0.29:
				_begin_boss_charge(2)
		return
	var boss := int(enemy["kind"]) == EnemyKind.BOSS
	var drop_pos := Vector2(enemy["pos"])
	_death_effects.append({"pos": drop_pos, "kind": int(enemy["kind"]), "life": 0.28})
	_enemies.remove_at(index)
	_score += 750 if boss else (50 if int(enemy["kind"]) == EnemyKind.SHADOW else 85)
	if boss:
		_finish_victory()
	elif randf() < 0.65:
		_pickups.append({"pos": drop_pos, "kind": "film", "age": 0.0})


func _update_damage_numbers(delta: float) -> void:
	for index in range(_damage_numbers.size() - 1, -1, -1):
		var number: Dictionary = _damage_numbers[index]
		number["life"] = float(number["life"]) - delta
		number["pos"] = Vector2(number["pos"]) + Vector2.UP * 16.0 * delta
		if float(number["life"]) <= 0.0:
			_damage_numbers.remove_at(index)
		else:
			_damage_numbers[index] = number


func _update_death_effects(delta: float) -> void:
	for index in range(_death_effects.size() - 1, -1, -1):
		var effect: Dictionary = _death_effects[index]
		effect["life"] = float(effect["life"]) - delta
		effect["pos"] = Vector2(effect["pos"]) + Vector2.UP * 10.0 * delta
		if float(effect["life"]) <= 0.0:
			_death_effects.remove_at(index)
		else:
			_death_effects[index] = effect


func _random_nearby_point() -> Vector2:
	return _player_pos + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(38.0, 95.0)


func _update_pickups(delta: float) -> void:
	for index in range(_pickups.size() - 1, -1, -1):
		var pickup: Dictionary = _pickups[index]
		pickup["age"] = float(pickup["age"]) + delta
		var pos := Vector2(pickup["pos"])
		var distance := pos.distance_to(_player_pos)
		var pull_radius := 205.0 if _magnet_time > 0.0 and String(pickup["kind"]) == "film" else 29.0
		if distance < pull_radius and distance > 0.01:
			pos = pos.move_toward(_player_pos, (170.0 if _magnet_time > 0.0 else 36.0 + (29.0 - distance) * 2.5) * delta)
			pickup["pos"] = pos
		if pos.distance_to(_player_pos) < 8.0:
			_collect_pickup(String(pickup["kind"]))
			_pickups.remove_at(index)
			if _mode == Mode.UPGRADE:
				return
		elif float(pickup["age"]) > 22.0 and String(pickup["kind"]) != "film":
			_pickups.remove_at(index)
		else:
			_pickups[index] = pickup


func _collect_pickup(kind: String) -> void:
	match kind:
		"film":
			_xp += 1
			_score += 15
			if _xp >= _xp_goal:
				_xp -= _xp_goal
				_level += 1
				_xp_goal += 3
				var available := _available_branches()
				if not available.is_empty():
					_mode = Mode.UPGRADE
					_upgrade_selection = available[0]
		"heart":
			_lives = mini(_max_lives, _lives + 1)
			_set_feedback("PALOMITAS: +1 VIDA", 1.0)
		"magnet":
			_magnet_time = 2.0
			_set_feedback("IMÁN: RECOGE CINTAS", 1.0)
	match kind:
		"film":
			if _tape_audio.stream != null and _tape_audio_cooldown <= 0.0:
				_tape_audio.pitch_scale = randf_range(0.96, 1.04)
				_tape_audio.play()
				_tape_audio_cooldown = 0.07
		"heart":
			if _heart_audio.stream != null:
				_heart_audio.play()
		"magnet":
			if _pickup_audio.stream != null:
				_pickup_audio.play() # El sonido anterior queda para el imán y como reversión.


func _dash() -> void:
	if _survival_branch < 3 or _dash_cooldown > 0.0:
		return
	_dash_time = 0.17
	_dash_cooldown = 4.4 if _difficulty == 0 else 5.1
	_invulnerable = maxf(_invulnerable, 0.42)


func _update_boss_attack(delta: float) -> void:
	if _boss_charge > 0.0:
		_boss_charge = maxf(0.0, _boss_charge - delta)
		if _boss_charge <= 0.0:
			_boss_phase = _boss_charge_target
			_boss_attack_cooldown = 0.55
			if _boss_phase == 1:
				# The first hidden phase calls exactly ten golden film bugs.
				for pack in 2:
					var center := _boss_position() + Vector2.RIGHT.rotated(float(pack) * PI) * 30.0
					_spawn_sprinter_pack(5, center)
				for enemy in _enemies:
					if int(enemy["kind"]) == EnemyKind.BOSS and float(enemy["hp"]) / float(enemy["max_hp"]) <= 0.29:
						_begin_boss_charge(2)
						break
		return
	if _boss_warning > 0.0:
		_boss_warning -= delta
		if _boss_warning <= 0.0:
			_boss_orbital_lasers()
		return
	_boss_attack_cooldown -= delta
	if _boss_attack_cooldown <= 0.0:
		_boss_warning = 0.28
		_boss_attack_cooldown = (2.8 if _difficulty == 0 else 2.25) - float(_boss_phase) * 0.25


func _begin_boss_charge(next_phase: int) -> void:
	_boss_charge_target = next_phase
	_boss_charge = 1.2 if next_phase == 1 else 1.0
	_boss_warning = 0.0
	_boss_attack_cooldown = 0.0


func _boss_orbital_lasers() -> void:
	var count := (2 if _difficulty == 0 else 3) + _boss_phase
	var angle_offset := _stage_elapsed * 0.9
	for index in count:
		var angle := angle_offset + TAU * float(index) / float(count)
		var radius := 0.0 if index == 0 else 24.0 + float(index % 2) * 14.0
		var target := _player_pos + Vector2.RIGHT.rotated(angle) * radius
		_laser_zones.append({"pos": target, "warning": 0.9 if _boss_phase < 2 else 0.7, "active": 0.0, "hit": false})
	# The final hidden phase adds a delayed strike at the player's former position.
	if _boss_phase >= 2:
		_laser_zones.append({"pos": _player_pos, "warning": 1.15, "active": 0.0, "hit": false})


func _update_laser_zones(delta: float) -> void:
	for index in range(_laser_zones.size() - 1, -1, -1):
		var zone: Dictionary = _laser_zones[index]
		if float(zone["warning"]) > 0.0:
			zone["warning"] = maxf(0.0, float(zone["warning"]) - delta)
			if float(zone["warning"]) <= 0.0:
				zone["active"] = 0.24
		else:
			zone["active"] = float(zone["active"]) - delta
		if float(zone["active"]) > 0.0 and not bool(zone["hit"]) and _invulnerable <= 0.0 and Vector2(zone["pos"]).distance_to(_player_pos) <= 13.0:
			zone["hit"] = true
			_take_hit()
		if float(zone["active"]) <= 0.0 and float(zone["warning"]) <= 0.0:
			_laser_zones.remove_at(index)
		else:
			_laser_zones[index] = zone
		if _mode != Mode.PLAYING:
			return


func _update_enemy_lasers(delta: float) -> void:
	for index in range(_enemy_lasers.size() - 1, -1, -1):
		var laser: Dictionary = _enemy_lasers[index]
		laser["age"] = float(laser["age"]) + delta
		var length := minf(260.0, float(laser["age"]) * 550.0)
		var start := Vector2(laser["pos"])
		var end := start + Vector2(laser["direction"]) * length
		if not bool(laser["hit"]) and _invulnerable <= 0.0 and Geometry2D.get_closest_point_to_segment(_player_pos, start, end).distance_to(_player_pos) <= 5.0:
			laser["hit"] = true
			_take_hit()
		if float(laser["age"]) >= 0.38:
			_enemy_lasers.remove_at(index)
		else:
			_enemy_lasers[index] = laser
		if _mode != Mode.PLAYING:
			return


func _update_enemy_shots(delta: float) -> void:
	for index in range(_enemy_shots.size() - 1, -1, -1):
		var shot: Dictionary = _enemy_shots[index]
		shot["pos"] = Vector2(shot["pos"]) + Vector2(shot["velocity"]) * delta
		shot["life"] = float(shot["life"]) - delta
		if float(shot["life"]) <= 0.0 or Vector2(shot["pos"]).distance_to(_player_pos) > 350.0:
			_enemy_shots.remove_at(index)
			continue
		if _invulnerable <= 0.0 and Vector2(shot["pos"]).distance_to(_player_pos) < 7.0:
			_enemy_shots.remove_at(index)
			_take_hit()
			if _mode != Mode.PLAYING:
				return
		else:
			_enemy_shots[index] = shot


func _take_hit() -> void:
	_lives -= 1
	_invulnerable = 1.5 if _difficulty == 0 else 1.25
	_damage_flash = 0.25
	_set_feedback("¡GOLPE! -1 VIDA", 1.0)
	if _hit_audio.stream != null:
		_hit_audio.play()
	if _lives <= 0:
		_finish_defeat("LAS SOMBRAS TE ATRAPARON")


func _boss_alive() -> bool:
	for enemy in _enemies:
		if int(enemy["kind"]) == EnemyKind.BOSS:
			return true
	return false


func _boss_position() -> Vector2:
	for enemy in _enemies:
		if int(enemy["kind"]) == EnemyKind.BOSS:
			return Vector2(enemy["pos"])
	return _player_pos


func _apply_upgrade() -> void:
	match _upgrade_selection:
		0:
			if _shot_branch >= 5:
				return
			_shot_branch += 1
		1:
			if _orbital_branch >= 5:
				return
			_orbital_branch += 1
		2:
			if _survival_branch >= 3:
				return
			_survival_branch += 1
			if _survival_branch == 1:
				_max_lives += 1
				_lives = mini(_max_lives, _lives + 1)
	_mode = Mode.PLAYING
	_invulnerable = maxf(_invulnerable, 0.45)


func _branch_capped(branch: int) -> bool:
	match branch:
		0: return _shot_branch >= 5
		1: return _orbital_branch >= 5
		_: return _survival_branch >= 3


func _available_branches() -> Array[int]:
	var available: Array[int] = []
	for branch in 3:
		if not _branch_capped(branch):
			available.append(branch)
	return available


func _step_upgrade(step: int) -> void:
	var available := _available_branches()
	if available.is_empty():
		return
	var current := available.find(_upgrade_selection)
	_upgrade_selection = available[posmod(current + step, available.size())] if current >= 0 else available[0]


func _set_feedback(message: String, duration: float) -> void:
	_feedback = message
	_feedback_time = duration


func _finish_victory() -> void:
	_mode = Mode.VICTORY
	var poster_id := NORMAL_POSTER_ID if _difficulty == 0 else HARD_POSTER_ID
	if _manager and not _manager.is_collectible_found(poster_id):
		_manager.collect_collectible(poster_id, null, "Cartel desbloqueado", "Pulsa Tab para verlo")
		_feedback = "CARTEL DESBLOQUEADO"
	else:
		_feedback = "CARTEL YA OBTENIDO"


func _finish_defeat(message: String) -> void:
	_mode = Mode.DEFEAT
	_feedback = message
	_defeat_selection = 0


func _has_blocking_modal() -> bool:
	if get_tree().paused:
		return true
	for group_name in ["arcade_minigame", "upgrade_menu", "tool_shop_panel", "pause_menu"]:
		var modal := get_tree().get_first_node_in_group(group_name)
		if modal and modal.has_method("is_open") and modal.is_open():
			return true
	return false


func _set_gameplay_hud_visible(visible: bool) -> void:
	var hud := get_tree().get_first_node_in_group("gameplay_hud")
	if hud and hud.has_method("set_gameplay_hud_visible"):
		hud.set_gameplay_hud_visible(visible)


func _make_music_loop() -> AudioStreamWAV:
	var sample_rate := 11025
	var melody := [220.0, 0.0, 261.63, 293.66, 220.0, 174.61, 196.0, 0.0,
		220.0, 261.63, 329.63, 293.66, 246.94, 196.0, 174.61, 0.0,
		220.0, 0.0, 261.63, 349.23, 329.63, 293.66, 261.63, 0.0,
		196.0, 220.0, 246.94, 261.63, 220.0, 174.61, 164.81, 0.0]
	var samples_per_note := int(sample_rate * 0.18)
	var data := PackedByteArray()
	for note_index in melody.size():
		var note: float = melody[note_index]
		var bass: float = [110.0, 87.31, 98.0, 82.41][int(note_index / 8)]
		for sample_index in samples_per_note:
			var t := float(sample_index) / float(sample_rate)
			var envelope := clampf(1.0 - float(sample_index) / float(samples_per_note), 0.22, 1.0)
			var lead := (0.11 if sin(TAU * note * t) >= 0.0 else -0.11) if note > 0.0 else 0.0
			var low := 0.065 * (2.0 * fmod(bass * t, 1.0) - 1.0)
			var sample := int(clampf((lead + low) * envelope, -0.9, 0.9) * 32767.0)
			data.append(sample & 0xff)
			data.append((sample >> 8) & 0xff)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = melody.size() * samples_per_note
	return stream


func _make_approved_music_loop() -> AudioStreamWAV:
	var stream := MUSIC_STREAM.duplicate() as AudioStreamWAV
	stream.loop_begin = 0
	stream.loop_end = maxi(1, roundi(stream.get_length() * stream.mix_rate))
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


class SurvivorScreen extends Control:
	const PIXEL_GLYPHS := ArcadeReelRescue.ArcadeReelScreen.PIXEL_GLYPHS
	const BLACK := Color("0d101a")
	const NAVY := Color("17233a")
	const FLOOR := Color("263550")
	const WINE := Color("793246")
	const RED := Color("d85d68")
	const CREAM := Color("f1dfb3")
	const GOLD := Color("efba5d")
	const CYAN := Color("65dad3")
	const VIOLET := Color("aa82d2")
	const STUN_BLUE := Color("246bf5")
	var controller: ArcadeLastUsherSurvivor

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		if controller == null:
			return
		var scale_factor := maxf(1.0, floorf(minf(size.x / LOGICAL_SIZE.x, size.y / LOGICAL_SIZE.y)))
		var offset := (size - LOGICAL_SIZE * scale_factor) * 0.5
		draw_rect(Rect2(Vector2.ZERO, size), BLACK)
		draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
		match controller._mode:
			Mode.BOOT, Mode.EXIT: _draw_boot()
			Mode.MENU: _draw_menu()
			Mode.HOW_TO: _draw_manual()
			Mode.PLAYING: _draw_game()
			Mode.UPGRADE: _draw_upgrade()
			Mode.VICTORY: _draw_outcome(true)
			Mode.DEFEAT: _draw_outcome(false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _text(value: String, at: Vector2, pixel: float, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> void:
		var label := value.to_upper().replace("·", ".")
		var x := at.x - _text_width(label, pixel) * 0.5 if alignment == HORIZONTAL_ALIGNMENT_CENTER else at.x
		var top := at.y - 5.0 * pixel
		for character in label:
			var glyph: PackedStringArray = PIXEL_GLYPHS.get(character, PIXEL_GLYPHS["?"])
			var glyph_top := top - float(glyph.size() - 5) * pixel
			for row in glyph.size():
				for column in glyph[row].length():
					if glyph[row][column] == "1":
						draw_rect(Rect2(x + column * pixel, glyph_top + row * pixel, pixel, pixel), color)
			x += 4.0 * pixel

	func _text_width(value: String, pixel: float) -> float:
		return maxf(0.0, value.length() * 4.0 * pixel - pixel)

	func _base() -> void:
		draw_rect(Rect2(Vector2.ZERO, LOGICAL_SIZE), NAVY)
		for index in 48:
			draw_rect(Rect2(float(posmod(index * 73 + 17, 370) + 7), float(posmod(index * 41 + 31, 200) + 7), 1, 1), Color(CYAN, 0.22))
		draw_rect(Rect2(4, 4, 376, 208), WINE, false, 3.0)
		draw_rect(Rect2(8, 8, 368, 200), CYAN, false, 1.0)
		for y in range(12, 208, 4):
			draw_line(Vector2(9, y), Vector2(375, y), Color(0.0, 0.0, 0.0, 0.13), 1.0)
		for corner in [Vector2(10, 10), Vector2(368, 10), Vector2(10, 200), Vector2(368, 200)]:
			draw_rect(Rect2(corner, Vector2(6, 6)), GOLD)

	func _sprite(texture: Texture2D, position: Vector2, sprite_size: float, modulate := Color.WHITE, stretch := Vector2.ONE) -> void:
		var extent := Vector2(sprite_size, sprite_size) * stretch
		draw_texture_rect(texture, Rect2(position - extent * 0.5, extent), false, modulate)

	func _icon(kind: String, center: Vector2, color := GOLD) -> void:
		match kind:
			"heart":
				draw_rect(Rect2(center + Vector2(-5, -4), Vector2(4, 3)), color)
				draw_rect(Rect2(center + Vector2(1, -4), Vector2(4, 3)), color)
				draw_rect(Rect2(center + Vector2(-6, -1), Vector2(12, 3)), color)
				draw_rect(Rect2(center + Vector2(-4, 2), Vector2(8, 2)), color)
				draw_rect(Rect2(center + Vector2(-2, 4), Vector2(4, 2)), color)
				draw_rect(Rect2(center + Vector2(-3, -3), Vector2(2, 1)), CREAM if color == RED else NAVY)
			"heart_small":
				draw_rect(Rect2(center + Vector2(-4, -3), Vector2(3, 2)), color)
				draw_rect(Rect2(center + Vector2(1, -3), Vector2(3, 2)), color)
				draw_rect(Rect2(center + Vector2(-5, -1), Vector2(10, 2)), color)
				draw_rect(Rect2(center + Vector2(-3, 1), Vector2(6, 2)), color)
				draw_rect(Rect2(center + Vector2(-1, 3), Vector2(2, 2)), color)
				draw_rect(Rect2(center + Vector2(-3, -2), Vector2.ONE), CREAM if color == RED else NAVY)
			"film":
				draw_rect(Rect2(center - Vector2(6, 5), Vector2(12, 10)), color)
				draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), BLACK)
				for hole_x in [-5, 4]:
					for hole_y in [-4, 3]:
						draw_rect(Rect2(center + Vector2(hole_x, hole_y), Vector2.ONE), BLACK)
			"film_pickup":
				draw_rect(Rect2(center + Vector2(-4, -3), Vector2(8, 7)), color)
				draw_rect(Rect2(center + Vector2(-2, -2), Vector2(4, 4)), BLACK)
				for hole_x in [-3, 2]:
					for hole_y in [-2, 2]:
						draw_rect(Rect2(center + Vector2(hole_x, hole_y), Vector2.ONE), BLACK)
			"dash":
				draw_rect(Rect2(center + Vector2(-3, -5), Vector2(4, 6)), color)
				draw_rect(Rect2(center + Vector2(-4, 1), Vector2(9, 3)), color)
				draw_rect(Rect2(center + Vector2(3, -1), Vector2(3, 4)), color)
				draw_line(center + Vector2(-1, -2), center + Vector2(4, 1), color, 2.0)
				draw_line(center + Vector2(-7, -2), center + Vector2(-5, -2), color)
				draw_line(center + Vector2(-8, 1), center + Vector2(-6, 1), color)
			"orbit":
				draw_arc(center, 5.0, 0.0, TAU, 16, color, 1.0)
				draw_circle(center, 1.5, color)
				draw_circle(center + Vector2(4, -3), 2.0, color)
				draw_circle(center + Vector2(-4, 3), 1.5, color)
			"orbit_reel":
				draw_circle(center, 4.0, color)
				draw_circle(center, 1.4, BLACK)
				draw_circle(center + Vector2(-2, -1), 0.8, FLOOR)
				draw_circle(center + Vector2(2, 1), 0.8, FLOOR)
			"magnet":
				draw_arc(center, 4.0, 0.0, PI, 8, color, 2.0)
				draw_line(center + Vector2(-4, 0), center + Vector2(-4, -4), color, 2.0)
				draw_line(center + Vector2(4, 0), center + Vector2(4, -4), color, 2.0)
				draw_rect(Rect2(center + Vector2(-5, -5), Vector2(2, 2)), RED)
				draw_rect(Rect2(center + Vector2(3, -5), Vector2(2, 2)), RED)
			"bolt":
				draw_colored_polygon(PackedVector2Array([center + Vector2(0, -6), center + Vector2(-3, 0), center, center + Vector2(-1, 6), center + Vector2(4, -1), center + Vector2(1, -1)]), color)
			"shot":
				draw_line(center + Vector2(-6, 1), center + Vector2(4, -1), color, 1.0)
				draw_circle(center + Vector2(4, -1), 1.5, CYAN)
				draw_line(center + Vector2(-5, -2), center + Vector2(-2, -2), color)

	func _upgrade_icon(branch: int, center: Vector2) -> void:
		match branch:
			0:
				draw_line(center + Vector2(-11, -5), center + Vector2(-6, -5), RED, 1.0)
				draw_line(center + Vector2(-13, 0), center + Vector2(-6, 0), RED, 1.0)
				draw_line(center + Vector2(-11, 5), center + Vector2(-6, 5), RED, 1.0)
				draw_rect(Rect2(center + Vector2(-5, -4), Vector2(10, 8)), GOLD)
				draw_colored_polygon(PackedVector2Array([center + Vector2(5, -4), center + Vector2(11, 0), center + Vector2(5, 4)]), CREAM)
				draw_rect(Rect2(center + Vector2(-5, -2), Vector2(2, 4)), WINE)
			1:
				draw_arc(center, 9.0, 0.0, TAU, 20, CYAN, 1.5)
				draw_circle(center, 2.5, CREAM)
				for angle in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
					draw_circle(center + Vector2.RIGHT.rotated(angle) * 9.0, 2.5, CYAN)
			2:
				draw_colored_polygon(PackedVector2Array([center + Vector2(-10, -4), center + Vector2(-5, -9), center, center + Vector2(5, -9), center + Vector2(10, -4), center + Vector2(10, 1), center + Vector2(0, 10), center + Vector2(-10, 1)]), GOLD)
				draw_rect(Rect2(center + Vector2(-1, -3), Vector2(2, 8)), WINE)
				draw_rect(Rect2(center + Vector2(-4, 0), Vector2(8, 2)), WINE)

	func _draw_boot() -> void:
		_base()
		_text("PALACE ENTERTAINMENT SYSTEM", Vector2(192, 70), 3, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		_text("INSERTANDO MONEDA...", Vector2(192, 102), 2, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		draw_rect(Rect2(72, 122, 240, 8), BLACK)
		draw_rect(Rect2(72, 122, 240.0 * clampf(controller._transition / 0.35, 0.0, 1.0), 8), GOLD)

	func _draw_menu() -> void:
		_base()
		draw_rect(Rect2(24, 22, 336, 55), BLACK)
		draw_rect(Rect2(26, 24, 332, 51), WINE, false, 2.0)
		for bulb in 16:
			draw_circle(Vector2(37 + bulb * 20, 28), 2.0, GOLD if (bulb + int(controller._animation * 6.0)) % 4 != 0 else RED)
		_text("PALACE ARCADE  1992", Vector2(192, 42), 1, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		_text("EL ÚLTIMO ACOMODADOR", Vector2(192, 66), 3, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		draw_circle(Vector2(96, 132), 33, Color(CYAN, 0.10))
		_sprite(USHER_TEXTURE, Vector2(92, 130), 36)
		_sprite(SHADOW_TEXTURE, Vector2(164, 125), 27)
		var options := ["NORMAL", "DIFÍCIL", "CÓMO JUGAR"]
		var box_width := 147.0
		for option in options:
			box_width = maxf(box_width, _text_width("> " + option, 2) + 20.0)
		for index in options.size():
			var y := 110.0 + index * 25.0
			var selected := controller._menu_selection == index
			if selected:
				var box := Rect2(278.0 - box_width * 0.5, y - 14.0, box_width, 19.0)
				draw_rect(box, WINE)
				draw_rect(box, GOLD, false, 1.0)
			_text(("> " if selected else "  ") + options[index], Vector2(278, y), 2, GOLD if selected else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		draw_rect(Rect2(27, 187, 330, 1), CYAN)
		_text("A/D ELEGIR   E/ESPACIO CONFIRMAR   ESC SALIR", Vector2(192, 202), 1, CREAM, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_manual() -> void:
		_base()
		_text("MANUAL DEL ACOMODADOR", Vector2(192, 34), 2, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		draw_rect(Rect2(24, 45, 336, 135), BLACK)
		draw_rect(Rect2(26, 47, 332, 131), CYAN, false, 1.0)
		var lines := [
			"WASD/FLECHAS: MAPA ABIERTO",
			"DISPARAS SOLO AL ENEMIGO MÁS CERCANO",
			"CADA CINTA COMPLETA: ELIGE UNA MEJORA",
			"TRES RAMAS: TIRO, ORBITA, VIDA",
			"ESPACIO: DASH SI LO DESBLOQUEAS",
			"MEJORA UNA RAMA HASTA EVOLUCIONAR",
			"ESQUIVA LOS DISPAROS DEL REY",
			"RESISTE Y VENCE AL JEFE FINAL",
		]
		for index in lines.size():
			var y := 62.0 + index * 15.0
			_draw_manual_icon(index, Vector2(45, y))
			_text(lines[index], Vector2(63, y + 2), 1, CYAN if index == 7 else CREAM)
		_text("E/ESPACIO VOLVER     ESC SALIR", Vector2(192, 201), 1, GOLD, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_manual_icon(kind: int, center: Vector2) -> void:
		draw_rect(Rect2(center - Vector2(7, 6), Vector2(14, 12)), FLOOR)
		draw_rect(Rect2(center - Vector2(7, 6), Vector2(14, 12)), CYAN, false, 1.0)
		match kind:
			0:
				_icon("dash", center)
			1:
				_icon("shot", center)
			2:
				_icon("film", center)
			3:
				_icon("orbit", center)
			4:
				_icon("dash", center)
			5:
				_icon("bolt", center, CYAN)
			6:
				draw_circle(center, 3.0, RED)
				draw_circle(center, 1.0, CREAM)
			7:
				_sprite(BOSS_TEXTURE, center, 11)

	func _draw_game() -> void:
		_base()
		_draw_arena()
		draw_rect(Rect2(12, 9, 360, 28), BLACK)
		_text("ACTO %d/4" % (controller._stage + 1), Vector2(19, 22), 2, GOLD)
		for life in controller._max_lives:
			_icon("heart_small", Vector2(90 + life * 11, 19), RED if life < controller._lives else FLOOR)
		_text("NV %02d" % controller._level, Vector2(161, 22), 2, CYAN)
		_text("PTS %06d" % controller._score, Vector2(220, 22), 1, CREAM)
		_text("%02d:%02d" % [ceili(controller._stage_time_left) / 60, ceili(controller._stage_time_left) % 60], Vector2(314, 22), 2, CREAM)
		var status := controller._feedback if controller._feedback_time > 0.0 else "WASD MOVER   AUTO FUEGO   LLENA CINTAS"
		_text(status, Vector2(192, 35), 1, GOLD if controller._feedback_time > 0.0 else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		draw_rect(Rect2(12, 188, 360, 20), BLACK)
		for icon_x in [121.0, 237.0]:
			draw_rect(Rect2(icon_x, 191, 16, 14), FLOOR)
			draw_rect(Rect2(icon_x, 191, 16, 14), CYAN, false, 1.0)
		if controller._survival_branch >= 3:
			draw_rect(Rect2(14, 191, 16, 14), FLOOR)
			draw_rect(Rect2(14, 191, 16, 14), GOLD, false, 1.0)
			_icon("dash", Vector2(22, 198), GOLD)
			_text("DASH LISTO" if controller._dash_cooldown <= 0.0 else "DASH %dS" % ceili(controller._dash_cooldown), Vector2(32, 202), 1, GOLD)
		_icon("orbit", Vector2(129, 198), CYAN)
		_text("ORBITA %d" % controller._orbital_branch, Vector2(139, 202), 1, CYAN)
		_icon("film", Vector2(245, 198), CREAM)
		_text("CINTA", Vector2(254, 202), 1, CREAM)
		draw_rect(Rect2(297, 195, 62, 6), FLOOR)
		draw_rect(Rect2(298, 196, 60.0 * float(controller._xp) / float(controller._xp_goal), 4), GOLD)
		draw_rect(Rect2(297, 195, 62, 6), CREAM, false, 1.0)
		if controller._banner_time > 0.0:
			if controller._stage == 0:
				draw_rect(Rect2(49, 86, 286, 43), BLACK)
				draw_rect(Rect2(49, 86, 286, 43), CYAN, false, 2.0)
				_text("ACTO %d: %s" % [controller._stage + 1, STAGE_NAMES[controller._stage]], Vector2(192, 106), 2, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
				_text("SOBREVIVE. EL REY LLEGA EN EL ACTO 4", Vector2(192, 121), 1, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
			else:
				_text("ACTO %d: %s" % [controller._stage + 1, STAGE_NAMES[controller._stage]], Vector2(192, 64), 1.5, GOLD, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_arena() -> void:
		draw_rect(ARENA, BLACK)
		var camera := controller._player_pos
		var first_x := int(floor((camera.x - 180.0) / 16.0))
		var first_y := int(floor((camera.y - 78.0) / 16.0))
		for column in 24:
			var x := float((first_x + column) * 16)
			var screen_x := controller._world_to_screen(Vector2(x, 0)).x
			if screen_x >= ARENA.position.x and screen_x <= ARENA.end.x:
				draw_line(Vector2(screen_x, ARENA.position.y), Vector2(screen_x, ARENA.end.y), Color(CYAN, 0.06))
		for row in 11:
			var y := float((first_y + row) * 16)
			var screen_y := controller._world_to_screen(Vector2(0, y)).y
			if screen_y >= ARENA.position.y and screen_y <= ARENA.end.y:
				draw_line(Vector2(ARENA.position.x, screen_y), Vector2(ARENA.end.x, screen_y), Color(CYAN, 0.06))
		var first_decor_x := int(floor((camera.x - 220.0) / 58.0))
		var first_decor_y := int(floor((camera.y - 110.0) / 45.0))
		for row in 6:
			for column in 9:
				var world := Vector2((first_decor_x + column) * 58 + 14, (first_decor_y + row) * 45 + 9)
				var position := controller._world_to_screen(world)
				if ARENA.grow(-8.0).has_point(position):
					draw_rect(Rect2(position, Vector2(13, 5)), Color(WINE, 0.22))
		draw_rect(ARENA, CYAN, false, 1.0)
		if controller._stage >= 2 and fmod(controller._stage_elapsed, 22.0) > 18.0:
			draw_rect(ARENA.grow(-1.0), Color(0.02, 0.01, 0.08, 0.28))
		for pickup in controller._pickups:
			var pos := controller._world_to_screen(Vector2(pickup["pos"]))
			if not ARENA.grow(-5.0).has_point(pos):
				continue
			var kind := String(pickup["kind"])
			var color := GOLD if kind == "film" else (RED if kind == "heart" else CYAN)
			_icon("film_pickup" if kind == "film" else kind, pos, color)
		for shot in controller._shots:
			var pos := controller._world_to_screen(Vector2(shot["pos"]))
			if ARENA.grow(-3.0).has_point(pos):
				var tail := Vector2(shot["velocity"]).normalized() * 4.0
				draw_line(pos - tail, pos, CREAM, 1.0 if float(shot.get("size", 1.0)) <= 1.0 else 1.5)
				draw_circle(pos, float(shot.get("size", 1.0)), CYAN)
		for shot in controller._enemy_shots:
			var pos := controller._world_to_screen(Vector2(shot["pos"]))
			if ARENA.grow(-4.0).has_point(pos):
				draw_circle(pos, 2.0, RED)
		for zone in controller._laser_zones:
			var pos := controller._world_to_screen(Vector2(zone["pos"]))
			if not ARENA.grow(-14.0).has_point(pos):
				continue
			if float(zone["warning"]) > 0.0:
				draw_circle(pos, 14.0, Color(RED, 0.13))
				draw_arc(pos, 13.0, 0.0, TAU, 24, RED, 1.5)
				_text("!", pos + Vector2(0, 3), 2, RED, HORIZONTAL_ALIGNMENT_CENTER)
			else:
				draw_circle(pos, 13.0, Color(RED, 0.42))
				draw_line(Vector2(pos.x, ARENA.position.y + 2.0), pos, Color(1.0, 0.21, 0.20, 0.8), 5.0)
				draw_line(Vector2(pos.x, ARENA.position.y + 2.0), pos, CREAM, 1.0)
		for laser in controller._enemy_lasers:
			var begin := controller._world_to_screen(Vector2(laser["pos"]))
			var length := minf(260.0, float(laser["age"]) * 550.0)
			var end := begin + Vector2(laser["direction"]) * length
			draw_line(begin, end, Color(RED, 0.35), 5.0)
			draw_line(begin, end, RED, 2.0)
		for effect in controller._death_effects:
			var pos := controller._world_to_screen(Vector2(effect["pos"]))
			if not ARENA.grow(-16.0).has_point(pos):
				continue
			var boss := int(effect["kind"]) == EnemyKind.BOSS
			var texture: Texture2D = BOSS_TEXTURE if boss else (PATROLLER_TEXTURE if int(effect["kind"]) == EnemyKind.PATROLLER else (SPRINTER_TEXTURE if int(effect["kind"]) == EnemyKind.SPRINTER else SHADOW_TEXTURE))
			var fade := clampf(float(effect["life"]) / 0.28, 0.0, 1.0)
			_sprite(texture, pos, (30.0 if boss else 12.0) * (1.0 + (1.0 - fade) * 0.16), Color(1.0, 1.0, 1.0, fade * 0.8))
		for enemy in controller._enemies:
			var pos := controller._world_to_screen(Vector2(enemy["pos"]))
			if int(enemy["kind"]) == EnemyKind.PATROLLER and float(enemy.get("laser_warning", 0.0)) > 0.0:
				# Aim is locked when the warning begins. Draw it around that point even
				# when the shooter itself is outside the narrow arcade viewport.
				var target := controller._world_to_screen(Vector2(enemy.get("laser_target", controller._player_pos)))
				if ARENA.grow(-7.0).has_point(target):
					var direction := Vector2(enemy["laser_direction"])
					var back_length := minf(90.0, Vector2(enemy["pos"]).distance_to(Vector2(enemy.get("laser_target", controller._player_pos))))
					var safe_arena := ARENA.grow(-3.0)
					var warning_start := (target - direction * back_length).clamp(safe_arena.position, safe_arena.end)
					var warning_end := (target + direction * 55.0).clamp(safe_arena.position, safe_arena.end)
					draw_line(warning_start, warning_end, Color(1.0, 0.12, 0.12, 0.22), 3.0)
					draw_line(warning_start, warning_end, Color(1.0, 0.32, 0.27, 0.70), 1.0)
					draw_arc(target, 5.0 + sin(controller._animation * 15.0) * 0.7, 0.0, TAU, 12, RED, 1.0)
					draw_circle(target, 1.0, RED)
			if not ARENA.grow(-16.0).has_point(pos):
				continue
			var boss := int(enemy["kind"]) == EnemyKind.BOSS
			var tint := STUN_BLUE if float(enemy["stun"]) > 0.0 else (CREAM if float(enemy["hit_flash"]) > 0.0 else Color.WHITE)
			if int(enemy["kind"]) == EnemyKind.SHADOW and float(enemy.get("ghost_fade", 0.0)) > 0.0:
				tint.a = clampf(absf(float(enemy["ghost_fade"]) - 0.22) / 0.22, 0.05, 1.0)
			if boss and controller._boss_charge > 0.0:
				tint = Color(1.0, 0.30, 0.28)
			var texture: Texture2D = BOSS_TEXTURE if boss else (PATROLLER_TEXTURE if int(enemy["kind"]) == EnemyKind.PATROLLER else (SPRINTER_TEXTURE if int(enemy["kind"]) == EnemyKind.SPRINTER else SHADOW_TEXTURE))
			var step := sin(float(enemy["phase"]) * (12.0 if int(enemy["kind"]) == EnemyKind.SPRINTER else 8.0))
			var stretch := Vector2(1.0 + step * 0.06, 1.0 - step * 0.08)
			if boss and controller._boss_charge > 0.0:
				var pulse := sin(controller._animation * 21.0) * 0.17
				stretch = Vector2(1.0 + pulse, 1.0 - pulse)
			_sprite(texture, pos + Vector2(0, step * 0.7), 30.0 if boss else (13.0 if int(enemy["kind"]) == EnemyKind.SPRINTER else 12.0), tint, stretch)
			if float(enemy["hit_flash"]) > 0.0:
				draw_line(pos + Vector2(-6, -5), pos + Vector2(-9, -7), GOLD, 1.0)
				draw_line(pos + Vector2(5, 4), pos + Vector2(8, 6), GOLD, 1.0)
			if boss:
				draw_rect(Rect2(pos + Vector2(-17, -20), Vector2(34, 3)), FLOOR)
				var max_hp := float(enemy.get("max_hp", 38 if controller._difficulty == 0 else 56))
				draw_rect(Rect2(pos + Vector2(-17, -20), Vector2(34.0 * float(enemy["hp"]) / max_hp, 3)), RED)
		if controller._boss_warning > 0.0 and controller._boss_alive():
			var boss_pos := controller._world_to_screen(controller._boss_position())
			if ARENA.grow(-25.0).has_point(boss_pos):
				draw_arc(boss_pos, 24.0 + sin(controller._animation * 15.0) * 2.0, 0.0, TAU, 32, RED, 1.0)
		for reel in controller._orbit_positions():
			var reel_pos := controller._world_to_screen(reel)
			_icon("orbit_reel", reel_pos, CYAN)
		for number in controller._damage_numbers:
			var number_pos := controller._world_to_screen(Vector2(number["pos"]))
			if ARENA.grow(-5.0).has_point(number_pos):
				_text("-%d" % int(number["damage"]), number_pos, 0.7, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		var pose := Vector2.ONE
		var bob := 0.0
		if controller._dash_time > 0.0:
			pose = Vector2(1.19, 0.82) if absf(controller._facing.x) > absf(controller._facing.y) else Vector2(0.82, 1.19)
			_sprite(USHER_TEXTURE, CAMERA_CENTER - controller._facing * 13.0, 17.0, Color(0.4, 0.85, 0.9, 0.25), pose)
			_sprite(USHER_TEXTURE, CAMERA_CENTER - controller._facing * 7.0, 17.0, Color(0.4, 0.85, 0.9, 0.4), pose)
		elif controller._walking:
			var step := sin(controller._animation * 15.0)
			pose = Vector2(1.0 + step * 0.07, 1.0 - step * 0.06)
			bob = absf(step) * 1.0
		else:
			var breath := sin(controller._animation * 3.2)
			pose = Vector2(1.0 - breath * 0.02, 1.0 + breath * 0.03)
			bob = breath * 0.3
		_sprite(USHER_TEXTURE, CAMERA_CENTER + Vector2(0, bob), 17.0, Color(1.0, 1.0, 1.0, 0.55) if controller._invulnerable > 0.0 and int(controller._animation * 14.0) % 2 == 1 else Color.WHITE, pose)
		if controller._damage_flash > 0.0:
			draw_rect(ARENA.grow(-2.0), Color(RED, controller._damage_flash * 0.35), false, 3.0)

	func _draw_upgrade() -> void:
		_base()
		_text("CINTA COMPLETA  NV %02d" % controller._level, Vector2(192, 39), 3, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		_text("ELIGE UNA RAMA PARA MEJORAR", Vector2(192, 62), 2, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		var levels := [controller._shot_branch, controller._orbital_branch, controller._survival_branch]
		var maximums := [5, 5, 3]
		var names := ["DISPARO", "ORBITAL", "VIDA"]
		var descriptions := [
			["CADENCIA +", "DAÑO +", "DOBLE TIRO", "CUÁDRUPLE", "BALA EVOLUCIONA"],
			["UNA BOBINA", "DOS BOBINAS", "TRES BOBINAS", "DAÑO +", "ÓRBITA EVOLUCIONA"],
			["VIDA MÁXIMA +1", "VELOCIDAD +", "DESBLOQUEA DASH"]
		]
		var available := controller._available_branches()
		var card_width := 111.0
		var gap := 4.0
		var total_width := available.size() * card_width + maxi(0, available.size() - 1) * gap
		var start_x := (LOGICAL_SIZE.x - total_width) * 0.5
		for display_index in available.size():
			var branch: int = available[display_index]
			var x := start_x + display_index * (card_width + gap)
			var selected := controller._upgrade_selection == branch
			var level: int = levels[branch]
			var maximum: int = maximums[branch]
			draw_rect(Rect2(x, 82, card_width, 91), WINE if selected else BLACK)
			draw_rect(Rect2(x, 82, card_width, 91), GOLD if selected else CYAN, false, 2.0 if selected else 1.0)
			draw_circle(Vector2(x + 55, 101), 15.0, Color(FLOOR, 0.8))
			_upgrade_icon(branch, Vector2(x + 55, 101))
			_text(names[branch], Vector2(x + 55, 130), 2, GOLD if selected else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
			_text("%d/%d" % [level, maximum], Vector2(x + 55, 142), 1, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
			var pip_width := maximum * 5.0 + (maximum - 1) * 2.0
			var pip_x := x + 55.0 - pip_width * 0.5
			for pip in maximum:
				draw_rect(Rect2(pip_x + pip * 7.0, 147, 5, 2), CYAN if pip < level else FLOOR)
			_text(descriptions[branch][level], Vector2(x + 55, 162), 1, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		_text("A/D ELEGIR   E/ESPACIO CONTINUAR", Vector2(192, 197), 1, CREAM, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_outcome(victory: bool) -> void:
		_base()
		_sprite(USHER_TEXTURE, Vector2(55, 105), 34)
		_sprite(BOSS_TEXTURE, Vector2(330, 105), 42, STUN_BLUE if victory else Color.WHITE)
		_text("¡CINE SALVADO!" if victory else "FIN DE LA FUNCIÓN", Vector2(192, 55), 3, GOLD if victory else RED, HORIZONTAL_ALIGNMENT_CENTER)
		_text("PUNTOS %07d" % controller._score, Vector2(192, 84), 1, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		if victory:
			_text(controller._feedback, Vector2(192, 119), 2, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
			_text("E/ESPACIO: OTRA DIFICULTAD", Vector2(192, 163), 1, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			_text(controller._feedback, Vector2(192, 109), 1, RED, HORIZONTAL_ALIGNMENT_CENTER)
			var options := ["REINTENTAR", "ELEGIR DIFICULTAD", "SALIR"]
			var box_width := 150.0
			for option in options:
				box_width = maxf(box_width, _text_width("> " + option, 1) + 20.0)
			for index in options.size():
				var y := 133.0 + index * 20.0
				var selected := controller._defeat_selection == index
				if selected:
					var box := Rect2(192.0 - box_width * 0.5, y - 10.0, box_width, 15.0)
					draw_rect(box, WINE)
					draw_rect(box, GOLD, false, 1.0)
				_text(("> " if selected else "  ") + options[index], Vector2(192, y), 1, GOLD if selected else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		_text("ESC SALIR", Vector2(192, 201), 1, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
