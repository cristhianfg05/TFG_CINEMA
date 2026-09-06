class_name PlayerController
extends CharacterBody3D

signal interaction_prompt_changed(prompt: String)

@export_category("Movement")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var crouch_speed: float = 2.5
@export var ground_acceleration: float = 24.0
@export var air_acceleration: float = 7.0
@export var jump_velocity: float = 5.0

@export_category("View")
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.12
@export_range(45.0, 89.0, 1.0) var pitch_limit_degrees: float = 85.0

@export_category("Body")
@export var standing_height: float = 1.8
@export var crouching_height: float = 1.05
@export var standing_eye_height: float = 1.65
@export var crouching_eye_height: float = 0.85
@export var crouch_transition_speed: float = 4.5
@export var fall_limit_y: float = -8.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var interaction_raycast: RayCast3D = $Head/Camera3D/InteractionRayCast3D
@onready var ceiling_check: RayCast3D = $CeilingCheck

var _gravity: float = 9.8
var _is_crouching: bool = false
var _respawn_transform: Transform3D
var _capsule: CapsuleShape3D
var _focused_interactable: Node


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_capsule = collision_shape.shape as CapsuleShape3D
	_respawn_transform = global_transform
	var respawn_point := get_tree().get_first_node_in_group("respawn_point") as Node3D
	if respawn_point:
		_respawn_transform = respawn_point.global_transform
		global_transform = _respawn_transform
	interaction_raycast.add_exception(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotation.x = clampf(
			head.rotation.x + deg_to_rad(-event.relative.y * mouse_sensitivity),
			deg_to_rad(-pitch_limit_degrees),
			deg_to_rad(pitch_limit_degrees)
		)
	elif event.is_action_pressed("pause"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	_update_crouch(delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		try_jump()

	var input_vector := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var target_speed := _get_target_speed()
	var target_horizontal := direction * target_speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	horizontal = horizontal.move_toward(target_horizontal, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()
	_update_interaction()

	if global_position.y < fall_limit_y:
		respawn()


func respawn() -> void:
	global_transform = _respawn_transform
	velocity = Vector3.ZERO
	head.rotation.x = 0.0


func try_jump() -> bool:
	if not is_on_floor() or _is_crouching:
		return false
	velocity.y = jump_velocity
	return true


func get_interaction_target() -> Object:
	if interaction_raycast.is_colliding():
		return interaction_raycast.get_collider()
	return null


func _update_interaction() -> void:
	var target := get_interaction_target() as Node
	if target == null or not target.has_method("get_interaction_prompt"):
		target = null
	if target != _focused_interactable:
		_set_focused_interactable(target)

	var prompt := ""
	if _focused_interactable and is_instance_valid(_focused_interactable):
		prompt = _focused_interactable.get_interaction_prompt()
		if Input.is_action_just_pressed("interact"):
			_focused_interactable.interact(self)
	interaction_prompt_changed.emit(prompt)


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
	if Input.is_action_pressed("sprint"):
		return sprint_speed
	return walk_speed


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
