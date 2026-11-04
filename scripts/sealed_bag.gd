class_name SealedBag
extends RigidBody3D

const BIN_ABSORB_DISTANCE := 1.0
const RESTING_LINEAR_DAMP := 1.4
const THROW_LINEAR_DAMP := 0.28
const THROW_FLIGHT_DAMP_DELAY := 1.15
const CARRY_LOCAL_POSITION := Vector3(0.58, -0.64, -1.58)

@export var contained_units: int = 0
@export var contained_base_value: int = 0
@export var created_room_id: StringName = &"room_01"
@export var delivered: bool = false

var _meshes: Array[MeshInstance3D] = []
var _base_materials: Array[Material] = []
var _highlight_materials: Array[Material] = []
var _carried := false
var _absorbing := false
var _absorb_check_remaining := 0.0
var _absorption_callback: Callable
var _throw_flight_remaining := 0.0
var _carry_anchor: Node3D


func _ready() -> void:
	add_to_group("sealed_bag")
	_find_meshes($Model)
	for mesh in _meshes:
		var original_override := mesh.material_override
		var source_material := original_override
		if source_material == null and mesh.mesh and mesh.mesh.get_surface_count() > 0:
			source_material = mesh.mesh.surface_get_material(0)
		_base_materials.append(original_override)
		var highlighted := source_material.duplicate() as Material if source_material else StandardMaterial3D.new()
		if highlighted is StandardMaterial3D:
			highlighted.emission_enabled = true
			highlighted.emission = Color("6a5114")
			highlighted.emission_energy_multiplier = 0.45
		_highlight_materials.append(highlighted)


func _physics_process(delta: float) -> void:
	if _carried:
		return
	if _absorbing or delivered:
		return
	if _throw_flight_remaining > 0.0:
		_throw_flight_remaining = maxf(0.0, _throw_flight_remaining - delta)
		if is_zero_approx(_throw_flight_remaining):
			linear_damp = RESTING_LINEAR_DAMP
	_absorb_check_remaining = maxf(0.0, _absorb_check_remaining - delta)
	if _absorb_check_remaining > 0.0:
		return
	_absorb_check_remaining = 0.10
	var manager := get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.has_method("request_sack_absorption"):
		manager.request_sack_absorption(self)


func get_interaction_prompt() -> String:
	return "E — Recoger saco (%d uds.)" % contained_units


func interact(_player: Node) -> void:
	var manager := get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.pick_up_sealed_bag(self)


func begin_carry(anchor: Node3D) -> bool:
	if anchor == null or _absorbing or delivered:
		return false
	_carried = true
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	_carry_anchor = anchor
	reparent(anchor, false)
	position = CARRY_LOCAL_POSITION
	rotation_degrees = Vector3(-8.0, 18.0, -6.0)
	scale = Vector3.ONE
	_set_world_model_visible(false)
	return true


func release_to(world_parent: Node3D, release_transform: Transform3D, release_velocity: Vector3) -> bool:
	if world_parent == null or _absorbing:
		return false
	reparent(world_parent, false)
	global_transform = release_transform
	_carried = false
	_carry_anchor = null
	_set_world_model_visible(true)
	freeze = false
	sleeping = false
	collision_layer = 2
	collision_mask = 1
	var thrown := release_velocity.length_squared() > 0.1
	linear_damp = THROW_LINEAR_DAMP if thrown else RESTING_LINEAR_DAMP
	_throw_flight_remaining = THROW_FLIGHT_DAMP_DELAY if thrown else 0.0
	linear_velocity = release_velocity
	angular_velocity = Vector3(0.22, 0.55, -0.16) if thrown else Vector3.ZERO
	_absorb_check_remaining = 0.18
	return true


func begin_absorption(world_parent: Node3D, target_position: Vector3, on_finished: Callable) -> bool:
	if _absorbing or delivered or world_parent == null:
		return false
	_absorbing = true
	_carried = false
	_carry_anchor = null
	_set_world_model_visible(true)
	delivered = true
	freeze = true
	sleeping = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	set_focused(false)
	reparent(world_parent, true)
	_absorption_callback = on_finished
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_position, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector3.ONE * 0.08, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", rotation + Vector3(0.25, TAU * 0.75, 0.4), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_finish_absorption)
	return true


func is_carried() -> bool:
	return _carried


func is_absorbing() -> bool:
	return _absorbing


func is_within_absorption_radius(target_position: Vector3, radius: float) -> bool:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	var probe_position := get_absorption_probe_position()
	var sack_radius := 0.0
	if collision and collision.shape is SphereShape3D:
		sack_radius = (collision.shape as SphereShape3D).radius
	# Treat the requested radius as a real trigger volume. The sack enters it as
	# soon as its collision surface overlaps, rather than requiring its root or
	# centre to cross the boundary after colliding with the physical bin.
	return probe_position.distance_to(target_position) <= maxf(0.0, radius) + sack_radius


func get_absorption_probe_position() -> Vector3:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	return collision.global_position if collision else global_position


func _finish_absorption() -> void:
	if _absorption_callback.is_valid():
		_absorption_callback.call()


func set_focused(focused: bool) -> void:
	for index in _meshes.size():
		_meshes[index].material_override = _highlight_materials[index] if focused else _base_materials[index]


func is_world_model_visible() -> bool:
	return not _meshes.is_empty() and _meshes[0].visible


func _set_world_model_visible(visible: bool) -> void:
	for mesh in _meshes:
		mesh.visible = visible


func serialize() -> Dictionary:
	return {"units": contained_units, "base_value": contained_base_value, "created_room_id": String(created_room_id), "delivered": delivered, "position": [position.x, position.y, position.z]}


func _find_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_meshes.append(node)
	for child in node.get_children():
		_find_meshes(child)
