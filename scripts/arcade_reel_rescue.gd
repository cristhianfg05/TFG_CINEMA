class_name ArcadeReelRescue
extends CanvasLayer

const HUD_FONT := preload("res://assets/fonts/PalaceHUD-Bold.ttf")
const LOGICAL_SIZE := Vector2(320.0, 180.0)
const NORMAL_POSTER_ID := "arcade_reel_rescue_normal_poster"
const HARD_POSTER_ID := "arcade_reel_rescue_hard_poster"
const ERROR_STREAM := preload("res://assets/audio/sfx/arcade/arcade_error_03.wav")
const REPAIR_STREAM := preload("res://assets/audio/sfx/arcade/arcade_repair_03.wav")
const SELECT_STREAM := preload("res://assets/audio/sfx/arcade/arcade_menu_soft_pim_03.wav")
const COLORS := {
	"black": Color("101116"), "charcoal": Color("24242c"), "wine": Color("6b2430"),
	"cream": Color("f2dfac"), "gold": Color("e7b34e"), "red": Color("d8514d"), "blue": Color("294b6d"),
	"cyan": Color("65d2cb"), "violet": Color("9d72c4"), "night": Color("121b2e"),
}

enum Mode { CLOSED, TRANSITION, MENU, HOW_TO, PLAYING, VICTORY, DEFEAT, EXIT_TRANSITION }

var _screen: ArcadeReelScreen
var _mode := Mode.CLOSED
var _difficulty := 0
var _transition_elapsed := 0.0
var _elapsed := 0.0
var _spawn_elapsed := 0.0
var _integrity := 5
var _repairs := 0
var _best_repairs := 0
var _score := 0
var _combo := 0
var _focus := 100.0
var _spawn_count := 0
var _stage := 0
var _stage_banner_time := 0.0
var _animation_time := 0.0
var _operator_lane := 1
var _defects: Array[Dictionary] = []
var _flash_time := 0.0
var _feedback := ""
var _feedback_time := 0.0
var _defeat_selection := 0
var _menu_selection := 0
var _stored_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _paused_before_open := false
var _manager: Node
var _audio: AudioStreamPlayer
var _error_audio: AudioStreamPlayer
var _repair_audio: AudioStreamPlayer
var _select_audio: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("arcade_minigame")
	_screen = ArcadeReelScreen.new()
	_screen.controller = self
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.visible = false
	add_child(_screen)
	_manager = get_tree().get_first_node_in_group("gameplay_manager")
	_audio = AudioStreamPlayer.new()
	_audio.name = "ArcadeChiptune"
	_audio.volume_db = -27.0
	_audio.stream = _make_chiptune_loop()
	_audio.bus = "Machines"
	add_child(_audio)
	_error_audio = AudioStreamPlayer.new()
	_error_audio.name = "ArcadeError"
	_error_audio.stream = ERROR_STREAM
	_error_audio.volume_db = -6.0
	_error_audio.bus = "Machines"
	add_child(_error_audio)
	_repair_audio = AudioStreamPlayer.new()
	_repair_audio.name = "ArcadeRepair"
	_repair_audio.stream = REPAIR_STREAM
	_repair_audio.volume_db = -8.0
	_repair_audio.bus = "Machines"
	add_child(_repair_audio)
	_select_audio = AudioStreamPlayer.new()
	_select_audio.name = "ArcadeSelect"
	_select_audio.stream = SELECT_STREAM
	_select_audio.volume_db = -10.0
	_select_audio.bus = "UI"
	add_child(_select_audio)


func is_open() -> bool:
	return _mode != Mode.CLOSED


func open_arcade(_source: Node3D = null) -> bool:
	if is_open() or _has_blocking_modal():
		return false
	_manager = get_tree().get_first_node_in_group("gameplay_manager")
	if _manager and _manager.has_method("set_vacuum_trigger_held"):
		_manager.set_vacuum_trigger_held(false)
	if _manager and _manager.has_method("mark_arcade_discovered"):
		_manager.mark_arcade_discovered()
	_paused_before_open = get_tree().paused
	_stored_mouse_mode = Input.mouse_mode
	_set_gameplay_hud_visible(false)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_mode = Mode.TRANSITION
	_transition_elapsed = 0.0
	_screen.visible = true
	_screen.queue_redraw()
	if _audio.stream != null:
		_audio.play()
	return true


func close_arcade() -> void:
	if not is_open():
		return
	_mode = Mode.CLOSED
	_defects.clear()
	_audio.stop()
	_screen.visible = false
	get_tree().paused = _paused_before_open
	Input.mouse_mode = _stored_mouse_mode
	_set_gameplay_hud_visible(true)


func _process(delta: float) -> void:
	if _mode == Mode.CLOSED:
		return
	_animation_time += delta
	if _mode == Mode.TRANSITION:
		_transition_elapsed += delta
		if _transition_elapsed >= 0.26:
			_mode = Mode.MENU
		_screen.queue_redraw()
		return
	if _mode == Mode.EXIT_TRANSITION:
		_transition_elapsed += delta
		if _transition_elapsed >= 0.26:
			close_arcade()
		else:
			_screen.queue_redraw()
		return
	if _mode == Mode.PLAYING:
		_update_run(delta)
	_screen.queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_open() or get_viewport().is_input_handled():
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		_begin_exit()
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.TRANSITION:
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.MENU:
		if event.is_action_pressed("move_forward") or event.is_action_pressed("move_left"):
			_menu_selection = posmod(_menu_selection - 1, 3)
			_select_audio.play()
		elif event.is_action_pressed("move_backward") or event.is_action_pressed("move_right"):
			_menu_selection = posmod(_menu_selection + 1, 3)
			_select_audio.play()
		elif event.is_action_pressed("interact") or event.is_action_pressed("jump"):
			if _menu_selection < 2:
				_difficulty = _menu_selection
				_start_run(_difficulty)
			else:
				_mode = Mode.HOW_TO
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.HOW_TO:
		if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
			_mode = Mode.MENU
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.PLAYING:
		if event.is_echo():
			get_viewport().set_input_as_handled()
			return
		if _stage_banner_time > 0.0:
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_left"):
			_operator_lane = maxi(0, _operator_lane - 1)
		elif event.is_action_pressed("move_right"):
			_operator_lane = mini(2, _operator_lane + 1)
		elif event.is_action_pressed("interact") or event.is_action_pressed("jump"):
			_try_repair()
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.VICTORY:
		if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
			_mode = Mode.MENU
		get_viewport().set_input_as_handled()
		return
	if _mode == Mode.DEFEAT:
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_forward"):
			_defeat_selection = posmod(_defeat_selection - 1, 3)
			_select_audio.play()
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_backward"):
			_defeat_selection = posmod(_defeat_selection + 1, 3)
			_select_audio.play()
		elif event.is_action_pressed("interact") or event.is_action_pressed("jump"):
			if _defeat_selection == 0:
				_start_run(_difficulty)
			elif _defeat_selection == 1:
				_mode = Mode.MENU
			else:
				close_arcade()
		get_viewport().set_input_as_handled()


func _start_run(difficulty: int) -> void:
	_difficulty = difficulty
	_elapsed = 0.0
	_spawn_elapsed = 0.9
	_integrity = _max_integrity()
	_repairs = 0
	_score = 0
	_combo = 0
	_focus = 100.0
	_spawn_count = 0
	_stage = 0
	_stage_banner_time = 1.8
	_animation_time = 0.0
	_operator_lane = 1
	_defects.clear()
	_feedback = ""
	_feedback_time = 0.0
	_flash_time = 0.0
	_mode = Mode.PLAYING


func _begin_exit() -> void:
	if _mode == Mode.EXIT_TRANSITION:
		return
	_transition_elapsed = 0.0
	_mode = Mode.EXIT_TRANSITION


func _update_run(delta: float) -> void:
	_elapsed += delta
	_flash_time = maxf(0.0, _flash_time - delta)
	_feedback_time = maxf(0.0, _feedback_time - delta)
	_stage_banner_time = maxf(0.0, _stage_banner_time - delta)
	var duration := _duration()
	if _elapsed >= duration:
		if _repairs >= _required_repairs():
			_finish_victory()
		else:
			_finish_defeat("FALTAN FOTOGRAMAS")
		return
	var next_stage := mini(3, int(_elapsed / duration * 4.0))
	if next_stage != _stage:
		_stage = next_stage
		_integrity = mini(_max_integrity(), _integrity + 1)
		_stage_banner_time = 1.5
	# Act cards never hide a live repair window from the player.
	if _stage_banner_time > 0.0:
		return
	var focus_active := Input.is_action_pressed("move_backward") and _focus > 0.0
	_focus = clampf(_focus + (-28.0 if focus_active else 8.0) * delta, 0.0, 100.0)
	_spawn_elapsed += delta
	var spawn_interval := _spawn_interval()
	if _spawn_elapsed >= spawn_interval and _defects.size() < _max_simultaneous_defects():
		_spawn_elapsed = 0.0
		_spawn_defect()
	var speed := _defect_speed() * (0.58 if focus_active else 1.0)
	for index in range(_defects.size() - 1, -1, -1):
		var defect := _defects[index]
		defect.y = float(defect.y) + speed * delta
		if float(defect.y) >= 162.0:
			_defects.remove_at(index)
			if not bool(defect.get("bonus", false)):
				_penalize("CINTA PERDIDA")
				if _mode == Mode.DEFEAT:
					return
		else:
			_defects[index] = defect


func _spawn_defect() -> void:
	var candidate_lanes: Array[int] = [0, 1, 2]
	# Avoid a newly spawned defect in a lane whose predecessor is about to enter
	# the repair zone. This keeps both difficulties physically fair.
	for defect in _defects:
		if float(defect.y) > 112.0:
			candidate_lanes.erase(int(defect.lane))
	var lane: int = candidate_lanes.pick_random() if not candidate_lanes.is_empty() else randi_range(0, 2)
	_spawn_count += 1
	_defects.append({"lane": lane, "y": 47.0, "kind": randi_range(0, 2), "bonus": _spawn_count % 5 == 0})


func _try_repair() -> void:
	var best_index := -1
	var best_distance := INF
	for index in _defects.size():
		var defect := _defects[index]
		if int(defect.lane) != _operator_lane:
			continue
		var distance := absf(float(defect.y) - 143.0)
		if distance <= 12.0 and distance < best_distance:
			best_index = index
			best_distance = distance
	if best_index >= 0:
		var bonus := bool(_defects[best_index].get("bonus", false))
		_defects.remove_at(best_index)
		_repairs += 2 if bonus else 1
		_combo += 1
		_score += (200 if bonus else 100) * mini(5, 1 + _combo / 4)
		_focus = minf(100.0, _focus + (25.0 if bonus else 13.0))
		if _combo % 3 == 0 or bonus:
			_integrity = mini(_max_integrity(), _integrity + 1)
		_best_repairs = maxi(_best_repairs, _repairs)
		_flash_time = 0.16
		_feedback = "CARRETE EXTRA +2" if bonus else ("COMBO X%d" % mini(5, 1 + _combo / 4) if _combo >= 4 else "¡REPARADO!")
		_feedback_time = 0.55
		if _repair_audio.stream != null:
			_repair_audio.play()
	else:
		_penalize("ERROR -1 VIDA")


func _penalize(message: String) -> void:
	_integrity -= 1
	_combo = 0
	_flash_time = 0.2
	_feedback = message
	_feedback_time = 0.75
	if _error_audio.stream != null:
		_error_audio.play()
	if _integrity <= 0:
		_finish_defeat("CINTA AGOTADA")


func _finish_defeat(message: String) -> void:
	_feedback = message
	_defeat_selection = 0
	_mode = Mode.DEFEAT


func _finish_victory() -> void:
	_mode = Mode.VICTORY
	var poster_id := NORMAL_POSTER_ID if _difficulty == 0 else HARD_POSTER_ID
	if _manager and not _manager.is_collectible_found(poster_id):
		_manager.collect_collectible(poster_id, null, "Cartel desbloqueado", "Pulsa Tab para verlo")
		_feedback = "CARTEL DESBLOQUEADO"
	else:
		_feedback = "CARTEL YA OBTENIDO"


func _duration() -> float:
	return 150.0 if _difficulty == 0 else 180.0


func _required_repairs() -> int:
	return 36 if _difficulty == 0 else 50


func _max_integrity() -> int:
	return 8 if _difficulty == 0 else 7


func _defect_speed() -> float:
	# Faster arrival and a shorter repair window in both modes. Difficult
	# escalates more sharply, but each new reel remains readable from the top.
	return 41.0 + _stage * 2.5 if _difficulty == 0 else 50.0 + _stage * 3.5


func _spawn_interval() -> float:
	return 2.15 - _stage * 0.12 if _difficulty == 0 else 1.85 - _stage * 0.13


func _max_simultaneous_defects() -> int:
	if _difficulty == 1 and _stage >= 2:
		return 3
	return 2


func _has_blocking_modal() -> bool:
	if get_tree().paused:
		return true
	for group_name in ["upgrade_menu", "tool_shop_panel", "pause_menu"]:
		var modal := get_tree().get_first_node_in_group(group_name)
		if modal and modal.has_method("is_open") and modal.is_open():
			return true
	return false


func _set_gameplay_hud_visible(visible: bool) -> void:
	var hud := get_tree().get_first_node_in_group("gameplay_hud")
	if hud and hud.has_method("set_gameplay_hud_visible"):
		hud.set_gameplay_hud_visible(visible)


func _make_chiptune_loop() -> AudioStreamWAV:
	var sample_rate := 11025
	var phrase := [261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 349.23]
	var samples_per_note := int(sample_rate * 0.24)
	var bytes := PackedByteArray()
	for note in phrase:
		for sample_index in samples_per_note:
			var envelope := clampf(1.0 - float(sample_index) / float(samples_per_note), 0.15, 1.0)
			var wave := 0.16 if sin(TAU * note * float(sample_index) / float(sample_rate)) >= 0.0 else -0.16
			var value := int(wave * envelope * 32767.0)
			bytes.append(value & 0xff)
			bytes.append((value >> 8) & 0xff)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = phrase.size() * samples_per_note
	return stream


class ArcadeReelScreen extends Control:
	const PIXEL_GLYPHS := {
		"A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"],
		"C": ["011", "100", "100", "100", "011"], "D": ["110", "101", "101", "101", "110"],
		"E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
		"G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"],
		"I": ["111", "010", "010", "010", "111"], "J": ["001", "001", "001", "101", "010"],
		"K": ["101", "101", "110", "101", "101"], "L": ["100", "100", "100", "100", "111"],
		"M": ["101", "111", "111", "101", "101"], "N": ["101", "111", "111", "111", "101"],
		"O": ["010", "101", "101", "101", "010"], "P": ["110", "101", "110", "100", "100"],
		"Q": ["010", "101", "101", "011", "001"], "R": ["110", "101", "110", "101", "101"],
		"S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"],
		"U": ["101", "101", "101", "101", "111"], "V": ["101", "101", "101", "101", "010"],
		"W": ["101", "101", "111", "111", "101"], "X": ["101", "101", "010", "101", "101"],
		"Y": ["101", "101", "010", "010", "010"], "Z": ["111", "001", "010", "100", "111"],
		# Accents sit two pixel rows above the shared 3x5 baseline.
		"Á": ["001", "000", "010", "101", "111", "101", "101"],
		"É": ["001", "000", "111", "100", "110", "100", "111"],
		"Í": ["001", "000", "111", "010", "010", "010", "111"],
		"Ó": ["001", "000", "010", "101", "101", "101", "010"],
		"Ú": ["001", "000", "101", "101", "101", "101", "111"],
		"Ü": ["101", "000", "101", "101", "101", "101", "111"],
		"Ñ": ["101", "010", "101", "111", "111", "111", "101"],
		"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
		"2": ["110", "001", "010", "100", "111"], "3": ["110", "001", "010", "001", "110"],
		"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "110", "001", "110"],
		"6": ["011", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
		"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "110"],
		" ": ["000", "000", "000", "000", "000"], "?": ["110", "001", "010", "000", "010"],
		"¿": ["010", "000", "010", "100", "011"], "¡": ["010", "000", "010", "010", "010"],
		"!": ["010", "010", "010", "000", "010"], ".": ["000", "000", "000", "000", "010"],
		":": ["000", "010", "000", "010", "000"], "-": ["000", "000", "111", "000", "000"],
		"/": ["001", "001", "010", "100", "100"], "+": ["000", "010", "111", "010", "000"], "[": ["110", "100", "100", "100", "110"],
		"]": ["011", "001", "001", "001", "011"], ">": ["100", "010", "001", "010", "100"],
		"●": ["010", "111", "111", "111", "010"],
	}
	var controller: ArcadeReelRescue

	func _draw() -> void:
		if controller == null:
			return
		var scale_factor: float = floor(minf(size.x / LOGICAL_SIZE.x, size.y / LOGICAL_SIZE.y))
		scale_factor = maxf(1.0, scale_factor)
		var draw_size: Vector2 = LOGICAL_SIZE * scale_factor
		var offset: Vector2 = (size - draw_size) * 0.5
		draw_rect(Rect2(Vector2.ZERO, size), COLORS.black)
		draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
		draw_rect(Rect2(Vector2.ZERO, LOGICAL_SIZE), COLORS.black)
		match controller._mode:
			Mode.TRANSITION: _draw_transition()
			Mode.MENU: _draw_menu()
			Mode.HOW_TO: _draw_how_to()
			Mode.PLAYING: _draw_gameplay()
			Mode.VICTORY: _draw_outcome(true)
			Mode.DEFEAT: _draw_outcome(false)
			Mode.EXIT_TRANSITION: _draw_exit_transition()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _text(value: String, at: Vector2, font_size: int, color: Color, centered := true) -> void:
		# The main game font is deliberately smooth. The arcade uses this small
		# bitmap alphabet instead, so it remains sharp at every integer scale.
		var pixel := clampi(roundi(float(font_size) / 6.0), 1, 3)
		var normalized := value.to_upper().replace("·", ".")
		var width := _pixel_text_width(normalized, pixel)
		var cursor := at.x - width * 0.5 if centered else at.x
		var top := at.y - 5.0 * pixel
		for character in normalized:
			var glyph: PackedStringArray = PIXEL_GLYPHS.get(character, PIXEL_GLYPHS["?"])
			var glyph_top := top - float(glyph.size() - 5) * pixel
			for row in glyph.size():
				for column in glyph[row].length():
					if glyph[row][column] == "1":
						draw_rect(Rect2(cursor + column * pixel, glyph_top + row * pixel, pixel, pixel), color)
			cursor += 4.0 * pixel

	func _pixel_text_width(value: String, pixel: int) -> float:
		return maxf(0.0, value.length() * 4.0 * pixel - pixel)

	func _frame() -> void:
		draw_rect(Rect2(Vector2.ZERO, LOGICAL_SIZE), COLORS.night)
		for star_index in 36:
			var x := float(posmod(star_index * 83 + 23, 300) + 10)
			var y := float(posmod(star_index * 47 + 17, 154) + 12)
			var pulse := 0.25 + 0.25 * sin(controller._animation_time * 2.0 + star_index)
			draw_rect(Rect2(x, y, 1, 1), Color(0.4, 0.8, 0.9, pulse))
		draw_rect(Rect2(4, 4, 312, 172), COLORS.wine, false, 3.0)
		draw_rect(Rect2(8, 8, 304, 164), COLORS.cyan, false, 1.0)
		for y in range(12, 172, 4):
			draw_line(Vector2(9, y), Vector2(311, y), Color(0.0, 0.0, 0.0, 0.12), 1.0)
		for corner in [Vector2(10, 10), Vector2(304, 10), Vector2(10, 164), Vector2(304, 164)]:
			draw_rect(Rect2(corner, Vector2(6, 6)), COLORS.gold)

	func _draw_transition() -> void:
		var progress := clampf(controller._transition_elapsed / 0.26, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, LOGICAL_SIZE), Color(0.0, 0.0, 0.0, progress))
		var inset := lerpf(150.0, 0.0, progress)
		draw_rect(Rect2(160.0 - inset, 90.0 - inset * 0.56, inset * 2.0, inset * 1.12), COLORS.gold, false, 2.0)

	func _draw_exit_transition() -> void:
		var progress := clampf(controller._transition_elapsed / 0.26, 0.0, 1.0)
		_draw_menu()
		var inset := lerpf(0.0, 150.0, progress)
		draw_rect(Rect2(160.0 - inset, 90.0 - inset * 0.56, inset * 2.0, inset * 1.12), COLORS.gold, false, 2.0)
		draw_rect(Rect2(Vector2.ZERO, LOGICAL_SIZE), Color(0.0, 0.0, 0.0, progress))

	func _draw_menu() -> void:
		_frame()
		draw_rect(Rect2(18, 17, 284, 51), COLORS.black)
		draw_rect(Rect2(20, 19, 280, 47), COLORS.wine, false, 2.0)
		for bulb in 14:
			var bulb_x := 30.0 + bulb * 20.0
			var bulb_color: Color = COLORS.gold if (bulb + int(controller._animation_time * 7.0)) % 3 != 0 else COLORS.red
			draw_circle(Vector2(bulb_x, 23), 1.5, bulb_color)
			draw_circle(Vector2(bulb_x, 62), 1.5, bulb_color)
		_text("PALACE ARCADE - 1991", Vector2(160, 33), 8, COLORS.cyan)
		_text("RESCATA EL CARRETE", Vector2(160, 53), 18, COLORS.gold)
		_draw_projector(Vector2(85, 116))
		# The moving film connects the machine to the difficulty selector.
		for segment in 6:
			var sy := 72.0 + float(segment) * 14.0 + fmod(controller._animation_time * 18.0, 14.0)
			draw_rect(Rect2(145, sy, 5, 8), COLORS.gold)
		var options := ["NORMAL  2:30", "DIFICIL 3:00", "COMO JUGAR"]
		var option_box_width := 130.0
		for option in options:
			option_box_width = maxf(option_box_width, _pixel_text_width("> " + String(option), 2) + 20.0)
		for option_index in options.size():
			var selected := controller._menu_selection == option_index
			var y := 89.0 + option_index * 24.0
			if selected:
				var box := Rect2(226.0 - option_box_width * 0.5, y - 14.0, option_box_width, 20.0)
				draw_rect(box, COLORS.wine)
				draw_rect(box, COLORS.gold, false, 1.0)
			_text(("> " if selected else "  ") + String(options[option_index]), Vector2(226, y), 9, COLORS.gold if selected else COLORS.cream)
		draw_rect(Rect2(21, 157, 278, 1), COLORS.cyan)
		_text("A/D ELEGIR   E/ESPACIO CONFIRMAR   ESC SALIR", Vector2(160, 169), 7, COLORS.cream)

	func _draw_how_to() -> void:
		_frame()
		_text("MANUAL DEL PROYECCIONISTA", Vector2(160, 29), 12, COLORS.gold)
		draw_rect(Rect2(21, 39, 278, 112), COLORS.black)
		draw_rect(Rect2(23, 41, 274, 108), COLORS.cyan, false, 1.0)
		_draw_reel(Vector2(63, 65), COLORS.cream)
		draw_rect(Rect2(50, 81, 26, 48), COLORS.blue)
		draw_rect(Rect2(48, 112, 30, 12), COLORS.gold, false, 2.0)
		draw_rect(Rect2(52, 99, 22, 8), COLORS.red)
		_text("A/D: CAMBIA DE CARRIL", Vector2(180, 57), 8, COLORS.cream)
		_text("E/ESPACIO: REPARA EN ORO", Vector2(180, 75), 8, COLORS.gold)
		_text("MANTEN S: RALENTIZA LA CINTA", Vector2(180, 93), 8, COLORS.cyan)
		_text("NO PULSES ANTES: PIERDES VIDA", Vector2(180, 111), 8, COLORS.red)
		_text("CIAN: +2 FOTOGRAMAS Y VIDA", Vector2(180, 129), 8, COLORS.cyan)
		_text("SALVA LA CUOTA EN CUATRO ACTOS", Vector2(160, 146), 8, COLORS.cream)
		_text("E/ESPACIO VOLVER     ESC SALIR", Vector2(160, 169), 8, COLORS.cream)

	func _draw_reel(center: Vector2, rim_color: Color) -> void:
		draw_circle(center, 14, COLORS.charcoal)
		draw_circle(center, 11, rim_color, false, 2.0)
		for spoke in 4:
			var angle := float(spoke) * TAU * 0.25 + 0.35
			draw_line(center, center + Vector2(cos(angle), sin(angle)) * 8.0, rim_color, 2.0)
		draw_circle(center, 3, COLORS.wine)

	func _draw_projector(center: Vector2) -> void:
		# Self-contained pixel-art silhouette; no new external or legacy asset.
		draw_rect(Rect2(center.x - 43, center.y + 27, 86, 4), COLORS.black)
		draw_rect(Rect2(center.x - 19, center.y + 2, 39, 28), COLORS.charcoal)
		draw_rect(Rect2(center.x - 17, center.y + 4, 35, 24), COLORS.blue)
		draw_rect(Rect2(center.x + 15, center.y + 9, 26, 10), COLORS.charcoal)
		draw_rect(Rect2(center.x + 38, center.y + 11, 7, 6), COLORS.gold)
		draw_rect(Rect2(center.x - 16, center.y + 27, 4, 6), COLORS.gold)
		draw_rect(Rect2(center.x + 11, center.y + 27, 4, 6), COLORS.gold)
		_draw_reel(center + Vector2(-13, -6), COLORS.cream)
		_draw_reel(center + Vector2(17, -5), COLORS.gold)
		draw_circle(center + Vector2(1, 15), 3, COLORS.red)

	func _draw_gameplay() -> void:
		_frame()
		draw_rect(Rect2(11, 11, 298, 29), COLORS.black)
		draw_rect(Rect2(12, 12, 296, 28), COLORS.wine, false, 1.0)
		_text("RESCATA EL CARRETE", Vector2(160, 21), 10, COLORS.gold)
		_text("VIDAS", Vector2(20, 33), 7, COLORS.cream, false)
		for life_index in controller._max_integrity():
			draw_rect(Rect2(47 + life_index * 6, 28, 4, 6), COLORS.red if life_index < controller._integrity else COLORS.charcoal)
		_text("CARRETES %02d" % controller._repairs, Vector2(160, 34), 9, COLORS.cyan)
		var time_left := ceili(maxf(0.0, controller._duration() - controller._elapsed))
		_text("%02d:%02d" % [time_left / 60, time_left % 60], Vector2(266, 34), 9, COLORS.cream)
		var progress := clampf(controller._elapsed / controller._duration(), 0.0, 1.0)
		draw_rect(Rect2(12, 39, 296, 2), COLORS.charcoal)
		draw_rect(Rect2(12, 39, 296.0 * progress, 2), COLORS.cyan)
		var lanes: Array[float] = [72.0, 160.0, 248.0]
		for lane_index in 3:
			var x: float = lanes[lane_index]
			draw_rect(Rect2(x - 22, 44, 44, 110), COLORS.black)
			draw_rect(Rect2(x - 19, 45, 38, 107), COLORS.blue)
			draw_rect(Rect2(x - 14, 45, 28, 107), Color("1c2942"))
			var scroll := int(controller._animation_time * (13.0 + controller._stage * 3.0)) % 12
			for sprocket in 10:
				var sy := 46 + sprocket * 12 + scroll
				if sy < 148:
					draw_rect(Rect2(x - 19, sy, 3, 5), COLORS.cream)
					draw_rect(Rect2(x + 16, sy, 3, 5), COLORS.cream)
			for frame_index in 5:
				var fy := 48.0 + frame_index * 20.0 + float(scroll)
				if fy < 132.0:
					draw_rect(Rect2(x - 12, fy, 24, 1), Color("355370"))
			draw_rect(Rect2(x - 24, 132, 48, 21), Color("74502e"))
			draw_rect(Rect2(x - 24, 132, 48, 21), COLORS.gold, false, 2.0)
			draw_rect(Rect2(x - 20, 142, 40, 2), COLORS.cream)
		for defect in controller._defects:
			var x: float = lanes[int(defect.lane)]
			var y := float(defect.y)
			var bonus := bool(defect.get("bonus", false))
			var color: Color = COLORS.cyan if bonus else (COLORS.red if int(defect.kind) == 0 else COLORS.violet)
			draw_rect(Rect2(x - 13, y - 7, 26, 14), COLORS.black)
			draw_rect(Rect2(x - 11, y - 5, 22, 10), color)
			draw_rect(Rect2(x - 13, y - 7, 26, 14), COLORS.cream, false, 1.0)
			if bonus:
				_text("+", Vector2(x, y + 3), 8, COLORS.black)
			else:
				draw_line(Vector2(x - 8, y + 3), Vector2(x + 8, y - 3), COLORS.black, 2.0)
		var operator_x: float = lanes[controller._operator_lane]
		draw_rect(Rect2(operator_x - 17, 151, 34, 8), COLORS.wine)
		draw_rect(Rect2(operator_x - 17, 151, 34, 8), COLORS.gold, false, 1.0)
		draw_rect(Rect2(operator_x - 7, 144, 14, 10), COLORS.cream)
		draw_rect(Rect2(operator_x - 4, 141, 8, 5), COLORS.gold)
		draw_circle(Vector2(operator_x, 149), 2, COLORS.red)
		if controller._flash_time > 0.0:
			draw_circle(Vector2(operator_x, 143), 19, Color(1.0, 0.93, 0.62, controller._flash_time * 3.5))
		if controller._feedback_time > 0.0:
			draw_rect(Rect2(80, 112, 160, 15), COLORS.black)
			_text(controller._feedback, Vector2(160, 123), 8, COLORS.gold)
		if controller._stage_banner_time > 0.0:
			draw_rect(Rect2(91, 82, 138, 27), COLORS.black)
			draw_rect(Rect2(91, 82, 138, 27), COLORS.cyan, false, 1.0)
			_text("ACTO %d / 4" % (controller._stage + 1), Vector2(160, 95), 12, COLORS.gold)
			_text("LA CINTA ACELERA" if controller._stage > 0 else "SALVA EL ESTRENO", Vector2(160, 105), 7, COLORS.cream)
		draw_rect(Rect2(11, 160, 298, 15), COLORS.black)
		_text("FOCO", Vector2(17, 171), 7, COLORS.cyan, false)
		draw_rect(Rect2(41, 165, 61, 6), COLORS.charcoal)
		draw_rect(Rect2(42, 166, 59.0 * controller._focus / 100.0, 4), COLORS.cyan)
		_text("S = CAMARA LENTA", Vector2(160, 171), 7, COLORS.cream)
		_text("PTS %06d" % controller._score, Vector2(236, 171), 7, COLORS.gold, false)

	func _draw_outcome(victory: bool) -> void:
		_frame()
		_draw_reel(Vector2(160, 43), COLORS.gold if victory else COLORS.red)
		var title := "¡PROYECCIÓN SALVADA!" if controller._difficulty == 0 else "¡FUNCIÓN RESTAURADA!"
		if not victory:
			title = "FIN DE LA PROYECCION"
		_text(title, Vector2(160, 76), 15, COLORS.gold if victory else COLORS.red)
		_text("%d FOTOGRAMAS  -  %06d PUNTOS" % [controller._repairs, controller._score], Vector2(160, 92), 8, COLORS.cyan)
		if victory:
			_text(controller._feedback, Vector2(160, 116), 10, COLORS.cream)
			_text("E/ESPACIO ELEGIR DIFICULTAD", Vector2(160, 145), 8, COLORS.gold)
			_text("ESC SALIR", Vector2(160, 163), 8, COLORS.cream)
		else:
			var options := ["REINTENTAR", "SELECCIONAR DIFICULTAD", "SALIR"]
			var option_box_width := 178.0
			for option in options:
				option_box_width = maxf(option_box_width, _pixel_text_width("> " + String(option), 1) + 20.0)
			for option_index in options.size():
				var selected := controller._defeat_selection == option_index
				var y := 111.0 + option_index * 18.0
				if selected:
					var box := Rect2(160.0 - option_box_width * 0.5, y - 10.0, option_box_width, 15.0)
					draw_rect(box, COLORS.wine)
					draw_rect(box, COLORS.gold, false, 1.0)
				_text(("> " if selected else "  ") + String(options[option_index]), Vector2(160, y), 8, COLORS.gold if selected else COLORS.cream)
