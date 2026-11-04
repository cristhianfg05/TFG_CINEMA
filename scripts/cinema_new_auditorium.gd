class_name CinemaNewAuditorium
extends Node3D

# Shared geometry-only authoring for the two new auditoria. All gameplay
# (movies, seats, levers, room audio, trash persistence) uses existing systems.
const ACTION_CARPET := preload("res://assets/pipeline/materials/room_03_action_carpet.tres")
const FEAR_CARPET := preload("res://assets/pipeline/materials/room_04_fear_carpet.tres")
const PANEL := preload("res://resources/materials/cinema_panel_wine.tres")
const CREAM := preload("res://resources/materials/corridor_aged_plaster.tres")
const DARK := preload("res://resources/materials/cinema_charcoal.tres")
const SCREEN := preload("res://resources/materials/cinema_screen.tres")
const CURTAIN := preload("res://resources/materials/cinema_curtain.tres")
const STEP_LIGHT := preload("res://resources/materials/cinema_step_light.tres")
const SEAT_STANDARD := preload("res://assets/models/source/general/ButacaEstandar.glb")
const SEAT_FOLDED := preload("res://assets/models/source/general/ButacaPlegada.glb")
const SEAT_BROKEN := preload("res://assets/models/source/general/ButacaRota.glb")
const CINEMA_SPEAKER := preload("res://assets/models/source/room_1/AltavozCine.glb")
const WALL_SPEAKER := preload("res://assets/models/source/room_1/AltavozParedes.glb")
const WALL_LIGHT := preload("res://assets/models/source/room_1/LucesParedes.glb")
const WALL_GRILLE := preload("res://assets/models/source/room_1/RejillaParedes.glb")
const ACTION_STAR := preload("res://assets/models/source/room_3/Estrella_ColgadaDecoracionAccion.glb")
const FEAR_BATS := preload("res://assets/models/source/room_4/MurcielagosColgados_DecoracionMiedo.glb")
const FEAR_WEB := preload("res://assets/models/source/room_4/Telaraña_DecoracionMiedo.glb")
const FEAR_CURTAIN := preload("res://assets/models/source/room_4/CortinaRota_DecoracionMiedo.glb")
const FEAR_SKULL := preload("res://assets/models/source/room_4/Calavera_DecoracionMiedo.glb")
const FEAR_WITCH_SIGN := preload("res://assets/models/source/room_4/CartelCasa_DecoracionMiedo.glb")
const POSTER := preload("res://assets/models/source/general/cartelPeliculas.glb")
const PosterMaterialScript := preload("res://scripts/cinema_poster_material.gd")
const SeatScript := preload("res://scripts/cinema_seat_interactable.gd")
const RoomZoneScript := preload("res://scripts/room_zone.gd")
const TRASH := preload("res://scenes/gameplay/trash_item.tscn")
const SMALL := [preload("res://resources/trash/ticket.tres"), preload("res://resources/trash/napkin.tres"), preload("res://resources/trash/cup.tres"), preload("res://resources/trash/can.tres"), preload("res://resources/trash/straw.tres"), preload("res://resources/trash/popcorn.tres")]
const LARGE := [preload("res://resources/trash/bottle.tres"), preload("res://resources/trash/bucket.tres")]

@export var room_id: StringName = &"room_03"

const WALL_RED_TOP := 2.55
# The wine wallpaper contains five vertical motifs per tile. In the long fear
# room, map them in metres so side and end-wall bays have the same motif width.
const FEAR_PANEL_TILE_SIZE := Vector3(5.4, 2.10, 5.4)

var _center_x := 0.0
var _width := 0.0
var _min_z := 0.0
var _max_z := 0.0
var _entry_z := 0.0
var _screen_z := 0.0
var _rear_row_z := 0.0
var _front_row_z := 0.0
var _rear_height := 0.0
var _row_count := 0
var _seat_columns: Array[float] = []
var _aisle_offsets: Array[float] = []
var _seat_collision_shape: BoxShape3D
var _carpet: Material
var _panel_material: Material
var _manager: GameplayManager
var _hanging_decor: Array[Node3D] = []
var _decor_time := 0.0


func _ready() -> void:
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	_configure()
	_build_shell()
	_build_rake_and_seats()
	_build_fixtures()
	_build_themed_decorations()
	_build_zone()
	call_deferred("_spawn_trash")


func _process(delta: float) -> void:
	_decor_time += delta
	for decoration in _hanging_decor:
		decoration.rotation.y += delta * 0.035
		decoration.rotation.x = sin(_decor_time * 0.72 + decoration.position.z) * 0.025


func _configure() -> void:
	_carpet = ACTION_CARPET if room_id == &"room_03" else FEAR_CARPET
	_panel_material = PANEL
	if room_id == &"room_03":
		# Room 3 shares Room 2's north/south footprint but extends west beyond
		# the manager office. A small gap separates the two auditoria.
		_center_x = -9.375
		# The outer walking lanes now reach both side walls without spare floor strips.
		_width = 27.25
		_min_z = 25.0
		_max_z = 57.0
		_entry_z = 25.0
		_screen_z = 56.67
		_rear_row_z = 33.0
		_front_row_z = 50.0
		_rear_height = 1.17
		_row_count = 9
		# Three six-seat blocks and four aisles, matching Room 2's arrangement.
		_seat_columns = [-11.75, -10.63, -9.31, -8.19, -6.87, -5.75, -3.10, -1.98, -0.66, 0.66, 1.98, 3.10, 5.70, 6.82, 8.14, 9.46, 10.78, 11.75]
		_aisle_offsets = [-12.90, -4.40, 4.40, 12.90]
	else:
		# Local triplanar coordinates restart the motif in every column bay while
		# keeping its physical width identical on lateral and end walls.
		var fear_panel := PANEL.duplicate() as StandardMaterial3D
		fear_panel.uv1_triplanar = true
		fear_panel.uv1_world_triplanar = false
		fear_panel.uv1_scale = Vector3(1.0 / FEAR_PANEL_TILE_SIZE.x, 1.0 / FEAR_PANEL_TILE_SIZE.y, 1.0 / FEAR_PANEL_TILE_SIZE.z)
		_panel_material = fear_panel
		_center_x = -44.0
		_width = 18.0
		_min_z = -63.0
		_max_z = -9.0
		_entry_z = -9.0
		_screen_z = -62.67
		_rear_row_z = -16.0
		_front_row_z = -50.0
		_rear_height = 1.75
		_row_count = 18
		_seat_columns = [-6.0, -4.8, -3.6, -2.4, 2.4, 3.6, 4.8, 6.0]
		_aisle_offsets = [-7.7, 0.0, 7.7]
	_seat_collision_shape = BoxShape3D.new()
	_seat_collision_shape.size = Vector3(1.08, 1.26, 0.98)


func _build_shell() -> void:
	var center_z := (_min_z + _max_z) * 0.5
	var join_y := WALL_RED_TOP - 0.02
	_solid("Floor", Vector3(_center_x, -0.12, center_z), Vector3(_width, 0.24, _max_z - _min_z), _carpet)
	_solid("Ceiling", Vector3(_center_x, 7.12, center_z), Vector3(_width, 0.24, _max_z - _min_z), DARK)
	for side in [-1.0, 1.0]:
		var x: float = _center_x + float(side) * _width * 0.5
		var bay_count := _side_bay_count()
		var bay_length := (_max_z - _min_z) / float(bay_count)
		for i in bay_count:
			var z := _min_z + (i + 0.5) * bay_length
			_solid("SideBase_%s_%02d" % [side, i], Vector3(x, 0.215, z), Vector3(0.24, 0.43, bay_length), DARK)
			_solid("SidePanel_%s_%02d" % [side, i], Vector3(x, (0.43 + join_y) * 0.5, z), Vector3(0.24, join_y - 0.43, bay_length), _panel_material)
			_solid("SidePlaster_%s_%02d" % [side, i], Vector3(x, (join_y + 7.0) * 0.5, z), Vector3(0.24, 7.0 - join_y, bay_length), CREAM)
			_solid("SideMoulding_%s_%02d" % [side, i], Vector3(x, WALL_RED_TOP, z), Vector3(0.30, 0.16, bay_length), DARK, false)
		for boundary in bay_count + 1:
			_solid("SidePillar_%s_%02d" % [side, boundary], Vector3(x, 3.5, _min_z + boundary * bay_length), Vector3(0.40, 7.0, 0.28), DARK)
	# Each room owns its entry wall except the exact shutter opening. Room 4's
	# remaining entry wing is provided by the west-corridor blockout.
	if room_id == &"room_03":
		_wall_z("EntryWestWing", _center_x - _width * 0.5, -9.5, _entry_z)
		_wall_z("EntryEastWing", -6.5, _center_x + _width * 0.5, _entry_z)
	else:
		# Sala 4 opens onto the center aisle from the lower wall of the left hall.
		_wall_z("EntryWestWing", _center_x - _width * 0.5, -45.5, _entry_z)
		_wall_z("EntryEastWing", -42.5, _center_x + _width * 0.5, _entry_z)
	# Only fill the doorway above the shutter; the wings already own their
	# plaster. A full-width upper slab doubled those faces and left a gap below.
	var opening_x := -8.0 if room_id == &"room_03" else -44.0
	_solid("EntryDoorHeader", Vector3(opening_x, 3.6, _entry_z), Vector3(3.0, 1.6, 0.24), CREAM)
	_solid("EntryDoorUpper", Vector3(opening_x, 5.7, _entry_z), Vector3(3.0, 2.6, 0.24), CREAM)
	var corridor_face_z := _entry_z + (-0.17 if room_id == &"room_03" else 0.17)
	_solid("EntryDoorFrameLeft", Vector3(opening_x - 1.5, 1.4, corridor_face_z), Vector3(0.34, 2.8, 0.08), DARK, false)
	_solid("EntryDoorFrameRight", Vector3(opening_x + 1.5, 1.4, corridor_face_z), Vector3(0.34, 2.8, 0.08), DARK, false)
	_solid("EntryDoorFrameTop", Vector3(opening_x, 3.0, corridor_face_z), Vector3(3.34, 0.38, 0.08), DARK, false)
	var room_face_z := _entry_z + (0.17 if room_id == &"room_03" else -0.17)
	_solid("EntryDoorInteriorFrameLeft", Vector3(opening_x - 1.5, 1.4, room_face_z), Vector3(0.34, 2.8, 0.08), DARK, false)
	_solid("EntryDoorInteriorFrameRight", Vector3(opening_x + 1.5, 1.4, room_face_z), Vector3(0.34, 2.8, 0.08), DARK, false)
	_solid("EntryDoorInteriorFrameTop", Vector3(opening_x, 3.0, room_face_z), Vector3(3.34, 0.38, 0.08), DARK, false)
	var screen_wall_z := _max_z if room_id == &"room_03" else _min_z
	_wall_z("ScreenWall", _center_x - _width * 0.5, _center_x + _width * 0.5, screen_wall_z)
	var screen_width := 14.2 if room_id == &"room_03" else 12.2
	_solid("Screen", Vector3(_center_x, 3.6, _screen_z), Vector3(screen_width, 5.2, 0.1), SCREEN)
	for side in [-1.0, 1.0]:
		_solid("ScreenFrameSide_%s" % side, Vector3(_center_x + side * (screen_width * 0.5 + 0.1), 3.6, _screen_z), Vector3(0.28, 5.62, 0.26), DARK, false)
		_solid("ScreenCurtain_%s" % side, Vector3(_center_x + side * (screen_width * 0.5 + 0.75), 3.5, _screen_z), Vector3(0.9, 5.7, 0.2), CURTAIN, false)
	_solid("ScreenFrameTop", Vector3(_center_x, 6.29, _screen_z), Vector3(screen_width + 0.6, 0.28, 0.26), DARK, false)
	_solid("ScreenFrameBottom", Vector3(_center_x, 0.91, _screen_z), Vector3(screen_width + 0.6, 0.28, 0.26), DARK, false)
	_light("ScreenHouseLight", Vector3(_center_x, 4.4, _entry_z + (2.0 if room_id == &"room_03" else -2.0)), 1.65, 22.0)


func _build_rake_and_seats() -> void:
	var travel := absf(_front_row_z - _rear_row_z)
	var row_spacing := travel / float(_row_count - 1)
	var toward_screen := 1.0 if room_id == &"room_03" else -1.0
	# Shared sloped walking lanes; shallow tiers provide seat plinths without
	# hundreds of individual floor colliders.
	for aisle_index in _aisle_offsets.size():
		var offset := _aisle_offsets[aisle_index]
		var aisle_width := _aisle_width(aisle_index)
		_ramp("AisleSlope_%02d" % aisle_index, _center_x + offset, aisle_width, _rear_row_z, _front_row_z, _rear_height)
	for row_index in _row_count:
		var fraction := float(row_index) / float(_row_count - 1)
		var z := lerpf(_rear_row_z, _front_row_z, fraction)
		var y := lerpf(_rear_height, 0.0, fraction)
		for column_index in _seat_columns.size():
			_add_seat(row_index, column_index, Vector3(_center_x + _seat_columns[column_index], y, z))
		if row_index < _row_count - 1:
			for block_index in (3 if room_id == &"room_03" else 2):
				var block := _block_geometry(block_index)
				_solid("Tier_%02d_%02d" % [row_index, block_index], Vector3(_center_x + block.x, y * 0.5, z + toward_screen * row_spacing * 0.5), Vector3(block.y, maxf(0.04, y), row_spacing * 1.02), _carpet)
				_solid("StepLight_%02d_%02d" % [row_index, block_index], Vector3(_center_x + block.x, y + 0.006, z + toward_screen * row_spacing * 0.88), Vector3(block.y * 0.8, 0.012, 0.04), STEP_LIGHT, false)
	# Room 3 copies Room 2's three filled entrance steps exactly: 0.85 m
	# treads from z=30.455 to 33, with the same widths as the four aisles.
	# Room 4 keeps five risers and the full 1.75 m climb, but uses the same
	# compact 0.85 m treads as Room 2 instead of five stretched 1.26 m slabs.
	var step_count := 3 if room_id == &"room_03" else 5
	var fear_step_depth := 0.85
	var fear_step_start_z := _rear_row_z - toward_screen * float(step_count) * fear_step_depth
	for aisle_index in _aisle_offsets.size():
		var x := _center_x + _aisle_offsets[aisle_index]
		var width := _aisle_width(aisle_index)
		for step in step_count:
			var rise := _rear_height * float(step + 1) / float(step_count)
			var z := 30.88 + step * 0.85 if room_id == &"room_03" else fear_step_start_z + toward_screen * (float(step) + 0.5) * fear_step_depth
			var depth := 0.85 if room_id == &"room_03" else fear_step_depth
			_solid("EntranceStep_%02d_%02d" % [aisle_index, step], Vector3(x, rise * 0.5, z), Vector3(width, rise, depth), _carpet, false)
			_solid("EntranceStepLight_%02d_%02d" % [aisle_index, step], Vector3(x, rise + 0.004, z + toward_screen * 0.40), Vector3(width * 0.84, 0.012, 0.045), STEP_LIGHT, false)
		if room_id == &"room_03":
			_ramp("EntranceRamp_%02d" % aisle_index, x, width, 30.455, _rear_row_z, 0.0, _rear_height)
		else:
			_ramp("EntranceRamp_%02d" % aisle_index, x, width, fear_step_start_z, _rear_row_z, 0.0, _rear_height)


func _aisle_width(index: int) -> float:
	if room_id == &"room_03":
		return 1.2 if index == 0 or index == 3 else 1.5
	# The fear room's side lanes now meet the inner wall faces, while the
	# central lane reaches both seat tiers without exposed floor strips.
	return 2.40 if absf(_aisle_offsets[index]) > 6.0 else 3.40


func _block_geometry(index: int) -> Vector2:
	if room_id == &"room_04":
		return Vector2(-4.2 if index == 0 else 4.2, 5.1)
	return [Vector2(-8.75, 7.2), Vector2(0.0, 7.2), Vector2(8.75, 7.2)][index]


func _add_seat(row_index: int, column_index: int, at: Vector3) -> void:
	var seat := StaticBody3D.new()
	seat.name = "%sSeat_%02d_%02d" % ["Room03" if room_id == &"room_03" else "Room04", row_index + 1, column_index + 1]
	seat.position = at
	seat.collision_layer = 8
	seat.collision_mask = 1
	seat.add_to_group("%s_seat" % room_id)
	add_child(seat)
	var pattern := (row_index * 7 + column_index * 3) % 5
	var folded := pattern == 1
	var source := SEAT_FOLDED if folded else (SEAT_BROKEN if pattern == 4 else SEAT_STANDARD)
	var visual := source.instantiate() as Node3D
	visual.name = "ButacaPlegada" if folded else ("ButacaRota" if pattern == 4 else "ButacaEstandar")
	visual.scale = Vector3.ONE * 1.55
	visual.rotation.y = PI if room_id == &"room_04" else 0.0
	seat.add_child(visual)
	seat.set_meta("seat_variant", visual.name)
	var collision := CollisionShape3D.new()
	collision.name = "SeatSimpleCollision"
	collision.position = Vector3(0.0, 0.64, 0.0)
	collision.shape = _seat_collision_shape
	seat.add_child(collision)
	if folded:
		return
	var interaction := Area3D.new()
	interaction.name = "CinemaSeatInteraction"
	interaction.set_script(SeatScript)
	interaction.room_id = room_id
	interaction.seat_id = StringName(seat.name)
	interaction.seat_body = seat
	interaction.facing_y = PI if room_id == &"room_03" else 0.0
	interaction.rear_direction = -1.0 if room_id == &"room_03" else 1.0
	var nearest := _aisle_offsets[0]
	for offset in _aisle_offsets:
		if absf(_seat_columns[column_index] - offset) < absf(_seat_columns[column_index] - nearest):
			nearest = offset
	# Exit candidates use the seat's global position; Room 4's blockout is
	# translated, so the matching aisle X must be expressed in world space too.
	interaction.aisle_x = to_global(Vector3(_center_x + nearest, 0.0, 0.0)).x
	interaction.position = Vector3(0.0, 0.75, 0.57 if room_id == &"room_03" else -0.57)
	interaction.collision_layer = 0
	interaction.collision_mask = 0
	interaction.add_to_group("cinema_seat")
	seat.add_child(interaction)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.94, 1.1, 0.64)
	var area_shape := CollisionShape3D.new()
	area_shape.shape = shape
	interaction.add_child(area_shape)


func _build_fixtures() -> void:
	var screen_side := 1.0 if room_id == &"room_03" else -1.0
	var room_name := "Room03" if room_id == &"room_03" else "Room04"
	for side in [-1.0, 1.0]:
		var speaker_x: float = _center_x + float(side) * (_width * 0.5 - 3.4)
		var speaker_z := _screen_z - screen_side * 1.35
		var speaker_scale := 4.2 if room_id == &"room_03" else 3.0
		var speaker_collision := Vector3(2.2, 3.5, 1.9) if room_id == &"room_03" else Vector3(1.6, 2.5, 1.4)
		var speaker_rotation: float = PI + float(side) * deg_to_rad(45.0) if room_id == &"room_03" else -float(side) * deg_to_rad(45.0)
		var cinema_speaker := _prop("%sCinemaSpeaker%s" % [room_name, "Left" if side < 0.0 else "Right"], CINEMA_SPEAKER, Vector3(speaker_x, 0.08, speaker_z), speaker_scale, speaker_collision, speaker_rotation)
		(cinema_speaker.get_child(1) as CollisionShape3D).rotation.y = speaker_rotation
		var bay_count := _side_bay_count()
		for bay in bay_count:
			var z := _min_z + (bay + 0.5) * (_max_z - _min_z) / float(bay_count)
			var wall_x: float = _center_x + float(side) * (_width * 0.5 - 0.2)
			var inward_rotation: float = float(side) * PI * 0.5
			_prop("WallGrille_%s_%02d" % [side, bay], WALL_GRILLE, Vector3(wall_x, 4.75, z), 0.9, Vector3.ZERO, inward_rotation)
			_prop("WallSpeaker_%s_%02d" % [side, bay], WALL_SPEAKER, Vector3(wall_x, 3.35, z), 1.1, Vector3.ZERO, inward_rotation + PI)
			_prop("WallLightA_%s_%02d" % [side, bay], WALL_LIGHT, Vector3(wall_x, 3.85, z - 1.55), 0.55, Vector3.ZERO, inward_rotation, PI * 0.5, Vector3(1.0, 1.0, 0.727))
			_prop("WallLightB_%s_%02d" % [side, bay], WALL_LIGHT, Vector3(wall_x, 3.85, z + 1.55), 0.55, Vector3.ZERO, inward_rotation, PI * 0.5, Vector3(1.0, 1.0, 0.727))
			_lamp_glow("WallGlowA_%s_%02d" % [side, bay], Vector3(wall_x - side * 0.38, 3.85, z - 1.55))
			_lamp_glow("WallGlowB_%s_%02d" % [side, bay], Vector3(wall_x - side * 0.38, 3.85, z + 1.55))
	var poster_x := -4.7 if room_id == &"room_03" else -41.0
	var poster_z := 24.60 if room_id == &"room_03" else -8.42
	_prop("%sEntryPosterFrame" % room_name, POSTER, Vector3(poster_x, 0.0, poster_z), 2.0, Vector3(1.5, 2.4, 0.55), PI if room_id == &"room_03" else 0.0)
	var display := MeshInstance3D.new()
	display.name = "%sEntryPosterDisplay" % room_name
	var quad := QuadMesh.new()
	quad.size = Vector2(1.27, 1.9)
	display.mesh = quad
	display.material_override = PosterMaterialScript.create_for_room(3 if room_id == &"room_03" else 4)
	display.position = Vector3(poster_x, 1.34, poster_z + (-0.10 if room_id == &"room_03" else 0.10))
	display.rotation.y = PI if room_id == &"room_03" else 0.0
	add_child(display)


func _side_bay_count() -> int:
	return 6 if room_id == &"room_03" else 10


func _build_themed_decorations() -> void:
	if room_id == &"room_03":
		for i in 8:
			var x: float = _center_x + [-7.0, -2.4, 3.5, 7.8][i % 4]
			var z := 30.0 + float(i / 4) * 12.0 + float(i % 4) * 2.3
			_hang("ActionStar_%02d" % i, ACTION_STAR, Vector3(x, 5.1 + float(i % 3) * 0.22, z), 3.1, i)
		return
	for i in 12:
		var x: float = _center_x + [-5.6, -2.2, 2.0, 5.5][i % 4]
		var z := -15.0 - float(i / 4) * 15.0 - float(i % 4) * 2.2
		_hang("FearBats_%02d" % i, FEAR_BATS, Vector3(x, 5.2 + float(i % 3) * 0.2, z), 3.0, i)
	# Four high corners; the meshes span the adjoining front/back and side walls.
	for screen_side in [-1, 1]:
		var wall_z := _min_z + 0.28 if screen_side < 0 else _max_z - 0.28
		for wall_side in [-1, 1]:
			var x := _center_x + float(wall_side) * (_width * 0.5 - 0.9)
			_prop("FearCobweb_%s_%s" % [screen_side, wall_side], FEAR_WEB, Vector3(x, 5.45, wall_z), 5.0, Vector3.ZERO, float(wall_side * screen_side) * PI * 0.25)
	for side in [-1, 1]:
		_prop("FearTornCurtain_%s" % side, FEAR_CURTAIN, Vector3(_center_x + float(side) * 5.65, 4.9, _screen_z + 0.22), 4.0, Vector3.ZERO, PI)
	var skull_positions := [
		Vector3(_center_x - 6.5, 0.0, -56.0),
		Vector3(_center_x + 6.2, 0.0, -54.0),
		Vector3(_center_x - 4.3, 0.0, -7.5),
		Vector3(_center_x + 4.2, 0.0, -7.2),
		Vector3(_center_x - 5.5, 0.0, -12.0),
		Vector3(_center_x + 5.4, 0.0, -13.4),
	]
	for i in skull_positions.size():
		_prop("FearSkull_%02d" % i, FEAR_SKULL, skull_positions[i], 1.4, Vector3.ZERO, float(i) * 0.9)
	# The supplied haunted-house sign belongs beside the Room 4 doorway.
	_prop("FearWitchSignLeftOfDoor", FEAR_WITCH_SIGN, Vector3(-46.9, 0.0, -8.59), 5.0, Vector3.ZERO, 0.0)


func _hang(label: String, source: PackedScene, at: Vector3, scale_value: float, index: int) -> void:
	_prop(label, source, at, scale_value, Vector3.ZERO, float(index % 4) * 0.33)
	_hanging_decor.append(get_node(label) as Node3D)


func _lamp_glow(label: String, at: Vector3) -> void:
	var lamp := _light(label, at, 0.26, 3.0)
	lamp.omni_attenuation = 1.35
	lamp.shadow_enabled = false


func _build_zone() -> void:
	var zone := Area3D.new()
	zone.name = "Room03Zone" if room_id == &"room_03" else "Room04Zone"
	zone.set_script(RoomZoneScript)
	zone.set("room_id", room_id)
	zone.position = Vector3(_center_x, 3.0, (_min_z + _max_z) * 0.5)
	zone.collision_layer = 0
	zone.collision_mask = 1
	var shape := BoxShape3D.new()
	shape.size = Vector3(_width - 0.7, 6.0, _max_z - _min_z - 0.6)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	zone.add_child(collision)
	add_child(zone)


func _spawn_trash() -> void:
	if _manager == null:
		push_error("New auditorium requires GameplayManager")
		return
	var small_positions := _build_trash_positions(false)
	var large_positions := _build_trash_positions(true)
	_manager.get_dense_registry().populate(room_id,small_positions,large_positions,self)


func _build_trash_positions(large: bool) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var action := room_id == &"room_03"
	if large:
		for i in (16 if action else 12):
			positions.append(_aisle_trash_position(i, 16 if action else 12, 0.40))
		for i in (8 if action else 4):
			positions.append(_rear_trash_position(i * (1 if action else 2), 0.42, true))
		for i in (6 if action else 4):
			positions.append(_front_trash_position(i, 0.42, true))
		return positions
	var cushion_count := 81 if action else 108
	var seat_total := _row_count * _seat_columns.size()
	var toward_screen := signf(_front_row_z - _rear_row_z)
	for i in cushion_count:
		var seat_index := (i * 37) % seat_total
		var row_index := floori(float(seat_index) / float(_seat_columns.size()))
		var column_index := seat_index % _seat_columns.size()
		var z := _row_z(row_index)
		positions.append(Vector3(_center_x + _seat_columns[column_index], _row_height(row_index) + 1.27, z))
	for i in cushion_count:
		var seat_index := ((i + cushion_count) * 37) % seat_total
		var row_index := floori(float(seat_index) / float(_seat_columns.size()))
		var column_index := seat_index % _seat_columns.size()
		var z := _row_z(row_index) + toward_screen * 0.52
		positions.append(Vector3(_center_x + _seat_columns[column_index], _row_height(row_index) + 0.22, z))
	# Each gap uses the top of its actual stepped tread, not the invisible
	# player ramp beneath the seating blocks.
	for row_index in _row_count - 1:
		for column_index in _seat_columns.size():
			var copies := 1 if action else 2
			for copy_index in copies:
				var gap_fraction := 0.50 if action else (0.35 if copy_index == 0 else 0.68)
				var z := lerpf(_row_z(row_index), _row_z(row_index + 1), gap_fraction)
				var x := _center_x + _seat_columns[column_index] + (0.12 if copy_index == 0 else -0.12)
				positions.append(Vector3(x, _row_height(row_index) + 0.27, z))
	var aisle_count := 64 if action else 96
	for i in aisle_count:
		positions.append(_aisle_trash_position(i, aisle_count, 0.28))
	for i in (24 if action else 32):
		positions.append(_rear_trash_position(i, 0.28, false))
	for i in (16 if action else 24):
		positions.append(_front_trash_position(i, 0.28, false))
	return positions


func _row_z(index: int) -> float:
	return lerpf(_rear_row_z, _front_row_z, float(index) / float(_row_count - 1))


func _row_height(index: int) -> float:
	return lerpf(_rear_height, 0.0, float(index) / float(_row_count - 1))


func _aisle_trash_position(index: int, count: int, clearance: float) -> Vector3:
	var along := (float(index) + 0.5) / float(count)
	var z := lerpf(_rear_row_z, _front_row_z, along)
	var x := _center_x + _aisle_offsets[index % _aisle_offsets.size()] + 0.16 * sin(float(index) * 1.7)
	return Vector3(x, lerpf(_rear_height, 0.0, along) + clearance, z)


func _rear_trash_position(index: int, clearance: float, large: bool) -> Vector3:
	# This landing is level. X slots deliberately avoid all entrance ramps,
	# including Room 4's center aisle, so nothing appears beneath the steps.
	var slots := [-11.1, -8.4, -6.0, -2.0, 2.0, 6.0, 8.4, 11.1] if room_id == &"room_03" else [-6.1, -4.4, -3.0, -1.45, 1.45, 3.0, 4.4, 6.1]
	var toward_screen := signf(_front_row_z - _rear_row_z)
	var z := _entry_z + toward_screen * (2.2 + float(floori(float(index) / 8.0)) * 1.1 + (0.45 if large else 0.0))
	return Vector3(_center_x + float(slots[index % 8]), clearance, z)


func _front_trash_position(index: int, clearance: float, large: bool) -> Vector3:
	var toward_screen := signf(_front_row_z - _rear_row_z)
	var x := _center_x - 6.2 + float(index % 8) * 1.77
	var z := _front_row_z + toward_screen * (3.0 + float(floori(float(index) / 8.0)) * 1.6 + (2.4 if large else 0.0))
	return Vector3(x, clearance, z)


func _spawn_item(large: bool, index: int, at: Vector3) -> void:
	var key := "%s:%s:%03d" % [room_id, "large" if large else "small", index + 1]
	if _manager.is_world_trash_collected(key):
		return
	var pool := LARGE if large else SMALL
	var item := TRASH.instantiate() as RigidBody3D
	item.name = "NewRoomTrash_%s_%03d" % ["large" if large else "small", index + 1]
	item.definition = pool[index % pool.size()]
	item.room_id = room_id
	item.world_item_id = key
	item.position = at
	item.rotation.y = deg_to_rad(float((index * 47) % 360))
	add_child(item)
	var player := get_tree().get_first_node_in_group("player") as PhysicsBody3D
	if player:
		item.add_collision_exception_with(player)
		player.add_collision_exception_with(item)


func _ramp(label: String, x: float, width: float, rear_z: float, front_z: float, rear_y: float, front_y := 0.0) -> void:
	var run := absf(front_z - rear_z)
	var rise := rear_y - front_y
	var length := sqrt(run * run + rise * rise)
	var body := StaticBody3D.new()
	body.name = label
	body.position = Vector3(x, (rear_y + front_y) * 0.5 - 0.055, (rear_z + front_z) * 0.5)
	body.rotation.x = atan2(rise, run) * signf(front_z - rear_z)
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 0.1, length)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	mesh.material = _carpet
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	body.add_child(visual)
	add_child(body)


func _wall_z(label: String, x0: float, x1: float, z: float) -> void:
	var width := x1 - x0
	var count := maxi(1, ceili(width / 4.6))
	var bay_width := width / float(count)
	var join_y := WALL_RED_TOP - 0.02
	for i in count:
		var x := x0 + (i + 0.5) * bay_width
		_solid("%sBase_%02d" % [label, i], Vector3(x, 0.215, z), Vector3(bay_width, 0.43, 0.24), DARK)
		_solid("%sPanel_%02d" % [label, i], Vector3(x, (0.43 + join_y) * 0.5, z), Vector3(bay_width, join_y - 0.43, 0.24), _panel_material)
		_solid("%sPlaster_%02d" % [label, i], Vector3(x, (join_y + 7.0) * 0.5, z), Vector3(bay_width, 7.0 - join_y, 0.24), CREAM)
		_solid("%sMoulding_%02d" % [label, i], Vector3(x, WALL_RED_TOP, z), Vector3(bay_width, 0.16, 0.3), DARK, false)
	# The screen-side columns sit in front of the wall face, but behind the
	# projection plane, so the picture stays free of black vertical stripes.
	var pillar_z := z
	if label == "ScreenWall":
		pillar_z += -0.09 if room_id == &"room_03" else 0.09
	for boundary in count + 1:
		_solid("%sPillar_%02d" % [label, boundary], Vector3(x0 + boundary * bay_width, 3.5, pillar_z), Vector3(0.34, 7.0, 0.30), DARK)


func _prop(label: String, source: PackedScene, at: Vector3, scale_value: float, dimensions: Vector3, rotation_y: float, rotation_x := 0.0, scale_axes := Vector3.ONE) -> Node3D:
	var root: Node3D = StaticBody3D.new() if dimensions != Vector3.ZERO else Node3D.new()
	root.name = label
	root.position = at
	var model := source.instantiate() as Node3D
	model.scale = scale_axes * scale_value
	model.rotation.y = rotation_y
	model.rotation.x = rotation_x
	root.add_child(model)
	if dimensions != Vector3.ZERO:
		var shape := BoxShape3D.new()
		shape.size = dimensions
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position.y = dimensions.y * 0.5
		root.add_child(collision)
	add_child(root)
	return root


func _light(label: String, at: Vector3, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = label
	light.position = at
	light.light_color = Color("ffc78d")
	light.light_energy = energy
	light.omni_range = radius
	add_child(light)
	return light


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
