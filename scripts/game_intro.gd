class_name GameIntro
extends CanvasLayer

signal intro_completed

const HUD_FONT := preload("res://assets/fonts/PalaceHUD-Bold.ttf")
const CREAM := Color("f7e6bd")
const GOLD := Color("f3bd4c")
const EYELID_COLOR := Color("080607")
const CASSETTE_STREAM := preload("res://assets/audio/sfx/cassette/cassette_recorder_start_02.wav")
const TYPING_STREAM := preload("res://assets/audio/sfx/dialogue/dialogue_soft_typing_03_loop.wav")
const RecordingCatalog := preload("res://resources/recordings/recording_catalog.gd")
const RECORDING_LINES := RecordingCatalog.INTRO_LINES
const RECORDING_CHAR_INTERVAL := 0.045
const RECORDING_LINE_HOLD := 1.0
const RECORDING_01_NARRATOR := "Manager"

@export var run_in_headless := false
@export_range(0.65, 1.20, 0.01) var seated_eye_height := 0.92
@export_range(-82.0, -35.0, 1.0) var seated_pitch_degrees := -68.0
@export_range(0.4, 2.5, 0.05) var stand_duration := 1.25
@export_range(0.2, 1.5, 0.05) var eyelid_open_duration := 0.85
@export var intro_audio_stream: AudioStream

var _overlay: Control
var _top_eyelid: ColorRect
var _bottom_eyelid: ColorRect
var _prompt_row: HBoxContainer
var _audio_player: AudioStreamPlayer
var _player: PlayerController
var _active := false
var _opening := false
var _eyelid_tween: Tween
var _prompt_tween: Tween
var _recording_canvas: CanvasLayer
var _recording_panel: PanelContainer
var _recording_caption: Label
var _recording_text: Label
var _cassette_player: AudioStreamPlayer
var _typing_player: AudioStreamPlayer
var _recording_state: StringName = &"idle"
var _recording_timer := 0.0
var _recording_elapsed := 0.0
var _recording_line_index := 0
var _active_recording_lines: Array[String] = []
var _current_recording_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_intro")
	_build_ui()
	if DisplayServer.get_name() == "headless" and not run_in_headless:
		_overlay.visible = false
		return
	call_deferred("_begin_intro")


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact") and not event.is_echo() and not _opening:
		_start_opening()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_update_recording(delta)


func is_active() -> bool:
	return _active


func is_opening() -> bool:
	return _opening


func complete_immediately() -> void:
	if not _active:
		return
	if _eyelid_tween and _eyelid_tween.is_valid():
		_eyelid_tween.kill()
	if _prompt_tween and _prompt_tween.is_valid():
		_prompt_tween.kill()
	if _player:
		_player.complete_game_intro_immediately()
	if _active:
		_finish_intro()


func _begin_intro() -> void:
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	if _player == null:
		push_error("GameIntro requires a PlayerController")
		_overlay.visible = false
		return
	_active = true
	_opening = false
	_overlay.visible = true
	# Closed eyelids are on layer 50; subtitles must be visible with the E prompt.
	_recording_canvas.layer = 51
	_reset_visual_state()
	_set_gameplay_hud_visible(false)
	_player.begin_game_intro(seated_eye_height, seated_pitch_degrees)
	_player.intro_finished.connect(_finish_intro, CONNECT_ONE_SHOT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var manager := get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	if manager != null and not manager.loaded_save:
		manager.discover_recording("01")
		_start_recording("01")


func _start_opening() -> void:
	_opening = true
	if intro_audio_stream != null:
		_audio_player.stream = intro_audio_stream
		_audio_player.play()

	_prompt_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_prompt_tween.set_parallel(true)
	_prompt_tween.tween_property(_prompt_row, "modulate:a", 0.0, 0.16)
	_prompt_tween.tween_property(_prompt_row, "scale", Vector2(0.96, 0.96), 0.16)

	_eyelid_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_eyelid_tween.set_parallel(true)
	_eyelid_tween.tween_property(_top_eyelid, "anchor_bottom", 0.0, eyelid_open_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_eyelid_tween.tween_property(_bottom_eyelid, "anchor_top", 1.0, eyelid_open_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_player.start_game_intro_stand(stand_duration)


func _finish_intro() -> void:
	if not _active:
		return
	_active = false
	_opening = false
	_overlay.visible = false
	_recording_canvas.layer = 9
	_set_gameplay_hud_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	intro_completed.emit()


func _set_gameplay_hud_visible(should_show: bool) -> void:
	var hud = get_tree().get_first_node_in_group("gameplay_hud")
	if hud and hud.has_method("set_gameplay_hud_visible"):
		hud.set_gameplay_hud_visible(should_show)


func _set_recording_hud_layout(active: bool) -> void:
	var hud = get_tree().get_first_node_in_group("gameplay_hud")
	if hud and hud.has_method("set_recording_layout_active"):
		hud.set_recording_layout_active(active)


func _reset_visual_state() -> void:
	_top_eyelid.anchor_bottom = 0.52
	_bottom_eyelid.anchor_top = 0.48
	_prompt_row.modulate = Color.WHITE
	_prompt_row.scale = Vector2.ONE
	_prompt_row.pivot_offset = _prompt_row.size * 0.5


func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.name = "IntroOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_top_eyelid = ColorRect.new()
	_top_eyelid.name = "TopEyelid"
	_top_eyelid.color = EYELID_COLOR
	_top_eyelid.set_anchor(SIDE_RIGHT, 1.0)
	_top_eyelid.set_anchor(SIDE_BOTTOM, 0.52)
	_top_eyelid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_top_eyelid)

	_bottom_eyelid = ColorRect.new()
	_bottom_eyelid.name = "BottomEyelid"
	_bottom_eyelid.color = EYELID_COLOR
	_bottom_eyelid.set_anchor(SIDE_TOP, 0.48)
	_bottom_eyelid.set_anchor(SIDE_RIGHT, 1.0)
	_bottom_eyelid.set_anchor(SIDE_BOTTOM, 1.0)
	_bottom_eyelid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_bottom_eyelid)

	var prompt_center := CenterContainer.new()
	prompt_center.name = "PromptCenter"
	prompt_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prompt_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(prompt_center)

	_prompt_row = HBoxContainer.new()
	_prompt_row.name = "PromptRow"
	_prompt_row.add_theme_constant_override("separation", 14)
	_prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_center.add_child(_prompt_row)

	var press_text := _make_label("PULSA", 28)
	_prompt_row.add_child(press_text)

	var key_panel := PanelContainer.new()
	key_panel.name = "Key"
	key_panel.custom_minimum_size = Vector2(58, 48)
	key_panel.add_theme_stylebox_override("panel", _style(Color("241a1d"), GOLD, 7, 2))
	key_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_row.add_child(key_panel)
	var key_text := _make_label("E", 25)
	key_text.name = "KeyText"
	key_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_panel.add_child(key_text)

	var stand_text := _make_label("PARA LEVANTARTE", 28)
	_prompt_row.add_child(stand_text)

	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "IntroAudio"
	add_child(_audio_player)
	_build_recording_ui()


func _build_recording_ui() -> void:
	# Layer 9 puts subtitles behind the gameplay HUD. During the seated intro
	# they temporarily rise to 51 so the closed eyelids cannot hide them.
	_recording_canvas = CanvasLayer.new()
	_recording_canvas.name = "RecordingCanvas"
	_recording_canvas.layer = 9
	add_child(_recording_canvas)
	_recording_panel = PanelContainer.new()
	_recording_panel.name = "RecordingPanel"
	_recording_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_recording_panel.offset_left = -350.0
	_recording_panel.offset_right = 350.0
	_recording_panel.offset_top = -154.0
	_recording_panel.offset_bottom = -16.0
	_recording_panel.add_theme_stylebox_override("panel", _style(Color(0.02, 0.018, 0.02, 0.78), Color(0.31, 0.26, 0.19, 0.82), 8, 1))
	_recording_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recording_panel.visible = false
	_recording_canvas.add_child(_recording_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 19)
	margin.add_theme_constant_override("margin_right", 19)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recording_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	_recording_caption = _make_label("Grabación 01 - %s" % RECORDING_01_NARRATOR, 16)
	_recording_caption.name = "RecordingCaption"
	_recording_caption.add_theme_color_override("font_color", GOLD)
	column.add_child(_recording_caption)
	_recording_text = _make_label("", 26)
	_recording_text.name = "RecordingText"
	_recording_text.add_theme_color_override("font_color", GOLD)
	_recording_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recording_text.custom_minimum_size = Vector2(0, 78)
	_recording_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(_recording_text)

	_cassette_player = AudioStreamPlayer.new()
	_cassette_player.name = "RecordingCassette"
	_cassette_player.bus = &"UI"
	_cassette_player.volume_db = -12.0
	_cassette_player.stream = CASSETTE_STREAM
	add_child(_cassette_player)
	_typing_player = AudioStreamPlayer.new()
	_typing_player.name = "RecordingTyping"
	_typing_player.bus = &"UI"
	_typing_player.volume_db = -15.0
	var typing_loop := TYPING_STREAM.duplicate() as AudioStreamWAV
	typing_loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	typing_loop.loop_begin = 0
	typing_loop.loop_end = typing_loop.data.size() / 4
	_typing_player.stream = typing_loop
	add_child(_typing_player)


func can_play_recording() -> bool:
	return _recording_state == &"idle" and not _active and not get_tree().paused


func play_recording(recording_id: String) -> bool:
	if not can_play_recording() or not RecordingCatalog.has_definition(recording_id):
		return false
	_start_recording(recording_id)
	return true


func _start_recording(recording_id: String = "01") -> void:
	var definition := RecordingCatalog.get_definition(recording_id)
	if definition.is_empty():
		return
	_active_recording_lines.clear()
	for line in definition.lines:
		_active_recording_lines.append(String(line))
	_current_recording_id = recording_id
	var manager := get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	if recording_id == "13" and manager != null:
		manager.mark_recording_heard("13")
	var mateo_revealed := manager != null and manager.is_recording_heard("13")
	_recording_caption.text = "Grabación %s - %s" % [recording_id, RecordingCatalog.narrator_for(recording_id, mateo_revealed)]
	_set_recording_hud_layout(true)
	_recording_panel.visible = true
	_recording_text.text = ""
	_recording_line_index = 0
	_recording_state = &"cassette_open"
	_recording_timer = CASSETTE_STREAM.get_length()
	_cassette_player.play()


func _start_recording_line(index: int) -> void:
	_recording_line_index = index
	_recording_text.text = _active_recording_lines[index]
	_recording_text.visible_characters = 1
	_recording_elapsed = 0.0
	_recording_state = &"typing"
	_typing_player.play()


func _update_recording(delta: float) -> void:
	if _recording_state == &"idle":
		return
	if get_tree().paused:
		_recording_panel.visible = false
		_cassette_player.stream_paused = true
		_typing_player.stream_paused = true
		return
	_recording_panel.visible = true
	_cassette_player.stream_paused = false
	_typing_player.stream_paused = false
	match _recording_state:
		&"cassette_open":
			_recording_timer -= delta
			if _recording_timer <= 0.0:
				_cassette_player.stop()
				_start_recording_line(0)
		&"typing":
			_recording_elapsed += delta
			var line_length: int = _active_recording_lines[_recording_line_index].length()
			_recording_text.visible_characters = mini(line_length, 1 + floori(_recording_elapsed / RECORDING_CHAR_INTERVAL))
			if _recording_text.visible_characters >= line_length:
				_typing_player.stop()
				_recording_state = &"hold"
				_recording_timer = RECORDING_LINE_HOLD
		&"hold":
			_recording_timer -= delta
			if _recording_timer <= 0.0:
				if _recording_line_index + 1 < _active_recording_lines.size():
					_start_recording_line(_recording_line_index + 1)
				else:
					_recording_state = &"cassette_close"
					_recording_text.text = ""
					_recording_timer = CASSETTE_STREAM.get_length()
					_cassette_player.play()
		&"cassette_close":
			_recording_timer -= delta
			if _recording_timer <= 0.0:
				_cassette_player.stop()
				_recording_panel.visible = false
				_recording_state = &"idle"
				_set_recording_hud_layout(false)
				var manager := get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
				if manager != null:
					manager.mark_recording_heard(_current_recording_id)


func _make_label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_outline_color", Color("160f11"))
	label.add_theme_constant_override("outline_size", 5)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
