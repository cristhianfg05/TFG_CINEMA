extends Node3D

const ROOM_WIDTH := 20.0
const ROOM_LENGTH := 30.0
const ROOM_HEIGHT := 6.0

var _materials: Dictionary = {}


func _ready() -> void:
	_create_materials()
	_build_shell()
	_build_screen_and_door()
	_build_seating()


func _create_materials() -> void:
	_materials = {
		"floor": _make_material(Color("353843")),
		"wall": _make_material(Color("4b2534")),
		"ceiling": _make_material(Color("25242b")),
		"screen": _make_material(Color("d8d1b9")),
		"door": _make_material(Color("2f6f68")),
		"trim": _make_material(Color("b18a45")),
		"seat": _make_material(Color("8f3040")),
		"seat_dark": _make_material(Color("47242d")),
	}


func _build_shell() -> void:
	_add_box("Floor", Vector3(0.0, -0.25, 0.0), Vector3(ROOM_WIDTH, 0.5, ROOM_LENGTH), "floor")
	_add_box("Ceiling", Vector3(0.0, ROOM_HEIGHT + 0.25, 0.0), Vector3(ROOM_WIDTH, 0.5, ROOM_LENGTH), "ceiling")
	_add_box("LeftWall", Vector3(-10.25, 3.0, 0.0), Vector3(0.5, ROOM_HEIGHT, ROOM_LENGTH), "wall")
	_add_box("RightWall", Vector3(10.25, 3.0, 0.0), Vector3(0.5, ROOM_HEIGHT, ROOM_LENGTH), "wall")
	_add_box("FrontWall", Vector3(0.0, 3.0, -15.25), Vector3(ROOM_WIDTH, ROOM_HEIGHT, 0.5), "wall")

	# Rear wall leaves a correctly scaled 2 m doorway at x = 7.5 m.
	_add_box("RearWallLeft", Vector3(-1.75, 3.0, 15.25), Vector3(16.5, ROOM_HEIGHT, 0.5), "wall")
	_add_box("RearWallRight", Vector3(9.25, 3.0, 15.25), Vector3(1.5, ROOM_HEIGHT, 0.5), "wall")
	_add_box("RearWallHeader", Vector3(7.5, 4.1, 15.25), Vector3(2.0, 3.8, 0.5), "wall")


func _build_screen_and_door() -> void:
	_add_box("Screen", Vector3(0.0, 3.25, -14.82), Vector3(12.0, 4.4, 0.12), "screen")
	_add_box("ScreenBottomTrim", Vector3(0.0, 1.0, -14.72), Vector3(12.4, 0.12, 0.18), "trim")
	_add_box("ScreenTopTrim", Vector3(0.0, 5.5, -14.72), Vector3(12.4, 0.12, 0.18), "trim")
	_add_box("ScreenLeftTrim", Vector3(-6.15, 3.25, -14.72), Vector3(0.12, 4.6, 0.18), "trim")
	_add_box("ScreenRightTrim", Vector3(6.15, 3.25, -14.72), Vector3(0.12, 4.6, 0.18), "trim")

	_add_box("Door", Vector3(7.5, 1.05, 14.92), Vector3(1.75, 2.1, 0.16), "door")
	_add_box("DoorLeftTrim", Vector3(6.52, 1.15, 14.82), Vector3(0.18, 2.3, 0.22), "trim")
	_add_box("DoorRightTrim", Vector3(8.48, 1.15, 14.82), Vector3(0.18, 2.3, 0.22), "trim")
	_add_box("DoorTopTrim", Vector3(7.5, 2.3, 14.82), Vector3(2.15, 0.18, 0.22), "trim")


func _build_seating() -> void:
	var row_positions := [-7.0, -4.6, -2.2, 0.2, 2.6, 5.0]
	var left_columns := [-6.4, -5.2, -4.0, -2.8, -1.6]
	var right_columns := [1.6, 2.8, 4.0, 5.2, 6.4]

	for row_index in row_positions.size():
		var z: float = row_positions[row_index]
		for column_index in left_columns.size():
			_add_seat(
				"Seat_L_%02d_%02d" % [row_index + 1, column_index + 1],
				Vector3(left_columns[column_index], 0.0, z)
			)
		for column_index in right_columns.size():
			_add_seat(
				"Seat_R_%02d_%02d" % [row_index + 1, column_index + 1],
				Vector3(right_columns[column_index], 0.0, z)
			)


func _add_seat(seat_name: String, seat_position: Vector3) -> void:
	var seat_root := Node3D.new()
	seat_root.name = seat_name
	seat_root.position = seat_position
	seat_root.add_to_group("phase_1_seat")
	add_child(seat_root)

	_add_box("Cushion", Vector3(0.0, 0.72, 0.0), Vector3(0.95, 0.14, 0.68), "seat", seat_root)
	_add_box("Back", Vector3(0.0, 1.25, 0.29), Vector3(0.95, 1.0, 0.14), "seat", seat_root)
	_add_box("Pedestal", Vector3(0.0, 0.35, 0.2), Vector3(0.18, 0.7, 0.18), "seat_dark", seat_root)


func _add_box(
	box_name: String,
	box_position: Vector3,
	box_size: Vector3,
	material_key: String,
	parent: Node3D = self
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = box_position
	body.collision_layer = 1
	body.collision_mask = 1
	body.add_to_group("phase_1_geometry")

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh.material = _materials[material_key]
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	parent.add_child(body)
	return body


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
