extends SceneTree

const SAVE_PATH := "res://.godot/room_04_polish_smoke_save.json"

var _failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var room3 := main.get_node("Room03Blockout") as Node3D
	var room4 := main.get_node("Room04Blockout") as Node3D
	for room in [room3, room4]:
		for side in [-1, 1]:
			var name := "%sCinemaSpeaker%s" % ["Room03" if room == room3 else "Room04", "Left" if side < 0 else "Right"]
			var speaker := room.get_node(name) as Node3D
			var model := speaker.get_child(0) as Node3D
			var collision := speaker.get_child(1) as CollisionShape3D
			var expected_size := Vector3(2.2, 3.5, 1.9) if room == room3 else Vector3(1.6, 2.5, 1.4)
			_expect((collision.shape as BoxShape3D).size.is_equal_approx(expected_size), "%s still has an oversized invisible collision block" % name)
			_expect(is_equal_approx(collision.rotation.y, model.rotation.y), "%s collision does not rotate with the visible speaker" % name)
			var toward_audience := Vector3.BACK.rotated(Vector3.UP, model.rotation.y)
			_expect(toward_audience.z * (-1.0 if room == room3 else 1.0) > 0.6 and toward_audience.x * float(side) < -0.6, "%s is not aimed at the seats" % name)
	var sign := room4.get_node("FearWitchSignLeftOfDoor") as Node3D
	_expect(is_zero_approx(sign.position.y), "The witch sign does not touch the floor")
	var skulls := room4.find_children("FearSkull_*", "Node3D", false, false)
	_expect(skulls.size() == 6, "Room 4 must have six skulls")
	var landing_skulls := 0
	for skull in skulls:
		if skull.position.z < -9.0 and skull.position.z > -16.0:
			landing_skulls += 1
	_expect(landing_skulls == 2, "The two additional skulls are not inside the rear landing")
	var seats := room4.find_children("Room04Seat_*", "StaticBody3D", false, false)
	_expect(seats.size() == 144, "Room 4 seating layout changed")
	for seat in seats:
		_expect(is_equal_approx((seat.get_child(0) as Node3D).rotation.y, PI), "Room 4 has a backward-facing seat: %s" % seat.name)
	var expected_widths := [2.40, 3.40, 2.40]
	for aisle in 3:
		var ramp := room4.get_node("EntranceRamp_%02d" % aisle) as Node3D
		_expect(is_equal_approx(ramp.position.z, -13.875), "Room 4 staircase does not keep its five-step rise up to the seating")
		for step in 5:
			var stair := room4.get_node("EntranceStep_%02d_%02d" % [aisle, step]) as Node3D
			var mesh := (stair.get_child(0) as MeshInstance3D).mesh as BoxMesh
			_expect(is_equal_approx(mesh.size.x, expected_widths[aisle]) and is_equal_approx(mesh.size.z, 0.85), "Room 4 step is too narrow or stretched")
			_expect(is_equal_approx(stair.position.y + mesh.size.y * 0.5, 1.75 * float(step + 1) / 5.0), "Room 4 step rise changed")
	await physics_frame
	var sampled_heights: Array[float] = []
	for sample_z in [-10.5, -13.875, -15.7]:
		var ray := PhysicsRayQueryParameters3D.create(room4.to_global(Vector3(-44.0, 3.0, sample_z)), room4.to_global(Vector3(-44.0, -1.0, sample_z)), 1)
		var hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(ray)
		_expect(not hit.is_empty(), "Room 4 center aisle has no walkable floor at z=%.3f" % sample_z)
		if not hit.is_empty():
			sampled_heights.append((hit.position as Vector3).y)
	if sampled_heights.size() == 3:
		_expect(sampled_heights[0] < 0.10 and sampled_heights[1] > 0.65 and sampled_heights[2] > 1.45, "Room 4's five compact steps no longer lift the player to the rear row")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if _failures.is_empty():
		print("ROOM_04_POLISH_SMOKE_OK")
		quit(0)
	else:
		print("ROOM_04_POLISH_SMOKE_FAILED: ", _failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("ROOM 04 POLISH TEST: %s" % message)
