extends SceneTree

const SAVE_PATH := "res://.godot/room_02_smoke_save.json"
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var room = main.get_node_or_null("Room02Blockout")
	var manager = get_first_node_in_group("gameplay_manager")
	var player = get_first_node_in_group("player")
	_expect(room != null, "Room 2 scene is missing")
	_expect(room.get_node_or_null("Room02Screen") != null and room.get_node_or_null("BajoLasLucesPoster") == null, "Room 2 screen must be blank")
	_expect(room.get_node_or_null("Room02EntryPosterDisplay") != null, "Room 2 entry poster slot is missing")
	_expect(room.get_node("Room02EntryPosterFrame").position.z - room.get_node("Room02EntryPosterDisplay").position.z < 0.15 and room.get_node("Room02EntryPosterDisplay").position.y > 1.3, "Room 2 poster image floats ahead or sits too low")
	_expect(room.get_node_or_null("Room02EntryDoorInteriorHeader") != null, "Room 2 lacks its own inner wall above the doorway")
	_expect(room.get_node_or_null("Room02EntryTable") == null, "Room 2 entry table must be removed")
	var poster_frame: Node3D = room.get_node("Room02EntryPosterFrame")
	var potato_display: Node3D = main.get_node("LeftWingBlockout/Room02WallPotatoDisplay")
	_expect(poster_frame.position.y == 0.0 and poster_frame.position.z < room.ENTRY_Z, "Room 2 poster must stand on the corridor floor")
	_expect(poster_frame.position.x > potato_display.position.x and poster_frame.position.x < 7.5, "Room 2 poster must be left of the potato display without blocking the shutter")
	_expect(poster_frame.get_node("Model").scale.x > 1.4, "Room 2 poster was not enlarged")
	_expect(room.get_node_or_null("Room02Zone") != null, "Room 2 zone is missing")
	_expect(is_equal_approx(room.ROOM_CENTER_X - room.ROOM_WIDTH * 0.5, 7.5), "Room 2 extends left of the existing shutter")
	_expect(room.ROOM_CENTER_X - room.ROOM_WIDTH * 0.5 > -12.0, "Room 2 invades the manager-side corridor")
	_expect(room.find_children("Room02Seat_*", "StaticBody3D", false, false).size() == 162, "Room 2 must contain 9 rows of 18 paired seats")
	var seat_variants := {"ButacaRota": 0, "ButacaEstandar": 0, "ButacaPlegada": 0}
	for seat in room.find_children("Room02Seat_*", "StaticBody3D", false, false):
		var variant := String(seat.get_meta("seat_variant", ""))
		if seat_variants.has(variant):
			seat_variants[variant] += 1
		if variant == "ButacaPlegada":
			_expect(not seat.has_node("SeatCushionSurface"), "Folded Room 2 seat has a false cushion collider")
	_expect(seat_variants["ButacaRota"] == 32 and seat_variants["ButacaEstandar"] == 97 and seat_variants["ButacaPlegada"] == 33, "Room 2 is not using the standard-majority mix of all three existing seat variants")
	var carpet_material := room.get_node("Room02CarpetFloor").get_child(0).mesh.material as StandardMaterial3D
	_expect(carpet_material.albedo_texture.resource_path.ends_with("room_02_romance_carpet.svg"), "Room 2 is still using Room 1's carpet")
	_expect(room.find_children("Room02AisleSlope_*", "StaticBody3D", false, false).size() == 4, "Room 2 must expose exactly four traversable aisles")
	_expect(room.find_children("Room02RearAccessSlope_*", "StaticBody3D", false, false).size() == 4, "Room 2 must expose four entrance stair ramps")
	_expect(room.find_children("Room02HeartLight_*", "Node3D", false, false).is_empty(), "Room 2 must not have illuminated hearts on its floor")
	_expect(room.find_children("Room02HangingHeart_*", "Node3D", false, false).size() == 9, "Room 2 must hang three hearts over each seating block")
	_expect(room.get_node("Room02HangingHeart_01").scale == Vector3.ONE and room.get_node("Room02HangingHeart_01/Model").scale.x >= 2.5 and room.get_node("Room02HangingHeart_01").position.y < 5.4, "Room 2 hanging hearts were not enlarged and lowered")
	_expect(absf(room.get_node("Room02HangingHeart_01").rotation.x) > 0.01 and room.get_node("Room02HangingHeart_01").position.z != room.get_node("Room02HangingHeart_04").position.z, "Room 2 hearts must be tilted and staggered")
	var heart_start_yaw: float = room.get_node("Room02HangingHeart_01").rotation.y
	for frame in 15:
		await process_frame
	_expect(absf(angle_difference(heart_start_yaw, room.get_node("Room02HangingHeart_01").rotation.y)) > 0.001, "Room 2 ceiling hearts are not rotating")
	var petals := room.find_children("Room02Petals_*", "Node3D", false, false)
	_expect(petals.size() == 82, "Room 2 aisle, front and rear petals are missing")
	var front_zs := {}
	var rear_zs := {}
	var front_count := 0
	var rear_count := 0
	for petal in petals:
		_expect(petal.get_node("Model").scale.x >= 0.088, "A Room 2 petal group was not enlarged")
		if petal.position.z >= 51.8:
			front_count += 1
			front_zs[snappedf(petal.position.z, 0.1)] = true
		elif petal.position.z <= 30.0:
			rear_count += 1
			rear_zs[snappedf(petal.position.z, 0.1)] = true
	_expect(front_count == 20 and rear_count == 30, "Room 2 needs scattered petals at both the front and rear")
	_expect(front_zs.size() > 10 and rear_zs.size() > 10, "Front or rear Room 2 petals still form rigid rows")
	_expect(room.find_children("Room02TablePetals_*", "Node3D", false, false).is_empty(), "Room 2 table petals must be removed")
	_expect(is_equal_approx(room.get_node("Room02Bow_L_01").position.y + 0.48, 2.55) and is_equal_approx(room.get_node("Room02Bow_R_01").position.y + 0.48, 2.55), "Room 2 bows are not centred on the horizontal wall beam")
	_expect(room.find_children("Room02EntryWallPillar_*", "StaticBody3D", false, false).size() == 6, "Room 2 rear wall pillars are missing")
	_expect(room.find_children("Room02EntryWinePanel_*", "StaticBody3D", false, false).size() == 5, "Room 2 rear wine wall must use uniform panels")
	_expect(room.find_children("Room02Grille_*", "Node3D", false, false).size() == 12, "Room 2 grilles must remain only on the lateral walls")
	_expect(room.find_children("Room02WallSpeaker_*", "Node3D", false, false).size() == 12, "Room 2 small speakers must remain only on the lateral walls")
	_expect(room.find_children("Room02WallLightA_*", "Node3D", false, false).size() == 12 and room.find_children("Room02WallLightB_*", "Node3D", false, false).size() == 12, "Room 2 wall lights must remain only on the lateral walls")
	_expect(room.get_node_or_null("Room02EntryLight") == null, "Room 2 rear wall light must be removed")
	var speaker_left: Node3D = room.get_node("Room02CinemaSpeakerLeft")
	var speaker_right: Node3D = room.get_node("Room02CinemaSpeakerRight")
	_expect(speaker_left.get_node("Model").scale.x > 2.7 and absf(angle_difference(speaker_left.rotation.y, PI - deg_to_rad(45.0))) < 0.001, "Room 2 left cinema speaker must be bigger and face the seats")
	_expect(speaker_right.get_node("Model").scale.x > 2.7 and absf(angle_difference(speaker_right.rotation.y, PI + deg_to_rad(45.0))) < 0.001, "Room 2 right cinema speaker must be bigger and face the seats")
	var room_trash := get_nodes_in_group("trash_item").filter(func(item): return item.get_room_id() == &"room_02")
	_expect(room_trash.size() == 480, "Room 2 must contain exactly 480 trash objects")
	_expect(room_trash.filter(func(item): return item.definition.size_units == 1).size() == 420, "Room 2 must contain 420 one-coin objects")
	_expect(room_trash.filter(func(item): return item.definition.size_units == 2).size() == 60, "Room 2 must contain 60 two-coin objects")
	_expect(manager.room_trash_totals.get("room_02", 0) == 480, "Room 2 trash total is not registered")
	_expect(manager.room_trash_unit_totals.get("room_02", 0) == 540, "Room 2 coin total is not registered")
	for item in room_trash:
		_expect(item.global_position.x >= 7.5 and item.global_position.x <= 34.7, "Room 2 trash crossed a side wall")
		_expect(item.global_position.z >= 25.0 and item.global_position.z <= 57.0, "Room 2 trash crossed an end wall")
	var first_step = room.get_node("Room02RearAccess_00_00")
	var last_step = room.get_node("Room02RearAccess_00_02")
	_expect(first_step.position.z < last_step.position.z and first_step.get_child(0).mesh.size.y < last_step.get_child(0).mesh.size.y, "Room 2 entrance stairs face the wrong way")
	var zone = room.get_node("Room02Zone")
	zone._on_body_entered(player)
	_expect(player.get_current_room_id() == &"room_02", "Room 2 zone did not set the player room")
	var shutter = main.get_node("LeftWingBlockout/Room02Access")
	manager.room_completed = true
	manager.state_changed.emit()
	for frame in 90:
		await physics_frame
	_expect(shutter.shutter.is_open and shutter.shutter.collision_shape.disabled, "Room 2 shutter did not open after Room 1 completion")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("ROOM_02_SMOKE_OK")
		quit(0)
	else:
		print("ROOM_02_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
