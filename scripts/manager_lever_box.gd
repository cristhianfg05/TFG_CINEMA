extends Node3D

const LEVER_SCRIPT := preload("res://scripts/manager_room_lever.gd")
const ROOM_IDS := [&"room_01", &"room_02", &"room_03", &"room_04"]
const LEVER_SPACING := 0.55
const LEVER_START_X := -0.825
const LEVER_UP_ANGLE := -80.0

@export var activation_sfx: AudioStream

var _manager: GameplayManager
var _lever_busy: Array[bool] = [false, false, false, false]
var _indicator_lenses: Array[MeshInstance3D] = []
var _lever_pivots: Array[Node3D] = []
var _audio_players: Array[AudioStreamPlayer3D] = []


func _ready() -> void:
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	if _manager == null:
		push_error("Manager lever box requires GameplayManager.")
		return
	for index in ROOM_IDS.size():
		var number := index + 1
		var pivot := $Model.find_child("Lever_%d_Pivot" % number, true, false) as Node3D
		var lens := $Model.find_child("Room_%d_IndicatorDark" % number, true, false) as MeshInstance3D
		if pivot == null or lens == null:
			push_error("Manager lever box is missing lever or indicator %d." % number)
			return
		_lever_pivots.append(pivot)
		_indicator_lenses.append(lens)
		pivot.rotation_degrees.x = LEVER_UP_ANGLE if _manager.is_room_activated(ROOM_IDS[index]) else 0.0
		var voice := AudioStreamPlayer3D.new()
		voice.name = "LeverAudio" if index == 0 else "LeverAudio_%02d" % (index + 1)
		voice.bus = &"Machines"
		voice.stream = activation_sfx
		voice.unit_size = 1.5
		voice.max_distance = 14.0
		voice.position = Vector3(LEVER_START_X + index * LEVER_SPACING, 0.71, 0.55)
		add_child(voice)
		_audio_players.append(voice)
		_add_hitbox(index)
	_manager.state_changed.connect(_refresh_indicators)
	_refresh_indicators()


func get_lever_prompt(room_id: StringName, number: int) -> String:
	if _manager == null:
		return ""
	if _manager.is_room_activated(room_id):
		return "Sala %d activada" % number
	if _manager.can_activate_room(room_id):
		return "[E] Activar sala %d" % number
	if int(_manager.room_trash_totals.get(String(room_id), 0)) <= 0:
		return "Sala %d pendiente" % number
	# Progress display rounds; never show 100% while one item still blocks activation.
	return ("Sala %d: limpieza %.2f%%" % [number, _manager.get_room_clean_percent(room_id)]).replace(".", ",")


func try_raise_lever(room_id: StringName, number: int) -> void:
	if _manager == null or number < 1 or number > ROOM_IDS.size():
		return
	var index := number - 1
	if _lever_busy[index] or ROOM_IDS[index] != room_id or not _manager.can_activate_room(room_id):
		return
	_lever_busy[index] = true
	var pivot := _lever_pivots[index]
	var tween := create_tween()
	tween.tween_property(pivot, "rotation_degrees:x", LEVER_UP_ANGLE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var voice := _audio_players[index]
	if voice.stream != null and DisplayServer.get_name() != "headless":
		voice.pitch_scale = randf_range(0.98, 1.02)
		voice.play()
	_spawn_sparks(index)
	await tween.finished
	if not is_instance_valid(_manager):
		_lever_busy[index] = false
		return
	if not _manager.activate_room(room_id):
		pivot.rotation_degrees.x = 0.0
	_lever_busy[index] = false
	_refresh_indicators()


func _add_hitbox(index: int) -> void:
	var hitbox := StaticBody3D.new()
	hitbox.name = "Room%02dLever" % (index + 1)
	hitbox.set_script(LEVER_SCRIPT)
	hitbox.room_id = ROOM_IDS[index]
	hitbox.lever_number = index + 1
	hitbox.controller = self
	hitbox.position = Vector3(LEVER_START_X + index * LEVER_SPACING, 0.65, 0.48)
	add_child(hitbox)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.47, 0.70, 0.37)
	shape.shape = box
	hitbox.add_child(shape)


func _refresh_indicators() -> void:
	if _manager == null:
		return
	for index in _indicator_lenses.size():
		var room_id: StringName = ROOM_IDS[index]
		var lens := _indicator_lenses[index]
		var indicator := StandardMaterial3D.new()
		indicator.metallic = 0.12
		indicator.roughness = 0.28
		if _manager.is_room_activated(room_id):
			indicator.albedo_color = Color(0.30, 0.95, 0.52)
			indicator.emission = Color(0.06, 0.42, 0.16)
		elif _manager.can_activate_room(room_id):
			indicator.albedo_color = Color(1.0, 0.72, 0.24)
			indicator.emission = Color(0.45, 0.19, 0.01)
		else:
			indicator.albedo_color = Color(0.16, 0.18, 0.19)
		indicator.emission_enabled = _manager.is_room_activated(room_id) or _manager.can_activate_room(room_id)
		lens.set_surface_override_material(0, indicator)


func _spawn_sparks(index: int) -> void:
	var origin := Vector3(LEVER_START_X + index * LEVER_SPACING, 0.71, 0.55)
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = Color(1.0, 0.71, 0.26)
	spark_material.emission_enabled = true
	spark_material.emission = Color(1.0, 0.53, 0.12)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for spark_index in 10:
		var spark := MeshInstance3D.new()
		spark.name = "ActivationSpark_%d_%02d" % [index + 1, spark_index]
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.025, 0.025, 0.025)
		spark.mesh = mesh
		spark.material_override = spark_material
		spark.position = origin
		add_child(spark)
		var direction := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(0.2, 1.0), rng.randf_range(0.1, 1.0)).normalized()
		var animation := create_tween().set_parallel(true)
		animation.tween_property(spark, "position", origin + direction * rng.randf_range(0.13, 0.38), 0.32)
		animation.tween_property(spark, "scale", Vector3.ZERO, 0.32)
		animation.finished.connect(spark.queue_free)
