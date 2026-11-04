class_name CinemaGlobalMusic
extends Node

@export var stream: AudioStream
@export var bus: StringName = &"Music"
@export var base_volume_db := -34.0
@export var ducked_volume_db := -48.0
@export var fade_seconds := 1.2

var _player: AudioStreamPlayer
var _fade: Tween
var _intro_finished := false
var _ducked := false


func _ready() -> void:
	var playback_stream := stream.duplicate() as AudioStream if stream != null else null
	if playback_stream == null:
		push_error("Cinema global music source is missing.")
		return
	if playback_stream is AudioStreamWAV:
		var wav := playback_stream as AudioStreamWAV
		wav.loop_begin = 0
		wav.loop_end = maxi(1, roundi(wav.get_length() * wav.mix_rate))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_player = AudioStreamPlayer.new()
	_player.name = "Player"
	_player.stream = playback_stream
	_player.bus = bus
	_player.volume_db = base_volume_db
	add_child(_player)
	var intro := get_parent().get_node_or_null("GameIntro") as GameIntro
	_intro_finished = intro == null or (DisplayServer.get_name() == "headless" and not intro.run_in_headless)
	if intro != null and not _intro_finished:
		intro.intro_completed.connect(_on_intro_completed)
	if _intro_finished:
		_player.play()


func set_ducked(ducked: bool) -> void:
	if _ducked == ducked or _player == null:
		return
	_ducked = ducked
	if _fade != null and _fade.is_running():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", ducked_volume_db if ducked else base_volume_db, fade_seconds)


func is_ducked() -> bool:
	return _ducked


func _on_intro_completed() -> void:
	_intro_finished = true
	if _player != null and not _player.playing:
		_player.play()
