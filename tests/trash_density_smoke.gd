extends SceneTree

const SAVE_PATH := "res://.godot/trash_density_smoke_save.json"
const EXPECTED := {
	"room_01": Vector2i(380, 20),
	"right_corridor": Vector2i(80, 10), # Visible left corridor; stable save ID.
	"manager_office": Vector2i(16, 2),
	"room_02": Vector2i(420, 60),
	"lobby": Vector2i(520, 35), # Entrance and vestibule are one built zone.
	"room_03": Vector2i(410, 30),
	"left_corridor": Vector2i(105, 15), # Visible right corridor; stable save ID.
	"room_04": Vector2i(640, 20),
}

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
	var manager := main.get_node("GameplayManager") as GameplayManager
	var actual: Dictionary = {}
	var room1_rear := 0
	for item in get_nodes_in_group("trash_item"):
		var key := String(item.room_id)
		if not actual.has(key):
			actual[key] = Vector2i.ZERO
		var current: Vector2i = actual[key]
		if int(item.definition.size_units) == 1:
			current.x += 1
		else:
			current.y += 1
		actual[key] = current
		if key == "room_01" and item.global_position.z > 12.5:
			room1_rear += 1
	for key in EXPECTED:
		var wanted: Vector2i = EXPECTED[key]
		_expect(actual.get(key, Vector2i.ZERO) == wanted, "%s has incorrect small/large counts" % key)
		_expect(int(manager.room_trash_totals.get(key, -1)) == wanted.x + wanted.y, "%s object total is incorrect" % key)
		_expect(int(manager.room_trash_unit_totals.get(key, -1)) == wanted.x + wanted.y * 2, "%s coin total is incorrect" % key)
	_expect(actual.size() == EXPECTED.size(), "Trash spawned in an unbuilt or unknown zone")
	_expect(room1_rear >= 8, "Room 1 rear landing has too little trash")
	var room2 := main.get_node("Room02Blockout") as Room02Blockout
	var room2_positions := room2._build_small_trash_positions() as Array[Vector3]
	var room2_rear := 0
	for position in room2_positions:
		if position.z < 30.0:
			room2_rear += 1
	_expect(room2_rear == 24, "Room 2 small trash is missing from the rear landing")
	for room_id in ["room_03", "room_04"]:
		var room := main.get_node("Room03Blockout" if room_id == "room_03" else "Room04Blockout") as CinemaNewAuditorium
		var small_positions := room._build_trash_positions(false) as Array[Vector3]
		var large_positions := room._build_trash_positions(true) as Array[Vector3]
		var cushion_count := 81 if room_id == "room_03" else 108
		var between_count := 144 if room_id == "room_03" else 272
		var aisle_count := 64 if room_id == "room_03" else 96
		var rear_count := 24 if room_id == "room_03" else 32
		_expect(small_positions.size() == EXPECTED[room_id].x and large_positions.size() == EXPECTED[room_id].y, "%s generated the wrong position count" % room_id)
		var rear_start := cushion_count * 2 + between_count + aisle_count
		for index in range(rear_start, rear_start + rear_count):
			var position := small_positions[index]
			_expect(position.y >= 0.27, "%s has rear trash below the level floor" % room_id)
			for aisle_index in room._aisle_offsets.size():
				var aisle_x: float = room._center_x + room._aisle_offsets[aisle_index]
				_expect(absf(position.x - aisle_x) > room._aisle_width(aisle_index) * 0.5 + 0.1, "%s rear trash is under an entrance ramp" % room_id)
		for position in small_positions + large_positions:
			_expect(absf(position.x - room._center_x) < room._width * 0.5 and position.z > room._min_z + 0.3 and position.z < room._max_z - 0.3, "%s trash escaped the auditorium bounds" % room_id)
	main.get_node("GameIntro").complete_immediately()
	var player := main.get_node("Player") as PlayerController
	player.global_position = Vector3(-9.4, 1.0, 40.0)
	player.set_current_room_id(&"room_03")
	await create_timer(0.6).timeout
	var near_room3 := 0
	var frozen_room4 := 0
	for item in get_nodes_in_group("trash_item"):
		if item.room_id == &"room_03" and item.global_position.distance_squared_to(player.global_position) < 9.0 * 9.0 and item.visible and not item.freeze:
			near_room3 += 1
		if item.room_id == &"room_04" and item.freeze and not item.visible:
			frozen_room4 += 1
	_expect(near_room3 >= 10, "Nearby Room 3 trash did not wake for interaction")
	_expect(frozen_room4 >= 500, "Distant Room 4 trash is still simulated or drawn")
	player.global_position = Vector3(27.9, 1.0, -15.0)
	player.set_current_room_id(&"room_04")
	await create_timer(0.6).timeout
	var near_room4 := 0
	for item in get_nodes_in_group("trash_item"):
		if item.room_id == &"room_04" and item.global_position.distance_squared_to(player.global_position) < 9.0 * 9.0 and item.visible and not item.freeze:
			near_room4 += 1
	_expect(near_room4 >= 10, "Nearby Room 4 trash did not wake for interaction")
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if failures.is_empty():
		print("TRASH_DENSITY_SMOKE_OK")
		quit(0)
	else:
		print("TRASH_DENSITY_SMOKE_FAILED: " + ", ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
