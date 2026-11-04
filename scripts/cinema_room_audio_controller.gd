extends Node3D

@export var room_id: StringName
@export var physical_room_path: NodePath
@export var speaker_names: PackedStringArray
@export var disabled_audio: AudioStream
@export var enabled_music: AudioStream
@export var side_music: AudioStream
@export var side_music_always_on := false
@export var speaker_height_offset := 1.72
@export var static_volume_db := -18.0
@export var static_max_distance := 11.0
@export var static_only_inside_room := false
@export var music_close_volume_db := -26.0
@export var music_far_volume_db := -60.0
@export var transition_seconds := 0.7

const MUSIC_FULL_VOLUME_DISTANCE := 4.0
const MUSIC_QUIET_VOLUME_DISTANCE := 42.0
const SIDE_MUSIC_VOLUME_DB := -39.0
const SIDE_STATIC_VOLUME_DB := -27.0

var _manager: GameplayManager
var _player: PlayerController
var _static_players: Array[AudioStreamPlayer3D] = []
var _music_players: Array[AudioStreamPlayer3D] = []
var _side_speakers: Array[Node3D] = []
var _side_music_players: Array[AudioStreamPlayer3D] = []
var _side_static_player: AudioStreamPlayer3D
var _side_static_timer: Timer
var _side_static_stop_timer: Timer
var _random := RandomNumberGenerator.new()
var _intro_finished := false
var _activated := false
var _mix := 0.0
var _transition: Tween


func _ready() -> void:
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	if _manager == null:
		push_error("Room audio requires the existing GameplayManager.")
		return
	_activated = _manager.is_room_activated(room_id)
	_mix = 1.0 if _activated else 0.0
	_manager.room_activated.connect(_on_room_activated)
	# Future rooms may already have state/configuration but no authored speakers.
	if physical_room_path.is_empty() or speaker_names.is_empty():
		return
	var physical_room := get_node_or_null(physical_room_path)
	if physical_room == null or disabled_audio == null:
		push_error("Room audio %s is missing its physical room or static loop." % room_id)
		return
	var static_loop := _loop_copy(disabled_audio)
	var music_loop := _loop_copy(enabled_music) if enabled_music != null else null
	var wall_music_source := side_music if side_music != null else enabled_music
	var wall_music_loop := _loop_copy(wall_music_source) if wall_music_source != null else null
	for speaker_index in speaker_names.size():
		var physical_speaker := physical_room.get_node_or_null(speaker_names[speaker_index]) as Node3D
		if physical_speaker == null:
			push_error("Room audio %s cannot find speaker %s." % [room_id, speaker_names[speaker_index]])
			return
		var location := physical_speaker.global_position + Vector3.UP * speaker_height_offset
		var static_player := AudioStreamPlayer3D.new()
		static_player.name = "Static_%02d" % (speaker_index + 1)
		static_player.stream = static_loop
		static_player.bus = &"Ambience"
		static_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		static_player.unit_size = 2.0
		static_player.max_distance = static_max_distance
		static_player.attenuation_filter_cutoff_hz = 20500.0
		add_child(static_player)
		static_player.global_position = location
		_static_players.append(static_player)
		var music_player := AudioStreamPlayer3D.new()
		music_player.name = "Music_%02d" % (speaker_index + 1)
		music_player.stream = music_loop
		music_player.bus = &"Music"
		# Positional panning stays active; the explicit distance curve sets level.
		music_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		music_player.max_distance = 70.0
		music_player.attenuation_filter_cutoff_hz = 20500.0
		add_child(music_player)
		music_player.global_position = location
		_music_players.append(music_player)
	# Lateral wall speakers share the room's approved stream. Their individual
	# inverse-distance emitters keep the audio attached to each physical bay.
	for wall_node in physical_room.find_children("*WallSpeaker_*", "Node3D", false, false):
		var wall_speaker := wall_node as Node3D
		_side_speakers.append(wall_speaker)
		if wall_music_loop == null:
			continue
		var wall_player := AudioStreamPlayer3D.new()
		wall_player.name = "WallMusic_%02d" % _side_speakers.size()
		wall_player.stream = wall_music_loop
		wall_player.bus = &"Music"
		wall_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		wall_player.unit_size = 2.0
		wall_player.max_distance = 12.0
		wall_player.attenuation_filter_cutoff_hz = 20500.0
		add_child(wall_player)
		wall_player.global_position = wall_speaker.global_position
		_side_music_players.append(wall_player)
	if _side_speakers.is_empty():
		push_error("Room audio %s has no lateral wall speakers." % room_id)
		return
	_random.randomize()
	_side_static_player = AudioStreamPlayer3D.new()
	_side_static_player.name = "WallInterference"
	_side_static_player.stream = static_loop
	_side_static_player.bus = &"Ambience"
	_side_static_player.volume_db = SIDE_STATIC_VOLUME_DB
	_side_static_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_side_static_player.unit_size = 2.0
	_side_static_player.max_distance = 11.0
	add_child(_side_static_player)
	_side_static_timer = Timer.new()
	_side_static_timer.name = "WallInterferenceInterval"
	_side_static_timer.one_shot = true
	add_child(_side_static_timer)
	_side_static_timer.timeout.connect(_on_side_static_timeout)
	_side_static_stop_timer = Timer.new()
	_side_static_stop_timer.name = "WallInterferenceStop"
	_side_static_stop_timer.one_shot = true
	add_child(_side_static_stop_timer)
	_side_static_stop_timer.timeout.connect(_side_static_player.stop)
	if static_only_inside_room and _player != null:
		_player.room_changed.connect(_on_player_room_changed)
	_update_mix()
	var intro := get_parent().get_parent().get_node_or_null("GameIntro") as GameIntro
	_intro_finished = intro == null or (DisplayServer.get_name() == "headless" and not intro.run_in_headless)
	if intro != null and not _intro_finished:
		intro.intro_completed.connect(_on_intro_completed)
	if _intro_finished:
		_start_playback()


func _process(_delta: float) -> void:
	if not _music_players.is_empty() and (_activated or _transition != null):
		_update_mix()


func _on_player_room_changed(_new_room_id: StringName) -> void:
	_update_mix()


func has_enabled_music() -> bool:
	return enabled_music != null


func is_activated() -> bool:
	return _activated


func _on_intro_completed() -> void:
	_intro_finished = true
	_start_playback()


func _start_playback() -> void:
	_update_mix()
	for player in _static_players:
		if not player.playing:
			player.play()
	for player in _side_music_players:
		if (_activated or side_music_always_on) and not player.playing:
			player.play()
	if _activated:
		for player in _music_players:
			if player.stream != null and not player.playing:
				player.play()
	_side_static_timer.start(_random.randf_range(7.0, 14.0))


func _on_room_activated(activated_room_id: StringName) -> void:
	if activated_room_id != room_id or _activated:
		return
	_activated = true
	if not _intro_finished:
		_mix = 1.0
		_update_mix()
		return
	for player in _music_players:
		if player.stream != null and not player.playing:
			player.play()
	for player in _side_music_players:
		if not player.playing:
			player.play()
	if _transition != null and _transition.is_running():
		_transition.kill()
	_transition = create_tween()
	_transition.tween_property(self, "_mix", 1.0, transition_seconds)


func _update_mix() -> void:
	var static_audible := not static_only_inside_room or _player == null or _player.get_current_room_id() == room_id
	for player in _static_players:
		player.volume_db = lerpf(static_volume_db, -80.0, _mix) if static_audible else -80.0
	for player in _music_players:
		if player.stream == null:
			continue
		var proximity := 1.0
		if _player != null:
			var distance := _player.global_position.distance_to(player.global_position)
			proximity = clampf(
				(distance - MUSIC_FULL_VOLUME_DISTANCE) /
				(MUSIC_QUIET_VOLUME_DISTANCE - MUSIC_FULL_VOLUME_DISTANCE),
				0.0,
				1.0
			)
		var target_db := lerpf(music_close_volume_db, music_far_volume_db, proximity)
		player.volume_db = lerpf(-80.0, target_db, _mix)
	for player in _side_music_players:
		player.volume_db = lerpf(-80.0, SIDE_MUSIC_VOLUME_DB, 1.0 if side_music_always_on else _mix)


func _on_side_static_timeout() -> void:
	# A short burst from one randomly selected wall speaker every 18-32 s;
	# the music keeps playing underneath. Outside the room the burst is skipped.
	if _player != null and _player.get_current_room_id() == room_id:
		var wall_speaker := _side_speakers[_random.randi_range(0, _side_speakers.size() - 1)]
		_side_static_player.global_position = wall_speaker.global_position
		var last_start := maxf(0.0, disabled_audio.get_length() - 1.0)
		_side_static_player.play(_random.randf_range(0.0, last_start))
		_side_static_stop_timer.start(_random.randf_range(0.45, 0.85))
	_side_static_timer.start(_random.randf_range(18.0, 32.0))


func _loop_copy(source: AudioStream) -> AudioStream:
	var result := source.duplicate() as AudioStream
	if result is AudioStreamWAV:
		var wav := result as AudioStreamWAV
		wav.loop_begin = 0
		wav.loop_end = maxi(1, roundi(wav.get_length() * wav.mix_rate))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return result
