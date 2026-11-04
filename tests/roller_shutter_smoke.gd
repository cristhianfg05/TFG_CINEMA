extends SceneTree

const CinemaDoorCatalog := preload("res://resources/doors/cinema_door_catalog.gd")
const DOOR_SCENE := preload("res://scenes/gameplay/roller_shutter_door.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(CinemaDoorCatalog.ACCESS_IDS.size() == 7, "Cinema door catalog must contain the seven planned accesses")
	var unique_ids: Dictionary = {}
	for access_id in CinemaDoorCatalog.ACCESS_IDS:
		unique_ids[access_id] = true
	_expect(unique_ids.size() == 7, "Cinema door catalog contains duplicate access ids")

	var door := DOOR_SCENE.instantiate() as RollerShutterDoor
	root.add_child(door)
	await process_frame
	await physics_frame
	_expect(is_equal_approx(door.OPENING_WIDTH, 3.0), "Roller door is not 3 m wide")
	_expect(is_equal_approx(door.OPENING_HEIGHT, 2.8), "Roller door is not 2.8 m high")
	_expect(door.has_method("open_door") and door.has_method("close_door"), "Roller door does not expose open_door/close_door")

	var slats := door.get_slat_nodes()
	_expect(slats.size() == 14, "Roller door must use fourteen horizontal slats")
	var shared_mesh: BoxMesh = (slats[0].get_node("Face") as MeshInstance3D).mesh as BoxMesh if not slats.is_empty() else null
	var shared_material: Material = shared_mesh.material if shared_mesh else null
	_expect(shared_mesh is BoxMesh, "Roller slats are not built from a BoxMesh")
	_expect(shared_material is StandardMaterial3D, "Roller slats do not share a StandardMaterial3D")
	if shared_material is StandardMaterial3D:
		var material := shared_material as StandardMaterial3D
		_expect(material.albedo_texture == null, "Roller slat material uses a photographic texture")
		_expect(material.roughness >= 0.8, "Roller slat material is not matte")
		_expect(material.albedo_color.get_luminance() < 0.25, "Roller slat material is not charcoal grey")
	var original_scales: Array[Vector3] = []
	for slat in slats:
		var face := slat.get_node("Face") as MeshInstance3D
		var face_mesh := face.mesh as BoxMesh
		original_scales.append(slat.scale)
		_expect(face_mesh == shared_mesh, "A roller slat uses a different BoxMesh")
		_expect(face_mesh.material == shared_material, "A roller slat uses a different material")
		_expect(slat.get_node_or_null("DarkSeparation") != null, "A roller slat has no dark separation")
		_expect(slat.get_node_or_null("WornEdge") != null, "A roller slat has no worn edge")
	_expect(door.get_node_or_null("GeneratedDoor/Frame/LeftRail") != null, "Roller door has no left frame")
	_expect(door.get_node_or_null("GeneratedDoor/Frame/RightRail") != null, "Roller door has no right frame")
	_expect(door.get_node_or_null("GeneratedDoor/Frame/TopHousing") != null, "Roller door has no top housing")
	_expect(door.door_panel.collision_layer == 1 and not door.collision_shape.disabled, "Closed roller door does not block passage")
	_expect(_ray_hits_blocker(door), "Closed roller door collision does not physically block its opening")

	door.open_door()
	await create_timer(0.58).timeout
	var partly_hidden := _count_hidden_slats(slats)
	_expect(partly_hidden > 0 and partly_hidden < slats.size(), "Slats do not disappear progressively into the housing")
	await create_timer(0.72).timeout
	await physics_frame
	_expect(is_equal_approx(door.openness, 1.0) and _count_hidden_slats(slats) == slats.size(), "Roller door did not finish opening upwards")
	_expect(door.door_panel.collision_layer == 0 and door.collision_shape.disabled, "Open roller door still blocks passage")
	_expect(not _ray_hits_blocker(door), "Open roller door collision still intersects its opening")
	for slat_index in slats.size():
		_expect(slats[slat_index].scale.is_equal_approx(original_scales[slat_index]), "Roller opening squashed a slat")

	door.close_door()
	await create_timer(1.30).timeout
	await physics_frame
	_expect(is_zero_approx(door.openness) and _count_hidden_slats(slats) == 0, "Roller door did not restore every slat when closing")
	_expect(door.door_panel.collision_layer == 1 and not door.collision_shape.disabled, "Closed roller door did not restore its collision")
	_expect(_ray_hits_blocker(door), "Reclosed roller door does not physically block its opening")

	door.queue_free()
	await process_frame
	_finish()


func _count_hidden_slats(slats: Array[Node3D]) -> int:
	var hidden := 0
	for slat in slats:
		if not slat.visible:
			hidden += 1
	return hidden


func _ray_hits_blocker(door: RollerShutterDoor) -> bool:
	var query := PhysicsRayQueryParameters3D.create(Vector3(0.0, 1.4, -1.0), Vector3(0.0, 1.4, 1.0), 1)
	var hit := root.world_3d.direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == door.door_panel


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ROLLER_SHUTTER_SMOKE_OK")
		quit(0)
	else:
		push_error("ROLLER_SHUTTER_SMOKE_FAILED: %s" % " | ".join(_failures))
		quit(1)
