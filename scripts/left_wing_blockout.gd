class_name LeftWingBlockout
extends Node3D

const DoorCatalog := preload("res://resources/doors/cinema_door_catalog.gd")
const ProgressionShutterScript := preload("res://scripts/progression_shutter.gd")
const RoomZoneScript := preload("res://scripts/room_zone.gd")
const CHARCOAL := preload("res://resources/materials/cinema_charcoal.tres")
const CREAM := preload("res://resources/materials/corridor_aged_plaster.tres")
const WINE := preload("res://resources/materials/cinema_panel_wine.tres")
const FLOOR := preload("res://resources/materials/corridor_worn_floor.tres")
const WARM_LIGHT := preload("res://resources/materials/cinema_step_light.tres")
const TRASH_SCENE := preload("res://scenes/gameplay/trash_item.tscn")
const LOST_FOUND_SCENE := preload("res://scenes/gameplay/lost_found_box.tscn")
const TABLE_SCENE := preload("res://assets/models/source/decoration/MesaCuadrada.glb")
const VACUUM_SCENE := preload("res://assets/models/source/tools/aspiradora.glb")
const BROOM_SCENE := preload("res://assets/pipeline/props/cinema_broom.glb")
const STOOL_SCENE := preload("res://assets/models/source/decoration/Taburete.glb")
const ARCADE_SCENE := preload("res://assets/models/source/decoration/MaquinaRecreativa.glb")
const ROUND_TABLE_SCENE := preload("res://assets/models/source/decoration/MesaRedonda.glb")
const VENDING_SCENE := preload("res://assets/models/source/decoration/MaquinaExpendedora.glb")
const ARMCHAIR_SCENE := preload("res://assets/models/source/decoration/Sillón.glb")
const POTATO_DISPLAY_SCENE := preload("res://assets/models/source/decoration/ExpositorPatatas.glb")
const ENTRY_POSTER_SCENE := preload("res://assets/models/source/general/cartelPeliculas.glb")
const PosterMaterialScript := preload("res://scripts/cinema_poster_material.gd")
const MANAGER_LEVER_BOX_SCENE := preload("res://scenes/props/manager_lever_box.tscn")
const ToolDisplayScript := preload("res://scripts/tool_display.gd")
const HAMMER_SCENE := preload("res://assets/pipeline/props/manager_mallet.glb")
const HammerPickupScript := preload("res://scripts/manager_hammer_pickup.gd")
const ArcadeMachineScript := preload("res://scripts/arcade_machine.gd")
const SMALL_TRASH: Array[Resource] = [
	preload("res://resources/trash/ticket.tres"), preload("res://resources/trash/napkin.tres"),
	preload("res://resources/trash/cup.tres"), preload("res://resources/trash/can.tres"),
	preload("res://resources/trash/straw.tres"), preload("res://resources/trash/popcorn.tres"),
]
const LARGE_TRASH: Array[Resource] = [
	preload("res://resources/trash/bottle.tres"), preload("res://resources/trash/bucket.tres"),
]
const CORRIDOR_SMALL_POSITIONS: Array[Vector3] = [
	Vector3(-10.750, 0.200, 15.580),
	Vector3(-10.750, 0.225, 21.400),
	Vector3(-10.750, 0.250, 16.200),
	Vector3(-10.750, 0.200, 20.780),
	Vector3(-9.720, 0.225, 15.580),
	Vector3(-9.720, 0.250, 21.400),
	Vector3(-9.720, 0.200, 16.200),
	Vector3(-9.720, 0.225, 20.780),
	Vector3(-8.690, 0.250, 15.580),
	Vector3(-8.690, 0.200, 21.400),
	Vector3(-8.690, 0.225, 16.200),
	Vector3(-8.690, 0.250, 20.780),
	Vector3(-7.660, 0.200, 15.580),
	Vector3(-7.660, 0.225, 21.400),
	Vector3(-7.660, 0.250, 16.200),
	Vector3(-7.660, 0.200, 20.780),
	Vector3(-6.630, 0.225, 15.580),
	Vector3(-6.630, 0.250, 21.400),
	Vector3(-6.630, 0.200, 16.200),
	Vector3(-6.630, 0.225, 20.780),
	Vector3(-5.600, 0.250, 15.580),
	Vector3(-5.600, 0.200, 21.400),
	Vector3(-5.600, 0.225, 16.200),
	Vector3(-5.600, 0.250, 20.780),
	Vector3(-4.570, 0.200, 15.580),
	Vector3(-4.570, 0.225, 21.400),
	Vector3(-4.570, 0.250, 16.200),
	Vector3(-4.570, 0.200, 20.780),
	Vector3(-3.540, 0.225, 15.580),
	Vector3(-3.540, 0.250, 21.400),
	Vector3(-3.540, 0.200, 16.200),
	Vector3(-3.540, 0.225, 20.780),
	Vector3(-2.510, 0.250, 15.580),
	Vector3(-2.510, 0.200, 21.400),
	Vector3(-2.510, 0.225, 16.200),
	Vector3(-2.510, 0.250, 20.780),
	Vector3(-1.480, 0.200, 15.580),
	Vector3(-1.480, 0.225, 21.400),
	Vector3(-1.480, 0.250, 16.200),
	Vector3(-1.480, 0.200, 20.780),
	Vector3(-0.450, 0.225, 15.580),
	Vector3(-0.450, 0.250, 21.400),
	Vector3(-0.450, 0.200, 16.200),
	Vector3(-0.450, 0.225, 20.780),
	Vector3(0.580, 0.250, 15.580),
	Vector3(0.580, 0.200, 20.150),
	Vector3(0.580, 0.225, 16.200),
	Vector3(0.580, 0.250, 20.150),
	Vector3(1.610, 0.200, 15.580),
	Vector3(1.610, 0.225, 20.150),
	Vector3(1.610, 0.250, 16.200),
	Vector3(1.610, 0.200, 20.150),
	Vector3(2.640, 0.225, 15.580),
	Vector3(2.640, 0.250, 20.150),
	Vector3(2.640, 0.200, 16.200),
	Vector3(2.640, 0.225, 20.150),
	Vector3(3.670, 0.250, 15.580),
	Vector3(3.670, 0.200, 20.150),
	Vector3(3.670, 0.225, 16.200),
	Vector3(3.670, 0.250, 20.150),
	Vector3(4.700, 0.200, 15.580),
	Vector3(4.700, 0.225, 21.400),
	Vector3(4.700, 0.250, 16.200),
	Vector3(4.700, 0.200, 20.780),
	Vector3(5.730, 0.225, 18.000),
	Vector3(5.730, 0.250, 21.400),
	Vector3(5.730, 0.200, 19.000),
	Vector3(5.730, 0.225, 20.780),
	Vector3(6.760, 0.250, 18.000),
	Vector3(6.760, 0.200, 21.400),
	Vector3(6.760, 0.225, 19.000),
	Vector3(6.760, 0.250, 20.780),
	Vector3(7.790, 0.200, 17.050),
	Vector3(7.790, 0.225, 21.400),
	Vector3(7.790, 0.250, 17.050),
	Vector3(7.790, 0.200, 20.780),
	Vector3(8.820, 0.225, 17.050),
	Vector3(8.820, 0.250, 21.400),
	Vector3(8.820, 0.200, 17.050),
	Vector3(8.820, 0.225, 20.780),
]
const CORRIDOR_LARGE_POSITIONS: Array[Vector3] = [
	Vector3(-10.8, 0.34, 16.4), Vector3(-9.1, 0.34, 21.25), Vector3(-7.0, 0.34, 15.7),
	Vector3(-4.7, 0.34, 21.25), Vector3(-2.4, 0.34, 15.7), Vector3(0.0, 0.34, 20.6),
	Vector3(4.5, 0.34, 21.25), Vector3(6.2, 0.34, 19.7), Vector3(8.1, 0.34, 20.9),
	Vector3(10.2, 0.34, 17.0),
]
const OFFICE_SMALL_POSITIONS: Array[Vector3] = [
	Vector3(-18.550, 0.200, 15.550),
	Vector3(-18.550, 0.200, 21.400),
	Vector3(-18.550, 0.200, 16.350),
	Vector3(-13.100, 0.200, 16.000),
	Vector3(-17.830, 0.200, 15.550),
	Vector3(-17.830, 0.200, 21.400),
	Vector3(-18.550, 0.200, 17.450),
	Vector3(-13.100, 0.200, 17.350),
	Vector3(-17.110, 0.200, 15.550),
	Vector3(-17.110, 0.200, 21.400),
	Vector3(-18.550, 0.200, 18.550),
	Vector3(-13.100, 0.200, 18.700),
	Vector3(-16.390, 0.200, 15.550),
	Vector3(-16.390, 0.200, 21.400),
	Vector3(-18.550, 0.200, 19.650),
	Vector3(-13.100, 0.200, 20.050),
]
const OFFICE_LARGE_POSITIONS: Array[Vector3] = [Vector3(-18.35, 0.34, 16.20), Vector3(-13.25, 0.34, 21.10)]


const WALL_HEIGHT := 4.4
const WALL_RED_TOP := 2.55
const WALL_DEPTH := 0.24
const CORRIDOR_MIN_X := -12.0
const CORRIDOR_MAX_X := 11.0
const CORRIDOR_MIN_Z := 15.0
const CORRIDOR_CEILING_MIN_Z := 15.36
const CORRIDOR_MAX_Z := 25.0
const OFFICE_MIN_X := -19.0
const OFFICE_MAX_X := -12.0
const OFFICE_MAX_Z := 24.76


func _ready() -> void:
	_build_corridor()
	_build_office_shell()
	_build_doors()
	_build_room_zones()
	_build_lighting()
	_build_corridor_decorations()
	_build_office_contents()
	call_deferred("_spawn_fixed_trash")


func _build_corridor() -> void:
	var corridor_depth := CORRIDOR_MAX_Z - CORRIDOR_MIN_Z
	var corridor_center_z := (CORRIDOR_MIN_Z + CORRIDOR_MAX_Z) * 0.5
	var ceiling_depth := CORRIDOR_MAX_Z - CORRIDOR_CEILING_MIN_Z
	var ceiling_center_z := (CORRIDOR_CEILING_MIN_Z + CORRIDOR_MAX_Z) * 0.5
	_add_solid("CorridorFloor", Vector3(23.0, 0.20, corridor_depth), Vector3(-0.5, -0.10, corridor_center_z), FLOOR)
	_add_solid("CorridorCeiling", Vector3(23.0, 0.20, ceiling_depth), Vector3(-0.5, WALL_HEIGHT + 0.10, ceiling_center_z), CHARCOAL)
	# The north face is Room 1's existing rear wall; leaving it untouched avoids
	# doubled collision and guarantees the existing 3 m exit opening remains exact.
	# Room 1's rear face ends at z=15.24. The corridor-facing skin and the
	# connector corner both end on z=15.31, avoiding the visible stepped join.
	var join_y := WALL_RED_TOP - 0.02
	_add_solid("ConnectorNorthLower", Vector3(0.76, join_y, WALL_DEPTH), Vector3(-11.62, join_y * 0.5, 15.19), WINE)
	_add_solid("ConnectorNorthUpper", Vector3(0.76, WALL_HEIGHT - join_y, WALL_DEPTH), Vector3(-11.62, (join_y + WALL_HEIGHT) * 0.5, 15.19), CREAM)
	# Keep the visual-only skin clear of Room 1's legacy wall and its collision.
	_add_corridor_wall_skin_z("Room01ExteriorLeft", -11.24, 7.5, 15.30)
	_add_corridor_wall_skin_z("Room01ExteriorRight", 10.5, 11.0, 15.30)
	_add_visual_box("Room01ExteriorHeader", Vector3(3.0, 1.6, 0.02), Vector3(9.0, 3.6, 15.30), CREAM)
	# Match the dark doorway frame already used at the Room 2 entrance without
	# adding new collision over Room 1's existing shutter rails.
	_add_visual_box("Room01DoorFrameLeft", Vector3(0.42, WALL_HEIGHT, 0.28), Vector3(7.5, WALL_HEIGHT * 0.5, 15.44), CHARCOAL)
	_add_visual_box("Room01DoorFrameRight", Vector3(0.42, WALL_HEIGHT, 0.28), Vector3(10.5, WALL_HEIGHT * 0.5, 15.44), CHARCOAL)
	_add_visual_box("Room01DoorFrameTop", Vector3(3.42, 0.38, 0.28), Vector3(9.0, 3.02, 15.44), CHARCOAL)
	# Sala 3 now owns the north face around its shutter at z=25.
	# Narrowing Sala 3 leaves this short north-facing corridor cap between
	# its new east wall and Sala 2's unchanged west wall.
	_add_layered_wall_z("Room03Room02Gap", 4.25, 7.5, CORRIDOR_MAX_Z)
	_add_layered_wall_z("SouthRight", 10.5, CORRIDOR_MAX_X, CORRIDOR_MAX_Z)
	_add_solid("Room02DoorHeader", Vector3(3.0, 1.6, WALL_DEPTH), Vector3(9.0, 3.6, CORRIDOR_MAX_Z), CREAM)
	# The original corridor retains its footprint. Its east end now has the
	# three-metre doorway into the narrow vestibule shown opposite Manager.
	_add_layered_wall_x("VestibuleSideSouth", CORRIDOR_MIN_Z, 17.0, CORRIDOR_MAX_X)
	_add_layered_wall_x("VestibuleSideNorth", 20.0, 24.62, CORRIDOR_MAX_X)
	_add_solid("VestibuleDoorHeader", Vector3(WALL_DEPTH, 1.6, 3.0), Vector3(CORRIDOR_MAX_X, 3.6, 18.5), CREAM)
	_add_visual_box("VestibuleDoorFrameSouth", Vector3(0.08, 2.8, 0.34), Vector3(10.84, 1.4, 17.0), CHARCOAL)
	_add_visual_box("VestibuleDoorFrameNorth", Vector3(0.08, 2.8, 0.34), Vector3(10.84, 1.4, 20.0), CHARCOAL)
	_add_visual_box("VestibuleDoorFrameTop", Vector3(0.08, 0.38, 3.34), Vector3(10.84, 3.0, 18.5), CHARCOAL)
	_add_pillar(Vector3(CORRIDOR_MIN_X, 2.2, 15.35))
	# The new jamb replaces this former corner pillar.
	_add_pillar(Vector3(CORRIDOR_MAX_X, 2.2, CORRIDOR_MAX_Z))
	_add_pillar(Vector3(7.5, 2.2, CORRIDOR_MAX_Z))
	_add_pillar(Vector3(10.5, 2.2, CORRIDOR_MAX_Z))


func _build_office_shell() -> void:
	# Extend the manager's floor to the same north/south reach as the corridor.
	# The end wall stops 0.24 m short of Room 3's wall to avoid coplanar faces.
	_add_solid("OfficeFloor", Vector3(7.0, 0.20, 10.0), Vector3(-15.5, -0.10, 20.0), FLOOR)
	_add_solid("OfficeCeiling", Vector3(7.0, 0.20, 10.0), Vector3(-15.5, WALL_HEIGHT + 0.10, 20.0), CHARCOAL)
	_add_layered_wall_z("OfficeNorth", OFFICE_MIN_X, OFFICE_MAX_X, CORRIDOR_MIN_Z)
	_add_layered_wall_z("OfficeSouth", OFFICE_MIN_X, OFFICE_MAX_X, OFFICE_MAX_Z)
	_add_layered_wall_x("OfficeWest", CORRIDOR_MIN_Z, OFFICE_MAX_Z, OFFICE_MIN_X)
	_add_layered_wall_x("OfficeEastNorth", CORRIDOR_MIN_Z, 17.70, OFFICE_MAX_X)
	_add_layered_wall_x("OfficeEastSouth", 19.30, OFFICE_MAX_Z, OFFICE_MAX_X)
	_add_solid("OfficeDoorHeader", Vector3(WALL_DEPTH, 1.9, 1.6), Vector3(OFFICE_MAX_X, 3.45, 18.5), CREAM)
	for corner in [
		Vector3(OFFICE_MIN_X, 2.2, CORRIDOR_MIN_Z), Vector3(OFFICE_MIN_X, 2.2, OFFICE_MAX_Z),
		Vector3(OFFICE_MAX_X, 2.2, CORRIDOR_MIN_Z), Vector3(OFFICE_MAX_X, 2.2, OFFICE_MAX_Z),
		Vector3(OFFICE_MAX_X, 2.2, 17.70), Vector3(OFFICE_MAX_X, 2.2, 19.30),
	]:
		_add_pillar(corner)


func _build_doors() -> void:
	var room_two := Node3D.new()
	room_two.name = "Room02Access"
	room_two.set_script(ProgressionShutterScript)
	room_two.set("access_id", &"room_02")
	# Both auditoria beyond the right wing wait for the manager office and
	# corridor to reach 95 %, after the initial room has opened the wing.
	var room_two_requirements: Array[StringName] = [&"room_01", &"left_corridor", &"manager_office"]
	room_two.set("required_clean_areas", room_two_requirements)
	# The shutter's 0.36 m-deep housing must sit in front of the wall, not
	# intersect it when the slats are raised.
	room_two.position = Vector3(9.0, 0.0, CORRIDOR_MAX_Z - 0.36)
	room_two.rotation_degrees.y = 180.0
	room_two.add_child(DoorCatalog.instantiate_for(&"room_02"))
	add_child(room_two)

	var office := Node3D.new()
	office.name = "ManagerOfficeAccess"
	office.set_script(ProgressionShutterScript)
	office.set("access_id", &"manager_office")
	office.set("unlock_with_room_one", true)
	office.position = Vector3(OFFICE_MAX_X + 0.36, 0.0, 18.5)
	office.rotation_degrees.y = 90.0
	office.add_child(DoorCatalog.instantiate_for(&"manager_office", true))
	add_child(office)


func _build_room_zones() -> void:
	# Reassign Room 1 when crossing back through its existing exit. Without this
	# volume the player retained left_corridor, which also filtered Ojo incorrectly.
	_add_room_zone("Room01ReturnZone", &"room_01", Vector3(3.0, 3.0, 2.2), Vector3(9.0, 1.5, 13.65))
	_add_room_zone("LeftCorridorZone", &"left_corridor", Vector3(23.0, 3.0, 9.4), Vector3(-0.5, 1.5, 20.0))
	_add_room_zone("ManagerOfficeZone", &"manager_office", Vector3(6.4, 3.0, 9.4), Vector3(-15.5, 1.5, 20.0))


func _build_lighting() -> void:
	# -8.0 is the Room 3 doorway: a lamp there floated across the opening.
	for light_x in [-1.0, 5.4]:
		_add_wall_light(Vector3(light_x, 2.2, 24.82), 0.0)
	var corridor_light := OmniLight3D.new()
	corridor_light.name = "CorridorWarmLight"
	corridor_light.position = Vector3(-1.0, 3.25, 20.0)
	corridor_light.light_color = Color("ffc477")
	corridor_light.light_energy = 1.25
	corridor_light.omni_range = 12.5
	add_child(corridor_light)
	var office_light := OmniLight3D.new()
	office_light.name = "OfficeWarmLight"
	office_light.position = Vector3(-15.5, 3.15, 20.0)
	office_light.light_color = Color("ffd29a")
	office_light.light_energy = 1.05
	office_light.omni_range = 7.0
	add_child(office_light)


func _build_corridor_decorations() -> void:
	# Only props explicitly present in the supplied decoration set are used.
	_add_arcade_machine(
		"FutureArcadeMachine", ARCADE_SCENE, Vector3(-10.75, 0.0, 23.95),
		Vector3.ONE * 1.90, Vector3(0.0, 180.0, 0.0), Vector3(1.04, 1.90, 1.16)
	)
	_add_static_decoration(
		"CorridorVendingMachine", VENDING_SCENE, Vector3(3.40, 0.0, 15.89),
		Vector3.ONE * 2.0, Vector3.ZERO, Vector3(1.05, 2.0, 1.15)
	)
	_add_static_decoration(
		"Room01EntryPosterFrame", ENTRY_POSTER_SCENE, Vector3(6.20, 0.0, 15.68),
		Vector3.ONE * 2.0, Vector3.ZERO, Vector3(1.50, 2.40, 0.55)
	)
	var room_one_poster := MeshInstance3D.new()
	room_one_poster.name = "Room01EntryPosterDisplay"
	var room_one_quad := QuadMesh.new()
	room_one_quad.size = Vector2(1.27, 1.90)
	room_one_poster.mesh = room_one_quad
	room_one_poster.material_override = PosterMaterialScript.create_for_room(1)
	room_one_poster.position = Vector3(6.20, 1.34, 15.78)
	add_child(room_one_poster)
	# Rest area against the future Room 2 wall. Both supplied props stay clear
	# of the shutter and face the corridor.
	_add_static_decoration(
		"Room02WallArmchair", ARMCHAIR_SCENE, Vector3(0.0, 0.0, 24.12),
		Vector3.ONE * 1.15, Vector3(0.0, 180.0, 0.0), Vector3(1.65, 1.25, 1.35)
	)
	_add_static_decoration(
		"Room02WallPotatoDisplay", POTATO_DISPLAY_SCENE, Vector3(4.25, 0.0, 24.25),
		Vector3.ONE * 1.85, Vector3(0.0, 180.0, 0.0), Vector3(1.35, 2.05, 0.90)
	)
	var table_center := Vector3(-5.25, 0.0, 18.35)
	_add_static_decoration(
		"CorridorRoundTable", ROUND_TABLE_SCENE, table_center,
		Vector3.ONE * 0.92, Vector3.ZERO, Vector3(1.45, 0.92, 1.45)
	)
	for stool_index in 5:
		var angle := -PI * 0.5 + TAU * float(stool_index) / 5.0
		var stool_position := table_center + Vector3(cos(angle), 0.0, sin(angle)) * 1.28
		_add_static_decoration(
			"CorridorStool_%02d" % (stool_index + 1), STOOL_SCENE,
			stool_position, Vector3.ONE * 0.88,
			Vector3(0.0, rad_to_deg(angle + PI), 0.0), Vector3(0.56, 0.88, 0.57)
		)


func _add_static_decoration(
	name_value: String, scene: PackedScene, at: Vector3, model_scale: Vector3,
	model_rotation: Vector3, collision_size: Vector3
) -> void:
	var body := StaticBody3D.new()
	body.name = name_value
	body.position = at
	var visual := scene.instantiate() as Node3D
	visual.name = "Model"
	visual.scale = model_scale
	visual.rotation_degrees = model_rotation
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = collision_size
	collision.shape = shape
	collision.position.y = collision_size.y * 0.5
	body.add_child(collision)
	add_child(body)


func _add_arcade_machine(
	node_name: String, scene: PackedScene, at: Vector3, model_scale: Vector3,
	model_rotation: Vector3, collision_size: Vector3
) -> void:
	var machine := StaticBody3D.new()
	machine.name = node_name
	machine.set_script(ArcadeMachineScript)
	machine.set("model_scene", scene)
	machine.set("model_scale", model_scale)
	machine.set("model_rotation_degrees", model_rotation)
	machine.set("interaction_size", collision_size)
	machine.position = at
	add_child(machine)


func _build_office_contents() -> void:
	var lever_box := MANAGER_LEVER_BOX_SCENE.instantiate() as Node3D
	lever_box.position = Vector3(-15.5, 1.25, 24.52)
	lever_box.rotation_degrees.y = 180.0
	add_child(lever_box)
	var table_visual := TABLE_SCENE.instantiate() as Node3D
	table_visual.name = "ManagerDeskModel"
	table_visual.position = Vector3(-16.65, 0.0, 18.5)
	table_visual.scale = Vector3(1.80, 0.80, 1.45)
	add_child(table_visual)
	var table_collision := StaticBody3D.new()
	table_collision.name = "ManagerDeskCollision"
	table_collision.position = Vector3(-16.65, 0.40, 18.5)
	var table_shape_node := CollisionShape3D.new()
	var table_shape := BoxShape3D.new()
	table_shape.size = Vector3(1.64, 0.80, 1.32)
	table_shape_node.shape = table_shape
	table_collision.add_child(table_shape_node)
	add_child(table_collision)

	_add_tool_display(&"hand_vacuum", VACUUM_SCENE, Vector3(-16.65, 0.82, 18.10), Vector3(0, 20, 0), Vector3(1.0, 0.55, 0.65))
	_add_tool_display(&"broom", BROOM_SCENE, Vector3(-17.8, 0.04, 18.92), Vector3(0, 195, -8), Vector3(0.62, 1.35, 0.72))
	var hammer_pickup := Node3D.new()
	hammer_pickup.name = "ManagerHammerPickup"
	hammer_pickup.set_script(HammerPickupScript)
	# Head on the floor, shaft diagonally resting against the office wall.
	hammer_pickup.position = Vector3(-18.65, 1.02, 22.10)
	hammer_pickup.rotation_degrees = Vector3(24.0, 0.0, 225.0)
	hammer_pickup.add_child(HAMMER_SCENE.instantiate())
	var hammer_body := StaticBody3D.new()
	hammer_body.name = "InteractionBody"
	var hammer_shape := CollisionShape3D.new()
	hammer_shape.name = "CollisionShape3D"
	hammer_shape.shape = BoxShape3D.new()
	(hammer_shape.shape as BoxShape3D).size = Vector3(0.75, 1.35, 0.55)
	hammer_shape.position.y = 0.65
	hammer_body.add_child(hammer_shape)
	hammer_pickup.add_child(hammer_body)
	add_child(hammer_pickup)

	var lost_found := LOST_FOUND_SCENE.instantiate() as Node3D
	lost_found.name = "ManagerLostFoundBox"
	lost_found.position = Vector3(-18.10, 0.0, 20.75)
	lost_found.rotation_degrees.y = -35.0
	add_child(lost_found)


func _add_tool_display(id: StringName, model: PackedScene, at: Vector3, rotation: Vector3, interaction_size: Vector3) -> void:
	var display := Node3D.new()
	display.name = "%sDisplay" % String(id).to_pascal_case()
	display.set_script(ToolDisplayScript)
	display.set("tool_id", id)
	display.set("model_scene", model)
	display.set("visual_rotation_degrees", rotation)
	display.set("interaction_size", interaction_size)
	display.position = at
	add_child(display)


func _spawn_fixed_trash() -> void:
	var manager := get_tree().get_first_node_in_group("gameplay_manager")
	if manager == null:
		push_error("LeftWingBlockout requires the existing GameplayManager")
		return
	# Save ID left_corridor belongs to the original, visibly RIGHT corridor.
	var small: Array[Vector3] = []
	var large: Array[Vector3] = []
	for index in 105: small.append(_corridor_small_position(index))
	for index in 15: large.append(_corridor_large_position(index))
	manager.get_dense_registry().populate(&"left_corridor",small,large,self)
	small = []
	large = []
	for index in 16: small.append(_office_small_position(index))
	for index in 2: large.append(_office_large_position(index))
	manager.get_dense_registry().populate(&"manager_office",small,large,self)


func _spawn_authored_trash(room_id: StringName, large: bool, index: int, at: Vector3, manager: Node) -> void:
	var size_key := "large" if large else "small"
	var stable_id := "%s:%s:%03d" % [String(room_id), size_key, index + 1]
	if manager.is_world_trash_collected(stable_id):
		return
	var definitions := LARGE_TRASH if large else SMALL_TRASH
	var item := TRASH_SCENE.instantiate()
	item.name = "Fixed_%s_%s_%03d" % [String(room_id), size_key, index + 1]
	item.definition = definitions[index % definitions.size()]
	item.room_id = room_id
	item.world_item_id = stable_id
	item.position = at
	item.rotation = Vector3(0.0, deg_to_rad(float((index * 47) % 360)), 0.0)
	add_child(item)
	var player := get_tree().get_first_node_in_group("player") as PhysicsBody3D
	if player:
		item.add_collision_exception_with(player)
		player.add_collision_exception_with(item)


func _corridor_small_position(index: int) -> Vector3:
	var authored := CORRIDOR_SMALL_POSITIONS[index % CORRIDOR_SMALL_POSITIONS.size()]
	return authored if index < CORRIDOR_SMALL_POSITIONS.size() else authored + Vector3(0.0, 0.0, 0.55)


func _corridor_large_position(index: int) -> Vector3:
	var authored := CORRIDOR_LARGE_POSITIONS[index % CORRIDOR_LARGE_POSITIONS.size()]
	return authored if index < CORRIDOR_LARGE_POSITIONS.size() else authored + Vector3(0.0, 0.0, 0.55)


func _office_small_position(index: int) -> Vector3:
	return OFFICE_SMALL_POSITIONS[index]


func _office_large_position(index: int) -> Vector3:
	return OFFICE_LARGE_POSITIONS[index]


func _add_layered_wall_z(node_name: String, start_x: float, end_x: float, z: float) -> void:
	var width := end_x - start_x
	var center_x := (start_x + end_x) * 0.5
	var join_y := WALL_RED_TOP - 0.02
	_add_solid(node_name + "Lower", Vector3(width, join_y, WALL_DEPTH), Vector3(center_x, join_y * 0.5, z), WINE)
	_add_solid(node_name + "Upper", Vector3(width, WALL_HEIGHT - join_y, WALL_DEPTH), Vector3(center_x, (join_y + WALL_HEIGHT) * 0.5, z), CREAM)
	_add_trim(Vector3(width, 0.16, 0.34), Vector3(center_x, WALL_RED_TOP, z - 0.02))
	_add_trim(Vector3(width, 0.28, 0.34), Vector3(center_x, 0.14, z - 0.02))


func _add_layered_wall_x(node_name: String, start_z: float, end_z: float, x: float) -> void:
	var depth := end_z - start_z
	var center_z := (start_z + end_z) * 0.5
	var join_y := WALL_RED_TOP - 0.02
	_add_solid(node_name + "Lower", Vector3(WALL_DEPTH, join_y, depth), Vector3(x, join_y * 0.5, center_z), WINE)
	_add_solid(node_name + "Upper", Vector3(WALL_DEPTH, WALL_HEIGHT - join_y, depth), Vector3(x, (join_y + WALL_HEIGHT) * 0.5, center_z), CREAM)
	_add_trim(Vector3(0.34, 0.16, depth), Vector3(x, WALL_RED_TOP, center_z))
	_add_trim(Vector3(0.34, 0.28, depth), Vector3(x, 0.14, center_z))


func _add_corridor_wall_skin_z(node_name: String, start_x: float, end_x: float, z: float) -> void:
	var width := end_x - start_x
	var center_x := (start_x + end_x) * 0.5
	var join_y := WALL_RED_TOP - 0.02
	_add_visual_box(node_name + "Lower", Vector3(width, join_y, 0.02), Vector3(center_x, join_y * 0.5, z), WINE)
	_add_visual_box(node_name + "Upper", Vector3(width, WALL_HEIGHT - join_y, 0.02), Vector3(center_x, (join_y + WALL_HEIGHT) * 0.5, z), CREAM)
	_add_visual_box(node_name + "MiddleTrim", Vector3(width, 0.16, 0.04), Vector3(center_x, WALL_RED_TOP, z + 0.015), CHARCOAL)
	_add_visual_box(node_name + "BaseTrim", Vector3(width, 0.28, 0.04), Vector3(center_x, 0.14, z + 0.015), CHARCOAL)


func _add_pillar(at: Vector3) -> void:
	_add_solid("Pillar", Vector3(0.42, WALL_HEIGHT, 0.42), at, CHARCOAL)


func _add_wall_light(at: Vector3, yaw: float) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "WarmWallLight"
	var box := BoxMesh.new()
	box.size = Vector3(0.16, 0.62, 0.08)
	box.material = WARM_LIGHT
	mesh.mesh = box
	mesh.position = at
	mesh.rotation_degrees.y = yaw
	add_child(mesh)


func _add_trim(size: Vector3, at: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "SharedTrim"
	var box := BoxMesh.new()
	box.size = size
	box.material = CHARCOAL
	mesh.mesh = box
	mesh.position = at
	add_child(mesh)


func _add_solid(node_name: String, size: Vector3, at: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _wall_material_for_size(material, size)
	visual.mesh = mesh
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body


func _add_visual_box(node_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _wall_material_for_size(material, size)
	visual.mesh = mesh
	visual.position = at
	add_child(visual)
	return visual


func _wall_material_for_size(material: Material, size: Vector3) -> Material:
	if material != WINE:
		return material
	# Room 1/2 use wine panels roughly 4.6 m wide. Repeat the same pattern on
	# longer corridor spans instead of stretching one panel across the wall.
	var horizontal_span := maxf(size.x, size.z)
	if horizontal_span <= 4.6:
		return material
	var tiled := WINE.duplicate() as StandardMaterial3D
	tiled.uv1_scale = Vector3(horizontal_span / 4.6, 1.0, 1.0)
	return tiled


func _add_room_zone(node_name: String, id: StringName, size: Vector3, at: Vector3) -> void:
	var zone := Area3D.new()
	zone.name = node_name
	zone.set_script(RoomZoneScript)
	zone.set("room_id", id)
	zone.position = at
	zone.collision_layer = 0
	zone.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	zone.add_child(collision)
	add_child(zone)
