extends Node3D

## Sala 1 ampliada. La arquitectura usa mallas/colliders primitivos; los GLB
## importados son visuales con colisiones sencillas independientes.
const ROOM_WIDTH := 22.0
const ROOM_LENGTH := 30.0
const ROOM_HEIGHT := 7.0
const SIDE_BAY_COUNT := 6
const FRONT_Z := -15.0
const REAR_Z := 15.0
const SCREEN_Z := -14.72
const SEAT_SCALE := 1.55
const ROW_RISE := 0.13
const RAMP_FRONT_Z := -10.25
const RAMP_REAR_Z := 9.70
const RAMP_REAR_HEIGHT := 1.17
const SIDE_RAMP_WIDTH := 1.90
const SIDE_RAMP_CENTRE := 10.05
const STAIR_EDGE_XS := [-10.94, -9.245, -0.955, 0.955, 9.245, 10.94]
const AISLE_LIGHT_CENTRES := [-10.0925, 0.0, 10.0925]
const AISLE_LIGHT_WIDTHS := [1.46, 1.70, 1.46]
const TRASH_BLOCKER_LAYER := 4
const SEAT_PLAYER_COLLISION_LAYER := 8

const SEAT_STANDARD_SCENE := preload("res://assets/models/source/general/ButacaEstandar.glb")
const SEAT_FOLDED_SCENE := preload("res://assets/models/source/general/ButacaPlegada.glb")
const SEAT_BROKEN_SCENE := preload("res://assets/models/source/general/ButacaRota.glb")
const SEAT_INTERACTABLE_SCRIPT := preload("res://scripts/cinema_seat_interactable.gd")
# Deterministic 60% standard / 20% folded / 20% broken distribution.
# The five-seat cycle shifts across rows to avoid conspicuous blocks.
const SEAT_VARIANT_PATTERN: Array[PackedScene] = [
	SEAT_STANDARD_SCENE,
	SEAT_FOLDED_SCENE,
	SEAT_STANDARD_SCENE,
	SEAT_STANDARD_SCENE,
	SEAT_BROKEN_SCENE,
]
const SEAT_VARIANT_NAMES := ["ButacaEstandar", "ButacaPlegada", "ButacaEstandar", "ButacaEstandar", "ButacaRota"]
const WALL_SPEAKER_SCENE := preload("res://assets/models/source/room_1/AltavozParedes.glb")
const CINEMA_SPEAKER_SCENE := preload("res://assets/models/source/room_1/AltavozCine.glb")
const WALL_LIGHT_SCENE := preload("res://assets/models/source/room_1/LucesParedes.glb")
const WALL_GRILLE_SCENE := preload("res://assets/models/source/room_1/RejillaParedes.glb")
const EXIT_LIGHT_SCENE := preload("res://assets/models/source/room_1/luzPuertaSuperiorSalida.glb")
const EXIT_DOOR_SCENE := preload("res://scenes/gameplay/exit_door.tscn")

const MATERIALS := {
	"carpet": preload("res://resources/materials/cinema_carpet.tres"),
	"charcoal": preload("res://resources/materials/cinema_charcoal.tres"),
	"curtain": preload("res://resources/materials/cinema_curtain.tres"),
	"panel": preload("res://resources/materials/cinema_panel_wine.tres"),
	"screen": preload("res://resources/materials/cinema_screen.tres"),
	"stage": preload("res://resources/materials/cinema_stage.tres"),
	"step_light": preload("res://resources/materials/cinema_step_light.tres"),
}

var _seat_collision_shapes: Dictionary = {}
var _seat_cushion_shape: BoxShape3D
var _seat_visual_index := 0


func _ready() -> void:
	_build_shell()
	_build_screen_and_exit()
	_build_raked_seating()
	_build_room_one_props()


func _build_shell() -> void:
	_add_box("CarpetFloor", Vector3(0, -0.12, 0), Vector3(ROOM_WIDTH, 0.24, ROOM_LENGTH), "carpet")
	_add_box("Ceiling", Vector3(0, ROOM_HEIGHT + 0.12, 0), Vector3(ROOM_WIDTH, 0.24, ROOM_LENGTH), "charcoal")
	# Use wall-sized modules so the vertical panel texture keeps the same scale
	# and orientation as it has on the lateral walls.
	for panel_index in 5:
		var front_x := -8.8 + float(panel_index) * 4.4
		_add_box(
			"FrontWallPanel_%02d" % (panel_index + 1),
			Vector3(front_x, 3.5, FRONT_Z - 0.12),
			Vector3(4.4, ROOM_HEIGHT, 0.24),
			"panel"
		)

	# 3 m roller-shutter opening centred at x = 9 m.
	for panel_index in 4:
		var rear_x := -8.6875 + float(panel_index) * 4.625
		_add_box(
			"RearWallPanel_%02d" % (panel_index + 1),
			Vector3(rear_x, 3.5, REAR_Z + 0.12),
			Vector3(4.625, ROOM_HEIGHT, 0.24),
			"panel"
		)
	_add_box("RearWallRight", Vector3(10.75, 3.5, REAR_Z + 0.12), Vector3(0.5, ROOM_HEIGHT, 0.24), "panel")
	_add_box("RearWallHeader", Vector3(9, 4.9, REAR_Z + 0.12), Vector3(3.0, 4.2, 0.24), "panel")
	# Interior black trim meets the first rear divider (x=10.8), matching
	# the aligned doorway treatment in the other auditoria.
	_add_box("Room01DoorInteriorFrameLeft", Vector3(7.5, 1.4, REAR_Z - 0.18), Vector3(0.34, 2.8, 0.08), "charcoal", false)
	_add_box("Room01DoorInteriorFrameRight", Vector3(10.76, 1.4, REAR_Z - 0.18), Vector3(0.48, 2.8, 0.08), "charcoal", false)
	_add_box("Room01DoorInteriorFrameTop", Vector3(9.13, 3.0, REAR_Z - 0.18), Vector3(3.60, 0.38, 0.08), "charcoal", false)

	_build_side_wall(-1.0)
	_build_side_wall(1.0)
	for x in [-7.0, 7.0]:
		_add_box("ScreenSideColumn_%s" % x, Vector3(x, 3.5, FRONT_Z + 0.12), Vector3(0.44, ROOM_HEIGHT, 0.50), "charcoal")
	# Rear columns coincide with the wall modules; the shutter owns its rails.
	for x in [-10.8, -6.375, -1.75, 2.875, 10.8]:
		_add_box("RearPillar_%s" % x, Vector3(x, 3.5, REAR_Z - 0.15), Vector3(0.34, ROOM_HEIGHT, 0.5), "charcoal")


func _build_side_wall(side: float) -> void:
	var x := side * 11.12
	var bay_length := ROOM_LENGTH / float(SIDE_BAY_COUNT)
	for bay in SIDE_BAY_COUNT:
		var z := FRONT_Z + (bay + 0.5) * bay_length
		# Sala 1 is the only auditorium with wine-red walls from floor to ceiling.
		_add_box("WallPanel_%s_%02d" % [side, bay], Vector3(x, ROOM_HEIGHT * 0.5, z), Vector3(0.24, ROOM_HEIGHT, bay_length), "panel")
	for boundary in SIDE_BAY_COUNT + 1:
		_add_box("WallPillar_%s_%02d" % [side, boundary], Vector3(x, 3.5, FRONT_Z + boundary * bay_length), Vector3(0.40, ROOM_HEIGHT, 0.28), "charcoal")


func _build_screen_and_exit() -> void:
	_add_box("Screen", Vector3(0, 3.55, SCREEN_Z), Vector3(12, 5, 0.10), "screen")
	# Four black beams frame the screen without crossing its projection surface.
	_add_box("ScreenBeamTop", Vector3(0, 6.15, SCREEN_Z + 0.05), Vector3(12.75, 0.28, 0.26), "charcoal", false)
	_add_box("ScreenBeamBottom", Vector3(0, 0.95, SCREEN_Z + 0.05), Vector3(12.75, 0.28, 0.26), "charcoal", false)
	_add_box("ScreenBeamLeft", Vector3(-6.24, 3.55, SCREEN_Z + 0.05), Vector3(0.28, 5.48, 0.26), "charcoal", false)
	_add_box("ScreenBeamRight", Vector3(6.24, 3.55, SCREEN_Z + 0.05), Vector3(0.28, 5.48, 0.26), "charcoal", false)

	var exit_door := EXIT_DOOR_SCENE.instantiate() as Node3D
	exit_door.name = "ExitDoor"
	exit_door.position = Vector3(9.0, 0.0, REAR_Z)
	add_child(exit_door)

	# The doorway deliberately opens into empty space. The future corridor will
	# be built behind this threshold in a later phase.


func _build_raked_seating() -> void:
	var row_positions := [-9.3, -7.3, -5.3, -3.3, -1.3, 0.7, 2.7, 4.7, 6.7, 8.7]
	# Six large chairs per block. Their spacing is deliberately close enough for
	# shared-armrest silhouettes while retaining a 1.8 m central aisle and about
	# 1.9 m at each side.
	var left_columns := [-8.36, -7.00, -5.64, -4.28, -2.92, -1.54]
	var right_columns := [1.54, 2.92, 4.28, 5.64, 7.00, 8.36]

	for row_index in row_positions.size():
		var z: float = row_positions[row_index]
		var row_height := float(row_index) * ROW_RISE
		_build_seat_tier(row_index, z, row_height)
		for column_index in left_columns.size():
			_add_seat("Seat_L_%02d_%02d" % [row_index + 1, column_index + 1], Vector3(left_columns[column_index], row_height, z))
		for column_index in right_columns.size():
			_add_seat("Seat_R_%02d_%02d" % [row_index + 1, column_index + 1], Vector3(right_columns[column_index], row_height, z))
	_build_ramp_edge_cladding(row_positions)

	# Smooth, shallow ramps: central and both side aisles are visible; the two
	# seating blocks get matching invisible primitive collisions over their tiers.
	_add_slope("CentralRamp", 0.0, 2.0, RAMP_FRONT_Z, RAMP_REAR_Z, 0.0, RAMP_REAR_HEIGHT, true)
	_add_slope("LeftSideRamp", -SIDE_RAMP_CENTRE, SIDE_RAMP_WIDTH, RAMP_FRONT_Z, RAMP_REAR_Z, 0.0, RAMP_REAR_HEIGHT, true)
	_add_slope("RightSideRamp", SIDE_RAMP_CENTRE, SIDE_RAMP_WIDTH, RAMP_FRONT_Z, RAMP_REAR_Z, 0.0, RAMP_REAR_HEIGHT, true)
	_add_slope("LeftSeatingCollision", -5.10, 8.20, RAMP_FRONT_Z, RAMP_REAR_Z, 0.0, RAMP_REAR_HEIGHT, false)
	_add_slope("RightSeatingCollision", 5.10, 8.20, RAMP_FRONT_Z, RAMP_REAR_Z, 0.0, RAMP_REAR_HEIGHT, false)
	_build_rear_access_steps()


func _build_seat_tier(row_index: int, z: float, row_height: float) -> void:
	if row_index == 0:
		return
	var front_edge := z - 1.0
	var depth := RAMP_REAR_Z - front_edge
	for side in [-1.0, 1.0]:
		var tier_position := Vector3(side * 5.10, row_height - ROW_RISE * 0.5, front_edge + depth * 0.5)
		var tier_size := Vector3(8.20, ROW_RISE, depth)
		_add_box(
			"SeatTier_%02d_%s" % [row_index, side],
			tier_position,
			tier_size,
			"carpet",
			false
		)
		# The player keeps using the smooth invisible ramp on layer 1. Trash also
		# collides with these layer-4 tier volumes, so it rests on the visible
		# carpet instead of sinking into the wedge between ramp and riser.
		_add_trash_only_collision(
			"SeatTierTrashCollision_%02d_%s" % [row_index, side],
			tier_position,
			tier_size
		)
	_build_step_lights(row_index, front_edge, row_height)


func _build_step_lights(row_index: int, z: float, _height: float) -> void:
	for aisle_index in AISLE_LIGHT_CENTRES.size():
		var light_root := _add_box(
			"AisleLight_%02d_%02d" % [row_index, aisle_index],
			Vector3(
				AISLE_LIGHT_CENTRES[aisle_index],
				_get_ramp_surface_height(z + 0.03) + 0.002,
				z + 0.03
			),
			Vector3(AISLE_LIGHT_WIDTHS[aisle_index], 0.012, 0.045),
			"step_light",
			false
		)
		light_root.rotation.x = -atan2(RAMP_REAR_HEIGHT, RAMP_REAR_Z - RAMP_FRONT_Z)


func _get_ramp_surface_height(z: float) -> float:
	return lerpf(
		0.0,
		RAMP_REAR_HEIGHT,
		clampf(inverse_lerp(RAMP_FRONT_Z, RAMP_REAR_Z, z), 0.0, 1.0)
	)


func _build_ramp_edge_cladding(row_positions: Array) -> void:
	# The four exposed edges of the two seating blocks are clad down to floor
	# level, following each tier rather than leaving the carpet layers visible.
	for row_index in range(1, row_positions.size()):
		var front_edge: float = float(row_positions[row_index]) - 1.0
		var rear_edge: float = (
			float(row_positions[row_index + 1]) - 1.0
			if row_index + 1 < row_positions.size()
			else RAMP_REAR_Z
		)
		var segment_depth := rear_edge - front_edge
		var segment_height := float(row_index) * ROW_RISE
		var trim_height := maxf(0.02, segment_height - 0.025)
		for x in STAIR_EDGE_XS:
			_add_trash_blocker_box(
				"RampEdge_%02d_%s" % [row_index, x],
				Vector3(x, trim_height * 0.5, front_edge + segment_depth * 0.5),
				Vector3(0.07, trim_height, segment_depth - 0.012),
				"charcoal"
			)
			_add_trash_blocker_box(
				"RampEdgeRail_%02d_%s" % [row_index, x],
				Vector3(x, segment_height + 0.075, front_edge + segment_depth * 0.5),
				Vector3(0.18, 0.15, segment_depth - 0.018),
				"charcoal"
			)

	# Rear faces form two solid charcoal walls. A thicker horizontal beam caps
	# each wall like the black rear rail in the visual reference.
	for side in [-1.0, 1.0]:
		_add_trash_blocker_box(
			"RearSeatingWall_%s" % side,
			Vector3(float(side) * 5.10, RAMP_REAR_HEIGHT * 0.5, RAMP_REAR_Z + 0.07),
			Vector3(8.20, RAMP_REAR_HEIGHT, 0.14),
			"charcoal"
		)
		_add_trash_blocker_box(
			"RearSeatingRail_%s" % side,
			Vector3(float(side) * 5.10, RAMP_REAR_HEIGHT + 0.10, RAMP_REAR_Z + 0.02),
			Vector3(8.35, 0.20, 0.30),
			"charcoal"
		)
	_build_rear_step_edge_cladding()


func _build_rear_step_edge_cladding() -> void:
	var segment_centres := [10.125, 10.975, 11.825]
	var segment_heights := [1.17, 0.78, 0.39]
	for segment_index in segment_centres.size():
		var trim_height: float = segment_heights[segment_index] - 0.025
		for x in STAIR_EDGE_XS:
			_add_trash_blocker_box(
				"RearStepEdge_%02d_%s" % [segment_index, x],
				Vector3(x, trim_height * 0.5, segment_centres[segment_index]),
				Vector3(0.07, trim_height, 0.838),
				"charcoal"
			)
			_add_trash_blocker_box(
				"RearStepRail_%02d_%s" % [segment_index, x],
				Vector3(x, segment_heights[segment_index] + 0.075, segment_centres[segment_index]),
				Vector3(0.18, 0.15, 0.832),
				"charcoal"
			)


func _build_rear_access_steps() -> void:
	# Three solid volumes meet the floor, so their sides never expose a void.
	var aisle_centres := [-SIDE_RAMP_CENTRE, 0.0, SIDE_RAMP_CENTRE]
	var aisle_widths := [SIDE_RAMP_WIDTH, 2.0, SIDE_RAMP_WIDTH]
	for aisle_index in aisle_centres.size():
		var floor_x: float = aisle_centres[aisle_index]
		var floor_width: float = aisle_widths[aisle_index]
		var light_x: float = AISLE_LIGHT_CENTRES[aisle_index]
		var light_width: float = AISLE_LIGHT_WIDTHS[aisle_index]
		_add_box("RearStepHigh_%s" % floor_x, Vector3(floor_x, 0.585, 10.125), Vector3(floor_width, 1.17, 0.85), "carpet", false)
		_add_box("RearStepMiddle_%s" % floor_x, Vector3(floor_x, 0.39, 10.975), Vector3(floor_width, 0.78, 0.85), "carpet", false)
		_add_box("RearStepLow_%s" % floor_x, Vector3(floor_x, 0.195, 11.825), Vector3(floor_width, 0.39, 0.85), "carpet", false)
		_add_slope("RearStepRamp_%s" % floor_x, floor_x, floor_width, RAMP_REAR_Z, 12.25, RAMP_REAR_HEIGHT, 0.0, false)
		var edge_zs := [9.72, 10.57, 11.42]
		var edge_heights := [1.176, 0.786, 0.396]
		for edge_index in edge_zs.size():
			_add_box(
				"RearStepLight_%s_%02d" % [floor_x, edge_index],
				Vector3(light_x, edge_heights[edge_index], edge_zs[edge_index]),
				Vector3(light_width, 0.012, 0.045),
				"step_light",
				false
			)


func _add_seat(seat_name: String, seat_position: Vector3) -> void:
	var root := StaticBody3D.new()
	root.name = seat_name
	root.position = seat_position
	# The smooth hull is reserved for character movement. Dynamic trash ignores
	# this layer so the hull cannot form an invisible ramp over the cushion.
	root.collision_layer = SEAT_PLAYER_COLLISION_LAYER
	root.collision_mask = 1
	root.add_to_group("phase_1_seat")
	root.add_to_group("phase_1_geometry")
	add_child(root)
	var variant_index := _seat_visual_index % SEAT_VARIANT_PATTERN.size()
	_seat_visual_index += 1
	var visual_scene: PackedScene = SEAT_VARIANT_PATTERN[variant_index]
	var variant_name: String = SEAT_VARIANT_NAMES[variant_index]
	var visual := visual_scene.instantiate()
	visual.name = variant_name
	visual.rotation.y = PI
	visual.scale = Vector3.ONE * SEAT_SCALE
	root.add_child(visual)
	root.set_meta("seat_variant", variant_name)
	if variant_name != "ButacaPlegada":
		_add_seat_interaction(root)
	if not _add_seat_convex_collision(visual, root):
		# Safety fallback matching the current 1.55 visual scale.
		_add_collision("FallbackCollision", Vector3(0, 0.64, 0.0), Vector3(1.10, 1.28, 0.98), root)
	if variant_name != "ButacaPlegada":
		_add_seat_cushion_collision(root)


func _add_seat_interaction(seat: StaticBody3D) -> void:
	var interaction := Area3D.new()
	interaction.name = "CinemaSeatInteraction"
	interaction.set_script(SEAT_INTERACTABLE_SCRIPT)
	interaction.room_id = &"room_01"
	interaction.seat_id = StringName(seat.name)
	interaction.seat_body = seat
	interaction.facing_y = 0.0
	interaction.rear_direction = 1.0
	var aisle_x := 0.0
	for candidate in [-10.05, 0.0, 10.05]:
		if absf(seat.position.x - candidate) < absf(seat.position.x - aisle_x):
			aisle_x = candidate
	interaction.aisle_x = aisle_x
	interaction.position = Vector3(0.0, 0.75, -0.57)
	interaction.collision_layer = 0
	interaction.collision_mask = 0
	interaction.add_to_group("cinema_seat")
	seat.add_child(interaction)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.94, 1.10, 0.64)
	collision.shape = shape
	interaction.add_child(collision)


func _add_seat_convex_collision(node: Node, body: StaticBody3D) -> bool:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var mesh_key := mesh_instance.mesh.get_instance_id()
			var shape := _seat_collision_shapes.get(mesh_key) as Shape3D
			if shape == null:
				# A simplified convex hull retains the outer mesh silhouette while
				# removing open triangles and cavities that can trap the player capsule.
				shape = mesh_instance.mesh.create_convex_shape(true, true)
				if shape != null:
					_seat_collision_shapes[mesh_key] = shape
			if shape != null:
				var collision := CollisionShape3D.new()
				collision.name = "ConvexSeatCollision"
				collision.shape = shape
				collision.transform = body.global_transform.affine_inverse() * mesh_instance.global_transform
				body.add_child(collision)
				return true
	for child in node.get_children():
		if _add_seat_convex_collision(child, body):
			return true
	return false


func _add_seat_cushion_collision(body: StaticBody3D) -> void:
	# The convex outer hull is intentionally smooth for the player, but its top
	# slopes from the backrest and would shed props. Keep this shared horizontal
	# pad on the normal world layer so lightweight props see the real seat while
	# ignoring the character-only hull.
	if _seat_cushion_shape == null:
		_seat_cushion_shape = BoxShape3D.new()
		_seat_cushion_shape.size = Vector3(0.96, 0.16, 0.62)
	var cushion_body := StaticBody3D.new()
	cushion_body.name = "SeatCushionSurface"
	cushion_body.collision_layer = 1
	cushion_body.collision_mask = 1
	body.add_child(cushion_body)
	var collision := CollisionShape3D.new()
	collision.name = "SeatCushionCollision"
	collision.position = Vector3(0.0, 0.57, 0.02)
	collision.shape = _seat_cushion_shape
	cushion_body.add_child(collision)


func _build_room_one_props() -> void:
	# Each lateral bay follows Room 3: grille, speaker and two horizontal lamps.
	var bay_length := ROOM_LENGTH / float(SIDE_BAY_COUNT)
	for side in [-1.0, 1.0]:
		var wall_x: float = float(side) * 10.94
		var inward_rotation: float = float(side) * PI * 0.5
		var speaker_rotation := inward_rotation + PI
		for bay_index in SIDE_BAY_COUNT:
			var z := FRONT_Z + (bay_index + 0.5) * bay_length
			var tag := "%s_%02d" % ["L" if side < 0 else "R", bay_index + 1]
			_add_prop("Grille_%s" % tag, WALL_GRILLE_SCENE, Vector3(wall_x, 4.75, z), Vector3(0.9, 0.9, 0.9), Vector3.ZERO, inward_rotation)
			_add_prop("WallSpeaker_%s" % tag, WALL_SPEAKER_SCENE, Vector3(wall_x, 3.35, z), Vector3(0.95, 0.95, 0.95), Vector3.ZERO, speaker_rotation)
			_add_prop("WallLightA_%s" % tag, WALL_LIGHT_SCENE, Vector3(wall_x, 3.85, z - 1.55), Vector3(0.55, 0.55, 0.40), Vector3.ZERO, inward_rotation, PI * 0.5)
			_add_prop("WallLightB_%s" % tag, WALL_LIGHT_SCENE, Vector3(wall_x, 3.85, z + 1.55), Vector3(0.55, 0.55, 0.40), Vector3.ZERO, inward_rotation, PI * 0.5)
			_add_wall_glow("WallGlowA_%s" % tag, Vector3(float(side) * 10.55, 3.85, z - 1.55))
			_add_wall_glow("WallGlowB_%s" % tag, Vector3(float(side) * 10.55, 3.85, z + 1.55))

	_add_prop("CinemaSpeakerLeft", CINEMA_SPEAKER_SCENE, Vector3(-8.25, 0.08, -13.35), Vector3(5.4, 5.4, 5.4), Vector3(3.06, 5.4, 2.7), deg_to_rad(35.0))
	_add_prop("CinemaSpeakerRight", CINEMA_SPEAKER_SCENE, Vector3(8.25, 0.08, -13.35), Vector3(5.4, 5.4, 5.4), Vector3(3.06, 5.4, 2.7), deg_to_rad(-35.0))
	_add_prop("ExitLight", EXIT_LIGHT_SCENE, Vector3(9, 3.48, REAR_Z - 0.24), Vector3(0.9, 0.9, 0.9))


func _add_wall_glow(light_name: String, at_position: Vector3) -> void:
	# Light originates at each lamp, not the speaker between them.
	var light := OmniLight3D.new()
	light.name = light_name
	light.position = at_position
	light.light_color = Color("ffd08a")
	light.light_energy = 0.24
	light.omni_range = 3.0
	light.omni_attenuation = 1.35
	light.shadow_enabled = false
	add_child(light)


func _add_slope(slope_name: String, x: float, width: float, front_z: float, rear_z: float, front_height: float, rear_height: float, show_mesh: bool) -> void:
	var run := rear_z - front_z
	var rise := rear_height - front_height
	var length := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	var root := StaticBody3D.new()
	root.name = slope_name
	root.position = Vector3(x, (front_height + rear_height) * 0.5 - 0.055, (front_z + rear_z) * 0.5)
	root.rotation.x = -angle
	root.add_to_group("phase_1_geometry")
	add_child(root)
	var size := Vector3(width, 0.10, length)
	if show_mesh:
		var mesh_instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = MATERIALS["carpet"]
		mesh_instance.mesh = mesh
		root.add_child(mesh_instance)
	_add_collision("Collision", Vector3.ZERO, size, root)


func _add_prop(prop_name: String, scene: PackedScene, at_position: Vector3, visual_scale: Vector3, collision_size := Vector3.ZERO, rotation_y := 0.0, rotation_x := 0.0) -> void:
	var root := StaticBody3D.new()
	root.name = prop_name
	root.position = at_position
	root.rotation = Vector3(rotation_x, rotation_y, 0.0)
	root.add_to_group("phase_1_geometry")
	add_child(root)
	var visual := scene.instantiate()
	visual.scale = visual_scale
	root.add_child(visual)
	if collision_size != Vector3.ZERO:
		_add_collision("Collision", Vector3(0, collision_size.y * 0.5, 0), collision_size, root)


func _add_box(box_name: String, at_position: Vector3, box_size: Vector3, material_key: String, has_collision := true) -> Node3D:
	var root: Node3D = StaticBody3D.new() if has_collision else Node3D.new()
	root.name = box_name
	root.position = at_position
	root.add_to_group("phase_1_geometry")
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh.material = MATERIALS[material_key]
	mesh_instance.mesh = mesh
	root.add_child(mesh_instance)
	if has_collision:
		_add_collision("Collision", Vector3.ZERO, box_size, root as CollisionObject3D)
	add_child(root)
	return root


func _add_trash_blocker_box(box_name: String, at_position: Vector3, box_size: Vector3, material_key: String) -> Node3D:
	var root := _add_box(box_name, at_position, box_size, material_key, true)
	var body := root as StaticBody3D
	body.collision_layer = TRASH_BLOCKER_LAYER
	body.collision_mask = 1
	return root


func _add_trash_only_collision(collision_name: String, at_position: Vector3, collision_size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = collision_name
	body.position = at_position
	body.collision_layer = TRASH_BLOCKER_LAYER
	body.collision_mask = 1
	body.add_to_group("trash_step_surface")
	_add_collision("Collision", Vector3.ZERO, collision_size, body)
	add_child(body)
	return body


func _add_collision(collision_name: String, at_position: Vector3, collision_size: Vector3, parent: CollisionObject3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = collision_name
	collision.position = at_position
	var shape := BoxShape3D.new()
	shape.size = collision_size
	collision.shape = shape
	parent.add_child(collision)
