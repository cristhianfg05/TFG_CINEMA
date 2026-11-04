class_name CinemaMovieController
extends Node3D

signal clip_completed(room_id: StringName, clip_number: int)
signal movie_cycle_completed(room_id: StringName, cycle_number: int)

const SCREEN_SHADER := preload("res://shaders/cinema_movie_screen.gdshader")
const DEFAULT_CLIP_COUNT := 4

@export var room_id: StringName
@export_dir var movie_folder: String
@export var screen_path: NodePath
@export var screen_size := Vector2(12.0, 5.0)
@export var audience_side := 1.0
@export var video_aspect := 16.0 / 9.0
@export var video_extension := "ogv"
@export_range(1, 12, 1) var clip_count := DEFAULT_CLIP_COUNT

var current_clip := -1
var completed_cycles := 0
var _manager: GameplayManager
var _video: VideoStreamPlayer
var _viewport: SubViewport
var _surface: MeshInstance3D
var _clips: Array[VideoStream] = []
var _clip_lengths: Array[float] = []
var _watching := false
var _watch_elapsed := 0.0
var _last_stream_position := 0.0
var _shader_prewarmed := false


func _ready() -> void:
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	_build_surface()
	_clip_lengths.resize(clip_count)
	_clip_lengths.fill(0.0)
	_load_clips()
	if _clips.is_empty() or DisplayServer.get_name() == "headless":
		_shader_prewarmed = true
	else:
		# Compile the projection shader during startup, before a lever can start
		# the first video. The one-time compile otherwise stalls its first frame.
		call_deferred("_prewarm_screen_shader")
	if _manager == null:
		push_error("CinemaMovieController requires GameplayManager.")
		return
	_manager.room_activated.connect(_on_room_activated)
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player != null:
		player.sat_in_cinema_seat.connect(_on_player_sat)
		player.stood_from_cinema_seat.connect(_on_player_stood)
	if _shader_prewarmed and _manager.is_room_activated(room_id) and is_ready_for_playback():
		_play_clip(0)


func _exit_tree() -> void:
	if _video != null:
		_video.stop()
		_video.stream = null
	if _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _surface != null and _surface.material_override is ShaderMaterial:
		(_surface.material_override as ShaderMaterial).set_shader_parameter("movie_frame", null)
		_surface.material_override = null


func _process(_delta: float) -> void:
	if current_clip < 0 or _video == null or not _video.is_playing():
		return
	var length := _video.get_stream_length()
	if length > 0.0:
		_clip_lengths[current_clip] = length
	var position := _video.stream_position
	if _watching and position >= _last_stream_position:
		_watch_elapsed += position - _last_stream_position
	_last_stream_position = position
	_check_watch_complete()


func is_ready_for_playback() -> bool:
	return _clips.size() == clip_count and _surface != null


func get_missing_clips() -> PackedStringArray:
	var missing := PackedStringArray()
	for number in range(1, clip_count + 1):
		var path := "%s/Movie_%d.%s" % [movie_folder, number, video_extension]
		if not FileAccess.file_exists(path):
			missing.append(path)
	return missing


func get_cycle_length() -> float:
	var total := 0.0
	for length in _clip_lengths:
		if float(length) <= 0.0:
			return 0.0
		total += float(length)
	return total


func is_showing_movie() -> bool:
	return _surface != null and _surface.visible and _video != null and _video.is_playing()


func _build_surface() -> void:
	# Rooms 3/4 can carry configuration before their authored screen exists.
	if screen_path.is_empty():
		return
	var screen := get_node_or_null(screen_path) as Node3D
	if screen == null:
		push_error("Movie screen is missing for %s." % room_id)
		return
	_viewport = SubViewport.new()
	_viewport.name = "MovieViewport"
	_viewport.size = Vector2i(960, 540)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	_video = VideoStreamPlayer.new()
	_video.name = "VideoPlayer"
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video.expand = true
	_video.loop = false
	_video.volume_db = -80.0 # Cinema music remains on the existing 3D speakers.
	_video.finished.connect(_on_clip_finished)
	_viewport.add_child(_video)
	_surface = MeshInstance3D.new()
	_surface.name = "MovieSurface"
	var quad := QuadMesh.new()
	quad.size = screen_size - Vector2(0.14, 0.14)
	_surface.mesh = quad
	add_child(_surface)
	_surface.global_position = screen.global_position + Vector3(0.0, 0.0, audience_side * 0.065)
	if audience_side < 0.0:
		_surface.rotation.y = PI
	var material := ShaderMaterial.new()
	material.shader = SCREEN_SHADER
	material.set_shader_parameter("movie_frame", _viewport.get_texture())
	material.set_shader_parameter("screen_aspect", screen_size.x / screen_size.y)
	material.set_shader_parameter("video_aspect", video_aspect)
	_surface.material_override = material
	_surface.visible = false


func _prewarm_screen_shader() -> void:
	if _surface == null or not is_inside_tree():
		_shader_prewarmed = true
		return
	var warm_viewport := SubViewport.new()
	warm_viewport.name = "MovieShaderWarmup"
	warm_viewport.size = Vector2i(16, 16)
	warm_viewport.own_world_3d = true
	warm_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(warm_viewport)
	var warm_camera := Camera3D.new()
	warm_camera.position.z = 2.0
	warm_camera.current = true
	warm_viewport.add_child(warm_camera)
	var warm_quad := MeshInstance3D.new()
	warm_quad.mesh = QuadMesh.new()
	warm_quad.material_override = _surface.material_override
	warm_viewport.add_child(warm_quad)
	await RenderingServer.frame_post_draw
	_shader_prewarmed = true
	if is_instance_valid(warm_viewport):
		warm_viewport.queue_free()
	if is_inside_tree() and _manager != null and _manager.is_room_activated(room_id) and is_ready_for_playback() and current_clip < 0:
		_play_clip(0)


func _load_clips() -> void:
	_clips.clear()
	if not get_missing_clips().is_empty():
		return
	for number in range(1, clip_count + 1):
		var stream := VideoStreamTheora.new()
		stream.file = "%s/Movie_%d.%s" % [movie_folder, number, video_extension]
		_clips.append(stream)


func _on_room_activated(activated_room_id: StringName) -> void:
	if activated_room_id != room_id or _video == null:
		return
	_load_clips()
	if _shader_prewarmed and is_ready_for_playback() and current_clip < 0:
		_play_clip(0)


func _play_clip(index: int) -> void:
	if not is_ready_for_playback() or index < 0 or index >= clip_count:
		return
	current_clip = index
	_video.stream = _clips[index]
	_video.play()
	_last_stream_position = 0.0
	_surface.visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _on_clip_finished() -> void:
	if current_clip < 0:
		return
	var completed_index := current_clip
	var length := _video.get_stream_length()
	if length > 0.0:
		_clip_lengths[completed_index] = length
		if _watching:
			_watch_elapsed += maxf(0.0, length - _last_stream_position)
	clip_completed.emit(room_id, completed_index + 1)
	if completed_index == clip_count - 1:
		completed_cycles += 1
		movie_cycle_completed.emit(room_id, completed_cycles)
	_check_watch_complete()
	_play_clip((completed_index + 1) % clip_count)


func _on_player_sat(seated_room_id: StringName, _seat_id: StringName) -> void:
	if seated_room_id != room_id or not is_showing_movie():
		return
	_watching = true
	_watch_elapsed = 0.0
	_last_stream_position = _video.stream_position


func _on_player_stood(seated_room_id: StringName, _seat_id: StringName) -> void:
	if seated_room_id == room_id:
		_watching = false
		_watch_elapsed = 0.0


func _check_watch_complete() -> void:
	if not _watching or _manager == null or _manager.is_movie_watched(room_id):
		return
	var full_length := get_cycle_length()
	if full_length > 0.0 and _watch_elapsed + 0.02 >= full_length:
		_watching = false
		_manager.mark_movie_watched(room_id)
