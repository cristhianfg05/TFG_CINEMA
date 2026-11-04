extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH","res://.godot/incremental_density_safety.json")
	call_deferred("_run")

func expect(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _run() -> void:
	var path := OS.get_environment("CINEMA_CLEANER_TEST_SAVE_PATH")
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for frame in 4: await physics_frame
	var manager: GameplayManager = main.get_node("GameplayManager")
	var registry := manager.get_dense_registry()
	var room2: Node = main.get_node("Room02Blockout")
	var player: PlayerController = main.get_node("Player")
	var counts := {}
	var room1_rear := 0
	var room2_rear := 0
	var space := main.get_world_3d().direct_space_state
	for entry in registry.entries:
		var key := String(entry.room)
		var count: Vector2i = counts.get(key,Vector2i.ZERO)
		if entry.definition.size_units==1: count.x+=1
		else: count.y+=1
		counts[key]=count
		var position: Vector3 = entry.pos
		var bottom := position.y+float(entry.bottom)
		expect(bottom>-.06,"Trash below world floor: "+String(entry.id))
		var bounds: AABB = registry.templates[String(entry.definition.id)].bounds
		var transform := Transform3D(Basis.from_euler(entry.rot),position)
		# The world AABB minimum does not describe contact on an inclined floor.
		# Test the oriented model corners at their own X/Z coordinates instead.
		for corner_index in 8:
			var corner: Vector3 = transform*bounds.get_endpoint(corner_index)
			var probe := PhysicsPointQueryParameters3D.new()
			probe.position=corner+Vector3.UP*.025
			probe.collision_mask=5
			probe.exclude=[player.get_rid()]
			var hits := space.intersect_point(probe,1)
			expect(hits.is_empty(),"Trash corner inside solid geometry: %s at %s in %s" % [entry.id,corner,str(hits[0].collider.get_path()) if not hits.is_empty() else ""])
		if key=="room_01":
			if position.z>12.5: room1_rear+=1
			for corner_index in 8:
				var corner: Vector3 = transform*bounds.get_endpoint(corner_index)
				expect(corner.y>=manager._get_trash_floor_height(corner)-.06,"Room 1 trash buried in a ramp/tier: "+String(entry.id))
		if key=="room_02":
			if position.z<30.0: room2_rear+=1
			# The analytic rake only applies between its endpoints. Behind it,
			# three access steps descend to a separate level rear landing.
			for corner_index in 8:
				var corner: Vector3 = transform*bounds.get_endpoint(corner_index)
				if corner.z>=room2.SEATING_REAR_Z and corner.z<=room2.SEATING_FRONT_Z:
					expect(corner.y>=room2._trash_surface_height(corner.x,corner.z)-.06,"Room 2 trash buried in a ramp/tier: "+String(entry.id))
	for room in registry.COUNTS:
		expect(counts.get(room,Vector2i.ZERO)==registry.COUNTS[room],"Wrong normal/large density: "+room)
	expect(counts.size()==8,"Trash appeared in an unbuilt zone")
	expect(room1_rear>=8 and room2_rear>=8,"Rear landings lack trash")
	expect(registry.bodies.is_empty(),"Initial trash should already be resting without a physics warmup")
	var remote: Dictionary
	for entry in registry.entries:
		if String(entry.room)=="room_04":
			remote=entry
			break
	var original_position: Vector3=remote.pos
	main.get_node("GameIntro").complete_immediately()
	player.global_position=original_position+Vector3(0,.4,1.5)
	player.set_current_room_id(&"room_04")
	for frame in 90: await physics_frame
	expect(Vector3(remote.pos).is_equal_approx(original_position) and registry.bodies.is_empty(),"Approaching trash triggered visible gravity/settling")
	print("INCREMENTAL_DENSITY_METRICS ",JSON.stringify({"room1_rear":room1_rear,"room2_rear":room2_rear,"failures":failures.size()}))
	main.queue_free()
	for frame in 5: await process_frame
	for failure in failures.slice(0,24): push_error(failure)
	print("INCREMENTAL_DENSITY_SAFETY_OK" if failures.is_empty() else "INCREMENTAL_DENSITY_SAFETY_FAILED")
	quit(0 if failures.is_empty() else 1)
