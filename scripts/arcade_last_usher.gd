class_name ArcadeLastUsher
extends CanvasLayer

# A self-contained second cabinet. It deliberately reuses the existing modal,
# collectible and save contracts without changing the first arcade's game.
const LOGICAL_SIZE := Vector2(384.0, 216.0)
const GRID_W := 24
const GRID_H := 12
const TILE := 12
const FIELD_ORIGIN := Vector2(48.0, 41.0)
const EXIT_CELL := Vector2i(12, 1)
const START_CELL := Vector2i(12, 10)
const BOSS_START_CELL := Vector2i(12, 2)
const PROJECTORS: Array[Vector2i] = [Vector2i(4, 5), Vector2i(12, 5), Vector2i(20, 5)]
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const NORMAL_POSTER_ID := "arcade_second_game_normal_poster"
const HARD_POSTER_ID := "arcade_second_game_hard_poster"
const NORMAL_MOVE_INTERVAL := 0.155
const HARD_MOVE_INTERVAL := 0.17
const SELECT_STREAM := preload("res://assets/audio/sfx/arcade/arcade_select_03.wav")
const PICKUP_STREAM := preload("res://assets/audio/sfx/arcade/arcade_repair_03.wav")
const HIT_STREAM := preload("res://assets/audio/sfx/arcade/arcade_error_03.wav")

enum Mode { CLOSED, BOOT, MENU, HOW_TO, PLAYING, UPGRADE, VICTORY, DEFEAT, EXIT }
enum EnemyKind { SHADOW, PATROLLER, SPRINTER, BOSS }

var _mode := Mode.CLOSED
var _screen: LastUsherScreen
var _manager: Node
var _music: AudioStreamPlayer
var _select_audio: AudioStreamPlayer
var _pickup_audio: AudioStreamPlayer
var _hit_audio: AudioStreamPlayer
var _stored_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _paused_before_open := false
var _transition := 0.0
var _animation := 0.0
var _menu_selection := 0
var _upgrade_selection := 0
var _defeat_selection := 0
var _difficulty := 0
var _stage := 0
var _stage_elapsed := 0.0
var _stage_time_left := 0.0
var _banner_time := 0.0
var _feedback := ""
var _feedback_time := 0.0
var _score := 0
var _combo := 0
var _last_pickup_time := -10.0
var _lives := 5
var _max_lives := 5
var _battery := 100.0
var _max_battery := 100.0
var _battery_regen := 8.0
var _speed_upgrade := 0
var _dash_cooldown := 0.0
var _move_cooldown := 0.0
var _flash_cooldown := 0.0
var _switch_cooldown := 0.0
var _invulnerable := 0.0
var _flash_time := 0.0
var _dash_effect_time := 0.0
var _light_time := 0.0
var _active_projector := Vector2i(-1, -1)
var _reinforcement_time := 0.0
var _player_cell := START_CELL
var _facing := Vector2i.UP
var _tickets: Array[Vector2i] = []
var _powerups: Array[Dictionary] = []
var _enemies: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("arcade_usher_minigame")
	_screen = LastUsherScreen.new()
	_screen.controller = self
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.visible = false
	add_child(_screen)
	_music = AudioStreamPlayer.new()
	_music.name = "LastUsherChiptune"
	_music.stream = _make_music_loop()
	_music.volume_db = -27.0
	_music.bus = "Machines"
	add_child(_music)
	_select_audio = _add_audio("LastUsherSelect", SELECT_STREAM, -11.0)
	_pickup_audio = _add_audio("LastUsherPickup", PICKUP_STREAM, -9.0)
	_hit_audio = _add_audio("LastUsherHit", HIT_STREAM, -10.0)


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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
		_update_game(delta)
	_screen.queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_open() or get_viewport().is_input_handled():
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		_mode = Mode.EXIT
		_transition = 0.0
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.BOOT or _mode == Mode.EXIT:
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	var direction := _direction_from_event(event)
	if _mode == Mode.MENU:
		if direction != Vector2i.ZERO:
			_menu_selection = posmod(_menu_selection + (1 if direction == Vector2i.DOWN or direction == Vector2i.RIGHT else -1), 3)
			_select_audio.play()
		elif _is_confirm(event):
			if _menu_selection == 2:
				_mode = Mode.HOW_TO
			else:
				_start_run(_menu_selection)
	elif _mode == Mode.HOW_TO:
		if _is_confirm(event):
			_mode = Mode.MENU
	elif _mode == Mode.PLAYING:
		if _banner_time <= 0.0:
			if direction != Vector2i.ZERO:
				_try_move(direction)
			elif event.is_action_pressed("interact"):
				_use_flashlight()
			elif event.is_action_pressed("jump"):
				_dash()
	elif _mode == Mode.UPGRADE:
		if direction != Vector2i.ZERO:
			_upgrade_selection = posmod(_upgrade_selection + (1 if direction == Vector2i.DOWN or direction == Vector2i.RIGHT else -1), 3)
			_select_audio.play()
		elif _is_confirm(event):
			_apply_upgrade()
	elif _mode == Mode.VICTORY:
		if _is_confirm(event):
			_mode = Mode.MENU
	elif _mode == Mode.DEFEAT:
		if direction != Vector2i.ZERO:
			_defeat_selection = posmod(_defeat_selection + (1 if direction == Vector2i.DOWN or direction == Vector2i.RIGHT else -1), 3)
			_select_audio.play()
		elif _is_confirm(event):
			if _defeat_selection == 0:
				_start_run(_difficulty)
			elif _defeat_selection == 1:
				_mode = Mode.MENU
			else:
				close_arcade()
	get_viewport().set_input_as_handled()


func _direction_from_event(event: InputEvent) -> Vector2i:
	if event.is_action_pressed("move_forward"):
		return Vector2i.UP
	if event.is_action_pressed("move_backward"):
		return Vector2i.DOWN
	if event.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if event.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP: return Vector2i.UP
			KEY_DOWN: return Vector2i.DOWN
			KEY_LEFT: return Vector2i.LEFT
			KEY_RIGHT: return Vector2i.RIGHT
	return Vector2i.ZERO


func _held_direction() -> Vector2i:
	# Keep the most recently pressed direction while it remains held. Without
	# this, holding W then tapping D silently turns the lantern back upwards.
	if _direction_is_held(_facing):
		return _facing
	if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_UP):
		return Vector2i.UP
	if Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_DOWN):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_LEFT):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_RIGHT):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _direction_is_held(direction: Vector2i) -> bool:
	match direction:
		Vector2i.UP:
			return Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_UP)
		Vector2i.DOWN:
			return Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_DOWN)
		Vector2i.LEFT:
			return Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_LEFT)
		Vector2i.RIGHT:
			return Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_RIGHT)
	return false


func _is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed("interact") or event.is_action_pressed("jump")


func _start_run(difficulty: int) -> void:
	_difficulty = difficulty
	_score = 0
	_combo = 0
	_last_pickup_time = -10.0
	_max_lives = 5 if difficulty == 0 else 4
	_lives = _max_lives
	_max_battery = 100.0
	_battery = _max_battery
	_battery_regen = 8.0 if difficulty == 0 else 6.0
	_speed_upgrade = 0
	_dash_cooldown = 0.0
	_stage = 0
	_music.pitch_scale = 0.94 if difficulty == 0 else 1.04
	_start_stage()


func _start_stage() -> void:
	_mode = Mode.PLAYING
	_stage_elapsed = 0.0
	_stage_time_left = (125.0 if _stage == 3 else 105.0) if _difficulty == 0 else (110.0 if _stage == 3 else 90.0)
	_banner_time = 2.0
	_feedback = ""
	_feedback_time = 0.0
	_player_cell = START_CELL
	_facing = Vector2i.UP
	_move_cooldown = 0.0
	_flash_cooldown = 0.0
	_switch_cooldown = 0.0
	_invulnerable = 2.0
	_flash_time = 0.0
	_dash_effect_time = 0.0
	_light_time = 0.0
	_active_projector = Vector2i(-1, -1)
	_reinforcement_time = 12.0 if _difficulty == 0 else 9.0
	_tickets.clear()
	_powerups.clear()
	_enemies.clear()
	var cells := _free_cells()
	cells.shuffle()
	var ticket_goal: int = ([8, 10, 12, 9] if _difficulty == 0 else [11, 14, 17, 12])[_stage]
	for cell in cells:
		if _tickets.size() >= ticket_goal:
			break
		if _distance(cell, START_CELL) < 4 or _distance(cell, EXIT_CELL) < 2 or PROJECTORS.has(cell) or _stage == 3 and cell == BOSS_START_CELL:
			continue
		_tickets.append(cell)
	var powerup_types := ["popcorn", "battery", "boots"]
	for powerup_type in powerup_types:
		var cell := _pick_spawn_cell(cells)
		if cell != Vector2i(-1, -1):
			_powerups.append({"cell": cell, "type": powerup_type})
	var enemy_count := (3 + _stage) if _difficulty == 0 else (4 + _stage)
	for index in enemy_count:
		_spawn_enemy(index % 3, cells)
	if _stage == 3:
		_enemies.append({"cell": BOSS_START_CELL, "kind": EnemyKind.BOSS, "timer": 1.4, "stun": 0.0, "hp": 3 if _difficulty == 0 else 5})
	_music.pitch_scale = (0.94 if _difficulty == 0 else 1.04) + _stage * 0.025


func _free_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(1, GRID_H - 1):
		for x in range(1, GRID_W - 1):
			var cell := Vector2i(x, y)
			if not _is_wall(cell):
				cells.append(cell)
	return cells


func _pick_spawn_cell(cells: Array[Vector2i]) -> Vector2i:
	for cell in cells:
		if _distance(cell, _player_cell) < 6 or cell == EXIT_CELL or PROJECTORS.has(cell) or _tickets.has(cell) or _stage == 3 and cell == BOSS_START_CELL:
			continue
		var occupied := false
		for powerup in _powerups:
			if powerup.cell == cell:
				occupied = true
		for enemy in _enemies:
			if enemy.cell == cell:
				occupied = true
		if not occupied:
			return cell
	return Vector2i(-1, -1)


func _is_wall(cell: Vector2i) -> bool:
	if cell.x <= 0 or cell.x >= GRID_W - 1 or cell.y <= 0 or cell.y >= GRID_H - 1:
		return true
	return (cell.y == 3 or cell.y == 4 or cell.y == 7 or cell.y == 8) and ((cell.x >= 2 and cell.x <= 7) or (cell.x >= 10 and cell.x <= 15) or (cell.x >= 18 and cell.x <= 21))


func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _update_game(delta: float) -> void:
	_banner_time = maxf(0.0, _banner_time - delta)
	_feedback_time = maxf(0.0, _feedback_time - delta)
	if _banner_time > 0.0:
		return
	_stage_elapsed += delta
	_stage_time_left -= delta
	if _stage_time_left <= 0.0:
		_finish_defeat("SE HA ACABADO LA FUNCION")
		return
	_battery = minf(_max_battery, _battery + _battery_regen * delta)
	_move_cooldown = maxf(0.0, _move_cooldown - delta)
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_flash_cooldown = maxf(0.0, _flash_cooldown - delta)
	_switch_cooldown = maxf(0.0, _switch_cooldown - delta)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_flash_time = maxf(0.0, _flash_time - delta)
	_dash_effect_time = maxf(0.0, _dash_effect_time - delta)
	_light_time = maxf(0.0, _light_time - delta)
	if _move_cooldown <= 0.0:
		var held := _held_direction()
		if held != Vector2i.ZERO:
			_try_move(held)
	_tick_enemies(delta)
	if _mode != Mode.PLAYING:
		return
	_reinforcement_time -= delta
	if _reinforcement_time <= 0.0:
		_reinforcement_time = 13.0 if _difficulty == 0 else 10.0
		if _enemies.size() < (9 if _difficulty == 0 else 12):
			_spawn_enemy(randi_range(0, 2), _free_cells())
			_set_feedback("OTRA SOMBRA EN LA SALA", 1.1)


func _try_move(direction: Vector2i) -> void:
	_facing = direction
	if _move_cooldown > 0.0:
		return
	_move_cooldown = maxf(0.09, (NORMAL_MOVE_INTERVAL if _difficulty == 0 else HARD_MOVE_INTERVAL) - _speed_upgrade * 0.015)
	var next := _player_cell + direction
	if _is_wall(next):
		return
	_player_cell = next
	_collect_at_player()
	_check_contact()
	_try_exit()


func _collect_at_player() -> void:
	var ticket_index := _tickets.find(_player_cell)
	if ticket_index >= 0:
		_tickets.remove_at(ticket_index)
		_combo = _combo + 1 if _stage_elapsed - _last_pickup_time <= 3.0 else 1
		_last_pickup_time = _stage_elapsed
		_score += 100 * mini(5, _combo)
		_battery = minf(_max_battery, _battery + 5.0)
		if _pickup_audio.stream != null:
			_pickup_audio.play()
		_set_feedback("ENTRADA RECUPERADA  X%d" % mini(5, _combo), 0.7)
	for index in range(_powerups.size() - 1, -1, -1):
		if _powerups[index].cell != _player_cell:
			continue
		match String(_powerups[index].type):
			"popcorn":
				_lives = mini(_max_lives, _lives + 1)
				_set_feedback("PALOMITAS: +1 VIDA", 1.0)
			"battery":
				_battery = _max_battery
				_set_feedback("PILAS: LINTERNA LLENA", 1.0)
			"boots":
				_dash_cooldown = 0.0
				_move_cooldown = 0.0
				_set_feedback("ZAPATOS: DASH LISTO", 1.0)
		_score += 150
		_powerups.remove_at(index)
		if _pickup_audio.stream != null:
			_pickup_audio.play()


func _try_exit() -> void:
	if _player_cell != EXIT_CELL:
		return
	if not _tickets.is_empty():
		_set_feedback("FALTAN %d ENTRADAS" % _tickets.size(), 1.0)
		return
	if _stage == 3 and _boss_alive():
		_set_feedback("DERROTA AL REY DE LA PANTALLA", 1.2)
		return
	_score += ceili(_stage_time_left) * 10 + _lives * 100
	if _stage == 3:
		_finish_victory()
	else:
		_mode = Mode.UPGRADE
		_upgrade_selection = 0


func _apply_upgrade() -> void:
	match _upgrade_selection:
		0:
			_max_lives = mini(9, _max_lives + 1)
			_lives = mini(_max_lives, _lives + 2)
		1:
			_max_battery += 20.0
			_battery_regen += 2.0
			_battery = _max_battery
		2:
			_speed_upgrade = mini(3, _speed_upgrade + 1)
			_dash_cooldown = 0.0
	_stage += 1
	_start_stage()


func _use_flashlight() -> void:
	for projector in PROJECTORS:
		if _distance(_player_cell, projector) <= 1:
			if _switch_cooldown > 0.0:
				_set_feedback("PROYECTOR RECARGANDO", 0.7)
				return
			_active_projector = projector
			_light_time = 8.0 if _difficulty == 0 else 6.0
			_switch_cooldown = 10.0 if _difficulty == 0 else 12.0
			for index in _enemies.size():
				var enemy: Dictionary = _enemies[index]
				if int(enemy.kind) != EnemyKind.BOSS and _distance(enemy.cell, projector) <= 5:
					enemy.stun = 1.5
					_enemies[index] = enemy
			_set_feedback("¡PROYECTOR ENCENDIDO!", 1.0)
			if _pickup_audio.stream != null:
				_pickup_audio.play()
			return
	if _flash_cooldown > 0.0:
		return
	var cost := 30.0 if _difficulty == 0 else 35.0
	if _battery < cost:
		_set_feedback("SIN BATERIA", 0.6)
		return
	_battery -= cost
	_flash_cooldown = 0.5
	_flash_time = 0.24
	var hits := 0
	for index in range(_enemies.size() - 1, -1, -1):
		var enemy: Dictionary = _enemies[index]
		var offset: Vector2i = enemy.cell - _player_cell
		var forward := offset.x * _facing.x + offset.y * _facing.y
		var side := absi(offset.x * _facing.y - offset.y * _facing.x)
		if forward < 1 or forward > 3 or side > 1:
			continue
		if int(enemy.kind) == EnemyKind.BOSS:
			if _light_time <= 0.0 or _distance(enemy.cell, _active_projector) > 5 or float(enemy.stun) > 0.0:
				_set_feedback("EL REY NECESITA LUZ", 0.8)
				continue
			enemy.hp = int(enemy.hp) - 1
			enemy.stun = 1.2
			_score += 500
			hits += 1
			if int(enemy.hp) <= 0:
				_enemies.remove_at(index)
				_set_feedback("¡REY DERROTADO! VE A LA SALIDA", 2.0)
			else:
				_enemies[index] = enemy
				_set_feedback("GOLPE AL REY  %d RESTANTES" % enemy.hp, 1.0)
		else:
			enemy.stun = 1.8 if _difficulty == 0 else 1.25
			_enemies[index] = enemy
			_score += 25
			hits += 1
	if hits > 0 and _feedback_time <= 0.0:
		_set_feedback("SOMBRAS ATURDIDAS", 0.7)
	if _pickup_audio.stream != null:
		_pickup_audio.play()


func _dash() -> void:
	if _dash_cooldown > 0.0:
		_set_feedback("DASH RECARGANDO", 0.5)
		return
	_dash_cooldown = maxf(3.0, (5.0 if _difficulty == 0 else 6.0) - _speed_upgrade * 0.6)
	_invulnerable = maxf(_invulnerable, 0.45)
	for step in 3:
		var next := _player_cell + _facing
		if _is_wall(next):
			break
		_player_cell = next
		_collect_at_player()
		_try_exit()
		if _mode != Mode.PLAYING:
			break
	_dash_effect_time = 0.16


func _spawn_enemy(kind: int, cells: Array[Vector2i]) -> void:
	var cell := _pick_spawn_cell(cells)
	if cell == Vector2i(-1, -1):
		return
	_enemies.append({"cell": cell, "kind": kind, "timer": 0.5 + randf() * 0.6, "stun": 0.0, "hp": 1})


func _tick_enemies(delta: float) -> void:
	var distances := _distance_field()
	for index in _enemies.size():
		var enemy: Dictionary = _enemies[index]
		enemy.stun = maxf(0.0, float(enemy.stun) - delta)
		if _light_time > 0.0 and int(enemy.kind) != EnemyKind.BOSS and _distance(enemy.cell, _active_projector) <= 4:
			enemy.stun = maxf(float(enemy.stun), 0.18)
		enemy.timer = float(enemy.timer) - delta
		if float(enemy.timer) <= 0.0 and float(enemy.stun) <= 0.0:
			enemy.timer = _enemy_interval(int(enemy.kind))
			enemy.cell = _next_enemy_cell(enemy, distances)
		_enemies[index] = enemy
	_check_contact()


func _enemy_interval(kind: int) -> float:
	var base := (0.40 if _difficulty == 0 else 0.29) - _stage * (0.025 if _difficulty == 0 else 0.02)
	if kind == EnemyKind.SPRINTER:
		base *= 0.83
	elif kind == EnemyKind.BOSS:
		base *= 0.95
	if _blackout_active():
		base *= 0.84
	return maxf(0.18, base)


func _next_enemy_cell(enemy: Dictionary, distances: Dictionary) -> Vector2i:
	var cell: Vector2i = enemy.cell
	var kind := int(enemy.kind)
	if kind == EnemyKind.PATROLLER and _distance(cell, _player_cell) > 5:
		var roaming: Array[Vector2i] = []
		for direction in DIRECTIONS:
			if not _is_wall(cell + direction):
				roaming.append(cell + direction)
		return roaming.pick_random() if not roaming.is_empty() else cell
	var best := cell
	var best_distance := int(distances.get(cell, 9999))
	for direction in DIRECTIONS:
		var next := cell + direction
		if _is_wall(next):
			continue
		var value := int(distances.get(next, 9999))
		if value < best_distance:
			best_distance = value
			best = next
	if kind == EnemyKind.SPRINTER and best != cell:
		var second := best + (best - cell)
		if not _is_wall(second) and int(distances.get(second, 9999)) < best_distance:
			return second
	return best


func _distance_field() -> Dictionary:
	var distances := {_player_cell: 0}
	var queue: Array[Vector2i] = [_player_cell]
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for direction in DIRECTIONS:
			var next := cell + direction
			if _is_wall(next) or distances.has(next):
				continue
			distances[next] = int(distances[cell]) + 1
			queue.append(next)
	return distances


func _check_contact() -> void:
	if _invulnerable > 0.0:
		return
	for enemy in _enemies:
		if enemy.cell != _player_cell or float(enemy.stun) > 0.0:
			continue
		_lives -= 1
		_combo = 0
		_invulnerable = 1.7 if _difficulty == 0 else 1.2
		_set_feedback("¡SOMBRA! -1 VIDA", 1.0)
		if _hit_audio.stream != null:
			_hit_audio.play()
		if _lives <= 0:
			_finish_defeat("LA SALA TE HA ATRAPADO")
		return


func _boss_alive() -> bool:
	for enemy in _enemies:
		if int(enemy.kind) == EnemyKind.BOSS and int(enemy.hp) > 0:
			return true
	return false


func _blackout_active() -> bool:
	return (_stage >= 2 or _difficulty == 1 and _stage >= 1) and fmod(_stage_elapsed, 24.0) >= 19.0


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
	# A small original 8-bit loop synthesized in memory; no legacy audio changes.
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


class LastUsherScreen extends Control:
	# Match the first cabinet's bitmap alphabet and 3/2/1-pixel text hierarchy.
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
	var controller: ArcadeLastUsher

	func _draw() -> void:
		if controller == null:
			return
		var scale_factor := maxf(1.0, floorf(minf(size.x / LOGICAL_SIZE.x, size.y / LOGICAL_SIZE.y)))
		var offset := (size - LOGICAL_SIZE * scale_factor) * 0.5
		draw_rect(Rect2(Vector2.ZERO, size), BLACK)
		draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
		match controller._mode:
			Mode.BOOT: _draw_boot()
			Mode.MENU: _draw_menu()
			Mode.HOW_TO: _draw_how_to()
			Mode.PLAYING: _draw_game()
			Mode.UPGRADE: _draw_upgrade()
			Mode.VICTORY: _draw_outcome(true)
			Mode.DEFEAT: _draw_outcome(false)
			Mode.EXIT: _draw_boot()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _text(value: String, at: Vector2, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> void:
		var label := _normalize_text(value)
		var pixel := clampi(roundi(float(font_size) / 6.0), 1, 3)
		var x := at.x - _pixel_text_width(label, pixel) * 0.5 if alignment == HORIZONTAL_ALIGNMENT_CENTER else at.x
		var top := at.y - 5.0 * pixel
		for character in label:
			var glyph: PackedStringArray = PIXEL_GLYPHS.get(character, PIXEL_GLYPHS["?"])
			for row in glyph.size():
				for column in glyph[row].length():
					if glyph[row][column] == "1":
						draw_rect(Rect2(x + column * pixel, top + row * pixel, pixel, pixel), color)
			x += 4.0 * pixel

	func _normalize_text(value: String) -> String:
		return value.to_upper().replace("Á", "A").replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U").replace("Ü", "U").replace("¡", "!").replace("·", ".")

	func _pixel_text_width(value: String, pixel: int) -> float:
		return maxf(0.0, value.length() * 4.0 * pixel - pixel)

	func _base() -> void:
		draw_rect(Rect2(Vector2.ZERO, LOGICAL_SIZE), NAVY)
		for index in 48:
			var x := float(posmod(index * 73 + 17, 370) + 7)
			var y := float(posmod(index * 41 + 31, 200) + 7)
			draw_rect(Rect2(x, y, 1, 1), Color(CYAN, 0.22))
		draw_rect(Rect2(4, 4, 376, 208), WINE, false, 3.0)
		draw_rect(Rect2(8, 8, 368, 200), CYAN, false, 1.0)
		for y in range(12, 208, 4):
			draw_line(Vector2(9, y), Vector2(375, y), Color(0.0, 0.0, 0.0, 0.13), 1.0)
		for corner in [Vector2(10, 10), Vector2(368, 10), Vector2(10, 200), Vector2(368, 200)]:
			draw_rect(Rect2(corner, Vector2(6, 6)), GOLD)

	func _draw_boot() -> void:
		_base()
		_text("PALACE ENTERTAINMENT SYSTEM", Vector2(192, 70), 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		_text("INSERTANDO MONEDA...", Vector2(192, 102), 13, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		var width := 240.0 * clampf(controller._transition / 0.35, 0.0, 1.0)
		draw_rect(Rect2(72, 122, 240, 8), BLACK)
		draw_rect(Rect2(72, 122, width, 8), GOLD)

	func _draw_menu() -> void:
		_base()
		draw_rect(Rect2(24, 22, 336, 55), BLACK)
		draw_rect(Rect2(26, 24, 332, 51), WINE, false, 2.0)
		for bulb in 16:
			var lit := (bulb + int(controller._animation * 6.0)) % 4 != 0
			draw_circle(Vector2(37 + bulb * 20, 28), 2.0, GOLD if lit else RED)
		_text("PALACE ARCADE  1992", Vector2(192, 42), 8, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		_text("EL ÚLTIMO ACOMODADOR", Vector2(192, 66), 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_usher(Vector2(90, 126), true)
		_draw_enemy(Vector2(158, 124), EnemyKind.SHADOW, 0.0)
		draw_line(Vector2(119, 122), Vector2(139, 120), GOLD, 3.0)
		var options := ["NORMAL", "DIFÍCIL", "CÓMO JUGAR"]
		var option_box_width := 147.0
		for option in options:
			option_box_width = maxf(option_box_width, _pixel_text_width(_normalize_text("> " + option), 2) + 20.0)
		for index in options.size():
			var y := 110.0 + index * 25.0
			var selected := controller._menu_selection == index
			if selected:
				var box := Rect2(278.0 - option_box_width * 0.5, y - 14.0, option_box_width, 19.0)
				draw_rect(box, WINE)
				draw_rect(box, GOLD, false, 1.0)
			_text(("> " if selected else "  ") + options[index], Vector2(278, y), 12, GOLD if selected else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		draw_rect(Rect2(27, 187, 330, 1), CYAN)
		_text("A/D ELEGIR   E/ESPACIO CONFIRMAR   ESC SALIR", Vector2(192, 202), 7, CREAM, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_how_to() -> void:
		_base()
		_text("MANUAL DEL ACOMODADOR", Vector2(192, 34), 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		draw_rect(Rect2(24, 45, 336, 135), BLACK)
		draw_rect(Rect2(26, 47, 332, 131), CYAN, false, 1.0)
		var lines := [
			"WASD / FLECHAS: MUÉVETE Y APUNTA",
			"ENTRADAS: RECOGE TODAS Y SAL",
			"E: DESTELLO, ATURDE EN TU DIRECCIÓN",
			"E EN PROYECTOR: ENCIENDE SU LUZ",
			"ESPACIO: DASH E INVULNERABILIDAD BREVE",
			"HUYE DE SOMBRAS, PATRULLAS Y VELOCISTAS",
			"JEFE FINAL: PROYECTOR + DESTELLO",
			"ENTRE ACTOS: ELIGE UNA MEJORA",
		]
		for index in lines.size():
			var row_y := 62.0 + index * 15.0
			_draw_manual_icon(index, Vector2(45, row_y))
			_text(lines[index], Vector2(63, row_y + 2), 8, CYAN if index == 6 else CREAM)
		_text("E/ESPACIO VOLVER     ESC SALIR", Vector2(192, 201), 8, GOLD, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_manual_icon(kind: int, center: Vector2) -> void:
		draw_rect(Rect2(center - Vector2(7, 6), Vector2(14, 12)), FLOOR)
		draw_rect(Rect2(center - Vector2(7, 6), Vector2(14, 12)), CYAN, false, 1.0)
		match kind:
			0: # Movement and facing.
				draw_line(center + Vector2(-4, 0), center + Vector2(4, 0), GOLD, 1.0)
				draw_line(center + Vector2(0, -4), center + Vector2(0, 4), GOLD, 1.0)
				draw_rect(Rect2(center - Vector2.ONE, Vector2(2, 2)), CREAM)
			1: # Ticket.
				draw_rect(Rect2(center - Vector2(5, 3), Vector2(10, 6)), GOLD)
				draw_rect(Rect2(center - Vector2(1, 2), Vector2(2, 4)), WINE)
			2: # Flashlight and beam.
				draw_rect(Rect2(center + Vector2(-5, -2), Vector2(5, 4)), GOLD)
				draw_colored_polygon(PackedVector2Array([center, center + Vector2(5, -4), center + Vector2(5, 4)]), Color(CREAM, 0.8))
			3: # Projector lens.
				draw_rect(Rect2(center + Vector2(-5, -3), Vector2(7, 6)), VIOLET)
				draw_circle(center + Vector2(3, 0), 3.0, GOLD)
			4: # Dash trail.
				draw_line(center + Vector2(-5, -3), center + Vector2(1, -3), GOLD, 1.0)
				draw_line(center + Vector2(-5, 0), center + Vector2(4, 0), GOLD, 1.0)
				draw_line(center + Vector2(-5, 3), center + Vector2(1, 3), GOLD, 1.0)
			5: # Shadow.
				draw_circle(center + Vector2(0, -1), 4.0, RED)
				draw_rect(Rect2(center + Vector2(-4, 0), Vector2(8, 4)), RED)
				draw_rect(Rect2(center + Vector2(-2, -2), Vector2(1, 1)), BLACK)
				draw_rect(Rect2(center + Vector2(2, -2), Vector2(1, 1)), BLACK)
			6: # Crowned final boss.
				draw_circle(center + Vector2(0, 1), 4.0, RED)
				draw_colored_polygon(PackedVector2Array([center + Vector2(-5, -3), center + Vector2(-3, -6), center + Vector2(0, -3), center + Vector2(3, -6), center + Vector2(5, -3)]), GOLD)
			7: # Permanent upgrade.
				draw_rect(Rect2(center + Vector2(-1, -5), Vector2(2, 10)), CYAN)
				draw_rect(Rect2(center + Vector2(-5, -1), Vector2(10, 2)), CYAN)

	func _draw_game() -> void:
		_base()
		draw_rect(Rect2(12, 9, 360, 30), BLACK)
		_text("ACTO %d/4" % (controller._stage + 1), Vector2(22, 23), 12, GOLD)
		for life in controller._max_lives:
			draw_rect(Rect2(89 + life * 9, 14, 6, 8), RED if life < controller._lives else FLOOR)
		_text("ENTRADAS %02d" % controller._tickets.size(), Vector2(178, 23), 12, CYAN)
		_text("%02d:%02d" % [ceili(controller._stage_time_left) / 60, ceili(controller._stage_time_left) % 60], Vector2(314, 23), 12, CREAM)
		var status := controller._feedback if controller._feedback_time > 0.0 else "WASD MOVER  E LINTERNA  ESPACIO DASH"
		var status_size := 8
		while _pixel_text_width(_normalize_text(status), clampi(roundi(float(status_size) / 6.0), 1, 3)) > 344.0 and status_size > 6:
			status_size -= 1
		_text(status, Vector2(192, 35), status_size, GOLD if controller._feedback_time > 0.0 else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_board()
		draw_rect(Rect2(12, 188, 360, 20), BLACK)
		_text("LUZ", Vector2(19, 202), 8, CYAN)
		draw_rect(Rect2(51, 194, 73, 9), FLOOR)
		draw_rect(Rect2(52, 195, 71.0 * controller._battery / controller._max_battery, 7), CYAN)
		_text("DASH %s" % ("LISTO" if controller._dash_cooldown <= 0.0 else "%dS" % ceili(controller._dash_cooldown)), Vector2(137, 202), 8, GOLD)
		_text("PTS %06d" % controller._score, Vector2(278, 202), 8, CREAM)
		if controller._banner_time > 0.0:
			draw_rect(Rect2(52, 86, 280, 43), BLACK)
			draw_rect(Rect2(52, 86, 280, 43), CYAN, false, 2.0)
			var title := "ACTO %d: %s" % [controller._stage + 1, ["LA ÚLTIMA RONDA", "SOMBRAS EN LA FILA", "APAGÓN", "EL REY DE LA PANTALLA"][controller._stage]]
			var title_size := 12
			while _pixel_text_width(_normalize_text(title), clampi(roundi(float(title_size) / 6.0), 1, 3)) > 268.0 and title_size > 9:
				title_size -= 1
			_text(title, Vector2(192, 106), title_size, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			_text("RECOGE LAS ENTRADAS Y SAL POR ARRIBA", Vector2(192, 121), 8, CREAM, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_board() -> void:
		draw_rect(Rect2(FIELD_ORIGIN, Vector2(GRID_W * TILE, GRID_H * TILE)), BLACK)
		for y in GRID_H:
			for x in GRID_W:
				var cell := Vector2i(x, y)
				var at := FIELD_ORIGIN + Vector2(cell) * TILE
				if controller._is_wall(cell):
					var seat := (x > 0 and x < GRID_W - 1 and y > 0 and y < GRID_H - 1)
					draw_rect(Rect2(at, Vector2(TILE, TILE)), WINE if seat else BLACK)
					if seat:
						draw_rect(Rect2(at + Vector2(2, 2), Vector2(8, 4)), RED)
						draw_rect(Rect2(at + Vector2(2, 8), Vector2(8, 2)), Color("48253b"))
				else:
					draw_rect(Rect2(at, Vector2(TILE, TILE)), FLOOR if (x + y) % 2 == 0 else NAVY)
					if y == 1 or y == 5 or y == 9:
						draw_rect(Rect2(at + Vector2(1, 6), Vector2(10, 1)), Color(WINE, 0.35))
		if controller._light_time > 0.0:
			var light_center := _center(controller._active_projector)
			draw_circle(light_center, 55.0, Color(GOLD, 0.12))
			draw_circle(light_center, 34.0, Color(CREAM, 0.10))
		if controller._blackout_active():
			draw_rect(Rect2(FIELD_ORIGIN, Vector2(GRID_W * TILE, GRID_H * TILE)), Color(0.0, 0.0, 0.07, 0.45))
		var exit_at := _center(EXIT_CELL)
		draw_rect(Rect2(exit_at - Vector2(5, 5), Vector2(10, 10)), CYAN if controller._tickets.is_empty() and not controller._boss_alive() else RED)
		_text("^", exit_at + Vector2(-3, 4), 11, BLACK)
		for projector in PROJECTORS:
			var center := _center(projector)
			draw_rect(Rect2(center - Vector2(5, 4), Vector2(10, 8)), GOLD if controller._active_projector == projector and controller._light_time > 0.0 else VIOLET)
			draw_circle(center, 2.0, CREAM)
		for ticket in controller._tickets:
			var center := _center(ticket)
			draw_rect(Rect2(center - Vector2(4, 3), Vector2(8, 6)), GOLD)
			draw_rect(Rect2(center - Vector2(2, 1), Vector2(4, 2)), WINE)
		for powerup in controller._powerups:
			var center := _center(powerup.cell)
			var color: Color = RED if powerup.type == "popcorn" else (CYAN if powerup.type == "battery" else GOLD)
			draw_circle(center, 5.0, color)
			_text("+" if powerup.type == "popcorn" else ("B" if powerup.type == "battery" else ">"), center + Vector2(-3, 4), 10, BLACK)
		for enemy in controller._enemies:
			_draw_enemy(_center(enemy.cell), int(enemy.kind), float(enemy.stun))
		if controller._dash_effect_time > 0.0:
			var dash_center := _center(controller._player_cell)
			var back := Vector2(-controller._facing)
			draw_line(dash_center + back * 7.0, dash_center + back * 24.0, GOLD, 2.0)
		if controller._flash_time > 0.0:
			var from := _center(controller._player_cell) + Vector2(controller._facing) * 6.0
			var along := Vector2(controller._facing) * 35.0
			var side := Vector2(-controller._facing.y, controller._facing.x) * 12.0
			draw_colored_polygon(PackedVector2Array([from, from + along + side, from + along - side]), Color(CREAM, 0.45))
		if controller._invulnerable <= 0.0 or int(controller._animation * 12.0) % 2 == 0:
			_draw_usher(_center(controller._player_cell), false, controller._facing)
		draw_rect(Rect2(FIELD_ORIGIN, Vector2(GRID_W * TILE, GRID_H * TILE)), CYAN, false, 1.0)

	func _center(cell: Vector2i) -> Vector2:
		return FIELD_ORIGIN + Vector2(cell) * TILE + Vector2(6, 6)

	func _draw_usher(center: Vector2, large: bool, facing := Vector2i.RIGHT) -> void:
		var factor := 2.0 if large else 1.0
		draw_rect(Rect2(center + Vector2(-4, -4) * factor, Vector2(8, 9) * factor), CYAN)
		draw_rect(Rect2(center + Vector2(-4, -7) * factor, Vector2(8, 3) * factor), NAVY)
		draw_rect(Rect2(center + Vector2(-6, -5) * factor, Vector2(12, 2) * factor), GOLD)
		var front := Vector2(facing)
		draw_rect(Rect2(center + front * 2.0 * factor - Vector2.ONE * factor, Vector2.ONE * 2.0 * factor), CREAM)
		if facing.x != 0:
			draw_rect(Rect2(center + front * 7.0 * factor - Vector2(3, 1) * factor, Vector2(6, 2) * factor), GOLD)
		else:
			draw_rect(Rect2(center + front * 7.0 * factor - Vector2(1, 3) * factor, Vector2(2, 6) * factor), GOLD)

	func _draw_enemy(center: Vector2, kind: int, stun: float) -> void:
		var color: Color = STUN_BLUE if stun > 0.0 else (RED if kind == EnemyKind.SHADOW else (VIOLET if kind == EnemyKind.PATROLLER else (GOLD if kind == EnemyKind.SPRINTER else Color("df82aa"))))
		if stun > 0.0:
			draw_circle(center, 8.0 if kind != EnemyKind.BOSS else 14.0, Color(CYAN, 0.32))
		if kind == EnemyKind.BOSS:
			draw_circle(center, 11.0, color)
			draw_rect(Rect2(center + Vector2(-12, 4), Vector2(24, 7)), color)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-10, -7), center + Vector2(-8, -15), center + Vector2(-4, -9)]), GOLD)
			draw_colored_polygon(PackedVector2Array([center + Vector2(4, -9), center + Vector2(8, -15), center + Vector2(10, -7)]), GOLD)
		else:
			draw_circle(center + Vector2(0, -2), 5.0, color)
			draw_rect(Rect2(center + Vector2(-5, -2), Vector2(10, 7)), color)
		draw_rect(Rect2(center + Vector2(-3, -3), Vector2(2, 2)), CREAM if stun > 0.0 else BLACK)
		draw_rect(Rect2(center + Vector2(2, -3), Vector2(2, 2)), CREAM if stun > 0.0 else BLACK)

	func _draw_upgrade() -> void:
		_base()
		_text("ACTO %d COMPLETADO" % (controller._stage + 1), Vector2(192, 40), 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		_text("ELIGE UNA MEJORA PERMANENTE", Vector2(192, 63), 13, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		var labels := [["VIDA", "EXTRA"], ["PILAS", "GRANDES"], ["BOTAS", "RÁPIDAS"]]
		var details := ["+1 MÁXIMO  +2 VIDAS", "+20 LUZ Y RECARGA", "MÁS VELOCIDAD Y DASH"]
		for index in 3:
			var x := 21.0 + index * 115.0
			var selected := controller._upgrade_selection == index
			draw_rect(Rect2(x, 85, 111, 81), WINE if selected else BLACK)
			draw_rect(Rect2(x, 85, 111, 81), GOLD if selected else CYAN, false, 2.0 if selected else 1.0)
			draw_circle(Vector2(x + 55, 103), 10, RED if index == 0 else (CYAN if index == 1 else GOLD))
			_text(labels[index][0], Vector2(x + 55, 128), 13, GOLD if selected else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
			_text(labels[index][1], Vector2(x + 55, 143), 13, GOLD if selected else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
			_text(details[index], Vector2(x + 55, 158), 7, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		_text("A/D ELEGIR   E/ESPACIO CONTINUAR", Vector2(192, 197), 8, CREAM, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw_outcome(victory: bool) -> void:
		_base()
		_draw_usher(Vector2(55, 104), true)
		_draw_enemy(Vector2(329, 105), EnemyKind.BOSS, 1.0 if victory else 0.0)
		_text("¡CINE SALVADO!" if victory else "FIN DE LA FUNCIÓN", Vector2(192, 55), 24, GOLD if victory else RED, HORIZONTAL_ALIGNMENT_CENTER)
		_text("PUNTOS %07d" % controller._score, Vector2(192, 84), 8, CYAN, HORIZONTAL_ALIGNMENT_CENTER)
		if victory:
			_text(controller._feedback, Vector2(192, 119), 10, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
			_text("E/ESPACIO: OTRA DIFICULTAD", Vector2(192, 163), 8, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			_text(controller._feedback, Vector2(192, 109), 8, RED, HORIZONTAL_ALIGNMENT_CENTER)
			var options := ["REINTENTAR", "ELEGIR DIFICULTAD", "SALIR"]
			var option_box_width := 150.0
			for option in options:
				option_box_width = maxf(option_box_width, _pixel_text_width(_normalize_text("> " + option), 1) + 20.0)
			for index in options.size():
				var y := 133.0 + index * 20.0
				var selected := controller._defeat_selection == index
				if selected:
					var box := Rect2(192.0 - option_box_width * 0.5, y - 10.0, option_box_width, 15.0)
					draw_rect(box, WINE)
					draw_rect(box, GOLD, false, 1.0)
				_text(("> " if selected else "  ") + options[index], Vector2(192, y), 8, GOLD if selected else CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		_text("ESC SALIR", Vector2(192, 201), 8, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
