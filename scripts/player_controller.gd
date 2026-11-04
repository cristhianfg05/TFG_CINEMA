class_name PlayerController
extends CharacterBody3D

const PICKUP_RAY_VERTICAL_ALLOWANCE := 0.75
const FOOTSTEP_STRIDE_DISTANCE := 1.35
const FOOTSTEP_CARPET_STREAM := preload("res://assets/audio/sfx/footsteps/footstep_carpet_303.wav")

signal interaction_prompt_changed(prompt: String)
signal intro_finished
signal room_changed(room_id: StringName)
signal sat_in_cinema_seat(room_id: StringName, seat_id: StringName)
signal stood_from_cinema_seat(room_id: StringName, seat_id: StringName)

@export_category("Movement")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 4.5
@export var crouch_speed: float = 1.5
@export var ground_acceleration: float = 24.0
@export var air_acceleration: float = 7.0
@export var jump_velocity: float = 5.0

@export_category("View")
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.12
@export_range(45.0, 89.0, 1.0) var pitch_limit_degrees: float = 85.0
@export_category("Camera Motion")
@export var walk_bob_frequency := 7.0
@export var sprint_bob_frequency := 10.0
@export var walk_bob_lateral := 0.012
@export var walk_bob_vertical := 0.018
@export var sprint_bob_lateral := 0.020
@export var sprint_bob_vertical := 0.032
@export var camera_bob_smoothing := 12.0

@export_category("Body")
@export var standing_height: float = 1.8
@export var crouching_height: float = 1.05
@export var standing_eye_height: float = 1.65
@export var crouching_eye_height: float = 0.85
@export var crouch_transition_speed: float = 4.5
@export var fall_limit_y: float = -8.0
@export var trash_push_impulse_factor: float = 0.10
@export var max_trash_push_impulse: float = 0.06
@export var sack_throw_hold_time: float = 0.48

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_raycast: RayCast3D = $Head/Camera3D/InteractionRayCast3D
@onready var ceiling_check: RayCast3D = $CeilingCheck
@onready var trash_push_area: Area3D = $TrashPushArea
@onready var footstep_audio: AudioStreamPlayer = $FootstepAudio

var _gravity: float = 9.8
var _camera_bob_time := 0.0
var _camera_bob_offset := Vector3.ZERO
var _camera_roll_degrees := 0.0
var _is_crouching: bool = false
var _respawn_transform: Transform3D
var _capsule: CapsuleShape3D
var _focused_interactable: Node
var _previous_eye_position: Vector3
var _current_eye_position: Vector3
var _sprint_unlocked := false
var _sprint_duration := 0.0
var _sprint_time_remaining := 0.0
var _sprint_recharge_time := 0.0
var _is_sprinting := false
var _sprint_exhausted := false
var _sprint_has_been_used := false
var _sack_hold_active := false
var _sack_hold_elapsed := 0.0
var _intro_active := false
var _cinematic_locked := false
var _intro_animating := false
var _intro_tween: Tween
var _current_room_id: StringName = &"room_01"
var _footstep_distance := 0.0
var _sitting_seat: Node3D
var _sitting_room_id: StringName = &""
var _seat_entry_position := Vector3.ZERO
var _sitting_collision_layer := 0
var _sitting_collision_mask := 0
var _seat_transition: Tween


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_capsule = collision_shape.shape as CapsuleShape3D
	_respawn_transform = global_transform
	var respawn_point := get_tree().get_first_node_in_group("respawn_point") as Node3D
	if respawn_point:
		_respawn_transform = respawn_point.global_transform
		global_transform = _respawn_transform
	interaction_raycast.add_exception(self)
	footstep_audio.stream = FOOTSTEP_CARPET_STREAM
	# Only the rendered eye is interpolated; physics and mouse rotation stay immediate.
	camera.top_level = true
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	interaction_raycast.top_level = true
	reset_camera_interpolation()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var eye_position := _previous_eye_position.lerp(
		_current_eye_position, Engine.get_physics_interpolation_fraction()
	)
	camera.global_transform = Transform3D(head.global_basis, eye_position)
	_update_camera_motion(delta)


func reset_camera_interpolation() -> void:
	_previous_eye_position = head.global_position
	_current_eye_position = head.global_position
	_camera_bob_time = 0.0
	_camera_bob_offset = Vector3.ZERO
	_camera_roll_degrees = 0.0
	camera.global_transform = head.global_transform
	interaction_raycast.global_transform = head.global_transform


func _update_camera_motion(delta: float) -> void:
	if _intro_active or is_sitting():
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_moving := is_on_floor() and horizontal_speed > 0.15
	var is_running := is_moving and _is_sprinting
	var frequency := sprint_bob_frequency if is_running else walk_bob_frequency
	var lateral := sprint_bob_lateral if is_running else walk_bob_lateral
	var vertical := sprint_bob_vertical if is_running else walk_bob_vertical
	if is_moving:
		_camera_bob_time += delta * frequency
	var target_offset := Vector3.ZERO
	var target_roll := 0.0
	if is_moving:
		target_offset = Vector3(
			sin(_camera_bob_time) * lateral,
			absf(cos(_camera_bob_time * 2.0)) * vertical,
			0.0
		)
		target_roll = sin(_camera_bob_time) * (0.75 if is_running else 0.35)
	var blend := clampf(delta * camera_bob_smoothing, 0.0, 1.0)
	_camera_bob_offset = _camera_bob_offset.lerp(target_offset, blend)
	_camera_roll_degrees = lerpf(_camera_roll_degrees, target_roll, blend)
	camera.global_position += head.global_basis * _camera_bob_offset
	camera.rotate_object_local(Vector3.FORWARD, deg_to_rad(_camera_roll_degrees))


func get_view_motion_state() -> Dictionary:
	return {
		"moving": is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.15,
		"sprinting": _is_sprinting,
		"phase": _camera_bob_time,
	}


func _unhandled_input(event: InputEvent) -> void:
	if _intro_active or _cinematic_locked:
		get_viewport().set_input_as_handled()
		return
	if is_sitting():
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if not is_seat_transitioning():
				_apply_mouse_look(event.relative)
		elif event.is_action_pressed("interact") and not event.is_echo() and not is_seat_transitioning():
			stand_up_from_cinema_seat()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.relative)
	var cycle_forward := event.is_action_pressed("cycle_tool") and not event.is_echo()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and cycle_forward:
		var equipment_manager := get_tree().get_first_node_in_group("gameplay_manager")
		if equipment_manager and equipment_manager.has_method("cycle_hand_vacuum"):
			if equipment_manager.cycle_hand_vacuum():
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("primary_action") and not event.is_echo():
		var vacuum_manager := get_tree().get_first_node_in_group("gameplay_manager")
		if vacuum_manager and vacuum_manager.hammer_taken and not vacuum_manager.final_wall_open:
			var hammer_controller := get_tree().get_first_node_in_group("hammer_controller")
			if hammer_controller != null:
				hammer_controller.swing()
				get_viewport().set_input_as_handled()
				return
		if vacuum_manager and vacuum_manager.equipped_tool == "vacuum":
			vacuum_manager.set_vacuum_trigger_held(true)
			get_viewport().set_input_as_handled()
			return
		if vacuum_manager and vacuum_manager.equipped_tool == "broom":
			vacuum_manager.sweep_with_broom()
			get_viewport().set_input_as_handled()
			return
	elif event.is_action_released("primary_action"):
		var vacuum_manager := get_tree().get_first_node_in_group("gameplay_manager")
		if vacuum_manager and vacuum_manager.has_method("set_vacuum_trigger_held"):
			vacuum_manager.set_vacuum_trigger_held(false)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interact") and not event.is_echo():
		var manager := get_tree().get_first_node_in_group("gameplay_manager")
		if manager and manager.has_method("has_carried_sack") and manager.has_carried_sack():
			_sack_hold_active = true
			_sack_hold_elapsed = 0.0
			get_viewport().set_input_as_handled()
	elif event.is_action_released("interact") and _sack_hold_active:
		var manager := get_tree().get_first_node_in_group("gameplay_manager")
		if manager and manager.has_method("has_carried_sack") and manager.has_carried_sack():
			if _sack_hold_elapsed >= sack_throw_hold_time:
				manager.throw_carried_sack(-camera.global_basis.z)
			else:
				manager.drop_carried_sack()
		_sack_hold_active = false
		_sack_hold_elapsed = 0.0
		get_viewport().set_input_as_handled()


func _apply_mouse_look(relative_motion: Vector2) -> void:
	rotate_y(deg_to_rad(-relative_motion.x * mouse_sensitivity))
	head.rotation.x = clampf(
		head.rotation.x + deg_to_rad(-relative_motion.y * mouse_sensitivity),
		deg_to_rad(-pitch_limit_degrees),
		deg_to_rad(pitch_limit_degrees)
	)
	camera.global_basis = head.global_basis


func _physics_process(delta: float) -> void:
	_previous_eye_position = _current_eye_position
	if _cinematic_locked:
		velocity = Vector3.ZERO
		_is_sprinting = false
		_current_eye_position = head.global_position
		interaction_raycast.global_transform = head.global_transform
		interaction_prompt_changed.emit("")
		return
	if _intro_active:
		velocity = Vector3.ZERO
		_is_sprinting = false
		_sack_hold_active = false
		_sack_hold_elapsed = 0.0
		if _focused_interactable != null:
			_set_focused_interactable(null)
		_current_eye_position = head.global_position
		interaction_raycast.global_transform = head.global_transform
		return
	if is_sitting():
		velocity = Vector3.ZERO
		_is_sprinting = false
		_current_eye_position = head.global_position
		interaction_raycast.global_transform = head.global_transform
		interaction_prompt_changed.emit("" if is_seat_transitioning() else "[E] Levantarse")
		return
	if _sack_hold_active:
		_sack_hold_elapsed += delta
	_update_crouch(delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		try_jump()

	var input_vector := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	_update_sprint(delta, not direction.is_zero_approx())
	var target_speed := _get_target_speed()
	var target_horizontal := direction * target_speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	horizontal = horizontal.move_toward(target_horizontal, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()
	_update_footsteps(delta)
	_push_nearby_trash()
	_current_eye_position = head.global_position
	interaction_raycast.global_transform = head.global_transform
	interaction_raycast.force_raycast_update()
	_update_interaction()

	if global_position.y < fall_limit_y:
		respawn()


func _update_footsteps(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or horizontal_speed < 0.4:
		_footstep_distance = 0.0
		return
	var stride_scale := 0.7 if _is_crouching else (0.78 if _is_sprinting else 1.0)
	_footstep_distance += horizontal_speed * delta
	var stride_distance := FOOTSTEP_STRIDE_DISTANCE * stride_scale
	if _footstep_distance < stride_distance:
		return
	_footstep_distance = fmod(_footstep_distance, stride_distance)
	footstep_audio.play()


func _push_nearby_trash() -> void:
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal_velocity.length_squared() < 0.01:
		return
	var push_direction := horizontal_velocity.normalized()
	for overlap in trash_push_area.get_overlapping_areas():
		var body := overlap.get_parent() as RigidBody3D
		if body == null or not body.is_in_group("trash_item"):
			continue
		if body.has_method("is_being_collected") and body.is_being_collected():
			continue
		var impulse_strength := minf(
			body.mass * horizontal_velocity.length() * trash_push_impulse_factor,
			max_trash_push_impulse
		)
		if body.has_method("apply_player_nudge"):
			body.apply_player_nudge(
				push_direction * impulse_strength,
				Vector3(0.0, 0.08, 0.0)
			)


func respawn() -> void:
	global_transform = _respawn_transform
	velocity = Vector3.ZERO
	head.rotation.x = 0.0
	reset_camera_interpolation()


func begin_game_intro(seated_height: float, pitch_degrees: float) -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_active = true
	_intro_animating = false
	velocity = Vector3.ZERO
	_is_crouching = false
	_sack_hold_active = false
	head.position.y = seated_height
	head.rotation.x = deg_to_rad(pitch_degrees)
	interaction_prompt_changed.emit("")
	reset_camera_interpolation()


func start_game_intro_stand(duration: float) -> void:
	if not _intro_active or _intro_animating:
		return
	_intro_animating = true
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	_intro_tween.tween_property(head, "position:y", standing_eye_height, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_intro_tween.tween_property(head, "rotation:x", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_intro_tween.finished.connect(_finish_game_intro, CONNECT_ONE_SHOT)


func complete_game_intro_immediately() -> void:
	if not _intro_active:
		return
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	head.position.y = standing_eye_height
	head.rotation.x = 0.0
	_finish_game_intro()


func is_game_intro_active() -> bool:
	return _intro_active


func set_cinematic_locked(locked: bool) -> void:
	_cinematic_locked = locked
	if locked:
		velocity = Vector3.ZERO
		_sack_hold_active = false
		_set_focused_interactable(null)


func _finish_game_intro() -> void:
	_intro_active = false
	_intro_animating = false
	head.position.y = standing_eye_height
	head.rotation.x = 0.0
	reset_camera_interpolation()
	intro_finished.emit()


func try_jump() -> bool:
	if not is_on_floor() or _is_crouching:
		return false
	velocity.y = jump_velocity
	return true


func get_interaction_target() -> Object:
	if interaction_raycast.is_colliding():
		return _resolve_interactable(interaction_raycast.get_collider() as Node)
	return null


func _resolve_interactable(candidate: Node) -> Node:
	var current := candidate
	while current and current != self:
		if (
			current.has_method("get_interaction_prompt")
			and (current.has_method("interact") or current.has_method("collect_interact"))
		):
			return current
		current = current.get_parent()
	return null


func _update_interaction() -> void:
	var manager := get_tree().get_first_node_in_group("gameplay_manager")
	var carrying_sack: bool = bool(manager and manager.has_method("has_carried_sack") and manager.has_carried_sack())
	var vacuum_equipped: bool = bool(manager and String(manager.equipped_tool) == "vacuum")
	var broom_equipped: bool = bool(manager and String(manager.equipped_tool) == "broom")
	var target: Node = null if carrying_sack else get_interaction_target() as Node
	if target == null or not target.has_method("get_interaction_prompt"):
		target = null
	if target != _focused_interactable:
		_set_focused_interactable(target)

	var prompt := ""
	if carrying_sack:
		prompt = "[E] Soltar saco  ·  Mantén [E] Lanzar"
	elif _focused_interactable and is_instance_valid(_focused_interactable):
		prompt = _focused_interactable.get_interaction_prompt()
		if (
			not vacuum_equipped and not broom_equipped
			and (Input.is_action_just_pressed("collect_item") or (manager and manager.get_upgrade_level(&"quick_hands") >= 1 and Input.is_action_pressed("collect_item") and manager.can_pick_up_now() and _focused_interactable.is_in_group("trash_item") and manager.can_collect(_focused_interactable.definition)))
			and _focused_interactable.has_method("collect_interact")
		):
			_focused_interactable.collect_interact(self)
		elif (
			Input.is_action_just_pressed("interact")
			and not _sack_hold_active
			and _focused_interactable.has_method("interact")
		):
			_focused_interactable.interact(self)
		elif (
			Input.is_action_just_pressed("primary_action")
			and _focused_interactable.has_method("primary_interact")
		):
			_focused_interactable.primary_interact(self)
	interaction_prompt_changed.emit(prompt)
	if manager and broom_equipped and Input.is_action_pressed("primary_action"):
		manager.sweep_with_broom()
	if manager and is_cleaning_input_allowed() and Input.is_action_pressed("interact") and _focused_interactable != null and _focused_interactable.has_method("play_unit_deposit") and not carrying_sack:
		manager.begin_deposit(_focused_interactable)


func is_cleaning_input_allowed() -> bool:
	return not _intro_active and not _cinematic_locked and not is_sitting() and not get_tree().paused and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func get_sack_carry_anchor() -> Node3D:
	return $Head/Camera3D/SackCarryAnchor


func set_current_room_id(room_id: StringName) -> void:
	if room_id.is_empty() or room_id == _current_room_id:
		return
	_current_room_id = room_id
	room_changed.emit(_current_room_id)


func get_current_room_id() -> StringName:
	return _current_room_id


func is_sitting() -> bool:
	return _sitting_seat != null and is_instance_valid(_sitting_seat)


func is_seat_transitioning() -> bool:
	return _seat_transition != null and _seat_transition.is_running()


func sit_in_cinema_seat(seat: Node3D) -> bool:
	if is_sitting() or _intro_active or seat == null or not seat.has_method("get_sitting_position"):
		return false
	var manager := get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	if manager == null or manager.has_carried_sack() or not manager.is_room_activated(seat.room_id) or not manager.is_room_fully_clean(seat.room_id):
		return false
	if seat.has_method("can_be_selected_from") and not seat.can_be_selected_from(self):
		return false
	manager.set_vacuum_trigger_held(false)
	_seat_entry_position = global_position
	_sitting_seat = seat
	_sitting_room_id = seat.room_id
	_sitting_collision_layer = collision_layer
	_sitting_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	_is_crouching = false
	_capsule.height = standing_height
	collision_shape.position.y = standing_height * 0.5
	_set_focused_interactable(null)
	reset_camera_interpolation()
	set_current_room_id(seat.room_id)
	interaction_prompt_changed.emit("")
	var target_yaw := rotation.y + wrapf(seat.facing_y - rotation.y, -PI, PI)
	_seat_transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_seat_transition.tween_property(self, "global_position", seat.get_sitting_position(), 0.62)
	_seat_transition.tween_property(self, "rotation:y", target_yaw, 0.62)
	_seat_transition.tween_property(head, "position:y", 1.18, 0.62)
	_seat_transition.tween_property(head, "rotation:x", 0.0, 0.62)
	_seat_transition.finished.connect(func() -> void:
		_seat_transition = null
		reset_camera_interpolation()
		interaction_prompt_changed.emit("[E] Levantarse")
		sat_in_cinema_seat.emit(seat.room_id, seat.seat_id)
	)
	return true


func stand_up_from_cinema_seat() -> bool:
	if not is_sitting() or is_seat_transitioning():
		return false
	var old_room_id := _sitting_room_id
	var old_seat_id: StringName = _sitting_seat.seat_id
	var exit_position := _find_safe_seat_exit(_sitting_seat)
	interaction_prompt_changed.emit("")
	# Match the sit-down camera travel. Keep collisions off and movement locked
	# until the body reaches a floor-tested exit outside the seat hull.
	_seat_transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_seat_transition.tween_property(self, "global_position", exit_position, 0.62)
	_seat_transition.tween_property(head, "position:y", standing_eye_height, 0.62)
	_seat_transition.finished.connect(func() -> void:
		_seat_transition = null
		collision_layer = _sitting_collision_layer
		collision_mask = _sitting_collision_mask
		_sitting_seat = null
		_sitting_room_id = &""
		_seat_entry_position = Vector3.ZERO
		velocity = Vector3.ZERO
		reset_camera_interpolation()
		stood_from_cinema_seat.emit(old_room_id, old_seat_id)
	)
	return true


func _find_safe_seat_exit(seat: Node3D) -> Vector3:
	var candidates: Array[Vector3] = seat.get_exit_candidates()
	if _sitting_seat == seat:
		candidates.push_front(_seat_entry_position)
	var fallback := candidates[0]
	var has_floor_fallback := false
	for candidate: Vector3 in candidates:
		var floor_query := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 2.5, candidate + Vector3.DOWN * 2.5, 1)
		floor_query.exclude = [get_rid()]
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(floor_query)
		if floor_hit.is_empty():
			continue
		var standing_position := Vector3(candidate.x, (floor_hit.position as Vector3).y + 0.06, candidate.z)
		if not has_floor_fallback:
			fallback = standing_position
			has_floor_fallback = true
		var shape_query := PhysicsShapeQueryParameters3D.new()
		shape_query.shape = _capsule
		shape_query.transform = Transform3D(Basis(), standing_position + Vector3.UP * standing_height * 0.5)
		shape_query.collision_mask = _sitting_collision_mask
		shape_query.exclude = [get_rid()]
		if get_world_3d().direct_space_state.intersect_shape(shape_query, 1).is_empty():
			return standing_position
	return fallback


func _set_focused_interactable(target: Node) -> void:
	if _focused_interactable and is_instance_valid(_focused_interactable):
		if _focused_interactable.has_method("set_focused"):
			_focused_interactable.set_focused(false)
	_focused_interactable = target
	if _focused_interactable and _focused_interactable.has_method("set_focused"):
		_focused_interactable.set_focused(true)


func is_crouching() -> bool:
	return _is_crouching


func _get_target_speed() -> float:
	if _is_crouching:
		return crouch_speed
	if _is_sprinting:
		return sprint_speed
	return walk_speed


func configure_progression(
	sprint_unlocked: bool,
	new_sprint_speed: float,
	new_sprint_duration: float,
	new_sprint_recharge_time: float,
	interaction_reach: float
) -> void:
	var was_unlocked := _sprint_unlocked
	var previous_duration := _sprint_duration
	var previous_ratio := (
		clampf(_sprint_time_remaining / previous_duration, 0.0, 1.0)
		if previous_duration > 0.0
		else 1.0
	)
	_sprint_unlocked = sprint_unlocked
	sprint_speed = new_sprint_speed
	_sprint_duration = new_sprint_duration
	_sprint_recharge_time = new_sprint_recharge_time
	if not _sprint_unlocked:
		_sprint_time_remaining = 0.0
		_sprint_exhausted = false
	elif not was_unlocked:
		_sprint_time_remaining = _sprint_duration
	else:
		_sprint_time_remaining = previous_ratio * _sprint_duration
	# The configured reach is measured along the floor. The ray starts at eye
	# height, so it needs this extra length to comfortably reach floor props.
	interaction_raycast.target_position.z = -(interaction_reach + PICKUP_RAY_VERTICAL_ALLOWANCE)


func _update_sprint(delta: float, is_moving: bool) -> void:
	var sprint_pressed := Input.is_action_pressed("sprint")
	if _sprint_exhausted and not sprint_pressed and _sprint_time_remaining > 0.0:
		_sprint_exhausted = false
	_is_sprinting = (
		_sprint_unlocked
		and not _is_crouching
		and is_moving
		and sprint_pressed
		and not _sprint_exhausted
		and _sprint_time_remaining > 0.0
	)
	if _is_sprinting:
		_sprint_has_been_used = true
		_sprint_time_remaining = maxf(0.0, _sprint_time_remaining - delta)
		if is_zero_approx(_sprint_time_remaining):
			_sprint_exhausted = true
	else:
		var recharge_rate := (
			_sprint_duration / _sprint_recharge_time
			if _sprint_recharge_time > 0.0
			else 0.0
		)
		_sprint_time_remaining = minf(
			_sprint_duration,
			_sprint_time_remaining + recharge_rate * delta
		)
		if _sprint_exhausted and not sprint_pressed and _sprint_time_remaining > 0.0:
			_sprint_exhausted = false


func get_sprint_state() -> Dictionary:
	return {
		"unlocked": _sprint_unlocked,
		"remaining": _sprint_time_remaining,
		"duration": _sprint_duration,
		"recharge_time": _sprint_recharge_time,
		"is_sprinting": _is_sprinting,
		"has_been_used": _sprint_has_been_used,
		"exhausted": _sprint_exhausted,
	}


func _update_crouch(delta: float) -> void:
	var wants_to_crouch := Input.is_action_pressed("crouch")
	if not wants_to_crouch and _is_crouching and ceiling_check.is_colliding():
		wants_to_crouch = true
	_is_crouching = wants_to_crouch

	var target_height := crouching_height if _is_crouching else standing_height
	var target_eye_height := crouching_eye_height if _is_crouching else standing_eye_height
	_capsule.height = move_toward(
		_capsule.height, target_height, crouch_transition_speed * delta
	)
	collision_shape.position.y = _capsule.height * 0.5
	head.position.y = move_toward(
		head.position.y, target_eye_height, crouch_transition_speed * delta
	)
