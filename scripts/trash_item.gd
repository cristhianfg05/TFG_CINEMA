extends RigidBody3D

@export var definition: Resource
@export var room_id: StringName = &"room_01"
@export var world_item_id := ""
@export var max_physics_speed := 2.2
@export var max_angular_speed := 8.0
@export var player_nudge_cooldown := 0.18

const FLOOR_COLLISION_CLEARANCE := 0.020
const FLOOR_VISUAL_CLEARANCE := 0.012
const FLOOR_SENSITIVE_IDS := ["ticket", "napkin", "straw"]

var _mesh_instance: MeshInstance3D
var _base_material: StandardMaterial3D
var _highlight_material: StandardMaterial3D
var _imported_meshes: Array[MeshInstance3D] = []
var _imported_base_materials: Array[Material] = []
var _imported_highlight_materials: Array[Material] = []
var _is_being_collected := false
var _nudge_cooldown_remaining := 0.0
var _collection_tween: Tween
var _collector: Node3D
var _collection_callback: Callable
var _collection_start_position: Vector3
var _collection_start_rotation: Vector3
static var _shared_all_seeing_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("trash_item")
	# With thousands of pieces, an idle cooldown callback on every body costs
	# more than the interaction itself. Run it only after a player nudge.
	set_physics_process(false)
	_configure_physics_mass()
	if definition != null and definition.model != null:
		_build_imported_model()
	else:
		_build_placeholder()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _is_being_collected:
		return
	if state.linear_velocity.length() > max_physics_speed:
		state.linear_velocity = state.linear_velocity.normalized() * max_physics_speed
	if state.angular_velocity.length() > max_angular_speed:
		state.angular_velocity = state.angular_velocity.normalized() * max_angular_speed


func _physics_process(delta: float) -> void:
	_nudge_cooldown_remaining = maxf(0.0, _nudge_cooldown_remaining - delta)
	if _nudge_cooldown_remaining <= 0.0:
		set_physics_process(false)


func apply_player_nudge(impulse: Vector3, offset: Vector3) -> bool:
	if _is_being_collected or _nudge_cooldown_remaining > 0.0:
		return false
	_nudge_cooldown_remaining = player_nudge_cooldown
	set_physics_process(true)
	sleeping = false
	apply_impulse(impulse, offset)
	return true


func apply_vacuum_pull(target: Vector3, acceleration: float, delta: float) -> bool:
	if _is_being_collected or freeze:
		return false
	var offset := target - global_position
	if offset.length_squared() <= 0.0001:
		return false
	sleeping = false
	var direction := offset.normalized()
	var phase := float(get_instance_id() % 31) * 0.37 + Time.get_ticks_msec() * 0.008
	var swirl := direction.cross(Vector3.UP).normalized() * sin(phase) * 0.34
	var desired_velocity := (direction * 4.8 + swirl).limit_length(max_physics_speed * 2.0)
	linear_velocity = linear_velocity.move_toward(desired_velocity, acceleration * delta)
	angular_velocity = angular_velocity.move_toward(Vector3(1.2, 2.4, 0.8), acceleration * 0.35 * delta)
	return true


func _configure_physics_mass() -> void:
	if definition == null:
		return
	match String(definition.id):
		"ticket", "napkin":
			mass = 0.035
			lock_rotation = true
		"straw":
			mass = 0.045
			lock_rotation = true
		"popcorn": mass = 0.045
		"cup", "can": mass = 0.08
		"bottle": mass = 0.12
		"bucket": mass = 0.16
	if String(definition.id) == "popcorn":
		lock_rotation = true
		angular_damp = 10.0


func set_focused(focused: bool) -> void:
	for mesh_index in _imported_meshes.size():
		_imported_meshes[mesh_index].material_override = (
			_imported_highlight_materials[mesh_index]
			if focused
			else _imported_base_materials[mesh_index]
		)
	if _mesh_instance:
		_mesh_instance.material_override = _highlight_material if focused else _base_material


func set_all_seeing_revealed(revealed: bool) -> void:
	var overlay := _get_all_seeing_material() if revealed else null
	for mesh in _imported_meshes:
		mesh.material_overlay = overlay
	if _mesh_instance:
		_mesh_instance.material_overlay = overlay


func _get_all_seeing_material() -> StandardMaterial3D:
	if _shared_all_seeing_material == null:
		_shared_all_seeing_material = StandardMaterial3D.new()
		_shared_all_seeing_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shared_all_seeing_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shared_all_seeing_material.no_depth_test = true
		_shared_all_seeing_material.albedo_color = Color(1.0, 0.68, 0.16, 0.30)
		_shared_all_seeing_material.emission_enabled = true
		_shared_all_seeing_material.emission = Color("ffb733")
		_shared_all_seeing_material.emission_energy_multiplier = 1.8
		_shared_all_seeing_material.render_priority = 1
	return _shared_all_seeing_material


func get_interaction_prompt() -> String:
	return ""


func collect_interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.request_collect(self, _player)


func is_being_collected() -> bool:
	return _is_being_collected


func get_room_id() -> StringName:
	return room_id


func get_world_item_id() -> String:
	return world_item_id


func begin_collection(collector: Node3D, on_arrived: Callable) -> bool:
	if _is_being_collected or collector == null or not is_instance_valid(collector):
		return false
	_is_being_collected = true
	set_focused(false)
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	var interaction_area := get_node_or_null("InteractionArea") as Area3D
	if interaction_area:
		interaction_area.collision_layer = 0

	_collector = collector
	_collection_callback = on_arrived
	_collection_start_position = global_position
	_collection_start_rotation = rotation
	_collection_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_collection_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_collection_tween.tween_method(_animate_collection, 0.0, 1.0, 0.32)
	_collection_tween.parallel().tween_property(self, "scale", Vector3.ONE * 0.12, 0.32)
	_collection_tween.tween_callback(_finish_collection_animation)
	return true


func _animate_collection(weight: float) -> void:
	if not is_instance_valid(_collector):
		return
	var collection_point := _collector.global_position + Vector3(0.0, 1.05, 0.0)
	global_position = _collection_start_position.lerp(collection_point, weight)
	rotation = _collection_start_rotation + Vector3(0.0, weight * PI, weight * PI * 0.35)


func _finish_collection_animation() -> void:
	if _collection_callback.is_valid():
		_collection_callback.call(self)


func collect() -> void:
	set_focused(false)
	collision_layer = 0
	collision_mask = 0
	if _collection_tween and _collection_tween.is_valid():
		_collection_tween.kill()
	queue_free()


func _build_imported_model() -> void:
	var model_root := definition.model.instantiate() as Node3D
	if model_root == null:
		push_error("Trash model requires a Node3D root")
		_build_placeholder()
		return
	model_root.name = "Model"
	model_root.scale = Vector3.ONE * float(definition.model_scale)
	model_root.rotation_degrees = definition.model_rotation_degrees
	add_child(model_root)
	_find_imported_meshes(model_root)
	if String(definition.id) in FLOOR_SENSITIVE_IDS:
		_lift_floor_sensitive_model(model_root)
	_prepare_imported_highlight_materials()
	var visual_bounds := get_visual_bounds_local()
	var dimensions := visual_bounds.size
	dimensions.x = maxf(dimensions.x, 0.035)
	dimensions.y = maxf(dimensions.y, 0.035)
	dimensions.z = maxf(dimensions.z, 0.035)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = _make_shape(String(definition.id), dimensions)
	collision.position = visual_bounds.get_center()
	add_child(collision)
	_add_floor_clearance_to_collisions(collision)
	_add_interaction_area(dimensions)


func _find_imported_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_imported_meshes.append(node)
	for child in node.get_children():
		_find_imported_meshes(child)


func _lift_floor_sensitive_model(model_root: Node3D) -> void:
	var visual_bottom := get_visual_bottom_local_y()
	if visual_bottom < FLOOR_VISUAL_CLEARANCE:
		model_root.position.y += FLOOR_VISUAL_CLEARANCE - visual_bottom


func get_visual_bottom_local_y() -> float:
	var bounds := get_visual_bounds_local()
	return bounds.position.y if bounds.size != Vector3.ZERO else 0.0


func get_visual_bounds_local() -> AABB:
	var visual_min := Vector3(INF, INF, INF)
	var visual_max := Vector3(-INF, -INF, -INF)
	var found_mesh := false
	for mesh in _imported_meshes:
		var mesh_bounds := mesh.get_aabb()
		for corner_x in [mesh_bounds.position.x, mesh_bounds.end.x]:
			for corner_y in [mesh_bounds.position.y, mesh_bounds.end.y]:
				for corner_z in [mesh_bounds.position.z, mesh_bounds.end.z]:
					var item_point := to_local(mesh.to_global(Vector3(corner_x, corner_y, corner_z)))
					visual_min = visual_min.min(item_point)
					visual_max = visual_max.max(item_point)
					found_mesh = true
	return AABB(visual_min, visual_max - visual_min) if found_mesh else AABB()


func get_min_floor_clearance(floor_height: Callable) -> float:
	var minimum := INF
	for mesh in _imported_meshes:
		var bounds := mesh.get_aabb()
		for corner_x in [bounds.position.x, bounds.end.x]:
			for corner_y in [bounds.position.y, bounds.end.y]:
				for corner_z in [bounds.position.z, bounds.end.z]:
					var point := mesh.to_global(Vector3(corner_x, corner_y, corner_z))
					minimum = minf(minimum, point.y - float(floor_height.call(point)))
	if minimum == INF:
		return global_position.y - float(floor_height.call(global_position))
	return minimum


func _prepare_imported_highlight_materials() -> void:
	for mesh in _imported_meshes:
		var original_override := mesh.material_override
		var source_material := original_override
		if source_material == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
			source_material = mesh.mesh.surface_get_material(0)
		_imported_base_materials.append(original_override)
		var highlight_material := (
			source_material.duplicate() as Material
			if source_material != null
			else StandardMaterial3D.new()
		)
		if highlight_material is StandardMaterial3D:
			var standard := highlight_material as StandardMaterial3D
			standard.emission_enabled = true
			standard.emission = Color("5d4310")
			standard.emission_energy_multiplier = 0.45
		_imported_highlight_materials.append(highlight_material)


func _add_floor_clearance_to_collisions(node: Node) -> void:
	if node is CollisionShape3D:
		var collision := node as CollisionShape3D
		if collision.shape is BoxShape3D:
			var box := collision.shape.duplicate() as BoxShape3D
			box.size.y += FLOOR_COLLISION_CLEARANCE * 2.0
			collision.shape = box
		elif collision.shape is CylinderShape3D:
			var cylinder := collision.shape.duplicate() as CylinderShape3D
			cylinder.height += FLOOR_COLLISION_CLEARANCE * 2.0
			cylinder.radius += FLOOR_COLLISION_CLEARANCE
			collision.shape = cylinder
		elif collision.shape is SphereShape3D:
			var sphere := collision.shape.duplicate() as SphereShape3D
			sphere.radius += FLOOR_COLLISION_CLEARANCE
			collision.shape = sphere
	for child in node.get_children():
		_add_floor_clearance_to_collisions(child)


func _build_placeholder() -> void:
	if definition == null:
		push_error("TrashItem requires a TrashDefinition")
		return

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Mesh"
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var item_id := String(definition.id)
	var dimensions := _get_dimensions(item_id)
	_mesh_instance.mesh = _make_mesh(item_id, dimensions)
	_mesh_instance.position.y = dimensions.y * 0.5
	collision.shape = _make_shape(item_id, dimensions)
	collision.position.y = dimensions.y * 0.5

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = _get_color(item_id)
	_base_material.roughness = 0.85
	_highlight_material = _base_material.duplicate() as StandardMaterial3D
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color("5d4310")
	_highlight_material.emission_energy_multiplier = 0.45
	_mesh_instance.material_override = _base_material

	add_child(_mesh_instance)
	add_child(collision)
	_add_floor_clearance_to_collisions(collision)
	_add_interaction_area(dimensions)


func _add_interaction_area(dimensions: Vector3) -> void:
	var area := Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true

	var area_collision := CollisionShape3D.new()
	area_collision.name = "FocusRadius"
	var sphere := SphereShape3D.new()
	var under_seat := String(get_meta("spawn_zone", "")) == "under_seat"
	sphere.radius = (
		0.62
		if under_seat
		else
		0.54
		if definition != null and String(definition.id) == "straw"
		else clampf(maxf(maxf(dimensions.x, dimensions.z), dimensions.y) * 0.75, 0.30, 0.38)
	)
	area_collision.shape = sphere
	area_collision.position.y = maxf(dimensions.y * 0.5, 0.20 if under_seat else 0.0)
	area.add_child(area_collision)
	add_child(area)


func _get_dimensions(item_id: String) -> Vector3:
	match item_id:
		"ticket": return Vector3(0.30, 0.045, 0.18)
		"napkin": return Vector3(0.3, 0.045, 0.26)
		"cup": return Vector3(0.145, 0.15, 0.145)
		"bottle": return Vector3(0.22, 0.45, 0.22)
		"can": return Vector3(0.08, 0.12, 0.08)
		"straw": return Vector3(0.18, 0.05, 0.40)
		"popcorn": return Vector3(0.17, 0.08, 0.17)
		"bucket": return Vector3(0.22, 0.22, 0.22)
		_: return Vector3(0.2, 0.2, 0.2)


func _make_mesh(item_id: String, dimensions: Vector3) -> PrimitiveMesh:
	if item_id in ["cup", "bottle", "can", "bucket"]:
		var cylinder := CylinderMesh.new()
		cylinder.height = dimensions.y
		cylinder.bottom_radius = dimensions.x * 0.5
		cylinder.top_radius = dimensions.x * (0.58 if item_id in ["cup", "bucket"] else 0.5)
		cylinder.radial_segments = 8
		return cylinder
	if item_id == "popcorn":
		var sphere := SphereMesh.new()
		sphere.radius = dimensions.x * 0.5
		sphere.height = dimensions.y
		sphere.radial_segments = 8
		sphere.rings = 4
		return sphere
	var box := BoxMesh.new()
	box.size = dimensions
	return box


func _make_shape(item_id: String, dimensions: Vector3) -> Shape3D:
	if item_id in ["cup", "bottle", "can", "bucket"]:
		var cylinder := CylinderShape3D.new()
		cylinder.height = dimensions.y
		# The diagonal radius encloses the complete imported AABB. This costs
		# virtually nothing for these small props and keeps their textured mesh
		# above ramps even when a cup, bottle or bucket starts on its side.
		cylinder.radius = Vector2(dimensions.x, dimensions.z).length() * 0.5
		return cylinder
	var box := BoxShape3D.new()
	box.size = dimensions
	return box


func _get_color(item_id: String) -> Color:
	match item_id:
		"ticket": return Color("d8c99b")
		"napkin": return Color("e7ddd2")
		"cup": return Color("d94b4b")
		"bottle": return Color("4d9a78")
		"can": return Color("7ca6c8")
		"straw": return Color("f05d9b")
		"popcorn": return Color("f4c95d")
		"bucket": return Color("c73737")
		_: return Color("ffffff")
