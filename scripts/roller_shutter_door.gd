@tool
class_name RollerShutterDoor
extends Node3D

signal door_opened
signal door_closed
signal openness_changed(value: float)

const SLAT_COUNT := 14
const OPENING_WIDTH := 3.0 # Compatibility: canonical wide variant.
const OPENING_HEIGHT := 2.8

enum DoorVariant { WIDE, NARROW }

@export_range(0.2, 4.0, 0.05) var animation_duration := 1.15
@export var variant: DoorVariant = DoorVariant.WIDE
@export_range(1.1, 6.0, 0.05) var opening_width := 3.0
@export_range(2.1, 3.5, 0.05) var opening_height := 2.8
@export var slat_mesh: BoxMesh
@export var slat_edge_mesh: BoxMesh
@export var groove_mesh: BoxMesh
@export var side_frame_mesh: BoxMesh
@export var housing_mesh: BoxMesh
@export var housing_lip_mesh: BoxMesh
@export var blocker_shape: BoxShape3D

var is_open := false
var openness := 0.0
var door_panel: StaticBody3D
var collision_shape: CollisionShape3D
var _slat_roots: Array[Node3D] = []
var _slat_rest_heights: Array[float] = []
var _motion_tween: Tween
var _is_blocking := false
var _is_animating := false


func _ready() -> void:
	add_to_group("roller_shutter_door")
	_apply_variant_dimensions()
	_prepare_sized_resources()
	_build_generated_door()
	_set_openness(0.0)


func open_door() -> void:
	if is_open:
		return
	is_open = true
	_animate_to(1.0)


func close_door() -> void:
	if not is_open:
		return
	is_open = false
	_animate_to(0.0)


func get_clearance_height() -> float:
	return openness * opening_height


func is_animating() -> bool:
	return _is_animating


func get_slat_nodes() -> Array[Node3D]:
	return _slat_roots


func set_focused(_focused: bool) -> void:
	# Keep the shared slat material immutable. Interaction feedback belongs to
	# whichever gameplay adapter owns this generic door.
	pass


func _animate_to(target: float) -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
	var distance := absf(target - openness)
	if distance <= 0.0001:
		_set_openness(target)
		_finish_motion(target)
		return
	_is_animating = true
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_method(_set_openness, openness, target, animation_duration * distance)
	_motion_tween.tween_callback(_finish_motion.bind(target))


func _set_openness(value: float) -> void:
	openness = clampf(value, 0.0, 1.0)
	var travel := openness * opening_height
	var hide_height := opening_height + 0.10
	for slat_index in _slat_roots.size():
		var slat := _slat_roots[slat_index]
		slat.position.y = _slat_rest_heights[slat_index] + travel
		slat.visible = slat.position.y < hide_height
	_set_blocking(get_clearance_height() < minf(2.05, opening_height * 0.78))
	openness_changed.emit(openness)


func _finish_motion(target: float) -> void:
	_set_openness(target)
	_is_animating = false
	if target >= 1.0:
		door_opened.emit()
	else:
		door_closed.emit()


func _set_blocking(should_block: bool) -> void:
	if door_panel == null or collision_shape == null:
		return
	if _is_blocking == should_block:
		return
	_is_blocking = should_block
	door_panel.collision_layer = 1 if should_block else 0
	door_panel.collision_mask = 1 if should_block else 0
	collision_shape.set_deferred("disabled", not should_block)


func _build_generated_door() -> void:
	var previous := get_node_or_null("GeneratedDoor")
	if previous:
		previous.queue_free()
	_slat_roots.clear()
	_slat_rest_heights.clear()
	if not _resources_are_valid():
		push_error("RollerShutterDoor requires its shared meshes and blocker shape")
		return

	var generated := Node3D.new()
	generated.name = "GeneratedDoor"
	add_child(generated)

	var slats := Node3D.new()
	slats.name = "Slats"
	generated.add_child(slats)
	var slat_pitch := opening_height / float(SLAT_COUNT)
	for slat_index in SLAT_COUNT:
		var slat_root := Node3D.new()
		slat_root.name = "Slat_%02d" % (slat_index + 1)
		slat_root.position = Vector3(0.0, (float(slat_index) + 0.5) * slat_pitch, -0.07)
		slats.add_child(slat_root)

		var face := MeshInstance3D.new()
		face.name = "Face"
		face.mesh = slat_mesh
		slat_root.add_child(face)

		var groove := MeshInstance3D.new()
		groove.name = "DarkSeparation"
		groove.position = Vector3(0.0, -0.0875, -0.071)
		groove.mesh = groove_mesh
		slat_root.add_child(groove)

		var worn_edge := MeshInstance3D.new()
		worn_edge.name = "WornEdge"
		worn_edge.position = Vector3(0.0, 0.073, -0.071)
		worn_edge.mesh = slat_edge_mesh
		slat_root.add_child(worn_edge)

		_slat_roots.append(slat_root)
		_slat_rest_heights.append(slat_root.position.y)

	var frame := Node3D.new()
	frame.name = "Frame"
	generated.add_child(frame)
	var rail_x := opening_width * 0.5 + 0.09
	_add_mesh_instance(frame, "LeftRail", side_frame_mesh, Vector3(-rail_x, opening_height * 0.5, -0.03))
	_add_mesh_instance(frame, "RightRail", side_frame_mesh, Vector3(rail_x, opening_height * 0.5, -0.03))
	_add_mesh_instance(frame, "TopHousing", housing_mesh, Vector3(0.0, opening_height + 0.20, -0.04))
	_add_mesh_instance(frame, "HousingLip", housing_lip_mesh, Vector3(0.0, opening_height, -0.225))

	door_panel = StaticBody3D.new()
	door_panel.name = "DoorPanel"
	door_panel.collision_layer = 1
	door_panel.collision_mask = 1
	generated.add_child(door_panel)
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "Collision"
	collision_shape.position = Vector3(0.0, opening_height * 0.5, 0.0)
	collision_shape.shape = blocker_shape
	door_panel.add_child(collision_shape)


func _add_mesh_instance(parent: Node3D, node_name: String, mesh: Mesh, at_position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at_position
	instance.mesh = mesh
	parent.add_child(instance)
	return instance


func _resources_are_valid() -> bool:
	return (
		slat_mesh != null
		and slat_edge_mesh != null
		and groove_mesh != null
		and side_frame_mesh != null
		and housing_mesh != null
		and housing_lip_mesh != null
		and blocker_shape != null
	)


func _apply_variant_dimensions() -> void:
	if variant == DoorVariant.NARROW:
		opening_width = 1.6
		opening_height = 2.5


func _prepare_sized_resources() -> void:
	# One duplicated mesh per role and door, never one material or mesh per slat.
	# Every slat instance still shares exactly the same mesh and material.
	slat_mesh = slat_mesh.duplicate() as BoxMesh
	slat_mesh.size = Vector3(opening_width, opening_height / float(SLAT_COUNT), 0.12)
	slat_edge_mesh = slat_edge_mesh.duplicate() as BoxMesh
	slat_edge_mesh.size = Vector3(maxf(0.2, opening_width - 0.12), 0.018, 0.014)
	groove_mesh = groove_mesh.duplicate() as BoxMesh
	groove_mesh.size = Vector3(opening_width, 0.025, 0.018)
	side_frame_mesh = side_frame_mesh.duplicate() as BoxMesh
	side_frame_mesh.size = Vector3(0.18, opening_height, 0.28)
	housing_mesh = housing_mesh.duplicate() as BoxMesh
	housing_mesh.size = Vector3(opening_width + 0.36, 0.4, 0.36)
	housing_lip_mesh = housing_lip_mesh.duplicate() as BoxMesh
	housing_lip_mesh.size = Vector3(opening_width + 0.18, 0.075, 0.055)
	blocker_shape = blocker_shape.duplicate() as BoxShape3D
	blocker_shape.size = Vector3(opening_width, opening_height, 0.18)
