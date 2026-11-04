class_name CinemaExpansionBlockout
extends Node3D

# World plan from the user's marked-up sketch: Manager -- right corridor --
# narrow vestibule -- left corridor -- future final room. Rooms 2/3 are north
# of the corridor strip; Rooms 1/4 are south. No final-room interior exists yet.
const DoorCatalog := preload("res://resources/doors/cinema_door_catalog.gd")
const ROLLER_SHUTTER_SCENE := preload("res://scenes/gameplay/roller_shutter_door.tscn")
const RoomZoneScript := preload("res://scripts/room_zone.gd")
const FLOOR := preload("res://resources/materials/corridor_worn_floor.tres")
const CREAM := preload("res://resources/materials/corridor_aged_plaster.tres")
const WINE := preload("res://resources/materials/cinema_panel_wine.tres")
const DARK := preload("res://resources/materials/cinema_charcoal.tres")
const TRASH := preload("res://scenes/gameplay/trash_item.tscn")
const ARCADE := preload("res://assets/models/source/decoration/MaquinaRecreativa.glb")
const ARMCHAIR := preload("res://assets/models/source/decoration/Sillón.glb")
const ROUND_TABLE := preload("res://assets/models/source/decoration/MesaRedonda.glb")
const VENDING := preload("res://assets/models/source/decoration/MaquinaExpendedora.glb")
const TICKET_MACHINE := preload("res://assets/models/source/decoration/MaquinaTiketsEntrada.glb")
const POSTER_FRAME := preload("res://assets/models/source/general/cartelPeliculas.glb")
const STOOL := preload("res://assets/models/source/decoration/Taburete.glb")
const PosterMaterialScript := preload("res://scripts/cinema_poster_material.gd")
const BIN := preload("res://scenes/gameplay/trash_bin.tscn")
const FINAL_BRICK_BARRIER := preload("res://assets/pipeline/props/final_room_brick_barrier.glb")
const FinalWallBreakScript := preload("res://scripts/final_wall_break.gd")
const ArcadeMachineScript := preload("res://scripts/arcade_machine.gd")
const SHUTTER_OPEN_SOUND := preload("res://assets/audio/sfx/doors/lobby_shutter_open_01.wav")
const SMALL := [preload("res://resources/trash/ticket.tres"), preload("res://resources/trash/napkin.tres"), preload("res://resources/trash/cup.tres"), preload("res://resources/trash/can.tres"), preload("res://resources/trash/straw.tres"), preload("res://resources/trash/popcorn.tres")]
const LARGE := [preload("res://resources/trash/bottle.tres"), preload("res://resources/trash/bucket.tres")]
const REQUIRED_FOR_LOBBY: Array[StringName] = [&"room_01", &"left_corridor", &"manager_office", &"room_02", &"room_03"]
# Entrance, ticket area, vestibule and popcorn share the same built zone.
# Its 555 objects are slightly denser than the proposed 510-object vestibule,
# without incorrectly adding both rows of the planning table together.
const LOBBY_SMALL := 520
const LOBBY_LARGE := 35
# Save ID right_corridor belongs to the visibly LEFT corridor.
const RIGHT_SMALL := 80
const RIGHT_LARGE := 10
const WALL_RED_TOP := 2.55

var _manager: GameplayManager
var _lobby_shutter: RollerShutterDoor
var _right_shutter: RollerShutterDoor
var _room_three_shutter: RollerShutterDoor
var _room_four_shutter: RollerShutterDoor
var _lobby_gate_audio: AudioStreamPlayer3D
var _right_gate_audio: AudioStreamPlayer3D
var _lobby_trash: Array[Node3D] = []
var _visibility_elapsed := 0.0


func _ready() -> void:
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	_build_lobby()
	_build_left_corridor()
	_build_left_corridor_bin()
	_build_zones()
	_build_lights()
	_build_shutters()
	if _manager:
		_manager.state_changed.connect(_refresh_unlocks)
	call_deferred("_spawn_trash_and_refresh")


func _process(delta: float) -> void:
	_visibility_elapsed += delta
	if _visibility_elapsed < 0.25 or _lobby_trash.is_empty():
		return
	_visibility_elapsed = 0.0
	_update_lobby_trash_visibility()


func _update_lobby_trash_visibility() -> void:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player == null:
		return
	var center := player.global_position
	var visible_distance_squared := 324.0 if player.get_current_room_id() == &"lobby" else 100.0
	for item in _lobby_trash:
		if is_instance_valid(item):
			item.visible = item.global_position.distance_squared_to(center) <= visible_distance_squared


func _build_lobby() -> void:
	# Straight, narrow rectangle between the two corridor doors. Its southern
	# wall stays 0.5 m clear of Room 1, avoiding intersecting room shells.
	# Pull the west edge 0.4 m clear of Room 1's side shell.
	_solid("LobbyFloor", Vector3(14.95, -0.1, 5.0), Vector3(7.1, 0.2, 40.0), FLOOR)
	_solid("LobbyCeiling", Vector3(14.95, 4.5, 5.0), Vector3(7.1, 0.2, 40.0), DARK)
	_solid("LobbyRightGateThreshold", Vector3(11.2, -0.1, 18.5), Vector3(0.4, 0.2, 3.0), FLOOR)
	# Stop the end wall flush with Room 2's existing cap, not inside its door.
	_wall_z("LobbyNorth", 11.12, 18.5, 24.75)
	_wall_z("LobbySouthWest", 11.8, 13.25, -15.0)
	_wall_z("LobbySouthEast", 16.25, 18.5, -15.0)
	_solid("LobbyEntranceHeader", Vector3(14.75, 3.6, -15.0), Vector3(3.0, 1.6, 0.24), CREAM)
	_wall_x("LobbyRoom01Side", -15.0, 15.0, 11.8)
	_wall_z("LobbyRoom01Corner", 11.0, 11.8, 15.0)
	# The right corridor owns the opposite wall at x=11 and its 3 m opening.
	_wall_x("LobbyLeftSouth", -15.0, 17.0, 18.5)
	_wall_x("LobbyLeftNorth", 20.0, 25.0, 18.5)
	_solid("LeftGateHeader", Vector3(18.5, 3.6, 18.5), Vector3(0.24, 1.6, 3.0), CREAM)
	_solid("LobbyCeilingBeamA", Vector3(14.95, 4.22, -4.0), Vector3(7.1, 0.25, 0.3), DARK, false)
	_solid("LobbyCeilingBeamB", Vector3(14.95, 4.22, 12.0), Vector3(7.1, 0.25, 0.3), DARK, false)
	_door_trim_x("LobbyRightGate", 11.16, 18.5)
	_door_trim_x("LobbyLeftGate", 18.34, 18.5)
	_door_trim_z("LobbyEntrance", 14.75, -14.84)


func _build_left_corridor() -> void:
	# One rectangular strip. Room 2 supplies the north wall and Room 4 supplies
	# the south wall; only short end caps avoid duplicated wall meshes.
	_solid("LeftCorridorFloor", Vector3(27.7, -0.1, 20.0), Vector3(18.4, 0.2, 10.0), FLOOR)
	_solid("LeftCorridorCeiling", Vector3(27.7, 4.5, 20.0), Vector3(18.4, 0.2, 10.0), DARK)
	# A short safe threshold remains behind the breakable wall until the final
	# auditorium is authored; the player cannot step straight into the void.
	_solid("FinalRoomThresholdFloor", Vector3(38.15, -0.1, 20.0), Vector3(2.6, 0.2, 6.0), FLOOR)
	_wall_z("FinalRoomThresholdSouth", 37.02, 39.28, 17.0)
	_wall_z("FinalRoomThresholdNorth", 37.02, 39.28, 23.0)
	_wall_x("FinalRoomTemporaryBackstop", 17.0, 23.0, 39.40)
	_wall_z("LeftCorridorNorthCap", 34.7, 36.9, 25.0)
	_wall_z("LeftCorridorSouthCap", 18.5, 18.9, 15.0)
	# The vestibule's east wall reaches Room 2; Sala 4 owns its own header.
	_door_trim_x("LeftCorridorGate", 18.66, 18.5)
	_wall_x("FinalWallSouth", 15.0, 17.0, 36.9)
	_wall_x("FinalWallNorth", 23.0, 25.0, 36.9)
	# The brick piece is 2.8 m high; continue every part of the end wall
	# to the auditorium wall height instead of ending at corridor-ceiling level.
	_solid("FinalWallSouthUpper", Vector3(36.9, 5.7, 16.0), Vector3(0.24, 2.6, 2.0), CREAM)
	_solid("FinalWallNorthUpper", Vector3(36.9, 5.7, 24.0), Vector3(0.24, 2.6, 2.0), CREAM)
	_solid("FinalBarrierHeader", Vector3(36.9, 3.65, 20.0), Vector3(0.24, 1.5, 6.0), CREAM)
	_solid("FinalBarrierUpper", Vector3(36.9, 5.7, 20.0), Vector3(0.24, 2.6, 6.0), CREAM)
	var barrier := StaticBody3D.new()
	barrier.name = "FutureFinalRoomBrickBarrier"
	barrier.position = Vector3(36.85, 0.0, 20.0)
	barrier.set_script(FinalWallBreakScript)
	var brick_visual := FINAL_BRICK_BARRIER.instantiate() as Node3D
	brick_visual.name = "BrickVisual"
	brick_visual.rotation_degrees.y = 90.0
	barrier.add_child(brick_visual)
	var barrier_shape := BoxShape3D.new()
	barrier_shape.size = Vector3(0.35, 2.9, 6.0)
	var barrier_collision := CollisionShape3D.new()
	barrier_collision.name = "CollisionShape3D"
	barrier_collision.position.y = 1.45
	barrier_collision.shape = barrier_shape
	barrier.add_child(barrier_collision)
	add_child(barrier)
	# Reuse the first cabinet's interaction/collision model and discovery sensor.
	var arcade := StaticBody3D.new()
	arcade.name = "LeftCorridorArcade"
	arcade.set_script(ArcadeMachineScript)
	arcade.set("model_scene", ARCADE)
	arcade.set("model_scale", Vector3.ONE * 1.9)
	arcade.set("model_rotation_degrees", Vector3(0.0, 180.0, 0.0))
	arcade.set("interaction_size", Vector3(1.04, 1.9, 1.16))
	arcade.set("arcade_index", 2)
	arcade.position = Vector3(21.5, 0.0, 24.05)
	add_child(arcade)


func _build_lobby_props() -> void:
	var island_carpet := StandardMaterial3D.new()
	island_carpet.albedo_color = Color("543137")
	island_carpet.roughness = 1.0
	_solid("LobbyTicketIslandRug", Vector3(-33.0, 0.014, 9.3), Vector3(11.8, 0.025, 5.6), island_carpet, false)
	_prop("LobbyTicketMachine", TICKET_MACHINE, Vector3(-33.0, 0.0, 10.2), 2.0, Vector3(1.7, 2.15, 1.35), 180.0)
	_lobby_poster("LobbyPosterAdventure", Vector3(-37.1, 0.0, 9.7), 1)
	_lobby_poster("LobbyPosterRomance", Vector3(-28.9, 0.0, 9.7), 2)
	_prop("LobbyWaitingSeatA", ARMCHAIR, Vector3(-41.2, 0.0, 18.5), 1.15, Vector3(1.65, 1.25, 1.35), 90.0)
	_prop("LobbyWaitingSeatB", ARMCHAIR, Vector3(-41.2, 0.0, 22.0), 1.15, Vector3(1.65, 1.25, 1.35), 90.0)
	_prop("LobbyRoundTable", ROUND_TABLE, Vector3(-39.0, 0.0, 20.2), 0.92, Vector3(1.45, 0.92, 1.45))
	_prop("LobbyVending", VENDING, Vector3(-20.5, 0.0, 1.5), 2.0, Vector3(1.05, 2.0, 1.15), 90.0)
	_prop("LobbyCafeTable", ROUND_TABLE, Vector3(-23.7, 0.0, 17.0), 0.92, Vector3(1.45, 0.92, 1.45))
	_prop("LobbyCafeStoolA", STOOL, Vector3(-25.2, 0.0, 17.0), 0.88, Vector3(0.56, 0.88, 0.57))
	_prop("LobbyCafeStoolB", STOOL, Vector3(-22.2, 0.0, 17.0), 0.88, Vector3(0.56, 0.88, 0.57))
	_prop("LobbyArcadeReserved", ARCADE, Vector3(-43.3, 0.0, -2.7), 1.9, Vector3(1.04, 1.9, 1.16), 90.0)
	# The second cabinet reserves a small arcade cluster, without gameplay duplication.
	_prop("LobbyArcadeReservedB", ARCADE, Vector3(-43.3, 0.0, 0.2), 1.9, Vector3(1.04, 1.9, 1.16), 90.0)


func _build_left_corridor_bin() -> void:
	# Place the vestibule's spare bin beside the arcade without blocking its
	# front interaction area or the nearby shutter.
	var bin := BIN.instantiate() as Node3D
	bin.name = "LeftCorridorTrashBin"
	bin.position = Vector3(23.4, 0.0, 23.85)
	bin.rotation.y = PI
	bin.set("room_id", &"right_corridor")
	add_child(bin)


func _lobby_poster(label: String, at: Vector3, room_number: int) -> void:
	var stand := StaticBody3D.new()
	stand.name = label
	stand.position = at
	stand.rotation.y = PI
	var frame := POSTER_FRAME.instantiate() as Node3D
	frame.name = "Frame"
	frame.scale = Vector3.ONE * 2.0
	stand.add_child(frame)
	var image := MeshInstance3D.new()
	image.name = "AgedMovieImage"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.27, 1.9)
	image.mesh = quad
	image.material_override = PosterMaterialScript.create_for_room(room_number)
	image.position = Vector3(0.0, 1.34, 0.10)
	stand.add_child(image)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 2.4, 0.55)
	var collider := CollisionShape3D.new()
	collider.position.y = 1.2
	collider.shape = shape
	stand.add_child(collider)
	add_child(stand)


func _build_zones() -> void:
	# Save IDs are intentionally stable: left_corridor is the original physical
	# right corridor, and right_corridor is the new physical left wing.
	_zone("LobbyZone", &"lobby", Vector3(14.75, 1.5, 5.0), Vector3(6.9, 3.0, 39.4))
	_zone("LeftCorridorZone", &"right_corridor", Vector3(27.7, 1.5, 20.0), Vector3(17.8, 3.0, 9.4))


func _build_lights() -> void:
	for z in [-9.0, 2.0, 12.0, 22.0]:
		_light("LobbyWarm_%s" % z, Vector3(14.75, 3.7, z), 1.5, 10.0)
	_light("LeftCorridorWarm", Vector3(28.5, 3.5, 20.0), 1.3, 13.0)


func _build_shutters() -> void:
	var entrance := ROLLER_SHUTTER_SCENE.instantiate() as RollerShutterDoor
	entrance.name = "LobbyMainEntranceShutter"
	entrance.opening_width = 3.0
	entrance.position = Vector3(14.75, 0.0, -14.64)
	add_child(entrance)
	_lobby_shutter = DoorCatalog.instantiate_for(&"left_corridor_vestibule")
	_lobby_shutter.name = "LobbyDoubleShutter"
	_lobby_shutter.opening_width = 3.0
	_lobby_shutter.position = Vector3(11.36, 0.0, 18.5)
	_lobby_shutter.rotation_degrees.y = 90.0
	add_child(_lobby_shutter)
	_right_shutter = DoorCatalog.instantiate_for(&"room_04")
	_right_shutter.name = "LeftCorridorDoubleShutter"
	_right_shutter.opening_width = 3.0
	_right_shutter.position = Vector3(18.14, 0.0, 18.5)
	_right_shutter.rotation_degrees.y = 90.0
	add_child(_right_shutter)
	_lobby_gate_audio = _gate_audio("LobbyGateOpeningSound", Vector3(11.0, 1.7, 18.5))
	_right_gate_audio = _gate_audio("LeftGateOpeningSound", Vector3(17.0, 1.7, 18.5))
	_room_three_shutter = DoorCatalog.instantiate_for(&"room_03")
	_room_three_shutter.name = "Room03Door"
	_room_three_shutter.position = Vector3(-8.0, 0.0, 24.64)
	_room_three_shutter.rotation_degrees.y = 180.0
	add_child(_room_three_shutter)
	_room_four_shutter = DoorCatalog.instantiate_for(&"room_04")
	_room_four_shutter.name = "Room04Door"
	_room_four_shutter.position = Vector3(27.9, 0.0, 15.36)
	add_child(_room_four_shutter)


func _spawn_trash_and_refresh() -> void:
	if _manager == null:
		push_error("Expansion requires GameplayManager")
		return
	var small: Array[Vector3] = []
	var large: Array[Vector3] = []
	for i in LOBBY_SMALL:
		var x := 12.1 + float((i * 37) % 55) * 0.1
		var z := -12.0 + float((i * 53) % 350) * 0.1
		small.append(Vector3(x,0.24,z))
	for i in LOBBY_LARGE:
		large.append(Vector3(13.0 if i % 2 == 0 else 16.5, 0.36, -9.0 + float(floori(float(i) / 2.0)) * 1.82))
	_manager.get_dense_registry().populate(&"lobby",small,large,self)
	small = []
	large = []
	for i in RIGHT_SMALL:
		var x := 20.0 + float((i * 37) % 155) * 0.1
		var z := 16.4 + float((i * 17) % 70) * 0.1
		small.append(Vector3(x,0.24,z))
	for i in RIGHT_LARGE:
		large.append(Vector3(20.6 + float((i * 13) % 16), 0.36, 17.2 if i % 2 == 0 else 22.7))
	_manager.get_dense_registry().populate(&"right_corridor",small,large,self)
	_refresh_unlocks()


func _refresh_unlocks() -> void:
	if _manager == null or _lobby_shutter == null or _right_shutter == null or _room_three_shutter == null or _room_four_shutter == null:
		return
	if _manager.are_required_areas_clean([&"room_01", &"left_corridor", &"manager_office"], 95):
		_room_three_shutter.open_door()
	if not _manager.lobby_unlocked and _manager.are_required_areas_clean(REQUIRED_FOR_LOBBY, 95):
		_manager.unlock_lobby()
	if _manager.lobby_unlocked:
		if not _lobby_shutter.is_open:
			_lobby_gate_audio.play()
		_lobby_shutter.open_door()
	if not _manager.right_corridor_unlocked and _manager.lobby_unlocked and _manager.are_required_areas_clean([&"lobby"], 95):
		_manager.unlock_right_corridor()
	if _manager.right_corridor_unlocked:
		if not _right_shutter.is_open:
			_right_gate_audio.play()
		_right_shutter.open_door()
		_room_four_shutter.open_door()


func _gate_audio(label: String, at: Vector3) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = label
	player.stream = SHUTTER_OPEN_SOUND
	player.bus = &"World"
	player.volume_db = -12.0
	player.max_distance = 18.0
	player.position = at
	add_child(player)
	return player


func _spawn_item(room_id: StringName, large: bool, index: int, at: Vector3) -> void:
	var stable_id := "%s:%s:%03d" % [room_id, "large" if large else "small", index + 1]
	if _manager.is_world_trash_collected(stable_id):
		return
	var pool := LARGE if large else SMALL
	var item := TRASH.instantiate() as RigidBody3D
	item.name = "ExpansionTrash_%s_%03d" % [room_id, index + 1]
	item.definition = pool[index % pool.size()]
	item.room_id = room_id
	item.world_item_id = stable_id
	item.position = at
	item.rotation.y = deg_to_rad(float((index * 47) % 360))
	add_child(item)
	if room_id == &"lobby":
		# In the long, narrow vestibule, hide distant trash visuals while keeping
		# all items and collisions. Godot's visibility range does not cull these
		# imported multi-mesh items reliably with the Compatibility renderer.
		_lobby_trash.append(item)
	var player := get_tree().get_first_node_in_group("player") as PhysicsBody3D
	if player:
		item.add_collision_exception_with(player)
		player.add_collision_exception_with(item)
	if room_id == &"lobby":
		_update_lobby_trash_visibility()


func _zone(label: String, room_id: StringName, at: Vector3, dimensions: Vector3) -> void:
	var zone := Area3D.new()
	zone.name = label
	zone.set_script(RoomZoneScript)
	zone.set("room_id", room_id)
	zone.position = at
	zone.collision_layer = 0
	zone.collision_mask = 1
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var collision := CollisionShape3D.new()
	collision.shape = shape
	zone.add_child(collision)
	add_child(zone)


func _light(label: String, at: Vector3, energy: float, radius: float) -> void:
	var light := OmniLight3D.new()
	light.name = label
	light.position = at
	light.light_color = Color("ffd29a")
	light.light_energy = energy
	light.omni_range = radius
	add_child(light)


func _prop(label: String, scene: PackedScene, at: Vector3, model_scale: float, dimensions: Vector3, rotation_y := 0.0) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	var model := scene.instantiate() as Node3D
	model.scale = Vector3.ONE * model_scale
	model.rotation_degrees.y = rotation_y
	body.add_child(model)
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = dimensions.y * 0.5
	body.add_child(collision)
	add_child(body)


func _wall_z(label: String, x0: float, x1: float, z: float) -> void:
	_wall(label, Vector3((x0 + x1) * 0.5, 0.0, z), Vector3(x1 - x0, 0.0, 0.24))


func _wall_x(label: String, z0: float, z1: float, x: float) -> void:
	_wall(label, Vector3(x, 0.0, (z0 + z1) * 0.5), Vector3(0.24, 0.0, z1 - z0))


func _wall(label: String, at: Vector3, dimensions: Vector3) -> void:
	var along_x := dimensions.x > dimensions.z
	var span := dimensions.x if along_x else dimensions.z
	var bays := maxi(1, ceili(span / 4.6))
	var bay_length := span / float(bays)
	var join_y := WALL_RED_TOP - 0.02
	for i in bays:
		var offset := -span * 0.5 + (i + 0.5) * bay_length
		var bay_center := at + (Vector3(offset, 0.0, 0.0) if along_x else Vector3(0.0, 0.0, offset))
		var bay_size := Vector3(bay_length, 0.0, 0.24) if along_x else Vector3(0.24, 0.0, bay_length)
		_solid("%sLower_%02d" % [label, i], bay_center + Vector3(0.0, join_y * 0.5, 0.0), Vector3(bay_size.x, join_y, bay_size.z), WINE)
		_solid("%sUpper_%02d" % [label, i], bay_center + Vector3(0.0, (join_y + 4.4) * 0.5, 0.0), Vector3(bay_size.x, 4.4 - join_y, bay_size.z), CREAM)
		_solid("%sMoulding_%02d" % [label, i], bay_center + Vector3(0.0, WALL_RED_TOP, 0.0), Vector3(maxf(0.32, bay_size.x), 0.16, maxf(0.32, bay_size.z)), DARK, false)


func _door_trim_x(label: String, x: float, z: float) -> void:
	_solid(label + "SouthJamb", Vector3(x, 1.4, z - 1.5), Vector3(0.08, 2.8, 0.34), DARK, false)
	_solid(label + "NorthJamb", Vector3(x, 1.4, z + 1.5), Vector3(0.08, 2.8, 0.34), DARK, false)
	_solid(label + "Top", Vector3(x, 3.0, z), Vector3(0.08, 0.38, 3.34), DARK, false)


func _door_trim_z(label: String, x: float, z: float) -> void:
	_solid(label + "LeftJamb", Vector3(x - 1.5, 1.4, z), Vector3(0.34, 2.8, 0.08), DARK, false)
	_solid(label + "RightJamb", Vector3(x + 1.5, 1.4, z), Vector3(0.34, 2.8, 0.08), DARK, false)
	_solid(label + "Top", Vector3(x, 3.0, z), Vector3(3.34, 0.38, 0.08), DARK, false)


func _solid(label: String, at: Vector3, dimensions: Vector3, material: Material, collide := true) -> void:
	var root: Node3D = StaticBody3D.new() if collide else Node3D.new()
	root.name = label
	root.position = at
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	root.add_child(visual)
	if collide:
		var shape := BoxShape3D.new()
		shape.size = dimensions
		var collision := CollisionShape3D.new()
		collision.shape = shape
		root.add_child(collision)
	add_child(root)
