class_name Room02Blockout
extends Node3D

## Sala 2 — Bajo las luces.
## The auditorium grows from the existing north-facing corridor shutter.  It is
## intentionally built from the same primitives/material resources as Room 1;
## only its direction is inverted: entrance at -Z, screen at +Z.

const ROOM_CENTER_X := 21.1
const ROOM_WIDTH := 27.2
const ROOM_LENGTH := 32.0
const ROOM_HEIGHT := 7.0
const WALL_RED_TOP := 2.55
const SIDE_BAY_COUNT := 6
const ENTRY_Z := 25.0
const SCREEN_Z := 56.72
const ROOM_REAR_Z := 57.0
const WALL_DEPTH := 0.24
const ROW_RISE := 0.14625
const SEAT_SCALE := 1.55
const SEATING_FRONT_Z := 51.0
const SEATING_REAR_Z := 33.0
const SEATING_REAR_HEIGHT := 1.17
const SEAT_PLAYER_COLLISION_LAYER := 8
const TRASH_BLOCKER_LAYER := 4

const SEAT_STANDARD_SCENE := preload("res://assets/models/source/general/ButacaEstandar.glb")
const SEAT_FOLDED_SCENE := preload("res://assets/models/source/general/ButacaPlegada.glb")
const SEAT_BROKEN_SCENE := preload("res://assets/models/source/general/ButacaRota.glb")
const SEAT_INTERACTABLE_SCRIPT := preload("res://scripts/cinema_seat_interactable.gd")
const PosterMaterialScript := preload("res://scripts/cinema_poster_material.gd")
# Match the standard-majority seat mix used in all cinema rooms.
const SEAT_VARIANT_PATTERN: Array[PackedScene] = [
	SEAT_STANDARD_SCENE, SEAT_FOLDED_SCENE, SEAT_STANDARD_SCENE,
	SEAT_STANDARD_SCENE, SEAT_BROKEN_SCENE,
]
const SEAT_VARIANT_NAMES := ["ButacaEstandar", "ButacaPlegada", "ButacaEstandar", "ButacaEstandar", "ButacaRota"]
const WALL_SPEAKER_SCENE := preload("res://assets/models/source/room_1/AltavozParedes.glb")
const CINEMA_SPEAKER_SCENE := preload("res://assets/models/source/room_1/AltavozCine.glb")
const WALL_LIGHT_SCENE := preload("res://assets/models/source/room_1/LucesParedes.glb")
const WALL_GRILLE_SCENE := preload("res://assets/models/source/room_1/RejillaParedes.glb")
const HANGING_HEART_SCENE := preload("res://assets/models/source/room_2/CorazonColgado.glb")
const PETALS_SCENE := preload("res://assets/models/source/room_2/Petalos.glb")
const BOW_SCENE := preload("res://assets/models/source/room_2/Lazo.glb")

const CARPET := preload("res://assets/pipeline/materials/room_02_romance_carpet.tres")
const CHARCOAL := preload("res://resources/materials/cinema_charcoal.tres")
const CREAM := preload("res://resources/materials/corridor_aged_plaster.tres")
const CURTAIN := preload("res://resources/materials/cinema_curtain.tres")
const PANEL := preload("res://resources/materials/cinema_panel_wine.tres")
const SCREEN := preload("res://resources/materials/cinema_screen.tres")
const STEP_LIGHT := preload("res://resources/materials/cinema_step_light.tres")
const RoomZoneScript := preload("res://scripts/room_zone.gd")
const ENTRY_POSTER_SCENE := preload("res://assets/models/source/general/cartelPeliculas.glb")
const TRASH_SCENE := preload("res://scenes/gameplay/trash_item.tscn")
const SMALL_TRASH: Array[Resource] = [
	preload("res://resources/trash/ticket.tres"), preload("res://resources/trash/napkin.tres"),
	preload("res://resources/trash/cup.tres"), preload("res://resources/trash/can.tres"),
	preload("res://resources/trash/straw.tres"), preload("res://resources/trash/popcorn.tres"),
]
const LARGE_TRASH: Array[Resource] = [
	preload("res://resources/trash/bottle.tres"), preload("res://resources/trash/bucket.tres"),
]
const ROOM02_SMALL_TRASH_COUNT := 420
const ROOM02_LARGE_TRASH_COUNT := 60

# Three longitudinal six-seat blocks.  Consecutive pairs use the smaller gap;
# the 1.32 m gaps then read as the separation between couples.
const BLOCK_COLUMNS := [
	[-11.75, -10.63, -9.31, -8.19, -6.87, -5.75],
	[-3.10, -1.98, -0.66, 0.66, 1.98, 3.10],
	[5.70, 6.82, 8.14, 9.46, 10.78, 11.75],
]
const ROW_ZS := [50.0, 48.0, 46.0, 44.0, 42.0, 40.0, 38.0, 36.0, 34.0]
const AISLE_CENTERS := [-12.90, -4.40, 4.40, 12.90]
const AISLE_WIDTHS := [1.42, 1.78, 1.78, 1.42]

var _seat_collision_shapes: Dictionary = {}
var _seat_cushion_shape: BoxShape3D
var _seat_visual_index := 0
var _hanging_hearts: Array[Node3D] = []
var _heart_base_x: Array[float] = []
var _heart_spin_time := 0.0


func _ready() -> void:
	_build_shell()
	_build_raked_seating()
	_build_wall_fixtures()
	_build_romantic_decorations()
	_build_entry_props()
	_build_room_zone()
	call_deferred("_spawn_fixed_trash")


func _process(delta: float) -> void:
	_heart_spin_time += delta
	for heart_index in _hanging_hearts.size():
		var heart := _hanging_hearts[heart_index]
		heart.rotation.y += delta * deg_to_rad(4.0 + float(heart_index % 3))
		heart.rotation.x = _heart_base_x[heart_index] + deg_to_rad(1.5) * sin(_heart_spin_time * 0.8 + float(heart_index) * 0.65)


func _build_shell() -> void:
	_add_box("Room02CarpetFloor", Vector3(ROOM_CENTER_X, -0.12, (ENTRY_Z + ROOM_REAR_Z) * 0.5), Vector3(ROOM_WIDTH, 0.24, ROOM_LENGTH), CARPET)
	_add_box("Room02Ceiling", Vector3(ROOM_CENTER_X, ROOM_HEIGHT + 0.12, (ENTRY_Z + ROOM_REAR_Z) * 0.5), Vector3(ROOM_WIDTH, 0.24, ROOM_LENGTH), CHARCOAL)
	var left_x := ROOM_CENTER_X - ROOM_WIDTH * 0.5
	var right_x := ROOM_CENTER_X + ROOM_WIDTH * 0.5
	assert(is_equal_approx(left_x, 7.5)) # Flush with the existing left shutter jamb.
	_build_side_wall(left_x, -1.0)
	_build_side_wall(right_x, 1.0)
	_build_screen_wall()
	_build_entry_extensions()


func _build_side_wall(x: float, side: float) -> void:
	_add_box("Room02SideBase_%s" % side, Vector3(x, 0.215, 41.0), Vector3(0.24, 0.43, ROOM_LENGTH), CHARCOAL)
	_add_box("Room02SideCornice_%s" % side, Vector3(x, 6.55, 41.0), Vector3(0.30, 0.30, ROOM_LENGTH), CREAM)
	var bay_length := ROOM_LENGTH / float(SIDE_BAY_COUNT)
	var join_y := WALL_RED_TOP - 0.02
	for bay in SIDE_BAY_COUNT:
		var z := ENTRY_Z + (bay + 0.5) * bay_length
		_add_box("Room02WallLower_%s_%02d" % [side, bay], Vector3(x, (0.43 + join_y) * 0.5, z), Vector3(0.18, join_y - 0.43, bay_length), PANEL)
		_add_box("Room02WallUpper_%s_%02d" % [side, bay], Vector3(x, (join_y + ROOM_HEIGHT) * 0.5, z), Vector3(0.18, ROOM_HEIGHT - join_y, bay_length), CREAM)
		_add_box("Room02WallMoulding_%s_%02d" % [side, bay], Vector3(x, WALL_RED_TOP, z), Vector3(0.30, 0.16, bay_length), CHARCOAL, false)
	for boundary in SIDE_BAY_COUNT + 1:
		_add_box("Room02WallPillar_%s_%02d" % [side, boundary], Vector3(x, 3.5, ENTRY_Z + boundary * bay_length), Vector3(0.40, ROOM_HEIGHT, 0.28), CHARCOAL)


func _build_screen_wall() -> void:
	_add_box("Room02ScreenWallBase", Vector3(ROOM_CENTER_X, 0.215, ROOM_REAR_Z), Vector3(ROOM_WIDTH, 0.43, WALL_DEPTH), CHARCOAL)
	var join_y := WALL_RED_TOP - 0.02
	for panel_index in 6:
		var x := ROOM_CENTER_X - 11.34 + panel_index * 4.54
		_add_box("Room02ScreenWallLower_%02d" % (panel_index + 1), Vector3(x, (0.43 + join_y) * 0.5, ROOM_REAR_Z), Vector3(4.54, join_y - 0.43, WALL_DEPTH), PANEL)
		_add_box("Room02ScreenWallUpper_%02d" % (panel_index + 1), Vector3(x, (join_y + ROOM_HEIGHT) * 0.5, ROOM_REAR_Z), Vector3(4.54, ROOM_HEIGHT - join_y, WALL_DEPTH), CREAM)
		_add_box("Room02ScreenWallMoulding_%02d" % (panel_index + 1), Vector3(x, WALL_RED_TOP, ROOM_REAR_Z - 0.02), Vector3(4.58, 0.16, 0.30), CHARCOAL, false)
	for pillar_index in 7:
		var pillar_x := ROOM_CENTER_X - ROOM_WIDTH * 0.5 + pillar_index * (ROOM_WIDTH / 6.0)
		_add_box("Room02ScreenWallPillar_%02d" % (pillar_index + 1), Vector3(pillar_x, 3.5, ROOM_REAR_Z - 0.13), Vector3(0.34, ROOM_HEIGHT, 0.38), CHARCOAL)
	_add_box("Room02Screen", Vector3(ROOM_CENTER_X, 3.60, SCREEN_Z), Vector3(14.2, 5.2, 0.10), SCREEN)
	_add_box("Room02ScreenBeamTop", Vector3(ROOM_CENTER_X, 6.28, SCREEN_Z - 0.05), Vector3(14.95, 0.28, 0.26), CHARCOAL, false)
	_add_box("Room02ScreenBeamBottom", Vector3(ROOM_CENTER_X, 0.92, SCREEN_Z - 0.05), Vector3(14.95, 0.28, 0.26), CHARCOAL, false)
	_add_box("Room02ScreenBeamLeft", Vector3(ROOM_CENTER_X - 7.34, 3.60, SCREEN_Z - 0.05), Vector3(0.28, 5.62, 0.26), CHARCOAL, false)
	_add_box("Room02ScreenBeamRight", Vector3(ROOM_CENTER_X + 7.34, 3.60, SCREEN_Z - 0.05), Vector3(0.28, 5.62, 0.26), CHARCOAL, false)
	_add_box("Room02CurtainLeft", Vector3(ROOM_CENTER_X - 8.05, 3.52, SCREEN_Z - 0.10), Vector3(1.05, 5.75, 0.20), CURTAIN, false)
	_add_box("Room02CurtainRight", Vector3(ROOM_CENTER_X + 8.05, 3.52, SCREEN_Z - 0.10), Vector3(1.05, 5.75, 0.20), CURTAIN, false)


func _build_entry_extensions() -> void:
	# The corridor owns the 3 m shutter at x=7.5..10.5 and the adjoining
	# lower wall through x=11.  Complete its right wing without sealing the door.
	var right_edge := ROOM_CENTER_X + ROOM_WIDTH * 0.5
	var lower_start := 11.0
	var lower_width := right_edge - lower_start
	var lower_centre := (lower_start + right_edge) * 0.5
	# Equal-width panels keep the wine material at a consistent scale instead of
	# stretching one texture over the entire 23.7 m rear wall.
	var bay_width := lower_width / 5.0
	var join_y := WALL_RED_TOP - 0.02
	for bay_index in 5:
		var bay_x := lower_start + (bay_index + 0.5) * bay_width
		_add_box("Room02EntryWinePanel_%02d" % (bay_index + 1), Vector3(bay_x, join_y * 0.5, ENTRY_Z), Vector3(bay_width, join_y, WALL_DEPTH), PANEL)
		_add_box("Room02EntryCreamPanel_%02d" % (bay_index + 1), Vector3(bay_x, (join_y + 4.4) * 0.5, ENTRY_Z), Vector3(bay_width, 4.4 - join_y, WALL_DEPTH), CREAM)
		_add_box("Room02EntryUpperPanel_%02d" % (bay_index + 1), Vector3(bay_x, 5.70, ENTRY_Z), Vector3(bay_width, 2.6, WALL_DEPTH), CREAM)
	_add_box("Room02EntryRightTrim", Vector3(lower_centre, WALL_RED_TOP, ENTRY_Z - 0.02), Vector3(lower_width, 0.16, 0.30), CHARCOAL, false)
	_add_box("Room02EntryRightBase", Vector3(lower_centre, 0.14, ENTRY_Z - 0.02), Vector3(lower_width, 0.28, 0.30), CHARCOAL, false)
	# Both the existing header and corridor wall end at y=4.4.
	_add_box("Room02EntryUpperHeader", Vector3(9.0, 5.70, ENTRY_Z + 0.04), Vector3(3.0, 2.6, 0.28), CREAM)
	# Cover the corridor-owned shutter header on the Room 2 side with the same
	# upper wall surface and depth as Room 2's own entrance wall.
	_add_box("Room02EntryDoorInteriorHeader", Vector3(9.0, 3.60, ENTRY_Z + 0.17), Vector3(3.0, 1.6, 0.02), CREAM, false)
	# The right jamb meets the first rear-wall divider at x=11 instead of
	# leaving a pale strip between shutter and column.
	_add_box("Room02EntryDoorInteriorFrameLeft", Vector3(7.5, 1.4, ENTRY_Z + 0.24), Vector3(0.34, 2.8, 0.08), CHARCOAL, false)
	_add_box("Room02EntryDoorInteriorFrameRight", Vector3(10.76, 1.4, ENTRY_Z + 0.24), Vector3(0.48, 2.8, 0.08), CHARCOAL, false)
	_add_box("Room02EntryDoorInteriorFrameTop", Vector3(9.13, 3.0, ENTRY_Z + 0.24), Vector3(3.60, 0.38, 0.08), CHARCOAL, false)
	_add_box("Room02EntryRightUpperCap", Vector3(10.75, 5.70, ENTRY_Z), Vector3(0.5, 2.6, WALL_DEPTH), CREAM)
	for pillar_index in 6:
		var pillar_x := lower_start + pillar_index * bay_width
		_add_box("Room02EntryWallPillar_%02d" % (pillar_index + 1), Vector3(pillar_x, ROOM_HEIGHT * 0.5, ENTRY_Z + 0.14), Vector3(0.38, ROOM_HEIGHT, 0.30), CHARCOAL)


func _build_raked_seating() -> void:
	for row_index in ROW_ZS.size():
		var z := float(ROW_ZS[row_index])
		var row_height := row_index * ROW_RISE
		_build_seat_tier(row_index, z, row_height)
		for block_index in BLOCK_COLUMNS.size():
			for seat_index in BLOCK_COLUMNS[block_index].size():
				var offset_x := float(BLOCK_COLUMNS[block_index][seat_index])
				_add_seat("Room02Seat_%02d_%02d_%02d" % [row_index + 1, block_index + 1, seat_index + 1], Vector3(ROOM_CENTER_X + offset_x, row_height, z))
	for aisle_index in AISLE_CENTERS.size():
		_add_slope("Room02AisleSlope_%02d" % (aisle_index + 1), ROOM_CENTER_X + float(AISLE_CENTERS[aisle_index]), float(AISLE_WIDTHS[aisle_index]), SEATING_FRONT_Z, SEATING_REAR_Z, 0.0, SEATING_REAR_HEIGHT, true)
	for block_index in BLOCK_COLUMNS.size():
		var center := _block_center(block_index)
		_add_slope("Room02SeatSlope_%02d" % (block_index + 1), ROOM_CENTER_X + center, 7.15, SEATING_FRONT_Z, SEATING_REAR_Z, 0.0, SEATING_REAR_HEIGHT, false)
	_build_rear_access_steps()


func _build_seat_tier(row_index: int, z: float, row_height: float) -> void:
	if row_index == 0:
		return
	var screen_edge := z + 1.0
	var depth := screen_edge - SEATING_REAR_Z
	for block_index in BLOCK_COLUMNS.size():
		var tier_position := Vector3(ROOM_CENTER_X + _block_center(block_index), row_height - ROW_RISE * 0.5, SEATING_REAR_Z + depth * 0.5)
		var tier_size := Vector3(7.15, ROW_RISE, depth)
		_add_box("Room02SeatTier_%02d_%02d" % [row_index, block_index], tier_position, tier_size, CARPET, false)
		_add_trash_only_collision("Room02SeatTierTrashCollision_%02d_%02d" % [row_index, block_index], tier_position, tier_size)
	for aisle_index in AISLE_CENTERS.size():
		var light := _add_box("Room02StepLight_%02d_%02d" % [row_index, aisle_index], Vector3(ROOM_CENTER_X + float(AISLE_CENTERS[aisle_index]), _ramp_surface_height(screen_edge) + 0.003, screen_edge), Vector3(float(AISLE_WIDTHS[aisle_index]) * 0.84, 0.012, 0.045), STEP_LIGHT, false)
		light.rotation.x = atan2(SEATING_REAR_HEIGHT, SEATING_FRONT_Z - SEATING_REAR_Z)


func _build_rear_access_steps() -> void:
	# Like Room 1, three filled steps rise from the entrance to the rear landing.
	for aisle_index in AISLE_CENTERS.size():
		var x := ROOM_CENTER_X + float(AISLE_CENTERS[aisle_index])
		var width := float(AISLE_WIDTHS[aisle_index])
		for step_index in 3:
			# Rise toward the auditorium: low beside the entrance, high beside the seats.
			var height := (step_index + 1) * (SEATING_REAR_HEIGHT / 3.0)
			var z := 30.88 + step_index * 0.85
			_add_box("Room02RearAccess_%02d_%02d" % [aisle_index, step_index], Vector3(x, height * 0.5, z), Vector3(width, height, 0.85), CARPET, false)
			_add_box("Room02RearAccessLight_%02d_%02d" % [aisle_index, step_index], Vector3(x, height + 0.004, z + 0.40), Vector3(width * 0.84, 0.012, 0.045), STEP_LIGHT, false)
		_add_slope("Room02RearAccessSlope_%02d" % aisle_index, x, width, SEATING_REAR_Z, 30.455, SEATING_REAR_HEIGHT, 0.0, false)


func _build_wall_fixtures() -> void:
	var bay_length := ROOM_LENGTH / float(SIDE_BAY_COUNT)
	for side in [-1.0, 1.0]:
		var wall_x: float = ROOM_CENTER_X + float(side) * (ROOM_WIDTH * 0.5 - 0.16)
		var inward_rotation: float = float(side) * PI * 0.5
		var speaker_rotation: float = inward_rotation + PI
		for bay_index in SIDE_BAY_COUNT:
			var z := ENTRY_Z + (bay_index + 0.5) * bay_length
			var tag := "%s_%02d" % ["L" if side < 0 else "R", bay_index + 1]
			_add_prop("Room02Grille_%s" % tag, WALL_GRILLE_SCENE, Vector3(wall_x, 4.75, z), Vector3.ONE * 0.9, Vector3.ZERO, inward_rotation)
			_add_prop("Room02WallSpeaker_%s" % tag, WALL_SPEAKER_SCENE, Vector3(wall_x, 3.35, z), Vector3.ONE * 0.92, Vector3.ZERO, speaker_rotation)
			_add_prop("Room02WallLightA_%s" % tag, WALL_LIGHT_SCENE, Vector3(wall_x, 3.85, z - 1.55), Vector3(0.55, 0.55, 0.40), Vector3.ZERO, inward_rotation, PI * 0.5)
			_add_prop("Room02WallLightB_%s" % tag, WALL_LIGHT_SCENE, Vector3(wall_x, 3.85, z + 1.55), Vector3(0.55, 0.55, 0.40), Vector3.ZERO, inward_rotation, PI * 0.5)
			_add_wall_glow("Room02WallGlowA_%s" % tag, Vector3(wall_x - side * 0.38, 3.85, z - 1.55))
			_add_wall_glow("Room02WallGlowB_%s" % tag, Vector3(wall_x - side * 0.38, 3.85, z + 1.55))
			# The bow mesh starts at its pivot and is 0.96 m high at this scale:
			# placing its base at 2.07 m centres it on the 2.55 m moulding.
			_add_decoration("Room02Bow_%s" % tag, BOW_SCENE, Vector3(wall_x - side * 0.18, 2.07, z), Vector3.ONE * 1.60, inward_rotation)
	# Only the lateral walls carry the small fixtures. The two freestanding
	# cinema speakers turn inward by 45 degrees toward the seats.
	_add_prop("Room02CinemaSpeakerLeft", CINEMA_SPEAKER_SCENE, Vector3(ROOM_CENTER_X - 9.25, 0.08, 55.40), Vector3.ONE * 3.2, Vector3(1.95, 3.55, 1.85), PI - deg_to_rad(45.0))
	_add_prop("Room02CinemaSpeakerRight", CINEMA_SPEAKER_SCENE, Vector3(ROOM_CENTER_X + 9.25, 0.08, 55.40), Vector3.ONE * 3.2, Vector3(1.95, 3.55, 1.85), PI + deg_to_rad(45.0))


func _build_romantic_decorations() -> void:
	# The existing 5.12 m-wide petal mesh now reads at roughly 45–53 cm.
	var petal_index := 0
	for aisle_index in AISLE_CENTERS.size():
		for row_index in 8:
			var z := 34.6 + row_index * 2.05
			var lateral := -0.23 if (row_index + aisle_index) % 2 == 0 else 0.23
			var at := Vector3(ROOM_CENTER_X + float(AISLE_CENTERS[aisle_index]) + lateral, _ramp_surface_height(z) + 0.035, z)
			_add_decoration("Room02Petals_%02d" % (petal_index + 1), PETALS_SCENE, at, Vector3.ONE * 0.092, deg_to_rad(float(petal_index * 47)), deg_to_rad(float((petal_index % 5 - 2) * 6)))
			petal_index += 1
	# Use a fixed seed so the two open-floor scatters are organic but stable
	# between runs. Keep clear of the screen speakers and entrance shutter.
	var petal_rng := RandomNumberGenerator.new()
	petal_rng.seed = 20260923
	petal_index = _scatter_floor_petals(petal_rng, 20, 11.2, 31.0, 51.8, 54.0, petal_index)
	petal_index = _scatter_floor_petals(petal_rng, 30, 11.4, 32.2, 26.2, 30.0, petal_index)
	# Each Vector3 stores lateral shift, gentle X tilt in degrees, and Z depth.
	# Staggering all three dimensions avoids nine hearts in rigid rows.
	var heart_layout := [
		[Vector3(-1.00, -7.0, 36.8), Vector3(0.85, 5.0, 43.9), Vector3(-0.35, -4.0, 49.4)],
		[Vector3(0.70, 6.0, 39.3), Vector3(-0.95, -5.0, 46.1), Vector3(1.05, 8.0, 50.3)],
		[Vector3(-0.75, -6.0, 35.9), Vector3(1.10, 4.0, 42.5), Vector3(-0.45, -8.0, 48.2)],
	]
	var heart_index := 0
	for block_index in BLOCK_COLUMNS.size():
		for placement in heart_layout[block_index]:
			var x: float = ROOM_CENTER_X + _block_center(block_index) + placement.x
			var heart := _add_decoration("Room02HangingHeart_%02d" % (heart_index + 1), HANGING_HEART_SCENE, Vector3(x, 5.25, placement.z), Vector3.ONE * 2.55, deg_to_rad(float(heart_index * 31)), deg_to_rad(placement.y))
			_hanging_hearts.append(heart)
			_heart_base_x.append(heart.rotation.x)
			heart_index += 1
	# No illuminated hearts on the floor: only the hanging decoration remains.


func _scatter_floor_petals(rng: RandomNumberGenerator, count: int, min_x: float, max_x: float, min_z: float, max_z: float, next_index: int) -> int:
	var placed: Array[Vector2] = []
	var attempts := 0
	while placed.size() < count and attempts < count * 80:
		attempts += 1
		var point := Vector2(rng.randf_range(min_x, max_x), rng.randf_range(min_z, max_z))
		var has_space := true
		for previous in placed:
			if previous.distance_to(point) < 1.0:
				has_space = false
				break
		if not has_space:
			continue
		placed.append(point)
		var petal_scale := rng.randf_range(0.088, 0.104)
		_add_decoration(
			"Room02Petals_%02d" % (next_index + 1), PETALS_SCENE,
			Vector3(point.x, 0.035, point.y), Vector3.ONE * petal_scale,
			rng.randf_range(0.0, TAU), deg_to_rad(rng.randf_range(-9.0, 9.0))
		)
		next_index += 1
	if placed.size() != count:
		push_error("Room 2 petal scatter could not place all groups safely.")
	return next_index


func _build_entry_props() -> void:
	# The potato display occupies x=4.25 on the corridor side. Seen when walking
	# toward Sala 2, its left is +X: this larger floor poster fits between the
	# display and shutter without obstructing either.
	_add_prop("Room02EntryPosterFrame", ENTRY_POSTER_SCENE, Vector3(6.20, 0.0, 24.55), Vector3.ONE * 2.0, Vector3(1.50, 2.40, 0.55), PI)
	var poster := MeshInstance3D.new()
	poster.name = "Room02EntryPosterDisplay"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.27, 1.90)
	poster.mesh = quad
	poster.material_override = PosterMaterialScript.create_for_room(2)
	poster.position = Vector3(6.20, 1.34, 24.45)
	poster.rotation.y = PI
	add_child(poster)


func _build_room_zone() -> void:
	var zone := Area3D.new()
	zone.name = "Room02Zone"
	zone.set_script(RoomZoneScript)
	zone.set("room_id", &"room_02")
	zone.position = Vector3(ROOM_CENTER_X, 2.4, 41.0)
	zone.collision_layer = 0
	zone.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(ROOM_WIDTH - 0.8, 4.8, ROOM_LENGTH - 0.5)
	collision.shape = shape
	zone.add_child(collision)
	add_child(zone)


func _spawn_fixed_trash() -> void:
	var manager := get_tree().get_first_node_in_group("gameplay_manager")
	if manager == null:
		push_error("Room02Blockout requires GameplayManager for persistent trash")
		return
	var small_positions := _build_small_trash_positions()
	var large_positions := _build_large_trash_positions()
	manager.get_dense_registry().populate(&"room_02",small_positions,large_positions,self)


func _spawn_room02_trash(manager: Node, large: bool, index: int, at: Vector3) -> void:
	var size_key := "large" if large else "small"
	var stable_id := "room_02:%s:%03d" % [size_key, index + 1]
	if manager.is_world_trash_collected(stable_id):
		return
	var definitions := LARGE_TRASH if large else SMALL_TRASH
	var item := TRASH_SCENE.instantiate() as RigidBody3D
	item.name = "Room02Trash_%s_%03d" % [size_key, index + 1]
	item.definition = definitions[index % definitions.size()]
	item.room_id = &"room_02"
	item.world_item_id = stable_id
	item.position = at
	item.rotation.y = deg_to_rad(float((index * 47 + (13 if large else 0)) % 360))
	add_child(item)
	var player := get_tree().get_first_node_in_group("player") as PhysicsBody3D
	if player:
		item.add_collision_exception_with(player)
		player.add_collision_exception_with(item)


func _build_small_trash_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	# 108 distinct cushions: four of the six seats per block in each row.
	var seat_slots := [0, 1, 3, 4]
	for row_index in ROW_ZS.size():
		for block_index in BLOCK_COLUMNS.size():
			for seat_slot in seat_slots:
				var x := ROOM_CENTER_X + float(BLOCK_COLUMNS[block_index][seat_slot])
				var z := float(ROW_ZS[row_index])
				result.append(Vector3(x, row_index * ROW_RISE + 1.27, z))
	# 72 pieces sit beneath the front lips of distinct seats, on their visible tiers.
	for row_index in 8:
		for block_index in BLOCK_COLUMNS.size():
			for seat_slot in [1, 3, 5]:
				var x := ROOM_CENTER_X + float(BLOCK_COLUMNS[block_index][seat_slot])
				var z := float(ROW_ZS[row_index]) + 0.48
				result.append(Vector3(x, _trash_surface_height(x, z) + 0.22, z))
	# 144 pieces in the open spaces between rows; six staggered slots per block.
	for gap_index in ROW_ZS.size() - 1:
		for block_index in BLOCK_COLUMNS.size():
			for slot_index in 6:
				var x := ROOM_CENTER_X + _block_center(block_index) - 2.45 + slot_index * 0.98
				var z := (float(ROW_ZS[gap_index]) + float(ROW_ZS[gap_index + 1])) * 0.5 + (0.25 if slot_index % 2 == 0 else -0.25)
				result.append(Vector3(x, _trash_surface_height(x, z) + 0.30, z))
	# 48 pieces on the aisle ramps, 24 at the screen, and 24 on the rear landing.
	for aisle_index in AISLE_CENTERS.size():
		for slot_index in 12:
			var x := ROOM_CENTER_X + float(AISLE_CENTERS[aisle_index]) + (0.22 if slot_index % 2 == 0 else -0.22)
			var z := 34.5 + slot_index * 1.4
			result.append(Vector3(x, _ramp_surface_height(z) + 0.30, z))
	for front_row in 2:
		for slot_index in 12:
			result.append(Vector3(ROOM_CENTER_X - 7.7 + slot_index * 1.4, 0.30, 52.2 + front_row * 1.05))
	for rear_row in 3:
		for slot_index in 8:
			result.append(Vector3(ROOM_CENTER_X - 10.5 + slot_index * 3.0, 0.30, 26.0 + rear_row * 1.2))
	return result


func _build_large_trash_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	# Larger pieces remain on traversable floor, away from cushions and props.
	for entry_row in 3:
		for slot_index in 8:
			result.append(Vector3(17.5 + slot_index * 2.1, 0.42, 26.5 + entry_row * 1.1))
	for aisle_index in AISLE_CENTERS.size():
		for slot_index in 6:
			var x := ROOM_CENTER_X + float(AISLE_CENTERS[aisle_index])
			var z := 35.2 + slot_index * 2.7
			result.append(Vector3(x, _ramp_surface_height(z) + 0.42, z))
	for front_row in 2:
		for slot_index in 6:
			result.append(Vector3(ROOM_CENTER_X - 7.0 + slot_index * 2.8, 0.42, 53.8 + front_row * 1.05))
	return result


func _trash_surface_height(x: float, z: float) -> float:
	var surface := _ramp_surface_height(z)
	for block_index in BLOCK_COLUMNS.size():
		if absf(x - (ROOM_CENTER_X + _block_center(block_index))) > 3.575:
			continue
		for row_index in range(1, ROW_ZS.size()):
			if z <= float(ROW_ZS[row_index]) + 1.0:
				surface = maxf(surface, row_index * ROW_RISE)
		return surface
	return surface


func _block_center(block_index: int) -> float:
	var columns: Array = BLOCK_COLUMNS[block_index]
	return (float(columns[0]) + float(columns[columns.size() - 1])) * 0.5


func _ramp_surface_height(z: float) -> float:
	return lerpf(0.0, SEATING_REAR_HEIGHT, clampf(inverse_lerp(SEATING_FRONT_Z, SEATING_REAR_Z, z), 0.0, 1.0))


func _add_seat(seat_name: String, at: Vector3) -> void:
	var root := StaticBody3D.new()
	root.name = seat_name
	root.position = at
	root.collision_layer = SEAT_PLAYER_COLLISION_LAYER
	root.collision_mask = 1
	# Keep Room 1's legacy profiling groups exclusive to its 120 seats.
	# Sala 2 exposes its own stable group for future room-specific systems.
	root.add_to_group("room_02_seat")
	add_child(root)
	var variant_index := _seat_visual_index % SEAT_VARIANT_PATTERN.size()
	_seat_visual_index += 1
	var variant_name: String = SEAT_VARIANT_NAMES[variant_index]
	var visual := SEAT_VARIANT_PATTERN[variant_index].instantiate()
	visual.name = variant_name
	visual.scale = Vector3.ONE * SEAT_SCALE
	root.add_child(visual)
	root.set_meta("seat_variant", variant_name)
	if variant_name != "ButacaPlegada":
		_add_seat_interaction(root)
	if not _add_seat_convex_collision(visual, root):
		_add_collision("FallbackCollision", Vector3(0.0, 0.64, 0.0), Vector3(1.10, 1.28, 0.98), root)
	if variant_name != "ButacaPlegada":
		_add_seat_cushion_collision(root)


func _add_seat_interaction(seat: StaticBody3D) -> void:
	var interaction := Area3D.new()
	interaction.name = "CinemaSeatInteraction"
	interaction.set_script(SEAT_INTERACTABLE_SCRIPT)
	interaction.room_id = &"room_02"
	interaction.seat_id = StringName(seat.name)
	interaction.seat_body = seat
	interaction.facing_y = PI
	interaction.rear_direction = -1.0
	var aisle_x := ROOM_CENTER_X + float(AISLE_CENTERS[0])
	for aisle_offset in AISLE_CENTERS:
		var candidate := ROOM_CENTER_X + float(aisle_offset)
		if absf(seat.position.x - candidate) < absf(seat.position.x - aisle_x):
			aisle_x = candidate
	interaction.aisle_x = aisle_x
	interaction.position = Vector3(0.0, 0.75, 0.57)
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


func _add_slope(node_name: String, x: float, width: float, front_z: float, rear_z: float, front_height: float, rear_height: float, show_mesh: bool) -> void:
	var run := rear_z - front_z
	var rise := rear_height - front_height
	var length := sqrt(run * run + rise * rise)
	var root := StaticBody3D.new()
	root.name = node_name
	root.position = Vector3(x, (front_height + rear_height) * 0.5 - 0.055, (front_z + rear_z) * 0.5)
	root.rotation.x = -atan2(rise, run)
	root.add_to_group("phase_1_geometry")
	add_child(root)
	var size := Vector3(width, 0.10, length)
	if show_mesh:
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = CARPET
		visual.mesh = mesh
		root.add_child(visual)
	_add_collision("Collision", Vector3.ZERO, size, root)


func _add_prop(node_name: String, scene: PackedScene, at: Vector3, scale_value: Vector3, collision_size := Vector3.ZERO, rotation_y := 0.0, rotation_x := 0.0) -> void:
	var root: Node3D = StaticBody3D.new() if collision_size != Vector3.ZERO else Node3D.new()
	root.name = node_name
	root.position = at
	root.rotation = Vector3(rotation_x, rotation_y, 0.0)
	var visual := scene.instantiate()
	visual.name = "Model"
	visual.scale = scale_value
	root.add_child(visual)
	if collision_size != Vector3.ZERO:
		_add_collision("Collision", Vector3(0.0, collision_size.y * 0.5, 0.0), collision_size, root as CollisionObject3D)
	add_child(root)


func _add_decoration(node_name: String, scene: PackedScene, at: Vector3, scale_value: Vector3, rotation_y: float, rotation_x := 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.position = at
	root.rotation = Vector3(rotation_x, rotation_y, 0.0)
	var visual := scene.instantiate()
	visual.name = "Model"
	visual.scale = scale_value
	root.add_child(visual)
	add_child(root)
	return root


func _add_wall_glow(node_name: String, at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = at
	light.light_color = Color("ffd08a")
	light.light_energy = 0.24
	light.omni_range = 3.0
	light.omni_attenuation = 1.35
	light.shadow_enabled = false
	add_child(light)


func _add_box(node_name: String, at: Vector3, box_size: Vector3, material: Material, has_collision := true) -> Node3D:
	var root: Node3D = StaticBody3D.new() if has_collision else Node3D.new()
	root.name = node_name
	root.position = at
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh.material = material
	visual.mesh = mesh
	root.add_child(visual)
	if has_collision:
		_add_collision("Collision", Vector3.ZERO, box_size, root as CollisionObject3D)
	add_child(root)
	return root


func _add_trash_only_collision(node_name: String, at: Vector3, box_size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	body.collision_layer = TRASH_BLOCKER_LAYER
	body.collision_mask = 1
	_add_collision("Collision", Vector3.ZERO, box_size, body)
	add_child(body)


func _add_collision(node_name: String, at: Vector3, collision_size: Vector3, parent: CollisionObject3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = node_name
	collision.position = at
	var shape := BoxShape3D.new()
	shape.size = collision_size
	collision.shape = shape
	parent.add_child(collision)
