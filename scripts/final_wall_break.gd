extends StaticBody3D

# The authored face stays intact until the first hit. A supported MultiMesh
# removes bricks around each actual impact, while detached islands fall away.
const ROWS := 7
const COLUMNS := 15
const BRICK_SIZE := Vector3(0.28, 0.37, 0.37)
const IMPACT_RADII := [0.73, 0.92, 1.10]
const FRAGMENTS_PER_HIT := 8
const FINAL_FRAGMENTS := 18

var _manager: GameplayManager
var _authored_visual: Node3D
var _collision: CollisionShape3D
var _fractured_visual: MultiMeshInstance3D
var _debris: Array[RigidBody3D] = []
var _debris_cleanup_generation := 0
var _brick_material: StandardMaterial3D
var _dust_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("final_brick_barrier")
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	_authored_visual = get_node_or_null("BrickVisual") as Node3D
	_collision = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _manager == null or _authored_visual == null or _collision == null:
		push_error("FinalWallBreak is missing the manager, visual or collider")
		return
	_brick_material = StandardMaterial3D.new()
	_brick_material.albedo_color = Color("745047")
	_brick_material.roughness = 0.97
	_dust_material = StandardMaterial3D.new()
	_dust_material.albedo_color = Color(0.57, 0.45, 0.40, 0.26)
	_dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fractured_visual = MultiMeshInstance3D.new()
	_fractured_visual.name = "ProceduralFracture"
	add_child(_fractured_visual)
	_manager.final_wall_struck.connect(_on_wall_struck)
	_restore_visual_state()


func hit_wall(global_hit_position: Vector3 = Vector3.ZERO) -> bool:
	if _manager == null:
		return false
	var local_hit := to_local(global_hit_position) if global_hit_position != Vector3.ZERO else Vector3(0.0, 1.2, 0.0)
	return _manager.register_final_wall_hit(Vector2(local_hit.y, local_hit.z))


func _restore_visual_state() -> void:
	if _manager.final_wall_open:
		_authored_visual.visible = false
		_fractured_visual.visible = false
		_collision.disabled = true
	elif _manager.final_wall_damage > 0:
		_authored_visual.visible = false
		_rebuild_fracture(_manager.final_wall_damage)
	else:
		_fractured_visual.visible = false


func _on_wall_struck(hit_count: int) -> void:
	_authored_visual.visible = false
	var removed := _removed_bricks(hit_count)
	if hit_count >= _manager.FINAL_WALL_HITS:
		_fractured_visual.visible = false
		_collision.set_deferred("disabled", true)
	else:
		_rebuild_fracture(hit_count)
	_spawn_debris(hit_count, removed)
	_spawn_dust(hit_count)


func _rebuild_fracture(hit_count: int) -> void:
	var brick_mesh := BoxMesh.new()
	brick_mesh.size = BRICK_SIZE
	brick_mesh.material = _brick_material
	var transforms: Array[Transform3D] = []
	var supported := _supported_bricks(hit_count)
	for row in ROWS:
		for column in COLUMNS:
			if supported[row * COLUMNS + column] == 0:
				continue
			transforms.append(Transform3D(Basis.IDENTITY, _brick_position(row, column)))
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = brick_mesh
	instances.instance_count = transforms.size()
	for index in transforms.size():
		instances.set_instance_transform(index, transforms[index])
	_fractured_visual.multimesh = instances
	_fractured_visual.visible = true


func _brick_position(row: int, column: int) -> Vector3:
	return Vector3(0.0, 0.20 + float(row) * 0.40, -2.80 + float(column) * 0.40 + (0.09 if row % 2 == 1 else -0.09))


func _supported_bricks(hit_count: int) -> PackedByteArray:
	var present := PackedByteArray()
	present.resize(ROWS * COLUMNS)
	if hit_count >= _manager.FINAL_WALL_HITS:
		return present
	for row in ROWS:
		for column in COLUMNS:
			var brick := _brick_position(row, column)
			var removed := false
			for strike in mini(hit_count, _manager.final_wall_hit_points.size()):
				var center: Vector2 = _manager.final_wall_hit_points[strike]
				var distance := Vector2((brick.y - center.x) * 1.05, brick.z - center.y).length()
				var ragged_edge := float((row * 7 + column * 11) % 5 - 2) * 0.035
				if distance < IMPACT_RADII[strike] + ragged_edge:
					removed = true
					break
			present[row * COLUMNS + column] = 0 if removed else 1
	if hit_count <= 0:
		return present
	# Only the brick courses connected to a side or the upper lintel remain.
	var supported := PackedByteArray()
	supported.resize(ROWS * COLUMNS)
	var frontier: Array[int] = []
	for row in ROWS:
		for column in COLUMNS:
			var index := row * COLUMNS + column
			if present[index] == 1 and (row == ROWS - 1 or column == 0 or column == COLUMNS - 1):
				supported[index] = 1
				frontier.append(index)
	var cursor := 0
	while cursor < frontier.size():
		var current := frontier[cursor]
		cursor += 1
		var row := current / COLUMNS
		var column := current % COLUMNS
		for neighbor in [current - COLUMNS if row > 0 else -1, current + COLUMNS if row < ROWS - 1 else -1, current - 1 if column > 0 else -1, current + 1 if column < COLUMNS - 1 else -1]:
			if neighbor >= 0 and present[neighbor] == 1 and supported[neighbor] == 0:
				supported[neighbor] = 1
				frontier.append(neighbor)
	return supported


func _brick_survives(row: int, z: float, hit_count: int) -> bool:
	var stagger := 0.09 if row % 2 == 1 else -0.09
	var column := clampi(roundi((z + 2.80 - stagger) / 0.40), 0, COLUMNS - 1)
	return _supported_bricks(hit_count)[row * COLUMNS + column] == 1


func _removed_bricks(hit_count: int) -> Array[Vector3]:
	var removed: Array[Vector3] = []
	var before := _supported_bricks(hit_count - 1)
	var after := _supported_bricks(hit_count)
	for row in ROWS:
		for column in COLUMNS:
			var index := row * COLUMNS + column
			if before[index] == 1 and after[index] == 0:
				removed.append(_brick_position(row, column))
	return removed


func _spawn_debris(hit_count: int, removed: Array[Vector3]) -> void:
	if removed.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987 + hit_count * 113
	var count := mini(removed.size(), FINAL_FRAGMENTS if hit_count >= _manager.FINAL_WALL_HITS else FRAGMENTS_PER_HIT)
	var picks := range(removed.size())
	for index in count:
		var pick := rng.randi_range(0, picks.size() - 1)
		var source := removed[picks[pick]]
		picks.remove_at(pick)
		var size := BRICK_SIZE * rng.randf_range(0.50, 0.85)
		var body := RigidBody3D.new()
		body.name = "TransientBrick_%02d_%02d" % [hit_count, index]
		body.collision_layer = 0
		body.collision_mask = 1
		body.mass = 0.18
		body.position = source + Vector3(-0.16, 0.0, 0.0)
		body.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.2, 0.2), rng.randf_range(-0.2, 0.2))
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = _brick_material
		var display := MeshInstance3D.new()
		display.mesh = mesh
		body.add_child(display)
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
		body.apply_central_impulse(Vector3(-rng.randf_range(0.9, 1.9), rng.randf_range(0.15, 0.8), rng.randf_range(-0.65, 0.65)))
		body.apply_torque_impulse(Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(-0.15, 0.15), rng.randf_range(-0.15, 0.15)))
		_debris.append(body)
	_clear_debris_later()


func _spawn_dust(hit_count: int) -> void:
	var puff := CPUParticles3D.new()
	puff.name = "ImpactDust_%d" % hit_count
	var center: Vector2 = _manager.final_wall_hit_points[hit_count - 1]
	puff.position = Vector3(-0.22, center.x, center.y)
	puff.amount = 16 if hit_count == _manager.FINAL_WALL_HITS else 8
	puff.lifetime = 0.52
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.direction = Vector3(-1.0, 0.3, 0.0)
	puff.spread = 48.0
	puff.initial_velocity_min = 0.4
	puff.initial_velocity_max = 1.1
	puff.gravity = Vector3(0.0, -0.65, 0.0)
	puff.scale_amount_min = 0.65
	puff.scale_amount_max = 1.2
	var dust_mesh := SphereMesh.new()
	dust_mesh.radius = 0.045
	dust_mesh.height = 0.09
	dust_mesh.radial_segments = 6
	dust_mesh.rings = 3
	dust_mesh.material = _dust_material
	puff.mesh = dust_mesh
	add_child(puff)
	puff.emitting = true
	get_tree().create_timer(1.1, true).timeout.connect(puff.queue_free, CONNECT_ONE_SHOT)


func _clear_debris_later() -> void:
	_debris_cleanup_generation += 1
	var generation := _debris_cleanup_generation
	await get_tree().create_timer(1.9, true).timeout
	if generation != _debris_cleanup_generation:
		return
	for body in _debris:
		if is_instance_valid(body):
			body.queue_free()
	_debris.clear()
