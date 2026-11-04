extends SceneTree

const SETTLE_FRAMES := 150
const MAX_PICKUP_RAY_LENGTH := 2.25

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	for frame in SETTLE_FRAMES:
		await physics_frame

	var manager = get_first_node_in_group("gameplay_manager")
	var player := get_first_node_in_group("player") as CollisionObject3D
	var items: Array[Node] = []
	for item in get_nodes_in_group("trash_item"):
		if item.get_room_id() == &"room_01":
			items.append(item)
	_expect(manager != null, "Gameplay manager is missing")
	_expect(items.size() == 400, "Room one does not contain exactly 400 trash items")
	if manager == null:
		_finish()
		return

	var excluded_trash: Array[RID] = []
	for item in items:
		excluded_trash.append((item as CollisionObject3D).get_rid())
	if player:
		excluded_trash.append(player.get_rid())

	var buried: Array[String] = []
	var unreachable: Array[String] = []
	var out_of_room: Array[String] = []
	var hidden_in_seat_tiers: Array[String] = []
	var settled_on_seats := 0
	for item in items:
		var body := item as RigidBody3D
		var min_floor_clearance := float(body.get_min_floor_clearance(Callable(manager, "_get_trash_floor_height")))
		if min_floor_clearance < -0.012:
			buried.append("%s[%s]@%s(%.3f)" % [body.name, body.get_meta("spawn_zone", "unknown"), body.global_position, min_floor_clearance])
		if absf(body.global_position.x) > 10.82 or body.global_position.z < -14.5 or body.global_position.z > 14.5:
			out_of_room.append(String(body.name))
		if String(body.get_meta("spawn_zone", "")) == "on_seat":
			var ramp_height: float = manager._get_trash_floor_height(body.global_position)
			if body.global_position.y > ramp_height + 0.38:
				settled_on_seats += 1
		if String(body.get_meta("spawn_zone", "")) in ["under_seat", "between_rows"] and min_floor_clearance < -0.012:
			hidden_in_seat_tiers.append("%s[%s]@%s(%.3f)" % [body.name, body.get_meta("spawn_zone", "unknown"), body.global_position, min_floor_clearance])
		if not _has_reachable_pickup_line(body, manager, excluded_trash, player):
			unreachable.append("%s[%s]@%s" % [body.name, body.get_meta("spawn_zone", "unknown"), body.global_position])

	_expect(buried.is_empty(), "Buried trash after settling: %s" % ", ".join(buried.slice(0, 12)))
	_expect(out_of_room.is_empty(), "Trash escaped the playable room: %s" % ", ".join(out_of_room.slice(0, 12)))
	_expect(settled_on_seats >= 12, "Seat props all fall through or off the chairs")
	_expect(hidden_in_seat_tiers.is_empty(), "Trash is hidden inside visible seat tiers: %s" % ", ".join(hidden_in_seat_tiers.slice(0, 12)))
	_expect(unreachable.is_empty(), "Trash lacks a clear pickup line: %s" % ", ".join(unreachable.slice(0, 12)))
	var tier_surfaces := get_nodes_in_group("trash_step_surface")
	_expect(tier_surfaces.size() == 18, "Seat tiers do not expose all 18 trash-only collision volumes")
	for surface in tier_surfaces:
		_expect((surface as StaticBody3D).collision_layer == 4, "A seat-tier trash surface can block the player")

	main.queue_free()
	await process_frame
	_finish()


func _has_reachable_pickup_line(
	item: RigidBody3D,
	manager: Node,
	excluded_trash: Array[RID],
	player: CollisionObject3D
) -> bool:
	var collision := item.get_node_or_null("Collision") as CollisionShape3D
	var target: Vector3 = collision.global_position if collision else item.global_position + Vector3.UP * 0.08
	var target_rid := item.get_rid()
	var ray_exclusions: Array[RID] = excluded_trash.duplicate()
	ray_exclusions.erase(target_rid)
	var standing_exclusions: Array[RID] = excluded_trash.duplicate()
	var space := item.get_world_3d().direct_space_state
	for eye_height in [0.85, 1.55]:
		for radius_value in [0.58, 0.86, 1.14, 1.38]:
			var radius := float(radius_value)
			for angle_index in 24:
				var angle := TAU * float(angle_index) / 24.0
				var sample_x: float = target.x + cos(angle) * radius
				var sample_z: float = target.z + sin(angle) * radius
				var floor_height: float = manager._get_trash_floor_height(Vector3(sample_x, 0.0, sample_z))
				var origin := Vector3(sample_x, floor_height + eye_height, sample_z)
				if origin.distance_to(target) > MAX_PICKUP_RAY_LENGTH:
					continue
				if not _standing_point_is_clear(space, origin, floor_height, standing_exclusions):
					continue
				var query := PhysicsRayQueryParameters3D.create(origin, target, 1, ray_exclusions)
				var hit := space.intersect_ray(query)
				if hit.is_empty() or hit.get("collider") == item:
					return true
	return false


func _standing_point_is_clear(
	space: PhysicsDirectSpaceState3D,
	origin: Vector3,
	floor_height: float,
	exclusions: Array[RID]
) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.55
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, Vector3(origin.x, floor_height + 0.86, origin.z))
	query.collision_mask = 1
	query.exclude = exclusions
	return space.intersect_shape(query, 1).is_empty()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TRASH_LAYOUT_SMOKE_OK")
		quit(0)
	else:
		print("TRASH_LAYOUT_SMOKE_FAILED: %s" % " | ".join(_failures))
		quit(1)
