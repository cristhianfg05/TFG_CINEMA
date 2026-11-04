extends Node3D

const HAMMER_MODEL := preload("res://assets/pipeline/props/manager_mallet.glb")
const GRIP_HAND_MODEL := preload("res://assets/pipeline/characters/hammer_grip_hand.glb")
const APPROVED_STONE_HIT := preload("res://assets/audio/sfx/hammer/hammer_stone_02.wav")
const APPROVED_SWING := preload("res://assets/audio/sfx/hammer/hammer_swing_01.wav")
const IDLE_POSITION := Vector3(0.35, -0.59, -0.91)
const IDLE_ROTATION := Vector3(13.0, -21.0, -17.0)
const WINDUP_POSITION := Vector3(0.42, -0.55, -0.76)
const WINDUP_ROTATION := Vector3(28.0, -39.0, -10.0)
const IMPACT_POSITION := Vector3(0.20, -0.73, -1.07)
const IMPACT_ROTATION := Vector3(-43.0, 15.0, -77.0)
const WALL_REST_POSITION := Vector3(36.62, 1.12, 16.05)
const WALL_REST_ROTATION := Vector3(20.0, 0.0, 135.0)

var _manager: GameplayManager
var _player: PlayerController
var _menu: UpgradeMenu
var _intro: GameIntro
var _pivot: Node3D
var _held_model: Node3D
var _grip_hand: Node3D
var _mounted_hammer: Node3D
var _hud: CanvasLayer
var _recording_canvas: CanvasLayer
var _hud_was_visible := true
var _recording_was_visible := true
var _swing_audio: AudioStreamPlayer
var _stone_audio: AudioStreamPlayer3D
var _swinging := false
var _picking_up := false
var _finishing := false
var _released := false
var _swing_tween: Tween
var _placement_start: Transform3D
var _placement_target: Transform3D


func _ready() -> void:
	add_to_group("hammer_controller")
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	_menu = get_tree().get_first_node_in_group("upgrade_menu") as UpgradeMenu
	_intro = get_tree().get_first_node_in_group("game_intro") as GameIntro
	_hud = get_tree().get_first_node_in_group("gameplay_hud") as CanvasLayer
	if _intro != null:
		_recording_canvas = _intro.get_node_or_null("RecordingCanvas") as CanvasLayer
	if _manager == null or _player == null:
		push_error("HammerController needs the player and GameplayManager")
		return
	_pivot = Node3D.new()
	_pivot.name = "HeldHammerPivot"
	_pivot.position = IDLE_POSITION
	_pivot.rotation_degrees = IDLE_ROTATION
	_held_model = HAMMER_MODEL.instantiate() as Node3D
	_held_model.scale = Vector3.ONE * 0.45
	_pivot.add_child(_held_model)
	_add_grip_hand()
	_player.camera.add_child(_pivot)
	_swing_audio = AudioStreamPlayer.new()
	_swing_audio.bus = &"Tools"
	_swing_audio.volume_db = -18.0
	_swing_audio.stream = APPROVED_SWING
	add_child(_swing_audio)
	_stone_audio = AudioStreamPlayer3D.new()
	_stone_audio.bus = &"World"
	_stone_audio.volume_db = -14.0
	_stone_audio.max_distance = 20.0
	_stone_audio.max_polyphony = 4
	_stone_audio.stream = APPROVED_STONE_HIT
	add_child(_stone_audio)
	_manager.final_wall_opened.connect(_on_wall_opened)
	if _manager.final_wall_open:
		_mount_hammer()
	_update_visibility()


func _process(_delta: float) -> void:
	if _pivot != null:
		_update_visibility()


func _update_visibility() -> void:
	var menu_open := _menu != null and _menu.is_open()
	var intro_active := _intro != null and _intro.is_active()
	_pivot.visible = not _released and (_picking_up or _finishing or (_manager.hammer_taken and not _manager.final_wall_open and not _player.is_sitting() and not menu_open and not intro_active))


func is_cinematic_active() -> bool:
	return _picking_up or _finishing


func begin_pickup_sequence() -> void:
	if _picking_up or _finishing or not _manager.hammer_taken:
		return
	_picking_up = true
	_begin_cinematic_presentation()
	_pivot.position = Vector3(0.58, -1.52, -0.62)
	_pivot.rotation_degrees = Vector3(82.0, -53.0, 32.0)
	_grip_hand.visible = true
	_pivot.visible = true
	var pickup := create_tween()
	pickup.set_parallel(true)
	pickup.tween_property(_pivot, "position", Vector3(0.08, -0.23, -0.92), 0.52).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pickup.tween_property(_pivot, "rotation_degrees", Vector3(4.0, -28.0, 9.0), 0.52).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pickup.set_parallel(false)
	pickup.tween_interval(0.18)
	pickup.set_parallel(true)
	pickup.tween_property(_pivot, "position", Vector3(-0.02, -0.28, -0.96), 0.38).set_trans(Tween.TRANS_SINE)
	pickup.tween_property(_pivot, "rotation_degrees", Vector3(8.0, 22.0, 4.0), 0.38).set_trans(Tween.TRANS_SINE)
	pickup.set_parallel(false)
	pickup.tween_interval(0.20)
	pickup.set_parallel(true)
	pickup.tween_property(_pivot, "position", IDLE_POSITION, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pickup.tween_property(_pivot, "rotation_degrees", IDLE_ROTATION, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pickup.set_parallel(false)
	pickup.tween_callback(_finish_pickup_sequence)


func _finish_pickup_sequence() -> void:
	_picking_up = false
	_end_cinematic_presentation()


func _begin_cinematic_presentation() -> void:
	_player.set_cinematic_locked(true)
	if _hud != null:
		_hud_was_visible = bool(_hud.call("is_gameplay_hud_visible"))
		_hud.call("set_gameplay_hud_visible", false)
	if _recording_canvas != null:
		_recording_was_visible = _recording_canvas.visible
		_recording_canvas.visible = false


func _end_cinematic_presentation() -> void:
	if _hud != null:
		_hud.call("set_gameplay_hud_visible", _hud_was_visible)
	if _recording_canvas != null:
		_recording_canvas.visible = _recording_was_visible
	_player.set_cinematic_locked(false)
	_player.reset_camera_interpolation()


func swing() -> bool:
	if _swinging or is_cinematic_active() or not _manager.hammer_taken or _manager.final_wall_open or _player.is_sitting() or (_menu != null and _menu.is_open()) or (_intro != null and _intro.is_active()):
		return false
	_swinging = true
	_swing_tween = create_tween()
	_swing_tween.set_parallel(true)
	_swing_tween.tween_property(_pivot, "position", WINDUP_POSITION, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(_pivot, "rotation_degrees", WINDUP_ROTATION, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_swing_tween.set_parallel(false)
	_swing_tween.tween_callback(_play_swing_audio)
	_swing_tween.set_parallel(true)
	_swing_tween.tween_property(_pivot, "position", IMPACT_POSITION, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_swing_tween.tween_property(_pivot, "rotation_degrees", IMPACT_ROTATION, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_swing_tween.set_parallel(false)
	_swing_tween.tween_callback(_strike_at_apex)
	_swing_tween.set_parallel(true)
	_swing_tween.tween_property(_pivot, "position", IDLE_POSITION, 0.31).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(_pivot, "rotation_degrees", IDLE_ROTATION, 0.31).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_swing_tween.set_parallel(false)
	_swing_tween.finished.connect(func() -> void: _swinging = false, CONNECT_ONE_SHOT)
	return true


func _play_swing_audio() -> void:
	_swing_audio.pitch_scale = randf_range(0.96, 1.04)
	_swing_audio.play()


func _add_grip_hand() -> void:
	# The single-mesh hand shares the hammer pivot through pickup, swing and release.
	_grip_hand = GRIP_HAND_MODEL.instantiate() as Node3D
	_grip_hand.name = "HeldGripHand"
	_pivot.add_child(_grip_hand)
	for piece in _grip_hand.find_children("*", "MeshInstance3D", true, false):
		(piece as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _strike_at_apex() -> void:
	var origin := _player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin - _player.camera.global_basis.z * 2.9)
	query.exclude = [_player.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var wall := result.get("collider") as Node
	if wall == null or not wall.is_in_group("final_brick_barrier"):
		return
	if wall.hit_wall(result.position):
		_stone_audio.global_position = result.position
		_stone_audio.pitch_scale = randf_range(0.97, 1.03)
		_stone_audio.play()


func _on_wall_opened() -> void:
	if _swing_tween != null and _swing_tween.is_running():
		_swing_tween.kill()
	_finishing = true
	_begin_cinematic_presentation()
	var place_from := _player.global_position
	var place_at := Vector3(35.20, place_from.y, 17.85)
	var facing := WALL_REST_POSITION - place_at
	var target_yaw := -atan2(facing.x, -facing.z)
	var approach := create_tween()
	approach.set_parallel(true)
	approach.tween_property(_player, "global_position", place_at, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	approach.tween_property(_player, "rotation:y", target_yaw, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	approach.tween_property(_player.head, "rotation:x", -0.17, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	approach.tween_property(_pivot, "position", IDLE_POSITION, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	approach.tween_property(_pivot, "rotation_degrees", IDLE_ROTATION, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	approach.set_parallel(false)
	approach.tween_callback(_start_wall_placement)


func _start_wall_placement() -> void:
	_placement_start = _pivot.global_transform
	_placement_target = Transform3D(Basis.from_euler(WALL_REST_ROTATION * (PI / 180.0)), WALL_REST_POSITION)
	var release := create_tween()
	release.tween_method(_animate_wall_placement, 0.0, 1.0, 0.86).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	release.tween_callback(_mount_hammer)
	release.tween_interval(0.38)
	release.tween_callback(_finish_sequence)


func _animate_wall_placement(progress: float) -> void:
	_pivot.global_transform = _placement_start.interpolate_with(_placement_target, progress)
	_held_model.scale = Vector3.ONE * lerpf(0.45, 1.0, progress)
	# The grip must follow the same viewmodel-to-world scale transition as the handle.
	_grip_hand.scale = _held_model.scale / 0.45
	_grip_hand.visible = progress < 0.83


func _mount_hammer() -> void:
	_released = true
	_pivot.visible = false
	if _mounted_hammer != null:
		return
	_mounted_hammer = HAMMER_MODEL.instantiate() as Node3D
	_mounted_hammer.name = "HammerLeftOnSideWall"
	# Lean it against the solid jamb: grip touches the wall, head rests on floor.
	_mounted_hammer.position = WALL_REST_POSITION
	_mounted_hammer.rotation_degrees = WALL_REST_ROTATION
	add_child(_mounted_hammer)


func _finish_sequence() -> void:
	_finishing = false
	_swinging = false
	_end_cinematic_presentation()
