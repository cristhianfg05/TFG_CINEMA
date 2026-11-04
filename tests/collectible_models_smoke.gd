extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const Catalog := preload("res://resources/collectibles/collectible_catalog.gd")
const SAVE_PATH := "res://.godot/collectible_models_smoke_save.json"
const PLACED_IDS := [
	"capitan_orbita", "amelia_del_anden", "hombre_del_paraguas",
	"palomito", "reina_refresco", "devorapalomitas",
	"acomodador_sin_rostro", "detective_mecha_corta", "paloma_dinamita",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var manager := get_first_node_in_group("gameplay_manager")
	var player := get_first_node_in_group("player")
	var hud := main.get_node("GameplayHUD")
	var pickups := get_nodes_in_group("collectible_pickup")
	_check(pickups.size() == 9, "Expected nine physical pickups, not %d" % pickups.size())
	_check(Catalog.get_definitions().size() == 14, "Ten figures and four posters are not registered")
	for collectible_id in PLACED_IDS:
		var pickup: Node3D = null
		for candidate in pickups:
			if candidate.collectible_id == collectible_id:
				pickup = candidate
				break
		_check(pickup != null, "Missing pickup %s" % collectible_id)
		if pickup == null:
			continue
		var model := pickup.get_node_or_null("VisualRoot/CollectibleModel") as Node3D
		_check(model != null, "Missing model %s" % collectible_id)
		_check(pickup.get_node_or_null("Glow") == null, "Legacy glow remains on %s" % collectible_id)
		if model == null:
			continue
		_check(model.scale.is_equal_approx(Vector3.ONE), "Authored scale was changed on %s" % collectible_id)
		_check(is_equal_approx(model.rotation_degrees.x, -90.0), "Figure is not lying down: %s" % collectible_id)
		var floor_query := PhysicsRayQueryParameters3D.create(pickup.global_position + Vector3.UP * 3.0, pickup.global_position + Vector3.DOWN * 3.0, 1)
		var floor_hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(floor_query)
		var floor_y := (floor_hit.get("position", Vector3.ZERO) as Vector3).y
		var local_lowest := _model_lowest_world_y(model)
		print("COLLECTIBLE_PLACEMENT %s at=%s low=%.3f floor=%.3f hit=%s" % [collectible_id, str(pickup.global_position), local_lowest, floor_y, str(floor_hit.get("collider", "none"))])
		_check(not floor_hit.is_empty(), "No supporting floor for %s" % collectible_id)
		_check(local_lowest >= floor_y - 0.06 and local_lowest <= floor_y + 0.08, "Figure does not rest on floor: %s" % collectible_id)
		var clearance := PhysicsShapeQueryParameters3D.new()
		var probe := SphereShape3D.new()
		probe.radius = 0.18
		clearance.shape = probe
		clearance.transform = Transform3D(Basis.IDENTITY, pickup.global_position + Vector3.UP * 0.25)
		clearance.collision_mask = 1
		var overlaps: Array[Dictionary] = main.get_world_3d().direct_space_state.intersect_shape(clearance, 8)
		if not overlaps.is_empty():
			for overlap in overlaps:
				var collider := overlap.get("collider") as Node3D
				print("COLLECTIBLE_OVERLAP %s %s at=%s" % [collectible_id, str(collider), str(collider.global_position) if collider else "?"])
		_check(overlaps.is_empty(), "Figure overlaps solid room geometry: %s" % collectible_id)
	_check(not PLACED_IDS.has("dama_de_la_linterna") and not manager.is_collectible_found("dama_de_la_linterna"), "Future-room figure unexpectedly appeared")
	for collectible_id in PLACED_IDS:
		var pickup := _find_pickup(collectible_id)
		if pickup:
			pickup.interact(player)
			await process_frame
			_check(manager.is_collectible_found(collectible_id), "Pickup did not register: %s" % collectible_id)
			_check(hud._objective_sound.playing, "Approved collectible sound was not played: %s" % collectible_id)
	_check(manager.get_found_collectible_count() == 9, "Figure progress or duplicate collection is wrong")
	_check(manager.is_recording_found("09") and manager.is_recording_found("10") and not manager.is_recording_found("17"), "Figure recording milestones are wrong")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if _failures.is_empty():
		print("COLLECTIBLE_MODELS_SMOKE_OK")
		quit()
	else:
		for failure in _failures:
			push_error("COLLECTIBLE MODELS: " + failure)
		print("COLLECTIBLE_MODELS_SMOKE_FAILED: ", ", ".join(_failures))
		quit(1)


func _model_lowest_world_y(model: Node3D) -> float:
	var minimum := INF
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		if instance.mesh == null:
			continue
		var bounds := instance.mesh.get_aabb()
		for corner in 8:
			minimum = minf(minimum, instance.to_global(bounds.get_endpoint(corner)).y)
	return minimum


func _find_pickup(collectible_id: String) -> Node:
	for candidate in get_nodes_in_group("collectible_pickup"):
		if candidate.collectible_id == collectible_id:
			return candidate
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
