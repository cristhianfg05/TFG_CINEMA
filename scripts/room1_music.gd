extends Node3D

@export var stream: AudioStream
@export var bus: StringName = &"Music"

const SPEAKER_POSITIONS := [
	Vector3(-8.25, 1.8, -13.35),
	Vector3(8.25, 1.8, -13.35),
]
# Each source is slightly quieter than the former single player so their
# combined level remains close to the approved Room 1 mix.
const CLOSE_VOLUME_DB := -26.0
const FAR_VOLUME_DB := -48.0
const FULL_VOLUME_DISTANCE := 4.0
const QUIET_VOLUME_DISTANCE := 38.0

var _player: PlayerController
var _intro_finished := false
var _speakers: Array[AudioStreamPlayer3D] = []


func _ready() -> void:
	# The imported WAV has no loop end because it was originally a one-shot.
	# Duplicate it so enabling its full-length loop does not mutate the legacy
	# resource shared by other audio players.
	var playback_stream := stream.duplicate() as AudioStream if stream != null else null
	if playback_stream == null:
		push_error("Room 1 music source is missing.")
		return
	if playback_stream is AudioStreamWAV:
		var wav := playback_stream as AudioStreamWAV
		wav.loop_begin = 0
		wav.loop_end = maxi(1, roundi(wav.get_length() * wav.mix_rate))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	for speaker_index in SPEAKER_POSITIONS.size():
		var speaker := AudioStreamPlayer3D.new()
		speaker.name = "LeftSpeaker" if speaker_index == 0 else "RightSpeaker"
		speaker.position = SPEAKER_POSITIONS[speaker_index]
		speaker.stream = playback_stream
		speaker.bus = bus
		# Keep positional panning while the existing proximity curve controls
		# loudness; using both distance curves would attenuate the music twice.
		speaker.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		speaker.attenuation_filter_cutoff_hz = 20500.0
		add_child(speaker)
		_speakers.append(speaker)
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	if _player == null:
		push_warning("Room1Music requires a PlayerController for speaker proximity.")
		return
	var intro := get_parent().get_node_or_null("GameIntro") as GameIntro
	_intro_finished = intro == null or (DisplayServer.get_name() == "headless" and not intro.run_in_headless)
	if intro != null and not _intro_finished:
		intro.intro_completed.connect(_on_intro_completed)
	_update_playback()


func _process(_delta: float) -> void:
	if _player != null and _speakers[0].playing:
		_update_proximity_volume()


func _on_intro_completed() -> void:
	_intro_finished = true
	_update_playback()


func _update_playback() -> void:
	# Music stays alive outside Room 1; distance from its real speakers makes
	# it fade naturally through the corridor instead of cutting off at a zone.
	var should_play := _intro_finished and _player != null
	for speaker in _speakers:
		if should_play and not speaker.playing:
			speaker.play()
		elif not should_play and speaker.playing:
			speaker.stop()
	if should_play:
		_update_proximity_volume()


func _update_proximity_volume() -> void:
	for speaker in _speakers:
		var distance := _player.global_position.distance_to(speaker.global_position)
		var proximity := clampf(
			(distance - FULL_VOLUME_DISTANCE) /
			(QUIET_VOLUME_DISTANCE - FULL_VOLUME_DISTANCE),
			0.0,
			1.0
		)
		speaker.volume_db = lerpf(CLOSE_VOLUME_DB, FAR_VOLUME_DB, proximity)
